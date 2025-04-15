#include "report.ch"
#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

//********************************************************************
// Proposito: Generar los reportes de cuentas corrientes de clientes
// .prg     : lisfac.prg
// Autor    : Cesar Gomez CM Soft
MEMVAR oApp
***********************************
** Cuenta corriente de cliente
PROCEDURE RepCre1()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      cTodos := "Todos los clientes          ", mnomcli := SPACE(30), mdesde := CTOD("01/01/2010"), mhasta := DATE(),;
      mcodcli := 0, mTotal := 0, lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"}, lConArt := .f.
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre, direccion FROM ge_"+oApp:cId+"clientes ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Cuentas corrientes" FROM 03,15 TO 14,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodcli OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(Buscar(oQryCli,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 50, 65 CHECKBOX oGet[5] VAR lConArt PROMPT "Muestrar Articulos"   OF oDlg1 PIXEL 
  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
lTipo:= IF(nTipo=1,.f.,.t.)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-9
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-9 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT fecha, CONCAT('REC ',LPAD(CAST(numero AS CHAR),8,'0')) AS compro,"+;
                            " 0 AS debe, total AS haber, interes as interes, ' ' as det"+;                          
                            " FROM ge_"+oApp:cId+"pagos "+;                          
                            " WHERE fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                            "       fecha <= " + ClipValue2Sql(mhasta) + " AND "+;
                            "       cliente = " + ClipValue2Sql(mcodcli) + " AND total <> 0 "+;
                            " UNION "+;   
                           "SELECT v.fecha, CONCAT(v.ticomp,v.letra,v.numcomp) AS compro,"+;
                           " v.importe*IF(v.ticomp='NC' OR v.ticomp='DE',-1,1) AS debe, 0 AS haber, 0 as interes,"+;
                           "d.det AS det "+;
                           " FROM ge_"+oApp:cId+"ventas_encab v"+;
                           " LEFT JOIN (SELECT GROUP_CONCAT(detart,' ',cantidad) AS det, NROFAC "+;
                           " FROM ge_"+oApp:cId+"ventas_det GROUP BY NROFAC) d "+;
                           " ON CONCAT(v.ticomp,v.letra,v.numcomp) = d.nrofac "+;                         
                           " WHERE fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                           "       fecha <= " + ClipValue2Sql(mhasta) + " AND "+;
                           "       codcli = " + ClipValue2Sql(mcodcli) +;
                           " UNION "+;
                           " SELECT " + ClipValue2Sql(mdesde-1) + " AS fecha, "+;
                           " 'Saldo Anterior' AS compro, "+;
                           "(SELECT SUM(importe*IF(ticomp='NC' OR ticomp='DE',-1,1)) "+;
                             "FROM ge_"+oApp:cId+"ventas_encab WHERE fecha < "+ClipValue2Sql(mdesde)+;
                                   " AND codcli = "+ClipValue2Sql(mcodcli)+") AS debe, "+;
                           "(SELECT SUM(total) "+;
                             "FROM ge_"+oApp:cId+"pagos WHERE fecha < "+ClipValue2Sql(mdesde)+;
                                   " AND cliente = "+ClipValue2Sql(mcodcli)+") AS haber ,"+;
                           "(SELECT SUM(interes) "+;
                             "FROM ge_"+oApp:cId+"pagos WHERE fecha < "+ClipValue2Sql(mdesde)+;
                                   " AND cliente = "+ClipValue2Sql(mcodcli)+") AS interes, ' ' as det "+;
                           " ORDER BY fecha ")
REPORT oRep TITLE "Cuenta corriente de (" + STR(mcodcli,6)+") "+  ALLTRIM(mNomCli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp)  , ;
       "Cuenta corrientes cliente" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Cuenta corrientes cliente"

COLUMN TITLE "Comprobante" DATA oQry:compro    SIZE IF(lConArt,15,35) FONT 1
COLUMN TITLE "Fecha"       DATA FechaSql(oQry:fecha)     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Debe"        DATA oQry:debe      PICTURE "99999999999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Haber"       DATA oQry:haber PICTURE "99999999999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Interes"     DATA oQry:interes PICTURE "99999999999.99" ;
                           SIZE 10 FONT 2 
COLUMN TITLE "Saldo"       DATA mtotal PICTURE "99999999999.99" ;
                           SIZE 10 FONT 2 
IF lConArt
   COLUMN TITLE "Productos"       DATA STRTRAN(oQry:det,","," - ") SIZE 35 FONT 1 MEMO
ENDIF                           

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop(), mtotal := oQry:debe - oQry:haber }
oRep:bSkip := {|| oQry:Skip(), mtotal := mtotal + oQry:debe + oQry:interes - oQry:haber }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)         

oQry:End()
RETURN 

***********************************
** Resumen de deudas
PROCEDURE Repcre2()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(10), oBot1, oBot2, oQryVen,;
      cTodos := "Todos                   ", mnomven := SPACE(30), mdesde := CTOD("01/01/2020"), mhasta := DATE(),;
      lDeta := .f.,mvendedor := 0,lTipo:=.f.,;
      oQryCli, mcliente := 0, mnomcli := SPACE(30), lDeta1 := .f.
oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")   
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Resumen de Deudas a cobrar" FROM 03,15 TO 18,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Cliente (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))
   @ 50, 65 GET oGet[7] VAR mcliente OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[7]:value = 0 .or. Buscar(oQryCli,oDlg1,oGet[7],oGet[8]));
                ACTION (oGet[7]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[7],oGet[8])) BITMAP "BUSC1" 
   @ 50,100 GET oGet[8] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[8]:cText := IF(mcliente=0,cTodos,oQryCli:nombre)) = SPACE(30))
   @ 65, 05 CHECKBOX oGet[6] VAR lDeta PROMPT "Emitir detalle" OF oDlg1 PIXEL SIZE 80,12
   @ 80, 05 CHECKBOX oGet[10] VAR lDeta1 PROMPT "Solo Origen/Saldo" OF oDlg1 PIXEL SIZE 80,12 WHEN(lDeta)
   @ 65,105 CHECKBOX oGet[9] VAR lTipo PROMPT "Solo Imputables" OF oDlg1 PIXEL SIZE 80,12 

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC   

IF !lDeta
oQry := oApp:oServer:Query("SELECT * FROM ("+;
                           "SELECT v.cliente AS codcli, c.nombre AS nombre, c.direccion AS direccion, "+;
                           " c.telefono AS telefono, "+;
                           "c.saldo AS acuenta, SUM(v.saldo*IF(v.tipo='NC',-1,1)) AS importe "+;
                           " FROM ge_"+oApp:cId+"ventas_cuota v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.cliente = c.codigo "+;
                           " WHERE v.saldo > 0 AND v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                           " v.fecha <= "+ ClipValue2Sql(mhasta) +;
                           " AND " + IF(mvendedor=0,"TRUE ","c.vendedor = "+ClipValue2Sql(mvendedor))+" "+;
                           " AND " + IF(mcliente=0,"TRUE ","v.cliente = "+ClipValue2Sql(mcliente))+" "+;
                           " AND " + IF(!lTipo,"TRUE ","v.letra <> 'X' ")+" "+;
                           " GROUP BY v.cliente "+;
                           "UNION "+;
                           "SELECT codigo as codcli, nombre as nombre, direccion as direccion, "+;
                           "telefono as telefono,0, "+;
                           "0 as importe "+;
                           "FROM ge_"+oApp:cId+"clientes WHERE TRUE AND " + IF(mvendedor=0,"TRUE ","vendedor = "+ClipValue2Sql(mvendedor))+" "+;
                           " AND " + IF(mcliente=0,"TRUE ","codigo = "+ClipValue2Sql(mcliente))+" "+;
                           " AND codigo NOT IN ( SELECT cliente FROM ge_"+oApp:cId+"ventas_cuota WHERE saldo > 0 "+;
                                " AND fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                                " fecha <= "+ ClipValue2Sql(mhasta) +;
                                ")"+;
                           ") res WHERE res.importe <>0 ORDER BY res.nombre " )
REPORT oRep TITLE "Resumen de deudas a cobrar " +;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Resumen de deudas a cobrar "+"- Vendedor:" + mnomven CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen de deudas"
*GROUP ON oQry:vendedor HEADER "Vendedor:"+ oQry:Vendedor FOOTER "Total Vendedor" FONT 3

COLUMN TITLE "Codigo"    DATA oQry:codcli     SIZE 06 FONT 1
COLUMN TITLE "Cliente"   DATA oQry:nombre     SIZE 25 FONT 1
COLUMN TITLE "Direccion" DATA oQry:direccion  SIZE 20 FONT 1
COLUMN TITLE "Telefonos" DATA oQry:telefono   SIZE 15 FONT 1
COLUMN TITLE "A cuenta"  DATA oQry:acuenta    PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Deuda"     DATA oQry:importe    PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL


// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
oQry:End()
ELSE
  IF !lDeta1
    oQry := oApp:oServer:Query("SELECT * FROM ("+;
    	                     "SELECT v.cliente AS codcli, c.nombre AS nombre, c.direccion AS direccion, "+;
                             " c.telefono AS telefono, CONCAT(v.tipo,v.letra,v.numero,' ',v.cuota) AS compro, "+;
                             " v.saldo*IF(v.tipo='NC',-1,1) AS saldo,"+;
                             " v.fecha AS fecha " +;
                             " FROM ge_"+oApp:cId+"ventas_cuota v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.cliente = c.codigo "+;
                             " WHERE v.saldo <> 0 "+;
                             " AND "+IF(mvendedor=0,"TRUE","c.vendedor = "+ClipValue2Sql(mvendedor))+;
                             " AND " + IF(mcliente=0,"TRUE ","v.cliente = "+ClipValue2Sql(mcliente))+" "+;
                             " AND " + IF(!lTipo,"TRUE ","v.letra <> 'X' ")+" "+;
                             " UNION " +;
                             "SELECT codigo AS codcli, nombre, direccion, "+;
                             " telefono, 'Anticipo' AS compro, "+;
                             "saldo*(-1)," +;
                             " CURDATE()  AS fecha " +;
                             " FROM ge_"+oApp:cId+"clientes  "+;
                             " WHERE TRUE "+;
                             " AND "+IF(mvendedor=0,"TRUE","vendedor = "+ClipValue2Sql(mvendedor))+;
                             " AND " + IF(mcliente=0,"TRUE ","codigo = "+ClipValue2Sql(mcliente))+" "+;
                             ") res WHERE res.saldo <>0 ORDER BY res.nombre,res.fecha " )
    REPORT oRep TITLE "Detalle de deudas a cobrar " + ALLTRIM(mnomven) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp)  , ;
           "Detalle de deudas a cobrar " CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Detalle de deudas"       
    GROUP ON oQry:codcli HEADER "Cliente: ("+ STR(oQry:codcli) + ") " + ALLTRIM(oQry:nombre)+;
           " - " + ALLTRIM(oQry:direccion) + " - " + ALLTRIM(oQry:telefono);
          FOOTER "Total Cliente" FONT 3

    COLUMN TITLE "Comprobante"  DATA oQry:compro     SIZE 14 FONT 1
    COLUMN TITLE "Fecha"        DATA FechaSql(oQry:fecha)       PICTURE "@D" SIZE 09 FONT 1
    COLUMN TITLE "+60 dias"     DATA IF(oQry:compro <> "Anticipo"  .AND. DATE()-oQry:fecha>60,oQry:saldo,0)  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "30/60 dias"   DATA IF(oQry:compro <> "Anticipo"  .AND. DATE()-oQry:fecha>30 .AND. DATE()-oQry:fecha<=60 ,oQry:saldo,0)  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "30 dias"      DATA IF(oQry:compro <> "Anticipo"  .AND. DATE()-oQry:fecha>00 .AND. DATE()-oQry:fecha<=30 ,oQry:saldo,0)  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "A Vencer"     DATA IF(oQry:compro <> "Anticipo"  .AND. DATE()-oQry:fecha<=00 ,oQry:saldo,0)  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "Sin aplicar"  DATA IF(oQry:compro = "Anticipo"  ,oQry:saldo,0)  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "Total"        DATA oQry:saldo  ;
                 SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL

    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
             ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
             ON POSTGROUP oRep:NewLine()
    oQry:End()
    ELSE
    //Detalle Simple
    oQry := oApp:oServer:Query(""+;
                           "SELECT v.cliente AS codcli, c.nombre AS nombre, c.direccion AS direccion, "+;
                             " c.telefono AS telefono, CONCAT(v.tipo,v.letra,v.numero,' ',v.cuota) AS compro, "+;
                             " v.importe*IF(v.tipo='NC',-1,1) AS origen,"+;
                             " v.saldo*IF(v.tipo='NC',-1,1) AS saldo,"+;
                             " v.fecha AS fecha " +;
                             " FROM ge_"+oApp:cId+"ventas_cuota v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.cliente = c.codigo "+;
                             " WHERE v.saldo <> 0 "+;
                             " AND "+IF(mvendedor=0,"TRUE","c.vendedor = "+ClipValue2Sql(mvendedor))+;
                             " AND " + IF(mcliente=0,"TRUE ","v.cliente = "+ClipValue2Sql(mcliente))+" "+;
                             " AND " + IF(!lTipo,"TRUE ","v.letra <> 'X' ")+" ORDER BY v.nombre, v.fecha")
    REPORT oRep TITLE "Detalle de deudas a cobrar " + ALLTRIM(mnomven) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp)  , ;
           "Detalle de deudas a cobrar " CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Detalle de deudas"       
    GROUP ON oQry:codcli HEADER "Cliente: ("+ STR(oQry:codcli) + ") " + ALLTRIM(oQry:nombre)+;
           " - " + ALLTRIM(oQry:direccion) + " - " + ALLTRIM(oQry:telefono);
          FOOTER "Total Cliente" FONT 3

    COLUMN TITLE "Comprobante"  DATA oQry:compro     SIZE 14 FONT 1
    COLUMN TITLE "Fecha"        DATA FechaSql(oQry:fecha)       PICTURE "@D" SIZE 09 FONT 1
    COLUMN TITLE "Imp.Origen"   DATA oQry:origen SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "Aplicado"     DATA oQry:origen-oQry:saldo SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    COLUMN TITLE "Saldo Actual" DATA oQry:saldo  SIZE 10 PICTURE "9,999,999,999.99"  FONT 1 TOTAL
    
    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
             ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
             ON POSTGROUP oRep:NewLine()
    oQry:End()
  ENDIF
ENDIF
RETURN 



/************************************
** Listados de cobranzas
PROCEDURE RepCre3()
LOCAL oRep, oFont, oFont1, oFont2, oFont3, acor, oGru,;
      oDlg1, oGet1, oGet2, oGet3, oGet4, oGet5, oGet6,oGet7,;
      oBot1, oBot2, mrta := .f., oQry, oChe, lReim := .f., nRecibo := 0,;
      mcodcli := 0, mnomcli := SPACE(30), mdesde := DATE(), ;
      mhasta := DATE(), lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"},;
      cUsua:= oApp:usuario,aUsua:={},;
      cTodos:= "TODOS LOS CLIENTES"+SPACE(32),;
      oQryUsu:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"usuarios"),;
      lAdmin:= oApp:oServer:Query("SELECT IF(tipo='ADMIN',TRUE,FALSE) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin
oQryUsu:GoTop()
AADD(aUsua,"TODOS")
DO WHILE !oQryUsu:Eof()
   AADD(aUsua,oQryUsu:usuario)
   oQryUsu:Skip()
ENDDO
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
// Pongo el cursor con el reloj
oQry := oApp:oServer:Query( "SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
DEFINE DIALOG oDlg1 TITLE "Reporte de Cobranzas" FROM 03,15 TO 14,70 ;
       OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 07, 05 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 50,12 RIGHT
   
   @ 05, 60 GET oGet3 VAR mdesde  OF oDlg1 PIXEL WHEN(!lReim)
   @ 20, 60 GET oGet4 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde) WHEN(!lReim)
   @ 35, 60 GET oGet5 VAR mcodcli OF oDlg1 PIXEL PICTURE "99999" ;
            VALID(mcodcli=0 .or. Buscar(oQry,oDlg1, oGet5,oGet1)) RIGHT WHEN(!lReim);
            SIZE 30,12 ; 
            ACTION (oGet5:cText:= 0, Buscar(oQry,oDlg1,oGet5,oGet1)) BITMAP "BUSC1"
   @ 35, 95 GET oGet1 VAR mnomcli OF oDlg1 PIXEL PICTURE "@!";
            WHEN((oGet1:cText := IF(mcodcli=0,cTodos,oQry:nombre)) = SPACE(50))

   @ 20,140 COMBOBOX oGet7 VAR cUsua OF oDlg1 PIXEL ITEMS aUsua SIZE 60,12 WHEN(lAdmin=1)
   @ 50, 95 CHECKBOX oChe VAR lReim PROMPT "Reimprime Rec Nro" OF oDlg1 PIXEL SIZE 60,10 
   @ 50, 60 GET oGet6 VAR nRecibo OF oDlg1 PIXEL PICTURE "99999999" RIGHT WHEN(lReim)
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT (oGet3:SetFocus())
oQry:End()
oQry := nil
IF !mrta
   RETURN
ENDIF
IF lReim 
   Reci(nRecibo,.f.)
   RETURN
ENDIF   
lTipo:= IF(nTipo=1,.f.,.t.)
// Defino el reporte
oQry := oApp:oServer:Query( "SELECT p.cliente,p.numero,p.fecha, p.total,p.facturas, c.nombre , res.efec, res.tarj, res.cheq, res.anti,res.reten "+;
                            "FROM ge_"+oApp:cId+"pagos p "+;
                            "LEFT JOIN "+;
                            "(SELECT res.numero,SUM(res.efec) AS efec,SUM(tarj) AS tarj,SUM(cheq) AS cheq,"+;
                             "SUM(anti) AS anti, SUM(reten) AS reten FROM( "+;
                            "SELECT numero,SUM(importe) AS efec,0 AS tarj,0 AS cheq,0 AS anti,0 AS reten FROM ge_"+oApp:cId+"pagcon WHERE codcon = 1 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,SUM(importe) AS tarj,0 AS cheq,0 AS anti,0 AS reten FROM ge_"+oApp:cId+"pagcon WHERE codcon = 2 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,SUM(importe) AS cheq,0 AS anti,0 AS reten FROM ge_"+oApp:cId+"pagcon WHERE codcon = 3 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,0 AS anti,SUM(importe) AS reten FROM ge_"+oApp:cId+"pagcon WHERE codcon = 5 OR codcon = 6 OR codcon = 8 OR codcon = 9 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,SUM(importe) AS anti,0 AS reten FROM ge_"+oApp:cId+"pagcon WHERE codcon = 7 GROUP BY numero "+;
                            ") res GROUP BY res.numero ) "  +;
                            "res ON p.NUMERO = res.NUMERO "+;
                            "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.CODIGO = p.cliente "+;
                            "WHERE (p.fecha >= "+ClipValue2Sql(mdesde)+") and "+;
                            "(p.fecha <= "+ClipValue2Sql(mhasta)+") "+;  
                            IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua)) +;
                            IF(mcodcli > 0, " AND p.cliente = " + ClipValue2Sql(mcodcli),"") + " " + ;
                            "ORDER BY p.fecha,p.numero")
REPORT oRep TITLE "Cobranzas del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Cobranzas" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Cobranzas"
COLUMN TITLE "Nro.Rec."          DATA oQry:numero  SIZE 10 FONT 1
COLUMN TITLE "Fecha"            DATA oQry:fecha    PICTURE "@D" SIZE 10 FONT 1
COLUMN TITLE "Codigo"           DATA oQry:cliente SIZE 06 FONT 1
COLUMN TITLE "Cliente"          DATA oQry:nombre  SIZE 20 FONT 1
COLUMN TITLE "Efectivo"         DATA oQry:efec   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Interdepositos"   DATA oQry:tarj   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Cheques"          DATA oQry:cheq   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Retenciones"      DATA oQry:reten  PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Anticipos"        DATA oQry:anti   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Importe"          DATA oQry:total  PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Anticipo Gen."    DATA IF(oQry:total-oQry:facturas>0,oQry:total-oQry:facturas,0);
                                PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
// Digo que el titulo lo escriba con al letra 2
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
          ON STARTPAGE oRep:SayBitMap(.1,.1,"LOGO.JPG",1.5,.5)
// Cierro los archivos
oQry:End()
oQry := nil
RETURN*/

***********************************
** Listados de cobranzas
PROCEDURE RepCre3()
LOCAL oRep, oFont, oFont1, oFont2, oFont3, acor, oGru,;
      oDlg1, oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oRet,;
      oBot1, oBot2, mrta := .f., oQry, oChe, lReim := .f., nRecibo := 0,;
      mcodcli := 0, mnomcli := SPACE(30), mdesde := DATE(), ;
      mhasta := DATE(), lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"},;
      cUsua:= oApp:usuario,aUsua:={},lRetenciones:=.f.,;
      cTodos:= "TODOS LOS CLIENTES"+SPACE(32), nCierre := 0, lPorTurno := .f.,;
      oQryUsu:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"usuarios"),;
      lAdmin:= oApp:oServer:Query("SELECT IF(tipo='ADMIN',TRUE,FALSE) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin
oQryUsu:GoTop()
AADD(aUsua,"TODOS")
DO WHILE !oQryUsu:Eof()
   AADD(aUsua,oQryUsu:usuario)
   oQryUsu:Skip()
ENDDO
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
// Pongo el cursor con el reloj
oQry := oApp:oServer:Query( "SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
DEFINE DIALOG oDlg1 TITLE "Reporte de Cobranzas" FROM 03,15 TO 16,70 ;
       OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)
   
   @ 07, 05 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 50,12 RIGHT
   
   @ 05, 60 GET oGet3 VAR mdesde  OF oDlg1 PIXEL WHEN(!lReim)
   @ 20, 60 GET oGet4 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde) WHEN(!lReim)
   @ 35, 60 GET oGet5 VAR mcodcli OF oDlg1 PIXEL PICTURE "99999" ;
            VALID(mcodcli=0 .or. Buscar(oQry,oDlg1, oGet5,oGet1)) RIGHT WHEN(!lReim);
            SIZE 30,12 ; 
            ACTION (oGet5:cText:= 0, Buscar(oQry,oDlg1,oGet5,oGet1)) BITMAP "BUSC1"
   @ 35, 95 GET oGet1 VAR mnomcli OF oDlg1 PIXEL PICTURE "@!";
            WHEN((oGet1:cText := IF(mcodcli=0,cTodos,oQry:nombre)) = SPACE(50))

   @ 20,140 COMBOBOX oGet7 VAR cUsua OF oDlg1 PIXEL ITEMS aUsua SIZE 60,12 WHEN(lAdmin=1)
   @ 50, 95 CHECKBOX oChe VAR lReim PROMPT "Reimprime Rec Nro" OF oDlg1 PIXEL SIZE 60,10 WHEN(!lRetenciones)
   @ 50, 60 GET oGet6 VAR nRecibo OF oDlg1 PIXEL PICTURE "99999999" RIGHT WHEN(lReim .and. !lRetenciones) 
   @ 05,140 CHECKBOX oRet VAR lRetenciones PROMPT "Listado de retenciones" OF oDlg1 PIXEL SIZE 60,10 
   @ 65,105 CHECKBOX oGet2 VAR lPorTurno PROMPT "Totalizar por turnos" OF oDlg1 PIXEL SIZE 60,10
   @ 65,166 GET oGet8 VAR nCierre OF oDlg1 PIXEL PICTURE "99999" RIGHT WHEN(lPorTurno)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT (oGet3:SetFocus())
oQry:End()
oQry := nil
IF !mrta
   RETURN
ENDIF

IF lRetenciones
      // Defino el reporte
      oQry := oApp:oServer:Query( "SELECT p.numero,p.fecha,c.cuit,c.nombre AS nomcli,pc.importe,pc.observa "+;
                                  "FROM ge_"+oApp:cId+"pagos p "+;
                                  "LEFT JOIN ge_"+oApp:cId+"pagcon pc ON pc.numero = p.numero "+;
                                  "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.CODIGO = p.cliente "+;
                                  "WHERE pc.tipocon = 5 AND (p.fecha >= "+ClipValue2Sql(mdesde)+") and "+;
                                  "(p.fecha <= "+ClipValue2Sql(mhasta)+") "+;  
                                  IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua)) +;
                                  IF(mcodcli > 0, " AND p.cliente = " + ClipValue2Sql(mcodcli),"") + " " + ;
                                  "ORDER BY p.fecha,p.numero")
      REPORT oRep TITLE "Retenciones del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
             FONT  oFont1,oFont2,oFont3 ;
             HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Retenciones" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Retenciones"
      COLUMN TITLE "Nro.Rec."         DATA oQry:numero  SIZE 07 FONT 1
      COLUMN TITLE "Fecha"            DATA oQry:fecha    PICTURE "@D" SIZE 08 FONT 1
      COLUMN TITLE "C.U.I.T"           DATA oQry:cuit SIZE 10 FONT 1
      COLUMN TITLE "Cliente"          DATA oQry:nomcli  SIZE 30 FONT 1
      COLUMN TITLE "Concepto"          DATA oQry:observa  SIZE 15 FONT 1
      COLUMN TITLE "Importe"          DATA oQry:importe   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL

      // Digo que el titulo lo escriba con al letra 2
      // Digo que el titulo lo escriba con al letra 2
      oRep:oTitle:aFont[1] := {|| 2 }
      oRep:bInit := {|| oQry:GoTop() }
      oRep:bSkip := {|| oQry:Skip() }
      END REPORT
      // Activo el reporte
      ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
                ON STARTPAGE oRep:SayBitMap(.1,.1,"LOGO.JPG",1.5,.5)
      // Cierro los archivos
      oQry:End()
      oQry := nil
ELSE
      IF lReim 
         Reci(nRecibo,.f.)
         RETURN
      ENDIF   
      lTipo:= IF(nTipo=1,.f.,.t.)
      // Defino el reporte
      oQry := oApp:oServer:Query( "SELECT p.cliente,p.numero,p.fecha, p.total,p.facturas, c.nombre , res.efec, res.tarj, res.cheq, res.anti,res.transf,res.promo,res.mpago,res.reten, p.id_cierre,pf.factura "+;
                                  "FROM ge_"+oApp:cId+"pagos p "+;
                                  "LEFT JOIN "+;
                                  "(SELECT res.numero,SUM(res.efec) AS efec,SUM(tarj) AS tarj,SUM(cheq) AS cheq,"+;
                                   "SUM(anti) AS anti, SUM(transf) AS transf , SUM(promo) AS promo,SUM(mpago) AS mpago,SUM(reten) AS reten FROM( "+;
                                  "SELECT numero,SUM(importe) AS efec,0 AS tarj,0 AS cheq,0 AS anti,0 AS transf,0 AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 1 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,0 AS anti,SUM(importe) AS transf,0 AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 2 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,SUM(importe) AS cheq,0 AS anti,0 AS transf,0 AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 3 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,SUM(importe) AS tarj,0 AS cheq,0 AS anti,0 AS transf,0 AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 4 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,0 AS anti,0 AS transf,0 AS promo, 0 as mpago, SUM(importe) as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 5 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,0 AS anti,0 AS transf,SUM(importe) AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 6 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,SUM(importe) AS anti,0 AS transf,0 AS promo, 0 as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 7 GROUP BY numero "+;
                                  "UNION "+;
                                  "SELECT numero,0 AS efec,0 AS tarj,0 AS cheq,0 AS anti,0 AS transf,0 AS promo, SUM(importe) as mpago, 0 as reten FROM ge_"+oApp:cId+"pagcon WHERE tipocon = 8 GROUP BY numero "+;
                                  ") res GROUP BY res.numero ) "  +;
                                  "res ON p.NUMERO = res.NUMERO "+;
                                  "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.CODIGO = p.cliente "+;
                                  "LEFT JOIN (SELECT numero,GROUP_CONCAT(ticomp,letra,numcomp) AS factura FROM ge_"+oApp:cId+"pagfac GROUP BY numero) pf ON pf.numero = res.numero "+;
                                  "WHERE (p.fecha >= "+ClipValue2Sql(mdesde)+") and "+;
                                  "(p.fecha <= "+ClipValue2Sql(mhasta)+") "+;  
                                  IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua)) +;
                                  IF(mcodcli > 0, " AND p.cliente = " + ClipValue2Sql(mcodcli),"") + " " + ;
                                  IF(lPorTurno .and. nCierre <> 0, " AND p.id_cierre = " + ClipValue2Sql(nCierre),"") + " " + ;
                                  IF(lPorTurno,"ORDER BY p.id_cierre,p.fecha,p.numero","ORDER BY p.fecha,p.numero"))
      REPORT oRep TITLE "Cobranzas del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
             FONT  oFont1,oFont2,oFont3 ;
             HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Cobranzas" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Cobranzas"
      IF lPorTurno
         GROUP ON oQry:id_cierre HEADER "Cierre de caja N° "+ IF(oQry:id_cierre=0,"Caja Activa",STR(oQry:id_cierre));
            FOOTER "Total Cierre" FONT 3
      ENDIF  
      COLUMN TITLE "Nro.Rec."         DATA oQry:numero  SIZE 10 FONT 1
      COLUMN TITLE "Fecha"            DATA oQry:fecha    PICTURE "@D" SIZE 10 FONT 1
      COLUMN TITLE "Codigo"           DATA oQry:cliente SIZE 06 FONT 1
      COLUMN TITLE "Cliente"          DATA oQry:nombre  SIZE 20 FONT 1
      COLUMN TITLE "Efectivo"         DATA oQry:efec   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Tarj. Deb/Cre"    DATA oQry:tarj   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Cheques"          DATA oQry:cheq   PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Transferencias"   DATA oQry:transf PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "M.Pago"           DATA oQry:mpago  PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Retenciones"      DATA oQry:reten  PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Importe"          DATA oQry:total  PICTURE "99999999.99" SIZE 10 FONT 2 TOTAL
      IF !lPorTurno
         COLUMN TITLE "Cierre"         DATA oQry:id_cierre  SIZE 06 FONT 1
      ENDIF
      COLUMN TITLE "Facturas"         DATA oQry:factura  SIZE 30 FONT 1
      // Digo que el titulo lo escriba con al letra 2
      // Digo que el titulo lo escriba con al letra 2
      oRep:oTitle:aFont[1] := {|| 2 }
      oRep:bInit := {|| oQry:GoTop() }
      oRep:bSkip := {|| oQry:Skip() }
      END REPORT
      // Activo el reporte
      ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
                ON STARTPAGE oRep:SayBitMap(.1,.1,"LOGO.JPG",1.5,.5)
      // Cierro los archivos
      oQry:End()
      oQry := nil
ENDIF
RETURN


***********************************
** Reporte de comisiones
PROCEDURE Repcre4()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryVen,;
      cTodos := "Todos los vendedores            ", mnomven := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mvendedor := 0
oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Comisiones por fecha" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT v.*, ve.comision AS comi, ve.condfac, ve.condtot, vc.saldo "+;                         
                         " FROM ge_"+oApp:cId+"ventas_encab v  "+;
                         " LEFT JOIN (SELECT tipo, letra, numero, SUM(saldo) as saldo FROM ge_"+oApp:cId+"ventas_cuota GROUP BY tipo,letra,numero) vc ON vc.tipo = v.ticomp AND vc.letra = v.letra AND vc.numero = v.numcomp "+;
                         " LEFT JOIN ge_"+oApp:cId+"vendedores ve ON v.vendedor = ve.nombre "+;
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                         IF(mvendedor = 0,"TRUE"," v.vendedor = " + ClipValue2Sql(mnomven)) +;
                         " ORDER BY v.vendedor, v.nombre " )
REPORT oRep TITLE "Comisiones. Vendedor:" + ALLTRIM(mnomven)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Comisiones" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Comisiones"
IF mvendedor = 0       
   GROUP ON oQry:vendedor HEADER "Vendedor:"+ ALLTRIM(oQry:Vendedor)+" "+;
            IF(oQry:condfac=1,"(Cobrado - ","(Facturado - ")+IF(oQry:condtot=1,"Neto)" ,"Total)");
            FOOTER "Total Vendedor" FONT 3
ENDIF   

COLUMN TITLE "Comprobante" DATA oQry:ticomp+oQry:letra+oQry:numcomp    SIZE 16 FONT 1
COLUMN TITLE "Cliente"   DATA oQry:nombre    SIZE 25 FONT 1
COLUMN TITLE "Fecha"     DATA FechaSql(oQry:fecha)   PICTURE "@D"     SIZE 08 FONT 1
COLUMN TITLE "Importe"   DATA oQry:importe * IF(oQry:ticomp="NC",-1,1)  PICTURE "9999999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Neto"      DATA oQry:neto    * IF(oQry:ticomp="NC",-1,1)  PICTURE "9999999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Adeuda"    DATA oQry:saldo   * IF(oQry:ticomp="NC",-1,1)  PICTURE "9999999999.99" SIZE 10 FONT 2 TOTAL
COLUMN TITLE "%"         DATA oQry:comi      PICTURE "999.99" SIZE 05 FONT 1
COLUMN TITLE "$ Comi."   DATA Importe(oQry)*(oQry:comi/100) * IF(oQry:ticomp="NC",-1,1) PICTURE "9999999999.99" SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
oQry:End()
RETURN 

STATIC FUNCTION Importe(oQry)
LOCAL nImporte := 0
DO CASE 
   CASE oQry:condfac = 1
        nImporte := 0
        IF oQry:saldo = 0
           IF oQry:condtot = 1 
              nImporte := oQry:neto 
              ELSE 
              nImporte := oQry:importe 
           ENDIF
        ENDIF 
   CASE oQry:condfac = 2
        IF oQry:condtot = 1 
           nImporte := oQry:neto 
           ELSE 
           nImporte := oQry:importe 
        ENDIF      
ENDCASE        
RETURN nImporte

***********************************
** Resumen de caja
PROCEDURE Repcre5()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCaj,;
      cTodos := "Todos las cajas            ", mnomcaj := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mcaja := SPACE(08), mTotal := 0, lResu := .t., oQrySal
oQryCaj:= oApp:oServer:Query("SELECT usuario as codigo,nombre as nombre FROM ge_"+oApp:cId+"usuarios ORDER BY usuario")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Resumen de caja" FROM 03,15 TO 15,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Caja (Blanco:Todas):"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcaja OF oDlg1 SIZE 30,12 PIXEL RIGHT PICTURE "9999";
                VALID(mcaja = SPACE(8) .or. Buscar(oQryCaj,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= SPACE(8), Buscar(oQryCaj,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcaj PICTURE "@!"  OF oDlg1 PIXEL ;
              WHEN((oGet[4]:cText := IF(mcaja=SPACE(8),cTodos,oQryCaj:nombre)) = SPACE(30))      
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC  

//Resumen por forma de pago por caja
oQry := oApp:oServer:Query("SELECT res.caja AS caja, res.fecha as fecha, SUM(res.efectivo) as efectivo,"+;
" SUM(res.tarjeta) as tarjeta, SUM(res.cuenta) as cuenta, SUM(res.cheques) as cheques,SUM(res.vales) as vales FROM ("+;
" SELECT p.usuario AS caja, p.fecha, SUM(pc.importe) AS efectivo, 0.00 AS tarjeta, 0.00 AS cuenta, 0.00 AS cheques, 0.00 AS vales "+;
" FROM ge_"+oApp:cId+"pagos p"+;
" LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero"+;
" WHERE p.fecha >= "+ClipValue2Sql(mdesde)+"  AND p.fecha <= "+ClipValue2Sql(mhasta) +" AND pc.codcon = 1"+;
" GROUP BY p.usuario, p.fecha UNION"+;
" SELECT p.usuario AS caja, p.fecha, 0 AS efectivo, SUM(pc.importe) AS tarjeta, 0.00 AS cuenta, 0.00 AS cheques, 0.00 AS vales "+;
" FROM ge_"+oApp:cId+"pagos p"+;
" LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero"+;
" WHERE p.fecha >= "+ClipValue2Sql(mdesde)+"  AND p.fecha <= "+ClipValue2Sql(mhasta) +" AND pc.codcon = 2"+;
" GROUP BY p.usuario, p.fecha UNION"+;
" SELECT p.usuario AS caja, p.fecha, 0 AS efectivo, 0 AS tarjeta, SUM(pc.importe) AS cuenta, 0.00 AS cheques, 0.00 AS vales "+;
" FROM ge_"+oApp:cId+"pagos p"+;
" LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero"+;
" WHERE p.fecha >= "+ClipValue2Sql(mdesde)+"  AND p.fecha <= "+ClipValue2Sql(mhasta) +" AND pc.codcon = 3"+;
" GROUP BY p.usuario, p.fecha UNION"+;
" SELECT p.usuario AS caja, p.fecha, 0 AS efectivo, 0 AS tarjeta, 0.00 AS cuenta, SUM(pc.importe) AS cheques, 0.00 AS vales "+;
" FROM ge_"+oApp:cId+"pagos p"+;
" LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero"+;
" WHERE p.fecha >= "+ClipValue2Sql(mdesde)+"  AND p.fecha <= "+ClipValue2Sql(mhasta) +" AND pc.codcon = 4"+;
" GROUP BY p.usuario, p.fecha UNION"+;
" SELECT p.usuario AS caja, p.fecha, 0 AS efectivo, 0 AS tarjeta, 0.00 AS cuenta, 0.00 AS cheques, SUM(pc.importe) AS vales "+;
" FROM ge_"+oApp:cId+"pagos p"+;
" LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero"+;
" WHERE p.fecha >= "+ClipValue2Sql(mdesde)+"  AND p.fecha <= "+ClipValue2Sql(mhasta) +" AND pc.codcon >= 5 GROUP BY p.usuario, p.fecha )"+;
" res WHERE res.caja " +IF(EMPTY(mcaja)," <> 'X1' ","="+ClipValue2Sql(mcaja))+;
" GROUP BY res.caja,res.fecha ORDER BY res.caja,res.fecha")
REPORT oRep TITLE "Ingresos por caja " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta)+ " usuario:" + mnomcaj ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ingresos por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ingresos por fecha"

COLUMN TITLE "Usuario"   DATA oQry:caja     PICTURE "@!" SIZE 08 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Efectivo"  DATA oQry:efectivo PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Tarjeta"   DATA oQry:tarjeta  PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Cta.Cte."  DATA oQry:cuenta   PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Cheques"   DATA oQry:cheques  PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Otros"     DATA oQry:vales    PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Total"     DATA oQry:efectivo+oQry:tarjeta+oQry:cuenta+oQry:cheques+oQry:vales PICTURE "9,999,999,999.99" SIZE 12 FONT 1 TOTAL
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
oQry:End()
RETURN 