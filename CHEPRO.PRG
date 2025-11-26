#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "hbcompat.ch"
*************************************************
** Cheques de propios
*************************************************
MEMVAR oApp
STATIC oQryBrw,oQry,oQry2,oQry3, oWnd1,oForm, oBrw, oDlg, lEdit := .f., cVentana, oError
PROCEDURE Chepro(cPermisos)
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
   oQryBrw:= oApp:oServer:Query("SELECT c.*, p.nombre AS Nprov,cu.nombre AS nomcue " +; 
                                " FROM ge_"+oApp:cId+"chepro c" +;
                                " LEFT JOIN ge_"+oApp:cId+"provee p ON c.codpro = p.codigo" +;
                                " LEFT JOIN ge_"+oApp:cId+"cuentas cu ON cu.codigo = c.numban")
   
   oQry2 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"cuentas ORDER BY codigo")
   oQry3 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Cheques propios" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
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
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Cheques propios",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
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
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "numche","nomcue","fecemi","fecvto","fecacr","importe";
              HEADERS "Numero","Cuenta bancaria","Emisión","Vencimiento","Acredita.","Importe";
              FOOTERS;
              SIZES   80,250,100,100,100,100;              
             ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT oBrw:cSeek ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[6]:nFooterType := AGGR_SUM
     PintaBrw(oBrw,6)
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     oBrw:Maketotals()
     // Activo el dialogo y al iniciar muevo a 0,0
        ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())

RETURN

*****************************************************************************
*****************************************************************************
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(10), oBot := ARRAY(3), lRta := .F., aCor, base,oGru,bGar,cCuenta:= SPACE(30),;
      banco2:= SPACE(30), nompro:= SPACE(30), vItems:={"Endoso","Despositado","Anulado"}, oFont
 
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
IF lAlta
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"chepro LIMIT 0")
   base := oQry:GetBlankRow()
   base:fecemi:= DATE()
   base:fecvto:= DATE()+1
   base:estado:= " "
   ELSE
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"chepro WHERE numban = " + ClipValue2SQL(oQryBrw:numban) +;
                                " and numche = " + ClipValue2SQL(oQryBrw:numche))
   base := oQry:GetRowObj()
   IF oQry2:Seek(oQry:numban,1) > 0
      cCuenta := oQry2:nombre
   ENDIF
   IF oQry3:Seek(oQry:codpro,1) > 0
      nompro := LTRIM(oQry3:nombre)
      ELSE
      nompro := "******************************"
   ENDIF  
ENDIF

DO WHILE .T.
   DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Cheques de propios";
       FROM 05,10 TO 26,65 OF oWnd1 ICON oApp:oIco FONT oFont
   acor := AcepCanc(oForm)
   
   @ 07, 05 SAY "Cuenta:"               OF oForm PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Número de cheque:"     OF oForm PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Importe:"              OF oForm PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Proveedor:"            OF oForm PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Nombre del proveedor:" OF oForm PIXEL SIZE 60,12 RIGHT
   @ 82, 05 SAY "Fecha de emisión:"     OF oForm PIXEL SIZE 60,12 RIGHT
   @ 97, 05 SAY "Fecha de Vto.:"        OF oForm PIXEL SIZE 60,12 RIGHT
   @112, 05 SAY "Orden de pago:"        OF oForm PIXEL SIZE 60,12 RIGHT
   @127, 05 SAY "Fecha de Acr.:"        OF oForm PIXEL SIZE 60,12 RIGHT

************************************************************************************************   
   @ 05, 70 GET oGet[01] VAR base:numban OF oForm PIXEL RIGHT PICTURE "999" SIZE 25,12 WHEN(lAlta);
                VALID(Buscar(oQry2,oForm,oGet[01],oGet[02]));
                ACTION (oGet[01]:cText:= 0, Buscar(oQry2,oForm,oGet[01],oGet[02])) BITMAP "BUSC1"
   @ 05,100 GET oGet[02] VAR cCuenta OF oForm PIXEL PICTURE "@!" WHEN(.f.)
   @ 20, 70 GET oGet[03] VAR base:numche  OF oForm PIXEL PICTURE "9999999999" RIGHT WHEN(lAlta);
                VALID(base:numche>0)
   @ 35, 70 GET oGet[04] VAR base:importe  OF oForm PIXEL PICTURE "999999999.99" RIGHT;
                VALID(base:importe>0)
   @ 50, 70 GET oGet[05] VAR base:codpro  OF oForm PIXEL PICTURE "999999" RIGHT SIZE 30,12;
                VALID(IF(base:codpro=0,.t.,Buscar(oQry3,oForm,oGet[05],oGet[06],'0','inactivo')));
                ACTION (oGet[05]:cText:= 0, Buscar(oQry3,oForm,oGet[05],oGet[06],'0','inactivo')) BITMAP "BUSC1"  
   @ 65, 70 GET oGet[06] VAR nompro  OF oForm PIXEL PICTURE "@!" WHEN(.F.)
   @ 80, 70 GET oGet[07] VAR base:fecemi OF oForm PIXEL CENTER  
   @ 95, 70 GET oGet[08] VAR base:fecvto OF oForm PIXEL CENTER 
   @110, 70 GET oGet[09] VAR base:orden OF oForm PICTURE "99999999" PIXEL RIGHT
   @125, 70 GET oGet[10] VAR base:fecacr OF oForm PICTURE "@D" PIXEL CENTER
   
  

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
ENDIF

base:usuario:= oApp:usuario
base:ip     := oApp:cIp
base:fecmod := DATE()

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQryBrw:Refresh(.t.)
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
IF oQry <> nil
   oQry:End()
ENDIF  

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

mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
 oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"chepro WHERE numban = " + ClipValue2SQL(oQryBrw:numban) +;
                              " and numche = " + ClipValue2SQL(oQryBrw:numche))
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)
CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrw:Refresh()
RETURN nil 

******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEstado := 1 
LOCAL oGet1, oGet2, oGet3, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, aEstado := {"Todos","Pagos","Impagos"} 


DEFINE DIALOG oDlg1 TITLE "FILTRADO de Cheques propios" FROM 05,10 TO 14,60 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha Vto:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha Vto:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Estado:"          OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 COMBOBOX oGet3 VAR nEstado  ITEMS aEstado SIZE 80,80 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " fecvto >=" + ClipValue2SQL(vdesde) +;
      + "  and fecvto <= " + ClipValue2SQL(vhasta) ;
      + "  and " + IF(nEstado = 1," TRUE ", IF(nEstado = 2, " fecacr IS NOT NULL"," fecacr IS NULL"))
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil