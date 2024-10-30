#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** Fondo de caja
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE FCAJA(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fondo "+;
                             IF(oApp:usua_es_supervisor," WHERE checkeado = FALSE "," WHERE checkeado = FALSE AND caja = "+str(oApp:prefijo)) +;
                             " ORDER BY fecha")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Fondos de caja" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
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
            ACTION oBrw:Report("Reporte de Fondos de caja",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Registros"  ;
            ACTION (Filt(), oBrw:Refresh());
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "fecha","importe","caja";
              HEADERS "Fecha","Importe","N° Caja";
              SIZES 80,120,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,3) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError, poriva, oQryPun,;
      lSuper:=.f.
      
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2SQl(oApp:cIp))
IF lAlta
   base := oQry:GetBlankRow()
   base:fecha := DATE()
   base:caja:= oQryPun:caja
   ELSE
   IF oQry:checkeado
       MsgStop("No puede modificar un movimiento ya consolidadado en un cierre","Error") 
       RETURN nil 
   ENDIF
   base := oQry:GetRowObj()
ENDIF
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Fondo de caja";
       FROM 05,15 TO 15,55 OF oWnd1
   
   @ 07, 05 SAY "Fecha:"        OF oForm PIXEL SIZE 35,20 RIGHT
   @ 22, 05 SAY "Importe:"      OF oForm PIXEL SIZE 35,20 RIGHT
   @ 37, 05 SAY "Caja:"         OF oForm PIXEL SIZE 35,20 RIGHT
  
   @ 05, 50 GET oGet[1] VAR base:fecha   PICTURE "@D"  OF oForm PIXEL CENTER 
   @ 20, 50 GET oGet[2] VAR base:importe PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                VALID(base:importe>0)
   @ 35, 50 GET oGet[3] VAR base:caja    PICTURE "999" OF oForm PIXEL RIGHT WHEN(lSuper);
                VALID(base:caja>0)
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF lAlta
   oQry:GetBlankRow()
   ELSE 
   Auditar(2," Fondo de caja: $"+alltrim(STR(oQry:importe,12,2))+" Caja "+STR(oQry:caja,4))
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
STATIC FUNCTION cerrar (  )
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
LOCAL mrta := .f., oError
IF oQry:checkeado
   MsgStop("No puede borrar un movimiento ya consolidadado en un cierre","Error") 
   RETURN nil 
ENDIF
mrta := MsgNoYes("¿Seguro de eliminar?","Atencion")
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


******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEstado := 1 
LOCAL oGet1, oGet2, oGet3, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, aEstado := {"Todos","En cartera","Depositados","Entregados"} 


DEFINE DIALOG oDlg1 TITLE "FILTRADO de Saldos de Caja" FROM 05,10 TO 14,60 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   *@ 37, 05 SAY "Estado:"          OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   *@ 35, 70 COMBOBOX oGet3 VAR nEstado  ITEMS aEstado SIZE 80,80 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " fecha >=" + ClipValue2SQL(vdesde) +;
      + "  and fecha <= " + ClipValue2SQL(vhasta) ;
      + IF(oApp:usua_es_supervisor,"", " AND caja = "+str(oApp:prefijo))

      //+ "  and " + IF(nEstado = 1," TRUE ", IF(nEstado = 2, " estado = 'C'",IF(nEstado=3," estado = 'D'"," estado = 'E'")))
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil