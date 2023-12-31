Unit ReadLWO1;{LightWave file (LWO) reader by S. Andrianov 2002 andriano@tsinet.ru}
{��� ����������� ����������� OpenGL ������� ���� ��� Z}
{���� ����������� ����� �������������� � �������������� ��������� (��.���������)}
interface

procedure ReadLWOfile(filename:string); {������ �������� ������ � ������}

implementation
uses windows, messages, deb_as, comm_3d;

const
  UseDet1 = {FALSE{}TRUE{};  {������������ �� �������������� (�����.�������.<0) ��������}
  UseDet2 = TRUE{}{FALSE{};  {������������ �� �������������� ��������}
var
   nmo : array[1..MaxMatObj]of longint; {������ ���������� ��������, ��������������� ������������}
   nnmo : longint; {���������� ������������ � �������}
type
  ChunkType = record  {��� ����� ���������� �� ������}
    n : string[5];    {�������������}
    l : longint;      {�����}
    b : boolean;      {�������� �� �� �����������}
  end;
  TpL = array[0..65535]of longint;
var
  UsedChunks    : array[1..256]of ChunkType;   {������ ������, ������������� � �����}

{******************************************************************************}
{****** ���������, �������������� ���������������� ������ �� ����� ************}
{******************************************************************************}

function ReadASCII:string; {������ 0-terminated string}
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
   if odd(FilePos) then begin {���������� �� ������ �������}
     inc(FilePos,1);
     seek(f,FilePos);
   end;
//   messagebox(0,'ReadASCII',@ss[1],MB_OK);  {}
   ReadASCII := ss;
end;

procedure MarkChunk(w:string; len:longint); {������ ���� � ������ ��������������}
var i : integer;
begin
  i := 0;
  repeat
    inc(i);
  until (UsedChunks[i].n = w) or (UsedChunks[i].n = '') or (i >= 256);
  if i >= 256 then begin
    if ToFile then
      writeln(t,'MarcChunk ERROR: Chunk List Overflow');
    if ToErrorFile then
      writeln(q,'MarcChunk ERROR: Chunk List Overflow',
              ' chunk = ',w,' File Ofs:',FilePos,'(',l2str(FilePos),') ');
    halt;
  end;
  if UsedChunks[i].n = '' then begin
    UsedChunks[i].n := w;
    UsedChunks[i].l := len;
 end;
end;

{function GetChunkIndex(id:word):integer; {���������� ������ ����� � ������� ��������-�������������}
{var j,index :integer;
begin
  index := 0;
  for j := 0 to MaxNC do
    if ChunkDesc[j].i = id then
      index := j;
  GetChunkIndex := index;
end;

function Known(id:word):boolean;{��������, ������ �� ��������� ���� ��� �����}
{begin
  Known := GetChunkIndex(id) <> 0;
end;}

{************************************************}
function ReadChunkName : string;
var
  s : string;
  i : longint;
begin
  blockread(f,s[1],4);
  s[0] := #4;
  for i := 1 to 4 do
    s[i] := UpCase(s[i]);
  ReadChunkName := s;
  inc(FilePos,4);
  inc(NumChunkRead);
end;

function ReadChunkLen4i : longint;
var
  i : longint;
  b : array[0..3]of byte absolute i;
  c : byte;
begin
  blockread(f,i,4);
  c := b[0];   b[0] := b[3];   b[3] := c;
  c := b[1];   b[1] := b[2];   b[2] := c;
  ReadChunkLen4i := i;
  inc(FilePos,4);
end;

function ReadChunkLen4s : single;
var
  i : single;
  b : array[0..3]of byte absolute i;
  c : byte;
begin
  blockread(f,i,4);
  c := b[0];   b[0] := b[3];   b[3] := c;
  c := b[1];   b[1] := b[2];   b[2] := c;
  ReadChunkLen4s := i;
  inc(FilePos,4);
end;

function ReadChunkLen2 : word;
var
  i : word;
  b : array[0..1]of byte absolute i;
  c : byte;
begin
  blockread(f,i,2);
  c := b[0];   b[0] := b[1];   b[1] := c;
  ReadChunkLen2 := i;
  inc(FilePos,2);
end;

procedure Revers4(p:pointer; count:longint);{�������������� count 4-�������� �������}
type btype = array[0..65536*4*2-1]of byte;
var
  i : longint;
  b : ^btype;
  c : byte;
begin
  b := p;
  for i := 0 to count-1 do begin
    c := b^[i*4];     b^[i*4]   := b^[i*4+3];   b^[i*4+3] := c;
    c := b^[i*4+1];   b^[i*4+1] := b^[i*4+2];   b^[i*4+2] := c;
  end;
end;

procedure Revers2(p:pointer; count:longint);{�������������� count 4-�������� �������}
type btype = array[0..65536*4*2-1]of byte;
var
  i : longint;
  b : ^btype;
  c : byte;
begin
  b := p;
  for i := 0 to count-1 do begin
    c := b^[i*2];     b^[i*2]   := b^[i*2+1];   b^[i*2+1] := c;
  end;
end;

{*************************************************************}
{******* ��������� ������ �������� ������ ********************}
{*************************************************************}
procedure ReadPNTS(l : longint);{������ ������}
var
  Count : word;
  kk : longint;
  MaX,MiX,MaY,MiY,MaZ,MiZ : single; {������� �������}
begin
  Count := l div sizeof(TRealVector);
  if Count > MaxPoints then begin
    if ToFile then
      writeln(t,'    ������� ����� �����: ',Count,' ( ��� ����: ',Npoints,' ��������: ',MaxPoints,')');
    if ToErrorFile then
      writeln(q,'    ������� ����� �����: ',Count,' ( ��� ����: ',Npoints,' ��������: ',MaxPoints,
         ' File Ofs:',FilePos,'(',l2str(FilePos),') ');
    halt;
  end;
  if (l mod sizeof(TRealVector)) <> 0 then begin
    if ToFile then
      writeln(t,'    ����� ����� � ��������� �������� ����� �������, l: ',l,
                     ' �������: ',l mod sizeof(TRealVector),
      ' ( ��� ����: ',Npoints,' ��������: ',MaxPoints,')');
    if ToErrorFile then
      writeln(q,'    ����� ����� � ��������� �������� ����� �������, l: ',l,
                     ' �������: ',l mod sizeof(TRealVector),
         ' File Ofs:',FilePos,'(',l2str(FilePos),') ');
    halt;
  end;
  if ToFile then
    writeln(t,'    ������: ',Count,' �����: ',Npoints);
  inc(Npoints,Count);
  if Mpoints < Count then Mpoints := Count;
  with Obj3DS[CurObj3DS] do begin
    nv := Count;
    getmemF(pv,Count*sizeof(TRealVector),'r3:VertL');
    blockread(f,pv^,Count*sizeof(TRealVector));  inc(FilePos,l);
    Revers4(pv, longint(3)*count); {����� ����� ������ ��������}
    MaX := -1.e36;   MiX := 1.e36;
    MaY := -1.e36;   MiY := 1.e36;
    MaZ := -1.e36;   MiZ := 1.e36;
    for kk := 0 to Count - 1 do begin
      pv^[kk].z := - pv^[kk].z; { !!! ����� ������ ���� ��� Z ��� ����� OpenGL !!! }
      if MaX < pv^[kk].x then MaX := pv^[kk].x;
      if MiX > pv^[kk].x then MiX := pv^[kk].x;
      if MaY < pv^[kk].y then MaY := pv^[kk].y;
      if MiY > pv^[kk].y then MiY := pv^[kk].y;
      if MaZ < pv^[kk].z then MaZ := pv^[kk].z;
      if MiZ > pv^[kk].z then MiZ := pv^[kk].z;
    end;
    if ToFile then
      writeln(t,'    ������: ',Count,' Range: X=(',MiX:8:2,':',MaX:8:2,
          ') Y=(',MiY:8:2,':',MaY:8:2,') Z=(',MiZ:8:2,':',MaZ:8:2,')');
  end;
end;

procedure ReadSRFS(l : longint);{������ ���� ������������}
var
  i : longint;
  s : string;
begin
  i := FilePos;
  repeat
    inc(nnmo);
    s := ReadASCII;
    CreateMaterial(s);
    CreateMatObj(CurObj3DS, 0, s); {�������� ��������� �������}
    if ToFile then
      writeln(t,'  Surface: ',s,' N: ',nnmo,' CurMater: ',CurMater,' CurMatObj: ',CurMatObj);
    nmo[nnmo] := CurMatObj;
  until FilePos >= i+l;
  if ToFile then
    writeln(t,' ��������� ',nnmo,' ������������');
end;

procedure ReadPOLS(l : longint);{������ ���������}
type
  wtype = array[0..65536*16-1]of word;
  ltype = array[0..65536*16-1]of longint;
var
  CountDet : longint; {-1 - ���-���, 0 - �������, >0 - ���-���}
  l1,l2 : longint; {���.��������: l1 - ����� ������(word), l2 - ����� ����(word)}
  l4    : longint; {���.��������: l4 - ����� ����}
  l5    : longint; {���.��������: l5 - ���-�� ������������� (���.�����������)}
  llbb     : longbool; {��� ������� �������������� ���������}
  i,j : longint;
  stat_m,stat_surf : array[0..255]of longint; {����������: �����.�����.�� ����� ������ / �����. � ����������� }
  stat_s : longint; {�-�� ���������}
  n,np,ns : longint; {������� � �����, ���������� ����� � ����� �����������}
  b : ^wtype;      {��������� ������: ������ + ����. ����������}
  n_p,n_t : ^ltype;  {�-�� �����.�� �������., �-�� �����. �� �������.}
  n_ps,n_ts : longint; {��������� �-�� ��������� � �������������}
begin
  if ToFile then
    writeln(t,'ReadPOLS l= ',l);
  getmemF(b,l + Nmater*8,' temp ReadPOLS ');
  fillchar(b^,l + Nmater*8,0);
  n_p := pointer(longint(b) + l);
  n_t := pointer(longint(b) + l + Nmater*4);
  n_ps := 0;
  n_ts := 0;
  blockread(f,b^,l);  inc(FilePos,l);
  revers2(b,l div 2);
{�������� ���������� �� ��������� � ������������ ���������� ������������� �� ������������}
  fillchar(stat_m,sizeof(stat_m),0);
  fillchar(stat_surf,sizeof(stat_surf),0);
  stat_s := 0;  {�-�� ���������}
//  llbb := FALSE; {�������������� �������}
  l2   := 0;  {��������� ����� �������������� ����������� ���������}
  l4   := 0;  {��������� ���������� �������������� ���������}
  l5   := 0;  {��������� ���������� �������������� (������.<0) ���������}
{������ ������}
  n := 0;    {������� ������� � �����}
  CountDet := 0; {������� �������������� ���������}
  repeat  {���� �� ���������}
    inc(stat_s);
    np := b^[n];   inc(n); {�-�� ����� � ��������}
    if np > 256 then begin
      if ToFile then
        writeln(t,' ������ ���������� ����� � ��������: ',np,' FilePos: ',FilePos);
      if ToErrorFile then
        writeln(q,' ������ ���������� ����� � ��������: ',np,' FilePos: ',FilePos);
    end;
    if np > 1024 then
      halt; { !!! ����� �� ��������� ��� ������� ������� ���������� ����� � �������� !!! }
    inc(stat_m[lo(np)]);
    ns := b^[n+np];    {����� �����������}
{��������� ����� ����������� �� �������������� ��� ���������� �������������� ��������}
    if ns > nnmo then begin {���������.�������.��� �������.� ���.����������}
      ns := 65536 - ns;
      if (ns > 0) and (ns <= nnmo) then begin {������.� ���.����������}
        if ToFile then
          writeln(t,' !!! Negative Surface ns= ',ns,' ( ',65536-ns, '), np= ',np,
             ' detail polygon list contain ',b^[n+np+1],' entries, Surface Name: ',MatObj[nmo[ns]].nm);
      end else begin                            {�������������� �����������}
        if ToFile then
          writeln(t,' !!! Negative Surface ns= ',ns,' ( ',65536-ns, '), np= ',np,
             ' detail polygon list contain ',b^[n+np+1],' entries, No such Surface !!!');
//        halt;
      end;
      CountDet := -1;
    end; {}
{������������ ������������ ������� ����������� � ���������� �������������� ��������}
    if (CountDet = 0) or (UseDet1 and (CountDet = -1)) or (UseDet2 and (CountDet > 0)) then
      if (ns > 0) and (ns <= nnmo) then {��������� ������ ������������ �����������}
        if np > 2 then begin {��������� ������ �������� � 3 � ����� ���������}
          inc(n_ps);
          inc(n_ts,np-2);
          inc(n_p^[lo(ns)]);
          inc(n_t^[lo(ns)],np-2);
        end;
    inc(stat_surf[lo(ns)]);
    inc(n,np+1);
//    writeln(t,' ������ ������, ������� ',stat_s,' np= ',np,' ns= ',ns,' n_ps=',n_ps,
//       ' n_ts= ',n_ts,' nnmo= ',nnmo,' CountDet= ',CountDet,' n=',n);
//    writeln(t,' l1= ',l1,' l2= ',l2,' l4= ',l4,' l5= ',l5);
{������ �������������� ���������}
    if CountDet = -1 then begin {�������������� �������}
      l1 := 0; {���������� ����������� ���� (W2)}
      CountDet := b^[n];    inc(n); {���������� �������������� ���������}
      inc(l5);
      inc(l4,CountDet);
    end else begin
      if CountDet > 0 then begin {�������������� �������}
        inc(l1,np+2);
        inc(l2,np+2);
//        if ToFile then
//          writeln(t,'    ',i,' �������������� ������� np= ',np,' ns= ',ns,' ( ',65536-ns,' )',
//            b^[n-1-np]:6,b^[n-np]:6,b^[n-np+1]:6,b^[n-np+2]:6);
        if CountDet = 1 then
          if ToFile then
            writeln(t,'    �������: ',CountDet,' ���.���������, ������ ',l1,' word, ���.� �����: ',
                 n*2,', ��� �����:  ',l,' ������.�����: ',l2,' ����� ����.:',b^[n]);
        dec(CountDet);
      end;
    end;
  until n*2 >= l; {���� �� ������� ��� �����}
{�� ��������� ���������� ��������� Obj3DS.pf[nf] � MatObj.pf[nf]}
{��������� ������}
  for i := 1 to nnmo do
    if n_t^[i] > 0 then
      getmemF(MatObj[nmo[i]].pf,n_t^[i]*sizeof(longint),'rdLWO:MatObj.pf');
  getmemF(Obj3DS[CurObj3DS].pf,n_ts*sizeof(FaceType),'rdLWO:Obj3DS.pf');
{������������� ������������� �� ��������}
  inc(Nfaces,n_ts);
  inc(NfaceMat,n_ts);
  if Mfaces < n_ts then Mfaces := n_ts;
{������ ������}
  n := 0;    {������� ������� � �����}
  CountDet := 0; {������� �������������� ���������}
  repeat  {���� �� ���������}
    np := b^[n];   inc(n);  {�-�� ����� � ��������}
    ns := b^[n+np];         {����� �����������}
{��������� ����� ����������� �� �������������� ��� ���������� �������������� ��������}
    if ns > nnmo then begin {���������.�������.��� �������.� ���.����������}
      ns := 65536 - ns;
      CountDet := -1;
    end; {}
{������������ ������������ ������� ����������� � ���������� �������������� ��������}
    if (CountDet = 0) or (UseDet1 and (CountDet = -1)) or (UseDet2 and (CountDet > 0)) then
      if (ns > 0) and (ns <= nnmo) then {��������� ������ ������������ �����������}
        if np > 2 then begin {��������� ������ �������� � 3 � ����� ���������}
          for j := 0 to np-3 do begin {���� �� �������������, �������� � �������}
            with Obj3DS[CurObj3DS] do begin
              i := nf + j;
              pf^ [i][1] := b^[n];
              pf^ [i][2] := b^[n+j+1];
              pf^ [i][3] := b^[n+j+2];
              if (pf^[i][1] < 0) or (pf^[i][1] > (nv-1)) or
                 (pf^[i][2] < 0) or (pf^[i][2] > (nv-1)) or
                 (pf^[i][3] < 0) or (pf^[i][3] > (nv-1)) then begin
                if ToFile then
                  writeln(t,'    Faces error: Max',nv-1:8,pf^[i][1]:8,pf^[i][2]:8,pf^[i][3]:8);
                if ToErrorFile then
                  writeln(q,'    Faces error: Max',nv-1:8,pf^[i][1]:8,pf^[i][2]:8,pf^[i][3]:8,
                      ' File Ofs:',FilePos,'(',l2str(FilePos),') ');
              end;
            end; {with}
            with MatObj[nmo[ns]] do {�������� �� ������������}
              if lb then
                pf^[nf+j] := i
              else begin
                if ToFile then
                  writeln(t,'  ReadPOLS ERROR �������������� ���.������� nmo[',ns,']=',nmo[ns]);
                if ToErrorFile then
                  writeln(q,'  ReadPOLS ERROR �������������� ���.������� nmo[',ns,']=',nmo[ns]);
              end;
          end; {for i}
          inc(Obj3DS[CurObj3DS].nf, np-2);
          inc(Obj3DS[CurObj3DS].nfm,np-2);
          inc(MatObj[nmo[ns]].nf,   np-2);
        end;
    inc(n,np+1);
{������ �������������� ���������}
    if CountDet = -1 then begin {�������������� �������}
      l1 := 0; {���������� ����������� ���� (W2)}
      CountDet := b^[n];    inc(n); {���������� �������������� ���������}
    end else begin
      if CountDet > 0 then begin {�������������� �������}
        inc(l1,np+2);
////        if ToFile then
////          writeln(t,'  *2*  ',i,' �������������� ������� np= ',np,' ns= ',ns,' ( ',65536-ns,' )',
////            b^[n-1-np]:6,b^[n-np]:6,b^[n-np+1]:6,b^[n-np+2]:6);
        if CountDet = 1 then
          if ToFile then
            writeln(t,'  *2*  �������: ',CountDet,' ���.���������, ������ ',l1,
                 ' word, ���.� �����: ',n*2,', ��� �����:  ',l,' ����� ����.:',b^[n]);
        dec(CountDet);
      end;
    end;
  until n*2 >= l; {���� �� ������� ��� �����}
  if ToFile then begin {�������� �� ���������� ����������� ���� �������� �� ������� b}
    if Obj3DS[CurObj3DS].nf <> n_ts then
      writeln(t,' ������ ������� �������: Obj3DS[CurObj3DS].nf=',Obj3DS[CurObj3DS].nf,' n_ts=',n_ts);
    for i := 1 to nnmo do
      if MatObj[nmo[i]].nf <> n_t^[i] then
        writeln(t,' ������ ������� �������: MatObj[nmo[',i,']].nf=',MatObj[nmo[i]].nf,
                       ' n_t^[',i,']=',n_t^[i],' nmo[i]=',nmo[i]);
  end;
{����� ����������}
  if ToFile then begin
    writeln(t,'������� ',stat_s,' ���������, ������ ',n,' word ������ ',
      n_ps,' ��������� � ',n_ts,' ������������� ===');
      if l2 > 0 then
        writeln(t,' ��������� ',l4,' �������������� ��������� ��������� ������ ',l2*2,' ����');
    writeln(t,' === ���������� ����� � �������� ===');
    for i := 0 to 255 do
      if stat_m[i] <> 0 then
        writeln(t,i:12,stat_m[i]:8);
    writeln(t,' === ���������� ��������� � ������������ (�����, ��������, �������������) ===');
    for i := 0 to 255 do
      if stat_surf[i] <> 0 then
        writeln(t,' ������:',i,' MO:',nmo[i]:6,' �����: ',stat_surf[i]:6,' ��������: ',n_p^[i]:6,
           ' �����-���: ',n_t^[i]:6,' ��� MO: ',MatObj[nmo[i]].nm);
    writeln(t,' ========================================');
  end;
  freememF(b,l + Nmater*8,' temp ReadPOLS ');
end;

procedure ReadCRVS(l : longint);{������ ������ ��������}
var i : longint;
begin
  inc(FilePos,l);
  seek(f,FilePos);
end;

procedure ReadPCHS(l : longint);{������ MetaNURBS ������}
var i : longint;
begin
  inc(FilePos,l);
  seek(f,FilePos);
end;

{******************************************}
procedure ReadSURF(l : longint);{������ ���������� ������������}
var
  chl : longint;

    function ReadIP2(s:string) : single; {������ ������������� ��������}
    var
      i : longint;
      fl : single;
    begin
      i := ReadChunkLen2;
      fl := i / 256;
      if ToFile then
        writeln(t,'  '+s+': ',i,' (',fl:6:3,')');
      if chl > 2 then begin
        inc(FilePos,chl-2);
        seek(f,FilePos);
        if ToFile then
          writeln(t,'  !!! '+s+' old size: ',chl);
      end;
      ReadIP2 := fl;
    end;

    function ReadFP4(s:string) : single; {������ ������������� ��������}
    var fl : single;
    begin
      fl := ReadChunkLen4s;
      if ToFile then
        writeln(t,'  '+s+'(v): ',fl:6:3);
      ReadFP4 := fl;
    end;

const
  c : array[0..3]of single = (-1.0,-1.0,-1.0,-1.0);{COLR}
  lumi1  : single = 0.0; { * Matrial.emit*color - LUMI/VLUM}
  diff1  : single = 0.0; { * Matrial.diff*color - DIFF/VDIF}
  spec1  : single = 0.0; { * Matrial.spec*color - SPEC/VSPC}
  refl1  : single = 0.0; { * aMatrial.mbi*color - REFL/VRFL   ?}
  tran1  : single = 0.0; { * Matrial.tran       - TRAN/VTRN}
  glos1  : single = 0.0; {   Matrial.shine      - GLOS        ?}
{*****************}
//    nt    : Namestr;    CTEX       {80 ��� ����� ��������   }
//    texp  : single;                { 4 ������� ��������}
// ++   ambi  : ColorType;  REFL, VRFL  {16 ���� ���������� ���������     (default=(0.2,0.2,0.2,1))}
// ++   diff  : ColorType;  DIFF, VDIF  {16 ���� ���������� ���������     (default=(0.8,0.8,0.8,1))}
// ++   spec  : ColorType;  SPEC, VSPC  { 16 ���� ����������� ���������    (default=(0.1,0.1,0.1,1))}
// ++   emis  : ColorType;  LUMI, VLUM  {16 ���� ���������                (default=(0.0,0.0,0.0,1))}
// ++   tran  : single;     TRAN, VTRN  { 4 ������� ������������          (default=0)}
// ++   shin  : single;     GLOS       { 4 ������� ����������� ��������� (default=0)}
{��� � ��������� �������� - 0.0-1.0, � �����: }
{ LUMI, DIFF, SPEC, REFL, TRAN - ip2 - (0-256)}
{ VLUM, VDIF, VSPC, VRFL, VTRN - fp4 - (0.0-1.0)}
{ FLAG : 0000000123456789 : ShadAlph, Add, DoubSide, SharpTerm, TranspEdge, OpaqueEdge, }
{     ColorFilter, ColorHightlights, Smoothing, Outline, Luminous}
{ ���� ��� ������ Lum - 100%, ������������ ������. ���� ��� ������ - 0.0}
{ GLOS - /1024 ,RFLT - ���� �� ������������}
{ CTEX - ��� ����� ��������, }
{ TCLR - texture color - C4}
{****************}
var
  kk,fp : longint;
  Imat,Imo : longint; {������ ��������������� ��������� � ��������� �������}
  s,name,chn : string;
  clr : array[0..3]of byte;
  w : word;
begin
  c[0] := -1.0; {COLR R}
  c[1] := -1.0; {COLR G}
  c[2] := -1.0; {COLR B}
  c[3] := -1.0; {COLR A}
  lumi1  := 0.0; { * Matrial.emit*color - LUMI/VLUM}
  diff1  := 0.0; { * Matrial.diff*color - DIFF/VDIF}
  spec1  := 0.0; { * Matrial.spec*color - SPEC/VSPC}
  refl1  := 0.0; { * aMatrial.mbi*color - REFL/VRFL   ?}
  tran1  := 0.0; { * Matrial.tran       - TRAN/VTRN}
  glos1  := 0.0; {   Matrial.shine      - GLOS        ?}
  fp   := FilePos;
  name := ReadASCII;
  Imo  := FindMatObj(name, CurObj3DS); {����� ������ ��������� ������� �� �����}
  Imat := FindMaterial(name); {����� ������ ��������� �� �����}
  if ToFile then begin
    writeln(t,'  ReadSurf ',name,' N MatObj Imo: ',Imo,' name: ',MatObj[Imo].nm,
          ' N Mater Imat: ',Imat,' name: ',Material[Imat].nm);
  end;
  repeat {��������� ���������}
    chn := ReadChunkName;
    chl := ReadChunkLen2;
    MarkChunk(chn,chl);
    if ToFile then
      writeln(t,'sub ',chn,' size: ',chl:8,'/',l2str(chl),' Position: ',FilePos:8,'/',l2str(FilePos));
    if          chn = 'COLR' then begin
      blockread(f,clr,4);   inc(FilePos,4);
      for kk := 0 to 3 do
        c[kk] := clr[kk] / 255;
      if ToFile then
        writeln(t,'  Color: R= ',clr[0],' G=',clr[1],' B=',clr[2],' A=',clr[3]);
    end else if chn = 'FLAG' then begin
      w := ReadChunkLen2;
      MatObj[Imo].fl0 := w;
      MatObj[Imo].fl1 := w;
      if ToFile then
        writeln(t,'  Flags: ',w2b(w));
    end else if chn = 'LUMI' then begin
      lumi1 := ReadIP2(chn);
    end else if chn = 'VLUM' then begin
      lumi1 := ReadFP4(chn);
    end else if chn = 'DIFF' then begin
      diff1 := ReadIP2(chn);
    end else if chn = 'VDIF' then begin
      diff1 := ReadFP4(chn);
    end else if chn = 'SPEC' then begin
      spec1 := ReadIP2(chn);
    end else if chn = 'VSPC' then begin
      spec1 := ReadFP4(chn);
    end else if chn = 'REFL' then begin
      refl1 := ReadIP2(chn);
    end else if chn = 'VRFL' then begin
      refl1 := ReadFP4(chn);
    end else if chn = 'TRAN' then begin
      tran1 := ReadIP2(chn);
    end else if chn = 'VTRN' then begin
      tran1 := ReadFP4(chn);
    end else if chn = 'GLOS' then begin
      glos1 := ReadIP2(chn)/4;
    end else begin
      inc(FilePos,chl);
      seek(f,FilePos);
    end;
  until FilePos >= l + fp;
{���������� ������ - ��������� ������ ������� � �������}
  if c[3] > -0.5 then begin
//    nt    : Namestr;    CTEX       {80 ��� ����� ��������   }
//    texp  : single;                { 4 ������� ��������}
    with Material[Imat] do begin
      ambi.r := c[0]*refl1;   ambi.g := c[1]*refl1;   ambi.b := c[2]*refl1;   ambi.a := 1.0;
      diff.r := c[0]*diff1;   diff.g := c[1]*diff1;   diff.b := c[2]*diff1;   diff.a := 1.0;
      spec.r := c[0]*spec1;   spec.g := c[1]*spec1;   spec.b := c[2]*spec1;   spec.a := 1.0;
      emis.r := c[0]*lumi1;   emis.g := c[1]*lumi1;   emis.b := c[2]*lumi1;   emis.a := 1.0;
      tran := tran1;
      shin := glos1;
    end; {with Material}
  end else begin {if color[3] > -0.5}
    if ToFile then
      writeln(t,' !!! ERROR ReadSURF - No Colors');
    if ToErrorFile then
      writeln(q,' !!! ERROR ReadSURF - No Colors');
  end; {if color[3] > -0.5}
end;


{******* ������� ��������� ������ ��������� ������� **********}
{*************************************************************}
procedure ReadLWOfile(filename:string); {������ ����� LWO}
const ChStr : string[5] = '    ';
var
  k,Count  : word;        {���������� ��� ����� � ���������� ������}
  kk       : longint;     {������� �����}
  pL       : ^TpL;        {}
  id1      : word;        {}
  len1     : longint;     {}
  tmpChunk : ChunkType;   {��� ���������� ������}
  FnameWOext : string;    {��� ����� ��� ����������}
  s : string;
begin
{������������� ���������� ����� ����������}
  Fillchar(UsedChunks,sizeof(UsedChunks),0); {������ ������, ������������� � �����}
  deb2file('ReadLWOfile *010* ',0);
  NumChunkRead := 0;
  fillchar(nmo,sizeof(nmo),0);
  nnmo := 0;
  CreateMaterial(DefMaterial);  {�������� �� ��������� �� ������ ������}
{�������� !!!�������������!!! �������}
  while pos('\',filename) > 0 do
    delete(filename,1,pos('\',filename));
  CreateObj3DS(filename);
  deb2file('ReadLWOfile *030* ',0);

{ !!!!!!!!! ��� ������� !!!!!!!!!!!!!}
///   CreateMatObj(CurObj3DS, 0, 'm.o.1'); {�������� ��������� �������}
///   CreateMatObj(CurObj3DS, 0, 'm.o.2'); {�������� ��������� �������}
///   CreateMatObj(CurObj3DS, 0, 'm.o.3'); {�������� ��������� �������}
///   CreateMatObj(CurObj3DS, 0, 'm.o.4'); {�������� ��������� �������}
///   DeleteMatObj(2);
//         writeln(t,' Read LWO file: ',FnameInput,' size: ',lf);
  s := ReadChunkName;
  if s = 'FORM' then begin
    kk := ReadChunkLen4i;
    if ToFile then
      writeln(t,s,' size: ',kk:8);
  end;
  s := ReadChunkName;
  if s = 'LWOB' then begin
    if ToFile then
      writeln(t,s);
  end;
  repeat
    s := ReadChunkName;
    kk := ReadChunkLen4i;
    if ToFile then
      writeln(t,s,' size: ',kk:8,'/',l2str(kk),' Position: ',FilePos:8,'/',l2str(FilePos));
    if s = 'PNTS' then ReadPNTS(kk)
      else if s = 'SRFS' then ReadSRFS(kk)
        else if s = 'POLS' then ReadPOLS(kk)
          else if s = 'CRVS' then ReadCRVS(kk)
            else if s = 'PCHS' then ReadPCHS(kk)
              else if s = 'SURF' then ReadSURF(kk)
                else begin
                  if ToFile then
                    writeln(t,'   *** ERROR Unknown Chunk');
                  if ToErrorFile then
                    writeln(q,'   *** ERROR Unknown Chunk: ',s,' size: ',kk:8,'/',l2str(kk),
                        ' Position: ',FilePos:8,'/',l2str(FilePos));
                  inc(FilePos,kk);
                  seek(f,FilePos);
                end;
  until FilePos >= lf;
  deb2file('ReadLWOfile *040* ',0);
  close(f);
{---�������� ������� ���������� � �������� � ������������ ��������� �� ���������, ���� ���---}
  deb2file('ReadLWOfile *070* ',0);
  if Nobj3DS > 0 then
    for kk := 0 to Nobj3DS-1 do begin
      if ToFile then
        writeln(t,'�������� ������� ���������� � �������� Nobj=',kk,' nf=',Obj3DS[kk].nf,' m0=',Obj3DS[kk].m0);
      if (Obj3DS[kk].nf > 0) and (Obj3DS[kk].m0 = -1) then begin
        Count := Obj3DS[kk].nf;
        inc(NfaceMat,Count);
        CreateMatObj(kk,longint(Count),DefMaterial);
        if ToFile then
          writeln(t,' ������������ ������� ',kk,' ��������� �� ��������� ',CurMatObj);
        with MatObj[CurMatObj] do begin
          nf := Count;
          for k := 0 to Count-1 do begin
            pf^[k] := k;
          end;
        end; {with}
      end; {if Count}
    end; {for}
{���������� � ����� � ���� ����������}
  deb2file('ReadLWOfile *080* ',0);
  if ToFile then begin
    writeln(t,'   --- Chunks ---');
    Count := 1;
    repeat   {���������� ���������� �������������� ������}
      inc(Count);
    until UsedChunks[Count].n = '';
    writeln(t);
    for k := 2 to count-1 do        {��������� ������ ������}
      for kk := count-1 downto k do
        if UsedChunks[kk].n < UsedChunks[kk-1].n then
          begin
            tmpChunk := UsedChunks[kk];
            UsedChunks[kk] := UsedChunks[kk-1];
            UsedChunks[kk-1] := tmpChunk;
          end;
    for k := 1 to count-1 do begin
      writeln(t,UsedChunks[k].n,UsedChunks[k].l:8);
//      if UsedChunks[k].b then
//        write(t,'  ? ')
//      else
//        write(t,'    ');
//      writeln(t,ChunkDesc[GetChunkIndex(UsedChunks[k].n)].s);
    end;
{}
    writeln(t,' ����.������ � ������� Mpoints=',Mpoints,' ����.������ � ������� Mfaces=',Mfaces);
  end;
  deb2file('ReadLWOfile *090* ',0);
  deb2file('ReadLWOfile, MFaces:',Mfaces);
  deb2file('ReadLWOfile, MPoints:',Mpoints);
end;

end.