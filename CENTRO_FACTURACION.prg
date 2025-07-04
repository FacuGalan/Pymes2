#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** CENTRO DE FACTURACION
*************************************************
MEMVAR oApp
STATIC oGet, oDlg,nTipoFecha,nCodCli,dFecDesde,dFecHasta,nImpDesde,nImpHasta,nForPag,dFechaFact,;
       oBrw1, oBrw2, oQry, oQryArtP,nHacer,oSay1,lMostrar_costos,lImprimir,nMesF,nAnioF,nTotalFiscal,oGetF
PROCEDURE CENFACTU()
LOCAL oFont, oFo1, cNomCli:='TODOS',cForPag:='TODAS',  mobserva, Lrta := .f., aObserva := {},oFontTotal,oBot,oSay,;
      oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes"),;
      oQryForPag:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"forpag"),;
      nCosto:=0,nValor:=0,oError,aFecha:={"Fecha del comprobante","Fecha seleccionada"},;
      aMeses:={"Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"}
oGet := ARRAY(12)
oGetF:=ARRAY(3)
lImprimir:= .t.
dFecDesde:= DATE()-5
dFecHasta:= DATE()
dFechaFact:= DATE()
nImpDesde:=0
nImpHasta:=0
nTipoFecha:=1
nCodCli:=0
nForPag:=0
nMesF:=1
nAnioF:= YEAR(DATE())
nTotalFiscal:=0
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS facturacion_temp ";
    +"( `TICOMP` VARCHAR(2) NOT NULL,";  
    +"`LETRA` VARCHAR(1) NOT NULL,";  
    +"`NUMCOMP` VARCHAR(13) NOT NULL,";
    +"`CODCLI` INT(6) NOT NULL, ";
    +"`FECHA` DATE NOT NULL, ";
    +"`NETO` DECIMAL(12,2) NOT NULL DEFAULT 0, ";
    +"`IVA` DECIMAL(12,2) NOT NULL DEFAULT 0, ";
    +"`IMPORTE` DECIMAL(12,2) NOT NULL DEFAULT 0, ";
    +"`SOBRETASA` DECIMAL(12,2) NOT NULL DEFAULT 0, ";
    +"`IIBB` DECIMAL(12,2) NOT NULL DEFAULT 0, ";
    +"`NOMBRE` VARCHAR(50) ,";
    +"`CUIT` VARCHAR(13) ,";
    +"`DNI` INT(8),";
    +"`CONCEPTOS` TEXT ";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE facturacion_temp")
oApp:oServer:NextResult()
oQry:= oApp:oServer:Query("SELECT * FROM facturacion_temp")

DO WHILE .T.
   DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE FONT oFontTotal NAME "ARIAL" SIZE 15,35
   DEFINE DIALOG oDlg RESOURCE "FACTURADOR" OF oApp:oWnd 
    oDlg:lHelpIcon := .f. 
    REDEFINE COMBOBOX oGet[1] VAR nTipoFecha ITEMS aFecha ID 101 OF oDlg;
             ON CHANGE (IF(nTipoFecha=1,(oGet[4]:cText:= DATE()-5,oGet[5]:cText:= DATE(),oGet[11]:cText:= DATE(),oGetF[1]:Set(MONTH(DATE())),oGetF[2]:cText:=YEAR(DATE())),nil),;
                        oQry:Zap(),oBrw1:Refresh(),oGet[7]:SetFocus(),oGet[1]:SetFocus)
    REDEFINE GET oGet[11] VAR dFechaFact ID 111 OF oDlg PICTURE "@D";
                 WHEN(nTipoFecha = 2);
                 ON CHANGE(oGetF[1]:Set(MONTH(dFechaFact)),oGetF[2]:cText:=YEAR(dFechaFact));
                 VALID(dFechaFact>=DATE()-5 .AND. dFechaFact<= DATE());
    
    REDEFINE GET oGet[7] VAR nImpDesde ID 107 OF oDlg PICTURE "9999999999.99"
    REDEFINE GET oGet[8] VAR nImpHasta ID 108 OF oDlg PICTURE "9999999999.99"

    REDEFINE GET oGet[4] VAR dFecDesde ID 104 OF oDlg PICTURE "@D" WHEN(nTipoFecha = 2)
    REDEFINE GET oGet[5] VAR dFecHasta ID 105 OF oDlg PICTURE "@D" WHEN(nTipoFecha = 2)

    REDEFINE GET oGet[2] VAR nCodCli ID 102 OF oDlg PICTURE "999999";
             WHEN(IF(nCodCli=0, (oGet[3]:cText:= 'TODOS') <> 'XXX',.T.));
             VALID(nCodCli = 0 .OR. Buscar(oQryCli,oDlg,oGet[2],oGet[3]));
             ACTION (oGet[2]:cText:= 0, Buscar(oQryCli,oDlg,oGet[2],oGet[3])) BITMAP "BUSC1"
    REDEFINE GET oGet[3] VAR cNomCli ID 103 OF oDlg WHEN(.F.)

    REDEFINE GET oGet[9] VAR nForPag ID 109 OF oDlg PICTURE "99";
            WHEN(IF(nForPag=0, (oGet[10]:cText:= 'TODAS') <> 'XXX',.T.));
             VALID(nForPag = 0 .OR. Buscar(oQryForPag,oDlg,oGet[9],oGet[10]));
             ACTION (oGet[9]:cText:= 0, Buscar(oQryForPag,oDlg,oGet[9],oGet[10])) BITMAP "BUSC1"
    REDEFINE GET oGet[10] VAR cForPag ID 110 OF oDlg WHEN(.F.)


    REDEFINE CHECKBOX oGet[6] VAR lImprimir ID 106 OF oDlg

    REDEFINE BUTTON oBot ID 201 OF oDlg ACTION (Filtrar()) 

    REDEFINE XBROWSE oBrw1 DATASOURCE oQry;
              COLUMNS "NUMCOMP","FECHA","CODCLI","NOMBRE","NETO","IVA","IMPORTE","CONCEPTOS";
              HEADERS "Numero","Fecha","Cliente","Nombre","Neto","I.V.A","Importe","Conceptos";
              FOOTERS ;
              PICTURE "9999-99999999","@D","999999","@!","9,999,999,999.99","9,999,999,999.99","9,999,999,999.99","@!";
              SIZES 90,70,60,270,90,90,100,200 ID 301 OF oDlg ON DBLCLICK IF(oQry:Reccount()>0,Facturar(),nil)
    PintaBrw(oBrw1,0)
    oBrw1:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw1:MakeTotals()

    REDEFINE SAY oSay ID 401 
    oSay:SetText("ATENCION!"+CHR(10)+;
                 "En el caso de seleccionar 'Fecha del comprobante' para la emisión fiscal "+;
                 "solo podra filtrar comprobantes de los últimos 5 días"+CHR(10)+;
                 "En el caso de seleccionar 'Fecha seleccionada' para la emisión fiscal "+;
                 "solo podra ingresar una fecha entre hoy y los últimos 5 días"+CHR(10)+;
                 "En cualquiera de ambos casos solo podra emitir comprobantes fiscales "+;
                 "en el caso de no haber emitido un comprobante posterior a la fecha que esta siendo seleccionada como fecha fiscal")

    REDEFINE COMBOBOX oGetF[1] VAR nMesF ITEMS aMeses ID 501 OF oDlg;
             ON CHANGE(oGetF[2]:SetFocus())
    REDEFINE GET oGetF[2] VAR nAnioF ID 502 OF oDlg;
             VALID(nAnioF <= YEAR(DATE()))

    REDEFINE GET oGetF[3] VAR nTotalFiscal ID 503 OF oDlg FONT oFontTotal PICTURE "9,999,999,999.99";
             WHEN((oGetF[3]:cText:= oApp:oServer:Query("SELECT SUM((vd.neto + vd.iva  ) * IF(vd.tipocomp='NC',-1,1)) AS suma FROM ge_"+oApp:cId+"ventivadet vd "+;
                  " LEFT JOIN ge_"+oApp:cId+"ventas_encab ve ON   vd.tipocomp = ve.ticomp AND vd.letra = ve.letra AND vd.numfac=ve.numcomp "+;
                  "WHERE ve.letra <> 'X' AND MONTH(ve.fecmod) = "+ClipValue2Sql(nMesF)+" AND YEAR(ve.fecmod) = "+ClipValue2Sql(nAnioF)):suma) = 'XXX')
   
   ACTIVATE DIALOG oDlg CENTER ON INIT (oGet[1]:SetFocus())
   IF !Lrta
      EXIT
   ENDIF

  TRY
  oApp:oServer:BeginTransaction()
  
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO

RETURN

****************************************************************************************************************************************************
****************************************************************************************************************************************************
STATIC FUNCTION Filtrar()
oApp:oServer:Execute("TRUNCATE facturacion_temp")
oApp:oServer:Execute("INSERT INTO facturacion_temp(ticomp,letra,numcomp,codcli,fecha,neto,iva,importe,sobretasa,iibb,nombre,cuit,dni,conceptos) "+;
                     "(SELECT v.ticomp,v.letra,v.numcomp,v.codcli,v.fecha,v.neto,v.iva,v.importe,v.sobretasa,v.iibb,v.nombre,v.cuit,v.dni,"+;
                     "GROUP_CONCAT(pc.observa SEPARATOR ',') as conceptos "+;
                     " FROM ge_"+oApp:cId+"ventas_encab v"+;
                     " LEFT JOIN ge_"+oApp:cId+"pagfac pf ON pf.ticomp = v.ticomp AND pf.letra = v.letra AND pf.numcomp = v.numcomp "+;
                     " LEFT JOIN ge_"+oApp:cId+"pagcon pc ON pc.numero = pf.numero "+;
                     " WHERE v.ticomp = 'FC' AND v.letra = 'X' AND v.importe > 0 AND "+;
                     " v.fecha >= "+ClipValue2Sql(dFecDesde)+" AND v.fecha <= "+ClipValue2Sql(dFecHasta)+" "+;
                     IF(nImpDesde>0,"AND v.importe >= "+ClipValue2Sql(nImpDesde)," ")+" "+;
                     IF(nImpHasta>0,"AND v.importe <= "+ClipValue2Sql(nImpHasta)," ")+" "+;
                     IF(nCodCli>0," AND v.codcli = "+ClipValue2Sql(nCodCli)," ")+" "+;
                     IF(nForPag>0,;
                         "AND EXISTS ( "+;
                         "       SELECT 1 "+;
                         "       FROM ge_"+oApp:cId+"pagfac pf2 "+;
                         "       JOIN ge_"+oApp:cId+"pagcon pc2 "+; 
                         "           ON pc2.numero = pf2.numero "+;
                         "       WHERE pf2.ticomp = v.ticomp "+; 
                         "           AND pf2.letra = v.letra "+; 
                         "           AND pf2.numcomp = v.numcomp "+;
                         "           AND pc2.codcon = "+ClipValue2Sql(nForPag)+" "+;
                         "   ) ",;
                     " ")+" "+;
                     " GROUP BY v.ticomp, v.letra, v.numcomp, v.codcli, v.fecha,v.neto, v.iva, v.importe, v.nombre, v.cuit, v.dni "+;
                     " ORDER BY v.fecha DESC,v.numcomp DESC)")
oQry:Refresh()
oBrw1:Refresh()
oBrw1:MakeTotals()
IF oQry:Reccount() = 0
    MsgStop("No se encontraron comprobantes para los filtros seleccionados","Atención!")
ENDIF
RETURN nil

****************************************************************************************************************************************************
****************************************************************************************************************************************************
STATIC FUNCTION Facturar()
LOCAL nPuntoVta,cPuntoVta,nPunLocal,oQryValid,cLetra,oQryPar,oQryCliAux,nNumero,cCae,dFecVtoC,nTipFor,dFecha,oQryIva,aTablaIva := {},cNumComp,oErr
nPunLocal :=  oApp:oServer:Query("SELECT punto FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):punto
IF nPunLocal > 0
   nPuntoVta := nPunLocal
   ELSE 
   nPuntoVta:= oApp:oServer:Query("SELECT prefijo FROM ge_"+oApp:cId+"parametros LIMIT 1"):prefijo
ENDIF
cPuntoVta:= STRTRAN(STR(nPuntoVta,4)," ","0")
dFecha:=  dFechaFact
dFecVtoC:= DATE()
cCae:= ""
nTipFor:=01
IF nTipoFecha = 1 
    oQryValid:= oApp:oServer:Query("SELECT numcomp FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = 'FC' AND letra <> 'X' "+;
                                         "AND LEFT(numcomp,4) = "+ClipValue2Sql(cPuntoVta)+" AND fecmod > "+ClipValue2Sql(oQry:fecha))

    IF oQryValid:reccount() > 0
        MsgStop("Hay un comprobante fiscal emitido en una fecha posterior al comprobante seleccionado, no se puede emitir la factura electronica "+;
                "sobre este comprobante","Imposible continuar")
        RETURN nil
    ENDIF 
    dFecha:= oQry:fecha
ENDIF

oQryPar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
oQryCliAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(oQry:codcli))
cLetra:=IF(oQryPar:coniva<>6,IF(oQryCliAux:coniva>2 .and. oQryCliAux:coniva <> 6,"B","A"),"C")

oQryIva:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventivadet WHERE tipocomp = 'FC' AND letra = 'X' AND numfac = "+ClipValue2Sql(oQry:numcomp))
DO WHILE !oQryIva:Eof()
      AADD(aTablaIva,{oQryIva:codiva,oQryIva:neto,oQryIva:iva})
   oQryIva:Skip()
ENDDO
Procesando(.t.)
FacturaElec2(nPuntoVta, 1, cLetra, aTablaIva, @nNumero, @cCae, @dFecVtoC,@nTipFor,;
            dFecha,oQryCliAux:cuit,oQryCliAux:dni,oQry:neto,oQry:iva,oQry:importe,oQry:sobretasa,oQryCliAux:coniva,oQry:iibb)
IF nNumero = 0
    Procesando(.f.)
    RETURN nil
ENDIF
cNumComp := STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNumero,8)," ","0")

TRY 
      oApp:oServer:BeginTransaction()
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_encab SET numcomp = "+ClipValue2Sql(cNumComp)+",letra = "+ClipValue2Sql(cLetra)+","+;
                             "cae = "+ClipValue2Sql(cCae)+",fecvto = "+ClipValue2Sql(dFecVtoC)+","+;
                             "tipfor = "+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+",fecmod = "+ClipValue2Sql(dFecha)+" "+;
                             "WHERE ticomp = 'FC' AND letra = 'X' AND numcomp = "+ClipValue2Sql(oQry:numcomp))

        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_det SET nrofac = "+ClipValue2Sql("FC"+cLetra+cNumComp)+" "+;
                             "WHERE nrofac = "+ClipValue2Sql("FCX"+oQry:numcomp))

        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_cuota SET numero = "+ClipValue2Sql(cNumComp)+",letra = "+ClipValue2Sql(cLetra)+" "+;
                             "WHERE tipo = 'FC' AND letra = 'X' AND numero = "+ClipValue2Sql(oQry:numcomp))


        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventivadet SET numfac = "+ClipValue2Sql(cNumComp)+",letra = "+ClipValue2Sql(cLetra)+" "+;
                             "WHERE tipocomp = 'FC' AND letra = 'X' AND numfac = "+ClipValue2Sql(oQry:numcomp))

        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"concfact SET numcomp = "+ClipValue2Sql(cNumComp)+",letra = "+ClipValue2Sql(cLetra)+" "+;
                             "WHERE ticomp = 'FC' AND letra = 'X' AND numcomp = "+ClipValue2Sql(oQry:numcomp))

        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagfac SET numcomp = "+ClipValue2Sql(cNumComp)+",letra = "+ClipValue2Sql(cLetra)+" "+;
                             "WHERE ticomp = 'FC' AND letra = 'X' AND numcomp = "+ClipValue2Sql(oQry:numcomp))
        oApp:oServer:CommitTransaction()
CATCH oErr
      MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN nil
END TRY
Procesando(.f.)
IF lImprimir
    PrintFactuElec('FC',cLetra+cNumComp)
ELSE 
    oGetF[3]:cText:= oApp:oServer:Query("SELECT SUM(importe*IF(ticomp='NC',-1,1)) AS suma FROM ge_"+oApp:cId+"ventas_encab "+;
    "WHERE letra <> 'X' AND MONTH(fecmod) = "+ClipValue2Sql(nMesF)+" AND YEAR(fecmod) = "+ClipValue2Sql(nAnioF)):suma
    MsgInfo("Comprobante emitido con éxito","Proceso finalizado")
ENDIF

Filtrar()

RETURN nil


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.
