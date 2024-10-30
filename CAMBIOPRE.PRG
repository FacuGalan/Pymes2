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
LOCAL oBar, hHand,cDialog,oBot:=ARRAY(7),oFontTotal, lRta := .f., aTipoDoc, nTipoComp, nBultos:=0,;
      cNomPro,  cCuit, cConIva, cNomCue, nDeuda, nCodArt, cDetArt, nCantidad, oError, ;
      nPunit, nPTotal, cNomRet1, cNomRet2, cNomRet3, cNomRet4, cNomRet5, oDlg1, oQryDoc,nRenglon,;
      nSaldoIni:=0, nImporteIni:=0,i
  //TABLA TEMPORAL PARA EL DETALLE DE LA COMPRA
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS proped_temp ";
    +"("; 
    +"`RENGLON` INT(2) NOT NULL AUTO_INCREMENT,";
    +"`PROVEE` INT(8) NOT NULL,";
    +"`CODART` BIGINT(14) NOT NULL,";
    +"`DETART`  VARCHAR(150) ,";
    +"`SINIVA` TINYINT(1) DEFAULT '0',";
    +"`PRECOSSIVA` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`DESC1` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC2` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC3` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC4` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`DESC5` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`IMPINT` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`FLETE` DECIMAL(5,2) NOT NULL DEFAULT '0.00',";
    +"`NETO` DECIMAL(12,2) NOT NULL DEFAULT '0.00',";
    +"`IVA` DECIMAL(12,2) NOT NULL DEFAULT '0.00',";
    +"`PCOSTO` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PORCENTAJE` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`PRECIOVEN` DECIMAL(12,2) NOT NULL DEFAULT '0.00',";
    +"`PORCENTAJEREV` DECIMAL(10,2) NOT NULL DEFAULT '0.00',";
    +"`REVENTA` DECIMAL(12,2) NOT NULL DEFAULT '0.00',";
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
    REDEFINE BUTTON oBot[7] ID 4005 ACTION ( PorReceta()) CANCEL 
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg1 CENTER ON INIT Inicializar()
IF !lRta
   RETURN 
ENDIF
IF !MsgNoYes("Está a punto de cambiar los precios de todo el grupo"+CHR(10)+;
            "de articulos que está visualizando."+chr(10)+;
            "Realmente desea confirmar el proceso?","Atencion")
   LOOP
ENDIF   
TRY
  oApp:oServer:BeginTransaction()   
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                       "(SELECT a.codigo,p.pcosto,p.precossiva,p.precioven,p.reventa,CURDATE(),"+ClipValue2Sql(oApp:usuario)+",'Cambio General Puntual' "+;
                       "FROM ge_"+oApp:cId+"articu a INNER JOIN proped_temp p ON p.codart = a.codigo "+;
                       "WHERE (a.preciocos <> p.pcosto OR a.precioven <> p.precioven OR a.reventa <> p.reventa) AND p.codart IS NOT NULL ) ") 
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
                            "CURDATE(),a.fecmod),"+;
                            "a.horamod=IF(a.precossiva<>p.precossiva OR a.preciocos<>p.pcosto OR a.precioven<>p.precioven OR a.reventa<>p.reventa,"+;
                            "CURTIME(),a.horamod)")
  oApp:oServer:CommitTransaction()
CATCH oError
    MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO

RETURN 

***************************************************************************************************
STATIC FUNCTION PorReceta()
LOCAL i := 0
Procesando(.t.)
   oApp:oServer:Execute("TRUNCATE proped_temp")
   oApp:oServer:Execute("INSERT INTO proped_temp (provee,codart,detart,siniva,precossiva,desc1,desc2,desc3,desc4,desc5,"+;
                                                    "impint,flete,pcosto,iva,neto,porcentaje,precioven,codiva,porcentajerev,reventa)  "+;
                        "(SELECT a.prov,a.codigo,a.nombre,a.siniva,(res.costo/a.cantprod),a.desc1,a.desc2,a.desc3,a.desc4,a.desc5,"+;
                                                    "a.impint,a.flete,a.preciocos,IF(a.siniva,a.preciocos*(i.tasa/100),a.preciocos-a.preciocos/(i.tasa/100+1)),"+;
                                                    "IF(a.siniva,a.preciocos,a.preciocos/(i.tasa/100+1)),a.porcentaje,"+;
                                                    "a.precioven,a.iva,a.porcentajerev,a.reventa "+;
                        "FROM ge_"+oApp:cId+"articu a "+;
                        "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva "+;
                        "LEFT JOIN (SELECT r.codart,SUM(r.cantidad*a1.preciocos) AS costo FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a1 ON a1.codigo = r.codusa AND a1.mprima = TRUE GROUP BY r.codart) res "+;
                        "ON res.codart = a.codigo "+;
                        "WHERE a.produccion = TRUE AND res.costo IS NOT NULL)") 
   oApp:oServer:Execute("INSERT INTO proped_temp (provee,codart,detart,siniva,precossiva,desc1,desc2,desc3,desc4,desc5,"+;
                                                    "impint,flete,pcosto,iva,neto,porcentaje,precioven,codiva,porcentajerev,reventa)  "+;
                        "(SELECT a.prov,a.codigo,a.nombre,a.siniva,(res.costo/1),a.desc1,a.desc2,a.desc3,a.desc4,a.desc5,"+;
                                                    "a.impint,a.flete,a.preciocos,IF(a.siniva,a.preciocos*(i.tasa/100),a.preciocos-a.preciocos/(i.tasa/100+1)),"+;
                                                    "IF(a.siniva,a.preciocos,a.preciocos/(i.tasa/100+1)),a.porcentaje,"+;
                                                    "a.precioven,a.iva,a.porcentajerev,a.reventa "+;
                        "FROM ge_"+oApp:cId+"articu a "+;
                        "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva "+;
                        "LEFT JOIN (SELECT r.codart,SUM(r.cantidad*a1.preciocos) AS costo FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a1 ON a1.codigo = r.codusa GROUP BY r.codart) res "+;
                        "ON res.codart = a.codigo "+;
                        "WHERE a.stockotro = TRUE AND res.costo IS NOT NULL)") 
oQryComprasDet:Refresh()
oQryComprasDet:GoTop()
DO WHILE !oQryComprasDet:EOF()
    CambiaValor(4,oQryComprasDet:precossiva)
    oQryComprasDet:Skip()
ENDDO
oBrw:Refresh()
Procesando(.f.)
RETURN nil

**************************************************************************************************************
****** FILTRAR ARTICULOS
STATIC FUNCTION Filtrar()
   
LOCAL vMarca,cMarc:=SPACE(30),vRubro,cRub:=SPACE(30),vempresa,cEmp:=SPACE(30),;
      vdepto,cDept:=SPACE(30),vProv,cProve:=SPACE(30),vcodigo,cNomArt:=SPACE(30),vnosale:=.f.,;
      vnombre:=SPACE(30),vnomregi:=SPACE(30),vstockmin,vstockact,vstockide,;
      vpreciocos,viva,cNomIva:=SPACE(30),vdesc1,vdesc2,vdesc3,vdesc4,vdesc5,;
      vprecioven,vpresugeri,vprecossiva,vpreciopro,vporcentaje,vfecmodd:="  /  /    ",vfecmodh:="  /  /    ",;
      vfecultcomd:="  /  /    ",vfecultcomh:="  /  /    ",oSay1,oSay2,;
      vneto,vimpint,vflete,vunimed,vobserva,cIvaNom:=SPACE(30),;
      oFilt, acor:=ARRAY(4), oBot:=ARRAY(2), lRta:=.f., oGet:=ARRAY(50),;
      vpesable:=.f.,vcombustible:=.f.,vmprima:=.f.,vproduccion:=.f.,;
      vmedida,ventero,vuxbulto,vpxbulto,vsiniva:=.f., cWhere, oError,;
      oQry2, oQry3, oQry4, oQry5, oQry6, oQry7

   oQry2  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")

DO WHILE .T.          
  DEFINE DIALOG oFilt TITLE "Seleccion de articulos" RESOURCE "ABMART1" OF oDlg 
  oFilt:lHelpIcon := .f.
  REDEFINE GET oGet[01] VAR vcodigo ID 100 OF oFilt/* PICTURE "99999999999999" ;
               VALID(EMPTY(oGet[01]:cText) .or. Buscar(oQryArt,oFilt,oGet[01],oGet[02]));
              ACTION (oGet[01]:cText:= 0, Buscar(oQryArt,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"*/
  REDEFINE GET oGet[02] VAR vnombre PICTURE "@!" ID 101 OF oFilt 
  REDEFINE GET oGet[03] VAR vnomregi ID 102 OF oFilt 
  REDEFINE CHECKBOX oGet[34] VAR vnosale ID 103 
  REDEFINE CHECKBOX oGet[46] VAR vpesable ID 4011 OF oFilt 
  *REDEFINE CHECKBOX oGet[43] VAR vcombustible ID 4005 OF oFilt
  *REDEFINE CHECKBOX oGet[44] VAR vmprima      ID 4007 OF oFilt
  *REDEFINE CHECKBOX oGet[45] VAR vproduccion  ID 4008 OF oFilt

  REDEFINE GET oGet[04] VAR vprov ID 104 OF oFilt ;
               VALID(EMPTY(oGet[04]:cText) .or. Buscar(oQry2,oFilt,oGet[04],oGet[05]));
               ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oFilt,oGet[04],oGet[05])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[21] VAR vmarca ID 122 OF oFilt ;
               VALID(EMPTY(oGet[21]:cText) .or. Buscar(oQry4,oFilt,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oFilt,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc      ID 123 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[23] VAR vrubro ID 124 OF oFilt ;
               VALID(EMPTY(oGet[23]:cText) .or. Buscar(oQry5,oFilt,oGet[23],oGet[24]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oFilt,oGet[23],oGet[24])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub ID 125 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[27] VAR vempresa ID 126 OF oFilt ;
               VALID(EMPTY(oGet[27]:cText) .or. Buscar(oQry7,oFilt,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oFilt,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp ID 127 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[25] VAR vdepto ID 128 OF oFilt ;
               VALID(EMPTY(oGet[25]:cText) .or. Buscar(oQry6,oFilt,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oFilt,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept ID 129 OF oFilt WHEN (.F.)

  
  REDEFINE GET oGet[35] VAR vunimed     ID 135 OF oFilt PICTURE "@!"
  REDEFINE GET oGet[47] VAR vmedida     ID 500 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[48] VAR ventero     ID 501 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[49] VAR vuxbulto    ID 502 OF oFilt PICTURE "99999"
  REDEFINE GET oGet[50] VAR vpxbulto    ID 503 OF oFilt PICTURE "99999999.99"


  REDEFINE CHECKBOX oGet[46] VAR vsiniva  ID 4003 OF oFilt
  REDEFINE GET oGet[06] VAR vprecossiva ID 106 OF oFilt 
  REDEFINE GET oGet[07] VAR vdesc1      ID 107 OF oFilt 
  REDEFINE GET oGet[08] VAR vdesc2      ID 108 OF oFilt 
  REDEFINE GET oGet[09] VAR vdesc3      ID 109 OF oFilt 
  REDEFINE GET oGet[10] VAR vdesc4      ID 110 OF oFilt 
  REDEFINE GET oGet[11] VAR vdesc5      ID 111 OF oFilt 
  REDEFINE GET oGet[39] VAR vNeto ID 112 OF oFilt 
  REDEFINE GET oGet[12] VAR vimpint ID 113 OF oFilt 
  REDEFINE GET oGet[13] VAR vflete ID 114 OF oFilt 
  REDEFINE GET oGet[14] VAR viva ID 115 OF oFilt ;
              VALID(EMPTY(oGet[14]:cText) .or. (Buscar(oQry3,oFilt,oGet[14],oGet[15]) .and. ;             
               ((oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx"))  );
               ACTION (oGet[14]:cText:= 0, Buscar(oQry3,oFilt,oGet[14],oGet[15]),;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx" ) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom ID 116 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[16] VAR vpreciocos ID 117 OF oFilt 
  REDEFINE GET oGet[17] VAR vporcentaje ID 118 OF oFilt 
  REDEFINE GET oGet[18] VAR vpreciopro ID 119 OF oFilt 
  REDEFINE GET oGet[19] VAR vpresugeri ID 120 OF oFilt 
  REDEFINE GET oGet[20] VAR vprecioven ID 121 OF oFilt 
  

  //FECHAS
  REDEFINE GET oGet[41] VAR vfecultcomd ID 1300 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay1 PROMPT "Hasta ultima compra:" ID 802 OF oFilt
  REDEFINE GET oGet[29] VAR vfecultcomh ID 130 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay2 PROMPT "Desde cambio precio:" ID 803 OF oFilt
  REDEFINE GET oGet[30] VAR vfecmodd    ID 131 OF oFilt PICTURE "@D"
  REDEFINE GET oGet[42] VAR vfecmodh    ID 1311 OF oFilt PICTURE "@D"

  REDEFINE GET oGet[31] VAR vstockmin ID 132 OF oFilt
  REDEFINE GET oGet[32] VAR vstockact ID 133 OF oFilt
  REDEFINE GET oGet[33] VAR vstockide ID 134 OF oFilt
  REDEFINE GET oGet[36] VAR vobserva  ID 136 OF oFilt

  REDEFINE BUTTON oBot[1] ID 137 OF oFilt;
           ACTION ((lRta := .t.), oFilt:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oFilt;
           ACTION ((lRta := .f.), oFilt:End() ) CANCEL
 
ACTIVATE DIALOG oFilt CENTER ON INIT (oGet[01]:SetFocus(),oGet[34]:Hide())

IF !lRta
   RETURN .f.
ENDIF

cWhere = " 1=1 " + IF(EMPTY(vCodigo),""," and a.CODIGO =" + ClipValue2SQL(VCodigo) + "") ;
            + "" + IF(EMPTY(VNOMBRE),"","  and TRIM(a.NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
            + "" + IF(EMPTY(Vnomregi),"","  and TRIM(a.nomregi) like '%" + ALLTRIM(Vnomregi) + "%'") ;
            + "" + IF(!vnosale,""," and a.nosale = TRUE ");
            + "" + IF(!vpesable,""," and a.pesable = TRUE ");
            + "" + IF(!vcombustible,""," and a.combustible = TRUE");
            + "" + IF(!vmprima,""," and a.mprima = TRUE ");
            + "" + IF(!vproduccion,""," and a.produccion = TRUE ");
            + "" + IF(!vsiniva,""," and a.siniva = TRUE ");
            + "" + IF(EMPTY(vProv),""," and a.prov =" + ClipValue2SQL(vProv) + "") ;
            + "" + IF(EMPTY(vMarca),""," and a.marca =" + ClipValue2SQL(vMarca) + "") ;
            + "" + IF(EMPTY(vRubro),""," and a.rubro =" + ClipValue2SQL(vRubro) + "") ;
            + "" + IF(EMPTY(vempresa),""," and a.empresa =" + ClipValue2SQL(vempresa) + "") ;
            + "" + IF(EMPTY(vdepto),""," and a.depto =" + ClipValue2SQL(vdepto) + "") ;
            + "" + IF(EMPTY(vStockmin),""," and a.stockmin =" + ClipValue2SQL(vstockmin) + "") ; 
            + "" + IF(EMPTY(vmedida),""," and a.medida =" + ClipValue2SQL(vmedida) + "") ;
            + "" + IF(EMPTY(ventero),""," and a.entero =" + ClipValue2SQL(ventero) + "") ;
            + "" + IF(EMPTY(vuxbulto),""," and a.uxbulto =" + ClipValue2SQL(vuxbulto) + "") ;
            + "" + IF(EMPTY(vpxbulto),""," and a.pxbulto =" + ClipValue2SQL(vpxbulto) + "") ;
            + "" + IF(EMPTY(vStockact),""," and a.stockact =" + ClipValue2SQL(vstockact) + "") ;
            + "" + IF(EMPTY(vstockide),""," and a.stockide =" + ClipValue2SQL(vstockide) + "") ;
            + "" + IF(EMPTY(vunimed),"","  and TRIM(a.unimed) like '%" + ALLTRIM(vunimed) + "%'");
            + "" + IF(EMPTY(vpreciocos),""," and a.preciocos =" + ClipValue2SQL(vpreciocos) + "") ;
            + "" + IF(EMPTY(vporcentaje),""," and a.porcentaje =" + ClipValue2SQL(vporcentaje) + "") ;
            + "" + IF(EMPTY(vprecossiva),""," and a.precossiva =" + ClipValue2SQL(vprecossiva) + "") ;
            + "" + IF(EMPTY(vneto),""," and a.neto =" + ClipValue2SQL(vneto) + "") ;
            + "" + IF(EMPTY(vimpint),""," and a.impint =" + ClipValue2SQL(vimpint) + "") ;
            + "" + IF(EMPTY(vflete),""," and a.flete =" + ClipValue2SQL(vflete) + "") ;
            + "" + IF(EMPTY(viva),""," and a.iva =" + ClipValue2SQL(viva) + "") ;
            + "" + IF(EMPTY(vdesc1),""," and a.desc1 =" + ClipValue2SQL(vdesc1) + "") ;
            + "" + IF(EMPTY(vdesc2),""," and a.desc2 =" + ClipValue2SQL(vdesc2) + "") ;
            + "" + IF(EMPTY(vdesc3),""," and a.desc3 =" + ClipValue2SQL(vdesc3) + "") ;
            + "" + IF(EMPTY(vdesc4),""," and a.desc4 =" + ClipValue2SQL(vdesc4) + "") ;
            + "" + IF(EMPTY(vdesc5),""," and a.desc5 =" + ClipValue2SQL(vdesc5) + "") ;            
            + "" + IF(EMPTY(vprecioven),""," and a.precioven =" + ClipValue2SQL(vprecioven) + "") ;
            + "" + IF(EMPTY(vpreciopro),""," and a.preciopro =" + ClipValue2SQL(vpreciopro) + "") ; 
            + "" + IF(EMPTY(vpresugeri),""," and a.presugeri =" + ClipValue2SQL(vpresugeri) + "") ; 
            + "" + IF(vfecultcomd="  /  /    ",""," and a.fecultcom >=" + ClipValue2SQL(CTOD(vfecultcomd)) + "") ;
            + "" + IF(vfecultcomh="  /  /    ",""," and a.fecultcom <=" + ClipValue2SQL(CTOD(vfecultcomh)) + "") ;
            + "" + IF(vfecmodd="  /  /    ",""," and a.fecmod >=" + ClipValue2SQL(CTOD(vfecmodd)) + "") ;
            + "" + IF(vfecmodh="  /  /    ",""," and a.fecmod <=" + ClipValue2SQL(CTOD(vfecmodh)) + "") ;
            + "" + IF(EMPTY(vobserva),"","  and TRIM(a.observa) like '%" + ALLTRIM(vobserva) + "%'") ;
 
   EXIT
ENDDO 
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
                                                    "WHERE "+ cWhere+")") 
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