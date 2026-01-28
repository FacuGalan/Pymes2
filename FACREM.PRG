#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"
************************************************************************************************
** FACTURAR REMITOS
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, nTipoEmp, nTipoFac, nTipoDoc, cVentana, oGet, oQryArt, oQryCli, oQryPar, oQryDet, oQryRub,;
       oBrw, oSay1, oDlg,cNumComp,lReventa,nConIva,oQryPun,nDescArt,nDescArt1,nLista,;
       nEfecti, nTarjet, nCheque, nCtaCte, nMPago, nCuotas, nPuntoVta, cLetra,nLisPre,cObserva,nPorIva,;
       cDetArt, nDescuGen, nCodIva, nTotal, nForPag, nRubro, nDeuda,oQryChe,mpagado,manticipo,dFecha,nTransfe,cVendedor,;
       oQryLisPre,aFormaNom,aFormaInc,aFormaTip,nFormaPago, nUltimoCli,nCodCli

PROCEDURE FACREM() 
LOCAL oBot := ARRAY(7), hHand , aTipoIva, aTipoDoc, cNomCli:=SPACE(30), cDireccion:=SPACE(30), cLocalidad:=SPACE(30),;
      cCUIT:=SPACE(13), nCodArt:=0, nCantidad:=0, nPunit:=0, nPtotal:=0, nTipoCli:=0, nNeto:=0, ;
      nIVA:=0,  dFecIni, dFecFin,  oFontLetra, oFontTotal,aVendedores,oQryUsua,cLisPre:="SIN LISTA ESPECIAL"+SPACE(31),;
      nDNI := 0, nTiArt,oQryIvaT, cRubNom := SPACE(30),nIngBru:=0,nIngBruP:=0,cCodArtP := SPACE(30), oQryFormas
 cVentana := PROCNAME()     
 IF ASCAN(oApp:aVentanas,cVentana) > 0
     hHand := ASCAN(oApp:aVentanas,cVentana)
     oApp:oWnd:Select(hHand)
     oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
     RETURN
  ENDIF
  AADD(oApp:aVentanas,cVentana)
oGet := ARRAY(41) 
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
"10  IVA Liberado – Ley Nº 19.640",;
"11  IVA Responsable Inscripto – Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social",;
"15  IVA NO Alcanzado"}
  
  
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS VENTAS_DET_H3 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(40) NOT NULL,";
    +"`CANTIDAD` DECIMAL(12,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUP`  DECIMAL(5,2) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`COSTO`  DECIMAL(12,3) DEFAULT '0.00',";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"`IMPINT` DECIMAL(12,3) DEFAULT '0.00',";
    +"`BULTOS` DECIMAL(6,1) DEFAULT '0.0',";
    +"`ESPROMO` TINYINT(1) DEFAULT '0' NOT NULL, ";
    +"`DEREMITO` TINYINT(1) DEFAULT '0' NOT NULL, ";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
    //+"`COSTO` DECIMAL(10,2) DEFAULT '0.00', PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS remitos_temp ";
    +"( `NUMREM` VARCHAR(16) NOT NULL, ";
    +"`TILDE` TINYINT(1),";
    +"`FECHA` DATE NOT NULL,";  
    +"`IMPORTE` DECIMAL(12,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`NUMREM`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
nUltimoCli := 0
nCodCli:=0
IF oApp:usua_es_vendedor
   cVendedor:= oApp:usuario
ELSE 
   cVendedor:= SPACE(50)
ENDIF
oQryUsua:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"vendedores ORDER BY nombre")
aVendedores:= {}
AADD(aVendedores,cVendedor)
oQryUsua:GoTop()
DO WHILE !oQryUsua:Eof()
   AADD(aVendedores,oQryUsua:nombre)
   oQryUsua:Skip()
ENDDO

oQryDet :=oApp:oServer:Query("SELECT * FROM VENTAS_DET_H3")
oQryDet:ZAP()

aTipoDoc := {"Factura","Nota de Débito","Nota de Crédito"}
nTipoDoc := 1 
oQryRub :=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"rubros")
oQryPar := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
nTipoEmp := oQryPar:coniva
nTipoFac := oQryPar:factura
nTipoCli := 1
oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
oQryArt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu   ORDER BY codigo")
oQryIvaT:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY tasa")
oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip))
oQryLisPre:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre")
nPuntoVta := oQryPun:caja

dFecha:= DATE()
dFecIni:= DATE()
dFecFin:= DATE()+30
nLisPre:=1
cObserva:=SPACE(100)
nPorIva:=21.00
nCodIva:= 5
nTiArt:=1
nDescuGen:=0
cDetArt:=SPACE(50)
nTotal:=0
nForPag:=2
nRubro := 1
cRubNom := SPACE(30)
lReventa:=.f.
nConIva:=1
cNumComp:= ""
nDescArt:=0
nDescArt1:=0
nLista:=1

IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    cerrar()
    RETURN
  ENDIF
ENDIF 

oQryFormas:= oApp:oServer:Query("SELECT nombre,incremento,tipo FROM ge_"+oApp:cId+"forpag ORDER BY codigo")
aFormaNom:={}
aFormaInc:={}
aFormaTip:={}
oQryFormas:GoTop()
DO WHILE !oQryFormas:eof()
  AADD(aFormaNom,oQryFormas:nombre)
  AADD(aFormaInc,oQryFormas:incremento)
  AADD(aFormaTip,oQryFormas:tipo)
  oQryFormas:Skip()
ENDDO
nFormaPago:=1
      
  //FUENTES -----------------------------------------------
  DEFINE FONT oFontLetra NAME "ARIAL" SIZE 35,60
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
  cLetra := IF(nTipoEmp=1 .or. nTipoEmp=2,"A","C")
  DEFINE WINDOW oWnd1 MDICHILD TITLE "Facturacion por ventas hechas con Remitos" OF oApp:oWnd NOZOOM ICON oApp:oIco
   
    *oWnd1:bGotFocus := { || oDlg:SetFocus}
    oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }

    //DLG -----------------------------------------------
    DEFINE DIALOG oDlg RESOURCE "FACREM" OF oWnd1
    //Fechas y tipo de Comprobante
    REDEFINE GET oGet[01] VAR dFecha ID 176  OF oDlg
    REDEFINE COMBOBOX oGet[02] VAR nTipoDoc ITEMS aTipoDoc ID 177 OF oDlg
    REDEFINE SAY oSay1    VAR cLetra  ID 180  OF oDlg FONT oFontLetra
    REDEFINE COMBOBOX oGet[36] VAR cVendedor ID 4011 OF oDlg ITEMS aVendedores WHEN(oApp:modifica_vend)
    //Numero de comprobante 
    REDEFINE GET oGet[05] VAR nPuntoVta ID 181 OF oDlg WHEN (.f.) PICTURE "9999"
    REDEFINE GET oGet[06] VAR cNumComp   ID 182 OF oDlg WHEN (.f.) PICTURE "@!"

    //CLIENTE
    REDEFINE GET oGet[08] VAR nCodCli ID 185 OF oDlg PICTURE "999999" ;
             ACTION (oGet[08]:cText:= 0, ValidaCli())  BITMAP "BUSC1" VALID (ValidaCli()) 
    REDEFINE GET oGet[09] VAR cNomCli ID 186 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[10] VAR cDireccion ID 187  OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[11] VAR cLocalidad ID 188  OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[12] VAR cCUIT      ID 189 OF oDlg PICTURE "99-99999999-9" WHEN(.F.);
             VALID(ValidaCuit(cCuit))
    REDEFINE GET oGet[22] VAR nDNI      ID 201 OF oDlg PICTURE "99999999" WHEN(.F.)
    REDEFINE COMBOBOX oGet[13] VAR nConIva ID 190 OF oDlg ITEMS aTipoIva WHEN(.F.);
             ON CHANGE ValidaCli(.f.) 
    REDEFINE GET oGet[23] VAR cObserva  ID 307 OF oDlg 

    REDEFINE GET oGet[40] VAR nLisPre ID 4017 OF oDlg PICTURE "999";
                 VALID((nLisPre = 0 .and. IF(nLisPre=0,(oGet[41]:cText:="SIN LISTA ESPECIAL"+SPACE(31))<>"xxx",.T.)) .or.;
                       Buscar(oQryLisPre,oDlg,oGet[40],oGet[41]));
                 ACTION (oGet[40]:cText:= 0, Buscar(oQryLisPre,oDlg,oGet[40],oGet[41])) BITMAP "BUSC1"
    REDEFINE GET oGet[41] VAR cLisPre ID 4018 OF oDlg PICTURE "@!" WHEN(.F.)

    //TIPO ARTICULO
    REDEFINE RADIO oGet[24] VAR nTiArt  ID 300,301 OF oDlg;
             ON CLICK(nCodArt:=0        ,cDetArt:=SPACE(70),nCantidad:=0      ,nPunit:=0         ,nTotal:=0,;
                      oGet[14]:Refresh(),oGet[15]:Refresh(),oGet[16]:Refresh(),oGet[17]:Refresh(),oGet[18]:Refresh(),;
                                         oGet[25]:Refresh(),oGet[26]:Refresh(),oGet[27]:Refresh(),oGet[28]:Refresh())
    
    //Datos del articulo registrado
    REDEFINE GET oGet[14] VAR nCodArt   ID 191  OF oDlg PICTURE "99999999999999" WHEN(nTiArt=1);
             ACTION (oGet[14]:cText:= 0, ValidaArt())  BITMAP "BUSC1" VALID(ValidaArt())
    REDEFINE GET oGet[15] VAR cDetArt   ID 192  OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[16] VAR nCantidad ID 193  OF oDlg PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=1)
    REDEFINE GET oGet[17] VAR nPunit    ID 194  OF oDlg PICTURE "999999999.999" WHEN(nTiArt=1 .and. oApp:modifica_precios)
    REDEFINE GET oGet[33] VAR nDescArt  ID 4003 OF oDlg PICTURE "999.99" WHEN(nTiArt=1 .and. oApp:modifica_descu)
    REDEFINE GET oGet[18] VAR nPtotal   ID 195  OF oDlg PICTURE "999999999.999" ;
            WHEN((oGet[18]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt/100)) = "-9" .and. nTiArt=1) 
    REDEFINE GET oGet[39] VAR cCodArtP   ID 4016  OF oDlg WHEN(nTiArt=1 .and. oApp:usar_codpro);
             VALID(oGet[39]:cText=SPACE(30) .OR. ValidaArtP())
    //Datos del articulo ocacional
    REDEFINE GET oGet[25] VAR cDetArt   ID 302  OF oDlg PICTURE "@S35" WHEN(nTiArt=2)
    REDEFINE GET oGet[26] VAR nCantidad ID 304  OF oDlg PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=2)
    REDEFINE GET oGet[27] VAR nPunit    ID 305  OF oDlg PICTURE "999999999.999" WHEN(nTiArt=2);
                 VALID((oGet[28]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt1/100)) <> "xxx" )
    REDEFINE GET oGet[34] VAR nDescArt1  ID 4004 OF oDlg PICTURE "999.99" WHEN(nTiArt=2 .and. oApp:modifica_descu)
    REDEFINE GET oGet[28] VAR nPtotal   ID 306  OF oDlg PICTURE "999999999.999" WHEN(.f.)
    REDEFINE GET oGet[30] VAR nPorIva   ID 303  OF oDlg PICTURE "999.99" WHEN(nTiArt=2); 
             VALID((oQryIvaT:Seek(nPorIva,3) > 0) .and. ((nCodIva:=oQryIvaT:codigo) >0 ))
          
    //ingresos brutos 
    REDEFINE GET oGet[37] VAR nIngBruP  ID 4013 OF oDlg PICTURE "999.99" WHEN(.F.)
    REDEFINE GET oGet[38] VAR nIngBru   ID 4014 OF oDlg PICTURE "99999999.99" WHEN(.F.)
    //neto y IVA y total
    REDEFINE GET oGet[19] VAR nNeto  ID 198 OF oDlg PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[20] VAR nIVA   ID 199 OF oDlg PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[21] VAR nTotal ID 200 OF oDlg COLOR CLR_RED , CLR_YELLOW READONLY;
           PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)
       
    //GRILLA ---------------------------------------------------------------      
    
    REDEFINE XBROWSE oBrw DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","STOTAL","IVA","PTOTAL","CODIVA","descuento","impint","descup","bultos";
       HEADERS "Codigo","Detalle Articulo","Cantidad","P. Unit.","Neto","Sub Total","IVA","Total","Tasa","descuento","Imp.Int.","descup","Bultos";
       FOOTERS ;
       SIZES 40,246,55,65,70,65,65,65,80,40;
    ID 197 OF oDlg AUTOSORT
    PintaBrw(oBrw,0)
    
    oBrw:aCols[8]:nFooterTypE := AGGR_SUM
    oBrw:aCols[4]:nFooterTypE := AGGR_SUM
    oBrw:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw:aCols[11]:nFooterTypE := AGGR_SUM
    oBrw:aCols[13]:nFooterTypE := AGGR_SUM
    oBrw:aCols[9]:Hide()
    oBrw:aCols[3]:lAutoSave := .t.
    oBrw:aCols[3]:nEditType := EDIT_GET 
    oBrw:aCols[13]:lAutoSave := .t.
    oBrw:aCols[13]:nEditType := EDIT_GET 
    oBrw:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | IF(oQryDet:DEREMITO,MsgStop("No se puede modificar los valores del remito","Atencion!"),CambiaCant(xval,,))} 
    
    IF oApp:modifica_precios
       oBrw:aCols[4]:lAutoSave := .t.
       oBrw:aCols[4]:nEditType := EDIT_GET 
       oBrw:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,xval)} 
    ENDIF   
    
    //BOTONES ---------------------------------------------------------------
    //Elige remitos
    REDEFINE BUTTON oBot[1] ID 101 ACTION (BuscaRemitos(nCodCli,oGet)) WHEN(nCodCli>0)
    //cancelar
    REDEFINE BUTTON oBot[2] ID 102 ACTION (LimpiarForm()) 
    //grabar
    REDEFINE BUTTON oBot[3] ID 103 ACTION Validaciones() WHEN(oBrw:aCols[8]:nTotal > 0)
    //salir
    REDEFINE BUTTON oBot[4] ID 104 ACTION (oDlg:End()) CANCEL 
    //+
    REDEFINE BUTTON oBot[5] ID 196 ACTION(AgregaItem(nTiArt),IF(nTiArt=1,oGet[14]:Setfocus(),oGet[25]:Setfocus()) ) ;
                   WHEN(((nCodArt>0 .and. nTiArt=1 .and. nPtotal>0) .or. (nTiArt=2 .and. cDetArt<>SPACE(30) .and. nPtotal>0)) .and. nCantidad > 0)
    //consultar precios 
    REDEFINE BUTTON oBot[6] ID 4012 ACTION (ConsultaPre(oGet),oBot[1]:SetFocus()) //WHEN(nCodArt>0)

    REDEFINE BUTTON oBot[7] ID 4001 ACTION (oWnd1:End(),RemitarFactura())
    // F9 Para grabar             
    oDlg:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[3]:Click,.f.) }
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT ;
    IF(!oApp:usabultosventa,;
        (oBrw:aCols[12]:Hide(),oDlg:Move(0,0)),;
        oDlg:Move(0,0)) ;
     VALID(oWnd1:End())
    ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN 


************************************************************************************
** Validar Articulo
STATIC FUNCTION ValidaArt()
LOCAL nPrecioVen,oQryPrecio

oQryArt:= oApp:oServer:Query("SELECT codigo,"+IF(oApp:usar_codpro,"codigopro","")+",nombre,stockact,precioven,iva,fecmod,reventa,preciocos,endolares,marca "+;
                             "FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(oGet[14]:cText))
IF oQryArt:RecCount() = 0 .OR. oGet[14]:value = 0
  oGet[14]:cText:= 0
  BuscarArt(oQryArt,oDlg,oGet[14])
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
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,stockact,precioven,iva,fecmod,reventa,preciocos,endolares,marca "+;
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
** Agregar item a la venta
STATIC FUNCTION AgregaItem(nTiArt)
LOCAL oQryIva, nTotalcIva, nIvaPes, nCodIva1, nSubTotal, nDescuento,;
      i,nCantidad,nPrecio1,nPrecio2,lRta:=.f.,nIvaCalc:=0,nDescMar

IF nTiArt = 1
   /*IF oQryPun:pidestock = 1 .and. oQryArt:stockact-oGet[16]:value < 0
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad ¿Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF
  ENDIF
  IF oQryPun:pidestock = 2 .and. oQryArt:stockact-oGet[16]:value < 0
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
     RETURN .F.
  ENDIF*/
  IF !ValidarCantidad(oQryArt:codigo,oGet[16]:value)
      RETURN .f.
  ENDIF 


   nDescMar:= oApp:oServer:Query("SELECT descuento FROM ge_"+oApp:cId+"desccli WHERE codmar ="+ClipValue2Sql(oQryArt:marca)+" AND "+;
                                 "codcli ="+ClipValue2Sql(oGet[8]:value)):descuento
   IF EMPTY(nDescMar) 
      nDescMar :=0
   ENDIF
   oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryArt:iva))
   nCodIva1 := oQryArt:iva
   nPrecio2:= oGet[17]:value * oGet[16]:value
   nDescuento:= nPrecio2 * ( IF(nDescMar>0,nDescMar,IF(nDescArt>0,nDescArt,nDescuGen))/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
   nSubTotal:= nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1
   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,descup,stotal,costo) "+;
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
                                 ClipValue2Sql(oQryArt:preciocos)+;
                         " )" ) 
ELSE
 nDescuento:=oGet[18]:Value * (IF(nDescArt1>0,nDescArt1,nDescuGen)/100)
 nSubTotal:=oGet[18]:Value - nDescuento
 nIvaPes := nSubTotal * (nPorIva/100)
 nTotalcIva := nSubTotal + nIvaPes
 nCodIva := IF(nPorIva=0,3,nCodIva)
 oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,descup,stotal) "+;
                      "VALUE ( 0,"+;
                                 ClipValue2Sql(oGet[15]:value)+","+;
                                 ClipValue2Sql(oGet[16]:value)+","+;
                                 ClipValue2Sql(oGet[17]:value)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(oGet[18]:value)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(IF(nDescArt>0,nDescArt,nDescuGen))+","+;
                                 ClipValue2Sql(nSubTotal)+;
                       " )" )
ENDIF                                
oApp:oServer:NextResult()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
cLetra := IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6 ,"A","B"),"C")
oGet[19]:cText := oBrw:aCols[7]:nTotal 
oGet[20]:cText := oBrw:aCols[8]:nTotal  
oGet[14]:cText:=1
oGet[14]:Refresh()
oGet[15]:cText:=SPACE(70)
oGet[25]:cText:=SPACE(70)
oGet[25]:Refresh()
oGet[15]:Refresh()
FOR i:= 16 TO 18
   oGet[i]:cText:=0
   oGet[i+10]:cText:=0
   oGet[i]:Refresh()
   oGet[i+10]:Refresh()
NEXT i
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal     
oGet[38]:cText := oBrw:aCols[6]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[8]:nTotal + oGet[38]:value
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN .t.


STATIC FUNCTION ValidarCantidad(nCod, nVal)
LOCAL lRta := .t., nCanti, oQryAux, oQryS
IF nCod <= 0 .OR. nTipoDoc = 3
   RETURN .t.
ENDIF   
nCanti := oApp:oServer:Query("SELECT SUM(cantidad) as canti FROM VENTAS_DET_H3 WHERE codart ="+str(nCod)):canti
nCanti := nCanti + nVal
oQryAux := oApp:oServer:Query("SELECT* FROM ge_"+oApp:cId+"articu WHERE codigo ="+str(nCod))
  //Valido que tenga stock el producto cuando no es stock de otro
   IF oQryPun:pidestock = 1 .and. oQryAux:stockact-nCanti < 0 .and. !oQryAux:stockotro
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad ¿Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF            
  ENDIF
  //Valido que tenga stock el producto que es stock de otro
  IF oQryPun:pidestock = 1 .and. oQryAux:stockotro 
      oQryS := oApp:oServer:Query("SELECT r.CODUSA, (a.STOCKACT - (r.CANTIDAD * "+STR(nCanti)+" )) AS STOCK_FINAL "+;
                                  " FROM ge_"+oApp:cId+"reseta r "+;
                                  " JOIN ge_"+oApp:cId+"articu a ON r.CODUSA = a.CODIGO "+;
                                  " JOIN ge_"+oApp:cId+"articu a1 ON r.CODART = a1.CODIGO "+;
                                  " WHERE r.CODART = "+STR(nCod)+;
                                  " HAVING STOCK_FINAL < 0")
      IF oQryS:nRecCount > 0
          lRta:=MsgYesNo("El articulo que esta facturando tiene receta, y los articulos"+chr(10)+;
                  "que la componen estan fuera de stock,"+CHR(10)+;
                  "verifique su disponibilidad ¿Desea continuar?","Atencion")
          IF !lRta 
             RETURN .f.
          ENDIF                
      ENDIF    
  ENDIF

  //No dejo vender por falta de stock
  IF oQryPun:pidestock = 2 .and. oQryAux:stockact-nCanti < 0 .and. !oQryAux:stockotro
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
     RETURN .F.
  ENDIF
  //No dejo vender por falta de stock de la receta
  IF oQryPun:pidestock = 2 .and. oQryAux:stockotro 
      oQryS := oApp:oServer:Query("SELECT r.CODUSA, (a.STOCKACT - (r.CANTIDAD * "+STR(nCanti)+" )) AS STOCK_FINAL "+;
                                  " FROM ge_"+oApp:cId+"reseta r "+;
                                  " JOIN ge_"+oApp:cId+"articu a ON r.CODUSA = a.CODIGO "+;
                                  " JOIN ge_"+oApp:cId+"articu a1 ON r.CODART = a1.CODIGO "+;
                                  " WHERE r.CODART = "+STR(nCod)+;
                                  " HAVING STOCK_FINAL < 0")
      IF oQryS:nRecCount > 0
          MsgStop("No puede facturar, el articulo seleccionado tiene receta, "+chr(10)+;
                  "y los articulos que la componen estan fuera de stock."+CHR(10),"Atencion")
          RETURN .F.
      ENDIF    
  ENDIF


  IF oQryPun:pidestock < 3 .and. oQryAux:stockmin > 0 .and. oQryAux:stockact-nCanti  < oQryAux:stockmin .and. !oQryAux:stockotro
     MsgAlert("Se esta quedando sin stock, llego al stock minimo","Atencion")         
  ENDIF
RETURN lRta

*******************************************************************************************
******* MOSTRAR REMITOS A FACTURAR
STATIC FUNCTION ConsultaPre(oGet)
LOCAL oDlg1,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f., oCom, nOpc

/*IF oGet[24]:nOption() = 1
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
ENDIF*/
DEFINE DIALOG oDlg1 TITLE "Cambiar Forma de Pago" OF oWnd1 FROM 05,15 TO 12,50
    oDlg1:lHelpIcon:=.f.
acor := AcepCanc(oDlg1)
nOpc := nFormaPago
@ 05, 10 COMBOBOX oCom VAR nOpc  ITEMS aFormaNom SIZE 90,80 PIXEL
@ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
@ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN nil 
ENDIF 
nFormaPago := nOpc
oQryDet:GoTop()
DO WHILE !oQryDet:EOF()
   CambiaCant(,,,,)     
   oQryDet:Skip()
ENDDO   
RETURN nil

*****************************************
** Cambiar pendientes
/*STATIC FUNCTION CambiaCant(n,nPorc,nPUnit,cNombre)
LOCAL base := oQryDet:GetRowObj(),nPrecio2,nDescuento,nPrecio1,nIvaPes,nSubTotal,nTotalcIva,oQryIva,nCodIva1,nIvaCalc, oQryPrecio
DEFAULT n := base:cantidad,nPorc:= base:descup,nPUnit:= base:punit, cNombre:= base:detart
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " +;
           ClipValue2Sql(IF(base:codart>0,base:codiva,5)))
nLista := IF(lReventa,2,1)
IF base:codart > 0
    IF nPunit = base:punit 
       oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+" AND "+;
                                  "codart = "+ClipValue2Sql(base:codart))
       IF oQryPrecio:RecCount() > 0
          nPunit:= oQryPrecio:precio 
          ELSE 
          oQryArt:= oApp:oServer:Query("SELECT precioven,reventa,endolares FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
          nPunit:= IF(nLista=1,oQryArt:precioven,oQryArt:reventa) * IF(oQryArt:endolares,oQryPar:dolar,1)      
      ENDIF
    ENDIF  
ENDIF
nCodIva1 := base:codiva
nPrecio2:= nPUnit * (n)
nDescuento:= nPrecio2 * (nPorc/100)
nPrecio1:= nPrecio2 - nDescuento
nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
nSubTotal:= nPrecio1 - nIvaPes
nTotalcIva := nPrecio1


base:cantidad := n 
base:ptotal:=nTotalcIva
base:neto:=nPrecio2-nIvaCalc
base:iva:=nIvaPes
base:descuento:=nDescuento
base:descup:= nPorc
base:stotal:=nSubTotal
base:punit:= nPUnit
base:detart:= cNombre
oQryDet:oRow := base
oQryDet:Save()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal     
oGet[38]:cText := oBrw:aCols[7]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[8]:nTotal + oGet[38]:value
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN nil*/
STATIC FUNCTION CambiaCant(n,nPorc,nPUnit,cNombre)
LOCAL base := oQryDet:GetRowObj(),nPrecio2,nDescuento,nPrecio1,nIvaPes,nSubTotal,nTotalcIva,oQryIva,nCodIva1,nIvaCalc, oQryPrecio
DEFAULT n := base:cantidad,nPorc:= base:descup,nPUnit:= base:punit, cNombre:= base:detart
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " +;
           ClipValue2Sql(IF(base:codart>0,base:codiva,5)))
nLista := IF(lReventa,2,1)
IF base:codart > 0
    IF VALTYPE(nPunit) <> "N" .OR. VALTYPE(n) <> "N" 
       RETURN nil 
    ENDIF
    IF nPunit = base:punit 
       oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+" AND "+;
                                  "codart = "+ClipValue2Sql(base:codart))
       IF oQryPrecio:RecCount() > 0
          nPunit:= oQryPrecio:precio 
          ELSE 
          oQryArt:= oApp:oServer:Query("SELECT precioven,reventa,endolares FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
          nPunit:= IF(nLista=1,oQryArt:precioven,oQryArt:reventa) * IF(oQryArt:endolares,oQryPar:dolar,1)      
      ENDIF
    ENDIF  
    nPunit:= nPunit * (1+(aFormaInc[nFormaPago]/100))
ENDIF
nCodIva1 := base:codiva
nPrecio2:= nPUnit * (n)
nDescuento:= nPrecio2 * (nPorc/100)
nPrecio1:= nPrecio2 - nDescuento
nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
nSubTotal:= nPrecio1 - nIvaPes
nTotalcIva := nPrecio1


base:cantidad := n 
base:ptotal:=nTotalcIva
base:neto:=nPrecio2-nIvaCalc
base:iva:=nIvaPes
base:descuento:=nDescuento
base:descup:= nPorc
base:stotal:=nSubTotal
base:punit:= nPUnit
base:detart:= cNombre
oQryDet:oRow := base
oQryDet:Save()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal     
oGet[38]:cText := oBrw:aCols[6]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[8]:nTotal + oGet[38]:value
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN nil


*******************************************************************************************
******* MOSTRAR REMITOS A FACTURAR
STATIC FUNCTION BuscaRemitos(nCodCli,oGet)
LOCAL oDlg1,oBrwRem,oQryRem,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f., cRemitos := "", lRespetaPrecios := .f.,;
      oChe
oGet[23]:cText := SPACE(100)
oQryDet:ZAP()
oBrw:Refresh()
oBrw:Maketotals()
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE remitos_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("INSERT INTO remitos_temp (tilde,numrem,fecha) "+;
                     "(SELECT 0,nrorem,fecha "+;
                     "FROM ge_"+oApp:cId+"remitos r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                     "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = r.codiva "+;
                     "WHERE r.codcli = "+ClipValue2Sql(nCodCli)+" "+;
                     "AND r.facturado = 0 GROUP BY r.nrorem )")
oQryRem:= oApp:oServer:Query("SELECT * FROM remitos_temp ORDER BY fecha,numrem")

DEFINE DIALOG oDlg1 TITLE "Remitos a facturar" OF oWnd1 FROM 05,15 TO 23,65
    oDlg1:lHelpIcon:=.f.
@ 05,05 CHECKBOX oChe VAR lRespetaPrecios PROMPT "Respetar precios cargados" SIZE 100, 12 of oDlg1 PIXEL 
@ 20,05 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "tilde","numrem","fecha";    
                 HEADERS " ","Numero","Fecha";
                 SIZES 40,120,70;
         OF oDlg1 SIZE 190,97 PIXEL 
oQryRem:bOnChangePage := {|| oBrwRem:Refresh() }
oBrwRem:aCols[1]:SetCheck(nil,.f.)   
oBrwRem:aCols[1]:bLDClickData := {|| CambiaChek(oQryRem,oBrwRem)}
oBrwRem:aCols[1]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oQryRem,oBrwRem))}
oBrwRem:aCols[1]:nEditType := 1
oBrwRem:aCols[1]:bEditValue:= {|| IF(oQryRem:tilde,.t.,.f.) }
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
oQryRem:GoTop()
DO WHILE !oQryRem:Eof()
   IF oQryRem:tilde 
      cRemitos := cRemitos + STRTRAN(STR(VAL(SUBSTR(oQryRem:numrem,3,4)),4)+"-"+STR(VAL(Right(oQryRem:numrem,8)),8)+","," ","")
   ENDIF 
   oQryRem:Skip() 
ENDDO

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H3")
oApp:oServer:NextResult()
/*
oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,ptotal,neto,iva,codiva,descuento,stotal) "+;
                      "(SELECT r.codart,r.detart,SUM(r.cantidad),"+;
                      "SUM((a.precioven+a.precioven*r.incrp/100)*r.cantidad+((a.precioven+a.precioven*r.incrp/100)*r.cantidad)*i.tasa/100),"+; //ptotal
                      "SUM(a.precioven*r.cantidad),"+; //neto
                      "SUM(((a.precioven+a.precioven*r.incrp/100)*r.cantidad)*i.tasa/100),codiva,"+; //iva
                      "SUM((a.precioven*r.incrp/100)*r.cantidad),"+; //incremento
                      "SUM((a.precioven+a.precioven*r.incrp/100)*r.cantidad) "+; //subtotal
                      "FROM ge_"+oApp:cId+"remitos r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                      "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = r.codiva "+;
                      "WHERE (r.nrorem IN (SELECT numrem FROM remitos_temp WHERE tilde = 1)) AND (r.codart > 0) "+;
                      "GROUP BY r.codart )")
*/
** ATENCION!!! CADA CHOCLO ES PRECIO VENTA CALCULADO == "+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+",1)
IF !lRespetaPrecios
    oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,costo,descup,bultos,DEREMITO) "+;
                          "(SELECT r.codart,r.detart,SUM(r.cantidad),"+;
                          "(("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1))) ,"+; //punitario
                          "SUM( ("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+",1)*(r.incrp*-1/100))*r.cantidad ),"+; //ptotal
                          "SUM( (("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1))*r.cantidad) / (1+i.tasa/100) ),"+; //neto
                          "SUM( ("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+",1)*(r.incrp*-1/100))*r.cantidad - "+;
                          " (("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)*r.incrp*-1/100)*r.cantidad) / (1+i.tasa/100) ),codiva,"+; //iva
                          "SUM(("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)*(r.incrp/100))*r.cantidad),"+; //descuento
                          "SUM(("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)*(r.incrp*-1/100))*r.cantidad) - "+;
                          "SUM( ("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+",1)*(r.incrp*-1/100))*r.cantidad - "+;
                          " (("+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)+"+IF(lReventa,"a.reventa","a.precioven")+" * IF(a.endolares,"+ClipValue2Sql(oQryPar:dolar)+;
                          ",1)*r.incrp*-1/100)*r.cantidad) / (1+i.tasa/100) ),a.preciocos,r.incrp, "+; //subtotal
                          "auto, "+; //bultos
                          "TRUE "+;// VIENE DE UN REMITO (PARA NO DESCONTAR STOCK)
                          "FROM ge_"+oApp:cId+"remitos r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                          "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = r.codiva "+;
                          "WHERE (r.nrorem IN (SELECT numrem FROM remitos_temp WHERE tilde = 1)) AND (r.codart > 0) "+;
                          ""+;
                          "GROUP BY r.codart ORDER BY r.id )")
  ELSE 
  oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,ptotal,neto,iva,codiva,descuento,stotal,punit,bultos,descup,DEREMITO) "+;
                      "(SELECT codart,detart,cantidad,"+;
                      "importe,"+; //ptotal
                      "neton,"+; //neto
                      "iva,codiva,"+; //iva
                      "(neto+iva)*100/(100-incrp)*(incrp/100),"+; //incremento
                      "neto, "+; //subtotal
                      "importe/cantidad, "+; //punit
                      "auto, incrp,TRUE "+; //Bultos
                      "FROM ge_"+oApp:cId+"remitos  "+;
                      "WHERE (nrorem IN (SELECT rt.numrem FROM remitos_temp rt WHERE rt.tilde = 1 ))  AND (codart > 0)) ")  
ENDIF  
oApp:oServer:Execute('UPDATE VENTAS_DET_H3 v LEFT JOIN ge_'+oApp:cId+'articu a ON a.codigo = v.codart '+;
                     ' SET v.impint = a.impint * v.cantidad')
oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (codart,detart,cantidad,ptotal,neto,iva,codiva,descuento,stotal,punit,bultos,DEREMITO) "+;
                      "(SELECT codart,detart,cantidad,"+;
                      "importe,"+; //ptotal
                      "neton,"+; //neto
                      "iva,codiva,"+; //iva
                      "(neton*incrp*-1/100),"+; //incremento
                      "neto, "+; //subtotal
                      "importe/cantidad, "+; //punit
                      "auto, TRUE "+; //Bultos
                      "FROM ge_"+oApp:cId+"remitos  "+;
                      "WHERE (nrorem IN (SELECT rt.numrem FROM remitos_temp rt WHERE rt.tilde = 1 ))  AND (codart = 0)) ")
oApp:oServer:Execute("DELETE FROM VENTAS_DET_H3 WHERE cantidad = 0")
oApp:oServer:NextResult()

oQryDet:Refresh()
ActualizarDet(lRespetaPrecios)
oBrw:Refresh()
oBrw:Maketotals()
IF cLetra = "A"
   oGet[19]:cText := oBrw:aCols[6]:nTotal 
   oGet[20]:cText := oBrw:aCols[7]:nTotal 
   ELSE
   oGet[19]:cText := 0
   oGet[20]:cText := 0
ENDIF     
oGet[38]:cText := oBrw:aCols[6]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[8]:nTotal + oGet[38]:value
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
oGet[23]:cText := " Rem:"+cRemitos + SPACE(255)
RETURN nil

**************************************************
*** ACTUALIZAR TODO EL DETALLE 
STATIC FUNCTION ActualizarDet(lRespetaPrecios)
DEFAULT lRespetaPrecios := .f.
oQryDet:GoTop()
DO WHILE !oQryDet:EOF()
   IF !lRespetaPrecios 
      CambiaCant(,,,)
      //ELSE 
      //CambiaCant(,,oQryDet:punit,)
   ENDIF   
   oQryDet:Skip()
ENDDO
RETURN .T.

**************************************
STATIC FUNCTION CambiaChek(oQry1,oBrw1)
LOCAL valor
valor := IF(oQry1:tilde=.f.,.t.,.f.)
oQry1:tilde := valor
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil


************************************************************************************
** Vaciar el formulario despues de grabar o cancelar
STATIC FUNCTION LimpiarForm()
oQryDet:Zap()
oBrw:Refresh()
oBrw:Maketotals()
oGet[37]:cText:=0
oGet[23]:cText:=SPACE(255)
oGet[38]:cText:=0
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal      
oGet[21]:cText := oBrw:aCols[8]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
oGet[08]:cText := 1
oGet[08]:SetFocus()
nUltimoCli := 0
nPuntoVta := oQryPun:caja
RETURN nil

************************************************************************************
STATIC FUNCTION ValidaCli(lVerCli)
LOCAL cLetra,nNro
DEFAULT lVerCli := .T.
/*
    oGet[08] --> nCodCli 
    oGet[09] --> cNomCli
    oGet[10] --> cDireccion
    oGet[11] --> cLocalidad
    oGet[12] --> cCUIT  
    oGet[22] --> nDNI  
    oGet[13] --> nConIva
    oGet[19] --> nNeto
    oGet[20] --> nIva
*/
IF lVerCli
  Buscar(oQryCli,oDlg,oGet[08])
  oGet[09]:cText := oQryCli:nombre
  oGet[10]:cText := oQryCli:direccion
  oGet[11]:ctext := oQryCli:localidad
  oGet[12]:cText := oQryCli:cuit
  oGet[22]:cText := oQryCli:dni
  IF oGet[08]:value <> nUltimoCli
     oGet[23]:cText := SPACE(100)
     oQryDet:Zap()
     oBrw:Refresh()
     oBrw:Maketotals()
     nUltimoCli := oGet[08]:value
  ENDIF   
  oGet[37]:cText := oQryCli:iibb  * IF(oApp:percep_iibb,1,0)
  oGet[13]:Set(oQryCli:coniva)
  oGet[09]:Refresh()
  oGet[10]:Refresh()
  oGet[11]:Refresh()
  oGet[12]:Refresh()
  oGet[22]:Refresh()
  oGet[13]:Refresh()
  manticipo:=oQryCli:saldo
  lReventa:= (oQryCli:lispre=2)
  nLisPre:= oQryCli:lispreesp
  oGet[40]:Refresh()
  oGet[41]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"lispre WHERE codigo = "+ClipValue2Sql(oQryCli:lispreesp)):nombre
ENDIF
cLetra := IF(oApp:tipo_iva<>6,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2  .or. oGet[13]:nAt = 6,"A","B"),"C")
nNro:= oApp:oServer:Query("SELECT "+IF(cLetra="A","facturaa","facturab")+"+1 AS num FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip)):num
cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
oGet[06]:Refresh()
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal    
oSay1:SetText(cLetra) 
oGet[19]:Refresh()
oGet[20]:Refresh()
RETURN .T.


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
LOCAL cLetra, oGet1 := ARRAY(20), oBot := ARRAY(4), oForm, lRta := .f., oBrw2, oQryCuo, dFecVto,oBrw1,nCliente,;
      nCodCue:=0,nNumOpe:=0,nNetoPar,aNomCondVen,aNomFormaPag,aCodCondVen,aCodFormaPag,nCondVen:=1,nFormaPag:=1,;
      cDetTar, cDetChe := SPACE(30), aTablaIva := {}, oTabIva, nNro, cCae,dFecVtoC, cTipoDoc,nCodAut:=0,nCodVen:=0,lCuenta:=.f.,;
      oQryVen, oQryPag, oQryPagCon, oQryPagFac, base, oErr, nRecibo, nTipFor, nSaldo := 0,cTipo:=" ",;
      oQryTar, aTarjetas, oError,oDlg2, nCodPro:=0,nCodBan:=0,cObserva1:=SPACE(255),nNumeroOrd:=0,nNumDep:=0,nOpcion:=1, lFisc,;
      oQryCondVen:=oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cond_venta"),oComb:=ARRAY(2),;
      oQryFormaPag:=oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"forpag"), nPunLocal,;
      nPuntos := 0, nPuntosAcu := 0,cSQL

cLetra := IF(nTipoEmp=1 .or. nTipoEmp=2,IF(oGet[13]:nAt = 1 .or. oGet[13]:nAt = 2 .or. oGet[13]:nAt = 6,"A","B"),"C")
// Validar que el DATOS CLIENTE
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
CalcularPromos()
nEfecti  := 0
nTarjet  := 0
nTransfe := 0
nCheque  := 0
nCtaCte  := 0
nMPago   := 0
nCuotas  := 1 
dFecVto  := DATE()+30
mpagado  := nTotal 

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
    REDEFINE BUTTON oBot[4]  ID 201 OF oForm ACTION ArmaPLan(oGet1, oBrw2, oQryCuo ) WHEN(nCtaCte > 0 .and. oApp:usar_cuotas)   
    REDEFINE BUTTON oBot[2]  ID 102 OF oDlg2 ACTION (lrta:=.t.,oDlg2:End()) 
    REDEFINE BUTTON oBot[3]  ID 103 OF oDlg2 ACTION (lRtA:=.F.,oDlg2:End())
ACTIVATE DIALOG oDlg2 CENTER


IF !lRta
   RETURN nil
ENDIF 
IF ROUND(nCtaCte,2) > 0 .and. oApp:usar_cuotas .and. oQryCuo:nRecCount = 0
   MsgStop("No genero el plan de cuotas","Error")
   LOOP
ENDIF
nCliente:=oGet[8]:value

IF nCtaCte > 0 .and. nCliente = 1
   MsgStop("Consumidor final no puede pagar en Cta.Cte.","Error")
   LOOP
ENDIF  

IF oApp:usar_limite_cred
  IF nCtaCte > 0 .AND. ((oQryCli:saldo + nCtaCte) > oQryCli:limite) .and. nCliente > 0
     IF !PedirClave("El cliente que quiere facturar tiene el limite de credito excedido, ingrese la clave de autorizacion para continuar",oDlg)
        LOOP
     ENDIF
  ENDIF
ENDIF

IF nCliente = -1 .and. nCtaCte > 0 
   MsgStop("Un cliente ocacional no puede pagar en Cta. Cte.","Error")
   LOOP
ENDIF

IF oApp:usar_dias_deuda
    IF oApp:oServer:Query("SELECT DATEDIFF(CURDATE(),MIN(fecvto)) AS dias FROM ge_"+oApp:cId+"ventas_cuota "+;
                          "WHERE saldo > 0 AND cliente = "+ClipValue2Sql(oGet[08]:cText)):dias > oApp:dias_deuda
       IF !PedirClave("El cliente que queire facturar tiene una deuda impaga que excede el limite de dias permitidos a deber,"+;
                      " ingrese la clave de autorizacion para continuar",oDlg)
          LOOP
       ENDIF
    ENDIF
ENDIF


IF nTransfe > 0
     lCuenta:=  DatosTransferencia(@nCodCue,@nNumOpe,@cObserva1)
     IF !lCuenta
        LOOP
     ENDIF
ENDIF  
EXIT 
ENDDO

nCondVen := aCodCondVen[nCondVen]
nFormaPag:= aCodFormaPag[nFormaPag]

oTabIva := oApp:oServer:Query("SELECT codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H3 GROUP BY codiva")
DO WHILE !oTabIva:Eof()
   AADD(aTablaIva,{oTabIva:codiva,oTabIva:neto,oTabIva:iva})
   oTabIva:Skip()
ENDDO
IF nTipoDoc=1
   dFecVtoC:= DATE()
   cCae:= ""
   nTipFor:=01
   lFisc:= MsgYesNo("¿Desea emitir el tiquet fiscal?","Atencion!")
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
          FacturaElec(oGet, nTipoFac, nPuntoVta, nTipoDoc, cLetra, aTablaIva, oBrw, @nNro, @cCae, @dFecVtoC,@nTipFor,.t.)
          IF nNro = 0
             MsgStop("Fallo el impresor fiscal","Error")
             Return nil 
          ENDIF 
      ELSE
          nPuntoVta := oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
          nNro := FacturaFiscal(oQryDet,oGet[08]:Value)
          IF nNro = 0
             MsgStop("Fallo el impresor fiscal","Error")
             Return nil 
          ENDIF 
      ENDIF 
   ELSE
     nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
     nNro := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):presupu+1
     cLetra := "X"
     cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
     cTipoDoc := IF(nTipoDoc=1,"FC",IF(nTipoDoc=2,"ND","NC"))
     *FacturaNoFiscal(oQryDet,oGet[08]:Value,cTipoDoc+cNumComp)
   ENDIF
   // Falta las impresiones fiscales de NC Y ND y Presupuesto y Remito  
ENDIF

cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
cTipoDoc := IF(nTipoDoc=1,"FR",IF(nTipoDoc=2,"ND","NC"))
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
          base:importe := IF(nEfecti + nTransfe + nTarjet + nCheque + manticipo + nMPago> nTotal,nTotal,;
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
                                                     "importe = "+ ClipValue2Sql(nTransfe)+","+;
                                                     "observa = 'TRANSFERENCIA'")
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                      ClipValue2Sql(RIGHT(cNumComp,13))+",2,2,"+ClipValue2Sql(nTransfe * IF(cTipoDoc="NC",-1,1))+","+;
                                      "'TRANSFERENCIA',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
           ENDIF
          
          IF ncheque > 0
             base := oQryPagCon:GetBlankRow()
             base:numero  := nRecibo
             base:importe := nCheque * IF(cTipoDoc="NC",-1,1)
             base:observa := IF(EMPTY(cDetChe),"CHEQUE: " + STR(nRecibo),cDetChe)
             base:codcon := 3
             base:tipocon := 3
             oQryPagCon:oRow := base
             oQryPagCon:Save()
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
             base:observa := IF(EMPTY(cDetTar),"TARJETA: " + STR(nRecibo),cDetTar)
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
      nNetoPar:= IF(nCtaCte<oBrw:aCols[6]:nTotal,nCtaCte,oBrw:aCols[6]:nTotal)
      //2 - CUOTAS DE PAGO EN CTA CTE ------------------------------------------------------  
      IF oApp:usar_cuotas    
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
                                                        "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip) "+;
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
                                         ClipValue2SQL(oApp:cIp)+" "+;
                              " FROM ventas_cuota_h)")
      ENDIF
      IF !oApp:usar_cuotas
             oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
                                                        "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip) "+;
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
                                         ClipValue2SQL(oApp:cIp)+")")
      ENDIF  

      // DESCUENTO STOCK DE LOS ARTICULOS AGREGADOS QUE NO VIENEN DE REMITO Y NO SON PROMO

      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
                   "INNER JOIN "+; 
                   "("+; 
                   "SELECT codart, SUM(cantidad) as suma "+;
                   "FROM VENTAS_DET_H3 "+;
                   "WHERE ESPROMO IS FALSE AND codart > 0 AND DEREMITO IS FALSE "+;
                   "GROUP BY codart "+;
                   ") v ON a.codigo = v.codart "+;
                   "SET a.stockact = a.stockact - (v.suma * "+IF(cTipoDoc="NC","-1","1")+") WHERE a.stockotro IS FALSE")

      cSQL := "UPDATE ge_"+oApp:cId+"articu m " + ;
      "JOIN ( " + ;
      "  SELECT r.codusa AS codigo_usado, SUM(d.cantidad * r.cantidad) AS total_a_restar " + ;
      "  FROM VENTAS_DET_H3 d " + ;
      "  JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart " + ;
      "  JOIN ge_"+oApp:cId+"reseta r ON r.codart = d.codart " + ;
      "  WHERE a.stockotro = TRUE AND d.ESPROMO IS FALSE AND DEREMITO IS FALSE " + ;
      "  GROUP BY r.codusa " + ;
      ") AS t ON t.codigo_usado = m.codigo " + ;
      "SET m.stockact = m.stockact - t.total_a_restar*"+IF(cTipoDoc="NC","-1","1")

      oApp:oServer:Execute( cSQL )

      //3 - FACTURA ------------------------------------------------------------------------
      IF nCtaCte <= 0  
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = "+ClipValue2Sql(ABS(nCtaCte)) + ", FECULT = CURDATE() WHERE codigo = " +ClipValue2Sql(nCliente))
      ELSE
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = 0, FECULT = CURDATE() WHERE codigo = " +ClipValue2Sql(nCliente))
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
                            ", codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H3 GROUP BY codiva)")
      //-- detalle de venta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
                        " (codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,codiva,neton,descu,pcosto,descup,bultos) "+;
                        " (SELECT codart,detart,cantidad,punit,"+ClipValue2Sql(oGet[1]:value)+","+ClipValue2Sql(nCliente)+","+;
                        "         "+ ClipValue2Sql(cTipoDoc+cNumComp)+",ptotal, stotal,iva,codiva,neto,descuento,costo,descup,bultos FROM VENTAS_DET_H3)")
      //-- encabezado de venta
      IF oApp:usar_puntos
         nPuntosAcu := oApp:oServer:Query("SELECT puntos FROM ge_"+oApp:cId+"clientes  WHERE codigo = "+ClipValue2Sql(nCliente) ):puntos
         nPuntosAcu := nPuntosAcu + INT(nTotal/oApp:pesos_x_punto)
         nPuntos :=  INT(nTotal/oApp:pesos_x_punto)
      ENDIF
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,coniva,fecha,neto,iva,iibb,importe,tipopag,observa,"+;
                                                     "nombre,cuit,dni,direccion,localidad,percep,cae,fecvto,tipfor,usuario,fecmod,ip,vendedor,condven,formapag,hora,puntos,puntosacu) VALUES "+;
                           "("+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+","+;
                            ClipValue2Sql(nCliente)+","+ClipValue2Sql(nConIva)+","+;
                            ClipValue2Sql(dFecha)+","+ClipValue2Sql(oBrw:aCols[6]:nTotal)+","+ClipValue2Sql(oBrw:aCols[7]:nTotal)+","+;
                            ClipValue2SQL(oGet[38]:cText)+","+ClipValue2Sql(nTotal)+","+IF(nCtaCte>0,"2","1")+","+;
                            ClipValue2Sql(oGet[23]:cText)+","+;
                            ClipValue2Sql(oGet[9]:cText)+","+ClipValue2Sql(oGet[12]:cText)+","+ClipValue2Sql(oGet[22]:cText)+","+;
                            ClipValue2Sql(oGet[10]:cText)+","+ClipValue2Sql(oGet[11]:cText)+","+ClipValue2SQL(oGet[37]:cText)+","+;
                            ClipValue2Sql(cCae)+","+ClipValue2Sql(dFecVtoC)+","+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+","+;
                            ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2Sql(cVendedor)+","+;
                            ClipValue2Sql(nCondVen)+","+ClipValue2Sql(nFormaPag)+;
                            ",CURTIME(),"+Clipvalue2sql(nPuntos)+","+ClipValue2Sql(nPuntosAcu) +")")
      
      IF oApp:usar_puntos
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos + "+ClipValue2Sql(INT(nTotal/oApp:pesos_x_punto)))
      ENDIF

     // ACTUALIZO LOS REMITOS FACTURADOS
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"remitos SET facturado = TRUE, factura = "+ClipValue2Sql(cTipoDoc+cNumComp)+" "+;
                           "WHERE nrorem IN (SELECT numrem FROM remitos_temp WHERE tilde = 1 GROUP BY numrem)")
      //fin de INSERCIONES------------------------------------------------------------------
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
  CATCH oErr
      MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN .F.
  END TRY
 IF lFisc  
    IF oApp:factura = 1
       PrintFactuElec(cTipoDoc,cNumComp)  
    ENDIF    
    ELSE
    IF oQryPar:pregunta_ticket
        IF MsgYesNo("¿Desea imprimir el ticket no fiscal?","Atencion!")
            FacturaNoFiscal(cTipoDoc,cNumComp)
        ENDIF
    ENDIF
 ENDIF
 * IF nForPag = 1  
 *    lRta := MsgYesNo("Desea imprimir el recibo de anticipos?","Atencion")
 *    IF lRta 
 *     *  Reci(nRecibo,.f.)
 *    ENDIF
 * ENDIF   
  *oQryCuo:ZAP()
  oQryCuo:End()
  oQryCuo := nil
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
   @ 20, 50 GET oGet[3] VAR nNumOpe PICTURE "99999999" OF oForm PIXEL RIGHT 
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


******************************************************************************************
***** SI PAGA EN EFECTIVO DA LA POSIBILIDAD DE HACER UN ANTICIPO DE PROVEEDOR O UN DEPOSITO BANCARIO
STATIC FUNCTION DiscriminaEfec(nCodPro,nCodBan,cObserva)
LOCAL oDlgE,oBotE,oGet1:=ARRAY(6),cNomPro:=SPACE(30),cNomBan:=SPACE(30),nForPag:=1,oQryPro1,oQryBan
oQryBan := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"bancos")
oQryPro1:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee")
DEFINE DIALOG oDlgE RESOURCE "FORMAPAG2" OF oDlg
oDlgE:lHelpIcon := .f.

 REDEFINE RADIO oGet1[01] VAR nForPag ID 100,101,102 OF oDlgE
 REDEFINE GET oGet1[02] VAR nCodPro ID 200 OF oDlgE PICTURE "999999";
              VALID(Buscar(oQryPro1,oDlgE,oGet1[02],oGet1[03]));
              ACTION (oGet1[02]:cText:= 0, Buscar(oQryPro1,oDlgE,oGet1[02],oGet1[03])) BITMAP "BUSC1" WHEN(nForPag=2)
 REDEFINE GET oGet1[03] VAR cNomPro ID 201 OF oDlgE PICTURE "@!" WHEN(.F.)
 REDEFINE GET oGet1[04] VAR nCodBan ID 202 OF oDlgE PICTURE "99";
              VALID(Buscar(oQryBan,oDlgE,oGet1[04],oGet1[05]));
              ACTION (oGet1[04]:cText:= 0, Buscar(oQryBan,oDlgE,oGet1[04],oGet1[05])) BITMAP "BUSC1" WHEN(nForPag=3)
 REDEFINE GET oGet1[05] VAR cNomBan ID 203 OF oDlgE PICTURE "@!" WHEN(.F.)
 REDEFINE GET oGet1[06] VAR cObserva ID 204 OF oDlgE PICTURE "@!" WHEN(nForPag>1)

 REDEFINE BUTTON oBotE ID 300 OF oDlgE ACTION(oDlgE:End())

ACTIVATE DIALOG oDlgE CENTER //ON INIT oGet1[01]:SetFocus()
RETURN nForPag

STATIC FUNCTION ArmaPLan(oGet1,oBrw2,oQryCuo)
LOCAL i, nCuotas := oGet1[09]:value, nValor := ROUND(oGet1[06]:value / nCuotas,2),;
      dFecVto := oGet1[10]:value, nAcu := 0, oRow, aLimites := {31,28,31,30,31,30,31,31,30,31,30,31}
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
base:codcli  := oGet[8]:value
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


STATIC FUNCTION CalcularPromos()
LOCAL cText, oQryTem, nNeto, nIva, nAux, i
//Borro las promos que cargue
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   RETURN nil 
ENDIF   
oApp:oServer:Execute("DELETE FROM VENTAS_DET_H3 WHERE ESPROMO = TRUE")
IF nCodCli > 1 .and. oApp:oServer:Query("SELECT excluyepromo FROM ge_"+oApp:cId+"clientes WHERE codigo = "+str(nCodCli)):excluyepromo
   //No 
   ELSE
  //Calculo las nuevas promos
  TEXT INTO cText 
  (SELECT
      prom.CODART,
      prom.TIPO,
      prom.id,
      prom.nompromo AS DETART,
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
  FROM  ge_000001promociones AS prom    
  JOIN (SELECT CODART, DETART, SUM(CANTIDAD) AS CANTIDAD, PUNIT AS PUNIT, SUM(NETO) AS NETO,
         0 AS DESCUENTO, SUM(STOTAL) AS STOTAL, SUM(IVA) AS IVA, CODIVA, SUM(PTOTAL) AS PTOTAL, 
         0 AS PCOSTO, 0 AS IMPINT, 0 AS ESPROMO FROM VENTAS_DET_H3 GROUP BY CODART) AS p    
      ON p.CODART = prom.codart   
  WHERE 
      CURRENT_DATE BETWEEN prom.fecha_inicio AND prom.fecha_fin
      AND (
          (prom.tipo = 1) OR
          (prom.tipo = 2 AND p.CANTIDAD >= prom.cantidad_requerida) OR
          (prom.tipo = 3 AND p.CANTIDAD >= prom.descuento_a_unidad) OR
          (prom.tipo = 4 AND p.CANTIDAD BETWEEN prom.cantidad_minima AND prom.cantidad_maxima)
      ) 
      GROUP BY prom.CODART, prom.TIPO)
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
                oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (CODART, DETART, CANTIDAD, PUNIT, "+;
                  +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, COSTO, IMPINT, ESPROMO) VALUES ("+;
                  ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                  ClipValue2Sql(oQryTem:cantidad)+","+ClipValue2Sql(-oQryTem:punit)+","+;
                  ClipValue2Sql(-nNeto)+",0,"+ClipValue2Sql(-nNeto)+","+Clipvalue2Sql(-nIva)+","+;
                  ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql(-nNeto-nIva)+",0,0,1"+;
                  +")")         
           CASE oQryTem:tipo = 3
                nNeto := nNeto / oQryTem:cantidad
                nIva  := nIva  / oQryTem:cantidad
                oApp:oServer:Execute("INSERT INTO VENTAS_DET_H3 (CODART, DETART, CANTIDAD, PUNIT, "+;
                  +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, COSTO, IMPINT, ESPROMO) VALUES ("+;
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
ENDIF  
oQryDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
oBrw:GoBottom()
oGet[19]:cText := oBrw:aCols[6]:nTotal 
oGet[20]:cText := oBrw:aCols[7]:nTotal  
oGet[14]:cText:= 1
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
oGet[38]:cText := oBrw:aCols[6]:nTotal * (oGet[37]:value/100) * IF(nTipoDoc=3,-1,1)
oGet[21]:cText := oBrw:aCols[8]:nTotal + oGet[38]:value  
//oGet[42]:cText := oBrw:aCols[11]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN nil