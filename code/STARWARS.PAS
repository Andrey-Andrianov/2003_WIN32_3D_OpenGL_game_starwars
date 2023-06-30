
program GLCube;

{$ifndef __WIN32__}
{$define INVALID_TARGET}
{$endif}
{$ifndef __GUI__}
{$define INVALID_TARGET}
{$endif}
{$ifdef INVALID_TARGET}
  This program must be compiled as Win32 GUI application only
{$endif}

uses Windows, Messages, Strings, OpenGL, {Use32, CommDlg,} MMSystem,{monstrs,}enems,
graphs2 {,gl_3ds},
(* read3d7c, deb_as, gl_draw1,rd_btmp0, timer_dw, comm_3d, readlwo1, {Mmedia,,} DDraw,*)
{Graph{,ddex1}grtext,getnorm1{,deb_as}, gl_draw1,keybdexc,comm_3d
     {,timer_dw, comm_3d,  MatrTrns, debug,Read3D7c};



type
    sctype  = array[0..1023,0..1023,0..2] of {single}byte;

    fire = record
      ind : longint;
      x : single;
      y : single;
      z : single;
      vx : single;
      vy : single;
      vz : single;
      angle : single;
      angle_y : single;
      tip : longint;
    end;

    segment = record
      ind : integer;
      color : byte;
      model : byte;
      x : single;
      y : single;
      z : single;
      angle : single;
      vidim : array [1..10] of byte;
    end;

    think = record
      ind : integer;
      model : byte;
      segment :byte;
      x : single;
      y : single;
      z : single;
      angle : single;
    end;

    replika = record
      n_m : longint;
      k_m : longint;
      n_c : longint;
      k_c : longint;
      n_b : longint;
      k_b : longint;
      n_s1 : longint;
      k_s1 : longint;
      n_s2 : longint;
      k_s2 : longint;
      n_c_v : longint;
      k_c_v : longint;
      n_c_p : longint;
      k_c_p : longint;
    end;


const
//  globe_paint : boolean = true{false};
  draw_3d_bar : boolean = true;
  regim_draw_pribor_panel : longint = 1;
  read_model_constant : longint = 0;

  asteroids_pole : boolean = {true}false;

  score : longint = 0;
  mission_score : longint = 0;
  regim : longint = -1;
  GLF_START_LIST = 0;
  play_wave : boolean = false;
  play_wave2 : boolean = false;
  play_wave3 : boolean = false;
  play_midi : boolean = true;

//  flag_320x200x16 : boolean = false;

  timer_bool : integer = 10;

  pole_life   : single = 100;
  pole_fire   : integer = 66;
  kol_rakets  : longint = 2;
//  pole_full   : integer = 20;


  scaled : single = 1;
  rotate_x : single = 0;
  rotate_y : single = 1;
  rotate_z : single = 0;
  myx : single = 1;
  myy : single = 1.1;
  myz : single = -19;

  base_x : single = 0;
  base_y : single = 0;
  base_z : single = 0;

  active_mission : longint = 1;
  your_mission : longint = 0{4};

  active_mission_false_step : longint = 1;
//  faza_texture_babax : longint = 0;

  angle : single = {270}0;
  angle2 : single = {270}0;
  angle_y : single = 0;
  angle_y2 : single = 0;
  mylive : longint = 100;
  spend : single = 0.12;

  num_polig : longint = 0;
  num_lesn  : longint = 0;
  num_fire : longint = 0;
  num_rakets : longint = 0;

  position : array[0..3]of single = (0.0,0.5,0.0,1.0);
  global_ambient : array[0..3]of single = (2,2,2,1);
  MaterialColor: Array [0..3] Of GLfloat = (1, 0.75, 0.0, 1.0);{}
  MaterialColorblack: Array [0..3] Of GLfloat = (0, 0, 0, 1.0);{}

  kol_objekts : longint = 0;

var
  ExitSave:Pointer;     { адрес старой программы выхода в DOS }

  zastavka_list1 : GLUint;
  zastavka_list2 : GLUint;
  zastavka_list3 : GLUint;
  zastavka_list4 : GLUint;
  chdirstr : string;
  mousex,mousey :single;
  mousekey      :word;
  fps : single;
//  MyMedia: TMMedia;

  id_Timer : uint; // идентификатор таймера
//  FPS{, Angle}: GLFloat;
  NewCount, LastCount, FrameCount: Integer;
  PixelFormat: Integer;
  DC: HDC;
  HRC: HGLRC;
  wnd: HWnd;

//  g_pDD:         IDirectDraw7 := nil;          // DirectDraw object
//  DD : IDirectDraw2;
//  DD1: IDirectDraw;  // Temp object for getting an IDirectDraw2 interface.
  Mess_beep:     String;


  i,j : longint;
  barmap : array [1..400,1..400] of byte;
//  textura : array[0..5,0..255,0..255,0..3] of byte;
  textura_babax : ^array[0..511,0..511,0..3] of byte;
  textura_babax_real : ^array[0..127,0..127,0..3] of byte;
//  lists : array[0..10] of GLUint;


  sc  : ^sctype;
  fires : array[1..500] of fire;
//  rakets: array[1..100] of fire;
  kol_segments : byte;
  my_segment : byte;
  segments : array[1..20] of segment;

  kol_thinks : byte;
  thinks : array[1..20] of think;

  repliks : array[0..11] of replika;
  texts_missions_str : array[1..400] of string[64];

  DeviceModeDefault : TDeviceMode;
  DeviceMode_real : TDeviceMode;




(*type distarray = array[0..MaxPoints-1]of single;
Var
  VertexNormals : ^VectArrayType; { массив нормалей, посчитанных по Faces}
  Faces         : ^FaceArrayType; { массив считанных граней, переупорядоченный для отображения}
  FaceNormals3  : ^VectArrayType; { массив нормалей к Faces}
  DistSum       : ^distarray; {расстояния от вершин до центра граней}

                                                                     *)

procedure readrepliks;
var
  f : text;
  i,j,n,k : longint;
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
  assign(f,'missions.dat');
  reset(f);
  readln(f,n);
  j := 1;
  i := 0;
  for i := 0 to n-1 do begin
    readln(f,k);
    readln(f,k);
    repliks[i].n_m := j;
    j := j+k;
    repliks[i].k_m := j;
    for k := repliks[i].n_m to repliks[i].k_m-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_s1 := j;
    j := j+k;
    repliks[i].k_s1 := j;
    for k := repliks[i].n_s1 to repliks[i].k_s1-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_s2 := j;
    j := j+k;
    repliks[i].k_s2 := j;
    for k := repliks[i].n_s2 to repliks[i].k_s2-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_b := j;
    j := j+k;
    repliks[i].k_b := j;
    for k := repliks[i].n_b to repliks[i].k_b-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_c := j;
    j := j+k;
    repliks[i].k_c := j;
    for k := repliks[i].n_c to repliks[i].k_c-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_c_v := j;
    j := j+k;
    repliks[i].k_c_v := j;
    for k := repliks[i].n_c_v to repliks[i].k_c_v-1 do
      readln(f,texts_missions_str[k]);

    readln(f,k);
    repliks[i].n_c_p := j;
    j := j+k;
    repliks[i].k_c_p := j;
    for k := repliks[i].n_c_p to repliks[i].k_c_p-1 do
      readln(f,texts_missions_str[k]);

    readln(f);
  end;
  close(f);
end;


procedure readbarmap;
var
  i,j : longint;
  f:file;
begin
  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});
  assign(f,'barmap.bmp');
  reset(f,1);
  seek(f,1078);
  for j := 400 downto 1 do
    blockread(f,barmap[j],400{sizeof(barmap)});
  close(f);
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
end;

procedure read3dbarsegments;
var
  f : text;
  i,j : integer;
begin
  assign(f,'segments.dat');
  reset(f);
  readln(f,kol_segments);
  for j := 1 to kol_segments do begin
    readln(f,segments[j].ind);
    readln(f,segments[j].color);
    readln(f,segments[j].model,segments[j].x,segments[j].y,segments[j].z,segments[j].angle);
    for i := 1 to 10 do
      read(f,segments[j].vidim[i]);
    readln(f);
    readln(f);
  end;
  close(f);

  assign(f,'thinks.dat');
  reset(f);
  readln(f,kol_thinks);
  for j := 1 to kol_thinks do begin
    readln(f,thinks[j].ind);
    readln(f,thinks[j].segment);
    readln(f,thinks[j].model,thinks[j].x,thinks[j].y,thinks[j].z,thinks[j].angle);
    readln(f);
  end;
  close(f);
end;

(*procedure readspacemodels;
begin
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
  ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,{'ship4.3ds'}'model_x1.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'model_x3.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x4.x',2,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'banka2.3ds'{'banka_x.x'},1,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'fire1.3ds',1{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x2.x',2,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'raketa.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'ship3_b.3ds',1,9,1); {}

  ReadModel(wnd,'model_x5.x',2,10,1); {}
  ReadModel(wnd,'model_x6.x',2,11,1); {}
  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,12,3); {}

  ReadModel(wnd,'globe.x'{'banka_x.x'},2,13,1); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'seg056.x'{'banka_x.x'},2,14,10); {}
  ReadModel(wnd,'seg052.x'{'banka_x.x'},2,15,10); {}
  ReadModel(wnd,'seg051.x'{'banka_x.x'},2,16,10); {}
  ReadModel(wnd,'seg055.x'{'banka_x.x'},2,17,10); {}
  ReadModel(wnd,'seg057.x'{'banka_x.x'},2,18,10); {}
  ReadModel(wnd,'cafe1.3ds'{'banka_x.x'},1,19,2.3); {}
  ReadModel(wnd,'duck.3ds'{'banka_x.x'},1,20,0.5); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'model_x1.x',2,21,9); {}
  ReadModel(wnd,'model_x1.x',2,22,0.5); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});
  read3dbarsegments;

  ReadModel(wnd,'man1.x',2,23,2); {}
  ReadModel(wnd,'man2.x',2,24,2); {}
  ReadModel(wnd,'man3.x',2,25,2); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
end;*)

(*procedure read3dbarmodels;
begin
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;
  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});

  ReadModel(wnd,{'ship4.3ds'}'seg051.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'seg051.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'seg051.x',2,3,1); {}
  ReadModel(wnd,'seg051.3ds',2,4,1); {}
  ReadModel(wnd,'seg051.3ds'{'banka_x.x'},2,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'seg051.3ds',2{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'seg051.x',2,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'seg051.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'seg051.3ds',2,9,1); {}

  ReadModel(wnd,'seg052.x',2,10,1); {}
  ReadModel(wnd,'seg051.x',2,11,1); {}
  ReadModel(wnd,'seg051.x'{'banka_x.x'},2,12,3); {}

  ReadModel(wnd,'seg051.x'{'banka_x.x'},2,13,1); {}
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
end;
       (****)



procedure SetDCPixelFormat;
const
   Pfd: TPIXELFORMATDESCRIPTOR = (
     nSize: SizeOf (TPIXELFORMATDESCRIPTOR);
     nVersion: 1;
     dwFlags: PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
     iPixelType: PFD_TYPE_RGBA;
     cColorBits: 32;
     cRedBits: 0;
     cRedShift: 0;
     cGreenBits: 0;
     cBlueBits: 0;
     cBlueShift: 0;
     cAlphaBits: 0;
     cAlphaShift: 0;
     cAccumBits: 0;
     cAccumRedBits: 0;
     cAccumGreenBits: 0;
     cAccumBlueBits: 0;
     cAccumAlphaBits: 0;
     cDepthBits: 32;
     cStencilBits: 0;
     cAuxBuffers: 0;
     iLayerType: PFD_MAIN_PLANE;
     bReserved: 0;
     dwLayerMask: 0;
     dwVisibleMask: 0;
     dwDamageMask: 0);
begin
  PixelFormat := ChoosePixelFormat(DC, @Pfd);
  SetPixelFormat(DC, PixelFormat, @Pfd);
end;

function WndWidth: Integer;
var
  rect: TRect;
begin
  GetClientRect(wnd, rect);
  Result := rect.right - rect.left + 1;
end;

function WndHeight: Integer;
var
  rect: TRect;
begin
  GetClientRect(wnd, rect);
  Result := rect.bottom - rect.top + 1;
end;


procedure prer_param;
begin
  DC := GetDC(wnd);
  SetDCPixelFormat;
  // Make a GL Context

  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  // Clear background color to black
  glClearColor(0.0, 0.0, 0.0, 0.0);
  // Clear the depth buffer
  glClearDepth(1.0);
  // Type of depth test
  glDepthFunc(GL_LESS);
  // Smooth color shading
  glShadeModel(GL_SMOOTH);
  // Depth test
  glEnable(GL_DEPTH_TEST);
  glMatrixMode(GL_PROJECTION);
  // Reset projection matrix
  glLoadIdentity;
  // Aspect ratio of the viewport

 glViewport(0, 0, WndWidth, WndHeight);
 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;



 gluperspective(90,WndWidth/WndHeight,0.01,150);


  glMatrixMode(GL_MODELVIEW);

//                                   gluPerspective(45.0, WndWidth / WndHeight, 0.1, 100.0);
  glMatrixMode(GL_MODELVIEW);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  gllightmodelfv(gl_light_model_ambient,@global_ambient);

//  gllightfv(gl_light0,gl_position,@position);
  gllightmodelf(gl_light_model_local_viewer,1);
//  gllightmodelf(gl_light_model_two_side,1);
  glenable(gl_cull_face);
  wglUseFontBitmaps(dc, 0, 255, GLF_START_LIST);
end;

(*procedure readspacemodels1;{тренеровочный полет}
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

          bmpp5(0,'loading.bmp');
          draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,{'ship4.3ds'}'model_x1.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'model_x3.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x4.x',2,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'banka2.3ds'{'banka_x.x'},1,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'fire1.3ds',1{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,'a.3ds',1,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'raketa.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'a.3ds',1,9,1); {}

  ReadModel(wnd,'a.3ds',1,10,1); {}
  ReadModel(wnd,'a.3ds',1,11,1); {}
  ReadModel(wnd,'a.3ds',1,12,1); {}

  ReadModel(wnd,'globe.x'{'banka_x.x'},2,13,1); {}

  ReadModel(wnd,'a.3ds',1,14,1); {}
  ReadModel(wnd,'a.3ds',1,15,1); {}
  ReadModel(wnd,'a.3ds',1,16,1); {}
  ReadModel(wnd,'a.3ds',1,17,1); {}
  ReadModel(wnd,'a.3ds',1,18,1); {}
  ReadModel(wnd,'a.3ds',1,19,1); {}
  ReadModel(wnd,'a.3ds',1,20,1); {}
  ReadModel(wnd,'a.3ds',1,21,1); {}
  ReadModel(wnd,'a.3ds',1,22,1); {}
  ReadModel(wnd,'a.3ds',1,23,1); {}
  ReadModel(wnd,'a.3ds',1,24,1); {}
  ReadModel(wnd,'a.3ds',1,25,1); {}
end;

procedure readspacemodels2;{миссия}
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

             bmpp5(0,'loading.bmp');
             draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,{'ship4.3ds'}'model_x1.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'model_x3.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x4.x',2,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'banka2.3ds'{'banka_x.x'},1,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'fire1.3ds',1{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x2.x',2,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'raketa.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'ship3_b.3ds',1,9,1); {}

  ReadModel(wnd,'model_x5.x',2,10,1); {}
  ReadModel(wnd,'model_x6.x',2,11,1); {}
  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,12,3); {}

  ReadModel(wnd,'globe.x'{'banka_x.x'},2,13,1); {}

  ReadModel(wnd,'a.3ds',1,14,1); {}
  ReadModel(wnd,'a.3ds',1,15,1); {}
  ReadModel(wnd,'a.3ds',1,16,1); {}
  ReadModel(wnd,'a.3ds',1,17,1); {}
  ReadModel(wnd,'a.3ds',1,18,1); {}
  ReadModel(wnd,'a.3ds',1,19,1); {}
  ReadModel(wnd,'a.3ds',1,20,1); {}
  ReadModel(wnd,'a.3ds',1,21,1); {}
  ReadModel(wnd,'a.3ds',1,22,1); {}
  ReadModel(wnd,'a.3ds',1,23,1); {}
  ReadModel(wnd,'a.3ds',1,24,1); {}
  ReadModel(wnd,'a.3ds',1,25,1); {}
end;

procedure read3dbarmodels;
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

             bmpp5(0,'loading.bmp');
             draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,'a.3ds',1,1,1); {}
  ReadModel(wnd,'a.3ds',1,2,1); {}
  ReadModel(wnd,'a.3ds',1,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'a.3ds',1,5,1); {}
  ReadModel(wnd,'a.3ds',1,6,1); {}
  ReadModel(wnd,'a.3ds',1,7,1); {}
  ReadModel(wnd,'a.3ds',1,8,1); {}
  ReadModel(wnd,'a.3ds',1,9,1); {}
  ReadModel(wnd,'a.3ds',1,10,1); {}
  ReadModel(wnd,'a.3ds',1,11,1); {}
  ReadModel(wnd,'a.3ds',1,12,1); {}
  ReadModel(wnd,'a.3ds',1,13,1); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'seg056.x'{'banka_x.x'},2,14,10); {}
  ReadModel(wnd,'seg052.x'{'banka_x.x'},2,15,10); {}
  ReadModel(wnd,'seg051.x'{'banka_x.x'},2,16,10); {}
  ReadModel(wnd,'seg055.x'{'banka_x.x'},2,17,10); {}
  ReadModel(wnd,'seg057.x'{'banka_x.x'},2,18,10); {}
  ReadModel(wnd,'cafe1.3ds'{'banka_x.x'},1,19,2.3); {}
  ReadModel(wnd,'duck.3ds'{'banka_x.x'},1,20,0.5); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'model_x1.x',2,21,9); {}
  ReadModel(wnd,'model_x1.x',2,22,0.5); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});
  read3dbarsegments;

  ReadModel(wnd,'man1.x',2,23,2); {}
  ReadModel(wnd,'man2.x',2,24,2); {}
  ReadModel(wnd,'man3.x',2,25,2); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
end;       (*********)



procedure OutText (Litera : string);
var
  i,j : longint;
begin
  glListBase(GLF_START_LIST);
  glCallLists(byte(litera[0]), GL_UNSIGNED_BYTE, @Litera+1);
end;

function SetFullscreenMode(width,height,ColorDepth: Integer) : Boolean;
// устанавливаем видеорежим согласно аргументу 'ModeIndex'
var
  DeviceMode : {T}{DevMode}TDeviceMode;
begin
  with DeviceMode do begin
    dmSize := SizeOf(DeviceMode);
    dmBitsPerPel := {VideoModes[ModeIndex].}ColorDepth;
    dmPelsWidth := {VideoModes[ModeIndex].}Width;
    dmPelsHeight := {VideoModes[ModeIndex].}Height;
    dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
    // если режим не устанавливается, ScreenModeChanged = False
    Result := ChangeDisplaySettings(DeviceMode,CDS_FULLSCREEN) = DISP_CHANGE_SUCCESSFUL;
{    if Result then ScreenModeChanged := True;
    if ModeIndex = 0 then ScreenModeChanged:=False;}
  end;
end;

procedure SaveDefaultscreenMode;
var
  DeskDC : HDC;
begin
  DeskDC := GetDC (0);
  with DeviceModeDefault do begin
    dmSize := SizeOf(DeviceModeDefault);
    dmBitsPerPel := GetDeviceCaps (DeskDC, BITSPIXEL);
    dmPelsWidth := GetDeviceCaps (DeskDC, HORZRES);
    dmPelsHeight := GetDeviceCaps (DeskDC, VERTRES);
//    dmPelsWidth := WndWidth;
//    dmPelsHeight := WndHeight;
    dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
  end;
end;

procedure Save_screenMode_real;
var
  DeskDC : HDC;
begin
  DeskDC := GetDC (0);
  with DeviceMode_real do begin
    dmSize := SizeOf(DeviceModeDefault);
    dmBitsPerPel := GetDeviceCaps (DeskDC, BITSPIXEL);
    dmPelsWidth := GetDeviceCaps (DeskDC, HORZRES);
    dmPelsHeight := GetDeviceCaps (DeskDC, VERTRES);
//    dmPelsWidth := WndWidth;
//    dmPelsHeight := WndHeight;
    dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
  end;
end;

procedure LoadDefaultscreenMode;
var
  DeskDC : HDC;
begin
  SetFullscreenMode(DeviceModeDefault.dmPelsWidth,DeviceModeDefault.dmPelsheight,DeviceModeDefault.dmBitsPerPel);
end;


procedure draw_3d_bar_procedure;
var
  i,j,k,l : integer;
  angle_y2,r_a_y : single;
  vidim_segments : array[1..20] of boolean;

begin

          r_a_y := 0;

          if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;

          if (angle_y > 0) and (angle_y < 90) then
            r_a_y := -(-cos(angle_y*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 90) and (angle_y < 180) then
            r_a_y := (-cos((angle_y-180)*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 180) and (angle_y < 270) then
            r_a_y := -(-cos((angle_y-180)*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 270) and (angle_y < 360) then
            r_a_y := (-cos(angle_y*Pi/180){-(angle_y/180)}*45+45);
//          r_a_y := 0;
         angle_y2 := angle_y +   r_a_y;

          if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;






  glEnable(GL_DEPTH_TEST);




        glLoadIdentity;
          glRotatef(Angle_y2, 1.0, 0.0, 0.0);
          glRotatef(Angle, 0.0, 1.0, 0);
          glTranslatef(-myx, -myy, -myz);                                          // Polygon depth
          position[0] := myx;
          position[1] := myy;
          position[2] := myz;
          gllightfv(gl_light0,gl_position,@position);



      gllightmodelf(gl_light_model_two_side,0);
      glenable(gl_cull_face);




          if read_model_constant = 0 then begin
            for i := 1 to kol_segments do
              if barmap[round(200+myz*2),round(200+myx*2)] = segments[i].color then
                my_segment := i;
          end else
            my_segment := 1;
          for i := 1 to kol_segments do
            vidim_segments[i] := false;

          vidim_segments[my_segment] := true;
          for i := 1 to 10 do
            vidim_segments[segments[my_segment].vidim[i]] := true;

          for i := 1 to kol_segments do
            if vidim_segments[i] then
              GLD_Draw(dc,segments[i].model,segments[i].x,segments[i].y,segments[i].z,segments[i].angle,0);

          for i := 1 to kol_thinks do
            if vidim_segments[thinks[i].segment] then
              GLD_Draw(dc,thinks[i].model,thinks[i].x,thinks[i].y,thinks[i].z,thinks[i].angle,0);



        glLoadIdentity;
        glTranslatef(-0.115, 0.085,-0.09);
        glrasterpos2f(0,0);
        NewCount := GetTickCount;
        FrameCount +:= 1;
        if (NewCount - LastCount) > 1000 then
         begin
           fps := FrameCount * 1000 / (NewCount - LastCount);
           LastCount := NewCount;
           FrameCount := 0;
         end;
//         readbarmap;
        outtext('space01 - ' + IntToStr(Round(fps)) + ' fps' +
             + ' x = ' + IntToStr(round(myx))+ ' z = ' + IntToStr(round(myz))+ ' y = ' + IntToStr(round(myy))+ ' spend = ' + IntToStr((round(spend*100)))+ ' life = ' + IntToStr((mylive))+ ' timer_bool = ' + IntToStr((timer_bool))  {+ 'a ' + IntToStr((round(angle))) + 'a_y ' + IntToStr((round(angle_y))) + 'a_y2 ' + IntToStr((round(angle_y2)))}
             {+' barmap = ' + IntToStr(barmap[round(200+myz*2),round(200+myx*2)]) });
end;

(*procedure bmpp2(n:integer;files : string);
type
  bitmapfileneader = packed record
    ch1 : char;
    ch2 : char;
    dword : longint;
    ch3 : word;
    ch4 : word;
    dword2 : longint;
  end;
  bitmapinfoheader = packed record
    dword : longint;
    long1 : longint;
    long2 : longint;
    word1 : word;
    word2 : word;
    word3 : longint;
    dword2 : longint;
    long3 : longint;
    long4 : longint;
    dword3 : longint;
    dword4 : longint;
  end;
  rgbquad = packed record
    byte1 : byte;
    byte2 : byte;
    byte3 : byte;
    byte4 : byte;
  end;
var
  c : bitmapfileneader;
  c1: bitmapinfoheader;
  i,j : integer;
  f : file;
begin
  assign(f,files);
//  {$I-}
  reset(f,1);
  blockread(f,c,{sizeof(c)}14);
  blockread(f,c1,{sizeof(c1)}40);
//  seek(f,filesize(f)-128*128*3);
  for j := c1.long2-1 downto 0 do
    blockread(f,sc^[j],c1.long1*3); {}
  for j := 0 to c1.long2 - 1 do
    for i := 0 to c1.long1 - 1 do begin
      textura[n,j,i,0] := sc^[j,i,2];
      textura[n,j,i,1] := sc^[j,i,1];
      textura[n,j,i,2] := sc^[j,i,0];
    end;
  close(f);
//  {$I+}
end;   *)

procedure bmpp3(n:integer;files : string);
type
  bitmapfileneader = packed record
    ch1 : char;
    ch2 : char;
    dword : longint;
    ch3 : word;
    ch4 : word;
    dword2 : longint;
  end;
  bitmapinfoheader = packed record
    dword : longint;
    long1 : longint;
    long2 : longint;
    word1 : word;
    word2 : word;
    word3 : longint;
    dword2 : longint;
    long3 : longint;
    long4 : longint;
    dword3 : longint;
    dword4 : longint;
  end;
  rgbquad = packed record
    byte1 : byte;
    byte2 : byte;
    byte3 : byte;
    byte4 : byte;
  end;
var
  c : bitmapfileneader;
  c1: bitmapinfoheader;
  i,j : integer;
  f : file;
begin
  assign(f,files);
//  {$I-}
  reset(f,1);
  blockread(f,c,{sizeof(c)}14);
  blockread(f,c1,{sizeof(c1)}40);
//  seek(f,filesize(f)-128*128*3);
  for j := c1.long2-1 downto 0 do
    blockread(f,sc^[j],c1.long1*3); {}
  for j := 0 to c1.long2 - 1 do
    for i := 0 to c1.long1 - 1 do begin
      pribors_tex[j,i,0] := sc^[j,i,2];
      pribors_tex[j,i,1] := sc^[j,i,1];
      pribors_tex[j,i,2] := sc^[j,i,0];
    end;
  close(f);
//  {$I+}
end;

procedure bmpp4(n:integer;files : string);
type
  bitmapfileneader = packed record
    ch1 : char;
    ch2 : char;
    dword : longint;
    ch3 : word;
    ch4 : word;
    dword2 : longint;
  end;
  bitmapinfoheader = packed record
    dword : longint;
    long1 : longint;
    long2 : longint;
    word1 : word;
    word2 : word;
    word3 : longint;
    dword2 : longint;
    long3 : longint;
    long4 : longint;
    dword3 : longint;
    dword4 : longint;
  end;
  rgbquad = packed record
    byte1 : byte;
    byte2 : byte;
    byte3 : byte;
    byte4 : byte;
  end;
var
  c : bitmapfileneader;
  c1: bitmapinfoheader;
  i,j : integer;
  f : file;
begin
  assign(f,files);
//  {$I-}
  reset(f,1);
  blockread(f,c,{sizeof(c)}14);
  blockread(f,c1,{sizeof(c1)}40);
//  seek(f,filesize(f)-128*128*3);
  for j := c1.long2-1 downto 0 do
    blockread(f,sc^[j],c1.long1*3); {}
  for j := 0 to c1.long2 - 1 do
    for i := 0 to c1.long1 - 1 do begin
      space_map_textura^[j,i,0] := sc^[j,i,2];
      space_map_textura^[j,i,1] := sc^[j,i,1];
      space_map_textura^[j,i,2] := sc^[j,i,0];
    end;
  close(f);
//  {$I+}
end;

procedure bmpp5(n:integer;files : string);
type
  bitmapfileneader = packed record
    ch1 : char;
    ch2 : char;
    dword : longint;
    ch3 : word;
    ch4 : word;
    dword2 : longint;
  end;
  bitmapinfoheader = packed record
    dword : longint;
    long1 : longint;
    long2 : longint;
    word1 : word;
    word2 : word;
    word3 : longint;
    dword2 : longint;
    long3 : longint;
    long4 : longint;
    dword3 : longint;
    dword4 : longint;
  end;
  rgbquad = packed record
    byte1 : byte;
    byte2 : byte;
    byte3 : byte;
    byte4 : byte;
  end;
var
  c : bitmapfileneader;
  c1: bitmapinfoheader;
  i,j : integer;
  f : file;
begin
  assign(f,files);
//  {$I-}
  reset(f,1);
  blockread(f,c,{sizeof(c)}14);
  blockread(f,c1,{sizeof(c1)}40);
//  seek(f,filesize(f)-128*128*3);
  for j := c1.long2-1 downto 0 do
    blockread(f,sc^[j],c1.long1*3); {}
  for j := 0 to c1.long2 - 1 do
    for i := 0 to c1.long1 - 1 do begin
      textura_pich^[j,i,0] := sc^[j,i,2];
      textura_pich^[j,i,1] := sc^[j,i,1];
      textura_pich^[j,i,2] := sc^[j,i,0];
    end;
  close(f);
//  {$I+}
end;

procedure bmpp6(n:integer;files : string);
type
  bitmapfileneader = packed record
    ch1 : char;
    ch2 : char;
    dword : longint;
    ch3 : word;
    ch4 : word;
    dword2 : longint;
  end;
  bitmapinfoheader = packed record
    dword : longint;
    long1 : longint;
    long2 : longint;
    word1 : word;
    word2 : word;
    word3 : longint;
    dword2 : longint;
    long3 : longint;
    long4 : longint;
    dword3 : longint;
    dword4 : longint;
  end;
  rgbquad = packed record
    byte1 : byte;
    byte2 : byte;
    byte3 : byte;
    byte4 : byte;
  end;
var
  c : bitmapfileneader;
  c1: bitmapinfoheader;
  i,j : integer;
  f : file;
begin
  assign(f,files);
//  {$I-}
  reset(f,1);
  blockread(f,c,{sizeof(c)}14);
  blockread(f,c1,{sizeof(c1)}40);
//  seek(f,filesize(f)-128*128*3);
  for j := c1.long2-1 downto 0 do
    blockread(f,sc^[j],c1.long1*3); {}
  for j := 0 to c1.long2 - 1 do
    for i := 0 to c1.long1 - 1 do begin
      textura_babax^[j,i,0] := sc^[j,i,2];
      textura_babax^[j,i,1] := sc^[j,i,1];
      textura_babax^[j,i,2] := sc^[j,i,0];
    end;
  close(f);
//  {$I+}
end;

procedure scale(s:single);
var
  i,j : integer;
  mt : array[0..3,0..3]of single;
begin
 for i := 0 to 3 do
   for j := 0 to 3 do
     mt[i,j] := 0.0;
 mt[0,0] := s; mt[1,1] := s; mt[2,2] := s; mt[3,3] := 1;
 glmultmatrixf(@mt);
end;





procedure rerspective;
var
  i,j : longint;
  x1 : single;
begin
 glViewport(0, 0, WndWidth, WndHeight);
 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;



 gluperspective(90,WndWidth/WndHeight,0.01,150);


  glMatrixMode(GL_MODELVIEW);

end;


procedure steprakets(n:longint);
var
  i,j,i1,l,b : longint;
  dx,dz,dl,dsin,dcos,genx1,geny1,genz1,dy,dysin,angle1,angle_y1,k,a1,a2,my_x,my_y,my_z : single;
begin
            dz := 10000;
            i1 := -1;
            dy := -2;
            for j := 1 to kol_monstrs do begin
              if (sqrt(sqr(fires[n].x-monstr[j].x)+sqr(fires[n].y-monstr[j].y)+sqr(fires[n].z-monstr[j].z))<=150) then begin
                if (dz > sqrt(sqr(fires[n].x-monstr[j].x)+sqr(fires[n].y-monstr[j].y)+sqr(fires[n].z-monstr[j].z))) and (monstr[j].t=1) and (monstr[j].heard > 0) then begin
                  dz := sqrt(sqr(fires[n].x-monstr[j].x)+sqr(fires[n].y-monstr[j].y)+sqr(fires[n].z-monstr[j].z));
                  i1 := j;
                end;
              end;{ else begin}
            end;

                if (i1 = -1) then begin
                  exit;
                end else begin
                  my_x := monstr[i1].x;
                  my_y := monstr[i1].y;
                  my_z := monstr[i1].z;
                end;

      dx := fires[n].x - my_x;
      dz := fires[n].z - my_z;
      dy := fires[n].y - my_y;

      dl := sqrt(dx*dx + dz*dz + dy*dy);

     if dl <> 0 then begin
      dsin := dx / dl;
      dcos := dz / dl;
      dysin := dy / dl;
     end;



          if (fires[n].z-my_z) >= 0 then
            k := 0
          else
            k := 180;
          if (fires[n].z-my_z) <> 0 then
            angle1 := k+arctan((fires[n].x-my_x)/(fires[n].z-my_z))*180/Pi
          else
            angle1 := k+180;
          if angle1 >= 360 then angle1 := angle1 - 360;
          if angle1 < 0 then angle1 := angle1 + 360;
          a1 := fires[n].angle - 2.0;
          a2 := fires[n].angle + 2.0;
          if (sqr(my_x-(fires[n].x-0.1*sin(a1/180*Pi)))+sqr(my_z-(fires[n].z-0.1*cos(a1/180*Pi)))) < (sqr(my_x-(fires[n].x-0.1*sin(a2/180*Pi)))+sqr(my_z-(fires[n].z-0.1*cos(a2/180*Pi)))) then
            fires[n].angle := a1
          else
            fires[n].angle := a2;
          if fires[n].angle >= 360 then fires[n].angle := fires[n].angle - 360;
          if fires[n].angle < 0 then fires[n].angle := fires[n].angle + 360;

//          if (monstr[i].z-myz) >= 0 then
//            k := 0
//          else
            k := 0;
//          if (monstr[i].z-myz) <> 0 then
            angle_y1 := k+arctan((fires[n].y-my_y)/sqrt(dx*dx+dz*dz))*180/Pi;
            fires[n].angle_y := angle_y1;
//          else
//            angle := k+180;
//          if angle >= 360 then angle := angle - 360;
//          if angle < 0 then angle := angle + 360;
//          a1 := monstr[i].angle_y - 0.5;
//          a2 := monstr[i].angle_y + 0.5;
//          if {(sqr(myx-(monstr[i].x-0.1*sin(a1/180*Pi)))+}abs(myy-(monstr[i].y-0.1*sin(a1/180*Pi))) < abs(myy-(monstr[i].y-0.1*sin(a2/180*Pi))){+sqr(myz-(monstr[i].z-0.1*cos(a2/180*Pi))))} then
//           monstr[i].angle_y := a1
//          else
//            monstr[i].angle_y := a2;
          if fires[n].angle_y >= 360 then fires[n].angle_y := fires[n].angle_y - 360;
          if fires[n].angle_y < 0 then fires[n].angle_y := fires[n].angle_y + 360;
end;

procedure stepmonstrs;
var
  i,j,i1,l,b : longint;
  dx,dz,dl,dsin,dcos,genx1,geny1,genz1,dy,dysin,angle1,angle_y1,k,a1,a2,my_x,my_y,my_z : single;
begin
//    if sqrt(sqr(mysors[k].x-myx)+sqr(mysors[k].y-myy)+sqr(mysors[k].z-myz)) > 25 then begin
  for i := 1 to kol_monstrs do begin
    inc(monstr[i].time);
    if monstr[i].time_lighting > 0 then
      dec(monstr[i].time_lighting);
  end;
  for i := 1 to kol_monstrs do IF monstr[i].t <> 100 THEN begin
    if {(monstr[i].vidim) and} (monstr[i].heard > 0) then begin
      case  monstr[i].t of
        1:begin
            dx := sqrt(sqr(monstr[i].x-myx)+sqr(monstr[i].y-myy)+sqr(monstr[i].z-myz));
            dz := 10000;
            i1 := -1;
            dy := -2;
            for j := 1 to kol_monstrs do begin
              if (j<>i) {and (monstr[j].t=50)} and (sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z))<=150) then begin
                if (dz > sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z))) and (monstr[j].t=51) and (monstr[j].heard > 0) then begin
                  dz := sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z));
                  i1 := j;
                end;
//                dl := 5;
                if (monstr[j].t=50) then begin
                  my_x := monstr[j].x;
                  my_y := monstr[j].y;
                  my_z := monstr[j].z;
                  dy := 2;
                  break;
                end;
              end;{ else begin}
            end;
//              i1 := -1;
{              if dy = 2 then begin
                my_x := myx;
                my_y := myy;
                my_z := myz;
              end else begin        }

              if dy = -2 then begin
                if (i1 = -1) or (dx <=  dz) then begin
                  my_x := myx;
                  my_y := myy;
                  my_z := myz;
                end else begin
{                  my_x := 400;
                  my_y := 0.1;
                  my_z := 150;}
                  my_x := monstr[i1].x;
                  my_y := monstr[i1].y;
                  my_z := monstr[i1].z;
{                  my_x := monstr[i1].x;
                  my_y := monstr[i1].y;
                  my_z := monstr[i1].z;}
                end;
              end;
//            end;
{                  my_x := monstr[2].x;
                  my_y := monstr[2].y;
                  my_z := monstr[2].z;    }
{                  my_x := 400;
                  my_y := 0.1;
                  my_z := 150;}
            case round(sqrt(sqr(monstr[i].x-my_x)+sqr(monstr[i].y-my_y)+sqr(monstr[i].z-my_z))) of
              150..10000:begin
                monstr[i].v := 0.0;
                monstr[i].y := myy;
              end;
              45..150:begin
                monstr[i].v := 0.3;
              end;
              15..45:begin
                monstr[i].v := 0.12;
              end;
              7..15:begin
                monstr[i].v := 0.06;
              end;
              0..7:begin
                if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;
//          if cos(monstr[i].angle - angle) >0 then
                monstr[i].v := 0.12;
              end;
              else begin
                monstr[i].v := 0.12;
              end;
            end;
          end;


        50:begin
            my_x := 2192;
            my_y := 1;
            my_z := 899;
            monstr[i].v := 0.1;
           end;
        51:begin
            dz := 10000;
            i1 := -1;
            dy := -2;
            for j := 1 to kol_monstrs do begin
              if (j<>i) and (sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z))<=150) then begin
                if (dz > sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z))) and (monstr[j].t=1) and (monstr[j].heard > 0) then begin
                  dz := sqrt(sqr(monstr[i].x-monstr[j].x)+sqr(monstr[i].y-monstr[j].y)+sqr(monstr[i].z-monstr[j].z));
                  i1 := j;
                end;
//                dl := 5;
              end;{ else begin}
            end;

                if (i1 = -1) then begin
                  my_x := 0;
                  my_y := 0;
                  my_z := 0;
                  monstr[i].v := 0.0;
                end else begin
                  my_x := monstr[i1].x;
                  my_y := monstr[i1].y;
                  my_z := monstr[i1].z;
                end;
            case round(sqrt(sqr(monstr[i].x-my_x)+sqr(monstr[i].y-my_y)+sqr(monstr[i].z-my_z))) of
              150..10000:begin
                monstr[i].v := 0.0;
                monstr[i].y := myy;
              end;
              45..150:begin
                monstr[i].v := 0.3;
              end;
              15..45:begin
                monstr[i].v := 0.12;
              end;
              7..15:begin
                monstr[i].v := 0.06;
              end;
              0..7:begin
                if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;
//          if cos(monstr[i].angle - angle) >0 then
                monstr[i].v := 0.12;
              end;
              else begin
                monstr[i].v := 0.12;
              end;
            end;
                if round(sqrt(sqr(monstr[i].x-400)+sqr(monstr[i].y-0.8)+sqr(monstr[i].z-115))) > 100 then begin
                  my_x := 400;
                  my_y := 0.8;
                  my_z := 115;
                  monstr[i].v := 0.12;
                end;
           end;
        10:begin
            if round(sqrt(sqr(monstr[i].x-myx)+sqr(monstr[i].y-myy)+sqr(monstr[i].z-myz))) <= 75 then monstr[i].t := 1;

            my_x := -158;
            my_y := 1;
            my_z := 755;
            monstr[i].v := 0.2;
           end;
      end;

      dx := monstr[i].x - my_x;
      dz := monstr[i].z - my_z;
      dy := monstr[i].y - my_y;

      dl := sqrt(dx*dx + dz*dz + dy*dy);

     if dl <> 0 then begin
      dsin := dx / dl;
      dcos := dz / dl;
      dysin := dy / dl;
     end;



          if (monstr[i].z-my_z) >= 0 then
            k := 0
          else
            k := 180;
          if (monstr[i].z-my_z) <> 0 then
            angle1 := k+arctan((monstr[i].x-my_x)/(monstr[i].z-my_z))*180/Pi
          else
            angle1 := k+180;
          if angle1 >= 360 then angle1 := angle1 - 360;
          if angle1 < 0 then angle1 := angle1 + 360;
          a1 := monstr[i].angle - 2.0;
          a2 := monstr[i].angle + 2.0;
          if (sqr(my_x-(monstr[i].x-0.1*sin(a1/180*Pi)))+sqr(my_z-(monstr[i].z-0.1*cos(a1/180*Pi)))) < (sqr(my_x-(monstr[i].x-0.1*sin(a2/180*Pi)))+sqr(my_z-(monstr[i].z-0.1*cos(a2/180*Pi)))) then
            monstr[i].angle := a1
          else
            monstr[i].angle := a2;
          if monstr[i].angle >= 360 then monstr[i].angle := monstr[i].angle - 360;
          if monstr[i].angle < 0 then monstr[i].angle := monstr[i].angle + 360;

//          if (monstr[i].z-myz) >= 0 then
//            k := 0
//          else
            k := 0;
//          if (monstr[i].z-myz) <> 0 then
            angle_y1 := k+arctan((monstr[i].y-my_y)/sqrt(dx*dx+dz*dz))*180/Pi;
            monstr[i].angle_y := angle_y1;
//          else
//            angle := k+180;
//          if angle >= 360 then angle := angle - 360;
//          if angle < 0 then angle := angle + 360;
//          a1 := monstr[i].angle_y - 0.5;
//          a2 := monstr[i].angle_y + 0.5;
//          if {(sqr(myx-(monstr[i].x-0.1*sin(a1/180*Pi)))+}abs(myy-(monstr[i].y-0.1*sin(a1/180*Pi))) < abs(myy-(monstr[i].y-0.1*sin(a2/180*Pi))){+sqr(myz-(monstr[i].z-0.1*cos(a2/180*Pi))))} then
//           monstr[i].angle_y := a1
//          else
//            monstr[i].angle_y := a2;
          if monstr[i].angle_y >= 360 then monstr[i].angle_y := monstr[i].angle_y - 360;
          if monstr[i].angle_y < 0 then monstr[i].angle_y := monstr[i].angle_y + 360;
//          if (abs(angle_y-0) < 1) or (abs(angle_y-360) < 1) then
//            monstr[i].angle_y := 0;



      if (monstr[i].t<>50) and (num_fire < 500) and (monstr[i].time > 40) and ((abs(monstr[i].angle-angle1)<=5)or(abs(monstr[i].angle-angle1)>=355)){and (monstr[i].leven = leven)} then begin
        num_fire := num_fire + 1;
        fires[num_fire].x := monstr[i].x;
        fires[num_fire].y := monstr[i].y;
        fires[num_fire].z := monstr[i].z;

        fires[num_fire].vx := -0.45{*dsin}*sin(monstr[i].angle/180*Pi);
        fires[num_fire].vy := -0.45*dysin;
        fires[num_fire].vz := -0.45{*dcos}*cos(monstr[i].angle/180*Pi);
        fires[num_fire].angle := {monstr[i].angle}angle1;
        fires[num_fire].angle_y := monstr[i].angle_y;
//        fires[num_fire].t := 10;
        fires[num_fire].ind := 2+i;
        monstr[i].time := 0;
        fires[num_fire].tip := 1;
      end else begin
        genx1 := monstr[i].x;
        geny1 := monstr[i].z;
        genz1 := monstr[i].y;
        genx1 := genx1 -monstr[i].v{*dsin}*sin(monstr[i].angle/180*Pi);
        geny1 := geny1 -monstr[i].v{*dcos}*cos(monstr[i].angle/180*Pi);
        genz1 := genz1 -monstr[i].v{*dcos}*sin(monstr[i].angle_y/180*Pi);
//        if gen_m^[monstr[i].leven,round((geny1 + 10)*10),round((genx1 + 10)*10)] <> 255 then begin

      b := 0;
      if ((sqrt(sqr(myx-genx1)+sqr(myy-genz1)+sqr(myz-geny1))) <= 1) then begin
          b := 1;
        end;
//      b := 0;
      for l := 1 to kol_monstrs do
        if ((sqrt(sqr(monstr[l].x-genx1)+sqr(monstr[l].y-genz1)+sqr(monstr[l].z-geny1))) <= 1) and (monstr[l].vid<>4) and (l<>i) then begin
          b := 1;
        end;

        if b = 0 then begin
          monstr[i].x := genx1;
          monstr[i].z := geny1;
          monstr[i].y := genz1;
        end else begin
          monstr[i].x := monstr[i].x +3{*dsin}*sin(monstr[i].angle/180*Pi);
          monstr[i].z := monstr[i].z +3{*dcos}*cos(monstr[i].angle/180*Pi);
          monstr[i].angle := monstr[i].angle + random(2)*90 - 45;
//          myy := myy -10{*dcos}*sin(monstr[i].angle_y/180*Pi);
        end;

//          monstr[i].angle := angle;
//          monstr[i].y := (monstr[i].leven-1)*3 + {rostheihgt +}0.8+ (gen_m^[monstr[i].leven,round((geny1 + 10)*10),round((genx1 + 10)*10)]-100)/100*3;
//          monstr[i].leven := 1 + trunc(monstr[i].y / 3);
//          if (monstr[i].y < 0) and (monstr[i].y > -3) then
//            monstr[i].leven := 0;
//        end;
      end;
    end;
  end;
end;

procedure draw_pribors;
var
  i,j,k,l : longint;
begin
        glLoadIdentity;

        gldisable(GL_DEPTH_TEST);
        gldisable(gl_cull_face);

     for i:= 0to 99 do
        for j:= 0to 99 do begin
          pribors_tex[j+13,i+13,0] := 0;
          pribors_tex[j+13,i+13,1] := 0;
          pribors_tex[j+13,i+13,2] := 0;
        end;
      for i := 1 to kol_monstrs do
        if (round(abs(myx-monstr[i].x)) < 49) and (round(abs(myz-monstr[i].z)) < 49) then begin
          for k := 0 to 1 do
            for l := 0 to 1 do
              if monstr[i].vid = 4 then begin
                pribors_tex[50+13+k+round(myz-monstr[i].z),50+13+l+round(myx-monstr[i].x),0] := 255;
                pribors_tex[50+13+k+round(myz-monstr[i].z),50+13+l+round(myx-monstr[i].x),1] := 255;
              end else
                if (monstr[i].t >= 50) and (monstr[i].t < 100) then begin
                  pribors_tex[50+13+k+round(myz-monstr[i].z),50+13+l+round(myx-monstr[i].x),2] := 255;
                end else
                  pribors_tex[50+13+k+round(myz-monstr[i].z),50+13+l+round(myx-monstr[i].x),0] := 255;
        end;
      pribors_tex[50+13,50+13,1] := 255;
      DrawLine(50+13,50+13,round(50+13+45*sin(2*pi-angle/180*Pi-Pi/4)),round(50+13+45*cos(2*pi-angle/180*Pi-Pi/4)),255);
      DrawLine(50+13,50+13,round(50+13+45*sin(2*pi-angle/180*Pi+Pi/4)),round(50+13+45*cos(2*pi-angle/180*Pi+Pi/4)),255);
      DrawLine(50+13,50+13,round(50+13+45*sin(2*pi-angle/180*Pi)),round(50+13+45*cos(2*pi-angle/180*Pi)),150);


      for i:= 0 to 50 do
        for j:= 0to 99 do begin
          pribors_tex[j+13,i+6+128,0] := 0;
          pribors_tex[j+13,i+6+128,1] := 0;
          pribors_tex[j+13,i+6+128,2] := 0;
        end;
      pribors_tex[13+50,6+128+25,1] := 255;
      DrawLine(6+128+25,50+13,round(6+128+25+25*sin(2*pi-angle_y/180*Pi-Pi/4+Pi/2)),round(50+25+35*cos(2*pi-angle_y/180*Pi-Pi/4+Pi/2)),255);
      DrawLine(6+128+25,50+13,round(6+128+25+25*sin(2*pi-angle_y/180*Pi+Pi/4+Pi/2)),round(50+25+35*cos(2*pi-angle_y/180*Pi+Pi/4+Pi/2)),255);
      DrawLine(6+128+25,50+13,round(6+128+25+25*sin(2*pi-angle_y/180*Pi+Pi/2)),round(50+13+25*cos(2*pi-angle_y/180*Pi+Pi/2)),150);
      for i := 1 to kol_monstrs do
        if (round(abs(myz-monstr[i].z)) < 24) and (round(abs(myy-monstr[i].y)) < 49) then begin
          for k := 0 to 1 do
            for l := 0 to 1 do
              if monstr[i].vid = 4 then begin
                pribors_tex[50+13+k+round(myy-monstr[i].y),25+6+128+l-round(myz-monstr[i].z),0] := 255;
                pribors_tex[50+13+k+round(myy-monstr[i].y),25+6+128+l-round(myz-monstr[i].z),1] := 255;
              end else
                if (monstr[i].t >= 50) and (monstr[i].t < 100) then begin
                  pribors_tex[50+13+k+round(myy-monstr[i].y),25+6+128+l-round(myz-monstr[i].z),2] := 255;
                end else
                  pribors_tex[50+13+k+round(myy-monstr[i].y),25+6+128+l-round(myz-monstr[i].z),0] := 255;
        end;


     for i:= 0 to 7 do
        for j:= 0 to 99 do begin
          pribors_tex[j+13,i+128+63+128+8,0] := 0;
          pribors_tex[j+13,i+128+63+128+8,1] := 0;
          pribors_tex[j+13,i+128+63+128+8,2] := 0;
        end;
     for i:= 0 to 7 do
        for j:= 0 to 99 do begin
          pribors_tex[j+13,i+128+63+128+8+16,0] := 0;
          pribors_tex[j+13,i+128+63+128+8+16,1] := 0;
          pribors_tex[j+13,i+128+63+128+8+16,2] := 0;
        end;
     for i:= 0 to 7 do
        for j:= 0 to 99 do begin
          pribors_tex[j+13,i+128+63+128+8+32,0] := 0;
          pribors_tex[j+13,i+128+63+128+8+32,1] := 0;
          pribors_tex[j+13,i+128+63+128+8+32,2] := 0;
        end;
     for i:= 0 to 7 do
        for j:= (100 - round(pole_life)) to 99 do begin
          pribors_tex[j+13,i+128+63+128+8,1] := 200;
        end;
     for i:= 0 to 7 do
        for j:= (100 - pole_fire) to 99 do begin
          pribors_tex[j+13,i+128+63+128+8+16,1] := 200;
        end;
     for i:= 0 to 7 do
        for j:= (100 - {pole_full}round(100*spend/0.3)) to 99 do begin
          pribors_tex[j+13,i+128+63+128+8+32,1] := 200;
        end;


     for i:= 0 to 128 do
        for j:= 0to 99 do begin
          pribors_tex[j+13,i+128+63,0] := 0;
          pribors_tex[j+13,i+128+63,1] := {random(256)}0;
          pribors_tex[j+13,i+128+63,2] := 0;
        end;
     text_out_indeficator := 2;
     puttext(192,15,'а ЄҐвл ' + IntToStr(kol_rakets));
     text_out_indeficator := 1;

     case regim_draw_pribor_panel of
       1:begin
//        regim_draw_pribor_panel = 1 then begin
        gltexparameteri(gl_texture_2d,gl_texture_mag_filter,gl_nearest);
        gltexparameteri(gl_texture_2d,gl_texture_min_filter,gl_nearest{gl_linear});
        glteximage2d(gl_texture_2d,0,GL_RGBA,512,128,0,GL_RGBA,GL_unsigned_byte,@pribors_tex);

        glEnable(gl_texture_2d);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, -0.6, -1);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, -0.6, -1);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -1);
        glEnd;
        glDisable(gl_texture_2d);
       end;
       3:begin
           GLD_Draw(dc,1,0,-0.5,-0.75,0,8);
         end;
     end;

        glBegin(GL_POLYGON);
          glNormal3f(0.0, 0.0, -1);
          glVertex3f(-0.1, 0.00235, -1);
          glVertex3f(0.1, 0.00235, -1);
          glVertex3f(0.1, -0.00235, -1);
          glVertex3f(-0.1, -0.00235, -1);
        glEnd;
        glBegin(GL_POLYGON);
          glNormal3f(0.0, 0.0, -1);
          glVertex3f(-0.003, 0.1, -1);
          glVertex3f(0.003, 0.1, -1);
          glVertex3f(0.003, -0.1, -1);
          glVertex3f(-0.003, -0.1, -1);
        glEnd;
end;

procedure draw_textura_map;
begin
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi-Pi/4))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi-Pi/4))-round(myz/2250*255),255);
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi+Pi/4))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi+Pi/4))-round(myz/2250*255),255);
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi))-round(myz/2250*255),150);

      if your_mission = 2 then begin
        DrawLine2(255-round(monstr[3].x/2250*255),255-round(monstr[3].z/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(monstr[3].x/2250*255),round(255+5*cos(2*pi-0/180*Pi))-round(monstr[3].z/2250*255),150);
        DrawLine2(255-round(monstr[3].x/2250*255),255-round(monstr[3].z/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(monstr[3].x/2250*255),round(255+5*cos(2*pi-90/180*Pi))-round(monstr[3].z/2250*255),150);
      end;


         gldisable(GL_DEPTH_TEST);
         gllightmodelf(gl_light_model_two_side,1);
         gldisable(gl_cull_face);

         gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
         gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
         glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,space_map_textura);

         glEnable(gl_texture_2d);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, 1, -1);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, 1, -1);
        glEnd;
        glDisable(gl_texture_2d);
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi-Pi/4))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi-Pi/4))-round(myz/2250*255),0);
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi+Pi/4))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi+Pi/4))-round(myz/2250*255),0);
      DrawLine2(255-round(myx/2250*255),255-round(myz/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(myx/2250*255),round(255+5*cos(2*pi-angle/180*Pi))-round(myz/2250*255),0);


      if your_mission = 2 then begin
        DrawLine2(255-round(monstr[3].x/2250*255),255-round(monstr[3].z/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(monstr[3].x/2250*255),round(255+5*cos(2*pi-0/180*Pi))-round(monstr[3].z/2250*255),0);
        DrawLine2(255-round(monstr[3].x/2250*255),255-round(monstr[3].z/2250*255),round(255+5*sin(2*pi-angle/180*Pi))-round(monstr[3].x/2250*255),round(255+5*cos(2*pi-90/180*Pi))-round(monstr[3].z/2250*255),0);
      end;
end;

procedure draw_textura_pich;
//var
//  l : GLUint;
begin

         gldisable(GL_DEPTH_TEST);
         gllightmodelf(gl_light_model_two_side,1);
         gldisable(gl_cull_face);

//      l :=glgenlists(1);
//      glnewlist(l, {GL_compile}-1);

         gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
         gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
         glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);

//      glendlist;

//      glcalllist(l);
         glEnable(gl_texture_2d);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, 1, -1);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, 1, -1);
        glEnd;
        glDisable(gl_texture_2d);


//        glDeleteLists(L, 1);

end;

procedure draw_textura_zastavka;
//var
//  l : GLUint;
begin

//         gldisable(GL_DEPTH_TEST);
         gllightmodelf(gl_light_model_two_side,1);
         gldisable(gl_cull_face);
        glTranslatef(0, 0,0.75-timer_bool/40);


{      if timer_bool < 500 then begin
        glcalllist(zastavka_list1);
         glEnable(gl_texture_2d);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, 1, -1);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, 1, -1);
        glEnd;
        glDisable(gl_texture_2d);
      end;}

        glenable(GL_DEPTH_TEST);
        glClearDepth(1.0);

        glcalllist(zastavka_list2);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight*5,-5, -1.0*15+15);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight*5,-5, -1.0*15+15);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight*5,-5, 1*15+15);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight*5,-5, 1*15+15);
        glEnd;
        glDisable(gl_texture_2d);

        glcalllist(zastavka_list3);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight*5,-5, -1.0*15+15+35);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight*5,-5, -1.0*15+15+35);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight*5,-5, 1*15+15+35);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight*5,-5, 1*15+15+35);
        glEnd;
        glDisable(gl_texture_2d);

        glLoadIdentity;
        glcalllist(zastavka_list4);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -3);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -3);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, 1, -3);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, 1, -3);
        glEnd;
        gldisable(GL_BLEND);
        glDisable(gl_texture_2d);

         gldisable(GL_DEPTH_TEST);
      if timer_bool < 500 then begin
        glTranslatef(0, 0,0.75-timer_bool/40);
        glcalllist(zastavka_list1);
         glEnable(gl_texture_2d);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight, -1.0, -1);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight, 1, -1);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight, 1, -1);
        glEnd;
        glDisable(gl_texture_2d);
      end;
end;

procedure draw_textura_film1;
//var
//  l : GLUint;
begin

         gldisable(GL_DEPTH_TEST);
         gllightmodelf(gl_light_model_two_side,1);
         gldisable(gl_cull_face);
        glTranslatef(0, 0,0.75-timer_bool/40);



        glcalllist(zastavka_list1);

        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(-WndWidth/WndHeight*5,-5, -1.0*15+7);
        gltexcoord2f(1,0); glVertex3f(WndWidth/WndHeight*5,-5, -1.0*15+7);
        gltexcoord2f(1,-1); glVertex3f(WndWidth/WndHeight*5,-5, 1*15+7);
        gltexcoord2f(0,-1); glVertex3f(-WndWidth/WndHeight*5,-5, 1*15+7);
        glEnd;
        glDisable(gl_texture_2d);

end;

procedure readspacemodels1;{тренеровочный полет}
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

          bmpp5(0,'loading.bmp');
          draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,{'ship4.3ds'}'model_x1.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'model_x3.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x4.x',2,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'banka2.3ds'{'banka_x.x'},1,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'fire1.3ds',1{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,'a.3ds',1,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'raketa.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'a.3ds',1,9,1); {}

  ReadModel(wnd,'a.3ds',1,10,1); {}
  ReadModel(wnd,'a.3ds',1,11,1); {}
  ReadModel(wnd,'a.3ds',1,12,1); {}

  ReadModel(wnd,'globe.x'{'banka_x.x'},2,13,1); {}

  ReadModel(wnd,'a.3ds',1,14,1); {}
  ReadModel(wnd,'a.3ds',1,15,1); {}
  ReadModel(wnd,'a.3ds',1,16,1); {}
  ReadModel(wnd,'a.3ds',1,17,1); {}
  ReadModel(wnd,'a.3ds',1,18,1); {}
  ReadModel(wnd,'a.3ds',1,19,1); {}
  ReadModel(wnd,'a.3ds',1,20,1); {}
  ReadModel(wnd,'a.3ds',1,21,1); {}
  ReadModel(wnd,'a.3ds',1,22,1); {}
  ReadModel(wnd,'a.3ds',1,23,1); {}
  ReadModel(wnd,'a.3ds',1,24,1); {}
  ReadModel(wnd,'a.3ds',1,25,1); {}
end;

procedure readspacemodels2;{миссия}
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

             bmpp5(0,'loading.bmp');
             draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,{'ship4.3ds'}'model_x1.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'model_x3.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x4.x',2,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'banka2.3ds'{'banka_x.x'},1,5,1/10); {}
//  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,5,3); {}

  ReadModel(wnd,'fire1.3ds',1{'globle.x',2},6,1/3); {}
//  ReadModel(wnd,'fire.x',2,6,1); {}

  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'model_x2.x',2,7,15); {}
  ReadModel(wnd,{'duck.3ds',1}'raketa.x',2,{'globe.x',2,}8,1/2); {}
  ReadModel(wnd,'ship3_b.3ds',1,9,1); {}

  ReadModel(wnd,'model_x5.x',2,10,1); {}
  ReadModel(wnd,'model_x6.x',2,11,1); {}
  ReadModel(wnd,'asteroid.x'{'banka_x.x'},2,12,3); {}

  ReadModel(wnd,'globe.x'{'banka_x.x'},2,13,1); {}

  ReadModel(wnd,'a.3ds',1,14,1); {}
  ReadModel(wnd,'a.3ds',1,15,1); {}
  ReadModel(wnd,'a.3ds',1,16,1); {}
  ReadModel(wnd,'a.3ds',1,17,1); {}
  ReadModel(wnd,'a.3ds',1,18,1); {}
  ReadModel(wnd,'a.3ds',1,19,1); {}
  ReadModel(wnd,'a.3ds',1,20,1); {}
  ReadModel(wnd,'a.3ds',1,21,1); {}
  ReadModel(wnd,'a.3ds',1,22,1); {}
  ReadModel(wnd,'a.3ds',1,23,1); {}
  ReadModel(wnd,'a.3ds',1,24,1); {}
  ReadModel(wnd,'a.3ds',1,25,1); {}
end;

procedure read3dbarmodels;
begin
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          kol_objekts := 0;

          GLD_Destroy(dc);
          Prer_Param;

             bmpp5(0,'loading.bmp');
             draw_textura_pich;

          ReadModel(wnd,'a.3ds',1,0,1); {}

  ReadModel(wnd,'a.3ds',1,1,1); {}
  ReadModel(wnd,'a.3ds',1,2,1); {}
  ReadModel(wnd,'a.3ds',1,3,1); {}
  ReadModel(wnd,'a.3ds',1,4,1); {}
  ReadModel(wnd,'a.3ds',1,5,1); {}
  ReadModel(wnd,'a.3ds',1,6,1); {}
  ReadModel(wnd,'a.3ds',1,7,1); {}
  ReadModel(wnd,'a.3ds',1,8,1); {}
  ReadModel(wnd,'a.3ds',1,9,1); {}
  ReadModel(wnd,'a.3ds',1,10,1); {}
  ReadModel(wnd,'a.3ds',1,11,1); {}
  ReadModel(wnd,'a.3ds',1,12,1); {}
  ReadModel(wnd,'a.3ds',1,13,1); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'seg056.x'{'banka_x.x'},2,14,10); {}
  ReadModel(wnd,'seg052.x'{'banka_x.x'},2,15,10); {}
  ReadModel(wnd,'seg051.x'{'banka_x.x'},2,16,10); {}
  ReadModel(wnd,'seg055.x'{'banka_x.x'},2,17,10); {}
  ReadModel(wnd,'seg057.x'{'banka_x.x'},2,18,10); {}
  ReadModel(wnd,'cafe1.3ds'{'banka_x.x'},1,19,2.3); {}
  ReadModel(wnd,'duck.3ds'{'banka_x.x'},1,20,0.5); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});

  ReadModel(wnd,'model_x1.x',2,21,9); {}
  ReadModel(wnd,'model_x1.x',2,22,0.5); {}

  chdir(chdirstr+'\data2'{'d:\programs\games\space06\data'});
  read3dbarsegments;

  ReadModel(wnd,'man1.x',2,23,2); {}
  ReadModel(wnd,'man2.x',2,24,2); {}
  ReadModel(wnd,'man3.x',2,25,2); {}
  ReadModel(wnd,'table.x',2,26,2); {}
  ReadModel(wnd,'man6.x',2,27,2); {}
  ReadModel(wnd,'man4.x',2,28,2); {}

  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});
end;       (*********)


procedure draw_victory;
var
  l,k : longint;
  i,j : single;
begin
        bmpp5(0,'victory.bmp');
//        puttext(10,420,'It is victory!!!  :-)');
//            read_model_constant := 2;
//          read3dbarmodels;
        case your_mission of
          0:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

                mission_score := 9 - l;
                if l = 0 then inc(mission_score);
{              if l = 0 then
                puttext(10,470,'very GOOD  :-)');
              if l = 1 then
                puttext(10,470,'GOOD  :-)');
              if l = 2 then
                puttext(10,470,'NORMAL  :-|');
              if l = 3 then
                puttext(10,470,'BAD  :-(');
              if l = 4 then
                puttext(10,470,'very BAD  :-((');}
            end;
          1:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

              mission_score := 4 - (l-1);
              if (monstr[3].heard > 0) then inc(mission_score,11);

{              if (monstr[3].heard > 0) then
                puttext(10,470,'GOOD  :-)');
              if (monstr[3].heard <= 0) then
                puttext(10,470,'BAD  :-(');}
            end;
          2:begin
              if (monstr[3].heard <= 0) then inc(mission_score,20);


{              if (monstr[3].heard <= 0) then
                puttext(10,470,'GOOD  :-)');
              if (monstr[3].heard > 0) then
                puttext(10,470,'BAD  :-(');}
            end;
          3:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

                mission_score := 14 - l;
                if l = 0 then inc(mission_score,11);
            end;
        end;
        inc(your_mission);

        l := 0;
        case your_mission-1 of
          0: l := 10;
          1: l := 25;
          2: l := 70;
          3: l := 105;
          4: l := 140;
        end;
        case your_mission-1 of
          0: j := mission_score/10;
          1: j := mission_score/15;
          2: j := mission_score/20;
          3: j := mission_score/25;
          4: j := mission_score/35;
        end;
        score := score + mission_score;
        puttext(150,500,'score mission ' + inttostr(mission_score) + ' your score ' + inttostr(score)
         + ' max score ' + inttostr(l));
        if j > 0.5 then begin
          for k := repliks[your_mission-1].n_c_v to repliks[your_mission-1].k_c_v-1 do
            puttext(5,330+(k-repliks[your_mission-1].n_c_v)*10,texts_missions_str[k]);
        end else begin
          for k := repliks[your_mission-1].n_c_p to repliks[your_mission-1].k_c_p-1 do
            puttext(5,330+(k-repliks[your_mission-1].n_c_p)*10,texts_missions_str[k]);
        end;

        mission_score := 0;
end;

procedure timeproc(uTimerid,umessage:uint; dwuser,dw1,dw2:dword)stdcall;
var
  k,l,k1,i,j : longint;
  genx1,geny1,genz1 : single;
begin
if g_bActive then begin
 timer_bool := timer_bool + 1;

 case regim of
  10: begin
   case your_mission of
     0: begin
          if (sqrt(sqr(341-myx)+sqr(742-myz)) <= 350) then
            asteroids_pole := true
          else
            asteroids_pole := false;
        end;
     1: begin
          if (sqrt(sqr(-51-myx)+sqr(633-myz)) <= 365) then
            asteroids_pole := true
          else
            asteroids_pole := false;
        end;
     2: begin
          if (sqrt(sqr(1172-myx)+sqr(1263-myz)) <= 415) then
            asteroids_pole := true
          else
            asteroids_pole := false;
        end;
     3: begin
          if (sqrt(sqr(256-myx)+sqr(894-myz)) <= 127) or (sqrt(sqr(658-myx)+sqr(-143-myz)) <= 276) then
            asteroids_pole := true
          else
            asteroids_pole := false;
        end;
     4: begin
          asteroids_pole := false;
        end;
   end;

   if pole_fire < 100 then
     inc(pole_fire{,4});
  if (pole_life < 100) and (pole_life >= 0.5) then
    pole_life := pole_life + 0.01;


  for k := 1 to 30 do begin
    mysors[k].angle := mysors[k].angle + 0.5;
    if mysors[k].Angle > 360.0 then mysors[k].Angle := mysors[k].angle - 360;
    if mysors[k].Angle < 0.0 then mysors[k].Angle := mysors[k].angle + 360;
    mysors[k].angle_y := mysors[k].angle_y + 0.5;
    if mysors[k].Angle_y > 360.0 then mysors[k].Angle_y := mysors[k].angle_y - 360;
    if mysors[k].Angle_y < 0.0 then mysors[k].Angle_y := mysors[k].angle_y + 360;

    if sqrt(sqr(mysors[k].x-myx)+sqr(mysors[k].y-myy)+sqr(mysors[k].z-myz)) > 25 then begin
      mysors[k].x := myx+random(40)-20;
      mysors[k].y := myy+random(40)-20;
      mysors[k].z := myz+random(40)-20;
      mysors[k].angle := random(100);
      mysors[k].angle_y := random(100);
    end;
  end;


  if asteroids_pole then
    for k := 1 to num_fire do                   {на пересечение с астероидами}
     for k1 := 1 to 30 do begin
      if   (abs(abs(fires[k].z) - abs(asteroids[k1].z)) < 1.5)
                  and (abs(abs(fires[k].x) - abs(asteroids[k1].x)) < 1.5)
                  and (abs(abs(fires[k].y) - abs(asteroids[k1].y)) < 1.5) then begin
        for l := k to num_fire do
          fires[l] := fires[l+1];
        num_fire := num_fire - 1;

        dec(asteroids[k1].heard);
      end;
       if  (abs(abs(asteroids[k1].z) - abs(myz)) < 1.5)
                  and (abs(abs(asteroids[k1].x) - abs(myx)) < 1.5)
                  and (abs(abs(asteroids[k1].y) - abs(myy)) < 1.5) then begin
         asteroids[k1].heard:=0;

         dec(mylive);
         if pole_life >= 10 then
           pole_life := pole_life -5;
         if (pole_life > 0) and (pole_life < 10) then
           pole_life := 0;
       end;
     end;




  for k := 1 to 30 do begin
    asteroids[k].angle := asteroids[k].angle + 0.5;
    if asteroids[k].Angle > 360.0 then asteroids[k].Angle := asteroids[k].angle - 360;
    if asteroids[k].Angle < 0.0 then asteroids[k].Angle := asteroids[k].angle + 360;
    asteroids[k].angle_y := asteroids[k].angle_y + 0.5;
    if asteroids[k].Angle_y > 360.0 then asteroids[k].Angle_y := asteroids[k].angle_y - 360;
    if asteroids[k].Angle_y < 0.0 then asteroids[k].Angle_y := asteroids[k].angle_y + 360;

    if (sqrt(sqr(asteroids[k].x-myx)+sqr(asteroids[k].y-myy)+sqr(asteroids[k].z-myz)) > 80) or (asteroids[k].heard<=0) then begin
      asteroids[k].angle := random(100);
      asteroids[k].angle_y := random(100);

      asteroids[k].x := myx+{random(40)-20}70*cos(asteroids[k].angle);
      asteroids[k].y := myy+70*sin(asteroids[k].angle_y){random(40)-20};
      asteroids[k].z := myz+{random(40)-20}70*sin(asteroids[k].angle);
      asteroids[k].angle := random(100);
      asteroids[k].angle_y := random(100);
      asteroids[k].heard := 3;
    end;
  end;

  for k := 1 to num_fire do begin                  {на пересечение со стенами}
    if fires[k].tip = 2 then begin
      steprakets(k);
      if (fires[k].angle_y > 90) and (fires[k].angle_y < 270) then l := -1 else l := 1;
      fires[k].vx := -0.3*l*sin(fires[k].angle/180*Pi){+ spend*k*sin(angle/180*Pi)};
      fires[k].vy := -0.3*sin(fires[k].angle_y/180*Pi){- spend*sin(angle_y/180*Pi)};
      fires[k].vz := -0.3*l*cos(fires[k].angle/180*Pi){- spend*k*cos(angle/180*Pi)};
    end;

    fires[k].x := fires[k].x + fires[k].vx;
    fires[k].y := fires[k].y + fires[k].vy;
    fires[k].z := fires[k].z + fires[k].vz;

{    if fires[k].t < -5 then begin
      for l := k to num_fire do
        fires[l] := fires[l+1];
      num_fire := num_fire - 1;
    end;

    if fires[k].t < 10 then dec(fires[k].t);}

//    if (((fires[k].x > 15) or (fires[k].x < -15)) or ((fires[k].y > 15) or (fires[k].y < -15))
//      or ((fires[k].z > 15) or (fires[k].z < -15))) {or
//      (gen_m^[leven,round((fires[k].z + 10)*10),round((fires[k].x + 10)*10)] = 255)} then begin
    if sqrt(sqr(fires[k].x-myx)+sqr(fires[k].y-myy)+sqr(fires[k].z-myz)) > 75 then begin
      for l := k to num_fire do
        fires[l] := fires[l+1];
      num_fire := num_fire - 1;
    end;
  end;

  for k := 1 to num_fire do                   {на пересечение с монстрами}
   for k1 := 1 to kol_monstrs do begin
    if  (abs(abs(fires[k].z) - abs(monstr[k1].z)) < 0.5) and ( ((fires[k].ind <> k1+2) and (active_mission = 1)) or ((fires[k].ind=1)and(active_mission = -1)) )
                and (abs(abs(fires[k].x) - abs(monstr[k1].x)) < 0.5)
                and (abs(abs(fires[k].y) - abs(monstr[k1].y)) < 0.5) and (monstr[k1].heard>0) {and (fires[k].t=10)  } then begin


//      fires[k].vx := -monstr[k1].v*cos(monstr[k1].angle/180*Pi);
//      fires[k].vy := -monstr[k1].v*sin(monstr[k1].angle_y/180*Pi);
//      fires[k].vz := -monstr[k1].v*sin(monstr[k1].angle/180*Pi);
//      dec(fires[k].t);
      monstr[k1].time_lighting := 35;
      dec(monstr[k1].heard);
      if fires[k].tip = 2 then
        monstr[k1].heard := 0;

      for l := k to num_fire do
        fires[l] := fires[l+1];
      num_fire := num_fire - 1;

//      monstr[k1].vid := random(3)+1;

{                 if play_wave then begin
                   sndPlaySound('killed.wav', 1);
//                   play_wave := false;
                 end;}
      if monstr[k1].heard = 0 then begin
        if (active_mission = -1) and (monstr[k1].vid<>4) then begin
          j := 0;
          for i := 1 to kol_monstrs do
            if monstr[i].heard > 0 then
              j := 1;
          if j = 0 then begin
            inc(active_mission_false_step);
            for i := 1 to active_mission_false_step do begin
              inc(kol_monstrs);
              monstr[kol_monstrs].x := random(50); monstr[kol_monstrs].y := random(10); monstr[kol_monstrs].z := random(50); monstr[kol_monstrs].vid := {8}random(3)+1; monstr[kol_monstrs].t := 1; monstr[kol_monstrs].heard := 10; monstr[kol_monstrs].leven := 1;
              monstr[kol_monstrs].time_lighting := 0;
            end;
          end;
        end;
        monstr[k1].vid := 4;
        monstr[k1].faza_texture_babax := -1;
        monstr[k1].time := 0;
        play_wave2 := true;
      end;
    end;
   end;
  for k := 1 to num_fire do                   {на пересечение с игроком}
   if  (abs(abs(fires[k].z) - abs(myz)) < 0.5) and (fires[k].ind >= 2)
                and (abs(abs(fires[k].x) - abs(myx)) < 0.5)
                and (abs(abs(fires[k].y) - abs(myy)) < 0.5) then begin
      for l := k to num_fire do
        fires[l] := fires[l+1];
      num_fire := num_fire - 1;
      dec(mylive);
      if pole_life >= 10 then
        pole_life := pole_life -10;
      if (pole_life > 0) and (pole_life < 10) then
        pole_life := 0;
   end;

  stepmonstrs;

  for l := 1 to kol_monstrs do
    if monstr[l].vid = 4 then
      if {timer_bool}monstr[l].time mod 7 = 6 then
        if monstr[l].faza_texture_babax = 15 then begin
          monstr[l].faza_texture_babax := 0;
          monstr[l].leven := 0;
//         for k := 1 to kol_monstrs do if monstr[k].vid = 4 then monstr[k].leven := 0;
    end else inc(monstr[l].faza_texture_babax);

      if not ((diks[$1E] and $80) <> 0) then begin {ВПЕРЕД}
        if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;

         if  not ((diks[$0F] and $80) <> 0) then begin
          genx1 := myx + spend*k*sin(angle/180*Pi);
          geny1 := myz - spend*k*cos(angle/180*Pi);
          genz1 := myy - spend*sin(angle_y/180*Pi);
         end else begin
          if (timer_bool mod 92) = 0 then
            play_wave3 := true;
          genx1 := myx + 1*k*sin(angle/180*Pi);
          geny1 := myz - 1*k*cos(angle/180*Pi);
          genz1 := myy - 1*sin(angle_y/180*Pi);
         end;

   if  (   ((abs(abs(base_z) - abs(geny1)) < 0.5*30) and (abs(abs(base_x) - abs(genx1)) < 0.5*20)
                and (abs(abs(base_y) - abs(genz1)) < 0.5*10))) and (active_mission = 1) then begin
     k := 0;
     if  (   ((abs(abs(base_z) - abs(myz)) < 0.5*30) and (abs(abs(base_x) - abs(genx1)) < 0.5*20)
                and (abs(abs(base_y) - abs(myy)) < 0.5*10)))   and (k=0) then  begin
        myy := genz1;
        myz := geny1;
        k := 1;
     end;
     if  (   ((abs(abs(base_z) - abs(geny1)) < 0.5*30) and (abs(abs(base_x) - abs(myx)) < 0.5*20)
                and (abs(abs(base_y) - abs(myy)) < 0.5*10))) and (k=0) then  begin
        myx := genx1;
        myy := genz1;
        k := 1;
     end;
     if  (   ((abs(abs(base_z) - abs(myz)) < 0.5*30) and (abs(abs(base_x) - abs(myx)) < 0.5*20)
                and (abs(abs(base_y) - abs(genz1)) < 0.5*10))) or (active_mission = -1) and (k=0)then begin
        myx := genx1;
        myz := geny1;
        k := 1;
     end;

   end else begin
      k := 0;
      for l := 1 to kol_monstrs do
        if ((sqrt(sqr(monstr[l].x-genx1)+sqr(monstr[l].y-genz1)+sqr(monstr[l].z-geny1))) <= 1) and (monstr[l].vid<>4) then begin
          k := 1;
        end;

        if k = 0 then begin
          myx := genx1;
          myz := geny1;
          myy := genz1;
        end else begin
          if pole_life >= 1 then
            pole_life := pole_life -1;
          if (pole_life > 0) and (pole_life < 1) then
            pole_life := 0;
        end;
   end;
      end;


  UpdateInputState(wnd);
      if (diks[$C8] and $80) <> 0 then begin {вниз}
        angle_y2 := angle_y + 3.5;
        if Angle_y2 > 360.0 then Angle_y2 := angle_y2 - 360;
        angle_y := angle_y2;
        angle2 := 0;
      end;
      if (diks[$D0] and $80) <> 0 then begin  {вверх}
        angle_y2 := angle_y - 3.5;
        if Angle_y2 < 0 then Angle_y2 := angle_y2 + 360;
        angle_y := angle_y2;
        angle2 := 0;
      end;
      if (diks[$CD] and $80) <> 0 then begin  {вправо}
        if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;

        if Angle > 360.0 then Angle := angle - 360;
        angle := angle + k*3.5;
        angle2 := angle2 + k*3.5;

       if (angle_y2 > 90) and (angle_y2 < 270) then begin
        if angle_y2 <=180 then
          angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180
        else
          angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180;
       end else begin
        if angle_y2 <=180 then
          angle_y := (cos(angle2/180*Pi))*angle_y2
        else
          angle_y := -(cos(angle2/180*Pi))*(360 -angle_y2);
       end;
        if Angle_y > 360.0 then Angle_y := angle_y - 360;
      end;
      if (diks[$CB] and $80) <> 0 then begin  {влево}
        if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;

        if Angle < 0 then Angle := angle + 360;
        angle := angle - k*3.5;
        angle2 := angle2 - k*3.5;

{        if angle_y2 <=180 then
          angle_y := (cos(angle2/180*Pi))*angle_y2
        else
          angle_y := -(cos(angle2/180*Pi))*(360 -angle_y2);}
       if (angle_y2 > 90) and (angle_y2 < 270) then begin
        if angle_y2 <=180 then
          angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180
        else
          angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180;
       end else begin
        if angle_y2 <=180 then
          angle_y := (cos(angle2/180*Pi))*angle_y2
        else
          angle_y := -(cos(angle2/180*Pi))*(360 -angle_y2);
       end;
        if Angle_y > 360.0 then Angle_y := angle_y - 360;
      end;

      if (diks[$4E] and $80) <> 0 then begin  {+ скорость}
        if spend < {2}0.3 then
        spend := spend + 0.01;
      end;
      if (diks[$4A] and $80) <> 0 then begin  {- скорость}
        if spend > 0.01 then
          spend := spend - 0.01;
      end;
      if (diks[$CF] and $80) <> 0 then begin  {голову прямо}
        angle_y2 := 0;
        angle_y := angle_y2;
      end;

      if (diks[$3B] and $80) <> 0 then begin  {вид с приборной панелью}
        regim_draw_pribor_panel := 1;
      end;
      if (diks[$3C] and $80) <> 0 then begin  {вид без приборной панели}
        regim_draw_pribor_panel := 2;
      end;
      if (diks[$3D] and $80) <> 0 then begin  {вид с кораблем}
        regim_draw_pribor_panel := 3;
      end;
//      if (diks[$39] and $80) <> 0 then begin              {прыжок}
//        if myy <= 0.01+((leven-1)*3 + rostheihgt + (gen_m^[leven,round((myz + 10)*10),round((myx + 10)*10)]-100)/100*3) then
//          myvy := 0.09;
//      end;

      if (diks[$1D] and $80) <> 0 then begin  {огонь}
        if (num_fire < 500) and (timer_bool > 10) and (pole_fire>25{99}) then begin
          dec(pole_fire,25{100});

//          MyMedia.play;   {звук выстрела}

          play_wave := true;
{      if play_wave then begin
        sndPlaySound('fire.wav', 1);
        play_wave := false;
      end;}

          num_fire := num_fire + 1;

          if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;

          fires[num_fire].vx := 0.3*k*sin(angle/180*Pi)+ spend*k*sin(angle/180*Pi);
          fires[num_fire].vy := -0.3*sin(angle_y/180*Pi)- spend*sin(angle_y/180*Pi);
          fires[num_fire].vz := -0.3*k*cos(angle/180*Pi)- spend*k*cos(angle/180*Pi);

          fires[num_fire].x := myx + fires[num_fire].vx*2;
          fires[num_fire].y := myy + fires[num_fire].vy*2;
          fires[num_fire].z := myz + fires[num_fire].vz*2;
//          fires[num_fire].t := 10;

          fires[num_fire].angle := -angle;
          fires[num_fire].angle_y := angle_y;

          fires[num_fire].ind := 1;
          fires[num_fire].tip := 1;

          timer_bool := 0;
        end;
      end;
      if (diks[$1C] and $80) <> 0 then begin  {Ракета}
        if (kol_rakets > 0) and (num_fire < 500) and (timer_bool > 25) {and (pole_fire>25)} then begin
          dec(kol_rakets);
//          MyMedia.play;   {звук выстрела}

//          play_wave := true;
{      if play_wave then begin
        sndPlaySound('fire.wav', 1);
        play_wave := false;
      end;}

          num_fire := num_fire + 1;

          if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;

          fires[num_fire].vx := 0.3*k*sin(angle/180*Pi)+ spend*k*sin(angle/180*Pi);
          fires[num_fire].vy := -0.3*sin(angle_y/180*Pi)- spend*sin(angle_y/180*Pi);
          fires[num_fire].vz := -0.3*k*cos(angle/180*Pi)- spend*k*cos(angle/180*Pi);

          fires[num_fire].x := myx + fires[num_fire].vx*2;
          fires[num_fire].y := myy + fires[num_fire].vy*2;
          fires[num_fire].z := myz + fires[num_fire].vz*2;
//          fires[num_fire].t := 10;

          fires[num_fire].angle := -angle;
          fires[num_fire].angle_y := angle_y;

          fires[num_fire].ind := 1;
          fires[num_fire].tip := 2;

          timer_bool := 0;
        end;
      end;
      if (diks[$32] and $80) <> 0 then begin  {карта}
        if (timer_bool > 20) then begin
          if regim = 10 then
            regim := 11
          else
            regim := 10;
          timer_bool := 0;
        end;
      end;



      if (diks[$46] and $80) <> 0 then begin   {коды}
        KOL_RAKETS := 100;
      end;




      if (diks[$01] and $80) <> 0 then if (timer_bool > 20) then begin{выход в меню 2}
               play_midi := true;
        bmpp5(0,'menu01.bmp');
        regim := 2;
        timer_bool := 0;

        myx := 0; myy := 2.1; myz :=0;

            read_model_constant := 2;
//          read3dbarmodels;


//        if draw_3d_bar then
//          read3dbarmodels;
//          SendMessage(wnd, WM_CLOSE, 0, 0);
      end;
      if (diks[$2E] and $80) <> 0 then if (timer_bool > 20) and (active_mission = 1) then begin{связь победа выход в меню 2}
               play_midi := true;
            read_model_constant := 2;
(*        bmpp5(0,'victory.bmp');
        puttext(10,420,'It is victory!!!  :-)');
            read_model_constant := 2;
//          read3dbarmodels;
        case your_mission of
          0:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

                mission_score := 9 - l;
                if l = 0 then inc(mission_score);
{              if l = 0 then
                puttext(10,470,'very GOOD  :-)');
              if l = 1 then
                puttext(10,470,'GOOD  :-)');
              if l = 2 then
                puttext(10,470,'NORMAL  :-|');
              if l = 3 then
                puttext(10,470,'BAD  :-(');
              if l = 4 then
                puttext(10,470,'very BAD  :-((');}
            end;
          1:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

              mission_score := 4 - (l-1);
              if (monstr[3].heard > 0) then inc(mission_score,11);

              if (monstr[3].heard > 0) then
                puttext(10,470,'GOOD  :-)');
              if (monstr[3].heard <= 0) then
                puttext(10,470,'BAD  :-(');
            end;
          2:begin
              if (monstr[3].heard <= 0) then inc(mission_score,20);


              if (monstr[3].heard <= 0) then
                puttext(10,470,'GOOD  :-)');
              if (monstr[3].heard > 0) then
                puttext(10,470,'BAD  :-(');
            end;
          3:begin
              l := kol_monstrs;
              for k := 1 to kol_monstrs do if monstr[k].heard <= 0 then dec(l);

                mission_score := 14 - l;
                if l = 0 then inc(mission_score,11);
            end;
        end;
        inc(your_mission);    *)
        regim := 8;
        timer_bool := 0;

(*        l := 0;
        case your_mission-1 of
          0: l := 10;
          1: l := 25;
          2: l := 70;
          3: l := 105;
          4: l := 140;
        end;
        score := score + mission_score;
        puttext(150,500,'score mission ' + inttostr(mission_score) + ' your score ' + inttostr(score)
         + ' max score ' + inttostr(l));

        mission_score := 0;*)
//          SendMessage(wnd, WM_CLOSE, 0, 0);
      end;
//  myy := myy + myvy;
//  if myy > 0.01+((leven-1)*3 + rostheihgt + (gen_m^[leven,round((myz + 10)*10),round((myx + 10)*10)]-100)/100*3) then begin
//    myvy := myvy - myg;
//    myy := myy + myvy;
//  end else begin
//    myvy := 0;
//    myy := ((leven-1)*3 + rostheihgt + (gen_m^[leven,round((myz + 10)*10),round((myx + 10)*10)]-100)/100*3);
//  end;
//  leven := 1 + trunc(myy / 3);
//  if (myy < 0) and (myy > -3) then
//    leven := 0;

//       messagebeep(0);
  end;
  11:begin
      UpdateInputState(wnd);
      if (diks[$32] and $80) <> 0 then begin  {карта}
        if (timer_bool > 20) then begin
          if regim = 10 then
            regim := 11
          else
            regim := 10;
          timer_bool := 0;
        end;
      end;
     end;
  1 :begin
      UpdateInputState(wnd);
      if ((diks[$02] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=18)and(mousey<=32)) then if (timer_bool > 20) then begin
                                                                                           {меню 2}
          mousekey := 0;
          regim := 2;
          if not draw_3d_bar then
            bmpp5(0,'menu01.bmp');
          timer_bool := 0;
      end;
      if ((diks[$04] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=50)and(mousey<=63)) then if (timer_bool > 20) then begin
                                                                                   {выход в меню 3}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
      end;
      if ((diks[$05] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=66)and(mousey<=78)) then if (timer_bool > 20) then begin
                                                                                         {авторы}
          mousekey := 0;
          regim := 6;
          bmpp5(0,'credits.bmp');
          puttext(30,30,'STAR WARS: space mission                        demo version');
          puttext(140,150,'programmist A.S.Andrianov');
          puttext(400,500,'version 0.64');
          timer_bool := 0;
      end;
      if ((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=82)and(mousey<=93)) then if (timer_bool > 30) then begin
        mousekey := 0;
                                                                                   {выход из игры}
        SendMessage(wnd, WM_CLOSE, 0, 0);
      end;
     end;
  3 :begin
      UpdateInputState(wnd);
      if ((diks[$03] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=33)and(mousey<=45)) then if (timer_bool > 20) then begin  {в меню 4}
          mousekey := 0;
          regim := 4;
          bmpp5(0,'menu04.bmp');
          timer_bool := 0;
//        DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);
//        g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
//        g_pDD.SetDisplayMode(320, 200, 16, 0, 0);
      end;
      if ((diks[$02] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=18)and(mousey<=30)) then if (timer_bool > 20) then begin  {игровые}
          mousekey := 0;
          regim := 15;
          bmpp5(0,'menu06.bmp');
          timer_bool := 0;
      end;
      if ((diks[$05] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=64)and(mousey<=77)) then if (timer_bool > 20) then begin  {выход в меню 5}
          mousekey := 0;
          regim := 5;
          bmpp5(0,'menu05.bmp');
          timer_bool := 0;
      end;
      if ((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=28)and(mousex<=68)and(mousey>=80)and(mousey<=90)) then if (timer_bool > 20) then begin  {выход в меню 1}
          mousekey := 0;
          regim := 1;
          bmpp5(0,'menu02.bmp');
          timer_bool := 0;
      end;
     end;
  4 :begin
      UpdateInputState(wnd);
      if ((diks[$02] and $80) <> 0) or  ((mousekey=1)and(mousex>=7)and(mousex<=37)and(mousey>=8)and(mousey<=17)) then if (timer_bool > 20) then begin
                                                                                  {320x200x16}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(320,200,16);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$03] and $80) <> 0) or  ((mousekey=1)and(mousex>=7)and(mousex<=37)and(mousey>=19)and(mousey<=27)) then if (timer_bool > 20) then begin
                                                                                  {640x480x16}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(640,480,16);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$04] and $80) <> 0) or  ((mousekey=1)and(mousex>=7)and(mousex<=37)and(mousey>=30)and(mousey<=38)) then if (timer_bool > 20) then begin
                                                                                  {800x600x16}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(800,600,16);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$05] and $80) <> 0) or  ((mousekey=1)and(mousex>=7)and(mousex<=37)and(mousey>=42)and(mousey<=50)) then if (timer_bool > 20) then begin
                                                                                 {1024x768x16}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(1024,768,16);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$06] and $80) <> 0) or  ((mousekey=1)and(mousex>=7)and(mousex<=37)and(mousey>=52)and(mousey<=60)) then if (timer_bool > 20) then begin
                                                                                {2048x1024x16}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(1024,768,16);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$07] and $80) <> 0) or  ((mousekey=1)and(mousex>=54)and(mousex<=87)and(mousey>=8)and(mousey<=17)) then if (timer_bool > 20) then begin
                                                                                  {320x200x32}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(320,200,32);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$08] and $80) <> 0) or  ((mousekey=1)and(mousex>=54)and(mousex<=87)and(mousey>=19)and(mousey<=27)) then if (timer_bool > 20) then begin
                                                                                  {640x480x32}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(640,480,32);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$09] and $80) <> 0) or  ((mousekey=1)and(mousex>=54)and(mousex<=87)and(mousey>=30)and(mousey<=38)) then if (timer_bool > 20) then begin
                                                                                  {800x600x32}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(800,600,32);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$0A] and $80) <> 0) or  ((mousekey=1)and(mousex>=54)and(mousex<=87)and(mousey>=42)and(mousey<=50)) then if (timer_bool > 20) then begin
                                                                                 {1024x768x32}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(1024,768,32);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$0B] and $80) <> 0) or  ((mousekey=1)and(mousex>=54)and(mousex<=87)and(mousey>=52)and(mousey<=60)) then if (timer_bool > 20) then begin
                                                                                {2048x1024x32}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          SendMessage(wnd, WM_SYSCOMMAND,SC_MINIMIZE,0);
          SetFullscreenMode(1024,768,32);
          SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
          Save_screenMode_real;
      end;
      if ((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=39)and(mousex<=59)and(mousey>=79)and(mousey<=89)) then if (timer_bool > 20) then begin  {выход в меню 3}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
      end;
     end;
  5 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=0)and(mousex<=100)and(mousey>=0)and(mousey<=100)) then if (timer_bool > 40) then begin  {выход в меню 3}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
      end;
     end;
  6 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=0)and(mousex<=100)and(mousey>=0)and(mousey<=100)) then if (timer_bool > 40) then begin  {выход в меню 1}
          mousekey := 0;
          regim := 1;
          bmpp5(0,'menu02.bmp');
          timer_bool := 0;
      end;
     end;
  8 :begin
      UpdateInputState(wnd);
      if (diks[$01] and $80) <> 0 then if (timer_bool > 20) then begin  {победа}
          mousekey := 0;
          bmpp5(0,'menu01.bmp');
          regim := 2;
          timer_bool := 0;
          myx := 0; myy := 2.1; myz := 0;

          if your_mission = 5 then
            read_model_constant := 5;
      end;
     end;
  9 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) then if (timer_bool > 20) then begin
                                                                        {задание}
          mousekey := 0;
          play_midi := false;
          regim := 10;
          active_mission := 1;
          timer_bool := 0;

//          if draw_3d_bar then
//            readspacemodels;
      end;
     end;
  15 :begin                                                             {настройки игровые}
      UpdateInputState(wnd);
      if (((diks[$01] and $80) <> 0) or  ((mousekey=1)and(mousex>=41)and(mousex<=64)and(mousey>=86)and(mousey<=95))) then if (timer_bool > 20) then begin {выход в меню 3}

          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
      end;
      if (((diks[$02] and $80) <> 0) or  ((mousekey=1)and(mousex>=5)and(mousex<=50)and(mousey>=13)and(mousey<=19))) then if (timer_bool > 20) then begin {2d-bar}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          draw_3d_bar := false;
      end;
      if (((diks[$03] and $80) <> 0) or  ((mousekey=1)and(mousex>=55)and(mousex<=95)and(mousey>=13)and(mousey<=19))) then if (timer_bool > 20) then begin {3d-bar}
          mousekey := 0;
          regim := 3;
          bmpp5(0,'menu03.bmp');
          timer_bool := 0;
          draw_3d_bar := true;
      end;
     end;
  2 :begin
      UpdateInputState(wnd);
      if draw_3d_bar then begin
        if (diks[$C9] and $80) <> 0 then begin {вниз}
          angle_y2 := angle_y + 3.5;
          if Angle_y2 > 360.0 then Angle_y2 := angle_y2 - 360;
          angle_y := angle_y2;
          angle2 := 0;
        end;
        if (diks[$D1] and $80) <> 0 then begin  {вверх}
          angle_y2 := angle_y - 3.5;
          if Angle_y2 < 0 then Angle_y2 := angle_y2 + 360;
          angle_y := angle_y2;
          angle2 := 0;
        end;
        if (diks[$CF] and $80) <> 0 then begin  {голову прямо}
          angle_y2 := 0;
          angle_y := angle_y2;
        end;
        if (diks[$C8] and $80) <> 0 then begin  {вперед}

          genx1 := myx + 0.1*sin(angle/180*Pi);
          geny1 := myz - 0.1*cos(angle/180*Pi);
          genz1 := myy - 0.1*sin(angle_y/180*Pi);

          if barmap[round(200+geny1*2),round(200+genx1*2)] <> 0{1=1} then begin
            myx := genx1;
            myy := genz1;
            myz := geny1;
          end;
        end;
        if (diks[$D0] and $80) <> 0 then begin  {вперед}

          genx1 := myx - 0.1*sin(angle/180*Pi);
          geny1 := myz + 0.1*cos(angle/180*Pi);
          genz1 := myy + 0.1*sin(angle_y/180*Pi);

          if barmap[round(200+geny1*2),round(200+genx1*2)] <> 0{1=1} then begin
            myx := genx1;
            myy := genz1;
            myz := geny1;
          end;
        end;

        if (diks[$CD] and $80) <> 0 then begin  {вправо}
          if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;

          if Angle > 360.0 then Angle := angle - 360;
          angle := angle + k*3.5;
          angle2 := angle2 + k*3.5;

         if (angle_y2 > 90) and (angle_y2 < 270) then begin
          if angle_y2 <=180 then
            angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180
          else
            angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180;
         end else begin
          if angle_y2 <=180 then
            angle_y := (cos(angle2/180*Pi))*angle_y2
          else
            angle_y := -(cos(angle2/180*Pi))*(360 -angle_y2);
         end;
          if Angle_y > 360.0 then Angle_y := angle_y - 360;
        end;
        if (diks[$CB] and $80) <> 0 then begin  {влево}
          if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;

          if Angle < 0 then Angle := angle + 360;
          angle := angle - k*3.5;
          angle2 := angle2 - k*3.5;

         if (angle_y2 > 90) and (angle_y2 < 270) then begin
          if angle_y2 <=180 then
            angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180
          else
            angle_y := (cos((angle2)/180*Pi))*(angle_y2-180)+180;
         end else begin
          if angle_y2 <=180 then
            angle_y := (cos(angle2/180*Pi))*angle_y2
          else
            angle_y := -(cos(angle2/180*Pi))*(360 -angle_y2);
         end;
          if Angle_y > 360.0 then Angle_y := angle_y - 360;
        end;

      end;
      if ((((diks[$02] and $80) <> 0)and(not draw_3d_bar)) or ((mousekey=1)and(mousex>=0)and(mousex<=35)and(mousey>=45)and(mousey<=88)and(not draw_3d_bar))) or
      ((round(sqrt(sqr(-56-myx)+sqr(28-myz))) <= 10)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin
                                                                        {тренировочный полет}
          mousekey := 0;
          kol_rakets := 4;
          play_midi := false;
          regim := 10;
          timer_bool := 0;
          active_mission := -1;
          myx := 1;
          myy := 1.1;
          myz := -19;
          pole_life := 100;
          num_fire := 0;
          kol_monstrs := 1;
          monstr[1].x := 0; monstr[1].y := 0.8; monstr[1].z := 0; monstr[1].v := 0.12;monstr[1].vid := random(3)+1; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=30; monstr[1].t:=1;
          monstr[1].time_lighting := 0;
          active_mission_false_step := 1;
              read_model_constant := 1;
//            readspacemodels;

//          if draw_3d_bar then
//            readspacemodels;
      end;
      if ((((diks[$03] and $80) <> 0)and(not draw_3d_bar))or ((mousekey=1)and(mousex>=87)and(mousex<=100)and(mousey>=21)and(mousey<=67)and(not draw_3d_bar) ))or
      ((round(sqrt(sqr(-27-myx)+sqr(-28-myz))) <= 10)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin  {миссия}
          mousekey := 0;
          kol_rakets := 2;
          regim := 9;
//          bmpp5(0,'mission1.bmp');
//          puttext(10,20,'mission ' + IntToStr(your_mission+1));
//          for k := texts_missions_indecs[your_mission] to texts_missions_indecs[your_mission+1] do
//            puttext(5,330+(k-texts_missions_indecs[your_mission])*10,texts_missions[k]);

//          bmpp4(0,'map0'   +IntToStr(your_mission+1)+    '.bmp');

          pole_life := 100;
          num_fire := 0;
          myx := 1;
          myy := 1.1;
          myz := -19;
              read_model_constant := 3;
//            readspacemodels;
          case your_mission of
            0:begin
          base_x := 1212;
          base_y := 1.1;
          base_z := -1428;
          myx := 1212;
          myy := 1.1;
          myz := -1488;
       kol_monstrs := 9{30};
//  monstr[1].x := 1222; monstr[1].y := 0.8; monstr[1].z := -1488; monstr[1].v := 0.12; monstr[1].vid := 3; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=0; monstr[1].t:=1;
  monstr[1].x := 1600; monstr[1].y := 1; monstr[1].z := 450; monstr[1].v := 0.12; monstr[1].vid := 3; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=0; monstr[1].t:=1;
  monstr[2].x := -1100; monstr[2].y := 1; monstr[2].z := -460; monstr[2].v := 0.12; monstr[2].vid := 2; monstr[2].heard:=10; monstr[2].leven:=1; monstr[2].angle:=30; monstr[2].angle_y:=0; monstr[2].t:=1;
  monstr[3].x := -500; monstr[3].y := 1; monstr[3].z := 1500; monstr[3].v := 0.12; monstr[3].vid := 1; monstr[3].heard:=10; monstr[3].leven:=1; monstr[3].angle:=30; monstr[3].angle_y:=0; monstr[3].t:=1;
  monstr[4].x := 1620; monstr[4].y := 1; monstr[4].z := 455; monstr[4].v := 0.12; monstr[4].vid := 3; monstr[4].heard:=10; monstr[4].leven:=1; monstr[4].angle:=30; monstr[4].angle_y:=0; monstr[4].t:=1;
  monstr[5].x := -1110; monstr[5].y := 1; monstr[5].z := -480; monstr[5].v := 0.12; monstr[5].vid := 2; monstr[5].heard:=10; monstr[5].leven:=1; monstr[5].angle:=30; monstr[5].angle_y:=0; monstr[5].t:=1;
  monstr[6].x := -530; monstr[6].y := 1; monstr[6].z := 1520; monstr[6].v := 0.12; monstr[6].vid := 1; monstr[6].heard:=10; monstr[6].leven:=1; monstr[6].angle:=30; monstr[6].angle_y:=0; monstr[6].t:=1;
  monstr[7].x := 1605; monstr[7].y := 1; monstr[7].z := 470; monstr[7].v := 0.12; monstr[7].vid := 3; monstr[7].heard:=10; monstr[7].leven:=1; monstr[7].angle:=30; monstr[7].angle_y:=0; monstr[7].t:=1;
  monstr[8].x := -1104; monstr[8].y := 1; monstr[8].z := -490; monstr[8].v := 0.12; monstr[8].vid := 2; monstr[8].heard:=10; monstr[8].leven:=1; monstr[8].angle:=30; monstr[8].angle_y:=0; monstr[8].t:=1;
  monstr[9].x := -510; monstr[9].y := 1; monstr[9].z := 1505; monstr[9].v := 0.12; monstr[9].vid := 1; monstr[9].heard:=10; monstr[9].leven:=1; monstr[9].angle:=30; monstr[9].angle_y:=0; monstr[9].t:=1;
              end;
            1:begin
          base_x := 144;
          base_y := 1.1;
          base_z := -944;
          myx := 144;
          myy := 1.1;
          myz := -980;
       kol_monstrs := 5{30};
  monstr[1].x := 769; monstr[1].y := 0.8; monstr[1].z := -429; monstr[1].v := 0.12;monstr[1].vid := 1; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=30; monstr[1].t:=1;
  monstr[2].x := 1723; monstr[2].y := 0.8; monstr[2].z := 461; monstr[2].v := 0.12;monstr[2].vid := 2; monstr[2].heard:=10; monstr[2].leven:=1; monstr[2].angle:=30; monstr[2].angle_y:=0; monstr[2].t:=1;
  monstr[3].x := 144; monstr[3].y := 0.8; monstr[3].z := -985; monstr[3].v := 0.12; monstr[3].vid := 9; monstr[3].heard:=40; monstr[3].leven:=1; monstr[3].angle:=30; monstr[3].angle_y:=0; monstr[3].t:=50;
  monstr[4].x := 1720; monstr[4].y := 0.8; monstr[4].z := 469; monstr[4].v := 0.12;monstr[4].vid := 2; monstr[4].heard:=10; monstr[4].leven:=1; monstr[4].angle:=30; monstr[4].angle_y:=0; monstr[4].t:=1;
  monstr[5].x := 759; monstr[5].y := 0.8; monstr[5].z := -449; monstr[5].v := 0.12;monstr[5].vid := 1; monstr[5].heard:=10; monstr[5].leven:=1; monstr[5].angle:=30; monstr[5].angle_y:=30; monstr[5].t:=1;
              end;
            2:begin
          base_x := 1543;
          base_y := 1.1;
          base_z := -1246;
          myx := 1547;
          myy := 1.1;
          myz := -1289;
       kol_monstrs := 6{30};
  monstr[1].x := 795; monstr[1].y := 0.8; monstr[1].z := -636; monstr[1].v := 0.12;monstr[1].vid := 1; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=30; monstr[1].t:=10;
  monstr[2].x := 816; monstr[2].y := 0.8; monstr[2].z := -636; monstr[2].v := 0.12;monstr[2].vid := 2; monstr[2].heard:=10; monstr[2].leven:=1; monstr[2].angle:=30; monstr[2].angle_y:=0; monstr[2].t:=10;
  monstr[3].x := 802; monstr[3].y := 0.8; monstr[3].z := -636; monstr[3].v := 0.12; monstr[3].vid := 9; monstr[3].heard:=40; monstr[3].leven:=1; monstr[3].angle:=30; monstr[3].angle_y:=0; monstr[3].t:=10;

  monstr[4].x := -168; monstr[4].y := 0.8; monstr[4].z := 753; monstr[4].v := 0.12; monstr[4].vid := 3; monstr[4].heard:=10; monstr[4].leven:=1; monstr[4].angle:=30; monstr[4].angle_y:=0; monstr[4].t:=1;
  monstr[5].x := -158; monstr[5].y := 0.8; monstr[5].z := 755; monstr[5].v := 0.12; monstr[5].vid := 3; monstr[5].heard:=10; monstr[5].leven:=1; monstr[5].angle:=30; monstr[5].angle_y:=0; monstr[5].t:=1;
  monstr[6].x := -148; monstr[6].y := 0.8; monstr[6].z := 757; monstr[6].v := 0.12; monstr[6].vid := 3; monstr[6].heard:=10; monstr[6].leven:=1; monstr[6].angle:=30; monstr[6].angle_y:=0; monstr[6].t:=1;
              end;
            3:begin
          base_x := -1681;
          base_y := 1.1;
          base_z := 1952;
          myx := -1700;
          myy := 1.1;
          myz := 2000;
       kol_monstrs := 14{30};
  monstr[1].x := 1011; monstr[1].y := 0.8; monstr[1].z := -350; monstr[1].v := 0.12;monstr[1].vid := 10; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=130; monstr[1].t:=100;
  monstr[2].x := 1001; monstr[2].y := 5.8; monstr[2].z := -354; monstr[2].v := 0.12;monstr[2].vid := 10; monstr[2].heard:=10; monstr[2].leven:=1; monstr[2].angle:=40; monstr[2].angle_y:=30; monstr[2].t:=100;
  monstr[3].x := 1021; monstr[3].y := 0.8; monstr[3].z := -374; monstr[3].v := 0.12;monstr[3].vid := 10; monstr[3].heard:=10; monstr[3].leven:=1; monstr[3].angle:=30; monstr[3].angle_y:=50; monstr[3].t:=100;
  monstr[4].x := 1031; monstr[4].y := 3.8; monstr[4].z := -324; monstr[4].v := 0.12;monstr[4].vid := 11; monstr[4].heard:=10; monstr[4].leven:=1; monstr[4].angle:=50; monstr[4].angle_y:=90; monstr[4].t:=100;
  monstr[5].x := 1081; monstr[5].y := 0.8; monstr[5].z := -344; monstr[5].v := 0.12;monstr[5].vid := 10; monstr[5].heard:=10; monstr[5].leven:=1; monstr[5].angle:=90; monstr[5].angle_y:=30; monstr[5].t:=100;
  monstr[6].x := 1091; monstr[6].y := 1.8; monstr[6].z := -334; monstr[6].v := 0.12;monstr[6].vid := 11; monstr[6].heard:=10; monstr[6].leven:=1; monstr[6].angle:=30; monstr[6].angle_y:=110; monstr[6].t:=100;
  monstr[7].x := 1071; monstr[7].y := 0.8; monstr[7].z := -394; monstr[7].v := 0.12;monstr[7].vid := 11; monstr[7].heard:=10; monstr[7].leven:=1; monstr[7].angle:=120; monstr[7].angle_y:=15; monstr[7].t:=100;
  monstr[8].x := 1061; monstr[8].y := 0.8; monstr[8].z := -364; monstr[8].v := 0.12;monstr[8].vid := 11; monstr[8].heard:=10; monstr[8].leven:=1; monstr[8].angle:=130; monstr[8].angle_y:=30; monstr[8].t:=100;
  monstr[9].x := 1051; monstr[9].y :=-1.8; monstr[9].z := -384; monstr[9].v := 0.12;monstr[9].vid := 10; monstr[9].heard:=10; monstr[9].leven:=1; monstr[9].angle:=15; monstr[9].angle_y:=40; monstr[9].t:=100;
  monstr[10].x := 1036; monstr[10].y := 0.8; monstr[10].z := -314; monstr[10].v := 0.12;monstr[10].vid := 11; monstr[10].heard:=10; monstr[10].leven:=1; monstr[10].angle:=45; monstr[10].angle_y:=36; monstr[10].t:=100;

  monstr[11].x := 1031; monstr[11].y := 0.8; monstr[11].z := -324; monstr[11].v := 0.12;monstr[11].vid := 3; monstr[11].heard:=10; monstr[11].leven:=1; monstr[11].angle:=30; monstr[11].angle_y:=30; monstr[11].t:=1;
  monstr[12].x := 1061; monstr[12].y := 0.8; monstr[12].z := -354; monstr[12].v := 0.12;monstr[12].vid := 3; monstr[12].heard:=10; monstr[12].leven:=1; monstr[12].angle:=30; monstr[12].angle_y:=30; monstr[12].t:=1;
  monstr[13].x := 1081; monstr[13].y := 0.8; monstr[13].z := -374; monstr[13].v := 0.12;monstr[13].vid := 3; monstr[13].heard:=10; monstr[13].leven:=1; monstr[13].angle:=30; monstr[13].angle_y:=30; monstr[13].t:=1;
  monstr[14].x := 1091; monstr[14].y := 0.8; monstr[14].z := -314; monstr[14].v := 0.12;monstr[14].vid := 3; monstr[14].heard:=10; monstr[14].leven:=1; monstr[14].angle:=30; monstr[14].angle_y:=30; monstr[14].t:=1;
              end;
            4:begin
          base_x := {311}350;
          base_y := 1.1;
          base_z := {272}200;
          myx := 340;
          myy := 17.1;
          myz := 230;
       kol_monstrs := 30{30};
       for k := 1 to 20 do begin
         monstr[k].x := 400+random(100)-50; monstr[k].y := 0.8+random(10)-5; monstr[k].z := 115+random(100)-50; monstr[k].v := 0.12;monstr[k].vid := 3; monstr[k].heard:=10; monstr[k].leven:=1; monstr[k].angle:=30; monstr[k].angle_y:=130; monstr[k].t:=1;
       end;
       for k := 20 to 30 do begin
         monstr[k].x := 400+random(100)-50; monstr[k].y := 1+random(10)-5; monstr[k].z := 150+random(100)-50; monstr[k].v := 0.12;monstr[k].vid := 1; monstr[k].heard:=10; monstr[k].leven:=1; monstr[k].angle:=30; monstr[k].angle_y:=130; monstr[k].t:=51{51};

       end;
              end;
          end;
//          inc(your_mission);
          for k := 1 to kol_monstrs do
            monstr[k].time_lighting := 0;
          timer_bool := 0;
      end;
      if ((diks[$01] and $80) <> 0) or  (((mousekey=1)and(mousex>=80)and(mousex<=100)and(mousey>=66)and(mousey<=100)and(not draw_3d_bar))) then if (timer_bool > 20) then begin  {выход в меню 1}
          regim := 1;
          bmpp5(0,'menu02.bmp');
          timer_bool := 0;
      end;
      if {((((diks[$03] and $80) <> 0)and(not draw_3d_bar))or ((mousekey=1)and(mousex>=87)and(mousex<=100)and(mousey>=21)and(mousey<=67)and(not draw_3d_bar) ))or}
         ((round(sqrt(sqr(28-myx)+sqr(14-myz))) <= 1.5)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin
                                                                                          {commandir}
          mousekey := 0;
          regim := -3;
          bmpp5(0,'boss.bmp');
          for k := repliks[your_mission].n_c to repliks[your_mission].k_c-1 do
            puttext(5,330+(k-repliks[your_mission].n_c)*10,texts_missions_str[k]);
          timer_bool := 0;
      end;
      if {((((diks[$03] and $80) <> 0)and(not draw_3d_bar))or ((mousekey=1)and(mousex>=87)and(mousex<=100)and(mousey>=21)and(mousey<=67)and(not draw_3d_bar) ))or}
         ((round(sqrt(sqr(-28-myx)+sqr(11-myz))) <= 1.5)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin
                                                                                           {barmen}
          mousekey := 0;
          regim := -3;
          bmpp5(0,'barmen.bmp');
          for k := repliks[your_mission].n_b to repliks[your_mission].k_b-1 do
            puttext(5,330+(k-repliks[your_mission].n_b)*10,texts_missions_str[k]);
          timer_bool := 0;
      end;
      if {((((diks[$03] and $80) <> 0)and(not draw_3d_bar))or ((mousekey=1)and(mousex>=87)and(mousex<=100)and(mousey>=21)and(mousey<=67)and(not draw_3d_bar) ))or}
         ((round(sqrt(sqr(-27-myx)+sqr(17-myz))) <= 1.5)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin
                                                                                            {man01}
          mousekey := 0;
          regim := -3;
          bmpp5(0,'man01.bmp');
          for k := repliks[your_mission].n_s1 to repliks[your_mission].k_s1-1 do
            puttext(5,330+(k-repliks[your_mission].n_s1)*10,texts_missions_str[k]);
          timer_bool := 0;
      end;
      if {((((diks[$03] and $80) <> 0)and(not draw_3d_bar))or ((mousekey=1)and(mousex>=87)and(mousex<=100)and(mousey>=21)and(mousey<=67)and(not draw_3d_bar) ))or}
         ((round(sqrt(sqr(-31-myx)+sqr(17-myz))) <= 1.5)and(draw_3d_bar)and((diks[$39] and $80) <> 0)) then if (timer_bool > 20) then begin
                                                                                             {man02}
          mousekey := 0;
          regim := -3;
          bmpp5(0,'man02.bmp');
          for k := repliks[your_mission].n_s2 to repliks[your_mission].k_s2-1 do
            puttext(5,330+(k-repliks[your_mission].n_s2)*10,texts_missions_str[k]);
          timer_bool := 0;
      end;
     end;
    -1 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) or  (mousekey=1) then if (timer_bool > 40) then begin  {выход в игру}
          mousekey := 0;
          regim := 1;
          bmpp5(0,'menu02.bmp');
          timer_bool := 0;
      end;
      if timer_bool >= 100 then begin
          read_model_constant := 4;
      end;
     end;
    -10 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) or  (mousekey=1) or (timer_bool >= 1500) then if (timer_bool > 40) then begin  {выход в игру}
          mousekey := 0;
          if score > 75 then
            regim := 2
          else
            regim := 1;
//          bmpp5(0,'menu01.bmp');
          timer_bool := 0;
      end;
     end;
    0 :begin
      UpdateInputState(wnd);
      if ((diks[$01] and $80) <> 0) or  (mousekey=1) or (timer_bool >= 3000) then if (timer_bool > 40) then begin  {выход в игру}
          mousekey := 0;
          regim := 1;
          bmpp5(0,'menu02.bmp');
          glDeleteLists(zastavka_list1, 1);
          glDeleteLists(zastavka_list2, 1);
          glDeleteLists(zastavka_list3, 1);
          glDeleteLists(zastavka_list4, 1);
          timer_bool := 0;
      end;
     end;
  -3:begin
      UpdateInputState(wnd);
      if (diks[$01] and $80) <> 0 then if (timer_bool > 20) then begin  {разговор}
          mousekey := 0;
          if not draw_3d_bar then
            bmpp5(0,'menu01.bmp');
          regim := 2;
          timer_bool := 0;
//          myx := 0; myy := 2.1; myz := 0;
      end;
     end;
//  bmpp5(0,'menu02.bmp');
 end;
end;
end;



function MyWndProc conv arg_stdcall (Window: HWND; Mess: UINT; Wp: WParam; Lp: LParam): LRESULT;
const
  r_a_y : single = 0;

var
  ps: TPaintStruct;
  Caption: array[0..MAX_PATH] of Char;
  number_tex : longint;
  i,j,k,l : integer;
  angle_y2 : single;
//  genx1,geny1 : single;

begin
  Result := 0;
  case Mess of
    WM_PAINT:
      begin
        BeginPaint (wnd, Ps);

        glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT);                   // Clear color & depth buffers





        glLoadIdentity;


  case regim of
    10:begin

          r_a_y := 0;

          if (angle_y > 90) and (angle_y < 270) then k := -1 else k := 1;

          if (angle_y > 0) and (angle_y < 90) then
            r_a_y := -(-cos(angle_y*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 90) and (angle_y < 180) then
            r_a_y := (-cos((angle_y-180)*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 180) and (angle_y < 270) then
            r_a_y := -(-cos((angle_y-180)*Pi/180){-(angle_y/180)}*45+45);
          if (angle_y > 270) and (angle_y < 360) then
            r_a_y := (-cos(angle_y*Pi/180){-(angle_y/180)}*45+45);
//          r_a_y := 0;
         angle_y2 := angle_y +   r_a_y;

          if (angle_y2 > 90) and (angle_y2 < 270) then k := -1 else k := 1;

//          glulookat(0,0,0,0 + 1*k*sin(angle/180*Pi),0 - 1*k*cos(angle/180*Pi),0 - 1*sin(angle_y/180*Pi),0 + 1*k*sin(angle/180*Pi),0 - 1*k*cos((angle)/180*Pi),0 - 1*sin((angle_y+90)/180*Pi));


          glRotatef(Angle_y{2}, 1.0, 0.0, 0.0);
          glRotatef(Angle, 0.0, 1.0, 0);



  gldisable(GL_DEPTH_TEST);
      gllightmodelf(gl_light_model_two_side,1);
  gldisable(gl_cull_face);

{      if not globe_paint then begin

               glcalllist(lists[0]);
        glEnable(gl_texture_2d);

        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,0); glVertex3f(75.0, 75.0, 75.0);
        gltexcoord2f(0,-1); glVertex3f(-75.0, 75.0, 75.0);
        gltexcoord2f(1,-1); glVertex3f(-75.0, -75.0, 75.0);
        gltexcoord2f(1,0); glVertex3f(75.0, -75.0, 75.0);
        glEnd;

        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, -1.0);
        gltexcoord2f(0,0); glVertex3f(75.0, 75.0, -75.0);
        gltexcoord2f(0,-1); glVertex3f(75.0, -75.0, -75.0);
        gltexcoord2f(1,-1); glVertex3f(-75.0, -75.0, -75.0);
        gltexcoord2f(1,0); glVertex3f(-75.0, 75.0, -75.0);
        glEnd;

        glBegin (GL_POLYGON);
        glNormal3f(-1.0, 0.0, 0.0);
        gltexcoord2f(0,0); glVertex3f(-75.0, 75.0, 75.0);
        gltexcoord2f(0,-1); glVertex3f(-75.0, 75.0, -75.0);
        gltexcoord2f(1,-1); glVertex3f(-75.0, -75.0, -75.0);
        gltexcoord2f(1,0); glVertex3f(-75.0, -75.0, 75.0);
        glEnd;

        glBegin (GL_POLYGON);
        glNormal3f(1.0, 0.0, 0.0);
        gltexcoord2f(0,0); glVertex3f(75.0, 75.0, 75.0);
        gltexcoord2f(0,-1); glVertex3f(75.0, -75.0, 75.0);
        gltexcoord2f(1,-1); glVertex3f(75.0, -75.0, -75.0);
        gltexcoord2f(1,0); glVertex3f(75.0, 75.0, -75.0);
        glEnd;

        glBegin(GL_POLYGON);
        glNormal3f(0.0, 1.0, 0.0);
        gltexcoord2f(0,0); glVertex3f(-75.0, 75.0, -75.0);
        gltexcoord2f(0,-1); glVertex3f(-75.0, 75.0, 75.0);
        gltexcoord2f(1,-1); glVertex3f(75.0, 75.0, 75.0);
        gltexcoord2f(1,0); glVertex3f(75.0, 75.0, -75.0);
        glEnd;

        glBegin(GL_POLYGON);
        glNormal3f(0.0, -1.0, 0.0);
        gltexcoord2f(0,0); glVertex3f(-75.0, -75.0, -75.0);
        gltexcoord2f(0,-1); glVertex3f(75.0, -75.0, -75.0);
        gltexcoord2f(1,-1); glVertex3f(75.0, -75.0, 75.0);
        gltexcoord2f(1,0); glVertex3f(-75.0, -75.0, 75.0);
        glEnd;
        glDisable(gl_texture_2d);
      end else begin   }
//        gldisable(GL_LIGHTING);
//        gldisable(GL_LIGHT0);
        GLD_Draw(dc,13,0,0,0,0,0);
//        glEnable(GL_LIGHTING);
//        glEnable(GL_LIGHT0);
//      end;
  glEnable(GL_DEPTH_TEST);

          glRotatef(-Angle, 0.0, 1.0, 0);
          glRotatef(-Angle_y{2}, 1.0, 0.0, 0.0);

          glRotatef(Angle_y2, 1.0, 0.0, 0.0);
          glRotatef(Angle, 0.0, 1.0, 0);

          (**********************РИСОВАНИЕ ВЗРЫВА*********        ****************)
          glTranslatef(-myx, -myy, -myz);                                          // Polygon depth
          position[0] := myx;
          position[1] := myy;
          position[2] := myz;
          gllightfv(gl_light0,gl_position,@position);
  materialcolor[0] := 1;
  materialcolor[1] := 1;
  materialcolor[2] := 1;
  glmaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,@MaterialColor);

      for i := 1 to kol_monstrs do if (monstr[i].leven = 1) and (monstr[i].vid = 4) then begin
        gltranslatef(monstr[i].x,monstr[i].y,monstr[i].z);
          glRotatef(-Angle, 0.0, 1.0, 0.0);
          glRotatef(-Angle_y2, 1.0, 0.0, 0);


        for k := 0 to 127 do
          for l := 0 to 127 do begin
            textura_babax_real^[k,l,0] := textura_babax^[k+128*(monstr[i].faza_texture_babax div 4),l+128*(monstr[i].faza_texture_babax mod 4),0];
            textura_babax_real^[k,l,1] := textura_babax^[k+128*(monstr[i].faza_texture_babax div 4),l+128*(monstr[i].faza_texture_babax mod 4),1];
            textura_babax_real^[k,l,2] := textura_babax^[k+128*(monstr[i].faza_texture_babax div 4),l+128*(monstr[i].faza_texture_babax mod 4),2];
            case textura_babax_real^[k,l,0] +textura_babax_real^[k,l,1] + textura_babax_real^[k,l,2] of
              0..10:textura_babax_real^[k,l,3] := 0;
              10..100:textura_babax_real^[k,l,3] := 50;
              100..250:textura_babax_real^[k,l,3] := 150;
              250..1024:textura_babax_real^[k,l,3] := 250;
            end;
{            if textura_babax_real^[k,l,0] +textura_babax_real^[k,l,1] + textura_babax_real^[k,l,2]  > 20 then
              textura_babax_real^[k,l,3] := 150
            else
              textura_babax_real^[k,l,3] := 0;}
          end;

        for k := 0 to 127 do begin
          textura_babax_real^[0,k,0] := 0;
          textura_babax_real^[0,k,1] := 0;
          textura_babax_real^[0,k,2] := 0;
          textura_babax_real^[k,l,3] := 0;
        end;


         glblendfunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

         gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
         gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
         glteximage2d(gl_texture_2d,0,GL_RGBA,128,128,0,GL_RGBA,GL_unsigned_byte,textura_babax_real);

        glenable(GL_BLEND);
        glEnable(gl_texture_2d);
        glBegin(GL_POLYGON);
        glNormal3f(0.0, 0.0, 1.0);
        gltexcoord2f(0,-1); glVertex3f(-1, 1, -1);
        gltexcoord2f(1,-1); glVertex3f(1, 1, -1);
        gltexcoord2f(1,0); glVertex3f(1, -1.0, -1);
        gltexcoord2f(0,0); glVertex3f(-1, -1.0, -1);
        glEnd;
        gldisable(GL_BLEND);
        glDisable(gl_texture_2d);

          glRotatef(Angle_y2, 1.0, 0.0, 0);
          glRotatef(Angle, 0.0, 1.0, 0.0);
        gltranslatef(-monstr[i].x,-monstr[i].y,-monstr[i].z);
      end;
  glmaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,@MaterialColorblack);
          (**************************************              *********)


        glLoadIdentity;
          glRotatef(Angle_y2, 1.0, 0.0, 0.0);
          glRotatef(Angle, 0.0, 1.0, 0);
          glTranslatef(-myx, -myy, -myz);                                          // Polygon depth
          position[0] := myx;
          position[1] := myy;
          position[2] := myz;
          gllightfv(gl_light0,gl_position,@position);


{      gllightmodelf(gl_light_model_two_side,1);
      gldisable(gl_cull_face);

  materialcolor[0] := 1;
  materialcolor[1] := 0.75;
  materialcolor[2] := 0;
  glmaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,@MaterialColor);
  for i := 1 to num_fire do begin
    glbegin(gl_triangle_strip);
          glnormal3f(1,1,1);
          glvertex3f(fires[i].x-0.5,fires[i].y-0.1,fires[i].z-0.5+0.5);
          glvertex3f(fires[i].x,fires[i].y-0.1,fires[i].z+0.5);
          glvertex3f(fires[i].x+0.5,fires[i].y-0.2,fires[i].z-0.5+0.5);
    glend;
  end;                       }
//  glmaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,@MaterialColorblack);


      gllightmodelf(gl_light_model_two_side,0);
//      glenable(gl_cull_face);



  (*************************************************)
        for i := 1 to kol_monstrs do
          if not((monstr[i].vid = 4) {and (monstr[i].leven=1)}) then
            if round(sqrt(sqr(monstr[i].x-myx)+sqr(monstr[i].y-myy)+sqr(monstr[i].z-myz))) < 100 then
              if monstr[i].time_lighting = 0 then
                GLD_Draw(dc,monstr[i].vid,monstr[i].x,monstr[i].y,monstr[i].z,monstr[i].angle,monstr[i].angle_y)
              else begin
                global_ambient[0] := 255; global_ambient[1] := 2; global_ambient[2] := 2;
                gllightmodelfv(gl_light_model_ambient,@global_ambient);
                GLD_Draw(dc,monstr[i].vid,monstr[i].x,monstr[i].y,monstr[i].z,monstr[i].angle,monstr[i].angle_y);
                global_ambient[0] := 2; global_ambient[1] := 2; global_ambient[2] := 2;
                gllightmodelfv(gl_light_model_ambient,@global_ambient);
              end;



//            GLD_Draw(dc,13,myx,myy,myz,0,0);


        if active_mission > 0 then
          if round(sqrt(sqr(base_x-myx)+sqr(base_y-myy)+sqr(base_z-myz))) < 100 then
            GLD_Draw(dc,7,base_x,base_y,base_z,0,0);

        for i := 1 to 30 do
          GLD_Draw(dc,5,mysors[i].x,mysors[i].y,mysors[i].z,mysors[i].angle,mysors[i].angle_y);

        if asteroids_pole then
          for i := 1 to 30 do
            GLD_Draw(dc,12,asteroids[i].x,asteroids[i].y,asteroids[i].z,asteroids[i].angle,asteroids[i].angle_y);

//          glRotatef(-10, 1.0, 0.0, 0);
        for i := 1 to num_fire do
          if fires[i].tip = 1 then
            GLD_Draw(dc,6,fires[i].x,fires[i].y,fires[i].z,fires[i].angle,fires[i].angle_y)
          else
            GLD_Draw(dc,8,fires[i].x,fires[i].y,fires[i].z,fires[i].angle,fires[i].angle_y);
  (*************************************************)
//  GLD_Draw(dc,8,0,0,0,30,45);








        draw_pribors;




        glTranslatef(-0.115, 0.085,-0.09);
        glrasterpos2f(0,0);
        NewCount := GetTickCount;
        FrameCount +:= 1;
        if (NewCount - LastCount) > 1000 then
         begin
           fps := FrameCount * 1000 / (NewCount - LastCount);
           LastCount := NewCount;
           FrameCount := 0;
         end;
        outtext('space01 - ' + IntToStr(Round(fps)) + ' fps' +
             + ' x = ' + IntToStr(round(myx))+ ' z = ' + IntToStr(round(myz))+ ' y = ' + IntToStr(round(myy))+ ' spend = ' + IntToStr((round(spend*100)))+ ' life = ' + IntToStr((mylive))+ ' timer_bool = ' + IntToStr((timer_bool))  {+ 'a ' + IntToStr((round(angle))) + 'a_y ' + IntToStr((round(angle_y))) + 'a_y2 ' + IntToStr((round(angle_y2)))});
//      if play_wave then begin
//        MyMedia.setpos(0);
//        MyMedia.play;
//        play_wave := false;
//      end;

//      if play_wave then begin
//        sndPlaySound('fire.wav', 1);
//        play_wave := false;
//      end;
        if not play_midi then begin
               Mess_beep := 'close my_midi' + #0;
               mciSendString(@Mess_beep[1], nil, 0, 0);
        end;
      if play_wave then begin
        sndPlaySound('fire.wav'{'killed.wav'}, SND_ASYNC);
        play_wave := false;
      end;
      if play_wave2 then begin
        sndPlaySound({'fire.wav'}'killed.wav', SND_ASYNC);
        play_wave2 := false;
      end;
      if play_wave3 then begin
        sndPlaySound({'fire.wav'}'full.wav', SND_ASYNC);
        play_wave3 := false;
      end;
//         angle_y := angle_y -    r_a_y;
    end;
    11:begin
         draw_textura_map;
       end;
    -1:begin
         draw_textura_pich;
       end;
    0:begin
         draw_textura_zastavka;
      end;
    -10:begin
         draw_textura_film1;
      end;
    -3:begin
         draw_textura_pich;
       end;
    1..9 or 15:if not ((regim = 2) and (draw_3d_bar)) then begin
//                             puttext(10,10,IntToStr(kol_objekts_models[8])+' '+IntToStr(kol_objekts_models[9]));
//        puttext(10,10,'mousex = ' + IntToStr(round(mousex)) + ' mousey = ' + IntToStr(round(mousey))+ ' mousekey = ' + IntToStr(mousekey));
//        puttext(10,20,chdirstr);
         draw_textura_pich;
              if play_midi then begin
               Mess_beep := 'open sequencer!sample.mid alias my_midi' + #0;
               mciSendString(@Mess_beep[1], nil, 0, 0);
               Mess_beep := 'play my_midi' + #0;
               mciSendString(@Mess_beep[1], nil, 0, 0);
               play_midi := false;
              end;
//              if flag_320x200x16 then begin
//                flag_320x200x16 := false;
//                g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
//                g_pDD.SetDisplayMode(320, 200, 16, 0, 0);
//              end;
       end else begin
         if play_midi then begin
           Mess_beep := 'open sequencer!sample.mid alias my_midi' + #0;
           mciSendString(@Mess_beep[1], nil, 0, 0);
           Mess_beep := 'play my_midi' + #0;
           mciSendString(@Mess_beep[1], nil, 0, 0);
           play_midi := false;
         end;
         draw_3d_bar_procedure;
       end;
  end;
        case read_model_constant of
          0:;
          1:begin
             readspacemodels1;
//             bmpp5(0,);
             read_model_constant := 0;
            end;
          2:begin
             read3dbarmodels;
             if not draw_3d_bar then
             bmpp5(0,'menu01.bmp');
             if regim = 8 then
               draw_victory;
             read_model_constant := 0;
            end;
          3:begin
             readspacemodels2;
             bmpp5(0,'mission1.bmp');
             puttext(10,20,'mission ' + IntToStr(your_mission+1));
//             for k := texts_missions_indecs[your_mission] to texts_missions_indecs[your_mission+1] do
//               puttext(5,330+(k-texts_missions_indecs[your_mission])*10,texts_missions[k]);
             for k := repliks[your_mission].n_m to repliks[your_mission].k_m-1 do
               puttext(5,330+(k-repliks[your_mission].n_m)*10,texts_missions_str[k]);
             bmpp4(0,'map0'   +IntToStr(your_mission+1)+    '.bmp');
             read_model_constant := 0;
            end;
          4:begin
             bmpp5(0,'zastav2.bmp');
             zastavka_list1 :=glgenlists(1);
             glnewlist(zastavka_list1, GL_compile);
             gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
             gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
             glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);
             glendlist;

             bmpp5(0,'zastav3.bmp');
             zastavka_list2 :=glgenlists(1);
             glnewlist(zastavka_list2, GL_compile);
             gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
             gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
             glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);
             glendlist;

             bmpp5(0,'zastav4.bmp');
             zastavka_list3 :=glgenlists(1);
             glnewlist(zastavka_list3, GL_compile);
             gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
             gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
             glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);
             glendlist;

             fillchar(textura_pich^,sizeof(textura_pich^),0);
             for j := 0 to 511 do
               for i := 0 to 511 do
                 textura_pich^[j,i,3] := 130;
             zastavka_list4 :=glgenlists(1);
             glnewlist(zastavka_list3, GL_compile);
             glblendfunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
             glenable(GL_BLEND);
             gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
             gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
             glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);
//        gldisable(GL_BLEND);
             glendlist;

             bmpp5(0,'menu02.bmp');
             mousekey := 0;
             regim := 0;
             timer_bool := 0;
             read_model_constant := 0;
            end;
          5:begin
             if score > 75 then
               bmpp5(0,'film1.bmp')
             else
               bmpp5(0,'film2.bmp');
             zastavka_list1 :=glgenlists(1);
             glnewlist(zastavka_list1, GL_compile);
             gltexparameteri(gl_texture_2d,gl_texture_mag_filter,{gl_nearest}gl_linear);
             gltexparameteri(gl_texture_2d,gl_texture_min_filter,{gl_nearest}gl_linear);
             glteximage2d(gl_texture_2d,0,GL_RGBA,512,512,0,GL_RGBA,GL_unsigned_byte,textura_pich);
             glendlist;


             if score > 75 then
               bmpp5(0,'menu01.bmp')
             else
               bmpp5(0,'menu02.bmp');
             mousekey := 0;
             regim := -10;
             timer_bool := 0;
             read_model_constant := 0;
            end;
        end;

        SwapBuffers(DC);
        EndPaint(wnd, Ps);
        // Force window repaint
      InvalidateRect(wnd, nil, FALSE);
      end;

    wm_mousemove:   begin
        mousex := LOWORD(lP)/DeviceMode_real.dmPelsWidth*100;
        mousey := HIWORD(lP)/DeviceMode_real.dmPelsHeight*100;
       end;
    WM_LBUTTONDOWN: begin
        mousekey := wp;
       end;
    WM_LBUTTONUP: begin
        mousekey := 0;
       end;

    WM_DESTROY: begin
(*      GLD_FreeAllTextures;
      GLD_Destroy(dc);
      timekillevent(id_timer);
      glDeleteLists (GLF_START_LIST, 256);

      FreeDirectInput;*)

      PostQuitMessage(0);



    end;
    WM_CREATE:
    begin


//  ReadModel(wnd,{'ship4.3ds'}'a.3ds'); {}
    end;
    WM_SIZE:
    begin


        rerspective;
    end;
        WM_ACTIVATE:
        begin
            if WA_INACTIVE = wP then
                g_bActive := FALSE
            else
                g_bActive := TRUE;

            // Set exclusive mode access to the mouse based on active state
            SetAcquire( wnd );
            Result := 1;
            exit;
            // Pause if minimized
//            wnd_actitate(Wnd, mess, wP, lP);
        end;
   else
      Result := DefWindowProc(Window, Mess, Wp, Lp);
  end;
end;



procedure MyExit;  { дополнительная процедура при выходе в DOS }
begin
  ExitProc:=ExitSave;

  GLD_FreeAllTextures;
  GLD_Destroy(dc);
  timekillevent(id_timer);
  glDeleteLists (GLF_START_LIST, 256);

  FreeDirectInput;

  LoadDefaultscreenMode;
  chdir(chdirstr);


  freemem(sc,sizeof(sc^));
  freemem(space_map_textura,sizeof(space_map_textura^));
  freemem(textura_pich,sizeof(space_map_textura^));
  freemem(textura_babax,sizeof(textura_babax^));
  freemem(textura_babax_real,sizeof(textura_babax_real^));
  freemems;
  Mess_beep := 'close my_midi' + #0;
  mciSendString(@Mess_beep[1], nil, 0, 0);

end;



var
  wc : TWndClass;
  Msg: TMsg;
begin
  ExitSave:=ExitProc;  {переопределение процедуры выхода}
  ExitProc:=@MyExit;

  Mess_beep := 'close my_midi' + #0;
  mciSendString(@Mess_beep[1], nil, 0, 0);



//  assign(t,'out01.txt');
//  rewrite(t);
  getmem(sc,sizeof(sc^));
  getmem(space_map_textura,sizeof(space_map_textura^));
  getmem(textura_pich,sizeof(space_map_textura^));
  getmem(textura_babax,sizeof(textura_babax^));
  getmem(textura_babax_real,sizeof(textura_babax_real^));

//    MyMedia.Create(0);
//    MyMedia.SetDevice({MCI_CDAudio}MCI_WaveAudio);
//    MyMedia.Open({'9'}'fire.wav');

  getdir(0,chdirstr);
  chdir(chdirstr+'\data'{'d:\programs\games\space06\data'});

//  bmpp2(0,'a2.bmp');
  bmpp3(0,'a1.bmp');
//  bmpp5(0,'menu02.bmp');
  bmpp6(0,'exp02.bmp');

//  halt(0);

  FillChar(wc, SizeOf(wc), 0);
  with wc do begin
    style:=CS_HREDRAW + CS_VREDRAW;
    lpfnWndProc := @MyWndProc;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hInstance := System.hInstance;
    hIcon := LoadIcon(hInstance, 'MAINICON');
    hCursor := LoadCursor(THandle(nil), IDC_ARROW);
    hbrBackGround := {COLOR_WINDOW + 1}GetStockObject(BLACK_BRUSH);
    lpszMenuName := nil;
    lpszClassName := 'MADGlBox';
  end;
  if RegisterClass(wc) = 0 then exit;


  wnd := CreateWindow(wc.lpszClassName, nil,WS_POPUP{WS_BORDER}, CW_USEDEFAULT, 0, 300{450}, {450}300, 0, 0, HInstance, nil);


//(************************************)  SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);



//  DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);

//  g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
//  g_pDD.SetDisplayMode(320, 200, 16, 0, 0);





  InitDirectInput(Wnd);








  // Initialize the rendering context
  DC := GetDC(wnd);
  SetDCPixelFormat;
  // Make a GL Context

  HRC := wglCreateContext(DC);
  wglMakeCurrent(DC, HRC);

  // Clear background color to black
  glClearColor(0.0, 0.0, 0.0, 0.0);
  // Clear the depth buffer
  glClearDepth(1.0);
  // Type of depth test
  glDepthFunc(GL_LESS);
  // Smooth color shading
  glShadeModel(GL_SMOOTH);
  // Depth test
  glEnable(GL_DEPTH_TEST);
  glMatrixMode(GL_PROJECTION);
  // Reset projection matrix
  glLoadIdentity;
  // Aspect ratio of the viewport

  rerspective;

//                                   gluPerspective(45.0, WndWidth / WndHeight, 0.1, 100.0);
  glMatrixMode(GL_MODELVIEW);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  gllightmodelfv(gl_light_model_ambient,@global_ambient);

  gllightfv(gl_light0,gl_position,@position);
  gllightmodelf(gl_light_model_local_viewer,1);
//  gllightmodelf(gl_light_model_two_side,1);
  glenable(gl_cull_face);

//wglusefontoutlines(dc,0,255,glf_start_list,0.0,0.15,WGL_FONT_POLYGONS,nil);:
//  wglUseFontOutlines (dc, 0, 255, GLF_START_LIST, 50, 0.15,
//                                                  WGL_FONT_POLYGONS, nil);
  wglUseFontBitmaps(dc, 0, 255, GLF_START_LIST);

(*  for i := 0 to 5 do begin
    lists[i] :=glgenlists(1);
    glnewlist(lists[i],GL_compile);
      gltexparameteri(gl_texture_2d,gl_texture_mag_filter,gl_nearest{gl_lines});
      gltexparameteri(gl_texture_2d,gl_texture_min_filter,gl_nearest);
      glteximage2d(gl_texture_2d,0,GL_RGBA,256,256,0,GL_RGBA,GL_unsigned_byte,@textura[i]);
    glendlist;
  end;*)

///////////////////////////////////////////////////////{  glMaterialfv (GL_FRONT, GL_AMBIENT_AND_DIFFUSE, PGLfloat(@MaterialColor));  }// Reflective properties
  id_timer := timesetevent(20,5,@timeproc,0,TIME_PERIODIC);




  ShowWindow(wnd, SW_SHOW);
  UpdateWindow(wnd);
    SetFocus(Wnd);

//  deb2file('Program begins               ',0);
//       GLD_PrepParams(dc);
//  ReadModel('ship.3ds'{'50pman.3ds'}); {}

(*  ReadModel('ship4.3ds'{'skeleton.3ds'{'50pman.3ds'},1,1); {}
  ReadModel({'50pman.3ds'}{'ship.3ds'}{'X_ship1.3ds'}{'ship6.3ds'}'x29.3ds',2,1); {}
  ReadModel('ship3.3ds'{'50pman.3ds'},3,1); {}
  ReadModel('a.3ds'{'50pman.3ds'},4,1); {}
  ReadModel('banka2.3ds'{'50pman.3ds'},5,1/10); {}
  ReadModel('fire1.3ds'{'50pman.3ds'},6,1/3); {}

  ReadModel('ship3.3ds',7,15); {}
  ReadModel('duck.3ds',8,1); {}*)
//  ReadModel('taracan.3ds'{'50pman.3ds'}); {}
  for i := 1 to 30 do begin
    mysors[i].x := myx+random(40)-20;
    mysors[i].y := myy+random(40)-20;
    mysors[i].z := myz+random(40)-20;
    mysors[i].angle := random(100);
    mysors[i].angle_y := random(100);
  end;

  for i := 1 to 30 do begin
{    asteroids[i].x := myx+random(40)-20;
    asteroids[i].y := myy+random(40)-20;
    asteroids[i].z := myz+random(40)-20;
    asteroids[i].angle := random(100);
    asteroids[i].angle_y := random(100);}
      asteroids[i].angle := random(100);
      asteroids[i].angle_y := random(100);

      asteroids[i].x := myx+{random(40)-20}70*cos(asteroids[i].angle);
      asteroids[i].y := myy+70*sin(asteroids[i].angle_y){random(40)-20};
      asteroids[i].z := myz+{random(40)-20}70*sin(asteroids[i].angle);
      asteroids[i].angle := random(100);
      asteroids[i].angle_y := random(100);
      asteroids[i].heard := 3;
  end;

//  DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);

//  g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
//  g_pDD.SetDisplayMode(800, 600, 16, 0, 0);

//          SetSVGAMode(640, 480, 8, 0);  // Set desired video mode

//    InitApp(hInstance, CmdShow,wnd);

//(**************)                               DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);

//  g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);

//  g_pDD.SetDisplayMode(640, 480, 16, 0, 0);//  g_pDD.SetDisplayMode(320, 200, 16, 0, 0);

//  changedisplaysettings(
//  SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);
  SaveDefaultscreenMode;
  Save_screenMode_real;

      SendMessage(wnd, WM_SYSCOMMAND,SC_MAXIMIZE,0);                 (********************)

(*    readspacemodels;
       kol_objekts := 0;
          GLD_FreeAllTextures;
          DeleteAllObjMat;
//       GLD_FreeAllTextures;
       kol_objekts := 0;
          GLD_FreeAllTextures;
          DeleteAllObjMat;
          GLD_Destroy(dc);
          GLD_PrepParams(dc);
  ReadModel(wnd,{'ship4.3ds'}'seg051.x',2,1,1); {}
  ReadModel(wnd,{'x29.3ds'}{'ship4.3ds'}{'ship3_b.3ds'}'seg051.x',2,2,1); {}
  ReadModel(wnd,{'ship3.3ds'}{'ship3_b.3ds'}'seg051.x',2,3,1); {}
  ReadModel(wnd,'seg051.3ds',2,4,1); {}
  ReadModel(wnd,'seg051.3ds'{'banka_x.x'},2,5,1/10); {}*)
//    read3dbarmodels;
//          GLD_FreeAllTextures;
//          DeleteAllObjMat;
//          kol_objekts := 0;
//          ReadModel(wnd,'a.3ds',1,0,1); {}
//          Nobj3DS := 0;
//          GLD_Destroy(dc);
//          GLD_PrepParams(dc);

  read3dbarmodels;
//  bmpp5(0,'menu02.bmp');
  bmpp5(0,'zastav1.bmp');
{    draw_pribors;
for i := 1 to 10 do
draw_textura_pich;}
//    readspacemodels;
    readbarmap;
    readrepliks;

  myx := 0; myy := 2.1; myz := 0;
  mousex := 0;
  mousey := 0;
  mousekey:=0;


  play_midi := true;
  timer_bool := 0;
  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

(*  LoadDefaultscreenMode;
  chdir(chdirstr);
//  SetFullscreenMode(800,600,16);


  freemem(sc,sizeof(sc^));
  freemem(space_map_textura,sizeof(space_map_textura^));
  freemem(textura_pich,sizeof(space_map_textura^));
  freemem(textura_babax,sizeof(textura_babax^));
  freemem(textura_babax_real,sizeof(textura_babax_real^));
  freemems;
//  freememory;
//  MyMedia.close;
  Mess_beep := 'close my_midi' + #0;
  mciSendString(@Mess_beep[1], nil, 0, 0);

//  close(t);*)
end.