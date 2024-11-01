#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

//
*************************************************
** CANCELACION DE PAGOS
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE ORDENES()
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol,nFiltro:=1,oBot,;
      lAdmin:= oApp:oServer:Query("SELECT IF(tipo='ADMIN',TRUE,FALSE) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS ordenes_temp ";
    +"(";
    +"`NUMERO` INT(10),";
    +"`NOMPRO` VARCHAR(50) NOT NULL,";  
    +"`FECHA` DATE NOT NULL,";  
    +"`TOTAL` DECIMAL(12,2) NOT NULL,"; 
    +"`USUARIO` VARCHAR(15) "; 
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE ordenes_temp")
oApp:oServer:NextResult()

AADD(oApp:aVentanas,cVentana)
  oApp:oServer:Execute("INSERT INTO ordenes_temp (numero,nompro,fecha,total,usuario)"+;
				"(SELECT o.numero, p.nombre,o.fecha, o.total,o.usuario  FROM ge_"+oApp:cId+"ordpag o "+;
        " LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
        " WHERE "+IF(lAdmin=1,"1=1"," o.usuario = "+ClipValue2Sql(oApp:usuario))+;
        " AND o.numero IN (SELECT MAX(numero) "+;
        " FROM ge_"+oApp:cId+"ordpag GROUP BY proveedor) AND p.nombre IS NOT NULL)")
  oQryBrw:= oApp:oServer:Query("SELECT * FROM ordenes_temp ")
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Cancelacion de ordenes de pago" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(),oBrw:Refresh());
            PROMPT "Modifica" TOP 
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Pagos",.T.,.F.);
            PROMPT "Reporte" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "numero","nompro","fecha","usuario","total";
              HEADERS "Numero","Proveedor","Fecha","Usuario","Importe";
              SIZES 80,200,100,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQryBrw))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oQryCon,oQryFac,;
      oBrw1,oBrw2, oQryOrden, nTotPag:=0, nTotFac:=0, oQry, nAnti := 0
oQry   := oApp:oServer:Query("SELECT o.*, p.codigo AS codpro, p.nombre AS nompro FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
   	                            "WHERE o.numero = "+ClipValue2Sql(oQryBrw:numero))
oQryCon:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ordcon WHERE numero = " + ClipValue2Sql(oQry:numero))
oQryFac:= oApp:oServer:Query("SELECT *,CONCAT(tipocomp,letra,numfac) AS mostrar FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2Sql(oQry:numero))

DEFINE DIALOG oForm TITLE "Cancelacion de orden de pago" RESOURCE "CANPAG" OF oDlg
  oForm:lHelpIcon := .f.

  REDEFINE SAY PROMPT "Proveedor:" ID 999 OF oForm 
	REDEFINE GET oGet[1] VAR oQry:numero ID 101 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[2] VAR oQry:fecha  ID 102 OF oForm PICTURE "@D" WHEN(.F.)
	REDEFINE GET oGet[3] VAR oQry:codpro ID 103 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[4] VAR oQry:nompro ID 104 OF oForm PICTURE "@!" WHEN(.F.)

	REDEFINE XBROWSE oBrw1 DATASOURCE oQryCon;
              COLUMNS "observa","importe";
              HEADERS "Forma pago","Importe";
              SIZES 205,105;
              ID 201 OF oForm
    PintaBrw(oBrw1,0)

    REDEFINE XBROWSE oBrw2 DATASOURCE oQryFac;
              COLUMNS "mostrar","importe";
              HEADERS "Documento","Importe";
              SIZES 241,70;
              ID 202 OF oForm
    PintaBrw(oBrw2,0) 
    REDEFINE BUTTON oBot[1] ID 301 OF oForm ACTION(lRta:=.t.,oForm:End())
    REDEFINE BUTTON oBot[2] ID 302 OF oForm ACTION(oForm:End())

ACTIVATE DIALOG oForm CENTER ON INIT oBot[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

TRY
oApp:oServer:BeginTransaction()
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"ordpag op ON op.numero = " + ClipValue2Sql(oQry:numero) +;
                     " LEFT JOIN ge_"+oApp:cId+"ordfac o ON c.tipocomp = o.tipocomp AND "+;
                                            "c.letra = o.letra AND "+;
                                            "c.numfac = o.numfac AND "+;
                                            "c.codpro = op.proveedor "+;
                     "SET c.saldo = c.saldo + ABS(o.importe) "+;
                     "WHERE o.numero = " + ClipValue2Sql(oQry:numero))
IF oQry:iddepo > 0
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"deposito WHERE id = " + ClipValue2Sql(oQry:iddepo))
ENDIF
oQryCon:GoTop()
DO WHILE !oQryCon:eof()
	IF oQryCon:codcon = 7
		   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET saldo = saldo + "+ClipValue2Sql(oQryCon:importe)+;
		                        " WHERE codigo = "+ClipValue2Sql(oQry:codpro))
     nAnti := oQryCon:importe  
	ELSE 
    nTotPag:= nTotPag + oQryCon:importe 
  ENDIF
	oQryCon:Skip()
ENDDO
nTotFac := oApp:oServer:Query("SELECT SUM(importe) AS total FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2Sql(oQry:numero)):total
IF nTotPag > nTotFac
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"provee SET saldo = saldo - "+ClipValue2Sql(nTotPag-nTotFac+nAnti)+" "+;
                           "WHERE codigo = "+ClipValue2Sql(oQry:codpro))
ENDIF
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"cheter SET estado = 'C', orden = 0, codpro = 0 WHERE orden = "+ ClipValue2Sql(oQry:numero))
oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"chepro WHERE orden = "+ ClipValue2Sql(oQry:numero))
oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"ordpag WHERE numero = " + ClipValue2Sql(oQry:numero))
Auditar(1," OP:"+alltrim(STR(oQry:numero,10))+" $"+alltrim(STR(oQry:total,12,2))+" Caja "+STR(oQry:caja,4)+" "+ALLTRIM(oQry:nompro))
oApp:oServer:Execute("DELETE FROM ordenes_temp WHERE numero = " + ClipValue2Sql(oQry:numero))
oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY 
oQryBrw:Refresh() 
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

 

