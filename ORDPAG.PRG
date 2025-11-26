#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** Pagos a proveedores - ordenes de pago
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot, mfecha, manticipo, mcodpro, mentrega, cDestinoMail,;
       oBrw, oQry, lEdita, oQryBan, oQryPro, oQryCue,mobserva,;
       lMostrarSis,lReten,;  //VARIABLE QUE DICE SI MUESTRA SISTEMA O DEMO / VARIABLE PARA CALCULAR O NO RETENCIONES
       lACuenta,; //LOGICA QUE ME HABILITA EL BOTON PARA PAGO A CUENTA
       oBrwCheT,oQryCheT,;
       oBrwCheP,oQryCheP,;
       nEfectivo,nTransferencia,nCheqT,nCheqP,nAnticipo,nFaltante,nTotal,nTotal1,nMPago,; //FORMAS DE PAGO
       nReten1,nReten2,nReten3,nIndice,nRetencion1,nRetencion3,nNetoGan,nNetoGanTot,nReten3Tot //PARA CALCULAR LAS RETENCIONES
PROCEDURE ordpag(cPermisos,nCodpro)
LOCAL oFont, oFo1,  oSay1, mnompro, mrta := .f.
DEFAULT nCodPro := 0
oGet := ARRAY(23)
oBot := ARRAY(05)
manticipo := 0
mentrega  := 0
mcodpro := nCodPro
lEdita := .t.
mfecha  := DATE()
mobserva:=SPACE(255)

IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    RETURN
  ENDIF
ENDIF

nEfectivo:=0
nTransferencia:=0
nCheqT :=0
nCheqP :=0
nReten1:=0
nReten2:=0
nReten3:=0
nTotal :=0 
nTotal1 :=0
nAnticipo :=0
nFaltante :=0
lMostrarSis:= .t.
nIndice := 1
nRetencion1:= 0
nRetencion3:= 0
nNetoGan:= 0
nNetoGanTot:= 0
nReten3Tot:=0
nMPago := 0
lACuenta:=.f.
lReten:= IF(oApp:usar_reten_gan .or. oApp:usar_reten_iibb .or. oApp:usar_reten_iva,.F.,.T.) 

// TABLA TEMPORAL DE DEUDA
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_ordpag` ("+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;
                           "`letra` VARCHAR(1) NOT NULL,"+;
                           "`numcomp` VARCHAR(13) NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`saldo` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`pagado` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`saldonue` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`neto` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`netogan` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "`aplicado` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;
                           "PRIMARY KEY (ticomp,letra,numcomp) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_ordpag")
oApp:oServer:NextResult()

// TABLA TEMPORAL DE CHEQUES DE TERCEROS
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_chequeT` ("+;
                           "`tilde` tinyint(1) NOT NULL DEFAULT 0,"+;
                           "`NOMBAN` varchar(30) NOT NULL ,"+;
                           "`NUMBAN` int(6) NOT NULL DEFAULT 1,"+;
                           "`NUMCHE` int(10) NOT NULL DEFAULT 0,"+;
                           "`FECING` date DEFAULT NULL,"+;
                           "`FECVTO` date DEFAULT NULL,"+;
                           "`IMPORTE` decimal(12,2) DEFAULT 0,"+;
                           "PRIMARY KEY (numban,numche) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_chequeT")
oApp:oServer:NextResult()  


oQryCheT := oApp:oServer:Query("SELECT * FROM transi_chequeT")  


// TABLA TEMPORAL DE CHQUES PROPIOS
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_chequeP` ("+;
                           "`NOMBAN` varchar(30) NOT NULL ,"+;
                           "`NUMBAN` int(6) NOT NULL DEFAULT 1,"+;
                           "`NUMCHE` int(10) NOT NULL DEFAULT 0,"+;
                           "`FECEMI` date DEFAULT NULL,"+;
                           "`FECVTO` date DEFAULT NULL,"+;
                           "`IMPORTE` decimal(12,2) DEFAULT 0,"+;
                           "PRIMARY KEY (numban,numche) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_chequeP")
oApp:oServer:NextResult()

oQryCheP := oApp:oServer:Query("SELECT * FROM transi_chequeP")

oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,saldo,retencio,cuit,direccion,localidad,retiva,telefono,gasto,exgana,inactivo FROM ge_"+oApp:cId+"provee")
oQryBan := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"bancos")
oQryCue := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cuentas")

DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM transi_ordpag ORDER BY fecha")
   DEFINE FONT oFont NAME "ARIAL" SIZE 08,-12 BOLD 
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE DIALOG oDlg RESOURCE "ORDPAG" OF oApp:oWnd TITLE "Ordenes de pago"
    oDlg:lHelpIcon := .f.
    REDEFINE SAY oSay1 PROMPT "Proveedor:" ID 111 OF oDlg
    REDEFINE GET oGet[1] VAR mcodpro  ID 112 OF oDlg PICTURE "99999";
             VALID(ValidaProvee(oGet));
             ACTION (oGet[01]:cText:= 0, ValidaProvee(oGet)) BITMAP "BUSC1" WHEN(lEdita)
    REDEFINE GET oGet[2] VAR mnompro  ID 113 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR mfecha ID 114 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[4] VAR mentrega  ID 116 OF oDlg PICTURE "999999999.99" VALID(IF(lEdita,.t.,(Mostrar()=.t. .and. oBrw:SetFocus()=nil)))
    REDEFINE GET oGet[5] VAR manticipo ID 117 OF oDlg PICTURE "999999999.99" WHEN(.f.)
    REDEFINE CHECKBOX oGet[16] VAR lMostrarSis ID 4001 OF oDlg ON CHANGE ValidaProvee(oGet) WHEN(lEdita) 
    REDEFINE BUTTON oBot[1] ID 115 OF oDlg ACTION (IF(Mostrar(),oBrw:SetFocus(),oGet[1]:SetFocus())) WHEN(lEdita)
    IF oApp:usar_reten_gan .or. oApp:usar_reten_iibb .or. oApp:usar_reten_iva
       REDEFINE CHECKBOX oGet[22] VAR lReten ID 4007 OF oDlg WHEN(lEdita) 
    ENDIF
    REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ticomp","letra","numcomp","fecha","saldo","pagado","saldonue","Importe","aplicado";
              HEADERS "Tipo","L","Nro. Compr.","Fecha","Saldo","Pagado","Nuevo Saldo","Importe","Aplicado" FOOTERS;
              SIZES 30,20,95,75,70,70,70,70,70  ID 20 OF oDlg       
    oBrw:aCols[5]:nFooterType := AGGR_SUM
    oBrw:aCols[6]:nFooterType := AGGR_SUM
    oBrw:aCols[7]:nFooterType := AGGR_SUM
    oBrw:aCols[8]:nFooterType := AGGR_SUM
    oBrw:aCols[9]:nFooterType := AGGR_SUM
    oBrw:aCols[6]:lAutoSave := .t.
    oBrw:aCols[6]:nEditType := EDIT_GET  
    //oBrw:aCols[6]:bEditValid  := {|oGet, oCol| ControlSaldo(oGet:value,EVAL(oBrw:aCols[5]:bEditValue))} 
    oBrw:aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaSaldo(xval)}  
    oBrw:aCols[6]:bOnChange := {|| oBot[3]:SetFocus(),oBrw:SetFocus(),mentrega:=oApp:oServer:Query("SELECT SUM(pagado) AS suma FROM transi_ordpag"):suma-nAnticipo,oGet[4]:Refresh()}
    PintaBrw(oBrw,0)    


    REDEFINE XBROWSE oBrwCheT DATASOURCE oQryCheT;
              COLUMNS "tilde","nomban","numche","fecvto","importe";
              HEADERS "","Banco","Numero","Vto.","Importe" FOOTERS;
              SIZES 30,180,50,70,65,70 ID 10 OF oDlg AUTOSORT
    PintaBrw(oBrwCheT,0)
    oBrwCheT:aCols[1]:SetCheck(nil,.f.)   
    oBrwCheT:aCols[1]:bLDClickData := {|| (CambiaChek(oQryCheT,oBrwCheT),oBot[3]:SetFocus(),oBrwCheT:SetFocus()) }
    oBrwCheT:aCols[1]:nEditType := 1
    oBrwCheT:aCols[1]:bEditValue := { || IF(oQryCheT:tilde,.t.,.f.)}

    REDEFINE XBROWSE oBrwCheP DATASOURCE oQryCheP;
              COLUMNS "nomban","numche","fecvto","importe";
              HEADERS "Cuenta","Numero","Vto.","Importe" FOOTERS;
              SIZES 200,60,70,65,70 ID 30 OF oDlg AUTOSORT
    oBrwCheP:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(DelCheqP(),oBrwCheP:Refresh(),CalcTot()),)}
    PintaBrw(oBrwCheP,0)

    REDEFINE GET oGet[06] VAR nEfectivo      ID 200 OF oDlg PICTURE "999999999.99"
    REDEFINE GET oGet[07] VAR nTransferencia ID 201 OF oDlg PICTURE "999999999.99"
    REDEFINE GET oGet[08] VAR nCheqT         ID 202 OF oDlg PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[09] VAR nCheqP         ID 203 OF oDlg PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[10] VAR nReten1        ID 204 OF oDlg PICTURE "99999999.99" WHEN(CalculaRet1())
    REDEFINE GET oGet[18] VAR nIndice        ID 4003 OF oDlg PICTURE "99.9999" WHEN(oApp:usar_reten_iibb)
    REDEFINE GET oGet[19] VAR nRetencion1     ID 4004 OF oDlg PICTURE "999.999"    WHEN(.F.)
    REDEFINE GET oGet[11] VAR nReten2        ID 205 OF oDlg PICTURE "999999999.99" WHEN(CalculaRet2())
    REDEFINE GET oGet[20] VAR nReten3        ID 4005 OF oDlg PICTURE "999999999.99" WHEN(CalculaRet3())
    REDEFINE GET oGet[21] VAR nRetencion3    ID 4006 OF oDlg PICTURE "999.999" WHEN(.F.)
    REDEFINE GET oGet[12] VAR nAnticipo      ID 206 OF oDlg PICTURE "999999999.99";
                 VALID(nAnticipo <= manticipo  );
                 WHEN(manticipo>0)
    REDEFINE GET oGet[23] VAR nMPago      ID 4008 OF oDlg PICTURE "999999999.99"



    REDEFINE GET oGet[13] VAR mobserva ID 4002 OF oDlg PICTURE "@S25"              
    REDEFINE GET oGet[14] VAR nFaltante ID 121 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())
    REDEFINE GET oGet[15] VAR nTotal ID 122 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())
    REDEFINE GET oGet[17] VAR nTotal1 ID 123 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "999999999.99";
                 WHEN(CalcTot())

    REDEFINE BUTTON oBot[2] ID 102 OF oDlg ACTION (Grabar()) WHEN( (oApp:oServer:Query("SELECT COUNT(*) AS suma FROM transi_ordpag WHERE pagado <> 0"):suma > 0;
                                                                                      .AND. ROUND(nFaltante,2) <= 0) .OR. lACuenta)
    REDEFINE BUTTON oBot[5] ID 105 OF oDlg ACTION (AddCheqP(oDlg),oBrwCheP:Refresh())
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg ACTION Cancela()
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
   ACTIVATE DIALOG oDlg CENTER ON INIT (oGet[16]:Hide())
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)
oQryPro:End()
oFont:End()
oFo1:End()
RETURN

******************************************************************************************************************************
**** CALCULAR LAS RETENCIONES DE LAS FACTURAS PAGADAS
STATIC FUNCTION CalculaRet1()
IF lMostrarSis
  IF !oQryPro:gasto .and. !lReten .and. oApp:usar_reten_iibb
	   oGet[10]:cText:= ROUND(oApp:oServer:Query("SELECT SUM(neto) AS suma FROM transi_ordpag WHERE importe = saldo AND pagado <> 0"):suma * (oQryPro:retencio/100) * nIndice,2)
  ENDIF
ENDIF
RETURN .F.

******************************************************************************************************************************
**** CALCULAR LAS RETENCIONES DE IVA DE LAS FACTURAS PAGADAS
STATIC FUNCTION CalculaRet2()
IF lMostrarSis
  IF !oQryPro:gasto .and. !lReten .and. oApp:usar_reten_iva
     oGet[11]:cText:= ROUND(oApp:oServer:Query("SELECT SUM(neto) AS suma FROM transi_ordpag WHERE importe = saldo AND pagado <> 0"):suma * (oQryPro:retiva/100) ,2)
  ENDIF
ENDIF
RETURN .F.

******************************************************************************************************************************
**** CALCULAR LAS RETENCIONES DE LAS FACTURAS PAGADAS
STATIC FUNCTION CalculaRet3()
LOCAL nNetoPagado:=0,oQryAux,nNetoAcumulado, oQryVariables
IF lMostrarSis
    IF !oQryPro:gasto .and. !lReten .and. !oQryPro:exgana .and. oApp:usar_reten_gan
        oQryAux:= oApp:oServer:Query("SELECT * FROM transi_ordpag WHERE pagado <> 0")
        oQryVariables := oApp:oServer:Query("SELECT * FROM bcn_config.variables_globales LIMIT 1")
        oQryAux:GoTop()
        DO WHILE !oQryAux:EOF()
           IF oQryAux:importe = oQryAux:pagado 
           	  nNetoPagado:= nNetoPagado + oQryAux:netogan
           ELSE 
           	  nNetoPagado:= nNetoPagado + (oQryAux:netogan / oQryAux:importe) * oQryAux:pagado
           ENDIF
           oQryAux:Skip()
        ENDDO
        //100000 DE MINIMO Y 2% DE RETENCION
        nNetoAcumulado:= oApp:oServer:Query("SELECT SUM(of.netogan) AS suma FROM ge_"+oApp:cId+"ordfac of LEFT JOIN ge_"+oApp:cId+"ordpag op ON op.numero = of.numero "+;
        	                                "WHERE op.proveedor = "+ClipValue2Sql(oQryPro:codigo)+" "+;
        	                                "AND MONTH(of.fecha) = MONTH(CURDATE()) AND YEAR(op.fecha) = YEAR(CURDATE())"):suma 
        IF nNetoAcumulado + nNetoPagado > oQryVariables:minimo_gana
           IF nNetoAcumulado < oQryVariables:minimo_gana
              oGet[20]:cText:=  ROUND((nNetoAcumulado + nNetoPagado - oQryVariables:minimo_gana) * oQryVariables:alicuota_gana,2)
           ELSE
              oGet[20]:cText:= ROUND(nNetoPagado * oQryVariables:alicuota_gana,2)
           ENDIF
           oGet[21]:cText:= oQryVariables:alicuota_gana * 100
        ELSE
           oGet[20]:cText:= 0
           oGet[21]:cText:= 0
        ENDIF
        nNetoGan:= nNetoPagado
        nNetoGanTot:= nNetoAcumulado
        nReten3Tot:= oApp:oServer:Query("SELECT SUM(reten) AS suma FROM ge_"+oApp:cId+"ordretgan WHERE codpro = "+ClipValue2Sql(oQryPro:codigo)+" "+;
        	                            "AND MONTH(fecha) = MONTH(CURDATE()) AND YEAR(fecha) = YEAR(CURDATE())"):suma
    ENDIF
ENDIF
RETURN .F.


******************************************************************************************************************************
********* TRAIGO LOS DATOS DEL PROVEEDOR ELEGIDO 
STATIC FUNCTION ValidaProvee(oGet)

oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,saldo,retencio,cuit,direccion,localidad,retiva,gasto,exgana,inactivo FROM ge_"+oApp:cId+"provee WHERE codigo = " +ClipValue2Sql(mcodpro))
IF oQryPro:RecCount() = 0 
   BuscarArt(oQryPro,oDlg,oGet[01])
ENDIF
oGet[02]:cText:= oQryPro:nombre 
oGet[05]:cText:= oQryPro:saldo //IF(lMostrarSis,oQryPro:saldo,oQryPro:saldod) 
oGet[12]:cText:= oQryPro:saldo //IF(lMostrarSis,oQryPro:saldo,oQryPro:saldod) 
oGet[19]:cText:= IF(oQryPro:gasto,0,oQryPro:retencio)


IF lMostrarSis
   oDlg:Gradient({ { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } })
   oDlg:Refresh()
ELSE 
   oDlg:Gradient({ { 1, RGB( 240,128,128 ),RGB( 237, 242, 248 ) } })
   oDlg:Refresh()
ENDIF

RETURN .t.


***********************************************************************************************************************************
******* CALCULO DE TOTALES
STATIC FUNCTION CalcTot()
oGet[08]:cText:= oApp:oServer:Query("SELECT SUM(importe) AS suma FROM transi_chequeT WHERE tilde = 1"):suma
oGet[09]:cText:= oApp:oServer:Query("SELECT SUM(importe) AS suma FROM transi_chequeP "):suma
oGet[15]:cText:= oGet[6]:value + oGet[7]:value + oGet[8]:value + oGet[9]:value + oGet[10]:value + oGet[11]:Value + oGet[12]:Value + oGet[20]:Value + oGet[23]:Value
oGet[17]:cText:= oBrw:aCols[6]:nTotal 
oGet[14]:cText:= oGet[17]:value - oGet[15]:value 

RETURN .f.


******************************************************************************************************************************
************** GRABAR EL PAGO 
STATIC FUNCTION Grabar()
LOCAL nOrden:=0,oError,mRta:=.f.,nCodCue:=0,nNumOpe:=0,cObserva:=SPACE(255),;
      nNumDep,lCuenta:=.f., nNumRet := 0, nNumRet1 := 0, nNumRet2 := 0,nMaximo, nNuevoSaldo := 0
IF oBrw:aCols[6]:nTotal <= 0 .AND. oApp:oServer:Query("SELECT ticomp FROM transi_ordpag WHERE pagado <> 0"):RecCount()=0 ;
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

IF ROUND(nFaltante,2) < 0
   IF !Avisar()
      RETURN .f.
   ENDIF
ENDIF

TRY 
   nNuevoSaldo := oBrw:aCols[5]:nTotal -;
                  (nEfectivo+nTransferencia+nCheqP+nCheqT+nReten1+nReten2+nReten3+nMPago) - nAnticipo
   mobserva := ALLTRIM(mobserva) + IF(nNuevoSaldo <> 0 ," - (Saldo de su cuenta: $ "+STR(nNuevoSaldo,15,2)+")","")
   oApp:oServer:BeginTransaction()
   nMaximo:= oApp:oServer:Query("SELECT MAX(numeroop)+1 AS num FROM ge_"+oApp:cId+"ordpag WHERE demo="+IF(lMostrarSis,"0","1")):num
     ** Agrego pago 
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordpag " + ;
                          " (proveedor, total, facturas, observa, fecha,caja, usuario,fecmod,ip, demo,numeroop) VALUES "+;
                         " ("+;
                             ClipValue2Sql(mcodpro)+","+;
                             ClipValue2Sql(nEfectivo+nTransferencia+nCheqP+nCheqT+nReten1+nReten2+nReten3+nMPago)+","+;
                             ClipValue2Sql(oBrw:aCols[6]:nTotal)+","+;
                             ClipValue2Sql(mobserva)+","+;
                             ClipValue2Sql(mfecha)+","+;
                             ClipValue2Sql(oApp:prefijo)+","+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2Sql(DATE())+","+;
                             ClipValue2Sql(oApp:cIp)+","+;
                             IF(lMostrarSis,"0","1")+","+;
                             ClipValue2Sql(nMaximo)+")")
     nOrden:= oApp:oServer:Query("SELECT MAX(numero) AS orden FROM ge_"+oApp:cId+"ordpag"):orden

     ** Actualizo saldos de facturas
     oQry:GoTop()
     DO WHILE !oQry:Eof()
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"compras SET saldo = " + ClipValue2Sql(ABS(oQry:saldonue)) +","+ ;
                                " estado = "+ ClipValue2Sql(IF(oQry:saldonue=0,"P","I"))+;
                                " WHERE tipocomp = " + ClipValue2Sql(oQry:ticomp) +;
                                " AND   letra    = " + ClipValue2Sql(oQry:letra) +;
                                " AND   numfac   = " + ClipValue2Sql(oQry:numcomp) +;
                                " AND   codpro   = " + ClipValue2Sql(mcodpro) )   
        IF oQry:pagado <> 0
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordfac SET numero = "+ ClipValue2Sql(nOrden)+","+;
                              "tipocomp = "+ ClipValue2Sql(oQry:ticomp)+","+;
                              "letra = "+ ClipValue2Sql(oQry:letra)+","+;
                              "numfac = "+ ClipValue2Sql(oQry:numcomp)+","+;
                              "fecha = "+ ClipValue2Sql(mfecha)+","+;
                              "importe = "+ClipValue2Sql(oQry:pagado)+","+;
                              "netogan = "+ClipValue2Sql((oQry:netogan/oQry:importe )*oQry:pagado)+","+;
                              "neto = "+IF(oQry:saldo=oQry:importe,ClipValue2Sql(oQry:neto),"0"))              
        ENDIF   
        oQry:Skip()
     ENDDO
     
     ** Grabo las formas de pago
     // INGRESO CONCEPTO EFECTIVO
     IF nEfectivo > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                               "codcon  = 1, "+;
                                               "importe = "+ ClipValue2Sql(nEfectivo)+","+;
                                               "observa = 'EFECTIVO'")
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"usuarios SET saldo = saldo - "+ClipValue2Sql(nEfectivo)+" "+;
                             "WHERE usuario = "+ClipValue2Sql(oApp:usuario))
     ENDIF
     
     // INGRESO CONCEPTO TRANSFERENCIA
     IF nTransferencia > 0
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
                            ClipValue2SQL(nTransferencia)+")")
        nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM ge_"+oApp:cId+"deposito"):numero 
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ordpag SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nOrden))
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                               "codcon  = 2, "+;
                                               "importe = "+ ClipValue2Sql(nTransferencia)+","+;
                                               "observa = 'TRANSFERENCIA'")
     ENDIF

     // INGRESO CONCEPTO CHEQUES DE TERCEROS Y ACTUALIZO SU ESTADO
     IF nCheqT > 0
     oQryCheT:GoTop()
       DO WHILE !oQryCheT:Eof()
          IF oQryCheT:tilde = .t.
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                          "codcon  = 3, "+;
                                                           "importe = "+ ClipValue2Sql(oQryCheT:importe)+","+;
                                                           "observa = '"    + ALLTRIM(oQryCheT:nomban)+;
                                                                     " Ch. "+ STR(oQryCheT:numche,10)+;
                                                                     " Vto "+ DTOC(oQryCheT:fecvto)+"'")
              oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"cheter SET estado = 'E',"+;
                                                     "codpro = "+ClipValue2Sql(mcodpro)+","+;
                                                     "orden  = "+ClipValue2Sql(nOrden)+" "+;
                                   "WHERE numban = " + ClipValue2Sql(oQryCheT:numban) +" "+;
                                   "AND   numche = " + ClipValue2Sql(oQryCheT:numche) )
          ENDIF
       oQryCheT:Skip()
       ENDDO
     ENDIF

     // INGRESO CONCEPTO CHEQUES PROPIOS Y LOS DOY DE ALTA COMO ENTREGADOS
     IF nCheqP > 0
     oQryCheP:GoTop()
       DO WHILE !oQryCheP:Eof()
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                          "codcon  = 4, "+;
                                                           "importe = "+ ClipValue2Sql(oQryCheP:importe)+","+;
                                                           "observa = 'CTA "+ ALLTRIM(oQryCheP:nomban)+;
                                                                     " Ch. "+ STR(oQryCheP:numche,10)+;
                                                                     " Vto "+ DTOC(oQryCheP:fecvto)+"'")
       oQryCheP:Skip()
       ENDDO
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"chepro (numban,numche,fecemi,fecvto,importe,orden,codpro,estado,usuario,fecmod,ip) "+;
                                   "( SELECT numban,numche,fecemi,fecvto,importe," +;
                                   ClipValue2Sql(nOrden) + "," + ClipValue2Sql(mcodpro) +",'E',"+ClipValue2Sql(oApp:usuario)+","+;
                                   ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+" "+;
                                   "FROM transi_chequeP)")
     ENDIF

     // INGRESO CONCEPTOS DE RETENCIONES                                   VER CON CESAR!!! SEPARAR LAS RETENCIONES COMPARAR CON LO DE COMPRAS
     IF nReten1 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                    "codcon  = 5, "+;
                                                    "importe = "+ ClipValue2Sql(nReten1)+","+;
                                                    "observa = 'RETENCIONES II.BB'")
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordret SET numero  = " + ClipValue2Sql(nOrden)+","+;
        	                                        "porcentaje = "+ ClipValue2Sql(oQryPro:retencio)+","+;
                                                    "indice = "+ ClipValue2Sql(nIndice)+","+;
                                                    "importe = "+ ClipValue2Sql(nReten1))
        nNumRet := oApp:oServer:Query("SELECT MAX(id) as numret FROM ge_"+oApp:cId+"ordret"):numret
     ENDIF
     IF nReten2 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                    "codcon  = 5, "+;
                                                    "importe = "+ ClipValue2Sql(nReten2)+","+;
                                                    "observa = 'RETENCIONES I.V.A'")
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordretiva SET numero  = " + ClipValue2Sql(nOrden)+","+;
        											"porcentaje = "+ ClipValue2Sql(oQryPro:retiva)+","+;
                                                    "importe = "+ ClipValue2Sql(nReten2))
        nNumRet1 := oApp:oServer:Query("SELECT MAX(id) as numret FROM ge_"+oApp:cId+"ordretiva"):numret
     ENDIF
     IF nReten3 > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                    "codcon  = 5, "+;
                                                    "importe = "+ ClipValue2Sql(nReten3)+","+;
                                                    "observa = 'RETENCIONES GANANCIAS'")
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordretgan SET numero  = " + ClipValue2Sql(nOrden)+","+;
        											"codpro = "+ ClipValue2Sql(oQryPro:codigo)+","+;
        											"fecha = "+ ClipValue2Sql(DATE())+","+;
        											"neto = "+ ClipValue2Sql(nNetoGan)+","+;
        											"netototal = "+ ClipValue2Sql(nNetoGanTot)+","+;
        											"minimo = 100000,"+;
        											"porcentaje = 2.0,"+;
        											"reten = "+ ClipValue2Sql(nReten3)+","+;
                                                    "retentotal = "+ ClipValue2Sql(nReten3Tot))
        nNumRet2 := oApp:oServer:Query("SELECT MAX(id) as numret FROM ge_"+oApp:cId+"ordretgan"):numret
     ENDIF

     // INGRESO MONTO PAGADO POR ANTICIPO                                  
     IF nAnticipo > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                    "codcon  = 7, "+;
                                                    "importe = "+ ClipValue2Sql(nAnticipo)+","+;
                                                    "observa = 'ANTICIPO'")
     ENDIF
     IF nMPago > 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                                    "codcon  = 8, "+;
                                                    "importe = "+ ClipValue2Sql(nMPago)+","+;
                                                    "observa = 'MERCADO PAGO'")
     ENDIF

     // ACTUALIZO SALDO DEL PROVEEDOR                       
     IF lMostrarSis
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET saldo = saldo -" +ClipValue2Sql(nAnticipo)+" + "+ClipValue2Sql(ABS(nFaltante))+" "+;
                             "WHERE codigo = "+ClipValue2Sql(mcodpro))
     ELSE
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET saldod = saldod -" +ClipValue2Sql(nAnticipo)+" + "+ClipValue2Sql(ABS(nFaltante))+" "+;
                             "WHERE codigo = "+ClipValue2Sql(mcodpro))
     ENDIF

  oApp:oServer:CommitTransaction()
    CATCH oError
    ValidaError(oError)
    RETURN .f.
END TRY

mobserva:=SPACE(255)
mrta := MsgYesNo("Desea Imprimir la Orden Pagada","Atencion")
IF mrta   
   oPago(nOrden,.f.)
ENDIF
IF nNumRet > 0 .and.  MsgYesNo("Desea Imprimir el comprobante de Retencion IIBB?","Atencion")
   ReteIngBru(nNumRet)
ENDIF
IF nNumRet1 > 0 .and.  MsgYesNo("Desea Imprimir el comprobante de Retencion IVA?","Atencion")
   ReteIva(nNumRet1)
ENDIF
IF nNumRet2 > 0 .and.  MsgYesNo("Desea Imprimir el comprobante de Retencion GANANCIAS?","Atencion")
   ReteGana(nNumRet2)
ENDIF
Cancela()
RETURN nil


STATIC FUNCTION Avisar()
LOCAL oBot := ARRAY(3), oForm, oFontGrande,acor,lRta:=.f.

DEFINE FONT oFontGrande NAME "TAHOMA" SIZE 12,-15


DEFINE DIALOG oForm TITLE "ATENCION!";
       FROM 05,15 TO 19,85 OF oDlg FONT oApp:oFont
   
   @ 05, 05 SAY "Se detecto un saldo a su favor."+CHR(10)+;
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
LOCAL base := oQry:GetRowObj(), lRet
IF base:saldo < 0
   IF ABS(n) <= ABS(base:saldo) .and. n <= 0
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
ELSE
   IF n <= base:saldo
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
ENDIF
IF !lRet
   
   MsgStop("No puede abonar mas de lo adeudado","Error")
   ELSE 
   base:pagado := n 
   base:saldonue := ABS(oQry:saldo-n) * IF(base:saldo<0,-1,1)
   oQry:oRow := base
   oQry:Save()
   oQry:Refresh()
ENDIF   
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
oQryCheT:Zap()
oBrwCheT:Refresh()
oQryCheP:Zap()
oBrwCheP:Refresh()
FOR i := 4 to 12 
   oGet[i]:cText:= 0
NEXT i
oGet[14]:cText:= 0
oGet[15]:cText:= 0
oGet[17]:cText:= 0
oGet[20]:cText:= 0
oGet[21]:cText:= 0
oGet[23]:cText:= 0
lEdita := .t.
lACuenta:=.F.
oGet[1]:SetFocus()
RETURN nil

*****************************************
** Cargar deuda
STATIC FUNCTION Mostrar()
LOCAL mentre := mentrega + nAnticipo
oQry:Zap()
oApp:oServer:Execute("INSERT INTO transi_ordpag (ticomp,letra,numcomp,fecha,saldo,pagado,saldonue,neto,importe,aplicado,netogan) "+;
                     "SELECT c.tipocomp AS ticomp,c.letra AS letra,c.numfac AS numcomp, c.fecfac AS fecha, "+;
                     " c.saldo * IF(c.tipocomp = 'NC', -1,1) AS saldo, "+;
                     " 0 as pagado, c.saldo * IF(c.tipocomp = 'NC', -1,1) AS saldonue, IF(c.saldo = c.importe,"+;
                          "(SELECT SUM(neto) FROM ge_"+oApp:cId+"compivadet WHERE codpro = c.codpro AND tipocomp = c.tipocomp AND letra = c.letra AND numfac = c.numfac),0) * IF(c.tipocomp = 'NC', -1,1),  "+;
                     " c.importe * IF(c.tipocomp = 'NC', -1,1), (c.importe - c.saldo)* IF(c.tipocomp = 'NC', -1,1),"+;
                     "(SELECT SUM(neto) FROM ge_"+oApp:cId+"compivadet WHERE codpro = c.codpro AND tipocomp = c.tipocomp AND letra = c.letra AND numfac = c.numfac) * IF(c.tipocomp = 'NC', -1,1) "+;
                     "FROM ge_"+oApp:cId+"compras c "+;
                     "WHERE c.codpro = " + ClipValue2Sql(mcodpro) + " AND " +;                     
                     " c.saldo > 0 ")
oApp:oServer:NextResult()
oQry:Refresh()
DO WHILE !oQry:Eof()
   IF oQry:ticomp = "NC"
      oQry:pagado   := oQry:saldo
      oQry:saldonue := 0
      mentre := mentre + ABS(oQry:saldo)
      oQry:Save()
   ENDIF   
   oQry:Skip()
ENDDO
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:ticomp <> "NC" .and. mentre > 0
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
IF oQry:nRecCount = 0 
   IF oQryPro:inactivo
      MsgStop("Proveedor sin deuda pendiente e Inactivo","Atencion!") 
      RETURN .f.
      ELSE 
      lACuenta:= MsgNoYes("Proveedor sin deuda pendiente ¿desea realizar un pago a cuenta?","Atencion!")
   ENDIF   
   ELSE
   lEdita := .f.
   lACuenta:=.f.
ENDIF

IF oQryCheT:reccount()=0
oApp:oServer:Execute("INSERT INTO transi_chequeT (tilde,numban,nomban,numche,fecing,fecvto,importe) "+;
                     "(SELECT 0,c.numban,b.nombre,c.numche,c.fecing,c.fecvto,c.importe FROM ge_"+oApp:cId+"cheter c "+;
                      "LEFT JOIN ge_"+oApp:cId+"bancos b ON b.codigo = c.numban "+;
                      "WHERE c.estado = 'C' and c.noorden = FALSE and c.demo = "+ClipValue2Sql(!lMostrarSis)+")")
oQryCheT:Refresh()
oBrwCheT:Refresh()
ENDIF

RETURN .t.

*************************************************
** Borrar cheques de Propios
STATIC FUNCTION DelCheqP(oWnd)
oQryCheP:Delete()
oQryCheP:Refresh()
RETURN nil


*************************************************
** Agregar cheques de propio
STATIC FUNCTION AddCheqP(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomCue := SPACE(30), cNomPro := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont
DO WHILE .T.
base := oQryCheP:GetBlankRow()
base:importe := 0
base:fecemi  := DATE()
base:fecvto  := DATE()
cNomPro      := oQryPro:nombre
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques propios" FROM 05,15 TO 19,66 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Cuenta:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryCue,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryCue,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 80 GET oGet2[2] VAR cNomCue OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(base:numche > 0) RIGHT
   @ 35, 50 GET oGet2[7] VAR base:fecemi   PICTURE "@D" PIXEL OF oDlg3 CENTER
   @ 50, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 VALID(base:fecvto >= base:fecemi) CENTER
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
oQryChe1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"chepro WHERE numban = " + ClipValue2Sql(base:numban) +;
                               " AND numche = " + ClipValue2Sql(base:numche) )
IF oQryChe1:nRecCount > 0
   MsgStop("Cheque ya existe", "Error")
   LOOP
ENDIF   
base:nomban:= cNomCue
oQryCheP:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryCheP:Save()
  oQryCheP:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


**********************************************
** Reimpresion de Op
PROCEDURE ReimpreOP()
LOCAL oDlg1, oFont,acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(4), oBot1, oBot2,;
      mrecibo := 0, mrecibo1 := 0, mrecibo2 := 0, mrecibo3 := 0
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reimprimir Orden de pago/Retencion" FROM 03,15 TO 15,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Orden Pago Nro:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Retencion IIBB Nro:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Retencion IVA Nro:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Retencion Gan. Nro:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mrecibo  PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(mrecibo1=0 .and. mrecibo2=0 .and. mrecibo3 = 0)
   @ 20, 65 GET oGet[2] VAR mrecibo1 PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(mrecibo=0  .and. mrecibo2=0 .and. mrecibo3 = 0)
   @ 35, 65 GET oGet[3] VAR mrecibo2 PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(mrecibo=0  .and. mrecibo1=0 .and. mrecibo3 = 0)
   @ 50, 65 GET oGet[4] VAR mrecibo3 PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(mrecibo=0  .and. mrecibo1=0 .and. mrecibo2 = 0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
DO CASE 
   CASE mrecibo > 0
        oPago(mrecibo,.f.)
   CASE mrecibo1 > 0
        ReteIngBru(mrecibo1)
   CASE mrecibo2 > 0
        ReteIva(mrecibo2)
   CASE mrecibo3 > 0
        ReteGana(mrecibo3)
ENDCASE  
RETURN 

**************************************************************
** Impresion del Retencion
PROCEDURE ReteIngBru(nNumero)
LOCAL oRep, nRow, nCol, oFont1, oFont2, i, oQryRetFac, oQryRetPro, mtotneto := 0,;
      aTipoIva :=  {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
                    "EXENTO         .","MONOTRIBUTO    .", "CONSUMIDOR FINAL"}
oQryRetPro    := oApp:oServer:Query( "SELECT p.nombre,p.direccion,p.localidad,p.cuit,p.coniva, p.mail,"+;
                                     "ore.id, ore.importe,ore.porcentaje,ore.indice,"+;
                                     "op.fecha, op.numero AS num "+;
                                     " FROM ge_"+oApp:cId+"ordret ore "+;
                                     " LEFT JOIN ge_"+oApp:cId+"ordpag op ON op.numero = ore.numero "+;
                                     " LEFT JOIN ge_"+oApp:cId+"provee p  ON op.proveedor = p.codigo "+;
                                     " WHERE ore.id = " + ClipValue2SQL(nNumero))
IF oQryRetPro:nRecCount = 0
   MsgStop("Orden de pago no existe!!","Error")
   RETURN 
ENDIF
oQryRetFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2SQL(oQryRetPro:num))
PRINT oRep NAME "Retencion ING. BRUTOS" PREVIEW MODAL      
      nRow = oRep:nVertRes() / 80
      nCol = oRep:nHorzRes() / 120
      DEFINE FONT oFont1 NAME "COURIER NEW" SIZE nRow*0.80,nCol*2.1 BOLD
      PAGE
        oApp:cDestinoMail := oQryRetPro:mail
        oRep:SayImage(0,0,"ARBA.JPG",oRep:nHorzRes(),oRep:nVertRes(), nil, .t.)        
        // Original
        oRep:Say(nRow*11.5,nCol*92,STRTRAN(STR(oQryRetPro:id,10)," ","0"),oFont1)
        oRep:Say(nRow*12.5,nCol*92,DTOC(oQryRetPro:fecha),oFont1)
        
        oRep:Say(nRow*27,nCol*26,oQryRetPro:nombre, oFont1)
        oRep:Say(nRow*28.7,nCol*26,oQryRetPro:cuit,oFont1)
        oRep:Say(nRow*30.4,nCol*26,aTipoIva[oQryRetPro:coniva],oFont1)
        oRep:Say(nRow*32,nCol*26,LEFT(oQryRetPro:direccion,25)+LEFT(oQryRetPro:localidad,20),oFont1)       
        oQryRetFac:GoTop()
        i := 1        
        DO WHILE !oQryRetFac:Eof()
           oRep:Say(nRow*(46+i),nCol*13,oQryRetFac:numfac,oFont1)
           oRep:Say(nRow*(46+i),nCol*67.2,"           "+STR(oQryRetFac:neto,14,2),oFont1)
           mtotneto := mtotneto + oQryRetFac:neto
           oQryRetFac:SKIP()
           i++
        ENDDO
        oRep:Say(nRow*(46+i),nCol*67.2,"Total Neto:"+STR(mtotneto,14,2),oFont1)

        oRep:Say(nRow*(63.5),nCol*89,STR(mtotneto*oQryRetPro:indice,12,2),oFont1)
        IF oQryRetPro:indice <> 1
           oRep:Say(nRow*(63.5),nCol*15,"Indice:"+STR(oQryRetPro:indice,8,4),oFont1)
        ENDIF
        oRep:Say(nRow*(66),nCol*98,STR(oQryRetPro:porcentaje,6,2),oFont1)
        oRep:Say(nRow*(69),nCol*89,STR(oQryRetPro:importe,12,2),oFont1)
      ENDPAGE
ENDPRINT   
oApp:cDestinoMail := ""
RETURN

**************************************************************
** Impresion del Retencion de ganancia
PROCEDURE ReteGana(nNumero)
LOCAL oRep, nRow, nCol, oFont1, oFont2, i, oQryRetFac, oQryRetPro, mtotneto := 0,;
      aTipoIva :=  {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
                    "EXENTO         .","MONOTRIBUTO    .", "CONSUMIDOR FINAL"}
oQryRetPro    := oApp:oServer:Query( "SELECT p.nombre,p.direccion,p.localidad,p.cuit,p.coniva, p.mail, "+;
                                     "ore.id, ore.reten,ore.porcentaje,"+;
                                     "op.fecha, op.numero AS num "+;
                                     " FROM ge_"+oApp:cId+"ordretgan ore "+;
                                     " LEFT JOIN ge_"+oApp:cId+"ordpag op ON op.numero = ore.numero "+;
                                     " LEFT JOIN ge_"+oApp:cId+"provee p  ON op.proveedor = p.codigo "+;
                                     " WHERE ore.id = " + ClipValue2SQL(nNumero))
IF oQryRetPro:nRecCount = 0
   MsgStop("Orden de pago no existe!!","Error")
   RETURN 
ENDIF
oQryRetFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2SQL(oQryRetPro:num))
PRINT oRep NAME "Retencion GANACIAS" PREVIEW MODAL      
      nRow = oRep:nVertRes() / 80
      nCol = oRep:nHorzRes() / 120
      DEFINE FONT oFont1 NAME "COURIER NEW" SIZE nRow*0.80,nCol*2.1 BOLD
      PAGE
        oApp:cDestinoMail := oQryRetPro:mail
        oRep:SayImage(0,0,"GANA.JPG",oRep:nHorzRes(),oRep:nVertRes(), nil, .t.)        
        // Original
        oRep:Say(nRow*11.5,nCol*92,STRTRAN(STR(oQryRetPro:id,10)," ","0"),oFont1)
        oRep:Say(nRow*12.5,nCol*92,DTOC(oQryRetPro:fecha),oFont1)
        
        oRep:Say(nRow*27,nCol*26,oQryRetPro:nombre, oFont1)
        oRep:Say(nRow*28.7,nCol*26,oQryRetPro:cuit,oFont1)
        oRep:Say(nRow*30.4,nCol*26,aTipoIva[oQryRetPro:coniva],oFont1)
        oRep:Say(nRow*32,nCol*26,LEFT(oQryRetPro:direccion,25)+LEFT(oQryRetPro:localidad,20),oFont1)       
        oQryRetFac:GoTop()
        i := 1        
        DO WHILE !oQryRetFac:Eof()
           oRep:Say(nRow*(46+i),nCol*13,oQryRetFac:numfac,oFont1)
           oRep:Say(nRow*(46+i),nCol*67.2,"           "+STR(oQryRetFac:neto,14,2),oFont1)
           mtotneto := mtotneto + oQryRetFac:neto
           oQryRetFac:SKIP()
           i++
        ENDDO
        oRep:Say(nRow*(63.5),nCol*89,STR(mtotneto,12,2),oFont1)           
        oRep:Say(nRow*(69),nCol*89,STR(oQryRetPro:reten,12,2),oFont1)
      ENDPAGE
ENDPRINT  
oApp:cDestinoMail := "" 
RETURN

**************************************************************
** Impresion del Retencion de IVA
PROCEDURE ReteIva(nNumero)
LOCAL oRep, nRow, nCol, oFont1, oFont2, i, oQryRetFac, oQryRetPro, mtotneto := 0,;
      aTipoIva :=  {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
                    "EXENTO         .","MONOTRIBUTO    .", "CONSUMIDOR FINAL"}
oQryRetPro    := oApp:oServer:Query( "SELECT p.nombre,p.direccion,p.localidad,p.cuit,p.coniva, p.mail, "+;
                                     "ore.id, ore.importe,ore.porcentaje,"+;
                                     "op.fecha, op.numero AS num "+;
                                     " FROM ge_"+oApp:cId+"ordretiva ore "+;
                                     " LEFT JOIN ge_"+oApp:cId+"ordpag op ON op.numero = ore.numero "+;
                                     " LEFT JOIN ge_"+oApp:cId+"provee p  ON op.proveedor = p.codigo "+;
                                     " WHERE ore.id = " + ClipValue2SQL(nNumero))
IF oQryRetPro:nRecCount = 0
   MsgStop("Orden de pago no existe!!","Error")
   RETURN 
ENDIF
oQryRetFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2SQL(oQryRetPro:num))
PRINT oRep NAME "Retencion IVA" PREVIEW MODAL      
      nRow = oRep:nVertRes() / 80
      nCol = oRep:nHorzRes() / 120
      DEFINE FONT oFont1 NAME "COURIER NEW" SIZE nRow*0.80,nCol*2.1 BOLD
      PAGE
        oApp:cDestinoMail := oQryRetPro:mail
        oRep:SayImage(0,0,"IVA.JPG",oRep:nHorzRes(),oRep:nVertRes(), nil, .t.)        
        // Original
        oRep:Say(nRow*11.5,nCol*92,STRTRAN(STR(oQryRetPro:id,10)," ","0"),oFont1)
        oRep:Say(nRow*12.5,nCol*92,DTOC(oQryRetPro:fecha),oFont1)
        
        oRep:Say(nRow*27,nCol*26,oQryRetPro:nombre, oFont1)
        oRep:Say(nRow*28.7,nCol*26,oQryRetPro:cuit,oFont1)
        oRep:Say(nRow*30.4,nCol*26,aTipoIva[oQryRetPro:coniva],oFont1)
        oRep:Say(nRow*32,nCol*26,LEFT(oQryRetPro:direccion,25)+LEFT(oQryRetPro:localidad,20),oFont1)       
        oQryRetFac:GoTop()
        i := 1        
        DO WHILE !oQryRetFac:Eof()
           oRep:Say(nRow*(46+i),nCol*13,oQryRetFac:numfac,oFont1)
           oRep:Say(nRow*(46+i),nCol*67.2,"           "+STR(oQryRetFac:neto,14,2),oFont1)
           mtotneto := mtotneto + oQryRetFac:neto
           oQryRetFac:SKIP()
           i++
        ENDDO
        
        oRep:Say(nRow*(63.5),nCol*89,STR(mtotneto,12,2),oFont1)
        oRep:Say(nRow*(69),nCol*89,STR(oQryRetPro:importe,12,2),oFont1)
      ENDPAGE
ENDPRINT 
oApp:cDestinoMail := ""  
RETURN

**************************************************************
** Impresion del orden de pagos
FUNCTION oPago(nNumero)
LOCAL aiva := {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
               "EXENTO         .","MONOTRIBUTO    .", "CONSUMIDOR FINAL"},;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, oQryPag, oQryPagFac, config,;
      oQryPagCon, oQryRet, oQryPro, aCor,nSuma,nCodCon,;
      aConceptos:={"EFECTIVO","TRANSFERENCIAS","CHEQ. TERCEROS","CHEQ. PROPIOS",;
                   "RETENCIONES",SPACE(14),"ANTICIPOS","MERCADO PAGO"}
   oQryPag    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordpag WHERE numero = " + ClipValue2SQL(nNumero))
   oQryPagFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2SQL(nNumero))
   oQryPagCon := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ordcon WHERE numero = " + ClipValue2SQL(nNumero)+" ORDER BY codcon")
   oQryRet    := oApp:oServer:Query( "SELECT 'RET. IIBB N°' AS concepto,ID FROM ge_"+oApp:cId+"ordret WHERE numero = "+ClipValue2SQL(nNumero)+;
                                  " UNION "+;
                                  "SELECT 'RET. GAN. N°' AS concepto,ID FROM ge_"+oApp:cId+"ordretgan WHERE numero = "+ClipValue2SQL(nNumero)+;
                                  " UNION "+;
                                  "SELECT 'RET. IVA N°' AS concepto,ID FROM ge_"+oApp:cId+"ordretiva WHERE numero = "+ClipValue2SQL(nNumero))
   oQryPro := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee WHERE codigo = " + ClipValue2SQL(oQryPag:proveedor)) 
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
   
   PRINT oPrn NAME "Orden de pago" PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
   FOR x := 1 TO 2
     PAGE       
       @ 0,0 PRINT TO oPrn IMAGE "fondoop.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY  

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
       
       oPrn:CmSay( 2  , 11, "Orden de Pago", oFont1 )       
       oPrn:CmSay( 2.5, 11, "Nro de Orden de Pago:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
       oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

       oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
       oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
       oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
            

       
       @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
       @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPro:cuit ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
       @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
       @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:nombre) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
       @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
       @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPro:coniva] ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
       nRow := IF(nRow<6,6,nRow)
       @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
       @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:direccion) + " " + ;
                                               ALLTRIM(oQryPro:localidad) ;
                  SIZE 8,1 CM FONT oFont ALIGN "L"

       @ 8.2, 01 PRINT TO oPrn TEXT "Comprobante" ;
                SIZE 5,.5 CM FONT oFont ALIGN "L"         
       @ 8.2, 11 PRINT TO oPrn TEXT "Importe" ;
                SIZE 4,.5 CM FONT oFont ALIGN "R"
               
       y := 9.2
       oQryPagFac:GoTop()
       DO WHILE !oQryPagFac:Eof()           
          @ y, 01 PRINT TO oPrn TEXT oQryPagFac:numfac ;
                SIZE 5.8,.5 CM FONT oFont ALIGN "L"             
          @ y, 11 PRINT TO oPrn TEXT STR(oQryPagFac:importe,14,2) ;
                SIZE 4,.5 CM FONT oFont ALIGN "R"           
          y := y + .5
          IF y > 20
              @ 22.5, 01 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA" SIZE 10,.5 CM FONT oFont  
              ENDPAGE
              PAGE
                 @ 0,0 PRINT TO oPrn IMAGE "fondoop.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY     
                 oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                 oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                 oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                 //oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
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
                 
                 oPrn:CmSay( 2  , 11, "Orden de Pago", oFont1 )       
                 oPrn:CmSay( 2.5, 11, "Nro de Orden de Pago:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
                 oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

                 oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                 oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                 oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                      

                 
                 @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPro:cuit ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:nombre) ;
                            SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPro:coniva] ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 nRow := IF(nRow<6,6,nRow)
                 @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:direccion) + " " + ;
                                                         ALLTRIM(oQryPro:localidad) ;
                            SIZE 8,1 CM FONT oFont ALIGN "L"  LASTROW nRow
                y := nRow + 1           
          ENDIF    
          oQryPagFac:SKIP()           
       ENDDO
       @ y, 01 PRINT TO oPrn TEXT "Neto Pagado:" ;
                SIZE 5.8,.5 CM FONT oFont ALIGN "L"             
       @ y, 11 PRINT TO oPrn TEXT STR(oQryPag:total,14,2) ;
                SIZE 4,.5 CM FONT oFont ALIGN "R"           
       y := y + 1

       oPrn:CmBox( y, .5, y+.5, 20.5 ) // Box titulos   
       @ y, 01 PRINT TO oPrn TEXT "Forma de pago" ;
                SIZE 12,.5 CM FONT oFont ALIGN "L"       
       @ y, 14 PRINT TO oPrn TEXT "Importe" ;
                SIZE 4,.5 CM FONT oFont ALIGN "R"
       y := y + 0.5
       nSuma:=0
       nCodCon:=0
       oQryPagCon:GoTop()
       DO WHILE !oQryPagCon:Eof()
           IF nCodCon <> oQryPagCon:codcon
              IF nSuma > 0
                 @ y, 14 PRINT TO oPrn TEXT STR(nSuma,12,2) ;
                   SIZE 4,.5 CM FONT oFont ALIGN "R"  
                 @ y, 7 PRINT TO oPrn TEXT "SUBTOTAL "+aConceptos[nCodCon] ;
                   SIZE 6.8,.5 CM ALIGN "R" FONT oFont                   
                  y := y + .5                  
              ENDIF
              nSuma:= 0
              nCodCon:= oQryPagCon:codcon 
           ENDIF
           @ y, 14 PRINT TO oPrn TEXT STR(oQryPagCon:importe,12,2) ;
                SIZE 4,.5 CM FONT oFont ALIGN "R"  
           @ y, 01 PRINT TO oPrn TEXT ALLTRIM(oQryPagCon:observa) ;
                SIZE 12.8,.5 CM FONT oFont ALIGN "L"  
           y := y + .5
           IF y > 20
              @ 22.5, 01 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA" SIZE 10,.5 CM FONT oFont  
              ENDPAGE
              PAGE
                 @ 0,0 PRINT TO oPrn IMAGE "fondoop.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY     
                 oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                 oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                 oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                 //oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
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
                 
                 oPrn:CmSay( 2  , 11, "Orden de Pago", oFont1 )       
                 oPrn:CmSay( 2.5, 11, "Nro de Orden de Pago:"+STRTRAN(STR(nNumero,8)," ","0"),oFont)
                 oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryPag:fecha),oFont)

                 oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                 oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                 oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                      

                 
                 @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPro:cuit ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:nombre) ;
                            SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                 @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPro:coniva] ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                 nRow := IF(nRow<6,6,nRow)
                 @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                            SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                 @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPro:direccion) + " " + ;
                                                         ALLTRIM(oQryPro:localidad) ;
                            SIZE 8,1 CM FONT oFont ALIGN "L"  LASTROW nRow
                y := nRow + 1            
          ENDIF
           nSuma:= nSuma + oQryPagCon:importe
           oQryPagCon:SKIP()           
       ENDDO
       IF nSuma > 0
          @ y, 14 PRINT TO oPrn TEXT STR(nSuma,12,2) ;
                   SIZE 4,.5 CM FONT oFont ALIGN "R"  
          @ y, 8 PRINT TO oPrn TEXT "SUBTOTAL "+aConceptos[nCodCon] ;
                   SIZE 5.8,.5 CM ALIGN "R" FONT oFont                   
          y := y + .5
       ENDIF
       nSuma:= ""
       oQryRet:GoTop()
       DO WHILE !oQryRet:EOF()
          nSuma:= nSuma +ALLTRIM(oQryRet:concepto)+": "+ALLTRIM(STR(oQryRet:id,8))+" " 
          oQryRet:Skip()
       ENDDO
       @ y, 1 PRINT TO oPrn TEXT nSuma SIZE 18,1 CM FONT oFont3
       y := y + .5
       @ y, 1 PRINT TO oPrn TEXT oQryPag:observa SIZE 18,1 CM FONT oFont
       
       @ 22.5, 1 PRINT TO oPrn TEXT "Nuestro pago   $:" + STR(oQryPag:total,12,2) ;
                SIZE 10,.5 CM FONT oFont3 ALIGN "L"
       @ 22.5, 12 PRINT TO oPrn TEXT REPLICATE("_",45) ;
                SIZE 9,.5 CM FONT oFont3 ALIGN "L"
       @ 23, 12 PRINT TO oPrn TEXT "Por "+oQryPro:nombre ;
                SIZE 9,.5 CM FONT oFont3 ALIGN "L"
       y := y + 1
       @ 23, 01 PRINT TO oPrn TEXT "Recibimos de " + ALLTRIM(oApp:nomb_emp) + " la " +;
                  " suma de Pesos: "+ Letra(oQryPag:total) + " ($"+STR(oQryPag:total)+")"+;
                  " en concepto de pago de los comprobantes antes mencionados." ;
         SIZE 10.8,3 CM FONT oFont         
       //@ 25.5,.6 PRINT TO oPrn IMAGE "fondoop.jpg" SIZE 21, 3 CM 
       ENDPAGE
     NEXT x
     oApp:cDestinoMail := oQryPro:mail 
   ENDPRINT
oApp:cDestinoMail := ""
RETURN nil