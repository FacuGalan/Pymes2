#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** Tipos de comprobantes
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE TDEP(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"tipodepo ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Tipos de depositos/retiros" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
          DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu(.t. ),oBrw:Refresh());
            PROMPT "Alta [F2]" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(.f. ),oBrw:Refresh());
            PROMPT "Modifica [F3]" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja [F4]" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta [F5]" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Tipos de depositos/retiriros",.T.,.F.);
            PROMPT "Reporte [F6]" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codigo","Nombre";
              HEADERS "Código","Nombre";
              SIZES 120,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(.f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(3), oBot := ARRAY(2), oForm, lRta := .f., aCor, base,;
      vTipo:={"Suma","Resta"}

IF lAlta
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"tipodepo")
   ELSE
   base := oQry:GetRowObj()
   base:codigo := oQry:codigo
ENDIF
DO WHILE .T.

DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Tipos de depositos/retiros";
       FROM 05,15 TO 12,60 OF oWnd1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Código:"   OF oForm PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Nombre:"   OF oForm PIXEL SIZE 50,12 RIGHT
 
   @ 05, 60 GET oGet[1] VAR base:codigo   OF oForm PICTURE "@!" PIXEL RIGHT 
   @ 20, 60 GET oGet[2] VAR base:nombre   OF oForm PICTURE "@!" PIXEL 
 
 @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:prefijo ="  " 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF
base:tipo := LEFT(base:tipo,1)
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

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f.
mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
oQry:Delete()
RETURN nil

 