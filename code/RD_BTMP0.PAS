unit rd_btmp0; {чтение файлов битмапа}
interface
uses windows,messages,ijl;

   {dx,dy,ColDep - размеры и глубина цвета, p - адрес, filename - файл}
procedure RecodeAndReadTextureFile(wnd:hwnd; var dx,dy,ColDep: longint; var p : pointer;
   fname : string);

implementation
uses dos, deb_as;

type
  ReadTextureFunc = function(fname:string; var x,y,c : longint; var p : pointer) : string;
  ReaderListType = record   {список ридеров, соответствующих расширениям файлов}
    func : ReadTextureFunc; {}
    extn : string[5];       {}
  end;
  ab = array[0..1024*1024*3-1] of byte;
  pb = ^ab;

function ReadJPG(fname:string; var x,y,c : longint; var p : pointer) : string;
var
  res, dib_buffer_size: Integer;
  dib_buffer: PByte = nil;
  jerr: TIJLERR;
  jcprops: TJPEG_CORE_PROPERTIES;
  Buff: array[0..MAX_PATH] of Char;
  s : string;
begin
  jerr := ijlInit(@jcprops);
  if IJL_OK <> jerr then
  begin
    str(jerr,s);
    ReadJPG := 'ijlInit() failed '+s;
    exit;
  end;
  fname := fname + #0;
  jcprops.JPGFile := @(fname[1]);
  jerr := ijlRead(@jcprops, IJL_JFILE_READPARAMS);
  if IJL_OK <> jerr then
  begin
    str(jerr,s);
    ReadJPG := 'ijlRead() failed '+s;
    exit;
  end;
  dib_buffer_size := jcprops.JPGWidth * jcprops.JPGHeight * jcprops.JPGChannels;
  GetMem(dib_buffer, dib_buffer_size);
  if dib_buffer =  nil then
  begin
    str(jerr,s);
    ReadJPG := 'can''t allocate memory '+s;
    exit;
  end;
  jcprops.DIBWidth       := jcprops.JPGWidth;
  jcprops.DIBHeight      := -jcprops.JPGHeight;
  jcprops.DIBBytes       := dib_buffer;
  jcprops.DIBPadBytes    := 0;
  jcprops.DIBColor       := IJL_BGR;
  jerr := ijlRead(@jcprops, IJL_JFILE_READWHOLEIMAGE);
  if IJL_OK <> jerr then
  begin
    str(jerr,s);
    ReadJPG := 'ijlRead() failed '+s;
    exit;
  end;
  ReadJPG := '';
//  Result := 0;
  p := dib_buffer;
  x := jcprops.JPGWidth;
  y := jcprops.JPGHeight;
  c := jcprops.JPGChannels;
  deb2file('ReadJPG - file: ' + fname + ' ',0);
  deb2file('ReadJPG - x: ',x);
  deb2file('ReadJPG - y: ',y);
  deb2file('ReadJPG - c: ',c);
end;

function ReadDDS(fname:string; var x,y,c : longint; var p : pointer) : string;
type
  DDShType = record
    id,sz,fl,nx,ny : dword;
  end;
  ColorType = record
    b,g,r{,a} : byte;
  end;
  pp44 = record
    c_0,c_1 : word;
    b : array[0..3]of byte;
  end;
  b2array = array[0..1024*1024-1]of pp44;
  ac      = array[0..1024*1024-1]of ColorType;
  pc      = ^ac;
var
  hDDS    : DDShType;
  buf1    : array[0..63]of dword;
  i,j,l,k : longint;
  dx,dx4  : longint;
  dy,dy4  : longint;
  f       : file;
  s1,s2   : string;
  b2      : ^b2array;
  lenf    : longint;
  cc      : array[0..3]of colorType;
  ca      : ColorType;
begin
  assign(f,fname);
  reset(f,1);
  lenf := filesize(f);
  deb2file('ReadDDS - file: ' + fname + ' ',lenf);
  blockread(f,hDDS,sizeof(hDDS));
  if hDDS.id <> 542327876 {'DDS '} then begin
    ReadDDS := 'Неверный формат файла ' + fname + ' ';
    exit;
  end;
  if hDDS.sz > 256 then begin
    str(hDDS.sz,s2);
    ReadDDS := 'Слишком длинный заголовок ' + fname + ' = ' + s2 + ' ';
    exit;
  end;
  blockread(f,buf1,hDDS.sz-16);
  if buf1[16] <> 827611204 {'DXT1'} then begin
    ReadDDS := 'Неподдерживаемый формат файла ' + fname + ' ';
    exit;
  end;
  deb2file('ReadDDS - nx: ',hDDS.nx);
  deb2file('ReadDDS - ny: ',hDDS.ny);
  if (lenf-hDDS.sz-4) < ((hDDS.nx*hDDS.ny) div 16 * sizeof(pp44)) then begin
    str(lenf-hDDS.sz-4,s1);
    str((hDDS.nx*hDDS.ny) div 16 * sizeof(pp44),s2);
    ReadDDS := 'Неверная длина файла ' + fname + ' ' + s1 + ' <> ' + s2;
    exit;
  end;
  x := hDDS.nx;
  y := hDDS.ny;
  c := sizeof(ColorType);   {3 - глубина цвета - RGB}
  getmemF(p,hDDS.nx*hDDS.ny*c,'ReadDDS: p ');
  getmemF(b2,lenf-hDDS.sz-4,'ReadDDS b2 ');
  blockread(f,b2^,lenf-hDDS.sz-4);
  close(f);
  dx  := hDDS.nx;
  dx4 := hDDS.nx div 4;
  dy  := hDDS.ny;
  dy4 := hDDS.ny div 4;
  for j := 0 to dy4-1 do
    for i := 0 to dx4-1 do begin
      cc[0].r := (b2^[j*dx4 + i].c_0 shr 8) and $f8;
      cc[0].g := (b2^[j*dx4 + i].c_0 shr 3) and $fc;
      cc[0].b := (b2^[j*dx4 + i].c_0 shl 3) and $f8;
      cc[1].r := (b2^[j*dx4 + i].c_1 shr 8) and $f8;
      cc[1].g := (b2^[j*dx4 + i].c_1 shr 3) and $fc;
      cc[1].b := (b2^[j*dx4 + i].c_1 shl 3) and $f8;
      cc[2].r := (word(2)*cc[0].r + cc[1].r + 1) div 3;
      cc[2].g := (word(2)*cc[0].g + cc[1].g + 1) div 3;
      cc[2].b := (word(2)*cc[0].b + cc[1].b + 1) div 3;
      cc[3].r := (word(2)*cc[1].r + cc[0].r + 1) div 3;
      cc[3].g := (word(2)*cc[1].g + cc[0].g + 1) div 3;
      cc[3].b := (word(2)*cc[1].b + cc[0].b + 1) div 3;
      for l := 0 to 3 do
        for k := 0 to 3 do begin
          pc(p)^[i*4 + k + ((dy - 1 - j*4 - l)*dx) ] :=
                       cc[(b2^[j*dx4 + i].b[l] shr (2*k)) and 3];
//          putpixel(i*4+k,j*4+l,dword(ca[l,k]));
//          putpixel(i*4+k+260,j*4+l,dword(cc[1]));
         end;
//         putpixel(i+260,j+320,dword(cc[0]));
//         putpixel(i+320,j+320,dword(cc[1]));
//         putpixel(i+390,j+320,dword(cc[2]));
//         putpixel(i+460,j+320,dword(cc[3]));

   end;

//              pb(p)^[(i + j*x)*c + 0] := pal[p0^[k],0];
//              pb(p)^[(i + j*x)*c + 1] := pal[p0^[k],1];
//              pb(p)^[(i + j*x)*c + 2] := pal[p0^[k],2];

  freememF(b2,lenf-hDDS.sz-4,'ReadDDS b2 ');
  deb2file('ReadDDS - ends ',0);
  ReadDDS := '';
end;

function ReadBMP(fname:string; var x,y,c : longint; var p : pointer) : string;
type
   bmFilH = record
      Typf : word;
      Size : longint;
      Res1 : word;
      Res2 : word;
      OfBm : longint;
   end;
   bmInfH = record
      Size : longint; {0e-14 word;  {размер структуры}
      Widt : longint; {12-18}
      Heig : longint; {16-22 }
      Plan : word;    {1a-26 }
      BitC : word;    {1c-28 бит / точка}
      Comp : longint; {1e-30 тип компрессии}
      SizI : longint; {22-34 размер изображения}
      XppM : longint; {26-38 }
      YppM : longint; {2a-42 }
      NCol : longint; {2e-46 число цетов}
      NCoI : longint; {32-50 число основных цветов}
   end;
   bmHead = record
      f : bmFilH;
      i : bmInfH;
   end;
var
  f : file;
  h : bmHead;
  p0 : pb;
  i,j,k,m,n,lenbmpstr : longint;
  pal : array[0..255,0..3]of byte;
begin
  assign(f,fname);
  reset(f,1);
  deb2file('ReadBMP - file: ' + fname + ' ',filesize(f));
  blockread(f,h,sizeof(h));
  if (char(lo(h.f.typf)) <> 'B') or (char(hi(h.f.typf)) <> 'M') then begin
    ReadBMP := 'Неверный формат файла ' + fname + ' ';
    exit;
  end;
  ReadBMP := '';
  deb2file('ReadBMP - f.Size: ',h.f.size);
  deb2file('ReadBMP - i.Size: ',h.i.size);
  deb2file('ReadBMP - i.SizI: ',h.i.sizi);
  if h.i.sizi = 0 then begin
    h.i.sizi := h.f.size-h.i.size-14;
    if h.i.BitC = 8 then
       h.i.sizi := h.i.sizi-1024;
  end;
  deb2file('ReadBMP - i.SizI: ',h.i.sizi);
  x := h.i.widt;
  deb2file('ReadBMP - X: ',x);
  y := h.i.heig;
  deb2file('ReadBMP - Y: ',y);
  c := h.i.BitC div 8;
  deb2file('ReadBMP - C: ',c);
  deb2file('ReadBMP - Compression: ',h.i.comp);
//  lenbmpstr := h.i.SizI div y;
  lenbmpstr := (x*c + 3) and $FFFc;
  deb2file('ReadBMP - l: ',lenbmpstr);
  getmemF(p,x*y*3,'ReadBMP: p ');
  getmemF(p0,h.i.SizI,'ReadBMP: p0 ');
  case h.i.BitC of
    4 : begin
       deb2file('ReadBMP: Неподдерживаемая глубина цвета ',h.i.BitC);
       freememF(p,x*y*3,'ReadBMP: p ');
       p := nil;
       ReadBMP := 'ReadBMP: Неподдерживаемая глубина цвета - 4 ' + fname + ' ';
    end;
    8 : begin
      deb2file('ReadBMP: 8 bpp DataOffset: ',h.f.OfBm);
      blockread(f,pal,sizeof(pal));
      seek(f,h.f.OfBm);
      blockread(f,p0^,h.i.SizI);
      c := 3;
      if h.i.comp = 0 then begin {несжатое изображение}
        for j := 0 to y-1 do
          for i := 0 to x-1 do begin
            pb(p)^[(i + j*x)*c + 0] := pal[p0^[i + j*lenbmpstr],0];
            pb(p)^[(i + j*x)*c + 1] := pal[p0^[i + j*lenbmpstr],1];
            pb(p)^[(i + j*x)*c + 2] := pal[p0^[i + j*lenbmpstr],2];
          end;
      end else begin              {сжатое изображение}
        i := 0;
        j := 0;
        k := 0;
        repeat
          if p0^[k] = 0 then begin {вариант с упр.байтами}
            inc(k);
            case p0^[k] of {второй байт последовательности}
              0 : begin        {конец строки}
                inc(k);
                i := 0;
                inc(j);
              end;
              1 : begin        {конец изображения}
                k := h.i.SizI;
              end;
              2 : begin        {перемещение по рисунку}
                inc(k);
                inc(i,p0^[k]);
                inc(k);
                inc(j,p0^[k]);
                inc(k);
              end;
              3..255 : begin   {перенос байтов}
                n := p0^[k];
                inc(k);
                for m := 1 to n do begin
                  pb(p)^[(i + j*x)*c + 0] := pal[p0^[k],0];
                  pb(p)^[(i + j*x)*c + 1] := pal[p0^[k],1];
                  pb(p)^[(i + j*x)*c + 2] := pal[p0^[k],2];
                  inc(k);
                  inc(i);
                end;
                k := (k+1) and $FFFFFFFE; {выравниваем на четную границу}
              end;
            end; {case}
          end else begin           {вариант с повторением байта}
            n := p0^[k];
            inc(k);
            for m := 1 to n do begin
              pb(p)^[(i + j*x)*c + 0] := pal[p0^[k],0];
              pb(p)^[(i + j*x)*c + 1] := pal[p0^[k],1];
              pb(p)^[(i + j*x)*c + 2] := pal[p0^[k],2];
//              inc(k);
              inc(i);
            end;
            inc(k);
//            k := (k+1) and $FFFFFFFE; {выравниваем на четную границу}
          end; {if}
        until k >= h.i.SizI;
      end; {else if h.i.comp = 0}
      deb2file('ReadBMP: last index p: ',(i + j*x)*c);
      deb2file('ReadBMP: last index p0: ',i + j*lenbmpstr);
    end;
    24 : begin
      deb2file('ReadBMP: 24 bpp DataOffset: ',h.f.OfBm);
      blockread(f,p0^,h.i.SizI);
      for j := 0 to y-1 do
        move(p0^[j*lenbmpstr],pb(p)^[j*x*c],x*c);
    end;
  end; {case}
  close(f);
//      deb2file('ReadBMP: 24 bpp DataOffset: ',h.f.OfBm);
  freememF(p0,h.i.SizI,'ReadBMP: p0 ');
//  ReadBMP := '';
end;

function ReadTGA(fname:string; var x,y,c : longint; var p : pointer) : string;
type
  htgaType = record  {18}
    l1,l2,l3 : longint; {в рассматриваемом случае должны быть 131072, 0, 0}
    width, height : word; {ширина и высота}
    bpp : byte;           {бит на точку}
    xxx : byte;           {признак ориентации}
  end;
var
  htga  : htgaType; {заголовок}
  f     : file;     {файл с битмэпом}
  l,i,j,k,m : longint;  {}
  b     : boolean;  {признак существования и нужной структуры файла}
  p2    : pb;
begin
  deb2file('ReadTGA: begin '+fname,0);
  assign(f,fname);
  reset(f,1);
  if FileSize(f) <= 18 then begin
    deb2file('ReadTGA: file too small, Length:',FileSize(f));
    ReadTGA := 'ReadTGA: file too small';
    close(f);
    exit;
  end;
  blockread(f,htga,sizeof(htga));
  deb2file('ReadTGA: after read header ',htga.l1);
  with htga do begin
    if ((l1<>$20000) and (l1<>$A0000)) or (l2<>0) or (l3<>0) then begin
      Deb2file('ReadTGA: Unsupported format: ',l1{ div 65536});
      ReadTGA := 'ReadTGA: Unsupported format: ';
      close(f);
      exit;
    end;
    x := width;
    y := height;
    c := bpp div 8;
    getmemF(p,x*y*c,' ReadTGA: p ');
    ReadTGA := '';
    case l1 of
      $20000 : begin
        if FileSize(f) < (x*y*c + 18) then begin
          Deb2file('ReadTGA: LengthFile Error - Need: ',(x*y*c + 18));
          Deb2file('ReadTGA: LengthFile Error - is  : ',FileSize(f));
          ReadTGA := 'ReadTGA: LengthFile Error';
        end else begin
          blockread(f,p^,x*y*c);
          deb2file('ReadTGA: after read bitmap, Size: ',x*y*c);
        end;
      end;
      $A0000 : begin
        l := FileSize(f)-18;
        getmemF(p2,l,'ReadTGA: p2 id=$a ');
        blockread(f,p2^,l);
        i := 0;
        j := 0;
        repeat
          k := p2^[i];
          case (k and $80) of
            0 : begin    {raw}
              inc(i);
              m := c*((k and $7f) + 1); {количество переписываемых байт}
              move(p2^[i],pb(p)^[j],m);
              inc(i,m);
              inc(j,m);
            end;
            $80 : begin  {run-length}
              inc(i);
              for m := 0 to (k and $7f) do begin
                move(p2^[i],pb(p)^[j],c);
                inc(j,c);
              end;
              inc(i,c);
            end;
          end;{case}
        until (i >= l) or (j >= x*y*c);
        freememF(p2,l,'ReadTGA: p2 id=$a ');
        if (i <> l) or (j <> x*y*c) then begin
           deb2file('ReadTGA: !!! ERROR !!! i=',i);
           deb2file('ReadTGA: !!! ERROR !!! l=',l);
           deb2file('ReadTGA: !!! ERROR !!! j=',j);
           deb2file('ReadTGA: !!! ERROR !!! *=',x*y*c);
           ReadTGA := 'ReadTGA ERROR ошибка распаковки ';
        end;
      end;
    end; {case}
  end; {with htga}
  close(f);
end;

function ReadCEL(fname:string; var x,y,c : longint; var p : pointer) : string;
type
   celFilH = record
     id  : word;  {37145}
     wid : word;
     hei : word;
     r1  : word;
     r2  : word;
     bpp : word;
     len : word;
     r3  : array[0..8]of word;
   end;
var
  i,j : longint;
  ch : celFilH;
  f    : file;     {файл с битмэпом}
  s1,s2 : string;
  Bcel : pb;
  pal : array[0..255,0..2]of byte;
begin
  assign(f,fname);
  reset(f,1);
  deb2file('ReadCEL: '+fname+' sizeHeader=',sizeof(ch));
  blockread(f,ch,sizeof(ch));
  if (ch.id <> 37145) or (ch.bpp <> 8) then begin
    str(ch.id,s2);
    s1 := 'Ошибка чтения файла ' + fname + ' Id: ' + s2;
    str(ch.bpp,s2);
    s1 := s1 + ', ' + s2 +' bpp'{+ #0};
//    MessageBox(Wnd,@s1[1],'Неизвестный формат файла с текстурой',MB_OK or MB_ICONWARNING);
    ReadCEL := 'ReadCEL: Неизвестный формат файла с текстурой' + s1;
    deb2file(s1,0);
    exit;
  end;
  if (ch.wid*ch.hei) <> ch.len then begin
    str(ch.wid,s2);
    s1 := 'Ошибка чтения файла ' + fname + ' размер: ' + s2;
    str(ch.hei,s2);
    s1 := s1 + ' x ' + s2;
    str(ch.len,s2);
    s1 := s1 + ', размер: ' + s2{ + #0};
//    MessageBox(Wnd,@s1[1],'Неверный размер данных файла с текстурой',MB_OK or MB_ICONWARNING);
    ReadCEL := 'ReadCEL: Неверный размер данных файла с текстурой' + s1;
    deb2file(s1,0);
    exit;
  end;
  x := ch.wid;
  y := ch.hei;
  c := 3;
  getmemF(Bcel,ch.len,'ReadCEL Bcel ');
  getmemF(p,ch.len*longint(3),'ReadCEL p ');
  deb2file(' Read .CEL: sizeX:     ',ch.wid);
  deb2file(' Read .CEL: sizeY:     ',ch.hei);
  deb2file(' Read .CEL: size:      ',ch.len);
  blockread(f,Pal,768);
  blockread(f,Bcel^,ch.len);
  close(f);
  for j := 0 to y-1 do
    for i := 0 to x-1 do begin
      pb(p)^[(i + j*x)*c + 0] := pal[Bcel^[i + (y-j-1)*x],2]*4 + 2;
      pb(p)^[(i + j*x)*c + 1] := pal[Bcel^[i + (y-j-1)*x],1]*4 + 2;
      pb(p)^[(i + j*x)*c + 2] := pal[Bcel^[i + (y-j-1)*x],0]*4 + 2;
    end;
  freememF(Bcel,ch.len,'ReadCEL Bcel ');
  ReadCEL := '';
end;

function ReadOther(fname:string; var x,y,c : longint; var p : pointer) : string;
const
   f1 = '_tmp$$$_.bmp';
var
   s1,s2 : string;
   si : TStartupInfo;
   Pi : TProcessInformation;
   pp : pointer;
   f : file;
   i : longint;
begin
  s1 := fexpand(paramstr(0));     {вычисляем начало командной строки}
  s2 := 'alch.exe' + #0;
  byte(s1[0]) := SearchPath(nil,@s2[1],nil,255,@s1[1],pp);
  while s1[length(s1)] <> '\' do dec(length(s1));
  s1 := s1 + 'alch.exe -w -24 ';
  deb2file('ReadOther - file: '+fname,0);
  deb2file('ReadOther - Command: '+s1+' ',0);
  s2 := s1 + fname + ' ' + f1 + #0;
  fillchar(si,sizeof(si),0);
  fillchar(pi,sizeof(pi),0);
  deb2file('ReadOther - Command: '+s2+' ',0);
  CreateProcess(nil,@s2[1],nil,nil,TRUE,CREATE_NEW_CONSOLE or HIGH_PRIORITY_CLASS,nil,nil, Si,Pi);
  deb2file('ReadOther - afetr CreateProcess ',0);
  WaitForSingleObject(pi.hProcess, INFINITE);

//  PostMessage(pi.hProcess,WM_CLOSE,0,0);
  DestroyWindow(FindWindow(nil,'alch'));
//  PostMessage(GetWindow(,GW_CHILD),WM_CLOSE,0,0);
  //  FaindWindow GetWindow

//     H := FindWindow ('WinMin', @hButtonX[i,j].n[1]{'Win_Min 0'});
//      If H <> 0 then SendMessage (H, MessFunc[i]{WM_SYSCOMMAND}, wParFunc[i]{SC_MINIMIZE}, 0);


  deb2file('ReadOther - afetr WaitForSingleObject ',0);
  deb2file('ReadOther - file: ' + f1 + ' ',0);
  assign(f,f1);  {проверяем наличие файла}
  {$I-}
  reset(f,1);
  {$I+}
  i := IOresult;
  if i <> 0 then begin
    str(i,s2);
    s1 := 'Ошибка чтения файла ' + fname + ' / ' + f1 + ' № ' + s2 + #0;
//    MessageBox(Wnd,@s1[1],'Нет файла с текстурой',MB_OK or MB_ICONWARNING);
    deb2file('ReadOther - !!! ERROR !!! : '+s1+' ',0);
    ReadOther := 'ReadOther - !!! ERROR !!! : '+ s1;
    exit;
  end;
  close(f);
  deb2file('ReadOther - before ReadBMP ',0);
  ReadBMP(f1, x, y, c, p);
  erase(f);
  ReadOther := '';
end;

function MyScaleImage(TypeNum, sx, sy, typeb : longint; s_ : pointer;
                               dx, dy, typea : longint; d_ : pointer):longint;
var
   s,d : pb;
   i,j,k,i0,j0,i1,j1,nc : longint;
   x,y,wx,wy : single;
begin
  if (typeb = 1{GL_UNSIGNED_BYTE}) and (typea = 1{GL_UNSIGNED_BYTE}) then begin
    case TypeNum of
      3{GL_RGB}                  : nc := 3;
      4{GL_RGBA}                 : nc := 4;
      1{GL_RED,GL_GREEN,GL_BLUE} : nc := 1;
      else begin
        deb2file('MyScaleImage !!! ERROR !!! Unsupported TypeNum: ',typeNUm);
        exit;
      end;
    end; {case}
    s := s_;
    d := d_;
    deb2file('MyScaleImage sx= ',sx);
    deb2file('MyScaleImage sy= ',sy);
    deb2file('MyScaleImage dx= ',dx);
    deb2file('MyScaleImage dy= ',dy);
    deb2file('MyScaleImage nc= ',nc);
    for j := 0 to dy-1 do begin
      if sy = dy then begin
        j0 := j;
        j1 := j;
        wy := 1.0;
      end else begin
        y := (j + 0.5)*sy/dy; {центр новой ячейки в координатах старой сетки}
        j0 := round(y-0.5-0.5);
        j1 := j0 + 1;
        if j0 < 0 then begin             {нижний край}
          j0 := 0;
          wy := 0.0;
        end else if j1 >= sy then begin  {верхний край}
          j1 := sy - 1;
          wy := 1.0;
        end else begin                   {серединка}
          wy := j1 - (y - 0.5);
        end;
      end;  {if sy = dy}
//        deb2file('MyScaleImage  j:  ',j);
      for i := 0 to dx-1 do begin
        if sx = dx then begin
          i0 := i;
          i1 := i;
          wx := 1.0;
        end else begin
          x := (i + 0.5)*sx/dx; {центр новой ячейки в координатах старой сетки}
          i0 := round(x-0.5-0.5);
          i1 := i0 + 1;
          if i0 < 0 then begin             {левый край}
            i0 := 0;
            wx := 0.0;
          end else if i1 >= sx then begin  {правый край}
            i1 := sx - 1;
            wx := 1.0;
          end else begin                   {серединка}
            wx := i1 - (x - 0.5);
          end;
        end;   {if sx = dx}
//        deb2file('MyScaleImage  i:  ',i);
//        deb2file('MyScaleImage  j:  ',j);
//        deb2file('MyScaleImage  i0: ',i0);
//        deb2file('MyScaleImage  i1: ',i1);
//        deb2file('MyScaleImage  x:  ',round(x*1000));
//        deb2file('MyScaleImage  wx: ',round(wx*1000));
//        deb2file('MyScaleImage  j0: ',j0);
//        deb2file('MyScaleImage  j1: ',j1);
//        deb2file('MyScaleImage  y:  ',round(y*1000));
//        deb2file('MyScaleImage  wy: ',round(wy*1000));
        if (wx < 0.0) or (wx > 1.0) or (i1 < 0) or (i0 >= sx) then begin
          deb2file('MyScaleImage !!! ERROR !!! i:  ',i);
          deb2file('MyScaleImage !!! ERROR !!! j:  ',j);
          deb2file('MyScaleImage !!! ERROR !!! i0: ',i0);
          deb2file('MyScaleImage !!! ERROR !!! i1: ',i1);
          deb2file('MyScaleImage !!! ERROR !!! x:  ',round(x*1000));
          deb2file('MyScaleImage !!! ERROR !!! wx: ',round(wx*1000));
        end;
        if (wy < 0.0) or (wy > 1.0) or (j1 < 0) or (j0 >= sy) then begin
          deb2file('MyScaleImage !!! ERROR !!! i:  ',i);
          deb2file('MyScaleImage !!! ERROR !!! j:  ',j);
          deb2file('MyScaleImage !!! ERROR !!! j0: ',j0);
          deb2file('MyScaleImage !!! ERROR !!! j1: ',j1);
          deb2file('MyScaleImage !!! ERROR !!! y:  ',round(y*1000));
          deb2file('MyScaleImage !!! ERROR !!! wy: ',round(wy*1000));
        end;
        for k := 0 to nc-1 do
          d^[(i + j*dx)*nc + k] := round(s^[(i0 + j0*sx)*nc + k]*wx     *wy
                                       + s^[(i1 + j0*sx)*nc + k]*(1.-wx)*wy
                                       + s^[(i0 + j1*sx)*nc + k]*wx     *(1.-wy)
                                       + s^[(i1 + j1*sx)*nc + k]*(1.-wx)*(1.-wy));
      end;{for i}
    end;  {for j}
    MyScaleImage := 0;
  end else begin
    deb2file('MyScaleImage !!! ERROR !!! Unsupported typea: ',typea);
    deb2file('MyScaleImage !!! ERROR !!! Unsupported typeb: ',typeb);
    MyScaleImage := -1;
  end;
  MyScaleImage := 0;
end;

const
  NumExt = 5; {количечтво обрабатываемых расширений файлов}
  ReaderList : array[0..NumExt]of ReaderListType =
      ((func : ReadOther;  extn : '???'),
       (func : ReadJPG;    extn : 'JPG'),
       (func : ReadDDS;    extn : 'DDS'),
       (func : ReadBMP;    extn : 'BMP'),
       (func : ReadTGA;    extn : 'TGA'),
       (func : ReadCEL;    extn : 'CEL'));

procedure RecodeAndReadTextureFile(wnd:hwnd; var dx,dy,ColDep: longint; var p : pointer;
   fname : string);
var
   s1,s2,s3      : string;
   i,j,NLF       : longint;
   f             : file;
   nx,ny,nx0,ny0 : longint;
   p2            : pb;
const
   MaxNxy = 6;
   NXY : array[0..MaxNxy]of longint = (32,64,128,256,512,1024,2048);
   DXY : array[1..MaxNxy]of longint = (   45,90,181,362,724,1448);
begin
{*** 1 - анализ расширения файла ***}
  i := pos('.',fname);
  s1 := '';
  if length(fname) > i then
    for j := i+1 to length(fname) do
      s1 := s1 + UpCase(fname[j]);
  deb2file('RecodeAndReadTextureFile - Ext: '+s1+' ',0);
{выбор программы чтения по расширению файла}
  NLF := 0;
  for i := 1 to NumExt do
    if ReaderList[i].extn = s1 then
      NLF := i;
{*** 2 - проверяем наличие файла ***}
  assign(f,fname);  {проверяем наличие файла}
  {$I-}
  reset(f,1);
  {$I+}
  i := IOresult;
  deb2file('RecodeAndReadTextureFile - IOerror: ',i);
  s3 := fname;
  if i <> 0 then begin
    str(i,s2);
    s1 := 'Ошибка чтения файла ' + fname + ' № ' + s2;
    if ReaderList[NLF].extn = 'BMP' then begin {попытка подстановки DDS вместо BMP}
      deb2file('RecodeAndReadTextureFile - IOerror / BMP file ',i);
      i := pos('.',s3);
      delete(s3,i,length(s3)-i+1);
      s3 := s3 + '.DDS';
      deb2file('RecodeAndReadTextureFile - IOerror / try DDS file: ' + s3 + ' ',0);
      assign(f,s3);  {проверяем наличие файла}
      {$I-}
      reset(f,1);
      {$I+}
      i := IOresult;
      deb2file('RecodeAndReadTextureFile - IOerror / try DDS file: ' + s3 + ' IOerror ',i);
      if i <> 0 then begin
        str(i,s2);
        s1 := s1 + ' / ' + s3 + ' № ' + s2 + #0;
        MessageBox(Wnd,@s1[1],'Нет файла с текстурой',MB_OK or MB_ICONWARNING);
        exit;
      end else begin  {есть файл .DDS}
        {выбор программы чтения по расширению файла}
        NLF := 0;
        for i := 1 to NumExt do
          if ReaderList[i].extn = 'DDS' then
            NLF := i;
      end;                            {конец попытки подстановки DDS}
    end else begin              {другие расширения}
      s1 := s1 + #0;
      MessageBox(Wnd,@s1[1],'Нет файла с текстурой',MB_OK or MB_ICONWARNING);
      exit;
    end;
  end;
  close(f);
  deb2file('RecodeAndReadTextureFile - read ' + s3 + ' ',0);
  s2 := ReaderList[NLF].func(s3, dx, dy, ColDep, p2);
  deb2file('RecodeAndReadTextureFile - texture pointer: ',dword(p2));
//  if j = -1 then
//    s2 := ReadOther(fname, dx, dy, ColDep, p2);
{*** 3 - анализ подготовленного файла и при необходимости вычисление новых размеров ***}
//{******}    MessageBox(Wnd,'2','1',MB_OK or MB_ICONWARNING);
  if s2 <> '' then begin
    MessageBox(Wnd,@s2[1],'Файл с текстурой',MB_OK or MB_ICONWARNING);
    deb2file(s2,0);
    exit;
  end;
  nx := dx;
  if (nx<>32) and (nx<>64) and (nx<>128) and (nx<>256) and (nx<>512) and (nx<>1024) and (nx<>2048) then begin
    deb2file('RecodeAndReadTextureFile - change nX: ',nx);
    nx := nxy[0];
    for i := 1 to MaxNxy do
      if dx > dxy[i] then nx := nxy[i];
  end;
  deb2file('RecodeAndReadTextureFile - nX: ',nx);
  ny := dy;
  if (nx<>32) and (ny<>64) and (ny<>128) and (ny<>256) and (ny<>512) and (ny<>1024) and (ny<>2048) then begin
    deb2file('RecodeAndReadTextureFile - change nY: ',ny);
    ny := nxy[0];
    for i := 1 to MaxNxy do
      if dy > dxy[i] then ny := nxy[i];
  end;
  deb2file('RecodeAndReadTextureFile - nY: ',ny);
{*** 4 - приведение файла к нужному размеру ***}
  nx0 := dx;
  ny0 := dy;
  deb2file('RecodeAndReadTextureFile - Old nX: ',nx0);
  deb2file('RecodeAndReadTextureFile - Old nY: ',ny0);
  deb2file('RecodeAndReadTextureFile - New nX: ',nx);
  deb2file('RecodeAndReadTextureFile - New nY: ',ny);
  deb2file('RecodeAndReadTextureFile - ColDep: ',ColDep);
  if (nx0 = nx) and (ny0 = ny) then begin
    p := p2;
    deb2file('RecodeAndReadTextureFile - Not ScaleImage: ',0);
  end else begin
    getmemF(p,nx*ny*ColDep,' ReadTexture: p ');
    case ColDep of
      3 : j := 3{GL_RGB};
      4 : j := 4{GL_RGBA};
    end; {case}
    deb2file('RecodeAndReadTextureFile - format: ',j);
    i := MyScaleImage(j, nx0, ny0, 1{GL_UNSIGNED_BYTE}, p2, nx, ny, 1{GL_UNSIGNED_BYTE}, p);
    deb2file('RecodeAndReadTextureFile - ScaleImage: ',i);
    dx := nx;
    dy := ny;
    freememF(p2,nx0*ny0*ColDep,' ReadTexture: p2 ');
    deb2file('RecodeAndReadTextureFile - after read bitmap, Size: ',dx*dy*ColDep);
  end;
  deb2file('RecodeAndReadTextureFile - texture pointer: ',dword(p));
end;

end.