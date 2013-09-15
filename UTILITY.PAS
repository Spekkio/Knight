Unit Utility;

Interface

CONST      MaxX=80;     MaxY=25;
           HercHi=$0F;  HercHiU=$09;
           HercLo=$07;  HercLoU=$01;
           HercInv=$70; Blink=$80;

TYPE       ScreenType=ARRAY[1..MaxY,1..MaxX] OF
           RECORD
             CH: Char; ATT: Byte
           END;
           ScreenPtr=^ScreenType;

VAR        Mouse:Boolean;
           Color:Boolean;
           Screen: ScreenPtr;
          _Insert,_Shift,_Ctrl,_Alt,_NumLock,_CapsLock,_ScrollLock: Boolean;

PROCEDURE  ClrKeyBuf;                       { T”m tangentbordsbufferten }
PROCEDURE  GetStatusKeys;                   { Specialtangent intryckt ? }
PROCEDURE  HideCursor;                      { Koppla bort mark”ren      }
PROCEDURE  ShowCursor;                      { Koppla p† mark”ren        }
PROCEDURE  ResetMouse;                      { Initiera musen            }
PROCEDURE  Showmouse;                       { Visa musen                }
PROCEDURE  HideMouse;                       { G”m musen                 }
FUNCTION   MouseKeys: Byte;                 { Nedtryckt mustangent      }
PROCEDURE  GetMouseXY(VAR x,y: INTEGER);       { Avl„s muskoordinater      }
PROCEDURE  PutMouseXY(x,y: Integer);           { Flytta musen till (x,y)   }
PROCEDURE  SetMouseRange(MinX,MinY,MaxX,MaxY: INTEGER);  { Musf”nstret     }
PROCEDURE  WaitMouse;                       { V„nta p† musaktivitet     }
PROCEDURE  SetBlink(On: Boolean);           { S„tt p† blink/16 bakgrf„rg}
PROCEDURE  Border(Col: Byte);               { S„tt ramf„rg              }
PROCEDURE  SetColor(ATT: Byte);             { S„tt text- & bakgrundf„rg }
PROCEDURE  WriteChar(x,y : Byte; CH:Char);  { Skriv tecken vid (x,y)    }
PROCEDURE  WriteLine(x,y,L:Byte; CH:Char);  { Rita linje fr†n (x,y)     }


Implementation

Uses       Dos,Crt;

VAR        Reg: Registers;
           Anfang: Byte ABSOLUTE $0040:$001A;
           Ende  : Byte ABSOLUTE $0040:$001C;

PROCEDURE  ClrKeyBuf;
BEGIN
  Anfang := Ende;
END;

PROCEDURE  GetStatusKeys;
BEGIN
  Reg.AH := $02;
  Intr($16,Reg);
  _Insert     := (Reg.AL AND 128) > 0;
  _Shift      := ((Reg.AL AND 1) > 0) OR
                 ((Reg.AL AND 2) > 0);
  _Ctrl       := (Reg.AL AND 4) > 0;
  _Alt        := (Reg.AL AND 8) > 0;
  _NumLock    := (Reg.AL AND 32) > 0;
  _CapsLock   := (Reg.AL AND 64) > 0;
  _ScrollLock := (Reg.AL AND 16) > 0;
END;

VAR        CursorBeg, CursorEnd: Word;
PROCEDURE  StoreCursor;
BEGIN
  Reg.AH := $0F; Intr($10,Reg);
  Reg.AH := $03; Intr($10,Reg);
  CursorBeg := Reg.CH; CursorEnd := Reg.Cl;
END;

PROCEDURE  HideCursor;
BEGIN
  Reg.AH := $01; Reg.CH := $20;
  Reg.CL := $00; Intr($10,Reg);
END;

PROCEDURE  ShowCursor;
BEGIN
  Reg.AH := $01; Reg.CH := $06;
  Reg.CL := $07; Intr($10,Reg);
END;

PROCEDURE  ResetMouse;
BEGIN
  Reg.AX := $00; Intr($33,Reg);
  Mouse := Reg.AX = $FFFF;
  IF NOT Mouse THEN Exit;
  Reg.AX := $0A; Reg.BX := $00;
  IF Color THEN BEGIN
    Reg.CX := $7FFF; Reg.DX := $7000;
  END ELSE BEGIN
    Reg.CX := $0000; Reg.DX := $0FDB;
  END;
  Intr($33,Reg);
END;

PROCEDURE  ShowMouse;
BEGIN
  IF NOT Mouse THEN Exit;
  Reg.AX := $01; Intr($33,Reg);
END;

PROCEDURE  HideMouse;
BEGIN
  IF NOT Mouse THEN Exit;
  Reg.AX := $02; Intr($33,Reg);
END;

FUNCTION   MouseKeys: Byte;
BEGIN
  IF NOT Mouse THEN BEGIN
    MouseKeys := 0; Exit;
  END;
  Reg.AX := $03; Intr($33,Reg);
  MouseKeys := Reg.BX
END;

PROCEDURE  GetMouseXY(VAR x,y: INTEGER);
BEGIN
  IF NOT Mouse THEN              
  BEGIN
    x := 1; y := 1;
    Exit;
  END;
  Reg.AX := $03; Intr($33,Reg);
  x := (Reg.CX SHR 3) + 1;        { Ger muskoordinaterna omr„knat }
  y := (Reg.DX SHR 3) + 1;         { i bildsk„rmskoordinater      }
END;

PROCEDURE  PutMouseXY(x,y: Integer);
VAR x2,y2: Word;
BEGIN
  IF NOT Mouse THEN Exit;
  x2 := (x-1) SHL 3; y2 := (y-1) SHL 3;
  Reg.AX := $04; Reg.CX := x2;
  Reg.DX := y2;  Intr($33,Reg);
END;

PROCEDURE  SetMouseRange(MinX,MinY,MaxX,MaxY: INTEGER);
BEGIN
  IF NOT Mouse THEN Exit;
  Reg.AX := $07; Reg.CX := (MinX - 1) SHL 3;
  Reg.DX := (MaxX - 1) SHL 3; Intr($33,Reg);
  Reg.AX := $08; Reg.CX := (MinY - 1) SHL 3;
  Reg.DX := (MaxY - 1) SHL 3; Intr($33,Reg);
END;

PROCEDURE  WaitMouse;
VAR Keys: Word;
BEGIN
  IF NOT Mouse THEN Exit;
  REPEAT
    Reg.AX := $03; Intr($33,Reg);
    Keys := Reg.BX;
  UNTIL Keys = 0;
END;

PROCEDURE  GetScreenType;          { Herc-/F„rgmode }
VAR MODE: ^Byte;
BEGIN
  MODE := Ptr($40,$49);
  IF MODE^ = 7
  THEN Screen := Ptr($B000,0000)
  ELSE Screen := Ptr($B800,0000);
  Color := Screen = Ptr($B800,0000);
END;

PROCEDURE  SetBlink(On: Boolean);  { EGA/VGA }
BEGIN
  IF NOT Color THEN Exit;
  Reg.AH := $10; Reg.AL := $03;
  IF On THEN Reg.BL := $01
  ELSE Reg.BL := $00; Intr($10,Reg);
END;

PROCEDURE  Border(Col: Byte);      { Bara EGA/VGA  }
BEGIN
  Col := Col MOD 16; Reg.AH := $0B;
  Reg.BH := $00; Reg.BL := Col; Intr($10,Reg);
END;

PROCEDURE  SetColor(ATT: Byte);
BEGIN                     
  TextAttr := ATT;      { ATT = textf„rg + bakgrundsf„rg * 16 }
END;

PROCEDURE WriteChar(x,y: Byte; CH: Char);
BEGIN
  Screen^[y,x].CH := CH;
  Screen^[y,x].ATT := TextAttr;
END;

PROCEDURE WriteLine(x,y,L: Byte; CH: Char);
BEGIN
  FOR x := x to x + L - 1 DO
  IF x < MaxX THEN WriteChar(x,y,CH);
END;

BEGIN   { ********** Huvudprogram ********** }
  StoreCursor; GetScreenType; ResetMouse;
END.
