// Dialogs designer
#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


MEMVAR oApp
static oDlg,oDlg1, nMesa := 1,oFont,oFontBot,oBrwDet,oQryDet,oQryDep,oQryArt,oBot,oGet,nPagado,nVuelto,cNomArt,nDescu,lConsulta,oQryPag,nAntes,;
       nUltDep,nPriDep,nUltArt,nPriArt,fDepto,nCantidad,dFecha,nCliente,cCliente,nTotal,cVentana,lMaxi:=.t.,;
       nPrecio,lReemplaza,nCondicion,oQryPun,nDescuTot,nRecarTot,oQry2,oQry3,oQry5,nLista,oQryPar

//----------------------------------------------------------------//

PROCEDURE POS1()
LOCAL hHand
LOCAL i,oFont1,oFont2,oFont3,oFont4,nCodArt:=0,nNumMesa,oMesa,nPicture,nComen:=0
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0 
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS VENTAS_DET_H1 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(13) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(10,2) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(10,2) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(10,2) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(10,2) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(10,2) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`PTOTAL` DECIMAL(10,2) DEFAULT '0.00',";
    +"`PCOSTO`  DECIMAL(10,2) DEFAULT '0.00', ";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H1")

oQryDet:= oApp:oServer:Query("SELECT * FROM VENTAS_DET_H1")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS formapag_temp";
    +"("; 
    +"`RENGLON`   INT(2) NOT NULL  AUTO_INCREMENT ,";
    +"`TIPOPAG`   INT(1) NOT NULL ,";
    +"`FORMAPAG`  VARCHAR(30) NOT NULL,";
    +"`CODFORMA`  INT(2) NOT NULL,";
    +"`IMPORTE`  DECIMAL(10,2) NOT NULL,"+;
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")  
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE formapag_temp")
oApp:oServer:NextResult() 

oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
oQryPar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,precioven,reventa,stockact FROM ge_"+oApp:cId+"articu")
lReemplaza:=.t.
   DEFINE FONT oFont NAME "TIME NEW ROMAS" SIZE 15,30
   DEFINE FONT oFontBot NAME "TIME NEW ROMAS" SIZE -06,11 BOLD
   oBot:=ARRAY(70)
   oGet:=ARRAY(9)
   fDepto:=0
   dFecha:=DATE()
   nCliente:=1
   cCliente:=SPACE(30)
   cNomArt:=SPACE(30)
   nTotal:=0
   nPrecio:=0
   nPagado:=0
   nVuelto:=0
   nDescu:=0
   nDescuTot:=0
   nRecarTot:=0
   lConsulta:=.f.
   nLista:=1
 DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-11.5
 DEFINE FONT oFont2 NAME "ARIAL" SIZE 17,-25
 DEFINE FONT oFont3 NAME "ARIAL" SIZE 15,-20
 DEFINE FONT oFont4 NAME "ARIAL" SIZE 0,-11.5
nUltDep:=0
nPriDep:=0
nUltArt:=0
nPriArt:=0
nCantidad:=1
nCondicion:=5

DEFINE DIALOG oDlg1 RESOURCE "POS" OF oApp:oWnd TITLE "Facturacion punto de venta"
   oDlg1:lHelpIcon := .f.
  /* //BOTONES DE DEPARTAMENTOS CON SUS FLECHAS (ABAJO DEL BROWSE)
   REDEFINE BTNBMP oBot[01] ID 101 OF oDlg1  ACTION(CambiarDeptos(.t.)) 2007 CENTER
   REDEFINE BTNBMP oBot[02] ID 102 OF oDlg1 2007 CENTER  FONT oFont1;
            ACTION(nCodArt:= - oBot[02]:cargo, oGet[02]:Refresh(),;
                   oGet[07]:cText:= oBot[02]:cCaption,oGet[03]:SetFocus()) 
   REDEFINE BTNBMP oBot[03] ID 103 OF oDlg1 2007 CENTER  FONT oFont1;
            ACTION(nCodArt:= - oBot[03]:cargo, oGet[02]:Refresh(),;
            	   oGet[07]:cText:= oBot[03]:cCaption,oGet[03]:SetFocus())
   REDEFINE BTNBMP oBot[04] ID 105 OF oDlg1 2007 CENTER  FONT oFont1;
            ACTION(nCodArt:= - oBot[04]:cargo, oGet[02]:Refresh(),;
            	   oGet[07]:cText:= oBot[04]:cCaption,oGet[03]:SetFocus()) 
   REDEFINE BTNBMP oBot[05] ID 106 OF oDlg1 2007 CENTER  FONT oFont1;
            ACTION(nCodArt:= - oBot[05]:cargo, oGet[02]:Refresh(),;
            	   oGet[07]:cText:= oBot[05]:cCaption,oGet[03]:SetFocus()) 
   REDEFINE BTNBMP oBot[07] ID 107 OF oDlg1 ACTION(CambiarDeptos(.f.)) 2007 CENTER
   */
   //BOTONES DE OPCIONES (ABAJO)
   REDEFINE BTNBMP oBot[30] ID 301 OF oDlg1 2007 CENTER; //ALTA DE ARTICULO
                   PROMPT "&Alta rapida";
                   ACTION (AltaArt(),oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[31] ID 302 OF oDlg1 2007 CENTER; //DESCUENTOS
                   PROMPT "&Descuentos";
                   ACTION(CargaDescu(),oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[32] ID 303 OF oDlg1 2007 CENTER; //BORRA ITEM
                   PROMPT "&Borrar item";
                   ACTION(oQryDet:Delete(),oBrwDet:Refresh(),oGet[02]:SetFocus());
                   WHEN(oQryDet:RecCount()>0)
   REDEFINE BTNBMP oBot[33] ID 304 OF oDlg1 2007 CENTER; //SELECCIONA CLIENTE
                   PROMPT "&Elegi cliente";
                   ACTION(ElijeCliente(),oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[34] ID 305 OF oDlg1 2007 CENTER; //SALIR
                   PROMPT "&Salir";
                   ACTION(oDlg1:End())
   REDEFINE BTNBMP oBot[35] ID 306 OF oDlg1 2007 CENTER; //ELIJE FORMAS DE PAGO
                   PROMPT "&Formas de pago";
                   ACTION(ElijeFormPag(),oGet[02]:SetFocus());
                   WHEN(nTotal>0)
   REDEFINE BTNBMP oBot[36] ID 307 OF oDlg1 2007 CENTER; //CONSULTA
                   PROMPT "&Consulta";
   	      			   ACTION(lConsulta:=.t.,oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[37] ID 308 OF oDlg1 2007 CENTER; //CALCULADORA
                   PROMPT "&Calculadora";
   				         ACTION(WinExec("calc.exe"))
   REDEFINE BTNBMP oBot[38] ID 309 OF oDlg1 2007 CENTER; //ANULAR
                   PROMPT "&Anular";
                   ACTION(Reiniciar(),oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[39] ID 310 OF oDlg1 2007 CENTER; //GRABA
                   PROMPT "&Grabar";
                   ACTION(Grabar(),oGet[02]:SetFocus());
                   WHEN((ROUND(nPagado,2) >= ROUND(nTotal,2)) .and. nTotal > 0) 
  
   //BOTONES DE NUMEROS (DERECHA)
   REDEFINE BTNBMP oBot[40] ID 400 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[41] ID 401 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[42] ID 402 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[43] ID 403 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[44] ID 404 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[45] ID 405 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[46] ID 406 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[47] ID 407 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture)) 
   REDEFINE BTNBMP oBot[48] ID 408 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[49] ID 409 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[50] ID 410 OF oDlg1 2007 CENTER;
                   ACTION(oGet[01]:SetFocus())
   REDEFINE BTNBMP oBot[51] ID 411 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,0,nPicture),CargarNum(oDlg1:cargo,0,nPicture))
   REDEFINE BTNBMP oBot[53] ID 413 OF oDlg1 2007 CENTER;
                   ACTION(IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[2]:nTop+oGet[2]:nLeft .and. oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE "+;
                                                                   "codigo = "+ClipValue2Sql(nCodArt)):RecCount>0,;
                            (AgregarArticu(nCodArt),oGet[02]:SetFocus()),; //SI ESTA PARADO EN EL CODIGO DE ARTICULO Y EXISTE LO AGREGO AL DETALLE
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[3]:nTop+oGet[3]:nLeft .and. nCodArt < 0 .and.;
                             oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"deptos WHERE codigo = "+ClipValue2Sql(ABS(nCodArt))):RecCount>0 ,;
                            (AgregarArticu(nCodArt),oGet[02]:SetFocus()),oGet[02]:SetFocus())),; //SI ESTA PARADO EN EL PRECIO E INGRESO UN DEPTO LO AGREGO AL DETALLE
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[1]:nTop+oGet[1]:nLeft,oGet[2]:SetFocus(),nil))  //SI ESTA EN CANTIDAD VUELVE AL CODIGO DEL ARTICULO   
   REDEFINE BTNBMP oBot[54] ID 414 OF oDlg1 2007 CENTER;
                   ACTION(BorrarNum(oDlg1:cargo))
   REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
            COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","DESCUENTO","STOTAL","IVA","PTOTAL","CODIVA";
            HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Neto","Dto./Rec.","Sub Total","IVA","Total","Tasa";
            FOOTERS ;
            SIZES 40,243,65,64,55,55,55,64,55 ID 1000 OF oDlg1 
   PintaBrw(oBrwDet,0)
   oBrwDet:aCols[5]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[6]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[7]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[8]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[9]:nFooterTypE := AGGR_SUM
   oBrwDet:MakeTotals()
   oBrwDet:aCols[1]:Hide()
   FOR i:= 5 TO 8 
       oBrwDet:aCols[i]:Hide() 
   NEXT i  
   oBrwDet:aCols[10]:Hide()
   
   REDEFINE GET oGet[02] VAR nCodArt   ID 10 OF oDlg1 PICTURE "99999999999999" FONT oFont2;
                ACTION (oGet[02]:cText:= 0, BuscarArt(oQryArt,oDlg1,oGet[2],oGet[7]),;
                        oGet[01]:cText:=1,oGet[03]:cText:=IF(nLista=1,oQryArt:precioven,oQryArt:reventa)) BITMAP "BUSC"
   REDEFINE GET oGet[07] VAR cNomArt   ID 16 OF oDlg1 PICTURE "@!" FONT oFont3 ;
                WHEN(IF(nCodArt>0,(oGet[07]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(oGet[2]:cText)):nombre) = "xxxxx",.f.))
   REDEFINE GET oGet[01] VAR nCantidad ID 11 OF oDlg1 PICTURE "999" FONT oFont2 
   REDEFINE GET oGet[03] VAR nPrecio   ID 12 OF oDlg1 PICTURE "99999999.99" FONT oFont2;
                WHEN(oGet[02]:value <= 0 .or. ((oGet[03]:cText:= IF(nLista=1,oApp:oServer:Query("SELECT precioven FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(oGet[2]:cText);
                                                                                    ):precioven,;
                                                                             oApp:oServer:Query("SELECT reventa FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(oGet[2]:cText);
                                                                                    ):reventa)*nCantidad) <> "xxx")) 

   REDEFINE GET oGet[08] VAR nDescuTot ID 17 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[09] VAR nRecarTot ID 18 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[04] VAR nPagado   ID 13 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[05] VAR nVuelto   ID 14 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[06] VAR nTotal    ID 15 OF oDlg1 PICTURE "99999999.99" FONT oFont2 WHEN(CalcTot()) 

   oGet[01]:bGotFocus := {|| oDlg1:cargo := oGet[1],nPicture:=2,lReemplaza:=.t.}
   oGet[02]:bGotFocus := {|| oDlg1:cargo := oGet[2],nPicture:=13,lReemplaza:=.t.}
   oGet[03]:bGotFocus := {|| oDlg1:cargo := oGet[3],nPicture:=10,lReemplaza:=.t.}
   oGet[06]:bGotFocus := {|| oDlg1:cargo := oGet[6],nPicture:=11}

   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==106,oGet[1]:SetFocus(),;
                                       IF(nKey==112,oBot[2]:Click,;
                                       IF(nKey==113,oBot[3]:Click,;
                                       IF(nKey==114,oBot[4]:Click,;
                                       IF(nKey==115,oBot[5]:Click,.F.)))))}
   oGet[03]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[3]:assign(),AgregarArticu(nCodArt),oGet[02]:SetFocus()),.t.)}
   oGet[02]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[2]:assign(),AgregarArticu(nCodArt),oGet[02]:SetFocus()),.t.)}
   oGet[01]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[1]:assign(),oGet[02]:SetFocus()),.t.)}


oDlg1:cargo:= oGet[02]
ACTIVATE DIALOG oDlg1 CENTER;
         ON INIT (oGet[02]:SetFocus())
// CUANDO CIERRA LA FACTURACION CAMBIA LOS BITMAPS

RETURN
************************************************************************************************************************
***** DAR DE ALTA UN ARTICULO CON LOS DATOS ESENCIALES
STATIC FUNCTION AltaArt()
LOCAL oForm,oGet1:=ARRAY(40),oBot1:=ARRAY(2),base,oQry,cProve:=SPACE(30),;
      cIvaNom:=SPACE(30),cRub:=SPACE(30),lRta:=.f.,oError,oQryValida
oQryValida:= oApp:oServer:Query("SELECT permisos FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario = "+ClipValue2Sql(oApp:usuario)+" "+;
                                "AND modulo = 'ARTIC'")
IF !"A"$oQryValida:permisos
   MsgStop("El usuario no tiene permiso para dar de alta un articulo","Atencion!")
   RETURN nil 
ENDIF
oQry2  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
oQry3  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
oQry5  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu LIMIT 0")
base := oQry:GetBlankRow()
base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"articu")
base:iva :=5

DEFINE DIALOG oForm TITLE "Alta rapida de Articulos" RESOURCE "ALTART" OF oDlg1
 oForm:lHelpIcon := .f.
 
 REDEFINE GET oGet1[01] VAR base:codigo PICTURE "99999999999999" ID 100 OF oForm;
              VALID(TraeDatos(base:codigo,oGet1,@oQry,@base))
  REDEFINE GET oGet1[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet1[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!" 
  REDEFINE GET oGet1[06] VAR base:precossiva ID 106 OF oForm PICTURE "999999.99" 
  REDEFINE GET oGet1[04] VAR base:prov ID 104 OF oForm PICTURE "99999";
                VALID(Buscar(oQry2,oForm,oGet1[4],oGet1[5]));
                ACTION (oGet1[04]:cText:= 0, Buscar(oQry2,oForm,oGet1[4],oGet1[5])) BITMAP "BUSC1"
  REDEFINE GET oGet1[05] VAR cProve          ID 105 OF oForm WHEN (.F.)
 REDEFINE GET oGet1[23] VAR base:rubro      ID 124 OF oForm PICTURE "999";
               VALID(Buscar(oQry5,oForm,oGet1[23],oGet1[24]));
               ACTION (oGet1[23]:cText:= 0, Buscar(oQry5,oForm,oGet1[23],oGet1[24])) BITMAP "BUSC1"
  REDEFINE GET oGet1[24] VAR cRub            ID 125 OF oForm WHEN (.F.)
  REDEFINE GET oGet1[14] VAR base:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet1[14]) .and. ;             
               (oGet1[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet1[14]:cText:= 0, (Buscar(oQry3,oForm,oGet1[14]) .and. ;             
               (oGet1[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet1[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
 
  REDEFINE GET oGet1[20] VAR base:precioven  ID 121 OF oForm PICTURE "99999.99"
 
  REDEFINE GET oGet1[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"

  REDEFINE BUTTON oBot1[1] ID 137 OF oForm;
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot1[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet1[01]:SetFocus())

IF !lRta 
   RETURN nil
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  IF oQry:lAppend
  	 oQry:Save()
  ELSE 
  	 oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET nombre = "+ClipValue2Sql(base:nombre)+","+;
                                            "nomregi = "+ClipValue2Sql(base:nomregi)+","+;
                                             "precossiva = "+ClipValue2Sql(base:precossiva)+","+;
                                             "prov = "+ClipValue2Sql(base:prov)+","+;
                                             "rubro = "+ClipValue2Sql(base:rubro)+","+;
                                             "iva = "+ClipValue2Sql(base:iva)+","+;
                                             "precioven = "+ClipValue2Sql(base:precioven)+","+;
                                             "stockact = "+ClipValue2Sql(base:stockact)+" "+;
                          "WHERE codigo = "+ClipValue2Sql(base:codigo))
  ENDIF
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
RETURN nil
************************************************************************************************************************
***** TRAE LOS DATOS DEL ARTICULO SI EXISTE EN ALTA RAPIDA 
STATIC FUNCTION TraeDatos(nArticulo,oGet1,oQry,base)
LOCAL oQryAux1
oQryAux1:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(nArticulo))
IF oQryAux1:RecCount() > 0
base:= oQryAux1:GetRowObj()
oGet1[2]:cText:=oQryAux1:nombre
oGet1[3]:cText:=oQryAux1:nombre
oGet1[6]:cText:=oQryAux1:precossiva
oGet1[4]:cText:=oQryAux1:prov
oGet1[23]:cText:=oQryAux1:rubro
oGet1[14]:cText:=oQryAux1:iva
oGet1[20]:cText:=oQryAux1:precioven
oGet1[32]:cText:=oQryAux1:stockact
oQry2:GoTop() 
   IF oQry2:Seek(oGet1[4]:value,1) > 0
      oGet1[5]:cText := oQry2:nombre
   ENDIF
oQry5:GoTop() 
   IF oQry5:Seek(oGet1[23]:value,1) > 0
      oGet1[24]:cText := oQry5:nombre
   ENDIF
oQry3:GoTop() 
   IF oQry3:Seek(oGet1[14]:value,1) > 0
      oGet1[15]:cText := ALLTRIM(oQry3:nombre)
   ENDIF
   oQry:lAppend:=.f.
ELSE 
	oGet1[2]:cText:=SPACE(30)
	oGet1[3]:cText:=SPACE(15)
	oGet1[6]:cText:=0
	oGet1[4]:cText:=0
	oGet1[23]:cText:=0
	oGet1[14]:cText:=5
	oGet1[20]:cText:=0
	oGet1[32]:cText:=0
	oQry:lAppend:=.T.
ENDIF
RETURN .t.

************************************************************************************************************************
***** GRABA LA VENTA 
STATIC FUNCTION Grabar()
LOCAL nNumero,cNumComp,cLetra:=IF(oApp:tipo_iva<>6,IF(nCondicion>2,"B","A"),"C"),nPuntoVta,nCtaCte,nEfecti,;
      nCheque,nTarjet,nTransf,oQryPag,oQryPagFac,oQryPagCon,oQryVen,nRecibo,base,oerr,lFisc:=.F.,oQryCliAux,;
      aTablaIva,oTabIva, cCae, dFecVtoc,nTipFor,dFecha := DATE()

lFisc:= MsgYesNo("�Desea emitir el tiquet fiscal?","Atencion!")
oQryCliAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCliente))
IF lFisc
   IF oQryPun:tipofac = 1
      oTabIva := oApp:oServer:Query("SELECT codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H1 "+;
                                    " GROUP BY codiva")
      DO WHILE !oTabIva:Eof()
         AADD(aTablaIva,{oTabIva:codiva,oTabIva:neto,oTabIva:iva})
         oTabIva:Skip()
      ENDDO      
      nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
      FacturaElec1( nPuntoVta, 1, cLetra, aTablaIva, @nNumero, @cCae, @dFecVtoC,@nTipFor,;
                   dFecha,oQryCliAux:cuit,oQryCliAux:dni,oBrwDet:aCols[7]:nTotal,oBrwDet:aCols[8]:nTotal,oBrwDet:aCols[9]:nTotal)
      ELSE 
      nNumero := FacturaFiscal(oQryDet,oGet[08]:Value)
   ENDIF   
   IF nNumero = 0
      MsgStop("Fallo la impresion fiscal","Error")
      Return nil       
   ENDIF      
  ELSE
  nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
  nNumero := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):presupu+1
  cLetra := "X"
  cNumComp := cLetra + STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNumero,8)," ","0")  
ENDIF  
nEfecti:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 1"):monto
nTransf:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 2"):monto
nCheque:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 3"):monto
nTarjet:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 4"):monto
nCtaCte:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 5"):monto
nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
cNumComp := STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNumero,8)," ","0")

  oQryPag    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagos LIMIT 0")
  oQryPagFac := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagfac LIMIT 0")
  oQryPagCon := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagcon LIMIT 0")
  oQryVen    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ventas_encab LIMIT 0")
  // Grabar la factura
  // Grabo el pago
 TRY 
 oApp:oServer:BeginTransaction()
          

      // Grabo el pago si no es todo Cuenta Corriente
      //1 - GRABACION DE PAGO -------------------------------------------------------------------
      nRecibo :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")

      // Grabo el registro de PAGOS
      base := oQryPag:GetBlankRow()
      base:numero  := nRecibo
      base:cliente := nCliente
      base:total   := nEfecti + nTarjet + nCheque + nTransf
      base:fecha   := DATE()
      base:usuario := oApp:usuario
      base:fecmod  := DATE()
      base:ip      := oApp:cIp
      base:interes := 0
      oQryPag:oRow := base
      oQryPag:Save()

      //Grabo Pago Factura
      base := oQryPagFac:GetBlankRow()
      base:numero := nRecibo
      base:ticomp:= "FC"
      base:letra := cLetra
      base:numcomp:= RIGHT(cNumComp,13)
      base:fecha:= DATE()
      base:importe := nEfecti + nTarjet + nCheque 
      oQryPagFac:oRow := base
      oQryPagFac:Save()
      
  
      // Grabo los conceptos pagados
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon (numero,codcon,importe,observa) "+;
                           "(SELECT "+ClipValue2Sql(nRecibo)+",tipopag,"+;
                           "IF(tipopag=1,importe-"+ClipValue2Sql(nVuelto)+",importe),formapag"+;
                           " FROM formapag_temp"+;
                           " WHERE tipopag <> 5)")

      
      // GRABO DEUDA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,importe,saldo,estado,"+;
                                                     "nombre,cuit,dni,direccion,localidad,usuario,fecmod,ip) "+;
                              " VALUES ('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+","+IF(nCtaCte>=0,"1","0")+",1,"+ClipValue2Sql(DATE())+","+;
                                         ClipValue2Sql(nCliente)+","+ClipValue2Sql(nTotal)+","+;
                                         IF(nCtaCte>=0,ClipValue2Sql(nCtaCte),"0")+","+IF(nCtaCte=0,"'P'","'I'")+","+;
                                         ClipValue2Sql(oQryCliAux:nombre)+","+ClipValue2Sql(oQryCliAux:cuit)+","+;
                                         ClipValue2Sql(oQryCliAux:dni)+","+ClipValue2Sql(oQryCliAux:direccion)+","+ClipValue2Sql(oQryCliAux:localidad)+","+;
                                         ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+")")
      //-- DETALLE DE IVA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventivadet (tipocomp,letra,numfac,codiva,neto,iva) "+;
                           "(SELECT 'FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+;
                            ", codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H1 GROUP BY codiva)")
      //-- detalle de venta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
                        " (codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,codiva,neton,descu,pcosto) "+;
                        " (SELECT codart,detart,cantidad,punit,"+ClipValue2Sql(DATE())+","+ClipValue2Sql(nCliente)+","+;
                        "         'FC"+cLetra+cNumComp+"',ptotal, stotal,iva,codiva,neto,descuento,pcosto FROM VENTAS_DET_H1)")

      
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,fecha,neto,iva,importe,tipopag,observa,"+;
                                                      "nombre,cuit,dni,direccion,localidad,usuario,fecmod,ip,coniva,condven,formapag) VALUES "+;
                           "('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+","+ClipValue2Sql(nCliente)+","+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oBrwDet:aCols[7]:nTotal)+","+ClipValue2Sql(oBrwDet:aCols[8]:nTotal)+","+;
                            ClipValue2Sql(nTotal)+",1,'PUNTO DE VENTA',"+;
                            ClipValue2Sql(oQryCliAux:nombre)+","+ClipValue2Sql(oQryCliAux:cuit)+","+;
                            ClipValue2Sql(oQryCliAux:dni)+","+ClipValue2Sql(oQryCliAux:direccion)+","+ClipValue2Sql(oQryCliAux:localidad)+","+;
                            ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2SQL(nCondicion)+;
                            ",1,1)")      

      IF oApp:usar_puntos
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos + "+ClipValue2Sql(INT(nTotal/oApp:pesos_x_punto)))
      ENDIF

      //ACTUALIZO EL STOCK DE LOS ARTICULOS VENDIDOS
      oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                           "SET a.stockact = a.stockact - v.cantidad")


      IF lFisc       
         IF cLetra = "A"
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturaa = "+ClipValue2Sql(nNumero)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))
         ELSE  
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturab = "+ClipValue2Sql(nNumero)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))          
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
IF !lFisc
   FacturaNoFiscal('FC',cLetra+cNumComp)
ENDIF
Reiniciar()
RETURN nil
**********************************************************************************************
***** CALCULAR IMPORTE FINAL
STATIC FUNCTION CalcTot()
LOCAL oQryAux1
oBrwDet:MakeTotals()
oQryAux1:= oApp:oServer:Query("SELECT SUM(IF(descuento > 0,descuento,0)) AS descu,SUM(IF(descuento < 0,descuento,0)) AS recar "+;
                              "FROM VENTAS_DET_H1")
oGet[08]:cText:= oQryAux1:descu 
oGet[09]:cText:= ABS(oQryAux1:recar)
oGet[06]:cText:= oBrwDet:aCols[9]:nTotal
oGet[06]:Refresh()
oGet[08]:Refresh()
RETURN .t.

**********************************************************************************************************************
******* ANULA LA VENTA Y REINICIA 
STATIC FUNCTION Reiniciar()
oGet[01]:cText:=1
oGet[02]:cText:=0
oGet[03]:cText:=0
oGet[07]:cText:=SPACE(30)
nDescu:=0
cCliente:="CONSUMIDOR FINAL"
nCliente:=1
nCondicion:= 5
nLista:= 1
nPagado:=0
nVuelto:=0
oGet[04]:Refresh()
oGet[05]:Refresh()
oApp:oServer:Execute("TRUNCATE formapag_temp")
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H1")
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
oGet[06]:Refresh()
oGet[02]:SetFocus()
RETURN nil

*************************************************************************************************
*** AGREGO ARTICULO AL DETALLE
STATIC FUNCTION AgregarArticu(nCodArt)
LOCAL oQryAux, nPtotal:=0,nNeto1:=0,nImpIva2:=0,nNeto2:=0,nImpIva1:=0,oQryIva,nDescuento,;
      nIvaPes,nSubTotal,nCodIva1,nTotalcIva,nPrecio1,nPrecio2,lRta:=.f.,nDescMar,nTotalPesado:=0,lPesado:=.f.
IF lConsulta
   lConsulta:= .f.
   RETURN .f.
ENDIF
IF nCodArt >= 0


   IF nCodArt = 0
   	  RETURN .t.
   ENDIF

   IF nCodArt > 2000000000000 .and. nCodArt < 3000000000000 //VERIFICO SI ES UN PESADO
      nTotalPesado := VAL(SUBSTR(STR(nCodArt,13),8,5)) / 100 //GUARDO EL PRECIO TOTAL DEL PESADO
      nCodArt := VAL(LEFT(STR(nCodArt,13),7))  //TRUNCO LA PARTE DEL CODIGO 
      lPesado := .t.
   ENDIF
   
   oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(nCodArt))
   IF oQryAux:RecCount() = 0
      SndPlaySound("ringin.wav",1)
      MsgWait("Articulo no encontrado","Error",1)
      RETURN .f.
   ENDIF

   IF lPesado  //SI ES UN PESADO CALCULO LA CANTIDAD DEPENDIENDO DEL TOTAL
     nCantidad := nTotalPesado / IF(nLista=1,oQryAux:precioven,oQryAux:reventa)
     nCantidad := round(nCantidad,3)
   ENDIF
   
   IF nCodArt = 0
      RETURN .t.
   ENDIF

   IF oApp:usar_dias_precio
    IF oQryAux:fecmod < (DATE()- oApp:dias_precio)
      MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
              "Verifique la fecha de modificacion","Atencion!")
      RETURN .f.
    ENDIF
  ENDIF

   IF oQryAux:pesable  //SI ES UN ARTICULO PESABLE PIDO QUE INGRESE LA CANTIDAD A FACTURAR
      IF !PedirCantidad()
         RETURN .f.
      ENDIF
   ENDIF

   IF oQryPun:pidestock = 1 .and. oQryAux:stockact-nCantidad <= 0
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad �Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF
  ENDIF
  IF oQryPun:pidestock = 2 .and. oQryAux:stockact-nCantidad <= 0
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
     RETURN .F.
  ENDIF

   nDescMar:= oApp:oServer:Query("SELECT descuento FROM ge_"+oApp:cId+"desccli WHERE codmar ="+ClipValue2Sql(oQryAux:marca)+" AND "+;
                                 "codcli ="+ClipValue2Sql(nCliente)):descuento
   IF EMPTY(nDescMar) 
      nDescMar :=0
   ENDIF
   oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryAux:iva))
   nCodIva1 := oQryAux:iva
   nPrecio2:= (IF(nLista=1,oQryAux:precioven,oQryAux:reventa) * IF(oQryAux:endolares,oQryPar:dolar,1)) * nCantidad
   nDescuento:= nPrecio2 * (IF(nDescMar>0,nDescMar,nDescu)/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
   nSubTotal:= nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1
   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto) "+;
                         "VALUE ( "+ClipValue2Sql(nCodArt)+","+;
                                 ClipValue2Sql(oQryAux:nombre)+","+;
                                 ClipValue2Sql(nCantidad)+","+;
                                 ClipValue2Sql(IF(nLista=1,oQryAux:precioven,oQryAux:reventa) * IF(oQryAux:endolares,oQryPar:dolar,1))+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio1-nIvaPes)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva1)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(nSubTotal)+","+;
                                 ClipValue2Sql(oQryAux:preciocos)+;
                         " )" )	
ELSE
   oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos WHERE codigo = " + ClipValue2Sql(ABS(nCodArt)))
   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal) "+;
                         "VALUE ( "+ClipValue2Sql(nCodArt)+","+;
                                    ClipValue2Sql(oQryAux:nombre)+","+;
                                    ClipValue2Sql(nCantidad)+","+;
                                    ClipValue2Sql(nPrecio)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad)+;
                          " )" )

ENDIF
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
nCantidad:=1
nPrecio:=0
oGet[02]:cText:=0
oGet[07]:cText:=SPACE(30)
oGet[01]:Refresh()
oGet[02]:Refresh()
oGet[03]:Refresh()
RETURN nil

**************************************************************************************************
****** PEDIR QUE INGRESE LA CANTIDAD SI ES UN PESABLE 
STATIC FUNCTION PedirCantidad()
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(2),oBot1,oBot2,lRta:=.f.,nCantTemp:=0

DEFINE DIALOG oDlgD TITLE "Ingresar cantidad del articulo pesable a facturar" OF oDlg1 FROM 05,15 TO 11,55
  acor := AcepCanc(oDlgD)
  

   @ 12, 05 SAY "Cantidad:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1[1] VAR nCantTemp OF oDlgD PIXEL PICTURE "9999.999" RIGHT


   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[1]:SetFocus
IF !lRta
   RETURN .f.
ENDIF
nCantidad:= nCantTemp
oGet[06]:SetFocus()
RETURN .t.

**************************************************************************************************
*** MUEVE LOS DEPARTAMENTOS DE LUGAR EN LOS BOTONES
STATIC FUNCTION CambiarDeptos(lArriba)
LOCAL i
IF !lArriba
 oQryDep:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos  WHERE codigo > "+ClipValue2Sql(nUltDep)+" LIMIT 4")
 IF oQryDep:RecCount() > 0
   nPriDep:= oQryDep:GetRowObj():codigo
   oQryDep:GoTop()
   FOR i:= 2 TO 5
      oBot[i]:cCaption:= IF(oQryDep:Eof()," ",ALLTRIM(oQryDep:nombre) + " (F"+STR(i-1,1)+")")
      oBot[i]:cargo:= IF(oQryDep:Eof(),0,oQryDep:codigo)
      oBot[i]:Refresh()
      IF oQryDep:Eof()
         oBot[i]:Hide()
      ELSE
         oBot[i]:Show()
      ENDIF 
      oQryDep:Skip()
   NEXT i
   nUltDep:=oQryDep:codigo
 ENDIF
ELSE
 oQryDep:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos WHERE codigo < "+ClipValue2Sql(nPriDep)+;
                              " ORDER BY codigo DESC LIMIT 4")  
 IF oQryDep:RecCount() > 0
   nUltDep:= oQryDep:GetRowObj():codigo
   oQryDep:GoTop()
   FOR i:= 5 TO 2 STEP -1
      oBot[i]:cCaption:= IF(oQryDep:Eof()," ",ALLTRIM(oQryDep:nombre)+ " (F"+STR(i-1,1)+")")
      oBot[i]:cargo:= IF(oQryDep:Eof(),0,oQryDep:codigo)
      oBot[i]:Refresh()
      IF oQryDep:Eof()
         oBot[i]:Hide()
      ELSE
         oBot[i]:Show()
      ENDIF
      oQryDep:Skip()
   NEXT i
   nPriDep:=oQryDep:codigo
 ENDIF
ENDIF
RETURN nil

*********************************************************************************************************
**********APLICA DESCUENTOS A LA MESA
STATIC FUNCTION CargaDescu()
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(2),oBot1,oBot2,lRta:=.f.,nDescTemp:=0,nOpcion:=1,;
      aTipos:={"Descuento","Recargo"}

DEFINE DIALOG oDlgD TITLE "Aplicar descuentos a la venta" OF oDlg1 FROM 05,15 TO 11,55
 	acor := AcepCanc(oDlgD)
  

   @ 12, 05 SAY "Porcentaje:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1[1] VAR nDescTemp OF oDlgD PIXEL PICTURE "999.99" RIGHT
   @ 10, 80 COMBOBOX oGet1[2] VAR nOpcion ITEMS aTipos OF oDlgD PIXEL SIZE 40,12

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[1]:SetFocus
IF !lRta
   RETURN .f.
ENDIF
IF nOpcion = 1
   nDescu:= nDescTemp
ELSE
   nDescu:= -nDescTemp
ENDIF 
oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                     "SET v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100),"+;
                         "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                         "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                         "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                         "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)")
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
                                                         
RETURN .t.


**********************************************************************************************
******** CAMBIA EL CLIENTE DE LA MESA (EMPIEZA SIEMPRE EN 1 [CONSUMIDOR FINAL])
STATIC FUNCTION ElijeCliente()
LOCAL oDlgC,oGet1,oGet2,oBot1,oBot2,oBot3,oQryCli,lRta:=.f.,nClient:=nCliente,cNomCli:=SPACE(30)

oQryCli:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
oQryCli:GoTop()
IF oQryCli:Seek(nCliente,1) > 0
   cNomCli := oQryCli:nombre
ENDIF

DEFINE DIALOG oDlgC RESOURCE "CLIE" OF oDlg1
  oDlgC:lHelpIcon := .f.

  REDEFINE GET oGet1 VAR nClient OF oDlgC ID 101 PICTURE "999999";
               VALID(Buscar(oQryCli,oDlgC,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, Buscar(oQryCli,oDlgC,oGet1,oGet2)) BITMAP "BUSC1"
  REDEFINE GET oGet2 VAR cNomCli OF oDlgC ID 102 PICTURE "@!" WHEN(.F.)

  REDEFINE BUTTON oBot1 ID 201 OF oDlgC ACTION(AltaCli(oDlgC))
  REDEFINE BUTTON oBot2 ID 202 OF oDlgC ACTION(lRta:=.t.,oDlgC:End())
  REDEFINE BUTTON oBot2 ID 203 OF oDlgC ACTION(oDlgC:End())

ACTIVATE DIALOG oDlgC CENTER ON INIT oGet1:SetFocus() 
IF !lRta
   RETURN nil
ENDIF

cCliente:=cNomCli
nCliente:=nClient
nCondicion:= oQryCli:coniva
nLista:= oQryCli:lispre
nAntes:= oApp:oServer:Query("SELECT SUM(IF(tipo='NC',saldo*(-1),saldo)) AS antes FROM ge_"+oApp:cId+"ventas_cuota "+;
                            "WHERE cliente = "+ClipValue2Sql(nCliente)):antes
nDescu:= oQryCli:descuento

oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                     "SET v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100),"+;
                         "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                         "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                         "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                         "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)")
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
RETURN nil

******************************************************************************************************
****************** ALTA DE clientes
STATIC FUNCTION AltaCli(oDlgC)
LOCAL oDlgA,oQry,oGet1,oGet2,oGet3,oGet4,oGet7,oGet10,oGet6,oGet11,;
      oBot1,oBot2,mrta:=.f.,base,acor:=ARRAY(4),oError,;
      atipoiva  := {;
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
"14  Pequeño Contribuyente Eventual Social"}

oQry  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY NOMBRE")
base := oQry:GetBlankRow()
base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"clientes")  
base:coniva:=5
DO WHILE .T.
DEFINE DIALOG oDlgA TITLE "Alta de Clientes" FROM 05,10 TO 22,80 OF oDlgC
   acor := AcepCanc(oDlgA)
  
   @ 07, 05 SAY "Codigo:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Direccion:"      OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Telefono:"       OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Localidad:"      OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 82, 05 SAY "C.U.I.T.:"       OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 82,125 SAY "D.N.I.:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 97, 05 SAY "Condicion IVA:"  OF oDlgA PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR base:codigo PICTURE "99999" OF oDlgA PIXEL WHEN(.F.)
   @ 20, 70 GET oGet2 VAR base:nombre PICTURE "@!"  OF oDlgA PIXEL VALID(base:nombre<>SPACE(30))
   @ 35, 70 GET oGet3 VAR base:direccion OF oDlgA PIXEL
   @ 50, 70 GET oGet4 VAR base:telefono  OF oDlgA PIXEL
   @ 65, 70 GET oGet7 VAR base:localidad OF oDlgA PIXEL
   @ 80, 70 GET oGet10 VAR base:cuit     PICTURE "99-99999999-9" ;
         VALID(ValidaCuit(base:cuit)) OF oDlgA PIXEL
   @ 80,200 GET oGet6  VAR base:dni      PICTURE "99999999"  OF oDlgA PIXEL RIGHT
   @ 95, 70 COMBOBOX oGet11 VAR base:coniva  ITEMS aTipoIva SIZE 80,80 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlgA SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlgA:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF
IF base:coniva > 6 .and. base:coniva <12
   MsgStop("Condicion de I.V.A. no soportada por este programa")
   LOOP
ENDIF
IF base:coniva <> 5 .and. (EMPTY(base:cuit) .Or. base:cuit = "  -        - ")
   MsgStop("Debe poner un CUIT para esa condicion de I.V.A.")
   LOOP
ENDIF
IF base:coniva = 5 .and. (EMPTY(base:cuit) .Or. base:cuit = "  -        - ") .and. EMPTY(base:dni)
   MsgStop("Debe poner un CUIT o DNI para esa condicion de I.V.A.")
   LOOP
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh(.t.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

***************************************************************************************************
**********COBRO DE LA MESA
STATIC FUNCTION ElijeFormPag()
LOCAL oDlgC,oBot1:=ARRAY(26),oGet1:=ARRAY(3),oError,oBrwPag,nMonto:=((nTotal-nPagado)+nVuelto),oFontF,;
      nVueltoT:=nVuelto,nPagadoT:=nPagado,lRta:=.f.
oQryPag:= oApp:oServer:Query("SELECT * FROM formapag_temp")
DEFINE FONT oFontF NAME "ARIAL" SIZE 14,-17
DEFINE DIALOG oDlgC RESOURCE "FORMAPAGT" OF oDlg1
  oDlgC:lHelpIcon := .f.
	
	 REDEFINE XBROWSE oBrwPag DATASOURCE oQryPag;
            COLUMNS "FormaPag","Importe";
            HEADERS "Forma de pago","Importe";
            FOOTERS ;
            SIZES 150,89 ID 500 OF oDlgC
   PintaBrw(oBrwPag,0)
   oBrwPag:aCols[2]:nFooterTypE := AGGR_SUM
   oBrwPag:MakeTotals()

   REDEFINE BTNBMP oBot1[01] OF oDlgC ID 201 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[01],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[02] OF oDlgC ID 202 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[02],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[03] OF oDlgC ID 203 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[03],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[04] OF oDlgC ID 204 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[04],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[05] OF oDlgC ID 205 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[05],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[06] OF oDlgC ID 206 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[06],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[07] OF oDlgC ID 207 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[07],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[08] OF oDlgC ID 208 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[08],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[09] OF oDlgC ID 209 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[09],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[10] OF oDlgC ID 210 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[10],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())


   REDEFINE BTNBMP oBot1[13] ID 300 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[14] ID 301 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[15] ID 302 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[16] ID 303 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[17] ID 304 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[18] ID 305 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[19] ID 306 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[20] ID 307 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11)) 
   REDEFINE BTNBMP oBot1[21] ID 308 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[22] ID 309 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[23] ID 310 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],0,11),CargarNum(oGet1[1],0,11))
   REDEFINE BTNBMP oBot1[24] ID 311 OF oDlgC 2007 CENTER;
                   ACTION(BorrarNum(oGet1[1]))
   

   REDEFINE GET oGet1[1] VAR nMonto ID 101 OF oDlgC PICTURE "99999999.99" FONT oFontF
   REDEFINE GET oGet1[2] VAR nVueltoT ID 102 OF oDlgC PICTURE "99999999.99" FONT oFontF;
                WHEN((oGet1[2]:cText:= IF(oBrwPag:aCols[2]:nTotal>nTotal,oBrwPag:aCols[2]:nTotal-nTotal,0)) = "xxx")
   REDEFINE GET oGet1[3] VAR nTotal ID 103 OF oDlgC PICTURE "99999999.99" WHEN(.F.) FONT oFontF
   
   REDEFINE BTNBMP oBot[26] ID 401 OF oDlgC 2007 CENTER ACTION(lRta:=.t.,oDlgC:End())
   *REDEFINE BTNBMP oBot[26] ID 402 OF oDlgC 2007 CENTER ACTION(lRta:=.f.,oDlgC:End()) 
   REDEFINE BTNBMP oBot[27] ID 403 OF oDlgC 2007 CENTER ;
                   ACTION(oQryPag:Delete(),oBrwPag:Refresh(),oBrwPag:MakeTotals(),;
                   	      oGet1[1]:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)) WHEN(oQryPag:RecCount() > 0)

ACTIVATE DIALOG oDlgC CENTER ON INIT (PoneFormas(oBot1)) VALID ((nPagadoT:=oBrwPag:aCols[2]:nTotal) >=0)
IF !lRta
    RETURN nil 
ENDIF
nVuelto:= nVueltoT
nPagado:= nPagadoT
oGet[04]:Refresh()
oGet[05]:Refresh()

RETURN nil	

********************************************************************************************
*********
STATIC FUNCTION AgregarConcepto(oBoton,oBrwPag,oQryPag,oGet1)
LOCAL nRenglon
IF oBoton:nLastRow = 3 .and. nCliente < 3
   MsgStop("Consumidor final no puede pagar en Cta.Cte.","Error")
   RETURN nil 
ENDIF
nRenglon:= oApp:oServer:GetAutoIncrement("formapag_temp")
oApp:oServer:Execute("INSERT INTO formapag_temp (RENGLON,CODFORMA,TIPOPAG,FORMAPAG,IMPORTE) VALUES "+;
                     "("+ClipValue2Sql(nRenglon)+","+ClipValue2Sql(oBoton:cargo)+","+ClipValue2Sql(oBoton:nLastRow)+","+;
                      ClipValue2Sql(oBoton:cCaption)+","+ClipValue2Sql(oGet1:value)+")")
oQryPag:Refresh()
oBrwPag:Refresh()
oBrwPag:MakeTotals()
oGet1:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)
RETURN nil


***************************************************************************************
**********
STATIC FUNCTION PoneFormas(oBot1)
LOCAL oQryForPag,i
oQryForPag:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"forpag WHERE tactil = TRUE ORDER BY codigo")
oQryForPag:GoTop()
FOR i:= 1 TO 10
       oBot1[i]:cCaption:= IF(oQryForPag:Eof()," ",oQryForPag:nombre)
       oBot1[i]:cargo:= IF(oQryForPag:Eof(),0,oQryForPag:codigo)
       oBot1[i]:nLastRow:= IF(oQryForPag:Eof(),0,oQryForPag:tipo)
       oBot1[i]:Refresh()
       IF oQryForPag:Eof()
          oBot1[i]:Hide()
       ENDIF 
       oQryForPag:Skip()
    NEXT i
RETURN nil


**************************************************************************************
***** CARGAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION CargarNum(oGet,nNum,nPict,lString)
LOCAL cTexto,lTienePunto:="."$oGet:cText
DEFAULT lString:=.f.

IF lString 
IF lReemplaza
  oGet:cText:=SPACE(nPict)
  lReemplaza:= .f.
ENDIF
   cTexto:=oGet:cText
   cTexto := cTexto + STR(nNum,1)
   oGet:cText:= cTexto
ELSE
  IF lReemplaza
     oGet:cText:=0
     lReemplaza:= .f.
  ENDIF
  IF LEN(ALLTRIM(oGet:cText)) = nPict
   RETURN nil
  ENDIF
  cTexto:= ALLTRIM(STR(oGet:Value,nPict,IF(lTienePunto,2,0))) 
  cTexto:= strtran(cTexto,".","")
  cTexto := cTexto + STR(nNum,1)
  IF !lTienePunto
     oGet:cText:= VAL(cTexto)
  ELSE
    oGet:cText:= VAL(cTexto) / 100
  ENDIF

ENDIF
RETURN nil
***************************************************************************************
***** BORRAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION BorrarNum(oGet,lString)
LOCAL cTexto,lTienePunto:="."$oGet:cText
DEFAULT lString:=.f.
cTexto:= strtran(oGet:cText,".","")
cTexto := LEFT(cTexto,LEN(cTexto)-1)
IF !lTienePunto
     oGet:cText:= VAL(cTexto)
  ELSE
    oGet:cText:= VAL(cTexto) / 100
ENDIF
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j

lMaxi:=.f.
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.
  