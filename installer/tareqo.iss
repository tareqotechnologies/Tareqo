; TAREQO Windows x64 installer
; Build the Flutter release before compiling this script (see README.md).

#define AppName "Tareqo"
#define AppVersion "2.6.0"
#define AppPublisher "TAREQO"
#define AppExeName "tareqo.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{C48C982B-87D2-4E20-994F-A35AE2937641}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={autopf}\Tareqo
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
SetupIconFile=..\windows\runner\resources\app_icon.ico
OutputDir=..\dist
OutputBaseFilename=TAREQO_SETUP
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.10240
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
DisableProgramGroupPage=yes
WizardStyle=modern
CloseApplications=yes
Compression=lzma2/ultra64
SolidCompression=yes
SetupLogging=yes
Uninstallable=yes
UninstallFilesDir={app}\{#AppName} Uninstaller
UsePreviousAppDir=yes
; The app's SQLite database is stored in the user's Documents folder, outside {app}.
; Updating/uninstalling therefore leaves user data intact.

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; Remove stale Flutter assets left by older builds before copying the current bundle.
Type: filesandordirs; Name: "{app}\data"

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Iniciar o Tareqo"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
; Flutter resources are application files; the SQLite database lives in Documents.
Type: filesandordirs; Name: "{app}\data"
