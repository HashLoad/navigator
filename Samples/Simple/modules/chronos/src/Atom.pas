unit Atom;

interface

uses
  System.Rtti, TTLControl, System.Classes;

type
  IAtomConsumer = interface
    procedure RemoveItem(ATag: string);
  end;

  TAtom = class(TInterfacedPersistent, ITTLConsumer)
  private
    FRoot: IAtomConsumer;
    FTTL: Int64;
    FData: TValue;
    FTag: string;

    procedure SetTTL(const Value: Int64);
    procedure BeginTTL;
    procedure RemoveTTL;
  public
    procedure DoRemove;
    procedure SetValue<AtomType>(const AData: AtomType);
    function GetValue<AtomType>: AtomType;
    function Raw: TMemoryStream;
    procedure Restore(ARawData: TMemoryStream);
    constructor Create(AOwner: IAtomConsumer);

    property TTL: Int64 read FTTL write SetTTL;
    property Tag: String read FTag write FTag;
  end;

implementation

uses
  System.Variants, System.TypInfo;

{ TAtom }

procedure TAtom.BeginTTL;
begin
  TControlTTL.GetInstance.TTLRegister(Self, TTL);
end;

constructor TAtom.Create(AOwner: IAtomConsumer);
begin
  FRoot := AOwner;
end;

procedure TAtom.DoRemove;
begin
  FRoot.RemoveItem(Tag);
end;

function TAtom.GetValue<AtomType>: AtomType;
var
  LCast: TValue;
begin
  if not FData.TryAsType<AtomType>(Result) then
  begin
    LCast := FData.Cast<AtomType>();
    LCast.TryAsType<AtomType>(Result);
  end;

end;

function TAtom.Raw: TMemoryStream;
var
  LRawData: Pointer;
begin
  Result := TMemoryStream.Create;
  Result.Position := 0;

  FData.ExtractRawData(@LRawData);
  Result.Write(LRawData, SizeOf(@LRawData));
  Result.Position := 0;
end;

procedure TAtom.RemoveTTL;
begin
  TControlTTL.GetInstance.TTLRemove(Self)
end;

procedure TAtom.Restore(ARawData: TMemoryStream);
begin
  ARawData.ReadBuffer(FData, SizeOf(FData));
end;

procedure TAtom.SetTTL(const Value: Int64);
begin
  if (FTTL > -1) and (Value = -1) then
    RemoveTTL;

  FTTL := Value;

  if FTTL > -1 then
    BeginTTL;
end;

procedure TAtom.SetValue<AtomType>(const AData: AtomType);
begin
  FData := TValue.From(AData)
end;

end.
