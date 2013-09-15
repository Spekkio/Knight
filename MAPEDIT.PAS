{Map editor by Daniel Hedeblom}
Program MapEdit;
uses crt,vesa,utility,TheFont;

Type Virtual  = Array [1..64000] of byte; {The size of our Virtual Screen}
     Virtual1 = Array [1..64000] of byte; {The size of Sprite Table}
     Virtual2 = Array [1..64000] of byte; {The size of Ground}

     VirtPtr  = ^Virtual;                 {Pointer to the virtual screen}
     SpritePtr= ^Virtual1;                {Pointer to the sprite table}
     GroundPtr= ^Virtual2;                {Pointer to the ground}

VAR Virscr      : VirtPtr;   {Virtual screen}
    SpriteScr   : SpritePtr; {SpriteTable}
    GroundScr   : GroundPtr; {Ground}
    VMCGA       : word;      {Segment of our virtual screen}
    VSPR        : word;      {Segment of our SpriteTable}
    GRND        : Word;      {Segment of our Ground}
    i,x,y   : longint;
    mx,my   : integer;
    f       : text;
    Mapl    : array[1..60000] of byte;
    WereMap : integer;
    WhatSpot: byte;
    k       : char;
    WereX,WereY,Monster : longint;
    test,test1    : string;

procedure Spot(mapx,mapy,i : integer);
var x,y : integer;
begin
case i of

   {GRASS}
1: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+109)*320+(X+96)];

   {LEFT WALL}
2: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+109)*320+(X+64)];

   {LEFT BOT CORNER WALL}
3: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+64)];

   {LEFT TOP CORNER WALL}
4: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+64)];

   {TOP WALL}
5: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+97)];

   {RIGHT TOP CORNER WALL}
6: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+128)];

   {RIGHT WALL}
7: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+109)*320+(X+128)];

   {RIGHT BOT WALL}
8: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+128)];

   {BOT WALL}
9: for x := 1 to 32 do
   for y := 1 to 20 do
   MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+96)];

    {LEFT TOP CORNER LAKE}
10: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+64)];

    {LEFT LAKE}
11: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+49)*320+(X+64)];

    {LEFT BOT CORNER LAKE}
12: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+64)];

    {BOTTOM LAKE}
13: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+96)];

    {RIGHT BOT CORNER LAKE}
14: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+128)];

    {RIGHT LAKE}
15: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+50)*320+(X+128)];

    {RIGHT TOP CORNER LAKE}
16: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+128)];

    {TOP LAKE}
17: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+96)];

    {LAKE}
18: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+49)*320+(X+96)];

    {ROCK}
19: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+32)];

    {Left Top Corner Lake Invert}
20: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+160)];

    {Top lake invert}
21: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+191)];

    {Right Top Corner Lake Invert}
22: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+29)*320+(X+224)];

    {Left Lake Invert}
23: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+49)*320+(X+160)];

    {Right Lake Invert}
24: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+49)*320+(X+224)];

    {Left Bot Corner Lake Invert}
25: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+160)];

    {Bot Lake Invert}
26: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+192)];

    {Right Bot Corner Lake Invert}
27: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+69)*320+(X+224)];

28: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+160)];

29: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+192)];

30: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+89)*320+(X+224)];

31: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+109)*320+(X+160)];

32: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+160)];

33: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+192)];

34: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+224)];

35: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+129)*320+(X+224)];

36: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+109)*320+(X+224)];

37: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+149)*320+(X+64)];

38: for x := 1 to 32 do
    for y := 1 to 20 do
    MEM[GRND:(MapY+Y)*320+(MapX+X)]:=MEM[VSPR:(Y+149)*320+(X+96)];


end;
end;

Procedure SetUpVirtual;
BEGIN
GetMem (VirScr,64000);
VMCGA := seg (virscr^);
GetMem (SpriteScr,64000);
VSPR  := seg (SpriteScr^);
GetMem (GroundScr,64000);
GRND  := seg (GroundScr^);
END;

procedure ClearVirtual(where : word); ASSEMBLER;      {CLEARVIRTUAL PROCEDURE}

ASM
  push where
  pop es
  mov cx, 32000
  xor di,di
  xor ax,ax
  cld
  rep stosw
end;

procedure ClearAll;                                       {CLEARALL PROCEDURE}
begin
ClearVirtual(MCGA);
ClearVirtual(VMCGA);
ClearVirtual(GRND);
ClearVirtual(VSPR);
end;

Procedure Flip(W1 : byte; W2 : word);                         {FLIP PROCEDURE}
BEGIN

case W1 of
1: Move (VirScr^   ,mem [W2:0],64000);
2: Move (SpriteScr^,mem [W2:0],64000);
3: Move (GroundScr^,mem [W2:0],64000);
end;

END;

Procedure ShutDown;                                       {SHUTDOWN PROCEDURE}
BEGIN
FreeMem (VirScr,64000);
FreeMem (SpriteScr,64000);
FreeMem (GroundScr,64000);
END;

procedure DelFile(w : string);
var p : text;
begin
  assign(p,w);
  reset(p);
  close(p);
  erase(p);
end;

Procedure LoadSprites;
var f : text;
    r,g,b,c : char;
begin
assign(f,'table.dat');
reset(f);
  for i := 0 to 255 do begin
    read(f,r);
    read(f,g);
    read(f,b);
    SetPal(i,ord(r),ord(g),ord(b));
  end;

  for x := 0 to 320 do
  for y := 0 to 200 do begin
    Read(f,c);
    SetPixel(x,y,ord(c),VSPR);
  end;
close(f);
end;

procedure displaybox(x,y : integer);
var x1 : integer;
begin
for x1 := x to x+32 do SetPixel(x1,y,40,vMCGA);
for x1 := y to y+20 do SetPixel(x+32,x1,40,vMCGA);
for x1 := x to x+32 do SetPixel(x1,y+20,40,vMCGA);
for x1 := y to y+20 do SetPixel(x,x1,40,vMCGA);
end;

Function WSpot(x,y : integer):byte;
var a,b : integer;
begin
if x=32  then b:=1;
if x=64  then b:=2;
if x=96  then b:=3;
if x=128 then b:=4;
if x=160 then b:=5;
if x=192 then b:=6;
if x=224 then b:=7;
if x=256 then b:=8;
if x=288 then b:=9;
if x=320 then b:=10;
if y=20  then a:=0;
if y=40  then a:=10;
if y=60  then a:=20;
if y=80  then a:=30;
if y=100 then a:=40;
if y=120 then a:=50;
if y=140 then a:=60;
if y=160 then a:=70;
if y=180 then a:=80;
if y=200 then a:=90;
WSpot:=a+b;
end;

Procedure LoadExistingMap;
var x,y : integer;
    i     : longint;
    c     : char;
begin
for i := 1 to 60000 do begin
read(f,c);
Mapl[i]:=ord(c);
end;
end;

procedure GetMap(w : longint);
var i   : longint;
    x,y : integer;
begin
x:=0;y:=0;
for i := 1 to 100 do begin
Spot(x,y,Mapl[i+w]);

inc(x,32);
if x>319 then begin inc(y,20); x:=0; end;
end;


end;


begin
Randomize;
assign(f,'mdat.dat');
reset(f);
{for i := 1 to 60000 do write(f,chr(random(27)+1));}
InitGraph;

SetupVirtual;
ClearAll;


LoadSprites;
i:=100;
PutMouseXY(0,0);
LoadExistingMap;
GetMap(0);

rewrite(f);

repeat
{ClearVirtual(VMCGA);}

k:=chr(0);
GetMouseXY(mx,my);
mx:=mx*32;
my:=my*20;
if mx>320 then mx:=320;
if my>200 then my:=200;

str(WereMap,test1);
str(Wspot(mx,my),test);
Flip(3,VMCGA);
writeg(concat(test,':',test1),10,10,40,VMCGA);
DisplayBox(mx-32,my-20);

if mousekeys=1 then begin
   Spot(mx-32,my-20,WhatSpot);
   Mapl[Wspot(mx,my)+WereMap]:=WhatSpot;
end;

Flip(1,MCGA);
if keypressed then k:=readkey;
if k='e' then inc(WhatSpot);
if k='q' then dec(WhatSpot);
if k='d' then begin inc(weremap,100);  ClearVirtual(GRND); GetMap(WereMap); end;
if k='a' then begin dec(weremap,100);  if weremap<1 then weremap:=0;ClearVirtual(GRND); GetMap(WereMap); end;
if k='s' then begin inc(weremap,3000); ClearVirtual(GRND); GetMap(WereMap); end;
if k='w' then begin dec(weremap,3000); if weremap<1 then weremap:=0; ClearVirtual(GRND); GetMap(WereMap); end;


until k=chr(027);
for i := 1 to 60000 do Write(f,chr(mapl[i]));




ShutDown;
CloseGraph;
close(f);
end.