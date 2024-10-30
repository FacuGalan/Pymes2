#include "fivewin.ch"
#include "report.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

MEMVAR oApp
PROCEDURE Gastos
LOCAL oBot1, oBot2, oDlg1,oGet:=ARRAY(6), mfecha := DATE(), hHand,oError,nRetiro:=.T., ;
      mrta := .f., aCor, oPrn, i, j, nRow, nCol,nNumero,cNumFac,nCompra,oQryPun,cFecha:=DATE(),;
      y, MaxFil, MaxCol, oFont,nProvee:=0,cNomPro:=SPACE(50),oQryPro,nImporte:=0,cObserva:=SPACE(255)
IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    RETURN
  ENDIF
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee")
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Carga de gastos" ;
       FROM 05,15 TO 17,85 OF oApp:oWnd ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
   
   @ 07, 05 SAY "Proveedor:"   OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Importe:"     OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Observacion:" OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Fecha:"       OF oDlg1 PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet[1] VAR nProvee  PICTURE "99999999" RIGHT OF oDlg1 SIZE 35,12 PIXEL;
                VALID(Buscar(oQryPro,oDlg1,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryPro,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1" 
   @ 05, 90 GET oGet[2] VAR cNomPro    PICTURE "@!" OF oDlg1 PIXEL WHEN(.F.)   
   @ 20, 50 GET oGet[3] VAR nImporte   PICTURE "99999999.99" OF oDlg1 PIXEL RIGHT VALID(nImporte>0)
   @ 35, 50 GET oGet[4] VAR cObserva   OF oDlg1 PIXEL PICTURE "@!" SIZE 220,12
   @ 50, 50 GET oGet[5] VAR cFecha     OF oDlg1 PIXEL PICTURE "@D" CENTER
   @ 20,100 CHECKBOX oGet[6] VAR nRetiro    OF oDlg1 PIXEL SIZE 100,12 PROMPT "Retira de caja"
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar (F9)" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}

ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()

IF !mrta
   RETURN 
ENDIF
IF nImporte <= 0
   MsgStop("Valores no válidos","Error")
   LOOP
ENDIF
nCompra:= oApp:oServer:Query("SELECT gastosman FROM ge_"+oApp:cId+"parametros"):gastosman+1
cNumFac:= STRTRAN("9999-"+STR(nCompra,8)," ","0")

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"compras (tipocomp,letra,numfac,codpro,fecfac,codcue,fecing,importe,saldo,estado,imputaiva,observa,usuario,fecmod,ip) VALUES "+;
  	                    "('FC','X','"+cNumFac+"',"+ClipValue2Sql(nProvee)+","+ClipValue2Sql(cFecha)+","+ClipValue2Sql(oQryPro:codcue)+","+;
  	                    ClipValue2Sql(cFecha)+","+ClipValue2Sql(nImporte)+",0,'P',0,"+ClipValue2Sql(cObserva)+","+ClipValue2Sql(oApp:usuario)+","+;
                        ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+")")
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordpag " + ;
                        " (proveedor, total, observa,usuario,fecmod,ip,fecha,caja) VALUES "+;
                        " ("+;
                            ClipValue2Sql(nProvee)+","+;
                            ClipValue2Sql(nImporte)+","+;
                            ClipValue2Sql(cObserva)+","+;
                            ClipValue2Sql(oApp:usuario)+","+;
                            ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2Sql(cFecha)+","+;
                            ClipValue2SQL(oQryPun:caja)+")")
  nNumero:= oApp:oServer:Query("SELECT MAX(numero) AS ultimo FROM ge_"+oApp:cId+"ordpag"):ultimo
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordfac SET numero = "+ ClipValue2Sql(nNumero)+","+;
                            "tipocomp = 'FC',"+;
                            "letra = 'X',"+;
                            "numfac = "+ ClipValue2Sql(cNumFac)+","+;
                            "fecha = "+ClipValue2Sql(cFecha)+","+;
                            "importe = "+ClipValue2Sql(nImporte))
  IF nRetiro = .f.
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nNumero)+","+;
                                               "codcon  = 1, "+;
                                               "importe = "+ ClipValue2Sql(nImporte)+","+;
                                               "observa = 'EFECTIVO'")
      ELSE 
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (caja,fecha,importe,observa,tipo,usuario) VALUES "+;
      	                   "("+ClipValue2Sql(oQryPun:caja)+","+ClipValue2Sql(cFecha)+","+;
      	                   	ClipValue2Sql(nImporte)+",'Pago de caja a "+cNomPro+"','R',"+ClipValue2Sql(oApp:usuario)+")")
  ENDIF
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"parametros SET gastosman = gastosman + 1 ")
  oApp:oServer:CommitTransaction()
CATCH oError
   ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN 