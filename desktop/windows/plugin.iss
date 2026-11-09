; OBS Blade Remote plugin installer: into OBS's plugin folder for all users
; (C:\ProgramData\obs-studio\plugins\obs-blade-remote, OBS 30+), admin.
;   ISCC /DVersion=0.4.0 /DSourceDir=<cmake install prefix holding obs-blade-remote\> /DOutputDir=<dir> plugin.iss
#define AppName "OBS Blade Remote plugin"

[Setup]
AppId={{2F7B9D44-6A1C-4E8B-B3D2-91C0A5E6F870}
AppName={#AppName}
AppVersion={#Version}
AppPublisher=Kounex
AppPublisherURL=https://obs-blade.kounex.com
AppSupportURL=https://github.com/Kounex/obs_blade/issues
DefaultDirName={commonappdata}\obs-studio\plugins\obs-blade-remote
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=obs-blade-remote-plugin-windows-x64-setup
SetupIconFile=..\standalone\resources\app.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile=..\..\LICENSE.md
UninstallFilesDir={app}\uninstall

[Files]
Source: "{#SourceDir}\obs-blade-remote\*"; DestDir: "{app}"; Excludes: "*.pdb"; Flags: recursesubdirs ignoreversion

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if CheckForMutexes('OBSStudioCore') then
  begin
    MsgBox('Please close OBS before installing the plugin.', mbInformation, MB_OK);
    Result := False;
  end;
end;
