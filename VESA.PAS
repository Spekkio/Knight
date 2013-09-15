Unit vesa;              {version 2.2 Alpha by Maxisoft (Daniel Hedeblom)}

Interface
uses dos,crt;
{TEXT}
TYPE  ScreenType = ARRAY[1..25,1..80] of RECORD
                   CH: Char; ATT: Byte;
                   END;
ScreenPtr        = ^ScreenType;
                   BITE = STRING[2];


CONST Screen_ : ScreenPtr = Ptr($B800,0000);
{TEXT}

{VIRTUAL}
Type Virtual = Array [1..64000] of byte; {The size of our Virtual Screen}
     VirtPtr = ^Virtual;                 {Pointer to the virtual screen}

VAR Virscr  : VirtPtr; {Our first Virtual screen}
    VMCGA   : word;    {Segment of our virtual screen}
{VIRTUAL}


{GRAPHIC}
const vseg        = $A000;
      MCGA        = $A000;
      VIDEO       = $10;  { Video interrupt number                    }
      CRTC_ADDR	  = $3d4; { Base port of the CRT Controller (color)   }
      SEQU_ADDR	  = $3c4; { Base port of the Sequencer                }
      vgran       = 64;

type
  ScreenBufferType = ARRAY[0..63999] of BYTE;
  ScreenBufferPtr  = ^ScreenBufferType;
  rgb          = record
                       red,
                       grn,
                       blu : byte
                     end;
  palettetype  = array[0..255] of rgb;
{GRAPHIC}


{VARIABLES}
var Screen : ScreenBufferPtr;
    curbank,pixels:word;
    palette : palettetype;
    reg:registers;
    h,m,s,ms,th,tm,ts,tms,ti : word;
    fp : longint;
    fps : string;

procedure SetPal(nocol   : byte; R,G,B : byte);
PROCEDURE SetPalASM(Farvenr: byte;R,G,B : Byte);
procedure GetPal(ColorNo : byte; var R,G,B : byte);
Procedure ClearColor (Col : Byte;where:word);
procedure InitGraph;
procedure CloseGraph;
procedure CloseGraph_;
{procedure SetPixel(X ,Y : INTEGER; Color : BYTE; where : word);}
procedure SetPixel(X,Y : Word; Color : BYTE; where : word);
procedure VerticalRetrace;
procedure LineTo(fx,fy,tx,ty,c : INTEGER; lines : byte; where : word);
procedure DisplayTime(x,y :integer);
procedure Circle(oX,oY,rad:integer;Col:Byte; where : word);
procedure InitFPS(secs : byte);
procedure FadeToStone(dela,F : byte);
procedure PalFade(times,dela : byte);
procedure UFade;
procedure MFade(Segment : byte; Where : word);
procedure RGBSmooth(del : byte;times : integer);
procedure PalRotate(dela,retrace : integer);
procedure RandomPalette(r,g,b,times : integer);
procedure Screenshot(var yeh : string);
procedure Line(x1,y1,x2,y2 : double; sc,ec : double; Where : word);
procedure Triangle(x1,y1,c1,x2,y2,c2,x3,y3,c3 : DOUBLE;were : word);
procedure shothtml(character:char; x1,x2,y1,y2 : integer; where:word; bgcolor,mega : string);
PROCEDURE WAITRETRACE;
procedure SinusPalette(a,b,c : word);
function RGBColor(red,green,blue : byte):byte;
function GetFPS: Integer;
function getsign(mx,my : integer):integer;
function SearchFile(var t : text; r : char): longint;
function getpixel(x,y : integer; where : word): integer;
FUNCTION COLMIDVALUE(WITCH : BYTE): BYTE;
FUNCTION FADE: BOOLEAN;
FUNCTION SHINE: BOOLEAN;
function hexstr(num : byte):bite;

{VirtualScreen}
Procedure SetUpVirtual;
procedure ClearVirtual(were : word);
Procedure Flip;
PROCEDURE FlipA(source,dest:word);
Procedure ShutDown;
procedure put(x,y : integer; c : byte);
Function get(x,y : integer):byte;

Implementation
(* -------------- Virtual Screens*)
procedure SinusPalette(a,b,c : word);
var i : byte;
begin
  for i := 0 to 255 do SetPal(i,
                                round(32 + 31 * sin((i shl 1)*pi/a)),
                                round(32 + 31 * sin((i shl 1)*pi/b)),
                                round(32 + 31 * sin((i shl 1)*pi/c)));
end;

Procedure SetUpVirtual;
BEGIN
GetMem (VirScr,64000);
VMCGA := seg (virscr^);
END;

function hexstr(num : byte):bite;

var pos  : record
                 a, b : byte;
           end;
const hexa: array[0..15] of char =
      ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

begin
     asm
        xor ax,ax
        mov al,[num]
        rol ax,4
        ror al,4
        mov [pos.a],ah
        mov [pos.b],al
     end;
     hexstr:=concat(hexa[pos.a],hexa[pos.b]);
end;


procedure put(x,y : integer; c : byte); assembler;
{ Written by Matt Sottile }
 asm
  mov ax,y
  mov bx,ax
  shl ax,8
  shl bx,6
  add bx,ax
  add bx,x
 push 0a000h
  pop es
  mov al,c
  mov es:[bx],al
 end;

Function get(x,y : integer):byte;
{ Put Modified by me }
begin
 asm
  mov ax,y
  mov bx,ax
  shl ax,8
  shl bx,6
  add bx,ax
  add bx,x
 push 0a000h
  pop es
  mov al,es:[bx]
  mov @result,al
 end;
end;

procedure ClearVirtual(were : word);ASSEMBLER;
ASM
  push were
  pop es
  mov cx, 32000
  xor di,di
  xor ax,ax
  cld
  rep stosw
end;

(* ------ Flip 64k screens in memory*)

PROCEDURE FlipA(source,dest:word);
ASSEMBLER;
asm
  mov     bx,ds
  mov     ax, dest
  mov     es, ax
  mov     ax, source
  mov     ds, ax
  xor     si, si
  xor     di, di
  mov     cx, 16000
  db      $66
  rep     movsw
  mov     ds,bx
END;

Procedure ClearColor (Col : Byte;where:word);
Assembler;
     asm
        mov     cx, 32000;
        mov     ax,where
        mov     es,ax
        xor     di,di
        mov     al,[col]
        mov     ah,al
        rep     stosw
      END;


Procedure Flip;
BEGIN
Move (Virscr^,mem [MCGA:0],64000);
END;

Procedure ShutDown;
BEGIN
FreeMem (VirScr,64000);
END;


(* -------------- Pop a Screenshot*)
procedure Screenshot(var yeh : string);
var t   : text;
    x,y : integer;

function getpixel(x,y : integer): integer;
begin
getpixel:=mem[$A000:((y shl 8)+(y shl 6))+x];
end;

begin

assign(t,yeh);
rewrite(t);

for x := 0 to 320 do
for y := 0 to 200 do begin
write(t,chr(getpixel(x,y)));
end;

close(t);

end;


(* Pick a color from the screen*)
function getpixel(x,y : integer; where : word): integer;
begin
getpixel:=mem[where:((y shl 8) + (y shl 6))+x];
end;


(* ------------ CAN BE USED IN A LOOP*)
FUNCTION SHINE: BOOLEAN;
VAR R,G,B,I,C : BYTE;

BEGIN
FOR I := 0 TO 255 DO BEGIN
GETPAL(I,R,G,B);
IF R<>255 THEN INC(R);
IF G<>255 THEN INC(G);
IF B<>255 THEN INC(B);
SETPAL(I,R,G,B);
C:=R+B+G;

IF C=762 THEN SHINE:=TRUE ELSE SHINE:=FALSE;

END;
END;

(* ------------ CAN BE USED IN A LOOP*)
FUNCTION FADE: BOOLEAN;
VAR R,G,B : BYTE;
    I     : BYTE;

BEGIN
FOR I := 0 TO 255 DO BEGIN
GETPAL(I,R,G,B);
IF R<>0 THEN DEC(R);
IF G<>0 THEN DEC(G);
IF B<>0 THEN DEC(B);
SETPAL(I,R,G,B);

IF (R+G+B)>3 THEN FADE:=FALSE ELSE FADE:=TRUE;

END;
END;

(* ------------ Returns the value of how many characters of the type r there is ain a file*)
function SearchFile(var t : text; r : char): longint;
var n : integer;
    a : char;
begin
n:=0;
a:=chr(000);
while not Eof(t) do begin
while not Eoln(t) do begin
read(t,a);
if a=r then inc(n);
end;
readln(t);
end;
SearchFile:=n;
end;

(* ------------ Returns the Ordinary value of a character @ x,y*)
function GetSign(mx, my : integer):integer;
begin
getSign:=ord(Screen_^[MY,MX].CH);
end;

(* ------------ Makes a Random Palette*)
procedure RandomPalette(r,g,b,times : integer);
var i : byte;
begin
if r>63 then r:=63;
if g>63 then g:=63;
if b>63 then b:=63;

for i := 0 to 255 do SetPal(i,random(r),random(g),random(b));
if times <>0 then for i := 1 to times do RGBSmooth(0,30) else RGBSmooth(0,30);
end;

(* ------------ Palette Smoother*)
procedure RGBSmooth(del : byte;times : integer);
var i                : byte;
    r,g,b,ar,ag,ab : array[0..255] of byte;
    a{,ar,ag,ab  }   : integer;
begin

for a := 0 to times do begin
for i := 0 to 255 do begin
GetPal(i  ,r[i]  ,g[i]  ,b[i]  );
GetPal(i+1,r[i+1],g[i+1],b[i+1]);
GetPal(i-1,r[i-1],g[i-1],b[i-1]);

ar[i]:= (r[i-1]+r[i]+r[i+1]) DIV 3;
ag[i]:= (g[i-1]+g[i]+g[i+1]) DIV 3;
ab[i]:= (b[i-1]+b[i]+b[i+1]) DIV 3;
SetPal(i,ar[i],ag[i],ab[i]);
end;
delay(del);
end;
end;

(* ------------ Rotates the Pal if in a Loop*)
procedure PalRotate(dela,retrace : integer);
var r,g,b,sr,sg,sb : array[0..256] of byte;
    i,p            : integer;
begin

for i := 0 to 256 do begin
GetPal(i,r[i],b[i],g[i]);
end;

for i := 0 to 256 do begin
p:=i;
GetPal(i,r[p],g[p],b[p]);
if p=0 then p:=256;
sr[i]:=r[p-1];
sg[i]:=g[p-1];
sb[i]:=b[p-1];
end;
if retrace<>0 then VerticalRetrace;
for i := 0 to 255 do SetPal(i,sr[i],sg[i],sb[i]);
delay(dela);

end;

procedure shothtml(character:char; x1,x2,y1,y2 : integer; where:word; bgcolor,mega : string);
var sx,sy,rr : integer;
    pal      : array[0..255] of record r, g, b : byte; end;
    shot     : text;

begin
 assign(shot,'shot.htm');
 rewrite(shot);
 write(shot,'<HTML><TITLE> Knight HTML Shooter </TITLE><BODY BGCOLOR="',bgcolor,'"><SMALL><B>');
  for rr := 0 to 255 do GetPal(rr,pal[rr].r,pal[rr].g,pal[rr].b);
  for sy := y1 to y2 do begin
   for sx := x1 to x2 do begin
    write(shot,'<FONT ',mega,'COLOR="#',
     hexstr(pal[MEM[where:((SY shl 8)+(SY shl 6))+SX]].r*255 DIV 63),
     hexstr(pal[MEM[where:((SY shl 8)+(SY shl 6))+SX]].g*255 DIV 63),
     hexstr(pal[MEM[where:((SY shl 8)+(sy shl 6))+SX]].b*255 DIV 63),'">',character,'</FONT>');
    end;
    write(shot,'<BR>');
   end;
  write(shot,'</BODY></HTML></SMALL></B>');
  close(shot);
end;

(* ------------ Init VESA *)
   procedure InitGraph;
   begin
   ASM
    mov AX, 0013h
    int 10h
    push 0A000h
    pop es
   END;
   Screen := PTR($A000, 0);
   END;

   procedure InitGraph_640x480;
   begin
   asm
    mov ax, $4F02
    mov bx, $101
    int VIDEO
   end;
   end;


(* ------------ Close VESA*)
   procedure CloseGraph; ASSEMBLER;
   ASM
    mov AX, 0003h
    int 10h
   END;

(* ------------ Close VESA*)
   procedure CloseGraph_;
   begin
   ASM
    mov AX, 0003h
    int 10h
   END;
Writeln('лллллллллллллллллллллллллллллллллллллллллллллллллл');
writeln;
Writeln('Written by Maxisoft (aka SpeedFreak or DragonMaxi)');
Writeln;
Writeln('  Mail me @: Crayola@swipnet.se');
Writeln('  http://speedfreak.sleepwalkers.org');
writeln;
Writeln('лллллллллллллллллллллллллллллллллллллллллллллллллл');
   end;


(* ------------ Set A Pixel On The Screen*)
   procedure SetPixel(X,Y : Word; Color : BYTE; where : word);
{   ASSEMBLER;
   ASM
      MOV DI,Y
      MOV AX,0140h
      MUL DI
      ADD DI,X
      MOV AX,Where
      MOV ES,AX
      MOV AL,Color
      STOSW}
   Begin
    MEM[where:((y shl 8)+(y shl 6))+x]:=Color;
   END;


procedure VerticalRetrace; ASSEMBLER;{Code from Dalnet's #ASM}
ASM
                 PUSHA
                 MOV     DX, 3DAh
 @@la:           IN      AL, DX
                 AND     AL, 8h
                 JZ      @@la
 @@lb:           IN      AL,  DX
                 AND     AL,  8h
                 JZ      @@lb
                 POPA
                 RET
end;

PROCEDURE WAITRETRACE;
BEGIN
Repeat Until Port[$03DA] And $08 = $08;
END;


(* ------------- Draw A Nice Line BAD!*)
   procedure LineTo(fx,fy,tx,ty,c : INTEGER; lines : byte; where : word);
   var t : integer;
   begin
    for t:=1 to lines do
    SetPixel(tx+(fx-tx)*t DIV lines,ty+(fy-ty)*t DIV lines,c,where);
   end;

(* ------------- Line, new*)
Procedure Line(x1,y1,x2,y2 : double; sc,ec : double; Where : word);
var a1,b1,c1,a2,b2,c2         : double;
    LenghtX,LenghtY,LenghtC    : double;
    HYPOTEN                   : double;
    I                         : INTEGER;

function specSQR(x,y : double):double;
assembler;
var bak:double;
asm
   finit
   fld x
   fmul st,st
   fld y
   fmul st,st
   fadd
   fsqrt
   fst bak
   fwait
end;

Function Invert(a : double): double;
begin
Invert:=a*(-1);
end;

function ZeroOne(a : double):double;
begin
if a=0 then ZeroOne:=1 else ZeroOne:=a;
end;

Begin
 LENGHTX:=ABS(X1-X2);
 LENGHTY:=ABS(Y1-Y2);
 HYPOTEN:=specSQR(LENGHTX,LENGHTY);
          {SQRT(SQR(LENGHTX)+SQR(LENGHTY));}
 C1     :=ABS(SC-EC)/ZeroOne(HYPOTEN);
 IF X1<>X2 THEN A1:=LENGHTX/HYPOTEN ELSE A1:=0;
 IF Y1<>Y2 THEN B1:=LENGHTY/HYPOTEN ELSE B2:=0;
 IF X1>X2 THEN A1:=INVERT(A1);
 IF Y1>Y2 THEN B1:=INVERT(B1);
 FOR I := 0 TO ROUND(HYPOTEN) DO BEGIN
  SETPIXEL(ROUND(X1),ROUND(Y1),ROUND(SC),where);
  X1:=X1+A1;
  Y1:=Y1+B1;
  SC:=SC+C1;
 END;
END;


(* ------------- Display time*)
   procedure DisplayTime(x,y : integer);

   begin
   GetTime(h,m,s,ms);
   gotoxy(x,y);write(h,':',m,':',s,':',ms);
   end;



(* ----------- Change Palette*)
procedure SetPal(nocol : byte; R,G,B : byte);
begin
 PORT[$3c8] := Nocol;
 PORT[$3c9] := R;
 PORT[$3c9] := G;
 PORT[$3c9] := B;
end;


(* ----------- Change The Palette*)
PROCEDURE SetPalASM(Farvenr: byte;R,G,B : Byte);
Assembler;
   asm
      mov    dx,3c8h
      mov    al,[farvenr]
      out    dx,al
      inc    dx
      mov    al,[r]
      out    dx,al
      mov    al,[g]
      out    dx,al
      mov    al,[b]
      out    dx,al
End;

(* ----------- Get Palette*)
Procedure GetPal(ColorNo : Byte; Var R,G,B : Byte);
 Begin
 Port[$3c7] := ColorNo;
  R := Port[$3c9];
  G := Port[$3c9];
  B := Port[$3c9];
 End;

(* ----------- RETURNS MID VALUE OF 1=RED, 2=GREEN, 3=BLUE*)

FUNCTION COLMIDVALUE(WITCH : BYTE): BYTE;
VAR GET : ARRAY[0..256] OF BYTE;
    Q   : REAL;
    I   : INTEGER;
    X,Y : BYTE;
BEGIN
FOR I := 0 TO 256 DO BEGIN
CASE WITCH OF
1: GETPAL(I,GET[I],X,Y);
2: GETPAL(I,X,GET[I],Y);
3: GETPAL(I,X,Y,GET[I]);
END;
Q:=Q+GET[I];
END;
Q:=Q/256;
COLMIDVALUE:=ROUND(Q);
END;


(* -------------------- A Circle*)
     Procedure Circle(oX,oY,rad:integer;Col:Byte; where : word);
     VAR deg:real;
     X,Y:integer;
     BEGIN
     deg:=0;
     repeat
     X:=round(rad*COS (deg));
     Y:=round(rad*sin (deg));
     setpixel (x+ox,y+oy,Col,where);
     deg:=deg+0.005;
     until (deg>6.4);
     END;


procedure UFade; ASSEMBLER;
asm
       pusha
       xor di,di
       mov bx,0FA00h
@start:
       inc di
       cmp di,bx
       jz @end
       mov ax,[ES:DI]
       cmp al,1b
       jb @start
@point:
       dec al
       mov [ES:DI],al
       jmp @start
@end:
       popa
end;


(* ------------------- Same as above*)
procedure MFade(Segment : byte; where : word);
var x,y   : integer;
    xa    : longint;
    a     : byte;
begin

for x:=0 to 320 do for y:=0 to 200 do begin
      a:=MEM[where:((y shl 8)+(y shl 6))+x];
      if a<Segment then a:=(Segment+1);
      dec(a,Segment);
      MEM[where:((y shl 8)+(y shl 6))+x]:=a;
     end;
end;

(* ------------------- Fades out the Palette complt..*)
procedure PalFade(times,dela : byte);
var r,g,b,i,a : byte;
begin

for a := 0 to times do begin
for i := 0 to 255 do begin
GetPal(i,r,g,b);
if r<>0 then dec(r);
if g<>0 then dec(g);
if b<>0 then dec(b);
SetPal(i,r,g,b);
end;

delay(dela);
end;
end;

(* ------------------- Fades The Palette to Grey*)
procedure FadeToStone(dela,F : byte);
var r,g,b,a: array[0..255]of byte;
    i,p,y  : byte;
begin

for i := 0 to 255 do begin
GetPal(i,r[i],g[i],b[i]);
a[i]:=(r[i]+g[i]+b[i]) DIV 3;
end;

for p := 0 to 63 do begin
for i := 0 to 255 do begin
if r[i]>a[i] then dec(r[i]) else inc(r[i]);
if r[i]>63 then r[i]:=63;
if r[i]<1  then r[i]:=0;

if g[i]>a[i] then dec(g[i]) else inc(g[i]);
if g[i]>63 then g[i]:=63;
if g[i]<1  then g[i]:=0;

if b[i]>a[i] then dec(b[i]) else inc(b[i]);
if b[i]>63 then b[i]:=63;
if b[i]<1  then b[i]:=0;
end;
if F=0 then VerticalRetrace;
for y := 0 to 255 do SetPal(y,r[y],g[y],b[y]);
delay(dela);
end;
end;


(* SDFSDFSDFSDFSDFSDF *)
procedure InitFPS(secs : byte);

begin
 GetTime(th,tm,ts,tms);
 if secs>60 then secs:=60;
 ti:=ts+secs;
 fp:=0;
end;

Function GetFPS : Integer;

begin

 GetTime(th,tm,ts,tms);
if ti<>ts then inc(fp);
if ti=ts then begin
   {font(concat(fps,' fps'),x,y,1);}
   GetFPS:=fp;
   str(fp,fps);
   {font(concat(fps,' fps'),x,y,c);}
   fp:=0;
   GetTime(th,tm,ts,tms);
   ti:=ts+1;
   if ti=60 then ti:=1;
end;
end;

function RGBColor(red,green,blue : byte):byte;
  var  i,min                 : integer;
       ReCol,GrCol,BlCol     : byte;
       R,G,B,rmin,gmin,bmin  : byte;
       BWColor               : BOOLEAN;
begin
  rMin:=63;
  gMin:=63;
  bMin:=63;
  Min:=63;
  ReCol:=63;
  GrCol:=63;
  BlCol:=63;
  BWColor:=FALSE;
  IF RED=GREEN then IF GREEN=BLUE THEN BWColor:=TRUE;
  IF NOT BWCOLOR THEN
  for I := 0 to 255 do begin
    GetPal(I,R,G,B);
    IF ABS(R-RED)<ReCol then ReCol:=ABS(R-RED);
    IF ABS(G-GREEN)<GrCol then GrCol:=ABS(G-GREEN);
    IF ABS(B-BLUE)<BlCol then BlCol:=ABS(B-BLUE);
    IF (ReCol<rMin) or
       (GrCol<gMin) or
       (BlCol<bMin) then begin
       rMin:=ReCol;
       gMin:=GrCol;
       bMin:=BlCol;
       RGBColor:=I;
    end;
  end ELSE begin
  for i := 0 to 255 do begin
    GETPAL(I,R,G,B);
    IF R=B then if B=G then begin
      ReCol:=ABS(R-RED);
      IF ReCol<MIN then begin
        min:=ReCol;
        RGBColor:=I;
      end;
    end;
  end;
  end;
end;
(* -- DRAW UGLY TRIANGLE, LOOKS NICE IF USING ONLY 1 COLOR *)
procedure Triangle(x1,y1,c1,
                   x2,y2,c2,
                   x3,y3,c3 : DOUBLE;
                   were     : word);
var a1,b1,cl1,a2,b2,cl2       : double;
    LenghtX,LenghtY,LenghtC   : double;
    HYPOTEN                   : double;
    I                         : INTEGER;

function specSQR(x,y : double):double;
assembler;
var bak:double;
asm
   finit
   fld x
   fmul st,st
   fld y
   fmul st,st
   fadd
   fsqrt
   fst bak
   fwait
end;


function Invert(a : double): double;
begin
Invert:=a*(-1);
end;

function ZeroOne(a : double):double;
begin
if a=0 then ZeroOne:=1 else ZeroOne:=a;
end;

Procedure Line(x1,y1,x2,y2 : double; sc,ec : double; Where : word);
var a1,b1,c1,a2,b2,c2         : double;
    LenghtX,LenghtY,LenghtC   : double;
    HYPOTEN                   : double;
    I                         : INTEGER;

Begin
 LENGHTX:=ABS(X1-X2);
 LENGHTY:=ABS(Y1-Y2);
 HYPOTEN:=specSQR(LENGHTX,LENGHTY);{SQRT(SQR(LENGHTX)+SQR(LENGHTY));}
 C1     :=ABS(SC-EC)/ZeroOne(HYPOTEN);
 IF X1<>X2 THEN A1:=LENGHTX/HYPOTEN ELSE A1:=0;
 IF Y1<>Y2 THEN B1:=LENGHTY/HYPOTEN ELSE B1:=0;
 IF X1>X2 THEN A1:=INVERT(A1);
 IF Y1>Y2 THEN B1:=INVERT(B1);
 FOR I := 0 TO ROUND(HYPOTEN) DO BEGIN
  SETPIXEL(ROUND(X1),ROUND(Y1),ROUND(SC),where);
  X1:=X1+A1;
  Y1:=Y1+B1;
  SC:=SC+C1;
 END;
END;

begin
 LENGHTX:=ABS(X2-X3);
 LENGHTY:=ABS(Y2-Y3);
 HYPOTEN:=specSQR(LENGHTX,LENGHTY);{SQRT(SQR(LENGHTX)+SQR(LENGHTY));}
 CL1    :=ABS(C2-C3)/ZeroOne(HYPOTEN);
 IF X2<>X3 THEN A1:=LENGHTX/HYPOTEN ELSE A1:=0;
 IF Y2<>Y3 THEN B1:=LENGHTY/HYPOTEN ELSE B1:=0;
 IF X2>X3 THEN A1:=INVERT(A1);
 IF Y2>Y3 THEN B1:=INVERT(B1);
 FOR I := 0 TO ROUND(HYPOTEN) DO BEGIN
  LINE(X1,Y1,
       X2,Y2,C1,C2, were);
  X2:=X2+A1;
  Y2:=Y2+B1;
  C2:=C2+CL1;
 END;
end;


end.



