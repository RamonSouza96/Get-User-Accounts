unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Objects,

  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.JNI.Provider,
  System.Permissions,
  Androidapi.JNI.Os,
  Androidapi.JNI.Accounts,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  Androidapi.JNI.App,
  System.Messaging;


type
  TForm1 = class(TForm)
    Rectangle1: TRectangle;
    mmLog: TMemo;
    RectSave: TRectangle;
    BtnGetAccountContacts: TSpeedButton;
    Rectangle2: TRectangle;
    SpeedButton2: TSpeedButton;
    Rectangle3: TRectangle;
    SpeedButton1: TSpeedButton;
    procedure BtnGetAccountContactsClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    function OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent): Boolean;  //IMPORTANTE
    procedure HandleActivityMessage(const Sender: TObject; const M: TMessage); //IMPORTANTE
  private
    const REQUEST_CODE_PICK_ACCOUNT = 1002;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.BtnGetAccountContactsClick(Sender: TObject);
var
  CContacts : JCursor;
  vAccount_name:string;
begin

  mmLog.Lines.Clear;
  PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.READ_CONTACTS)], nil);

  try

    CContacts :=  TAndroidHelper.Activity.getContentResolver.query(TJContactsContract_RawContacts.JavaClass.CONTENT_URI,nil,nil,nil,nil);

     TThread.CreateAnonymousThread(
      procedure
      begin

          while (CContacts.moveToNext) do
        begin

           if (vAccount_name <> JStringToString(CContacts.getString(CContacts.getColumnIndex(StringToJString('account_name')))))
           and (JStringToString(CContacts.getString(CContacts.getColumnIndex(StringToJString('account_type_and_data_set')))) = 'com.google') then
           Begin

             vAccount_name := JStringToString(CContacts.getString(CContacts.getColumnIndex(StringToJString('account_name'))));
              if Pos(vAccount_name, mmLog.Lines.Text) = 0 then
              Begin

                TThread.Synchronize(TThread.CurrentThread,
                 procedure
                 begin
                  mmLog.Lines.Add(vAccount_name);
                 end);

              End;

           End;

        end;

         CContacts.close;

      end).Start;

  finally
  end;

end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
 Intent : JIntent;
 jAm: JAccountManager;
 accounts: TJavaObjectArray<JAccount>;
 jAcc: JAccount;
 i:integer;
begin

  mmLog.Lines.Clear;
  //PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.GET_ACCOUNTS)], nil);

  jAm := TJAccountManager.JavaClass.get(SharedActivityContext);

  if jAm <> nil then
  begin

    Accounts := TJavaObjectArray<JAccount>.Wrap(jAm.getAccountsByType(StringToJString('com.google')));
     // Accounts := TJavaObjectArray<JAccount>.Wrap(jAm.getAccounts);

    if Accounts <> nil then
    begin

      mmLog.Lines.Add('Length Accounts: ' + IntToStr(Accounts.Length));

      if Accounts.Length > 0 then
      begin

        for I := 0 to Accounts.Length -1 do
        Begin

          jAcc := Accounts.Items[i];
          mmLog.Lines.Add(JStringToString(jAcc._Getname));

        End;


      end
      else
      begin
        mmLog.Lines.Add('no accounts available');
      end;

    end;
  end
  else
  begin
    mmLog.Lines.Add('no accounts found');
  end;

end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  Intent:JIntent;
begin

  mmLog.Lines.Clear;
  TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification, HandleActivityMessage);
  Intent:=TJAccountManager.JavaClass.newChooseAccountIntent(nil,nil,nil,nil,nil,nil,nil);
  SharedActivity.startActivityForResult(Intent,REQUEST_CODE_PICK_ACCOUNT);

end;

procedure TForm1.HandleActivityMessage(const Sender: TObject; const M: TMessage); //IMPORTANTE
begin

  if M is TMessageResultNotification then
   begin

     OnActivityResult(TMessageResultNotification(M).RequestCode,
                      TMessageResultNotification(M).ResultCode,
                      TMessageResultNotification(M).Value);
   end;

end;

function TForm1.OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent): Boolean;  //IMPORTANTE
var
 Acc: JAccountManager;
begin

  TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, HandleActivityMessage);

  if RequestCode = REQUEST_CODE_PICK_ACCOUNT then
  begin

    if ResultCode = TJActivity.JavaClass.RESULT_OK then
    begin
      if Assigned(Data) then
      Begin
        mmLog.Lines.Add('KEY_ACCOUNT_NAME: '+JStringToString(Data.getStringExtra(TJAccountManager.JavaClass.KEY_ACCOUNT_NAME)));
        mmLog.Lines.Add('KEY_ACCOUNT_TYPE: '+JStringToString(Data.getStringExtra(TJAccountManager.JavaClass.KEY_ACCOUNT_TYPE)));
      End;
      Invalidate;

    end;

  end;
end;

end.
