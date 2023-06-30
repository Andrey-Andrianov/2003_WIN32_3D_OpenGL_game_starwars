unit getnorm1;
interface
uses windows;

procedure ReadModel(wnd:hwnd; name:string;tip:byte;  model:longint;scale:single);{чтение модели из файла с расчетов массивов для отображения}
procedure readmodeltexturs(wnd:hwnd);
//procedure ReadModel3(wnd:hwnd; name:string;tip:byte);{чтение модели из файла с расчетов массивов для отображения}
//procedure FreeTexures; {освобождение всех текстур из OpenGL}

implementation
uses read3d7c, deb_as, gl_draw1, comm_3d, {readlwo1,} readx;

type distarray = array[0..MaxPoints-1]of single;

const
  kol_objekts : longint = 0;

var
  VertexNormals : ^VectArrayType; { массив нормалей, посчитанных по Faces}
  Faces         : ^FaceArrayType; { массив считанных граней, переупорядоченный для отображения}
  FaceNormals3  : ^VectArrayType; { массив нормалей к Faces}
  DistSum       : ^distarray; {расстояния от вершин до центра граней}
//  scrange : single; {для масштабирования массивов для отображения ЩзутПД}

function VectTo1R( Vect : TRealVector; Var W : TRealVector): boolean;
Var  Len : single;
Begin
   Len := Sqrt( Sqr( Vect.X) + Sqr( Vect.Y) + Sqr( Vect.Z));
   if Len = 0 then begin
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
/////////////////////////////      writeln(t,'Длина нормализуемого вектора = 0');
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
//      W.X := 1;   W.Y := 0;   W.Z := 0;
      W.X := 0;   W.Y := 0;   W.Z := 0;
      VectTo1r := FALSE;
   end else begin
      W.X := Vect.X / Len;   W.Y := Vect.Y / Len;   W.Z := Vect.Z / Len;
      VectTo1r := TRUE;
   end;
End;

function GetDistance(NObj,NFac,Nver:longint):single; {расст. от точки до центра грани}
var
   dx,dy,dz : single;
   i1,i2,i3 : longint;
begin         {вычисл.квадрат расстояния}
  with obj3DS[NObj] do begin
    i1 := pf^[Nfac][1];
    i2 := pf^[Nfac][2];
    i3 := pf^[Nfac][3];
    dx := (pv^[i1].X + pv^[i2].X + pv^[i3].X)/3 - pv^[Nver].X;{}
//    dx := dx/3 - pv^[Nver].X;{}
{   dx := ((Points2^[ Faces2^[NF][1]].X + Points2^[ Faces2^[NF][2]].X + Points2^[ Faces2^[NF][3]].X)/3 - Points2^[NP].X);{}
    dy := (pv^[i1].Y + pv^[i2].Y + pv^[i3].Y)/3 - pv^[Nver].Y;{}
// dy := dy/3 - pv^[Nver].Y;{}
{   dy := ((Points2^[ Faces2^[NF][1]].Y + Points2^[ Faces2^[NF][2]].Y + Points2^[ Faces2^[NF][3]].Y)/3 - Points2^[NP].Y);{}
    dz := (pv^[i1].Z + pv^[i2].Z + pv^[i3].Z)/3 - pv^[Nver].Z;{}
//   dz := dz/3 - Points2^[NP].Z;{}
{   dz := ((Points2^[ Faces2^[NF][1]].z + Points2^[ Faces2^[NF][2]].Z + Points2^[ Faces2^[NF][3]].Z)/3 - Points2^[NP].Z);{}
   GetDistance := 1{sqrt}{(sqrt}{(sqrt(dx*dx + dy*dy + dz*dz)){){};
  end;
end;

Procedure CalcNormalVectorR(P1,P2,P3 : TRealVector;Var Normal : TRealVector);
Var Ax,Ay,Az,Bx,By,Bz : single;
Begin
   Ax := P2.X - P1.X;     Ay := P2.Y - P1.Y;     Az := P2.Z - P1.Z;
   Bx := P3.X - P1.X;     By := P3.Y - P1.Y;     Bz := P3.Z - P1.Z;
   Normal.X := (Ay * Bz) - (Az * By);
   Normal.Y := (Az * Bx) - (Ax * Bz);
   Normal.Z := (Ax * By) - (Ay * Bx);
End;

function binw(i:word):string; {convert word -> binary (string)}
var
   s : string;
   j : integer;
begin
   s[0] := #17;
   s[9] := ' ';
   for j := 0 to 7 do begin
      s[j+1] := char(byte('0') + ((i shr (15-j)) and 1));
      s[j+10] := char(byte('0') + ((i shr (7-j)) and 1));
   end;
   binw := s;
end;

Procedure CalcNormals2(Nobj:longint);
Var
  Nmat,Nfac,Nver,k,Counter : longint; {индексы по материалам, граням, вершинам, точкам грани}
  Dist0 : single;{}
  NewNF : longint; {количество граней после сокращения}
  fn4:Trealvector;
  NumZeroLen : longint; {количество векторов длиной 0}
//  LenNonZero : boolean; {факт, что вектор имеет ненулевую длину}
Begin
 { расчитываем нормали для каждой вершины }
  fillchar(VertexNormals^,Mpoints*sizeof(TRealVector),0);
  fillchar(DistSum^,      Mpoints*sizeof(single),0);
  with Obj3DS[Nobj] do begin
    if ToFile then
      writeln(t,'CalcNormals2 030');
    Nmat := m0;
    while Nmat <> -1 do {цикл по материалам - вычисление нормалей к граням}
      with MatObj[Nmat] do begin
        if ToFile then
          writeln(t,'CalcNormals2 обрабатывается материал ',Nmat,' ',nm);
        NewNF := 0;
        NumZeroLen := 0;
        for Nfac := 0 to nf-1 do begin {цикл по граням материала}
          Faces^[Nfac] := Obj3DS[Nobj].pf^[pf^[Nfac]];
          with Obj3DS[Nobj] do
            CalcNormalVectorR( pv^[ Faces^[Nfac][1]], {нормаль к грани}
                               pv^[ Faces^[Nfac][2]],
                               pv^[ Faces^[Nfac][3]], FaceNormals3^[Nfac]);
          if VectTo1R(FaceNormals3^[Nfac],FaceNormals3^[Nfac]) then begin
            for k := 1 to 3 do begin {перебираем вершины грани}
              Nver := Faces^[Nfac][k]; {номер одной из 3-х точек грани}
 { расчитываем нормали для вершины }
              Dist0 := 1/GetDistance(Nobj,Nfac,Nver);
 {проверяем, что нормали не противоположны (случай разнонаправленных граней)}
 {   ^  }     if (abs(VertexNormals^[Nver].X + FaceNormals3^[Nfac].X * Dist0)
 {  / \ }       + abs(VertexNormals^[Nver].Y + FaceNormals3^[Nfac].Y * Dist0)
 { /   \}       + abs(VertexNormals^[Nver].Z + FaceNormals3^[Nfac].Z * Dist0)) > 0.001 then
              begin
                 VertexNormals^[Nver].X := VertexNormals^[Nver].X + FaceNormals3^[Nfac].X * Dist0;
                 VertexNormals^[Nver].Y := VertexNormals^[Nver].Y + FaceNormals3^[Nfac].Y * Dist0;
                 VertexNormals^[Nver].Z := VertexNormals^[Nver].Z + FaceNormals3^[Nfac].Z * Dist0;
                 DistSum^[Nver] := DistSum^[Nver] + Dist0;
              end;
            End;
            if NewNF <> Nfac then begin{если надо, то "сжимаем" массив}
              Faces^[NewNF]        := Faces^[Nfac];
              FaceNormals3^[NewNF] := FaceNormals3^[Nfac];
            end;
            inc(NewNF);
          end else begin  {if VectTo1R(FaceNormals3}
            if ToFile then
              writeln(t,'  * Face ',Nfac,' between ',NewNF-1,' and ',NewNF,' passed MatObj[',
                    Nmat,']: ',MatObj[Nmat].nm,' Obj3DS[',Nobj,']: ',Obj3DS[Nobj].nm);
            inc(NumZeroLen);
          end;            {if VectTo1R(FaceNormals3}
        end; {for Nfac}
        if nf <> NewNF then
          if ToFile then
            writeln(t,'  ** Сокращено ',nf-NewNF,' граней MatObj[',Nmat,']: ',MatObj[Nmat].nm,
                                    ' Obj3DS[',Nobj,']: ',Obj3DS[Nobj].nm);
        nvn := NewNF*3;
        if ToFile then
          writeln(t,'CalcNorm: nf=',nf,' NewNF=',NewNF,' nvn=',nvn,' MatObj[',Nmat,']: ',MatObj[Nmat].nm,
            ' Obj3DS[',Nobj,']: ',Obj3DS[Nobj].nm,' нулевых нормалей к граням:',NumZeroLen);
        if NumZeroLen > 0 then
          if ToFile then
            writeln(t,'  *** CalcNormals2 Обнаружено ',NumZeroLen,
                 ' нулевых нормалей к граням, материал: ',Nmat,' ',nm);
{сюда вставлять все, что связано с расчетом для текущего материала}
        getmemF(pvf,nvn*sizeof(TRealVector),' MatObj.pvf ');
        getmemF(pvn,nvn*sizeof(TRealVector),' MatObj.pvn ');
        getmemF(pnf,nvn*sizeof(TRealVector),' MatObj.pnf ');
        NumZeroLen := 0;
        for Nfac := 0 to NewNF-1 do begin
          for k := 1 to 3 do begin         { !!! массивы для отображения масштабируем !!! }
//            pvf^[Nfac*3 + k - 1].x :=  pv^[Faces^[Nfac][k]].x / scrange;
//            pvf^[Nfac*3 + k - 1].y :=  pv^[Faces^[Nfac][k]].y / scrange;
//            pvf^[Nfac*3 + k - 1].z :=  pv^[Faces^[Nfac][k]].z / scrange;

            pvf^[Nfac*3 + k - 1] :=  pv^[Faces^[Nfac][k]];

            if not VectTo1R(VertexNormals^[Faces^[Nfac][k]],VertexNormals^[Faces^[Nfac][k]]) then
              inc(NumZeroLen);
            pvn^[Nfac*3 + k - 1] := VertexNormals^[Faces^[Nfac][k]];
            pnf^[Nfac*3 + k - 1] := FaceNormals3^[Nfac];{  VertexNormals^[Faces^[Nfac][3]];}
          end;{}
{          pvf^[Nfac*3    ] := pv^           [Faces^[Nfac][1]];
          pvf^[Nfac*3 + 1] := pv^           [Faces^[Nfac][2]];
          pvf^[Nfac*3 + 2] := pv^           [Faces^[Nfac][3]];
             VectTo1R(VertexNormals^[Faces^[Nfac][1]],VertexNormals^[Faces^[Nfac][1]]);
          pvn^[Nfac*3    ] := VertexNormals^[Faces^[Nfac][1]];
             VectTo1R(VertexNormals^[Faces^[Nfac][2]],VertexNormals^[Faces^[Nfac][2]]);
          pvn^[Nfac*3 + 1] := VertexNormals^[Faces^[Nfac][2]];
             VectTo1R(VertexNormals^[Faces^[Nfac][3]],VertexNormals^[Faces^[Nfac][3]]);
          pvn^[Nfac*3 + 2] := VertexNormals^[Faces^[Nfac][3]];
{          pnf^[Nfac*3 + 2] := FaceNormals3^[Nfac];{  VertexNormals^[Faces^[Nfac][3]];}
        end;
        if NumZeroLen > 0 then
          if ToFile then
            writeln(t,'  **** CalcNormals2 Обнаружено ',NumZeroLen,' нулевых нормалей в вершинах, материал: ',
                  Nmat,' ',nm);
        NumZeroLen := 0;
        if (Material[im].dx > 0) and (nt > 0) then begin
          getmemF(ptf,nvn*sizeof(TtextC),' MatObj.ptf ');
          deb2file('CalcNorm: NewNF ',NewNF);
          deb2file('CalcNorm: nvn ',nvn);
          ntf := nvn;
          for Nfac := 0 to NewNF-1 do begin
            if Nfac > Mfaces then begin
              deb2file('CalcNorm: !!! ERROR !!! Nfac=',Nfac);
              deb2file('CalcNorm: !!! ERROR !!! Mfaces=',Mfaces);
            end;
            if Faces^[Nfac][1] > nt then begin
              deb2file('CalcNorm: !!! ERROR !!! Faces^[Nfac][1]=',Faces^[Nfac][1]);
              deb2file('CalcNorm: !!! ERROR !!! nt=',nt);
            end;
//              writeln(t,'NewNF=',NewNF,' nvn=',nvn,' Nfac=',Nfac,' Mfaces=',Mfaces,
//                 ' Faces^[Nfac][1]=',Faces^[Nfac][1],' nt=',nt);
            ptf^[Nfac*3    ] :=
                                pt^[Faces^[Nfac][1]];
            ptf^[Nfac*3 + 1] := pt^[Faces^[Nfac][2]];
            ptf^[Nfac*3 + 2] := pt^[Faces^[Nfac][3]];
          end;
        end else begin
          if ToFile then
            writeln(t,'CalcNorm: No Texture Load - nt=',nt,' NewNF=',NewNF);
        end;
        Nmat := nx;  {переходим к следующему материалу в списке}
      end; {with - cycle by material}
    Counter := 0;
    NumZeroLen := 0;
    if ToFile then
      writeln(t,'CalcNormals2 подсчет точек, не входящих в грани');
    For Nver := 0 to nv-1 Do {подсчет точек, не входящих в грани}
      if DistSum^[Nver] > 0 then begin
        if not VectTo1R(VertexNormals^[Nver],VertexNormals^[Nver]) then
          inc(NumZeroLen);
      end else begin
        inc(Counter);
        if ToFile then
          writeln(t,'Точка ',Nver,' не входит ни в одну грань Obj3DS[',Nobj,']: ',Obj3DS[Nobj].nm);
      end;
    if ToFile then
      writeln(t,' Не используется ',Counter,' точек, из остальных ',NumZeroLen,
        ' имеют нулевые нормали, Obj3DS[',Nobj,']: ',Obj3DS[Nobj].nm);
    NumZeroLen := 0;
  end; {with Obj3DS}
End;

procedure ReadModel(wnd:hwnd; name:string;tip:byte;  model:longint;scale:single);{чтение модели из файла с расчетов массивов для отображения}
var
  Nver,Nobj,NewNF,Nmat,k : longint;
  ch : char;
  scrange : single;
begin
{обработка имени файла и открытие файлов протокола}
  deb2file('ReadModel: *000* '+name+' ',0);
  FnameInput    := name;       {имя читаемого файла }
  k := pos('.',name);
  if k > 0 then begin
    ch := name[k+1];
    delete(name,k+1,length(name)-k);
  end;
  FnameReport   := name+'rp'+ch;       {имя файла протокола}
  FnameError    := name+'re'+ch;       {имя файла для сообщений об ошибках}
  Assign(f,FnameInput);                        {файл .3DS}
  {$I-}
  reset(f,1);
  {$I+}
  if ioresult <> 0 then exit;
  lf := filesize(f);                         {длина файла}
  FilePos := 0;                              {позиция в файле}
//  NumChunkRead := 0;
//  TargetPointer := nil;           {указатель на данные, которые скоро необходимо принять}
//  Fillchar(UsedChunks,sizeof(UsedChunks),0); {список чанков, встретившихся в файле}
  deb2file('ReadModel file: '+FnameInput+' size: ',lf);
//  ChangeListMode{(ListMode)}; {изменение режима ведения протокола}
  if ToFile then begin
    assign(t,FnameReport);                { : text;  файл протокола}
    rewrite(t);
    writeln(t,'   File: ',FnameInput,'  Length: ',lf);
    writeln(t,'   File: ',FnameReport);
  end;
  deb2file('ReadModel *020* ',0);
  if ToErrorFile then begin
    assign(q,FnameError);                { : text;  файл протокола ошибок}
    rewrite(q);
  end;
  DebFileOpened := TRUE;
{чтение файла}
  deb2file('ReadModel: *020* '+name+' ',0);
(*  case UpCase(name[pos('.',name)+1]) of
    '3'{.3DS} : Read3DSfile(name); {звҐ­ЁҐ ¬ ббЁў®ў ўҐаиЁ­ Ё Ја ­Ґ©}
    'L'{.LWO} : ReadLWOfile(name); {звҐ­ЁҐ ¬ ббЁў®ў ўҐаиЁ­ Ё Ја ­Ґ©}
    'X'{.X  } : ReadXfile(name); {звҐ­ЁҐ ¬ ббЁў®ў ўҐаиЁ­ Ё Ја ­Ґ©}
  end; {case}
                                             *)
  if tip = 1 then
    Read3DSfile(name); //else
  if tip = 2 then
    ReadXfile(name);


(*  for Nmat := 0 to Nmater-1 do
    with Material[Nmat] do
      if nt <> '' then
        GLD_LoadTexture(wnd, dx, dy, bp, dlst, pt, nt{'commands.dds'});*)

  deb2file('ReadModel: after Read3DSfile Mfaces=',Mfaces);
  for Nmat := 0{kol_objekts} to Nmater-1 do
    with Material[Nmat] do begin
      deb2file('ReadModel: Loadtexture: '+nt+' Material:',Nmat);
      if nt <> '' then begin
        GLD_LoadTexture(wnd, dx, dy, bp, dlst, pt, nt{'commands.dds'});
        if ToFile then begin
          writeln(t,'    загружена текстура '+nt+'- size: ',dx,'x',dy,'x',bp);{}
        end;{}
      end;
    end;
  deb2file('ReadModel: after LoadTexture Mfaces=',Mfaces);

  if ToFile then begin
    writeln(t,'All right');
    writeln(t,' Вершин:',Npoints,' Граней:',Nfaces);
  end;
{масштабирование}
  MinBB_X := 1.e+30; MaxBB_X := -1.e+30;
  MinBB_Y := 1.e+30; MaxBB_Y := -1.e+30;
  MinBB_Z := 1.e+30; MaxBB_Z := -1.e+30;
  for Nobj := {0}kol_objekts to Nobj3DS-1 do
    with Obj3DS[Nobj] do
      for Nver := 0 to nv-1 do begin
        if MinBB_X > pv^[Nver].X then MinBB_X := pv^[Nver].X;
        if MaxBB_X < pv^[Nver].X then MaxBB_X := pv^[Nver].X;
        if MinBB_Y > pv^[Nver].Y then MinBB_Y := pv^[Nver].Y;
        if MaxBB_Y < pv^[Nver].Y then MaxBB_Y := pv^[Nver].Y;
        if MinBB_Z > pv^[Nver].Z then MinBB_Z := pv^[Nver].Z;
        if MaxBB_Z < pv^[Nver].Z then MaxBB_Z := pv^[Nver].Z;
      end;
  MaxDistance := 4*sqrt(sqr(MaxBB_X - MinBB_X) + sqr(MaxBB_Y - MinBB_Y) + sqr(MaxBB_Z - MinBB_Z));
  Distance := MaxDistance / 2.0;
  if ToFile then begin
    writeln(t,' Distance = ',Distance,', MaxDistance = ',MaxDistance,' Object Geom Parameters:');
    writeln(t,'          Min         Max       Center       Size ');
    writeln(t,' X ',MinBB_X:12:4,MaxBB_X:12:4,(MaxBB_X + MinBB_X)/2.0:12:4,MaxBB_X - MinBB_X:12:4);
    writeln(t,' Y ',MinBB_Y:12:4,MaxBB_Y:12:4,(MaxBB_Y + MinBB_Y)/2.0:12:4,MaxBB_Y - MinBB_Y:12:4);
    writeln(t,' Z ',MinBB_Z:12:4,MaxBB_Z:12:4,(MaxBB_Z + MinBB_Z)/2.0:12:4,MaxBB_Z - MinBB_Z:12:4);
    writeln(t,'Определение масштаба закончено MaxDistance=',MaxDistance:8:3);
  end;


  scrange := sqrt(sqr(MaxBB_X - MinBB_X) + sqr(MaxBB_Y - MinBB_Y) + sqr(MaxBB_Z - MinBB_Z))/2/scale{6};

  for Nobj := {0}kol_objekts to Nobj3DS-1 do
    with Obj3DS[Nobj] do
      for Nver := 0 to nv-1 do begin
        pv^[Nver].X := (pv^[Nver].X - ({scx1 + scx0}MaxBB_X + MinBB_X)/2/scale)/scrange;
        pv^[Nver].Y := (pv^[Nver].Y - ({scy1 + scy0}MaxBB_Y + MinBB_Y)/2/scale)/scrange;
        pv^[Nver].Z := (pv^[Nver].Z - ({scz1 + scz0}MaxBB_Z + MinBB_Z)/2/scale)/scrange;
      end;

  kol_objekts_models[model] := kol_objekts;
  kol_objekts := Nobj3DS;
  kol_objekts_models[model+1] := kol_objekts;


  getmemF ( Faces,         Mfaces*sizeof(FaceType),    ' ReadModel Faces         ');
  getmemF ( VertexNormals, Mpoints*sizeof(TRealVector),' ReadModel VertexNormals ');
  getmemF ( FaceNormals3,  Mfaces*sizeof(TRealVector), ' ReadModel FaceNormals3  ');
  getmemF ( DistSum,       Mpoints*sizeof(single),     ' ReadModel DistSum       ');
  for Nobj := 0 to Nobj3DS-1 do begin
    if ToFile then
      writeln(t,'Вычисление нормалей для объекта ',Nobj);
    CalcNormals2(Nobj);
    if ToFile then
      writeln(t,'Закончено вычисление нормалей для объекта ',Nobj);
  end;
  freememF( DistSum,       Mpoints*sizeof(single),     ' ReadModel DistSum       ');
  freememF( FaceNormals3,  Mfaces*sizeof(TRealVector), ' ReadModel FaceNormals3  ');
  freememF( VertexNormals, Mpoints*sizeof(TRealVector),' ReadModel VertexNormals ');
  freememF( Faces,         Mfaces*sizeof(FaceType),    ' ReadModel Faces         ');
  deb2file('ReadModel: after CalcNormals2     ',0);
  PrintStat;
  DebFileOpened := FALSE;

  if ToFile then begin
    writeln(t,'All right');
    close(t);          {закрываем и открываем файл, чтобы сбросить буфера}
  end;
  if ToErrorFile then begin
    close(q);
  end;
end;


procedure readmodeltexturs(wnd:hwnd);
var
  i,j : integer;
begin
  for {Nmat}i := 0{kol_objekts} to Nmater-1 do
    with Material[{Nmat}i] do begin
      deb2file('ReadModel: Loadtexture: '+nt+' Material:',{Nmat}i);
      if nt <> '' then begin
        GLD_LoadTexture(wnd, dx, dy, bp, dlst, pt, nt{'commands.dds'});
        if ToFile then begin
          writeln(t,'    загружена текстура '+nt+'- size: ',dx,'x',dy,'x',bp);{}
        end;{}
      end;
    end;
end;

end.