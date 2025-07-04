#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** ABM I.V.As
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE ABMDEP(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Departamentos de articulos" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu(.t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(.f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Departamentos de articulos",.T.,.F.);
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
              COLUMNS "Codigo","Nombre";
              HEADERS "Código","Nombre del departamento";
              SIZES 80,200;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oDlg:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(5), oBot := ARRAY(2), oForm, lRta := .f., aCor, base,;
      oQryIva:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo"), cNomIva := SPACE(30)

IF lAlta
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"deptos")
   base:iva := 5
   ELSE
   base := oQry:GetRowObj()
   base:codigo := oQry:codigo
   oQryIva:GoTop()
   IF oQryIva:Seek(base:iva,1) > 0
      cNomIva:= oQryIva:nombre
   ENDIF
ENDIF
DO WHILE .T.

DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Departametos de articulos";
       FROM 05,15 TO 16,60 OF oWnd1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Código:"       OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Nombre:"       OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Utilidad %:"   OF oForm PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Tasa IVA:"     OF oForm PIXEL SIZE 40,12 RIGHT
 
   @ 05, 50 GET oGet[1] VAR base:codigo   OF oForm PICTURE "9999" PIXEL RIGHT WHEN(.F.)
   @ 20, 50 GET oGet[2] VAR base:nombre   OF oForm PICTURE "@!" PIXEL 
   @ 35, 50 GET oGet[5] VAR base:porcenbase   OF oForm PICTURE "999.99" PIXEL RIGHT
   @ 50, 60 GET oGet[3] VAR base:iva PICTURE "99"    OF oForm PIXEL SIZE 25,12 RIGHT;
                VALID(Buscar(oQryIva,oForm,oGet[03],oGet[04]));
                ACTION (oGet[03]:cText:= 0, Buscar(oQryIva,oForm,oGet[03],oGet[04])) BITMAP "BUSC1"
   @ 50, 90 GET oGet[4] VAR cNomIva     PICTURE "@!"    OF oForm PIXEL WHEN(.F.)
 
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[2]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:iva <> 3 .and. base:iva <> 4 .and. base:iva <> 5
   MsgStop("Tasa de IVA no valida para facturacion","Error")
   LOOP
ENDIF   
IF base:codigo = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   oQry:GetBlankRow()
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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQry:codigo
IF oQry:codigo = 0
   RETURN nil
ENDIF
IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE depto = "+str(nNum)):nRecCount > 0
   MsgStop("No puede borrar este departamento porque tiene"+CHR(10)+;
                 "articulos asociados","Atencion")
   RETURN nil 
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 
 