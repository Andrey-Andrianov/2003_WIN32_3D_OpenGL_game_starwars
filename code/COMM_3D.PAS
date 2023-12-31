unit comm_3d;{����� ����, ��������� � ��������� �� ������ � 3D-���������}
interface
uses matrx_wd;

const
  MaxPoints   = 65536*2;{x(12+8)  64K vertecles = 0.75 Mb in file/ 2.25 Mb in memory}
  MaxFaces    = 65536*4;{x(12+)  64K faces = 512 K in file/ 0.75 Mb in memory}
  MaxMat      = 1024;   { *260 ���� ���-�� ���������� � �����}
  MaxMatObj   = 1024;   { *176 ����. ���-�� ����������, ����������� � ��������}
  MaxObj      = 1024;   { *248 ����. ���-�� ��������}
  ToFile      : boolean = FALSE;   {����� �� ������ ��������� � ����}
  ToErrorFile : boolean = FALSE; {����� �� ������ ��������� � ���� ������}
  ListMode    : longint = 4;
  ListModeOld : longint = 4;
  DefMaterial = 'Default Material'; {��� ��������� �� ��������� - ��� ������� ��� �������� ���������}
  MaxValue    = 32768; {������������ ��������, ������� ����� ��������� ����������}
  DebFileOpened : boolean = FALSE; {������� �� ����� ��� ���������}
  Distance      : single = 40; {���������� �� ������ (�����������, ������ �� �������� �������)}
Type
  TRealVector = Record          {������ - 12 ����}
    X,Y,Z : single;
  End;
  TtextC = record               {���������� ���������� (8 bytes)}
    u,v : single;
  end;
  ColorType = record    {���� ��� ������������� ��������� OprnGL}
    r,g,b,a : single; {�������� ������������ � ������������ (16 bytes)}
  end;
  FaceType      = Array[1..3] of longint;       { 12 bytes ������ ������ � �����}
  FaceType2     = Array[1..4] of word; { 8 bytes ������ ������ � ����� (��� ������) + �����}
//  MatriXtype    = array[0..3,0..3]of single;           { 64 bytes ������� 4�4}
  VectArrayType = Array[0..MaxPoints-1]of TRealVector;  { *12 }
  FaceArrayType = Array[0..MaxFaces-1]of FaceType;      { *12 }
  FaceArrayType2= Array[0..MaxFaces-1]of FaceType2;     { *6 }
  TextArrayType = Array[0..MaxPoints-1]of TtextC;       { *8 }
  FaceWordType  = Array[0..MaxFaces-1]of word;          { *4 }
  FaceLongType  = Array[0..MaxFaces-1]of longint;       { *8 }
  NameStr       = string[79];                           { *80 }
  Tobj3DS = record {��������������� ������ (80+48+128+32+24=312 bytes)}
    nm    : NameStr;        {80 ��������}
    pv    : ^VectArrayType; { 4 (nv) ������ ������}
    nv    : longint;        { 4 ���������� ������ ��� ������� �������, � ����� �����.�����}
    pf    : ^FaceArrayType; { 4 (nf) ������ ������}
    pff   : ^FaceWordType;  { 4 (nf) ������ ������ ������}
    pfg   : ^FaceLongType;  { 4 (nf) ������ ����� ����������� ������}
    nf    : longint;        { 4 ���������� ������}
    nfm   : longint;        { 4 ���������� ������ � �����������}
    pt    : ^TextArrayType; { 4 (nv ?) ������ ���������� ���������}
    nt    : longint;        { 4 ���������� ���������� ���������}
    parent: longint;        { 4 ������-��������}
    m0,m1 : longint;        { 8 ������� ������ � ������ ������ ���������� � ������� MatObj}
    tm    : MatrixType;     {128 -/ 64 ������� ��������������}
    cr    : TRealVector;    {12 ����� �������� (�� ����� ��������)}
    ar    : TRealVector;    {12 ��� �������� (�� ����� ��������)}
    lb    : longbool;       { 4 ������� �����������}
    vz    : longbool;       { 4 ������� ����, ��� ������� ���������� �� �����}
    MaX,MiX,MaY,MiY,MaZ,MiZ : single; {24 ������� �������}
  end;
  Tmaterial = record {�������� ����������, ������������ � ����� (160+20+64+12+4=260)}
    nm    : Namestr;   {80 �������� ��������� ()}
    nt    : Namestr;   {80 ��� ����� ��������   }
    dx,dy : longint;   { 8 ������� ��������     }
    bp    : longint;   { 4 ������� ����� ��������, ����: 1,3,4}
    texp  : single;    { 4 ������� ��������}
    pt    : pointer;   { 4 ��������� �� ������ � ���������}
    ambi  : ColorType; {16 ���� ���������� ���������     (default=(0.2,0.2,0.2,1))}
    diff  : ColorType; {16 ���� ���������� ���������     (default=(0.8,0.8,0.8,1))}
    spec  : ColorType; {16 ���� ����������� ���������    (default=(0.1,0.1,0.1,1))}
    emis  : ColorType; {16 ���� ���������                (default=(0.0,0.0,0.0,1))}
    tran  : single;    { 4 ������� ������������          (default=0)}
    shin  : single;    { 4 ������� ����������� ��������� (default=0)}
    lb    : longbool;  { 4 ������� �����������}
   {--------�������������� ����-------------------------}
    dlst  : longint;   { 4 ���������� ���� ��� ��������}
  end;
  TmatObj = record {�������� ���������� ����������� �������  (80+36+24+36=176)}
    nm    : Namestr; {80 �������� ���������}
    pr,nx : longint; { 8 ������� ����������� � ����������� ���������� � ������ � ������� MatObj}
    io    : longint; { 4 4����� �������, �������� �������� ��������}
    im    : longint; { 4 ����� ��������� � ������� Material}
    pf    : ^FaceLongType; { 4 (nf<Obj.nf) ������ ������ ��� ������� ��������� � ������� Obj3DS.pf}
    nf    : longint; { 4 ���������� ������ ��� ������� ��������� � ������� FaceMat}
    lb    : longbool;{ 4 ������� �����������}
    fl0,fl1:word; { 8 ����� ���������}
    xi,xa,x0,yi,ya,y0,zi,za,z0 : single; {36 �����������, ������������ � ������� ����������}
   {--------�������������� ����-------------------------}
    pvf   : ^VectArrayType; { 4 ������ ������, ������������� ��� �����������}
    pvn   : ^VectArrayType; { 4 ������ �������� (� ��������), ������������� ��� �����������}
    pnf   : ^VectArrayType; { 4 ������ <�������> �������� (� ������), ������������� ��� �����������}
    nvn   : longint;        { 4 ������ �������� ������ � ��������}
    ptf   : ^TextArrayType; { 4 ������ ���������� ���������, ������������� ��� �����������}
    ntf   : longint;        { 4 ���������� ���������� ���������}
  end;
var
  f             : file;                      {���� .3DS}
  lf            : longint;                   {����� �����}
  FilePos       : longint;                   {������� � �����}
  Obj3DS      : Array[0..MaxObj-1]of Tobj3DS;    {������ ��������}
  NObj3DS     : longint;                         {���������� �������� (����� ��������� ������� ������+1)}
  Material    : Array[0..MaxMat-1]of Tmaterial;  {������ ����������}
  Nmater      : longint;                         {���������� ���������� (����� ������.������� ������+1)}
  MatObj      : Array[0..MaxMatObj-1]of TmatObj; {������ ���������� ��������}
  NmatObj     : longint;                         {���������� ���������� �������� (����� ����.���.������+1)}
  Npoints     : longint; {��� ����������: ����� ���������� ������}
  Nfaces      : longint; {��� ����������: ����� ���������� ������}
  NfaceMat    : longint; {��� ����������: ����� ���������� ������ � �����������}
  NtextC      : longint; {��� ����������: ����� ���������� ���������� ���������}
  Mpoints     : longint; {��� ����������: ������������ ���������� ������ � ����� �������}
  Mfaces      : longint; {��� ����������: ������������ ���������� ������ � ����� �������}
  t             : text;                        {���� ���������}
  q             : text;                        {���� ��������� ������}
  CurObj3DS     : longint;                   {����� �������� �������}
  CurMater      : longint;                   {����� �������� ���������}
  CurMatObj     : longint;                   {����� �������� ��������� ��������}
  FnameInput    : string;                    {��� 3DS-����� }
  FnameReport   : string;                    {��� ����� ���������}
  FnameError    : string;                    {��� ����� ��� ��������� �� �������}
  NumChunkRead  : longint;                   {���������� ������, ����������� ����������}

function Hex2str(w:word):string; { word -> string(hex)}
function l2str(l:longint):Namestr; { longint -> string(hex)}
function w2b(w:word):NameStr;  { word -> string(bin)}
//procedure ChangeListMode{(mode:longint)}; {��������� ������ ������� ���������}
function FindObj3DS(s : string) : longint; {����� ������ ������� �� �����}
function FindMatObj(s : string; Nobj : longint) : longint; {����� ������ ��������� ������� �� �����}
function FindMaterial(s : string) : longint; {����� ������ ��������� �� �����}
procedure CreateMatObj(Nobj,CountL : longint; name : NameStr); {�������� ��������� �������}
                    {Nobj - ����� �������, CountL - ���������� ������ ������� ���������}
procedure DeleteMatObj(Nmat : longint); {����������� ��������� �������}
function CreateObj3DS(name : NameStr) : longint; {�������� ������� (�����. ����� �������)}
procedure DeleteObj3DS(Nobj : longint); {����������� �������}
procedure CreateMaterial(name : NameStr); {�������� ���������}
procedure DeleteMaterial(Nmat : longint); {����������� ���������}
procedure DeleteAllObjMat; {����������� ���� �������� � ����������}
procedure PrintStat; {����� � ���� ����������}

implementation

uses deb_as;

var
  FirstEmpObj   : longint;                     {������ ��������� ������ (��� ������ �� �������)}
  FirstEmpMat   : longint;                     {������ ��������� �������� (��� ������ �� �������)}
  FirstEmpMO    : longint;                     {������ ��������� �������� ������� (��� ������ �� �������)}
//  NobjAter    : longint; {����� � ������� ��������, ���� �������� ��� ������ ���������}
//  NmatAter    : longint; {����� � ������� ����������, ���� �������� ��� ������ ���������}
//  NmatObjAter : longint; {����� � ������� ���������� ��������, ���� �������� ��� ������ ���������}
const h : array[0..15]of char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

function Hex2str(w:word):string; { word -> string(hex)}
begin
   Hex2str := h[w shr 12] + h[(w shr 8) and $f] + h[(w shr 4) and $f] + h[w and $f];
end;

function l2str(l:longint):Namestr; { longint -> string(hex)}
begin
   if lf >= 65536 then
      l2str := h[ l shr 20]         + h[(l shr 16) and $f] + h[(l shr 12) and $f]
             + h[(l shr  8) and $f] + h[(l shr  4) and $f] + h[ l         and $f]
   else
      l2str := h[l shr 12] + h[(l shr 8) and $f] + h[(l shr 4) and $f] + h[l and $f];
end;

function w2b(w:word):NameStr;  { word -> string(bin)}
var
   s : namestr;
   i : integer;
begin
   s := '';
   for i := 15 downto 0 do
      s := s + char(((w shr i) and 1) + byte('0'));
   w2b := s;
end;

//procedure ChangeListMode{(mode:longint)}; {��������� ������ ������� ���������}
{begin
  deb2file('ChangeListMode OldMode: ',ListModeOld);
  deb2file('ChangeListMode FileReport: '+FnameReport+' ',0);
  deb2file('ChangeListMode ToFile: ',longint(ToFile));
  deb2file('ChangeListMode FileError: '+FnameError+' ',0);
  deb2file('ChangeListMode ToErrorFile: ',longint(ToErrorFile));
  deb2file('ChangeListMode NewMode: ',ListMode);
  if (ListModeOld and 1) = 1 then {��������}
{    if ToFile then begin
      deb2file('ChangeListMode Close(r): '+FnameReport+' ',longint(ToFile));
      writeln(t,' Close file, New filename: ',FnameReport);
      close(t);
    end;
  if (ListModeOld and 2) = 2 then {������}
{    if ToErrorFile then begin
      deb2file('ChangeListMode Close(e): '+FnameError+' ',longint(ToErrorFile));
      writeln(t,' Close file, New filename: ',FnameError);
      close(q);
    end;
  ListModeOld := ListMode;
  if ((ListMode and 1) = 1) and (FnameReport <> '') then begin{��������}
{    deb2file('ChangeListMode Open(r): '+FnameReport+' ',longint(ToFile));
    assign(t,FnameReport);
    rewrite(t);
    writeln(t,'ChangeListMode Mode: ',ListMode);
    ToFile := TRUE;
  end else
    ToFile := FALSE;
  if ((ListMode and 2) = 2) and (FnameError <> '') then begin{��������}
{    deb2file('ChangeListMode Open(e): '+FnameError+' ',longint(ToErrorFile));
    assign(q,FnameError);
    writeln(q,'ChangeListMode Mode: ',ListMode);
    rewrite(q);
    ToErrorFile := TRUE;
  end else
    ToErrorFile := FALSE;
  deb2file('ChangeListMode end ToFile: ',longint(ToFile));
  deb2file('ChangeListMode end ToErrorFile: ',longint(ToErrorFile));
end;}

function FindObj3DS(s : string) : longint; {����� ������ ������� �� �����}
var n,i : longint;
begin
  n := -1;
  for i := 0 to Nobj3DS - 1 do
    if Obj3DS[i].nm = s then
      n := i;
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindObj3DS �������: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindObj3DS �������: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   ������ ������ ',n,' �� ����� ',s);
  FindObj3DS := n;
end;

function FindMatObj(s : string; Nobj : longint) : longint; {����� ������ ��������� ������� �� �����}
var n,i : longint;
begin
  n := -1;
  i := Obj3DS[NObj].m0;
  repeat {����� ��������� ������� �� �����}
    if s = MatObj[i].nm then
       n := i;
    i := MatObj[i].nx;
  until (i = -1);
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindMatObj �������� ������� ',Nobj,' Imo: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindMatObj �������� ������� ',Nobj,' Imo: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   ������ �������� ������� ',Nobj,' NumMatObj: ',n,' �� ����� ',s);
  FindMatObj := n;
end;

function FindMaterial(s : string) : longint; {����� ������ ��������� �� �����}
var n,i : longint;
begin
  n := -1;
  for i := 0 to Nmater-1 do {����� ��������� �� �����}
    if s = Material[i].nm then
      n := i;
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindMaterial ��������: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindMaterial ��������: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   ������ �������� ',n,' �� ����� ',s);
  FindMaterial := n;
end;

procedure CreateMatObj(Nobj,CountL : longint; name : NameStr); {�������� ��������� �������}
var i : longint; {Nobj - ����� �������, CountL - ���������� ������ ������� ���������}
begin
  while MatObj[FirstEmpMO].lb and (FirstEmpMO < MaxMatObj) do inc(FirstEmpMO); {���� ��������� �����}
  if FirstEmpMO >= MaxMatObj then begin
    if ToFile then
      writeln(t,' CreateMatObj ERROR: MatObj list overflow FirstEmpMO=',FirstEmpMO);
    if ToErrorFile then
      writeln(q,' CreateMatObj ERROR: MatObj list overflow FirstEmpMO=',FirstEmpMO,
                   ' Nobj=',Nobj,' CountL=',CountL,' Name:',name);
    halt;
  end;
  CurMatObj := FirstEmpMO;
  inc(FirstEmpMO);
  if NmatObj < FirstEmpMO then
    NmatObj := FirstEmpMO;
  with MatObj[CurMatObj] do begin
    if not lb then begin
      nm := name; {�������� ���������}
      pr := Obj3DS[Nobj].m1; {������ ���������� ��������� � ������ � ������� MatObj}
      if pr = -1 then begin {������ �������� � �������}
        Obj3DS[Nobj].m0 := CurMatObj;
      end else begin                     {����������� �������� � �������}
        MatObj[pr].nx := CurMatObj;
      end;
      Obj3DS[Nobj].m1 := CurMatObj;
      nx := -1; {������ ������������ ��������� � ������ � ������� MatObj}
      io := Nobj; {����� �������, �������� �������� ��������}
      im := -1; {����� ��������� � ������� Material}
      for i := 0 to Nmater-1 do
         if Material[i].nm = name then
           im := i;
      if im = -1 then begin
        if ToFile then
           writeln(t,'    CreateMatObj ERROR: Material ',name,' not found');
        if ToErrorFile then
           writeln(q,'    CreateMatObj ERROR: Material ',name,' not found',' Nobj=',Nobj,' CountL=',CountL);
      end;
      pf := nil; {������ ������ ��� ������� ��������� � ������� FaceMat}
      if CountL > 0 then
        getmemF(pf,CountL*sizeof(longint),'r3:CrMO');
      nf  := CountL;   {���������� ������ ��� ������� ��������� � ������� FaceMat}
      lb  := TRUE;     {������� �����������}
      fl0 := 0;      {����� ���������}
      fl1 := $ffff;  {����� ���������}
      pvf := nil;    {������ ������, ������������� ��� �����������}
      pvn := nil;    {������ ��������, ������������� ��� �����������}
      nvn := 0;        {������ �������� ������ � ��������}
      ptf := nil;    {������ ���������� ���������, ������������� ��� �����������}
      ntf := 0;        {���������� ���������� ���������}
      if ToFile then begin
        writeln(t,'    CreateMatObj: CurMatObj=',CurMatObj,' Nobj=',Nobj,' Mat=',im,' Prev=',pr,
           ' Next=',nx,' Faces=',CountL,' Name=',name,' pf=',longint(pf));
      end;
    end else begin
      if ToFile then
        writeln(t,'    **ERROR** CreateMatObj: CurMatObj=',CurMatObj,' Nobj=',Nobj,' Name=',name);
      if ToErrorFile then
        writeln(q,'    **ERROR** CreateMatObj: CurMatObj=',CurMatObj,' Nobj=',Nobj,' Name=',name);
    end;
  end;
end;

procedure DeleteMatObj(Nmat : longint); {����������� ��������� �������}
begin
  if (Nmat >= 0) and (Nmat < NmatObj) then
    with MatObj[Nmat] do begin
      if lb then begin
//        if ToFile then begin
//          writeln(t,'    DeleteMatObj: Nmat=',Nmat,' Nobj=',io,' Mat=',im,' Prev=',pr,
//             ' Next=',nx,' Name=',nm);
//        end;
//        nm := '';
        if pr >= 0 then
          MatObj[pr].nx := nx
        else
          Obj3DS[io].m0 := nx;
        if nx >= 0 then
          MatObj[nx].pr := pr
        else
          Obj3DS[io].m1 := pr;
        pr := -2;
        nx := -2;
//        io := -1;
//        im := -1;
        if pf <> nil then begin freememF(pf,nf*sizeof(longint),'r3:DlMO1');  pf := nil;  end;
        nf := 0;
        lb := FALSE;
        if pvf <> nil then begin freememF(pvf,nvn*sizeof(TrealVector),'r3:DlMO2');  pvf := nil;  end;
        if pvn <> nil then begin freememF(pvn,nvn*sizeof(TRealVector),'r3:DlMO3');  pvn := nil;  end;
        if pnf <> nil then begin freememF(pnf,nvn*sizeof(TRealVector),'r3:DlMO3');  pnf := nil;  end;
        nvn := 0;
        if ptf <> nil then begin freememF(ptf,ntf*sizeof(TtextC),'r3:DlMO4');  ptf := nil;  end;
        ntf := 0;
        if NmatObj = (Nmat+1) then dec(NmatObj); {��� ����������� ��������� ������� �������}
        if FirstEmpMO > Nmat then FirstEmpMO := Nmat;
      end else begin
        deb2file('    **ERROR** DeleteMatObj: Nmat=',Nmat);
        deb2file('    **ERROR** DeleteMatObj: '+nm+' Nobj=',io);
//        deb2file('    **ERROR** DeleteMatObj: Name=',nm);
//        if ToFile then
//          writeln(t,'    **ERROR** DeleteMatObj: Nmat=',Nmat,' Nobj=',io,' Name=',nm);
//        if ToErrorFile then
//          writeln(q,'    **ERROR** DeleteMatObj: Nmat=',Nmat,' Nobj=',io,' Name=',nm);
      end;
    end
  else
    if ToFile then
      writeln(t,'  ERROR!!! DeleteMatObj: Nmat=',Nmat,' No cuch material of object');
end;

function CreateObj3DS(name : NameStr) : longint; {�������� ������� (�����. ����� �������)}
const DefMatr : MatrixType = ((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));
begin
  while Obj3DS[FirstEmpObj].lb and (FirstEmpObj < MaxObj) do inc(FirstEmpObj); {���� ��������� �����}
  if FirstEmpObj >= MaxObj then begin
    if ToFile then
      writeln(t,' CreateObj3DS ERROR: Object list overflow FirstEmpObj=',FirstEmpObj);
    if ToErrorFile then
      writeln(q,' CreateObj3DS ERROR: Object list overflow FirstEmpObj=',FirstEmpObj,' Name:',name);
    halt;
  end;
  CurObj3DS := FirstEmpObj;
  inc(FirstEmpObj);
  if Nobj3DS <= FirstEmpObj then
    Nobj3DS := FirstEmpObj;
  with Obj3DS[CurObj3DS] do begin
    if not lb then begin
      nm     := name;    {��������}
      pv     := nil;     {������ ������}
      nv     := 0;       {���������� ������ ��� ������� �������, � ����� �����.�����}
      pf     := nil;     {������ ������}
      pff    := nil;     {������ ������ ������}
      pfg    := nil;     {������ ����� ����������� ������}
      nf     := 0;       {���������� ������}
      nfm    := 0;       {���������� ������ � �����������}
      pt     := nil;     {������ ���������� ���������}
      nt     := 0;       {���������� ���������� ���������}
      parent := -1;      {������-��������}
      m0     := -1;      {������� ������ � ������ ������ ���������� � ������� MatObj}
      m1     := -1;      {������� ������ � ������ ������ ���������� � ������� MatObj}
      tm     := DefMatr; {������� ��������������}
      cr.X := 0;   cr.Y := 0;   cr.Z := 0; {����� �������� (�� ����� ��������)}
      ar.X := 1;   ar.Y := 0;   ar.Z := 0; {��� �������� (�� ����� ��������)}
      lb     := TRUE;    {������� �����������}
      vz     := TRUE;    {������� �����������}
      if ToFile then begin
        writeln(t,'    CreateObj3DS: Obj=',CurObj3DS,' Name=',nm,
                     ' (Points:',Npoints,', Faces:',Nfaces,')');
        CreateObj3DS := CurObj3DS;
      end;
    end else begin
      if ToFile then
        writeln(t,'    **ERROR** CreateObj3DS: obj=',CurObj3DS,' Name=',nm);
      if ToErrorFile then
        writeln(q,'    **ERROR** CreateObj3DS: obj=',CurObj3DS,' Name=',nm);
        CreateObj3DS := -1;
    end;
  end;
end;

procedure DeleteObj3DS(Nobj : longint); {����������� �������}
begin
  if (Nobj >= 0) and (Nobj < NObj3DS) then
    with Obj3DS[Nobj] do begin
      if lb then begin
//        if ToFile then begin
//          writeln(t,'    DeleteObj3DS: obj=',Nobj,' Name=',nm);
//        end;
        nm := '';
        if pv  <> nil then begin  freememF(pv,nv*sizeof(TRealVector),'r3:DlO31');  pv  := nil;  end;
        nv := 0;
        if pf  <> nil then begin  freememF(pf,nf*sizeof(FaceType),'r3:DlO32');     pf  := nil;  end;
        if pff <> nil then begin  freememF(pff,nf*sizeof(word),'r3:DlO33');        pff := nil;  end;
        if pfg <> nil then begin  freememF(pfg,nf*sizeof(longint),'r3:DlO34');     pfg := nil;  end;
        nf := 0;
        nfm:= 0;
        if pt  <> nil then begin  freememF(pt,nt*sizeof(TtextC),'r3:DlO35');       pt  := nil;  end;
        nt := 0;
        while m0 <> -1 do
          DeleteMatObj(m0);
        lb := FALSE;
        if Nobj3DS = (Nobj+1) then dec(Nobj3DS); {��� ����������� ��������� ������� �������}
        if FirstEmpObj > Nobj then FirstEmpObj := Nobj;
      end else begin
        deb2file('    **ERROR** DeleteObj3DS: '+nm+' obj=',Nobj);
//        deb2file('    **ERROR** DeleteObj3DS: Name=',nm);
//        if ToFile then
//          writeln(t,'    **ERROR** DeleteObj3DS: obj=',Nobj,' Name=',nm);
//        if ToErrorFile then
//          writeln(q,'    **ERROR** DeleteObj3DS: obj=',Nobj,' Name=',nm);
      end;
    end
  else
    if ToFile then
      writeln(t,'  ERROR!!! DeleteObj3DS: Nobj=',Nobj,' No cuch object');
end;

procedure CreateMaterial(name : NameStr); {�������� ���������}
const AmbiDef : ColorType = (r : 0.2;  g : 0.2;  b : 0.2;  a : 1.0);
      DiffDef : ColorType = (r : 0.8;  g : 0.8;  b : 0.8;  a : 1.0);
      SpecDef : ColorType = (r : 0.1;  g : 0.1;  b : 0.1;  a : 1.0);
      EmisDef : ColorType = (r : 0.0;  g : 0.0;  b : 0.0;  a : 1.0);
begin
  while Material[FirstEmpMat].lb and (FirstEmpMat < MaxMat) do inc(FirstEmpMat); {���� ��������� �����}
  if FirstEmpMat >= MaxMat then begin
    if ToFile then
      writeln(t,' CreateMaterial ERROR: Object list overflow FirstEmpMat=',FirstEmpMat);
    if ToErrorFile then
      writeln(q,' CreateMaterial ERROR: Object list overflow FirstEmpMat=',FirstEmpMat,' Name:',name);
    halt;
  end;
  CurMater := FirstEmpMat;
  inc(FirstEmpMat);
  if Nmater < FirstEmpMat then
    Nmater := FirstEmpMat;
  with Material[CurMater] do begin
    if not lb then begin
      nm   := name;      {�������� ��������� ()}
      nt   := '';   {��� ����� ��������   }
      dx   := 0;   {������� ��������     }
      dy   := 0;   {������� ��������     }
      bp   := 0;   {������� ����� ��������}
      pt   := nil; {��������� �� ������ � ���������}
      ambi := AmbiDef; {���� ���������� ���������     (default=(0.2,0.2,0.2,1))}
      diff := DiffDef; {���� ���������� ���������     (default=(0.8,0.8,0.8,1))}
      spec := SpecDef; {���� ����������� ���������    (default=(0.1,0.1,0.1,1))}
      emis := EmisDef; {���� ���������                (default=(0.0,0.0,0.0,1))}
      tran := 0;       {������� ������������          (default=0)}
      shin := 0.1;       {������� ����������� ��������� (default=0)}
      lb   := TRUE;  {������� �����������}
      dlst := -1;
//******************      LoadTexture(dx, dy, bp, pt, nt, dlist);
      if ToFile then begin
        writeln(t,'    CreateMaterial: CurMater=',CurMater,' Name=',name);
      end;
    end else begin
      deb2file('    **ERROR** CreateMaterial: '+name+' CurMater=',CurMater);
//      deb2file('    **ERROR** CreateMaterial: Name=',name);
      if ToFile then
        writeln(t,'    **ERROR** CreateMaterial: CurMater=',CurMater,' Name=',name);
      if ToErrorFile then
        writeln(q,'    **ERROR** CreateMaterial: CurMater=',CurMater,' Name=',name);
    end;
  end;
end;

procedure DeleteMaterial(Nmat : longint); {����������� ���������}
begin
  with Material[Nmat] do begin
    if lb then begin
//      nm   := name;      {�������� ��������� ()}
//      nt   := '';   {��� ����� ��������   }
      if pt <> nil then begin freememF(pt,dx*dy*bp,'DelMater');  pt  := nil;  end;
      dx   := 0;   {������� ��������     }
      dy   := 0;   {������� ��������     }
      bp   := 0;   {������� ����� ��������}
//      ambi := AmbiDef; {���� ���������� ���������     (default=(0.2,0.2,0.2,1))}
//      diff := DiffDef; {���� ���������� ���������     (default=(0.8,0.8,0.8,1))}
//      spec := SpecDef; {���� ����������� ���������    (default=(0.1,0.1,0.1,1))}
//      emis := EmisDef; {���� ���������                (default=(0.0,0.0,0.0,1))}
//      tran := 0;    {������� ������������          (default=0)}
//      shin := 0;    {������� ����������� ��������� (default=0)}
      lb   := FALSE;  {������� �����������}
      if Nmater = (Nmat+1) then dec(Nmater); {��� ����������� ��������� ������� �������}
      if FirstEmpMat > Nmat then FirstEmpMat := Nmat;
//      if ToFile then begin
//        writeln(t,'    DeleteMaterial: Nmat=',Nmat,' Name=',nm);
//      end;
    end else begin
      deb2file('    **ERROR** DeleteMaterial: '+nm+' Nmat=',Nmat);
//      deb2file('    **ERROR** DeleteMaterial: Name=',nm);
//      if ToFile then
//        writeln(t,'    **ERROR** DeleteMaterial: Nmat=',Nmat,' Name=',nm);
//      if ToErrorFile then
//        writeln(q,'    **ERROR** DeleteMaterial: Nmat=',Nmat,' Name=',nm);
    end;
  end;
end;

procedure PrintStat; {����� � ���� ����������}
var k,kk,i,j : longint;
begin
  if ToFile then begin
    writeln(t,' FilePos:',FilePos,' Points:',npoints,' Faces:',Nfaces);{}
    writeln(t,'������=',Npoints,' ������=',Nfaces,' ����������=',Nmater,' ��������:',Nobj3DS,
        ' ������-��=',NmatObj,' ������ � ���:',NfaceMat,' ����-����=',NtextC);
    writeln(t,' ����.������ � �������=',Mpoints,' ����.������ � �������=',Mfaces,
      ' ������� ������=',CurObj3DS,' ������� ��������=',CurMater);
    writeln(t,' ������� �������� �������=',CurMatObj,' ���������� ����������� ������=',NumChunkRead);
//    writeln(t,' ������ ��������� ������=',FirstEmpObj,' ������ ��������� ��������=',FirstEmpMat,' ������ ��������� �������� �������=',FirstEmpMO);
    writeln(t,'   --- Objects ---');
  end; {if ToFile}
  if Nobj3DS > 0 then
    for k := 0 to Nobj3DS-1 do
      with Obj3DS[k] do begin
        if ToFile then begin
          writeln(t,'Obj=',k:3,' nv=',nv:6,' nf=',nf:6,' nfm=',nfm:6,' nt=',nt:6,' m0=',m0:4,' m1=',m1:4,
               ' lb=',lb,' parent=',parent:3,' nm=',nm);
          writeln(t,'TrMatrix:  ',tm[0,0]:7:3,tm[0,1]:7:3,tm[0,2]:7:3,tm[0,3]:7:3,'    pv =',dword(pv):10);
          writeln(t,'TrMatrix:  ',tm[1,0]:7:3,tm[1,1]:7:3,tm[1,2]:7:3,tm[1,3]:7:3,'    pf =',dword(pf):10);
          writeln(t,'TrMatrix:  ',tm[2,0]:7:3,tm[2,1]:7:3,tm[2,2]:7:3,tm[2,3]:7:3,'    pff=',dword(pff):10);
          writeln(t,'TrMatrix:  ',tm[3,0]:7:3,tm[3,1]:7:3,tm[3,2]:7:3,tm[3,3]:7:3,'    pfg=',dword(pfg):10);
          writeln(t,'RotCenter: ',cr.X:7:3,cr.Y:7:3,cr.Z:7:3,              '           pt =',dword(pt):10);
          writeln(t,'RotAxe:    ',ar.X:7:3,ar.Y:7:3,ar.Z:7:3);
          writeln(t,'    ������: ',nf,' Range: X=(',MiX:8:2,':',MaX:8:2,
              ') Y=(',MiY:8:2,':',MaY:8:2,') Z=(',MiZ:8:2,':',MaZ:8:2,')');
        end; {if ToFile}
        kk := m0;
        while kk <> -1 do
          with MatObj[kk] do begin
{!!!}{�������������� ���������� - �� ���������}
            xi := 1.e36;   xa := -1.e36;
            yi := 1.e36;   ya := -1.e36;
            zi := 1.e36;   za := -1.e36;
            for i := 0 to nf-1 do begin
              j := pf^[i]; {����� ����� � ������� Obj3DS.pf}
              with Obj3DS[io] do begin
                if xa < pv^[pf^[j][1]].x then xa := pv^[pf^[j][1]].x;
                if xa < pv^[pf^[j][2]].x then xa := pv^[pf^[j][2]].x;
                if xa < pv^[pf^[j][3]].x then xa := pv^[pf^[j][3]].x;
                if xi > pv^[pf^[j][1]].x then xi := pv^[pf^[j][1]].x;
                if xi > pv^[pf^[j][2]].x then xi := pv^[pf^[j][2]].x;
                if xi > pv^[pf^[j][3]].x then xi := pv^[pf^[j][3]].x;
                if ya < pv^[pf^[j][1]].y then ya := pv^[pf^[j][1]].y;
                if ya < pv^[pf^[j][2]].y then ya := pv^[pf^[j][2]].y;
                if ya < pv^[pf^[j][3]].y then ya := pv^[pf^[j][3]].y;
                if yi > pv^[pf^[j][1]].y then yi := pv^[pf^[j][1]].y;
                if yi > pv^[pf^[j][2]].y then yi := pv^[pf^[j][2]].y;
                if yi > pv^[pf^[j][3]].y then yi := pv^[pf^[j][3]].y;
                if za < pv^[pf^[j][1]].z then za := pv^[pf^[j][1]].z;
                if za < pv^[pf^[j][2]].z then za := pv^[pf^[j][2]].z;
                if za < pv^[pf^[j][3]].z then za := pv^[pf^[j][3]].z;
                if zi > pv^[pf^[j][1]].z then zi := pv^[pf^[j][1]].z;
                if zi > pv^[pf^[j][2]].z then zi := pv^[pf^[j][2]].z;
                if zi > pv^[pf^[j][3]].z then zi := pv^[pf^[j][3]].z;
              end;
            end;
            x0 := (xi + xa)/2.;
            y0 := (yi + ya)/2.;
            z0 := (zi + za)/2.;
            if ToFile then begin
              writeln(t,'       Material: ',kk:3,' pr:',pr:3,' nx:',nx:3
                     {,' io:',io,' im:',im:3,' f0:',f0,' f1:',f1,' ',nm});
              writeln(t,'    ������: ',nf,' Range: X=(',xi:8:2,':',xa:8:2,
                  ') Y=(',yi:8:2,':',ya:8:2,') Z=(',zi:8:2,':',za:8:2,') Center: ',
                   x0:8:2,y0:8:2,z0:8:2);
            end;
            kk := nx;
          end;
      end; {with}
  if ToFile then
    writeln(t,'   --- Materials ---');
  if Nmater >= 0 then
    for k := 0 to Nmater-1 do
      with Material[k] do begin
{!!!}{�������������� ���������� - �� ���������}
//            tran := 0.7;
{!!!}   ambi.a := 1.0 - tran;
{!!!}   diff.a := 1.0 - tran;
        if ToFile then begin
          writeln(t,'Mat=',k:3,' Texture:',dx,'x',dy,'x',bp,' TexPerc=',texp:5:3,' ',nm,' (',nt,')');
          writeln(t,'     Ambient  : ',ambi.r:6:3,ambi.g:6:3,ambi.b:6:3,ambi.a:6:3,'     lb         = ',lb);
          writeln(t,'     Diffuse  : ',diff.r:6:3,diff.g:6:3,diff.b:6:3,diff.a:6:3,'     tran       = ',tran:5:3);
          writeln(t,'     Specular : ',spec.r:6:3,spec.g:6:3,spec.b:6:3,spec.a:6:3,'     Shin       = ',shin:5:3);
          writeln(t,'     Emission : ',emis.r:6:3,emis.g:6:3,emis.b:6:3,emis.a:6:3,'     Pointer pt = ',dword(pt):10);
        end;
      end;
  if ToFile then begin
    writeln(t,'   --- Materials of Objects ---');
    if NmatObj > 0 then begin
      writeln(t,' MO pr nx io im   nf     lb  nvn ntf ptr: pf  pvf       pvn ptf  flags: fl0    fl1    name');
      for kk := 0 to NmatObj-1 do
        with MatObj[kk] do
          writeln(t,kk:3,pr:3,nx:3,io:3,im:3,nf:8,lb:5,nvn:4,ntf:4,dword(pf):10,
                dword(pvf):4,dword(pvn):4,dword(ptf):4,w2b(fl0),' ',w2b(fl1),' ',nm);
{          writeln(t,'MO=',kk:3,' pr:',pr:3,' nx:',nx:3,' io:',io:3,' im:',im:3,' nf:',nf:8,
                ' lb:',lb:5,' nvn:',nvn:4,' ntf:',ntf:4,' Pointers: pf=',dword(pf):10,
                ' pvf=',dword(pvf):4,' pvn=',dword(pvn):4,' ptf=',dword(ptf):4,
                ' flags: ',w2b(fl0),' ',w2b(fl1),' ',nm);{}
    end;
    writeln(t,'   --- Object Animation ---');
    for k := 0 to Nobj3DS-1 do
      if Obj3DS[k].parent <> -1 then
         writeln(t,' Object No ',k:3,' ',Obj3DS[k].nm,' has parent: ',Obj3DS[Obj3DS[k].parent].nm)
      else
         writeln(t,' Object No ',k:3,' ',Obj3DS[k].nm,' has no parent');
 {Obj3DS[TrackObj[i].Main].parent = TrackObj[TrackObj[i].parent].Main  ???}
  end;
end;

procedure DeleteAllObjMat; {����������� ���� �������� � ����������}
var i : longint;
begin
{������������� ���������� ������������ �����}
  deb2file('DeleteAllObjMat begin ',0);
  if Nobj3DS > 0 then
    for i := 0 to Nobj3DS-1 do
       DeleteObj3DS(i);
  deb2file('DeleteAllObjMat ',1);
  if Nmater > 0 then
    for i := 0 to Nmater-1 do
       DeleteMaterial(i);
  deb2file('DeleteAllObjMat ',2);

  NObj3DS := 0;                   {���������� ��������}
  Nmater  := 0;                   {���������� ����������}
  NmatObj := 0;                   {���������� ���������� ��������}

  Npoints     := 0;    {��� ����������: ����� ���������� ������}
  Nfaces      := 0;    {��� ����������: ����� ���������� ������}
  NfaceMat    := 0;    {��� ����������: ����� ���������� ������ � �����������}
  NtextC      := 0;    {��� ����������: ����� ���������� ���������� ���������}
  Mpoints     := 0;    {��� ����������: ������������ ���������� ������ � ����� �������}
  Mfaces      := 0;    {��� ����������: ������������ ���������� ������ � ����� �������}

  CurObj3DS := -1;                   {����� �������� �������}
  CurMater  := -1;                   {����� �������� ���������}
  CurMatObj := -1;                   {����� �������� ��������� ��������}
  FirstEmpObj := 0;                     {������ ��������� ������ (��� ������ �� �������)}
  FirstEmpMat := 0;                     {������ ��������� �������� (��� ������ �� �������)}
  FirstEmpMO  := 0;                     {������ ��������� �������� ������� (��� ������ �� �������)}
  deb2file('DeleteAllObjMat ',3);
  fillchar(Obj3DS,sizeof(Obj3DS),0);      {������ ��������}
  fillchar(Material,sizeof(Material),0);  {������ ����������}
  fillchar(MatObj,sizeof(MatObj),0);      {������ ���������� ��������}

  FirstEmpObj   := 0;             {������ ��������� ������ (��� ������ �� �������)}
  FirstEmpMat   := 0;             {������ ��������� �������� (��� ������ �� �������)}
  FirstEmpMO    := 0;             {������ ��������� �������� ������� (��� ������ �� �������)}
  deb2file('DeleteAllObjMat ',4);
  if DebFileOpened then begin
    if ToErrorFile then
      close(q);
    if ToFile then
      close(t);
    DebFileOpened := FALSE;
  end;
  deb2file('DeleteAllObjMat end ',5);
end;

var
  ExitSave : Pointer;       {����� ������ ��������� ������ � DOS }

procedure MyExit;  { �������������� ��������� ��� ������ � DOS }
var i : longint;
begin
  ExitProc:=ExitSave;
  deb2file('Comm_3D ���������������  ',0);
  DeleteAllObjMat;
//  ChangeListMode{(0)}; {��������� ������ ������� ���������}
end;

begin
  deb2file('Comm_3D  * ������������� sizeof(Obj3DS)  = ',sizeof(Obj3DS));
  deb2file('Comm_3D  * ������������� sizeof(Material)= ',sizeof(Material));
  deb2file('Comm_3D  * ������������� sizeof(MatObj)  = ',sizeof(MatObj));
  ExitSave:=ExitProc;  {��������������� ��������� ������}
  ExitProc:=@MyExit;
  NObj3DS := 0;                   {���������� ��������}
  Nmater  := 0;                   {���������� ����������}
  NmatObj := 0;                   {���������� ���������� ��������}
  DeleteAllObjMat; {����������� ���� �������� � ����������}
//  ChangeListMode{(0)}; {��������� ������ ������� ���������}
end.