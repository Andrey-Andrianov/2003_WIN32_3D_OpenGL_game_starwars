unit graphs2;
interface

const
  text_out_indeficator : longint = 1;

type
  scrtype = array[0..199,0..319]of byte; {тип массива для экрана}
  scrptr = ^scrtype;
  matr = array[1..4,1..4] of single;
  bekt = array[1..3] of single;

var
  pribors_tex : array[0..127,0..511,0..3] of byte;
  space_map_textura : ^array[0..511,0..511,0..3] of byte;
  textura_pich : ^array[0..511,0..511,0..3] of byte;
  scr : scrptr;
  np3 : scrptr;

procedure treug(x4,y4,z4,x5,y5,z5,x6,y6,z6:single);  {закрашенный треугольник}
procedure DrawLine(x1,y1,x2,y2:integer;color:byte); {линия}
procedure DrawLine2(x1,y1,x2,y2:integer;color:byte); {линия}
procedure addmatr(a,b : matr; var c : matr); {Сложение 2 матриц}
procedure add2matr(a,b : matr; var c : matr); {Умножение 2 матриц}
procedure matr_add2_vekt(a : matr; b : bekt; var c : bekt);{Умножение вектора на матрицу}
procedure putpixel(x,y : word; c : byte);
function getpixel(x,y : word):byte;

implementation

type
  m = array[1..4]of single;


procedure SwapInt(var a,b:integer);
var
  c : integer;
begin
  c := a;
  a := b;
  b := c;
end;

function Sgn(x:integer):integer;
begin
  if x >= 0 then
    Sgn := 1
  else
    Sgn := -1;
end;

procedure DrawLine(x1,y1,x2,y2:integer;color:byte);
var
  j,steps,sx,sy,dx,dy,e : integer;
  step : boolean;
begin
  dx := abs(x2 - x1);
  sx := sgn(x2 - x1);
  dy := abs(y2 - y1);
  sy := sgn(y2 - y1);
  step := (dy > dx);
  if step then begin
    SwapInt(x1,y1);
    SwapInt(dx,dy);
    SwapInt(sx,sy);
  end;
  e := 2 * dy - dx;
  for j := 1 to dx do begin
    if step then
      pribors_tex[x1,y1,1] := color
    else
      pribors_tex[y1,x1,1] := color;
    while e >= 0 do begin
      inc(y1,sy);
      dec(e,2 * dx);
    end;
    inc(x1,sx);
    inc(e,2 * dy);
  end;
  pribors_tex[y2,x2,1] := color;
end;


procedure DrawLine2(x1,y1,x2,y2:integer;color:byte);
var
  j,steps,sx,sy,dx,dy,e : integer;
  step : boolean;
begin
  dx := abs(x2 - x1);
  sx := sgn(x2 - x1);
  dy := abs(y2 - y1);
  sy := sgn(y2 - y1);
  step := (dy > dx);
  if step then begin
    SwapInt(x1,y1);
    SwapInt(dx,dy);
    SwapInt(sx,sy);
  end;
  e := 2 * dy - dx;
  for j := 1 to dx do begin
    if step then
      space_map_textura^[x1,y1,1] := color
    else
      space_map_textura^[y1,x1,1] := color;
    while e >= 0 do begin
      inc(y1,sy);
      dec(e,2 * dx);
    end;
    inc(x1,sx);
    inc(e,2 * dy);
  end;
  space_map_textura^[y2,x2,1] := color;
end;


procedure treug(x4,y4,z4,x5,y5,z5,x6,y6,z6:single);
type
  p = record
    x : integer;
    y : integer;
    n : integer;
  end;
var
  a,b,c : p;
  sy,i,j : word;
  col :byte;
  x1,x2,x3,y1,y2,y3 : word;
  ax,ay,az ,bx,by,bz ,cx,cy,cz ,dx,dy,dz ,l,ambient,anp : single;
begin
 if (y4-y5)*(x4-x6) < (y4-y6)*(x4-x5) then begin
  ax := x6 - x5;     {1 вектор}
  ay := y6 - y5;
  az := z6 - z5;

  bx := x4 - x5;     {2 вектор}
  by := y4 - y5;
  bz := z4 - z5;

  cx := ay*bz - az*by;  {нормаль}
  cy := az*bx - ax*bz;
  cz := ax*by - ay*bx;

  l := sqrt(cx*cx + cy*cy + cz*cz);   {длинна нормали}
  ambient := 10;     {освещение без источника}
  anp := 40;         {мощность источника}

  cx := cx / l; {единичная нормаль}
  cy := cy / l;
  cz := cz / l;

  dx := 0;      {вектор света}
  dy := 0;
  dz := 1;

  col := round(ambient + anp*(cx*dx + cy*dy + cz*dz)); {интенсивность}
  (*****************************************************)
  x1 := round(x4);
  x2 := round(x5);
  x3 := round(x6);
  y1 := round(y4);
  y2 := round(y5);
  y3 := round(y6);
  a.x := x1;   {верхняя точка}
  a.y := y1;
  a.n := 1;
  if a.y > y2 then begin
    a.x := x2;
    a.y := y2;
    a.n := 2;
  end;
  if a.y > y3 then begin
    a.x := x3;
    a.y := y3;
    a.n := 3;
  end;
  c.y := -1;   {нижняя точка}
  c.n := 1;
  if (a.n <> 1) then begin
    c.x := x1;
    c.y := y1;
    c.n := 1;
  end;
  if (c.y < y2) and (a.n <> 2) then begin
    c.x := x2;
    c.y := y2;
    c.n := 2;
  end;
  if (c.y < y3) and (a.n <> 3) then begin
    c.x := x3;
    c.y := y3;
    c.n := 3;
  end;
  b.n := 6 - a.n - c.n;     {средняя точка}
  if b.n = 1 then begin
    b.x := x1;
    b.y := y1;
  end;
  if b.n = 2 then begin
    b.x := x2;
    b.y := y2;
  end;
  if b.n = 3 then begin
    b.x := x3;
    b.y := y3;
  end;
  if c.y <> a.y then
    for sy := a.y to c.y do begin
      x1 := (a.x + (sy - a.y) * (c.x - a.x) div (c.y - a.y));
      if sy < b.y then
        x2 := (a.x + (sy - a.y) * (b.x - a.x) div (b.y - a.y))
      else
        if c.y = b.y then
          x2 := b.x
        else
          x2 := (b.x + (sy - b.y) * (c.x - b.x) div (c.y - b.y));
      if x1 > x2 then begin
        i := x2;
        x2 := x1;
        x1 := i;
      end;
      fillchar(np3^[sy,x1],x2-x1,col);
    end;
  (*****************************************************)
 end;
end;

procedure addmatr(a,b : matr; var c : matr); {Сложение 2 матриц}
var
  i,j : integer;
begin
  for i := 1 to 4 do
    for j := 1 to 4 do
      c[i,j] := a[i,j] + b[i,j];
end;

function a2m(a,b:m):single;
var
  i : integer;
  c : single;
begin
  c := 0;
  for i := 1 to 4 do
    c := a[i] * b[i] + c;
  a2m := c;
end;

procedure add2matr(a,b : matr; var c : matr); {Умножение 2 матриц}
var
  i,j,i2 : integer;
  x : m;
begin
  for i := 1 to 4 do
    for j := 1 to 4 do
      c[i,j] := 0;
  for i := 1 to 4 do
    for j := 1 to 4 do begin
      for i2 := 1 to 4 do
        x[i2] := b[i2,j];
      c[i,j] := a2m(m(a[i]),x);
    end;
end;

procedure matr_add2_vekt(a : matr; b : bekt; var c : bekt);
var
  i,j : integer;
begin
  for i := 1 to 3 do
    c[i] := 0;
  for i := 1 to 3 do
    for j := 1 to 3 do
      c[i] := c[i] + a[i,j] * b[j];
end;

procedure putpixel(x,y : word; c : byte);
begin
  scr^[y,x] := c;
end;

function getpixel(x,y : word):byte;
begin
  getpixel := scr^[y,x];
end;

begin
//  scr:=ptr($A000,0){ptr(SegA000,0)};
end.