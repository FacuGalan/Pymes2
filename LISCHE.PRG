#include "FiveWin.ch"
#include "report.ch"
//********************************************************************
// Proposito: Generar los reportes
// .prg     : listados.prg
// Autor    : Cesar Gomez CM Soft

***********************************
** Cheques propios
MEMVAR oApp
PROCEDURE RepChe1()
LOCAL oRep,oFont1,oFont2,oFont3,acor,;
      oDlg1, oGet1, oGet2, oGet3, oGet4, ;
      oBot1, oBot2, mrta := .f., cTodos := "Todos los proveedores            ",;
      mcodpro := 0, mnompro := SPACE(30), mdesde := CTOD("01/01/2000"),;
      mhasta := DATE(), oQry,oQryProv
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
oQryProv:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee")
// Pongo el cursor con el reloj
DEFINE DIALOG oDlg1 TITLE "Reporte de cheques propios" FROM 03,15 TO 13,70 ;
       OF oApp:oWnd
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Proveedor(0:Todos):"   OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Desde Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Hasta Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   
   @ 05, 60 GET oGet1 VAR mcodpro OF oDlg1 SIZE 30,12 PIXEL;
                VALID(oGet1:value = 0 .or. Buscar(oQryProv,oDlg1,oGet1,oGet2));
                ACTION (oGet1:cText:= 0, Buscar(oQryProv,oDlg1,oGet1,oGet2)) BITMAP "BUSC1" 
   @ 05, 95 GET oGet2 VAR mnompro PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet2:cText := IF(mcodpro=0,cTodos,oQryProv:nombre)) = SPACE(30))
   @ 20, 60 GET oGet3 VAR mdesde  OF oDlg1 PIXEL
   @ 35, 60 GET oGet4 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus() 
IF !mrta
   RETURN
ENDIF
oQry:= oApp:oServer:Query("SELECT c.*,p.nombre FROM ge_"+oApp:cId+"chepro c LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro WHERE "+;
                          IF(mcodpro>0,"c.codpro = "+ClipValue2Sql(mcodpro)," TRUE ")+" AND "+;
                          "c.fecvto >= "+ClipValue2Sql(mdesde)+" AND c.fecvto <= "+ClipValue2Sql(mhasta))


REPORT oRep TITLE "Cheques a " + ALLTRIM(mnompro)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Cheques propios" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Cheques Propios"

COLUMN TITLE "Cta."    DATA oQry:numban    SIZE 05 FONT 1
COLUMN TITLE "Numero"  DATA oQry:numche    SIZE 10 FONT 1
COLUMN TITLE "Importe" DATA oQry:importe   SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Provee." DATA oQry:nombre    SIZE 20 FONT 1
COLUMN TITLE "Vto."    DATA oQry:fecvto    SIZE 10 FONT 1
COLUMN TITLE "Emision" DATA oQry:fecemi    SIZE 10 FONT 1
COLUMN TITLE "O.Pago"  DATA oQry:orden     SIZE 06 FONT 1

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT

ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)

oQry:End()
RETURN 

   
***********************************
** Cheques de terceros
PROCEDURE RepChe2()
LOCAL oRep,oFont1,oFont2,oFont3,acor,;
      oDlg1, oGet1, oGet2, oGet3, oGet4, ;
      oBot1, oBot2, mrta := .f., cTodos := "Todos los clientes               ",;
      mcodcli := 0, mnomcli := SPACE(30), mdesde := CTOD("01/01/2000"),;
      mhasta := DATE(), oQryCli, oQry
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")
DEFINE DIALOG oDlg1 TITLE "Cheques de terceros" FROM 03,15 TO 13,70 ;
       OF oApp:oWnd
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Cliente(0:Todos):" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Desde Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Hasta Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT 
   
   @ 05, 60 GET oGet1 VAR mcodcli OF oDlg1 SIZE 30,12 PIXEL;
                VALID(oGet1:value = 0 .or. Buscar(oQryCli,oDlg1,oGet1,oGet2));
                ACTION (oGet1:cText:= 0, Buscar(oQryCli,oDlg1,oGet1,oGet2)) BITMAP "BUSC1" 
   @ 05, 95 GET oGet2 VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet2:cText := IF(mcodcli=0,cTodos,oQryCli:nombre)) = SPACE(30))
   @ 20, 60 GET oGet3 VAR mdesde  OF oDlg1 PIXEL
   @ 35, 60 GET oGet4 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus() 
IF !mrta
   RETURN
ENDIF

oQry:= oApp:oServer:Query("SELECT ch.*,c.nombre FROM ge_"+oApp:cId+"cheter ch LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = ch.codcli WHERE "+;
                          IF(mcodcli>0,"ch.codcli = "+ClipValue2Sql(mcodcli)," TRUE ")+" AND "+;
                          "ch.fecvto >= "+ClipValue2Sql(mdesde)+" AND ch.fecvto <= "+ClipValue2Sql(mhasta))



REPORT oRep TITLE "Cheques de " + ALLTRIM(mnomcli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Cheques de terceros" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Cheques de terceros"

COLUMN TITLE "Banco"   DATA oQry:numban    SIZE 05 FONT 1
COLUMN TITLE "Numero"  DATA oQry:numche    SIZE 10 FONT 1
COLUMN TITLE "Importe" DATA oQry:importe   SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Cliente" DATA oQry:nombre    SIZE 20 FONT 1
COLUMN TITLE "Vto."    DATA oQry:fecvto    SIZE 10 FONT 1
COLUMN TITLE "Emision" DATA oQry:fecing    SIZE 10 FONT 1
COLUMN TITLE "Recibo"  DATA oQry:recibo    SIZE 06 FONT 1
COLUMN TITLE "Prov. "  DATA oQry:codpro    SIZE 06 FONT 1
COLUMN TITLE "O.Pago"  DATA oQry:orden     SIZE 06 FONT 1
COLUMN TITLE "Estado"  DATA IF(oQry:estado="C","En Cartera",IF(oQry:estado="D","Depositado",;
                            IF(oQry:estado="R","Rechazado","Entregado")))     SIZE 10 FONT 1

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT

ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)

oQry:End()
RETURN 

***********************************
** Movimientos cuenta
PROCEDURE RepChe3()
LOCAL oRep,oFont1,oFont2,oFont3,acor,;
      oDlg1, oGet1, oGet2, oGet3, oGet4, ;
      oBot1, oBot2, mrta := .f.,;
      mcodcue := 0, mnomcue := SPACE(30), mdesde := CTOD("01/01/2000"),;
      mhasta := DATE(), oQryCue, oQry, mtotal := 0
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas")
DEFINE DIALOG oDlg1 TITLE "Movimientos de cuentas bancarias" FROM 03,15 TO 13,70 ;
       OF oApp:oWnd
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Cuenta:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Desde Fecha:"     OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Hasta Fecha:"     OF oDlg1 PIXEL SIZE 50,12 RIGHT 
   
   @ 05, 60 GET oGet1 VAR mcodcue OF oDlg1 SIZE 30,12 PIXEL;
                VALID(Buscar(oQryCue,oDlg1,oGet1,oGet2));
                ACTION (oGet1:cText:= 0, Buscar(oQryCue,oDlg1,oGet1,oGet2)) BITMAP "BUSC1" 
   @ 05, 95 GET oGet2 VAR mnomcue PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 20, 60 GET oGet3 VAR mdesde  OF oDlg1 PIXEL
   @ 35, 60 GET oGet4 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus() 
IF !mrta
   RETURN
ENDIF

/*oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deposito WHERE banco = " + ClipValue2Sql(mcodcue) +" AND "+;
                          "fecacr >= "+ClipValue2Sql(mdesde)+" AND fecacr <= "+ClipValue2Sql(mhasta))*/
oQry:= oApp:oServer:Query(" SELECT res.* FROM ("+;
                          "(SELECT numban AS banco,'R' as tipo, "+ClipValue2Sql(mdesde-1)+" as fecemi, "+ClipValue2Sql(mdesde-1)+" as fecacr,"+;
                          "-1 as numope, 'Saldo Anterior Creditos' as detalle, SUM(importe) as importe, ' ' as nomtip,"+;
                          "0 as id, 0 as idretiro, 0 as cuentac FROM ge_"+oApp:cId+"chepro WHERE numban = " + ClipValue2Sql(mcodcue) +" AND "+;
                          "fecacr < "+ClipValue2Sql(mdesde)+" GROUP BY numban) " +;
                          " UNION "+;
                          "(SELECT banco,'D' AS tipo, "+ClipValue2Sql(mdesde-1)+" AS fecemi, "+ClipValue2Sql(mdesde-1)+" AS fecacr,-1 AS numope,"+; 
                          " 'Saldo Anterior Debitos' AS detalle, SUM(IF(tipo='D',1,-1)*importe) AS importe, ' ' as nomtip, 0 AS id, 0 AS idretiro, 0 AS cuentac "+;
                          " FROM ge_"+oApp:cId+"deposito WHERE banco = " + ClipValue2Sql(mcodcue) +" AND fecacr <= "+ClipValue2Sql(mdesde-1)+" )"+;
                          " UNION "+;
                          "(SELECT m.banco,m.tipo,m.fecemi,m.fecacr,m.numope,m.detalle,m.importe,t.nombre as nomtip,m.id,0 as idretiro,0 as cuentac "+;
                          " FROM ge_"+oApp:cId+"deposito m LEFT JOIN ge_"+oApp:cId+"tipodepo t ON t.codigo = m.codtip WHERE m.banco = " + ClipValue2Sql(mcodcue) +" AND "+;
                          "m.fecacr >= "+ClipValue2Sql(mdesde)+" AND m.fecacr <= "+ClipValue2Sql(mhasta)+")"+;
                          " UNION "+;
                          "(SELECT numban AS banco,'R' as tipo, fecemi as fecemi, fecacr as fecacr,"+;
                          "numche as numope, 'ACREDITACION CHEQUE' as detalle, importe as importe,' ' as nomtip,"+;
                          "0 as id, 0 as idretiro, 0 as cuentac FROM ge_"+oApp:cId+"chepro WHERE numban = " + ClipValue2Sql(mcodcue) +" AND "+;
                          "fecacr >= "+ClipValue2Sql(mdesde)+" AND fecacr <= "+ClipValue2Sql(mhasta)+")) res "+;
                          "ORDER BY res.fecacr")

// Defino el reporte
REPORT oRep TITLE "Movimiento de cuenta " + ALLTRIM(mnomcue)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;                  
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Movimientos banco" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Movimientos bancos"

COLUMN TITLE "ID"      DATA oQry:id        SIZE 6 FONT 1
COLUMN TITLE "Fecha"   DATA oQry:fecacr    SIZE 10 FONT 1
COLUMN TITLE "Tipo Mov." DATA oQry:nomtip   SIZE 15 FONT 1
COLUMN TITLE "Concep." DATA oQry:detalle   SIZE 20 FONT 1
COLUMN TITLE "N° Ope./Che." DATA oQry:numope    SIZE 10 FONT 1
COLUMN TITLE "Debe"    DATA IF(oQry:tipo="D",oQry:importe,0.00)   SIZE 10 FONT 2 TOTAL PICTURE "999999999.99"
COLUMN TITLE "Haber"   DATA IF(oQry:tipo="R",oQry:importe,0.00)   SIZE 10 FONT 2 TOTAL PICTURE "999999999.99"
COLUMN TITLE "Saldo"   DATA mtotal PICTURE "999999999.99" RIGHT;
                           SIZE 10 FONT 2 

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop(), mtotal := IF(oQry:tipo="D",oQry:importe,-oQry:importe) }
oRep:bSkip := {|| oQry:Skip(), mtotal := mtotal + IF(oQry:tipo="D",oQry:importe,-oQry:importe) }

END REPORT

ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)

oQry:End()
RETURN 