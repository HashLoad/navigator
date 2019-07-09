unit Simple.Master;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.Navigator, Storage.Chronos;

type
  TSimpleMaster = class(TFrame)
    Memo1: TMemo;
    Button1: TButton;
    Chronos: TChronos;
    procedure Button1Click(Sender: TObject);
  end;

implementation

{$R *.fmx}

uses Simple.Detail;

{ TSimpleMaster }

procedure TSimpleMaster.Button1Click(Sender: TObject);
var
  LNavigator: TNavigator;
begin
  LNavigator := Chronos.GetItem<TNavigator>('navigator');
  LNavigator.Push('New Title', TSimpleDetail);
end;

end.
