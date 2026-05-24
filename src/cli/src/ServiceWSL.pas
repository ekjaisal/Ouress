{
 BSD 3-Clause License
 ____________________

 Copyright © 2026, Jaisal E. K.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

unit ServiceWSL;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TWSLStatus = (wsUnknown, wsStopped, wsRunning);

  TWSLEnvironment = record
    Name:    String;
    Status:  TWSLStatus;
    Version: Integer;
  end;

  TWSLEnvironmentArray = array of TWSLEnvironment;

  TServiceWSL = class
  private
    class function RunProcess(const AExe: String; const AArgs: array of String; out AOutput: String; ATimeoutMS: Integer = 0): Boolean;
    class function FindWSLExe: String;
    class function StripControlChars(const S: String): String;
    class function IsValidRessFile(const APath: String): Boolean;
  public
    class function IsWSL2Available(out AErrorMsg: String): Boolean;
    class function ListEnvironments: TWSLEnvironmentArray;
    class function EnvironmentExists(const AName: String): Boolean;
    class function ImportEnvironment(const AName, AInstallPath, ARootFSPath: String; out AErrorMsg: String): Boolean;
    class function ExportEnvironment(const AName, ADestPath: String; ACompressionLevel: Integer; out AErrorMsg: String): Boolean;
    class function UnregisterEnvironment(const AName: String; out AErrorMsg: String): Boolean;
  end;

implementation

class function TServiceWSL.StripControlChars(const S: String): String;
var
  I, J, Len: Integer;
begin
  Result := '';
  Len := Length(S);
  SetLength(Result, Len);
  J := 0;
  for I := 1 to Len do
  begin
    if (S[I] >= #32) or (S[I] = #9) or (S[I] = #10) or (S[I] = #13) then
    begin
      Inc(J);
      Result[J] := S[I];
    end;
  end;
  SetLength(Result, J);
  Result := Trim(Result);
end;

class function TServiceWSL.FindWSLExe: String;
var
  SysDir: String;
begin
  SysDir := GetEnvironmentVariable('SystemRoot');
  if SysDir = '' then
    SysDir := 'C:\Windows';
  Result := SysDir + '\System32\wsl.exe';
  if not FileExists(Result) then
    Result := 'wsl.exe';
end;

class function TServiceWSL.IsValidRessFile(const APath: String): Boolean;
var
  FS: TFileStream;
  Magic: array[0..5] of Byte;
begin
  Result := False;

  Magic[0] := 0;
  Magic[1] := 0;
  Magic[2] := 0;
  Magic[3] := 0;
  Magic[4] := 0;
  Magic[5] := 0;

  try
    FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
    try
      if FS.Size >= 6 then
      begin
        FS.ReadBuffer(Magic, 6);
        if (Magic[0] = $FD) and (Magic[1] = $37) and (Magic[2] = $7A) and
           (Magic[3] = $58) and (Magic[4] = $5A) and (Magic[5] = $00) then
        begin
          Result := True;
        end;
      end;
    finally
      FS.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

class function TServiceWSL.RunProcess(const AExe: String; const AArgs: array of String; out AOutput: String; ATimeoutMS: Integer = 0): Boolean;
var
  Proc: TProcess;
  MS: TMemoryStream;
  Buf: array[0..4095] of Byte;
  BytesRead: Integer;
  I: Integer;
  WS: WideString;
  P: PByte;
  TimeoutCounter: Integer;
begin
  Result := False;
  AOutput := '';
  WS := '';
  Buf[0] := 0;
  FillChar(Buf, SizeOf(Buf), 0);

  MS := TMemoryStream.Create;
  try
    Proc := TProcess.Create(nil);
    try
      Proc.Executable := AExe;
      for I := 0 to High(AArgs) do
        Proc.Parameters.Add(AArgs[I]);

      Proc.Options := [poUsePipes, poNoConsole, poStderrToOutPut];
      Proc.Execute;

      TimeoutCounter := 0;

      while True do
      begin
        if Proc.Output.NumBytesAvailable > 0 then
        begin
          BytesRead := Proc.Output.Read(Buf, SizeOf(Buf));
          if BytesRead > 0 then
          begin
            MS.Write(Buf, BytesRead);
            TimeoutCounter := 0;
          end;
        end
        else if not Proc.Running then
        begin
          Break;
        end
        else
        begin
          Sleep(50);
          if ATimeoutMS > 0 then
          begin
            Inc(TimeoutCounter, 50);
            if TimeoutCounter > ATimeoutMS then
            begin
              Proc.Terminate(1);
              AOutput := 'ERROR_TIMEOUT: The WSL subsystem froze ' +
                'and was terminated.';
              Result := False;
              Break;
            end;
          end;
        end;
      end;

      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buf, SizeOf(Buf));
        if BytesRead > 0 then
          MS.Write(Buf, BytesRead);
      end;

      if MS.Size > 0 then
      begin
        P := PByte(MS.Memory);

        if (MS.Size >= 2) and (P[0] = $FF) and (P[1] = $FE) then
        begin
          SetLength(WS, (MS.Size div 2) - 1);
          if Length(WS) > 0 then
            Move(P[2], WS[1], Length(WS) * 2);
          AOutput := UTF8Encode(WS);
        end
        else
        begin
          SetLength(AOutput, MS.Size);
          Move(P[0], AOutput[1], MS.Size);
        end;
      end;

      Result := Proc.ExitCode = 0;
    finally
      Proc.Free;
    end;
  finally
    MS.Free;
  end;
end;

class function TServiceWSL.IsWSL2Available(out AErrorMsg: String): Boolean;
var
  Output: String;
  WslExe: String;
begin
  AErrorMsg := '';
  WslExe := FindWSLExe;

  if not FileExists(WslExe) then
  begin
    AErrorMsg := 'The wsl.exe executable was not found. WSL is not installed.';
    Result := False;
    Exit;
  end;

  Result := RunProcess(WslExe, ['--status'], Output, 15000);

  if Result and ((Pos('Error code:', Output) > 0) or
    (Pos('Wsl/Service', Output) > 0)) then
    Result := False;

  if not Result then
  begin
    AErrorMsg := StripControlChars(Output);
    Result := RunProcess(WslExe, ['--list'], Output, 15000);

    if Result and ((Pos('Error code:', Output) > 0) or
      (Pos('Wsl/Service', Output) > 0)) then
      Result := False;

    if not Result then
    begin
      if AErrorMsg = '' then
        AErrorMsg := StripControlChars(Output);
      if AErrorMsg = '' then
        AErrorMsg := 'WSL failed to respond to diagnostic commands.';
    end
    else
    begin
      AErrorMsg := '';
    end;
  end;
end;

class function TServiceWSL.ListEnvironments: TWSLEnvironmentArray;
var
  Output: String;
  Lines: TStringList;
  I: Integer;
  Line: String;
  Parts: TStringList;
  Env: TWSLEnvironment;
  Count: Integer;
begin
  Result := nil;
  SetLength(Result, 0);
  Count := 0;

  if not RunProcess(FindWSLExe, ['--list', '--verbose'], Output, 15000) then
    Exit;

  Lines := TStringList.Create;
  try
    Parts := TStringList.Create;
    try
      Lines.Text := Output;
      for I := 0 to Lines.Count - 1 do
      begin
        Line := StripControlChars(Lines[I]);

        if (Line = '') or (Pos('NAME', UpperCase(Line)) > 0) then
          Continue;

        if (Length(Line) > 0) and (Line[1] = '*') then
          Delete(Line, 1, 1);
        Line := TrimLeft(Line);

        Parts.Clear;
        Parts.Delimiter := ' ';
        Parts.DelimitedText := Line;

        while Parts.IndexOf('') >= 0 do
          Parts.Delete(Parts.IndexOf(''));

        if Parts.Count < 1 then
          Continue;

        Env.Name := Parts[0];
        Env.Status := wsUnknown;
        Env.Version := 2;

        if Parts.Count >= 2 then
        begin
          if SameText(Parts[1], 'Running') then
            Env.Status := wsRunning
          else if SameText(Parts[1], 'Stopped') then
            Env.Status := wsStopped;
        end;

        if Parts.Count >= 3 then
          Env.Version := StrToIntDef(Parts[2], 2);

        SetLength(Result, Count + 1);
        Result[Count] := Env;
        Inc(Count);
      end;
    finally
      Parts.Free;
    end;
  finally
    Lines.Free;
  end;
end;

class function TServiceWSL.EnvironmentExists(const AName: String): Boolean;
var
  Envs: TWSLEnvironmentArray;
  I: Integer;
begin
  Result := False;
  Envs := ListEnvironments;
  for I := 0 to High(Envs) do
    if SameText(Envs[I].Name, AName) then
    begin
      Result := True;
      Exit;
    end;
end;

class function TServiceWSL.ImportEnvironment(const AName, AInstallPath,
  ARootFSPath: String; out AErrorMsg: String): Boolean;
var
  Output: String;
begin
  AErrorMsg := '';

  if not FileExists(ARootFSPath) then
  begin
    AErrorMsg := 'Base image not found: ' + ARootFSPath;
    Result := False;
    Exit;
  end;

  if not IsValidRessFile(ARootFSPath) then
  begin
    AErrorMsg := 'Invalid archive format. The file is corrupt or ' +
      'not a valid Ouress snapshot.';
    Result := False;
    Exit;
  end;

  if not DirectoryExists(AInstallPath) then
    ForceDirectories(AInstallPath);

  Result := RunProcess(FindWSLExe,
    ['--import', AName, AInstallPath, ARootFSPath, '--version', '2'],
    Output, 0);

  if not Result then
    AErrorMsg := 'Import failed: ' + StripControlChars(Output);
end;

class function TServiceWSL.ExportEnvironment(const AName,
  ADestPath: String; ACompressionLevel: Integer; out AErrorMsg: String): Boolean;
var
  Output: String;
  TempTarPath: String;
  WSLPath: String;
  RenameRetries: Integer;
begin
  AErrorMsg := '';
  TempTarPath := ADestPath + '.tmp.tar';

  RunProcess(FindWSLExe, ['--terminate', AName], Output, 30000);
  Sleep(500);

  if FileExists(TempTarPath) then
    SysUtils.DeleteFile(TempTarPath);
  if FileExists(TempTarPath + '.xz') then
    SysUtils.DeleteFile(TempTarPath + '.xz');

  Result := RunProcess(FindWSLExe,
    ['--export', AName, TempTarPath], Output, 0);

  if not Result then
  begin
    AErrorMsg := 'Export failed: ' + StripControlChars(Output);
    Exit;
  end;

  Result := RunProcess(FindWSLExe,
    ['-d', AName, '-e', 'wslpath', '-a', TempTarPath], WSLPath, 15000);

  if not Result then
  begin
    AErrorMsg := 'Path resolution failed: ' + StripControlChars(WSLPath);
    SysUtils.DeleteFile(TempTarPath);
    Exit;
  end;

  WSLPath := Trim(StripControlChars(WSLPath));

  Result := RunProcess(FindWSLExe,
    ['-d', AName, '-e', 'xz', '-z', '-' + IntToStr(ACompressionLevel), '-T0', WSLPath], Output, 0);

  if not Result then
  begin
    AErrorMsg := 'Compression failed: ' + StripControlChars(Output);
    SysUtils.DeleteFile(TempTarPath);
    Exit;
  end;

  RunProcess(FindWSLExe, ['--terminate', AName], Output, 30000);

  if FileExists(ADestPath) then
    SysUtils.DeleteFile(ADestPath);

  if FileExists(TempTarPath + '.xz') then
  begin
    RenameRetries := 0;
    Result := False;
    while (RenameRetries < 20) and not Result do
    begin
      Result := RenameFile(TempTarPath + '.xz', ADestPath);
      if not Result then
      begin
        Sleep(250);
        Inc(RenameRetries);
      end;
    end;

    if not Result then
    begin
      SysUtils.DeleteFile(TempTarPath + '.xz');
      AErrorMsg := 'Export failed: OS file lock prevented ' +
        'finalisation. Temp files removed.';
      Result := False;
    end;
  end
  else
  begin
    AErrorMsg := 'Expected compressed file was not created.';
    Result := False;
  end;
end;

class function TServiceWSL.UnregisterEnvironment(const AName: String;
  out AErrorMsg: String): Boolean;
var
  Output: String;
begin
  AErrorMsg := '';
  Result := RunProcess(FindWSLExe,
    ['--unregister', AName], Output, 60000);
  if not Result then
    AErrorMsg := 'Unregistration failed: ' + StripControlChars(Output);
end;

end.