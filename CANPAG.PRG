#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

//
*************************************************
** CANCELACION DE PAGOS
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError,nFiltro
PROCEDURE PAGOS()
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol,oBot,lFiltro:=.t.
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
nFiltro:=0
AADD(oApp:aVentanas,cVentana)

  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS pagos_temp ";
    +"(";
    +"`NUMERO` INT(10),";
    +"`NOMCLI` VARCHAR(50) NOT NULL,";  
    +"`FECHA` DATE NOT NULL,";  
    +"`DEMO` TINYINT(1) NOT NULL,";  
    +"`TOTAL` DECIMAL(10,2) NOT NULL"; 
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE pagos_temp")
oApp:oServer:NextResult()
IF oApp:oServer:Query("SELECT tipo FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):tipo = "ADMIN"
	lFiltro:=.f.
ENDIF

   oApp:oServer:Execute( "INSERT INTO pagos_temp (numero,nomcli,fecha,total,demo) "+;
                                "(SELECT p.numero, c.nombre, p.fecha, p.total, p.demo  FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
   	                            "LEFT JOIN (SELECT MAX(numero) AS num FROM ge_"+oApp:cId+"pagos GROUP BY cliente) p1 ON p1.num = p.numero "+;
                                "WHERE  p.numero = p1.num )")

   oQryBrw:= oApp:oServer:Query("SELECT * FROM pagos_temp WHERE demo = "+ClipValue2Sql(nFiltro))
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Cancelacion de pagos de clientes" ;
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
              COLUMNS "numero","nomcli","fecha","total";
              HEADERS "Numero","Cliente","Fecha","Importe";
              SIZES 80,200,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,4) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQryBrw))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oQryCon,oQryFac,;
      oBrw1,oBrw2, oQryOrden, nTotPag:=0, nTotFac:=0,oQry , nTotAnt := 0

oQry   := oApp:oServer:Query( "SELECT p.*, c.codigo AS codcli, c.nombre AS nomcli FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
                                "WHERE p.numero = "+ClipValue2Sql(oQryBrw:numero))
oQryCon:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"pagcon WHERE numero = " + ClipValue2Sql(oQry:numero))
oQryFac:= oApp:oServer:Query("SELECT *,CONCAT(ticomp,letra,numcomp) AS mostrar FROM ge_"+oApp:cId+"pagfac WHERE numero = " + ClipValue2Sql(oQry:numero))

DEFINE DIALOG oForm TITLE "Cancelacion de pago" RESOURCE "CANPAG" OF oDlg
	oForm:lHelpIcon := .f.
	
	REDEFINE GET oGet[1] VAR oQry:numero ID 101 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[2] VAR oQry:fecha  ID 102 OF oForm PICTURE "@D" WHEN(.F.)
	REDEFINE GET oGet[3] VAR oQry:codcli ID 103 OF oForm PICTURE "999999" WHEN(.F.)
	REDEFINE GET oGet[4] VAR oQry:nomcli ID 104 OF oForm PICTURE "@!" WHEN(.F.)

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
nTotFac := 0
nTotAnt := 0
TRY
oApp:oServer:BeginTransaction()
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_cuota v LEFT JOIN ge_"+oApp:cId+"pagfac p ON v.tipo = p.ticomp AND "+;
                                                                  "v.letra = p.letra AND "+;
                                                                  "v.numero = p.numcomp "+;
                     "SET v.saldo = v.saldo + ABS(p.importe) "+;
                     "WHERE p.numero = " + ClipValue2Sql(oQry:numero))
IF oQry:iddepo > 0
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"deposito WHERE id = " + ClipValue2Sql(oQry:iddepo))
ENDIF
oQryCon:GoTop()
DO WHILE !oQryCon:eof()
	IF oQryCon:codcon = 7			   
     nTotAnt := nTotAnt + oQryCon:importe                       	
	   ELSE 
     nTotPag:= nTotPag + oQryCon:importe 
  ENDIF
	oQryCon:Skip()
ENDDO
nTotFac := oApp:oServer:Query("SELECT SUM(importe) AS total FROM ge_"+oApp:cId+"pagfac WHERE numero = " + ClipValue2Sql(oQry:numero)):total
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = saldo - "+ClipValue2Sql(nTotPag-nTotFac)+" "+;
                           "WHERE codigo = "+ClipValue2Sql(oQry:codcli))   
oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"cheter WHERE recibo = "+ ClipValue2Sql(oQry:numero))
oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pagos  WHERE numero = " + ClipValue2Sql(oQry:numero))
oApp:oServer:Execute("DELETE FROM pagos_temp  WHERE numero = " + ClipValue2Sql(oQry:numero))
Auditar(1," REC: "+alltrim(STR(oQry:numero,10))+" $"+alltrim(STR(oQry:total,12,2))+" Caja "+STR(oQry:caja,4)+" "+ALLTRIM(oQry:nomcli))
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