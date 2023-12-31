unit timer_dw; { (c) S. Andrianov 2001 2:5017/13.40@fidonet andriano@tsinet.ru}
{ ������ ��������� ������� - ������ �������� �� ������� ���������� 42.5 ��� }
interface

function gettimer_1:dword;    {������� � ��� (���������� ��� � 15-35 ���)}
function gettimer_50:dword;   {������� � 50 ��� (���������� ��� � 15-35 �)}
function gettimer_1000:dword; {������� � �� (���������� ��� � 12-25 ���)}
function getCPUtick:dword;    {������� � ������ ���������� (���.��� � 3-30 ���}
function GetCPUfreq:dword;    {������� ���������� � ��� (�.�. 133000-1400000)}
function GetDelta:dword;      {����������� ������� ���������� � ���}
function isqrt(x:longint):longint; {arithmetic version}

implementation
uses WinDos;

var
   b1,b50,b1000,delta : longint; {b1000 - ������� � ���, delta - ��.��.����. }
   C1,c50,c1000       : longint; {�����}

function GetCPUfreq:dword;    {������� ���������� � ��� (�.�. 133000-1400000)}
begin
   GetCPUfreq := b1000;
end;

function GetDelta:dword; {����������� ������� ���������� � ���}
begin
   GetDelta := delta;
end;

function gettimer_1:dword; assembler;
asm
      db $0f,$31 {rdtsc}
      and edx,c1
      div b1
end;

function gettimer_50:dword; assembler;
asm
      db $0f,$31 {rdtsc}
      and edx,c50
      div b50
end;

function gettimer_1000:dword; assembler;
asm
      db $0f,$31 {rdtsc}
      and edx,c1000
      div b1000
end;

function getCPUtick:dword;  assembler;
asm
      db $0f,$31 {rdtsc}
      and eax,$7fffffff
end;

function isqrt(x:longint):longint; {arithmetic version}
var a,b:longint;
begin
  b:=x;        {initial value}
  repeat
    a:=b;
    b:=(a+x div a) div 2;
  until a<=b;
  isqrt:=a;
end;

function GetLessFF(n:longint):longint;{����� �������� ����� ���� 00...0011...11 ������� ���������}
var i,j : longint;
begin
   j := 1;
   repeat
      i := j;
      j := j*2;
   until j > n;
   GetLessFF := i-1;
end;

const n = 8; {(3-255) ���������� ����� �� 55 ��, ��������� ��� ���������}
var
   i,j,k : integer;
   t : array[0..n]of longint; {������ ������� ������, � ����� �� ����������}
   d : array[0..n]of longint; {������ ���������� ��������� ����� � ��}
   t0,t1,t2,c0,tt0,tt1 : dword;
   h_,m_,s_,d_,d1_ : word;
   tt : text;
   appr_d,d_sum,d_t,d_d : longint; {��������������� �-�� ������ �� ���;����� �����;����� ������; ��/���}
begin
   tt0 := getCPUtick;
   k := n div 4; {����������� �������o �� 1/4 � ������ �������}
   d_sum := 0;
   for i := 0 to n do begin {��������� ������ �������� tsc}
      GetTime(h_,m_,s_,d_);
      repeat
         GetTime(h_,m_,s_,d1_);
      until d1_ <> d_;
      t[i] := getCPUtick;
      if d1_ > d_ then
         d[i] := (d1_-d_)*10
      else
         d[i] := (d1_+100-d_)*10;
      inc(d_sum,d[i]);
   end;
   d_sum := d_sum-d[0];
   d_t := t[n]-t[0];
   appr_d := (d_sum + (d_t div 2)) div d_t;{�����. �-�� ������ �� ���}
   d_d := (d_sum + (n div 2))div n;        {�����. �-�� ��/���}
   if (d_d > 40) and (d_d < 75) then begin
      for i := 0 to n-1 do begin  {��������� ������ ������ �� 1 ���}
{!}         t[i] := (t[i+1]-t[i] + 25) div 50;   {!!!!!!!!!!!!!!!!!!!!!!!!!!!}
         if t[i] < 0 then t[i] := 0;
      end;
      for i := 1 to n-1 do        {��������� ������}
         for j := n-1 downto i do
            if t[j] < t[j-1] then
               begin
                  t0 := t[j]; t[j] := t[j-1]; t[j-1] := t0;
                  t0 := d[j]; d[j] := d[j-1]; d[j-1] := t0;
               end;
      t0 := 0;
      for i := k to n-1-k do
         inc(t0,t[i]);
      t0 := (t0 + n div 2 - k) div (n-k-k); {������� �-�� ������ �� ���}
      t1 := (t0 * 91 + 50) div 100;      {������� �-�� ������ �� ��}
      t2 := 0;
      for i := k to n-1-k do
         inc(t2,sqr(t[i]-t0));
      t2 := (t2 + n div 2 - k) div (n-k-k);
      t2 := isqrt(t2);
      t2 := (t2 * 91 + 50) div 100;
      delta := t2;
   end else begin
      t1 := (d_t + (d_sum div 2)) div d_sum;
      delta := 8888;
   end;
   b1000 := t1;
   b50 := (b1000 + 10) div 20;
   b1 := (b1000 + 500) div 1000;
   c1    := GetLessFF(   b1);
   c50   := GetLessFF(  b50);
   c1000 := GetLessFF(b1000);
   tt1 := getCPUtick;

//   assign(tt,'timer_dw.out');
//   rewrite(tt);
//   writeln(tt,'Timer_dw: const(1/50/100): ',b1,' / ',b50,' / ',b1000,' delta=',delta,' kHz');
//   writeln(tt,'Timer_dw: time elapced: ',(tt1-tt0) div b1000,' ms');
//   writeln(tt,'Timer_dw: tact/tic: ',Appr_d,' ms/tic:', d_d);
//   for i := 0 to n-1 do
//      writeln(tt,'Timer_dw: t[',i,']=',t[i],' d[',i,']=',d[i]);
//   writeln(tt,'Timer_dw: const "c" (1/50/100): ',c1,' / ',c50,' / ',c1000);
//   close(tt);
end.