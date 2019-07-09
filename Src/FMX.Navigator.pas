unit FMX.Navigator;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, FMX.Types,
  FMX.Controls, FMX.Layouts, FMX.StdCtrls, FMX.Objects, FMX.Graphics, FMX.MultiView, FMX.Effects, System.UITypes,
  FMX.Forms, FMX.Controls.Presentation, FMX.Filter.Effects;

type
  TGetMainFrameEvent = procedure(out AFrame: TFrame) of object;

  TFrameClass = class of TFrame;

  TFrameHelper = class helper for TControl
    procedure DoShow;
    procedure DoHide;
  end;

  TNavigator = class(TLayout)
  private
    FOnSettingsClick: TNotifyEvent;
    FViewRender: TControl;
    FMultiView: TMultiView;
    FMultiViewButton: TButton;
    FStack: TStack<TPair<string, TFrame>>;
    FFontColor: TAlphaColor;
    FMainFrame: TFrame;
    FOnGetMainFrame: TGetMainFrameEvent;
    FShadowEffectToolbar: TShadowEffect;
    FRectangle: TRectangle;
    FTitle: TLabel;
    FTitleFill: TFillRGBEffect;
    FMenuButton: TButton;
    FMenuButtonFill: TFillRGBEffect;
    FBackButton: TButton;
    FBackButtonFill: TFillRGBEffect;
    FSettingsButton: TButton;
    FSettingsButtonFill: TFillRGBEffect;
    FOnKeyUpOwner: TKeyEvent;

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
    procedure DoInjectKeyUp;
    procedure SetMainFrame(const Value: TFrame);
    function GetVisibleSettings: Boolean;
    procedure SetVisibleSettings(const Value: Boolean);
    procedure SetViewRender(const Value: TControl);
    property MainFrame: TFrame read FMainFrame write SetMainFrame;
    procedure DoOnGetMainFrame;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure OnFormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure Loaded; override;
    function CreateFrameInstance(Frame: TFrameClass): TFrame;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Stack: TStack < TPair < string, TFrame >> read FStack write FStack;
    // procedure Push(Frame: TFrame); overload; deprecated;
    // procedure Push(NavigatorTitle: string; Frame: TFrame); overload; deprecated;
    procedure Push(NavigatorTitle: string; Frame: TFrameClass); overload;
    procedure Pop;
    procedure Clear;
    procedure FreeStack;
  published
    property OnSettingsClick: TNotifyEvent read FOnSettingsClick write FOnSettingsClick;
    property OnGetMainFrame: TGetMainFrameEvent read FOnGetMainFrame write FOnGetMainFrame;
    property VisibleSettings: Boolean read GetVisibleSettings write SetVisibleSettings default False;
    property MultiView: TMultiView read FMultiView write SetMultiView;
    property Fill: TBrush read GetFill write SetFill;
    property Title: string read GetTitle write SetTitle;
    property FontColor: TAlphaColor read FFontColor write SetFontColor default TAlphaColorRec.Black;
    property ViewRender: TControl read FViewRender write SetViewRender;
  end;

procedure Register;

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

  FStack := TStack < TPair < string, TFrame >>.Create;
  CreateShadow;
  CreateRectangle;
  CreateButtons;
  CreateLabel;

  DoInjectKeyUp;

  Align := TAlignLayout.Top;
  Height := 56;

  FontColor := TAlphaColorRec.Black;
end;

procedure TNavigator.CreateButtons;
begin
  FMenuButton := TButton.Create(Self);
  FMenuButton.Parent := FRectangle;
  FMenuButton.Align := TAlignLayout.Left;
  FMenuButton.Size.Width := FRectangle.Height;
  FMenuButton.StyleLookup := 'drawertoolbutton';
  FMenuButton.OnClick := MenuButtonClick;
  FMenuButton.Stored := False;
  FMenuButton.SetSubComponent(True);
  FMenuButtonFill := TFillRGBEffect.Create(FMenuButton);
  FMenuButtonFill.Parent := FMenuButton;

  FBackButton := TButton.Create(Self);
  FBackButton.Parent := FRectangle;
  FBackButton.Align := TAlignLayout.Left;
  FBackButton.Size.Width := FRectangle.Height;
  FBackButton.StyleLookup := 'backtoolbutton';
  FBackButton.Visible := False;
  FBackButton.OnClick := BackButtonClick;
  FBackButton.Stored := False;
  FBackButton.SetSubComponent(True);
  FBackButtonFill := TFillRGBEffect.Create(FBackButton);
  FBackButtonFill.Parent := FBackButton;

  FMultiViewButton := TButton.Create(Self);
  FMultiViewButton.Stored := False;
  FMultiViewButton.SetSubComponent(True);

  FSettingsButton := TButton.Create(Self);
  FSettingsButton.Parent := FRectangle;
  FSettingsButton.Align := TAlignLayout.Right;
  FSettingsButton.Size.Width := FRectangle.Height;
  FSettingsButton.StyleLookup := 'detailstoolbutton';
  VisibleSettings := False;
  FSettingsButton.Stored := False;
  FSettingsButton.SetSubComponent(True);
  FSettingsButtonFill := TFillRGBEffect.Create(FSettingsButton);
  FSettingsButtonFill.Parent := FSettingsButton;
end;

function TNavigator.CreateFrameInstance(Frame: TFrameClass): TFrame;
var
  LInstance: TFrame;
begin
  LInstance := TFrame(Frame.NewInstance);
  try
    LInstance.Create(TForm(Self.Root));
    Result := LInstance;
  except
    LInstance := nil;
    raise;
  end;
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
  DoOnGetMainFrame;
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

        if Assigned(FMainFrame) then
          FMainFrame.Parent := FViewRender;
      end
      else
      begin
        FStack.Peek.Value.Parent := FViewRender;
        Title := FStack.Peek.Key;
      end;
    end);
end;

procedure TNavigator.Push(NavigatorTitle: string; Frame: TFrameClass);
var
  LFrame: TFrame;
begin
  LFrame := CreateFrameInstance(Frame);
  DoPush(NavigatorTitle, LFrame);
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

procedure TNavigator.DoOnGetMainFrame;
var
  LMainFrame: TFrame;
begin
  if not(csDesigning in ComponentState) and Assigned(FOnGetMainFrame) then
  begin
    FOnGetMainFrame(LMainFrame);
    MainFrame := LMainFrame;
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

        if Assigned(FMainFrame) then
          FMainFrame.Parent := nil;
      end
      else
        FStack.Peek.Value.Parent := nil;

      FStack.Push(TPair<string, TFrame>.Create(TitleNavigator, Frame));
      Title := TitleNavigator;
      Frame.Align := TAlignLayout.Client;

      Frame.Parent := FViewRender;
      Frame.DoShow;
    end);
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

// procedure TNavigator.Push(NavigatorTitle: string; Frame: TFrame);
// begin
// DoPush(NavigatorTitle, Frame);
// end;
//
// procedure TNavigator.Push(Frame: TFrame);
// begin
// DoPush(Title, Frame);
// end;

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
    FBackButtonFill.Color := Value;
    FSettingsButtonFill.Color := Value;
    FMenuButtonFill.Color := Value;
  end;
end;

procedure TNavigator.SetMainFrame(const Value: TFrame);
begin
  if FMainFrame <> Value then
  begin
    if Assigned(FMainFrame) then
    begin
      RemoveFreeNotification(FMainFrame);
      FMainFrame.DisposeOf;
    end;

    FMainFrame := Value;

    if FMainFrame <> nil then
    begin
      AddFreeNotify(FMainFrame);
      FMainFrame.Align := TAlignLayout.Client;
      FMainFrame.Parent := FViewRender;
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
  FViewRender := Value;
end;

procedure TNavigator.SetVisibleSettings(const Value: Boolean);
begin
  if FSettingsButton.Visible <> Value then
  begin
    FSettingsButton.Visible := Value
  end;
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
