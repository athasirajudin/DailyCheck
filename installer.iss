; =========================
; Inno Setup Script
; DailyCheck (Flutter Windows)
; =========================

#define MyAppName "DailyCheck"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

[Setup]
AppId={{C12F514E-9A95-4D63-8E41-87A17E3CF5BD}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Lemhannas RI
AppPublisherURL=https://lemhannas.go.id
AppSupportURL=https://lemhannas.go.id
AppUpdatesURL=https://lemhannas.go.id

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputDir=output
OutputBaseFilename={#MyAppName}-Setup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

LicenseFile=license.txt
DisableProgramGroupPage=yes
PrivilegesRequired=admin

SetupIconFile={#SourcePath}windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Aktifkan lagi jika file Indonesian.isl tersedia di folder Inno Setup\Languages
; Name: "indonesian"; MessagesFile: "compiler:Languages\Indonesian.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "startmenuicon"; Description: "Create a &Start Menu shortcut"; GroupDescription: "Additional icons:"; Flags: checkedonce

[Files]
; Copy seluruh output Flutter Windows Release
Source: "{#SourcePath}build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourcePath}README.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourcePath}CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\DailyCheck.exe"; Tasks: startmenuicon
Name: "{group}\README"; Filename: "{app}\README.md"; Tasks: startmenuicon
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\DailyCheck.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\DailyCheck.exe"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
