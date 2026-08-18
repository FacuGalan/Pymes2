#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM DE FORMAS DE PAGO
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE FORPAG(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
ValidarForpagDesc()

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"forpag ORDER BY nombre")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de formas de pago" ;
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
            ACTION oBrw:Report("Reporte de Formas de pago",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         IF oApp:usar_cuotas
            DEFINE BUTTON RESOURCE "TASA" OF oBar ;
            TOOLTIP "Tabla de Intereses Por mora"  ;
            ACTION TablaIndices(oDlg);
            PROMPT "Indices" TOP WHEN("A"$cPermisos) 
         ENDIF
         DEFINE BUTTON RESOURCE "CAMPRE" OF oBar ;
            TOOLTIP "Descuentos por forma de pago segun importe"  ;
            ACTION DescuentosForma(oQry:codigo);
            PROMPT "Descuentos" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
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
              HEADERS "Codigo","Nombre";
              SIZES 50,350;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(11), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,poriva,;
      aTipos:={"Efectivo","Transferencia","Cheque","Tarjeta","Cuenta Corriente","Mercado Pago"},;
      oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas"),cNomCue:=SPACE(100)
IF lAlta
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"forpag")
   base:tactil := .f.
   base:tipo := 1
   ELSE
   base := oQry:GetRowObj()
   oQry:lAppend := .f.
   IF base:codcue > 0
       oQryCue:GoTop()
       IF oQryCue:Seek(base:codcue,1) > 0
          cNomCue := oQryCue:nombre
       ENDIF
   ENDIF    
ENDIF
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Formas de pago";
       FROM 05,15 TO 21,65 OF oWnd1
   
   @ 07, 05 SAY "Codigo:"         OF oForm PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oForm PIXEL SIZE 50,20 RIGHT
   @ 37, 05 SAY "Tipo:"           OF oForm PIXEL SIZE 50,20 RIGHT 
   @ 52, 05 SAY "Incremento %:"   OF oForm PIXEL SIZE 50,20 RIGHT
   @ 67, 05 SAY "Cuenta:"         OF oForm PIXEL SIZE 50,20 RIGHT
  
   @ 05, 60 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 20, 60 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(30))   
   @ 35, 60 COMBOBOX oGet[3] VAR base:tipo ITEMS aTipos OF oForm PIXEL SIZE 55,12
   @ 50, 60 GET oGet[4] VAR base:incremento PICTURE "999.99" OF oForm PIXEL RIGHT 
   @ 65, 60 GET oGet[9] VAR base:codcue OF oForm PIXEL PICTURE "999" SIZE 25,12 RIGHT WHEN(base:tipo = 2);
            VALID(base:codcue = 0 .or. Buscar(oQryCue,oForm,oGet[9],oGet[10]));
            ACTION (oGet[9]:cText:= -1, Buscar(oQryCue,oForm,oGet[9],oGet[10])) BITMAP "BUSC1" 
   @ 65,90 GET oGet[10] VAR cNomCue OF oForm PIXEL PICTURE "@S20" ;
              WHEN((oGet[10]:cText := IF(base:codcue=0,'SIN ASIGNAR CUENTA',cNomCue)) = 'x-x-x-x-')
   @ 05,130 CHECKBOX oGet[5] VAR base:tactil OF oForm PIXEL PROMPT "Visible en tactil" SIZE 150,12  
   @ 80,05  CHECKBOX oGet[11] VAR base:lFiscal OF oForm PIXEL PROMPT "Es una forma de pago Fiscal" SIZE 150,12 

   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
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
*************************************************
** Validacion de la tabla de descuentos por forma de pago (crea si no existe)
STATIC FUNCTION ValidarForpagDesc()
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"forpag_desc")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"forpag_desc ( "+;
  "`id` INT(8) AUTO_INCREMENT,"+;
  "`codfor` INT NOT NULL,"+;
  "`desde_importe` DECIMAL(12,2) DEFAULT 0,"+;
  "`hasta_importe` DECIMAL(12,2) DEFAULT 0,"+;
  "`porcentaje` DECIMAL(5,2) DEFAULT 0,"+;
  "PRIMARY KEY (`id`),"+;
  "KEY `codfor` (`codfor`)"+;
") ENGINE=INNODB DEFAULT CHARSET=utf8")
ENDIF
RETURN nil

*************************************************
** ABM de rangos de descuento por importe para una forma de pago
STATIC FUNCTION DescuentosForma(nCodFor)
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp, cNomFor,;
      oQryR := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"forpag_desc WHERE codfor = "+ClipValue2Sql(nCodFor)+" ORDER BY desde_importe")
cNomFor := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"forpag WHERE codigo = "+ClipValue2Sql(nCodFor)):nombre
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Descuentos por importe - "+ALLTRIM(cNomFor) FROM 03,15 TO 23,72
   acor := AcepCanc(oDlg1)
   @ 05, 05 SAY "Al cobrar con esta forma de pago, si el TOTAL de la venta cae en el rango, se agrega el % como descuento." OF oDlg1 PIXEL SIZE 190,40
   @ 20, 05 XBROWSE oBrwTmp SIZE 180,80 PIXEL OF oDlg1 DATASOURCE oQryR ;
      HEADERS "Desde importe", "Hasta importe", "% Descuento";
      COLUMNS "desde_importe","hasta_importe","porcentaje";
      SIZES 110,110,80;
      CELL LINES NOBORDER
   WITH OBJECT oBrwTmp
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}
      :CreateFromCode()
   END
   PintaBrw(oBrwTmp,0)
   @ acor[3], acor[2] BUTTON oBot1 PROMPT "&Agregar" OF oDlg1 SIZE 30,10 ;
           ACTION (NuevoRango(oQryR,oBrwTmp,oDlg1,nCodFor)) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Salir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF
ENDDO
RETURN nil

*************************************************
** Alta de un rango de descuento (con validacion de no-solapamiento)
STATIC FUNCTION NuevoRango(oQryR,oBrwTmp,oWnd,nCodFor)
LOCAL oGet := ARRAY(3), oDlg1, oBot := ARRAY(2), aCor, base, lRta := .f., oError
base := oQryR:GetBlankRow()
base:codfor := nCodFor
base:desde_importe := 0
base:hasta_importe := 0
base:porcentaje := 0
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Nuevo rango de descuento" FROM 03,15 TO 14,55 OF oWnd
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Desde importe:" OF oDlg1 PIXEL SIZE 65,12 RIGHT
   @ 22, 05 SAY "Hasta importe:" OF oDlg1 PIXEL SIZE 65,12 RIGHT
   @ 37, 05 SAY "% Descuento:"   OF oDlg1 PIXEL SIZE 65,12 RIGHT
   @ 05, 80 GET oGet[1] VAR base:desde_importe PICTURE "999999999.99" OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 20, 80 GET oGet[2] VAR base:hasta_importe PICTURE "999999999.99" OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 35, 80 GET oGet[3] VAR base:porcentaje    PICTURE "999.99" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER
IF !lRta
   RETURN nil
ENDIF
IF base:hasta_importe <= base:desde_importe .or. base:porcentaje <= 0
   MsgStop("El importe Hasta debe ser mayor al Desde, y el porcentaje mayor a cero","Error")
   LOOP
ENDIF
IF oApp:oServer:Query("SELECT id FROM ge_"+oApp:cId+"forpag_desc WHERE codfor = "+ClipValue2Sql(nCodFor)+;
        " AND desde_importe <= "+ClipValue2Sql(base:hasta_importe)+;
        " AND hasta_importe >= "+ClipValue2Sql(base:desde_importe)):nRecCount > 0
   MsgStop("El rango se solapa con otro ya existente para esta forma de pago","Error")
   LOOP
ENDIF
oQryR:GetBlankRow()
oQryR:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryR:Save()
  oApp:oServer:CommitTransaction()
  oQryR:Refresh()
  oBrwTmp:Refresh()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

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
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


STATIC FUNCTION TablaIndices(oWnd)
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      i, cError, cSql,;
      oQrySeg:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"indexa ORDER BY dias")
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Tabla de indices de Intereses por Mora" FROM 03,15 TO 35,40
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 100,180 pixel OF oDlg1 DATASOURCE oQrySeg ;
      HEADERS "Dias", "Indice";
      COLUMNS "dias","indice";
      SIZES 80,80;
      CELL LINES NOBORDER 
   WITH OBJECT oBrwTmp
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
      :nFreeze := 2
   END  
   PintaBrw(oBrwTmp,0)
   @ 05, acor[2] BUTTON oBot1 PROMPT "&Nuevo" OF oDlg1 SIZE 30,10 ;
           ACTION (NuevaObs(oQrySeg,oBrwTmp, oDlg1)) PIXEL
   @ 05, acor[4] BUTTON oBot1 PROMPT "&Editar" OF oDlg1 SIZE 30,10 ;
           ACTION (VerObs(oQrySeg,oBrwTmp,oDlg1)) PIXEL   
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Salir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN nil 
ENDIF 
ENDDO 
RETURN nil

STATIC FUNCTION NuevaObs(oQrySeg,oBrwTmp, oWnd)
LOCAL oGet := ARRAY(6), oDlg1, oBot := ARRAY(2), aCor, base, lRta := .f., lAgendar := .F.,;
      mfecha := CTOD('  /  /    '), mhora := TIME(), oError
base := oQrySeg:GetBlankRow()
base:dias := 0
base:indice := 1
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Nuevo Indice" FROM 03,15 TO 12,40 OF oWnd
   acor := AcepCanc(oDlg1)  
   @ 07, 05 SAY "Dias:"         OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Indice:"       OF oDlg1 PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:dias   PICTURE "999" OF oDlg1 PIXEL RIGHT
   @ 20, 65 GET oGet[2] VAR base:indice PICTURE "999.9999" OF oDlg1 PIXEL RIGHT

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !lRta
   RETURN nil
ENDIF
IF EMPTY(base:indice)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQrySeg:GetBlankRow()
oQrySeg:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQrySeg:Save()
  oApp:oServer:CommitTransaction()
  oQrySeg:Refresh()
  oBrwTmp:Refresh()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil 

STATIC FUNCTION VerObs(oQrySeg,oBrwTmp,oWnd)
LOCAL oGet := ARRAY(6), oDlg1, oBot := ARRAY(2), aCor, base, lRta := .f., oError
base := oQrySeg:GetRowObj()
oQrySeg:lAppend := .f. 
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Editar Indice" FROM 03,15 TO 12,60 OF oWnd
   acor := AcepCanc(oDlg1)  
   @ 07, 05 SAY "Dias:"         OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Indice:"       OF oDlg1 PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:dias   PICTURE "999" OF oDlg1 PIXEL RIGHT
   @ 20, 65 GET oGet[2] VAR base:indice PICTURE "999.9999" OF oDlg1 PIXEL RIGHT
      
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !lRta
   RETURN nil
ENDIF
IF EMPTY(base:indice)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQrySeg:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQrySeg:Save()  
  oApp:oServer:CommitTransaction()
  oQrySeg:Refresh()
  oBrwTmp:Refresh()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil