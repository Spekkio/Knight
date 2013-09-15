{.dat file reader by Daniel Hedeblom}
program DatRed;
uses vesa,crt;

var i,x,y   : integer;
    r,g,b,c : char;
    f       : text;
    p       : string;

begin
Write('Dat File To Read: ');
readln(p);
InitGraph;
assign(f,p);
reset(f);

for i := 0 to 255 do begin
read(f,r);
read(f,g);
read(f,b);
SetPal(i,ord(r),ord(g),ord(b));
end;

for x := 0 to 320 do
for y := 0 to 200 do begin
read(f,c);
SetPixel(x,y,ord(c),MCGA);
end;

close(f);

repeat until keypressed;

CloseGraph;
end.