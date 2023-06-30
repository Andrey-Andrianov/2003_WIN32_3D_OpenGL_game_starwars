unit enems;
interface

type
  enem = record
    vid   : longint;
    t     : longint;
    heard : longint;
    time  : longint;
    time_lighting  : longint;
    leven : longint;
    vidim : boolean;
    x : single;
    y : single;
    z : single;
    v : single;
    angle : single;
    angle_y : single;
    faza_texture_babax : longint;
  end;

const
  kol_monstrs : longint = 1{30};

var
  monstr : array[1..200] of enem;
  mysors : array[1..30] of enem;
  asteroids : array[1..30] of enem;

implementation

var
  i,j : longint;

begin
  monstr[1].x := 0; monstr[1].y := 0.8; monstr[1].z := 0; monstr[1].v := 0.12;monstr[1].vid := 8; monstr[1].heard:=10; monstr[1].leven:=1; monstr[1].angle:=30; monstr[1].angle_y:=30; monstr[1].t:=1;
{  monstr[2].x := -9; monstr[2].y := 0.8; monstr[2].z := 1; monstr[2].v := 0.12;monstr[2].vid := 2; monstr[2].heard:=10; monstr[2].leven:=1; monstr[2].angle:=30; monstr[2].angle_y:=0; monstr[2].t:=1;
  monstr[3].x := -3; monstr[3].y := 0.8; monstr[3].z := 1; monstr[3].v := 0.12; monstr[3].vid := 3; monstr[3].heard:=10; monstr[3].leven:=1; monstr[3].angle:=30; monstr[3].angle_y:=0; monstr[3].t:=1;
  monstr[4].x := 1600; monstr[4].y := 1; monstr[4].z := 450; monstr[4].v := 0.12; monstr[4].vid := 3; monstr[4].heard:=10; monstr[4].leven:=1; monstr[4].angle:=30; monstr[4].angle_y:=0; monstr[4].t:=1;
  monstr[5].x := -1100; monstr[5].y := 1; monstr[5].z := -460; monstr[5].v := 0.12; monstr[5].vid := 2; monstr[5].heard:=10; monstr[5].leven:=1; monstr[5].angle:=30; monstr[5].angle_y:=0; monstr[5].t:=1;
  monstr[6].x := -500; monstr[6].y := 1; monstr[6].z := 1500; monstr[6].v := 0.12; monstr[6].vid := 1; monstr[6].heard:=10; monstr[6].leven:=1; monstr[6].angle:=30; monstr[6].angle_y:=0; monstr[6].t:=1;}

//  for i := 1 to kol_monstrs do begin
//    monstr[i].x := -3+random(50); monstr[i].y := 0.8; monstr[i].z := 1+random(50); monstr[i].v := 0.12; monstr[i].vid := 3; monstr[i].heard:=10; monstr[i].leven:=1; monstr[i].angle:=30; monstr[i].angle_y:=0;
//  end;

  for i := 1 to kol_monstrs do begin
    monstr[i].time := 0;
    monstr[i].vidim := false;
  end;
end.