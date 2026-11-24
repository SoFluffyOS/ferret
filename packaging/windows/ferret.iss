; Inno Setup 6 script for Ferret. scripts/package_windows.ps1 runs it as
;
;   ISCC.exe /DAppVersion=0.1.0 /DArch=x64 /DSourceDir=<stage> /DOutputDir=<out> ferret.iss
;
; <stage> holds the Flutter release bundle (ferret.exe, DLLs, data\) plus
; ferret-cli.exe and the MSVC runtime DLLs.
;
; Installs for the current user, with no admin rights, into
; %LOCALAPPDATA%\Programs\Ferret. "Install for all users" is still offered
; and asks for admin. The firewall task is the only step that elevates.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
; Windows file versions are numbers only: 0.2.0-beta.1 shows as 0.2.0.
#ifndef FileVersion
  #define FileVersion AppVersion
#endif
#ifndef Arch
  #define Arch "x64"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows-packages\stage"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\windows-packages"
#endif

[Setup]
AppId={{5B59C714-DD74-41F5-8B9E-1209ECA0CE73}
AppName=Ferret
AppVersion={#AppVersion}
AppVerName=Ferret {#AppVersion}
AppPublisher=SoFluffy
AppPublisherURL=https://github.com/simonpham/ferret
AppSupportURL=https://github.com/simonpham/ferret/issues
AppUpdatesURL=https://github.com/simonpham/ferret/releases
AppCopyright=SoFluffy, GPL-3.0
VersionInfoVersion={#FileVersion}
DefaultDirName={autopf}\Ferret
DefaultGroupName=Ferret
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
UsedUserAreasWarning=no
#if Arch == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
MinVersion=10.0.17763
OutputDir={#OutputDir}
OutputBaseFilename=Ferret-{#AppVersion}-{#Arch}-setup
SetupIconFile=..\..\apps\ferret\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ferret.exe
UninstallDisplayName=Ferret
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
WizardImageFile=wizard-100.bmp,wizard-200.bmp
WizardSmallImageFile=wizard-small-100.bmp,wizard-small-200.bmp
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
english.FirewallTask=Allow Ferret through Windows Firewall on private networks (asks for administrator)
english.SendToTask=Add Ferret to the Send to menu
english.NetworkGroup=Network:
english.ShortcutsGroup=Shortcuts:
english.FirewallFailed=Ferret couldn't add its firewall rules. You can do it later from Ferret: Add a device, then Check my network, then Allow through firewall.

[Tasks]
Name: "firewall"; Description: "{cm:FirewallTask}"; GroupDescription: "{cm:NetworkGroup}"
Name: "sendto"; Description: "{cm:SendToTask}"; GroupDescription: "{cm:ShortcutsGroup}"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:ShortcutsGroup}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Ferret"; Filename: "{app}\ferret.exe"; AppUserModelID: "io.sofluffy.ferret"
Name: "{usersendto}\Ferret"; Filename: "{app}\ferret.exe"; Parameters: "send"; IconFilename: "{app}\ferret.exe"; Tasks: sendto
Name: "{autodesktop}\Ferret"; Filename: "{app}\ferret.exe"; Tasks: desktopicon

; Keys Ferret writes itself, dropped on uninstall: the window's size and
; place, and what flutter_local_notifications registers for Ferret's
; AppUserModelID (modules/shell SystemNotifier).
[Registry]
Root: HKCU; Subkey: "Software\SoFluffy\Ferret"; Flags: uninsdeletekey dontcreatekey
Root: HKCU; Subkey: "Software\SoFluffy"; Flags: uninsdeletekeyifempty dontcreatekey
Root: HKCU; Subkey: "Software\Classes\AppUserModelId\io.sofluffy.ferret"; Flags: uninsdeletekey dontcreatekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\PushNotifications\Backup\io.sofluffy.ferret"; Flags: uninsdeletekey dontcreatekey

[Run]
Filename: "{app}\ferret.exe"; Description: "{cm:LaunchProgram,Ferret}"; Flags: nowait postinstall skipifsilent

[Code]
const
  RunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';

{ The same four rules as WindowsFirewallRules in packages/ferret_system:
  Ferret's port, the ports Ferret in a second account moves to, discovery
  and mDNS, inbound, on Private networks only.
  Each add first deletes a rule of the same name, so running it twice
  never leaves duplicates. }
function FirewallCommands(Add: Boolean): String;
begin
  if not Add then
  begin
    Result :=
      'netsh advfirewall firewall delete rule name="Ferret (47640/tcp)" & ' +
      'netsh advfirewall firewall delete rule name="Ferret other accounts (47642-47649/tcp)" & ' +
      'netsh advfirewall firewall delete rule name="Ferret discovery (47641/udp)" & ' +
      'netsh advfirewall firewall delete rule name="Ferret mDNS (5353/udp)"';
    exit;
  end;

  Result :=
    'netsh advfirewall firewall delete rule name="Ferret (47640/tcp)" >nul & ' +
    'netsh advfirewall firewall add rule name="Ferret (47640/tcp)" dir=in action=allow protocol=TCP localport=47640 profile=private & ' +
    'netsh advfirewall firewall delete rule name="Ferret other accounts (47642-47649/tcp)" >nul & ' +
    'netsh advfirewall firewall add rule name="Ferret other accounts (47642-47649/tcp)" dir=in action=allow protocol=TCP localport=47642-47649 profile=private & ' +
    'netsh advfirewall firewall delete rule name="Ferret discovery (47641/udp)" >nul & ' +
    'netsh advfirewall firewall add rule name="Ferret discovery (47641/udp)" dir=in action=allow protocol=UDP localport=47641 profile=private & ' +
    'netsh advfirewall firewall delete rule name="Ferret mDNS (5353/udp)" >nul & ' +
    'netsh advfirewall firewall add rule name="Ferret mDNS (5353/udp)" dir=in action=allow protocol=UDP localport=5353 profile=private';
end;

{ Reading rules needs no admin rights: netsh exits 1 when none match. }
function FirewallRulesExist(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(ExpandConstant('{sys}\netsh.exe'),
    'advfirewall firewall show rule name="Ferret (47640/tcp)"', '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

{ The "runas" verb shows the UAC prompt once for all the commands. False
  when the user says No. }
function RunElevated(Commands: String): Boolean;
var
  ResultCode: Integer;
begin
  Result := ShellExec('runas', ExpandConstant('{cmd}'), '/c ' + Commands, '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep <> ssPostInstall) or not WizardIsTaskSelected('firewall') then
    exit;

  if not RunElevated(FirewallCommands(True)) or not FirewallRulesExist() then
    SuppressibleMsgBox(CustomMessage('FirewallFailed'), mbInformation, MB_OK, IDOK);
end;

{ Removes what Ferret added outside its folder: the firewall rules, whether
  the installer or the app's Allow through firewall made them, and the Run
  value behind Start at login. ~\.sofluffy\ferret (keys, paired devices,
  settings) stays, so a reinstall keeps your devices. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep <> usUninstall then
    exit;

  if FirewallRulesExist() then
    RunElevated(FirewallCommands(False));

  RegDeleteValue(HKEY_CURRENT_USER, RunKey, 'Ferret');
end;
