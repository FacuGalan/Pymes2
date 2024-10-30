#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** Carga manual de deudas
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, cVentana
PROCEDURE CARDEU(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw  := oApp:oServer:Query( "SELECT c.*,p.nombre AS nompro FROM ge_"+oApp:cId+"compras c "+;
                                "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Facturas de compra" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta [F2]" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica [F3]" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja [F4]" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta [F5]" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Facturas de venta",.T.,.F.);
            PROMPT "Reporte [F6]" TOP WHEN(oQryBrw:RecCount()>0 .and. "R"$cPermisos)
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "ticomp","numcomp","nompro","importe","saldo";
              HEADERS "Ti","Numero","Proveedor","Importe","Saldo";
              SIZES 50,100,250,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK Formu( .f.)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQryBrw,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
      oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(17), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,cNomPro:=SPACE(30),;
      cNomVen:=SPACE(30),oQry,oQryPro,oQryTip 

oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,localidad FROM ge_"+oApp:cId+"provee")
oQryTip:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipocomp")
IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"compras LIMIT 0")
   base := oQry:GetBlankRow()
   base:fecha:= DATE()
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"compras WHERE ticomp = " + ClipValue2Sql(oQryBrw:ticomp)+" "+;
                             "AND numcomp = " + ClipValue2Sql(oQryBrw:numcomp))
   base := oQry:GetRowObj()
   IF oQryPro:Seek(base:codPro,1) > 0
      cNomPro:= oQryPro:nombre
   ENDIF
ENDIF
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Facturas de compra";
       FROM 05,15 TO 27,67 OF oWnd1
   
   @ 07, 05 SAY "Tipo:"          OF oForm PIXEL SIZE 40,20 RIGHT
   @ 07,200 SAY "Usuario:"       OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 05 SAY "Numero:"        OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 05 SAY "Proveedor:"     OF oForm PIXEL SIZE 40,20 RIGHT
   @ 52, 05 SAY "Fecha:"         OF oForm PIXEL SIZE 40,20 RIGHT
   @ 67, 05 SAY "Neto:"          OF oForm PIXEL SIZE 40,20 RIGHT
   @ 67,105 SAY "I.V.A:"         OF oForm PIXEL SIZE 40,20 
   @ 82, 05 SAY "Retencion:"     OF oForm PIXEL SIZE 40,20 RIGHT
   @ 97, 05 SAY "Imp. interno:"  OF oForm PIXEL SIZE 40,20 RIGHT
   @112, 05 SAY "Importe:"       OF oForm PIXEL SIZE 40,20 RIGHT
   @127, 05 SAY "Saldo:"         OF oForm PIXEL SIZE 40,20 RIGHT

   
  
   @ 05, 50 GET oGet[01] VAR base:ticomp  PICTURE "@!" SIZE 25,12 OF oForm PIXEL WHEN(lAlta);
                VALID(Buscar(oQryTip,oForm,oGet[01]));
                ACTION (oGet[03]:cText:= "0", Buscar(oQryTip,oForm,oGet[01])) BITMAP "BUSC1"
   @ 20, 50 GET oGet[02] VAR base:numcomp PICTURE "99999-99999999" OF oForm PIXEL WHEN(lAlta)
   @ 35, 50 GET oGet[03] VAR base:codpro  PICTURE "999999"         OF oForm PIXEL SIZE 35,12;
                VALID(Buscar(oQryPro,oForm,oGet[03],oGet[04]));
                ACTION (oGet[03]:cText:= 0, Buscar(oQryPro,oForm,oGet[03],oGet[04])) BITMAP "BUSC1"
   @ 35, 90 GET oGet[04] VAR cNomPro      PICTURE "@!"             OF oForm PIXEL WHEN(.F.)          
   @ 50, 50 GET oGet[05] VAR base:fecha   PICTURE "@D"             OF oForm PIXEL CENTER
   @ 65, 50 GET oGet[06] VAR base:neto    PICTURE "999999999.999"  OF oForm PIXEL RIGHT
   @ 65,120 GET oGet[07] VAR base:iva     PICTURE "999999999.999"  OF oForm PIXEL RIGHT;
                WHEN((oGet[07]:cText:= base:neto * 21/100) > "-1")
   @ 80, 50 GET oGet[08] VAR base:reten   PICTURE "999999999.999"  OF oForm PIXEL RIGHT
   @ 95, 50 GET oGet[09] VAR base:impint  PICTURE "999999999.999"  OF oForm PIXEL RIGHT
   @112, 50 GET oGet[10] VAR base:importe PICTURE "999999999.999"  OF oForm PIXEL RIGHT ;
                VALID(base:importe > 0)
   @127, 50 GET oGet[11] VAR base:saldo   PICTURE "999999999.999"  OF oForm PIXEL RIGHT;
                VALID(base:saldo <= base:importe)
              
              
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:importe <= 0
   msgstop("Importe no valido($"+base:importe+")","Atencion!")
   LOOP
ENDIF
IF lAlta                                  
   oQry:GetBlankRow()
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQryBrw:Refresh()
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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el documento: "+oQryBrw:ticomp+" N° "+oQryBrw:numcomp+" ?","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compras WHERE ticomp = " + ClipValue2Sql(oQryBrw:ticomp)+" "+;
                       "AND numcomp = " + ClipValue2Sql(oQryBrw:numcomp))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 