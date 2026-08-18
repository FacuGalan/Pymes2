#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

//
*************************************************
** Cambiar Formas de pago
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError,nFiltro
PROCEDURE CambiarPagos(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol,oBot,lFiltro:=.t.
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
nFiltro:=0
AADD(oApp:aVentanas,cVentana)

   oQryBrw:= oApp:oServer:Query("SELECT p.numero, c.nombre as nomcli, p.fecha, p.total, p.caja "+;
                                " FROM ge_"+oApp:cId+"pagos p "+;
                                " LEFT JOIN ge_"+oApp:cId+"clientes c ON p.cliente = c.codigo "+;
                                " WHERE p.checkeado IS FALSE")
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Cambiar Formas de pagos de clientes" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(cPermisos),oBrw:Refresh());
            PROMPT "Modifica" TOP 
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Pagos Pendientes de cierre",.T.,.F.);
            PROMPT "Reporte" TOP
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Cambiar a Cancelar Pagos"  ;
            ACTION (oWnd1:End(),Pagos(cPermisos));
            PROMPT "Cancela" TOP    
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "numero","nomcli","fecha","total","caja";
              HEADERS "Numero","Cliente","Fecha","Importe","Caja";
              SIZES 80,200,100,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(cPermisos),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQryBrw))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (cPermisos)
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oQryCon,oQryFac,;
      oBrw1,oBrw2, oQryOrden, nTotPag:=0, nTotFac:=0,oQry , nTotAnt := 0

oQry   := oApp:oServer:Query( "SELECT p.*, c.codigo AS codcli, c.nombre AS nomcli FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
                                "WHERE p.numero = "+ClipValue2Sql(oQryBrw:numero))
oQryCon:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"pagcon WHERE numero = " + ClipValue2Sql(oQry:numero))
oQryFac:= oApp:oServer:Query("SELECT *,CONCAT(ticomp,letra,numcomp) AS mostrar FROM ge_"+oApp:cId+"pagfac WHERE numero = " + ClipValue2Sql(oQry:numero))

DEFINE DIALOG oForm TITLE "Modificar forma de pago" RESOURCE "CANPAG" OF oDlg
	oForm:lHelpIcon := .f.
	
	REDEFINE GET oGet[1] VAR oQry:numero ID 101 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[2] VAR oQry:fecha  ID 102 OF oForm PICTURE "@D" WHEN(.F.)
	REDEFINE GET oGet[3] VAR oQry:codcli ID 103 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[4] VAR oQry:nomcli ID 104 OF oForm PICTURE "@!" WHEN(.F.)

	REDEFINE XBROWSE oBrw1 DATASOURCE oQryCon;
              COLUMNS "observa","importe","codcon";
              HEADERS "Forma pago","Importe","Cod";
              SIZES 205,105;
              ID 201 OF oForm ON DBLCLICK CambiarForma(oQryCon, oBrw1,cPermisos)
    PintaBrw(oBrw1,0)

    REDEFINE XBROWSE oBrw2 DATASOURCE oQryFac;
              COLUMNS "mostrar","importe";
              HEADERS "Documento","Importe";
              SIZES 241,70;
              ID 202 OF oForm
    PintaBrw(oBrw2,0) 
    REDEFINE BUTTON oBot[1] ID 301 OF oForm ACTION(lRta:=.t.,oForm:End())
    REDEFINE BUTTON oBot[2] ID 302 OF oForm ACTION(oForm:End())

ACTIVATE DIALOG oForm CENTER ON INIT (oBrw1:SetFocus(), oBot[1]:cTitle := "Cerrar")
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( oQry )
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

//Cambiar forma de pago
STATIC FUNCTION CambiarForma(oQryCon, oBrw1, cPermisos)
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, baseAnt, oError, oQryFor

oQryFor:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"forpag")
base := oQryCon:GetRowObj()
baseAnt := oQryCon:GetRowObj()

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Modificacion de Concepto de cobro" FROM 05,15 TO 15,75 OF oWnd1
   
   @ 07, 05 SAY "Codigo:"         OF oForm PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Concepto:"       OF oForm PIXEL SIZE 50,20 RIGHT
   @ 37, 05 SAY "Tipo:"           OF oForm PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:codcon PICTURE "99999" OF oForm PIXEL RIGHT ;
            VALID(BuscarArt(oQryFor,oForm,oGet[1],oGet[2]));
               ACTION (oGet[1]:cText:= 0, BuscarArt(oQryFor,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 20, 65 GET oGet[2] VAR base:observa PICTURE "@!"    OF oForm PIXEL WHEN(.F.)
   @ 35, 65 GET oGet[3] VAR base:tipocon OF oForm PIXEL WHEN(.F.)
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:codcon = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
base:tipocon := oQryFor:tipo
oQryCon:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagcon SET codcon = "+ ClipValue2Sql(base:codcon)+","+;
                       "tipocon = "+ClipValue2Sql(base:tipocon)+", observa = "+ClipValue2Sql(base:observa)+;
                       " WHERE numero = "+ClipValue2Sql(baseAnt:numero)+ " AND "+;
                       "       codcon  = "+ClipValue2Sql(baseAnt:codcon)+ " AND "+;
                       "       tipocon = "+ClipValue2Sql(baseAnt:tipocon)+ " AND "+;
                       "       importe = "+ClipValue2Sql(baseAnt:importe))
  oApp:oServer:CommitTransaction()
CATCH oError
  ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
oQryCon:Refresh()
oBrw1:Refresh()
RETURN nil