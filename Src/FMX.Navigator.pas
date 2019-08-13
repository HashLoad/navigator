unit FMX.Navigator;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, FMX.Types,
  FMX.Controls, FMX.Layouts, FMX.StdCtrls, FMX.Objects, FMX.Graphics,
  FMX.MultiView, FMX.Effects, System.UITypes,
  FMX.Forms, FMX.Controls.Presentation, FMX.Filter.Effects;

type
  TFrameClass = class of TFrame;

  TGetMainFrameEvent = procedure(out AFrame: TFrame) of object;

  TGetFrameMainClassEvent = procedure(out AFrameClass: TFrameClass) of object;

  TFrameHelper = class helper for TControl
    procedure DoShow;
    procedure DoHide;
  end;

  TNavigator = class(TLayout)
  private
    FBackPath: TPath;
    FSettingsPath: TPath;
    FMenuPath: TPath;

    FOnSettingsClick: TNotifyEvent;
    FViewRender: TControl;
    FMultiView: TMultiView;
    FMultiViewButton: TSpeedButton;
    FStack: TStack<TPair<string, TFrame>>;
    FFontColor: TAlphaColor;
    FFrameMain: TFrame;
    FShadowEffectToolbar: TShadowEffect;
    FRectangle: TRectangle;
    FTitle: TLabel;
    FTitleFill: TFillRGBEffect;
    FMainTitle: string;
    FMenuButton: TSpeedButton;
    FBackButton: TSpeedButton;
    FSettingsButton: TSpeedButton;
    FOnKeyUpOwner: TKeyEvent;
    FOnGetFrameMainClass: TGetFrameMainClassEvent;
    procedure FreeStack;
    procedure SetMultiView(const Value: TMultiView);
    function HasMultiView: Boolean;
    function StackIsEmpty: Boolean;
    function GetTitle: string;
    procedure SetTitle(const Value: string);
    procedure SetFontColor(const Value: TAlphaColor);
    function GetFill: TBrush;
    procedure SetFill(const Value: TBrush);
    procedure DoPush(TitleNavigator: string; Frame: TFrame);
    procedure BackButtonClick(Sender: TObject);
    procedure MenuButtonClick(Sender: TObject);
    procedure CreateShadow;
    procedure CreateButtons;
    procedure CreateRectangle;
    procedure CreateLabel;
    procedure CreatePaths;
    procedure DoInjectKeyUp;
    procedure SetMainFrame(const Value: TFrame);
    function GetVisibleSettings: Boolean;
    procedure SetVisibleSettings(const Value: Boolean);
    procedure SetViewRender(const Value: TControl);
    function GetViewRender: TControl;
    property FrameMain: TFrame read FFrameMain write SetMainFrame;
    procedure DoOnGetFrameMainClass;
    procedure DoAdjustStyle;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure OnFormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure Loaded; override;
    function CreateFrameInstance(Frame: TFrameClass): TFrame;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Stack: TStack <TPair<string, TFrame>> read FStack write FStack;
    procedure Push(AFrame: TFrame); overload; deprecated 'Use method Push(AFrame: TFrameClass)';
    procedure Push(ATitle: string; AFrame: TFrame); overload; deprecated 'Use method Push(AFrame: TFrameClass)';
    procedure Push(ATitle: string; AFrame: TFrameClass); overload;
    procedure Push(AFrame: TFrameClass); overload;
    procedure Pop;
    procedure Clear;
  published
    property OnSettingsClick: TNotifyEvent read FOnSettingsClick write FOnSettingsClick;
    property OnGetFrameMainClass: TGetFrameMainClassEvent read FOnGetFrameMainClass write FOnGetFrameMainClass;
    property VisibleSettings: Boolean read GetVisibleSettings write SetVisibleSettings default False;
    property MultiView: TMultiView read FMultiView write SetMultiView;
    property Fill: TBrush read GetFill write SetFill;
    property Title: string read GetTitle write SetTitle;
    property FontColor: TAlphaColor read FFontColor write SetFontColor default TAlphaColorRec.Black;
    property ViewRender: TControl read GetViewRender write SetViewRender;
  end;

procedure Register;
const
  BACK_BUTTON = 'M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z';
  MENU_BUTTON = 'M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z';
  SETTINGS_BUTTON = 'M12,8 c1.1,0 2,-0.9 2,-2 s-0.9,-2 -2,-2 s-2,0.9 -2,2 s0.9,2 2,2 zm0,2 c-1.1,0 -2,0.9 -2,2 ' +
    's0.9,2 2,2 s2,-0.9 2,-2 s-0.9,-2 -2,-2 zm0,6 c-1.1,0 -2,0.9 -2,2 s0.9,2 2,2 s2,-0.9 2,-2 s-0.9,-2 -2,-2 z';

implementation

uses
  FMX.Styles.Objects, FMX.VirtualKeyboard, FMX.Platform;

procedure Register;
begin
  RegisterComponents('HashLoad', [TNavigator]);
end;

{ TNavigator }

procedure TNavigator.BackButtonClick(Sender: TObject);
begin
  Pop;
end;

procedure TNavigator.Clear;
begin
  while not StackIsEmpty do
    Pop;
end;

constructor TNavigator.Create(AOwner: TComponent);
begin
  inherited;

  FStack := TStack <TPair<string, TFrame>>.Create;
  CreateShadow;
  CreateRectangle;
  CreateButtons;
  CreateLabel;
  CreatePaths;

  DoInjectKeyUp;
  DoAdjustStyle;

  Align := TAlignLayout.Top;
  Height := 56;

  FontColor := TAlphaColorRec.Black;
end;

procedure TNavigator.CreateButtons;
begin
  FMenuButton := TSpeedButton.Create(Self);
  FMenuButton.Parent := FRectangle;
  FMenuButton.Align := TAlignLayout.Left;
  FMenuButton.Size.Width := FRectangle.Height;
  FMenuButton.OnClick := MenuButtonClick;
  FMenuButton.Stored := False;
  FMenuButton.SetSubComponent(True);

  FBackButton := TSpeedButton.Create(Self);
  FBackButton.Parent := FRectangle;
  FBackButton.Align := TAlignLayout.Left;
  FBackButton.Size.Width := FRectangle.Height;
  FBackButton.Visible := False;
  FBackButton.OnClick := BackButtonClick;
  FBackButton.Stored := False;
  FBackButton.SetSubComponent(True);

  FMultiViewButton := TSpeedButton.Create(Self);
  FMultiViewButton.Stored := False;
  FMultiViewButton.SetSubComponent(True);

  FSettingsButton := TSpeedButton.Create(Self);
  FSettingsButton.Parent := FRectangle;
  FSettingsButton.Align := TAlignLayout.Right;
  FSettingsButton.Size.Width := FRectangle.Height;
  VisibleSettings := False;
  FSettingsButton.Stored := False;
  FSettingsButton.SetSubComponent(True);
end;

function TNavigator.CreateFrameInstance(Frame: TFrameClass): TFrame;
var
  LInstance: TFrame;
begin
  LInstance := TFrame(Frame.NewInstance);
  LInstance.Create(TForm(Self.Root));
  Result := LInstance;
end;

procedure TNavigator.CreateLabel;
begin
  FTitle := TLabel.Create(Self);
  FTitle.Parent := FRectangle;
  FTitle.Align := TAlignLayout.Client;
  FTitle.Margins.Left := 16;
  FTitle.Margins.Top := 5;
  FTitle.Margins.Right := 5;
  FTitle.Margins.Bottom := 5;

  FTitleFill := TFillRGBEffect.Create(FTitle);
  FTitleFill.Parent := FTitle;
end;

procedure TNavigator.CreateShadow;
begin
  FShadowEffectToolbar := TShadowEffect.Create(Self);
  FShadowEffectToolbar.Distance := 3;
  FShadowEffectToolbar.Direction := 90;
  FShadowEffectToolbar.Softness := 0.3;
  FShadowEffectToolbar.Opacity := 1;
  FShadowEffectToolbar.ShadowColor := TAlphaColorRec.Darkgray;
  FShadowEffectToolbar.Stored := False;
  FShadowEffectToolbar.Parent := Self;
  FShadowEffectToolbar.SetSubComponent(True);
end;

procedure TNavigator.CreateRectangle;
begin
  FRectangle := TRectangle.Create(Self);
  FRectangle.SetSubComponent(True);
  FRectangle.Stored := False;
  FRectangle.Stroke.Kind := TBrushKind.None;
  FRectangle.Align := TAlignLayout.Client;
  FRectangle.Parent := Self;
end;

destructor TNavigator.Destroy;
begin
  FreeStack;

  if HasMultiView then
    FMultiView.RemoveFreeNotify(Self);

  inherited;
end;

function TNavigator.GetFill: TBrush;
begin
  Result := FRectangle.Fill;
end;

function TNavigator.GetTitle: string;
begin
  Result := FTitle.Text;
end;

function TNavigator.GetViewRender: TControl;
begin
  if Assigned(FViewRender) then
    Result := FViewRender
  else
    Result := TControl(Self.Parent);
end;

function TNavigator.GetVisibleSettings: Boolean;
begin
  Result := FSettingsButton.Visible;
end;

function TNavigator.HasMultiView: Boolean;
begin
  Result := FMultiView <> nil;
end;

procedure TNavigator.Loaded;
begin
  inherited;
  DoOnGetFrameMainClass;
  FSettingsButton.OnClick := FOnSettingsClick;
end;

procedure TNavigator.MenuButtonClick(Sender: TObject);
begin
  if Assigned(FMultiView) then
    FMultiViewButton.OnClick(Sender);
end;

function TNavigator.StackIsEmpty: Boolean;
begin
  Result := FStack.Count = 0;
end;

procedure TNavigator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (AComponent = FMultiView) and (Operation = opRemove) then
    FMultiView := nil;
end;

procedure TNavigator.OnFormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
var
  LService: IFMXVirtualKeyboardService;
begin
  if (Key = vkHardwareBack) and not StackIsEmpty then
    begin
      TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(LService));
      if Not((LService <> nil) and (TVirtualKeyboardState.Visible in LService.VirtualKeyBoardState)) then
        Pop
      else if (TVirtualKeyboardState.Visible in LService.VirtualKeyBoardState) then
        LService.HideVirtualKeyboard;
      Key := 0;
    end;

  if Assigned(FOnKeyUpOwner) then
    FOnKeyUpOwner(Sender, Key, KeyChar, Shift);
end;

procedure TNavigator.Pop;
var
  LFrame: TFrame;
begin
  LFrame := FStack.Peek.Value;
  FStack.Pop;

  TThread.Synchronize(nil,
    procedure
    begin
      LFrame.Parent := nil;
      TForm(Self.Root).RemoveFreeNotification(LFrame);
      TForm(Self.Root).RemoveComponent(LFrame);
      FreeAndNil(LFrame);

      if StackIsEmpty then
        begin
          FMenuButton.Visible := True;
          FBackButton.Visible := False;

          Title := FMainTitle;

          if Assigned(FFrameMain) then
            FFrameMain.Parent := FViewRender;
        end
      else
        begin
          FStack.Peek.Value.Parent := FViewRender;
          Title := FStack.Peek.Key;
        end;
    end);
end;

procedure TNavigator.Push(ATitle: string; AFrame: TFrameClass);
var
  LFrame: TFrame;
begin
  LFrame := CreateFrameInstance(AFrame);
  DoPush(ATitle, LFrame);
end;

procedure TNavigator.DoAdjustStyle;
begin
  {$IFDEF MSWINDOWS}
    FTitle.StyledSettings :=  [];
    FTitle.Font.Size := 16;
    FTitle.Font.Style := [TFontStyle.fsBold];
    FTitle.Font.Family := 'Roboto';
  {$ENDIF}
//  FMenuButton.StyleLookup := 'drawertoolbutton';
//  FSettingsButton.StyleLookup := 'detailstoolbutton';
end;

procedure TNavigator.DoInjectKeyUp;
begin
  if Owner.InheritsFrom(TCommonCustomForm) then
    begin
      FOnKeyUpOwner := TCommonCustomForm(Owner).OnKeyUp;
      TCommonCustomForm(Owner).OnKeyUp := OnFormKeyUp;
    end
  else if Owner.InheritsFrom(TControl) then
    begin
      FOnKeyUpOwner := TControl(Owner).OnKeyUp;
      TControl(Owner).OnKeyUp := OnFormKeyUp;
    end;
end;

procedure TNavigator.DoOnGetFrameMainClass;
var
  LFrameMainClass: TFrameClass;
begin
  if not(csDesigning in ComponentState) and Assigned(FOnGetFrameMainClass) then
    begin
      FOnGetFrameMainClass(LFrameMainClass);
      FrameMain := CreateFrameInstance(LFrameMainClass);
    end;
end;

procedure TNavigator.DoPush(TitleNavigator: string; Frame: TFrame);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if StackIsEmpty then
        begin
          FMenuButton.Visible := False;
          FBackButton.Visible := True;

          FMainTitle := Title;

          if Assigned(FFrameMain) then
            FFrameMain.Parent := nil;
        end
      else
        FStack.Peek.Value.Parent := nil;

      FStack.Push(TPair<string, TFrame>.Create(TitleNavigator, Frame));
      Title := TitleNavigator;
      Frame.Align := TAlignLayout.Client;
      Frame.Name := Frame.Name + FStack.Count.ToString;
      Frame.Parent := FViewRender;
      Frame.DoShow;
    end);
end;

procedure TNavigator.CreatePaths;
const
  PATH_SIZE = 18;

  procedure MakePath(var APath: TPath; AData: string; AParent: TFmxObject);
  begin
    APath := TPath.Create(AParent);
    APath.Parent := AParent;
    APath.SetSubComponent(True);
    APath.Stored := False;
    APath.HitTest := False;

    APath.Width := PATH_SIZE;
    APath.Height := PATH_SIZE;

    APath.Data.Data := AData;
    APath.Align := TAlignLayout.Center;
    APath.Fill.Color := FontColor;
    APath.Stroke.Kind := TBrushKind.None;

    APath.Padding.Left := -PATH_SIZE;
    APath.Padding.Right := -PATH_SIZE;
    APath.Padding.Top := -PATH_SIZE;
    APath.Padding.Bottom := -PATH_SIZE;
    APath.WrapMode := TPathWrapMode.Fit;

  end;
begin
  MakePath(FBackPath, BACK_BUTTON, FBackButton);
  MakePath(FMenuPath, MENU_BUTTON, FMenuButton);
  MakePath(FSettingsPath, SETTINGS_BUTTON, FSettingsButton);
end;

procedure TNavigator.FreeStack;
var
  LPairFrame: TPair<string, TFrame>;
  LFrame: TFrame;
begin
  while FStack.Count > 0 do
    begin
      LPairFrame := FStack.Pop;
      LFrame := LPairFrame.Value;
      LFrame.Parent := nil;
    end;
  FreeAndNil(FStack);
end;

procedure TNavigator.Push(ATitle: string; AFrame: TFrame);
begin
  DoPush(ATitle, AFrame);
end;

procedure TNavigator.Push(AFrame: TFrame);
begin
  DoPush(Title, AFrame);
end;

procedure TNavigator.SetFill(const Value: TBrush);
begin
  FRectangle.Fill := Value;
end;

procedure TNavigator.SetFontColor(const Value: TAlphaColor);
begin
  if FFontColor <> Value then
    begin
      FFontColor := Value;
      FTitleFill.Color := Value;

      FBackPath.Fill.Color := Value;
      FSettingsPath.Fill.Color := Value;
      FMenuPath.Fill.Color := Value;
    end;
end;

procedure TNavigator.SetMainFrame(const Value: TFrame);
begin
  if FFrameMain <> Value then
    begin
      if Assigned(FFrameMain) then
        begin
          RemoveFreeNotification(FFrameMain);
          FFrameMain.DisposeOf;
        end;

      FFrameMain := Value;

      if FFrameMain <> nil then
        begin
          AddFreeNotify(FFrameMain);
          FFrameMain.Align := TAlignLayout.Client;
          FFrameMain.Parent := FViewRender;
        end;
    end;
end;

procedure TNavigator.SetMultiView(const Value: TMultiView);
begin
  if FMultiView <> Value then
    begin
      FMultiView := Value;

      if HasMultiView then
        begin
          FMultiView.AddFreeNotify(Self);
          FMultiView.MasterButton := FMultiViewButton;
          FMenuButton.Visible := True;
        end;
    end;
end;

procedure TNavigator.SetTitle(const Value: string);
begin
  if FTitle.Text <> Value then
    FTitle.Text := Value;
end;

procedure TNavigator.SetViewRender(const Value: TControl);
begin
  if FViewRender <> Value then
    begin
      FViewRender := Value;
    end;
end;

procedure TNavigator.SetVisibleSettings(const Value: Boolean);
begin
  if FSettingsButton.Visible <> Value then
    begin
      FSettingsButton.Visible := Value
    end;
end;

procedure TNavigator.Push(AFrame: TFrameClass);
var
  LFrame: TFrame;
begin
  LFrame := CreateFrameInstance(AFrame);
  DoPush(Title, LFrame);
end;

{ TFrameHelper }

procedure TFrameHelper.DoHide;
begin
  Self.Hide;
end;

procedure TFrameHelper.DoShow;
begin
  Self.Show;
end;

end.
