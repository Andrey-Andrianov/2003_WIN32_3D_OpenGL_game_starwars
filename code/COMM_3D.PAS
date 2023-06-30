unit comm_3d;{общие типы, константы и процедуры по работе с 3D-объектами}
interface
uses matrx_wd;

const
  MaxPoints   = 65536*2;{x(12+8)  64K vertecles = 0.75 Mb in file/ 2.25 Mb in memory}
  MaxFaces    = 65536*4;{x(12+)  64K faces = 512 K in file/ 0.75 Mb in memory}
  MaxMat      = 1024;   { *260 макс кол-во материалов в сцене}
  MaxMatObj   = 1024;   { *176 макс. кол-во материалов, привязанных к объектам}
  MaxObj      = 1024;   { *248 макс. кол-во объектов}
  ToFile      : boolean = FALSE;   {вести ли запись протокола в файл}
  ToErrorFile : boolean = FALSE; {вести ли запись протокола в файл ошибок}
  ListMode    : longint = 4;
  ListModeOld : longint = 4;
  DefMaterial = 'Default Material'; {имя материала по умолчанию - для моделей без описаний материала}
  MaxValue    = 32768; {максимальное значение, которое могут принимать координаты}
  DebFileOpened : boolean = FALSE; {открыты ли файлы для протокола}
  Distance      : single = 40; {расстояние до камеры (вычисляется, исходя из размеров объекта)}
Type
  TRealVector = Record          {вектор - 12 байт}
    X,Y,Z : single;
  End;
  TtextC = record               {текстурные координаты (8 bytes)}
    u,v : single;
  end;
  ColorType = record    {цвет для характеристик материала OprnGL}
    r,g,b,a : single; {цветовые составляющие и прозрачность (16 bytes)}
  end;
  FaceType      = Array[1..3] of longint;       { 12 bytes номера вершин в грани}
  FaceType2     = Array[1..4] of word; { 8 bytes номера вершин в грани (для чтения) + флаги}
//  MatriXtype    = array[0..3,0..3]of single;           { 64 bytes матрица 4х4}
  VectArrayType = Array[0..MaxPoints-1]of TRealVector;  { *12 }
  FaceArrayType = Array[0..MaxFaces-1]of FaceType;      { *12 }
  FaceArrayType2= Array[0..MaxFaces-1]of FaceType2;     { *6 }
  TextArrayType = Array[0..MaxPoints-1]of TtextC;       { *8 }
  FaceWordType  = Array[0..MaxFaces-1]of word;          { *4 }
  FaceLongType  = Array[0..MaxFaces-1]of longint;       { *8 }
  NameStr       = string[79];                           { *80 }
  Tobj3DS = record {предварительный объект (80+48+128+32+24=312 bytes)}
    nm    : NameStr;        {80 название}
    pv    : ^VectArrayType; { 4 (nv) массив вершин}
    nv    : longint;        { 4 количество вершин для данного объекта, а текже текст.коорд}
    pf    : ^FaceArrayType; { 4 (nf) массив граней}
    pff   : ^FaceWordType;  { 4 (nf) массив флагов граней}
    pfg   : ^FaceLongType;  { 4 (nf) массив групп сглаживания граней}
    nf    : longint;        { 4 количество граней}
    nfm   : longint;        { 4 количество граней с материалами}
    pt    : ^TextArrayType; { 4 (nv ?) массив текстурных координат}
    nt    : longint;        { 4 количество текстурных координат}
    parent: longint;        { 4 объект-родитель}
    m0,m1 : longint;        { 8 индексы головы и хвоста списка материалов в массиве MatObj}
    tm    : MatrixType;     {128 -/ 64 матрица преобразования}
    cr    : TRealVector;    {12 центр вращения (из блока анимации)}
    ar    : TRealVector;    {12 ось вращения (из блока анимации)}
    lb    : longbool;       { 4 признак присутствия}
    vz    : longbool;       { 4 признак того, что следует отображать на экран}
    MaX,MiX,MaY,MiY,MaZ,MiZ : single; {24 границы объекта}
  end;
  Tmaterial = record {описание материалов, используемых в сцене (160+20+64+12+4=260)}
    nm    : Namestr;   {80 название материала ()}
    nt    : Namestr;   {80 имя файла текстуры   }
    dx,dy : longint;   { 8 размеры текстуры     }
    bp    : longint;   { 4 глубина цвета текстуры, байт: 1,3,4}
    texp  : single;    { 4 процент текстуры}
    pt    : pointer;   { 4 указатель на массив с текстурой}
    ambi  : ColorType; {16 цвет рассеяного отражения     (default=(0.2,0.2,0.2,1))}
    diff  : ColorType; {16 цвет диффузного отражения     (default=(0.8,0.8,0.8,1))}
    spec  : ColorType; {16 цвет зеркального отражения    (default=(0.1,0.1,0.1,1))}
    emis  : ColorType; {16 цвет излучения                (default=(0.0,0.0,0.0,1))}
    tran  : single;    { 4 степень прозрачности          (default=0)}
    shin  : single;    { 4 степень зеркального отражения (default=0)}
    lb    : longbool;  { 4 признак присутствия}
   {--------дополнительные поля-------------------------}
    dlst  : longint;   { 4 дисплейный лист для текстуры}
  end;
  TmatObj = record {описание материалов конкретного объекта  (80+36+24+36=176)}
    nm    : Namestr; {80 название материала}
    pr,nx : longint; { 8 индексы предыдущего и последующих материалов в списке в массиве MatObj}
    io    : longint; { 4 4номер объекта, которому приписан материал}
    im    : longint; { 4 номер материала в массиве Material}
    pf    : ^FaceLongType; { 4 (nf<Obj.nf) номера граней для данного материала в массиве Obj3DS.pf}
    nf    : longint; { 4 количество граней для данного материала в массиве FaceMat}
    lb    : longbool;{ 4 признак присутствия}
    fl0,fl1:word; { 8 флаги материала}
    xi,xa,x0,yi,ya,y0,zi,za,z0 : single; {36 минимальные, максимальные и средние координаты}
   {--------дополнительные поля-------------------------}
    pvf   : ^VectArrayType; { 4 массив вершин, упорядоченный для отображения}
    pvn   : ^VectArrayType; { 4 массив нормалей (к вершинам), упорядоченный для отображения}
    pnf   : ^VectArrayType; { 4 массив <плоских> нормалей (к граням), упорядоченный для отображения}
    nvn   : longint;        { 4 размер массивов вершин и нормалей}
    ptf   : ^TextArrayType; { 4 массив текстурных координат, упорядоченный для отображения}
    ntf   : longint;        { 4 количество текстурных координат}
  end;
var
  f             : file;                      {файл .3DS}
  lf            : longint;                   {длина файла}
  FilePos       : longint;                   {позиция в файле}
  Obj3DS      : Array[0..MaxObj-1]of Tobj3DS;    {массив объектов}
  NObj3DS     : longint;                         {количество объектов (номер последней занятой ячейки+1)}
  Material    : Array[0..MaxMat-1]of Tmaterial;  {массив материалов}
  Nmater      : longint;                         {количество материалов (номер послед.занятой ячейки+1)}
  MatObj      : Array[0..MaxMatObj-1]of TmatObj; {массив материалов объектов}
  NmatObj     : longint;                         {количество материалов объектов (номер посл.зан.ячейки+1)}
  Npoints     : longint; {для статистики: общее количество вершин}
  Nfaces      : longint; {для статистики: общее количество граней}
  NfaceMat    : longint; {для статистики: общее количество граней с материалами}
  NtextC      : longint; {для статистики: общее количество текстурных координат}
  Mpoints     : longint; {для статистики: максимальное количество вершин в одном объекте}
  Mfaces      : longint; {для статистики: максимальное количество граней в одном объекте}
  t             : text;                        {файл протокола}
  q             : text;                        {файл протокола ошибок}
  CurObj3DS     : longint;                   {номер текущего объекта}
  CurMater      : longint;                   {номер текущего материала}
  CurMatObj     : longint;                   {номер текущего материала объектов}
  FnameInput    : string;                    {имя 3DS-файла }
  FnameReport   : string;                    {имя файла протокола}
  FnameError    : string;                    {имя файла для сообщений об ошибках}
  NumChunkRead  : longint;                   {количество чанков, прочитанных программой}

function Hex2str(w:word):string; { word -> string(hex)}
function l2str(l:longint):Namestr; { longint -> string(hex)}
function w2b(w:word):NameStr;  { word -> string(bin)}
//procedure ChangeListMode{(mode:longint)}; {изменение режима ведения протокола}
function FindObj3DS(s : string) : longint; {поиск номера объекта по имени}
function FindMatObj(s : string; Nobj : longint) : longint; {поиск номера материала объекта по имени}
function FindMaterial(s : string) : longint; {поиск номера материала по имени}
procedure CreateMatObj(Nobj,CountL : longint; name : NameStr); {создание материала объекта}
                    {Nobj - номер объекта, CountL - количество граней данного материала}
procedure DeleteMatObj(Nmat : longint); {уничтожение материала объекта}
function CreateObj3DS(name : NameStr) : longint; {создание объекта (возвр. номер объекта)}
procedure DeleteObj3DS(Nobj : longint); {уничтожение объекта}
procedure CreateMaterial(name : NameStr); {создание материала}
procedure DeleteMaterial(Nmat : longint); {уничтожение материала}
procedure DeleteAllObjMat; {уничтожение всех объектов и материалов}
procedure PrintStat; {вывод в файл статистики}

implementation

uses deb_as;

var
  FirstEmpObj   : longint;                     {первый свободный объект (для работы со списком)}
  FirstEmpMat   : longint;                     {первый свободный материал (для работы со списком)}
  FirstEmpMO    : longint;                     {первый свободный материал объекта (для работы со списком)}
//  NobjAter    : longint; {номер в массиве объектов, ниже которого все ячейки заполнены}
//  NmatAter    : longint; {номер в массиве материалов, ниже которого все ячейки заполнены}
//  NmatObjAter : longint; {номер в массиве материалов объектов, ниже которого все ячейки заполнены}
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

//procedure ChangeListMode{(mode:longint)}; {изменение режима ведения протокола}
{begin
  deb2file('ChangeListMode OldMode: ',ListModeOld);
  deb2file('ChangeListMode FileReport: '+FnameReport+' ',0);
  deb2file('ChangeListMode ToFile: ',longint(ToFile));
  deb2file('ChangeListMode FileError: '+FnameError+' ',0);
  deb2file('ChangeListMode ToErrorFile: ',longint(ToErrorFile));
  deb2file('ChangeListMode NewMode: ',ListMode);
  if (ListModeOld and 1) = 1 then {протокол}
{    if ToFile then begin
      deb2file('ChangeListMode Close(r): '+FnameReport+' ',longint(ToFile));
      writeln(t,' Close file, New filename: ',FnameReport);
      close(t);
    end;
  if (ListModeOld and 2) = 2 then {ошибки}
{    if ToErrorFile then begin
      deb2file('ChangeListMode Close(e): '+FnameError+' ',longint(ToErrorFile));
      writeln(t,' Close file, New filename: ',FnameError);
      close(q);
    end;
  ListModeOld := ListMode;
  if ((ListMode and 1) = 1) and (FnameReport <> '') then begin{протокол}
{    deb2file('ChangeListMode Open(r): '+FnameReport+' ',longint(ToFile));
    assign(t,FnameReport);
    rewrite(t);
    writeln(t,'ChangeListMode Mode: ',ListMode);
    ToFile := TRUE;
  end else
    ToFile := FALSE;
  if ((ListMode and 2) = 2) and (FnameError <> '') then begin{протокол}
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

function FindObj3DS(s : string) : longint; {поиск номера объекта по имени}
var n,i : longint;
begin
  n := -1;
  for i := 0 to Nobj3DS - 1 do
    if Obj3DS[i].nm = s then
      n := i;
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindObj3DS объекта: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindObj3DS объекта: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   Найден объект ',n,' по имени ',s);
  FindObj3DS := n;
end;

function FindMatObj(s : string; Nobj : longint) : longint; {поиск номера материала объекта по имени}
var n,i : longint;
begin
  n := -1;
  i := Obj3DS[NObj].m0;
  repeat {поиск материала объекта по имени}
    if s = MatObj[i].nm then
       n := i;
    i := MatObj[i].nx;
  until (i = -1);
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindMatObj материал объекта ',Nobj,' Imo: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindMatObj материал объекта ',Nobj,' Imo: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   Найден материал объекта ',Nobj,' NumMatObj: ',n,' по имени ',s);
  FindMatObj := n;
end;

function FindMaterial(s : string) : longint; {поиск номера материала по имени}
var n,i : longint;
begin
  n := -1;
  for i := 0 to Nmater-1 do {поиск материала по имени}
    if s = Material[i].nm then
      n := i;
  if n = -1 then begin
    if ToFile then
      writeln(t,' ERROR! FindMaterial материал: ',n,' name: ',s);
    if ToErrorFile then
      writeln(q,' ERROR! FindMaterial материал: ',n,' name: ',s);
  end;
  if ToFile then
    writeln(t,'   Найден материал ',n,' по имени ',s);
  FindMaterial := n;
end;

procedure CreateMatObj(Nobj,CountL : longint; name : NameStr); {создание материала объекта}
var i : longint; {Nobj - номер объекта, CountL - количество граней данного материала}
begin
  while MatObj[FirstEmpMO].lb and (FirstEmpMO < MaxMatObj) do inc(FirstEmpMO); {ищем свободное место}
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
      nm := name; {название материала}
      pr := Obj3DS[Nobj].m1; {индекс последнего материала в списке в массиве MatObj}
      if pr = -1 then begin {первый материал в цепочке}
        Obj3DS[Nobj].m0 := CurMatObj;
      end else begin                     {последующий материал в цепочке}
        MatObj[pr].nx := CurMatObj;
      end;
      Obj3DS[Nobj].m1 := CurMatObj;
      nx := -1; {индекс последующего материала в списке в массиве MatObj}
      io := Nobj; {номер объекта, которому приписан материал}
      im := -1; {номер материала в массиве Material}
      for i := 0 to Nmater-1 do
         if Material[i].nm = name then
           im := i;
      if im = -1 then begin
        if ToFile then
           writeln(t,'    CreateMatObj ERROR: Material ',name,' not found');
        if ToErrorFile then
           writeln(q,'    CreateMatObj ERROR: Material ',name,' not found',' Nobj=',Nobj,' CountL=',CountL);
      end;
      pf := nil; {массив граней для данного материала в массиве FaceMat}
      if CountL > 0 then
        getmemF(pf,CountL*sizeof(longint),'r3:CrMO');
      nf  := CountL;   {количество граней для данного материала в массиве FaceMat}
      lb  := TRUE;     {признак присутствия}
      fl0 := 0;      {флаги материала}
      fl1 := $ffff;  {флаги материала}
      pvf := nil;    {массив вершин, упорядоченный для отображения}
      pvn := nil;    {массив нормалей, упорядоченный для отображения}
      nvn := 0;        {размер массивов вершин и нормалей}
      ptf := nil;    {массив текстурных координат, упорядоченный для отображения}
      ntf := 0;        {количество текстурных координат}
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

procedure DeleteMatObj(Nmat : longint); {уничтожение материала объекта}
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
        if NmatObj = (Nmat+1) then dec(NmatObj); {при возможности уменьшаем верхнюю границу}
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

function CreateObj3DS(name : NameStr) : longint; {создание объекта (возвр. номер объекта)}
const DefMatr : MatrixType = ((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));
begin
  while Obj3DS[FirstEmpObj].lb and (FirstEmpObj < MaxObj) do inc(FirstEmpObj); {ищем свободное место}
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
      nm     := name;    {название}
      pv     := nil;     {массив вершин}
      nv     := 0;       {количество вершин для данного объекта, а текже текст.коорд}
      pf     := nil;     {массив граней}
      pff    := nil;     {массив флагов граней}
      pfg    := nil;     {массив групп сглаживания граней}
      nf     := 0;       {количество граней}
      nfm    := 0;       {количество граней с материалами}
      pt     := nil;     {массив текстурных координат}
      nt     := 0;       {количество текстурных координат}
      parent := -1;      {объект-родитель}
      m0     := -1;      {индексы головы и хвоста списка материалов в массиве MatObj}
      m1     := -1;      {индексы головы и хвоста списка материалов в массиве MatObj}
      tm     := DefMatr; {матрица преобразования}
      cr.X := 0;   cr.Y := 0;   cr.Z := 0; {центр вращения (из блока анимации)}
      ar.X := 1;   ar.Y := 0;   ar.Z := 0; {ось вращения (из блока анимации)}
      lb     := TRUE;    {признак присутствия}
      vz     := TRUE;    {признак отображения}
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

procedure DeleteObj3DS(Nobj : longint); {уничтожение объекта}
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
        if Nobj3DS = (Nobj+1) then dec(Nobj3DS); {при возможности уменьшаем верхнюю границу}
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

procedure CreateMaterial(name : NameStr); {создание материала}
const AmbiDef : ColorType = (r : 0.2;  g : 0.2;  b : 0.2;  a : 1.0);
      DiffDef : ColorType = (r : 0.8;  g : 0.8;  b : 0.8;  a : 1.0);
      SpecDef : ColorType = (r : 0.1;  g : 0.1;  b : 0.1;  a : 1.0);
      EmisDef : ColorType = (r : 0.0;  g : 0.0;  b : 0.0;  a : 1.0);
begin
  while Material[FirstEmpMat].lb and (FirstEmpMat < MaxMat) do inc(FirstEmpMat); {ищем свободное место}
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
      nm   := name;      {название материала ()}
      nt   := '';   {имя файла текстуры   }
      dx   := 0;   {размеры текстуры     }
      dy   := 0;   {размеры текстуры     }
      bp   := 0;   {глубина цвета текстуры}
      pt   := nil; {указатель на массив с текстурой}
      ambi := AmbiDef; {цвет рассеяного отражения     (default=(0.2,0.2,0.2,1))}
      diff := DiffDef; {цвет диффузного отражения     (default=(0.8,0.8,0.8,1))}
      spec := SpecDef; {цвет зеркального отражения    (default=(0.1,0.1,0.1,1))}
      emis := EmisDef; {цвет излучения                (default=(0.0,0.0,0.0,1))}
      tran := 0;       {степень прозрачности          (default=0)}
      shin := 0.1;       {степень зеркального отражения (default=0)}
      lb   := TRUE;  {признак присутствия}
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

procedure DeleteMaterial(Nmat : longint); {уничтожение материала}
begin
  with Material[Nmat] do begin
    if lb then begin
//      nm   := name;      {название материала ()}
//      nt   := '';   {имя файла текстуры   }
      if pt <> nil then begin freememF(pt,dx*dy*bp,'DelMater');  pt  := nil;  end;
      dx   := 0;   {размеры текстуры     }
      dy   := 0;   {размеры текстуры     }
      bp   := 0;   {глубина цвета текстуры}
//      ambi := AmbiDef; {цвет рассеяного отражения     (default=(0.2,0.2,0.2,1))}
//      diff := DiffDef; {цвет диффузного отражения     (default=(0.8,0.8,0.8,1))}
//      spec := SpecDef; {цвет зеркального отражения    (default=(0.1,0.1,0.1,1))}
//      emis := EmisDef; {цвет излучения                (default=(0.0,0.0,0.0,1))}
//      tran := 0;    {степень прозрачности          (default=0)}
//      shin := 0;    {степень зеркального отражения (default=0)}
      lb   := FALSE;  {признак присутствия}
      if Nmater = (Nmat+1) then dec(Nmater); {при возможности уменьшаем верхнюю границу}
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

procedure PrintStat; {вывод в файл статистики}
var k,kk,i,j : longint;
begin
  if ToFile then begin
    writeln(t,' FilePos:',FilePos,' Points:',npoints,' Faces:',Nfaces);{}
    writeln(t,'вершин=',Npoints,' граней=',Nfaces,' материалов=',Nmater,' объектов:',Nobj3DS,
        ' матерл-об=',NmatObj,' граней с мат:',NfaceMat,' ткст-коор=',NtextC);
    writeln(t,' макс.вершин в объекте=',Mpoints,' макс.граней в объекте=',Mfaces,
      ' текущий объект=',CurObj3DS,' текущий материал=',CurMater);
    writeln(t,' текущий материал объекта=',CurMatObj,' количество прочитанных чанков=',NumChunkRead);
//    writeln(t,' первый свободный объект=',FirstEmpObj,' первый свободный материал=',FirstEmpMat,' первый свободный материал объекта=',FirstEmpMO);
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
          writeln(t,'    граней: ',nf,' Range: X=(',MiX:8:2,':',MaX:8:2,
              ') Y=(',MiY:8:2,':',MaY:8:2,') Z=(',MiZ:8:2,':',MaZ:8:2,')');
        end; {if ToFile}
        kk := m0;
        while kk <> -1 do
          with MatObj[kk] do begin
{!!!}{дополнительные вычисления - не отключать}
            xi := 1.e36;   xa := -1.e36;
            yi := 1.e36;   ya := -1.e36;
            zi := 1.e36;   za := -1.e36;
            for i := 0 to nf-1 do begin
              j := pf^[i]; {номер грани в массиве Obj3DS.pf}
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
              writeln(t,'    граней: ',nf,' Range: X=(',xi:8:2,':',xa:8:2,
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
{!!!}{дополнительные вычисления - не отключать}
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

procedure DeleteAllObjMat; {уничтожение всех объектов и материалов}
var i : longint;
begin
{инициализация переменных интерфейсной части}
  deb2file('DeleteAllObjMat begin ',0);
  if Nobj3DS > 0 then
    for i := 0 to Nobj3DS-1 do
       DeleteObj3DS(i);
  deb2file('DeleteAllObjMat ',1);
  if Nmater > 0 then
    for i := 0 to Nmater-1 do
       DeleteMaterial(i);
  deb2file('DeleteAllObjMat ',2);

  NObj3DS := 0;                   {количество объектов}
  Nmater  := 0;                   {количество материалов}
  NmatObj := 0;                   {количество материалов объектов}

  Npoints     := 0;    {для статистики: общее количество вершин}
  Nfaces      := 0;    {для статистики: общее количество граней}
  NfaceMat    := 0;    {для статистики: общее количество граней с материалами}
  NtextC      := 0;    {для статистики: общее количество текстурных координат}
  Mpoints     := 0;    {для статистики: максимальное количество вершин в одном объекте}
  Mfaces      := 0;    {для статистики: максимальное количество граней в одном объекте}

  CurObj3DS := -1;                   {номер текущего объекта}
  CurMater  := -1;                   {номер текущего материала}
  CurMatObj := -1;                   {номер текущего материала объектов}
  FirstEmpObj := 0;                     {первый свободный объект (для работы со списком)}
  FirstEmpMat := 0;                     {первый свободный материал (для работы со списком)}
  FirstEmpMO  := 0;                     {первый свободный материал объекта (для работы со списком)}
  deb2file('DeleteAllObjMat ',3);
  fillchar(Obj3DS,sizeof(Obj3DS),0);      {массив объектов}
  fillchar(Material,sizeof(Material),0);  {массив материалов}
  fillchar(MatObj,sizeof(MatObj),0);      {массив материалов объектов}

  FirstEmpObj   := 0;             {первый свободный объект (для работы со списком)}
  FirstEmpMat   := 0;             {первый свободный материал (для работы со списком)}
  FirstEmpMO    := 0;             {первый свободный материал объекта (для работы со списком)}
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
  ExitSave : Pointer;       {адрес старой программы выхода в DOS }

procedure MyExit;  { дополнительная процедура при выходе в DOS }
var i : longint;
begin
  ExitProc:=ExitSave;
  deb2file('Comm_3D Деинициализация  ',0);
  DeleteAllObjMat;
//  ChangeListMode{(0)}; {изменение режима ведения протокола}
end;

begin
  deb2file('Comm_3D  * Инициализация sizeof(Obj3DS)  = ',sizeof(Obj3DS));
  deb2file('Comm_3D  * Инициализация sizeof(Material)= ',sizeof(Material));
  deb2file('Comm_3D  * Инициализация sizeof(MatObj)  = ',sizeof(MatObj));
  ExitSave:=ExitProc;  {переопределение процедуры выхода}
  ExitProc:=@MyExit;
  NObj3DS := 0;                   {количество объектов}
  Nmater  := 0;                   {количество материалов}
  NmatObj := 0;                   {количество материалов объектов}
  DeleteAllObjMat; {уничтожение всех объектов и материалов}
//  ChangeListMode{(0)}; {изменение режима ведения протокола}
end.