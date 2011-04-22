{Copyright (c) 2008 Ville Krumlinde

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.}

unit ZExpressions;

{
  Expressions.
  Use global proc RunCode(...) to execute code.

  Runtime Virtual Machine
}

interface

uses ZClasses;

type
  //Klass med en expression-prop
  TZExpression = class(TCommand)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Expression : TZExpressionPropValue;
    Value : single;
    procedure Execute; override;
  end;

  //User-defined functions
  TZLibrary = class(TZComponent)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Source : TZExpressionPropValue;
  end;

  TDefineVariableBase = class(TZComponent)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    _Type : (dvbFloat,dvbInt);
  end;


  //Define a global variable that can be used in expressions
  TDefineVariable = class(TDefineVariableBase)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Value : single;
    IntValue : integer;
  end;

  //Define a global constant that can be used in expressions
  //Value is copied into code, this component is not streamed in final binary
  TDefineConstant = class(TZComponent)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Value : single;
    {$ifndef minimal}function GetDisplayName: string; override;{$endif}
  end;

  TDefineArray = class(TDefineVariableBase)
  strict private
    Data : PFloatArray;
    Limit : integer;
    procedure AllocData;
  private
    function PopAndGetElement : PFloat;
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Dimensions : (dadOne,dadTwo,dadThree);
    SizeDim1,SizeDim2,SizeDim3 : integer;
    Persistent : boolean;
    Values : TZBinaryPropValue;
    destructor Destroy; override;
    function GetData : PFloat;
    function CalcLimit : integer;
  end;

  //Virtual machine instruction baseclass
  TExpBase = class(TZComponent)
  protected
    procedure Execute; virtual; abstract;
    {$ifndef minimal}public function ExpAsText : string;{$endif}
  end;

  //Load value of prop to stack
  TExpPropValueBase = class(TExpBase)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Source : TZPropertyRef;
  end;

  TExpPropValue4 = class(TExpPropValueBase)
  protected
    procedure Execute; override;
  end;

  TExpPropValue1 = class(TExpPropValueBase)
  protected
    procedure Execute; override;
  end;

  //Load pointer to prop on stack, used with assign
  TExpPropPtr = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Target : TZPropertyRef;
  end;

  TExpConstantFloat = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Constant : single;
    {$ifndef minimal}
    function GetDisplayName: String; override;
    {$endif}
  end;

  TExpConstantInt = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Constant : integer;
    {$ifndef minimal}
    function GetDisplayName: String; override;
    {$endif}
  end;

  TExpOpBinaryKind = (vbkPlus,vbkMinus,vbkMul,vbkDiv);

  TExpOpBinaryBase = class(TExpBase)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : TExpOpBinaryKind;
  end;

  TExpOpBinaryFloat = class(TExpOpBinaryBase)
  protected
    procedure Execute; override;
  end;

  TExpOpBinaryInt = class(TExpOpBinaryBase)
  protected
    procedure Execute; override;
  end;

  TExpOpJumpKind = (jsJumpAlways,jsJumpLT,jsJumpGT,jsJumpLE,jsJumpGE,jsJumpNE,jsJumpEQ);
  TExpJump = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : TExpOpJumpKind;
    Destination : integer;  //todo could be smallint or byte
    _Type : (jutFloat,jutInt);
  end;

  TExpFuncCallKind = (fcSin,fcSqrt,fcCos,fcAbs,fcRnd,fcFrac,fcExp,
     fcTan,fcCeil,fcFloor,fcAcos,fcAsin,fcRound,
     fcRandom,fcAtan2,fcNoise2,fcNoise3,fcClamp,fcPow,fcCenterMouse,
     fcSetRandomSeed,fcQuit,
     fcJoyGetAxis,fcJoyGetButton,fcJoyGetPOV);

  //Built-in function call
  TExpFuncCall = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : TExpFuncCallKind;
  end;

  //Read value from array and push on stack
  TExpArrayRead = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    TheArray : TDefineArray;
  end;

  //Push ptr to element in array on stack, used with assign
  TExpArrayWrite = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    TheArray : TDefineArray;
  end;

  //Setup local stack frame
  TExpStackFrame = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Size : integer;
  end;

  //Load/store local value
  TExpAccessLocal = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : (loLoad,loStore);
    Index : integer;
  end;

  //Return from function
  TExpReturn = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    HasFrame : boolean;
    IsFunction : boolean;      //if false=simple expression
    HasReturnValue : boolean;
    Arguments : integer;
  end;

  TExpMisc = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : (emPop,emDup);
  end;

  TExpUserFuncCall = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Lib : TZLibrary;
    Index : integer;
  end;

  TExpConvertKind = (eckFloatToInt,eckIntToFloat);
  TExpConvert = class(TExpBase)
  protected
    procedure Execute; override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Kind : TExpConvertKind;
  end;

  //Assign ptr to 4-byte value, both on stack
  TExpAssign4 = class(TExpBase)
  protected
    procedure Execute; override;
  end;

  //Assign ptr to 1-byte value, both on stack
  TExpAssign1 = class(TExpBase)
  protected
    procedure Execute; override;
  end;

//Run a compiled expression
//Uses global vars for state.
procedure RunCode(Code : TZComponentList);

var
  //Return value of last executed expression
  gReturnValue : single;


implementation


uses ZMath,ZPlatform,ZApplication
{$ifndef minimal},ZLog,SysUtils,Math{$endif};

var
  //Expression execution context
  gCurrentPc : ^TExpBase;
  gCurrentBP : integer;


const
  ZcStackSize=16384;

var
  ZcStack : array[0..ZcStackSize div SizeOf(Integer)] of integer;
  ZcStackPtr : PInteger;

const
  ZcStackBegin : PInteger = @ZcStack;

function StackGetDepth : integer;
begin
  {$if SizeOf(Integer)<>4}
  'update shift bits to divide with word length below'
  {$ifend}
  Result := (integer(ZcStackPtr) - integer(ZcStackBegin)) shr 2;
end;

procedure StackPush(const X);
begin
  {$ifndef minimal}
  if StackGetDepth>=High(ZcStack) then
    ZHalt('Zc Stack Overflow (infinite recursion?)');
  {$endif}
  ZcStackPtr^ := PInteger(@X)^;
  Inc(ZcStackPtr);
end;

procedure StackPushValue(X : pointer); inline;
begin
  StackPush(X);
end;

procedure StackPopTo(var X);
begin
  {$ifndef minimal}
  if StackGetDepth=0 then
    ZHalt('Zc Stack Underflow');
  {$endif}
  Dec(ZcStackPtr);
  PInteger(@X)^:=ZcStackPtr^;
end;

function StackPopFloat : single;
begin
  StackPopTo(Result);
end;


function StackGetPtrToItem(const Index : integer) : PInteger;
begin
  Result := @ZcStack;
  Inc(Result,Index);
end;

procedure RunCode(Code : TZComponentList);
{$ifndef minimal}
var
  GuardLimit : integer;
{$endif}
begin
  //Pc can be modified in jump-code
  if Code.Count=0 then
    Exit;
  gCurrentPc := Code.GetPtrToItem(0);
  gCurrentBP := 0;

  //Reset stack
  ZcStackPtr := ZcStackBegin;
  StackPushValue(nil); //Push return adress nil

  {$ifndef minimal}
  GuardLimit := 20 * 1000000;
  {$endif}
  while True do
  begin
    TExpBase(gCurrentPc^).Execute;
    if gCurrentPc=nil then
       break;
    Inc(gCurrentPc);
    {$ifndef minimal}
    Dec(GuardLimit);
    if GuardLimit=0 then
      ZHalt('Twenty million instructions executed. Infinite loop?');
    {$endif}
  end;
  if StackGetDepth=1 then
    StackPopTo(gReturnValue);
  {$ifndef minimal}
  if StackGetDepth>0 then
    ZLog.GetLog('Zc').Warning('Stack not empty on script completion');
  {$endif}
end;

{ TZExpression }

procedure TZExpression.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Expression',{$ENDIF}integer(@Expression) - integer(Self), zptExpression);
end;

procedure TZExpression.Execute;
begin
  ZExpressions.RunCode(Expression.Code);
  Value := ZExpressions.gReturnValue;
end;

{ TExpPropValueBase }

procedure TExpPropValueBase.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Source',{$ENDIF}integer(@Source) - integer(Self), zptPropertyRef);
end;

procedure TExpPropValue4.Execute;
begin
  StackPush(ZClasses.GetPropertyRef(Source)^);
end;

//Load byte value and cast to integer
procedure TExpPropValue1.Execute;
var
  I : integer;
begin
  I := PByte(ZClasses.GetPropertyRef(Source))^;
  StackPush(I);
end;

{ TExpConstantFloat }

procedure TExpConstantFloat.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Constant',{$ENDIF}integer(@Constant) - integer(Self), zptFloat);
end;

procedure TExpConstantFloat.Execute;
begin
  StackPush( Constant );
end;

{$ifndef minimal}
function TExpConstantFloat.GetDisplayName: String;
begin
  Result := inherited GetDisplayName + ' ' + FloatToStr(Constant);
end;
{$endif}

{ TExpConstantInt }

procedure TExpConstantInt.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Constant',{$ENDIF}integer(@Constant) - integer(Self), zptInteger);
end;

procedure TExpConstantInt.Execute;
begin
  StackPush( Constant );
end;

{$ifndef minimal}
function TExpConstantInt.GetDisplayName: String;
begin
  Result := inherited GetDisplayName + ' ' + IntToStr(Constant);
end;
{$endif}

{ TExpOpBinary }

procedure TExpOpBinaryBase.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
end;

{$ifdef minimal} {$WARNINGS OFF} {$endif}
procedure TExpOpBinaryFloat.Execute;
var
  A1,A2,V : single;
begin
  StackPopTo(A1);
  StackPopTo(A2);
  case Kind of
    vbkPlus : V := A1 + A2;
    vbkMinus : V := A2 - A1;
    vbkMul : V := A2 * A1;
    vbkDiv : V := A2 / A1;
    {$ifndef minimal}else begin ZHalt('Invalid binary op'); exit; end;{$endif}
  end;
  StackPush(V);
end;
{$ifdef minimal} {$WARNINGS ON} {$endif}

{$ifdef minimal} {$WARNINGS OFF} {$endif}
procedure TExpOpBinaryInt.Execute;
var
  A1,A2,V : integer;
begin
  StackPopTo(A1);
  StackPopTo(A2);
  case Kind of
    vbkPlus : V := A1 + A2;
    vbkMinus : V := A2 - A1;
    vbkMul : V := A2 * A1;
    vbkDiv : V := A2 div A1;
    {$ifndef minimal}else begin ZHalt('Invalid binary op'); exit; end;{$endif}
  end;
  StackPush(V);
end;
{$ifdef minimal} {$WARNINGS ON} {$endif}

{ TExpPropPtr }

procedure TExpPropPtr.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Target',{$ENDIF}integer(@Target) - integer(Self), zptPropertyRef);
end;

procedure TExpPropPtr.Execute;
begin
  StackPushValue(GetPropertyRef(Target));
end;

{ TExpJump }

procedure TExpJump.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
  List.AddProperty({$IFNDEF MINIMAL}'Destination',{$ENDIF}integer(@Destination) - integer(Self), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'Type',{$ENDIF}integer(@_Type) - integer(Self), zptByte);
end;

procedure TExpJump.Execute;
var
  L,R : single;
  Li,Ri : integer;
  Jump : boolean;
begin
  Jump := True;
  case Kind of
    jsJumpAlways : ;
  else
    begin
      if _Type=jutFloat then
      begin
        StackPopTo(R);
        StackPopTo(L);
        case Kind of
          jsJumpLT : Jump := L<R;
          jsJumpGT : Jump := L>R;
          jsJumpLE : Jump := L<=R;
          jsJumpGE : Jump := L>=R;
          jsJumpNE : Jump := L<>R;
          jsJumpEQ : Jump := L=R;
        {$ifndef minimal}else ZHalt('Invalid jump op');{$endif}
        end;
      end else
      begin
        StackPopTo(Ri);
        StackPopTo(Li);
        case Kind of
          jsJumpLT : Jump := Li<Ri;
          jsJumpGT : Jump := Li>Ri;
          jsJumpLE : Jump := Li<=Ri;
          jsJumpGE : Jump := Li>=Ri;
          jsJumpNE : Jump := Li<>Ri;
          jsJumpEQ : Jump := Li=Ri;
        {$ifndef minimal}else ZHalt('Invalid jump op');{$endif}
        end;
      end;
    end;
  end;
  if Jump then
    Inc(gCurrentPc,Destination);
end;

{ TDefineVariable }

procedure TDefineVariable.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Value',{$ENDIF}integer(@Value) - integer(Self), zptFloat);
    //Variabler �r ingen ide att spara, de m�ste s�ttas ifr�n kod
    List.GetLast.NeverPersist := True;
  List.AddProperty({$IFNDEF MINIMAL}'IntValue',{$ENDIF}integer(@IntValue) - integer(Self), zptInteger);
    List.GetLast.NeverPersist := True;
end;

{ TExpFuncCall }

procedure TExpFuncCall.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
end;


{$ifdef minimal} {$WARNINGS OFF} {$endif}
procedure TExpFuncCall.Execute;
var
  V,A1,A2,A3 : single;
  I1,I2 : integer;
  HasReturnValue : boolean;
begin
  HasReturnValue := True;
  case Kind of
    fcSin :  V := Sin(StackPopFloat);
    fcSqrt : V := Sqrt(StackPopFloat);
    fcCos : V := Cos(StackPopFloat);
    fcAbs : V := Abs(StackPopFloat);
    fcRnd : V := System.Random;
    fcFrac : V := Frac(StackPopFloat);
    fcExp : V := Exp(StackPopFloat);
    fcTan : V := Tan(StackPopFloat);
    fcCeil : V := Ceil(StackPopFloat);
    fcFloor : V := Floor(StackPopFloat);
    fcAcos : V := ArcCos(StackPopFloat);
    fcAsin : V := ArcSin(StackPopFloat);
    fcRound : PInteger(@V)^ := Round(StackPopFloat);

    fcRandom :
      begin
        StackPopTo(A2); //Variance
        StackPopTo(A1); //Base
        V := A1 + ((2*System.Random-1.0) * A2);
      end;
    fcAtan2 :
      begin
        StackPopTo(A2);
        StackPopTo(A1);
        V := ArcTan2(A1,A2);
      end;
    fcNoise2 :
      begin
        StackPopTo(A2);
        StackPopTo(A1);
        V := PerlinNoise2(A1,A2);
      end;
    fcNoise3 :
      begin
        StackPopTo(A3);
        StackPopTo(A2);
        StackPopTo(A1);
        V := PerlinNoise3(A1,A2,A3);
      end;
    fcClamp :
      begin
        StackPopTo(A3);
        StackPopTo(A2);
        StackPopTo(A1);
        V := Clamp(A1,A2,A3);
      end;
    fcPow :
      begin
        StackPopTo(A2);
        StackPopTo(A1);
        V := ZMath.Power(A1,A2);
      end;
    fcCenterMouse :
      begin
        HasReturnValue := False;
        Platform_SetMousePos(ScreenWidth div 2,ScreenHeight div 2);
      end;
    fcSetRandomSeed :
      begin
        V := System.RandSeed; //int to float
        System.RandSeed := Round(StackPopFloat); //float to int
      end;
    fcQuit :
      begin
        HasReturnValue := False;
        ZApp.Terminating := True;
      end;
    fcJoyGetAxis :
      begin
        StackPopTo(I2);
        StackPopTo(I1);
        V := Platform_GetJoystickAxis(I1,I2);
      end;
    fcJoyGetButton :
      begin
        StackPopTo(I2);
        StackPopTo(I1);
        PInteger(@V)^ := Ord(Platform_GetJoystickButton(I1,I2)) and 1;
      end;
    fcJoyGetPOV :
      begin
        StackPopTo(I1);
        V := Platform_GetJoystickPOV(I1);
      end;
  {$ifndef minimal}else begin ZHalt('Invalid func op'); exit; end;{$endif}
  end;
  if HasReturnValue then
    StackPush(V);
end;
{$ifdef minimal} {$WARNINGS ON} {$endif}

{ TDefineConstant }

procedure TDefineConstant.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Value',{$ENDIF}integer(@Value) - integer(Self), zptFloat);
   {$ifndef minimal}List.GetLast.NeedRefreshNodeName := True; {$endif}
end;

{$ifndef minimal}
function TDefineConstant.GetDisplayName: string;
begin
  Result := inherited GetDisplayName + ' ' + FormatFloat('###0.#',Value);
end;
{$endif}

{ TExpArrayRead }

procedure TExpArrayRead.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'TheArray',{$ENDIF}integer(@TheArray) - integer(Self), zptComponentRef);
end;

procedure TExpArrayRead.Execute;
var
  V : single;
  P : PFloat;
begin
  P := TheArray.PopAndGetElement;
  {$ifndef minimal}
  if P=nil then
    ZHalt('Array read outside range: ' + TheArray.Name);
  {$endif}
  V := P^;
  StackPush( V );
end;

{ TDefineArray }

procedure TDefineArray.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Dimensions',{$ENDIF}integer(@Dimensions) - integer(Self), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['One','Two','Three']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'SizeDim1',{$ENDIF}integer(@SizeDim1) - integer(Self), zptInteger);
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'SizeDim2',{$ENDIF}integer(@SizeDim2) - integer(Self), zptInteger);
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'SizeDim3',{$ENDIF}integer(@SizeDim3) - integer(Self), zptInteger);
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Persistent',{$ENDIF}integer(@Persistent) - integer(Self), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'Values',{$ENDIF}integer(@Values) - integer(Self), zptBinary);
end;

destructor TDefineArray.Destroy;
begin
  if Data<>nil then
    FreeMem(Data);
  inherited;
end;

function TDefineArray.GetData: PFloat;
begin
  {$ifndef minimal}
  //Array size can only be changed in zdesigner, not runtime
  if Limit<>CalcLimit then
    AllocData;
  {$endif}
  if Persistent then
  begin
    if Values.Data=nil then
      AllocData;
    Result := PFloat(Values.Data)
  end
  else
  begin
    if Data=nil then
      AllocData;
    Result := PFloat(Data);
  end;
end;

function TDefineArray.CalcLimit: integer;
begin
  Result := SizeDim1 * (SizeDim2 + 1) * (SizeDim3 + 1);
end;

procedure TDefineArray.AllocData;
var
  ByteSize: Integer;
  P : PPointer;
  WasNil : boolean;
begin
  Self.Limit := CalcLimit;
  ByteSize := Limit * SizeOf(single);
  if Persistent then
  begin
    Self.Values.Size := ByteSize;
    P := @Self.Values.Data
  end
  else
    P := @Self.Data;
  WasNil := P^ = nil;
  ReallocMem(P^, ByteSize);
  if WasNil then
    FillChar(P^^, ByteSize, 0);
end;

function TDefineArray.PopAndGetElement : PFloat;
var
  Index,I1,I2,I3 : integer;
  P : PFloatArray;
begin
  StackPopTo(I3);
  if Self.Dimensions>=dadTwo then
    StackPopTo(I2)
  else
    I2 := 0;
  if Self.Dimensions=dadThree then
    StackPopTo(I1)
  else
    I1 := 0;

  case Self.Dimensions of
    dadOne: Index := I3;
    dadTwo: Index := (I2*SizeDim2) + I3;
  else
    Index := (I1*SizeDim2*SizeDim3) + (I2*SizeDim3) + I3;
  end;

  P := PFloatArray(GetData);

  {$ifndef minimal}
  if ((Index<0) or (Index>=Limit)) or
    ((I1<0) or (I2<0) or (I3<0)) or
    ((Dimensions=dadOne) and (I3>=SizeDim1)) or
    ((Dimensions=dadTwo) and ((I2>=SizeDim1) or (I3>=SizeDim2))) or
    ((Dimensions=dadThree) and ((I1>=SizeDim1) or (I2>=SizeDim2) or (I3>=SizeDim3)))
    then
  begin
    {$ifdef zlog}
    ZLog.GetLog(Self.ClassName).Warning('Array access outside range: ' + Self.Name + ' ' + IntToStr(I1) + ' ' + IntToStr(I2) + ' ' + IntToStr(I3));
    {$endif}
    Result := nil;
    Exit;
  end;
  {$endif}

  Result := @P^[Index];
end;

{ TExpArrayWrite }

procedure TExpArrayWrite.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'TheArray',{$ENDIF}integer(@TheArray) - integer(Self), zptComponentRef);
end;

procedure TExpArrayWrite.Execute;
var
  P : Pointer;
begin
  P := TheArray.PopAndGetElement;
  {$ifndef minimal}
  if P=nil then
    ZHalt('Array assign outside range: ' + TheArray.Name);
  {$endif}
  StackPush(P);
end;

{ TExpStackFrame }

procedure TExpStackFrame.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Size',{$ENDIF}integer(@Size) - integer(Self), zptInteger);
end;

procedure TExpStackFrame.Execute;
//http://en.wikipedia.org/wiki/Function_prologue
begin
  StackPush(gCurrentBP);
  gCurrentBP := StackGetDepth;
  //Add frame to stack
  Inc(ZcStackPtr,Self.Size);
end;

{ TExpAccessLocal }

procedure TExpAccessLocal.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
  List.AddProperty({$IFNDEF MINIMAL}'Index',{$ENDIF}integer(@Index) - integer(Self), zptInteger);
end;

procedure TExpAccessLocal.Execute;
var
  P : PInteger;  //4 byte data
begin
  P := StackGetPtrToItem( gCurrentBP + Self.Index );
  case Kind of
    loLoad: StackPush(P^);
    loStore: StackPopTo(P^);
  end;
end;

{ TExpReturn }

procedure TExpReturn.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'HasFrame',{$ENDIF}integer(@HasFrame) - integer(Self), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'IsFunction',{$ENDIF}integer(@IsFunction) - integer(Self), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'HasReturnValue',{$ENDIF}integer(@HasReturnValue) - integer(Self), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'Arguments',{$ENDIF}integer(@Arguments) - integer(Self), zptInteger);
end;

{$warnings off}
procedure TExpReturn.Execute;
var
  RetVal : integer;
begin
  if HasReturnValue then
  begin
    //Local0 holds returnvalue
    RetVal := PInteger( StackGetPtrToItem( gCurrentBP ) )^;
  end;

  if HasFrame then
  begin
    Dec(ZcStackPtr,StackGetDepth-gCurrentBP);
    StackPopTo(gCurrentBP);
  end;

  //Get return adress
  StackPopTo(gCurrentPc);

  //Clean stack of function arguments
  Dec(ZcStackPtr,Arguments);

  if HasReturnValue then
  begin
    StackPush(RetVal);
  end;
end;
{$warnings on}

{ TExpBase }

{$ifndef minimal}
function TExpBase.ExpAsText: string;
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I : integer;
  S : string;
begin
  Result := Copy(ComponentManager.GetInfo(Self).ZClassName,4,255);
  PropList := Self.GetProperties;
  for I := 3 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    Self.GetProperty(Prop,Value);
    case Prop.PropertyType of
      zptFloat,zptScalar : S := FloatToStr( RoundTo( Value.FloatValue ,-FloatTextDecimals) );
      zptInteger : S := IntToStr(Value.IntegerValue);
      zptComponentRef : S := Value.ComponentValue.Name;
      zptPropertyRef :
        begin
          S := Value.PropertyValue.Component.Name + ' ' + Value.PropertyValue.Prop.Name;
          if Value.PropertyValue.Index>0 then
            S := S + ' ' + IntToStr(Value.PropertyValue.Index);
        end;
      zptByte : S := IntToStr(Value.ByteValue);
      zptBoolean : S := IntToStr( byte(Value.BooleanValue) );
    else
      S := '';
    end;
    Result:=Result + ' ' + S;
  end;
end;
{$endif}

{ TExpMisc }

procedure TExpMisc.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
end;

procedure TExpMisc.Execute;
var
  V : integer;
begin
  case Kind of
    emPop: StackPopFloat;  //Pop, discard value from top of stack
    emDup :
      begin
        StackPopTo(V);
        StackPush(V);
        StackPush(V);
      end;
  end;
end;

{ TZLibrary }

procedure TZLibrary.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Source',{$ENDIF}integer(@Source) - integer(Self), zptExpression);
end;

{ TExpUserFuncCall }

procedure TExpUserFuncCall.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Lib',{$ENDIF}integer(@Lib) - integer(Self), zptComponentRef);
  List.AddProperty({$IFNDEF MINIMAL}'Index',{$ENDIF}integer(@Index) - integer(Self), zptInteger);
end;

procedure TExpUserFuncCall.Execute;
begin
  StackPush(gCurrentPC);
  gCurrentPC := Lib.Source.Code.GetPtrToItem(Index);
  Dec(gCurrentPc);
end;

{ TExpConvert }

procedure TExpConvert.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind) - integer(Self), zptByte);
end;

procedure TExpConvert.Execute;
var
  V : single;
  I : integer;
begin
  case Kind of
    eckFloatToInt:
      begin
        I := Trunc(StackPopFloat);
        StackPush(I);
      end;
    eckIntToFloat :
      begin
        StackPopTo(I);
        V := I;
        StackPush(V);
      end;
  end;
end;

{ TExpAssign4 }

procedure TExpAssign4.Execute;
var
  I : integer;
  P : pointer;
begin
  StackPopTo(I);
  StackPopTo(P);
  PInteger(P)^ := I;
end;

{ TExpAssign1 }

procedure TExpAssign1.Execute;
var
  V : integer;
  B : byte;
  P : pointer;
begin
  //Cast integer to byte before assigning
  StackPopTo(V);
  StackPopTo(P);
  B := V;
  PByte(P)^ := B;
end;

{ TDefineVariableBase }

procedure TDefineVariableBase.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Type',{$ENDIF}integer(@_Type) - integer(Self), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Float','Integer']);{$endif}
end;

initialization

  ZClasses.Register(TZExpression,ZExpressionClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=2;{$endif}
  ZClasses.Register(TZLibrary,ZLibraryClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=2;{$endif}
  ZClasses.Register(TDefineVariable,DefineVariableClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=8;{$endif}
  ZClasses.Register(TDefineConstant,DefineConstantClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ExcludeFromBinary:=True;{$endif}
  ZClasses.Register(TDefineArray,DefineArrayClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=8;{$endif}

  ZClasses.Register(TExpConstantFloat,ExpConstantFloatClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpConstantInt,ExpConstantIntClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpOpBinaryFloat,ExpOpBinaryFloatClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpOpBinaryInt,ExpOpBinaryIntClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpPropValue4,ExpPropValue4ClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpPropValue1,ExpPropValue1ClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpPropPtr,ExpPropPtrClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpJump,ExpJumpClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpFuncCall,ExpFuncCallClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpArrayRead,ExpArrayReadClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpArrayWrite,ExpArrayWriteClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpStackFrame,ExpStackFrameClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpAccessLocal,ExpAccessLocalClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpReturn,ExpReturnClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpMisc,ExpMiscClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpUserFuncCall,ExpUserFuncCallClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpConvert,ExpConvertClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpAssign4,ExpAssign4ClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}
  ZClasses.Register(TExpAssign1,ExpAssign1ClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate:=True;{$endif}

end.