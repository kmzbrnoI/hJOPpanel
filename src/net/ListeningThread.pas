unit ListeningThread;

{
  Poslouchaci vlakno TCP spojeni
}

interface

uses
  Classes, IdTCPClient;

type
  TDataEvent = procedure(const Data: string) of object;
  TErrorEvent = procedure() of object;
  TReadingThread = class(TThread)
  private
    FClient: TIdTCPClient;
    FData: string;
    FOnData: TDataEvent;
    FOnError: TErrorEvent;
    procedure DataReceived;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TIdTCPClient); reintroduce;
    property OnData: TDataEvent read FOnData write FOnData;
    property OnError: TErrorEvent read FOnError write FOnError;
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
     if ((Assigned(FOnError)) and (not Terminated)) then
      Synchronize(FOnError);
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
