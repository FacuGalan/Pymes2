#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


*************************************************
** ABM DE vendedores
*************************************************
MEMVAR oApp
STATIC oQryBrw,oWnd1, oBrw, oDlg, cVentana
PROCEDURE VENDE(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores ORDER BY nombre")
                         
  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Vendedores" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Vendedores",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar clientes"  ;
            ACTION (oBrw:Refresh());
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "Codigo","nombre";
              HEADERS "Código","Nombre";
              SIZES 60,345;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     *oBrw:aCols[2]:SetOrder()
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(16), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
	    cNomVen:=SPACE(50),aComision:={"Cobrado","Facturado"},aComTot:={"Neto","Total"},;
      aListaPre := {"Precio Venta (Lista 1)","Precio Reventa (Lista 2)","Selecciona Lista Especial"}


IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores LIMIT 0")
   base := oQry:GetBlankRow()   
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"vendedores")
   base:condfac := 1
   base:condtot := 1
   base:permitealta := .f.
   base:listapre := 1
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
   base := oQry:GetRowObj()
   oQry:lAppend:= .f.

ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Vendedor";
       FROM 05,15 TO 35,85 OF oWnd1 FONT oApp:oFont
   
   @ 07, 05 SAY "Codigo:"         OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 05 SAY "Comisión %:"     OF oForm PIXEL SIZE 40,20 RIGHT
   @ 52, 05 SAY "Comisión sobre:" OF oForm PIXEL SIZE 40,20 RIGHT
   @ 67, 05 SAY "D.N.I.:"         OF oForm PIXEL SIZE 40,20 RIGHT
   @ 82, 05 SAY "Localidad:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 97, 05 SAY "Direccion:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @112, 05 SAY "Telefonos:"      OF oForm PIXEL SIZE 40,20 RIGHT  
   @127, 05 SAY "Celular:"        OF oForm PIXEL SIZE 40,20 RIGHT
   @142, 05 SAY "Mail:"           OF oForm PIXEL SIZE 40,20 RIGHT
   @157, 05 SAY "Cta. bancaria:"  OF oForm PIXEL SIZE 40,20 RIGHT
   @172, 05 SAY "Usuario/Pass Web (Pedidos):"  OF oForm PIXEL SIZE 40,25 RIGHT

   @ 05, 50 GET oGet[01] VAR base:codigo OF oForm PIXEL PICTURE "99999" RIGHT WHEN(.F.)
   @ 20, 50 GET oGet[02] VAR base:nombre OF oForm PIXEL PICTURE "@!" ;
                VALID(base:nombre<>SPACE(30))  
   @ 35, 50 GET oGet[03] VAR base:comision PICTURE "999.99" OF oForm PIXEL RIGHT 
   @ 50, 50 COMBOBOX oGet[4] VAR base:condfac SIZE 50,12 OF oForm PIXEL ITEMS aComision
   @ 50,105 COMBOBOX oGet[12] VAR base:condtot SIZE 50,12 OF oForm PIXEL ITEMS aComTot
   @ 65, 50 GET oGet[05] VAR base:dni       OF oForm PIXEL PICTURE "99999999" RIGHT 
   @ 80, 50 GET oGet[06] VAR base:localidad OF oForm PIXEL PICTURE "@!"
   @ 95, 50 GET oGet[07] VAR base:direccion OF oForm PIXEL PICTURE "@!" SIZE 214,12
   @110, 50 GET oGet[08] VAR base:telefono  OF oForm PIXEL TEXT SIZE 120,12
   @125, 50 GET oGet[09] VAR base:celular   OF oForm PIXEL PICTURE "@!"
   @140, 50 GET oGet[10] VAR base:mail      OF oForm PIXEL PICTURE "@!"
   @155, 50 GET oGet[11] VAR base:cuenta OF oForm PIXEL PICTURE "@!" SIZE 214,12
   @170, 50 GET oGet[12] VAR base:user   OF oForm PIXEL 
   @170,120 GET oGet[13] VAR base:pass   OF oForm PIXEL 
   @170,190 CHECKBOX oGet[14] VAR base:permitedesc SIZE 95,12 PROMPT "Carga descuentos"   OF oForm PIXEL 
   @185, 50 CHECKBOX oGet[15] VAR base:permitealta SIZE 55,12 PROMPT "Permite Alta Clientes" OF oForm PIXEL 
   @185,125 COMBOBOX oGet[16] VAR base:listapre SIZE 90,12 OF oForm PIXEL ITEMS aListaPre

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN nil
ENDIF
  
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
oQryBrw:Refresh()
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQryBrw:End()
RELEASE oQryBrw
  

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
LOCAL mrta := .f., oError, nNum := oQryBrw:codigo
IF oQryBrw:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"vendedores WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)

CATCH oError
    ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 
