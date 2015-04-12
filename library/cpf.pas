{ *********************************************************************** }
{ "Crystal Path Finding" (cpf) is a very small part of CrystalEngine,     }
{ that helps to find the shortest paths with A*/WA* algorithms.           }
{                                                                         }
{ email: softforyou@inbox.ru                                              }
{ skype: dimandevil                                                       }
{ repository: https://github.com/d-mozulyov/CrystalPathFinding            }
{ *********************************************************************** }

{.$define NOEXCEPTIONS}

unit cpf;

// compiler directives
{$ifdef FPC}
  {$mode Delphi}
  {$asmmode Intel}
  {$define INLINESUPPORT}
{$else}
  {$if CompilerVersion >= 24}
    {$LEGACYIFEND ON}
  {$ifend}
  {$if CompilerVersion >= 15}
    {$WARN UNSAFE_CODE OFF}
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$ifend}
  {$if (CompilerVersion < 23)}
    {$define CPUX86}
  {$ifend}
  {$if (CompilerVersion >= 17)}
    {$define INLINESUPPORT}
  {$ifend}
  {$if CompilerVersion >= 21}
    {$WEAKLINKRTTI ON}
    {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$ifend}
{$endif}
{$U-}{$V+}{$B-}{$X+}{$T+}{$P+}{$H+}{$J-}{$Z1}{$A4}
{$O+}{$R-}{$I-}{$Q-}{$W-}
{$ifdef KOL_MCK}
  {$define KOL}
{$endif}

interface
  uses Types 
       {$ifNdef NOEXCEPTIONS}
         {$ifdef KOL}
           , KOL, err
         {$else}
           , SysUtils
         {$endif}
       {$endif};

type
  // standard types
  {$ifdef FPC}
    Integer = Longint;
    PInteger = ^Integer;
  {$else}
    {$if CompilerVersion < 19}
      NativeInt = Integer;
      NativeUInt = Cardinal;
    {$ifend}
    {$if CompilerVersion < 22}
      PNativeInt = ^NativeInt;
      PNativeUInt = ^NativeUInt;
    {$ifend}
  {$endif}

  // map tile
  TPathMapTile = type Byte;
  PPathMapTile = ^TPathMapTile;

  // kind of map
  TPathMapKind = (mkSimple, mkDiagonal, mkDiagonalEx, mkHexagonal);

  // points as array
  PPointList = ^TPointList;
  TPointList = array[0..High(Integer) div SizeOf(TPoint) - 1] of TPoint;

  // exception class
  {$ifNdef NOEXCEPTIONS}
  ECrystalPathFinding = class(Exception)
  {$ifdef KOL}
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    constructor CreateRes(Ident: NativeUInt); overload;
    constructor CreateRes(ResStringRec: PResStringRec); overload;
    constructor CreateResFmt(Ident: NativeUInt; const Args: array of const); overload;
    constructor CreateResFmt(ResStringRec: PResStringRec; const Args: array of const); overload;
  {$endif}
  end;  
  {$endif}
  
  // Result of FindPath() function
  TPathMapResult = packed record
    Points: PPointList;
    PointsCount: NativeUInt;
    Distance: Double;
  end;
  PPathMapResult = ^TPathMapResult;

  // handle type
  PCPFHandle = ^TCPFHandle;
  TCPFHandle = type NativeUInt;

  // object oriented Weights interface
  TPathMapWeights = class(TObject)
  private
    FHandle: TCPFHandle;
    FHighTile: TPathMapTile;

    function GetValue(const Tile: TPathMapTile): Single; {$ifdef INLINESUPPORT}inline;{$endif}
    procedure SetValue(const Tile: TPathMapTile; const Value: Single); {$ifdef INLINESUPPORT}inline;{$endif}
  {$ifdef AUTOREFCOUNT}protected{$else}public{$endif}
    destructor Destroy; override;
  public
    constructor Create(const AHighTile: TPathMapTile);

    property HighTile: TPathMapTile read FHighTile;
    property Handle: TCPFHandle read FHandle;
    property Values[const Tile: TPathMapTile]: Single read GetValue write SetValue; default;
  end;

  // object oriented Map interface
  TPathMap = class(TObject)
  private
    FHandle: TCPFHandle;
    FWidth: Word;
    FHeight: Word;
    FKind: TPathMapKind;
    FHighTile: TPathMapTile;
    FSectorTest: Boolean;
    FUseCache: Boolean;

    function GetTile(const X, Y: Word): TPathMapTile; {$ifdef INLINESUPPORT}inline;{$endif}
    procedure SetTile(const X, Y: Word; const Value: TPathMapTile); {$ifdef INLINESUPPORT}inline;{$endif}
  {$ifdef AUTOREFCOUNT}protected{$else}public{$endif}
    destructor Destroy; override;
  public
    constructor Create(const AWidth, AHeight: Word; const AKind: TPathMapKind = mkSimple; const AHighTile: TPathMapTile = 0);
    procedure Clear(); {$ifdef INLINESUPPORT}inline;{$endif}
    procedure Update(const ATiles: PPathMapTile; const X, Y, AWidth, AHeight: Word; const Pitch: NativeInt = 0); {$ifdef INLINESUPPORT}inline;{$endif}

    property Width: Word read FWidth;
    property Height: Word read FHeight;
    property Kind: TPathMapKind read FKind;
    property HighTile: TPathMapTile read FHighTile;
    property SectorTest: Boolean read FSectorTest write FSectorTest;
    property UseCache: Boolean read FUseCache write FUseCache;
    property Handle: TCPFHandle read FHandle;
    property Tiles[const X, Y: Word]: TPathMapTile read GetTile write SetTile; default;

    function FindPath(const Start, Finish: TPoint; const Weights: TPathMapWeights = nil;
      const ExcludePoints: PPoint = nil; const ExcludePointsCount: NativeUInt = 0): PPathMapResult; {$ifdef INLINESUPPORT}inline;{$endif}
  end;


{ Dynamic link library API }

const
  cpf_lib = 'cpf.dll';

function  cpfCreateWeights(HighTile: TPathMapTile): TCPFHandle; cdecl; external cpf_lib;
procedure cpfDestroyWeights(var HWeights: TCPFHandle); cdecl; external cpf_lib;  
function  cpfWeightGet(HWeights: TCPFHandle; Tile: TPathMapTile): Single; cdecl; external cpf_lib;
procedure cpfWeightSet(HWeights: TCPFHandle; Tile: TPathMapTile; Value: Single); cdecl; external cpf_lib;
function  cpfCreateMap(Width, Height: Word; Kind: TPathMapKind = mkSimple; HighTile: TPathMapTile = 0): TCPFHandle; cdecl; external cpf_lib;
procedure cpfDestroyMap(var HMap: TCPFHandle); cdecl; external cpf_lib;  
procedure cpfMapClear(HMap: TCPFHandle); cdecl; external cpf_lib;  
procedure cpfMapUpdate(HMap: TCPFHandle; Tiles: PPathMapTile; X, Y, Width, Height: Word; Pitch: NativeInt = 0); cdecl; external cpf_lib;
function  cpfMapGetTile(HMap: TCPFHandle; X, Y: Word): TPathMapTile; cdecl; external cpf_lib;
procedure cpfMapSetTile(HMap: TCPFHandle; X, Y: Word; Value: TPathMapTile); cdecl; external cpf_lib;
function  cpfFindPath(HMap: TCPFHandle; Start, Finish: TPoint; HWeights: TCPFHandle = 0; ExcludePoints: PPoint = nil; ExcludePointsCount: NativeUInt = 0; SectorTest: Boolean = True; UseCache: Boolean = True): PPathMapResult; cdecl; external cpf_lib;

implementation
var
  MemoryManager: {$if Defined(FPC) or (CompilerVersion < 18)}TMemoryManager{$else}TMemoryManagerEx{$ifend};

  
{ ECrystalPathFinding }  
  
{$if Defined(KOL) and (not Defined(NOEXCEPTIONS)))}
constructor ECrystalPathFinding.Create(const Msg: string);
begin
  inherited Create(e_Custom, Msg);
end;

constructor ECrystalPathFinding.CreateFmt(const Msg: string;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, Msg, Args);
end;

type
  PStrData = ^TStrData;
  TStrData = record
    Ident: Integer;
    Str: string;
  end;

function EnumStringModules(Instance: NativeInt; Data: Pointer): Boolean;
var
  Buffer: array [0..1023] of Char;
begin
  with PStrData(Data)^ do
  begin
    SetString(Str, Buffer, Windows.LoadString(Instance, Ident, Buffer, sizeof(Buffer)));
    Result := Str = '';
  end;
end;

function FindStringResource(Ident: Integer): string;
var
  StrData: TStrData;
  Func: TEnumModuleFunc;
begin
  StrData.Ident := Ident;
  StrData.Str := '';
  Pointer(@Func) := @EnumStringModules;
  EnumResourceModules(Func, @StrData);
  Result := StrData.Str;
end;

function LoadStr(Ident: Integer): string;
begin
  Result := FindStringResource(Ident);
end;

constructor ECrystalPathFinding.CreateRes(Ident: NativeUInt);
begin
  inherited Create(e_Custom, LoadStr(Ident));
end;

constructor ECrystalPathFinding.CreateRes(ResStringRec: PResStringRec);
begin
  inherited Create(e_Custom, System.LoadResString(ResStringRec));
end;

constructor ECrystalPathFinding.CreateResFmt(Ident: NativeUInt;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, LoadStr(Ident), Args);
end;

constructor ECrystalPathFinding.CreateResFmt(ResStringRec: PResStringRec;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, System.LoadResString(ResStringRec), Args);
end;
{$ifend}  


{ TPathMapWeights }

constructor TPathMapWeights.Create(const AHighTile: TPathMapTile);
begin
  inherited Create;

  FHighTile := AHighTile;
  FHandle := cpfCreateWeights(AHighTile);
end;

destructor TPathMapWeights.Destroy;
begin
  cpfDestroyWeights(FHandle);
  inherited;
end;

function TPathMapWeights.GetValue(const Tile: TPathMapTile): Single;
begin
  Result := cpfWeightGet(FHandle, Tile);
end;

procedure TPathMapWeights.SetValue(const Tile: TPathMapTile;
  const Value: Single);
begin
  cpfWeightSet(FHandle, Tile, Value);
end;


{ TPathMap }

constructor TPathMap.Create(const AWidth, AHeight: Word;
  const AKind: TPathMapKind; const AHighTile: TPathMapTile);
begin
  inherited Create;

  FWidth := AWidth;
  FHeight := AHeight;
  FKind := AKind;
  FHighTile := AHighTile;
  FUseCache := True;

  FHandle := cpfCreateMap(AWidth, AHeight, AKind, AHighTile);
end;

destructor TPathMap.Destroy;
begin
  cpfDestroyMap(FHandle);
  inherited;
end;

function TPathMap.GetTile(const X, Y: Word): TPathMapTile;
begin
  Result := cpfMapGetTile(FHandle, X, Y);
end;

procedure TPathMap.SetTile(const X, Y: Word; const Value: TPathMapTile);
begin
  cpfMapSetTile(FHandle, X, Y, Value);
end;

procedure TPathMap.Update(const ATiles: PPathMapTile; const X, Y, AWidth,
  AHeight: Word; const Pitch: NativeInt);
begin
  cpfMapUpdate(FHandle, ATiles, X, Y, AWidth, AHeight, Pitch);
end;

procedure TPathMap.Clear;
begin
  cpfMapClear(FHandle);
end;

function TPathMap.FindPath(const Start, Finish: TPoint;
  const Weights: TPathMapWeights; const ExcludePoints: PPoint;
  const ExcludePointsCount: NativeUInt): PPathMapResult;
begin
  Result := cpfFindPath(FHandle, Start, Finish, TCPFHandle(Weights),
    ExcludePoints, ExcludePointsCount, FSectorTest, FUseCache);
end;


{ Low level callbacks }

type
  TCPFAlloc = function(Size: NativeUInt): Pointer; cdecl;
  TCPFFree = function(P: Pointer): Boolean; cdecl;
  TCPFRealloc = function(P: Pointer; Size: NativeUInt): Pointer; cdecl;
  TCPFException = procedure(Message: PWideChar; Address: Pointer); cdecl;
  TCPFCallbacks = packed record
    Alloc: TCPFAlloc;
    Free: TCPFFree;
    Realloc: TCPFRealloc;
    Exception: TCPFException;
  end;
  
function CPFAlloc(Size: NativeUInt): Pointer; cdecl;
begin
  Result := MemoryManager.GetMem(Size);
end;

function CPFFree(P: Pointer): Boolean; cdecl;
begin
  Result := (MemoryManager.FreeMem(P) = 0);
end;

function CPFRealloc(P: Pointer; Size: NativeUInt): Pointer; cdecl;
begin
  Result := MemoryManager.ReallocMem(P, Size);
end;

procedure CPFException(Message: PWideChar; Address: Pointer); cdecl;
var
  Text: string;
begin
  Text := Message;

  {$ifdef NOEXCEPTIONS}
    // Assert(False, Text, Address);
    if Assigned(AssertErrorProc) then
    begin
      AssertErrorProc(Text, 'cpf.pas', 0, Address)
    end else
    begin
     System.ErrorAddr := Address;
     System.ExitCode := 207{reInvalidOp};
     System.Halt;
    end;
  {$else}
    raise ECrystalPathFinding.Create(Text) at Address;
  {$endif}
end;


const
  CPFCallbacks: TCPFCallbacks = (
    Alloc: CPFAlloc;
    Free: CPFFree;
    Realloc: CPFRealloc;
    Exception: CPFException; 
  );

procedure cpfInitialize(const Callbacks: TCPFCallbacks); cdecl; external cpf_lib;    


initialization
  System.GetMemoryManager(MemoryManager);
  cpfInitialize(CPFCallbacks);

end.
