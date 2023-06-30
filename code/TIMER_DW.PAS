unit timer_dw; { (c) S. Andrianov 2001 2:5017/13.40@fidonet andriano@tsinet.ru}
{ модуль измерени€ времени - должен работать до частоты процессора 42.5 √√ц }
interface

function gettimer_1:dword;    {счетчик в мкс (обнул€етс€ раз в 15-35 мин)}
function gettimer_50:dword;   {счетчик в 50 мкс (обнул€етс€ раз в 15-35 ч)}
function gettimer_1000:dword; {счетчик в мс (обнул€етс€ раз в 12-25 сут)}
function getCPUtick:dword;    {счетчик в циклах процессора (обн.раз в 3-30 сек}
function GetCPUfreq:dword;    {частота процессора в к√ц (т.е. 133000-1400000)}
function GetDelta:dword;      {погрешность частоты процессора в к√ц}
function isqrt(x:longint):longint; {arithmetic version}

implementation
uses WinDos;

var
   b1,b50,b1000,delta : longint; {b1000 - частота в к√ц, delta - ср.кв.откл. }
   C1,c50,c1000       : longint; {маски}

function GetCPUfreq:dword;    {частота процессора в к√ц (т.е. 133000-1400000)}
begin
   GetCPUfreq := b1000;
end;

function GetDelta:dword; {погрешность частоты процессора в к√ц}
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

function GetLessFF(n:longint):longint;{возвр бинарное число вида 00...0011...11 меньшее заданного}
var i,j : longint;
begin
   j := 1;
   repeat
      i := j;
      j := j*2;
   until j > n;
   GetLessFF := i-1;
end;

const n = 8; {(3-255) количаетво тиков по 55 мс, отводимых дл€ измерени€}
var
   i,j,k : integer;
   t : array[0..n]of longint; {массив сначала тактов, а затем их приращений}
   d : array[0..n]of longint; {массив приращений показаний часов в мс}
   t0,t1,t2,c0,tt0,tt1 : dword;
   h_,m_,s_,d_,d1_ : word;
   tt : text;
   appr_d,d_sum,d_t,d_d : longint; {приблизительное к-во тактов на тик;сумма тиков;сумма тактов; мс/тик}
begin
   tt0 := getCPUtick;
   k := n div 4; {отбрасываем примернo по 1/4 с каждой стороны}
   d_sum := 0;
   for i := 0 to n do begin {формируем массив значений tsc}
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
   appr_d := (d_sum + (d_t div 2)) div d_t;{прибл. к-во тактов на тик}
   d_d := (d_sum + (n div 2))div n;        {прибл. к-во мс/тик}
   if (d_d > 40) and (d_d < 75) then begin
      for i := 0 to n-1 do begin  {формируем массив времен на 1 тик}
{!}         t[i] := (t[i+1]-t[i] + 25) div 50;   {!!!!!!!!!!!!!!!!!!!!!!!!!!!}
         if t[i] < 0 then t[i] := 0;
      end;
      for i := 1 to n-1 do        {сортируем массив}
         for j := n-1 downto i do
            if t[j] < t[j-1] then
               begin
                  t0 := t[j]; t[j] := t[j-1]; t[j-1] := t0;
                  t0 := d[j]; d[j] := d[j-1]; d[j-1] := t0;
               end;
      t0 := 0;
      for i := k to n-1-k do
         inc(t0,t[i]);
      t0 := (t0 + n div 2 - k) div (n-k-k); {среднее к-во тактов за тик}
      t1 := (t0 * 91 + 50) div 100;      {среднее к-во тактов за мс}
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