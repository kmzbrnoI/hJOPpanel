unit InterProcessCom;

{
  Inter-process communication for sharing logins between running instances
  of panel.

  Sadly, the implementation of the real inter-process communication must be
  be bound to a form, so this class just calls methods of F_Main.
}

interface

uses SysUtils, JclAppInst, Classes;

const
  _IPC_MYID = 42865;

type
  TIPC = class(TObject)
  private
    parsed:TStrings;
    connect_wait: boolean;
    connect_time: TDateTime;

    function SendData(data:string):Boolean;
    procedure BroadcastLogin(username:string; password:string);

  public
    username:string;
    password:string;

    constructor Create();
    destructor Destroy(); override;

    procedure ParseData(data:string);
    function InstanceCnt():Integer;
    procedure Update();

    procedure CheckAuth();

  end;

var
  IPC: TIPC;

implementation

uses fMain, GlobalConfig, Panel, TCPClientPanel, parseHelper;

////////////////////////////////////////////////////////////////////////////////

constructor TIPC.Create();
begin
 inherited;
 Self.parsed := TStringList.Create();
end;

destructor TIPC.Destroy();
begin
 Self.parsed.Free();
 inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TIPC.ParseData(data:string);
begin
 Self.parsed.Clear();
 ExtractStringsEx([';'], [#13, #10], data, Self.parsed);

 try
   if ((parsed.Count = 3) and (parsed[0] = 'LOGIN') and (GlobConfig.data.auth.ipc_receive)) then
    begin
     GlobConfig.data.auth.username := parsed[1];
     GlobConfig.data.auth.password := parsed[2];
     GlobConfig.data.auth.autoauth := true;
     GlobConfig.data.auth.forgot := true;

     // pockame nahodny cas, abychom server nezatezovali velkym poctem novych spojeni...
     if (PanelTCPClient.status = TPanelConnectionStatus.closed) then
       Self.connect_time := Now + EncodeTime(0, 0, 0, Random(799)+200)
     else
       Self.connect_time := Now + EncodeTime(0, 0, 0, Random(200));

     Self.connect_wait := true;
    end;
 except

 end;
end;

////////////////////////////////////////////////////////////////////////////////

function TIPC.SendData(data:string):Boolean;
begin
 Result := JclAppInstances.SendString(F_Main.ClassName, _IPC_MYID, data, F_Main.Handle);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TIPC.BroadcastLogin(username:string; password:string);
begin
 Self.SendData('LOGIN;{'+username+'};{'+password+'}');
end;

////////////////////////////////////////////////////////////////////////////////

function TIPC.InstanceCnt():Integer;
begin
 Result := JclAppInstances.InstanceCount;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TIPC.CheckAuth();
begin
 if ((Self.username <> '') and (Self.password <> '')) then
   Self.BroadcastLogin(Self.username, Self.password);

 Self.username := '';
 Self.password := '';
end;

////////////////////////////////////////////////////////////////////////////////

procedure TIPC.Update();
begin
 if ((Self.connect_wait) and (Now > Self.connect_time)) then
  begin
   Self.connect_wait := false;
   Relief.IPAAuth();
  end;
end;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

initialization
  IPC := TIPC.Create();

finalization
  FreeAndNil(IPC);

end.
