unit deb_as; {������������� ������ � ����� � ���� ���������� ����������}
interface

const
  deb_ind     : boolean = FALSE{}{TRUE};              {�������-������������� ������ � ����}
  deb_mem_ind : boolean = FALSE{TRUE};  {�������-������������� ������ � ���� ��� ������ � �������}
  deb_time    : boolean = FALSE{TRUE};   {timer}
  deb_memPhys : boolean = FALSE{TRUE};   {Phys.Memory}
  deb_memUsed : boolean = FALSE{TRUE};   {MemUsed}
  deb_AlClose : boolean = FALSE{TRUE{}; {��������� �� ��������/�������� ����� ��� ������ ������}
  div_const   : longint = 1{024{};  {����������� ������� ��� ������ ���������� ������}

procedure deb2file(s:string; n:longint);                {����� ���������� � ����}
procedure GetMemC(var p:pointer; size:dword);              {��������� ������}
procedure FreeMemC(p:pointer;    size:dword);              {������������ ������}
procedure GetMemF(var p:pointer; size:dword; s:string);       {��������� ������}
procedure FreeMemF(p:pointer;    size:dword; s:string);       {������������ ������}

implementation
uses windows,timer_dw;

const
  MemAllocated  : dword = 0; {��� �������������� ������}
  MemDisposed   : dword = 0; {������� ������ ������� ����������}
  MemAllocatedF : dword = 0;   {��� �������������� ������}
  MemDisposedF  : dword = 0;   {������� ������ ������� ����������}
  MaxMemUsed    : dword = 0; {������������ ���������� ������������� ���������� ������}
  NumGetmem     : dword  = 0; {������� ��� ���������� � getmem}
  NumFreemem    : dword  = 0; {������� ��� ���������� � freemem}
  NumGetmemF    : dword  = 0;   {������� ��� ���������� � getmem}
  NumFreememF   : dword  = 0;   {������� ��� ���������� � freemem}
  filename      = 'deb_as.out'; {���� ���������}
  BegPhys       : longint  = 0;   {��������� �������� ��������� ���������� ������}
  MinPhys       : dword  = 0;   {����������� �������� ��������� ���������� ������}
var
  ExitSave     : Pointer;       {����� ������ ��������� ������ � DOS }
  f            : text;        {���� ���������}
  BegCounter   : longint; {������� ����� � ������ �������������}
  counter      : longint; {������� - �� � ������ ������ ���������}
  last_call    : longint; {��������� �������� � ���������� ���������44321}
  MS           : TMemoryStatus;  {��� ������� � ������� � ������}
  CurrentTimer : longint;   {��� �������� �������}
  OldTime      : longint;
  OldMemPhys   : longint;
  OldMemUsed   : longint;

procedure deb2file(s:string; n:longint);{����� ���������� � ����}
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
  MemAllocated := (MemAllocated + size + 3) and $FFFFFFFC; {� �������������}
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
  MemDisposed := (MemDisposed + size + 3) and $FFFFFFFC; {� �������������}
  inc(NumFreeMem);
end;

procedure GetMemF(var p:pointer; size:dword; s:string);
begin
  if deb_mem_ind then
    deb2file('GetMemF (Kb):  '+s+' ',size div div_const);
  if size <= 0 then
    deb2file(' ERROR-GetMemF (Kb):  '+s+' ',size);
  getmem(p,size);
  MemAllocated := (MemAllocated + size + 3) and $FFFFFFFC; {� �������������}
  inc(NumGetMem);
  MemAllocatedF := (MemAllocatedF + size + 3) and $FFFFFFFC; {� �������������}
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
  MemDisposed := (MemDisposed + size + 3) and $FFFFFFFC; {� �������������}
  inc(NumFreeMem);
  MemDisposedF := (MemDisposedF + size + 3) and $FFFFFFFC; {� �������������}
  inc(NumFreeMemF);
end;

{-----------------------}
procedure MyExit;  { �������������� ��������� ��� ������ � DOS }
begin
  ExitProc:=ExitSave;
  GlobalMemoryStatus(MS);
  deb2file('Deb_AS * ���������������                 ',0);
  deb2file('Deb_AS * ��������� (Kb):                 ',MemAllocated div div_const);
  deb2file('Deb_AS * ����������(Kb):                 ',MemDisposed div div_const);
  deb2file('Deb_AS * ���������  F (Kb):              ',MemAllocatedF div div_const);
  deb2file('Deb_AS * ���������� F (Kb):              ',MemDisposedF div div_const);
  deb2file('Deb_AS * ����.�����(Kb):                 ',MaxMemUsed div div_const);
  deb2file('Deb_AS * ���.������ � ������(Kb):        ',BegPhys div div_const);
  deb2file('Deb_AS * ���.������ � �����(Kb):         ',MS.dwAvailPhys div div_const);
  deb2file('Deb_AS * ������� ���.������(Kb):         ',MinPhys div div_const);
  deb2file('Deb_AS * ������.���.������ � �����(Kb):  ',(BegPhys - MS.dwAvailPhys) div div_const);
  deb2file('Deb_AS * ����.���������� ���.������(Kb): ',(BegPhys - MinPhys) div div_const);
  deb2file('Deb_AS * ��������� GetMemC:              ',NumGetmem);
  deb2file('Deb_AS * ��������� FreeMemC:             ',NumFreemem);
  deb2file('Deb_AS * ��������� GetMemF:              ',NumGetmemF);
  deb2file('Deb_AS * ��������� FreeMemF:             ',NumFreememF);
  if deb_ind then
    if not deb_AlClose then
      close(f);
end;

{-------------------}

begin
  BegCounter := GetTimer_50;
  ExitSave:=ExitProc;  {��������������� ��������� ������}
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