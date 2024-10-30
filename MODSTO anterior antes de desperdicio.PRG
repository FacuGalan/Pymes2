#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "hbcompat.ch"
*************************************************
** Modificacion manual de stock
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana, oError
PROCEDURE MODSTOCK(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol, oMen, nOpt := 1
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

   CursorWait()
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"articu ORDER BY codigo")
  

   
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Modific. manual de stock" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Stock actual",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)     
         
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
   DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
        REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codigo","Nombre","Stockact";
              HEADERS "Código articulo","Nombre","Stock actual";
              SIZES   100,250,80;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil))
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     PintaBrw(oBrw,3) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,3)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

*****************************************************************************
*****************************************************************************
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .F., aCor, base, nEntradas:= 0,;
      nSalidas:= 0, nStock
     
      
   base := oQry:GetRowObj()
   base:codigo := oQry:codigo
   nStock:= base:StockAct
   


DEFINE DIALOG oForm TITLE "Modificación manual de stock";
   FROM 05,10 TO 17,50 OF oWnd1
   acor := AcepCanc(oForm)
   
   @ 07, 20 SAY "Stock actual:" OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 20 SAY "Entradas:"     OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 20 SAY "Salidas:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 52, 20 SAY "Nuevo stock:"  OF oForm PIXEL SIZE 40,20 RIGHT
 ******************************************************************
   @ 05, 70 GET oGet[1] VAR base:stockact OF oForm PIXEL PICTURE "9999999.999" RIGHT WHEN(.F.)
   @ 20, 70 GET oGet[2] VAR nEntradas OF oForm PIXEL PICTURE "999999.999" RIGHT
   @ 35, 70 GET oGet[3] VAR nSalidas  OF oForm  PIXEL RIGHT PICTURE "999999.999"
   @ 50, 70 GET oGet[4] VAR nStock    OF oForm  PIXEL RIGHT  PICTURE "9999999.999";
     WHEN(( oGet[4]:cText := base:stockact - nSalidas + nEntradas) = "-9999999999")   
   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL

ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()


IF !lRta
   RETURN nil
ENDIF

TRY
   oApp:oServer:BeginTransaction()    
   base:stockact := base:stockact + nEntradas - nSalidas
   base:save()
   oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha"},;
                           {base:codigo,nEntradas,nSalidas,DATE()})
   oApp:oServer:CommitTransaction() 
CATCH oError
 MsgInfo(oError:description)
 oApp:oServer:RollBack()   
END TRY
oBrw:Refresh()
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
IF oQry:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
oQry:Delete()
RETURN nil



  