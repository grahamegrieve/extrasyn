{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterTclTk.pas, released 2000-05-05.
The Original Code is based on the siTclTkSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Igor Shitikov.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynHighlighterTclTk.pas,v 1.20 2019/06/06 16:53:25 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a TCL/Tk highlighter for SynEdit)
@author(Igor Shitikov, converted to SynEdit by David Muir <dhm@dmsoftware.co.uk>)
@created(5 December 1999, converted to SynEdit April 18, 2000)
@lastmod(2019/06/06) MOD by M.A.R.C. for SBACreator
The SynHighlighterTclTk unit provides SynEdit with a TCL/Tk highlighter.
}

{$IFNDEF QSYNHIGHLIGHTERTCLTK}
unit SynHighlighterTclTk;
{$ENDIF}

// extrasyn.inc is the synedit.inc from laz 1.2.0 synedit package source,
// If it has changed in newer version you might need to copy it again.
// Remember to redclare the syn_lazarus define.
{$I extrasyn.inc}


interface

uses
{$IFDEF SYN_CLX}
  QGraphics,
  QSynEditTypes,
  QSynEditHighlighter,
{$ELSE}
  Graphics,
  SynEditHighlighter,
  SynEditHighlighterFoldBase,
{$ENDIF}
  SysUtils,
  Classes;

type
  TtkTokenKind = (tkComment, tkIdentifier, tkKey, tkNull, tkNumber, tkSecondKey,
    tkSpace, tkString, tkSymbol, tkUnknown);

  TRangeState = (rsUnknown);

  TProcTableProc = procedure of object;

  TBlockID = (
    BodyBlk
    );

type
  TSynTclTkSyn = class(TSynCustomFoldHighlighter)
  private
    fRange: TRangeState;
    fLine: PChar;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fTokenPos: Integer;
    FTokenID: TtkTokenKind;
    fLineNumber: Integer;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fSecondKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fCommentAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fKeyWords: TStrings;
    fSecondKeys: TStrings;
    procedure BraceOpenProc;
    procedure BraceCloseProc;
    procedure PointCommaProc;
    procedure CRProc;
    procedure IdentProc;
    procedure LFProc;
    procedure NullProc;
    procedure NumberProc;
    procedure RoundOpenProc;
    procedure HashProc;
    procedure SlashProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure UnknownProc;
    procedure MakeMethodTables;
    procedure SetKeyWords(const Value: TStrings);
    procedure SetSecondKeys(const Value: TStrings);
    function IsKeywordListStored: boolean;
  protected
    function GetSampleSource: string; override;
    function IsFilterStored: Boolean; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetRange: Pointer; override;
    function GetTokenID: TtkTokenKind;
    function IsKeyword(const AKeyword: string): boolean; override;
    function IsSecondKeyWord(aToken: string): Boolean;
    {$IFDEF SYN_LAZARUS}
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    {$ENDIF}
    procedure SetLine(const NewValue: string; LineNumber:Integer); override;
    function GetToken: string; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    {$IFNDEF SYN_LAZARUS} {$IFNDEF SYN_CLX}
    function SaveToRegistry(RootKey: HKEY; Key: string): boolean; override;
    function LoadFromRegistry(RootKey: HKEY; Key: string): boolean; override;
    {$ENDIF} {$ENDIF}
  published
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property KeyWords: TStrings read fKeyWords write SetKeyWords
      stored IsKeywordListStored;
    property SecondKeyAttri: TSynHighlighterAttributes read fSecondKeyAttri
      write fSecondKeyAttri;
    property SecondKeyWords: TStrings read fSecondKeys write SetSecondKeys;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
  end;

implementation

uses
{$IFDEF SYN_CLX}
  QSynEditStrConst;
{$ELSE}
  SynEditStrConst, SynEditStrConstExtra;
{$ENDIF}

const
   TclTkKeys: array[0..146] of string = (
     'AFTER', 'APPEND', 'ARRAY', 'BELL', 'BGERROR', 'BINARY', 'BIND',
     'BINDIDPROC', 'BINDPROC', 'BINDTAGS', 'BITMAP', 'BREAK', 'BUTTON',
     'CANVAS', 'CATCH', 'CD', 'CHECKBUTTON', 'CLIPBOARD', 'CLOCK',
     'CLOSE', 'CONCAT', 'CONTINUE', 'DESTROY', 'ELSE', 'ENTRY', 'EOF',
     'ERROR', 'EVAL', 'EVENT', 'EXEC', 'EXIT', 'EXPR', 'FBLOCKED',
     'FCONFIGURE', 'FCOPY', 'FILE', 'FILEEVENT', 'FILENAME', 'FLUSH',
     'FOCUS', 'FONT', 'FOR', 'FOREACH', 'FORMAT', 'FRAME', 'GETS', 'GLOB',
     'GLOBAL', 'GRAB', 'GRID', 'HISTORY', 'HTTP', 'IF', 'IMAGE', 'INCR',
     'INFO', 'INTERP', 'JOIN', 'LABEL', 'LAPPEND', 'LIBRARY', 'LINDEX',
     'LINSERT', 'LIST', 'LISTBOX', 'LLENGTH', 'LOAD', 'LOADTK', 'LOWER',
     'LRANGE', 'LREPLACE', 'LSEARCH', 'LSORT', 'MENU', 'MESSAGE', 'NAMESPACE',
     'NAMESPUPD', 'OPEN', 'OPTION', 'OPTIONS', 'PACK', 'PACKAGE', 'PHOTO',
     'PID', 'PKG_MKINDEX', 'PLACE', 'PROC', 'PUTS', 'PWD', 'RADIOBUTTON',
     'RAISE', 'READ', 'REGEXP', 'REGISTRY', 'REGSUB', 'RENAME', 'RESOURCE',
     'RETURN', 'RGB', 'SAFEBASE', 'SCALE', 'SCAN', 'SEEK', 'SELECTION',
     'SEND', 'SENDOUT', 'SET', 'SOCKET', 'SOURCE', 'SPLIT', 'STRING', 'SUBST',
     'SWITCH', 'TCL', 'TCLVARS', 'TELL', 'TEXT', 'THEN', 'TIME', 'TK',
     'TK_BISQUE', 'TK_CHOOSECOLOR', 'TK_DIALOG', 'TK_FOCUSFOLLOWSMOUSE',
     'TK_FOCUSNEXT', 'TK_FOCUSPREV', 'TK_GETOPENFILE', 'TK_GETSAVEFILE',
     'TK_MESSAGEBOX', 'TK_OPTIONMENU', 'TK_POPUP', 'TK_SETPALETTE', 'TKERROR',
     'TKVARS', 'TKWAIT', 'TOPLEVEL', 'TRACE', 'UNKNOWN', 'UNSET', 'UPDATE',
     'UPLEVEL', 'UPVAR', 'VARIABLE', 'VWAIT', 'WHILE', 'WINFO', 'WM');

var
  Identifiers: array[#0..#255] of ByteBool;
  mHashTable: array[#0..#255] of Integer;

procedure MakeIdentTable;
var
  I, J: Char;
begin
  for I := #0 to #255 do
  begin
    case I of
      '_', '0'..'9', 'a'..'z', 'A'..'Z': Identifiers[I] := True;
      else
        Identifiers[I] := False;
    end;
    J := UpCase(I);
    case I in ['_', '0'..'9', 'A'..'Z', 'a'..'z'] of
      True: mHashTable[I] := Ord(J)
        else
          mHashTable[I] := 0;
    end;
  end;
end;

function TSynTclTkSyn.IsKeyword(const AKeyword: string): boolean;
var
  First, Last, I, Compare: Integer;
  Token: String;
begin
  First := 0;
  Last := fKeywords.Count - 1;
  Result := False;
  Token := UpperCase(AKeyword);
  while First <= Last do
  begin
    I := (First + Last) shr 1;
    Compare := CompareStr(fKeywords[i], Token);
    if Compare = 0 then
    begin
      Result := True;
      break;
    end
    else
      if Compare < 0 then First := I + 1 else Last := I - 1;
  end;
end; { IsKeyWord }

function TSynTclTkSyn.IsSecondKeyWord(aToken: String): Boolean;
var
  First, Last, I, Compare: Integer;
  Token: String;
begin
  First := 0;
  Last := fSecondKeys.Count - 1;
  Result := False;
  Token := UpperCase(aToken);
  while First <= Last do
  begin
    I := (First + Last) shr 1;
    Compare := CompareStr(fSecondKeys[i], Token);
    if Compare = 0 then
    begin
      Result := True;
      break;
    end
    else
      if Compare < 0 then First := I + 1 else Last := I - 1;
  end;
end; { IsSecondKeyWord }

procedure TSynTclTkSyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    case I of
      #0: fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  NullProc;
      '#': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  HashProc;
      '{': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  BraceOpenProc;
      '}': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  BraceCloseProc;
      ';': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  PointCommaProc;
      '(': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  RoundOpenProc;
      '"': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  StringProc;
      '/': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  SlashProc;
      #10: fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  LFProc;
      #13: fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  CRProc;
      '0'..'9': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  NumberProc;
      'A'..'Z', 'a'..'z', '_': fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  IdentProc;
      #1..#9, #11, #12, #14..#32: fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  SpaceProc;
    else
      fProcTable[I] :=  {$IFDEF FPC}@{$ENDIF}  UnknownProc;
    end;
end;

constructor TSynTclTkSyn.Create(AOwner: TComponent);
var
   i: integer;
begin
  inherited Create(AOwner);
  fKeyWords := TStringList.Create;
  TStringList(fKeyWords).Sorted := True;
  TStringList(fKeyWords).Duplicates := dupIgnore;
  fSecondKeys := TStringList.Create;
  TStringList(fSecondKeys).Sorted := True;
  TStringList(fSecondKeys).Duplicates := dupIgnore;
  for i := Low(TclTkKeys) to High(TclTkKeys) do
    FKeyWords.Add(TclTkKeys[i]);

  fCommentAttri := TSynHighlighterAttributes.Create(SYNS_AttrComment);
  fCommentAttri.Style := [fsItalic];
  AddAttribute(fCommentAttri);
  fIdentifierAttri := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier);
  AddAttribute(fIdentifierAttri);
  fKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord);
  fKeyAttri.Style := [fsBold];
  AddAttribute(fKeyAttri);
  fSecondKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrSecondReservedWord);
  fSecondKeyAttri.Style := [fsBold];
  AddAttribute(fSecondKeyAttri);
  fNumberAttri := TSynHighlighterAttributes.Create(SYNS_AttrNumber);
  AddAttribute(fNumberAttri);
  fSpaceAttri := TSynHighlighterAttributes.Create(SYNS_AttrSpace);
  AddAttribute(fSpaceAttri);
  fStringAttri := TSynHighlighterAttributes.Create(SYNS_AttrString);
  AddAttribute(fStringAttri);
  fSymbolAttri := TSynHighlighterAttributes.Create(SYNS_AttrSymbol);
  AddAttribute(fSymbolAttri);
  SetAttributesOnChange({$IFDEF FPC}@{$ENDIF}DefHighlightChange);

  MakeMethodTables;
  fRange := rsUnknown;
  fDefaultFilter := SYNS_FilterTclTk;
end; { Create }

destructor TSynTclTkSyn.Destroy;
begin
  fKeyWords.Free;
  fSecondKeys.Free;
  inherited Destroy;
end; { Destroy }

{$IFDEF SYN_LAZARUS}
procedure TSynTclTkSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength := Run - fTokenPos;
  TokenStart  := FLine + fTokenPos;
end;
{$ENDIF}

procedure TSynTclTkSyn.SetLine(const NewValue: String; LineNumber:Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end; { SetLine }

procedure TSynTclTkSyn.BraceOpenProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
  StartCodeFoldBlock(Pointer(PtrUInt(BodyBlk)));
end;

procedure TSynTclTkSyn.BraceCloseProc;
var Blk:TBlockID;
begin
  blk:=TBlockID(PtrUInt(TopCodeFoldBlockType));
  if blk=BodyBlk then EndCodeFoldBlock();
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynTclTkSyn.PointCommaProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynTclTkSyn.CRProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  if fLine[Run + 1] = #10 then Inc(Run);
end;

procedure TSynTclTkSyn.IdentProc;
begin
  while Identifiers[fLine[Run]] do inc(Run);
  if IsKeyWord(GetToken) then begin
    fTokenId := tkKey;
    Exit;
  end else fTokenId := tkIdentifier;
  if IsSecondKeyWord(GetToken)
    then fTokenId := tkSecondKey
    else fTokenId := tkIdentifier;
end;

procedure TSynTclTkSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynTclTkSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynTclTkSyn.NumberProc;
begin
  inc(Run);
  fTokenID := tkNumber;
  while FLine[Run] in ['0'..'9', '.', 'a'..'f', 'A'..'F', 'x', 'X'] do
  begin
    case FLine[Run] of
      '.':
        if FLine[Run + 1] = '.' then break;
    end;
    inc(Run);
  end;
end;

procedure TSynTclTkSyn.RoundOpenProc;
begin
  inc(Run);
  fTokenId := tkSymbol;
end;

procedure TSynTclTkSyn.HashProc;
begin
  fTokenID := tkComment;
  while FLine[Run] <> #0 do
  begin
    case FLine[Run] of
      #10, #13: break;
    end;
    inc(Run);
  end;
end;

procedure TSynTclTkSyn.SlashProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynTclTkSyn.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  while FLine[Run] in [#1..#9, #11, #12, #14..#32] do inc(Run);
end;

procedure TSynTclTkSyn.StringProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #34) and (FLine[Run + 2] = #34)
    then inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until (FLine[Run] = #34) and (FLine[Pred(Run)] <> '\');
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynTclTkSyn.UnknownProc;
begin
{$IFDEF SYN_MBCSSUPPORT}
  if FLine[Run] in LeadBytes then
    Inc(Run, 2)
  else
{$ENDIF}
//  inc(Run);
//  fTokenID := tkUnKnown;
  inc(Run);
  while (fLine[Run] in [#128..#191]) OR // continued utf8 subcode
   ((fLine[Run]<>#0) and (fProcTable[fLine[Run]] = @UnknownProc)) do inc(Run);
  fTokenID := tkUnknown;
end;

procedure TSynTclTkSyn.Next;
begin
  fTokenPos := Run;
  fProcTable[fLine[Run]];
end;

function TSynTclTkSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynTclTkSyn.GetEol: Boolean;
begin
  Result := fTokenID = tkNull;
end;

function TSynTclTkSyn.GetRange: Pointer;
begin
  CodeFoldRange.RangeType := Pointer(PtrInt(fRange));
  Result := inherited;
end;

function TSynTclTkSyn.GetToken: string;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  SetString(Result, (FLine + fTokenPos), Len);
end;

function TSynTclTkSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynTclTkSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkComment: Result := fCommentAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkSecondKey: Result := fSecondKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynTclTkSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynTclTkSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

procedure TSynTclTkSyn.ResetRange;
begin
  inherited;
  fRange := rsUnknown;
end;

procedure TSynTclTkSyn.SetRange(Value: Pointer);
begin
//  fRange := TRangeState(PtrUInt(Value));
  inherited;
  fRange := TRangeState(PtrUInt(CodeFoldRange.RangeType));
end;

procedure TSynTclTkSyn.SetKeyWords(const Value: TStrings);
var
  i: Integer;
begin
  if Value <> nil then
    begin
      Value.BeginUpdate;
      for i := 0 to Value.Count - 1 do
        Value[i] := UpperCase(Value[i]);
      Value.EndUpdate;
    end;
  fKeyWords.Assign(Value);
  DefHighLightChange(nil);
end;

procedure TSynTclTkSyn.SetSecondKeys(const Value: TStrings);
var
  i: Integer;
begin
  if Value <> nil then
    begin
      Value.BeginUpdate;
      for i := 0 to Value.Count - 1 do
        Value[i] := UpperCase(Value[i]);
      Value.EndUpdate;
    end;
  fSecondKeys.Assign(Value);
  DefHighLightChange(nil);
end;

function TSynTclTkSyn.IsFilterStored: Boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterTclTk;
end;

class function TSynTclTkSyn.GetLanguageName: string;
begin
  Result := SYNS_LangTclTk;
end;

{$IFNDEF SYN_LAZARUS} {$IFNDEF SYN_CLX}
function TSynTclTkSyn.LoadFromRegistry(RootKey: HKEY; Key: string): boolean;
var
  r: TBetterRegistry;
begin
  r:= TBetterRegistry.Create;
  try
    r.RootKey := RootKey;
    if r.OpenKeyReadOnly(Key) then begin
      if r.ValueExists('KeyWords') then KeyWords.Text:= r.ReadString('KeyWords');
      Result := inherited LoadFromRegistry(RootKey, Key);
    end
    else Result := false;
  finally r.Free; end;
end;

function TSynTclTkSyn.SaveToRegistry(RootKey: HKEY; Key: string): boolean;     
var
  r: TBetterRegistry;
begin
  r:= TBetterRegistry.Create;
  try
    r.RootKey := RootKey;
    if r.OpenKey(Key,true) then begin
      Result := true;
      r.WriteString('KeyWords', KeyWords.Text);
      Result := inherited SaveToRegistry(RootKey, Key);
    end
    else Result := false;
  finally r.Free; end;
end;
{$ENDIF} {$ENDIF}

function TSynTclTkSyn.IsKeywordListStored: boolean;
var
  iKeys: TStringList;
  cDefKey: integer;
  iIndex: integer;
begin
  iKeys := TStringList.Create;
  try
    iKeys.Assign( KeyWords );
    iIndex := 0;
    for cDefKey := Low(TclTkKeys) to High(TclTkKeys) do
    begin
      iIndex:=iKeys.IndexOf(TclTkKeys[cDefKey]);
      if iIndex=-1 then
      begin
        Result := True;
        Exit;
      end;
      iKeys.Delete( iIndex );
    end;
    Result := iKeys.Count <> 0;
  finally
    iKeys.Free;
  end;
end;

function TSynTclTkSyn.GetSampleSource: string;
begin
  Result :=
    '#!/usr/local/tclsh8.0'#13#10 +
    'if {$argc < 2} {'#13#10 +
    '	puts stderr "Usage: $argv0 parameter"'#13#10 +
    '	exit 1'#13#10 +
    '}';
end;

initialization
  MakeIdentTable;
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TSynTclTkSyn);
{$ENDIF}
end.
