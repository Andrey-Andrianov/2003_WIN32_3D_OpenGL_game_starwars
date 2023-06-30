{.X file reader by S. Andrianov 1999-2002 andriano.tsinet.ru}
Unit ReadX; {чтение .X-файла}
interface

procedure ReadXfile(filename:string); {чтение массивов вершин и граней}

implementation
uses windows, messages, deb_as, comm_3d, matrx_wd;

type
  PolyType = record
    b,e : longint;
  end;
  PolyTypeArr = array[0..131071]of PolyType;
var
  s  : string; {основная строка для чтения}
  CurrentChunk,CurrentName : string; {строка с текущим часнком = ChunkStack[NChunkStack-1]}
  ChunkStack,NameStack : array[0..31]of string; {стек чанков и их имен}
  NChunkStack,_NCS : longint;              {указатель вершины стека (и проверка для него)}
  OldChar : char; {предыдущий считанный символ}
  IsFrameBeforeMesh : boolean; {признак, что есть FRAME}
  BndPoly : ^PolyTypeArr; {количество тр-ков в полигоне текущего объекта}
  NBndPoly : longint;                {количество Элементов в массиве LenPoly}

const NewMaterialName : string = 'Material_N_000'; {для материалов без имени}

var {для буферизации чтения}
  buf : array[0..4095]of char; {буфер}
  bufCount : longint;          {счетчик в буфере}
  LenBuf   : longint;          {длина считанного буфера}
  ExtraCount : longint;        {превышение длины файла}

function _GetChar : char; {буферизованное чтение символа}
var c : char;
begin
  if (bufCount >= LenBuf) and (not eof(f)) then begin {дочитываем следующий кусок}
    blockread(f,buf,4096,LenBuf);
    bufCount := 0;
  end;
  if (bufCount < LenBuf) then begin {читаем из буфера}
    c := buf[bufCount];
    inc(bufCount);
    _GetChar := c;
  end else begin                    {добавляем конец строки и скобки}
    inc(ExtraCount);
    if ToFile then
      writeln(t,' !!! GetChar: end of file ExtraCount= ',ExtraCount);
    case ExtraCount of
      1:   _GetChar := #13;
      2:   _GetChar := #10;
      else _GetChar := '}';
    end; {case}
  end;
end;

function GetChar : char; {чтение символа с заменой управляющих пробелами и пропуском комментариев}
var c : char;
begin
  c := _GetChar;
  if (c = '/') or (c = '#') then
    repeat
      c := _GetChar;
      if ToFile then
        write(t,c);
    until {(c = #13) or }(c = #10);
  if c = '{' then inc(_NCS);
  if c = '}' then dec(_NCS);
  if byte(c) < byte(' ') then c := ' ';
  if (c = ',') or (c = ';') then c := ' ';
  OldChar := c;
  GetChar := c;
//  writeln(t,'& ',c);
end;

function GetString : string;
var
  ss : string;
  c : char;
begin
  c := OldChar;
  while c = ' ' do c := GetChar; {пропускаем ведущие пробелы}
  if (c = '{') or (c = '}') then begin
    if c = '{' then begin
      inc(NChunkStack);
    end else begin
      dec(NChunkStack);
    end;
    ss := c;
    c := GetChar;
  end else begin
    ss := '';
    repeat
      ss := ss + c;
      c := GetChar;
    until (c = ' ') or (c = '{') or (c = '}');
  end;
//  if ToFile then
  GetString := ss;
end;

function GetInteger : longint;
var
  c : char;
  i : longint;
begin
  c := OldChar;
  while c = ' ' do c := GetChar; {пропускаем ведущие пробелы}
  i := 0;
  repeat
    i := i*10 + (byte(c) - byte('0'));
    c := GetChar;
  until not (c in ['0'..'9']);
  GetInteger := i;
end;

function GetReal : single;
var
  c : char;
  i : single;
  j : integer;
  ss : string;
begin
  c := OldChar;
  while c = ' ' do c := GetChar; {пропускаем ведущие пробелы}
  ss := '';
  while c in ['.','-','+','0'..'9'] do begin
    ss := ss + c;
    c := GetChar;
  end;
  val(ss,i,j);
  GetReal := i;
end;

procedure SkipChunk;
var
  i : integer;
  c : char;
begin
  i := 1;
  if ToFile then
    write(t,'Skip ');
  repeat
    c := GetChar;
    if c = '{' then begin
      inc(i);
      if ToFile then
        write(t,'{',i);
    end;
    if c = '}' then begin
      dec(i);
      if ToFile then
        write(t,'}',i);
    end;
  until i = 0;
  dec(NChunkStack);
  if ToFile then
    writeln(t,' NChunkStack:',NChunkStack);
  c := GetChar;
end;

{***************************************************}
procedure ReadChunkHeader{(s:string)};{читает заголовок чанка} forward;

procedure DoFrame;
var i : integer;
begin
  if ToFile then
    writeln(t,'DoFrame NChunkStack',NChunkStack);
  CreateObj3DS(CurrentName);
  IsFrameBeforeMesh := TRUE;
  if NChunkStack >= 2 then begin
    if ToFile then
      writeln(t,' DoFile parent: ',NameStack[NChunkStack-2]);

    Obj3DS[CurObj3DS].parent := FindObj3DS(NameStack[NChunkStack-2]); {поиск номера объекта по имени}
    if ToFile then
      writeln(t,' DoFile parent: ',Obj3DS[Obj3DS[CurObj3DS].parent].nm);
  end;
  i := NChunkStack;
  repeat
    ReadChunkHeader;
  until NChunkStack < i;
end;

procedure DoMaterial;
var i : longint;
begin
  CreateMaterial(CurrentName);
  with Material[CurMater] do begin
    ambi.r := GetReal;
    ambi.g := GetReal;
    ambi.b := GetReal;
    ambi.a := GetReal;
    diff := ambi;
    shin := GetReal / 128.0;
    spec.r := GetReal;
    spec.g := GetReal;
    spec.b := GetReal;
    emis.r := GetReal;
    emis.g := GetReal;
    emis.b := GetReal;
  end;
  i := NChunkStack;
  repeat
    ReadChunkHeader;
  until NChunkStack < i;
//  SkipChunk; {!!!!!!!      !!!!!!        !!!!!!!    texture}
end;

procedure DoMesh;
var
  m_1,m_2 : MatrixType;
  Count,Count2,kk,Obj1,Obj2,i,j,k,l1 : longint;
  v : tDoubleVector;
  ps : ^FaceArrayType;
begin
  if ToFile then
    writeln(t,'DoMesh');
  if not IsFrameBeforeMesh then
    CreateObj3DS(CurrentName);
  IsFrameBeforeMesh := FALSE;
{читаем вершины}
  Count := GetInteger;
  if ToFile then
    writeln(t,'DoMesh Verticles Count: ',Count);
  if Count > MaxPoints then begin
    if ToFile then
      writeln(t,'    Слишком много точек: ',Count,' ( Уже есть: ',Npoints,' Максимум: ',MaxPoints,')');
    if ToErrorFile then
      writeln(q,'    Слишком много точек: ',Count,' ( Уже есть: ',Npoints,' Максимум: ',MaxPoints,')');
    halt;
  end;
  if ToFile then
    writeln(t,'DoMesh  вершин: ',Count,' Всего: ',Npoints);
  inc(Npoints,Count);
  if Mpoints < Count then Mpoints := Count;
  with Obj3DS[CurObj3DS] do begin
    nv := Count;
    getmemF(pv,Count*sizeof(TRealVector),'r3:VertL');
    MaX := -1.e36;   MiX := 1.e36;
    MaY := -1.e36;   MiY := 1.e36;
    MaZ := -1.e36;   MiZ := 1.e36;
    m_1 := tm;
    Obj1 := CurObj3DS;
    while Obj3DS[Obj1].parent <> -1 do begin
       Obj1 := Obj3DS[Obj1].parent;
       m_2  := Obj3DS[Obj1].tm;
       m_1  := MulMatrix(m_1,m_2);
    end;
    for kk := 0 to Count - 1 do begin
      v.x := GetReal;
      v.y := GetReal;  {переносим объект по марице}
      v.z := GetReal;
      if ToFile then
        if kk = 0 then
          writeln(t,' first verticle (before tr.): x= ',v.x:12:6,' y= ',v.y:12:6,' z= ',v.z:12:6);
      v := MatrVect(m_1,v);
      if ToFile then
        if kk = 0 then
          writeln(t,' first verticle (after tr. ): x= ',v.x:12:6,' y= ',v.y:12:6,' z= ',v.z:12:6);
      pv^[kk].x := v.x;
      pv^[kk].y := v.y;
      pv^[kk].z := - v.z;{ здесь меняем знак оси Z для отобр OpenGL}
      if pv^[kk].x >  MaxValue then pv^[kk].x :=  MaxValue;
      if pv^[kk].x < -MaxValue then pv^[kk].x := -MaxValue;
      if pv^[kk].y >  MaxValue then pv^[kk].y :=  MaxValue;
      if pv^[kk].y < -MaxValue then pv^[kk].y := -MaxValue;
      if pv^[kk].z >  MaxValue then pv^[kk].z :=  MaxValue;
      if pv^[kk].z < -MaxValue then pv^[kk].z := -MaxValue;
      if MaX < pv^[kk].x then MaX := pv^[kk].x;
      if MiX > pv^[kk].x then MiX := pv^[kk].x;
      if MaY < pv^[kk].y then MaY := pv^[kk].y;
      if MiY > pv^[kk].y then MiY := pv^[kk].y;
      if MaZ < pv^[kk].z then MaZ := pv^[kk].z;
      if MiZ > pv^[kk].z then MiZ := pv^[kk].z;
    end;
    if ToFile then
      writeln(t,'    вершин: ',Count,' Range: X=(',MiX:8:2,':',MaX:8:2,
          ') Y=(',MiY:8:2,':',MaY:8:2,') Z=(',MiZ:8:2,':',MaZ:8:2,')');
  end;
{читаем грани}
{сначала читаем их во временный массив, т.к. не знаем, сколько нужно треуг-ков}
  Count := GetInteger;
  Count2 := 0;
  l1 := 128 * 1024; {макс число граней}
  if (16 * Count) > l1 then l1 := (16 * Count);
  if ToFile then
    writeln(t,'DoMesh Count= ',Count, ' l1= ',l1,' 16Count= ',16*Count);
  getmemF(ps,l1*sizeof(FaceType),'DoMesh Faces TMP');
  for kk := 0 to Count-1 do begin
    i := GetInteger-2; {количество тр-ков в полигоне}
    BndPoly^[kk].b := Count2;    {заполняем массив для использования в DoMatObj}
    ps^ [Count2][1] := GetInteger;
    ps^ [Count2][3] := GetInteger;
    ps^ [Count2][2] := GetInteger;
    j               := ps^ [Count2][1];
    inc(Count2);
    if i > 1 then
      for k := 2 to i do begin
        ps^ [Count2][1] := j;
        ps^ [Count2][3] := ps^ [Count2-1][2];
        ps^ [Count2][2] := GetInteger;
        inc(Count2);
      end;
    BndPoly^[kk].e := Count2-1;    {заполняем массив для использования в DoMatObj}
  end;
  NbndPoly := Count;
  if ToFile then begin
    writeln(t,'DoMesh Count= ',Count, ' Count2= ',Count2);
    writeln(t,'DoMesh last face: ',ps^ [Count2-1][1],' ',ps^ [Count2-1][2],' ',ps^ [Count2-1][3]);
  end;
  if Count2 > l1 then begin
    if ToFile then
      writeln(t,'DoMesh ERROR Count= ',Count, ' Count2= ',Count2,' l1= ',l1);
    if ToErrorFile then
      writeln(q,'DoMesh ERROR Count= ',Count, ' Count2= ',Count2,' l1= ',l1);
  end;
  Count := Count2;
  if Count > MaxFaces then begin
    if ToFile then
      writeln(t,'    Слишком много граней: ',Count,' ( Уже есть: ',Nfaces,' Максимум: ',MaxFaces,')');
    if ToErrorFile then
      writeln(q,'    Слишком много граней: ',Count,' ( Уже есть: ',Nfaces,' Максимум: ',MaxFaces,')');
    halt;
  end;
  inc(Nfaces,Count);
  if Mfaces < Count then Mfaces := Count;
  with Obj3DS[CurObj3DS] do begin
    if Count > 0 then begin
      nf := Count;
      getmemF(pf,Count*sizeof(FaceType),'r3:FacL1');
      getmemF(pff,Count*sizeof(word),'r3:FacL2');
      for kk := 0 to Count-1 do begin
        pf^ [kk] := ps^ [kk];
        if (pf^[kk][1] < 0) or (pf^[kk][1] > (nv-1)) or
           (pf^[kk][2] < 0) or (pf^[kk][2] > (nv-1)) or
           (pf^[kk][3] < 0) or (pf^[kk][3] > (nv-1)) then begin
          if ToFile then
            writeln(t,'    Faces error: Max',nv-1:8,pf^[kk][1]:8,pf^[kk][2]:8,pf^[kk][3]:8);
          if ToErrorFile then
            writeln(q,'    Faces error: Max',nv-1:8,pf^[kk][1]:8,pf^[kk][2]:8,pf^[kk][3]:8);
        end;
      end;
    end; {if Count > 0}
  end;{with}
  freememF(ps,l1*sizeof(FaceType),'DoMesh Faces TMP');
  kk := NChunkStack;
  repeat
    ReadChunkHeader;
  until NChunkStack < kk;
end;

procedure DoTrMatrix;
var i,j : longint;
begin
  if ToFile then
    writeln(t,'DoTrMatrix');
  with Obj3DS[CurObj3DS] do
    for j := 0 to 3 do
      for i := 0 to 3 do
        tm[j,i] := GetReal;
  SkipChunk;
end;

procedure DoMatObj;
type pltype = array[0..0]of longint;
var
  Count,i,j,k,m,NumMO,NF_ : longint;
  pl : ^pltype;
  ss,ss2 : string;

  procedure CreatNewMO;
  begin
{чтение имени (выделение его из фигурных скобок)}
    ss := GetString;
    if ss <> '{' then begin      {материал внутри?}
      if ss = 'Material' then begin       {да!}
        ss := GetString;
        if ss = '{' then begin  {материал без названия}
          inc(byte(NewMaterialName[length(NewMaterialName)]));
          if NewMaterialName[length(NewMaterialName)] = ':' then begin
            inc(byte(NewMaterialName[length(NewMaterialName)-1]));
            NewMaterialName[length(NewMaterialName)] := '0';
          end;
          CurrentName := NewMaterialName;
        end else begin          {матеиал с названием}
          CurrentName := ss;
          ss := GetString;
          if ss <> '{' then begin
            if ToFile then
              writeln(t,'ERROR DoMatObj No { ',ss,' Mat inside');
            if ToErrorFile then
              writeln(q,'ERROR DoMatObj No { ',ss,' Mat inside');
          end;
        end;
        DoMaterial;
        CreateMatObj(CurObj3DS,Count,CurrentName);
      end;
    end else begin
      ss := GetString;
      if ss = '{' then begin
        if ToFile then
          writeln(t,'ERROR DoMatObj No Name',ss);
        if ToErrorFile then
          writeln(q,'ERROR DoMatObj No Name',ss);
      end;
      CreateMatObj(CurObj3DS,Count,ss);
      ss := GetString;
      if ss <> '}' then begin
        if ToFile then
          writeln(t,'ERROR DoMatObj No }',ss);
        if ToErrorFile then
          writeln(q,'ERROR DoMatObj No }',ss);
      end;
    end;
  end;

begin
  NumMO := GetInteger;
  NF_ := GetInteger;
  if (NumMO = 1) and (NF_ = 1) then begin {случай сокр.записи единственного MO}
    GetInteger;
    Count := Obj3DS[CurObj3DS].nf;
    CreatNewMO;
//    CreateMatObj(CurObj3DS,Obj3DS[CurObj3DS].nf,s);
    if ToFile then
      writeln(t,'DoMatObj: single material nf=',Obj3DS[CurObj3DS].nf);
    with Obj3DS[CurObj3DS] do
      nfm := nf;
    for i := 0 to Obj3DS[CurObj3DS].nf-1 do
      MatObj[CurMatObj].pf^[i] := i;
  end else begin                {полный список материалов граней}
    if ToFile then
      writeln(t,'DoMatObj: full list NF_=',NF_);
    getmemF(pl,4*NF_,'rx:DoMatObj'); {временный массив для номеров материалов}
    for i := 0 to NF_-1 do
      pl^[i] := GetInteger;          {заполнение временного массива}
    for j := 0 to NumMO-1 do begin {перебор по MO}
      Count := 0;                  {к-во граней данного материала}
      for i := 0 to NF_-1 do
        if pl^[i] = j then inc(Count,BndPoly^[i].e - BndPoly^[i].b + 1);    {подсчитываем Count}
      CreatNewMO;
{заполнение массива MO}
      k := 0;                             {счетчик массива в MO}
      for i := 0 to NF_-1 do              {заполняем массив в структуре MO}
        if pl^[i] = j then begin
          for m := BndPoly^[i].b to BndPoly^[i].e do begin
            MatObj[CurMatObj].pf^[k] := m;
            inc(k);
          end;
        end;
{*****************************}
      if ToFile then begin
        writeln(t,'Obj3DS[CurObj3DS].nf:)',Obj3DS[CurObj3DS].nf,' NbndPoly:',NbndPoly,
         ' NF_:',NF_,' Count:',Count,' k:',k,' MatObj[CurMatObj].nf:',MatObj[CurMatObj].nf);
        for i := 0 to NF_-1 do
          writeln(t,pl^[i]:6,BndPoly^[i].b:6,BndPoly^[i].e:6);
        for i := 0 to MatObj[CurMatObj].nf-1 do
          writeln(t,MatObj[CurMatObj].pf^[i]:4);
      end;
{*****************************}
    end;
    freememF(pl,4*NF_,'rx:DoMatObj');
  end;
  SkipChunk;
end;

procedure DoTextCoord;
var
  Count : word;
  kk : longint;
  MinU,MinV,MaxU,MaxV : single; {пределы изменения текстурных координат}
begin
//  blockread(f,Count,sizeof(Count));
  Count := GetInteger;
//  CheckChunkLength(2 + longint(Count)*sizeof(TtextC),'Read TextCoord');
  if ToFile then
    writeln(t,'    кол-во текст.координат: ',Count);{}
  inc(NtextC, Count);
  with Obj3DS[CurObj3DS] do begin
    if Count <> nv then begin
      if ToFile then
        writeln(t,'    ERROR: Несовпадение количества вершин и текс.коорд.: nv=:',nv,' nt=',Count);
      if ToFile then
        writeln(t,'    ERROR: Несовпадение количества вершин и текс.коорд.: nv=:',nv,' nt=',Count);
    end;
    nt := Count;
    getmemF(pt,Count*sizeof(TtextC),'rX:TexC');
//    blockread(f,pt^,Count*sizeof(TtextC));
//    if ToFile or ToErrorFile then begin
      MinU := 1000.0;   MinV := 1000.0;   MaxU := -1000.0; MaxV := -1000.0;
      for kk := 0 to Count - 1 do begin
//        pt^[kk].u := 1.0 - GetReal;   { !!! переворачиваем текстуру в DirectX !!!}
   {*}  pt^[kk].u := GetReal;   { !!! переворачиваем текстуру в DirectX !!!}
   {*}  pt^[kk].v := 1.0 - GetReal;   { !!! переворачиваем текстуру в DirectX !!!}
//        pt^[kk].v := GetReal;   { !!! переворачиваем текстуру в DirectX !!!}
        if MinU > pt^[kk].u then MinU := pt^[kk].u;
        if MinV > pt^[kk].v then MinV := pt^[kk].v;
        if MaxU < pt^[kk].u then MaxU := pt^[kk].u;
        if MaxV < pt^[kk].v then MaxV := pt^[kk].v;
      end;
      if ToFile then
        writeln(t,'    текст.коорд. U=(',MinU:5:3,':',MaxU:5:3,') V=(',MinV:5:3,':',MaxV:5:3,')');
      if (MinU < 0) or (MaxU > 1) or (MinV < 0) or (MaxV > 1) then begin
        if ToFile then
          writeln(t,'    ERROR текст.коорд. U=(',MinU:5:3,':',MaxU:5:3,') V=(',MinV:5:3,':',MaxV:5:3,')');
        if ToErrorFile then
          writeln(q,'    ERROR текст.коорд. U=(',MinU:5:3,':',MaxU:5:3,') V=(',MinV:5:3,':',MaxV:5:3,')');
      end;
//    end;{if ToFile}
  end; {with}
  SkipChunk;
end;

procedure DoTextFname;
begin
  Material[CurMater].nt := GetString;
  if ToFile then
    writeln(t,'   Texture file: <',Material[CurMater].nt,'>');
  while pos('"',Material[CurMater].nt) > 0 do
    delete(Material[CurMater].nt,pos('"',Material[CurMater].nt),1);
  if ToFile then
    writeln(t,'   Texture file: <',Material[CurMater].nt,'>');
  SkipChunk;
end;

type
   GetDataProc = procedure{(id:word; Len : longint)};
   ChunkDescType = record
      i : string;    {идентификатор блока}
//      d : char;    {'d' - есть данные, '-' - нет данных}
//      c : char;    {'c' - есть чанк с безымянными цифрами, для чего нужно оставить адрес}
//      o : char;    {'o' - есть вложенные объекты, '-' - нет вложенных объектов}
      p : GetDataProc; {процедура чтения данных}
      s : NameStr; {строка-описатель блока}
   end;
const
   MaxNC = 7;
   ChunkDesc : array[0..MaxNC]of ChunkDescType = (
 (i:'None';                   p:SkipChunk;      {0 0} s:' No Chunk ! '),
 (i:'Frame';                  p:DoFrame;        {0 0} s:' *Frame* '),
 (i:'Mesh';                   p:DoMesh;         {0 0} s:' *Mesh* '),
 (i:'FrameTransformMatrix';   p:DoTrMatrix;     {0 0} s:' *FrameTransformMatrix* '),
 (i:'MeshMaterialList';       p:DoMatObj;       {0 0} s:' *MeshMaterialList* '),
 (i:'MeshTextureCoords';      p:DoTextCoord;    {0 0} s:' *MeshTextureCoords* '),
 (i:'TextureFilename';        p:DoTextFname;    {0 0} s:' *TextureFilename* '),
 (i:'Material';               p:DoMaterial;     {0 0} s:' *Material* '));

procedure DoChunk; {обработка чанка}
var i,j : integer;
begin
  j := 0;
  for i := 1 to MaxNC do
    if CurrentChunk = ChunkDesc[i].i then
      j := i;
  if ToFile then
    writeln(t,' DoChunk: ',j,' ',CurrentChunk,' ',ChunkDesc[j].s);
  ChunkDesc[j].p;
end;

procedure ReadChunkHeader{(s:string)};{читает заголовок чанка}
var
   i,j,NCS : integer;
begin
  inc(NumChunkRead);
  NCS := NChunkStack;
  s := GetString;
  case s[1] of
    '{': begin
      if ToFile then
        writeln(t,'ERROR: {');
      if ToErrorFile then
        writeln(q,'ERROR: {');
    end;
    '}':begin
      if NChunkStack < 0 then begin
        if ToFile then
          writeln(t,'ERROR: NChunkStack=',NChunkStack);
        if ToErrorFile then
          writeln(q,'ERROR: NChunkStack=',NChunkStack);
      end;
      if ToFile then
        writeln(t,'} NChunkStack=',NChunkStack);
    end;
    else begin {новый чанк}
      ChunkStack[NCS] := s;
      CurrentChunk := s;
      s := GetString;
      if s[1] = '{' then begin
        NameStack[NCS] := '';
      end else begin
        if s[1] = '}' then begin
          if ToFile then
            writeln(t,'ERROR: }');
          if ToErrorFile then
            writeln(q,'ERROR: }');
        end else begin
          NameStack[NCS] := s;
          CurrentName := s;
        end;
        s := GetString;
        if s[1] <> '{' then
          if ToFile then
            writeln(t,'Error: absent {');
        end;
      if ToFile then begin
        for i := 1 to NChunkStack do write(t,'+');
        writeln(t,'ReadChunkHeader data: N:',NumChunkRead,' Stack: ',NChunkStack,
                ' / ',_NCS,' ',ChunkStack[NCS],' ',NameStack[NCS]);
      end;
      DoChunk;
    end;
  end; {case s[1]}
end;

{*************************************************************}
{******* главная процедура модуля доступная снаружи **********}
{*************************************************************}
procedure ReadXfile(filename:string); {чтение файла 3DS}
var
  k,kk,Count  : word;        {переменные для цикла и временного чтения}
  len1     : longint;     {}
begin
{инициализация переменных части реализации}
  blockread(f,s[1],16);
  if (s[1] <> 'x') or (s[ 2] <> 'o') or (s[ 3] <> 'f') or (s[ 4] <> ' ') or
     (s[5] <> '0') or (s[ 6] <> '3') or (s[ 7] <> '0') or (s[ 8] <> '2') or
     (s[9] <> 't') or (s[10] <> 'x') or (s[11] <> 't') or (s[12] <> ' ') then begin
     deb2file('ReadXfile: file not valid ',0);
     close(f);
     exit;
  end;
  NChunkStack := 0;
  _NCS := 0;
  BufCount := 65536;
  ExtraCount := 0;
  LenBuf := 0;
  NumChunkRead := 0;
  OldChar := ' ';
  IsFrameBeforeMesh := FALSE;
  NbndPoly := 0;
  getmemF(BndPoly,sizeof(BndPoly^),'ReadX BndPoly');
  deb2file('ReadXfile *010* ',0);
{исполняющая часть}
  CreateMaterial(DefMaterial);  {материал по умолчанию на всякий случай}
//  inc(Nmater);
  deb2file('ReadXfile *040* ',0);
  repeat
    ReadChunkHeader{('')}; {инизиализирует chunk, lch, Beg_ofs}
  until {eof(f)}ExtraCount > 0;
  freememF(BndPoly,sizeof(BndPoly^),'ReadX BndPoly');
  if ToFile then
    writeln(t,'Stack state: ',NChunkStack);
{основная рекурсивная процедура разбора файла}
  deb2file('ReadXfile *050* ',0);
  close(f);

{---проверка наличия материалов у объектов и приписывания материала по умолчанию, если нет---}
  deb2file('Read3DSfile *070* ',0);
  if Nobj3DS > 0 then
    for k := 0 to Nobj3DS-1 do begin
      if ToFile then
        writeln(t,'проверка наличия материалов у объектов Nobj=',k,' nf=',Obj3DS[k].nf,' m0=',Obj3DS[k].m0);
      if (Obj3DS[k].nf > 0) and (Obj3DS[k].m0 = -1) then begin
        Count := Obj3DS[k].nf;
        inc(NfaceMat,Count);
        CreateMatObj(k,longint(Count),DefMaterial);
        if ToFile then
          writeln(t,' Приписывание объекту ',k,' материала по умолчанию ',CurMatObj);
        with MatObj[CurMatObj] do begin
          nf := Count;
          for kk := 0 to Count-1 do begin
            pf^[kk] := kk;
          end;
        end; {with}
      end; {if Count}
    end; {for}
  deb2file('ReadXfile *080* ',0);
end;

end.