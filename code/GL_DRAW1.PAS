unit gl_draw1; {отображение на экран с помощью OpenGL}
interface
uses Windows, Messages, OpenGL, deb_as, rd_btmp0, comm_3d, MatrTrns, matrx_wd;

const
  WhiteMaterial : boolean = FALSE;
  IsTexture     : boolean = TRUE;
  TilingTexture : boolean = FALSE;
  ModeFace      : longint = 1;    {1 - лицевые, 2 - нелицевые, 3 - все}
  ModeMaterial  : longint = 3;    {1 - исходный. 2 - белый. 3 - под тексттурой}
  ModeMatSpot   : boolean = {TRUE}false; {блик}
  ModeTexture   : longint = 1;    {1 - исходная, 2 - сетка, 3 - нет}
  ModeTxtrDecal : boolean = FALSE; {плоская(decal)}
  ModeShape     : longint = 1;    {1 - сглаженый, 2 - граненый, 3 - каркас1}
  ModeTranspar  : longint = 1;    {1 - нормальная, 2 - не рисовать, 3 - непрозрачные}
  TimeBeg : longint = -1; {время первого вызова GLD_Draw}
  TimeEnd : longint = -1; {время последнего вызова GLD_Draw}
  NumDraw : longint = 0;  {количество вызовов GLD_Draw}
  MaxDistance : single = 100; {граница заднего отсечения OpenGL}
var
  MinBB_X,MaxBB_X,MinBB_Y,MaxBB_Y,MinBB_Z,MaxBB_Z : double; {для опр.границ и масштабирования}
  kol_objekts_models : array[0..40]of longint;
  Nlist  : longint;                     {количество  дисплейных листов}

procedure CheckGlError(s:string; i:longint); {проверка ошибок и вывод в файл}
procedure OGL_CenterToObject; // центририрование по объекту
procedure GLD_Destroy(dc : hdc);  {завершает работу OpenGL}
procedure GLD_Resize(MainWindow : hwnd); {сообщаем OpenGL, что размеры окна изменились}
procedure GLD_Draw(dc: HDC;model:longint;x,y,z,AngleX,AngleY : GLFloat); {рисует OGL-сцену при перерисовке экрана}
procedure GLD_PrepParams(dc : hdc); {предварительная инициализация нужных режимов}
procedure GLD_LoadTexture(wnd : hwnd; var dx,dy,ColDep,list: longint; var p : pointer;
     filename:string);{dx,dy,ColDep - разм.и глуб.цвета, list - диспл.список, p - адрес}
procedure GLD_FreeAllTextures; {освобождает все списки с текстурами}

implementation
uses strings;
type
  DistMatObjType = record
    d : longint; {индикатор: 1 - прозрачность, 2 - блик, 3 - оба}
    m : longint; {номер материала объекта}
    l : single;  {расстояние}
  end;
  ListType = record
    nm         : string;   {имя файла с текстурой}
    l,dx,dy,cd : longint;  {дисплейный лист, размеры, глубина цвета}
    p          : pointer;  {указатель на текстуру}
  end;
var
  HRC           : HGLRC;
  PolygonMode   : word;
  FlatFace      : boolean;
  MO23    : array[0..MaxMatObj-1]of DistMatObjType; {список материалов прозрачных и с бликами }
  NMO23   : longint;
  ListArray : array[0..63]of ListType;  {список дисплейных листов}
//  Nlist  : longint;                     {количество  дисплейных листов}
const
  LightAmbient:  Array [0..3] Of GLfloat = (0.0, 0.0, 0.0, 1.0);
  LightDiffuse:  Array [0..3] Of GLfloat = (0.7, 0.7, 0.7, 1.0);
  LightSpecular: Array [0..3] Of GLfloat = (0.9, 0.9, 0.9, 1.0);
  LightPosition: Array [0..3] Of GLfloat = (0.0, 0.0, 2.0, 1.0);

  lmodel_ambient  : array[0..3] of GLfloat = ( 0.2, 0.2, 0.2, 1.0 );
  WhiteC      : colortype = (r:1.0; g:1.0; b:1.0; a:1.0);
  BlackC      : colortype = (r:0.0; g:0.0; b:0.0; a:1.0);
  BlackTransp : colortype = (r:0.0; g:0.0; b:0.0; a:0.0);

{$ifdef __TMT__}
const opengl32 = opengl32dll;
{$ENDIF}
{const
  GL_VERTEX_ARRAY         = $8074;
  GL_TEXTURE_COORD_ARRAY  = $8078;}
procedure glVertexPointer (size: GLint; atype: GLenum; stride: GLsizei; data: pointer); stdcall; external OpenGL32;
procedure glNormalPointer (atype: GLenum; stride: GLsizei; data: pointer); stdcall; external OpenGL32;
procedure glColorPointer  (size: GLint; atype: GLenum; stride: GLsizei; data: pointer); stdcall; external OpenGL32dll;{}
procedure glDrawArrays    (mode: GLenum; first: GLint; count: GLsizei); stdcall; external OpenGL32;{}
procedure glEnableClientState (aarray: GLenum);                            stdcall; external OpenGL32;{}
procedure glDisableClientState (aarray: GLenum);                           stdcall; external OpenGL32;{}
procedure glArrayElement (index: GLint);                                   stdcall; external OpenGL32;{}

procedure glDrawElements(mode : GLenum; count : GLsizei; types : GLenum; indices : Pointer); stdcall; external opengl32;
procedure glTexCoordPointer(size : GLint; types : GLenum; stride : GLsizei; ptr : Pointer); stdcall; external opengl32;


procedure CheckGlError(s:string; i:longint); {проверка ошибок и вывод в файл}
var  n,m : longint;
begin
  m := 3;
  repeat
    n := glGetError;
    if n <> GL_NO_ERROR then
      deb2file('! gl ERROR !!! ' + s + ' ' + strpas(gluErrorString(n)) + ' ',i);
    dec(m);
  until (n = GL_NO_ERROR) or (m = 0);
end;

procedure OGL_CenterToObject; // центририрование по объекту
begin
  MT_ResetMatrix;                  // приводит текущую к единичной
  MT_MoveCenterC(-(MinBB_X+MaxBB_X)/2.0,-(MinBB_Y+MaxBB_Y)/2.0,-(MinBB_Z+MaxBB_Z)/2.0);// перемещение центра вращения
end;

procedure GLD_Resize(MainWindow:hwnd);
var Wid,Hei : longint;
  rect: TRect;
begin
    CheckGlError('GLResize:begin',0);
      // Reset The Current Viewport And Perspective Transformation
  GetClientRect(MainWindow, rect);
  glViewport(0, 0, rect.right - rect.left + 1, rect.bottom - rect.top + 1);
    CheckGlError('GLResize:Viewport',rect.right - rect.left + 1);
  glMatrixMode(GL_PROJECTION);
    CheckGlError('GLResize:MatrixMode(PROJECTION)',0);
  glLoadIdentity;
    CheckGlError('GLResize:LoadIdentity',0);
  gluPerspective(30.0, (rect.right - rect.left + 1) / (rect.bottom - rect.top + 1),
                                        0.01*MaxDistance, MaxDistance);
    CheckGlError('GLResize:Perspective',0);
  glMatrixMode(GL_MODELVIEW);
    CheckGlError('GLResize:MatrixMode(MODELVIEW)',round(MaxDistance));
end;

procedure GLD_LoadTexture(wnd : hwnd; var dx,dy,ColDep,list: longint; var p : pointer; filename:string);
type ab = array[0..1024*1024*3-1] of byte;
     pb = ^ab;
const RGBtype : array[3..4]of longint = (GL_RGB,GL_RGBA);
var
   i,b : longint;
begin
  b := -1;
  if Nlist > 0 then
    for i := 0 to Nlist-1 do
      if filename = ListArray[i].nm then
        b := i;
  if b = -1 then begin {новая текстура}
    RecodeAndReadTextureFile(wnd, dx, dy, ColDep, p, filename);
    if dx <> 0 then begin
      for i := 0 to dx*dy-1 do begin {swap colors}
        b := pb(p)^[i*ColDep];
        pb(p)^[i*ColDep] := pb(p)^[i*ColDep+2];
        pb(p)^[i*ColDep+2] := b;
      end;
      list :=glgenlists(1);
      glnewlist(list, GL_compile);
      glteximage2d(gl_texture_2d, 0, ColDep, dx, dy, 0, RGBtype[ColDep], GL_unsigned_byte, p);
      CheckGlError('LoadTexture: glteximage2d ',list);
      glendlist;
      deb2file('LoadTexture: texturte display list: ',list);
    end;
    CheckGlError('LoadTexture: !!! ERROR !!! list=',list);
    deb2file('LoadTexture: texture pointer: ',dword(p));
    freememF(p,dx*dy*ColDep,'ReadTexture - after use ');
    deb2file('LoadTexture: free memory: ',dx*dy*ColDep);
    p := nil;
    ListArray[Nlist].nm := filename;
    ListArray[Nlist].l  := list;
    ListArray[Nlist].dx := dx;
    ListArray[Nlist].dy := dy;
    ListArray[Nlist].cd := ColDep;
    ListArray[Nlist].p  := p;
    inc(Nlist);
  end else begin {текстура уже есть в списке}
    deb2file('LoadTexture: use existence list: ',list);
    list   := ListArray[b].l;
    dx     := ListArray[b].dx;
    dy     := ListArray[b].dy;
    ColDep := ListArray[b].cd;
    p      := ListArray[b].p;
  end;{if b = -1}
end;

procedure GLD_FreeAllTextures; {освобождает все спискм с текстурами}
var i : longint;
begin
  deb2file('GLD_FreeAllTextures Nmater=',Nmater);
    CheckGlError('FreeAllTextures:begin',0);

//  fillchar(ListArray[i],sizeof(ListArray[i]),-1);
//  for i := 0 to Nlist-1 do
//    if ListArray[i].l <> -1 then begin
//      ListArray[i].l := -1;
//      ListArray[i].nt := '';
//    end;
//    Nmater := 0;
  for i := 0 to Nlist-1 do
    if ListArray[i].l <> -1 then begin
      deb2file('GLD_FreeAllTextures List: ',ListArray[i].l);
      glDeleteLists(ListArray[i].l, 1);
      CheckGlError('GLD_FreeAllTextures      : ',ListArray[i].l);
    end;
  Nlist := 0;
end;

procedure GLD_Destroy(dc : hdc);
var i : integer;
begin
    CheckGlError('GLDestroy:begin',0);
  wglMakeCurrent (dc, 0); // перед завершением работы необходимо,
                          // чтобы контекст никем не использовался
    CheckGlError('GLDestroy:MakeCurrent (dc, 0)',0);
  deb2file(' PGLP:Destroy-CurCn: MakeCurrent (dc, 0) ',wglGetCurrentContext);
  wglDeleteContext(HRC);
    CheckGlError('GLDestroy:DeleteContext',0);
  deb2file(' PGLP:Destroy-DlCon ',0);
  TimeEnd := GetTickCount; {время последнего вызова GLD_Draw}
  deb2file(' PGLP:Destroy Work Time: ',TimeEnd-TimeBeg);
  deb2file(' PGLP:Destroy Numb.Draw: ',NumDraw);
end;

procedure DrawMatObj(Nmat:longint; ca,cd,cs : pointer; sh : single; im : longint);
//var i : longint;
begin
  with MatObj[Nmat] do begin
    glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, ca{}{PGLfloat(@Material[i].Ambi){});  // Reflective properties
      CheckGlError('GLDraw:Material(AMBIENT)',NumDraw);
    glMaterialfv (GL_FRONT_AND_BACK, GL_DIFFUSE, cd{}{PGLfloat(@Material[i].Diff){});  // Reflective properties
      CheckGlError('GLDraw:Material(DIFFUSE)',NumDraw);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, cs{}{PGLfloat(@Material[i].Spec){});  // Reflective properties
      CheckGlError('GLDraw:Material(SPECULAR)',NumDraw);
    glMaterialf  (GL_FRONT_AND_BACK, GL_SHININESS, sh{Material[i].SHIN});  // Reflective properties
      CheckGlError('GLDraw:Material(SHININESS)',round(sh{Material[i].SHIN}));

    if IsTexture then begin
//      deb2file('DrawMatObj im=',im);
//      deb2file('DrawMatObj Material[im].dlst',Material[im].dlst);

      gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_linear}gl_nearest);
        CheckGlError('GLDraw:texparameteri 1 ',0);
      gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_linear}gl_nearest);
        CheckGlError('GLDraw:texparameteri 2 ',0);
{      if TilingTexture then begin
        gltexparameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
        gltexparameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
      end else begin
        gltexparameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);
        gltexparameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);

        glTexParameterfv(GL_TEXTURE_2D,GL_TEXTURE_BORDER_COLOR,@BlackTransp);
      end;}
        CheckGlError('GLDraw:texparameteri 3 ',longint(TilingTexture));
      glhint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
        CheckGlError('GLDraw:glhint',0);

      if not glIsList(glint(Material[im].dlst)) then begin
        deb2file('GLDraw: no such list, Nmat:     ',Nmat);
        deb2file('GLDraw: no such list, im:       ',im);
        deb2file('GLDraw: no such list, im(Nmat): ',MatObj[Nmat].im);
        deb2file('GLDraw: no such list, list:     ',Material[im].dlst);
        deb2file('GLDraw: no such list, im.dx:    ',Material[im].dx);
        deb2file('GLDraw: no such list, IsTexture ',longint(IsTexture));
      end;
      glcalllist(glint(Material[im].dlst));
        CheckGlError('GLDraw:calllist',Material[im].dlst);
      glEnable (gl_texture_2d);
      glEnableClientState (GL_TEXTURE_COORD_ARRAY_EXT);
        CheckGlError('GLDraw:EnableClientState (GL_TEXTURE_COORD_ARRAY) ',NumDraw);
      if ModeTxtrDecal then
        glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL)
      else
        glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);
          CheckGlError('GLDraw:TexEnv',NumDraw);
      glTexCoordPointer{EXT}(2,GL_FLOAT,0,ptf);
        CheckGlError('GLDraw:TextureMode',NumDraw);
    end;
{******************************}
//        glBegin(GL_TRIANGLES);
//        For I := 0 To nvn-1 Do Begin
//           glNormal3fv(@(pvn^[i]));
//           glVertex3fv(@(pvf^[i]));
//        End;

//        glEnd;
{******************************}
    glVertexPointer (3, GL_FLOAT, 0, pvf);{}
      CheckGlError('GLDraw:VertexPointer',NumDraw);

    if FlatFace then
      glNormalPointer (GL_FLOAT, 0, pnf)
    else
      glNormalPointer (GL_FLOAT, 0, pvn);
        CheckGlError('GLDraw:NormalPointer',NumDraw);

    glEnableClientState (GL_VERTEX_ARRAY_EXT);{}
    glEnableClientState (GL_NORMAL_ARRAY_EXT);{}
      CheckGlError('GLDraw:EnableClientState',NumDraw);

    glDrawArrays (GL_TRIANGLES, 0, nvn);{glDrawArraysExt}
      CheckGlError('GLDraw:DrawArrays',NumDraw);

    glDisableClientState (GL_TEXTURE_COORD_ARRAY_EXT);
    glDisable(gl_texture_2d);
    glDisableClientState (GL_NORMAL_ARRAY_EXT);{}
    glDisableClientState (GL_VERTEX_ARRAY_EXT);{}
      CheckGlError('GLDraw:Disable',NumDraw);
  end;{with}
end;

procedure GLD_Draw(dc: HDC;model:longint;x,y,z,AngleX,AngleY : GLFloat);{рисует OGL-сцену при перерисовке экрана}
//const
//  WhiteC : colortype = (r:1;g:1;b:1;a:1);
//  BlackC : colortype = (r:0;g:0;b:0;a:1);
var
  Nobj,Nmat,i,j : longint;
  m1       : matrixType;
  v1       : TDoubleVector;
  ca,cd,cs : colortype;
  TmpDMO : DistMatObjType;
begin
  glTranslatef(x,y, z);                                          // Polygon depth
  glRotatef(Anglex{+180}, 0.0, 1.0, 0.0);
  glRotatef(-Angley{+90}, 1.0, 0.0, 0.0);
//  glRotatef(180, 0.0, 1.0, 0.0);
//  glRotatef(-90, 1.0, 0.0, 0.0);



    CheckGlError('GLDraw:begin',NumDraw);
  if NumDraw = 0 then
    TimeBeg := GetTickCount; {время первого вызова GLD_Draw}
  inc(NumDraw);
  NMO23 := 0;

//  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT); // Clear color & depth buffers
    CheckGlError('GLDraw:Clear(BUFFER)',0);
  MT_CalcCurrent;                               // внесение накопленных за кадр изменений
  v1.x := 0; v1.y := 0; v1.z := -Distance;
  m1 := MulMatrix(MT_GetMatrix,MoveMatr(v1));                 // финальный отъезд
//  glLoadMatrixd(@m1);{}
    CheckGlError('GLDraw:LoadMatrix',0);

//  glShadeModel(ShadeMode{GL_FLAT{GL_SMOOTH});   // Smooth color shading
//    CheckGlError('GLDraw:ShadeModel',0);
  case ModeFace of
    1: begin             // лицевые грани
      glEnable (GL_CULL_FACE);{}
        CheckGlError('GLDraw:Enable(CULL_FACE)',0);
      glCullFace(GL_BACK);
        CheckGlError('GLDraw:CULL_FACE',0);
    end;
    2: begin             // нелицевые грани
      glEnable (GL_CULL_FACE);{}
        CheckGlError('GLDraw:Enable(CULL_FACE)',0);
      glCullFace(GL_FRONT);
        CheckGlError('GLDraw:CULL_FACE',0);
    end;
    3: begin             // все грани
      glDisable (GL_CULL_FACE);{}
        CheckGlError('GLDraw:Enable(CULL_FACE)',0);
    end;
  end; {case ModeFace}
  case ModeShape of
    1: begin             // сглаженый
      PolygonMode := GL_FILL;
      FlatFace := FALSE;
    end;
    2: begin             // граненый
      PolygonMode := GL_FILL;
      FlatFace := TRUE;
    end;
    3: begin             // каркас
      PolygonMode := GL_LINE;
      FlatFace := FALSE;
    end;
  end; {case ModeShape}
  glPolygonMode(GL_FRONT_AND_BACK,PolygonMode{GL_LINE});{}
      CheckGlError('GLDraw:PolygonMode',0);
  glDepthFunc(GL_LESS);   // Type of depth test
    CheckGlError('PGLP:DepthFunc',0);





{  glEdgeFlag (FALSE);  {}
{ 1-й проход - рисуем все кроме прозрачных и бликов при текстурах}
  for Nobj := {0}kol_objekts_models[model] to {Nobj3DS}kol_objekts_models[model+1]-1 do
    if Obj3DS[Nobj].vz and Obj3DS[Nobj].lb then begin
      Nmat := Obj3DS[Nobj].m0;
      while Nmat <> -1 do {цикл по материалам - вычисление нормалей к граням}
        with MatObj[Nmat] do begin

          case ModeTexture of
            1: IsTexture := (Material[im].dx > 0) and (ntf = nvn);
{!!!!}      2: IsTexture := FALSE;
            3: IsTexture := FALSE;
          end; {case}
          case ModeMaterial of
            1: WhiteMaterial := FALSE;
            2: WhiteMaterial := TRUE;
            3: if IsTexture then
                 WhiteMaterial := TRUE
               else
                 WhiteMaterial := FALSE;
          end; {case}

          if WhiteMaterial then
            i := 0
          else
            i := im;
          j := 0;
          if Material[i].tran > 0.15 then
            case ModeTranspar of
              1 : j := 1;        {нормальная}
              2 : j := 4;        {не рисовать}
              3 : j := 0;        {непрозрачные}
            end;
          with Material[i] do
            if ModeMatSpot and ((Spec.r + Spec.g + Spec.b) > 0.2) then
              if IsTexture or (j = 1) then
                j := j or 2;
          if (j and 3) > 0 then begin
            MO23[NMO23].d := j;
            MO23[NMO23].m := Nmat;
            inc(NMO23);
          end;
//             writeln(t,'Draw: ntf=',ntf,' nvn=',nvn,' im=',im,' Material[im].dx=',Material[im].dx,
//               ' ModeTexture=',ModeTexture,' WhiteMaterial=',WhiteMaterial,' j=',j);

          if (j and 5) = 0 then
            DrawMatObj(Nmat,@Material[i].Ambi,@Material[i].Diff,@Material[i].Spec,Material[i].shin*128,i);
          Nmat := nx;
        end;{with}
    end;{if}
{ 2-й проход - рисуем прозрачные объекты и блики}
  glEnable(GL_BLEND);
  glDepthMask(FALSE);
  IsTexture := FALSE;

  if NMO23 > 0 then begin
    if NMO23 > 1 then begin               // сортировка по удаленности
      for i := 0 to NMO23-1 do begin // вычисление расстояний
        with MatObj[MO23[i].m] do begin
          v1.x := x0; v1.y := y0; v1.z := z0;
        end;
        v1 := MatrVect(MT_GetMatrix,v1);
        MO23[i].l := v1.z;
      end; {for i}
      for i := 1 to NMO23-1 do          // сортировка
        for j := NMO23-1 downto i do
          if MO23[j].l < MO23[j-1].l then begin
            TmpDMO := MO23[j];     MO23[j] := MO23[j-1];    MO23[j-1] := TmpDMO;
          end;
    end;   {NMO23 > 1}
    for i := 0 to NMO23-1 do begin // рисование
      Nmat := MO23[i].m;
      if WhiteMaterial then
        j := 0
      else
        j := MatObj[Nmat].im;
      if (MO23[i].d and 1) > 0 then begin  // прозрачные
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDepthFunc(GL_LESS);   // Type of depth test
          CheckGlError('PGLP:DepthFunc',0);
        DrawMatObj(Nmat,@Material[j].Ambi,@Material[j].Diff,@Material[j].Spec,Material[j].shin*128,j);
      end;  {if (MO23[i].d and 1) > 0}
      if (MO23[i].d and 2) > 0 then begin  // блики
        glBlendFunc(GL_ONE, GL_ONE);
        glDepthFunc(GL_LEQUAL);   // Type of depth test
          CheckGlError('PGLP:DepthFunc',0);
        DrawMatObj(Nmat, @BlackC, @BlackC, @Material[j].Spec, Material[j].shin*128,j);
      end;  {if (MO23[i].d and 2) > 0}
    end; {for i}
  end; {if NMO23 > 0}

//  SwapBuffers(DC);
    CheckGlError('GLDraw:SwapBuffers',NumDraw);
  glDisable(GL_BLEND);
  glDepthMask(TRUE);
  glDisable(GL_CULL_FACE);{}

//  glRotatef(90, 1.0, 0.0, 0.0);
//  glRotatef(-180, 0.0, 1.0, 0.0);
  glRotatef(Angley{-90}, 1.0, 0.0, 0.0);
  glRotatef(-Anglex{-180}, 0.0, 1.0, 0.0);
  glTranslatef(-x,-y, -z);                                          // Polygon depth
        glMaterialfv (GL_FRONT_AND_BACK, GL_AMBIENT, PGLfloat(@Material[0].Ambi));  // Reflective properties
        glMaterialfv (GL_FRONT_AND_BACK, GL_DIFFUSE, PGLfloat(@Material[0].Diff));  // Reflective properties
        glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, PGLfloat(@Material[0].Spec));  // Reflective properties
        glMaterialf  (GL_FRONT_AND_BACK, GL_SHININESS, Material[0].SHIN*128);  // Reflective properties
end;

procedure GLD_PrepParams(dc : hdc); {предварительная инициализация нужных режимов}
begin
    CheckGlError('GLG begin',longint(dc));
  deb2file(' PGLP:begin: dc=',longint(dc));
  HRC := wglCreateContext (DC); // Make a GL Context
    CheckGlError('PGLP:CreateContext',HRC);

  wglMakeCurrent (dc, hrc);     // устанавливает текущий контекст воспроизведения
    CheckGlError('PGLP:MakeCurrent',0);
  glClearColor(0.0, 0.4, 0.2, 1.0); // Clear background color to black
//  glClearColor(1.0, 1.0, 1.0, 1.0); // Clear background color to black
    CheckGlError('PGLP:ClearColor',0);
  glClearDepth(1.0);   // Clear the depth buffer
    CheckGlError('PGLP:ClearDepth',0);

//  glShadeModel(GL_FLAT{GL_SMOOTH});   // Smooth color shading
  glEnable(GL_DEPTH_TEST);   // Depth test
    CheckGlError('PGLP:Enable(DEPTH_TEST)',0);
  glMatrixMode(GL_PROJECTION);
    CheckGlError('PGLP:MatrixMode(PROJECTION)',0);
  glLoadIdentity;             // Reset projection matrix
    CheckGlError('PGLP:LoadIdentity',0);
  glMatrixMode(GL_MODELVIEW);
    CheckGlError('PGLP:MatrixMode(MODELVIEW)',0);
  // Create light
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,1);
    CheckGlError('PGLP:LightModeli',0);

  glLightfv(GL_LIGHT0, GL_AMBIENT, PGLfloat(@LightAmbient));
    CheckGlError('PGLP:Lightf(0,AMBIENT)',0);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, PGLfloat(@LightDiffuse));
    CheckGlError('PGLP:Lightf(0,DIFFUSE)',0);
  glLightfv(GL_LIGHT0, GL_SPECULAR, PGLfloat(@LightSpecular));
    CheckGlError('PGLP:Lightf(0,SPECULAR)',0);
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, @lmodel_ambient);
    CheckGlError('PGLP:Lightf(0,LIGHT_MODEL_AMBIENT',0);
  // Light position
  glLightfv(GL_LIGHT0, GL_POSITION, PGLfloat(@LightPosition));
    CheckGlError('PGLP:Lightf(0,POSITION)',0);
  glEnable(GL_LIGHTING);
    CheckGlError('PGLP:Enable(LIGHTING)',0);
  glEnable(GL_LIGHT0);
    CheckGlError('PGLP:Enable(LIGHT0)',0);
end;

begin
  Nlist := 0;
end.