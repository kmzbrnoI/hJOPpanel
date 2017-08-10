unit ListeningThread;

{
  Poslouchaci vlakno TCP spojeni
}

interface

uses
  Classes, IdTCPClient;

type
  TDataEvent = procedure(const Data: string) of object;
  TTimeoutEvent = procedure() of object;
  TReadingThread = class(TThread)
  private
    FClient: TIdTCPClient;
    FData: string;
    FOnData: TDataEvent;
    FOnTimeout: TTimeoutEvent;
    procedure DataReceived;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TIdTCPClient); reintroduce;
    property OnData: TDataEvent read FOnData write FOnData;
    property OnTimeout: TTimeoutEvent read FOnTimeout write FOnTimeout;
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
     FData := FClient.IOHandler.ReadLn;
    except
     if ((Assigned(FOnTimeout)) and (not Terminated)) then
      Synchronize(FOnTimeout);
     Exit;
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
