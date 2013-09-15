{$F+}
unit games;

interface

{ constants for scan codes of various keys }

const escscan: byte = $01;
      backscan: byte = $0e;
      ctrlscan: byte = $1d;
      lshscan: byte = $2a;
      capscan: byte = $3a;
      f1scan: byte = $3b;
      f2scan: byte = $3c;
      f3scan: byte = $3d;
      f4scan: byte = $3e;
      f5scan: byte = $3f;
      f6scan: byte = $40;
      f7scan: byte = $41;
      f8scan: byte = $42;
      f9scan: byte = $43;
      f10scan: byte = $44;
      f11scan: byte = $d9;
      f12scan: byte = $da;
      scrlscan: byte = $46;
      tabscan: byte = $0f;
      entscan: byte = $1c;
      rshscan: byte = $36;
      prtscan: byte = $37;
      altscan: byte = $38;
      homescan: byte = $47;
      upscan: byte = $48;
      pgupscan: byte = $49;
      minscan: byte = $4a;
      leftscan: byte = $4b;
      midscan: byte = $4c;
      rightscan: byte = $4d;
      plusscan: byte = $4e;
      endscan: byte = $4f;
      downscan: byte = $50;
      pgdnscan: byte = $51;
      insscan: byte = $52;
      delscan: byte = $53;
      numscan: byte = $45;

{ arrays that record keyboard status }

var keydown, wasdown: array[0..127] of boolean;

{ procedures/functions you may call }

procedure initnewkeyint;
procedure setoldkeyint;
procedure clearwasdownarray;
procedure initnewtimint;
procedure setoldtimint;
procedure initnewbrkint;
procedure setoldbrkint;
function scanof(chartoscan: char): byte;
procedure tickwait(time2wait: byte);

{}
implementation
uses dos;

{ pointers to old interrupt routines }

var oldkbdint, oldtimint, oldbrkint: pointer;
    cloktick: byte; { counter to count clock "ticks" }
{}
procedure sti;
inline($fb);    { STI: set interrupt flag }
{}
procedure cli;
inline($fa);    { CLI: clear interrupt flag -- not used }
{}
procedure calloldint(sub: pointer);

{ calls old interrupt routine so that your programs don't deprive the computer
  of any vital functions -- kudos to Stephen O'Brien and "Turbo Pascal 6.0:
  The Complete Reference" for including this inline code on page 407 }

begin
  inline($9c/           { PUSHF }
         $ff/$5e/$06)   { CALL DWORD PTR [BP+6] }
  end;
{}
procedure newkbdint; interrupt;   { new keyboard handler }
begin
  keydown[port[$60] mod 128] := (port[$60] < 128);  { key is down if value of
                                                      60h is less than 128 --
                                                      record current status }
  if port[$60] < 128 then wasdown[port[$60]] := true; { update WASDOWN if the
                                                        key is currently
                                                        depressed }
  calloldint(oldkbdint);                              { call old interrupt }
  mem[$0040:$001a] := mem[$0040:$001c];   { Clear keyboard buffer: the buffer
                                            is a ring buffer, where the com-
                                            puter keeps track of the location
                                            of the next character in the buffer
                                            end the final character in the
                                            buffer.  To clear the buffer, set
                                            the two equal to each other. }
  sti
  end;
{}
procedure initnewkeyint;      { set new keyboard interrupt }
var keycnt: byte;
begin
  for keycnt := 0 to 127 do begin   { reset arrays to all "False" }
    keydown[keycnt] := false;
    wasdown[keycnt] := false
    end;
  getintvec($09, oldkbdint);        { record location of old keyboard int }
  setintvec($09, addr(newkbdint));  { this line installs the new interrupt }
  sti
  end;
{}
procedure setoldkeyint;           { reset old interrupt }
begin
  setintvec($09, oldkbdint);
  sti
  end;
{}
procedure clearwasdownarray;      { set all values in WASDOWN to "False" }
var cnter: byte;
begin
  for cnter := 0 to 127 do wasdown[cnter] := false
  end;
{}
function scanof(chartoscan: char): byte;  { return scan code corresponding
                                            to a character }
var tempbyte: byte;
begin
  tempbyte := 0;
  case upcase(chartoscan) of
    '!', '1': tempbyte := $02;
    '@', '2': tempbyte := $03;
    '#', '3': tempbyte := $04;
    '$', '4': tempbyte := $05;
    '%', '5': tempbyte := $06;
    '^', '6': tempbyte := $07;
    '&', '7': tempbyte := $08;
    '*', '8': tempbyte := $09;
    '(', '9': tempbyte := $0a;
    ')', '0': tempbyte := $0b;
    '_', '-': tempbyte := $0c;
    '+', '=': tempbyte := $0d;
    'A': tempbyte := $1e;
    'S': tempbyte := $1f;
    'D': tempbyte := $20;
    'F': tempbyte := $21;
    'G': tempbyte := $22;
    'H': tempbyte := $23;
    'J': tempbyte := $24;
    'K': tempbyte := $25;
    'L': tempbyte := $26;
    ':', ';': tempbyte := $27;
    '"', '''': tempbyte := $28;
    '~', '`': tempbyte := $29;
    ' ': tempbyte := $39;
    'Q': tempbyte := $10;
    'W': tempbyte := $11;
    'E': tempbyte := $12;
    'R': tempbyte := $13;
    'T': tempbyte := $14;
    'Y': tempbyte := $15;
    'U': tempbyte := $16;
    'I': tempbyte := $17;
    'O': tempbyte := $18;
    'P': tempbyte := $19;
    '{', '[': tempbyte := $1a;
    '}', ']': tempbyte := $1b;
    '|', '\': tempbyte := $2b;
    'Z': tempbyte := $2c;
    'X': tempbyte := $2d;
    'C': tempbyte := $2e;
    'V': tempbyte := $2f;
    'B': tempbyte := $30;
    'N': tempbyte := $31;
    'M': tempbyte := $32;
    '<', ',': tempbyte := $33;
    '>', '.': tempbyte := $34;
    '?', '/': tempbyte := $35
    end;
  scanof := tempbyte
  end;
{}
procedure newtimint; interrupt;   { new timer interrupt }
begin
  calloldint(oldtimint);          { call old timer interrupt }
  cloktick := cloktick + 1        { update "tick" counter }
  end;
{}
procedure initnewtimint;              { set up new timer interrupt }
begin
  getintvec($1c, oldtimint);          { record location of old interrupt }
  setintvec($1c, addr(newtimint));    { install new interrupt procedure }
  cloktick := 0;                      { set counter to 0 }
  sti
  end;
{}
procedure setoldtimint;               { reset old timer }
begin
  setintvec($1c, oldtimint);
  sti
  end;
{}
procedure tickwait(time2wait: byte);    { do nothing until counter reaches
                                          certain value }
begin
  repeat until cloktick >= time2wait;
  cloktick := 0                         { reset counter }
  end;
{}
procedure newbrkint; interrupt;   { new "Ctrl-Break" interrupt: does nothing }
begin 
  sti
  end;
{}
procedure setoldbrkint;           { reset old "Ctrl-Break" interrupt }
begin
  setintvec($1b, oldbrkint);
  sti
  end;
{}
procedure initnewbrkint;              { install new "Ctrl-Break" interrupt }
begin
  getintvec($1b, oldbrkint);          { get old interrupt location }
  setintvec($1b, addr(newbrkint));    { set up new interrupt procedure }
  sti
  end;

end.