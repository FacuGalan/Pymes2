#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
************************************************************************************************
** Cambio de precios
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, oBrw, oDlg, cVentana,oQry, oQryBrw, nCant,oQryIvaDet,oBrwIvas,oBrwRet,lIncluido, ;
       oQryComprasDet, oQryCue, oQryPro, oQryArt,  oQryIva, oQryTip, oQryRet, oQryCom, oBot, base, baseDet,;
       oQry2,oQry3,oQry4,oQry5,oQry6,oQry7,cNumRe1,cNumRe2,lActualizar,oQryPun,nCodPro,nimporte
PROCEDURE CambioPre(cPermisos) 
LOCAL oBar, hHand,cDialog,oBot:=ARRAY(6),oFontTotal, lRta := .f., aTipoDoc, nTipoComp, nBultos:=0,;
      cNomPro,  cCuit, cConIva, cNomCue, nDeuda, nCodArt, cDetArt, nCantidad, oError, ;
      nPunit, nPTotal, cNomRet1, cNomRet2, cNomRet3, cNomRet4, cNomRet5, oDlg1, oQryDoc,nRenglon,;
      nSaldoIni:=0, nImporteIni:=0,i
  //TABLA TEMPORAL PARA EL DETALLE DE LA COMPRA
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS proped_temp ";
    +"("; 
    +"`RENGLON` INT(2) NOT NULL AUTO_INCREMENT,";
    +"`PROVEE` INT(8) NOT NULL,";
    +"`CODART` BIGINT(13) NOT NULL,";
    +"`DETART`  VARCHAR(50) ,";
    +"`SINIVA` TINYINT(1) DEFAULT '0',";
    +"`PRECOSSIVA` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`DESC1` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC2` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC3` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC4` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC5` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`IMPINT` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`FLETE` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`NETO` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`IVA` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PCOSTO` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PORCENTAJE` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PRECIOVEN` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PORCENTAJEREV` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`REVENTA` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`CODIVA` DECIMAL(2) DEFAULT '0',";
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")   
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE proped_temp")
  oApp:oServer:NextResult()
  oApp:oServer:Execute("INSERT INTO proped_temp (provee,codart,detart,siniva,precossiva,desc1,desc2,desc3,desc4,desc5,"+;
                                                "impint,flete,pcosto,iva,neto,porcentaje,precioven,codiva,porcentajerev,reventa) "+;
                        "(SELECT a.prov,a.codigo,a.nombre,a.siniva,a.precossiva,a.desc1,a.desc2,a.desc3,a.desc4,a.desc5,"+;
                                                "a.impint,a.flete,a.preciocos,IF(a.siniva,a.preciocos*(i.tasa/100),a.preciocos-a.preciocos/(i.tasa/100+1)),"+;
                                                "IF(a.siniva,a.preciocos,a.preciocos/(i.tasa/100+1)),a.porcentaje,"+;
                                                "a.precioven,a.iva,a.porcentajerev,a.reventa FROM ge_"+oApp:cId+"articu a "+;
                                                "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva )")       

        
 
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
  oQryComprasDet :=oApp:oServer:Query("SELECT * FROM proped_temp")
  DO WHILE .T.
    DEFINE DIALOG oDlg1 RESOURCE "PROCESAPED" OF oWnd1
    oDlg1:lHelpIcon := .f.
      

    //GRILLA ---------------------------------------------------------------      
    REDEFINE XBROWSE oBrw DATASOURCE oQryComprasDet;
       COLUMNS "CODART","DETART","siniva","precossiva","desc1","desc2","desc3","desc4","desc5",;
               "impint","flete","iva","neto","pcosto","porcentaje","precioven","porcentajerev","reventa";
       HEADERS "Codigo","Articulo","I.V.A","Costo s/iva","Dto 1","Dto 2","Dto 3","Dto 4","Dto 5",;
               "Imp.Int.","Flete","I.V.A","Neto","P.costo","Porcentaje 1","Precio venta 1","Porcentaje 2","Precio venta 2";
       FOOTERS ;
       SIZES 85,300,70,70,60,60,60,50,50,55;
       ID 132 OF oDlg1 AUTOSORT
    PintaBrw(oBrw,0)
    oBrw:nfreeze:=2
    oBrw:nMoveType := 1
    oBrw:aCols[2]:SetOrder()

    oBrw:aCols[3]:bStrData := {|| IF(oQryComprasDet:RecCount()>0,IF(oQryComprasDet:siniva,"Sin IVA","IVA incluido"),"")}
    oBrw:aCols[12]:Hide()
    oBrw:aCols[13]:Hide()
    oBrw:aCols[4]:lAutoSave := .t.
    oBrw:aCols[4]:nEditType := EDIT_GET  
    oBrw:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(4,xval)}
    oBrw:aCols[5]:lAutoSave := .t.
    oBrw:aCols[5]:nEditType := EDIT_GET  
    oBrw:aCols[5]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(5,xval)}
    oBrw:aCols[6]:lAutoSave := .t.
    oBrw:aCols[6]:nEditType := EDIT_GET  
    oBrw:aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(6,xval)}
    oBrw:aCols[7]:lAutoSave := .t.
    oBrw:aCols[7]:nEditType := EDIT_GET  
    oBrw:aCols[7]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(7,xval)}
    oBrw:aCols[8]:lAutoSave := .t.
    oBrw:aCols[8]:nEditType := EDIT_GET  
    oBrw:aCols[8]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(8,xval)}
    oBrw:aCols[9]:lAutoSave := .t.
    oBrw:aCols[9]:nEditType := EDIT_GET  
    oBrw:aCols[9]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(9,xval)}
    oBrw:aCols[10]:lAutoSave := .t.
    oBrw:aCols[10]:nEditType := EDIT_GET  
    oBrw:aCols[10]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(10,xval)}
    oBrw:aCols[11]:lAutoSave := .t.
    oBrw:aCols[11]:nEditType := EDIT_GET  
    oBrw:aCols[11]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(11,xval)}
    oBrw:aCols[14]:lAutoSave := .t.
    oBrw:aCols[14]:nEditType := EDIT_GET  
    oBrw:aCols[14]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(14,xval)}
    oBrw:aCols[15]:lAutoSave := .t.
    oBrw:aCols[15]:nEditType := EDIT_GET  
    oBrw:aCols[15]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(15,xval)} 
    oBrw:aCols[16]:lAutoSave := .t.
    oBrw:aCols[16]:nEditType := EDIT_GET  
    oBrw:aCols[16]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(16,xval)} 
    oBrw:aCols[17]:lAutoSave := .t.
    oBrw:aCols[17]:nEditType := EDIT_GET  
    oBrw:aCols[17]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(17,xval)} 
    oBrw:aCols[18]:lAutoSave := .t.
    oBrw:aCols[18]:nEditType := EDIT_GET  
    oBrw:aCols[18]:bOnPostEdit := {|oCol, xVal, nKey | CambiaValor(18,xval)} 
    oQryComprasDet:bOnChangePage := {|| oBrw:Refresh() }

   
        
    //BOTONES ---------------------------------------------------------------
    REDEFINE BUTTON oBot[2] ID 4002 ACTION (lRta:=.t.,oDlg1:End()) 
    REDEFINE BUTTON oBot[4] ID 4004 ACTION (Filtrar(),oBrw:SetFocus())
    REDEFINE BUTTON oBot[5] ID 4006 ACTION (lRta:=.f.,oDlg1:End()) CANCEL 
    REDEFINE BUTTON oBot[4] ID 4001 ACTION (lRta:=.f.,oDlg1:End(), PREGEN()) CANCEL 
    REDEFINE BUTTON oBot[6] ID 4003 ACTION (lRta:=.f.,oDlg1:End(), PREGENLIS()) CANCEL 
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg1 CENTER ON INIT Inicializar()
IF !lRta
   RETURN 
ENDIF

TRY
  oApp:oServer:BeginTransaction()   
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod) "+;
                       "(SELECT a.codigo,p.pcosto,p.precossiva,p.precioven,p.reventa,CURDATE() "+;
                       "FROM ge_"+oApp:cId+"articu a INNER JOIN proped_temp p ON p.codart = a.codigo "+;
                       "WHERE a.preciocos <> p.pcosto OR a.precioven <> p.precioven OR a.reventa <> p.reventa)") 
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a INNER JOIN proped_temp p ON p.codart = a.codigo "+;
                       "SET a.precossiva=p.precossiva,"+;
                            "a.desc1=p.desc1,a.desc2=p.desc2,a.desc3=p.desc3,a.desc4=p.desc4,a.desc5=p.desc5,"+;
                            "a.impint=p.impint,"+;
                            "a.flete=p.flete,"+;
                            "a.preciocos=p.pcosto,"+;
                            "a.porcentaje=p.porcentaje,"+;
                            "a.precioven=p.precioven, "+;
                            "a.porcentajerev=p.porcentajerev,"+;
                            "a.reventa=p.reventa,"+;
                            "a.fecmod=IF(a.precossiva<>p.precossiva OR a.preciocos<>p.pcosto OR a.precioven<>p.precioven OR a.reventa<>p.reventa,"+;
                            "CURDATE(),a.fecmod)")
  oApp:oServer:CommitTransaction()
CATCH oError
    MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO

RETURN 

**************************************************************************************************************
****** FILTRAR ARTICULOS
STATIC FUNCTION Filtrar()
LOCAL mrta:=.f.,oDlg1,oGet:=ARRAY(7),oBot1,oBot2,vEmpresa:=0,cNomEmp:=SPACE(30),;
      vMarca:=0,cNomMar:=SPACE(30),oQryMar,oQryEmp,cWhere,acor:=ARRAY(4),oError,;
      dDesde:=CTOD("  /  /    "),dHasta:=DATE(),cNombre:=SPACE(50)
oQryMar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"marcas")
oQryEmp:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"empresas")

DEFINE DIALOG oDlg1 TITLE "Filtrar articulos" FROM 05,10 TO 17,70 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Empresa:"       OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Marca:"         OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 say "Fecha compra:"  OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 55 say "A"              OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Nombre:"		 OF oDlg1 PIXEL SIZE 40,12 RIGHT

   @ 05, 50 GET oGet[1] VAR vEmpresa    OF oDlg1 PIXEL SIZE 25,12 RIGHT PICTURE "999";
                         VALID(vEmpresa = 0 .or. Buscar(oQryEmp,oDlg1,oGet[1],oGet[2]));
                         ACTION (oGet[1]:cText:= 0, Buscar(oQryEmp,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1"  
   @ 05, 80 GET oGet[2] VAR cNomEmp   OF oDlg1 PIXEL PICTURE "@!" WHEN(.F.)

   @ 20, 50 GET oGet[3] VAR vMarca    OF oDlg1 PIXEL SIZE 25,12 RIGHT PICTURE "999";
                         VALID(vMarca = 0.or. Buscar(oQryMar,oDlg1,oGet[3],oGet[4]));
                         ACTION (oGet[3]:cText:= 0, Buscar(oQryMar,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1"  
   @ 20, 80 GET oGet[4] VAR cNomMar   OF oDlg1 PIXEL PICTURE "@!" WHEN(.F.)
   @ 35, 50 GET oGet[5] VAR dDesde    OF oDlg1 PIXEL PICTURE "@D" CENTER
   @ 35,100 GET oGet[6] VAR dHasta    OF oDlg1 PIXEL PICTURE "@D" CENTER  
   @ 50, 50 GET oGet[7] VAR cNombre   OF oDlg1 PIXEL PICTURE "@!"

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

TRY
  oApp:oServer:BeginTransaction()  
    oApp:oServer:Execute("TRUNCATE proped_temp")
    oApp:oServer:Execute("INSERT INTO proped_temp (provee,codart,detart,siniva,precossiva,desc1,desc2,desc3,desc4,desc5,"+;
                                                    "impint,flete,pcosto,iva,neto,porcentaje,precioven,codiva,porcentajerev,reventa) "+;
                            "(SELECT a.prov,a.codigo,a.nombre,a.siniva,a.precossiva,a.desc1,a.desc2,a.desc3,a.desc4,a.desc5,"+;
                                                    "a.impint,a.flete,a.preciocos,IF(a.siniva,a.preciocos*(i.tasa/100),a.preciocos-a.preciocos/(i.tasa/100+1)),"+;
                                                    "IF(a.siniva,a.preciocos,a.preciocos/(i.tasa/100+1)),a.porcentaje,"+;
                                                    "a.precioven,a.iva,a.porcentajerev,a.reventa FROM ge_"+oApp:cId+"articu a "+;
                                                    "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva "+;
                                                    "WHERE "+ IF(EMPTY(vempresa),"1=1"," a.empresa = " + ClipValue2SQL(vempresa) + "")+" AND ";
                                                            + IF(EMPTY(vMarca),"1=1"," a.marca =" + ClipValue2SQL(vMarca) + "") +" AND "+;
                                                            + IF(EMPTY(ALLTRIM(cNombre)),"1=1"," a.nombre LIKE '%" + ALLTRIM(cNombre) + "%'") +" AND "+;
                                                            + IF(DTOC(dDesde)<>"  /  /    ","a.codigo IN (SELECT cd.codart FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"compradet cd ON CONCAT(cd.tipocomp,cd.letra,cd.numfac) = CONCAT(c.tipocomp,c.letra,c.numfac) "+;
                                                                         "WHERE c.fecfac >= "+ClipValue2Sql(dDesde)+" AND c.fecfac <= "+ClipValue2Sql(dHasta)+")","1=1")+;
                                                             ")") 
oApp:oServer:CommitTransaction()
CATCH oError
    MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oQryComprasDet:Refresh()
oBrw:Refresh()
RETURN nil

***************************************************************************************************************
****** CAMBIA PROVEEDOR EN EL BROWSE 
STATIC FUNCTION ValidaProv(oGet,oCol,oDlg1)
LOCAL oQryProv

oQryProv:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"provee WHERE codigo = " +ClipValue2Sql(oGet:value))
IF oQryProv:RecCount() = 0
  Buscar(oQryProv,oGet, oGet)
ENDIF
RETURN .t.


***************************************************************************************************************
***** RECALCULAR LOS VALORES DEL BROWSE CUANDO SE ABRE LA VENTANA 
STATIC FUNCTION Inicializar()/*
oQryComprasDet:GoTop()
DO WHILE !oQryComprasDet:EOF()
  CambiaValor()
  oQryComprasDet:Skip()
ENDDO
oQryComprasDet:GoTop()
oBrw:Refresh()*/
RETURN nil 

***************************************************************************************************************
***** CAMBIA LOS VALORES DEL BROWSE 
STATIC FUNCTION CambiaValor(n,xVal)
LOCAL nNeto,nNeto2,nTasa,nImpInt,nFlete,nIVA,nNetoPar
DEFAULT n := 1, xVal:=0
IF n<>1
  oQryComprasDet:fieldput( n+2, xVal )
  oQryComprasDet:Save()
  oQryComprasDet:Refresh()
ENDIF
nTasa:= oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(oQryComprasDet:codiva)):tasa

IF n = 14
    nNeto:= oQryComprasDet:pcosto/;
               (1+(nTasa/100)+(oQryComprasDet:flete/100)+(oQryComprasDet:impint/100))
    nNeto:= nNeto * IF(oQryComprasDet:desc5>0,(100/oQryComprasDet:desc5),1) 
    nNeto:= nNeto * IF(oQryComprasDet:desc4>0,(100/oQryComprasDet:desc4),1) 
    nNeto:= nNeto * IF(oQryComprasDet:desc3>0,(100/oQryComprasDet:desc3),1) 
    nNeto:= nNeto * IF(oQryComprasDet:desc2>0,(100/oQryComprasDet:desc2),1) 
    nNeto:= nNeto * IF(oQryComprasDet:desc1>0,(100/oQryComprasDet:desc1),1) 
    nIVA :=   nNeto * (nTasa/100) 

    oQryComprasDet:precossiva:= nNeto + IF(oQryComprasDet:siniva,0,nIVA) 
ENDIF  
IF n <> 14 .and. n <> 16 .and. n <> 15 .and. n <> 17 .and. n <> 18
    nNeto:= IF(oQryComprasDet:siniva,oQryComprasDet:precossiva,oQryComprasDet:precossiva/(1+nTasa/100))
    nNeto:= nNeto - nNeto * (oQryComprasDet:desc1/100) 
    nNeto:= nNeto - nNeto * (oQryComprasDet:desc2/100) 
    nNeto:= nNeto - nNeto * (oQryComprasDet:desc3/100) 
    nNeto:= nNeto - nNeto * (oQryComprasDet:desc4/100) 
    nNeto:= nNeto - nNeto * (oQryComprasDet:desc5/100) 
    nImpInt:= nNeto * (oQryComprasDet:impint/100)
    nFlete:= nNeto * (oQryComprasDet:flete/100) 
    nIVA:= nNeto * nTasa/100
    nNeto:= nNeto + nImpInt + nFlete + nIVA
    oQryComprasDet:pcosto:= nNeto
ENDIF  
IF n = 16
    oQryComprasDet:porcentaje:= (oQryComprasDet:precioven * 100) / oQryComprasDet:pcosto -100
ENDIF  
IF n <> 16
    oQryComprasDet:precioven:= INT(oQryComprasDet:pcosto + oQryComprasDet:pcosto * (oQryComprasDet:porcentaje/100))
ENDIF
IF n = 18
    oQryComprasDet:porcentajerev:= (oQryComprasDet:reventa * 100) / oQryComprasDet:pcosto -100
ENDIF  
IF n <> 18
    oQryComprasDet:reventa:= INT(oQryComprasDet:pcosto + oQryComprasDet:pcosto * (oQryComprasDet:porcentajerev/100))
ENDIF

oQryComprasDet:iva:= IF(oQryComprasDet:siniva,oQryComprasDet:precossiva*(nTasa/100),oQryComprasDet:precossiva-oQryComprasDet:precossiva/(nTasa/100+1))
oQryComprasDet:neto:= IF(oQryComprasDet:siniva,oQryComprasDet:precossiva,oQryComprasDet:precossiva/(1+nTasa/100))
oQryComprasDet:Save()
oQryComprasDet:Refresh()
ActualizarGrupo(oQryComprasDet)
oQryComprasDet:Refresh()
oBrw:Refresh()
RETURN nil

*************************************************************************************************************
********** ACTUALIZA EL PRECIO DE LOS ARTICULOS QUE SE ENCUENTRAN EN EL MISMO GRUPO QUE EL MODIFICADO
STATIC FUNCTION ActualizarGrupo(base)
LOCAL nGrupo:= oApp:oServer:Query("SELECT codgru FROM ge_"+oApp:cId+"gruposdet WHERE codart = "+ClipValue2Sql(base:codart)):codgru

oApp:oServer:Execute("UPDATE proped_temp SET precossiva = "+ClipValue2Sql(base:precossiva)+","+;
                                       "desc1      = "+ClipValue2Sql(base:desc1)+","+;
                                       "desc2      = "+ClipValue2Sql(base:desc2)+","+;
                                       "desc3      = "+ClipValue2Sql(base:desc3)+","+;
                                       "desc4      = "+ClipValue2Sql(base:desc4)+","+;
                                       "desc5      = "+ClipValue2Sql(base:desc5)+","+;
                                       "impint     = "+ClipValue2Sql(base:impint)+","+;
                                       "flete      = "+ClipValue2Sql(base:flete)+","+;
                                       "iva        = "+ClipValue2Sql(base:iva)+","+;
                                       "pcosto     = "+ClipValue2Sql(base:pcosto)+","+;
                                       "porcentaje = "+ClipValue2Sql(base:porcentaje)+","+;
                                       "precioven  = "+ClipValue2Sql(base:precioven)+","+;
                                       "porcentajerev = "+ClipValue2Sql(base:porcentajerev)+","+;
                                       "reventa    = "+ClipValue2Sql(base:reventa)+","+;
                                       "siniva     = "+ClipValue2Sql(base:siniva)+" "+;
                     "WHERE codart IN (SELECT codart FROM ge_"+oApp:cId+"gruposdet WHERE codgru = "+ClipValue2Sql(nGrupo)+")")
RETURN nil


**************************************
STATIC FUNCTION CambiaChek(oQry1,oBrw1)
LOCAL valor
valor := IF(oQry1:CAMBIAPRE=.f.,.t.,.f.)
oQry1:CAMBIAPRE := valor
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil



*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaCant(nCantidad,nFaltantes,nPCosto,nProvee)
LOCAL base := oQryComprasDet:GetRowObj(),nPrecio2,nDescuento,nPrecio1,nIvaPes,nSubTotal,nTotalcIva,oQryIva,nCodIva1,nIvaCalc
DEFAULT nFaltantes := base:faltantes, nPCosto := base:pcosto, nCantidad := base:cantidad, nProvee:= base:provee
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(base:codiva))
nCodIva1 := base:codiva
nPrecio2:= nPCosto * (nCantidad-nFaltantes)
nIvaPes := nPrecio2 * oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(base:codiva)):tasa/100

base:cantidad  := nCantidad 
base:faltantes := nFaltantes
base:pcosto    := nPCosto 
base:disponibles:= nCantidad-nFaltantes
base:neto:=nPrecio2
base:iva:=nIvaPes
base:ptotal:=base:neto+base:iva
IF oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"provee WHERE codigo = "+ClipValue2Sql(nProvee)):RecCount() = 0
   MsgStop("Codigo de proveedor no existe","Atencion")
   RETURN nil 
ENDIF
base:provee:= nProvee
oQryComprasDet:lAppend:=.f.
oQryComprasDet:oRow := base
oQryComprasDet:Save()
oQryComprasDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()

RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
LOCAL aNueva := {}, i, j
IF oQry<> nil
   oQry:End()
   RELEASE oQry
ENDIF
oQryBrw:End()
RELEASE oQryBrw
oQryIva:End()
RELEASE oQryIva
oQryCue:End()
RELEASE oQryCue

j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.