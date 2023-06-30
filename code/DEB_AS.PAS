unit deb_as; {распределение памяти и вывод в файл отладочной информации}
interface

const
  deb_ind     : boolean = FALSE{}{TRUE};              {признак-переключатель вывода в файл}
  deb_mem_ind : boolean = FALSE{TRUE};  {признак-переключатель вывода в файл при работе с памятью}
  deb_time    : boolean = FALSE{TRUE};   {timer}
  deb_memPhys : boolean = FALSE{TRUE};   {Phys.Memory}
  deb_memUsed : boolean = FALSE{TRUE};   {MemUsed}
  deb_AlClose : boolean = FALSE{TRUE{}; {повторять ли открытик/закрытие файла при каждой записи}
  div_const   : longint = 1{024{};  {коэффициент деления для вывода количества памяти}

procedure deb2file(s:string; n:longint);                {вывод статистики в файл}
procedure GetMemC(var p:pointer; size:dword);              {выделение памяти}
procedure FreeMemC(p:pointer;    size:dword);              {освобождение памяти}
procedure GetMemF(var p:pointer; size:dword; s:string);       {выделение памяти}
procedure FreeMemF(p:pointer;    size:dword; s:string);       {освобождение памяти}

implementation
uses windows,timer_dw;

const
  MemAllocated  : dword = 0; {уже распределенная память}
  MemDisposed   : dword = 0; {сколько памяти просили освободить}
  MemAllocatedF : dword = 0;   {уже распределенная память}
  MemDisposedF  : dword = 0;   {сколько памяти просили освободить}
  MaxMemUsed    : dword = 0; {максимальное количество единовременно выделенной памяти}
  NumGetmem     : dword  = 0; {сколько раз обращались к getmem}
  NumFreemem    : dword  = 0; {сколько раз обращались к freemem}
  NumGetmemF    : dword  = 0;   {сколько раз обращались к getmem}
  NumFreememF   : dword  = 0;   {сколько раз обращались к freemem}
  filename      = 'deb_as.out'; {файл протокола}
  BegPhys       : longint  = 0;   {начальное значение свободной физической памяти}
  MinPhys       : dword  = 0;   {минимальное значение свободной физической памяти}
var
  ExitSave     : Pointer;       {адрес старой программы выхода в DOS }
  f            : text;        {файл протокола}
  BegCounter   : longint; {счетчик тиков в момент инициализации}
  counter      : longint; {счетчик - мс с начала работы программы}
  last_call    : longint; {показания счетчика в предыдущее обращение44321}
  MS           : TMemoryStatus;  {для запроса к системе о памяти}
  CurrentTimer : longint;   {для текущего времени}
  OldTime      : longint;
  OldMemPhys   : longint;
  OldMemUsed   : longint;

procedure deb2file(s:string; n:longint);{вывод статистики в файл}
var  NewTime, NewMemPhys, NewMemUsed : longint;
begin
  if deb_ind then begin
    GlobalMemoryStatus(MS);
    NewTime    := GetTimer_50 - BegCounter;
    NewMemPhys := MS.dwAvailPhys               div div_const;
    NewMemUsed := (MemAllocated - MemDisposed) div div_const;
    if deb_AlClose then
      append(f);
    CurrentTimer := GetTimer_50-BegCounter;
    if deb_time then
      write(f,'T:',NewTime div 20:5,'.',(NewTime mod 20)*5:2,'('
          ,(NewTime-OldTime) div 20:5,'.',((NewTime-OldTime) mod 20)*5:2,')');
    if deb_memPhys then
      write(f,' F:',NewMemPhys:6,'(',NewMemPhys-OldMemPhys:6,')');
    if deb_memUsed then
      write(f,' U:',    NewMemUsed:6,' (',NewMemUsed-OldMemUsed:6,')');
    writeln(f,' '+s,n);
    if deb_AlClose then
      close(f);
    OldTime    := NewTime;
    OldMemPhys := NewMemPhys;
    OldMemUsed := NewMemUsed;
    if MinPhys > NewMemPhys then
      MinPhys := NewMemPhys;
  end;
end;

procedure GetMemC(var p:pointer;size:dword);
begin
  if deb_mem_ind then
    deb2file('GetMemC (Kb):  ',size div div_const);
  if size <= 0 then
    deb2file(' ERROR-GetMemC (Kb):  ',size);
  getmem(p,size);
  MemAllocated := (MemAllocated + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumGetMem);
  if (MemAllocated - MemDisposed) > MaxMemUsed then
    MaxMemUsed := MemAllocated - MemDisposed;
end;

procedure FreeMemC(p:pointer;size:dword);
begin
  if deb_mem_ind then
    deb2file('FreeMemC (Kb): ',size div div_const);
  if size <= 0 then
    deb2file(' ERROR-FreeMemC (Kb): ',size);
  freemem(p,size);
  MemDisposed := (MemDisposed + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumFreeMem);
end;

procedure GetMemF(var p:pointer; size:dword; s:string);
begin
  if deb_mem_ind then
    deb2file('GetMemF (Kb):  '+s+' ',size div div_const);
  if size <= 0 then
    deb2file(' ERROR-GetMemF (Kb):  '+s+' ',size);
  getmem(p,size);
  MemAllocated := (MemAllocated + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumGetMem);
  MemAllocatedF := (MemAllocatedF + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumGetMemF);
  if (MemAllocated - MemDisposed) > MaxMemUsed then
    MaxMemUsed := MemAllocated - MemDisposed;
end;

procedure FreeMemF(p:pointer; size:dword; s:string);
begin
  if deb_mem_ind then
    deb2file('FreeMemF (Kb): '+s+' ',size div div_const);
  if size <= 0 then
    deb2file(' ERROR-FreeMemF (Kb): '+s+' ',size);
  freemem(p,size);
  MemDisposed := (MemDisposed + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumFreeMem);
  MemDisposedF := (MemDisposedF + size + 3) and $FFFFFFFC; {с выравниванием}
  inc(NumFreeMemF);
end;

{-----------------------}
procedure MyExit;  { дополнительная процедура при выходе в DOS }
begin
  ExitProc:=ExitSave;
  GlobalMemoryStatus(MS);
  deb2file('Deb_AS * Деинициализация                 ',0);
  deb2file('Deb_AS * запрошено (Kb):                 ',MemAllocated div div_const);
  deb2file('Deb_AS * возвращено(Kb):                 ',MemDisposed div div_const);
  deb2file('Deb_AS * запрошено  F (Kb):              ',MemAllocatedF div div_const);
  deb2file('Deb_AS * возвращено F (Kb):              ',MemDisposedF div div_const);
  deb2file('Deb_AS * макс.объем(Kb):                 ',MaxMemUsed div div_const);
  deb2file('Deb_AS * физ.память в начале(Kb):        ',BegPhys div div_const);
  deb2file('Deb_AS * физ.память в конце(Kb):         ',MS.dwAvailPhys div div_const);
  deb2file('Deb_AS * минимум физ.памяти(Kb):         ',MinPhys div div_const);
  deb2file('Deb_AS * уменьш.физ.памяти в конце(Kb):  ',(BegPhys - MS.dwAvailPhys) div div_const);
  deb2file('Deb_AS * макс.уменьшение физ.памяти(Kb): ',(BegPhys - MinPhys) div div_const);
  deb2file('Deb_AS * обращений GetMemC:              ',NumGetmem);
  deb2file('Deb_AS * обращений FreeMemC:             ',NumFreemem);
  deb2file('Deb_AS * обращений GetMemF:              ',NumGetmemF);
  deb2file('Deb_AS * обращений FreeMemF:             ',NumFreememF);
  if deb_ind then
    if not deb_AlClose then
      close(f);
end;

{-------------------}

begin
  BegCounter := GetTimer_50;
  ExitSave:=ExitProc;  {переопределение процедуры выхода}
  ExitProc:=@MyExit;
  if deb_ind then begin
    assign(f,filename);
    rewrite(f);
    GlobalMemoryStatus(MS);
    CurrentTimer := GetTimer_50-BegCounter;
    writeln(f,'Deb_as: Start Report Time=',CurrentTimer div 20,'.',(CurrentTimer mod 20)*5:2,
      ' ms Phys.Memory=',MS.dwAvailPhys div div_const,' MemAvail=',MemAvail div div_const,
      ' MaxAvail=',MaxAvail div div_const,' MemUsed=',(MemAllocated - MemDisposed) div div_const);
    if deb_AlClose then
      close(f);
    OldTime    := CurrentTimer;
    OldMemPhys := MS.dwAvailPhys               div div_const;
    OldMemUsed := (MemAllocated - MemDisposed) div div_const;
    BegPhys    := OldMemPhys;
    MinPhys    := OldMemPhys;
  end;
end.