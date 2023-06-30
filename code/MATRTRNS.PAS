unit MatrTrns; {матричные преобразования}
{ все функции вращения являются отложенными до вызова MT_CalcCurrent }
{ все функции кроме вращения снимают (или выполняют-по обстановке) отложенные действия}
interface
uses comm_3d, matrx_wd;

type MyFloat = double; {текущий тип данных}

function  MT_GetMatrix : MatriXtype;       // возвращает текущую матрицу
procedure MT_SetMatrix(m : MatriXtype);    // устанавливает текущую матрицу
procedure MT_ResetMatrix;                  // приводит текущую к единичной
procedure MT_PushMatrix;                   // заталкивает текущую в стек (глубина 16)
procedure MT_PopMatrix;                    // извлекает из стека в текущую
procedure MT_CalcCurrent;                  // выполняет отложенные преобразования текущей
procedure MT_RotArndCentX(dAX:MyFloat);    // отлож.вращ.вокруг центра по X (вверх/вниз)
procedure MT_RotArndCentY(dAY:MyFloat);    // отлож.вращ.вокруг центра по Y (влево/вправо)
procedure MT_RotArndCentZ(dAZ:MyFloat);    // отлож.вращ.вокруг центра по Z (по/против часовой)
procedure MT_RotArndViewX(dA0X:MyFloat);   // отлож.вращ.вокруг камеры по X (вверх/вниз)
procedure MT_RotArndViewY(dA0Y:MyFloat);   // отлож.вращ.вокруг камеры по Y (влево/вправо)
procedure MT_MoveCenterC(dx,dy,dz:MyFloat);// перемещение центра вращения
procedure MT_MoveCenterV(v:TdoubleVector); //      -"-
procedure MT_PrintMatrix(s:string);        // вывод на печать текущей матрицы преобразования

implementation

const
  MT_Debug = TRUE;      // отладочная печать

  RotX  : boolean = FALSE;    //   индикаторы,
  RotY  : boolean = FALSE;    //  показывающие
  RotZ  : boolean = FALSE;    // необходимость
  Rot0X : boolean = FALSE;    //  отложенного
  Rot0Y : boolean = FALSE;    //  перемещения
  dA_X  : MyFloat = 0.0;  //
  dA_Y  : MyFloat = 0.0;  // отложенные
  dA_Z  : MyFloat = 0.0;  // перемещения
  dA_0X : MyFloat = 0.0;  //
  dA_0Y : MyFloat = 0.0;  //

  vX1     : TDoubleVector = (x:1; y:0; z:0);                        // ед.вектора
  vY1     : TDoubleVector = (x:0; y:1; z:0);                        //
  vZ1     : TDoubleVector = (x:0; y:0; z:1);
  BegMatr : MatriXtype = ((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1)); // ед.матрица

  StackSize = 16;                    // максимальная глубина стека матриц
  StackDep : longint = 0;            // текущая глубина стека матриц
var
  MainMatr : MatriXtype;             // основная матрица преобразования
  stack : array[0..15]of MatriXtype; // стек матриц

function MT_GetMatrix : MatriXtype;       // возвращает текущую матрицу
begin
  if RotX or RotY or RotZ or Rot0X or Rot0Y then
    MT_CalcCurrent;
  MT_GetMatrix := MainMatr;
//  if MT_Debug then
//    MT_PrintMatrix('MT_GetMatrix');
end;

procedure MT_SetMatrix(m : MatriXtype);    // устанавливает текущую матрицу
begin
  MainMatr := m;
  if MT_Debug then
    MT_PrintMatrix('MT_SetMatrix');
  RotX := FALSE;   RotY := FALSE;   RotZ := FALSE;   Rot0X := FALSE;   Rot0Y := FALSE;
  dA_X := 0.0;     dA_Y := 0.0;     dA_Z := 0.0;     dA_0X := 0.0;       dA_0Y := 0.0;
end;

procedure MT_ResetMatrix;                  // приводит текущую к единичной
begin
  MainMatr := BegMatr;
//  if MT_Debug then
//    MT_PrintMatrix('MT_ResetMatrix');
  RotX := FALSE;   RotY := FALSE;   RotZ := FALSE;   Rot0X := FALSE;   Rot0Y := FALSE;
  dA_X := 0.0;     dA_Y := 0.0;     dA_Z := 0.0;     dA_0X := 0.0;       dA_0Y := 0.0;
end;

procedure MT_PushMatrix;                   // заталкивает текущую в стек (глубина 16)
begin
  if RotX or RotY or RotZ or Rot0X or Rot0Y then
    MT_CalcCurrent;
  if StackDep < StackSize then begin
    Stack[StackDep] := MainMatr;
    inc(StackDep);
  end else begin
    if MT_Debug then
      if ToFile then
        writeln(t,'   !!! ERROR MatrTrns: Stack Overflow');
    if ToErrorFile then
      writeln(q,'   !!! ERROR MatrTrns: Stack Overflow');
  end;
  if MT_Debug then
    MT_PrintMatrix('MT_PushMatrix');
end;

procedure MT_PopMatrix;                    // извлекает из стека в текущую
begin
  if StackDep > 0 then begin
    inc(StackDep);
    MainMatr := Stack[StackDep];
  end else begin
    if MT_Debug then
      if ToFile then
        writeln(t,'   !!! ERROR MatrTrns: Stack Underflow');
    if ToErrorFile then
      writeln(q,'   !!! ERROR MatrTrns: Stack Underflow');
  end;
  if MT_Debug then
    MT_PrintMatrix('MT_PopMatrix');
  RotX := FALSE;   RotY := FALSE;   RotZ := FALSE;   Rot0X := FALSE;   Rot0Y := FALSE;
  dA_X := 0.0;     dA_Y := 0.0;     dA_Z := 0.0;     dA_0X := 0.0;       dA_0Y := 0.0;
end;

procedure MT_CalcCurrent;                  // выполняет отложенные преобразования текущей
var
  v1,v2 : TdoubleVector;
  m1    : MatrixType;
begin
  if RotX or RotY or RotZ or Rot0X or Rot0Y then begin
    v1.x := 0; v1.y := 0; v1.z := -Distance;  // готовим вектора для
    v2.x := 0; v2.y := 0; v2.z := Distance;   // "отъезда" и последующего "наезда"
{вариант в "историческом порядке" с приращениями вычисление нового перемещения}
                {m1 - новое преобразование}
    m1 := BegMatrix;                      // загрузка начальной
    if Rot0X or Rot0Y then
                          m1 := MulMatrix(m1,MoveMatr(v1));         //
    if Rot0X          then
                          m1 := MulMatrix(m1,RotMatrX(dA_0X));       // перемещение
    if Rot0Y          then
                          m1 := MulMatrix(m1,RotMatrY(dA_0Y));       // центра
    if Rot0X or Rot0Y then
                          m1 := MulMatrix(m1,MoveMatr(v2));         // вращения
    if Rot0Y          then
                          m1 := MulMatrix(m1,RotMatrY(-dA_0Y));      //
    if Rot0X          then
                          m1 := MulMatrix(m1,RotMatrX(-dA_0X));      //

    if RotZ then
                m1 := MulMatrix(m1,RotMatrZ(dA_Z));   // вращение
    if RotY then
                m1 := MulMatrix(m1,RotMatrX(dA_X));   // вокруг центра
    if RotX then
                m1 := MulMatrix(m1,RotMatrY(dA_Y));   // вращения

    MainMatr := MulMatrix(MainMatr,m1); // результирующее преобразование
  end;
  RotX := FALSE;   RotY := FALSE;   RotZ := FALSE;   Rot0X := FALSE;   Rot0Y := FALSE;
  dA_X := 0.0;     dA_Y := 0.0;     dA_Z := 0.0;     dA_0X := 0.0;       dA_0Y := 0.0;
end;

procedure MT_RotArndCentX(dAX:MyFloat);    // отлож.вращ.вокруг центра по X (вверх/вниз)
begin
  dA_X := dA_X + dAX;
  RotX := TRUE;
end;

procedure MT_RotArndCentY(dAY:MyFloat);    // отлож.вращ.вокруг центра по Y (влево/вправо)
begin
  dA_Y := dA_Y + dAY;
  RotY := TRUE;
end;

procedure MT_RotArndCentZ(dAZ:MyFloat);    // отлож.вращ.вокруг центра по Z (по/против часовой)
begin
  dA_Z := dA_Z + dAZ;
  RotZ := TRUE;
end;

procedure MT_RotArndViewX(dA0X:MyFloat);   // отлож.вращ.вокруг камеры по X (вверх/вниз)
begin
  dA_0X := dA_0X + dA0X;
  Rot0X := TRUE;
end;

procedure MT_RotArndViewY(dA0Y:MyFloat);   // отлож.вращ.вокруг камеры по Y (влево/вправо)
begin
  dA_0Y := dA_0Y + dA0Y;
  Rot0Y := TRUE;
end;

procedure MT_MoveCenterC(dx,dy,dz:MyFloat);// перемещение центра вращения
var
  v : TdoubleVector;
begin
  if RotX or RotY or RotZ or Rot0X or Rot0Y then
    MT_CalcCurrent;
  v.x := dx; v.y := dy; v.z := dz;
  if MT_Debug then
    if ToFile then
      writeln(t,' MT_MoveCenterC dx=',v.x:12:6,' dy=',v.y:12:4,' dz=',v.z:12:4);
  MainMatr := MulMatrix(MainMatr,MoveMatr(v));
  if MT_Debug then begin
    if ToFile then
      writeln(t,'  MT_MoveCenterC:  x= ',v.x:7:3,'  y= ',v.y:7:3,'  z= ',v.z:7:3);
                 MT_PrintMatrix('MT_MoveCenterC');
  end;
end;

procedure MT_MoveCenterV(v:TdoubleVector); //      -"-
begin
  if RotX or RotY or RotZ or Rot0X or Rot0Y then
    MT_CalcCurrent;
  MainMatr := MulMatrix(MainMatr,MoveMatr(v));
  if MT_Debug then begin
    if ToFile then
      writeln(t,'  MT_MoveCenterV:  x= ',v.x:7:3,'  y= ',v.y:7:3,'  z= ',v.z:7:3);
    MT_PrintMatrix('MT_MoveCenterV');
  end;
end;

procedure MT_PrintMatrix(s:string); // вывод на печать текущей матрицы преобразования
var v : TDoubleVector;
begin
  v := MatrVect(MainMatr, vz1);
  if MT_Debug then begin
    if ToFile then begin
      writeln(t,'============= MT_PrintMatrix '+s+' =============');
      writeln(t,'  Stack : ',StackDep);
      writeln(t,'  View Vector: x= ',v.x:7:3,'  y= ',v.y:7:3,'  z= ',v.z:7:3);
      writeln(t,MainMatr[0,0]:7:3,' ',MainMatr[0,1]:7:3,' ',MainMatr[0,2]:7:3,' ',MainMatr[0,3]:7:3);
      writeln(t,MainMatr[1,0]:7:3,' ',MainMatr[1,1]:7:3,' ',MainMatr[1,2]:7:3,' ',MainMatr[1,3]:7:3);
      writeln(t,MainMatr[2,0]:7:3,' ',MainMatr[2,1]:7:3,' ',MainMatr[2,2]:7:3,' ',MainMatr[2,3]:7:3);
      writeln(t,MainMatr[3,0]:7:3,' ',MainMatr[3,1]:7:3,' ',MainMatr[3,2]:7:3,' ',MainMatr[3,3]:7:3);
      writeln(t,'================================================================');
    end;
  end;
end;

begin
  MainMatr := BegMatr;   // основная матрица преобразования
end.