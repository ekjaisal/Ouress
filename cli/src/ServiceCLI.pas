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

unit ServiceCLI;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ServiceWSL, AppIdentity, Windows, CommDlg;

type
  TStringArray = array of String;

  TServiceCLI = class
  private
    class procedure PrintHeader;
    class procedure PrintDiagnostic(const AErrorMsg: String);
    class procedure EnsureWSLAvailable;
    class procedure ListInstances(out AEnvs: TWSLEnvironmentArray);
    class function GetBaseImages: TStringArray;
    class procedure ListBaseImagesDisplay(const AImages: TStringArray);
    class function CleanInput(const AInput: String): String;
    class function IsValidDistroName(const AName: String): Boolean;
    class function PromptForFile(AIsSave: Boolean; const ATitle: String): String;
    class procedure ProcessRegistration(const BaseImages: TStringArray);
    class procedure ProcessImport;
    class procedure ProcessExport(const Envs: TWSLEnvironmentArray);
    class procedure ProcessUnregister(const Envs: TWSLEnvironmentArray);
    class procedure HandleMenu;
  public
    class procedure Execute;
  end;

implementation

class procedure TServiceCLI.PrintHeader;
begin
  Writeln(APP_NAME, ' v', APP_VERSION, ' · ', APP_URL);
  Writeln('Copyright © 2026 ', DEV_AUTHOR, ' · BSD 3-Clause License');
  Writeln('See the installation directory for full license text and third-party notices.');
  Writeln('----------------------------------------------------------------------------------');
end;

class procedure TServiceCLI.PrintDiagnostic(const AErrorMsg: String);
var
  UpperErr: String;
begin
  UpperErr := UpperCase(AErrorMsg);

  Writeln('Diagnostic Information:');
  Writeln(AErrorMsg);

  if Pos('HCS_E_SERVICE_NOT_AVAILABLE', UpperErr) > 0 then
  begin
    Writeln;
    Writeln('The Host Compute Service (HCS) is not running or is disabled.');
    Writeln('Ensure virtualisation is enabled in the BIOS/UEFI and the Virtual');
    Writeln('Machine Platform feature is active.');
  end
  else if Pos('WSL_E_WSL_OPTIONAL_COMPONENT_REQUIRED', UpperErr) > 0 then
  begin
    Writeln;
    Writeln('A required Windows optional component is missing.');
    Writeln('Please open PowerShell as Administrator and execute:');
    Writeln('    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform');
  end
  else if Pos('NOT INSTALLED', UpperErr) > 0 then
  begin
    Writeln;
    Writeln('WSL does not appear to be installed on this machine.');
    Writeln('Please open PowerShell as Administrator and execute:');
    Writeln('    wsl --install');
  end
  else if (Pos('ERROR CODE:', UpperErr) > 0) or (Pos('WSL/SERVICE', UpperErr) > 0) then
  begin
    Writeln;
    Writeln('A subsystem error occurred.');
    Writeln('Ensure the Virtual Machine Platform is enabled and WSL is up to date.');
    Writeln('A repair can be attempted by opening PowerShell as Administrator');
    Writeln('and executing:');
    Writeln('    wsl --update');
  end;
end;

class procedure TServiceCLI.EnsureWSLAvailable;
var
  ErrMsg: String;
begin
  if not TServiceWSL.IsWSL2Available(ErrMsg) then
  begin
    Writeln('CRITICAL: Windows Subsystem for Linux (WSL) is unavailable.');
    Writeln;
    PrintDiagnostic(ErrMsg);
    Writeln;
    Writeln('Press Enter to terminate.');
    Readln;
    Halt(1);
  end;
end;

class procedure TServiceCLI.ListInstances(out AEnvs: TWSLEnvironmentArray);
var
  I: Integer;
begin
  AEnvs := TServiceWSL.ListEnvironments;

  Writeln;
  Writeln('Registered Environments');
  Writeln('----------------------------------------------------------------------------------');

  if Length(AEnvs) = 0 then
  begin
    Writeln('No environments found.');
    Exit;
  end;

  for I := 0 to High(AEnvs) do
  begin
    Writeln(Format(' [%d] %s', [I + 1, AEnvs[I].Name]));
  end;
end;

class function TServiceCLI.GetBaseImages: TStringArray;
var
  SearchRec: TSearchRec;
  ExeDir: String;
  Count: Integer;
begin
  Result := nil;
  Count := 0;
  ExeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  if FindFirst(ExeDir + 'ouress-*' + EXTENSION, faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
      begin
        SetLength(Result, Count + 1);
        Result[Count] := SearchRec.Name;
        Inc(Count);
      end;
    until FindNext(SearchRec) <> 0;
  finally
    SysUtils.FindClose(SearchRec);
  end;
end;

class procedure TServiceCLI.ListBaseImagesDisplay(const AImages: TStringArray);
var
  I: Integer;
begin
  Writeln;
  Writeln('Available Base Images');
  Writeln('----------------------------------------------------------------------------------');

  if Length(AImages) = 0 then
  begin
    Writeln('No base images found. Place a valid image file (' + EXTENSION + ') in the folder.');
  end
  else
  begin
    for I := 0 to High(AImages) do
      Writeln(Format(' [%d] %s', [I + 1, AImages[I]]));
  end;
end;

class function TServiceCLI.CleanInput(const AInput: String): String;
begin
  Result := Trim(AInput);
  if Length(Result) >= 2 then
  begin
    if (Result[1] = '"') and (Result[Length(Result)] = '"') then
      Result := Copy(Result, 2, Length(Result) - 2)
    else if (Result[1] = '''') and (Result[Length(Result)] = '''') then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;
  Result := Trim(Result);
end;

class function TServiceCLI.IsValidDistroName(const AName: String): Boolean;
var
  I: Integer;
begin
  Result := Length(AName) > 0;
  for I := 1 to Length(AName) do
  begin
    if not (AName[I] in ['a'..'z', 'A'..'Z', '0'..'9', '.', '_', '-']) then
      Exit(False);
  end;
end;

class function TServiceCLI.PromptForFile(AIsSave: Boolean; const ATitle: String): String;
type
  TSetThreadDpiAwarenessContext = function(dpiContext: THandle): THandle; stdcall;
var
  OFN: TOpenFileNameW;
  SzFile: array[0..MAX_PATH] of WideChar;
  FilterStr: WideString;
  User32Module: HMODULE;
  SetThreadDpiCtx: TSetThreadDpiAwarenessContext;
  OldCtx: THandle;
begin
  Result := '';
  OldCtx := 0;
  SetThreadDpiCtx := nil;

  User32Module := LoadLibrary('user32.dll');
  if User32Module <> 0 then
  begin
    SetThreadDpiCtx := TSetThreadDpiAwarenessContext(GetProcAddress(User32Module, 'SetThreadDpiAwarenessContext'));
    if Assigned(SetThreadDpiCtx) then
      OldCtx := SetThreadDpiCtx(THandle(-4));
  end;

  OFN.lStructSize := 0;
  SzFile[0] := #0;

  FillChar(OFN, SizeOf(TOpenFileNameW), 0);
  FillChar(SzFile, SizeOf(SzFile), 0);

  FilterStr := 'Ouress Snapshot (*.ress)'#0'*.ress'#0'All Files (*.*)'#0'*.*'#0#0;

  OFN.lStructSize := SizeOf(TOpenFileNameW);
  OFN.hwndOwner := GetConsoleWindow();
  OFN.lpstrFilter := PWideChar(FilterStr);
  OFN.lpstrFile := SzFile;
  OFN.nMaxFile := MAX_PATH;
  OFN.lpstrTitle := PWideChar(WideString(ATitle));
  OFN.lpstrDefExt := PWideChar(WideString('ress'));

  if AIsSave then
  begin
    OFN.Flags := OFN_EXPLORER or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT;
    if GetSaveFileNameW(@OFN) then
      Result := String(WideString(SzFile));
  end
  else
  begin
    OFN.Flags := OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST;
    if GetOpenFileNameW(@OFN) then
      Result := String(WideString(SzFile));
  end;

  if (User32Module <> 0) and Assigned(SetThreadDpiCtx) and (OldCtx <> 0) then
    SetThreadDpiCtx(OldCtx);

  if User32Module <> 0 then
    FreeLibrary(User32Module);
end;

class procedure TServiceCLI.ProcessRegistration(const BaseImages: TStringArray);
var
  TargetName, RootFS, DestPath, ErrMsg, Choice: String;
  ChoiceInt, ImageIndex: Integer;
begin
  if Length(BaseImages) = 0 then
  begin
    Writeln;
    Writeln('Error: Cannot register a new environment without a base image.');
    Writeln;
    Exit;
  end;

  Write('Enter a name for the new environment: ');
  Readln(TargetName);
  TargetName := CleanInput(TargetName);
  if TargetName = '' then Exit;

  if not IsValidDistroName(TargetName) then
  begin
    Writeln;
    Writeln('Error: Environment names must not contain spaces or special');
    Writeln('characters. Only alphanumeric characters, periods, underscores,');
    Writeln('and hyphens are permitted.');
    Writeln;
    Exit;
  end;

  if Length(BaseImages) = 1 then
  begin
    ImageIndex := 0;
  end
  else
  begin
    Write('Select a base image by number (1 to ', Length(BaseImages), '): ');
    Readln(Choice);
    Choice := CleanInput(Choice);
    ChoiceInt := StrToIntDef(Choice, 0);
    if (ChoiceInt < 1) or (ChoiceInt > Length(BaseImages)) then
    begin
      Writeln;
      Writeln('Invalid selection.');
      Writeln;
      Exit;
    end;
    ImageIndex := ChoiceInt - 1;
  end;

  RootFS := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + BaseImages[ImageIndex];
  DestPath := IncludeTrailingPathDelimiter(SysUtils.GetEnvironmentVariable('LOCALAPPDATA')) + APP_NAME + '\' + TargetName;

  Writeln;
  Writeln('Registering environment... please wait.');
  if TServiceWSL.ImportEnvironment(TargetName, DestPath, RootFS, ErrMsg) then
  begin
    Writeln;
    Writeln('Environment registered successfully.');
    Writeln;
  end
  else
  begin
    Writeln;
    Writeln('Error: Environment registration failed.');
    Writeln;
    PrintDiagnostic(ErrMsg);
    Writeln;
  end;
end;

class procedure TServiceCLI.ProcessImport;
var
  TargetName, RootFS, DestPath, ErrMsg, Choice: String;
begin
  Write('Enter a name for the imported environment: ');
  Readln(TargetName);
  TargetName := CleanInput(TargetName);
  if TargetName = '' then Exit;

  if not IsValidDistroName(TargetName) then
  begin
    Writeln;
    Writeln('Error: Environment names must not contain spaces or special');
    Writeln('characters. Only alphanumeric characters, periods, underscores,');
    Writeln('and hyphens are permitted.');
    Writeln;
    Exit;
  end;

  Writeln('Please select the .ress file from the dialog window...');
  RootFS := PromptForFile(False, 'Select Ouress Snapshot to Import');
  if RootFS = '' then Exit;

  DestPath := IncludeTrailingPathDelimiter(SysUtils.GetEnvironmentVariable('LOCALAPPDATA')) + APP_NAME + '\' + TargetName;

  Writeln;
  Writeln('Selected File: ', RootFS);
  Writeln;
  Writeln('IMPORTANT: This action will import a full execution environment.');
  Writeln('By default, Ouress environments possess read/write access to');
  Writeln('Windows files (via /mnt/) with the exact same privileges as the');
  Writeln('current Windows user account.');
  Writeln;
  Writeln('Only proceed if the .ress file is from a trusted source.');
  Writeln;
  Write('Proceed to import and register? (y/n): ');
  Readln(Choice);
  Choice := LowerCase(CleanInput(Choice));
  if (Choice <> 'y') and (Choice <> 'yes') then Exit;

  Writeln;
  Writeln('Importing and registering environment...');
  if TServiceWSL.ImportEnvironment(TargetName, DestPath, RootFS, ErrMsg) then
  begin
    Writeln;
    Writeln('Environment imported and registered successfully.');
    Writeln;
  end
  else
  begin
    Writeln;
    Writeln('Error: Environment import failed.');
    Writeln;
    PrintDiagnostic(ErrMsg);
    Writeln;
  end;
end;

class procedure TServiceCLI.ProcessExport(const Envs: TWSLEnvironmentArray);
var
  TargetName, DestPath, ErrMsg, Choice: String;
  ChoiceInt, CompLevel: Integer;
begin
  if Length(Envs) = 0 then
  begin
    Writeln;
    Writeln('No environments available to export.');
    Writeln;
    Exit;
  end;

  Write('Select environment to export by number (1 to ', Length(Envs), '): ');
  Readln(Choice);
  Choice := CleanInput(Choice);
  ChoiceInt := StrToIntDef(Choice, 0);
  if (ChoiceInt < 1) or (ChoiceInt > Length(Envs)) then
  begin
    Writeln;
    Writeln('Invalid selection.');
    Writeln;
    Exit;
  end;
  TargetName := Envs[ChoiceInt - 1].Name;

  Writeln;
  Writeln('Compression Level');
  Writeln('----------------------------------------------------------------------------------');
  Writeln(' [1] Minimum (fastest export; larger file size)');
  Writeln(' [2] Normal (balanced)');
  Writeln(' [3] Maximum (slowest export; smaller file size)');
  Writeln;
  Write('Select an option [1-3]: ');
  Readln(Choice);
  Choice := CleanInput(Choice);
  ChoiceInt := StrToIntDef(Choice, 0);
  if (ChoiceInt < 1) or (ChoiceInt > 3) then
  begin
    Writeln;
    Writeln('Invalid selection.');
    Writeln;
    Exit;
  end;

  case ChoiceInt of
    1: CompLevel := 0;
    2: CompLevel := 6;
    3: CompLevel := 9;
  else
    CompLevel := 6;
  end;

  Writeln;
  Writeln('Please select the destination from the dialog window...');
  DestPath := PromptForFile(True, 'Save Ouress Snapshot As');
  if DestPath = '' then Exit;

  Writeln;
  Writeln('Exporting data... please wait (this might take several minutes).');
  if TServiceWSL.ExportEnvironment(TargetName, DestPath, CompLevel, ErrMsg) then
  begin
    Writeln;
    Writeln('Environment exported successfully to:');
    Writeln(DestPath);
    Writeln;
  end
  else
  begin
    Writeln;
    Writeln('Error: Environment export failed.');
    Writeln;
    PrintDiagnostic(ErrMsg);
    Writeln;
  end;
end;

class procedure TServiceCLI.ProcessUnregister(const Envs: TWSLEnvironmentArray);
var
  Choice, TargetNamesStr, ErrMsg: String;
  DelParts: TStringList;
  Targets: TStringArray;
  ChoiceInt, I: Integer;
begin
  if Length(Envs) = 0 then
  begin
    Writeln;
    Writeln('No environments available to unregister.');
    Writeln;
    Exit;
  end;

  Write('Specify the environments to unregister by number (e.g. 1, 2): ');
  Readln(Choice);
  Choice := CleanInput(Choice);
  if Choice = '' then Exit;

  Targets := nil;

  DelParts := TStringList.Create;
  try
    DelParts.Delimiter := ',';
    DelParts.StrictDelimiter := True;
    DelParts.DelimitedText := Choice;

    for I := 0 to DelParts.Count - 1 do
    begin
      ChoiceInt := StrToIntDef(Trim(DelParts[I]), 0);
      if (ChoiceInt >= 1) and (ChoiceInt <= Length(Envs)) then
      begin
        SetLength(Targets, Length(Targets) + 1);
        Targets[High(Targets)] := Envs[ChoiceInt - 1].Name;
      end;
    end;
  finally
    DelParts.Free;
  end;

  if Length(Targets) = 0 then
  begin
    Writeln;
    Writeln('No valid environments selected.');
    Writeln;
    Exit;
  end;

  TargetNamesStr := '';
  for I := 0 to High(Targets) do
  begin
    if I = 0 then
      TargetNamesStr := '"' + Targets[I] + '"'
    else if I = High(Targets) then
      TargetNamesStr := TargetNamesStr + ' and "' + Targets[I] + '"'
    else
      TargetNamesStr := TargetNamesStr + ', "' + Targets[I] + '"';
  end;

  Writeln;
  Write('Proceed to unregister ', TargetNamesStr, '? (y/n): ');
  Readln(Choice);
  Choice := LowerCase(CleanInput(Choice));
  if (Choice = 'y') or (Choice = 'yes') then
  begin
    Writeln;
    for I := 0 to High(Targets) do
    begin
      if TServiceWSL.UnregisterEnvironment(Targets[I], ErrMsg) then
        Writeln('Unregistered: ', Targets[I])
      else
      begin
        Writeln('Error unregistering ', Targets[I], ':');
        PrintDiagnostic(ErrMsg);
      end;
    end;
    Writeln;
  end;
end;

class procedure TServiceCLI.HandleMenu;
var
  Choice: String;
  Envs: TWSLEnvironmentArray;
  BaseImages: TStringArray;
begin
  Envs := nil;
  repeat
    Writeln;
    ListInstances(Envs);
    BaseImages := GetBaseImages;
    ListBaseImagesDisplay(BaseImages);
    Writeln;

    Writeln('Menu');
    Writeln('----------------------------------------------------------------------------------');
    Writeln(' [1] Register New Environment');
    Writeln(' [2] Import Environment');
    Writeln(' [3] Export Environment');
    Writeln(' [4] Unregister Environment');
    Writeln(' [0] Exit');
    Writeln;
    Write('Select an option [0-4]: ');
    Readln(Choice);
    Choice := CleanInput(Choice);

    case Choice of
      '1': ProcessRegistration(BaseImages);
      '2': ProcessImport;
      '3': ProcessExport(Envs);
      '4': ProcessUnregister(Envs);
    end;
  until Choice = '0';
end;

class procedure TServiceCLI.Execute;
begin
  PrintHeader;
  EnsureWSLAvailable;
  HandleMenu;
end;

end.