#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

//
*************************************************
** CANCELACION DE PAGOS
*************************************************
MEMVAR oApp
STATIC oQryBrw, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError,;
       lAdmin, lConc, dDesde
PROCEDURE ORDENES()
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol,nFiltro:=1,oBot
lAdmin := oApp:oServer:Query("SELECT IF(tipo='ADMIN',TRUE,FALSE) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin
// Cliente con la cta cte conciliada (CTAPROV.PRG): se puede anular cualquier OP.
// Sin conciliar: solo la ultima de cada proveedor (la logica vieja descuadra si no)
lConc  := CtaProvConciliado()
dDesde := DATE() - 90
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
    +"`TOTAL` DECIMAL(14,2) NOT NULL,";
    +"`USUARIO` VARCHAR(15), ";
    +"`PROVEEDOR` INT(6) ";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE ordenes_temp")
oApp:oServer:NextResult()

AADD(oApp:aVentanas,cVentana)
  CargarOPs()
  oQryBrw:= oApp:oServer:Query("SELECT * FROM ordenes_temp ORDER BY numero DESC")
   DEFINE WINDOW oWnd1 MDICHILD TITLE TituloOPs() ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(),oBrw:Refresh());
            PROMPT "Modifica" TOP
         IF lConc
            DEFINE BUTTON RESOURCE "FILT" OF oBar ;
               TOOLTIP "Mostrar las ordenes desde una fecha"  ;
               ACTION CambiarDesde();
               PROMPT "Desde" TOP
         ENDIF
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Pagos",.T.,.F.);
            PROMPT "Reporte" TOP
         DEFINE BUTTON RESOURCE "PAGO" OF oBar ;
            TOOLTIP "Composicion del anticipo del proveedor"  ;
            ACTION VerAnticipo();
            PROMPT "Anticipo" TOP
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
      oBrw1,oBrw2, oQryOrden, oQry, aArr, aRes
oQry   := oApp:oServer:Query("SELECT o.*, p.codigo AS codpro, p.nombre AS nompro FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
   	                            "WHERE o.numero = "+ClipValue2Sql(oQryBrw:numero))
oQryCon:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ordcon WHERE numero = " + ClipValue2Sql(oQry:numero))
oQryFac:= oApp:oServer:Query("SELECT *,CONCAT(tipocomp,letra,numfac) AS mostrar FROM ge_"+oApp:cId+"ordfac WHERE numero = " + ClipValue2Sql(oQry:numero))
IF oQry:RecCount() = 0
   MsgStop("La orden de pago ya no existe (la anularon desde otro puesto)","Atencion")
   RETURN nil
ENDIF
IF VALTYPE(oQry:observa) = "C" .AND. ALLTRIM(oQry:observa) == CtaProvObsAjuste()
   MsgStop("La orden de ajuste de la conciliacion no se puede anular","Atencion")
   RETURN nil
ENDIF

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

// Caja cerrada, retenciones de un mes anterior o cheques: solo ADMIN sigue
IF !AvisosOP(oQry)
   RETURN nil
ENDIF

// Si el anticipo que genero esta OP ya se uso en pagos posteriores, avisar
// antes que facturas vuelven a quedar con saldo (CTAPROV.PRG)
aArr := CtaProvSimularAnul(oQry:numero)
IF LEN(aArr) > 0 .AND. !AvisoArrastre(oQry:numero, aArr)
   RETURN nil
ENDIF

CtaProvCrearAnul()   // DDL: fuera de la transaccion
TRY
oApp:oServer:BeginTransaction()
// Guarda la copia en ordpag_anul, borra la OP y rehace los saldos
aRes := CtaProvAnularOP(oQry:numero)
Auditar(1," OP:"+alltrim(STR(oQry:numero,10))+" $"+alltrim(STR(oQry:total,12,2))+" Caja "+STR(oQry:caja,4)+" "+ALLTRIM(oQry:nompro)+;
        IF(VALTYPE(oQry:id_cierre) = "N" .AND. oQry:id_cierre > 0, " Cierre "+ALLTRIM(STR(oQry:id_cierre)), ""))
oApp:oServer:Execute("DELETE FROM ordenes_temp WHERE numero = " + ClipValue2Sql(oQry:numero))
oApp:oServer:CommitTransaction()
IF aRes <> nil .AND. ROUND(aRes[3] - aRes[2],2) <> 0
   MsgInfo("Orden de pago anulada."+CHR(10)+CHR(10)+;
           "Anticipo del proveedor:"+CHR(10)+;
           "antes $ "+ALLTRIM(TRANSFORM(aRes[2],"999,999,999.99"))+CHR(10)+;
           "ahora $ "+ALLTRIM(TRANSFORM(aRes[3],"999,999,999.99")),"Atencion")
ENDIF
CATCH oError
    ValidaError(oError)
END TRY
// Recargo: por el arrastre otra OP pudo quedar vacia y eliminarse
CargarOPs()
oQryBrw:Refresh()
RETURN nil

***************************************
** Aviso de arrastre: la OP a anular genero un anticipo que ya se uso para
** pagar facturas en OPs posteriores. Al anularla esas facturas vuelven a
** quedar con saldo. Devuelve .t. si el usuario confirma.
STATIC FUNCTION AvisoArrastre(nOp, aArr)
LOCAL cTxt, i, nTot := 0
cTxt := "El anticipo que genero la OP "+ALLTRIM(STR(nOp))+" ya se uso en pagos posteriores."+CHR(10)+;
        "Si la anula, estas facturas dejan de estar pagadas y vuelven a tener saldo:"+CHR(10)+CHR(10)
FOR i := 1 TO LEN(aArr)
    IF i <= 12
       cTxt += "OP "+ALLTRIM(STR(aArr[i,1]))+" del "+IF(VALTYPE(aArr[i,2])="D",DTOC(aArr[i,2]),"")+":  "+;
               ALLTRIM(aArr[i,3])+" "+ALLTRIM(aArr[i,4])+" "+ALLTRIM(aArr[i,5])+;
               "   $ "+ALLTRIM(TRANSFORM(aArr[i,6],"999,999,999.99"))+;
               IF(aArr[i,7], "  (la OP queda vacia y se elimina)", "")+CHR(10)
    ENDIF
    nTot += aArr[i,6]
NEXT i
IF LEN(aArr) > 12
   cTxt += "... y "+ALLTRIM(STR(LEN(aArr)-12))+" mas"+CHR(10)
ENDIF
cTxt += CHR(10)+"Total que vuelve a deberse: $ "+ALLTRIM(TRANSFORM(nTot,"999,999,999.99"))+CHR(10)+;
        "Esas OPs quedan modificadas y se registra en el detalle del anticipo."+CHR(10)+CHR(10)+;
        "Confirma la anulacion?"
RETURN MsgNoYes(cTxt,"Atencion")

***************************************
** Composicion del anticipo del proveedor de la fila elegida
STATIC FUNCTION VerAnticipo()
LOCAL oForm, oBrwA, aRow := {}, acor, oBot := ARRAY(2), i, oChk, lCompleto := .f., nCod
IF oQryBrw:RecCount() = 0
   RETURN nil
ENDIF
nCod := oQryBrw:proveedor
AntiFilas(nCod, .f., aRow)
DEFINE DIALOG oForm TITLE "Composicion del anticipo - "+ALLTRIM(oQryBrw:nompro) ;
       FROM 03,10 TO 33,145 OF oWnd1 FONT oApp:oFont
   acor := AcepCanc(oForm)
   oForm:lHelpIcon := .f.
   @ 05, 05 XBROWSE oBrwA SIZE 520,170 PIXEL OF oForm ARRAY aRow ;
      HEADERS "Fecha","Detalle","OP","Pagado","Aplicado","Anticipo","Acumulado" ;
      COLUMNS 1,2,3,4,5,6,7 ;
      SIZES 70,490,50,90,90,90,90 ;
      CELL LINES NOBORDER
   WITH OBJECT oBrwA
      :lHScroll := .f.
      :aCols[1]:nDataStrAlign := AL_CENTER
      :aCols[3]:cEditPicture := "@Z 99999999"
      FOR i := 4 TO 7
          :aCols[i]:cEditPicture := "@Z 999,999,999.99"
      NEXT i
      :CreateFromCode()
   END
   PintaBrw(oBrwA,0)
   // Resalta el anticipo actual y el titulo de anuladas
   oBrwA:bClrStd := { || IF( LEN(aRow) > 0 .AND. LEFT(aRow[oBrwA:nArrayAt,2],3) $ "ANT,---", ;
                             { CLR_BLACK, RGB(255,230,150) }, ;
                             IF( oBrwA:KeyNo() % 2 == 0, { CLR_BLACK, RGB(193,221,255) }, ;
                                                         { CLR_BLACK, RGB(221,245,255) } ) ) }
   // Normal: arranca en el anticipo al conciliar. Completa: desde la primer OP
   @ acor[1]+1, 08 CHECKBOX oChk VAR lCompleto PROMPT "Historia completa" OF oForm SIZE 80,10 PIXEL ;
           ON CHANGE (AntiFilas(nCod, lCompleto, aRow), oBrwA:GoTop(), oBrwA:Refresh())
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Excel" OF oForm SIZE 30,10 ;
           ACTION oBrwA:ToExcel() PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cerrar" OF oForm SIZE 30,10 ;
           ACTION oForm:End() PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER
RETURN nil

***************************************
** Llena aRow (en el lugar, lo usa la grilla) con la composicion del anticipo.
** Las fechas van como texto: las filas sin fecha quedan en blanco.
STATIC FUNCTION AntiFilas(nCod, lCompleto, aRow)
LOCAL aNue := CtaProvComposicion(nCod, , , lCompleto), i
ASIZE(aRow, 0)
FOR i := 1 TO LEN(aNue)
    aNue[i,1] := IF(EMPTY(aNue[i,1]), "", DTOC(aNue[i,1]))
    AADD(aRow, aNue[i])
NEXT i
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

*************************************
** Llena ordenes_temp. Conciliado: todas las OPs desde dDesde. Sin conciliar:
** solo la ultima de cada proveedor. El que no es ADMIN ve solo las suyas.
** La OP de ajuste de la conciliacion (CTAPROV.PRG) no se muestra ni se anula
STATIC FUNCTION CargarOPs()
LOCAL cP := "ge_"+oApp:cId, cAjuste := ClipValue2Sql(CtaProvObsAjuste())
oApp:oServer:Execute("TRUNCATE ordenes_temp")
oApp:oServer:Execute("INSERT INTO ordenes_temp (numero,nompro,fecha,total,usuario,proveedor)"+;
        "(SELECT o.numero, p.nombre,o.fecha, o.total,o.usuario,o.proveedor  FROM "+cP+"ordpag o "+;
        " LEFT JOIN "+cP+"provee p ON p.codigo = o.proveedor "+;
        " WHERE "+IF(lAdmin=1,"1=1"," o.usuario = "+ClipValue2Sql(oApp:usuario))+;
        " AND IFNULL(o.observa,'') <> "+cAjuste+;
        IF(lConc, " AND o.fecha >= "+ClipValue2Sql(dDesde),;
                  " AND o.numero IN (SELECT MAX(numero) FROM "+cP+"ordpag "+;
                  " WHERE IFNULL(observa,'') <> "+cAjuste+" GROUP BY proveedor)")+;
        " AND p.nombre IS NOT NULL)")
RETURN nil

STATIC FUNCTION TituloOPs()
RETURN "Cancelacion de ordenes de pago"+;
       IF(lConc, " - desde el "+DTOC(dDesde), " - ultima orden de cada proveedor")

STATIC FUNCTION CambiarDesde()
LOCAL dNue := dDesde
IF MsgGet("Ordenes de pago", "Mostrar desde:", @dNue) .AND. !EMPTY(dNue)
   dDesde := dNue
   CargarOPs()
   oQryBrw:Refresh()
   oBrw:GoTop()
   oBrw:Refresh()
   oWnd1:SetText(TituloOPs())
ENDIF
RETURN nil

*************************************
** Avisos antes de anular: caja ya cerrada (aviso para todos), retenciones
** de un mes anterior y cheques de una OP que no es de hoy (con estos dos
** solo un ADMIN puede seguir). Devuelve .t. si se puede anular.
STATIC FUNCTION AvisosOP(oQry)
LOCAL cP := "ge_"+oApp:cId, cNum := ClipValue2Sql(oQry:numero), cTxt := "", cCaja := "", cTit, oQ, nRet
// Caja: CIETUR marca checkeado/id_cierre en las OPs del turno que cierra
IF oApp:oServer:Query("SELECT COUNT(*) AS n FROM "+cP+"ordpag WHERE numero = "+cNum+;
                      " AND (IFNULL(id_cierre,0) > 0 OR IFNULL(checkeado,0) <> 0)"):n > 0
   cCaja := "- Ya esta incluida en un cierre de caja: al reimprimir ese turno se avisa que "+;
            "la orden se anulo despues del cierre."+CHR(10)+CHR(10)
ENDIF
// Retenciones de un mes anterior (en el mes corriente todavia se pueden corregir)
IF oQry:fecha < DATE() - DAY(DATE()) + 1
   nRet := oApp:oServer:Query("SELECT "+;
              "(SELECT IFNULL(SUM(importe),0) FROM "+cP+"ordret WHERE numero = "+cNum+") + "+;
              "(SELECT IFNULL(SUM(importe),0) FROM "+cP+"ordretiva WHERE numero = "+cNum+") + "+;
              "(SELECT IFNULL(SUM(reten),0) FROM "+cP+"ordretgan WHERE numero = "+cNum+") AS ret"):ret
   IF nRet <> 0
      cTxt += "- Tiene retenciones por $ "+ALLTRIM(TRANSFORM(nRet,"999,999,999.99"))+" de un mes anterior: "+;
              "el certificado probablemente ya se entrego y se declaro, y las retenciones de "+;
              "Ganancias de las ordenes posteriores de ese mes se calcularon con esta incluida. "+;
              "Las retenciones se borran con la orden."+CHR(10)+CHR(10)
   ENDIF
ENDIF
// Cheques de una OP vieja: puede que ya no esten en la mano / ya se debitaron
IF oQry:fecha < DATE()
   oQ := oApp:oServer:Query("SELECT numche, importe FROM "+cP+"cheter WHERE orden = "+cNum+" ORDER BY numche")
   IF oQ:RecCount() > 0
      cTxt += "- Cheques de terceros entregados: vuelven a cartera (si el proveedor ya los deposito, "+;
              "quedan en cartera cheques que no estan):"+CHR(10)
      ListaCheques(oQ, @cTxt)
   ENDIF
   oQ := oApp:oServer:Query("SELECT numche, importe FROM "+cP+"chepro WHERE orden = "+cNum+" ORDER BY numche")
   IF oQ:RecCount() > 0
      cTxt += "- Cheques propios emitidos: se borran (si ya se debitaron, el banco queda distinto):"+CHR(10)
      ListaCheques(oQ, @cTxt)
   ENDIF
ENDIF
IF EMPTY(cTxt) .AND. EMPTY(cCaja)
   RETURN .t.
ENDIF
cTit := "Orden de pago "+ALLTRIM(STR(oQry:numero))+" del "+DTOC(oQry:fecha)+":"+CHR(10)+CHR(10)
// Retenciones/cheques: solo ADMIN. La caja cerrada sola es un aviso para todos
IF !EMPTY(cTxt) .AND. lAdmin <> 1
   MsgStop(cTit+cCaja+cTxt+"Solo un usuario ADMIN puede anular esta orden.","Atencion")
   RETURN .f.
ENDIF
RETURN MsgNoYes(cTit+cCaja+cTxt+"Anula la orden igual?","Atencion")

STATIC FUNCTION ListaCheques(oQ, cTxt)
LOCAL i := 0
oQ:GoTop()
DO WHILE !oQ:Eof()
   i++
   IF i <= 8
      cTxt += "     Nro "+ALLTRIM(STR(oQ:numche))+"   $ "+ALLTRIM(TRANSFORM(oQ:importe,"999,999,999.99"))+CHR(10)
   ENDIF
   oQ:Skip()
ENDDO
IF i > 8
   cTxt += "     ... y "+ALLTRIM(STR(i-8))+" mas"+CHR(10)
ENDIF
cTxt += CHR(10)
RETURN nil

 

