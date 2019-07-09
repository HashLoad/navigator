unit Storage.Chronos;

interface

uses
  System.SysUtils, System.Generics.Collections, Atom, System.Rtti, System.Classes, System.Generics.Defaults;

type

  TChronosManager = class(TSingletonImplementation, IAtomConsumer)
  private
    FData: TDictionary<string, TAtom>;

  public
    constructor Create; reintroduce;

    procedure SetItem<AtomType>(AKey: string; const AValue: AtomType); overload;
    procedure SetItem<AtomType>(AKey: string; const AValue: AtomType; ATTL: Int64); overload;
    function GetItem<AtomType>(AKey: string): AtomType;
    procedure RemoveItem(AKey: string);
    function ContainsItem(AKey: string): Boolean;
    function TryGetItem<AtomType>(AKey: string; out AValue: AtomType): Boolean;

    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    destructor Destroy; override;
  end;


 TChronos = class(TComponent)
  public
    procedure SetItem<AtomType>(AKey: string; const AValue: AtomType); overload;
    procedure SetItem<AtomType>(AKey: string; const AValue: AtomType; ATTL: Int64); overload;
    function GetItem<AtomType>(AKey: string): AtomType;
    procedure RemoveItem(AKey: string);
    function ContainsItem(AKey: string): Boolean;
    function TryGetItem<AtomType>(AKey: string; out AValue: AtomType): Boolean;
  end;


var
  Chronos: TChronosManager;

procedure Register;

implementation

uses
  System.IniFiles;

const
  C_SECTION = 'CHRONOS';

procedure TChronosManager.SetItem<AtomType>(AKey: string; const AValue: AtomType);
begin
  SetItem<AtomType>(AKey, AValue, -1);
end;

procedure TChronosManager.SetItem<AtomType>(AKey: string; const AValue: AtomType; ATTL: Int64);
var
  LData: TAtom;
begin
  System.TMonitor.Enter(FData);
  AKey := AKey.ToUpper;
  try
    if FData.TryGetValue(AKey, LData) then
      LData.SetValue(AValue)
    else
    begin
      LData := TAtom.Create(Self);
      FData.Add(AKey, LData);
      LData.Tag := AKey;
      LData.SetValue(AValue);
    end;
    LData.TTL := ATTL;
  finally
    System.TMonitor.Exit(FData);
  end;
end;

function TChronosManager.ContainsItem(AKey: string): Boolean;
begin
  Result := FData.ContainsKey(AKey);
end;

constructor TChronosManager.Create;
begin
  FData := TObjectDictionary<string, TAtom>.Create([doOwnsValues]);
end;

destructor TChronosManager.Destroy;
begin
  FData.DisposeOf;
  inherited;
end;

function TChronosManager.GetItem<AtomType>(AKey: string): AtomType;
var
  LData: TAtom;
begin
  System.TMonitor.Enter(FData);
  try
    AKey := AKey.ToUpper;
    if FData.TryGetValue(AKey, LData) then
      Result := LData.GetValue<AtomType>
  finally
    System.TMonitor.Exit(FData);
  end;
end;

procedure TChronosManager.LoadFromFile(const AFileName: string);
var
  LFile: TIniFile;
  LFileName: string;
  LAtom: TAtom;
  LStream: TMemoryStream;
  LKeys: TStringList;
  LKey: string;

begin
  LFileName := ChangeFileExt(AFileName, '.ini');
  LKeys := TStringList.Create;
  try

    LFile := TIniFile.Create(LFileName);
    try
      LFile.ReadSection(C_SECTION, LKeys);
      for LKey in LKeys do
      begin
        if not FData.TryGetValue(LKey, LAtom) then
        begin
          LAtom := TAtom.Create(Self);
          FData.Add(LKey, LAtom);
        end;

        LStream := TMemoryStream.Create;
        try
          LFile.ReadBinaryStream(C_SECTION, LKey, LStream);
          LAtom.Restore(LStream);
        finally
          LStream.Free;
        end;

      end;

    finally
      LFile.DisposeOf;
    end;
  finally
    LKeys.DisposeOf;
  end;
end;

procedure TChronosManager.RemoveItem(AKey: string);
begin
  System.TMonitor.Enter(FData);
  try
    AKey := AKey.ToUpper;
    FData.Remove(AKey);
  finally
    System.TMonitor.Exit(FData);
  end;
end;

procedure TChronosManager.SaveToFile(const AFileName: string);
var
  LFile: TIniFile;
  LFileName: string;
  LAtomPair: TPair<string, TAtom>;
  LStream: TStream;
  LFileTmp: TextFile;
begin
  LFileName := ChangeFileExt(AFileName, '.ini');
  if not FileExists(LFileName) then
  begin
    AssignFile(LFileTmp, LFileName);
    Rewrite(LFileTmp);
    CloseFile(LFileTmp);
  end;

  LFile := TIniFile.Create(LFileName);
  try
    for LAtomPair in FData do
    begin
      LStream := LAtomPair.Value.Raw;
      try
        LFile.WriteBinaryStream(C_SECTION, LAtomPair.Key, LStream);
      finally
        LStream.DisposeOf;
      end;
    end;

    LFile.UpdateFile;
  finally
    LFile.DisposeOf;
  end;
end;

function TChronosManager.TryGetItem<AtomType>(AKey: string; out AValue: AtomType): Boolean;
var
  LAtom: TAtom;
begin
  Result := FData.TryGetValue(AKey, LAtom);
  if Result then
    AValue := LAtom.GetValue<AtomType>;
end;

{ TChronosComponent }

function TChronos.ContainsItem(AKey: string): Boolean;
begin
  Result := Chronos.ContainsItem(AKey)
end;

function TChronos.GetItem<AtomType>(AKey: string): AtomType;
begin
  Result := Chronos.GetItem<AtomType>(AKey);
end;

procedure TChronos.RemoveItem(AKey: string);
begin
  Chronos.RemoveItem(AKey);
end;

procedure TChronos.SetItem<AtomType>(AKey: string; const AValue: AtomType);
begin
  Chronos.SetItem<AtomType>(AKey, AValue);
end;

procedure TChronos.SetItem<AtomType>(AKey: string; const AValue: AtomType; ATTL: Int64);
begin
  Chronos.SetItem<AtomType>(AKey, AValue, ATTL);
end;

function TChronos.TryGetItem<AtomType>(AKey: string; out AValue: AtomType): Boolean;
begin
  Result := Chronos.TryGetItem<AtomType>(AKey, AValue);
end;

procedure Register;
begin
  RegisterComponents('HashLoad', [TChronos]);
end;

initialization

Chronos := TChronosManager.Create;

finalization

Chronos.DisposeOf;

end.
