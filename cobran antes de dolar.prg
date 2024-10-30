#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** COBRANZA DE CLIENTES
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot, mfecha, manticipo, mcodcli, mentrega, ;
       oBrw, oQry, lEdita, oQryBan, oQryCli, oQryCue,mobserva, oBrwRet, oQryRet,;
       oQryDeu, oBrwD,; // BROWSE DE FACTURAS
       lMostrarSis,;  //VARIABLE QUE DICE SI MUESTRA SISTEMA O DEMO
       oBrwCheT,oQryCheT,;
       lACuenta,; //LOGICA QUE ME HABILITA EL BOTON PARA PAGO A CUENTA
       nEfectivo,nTransferencia,nTarjeta,nCheqT,nTotRet,nReten1,nReten2,nReten3,nReten4,nAnticipo,nFaltante,nTotal,nTotal1,nMPago //FORMAS DE PAGO
PROCEDURE COBRAN()
LOCAL oFont, oFo1,  oSay1, mnomcli, mrta := .f.,cRecurso
oGet := ARRAY(20)
oBot := ARRAY(05)
manticipo := 0
mentrega  := 0
mcodcli := 0
lEdita := .t.
mfecha  := DATE()
mobserva:=SPACE(255)

nEfectivo:=0
nTransferencia:=0
nTarjeta:=0
nMPago:=0
nCheqT :=0
nTotRet:=0
nReten1:=0
nReten2:=0
nReten3:=0
nReten4:=0
nTotal :=0 
nTotal1 :=0
nAnticipo :=0
nFaltante :=0
lMostrarSis:= .t.
lACuenta:=.f.

IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    RETURN
  ENDIF
ENDIF

// TABLA TEMPORAL DE DEUDA
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `tranci_pagos` ("+;
                           "`tipo` VARCHAR(2) , "+; 
                           "`numcomp` VARCHAR(14) , "+; 
                           "`cuota` INT(2) DEFAULT 0 NOT NULL, "+; 
                           "`cantcuo` INT(2) DEFAULT 0 NOT NULL, "+;
                           "`fecha` DATE NOT NULL,"+;
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`saldo` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`pagado` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`saldonue` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`neto` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`aplicado` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`interes` DECIMAL(12,2) DEFAULT 0 NOT NULL "+;
                           ") ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE tranci_pagos")
oApp:oServer:NextResult()

// TABLA TEMPORAL DE DEUDA
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `tranci_deu` ("+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;
                           "`letra` VARCHAR(1) NOT NULL,"+;
                           "`numcomp` VARCHAR(13) NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL "+;
                           ") ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE tranci_deu")
oApp:oServer:NextResult()

// TABLA TEMPORAL DE CHEQUES DE TERCEROS
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_chequeT1` ("+;
                           "`tilde` tinyint(1) NOT NULL DEFAULT 0,"+;
                           "`NOORDEN` tinyint(1) NOT NULL DEFAULT 0,"+;
                           "`NOMBAN` varchar(30) NOT NULL ,"+;
                           "`NUMBAN` int(6) NOT NULL DEFAULT 1,"+;
                           "`NUMCHE` int(10) NOT NULL DEFAULT 0,"+;
                           "`FECING` date DEFAULT NULL,"+;
                           "`FECVTO` date DEFAULT NULL,"+;
                           "`IMPORTE` decimal(12,2) DEFAULT 0,"+;
                           "PRIMARY KEY (numban,numche) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_chequeT1")
oApp:oServer:NextResult()

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_ret` ("+;
                           "`nombre` VARCHAR(30) NOT NULL,"+;                           
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL "+;
                           ") ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_ret")
oApp:oServer:NextResult()  

oApp:oServer:Execute("INSERT INTO transi_ret (nombre) (SELECT nombre FROM ge_"+oApp:cId+"retencio WHERE retecli IS TRUE)")
oQryRet := oApp:oServer:Query("SELECT * FROM transi_ret")  

oQryCheT := oApp:oServer:Query("SELECT * FROM transi_chequeT1")  

oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,saldo,cuit,direccion FROM ge_"+oApp:cId+"clientes")
oQryBan := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"bancos")
oQryCue := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cuentas")
oQryCue := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cuentas")

cRecurso:= IF(oApp:usar_cuotas,"COBRAN","COBRAN2")
DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM tranci_pagos ORDER BY fecha")
   oQryDeu:= oApp:oServer:Query("SELECT * FROM tranci_deu ORDER BY fecha")
   DEFINE FONT oFont NAME "ARIAL" SIZE 09,-11
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE DIALOG oDlg RESOURCE cRecurso OF oApp:oWnd TITLE "Cobranza de cuentas corrientes"
    oDlg:lHelpIcon := .f.
    REDEFINE SAY oSay1 PROMPT "Cliente:" ID 111 OF oDlg
    REDEFINE GET oGet[1] VAR mcodcli  ID 112 OF oDlg PICTURE "99999";
             VALID(ValidaCli(oGet));
             ACTION (oGet[01]:cText:= 0, ValidaCli(oGet)) BITMAP "BUSC1" WHEN(lEdita)
    REDEFINE GET oGet[2] VAR mnomcli  ID 113 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR mfecha ID 114 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[4] VAR mentrega  ID 116 OF oDlg PICTURE "99999999.99" VALID(IF(lEdita,.t.,(Mostrar()=nil .and. oBrw:SetFocus()=nil)))
    REDEFINE GET oGet[5] VAR manticipo ID 117 OF oDlg PICTURE "99999999.99" WHEN(.f.)    
    REDEFINE CHECKBOX oGet[16] VAR lMostrarSis ID 4001 OF oDlg ON CHANGE ValidaCli(oGet) WHEN(lEdita) 
    REDEFINE BUTTON oBot[1] ID 115 OF oDlg ACTION (Mostrar(),oBrw:SetFocus()) WHEN(lEdita)
    IF oApp:usar_cuotas
        REDEFINE XBROWSE oBrwD DATASOURCE oQryDeu;
                  COLUMNS "ticomp","letra","numcomp","fecha","importe";
                  HEADERS "Tipo","L","Numero","Fecha","Importe" FOOTERS;
                  SIZES 30,20,95,70,100 ID 4003 OF oDlg ON CHANGE  Mostrar1(oQryDeu:ticomp,oQryDeu:letra,oQryDeu:numcomp)
        PintaBrw(oBrwD,0)

        REDEFINE XBROWSE oBrw DATASOURCE oQry;
                  COLUMNS "cuota","cantcuo","cuota","fecha","saldo","pagado","saldonue","Importe","aplicado","interes";
                  HEADERS "Cuota","De"," ","Fecha","Saldo","Pagado","Nuevo Saldo","Origen","Aplicado","Interes" FOOTERS;
                  SIZES 35,30,95,75,75,75,75,75,75,75 ID 20 OF oDlg 
        oBrw:aCols[3]:Hide()
        oBrw:aCols[10]:Hide()
        oBrw:aCols[5]:nFooterType := AGGR_SUM
        oBrw:aCols[6]:nFooterType := AGGR_SUM
        oBrw:aCols[7]:nFooterType := AGGR_SUM
        oBrw:aCols[8]:nFooterType := AGGR_SUM
        oBrw:aCols[9]:nFooterType := AGGR_SUM
        oBrw:aCols[6]:lAutoSave := .t.
        oBrw:aCols[6]:nEditType := EDIT_GET  
        oBrw:aCols[6]:bEditValid  := {|oGet, oCol| ControlSaldo(oGet:value,EVAL(oBrw:aCols[5]:bEditValue))} 
        oBrw:aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaSaldo(xval)}  
        oBrw:aCols[6]:bOnChange := {|| oBot[3]:SetFocus(),oBrw:SetFocus(),mentrega:=oApp:oServer:Query("SELECT SUM(pagado) AS suma FROM tranci_pagos"):suma-nAnticipo,oGet[4]:Refresh()}
        PintaBrw(oBrw,0)    
        ELSE 
        REDEFINE XBROWSE oBrw DATASOURCE oQry;
                  COLUMNS "tipo","numcomp","cuota","fecha","saldo","pagado","saldonue","Importe","aplicado","interes";
                  HEADERS "Tip","Nro comprobante"," ","Fecha","Saldo","Pagado","Nuevo Saldo","Origen","Aplicado","Interes" FOOTERS;
                  SIZES 90,250,40,90,90,90,90,90,90,90 ID 20 OF oDlg ON DBLCLICK VerFactura(oQry)
        oBrw:aCols[3]:Hide()
        oBrw:aCols[10]:Hide()
        oBrw:aCols[5]:nFooterType := AGGR_SUM
        oBrw:aCols[6]:nFooterType := AGGR_SUM
        oBrw:aCols[7]:nFooterType := AGGR_SUM
        oBrw:aCols[8]:nFooterType := AGGR_SUM
        oBrw:aCols[9]:nFooterType := AGGR_SUM
        oBrw:aCols[6]:lAutoSave := .t.
        oBrw:aCols[6]:nEditType := EDIT_GET  
        oBrw:aCols[6]:bEditValid  := {|oGet, oCol| ControlSaldo(oGet:value,EVAL(oBrw:aCols[5]:bEditValue))} 
        oBrw:aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaSaldo(xval)}  
        oBrw:aCols[6]:bOnChange := {|| oBot[3]:SetFocus(),oBrw:SetFocus(),mentrega:=oApp:oServer:Query("SELECT SUM(pagado) AS suma FROM tranci_pagos"):suma-nAnticipo,oGet[4]:Refresh()}
        PintaBrw(oBrw,0)     
    ENDIF
    REDEFINE XBROWSE oBrwCheT DATASOURCE oQryCheT;
              COLUMNS "tilde","nomban","numche","fecvto","importe";
              HEADERS "","Banco","Numero","Vto.","Importe" FOOTERS;
              SIZES 30,150,50,70,65,70 ID 30 OF oDlg AUTOSORT
    PintaBrw(oBrwCheT,0)
    oBrwCheT:aCols[1]:SetCheck(nil,.f.)   
    *oBrwCheT:aCols[1]:bLDClickData := {|| CambiaChek(oQryCheT,oBrwCheT)}
    *oBrwCheT:aCols[1]:nEditType := 1
    oBrwCheT:aCols[1]:bEditValue := { || IF(oQryCheT:tilde,.t.,.f.) }
    oBrwCheT:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(DelCheqT(),oBrwCheT:Refresh(),CalcTot()),)}

    REDEFINE GET oGet[06] VAR nEfectivo      ID 200  OF oDlg PICTURE "99999999.99"
    REDEFINE GET oGet[07] VAR nTransferencia ID 201  OF oDlg PICTURE "99999999.99"
    REDEFINE GET oGet[09] VAR nTarjeta       ID 4004 OF oDlg PICTURE "99999999.99" 
    REDEFINE GET oGet[08] VAR nCheqT         ID 202  OF oDlg PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[12] VAR nAnticipo      ID 203  OF oDlg PICTURE "99999999.99";
                 VALID(nAnticipo <= manticipo );
                 WHEN(manticipo>0)
    REDEFINE GET oGet[20] VAR nMPago         ID 4005 OF oDlg PICTURE "99999999.99" 

    REDEFINE XBROWSE oBrwRet DATASOURCE oQryRet;
              COLUMNS "nombre","importe";
              HEADERS "Retencion","Importe" FOOTERS;
              SIZES 120,80 ID 31 OF oDlg WHEN(!lEdita)
    PintaBrw(oBrwRet,0)        
    oBrwRet:aCols[2]:nEditType := 1
    oBrwRet:aCols[2]:nFooterType := AGGR_SUM
    oBrwRet:lRecordSelector := .f.

    REDEFINE GET oGet[13] VAR mobserva ID 4002 OF oDlg PICTURE "@!"              
    REDEFINE GET oGet[14] VAR nFaltante ID 121 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())
    REDEFINE GET oGet[15] VAR nTotal ID 122 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())
    REDEFINE GET oGet[17] VAR nTotal1 ID 123 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())

    REDEFINE BUTTON oBot[2] ID 102 OF oDlg ACTION (Grabar()) WHEN( (oApp:oServer:Query("SELECT COUNT(*) AS suma FROM tranci_pagos WHERE pagado <> 0"):suma > 0;
                                                                   .AND. ROUND(nFaltante,2) <= 0) .OR. lACuenta)
    REDEFINE BUTTON oBot[5] ID 105 OF oDlg ACTION (AddCheqT(oDlg),oBrwCheT:Refresh())
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg ACTION Cancela()
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
   ACTIVATE DIALOG oDlg CENTER ON INIT (oGet[16]:Hide())
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)
oQryCli:End()
oFont:End()
oFo1:End()
RETURN


STATIC FUNCTION VerFactura(oQry)
IF !oApp:oServer:Query("SELECT imprimeTic FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):imprimeTic
  IF LEFT(oQry:numcomp,1) $ "ABC"
     PrintFactuElec(oQry:tipo,oQry:numcomp)  
  ELSE 
     FacturaNoFiscal(oQry:tipo,oQry:numcomp)
  ENDIF
ENDIF  
RETURN NIL

******************************************************************************************************************************
********* TRAIGO LOS DATOS DEL CLIENTE ELEGIDO 
STATIC FUNCTION ValidaCli(oGet)

oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,saldo,cuit,direccion FROM ge_"+oApp:cId+"clientes WHERE codigo = " +ClipValue2Sql(mcodcli))
IF oQryCli:RecCount() = 0 
   Buscar(oQryCli,oDlg,oGet[01])
ENDIF
oGet[02]:cText:= oQryCli:nombre 
oGet[05]:cText:= oQryCli:saldo // IF(lMostrarSis,oQryCli:saldo,oQryCli:saldod) 
oGet[12]:cText:= oQryCli:saldo //IF(lMostrarSis,oQryCli:saldo,oQryCli:saldod) 

IF lMostrarSis
   oDlg:Gradient({ { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } })
   oDlg:Refresh()
ELSE 
   oDlg:Gradient({ { 1, RGB( 240,128,128 ), RGB( 237, 242, 248 ) } })
   oDlg:Refresh()
ENDIF
RETURN .t.


***********************************************************************************************************************************
******* CALCULO DE TOTALES
STATIC FUNCTION CalcTot()
oGet[08]:cText:= oApp:oServer:Query("SELECT SUM(importe) AS suma FROM transi_chequeT1 WHERE tilde = 1"):suma
*oGet[09]:cText:= oApp:oServer:Query("SELECT SUM(importe) AS suma FROM transi_chequeP "):suma
oGet[15]:cText:= oGet[6]:value + oGet[7]:value + oGet[8]:value + oGet[9]:value + oGet[12]:Value + oGet[20]:Value + oBrwRet:aCols[2]:nTotal
oGet[17]:cText:= oBrw:aCols[6]:nTotal 
oGet[14]:cText:= oGet[17]:value - oGet[15]:value 

RETURN .f.


******************************************************************************************************************************
************** GRABAR EL PAGO 
STATIC FUNCTION Grabar()
LOCAL nPago:=0,oError,mRta:=.f.,nCodCue:=0,nNumOpe:=0,cObserva:=SPACE(255),nNumDep,;
      lCuenta:=.f., nInteres := 0, nNuevoSaldo := 0
IF oBrw:aCols[6]:nTotal <= 0 .AND. oApp:oServer:Query("SELECT * FROM tranci_pagos WHERE pagado <> 0"):RecCount()=0 ;
    .AND. oBrw:aCols[5]:nTotal <> 0
   MsgStop("No marco ninguna factura para pagar","Atencion")   
   RETURN .f.
ENDIF
IF nTransferencia > 0
     lCuenta:=  DatosTransferencia(@nCodCue,@nNumOpe,@cObserva)
     IF !lCuenta
        RETURN .f.
     ENDIF
ENDIF
mrta := MsgYesNo("Confirma grabar el pago?","Atencion")
IF !mRta
   RETURN .f.
ENDIF
IF ROUND(nFaltante,2) < 0
   IF !Avisar()
      RETURN .f.
   ENDIF
ENDIF
nTotRet:= oApp:oServer:Query("SELECT SUM(importe) AS total FROM transi_ret"):total
TRY 
   oApp:oServer:BeginTransaction()
     IF oApp:usar_cuotas // Si vende en cuotas calculo el interes
         DO WHILE !oQry:Eof()
            IF oQry:interes <> 0 .AND. oQry:pagado <> 0
               IF(ABS(oQry:pagado) > ABS(oQry:interes))
                  nInteres :=  ABS(oQry:interes) * IF(oQry:tipo="NC",-1,1)
                  ELSE 
                  nInteres :=  ABS(oQry:pagado) * IF(oQry:tipo="NC",-1,1)
               ENDIF      
            ENDIF
            oQry:Skip()
         ENDDO
     ENDIF
     nNuevoSaldo := oBrw:aCols[5]:nTotal -;
                  (nEfectivo+nTransferencia+nTarjeta+nCheqT+nTotRet+nMPago) - nAnticipo
     mobserva := ALLTRIM(mobserva) + IF(nNuevoSaldo <> 0 ," - (Saldo de su cuenta: $ "+STR(nNuevoSaldo,15,2)+")","")
     ** Agrego pago 
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagos " + ;                                       //INTERESES???
                          " (cliente, total, facturas, observa, fecha,caja, usuario,vendedor, fecmod, ip, demo,interes) VALUES "+;
                         " ("+;
                             ClipValue2Sql(mcodcli)+","+;
                             ClipValue2Sql(nEfectivo+nTransferencia+nTarjeta+nCheqT+nTotRet+nMPago)+","+;
                             ClipValue2Sql(oBrw:aCols[6]:nTotal)+","+;
                             ClipValue2Sql(mobserva)+","+;
                             ClipValue2Sql(mfecha)+","+;
                             ClipValue2Sql(oApp:prefijo)+","+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2SQL(DATE())+","+;
                             ClipValue2SQL(oApp:cIp)+","+;
                             IF(lMostrarSis,"0","1")+","+;
                             ClipValue2SQL(nInteres)+;
                             ")")
     nPago:= oApp:oServer:Query("SELECT MAX(numero) AS orden FROM ge_"+oApp:cId+"pagos"):orden
     ** Actualizo saldos de facturas
     oQry:GoTop()
     IF oApp:usar_cuotas
         DO WHILE !oQry:Eof()
            IF oQry:pagado <> 0
               oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_cuota SET saldo = " + ClipValue2Sql(ABS(oQry:saldonue)) +", "+ ;
                                    "fecvto = IF("+ClipValue2Sql(ABS(oQry:saldonue))+" = 0,fecvto,curdate()) "+;
                                    " WHERE tipo = " + ClipValue2Sql(oQryDeu:ticomp) +;
                                    " AND   letra    = " + ClipValue2Sql(oQryDeu:letra) +;
                                    " AND   numero   = " + ClipValue2Sql(oQryDeu:numcomp) +;
                                    " AND   cuota   = " + ClipValue2Sql(oQry:cuota) +;
                                    " AND   cliente   = " + ClipValue2Sql(mcodcli) )               
               oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagfac SET numero = "+ ClipValue2Sql(nPago)+","+;
                                  "ticomp = "+ ClipValue2Sql(oQryDeu:ticomp)+","+;
                                  "letra = "+ ClipValue2Sql(oQryDeu:letra)+","+;
                                  "numcomp = "+ ClipValue2Sql(oQryDeu:numcomp)+","+;
                                  "cuota = " + ClipValue2Sql(oQry:cuota)+","+;
                                  "cantcuo = " + ClipValue2Sql(oQry:cantcuo)+","+;
                                  "fecha = "+ ClipValue2Sql(mfecha)+","+;
                                  "importe = "+ClipValue2Sql(oQry:pagado)+","+;
                                  "neto = "+IF(oQry:saldo=oQry:importe,ClipValue2Sql(oQry:neto),"0"))              
            ENDIF   
            oQry:Skip()
         ENDDO
         ELSE 
         DO WHILE !oQry:Eof()
            oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_cuota SET saldo = " + ClipValue2Sql(ABS(oQry:saldonue)) +" "+ ;
                                    " WHERE tipo = " + ClipValue2Sql(oQry:tipo) +;
                                    " AND   letra    = " + ClipValue2Sql(LEFT(oQry:numcomp,1)) +;
                                    " AND   numero   = " + ClipValue2Sql(RIGHT(oQry:numcomp,13)) +;
                                    " AND   cuota   = " + ClipValue2Sql(oQry:cuota) +;
                                    " AND   cliente   = " + ClipValue2Sql(mcodcli) )   
            IF oQry:pagado <> 0
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagfac SET numero = "+ ClipValue2Sql(nPago)+","+;
                                  "ticomp = "+ ClipValue2Sql(oQry:tipo)+","+;
                                  "letra = "+ ClipValue2Sql(LEFT(oQry:numcomp,1))+","+;
                                  "numcomp = "+ ClipValue2Sql(RIGHT(oQry:numcomp,13))+","+;
                                  "cuota = " + ClipValue2Sql(oQry:cuota)+","+;
                                  "cantcuo = " + ClipValue2Sql(oQry:cantcuo)+","+;
                                  "fecha = "+ ClipValue2Sql(mfecha)+","+;
                                  "importe = "+ClipValue2Sql(oQry:pagado)+","+;
                                  "neto = "+IF(oQry:saldo=oQry:importe,ClipValue2Sql(oQry:neto),"0"))              
            ENDIF   
            oQry:Skip()
         ENDDO
     ENDIF
     ** Grabo las formas de pago
     // INGRESO CONCEPTO EFECTIVO
     IF nEfectivo > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                               "codcon  = 1, "+;
                                               "tipocon  = 1, "+;
                                               "importe = "+ ClipValue2Sql(nEfectivo)+","+;
                                               "observa = 'EFECTIVO'")
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"usuarios SET saldo = saldo + "+ClipValue2Sql(nEfectivo)+" "+;
                             "WHERE usuario = "+ClipValue2Sql(oApp:usuario))
     ENDIF

     IF nMPago > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                               "codcon  = 8, "+;
                                               "tipocon  = 8, "+;
                                               "importe = "+ ClipValue2Sql(nMPago)+","+;
                                               "observa = 'MERCADO PAGO'")        
     ENDIF
     
     // INGRESO CONCEPTO TRANSFERENCIA
     IF nTransferencia > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,numope,detalle,usuario,fecmod,ip,importe) VALUES "+;
                        " ("+;
                          ClipValue2SQL(nCodCue)+","+;
                          "'D',"+;
                          ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2Sql(nNumOpe)+","+;
                            ClipValue2SQL(cObserva)+","+;
                            ClipValue2SQL(oApp:usuario)+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(oApp:cIp)+","+;
                            ClipValue2SQL(nTransferencia)+")")
        nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM ge_"+oApp:cId+"deposito"):numero 
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagos SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nPago))
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                               "codcon  = 2, "+;
                                               "tipocon  = 2, "+;
                                               "importe = "+ ClipValue2Sql(nTransferencia)+","+;
                                               "observa = 'TRANSFERENCIA'")
     ENDIF

     // INGRESO CONCEPTO CHEQUES DE TERCEROS Y ACTUALIZO SU ESTADO
     IF nCheqT > 0
     oQryCheT:GoTop()
       DO WHILE !oQryCheT:Eof()
          IF oQryCheT:tilde = .t.
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                          "codcon  = 3, "+;
                                                          "tipocon  = 3, "+;
                                                           "importe = "+ ClipValue2Sql(oQryCheT:importe)+","+;
                                                           "observa = '"    + ALLTRIM(oQryCheT:nomban)+;
                                                                     " NRO "+ STR(oQryCheT:numche,10)+;
                                                                     " VTO "+ DTOC(oQryCheT:fecvto)+"'")
            //SI EXISTE ACTUALIZO LOS DATOS SINO LO DOY DE ALTA
            IF oApp:oServer:Query("SELECT numche FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2Sql(oQryCheT:numban) +" "+;
                                                            "AND   numche = " + ClipValue2Sql(oQryCheT:numche) ):RecCount() > 0
                oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"cheter SET codcli = "+ClipValue2Sql(mcodcli)+","+;
                                                       "recibo = "+ClipValue2Sql(nPago)+" "+;
                                     "WHERE numban = " + ClipValue2Sql(oQryCheT:numban) +" "+;
                                     "AND   numche = " + ClipValue2Sql(oQryCheT:numche) )
            ELSE 
                oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cheter SET numban  = "+ClipValue2Sql(oQryCheT:numban)+","+;
                                                            "numche  = "+ClipValue2Sql(oQryCheT:numche)+","+;
                                                            "fecing  = "+ClipValue2Sql(oQryCheT:fecing)+","+;
                                                            "fecvto  = "+ClipValue2Sql(oQryCheT:fecvto)+","+;
                                                            "importe = "+ClipValue2Sql(oQryCheT:importe)+","+;
                                                            "recibo  = "+ClipValue2Sql(nPago)+","+;
                                                            "codcli  = "+ClipValue2Sql(mcodcli)+","+;
                                                            "noorden = "+ClipValue2Sql(oQryCheT:noorden)+","+;
                                                            "usuario = "+ClipValue2Sql(oApp:usuario)+","+;
                                                            "fecmod  = CURDATE(),"+;
                                                            "ip      = "+ClipValue2Sql(oApp:cIp)+","+;
                                                            "estado  = 'C'")

            ENDIF
          ENDIF
       oQryCheT:Skip()
       ENDDO
     ENDIF

     IF nTarjeta > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 4, "+;
                                                    "tipocon  = 4, "+;
                                                    "importe = "+ ClipValue2Sql(nTarjeta)+","+;
                                                    "observa = 'TARJETA'")
     ENDIF
     // INGRESO CONCEPTOS DE RETENCIONES   
     /*            
     IF nReten1 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 5, "+;
                                                    "importe = "+ ClipValue2Sql(nReten1)+","+;
                                                    "observa = 'RETENCIONES GANANCIAS'")
     ENDIF
     IF nReten2 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 6, "+;
                                                    "importe = "+ ClipValue2Sql(nReten2)+","+;
                                                    "observa = 'RETENCIONES I.V.A'")
     ENDIF
     IF nReten3 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 8, "+;
                                                    "importe = "+ ClipValue2Sql(nReten3)+","+;
                                                    "observa = 'RETENCIONES II.BB'")
     ENDIF
     IF nReten4 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 9, "+;
                                                    "importe = "+ ClipValue2Sql(nReten4)+","+;
                                                    "observa = 'RETENCIONES SUSS'")
     ENDIF
     */
     oQryRet:GoTop()
     DO WHILE !oQryRet:Eof()
        IF oQryRet:importe > 0
           oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                        "codcon  = 5, "+;
                                                        "tipocon  = 5, "+;
                                                        "importe = "+ ClipValue2Sql(oQryRet:importe)+","+;
                                                        "observa = "+ ClipValue2Sql(oQryRet:nombre))
        ENDIF
        oQryRet:Skip()
     ENDDO
     // INGRESO MONTO PAGADO POR ANTICIPO                                  
     IF nAnticipo > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                                    "codcon  = 7, "+;
                                                    "tipocon  = 7, "+;
                                                    "importe = "+ ClipValue2Sql(nAnticipo)+","+;
                                                    "observa = 'ANTICIPO'")
     ENDIF

     // ACTUALIZO SALDO DEL CLIENTE                       
     //IF lMostrarSis
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = saldo -" +ClipValue2Sql(nAnticipo)+" + "+ClipValue2Sql(ABS(nFaltante))+" "+;
                             "WHERE codigo = "+ClipValue2Sql(mcodcli))
    /* ELSE
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldod = saldod -" +ClipValue2Sql(nAnticipo)+" + "+ClipValue2Sql(ABS(nFaltante))+" "+;
                             "WHERE codigo = "+ClipValue2Sql(mcodcli))
     ENDIF*/

    oApp:oServer:CommitTransaction()
    CATCH oError
    ValidaError(oError)
    RETURN .f.
END TRY
mobserva:=SPACE(255)
mrta := MsgYesNo("Desea Imprimir el Recibo?","Atencion")
IF mrta   
   Reci(nPago,.t.)
ENDIF

*IF nReten1+nReten2 > 0 .and.  MsgYesNo("Desea Imprimir el comprobante de Retencion?","Atencion")
   
*ENDIF
Cancela()
RETURN nil

STATIC FUNCTION Avisar()
LOCAL oBot := ARRAY(3), oForm, oFontGrande,acor,lRta:=.f.

DEFINE FONT oFontGrande NAME "TAHOMA" SIZE 12,-15


DEFINE DIALOG oForm TITLE "ATENCION!";
       FROM 05,15 TO 19,85 OF oDlg FONT oApp:oFont
   
   @ 05, 05 SAY "Se detecto un saldo a favor del cliente."+CHR(10)+;
                "EL monto marcado a pagar es de $"+ALLTRIM(oGet[17]:cText)+CHR(10)+;
                "y la suma de las formas de pago es de $"+ALLTRIM(oGet[15]:cText)+"."+CHR(10)+;
                "El anticipo que se va a generar es de $"+ALLTRIM(STR(ABS(nFaltante),10))+CHR(10)+;
                "¿DESEA CONTINUAR?";
   OF oForm PIXEL SIZE 230,100 FONT oFontGrande
   
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Si" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&No" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 

IF !lRta
   RETURN .F.
ENDIF
RETURN .T.

STATIC FUNCTION CambiaChek(oQry1,oBrw1)
LOCAL valor
valor := IF(oQry1:tilde=.f.,.t.,.f.)
oQry1:tilde := valor
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
CalcTot()
RETURN nil

***********************************************************************************************************************************
***** SI ES UNA TRANSFERENCIA PIDO LOS DATOS DE LA CUENTA 
STATIC FUNCTION DatosTransferencia(nCodCue,nNumOpe,cObserva)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomCue:=SPACE(50),oQryCue,oDlg1

oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas")


DEFINE DIALOG oForm TITLE "Cuenta de la transferencia";
       FROM 05,15 TO 15,85 OF oDlg FONT oApp:oFont
   
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


*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaSaldo(n)
LOCAL base := oQry:GetRowObj()
base:pagado := n 
base:saldonue := ABS(oQry:saldo-n) * IF(base:saldo<0,-1,1)
oQry:oRow := base
oQry:Save()
oQry:Refresh()
RETURN nil


*****************************************
** Controla saldo
STATIC FUNCTION ControlSaldo(n,n1)
LOCAL lRet
IF n1 < 0
   IF ABS(n) <= ABS(n1) .and. n <= 0
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
   ELSE
   IF n <= n1
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
ENDIF
IF !lRet
   MsgStop("No puede abonar mas de lo adeudado","Error")
ENDIF
RETURN lRet         


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.

*****************************************
** Cancelar
STATIC FUNCTION Cancela()
LOCAL i
oQry:Zap()
oBrw:Refresh()
oBrw:MakeTotals()
oQryDeu:Zap()
IF oApp:usar_cuotas
  oBrwD:Refresh()
  oBrwD:MakeTotals()
ENDIF
oQryCheT:Zap()
oBrwCheT:Refresh()
FOR i := 4 to 12 
  IF i <> 9 .and. i <> 10 .and. i <> 11
   oGet[i]:cText:= 0
  ENDIF
NEXT i
oGet[14]:cText:= 0
oGet[15]:cText:= 0
oGet[17]:cText:= 0
oGet[20]:cText:= 0
*oGet[19]:cText:= 0
lEdita := .t.
lACuenta:=.F.
oGet[1]:SetFocus()
oApp:oServer:Execute("UPDATE transi_ret SET importe = 0")
oQryRet:Refresh()
oBrwRet:Refresh()
oBrwRet:MakeTotals()
RETURN nil

*****************************************
** Cargar deuda
STATIC FUNCTION Mostrar1(cTipoCom,cLetra,cNumFac)
LOCAL mentre := mentrega + nAnticipo
oQry:Zap()
oApp:oServer:Execute("INSERT INTO tranci_pagos (tipo,numcomp,cuota,cantcuo,fecha,saldo,pagado,saldonue,neto,importe,aplicado,interes) "+;
                     "SELECT  tipo, CONCAT(letra,numero) as numcomp,cuota,cantcuo,fecvto, "+;
                     " saldo * IF(tipo = 'NC', -1,1) * "+;
                     " ( SELECT i.indice "+;
                     " FROM ge_"+oApp:cId+"indexa i WHERE i.dias <   DATEDIFF(CURDATE() , v.fecvto)  ORDER BY dias DESC LIMIT 1),"+;
                     " 0 , saldo * IF(tipo = 'NC', -1,1) * "+;
                     " ( SELECT i.indice "+;
                     " FROM ge_"+oApp:cId+"indexa i WHERE i.dias <   DATEDIFF(CURDATE() , v.fecvto)  ORDER BY dias DESC LIMIT 1),"+;
                     " IF(saldo = importe,neto,0) * IF(tipo = 'NC', -1,1),  "+;
                     " importe, importe-saldo ,  "+;
                     " saldo * IF(tipo = 'NC', -1,1) * "+;
                     " ( SELECT (i.indice-1) "+;
                     " FROM ge_"+oApp:cId+"indexa i WHERE i.dias <   DATEDIFF(CURDATE() , v.fecvto)  ORDER BY dias DESC LIMIT 1) "+;
                     "FROM ge_"+oApp:cId+"ventas_cuota v "+;
                     "WHERE cliente = " + ClipValue2Sql(mcodcli) + " AND " +;
                     IF(oApp:usar_cuotas,;
                     " tipo = "+ClipValue2Sql(cTipoCom)+" AND "+;
                     " letra = "+ClipValue2Sql(cLetra)+" AND "+;
                     " numero = "+ClipValue2Sql(cNumFac)+" AND ","")+;
                     " saldo > 0 ")
                     //" cae " + IF(lMostrarSis," IS NOT NULL","IS NULL")+" AND "+;
                     
oApp:oServer:NextResult()
oQry:Refresh()
DO WHILE !oQry:Eof()
   IF oQry:tipo = "NC"
      oQry:pagado   := oQry:saldo
      oQry:saldonue := 0
      mentre := mentre + ABS(oQry:saldo)
      oQry:Save()
   ENDIF   
   oQry:Skip()
ENDDO
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:tipo <> "NC" .and. mentre > 0
      IF mentre > oQry:saldo
         mentre := mentre - oQry:saldo
         oQry:pagado := oQry:saldo
         oQry:saldonue := 0
         oQry:Save()
         ELSE
         oQry:pagado := mentre
         oQry:saldonue := oQry:saldo - oQry:pagado
         mentre := 0
         oQry:Save()
      ENDIF   
   ENDIF
   oQry:Skip()
ENDDO

oQry:GoTop()
oBrw:Refresh()
oBrw:MakeTotals()

/*
IF oQryCheT:reccount()=0
  oApp:oServer:Execute("INSERT INTO transi_chequeT1 (tilde,numban,nomban,numche,fecing,fecvto,importe) "+;
                       "(SELECT 0,c.numban,b.nombre,c.numche,c.fecing,c.fecvto,c.importe FROM ge_"+oApp:cId+"cheter c "+;
                        "LEFT JOIN ge_"+oApp:cId+"bancos b ON b.codigo = c.numban "+;
                        "WHERE c.estado = 'C' AND c.codcli = "+ClipValue2Sql(mcodcli)+")")
  oQryCheT:Refresh()
  oBrwCheT:Refresh()
ENDIF*/
RETURN nil 


*****************************************
** Cargar deuda
STATIC FUNCTION Mostrar()
LOCAL mentre := mentrega + nAnticipo
oQryDeu:Zap()
oApp:oServer:Execute("INSERT INTO tranci_deu (ticomp,letra,numcomp,fecha,importe) "+;
                     "(SELECT  ANY_VALUE(tipo) AS tipo,ANY_VALUE(letra) AS letra,ANY_VALUE(numero) AS numero,ANY_VALUE(fecha) AS fecha,SUM(importe) "+;  
                     "FROM ge_"+oApp:cId+"ventas_cuota "+;
                     "WHERE cliente = " + ClipValue2Sql(mcodcli) + " AND " +;
                     " saldo > 0 "+;
                     "GROUP BY tipo,letra,numero)")
oQryDeu:Refresh()
oQryDeu:GoTop()
IF oApp:usar_cuotas
   oBrwD:Refresh()
   oBrwD:MakeTotals()
ENDIF
IF oQryDeu:nRecCount = 0
   lACuenta:= MsgNoYes("Cliente sin deuda pendiente ¿desea realizar un pago a cuenta?","Atencion!")
   ELSE
   lEdita := .f.
   lACuenta:=.f.
   Mostrar1(oQryDeu:ticomp,oQryDeu:letra,oQryDeu:numcomp)   
ENDIF

RETURN nil 

*************************************************
** Borrar cheques de Terceros
STATIC FUNCTION DelCheqT(oWnd)
oQryCheT:Delete()
oQryCheT:Refresh()
RETURN nil

*************************************************
** Agregar cheques de Terceros
STATIC FUNCTION AddCheqT(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomBan := SPACE(30), cNomCli := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont
DO WHILE .T.
base := oQryCheT:GetBlankRow()
base:importe := 0
base:fecing  := DATE()
base:fecvto  := DATE()
cNomCli      := oQryCli:nombre
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques de Terceros" FROM 05,15 TO 19,66 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Banco:"         OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 80 GET oGet2[2] VAR cNomBan OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(base:numche > 0) RIGHT
   @ 20,100 CHECKBOX oGEt2[4] VAR base:noorden PIXEL OF oDlg3 PROMPT "No a la orden" SIZE 100,12 
   @ 35, 50 GET oGet2[7] VAR base:fecing   PICTURE "@D" PIXEL OF oDlg3 CENTER
   @ 50, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 VALID(base:fecvto >= base:fecing) CENTER
   @ 65, 50 GET oGet2[9] VAR base:importe  PICTURE "999999999.99" PIXEL OF oDlg3 RIGHT VALID(base:importe>0)
   @ acor[1],acor[2] BUTTON oBot2[1] PROMPT "&Grabar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg3:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2[2] PROMPT "&Cancelar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg3:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg3 CENTER ON INIT oGet2[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF
IF base:importe <= 0
   MsgStop("Importe no valido","Error")
   LOOP
ENDIF   
oQryChe1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2Sql(base:numban) +;
                               " AND numche = " + ClipValue2Sql(base:numche) )
IF oQryChe1:nRecCount > 0
   MsgStop("Cheque ya existe", "Error")
   LOOP
ENDIF   
base:nomban:= cNomBan
base:tilde:= .t.
oQryCheT:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryCheT:Save()
  oQryCheT:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

**************************************************************
** Impresion del recibo de pagos
FUNCTION Reci(nNumero)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado – Ley Nº 19.640",;
                "IVA Responsable Inscripto – Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA NO Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, oQryPag, oQryPagFac, config,;
      oQryPagCon, aCor
   oQryPag    := oApp:oServer:Query( "SELECT p.*, c.nombre, c.direccion, c.cuit, c.localidad, c.coniva, c.mail "+;
   	             " FROM ge_"+oApp:cId+"pagos p "+;
   	             " LEFT JOIN ge_"+oApp:cId+"clientes c  ON c.codigo = p.cliente "+;
   	             " WHERE p.numero = " + ClipValue2SQL(nNumero))
   oQryPagFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagfac WHERE numero = " + ClipValue2SQL(nNumero))
   oQryPagCon := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagcon WHERE numero = " + ClipValue2SQL(nNumero))
   
   IF oQryPag:nRecCount = 0
      MsgStop("Recibo no existe!!","Error")
      RETURN nil
   ENDIF      
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   ** FACTURACION CON FORMATO PARA FACTURA ELECTRONICA
   DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
   DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD
   DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
   
   PRINT oPrn NAME "Recibo" PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
   FOR x := 1 TO 2
	   PAGE	   	 
     oApp:cDestinoMail := oQryPag:mail
     @ 0,0 PRINT TO oPrn IMAGE "fondorec.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY  	   
	   oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
     oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
     oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
     oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
     oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
     @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
            SIZE 18,.9 CM FONT oFont1 ALIGN "C"	   
     IF config:x1 = 2 .or. config:x1 = 3
        @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
     ENDIF
     IF config:x1 = 1 .or. config:x1 = 3
         @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                  SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
         @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
         @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
     ENDIF
	   
	   oPrn:CmSay( 2  , 11, "RECIBO", oFont1 )   	   
	   oPrn:CmSay( 2.5, 11, "Nro de recibo:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
	   oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

	   oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
	   oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont)	
	   oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)	   
          

	   
	   @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
	              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
	   @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPag:cuit ;
	              SIZE 6,.5 CM FONT oFont ALIGN "L"
	   @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
	              SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
	   @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:nombre) ;
	              SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
	   @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
	              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
	   @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPag:coniva] ;
	              SIZE 6,.5 CM FONT oFont ALIGN "L"
	   nRow := IF(nRow<6,6,nRow)
	   @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
	              SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
	   @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:direccion) + " " + ;
	                                           ALLTRIM(oQryPag:localidad) ;
	              SIZE 8,1 CM FONT oFont ALIGN "L"

	   @ 8.2, 01 PRINT TO oPrn TEXT "Comprobante" ;
              SIZE 5,.5 CM FONT oFont ALIGN "L"
       @ 8.2, 7 PRINT TO oPrn TEXT "Cuota" ;
              SIZE 2,.5 CM FONT oFont ALIGN "L"
       @ 8.2, 11 PRINT TO oPrn TEXT "Importe" ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
             
	   y := 9.2
	   oQryPagFac:GoTop()
	     DO WHILE !oQryPagFac:Eof()           
           @ y, 01 PRINT TO oPrn TEXT oQryPagFac:ticomp+oQryPagFac:letra+oQryPagFac:numcomp ;
              SIZE 5.8,.5 CM FONT oFont ALIGN "L"
           IF oQryPagFac:cuota <> 0
              @ y, 07 PRINT TO oPrn TEXT STR(oQryPagFac:cuota,2)+"/"+STR(oQryPagFac:cantcuo,2) ;
                 SIZE 2,.5 CM FONT oFont ALIGN "C"
           ENDIF
           @ y, 11 PRINT TO oPrn TEXT STR(oQryPagFac:importe,14,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"           
	         y := y + .5
           IF y > 20
              @ 22.5, 01 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA" SIZE 10,.5 CM FONT oFont  
              ENDPAGE
              PAGE
                 @ 0,0 PRINT TO oPrn IMAGE "fondorec.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY       
                 oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                 oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                 oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                 oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
                 oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
                 @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                        SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                              SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                              SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 
                 oPrn:CmSay( 2  , 11, "RECIBO", oFont1 )       
                 oPrn:CmSay( 2.5, 11, "Nro de recibo:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
                 oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

                 oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                 oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                 oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                      

                 
                 @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPag:cuit ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:nombre) ;
                            SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPag:coniva] ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 nRow := IF(nRow<6,6,nRow)
                 @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:direccion) + " " + ;
                                                         ALLTRIM(oQryPag:localidad) ;
                            SIZE 8,1 CM FONT oFont ALIGN "L"
                y := 9.2            
           ENDIF
           oQryPagFac:SKIP()           
       ENDDO
       y := y + 1
       oPrn:CmBox( y, .5, y+.5, 20.5 ) // Box titulos   
       @ y, 01 PRINT TO oPrn TEXT "Forma de pago" ;
              SIZE 12,.5 CM FONT oFont ALIGN "L"       
       @ y, 14 PRINT TO oPrn TEXT "Importe" ;
              SIZE 3,.5 CM FONT oFont ALIGN "R"
       y := y + 0.5
       oQryPagCon:GoTop()
       DO WHILE !oQryPagCon:Eof()
           @ y, 14 PRINT TO oPrn TEXT STR(oQryPagCon:importe,12,2) ;
              SIZE 3,.5 CM FONT oFont ALIGN "R"  
           @ y, 01 PRINT TO oPrn TEXT ALLTRIM(oQryPagCon:observa) ;
              SIZE 5.8,1 CM FONT oFont LASTROW nRow
           y := nRow
           IF y > 20
              @ 22.5, 01 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA" SIZE 10,.5 CM FONT oFont  
              ENDPAGE
              PAGE
                 @ 0,0 PRINT TO oPrn IMAGE "fondorec.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY       
                 oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                 oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                 oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente    
                 oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
                 @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                        SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                              SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                              SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 
                 oPrn:CmSay( 2  , 11, "RECIBO", oFont1 )       
                 oPrn:CmSay( 2.5, 11, "Nro de recibo:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
                 oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

                 oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                 oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                 oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                      

                 
                 @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPag:cuit ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:nombre) ;
                            SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPag:coniva] ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 nRow := IF(nRow<6,6,nRow)
                 @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPag:direccion) + " " + ;
                                                         ALLTRIM(oQryPag:localidad) ;
                            SIZE 8,1 CM FONT oFont ALIGN "L"                 
                 y := 8
                 oPrn:CmBox( y, .5, y+.5, 20.5 ) // Box titulos   
                 @ y, 01 PRINT TO oPrn TEXT "Forma de pago" ;
                        SIZE 12,.5 CM FONT oFont ALIGN "L"       
                 @ y, 14 PRINT TO oPrn TEXT "Importe" ;
                        SIZE 3,.5 CM FONT oFont ALIGN "R"
                 y := y + 1   
           ENDIF   
           oQryPagCon:SKIP()           
       ENDDO
	     y := y + .5
       @ y, 1 PRINT TO oPrn TEXT oQryPag:observa SIZE 18,1 CM FONT oFont
       @ 22.5, 1 PRINT TO oPrn TEXT "Su pago      $:" + STR(oQryPag:total,12,2) ;
              SIZE 10,.5 CM FONT oFont3 ALIGN "L"
       @ 22.5, 12 PRINT TO oPrn TEXT REPLICATE("_",45) ;
              SIZE 9,.5 CM FONT oFont3 ALIGN "L"
       @ 23, 12 PRINT TO oPrn TEXT "Por "+oApp:nomb_emp ;
              SIZE 9,.5 CM FONT oFont3 ALIGN "L"
       y := y + 1
       @ 23, 01 PRINT TO oPrn TEXT "Recibimos de " + ALLTRIM(oQryPag:nombre) + " la " +;
                " suma de Pesos: "+ Letra(oQryPag:total) + " ($"+STR(oQryPag:total)+")"+;
                " en concepto de los comprobantes antes mencionados." ;
              SIZE 10.8,3 CM FONT oFont         
	   ENDPAGE
   NEXT x
   ENDPRINT
RETURN nil