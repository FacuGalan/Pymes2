#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM Fragancias gustos y sabores
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana,oQryPun
PROCEDURE FGS(cPermisos)
LOCAL oBar, hHand, cDialog
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp))
cDialog:= "ABMS"
oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"grupos ORDER BY nombre")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Fragancias, gustos y sabores" ;
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
            ACTION oBrw:Report("Reporte de Fragancias, gustos y sabores",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
            // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE cDialog OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codigo","Nombre";
              HEADERS "Codigo","Nombre";
              SIZES 50,350;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu( .f.),MsgInfo("Sin Permiso")),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
STATIC FUNCTION Acelerador2(nKey, oBar,cPermisos)
IF nkey = VK_F2
   oBar:aControls[1]:Click()
ENDIF
IF nKey = VK_F3 
   oBar:aControls[2]:Click()
ENDIF
IF nKey = VK_F4
   oBar:aControls[3]:Click()
ENDIF
IF nKey = VK_F5
   oBar:aControls[4]:Click()
ENDIF
IF nKey = VK_F6
   oBar:aControls[5]:Click()
ENDIF

/*
IF nKey = 13
   IF "M"$cPermisos
      oBar:aControls[2]:Click()
      oBrw:GoLeftMost()
  ENDIF
ENDIF
*/
RETURN NIL


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(6),oQryPar,oQryEnt,oQryPro, oForm, lRta := .f., aCor, base, oError,;
      oBrw1,oBrw2,oFont

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_artp` ("+;
                           "`codart` BIGINT(14) NOT NULL,"+;
                           "`nomart` VARCHAR(50),"+;
                           "PRIMARY KEY (codart,nomart)) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_artp ")
oApp:oServer:NextResult()


IF lAlta
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"grupos LIMIT 0")
   base := oQryPro:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"grupos")
   ELSE
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"grupos WHERE codigo = " +ClipValue2Sql(oQry:codigo))
   base := oQryPro:GetRowObj()
   oApp:oServer:Execute("INSERT INTO transi_artp (codart,nomart) "+;
                     "SELECT p.codart,a.nombre FROM ge_"+oApp:cId+"gruposdet p LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                     "WHERE p.codgru = " + ClipValue2Sql(oQry:codigo))
   oApp:oServer:NextResult()
ENDIF
oQryPar:= oApp:oServer:Query("SELECT * FROM transi_artp")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Fragancias, gustos y sabores";
       FROM 05,15 TO 27,80 OF oWnd1 FONT oFont
   
   @ 07, 05 SAY "Codigo:"                   OF oForm PIXEL SIZE 30,20 RIGHT
   @ 22, 05 SAY "Nombre:"                   OF oForm PIXEL SIZE 30,20 RIGHT
   @ 37, 05 SAY "Articulos que participan"  OF oForm PIXEL

   @ 05, 40 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 20, 40 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(30))  
   @ 70,243 BUTTON oBot[3] PROMPT "+" SIZE 12,12 OF oForm PIXEL ACTION(AgregaArt(oForm),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())   
   @ 45, 05 XBROWSE oBrw1 DATASOURCE oQryPar ;
           COLUMNS "codart","nomart";
           HEADERS "Codgio","Detalle del articulo";
           SIZES   100,322 OF oForm SIZE 236, 95 AUTOSORT PIXEL   
   oBrw1:CreateFromCode()  
   PintaBrw(oBrw1,0) 
  
   @100,243 BUTTON oBot[4] PROMPT "-" SIZE 12,12 OF oForm PIXEL ACTION(BorrarArt(oQryPar:codart),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
   oForm:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)}
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF

oQryPro:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryPro:Save()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"gruposdet WHERE codgru = " + ClipValue2Sql(base:codigo))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"gruposdet (codgru,codart) "+;
                       "SELECT "+ClipValue2Sql(base:codigo)+",codart FROM transi_artp") 
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

******************************************************************************
STATIC FUNCTION BorrarArt(codigo)
LOCAL mrta := .f., oError
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el artículo código N°:"+STR(codigo),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM transi_artp WHERE codart = " + ClipValue2Sql(codigo))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


*******************************************************************************
STATIC FUNCTION AgregaArt(oForm)
LOCAL oDlgA,oError,oQryArt,nArticu:=0,cNomArt:=SPACE(30),oGet1,oGet2,;
      oBot:=ARRAY(2),acor:=ARRAY(4),lRta:=.f.
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,precioven,reventa,stockact,stockmin,stockotro FROM ge_"+oApp:cId+"articu")
                              
DEFINE DIALOG oDlgA TITLE "Seleccione el articulo" FROM 05,15 TO 12,70 OF oForm
   @ 12, 05 SAY "Artículo:" OF oDlgA PIXEL SIZE 30,12 RIGHT   
   @ 10, 40 GET oGet1 VAR nArticu OF oDlgA PIXEL PICTURE "99999999999999" SIZE 45,12 RIGHT;
               VALID(BuscarArt(oQryArt,oDlgA,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, BuscarArt(oQryArt,oDlgA,oGet1,oGet2)) BITMAP "BUSC1"
   @ 10, 90 GET oGet2 VAR cNomArt OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)
   acor := AcepCanc(oDlgA)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgA:End() ) PIXEL CANCEL  
    oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)} 
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet1:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction() 
  oApp:oServer:Insert("transi_artp",{"codart","nomart"},{nArticu,cNomArt})
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
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
LOCAL mrta := .f., oError, nNum := oQry:codigo
IF oQry:codigo = 0
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
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"gruposdet WHERE codgru = " + ClipValue2Sql(nNum))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 