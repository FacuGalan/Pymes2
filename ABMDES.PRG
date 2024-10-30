#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM de descuentos por marca
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE DESCCLI(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQry  := oApp:oServer:Query( "SELECT d.codmar AS codmar,m.nombre AS nombre FROM ge_"+oApp:cId+"desccli d LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = d.codmar GROUP BY d.codmar")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Descuentos por marca" ;
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
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codmar","Nombre";
              HEADERS "Codigo","Nombre";
              SIZES 50,350;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu( .f.),MsgInfo("Sin Permiso")),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(6),oQryPar,oQryEnt,oQryDesc, oForm, lRta := .f., aCor, base, oError,;
      oBrw1,oBrw2,oFont,oQryMarca:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"marcas"),nCodMar:=0,cNomMar:=SPACE(30)

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_artp` ("+;
                           "`codcli` int(8) NOT NULL,"+;
                           "`nomcli` VARCHAR(50),"+;
                           "`descu` DECIMAL(5,2) NOT NULL,"+;
                           "PRIMARY KEY (codcli,nomcli)) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_artp ")
oApp:oServer:NextResult()


IF !lAlta
   nCodMar:= oQry:codmar 
   cNomMar:= oQry:nombre
   oApp:oServer:Execute("INSERT INTO transi_artp (codcli,nomcli,descu) "+;
                     "(SELECT d.codcli,c.nombre,d.descuento FROM ge_"+oApp:cId+"desccli d LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = d.codcli "+;
                     "WHERE d.codmar = "+ClipValue2Sql(oQry:codmar)+")")
   oApp:oServer:NextResult()
ENDIF
oQryPar:= oApp:oServer:Query("SELECT * FROM transi_artp")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Descuentos por marca";
       FROM 05,15 TO 27,80 OF oWnd1 FONT oFont
   
   @ 07, 05 SAY "Codigo:"                   OF oForm PIXEL SIZE 30,20 RIGHT
   @ 22, 05 SAY "Marca:"                    OF oForm PIXEL SIZE 30,20 RIGHT
   @ 37, 05 SAY "Clientes afectados"        OF oForm PIXEL

   @ 05, 40 GET oGet[1] VAR nCodMar     PICTURE "999" OF oForm PIXEL RIGHT SIZE 25,12 WHEN(lAlta);
                VALID(Buscar(oQryMarca,oForm,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryMarca,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 20, 40 GET oGet[2] VAR cNomMar     PICTURE "@!"    OF oForm PIXEL WHEN(.F.)
   @ 70,243 BUTTON oBot[3] PROMPT "+" SIZE 12,12 OF oForm PIXEL ACTION(AgregaArt(oForm),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())   
   @ 45, 05 XBROWSE oBrw1 DATASOURCE oQryPar ;
           COLUMNS "nomcli","descu";
           HEADERS "Cliente","Descuento";
           SIZES   322,100 OF oForm SIZE 236, 95 AUTOSORT PIXEL   
   oBrw1:CreateFromCode()  
   PintaBrw(oBrw1,0) 
   oBrw1:nfreeze:=3
   oBrw1:aCols[2]:lAutoSave := .t.
   oBrw1:aCols[2]:nEditType := EDIT_GET  
   oBrw1:aCols[2]:bOnPostEdit := {|oCol, xVal, nKey | oQryPar:descu:=xVal,oQryPar:Save()}
  
   @100,243 BUTTON oBot[4] PROMPT "-" SIZE 12,12 OF oForm PIXEL ACTION(BorrarArt(oQryPar:codcli),oQryPar:Refresh(),;
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

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"desccli WHERE codmar = " + ClipValue2Sql(nCodMar))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"desccli (codmar,codcli,descuento) "+;
                       "SELECT "+ClipValue2Sql(nCodMar)+",codcli,descu FROM transi_artp") 
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
                 "el cliente código N°:"+STR(codigo),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM transi_artp WHERE codcli = " + ClipValue2Sql(codigo))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


*******************************************************************************
STATIC FUNCTION AgregaArt(oForm)
LOCAL oDlgA,oError,oQryCli,nCliente:=0,cNomCli:=SPACE(30),oGet1,oGet2,oGet3,;
      oBot:=ARRAY(2),acor:=ARRAY(4),lRta:=.f.,nDescuento:=0
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes") 
                              
DEFINE DIALOG oDlgA TITLE "Seleccione el cliente" FROM 05,15 TO 14,70 OF oForm
   @ 12, 05 SAY "Cliente:" OF oDlgA PIXEL SIZE 30,12 RIGHT   
   @ 27, 05 SAY "Descuento:" OF oDlgA PIXEL SIZE 30,12 RIGHT
   @ 10, 40 GET oGet1 VAR nCliente OF oDlgA PIXEL PICTURE "99999999" SIZE 30,12 RIGHT;
               VALID(Buscar(oQryCli,oDlgA,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, Buscar(oQryCli,oDlgA,oGet1,oGet2)) BITMAP "BUSC1"
   @ 10, 90 GET oGet2 VAR cNomCli OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)
   @ 25, 40 GET oGet3 VAR nDescuento OF oDlgA PIXEL PICTURE "999.99"

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
  oApp:oServer:Insert("transi_artp",{"codcli","nomcli","descu"},{nCliente,cNomCli,nDescuento})
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
LOCAL mrta := .f., oError, nNum := oQry:codmar
IF oQry:codmar = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute( "DELETE FROM ge_"+oApp:cId+"desccli WHERE codmar ="+ClipValue2Sql(nNum))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)
CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 