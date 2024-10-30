#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** DEFINICION DE PROMOCIONES
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE Promociones(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
validarqueexista()
AADD(oApp:aVentanas,cVentana)
oQry  := oApp:oServer:Query( "SELECT p.*,a.nombre FROM ge_"+oApp:cId+"promociones p "+;
                             "LEFT JOIN ge_"+oApp:cId+"articu a ON p.codart = a.codigo ORDER BY p.nompromo")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Promociones" ;
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
            ACTION oBrw:Report("Reporte de Promociones",.T.,.F.);
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
              COLUMNS "codart","nombre","nompromo","tipo","descuento","fecha_vto";
              HEADERS "Codigo","Nombre","Nombre Promo","Tipo","% Desc","Fecha Vto";
              SIZES 50,200,200,40,50,80;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu( .f.),MsgInfo("Sin Permiso")),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     PintaBrw(oBrw,6) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(2),oQryPro, oQryArt, oForm, lRta := .f., aCor, base, oError,;
      oBrw1,oBrw2,oFont,aTipo:={"Por Precio","Por % Descuento"}, cNombre := SPACE(50)

oQryArt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu")
IF lAlta
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"promociones LIMIT 0")
   base := oQryPro:GetBlankRow()   
   base:cantidad_promo := 1
   base:tipo := 1
   ELSE
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"promociones WHERE codart = " +ClipValue2Sql(oQry:codart))
   base := oQryPro:GetRowObj()
   oQryArt:GoTop()
   IF oQryArt:Seek(base:codart,1) > 0
      cNombre := oQryArt:nombre
   ENDIF
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Promociones";
       FROM 05,15 TO 25,97 OF oWnd1
   
   @ 07, 05 SAY "Codigo Articulo:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @ 22, 05 SAY "Nombre Articulo:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @ 37, 05 SAY "Nombre Promo:"          OF oForm PIXEL SIZE 70,12 RIGHT
   @ 52, 05 SAY "Cantidad Unidades:"     OF oForm PIXEL SIZE 70,12 RIGHT
   @ 67, 05 SAY "Tipo de promo:"         OF oForm PIXEL SIZE 70,12 RIGHT
   @ 82, 05 SAY "Descuento %:"           OF oForm PIXEL SIZE 70,12 RIGHT
   @ 97, 05 SAY "Precio Promo:"          OF oForm PIXEL SIZE 70,12 RIGHT
   @112, 05 SAY "Fecha Vencimiento:"     OF oForm PIXEL SIZE 70,12 RIGHT
  
   @ 05, 80 GET oGet[1] VAR base:codart PICTURE "99999999999999" RIGHT OF oForm SIZE 60,12 PIXEL;
                VALID(Buscar(oQryArt,oForm,oGet[01],oGet[02]));
                ACTION (oGet[01]:cText:= 0, Buscar(oQryArt,oForm,oGet[01],oGet[02])) BITMAP "BUSC1" WHEN(lAlta)
   @ 20, 80 GET oGet[2] VAR cNombre    PICTURE "@!" OF oForm PIXEL WHEN(.F.)  
   @ 35, 80 GET oGet[3] VAR base:nompromo PICTURE "@!"    OF oForm PIXEL VALID(base:nompromo<>SPACE(30))     
   @ 50, 80 GET oGet[4] VAR base:cantidad_promo  PICTURE "999" RIGHT OF oForm SIZE 25,12 PIXEL;
    VALID(base:cantidad_promo>0)
   @ 65, 80 COMBOBOX oGet[5] VAR base:tipo ITEMS aTipo OF oForm PIXEL SIZE 70,12
   @ 80, 80 GET oGet[6] VAR base:descuento  PICTURE "999.99" RIGHT OF oForm SIZE 25,12 PIXEL WHEN(base:tipo = 2)
   @ 95, 80 GET oGet[7] VAR base:precio     PICTURE "999999999.999" RIGHT OF oForm SIZE 60,12 PIXEL WHEN(base:tipo = 1)
   @110, 80 GET oGet[8] VAR base:fecha_vto  PICTURE "@D" OF oForm PIXEL
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 
IF !lRta
   RETURN nil
ENDIF
IF base:codart = 0 .or. base:nompromo = SPACE(30)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   oQryPro:GetBlankRow()
ENDIF
oQryPro:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryPro:Save()
  oQry:Refresh()
  oBrw:Refresh()
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
LOCAL mrta := .f., oError, nNum := oQry:codart
IF oQry:codart = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"promociones WHERE codart = "+str(nNum))
  oApp:oServer:CommitTransaction()
  oQry:Refresh()
CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 

STATIC FUNCTION validarqueexista()

IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"promociones ( "+;
  "`codart` BIGINT(14) NOT NULL,"+;
  "`cantidad_promo` INT(4) NOT NULL,"+;
  "`nompromo` VARCHAR(40) DEFAULT NULL,"+;
  "`tipo` INT(1) NOT NULL DEFAULT 1,"+;
  "`descuento` DECIMAL(6,2) DEFAULT 0,"+;
  "`precio` DECIMAL(12,3) DEFAULT 0,"+;
  "`fecha_vto` DATE DEFAULT NULL,"+;  
  "PRIMARY KEY (`codart`)"+;
") ENGINE=INNODB DEFAULT CHARSET=utf8")
ENDIF
RETURN nil 