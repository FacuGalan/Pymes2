#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"


************************************************************************************************
** VENTAS
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, nTipoEmp, nTipoFac, nTipoDoc, cVentana, oGet, oQryArt, oQryCli, oQryPar, oQryDet, oQryRub,;
       oBrw, oSay1,oSay3,cRemitos, oDlg,nCodCli,nTarjeta,nefectivo,oQryPun,nDescArt,nDescArt1,nLista,nConIva,;
       nEfecti, nTarjet, nTransfe, nCheque, nCtaCte, nMPago, nCuotas, nPuntoVta, cLetra,nLisPre,cObserva,nPorIva,cNumComp,;
       cDetArt, nDescuGen, nCodIva, nTotal, nForPag, nRubro, nDeuda,oQryChe,mpagado,manticipo,dFecha,cVendedor,nTipoCli,;
       nBorrarPend,lUsoPedido,oQryLisPre,aFormaNom,aFormaInc,nFormaPago, lAcopio, nBorrarPresu,lPedidoUsado,;
       lFacturaM , lFacturaD, cOrigenNC

PROCEDURE Ventas() 
LOCAL oBot := ARRAY(11), hHand , aTipoIva, aTipoDoc, cNomCli:=SPACE(30), cDireccion:=SPACE(30), cLocalidad:=SPACE(30),;
      cCUIT:=SPACE(13), nCodArt:=0, nCantidad:=0, nPunit:=0, nPtotal:=0, nNeto:=0, nImpInt:=0, nBultos := 0,;
      nIVA:=0, oFontLetra, oFontTotal,cDescu,oSay2,oQryUsua,aVendedores,cLisPre:="SIN LISTA ESPECIAL"+SPACE(31),;
      nNumFac:=0, nDNI := 0, nTiArt,oQryIvaT, cRubNom := SPACE(30),nIngBru:=0,nIngBruP:=0, cCodArtP := SPACE(30),oQryFormas,;
      oSay := ARRAY(2)
 cVentana := PROCNAME()     
 IF ASCAN(oApp:aVentanas,cVentana) > 0
     hHand := ASCAN(oApp:aVentanas,cVentana)
     oApp:oWnd:Select(hHand)
     oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
     RETURN
  ENDIF
  AADD(oApp:aVentanas,cVentana)
oQryUsua:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"vendedores ORDER BY nombre")
IF oApp:usua_es_vendedor
   cVendedor:= oApp:usuario
ELSE 
   cVendedor:= SPACE(50)
ENDIF
aVendedores:= {}
AADD(aVendedores,cVendedor)
oQryUsua:GoTop()
DO WHILE !oQryUsua:Eof()
   AADD(aVendedores,oQryUsua:nombre)
   oQryUsua:Skip()
ENDDO
manticipo:= 0
lFacturaM := .f.
lFacturaD := .f.
nCodCli:=0
oGet := ARRAY(48) 
aTipoiva  := {;
"1 IVA Responsable Inscripto",;
"2 IVA Responsable no Inscripto",;
"3 IVA no Responsable",;
"4 IVA Sujeto Exento",;
"5 Consumidor Final",;
"6 Responsable Monotributo",;
"7 Sujeto no Categorizado",;
"8 Proveedor del Exterior",;
"9 Cliente del Exterior",;
"10  IVA Liberado Ley Nº 19.640",;
"11  IVA Responsable Inscripto Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social",;
"15  IVA NO Alcanzado"}
  
  
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS ventas_det_H ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(500) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUP`  DECIMAL(5,2) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"`PCOSTO` DECIMAL(12,3) DEFAULT '0.00',";
    +"`IMPINT` DECIMAL(12,3) DEFAULT '0.00',";
    +"`BULTOS` DECIMAL(6,1) DEFAULT '0.0',";
    +"`ESPROMO` TINYINT(1) DEFAULT '0' NOT NULL, ";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
    //+"`COSTO` DECIMAL(10,2) DEFAULT '0.00', PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS precios_temp ";
    +"( `FORMAPAG` VARCHAR(50) NOT NULL, ";
    +"`INCREMENTO` DECIMAL(5,2) DEFAULT '0.00',";
    +"`IMPORTE` DECIMAL(12,2) DEFAULT '0.00' ";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE precios_temp")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS pedidos_temp ";
    +"( `ID` INT(10) NOT NULL, ";
    +"`TILDE` TINYINT(1),";
    +"`FECHA` DATE NOT NULL,";  
    +"`VENDEDOR` VARCHAR(15),";
    +"`PARAFECHA` DATE NOT NULL,";
    +"`OBSERVA` TEXT,";
    +"PRIMARY KEY (`ID`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

/*
oApp:oServer:Execute("INSERT INTO precios_temp (formapag,incremento,importe) "+;
                     "(SELECT nombre,incremento,0 FROM ge_"+oApp:cId+"forpag )")
*/
oQryFormas:= oApp:oServer:Query("SELECT nombre,incremento FROM ge_"+oApp:cId+"forpag ORDER BY codigo")
aFormaNom:={}
aFormaInc:={}
oQryFormas:GoTop()
DO WHILE !oQryFormas:eof()
  AADD(aFormaNom,oQryFormas:nombre)
  AADD(aFormaInc,oQryFormas:incremento)
  oQryFormas:Skip()
ENDDO
nFormaPago:=1
lAcopio := IF(FILE('.\ACOPIO.INI'),.T.,.f.)
oQryDet :=oApp:oServer:Query("SELECT * FROM ventas_det_H")
oQryDet:ZAP()

aTipoDoc := {"Factura","Nota de Débito","Nota de Crédito","Presupuesto","Remito"}
nTipoDoc := 1 
oQryRub :=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"rubros")
oQryPar := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip))
nTipoEmp := oQryPar:coniva
nTipoFac := oQryPar:factura
nTipoCli := 1
nLista:=1
nPuntoVta := oQryPun:caja
oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
oQryIvaT:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY tasa")
oQryLisPre:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre")

dFecha:= DATE()
nLisPre:=0
cObserva:=SPACE(255)
nPorIva:=21.00
nCodIva:= 5
nTiArt:=1
nDescuGen:=0
cDetArt:=SPACE(500)
nTotal:=0
nForPag:=2
nRubro := 1
nDeuda:= 0
nDescArt:=0
nDescArt1:=0
cRemitos:= SPACE(20)
cRubNom := SPACE(30)
cDescu:= "Descuento:"
nConIva:=1
nBorrarPend:=0
nBorrarPresu:=0
lUsoPedido:=.f.
lPedidoUsado:=.f.
cOrigenNC := ''

IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    cerrar()
    RETURN
  ENDIF
ENDIF

IF !ValidarSaldoCaja()
   cerrar()
   RETURN 
ENDIF   

 
      
  //FUENTES -----------------------------------------------
  DEFINE FONT oFontLetra NAME "ARIAL" SIZE 35,60
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
  cLetra := IF(oApp:tipo_iva<>6,"A","C")
  DEFINE WINDOW oWnd1 MDICHILD TITLE "Facturacion por ventas" OF oApp:oWnd NOZOOM ICON oApp:oIco
   
    *oWnd1:bGotFocus := { || oDlg:SetFocus}
    oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }

    //DLG -----------------------------------------------
    DEFINE DIALOG oDlg RESOURCE "VENTAS" OF oWnd1
    //Fechas y tipo de Comprobante
    REDEFINE GET oGet[01] VAR dFecha ID 176  OF oDlg 
    REDEFINE CHECKBOX oGet[44] VAR lAcopio   OF oDlg ID 4023
    REDEFINE CHECKBOX oGet[47] VAR lFacturaM OF oDlg ID 4029
    oGet[47]:cToolTip:= "Regimen Espcial - Para generar comprobantes 'M' en lugar de comprobantes 'A'"
    REDEFINE CHECKBOX oGet[48] VAR lFacturaD OF oDlg ID 4030
    oGet[48]:cToolTip:= "Realizar la factura en DOLARES"
    REDEFINE COMBOBOX oGet[02] VAR nTipoDoc ITEMS aTipoDoc ID 177 OF oDlg;
             ON CHANGE(oGet[08]:SetFocus())
    REDEFINE SAY oSay1    VAR cLetra  ID 180  OF oDlg FONT oFontLetra
    REDEFINE SAY oSay2    VAR cDescu  ID 999 OF oDlg
    //Numero de comprobante 
    REDEFINE GET oGet[05] VAR nPuntoVta ID 181 OF oDlg WHEN (.f.) PICTURE "9999"
    REDEFINE GET oGet[06] VAR cNumComp   ID 182 OF oDlg WHEN (.f.) PICTURE "@!"
    REDEFINE COMBOBOX oGet[36] VAR cVendedor ID 4011 OF oDlg ITEMS aVendedores WHEN(oApp:modifica_vend)

    //Tipo de cliente
    REDEFINE RADIO oGet[07] VAR nTipoCli ID 183, 184 OF oDlg WHEN lPedidoUsado=.f.;
             ON CHANGE IF(nTipoCli = 1, (nCodCli := 0, oGet[08]:SetFocus()), ;
                          (oGet[08]:cText := 0, oGet[09]:cText := SPACE(50), ;
                           oGet[10]:cText := SPACE(50),oGet[11]:cText := SPACE(50),;
                           oGet[12]:cText := SPACE(13), oGet[22]:cText :=0, oGet[13]:Set(5),oGet[09]:SetFocus() ) )

    //CLIENTE
    REDEFINE GET oGet[08] VAR nCodCli ID 185 OF oDlg PICTURE "999999" WHEN(nTipoCli=1 .and. lPedidoUsado=.f.) ;
             ACTION (oGet[08]:cText:= 0, ValidaCli())  BITMAP "BUSC1" VALID (ValidaCli()) 
    REDEFINE GET oGet[09] VAR cNomCli ID 186 OF oDlg PICTURE "@!"  WHEN(nTipoCli=2)
    REDEFINE GET oGet[10] VAR cDireccion ID 187  OF oDlg PICTURE "@!" WHEN(nTipoCli=2)
    REDEFINE GET oGet[11] VAR cLocalidad ID 188  OF oDlg PICTURE "@!" WHEN(nTipoCli=2)
    REDEFINE GET oGet[12] VAR cCUIT      ID 189 OF oDlg PICTURE "99-99999999-9" ;
             WHEN(nTipoCli=2) VALID(ValidaCuit(cCuit))
    REDEFINE GET oGet[22] VAR nDNI      ID 201 OF oDlg PICTURE "99999999" ;
             WHEN(nTipoCli=2)
    REDEFINE COMBOBOX oGet[13] VAR nConIva ID 190 OF oDlg WHEN(nTipoCli=2) ITEMS aTipoIva;
             ON CHANGE ValidaCli(.f.) 
    REDEFINE GET oGet[31] VAR nDescuGen ID 308 OF oDlg PICTURE "999.99" WHEN(nTipoDoc = 5)
    REDEFINE GET oGet[23] VAR cObserva  ID 307 OF oDlg PICTURE "@S40"
    REDEFINE GET oGet[32] VAR nDeuda    ID 4001 OF oDlg PICTURE "9999999999.99" WHEN(.F.)
    
    REDEFINE SAY oSay3 VAR cRemitos ID 4002 OF oDlg COLOR CLR_GREEN

    REDEFINE GET oGet[40] VAR nLisPre ID 4017 OF oDlg PICTURE "999" WHEN(!lUsoPedido);
                 VALID((nLisPre = 0 .and. IF(nLisPre=0,(oGet[41]:cText:="SIN LISTA ESPECIAL"+SPACE(31))<>"xxx",.T.)) .or.;
                       Buscar(oQryLisPre,oDlg,oGet[40],oGet[41]) .and. ActualizarDet());
                 ACTION (oGet[40]:cText:= 0, Buscar(oQryLisPre,oDlg,oGet[40],oGet[41]),ActualizarDet()) BITMAP "BUSC1"
    REDEFINE GET oGet[41] VAR cLisPre ID 4018 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE COMBOBOX oGet[43] VAR nFormaPago ID 4012 OF oDlg ITEMS aFormaNom ON CHANGE ActualizarDet() WHEN(!lUsoPedido)
    //TIPO ARTICULO
    REDEFINE RADIO oGet[24] VAR nTiArt  ID 300,301 OF oDlg;
             ON CLICK(nCodArt:=0        ,cDetArt:=SPACE(500),nCantidad:=0      ,nPunit:=0         ,nPTotal:=0,;
                      oGet[14]:Refresh(),oGet[15]:Refresh(),oGet[16]:Refresh(),oGet[17]:Refresh(),oGet[18]:Refresh(),;
                                         oGet[25]:Refresh(),oGet[26]:Refresh(),oGet[27]:Refresh(),oGet[28]:Refresh())
    
    //Datos del articulo registrado
    REDEFINE GET oGet[14] VAR nCodArt   ID 191  OF oDlg PICTURE "99999999999999" WHEN(nTiArt=1);
             ACTION (oGet[14]:cText:= 0, ValidaArt())  BITMAP "BUSC1" VALID(ValidaArt())
    oGet[14]:bGotFocus :={|| oGet[14]:SelectAll()}
    REDEFINE GET oGet[15] VAR cDetArt   ID 192  OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[16] VAR nCantidad ID 193  OF oDlg PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=1)
    REDEFINE GET oGet[17] VAR nPunit    ID 194  OF oDlg PICTURE "99999999.999" WHEN(nTiArt=1 .and. oApp:modifica_precios)
    REDEFINE GET oGet[33] VAR nDescArt  ID 4003 OF oDlg PICTURE "999.99" WHEN(nTiArt=1 .and. oApp:modifica_descu)
    REDEFINE GET oGet[18] VAR nPtotal   ID 195  OF oDlg PICTURE "99999999.999" ;
            WHEN((oGet[18]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt/100)) = "-9" .and. nTiArt=1) 
    REDEFINE SAY oSay[1] ID 4027          
    REDEFINE GET oGet[45] VAR nBultos    ID 4025  OF oDlg PICTURE "9999.9"  WHEN(nTiArt=1)
    REDEFINE GET oGet[39] VAR cCodArtP   ID 4016  OF oDlg WHEN(nTiArt=1 .and. oApp:usar_codpro);
             VALID(oGet[39]:cText=SPACE(30) .OR. ValidaArtP())
    //Datos del articulo ocacional
    REDEFINE GET oGet[25] VAR cDetArt   ID 302  OF oDlg PICTURE "@S35" WHEN(nTiArt=2)
    REDEFINE GET oGet[26] VAR nCantidad ID 304  OF oDlg PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=2)
    REDEFINE GET oGet[27] VAR nPunit    ID 305  OF oDlg PICTURE "99999999.999" WHEN(nTiArt=2);
                 VALID((oGet[28]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt1/100)) <> "xxx" )
    REDEFINE GET oGet[34] VAR nDescArt1  ID 4004 OF oDlg PICTURE "999.99" WHEN(nTiArt=2 .and. oApp:modifica_descu)
    REDEFINE GET oGet[28] VAR nPtotal   ID 306  OF oDlg PICTURE "99999999.999" WHEN(.f.)
    REDEFINE GET oGet[30] VAR nPorIva   ID 303  OF oDlg PICTURE "999.99" WHEN(nTiArt=2); 
             VALID((oQryIvaT:Seek(nPorIva,3) > 0) .and. ((nCodIva:=oQryIvaT:codigo) >0 ))
    REDEFINE GET oGet[46] VAR nBultos    ID 4026  OF oDlg PICTURE "9999.9" WHEN(nTiArt=2)      
    REDEFINE SAY oSay[2] ID 4028

    //ingresos brutos 
    REDEFINE GET oGet[37] VAR nIngBruP  ID 4013 OF oDlg PICTURE "999.99" 
    REDEFINE GET oGet[38] VAR nIngBru   ID 4014 OF oDlg PICTURE "999999999.99" WHEN(.F.)
    //neto y IVA y total
    REDEFINE GET oGet[19] VAR nNeto  ID 198 OF oDlg PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[20] VAR nIVA   ID 199 OF oDlg PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[21] VAR nTotal ID 200 OF oDlg COLOR CLR_RED , CLR_YELLOW READONLY;
           PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)
    REDEFINE GET oGet[42] VAR nImpInt ID 4019 OF oDlg PICTURE "99999999.99" WHEN(.F.)    
    //GRILLA ---------------------------------------------------------------      
    
    REDEFINE XBROWSE oBrw DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","DESCUENTO","STOTAL","IVA","PTOTAL","CODIVA","IMPINT","DESCUP", { || STR(oQryDet:stotal / oQryDet:cantidad,12,3) },"BULTOS" ;
       HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Neto","Dto./Rec.","Sub Total","IVA","Total","Tasa","Imp.","Dto %","Neto Un","Bultos";
       FOOTERS ;
       SIZES 80,270,55,55,55,55,55,55,55,55,55,40,40;
    ID 197 OF oDlg AUTOSORT
    oBrw:nFreeze := 3
    PintaBrw(oBrw,0)
    
    oBrw:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(EliminarItem(),;
                                   nTotal:= oBrw:aCols[9]:nTotal,oGet[21]:Refresh(),;
                                   nImpInt:= oBrw:aCols[11]:nTotal,oGet[42]:Refresh()),)}
    oBrw:aCols[9]:nFooterTypE := AGGR_SUM
    oBrw:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw:aCols[8]:nFooterTypE := AGGR_SUM
    oBrw:aCols[11]:nFooterTypE := AGGR_SUM
    oBrw:aCols[14]:nFooterTypE := AGGR_SUM
    oBrw:aCols[3]:lAutoSave := .t.
    oBrw:aCols[3]:nEditType := EDIT_GET 
    oBrw:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,)} 
    IF oApp:modifica_precios
      oBrw:aCols[4]:lAutoSave := .t.
      oBrw:aCols[4]:nEditType := EDIT_GET 
      oBrw:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,xval)} 
      oBrw:aCols[12]:lAutoSave := .t.
      oBrw:aCols[12]:nEditType := EDIT_GET 
      oBrw:aCols[12]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,xval,)} 
    ENDIF
    oBrw:aCols[10]:Hide()
    oBrw:aCols[11]:Hide()
    oBrw:aCols[14]:lAutoSave := .t.
    oBrw:aCols[14]:nEditType := EDIT_GET 
    
    //BOTONES ---------------------------------------------------------------
    //+
    REDEFINE BUTTON oBot[1] ID 196 PROMPT "&+" ACTION(AgregaItem(nTiArt),IF(nTiArt=1,oGet[14]:Setfocus(),oGet[25]:Setfocus()) ) ;
                   WHEN(((nCodArt>0 .and. nTiArt=1 .and. (nPtotal>0 .or. (nPtotal=0 .and. nDescArt=100))) .or. (nTiArt=2 .and. cDetArt<>SPACE(30) .and. nPtotal>0)) .and. nCantidad > 0 .AND. (nCodcli > 0 .or. nTipoCli = 2))
    //cancelar
    REDEFINE BUTTON oBot[2] ID 102 ACTION (LimpiarForm()) 
    //grabar
    REDEFINE BUTTON oBot[3] ID 103  ACTION Validaciones() WHEN(oBrw:aCols[9]:nTotal > 0 .and. IF(oApp:usar_remitos,.T.,IF(nTipoDoc=5,.F.,.T.)))
    //elegir factura para nota de credito
    REDEFINE BUTTON oBot[5] ID 4005 ACTION(ElegirFact()) WHEN(nTipoDoc=3 .or. nTipoDoc=1)
    //salir
    REDEFINE BUTTON oBot[4] ID 104 ACTION (oDlg:End()) CANCEL 
    // Ver Historial
    REDEFINE BUTTON oBot[6] ID 4021 ACTION VerHistorial(nCodCli,oQryDet,oBrw) WHEN(nCodCli > 0)
    //Vales 
    REDEFINE BUTTON oBot[10] ID 4022 WHEN oApp:usavales
    oBot[10]:bAction = { | nRow, nCol | Vales( nRow, nCol, oBot[10]) }
    
    //dejar factura pendiente
    REDEFINE BUTTON oBot[7] ID 105 ACTION(DejarPendiente(oGet)) WHEN(oBrw:aCols[9]:nTotal > 0 .and. IF(oApp:usar_remitos,.T.,IF(nTipoDoc=5,.F.,.T.)))
    //salir
    REDEFINE BUTTON oBot[8] ID 4015 ACTION (IF(CargarPedido(nCodCli),oBrw:SetFocus(),oGet[8]:SetFocus())) PROMPT "Pedido" WHEN(nCodCli>0)

    REDEFINE BUTTON oBot[9] ID 4020 ACTION VerDeuda(nCodcli)  WHEN(nCodCli>0)

    REDEFINE BUTTON oBot[11] ID 4024 ACTION FacturarPresupu(nCodcli)
    // F9 Para grabar             
    oDlg:bKeyDown = { | nKey, nFlags | IF(oDlg:oCtlFocus == oGet[8],.F.,IF(nKey==VK_F9,oBot[3]:Click,;
                                       IF(nKey==VK_F3,oBot[5]:Click,;
                                       IF(nKey==VK_F4,oBot[6]:Click,;
                                       .f.)))) }
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT;
     IF(!oApp:usabultosventa,;
        (oGet[45]:Hide(),oGet[46]:Hide(),oBrw:aCols[14]:Hide(),oSay[1]:Hide(),oSay[2]:Hide(),oDlg:Move(0,0)),;
        oDlg:Move(0,0)) ;
       VALID(oWnd1:End())
    ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN 


*****************************************************************************************************************
****** TRAER PEDIDO PENDIENTE DEL CLIENTE 
STATIC FUNCTION CargarPedido(nCodCli)
LOCAL oDlg1,oBrwRem,oQryRem,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f., cRemitos := "",oQryStock,lRtA:=.f.,;
      oChe
IF lPedidoUsado 
   MsgStop("Ya marco pedidos, realice la facturacion "+;
    " o cancele y vuelva a seleccionar","Atencion")
   RETURN .f.
ENDIF
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE pedidos_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("INSERT INTO pedidos_temp (tilde,id,fecha,vendedor,parafecha,observa) "+;
                     "(SELECT 0,id,fecha,vendedor,parafecha,observa "+;
                     "FROM ge_"+oApp:cId+"pedidos_encab "+;
                     "WHERE codcli = "+ClipValue2Sql(nCodCli)+" AND estado = 'P')")
oQryRem:= oApp:oServer:Query("SELECT * FROM pedidos_temp ORDER BY id")

IF oQryRem:RecCount() = 0
   MsgStop("El cliente seleccionado no tiene un pedido cargado","Atencion!")
   RETURN .F. 
ENDIF
lUsoPedido := .t.
DEFINE DIALOG oDlg1 TITLE "Pedidos a facturar" OF oWnd1 FROM 05,15 TO 24,65
    oDlg1:lHelpIcon:=.f.

@ 05,05 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "tilde","id","fecha","vendedor","parafecha","observa";   
                 HEADERS " ","Numero","Fecha","Vendedor","Para","Observaciones";
                 SIZES 40,60,70,100,70;
         OF oDlg1 SIZE 190,97 PIXEL 
oQryRem:bOnChangePage := {|| oBrwRem:Refresh() }
oBrwRem:aCols[1]:SetCheck(nil,.f.)   
oBrwRem:aCols[1]:bLDClickData := {|| CambiaChek(oQryRem,oBrwRem)}
oBrwRem:aCols[1]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oQryRem,oBrwRem))}
oBrwRem:aCols[1]:nEditType := 1
oBrwRem:aCols[1]:bEditValue:= {|| IF(oQryRem:tilde,.t.,.f.) }
oBrwRem:CreateFromcode()
PintaBrw(oBrwRem,0)
@ 110,05 CHECKBOX oChe VAR lUsoPedido PROMPT "Respetar precios del pedido" SIZE 110,12 OF oDlg1 PIXEL
oBrwRem:bKeyDown = { | nKey, nFlags | IF(nKey==13,oBot1:Click,.f.) }

acor := AcepCanc(oDlg1)
@ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
@ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwRem:SetFocus()


IF mRta = .f.
   lUsoPedido := .f.
   RETURN .F. 
ENDIF

IF oApp:oServer:Query("SELECT id FROM pedidos_temp WHERE tilde"):RecCount() = 0
  MsgStop("Debe seleccionar algun pedido para continuar","Atencion!")
  RETURN .f.
ENDIF

IF oQryPun:pidestock < 3 .and. nTipoDoc <> 3
   oQryStock := oApp:oServer:Query("SELECT p.codart,p.detart,p.cantidadreal,a.stockact,a.stockmin "+;
                   "FROM ge_"+oApp:cId+"pedidos_det p LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                   " WHERE p.idpedido IN (SELECT id FROM pedidos_temp WHERE tilde ) AND "+;
                   "p.cantidadreal > 0 "+;
                   " AND (a.stockact < p.cantidadreal " +;
                   " OR IF(a.stockmin > 0, a.stockact - p.cantidadreal > a.stockmin,FALSE))")
   IF oQryStock:nRecCount > 0
      DEFINE DIALOG oDlg1 TITLE "Faltantes de Stock" OF oWnd1 FROM 05,15 TO 21,78
          oDlg1:lHelpIcon:=.f.

      @ 05,05 XBROWSE oBrwRem DATASOURCE oQryStock;
                       COLUMNS "detart","cantidadreal","stockact","stockmin";    
                       HEADERS "Producto","Pedidos","Stock","Min";
                       PICTURE "@!","99999","99999","99999";
                       SIZES 250,50,50,50;
               OF oDlg1 SIZE 240,97 PIXEL 
      oBrwRem:CreateFromcode()
      PintaBrw(oBrwRem,0)


      acor := AcepCanc(oDlg1)
      @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Continuar" OF oDlg1 SIZE 30,10 ;
                 ACTION ((lRta := .t.), oDlg1:End() ) PIXEL DEFAULT 
      @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Abortar" OF oDlg1 SIZE 30,10 ;
                 ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
      ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwRem:SetFocus() 
      IF !lRta 
         lUsoPedido := .f.
         RETURN .F.
      ENDIF
   ENDIF
ENDIF


    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,neto,descuento,stotal,iva,codiva,ptotal,pcosto,descup) "+;
                       "(SELECT p.codart,p.detart,sum(p.cantidadreal),p.punitario,"+;
                       "0,"+; //neto
                       "p.descu,"+;
                       "0,"+; //neto con descuento
                       "0,"+; //iva con descuento
                       "IF(p.codart>0,a.iva,5),"+;
                       "0,"+; //total
                       "a.preciocos,p.descup "+;
                       "FROM ge_"+oApp:cId+"pedidos_det p "+;
                       "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                       "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva "+;
                       "WHERE p.idpedido IN (SELECT id FROM pedidos_temp WHERE tilde ) AND p.cantidadreal>0 "+;
                       " GROUP BY p.codart,p.detart"+if(lUsoPedido,",p.punitario,p.descu","")+ ")")
                       
    oQryDet:Refresh() 
    lPedidoUsado:=.t.
    ActualizarDet(lUsoPedido)    
    oBrw:Refresh()
    oBrw:MakeTotals()
    oGet[19]:cText := oBrw:aCols[7]:nTotal 
    oGet[20]:cText := oBrw:aCols[8]:nTotal      
    oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) 
    oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
    oGet[42]:cText := oBrw:aCols[11]:nTotal
  

RETURN .T. 

STATIC FUNCTION CambiaChek(oQry1,oBrw1)
LOCAL valor
valor := IF(oQry1:tilde=.f.,.t.,.f.)
oQry1:tilde := valor
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil

**************************************************
*** ACTUALIZAR TODO EL DETALLE 
STATIC FUNCTION ActualizarDet(lPedido)
DEFAULT lPedido := .f.
oQryDet:GoTop()
DO WHILE !oQryDet:EOF()
   CambiaCant(,,,,lPedido)     
   oQryDet:Skip()
ENDDO
RETURN .T.

*****************************************
** Cambiar pendientes
STATIC FUNCTION CambiaCant(n,nPorc,nPUnit,cNombre,lPedido)
LOCAL base := oQryDet:GetRowObj(),nPrecio2,nDescuento,nPrecio1,nIvaPes,nSubTotal,nTotalcIva,;
      oQryIva,nCodIva1,nIvaCalc,nII:=base:impint/base:cantidad,oQryPrecio,oQryArt
DEFAULT n := base:cantidad,nPorc:= base:descup,nPUnit:= base:punit, cNombre:= base:detart,lPedido:=.f.
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(base:codiva))
nCodIva1 := base:codiva
IF base:codart > 0    
    IF VALTYPE(nPunit) <> "N" .OR. VALTYPE(n) <> "N" 
       RETURN nil 
    ENDIF
    IF nPunit = base:punit .and. lPedido = .f.
      oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+" AND "+;
                                  "codart = "+ClipValue2Sql(base:codart))
      IF oQryPrecio:RecCount() > 0
         nPunit:= oQryPrecio:precio 
      ELSE 
         oQryArt:= oApp:oServer:Query("SELECT precioven,reventa FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
         nPunit:= IF(nLista=1,oQryArt:precioven,oQryArt:reventa)
      ENDIF    
    ENDIF
    nPunit:= nPunit * (1+(aFormaInc[nFormaPago]/100))
ENDIF      
nPrecio2:= (nPUnit-(nII)) * (n)
nDescuento:= nPrecio2 * (nPorc/100)
nPrecio1:= nPrecio2 - nDescuento
nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
nSubTotal:= nPrecio1 - nIvaPes
nTotalcIva := nPrecio1 + (nII*n)

base:impint:= nII * n
base:descup:= nPorc
base:cantidad := n 
base:ptotal:=nTotalcIva
base:neto:=nPrecio2-nIvaCalc
base:iva:=nIvaPes
base:descuento:=nDescuento
base:stotal:=nSubTotal
base:punit:= nPUnit
base:detart:= cNombre
oQryDet:oRow := base
oQryDet:Save()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal  
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
oGet[42]:cText := oBrw:aCols[11]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
oGet[42]:Refresh()
RETURN nil

************************************************************************************************************
******* DEJAR FACTURA PENDIENTE DE FACTURACION
STATIC FUNCTION DejarPendiente(oGet)
LOCAL nCliente:= IF(nTipoCli=1,oGet[8]:value,-1),nNumero, lRta := .f., oErr
lRta := SiNoCancelar("Atencion","Desea imprimir el comprobante"+chr(10)+"Antes de dejar en cola?",;
                      {"Tipo Presupuesto","Formato Remito","No imprimir"})
IF lRta <> nil
    IF lRta
       PrintPresupu(oQryDet,oGet,oBrw,.f.,,"00000000000000000")
       ELSE
       PrintRemito(oQryDet,oGet,oBrw,"00000000000000000")
    ENDIF
ENDIF    
TRY
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab_p (nombre_equipo,codcli,nombre,cuit,dni,direccion,localidad,coniva,importe) "+;
                           "VALUES("+ClipValue2Sql(DTOC(DATE())+" "+oApp:cNombreEquipo)+","+ClipValue2Sql(nCliente)+","+ClipValue2Sql(oGet[9]:cText)+","+;
                            ClipValue2Sql(oGet[12]:cText)+","+ClipValue2Sql(oGet[22]:cText)+","+;
                            ClipValue2Sql(oGet[10]:cText)+","+ClipValue2Sql(oGet[11]:cText)+","+ClipValue2Sql(nConIva)+","+;
                            ClipValue2Sql(nTotal)+")")
      nNumero:= oApp:oServer:LastInsertID()
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det_p "+;
                        " (numven,codart,detart,cantidad,punit,codcli,importe,neto,iva,codiva,neton,descu,pcosto,descup) "+;
                        " (SELECT "+ClipValue2Sql(nNumero)+",codart,detart,cantidad,punit,"+ClipValue2Sql(nCliente)+","+;
                        " ptotal, stotal,iva,codiva,neto,descuento,pcosto,descup FROM ventas_det_H)")
      //BORRO FACTURAS PENDIENTES USADAS (SI NO USA NINGUNA ES 0)
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab_p WHERE id = "+ClipValue2Sql(nBorrarPend))
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det_p   WHERE numven = "+ClipValue2Sql(nBorrarPend))
CATCH oErr 
      MsgInfo(oErr:description,"Error")
END TRY     
LimpiarForm()
RETURN nil


*******************************************************************************************
******* MOSTRAR REMITOS A FACTURAR
STATIC FUNCTION ConsultaPre(oGet)
LOCAL oDlg1,oBrwRem,oQryRem,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f.

IF oGet[24]:nOption() = 1
oApp:oServer:Execute("UPDATE precios_temp SET importe = "+;
                    "(SELECT "+IF(nLista=1,"precioven","reventa")+" FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(oQryArt:codigo)+")"+;
                    "*(1+(incremento/100))")

oQryRem:= oApp:oServer:Query("SELECT * FROM precios_temp")

DEFINE DIALOG oDlg1 TITLE "Lista de precios segun forma de pago "+ALLTRIM(cDetArt) OF oWnd1 FROM 05,15 TO 21,78
    oDlg1:lHelpIcon:=.f.

@ 05,05 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "formapag","incremento","importe";    
                 HEADERS "Forma","Incr %","Precio";
                 SIZES 308,50,70;
         OF oDlg1 SIZE 240,97 PIXEL 
oQryRem:bOnChangePage := {|| oBrwRem:Refresh() }
oBrwRem:CreateFromcode()
PintaBrw(oBrwRem,0)

oBrwRem:bKeyDown = { | nKey, nFlags | IF(nKey==13,oBot1:Click,.f.) }

acor := AcepCanc(oDlg1)
@ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
@ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwRem:SetFocus()

IF !mRta
  RETURN nil 
ENDIF

oGet[17]:cText:= oQryRem:importe 
ELSE
MsgInfo("Formas de pago sobre productos no eventuales","Error")
ENDIF
RETURN nil

*******************************************************************************************
******* MOSTRAR DEUDA DEL CLIENTE
STATIC FUNCTION VerDeuda(nCod)
LOCAL oDlg1,oBrwRem,oQryRem,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f.

oQryRem := oApp:oServer:Query("SELECT concat(tipo,letra,numero) as compro, fecha, "+;
                              " saldo * IF(tipo='NC',-1,1) as saldo "+;
                              " FROM ge_"+oApp:cId+"ventas_cuota WHERE cliente = "+;
                              ClipValue2Sql(ncod) + " AND saldo <> 0 ")

DEFINE DIALOG oDlg1 TITLE "Deudas impagas del cliente " OF oWnd1 FROM 05,15 TO 21,78
    oDlg1:lHelpIcon:=.f.

@ 05,05 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "compro","fecha","saldo";    
                 HEADERS "Comprobante","Fecha","Saldo";
                 FOOTERS;
                 SIZES 120,90,90;
         OF oDlg1 SIZE 240,97 PIXEL 
oBrwRem:aCols[3]:nFooterType := AGGR_SUM         
oBrwRem:MakeTotals()
oBrwRem:CreateFromcode()
PintaBrw(oBrwRem,0)

acor := AcepCanc(oDlg1)
@ acor[1],acor[2] BUTTON oBot1 PROMPT "&Cerrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT
@ acor[3],acor[4] BUTTON oBot2 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION (oBrwRem:Report("Reporte de Deuda de "+oGet[09]:cText,.T.,.F.),oDlg1:End()) PIXEL  
ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwRem:SetFocus()

RETURN nil


************************************************************************************
***** Elegir factura para nota de credito
STATIC FUNCTION ElegirFact()
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oDlg1, oFont, mnumfac, ;
      mrta := .f., aCor, base, marchi, mtotal, mdescp := 0, mdeuda := 0,;
      aTipo  := {"Factura","Factur x Rem."}, oRep,;
      aTip1  := {"FC","FR"}, mtipo := 1, mletra := "A", mprefijo := oApp:prefijo,;
      mnumero := 0,oQryFac, oQryPend,oBrwPend
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5   

IF nTipoDoc = 3   
    DEFINE DIALOG oDlg1 TITLE "Elejir factura para nota de credito" FROM 03,20 TO 14,60 OF oApp:oWnd FONT oFont
       acor := AcepCanc(oDlg1)
       
       @ 07, 05 SAY "Tipo Docum.:" OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 22, 05 SAY "Letra:"       OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 37, 05 SAY "Prefijo:"     OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 52, 05 SAY "Numero:"      OF oDlg1 PIXEL RIGHT SIZE 40,10
       
       @ 05, 50 COMBOBOX oGet1 VAR mtipo ITEMS aTipo OF oDlg1 SIZE 79,50 PIXEL
       @ 20, 50 GET      oGet2 VAR mletra PICTURE "@!" OF oDlg1 SIZE 20,10 PIXEL;
                         VALID(mletra$"ABCX")
       @ 35, 50 GET      oGet3 VAR mprefijo PICTURE "9999" OF oDlg1 PIXEL RIGHT
       @ 50, 50 GET      oGet4 VAR mnumero  PICTURE "99999999" OF oDlg1 PIXEL RIGHT
       
       @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Elegir" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
    IF !mrta
       RETURN nil
    ENDIF
    oQryFac:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = "+ClipValue2Sql(aTip1[mtipo])+;
                                 "AND letra = "+ClipValue2Sql(mletra)+;
                                 "AND numcomp = "+ClipValue2Sql(STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0")))
    IF oQryFac:RecCount() = 0
       MsgStop("La factura no existe","Atencion!")
       RETURN nil 
    ENDIF

    oGet[08]:cText:= oQryFac:codcli
    ValidaCli()                                   

    oApp:oServer:Execute("TRUNCATE ventas_det_H")
    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,neto,descuento,descup,stotal,iva,codiva,ptotal,pcosto,impint) "+;
                         "(SELECT codart,detart,cantidad,punit,neton,descu,descup,neto,iva,codiva,importe,pcosto,impint FROM ge_"+oApp:cId+"ventas_det "+;
                         "WHERE nrofac = "+ClipValue2Sql(oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp)+")")
    cOrigenNC := oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp
ENDIF

IF nTipoDoc= 1
    oQryPend:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab_p")
    DEFINE DIALOG oDlg1 TITLE "Listado de facturas pendientes" OF oWnd1 FROM 05,15 TO 21,78
        oDlg1:lHelpIcon:=.f.

    @ 05,05 XBROWSE oBrwPend DATASOURCE oQryPend;
                     COLUMNS "nombre_equipo","nombre","importe";    
                     HEADERS "Cargada en","Cliente","Importe";
                     SIZES 140,218,70;
             OF oDlg1 SIZE 240,97 PIXEL AUTOSORT
    oQryPend:bOnChangePage := {|| oBrwPend:Refresh() }    
    oBrwPend:CreateFromcode()
    PintaBrw(oBrwPend,0)

    oBrwPend:bKeyDown := { |nKey, nFlags| IF (nKey == VK_DELETE,;
                          IF(MsgNoYes("Seguro de borrar?","Atencion"),oBrwPend:Delete(),);
                          ,IF(nKey==13,oBot1:Click,.f.))}

    acor := AcepCanc(oDlg1)
    @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
    @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwPend:SetFocus()

    IF !mrta
       RETURN nil
    ENDIF

    IF oQryPend:codcli > 0
       oGet[08]:cText= oQryPend:codcli
       ValidaCli()
    ELSE 
       oGet[08]:cText:= 0
       oGet[09]:cText:= oQryPend:nombre 
       oGet[10]:cText:= oQryPend:direccion
       oGet[11]:cText:= oQryPend:localidad 
       oGet[12]:cText:= oQryPend:cuit 
       oGet[22]:cText:= oQryPend:dni
       oGet[13]:Set(oQryPend:coniva)
    ENDIF
    oApp:oServer:Execute("TRUNCATE ventas_det_H")
    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,neto,descuento,descup,stotal,iva,codiva,ptotal,pcosto) "+;
                         "(SELECT codart,detart,cantidad,punit,neton,descu,descup,neto,iva,codiva,importe,pcosto FROM ge_"+oApp:cId+"ventas_det_p "+;
                         "WHERE numven = "+ClipValue2Sql(oQryPend:id)+")")
    nBorrarPend:= oQryPend:id
ENDIF
oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal 
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
oGet[42]:cText := oBrw:aCols[11]:nTotal
RETURN nil

************************************************************************************
** Vaciar el formulario despues de grabar o cancelar
STATIC FUNCTION LimpiarForm()
oQryDet:Zap()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal      
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
oGet[42]:cText := oBrw:aCols[11]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
oGet[08]:cText := 0
oGet[09]:cText := SPACE(30)
oGet[10]:cText := SPACE(30)
oGet[11]:cText := SPACE(30)
oGet[12]:cText := SPACE(13)
oGet[23]:cText := SPACE(255)
oGet[13]:nAt := 5    
oGet[02]:Select(1)
oGet[02]:SetFocus()
lFacturaD := .f.
oGet[48]:Refresh()
nBorrarPend:=0
lUsoPedido := .f.
lAcopio := IF(FILE('.\ACOPIO.INI'),.T.,.f.)
lPedidoUsado := .f.
oGet[44]:Refresh()
nPuntoVta := oQryPun:caja
cOrigenNC := ''
RETURN nil


************************************************************************************
** Agregar item a la venta
STATIC FUNCTION AgregaItem(nTiArt)
LOCAL oQryIva, nTotalcIva, nIvaPes, nCodIva1, nSubTotal, nDescuento,;
      i,nCantidad,nPrecio1,nPrecio2,lRta:=.f.,nIvaCalc:=0,nDescMar, nPunit

IF nTiArt = 1
   IF oQryPun:pidestock = 1 .and. oQryArt:stockact-oGet[16]:value < 0 .and. nTipoDoc <> 3
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad ¿Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF
  ENDIF
  IF oQryPun:pidestock = 2 .and. oQryArt:stockact-oGet[16]:value < 0 .and. nTipoDoc <> 3
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
     RETURN .F.
  ENDIF
  IF oQryPun:pidestock < 3 .and. oQryArt:stockmin > 0 .and. oQryArt:stockact-oGet[16]:value  < oQryArt:stockmin .and. nTipoDoc <> 3
     MsgAlert("Se esta quedando sin stock, llego al stock minimo","Atencion")     
  ENDIF


   nDescMar:= oApp:oServer:Query("SELECT descuento FROM ge_"+oApp:cId+"desccli WHERE codmar ="+ClipValue2Sql(oQryArt:marca)+" AND "+;
                                 "codcli ="+ClipValue2Sql(oGet[8]:value)):descuento
   IF EMPTY(nDescMar) 
      nDescMar :=0
   ENDIF
   oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryArt:iva))
   nCodIva1 := oQryArt:iva
   //nPrecio2:= oGet[17]:value * oGet[16]:value
   nPrecio2:= (oGet[17]:value - oQryArt:impint) * oGet[16]:value
   nDescuento:= nPrecio2 * ( IF(nDescMar>0,nDescMar,IF(nDescArt>0,nDescArt,nDescuGen))/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
   nSubTotal:= nPrecio1 - nIvaPes
   //nTotalcIva := nPrecio1
   oQryArt:nombre := STRTRAN(oQryArt:nombre,"'","´")
   nTotalcIva := nPrecio1 + (oQryArt:impint*oGet[16]:value)
   oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,descup,stotal,pcosto,impint,bultos) "+;
                         "VALUE ( "+ClipValue2Sql(oQryArt:codigo)+","+;
                                 ClipValue2Sql(oQryArt:nombre)+","+;
                                 ClipValue2Sql(oGet[16]:cText)+","+;
                                 ClipValue2Sql(oGet[17]:value)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio2-nIvaCalc)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva1)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(IF(nDescArt>0,nDescArt,nDescuGen))+","+;
                                 ClipValue2Sql(nSubTotal)+","+;
                                 ClipValue2Sql(oQryArt:preciocos)+","+;
                                 ClipValue2Sql(oQryArt:impint*oGet[16]:value)+","+;
                                 ClipValue2Sql(oGet[45]:value)+""+; //Bultos
                         " )" ) 
ELSE
   nPunit  := oGet[27]:value
   nPunit  := IF(oApp:artievenmasiva,nPunit*(1+nPorIva*0.01),nPunit)
   nPunit  := IF(oApp:artievenendolar,nPunit*oQryPar:dolar,nPunit)
   nPrecio2:= oGet[27]:value  * oGet[26]:value
   nPrecio2:= IF(oApp:artievenmasiva,nPrecio2*(1+nPorIva*0.01),nPrecio2)
   nPrecio2:= IF(oApp:artievenendolar,nPrecio2*oQryPar:dolar,nPrecio2)
   nDescuento:=nPrecio2 * (IF(nDescArt1>0,nDescArt1,nDescuGen)/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaCalc := nPrecio2 - (nPrecio2 / (1 + nPorIva/100))
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + nPorIva/100))
   nSubTotal:= nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1 
   nCodIva := IF(nPorIva=0,3,nCodIva)

 oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,descup,stotal,impint,bultos) "+;
                      "VALUE ( 0,"+;
                                 ClipValue2Sql(oGet[25]:value)+","+;
                                 ClipValue2Sql(oGet[26]:value)+","+;
                                 ClipValue2Sql(nPunit)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio2-nIvaCalc)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(IF(nDescArt1>0,nDescArt1,nDescuGen))+","+;
                                 ClipValue2Sql(nSubTotal)+",0,"+;
                                 ClipValue2Sql(oGet[45]:value)+""+; //Bultos
                       " )" )
ENDIF                                
oApp:oServer:NextResult()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
oBrw:GoBottom()
cLetra := IF(nTipoDoc=5,"R",IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6 ,"A","B"),"C"))
cLetra := IF(!lFacturaM,cLetra,IF(cLetra="A","M",cLetra))
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal  
oGet[14]:cText:= IF(oQryArt <> nil,oQryArt:codigo,1)
oGet[14]:Refresh()
oGet[15]:cText:=SPACE(70)
oGet[25]:cText:=SPACE(500)
oGet[33]:cText := 0
oGet[25]:Refresh()
oGet[15]:Refresh()
FOR i:= 16 TO 18
   oGet[i]:cText:=0
   oGet[i+10]:cText:=0
   oGet[i]:Refresh()
   oGet[i+10]:Refresh()
NEXT i
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value  
oGet[42]:cText := oBrw:aCols[11]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN .t.

************************************************************************************
** Borrar item de la venta
STATIC FUNCTION EliminarItem()
LOCAL cLetra
IF oQryDet:RecCount()>0
oQryDet:DELETE()
oBrw:Refresh()
oQryDet:Refresh()
oBrw:Maketotals()
cLetra := IF(nTipoDoc=5,"R",IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6,"A","B"),"C"))
cLetra := IF(!lFacturaM,cLetra,IF(cLetra="A","M",cLetra))
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal   
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
ENDIF
RETURN .t.



************************************************************************************
STATIC FUNCTION ValidaCli(lVerCli)
LOCAL nNro:=0,oQryVende
DEFAULT lVerCli := .T.
//Validar saldo de caja
IF !ValidarSaldoCaja()   
   RETURN .f.
ENDIF   

IF lVerCli
  BuscarArt(oQryCli,oDlg,oGet[08])
  IF oQryCli:zona = "2"
     MsgInfo("El cliente no esta activo para facturar!!","Error")
     oGet[08]:cText := 0
     RETURN .f.
  ENDIF
  nLista:=oQryCli:lispre
  oGet[09]:cText := oQryCli:nombre
  oGet[10]:cText := oQryCli:direccion
  oGet[11]:ctext := oQryCli:localidad
  oGet[12]:cText := oQryCli:cuit
  oGet[22]:cText := oQryCli:dni
  oGet[31]:cText := oQryCli:descuento
  oGet[37]:cText := oQryCli:iibb  * IF(oApp:percep_iibb,1,0)
  oGet[32]:cText := oApp:oServer:Query("SELECT SUM(saldo*IF(tipo='NC',-1,1)) AS deuda FROM ge_"+oApp:cId+"ventas_cuota "+;
                                       "WHERE cliente = "+ClipValue2Sql(oQryCli:codigo)):deuda
  oGet[13]:Set(oQryCli:coniva)
  oGet[09]:Refresh()
  oGet[10]:Refresh()
  oGet[11]:Refresh()
  oGet[12]:Refresh()
  oGet[22]:Refresh()
  oGet[32]:Refresh()
  oGet[13]:Refresh()
  oQryVende:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores WHERE codigo = "+ClipValue2Sql(oQryCli:vendedor))
  IF oQryVende:RecCount() > 0
     cVendedor:= oQryVende:nombre 
     oGet[36]:Refresh()
  ENDIF
  manticipo:=oQryCli:saldo
  IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"remitos WHERE facturado = 0 and codcli = " + ClipValue2Sql(oQryCli:Codigo)):RecCount() > 0
      cRemitos:= "CLIENTE CON REMITOS PENDIENTES"
      oSay3:setcolor(CLR_RED)
  ELSE
      cRemitos:= "CLIENTE SIN REMITOS PENDIENTES"
      oSay3:setcolor(CLR_GREEN)
  ENDIF
  nLisPre:= oQryCli:lispreesp
  oGet[40]:Refresh()
  oGet[41]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"lispre WHERE codigo = "+ClipValue2Sql(oQryCli:lispreesp)):nombre
ELSE
  cRemitos:= SPACE(20)
  nLista:=1
ENDIF
oSay3:Refresh()
cLetra := IF(nTipoDoc=5,"R",IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6,"A","B"),"C"))
cLetra := IF(!lFacturaM,cLetra,IF(cLetra="A","M",cLetra))
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal    
nNro:= oApp:oServer:Query("SELECT "+IF(cLetra="R","remito",IF(cLetra="A","facturaa","facturab"))+"+1 AS num FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip)):num
cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
oGet[6]:Refresh()
oSay1:SetText(cLetra) 
oGet[19]:Refresh()
oGet[20]:Refresh()
RETURN .T.



************************************************************************************
** Validar Articulo
STATIC FUNCTION ValidaArt()
LOCAL nPrecioVen,oQryPrecio

oQryArt:= oApp:oServer:Query("SELECT codigo"+IF(oApp:usar_codpro,",codigopro","")+",nombre,stockact,precioven,iva,fecmod,reventa,preciocos,endolares,marca,stockmin,impint "+;
                             "FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[14]:cText))
IF oQryArt:RecCount() = 0 .OR. oGet[14]:value = 0
  oGet[14]:cText:= 0
  BuscarArt(oQryArt,oDlg,oGet[14],,'0','nosale')
ENDIF
IF oQryArt:nRecCount = 0
   RETURN .f.
ENDIF
IF oApp:usar_dias_precio
  IF oQryArt:fecmod < (DATE()- oApp:dias_precio)
    MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
            "Verifique la fecha de modificacion","Atencion!")
    RETURN .f.
  ENDIF
ENDIF
oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+" AND "+;
                              "codart = "+ClipValue2Sql(oQryArt:codigo))
IF oQryPrecio:RecCount() = 0
   nPrecioVen:= IF(nLista=1,oQryArt:precioven,oQryArt:reventa)
ELSE
   nPrecioVen:= oQryPrecio:precio 
ENDIF
nPrecioVen:= nPrecioVen * (1+(aFormaInc[nFormaPago]/100))
oGet[15]:cText := oQryArt:nombre
oGet[16]:cText := 1
oGet[17]:ctext := IF(nTipoDoc<6,nPrecioVen,oQryArt:preciocos) * IF(oQryArt:endolares,oQryPar:dolar,1)
oGet[18]:cText := IF(nTipoDoc<6,nPrecioVen,oQryArt:preciocos) * IF(oQryArt:endolares,oQryPar:dolar,1)

     
oGet[14]:Refresh()
oGet[15]:Refresh()
oGet[16]:Refresh()
oGet[17]:Refresh()
oGet[18]:Refresh()
RETURN .t.

**********************************************************************************************
STATIC FUNCTION ValidaArtP()
    oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,stockact,precioven,iva,fecmod,reventa,preciocos,endolares,marca,stockmin,impint "+;
                             "FROM ge_"+oApp:cId+"articu WHERE codigopro = "+ClipValue2Sql(oGet[39]:cText)) 
    

IF oQryArt:RecCount() = 0 
   MsgStop("Codigo de proveedor no existe","Error")
   RETURN .f.
ENDIF
IF oApp:usar_dias_precio
  IF oQryArt:fecmod < (DATE()- oApp:dias_precio)
    MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
            "Verifique la fecha de modificacion","Atencion!")
    RETURN .f.
  ENDIF
ENDIF
oGet[14]:cText := oQryArt:codigo
oGet[15]:cText := oQryArt:nombre
oGet[16]:cText := 1
oGet[17]:ctext := IF(nTipoDoc<6,IF(nLista=1,oQryArt:precioven,oQryArt:reventa),oQryArt:preciocos) * IF(oQryArt:endolares,oQryPar:dolar,1)
oGet[18]:cText := IF(nTipoDoc<6,IF(nLista=1,oQryArt:precioven,oQryArt:reventa),oQryArt:preciocos) * IF(oQryArt:endolares,oQryPar:dolar,1)

     
oGet[14]:Refresh()
oGet[15]:Refresh()
oGet[16]:Refresh()
oGet[17]:Refresh()
oGet[18]:Refresh()
oGet[39]:oJump := oGet[16]
oGet[39]:cText := SPACE(30)
oGet[16]:SetFocus()
RETURN .t.

************************************************************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( oWnd )
LOCAL aNueva := {}, i, j
  oQryCli:End()
  oQryCli := NIL
  oQryPar:End()
  oQryPar:= nil
  oQryDet:End()
  oQryDet:= nil

  j := ASCAN(oApp:aVentanas,cVentana)
  FOR i := 1 TO LEN(oApp:aVentanas)
      IF i <> j
         AADD(aNueva,oApp:aVentanas[i])
      ENDIF
  NEXT i
  oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

************************************************************************************
** Validaciones a hacer cuando quiere grabar (Incluye forma de pago y facturacion)
STATIC FUNCTION Validaciones()
LOCAL oGet1 := ARRAY(22), oBot := ARRAY(4), oForm, lRta := .f., oBrw2, oQryCuo, dFecVto,;
      nCodCue:=0,nNumOpe:=0,nNumDep,oBrw1,nCliente,nNetoPar,aNomCondVen,aNomFormaPag,aCodCondVen,aCodFormaPag,nCondVen:=1,nFormaPag:=1,;
      cDetTar, cDetChe := SPACE(30), aTablaIva := {}, oTabIva, nNro:=0, cTipoDoc,nCodAut:=0,nCodVen:=0,;
      oQryVen, oQryPag, oQryPagCon, oQryPagFac, base, oErr, nRecibo :=0, nTipFor, nSaldo := 0,cTipo:=" ",lCuenta:=.f.,;
      oQryTar, aTarjetas, oError,oDlg2, nCodPro:=0,nCodBan:=0,cObserva1:=SPACE(255), lFisc,cCae,dFecVtoC,oComb:=ARRAY(2),;
      oQryCondVen:=oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cond_venta"),;
      oQryFormaPag:=oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"forpag"), oQryStock,;
      dFecVen:=DATE(),lGuarda:=.t.,lEnDolares:=.f.,nNumero, nPunLocal , nVuelto := 0, oFontV,;
      lImpSinIva := .f., cNomban, nSaldoCta, nNewPed, nCotiza, nPuntos := 0, nPuntosAcu := 0,;
      cNotaCre := "", lPreciosFinales := .f.
cLetra := IF(nTipoDoc=5,"R",IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6,"A","B"),"C"))
cLetra := IF(!lFacturaM,cLetra,IF(cLetra="A","M",cLetra))
// Validar que el DATOS CLIENTE
nFormaPag := nFormaPago
IF (oGet[13]:nAt <> 5 .and. (EMPTY(oGet[12]:cText) .OR. oGet[12]:cText = "  -        - ")) .and. nTipoDoc <> 6
   MsgStop("C.U.I.T. Invalido para tipo de condicion de I.V.A.","Error")
   RETURN nil
ENDIF
nCliente:= IF(nTipoCli=1,oGet[8]:value,-1)
DO CASE 
CASE nTipoDoc < 4
IF nTipoDoc = 1
   CalcularPromos()

ENDIF   
// Validacion datos Ok
//Traigo trarjetas para el detalle de la tarjeta
oQryTar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tarjetas")
aTarjetas:={}
aTarjetas:= oQryTar:FillArray(,{"nombre"})
cDetTar:= aTarjetas[1]

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_cheque` ("+;
                           "`tipo` int(1) NOT NULL DEFAULT 1,"+;
                           "`NUMBAN` int(6) NOT NULL DEFAULT 1,"+;
                           "`NUMCHE` int(10) NOT NULL DEFAULT 0,"+;
                           "`FECEMI` date DEFAULT NULL,"+;
                           "`FECVTO` date DEFAULT NULL,"+;
                           "`IMPORTE` decimal(12,2) DEFAULT 0,"+;
                           "`ORDEN` int(8) DEFAULT 0,"+;
                           "`CODPRO` int(8) DEFAULT 0, "+;
                           "`ESTADO` varchar(1) DEFAULT ' ',"+;
                           "`CODCLI` int(8) DEFAULT 0,"+;
                           "`RECIBO` int(8) DEFAULT 0,"+;
                           "PRIMARY KEY (tipo,numban,numche) ) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_cheque")
oApp:oServer:NextResult()      
oQryChe := oApp:oServer:Query("SELECT * FROM transi_cheque")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS `ventas_cuota_h` ( ";
    + "  `CUOTA` int(3) DEFAULT '0',";
    + "  `FECVTO` date DEFAULT NULL,";
    + "  `IMPORTE` decimal(12,2) DEFAULT NULL";
    + " ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
  
oApp:oServer:NextResult()
oQryCuo := oApp:oServer:Query("SELECT * FROM ventas_cuota_h  ")      
oQryCuo:ZAP()

nEfecti  := 0
nTarjet  := 0
nTransfe := 0
nCheque  := 0
nCtaCte  := 0
nMPago   := 0
nCuotas  := 1 
dFecVto  := DATE()+30
mpagado  := nTotal 
IF oApp:anticipoesvuelto    
   DEFINE FONT oFontV NAME "ARIAL" SIZE 14,20 BOLD
ENDIF
//Si es nota de credito
IF nTipoDoc = 3
   manticipo := 0
   ELSE 
   manticipo := oQryCli:saldo 
ENDIF    
aNomCondVen := {}
aCodCondVen := {}
DO WHILE !oQryCondVen:Eof()
   AADD(aNomCondVen, oQryCondVen:Nombre)
   AADD(aCodCondVen, oQryCondVen:codigo)
   oQryCondVen:Skip()
ENDDO
aNomFormaPag := {}
aCodFormaPag := {}
DO WHILE !oQryFormaPag:Eof()
   AADD(aNomFormaPag,oQryFormaPag:Nombre)
   AADD(aCodFormaPag,oQryFormaPag:codigo)
   oQryFormaPag:Skip()
ENDDO
DO WHILE .T.
DEFINE DIALOG oDlg2 RESOURCE "FORMAPAG" OF oDlg
    oDlg2:lHelpIcon := .f.
    REDEFINE GET oGet1[1] VAR mpagado   ID 110 OF oDlg2 PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet1[2] VAR manticipo ID 111 OF oDlg2 PICTURE "999999999.99" WHEN(.f.)
    REDEFINE GET oGet1[3] VAR nEfecti   ID 112 OF oDlg2 PICTURE "999999999.99"
    REDEFINE GET oGet1[4] VAR nTarjet   ID 113 OF oDlg2 PICTURE "999999999.99"
    REDEFINE GET oGet1[5] VAR nTransfe  ID 4001 OF oDlg2 PICTURE "999999999.99"
    REDEFINE GET oGet1[11] VAR nMPago   ID 4006 OF oDlg2 PICTURE "999999999.99"
    REDEFINE GET oGet1[7] VAR nCheque   ID 114 OF oDlg2 PICTURE "999999999.99" WHEN(.F.)    
    REDEFINE GET oGet1[6] VAR nCtaCte   ID 115 OF oDlg2 PICTURE "999999999.99";
                    WHEN((oGet1[6]:cText := mpagado - (manticipo+nEfecti +;
                                      nTarjet + nTransfe + nCheque + nMPago)) = "-9999999")
    IF oApp:anticipoesvuelto  
       REDEFINE GET oGet1[21] VAR nVuelto PICTURE "99999999.99" ID 4007 FONT oFontV OF oDlg2;
          WHEN((oGet1[21]:cText := IF(nCtaCte < 0 .and. nEfecti >= ABS(nCtaCte), ABS(nCtaCte),0)) = "-9999999")
       REDEFINE SAY oGet1[22] ID 4008 FONT oFontV OF oDlg2
       ELSE 
       REDEFINE GET oGet1[21] VAR nVuelto ID 4007 OF oDlg2
       REDEFINE SAY oGet1[22] PROMPT "" ID 4008 OF oDlg2
    ENDIF
    //cant cuotas
    REDEFINE GET oGet1[09] VAR nCuotas  ID 118  OF oDlg2  PICTURE "9999" WHEN (nCtaCte > 0 .and. oApp:usar_cuotas)
    //vto primera cuota
    REDEFINE GET oGet1[10] VAR dFecVto  ID 119  OF oDlg2 WHEN (nCtaCte > 0)

    //GRILLA ----------------------------------------------------
    REDEFINE XBROWSE oBrw2 DATASOURCE oQryCuo;
       COLUMNS "CUOTA","FECVTO","IMPORTE";
       HEADERS "Cuota","Fecha","Importe";
       FOOTERS ;
       SIZES 80,100,170;
    ID 4003 OF oDlg2 
    PintaBrw(oBrw2,0)
    oBrw2:aCols[2]:lAutoSave := .t.
    oBrw2:aCols[2]:nEditType := EDIT_GET 
    oBrw2:nMarqueeStyle := 6
    oBrw2:aCols[3]:nFooterTypE := AGGR_SUM
    oBrw2:MakeTotals()

    REDEFINE BUTTON oBot[1] ID 116 OF oDlg2 ACTION ;
               (AddCheqT(oBot[1]),oBrw1:Refresh(),oBrw1:MakeTotals(),;
                                oGet1[7]:cText := oBrw1:aCols[6]:nTotal,oGet1[7]:Refresh())
    REDEFINE XBROWSE oBrw1  ID 120  OF oDlg2 DATASOURCE oQryChe ;
              COLUMNS "tipo","numban","numche","fecemi","fecvto","importe";
              HEADERS "Tipo","Banco","Numero","Emision","Vto.","Importe" FOOTERS;
              SIZES 30,45,55,70,70,75
    oBrw1:bKeyDown := { | nKey, nFlags |;
       IF(nKey==46,IF(MsgNoYes("Borra el cheque?"),;
                     (oQryChe:Delete(),oBrw1:Refresh(),oBrw1:MakeTotals(),;
                      oGet1[7]:cText := oBrw1:aCols[6]:nTotal, oGet1[7]:Refresh(), oGet1[3]:SetFocus()),;
                     .f.),.f.)}      
    oBrw1:aCols[6]:nFooterType := AGGR_SUM
    PintaBrw(oBrw1,0)    

    REDEFINE COMBOBOX oComb[1] VAR nCondVen  ITEMS aNomCondVen  ID 4004 OF oDlg2
    REDEFINE COMBOBOX oComb[2] VAR nFormaPag ITEMS aNomFormaPag ID 4005 OF oDlg2 

    //arma plan 
    REDEFINE BUTTON oBot[4]  ID 201 OF oForm ACTION ArmaPLan(oGet1, oBrw2, oQryCuo );
             WHEN(IF(nTipoCli=1,ROUND(nCtaCte,2) > 0 .and. oApp:usar_cuotas,ROUND(nCtaCte,2)=0))   
    REDEFINE BUTTON oBot[2]  ID 102 OF oDlg2 ACTION (lrta:=.t.,oDlg2:End()) 
    REDEFINE BUTTON oBot[3]  ID 103 OF oDlg2 ACTION (lRtA:=.F.,oDlg2:End())
ACTIVATE DIALOG oDlg2 CENTER ON INIT  (oGet1[03]:SetFocus(),IF(!oApp:anticipoesvuelto,oGet1[21]:Hide(),NIL))


IF !lRta
   RETURN nil
ENDIF 
nCtaCte := ROUND(nCtaCte,2)
IF oApp:anticipoesvuelto
   nEfecti := nEfecti - nVuelto 
   nCtaCte := nCtaCte + nVuelto
ENDIF   
IF ROUND(nCtaCte,2) > 0 .and. oApp:usar_cuotas .and. oQryCuo:nRecCount = 0
   MsgStop("No genero el plan de cuotas","Error")
   LOOP
ENDIF

IF ROUND(nCtaCte,2) > 0 .and. nCliente <= 1
   MsgStop("Consumidor final no puede pagar en Cta.Cte.","Error")
   LOOP
ENDIF 

IF ROUND(nCtaCte,2) < 0 .and. nCliente <= 1
   MsgStop("Consumidor final no puede quedar con anticipo","Error")
   LOOP
ENDIF  

IF oApp:usar_limite_cred .and. oQryCli:limite <> 0 .and. nTipoDoc <> 3
  nSaldoCta := oApp:oServer:Query("SELECT SUM(saldo * if(tipo='NC',-1,1)) AS deuda FROM ge_"+oApp:cId+"ventas_cuota "+;
                                       "WHERE cliente = "+ClipValue2Sql(nCliente)):deuda 
  IF nCtaCte > 0 .AND. ((nCtaCte - oQryCli:saldo + nSaldoCta ) > oQryCli:limite) .and. nCliente > 1
     IF oApp:usar_clave
       IF !PedirClave("El cliente que quiere facturar tiene el limite de credito excedido, ingrese la clave de autorizacion para continuar",oDlg)
          LOOP
       ENDIF
       ELSE
       IF !MsgNoYes("El cliente que quiere facturar tiene el limite de credito excedido, desea continuar","Atencion")
          LOOP
       ENDIF
     ENDIF      
  ENDIF
ENDIF

IF nCliente = -1 .and. ROUND(nCtaCte,2) > 0 
   MsgStop("Un cliente ocacional no puede pagar en Cta. Cte. "+str(nCtaCte),"Error")
   LOOP
ENDIF

IF oApp:usar_dias_deuda
    IF oApp:oServer:Query("SELECT DATEDIFF(CURDATE(),MIN(fecvto)) AS dias FROM ge_"+oApp:cId+"ventas_cuota "+;
                          "WHERE saldo > 0 AND cliente = "+ClipValue2Sql(oGet[08]:cText)):dias > oApp:dias_deuda
      IF oApp:usar_clave 
       IF !PedirClave("El cliente que quiere facturar tiene una deuda impaga que excede el limite de dias permitidos a deber,"+;
                      " ingrese la clave de autorizacion para continuar",oDlg)
          LOOP
       ENDIF
       ELSE 
       IF !MsgNoYes("El cliente que quiere facturar tiene una deuda impaga que excede el limite de dias permitidos a deber,"+;
                      " desea continuar?","Atencion")
          LOOP
       ENDIF
      ENDIF 
    ENDIF
ENDIF

nCondVen := aCodCondVen[nCondVen]
nFormaPag:= aCodFormaPag[nFormaPag]

IF nTransfe > 0
     lCuenta:=  DatosTransferencia(@nCodCue,@nNumOpe,@cObserva1)
     IF !lCuenta
        LOOP
     ENDIF
ENDIF  
EXIT 
ENDDO

oTabIva := oApp:oServer:Query("SELECT codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM ventas_det_H GROUP BY codiva")
DO WHILE !oTabIva:Eof()
   AADD(aTablaIva,{oTabIva:codiva,oTabIva:neto,oTabIva:iva})
   oTabIva:Skip()
ENDDO
IF nTipoDoc<=3
   dFecVtoC:= DATE()
   cCae:= ""
   nTipFor:=01
   lFisc:= MsgYesNo("¿Desea emitir el factura fiscal?","Atencion!")
   IF lFisc
      IF oQryPun:tipofac = 1
          nPunLocal :=  oApp:oServer:Query("SELECT punto FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):punto
          IF nPunLocal > 0
             nPuntoVta := nPunLocal
             ELSE 
             nPuntoVta:= oApp:oServer:Query("SELECT prefijo FROM ge_"+oApp:cId+"parametros LIMIT 1"):prefijo
          ENDIF
          IF cLetra = "A" .and. !ConsultaCuitRapida(val(STRTRAN(oQryCli:cuit,"-","")),oQryCli:coniva)
             RETURN nil 
          ENDIF      
          FacturaElec(oGet, nTipoFac, nPuntoVta, nTipoDoc, cLetra, aTablaIva, oBrw, @nNro, @cCae, @dFecVtoC,@nTipFor,,lFacturaD,@nCotiza,@cNotaCre)
          IF nNro = 0
             MsgStop("Fallo el Comunicacion con WebService AFIP","Error")
             Return nil 
          ENDIF
      ELSE
          nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
          nNro := FacturaFiscal(oQryDet,oGet[08]:Value,aNomFormaPag[nFormaPag],nTotal,0,IF(nTipoDoc=3,'N','T'))
          IF nNro = 0
             MsgStop("Fallo el impresor fiscal","Error")
             Return nil 
          ENDIF 
      ENDIF     
   ELSE
     nNro := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):presupu+1
     cLetra := "X"
     cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
     cTipoDoc := IF(nTipoDoc=1,"FC",IF(nTipoDoc=2,"ND","NC"))
     
   ENDIF
   // Falta las impresiones fiscales de NC Y ND y Presupuesto y Remito  
ENDIF
cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
cTipoDoc := IF(nTipoDoc=1,"FC",IF(nTipoDoc=2,"ND","NC"))
  oQryPag    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagos LIMIT 0")
  oQryPagFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagfac LIMIT 0")
  oQryPagCon := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagcon LIMIT 0")
  oQryVen    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ventas_encab LIMIT 0")
  oQryCuo    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ventas_cuota LIMIT 0")
  // Grabar la factura
  // Grabo el pago

  TRY 

 
 oApp:oServer:BeginTransaction()
      IF nEfecti + nTarjet + nCheque + nTransfe + manticipo + nMPago > 0
          // Grabo el pago si no es todo Cuenta Corriente
          //1 - GRABACION DE PAGO -------------------------------------------------------------------
          nRecibo :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")

           // Grabo el registro de PAGOS
          base := oQryPag:GetBlankRow()
          base:numero  := nRecibo
          base:cliente := nCliente
          base:total   := (nEfecti + nTarjet + nTransfe + nCheque + nMPago) * IF(cTipoDoc="NC",-1,1) 
          base:fecha   := oGet[1]:value
          base:usuario := oApp:usuario
          base:fecmod  := DATE()
          base:ip      := oApp:cIp
          base:caja    := oApp:prefijo
          base:vendedor:= cVendedor
          base:interes := 0
          oQryPag:oRow := base
          oQryPag:Save()

          //Grabo Pago Factura
          base := oQryPagFac:GetBlankRow()
          base:numero := nRecibo
          base:ticomp:= LEFT(cTipoDoc,2)
          base:letra := LEFT(cNumComp,1)
          base:numcomp:= RIGHT(cNumComp,13)
          base:fecha:= oGet[1]:value
          base:importe := IF(nEfecti + nTransfe + nTarjet + nCheque + manticipo + nMPago > nTotal,nTotal,;
                            nEfecti + nTransfe + nTarjet + nCheque + manticipo + nMPago) * IF(cTipoDoc="NC",-1,1)
          oQryPagFac:oRow := base
          oQryPagFac:Save()
        
          
          // Grabo los conceptos pagados
          IF nEfecti > 0
                  base := oQryPagCon:GetBlankRow()
                  base:numero  := nRecibo
                  base:importe := nEfecti * IF(cTipoDoc="NC",-1,1)
                  base:observa := "EFECTIVO"
                  base:codcon := 1
                  base:tipocon:= 1
                  oQryPagCon:oRow := base
                  oQryPagCon:Save()
                  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",1,1,"+ClipValue2Sql(nEfecti * IF(cTipoDoc="NC",-1,1))+","+;
                                      "'EFECTIVO',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
          ENDIF   

           // INGRESO CONCEPTO TRANSFERENCIA
           IF nTransfe > 0
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                              " (banco,tipo,fecemi,fecacr,numope,detalle,usuario,fecmod,ip,importe) VALUES "+;
                              " ("+;
                                ClipValue2SQL(nCodCue)+","+;
                                "'D',"+;
                                ClipValue2SQL(DATE())+","+;
                                  ClipValue2SQL(DATE())+","+;
                                  ClipValue2Sql(nNumOpe)+","+;
                                  ClipValue2SQL(cObserva1)+","+;
                                  ClipValue2SQL(oApp:usuario)+","+;
                                  ClipValue2SQL(DATE())+","+;
                                  ClipValue2SQL(oApp:cIp)+","+;
                                  ClipValue2SQL(nTransfe)+")")
              nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM ge_"+oApp:cId+"deposito"):numero 
              oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagos SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nRecibo))
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nRecibo)+","+;
                                                     "codcon  = 2, "+;
                                                     "tipocon  = 2, "+;
                                                     "importe = "+ ClipValue2Sql(nTransfe * IF(cTipoDoc="NC",-1,1))+","+;
                                                     "observa = 'TRANSFERENCIA'")
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",2,2,"+ClipValue2Sql(nTransfe * IF(cTipoDoc="NC",-1,1))+","+;
                                      "'TRANSFERENCIA',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
           ENDIF
          
          IF ncheque > 0
             oQryChe:GoTop()
             DO WHILE !oQryChe:Eof()
                cNomBan := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"bancos WHERE codigo = "+ClipValue2Sql(oQryChe:numban)):nombre
                oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nRecibo)+","+;
                                                          "codcon  = 3, "+;
                                                          "tipocon  = 3, "+;
                                                           "importe = "+ ClipValue2Sql(oQryChe:importe)+","+;
                                                           "observa = '"    + ALLTRIM(cNomBan)+;
                                                                     " NRO "+ STR(oQryChe:numche,10)+;
                                                                     " VTO "+ DTOC(oQryChe:fecvto)+"'")
                oQryChe:Skip()
             ENDDO
             oQryChe:GoTop()   
             /*base := oQryPagCon:GetBlankRow()
             base:numero  := nRecibo
             base:importe := nCheque * IF(cTipoDoc="NC",-1,1)
             base:observa := IF(EMPTY(cDetChe),"CHEQUE: " + STR(nRecibo),cDetChe)
             base:codcon := 3
             base:tipocon := 3
             oQryPagCon:oRow := base
             oQryPagCon:Save()*/
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",3,3,"+;
                                      ClipValue2Sql(nCheque * IF(cTipoDoc="NC",-1,1))+","+;
                                      ClipValue2Sql(IF(EMPTY(cDetChe),"CHEQUE: " + STR(nRecibo),cDetChe))+","+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
          ENDIF   

          IF nTarjet > 0
             base := oQryPagCon:GetBlankRow()
             base:numero  := nRecibo
             base:importe := nTarjet * IF(cTipoDoc="NC",-1,1)
             base:codcon := 4
             base:tipocon := 4
             base:observa := IF(EMPTY(cDetTar),"TARJETA: " + STR(nRecibo),"TARJETA")
             oQryPagCon:oRow := base
             oQryPagCon:Save()
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",4,4,"+ClipValue2Sql(nTarjet * IF(cTipoDoc="NC",-1,1))+","+;
                                      "'TARJETA',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
          ENDIF   
          IF nMPago > 0
             base := oQryPagCon:GetBlankRow()
             base:numero  := nRecibo
             base:importe := nMPago * IF(cTipoDoc="NC",-1,1)
             base:codcon := 8
             base:tipocon := 8
             base:observa := "MERCADO PAGO: " + STR(nRecibo)
             oQryPagCon:oRow := base
             oQryPagCon:Save()
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",8,8,"+ClipValue2Sql(nMPago * IF(cTipoDoc="NC",-1,1))+","+;
                                      "'M.PAGO',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
          ENDIF   
          IF manticipo > 0
            oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nRecibo)+","+;
                                               "codcon  = 7, "+;
                                               "tipocon  = 7, "+;
                                               "importe = "+ ClipValue2Sql(manticipo * IF(cTipoDoc="NC",-1,1))+","+;
                                               "observa = 'ANTICIPO'")
            oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                             "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                        ClipValue2Sql(RIGHT(cNumComp,13))+",7,7,"+ClipValue2Sql(manticipo * IF(cTipoDoc="NC",-1,1))+","+;
                                        "'ANTICIPO',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
          ENDIF          
      ENDIF  
      nNetoPar:= IF(nCtaCte<oBrw:aCols[7]:nTotal,nCtaCte,oBrw:aCols[7]:nTotal)
      //2 - CUOTAS DE PAGO EN CTA CTE ------------------------------------------------------    
      IF oApp:usar_cuotas  
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
                                                        "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip,saldodolar) "+;
                              "(SELECT "+ClipValue2Sql(cTipoDoc)+","+;
                                         ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                         ClipValue2Sql(RIGHT(cNumComp,13))+","+;
                                         "cuota," + ClipValue2Sql(oGet1[9]:value) +","+;
                                         "CURDATE(),"+ ClipValue2Sql(nCliente)+","+ClipValue2Sql(nNetoPar/oGet1[9]:value)+","+;
                                         "importe,"+IF(nCtaCte>=0,"importe","0")+","+IF(nCtaCte=0,"'P'","'I'")+",fecvto, "+;
                                         ClipValue2Sql(oGet[9]:cText)+","+;
                                         ClipValue2Sql(oGet[12]:cText)+","+;
                                         ClipValue2Sql(oGet[22]:cText)+","+;
                                         ClipValue2Sql(oGet[10]:cText)+","+;
                                         ClipValue2Sql(oGet[11]:cText)+","+;
                                         ClipValue2SQL(oApp:usuario)+","+;
                                         ClipValue2SQL(cVendedor)+","+;
                                         ClipValue2SQL(DATE())+","+;
                                         ClipValue2SQL(oApp:cIp)+", "+;
                                         IF(lFacturaD,+IF(nCtaCte>=0,"importe/"+STR(nCotiza),"0"),"0")+;
                              " FROM ventas_cuota_h)")
      ENDIF
      IF !oApp:usar_cuotas
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
                                                        "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip,saldodolar) "+;
                              "VALUES ("+ClipValue2Sql(cTipoDoc)+","+;
                                         ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                         ClipValue2Sql(RIGHT(cNumComp,13))+","+;
                                         "0," + ClipValue2Sql(oGet1[9]:value) +","+;
                                         "CURDATE(),"+ ClipValue2Sql(nCliente)+",0,"+;
                                         ClipValue2Sql(nTotal)+","+;
                                         IF(nCtaCte>0,ClipValue2Sql(nCtaCte),"0")+",'P',CURDATE(),"+;
                                         ClipValue2Sql(oGet[9]:cText)+","+;
                                         ClipValue2Sql(oGet[12]:cText)+","+;
                                         ClipValue2Sql(oGet[22]:cText)+","+;
                                         ClipValue2Sql(oGet[10]:cText)+","+;
                                         ClipValue2Sql(oGet[11]:cText)+","+;
                                         ClipValue2SQL(oApp:usuario)+","+;
                                         ClipValue2SQL(cVendedor)+","+;
                                         ClipValue2SQL(DATE())+","+;
                                         ClipValue2SQL(oApp:cIp)+","+;
                                         IF(lFacturaD,+IF(nCtaCte>=0,Clipvalue2sql(nCtaCte/nCotiza),"0"),"0")+;
                                         ")")
      ENDIF
      //3 - FACTURA ------------------------------------------------------------------------
      IF nCtaCte <= 0  
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = "+ClipValue2Sql(ABS(nCtaCte)) + " WHERE codigo = " +ClipValue2Sql(nCliente))
      ELSE
         IF nTipoDoc <> 3
            oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = 0 WHERE codigo = " +ClipValue2Sql(nCliente))
         ENDIF   
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                             "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                        ClipValue2Sql(RIGHT(cNumComp,13))+",5,5,"+ClipValue2Sql(nCtaCte)+","+;
                                        "'CTA. CTE.',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
      ENDIF

      DO WHILE !oQryChe:Eof()
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cheter SET numban  = "+ClipValue2Sql(oQryChe:numban)+","+;
                                                            "numche  = "+ClipValue2Sql(oQryChe:numche)+","+;
                                                            "fecing  = "+ClipValue2Sql(oQryChe:fecemi)+","+;
                                                            "fecvto  = "+ClipValue2Sql(oQryChe:fecvto)+","+;
                                                            "importe = "+ClipValue2Sql(oQryChe:importe)+","+;
                                                            "recibo  = "+ClipValue2Sql(nRecibo)+","+;
                                                            "codcli  = "+ClipValue2Sql(nCliente)+","+;
                                                            "noorden = 0,"+;
                                                            "demo    = 0,"+;
                                                            "usuario = "+ClipValue2Sql(oApp:usuario)+","+;
                                                            "fecmod  = CURDATE(),"+;
                                                            "ip      = "+ClipValue2Sql(oApp:cIp)+","+;
                                                            "estado  = 'C'")
          oQryChe:Skip()
     ENDDO   
      
      //-- DETALLE DE IVA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventivadet (tipocomp,letra,numfac,codiva,neto,iva) "+;
                           "(SELECT "+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+;
                            ", codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM ventas_det_H GROUP BY codiva)")
      //-- detalle de venta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
                        " (codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,codiva,neton,descu,pcosto,impint,descup,bultos) "+;
                        " (SELECT codart,detart,cantidad,punit,"+ClipValue2Sql(oGet[1]:value)+","+ClipValue2Sql(nCliente)+","+;
                        "         "+ ClipValue2Sql(cTipoDoc+cNumComp)+",ptotal, stotal,iva,codiva,neto,descuento,pcosto,impint,descup,bultos FROM ventas_det_H)")

      //-- encabezado de venta
      IF oApp:usar_puntos
         nPuntosAcu := oApp:oServer:Query("SELECT puntos FROM ge_"+oApp:cId+"clientes  WHERE codigo = "+ClipValue2Sql(nCliente) ):puntos
         nPuntosAcu := nPuntosAcu + INT(nTotal/oApp:pesos_x_punto)
         nPuntos :=  INT(nTotal/oApp:pesos_x_punto)
      ENDIF
      IF EMPTY(cNotaCre)
         IF !EMPTY(cOrigenNC) .AND. cTipoDoc = 'NC'
            cNotaCre := cOrigenNC
         ENDIF
      ENDIF      
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,coniva,fecha,neto,iva,iibb,importe,tipopag,observa,"+;
                                                     "nombre,cuit,dni,direccion,localidad,percep,cae,fecvto,tipfor,usuario,fecmod,ip,vendedor,condven,"+;
                                                     "formapag,sobretasa,acopio,endolares,cotiza,hora,puntos,puntosacu) VALUES "+;
                           "("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+","+;
                            ClipValue2Sql(nCliente)+","+ClipValue2Sql(nConIva)+","+;
                            ClipValue2Sql(oGet[1]:value)+","+ClipValue2Sql(oBrw:aCols[7]:nTotal)+","+ClipValue2Sql(oBrw:aCols[8]:nTotal)+","+;
                            ClipValue2SQL(oGet[38]:cText)+","+ClipValue2Sql(nTotal)+","+IF(nCtaCte>0,"2","1")+","+;
                            ClipValue2Sql(IF(EMPTY(cNotaCre),"",cNotaCre+" - ")+ALLTRIM(oGet[23]:cText)+IF(nDescuGen>0," Descuento: %"+ALLTRIM(STR(nDescuGen,5,2)),""))+","+;
                            ClipValue2Sql(oGet[9]:cText)+","+ClipValue2Sql(oGet[12]:cText)+","+ClipValue2Sql(oGet[22]:cText)+","+;
                            ClipValue2Sql(oGet[10]:cText)+","+ClipValue2Sql(oGet[11]:cText)+","+ClipValue2SQL(oGet[37]:cText)+","+;
                            ClipValue2Sql(cCae)+","+ClipValue2Sql(dFecVtoC)+","+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+","+;
                            ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2Sql(cVendedor)+","+;
                            ClipValue2Sql(nCondVen)+","+ClipValue2Sql(nFormaPag)+","+ ClipValue2SQL(oGet[42]:cText)+","+ClipValue2Sql(lAcopio)+","+;
                            IF(lFacturaD,"TRUE","FALSE")+","+IF(lFacturaD,ClipValue2SQL(nCotiza),"0")+;
                            ",CURTIME(),"+Clipvalue2sql(nPuntos)+","+ClipValue2Sql(nPuntosAcu) +")")        
      
      IF oApp:usar_puntos
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos + "+ClipValue2Sql(INT(nTotal/oApp:pesos_x_punto)) +;
          " WHERE codigo = "+ClipValue2Sql(nCliente) )
      ENDIF
      //Auditoria
      IF nDescuGen > 0
         Auditar(6," "+cTipoDoc+cNumcomp+" "+alltrim(STR(nDescuGen,6,2))+"% Caja "+STR(oApp:prefijo,4))
         ELSE
         oQryDet:GoTop()
         DO WHILE !oQryDet:Eof()
            IF oQryDet:descup > 0 
               Auditar(6," "+cTipoDoc+cNumcomp+" "+alltrim(STR(oQryDet:descup,6,2))+"% Caja "+STR(oApp:prefijo,4)+;
                " Puntual "+oQryDet:detart)
            ENDIF
            oQryDet:Skip()
         ENDDO
      ENDIF

      //ACTUALIZO EL STOCK DE LOS ARTICULOS VENDIDOS (SI NO ES ACOPIO)
      //oApp:oServer:Execute("UPDATE  ge_"+oApp:cId+"articu a SET a.stockact = a.stockact - "+;
      //                     "(SELECT SUM(v.cantidad * IF("+ClipValue2Sql(cTipoDoc)+"='NC',(-1),1)) FROM ventas_det_H v WHERE v.codart = a.codigo GROUP BY v.codart ) ")

      // Primero actualizo los que tienen stock propio
      IF !lAcopio
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
                   "INNER JOIN "+; 
                   "("+; 
                   "SELECT codart, SUM(cantidad) as suma "+;
                   "FROM ventas_det_H "+;
                   "GROUP BY codart "+;
                   ") v ON a.codigo = v.codart "+;
                   "SET a.stockact = a.stockact - (v.suma * "+IF(cTipoDoc="NC","-1","1")+") WHERE a.stockotro IS FALSE")

          // Actualizo el stock de los que descuentan de otros articulos
          oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) * ("+IF(cTipoDoc="NC","-1","1")+") AS cantidad,"+;
                                         "d.codart AS codart FROM ventas_det_H d "+;
                                         "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                         "WHERE a.stockotro = TRUE GROUP BY d.codart ")
          oQryStock:GoTop()
          DO WHILE !oQryStock:EOF()
             oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                                  " ON m.codigo = r.codusa "+;
                                  "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                                  "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
             oQryStock:Skip()
          ENDDO
      ENDIF


      //BORRO FACTURAS PENDIENTES USADAS (SI NO USA NINGUNA ES 0)
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab_p WHERE id = "+ClipValue2Sql(nBorrarPend))
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det_p   WHERE numven = "+ClipValue2Sql(nBorrarPend))
      //BORRO PRESUPUESTOS USADOS (SI NO USA NINGUNA ES 0)
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"presupuestos SET estado = 2 WHERE id = "+ClipValue2Sql(nBorrarPresu))
      ***oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"presupuestos_det   WHERE numven = "+ClipValue2Sql(nBorrarPresu))

      IF lFisc       
         IF cLetra = "A"
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturaa = "+ClipValue2Sql(nNro)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))
         ELSE  
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturab = "+ClipValue2Sql(nNro)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))          
         ENDIF 
      ELSE
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET presupu = presupu+1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
      ENDIF         
      oApp:oServer:CommitTransaction()
      IF lFisc 
         IF oApp:factura = 1
            PrintFactuElec(cTipoDoc,cNumComp)  
         ENDIF
      ELSE 
        IF oQryPar:pregunta_ticket
          IF MsgYesNo("¿Desea imprimir el ticket no fiscal?","Atencion!")
            FacturaNoFiscal(cTipoDoc,cNumComp)            
          ENDIF
          ELSE
          FacturaNoFiscal(cTipoDoc,cNumComp)
        ENDIF
      ENDIF
      IF nRecibo > 0
         Reci(nRecibo)
      ENDIF
      //-- BORRO PEDIDO SI LO USO
      /*IF lUsoPedido
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos SET cantidad = faltantes, faltantes = 0 WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText))
         oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos WHERE cantidad = 0 AND codcli = "+ ClipValue2Sql(oGet[8]:cText))
         IF oApp:oServer:Query("SELECT COUNT(codcli) as cant FROM ge_"+oApp:cId+"pedidos WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText)):cant > 0
            IF !MsgYesNo("El pedido del cliente tiene faltantes"+chr(10)+"Desea generar un pedido nuevo con los faltantes?","Atencion")
               oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText))
            ENDIF    
         ENDIF         
      ENDIF*/
      //-- BORRO PEDIDO SI LO USO
      IF lPedidoUsado = .t.
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos_encab SET estado = 'F',facturanro = "+ClipValue2Sql(cTipoDoc+cNumComp)+" "+;
                            "WHERE id IN (SELECT id FROM pedidos_temp WHERE tilde )")
         lPedidoUsado:=.f.         
         //Aca hago las comprobaciones si desea guardar los faltantes como pedido nuevo
         IF (oApp:oServer:Query("SELECT COUNT(id) as cant FROM ge_"+oApp:cId+"pedidos_det "+;
                                " WHERE cantidadreal < cantidad "+;
                                " AND idpedido IN (SELECT id FROM pedidos_temp WHERE tilde )"):cant > 0)
            IF MsgYesNo("Los pedidos del cliente tienen faltantes"+chr(10)+;
               "Desea generar un pedido nuevo con los faltantes?","Atencion")
               //Genero un nuevo pedido con todos los productos faltantes 
               //Primero ingreso el encabezado
               oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedidos_encab "+;
                " (codcli,cliente,codven,vendedor,fecha,parafecha,estado,observa) "+;
                "VALUES ("+ClipValue2Sql(nCliente)+','+ClipValue2Sql(oGet[9]:cText)+','+ClipValue2Sql(nCondVen)+","+;
                            ClipValue2Sql(cVendedor)+',CURDATE(),CURDATE(),"P","Creado por faltantes")')
               nNewPed := oApp:oServer:LastInsertID()
               //Luego el cuerpo
               oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedidos_det "+;
                " (idpedido,codart,detart,cantidad,cantidadreal,punitario)  "+;
                " ( SELECT "+ClipValue2Sql(nNewPed)+",codart,detart,cantidad - cantidadreal,cantidad - cantidadreal,"+;
                "   punitario FROM ge_"+oApp:cId+"pedidos_det  WHERE cantidadreal < cantidad "+;
                                " AND idpedido IN (SELECT id FROM pedidos_temp WHERE tilde ) ) ")               
            ENDIF 
         ENDIF 
         oApp:oServer:Execute("TRUNCATE pedidos_temp")    
      ENDIF
  CATCH oErr
      MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN .F.
  END TRY
 /*
  IF nEfecti+nTarjet+nCheque+manticipo > 0  
     lRta := MsgYesNo("Desea imprimir el recibo de anticipos?","Atencion")
     IF lRta 
        Reci(nRecibo,.f.)
     ENDIF
  ENDIF   
*/
CASE nTipoDoc = 4
     nCliente:= IF(nTipoCli=1,oGet[8]:value,-1)
     IF !PreguntasPresupu(@lEnDolares,@dFecVen,@lGuarda,@lImpSinIva,@lPreciosFinales)
        RETURN .f. 
     ENDIF     

     IF lGuarda
        cVendedor := IF(EMPTY(cVendedor),oApp:usuanom,cVendedor)
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"presupuestos (vendedor,fecha,fecvto,codcli,nombre,cuit,dni,direccion,localidad,coniva,importe,usuario,caja,estado,observa) "+;
                             "VALUES("+ClipValue2Sql(cVendedor)+",CURDATE(),"+ClipValue2Sql(dFecVen)+","+ClipValue2Sql(nCliente)+","+ClipValue2Sql(oGet[9]:cText)+","+;
                              ClipValue2Sql(oGet[12]:cText)+","+ClipValue2Sql(oGet[22]:cText)+","+;
                              ClipValue2Sql(oGet[10]:cText)+","+ClipValue2Sql(oGet[11]:cText)+","+ClipValue2Sql(nConIva)+","+;
                              ClipValue2Sql(nTotal)+","+ClipValue2Sql(oApp:usuario)+","+ClipValue2Sql(oApp:prefijo)+",1,"+ClipValue2SQL(oGet[23]:cText)+")")
        nNumero:= oApp:oServer:Query("SELECT MAX(id) AS ultimo FROM ge_"+oApp:cId+"presupuestos"):ultimo
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"presupuestos_det "+;
                          " (numven,codart,detart,cantidad,punit,codcli,importe,neto,iva,codiva,neton,descu,pcosto,descup) "+;
                          " (SELECT "+ClipValue2Sql(nNumero)+",codart,detart,cantidad,punit,"+ClipValue2Sql(nCliente)+","+;
                          " ptotal, stotal,iva,codiva,neto,descuento,pcosto,descup FROM ventas_det_H)")
        cNumcomp := STRTRAN("P" + STR(nPuntoVta,4)+"-"+STR(nNumero,8)," ","0")
        PrintPresupu(oQryDet,oGet,oBrw,lEnDolares,dFecVen,cNumComp,lImpSinIva,lPreciosFinales)
        ELSE 
        nNumero := oApp:oServer:Query("SELECT presu FROM ge_"+oApp:cId+"parametros LIMIT 1"):presu
        cNumcomp := STRTRAN("P" + STR(0,4)+"-"+STR(nNumero,8)," ","0")
        PrintPresupu(oQryDet,oGet,oBrw,lEnDolares,dFecVen,cNumComp, lImpSinIva,lPreciosFinales)
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"parametros SET presu = presu + 1")
      ENDIF

CASE nTipoDoc = 5
  nCodAut:=0
  cTipoDoc:="RE"
  cNumComp:= STRTRAN(STR(nPuntoVta,4)+"-"+STR(oApp:oServer:Query("SELECT remito FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):remito+1,8)," ","0")  
  TRY
  oApp:oServer:BeginTransaction()                     
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"remitos "+;
                        " (codart,detart,cantidad,fecha,codcli,nrorem,codiva,facturado,incrp,importe,iva,neto,neton,tipo,auto,vendedor) "+;
                        " (SELECT codart,detart,cantidad,"+ClipValue2Sql(oGet[1]:value)+","+ClipValue2Sql(oGet[8]:value)+","+;
                        + ClipValue2Sql(cTipoDoc+cNumComp)+",codiva,FALSE,descup,0,0,0,0, "+;
                        "'I',bultos,"+ClipValue2Sql(cVendedor)+" "+;
                        "   FROM ventas_det_H WHERE codart > 0)")
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"remitos "+;
                        " (codart,detart,cantidad,fecha,codcli,nrorem,codiva,facturado,incrp,importe,iva,neto,neton,tipo,auto,vendedor) "+;
                        " (SELECT codart,detart,cantidad,"+ClipValue2Sql(oGet[1]:value)+","+ClipValue2Sql(oGet[8]:value)+","+;
                        + ClipValue2Sql(cTipoDoc+cNumComp)+",codiva,FALSE,descup,ptotal,iva,stotal,neto, "+;
                        "'I',bultos,"+ClipValue2Sql(cVendedor)+" "+;
                        "   FROM ventas_det_H WHERE codart = 0)")
  //Actualizo pedidos
  /*IF lUsoPedido
     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos SET cantidad = faltantes, faltantes = 0 WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText))
     oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos WHERE cantidad = 0 AND codcli = "+ ClipValue2Sql(oGet[8]:cText))
     IF oApp:oServer:Query("SELECT COUNT(codcli) as cant FROM ge_"+oApp:cId+"pedidos WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText)):cant > 0
        IF !MsgYesNo("El pedido del cliente tiene faltantes"+chr(10)+"Desea generar un pedido nuevo con los faltantes?","Atencion")
           oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos WHERE codcli = "+ ClipValue2Sql(oGet[8]:cText))
        ENDIF    
     ENDIF         
  ENDIF*/
  IF lPedidoUsado = .t.
     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos_encab SET estado = 'F',facturanro = "+ClipValue2Sql(cTipoDoc+cNumComp)+" "+;
                        "WHERE id IN (SELECT id FROM pedidos_temp WHERE tilde )")
     lPedidoUsado:=.f.         
     //Aca hago las comprobaciones si desea guardar los faltantes como pedido nuevo
     IF (oApp:oServer:Query("SELECT COUNT(id) as cant FROM ge_"+oApp:cId+"pedidos_det "+;
                            " WHERE cantidadreal < cantidad "+;
                            " AND idpedido IN (SELECT id FROM pedidos_temp WHERE tilde )"):cant > 0)
        IF MsgYesNo("Los pedidos del cliente tienen faltantes"+chr(10)+;
           "Desea generar un pedido nuevo con los faltantes?","Atencion")
           //Genero un nuevo pedido con todos los productos faltantes 
           //Primero ingreso el encabezado
           oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedidos_encab "+;
            " (codcli,cliente,codven,vendedor,fecha,parafecha,estado,observa) "+;
            "VALUES ("+ClipValue2Sql(nCliente)+','+ClipValue2Sql(oGet[9]:cText)+','+ClipValue2Sql(nCondVen)+","+;
                        ClipValue2Sql(cVendedor)+',CURDATE(),CURDATE(),"P","Creado por faltantes")')
           nNewPed := oApp:oServer:LastInsertID()
           //Luego el cuerpo
           oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedidos_det "+;
            " (idpedido,codart,detart,cantidad,cantidadreal,punitario)  "+;
            " ( SELECT "+ClipValue2Sql(nNewPed)+",codart,detart,cantidad - cantidadreal,cantidad - cantidadreal,"+;
            "   punitario FROM ge_"+oApp:cId+"pedidos_det  WHERE cantidadreal < cantidad "+;
                            " AND idpedido IN (SELECT id FROM pedidos_temp WHERE tilde ) ) ")               
        ENDIF 
     ENDIF 
     oApp:oServer:Execute("TRUNCATE pedidos_temp")    
  ENDIF
  //ACTUALIZO EL STOCK DE LOS ARTICULOS VENDIDOS
  //oApp:oServer:Execute(" UPDATE ventas_det_H v LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart SET a.stockact = a.stockact - v.cantidad")
  // Primero actualizo los que tienen stock propio
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
               "INNER JOIN "+; 
               "("+; 
               "SELECT codart, SUM(cantidad) as suma "+;
               "FROM ventas_det_H "+;
               "GROUP BY codart "+;
               ") v ON a.codigo = v.codart "+;
               "SET a.stockact = a.stockact - v.suma WHERE a.stockotro IS FALSE")

      // Actualizo el stock de los que descuentan de otros articulos
      oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                     "d.codart AS codart FROM ventas_det_H d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE a.stockotro = TRUE GROUP BY d.codart ")
      oQryStock:GoTop()
      DO WHILE !oQryStock:EOF()
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                              " ON m.codigo = r.codusa "+;
                              "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                              "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
         oQryStock:Skip()
      ENDDO

  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET remito = remito + 1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
  oApp:oServer:CommitTransaction()
  PrintRemito(oQryDet,oGet,oBrw,cNumComp)
CATCH oError
   ValidaError(oError)
END TRY
ENDCASE 
LimpiarForm()
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

*********************************************************************************************************************************
************* SELECCIONA EL TIPO DE REMITO (INTERNO O EXTERNO)
STATIC FUNCTION TipoDeRemito(nCodAut,nCodVen,cTipo)
LOCAL oDlgR,oGet1:=ARRAY(4),oRadio,cNomAut:=SPACE(30),cNomVen:=SPACE(30),;
      oQryVend,oQryAut,lRta:=.f.,oBot1:=ARRAY(2),nTipo:=2
oQryVend:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")
oQryAut:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"auto")
nCodAut:=0
nCodVen:=0
DEFINE DIALOG oDlgR RESOURCE "REMITO" OF oDlg
oDlgR:lHelpIcon := .f.

 REDEFINE RADIO oRadio VAR nTipo ID 100,200 OF oDlgR
 REDEFINE GET oGet1[1] VAR nCodAut ID 101 OF oDlgR PICTURE "999999" WHEN(nTipo=1);
              VALID(Buscar(oQryAut,oDlgR,oGet1[1],oGet1[2]));
              ACTION (oGet1[1]:cText:= 0, Buscar(oQryAut,oDlgR,oGet1[1],oGet1[2])) BITMAP "BUSC1" 
 REDEFINE GET oGet1[2] VAR cNomAut ID 102 OF oDlgR PICTURE "@!" WHEN(.F.)
 REDEFINE GET oGet1[3] VAR nCodVen ID 103 OF oDlgR PICTURE "99" WHEN(nTipo=1);
              VALID(Buscar(oQryVend,oDlgR,oGet1[3],oGet1[4]));
              ACTION (oGet1[3]:cText:= 0, Buscar(oQryVend,oDlgR,oGet1[3],oGet1[4])) BITMAP "BUSC1" 
 REDEFINE GET oGet1[4] VAR cNomVen ID 104 OF oDlgR PICTURE "@!" WHEN(.F.)

 REDEFINE BUTTON oBot1[1] ID 300 OF oDlgR ACTION (lrta:=.t.,oDlgR:End()) 
 REDEFINE BUTTON oBot1[2] ID 301 OF oDlgR ACTION oDlgR:End()

ACTIVATE DIALOG oDlgR CENTER //ON INIT oGet1[01]:SetFocus()
IF !lRta 
   RETURN .f.
ENDIF
cTipo:= IF(nTipo=1,"I","E")
RETURN .t.



STATIC FUNCTION ArmaPLan(oGet1,oBrw2,oQryCuo)
LOCAL i, nCuotas := oGet1[09]:value, nValor := ROUND(oGet1[06]:value / nCuotas,2),;
      dFecVto := oGet1[10]:value, nAcu := 0, oRow, aLimites := {31,28,31,30,31,30,31,31,30,31,30,31}
oQryCuo:Zap()
FOR i := 1 TO nCuotas
    oRow := oQryCuo:GetBlankRow()
    oRow:cuota := i
    oRow:fecvto := dFecVto
    IF i = nCuotas
       oRow:importe := oGet1[06]:value - nAcu
       ELSE
       oRow:importe := nValor
    ENDIF   
    nAcu := nAcu + nValor
    dFecVto := dFecVto + aLimites[MONTH(dFecVto)]
    oQryCuo:oRow := oRow
    oQryCuo:Save()
    oQryCuo:Refresh()
NEXT i    
oBrw2:Refresh()
oBrw2:MakeTotals()
RETURN nil



*************************************************
** Agregar cheques de Tercero
STATIC FUNCTION AddCheqT(oWnd)
LOCAL oGet2 := ARRAY(12), oBot2 := ARRAY(2) , oDlg3, cNomCue := SPACE(30), cNomPro := SPACE(30),;
      mrta := .f., aCor, oQryChe1, base, oError, oFont,oQryBan
DO WHILE .T.
base := oQryChe:GetBlankRow()
base:tipo  := 1
base:recibo  := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
base:importe := IF(nCtaCte>0,nCtaCte,0)
base:codcli  := ncodcli
base:fecemi  := DATE()
base:fecvto  := DATE()
cNomPro      := oQryCli:nombre
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryBan:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"bancos")

DEFINE DIALOG oDlg3 TITLE "Alta de Cheques de Tercero" FROM 05,15 TO 23,66 OF oWnd FONT oFont
   acor := AcepCanc(oDlg3)
   @ 07, 05 SAY "Banco:"         OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Numero:"        OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Entregado por:" OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "En recibo:"     OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Emision:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 82, 05 SAY "Vencimiento:"   OF oDlg3 PIXEL SIZE 40,12 RIGHT
   @ 97, 05 SAY "Importe:"       OF oDlg3 PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet2[1] VAR base:numban  PICTURE "999" OF oDlg3 PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2]) );
                ACTION (oGet2[1]:cText:= 0, Buscar(oQryBan,oDlg3,oGet2[1],oGet2[2])) BITMAP "BUSC1"         
   @ 05, 80 GET oGet2[2] VAR cNomCue OF oDlg3 PIXEL PICTURE "@!" WHEN(.F.)   
   @ 20, 50 GET oGet2[3] VAR base:numche  PICTURE "9999999999"  OF oDlg3 PIXEL ;
                VALID(base:numche > 0) RIGHT
   @ 35, 50 GET oGet2[4] VAR base:codcli OF oDlg3  PICTURE "999999" PIXEL RIGHT WHEN(.F.)
   @ 35, 80 GET oGet2[5] VAR cNomPro OF oDlg3 SIZE 110,12  PIXEL WHEN(.F.)
   @ 50, 50 GET oGet2[6] VAR base:recibo PICTURE "99999999" PIXEL OF oDlg3 RIGHT WHEN(.F.)
   @ 65, 50 GET oGet2[7] VAR base:fecemi   PICTURE "@D" PIXEL OF oDlg3 CENTER
   @ 80, 50 GET oGet2[8] VAR base:fecvto   PICTURE "@D" PIXEL OF oDlg3 VALID(base:fecvto >= base:fecemi) CENTER
   @ 95, 50 GET oGet2[9] VAR base:importe  PICTURE "999999999.99" PIXEL OF oDlg3 RIGHT VALID(base:importe>0)
   @ acor[1],acor[2] BUTTON oBot2[1] PROMPT "&Grabar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg3:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2[2] PROMPT "&Cancelar" OF oDlg3 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg3:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg3 CENTER ON INIT oGet2[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF
oQryChe1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2Sql(base:numban) +;
                               " AND numche = " + ClipValue2Sql(base:numche) )
IF oQryChe1:nRecCount > 0
   MsgStop("Cheque ya existe", "Error")
   LOOP
ENDIF   
oQryChe:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryChe:Save()
  oQryChe:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*********************************************
*** SI ES UNA TRANSFERENCIA PIDO LOS DATOS DE LA CUENTA 
STATIC FUNCTION PreguntasPresupu(lEnDolares,dFecVen,lGuarda,lImpSinIva,lPreciosFinales)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomCue:=SPACE(50),oQryCue,oDlg1
DEFAULT lImpSinIva := .f.

DEFINE DIALOG oForm TITLE "Emision de presupuesto";
       FROM 05,15 TO 17,70 OF oDlg FONT oApp:oFont
   
   @ 07, 05 SAY "Vencimiento:"       OF oForm PIXEL SIZE 40,12 RIGHT

  
   @ 05, 50 GET oGet[1] VAR dFecVen OF oForm CENTER PICTURE "@D" PIXEL

   @ 20, 50 CHECKBOX oGet[2] VAR lEnDolares OF oForm PIXEL SIZE 200,12 PROMPT "Emitir presupuesto en dolares" 
   @ 35, 50 CHECKBOX oGet[3] VAR lGuarda OF oForm PIXEL SIZE 200,12 PROMPT "Guardar presupuesto para futura facturacion"
   IF oApp:presudiscriva
      @ 50, 50 CHECKBOX oGet[4] VAR lImpSinIva OF oForm PIXEL SIZE 200,12 PROMPT "Imprimir presupuesto sin IVA"
      ELSE 
      @ 50, 50 CHECKBOX oGet[4] VAR lPreciosFinales OF oForm PIXEL SIZE 200,12 PROMPT "Imprimir Precios finales"
   ENDIF      
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN .F.
ENDIF

RETURN .T.


*****************************************************************************
*** Imprimir factura electronica
*******************************************
** Impresion de factura
FUNCTION PrintFactuElec(cTipoDoc,cNumComp)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado Ley Nº 19.640",;
                "IVA Responsable Inscripto Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social",;
                "IVA NO Alcanzado"}, nIndiceDolar, cSigno,;
  i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, oFont5, oQryVen1, oQryDet1, config, lComan,;
  oQryIvaDet, aCor,cCondVen,cFormaPag, nDesFac, oQryP , nRow1, nHoja , oQryPar1, cDomicilioFiscal, nBultos,lImprimio_promo 
  oQryVen1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab  "+;                                 
                                 "WHERE ticomp = " + ClipValue2Sql(cTipoDoc)+;
                                 " AND letra = "+Clipvalue2sql(LEFT(cNumComp,1))+;
                                 " AND numcomp = " + ClipValue2Sql(RIGHT(cNumComp,13)))
  IF oQryVen1:endolares 
     nIndiceDolar := oQryVen1:cotiza
     cSigno := "u$s"
     ELSE 
     nIndiceDolar := 1
     cSigno := "$"
  ENDIF
  oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
  oQryPar1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
  oApp:cDestinoMail := oApp:oServer:Query("SELECT mail FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(oQryVen1:codcli)):mail
   IF oQryVen1:nRecCount = 0
      MsgStop("Factura no existe!!","Error")
      RETURN nil
   ENDIF   
   IF EMPTY(oQryVen1:cae)
      MsgStop("Factura Sin CAE!!","Error")
      RETURN nil
   ENDIF   
   IF oQryP:punto = VAL(SUBSTR(cNumComp,2,4)) .AND. !EMPTY(oQryP:direccionf) 
      cDomicilioFiscal := oQryP:direccionf 
      ELSE 
      cDomicilioFiscal := oApp:dire_emp
   ENDIF   
   IF oQryP:preguntaimpr
      lComan := SiNoCancelar("Atencion","Por donde desea emitir el Comprobante?",{"Comandera","Impresora","No imprimir"})
      IF lComan == nil 
         RETURN nil 
      ENDIF
      oQryP:imprimeTic := lComan
   ENDIF 
   oQryIvaDet:= oApp:oServer:Query("SELECT SUM(v.iva) AS iva,SUM(v.neto) AS neto, v.codiva, i.nombre AS nomiva FROM ge_"+oApp:cId+"ventas_det v "+;
                                   "INNER JOIN ge_"+oApp:cId+"ivas i ON v.codiva = i.codigo "+;
                                   "WHERE v.nrofac = " + ClipValue2Sql(cTipoDoc+cNumComp)+ " GROUP BY v.codiva ")
   oQryDet1 := oApp:oServer:Query("SELECT vd.codart,vd.detart,vd.cantidad,vd.punit,vd.importe,vd.neto,vd.iva,"+;
                                  "vd.codiva,vd.neton,vd.descu,vd.impint,vd.bultos,"+;
       "IF(vd.descup>0,vd.descup,0) AS descupor,"+;
       "IF(SUBSTR(nrofac,3,1) = 'A', neto,importe) AS subtot,"+;
       "IF(codiva = 5,'21%',IF(codiva=3,'0%','10.5%')) AS alicu, (i.tasa / 100) as tasa,"+;
       "importe AS subtotalciva,a.codigopro FROM ge_"+oApp:cId+"ventas_det vd "+;
                                  " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = vd.codart "+;
                                  " LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = vd.codiva "+;
                                  " WHERE nrofac = " + ClipValue2Sql(cTipoDoc+cNumComp))
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   cCondVen := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"cond_venta WHERE codigo = "+ClipValue2Sql(oQryVen1:condven)):nombre
   cFormaPag:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"forpag WHERE codigo = "+ClipValue2Sql(oQryVen1:formapag)):nombre
   GeneraQr(oQryVen1)
   DO CASE
      CASE !oQryP:imprimeTic
           ** FACTURACION CON FORMATO PARA FACTURA ELECTRONICA
           IF config:fon < 14
              config:fon := config:fon * 2.8
           ENDIF
           DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
           DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD
           DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
           DEFINE FONT oFont5  NAME "ARIAL"       SIZE config:fon*.8,config:fon*1.9 BOLD
           AddFontResource( "i2of5txt.ttf" )
           DEFINE FONT oFont4 NAME "Interleaved 2of5 Text"    SIZE config:fon*1.5, config:fon*5 
           PRINT oPrn NAME "Factura "+cTipoDoc+cNumComp PREVIEW MODAL
           oPrn:SetPortrait()
           oPrn:SetPage(9)
           FOR x := 1 TO 2
             nHoja := 1
             nBultos := 0
             lImprimio_promo := .f.
             PAGE                 
             @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL STRETCH GRAY
             *oPrn:SayImage(0,0, "fondofac.jpg",;
             *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
             aCor := oPrn:Cmtr2Pix(25.5,1)
             oPrn:SayImage(aCor[1],aCor[2], "afip.jpg",;
                                oPrn:nHorzRes()*.19, oPrn:nVertRes()*.04 ,   nil, .t. )
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
                @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+cDomicilioFiscal ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
              @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
           ENDIF
           oPrn:CmSay( 1.7  , 11, IF(cTipoDoc="FC" .OR. cTipoDoc='FR',"FACTURA",;
                                  IF(cTipoDoc="NC","NOTA DE CREDITO","NOTA DE DEBITO")), oFont1 )   
           oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
           oPrn:CmSay( 1.5, 9.8, LEFT(cNumComp,1),oFont2)
           oPrn:CmSay( 2.3, 9.5, "Cod:"+oQryVen1:tipfor,oFont)
           oPrn:CmSay( 2.5, 11, "Punto de venta:"+SUBSTR(cNumcomp,2,4) + " Comprobante Nro:"+RIGHT(cNumcomp,8),oFont)
           oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryVen1:fecha),oFont)

             oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
             oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
             oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)                
                  

             
             @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 4.1 PRINT TO oPrn TEXT oQryVen1:cuit ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre) ;
                      SIZE 8,1 CM FONT oFont LASTROW nRow  
             @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva] ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             nRow := IF(nRow<6,6,nRow)
             @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                   ALLTRIM(oQryVen1:localidad) ;
                      SIZE 8,1 CM FONT oFont  
             @ 6.5, 01 PRINT TO oPrn TEXT "Condicion venta:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 6.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(cCondVen) ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 7, 01 PRINT TO oPrn TEXT "Forma de pago:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 7, 4.1 PRINT TO oPrn TEXT ALLTRIM(cFormaPag) ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             

             @ 8.2, 0.7 PRINT TO oPrn TEXT "Codigo" ;
                      SIZE 2.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 3.5 PRINT TO oPrn TEXT "Descripcion del producto" ;
                      SIZE 6.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 10 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             IF oApp:usabultosventa
                @ 8.2, 12.05 PRINT TO oPrn TEXT "Btos" ;
                      SIZE .5,.9 CM FONT oFont5 ALIGN "R"                      
             ENDIF         
             @ 8.2, 12 PRINT TO oPrn TEXT "Pr.Unitario" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             @ 8.2, 14 PRINT TO oPrn TEXT "Desc.%" ;
                      SIZE 1.5,.9 CM FONT oFont5 ALIGN "C"
             @ 8.2, 15.5 PRINT TO oPrn TEXT "Subtotal" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"             
             @ 8.2, 17.5 PRINT TO oPrn TEXT "Alic. IVA" ;
                      SIZE 1,.9 CM FONT oFont5 ALIGN "C"
             @ 8.2, 18.5 PRINT TO oPrn TEXT "Subtotal con IVA Incluí­do" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "C"
             y := 9.2
             oQryDet1:GoTop()
             nDesFac := 0
             FOR i = 1 TO oQryDet1:nRecCount 
                 IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                    @ y+.1, 01 PRINT TO oPrn TEXT "Descuentos Promociones" SIZE 18,1 CM FONT oFont ALIGN "TC" LASTROW y
                    lImprimio_promo := .t.
                    y := y + .1
                 ENDIF          
                 IF oApp:impcodpro
                     @ y-0.07, 01 PRINT TO oPrn TEXT IF(EMPTY(oQryDet1:codigopro),STR(oQryDet1:codart,13),LEFT(oQryDet1:codigopro,13)) ;
                          SIZE 2.5,.5 CM FONT oFont5 ALIGN "TL"
                    ELSE 
                    @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet1:codart,13) ;
                          SIZE 2.5,.5 CM FONT oFont5 ALIGN "TL"
                 ENDIF         
                 @ y-0.07, 03.5 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart) ;
                      SIZE 6.5,2.5 CM FONT oFont5 LASTROW nRow ALIGN "TL"
                 @ y-0.07, 10 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,08,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
                 IF oApp:usabultosventa
                    @ y-0.07, 12.05 PRINT TO oPrn TEXT;
                     IF(INT(oQryDet1:bultos) <> oQryDet1:bultos,STR(oQryDet1:bultos,06,1),STR(oQryDet1:bultos,4)) ;
                          SIZE .5,.5 CM FONT oFont5 ALIGN "TR"  
                    nBultos := nBultos + oQryDet1:bultos                          
                 ENDIF     
                 @ y-0.07, 12 PRINT TO oPrn TEXT STR(IF(!LEFT(cNumComp,1)$"AM",oQryDet1:punit/nIndiceDolar ,oQryDet1:neton/oQryDet1:cantidad/nIndiceDolar),12,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
                 @ y-0.07, 14 PRINT TO oPrn TEXT oQryDet1:descupor ;
                      SIZE 1.5,.5 CM FONT oFont5 ALIGN "TR" 
                 @ y-0.07, 15.5 PRINT TO oPrn TEXT STR(oQryDet1:subtot/nIndiceDolar,12,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
                 @ y-0.07, 17.7 PRINT TO oPrn TEXT oQryDet1:alicu ;
                      SIZE .7,.5 CM FONT oFont5 ALIGN "TC"
                 @ y-0.07, 18.3 PRINT TO oPrn TEXT STR(oQryDet1:subtotalciva/nIndiceDolar,12,2);
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"    
                 nDesFac := nDesFac + oQryDet1:descu   
                 oQryDet1:Skip()
                 y := nRow + .1
                 IF y > 21
                    @ 23, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                       *oPrn:SayImage(0,0, "fondofac.jpg",;
                       *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
                       aCor := oPrn:Cmtr2Pix(25.5,1)
                       oPrn:SayImage(aCor[1],aCor[2], "afip.jpg",;
                                          oPrn:nHorzRes()*.19, oPrn:nVertRes()*.04 ,   nil, .t. )
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                       oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                       oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                       oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
                       oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
                       @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO")+' Hoja:' + STR(nHoja,1) ;
                                SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
                       IF config:x1 = 2 .or. config:x1 = 3
                          @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
                       ENDIF
                       IF config:x1 = 1 .or. config:x1 = 3
                           @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                    SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                           @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+cDomicilioFiscal ;
                                    SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                           @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                                    SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
                       ENDIF
                       oPrn:CmSay( 1.7  , 11, IF(cTipoDoc="FC" .OR. cTipoDoc='FR',"FACTURA",;
                                            IF(cTipoDoc="NC","NOTA DE CREDITO","NOTA DE DEBITO")), oFont1 )   
                       oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
                       oPrn:CmSay( 1.5, 9.8, LEFT(cNumComp,1),oFont2)
                       oPrn:CmSay( 2.3, 9.5, "Cod:"+oQryVen1:tipfor,oFont)
                       oPrn:CmSay( 2.5, 11, "Punto de venta:"+SUBSTR(cNumcomp,2,4) + " Comprobante Nro:"+RIGHT(cNumcomp,8),oFont)
                       oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryVen1:fecha),oFont)

                       oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                       oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                       oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                         
                            

                       
                       @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 5.5, 4.1 PRINT TO oPrn TEXT oQryVen1:cuit ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                       @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre) ;
                                SIZE 8,1 CM FONT oFont LASTROW nRow  
                       @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva] ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       nRow := IF(nRow<6,6,nRow)
                       @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                       @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                             ALLTRIM(oQryVen1:localidad) ;
                                SIZE 8,1 CM FONT oFont  
                       @ 6.5, 01 PRINT TO oPrn TEXT "Condicion venta:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 6.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(cCondVen) ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       @ 7, 01 PRINT TO oPrn TEXT "Forma de pago:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 7, 4.1 PRINT TO oPrn TEXT ALLTRIM(cFormaPag) ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       

                       @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                                SIZE 2.8,.5 CM FONT oFont ALIGN "L"
                       @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                                SIZE 7,.5 CM FONT oFont ALIGN "L"
                       @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                                SIZE 2,.5 CM FONT oFont ALIGN "R"
                       @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unitario" ;
                                SIZE 2,.5 CM FONT oFont ALIGN "R"
                       @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal" ;
                                SIZE 3,.5 CM FONT oFont ALIGN "R"
                       y := 9.2
                 ENDIF
              NEXT       
              y := y + .5
              @ y, 1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:observa) + IF(nDesFac>0," Desc."+cSigno+" "+STR(nDesFac/nIndiceDolar,12,2)+ " (IVA Incl.) "," ") + ;
                      IF(oQryVen1:letra = 'A' .and. oQryVen1:coniva = 6,CHR(10)+"El crédito fiscal discriminado en el presente comprobante, sólo podrá ser computado a efectos del Régimen de Sostenimiento e Inclusión Fiscal para Pequeños Contribuyentes de la Ley Nº 27.618","")  ;
                      SIZE 18,3 CM FONT oFont ALIGN "L" LASTROW y
              IF oApp:usabultosventa
                 @ y  ,1  PRINT TO oPrn TEXT "Total Bultos:" + STR(nBultos,4);
                          SIZE 3,1 CM FONT oFont ALIGN "L"
              ENDIF        
              IF oApp:usareparto
                 @ 27  ,13  PRINT TO oPrn TEXT CodigoBarra(STRTRAN(STR(oQryVen1:codbarra,11)," ","0"));
                          SIZE 6,1 CM FONT oFont4 ALIGN "R" 
              ENDIF        

              @ 22.5,1  PRINT TO oPrn TEXT "Percepcion IIBB "+STR(oQryVen1:percep,6,2)+"% "+cSigno+":" ;
                      SIZE 5,.5 CM FONT oFont3 ALIGN "R"
              @ 22.5,6.1 PRINT TO oPrn TEXT STR(oQryVen1:IIBB/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
              
            IF !LEFT(cNumComp,1)$"AM"    
                 @ 22.5, 12 PRINT TO oPrn TEXT "Subtotal "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
               @ 22.5, 17 PRINT TO oPrn TEXT STR((oQryVen1:importe-oQryVen1:sobretasa)/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
                 @ 23, 12 PRINT TO oPrn TEXT "Otros Tributos "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                 @ 23, 17 PRINT TO oPrn TEXT STR(oQryVen1:sobretasa/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
                 @ 23.5, 12 PRINT TO oPrn TEXT "Total "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                 @ 23.5, 17 PRINT TO oPrn TEXT STR(oQryVen1:importe/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"        
               ELSE 
               @ 22.5, 12 PRINT TO oPrn TEXT "Subtotal "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                 @ 22.5, 17 PRINT TO oPrn TEXT STR(oQryVen1:neto/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
                 @ 23, 12 PRINT TO oPrn TEXT "Otros Tributos "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                 @ 23, 17 PRINT TO oPrn TEXT STR(oQryVen1:sobretasa/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
                 y := 23.5
               oQryIvaDet:GoTop()
               FOR i = 1 TO oQryIvaDet:nRecCount           
                     @ y, 12 PRINT TO oPrn TEXT "I.V.A. "+ALLTRIM(oQryIvaDet:nomiva) + " "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                     @ y, 17 PRINT TO oPrn TEXT STR(oQryIvaDet:iva/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R" 
                      oQryIvaDet:Skip()        
                     y := y + .5
               NEXT
               @ y, 12 PRINT TO oPrn TEXT "Total "+cSigno+":" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
               @ y, 17 PRINT TO oPrn TEXT STR(oQryVen1:importe/nIndiceDolar,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"                  
             ENDIF    
             IF oQryPar1:imprimevendedor
                @ 23.0,1  PRINT TO oPrn TEXT IF(!empty(oQryVen1:vendedor),"Vendedor: "+ALLTRIM(oQryVen1:vendedor),"") ;
                      SIZE 5,.5 CM FONT oFont3
             ENDIF         
             @ 25.5,13  PRINT TO oPrn TEXT "CAE Nro:" ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
             @ 25.5,17 PRINT TO oPrn TEXT oQryVen1:cae ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 26  ,13  PRINT TO oPrn TEXT "Fecha Vto CAE:" ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
             @ 26  ,17 PRINT TO oPrn TEXT DTOC(oQryVen1:fecVto) ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"    
                      
             **oPrn:SayBitmap(aCor[1],aCor[2]*6, "FactQR.bmp",oPrn:nHorzRes()*.15,oPrn:nHorzRes()*.15 ) 
             @ 25.5,6 PRINT TO oPrn IMAGE "FactQR.bmp" SIZE 2.5, 2.5 CM NOTRANSPARENT LASTROW nRow
             IF oQryVen1:endolares
                 @ nRow,1 PRINT TO oPrn TEXT "El total de este comprobante expresado en moneda de curso "+;
                 " legal, PESOS ARGENTINOS, considerando el tipo de cambio consiganado de "+STR(oQryVen1:Cotiza,12,2)+;
                 " asciende a $ "+STR(oQryVen1:importe ,13,2)    ;
                   SIZE 16,1 CM FONT oFont5  ALIGN "L" LASTROW nRow
             ENDIF
             IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                @ nRow,1 PRINT TO oPrn TEXT "(Puntos de esta venta: "+STR(oQryVen1:puntos,8)+;
                 " - Acumulados: "+STR(oQryVen1:puntosacu,8)+;
                 " - Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8)    ;
                   SIZE 16,1 CM FONT oFont5  ALIGN "L" 
             ENDIF           
             //oPrn:CmSay( 26.5,1, CodigoBarra(STRTRAN(oApp:cuit_emp,"-","")+ oQryVen1:tipfor+;
             //                    SUBSTR(oQryVen1:numcomp,1,4)+ALLTRIM(oQryVen1:cae)+DTOS(oQryVen1:fecVto) ),oFont4)
             ENDPAGE
           NEXT x
           ENDPRINT
           oApp:cDestinoMail := " "
       OTHERWISE
           IF !oApp:tick80
               *********** Impresion de Ticket 48 mm 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF   
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 2
                     IF config:x1 = 2 .or. config:x1 = 3
                        @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                     ENDIF
                     IF config:x1 = 1 .or. config:x1 = 3
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                  SIZE 4.8,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                                  
                     @ nRow, .1 PRINT TO oPrn TEXT IF(cTipoDoc="FC" .or. cTipoDoc = "FR","FACTURA",;
                                  IF(cTipoDoc="NC","NOTA CREDITO","NOTA DEBITO")) +" "+ LEFT(cNumComp,1) ;
                                  SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Cod:" + oQryVen1:tipfor+" Nro:"+RIGHT(cNumcomp,13) ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                     IF oQryVen1:coniva = 5 .and. oQryVen1:codcli <= 1 .and. "CONSUMIDOR"$oQryVen1:nombre 
                        @ nRow, .1 PRINT TO oPrn TEXT "A Consumidor Final";
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                        ELSE 
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT IF(oQryVen1:dni = 0,oQryVen1:cuit,STR(oQryVen1:dni));
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva];
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     ENDIF 
                     nRow1 := nRow + .5
                     @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03 PRINT TO oPrn TEXT "Cant";
                                  SIZE .7,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 03.8 PRINT TO oPrn TEXT "Total";
                                  SIZE 1.0,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                                      oQryDet1:GoTop()   
                     nDesFac := 0               
                     lImprimio_promo := .f.
                     FOR i = 1 TO oQryDet1:nRecCount           
                         nRow1 := nRow
                         IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                            @ y+.01, 01 PRINT TO oPrn TEXT "Descuentos Promos" SIZE 5,1 CM FONT oFont ALIGN "TC" LASTROW nRow1
                            lImprimio_promo := .t.
                            nRow1 := nRow1 + .1
                         ENDIF 
                         @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart);
                              SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,06,1);
                              SIZE 0.7,.5 CM FONT oFont  ALIGN "R"
                         /*@ nRow1, 3.8 PRINT TO oPrn TEXT IF(LEFT(cNumComp,1) <> "A",;
                                                     STR(oQryDet1:neton*(1+oQryDet1:tasa)+oQryDet1:impint,12,2),;
                                                     STR(oQryDet1:neto,12,2));
                              SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"*/
                         @ nRow1, 3.8 PRINT TO oPrn TEXT IF(LEFT(cNumComp,1) <> "A",;
                              STR((oQryDet1:punit*oQryDet1:cantidad),12,2),;
                              STR(oQryDet1:punit*oQryDet1:cantidad/(1+oQryDet1:tasa),12,2));
                              SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"     
                         nDesFac := nDesFac + oQryDet1:descu 
                         oQryDet1:Skip()                     
                      NEXT                                           
                      IF nDesFac > 0 
                         
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(STRTRAN(oQryVen1:observa,"PUNTO DE VENTA",""));
                                  SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"  
                         @ nRow, .1 PRINT TO oPrn TEXT "Descuento $ " + STR(nDesFac,12,2);
                                  SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"  
                      ENDIF
                      IF LEFT(cNumComp,1)<>"A"       
                         @ nRow, .1 PRINT TO oPrn TEXT "Total $ " + STR(oQryVen1:importe,12,2);
                                  SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT "Subtotal $ " + STR(oQryVen1:neto,12,2);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                         oQryIvaDet:GoTop()
                         FOR i = 1 TO oQryIvaDet:nRecCount           
                             @ nRow, .1 PRINT TO oPrn TEXT "I.V.A. "+ALLTRIM(oQryIvaDet:nomiva) + " $:" +STR(oQryIvaDet:iva,12,2) ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"  
                             oQryIvaDet:Skip()                       
                         NEXT
                         IF oQryVen1:sobretasa > 0
                            @ nRow, .1 PRINT TO oPrn TEXT "Imp. Internos: $"+STR(oQryVen1:sobretasa,12,2) ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                         ENDIF
                         @ nRow, .1 PRINT TO oPrn TEXT "Total $:"+STR(oQryVen1:importe,12,2) ;
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                     ENDIF 
                     IF oQryPar1:imprimevendedor 
                        @ nRow, .1 PRINT TO oPrn TEXT IF(!empty(oQryVen1:vendedor),"Vendedor: "+ALLTRIM(oQryVen1:vendedor),"") ;
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     ENDIF         
                     IF oQryVen1:letra = 'A' .and. oQryVen1:coniva = 6
                        @ nRow,.1 PRINT TO oPrn TEXT "El crédito fiscal discriminado en el presente comprobante, sólo podrá ser computado a efectos del Régimen de Sostenimiento e Inclusión Fiscal para Pequeños Contribuyentes de la Ley Nº 27.618"  ;
                                  SIZE 4.8,3 CM FONT oFont ALIGN "L" LASTROW nRow 
                     ENDIF             
                     @ nRow, .1 PRINT TO oPrn TEXT "Items:" + STR(oQryDet1:nRecCount,4) ;
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT ".";
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,1.25 PRINT TO oPrn IMAGE "FactQR.bmp" SIZE 2.5,2.5 CM NOTRANSPARENT;
                       LASTROW nRow   
                     @ nRow, .1 PRINT TO oPrn TEXT "CAE Nro:"+oQryVen1:cae ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Vto CAE:"+DTOC(oQryVen1:fecVto);
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"   
                     IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                        @ nRow,0 PRINT TO oPrn TEXT "Puntos: "+STR(oQryVen1:puntos,8) SIZE 4.8,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Acumulados: "+STR(oQryVen1:puntosacu,8) SIZE 4.8,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8) SIZE 4.8,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                     ENDIF            
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"              
                  ENDPAGE
               ENDPRINT
              ELSE
               *********** Impresion de Ticket 80 mm 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF   
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 2
                     IF config:x1 = 2 .or. config:x1 = 3
                        @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                     ENDIF
                     IF config:x1 = 1 .or. config:x1 = 3
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                  SIZE 7.1,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                                  
                     @ nRow, .1 PRINT TO oPrn TEXT IF(cTipoDoc="FC" .or. cTipoDoc = "FR","FACTURA",;
                                  IF(cTipoDoc="NC","NOTA CREDITO","NOTA DEBITO")) +" "+ LEFT(cNumComp,1) ;
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Cod:" + oQryVen1:tipfor+" Nro:"+RIGHT(cNumcomp,13) ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                     IF oQryVen1:coniva = 5 .and. oQryVen1:codcli <= 1 .and. "CONSUMIDOR"$oQryVen1:nombre 
                        @ nRow, .1 PRINT TO oPrn TEXT "A Consumidor Final";
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                        ELSE 
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre);
                                  SIZE 7.1,1 CM FONT oFont LASTROW nRow ALIGN "L"                                  
                        @ nRow, .1 PRINT TO oPrn TEXT IF(oQryVen1:dni = 0,oQryVen1:cuit,STR(oQryVen1:dni));
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva];
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 7.1,1 CM FONT oFont LASTROW nRow ALIGN "L"
                     ENDIF 
                     nRow1 := nRow + .5                     
                     @ nRow1, 00.02 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03.60 PRINT TO oPrn TEXT "Cant";
                                  SIZE .9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 04.62 PRINT TO oPrn TEXT "Unit";
                                  SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 05.66 PRINT TO oPrn TEXT "Total";
                                  SIZE 1.4,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     oQryDet1:GoTop()  
                     oPrn:CmLine( nRow,0, nRow,9 )              
                     nRow := nRow + .2   
                     nDesFac := 0     
                     lImprimio_promo := .f.             
                     FOR i = 1 TO oQryDet1:nRecCount           
                         nRow1 := nRow
                         IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                            @ y+.01, 01 PRINT TO oPrn TEXT "Descuentos Promos" SIZE 7.1,1 CM FONT oFont ALIGN "TC" LASTROW nRow1
                            lImprimio_promo := .t.
                            nRow1 := nRow1 + .1
                         ENDIF 
                         @ nRow1, 00.00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart);
                              SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03.60 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,06,2);
                              SIZE .9,.5 CM FONT oFont  ALIGN "R"
                         @ nRow1, 04.66 PRINT TO oPrn TEXT STR(IF(LEFT(cNumComp,1)<>"A",oQryDet1:punit,oQryDet1:neton/oQryDet1:cantidad),12,2) ;
                              SIZE 1,.5   CM FONT oFont ALIGN "R"
                         /*@ nRow1, 05.66 PRINT TO oPrn TEXT IF(LEFT(cNumComp,1) <> "A",;
                                                     STR(oQryDet1:neton*(1+oQryDet1:tasa)+oQryDet1:impint,12,2),;
                                                     STR(oQryDet1:neto,12,2));
                              SIZE 1.4,.5 CM FONT oFont LASTROW nRow ALIGN "R"  */
                         @ nRow1, 05.66 PRINT TO oPrn TEXT IF(LEFT(cNumComp,1) <> "A",;
                              STR((oQryDet1:punit*oQryDet1:cantidad),12,2),;
                              STR(oQryDet1:punit*oQryDet1:cantidad/(1+oQryDet1:tasa),12,2));
                              SIZE 1.4,.5  CM FONT oFont LASTROW nRow ALIGN "R"     
                         nDesFac := nDesFac + oQryDet1:descu                    
                         oQryDet1:Skip()                     
                      NEXT                                           
                      IF nDesFac > 0 
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(STRTRAN(oQryVen1:observa,"PUNTO DE VENTA",""));
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"  
                         @ nRow, .1 PRINT TO oPrn TEXT "Descuento $ " + STR(nDesFac,12,2);
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                      ENDIF
                      nRow1 := nRow
                      oPrn:CmLine( nRow1,0, nRow1,9 )
                      nRow := nRow + .3
                      IF LEFT(cNumComp,1)<>"A"       
                         @ nRow, .1 PRINT TO oPrn TEXT "Total $ " + STR(oQryVen1:importe,12,2);
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT "Subtotal $ " + STR(oQryVen1:neto,12,2);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                         oQryIvaDet:GoTop()
                         FOR i = 1 TO oQryIvaDet:nRecCount           
                             @ nRow, .1 PRINT TO oPrn TEXT "I.V.A. "+ALLTRIM(oQryIvaDet:nomiva) + " $:" +STR(oQryIvaDet:iva,12,2) ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"  
                             oQryIvaDet:Skip()                       
                         NEXT
                         IF oQryVen1:sobretasa > 0
                            @ nRow, .1 PRINT TO oPrn TEXT "Imp. Internos: $"+STR(oQryVen1:sobretasa,12,2) ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                         ENDIF
                         @ nRow, .1 PRINT TO oPrn TEXT "Total $:"+STR(oQryVen1:importe,12,2) ;
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                     ENDIF 
                     IF oQryPar1:imprimevendedor 
                        @ nRow, .1 PRINT TO oPrn TEXT IF(!empty(oQryVen1:vendedor),"Vendedor: "+ALLTRIM(oQryVen1:vendedor),"") ;
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     ENDIF
                     IF oQryVen1:letra = 'A' .and. oQryVen1:coniva = 6
                        @ nRow,.1 PRINT TO oPrn TEXT "El crédito fiscal discriminado en el presente comprobante, sólo podrá ser computado a efectos del Régimen de Sostenimiento e Inclusión Fiscal para Pequeños Contribuyentes de la Ley Nº 27.618" ;
                                  SIZE 7.1,3 CM FONT oFont ALIGN "L" LASTROW nRow 
                     ENDIF             
                     @ nRow, .1 PRINT TO oPrn TEXT "Items:" + STR(oQryDet1:nRecCount,4) ;
                              SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT ".";
                              SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,2.5 PRINT TO oPrn IMAGE "FactQR.bmp" SIZE 3,3 CM NOTRANSPARENT;
                       LASTROW nRow   
                     @ nRow, .1 PRINT TO oPrn TEXT "CAE Nro:"+oQryVen1:cae ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"                     
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Vto CAE:"+DTOC(oQryVen1:fecVto);
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"  
                     IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                        @ nRow,0 PRINT TO oPrn TEXT "Puntos: "+STR(oQryVen1:puntos,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Acumulados: "+STR(oQryVen1:puntosacu,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                     ENDIF 
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"              
                  ENDPAGE
               ENDPRINT              
              ENDIF 
ENDCASE
RETURN nil

STATIC FUNCTION CodigoBarra( x )
LOCAL i, bar := {}, j := 0, bar1 := {}, cBarr := ""
x := x + DigitoVer(x)
FOR i := 48 TO 97
       AADD(bar ,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
   FOR i := 192 TO 241
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
FOR j := 1 TO LEN(x)-1 STEP 2
    i := ASCAN(bar1,SUBSTR(x,j,2))
    cBarr := cBarr + bar[i]
NEXT j
RETURN cBarr

STATIC FUNCTION DigitoVer(cText)
LOCAL nSuma := 0, i, aSecuencia := {1,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9,3,5,7,9}
FOR i := 1 TO LEN(cText)
    nSuma := nSuma + VAL(SUBSTR(cText,i,1)) * aSecuencia[i]       
NEXT I
nSuma := INT(nSuma / 2)
nSuma := nSuma%10
RETURN STR(nSuma,1)

*******************************************
** Impresion de Presupuesto
FUNCTION PrintPresupu(oQryDet,oGet,oBrw,lDolar,dFecVen,cNumcomp,lImpSinIva,lPreciosFinales)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado Ley Nº 19.640",;
                "IVA Responsable Inscripto  Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA no Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont2, oFont1, oFont3, config, nHoja := 1, cCodigopro, nIva := 0,;
      oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)),;
      lComan :=.f., cDomicilioFiscal, nRow1    
DEFAULT dFecVen:= nil, lImpSinIva := .f., lPreciosFinales := .f.
   oApp:cDestinoMail := oApp:oServer:Query("SELECT mail FROM ge_"+oApp:cId+"clientes WHERE codigo = "+oGet[08]:cText):mail
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   
   cDomicilioFiscal := oApp:dire_emp
    
   IF oQryP:preguntaimpr 
      lComan := SiNoCancelar("Atencion","Por donde desea emitir el Comprobante?",{"Comandera","Impresora","No imprimir"})
      IF lComan == nil 
         RETURN nil 
      ENDIF
      oQryP:imprimeTic := lComan
   ENDIF 
   IF !oQryP:imprimeTic
       ** PRESUPUESTOS
       DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
       DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
       DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
       DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
       PRINT oPrn NAME "Presupuesto "+cNumcomp PREVIEW MODAL
       oPrn:SetPortrait()
       oPrn:SetPage(9)
       FOR x := 1 TO 2
         PAGE
         nHoja := 1
         nIva := 0
         nRow := (oPrn:nHorzRes() / 80) / 47
         IF FILE('fondopre.jpg')
            @ 0,0 PRINT TO oPrn IMAGE "fondopre.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
            ELSE
            @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
         ENDIF
         *oPrn:SayImage(0,0, "fondofac.jpg",;
         *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
         oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
         @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                  SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
         oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
         oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
         oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
         oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
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
         oPrn:CmSay( 1.7  , 11, "PRESUPUESTO", oFont1 )   
         oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
         oPrn:CmSay( 1.5, 9.8, "X",oFont2)
         oPrn:CmSay( 2.0, 16, "N°: "+SUBSTR(cNumcomp,2,16),oFont)         
         oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)
         IF dFecVen <> nil
             oPrn:CmSay( 3.0, 11, "Fecha de vencimiento:"+DTOC(dFecVen),oFont)
         ENDIF

         oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
         oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
         oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

         @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 5.5, 4.1 PRINT TO oPrn TEXT oGet[12]:cText;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
         @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                  SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
         @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oGet[9]:cText) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow 
         @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 6,4.1 PRINT TO oPrn TEXT aIva[oGet[13]:nAt] ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
         nRow := IF(nRow<6,6,nRow)
         @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                  SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
         @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oGet[10]:cText) + " " + ;
                                               ALLTRIM(oGet[11]:cText) ;
                  SIZE 8,1 CM FONT oFont 
         @ 6.5, 01 PRINT TO oPrn TEXT "Forma de Pago:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 6.5, 4.1 PRINT TO oPrn TEXT aFormaNom[nFormaPago] ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"

         @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                  SIZE 2.8,.5 CM FONT oFont ALIGN "L"
         @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                  SIZE 7,.5 CM FONT oFont ALIGN "L"
         @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unit."+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                  SIZE 2.1,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal"+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                  SIZE 3,.5 CM FONT oFont ALIGN "R"
         y := 9.2
         oQryDet:GoTop()
               
         FOR i = 1 TO oQryDet:nRecCount                      
             //@ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
             //     SIZE 2.8,.5 CM FONT oFont ALIGN "R"
             cCodigopro := ""
             IF oQryDet:codart > 0              
                cCodigoPro := oApp:oServer:Query("SELECT codigopro FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryDet:codart)):codigopro
             ENDIF 
             IF oApp:impcodpro
                @ y-0.07, 01 PRINT TO oPrn TEXT IF(EMPTY(cCodigopro),STR(oQryDet:codart,13),ALLTRIM(cCodigopro)) ;
                          SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
                ELSE 
                @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                          SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
             ENDIF             
             @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                  SIZE 7,2.5 CM FONT oFont LASTROW nRow ALIGN "TL"
             @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "TR"
             IF !oApp:presudiscriva     
                 @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:punit/IF(lDolar,oApp:dolar,1),12,2) ;
                      SIZE 2,.5 CM FONT oFont ALIGN "TR"
                 @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                      SIZE 3,.5 CM FONT oFont ALIGN "TR" 
                 ELSE
                 IF !lPreciosFinales 
                     @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:stotal/oQryDet:cantidad/IF(lDolar,oApp:dolar,1),12,2) ;
                          SIZE 2,.5 CM FONT oFont ALIGN "TR"
                     @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryDet:stotal/IF(lDolar,oApp:dolar,1),12,2);
                          SIZE 3,.5 CM FONT oFont ALIGN "TR" 
                     nIva := nIva + oQryDet:ptotal - oQryDet:stotal     
                    ELSE 
                    @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:ptotal/oQryDet:cantidad/IF(lDolar,oApp:dolar,1),12,2) ;
                          SIZE 2,.5 CM FONT oFont ALIGN "TR"
                     @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                          SIZE 3,.5 CM FONT oFont ALIGN "TR" 
                     nIva := nIva + 0
                 ENDIF   
             ENDIF         
             y := nRow + .1
             IF y > 21
                @ 23, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                  SIZE 9,2 CM FONT oFont
                ENDPAGE 
                nHoja ++
                PAGE     
                   @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                   *oPrn:SayImage(0,0, "fondofac.jpg",;
                   *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
                   oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                   @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO")+" (Hoja:"+STR(nHoja,2)+")" ;
                            SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
                   oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                   oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                   oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
                   oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
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
                   oPrn:CmSay( 2  , 11, "PRESUPUESTO", oFont1 )   
                   oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
                   oPrn:CmSay( 1.5, 9.8, "X",oFont2)
                       
                   oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)
                   IF dFecVen <> nil
                       oPrn:CmSay( 3.0, 11, "Fecha de vencimiento:"+DTOC(dFecVen),oFont)
                   ENDIF

                   oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                   oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                   oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

                   @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                   @ 5.5, 4.1 PRINT TO oPrn TEXT oGet[12]:cText;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                   @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                            SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                   @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oGet[9]:cText) ;
                            SIZE 8,1 CM FONT oFont LASTROW nRow 
                   @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                   @ 6,4.1 PRINT TO oPrn TEXT aIva[oGet[13]:nAt] ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"
                   nRow := IF(nRow<6,6,nRow)
                   @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                            SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                   @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oGet[10]:cText) + " " + ;
                                                         ALLTRIM(oGet[11]:cText) ;
                            SIZE 8,1 CM FONT oFont 
                   @ 6.5, 01 PRINT TO oPrn TEXT "Condicion:" ;
                            SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                   @ 6.5, 4.1 PRINT TO oPrn TEXT "Contado" ;
                            SIZE 6,.5 CM FONT oFont ALIGN "L"

                   @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                            SIZE 2.8,.5 CM FONT oFont ALIGN "L"
                   @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                            SIZE 7,.5 CM FONT oFont ALIGN "L"
                   @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                            SIZE 2,.5 CM FONT oFont ALIGN "R"
                   @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unit."+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                            SIZE 2,.5 CM FONT oFont ALIGN "R"
                   @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal"+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                            SIZE 3,.5 CM FONT oFont ALIGN "R"
         
                   y := 9.2
             ENDIF
             oQryDet:Skip()
          NEXT       
          IF lDolar 
              oPrn:CmSay( y ,  1 ,"(Los Precios anteriores estan expresados en dolares americanos)",oFont)
              y := y + .5
          ENDIF 
          IF lImpSinIva 
              oPrn:CmSay( y ,  1 ,"(Los Precios anteriores NO INCLUYEN IVA)",oFont)
              y := y + .5
          ENDIF 
          y := y + .5
          @ y, 1 PRINT TO oPrn TEXT oGet[23]:cText ;
                  SIZE 18,3 CM FONT oFont ALIGN "L"
          IF oBrw:aCols[6]:nTotal > 0        
              @ 23.5,01  PRINT TO oPrn TEXT "Descuento General"+IF(lDolar,"u$s","$")+":"  ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
              @ 23.5,5 PRINT TO oPrn TEXT STR(oBrw:aCols[6]:nTotal/IF(lDolar,oApp:dolar,1),12,2) ;
                  SIZE 4,.5 CM FONT oFont1 ALIGN "L"
          ENDIF    
          IF !oApp:presudiscriva  .OR. !lPreciosFinales      
              @ 23.5,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
              @ 23.5,15 PRINT TO oPrn TEXT STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2) ;
                      SIZE 4,.5 CM FONT oFont1 ALIGN "L"
              ELSE 
              IF !lImpSinIva 
                  @ 23.5,11  PRINT TO oPrn TEXT "Tasa gral (IVA) "+IF(lDolar,"u$s","$")+":"  ;
                          SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
                  @ 23.5,15 PRINT TO oPrn TEXT STR(nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                          SIZE 4,.5 CM FONT oFont1 ALIGN "L"
                  @ 24.0,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                          SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
                  @ 24.0,15 PRINT TO oPrn TEXT STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2) ;
                          SIZE 4,.5 CM FONT oFont1 ALIGN "L"
                 ELSE             
                  @ 24.0,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                          SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
                  @ 24.0,15 PRINT TO oPrn TEXT STR(oGet[21]:value/IF(lDolar,oApp:dolar,1)-nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                          SIZE 4,.5 CM FONT oFont1 ALIGN "L"
              ENDIF            
          ENDIF 
          @ 24.0,1  PRINT TO oPrn TEXT "Vendedor: "+ALLTRIM(oGet[36]:aItems[oGet[36]:nAt]) ;
                          SIZE 5,.5 CM FONT oFont3                             
         ENDPAGE
       NEXT x
       ENDPRINT
       oApp:cDestinoMail := " "

       ELSE 
       ** PRESUPUESTO POR COMANDERA 
       IF !oApp:tick80
           *********** Impresion de Ticket 48 mm 
           IF config:fon > 25
              config:fon := config:fon /3
           ENDIF   
           DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
              oPrn:oFont := oFont
              PAGE                                  
                 nRow := 2
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 4.8,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                              
                 @ nRow, .1 PRINT TO oPrn TEXT "PRESUPUESTO" ;
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                 @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(DATE());
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oGet[9]:cText);
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT oGet[12]:cText;
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT aIva[oGet[13]:nAt];
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oGet[10]:cText) + " " + ;
                                                     ALLTRIM(oGet[11]:cText);
                              SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 
                 nRow1 := nRow + .5
                 @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                              SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow1, 03 PRINT TO oPrn TEXT "Cant";
                              SIZE .7,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                 @ nRow1, 03.8 PRINT TO oPrn TEXT "Total";
                              SIZE 1.0,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                 oQryDet:GoTop()   
                        
                 FOR i = 1 TO oQryDet:nRecCount           
                     nRow1 := nRow
                     @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                          SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,1);
                          SIZE 0.7,.5 CM FONT oFont  ALIGN "R"
                     IF !oApp:presudiscriva                                 
                         @ nRow1, 3.8 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 1,.5 CM FONT oFont ALIGN "R" 
                         ELSE                              
                         IF !lPreciosFinales
                            @ nRow1, 3.8 PRINT TO oPrn TEXT STR(oQryDet:stotal/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 1,.5 CM FONT oFont ALIGN "TR" 
                            nIva := nIva + oQryDet:ptotal - oQryDet:stotal     
                            ELSE 
                            @ nRow1, 3.8 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 1,.5 CM FONT oFont ALIGN "TR" 
                            nIva := nIva + 0
                         ENDIF   
                     ENDIF                         
                     oQryDet:Skip()                     
                 NEXT 
                  IF lDolar 
                      @ nRow1, 0 PRINT TO oPrn TEXT "(Los Precios anteriores estan expresados en dolares americanos)" SIZE 4.8,1 CM FONT oFont LASTROW nRow1
                  ENDIF 
                  IF lImpSinIva 
                     @ nRow1, 0 PRINT TO oPrn TEXT "(Los Precios anteriores NO INCLUYEN IVA)" SIZE 4.8,1 CM FONT oFont LASTROW nRow1
                  ENDIF 
                  @ nRow1, 0 PRINT TO oPrn TEXT oGet[23]:cText ;
                          SIZE 4.8,1 CM FONT oFont ALIGN "L" LASTROW nRow1
                  IF oBrw:aCols[6]:nTotal > 0        
                      @ nRow1,00  PRINT TO oPrn TEXT "Desc. "+IF(lDolar,"u$s","$")+":" +STR(oBrw:aCols[6]:nTotal/IF(lDolar,oApp:dolar,1),12,2) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                          
                  ENDIF    
                  IF !oApp:presudiscriva .OR. lPreciosFinales        
                      @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                                                    
                      ELSE 
                      IF !lImpSinIva 
                         @ nRow1,00  PRINT TO oPrn TEXT "(IVA) "+IF(lDolar,"u$s","$")+":" +STR(nIva/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1
                         @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                                                                                                                
                         ELSE             
                         @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1)-nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                               
                      ENDIF            
                  ENDIF 
                  @ nRow1,00  PRINT TO oPrn TEXT "Vendedor: "+ALLTRIM(oGet[36]:aItems[oGet[36]:nAt]) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1 
              ENDPAGE
           ENDPRINT                            
           ELSE 
           ** IMPRESORA DE 80 MM 
           IF config:fon > 25
              config:fon := config:fon /3
           ENDIF   
           DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
              oPrn:oFont := oFont
              PAGE                                  
                 nRow := 2
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 7.1,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                              
                 @ nRow, .1 PRINT TO oPrn TEXT "PRESUPUESTO" ;
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                 @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(DATE());
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oGet[9]:cText);
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT oGet[12]:cText;
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT aIva[oGet[13]:nAt];
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oGet[10]:cText) + " " + ;
                                                     ALLTRIM(oGet[11]:cText);
                              SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 
                 nRow1 := nRow + .5
                 @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                              SIZE 3.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                 @ nRow1, 04.3 PRINT TO oPrn TEXT "Cant";
                              SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                 @ nRow1, 05.4 PRINT TO oPrn TEXT "Total";
                              SIZE 1.7,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                 oQryDet:GoTop()   
                 nRow1 := nRow       
                 FOR i = 1 TO oQryDet:nRecCount                                
                     @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                          SIZE 3.9,.5 CM FONT oFont ALIGN "L"
                     @ nRow1, 04.3 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,1);
                          SIZE 1,.5 CM FONT oFont  ALIGN "R"
                     IF !oApp:presudiscriva                         
                         @ nRow1, 5.3 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 1.7,.5 CM FONT oFont ALIGN "R" LASTROW nRow1
                         ELSE
                         IF !lPreciosFinales                                                       
                             @ nRow1, 5.3 PRINT TO oPrn TEXT STR(oQryDet:stotal/IF(lDolar,oApp:dolar,1),12,2);
                                  SIZE 1.7,.5 CM FONT oFont ALIGN "R" LASTROW nRow1
                             nIva := nIva + oQryDet:ptotal - oQryDet:stotal     
                            ELSE 
                            @ nRow1, 5.3 PRINT TO oPrn TEXT STR(oQryDet:ptotal/IF(lDolar,oApp:dolar,1),12,2);
                                  SIZE 1.7,.5 CM FONT oFont ALIGN "R" LASTROW nRow1
                             nIva := nIva + 0
                         ENDIF
                     ENDIF                         
                     oQryDet:Skip()                     
                 NEXT 
                 IF lDolar 
                      @ nRow1, 0 PRINT TO oPrn TEXT "(Los Precios anteriores estan expresados en dolares americanos)" SIZE 4.8,1 CM FONT oFont LASTROW nRow1
                 ENDIF 
                 IF lImpSinIva 
                     @ nRow1, 0 PRINT TO oPrn TEXT "(Los Precios anteriores NO INCLUYEN IVA)" SIZE 4.8,1 CM FONT oFont LASTROW nRow1
                 ENDIF 
                 @ nRow1, 0 PRINT TO oPrn TEXT oGet[23]:cText ;
                          SIZE 4.8,1 CM FONT oFont ALIGN "L" LASTROW nRow1
                 IF oBrw:aCols[6]:nTotal > 0        
                      @ nRow1,00  PRINT TO oPrn TEXT "Desc. "+IF(lDolar,"u$s","$")+":" +STR(oBrw:aCols[6]:nTotal/IF(lDolar,oApp:dolar,1),12,2) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                          
                 ENDIF    
                 IF !oApp:presudiscriva .OR. lPreciosFinales
                      @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                                                    
                      ELSE 
                      IF !lImpSinIva 
                         @ nRow1,00  PRINT TO oPrn TEXT "(IVA) "+IF(lDolar,"u$s","$")+":" +STR(nIva/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1
                         @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1),12,2);
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                                                                                                                
                         ELSE             
                         @ nRow1,00  PRINT TO oPrn TEXT "TOTAL "+IF(lDolar,"u$s","$")+":" +STR(oGet[21]:value/IF(lDolar,oApp:dolar,1)-nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1                               
                      ENDIF            
                 ENDIF 
                 @ nRow1,00  PRINT TO oPrn TEXT "Vendedor: "+ALLTRIM(oGet[36]:aItems[oGet[36]:nAt]) ;
                              SIZE 3.9,.5 CM FONT oFont3 LASTROW nRow1 
              ENDPAGE
           ENDPRINT                            
        ENDIF
    ENDIF    
RETURN nil


*******************************************
** Impresion de Remito
FUNCTION PrintRemito(oQryDet,oGet,oBrw, cNumComp, nCodCli)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado Ley Nº 19.640",;
                "IVA Responsable Inscripto Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA no Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, config, oQryCli, lRta, cCodigopro , nBultos,;
      oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)),;
      lComan :=.f., cDomicilioFiscal, nRow1

    IF nCodcli = nil
       nCodcli := oGet[08]:value       
    ENDIF
    IF oQryP:punto = VAL(LEFT(cNumComp,4)) .AND. !EMPTY(oQryP:direccionf) 
       cDomicilioFiscal := oQryP:direccionf 
       ELSE 
       cDomicilioFiscal := oApp:dire_emp
    ENDIF 
    IF oQryP:preguntaimpr 
      lComan := SiNoCancelar("Atencion","Por donde desea emitir el Comprobante?",{"Comandera","Impresora","No imprimir"})
      IF lComan == nil 
         RETURN nil 
      ENDIF
      oQryP:imprimeTic := lComan
    ENDIF 
    oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+Clipvalue2sql(nCodcli))
    config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
    IF !oQryP:imprimeTic
         lRta := MsgNoYes("Imprime los encabezados?","Atencion")
         
         oApp:cDestinoMail := oQryCli:mail
         ** REMITO A4
         IF config:fon < 14
            config:fon := config:fon * 2.8
         ENDIF
         DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
         DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
         DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
         DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
         PRINT oPrn NAME "Remito "+cNumcomp  PREVIEW MODAL
         oPrn:SetPortrait()
         oPrn:SetPage(9)
         FOR x := 1 TO 2
           PAGE
           nRow := (oPrn:nHorzRes() / 80) / 47
           nBultos := 0 
           IF lRta
               IF FILE('fondorem.jpg')
                  @ 0,0 PRINT TO oPrn IMAGE "fondorem.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                  ELSE
                  @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
               ENDIF   
               *oPrn:SayImage(0,0, "fondofac.jpg",;
               *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
               oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
               @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                        SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
               oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
               oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
               oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
               
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

               oPrn:CmSay( 1.7  , 11, "REMITO", oFont1 )   
               oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
               oPrn:CmSay( 1.5, 9.8, "R",oFont2)
               oPrn:CmSay( 2.5, 11, "Punto de venta:"+LEFT(cNumcomp,4) + " Remito Nro:"+RIGHT(cNumcomp,8),oFont)     
               oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(DATE()),oFont)

               oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
               oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
               oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)
               ELSE 
               @ 3, 9.5 PRINT TO oPrn TEXT "Fecha de emision:" SIZE 2.5,.5 CM FONT oFont3 ALIGN "TR"
               @ 3,12.5 PRINT TO oPrn TEXT DTOC(DATE())        SIZE 8,1 CM FONT oFont ALIGN 'TL'
           ENDIF
           @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                    SIZE 3,.5 CM FONT oFont3 ALIGN "R"
           @ 5.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:cuit);
                    SIZE 6,.5 CM FONT oFont ALIGN "L"
           @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                    SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
           @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre) ;
                    SIZE 8,1 CM FONT oFont LASTROW nRow 
           @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                    SIZE 3,.5 CM FONT oFont3 ALIGN "R"
           @ 6,4.1 PRINT TO oPrn TEXT aIva[IF(oQryCli:coniva<>0,oQryCli:coniva,5)] ;
                    SIZE 6,.5 CM FONT oFont ALIGN "L"
           nRow := IF(nRow<6,6,nRow)
           @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                    SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
           @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                                 ALLTRIM(oQryCli:localidad) ;
                    SIZE 8,1 CM FONT oFont 
           
           @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                    SIZE 2.8,.5 CM FONT oFont ALIGN "L"
           @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                    SIZE 7,.5 CM FONT oFont ALIGN "L"
           @ 8.2, 15 PRINT TO oPrn TEXT "Cantidad" ;
                    SIZE 2,.5 CM FONT oFont ALIGN "R"
           IF oApp:usabultosventa
              @ 8.2, 18 PRINT TO oPrn TEXT "Btos" ;
                    SIZE 1,.5 CM FONT oFont ALIGN "R" 
           ENDIF
           y := 9.2
           oQryDet:GoTop()
           FOR i = 1 TO oQryDet:nRecCount          
                 //@ y, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                 //   SIZE 2.8,.5 CM FONT oFont  ALIGN "R"
                 cCodigopro := ""
                 IF oQryDet:codart > 0              
                    cCodigoPro := oApp:oServer:Query("SELECT codigopro FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryDet:codart)):codigopro
                 ENDIF  
                 IF oApp:impcodpro 
                    @ y-0.07, 01 PRINT TO oPrn TEXT IF(EMPTY(cCodigopro),STR(oQryDet:codart,13),ALLTRIM(cCodigopro)) ;
                            SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
                    ELSE 
                    @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                            SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
                 ENDIF           
                 @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                    SIZE 7,2.5 CM FONT oFont LASTROW nRow ALIGN "TL"
                 @ y-0.07, 15 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                    SIZE 2,.5 CM FONT oFont ALIGN "TR"        
                 IF oApp:usabultosventa
                    @ y-0.07, 18 PRINT TO oPrn TEXT;
                     IF(INT(oQryDet:bultos) <> oQryDet:bultos,STR(oQryDet:bultos,06,1),STR(oQryDet:bultos,4)) ;
                          SIZE 1,.5 CM FONT oFont ALIGN "TR"  
                    nBultos := nBultos + oQryDet:bultos                          
                 ENDIF   
                 y := nRow + .1
                 oQryDet:Skip()
           NEXT       
           IF oGet <> nil
              @ y, 1 PRINT TO oPrn TEXT oGet[23]:cText ;
                    SIZE 18,3 CM FONT oFont ALIGN "L" LASTROW y
           ENDIF
           IF oApp:usabultosventa
              @ y, 1 PRINT TO oPrn TEXT "Total Bultos:"+STR(nBultos,4) ;
                    SIZE 3,1 CM FONT oFont ALIGN "L"
           ENDIF
           ENDPAGE
         NEXT x
         ENDPRINT
         oApp:cDestinoMail := " "
         ELSE
         ** Impresion de remitos por comandera
         IF !oApp:tick80
               *********** Impresion de Ticket 48 mm 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF   
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 2
                     IF config:x1 = 2 .or. config:x1 = 3
                        @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                     ENDIF
                     IF config:x1 = 1 .or. config:x1 = 3
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                  SIZE 4.8,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                                  
                     @ nRow, .1 PRINT TO oPrn TEXT "REMITO" ;
                                  SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(DATE());
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT IF(oQryCli:dni = 0,oQryCli:cuit,STR(oQryCli:dni));
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryCli:coniva];
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                                           ALLTRIM(oQryCli:localidad);
                                  SIZE 4.8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     
                     nRow1 := nRow + .5
                     @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03 PRINT TO oPrn TEXT "Cant";
                                  SIZE .7,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     oQryDet:GoTop()                        
                     FOR i = 1 TO oQryDet:nRecCount           
                         nRow1 := nRow
                         @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                              SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,1);
                              SIZE 0.7,.5 CM FONT oFont  ALIGN "R"                         
                         oQryDet:Skip()                     
                      NEXT                                                                 
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 4.8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"              
                  ENDPAGE
               ENDPRINT
              ELSE
               *********** Impresion de Ticket 80 mm 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF   
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 2
                     IF config:x1 = 2 .or. config:x1 = 3
                        @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                     ENDIF
                     IF config:x1 = 1 .or. config:x1 = 3
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                  SIZE 7.1,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(cDomicilioFiscal) ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     @ nRow, .1 PRINT TO oPrn TEXT "REMITO" ;
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                     @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                     @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(DATE());
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                                  
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT IF(oQryCli:dni = 0,oQryCli:cuit,STR(oQryCli:dni));
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryCli:coniva];
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                                           ALLTRIM(oQryCli:localidad);
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     
                     nRow1 := nRow + .5
                     @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 4,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 05 PRINT TO oPrn TEXT "Cant";
                                  SIZE 2,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     oQryDet:GoTop()  
                     nRow := nRow + .2                  
                     FOR i = 1 TO oQryDet:nRecCount           
                         nRow1 := nRow
                         @ nRow1, 00.00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                              SIZE 4,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 5 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,2);
                              SIZE 2,.5 CM FONT oFont  ALIGN "R"                         
                         oQryDet:Skip()                     
                      NEXT                                                                 
                      nRow1 := nRow
                      oPrn:CmLine( nRow1,0, nRow1,9 )
                      nRow := nRow + .3                      
                     @ nRow, .1 PRINT TO oPrn TEXT "Items:" + STR(oQryDet:nRecCount,4) ;
                              SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
                     @ nRow,.1 PRINT TO oPrn TEXT "...";
                              SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"              
                  ENDPAGE
               ENDPRINT              
          ENDIF 
    ENDIF       
RETURN nil


FUNCTION FacturaNoFiscal(cTipoDoc,cNumComp)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado  Ley Nº 19.640",;
                "IVA Responsable Inscripto Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA no Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, oFont5, oQryVen1, oQryDet1, config,;
      oQryIvaDet, aCor,cCondVen,cFormaPag, oQryP, nRow1, nHoja, nDesFac, nBultos, lComan, lImprimio_promo := .f.
   oQryVen1 := oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"ventas_encab "+;
                                 " WHERE ticomp = " + ClipValue2Sql(cTipoDoc)+;
                                 " AND letra = "+Clipvalue2sql(LEFT(cNumComp,1))+;
                                 " AND numcomp = " + ClipValue2Sql(RIGHT(cNumComp,13)))
   oQryPar := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
   oApp:cDestinoMail := oApp:oServer:Query("SELECT mail FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(oQryVen1:codcli)):mail
   IF oQryVen1:nRecCount = 0
      MsgStop("Factura no existe!!","Error")
      RETURN nil
   ENDIF       
   oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
   IF oQryP:preguntaimpr
      lComan := SiNoCancelar("Atencion","Por donde desea emitir el Comprobante?",{"Comandera","Impresora","No imprimir"})
      IF lComan == nil 
         RETURN nil 
      ENDIF
      oQryP:imprimeTic := lComan
   ENDIF 
   oQryIvaDet:= oApp:oServer:Query("SELECT SUM(v.iva) AS iva,SUM(v.neto) AS neto, v.codiva, i.nombre AS nomiva FROM ge_"+oApp:cId+"ventas_det v "+;
                                   "INNER JOIN ge_"+oApp:cId+"ivas i ON v.codiva = i.codigo "+;
                                   "WHERE v.nrofac = " + ClipValue2Sql(cTipoDoc+cNumComp)+ " GROUP BY v.codiva ")
   oQryDet1 := oApp:oServer:Query("SELECT vd.codart,vd.detart,vd.cantidad,vd.punit,vd.importe,vd.neto,vd.iva,"+;
                                  "vd.codiva,vd.neton,vd.descu,vd.impint,vd.bultos,"+;
       "IF(vd.descup>0,vd.descup,0) AS descupor,"+;
       "IF(SUBSTR(nrofac,3,1) = 'A', neto,importe) AS subtot,"+;
       "IF(codiva = 5,'21%',IF(codiva=3,'0%','10.5%')) AS alicu, (i.tasa / 100) as tasa,"+;
       "importe AS subtotalciva,a.codigopro FROM ge_"+oApp:cId+"ventas_det vd "+;
                                  " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = vd.codart "+;
                                  " LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = vd.codiva "+;
                                  " WHERE nrofac = " + ClipValue2Sql(cTipoDoc+cNumComp))
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   cCondVen := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"cond_venta WHERE codigo = "+ClipValue2Sql(oQryVen1:condven)):nombre
   cFormaPag:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"forpag WHERE codigo = "+ClipValue2Sql(oQryVen1:formapag)):nombre
   DO CASE
      CASE !oQryP:imprimeTic   
           ** FACTURACION CON FORMATO PARA FACTURA ELECTRONICA
           DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
           DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD
           DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD  
           DEFINE FONT oFont5  NAME "ARIAL"       SIZE config:fon*.8,config:fon*1.9 BOLD 
           AddFontResource( "i2of5txt.ttf" )
           DEFINE FONT oFont4 NAME "Interleaved 2of5 Text"    SIZE config:fon*1.5, config:fon*5 
           PRINT oPrn NAME "Presupuesto "+cNumcomp PREVIEW MODAL
           oPrn:SetPortrait()
           oPrn:SetPage(9)
           FOR x := 1 TO 2
             PAGE 
             nHoja := 1   
             nBultos := 0
             lImprimio_promo := .f.
             IF oQryP:imprimeDat
                @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                ELSE 
                @ 0,0 PRINT TO oPrn IMAGE "fondonof.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
             ENDIF   
             *oPrn:SayImage(0,0, "fondofac.jpg",;
             *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )     
             oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
             @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C" 
             IF oQryP:imprimeDat            
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
             ENDIF
             //oPrn:CmSay( 1.7  , 11, "PRESUPUESTO"+IF(cTipoDoc="NC"," NC",""), oFont1 )   
             oPrn:CmSay( 1.7  , 11, ALLTRIM(oQryPar:textonofiscal)+IF(cTipoDoc="NC"," NC",""), oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             //oPrn:CmSay( 1.5, 9.8, LEFT(cNumComp,1),oFont2)
             oPrn:CmSay( 1.5, 9.8, oQryPar:letranofiscal,oFont2)
             
             oPrn:CmSay( 2.5, 11, "Punto de venta:"+SUBSTR(cNumcomp,2,4) + " Comprobante Nro:"+RIGHT(cNumcomp,8),oFont)
             oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryVen1:fecha),oFont)
             IF oQryP:imprimeDat
                 oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                 oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                 oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
             ENDIF                    
             
             @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 4.1 PRINT TO oPrn TEXT oQryVen1:cuit ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre) ;
                      SIZE 8,1 CM FONT oFont LASTROW nRow 
             @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva] ;
                      SIZE 6,.5 CM FONT oFont 
             nRow := IF(nRow<6,6,nRow)
             @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                   ALLTRIM(oQryVen1:localidad) ;
                      SIZE 8,1 CM FONT oFont 
             @ 6.5, 01 PRINT TO oPrn TEXT "Condicion venta:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 6.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(cCondVen) ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 7, 01 PRINT TO oPrn TEXT "Forma de pago:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 7, 4.1 PRINT TO oPrn TEXT ALLTRIM(cFormaPag) ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             

             @ 8.2, 0.7 PRINT TO oPrn TEXT "Codigo" ;
                      SIZE 2.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 3.5 PRINT TO oPrn TEXT "Descripcion del producto" ;
                      SIZE 6.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 10 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             IF oApp:usabultosventa
                @ 8.2, 12.05 PRINT TO oPrn TEXT "Btos" ;
                      SIZE .5,.9 CM FONT oFont5 ALIGN "R"                      
             ENDIF
             @ 8.2, 12 PRINT TO oPrn TEXT "Pr.Unitario" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             @ 8.2, 14 PRINT TO oPrn TEXT "Desc.%" ;
                      SIZE 1.5,.9 CM FONT oFont5 ALIGN "C"
             @ 8.2, 15.5 PRINT TO oPrn TEXT "Subtotal" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"             

             y := 9.2
             oQryDet1:GoTop()
             nDesFac := 0
             FOR i = 1 TO oQryDet1:nRecCount   
                 IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                    @ y+.01, 01 PRINT TO oPrn TEXT "Descuentos Promociones" SIZE 18,1 CM FONT oFont ALIGN "TC" LASTROW y
                    lImprimio_promo := .t.
                    y := y + .1
                 ENDIF        
                 IF oApp:impcodpro
                    @ y-0.07, 01 PRINT TO oPrn TEXT IF(EMPTY(oQryDet1:codigopro),STR(oQryDet1:codart,13),LEFT(oQryDet1:codigopro,13)) ;
                      SIZE 2.5,.5 CM FONT oFont5 ALIGN "TL"
                    ELSE 
                    @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet1:codart,13) ;
                      SIZE 2.5,.5 CM FONT oFont5 ALIGN "TL"
                 ENDIF     
                 @ y-.07, 03.5 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart) ;
                      SIZE 6.5,2.5 CM FONT oFont5 LASTROW nRow ALIGN "TL"
                 @ y-0.07, 10 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,08,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
                 IF oApp:usabultosventa
                    @ y-0.07, 12.05 PRINT TO oPrn TEXT;
                     IF(INT(oQryDet1:bultos) <> oQryDet1:bultos,STR(oQryDet1:bultos,06,1),STR(oQryDet1:bultos,4)) ;
                          SIZE .5,.5 CM FONT oFont5 ALIGN "TR"  
                    nBultos := nBultos + oQryDet1:bultos                          
                 ENDIF  
                 @ y-0.07, 12 PRINT TO oPrn TEXT STR(IF(LEFT(cNumComp,1)<>"A",oQryDet1:punit,oQryDet1:neton/oQryDet1:cantidad),12,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
                 @ y-0.07, 14 PRINT TO oPrn TEXT oQryDet1:descupor ;
                      SIZE 1.5,.5 CM FONT oFont5 ALIGN "TR" 
                 @ y-0.07, 15.5 PRINT TO oPrn TEXT STR(oQryDet1:subtot,12,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "TR"
  
                 y := nRow + .1
                 IF y > 21
                    @ 23, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       IF oQryP:imprimeDat
                          @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                          ELSE 
                          @ 0,0 PRINT TO oPrn IMAGE "fondonof.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                       ENDIF   
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                       oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                       oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                       oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
                       oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
                       @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                                SIZE 18,.9 CM FONT oFont1 ALIGN "C"  
                       IF oQryP:imprimeDat  
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
                       ENDIF
                       //oPrn:CmSay( 1.7  , 11, "PRESUPUESTO"+IF(cTipoDoc="NC"," NC",""), oFont1 )   
                       oPrn:CmSay( 1.7  , 11, ALLTRIM(oQryPar:textonofiscal)+IF(cTipoDoc="NC"," NC",""), oFont1 )   
                       oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
                       //oPrn:CmSay( 1.5, 9.8, LEFT(cNumComp,1),oFont2)
                       oPrn:CmSay( 1.5, 9.8, oQryPar:letranofiscal,oFont2)
                       
                       oPrn:CmSay( 2.5, 11, "Punto de venta:"+SUBSTR(cNumcomp,2,4) + " Comprobante Nro:"+RIGHT(cNumcomp,8),oFont)
                       oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQryVen1:fecha),oFont)
                       IF oQryP:imprimeDat
                           oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                           oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                           oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
                       ENDIF 
                            
                       @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 5.5, 4.1 PRINT TO oPrn TEXT oQryVen1:cuit ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                       @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre) ;
                                SIZE 8,1 CM FONT oFont LASTROW nRow 
                       @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva] ;
                                SIZE 6,.5 CM FONT oFont 
                       nRow := IF(nRow<6,6,nRow)
                       @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                       @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                             ALLTRIM(oQryVen1:localidad) ;
                                SIZE 8,1 CM FONT oFont 
                       @ 6.5, 01 PRINT TO oPrn TEXT "Condicion venta:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 6.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(cCondVen) ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       @ 7, 01 PRINT TO oPrn TEXT "Forma de pago:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 7, 4.1 PRINT TO oPrn TEXT ALLTRIM(cFormaPag) ;
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       

                       @ 8.2, 0.7 PRINT TO oPrn TEXT "Codigo" ;
                                SIZE 2.5,.9 CM FONT oFont5 ALIGN "L"
                       @ 8.2, 3.5 PRINT TO oPrn TEXT "Descripcion del producto" ;
                                SIZE 6.5,.9 CM FONT oFont5 ALIGN "L"
                       @ 8.2, 10 PRINT TO oPrn TEXT "Cantidad" ;
                                SIZE 2,.9 CM FONT oFont5 ALIGN "R"
                       @ 8.2, 12 PRINT TO oPrn TEXT "Pr.Unitario" ;
                                SIZE 2,.9 CM FONT oFont5 ALIGN "R"
                       @ 8.2, 14 PRINT TO oPrn TEXT "Desc.%" ;
                                SIZE 1.5,.9 CM FONT oFont5 ALIGN "C"
                       @ 8.2, 15.5 PRINT TO oPrn TEXT "Subtotal" ;
                                SIZE 2,.9 CM FONT oFont5 ALIGN "R"             
                       @ 8.2, 17.5 PRINT TO oPrn TEXT "Alic. IVA" ;
                                SIZE 1,.9 CM FONT oFont5 ALIGN "C"
                       @ 8.2, 18.5 PRINT TO oPrn TEXT "Subtotal con IVA Incluí­do" ;
                                SIZE 2,.9 CM FONT oFont5 ALIGN "C"
             
                       y := 9.2
                 ENDIF     
                 nDesFac := nDesFac + oQryDet1:descu
                 oQryDet1:Skip()                 
              NEXT       
              y := y + .5
              @ y, 1 PRINT TO oPrn TEXT oQryVen1:observa ;
                      SIZE 18,3 CM FONT oFont ALIGN "L" LASTROW y 
              IF oApp:usabultosventa
                 @ y  ,1  PRINT TO oPrn TEXT "Total Bultos:" + STR(nBultos,4);
                          SIZE 3,1 CM FONT oFont ALIGN "L"
              ENDIF 
              IF oApp:usareparto 
                 @ 27  ,13  PRINT TO oPrn TEXT CodigoBarra(STRTRAN(STR(oQryVen1:codbarra,11)," ","0"));
                          SIZE 6,1 CM FONT oFont4 ALIGN "R"
              ENDIF                    
              IF nDesFac > 0
                 y := y + .5
                 @ y, 1 PRINT TO oPrn TEXT ALLTRIM(STRTRAN(oQryVen1:observa,"PUNTO DE VENTA",""));
                                  SIZE 18,3 CM FONT oFont LASTROW nRow ALIGN "L" 
                 @ nRow, 1 PRINT TO oPrn TEXT "Descuento Gral:"+STR(nDesFac,12,2) ;
                      SIZE 18,3 CM FONT oFont ALIGN "L"
              ENDIF        
              @ 23.0,1  PRINT TO oPrn TEXT IF(!empty(oQryVen1:vendedor),"Vendedor: "+ALLTRIM(oQryVen1:vendedor),"") ;
                      SIZE 5,.5 CM FONT oFont3
                       
              @ 23.5, 12 PRINT TO oPrn TEXT "Total $:" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
              @ 23.5, 17 PRINT TO oPrn TEXT STR(oQryVen1:importe,12,2) ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R" LASTROW nRow
              IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                 @ nRow,1 PRINT TO oPrn TEXT "(Puntos de esta venta: "+STR(oQryVen1:puntos,8)+;
                   " - Acumulados: "+STR(oQryVen1:puntosacu,8)+;
                   " - Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8)    ;
                   SIZE 16,1 CM FONT oFont5  ALIGN "L" 
              ENDIF
              
             ENDPAGE
           NEXT x
           ENDPRINT
          OTHERWISE
           IF !oApp:tick80
               *** Impresion 48 mm
               *********** Impresion de Ticket NO FISCAL 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD
               DEFINE FONT oFont2  NAME "CALIBRI"           SIZE config:fon*1.1,config:fon*3 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 1
                     IF oQryP:imprimeDat
                         IF config:x1 = 2 .or. config:x1 = 3
                            @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                         ENDIF
                         IF config:x1 = 1 .or. config:x1 = 3
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                      SIZE 5,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ENDIF
                         @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                                      
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryPar:textonofiscal) +IF(cTipoDoc="NC"," NC","")+ " " + oQryPar:letranofiscal ;
                                      SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"                                      
                         @ nRow, .1 PRINT TO oPrn TEXT "No Valido como factura " ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryPar:textonofiscal)  ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"                     
                         @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     IF oQryVen1:coniva = 5 .and. oQryVen1:codcli <= 1 .and. "CONSUMIDOR"$oQryVen1:nombre 
                        @ nRow, .1 PRINT TO oPrn TEXT "A Consumidor Final";
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                        ELSE 
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre);
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT oQryVen1:cuit;
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva];
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     ENDIF 
                     nRow1 := nRow + .5
                     @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03 PRINT TO oPrn TEXT "Cant";
                                  SIZE .8,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 03.9 PRINT TO oPrn TEXT "Total";
                                  SIZE 0.9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                                      oQryDet1:GoTop()
                     nDesFac := 0                  
                     lImprimio_promo := .f.
                     FOR i = 1 TO oQryDet1:nRecCount           
                         nRow1 := nRow 
                         IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                            @ y+.01, 01 PRINT TO oPrn TEXT "Descuentos Promos" SIZE 5,1 CM FONT oFont ALIGN "TC" LASTROW nRow1
                            lImprimio_promo := .t.
                            nRow1 := nRow1 + .1
                         ENDIF  
                         @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart);
                              SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,06,1);
                              SIZE 0.7,.5 CM FONT oFont  ALIGN "R"
                         @ nRow1, 3.8 PRINT TO oPrn TEXT STR(oQryDet1:importe,9,2);
                              SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R" 
                         nDesFac := nDesFac + oQryDet1:descu                  
                         oQryDet1:Skip()                     
                      NEXT    
                      IF nDesFac > 0      
                          @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(STRTRAN(oQryVen1:observa,"PUNTO DE VENTA",""));
                                  SIZE 5,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"                  
                          @ nRow, .1 PRINT TO oPrn TEXT "Descuento $ " + STR(nDesFac,12,2);
                                  SIZE 5,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"            
                      ENDIF
                      @ nRow, .1 PRINT TO oPrn TEXT "Items:" + STR(oQryDet1:nRecCount,4) ;
                              SIZE 4.8,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"
                      @ nRow, .1 PRINT TO oPrn TEXT "Total $ " + STR(oQryVen1:importe,12,2);
                                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"            
                      IF oQryPar:emite_pie
                        @ nRow, .1 PRINT TO oPrn TEXT oQryPar:texto_pie ;
                                    SIZE 3,1.5 CM FONT oFont2 LASTROW nRow ALIGN "L"             
                      ENDIF
                      IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                        @ nRow,0 PRINT TO oPrn TEXT "Puntos: "+STR(oQryVen1:puntos,8) SIZE 4.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Acumulados: "+STR(oQryVen1:puntosacu,8) SIZE 4.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8) SIZE 4.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                      ENDIF
                      @ nRow, .1 PRINT TO oPrn TEXT "...";
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                      @ nRow, .1 PRINT TO oPrn TEXT "...";
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"                       
                  ENDPAGE
               ENDPRINT
              ELSE
               *** Impresion 80 mm
               *********** Impresion de Ticket NO FISCAL 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD
               DEFINE FONT oFont2  NAME "CALIBRI"           SIZE config:fon*1.2,config:fon*3 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 1
                     IF oQryP:imprimeDat
                         IF config:x1 = 2 .or. config:x1 = 3
                            @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                         ENDIF
                         IF config:x1 = 1 .or. config:x1 = 3
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                      SIZE 7.1,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                             @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ENDIF
                         @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                                      
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryPar:textonofiscal) +IF(cTipoDoc="NC"," NC","")+ " " + oQryPar:letranofiscal ;
                                      SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"              
                         @ nRow, .1 PRINT TO oPrn TEXT "No Valido como factura " ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryPar:textonofiscal)  ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"                     
                         @ nRow, .1 PRINT TO oPrn TEXT cNumcomp ;
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                      SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                     IF oQryVen1:coniva = 5 .and. oQryVen1:codcli <= 1 .and. "CONSUMIDOR"$oQryVen1:nombre 
                        @ nRow, .1 PRINT TO oPrn TEXT "A Consumidor Final";
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                        ELSE 
                        @ nRow, .1 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(oQryVen1:nombre);
                                  SIZE 7.1,1 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT oQryVen1:cuit;
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT "Cond. Fiscal: "+aIva[oQryVen1:coniva];
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 7.1,1 CM FONT oFont LASTROW nRow ALIGN "L"
                     ENDIF 
                     nRow1 := nRow + .5                     
                     @ nRow1, 00.00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03.60 PRINT TO oPrn TEXT "Cant";
                                  SIZE .9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 04.65 PRINT TO oPrn TEXT "Unit";
                                  SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 05.70 PRINT TO oPrn TEXT "Total";
                                  SIZE 1.4,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     oQryDet1:GoTop()  
                     oPrn:CmLine( nRow,0, nRow,9 )               
                     nRow := nRow + .2  
                     nDesFac := 0     
                     lImprimio_promo := .f.              
                     FOR i = 1 TO oQryDet1:nRecCount           
                         nRow1 := nRow
                         IF oQryDet1:punit < 0 .and. !lImprimio_promo 
                            @ y+.01, 01 PRINT TO oPrn TEXT "Descuentos Promos" SIZE 7.1,1 CM FONT oFont ALIGN "TC" LASTROW nRow1
                            lImprimio_promo := .t.
                            nRow1 := nRow1 + .1
                         ENDIF 

                         @ nRow1, 00.00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart);
                              SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03.60 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,06,2);
                              SIZE .9,.5 CM FONT oFont  ALIGN "R"
                         @ nRow1, 04.65 PRINT TO oPrn TEXT STR(oQryDet1:importe/oQryDet1:cantidad,9,2);
                              SIZE 1,.5   CM FONT oFont ALIGN "R"
                         @ nRow1, 05.70 PRINT TO oPrn TEXT STR(oQryDet1:importe,9,2);
                              SIZE 1.3,.5 CM FONT oFont LASTROW nRow ALIGN "R"                     
                         nDesFac := nDesFac + oQryDet1:descu     
                         oQryDet1:Skip()                     
                     NEXT
                     IF nDesFac > 0
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(STRTRAN(oQryVen1:observa,"PUNTO DE VENTA",""));
                                  SIZE 5,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT "Descuento $ " + STR(nDesFac,12,2);
                                  SIZE 5,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"                                   
                     ENDIF             
                     nRow1 := nRow
                     oPrn:CmLine( nRow1,0, nRow1,9 )
                     nRow := nRow + .3
                     @ nRow, .1 PRINT TO oPrn TEXT "Items:" + STR(oQryDet1:nRecCount,4) ;
                              SIZE 5,.5 CM FONT oFont2 LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT "Total $ " + STR(oQryVen1:importe,12,2);
                                  SIZE 7.1,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"            
                     IF oQryPar:emite_pie
                        @ nRow, .1 PRINT TO oPrn TEXT oQryPar:texto_pie ;
                                  SIZE 5.0,1.5 CM FONT oFont2 LASTROW nRow ALIGN "L"             
                     ENDIF
                     IF oApp:usar_puntos .and. oQryVen1:codcli > 1
                        @ nRow,0 PRINT TO oPrn TEXT "Puntos: "+STR(oQryVen1:puntos,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Acumulados: "+STR(oQryVen1:puntosacu,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                        @ nRow,0 PRINT TO oPrn TEXT "Total: "+STR(oQryVen1:puntos+oQryVen1:puntosacu ,8) SIZE 7.1,1 CM FONT oFont  ALIGN "L" LASTROW nRow
                     ENDIF
                     @ nRow, .1 PRINT TO oPrn TEXT "...";
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow, .1 PRINT TO oPrn TEXT "...";
                                  SIZE 7.1,.5 CM FONT oFont LASTROW nRow ALIGN "L"                       
                  ENDPAGE
               ENDPRINT
              ENDIF 
ENDCASE
oApp:cDestinoMail := ""
RETURN nil


**********************************************
** Historial de Ventas realizadas
STATIC FUNCTION VerHistorial(nCodcli,oQry,oBrw)
LOCAL oBot := ARRAY(2), oForm, lRta := .f., aCor, oFont, oFont1, oError,;
      oQryVen, oQryDet, oBrwVen, oBrwDet
oQryVen := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha as fecha, "+;                          
                          "  v.importe"+;
                          " FROM ge_"+oApp:cId+"ventas_encab v "+;
                          " WHERE v.codcli = " + ClipValue2Sql(nCodCli) + " AND v.ticomp IN ('FC','FR')  "+;
                          " ORDER BY v.fecha DESC" )
oQryDet := oApp:oServer:Query("SELECT codart,cantidad,detart,punit,importe FROM ge_"+oApp:cId+"ventas_det LIMIT 0 ")
           
DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0,-22
DEFINE DIALOG oForm TITLE "Historial"  FROM 05,15 TO 25,130 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)   
   @ 05, 05 SAY "COMPROBANTES" OF oForm SIZE 100,14 PIXEL FONT oFont1
   @ 25, 05 XBROWSE oBrwVen SIZE 170,100 PIXEL OF oForm DATASOURCE oQryVen ;
      COLUMNS "fecha","compro","importe";
      HEADERS "Fecha","Comprobante","Importe";
              SIZES 80,100,100;
      FOOTERS CELL LINES NOBORDER AUTOSORT ON CHANGE Actuali(oQryVen,oQryDet,oBrwDet)
   oBrwVen:aCols[3]:nFooterType   := AGGR_SUM   
   oBrwVen:MakeTotals()
   oBrwVen:CreateFromCode()   
   PintaBrw(oBrwVen,0)
   @ 05,185 SAY "Detalle Comprobante" OF oForm SIZE 205,14 PIXEL FONT oFont1
   @ 25,185 XBROWSE oBrwDet SIZE 260,100 PIXEL OF oForm DATASOURCE oQryDet ;
          COLUMNS 'codart',"detart","cantidad","punit","importe";
          HEADERS 'Codigo',"Detalle Producto","Cant.","Unitario","Total";
          SIZES 70,220,60,60,80 FOOTERS;
          CELL LINES NOBORDER AUTOSORT          
   oBrwDet:aCols[3]:nFooterType   := AGGR_SUM
   oBrwDet:aCols[5]:nFooterType   := AGGR_SUM
   oBrwDet:MakeTotals()
   oBrwDet:CreateFromCode()
   PintaBrw(oBrwDet,0)   

  
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Repetir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT Actuali(oQryVen,oQryDet,oBrwDet)
IF !lRta 
   RETURN NIL
ENDIF

TRY
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("DELETE FROM ventas_det_H")           
    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,ptotal,stotal,iva,codiva,neto,descuento,pcosto) "+;
                     "(SELECT v.codart,v.detart,v.cantidad,a.precioven,a.precioven*v.cantidad,"+;
                     "a.precioven*v.cantidad/1.21,a.precioven*v.cantidad-a.precioven*v.cantidad/1.21,"+;
                     "a.iva,a.precioven*v.cantidad/1.21,0,a.preciocos FROM ge_"+oApp:cId+"ventas_det v "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON v.codart = a.codigo "+;
                     "WHERE v.nrofac = "+ClipValue2Sql(oQryVen:compro)+" AND v.codart > 0)")
    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,ptotal,stotal,iva,codiva,neto,descuento) "+;
                     "(SELECT v.codart,v.detart,v.cantidad,v.punit,v.importe,"+;
                     "v.neton,v.iva,"+;
                     "v.codiva,v.neton,0 FROM ge_"+oApp:cId+"ventas_det v "+;                     
                     "WHERE v.nrofac = "+ClipValue2Sql(oQryVen:compro)+" AND v.codart <= 0)")
    oApp:oServer:CommitTransaction()
    oQry:Refresh()
    oBrw:Refresh()
    oBrw:Maketotals()
    ActualizarDet()
    oGet[19]:cText := oBrw:aCols[7]:nTotal 
  oGet[20]:cText := oBrw:aCols[8]:nTotal  
  oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
  oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value  
  oGet[42]:cText := oBrw:aCols[11]:nTotal
  oGet[19]:Refresh()
  oGet[20]:Refresh()
  oGet[21]:Refresh()
CATCH oError
    MsgStop("Error al repetir"+CHR(10)+oError:description,"Error")
    oApp:oServer:RollBack()
END TRY
RETURN nil

***********************************************
** Busca los articulos vendidos en cada factura
STATIC FUNCTION Actuali(oQryVen,oQryDet,oBrwDet)
LOCAL cWhere
cWhere := "nrofac = " + ClipValue2Sql(oQryVen:compro) 
oQryDet:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwDet:MakeTotals()
oBrwDet:Refresh()
RETURN .t.



************************************************************************************
***** Elegir factura para nota de credito
STATIC FUNCTION FacturarPresupu(nCodCli)
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oDlg1, oFont, mnumfac, ;
      mrta := .f., aCor, base, marchi, mtotal, mdescp := 0, mdeuda := 0,;
      aTipo  := {"Factura","Factur x Rem."}, oRep,;
      aTip1  := {"FC","FR"}, mtipo := 1, mletra := "A", mprefijo := oApp:prefijo,;
      mnumero := 0,oQryFac, oQryPresu,oBrwPresu
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5  



    oQryPresu:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"presupuestos WHERE codcli = "+ClipValue2Sql(nCodCli)+" AND estado = 1")
   
    IF oQryPresu:RecCount() = 0
       MsgStop("El cliente seleccionado no tiene presupuestos generados para facturar","Atencion!")
       RETURN nil
    ENDIF

    DEFINE DIALOG oDlg1 TITLE "Listado de facturas pendientes" OF oWnd1 FROM 05,15 TO 21,78
        oDlg1:lHelpIcon:=.f.

    @ 05,05 XBROWSE oBrwPresu DATASOURCE oQryPresu;
                     COLUMNS "id","fecha","vendedor","nombre","importe","fecvto";    
                     HEADERS "#","Fecha","Vendedor","Cliente","Importe","Vto.";
                     SIZES 40,70,70,200,70,70;
             OF oDlg1 SIZE 240,97 PIXEL AUTOSORT
    oQryPresu:bOnChangePage := {|| oBrwPresu:Refresh() }    
    oBrwPresu:CreateFromcode()
    PintaBrw(oBrwPresu,0)

    oBrwPresu:bKeyDown := { |nKey, nFlags| IF (nKey == VK_DELETE,;
                          IF(MsgNoYes("Seguro de borrar?","Atencion"),oBrwPresu:Delete(),);
                          ,IF(nKey==13,oBot1:Click,.f.))}

    acor := AcepCanc(oDlg1)
    @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT
    @ acor[3],acor[4]-aCor[2]-20 BUTTON oBot2 PROMPT "&Reimprimir" OF oDlg1 SIZE 35,10 ;
               ACTION (ReimprimirPresu(oQryPresu) ) PIXEL CANCEL
    @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwPresu:SetFocus()

    IF !mrta
       RETURN nil
    ENDIF

    IF oQryPresu:codcli > 0
       oGet[08]:cText= oQryPresu:codcli
       ValidaCli()
    ELSE
       oGet[08]:cText:= 0
       oGet[09]:cText:= oQryPresu:nombre
       oGet[10]:cText:= oQryPresu:direccion
       oGet[11]:cText:= oQryPresu:localidad
       oGet[12]:cText:= oQryPresu:cuit
       oGet[22]:cText:= oQryPresu:dni
       oGet[13]:Set(oQryPresu:coniva)
    ENDIF
    oApp:oServer:Execute("TRUNCATE ventas_det_H")
    oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,neto,descuento,descup,stotal,iva,codiva,ptotal,pcosto) "+;
                         "(SELECT codart,detart,cantidad,punit,neton,descu,descup,neto,iva,codiva,importe,pcosto FROM ge_"+oApp:cId+"presupuestos_det "+;
                         "WHERE numven = "+ClipValue2Sql(oQryPresu:id)+")")
    nBorrarPresu:= oQryPresu:id

oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[7]:nTotal
oGet[20]:cText := oBrw:aCols[8]:nTotal
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value
oGet[42]:cText := oBrw:aCols[11]:nTotal
RETURN nil


*******************************************
** Impresion de Presupuesto
FUNCTION ReimprimirPresu(oQryPresu)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado Ley Nº 19.640",;
                "IVA Responsable Inscripto Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA no Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont2, oFont1, oFont3, config, nHoja := 1, cCodigopro, nIva := 0, oQryDet,;
      dFecVen, lImpSinIva := .f., cNumcomp , oQryCli , lDolar := .f., oForm, oBot := ARRAY(2), lRta := .f.,;
      oGet := ARRAY(4), aCor, nDescuP
   DEFINE DIALOG oForm TITLE "Emision de presupuesto";
       FROM 05,15 TO 13,70  FONT oApp:oFont   

   @ 05, 50 CHECKBOX oGet[2] VAR lDolar OF oForm PIXEL SIZE 200,12 PROMPT "Emitir presupuesto en dolares"    
   IF oApp:presudiscriva
      @ 20, 50 CHECKBOX oGet[4] VAR lImpSinIva OF oForm PIXEL SIZE 200,12 PROMPT "Imprimir presupuesto sin IVA"
   ENDIF      
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
   ACTIVATE DIALOG oForm CENTER
   IF !lRta 
      RETURN nil 
   ENDIF
   dFecVen := oQryPresu:fecvto
   cNumcomp := STRTRAN(STR(oQryPresu:caja,4)+"-"+STR(oQryPresu:id,8)," ","0")
   oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(oQryPresu:codcli))
   oApp:cDestinoMail := oQryCli:mail
   oQryDet := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"presupuestos_det WHERE numven = "+ClipValue2Sql(oQryPresu:id))
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   ** PRESUPUESTOS
   DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
   DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
   DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
   PRINT oPrn NAME "Presupuesto "+cNumcomp PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
   FOR x := 1 TO 2
     nDescuP := 0
     PAGE
     nHoja := 1
     nIva := 0
     nRow := (oPrn:nHorzRes() / 80) / 47
     IF FILE('fondopre.jpg')
        @ 0,0 PRINT TO oPrn IMAGE "fondopre.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
        ELSE
        @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
     ENDIF
     *oPrn:SayImage(0,0, "fondofac.jpg",;
     *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
     oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
     @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
              SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
     oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
     oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
     oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
     oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
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
     oPrn:CmSay( 1.7  , 11, "PRESUPUESTO", oFont1 )   
     oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
     oPrn:CmSay( 1.5, 9.8, "X",oFont2)
     oPrn:CmSay( 2.0, 16, "N°: "+cNumcomp,oFont)         
     oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(oQryPresu:fecha),oFont)
     IF dFecVen <> nil
         oPrn:CmSay( 3.0, 11, "Fecha de vencimiento:"+DTOC(dFecVen),oFont)
     ENDIF

     oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
     oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
     oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

     @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
     @ 5.5, 4.1 PRINT TO oPrn TEXT oQryPresu:cuit;
              SIZE 6,.5 CM FONT oFont ALIGN "L"
     @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
              SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
     @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPresu:nombre) ;
              SIZE 8,1 CM FONT oFont LASTROW nRow 
     @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
     @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryPresu:coniva] ;
              SIZE 6,.5 CM FONT oFont ALIGN "L"
     nRow := IF(nRow<6,6,nRow)
     @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
              SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
     @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryPresu:direccion) + " " + ;
                                           ALLTRIM(oQryPresu:localidad) ;
              SIZE 8,1 CM FONT oFont 
     /*@ 6.5, 01 PRINT TO oPrn TEXT "Forma de Pago:" ;
              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
     @ 6.5, 4.1 PRINT TO oPrn TEXT aFormaNom[nFormaPago] ;
              SIZE 6,.5 CM FONT oFont ALIGN "L"*/

     @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
              SIZE 7,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unit."+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
              SIZE 2.1,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal"+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
              SIZE 3,.5 CM FONT oFont ALIGN "R"
     y := 9.2
     oQryDet:GoTop()
           
     FOR i = 1 TO oQryDet:nRecCount                      
         //@ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
         //     SIZE 2.8,.5 CM FONT oFont ALIGN "R"
         cCodigopro := ""
         IF oQryDet:codart > 0              
            cCodigoPro := oApp:oServer:Query("SELECT codigopro FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryDet:codart)):codigopro
         ENDIF 
         IF oApp:impcodpro
            @ y-0.07, 01 PRINT TO oPrn TEXT IF(EMPTY(cCodigopro),STR(oQryDet:codart,13),ALLTRIM(cCodigopro)) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
            ELSE 
            @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "TL"
         ENDIF             
         @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
              SIZE 7,2.5 CM FONT oFont LASTROW nRow ALIGN "TL"
         @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "TR"
         IF !oApp:presudiscriva     
             @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:punit/IF(lDolar,oApp:dolar,1),12,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "TR"
             @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryDet:importe/IF(lDolar,oApp:dolar,1),12,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "TR" 
             ELSE 
             @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:neto/oQryDet:cantidad/IF(lDolar,oApp:dolar,1),12,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "TR"
             @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryDet:neto/IF(lDolar,oApp:dolar,1),12,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "TR" 
             nIva := nIva + oQryDet:importe - oQryDet:neto     
         ENDIF   
         nDescuP := nDescuP + oQryDet:descu      
         y := nRow + .1
         IF y > 21
            @ 23, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
              SIZE 9,2 CM FONT oFont
            ENDPAGE 
            nHoja ++
            PAGE     
               IF FILE('fondopre.jpg')
                  @ 0,0 PRINT TO oPrn IMAGE "fondopre.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                  ELSE
                  @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
               ENDIF
               *oPrn:SayImage(0,0, "fondofac.jpg",;
               *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
               oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
               @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                        SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
               oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
               oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
               oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
               oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
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
               oPrn:CmSay( 1.7  , 11, "PRESUPUESTO", oFont1 )   
               oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
               oPrn:CmSay( 1.5, 9.8, "X",oFont2)
               oPrn:CmSay( 2.0, 16, "N°: "+cNumcomp,oFont)         
               oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(oQryPresu:fecha),oFont)
               IF dFecVen <> nil
                   oPrn:CmSay( 3.0, 11, "Fecha de vencimiento:"+DTOC(dFecVen),oFont)
               ENDIF

               oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
               oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
               oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

               @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                        SIZE 3,.5 CM FONT oFont3 ALIGN "R"
               @ 5.5, 4.1 PRINT TO oPrn TEXT oQryCli:cuit;
                        SIZE 6,.5 CM FONT oFont ALIGN "L"
               @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                        SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
               @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre) ;
                        SIZE 8,1 CM FONT oFont LASTROW nRow 
               @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                        SIZE 3,.5 CM FONT oFont3 ALIGN "R"
               @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryCli:coniva] ;
                        SIZE 6,.5 CM FONT oFont ALIGN "L"
               nRow := IF(nRow<6,6,nRow)
               @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                        SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
               @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                                     ALLTRIM(oQryCli:localidad) ;
                        SIZE 8,1 CM FONT oFont 
               /*@ 6.5, 01 PRINT TO oPrn TEXT "Forma de Pago:" ;
                        SIZE 3,.5 CM FONT oFont3 ALIGN "R"
               @ 6.5, 4.1 PRINT TO oPrn TEXT aFormaNom[nFormaPago] ;
                        SIZE 6,.5 CM FONT oFont ALIGN "L"*/

               @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                        SIZE 2.8,.5 CM FONT oFont ALIGN "L"
               @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                        SIZE 7,.5 CM FONT oFont ALIGN "L"
               @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                        SIZE 2,.5 CM FONT oFont ALIGN "R"
               @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unit."+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                        SIZE 2.1,.5 CM FONT oFont ALIGN "R"
               @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal"+IF(oApp:presudiscriva .and. !lImpSinIva," S/IVA","") ;
                        SIZE 3,.5 CM FONT oFont ALIGN "R"
               y := 9.2
         ENDIF
         oQryDet:Skip()
      NEXT       
      IF lDolar 
          oPrn:CmSay( y ,  1 ,"(Los Precios anteriores estan expresados en dolares americanos)",oFont)
          y := y + .5
      ENDIF 
      IF lImpSinIva 
          oPrn:CmSay( y ,  1 ,"(Los Precios anteriores NO INCLUYEN IVA)",oFont)
          y := y + .5
      ENDIF 
      y := y + .5
      @ y, 1 PRINT TO oPrn TEXT oQryPresu:observa ;
              SIZE 18,3 CM FONT oFont ALIGN "L"
      IF nDescuP > 0        
          @ 23.5,01  PRINT TO oPrn TEXT "Descuento General"+IF(lDolar,"u$s","$")+":"  ;
                  SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
          @ 23.5,5 PRINT TO oPrn TEXT STR(nDescuP/IF(lDolar,oApp:dolar,1),12,2) ;
              SIZE 4,.5 CM FONT oFont1 ALIGN "L"
      ENDIF    
      IF !oApp:presudiscriva        
          @ 23.5,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                  SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
          @ 23.5,15 PRINT TO oPrn TEXT STR(oQryPresu:importe/IF(lDolar,oApp:dolar,1),12,2) ;
                  SIZE 4,.5 CM FONT oFont1 ALIGN "L"
          ELSE 
          IF !lImpSinIva
              @ 23.5,11  PRINT TO oPrn TEXT "Tasa gral (IVA) "+IF(lDolar,"u$s","$")+":"  ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
              @ 23.5,15 PRINT TO oPrn TEXT STR(nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                      SIZE 4,.5 CM FONT oFont1 ALIGN "L"
              @ 24.0,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
              @ 24.0,15 PRINT TO oPrn TEXT STR(oQryPresu:importe/IF(lDolar,oApp:dolar,1),12,2) ;
                      SIZE 4,.5 CM FONT oFont1 ALIGN "L"
             ELSE             
              @ 24.0,11  PRINT TO oPrn TEXT "Total presupuesto "+IF(lDolar,"u$s","$")+":"  ;
                      SIZE 3.9,.5 CM FONT oFont3 ALIGN "R"
              @ 24.0,15 PRINT TO oPrn TEXT STR(oQryPresu:importe/IF(lDolar,oApp:dolar,1)-nIva/IF(lDolar,oApp:dolar,1),12,2) ;
                      SIZE 4,.5 CM FONT oFont1 ALIGN "L"
          ENDIF            
      ENDIF 
      @ 24.0,1  PRINT TO oPrn TEXT "Vendedor: "+ALLTRIM(oQryPresu:vendedor) ;
                      SIZE 5,.5 CM FONT oFont3                             
     ENDPAGE
   NEXT x
   ENDPRINT
oApp:cDestinoMail := " "
RETURN nil


//////// Calcular Promos
STATIC FUNCTION CalcularPromos()
LOCAL cText, oQryTem, nNeto, nIva, nAux, i
//Borro las promos que cargue
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   RETURN nil 
ENDIF   
oApp:oServer:Execute("DELETE FROM ventas_det_H WHERE ESPROMO = TRUE")
//Calculo las nuevas promos
TEXT INTO cText 
(SELECT
    prom.CODART,
    prom.TIPO,
    prom.nompromo as DETART,
    CASE 
        WHEN prom.tipo = 2 AND FLOOR(p.CANTIDAD / prom.cantidad_requerida) > 0 THEN 
            p.cantidad - (FLOOR(p.CANTIDAD / prom.cantidad_requerida) * prom.cantidad_a_pagar + MOD(p.CANTIDAD, prom.cantidad_requerida))
        ELSE p.CANTIDAD
    END AS CANTIDAD,
    CASE
        WHEN prom.tipo = 1 THEN p.punit - prom.precio_especial        
        WHEN prom.tipo = 4 AND p.CANTIDAD BETWEEN prom.cantidad_minima AND prom.cantidad_maxima THEN p.punit - prom.precio_unitario
        ELSE p.PUNIT
    END AS PUNIT,    
    CASE
        WHEN prom.tipo = 3 AND p.CANTIDAD >= prom.descuento_a_unidad THEN
            prom.descuento_porcentual * FLOOR(p.CANTIDAD / prom.descuento_a_unidad)
        ELSE 0
    END AS DESCUENTO,    
    p.CODIVA    
FROM (SELECT CODART, DETART, SUM(CANTIDAD) AS CANTIDAD, PUNIT AS PUNIT, SUM(NETO) AS NETO,
       0 AS DESCUENTO, SUM(STOTAL) AS STOTAL, SUM(IVA) AS IVA, CODIVA, SUM(PTOTAL) AS PTOTAL, 
       0 AS PCOSTO, 0 AS IMPINT, 0 AS ESPROMO FROM ventas_det_H GROUP BY CODART) AS p
JOIN ge_000001promociones AS prom
    ON p.CODART = prom.codart
WHERE 
    CURRENT_DATE BETWEEN prom.fecha_inicio AND prom.fecha_fin
    AND (
        (prom.tipo = 1) OR
        (prom.tipo = 2 AND p.CANTIDAD >= prom.cantidad_requerida) OR
        (prom.tipo = 3 AND p.CANTIDAD >= prom.cantidad_requerida) OR
        (prom.tipo = 4 AND p.CANTIDAD BETWEEN prom.cantidad_minima AND prom.cantidad_maxima)
    ))
ENDTEXT



cText := STRTRAN(cText,'ge_000001promociones','ge_'+oApp:cId+'promociones')
oQryTem := oApp:oServer:Query(cText)
oQryTem:GoTop()
IF oQryTem:nRecCount > 0
   DO WHILE !oQryTem:Eof()
      DO CASE
         CASE oQryTem:codiva = 3
              nNeto := oQryTem:punit * oQryTem:cantidad 
              nIva  := 0
         CASE oQryTem:codiva = 4
              nNeto := oQryTem:punit * oQryTem:cantidad  / 1.105
              nIva  := oQryTem:punit * oQryTem:cantidad  - nNeto
         CASE oQryTem:codiva = 5
              nNeto := oQryTem:punit * oQryTem:cantidad  / 1.21
              nIva  := oQryTem:punit * oQryTem:cantidad  - nNeto
      ENDCASE
      DO CASE 
         CASE oQryTem:tipo = 1 .or. oQryTem:tipo = 2 .or. oQryTem:tipo = 4
              oApp:oServer:Execute("INSERT INTO ventas_det_H (CODART, DETART, CANTIDAD, PUNIT, "+;
                +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, PCOSTO, IMPINT, ESPROMO) VALUES ("+;
                ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                ClipValue2Sql(oQryTem:cantidad)+","+ClipValue2Sql(-oQryTem:punit)+","+;
                ClipValue2Sql(-nNeto)+",0,"+ClipValue2Sql(-nNeto)+","+Clipvalue2Sql(-nIva)+","+;
                ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql(-nNeto-nIva)+",0,0,1"+;
                +")")         
         CASE oQryTem:tipo = 3
              nNeto := nNeto / oQryTem:cantidad
              nIva  := nIva  / oQryTem:cantidad
              oApp:oServer:Execute("INSERT INTO ventas_det_H (CODART, DETART, CANTIDAD, PUNIT, "+;
                +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, PCOSTO, IMPINT, ESPROMO) VALUES ("+;
                ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                ClipValue2Sql(1)+","+ClipValue2Sql(-oQryTem:punit*oQryTem:descuento/100)+","+;
                ClipValue2Sql(-nNeto*oQryTem:descuento/100)+;
                ",0,"+ClipValue2Sql(-nNeto*oQryTem:descuento/100)+;
                  ","+Clipvalue2Sql(-nIva*oQryTem:descuento/100)+","+;
                ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql( (-nNeto-nIva)*oQryTem:descuento/100)+",0,0,1"+;
                +")")         

      ENDCASE   
      oQryTem:Skip()
   ENDDO
ENDIF
oQryDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
oBrw:GoBottom()
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal  
oGet[14]:cText:= IF(oQryArt <> nil,oQryArt:codigo,1)
oGet[14]:Refresh()
oGet[15]:cText:=SPACE(70)
oGet[25]:cText:=SPACE(500)
oGet[33]:cText := 0
oGet[25]:Refresh()
oGet[15]:Refresh()
FOR i:= 16 TO 18
   oGet[i]:cText:=0
   oGet[i+10]:cText:=0
   oGet[i]:Refresh()
   oGet[i+10]:Refresh()
NEXT i
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[9]:nTotal + oGet[38]:value  
oGet[42]:cText := oBrw:aCols[11]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN nil