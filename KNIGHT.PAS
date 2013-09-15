{Cecil Game 1.0 Coding By Daniel Hedeblom}
{File Encryption by Sean Lynch - TPU conversion by Daniel Hedeblom}
{Games.TPU keyboard library by Lou DuChez}
{Character Sprites from www.rpgsprites.com}

{Benchmark Stats:

 PIII @ 800Mhz: 560fps
 P    @ 200Mhz: 230fps


}

program Knight;
uses Vesa,CRT,dos,Games,TheFont,Utility;

CONST NULL        = 0;     {Zero}
      Transparent = 57;    {Transparent Area, Find With DEBUG Procedure}
      WalkSpeed   = 0.200; {Walk Speed}
      AnimationSp = 0.025; {Animation Speed}
      MapSize     = 60000; {600 screens}


Type Virtual  = Array [1..64000] of byte; {The size of our Virtual Screen}
     Virtual1 = Array [1..64000] of byte; {The size of Sprite Table}
     Virtual2 = Array [1..64000] of byte; {The size of Ground}
     Virtual3 = Array [1..MapSize] of byte; {The MAP Mem} {256Kb Of MEM}

     VirtPtr  = ^Virtual;                 {Pointer to the virtual screen}
     SpritePtr= ^Virtual1;                {Pointer to the sprite table}
     GroundPtr= ^Virtual2;                {Pointer to the ground}
     MapPtr   = ^Virtual3;


VAR Virscr      : VirtPtr;   {Virtual screen}
    SpriteScr   : SpritePtr; {SpriteTable}
    GroundScr   : GroundPtr; {Ground}
    MapScr      : MapPtr;
    VMCGA       : word;      {Segment of our virtual screen}
    VSPR        : word;      {Segment of our SpriteTable}
    GRND        : Word;      {Segment of our Ground}
    MAP         : word;      {Segment of our map}
    KEY         : char;
    WereX,WereY,
    WereMap     : LongInt;
    WeX,WeY     : Real;
    Up1,Up2,
    Do1,Do2     : array[1..16,1..16] of byte;
    Le1,Le2,
    Ri1,Ri2     : array[1..13,1..16] of byte;
    WalkC       : longint;
    WalkR       : real;
    up,left,
    right,
    down,walk,
    moved,
    ExitLeft,
    ExitRight,
    ExitUp,
    ExitDown,Water,
    Day,Night_  : boolean;
    WereS       : integer;
    WichShit    : byte;
    BoxX,BoxY,
    FootX,FootY : integer;
    Colide      : array[1..100] of boolean;
    TypeOf      : array[1..100] of byte;
    Night,Dr,Dg,
    Db          : array[0..255] of byte;
    WereLoop    : integer;
    h,m,s,ms    : word;
    DoFadeN,EndIsSet : boolean;

procedure ResetPositionData;
begin
  WereMap:=0;
  ExitLeft:=FALSE;
  ExitRight:=FALSE;
  ExitUp:=FALSE;
  ExitDown:=FALSE;
  WereX:=320 DIV 2;
  WereY:=200 DIV 2;
  WeX:=WereX;
  WeY:=WereY;
  WalkR:=0;
  WalkC:=0;
end;

procedure StartRPGEngine;

Function BoxCodes(x,y : byte):byte;
var a,b : integer;
begin
a:=x+1;
if y<1 then b:=0 else b:=y*10;
BoxCodes:=a+b;
end;

function icke(a : boolean):boolean;                            {ICKE FUNCTION}
begin
if a then icke:=FALSE else icke:=true;
end;


Procedure WaitHere;                                       {WAITHERE PROCEDURE}
begin
  repeat
  until KEYDOWN[escscan];
end;


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
ClearVirtual(MAP);
end;



Procedure Flip(W1 : Word; W2 : word);                         {FLIP PROCEDURE}
BEGIN

case W1 of
1: Move (VirScr^   ,mem [W2:0],64000);
2: Move (SpriteScr^,mem [W2:0],64000);
3: Move (GroundScr^,mem [W2:0],64000);
4: Move (MapScr^   ,mem [W2:0],MapSize);
end;

END;


Procedure LoadSpriteTable;                         {LOADSPRITETABLE PROCEDURE}

var f       : text;
    pswd    : string;
    i,x,y   : integer;
    r,g,b,c : char;

procedure DelFile(w : string);
var p : text;
begin
  assign(p,w);
  reset(p);
  close(p);
  erase(p);
end;


procedure LoadMapFile;
var mapf : text;
    t    : longint;
    spot : char;

begin
  assign(mapf,'mdat.dat');
  reset(mapf);
  ClearVirtual(map);
  for t := 1 to 60000 do begin
   read(mapf,spot);
   MEM[MAP:T]:=ord(SPOT);
  end;
  close(mapf);
end;

begin
  InitGraph;
  WriteG('loading maps',10,10,15,MCGA);
  LoadMapFile;
  assign(f,'sprites.dat');
  reset(f);
  InitGraph;
  WriteG('loading graphics',10,10,15,MCGA);

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


Procedure DisplayStillCharacter(were : word);       {ERROR}
var x,y : integer;
begin
if not Walk then begin
 if up then for x:= 1 to 16 do
 for y := 1 to 16 do if Up2[x,y]<>Transparent then
 SetPixel(WereX+x,WereY+y,Up2[x,y],were);

 if down then for x:= 1 to 16 do
 for y := 1 to 16 do if Do2[x,y]<>Transparent then
 SetPixel(WereX+x,WereY+y,Do2[x,y],were);

 if Left then for x:= 1 to 13 do
 for y := 1 to 16 do if Le2[x,y]<>Transparent then
 SetPixel(WereX+x,WereY+y,Le2[x,y],were);

 if right then for x:= 1 to 13 do
 for y := 1 to 16 do if Ri2[x,y]<>Transparent then
 SetPixel(WereX+x,WereY+y,Ri2[x,y],were);
end;

end;


procedure SearchForKeyPress;                     {SEARCHFORKEYPRESS PROCEDURE}

procedure WriteRi1(were : word);
  var x,y : integer;

begin
 RIGHT:=TRUE;

{WALK RIGHT 1}
if not up or
   not down then begin

for x := 1 to 13 do
for y := 1 to 16 do
  if Ri1[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Ri1[x,y],were);
end;
 UP:=FALSE;
 DOWN:=FALSE;
 LEFT:=FALSE;
 Wex:=WeX+WalkSpeed;
 WereX:=Round(WeX);
 Walk:=TRUE;

 FootX:=WereX+7;
 FootY:=WereY+16;
end;

procedure WriteRi2(were : word);
  var x,y : integer;

begin
 RIGHT:=TRUE;

{WALK RIGHT 2}
if not up or
   not down then begin

for x := 1 to 13 do
for y := 1 to 16 do
  if Ri2[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Ri2[x,y],were);
end;

 UP:=FALSE;
 DOWN:=FALSE;
 LEFT:=FALSE;
 Wex:=WeX+WalkSpeed;
 WereX:=Round(WeX);
 Walk:=TRUE;

 FootX:=WereX+7;
 FootY:=WereY+16;
end;




procedure WriteLe1(were : word);
  var x,y : integer;

begin

{WALK LEFT 1}
 LEFT:=TRUE;

if not up or
   not down then begin

for x := 1 to 13 do
for y := 1 to 16 do
  if Le1[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Le1[x,y],were);

end;

 UP:=FALSE;
 DOWN:=FALSE;
 RIGHT:=FALSE;
 WeX:=WeX-WalkSpeed;
 WereX:=Round(WeX);
 Walk:=TRUE;

 FootX:=WereX+7;
 FootY:=WereY+16;
end;

procedure WriteLe2(were : word);
  var x,y : integer;

begin

 LEFT:=TRUE;

if not up or
   not down then begin
{WALK LEFT 2}
for x := 1 to 13 do
for y := 1 to 16 do
  if Le2[x,y]<>Transparent then SetPixel(WereX+x,WereY+y,Le2[x,y],were);

end;

 UP:=FALSE;
 DOWN:=FALSE;
 RIGHT:=FALSE;
 WeX:=WeX-WalkSpeed;
 WereX:=Round(WeX);
 Walk:=TRUE;

 FootX:=WereX+7;
 FootY:=WereY+16;
end;


procedure WriteDo1(were : word);
  var x,y : integer;

begin

 DOWN:=TRUE;

if not left and
   not right then begin

{WALK DOWN 1}
for x := 1 to 16 do
for y := 1 to 16 do
  if Do1[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Do1[x,y],were);

end;

 UP:=FALSE;
 LEFT:=FALSE;
 RIGHT:=FALSE;
 WeY:=WeY+WalkSpeed;
 WereY:=Round(WeY);
 Walk:=TRUE;

 FootX:=WereX+8;
 FootY:=WereY+16;
end;

procedure WriteDo2(were : word);
  var x,y : integer;

begin

 DOWN:=TRUE;

if not left and
   not right then begin

{WALK DOWN 2}
for x := 1 to 16 do
for y := 1 to 16 do
  if Do2[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Do2[x,y],were);

end;

 UP:=FALSE;
 LEFT:=FALSE;
 RIGHT:=FALSE;
 WeY:=WeY+WalkSpeed;
 WereY:=Round(WeY);
 Walk:=TRUE;

 FootX:=WereX+8;
 FootY:=WereY+16;
end;



procedure WriteUp1(were : word);
  var x,y : integer;

begin
 UP:=TRUE;


{WALK UP 1}
if not left and
   not right then begin

for x := 1 to 16 do
for y := 1 to 16 do
  if Up1[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Up1[x,y],were);

end;

 DOWN:=FALSE;
 LEFT:=FALSE;
 RIGHT:=FALSE;
 WeY:=WeY-WalkSpeed;
 WereY:=Round(WeY);
 Walk:=TRUE;
 FootX:=WereX+8;
 FootY:=WereY+16;
end;

procedure WriteUp2(were : word);
  var x,y : integer;

begin
 UP:=TRUE;

{WALK UP 2}
if not left and
   not right then begin

for x := 1 to 16 do
for y := 1 to 16 do
  if Up2[x,y]<>Transparent then
  SetPixel(WereX+x,WereY+y,Up2[x,y],were);
 end;

 DOWN:=FALSE;
 LEFT:=FALSE;
 RIGHT:=FALSE;
 WeY:=WeY-WalkSpeed;
 WereY:=Round(WeY);
 Walk:=TRUE;
 FootX:=WereX+8;
 FootY:=WereY+16;
end;

var sx,sy,rr : integer;
    pal      : array[0..255] of record r, g, b : byte; end;
    shot     : text;

begin
{********* Which Key Was Pressed?}
Walk:=FALSE;
IF KEYDOWN[Upscan] then if
   Odd(WalkC) then WriteUp1(VMCGA) else WriteUp2(VMCGA);

IF KEYDOWN[Downscan] then if
   Odd(WalkC) then WriteDo1(VMCGA) else WriteDo2(VMCGA);

IF KEYDOWN[leftscan] then if
   Odd(WalkC) then WriteLe1(VMCGA) else WriteLe2(VMCGA);

IF KEYDOWN[Rightscan] then if
   Odd(WalkC) then WriteRi1(VMCGA) else WriteRi2(VMCGA);

IF KEYDOWN[f1scan] then begin
                        assign(shot,'shot.htm');
                        rewrite(shot);
                        write(shot,'<HTML><TITLE> Knight HTML Shooter </TITLE><BODY BGCOLOR="#000000"><SMALL><B>');
                        for rr := 0 to 255 do GetPal(rr,pal[rr].r,pal[rr].g,pal[rr].b);
                        for sy := 1 to 200 do begin
                         for sx := 1 to 320 do begin
                          write(shot,'<FONT FACE="verdana" SIZE=-2 COLOR="#',
                           hexstr(pal[MEM[$A000:SY*320+SX]].r*255 DIV 63),
                           hexstr(pal[MEM[$A000:SY*320+SX]].g*255 DIV 63),
                           hexstr(pal[MEM[$A000:SY*320+SX]].b*255 DIV 63),'">$</FONT>');
                         end;
                         write(shot,'<BR>');
                        end;

                        write(shot,'</BODY></HTML></SMALL></B>');
                        close(shot);
                        end;
end;

Procedure WalkChanger;                                 {WALKCHANGER PROCEDURE}
begin
WalkR:=WalkR+AnimationSp;
if WalkR>1000 then WalkR:=0;
WalkC:=Round(WalkR);
end;

Procedure SetupSprites;                               {SETUPSPRITES PROCEDURE}
var x,y : integer;
begin
for x := 1 to 16 do
for y := 1 to 16 do Up1[x,y]:=MEM[VSPR:(((y+29) shl 8)+((y+29) shl 6))+(x+23)];
for x := 1 to 16 do
for y := 1 to 16 do Up2[x,y]:=MEM[VSPR:(((y+29) shl 8)+((y+29) shl 6))+(x+39)];
for x := 1 to 16 do
for y := 1 to 16 do Do1[x,y]:=MEM[VSPR:(((y+61) shl 8)+((y+61) shl 6))+(x+23)];
for x := 1 to 16 do
for y := 1 to 16 do Do2[x,y]:=MEM[VSPR:(((y+61) shl 8)+((y+61) shl 6))+(x+39)];
for x := 1 to 13 do
for y := 1 to 16 do Le1[x,y]:=MEM[VSPR:(((y+111) shl 8)+((y+111) shl 6))+(x+34)];
for x := 1 to 13 do
for y := 1 to 16 do Le2[x,y]:=MEM[VSPR:(((y+111) shl 8)+((y+111) shl 6))+(x+47)];
for x := 1 to 13 do
for y := 1 to 16 do Ri1[x,y]:=MEM[VSPR:(((y+128) shl 8)+((y+128) shl 6))+(x+34)];
for x := 1 to 13 do
for y := 1 to 16 do Ri2[x,y]:=MEM[VSPR:(((y+128) shl 8)+((y+128) shl 6))+(x+47)];
end;


procedure Debug;                                             {DEBUG PROCEDURE}
var  test        : byte;
     test1,test2 : string;
     log         : text;
begin
{ assign(log,'numlog.log');
 append(log);
 Writeln(log,'Org.X: ',WeX,' Org.Y: ',Wey);
 Writeln(log,'Walks?', walk,' Collide?:',colide,':');
 writeln(log,'FPS: ',fps);
 Writeln(log);
 Close(log);}

 if night_ then test1:='night' else test1:='day';
{test:=MEM[VSPR:20826];
 str(test,test1);}


  WriteG(concat(test1,' demo'),10,10,transparent,VMCGA);

 GetFPS;
 WriteG(concat('fps: ',fps)
 ,10,193,55,VMCGA);      {Mov FPS counter to VMCGA}

 {Nosound;}

end;

Procedure MoveCharacter(x,y : integer);              {MOVECHARACTER PROCEDURE}
begin
WereX:=X;
WeX:=X;
WereY:=Y;
WeY:=Y;
end;

Procedure Collission;                                   {COLLISSION PROCEDURE}
var i : integer;

procedure GetCoord(ThisMap : byte);
var  i :integer;
begin
Case ThisMap of
   {LEFT WALL}
2:    if Wex<=(BoxX shl 5)+16 then WeX:=(BoxX shl 5)+16;

   {LEFT BOT CORNER WALL}
3:  begin
      if WeX<=(BoxX shl 5)+16 then WeX:=(BoxX shl 5)+16;
      if WeY>=((BoxY shl 4)+(BoxY shl 2))-9  then WeY:=((BoxY shl 4)+(BoxY shl 2))-9;
    end;

   {LEFT TOP CORNER WALL}
4:  begin
      if WeX<=(BoxX shl 5)+16 then WeX:=(BoxX shl 5)+16;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))+4  then WeY:=((BoxY shl 4)+(BoxY shl 2))+4;
    end;

   {TOP WALL}
5:    if WeY<=((BoxY shl 4)+(BoxY shl 2))+4 then WeY:=((BoxY shl 4)+(BoxY shl 2))+4;

   {RIGHT TOP CORNER WALL}
6:  begin
      if WeX>=(BoxX shl 5)+5 then WeX:=(BoxX shl 5)+5;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))+4 then WeY:=((BoxY shl 4)+(BoxY shl 2))+4;
    end;

   {RIGHT WALL}
7:    if WeX>=(BoxX shl 5)+10 then WeX:=(BoxX shl 5)+10;

   {RIGHT BOT CORNER WALL}
8:  begin
      if WeX>=(BoxX shl 5)+10 then WeX:=(BoxX shl 5)+10;
      if WeY>=((BoxY shl 4)+(BoxY shl 2))-9  then WeY:=((BoxY shl 4)+(BoxY shl 2))-9;
    end;

   {BOT WALL}
9:    if WeY>=((BoxY shl 4)+(BoxY shl 2))-8 then WeY:=((BoxY shl 4)+(BoxY shl 2))-8;

    {LEFT TOP CORNER LAKE}
10: begin
      if (WeX>=(BoxX shl 5)+5) then if (WeY>=((BoxY shl 4)+(BoxY shl 2))-6) then begin
          WeX:=BoxX shl 5+5; WeY:=((BoxY shl 4)+(BoxY shl 2))-6; end;
      if (WeY>=((BoxY shl 4)+(BoxY shl 2))-6) then if (WeX>=(BoxX shl 5)+5) then begin
          WeY:=BoxY*20-6; WeX:=(BoxX shl 5)+5; end;
    end;

    {LEFT LAKE}
11:   if WeX>=(BoxX shl 5)+5 then WeX:=(BoxX shl 5)+5;

    {LEFT BOT CORNER LAKE}
12: begin
      if WeX>=(BoxX shl 5)+5 then if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then WeX:=(BoxX shl 5)+5;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then if WeX>=(BoxX shl 5)+5 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {BOTTOM LAKE}
13:   if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then WeY:=BoxY*20-6;

    {RIGHT BOT CORNER LAKE}
14: begin
      if WeX<=(BoxX shl 5)+8 then if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then WeX:=(BoxX shl 5)+8;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then if WeX<=(BoxX shl 5)+8 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {RIGHT LAKE}
15:   if WeX<=(BoxX shl 5)+8 then WeX:=(BoxX shl 5)+8;

    {RIGHT TOP CORNER LAKE}
16: begin
      if WeX<=(BoxX shl 5)+8 then if WeY>=((BoxY shl 4)+(BoxY shl 2))-6 then WeX:=(BoxX shl 5)+8;
      if WeY>=((BoxY shl 4)+(BoxY shl 2))-6 then if WeX<=(BoxX shl 5)+8 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {TOP LAKE}
17:   if WeY>=((BoxY shl 4)+(BoxY shl 2))-6 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;

    {Left Top Corner Lake Invert}
20: begin
      if WeX<=(BoxX shl 5)+8 then WeX:=(BoxX shl 5)+8;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))-6  then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {Top lake invert}
21: If WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;

    {Right Top Corner Lake Invert}
22: begin
      if WeX>=(BoxX shl 5)+5 then WeX:=(BoxX shl 5)+5;
      if WeY<=((BoxY shl 4)+(BoxY shl 2))-6 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {Left Lake Invert}
23: if Wex<=(BoxX shl 5)+8 then WeX:=(BoxX shl 5)+8;

    {Right Lake Invert}
24: if WeX>=(BoxX shl 5)+5 then WeX:=(BoxX shl 5)+5;

    {Left Bot Corner Lake Invert}
25: begin
      if WeX<=(BoxX shl 5)+8 then WeX:=(BoxX shl 5)+8;
      if WeY>=((BoxY shl 4)+(BoxY shl 2))-6  then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

    {Bot Lake Invert}
26:   if WeY>=((BoxY shl 4)+(BoxY shl 2))-6 then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;

    {Right Bot Corner Lake Invert}
27: begin
      if WeX>=(BoxX shl 5)+5 then WeX:=(BoxX shl 5)+5;
      if WeY>=((BoxY shl 4)+(BoxY shl 2))-6  then WeY:=((BoxY shl 4)+(BoxY shl 2))-6;
    end;

end;


end;

begin
If WeX>310 then begin
    ExitRight:=TRUE;
    Moved:=TRUE;
    MoveCharacter(3,WereY);
   end;
If WeX<1   then begin ExitLeft:=TRUE;Moved:=TRUE;MoveCharacter(309,WereY);end;
If WeY>189 then begin ExitDown:=TRUE;Moved:=TRUE;MoveCharacter(WereX,2);end;
If WeY<0   then begin ExitUp:=TRUE;Moved:=TRUE;MoveCharacter(WereX,181);end;

if colide[BoxCodes(BoxX,BoxY)] then GetCoord(TypeOf[BoxCodes(BoxX,BoxY)]);

end;

Procedure LoadTheMap;                                   {LOADTHEMAP PROCEDURE}
var mx,my,Xmax,Xmin,Ymax,Ymin,yx,yy : integer;

procedure Spot(mapx,mapy,i : integer);
var x,y : integer;
begin

  for x := 1 to 32 do
  for y := 1 to 20 do
    case i of
      1:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+109) shl 8)+((Y+109) shl 6))+(X+96)];
      2:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+109) shl 8)+((Y+109) shl 6))+(X+64)];
      3:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+64)];
      4:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+64)];
      5:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+97)];
      6:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+128)];
      7:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+109) shl 8)+((Y+109) shl 6))+(X+128)];
      8:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+128)];
      9:  MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+96)];
      10: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+64)];
      11: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+49)  shl 8)+((Y+49)  shl 6))+(X+64)];
      12: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+64)];
      13: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+96)];
      14: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+128)];
      15: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+50)  shl 8)+((Y+50)  shl 6))+(X+128)];
      16: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+128)];
      17: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+96)];
      18: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+49)  shl 8)+((Y+49)  shl 6))+(X+96)];
      19: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+32)];
      20: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+160)];
      21: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+191)];
      22: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+29)  shl 8)+((Y+29)  shl 6))+(X+224)];
      23: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+49)  shl 8)+((Y+49)  shl 6))+(X+160)];
      24: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+49)  shl 8)+((Y+49)  shl 6))+(X+224)];
      25: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+160)];
      26: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+192)];
      27: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+69)  shl 8)+((Y+69)  shl 6))+(X+224)];
      28: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+160)];
      29: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+192)];
      30: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+89)  shl 8)+((Y+89)  shl 6))+(X+224)];
      31: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+109) shl 8)+((Y+109) shl 6))+(X+160)];
      32: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+160)];
      33: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+192)];
      34: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+224)];
      35: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+129) shl 8)+((Y+129) shl 6))+(X+224)];
      36: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+109) shl 8)+((Y+109) shl 6))+(X+224)];

      37: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+149) shl 8)+((Y+149) shl 6))+(X+64)];
      38: MEM[GRND:(((MapY+Y) shl 8)+((MapY+Y) shl 6))+(MapX+X)]:=MEM[VSPR:(((Y+149) shl 8)+((Y+149) shl 6))+(X+96)];
       {Here can more groundsprites be added,
        be sure you add collision data further up too}
    end;
end;



function WhatSpot:byte;
var i : byte;

  function Crashable(a : integer):BOOLEAN;
  begin
    Water:=FALSE;
    if a>1 then Crashable:=TRUE else Crashable:=FALSE;
    if a=18 then begin Crashable:=FALSE; Water:=TRUE;end;
  end;

begin
  {MAIN FUNCTION}

Inc(yx);
i:=MEM[MAP:WereMap+(yx)];
WhatSpot:=i;

  {Here We can perform other commands during loop}
  {without starting that ugly BEGIN -> END}

Colide[yx]:=Crashable(i);
TypeOf[yx]:=i;

end;

begin

If ExitRight then inc(WereMap,100);
If ExitLeft  then dec(WereMap,100);
If ExitDown  then inc(WereMap,3000);
If ExitUp    then dec(WereMap,3000);

If WereMap<0     then WereMap:=0;

ExitRight:=FALSE;
ExitLeft :=FALSE;
ExitUp   :=FALSE;
ExitDown :=FALSE;
WichShit :=1;
yx:=0;
for my := 1 to 100 do Colide[my]:=FALSE;

for my := 1 to 10 do
for mx := 1 to 10 do Spot((mx shl 5)-33,((my shl 4)+(my shl 2))-21,WhatSpot);


Moved:=FALSE;
end;


procedure DisplayStillCharacter_;
begin
IF NOT KEYDOWN[rightscan] OR
   NOT KEYDOWN[leftscan]  OR
   NOT KEYDOWN[upscan]    OR
   NOT KEYDOWN[downscan]  THEN DisplayStillCharacter(VMCGA);
end;

procedure CalculateBox;

procedure displaybox(x,y : integer);
var x1 : integer;
begin
for x1 := x to x+32 do SetPixel(x1,y,40,vMCGA);
for x1 := y to y+20 do SetPixel(x+32,x1,40,vMCGA);
for x1 := x to x+32 do SetPixel(x1,y+20,40,vMCGA);
for x1 := y to y+20 do SetPixel(x,x1,40,vMCGA);
end;


begin
  BoxX:=Round(WereX*0.030395137);
  BoxY:=Round(WereY*0.050000000);
{ DisplayBox(BoxX*32,BoxY*20);}
end;

procedure SetupPalForCha;                              {SETUPFORCHA PROCEDURE}
var i : integer;
    r,g,b : byte;
begin

for i := 0 to 255 do begin
  GetPal(i,r,g,b);
  Night[i]:=(r+g+b) DIV 3;
end;

for i := 0 to 255 do begin
  GetPal(i,r,g,b);
  Dr[i]:=r;
  Dg[i]:=g;
  Db[i]:=b;
end;

end;



procedure GetNightDay;
var h,m,s,ms: word;
    i       : integer;

procedure DayNightChanger;                         {DAYNIGHTCHANGER PROCEDURE}
var x,y     : integer;
    i,r,g,b : byte;
    StillDay,StillNight : Boolean;
    Change  : boolean;

function FadeDay:BOOLEAN;
var i,y : integer;
begin

for y := 1 to 63 do
for i := 0 to 255 do begin
getpal(i,r,g,b);
if r<>dr[i] then inc(r);
if g<>dg[i] then inc(g);
if b<db[i] then inc(b) else dec(b);
SetPal(i,r,g,b);
end;
end;

Function FadeNight:BOOLEAN;
var i,y : integer;
begin

for y := 1 to 63 do
for i := 0 to 255 do begin
getpal(i,r,g,b);
if r<>0 then dec(r);
if g<>0 then dec(g);
if b>Night[i] then dec(b) else inc(b);
SetPal(i,r,g,b);
end;


end;


begin
GetTime(h,m,s,ms);
if h>=23 then Night_:=TRUE;
Day:=ICKE(Night_);
if Night_ then FadeNight;
end;


begin
GetTime(h,m,s,ms);
if (h>=21) and (h<=6) then Night_:=TRUE;
Day:=ICKE(Night_);
DayNightChanger;
end;

procedure FadeToNight(Hour,minute,Second : word);
var r,g,b    : byte;
    h,m,s,ms : word;

function FadeNight:BOOLEAN;
var i : integer;
begin
inc(WereLoop);
FadeNight:=FALSE;
for i := 0 to 255 do begin
GetPal(i,r,g,b);
if r<>0    then dec(r);
if g<>0    then dec(g);
if b>night[i] then dec(b) else inc(b);
SetPal(i,r,g,b);
end;
if WereLoop=61 then FadeNight:=TRUE;
end;

function FadeDay:BOOLEAN;
var i : integer;
begin
inc(WereLoop);
FadeDay:=FALSE;
for i := 0 to 255 do begin
getpal(i,r,g,b);
if r<>dr[i] then inc(r);
if g<>dg[i] then inc(g);
if b<db[i] then inc(b) else dec(b);
SetPal(i,r,g,b);
end;
if WereLoop=61 then FadeDay:=TRUE;
end;

begin
GetTime(h,m,s,ms);

if not DoFadeN then if (s=15) then begin
  DoFadeN:=TRUE;
  wereloop:=0;
  Night_:=TRUE;
  Day:=ICKE(NIGHT_);
end;

if not DoFadeN then if (s=45) then begin
  DoFadeN:=TRUE;
  wereloop:=0;
  Night_:=FALSE;
  Day:=ICKE(NIGHT_);
end;

if DoFadeN and Night_ then if not FadeNight then DoFadeN:=FALSE;
if DoFadeN and Day then if not FadeDay then DoFadeN:=FALSE;

end;


begin
 {******* LoadData, And Setup Graphics}
 InitNewKeyInt;   {Init Better Keyboard Handling}

 ClearAll;        {Clear Our Virtual Memory}

 LoadSpriteTable; {This Procedure Init's Graph too...}
                  {Reads the Sprites into 'VSpr'}
                  {Vspr = CONSTANT, It's a graphic adress like $A000h}

 SetupSprites;    {Loads Sprites into Arrays}

 SetupPalForCha;  {Get the palette values for night/day changing}

 {******* Setup}

 {+++++++ FLIP data}
     {1 = VirScr^          **NOTE**
      2 = SpriteScr^
      3 = GroundScr^
      4 = MapScr^}


 InitFPS(2);      {Init The FPS counter to start in 2 seconds}
 Moved:=TRUE;     {Makes a screen appear}
 Down:=TRUE;      {So That The Character Will Be Displayed}

 GetNightDay;     {Detect if it's night or day}
 DoFadeN:=FALSE;
 WereLoop:=0;     {night/day}
 {******* Main Loop}
 Repeat

   If Moved then LoadTheMap; {Load a new frame if moved to a new frame}

   Flip(3,VMCGA);            {Mov background from GRND to VMCGA}

   DisplayStillCharacter_;   {If not moving, display a frozen character}

   SearchForKeyPress;        {Mov Character If Key is Pressed}

   CalculateBox;             {Calculate wich segment we are present in}

   Collission;               {Crashed into a Wall, Rock, Lake, End Of Screen?}

   WalkChanger;              {Animates the Character}

   FadeToNight(21,0,0);      {Detect the CMOS clock and change to night}

   Debug;                    {Perform Debug Commands}

   flip(1,MCGA);             {Mov VMCGA to MCGA(=$A000), Display Screen}

 Until KEYDOWN[escscan];     {Esc key pressed, then exit}

 SetOldKeyInt;               {Set Normal Keyboard Handling}

 ClrKeyBuf;                  {Clear The Fucking KeyBuffer}

end;

Procedure DisplayCredits(color : byte);             {DISPLAYCREDITS PROCEDURE}
var f          : text;
    r,g,b      : array[1..255] of byte;
    i          : integer;
    r1,g1,b1,c : char;
    x,y        : integer;

procedure FadeIn;
var i,a      : integer;
    r1,g1,b1 : byte;
begin

for i := 0 to 63 do begin
for a := 0 to 255 do begin
GetPal(a,r1,g1,b1);
if r1<r[a] then inc(r1);
if g1<g[a] then inc(g1);
if b1<b[a] then inc(b1);
SetPal(a,r1,g1,b1);
end;
VerticalRetrace;
end;

end;

begin
PalFade(63,20);
assign(f,'credits.dat');
reset(f);
  for i := 0 to 255 do begin
    read(f,r1);
    read(f,g1);
    read(f,b1);
    r[i]:=ord(r1);
    g[i]:=ord(g1);
    b[i]:=ord(b1);
  end;
  for x := 0 to 320 do
  for y := 0 to 200 do begin
    Read(f,c);
    SetPixel(x,y,ord(c),MCGA);
  end;
close(f);
FadeIn;
end;

Procedure ShutDown;                                       {SHUTDOWN PROCEDURE}
BEGIN
FreeMem (VirScr,64000);
FreeMem (SpriteScr,64000);
FreeMem (GroundScr,64000);
FreeMem (MapScr,MapSize);
END;



function menu:byte;
var k : char;
    i : integer;
begin
ClearVirtual(MCGA);
WriteG('menu---------',10,10,10,MCGA);
WriteG('1: start game',10,18,10,MCGA);
WriteG('2: quit game',10,26,10,MCGA);
repeat
i:=0;
if keypressed then k:=readkey;
if k=chr(027) then i:=2;
if k=chr(050) then i:=2;
if k=chr(049) then i:=1;
until i <> 0;
menu:=i;
end;

Procedure SetUpVirtual;
BEGIN
GetMem (VirScr,64000);
VMCGA := seg (virscr^);
GetMem (SpriteScr,64000);
VSPR  := seg (SpriteScr^);
GetMem (GroundScr,64000);
GRND  := seg (GroundScr^);
GetMem (MapScr,MapSize);
MAP   := seg (MapScr^);
END;


begin
 EndIsSet:=FALSE;    {OK}
 InitGraph;          {--------------------}
 SetUpVirtual;       {Setup Virtual Memory}
 ResetPositionData;  {Does what is says, 'is called here',
                      so that if you enter the menu
                      your character position is memorized}
repeat

 case menu of        {Menu system}

   1: StartRPGEngine;  {Starts The Game}
   2: EndIsSet:=TRUE;  {Quit}

 end;

Until EndIsSet;

 DisplayCredits(0); {Display The Credits}

 repeat          {<--+}
 until keypressed;  {|- Wait Here}

 {******* Close}
 CloseGraph;        {Close Mode 13h}
 ShutDown;          {Free the virtual memory}
end.
