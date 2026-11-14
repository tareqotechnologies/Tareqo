; Instalador Windows do TAREQO.
; Gere primeiro o build com: flutter build windows --release
; Compile este ficheiro no Inno Setup Compiler.

#define AppName "TAREQO"
#define AppVersion "2.6.0"
#define AppPublisher "TAREQO"
#define AppExeName "tareqo.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{C48C982B-87D2-4E20-994F-A35AE2937641}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\TAREQO
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
SetupIconFile=..\windows\runner\resources\app_icon.ico
OutputDir=..\build\installer
OutputBaseFilename=tareqo-setup-{#AppVersion}-windows-x64
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
DisableProgramGroupPage=yes
WizardStyle=modern
CloseApplications=yes
Compression=lzma2
SolidCompression=yes
SetupLogging=yes

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho no ambiente de trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Abrir o TAREQO"; Flags: postinstall nowait skipifsilent
