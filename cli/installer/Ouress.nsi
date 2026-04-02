; BSD 3-Clause License
; ____________________
; 
; Copyright © 2026, Jaisal E. K.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
; 
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
; 
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WordFunc.nsh"

Unicode true
ManifestDPIAware true
ManifestSupportedOS Win10

!define APP_NAME "Ouress"
!define APP_EXE "Ouress.exe"

!getdllversion "..\..\bin\${APP_EXE}" ext_ver_
!define APP_VERSION "${ext_ver_1}.${ext_ver_2}.${ext_ver_3}"
!define APP_BUILD "${ext_ver_4}"

!define APP_PUBLISHER "Jaisal E. K."
!define APP_WEBSITE "https://ouress.jaisal.in"
!define APP_COPYRIGHT_YEAR "2026"
!define APP_COMMENT "An Opinionated Underlabouring Research Environment for the Social Sciences"
!define APP_GUID "{A182689B-F2CA-4889-A271-B0B605038533}"

Name "${APP_NAME}"
!system 'cmd.exe /c if not exist "..\..\releases" mkdir "..\..\releases"'
OutFile "..\..\releases\${APP_NAME}-v${APP_VERSION}-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\${APP_NAME}"
RequestExecutionLevel user
SetCompressor lzma

SetFont "Arial" 9

VIProductVersion "${APP_VERSION}.${APP_BUILD}"
VIAddVersionKey /LANG=2057 "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=2057 "Comments" "${APP_COMMENT}"
VIAddVersionKey /LANG=2057 "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey /LANG=2057 "LegalCopyright" "© ${APP_COPYRIGHT_YEAR} ${APP_PUBLISHER}"
VIAddVersionKey /LANG=2057 "FileDescription" "${APP_NAME} Setup"
VIAddVersionKey /LANG=2057 "FileVersion" "${APP_VERSION}.${APP_BUILD}"
VIAddVersionKey /LANG=2057 "ProductVersion" "${APP_VERSION}"

BrandingText "${APP_PUBLISHER}"

!define MUI_ICON "..\Ouress.ico"
!define MUI_UNICON "..\Ouress.ico"
!define MUI_ABORTWARNING

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"

!define MUI_WELCOMEPAGE_TEXT "Setup will guide you through the installation of ${APP_NAME}.$\r$\n$\r$\nClick Next to continue."

!define MUI_FONT_NAME "Arial"
!define MUI_FONT_SIZE "9"

!insertmacro MUI_PAGE_WELCOME

!define MUI_PAGE_CUSTOMFUNCTION_SHOW LicenseShow
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchApplication
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

LangString ^BackBtn ${LANG_ENGLISH} "&Back"
LangString ^NextBtn ${LANG_ENGLISH} "&Next"

Function .onInit
  SetRegView 64
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "DisplayVersion"
  ${If} $0 != ""
    ${VersionCompare} $0 "${APP_VERSION}" $1
    ${If} $1 == 1
      MessageBox MB_YESNO|MB_ICONEXCLAMATION|MB_DEFBUTTON2 "A newer version of ${APP_NAME} ($0) is already installed on this system.$\n$\nConfirm downgrade to version ${APP_VERSION}?" IDYES +2
      Abort
    ${ElseIf} $1 == 0
      MessageBox MB_YESNO|MB_ICONQUESTION "Version ${APP_VERSION} of ${APP_NAME} is already installed.$\n$\nReinstall?" IDYES +2
      Abort
    ${EndIf}
  ${EndIf}
FunctionEnd

Function LicenseShow
  FindWindow $0 "#32770" "" $HWNDPARENT
  GetDlgItem $0 $0 1000
  CreateFont $1 "Consolas" 8 700
  SendMessage $0 0x0030 $1 1
FunctionEnd

Function CloseRunningInstance
  IfFileExists "$INSTDIR\${APP_EXE}" 0 Done
  CheckLock:
    ClearErrors
    FileOpen $0 "$INSTDIR\${APP_EXE}" a
    IfErrors Locked Free
  Locked:
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "${APP_NAME} is currently running. Please close the application window and click Retry to continue the installation." IDRETRY CheckLock IDCANCEL AbortInstall
  Free:
    FileClose $0
    Goto Done
  AbortInstall:
    Quit
  Done:
FunctionEnd

Section "Install"
  SetRegView 64

  Call CloseRunningInstance

  SetOutPath "$INSTDIR"
  
  File "..\..\bin\${APP_EXE}"
  File "..\..\LICENSE"
  File "..\..\NOTICE"

  SetOverwrite off
  File "..\..\releases\ouress-v${APP_VERSION}.ress"
  SetOverwrite on

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  SetShellVarContext current
  CreateShortcut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "URLInfoAbout" "${APP_WEBSITE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "URLUpdateInfo" "${APP_WEBSITE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "HelpLink" "${APP_WEBSITE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "Comments" "${APP_COMMENT}"

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "EstimatedSize" "$0"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetRegView 64

  Call un.CloseRunningInstance

  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\NOTICE"
  Delete "$INSTDIR\ouress-v${APP_VERSION}.ress"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"

  SetShellVarContext current
  Delete "$SMPROGRAMS\${APP_NAME}.lnk"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_GUID}"
SectionEnd

Function un.CloseRunningInstance
  IfFileExists "$INSTDIR\${APP_EXE}" 0 Done
  CheckLock:
    ClearErrors
    FileOpen $0 "$INSTDIR\${APP_EXE}" a
    IfErrors Locked Free
  Locked:
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "${APP_NAME} is currently running. Please close the application window and click Retry to continue the uninstallation." IDRETRY CheckLock IDCANCEL AbortUninstall
  Free:
    FileClose $0
    Goto Done
  AbortUninstall:
    Quit
  Done:
FunctionEnd

Function LaunchApplication
  System::Call 'user32::AllowSetForegroundWindow(i -1)'
  Exec '"$INSTDIR\${APP_EXE}"'
FunctionEnd