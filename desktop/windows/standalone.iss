; OBS Blade Remote (standalone) installer - per user, no admin prompt.
;   ISCC /DVersion=0.4.0 /DSourceDir=<folder with obs-blade-remote.exe + Qt> /DOutputDir=<dir> standalone.iss
; Keeps the user's pairing (%APPDATA%\obs-blade-remote) on uninstall.
#define AppName "OBS Blade Remote"
#define AppExe "obs-blade-remote.exe"

[Setup]
AppId={{8C1E5A0B-3F64-4C7A-9C55-0B1E4D2A7F31}
AppName={#AppName}
AppVersion={#Version}
AppPublisher=Kounex
AppPublisherURL=https://obs-blade.kounex.com
AppSupportURL=https://github.com/Kounex/obs_blade/issues
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=OBS-Blade-Remote-windows-x64-setup
SetupIconFile=..\standalone\resources\app.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
LicenseFile=..\..\LICENSE.md

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"

[Registry]
; Created by the app ("Start at login", on by default) - removed with it
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "{#AppName}"; Flags: uninsdeletevalue dontcreatekey
Root: HKCU; Subkey: "Software\Kounex\{#AppName}"; ValueType: none; Flags: uninsdeletekey dontcreatekey

[Run]
Filename: "{app}\{#AppExe}"; Description: "Start {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM {#AppExe}"; Flags: runhidden; RunOnceId: "StopApp"
