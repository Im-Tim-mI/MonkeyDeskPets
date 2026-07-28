#define AppName "MonkeyDeskPets"
#define AppPublisher "廷廷小教室、廷廷的家（Tim945）"
#define AppURL "https://github.com/Im-Tim-mI/MonkeyDeskPets"

[Setup]
AppId={{D6104A60-B605-4D82-99B5-32AB78F47461}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\MonkeyDeskPets.exe
OutputDir={#OutputDir}
OutputBaseFilename=MonkeyDeskPets-Windows-{#Runtime}-Setup-v{#AppVersion}
SetupIconFile={#SourcePath}\..\src\MonkeyDeskPets.Windows\Assets\MonkeyDeskPets.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed={#AllowedArchitectures}
ArchitecturesInstallIn64BitMode={#AllowedArchitectures}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "{#SourcePath}\LICENSE-en.txt"
Name: "chinesetraditional"; MessagesFile: "{#SourcePath}\ChineseTraditional.isl"; LicenseFile: "{#SourcePath}\LICENSE-zh-TW.txt"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "開機時自動啟動 / Start with Windows"; Flags: unchecked

[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MonkeyDeskPets"; Filename: "{app}\MonkeyDeskPets.exe"
Name: "{autodesktop}\MonkeyDeskPets"; Filename: "{app}\MonkeyDeskPets.exe"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonkeyDeskPets"; ValueData: """{app}\MonkeyDeskPets.exe"""; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\MonkeyDeskPets.exe"; Description: "{cm:LaunchProgram,MonkeyDeskPets}"; Flags: nowait postinstall skipifsilent
