unit matx_wd; {работа с матрицами}
interface

type
   TDoubleVector = Record
      X,Y,Z : double;
   End;
   MatriXtype = array[0..3,0..3]of double;
function BegMatrix : MatrixType;                   {единичная матрица}
function MulMatrix(m1,m2:MatrixType) : MatrixType; {m3 = m1*m2}
function MoveMatr(v:TDoubleVector) : MatrixType;     {матрица перемещения}
function RotMatrX(a:Double) : MatrixType;          {матрица вращения вокруг X}
function RotMatrY(a:Double) : MatrixType;          {матрица вращения вокруг Y}
function RotMatrZ(a:Double) : MatrixType;          {матрица вращения вокруг Z}
function MatrVect(m:MatrixType; v:TDoubleVector):TDoubleVector;  {w=m*v}

implementation
const
  MainMatr : MatriXtype = ((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

function BegMatrix : MatrixType;                   {единичная матрица}
begin
  BegMatrix := MainMatr;
end;

function MulMatrix(m1,m2:MatrixType) : MatrixType;{m3 = m1*m2}
var
{  i,j : integer;{}
  m : MatrixType;
begin
  m[0,0] := m1[0,0]*m2[0,0] + m1[0,1]*m2[1,0] + m1[0,2]*m2[2,0] + m1[0,3]*m2[3,0];
  m[0,1] := m1[0,0]*m2[0,1] + m1[0,1]*m2[1,1] + m1[0,2]*m2[2,1] + m1[0,3]*m2[3,1];
  m[0,2] := m1[0,0]*m2[0,2] + m1[0,1]*m2[1,2] + m1[0,2]*m2[2,2] + m1[0,3]*m2[3,2];
  m[0,3] := m1[0,0]*m2[0,3] + m1[0,1]*m2[1,3] + m1[0,2]*m2[2,3] + m1[0,3]*m2[3,3];
  m[1,0] := m1[1,0]*m2[0,0] + m1[1,1]*m2[1,0] + m1[1,2]*m2[2,0] + m1[1,3]*m2[3,0];
  m[1,1] := m1[1,0]*m2[0,1] + m1[1,1]*m2[1,1] + m1[1,2]*m2[2,1] + m1[1,3]*m2[3,1];
  m[1,2] := m1[1,0]*m2[0,2] + m1[1,1]*m2[1,2] + m1[1,2]*m2[2,2] + m1[1,3]*m2[3,2];
  m[1,3] := m1[1,0]*m2[0,3] + m1[1,1]*m2[1,3] + m1[1,2]*m2[2,3] + m1[1,3]*m2[3,3];
  m[2,0] := m1[2,0]*m2[0,0] + m1[2,1]*m2[1,0] + m1[2,2]*m2[2,0] + m1[2,3]*m2[3,0];
  m[2,1] := m1[2,0]*m2[0,1] + m1[2,1]*m2[1,1] + m1[2,2]*m2[2,1] + m1[2,3]*m2[3,1];
  m[2,2] := m1[2,0]*m2[0,2] + m1[2,1]*m2[1,2] + m1[2,2]*m2[2,2] + m1[2,3]*m2[3,2];
  m[2,3] := m1[2,0]*m2[0,3] + m1[2,1]*m2[1,3] + m1[2,2]*m2[2,3] + m1[2,3]*m2[3,3];
  m[3,0] := m1[3,0]*m2[0,0] + m1[3,1]*m2[1,0] + m1[3,2]*m2[2,0] + m1[3,3]*m2[3,0];
  m[3,1] := m1[3,0]*m2[0,1] + m1[3,1]*m2[1,1] + m1[3,2]*m2[2,1] + m1[3,3]*m2[3,1];
  m[3,2] := m1[3,0]*m2[0,2] + m1[3,1]*m2[1,2] + m1[3,2]*m2[2,2] + m1[3,3]*m2[3,2];
  m[3,3] := m1[3,0]*m2[0,3] + m1[3,1]*m2[1,3] + m1[3,2]*m2[2,3] + m1[3,3]*m2[3,3];{}
{  for i := 0 to 3 do
    for j := 0 to 3 do
      m[i,j] := m1[i,0]*m2[0,j] + m1[i,1]*m2[1,j] + m1[i,2]*m2[2,j] + m1[i,3]*m2[3,j];{}
  MulMatrix := m;{}
end;

function MoveMatr(v:TDoubleVector) : MatrixType; {матрица перемещения}
var m : MatrixType;
begin
   m[0,0] := 1;        m[0,1] :=  0;        m[0,2] := 0;     m[0,3] := 0;
   m[1,0] := 0;        m[1,1] :=  1;        m[1,2] := 0;     m[1,3] := 0;
   m[2,0] := 0;        m[2,1] :=  0;        m[2,2] := 1;     m[2,3] := 0;
   m[3,0] := v.x;      m[3,1] :=  v.y;      m[3,2] := v.z;   m[3,3] := 1;
   MoveMatr := m;
end;

function RotMatrZ(a:Double) : MatrixType; {матрица вращения вокруг X}
var m : MatrixType;
begin
   m[0,0] := cos(a);   m[0,1] :=  sin(a);   m[0,2] := 0;   m[0,3] := 0;
   m[1,0] :=-sin(a);   m[1,1] :=  cos(a);   m[1,2] := 0;   m[1,3] := 0;
   m[2,0] := 0;        m[2,1] :=  0;        m[2,2] := 1;   m[2,3] := 0;
   m[3,0] := 0;        m[3,1] :=  0;        m[3,2] := 0;   m[3,3] := 1;
   RotMatrZ := m;
end;

function RotMatrX(a:Double) : MatrixType; {матрица вращения вокруг Y}
var m : MatrixType;
begin
   m[0,0] := 1;        m[0,1] :=  0;        m[0,2] := 0;         m[0,3] := 0;
   m[1,0] := 0;        m[1,1] :=  cos(a);   m[1,2] :=  sin(a);   m[1,3] := 0;
   m[2,0] := 0;        m[2,1] := -sin(a);   m[2,2] := cos(a);    m[2,3] := 0;
   m[3,0] := 0;        m[3,1] :=  0;        m[3,2] := 0;         m[3,3] := 1;
   RotMatrX := m;
end;

function RotMatrY(a:Double) : MatrixType; {матрица вращения вокруг Z}
var m : MatrixType;
begin
   m[0,0] := cos(a);   m[0,1] :=  0;        m[0,2] :=-sin(a);   m[0,3] := 0;
   m[1,0] := 0;        m[1,1] :=  1;        m[1,2] := 0;        m[1,3] := 0;
   m[2,0] :=  sin(a);  m[2,1] :=  0;        m[2,2] := cos(a);   m[2,3] := 0;
   m[3,0] := 0;        m[3,1] :=  0;        m[3,2] := 0;        m[3,3] := 1;
   RotMatrY := m;
end;

function MatrVect(m:MatrixType; v:TDoubleVector):TDoubleVector;{w=m*v}
var
  i : integer;
  w : TDoubleVector;
begin
   w.x := v.x*m[0,0] + v.y*m[1,0] + v.z*m[2,0] + m[3,0];
   w.y := v.x*m[0,1] + v.y*m[1,1] + v.z*m[2,1] + m[3,1];
   w.z := v.x*m[0,2] + v.y*m[1,2] + v.z*m[2,2] + m[3,2];
   MatrVect := w;
end;

end.