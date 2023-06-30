unit grtext;
interface

procedure setgrtext(color,bkcolor,typetext,size:word);
procedure GetGrText(var c2,b2,t2,s2:word); {возврвщает атрибуты текста}
procedure SETGTCOL(C1:word);
procedure SETGTBKC(B1:word);
procedure SETGTTYP(T1:word);
procedure SETGTSIZ(S1:word);
procedure puttext(x,y:word;text:string);
procedure putchar(x,y:word;chr:char);
procedure freemems;

//type
//  scrtype = array[0..199,0..319]of byte;

//var
//  scr : ^scrtype;
//  np  : ^scrtype;

implementation
uses crt,graphs2;
type
   ZngType = array[0..255,0..7]of byte;
   ZngPtr  = ^ZngType;
const
   colors : array[0..15]of word = (0,1,2,3,   4, 5,6,7,
                                   8,9,10,11,   12,13,14, 15);
var
   zng : ZngPtr;
   c,b,t,s,summa,reserv : word;

{procedure saveXXX;
var
  f : file;
begin
  assign(f,'text.dat');
  rewrite(f,1);
  blockwrite(f,zng^,sizeof(zng^));
  close(f);
end; }

procedure putpixel(x,y:integer;c:byte);
begin
//  textura_pich^[y,x,0] := 255;
  case text_out_indeficator of
    1:begin
        if c = 0 then begin
          textura_pich^[y,x,0] := 0;
          textura_pich^[y,x,1] := 0;
          textura_pich^[y,x,2] := 0;
        end else begin
          textura_pich^[y,x,0] := 255;
          textura_pich^[y,x,1] := 255;
          textura_pich^[y,x,2] := 0;
        end;
      end;
    2:begin
        if c = 0 then begin
          pribors_tex[y,x,0] := 0;
          pribors_tex[y,x,1] := 0;
          pribors_tex[y,x,2] := 0;
        end else begin
          pribors_tex[y,x,0] := 255;
          pribors_tex[y,x,1] := 255;
          pribors_tex[y,x,2] := 0;
        end;
      end;
    end;
//  textura_pich^[y,x,2] := 255;
end;

function getpixel(x,y:integer):byte;
begin
  textura_pich^[y,x,0] := c;
end;

procedure loadXXX;
var
  f : file;
begin
  assign(f,'text.dat');
  reset(f,1);
  blockread(f,zng^,sizeof(zng^));
  close(f);
end;

procedure getmems;
begin
  getmem(zng,sizeof(zng^));
end;

procedure freemems;
begin
  freemem(zng,sizeof(zng^));
end;

procedure setgrtext(color,bkcolor,typetext,size:word);
{c  color    - цвет текста, если typetext # 4, фона - при typetext = 2 }
{c  bkcolor  - цвет фона при typetext = 3, текста - при typetext = 2   }
{c  typetext - 0:or, 1:and, 2:инверсия с фоном, 3:с фоном, 4:xor       }
{c  size     - множитель >=1                                           }
begin
   c     := colors[14];
   b     := colors[bkcolor];
   t     := typetext;
   s     := size;
   SUMMA := C+B+T+S+1111;
end;

procedure GetGrText(var c2,b2,t2,s2:word); {возврвщает атрибуты текста}
begin
   c2 := c;
   b2 := b;
   t2 := t;
   s2 := s;
end;

procedure SETGTCOL(C1:word);
begin
   C     := colors[C1];
   SUMMA := C+B+T+S+1111;
end;

procedure SETGTBKC(B1:word);
begin
   B     := colors[B1];
   SUMMA := C+B+T+S+1111;
end;

procedure SETGTTYP(T1:word);
begin
   T     := T1;
   SUMMA := C+B+T+S+1111;
end;

procedure SETGTSIZ(S1:word);
begin
   S     := S1;
   SUMMA := C+B+T+S+1111;
end;

procedure puttext(x,y:word;text:string);
var
   i:word;
begin
   if(byte(text[0])>0)then
      for i := 1 to byte(text[0]) do putchar(x+s*8*(i-1),y,text[i])
end;

procedure putchar(x,y:word;chr:char);
var
   i,j,k,l : word;
   xp,yp,_getpixel : word;
begin
   l := byte(chr);
   case t of
      0:                       { OR }
         for i := 0 to 7 do
            for j := 0 to 7 do
               if (zng^[l,i] and (1 shl (7-j)) <> 0) then
                  putpixel(x+j,y+i,c);
      1:                       { AND }
         for i := 0 to 7 do
            for j := 0 to 7 do
               if (zng^[l,i] and (1 shl (7-j))) <> 0 then
                  if getpixel(x+j,y+i) = 0 then
                     putpixel(x+j,y+i,c);
      2:                       { инверсия с фоном }
         for i := 0 to 7 do
            for j := 0 to 7 do
               if (zng^[l,i] and (1 shl (7-j)) <> 0) then
                  putpixel(x+j,y+i,b)
               else putpixel(x+j,y+i,c);
      3:                       { с фоном }
         for i := 0 to 7 do
            for j := 0 to 7 do
               if (zng^[l,i] and (1 shl (7-j)) <> 0) then
                  putpixel(x+j,y+i,c)
               else putpixel(x+j,y+i,b);
      4:                       { XOR }
         for i := 0 to 7 do
            for j := 0 to 7 do
               if (zng^[l,i] and (1 shl (7-j)) <> 0) then
                  putpixel(x+j,y+i,getpixel(x+j,y+i) xor $FF);
   end;
end;

begin
{  asm
      push bp
      push ds
      mov ax,$1130
      mov bh,3
      int $10
      pop ds
      mov word ptr zng,bp
      mov word ptr zng+2,es
      pop bp
   end;     }
   getmems;
   loadxxx;
   c      := 15;
   b      :=  0;
   t      :=  3;
   s      :=  1;
   SUMMA  := c+b+t+s+1111;
   RESERV :=  0;
end.