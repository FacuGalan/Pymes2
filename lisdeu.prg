#include "report.ch"
#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

//********************************************************************
// Proposito: Generar los reportes de cuentas corrientes de clientes
// .prg     : lisdeu.prg
// Autor    : Cesar Gomez CM Soft
MEMVAR oApp
***********************************
** Cuenta corriente de proveedores
PROCEDURE RepDeu1()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryPro,;
      cTodos := "Todos los Proveedores        ", mnompro := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mcodpro := 0, mTotal := 0
oQryPro:= oApp:oServer:Query("SELECT codigo,nombre, direccion FROM ge_"+oApp:cId+"provee ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Cuentas corrientes" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Proveedor:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodpro OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(Buscar(oQryPro,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryPro,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnompro PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)                
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
oQry := oApp:oServer:Query("SELECT fecha, CONCAT('OP ',LPAD(CAST(numero AS CHAR),8,'0')) AS compro,"+;
                            " 0 AS debe, total AS haber"+;                          
                            " FROM ge_"+oApp:cId+"ordpag "+;                          
                            " WHERE fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                            "       fecha <= " + ClipValue2Sql(mhasta) + " AND "+;
                            "       proveedor = " + ClipValue2Sql(mcodpro) +;
                            " UNION "+;
                           "SELECT fecfac as fecha, CONCAT(tipocomp,letra,numfac) AS compro,"+;
                           " importe*IF(tipocomp='NC',-1,1) AS debe, 0 AS haber"+;                         
                           " FROM ge_"+oApp:cId+"compras "+;                         
                           " WHERE fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
                           "       fecfac <= " + ClipValue2Sql(mhasta) + " AND "+;
                           "       codpro = " + ClipValue2Sql(mcodpro) +;
                           " UNION "+;
                           " SELECT " + ClipValue2Sql(mdesde-1) + " AS fecha, "+;
                           " 'Saldo Anterior' AS compro, "+;
                           "(SELECT SUM(importe*IF(tipocomp='NC',-1,1)) "+;
                             "FROM ge_"+oApp:cId+"compras WHERE fecfac < "+ClipValue2Sql(mdesde)+;
                                   " AND codpro = "+ClipValue2Sql(mcodpro)+") AS debe, "+;
                           "(SELECT SUM(total) "+;
                             "FROM ge_"+oApp:cId+"ordpag WHERE fecha < "+ClipValue2Sql(mdesde)+;
                                   " AND proveedor = "+ClipValue2Sql(mcodpro)+") AS haber "+;
                           " ORDER BY fecha ")
REPORT oRep TITLE "Cuenta corriente de " + ALLTRIM(mnompro)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Cuenta corrientes proveedor" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Cuenta corrientes proveedor"

COLUMN TITLE "Comprobante" DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"       DATA oQry:fecha     SIZE 08 FONT 1
COLUMN TITLE "Debe"        DATA oQry:debe      PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Haber"       DATA oQry:haber PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Saldo"       DATA mtotal PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop(), mtotal := oQry:debe - oQry:haber }
oRep:bSkip := {|| oQry:Skip(), mtotal := mtotal + oQry:debe - oQry:haber }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)         

oQry:End()
RETURN 

***********************************
** Resumen de deudas
PROCEDURE RepDeu2()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      mdesde := CTOD("01/01/2020"), mhasta := DATE(), lDetalle := .f., oGru, lTipo := .F., lDeta1 := .f.
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Resumen de deudas a Pagar" FROM 03,15 TO 15,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 05 CHECKBOX oGet[3] VAR lDetalle PROMPT "Detallado" OF oDlg1 SIZE 70,12 PIXEL   
   @ 35, 85 CHECKBOX oGet[4] VAR lTipo    PROMPT "Solo Imputables" OF oDlg1 SIZE 70,12 PIXEL
   @ 50, 05 CHECKBOX oGet[5] VAR lDeta1   PROMPT "Solo Origen/Saldo" OF oDlg1 SIZE 70,12 PIXEL WHEN(lDetalle)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-9
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-9 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC 
IF !lDetalle
    oQry := oApp:oServer:Query("SELECT c.codpro AS codpro, p.nombre AS nombre, p.direccion AS direccion, "+;
                             " p.telefono AS telefono, "+;
                             " p.saldo AS acuenta, SUM(c.saldo*IF(c.tipocomp='NC',-1,1)) AS importe,"+;
                             " (SELECT MAX(o.fecha) FROM ge_"+oApp:cId+"ordpag o WHERE o.proveedor = p.codigo)  AS fecha  " +;                         
                             " FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"provee p ON c.codpro = p.codigo "+;                                                 
                             " WHERE c.saldo > 0 AND c.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
                             " c.fecfac <= "+ ClipValue2Sql(mhasta) +; 
                             " AND " + IF(!lTipo,"TRUE","c.imputaiva")+;
                             " GROUP BY c.codpro ORDER BY p.nombre " )
    REPORT oRep TITLE "Resumen de deudas" + " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3  HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Resumen de deudas a Pagar" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Resumen de deudas a Pagar"

    COLUMN TITLE "Codigo"    DATA oQry:codpro     SIZE 06 FONT 1
    COLUMN TITLE "Proveedor" DATA oQry:nombre     SIZE 25 FONT 1
    COLUMN TITLE "Direccion" DATA oQry:direccion  SIZE 20 FONT 1
    COLUMN TITLE "Telefonos" DATA oQry:telefono   SIZE 15 FONT 1
    COLUMN TITLE "Ult. Pago" DATA oQry:fecha      SIZE 08 FONT 1
    COLUMN TITLE "A Cuenta"  DATA oQry:acuenta    PICTURE "9,999,999,999.99" ;
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
      DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-9
      DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-9 BOLD
      oQry := oApp:oServer:Query("SELECT * FROM ("+;
                              "SELECT c.codpro AS codpro, p.nombre AS nombre, c.fecfac as fecha,  "+;
                               " c.saldo*IF(c.tipocomp='NC',-1,1) AS saldo,"+;           
                               " c.importe*IF(c.tipocomp='NC',-1,1) AS importe,"+;                             
                               " CONCAT(c.tipocomp,c.letra,c.numfac) as compro "+;
                               " FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"provee p ON c.codpro = p.codigo "+;                                                 
                               " WHERE c.saldo > 0 AND c.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
                               " c.fecfac <= "+ ClipValue2Sql(mhasta) +; 
                               " AND " + IF(!lTipo,"TRUE","c.imputaiva")+;      
                               " UNION " +;
                               "SELECT codigo AS codpro, nombre, CURDATE()  AS fecha , "+;                            
                               "saldo*(-1) as saldo," +;
                               " 0  AS importe, " +;
                               "'Anticipo' AS compro "+;
                               " FROM ge_"+oApp:cId+"provee  "+;
                               " WHERE saldo > 0 "+;
                               ") res WHERE res.saldo <> 0 ORDER BY res.nombre, res.fecha " )
      REPORT oRep TITLE "Detalle de deudas" + " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
             FONT  oFont1,oFont2,oFont3  HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Detalle de deudas a Pagar" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Detalle de deudas a Pagar"
      GROUP oGru ON oQry:codpro HEADER oQry:nombre FOOTER "Totales Proveedor"  FONT 3 
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
               ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
      oQry:End()

      ELSE

      oQry := oApp:oServer:Query(""+;
                              "SELECT c.codpro AS codpro, p.nombre AS nombre, c.fecfac as fecha,  "+;
                               " c.saldo*IF(c.tipocomp='NC',-1,1) AS saldo,"+;           
                               " c.importe*IF(c.tipocomp='NC',-1,1) AS origen,"+;                             
                               " CONCAT(c.tipocomp,c.letra,c.numfac) as compro "+;
                               " FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"provee p ON c.codpro = p.codigo "+;                                                 
                               " WHERE c.saldo > 0 AND c.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
                               " c.fecfac <= "+ ClipValue2Sql(mhasta) +; 
                               " AND " + IF(!lTipo,"TRUE","c.imputaiva")+;                                     
                               "" )
      REPORT oRep TITLE "Detalle de deudas" + " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
             FONT  oFont1,oFont2,oFont3  HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Detalle de deudas a Pagar" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Detalle de deudas a Pagar"
      GROUP oGru ON oQry:codpro HEADER oQry:nombre FOOTER "Totales Proveedor"  FONT 3 
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
               ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
      oQry:End()

    ENDIF
ENDIF    
RETURN 


***********************************
** Listados de pagos a proveedores
PROCEDURE RepDeu3()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCaj,;
      cTodos := "Todos las cajas            ", mnomcaj := SPACE(30), mdesde := CTOD("01/01/2010"), mhasta := DATE(),;
      mcaja := 0, mTotal := 0, oQrySal, lTipo := .f., cUsua:= oApp:usuario,aUsua:={},;
      oQryUsu:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"usuarios"), mturno := 0, lTurno := .f.
oQryUsu:GoTop()
AADD(aUsua,"TODOS")
DO WHILE !oQryUsu:Eof()
   AADD(aUsua,oQryUsu:usuario)
   oQryUsu:Skip()
ENDDO
oQryCaj:= oApp:oServer:Query("SELECT caja as codigo,ip as nombre FROM ge_"+oApp:cId+"punto ORDER BY caja")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Informe de Pagos" FROM 03,15 TO 15,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Caja (0:Todas):"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Turno:"       OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   *@ 35, 65 GET oGet[3] VAR mcaja OF oDlg1 SIZE 30,12 PIXEL RIGHT PICTURE "9999";
   *             VALID(mcaja = 0 .or. Buscar(oQryCaj,oDlg1,oGet[3],oGet[4]));
   *             ACTION (oGet[3]:cText:= 0, Buscar(oQryCaj,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   *@ 35,100 GET oGet[4] VAR mnomcaj PICTURE "@!"  OF oDlg1 PIXEL ;
   *           WHEN((oGet[4]:cText := IF(mcaja=0,cTodos,oQryCaj:nombre)) = SPACE(30))    
   @ 35, 65 CHECKBOX oGet[4] VAR lTurno PROMPT "Por turno de caja" OF oDlg1 SIZE 90,12 PIXEL
   @ 52, 65 GET oGet[3] VAR mturno OF oDlg1 SIZE 30,12 PIXEL RIGHT PICTURE "9999" VALID(mturno>0) WHEN(lTurno)                          
   @ 20, 140 COMBOBOX oGet[6] VAR cUsua OF oDlg1 PIXEL ITEMS aUsua SIZE 60,12 
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
IF !lTurno     
  oQry := oApp:oServer:Query("SELECT  LPAD(CAST(o.numero AS CHAR),8,'0') AS numero, o.fecha as fecha, o.caja as caja, o.usuario, "+;
                           " p.nombre AS proveedor, o.total AS efectivo, res.efec, res.tarj, res.cheqt, res.cheqp, res.anti,res.reten,res.mpago "+;
                           " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"provee p ON o.proveedor = p.codigo "+; 
                           "LEFT JOIN "+;
                              "(SELECT res.numero,SUM(res.efec) AS efec,SUM(tarj) AS tarj,SUM(cheqt) AS cheqt,SUM(cheqp) AS cheqp,"+;
                               "SUM(anti) AS anti, SUM(reten) AS reten, SUM(mpago) as mpago FROM( "+;
                              "SELECT numero,SUM(importe) AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 1 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,SUM(importe) AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 2 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,0 AS tarj,SUM(importe) AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 3 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,SUM(importe) AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 4 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,SUM(importe) AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 5 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,SUM(importe) AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 7 GROUP BY numero "+;
                              "UNION "+;
                              "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, SUM(importe) as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 8 GROUP BY numero "+;
                              ") res GROUP BY res.numero ) "  +;
                           "res ON o.NUMERO = res.NUMERO "+;              
                           " WHERE o.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                           " o.fecha <= "+ ClipValue2Sql(mhasta)+;
                           IF(mcaja = 0,""," AND o.caja = "+ ClipValue2Sql(mcaja))+;
                           IF(cUsua = "TODOS",""," AND o.usuario = "+ ClipValue2Sql(cUsua))+;
                           " ORDER BY o.fecha,o.numero" )
  REPORT oRep TITLE "Ordenes de Pago por fecha del " + ;
                    DTOC(mdesde) + " al " + DTOC(mhasta);
         FONT  oFont1,oFont2,oFont3 ;
         HEADER OemToAnsi(oApp:nomb_emp) , ;
         "Ordenes de Pagos por fecha" CENTER ;
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Ordenes de Pagos por fecha"
  ELSE 
  oQry := oApp:oServer:Query("SELECT  LPAD(CAST(o.numero AS CHAR),8,'0') AS numero, o.fecha as fecha, o.caja as caja, o.usuario, "+;
                         " p.nombre AS proveedor, o.total AS efectivo, res.efec, res.tarj, res.cheqt, res.cheqp, res.anti,res.reten,res.mpago "+;
                         " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"provee p ON o.proveedor = p.codigo "+; 
                         "LEFT JOIN "+;
                            "(SELECT res.numero,SUM(res.efec) AS efec,SUM(tarj) AS tarj,SUM(cheqt) AS cheqt,SUM(cheqp) AS cheqp,"+;
                             "SUM(anti) AS anti, SUM(reten) AS reten, SUM(mpago) as mpago FROM( "+;
                            "SELECT numero,SUM(importe) AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 1 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,SUM(importe) AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 2 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,SUM(importe) AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 3 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,SUM(importe) AS cheqp,0 AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 4 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,SUM(importe) AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 5 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,SUM(importe) AS anti,0 AS reten, 0 as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 7 GROUP BY numero "+;
                            "UNION "+;
                            "SELECT numero,0 AS efec,0 AS tarj,0 AS cheqt,0 AS cheqp,0 AS anti,0 AS reten, SUM(importe) as mpago FROM ge_"+oApp:cId+"ordcon WHERE codcon = 8 GROUP BY numero "+;
                            ") res GROUP BY res.numero ) "  +;
                         "res ON o.NUMERO = res.NUMERO "+;              
                         " WHERE o.id_cierre = " + ClipValue2Sql(mturno) +;                         
                         " ORDER BY o.fecha,o.numero" )
    REPORT oRep TITLE "Ordenes de Pago por turno " + STR(mturno,5) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ordenes de Pagos por turno" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ordenes de Pagos por turno"
ENDIF

COLUMN TITLE "Nro.Orden" DATA oQry:numero  PICTURE "99999999" SIZE 08 FONT 1
COLUMN TITLE "Caja"      DATA oQry:caja       SIZE 03 FONT 1
COLUMN TITLE "Pagó"      DATA oQry:usuario    SIZE 05 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha   SIZE 08 FONT 1
COLUMN TITLE "Proveedor" DATA oQry:proveedor  SIZE 20 FONT 1
COLUMN TITLE "Pagado"    DATA oQry:efectivo   PICTURE "9999999999.99" SIZE 10 FONT 2 TOTAL  
COLUMN TITLE "Efectivo"       DATA oQry:efec  SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
COLUMN TITLE "Transferencias" DATA oQry:tarj  SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
COLUMN TITLE "Cheq. T"        DATA oQry:cheqt SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
COLUMN TITLE "Cheq. P"        DATA oQry:cheqp SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
COLUMN TITLE "M.Pago "        DATA oQry:mpago SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99" 
COLUMN TITLE "Retenciones"    DATA oQry:reten SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
COLUMN TITLE "Anticipos"      DATA oQry:anti  SIZE 10 FONT 1 TOTAL PICTURE "9999999999.99"
                   
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