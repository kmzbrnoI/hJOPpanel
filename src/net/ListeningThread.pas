unit ListeningThread;

{
  Poslouchaci vlakno TCP spojeni
}

interface

uses
  Classes, IdTCPClient, SysUtils, IdException;

type
  TDataEvent = procedure(const Data: string) of object;
  TErrorEvent = procedure() of object;

  TReadingThread = class(TThread)
  private
    FClient: TIdTCPClient;
    FData: string;
    FOnData: TDataEvent;
    FOnError: TErrorEvent;
    FOnTimeout: TErrorEvent;
    procedure DataReceived;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TIdTCPClient); reintroduce;
    property OnData: TDataEvent read FOnData write FOnData;
    property OnError: TErrorEvent read FOnError write FOnError;
    property OnTimeout: TErrorEvent read FOnTimeout write FOnTimeout;
  end;

implementation

constructor TReadingThread.Create(AClient: TIdTCPClient);
begin
  inherited Create(True);
  FClient := AClient;
end;

procedure TReadingThread.Execute;
begin
  while (not Terminated) do
  begin
    try
      FData := FClient.IOHandler.ReadLn();
    except
      on E: EIdConnClosedGracefully do
      begin
        if ((Assigned(FOnTimeout)) and (not Terminated)) then
          Synchronize(FOnTimeout);
        Exit();
      end;
      on E: Exception do
      begin
        if ((Assigned(FOnError)) and (not Terminated)) then
          Synchronize(FOnError);
        Exit();
      end;
    end;
    if (FData <> '') and Assigned(FOnData) then
      Synchronize(DataReceived);
  end;
end;

procedure TReadingThread.DataReceived;
begin
  if Assigned(FOnData) then
    FOnData(FData);
end;

end.
