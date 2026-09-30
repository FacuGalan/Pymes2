#include "Fivewin.ch"
#include "Tdolphin.ch"

*************************************************
** Cuenta corriente de proveedores: saldos recalculados
**
** Los saldos se siguen guardando en compras.saldo (por factura) y
** provee.saldo (anticipo), pero ya no se ajustan sumando y restando:
** despues de cada operacion se rehacen desde los movimientos.
**
**   saldo factura = importe - lo aplicado por las OPs (ordfac), minimo 0
**   anticipo      = total de las OPs - lo aplicado a facturas existentes
**                   (limitado al importe de cada factura)
**
** Con eso  deuda - anticipo = compras - pagos = cuenta corriente,
** siempre. Las NC van con signo -1 (en ordfac se graban en negativo).
**
** ConciliarCtaProv() se corre UNA vez por cliente antes de empezar a
** recalcular: por cada proveedor descuadrado genera una OP de ajuste
** (fecha 01/01/2000, checkeado, caja 0, concepto 6) cuyas filas de
** ordfac hacen que la formula reproduzca exactamente los saldos
** guardados hoy. Asi nadie ve cambiar un saldo y la cuenta corriente
** pasa a mostrar lo mismo que la orden de pago.
** La marca de "conciliado" y el log quedan en ge_XXXXXXconcilia.
*************************************************
MEMVAR oApp

#define CP_OBS_AJUSTE   "AJUSTE CONCILIACION CTA CTE"
#define CP_FECHA_AJUSTE "2000-01-01"
#define CP_USU_AJUSTE   "CONCILIACION"

*************************************************
** Recalcula saldos de facturas y anticipo de un proveedor.
** Se llama DENTRO de la transaccion del que graba. Devuelve el anticipo.
** Si el anticipo diera negativo (se anulo una OP que genero anticipo y
** ese anticipo ya se habia usado para pagar facturas), desaplica el
** faltante de las OPs mas recientes que usaron anticipo: esas facturas
** vuelven a quedar con saldo y el anticipo queda en 0.
** aArr (opcional) recibe lo desaplicado: { numero_op, fecha_op, tipocomp,
** letra, numfac, importe, lOpBorrada } por cada factura que volvio a quedar
** con saldo (lOpBorrada = la OP quedo vacia y se elimino).
FUNCTION RecalcCtaProv(nCodPro, oSrv, cId, aArr)
LOCAL cP, nAnt, nDesde, i
DEFAULT oSrv := oApp:oServer, cId := oApp:cId, aArr := {}
cP   := "ge_"+cId
nAnt := CtaProvRehacer(oSrv, cP, nCodPro)
IF nAnt < -0.004
   nDesde := LEN(aArr) + 1
   CtaProvDesaplicar(oSrv, cP, nCodPro, -nAnt, aArr)
   // 7mo elemento: .t. si la OP quedo vacia (solo aplicaba anticipo) y se borro
   FOR i := nDesde TO LEN(aArr)
       AADD(aArr[i], oSrv:Query("SELECT COUNT(*) AS n FROM "+cP+"ordpag WHERE numero = "+ClipValue2Sql(aArr[i,1])):n = 0)
   NEXT i
   nAnt := CtaProvRehacer(oSrv, cP, nCodPro)
ENDIF
RETURN nAnt

*************************************************
** Rehace compras.saldo/estado y provee.saldo de un proveedor con la formula.
STATIC FUNCTION CtaProvRehacer(oSrv, cP, nCodPro)
LOCAL cCod, cApl, cSig
cCod := ClipValue2Sql(nCodPro)
cApl := CtaProvSqlApl(cP, nCodPro)
cSig := "IF(c.tipocomp='NC',-1,1)"

oSrv:Execute("UPDATE "+cP+"compras c LEFT JOIN "+cApl+" a "+;
             " ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
             "SET c.saldo  = GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+"), "+;
             "    c.estado = IF(GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") = 0, 'P', 'I') "+;
             "WHERE c.codpro = "+cCod)

oSrv:Execute("UPDATE "+cP+"provee SET saldo = "+;
             "(SELECT IFNULL(SUM(total),0) FROM "+cP+"ordpag WHERE proveedor = "+cCod+") - "+;
             "(SELECT IFNULL(SUM("+cSig+" * LEAST(c.importe, IFNULL(a.apl,0)*"+cSig+")),0) "+;
             "   FROM "+cP+"compras c LEFT JOIN "+cApl+" a "+;
             "     ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
             "  WHERE c.codpro = "+cCod+") "+;
             "WHERE codigo = "+cCod)

RETURN oSrv:Query("SELECT saldo FROM "+cP+"provee WHERE codigo = "+cCod):saldo

*************************************************
** Desaplica nFalta de lo imputado a facturas, de la OP mas reciente para
** atras. 1ra pasada: solo OPs que usaron anticipo (concepto 7) y como
** maximo lo que usaron. 2da pasada (solo si hiciera falta, datos raros):
** cualquier OP. Nunca toca la OP de ajuste ni la plata real de la OP
** (ordpag.total, conceptos de caja): solo ordfac, ordpag.facturas y el
** concepto 7. Una OP que queda en total 0, sin facturas ni conceptos, se
** borra (solo aplicaba anticipo).
STATIC FUNCTION CtaProvDesaplicar(oSrv, cP, nCodPro, nFalta, aArr)
LOCAL nPasada, oQ, nCap, nX, nRed, nOp, nResta, cCod, cWhere
cCod   := ClipValue2Sql(nCodPro)
nResta := ROUND(nFalta,2)
FOR nPasada := 1 TO 2
    IF nResta <= 0
       EXIT
    ENDIF
    oQ := oSrv:Query("SELECT o.numero, o.fecha, o.facturas, "+;
          " IFNULL((SELECT SUM(k.importe) FROM "+cP+"ordcon k WHERE k.numero = o.numero AND k.codcon = 7),0) AS anti, "+;
          " f.tipocomp, f.letra, f.numfac, f.importe "+;
          "FROM "+cP+"ordpag o JOIN "+cP+"ordfac f ON f.numero = o.numero "+;
          "JOIN "+cP+"compras c ON c.codpro = o.proveedor AND c.tipocomp = f.tipocomp AND c.letra = f.letra AND c.numfac = f.numfac "+;
          "WHERE o.proveedor = "+cCod+" AND f.importe > 0 AND o.observa <> '"+CP_OBS_AJUSTE+"' "+;
          IF(nPasada = 1, " AND EXISTS (SELECT 1 FROM "+cP+"ordcon k WHERE k.numero = o.numero AND k.codcon = 7 AND k.importe > 0) ", "")+;
          "ORDER BY o.numero DESC, f.importe DESC")
    nOp := 0
    nRed := 0
    oQ:GoTop()
    DO WHILE !oQ:Eof() .AND. nResta > 0
       IF oQ:numero <> nOp
          IF nOp > 0
             CtaProvCerrarOp(oSrv, cP, nOp, nRed, nPasada)
          ENDIF
          nOp  := oQ:numero
          nRed := 0
          nCap := ROUND(IF(nPasada = 1, oQ:anti, oQ:facturas),2)
       ENDIF
       nX := ROUND(MIN(MIN(oQ:importe, nCap), nResta),2)
       IF nX > 0
          cWhere := " WHERE numero = "+ClipValue2Sql(oQ:numero)+" AND tipocomp = "+ClipValue2Sql(oQ:tipocomp)+;
                    " AND letra = "+ClipValue2Sql(oQ:letra)+" AND numfac = "+ClipValue2Sql(oQ:numfac)+;
                    " AND importe = "+ClipValue2Sql(ROUND(oQ:importe,2))+" LIMIT 1"
          IF ROUND(oQ:importe - nX,2) = 0
             oSrv:Execute("DELETE FROM "+cP+"ordfac"+cWhere)
          ELSE
             oSrv:Execute("UPDATE "+cP+"ordfac SET importe = importe - "+ClipValue2Sql(nX)+cWhere)
          ENDIF
          AADD(aArr, { oQ:numero, oQ:fecha, oQ:tipocomp, oQ:letra, oQ:numfac, nX })
          nCap   := ROUND(nCap - nX,2)
          nResta := ROUND(nResta - nX,2)
          nRed   := ROUND(nRed + nX,2)
       ENDIF
       oQ:Skip()
    ENDDO
    IF nOp > 0
       CtaProvCerrarOp(oSrv, cP, nOp, nRed, nPasada)
    ENDIF
NEXT nPasada
RETURN nResta

*************************************************
** Ajusta ordpag.facturas (y el concepto 7 en la 1ra pasada) de una OP
** a la que se le desaplico nRed. Si quedo vacia, la borra.
STATIC FUNCTION CtaProvCerrarOp(oSrv, cP, nOp, nRed, nPasada)
LOCAL cNum := ClipValue2Sql(nOp)
IF nRed <= 0
   RETURN nil
ENDIF
oSrv:Execute("UPDATE "+cP+"ordpag SET facturas = facturas - "+ClipValue2Sql(nRed)+" WHERE numero = "+cNum)
IF nPasada = 1
   oSrv:Execute("UPDATE "+cP+"ordcon SET importe = importe - "+ClipValue2Sql(nRed)+;
                " WHERE numero = "+cNum+" AND codcon = 7 AND importe >= "+ClipValue2Sql(nRed)+" LIMIT 1")
   oSrv:Execute("DELETE FROM "+cP+"ordcon WHERE numero = "+cNum+" AND codcon = 7 AND importe <= 0")
ENDIF
oSrv:Execute("DELETE FROM "+cP+"ordpag WHERE numero = "+cNum+" AND total = 0 "+;
             " AND NOT EXISTS (SELECT 1 FROM "+cP+"ordfac f WHERE f.numero = "+cNum+") "+;
             " AND NOT EXISTS (SELECT 1 FROM "+cP+"ordcon k WHERE k.numero = "+cNum+")")
RETURN nil

*************************************************
** Indica si el cliente ya fue conciliado (existe la marca).
FUNCTION CtaProvConciliado(oSrv, cId)
LOCAL cP
DEFAULT oSrv := oApp:oServer, cId := oApp:cId
cP := "ge_"+cId
IF oSrv:Query("SHOW TABLES LIKE '"+cP+"concilia'"):RecCount() = 0
   RETURN .f.
ENDIF
RETURN oSrv:Query("SELECT COUNT(*) AS cant FROM "+cP+"concilia WHERE tipo = 'C'"):cant > 0

*************************************************
** Concilia la cuenta corriente de proveedores de un cliente.
** lGrabar = .f. : solo informa, no escribe nada.
** lGrabar = .t. : genera las OPs de ajuste, el log y la marca, todo en
**                 una transaccion. Verifica antes de confirmar que la
**                 formula reproduzca los saldos guardados; si no, deshace.
** Devuelve { lOk, cMensaje, aDetalle } donde cada fila de aDetalle es
** { codpro, nombre, anticipo_guardado, anticipo_formula, ajuste,
**   facturas_ajustadas, deuda_guardada, ctacte, aMotivos } (ver CtaProvMotivos).
** "ajuste" = total de la OP de ajuste = diferencia entre la cuenta
** corriente y lo que muestra la orden de pago.
FUNCTION ConciliarCtaProv(lGrabar, oSrv, cId, cVersion, cUsuario)
LOCAL cP, aDet := {}, oQry, cApl, cSig, lOk := .t., cMsg := "", oError, nOp, i, j,;
      cLock, nMal, lEnTrans := .f.
DEFAULT lGrabar := .f., oSrv := oApp:oServer, cId := oApp:cId, cVersion := "", cUsuario := CP_USU_AJUSTE
cP   := "ge_"+cId
cApl := CtaProvSqlApl(cP, 0)
cSig := "IF(c.tipocomp='NC',-1,1)"
cLock:= "concilia_"+cP

IF lGrabar
   IF oSrv:Query("SELECT GET_LOCK('"+cLock+"',60) AS ok"):ok <> 1
      RETURN { .f., "No se pudo obtener el bloqueo de conciliacion de "+cP, aDet }
   ENDIF
   // DDL fuera de la transaccion (hace commit implicito)
   oSrv:Execute("CREATE TABLE IF NOT EXISTS "+cP+"concilia ("+;
                "id INT(10) NOT NULL AUTO_INCREMENT,"+;
                "tipo CHAR(1) NOT NULL,"+;                       // C = cabecera (marca), P = proveedor ajustado
                "fecha DATETIME NULL,"+;
                "version VARCHAR(20) NOT NULL DEFAULT '',"+;
                "usuario VARCHAR(15) NOT NULL DEFAULT '',"+;
                "codpro INT(8) NOT NULL DEFAULT 0,"+;
                "anticipo_ant DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
                "anticipo_calc DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
                "ajuste DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
                "facturas INT(6) NOT NULL DEFAULT 0,"+;
                "deuda DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
                "ctacte DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
                "numero_op INT(10) NOT NULL DEFAULT 0,"+;
                "motivo CHAR(1) NOT NULL DEFAULT '',"+;           // tipo D: F/A/H/E/R (ver CtaProvMotivos)
                "detalle VARCHAR(255) NOT NULL DEFAULT '',"+;     // tipo D: explicacion del motivo
                "PRIMARY KEY (id), KEY tipo (tipo)) ENGINE=INNODB DEFAULT CHARSET=latin1")
   IF oSrv:Query("SHOW COLUMNS FROM "+cP+"concilia LIKE 'detalle'"):RecCount() = 0
      oSrv:Execute("ALTER TABLE "+cP+"concilia ADD motivo CHAR(1) NOT NULL DEFAULT '', "+;
                   "ADD detalle VARCHAR(255) NOT NULL DEFAULT ''")
   ENDIF
   IF CtaProvConciliado(oSrv, cId)
      oSrv:Query("SELECT RELEASE_LOCK('"+cLock+"') AS ok")
      RETURN { .t., "Ya estaba conciliado", aDet }
   ENDIF
ENDIF

// Por proveedor: lo guardado, lo que daria la formula y el ajuste necesario.
//  ajuste = anticipo guardado - total OPs + lo que deberia quedar aplicado
//         = cuenta corriente - (deuda guardada - anticipo guardado)
oQry := oSrv:Query(;
   "SELECT p.codigo, p.nombre, p.saldo AS anticipo, "+;
   "  IFNULL(o.tot,0) AS totop, "+;
   "  IFNULL(f.impo,0) AS impo, IFNULL(f.deuda,0) AS deuda, "+;
   "  IFNULL(f.aplobj,0) AS aplobj, IFNULL(f.aplcal,0) AS aplcal, IFNULL(f.nmal,0) AS nmal "+;
   "FROM "+cP+"provee p "+;
   "LEFT JOIN (SELECT proveedor, SUM(total) AS tot FROM "+cP+"ordpag GROUP BY proveedor) o ON o.proveedor = p.codigo "+;
   "LEFT JOIN (SELECT c.codpro, "+;
   "     SUM("+cSig+"*c.importe) AS impo, "+;
   "     SUM(IF(c.saldo > 0, "+cSig+"*c.saldo, 0)) AS deuda, "+;
   "     SUM("+cSig+"*(c.importe - c.saldo)) AS aplobj, "+;
   "     SUM("+cSig+"*LEAST(c.importe, IFNULL(a.apl,0)*"+cSig+")) AS aplcal, "+;
   "     SUM(ABS(GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") - c.saldo) > 0.004) AS nmal "+;
   "   FROM "+cP+"compras c LEFT JOIN "+cApl+" a "+;
   "     ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
   "   GROUP BY c.codpro) f ON f.codpro = p.codigo "+;
   "WHERE ABS(p.saldo - IFNULL(o.tot,0) + IFNULL(f.aplobj,0)) > 0.004 OR IFNULL(f.nmal,0) > 0 "+;
   "ORDER BY p.codigo")

oQry:GoTop()
DO WHILE !oQry:Eof()
   AADD(aDet, { oQry:codigo, ALLTRIM(oQry:nombre), oQry:anticipo, ;
                ROUND(oQry:totop - oQry:aplcal,2), ;
                ROUND(oQry:anticipo - oQry:totop + oQry:aplobj,2), ;
                oQry:nmal, oQry:deuda, ROUND(oQry:impo - oQry:totop,2) })
   oQry:Skip()
ENDDO
// Por que se ajusta cada proveedor (aDet[i,9])
FOR i := 1 TO LEN(aDet)
    AADD(aDet[i], CtaProvMotivos(oSrv, cP, aDet[i,1], aDet[i,2], aDet[i,3], aDet[i,4], aDet[i,5]))
NEXT i

IF !lGrabar
   RETURN { .t., STR(LEN(aDet),5)+" proveedores a ajustar", aDet }
ENDIF

TRY
   oSrv:BeginTransaction()
   lEnTrans := .t.
   FOR i := 1 TO LEN(aDet)
       // OP de ajuste: total = diferencia de la cuenta corriente
       oSrv:Execute("INSERT INTO "+cP+"ordpag "+;
                    "(proveedor,total,facturas,observa,fecha,caja,usuario,fecmod,ip,demo,numeroop,checkeado) VALUES ("+;
                    ClipValue2Sql(aDet[i,1])+","+ClipValue2Sql(aDet[i,5])+",0,'"+CP_OBS_AJUSTE+"','"+CP_FECHA_AJUSTE+"',"+;
                    "0,'"+LEFT(cUsuario,15)+"',CURDATE(),'',0,0,1)")
       nOp := oSrv:LastInsertID()
       // Filas de ordfac: lo que falta (o sobra) aplicar a cada factura para
       // que importe - aplicado = saldo guardado. Se calcula en SQL (exacto).
       oSrv:Execute("INSERT INTO "+cP+"ordfac (numero,tipocomp,letra,numfac,fecha,importe,neto,netogan) "+;
                    "SELECT "+ClipValue2Sql(nOp)+", c.tipocomp, c.letra, c.numfac, '"+CP_FECHA_AJUSTE+"', "+;
                    "  (c.importe - IFNULL(a.apl,0)*"+cSig+" - c.saldo)*"+cSig+", 0, 0 "+;
                    "FROM "+cP+"compras c LEFT JOIN "+CtaProvSqlApl(cP, aDet[i,1])+" a "+;
                    "  ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
                    "WHERE c.codpro = "+ClipValue2Sql(aDet[i,1])+;
                    "  AND ABS(GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") - c.saldo) > 0.004")
       oSrv:Execute("UPDATE "+cP+"ordpag SET facturas = "+;
                    "(SELECT IFNULL(SUM(importe),0) FROM "+cP+"ordfac WHERE numero = "+ClipValue2Sql(nOp)+") "+;
                    "WHERE numero = "+ClipValue2Sql(nOp))
       // Concepto 6: no lo suma ningun cierre de caja ni listado de caja
       oSrv:Execute("INSERT INTO "+cP+"ordcon (numero,codcon,importe,observa) "+;
                    "SELECT numero, 6, total, 'AJUSTE CONCILIACION' FROM "+cP+"ordpag "+;
                    "WHERE numero = "+ClipValue2Sql(nOp)+" AND total <> 0")
       oSrv:Execute("INSERT INTO "+cP+"concilia "+;
                    "(tipo,fecha,version,usuario,codpro,anticipo_ant,anticipo_calc,ajuste,facturas,deuda,ctacte,numero_op) VALUES ("+;
                    "'P',NOW(),"+ClipValue2Sql(cVersion)+","+ClipValue2Sql(LEFT(cUsuario,15))+","+;
                    ClipValue2Sql(aDet[i,1])+","+ClipValue2Sql(aDet[i,3])+","+ClipValue2Sql(aDet[i,4])+","+;
                    ClipValue2Sql(aDet[i,5])+","+ClipValue2Sql(aDet[i,6])+","+ClipValue2Sql(aDet[i,7])+","+;
                    ClipValue2Sql(aDet[i,8])+","+ClipValue2Sql(nOp)+")")
       // Motivos (D): por que se ajusto, para consultar despues
       FOR j := 1 TO LEN(aDet[i,9])
           oSrv:Execute("INSERT INTO "+cP+"concilia "+;
                        "(tipo,fecha,version,usuario,codpro,ajuste,numero_op,motivo,detalle) VALUES ("+;
                        "'D',NOW(),"+ClipValue2Sql(cVersion)+","+ClipValue2Sql(LEFT(cUsuario,15))+","+;
                        ClipValue2Sql(aDet[i,1])+","+ClipValue2Sql(aDet[i,9,j,3])+","+ClipValue2Sql(nOp)+","+;
                        ClipValue2Sql(aDet[i,9,j,1])+","+ClipValue2Sql(LEFT(aDet[i,9,j,2],255))+")")
       NEXT j
   NEXT i

   // Verificacion: con los ajustes, la formula tiene que dar exactamente
   // lo guardado en TODAS las facturas y TODOS los anticipos.
   nMal := CtaProvDescuadres(oSrv, cP)
   IF nMal > 0
      oSrv:RollBack()
      lEnTrans := .f.
      lOk  := .f.
      cMsg := "Verificacion fallida: "+ALLTRIM(STR(nMal))+" saldos no coinciden. No se grabo nada."
   ELSE
      // numero_op de la marca = ultima OP al conciliar (corte de CtaProvComposicion)
      oSrv:Execute("INSERT INTO "+cP+"concilia (tipo,fecha,version,usuario,facturas,ajuste,numero_op) "+;
                   "SELECT 'C', NOW(), "+ClipValue2Sql(cVersion)+", "+ClipValue2Sql(LEFT(cUsuario,15))+", "+;
                   "COUNT(*), IFNULL(SUM(ajuste),0), "+;
                   "(SELECT IFNULL(MAX(numero),0) FROM "+cP+"ordpag) FROM "+cP+"concilia WHERE tipo = 'P'")
      oSrv:CommitTransaction()
      lEnTrans := .f.
      cMsg := "Conciliado: "+ALLTRIM(STR(LEN(aDet)))+" proveedores ajustados"
   ENDIF
CATCH oError
   IF lEnTrans
      oSrv:RollBack()
   ENDIF
   lOk  := .f.
   cMsg := "Error al conciliar "+cP+": "+IF(oError <> nil, oError:description, "")
END TRY
oSrv:Query("SELECT RELEASE_LOCK('"+cLock+"') AS ok")
RETURN { lOk, cMsg, aDet }

*************************************************
** Motivos del ajuste de un proveedor, para el log de la conciliacion.
** Devuelve { {motivo, texto, importe}, ... }. "importe" es lo que ese
** motivo aporta al ajuste: los F + A (+ R) suman exactamente el ajuste.
**   F = factura cuyo saldo guardado no coincide con importe - sus pagos
**   A = anticipo guardado distinto del que dan las OPs (pagado - aplicado)
**   H = informativo: pago a un comprobante que ya no existe (esa plata
**       cuenta en el anticipo "segun las OPs")
**   E = informativo: OP del proveedor eliminada segun la auditoria
**   R = diferencia de redondeo (no deberia aparecer)
** Las causas son "posibles": se deducen de los datos, no hay registro.
STATIC FUNCTION CtaProvMotivos(oSrv, cP, nCod, cNom, nAntG, nAntF, nAjuste)
LOCAL aMot := {}, oQ, cCod := ClipValue2Sql(nCod), cSig := "IF(c.tipocomp='NC',-1,1)", nSuma := 0, nX, cNom20, cTxt

// Facturas con saldo guardado distinto de importe - pagos
oQ := oSrv:Query("SELECT c.tipocomp, c.letra, c.numfac, c.fecfac, c.importe, c.saldo, "+;
                 " IFNULL(a.apl,0)*"+cSig+" AS pagado, "+;
                 " GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") AS segun, "+;
                 " c.fecmod, IFNULL(c.usuario,'') AS usuario, "+;
                 " "+cSig+"*(c.importe - c.saldo - LEAST(c.importe, IFNULL(a.apl,0)*"+cSig+")) AS aporte "+;
                 "FROM "+cP+"compras c LEFT JOIN "+CtaProvSqlApl(cP, nCod)+" a "+;
                 "  ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
                 "WHERE c.codpro = "+cCod+;
                 "  AND ABS(GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") - c.saldo) > 0.004 "+;
                 "ORDER BY c.fecfac, c.numfac")
oQ:GoTop()
DO WHILE !oQ:Eof()
   AADD(aMot, { "F", oQ:tipocomp+" "+oQ:letra+" "+ALLTRIM(oQ:numfac)+" del "+CPFec(oQ:fecfac)+;
                ": importe "+CPNum(oQ:importe)+", pagado "+CPNum(oQ:pagado)+;
                ", saldo guardado "+CPNum(oQ:saldo)+" y segun sus pagos "+CPNum(oQ:segun)+". "+;
                IF(oQ:saldo < oQ:segun, ;
                   "Figura con MENOS deuda (posible: se subio el importe o se cambio el numero despues de pagarla).", ;
                   "Figura con MAS deuda (posible: se bajo el importe despues de pagarla o se borro un pago).")+;
                " Ult. modif. "+CPFec(oQ:fecmod)+" "+ALLTRIM(oQ:usuario), ;
                ROUND(oQ:aporte,2) })
   nSuma := ROUND(nSuma + oQ:aporte,2)
   oQ:Skip()
ENDDO

// Anticipo
nX := ROUND(nAntG - nAntF,2)
IF nX <> 0
   DO CASE
   CASE ABS(nX) < 1
      cTxt := "Anticipo guardado "+CPNum(nAntG)+" y segun las OPs "+CPNum(nAntF)+": diferencia de centavos "+;
              "(redondeos al aplicar pagos)."
   CASE nAntF < 0
      cTxt := "Anticipo guardado "+CPNum(nAntG)+", pero las OPs aplicaron a facturas "+CPNum(-nAntF)+;
              " mas de lo que pagaron: se uso un anticipo que segun los pagos no existia "+;
              "(posible: OP eliminada con la version anterior de ORDENES, que devolvia anticipo de mas, "+;
              "y ese anticipo se uso despues)."
   CASE nX > 0
      cTxt := "Anticipo guardado "+CPNum(nAntG)+" y segun las OPs (pagado - aplicado) "+CPNum(nAntF)+;
              ". Figura con MAS anticipo (posible: OP eliminada con la version anterior de ORDENES, "+;
              "que devolvia anticipo de mas)."
   OTHERWISE
      cTxt := "Anticipo guardado "+CPNum(nAntG)+" y segun las OPs (pagado - aplicado) "+CPNum(nAntF)+;
              ". Figura con MENOS anticipo (posible: OP eliminada o anticipo usado sin descontar bien)."
   ENDCASE
   AADD(aMot, { "A", cTxt, nX })
   nSuma := ROUND(nSuma + nX,2)
ENDIF

// Informativo: pagos a comprobantes que ya no existen
oQ := oSrv:Query("SELECT f.numero, o.fecha, f.tipocomp, f.letra, f.numfac, f.importe "+;
                 "FROM "+cP+"ordfac f JOIN "+cP+"ordpag o ON o.numero = f.numero "+;
                 "LEFT JOIN "+cP+"compras c ON c.codpro = o.proveedor AND c.tipocomp = f.tipocomp "+;
                 "  AND c.letra = f.letra AND c.numfac = f.numfac "+;
                 "WHERE o.proveedor = "+cCod+" AND c.codpro IS NULL ORDER BY f.numero")
oQ:GoTop()
DO WHILE !oQ:Eof()
   AADD(aMot, { "H", "La OP "+ALLTRIM(STR(oQ:numero))+" del "+CPFec(oQ:fecha)+" pago "+CPNum(oQ:importe)+;
                " a "+oQ:tipocomp+" "+oQ:letra+" "+ALLTRIM(oQ:numfac)+", que ya no existe "+;
                "(se cambio el numero o se borro); esa plata cuenta como anticipo.", 0 })
   oQ:Skip()
ENDDO

// Informativo: OPs eliminadas segun la auditoria (si hay diferencia de anticipo)
IF nX <> 0 .AND. oSrv:Query("SHOW TABLES LIKE '"+cP+"auditoria'"):RecCount() > 0
   cNom20 := LEFT(ALLTRIM(cNom),20)
   oQ := oSrv:Query("SELECT fecha, usuario, descripcion FROM "+cP+"auditoria "+;
                    "WHERE descripcion LIKE '%OP:%' AND LOCATE("+ClipValue2Sql(cNom20)+", descripcion) > 0 "+;
                    "ORDER BY fecha, hora")
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      AADD(aMot, { "E", "Auditoria "+CPFec(oQ:fecha)+" "+ALLTRIM(oQ:usuario)+": "+ALLTRIM(oQ:descripcion), 0 })
      oQ:Skip()
   ENDDO
ENDIF

IF ABS(nAjuste - nSuma) > 0.004
   AADD(aMot, { "R", "Diferencia sin explicar (redondeo): "+CPNum(nAjuste - nSuma), ROUND(nAjuste - nSuma,2) })
ENDIF
RETURN aMot

STATIC FUNCTION CPNum(n)
RETURN ALLTRIM(TRANSFORM(n, "@E 999,999,999,999.99"))

STATIC FUNCTION CPFec(d)
RETURN IF(VALTYPE(d) = "D" .AND. !EMPTY(d), DTOC(d), "")

*************************************************
** Motivos guardados de la conciliacion de un proveedor (tipo D), para
** mostrarlos en la composicion del anticipo. { {motivo, texto, importe} }
FUNCTION CtaProvMotivosGuardados(nCodPro, oSrv, cId)
LOCAL aMot := {}, oQ, cP
DEFAULT oSrv := oApp:oServer, cId := oApp:cId
cP := "ge_"+cId
IF oSrv:Query("SHOW TABLES LIKE '"+cP+"concilia'"):RecCount() = 0 .OR. ;
   oSrv:Query("SHOW COLUMNS FROM "+cP+"concilia LIKE 'detalle'"):RecCount() = 0
   RETURN aMot
ENDIF
oQ := oSrv:Query("SELECT motivo, detalle, ajuste FROM "+cP+"concilia "+;
                 "WHERE tipo = 'D' AND codpro = "+ClipValue2Sql(nCodPro)+" ORDER BY id")
oQ:GoTop()
DO WHILE !oQ:Eof()
   AADD(aMot, { oQ:motivo, oQ:detalle, oQ:ajuste })
   oQ:Skip()
ENDDO
RETURN aMot

*************************************************
** Cantidad de facturas + proveedores donde la formula no da lo guardado.
** Con 0 el cliente esta en condiciones de usar RecalcCtaProv.
FUNCTION CtaProvDescuadres(oSrv, cP)
LOCAL cApl := CtaProvSqlApl(cP, 0), cSig := "IF(c.tipocomp='NC',-1,1)", nFac, nPro
nFac := oSrv:Query("SELECT COUNT(*) AS cant FROM "+cP+"compras c LEFT JOIN "+cApl+" a "+;
                   " ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
                   "WHERE ABS(GREATEST(0, c.importe - IFNULL(a.apl,0)*"+cSig+") - c.saldo) > 0.004"):cant
nPro := oSrv:Query("SELECT COUNT(*) AS cant FROM "+cP+"provee p "+;
                   "LEFT JOIN (SELECT proveedor, SUM(total) AS tot FROM "+cP+"ordpag GROUP BY proveedor) o ON o.proveedor = p.codigo "+;
                   "LEFT JOIN (SELECT c.codpro, SUM("+cSig+"*LEAST(c.importe, IFNULL(a.apl,0)*"+cSig+")) AS apl "+;
                   "   FROM "+cP+"compras c LEFT JOIN "+cApl+" a "+;
                   "     ON a.proveedor = c.codpro AND a.tipocomp = c.tipocomp AND a.letra = c.letra AND a.numfac = c.numfac "+;
                   "   GROUP BY c.codpro) f ON f.codpro = p.codigo "+;
                   "WHERE ABS(p.saldo - (IFNULL(o.tot,0) - IFNULL(f.apl,0))) > 0.004"):cant
RETURN nFac + nPro

*************************************************
** Subconsulta: lo aplicado por las OPs a cada factura (del proveedor de
** la OP). nCodPro = 0 -> todos los proveedores.
STATIC FUNCTION CtaProvSqlApl(cP, nCodPro)
RETURN "(SELECT o.proveedor, f.tipocomp, f.letra, f.numfac, SUM(f.importe) AS apl "+;
       "   FROM "+cP+"ordfac f JOIN "+cP+"ordpag o ON o.numero = f.numero "+;
       IF(nCodPro > 0, " WHERE o.proveedor = "+ClipValue2Sql(nCodPro), "")+;
       "  GROUP BY o.proveedor, f.tipocomp, f.letra, f.numfac)"

*************************************************
** Leyenda (ordpag.observa) de la OP de ajuste de la conciliacion.
FUNCTION CtaProvObsAjuste()
RETURN CP_OBS_AJUSTE

*************************************************
** Tabla de OPs anuladas (DDL: llamar FUERA de una transaccion).
** Cada anulacion es un grupo (grupo = id de su fila O):
**   O = la OP anulada, con el anticipo del proveedor antes y despues
**   C = sus conceptos (formas de pago)
**   F = las facturas que pagaba
**   X = OP posterior modificada por arrastre: habia usado el anticipo que
**       generaba la anulada; se le desaplico "importe" de esa factura,
**       que volvio a quedar con saldo
FUNCTION CtaProvCrearAnul(oSrv, cId)
DEFAULT oSrv := oApp:oServer, cId := oApp:cId
oSrv:Execute("CREATE TABLE IF NOT EXISTS ge_"+cId+"ordpag_anul ("+;
             "id INT(10) NOT NULL AUTO_INCREMENT,"+;
             "grupo INT(10) NOT NULL DEFAULT 0,"+;
             "tipo CHAR(1) NOT NULL,"+;
             "anulada INT(10) NOT NULL DEFAULT 0,"+;
             "fecanul DATETIME NULL,"+;
             "usuario VARCHAR(15) NOT NULL DEFAULT '',"+;
             "ip VARCHAR(40) NOT NULL DEFAULT '',"+;
             "proveedor INT(6) NOT NULL DEFAULT 0,"+;
             "numero INT(10) NOT NULL DEFAULT 0,"+;
             "fecha DATE NULL,"+;
             "numeroop INT(10) NOT NULL DEFAULT 0,"+;
             "caja INT(4) NOT NULL DEFAULT 0,"+;
             "total DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
             "facturas DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
             "codcon INT(2) NOT NULL DEFAULT 0,"+;
             "tipocomp VARCHAR(2) NOT NULL DEFAULT '',"+;
             "letra VARCHAR(1) NOT NULL DEFAULT '',"+;
             "numfac VARCHAR(13) NOT NULL DEFAULT '',"+;
             "importe DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
             "anticipo_ant DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
             "anticipo_nue DECIMAL(14,2) NOT NULL DEFAULT 0,"+;
             "observa VARCHAR(255) NOT NULL DEFAULT '',"+;
             "PRIMARY KEY (id), KEY grupo (grupo), KEY proveedor (proveedor)) ENGINE=INNODB DEFAULT CHARSET=utf8")
RETURN nil

*************************************************
** Anula (borra) una OP. Se llama DENTRO de la transaccion del que anula,
** con la tabla ordpag_anul ya creada (CtaProvCrearAnul).
** Guarda la copia en ordpag_anul, libera cheques de terceros, borra
** cheques propios y el deposito de la transferencia, y rehace los saldos:
**  - cliente conciliado: RecalcCtaProv (y el arrastre queda registrado)
**  - sin conciliar: la logica de siempre (sumar/restar)
** Devuelve { proveedor, anticipo_antes, anticipo_despues } o nil si la OP
** no existe. aArr (opcional) recibe el arrastre (ver RecalcCtaProv).
FUNCTION CtaProvAnularOP(nOp, aArr, oSrv, cId, cUsuario, cIp)
LOCAL cP, cNum, cCod, oOp, nAntAnt, nAntNue, nTotPag, nTotFac, cIns, cDat, nGrp, i
DEFAULT aArr := {}, oSrv := oApp:oServer, cId := oApp:cId, cUsuario := oApp:usuario, cIp := oApp:cIp
cIp  := IF(VALTYPE(cIp) = "C", cIp, "")
cP   := "ge_"+cId
cNum := ClipValue2Sql(nOp)
oOp  := oSrv:Query("SELECT * FROM "+cP+"ordpag WHERE numero = "+cNum)
IF oOp:RecCount() = 0
   RETURN nil
ENDIF
cCod    := ClipValue2Sql(oOp:proveedor)
nAntAnt := oSrv:Query("SELECT IFNULL(saldo,0) AS saldo FROM "+cP+"provee WHERE codigo = "+cCod):saldo

// Copia de la OP (O) y su detalle (C conceptos, F facturas)
oSrv:Execute("INSERT INTO "+cP+"ordpag_anul "+;
             "(tipo,anulada,fecanul,usuario,ip,proveedor,numero,fecha,numeroop,caja,total,facturas,anticipo_ant,observa) "+;
             "SELECT 'O',numero,NOW(),"+ClipValue2Sql(LEFT(cUsuario,15))+","+ClipValue2Sql(cIp)+",proveedor,numero,"+;
             "fecha,numeroop,IFNULL(caja,0),IFNULL(total,0),facturas,"+ClipValue2Sql(nAntAnt)+",IFNULL(observa,'') "+;
             "FROM "+cP+"ordpag WHERE numero = "+cNum)
nGrp := oSrv:LastInsertID()
oSrv:Execute("UPDATE "+cP+"ordpag_anul SET grupo = id WHERE id = "+ClipValue2Sql(nGrp))
cIns := "INSERT INTO "+cP+"ordpag_anul (grupo,tipo,anulada,fecanul,usuario,ip,proveedor,numero,"
cDat := ClipValue2Sql(nGrp)+",'#',"+cNum+",NOW(),"+ClipValue2Sql(LEFT(cUsuario,15))+","+ClipValue2Sql(cIp)+","+cCod+","+cNum+","
oSrv:Execute(cIns+"codcon,importe,observa) "+;
             "SELECT "+STRTRAN(cDat,"'#'","'C'")+"IFNULL(codcon,0),IFNULL(importe,0),IFNULL(observa,'') "+;
             "FROM "+cP+"ordcon WHERE numero = "+cNum)
oSrv:Execute(cIns+"fecha,tipocomp,letra,numfac,importe) "+;
             "SELECT "+STRTRAN(cDat,"'#'","'F'")+"fecha,tipocomp,letra,numfac,importe "+;
             "FROM "+cP+"ordfac WHERE numero = "+cNum)

IF !CtaProvConciliado(oSrv, cId)
   // Logica de siempre: devuelve a las facturas lo que pagaba y descuenta
   // del anticipo lo que la OP pago de mas
   oSrv:Execute("UPDATE "+cP+"compras c LEFT JOIN "+cP+"ordpag op ON op.numero = "+cNum+;
                " LEFT JOIN "+cP+"ordfac o ON c.tipocomp = o.tipocomp AND c.letra = o.letra AND "+;
                "c.numfac = o.numfac AND c.codpro = op.proveedor "+;
                "SET c.saldo = c.saldo + ABS(o.importe) "+;
                "WHERE o.numero = "+cNum)
   nTotPag := oSrv:Query("SELECT IFNULL(SUM(importe),0) AS total FROM "+cP+"ordcon WHERE numero = "+cNum+" AND codcon <> 7"):total
   nTotFac := oSrv:Query("SELECT IFNULL(SUM(importe),0) AS total FROM "+cP+"ordfac WHERE numero = "+cNum):total
   oSrv:Execute("UPDATE "+cP+"provee SET saldo = saldo - "+ClipValue2Sql(nTotPag-nTotFac)+" WHERE codigo = "+cCod)
ENDIF

IF !EMPTY(oOp:iddepo)
   oSrv:Execute("DELETE FROM "+cP+"deposito WHERE id = "+ClipValue2Sql(oOp:iddepo))
ENDIF
oSrv:Execute("UPDATE "+cP+"cheter SET estado = 'C', orden = 0, codpro = 0 WHERE orden = "+cNum)
oSrv:Execute("DELETE FROM "+cP+"chepro WHERE orden = "+cNum)
oSrv:Execute("DELETE FROM "+cP+"ordpag WHERE numero = "+cNum)   // ordcon y ordfac en cascada

IF CtaProvConciliado(oSrv, cId)
   RecalcCtaProv(oOp:proveedor, oSrv, cId, aArr)
   FOR i := 1 TO LEN(aArr)
       // numero = la OP modificada; anulada = la que se anulo
       oSrv:Execute("INSERT INTO "+cP+"ordpag_anul "+;
                    "(grupo,tipo,anulada,fecanul,usuario,ip,proveedor,numero,fecha,tipocomp,letra,numfac,importe,observa) VALUES ("+;
                    ClipValue2Sql(nGrp)+",'X',"+cNum+",NOW(),"+ClipValue2Sql(LEFT(cUsuario,15))+","+ClipValue2Sql(cIp)+","+;
                    cCod+","+ClipValue2Sql(aArr[i,1])+","+ClipValue2Sql(aArr[i,2])+","+ClipValue2Sql(aArr[i,3])+","+;
                    ClipValue2Sql(aArr[i,4])+","+ClipValue2Sql(aArr[i,5])+","+ClipValue2Sql(aArr[i,6])+","+;
                    IF(aArr[i,7], "'OP ELIMINADA: QUEDO SIN FACTURAS NI PAGOS'", "''")+")")
   NEXT i
ENDIF
nAntNue := oSrv:Query("SELECT IFNULL(saldo,0) AS saldo FROM "+cP+"provee WHERE codigo = "+cCod):saldo
oSrv:Execute("UPDATE "+cP+"ordpag_anul SET anticipo_nue = "+ClipValue2Sql(nAntNue)+" WHERE id = "+ClipValue2Sql(nGrp))
RETURN { oOp:proveedor, nAntAnt, nAntNue }

*************************************************
** Simula la anulacion de una OP para avisar ANTES de confirmar: borra la
** OP y recalcula dentro de una transaccion que siempre se deshace.
** Devuelve el arrastre (ver RecalcCtaProv); vacio si no hay, o si el
** cliente no esta conciliado. NO llamar dentro de otra transaccion.
FUNCTION CtaProvSimularAnul(nOp, oSrv, cId)
LOCAL aArr := {}, cP, oQ, oError
DEFAULT oSrv := oApp:oServer, cId := oApp:cId
cP := "ge_"+cId
IF !CtaProvConciliado(oSrv, cId)
   RETURN aArr
ENDIF
oQ := oSrv:Query("SELECT proveedor FROM "+cP+"ordpag WHERE numero = "+ClipValue2Sql(nOp))
IF oQ:RecCount() = 0
   RETURN aArr
ENDIF
TRY
   oSrv:BeginTransaction()
   oSrv:Execute("DELETE FROM "+cP+"ordpag WHERE numero = "+ClipValue2Sql(nOp))
   RecalcCtaProv(oQ:proveedor, oSrv, cId, aArr)
CATCH oError
   aArr := {}
END TRY
oSrv:RollBack()
RETURN aArr

*************************************************
** Composicion del anticipo de un proveedor: explica provee.saldo con las
** OPs vigentes. Cada fila: { fecha, detalle, op, pagado, aplicado,
** anticipo (+ genera / - usa), acumulado }. Al final el anticipo guardado
** y, si existe la tabla, las anulaciones que lo afectaron.
** Cliente conciliado y lCompleto = .f. (normal): todo lo anterior a la
** conciliacion (OPs viejas, OP de ajuste y sus correcciones) va resumido
** en una linea "Anticipo al conciliar"; se detalla solo lo posterior.
FUNCTION CtaProvComposicion(nCodPro, oSrv, cId, lCompleto)
LOCAL cP, cCod, aRow := {}, oQ, nAcu := 0, nX, nGuard, dVacia := CTOD(""),;
      nCorte := 0, dConc, nIni := 0, lPre, aMot
DEFAULT oSrv := oApp:oServer, cId := oApp:cId, lCompleto := .f.
cP   := "ge_"+cId
cCod := ClipValue2Sql(nCodPro)

// Corte: ultima OP existente al conciliar (las de ajuste son las ultimas
// que se crearon; bases conciliadas antes de guardar numero_op en la marca)
IF !lCompleto .AND. CtaProvConciliado(oSrv, cId)
   oQ := oSrv:Query("SELECT DATE(fecha) AS fecha, numero_op FROM "+cP+"concilia WHERE tipo = 'C' ORDER BY id LIMIT 1")
   dConc  := oQ:fecha
   nCorte := oQ:numero_op
   IF EMPTY(nCorte)
      nCorte := oSrv:Query("SELECT IFNULL(MAX(numero),0) AS n FROM "+cP+"ordpag WHERE observa = '"+CP_OBS_AJUSTE+"'"):n
   ENDIF
ENDIF

// Lo que cada OP pago de mas (genera anticipo) o de menos (uso anticipo)
oQ := oSrv:Query("SELECT o.numero, o.fecha, IFNULL(o.total,0) AS total, IFNULL(o.observa,'') AS observa, "+;
                 " IFNULL((SELECT SUM(f.importe) FROM "+cP+"ordfac f WHERE f.numero = o.numero),0) AS apl "+;
                 "FROM "+cP+"ordpag o WHERE o.proveedor = "+cCod+" ORDER BY o.fecha, o.numero")
oQ:GoTop()
DO WHILE !oQ:Eof()
   nX := ROUND(oQ:total - oQ:apl,2)
   IF oQ:numero <= nCorte
      nIni := ROUND(nIni + nX,2)
   ELSEIF nX <> 0
      AADD(aRow, { oQ:fecha, ;
                   IF(ALLTRIM(oQ:observa) == CP_OBS_AJUSTE, "Ajuste conciliacion cta cte", ;
                      IF(nX > 0, "Pago de mas: genera anticipo", "Usa anticipo")), ;
                   oQ:numero, oQ:total, oQ:apl, nX, 0 })
   ENDIF
   oQ:Skip()
ENDDO

// Aplicado de mas a una factura, o a un comprobante que ya no existe:
// no descuenta del anticipo. Va al resumen inicial si la ultima OP que la
// toco es anterior a la conciliacion y la factura no se modifico despues
// (ej: se le bajo el importe despues de pagada -> linea propia).
oQ := oSrv:Query("SELECT CONCAT(a.tipocomp,' ',a.letra,' ',a.numfac) AS comp, a.apl, a.ultop, c.fecmod, "+;
                 IF(nCorte > 0, " IF(c.fecmod >= "+ClipValue2Sql(dConc)+", 1, 0)", " 0")+" AS modpost, "+;
                 " IF(c.codpro IS NULL, 'Aplicado a comprobante inexistente', 'Aplicado de mas a') AS det, "+;
                 " a.apl - IF(c.codpro IS NULL, 0, IF(a.tipocomp='NC',-1,1)*LEAST(c.importe, a.apl*IF(a.tipocomp='NC',-1,1))) AS dif "+;
                 "FROM (SELECT o.proveedor, f.tipocomp, f.letra, f.numfac, SUM(f.importe) AS apl, MAX(f.numero) AS ultop "+;
                 "        FROM "+cP+"ordfac f JOIN "+cP+"ordpag o ON o.numero = f.numero "+;
                 "       WHERE o.proveedor = "+cCod+" GROUP BY o.proveedor, f.tipocomp, f.letra, f.numfac) a "+;
                 "LEFT JOIN "+cP+"compras c "+;
                 " ON c.codpro = a.proveedor AND c.tipocomp = a.tipocomp AND c.letra = a.letra AND c.numfac = a.numfac "+;
                 "HAVING ABS(dif) > 0.004")
oQ:GoTop()
DO WHILE !oQ:Eof()
   lPre := oQ:ultop <= nCorte .AND. ;
           !IF(VALTYPE(oQ:modpost) = "L", oQ:modpost, oQ:modpost = 1)
   IF lPre
      nIni := ROUND(nIni + oQ:dif,2)
   ELSE
      AADD(aRow, { IF(VALTYPE(oQ:fecmod) = "D", oQ:fecmod, dVacia), oQ:det+" "+oQ:comp, 0, 0, oQ:apl, oQ:dif, 0 })
   ENDIF
   oQ:Skip()
ENDDO

IF nCorte > 0
   // Motivos por los que se ajusto este proveedor al conciliar (informativos)
   aMot := CtaProvMotivosGuardados(nCodPro, oSrv, cId)
   FOR nX := LEN(aMot) TO 1 STEP -1
       ASIZE(aRow, LEN(aRow)+1)
       AINS(aRow, 1)
       aRow[1] := { dVacia, "   Conciliacion: "+ALLTRIM(aMot[nX,2]), 0, 0, 0, 0, 0 }
   NEXT nX
   ASIZE(aRow, LEN(aRow)+1)
   AINS(aRow, 1)
   aRow[1] := { dConc, "Anticipo al conciliar la cuenta", 0, 0, 0, nIni, 0 }
ENDIF
// Acumulado
FOR nX := 1 TO LEN(aRow)
    nAcu := ROUND(nAcu + aRow[nX,6],2)
    // Las lineas informativas (motivos de la conciliacion) van sin acumulado
    aRow[nX,7] := IF(LEFT(aRow[nX,2],3) == "   ", 0, nAcu)
NEXT nX

nGuard := oSrv:Query("SELECT IFNULL(saldo,0) AS saldo FROM "+cP+"provee WHERE codigo = "+cCod):saldo
AADD(aRow, { dVacia, "ANTICIPO ACTUAL DEL PROVEEDOR"+;
             IF(ABS(nGuard - nAcu) > 0.004, " (NO COINCIDE CON EL DETALLE)", ""), 0, 0, 0, nGuard, nAcu })

// Anulaciones que afectaron al proveedor
IF oSrv:Query("SHOW TABLES LIKE '"+cP+"ordpag_anul'"):RecCount() > 0
   oQ := oSrv:Query("SELECT tipo, DATE(fecanul) AS fecanul, usuario, anulada, numero, fecha, total, facturas, "+;
                    " anticipo_ant, anticipo_nue, CONCAT(tipocomp,' ',letra,' ',numfac) AS comp, importe, observa "+;
                    "FROM "+cP+"ordpag_anul WHERE proveedor = "+cCod+" AND tipo IN ('O','X') "+;
                    "ORDER BY grupo, IF(tipo='O',0,1), id")
   IF oQ:RecCount() > 0
      AADD(aRow, { dVacia, "--- OPS ANULADAS ---", 0, 0, 0, 0, 0 })
   ENDIF
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      IF oQ:tipo = "O"
         AADD(aRow, { oQ:fecanul, "Anulada OP "+ALLTRIM(STR(oQ:anulada))+" del "+IF(VALTYPE(oQ:fecha)="D",DTOC(oQ:fecha),"")+" ("+ALLTRIM(oQ:usuario)+")"+;
                      IF(ROUND(oQ:anticipo_nue - oQ:anticipo_ant,2) <> 0, ;
                         ": anticipo "+ALLTRIM(TRANSFORM(oQ:anticipo_ant,"999,999,999.99"))+" -> "+;
                         ALLTRIM(TRANSFORM(oQ:anticipo_nue,"999,999,999.99")), ""), ;
                      oQ:anulada, oQ:total, oQ:facturas, 0, 0 })
      ELSE
         AADD(aRow, { oQ:fecanul, "   por la anulacion: la OP "+ALLTRIM(STR(oQ:numero))+;
                      " dejo de pagar "+oQ:comp+" (vuelve a tener saldo)"+;
                      IF(EMPTY(oQ:observa), "", " - la OP quedo vacia y se elimino"), ;
                      oQ:numero, 0, -oQ:importe, 0, 0 })
      ENDIF
      oQ:Skip()
   ENDDO
ENDIF
RETURN aRow
