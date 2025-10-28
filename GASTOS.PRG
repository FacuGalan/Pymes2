#include "fivewin.ch"
#include "report.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

MEMVAR oApp
PROCEDURE Gastos
LOCAL oBot1, oBot2, oDlg1,oGet:=ARRAY(7), mfecha := DATE(), hHand,oError,nRetiro:=.T., nNumDep, ;
      mrta := .f., aCor, oPrn, i, j, nRow, nCol,nNumero,cNumFac,nCompra,oQryPun,cFecha:=DATE(),;
      y, MaxFil, MaxCol, oFont,nProvee:=0,cNomPro:=SPACE(50),oQryPro,nImporte:=0,cObserva:=SPACE(255),;
      nPago := 1, aPago := {"Efectivo","Transferencia","Mercado Pago"}, nCodCue := 0, nNumOpe:= 0, lCuenta := .f.      
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
       FROM 05,15 TO 19,85 OF oApp:oWnd ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
   
   @ 07, 05 SAY "Proveedor:"   OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Importe:"     OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Observacion:" OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Fecha:"       OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Forma Pago:"  OF oDlg1 PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet[1] VAR nProvee  PICTURE "99999999" RIGHT OF oDlg1 SIZE 35,12 PIXEL;
                VALID(Buscar(oQryPro,oDlg1,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryPro,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1" 
   @ 05, 90 GET oGet[2] VAR cNomPro    PICTURE "@!" OF oDlg1 PIXEL WHEN(.F.)   
   @ 20, 50 GET oGet[3] VAR nImporte   PICTURE "99999999.99" OF oDlg1 PIXEL RIGHT VALID(nImporte>0)
   @ 35, 50 GET oGet[4] VAR cObserva   OF oDlg1 PIXEL PICTURE "@!" SIZE 220,12
   @ 50, 50 GET oGet[5] VAR cFecha     OF oDlg1 PIXEL PICTURE "@D" CENTER
   @ 20,100 CHECKBOX oGet[6] VAR nRetiro  OF oDlg1 PIXEL SIZE 100,12 PROMPT "Retira de caja"
   @ 65, 50 COMBOBOX oGet[7] VAR nPago    ITEMS aPago OF oDlg1 PIXEL SIZE 70,12 WHEN(!nRetiro)
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar (F9)" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}

ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()

IF !mrta
   RETURN 
ENDIF
IF nRetiro 
   nPago := 1
ENDIF   
IF nImporte <= 0
   MsgStop("Valores no válidos","Error")
   LOOP
ENDIF
IF nPago = 2
     lCuenta:=  DatosTransferencia(@nCodCue,@nNumOpe,@cObserva)
     IF !lCuenta
        LOOP
     ENDIF
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
      DO CASE 
         CASE nPago = 1
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nNumero)+","+;
                                                       "codcon  = 1, "+;
                                                       "importe = "+ ClipValue2Sql(nImporte)+","+;
                                                       "observa = 'EFECTIVO'")
         CASE nPago = 2
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,numope,detalle,usuario,fecmod,ip,importe) VALUES "+;
                        " ("+;
                          ClipValue2SQL(nCodCue)+","+;
                          "'R',"+;
                          ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2Sql(nNumOpe)+","+;
                            ClipValue2SQL(cObserva)+","+;
                            ClipValue2SQL(oApp:usuario)+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(oApp:cIp)+","+;
                            ClipValue2SQL(nImporte)+")")
              nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM ge_"+oApp:cId+"deposito"):numero 
              oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ordpag SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nNumero))
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nNumero)+","+;
                                                     "codcon  = 2, "+;
                                                     "importe = "+ ClipValue2Sql(nImporte)+","+;
                                                     "observa = 'TRANSFERENCIA'")

         CASE nPago = 3
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nNumero)+","+;
                                                       "codcon  = 8, "+;
                                                       "importe = "+ ClipValue2Sql(nImporte)+","+;
                                                       "observa = 'MERCADO PAGO'")
      ENDCASE        
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


***********************************************************************************************************************************
***** SI ES UNA TRANSFERENCIA PIDO LOS DATOS DE LA CUENTA 
STATIC FUNCTION DatosTransferencia(nCodCue,nNumOpe,cObserva)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomCue:=SPACE(50),oQryCue,oDlg1

oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas")


DEFINE DIALOG oForm TITLE "Cuenta de la transferencia";
       FROM 05,15 TO 15,85 FONT oApp:oFont
   
   @ 07, 05 SAY "Cuenta:"            OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Operacion:"         OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Observaciones:"     OF oForm PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet[1] VAR nCodCue OF oForm SIZE 25,12 RIGHT PICTURE "99" PIXEL;
                VALID(Buscar(oQryCue,oDlg1,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryCue,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 05, 80 GET oGet[2] VAR cNomCue PICTURE "@!" OF oForm PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR nNumOpe PICTURE "99999999999999999999" OF oForm PIXEL RIGHT 
   @ 35, 50 GET oGet[4] VAR cObserva PICTURE "@!" OF oForm PIXEL SIZE 200,12
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN .F.
ENDIF

RETURN .T.