{3DS file reader by S. Andrianov 1999-2002 andriano.tsinet.ru}
{для правильного отображения OpenGL изменен знак оси Z}
Unit Read3D7c; {чтение 3ds-файла}
interface

{var
  f : file;}

procedure Read3DSfile(filename:string); {чтение массивов вершин и граней}

implementation
uses windows, messages, deb_as, comm_3d, matrx_wd;

type
  ChunkType = record  {для сбора статистики по чанкам}
    n : word;         {идентификатор}
    l : longint;      {длина}
    b : boolean;      {является ли он неизвестным}
  end;
  TpL = array[0..65535]of longint;
  TpW = array[0..65535]of word;
  TrackObjType = record {дополнительный массив для отслеживания связей анимации}
               {нужен из-за того, что номер объекта при анимации отслеживается только по порядку}
               { его появления, а порядок появления в основном блоке и блоке анимации различен}
    Main   : longint;   {номер соответствующего элемента в массиве Obj3DS}
                         { Obj3DS[TrackObj[i].Main] - так обращаться к полям основного массива}
    Parent : longint;   {номер родителя в массиве TrackObj}
                         { Obj3DS[TrackObj[i].Main].parent = TrackObj[TrackObj[i].parent].Main }
  end;
var
  UsedChunks    : array[1..256]of ChunkType;   {список чанков, встретившихся в файле}
  chunk         : word;                      {номер чанка}
  lch           : longint;                   {длина чанка}
  Beg_ofs       : longint;                   {смещение начала чанка}
  TargetPointer : pointer;                   {указатель на данные, которые скоро необходимо принять}
  TrackObj      : array[0..MaxObj-1]of TrackObjType; {дополнительный массив для анимации}
  NtrackObj     : longint;                   {количество объектов в дополнительном массиве}
  TempColor     : ColorType;                 {4*4=16 bytes - временный вектор для обмена между чанками}

{******************************************************************************}
{****** процедуры, осуществляющее непосредственное чтение из файла ************}
{******************************************************************************}

function ReadASCII:string; {читает 0-terminated string}
var
   ss : string;
   ch : char;
begin
   ss := '';
   repeat
      blockread(f,ch,sizeof(ch)); inc(FilePos,sizeof(ch));
      if ch <> #0 then ss := ss + ch;
   until (ch = #0) or (length(ss) >= 79);
   ss[length(ss)+1] := #0;
//   messagebox(0,'ReadASCII',@ss[1],MB_OK);  {}
   ReadASCII := ss;
end;

procedure SkipData(id:word; Len : longint); {пропустить данные}
begin
  inc(FilePos,Len-6);
  seek(f,FilePos);
end;

function CheckChunkLength(LenData:longint; s:string):boolean;{верна ли длина чанка}
begin
  if lch <> (LenData + 6) then begin
    if ToFile then
      writeln(t,'  ERROR Length Chunk. Real Length= ',lch,' instead ',LenData+6,' '+s);
    if ToErrorFile then
      writeln(q,'  ERROR Length Chunk. Real Length= ',lch,' instead ',LenData+6,
         ' chunk=',hex2str(chunk),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') '+s);
  end;
  CheckChunkLength :=  lch = (LenData + 6);
end;

procedure r0002_M3DVersion(id:word; Len : longint);
var ver : longint;
begin {+ 4d4d [+]  M3D Version M3D_VERSION}
  CheckChunkLength(4,'M3D Version');
  blockread(f,ver,sizeof(ver));
  if ToFile then
    writeln(t,'    M3D Version = ',ver);
  inc(FilePos,sizeof(ver));
end;

procedure r0010_RGBfloat(id:word; Len : longint);
var RGB : ColorType;
begin {+ 4600 (A010, A020, A030 ?) [+] Reg, Green, Blue: bytes}
  CheckChunkLength(12,'RGB float');
  blockread(f,RGB,12);
  if ToFile then
    writeln(t,'    RGB float: R = ',RGB.r:5:3,' G = ', RGB.g:5:3,' B = ',RGB.b:5:3,', Prev chunk = ',hex2str(id));
//  if id in [ $A010, $A020, $A030 ] then begin
  if (id = $4600) {or (id = $A020) or (id = $A030)} then begin
    if TargetPointer <> nil then begin {проверяем, готово ли поле принять данные}
      ColorType(TargetPointer^).r := RGB.r;
      ColorType(TargetPointer^).g := RGB.g;
      ColorType(TargetPointer^).b := RGB.b;
      ColorType(TargetPointer^).a := 1.0;
      TargetPointer := nil;
    end else begin
      if ToFile then
        writeln(t,'    RGB float ERROR: target not ready');
      if ToErrorFile then
        writeln(q,'    RGB float ERROR: target not ready Prev chunk = ',hex2str(id),
             ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
  end else begin {if id}
    if ToFile then
      writeln(t,'    RGB float ERROR: Previous chunk not valid, chunk = '+hex2str(id));
    if ToErrorFile then
      writeln(q,'    RGB float ERROR: Previous chunk not valid, chunk = '+hex2str(id),
            ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  inc(FilePos,12);
end;

procedure r0011_RGBbyte(id:word; Len : longint);
type RGBbyteType = record r,g,b : byte; end;
var RGB : RGBbyteType;
begin {+ A010, A020, A030 [+] Reg, Green, Blue: bytes}
  CheckChunkLength(3,'RGB byte');
  blockread(f,RGB,sizeof(RGB));
  if ToFile then
    writeln(t,'    RGB byte: R = ',RGB.r,' G = ', RGB.g,' B = ',RGB.b,', Prev chunk = ',hex2str(id));
//  if id in [ $A010, $A020, $A030 ] then begin
  if (id = $A010) or (id = $A020) or (id = $A030) then begin
    if TargetPointer <> nil then begin {проверяем, готово ли поле принять данные}
      ColorType(TargetPointer^).r := RGB.r / 255;
      ColorType(TargetPointer^).g := RGB.g / 255;
      ColorType(TargetPointer^).b := RGB.b / 255;
      ColorType(TargetPointer^).a := 1.0;
      TargetPointer := nil;
    end else begin
      if ToFile then
        writeln(t,'    RGB byte ERROR: target not ready');
      if ToErrorFile then
        writeln(q,'    RGB byte ERROR: target not ready, chunk = '+hex2str(id),
            ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
  end else begin{if id}
    if ToFile then
      writeln(t,'    RGB byte ERROR: Previous chunk not valid, chunk = '+hex2str(id));
    if ToErrorFile then
      writeln(q,'    RGB byte ERROR: Previous chunk not valid, chunk = '+hex2str(id),
            ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  inc(FilePos,sizeof(RGB));
end;

procedure r0030_Percentage(id:word; Len : longint);
var Percentage : word;
begin {+ a040, a041, a050, a052, a053, a084, a200, a220 [+] Percentage}
  CheckChunkLength(2,'Percentage');
  blockread(f,Percentage,sizeof(Percentage));
  if ToFile then
    writeln(t,'    Percentage = ',Percentage,', Prev chunk = ',hex2str(id));
  if (id = $A040) or (id = $A041) or (id = $A050) or (id = $A052) or (id = $A053) or (id = $A084) or
     (id = $A200) or (id = $A220) then begin
    if TargetPointer <> nil then begin {проверяем, готово ли поле принять данные}
      single(TargetPointer^) := Percentage / 100;
      TargetPointer := nil;
    end else begin
      if ToFile then
        writeln(t,'    Percentage ERROR: target not ready');
      if ToErrorFile then
        writeln(q,'    Percentage ERROR: target not ready chunk = '+hex2str(id),
            ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
  end else begin {if id}
    if ToFile then
      writeln(t,'    Percentage ERROR: Previous chunk not valid, chunk = '+hex2str(id));
    if ToErrorFile then
      writeln(q,'    Percentage ERROR: Previous chunk not valid, chunk = '+hex2str(id),
            ' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  inc(FilePos,sizeof(Percentage));
end;

procedure r0100_MasterScale(id:word; Len : longint);
var Scale : single;
begin {+ 3d3d [+] Master Scale}
  CheckChunkLength(4,'Master Scale');
  blockread(f,Scale,sizeof(Scale));
  if ToFile then
    writeln(t,'    Master Scale = ',Scale);
  inc(FilePos,sizeof(Scale));
end;

procedure r3d3e_MeshVersion(id:word; Len : longint);
var ver : longint;
begin {+ 3d3d [+]  Mesh Version MESH_VERSION}
  CheckChunkLength(4,'Mesh Version');
  blockread(f,ver,sizeof(ver));
  if ToFile then
    writeln(t,'    Mesh Version = ',ver);
  inc(FilePos,sizeof(ver));
end;

procedure r4000_ObjBlock(id:word; Len : longint);
begin {+ 3d3d [+] объект                      CHUNK_OBJBLOCK}
  if Nobj3DS >= MaxObj then begin
    messagebox(0,'Слишком много объектов','Read3DS ERROR',MB_OK or MB_ICONERROR);  {}
    halt;
  end;
  CreateObj3DS(ReadASCII);
end;

procedure r4110_VertList(id:word; Len : longint);
var
  Count : word;
  kk : longint;
  temps : single;
begin {+ 4100 [+] список вершин               CHUNK_VERTLIST}
  blockread(f,Count,sizeof(Count)); {inc(FilePos,sizeof(k));}
  CheckChunkLength(2 + longint(Count)*12,'Read VertList');
  if Count > MaxPoints then begin
    if ToFile then
      writeln(t,'    Слишком много точек: ',Count,' ( Уже есть: ',Npoints,' Максимум: ',MaxPoints,')');
    if ToErrorFile then
      writeln(q,'    Слишком много точек: ',Count,' ( Уже есть: ',Npoints,' Максимум: ',MaxPoints,
         ') chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    halt;
  end;
  if ToFile then
    writeln(t,'    вершин: ',Count,' Всего: ',Npoints);
  inc(Npoints,Count);
  if Mpoints < Count then Mpoints := Count;
  with Obj3DS[CurObj3DS] do begin
    nv := Count;
    getmemF(pv,Count*sizeof(TRealVector),'r3:VertL');
    blockread(f,pv^,Count*sizeof(TRealVector));
    MaX := -1.e36;   MiX := 1.e36;
    MaY := -1.e36;   MiY := 1.e36;
    MaZ := -1.e36;   MiZ := 1.e36;    { \V/  здесь меняем знак оси Z для отобр OpenGL}
    for kk := 0 to Count - 1 do begin {  V                                           }
    temps := pv^[kk].z;   pv^[kk].z := - pv^[kk].y;   pv^[kk].y := temps; { Swap Y <-> Z }
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
    if ToFile then begin
      writeln(t,'    вершин: ',Count,' Range: X=(',MiX:8:2,':',MaX:8:2,
          ') Y=(',MiY:8:2,':',MaY:8:2,') Z=(',MiZ:8:2,':',MaZ:8:2,')');
      writeln(t,' first verticle: x= ',pv^[0].x:12:6,' y= ',pv^[0].y:12:6,' z= ',pv^[0].z:12:6);
    end;
  end;
  inc(FilePos,lch-6);
end;

procedure r4111_VertFlag(id:word; Len : longint);
var
  Count : word;
  kk : longint;
//  temps : single;
  ff : ^tpw;
begin {+ 4100 [+] список вершин               CHUNK_VERTFACES}
  blockread(f,Count,sizeof(Count)); {inc(FilePos,sizeof(k));}
  CheckChunkLength(2 + longint(Count)*2,'Read VertFlag');
  if Count <> Obj3DS[CurObj3DS].nv then begin
    if ToFile then
      writeln(t,'    Разное количество вершин (',Obj3DS[CurObj3DS].nv,') и флагов (',Count,')');
    if ToErrorFile then
      writeln(q,'    Разное количество вершин (',Obj3DS[CurObj3DS].nv,') и флагов (',Count,
         ') chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    halt;
  end;
  with Obj3DS[CurObj3DS] do begin
    if ToFile then
      writeln(t,'    флагов вершин: ',Count,' текстурных координат: ',nt);
//    nv := Count;
    getmemF(ff,Count*sizeof(word),'r3:VertFlag');
    blockread(f,ff^,Count*sizeof(word));
    if nt = count then
      if ToFile then
        for kk := 0 to Count-1 do
          writeln(t,' Vert N: ',kk:5,' Flag: ',w2b(ff^[kk]),' Tex.Coord.: ',pt^[kk].u:7:3,' ',pt^[kk].v:7:3);
    freememF(ff,Count*sizeof(word),'r3:VertFlag');
  end;
  inc(FilePos,lch-6);
end;

procedure r4120_FaceList(id:word; Len : longint);
var
  Count : word;
  kk : longint;
  pf2      : ^FaceArrayType2;
begin {+ 4100 [+] список граней               CHUNK_FACELIST}
  blockread(f,Count,sizeof(Count));
  if Count > MaxFaces then begin
    if ToFile then
      writeln(t,'    Слишком много граней: ',Count,' ( Уже есть: ',Nfaces,' Максимум: ',MaxFaces,')');
    if ToErrorFile then
      writeln(q,'    Слишком много граней: ',Count,' ( Уже есть: ',Nfaces,' Максимум: ',MaxFaces,
         ') chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    halt;
  end;
  inc(Nfaces,Count);
  if Mfaces < Count then Mfaces := Count;
  with Obj3DS[CurObj3DS] do begin
    if Count > 0 then begin
      nf := Count;
      getmemF(pf,Count*sizeof(FaceType),'r3:FacL1');
      getmemF(pff,Count*sizeof(word),'r3:FacL2');
      getmemF(pf2,Count*sizeof(FaceType2),'r3:FacL3');
      blockread(f,pf2^,Count*sizeof(FaceType2));
      for kk := 0 to Count-1 do begin
        pf^ [kk][1] := pf2^[kk][1];
        pf^ [kk][2] := pf2^[kk][2];
        pf^ [kk][3] := pf2^[kk][3];
        pff^[kk]    := pf2^[kk][4];
        if (pf^[kk][1] < 0) or (pf^[kk][1] > (nv-1)) or
           (pf^[kk][2] < 0) or (pf^[kk][2] > (nv-1)) or
           (pf^[kk][3] < 0) or (pf^[kk][3] > (nv-1)) then begin
          if ToFile then
            writeln(t,'    Faces error: Max',nv-1:8,pf^[kk][1]:8,pf^[kk][2]:8,pf^[kk][3]:8);
          if ToErrorFile then
            writeln(q,'    Faces error: Max',nv-1:8,pf^[kk][1]:8,pf^[kk][2]:8,pf^[kk][3]:8,
                ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
        end;
      end;
      freememF(pf2,Count*sizeof(FaceType2),'r3:FaceL');
    end; {if Count > 0}
    if ToFile then begin
      if Count > 0 then kk := Count else kk := 1;
      if (lch-6-2-longint(Count)*8) = 0 then
        writeln(t,'    граней: ',Count,' нет остатка длины'){}
      else if (lch-6-2-longint(Count)*8) = (6+longint(Count)*4) then
        writeln(t,'    граней: ',Count,' остаток длины для блока с 4 байтами на грань'){}
      else
        writeln(t,'    граней: ',Count,' остаток длины: ',lch-6-2-Count*8,' (',
        (lch-6-2-Count*8) div kk,' на грань (+',(lch-6-2-Count*8) mod kk,'))');{}
    end;
    inc(FilePos, sizeof(Count) + Count*sizeof(FaceType2));
  end;
end;

procedure r4130_FaceMat(id:word; Len : longint);
var
  s        : string;
  Count : word;
  kk : longint;
  pW       : ^TpW;
begin {. 4120 [+] материалы граней            CHUNK_FACEMAT}
  s := ReadASCII;
  blockread(f,Count,sizeof(Count));
  CheckChunkLength(length(s)+1 + 2 + longint(Count)*2,'Read FaceMat');
  with Obj3DS[CurObj3DS] do begin
    if (nfm + Count) > nf then begin
      if ToFile then
        writeln(t,'    ERROR: Слишком много граней с материалами: nfm=',nfm,' Count=',Count,' nf=',nf);
      if ToErrorFile then
        writeln(q,'    ERROR: Слишком много граней с материалами: nfm=',nfm,' Count=',Count,' nf=',nf,
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
      halt;
    end else
      inc(nfm,Count);
  end; {with}
  if Count > 0 then begin
    inc(NfaceMat,Count);
    CreateMatObj(CurObj3DS,longint(Count),s);
    getmemF(pW,longint(Count)*sizeof(word),'r3:FacMt');
    blockread(f,pW^,longint(Count)*sizeof(word));
    with MatObj[CurMatObj] do begin
      nf := Count;
      for kk := 0 to Count-1 do begin
        pf^[kk] := pW^[kk];
        fl0 := fl0 or  Obj3DS[CurObj3DS].pff^[pf^[kk]];
        fl1 := fl1 and Obj3DS[CurObj3DS].pff^[pf^[kk]];
      end;
    end; {with}
//    inc(NmatObj);
    freememF(pW,longint(Count)*sizeof(word),'r3:FaceM');
  end; {if Count}
  inc(FilePos, sizeof(Count) + Count*sizeof(word));
end;{}

procedure r4140_TextCoord(id:word; Len : longint);
var
  Count : word;
  kk : longint;
  MinU,MinV,MaxU,MaxV : single; {пределы изменения текстурных координат}
begin {. 4100 [+] текстурные координаты       CHUNK_MAPLIST}
  blockread(f,Count,sizeof(Count));
  CheckChunkLength(2 + longint(Count)*sizeof(TtextC),'Read TextCoord');
  if ToFile then
    writeln(t,'    кол-во текст.координат: ',Count{,'/',(lch-8) div 8,' (',(lch-8) mod 8,')'});{}
  inc(NtextC, Count);
  with Obj3DS[CurObj3DS] do begin
    if Count <> nv then begin
      if ToFile then
        writeln(t,'    ERROR: Несовпадение количества вершин и текс.коорд.: nv=:',nv,' nt=',Count);
      if ToFile then
        writeln(t,'    ERROR: Несовпадение количества вершин и текс.коорд.: nv=:',nv,' nt=',Count,
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
    nt := Count;
    getmemF(pt,Count*sizeof(TtextC),'r3:TexC');
    blockread(f,pt^,Count*sizeof(TtextC));
    if ToFile or ToErrorFile then begin
      MinU := 1000.0;   MinV := 1000.0;   MaxU := -1000.0; MaxV := -1000.0;
      for kk := 0 to Count - 1 do begin
        if MinU > pt^[kk].u then MinU := pt^[kk].u;
        if MinV > pt^[kk].v then MinV := pt^[kk].v;
        if MaxU < pt^[kk].u then MaxU := pt^[kk].u;
        if MaxV < pt^[kk].v then MaxV := pt^[kk].v;
      end;
      if (MinU < 0) or (MaxU > 1) or (MinV < 0) or (MaxV > 1) then begin
        if ToFile then
          writeln(t,'    ERROR текст.коорд. U=(',MinU:5:3,':',MaxU:5:3,') V=(',MinV:5:3,':',MaxV:5:3,')');
        if ToErrorFile then
          writeln(q,'    ERROR текст.коорд. U=(',MinU:5:3,':',MaxU:5:3,') V=(',MinV:5:3,':',MaxV:5:3,')',
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
      end;
    end;{if ToFile}
  end; {with}
  inc(FilePos,lch-6);
end;{}

procedure r4150_SmoothGroup(id:word; Len : longint);
var
   i : word;
   n : array[0..3,0..255]of word;
begin {+ 4120 [+] группы сглаживания граней               SMOOTH_GROUP}
  with Obj3DS[CurObj3DS] do begin
    CheckChunkLength(nf*sizeof(longint),'Read SmoothGroup');
    getmemF(pfg,nf*sizeof(longint),'r3:SmGrp');
    blockread(f,pfg^,nf*sizeof(longint));
    inc(FilePos, nf*sizeof(longint));
{статистика}
    if ToFile then begin
    fillchar(n,sizeof(n),0);
//      writeln(t,'    группы сглаживания');
      if nf > 0 then
        for i := 0 to nf-1 do begin
          inc(n[0,(pfg^[i]       ) and $ff]);
          inc(n[1,(pfg^[i] shr  8) and $ff]);
          inc(n[2,(pfg^[i] shr 16) and $ff]);
          inc(n[3,(pfg^[i] shr 24) and $ff]);
        end;
      for i := 0 to 255 do
        if (n[3,i] + n[2,i] + n[1,i] + n[0,i]) > 0 then
          writeln(t,'    группы сглаживания i=',i:3,'   ',n[3,i]:6,n[2,i]:6,n[1,i]:6,n[0,i]:6,'  of ',nf);
    end; {if ToFile}
  end; {with}
end;

procedure r4160_TrMatrix(id:word; Len : longint);
var
  kk : word;
  vv    : TRealVector;    {просто для чтения данных}
begin {+ 4100 [+] матрица перевода            CHUNK_TRMATRIX}
  CheckChunkLength(48,'Read TrMatrix');
  with Obj3DS[CurObj3DS] do begin
    blockread(f,vv,sizeof(vv));
    tm[0,0] := vv.x;
    tm[0,2] := vv.y;
    tm[0,1] := vv.z;
    blockread(f,vv,sizeof(vv));
    tm[2,0] := vv.x;
    tm[2,2] := vv.y;
    tm[2,1] := vv.z;
    blockread(f,vv,sizeof(vv));
    tm[1,0] := vv.x;
    tm[1,2] := vv.y;
    tm[1,1] := vv.z;
    blockread(f,vv,sizeof(vv));
    tm[3,0] := vv.x;
    tm[3,2] := vv.y;
    tm[3,1] := vv.z;
    if ToFile then begin
      writeln(t,'    вектор смещ. : ',vv.x:12:6,vv.y:12:6,vv.z:12:6);
      for kk := 0 to 3 do
        writeln(t,'    матр.переводa :',tm[kk,0]:12:6,tm[kk,1]:12:6,tm[kk,2]:12:6,tm[kk,3]:12:6);
    end;
  end;
  inc(FilePos,lch-6);
end;{}

procedure r4600_NdirectLight(id:word; Len : longint);
var vv : TRealVector;    {просто для чтения данных}
begin {+ 4000 [+]     вектор света ?  4600H  N_DIRECT_LIGHT}
  CheckChunkLength(sizeof(vv)+18,'Read N Direct Light');
  blockread(f,vv,sizeof(vv));
  inc(FilePos,sizeof(vv));
//  if NtrackObj > 0 then begin
//    Obj3DS[TrackObj[NtrackObj-1].main].cr := vv;
  if ToFile then
    writeln(t,'    вектор прямого света: ',vv.x:10:4,vv.y:10:4,vv.z:10:4);
//  end else
//    if ToFile then
//      writeln(t,'    ERROR TrackPivot: no Track Object, центр вращ.: NtrackObj=',NtrackObj);
//  inc(FilePos,lch-6);//   seek(f,FilePos); end; {пропускаем данные}
//     TargetPointer := @TempColor;
//  if ToFile then
//    writeln(t,'    Material Ambient ');
  if TargetPointer = nil then
     TargetPointer := @TempColor;
//  else
//    if ToFile then
//      writeln(t,'    Material Ambient ERROR:  TargetPointer not free');
end;

procedure r4610_SpotLight(id:word; Len : longint);
var vv : TRealVector;    {просто для чтения данных}
   hots,fall : single;
begin {+ 4600 [+]     прожектор?  4610H  SpotLight}
  CheckChunkLength(5*sizeof(single),'Read Spot Light');
  blockread(f,vv,sizeof(vv));
  blockread(f,hots,sizeof(single));
  blockread(f,fall,sizeof(single));
  inc(FilePos,5*sizeof(single));
  if ToFile then begin
    writeln(t,'    прожектор: ',vv.x:10:4,vv.y:10:4,vv.z:10:4);
    writeln(t,'    HotSpot Angle = ',hots:10:4);
    writeln(t,'    FallOff Angle = ',fall:10:4);
  end;
//  if TargetPointer = nil then
//     TargetPointer := @TempColor;
end;

procedure rA000_MatName(id:word; Len : longint);
var s : string;
begin {. afff [+] название материала          CHUNK_MATNAME}
  s := ReadASCII;
  CheckChunkLength(length(s)+1,'Read MatName');
  CreateMaterial(s);
end;{}

function CheckTargetPointer(id:word; s:string):boolean;{проверка на пустой указатель + печать}
begin
  if ToFile then
    writeln(t,'    '+s+' ');
  if TargetPointer = nil then
    CheckTargetPointer := TRUE
  else begin
    if ToFile then
      writeln(t,'    '+s+' ERROR:  TargetPointer not free');
    if ToErrorFile then
      writeln(q,'    '+s+' ERROR:  TargetPointer not free',
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
end;

procedure rA010_Ambient(id:word; Len : longint);
begin {. afff [+] material ambient           CHUNK_AMBIENT}
  if CheckTargetPointer(id,'Material Ambient') then
     TargetPointer := @Material[CurMater].ambi
end;{}

procedure rA020_Diffuse(id:word; Len : longint);
begin {. afff [+] material Diffuse           CHUNK_DIFFUSE}
  if CheckTargetPointer(id,'Material Diffuse') then
     TargetPointer := @Material[CurMater].diff
end;{}

procedure rA030_Specular(id:word; Len : longint);
begin {. afff [+] material Specular           CHUNK_SPECULAR}
  if CheckTargetPointer(id,'Material Specular') then
     TargetPointer := @Material[CurMater].spec
end;{}

procedure rA040_Shininess(id:word; Len : longint);
begin {. afff [+] material Shininess           MAT_SHININESS}
  if CheckTargetPointer(id,'Material Shininess') then
     TargetPointer := @Material[CurMater].shin
end;{}

procedure rA041_52_53_84_200(id:word; Len : longint);
var a : single;
begin {. afff [+] material Shininess           MAT_SHININESS}
  if CheckTargetPointer(id,'Material 41_52_53_84_200') then
     TargetPointer := @a
end;{}

procedure rA050_Transparency(id:word; Len : longint);
begin {. afff [+] material Transparency           MAT_TRANSPARENCY}
  if CheckTargetPointer(id,'Material Transparency') then
     TargetPointer := @Material[CurMater].tran
end;{}

procedure rA200_Texture(id:word; Len : longint);
begin {. afff [+] material Texture           CHUNK_TEXTURE}
  if CheckTargetPointer(id,'Material Texture') then
     TargetPointer := @Material[CurMater].texp
end;{}

procedure rA300_MapFile(id:word; Len : longint);
var s : string;
begin {. a300 [+] имя файла текстуры          CHUNK_MAPFILE}
  s := ReadASCII;
  CheckChunkLength(length(s)+1,'Read MapFile');
  if ToFile then
    writeln(t,'    имя файла текстуры: ',s);
  if id <> $A200 then begin
    if ToFile then
      writeln(t,'   MapFile ERROR Mapfile not for Texture, Prev Chunk:',hex2str(id));
    if ToErrorFile then
      writeln(q,'   MapFile ERROR Mapfile not for Texture, Prev Chunk:',hex2str(id),
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  with Material[CurMater] do begin
    nt := s;
{************************************}
{здесь можно вставить чтение файла текстуры}
{************************************}
//          LoadTexture(dx, dy, bp, pt, nt, dlst);
    if ToFile then begin
      writeln(t,'    загружена текстура - size: ',dx,'x',dy,'x',bp);{}
    end;{}
  end;
end;{}

procedure rA351_Tiling(id:word; Len : longint);
var w : word;
begin {. a351 [+] флаги параметров материала / мозайка   CHUNK_TILING}
  CheckChunkLength(sizeof(w),'Read Tiling');
  blockread(f,w,sizeof(w));
  inc(FilePos,sizeof(w));
  if ToFile then
    writeln(t,'    Tiling: ',w2b(w));
end;{}

procedure rB010_TrackObjName(id:word; Len : longint);
var
  s : string;
  k : word;
  NmainObj : longint;
begin {+ b002 [+] название объекта, для которого траектория  CHUNK_TRACKOBJNAME}
  s := ReadASCII;{}
  CheckChunkLength(length(s)+1+6,'Read Track ObjName');
  NmainObj := -1;
  for k := 0 to Nobj3DS-1 do
    if s = Obj3DS[k].nm then
      NmainObj := k;
  blockread(f,k,sizeof(k)); {флаги}
  blockread(f,k,sizeof(k)); {флаги}
  blockread(f,k,sizeof(k)); {объект-родитель}
  inc(FilePos,6);
  if ToFile then
    writeln(t,'    имя объекта анимации: ',s,'  родитель: ',k,' номер основного объекта: ',NmainObj,
              ' номер объекта анимации: ',NtrackObj);{}
  TrackObj[NtrackObj].main := NmainObj;
  TrackObj[NtrackObj].parent := k;
  if NmainObj < 0 then begin
    if ToFile then
      writeln(t,'    ERROR TrackObjName: Object ',s,' not found NtrackObj:',NtrackObj,' / NmainObj:',NmainObj);{}
    if ToErrorFile then
      writeln(q,'    ERROR TrackObjName: Object ',s,' not found NtrackObj:',NtrackObj,' / NmainObj:',NmainObj,{}
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  inc(NtrackObj);
end;{}

procedure rB013_TrackPivot(id:word; Len : longint);
var vv : TRealVector;    {просто для чтения данных}
begin {+ b002 [+] центр вращения объекта      CHUNK_TRACKPIVOT}
  CheckChunkLength(sizeof(vv),'Read Track Pivot');
  blockread(f,vv,sizeof(vv));
  if NtrackObj > 0 then begin
//        writeln(t,' rB013_TrackPivot NtrackObj=',NtrackObj,' TrackObj[NtrackObj-1].main=',TrackObj[NtrackObj-1].main);
    if TrackObj[NtrackObj-1].main >= 0 then begin
      Obj3DS[TrackObj[NtrackObj-1].main].cr := vv;
      if ToFile then begin
        write(t,'    центр вращ.: ',vv.x:10:4,vv.y:10:4,vv.z:10:4,' NtrackObj=',NtrackObj-1,
          ' N Obj=',TrackObj[NtrackObj-1].main);
        if TrackObj[NtrackObj-1].main >= 0 then
          writeln(t,' Obj=',Obj3DS[TrackObj[NtrackObj-1].main].nm)
        else
          writeln(t,' Object Absent');
      end;
    end else begin
      if ToFile then
        writeln(t,'    ERROR (1) TrackPivot: no Track Object, центр вращ.: NtrackObj=',NtrackObj,
           ' N Obj=',TrackObj[NtrackObj-1].main);
      if ToErrorFile then
        writeln(q,'    ERROR (1) TrackPivot: no Track Object, центр вращ.: NtrackObj=',NtrackObj,
           ' N Obj=',TrackObj[NtrackObj-1].main,' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
  end else begin
    if ToFile then
      writeln(t,'    ERROR (2) TrackPivot: no Track Object, центр вращ.: NtrackObj=',NtrackObj);
    if ToErrorFile then
      writeln(q,'    ERROR (2) TrackPivot: no Track Object, центр вращ.: NtrackObj=',NtrackObj,
              ' chunk = ',hex2str(id),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  inc(FilePos,lch-6);//   seek(f,FilePos); end; {пропускаем данные}
end;

procedure rB020_TrackPos(id:word; Len : longint);
var
  vv : TRealVector;    {просто для чтения данных}
  Count,kk : word;
  bb : array[0..9]of byte;    {просто для чтения данных}
begin {+ b001 [+] траектория объекта          CHUNK_TRACKPOS}
  blockread(f,bb,10); {2 байта флагов и 8 - unknown}
  blockread(f,Count,sizeof(Count)); {к-во кадров}
  if ToFile then
    writeln(t,'    траектория объекта, количество кадров: ',Count);
{дальше читаем только первый элемент траектории, предполагая, что сплайнов нет}
  blockread(f,kk,sizeof(kk)); {номер кадра}
  blockread(f,Count,sizeof(Count)); {флаги кадра}
  if (Count=0) then begin {}
    blockread(f,vv,sizeof(vv)); {положение объекта}
    if ToFile then begin
      writeln(t,'    положение: ',vv.x:12:6,vv.y:12:6,vv.z:12:6);
    end;
  end;
  begin inc(FilePos,lch-6);   seek(f,FilePos); end; {пропускаем данные}
end;

{--------------------------------------------}
procedure rB021_TrackRotate(id:word; Len : longint);
var
  Count : word;
  bb : array[0..9]of byte;    {просто для чтения данных}
begin {+ b002 [+] траектория вращения объекта CHUNK_TRACKROTATE}
  blockread(f,bb,10); {2 байта флагов и 8 - unknown}
  blockread(f,Count,sizeof(Count)); {к-во кадров}
  if ToFile then
    writeln(t,'    траектория вращения объекта, количество кадров: ',Count);
{дальше читаем только первый элемент траектории, предполагая, что сплайнов нет}
//  blockread(f,kk,sizeof(kk)); {номер кадра}
//  blockread(f,Count,sizeof(Count)); {флаги кадра}
//   if (Count=0) then begin {}
//     blockread(f,aa,sizeof(aa)); {угол поворотоа}
//     blockread(f,vv,sizeof(vv)); {ось вращения}
//{               Obj[Nobj].ax := vv;}
//     if ToFile then begin
//      writeln(t,'    угол поворота: ',aa:12:6);
//      writeln(t,'    ось вращения:  ',vv.x:12:6,vv.y:12:6,vv.z:12:6);
//    end;
//  end;
  begin inc(FilePos,lch-6);   seek(f,FilePos); end; {пропускаем данные}
end;
{--------------------------------------------}

type
   GetDataProc = procedure(id:word; Len : longint);
   ChunkDescType = record
      i : word;    {идентификатор блока}
      d : char;    {'d' - есть данные, '-' - нет данных}
      c : char;    {'c' - есть чанк с безымянными цифрами, для чего нужно оставить адрес}
      o : char;    {'o' - есть вложенные объекты, '-' - нет вложенных объектов}
      p : GetDataProc; {процедура чтения данных}
      s : NameStr; {строка-описатель блока}
   end;
const
   MaxNC = 55;
   ChunkDesc : array[0..MaxNC]of ChunkDescType = (
 (i:$0000; d:'-'; c:'-'; o:'-'; p:SkipData;           {0 0} s:' No Chunk ! '),
 (i:$0002; d:'d'; c:'-'; o:'-'; p:r0002_M3DVersion;   {+ -} s:'[-] M3D Version'),
 (i:$0010; d:'d'; c:'-'; o:'-'; p:r0010_RGBfloat;     {+  } s:'[+] RGB Float'),
 (i:$0011; d:'d'; c:'-'; o:'-'; p:r0011_RGBbyte;      {+  } s:'[+] RGB Byte'),
 (i:$0012; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] RGB ?'),
 (i:$0030; d:'d'; c:'-'; o:'-'; p:r0030_Percentage;   {+  } s:'[+] percentage'),
 (i:$0100; d:'d'; c:'-'; o:'-'; p:r0100_MasterScale;  {+ -} s:'[+] Master Scale'),
 (i:$3D3D; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] всяческие объекты'),
 (i:$3D3E; d:'d'; c:'-'; o:'-'; p:r3d3e_MeshVersion;  {+ -} s:'[-] Mesh Version'),
 (i:$4000; d:'d'; c:'-'; o:'o'; p:r4000_ObjBlock;     {+  } s:'[+] объект'),
 (i:$4100; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] trimesh-объект'),
 (i:$4110; d:'d'; c:'-'; o:'-'; p:r4110_VertList;     {+  } s:'[+] список вершин'),
 (i:$4111; d:'d'; c:'-'; o:'-'; p:r4111_VertFlag;     {+ -} s:'[+] список флагов вершин'),
 (i:$4120; d:'d'; c:'-'; o:'o'; p:r4120_FaceList;     {+  } s:'[+] список граней'),
 (i:$4130; d:'d'; c:'-'; o:'-'; p:r4130_FaceMat;      {+  } s:'[+] материалы граней'),
 (i:$4140; d:'d'; c:'-'; o:'-'; p:r4140_TextCoord;    {+  } s:'[+] текстурные координаты'),
 (i:$4150; d:'d'; c:'-'; o:'-'; p:r4150_SmoothGroup;  {+  } s:'[+] группы сглаживания ?'),
 (i:$4160; d:'d'; c:'-'; o:'-'; p:r4160_TrMatrix;     {+  } s:'[+] матрица перевода'),
 (i:$4600; d:'d'; c:'-'; o:'-'; p:r4600_NdirectLight; {+ -} s:'[+] прямой свет'),
 (i:$4610; d:'d'; c:'-'; o:'-'; p:r4610_SpotLight;    {+ -} s:'[+] прожектор ??'),
 (i:$4700; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] объект-камера'),
 (i:$4D4D; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] сцена'),
 (i:$A000; d:'d'; c:'-'; o:'-'; p:rA000_MatName;      {+  } s:'[+] название материала'),
 (i:$A010; d:'-'; c:'c'; o:'o'; p:rA010_Ambient;      {+  } s:'[+] ambient материала'),   { на самом      }
 (i:$A020; d:'-'; c:'c'; o:'o'; p:rA020_Diffuse;      {+  } s:'[+] diffuse материала'),   { деле данных   }
 (i:$A030; d:'-'; c:'c'; o:'o'; p:rA030_Specular;     {+  } s:'[+] specular материала'),  { нет,          }
 (i:$A040; d:'-'; c:'c'; o:'o'; p:rA040_Shininess;    {+  } s:'[+] shininess материала'), { но нужно      }
 (i:$A041; d:'-'; c:'c'; o:'o'; p:rA041_52_53_84_200; {+ -} s:'[+] shin2pct материала'),  { вызывать      }
 (i:$A050; d:'-'; c:'c'; o:'o'; p:rA050_Transparency; {+  } s:'[+] прозр-сть материала'), { процедуру     }
 (i:$A052; d:'-'; c:'c'; o:'o'; p:rA041_52_53_84_200; {+ -} s:'[+] xpfall материала'),    { для           }
 (i:$A053; d:'-'; c:'c'; o:'o'; p:rA041_52_53_84_200; {+ -} s:'[+] refblur материала'),   { инициализации }
 (i:$A081; d:'-'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] two_side материала'),
 (i:$A084; d:'-'; c:'c'; o:'o'; p:rA041_52_53_84_200; {+ -} s:'[+] self_ilpct материала'),{  адреса       }
 (i:$A087; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] wiresize материала'),
 (i:$A08a; d:'-'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] xpfallin материала'),
 (i:$A100; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] shading материала'),
 (i:$A200; d:'-'; c:'c'; o:'o'; p:rA200_Texture;      {+  } s:'[-] текстура материала'),
 (i:$A220; d:'-'; c:'-'; o:'o'; p:SkipData;           {  -} s:'[+] reflmap материала'),
 (i:$A240; d:'-'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] use_xpfall материала'),
 (i:$A250; d:'-'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] use_refblur материала'),
 (i:$A300; d:'d'; c:'-'; o:'-'; p:rA300_MapFile;      {+  } s:'[+] имя файла текстуры'),
 (i:$A320; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] sxp_text_data текстуры'),
 (i:$A324; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] sxp_bump_data текстуры'),
 (i:$A351; d:'d'; c:'-'; o:'-'; p:rA351_Tiling;       {+ -} s:'[+] map_tiling текстуры'),
 (i:$A353; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] map_texblur текстуры'),
 (i:$AFFF; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] материал'),
 (i:$B000; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] информация об анимации'),
 (i:$B002; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] поведение объекта'),
 (i:$B003; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] поведение камеры'),
 (i:$B004; d:'-'; c:'-'; o:'o'; p:SkipData;           {+  } s:'[-] поведение "цели" камеры'),
 (i:$B010; d:'d'; c:'-'; o:'-'; p:rB010_TrackObjName; {+  } s:'[+] назв.объекта, с траекторией'),
 (i:$B013; d:'d'; c:'-'; o:'-'; p:rB013_TrackPivot;   {+  } s:'[+] центр вращения объекта'),
 (i:$B020; d:'d'; c:'-'; o:'-'; p:rB020_TrackPos;     {+ -} s:'[+] траектория объекта'),
 (i:$B021; d:'d'; c:'-'; o:'-'; p:rB021_TrackRotate;  {+ -} s:'[+] траектория вращения объекта'),
 (i:$B023; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] поведение FOV камеры'),
 (i:$B024; d:'d'; c:'-'; o:'-'; p:SkipData;           {  -} s:'[+] поведение roll камеры'));

{******************************************************************************}
{********** процедуры для разбора внутренней логики файла и статистики ********}
{******************************************************************************}

procedure MarkChunk(w:word; len:longint); {вносит чанк в список использованных}
var i : integer;
begin
  i := 0;
  repeat
    inc(i);
  until (UsedChunks[i].n = w) or (UsedChunks[i].n = 0) or (i >= 256);
  if i >= 256 then begin
    if ToFile then
      writeln(t,'MarcChunk ERROR: Chunk List Overflow');
    if ToErrorFile then
      writeln(q,'MarcChunk ERROR: Chunk List Overflow',
              ' chunk = ',hex2str(w),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    halt;
  end;
  if UsedChunks[i].n = 0 then begin
    UsedChunks[i].n := w;
    UsedChunks[i].l := len;
 end;
end;

procedure MarkUnknownChunk(w:word); {отмечает использованный чанк как неопознанный}
var i : integer;
begin
  i := 0;
  repeat
    inc(i);
  until (UsedChunks[i].n = w) or (UsedChunks[i].n = 0) or (i >= 256);
  if i >= 256 then begin
    if ToFile then
      writeln(t,'MarcChunk: Chunk List Overflow');
    if ToErrorFile then
      writeln(q,'MarcChunk: Chunk List Overflow',
              ' chunk = ',hex2str(w),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    halt;
  end;
  if UsedChunks[i].n = 0 then begin
    if ToFile then
      writeln(t,'*** ERROR MarcUnknkwnChunk : chunk=0000 ***');
    if ToErrorFile then
      writeln(q,'*** ERROR MarcUnknkwnChunk : chunk=0000 ***',
              ' chunk = ',hex2str(w),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
  end;
  UsedChunks[i].b := TRUE;
end;

function GetChunkIndex(id:word):integer; {возвращает индекс чанка в массиве структур-характеристик}
var j,index :integer;
begin
  index := 0;
  for j := 0 to MaxNC do
    if ChunkDesc[j].i = id then
      index := j;
  GetChunkIndex := index;
end;

function Known(id:word):boolean;{сообщает, знаком ли программе этот тип блока}
begin
  Known := GetChunkIndex(id) <> 0;
end;

function IsData(id:word):boolean;{сообщает, содержит ли чанк данные}
begin
  IsData := ChunkDesc[GetChunkIndex(id)].d = 'd';
end;

function IsChunk(id:word):boolean;{сообщает, содержит ли чанк другие чанки}
begin
  IsChunk := ChunkDesc[GetChunkIndex(id)].o = 'o';
end;

procedure ReadChunkHeader(s:string);{читает заголовок чанка}
var
   i,j : integer;
begin
  deb2file('Read3DSfile *042* ',0);
  inc(NumChunkRead);
  Beg_Ofs := FilePos;
//       writeln(t,'     ReadChunkHeader 1 pos : ',l2str(Beg_ofs),' / ',l2str(FilePos));
  blockread(f,chunk,sizeof(chunk));     inc(FilePos,sizeof(chunk)); {читаем тип и длину}
  deb2file('Read3DSfile *043* ',0);
//       writeln(t,'     ReadChunkHeader 2 pos : ',l2str(Beg_ofs),' / ',l2str(FilePos),' ch: ',l2str(chunk));
  blockread(f,lch,sizeof(lch));         inc(FilePos,sizeof(lch));
//       writeln(t,'     ReadChunkHeader 3 pos : ',l2str(Beg_ofs),' / ',l2str(FilePos),' len: ',l2str(lch));
  MarkChunk(chunk,lch);
  if ToFile then begin
    write(t,s+'-'+hex2str(chunk)+' ');
    if length(s) < 30 then
      for i := length(s) to 29 do
        write(t,' ');
    if Known(chunk)   then write(t,'K') else write(t,'-');
    if IsData(chunk)  then write(t,'D') else write(t,'-');
    if IsChunk(chunk) then write(t,'O') else write(t,'-');
    if lf >= 65536 then
      write(t,' B:',Beg_ofs:8,'/',l2str(Beg_ofs),
        ' L:',lch:8,'/',l2str(lch),' E:',Beg_ofs+lch:8,'/',l2str(Beg_ofs+lch),' ')
    else
      write(t,' B:',Beg_ofs:5,'/',l2str(Beg_ofs),
        ' L:',lch:5,'/',l2str(lch),' E:',Beg_ofs+lch:5,'/',l2str(Beg_ofs+lch),' ');
    j := -1;
    for i := 0 to MaxNC do
      if Chunk = ChunkDesc[i].i then
        j := i;
    if j = -1 then
      writeln(t,'Unknown')
    else
      writeln(t,ChunkDesc[j].s);
  end;
end;

procedure dXXXX_common(s:string; PrevId:word); {общая процедура чтения блока}
var
  StartPos     : longint; {смещение в файле до начала чанка}
  CurrentId : word;
  CurrentLen : longint;
  j : integer;
  b : boolean;
  GDP : GetDataProc;
begin
  StartPos := FilePos-6;           { запоминаем старые параметры,}
  CurrentId := chunk;              {    чтобы не забыть их       }
  CurrentLen := lch;               {   при рекурсивных вызовах   }
  if not Known(chunk) then begin {пропускаем неопознанный блок}
    MarkUnknownChunk(chunk);
    SkipData(PrevId,lch);
  end else begin              {опознанный блок}
    j := GetChunkIndex(chunk);
    if (ChunkDesc[j].d = 'd') or (ChunkDesc[j].c = 'c') then  {есть данные или неименованный подблок}
      ChunkDesc[j].p(PrevId, lch);                {чтение данных}
    if (FilePos = (StartPos + lch)) = IsChunk(chunk) then begin
      if ToFile then
        writeln(t,'   *** ERROR length and data: Length Remain=',(StartPos + lch)-FilePos,' IsSubChunk=',IsChunk(chunk));
      if ToErrorFile then
        writeln(q,'   *** ERROR length and data: Length Remain=',(StartPos + lch)-FilePos,
              ' IsSubChunk=',IsChunk(chunk),
              ' chunk = ',hex2str(chunk),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ',
              ' FilePos=',FilePos,' StartPos=',StartPos,' lch=',lch);
    end;
    while FilePos < (StartPos + CurrentLen) do begin
      ReadChunkHeader(s+'-'+hex2str(CurrentId));
      dXXXX_common(s+'-'+hex2str(CurrentId), CurrentId);
    end;
  {+++++++++++++++++++ отладка ++++++++++++++++++++++++++}
//  if CurrentId = $4100 then
//    if Nobj3DS > 1 then
//      if random(2) = 1 then
//        DeleteObj3DS(random(Nobj3DS));
  {+++++++++++++++++++++++++++++++++++++++++}
    if FilePos <> (StartPos + CurrentLen) then begin
      if ToFile then
        writeln(t,'   *** ERROR length chunk: Current File ofs: ',FilePos,' Must be: ',StartPos + CurrentLen);
      if ToErrorFile then
        writeln(q,'   *** ERROR length chunk: Current File ofs: ',FilePos,' Must be: ',StartPos + CurrentLen,
              ' chunk = ',hex2str(chunk),' File Ofs:',Beg_ofs,'(',l2str(Beg_ofs),') ');
    end;
  end;
end;

{*************************************************************}
{******* главная процедура модуля доступная снаружи **********}
{*************************************************************}
procedure Read3DSfile(filename:string); {чтение файла 3DS}
var
  k,Count  : word;        {переменные для цикла и временного чтения}
  kk       : longint;     {счетчик цикла}
  pL       : ^TpL;        {}
  id1      : word;        {}
  len1     : longint;     {}
  tmpChunk : ChunkType;   {для сортировки чанков}
  FnameWOext : string;    {имя файла без расширения}
  m_1,m_2 : MatrixType;
  v : tDoubleVector;
begin
{инициализация переменных части реализации}
  NumChunkRead := 0;
  TargetPointer := nil;           {указатель на данные, которые скоро необходимо принять}
  Fillchar(UsedChunks,sizeof(UsedChunks),0); {список чанков, встретившихся в файле}
  deb2file('Read3DSfile *010* ',0);
  fillchar(TrackObj,sizeof(TrackObj),0);  { array[0..MaxObj-1]of TrackObjType; {дополнительный массив для анимации}
  NtrackObj     := 0;                   {количество объектов в дополнительном массиве}
{исполняющая часть}
  CreateMaterial(DefMaterial);  {материал по умолчанию на всякий случай}
//  inc(Nmater);
  deb2file('Read3DSfile *040* ',0);
  ReadChunkHeader(''); {инизиализирует chunk, lch, Beg_ofs}
{основная рекурсивная процедура разбора файла}
  deb2file('Read3DSfile *050* ',0);
  dXXXX_common('', 0);
  deb2file('Read3DSfile *060* ',0);
  close(f);
{выполнение финальных расчетов}
{---составление катры родитель-потомок}
  if ToFile then
    writeln(t,' количество временных объектов для отслеживания анимации:',NtrackObj);
  if NtrackObj > 0 then
    for k := 0 to NtrackObj-1 do begin
      if ToFile then
        if TrackObj[k].parent <> $ffff then begin
          writeln(t,'родитель-потомок: k=',k:4,' Main Object=',TrackObj[k].Main:4,' parent(k)',
              TrackObj[k].parent:6,' parent(MainObject)',TrackObj[TrackObj[k].parent].Main:4,' ',
              Obj3DS[TrackObj[k].Main].nm);
          Obj3DS[TrackObj[k].Main].parent := TrackObj[TrackObj[k].parent].Main;
        end else begin
          write(t,'родитель-потомок: k=',k:4,' Main Object=',TrackObj[k].Main:4,' parent(k)',
              TrackObj[k].parent:6,' No Parent! ');
          if TrackObj[k].Main >= 0 then
            writeln(t,Obj3DS[TrackObj[k].Main].nm)
          else
            writeln(t,' No Object! ');
        end;
    end;
{---проверка наличия материалов у объектов и приписывания материала по умолчанию, если нет---}
{---а также преобразование координат согласно матрицам перевода}
  deb2file('Read3DSfile *070* ',0);
  if Nobj3DS > 0 then
    for kk := 0 to Nobj3DS-1 do begin
{материалы}
      if ToFile then
        writeln(t,'проверка наличия материалов у объектов Nobj=',kk,' nf=',Obj3DS[kk].nf,' m0=',Obj3DS[kk].m0);
      if (Obj3DS[kk].nf > 0) and (Obj3DS[kk].m0 = -1) then begin
        Count := Obj3DS[kk].nf;
        inc(NfaceMat,Count);
        CreateMatObj(kk,longint(Count),DefMaterial);
        if ToFile then
          writeln(t,' Приписывание объекту ',kk,' материала по умолчанию ',CurMatObj);
        with MatObj[CurMatObj] do begin
          nf := Count;
          for k := 0 to Count-1 do begin
            pf^[k] := k;
          end;
        end; {with}
      end; {if Count}
{координаты}
{      if Obj3DS[kk].nv > 0 then
        with Obj3DS[kk] do begin
          m_1 := tm;
          k := kk;
          while Obj3DS[k].parent <> -1 do begin
            k := Obj3DS[k].parent;
            m_2  := Obj3DS[k].tm;
            m_1  := MulMatrix(m_1,m_2);
          end;
          for k := 0 to nv - 1 do begin
            v.x :=   pv^[k].x;
            v.y :=   pv^[k].y;  {переносим объект по марице}
{            v.z := - pv^[k].z;
            v := MatrVect(m_1,v);
            pv^[k].x :=   v.x;
            pv^[k].y :=   v.y;
            pv^[k].z := - v.z;{ здесь меняем знак оси Z для отобр OpenGL}
{          end; {for}
{        end; {with}
{}
    end; {for}
  if ToFile then begin
    writeln(t,'   --- Chunks ---');
    Count := 1;
    repeat   {определяем количество использованных чанков}
      inc(Count);
    until UsedChunks[Count].n = 0;
    writeln(t);
    for k := 2 to count-1 do        {сортируем массив чанков}
      for kk := count-1 downto k do
        if UsedChunks[kk].n < UsedChunks[kk-1].n then
          begin
            tmpChunk := UsedChunks[kk];
            UsedChunks[kk] := UsedChunks[kk-1];
            UsedChunks[kk-1] := tmpChunk;
          end;
    for k := 1 to count-1 do begin
      write(t,hex2str(UsedChunks[k].n),UsedChunks[k].l:8);
      if UsedChunks[k].b then
        write(t,'  ? ')
      else
        write(t,'    ');
      writeln(t,ChunkDesc[GetChunkIndex(UsedChunks[k].n)].s);
    end;
{подведение статистики по частоте встречаемости различных флагов граней}
    writeln(t,'   --- Face Flags ---');
    getmemF(pL,sizeof(pL^),' temp Face Flags ');
    fillchar(pL^,sizeof(pL^),0);
    for k := 0 to Nobj3DS-1 do
      with Obj3DS[k] do
        for kk := 0 to nf-1 do
          inc(pL^[pff^[kk]]);
    for kk := 0 to 65535 do
      if pL^[kk] <> 0 then
        writeln(t,kk:5,' ',w2b(kk),' ',pL^[kk]);
    freememF(pL,sizeof(pL^),' temp Face Flags ');
  end;
  deb2file('Read3DSfile *090* ',0);
end;

end.