unit Simple.Navigator;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Navigator, FMX.MultiView, FMX.Effects, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.Ani,
  Storage.Chronos;

type
  TSimpleNavigator = class(TForm)
    MultiView: TMultiView;
    Button1: TButton;
    Navigator: TNavigator;
    Chronos: TChronos;
    procedure Button1Click(Sender: TObject);
    procedure NavigatorSettingsClick(Sender: TObject);
    procedure NavigatorGetFrameMainClass(out AFrameClass: TFrameClass);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  SimpleNavigator: TSimpleNavigator;

implementation

{$R *.fmx}

uses Simple.Master;

procedure TSimpleNavigator.Button1Click(Sender: TObject);
begin
  Close;
end;

constructor TSimpleNavigator.Create(AOwner: TComponent);
begin
  inherited;
  Chronos.SetItem('navigator', Navigator);
end;

procedure TSimpleNavigator.NavigatorGetFrameMainClass(
  out AFrameClass: TFrameClass);
begin
  AFrameClass := TSimpleMaster;
end;

procedure TSimpleNavigator.NavigatorSettingsClick(Sender: TObject);
begin
  ShowMessage('Test');
end;

end.
