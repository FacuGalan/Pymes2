#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM DE BANCOS
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, cVentana
PROCEDURE DESCU(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw  := oApp:oServer:Query( "SELECT d.*,c.nombre AS nomcli,a.nombre AS nomart,a.marca,a.rubro FROM ge_"+oApp:cId+"clides d "+;
                                "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = d.codcli "+;
                                "LEFT JOIN ge_"+oApp:cId+"articu a   ON a.codigo = d.codmar "+;
                                "ORDER BY c.nombre")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Descuentos por clientes" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(),oBrw:Refresh());
            PROMPT "Modifica [F2]" TOP WHEN(oQryBrw :RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar cliente"  ;
            ACTION (FILT(),oBrw:Refresh());
            PROMPT "Filtrar [F3]" TOP  
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw :RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta [F4]" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Descuentos por cliente",.T.,.F.);
            PROMPT "Reporte [F5]" TOP WHEN(oQryBrw :RecCount()>0 .and. "R"$cPermisos) 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw ;
              COLUMNS "nomcli","nomart","descu";
              HEADERS "Cliente","Articulo","Descuento";
              SIZES 300,300,70;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,3) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,4)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(5), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,oQryDesc
   oQryDesc:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clides WHERE codcli = " + ClipValue2Sql(oQryBrw:codcli)+" "+;
                                 "AND codmar = " + ClipValue2Sql(oQryBrw:codmar))
   base := oQryDesc:GetRowObj()

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Descuento puntual";
       FROM 05,15 TO 15,65 OF oWnd1 ICON oApp:oIco
   
   @ 07, 05 SAY "Cliente:"        OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 05 SAY "Articulo:"       OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 05 SAY "Descuento:"      OF oForm PIXEL SIZE 40,20 RIGHT
  
   @ 05, 50 GET oGet[1] VAR oQryBrw:codcli PICTURE "999999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 05, 80 GET oGet[2] VAR oQryBrw:nomcli PICTURE "@!" SIZE 100,12 OF oForm PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR oQryBrw:codmar PICTURE "999999" OF oForm PIXEL RIGHT WHEN(.F.) 
   @ 20, 80 GET oGet[4] VAR oQryBrw:nomart PICTURE "@!" SIZE 100,12 OF oForm PIXEL WHEN(.F.)
   @ 35, 50 GET oGet[5] VAR base:descu     PICTURE "999.99" OF oForm PIXEL RIGHT
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

oQryDesc:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryDesc:Save()
  oQryBrw:Refresh(.F.)
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

****************************************FILTRADO**********************
STATIC FUNCTION FILT( )
LOCAL oFilt, acor:=ARRAY(4), oBot:=ARRAY(2), lRta:=.f., oGet:=ARRAY(8), cWhere,;
      vCliente:=0,vArticulo:=0,vMarca:=0,vRubro:=0,cNomCli:=SPACE(30),cNomArt:=SPACE(30),;
      cNomMar:=SPACE(30),cNomRub:=SPACE(30),oQryCli,oQryArt,oQryRub,oQryMar

oQryArt:=oApp:oServer:Query("SELECT codigo,nombre,precioven1 AS precio FROM ge_"+oApp:cId+"articu")
oQryCli:=oApp:oServer:Query("SELECT codigo,nombre,localidad FROM ge_"+oApp:cId+"clientes")
oQryRub:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"rubros")
oQryMar:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"marcas")

DO WHILE .T.
DEFINE DIALOG oFilt TITLE "Filtrado de descuentos";
       FROM 05,15 TO 17,65 OF oWnd1 ICON oApp:oIco
   
   @ 07, 05 SAY "Cliente:"    OF oFilt PIXEL SIZE 40,20 RIGHT
   @ 22, 05 SAY "Articulo:"   OF oFilt PIXEL SIZE 40,20 RIGHT
   @ 37, 05 SAY "Marca:"      OF oFilt PIXEL SIZE 40,20 RIGHT
   @ 52, 05 SAY "Rubro:"      OF oFilt PIXEL SIZE 40,20 RIGHT
   
   @ 05, 50 GET oGet[1] VAR vCliente   OF oFilt PIXEL RIGHT SIZE 30,12 PICTURE "999999";
                VALID((oGet[1]:cText="     0") .or. Buscar(oQryCli,oFilt,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryCli,oFilt,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 05, 85 GET oGet[2] VAR cNomCli    PICTURE "@!" SIZE 100,12 OF oFilt PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR vArticulo  OF oFilt PIXEL RIGHT SIZE 30,12 PICTURE "999999";
                VALID((oGet[3]:cText="     0") .or. Buscar(oQryArt,oFilt,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryArt,oFilt,oGet[3],oGet[4])) BITMAP "BUSC1"
   @ 20, 85 GET oGet[4] VAR cNomArt    PICTURE "@!" SIZE 100,12 OF oFilt PIXEL WHEN(.F.)
   @ 35, 50 GET oGet[5] VAR vMarca     OF oFilt PIXEL RIGHT SIZE 30,12 PICTURE "999";
                VALID((oGet[5]:cText="  0") .or. Buscar(oQryMar,oFilt,oGet[5],oGet[6]));
                ACTION (oGet[5]:cText:= 0, Buscar(oQryMar,oFilt,oGet[5],oGet[6])) BITMAP "BUSC1"
   @ 35, 85 GET oGet[6] VAR cNomMar    PICTURE "@!" SIZE 100,12 OF oFilt PIXEL WHEN(.F.)
   @ 50, 50 GET oGet[7] VAR vRubro     OF oFilt PIXEL RIGHT SIZE 30,12 PICTURE "999";
                VALID((oGet[7]:cText="  0") .or. Buscar(oQryRub,oFilt,oGet[7],oGet[8]));
                ACTION (oGet[7]:cText:= 0, Buscar(oQryRub,oFilt,oGet[7],oGet[8])) BITMAP "BUSC1"
   @ 50, 85 GET oGet[8] VAR cNomRub    PICTURE "@!" SIZE 100,12 OF oFilt PIXEL WHEN(.F.)
   
   acor := AcepCanc(oFilt)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .t.), oFilt:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
ACTIVATE DIALOG oFilt CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN nil
ENDIF

cWhere = " 1=1 " + IF(EMPTY(vCliente),""," and d.codcli =" + ClipValue2SQL(vCliente) + "") ;
            + "" + IF(EMPTY(vArticulo),""," and d.codart =" + ClipValue2SQL(vArticulo) + "") ;
            + "" + IF(EMPTY(vMarca),""," and a.marca =" + ClipValue2SQL(vMarca) + "") ;
            + "" + IF(EMPTY(vRubro),""," and a.rubro =" + ClipValue2SQL(vRubro) + "") ;
            
EXIT
ENDDO
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil