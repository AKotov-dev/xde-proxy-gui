unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  Process, DefaultTranslator, XMLPropStorage, ExtCtrls, IniFiles, lcltype;

type

  { TMainForm }

  TMainForm = class(TForm)
    Edit7: TEdit;
    Edit8: TEdit;
    Image1: TImage;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    RadioGroup1: TRadioGroup;
    DefaultBtn: TSpeedButton;
    ClearBtn: TSpeedButton;
    StaticText1: TStaticText;
    CheckBox2: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ApplyBtn: TSpeedButton;
    XMLPropStorage1: TXMLPropStorage;
    procedure CheckBox2Change(Sender: TObject);
    procedure DefaultBtnClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit4KeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure StartProcess(command: string);

  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SNoUtils =
    'gsettings or dconf not found!';
  SModeAuto = 'Auto';
  SModeManual = 'Manual';
  SModeNone = 'None';
  SLXDEConfMsg =
    'LXDE:' + #13#13 +
    'XDG_CURRENT_DESKTOP=GNOME:LXDE will be added to the [Environment_variable] ' +
    'section of the ~/.config/lxsession/LXDE/desktop.conf file. ' +
    'You will then need to log out or reboot your computer. ' + #13#10 +
    #13#10 + 'Are you sure you want to make changes?';

implementation

{$R *.lfm}

{ TMainForm }

//StartCommand
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Если есть LXDE - вставка окружения в пользовательские настройки
procedure EnsureLXDEDesktopEnv;
var
  SystemConf: string;
  UserConfDir: string;
  UserConfFile: string;
  Ini: TIniFile;
begin
  // 1. Проверка наличия LXDE в системе
  SystemConf := '/etc/xdg/lxsession/LXDE/desktop.conf';
  if not FileExists(SystemConf) then
    Exit; // LXDE не установлен — ничего не делаем

  // 2. Пути пользователя
  UserConfDir := GetEnvironmentVariable('HOME') + '/.config/lxsession/LXDE';
  UserConfFile := UserConfDir + '/desktop.conf';

  // 3. Создаём каталог при необходимости
  if not DirectoryExists(UserConfDir) then
    ForceDirectories(UserConfDir);

  // 4. Работаем с ini-файлом; Вставляем секцию с запросом на relogin
  Ini := TIniFile.Create(UserConfFile);
  try
    if Ini.ReadString('Environment_variable', 'XDG_CURRENT_DESKTOP', '') <>
      'GNOME:LXDE' then
      if MessageDlg(SLXDEConfMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        // 5. Жёстко фиксируем комбинированный XDG_CURRENT_DESKTOP
        Ini.WriteString('Environment_variable',
          'XDG_CURRENT_DESKTOP',
          'GNOME:LXDE');
  finally
    Ini.Free;
  end;
end;

//Преобразование для отправки в gsettings
function HumanToGSettingsList(const S: string): string;
var
  Items: TStringList;
  i: integer;
begin
  Items := TStringList.Create;
  try
    Items.CommaText := Trim(S);
    for i := 0 to Items.Count - 1 do
      Items[i] := Trim(Items[i]);

    Result := '[';
    for i := 0 to Items.Count - 1 do
    begin
      if i > 0 then Result := Result + ', ';
      Result := Result + QuotedStr(Items[i]);
    end;
    Result := Result + ']';
  finally
    Items.Free;
  end;
end;

//Применить
procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  S: string;
begin
  //Проверяем наличие утилит "gsettings" и "dconf"
  if RunCommand('bash', ['-c',
    'if command -v gsettings &>/dev/null && command -v dconf &>/dev/null; then echo "yes"; fi'],
    S) then
    if Trim(S) <> 'yes' then
    begin
      MessageDlg(SNoUtils, mtWarning, [mbOK], 0);
      Exit;
    end;

  //Индикатор
  Label7.Visible := True;

  //Проверяем/вставляем запись в ~/.bashrc для передёргивания /etc/profile.s/proxy-sync.sh (XUbuntu)
  RunCommand('/bin/bash', ['-c',
    'grep -qxF ''[ -r /etc/profile.d/proxy-sync.sh ] && source /etc/profile.d/proxy-sync.sh'' ~/.bashrc || echo ''[ -r /etc/profile.d/proxy-sync.sh ] && source /etc/profile.d/proxy-sync.sh'' >> ~/.bashrc'], S);

  //LXDE? Экспорт XDG_CURRENT_DESKTOP=GNOME через ~/.config/lxsession/LXDE/desktop.conf
  //https://github.com/lxde/lxsession/blob/master/data/desktop.conf.example
  EnsureLXDEDesktopEnv;

  //Use same proxy
  if CheckBox2.Checked then
    RunCommand('bash', ['-c',
      'gsettings set org.gnome.system.proxy use-same-proxy true'], S)
  else
    RunCommand('bash', ['-c',
      'gsettings set org.gnome.system.proxy use-same-proxy false'], S);

  //Проверяем на пустоту список ignore-hosts (пусто = Default)
  if Trim(Edit7.Text) = '' then DefaultBtn.Click;

  //Настраиваем proxy
  case RadioGroup1.ItemIndex of
    //auto - Режим PAC (параметры не учитываются, только PAC url)
    0:
    begin
      S := 'gsettings set org.gnome.system.proxy mode "auto"; ' +
        'gsettings set org.gnome.system.proxy autoconfig-url "' +
        Trim(Edit8.Text) + '"; ' +
        'gsettings set org.gnome.system.proxy ignore-hosts "' +
        HumanToGSettingsList(Edit7.Text) + '"';
    end;

    //manual - ручная установка параметров
    1:
    begin
      //Есть ли пустые порты? Ставим '0'
      if Trim(Edit4.Text) = '' then Edit4.Text := '0';
      if Trim(Edit5.Text) = '' then Edit5.Text := '0';
      if Trim(Edit6.Text) = '' then Edit6.Text := '0';

      S := 'gsettings set org.gnome.system.proxy mode "manual";' +
        'gsettings set org.gnome.system.proxy.http host "' +
        Trim(Edit1.Text) + '";' + 'gsettings set org.gnome.system.proxy.http port "' +
        Trim(Edit4.Text) + '";' + 'gsettings set org.gnome.system.proxy.https host "' +
        Trim(Edit2.Text) + '";' + 'gsettings set org.gnome.system.proxy.https port "' +
        Trim(Edit5.Text) + '";' + 'gsettings set org.gnome.system.proxy.ftp host "' +
        Trim(Edit1.Text) + '";' + 'gsettings set org.gnome.system.proxy.ftp port "' +
        Trim(Edit4.Text) + '";' + 'gsettings set org.gnome.system.proxy.socks host "' +
        Trim(Edit3.Text) + '";' + 'gsettings set org.gnome.system.proxy.socks port "' +
        Trim(Edit6.Text) + '";' + 'gsettings set org.gnome.system.proxy ignore-hosts "' +
        HumanToGSettingsList(Edit7.Text) + '"';
    end;

    //Отключаем proxy (настройки не удаляем)
    2: S := 'gsettings set org.gnome.system.proxy mode "none"';
  end;

  Application.ProcessMessages;
  StartProcess(S);
  Label7.Visible := False;
end;

procedure TMainForm.RadioGroup1Click(Sender: TObject);
begin
  case RadioGroup1.ItemIndex of
    0: //auto
    begin
      GroupBox1.Enabled := False;
      Label9.Enabled := True;
      Edit7.Enabled := False;
      DefaultBtn.Enabled := False;
      Edit8.Enabled := True;
      ClearBtn.Enabled := True;
    end;
    1: //manual
    begin
      GroupBox1.Enabled := True;
      Label8.Enabled := True;
      Edit7.Enabled := True;
      DefaultBtn.Enabled := True;
      Label9.Enabled := False;
      Edit8.Enabled := False;
      ClearBtn.Enabled := False;
    end;
    2: //none
    begin
      GroupBox1.Enabled := False;
      Label8.Enabled := False;
      Edit7.Enabled := False;
      DefaultBtn.Enabled := False;
      Label9.Enabled := False;
      Edit8.Enabled := False;
      ClearBtn.Enabled := False;
    end;
  end;
end;

//Clear PAC URL
procedure TMainForm.ClearBtnClick(Sender: TObject);
begin
  Edit8.Clear;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
begin
  XMLPropStorage1.FileName := GetUserDir + '.config/xde-proxy-gui.conf';
  XMLPropStorage1.Active := True;

  MainForm.Caption := Application.Title;

  //Устраняем баг иконки приложения
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Assign(Image1.Picture.Graphic);
    Application.Icon.Assign(bmp);
  finally
    bmp.Free;
  end;
end;

//Обработка нажатия кнопок
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN: ApplyBtn.Click;
    VK_Escape: Close;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  S: string;
begin
  //Для KDE
  XMLPropStorage1.Restore;

  DefaultBtn.Width := Edit7.Height;
  ClearBtn.Width := Edit8.Height;

  //Режимы с переводом
  RadioGroup1.Items[0] := SModeAuto;
  RadioGroup1.Items[1] := SModeManual;
  RadioGroup1.Items[2] := SModeNone;

  //--Чтение параметров--
  //Mode
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy mode'], S) then
  begin
    S := Trim(StringReplace(S, '''', '', [rfReplaceAll]));
    case S of
      'auto': RadioGroup1.ItemIndex := 0;
      'manual': RadioGroup1.ItemIndex := 1;
      'none': RadioGroup1.ItemIndex := 2;
    end;
  end;

  //HTTP host
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.http host'], S) then
    Edit1.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));
  //HTTP port
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.http port'], S) then
    Edit4.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));

  //HTTPS host
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.https host'],
    S) then
    Edit2.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));
  //HTTPS port
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.https port'],
    S) then
    Edit5.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));

  //SOCKS host
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.socks host'],
    S) then
    Edit3.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));
  //SOCKS port
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy.socks port'],
    S) then
    Edit6.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));

  //Use same proxy
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy use-same-proxy'],
    S) then
    if Trim(S) = 'true' then CheckBox2.Checked := True;

  //Ignore hosts (убираем апострофы и скобки)
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy ignore-hosts'],
    S) then
  begin
    S := StringReplace(S, '''', '', [rfReplaceAll]);
    S := StringReplace(S, '[', '', [rfReplaceAll]);
    S := StringReplace(S, ']', '', [rfReplaceAll]);
    Edit7.Text := Trim(S);
  end;

  //Autoconfig URL (PAC)
  if RunCommand('bash', ['-c', 'gsettings get org.gnome.system.proxy autoconfig-url'],
    S) then
    Edit8.Text := Trim(StringReplace(S, '''', '', [rfReplaceAll]));
end;

//Дублировать HTTP => HTTPS (вкл. default)
procedure TMainForm.CheckBox2Change(Sender: TObject);
begin
  if CheckBox2.Checked then
  begin
    Edit2.Text := Edit1.Text;
    Edit5.Text := Edit4.Text;
  end;
end;

//Default Ignore hosts
procedure TMainForm.DefaultBtnClick(Sender: TObject);
begin
  Edit7.Text := 'localhost, 127.0.0.0/8, ::1';
end;

procedure TMainForm.Edit1Change(Sender: TObject);
begin
  if CheckBox2.Checked then
  begin
    Edit2.Text := Edit1.Text;
    Edit5.Text := Edit4.Text;
  end;
end;

//Порт: Вводим только цифры
procedure TMainForm.Edit4KeyPress(Sender: TObject; var Key: char);
begin
  // проверяем нажатую клавишу
  case Key of
    // цифры разрешаем
    '0'..'9': key := key;
    // разрешаем десятичный разделитель (только точку)
    //'.', ',': key:='.';
    // разрешаем BackSpace
    #8: key := key;
      // все прочие клавиши "гасим"
    else
      key := #0;
  end;
end;

end.
