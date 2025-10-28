// Dialogs designer
#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


MEMVAR oApp
static oDlg, oDlg1, nMesa := 1, oFont, oFontBot, oBrwDet, oQryDet, oQryDep, oQryArt, oBot, oGet,;
       nPagado, nVuelto, cNomArt, nDescu, lConsulta, oQryPag, nAntes,;
       nUltDep, nPriDep, nUltArt, nPriArt, fDepto, nCantidad, dFecha, nCliente, cCliente, nTotal, cVentana, ;
       lMaxi:=.t., nPrecio, lReemplaza, nCondicion, oQryPun, nDescuTot, nRecarTot, oQry2, oQry3, oQry5,;
       oQryPendi, oBrwPendi, nLista, oQryPar, nLisPre, aFormaNom, aFormaInc, aFormaTip, nFormaPago, oGetDep1, oGetDep2,;
       oGetDep3 , cPermi, lSaleX

//----------------------------------------------------------------//

PROCEDURE POSMULTI(cPermisos)
LOCAL oWnd1, oDlg, oBar, oTimer
CrearTemporales()
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H1")
oApp:oServer:Execute("TRUNCATE formapag_temp")
oQryPendi := oApp:oServer:Query("SELECT id,nombre_equipo,codcli,nombre,importe FROM ge_"+oApp:cId+"ventas_encab_p")
DEFINE WINDOW oWnd1 MDICHILD TITLE "Ventas Temporales" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Venta Temporal"  ;
            ACTION (POS1MULTI(cPermisos,0),oBrwPendi:Refresh());
            PROMPT "Alta" TOP
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Venta Temporal"  ;
            ACTION (POS1MULTI(cPermisos,oQryPendi:id),oBrwPendi:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryPendi:RecCount()>0)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Venta Temporal"  ;
            ACTION (Baja(oQryPendi:id),oBrwPendi:Refresh());
            PROMPT "Baja" TOP WHEN(oQryPendi:RecCount()>0 .AND. "B"$cPermisos) 
         DEFINE BUTTON RESOURCE "BACKU" OF oBar ;
            TOOLTIP "Refrescar la pantalla"  ;
            ACTION (oQryPendi:Refresh(),oBrwPendi:Refresh());
            PROMPT "Refresca" TOP
         DEFINE BUTTON RESOURCE "BUSC" OF oBar ;
            TOOLTIP "Ver el historial de hoy"  ;
            ACTION Historial(oWnd1);
            PROMPT "Historial" TOP
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
    oWnd1:bGotFocus := { || oDlg:SetFocus}
    oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrwPendi DATASOURCE oQryPendi;
              COLUMNS "id","nombre_equipo","nombre","importe";
              HEADERS "N° Pedido","Terminal","Cliente","Importe";
              SIZES 90,150,350,100;
              FOOTERS ;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (POS1MULTI( cPermisos,oQryPendi:id),oBrwPendi:Refresh())
     REDEFINE SAY oBrwPendi:oSeek PROMPT "" ID 113 OF oDlg

     DEFINE TIMER oTimer INTERVAL 20000 ACTION ActualizarPendi() OF oWnd1
     oQryPendi:bOnChangePage := {|| oBrwPendi:Refresh() }
     oBrwPendi:aCols[4]:nFooterTypE := AGGR_SUM
     oBrwPendi:MakeTotals()
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrwPendi,4) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE    
     oBrwPendi:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrwPendi,cPermisos,3)} 
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT (Incrusta( oWnd1, oDlg, .T.),oTimer:Activate()) VALID(cerrar())
RETURN 

STATIC FUNCTION ActualizarPendi()
LOCAL oQryT := oApp:oServer:Query("SELECT COUNT(id) as cant, SUM(importe) AS tot FROM ge_"+oApp:cId+"ventas_encab_p")
CrearTemporales()
IF oQryT:cant > oQryPendi:nRecCount .or. oQryT:tot <> oBrwPendi:aCols[4]:nTotal 
   oQryPendi:Refresh()
   oBrwPendi:Refresh()
ENDIF
RETURN nil   

static function baja(nId)
LOCAL lRta := .f.
lRta := MsgNoYes("Seguro de borrar?","Atencion")
IF lRta 
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab_p WHERE id = "+ClipValue2Sql(nId))
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det_p   WHERE numven = "+ClipValue2Sql(nId))
   oQryPendi:Refresh()
   oBrwPendi:Refresh()     
ENDIF
return nil

PROCEDURE POS1MULTI(cPermisos,nId)
LOCAL hHand
LOCAL i,oFont1,oFont2,oFont3,oFont4,nCodArt:=0,nNumMesa,oMesa,nPicture,nComen:=0,oQryFormas, lGrande := .f.
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0 
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
cPermi := cPermisos   
lSaleX := .F.
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H1")

IF nId > 0
   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,neto,descuento,stotal,iva,codiva,ptotal,pcosto,impint) "+;
                         "(SELECT codart,detart,cantidad,punit,neton,descu,neto,iva,codiva,importe,pcosto,impint FROM ge_"+oApp:cId+"ventas_det_p "+;
                         "WHERE numven = "+ClipValue2Sql(nId)+")")
   nCliente:= oQryPendi:codcli
   cCliente:= oQryPendi:nombre
   ELSE 
   nCliente:= 1
   cCliente:= SPACE(30)
ENDIF
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS VENTAS_DET_H1 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(10,3) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"`PCOSTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IMPINT`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`ESPROMO` TINYINT(1) DEFAULT '0' NOT NULL, ";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

oQryDet:= oApp:oServer:Query("SELECT * FROM VENTAS_DET_H1")

oApp:oServer:Execute("TRUNCATE formapag_temp")
oApp:oServer:NextResult() 

oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
oQryPar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,precioven,reventa,stockact,stockmin,stockotro FROM ge_"+oApp:cId+"articu")
lReemplaza:=.t.
   oBot:=ARRAY(70)
   oGet:=ARRAY(10)
   fDepto:=0
   dFecha:=DATE()
   
   cNomArt:=SPACE(30)
   nTotal:=0
   nPrecio:=0
   nPagado:=0
   nVuelto:=0
   nDescu:=0
   nDescuTot:=0
   nRecarTot:=0
   lConsulta:=.f.
   nLista:= oApp:oServer:Query("SELECT lispre FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCliente)):lispre
   nLisPre := 0
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
 DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-12 
 DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-25 BOLD
 DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-20 BOLD 
 DEFINE FONT oFont4 NAME "ARIAL" SIZE 0,-11.5
nUltDep:=0
nPriDep:=0
nUltArt:=0
nPriArt:=0
nCantidad:=1
IF nId > 0
   nCondicion:= oApp:oServer:Query("SELECT coniva FROM ge_"+oApp:cId+"clientes WHERE codigo = "+STR(nCliente)):coniva
   ELSE 
   nCondicion:=5
ENDIF   

IF oApp:cierre_turno
  IF !ValidarTurno(oApp:oWnd)
    cerrar()
    RETURN
  ENDIF
ENDIF
IF !ValidarSaldoCaja()   
   RETURN 
ENDIF
IF ResolucionMonitor() > 1400
   DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-14
   DEFINE DIALOG oDlg1 RESOURCE "POSGRANDE" OF oApp:oWnd TITLE "Facturacion punto de venta" FONT oFont1
   lGrande := .t.
   ELSE 
   DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-11.5
   DEFINE DIALOG oDlg1 RESOURCE "POS" OF oApp:oWnd TITLE "Facturacion punto de venta"
ENDIF   
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
                   PROMPT "&Guardar [F8]";
                   ACTION (GrabaySigue(nId),oDlg1:End()) WHEN(oQryDet:RecCount()>0)
   REDEFINE BTNBMP oBot[31] ID 302 OF oDlg1 2007 CENTER; //DESCUENTOS
                   PROMPT "&Descuentos";
                   ACTION(CargaDescu(),oGet[02]:SetFocus()) WHEN("R"$cPermisos)
   REDEFINE BTNBMP oBot[32] ID 303 OF oDlg1 2007 CENTER; //BORRA ITEM
                   PROMPT "&Borrar item [F6]";
                   ACTION BorraItem(cPermisos, oDlg1) WHEN (oQryDet:RecCount()>0)
   REDEFINE BTNBMP oBot[33] ID 304 OF oDlg1 2007 CENTER; //SELECCIONA CLIENTE
                   PROMPT "&Elegi cliente [F3]";
                   ACTION(ElijeCliente(),oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[34] ID 305 OF oDlg1 2007 CENTER; //SALIR
                   PROMPT "&Salir [Esc]";
                   ACTION(oDlg1:End())
   REDEFINE BTNBMP oBot[35] ID 306 OF oDlg1 2007 CENTER; //ELIJE FORMAS DE PAGO
                   PROMPT "&Cobrar [F4]";
                   ACTION(CalcularPromos(),ElijeFormPag(),oGet[02]:SetFocus());
                   WHEN(nTotal>0 .AND. oApp:usua_es_supervisor) 
   REDEFINE BTNBMP oBot[36] ID 307 OF oDlg1 2007 CENTER; //CONSULTA
                   PROMPT "&Consulta";
                   ACTION(lConsulta:=.t.,oGet[02]:SetFocus())
   REDEFINE BTNBMP oBot[37] ID 308 OF oDlg1 2007 CENTER; //CALCULADORA
                   PROMPT "Departamen&tos [F5]";
                   ACTION(FactDept(oDlg1,oFont2)) WHEN("E"$cPermisos)
   REDEFINE BTNBMP oBot[38] ID 309 OF oDlg1 2007 CENTER; //ANULAR
                   PROMPT "A&nular";
                   ACTION(AunularTicket(cPermisos),oGet[02]:SetFocus()) 
   REDEFINE BTNBMP oBot[39] ID 310 OF oDlg1 2007 CENTER; //GRABA
                   PROMPT "&Grabar [F12]";
                   ACTION(IF(Grabar(nId),oDlg1:End(),nil));
                   WHEN((ROUND(nPagado,2) >= ROUND(nTotal,2)) .and. nTotal > 0) 
   REDEFINE BTNBMP oBot[19] ID 4004 OF oDlg1 2007 CENTER; //GRABA
                   PROMPT "&Vales" WHEN(oApp:usavales)
   oBot[19]:bAction = { | nRow, nCol | Vales( nRow, nCol, oBot[19],.t.,oDlg1) }
  
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
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[1]:nTop+oGet[1]:nLeft,oGet[2]:SetFocus(),;
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[2]:nTop+oGet[2]:nLeft .and. nCodart < 0,oGet[3]:SetFocus(),nil)  ))  //SI ESTA EN CANTIDAD VUELVE AL CODIGO DEL ARTICULO                         
   REDEFINE BTNBMP oBot[54] ID 414 OF oDlg1 2007 CENTER;
                   ACTION(BorrarNum(oDlg1:cargo))
   
   IF !lGrande
      REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
            COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","DESCUENTO","STOTAL","IVA","PTOTAL","CODIVA","IMPINT";
            HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Neto","Dto./Rec.","Sub Total","IVA","Total","Tasa","Imp.";
            FOOTERS ;
            SIZES 40,243,65,64,55,55,55,64,55,55,55 ID 1000 OF oDlg1 WHEN(oQryDet:RecCount()>0)
      ELSE
      REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
            COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","DESCUENTO","STOTAL","IVA","PTOTAL","CODIVA","IMPINT";
            HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Neto","Dto./Rec.","Sub Total","IVA","Total","Tasa","Imp.";
            FOOTERS ;
            SIZES 40,340,105,105,55,55,55,55,105,55,55 ID 1000 OF oDlg1 WHEN(oQryDet:RecCount()>0)
   ENDIF   
   PintaBrw(oBrwDet,0)
   oBrwDet:aCols[2]:nFooterTypE := AGGR_COUNT
   oBrwDet:aCols[3]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[5]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[6]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[7]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[8]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[9]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[11]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[2]:bEditWhen := {| |SiEsDepto(oQryDet)}
   oBrwDet:aCols[2]:nEditType := EDIT_GET
   IF oApp:modifica_precios .AND. "M"$cPermisos
      oBrwDet:aCols[4]:nEditType := EDIT_GET
   ENDIF
   IF "M"$cPermisos
      oBrwDet:aCols[3]:nEditType := EDIT_GET
   ENDIF
   oBrwDet:aCols[4]:bEditValid := ;
       {|oGet| IF(oGet:Value <= 0,MsgStop("Ponga un importe valido","Error")<>nil,.t.)}   
   oBrwDet:aCols[3]:bOnPostEdit := { |oCol,xval,nkey| CambiaCant(xval,1)} 
   oBrwDet:aCols[4]:bOnPostEdit := { |oCol,xval,nkey| CambiaCant(xval,2)} 

   oBrwDet:MakeTotals()
   oBrwDet:aCols[1]:Hide()
   FOR i:= 5 TO 8 
       oBrwDet:aCols[i]:Hide() 
   NEXT i  
   oBrwDet:aCols[10]:Hide()
   oBrwDet:aCols[11]:Hide()
   
   REDEFINE GET oGet[02] VAR nCodArt   ID 10 OF oDlg1 PICTURE "99999999999999" FONT oFont2;
                ACTION (oGet[02]:cText:= 0, BuscarArt(oQryArt,oDlg1,oGet[2],oGet[7],'0','nosale'),;
                        oGet[01]:cText:=1,oGet[03]:cText:=IF(nLista=1,oQryArt:precioven,oQryArt:reventa)) BITMAP "BUSC"
   REDEFINE GET oGet[07] VAR cNomArt   ID 16 OF oDlg1 PICTURE "@!" FONT oFont3 ;
                WHEN(IF(nCodArt>0,;
                     (oGet[07]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[2]:cText)):nombre) = "xxxxx",;
                     (oGet[07]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"deptos WHERE codigo = "+ClipValue2Sql(ABS(oGet[2]:value))):nombre) = "xxxxx"))
   REDEFINE GET oGet[01] VAR nCantidad ID 11 OF oDlg1 PICTURE "9999" FONT oFont2 
   REDEFINE GET oGet[03] VAR nPrecio   ID 12 OF oDlg1 PICTURE "99999999.99" FONT oFont2 ;
                WHEN(oGet[02]:value <= 0 .or. ((oGet[03]:cText:= IF(nLista=1,oApp:oServer:Query("SELECT precioven FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[2]:cText);
                                                                                    ):precioven,;
                                                                             oApp:oServer:Query("SELECT reventa FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[2]:cText);
                                                                                    ):reventa)*nCantidad) <> "xxx")) 

   REDEFINE COMBOBOX oGet[10] VAR nFormaPago ID 4002 OF oDlg ITEMS aFormaNom ON CHANGE (ActualizarDet(),oGet[02]:SetFocus())
   REDEFINE GET oGet[08] VAR nDescuTot ID 17 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[09] VAR nRecarTot ID 18 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[04] VAR nPagado   ID 13 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[05] VAR nVuelto   ID 14 OF oDlg1 PICTURE "99999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[06] VAR nTotal    ID 15 OF oDlg1 PICTURE "99999999.99" FONT oFont2 WHEN(CalcTot()) COLOR CLR_WHITE,CLR_BLACK

   oGet[01]:bGotFocus := {|| oDlg1:cargo := oGet[1],nPicture:=2,lReemplaza:=.t.}
   oGet[02]:bGotFocus := {|| oDlg1:cargo := oGet[2],nPicture:=13,lReemplaza:=.t.}
   oGet[03]:bGotFocus := {|| oDlg1:cargo := oGet[3],nPicture:=10,lReemplaza:=.t.}
   oGet[06]:bGotFocus := {|| oDlg1:cargo := oGet[6],nPicture:=11}

   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==106,oGet[1]:SetFocus(),;
                                       IF(nKey==113,(Eval(oGet[02]:bAction),oGet[1]:SetFocus()),;
                                       IF(nKey==117,oBot[32]:Click,;
                                       IF(nKey==114,oBot[33]:Click,;
                                       IF(nKey==115,oBot[35]:Click,;
                                       IF(nKey==116,oBot[37]:Click,;
                                       IF(nKey==118,Varios(oGet),;
                                       IF(nKey==119,oBot[30]:Click,;
                                       IF(nKey==123,oBot[39]:Click,.F.)))))))))}
   oGet[03]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[3]:assign(),AgregarArticu(nCodArt),oGet[02]:SetFocus()),.t.)}
   oGet[02]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[2]:assign(),AgregarArticu(nCodArt)),.t.)}
   oGet[01]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[1]:assign(),oGet[02]:SetFocus()),.t.)}


oDlg1:cargo:= oGet[02]
ACTIVATE DIALOG oDlg1 CENTER;
         ON INIT (oGet[02]:SetFocus(), IF(!oApp:usavales,oBot[19]:Hide(),.f.));
         VALID(PuedeSalir(cPermisos,oQryDet))
// CUANDO CIERRA LA FACTURACION CAMBIA LOS BITMAPS

RETURN

STATIC FUNCTION AunularTicket(cPermisos)
IF "A"$cPermisos
   IF !MsgNoYes("Seguro de anular los cambios temporales","Atencion")
      RETURN .f.
   ENDIF 
   Auditar(4," $"+alltrim(STR(nTotal,12,2))+" "+STR(oQryDet:nRecCount,4)+" Items Caja "+STR(oApp:prefijo,4))
   Reiniciar()
   RETURN .t. 
ENDIF 
IF oQryDet:nRecCount > 0 .and. PedirClave()       
   Auditar(4," $"+alltrim(STR(nTotal,12,2))+" "+STR(oQryDet:nRecCount,4)+" Items Caja "+STR(oApp:prefijo,4))
   Reiniciar()
   RETURN .t. 
ENDIF
RETURN .f.

STATIC FUNCTION GrabaySigue(nId)
LOCAL nNumero, lRta := .f., oErr
IF EMPTY(cCliente)
   MsgGet("Asingar Pendiente","Nombre del cliente:",@cCliente)
ENDIF 
  
TRY
      IF nId > 0
          //BORRO FACTURAS PENDIENTES USADAS (SI NO USA NINGUNA ES 0)
          oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab_p WHERE id = "+ClipValue2Sql(nId))
          oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det_p   WHERE numven = "+ClipValue2Sql(nId))

          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab_p (id,nombre_equipo,codcli,nombre,cuit,dni,direccion,localidad,coniva,importe) "+;
                               "VALUES("+ClipValue2Sql(nId)+","+ClipValue2Sql(DTOC(DATE())+" "+;
                                oApp:cNombreEquipo)+","+ClipValue2Sql(nCliente)+","+ClipValue2Sql(cCliente)+","+;
                                ClipValue2Sql(' ')+","+ClipValue2Sql(0)+","+;
                                ClipValue2Sql(' ')+","+ClipValue2Sql( ' ')+","+ClipValue2Sql(5)+","+;
                                ClipValue2Sql(nTotal)+")")
          nNumero:= nId
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det_p "+;
                            " (numven,codart,detart,cantidad,punit,codcli,importe,neto,iva,codiva,neton,descu,pcosto,impint) "+;
                            " (SELECT "+ClipValue2Sql(nNumero)+",codart,detart,cantidad,punit,"+ClipValue2Sql(nCliente)+","+;
                            " ptotal, stotal,iva,codiva,neto,descuento,pcosto,impint FROM VENTAS_DET_H1 WHERE ESPROMO IS FALSE)")
        ELSE
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab_p (nombre_equipo,codcli,nombre,cuit,dni,direccion,localidad,coniva,importe) "+;
                               "VALUES("+ClipValue2Sql(DTOC(DATE())+" "+oApp:cNombreEquipo)+","+ClipValue2Sql(nCliente)+","+ClipValue2Sql(cCliente)+","+;
                                ClipValue2Sql(' ')+","+ClipValue2Sql(0)+","+;
                                ClipValue2Sql(' ')+","+ClipValue2Sql( ' ')+","+ClipValue2Sql(5)+","+;
                                ClipValue2Sql(nTotal)+")")
          nNumero:= oApp:oServer:LastInsertID()
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det_p "+;
                            " (numven,codart,detart,cantidad,punit,codcli,importe,neto,iva,codiva,neton,descu,pcosto,impint) "+;
                            " (SELECT "+ClipValue2Sql(nNumero)+",codart,detart,cantidad,punit,"+ClipValue2Sql(nCliente)+","+;
                            " ptotal, stotal,iva,codiva,neto,descuento,pcosto,impint FROM VENTAS_DET_H1  WHERE ESPROMO IS FALSE)")
      ENDIF    
      
CATCH oErr 
      MsgInfo(oErr:description,"Error")
END TRY
lRta := MsgNoYes("Desea imprimir el comprobante"+chr(10)+"Antes de dejar en cola?","Atencion")
IF lRta
    PrintPendi(nNumero)    
ENDIF
oQryPendi:Refresh()
oBrwPendi:Refresh()
lSaleX := .T.     
RETURN .t.

STATIC FUNCTION PuedeSalir(cPermisos,oQryDet)
LOCAL lRta
IF lSaleX 
   RETURN .t.
ENDIF   
IF "A"$cPermisos .AND. "B"$cPermisos
   lRta := .t.
   ELSE 
   IF oQryDet:nRecCount > 0
      IF "A"$cPermisos
         lRta := MsgNoYes("Seguro de Salir sin grabar?","Atencion!")
         ELSE 
         lRta := .f.
         MsgStop("Debe cerrar el ticket para salir","Atencion!")
      ENDIF
      ELSE 
      lRta := .t.
   ENDIF
ENDIF
RETURN lRta

STATIC FUNCTION BorraItem(cPermisos,oDlg1)
IF "B"$cPermisos
   Auditar(3," $"+alltrim(STR(oQryDet:ptotal,12,2))+" "+ALLTRIM(oQryDet:detart)+" Caja "+STR(oApp:prefijo,4))
   oQryDet:Delete()
   oBrwDet:Refresh()
   oApp:oServer:Execute("TRUNCATE formapag_temp")
   nPagado := 0
   oGet[04]:Refresh()
   oGet[02]:SetFocus()
   ELSE 
   IF oApp:usar_clave
       IF !PedirClave("Ponga la clave de autorización para borrar item",oDlg1)
          RETURN nil
          ELSE 
          Auditar(3," $"+alltrim(STR(oQryDet:ptotal,12,2))+" "+ALLTRIM(oQryDet:detart)+" Caja "+STR(oApp:prefijo,4))
          oQryDet:Delete()
          oBrwDet:Refresh()
          oApp:oServer:Execute("TRUNCATE formapag_temp")
          nPagado := 0
          oGet[04]:Refresh()
          oGet[02]:SetFocus()  
       ENDIF
       ELSE
       MsgStop("No tiene permiso para borrar item","Atencion")
       RETURN nil       
   ENDIF  
ENDIF
RETURN nil   

STATIC FUNCTION SiEsDepto(oQ)
RETURN oQ:codart < 0

STATIC FUNCTION Varios(oGet)
oGet[02]:cText := -1
oGet[07]:cText := "VARIOS                 "
oGet[03]:SetFocus()
RETURN nil

*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaCant(nVal,n)
LOCAL nII, nCantAnt
IF nVal = 0
  MsgStop("Cantidad no válida","Error")
  RETURN nil 
ENDIF   
IF n = 1
   nCantAnt := oQryDet:cantidad
   IF nVal > 99999
      MsgStop("Cantidad no válida","Error")
      RETURN nil
   ENDIF   
   IF !ValidarCantidad(oQryDet:codart, nVal-oQryDet:cantidad)
      RETURN nil 
   ENDIF
   oQryDet:cantidad := nVal
   oQryDet:ptotal    := oQryDet:ptotal / nCantAnt * nVal
   oQryDet:neto     := oQryDet:neto / nCantAnt * nVal
   oQryDet:iva      := oQryDet:iva / nCantAnt * nVal
   oQryDet:impint   := oQryDet:impint / nCantAnt * nVal
   oQryDet:stotal   := oQryDet:neto
   oQryDet:Save()
   oQryDet:Refresh()
   oBrwDet:Refresh()
   oBrwDet:MakeTotals()
   nTotal := ROUND(oBrwDet:aCols[9]:nTotal,2)
   oGet[06]:Refresh()
   ELSE 
   IF n = 2      
      nII:=oQryDet:impint/oQryDet:cantidad
      //oQryDet:punit := nVal - nII
      oQryDet:punit := nVal 
      oQryDet:ptotal    := nVal * oQryDet:cantidad
      oQryDet:neto     := (oQryDet:ptotal-nII) / IF(oQryDet:codiva = 5,1.21,IF(oQryDet:codiva=4,1.105,1))
      oQryDet:iva      := oQryDet:ptotal - oQryDet:neto - nII
      oQryDet:stotal   := oQryDet:neto
      
      oQryDet:Save()
      oQryDet:Refresh()
      oBrwDet:Refresh()
      oBrwDet:MakeTotals()
      nTotal := ROUND(oBrwDet:aCols[9]:nTotal,2)
      oGet[06]:Refresh()
   ENDIF
ENDIF
RETURN nil

**************************************************
*** ACTUALIZAR TODO EL DETALLE 
STATIC FUNCTION ActualizarDet()
LOCAL cPunit:= "(IF(l.precio IS NOT NULL AND l.precio >0,l.precio,"+IF(nLista=1,"a.precioven","a.reventa")+") * (1+("+ClipValue2Sql(aFormaInc[nFormaPago])+"/100)))",oQryCli
CrearTemporales()
oApp:oServer:Execute("TRUNCATE formapag_temp")
oQryCli:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCliente))
oApp:oServer:Execute("DELETE FROM VENTAS_DET_H1 WHERE ESPROMO IS TRUE")
oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                     "LEFT JOIN ge_"+oApp:cId+"lispredet l ON l.codlis = "+ClipValue2Sql(nLisPre)+" AND l.codart = a.codigo "+;
                     "SET v.punit = "+cPunit+","+;
                         "v.descuento = (v.cantidad * "+cPunit+") * ("+ClipValue2Sql(nDescu)+"/100),"+;
                         "v.iva =  ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) - ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * "+cPunit+"-v.cantidad * a.impint) - ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                         "v.stotal = ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) - ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                         "v.ptotal = ((v.cantidad * "+cPunit+") - ((v.cantidad * "+cPunit+") * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                         "v.neto =  ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) - ((v.cantidad * "+cPunit+"-v.cantidad * a.impint) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100) WHERE v.codart > 0")

oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                     "LEFT JOIN ge_"+oApp:cId+"deptos a ON a.codigo = ABS(v.codart) "+;                     
                     "SET "+;
                         "v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100),"+;
                         "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                         "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                         "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                         "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100) WHERE v.codart < 0")
nPagado:=0
nVuelto:=0
oGet[04]:Refresh()
oGet[05]:Refresh()
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
RETURN .T.

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
  REDEFINE CHECKBOX oGet1[07] VAR base:pesable ID 4001 OF oForm  
  REDEFINE GET oGet1[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet1[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!" 
  REDEFINE GET oGet1[06] VAR base:precossiva ID 106 OF oForm PICTURE "99999999.99" 
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
 
  REDEFINE GET oGet1[20] VAR base:precioven  ID 121 OF oForm PICTURE "99999999.99"
 
  REDEFINE GET oGet1[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"

  REDEFINE BUTTON oBot1[1] ID 137 OF oForm;
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot1[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet1[01]:SetFocus())

IF !lRta 
   RETURN nil
ENDIF
base:fecmod = DATE()
IF oQry:lAppend
   base:depto := 1
   base:empresa := 1
   base:marca := 1
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
                                             "fecmod = "+ClipValue2Sql(base:fecmod)+","+;
                                             "pesable = "+ClipValue2Sql(base:pesable)+","+;
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
oQryAux1:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(nArticulo))
IF oQryAux1:RecCount() > 0
base:= oQryAux1:GetRowObj()
oGet1[2]:cText:=oQryAux1:nombre
oGet1[3]:cText:=oQryAux1:nombre
oGet1[6]:cText:=oQryAux1:precossiva
oGet1[7]:SetCheck(oQryAux1:pesable)
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
  oGet1[7]:SetCheck(.f.)
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
STATIC FUNCTION Grabar(nId)
LOCAL nNumero,cNumComp,cLetra:=IF(oApp:tipo_iva<>6,IF(nCondicion = 1 .or. nCondicion = 2 .or. nCondicion = 6 ,"A","B"),"C"),nPuntoVta,nCtaCte,nEfecti,;
      nCheque,nTarjet,nTransf,nMPago,oQryPag,oQryPagFac,oQryPagCon,oQryVen,nRecibo,base,oerr,lFisc:=.F.,oQryCliAux,;
      aTablaIva := {},oTabIva, cCae := "", dFecVtoc := DATE(),nTipFor:=0,dFecha := DATE(),nForma, oQryStock,;
      nNumDep, nPunLocal, nSaldoCta, oTransferencias,;
      nCodCue := 0, nNumOpe := 0, cObserva1:="Pago por Pos "+SPACE(255), oQryTransf,;
      nCodCue2 := 0, nNumOpe2 := 0, cObserva2:="Pago por Pos "+SPACE(255),;
      nPuntos := 0, nPuntosAcu := 0, cSQL
nTransf:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 2"):monto
oTransferencias:= oApp:oServer:Query("SELECT f1.* FROM formapag_temp f1 LEFT JOIN ge_"+oApp:cId+"forpag f2 ON f2.codigo = f1.codforma WHERE f1.tipopag = 2 AND f2.codcue = 0")
IF nTransf > 0
   IF oTransferencias:RecCount() > 0
      IF !DatosTransferencia(@nCodCue2,@nNumOpe2,@cObserva2,)     
         RETURN .f.
      ENDIF
   ENDIF
ENDIF
oQryCliAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCliente))
nSaldoCta := oApp:oServer:Query("SELECT SUM(saldo * if(tipo='NC',-1,1)) AS deuda FROM ge_"+oApp:cId+"ventas_cuota "+;
                                       "WHERE cliente = "+ClipValue2Sql(nCliente)):deuda

IF oApp:usar_limite_cred .and. oQryCliAux:limite <> 0 
   nCtaCte:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 5"):monto
  IF nCtaCte > 0 .AND. ((nCtaCte - oQryCliAux:saldo + nSaldoCta ) > oQryCliAux:limite) .and. nCliente > 1
    IF oApp:usar_clave
     IF !PedirClave("El cliente que quiere facturar tiene el limite de credito excedido, ingrese la clave de autorizacion para continuar",oDlg)
        RETURN .f.
     ENDIF
    ELSE 
     IF !MsgNoYes("El cliente que quiere facturar tiene el limite de credito excedido, desea continuar","Atencion")
        RETURN .f.
     ENDIF
    ENDIF 
  ENDIF
ENDIF
CrearTemporales()
lFisc:= MsgYesNo("¿Desea emitir el tiquet fiscal?","Atencion!")
IF lFisc
   IF oQryPun:tipofac = 1
      oTabIva := oApp:oServer:Query("SELECT codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H1 "+;
                                    " GROUP BY codiva")
      DO WHILE !oTabIva:Eof()
         AADD(aTablaIva,{oTabIva:codiva,oTabIva:neto,oTabIva:iva})
         oTabIva:Skip()
      ENDDO
      nPunLocal :=  oApp:oServer:Query("SELECT punto FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):punto
      IF nPunLocal > 0
         nPuntoVta := nPunLocal
         ELSE 
         nPuntoVta:= oApp:oServer:Query("SELECT prefijo FROM ge_"+oApp:cId+"parametros LIMIT 1"):prefijo
      ENDIF 
      IF cLetra = "A" .and. !ConsultaCuitRapida(val(STRTRAN(oQryCliAux:cuit,"-","")),oQryCliAux:coniva)
         RETURN .f.
      ENDIF           
      FacturaElec1( nPuntoVta, 1, cLetra, aTablaIva, @nNumero, @cCae, @dFecVtoC,@nTipFor,;
                   dFecha,oQryCliAux:cuit,oQryCliAux:dni,oBrwDet:aCols[7]:nTotal,oBrwDet:aCols[8]:nTotal,oBrwDet:aCols[9]:nTotal,oBrwDet:aCols[11]:nTotal,oQryCliAux:coniva)
      ELSE 
      nNumero := FacturaFiscal(oQryDet,oGet[08]:Value)
      nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
   ENDIF   
   IF nNumero = 0
      MsgStop("Fallo la impresion fiscal","Error")
      Return .f.       
   ENDIF      
  ELSE
  nPuntoVta:=  oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja
  nNumero := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):presupu+1
  cLetra := "X"
  cNumComp := cLetra + STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNumero,8)," ","0")  
ENDIF  
nForma := oApp:oServer:Query("SELECT CODFORMA FROM formapag_temp LIMIT 1"):CODFORMA
nEfecti:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 1"):monto
nTransf:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 2"):monto
nCheque:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 3"):monto
nTarjet:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 4"):monto
nCtaCte:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 5"):monto
nMPago:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 6"):monto

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
      nEfecti := IF(nEfecti + nTarjet + nCheque + nTransf + nMPago > nTotal, nEfecti - ((nEfecti + nTarjet + nCheque + nTransf + nMPago) - nTotal) ,nEfecti)
      // Grabo el registro de PAGOS
      base := oQryPag:GetBlankRow()
      base:numero  := nRecibo
      base:cliente := nCliente
      base:total   := nEfecti + nTarjet + nCheque + nTransf + nMPago
      base:fecha   := DATE()
      base:caja    := oApp:prefijo
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
      base:importe := nEfecti + nTarjet + nCheque + nTransf + nMPago
      oQryPagFac:oRow := base
      oQryPagFac:Save()
      
  
      // Grabo los conceptos pagados
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon (numero,codcon,tipocon,importe,observa) "+;
                           "(SELECT "+ClipValue2Sql(nRecibo)+",codforma,IF(tipopag=6,8,tipopag),"+;
                           "IF(tipopag=1,importe-"+ClipValue2Sql(nVuelto)+",importe),formapag"+;
                           " FROM formapag_temp"+;
                           " WHERE tipopag <> 5 AND tipopag <> 1)")

      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "(SELECT 'FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+",codforma,tipopag,importe,formapag,"+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+" FROM formapag_temp WHERE tipopag <> 1)")

      IF nEfecti > 0
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon (numero,codcon,tipocon,importe,observa) values ("+;
                           ""+ClipValue2Sql(nRecibo)+",1,1,"+;
                           ""+ClipValue2Sql(nEfecti)+",'EFECTIVO')")
      /*oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+",1,1,"+ClipValue2Sql(nEfecti)+",'EFECTIVO',"+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")*/

      //oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
      //                     "(SELECT 'FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+",codforma,tipopag,SUM(importe),formapag,"+;
      //                      ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+" FROM formapag_temp WHERE tipopag = 1 GROUP BY codforma)")                            
      IF oApp:oServer:Query("SELECT SUM(importe) as importe FROM formapag_temp WHERE tipopag = 1"):importe = nEfecti
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "(SELECT 'FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+",codforma,tipopag,SUM(importe),formapag,"+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+" FROM formapag_temp WHERE tipopag = 1 GROUP BY codforma)")                            
         ELSE 
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) "+;
                           "VALUES('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+",1,1,"+ClipValue2Sql(nEfecti)+",'EFECTIVO',"+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
      ENDIF   
      ENDIF
      IF nTransf > 0
        oQryTransf:= oApp:oServer:Query("SELECT * FROM formapag_temp WHERE tipopag = 2")
        oQryTransf:GoTop()
        DO WHILE !oQryTransf:eof()
              nCodCue:= oApp:oServer:Query("SELECT codcue FROM ge_"+oApp:cId+"forpag WHERE codigo = "+ClipValue2Sql(oQryTransf:codforma)):codcue
              IF nCodCue = 0
                 nCodCue:= nCodCue2
                 nNumOpe:= nNumOpe2
                 cObserva1:= cObserva2
              ENDIF
              oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,numope,detalle,usuario,fecmod,ip,importe,codtip) VALUES "+;
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
                            ClipValue2SQL(oQryTransf:importe)+",1)")
              //nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM re_"+oApp:cId+"deposito"):numero 
              nNumDep := oApp:oServer:LastInsertID()
              oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagos SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nRecibo))
              oQryTransf:Skip() 
        ENDDO     
     ENDIF
      
      // GRABO DEUDA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,importe,saldo,estado,"+;
                                                     "nombre,cuit,dni,direccion,localidad,usuario,fecmod,ip,fecvto) "+;
                              " VALUES ('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+","+IF(nCtaCte>=0,"1","0")+",1,"+ClipValue2Sql(DATE())+","+;
                                         ClipValue2Sql(nCliente)+","+ClipValue2Sql(nTotal)+","+;
                                         IF(nCtaCte>=0,ClipValue2Sql(nCtaCte),"0")+","+IF(nCtaCte=0,"'P'","'I'")+","+;
                                         ClipValue2Sql(oQryCliAux:nombre)+","+ClipValue2Sql(oQryCliAux:cuit)+","+;
                                         ClipValue2Sql(oQryCliAux:dni)+","+ClipValue2Sql(oQryCliAux:direccion)+","+ClipValue2Sql(oQryCliAux:localidad)+","+;
                                         ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2SQL(DATE())+")")
      //-- DETALLE DE IVA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventivadet (tipocomp,letra,numfac,codiva,neto,iva) "+;
                           "(SELECT 'FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+;
                            ", codiva, SUM(stotal) AS neto,SUM(iva) AS iva FROM VENTAS_DET_H1 GROUP BY codiva)")
      //-- detalle de venta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
                        " (codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,codiva,neton,descu,pcosto,impint) "+;
                        " (SELECT codart,detart,cantidad,punit,"+ClipValue2Sql(DATE())+","+ClipValue2Sql(nCliente)+","+;
                        "         'FC"+cLetra+cNumComp+"',ptotal, stotal,iva,codiva,neto,descuento,pcosto,impint FROM VENTAS_DET_H1)")

      IF oApp:usar_puntos
         nPuntosAcu := oApp:oServer:Query("SELECT puntos FROM ge_"+oApp:cId+"clientes  WHERE codigo = "+ClipValue2Sql(nCliente) ):puntos
         nPuntosAcu := nPuntosAcu + INT(nTotal/oApp:pesos_x_punto)
         nPuntos :=  INT(nTotal/oApp:pesos_x_punto)
      ENDIF
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,fecha,neto,iva,importe,tipopag,observa,"+;
                                                      "nombre,cuit,dni,direccion,localidad,usuario,fecmod,ip,coniva,condven,formapag,cae,fecvto,tipfor,sobretasa,hora,puntos,puntosacu) VALUES "+;
                           "('FC',"+ClipValue2Sql(cLetra)+","+ClipValue2Sql(cNumComp)+","+ClipValue2Sql(nCliente)+","+;
                            ClipValue2Sql(DATE())+","+ClipValue2Sql(oBrwDet:aCols[7]:nTotal)+","+ClipValue2Sql(oBrwDet:aCols[8]:nTotal)+","+;
                            ClipValue2Sql(nTotal)+",1,'PUNTO DE VENTA "+IF(nDescu>0," Dto: %"+ALLTRIM(STR(nDescu,6,2)),"")+"',"+;
                            ClipValue2Sql(IF(nCliente<=1,ALLTRIM(cCliente)+" "+ALLTRIM(oQryCliAux:nombre),oQryCliAux:nombre))+;
                            ","+ClipValue2Sql(oQryCliAux:cuit)+","+;
                            ClipValue2Sql(oQryCliAux:dni)+","+ClipValue2Sql(oQryCliAux:direccion)+","+ClipValue2Sql(oQryCliAux:localidad)+","+;
                            ClipValue2Sql(oApp:usuario)+","+ClipValue2SQL(DATE())+","+ClipValue2SQL(oApp:cIp)+","+ClipValue2SQL(nCondicion)+;
                            ",1,"+ClipValue2Sql(nForma)+","+;
                            ClipValue2Sql(cCae)+","+ClipValue2Sql(dFecVtoC)+","+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+;
                            ","+ClipValue2Sql(oBrwDet:aCols[11]:nTotal)+",CURTIME()"+;
                            ","+Clipvalue2sql(nPuntos)+","+ClipValue2Sql(nPuntosAcu) +")")     

      IF oApp:usar_puntos
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos + "+ClipValue2Sql(INT(nTotal/oApp:pesos_x_punto)) +;
          " WHERE codigo = "+ClipValue2Sql(nCliente))
      ENDIF
      IF nDescu > 0
         Auditar(6," FC"+cLetra+cNumcomp+" "+alltrim(STR(nDescu,6,2))+"% Caja "+STR(oApp:prefijo,4))
      ENDIF
/*
      //ACTUALIZO EL STOCK DE LOS ARTICULOS VENDIDOS
      oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                           "SET a.stockact = a.stockact - v.cantidad WHERE v.codart > 0 ")
*/
      //oApp:oServer:Execute("UPDATE  ge_"+oApp:cId+"articu a SET a.stockact = a.stockact - "+;
      //                     "(SELECT SUM(v.cantidad) FROM VENTAS_DET_H1 v WHERE v.codart = a.codigo GROUP BY v.codart ) ")
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
               "INNER JOIN "+; 
               "("+; 
               "SELECT codart, SUM(cantidad) as suma "+;
               "FROM VENTAS_DET_H1 "+;
               "WHERE ESPROMO IS FALSE "+;
               "GROUP BY codart "+;
               ") v ON a.codigo = v.codart "+;
               "SET a.stockact = a.stockact - v.suma WHERE a.stockotro IS FALSE")
      // Actualizo el stock de los que descuentan de otros articulos
      /*oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                     "d.codart AS codart FROM VENTAS_DET_H1 d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE a.stockotro = TRUE GROUP BY d.codart ")
      oQryStock:GoTop()
      DO WHILE !oQryStock:EOF()
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                              " ON m.codigo = r.codusa "+;
                              "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                              "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
         oQryStock:Skip()
      ENDDO*/
      cSQL := "UPDATE ge_"+oApp:cId+"articu m " + ;
        "JOIN ( " + ;
        "  SELECT r.codusa AS codigo_usado, SUM(d.cantidad * r.cantidad) AS total_a_restar " + ;
        "  FROM VENTAS_DET_H1 d " + ;
        "  JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart " + ;
        "  JOIN ge_"+oApp:cId+"reseta r ON r.codart = d.codart " + ;
        "  WHERE a.stockotro = TRUE AND d.ESPROMO IS FALSE " + ;
        "  GROUP BY r.codusa " + ;
        ") AS t ON t.codigo_usado = m.codigo " + ;
        "SET m.stockact = m.stockact - t.total_a_restar"

      oApp:oServer:Execute( cSQL )


      IF lFisc       
         IF cLetra = "A"
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturaa = "+ClipValue2Sql(nNumero)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))
         ELSE  
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturab = "+ClipValue2Sql(nNumero)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))          
         ENDIF 
      ELSE         
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET presupu = presupu+1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
      ENDIF   
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab_p WHERE id = "+ClipValue2Sql(nId))
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det_p   WHERE numven = "+ClipValue2Sql(nId))     
      oApp:oServer:CommitTransaction()
      lSaleX := .t.
 CATCH oErr
    MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN .F.
 END TRY
IF !lFisc
   IF oQryPar:pregunta_ticket
        IF MsgYesNo("¿Desea imprimir el ticket no fiscal?","Atencion!")
          FacturaNoFiscal('FC',cLetra+cNumComp)
        ENDIF
      ELSE   
      FacturaNoFiscal('FC',cLetra+cNumComp)
   ENDIF
   ELSE 
   IF oQryPun:tipofac = 1
      PrintFactuElec('FC',cLetra+cNumComp) 
   ENDIF
ENDIF
oQryPendi:Refresh()
oBrwPendi:Refresh()
RETURN .t.
**********************************************************************************************
***** CALCULAR IMPORTE FINAL
STATIC FUNCTION CalcTot()
LOCAL oQryAux1
CrearTemporales()
oBrwDet:MakeTotals()
oQryAux1:= oApp:oServer:Query("SELECT SUM(IF(descuento > 0,descuento,0)) AS descu,SUM(IF(descuento < 0,descuento,0)) AS recar "+;
                              "FROM VENTAS_DET_H1")
oGet[08]:cText:= oQryAux1:descu 
oGet[09]:cText:= ABS(oQryAux1:recar)
oGet[06]:cText:= ROUND(oBrwDet:aCols[9]:nTotal,2)
oGet[06]:Refresh()
oGet[08]:Refresh()
RETURN .t.

**********************************************************************************************************************
******* ANULA LA VENTA Y REINICIA 
STATIC FUNCTION Reiniciar()
CrearTemporales()
oGet[01]:cText:=1
oGet[02]:cText:=0
oGet[03]:cText:=0
oGet[07]:cText:=SPACE(30)
nDescu:=0
cCliente:="CONSUMIDOR FINAL"
nCliente:=1
nCondicion:= 5
nLista:= 1
nLisPre:= 0
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
oGet[10]:Set(1)
RETURN nil

*************************************************************************************************
*** AGREGO ARTICULO AL DETALLE
STATIC FUNCTION AgregarArticu(nCodArt)
LOCAL oQryAux, nPtotal:=0,nNeto1:=0,nImpIva2:=0,nNeto2:=0,nImpIva1:=0,oQryIva,nDescuento,nPrecioVen,oQryPrecio,;
      nIvaPes,nSubTotal,nCodIva1,nTotalcIva,nPrecio1,nPrecio2,lRta:=.f.,nDescMar,nTotalPesado:=0,lPesado:=.f.,;
      nImpInt
IF lConsulta
   lConsulta:= .f.
   RETURN .f.
ENDIF
IF oQryDet:nRecCount = 0
   IF !ValidarSaldoCaja()   
      RETURN .f.
   ENDIF 
ENDIF   
IF nCodArt >= 0


   IF nCodArt = 0
      RETURN .t.
   ENDIF

   IF nCodArt > 2000000000000 .and. nCodArt < 3000000000000 //VERIFICO SI ES UN PESADO
      IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = " + ClipValue2Sql(nCodArt)):nRecCount = 0
          nTotalPesado := VAL(SUBSTR(STR(nCodArt,13),8,5)) / 1000 //GUARDO LA CANTIDAD PESADO
          nCodArt := VAL(LEFT(STR(nCodArt,13),7))  //TRUNCO LA PARTE DEL CODIGO 
          lPesado := .t.
      ENDIF
   ENDIF
   
   oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = " + ClipValue2Sql(nCodArt))
   IF oQryAux:RecCount() = 0
      oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigopro = " + ClipValue2Sql(alltrim(str(nCodArt))))
      IF oQryAux:RecCount() = 0
        SndPlaySound("ringin.wav",1)
        MsgWait("Articulo no encontrado","Error",1)
        RETURN .f.
        ELSE 
        nCodArt := oQryAux:codigo 
      ENDIF  
   ENDIF
   // Si tiene lista de precios especiales
   oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+" AND "+;
                              "codart = "+ClipValue2Sql(oQryArt:codigo))
   IF oQryPrecio:RecCount() = 0
       nPrecioVen:= IF(nLista=1,oQryAux:precioven,oQryAux:reventa)
   ELSE
       nPrecioVen:= oQryPrecio:precio 
   ENDIF
   nPrecioVen:= nPrecioVen * (1+(aFormaInc[nFormaPago]/100))
   IF lPesado  //SI ES UN PESADO CALCULO LA CANTIDAD DEPENDIENDO DEL TOTAL
     nCantidad := nTotalPesado /* IF(nLista=1,oQryAux:precioven,oQryAux:reventa)*/
     nCantidad := round(nCantidad,3)
     IF !oQryAux:pesable
        nCantidad := nCantidad * 1000
     ENDIF
   ENDIF
   
   IF nCodArt = 0 
      RETURN .t.
   ENDIF
   IF nCantidad = 0
      MsgStop("Ingrese una cantidad válida","Error")
      RETURN .t.
   ENDIF   


   IF oApp:usar_dias_precio
    IF oQryAux:fecmod < (DATE()- oApp:dias_precio)
      MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
              "Verifique la fecha de modificacion","Atencion!")
      RETURN .f.
    ENDIF
  ENDIF

   IF oQryAux:pesable .and. !lPesado  //SI ES UN ARTICULO PESABLE PIDO QUE INGRESE LA CANTIDAD A FACTURAR
      oGet[07]:cText:= oQryAux:nombre
      IF !PedirCantidad(nPrecioVen)
         RETURN .f.
      ENDIF
   ENDIF

   /*IF oQryPun:pidestock = 1 .and. oQryAux:stockact-nCantidad < 0 .and. !oQryAux:stockotro
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad ¿Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF      
      oBrwDet:SetFocus()
      oGet[02]:SetFocus()
  ENDIF
  IF oQryPun:pidestock = 2 .and. oQryAux:stockact-nCantidad < 0 .and. !oQryAux:stockotro
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryAux:stockact)),"Atencion")
     RETURN .F.
  ENDIF
  IF oQryPun:pidestock < 3 .and. oQryAux:stockmin > 0 .and. oQryAux:stockact-nCantidad  < oQryAux:stockmin .and. !oQryAux:stockotro
     MsgAlert("Se esta quedando sin stock, llego al stock minimo","Atencion")    
     oDlg1:SetFocus() 
     oGet[02]:SetFocus()
  ENDIF*/
  IF !ValidarCantidad(nCodart,nCantidad)
     RETURN nil 
  ENDIF

   nDescMar:= oApp:oServer:Query("SELECT descuento FROM ge_"+oApp:cId+"desccli WHERE codmar ="+ClipValue2Sql(oQryAux:marca)+" AND "+;
                                 "codcli ="+ClipValue2Sql(nCliente)):descuento
   IF EMPTY(nDescMar) 
      nDescMar :=0
   ENDIF
   CrearTemporales()
   oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryAux:iva))
   nCodIva1 := oQryAux:iva
   nPrecio2:= (nPrecioVen * IF(oQryAux:endolares,oQryPar:dolar,1)) * nCantidad
   nPrecio2 := nPrecio2 - oQryAux:impint * nCantidad
   nDescuento:= nPrecio2 * (IF(nDescMar>0,nDescMar,nDescu)/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
   nSubTotal:= nPrecio1 - nIvaPes   
   nTotalcIva := nPrecio1 + (oQryAux:impint*nCantidad)

   //Valido el costo y aviso   
   IF oQryPun:validacosto = 1
      IF oQryAux:preciocos > (nTotalcIva/nCantidad) * IF(oQryAux:endolares,oQryPar:dolar,1) +1
          lRta:=MsgYesNo("El precio que está facturando está por debajo,"+CHR(10)+;
              "del costo del producto ¿Desea continuar?"+CHR(10)+;
              "Costo: "+ALLTRIM(STR(oQryAux:preciocos)),"Atencion")
          IF !lRta 
             RETURN .f.
          ENDIF      
          oBrwDet:SetFocus()
          oGet[02]:SetFocus()
      ENDIF 
   ENDIF
   //Prohibo la venta por costo menor a venta
   IF oQryPun:validacosto = 2
      IF oQryAux:preciocos > (nTotalcIva/nCantidad) * IF(oQryAux:endolares,oQryPar:dolar,1) +1
          MsgStop("No puede facturar el articulo seleccionado porque el "+CHR(10)+;
             "precio está por debajo del costo"+CHR(10)+;
             "Costo: "+ALLTRIM(STR(oQryAux:preciocos)),"Atencion")
          RETURN .F.
      ENDIF
   ENDIF

   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto,impint) "+;
                         "VALUE ( "+ClipValue2Sql(nCodArt)+","+;
                                 ClipValue2Sql(oQryAux:nombre)+","+;
                                 ClipValue2Sql(nCantidad)+","+;
                                 ClipValue2Sql(nPrecioVen * IF(oQryAux:endolares,oQryPar:dolar,1))+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio1-nIvaPes)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva1)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(nSubTotal)+","+;
                                 ClipValue2Sql(oQryAux:preciocos)+","+;
                                 ClipValue2Sql(oQryAux:impint*nCantidad)+;
                         " )" ) 
   oGet[02]:SetFocus()
ELSE
   //oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos WHERE codigo = " + ClipValue2Sql(ABS(nCodArt)))
   IF nPrecio = 0
      oGet[03]:SetFocus()
      RETURN nil
   ENDIF
   IF nPrecio < 0
      MsgStop("Precio negativo, no puede facturar!","Error")
      oGet[03]:SetFocus()
      RETURN nil
   ENDIF

   IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos WHERE codigo = " + ClipValue2Sql(ABS(nCodArt))):nRecCount = 0
      MsgStop("El departamento no existe","Error")
      oGet[02]:SetFocus()
      RETURN nil
   ENDIF   

   oQryAux:= oApp:oServer:Query("SELECT d.*,i.tasa FROM ge_"+oApp:cId+"deptos d "+;
                                " LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = d.iva "+;
                                " WHERE d.codigo = " + ClipValue2Sql(ABS(nCodArt)))
   nPrecio1 := nPrecio / (1+oQryAux:porcenbase/100)
   /*oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto) "+;
                         "VALUE ( "+ClipValue2Sql(nCodArt)+","+;
                                    ClipValue2Sql(oQryAux:nombre)+","+;
                                    ClipValue2Sql(nCantidad)+","+;
                                    ClipValue2Sql(nPrecio)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad/1.21)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad-nPrecio*nCantidad/1.21)+","+;
                                    ClipValue2Sql(5)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad/1.21)+","+;
                                    ClipValue2Sql(nPrecio1)+;
                          " )" )*/

   oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto) "+;
                         "VALUE ( "+ClipValue2Sql(nCodArt)+","+;
                                    ClipValue2Sql(oQryAux:nombre)+","+;
                                    ClipValue2Sql(nCantidad)+","+;
                                    ClipValue2Sql(nPrecio)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad/(1+oQryAux:tasa/100))+","+;
                                    ClipValue2Sql(nPrecio*nCantidad-nPrecio*nCantidad/(1+oQryAux:tasa/100))+","+;
                                    ClipValue2Sql(oQryAux:iva)+","+;
                                    ClipValue2Sql(0)+","+;
                                    ClipValue2Sql(nPrecio*nCantidad/(1+oQryAux:tasa/100))+","+;
                                    ClipValue2Sql(nPrecio1)+;
                          " )" )
    oGet[02]:SetFocus()
ENDIF
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
oBrwDet:GoBottom()
nCantidad:=1
nPrecio:=0
oGet[02]:cText:=0
oGet[07]:cText:=SPACE(30)
oGet[01]:Refresh()
oGet[02]:Refresh()
oGet[03]:Refresh()
nTotal := ROUND(oBrwDet:aCols[9]:nTotal,2)
RETURN nil

**************************************************************************************************
****** PEDIR QUE INGRESE LA CANTIDAD SI ES UN PESABLE 
STATIC FUNCTION PedirCantidad(nPre)
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(2),oBot1,oBot2,lRta:=.f.,nCantTemp:=0, nPrecio := 0

DEFINE DIALOG oDlgD TITLE "Ingresar cantidad del articulo pesable a facturar" OF oDlg1 FROM 05,15 TO 14,65
  acor := AcepCanc(oDlgD)
  

   @ 12, 05 SAY "Cantidad:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1[1] VAR nCantTemp OF oDlgD PIXEL PICTURE "9999.999" RIGHT;
                 VALID((oGet1[2]:cText:= ROUND(nCantTemp*nPre,2)) <> 'xxx')


   @ 27, 05 SAY "Precio:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 25, 50 GET oGet1[2] VAR nPrecio OF oDlgD PIXEL PICTURE "99999999.99" RIGHT;
                 VALID((oGet1[1]:cText:= ROUND(nPrecio /nPre,3)) <> 'xxx');
                 WHEN ("M"$cPermi) 

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[1]:SetFocus
IF !lRta
   RETURN .f.
ENDIF
IF nCantTemp = 0
   RETURN .f.
ENDIF
nCantidad:= nCantTemp
oGet[06]:SetFocus()
RETURN .t.

STATIC FUNCTION Convierte(nPrecio,nPre,oGet)
IF nPrecio = 0
   RETURN .t.
ENDIF 
IF nPrecio < 0
   RETURN .t.
ENDIF 
oGet:cText := ROUND(nPrecio / nPre,3)
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
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(3),oBot1,oBot2,lRta:=.f.,nDescTemp:=0,nOpcion:=1,;
      aTipos:={"Descuento","Recargo"}, lSoloPuntual := .f., nDescuPun, oFont
DEFINE FONT oFont   NAME "ARIAL" SIZE 0,-10
DEFINE DIALOG oDlgD TITLE "Aplicar descuentos a la venta" OF oDlg1 FROM 05,15 TO 13,55 FONT oFont
  acor := AcepCanc(oDlgD)
  

   @ 12, 05 SAY "Porcentaje:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1[1] VAR nDescTemp OF oDlgD PIXEL PICTURE "999.99" RIGHT
   @ 10, 80 COMBOBOX oGet1[2] VAR nOpcion ITEMS aTipos OF oDlgD PIXEL SIZE 40,12
   @ 25, 05 CHECKBOX oGet1[3] VAR lSoloPuntual PROMPT "Aplicar solo a articulo seleccionado" SIZE 90,12 PIXEL

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[1]:SetFocus
RELEASE oFont
IF !lRta
   RETURN .f.
ENDIF
IF !lSoloPuntual
    IF nOpcion = 1
       nDescu:= nDescTemp
    ELSE
       nDescu:= -nDescTemp
    ENDIF 
    CrearTemporales()
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                         "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                         "SET v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100),"+;
                             "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                             "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                             "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                             "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)")
    IF oApp:oServer:Query("SELECT * FROM VENTAS_DET_H1 WHERE pcosto > (ptotal/cantidad)+1"):nRecCount > 0
       IF oQryPun:validacosto = 1
          lRta:=MsgYesNo("El descuento aplicado deja por debajo,"+CHR(10)+;
                  "del costo a producto ¿Desea continuar?","Atencion")
          IF !lRta
             oApp:oServer:RollBack()
          ENDIF
       ENDIF
       IF oQryPun:validacosto = 2
          MsgStop("No puede aplicar decuento seleccionado porque el "+CHR(10)+;
                 "precio deja por debajo del costo a productos","Atencion")
          oApp:oServer:RollBack()
       ENDIF
       oApp:oServer:CommitTransaction()
    ENDIF 
    ELSE 
    IF nOpcion = 1
       nDescuPun:= nDescTemp
    ELSE
       nDescuPun:= -nDescTemp
    ENDIF 
    CrearTemporales()
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                         "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                         "SET v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100),"+;
                             "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100)))/(1+i.tasa/100)),"+;
                             "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100)))/(1+i.tasa/100),"+;
                             "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100))),"+;
                             "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescuPun)+"/100)))/(1+i.tasa/100)"+;
                             " WHERE v.id = " + STR(oQryDet:id))
    IF oApp:oServer:Query("SELECT * FROM VENTAS_DET_H1 WHERE pcosto > (ptotal/cantidad)+1"):nRecCount > 0
       IF oQryPun:validacosto = 1
          lRta:=MsgYesNo("El descuento aplicado deja por debajo,"+CHR(10)+;
                  "del costo a producto ¿Desea continuar?","Atencion")
          IF !lRta
             oApp:oServer:RollBack()
          ENDIF
       ENDIF
       IF oQryPun:validacosto = 2
          MsgStop("No puede aplicar decuento seleccionado porque el "+CHR(10)+;
                 "precio deja por debajo del costo a productos","Atencion")
          oApp:oServer:RollBack()
       ENDIF
       oApp:oServer:CommitTransaction()
    ENDIF 
ENDIF
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
DO WHILE .T.
DEFINE DIALOG oDlgC RESOURCE "CLIE" OF oDlg1
  oDlgC:lHelpIcon := .f.

  REDEFINE GET oGet1 VAR nClient OF oDlgC ID 101 PICTURE "999999";
               VALID(BuscarArt(oQryCli,oDlgC,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, BuscarArt(oQryCli,oDlgC,oGet1,oGet2)) BITMAP "BUSC1"
  REDEFINE GET oGet2 VAR cNomCli OF oDlgC ID 102 PICTURE "@!" WHEN(.F.)

  REDEFINE BUTTON oBot1 ID 201 OF oDlgC ACTION(AltaCli(oDlgC))
  REDEFINE BUTTON oBot2 ID 202 OF oDlgC ACTION(lRta:=.t.,oDlgC:End())
  REDEFINE BUTTON oBot2 ID 203 OF oDlgC ACTION(oDlgC:End())

ACTIVATE DIALOG oDlgC CENTER ON INIT oGet1:SetFocus() 
IF !lRta
   RETURN nil
ENDIF
IF oQryCli:zona = "2"
   MsgStop("El cliente esta inhabilitado para facturar","Error")
   LOOP
ENDIF
EXIT
ENDDO

cCliente:=cNomCli
nCliente:=nClient
nCondicion:= oQryCli:coniva
nLista:= oQryCli:lispre
nLisPre:= oQryCli:lispreesp
nAntes:= oApp:oServer:Query("SELECT SUM(IF(tipo='NC',saldo*(-1),saldo)) AS antes FROM ge_"+oApp:cId+"ventas_cuota "+;
                            "WHERE cliente = "+ClipValue2Sql(nCliente)):antes
nDescu:= oQryCli:descuento
/*
oApp:oServer:Execute("UPDATE VENTAS_DET_H1 v LEFT JOIN ge_"+oApp:cId+"ivas i  ON i.codigo = v.codiva "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                     "SET v.descuento = (v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100),"+;
                         "v.iva =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))-(((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)),"+;
                         "v.stotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100),"+;
                         "v.ptotal = ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100))),"+;
                         "v.neto =  ((v.cantidad * v.punit) - ((v.cantidad * v.punit) * ("+ClipValue2Sql(nDescu)+"/100)))/(1+i.tasa/100)")
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()*/
ActualizarDet()
RETURN nil

******************************************************************************************************
****************** ALTA DE clientes
STATIC FUNCTION AltaCli(oDlgC)
LOCAL oDlgA,oQry,oGet:=ARRAY(27),;
      oBot1,oBot2,mrta:=.f.,base,acor:=ARRAY(4),oError, nCuit := 0, oGet5,;
      aListas:={"Lista 1","Lista 2"},cLisPre:="SIN LISTA ESPECIAL"+SPACE(31),lCambiar := .t.,;
      oQryLisPre:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre"),;
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
"10  IVA Liberado Ley Nº 19.640",;
"11  IVA Responsable Inscripto Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social"},;
oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))

oQry  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY NOMBRE")
base := oQry:GetBlankRow()
base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"clientes")  
base:coniva:=5
DO CASE
   CASE oQryP:lispreclientepos = 0
        base:lispre:=1
   CASE oQryP:lispreclientepos = 1
        base:lispre:=1
   CASE oQryP:lispreclientepos = 2
        base:lispre:=2
ENDCASE 
DO WHILE .T.
DEFINE DIALOG oDlgA TITLE "Alta de Clientes" FROM 05,10 TO 26,80 OF oDlgC
   acor := AcepCanc(oDlgA)
  
   @ 07, 05 SAY "Codigo:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Direccion:"      OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Telefono:"       OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Localidad:"      OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 82, 05 SAY "C.U.I.T.:"       OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 82,125 SAY "D.N.I.:"         OF oDlgA PIXEL SIZE 60,12 RIGHT
   @ 97, 05 SAY "Condicion IVA:"  OF oDlgA PIXEL SIZE 60,12 RIGHT
   @112, 05 SAY "Lista de precios:" OF oDlgA PIXEL SIZE 50,12 RIGHT
   @127, 05 SAY "Lista especial:"   OF oDlgA PIXEL SIZE 50,12 RIGHT
   @07, 90 SAY "CUIT Afip:"   OF oDlgA PIXEL SIZE 28,12 RIGHT
   @05,121 GET oGet[5] VAR nCuit PICTURE "99999999999"   OF oDlgA PIXEL SIZE 45,12 RIGHT;
      VALID(ConsultaCuit(nCuit,oGet,{2,3,7,10,11},@lCambiar))
   @ 05, 70 GET oGet[1] VAR base:codigo PICTURE "99999" OF oDlgA PIXEL WHEN(.F.)
   @ 20, 70 GET oGet[2] VAR base:nombre PICTURE "@!"  OF oDlgA PIXEL VALID(base:nombre<>SPACE(30))
   @ 35, 70 GET oGet[3] VAR base:direccion OF oDlgA PIXEL
   @ 50, 70 GET oGet[4] VAR base:telefono  OF oDlgA PIXEL
   @ 65, 70 GET oGet[7] VAR base:localidad OF oDlgA PIXEL
   @ 80, 70 GET oGet[10] VAR base:cuit     PICTURE "99-99999999-9" ;
         VALID(ValidaCuit(base:cuit)) OF oDlgA PIXEL
   @ 80,200 GET oGet[6]  VAR base:dni      PICTURE "99999999"  OF oDlgA PIXEL RIGHT
   @ 95, 70 COMBOBOX oGet[11] VAR base:coniva  ITEMS aTipoIva SIZE 80,80 PIXEL OF oDlgA WHEN(lCambiar)
   @110, 70 COMBOBOX oGet[19] VAR base:lispre ITEMS aListas OF oDlgA SIZE 40,40 PIXEL WHEN("A"$cPermi  .and. oQryP:lispreclientepos = 0)
   @125, 70 GET oGet[22] VAR base:lispreesp  OF oDlgA PICTURE "999" SIZE 25,12 RIGHT PIXEL WHEN("A"$cPermi  .and. oQryP:lispreclientepos = 0);
                 VALID((base:lispreesp = 0 .and. IF(base:lispreesp=0,(oGet[23]:cText:="SIN LISTA ESPECIAL"+SPACE(31))<>"xxx",.T.)) .or.;
                       Buscar(oQryLisPre,oDlg1,oGet[22],oGet[23]));
                 ACTION (oGet[22]:cText:= 0, Buscar(oQryLisPre,oDlg1,oGet[22],oGet[23])) BITMAP "BUSC1"
   @125,100 GET oGet[23] VAR cLisPre OF oDlgA PIXEL PICTURE "@!" SIZE 150,12 WHEN(.F.)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlgA SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlgA:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgA CENTER 
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
//Validar si el cuit es repetido
IF base:cuit <> "  -        - "
   IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"clientes WHERE codigo <> "+str(base:codigo)+;
         " AND cuit = "+ClipValue2SQL( base:cuit)):nRecCount > 0
      mRta := MsgNoYes("Ya existe un cliente con ese cuit, continua igual?","Atencion")
      IF !mRta 
         LOOP
      ENDIF
   ENDIF
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
**********COBRO 
STATIC FUNCTION ElijeFormPag()
LOCAL oDlgC,oBot1:=ARRAY(26),oGet1:=ARRAY(3),oError,oBrwPag,nMonto:=((nTotal-nPagado)+nVuelto),oFontF,oFontBot,;
      nVueltoT:=nVuelto,nPagadoT:=nPagado,lRta:=.f.
oQryPag:= oApp:oServer:Query("SELECT * FROM formapag_temp")
DEFINE FONT oFontF   NAME "ARIAL" SIZE 11,-15
DEFINE FONT oFontBot NAME "TAHOMA" SIZE 4,-11 BOLD
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

   REDEFINE BTNBMP oBot1[01] OF oDlgC ID 201 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[01],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[02] OF oDlgC ID 202 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[02],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[03] OF oDlgC ID 203 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[03],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[04] OF oDlgC ID 204 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[04],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[05] OF oDlgC ID 205 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[05],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[06] OF oDlgC ID 206 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[06],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[07] OF oDlgC ID 207 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[07],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[08] OF oDlgC ID 208 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[08],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[09] OF oDlgC ID 209 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[09],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))
   REDEFINE BTNBMP oBot1[10] OF oDlgC ID 210 2007 CENTER WHEN(nMonto > 0) FONT oFontBot;
            ACTION(AgregarConcepto(oBot1[10],oBrwPag,oQryPag,oGet1[1]),IF(oGet1[1]:value>0,oGet1[01]:SetFocus(),oBot[26]:SetFocus()))


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
   
   REDEFINE BTNBMP oBot[26] ID 401 OF oDlgC PROMPT "Aceptar [F12]" 2007 CENTER ACTION(lRta:=.t.,oDlgC:End())
   *REDEFINE BTNBMP oBot[26] ID 402 OF oDlgC 2007 CENTER ACTION(lRta:=.f.,oDlgC:End()) 
   REDEFINE BTNBMP oBot[27] ID 403 OF oDlgC 2007 CENTER ;
                   ACTION(oQryPag:Delete(),oBrwPag:Refresh(),oBrwPag:MakeTotals(),;
                          oGet1[1]:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0),oGet1[1]:SetFocus()) WHEN(oQryPag:RecCount() > 0)
   oDlgC:bKeyDown = { | nKey, nFlags | (oGet1[1]:assign(),IF(nKey==113,oBot1[01]:Click,;
                                       IF(nKey==114,oBot1[02]:Click,;
                                       IF(nKey==115,oBot1[03]:Click,;
                                       IF(nKey==116,oBot1[04]:Click,;
                                       IF(nKey==117,oBot1[05]:Click,;
                                       IF(nKey==118,oBot1[06]:Click,;
                                       IF(nKey==123,oBot[26]:Click,.F.))))))))}
ACTIVATE DIALOG oDlgC CENTER ON INIT (PoneFormas(oBot1)) VALID ((nPagadoT:=oBrwPag:aCols[2]:nTotal) >=0)
IF !lRta
    RETURN nil 
ENDIF
IF ROUND(oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag <> 1"):monto,2) > ROUND(nTotal,2) 
   MsgStop("Las formas de pago son mayores al total de la venta","Imposible continuar")
   oApp:oServer:Execute("DELETE FROM formapag_temp")
   nVuelto:= 0
   nPagado:= 0
   ELSE 
   nVuelto:= nVueltoT
   nPagado:= nPagadoT
ENDIF
oGet[04]:Refresh()
oGet[05]:Refresh()
RELEASE FONT oFontBot
RELEASE FONT oFontF
RETURN nil  

********************************************************************************************
*********
STATIC FUNCTION AgregarConcepto(oBoton,oBrwPag,oQryPag,oGet1)
LOCAL nRenglon, cTexto, n,;
      oQryForPag:= oApp:oServer:Query("SELECT codigo,nombre,tipo FROM ge_"+oApp:cId+"forpag WHERE tactil = TRUE ORDER BY codigo")
IF oBoton:cargo > 0
    IF oBoton:nLastRow = 5 .and. nCliente < 2
       MsgStop("Consumidor final no puede pagar en Cta.Cte.","Error")
       RETURN nil 
    ENDIF
    nRenglon:= oApp:oServer:GetAutoIncrement("formapag_temp")
    cTexto := IF('[F'$oBoton:cCaption,LEFT(oBoton:cCaption,LEN(oBoton:cCaption)-4),ALLTRIM(oBoton:cCaption))
    oApp:oServer:Execute("INSERT INTO formapag_temp (RENGLON,CODFORMA,TIPOPAG,FORMAPAG,IMPORTE) VALUES "+;
                         "("+ClipValue2Sql(nRenglon)+","+ClipValue2Sql(oBoton:cargo)+","+ClipValue2Sql(oBoton:nLastRow)+","+;
                          ClipValue2Sql(cTexto)+","+ClipValue2Sql(oGet1:value)+")")
    oQryPag:Refresh()
    oBrwPag:Refresh()
    oBrwPag:MakeTotals()
    oGet1:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)
    ELSE 
    n := Val(oGet1:cText)
    oGet1:cText := 0
    Buscar(oQryForPag,oBoton,oGet1)
    nRenglon:= oApp:oServer:GetAutoIncrement("formapag_temp")
    cTexto := oQryForPag:nombre
    oGet1:cText := n
    oApp:oServer:Execute("INSERT INTO formapag_temp (RENGLON,CODFORMA,TIPOPAG,FORMAPAG,IMPORTE) VALUES "+;
                         "("+ClipValue2Sql(nRenglon)+","+ClipValue2Sql(oQryForPag:codigo)+","+ClipValue2Sql(oQryForPag:tipo)+","+;
                          ClipValue2Sql(cTexto)+","+ClipValue2Sql(oGet1:value)+")")
    oQryPag:Refresh()
    oBrwPag:Refresh()
    oBrwPag:MakeTotals()
    oGet1:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)
ENDIF
RETURN nil


***************************************************************************************
**********
STATIC FUNCTION PoneFormas(oBot1)
LOCAL oQryForPag,i, cF
oQryForPag:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"forpag WHERE tactil = TRUE ORDER BY codigo")
oQryForPag:GoTop()
FOR i:= 1 TO 10
       cF := IF(i<7 .and. !oQryForPag:Eof(),' [F'+STR(i+1,1)+']','')
       oBot1[i]:cCaption:= IF(oQryForPag:Eof()," ",ALLTRIM(oQryForPag:nombre)+cF)
       oBot1[i]:cargo:= IF(oQryForPag:Eof(),0,oQryForPag:codigo)
       oBot1[i]:nLastRow:= IF(oQryForPag:Eof(),0,oQryForPag:tipo)
       oBot1[i]:Refresh()
       IF oQryForPag:Eof()
          oBot1[i]:Hide()
       ENDIF 
       oQryForPag:Skip()
NEXT i
IF oQryForPag:nRecCount > 10 
   oBot1[10]:cCaption := '(Mas Formas)'
   oBot1[10]:nLastRow := 0
   oBot1[10]:cargo := 0
ENDIF   
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
  

STATIC FUNCTION FactDept(oWnd,oFont)
LOCAL oQryDep
LOCAL oDlgA,;
      oBot1,oBot2,mrta:=.f.,acor:=ARRAY(4), nCodDep := 0, cNomDep := SPACE(30), nImporte := 0,;
      oBot, x, y, i, bAction
oQryDep:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos  ORDER BY nombre")
oBot := ARRAY(oQryDep:nRecCount)
DEFINE DIALOG oDlgA TITLE "DEPARTAMENTOS" FROM 05,10 TO 42,110 OF oWnd FONT oWnd:oFont
   acor := AcepCanc(oDlgA)
   oDlgA:lHelpIcon := .f.
   @ 07, 05 SAY "Depto Elegido:"       OF oDlgA PIXEL SIZE 45,12 RIGHT 
   @ 10, 60 SAY oGetDep1 VAR nCodDep   OF oDlgA PIXEL SIZE 45,18 RIGHT FONT oFont
   @ 10,140 SAY oGetDep2 VAR cNomDep   OF oDlgA PIXEL SIZE 220,18 FONT oFont
   @ 42, 05 SAY "Importe:"        OF oDlgA PIXEL SIZE 80,18 RIGHT FONT oFont
   
   /*@ 05, 90 GET oGet1 VAR nCodDep OF oDlgA PIXEL PICTURE "999" RIGHT SIZE 45,12 ;
                VALID(Buscar(oQryDep,oDlgA,oGet1,oGet2));
                ACTION (oGet1:cText:= 0, Buscar(oQryDep,oDlgA,oGet1,oGet2)) BITMAP "BUSC1"    
   @ 05,140 GET oGet2 VAR cNomDep PICTURE "@!" OF oDlgA PIXEL WHEN(.F.) SIZE 220,12*/
   @ 40, 90 GET oGetDep3 VAR nImporte PICTURE "99999999.99"  OF oDlgA PIXEL RIGHT SIZE 95,22 FONT oFont
   oQryDep:GoTop()
   x := 65
   y := 05
   i := 1
   DO WHILE !oQryDep:Eof()
      bAction := "{ |  | PoneDept1("+STR(oQryDep:codigo)+", '"+ALLTRIM(oQryDep:nombre)+"') }"
      bAction := &bAction
      @ x, y BTNBMP oBot[i] PROMPT ALLTRIM(LEFT(oQryDep:nombre,20)) SIZE 60,30 OF oDlgA PIXEL ;
              CENTER NOBORDER 2007 
      oBot[i]:bAction := bAction
      oQryDep:Skip()
      i++
      y := y + 65 
      IF y > 350
         y := 05
         x := x + 35
      ENDIF   
   ENDDO             
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Ok" OF oDlgA SIZE 50,12 ;
           ACTION ((mrta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Salir" OF oDlgA SIZE 50,12 ;
           ACTION ((mrta := .f.), oDlgA:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgA CENTER ON INIT oGetDep3:SetFocus()
IF !mRta
   RETURN nil
ENDIF
oGet[2]:cText := -val(oGetDep1:cCaption)
oGet[3]:cText := nImporte
oGet[7]:cText := oGetDep2:cCaption
oGet[3]:SetFocus()   

RETURN nil 


FUNCTION PoneDept1(nCod,cNombre)
oGetDep1:SetText(nCod)
oGetDep2:SetText(cNombre)
oGetDep3:SetFocus()
RETURN nil 


***********************************************************************************************************************************
***** SI ES UNA TRANSFERENCIA PIDO LOS DATOS DE LA CUENTA 
STATIC FUNCTION DatosTransferencia(nCodCue,nNumOpe,cObserva)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomCue:=SPACE(50),oQryCue

oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas")


DEFINE DIALOG oForm TITLE "Cuenta de la transferencia" OF oDlg;
       FROM 05,15 TO 15,85 FONT oApp:oFont
   
   @ 07, 05 SAY "Cuenta:"            OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Operacion:"         OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Observaciones:"     OF oForm PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet[1] VAR nCodCue OF oForm SIZE 25,12 RIGHT PICTURE "99" PIXEL;
                VALID(Buscar(oQryCue,oForm,oGet[1],oGet[2]));
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

*******************************************
** Impresion de Pedido
STATIC FUNCTION PrintPendi(nId)
LOCAL i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, config, oQryCli, lRta := .F.,;
      oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))   
   IF oQryP:imprimeTic
      lRta := .t.
      ELSE 
      lRta := .f.
   ENDIF      
   
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   IF !lRta
       ** PENDIENTES
       DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
       DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
       DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
       DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
       PRINT oPrn NAME "Pendiente"  PREVIEW MODAL
       oPrn:SetPortrait()
       oPrn:SetPage(9)

         PAGE
         nRow := (oPrn:nHorzRes() / 80) / 47
         @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY         
         oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
         @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
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
         ENDIF

         oPrn:CmSay( 2  , 11, "PENDIENTES", oFont1 )   
         *oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
         oPrn:CmSay( 1.5, 9.8, " ",oFont2)
         oPrn:CmSay( 2.5, 11, "Pendiente Nro:"+STR(nId,8),oFont)    
         oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(DATE()),oFont)

         oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
         oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
         oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

         @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
         @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(cCliente) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"                  
         
         @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                          SIZE 2.8,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                  SIZE 7,.5 CM FONT oFont ALIGN "L"
         @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unitario" ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal" ;
                  SIZE 3,.5 CM FONT oFont ALIGN "R"
             
         y := 9.2
         oQryDet:GoTop()
         FOR i = 1 TO oQryDet:nRecCount          
               @ y, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                  SIZE 2.8,.5 CM FONT oFont ALIGN "R"
               @ y+0.06, 04 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                  SIZE 7,1.5 CM FONT oFont LASTROW nRow
               @ y, 11 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"  
               @ y, 14 PRINT TO oPrn TEXT oQryDet:ptotal/oqrydet:cantidad ;
                          SIZE 2,.5 CM FONT oFont ALIGN "R"
               @ y, 17 PRINT TO oPrn TEXT oQryDet:ptotal;
                    SIZE 3,.5 CM FONT oFont ALIGN "R"             
               y := nRow + .1               
               oQryDet:Skip()
         NEXT             
         @ 23.5, 12 PRINT TO oPrn TEXT "Total $:" ;
                          SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                     @ 23.5, 17 PRINT TO oPrn TEXT STR(nTotal,12,2) ;
                          SIZE 3,.5 CM FONT oFont ALIGN "R"  
       ENDPAGE

       ENDPRINT
       /// Reporte por comandera
       ELSE 
       ** PENDIENTES POR COMANDERA
       IF config:fon > 25
          config:fon := config:fon /3
       ENDIF  
       DEFINE FONT oFont   NAME "COURIER NEW" SIZE config:fon,config:fon*2.5 BOLD
       DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
       IF !oApp:tick80
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT) 
               PAGE
                 nRow := 1
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 5,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     
                 @ nRow, 00 PRINT TO oPrn TEXT "PENDIENTE N°"+ALLTRIM(STR(nId,8)) ;
                          SIZE 4.8,1 CM FONT oFont LASTROW nRow ALIGN "C"
                 nRow := nRow + .5
                 @ nRow, 00 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(cCliente) ;
                      SIZE 4.8,1 CM FONT oFont1 LASTROW nRow                 
                 @ nRow, 00 PRINT TO oPrn TEXT "Producto" ;
                              SIZE 3,.5 CM FONT oFont 
                 @ nRow, 03.1 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 1.5,.5 CM FONT oFont ALIGN "R"
                 oQryDet:GoTop()
                 y := nRow + .5
                 FOR i = 1 TO oQryDet:nRecCount          
                       
                       @ y, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                          SIZE 3,1 CM FONT oFont LASTROW nRow
                       @ y, 3.1 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                          SIZE 1.5,.5 CM FONT oFont ALIGN "R"  
                         y := nRow + .1
                       oQryDet:Skip()
                 NEXT  
                 y := y + .5                   
                 @ y, 00 PRINT TO oPrn TEXT "Total $:" + STR(nTotal,12,2);
                              SIZE 4,.5 CM FONT oFont1 ALIGN "R"
                 @ y+.5,.1 PRINT TO oPrn TEXT "...";
                              SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
           ENDPAGE
           ENDPRINT
           ELSE
           // Ticket 80 mm
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT) 
               PAGE
                 nRow := 0
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 8,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                              
                 @ nRow, 00 PRINT TO oPrn TEXT "PENDIENTE N°"+ALLTRIM(STR(nId,8)) ;
                          SIZE 7.5,1 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 nRow := nRow + .5
                 @ nRow, 00 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(cCliente) ;
                      SIZE 7.5,1 CM FONT oFont1 LASTROW nRow                 
                 nRow := nRow + 1
                 @ nRow, 00 PRINT TO oPrn TEXT "Producto" ;
                              SIZE 4,.5 CM FONT oFont
                 @ nRow, 04.1 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 1.5,.5 CM FONT oFont ALIGN "R"
                 @ nRow, 05.6 PRINT TO oPrn TEXT "Total" ;
                      SIZE 1.7,.5 CM FONT oFont ALIGN "R"
                 oQryDet:GoTop()
                 y := nRow + .5
                 FOR i = 1 TO oQryDet:nRecCount          
                       
                       @ y, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                          SIZE 4,1 CM FONT oFont LASTROW nRow
                       @ y, 4.1 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                          SIZE 1.3,.5 CM FONT oFont ALIGN "R" 
                       @ y, 5.5 PRINT TO oPrn TEXT STR(oQryDet:ptotal,12,2) ;
                          SIZE 1.5,.5 CM FONT oFont ALIGN "R"  
                         y := nRow + .1
                       oQryDet:Skip()
                 NEXT  
                 y := y + .2  
                 
                 @ y, 00 PRINT TO oPrn TEXT "Total $:" + STR(nTotal,12,2);
                              SIZE 7.5,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow   
                 @ y+.02, 00 PRINT TO oPrn TEXT "...";
                              SIZE 7.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
           ENDPAGE
           ENDPRINT
        ENDIF
    ENDIF
RETURN nil


STATIC Function ResolucionMonitor()
LOCAL oFont, hDC
LOCAL Horizontal

   
   hDC := GetDc(0)
   //Vertical   := GetDeviceCaps(hDC, 0x0075)
   Horizontal := GetDeviceCaps(hDC, 0x0076)
   //msginfo(HB_VALTOSTR(Horizontal) +" x "+HB_VALTOSTR(Vertical))

RETURN Horizontal


STATIC FUNCTION CrearTemporales()
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS VENTAS_DET_H1 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(13) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(10,3) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"`PCOSTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IMPINT`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`ESPROMO` TINYINT(1) DEFAULT '0' NOT NULL, ";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS formapag_temp";
    +"("; 
    +"`RENGLON`   INT(2) NOT NULL  AUTO_INCREMENT ,";
    +"`TIPOPAG`   INT(1) NOT NULL ,";
    +"`FORMAPAG`  VARCHAR(30) NOT NULL,";
    +"`CODFORMA`  INT(2) NOT NULL,";
    +"`IMPORTE`  DECIMAL(12,2) NOT NULL,"+;
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")  

RETURN nil

//Validar Cantidad si lleva control de stock
STATIC FUNCTION ValidarCantidad(nCod, nVal)
LOCAL lRta := .t., nCanti, oQryAux, oQryS
IF nCod <= 0
   RETURN .t.
ENDIF   
nCanti := oApp:oServer:Query("SELECT SUM(cantidad) as canti FROM VENTAS_DET_H1 WHERE codart ="+str(nCod)):canti
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
      oBrwDet:SetFocus()
      oGet[02]:SetFocus()
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
          oBrwDet:SetFocus()
          oGet[02]:SetFocus()
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
     oDlg1:SetFocus() 
     oGet[02]:SetFocus()
  ENDIF
RETURN lRta


//Validar costo si lleva control de costo
STATIC FUNCTION ValidarCosto(nCos,nVen)
LOCAL lRta := .t.
   IF oQryPun:validacosto = 1
      IF nCos > nVen+1
          lRta:=MsgYesNo("El precio que está facturando está por debajo,"+CHR(10)+;
              "del costo del producto ¿Desea continuar?"+CHR(10)+;
              "Costo: "+ALLTRIM(STR(nCos)),"Atencion")
          IF !lRta 
             RETURN .f.
          ENDIF      
          //oBrwDet:SetFocus()
          //oGet[02]:SetFocus()
      ENDIF 
   ENDIF
   //Prohibo la venta por costo menor a venta
   IF oQryPun:validacosto = 2
      IF nCos > nVen+1
          MsgStop("No puede facturar el articulo seleccionado porque el "+CHR(10)+;
             "precio está por debajo del costo"+CHR(10)+;
             "Costo: "+ALLTRIM(STR(nCos)),"Atencion")
          RETURN .F.
      ENDIF
   ENDIF
RETURN .t.


STATIC FUNCTION CalcularPromos()
LOCAL cText, oQryTem, nNeto, nIva, nAux
//Borro las promos que cargue
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   RETURN nil 
ENDIF   
oApp:oServer:Execute("DELETE FROM VENTAS_DET_H1 WHERE ESPROMO = TRUE")
IF nCliente > 1 .and. oApp:oServer:Query("SELECT excluyepromo FROM ge_"+oApp:cId+"clientes WHERE codigo = "+str(nCliente)):excluyepromo
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
         0 AS PCOSTO, 0 AS IMPINT, 0 AS ESPROMO FROM VENTAS_DET_H1 GROUP BY CODART) AS p    
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
                oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (CODART, DETART, CANTIDAD, PUNIT, "+;
                  +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, PCOSTO, IMPINT, ESPROMO) VALUES ("+;
                  ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                  ClipValue2Sql(oQryTem:cantidad)+","+ClipValue2Sql(-oQryTem:punit)+","+;
                  ClipValue2Sql(-nNeto)+",0,"+ClipValue2Sql(-nNeto)+","+Clipvalue2Sql(-nIva)+","+;
                  ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql(-nNeto-nIva)+",0,0,1"+;
                  +")")         
           CASE oQryTem:tipo = 3
                nNeto := nNeto / oQryTem:cantidad
                nIva  := nIva  / oQryTem:cantidad
                oApp:oServer:Execute("INSERT INTO VENTAS_DET_H1 (CODART, DETART, CANTIDAD, PUNIT, "+;
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
ENDIF  
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
oBrwDet:GoBottom()
oGet[02]:cText:=0
oGet[07]:cText:=SPACE(30)
oGet[01]:Refresh()
oGet[02]:Refresh()
oGet[03]:Refresh()
nTotal := ROUND(oBrwDet:aCols[9]:nTotal,2)
RETURN nil

**********************************************
** Historial de Ventas realizadas
STATIC FUNCTION Historial(oWnd1)
LOCAL oBot := ARRAY(2), oForm, lRta := .f., aCor, oFont, oFont1, oError,;
      oQryVen, oQryDet, oBrwVen, oBrwDet, aArr
oQryVen := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha, v.hora, "+;                          
                          "  v.importe, v.nombre , c.observa "+;
                          " FROM ge_"+oApp:cId+"ventas_encab v "+;
                          " LEFT JOIN (SELECT CONCAT(ticomp,letra, numcomp) AS compro, "+;
                               " GROUP_CONCAT(observa) AS observa "+;
                               "FROM ge_"+oApp:cId+"concfact WHERE fecha=CURDATE() "+;
                               " GROUP BY CONCAT(ticomp,letra, numcomp) ) c "+;
                          " ON c.compro = CONCAT(v.ticomp,v.letra, v.numcomp) "+;     
                          " WHERE v.fecha = CURDATE() AND v.ticomp IN ('FC','FR')  ")
oQryDet := oApp:oServer:Query("SELECT codart,cantidad,detart,punit,importe "+;
                              " FROM ge_"+oApp:cId+"ventas_det LIMIT 0 ")
aArr := oQryVen:FillArray(,{"hora","compro","nombre","importe","observa"})     
IF EMPTY(aArr)
   MsgInfo("Sin datos del dia de hoy para historial","Atencion") 
   RETURN nil 
ENDIF      
DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0,-22
DEFINE DIALOG oForm TITLE "Historial"  FROM 05,15 TO 25,150 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)   
   @ 05, 05 SAY "COMPROBANTES" OF oForm SIZE 100,14 PIXEL FONT oFont1
   @ 25, 05 XBROWSE oBrwVen SIZE 235,100 PIXEL OF oForm ARRAY aArr ;
      COLUMNS 1,2,3,4,5;
      HEADERS "Hora","Comprobante","Cliente","Importe","F. Pago";
              SIZES 60,100,120,80,100;
      FOOTERS CELL LINES NOBORDER AUTOSORT ON CHANGE Actuali(aArr,oBrwVen,oQryDet,oBrwDet)
   oBrwVen:aCols[4]:nFooterType   := AGGR_SUM   
   oBrwVen:MakeTotals()
   oBrwVen:CreateFromCode()   
   PintaBrw(oBrwVen,0)
   @ 05,245 SAY "Detalle Comprobante" OF oForm SIZE 205,14 PIXEL FONT oFont1
   @ 25,245 XBROWSE oBrwDet SIZE 255,100 PIXEL OF oForm DATASOURCE oQryDet ;
          COLUMNS 'codart',"detart","cantidad","punit","importe";
          HEADERS 'Codigo',"Detalle Producto","Cant.","Unitario","Total";
          SIZES 70,220,60,60,80 FOOTERS;
          CELL LINES NOBORDER AUTOSORT          
   oBrwDet:aCols[3]:nFooterType   := AGGR_SUM
   oBrwDet:aCols[5]:nFooterType   := AGGR_SUM
   oBrwDet:MakeTotals()
   oBrwDet:CreateFromCode()
   PintaBrw(oBrwDet,0)   

   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Salir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT Actuali(aArr,oBrwVen,oQryDet,oBrwDet)
RETURN nil

***********************************************
** Busca los articulos vendidos en cada factura
STATIC FUNCTION Actuali(aArr,oBrwVen,oQryDet,oBrwDet)
LOCAL cWhere, n := Eval(oBrwVen:bKeyno), cComprobante
cComprobante := IF(n>0.and.n<=len(aArr),aArr[n,2],'   ')
cWhere := "nrofac = " + ClipValue2Sql(cComprobante) 
oQryDet:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwDet:MakeTotals()
oBrwDet:Refresh()
RETURN .t.