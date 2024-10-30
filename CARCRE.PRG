#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** CARGA MANUAL DE CREDITOS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE CarCre()
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query( "SELECT v.ticomp AS ticomp, v.letra AS letra, v.numcomp AS numcomp, c.nombre AS nomcli, "+;
                                "v.fecha AS fecha, v.importe AS importe, vc.saldo AS saldo, v.codcli AS codcli "+;
                                "FROM ge_"+oApp:cId+"ventas_encab v "+;
                                "INNER JOIN ge_"+oApp:cId+"ventas_cuota vc ON vc.tipo = v.ticomp AND vc.letra = v.letra AND vc.numero = v.numcomp "+;
   	                            "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;
                                "WHERE vc.estado = 'I' AND (v.ticomp = 'PR' OR v.ticomp = 'NP') ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Carga manual de credito" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Ver Registro"  ;
            ACTION (Formu(.f. ),oBrw:Refresh());
            PROMPT "Ver [F2]" TOP 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja [F3]" TOP 
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta [F4]" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Cuotas ",.T.,.F.);
            PROMPT "Reporte [F5]" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ticomp","letra","numcomp","nomcli","fecha","importe","saldo";
              HEADERS "Documento","Letra","Numero","Cliente","Fecha","Importe","Saldo";
              SIZES 60,60,110,250,80,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(.f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,7) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
      
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(2), oForm, lRta := .f., aCor, base,oQry2,oQryTip,oQryCli,;
      cNomCli:=SPACE(30),nNum1:=SPACE(4),nNum2:=SPACE(8)

oQryTip:= oApp:oServer:Query("SELECT codigo,nombre,prefijo FROM ge_"+oApp:cId+"tipocomp ORDER BY prefijo")
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"clientes ORDER BY codigo")

   base := oQry:GetRowObj()
   oQry:lAppend := .f.
   nNum1:=LEFT(base:numcomp,4)
   nNum2:=RIGHT(base:numcomp,8)
   oQryCli:GoTop()
   IF oQryCli:Seek(base:codcli,1) > 0
      cNomCli:= oQryCli:nombre
   ENDIF


DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Cuota de venta";
       FROM 05,15 TO 22,70 OF oWnd1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Tipo Documento:"   OF oForm PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Letra:"            OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Numero:"           OF oForm PIXEL SIZE 50,12 RIGHT
   @ 52, 05 SAY "Cliente:"          OF oForm PIXEL SIZE 50,12 RIGHT 
   @ 67, 05 SAY "Fecha:"            OF oForm PIXEL SIZE 50,12 RIGHT
   @ 82, 05 SAY "Importe:"          OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37, 80 SAY "-"                 OF oForm PIXEL SIZE 3,12
   @ 95, 05 SAY "Saldo:"            OF oForm PIXEL SIZE 50,12 RIGHT
 
   @ 05, 60 GET oGet[01] VAR base:ticomp  PICTURE "@!" SIZE 13,12 OF oForm PIXEL WHEN(.f.)
   @ 20, 60 GET oGet[02] VAR base:letra   OF oForm PICTURE "@!" PIXEL WHEN(.f.) 
   @ 35, 60 GET oGet[03] VAR nNum1        OF oForm PICTURE "9999" PIXEL RIGHT WHEN(.f.);
                VALID((oGet[3]:cText:= STRTRAN(STR(VAL(oGet[3]:cText),4)," ","0")) <> "xxx")
    oGet[3]:bGotFocus:={|| oGet[3]:SelectAll()}
   @ 35, 85 GET oGet[04] VAR nNum2        OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(.f.);
                VALID((oGet[4]:cText:= STRTRAN(STR(VAL(oGet[4]:cText),8)," ","0")) <> "xxx")
    oGet[4]:bGotFocus:={|| oGet[4]:SelectAll()}
   @ 50, 60 GET oGet[05] VAR base:codcli OF oForm PICTURE "999999" PIXEL SIZE 35,12 RIGHT WHEN(.f.);
                VALID(Buscar(oQryCli,oForm,oGet[05],oGet[06]));
                ACTION (oGet[05]:cText:= 0, Buscar(oQryCli,oForm,oGet[05],oGet[06])) BITMAP "BUSC1"   
   @ 50,100 GET oGet[06] VAR cNomCli      OF oForm PICTURE "@!" PIXEL WHEN(.F.)
   @ 65, 60 GET oGet[07] VAR base:fecha   OF oForm PICTURE "@D" PIXEL CENTER WHEN(.f.)
   @ 80, 60 GET oGet[08] VAR base:importe OF oForm PICTURE "99999999.99" PIXEL RIGHT WHEN(.f.)
   @ 95, 60 GET oGet[09] VAR base:saldo   OF oForm PICTURE "99999999.99" PIXEL RIGHT WHEN(.F.) 
 
 @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

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
LOCAL mrta := .f., oError
IF oQry:importe <> oQry:saldo
   msgstop("La factura elegida tiene un pago parcial realizado "+CHR(10)+;
           "Imposible borrar","Atencion!")
   RETURN nil
ENDIF

mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el comprobante "+oQry:ticomp+" "+oQry:letra+" "+oQry:numcomp,"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_cuota WHERE tipo = " + ClipValue2Sql(oQry:ticomp)+" AND "+;
   	                                                          "letra = "+ ClipValue2Sql(oQry:letra)+" AND "+;
   	                                                          "numero = "+ ClipValue2Sql(oQry:numcomp))
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_det WHERE numfac = " + ClipValue2Sql(oQry:ticomp+oQry:letra+oQry:numcomp))
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = " + ClipValue2Sql(oQry:ticomp)+" AND "+;
                                                              "letra = "+ ClipValue2Sql(oQry:letra)+" AND "+;
                                                              "numcomp = "+ ClipValue2Sql(oQry:numcomp))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.f.)

CATCH oError
    ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 

 