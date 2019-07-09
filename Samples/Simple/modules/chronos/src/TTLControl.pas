unit TTLControl;

interface

uses
  System.Generics.Collections, System.Threading;

type
  ITTLConsumer = interface
    procedure DoRemove;
  end;

  TControlTTL = class;

  TAtomTTL = class(TInterfacedObject, IInterface)
  strict private
    FStopTime: TDateTime;
    FTask: ITask;
  private
    FAtomData: ITTLConsumer;
    FController: TControlTTL;
    FTTL: Int64;
    procedure DoRemove;
  private
    procedure Start;
    procedure Stop;
    constructor Create(AController: TControlTTL; AAtom: ITTLConsumer);
  end;

  TControlTTL = class(TInterfacedObject, IInterface)
  private
    class var FInstance: TControlTTL;
  private
    FControlled: TDictionary<ITTLConsumer, TAtomTTL>;
  public
    procedure TTLRegister(AObject: ITTLConsumer; ALiveTime: Int64);
    procedure TTLRemove(AObject: ITTLConsumer);
    constructor Create();

    class function GetInstance: TControlTTL;
    destructor Destroy; override;
  end;

implementation

uses
  System.DateUtils, System.SysUtils, System.Classes;

{ TControlTTL }

constructor TControlTTL.Create;
begin
  FControlled := TDictionary<ITTLConsumer, TAtomTTL>.Create;
end;

destructor TControlTTL.Destroy;
var
  LTTL: TAtomTTL;
begin
  for LTTL in FControlled.Values do
  begin
    LTTL.Stop;
  end;
  FControlled.Free;
  inherited;
end;

class function TControlTTL.GetInstance: TControlTTL;
begin
  if not Assigned(TControlTTL.FInstance) then
    TControlTTL.FInstance := TControlTTL.Create;

  Result := TControlTTL.FInstance;
end;

procedure TControlTTL.TTLRegister(AObject: ITTLConsumer; ALiveTime: Int64);
var
  LData: TAtomTTL;
begin
  if FControlled.TryGetValue(AObject, LData) then
  begin
    LData.Stop;
  end
  else
  begin
    LData := TAtomTTL.Create(Self, AObject);
    FControlled.Add(AObject, LData);
  end;

  LData.FTTL := ALiveTime;
  LData.Start;
end;

procedure TControlTTL.TTLRemove(AObject: ITTLConsumer);
var
  LTTLAtom: TAtomTTL;
begin
  if FControlled.TryGetValue(AObject, LTTLAtom) then
  begin
    LTTLAtom.Stop;
    FControlled.Remove(AObject);
  end;
end;

{ TAtomTTL }

constructor TAtomTTL.Create(AController: TControlTTL; AAtom: ITTLConsumer);
begin
  FAtomData := AAtom;
  FController := AController;
end;

procedure TAtomTTL.DoRemove;
begin
  FController.TTLRemove(FAtomData);
  FAtomData.DoRemove;
end;

procedure TAtomTTL.Start;
begin
  if Assigned(FTask) then
    FTask.Cancel;

  FStopTime := IncMillisecond(Now, FTTL);

  FTask := TTask.Create(
    procedure
    begin
      while not(Now > FStopTime) do
      begin
        if FTask.Status <> TTaskStatus.Running then
          Exit;
      end;
      DoRemove;
    end);
  FTask.Start;
end;

procedure TAtomTTL.Stop;
begin
  if Assigned(FTask) then
    FTask.Cancel;
end;

end.
