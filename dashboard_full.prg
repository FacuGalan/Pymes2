#include "FiveWin.ch"
#include "Tdolphin.ch"

MEMVAR oApp
STATIC oWnd1, oWebView, cVentana, oPanelWeb, aIAHistorial := {}

//----------------------------------------------------------------//
// PROCEDIMIENTO PRINCIPAL - Ventana MDI con WebView2
//----------------------------------------------------------------//
PROCEDURE DashboardFull()
LOCAL hHand

cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas, cVentana) > 0
   hHand := ASCAN(oApp:aVentanas, cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas, cVentana)

DEFINE WINDOW oWnd1 MDICHILD TITLE "Dashboard Empresarial" ;
   OF oApp:oWnd ICON oApp:oIco

   oPanelWeb := TPanel():New(0, 0, oWnd1:nHeight, oWnd1:nWidth, oWnd1)

   oWebView := TWebView2():New(oPanelWeb)
   oWebView:bOnBind := {|aParams, oWV| DashOnBind(aParams, oWV)}
   oWebView:SetHtml(DashHtml())

ACTIVATE WINDOW oWnd1 MAXIMIZED ;
   ON RESIZE (oPanelWeb:Move(0, 0, oWnd1:nWidth, oWnd1:nHeight - 2), ;
              oWebView:SetSize(oPanelWeb:nWidth, oPanelWeb:nHeight)) ;
   ON INIT (oWnd1:SetSize(oApp:oWnd:oWndClient:nWidth, oApp:oWnd:oWndClient:nHeight), ;
            oPanelWeb:Move(0, 0, oWnd1:nWidth, oWnd1:nHeight - 2), ;
            oWebView:SetSize(oPanelWeb:nWidth, oPanelWeb:nHeight)) ;
   VALID DashCerrar()

RETURN

//----------------------------------------------------------------//
// CERRAR - Limpia la ventana del array de ventanas
//----------------------------------------------------------------//
STATIC FUNCTION DashCerrar()
LOCAL aNueva := {}, i, j
j := ASCAN(oApp:aVentanas, cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva, oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

//----------------------------------------------------------------//
// HANDLER - Recibe mensajes desde JavaScript via SendToFWH()
//----------------------------------------------------------------//
STATIC FUNCTION DashOnBind(aParams, oWV)
LOCAL cAction, cDesde, cHasta, cJSON

IF EMPTY(aParams) .OR. LEN(aParams) = 0
   RETURN nil
ENDIF

cAction := aParams[1]

DO CASE
   CASE cAction == "resumen"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosResumen(cDesde, cHasta)
      oWebView:Eval("recibirDatos('resumen'," + cJSON + ")")

   CASE cAction == "ventas_agrupado"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosVentasAgrupado(cDesde, cHasta, aParams[4])
      oWebView:Eval("recibirDatos('ventas_agrupado'," + cJSON + ")")

   CASE cAction == "ventas_formapago"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosVentasFormaPago(cDesde, cHasta)
      oWebView:Eval("recibirDatos('ventas_formapago'," + cJSON + ")")

   CASE cAction == "top_productos"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosTopProductos(cDesde, cHasta)
      oWebView:Eval("recibirDatos('top_productos'," + cJSON + ")")

   CASE cAction == "compras_cuenta"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosComprasCuenta(cDesde, cHasta)
      oWebView:Eval("recibirDatos('compras_cuenta'," + cJSON + ")")

   CASE cAction == "top_proveedores"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosTopProveedores(cDesde, cHasta)
      oWebView:Eval("recibirDatos('top_proveedores'," + cJSON + ")")

   CASE cAction == "top_comprados"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosTopComprados(cDesde, cHasta)
      oWebView:Eval("recibirDatos('top_comprados'," + cJSON + ")")

   CASE cAction == "cobranzas_resumen"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCobranzasResumen(cDesde, cHasta)
      oWebView:Eval("recibirDatos('cobranzas_resumen'," + cJSON + ")")

   CASE cAction == "cobranzas_formapago"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCobranzasFormaPago(cDesde, cHasta)
      oWebView:Eval("recibirDatos('cobranzas_formapago'," + cJSON + ")")

   CASE cAction == "deudas_cliente"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosDeudasCliente(cDesde, cHasta)
      oWebView:Eval("recibirDatos('deudas_cliente'," + cJSON + ")")

   CASE cAction == "deudas_vendedor"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosDeudasVendedor(cDesde, cHasta)
      oWebView:Eval("recibirDatos('deudas_vendedor'," + cJSON + ")")

   CASE cAction == "ultimos_recibos"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosUltimosRecibos(cDesde, cHasta)
      oWebView:Eval("recibirDatos('ultimos_recibos'," + cJSON + ")")

   CASE cAction == "pagos_resumen"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosPagosResumen(cDesde, cHasta)
      oWebView:Eval("recibirDatos('pagos_resumen'," + cJSON + ")")

   CASE cAction == "pagos_formapago"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosPagosFormaPago(cDesde, cHasta)
      oWebView:Eval("recibirDatos('pagos_formapago'," + cJSON + ")")

   CASE cAction == "deudas_proveedor"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosDeudasProveedor(cDesde, cHasta)
      oWebView:Eval("recibirDatos('deudas_proveedor'," + cJSON + ")")

   CASE cAction == "ultimas_ordpag"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosUltimasOrdPag(cDesde, cHasta)
      oWebView:Eval("recibirDatos('ultimas_ordpag'," + cJSON + ")")

   CASE cAction == "caja_resultado"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCajaResultado(cDesde, cHasta)
      oWebView:Eval("recibirDatos('caja_resultado'," + cJSON + ")")

   CASE cAction == "caja_evolucion"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCajaEvolucion(cDesde, cHasta)
      oWebView:Eval("recibirDatos('caja_evolucion'," + cJSON + ")")

   CASE cAction == "caja_conceptos"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCajaConceptos(cDesde, cHasta)
      oWebView:Eval("recibirDatos('caja_conceptos'," + cJSON + ")")

   CASE cAction == "caja_cierres"
      cDesde := aParams[2]
      cHasta := aParams[3]
      cJSON := DatosCajaCierres(cDesde, cHasta)
      oWebView:Eval("recibirDatos('caja_cierres'," + cJSON + ")")

   CASE cAction == "ia_consulta"
      cJSON := IAConsulta(aParams[2])
      oWebView:Eval("recibirIA(" + cJSON + ")")

   CASE cAction == "ia_calificar"
      IACalificar(aParams[2], aParams[3])
      oWebView:Eval("iaCalificacionOk()")

ENDCASE

RETURN nil

//----------------------------------------------------------------//
// QUERIES - Resumen general (paneles de totales)
//----------------------------------------------------------------//
STATIC FUNCTION DatosResumen(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "(SELECT IFNULL(SUM(importe),0) FROM ge_" + oApp:cId + "ventas_encab " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND LEFT(ticomp,2) = 'FC') AS ventas, " + ;
   ;
   "(SELECT IFNULL(SUM(importe),0) FROM ge_" + oApp:cId + "ventas_encab " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND LEFT(ticomp,2) = 'NC') AS notascredito, " + ;
   ;
   "(SELECT IFNULL(SUM(importe * IF(tipocomp='NC',-1,1)),0) FROM ge_" + oApp:cId + "compras " + ;
   " WHERE fecfac >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecfac <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND tipocomp <> 'RE') AS compras, " + ;
   ;
   "(SELECT IFNULL(SUM(total),0) FROM ge_" + oApp:cId + "pagos " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS cobranzas, " + ;
   ;
   "(SELECT IFNULL(SUM(total),0) FROM ge_" + oApp:cId + "ordpag " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS pagos, " + ;
   ;
   "(SELECT COUNT(*) FROM ge_" + oApp:cId + "ventas_encab " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND LEFT(ticomp,2) = 'FC') AS cant_facturas")

cJSON := '{"ventas":' + ALLTRIM(STR(oQry:ventas, 14, 2)) + ;
         ',"notascredito":' + ALLTRIM(STR(oQry:notascredito, 14, 2)) + ;
         ',"compras":' + ALLTRIM(STR(oQry:compras, 14, 2)) + ;
         ',"cobranzas":' + ALLTRIM(STR(oQry:cobranzas, 14, 2)) + ;
         ',"pagos":' + ALLTRIM(STR(oQry:pagos, 14, 2)) + ;
         ',"cant_facturas":' + ALLTRIM(STR(oQry:cant_facturas, 10)) + ;
         '}'

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Ventas agrupadas por rubro/marca/depto/proveedor
//----------------------------------------------------------------//
STATIC FUNCTION DatosVentasAgrupado(cDesde, cHasta, cAgrupar)
LOCAL oQry, cJSON, cCampo, cJoin, cNombre

DO CASE
   CASE cAgrupar == "marca"
      cJoin  := "LEFT JOIN ge_" + oApp:cId + "marcas t ON t.codigo = a.marca "
      cCampo := "t.nombre"
      cNombre := "Sin marca"
   CASE cAgrupar == "depto"
      cJoin  := "LEFT JOIN ge_" + oApp:cId + "deptos t ON t.codigo = a.depto "
      cCampo := "t.nombre"
      cNombre := "Sin depto"
   CASE cAgrupar == "proveedor"
      cJoin  := "LEFT JOIN ge_" + oApp:cId + "provee t ON t.codigo = a.prov "
      cCampo := "t.nombre"
      cNombre := "Sin proveedor"
   OTHERWISE // rubro
      cJoin  := "LEFT JOIN ge_" + oApp:cId + "rubros t ON t.codigo = a.rubro "
      cCampo := "t.nombre"
      cNombre := "Sin rubro"
ENDCASE

oQry := oApp:oServer:Query( ;
   "SELECT IFNULL(" + cCampo + ",'" + cNombre + "') AS agrupado, " + ;
   "SUM(d.importe) AS total " + ;
   "FROM ge_" + oApp:cId + "ventas_det d " + ;
   "LEFT JOIN ge_" + oApp:cId + "articu a ON a.codigo = d.codart " + ;
   cJoin + ;
   "WHERE d.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND d.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND d.codart > 0 AND LEFT(d.nrofac,2) <> 'NC' " + ;
   "GROUP BY agrupado HAVING total > 0 ORDER BY total DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:agrupado)) + '",' + ;
            ALLTRIM(STR(oQry:total, 14, 2)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Ventas por forma de pago
//----------------------------------------------------------------//
STATIC FUNCTION DatosVentasFormaPago(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "CASE c.tipocon " + ;
   "  WHEN 1 THEN 'Efectivo' " + ;
   "  WHEN 2 THEN 'Transferencia' " + ;
   "  WHEN 3 THEN 'Cheque' " + ;
   "  WHEN 4 THEN 'Tarjeta' " + ;
   "  WHEN 5 THEN 'Cuenta Corriente' " + ;
   "  WHEN 6 THEN 'Otros' " + ;
   "  ELSE 'Otros' END AS forma, " + ;
   "SUM(c.importe) AS total " + ;
   "FROM ge_" + oApp:cId + "concfact c " + ;
   "WHERE c.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND c.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " GROUP BY forma ORDER BY total DESC")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:forma)) + '",' + ALLTRIM(STR(oQry:total, 14, 2)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Top 10 productos mas vendidos
//----------------------------------------------------------------//
STATIC FUNCTION DatosTopProductos(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT a.nombre, SUM(d.cantidad) AS cantidad, SUM(d.importe) AS total " + ;
   "FROM ge_" + oApp:cId + "ventas_det d " + ;
   "LEFT JOIN ge_" + oApp:cId + "articu a ON a.codigo = d.codart " + ;
   "WHERE d.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND d.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND d.codart > 0 " + ;
   "GROUP BY a.nombre ORDER BY total DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"nombre":"' + JsonEscape(ALLTRIM(oQry:nombre)) + '"' + ;
            ',"cantidad":' + ALLTRIM(STR(oQry:cantidad, 12, 2)) + ;
            ',"total":' + ALLTRIM(STR(oQry:total, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Compras por cuenta contable
//----------------------------------------------------------------//
STATIC FUNCTION DatosComprasCuenta(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT IFNULL(t.nombre,'Sin cuenta') AS agrupado, " + ;
   "SUM(c.importe * IF(c.tipocomp='NC',-1,1)) AS total " + ;
   "FROM ge_" + oApp:cId + "compras c " + ;
   "LEFT JOIN ge_" + oApp:cId + "plancont t ON t.codigo = c.codcue " + ;
   "WHERE c.fecfac >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND c.fecfac <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND c.tipocomp <> 'RE' " + ;
   "GROUP BY agrupado HAVING total > 0 ORDER BY total DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:agrupado)) + '",' + ;
            ALLTRIM(STR(oQry:total, 14, 2)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Top 10 productos mas comprados
//----------------------------------------------------------------//
STATIC FUNCTION DatosTopComprados(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT a.nombre, " + ;
   "SUM(d.cantidad * IF(d.tipocomp='NC',-1,1)) AS cantidad, " + ;
   "SUM(d.cantidad * d.punit * IF(d.tipocomp='NC',-1,1)) AS total " + ;
   "FROM ge_" + oApp:cId + "compradet d " + ;
   "LEFT JOIN ge_" + oApp:cId + "articu a ON a.codigo = d.codart " + ;
   "LEFT JOIN ge_" + oApp:cId + "compras c ON CONCAT(c.tipocomp,c.letra,c.numfac) = CONCAT(d.tipocomp,d.letra,d.numfac) AND c.codpro = d.codpro " + ;
   "WHERE c.fecfac >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND c.fecfac <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND d.codart > 0 " + ;
   "GROUP BY a.nombre HAVING total > 0 ORDER BY total DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"nombre":"' + JsonEscape(ALLTRIM(oQry:nombre)) + '"' + ;
            ',"cantidad":' + ALLTRIM(STR(oQry:cantidad, 12, 2)) + ;
            ',"total":' + ALLTRIM(STR(oQry:total, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Top 10 proveedores por monto de compra
//----------------------------------------------------------------//
STATIC FUNCTION DatosTopProveedores(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT p.nombre, " + ;
   "SUM(c.importe * IF(c.tipocomp='NC',-1,1)) AS total, " + ;
   "COUNT(*) AS cant_compras " + ;
   "FROM ge_" + oApp:cId + "compras c " + ;
   "LEFT JOIN ge_" + oApp:cId + "provee p ON p.codigo = c.codpro " + ;
   "WHERE c.fecfac >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND c.fecfac <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " AND c.tipocomp <> 'RE' " + ;
   "GROUP BY p.nombre HAVING total > 0 ORDER BY total DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"nombre":"' + JsonEscape(ALLTRIM(IF(EMPTY(oQry:nombre),"Sin proveedor",oQry:nombre))) + '"' + ;
            ',"cant_compras":' + ALLTRIM(STR(oQry:cant_compras, 10)) + ;
            ',"total":' + ALLTRIM(STR(oQry:total, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Cobranzas: paneles de resumen
//----------------------------------------------------------------//
STATIC FUNCTION DatosCobranzasResumen(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "(SELECT IFNULL(SUM(total),0) FROM ge_" + oApp:cId + "pagos " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS cobrado, " + ;
   ;
   "(SELECT IFNULL(SUM(saldo * IF(tipo='NC',-1,1)),0) FROM ge_" + oApp:cId + "ventas_cuota " + ;
   " WHERE saldo > 0) AS deuda_total, " + ;
   ;
   "(SELECT IFNULL(SUM(saldo * IF(tipo='NC',-1,1)),0) FROM ge_" + oApp:cId + "ventas_cuota " + ;
   " WHERE saldo > 0 AND fecha < CURDATE() - INTERVAL 30 DAY) AS deuda_vencida, " + ;
   ;
   "(SELECT COUNT(DISTINCT cliente) FROM ge_" + oApp:cId + "ventas_cuota " + ;
   " WHERE saldo > 0) AS clientes_deudores, " + ;
   ;
   "(SELECT COUNT(*) FROM ge_" + oApp:cId + "pagos " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS cant_recibos")

cJSON := '{"cobrado":' + ALLTRIM(STR(oQry:cobrado, 14, 2)) + ;
         ',"deuda_total":' + ALLTRIM(STR(oQry:deuda_total, 14, 2)) + ;
         ',"deuda_vencida":' + ALLTRIM(STR(oQry:deuda_vencida, 14, 2)) + ;
         ',"clientes_deudores":' + ALLTRIM(STR(oQry:clientes_deudores, 10)) + ;
         ',"cant_recibos":' + ALLTRIM(STR(oQry:cant_recibos, 10)) + ;
         '}'

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Cobranzas por forma de pago
//----------------------------------------------------------------//
STATIC FUNCTION DatosCobranzasFormaPago(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "CASE pc.tipocon " + ;
   "  WHEN 1 THEN 'Efectivo' " + ;
   "  WHEN 2 THEN 'Transferencia' " + ;
   "  WHEN 3 THEN 'Cheque' " + ;
   "  WHEN 4 THEN 'Tarjeta' " + ;
   "  WHEN 5 THEN 'Retencion' " + ;
   "  WHEN 6 THEN 'Promocion' " + ;
   "  WHEN 7 THEN 'Anticipo' " + ;
   "  WHEN 8 THEN 'M. Pago' " + ;
   "  ELSE 'Otros' END AS forma, " + ;
   "SUM(pc.importe) AS total " + ;
   "FROM ge_" + oApp:cId + "pagcon pc " + ;
   "LEFT JOIN ge_" + oApp:cId + "pagos p ON p.numero = pc.numero " + ;
   "WHERE p.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND p.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " GROUP BY forma ORDER BY total DESC")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:forma)) + '",' + ALLTRIM(STR(oQry:total, 14, 2)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Deudas por cliente (top 10)
//----------------------------------------------------------------//
STATIC FUNCTION DatosDeudasCliente(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT c.nombre, " + ;
   "SUM(v.saldo * IF(v.tipo='NC',-1,1)) AS deuda, " + ;
   "MIN(v.fecha) AS fecha_mas_vieja, " + ;
   "DATEDIFF(CURDATE(), MIN(v.fecha)) AS dias_atraso " + ;
   "FROM ge_" + oApp:cId + "ventas_cuota v " + ;
   "LEFT JOIN ge_" + oApp:cId + "clientes c ON c.codigo = v.cliente " + ;
   "WHERE v.saldo > 0 " + ;
   "GROUP BY c.nombre HAVING deuda > 0 ORDER BY deuda DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"nombre":"' + JsonEscape(ALLTRIM(oQry:nombre)) + '"' + ;
            ',"deuda":' + ALLTRIM(STR(oQry:deuda, 14, 2)) + ;
            ',"dias_atraso":' + ALLTRIM(STR(oQry:dias_atraso, 10)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Deudas agrupadas por vendedor
//----------------------------------------------------------------//
STATIC FUNCTION DatosDeudasVendedor(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT IFNULL(ve.nombre,'Sin vendedor') AS vendedor, " + ;
   "SUM(v.saldo * IF(v.tipo='NC',-1,1)) AS deuda, " + ;
   "COUNT(DISTINCT v.cliente) AS cant_clientes " + ;
   "FROM ge_" + oApp:cId + "ventas_cuota v " + ;
   "LEFT JOIN ge_" + oApp:cId + "clientes c ON c.codigo = v.cliente " + ;
   "LEFT JOIN ge_" + oApp:cId + "vendedores ve ON ve.codigo = c.vendedor " + ;
   "WHERE v.saldo > 0 " + ;
   "GROUP BY vendedor HAVING deuda > 0 ORDER BY deuda DESC")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:vendedor)) + '",' + ;
            ALLTRIM(STR(oQry:deuda, 14, 2)) + ',' + ;
            ALLTRIM(STR(oQry:cant_clientes, 10)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Ultimos 10 recibos cobrados
//----------------------------------------------------------------//
STATIC FUNCTION DatosUltimosRecibos(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT p.numero, p.fecha, p.total, c.nombre, p.usuario, " + ;
   "IFNULL(GROUP_CONCAT(DISTINCT CONCAT(pf.ticomp,pf.letra,pf.numcomp) SEPARATOR ', '),'') AS facturas " + ;
   "FROM ge_" + oApp:cId + "pagos p " + ;
   "LEFT JOIN ge_" + oApp:cId + "clientes c ON c.codigo = p.cliente " + ;
   "LEFT JOIN ge_" + oApp:cId + "pagfac pf ON pf.numero = p.numero " + ;
   "WHERE p.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND p.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " GROUP BY p.numero, p.fecha, p.total, c.nombre, p.usuario " + ;
   "ORDER BY p.fecha DESC, p.numero DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"numero":' + ALLTRIM(STR(oQry:numero, 10)) + ;
            ',"fecha":"' + DTOC(oQry:fecha) + '"' + ;
            ',"total":' + ALLTRIM(STR(oQry:total, 14, 2)) + ;
            ',"cliente":"' + JsonEscape(ALLTRIM(oQry:nombre)) + '"' + ;
            ',"usuario":"' + JsonEscape(ALLTRIM(oQry:usuario)) + '"' + ;
            ',"facturas":"' + JsonEscape(ALLTRIM(oQry:facturas)) + '"}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Pagos a proveedores: paneles de resumen
//----------------------------------------------------------------//
STATIC FUNCTION DatosPagosResumen(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "(SELECT IFNULL(SUM(total),0) FROM ge_" + oApp:cId + "ordpag " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS pagado, " + ;
   ;
   "(SELECT IFNULL(SUM(saldo * IF(tipocomp='NC',-1,1)),0) FROM ge_" + oApp:cId + "compras " + ;
   " WHERE saldo > 0 AND tipocomp <> 'RE') AS deuda_total, " + ;
   ;
   "(SELECT IFNULL(SUM(saldo * IF(tipocomp='NC',-1,1)),0) FROM ge_" + oApp:cId + "compras " + ;
   " WHERE saldo > 0 AND tipocomp <> 'RE' AND fecfac < CURDATE() - INTERVAL 30 DAY) AS deuda_vencida, " + ;
   ;
   "(SELECT COUNT(DISTINCT codpro) FROM ge_" + oApp:cId + "compras " + ;
   " WHERE saldo > 0 AND tipocomp <> 'RE') AS prov_deudores, " + ;
   ;
   "(SELECT COUNT(*) FROM ge_" + oApp:cId + "ordpag " + ;
   " WHERE fecha >= " + ClipValue2Sql(CTOD(cDesde)) + " AND fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   ") AS cant_ordenes")

cJSON := '{"pagado":' + ALLTRIM(STR(oQry:pagado, 14, 2)) + ;
         ',"deuda_total":' + ALLTRIM(STR(oQry:deuda_total, 14, 2)) + ;
         ',"deuda_vencida":' + ALLTRIM(STR(oQry:deuda_vencida, 14, 2)) + ;
         ',"prov_deudores":' + ALLTRIM(STR(oQry:prov_deudores, 10)) + ;
         ',"cant_ordenes":' + ALLTRIM(STR(oQry:cant_ordenes, 10)) + ;
         '}'

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Pagos por forma de pago (ordcon)
//----------------------------------------------------------------//
STATIC FUNCTION DatosPagosFormaPago(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT " + ;
   "CASE oc.codcon " + ;
   "  WHEN 1 THEN 'Efectivo' " + ;
   "  WHEN 2 THEN 'Transferencia' " + ;
   "  WHEN 3 THEN 'Cheque Terceros' " + ;
   "  WHEN 4 THEN 'Cheque Propio' " + ;
   "  WHEN 5 THEN 'Retencion' " + ;
   "  WHEN 7 THEN 'Anticipo' " + ;
   "  WHEN 8 THEN 'M. Pago' " + ;
   "  ELSE 'Otros' END AS forma, " + ;
   "SUM(oc.importe) AS total " + ;
   "FROM ge_" + oApp:cId + "ordcon oc " + ;
   "LEFT JOIN ge_" + oApp:cId + "ordpag o ON o.numero = oc.numero " + ;
   "WHERE o.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND o.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " GROUP BY forma ORDER BY total DESC")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '["' + JsonEscape(ALLTRIM(oQry:forma)) + '",' + ALLTRIM(STR(oQry:total, 14, 2)) + ']'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Deudas por proveedor (top 10)
//----------------------------------------------------------------//
STATIC FUNCTION DatosDeudasProveedor(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT p.nombre, " + ;
   "SUM(c.saldo * IF(c.tipocomp='NC',-1,1)) AS deuda, " + ;
   "MIN(c.fecfac) AS fecha_mas_vieja, " + ;
   "DATEDIFF(CURDATE(), MIN(c.fecfac)) AS dias_atraso " + ;
   "FROM ge_" + oApp:cId + "compras c " + ;
   "LEFT JOIN ge_" + oApp:cId + "provee p ON p.codigo = c.codpro " + ;
   "WHERE c.saldo > 0 AND c.tipocomp <> 'RE' " + ;
   "GROUP BY p.nombre HAVING deuda > 0 ORDER BY deuda DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"nombre":"' + JsonEscape(ALLTRIM(IF(EMPTY(oQry:nombre),"Sin proveedor",oQry:nombre))) + '"' + ;
            ',"deuda":' + ALLTRIM(STR(oQry:deuda, 14, 2)) + ;
            ',"dias_atraso":' + ALLTRIM(STR(oQry:dias_atraso, 10)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Ultimas 10 ordenes de pago
//----------------------------------------------------------------//
STATIC FUNCTION DatosUltimasOrdPag(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT o.numero, o.fecha, o.total, p.nombre, o.usuario " + ;
   "FROM ge_" + oApp:cId + "ordpag o " + ;
   "LEFT JOIN ge_" + oApp:cId + "provee p ON p.codigo = o.proveedor " + ;
   "WHERE o.fecha >= " + ClipValue2Sql(CTOD(cDesde)) + ;
   " AND o.fecha <= " + ClipValue2Sql(CTOD(cHasta)) + ;
   " ORDER BY o.fecha DESC, o.numero DESC LIMIT 10")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"numero":' + ALLTRIM(STR(oQry:numero, 10)) + ;
            ',"fecha":"' + DTOC(oQry:fecha) + '"' + ;
            ',"total":' + ALLTRIM(STR(oQry:total, 14, 2)) + ;
            ',"proveedor":"' + JsonEscape(ALLTRIM(IF(EMPTY(oQry:nombre),"Sin proveedor",oQry:nombre))) + '"' + ;
            ',"usuario":"' + JsonEscape(ALLTRIM(oQry:usuario)) + '"}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Caja: Resultado del periodo (ventas-compras-cobros-pagos)
//----------------------------------------------------------------//
STATIC FUNCTION DatosCajaResultado(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT RES.* FROM (" + ;
   "(SELECT 'Ventas' as concepto, IFNULL(SUM(importe*IF(ticomp='NC',-1,1)),0) as ingreso, 0 as egreso FROM ge_" + oApp:cId + "ventas_encab " + ;
   " WHERE fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + ") " + ;
   "UNION ALL " + ;
   "(SELECT 'Compras' as concepto, 0 as ingreso, IFNULL(SUM(importe*IF(tipocomp='NC',-1,1)),0) as egreso FROM ge_" + oApp:cId + "compras " + ;
   " WHERE fecfac BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + " AND tipocomp <> 'RE') " + ;
   "UNION ALL " + ;
   "(SELECT 'Cobranzas' as concepto, IFNULL(SUM(total),0) as ingreso, 0 as egreso FROM ge_" + oApp:cId + "pagos " + ;
   " WHERE fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + ") " + ;
   "UNION ALL " + ;
   "(SELECT 'Pagos Prov.' as concepto, 0 as ingreso, IFNULL(SUM(total),0) as egreso FROM ge_" + oApp:cId + "ordpag " + ;
   " WHERE fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + ") " + ;
   "UNION ALL " + ;
   "(SELECT 'Faltantes/Sobrantes' as concepto, 0 as ingreso, IFNULL(SUM(saldo),0) as egreso FROM ge_" + oApp:cId + "cajadiaria " + ;
   " WHERE fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + ") " + ;
   ") RES")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"concepto":"' + JsonEscape(ALLTRIM(oQry:concepto)) + '"' + ;
            ',"ingreso":' + ALLTRIM(STR(oQry:ingreso, 14, 2)) + ;
            ',"egreso":' + ALLTRIM(STR(oQry:egreso, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Caja: evolucion diaria de ingresos/egresos
//----------------------------------------------------------------//
STATIC FUNCTION DatosCajaEvolucion(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT c.fecha, SUM(cd.debe) AS ingresos, SUM(cd.haber) AS egresos, SUM(c.saldo) AS faltante " + ;
   "FROM ge_" + oApp:cId + "cajadiaria c " + ;
   "LEFT JOIN (SELECT id_caja, SUM(debe) AS debe, SUM(haber) AS haber " + ;
   " FROM ge_" + oApp:cId + "cajadiaria_det WHERE LEFT(concepto,1) <> '*' GROUP BY id_caja) cd ON cd.id_caja = c.id " + ;
   "WHERE c.fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + " " + ;
   "GROUP BY c.fecha ORDER BY c.fecha")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"fecha":"' + DTOC(oQry:fecha) + '"' + ;
            ',"ingresos":' + ALLTRIM(STR(oQry:ingresos, 14, 2)) + ;
            ',"egresos":' + ALLTRIM(STR(oQry:egresos, 14, 2)) + ;
            ',"faltante":' + ALLTRIM(STR(oQry:faltante, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Caja: detalle por concepto
//----------------------------------------------------------------//
STATIC FUNCTION DatosCajaConceptos(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT cd.concepto, SUM(cd.debe) AS debe, SUM(cd.haber) AS haber, SUM(cd.efectivo) AS efectivo " + ;
   "FROM ge_" + oApp:cId + "cajadiaria_det cd " + ;
   "LEFT JOIN ge_" + oApp:cId + "cajadiaria c ON c.id = cd.id_caja " + ;
   "WHERE c.fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + " " + ;
   "AND LEFT(cd.concepto,1) <> '*' " + ;
   "GROUP BY cd.concepto ORDER BY debe+haber DESC")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"concepto":"' + JsonEscape(ALLTRIM(oQry:concepto)) + '"' + ;
            ',"debe":' + ALLTRIM(STR(oQry:debe, 14, 2)) + ;
            ',"haber":' + ALLTRIM(STR(oQry:haber, 14, 2)) + ;
            ',"efectivo":' + ALLTRIM(STR(oQry:efectivo, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// QUERIES - Caja: ultimos cierres
//----------------------------------------------------------------//
STATIC FUNCTION DatosCajaCierres(cDesde, cHasta)
LOCAL oQry, cJSON

oQry := oApp:oServer:Query( ;
   "SELECT c.id, c.fecha, c.caja, c.hora, c.saldo, cd.debe, cd.haber, cd.efectivo " + ;
   "FROM ge_" + oApp:cId + "cajadiaria c " + ;
   "LEFT JOIN (SELECT id_caja, SUM(debe) AS debe, SUM(haber) AS haber, SUM(efectivo) AS efectivo " + ;
   " FROM ge_" + oApp:cId + "cajadiaria_det WHERE LEFT(concepto,1) <> '*' GROUP BY id_caja) cd ON cd.id_caja = c.id " + ;
   "WHERE c.fecha BETWEEN " + ClipValue2Sql(CTOD(cDesde)) + " AND " + ClipValue2Sql(CTOD(cHasta)) + " " + ;
   "ORDER BY c.id DESC LIMIT 15")

cJSON := "["
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF LEN(cJSON) > 1
      cJSON += ","
   ENDIF
   cJSON += '{"id":' + ALLTRIM(STR(oQry:id, 10)) + ;
            ',"fecha":"' + DTOC(oQry:fecha) + '"' + ;
            ',"caja":' + ALLTRIM(STR(oQry:caja, 5)) + ;
            ',"hora":"' + ALLTRIM(oQry:hora) + '"' + ;
            ',"saldo":' + ALLTRIM(STR(oQry:saldo, 14, 2)) + ;
            ',"debe":' + ALLTRIM(STR(oQry:debe, 14, 2)) + ;
            ',"haber":' + ALLTRIM(STR(oQry:haber, 14, 2)) + ;
            ',"efectivo":' + ALLTRIM(STR(oQry:efectivo, 14, 2)) + '}'
   oQry:Skip()
ENDDO
cJSON += "]"

RETURN cJSON

//----------------------------------------------------------------//
// IA - Consulta: recibe pregunta, genera SQL, ejecuta, devuelve JSON
//----------------------------------------------------------------//
STATIC FUNCTION IAConsulta(cPregunta)
LOCAL cSQL, cRespIA, cJSON, cPrefix, oQry, i, cColumnas, cFila, oErr

cPrefix := "ge_" + oApp:cId

// 0. Guardar pregunta en historial
AADD(aIAHistorial, {"role" => "user", "content" => cPregunta})

// 1. Llamar a Groq para obtener SQL
cRespIA := IALlamarGroq(cPregunta, cPrefix)

IF EMPTY(cRespIA)
   RETURN '{"error":"No se pudo conectar con la IA"}'
ENDIF

// Guardar respuesta en historial
AADD(aIAHistorial, {"role" => "assistant", "content" => cRespIA})
// Limitar historial a 10 mensajes para no saturar memoria
DO WHILE LEN(aIAHistorial) > 10
   ADEL(aIAHistorial, 1, .T.)
ENDDO

// 2. Extraer SQL de la respuesta (si no es SQL, es respuesta de texto)
cSQL := IAExtraerSQL(cRespIA)

IF EMPTY(cSQL)
   // Es una respuesta informativa, no SQL
   IAGuardar(cPregunta, "TEXTO", "N")
   RETURN '{"texto":"' + JsonEscape(IALimpiarTexto(cRespIA)) + '"}'
ENDIF

// 2b. Corregir comillas faltantes en valores de texto
cSQL := IACorregirComillas(cSQL)

// 3. Validar seguridad
IF !IAValidarSQL(cSQL, cPrefix)
   RETURN '{"error":"La consulta generada no es segura o intenta modificar datos","sql":"' + JsonEscape(cSQL) + '"}'
ENDIF

// 4. Asegurar LIMIT
IF !("LIMIT" $ UPPER(cSQL))
   cSQL := cSQL + " LIMIT 100"
ENDIF

// 5. Ejecutar query
TRY
   oQry := oApp:oServer:Query(cSQL)
CATCH oErr
   RETURN '{"error":"Error al ejecutar la consulta: ' + JsonEscape(oErr:description) + '","sql":"' + JsonEscape(cSQL) + '"}'
END TRY

IF oQry:RecCount() = 0
   RETURN '{"sql":"' + JsonEscape(cSQL) + '","columnas":[],"datos":[],"mensaje":"La consulta no devolvio resultados"}'
ENDIF

// 6. Armar JSON con columnas y datos
cColumnas := "["
FOR i := 1 TO oQry:FCount()
    IF i > 1
       cColumnas += ","
    ENDIF
    cColumnas += '"' + JsonEscape(IALimpiarTexto(oQry:FieldName(i))) + '"'
NEXT i
cColumnas += "]"

cJSON := '{"sql":"' + JsonEscape(cSQL) + '","columnas":' + cColumnas + ',"datos":['
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF oQry:RecNo() > 1
      cJSON += ","
   ENDIF
   cFila := "["
   FOR i := 1 TO oQry:FCount()
       IF i > 1
          cFila += ","
       ENDIF
       IF VALTYPE(oQry:FieldGet(i)) == "C"
          cFila += '"' + JsonEscape(ALLTRIM(oQry:FieldGet(i))) + '"'
       ELSEIF VALTYPE(oQry:FieldGet(i)) == "N"
          cFila += ALLTRIM(STR(oQry:FieldGet(i), 20, 2))
       ELSEIF VALTYPE(oQry:FieldGet(i)) == "D"
          cFila += '"' + DTOC(oQry:FieldGet(i)) + '"'
       ELSEIF VALTYPE(oQry:FieldGet(i)) == "L"
          cFila += IF(oQry:FieldGet(i), "true", "false")
       ELSE
          cFila += '""'
       ENDIF
   NEXT i
   cFila += "]"
   cJSON += cFila
   oQry:Skip()
ENDDO
cJSON += ']}'

// Guardar la pregunta como pendiente de calificacion
IAGuardar(cPregunta, "SQL", "P")

RETURN cJSON

//----------------------------------------------------------------//
// IA - Llamar a Groq API
//----------------------------------------------------------------//
STATIC FUNCTION IALlamarGroq(cPregunta, cPrefix)
LOCAL oHttp, cJsonReq, cResponse := ""
LOCAL hRequest := {=>}, hSys := {=>}, hUser := {=>}, hResp, cValue, aMessages, i
LOCAL cKey := oApp:oServer:Query("SELECT KEY FROM CONFIG")
LOCAL cSchema, cContexto


cSchema := ;
   "Eres un asistente SQL para MySQL. Genera SOLO UN SELECT valido, sin explicaciones, sin markdown, sin comillas de bloque, sin punto y coma. " + ;
   "TABLAS (prefijo " + cPrefix + "): " + ;
   ;
   "VENTAS - Hay 4 tablas, cada una con un proposito distinto: " + ;
   ;
   "TABLA 1 - " + cPrefix + "ventas_encab: ENCABEZADO de factura, UNA fila por factura con el total. " + ;
   "Campos: ticomp(FC=factura,NC=nota credito),letra,numcomp,codcli INT,fecha DATE,neto DECIMAL,iva DECIMAL,importe DECIMAL(total factura),usuario,vendedor. " + ;
   "USAR PARA: totales de ventas por periodo, cantidad de facturas, promedios de ticket, ventas por usuario/vendedor. " + ;
   "NO tiene saldo de deuda, NO tiene detalle de productos. " + ;
   ;
   "TABLA 2 - " + cPrefix + "ventas_det: DETALLE de productos vendidos, UNA fila por cada articulo dentro de cada factura. " + ;
   "Campos: codart BIGINT,detart VARCHAR,cantidad DECIMAL,punit DECIMAL,fecha DATE,codcli INT,nrofac VARCHAR,importe DECIMAL(subtotal linea),neto,iva,pcosto. " + ;
   "USAR PARA: que productos se vendieron, cantidades, ranking de productos, ventas por rubro/marca/depto. SIEMPRE JOIN con articu para nombre. " + ;
   ;
   "TABLA 3 - " + cPrefix + "ventas_cuota: DEUDA de cada factura. UNA fila por factura con importe original y saldo adeudado. " + ;
   "Campos: tipo(FC/NC),letra,numero,cliente INT,fecha DATE,importe DECIMAL(valor original),saldo DECIMAL(lo que falta pagar),estado(P=pagado/I=impago). " + ;
   "USAR PARA: deudas de clientes, facturas impagas, antigueedad de deuda, saldos pendientes. " + ;
   "saldo>0 = el cliente todavia debe. saldo=0 = ya pago. " + ;
   "Para facturas adeudadas mas viejas: SELECT v.tipo,v.letra,v.numero,c.nombre,v.fecha,v.importe,v.saldo FROM " + cPrefix + "ventas_cuota v LEFT JOIN " + cPrefix + "clientes c ON c.codigo=v.cliente WHERE v.saldo>0 ORDER BY v.fecha ASC. " + ;
   "Para saber quien me debe mas: SELECT c.nombre,SUM(v.saldo*IF(v.tipo='NC',-1,1)) as deuda FROM " + cPrefix + "ventas_cuota v LEFT JOIN " + cPrefix + "clientes c ON c.codigo=v.cliente WHERE v.saldo>0 GROUP BY c.nombre HAVING deuda>0 ORDER BY deuda DESC. " + ;
   "NUNCA buscar deudas en ventas_encab, SIEMPRE en ventas_cuota. " + ;
   ;
   "TABLA 4 - " + cPrefix + "ventivadet: Detalle de IVA por factura. " + ;
   "Campos: tipocomp,letra,numfac,codiva INT,neto DECIMAL,iva DECIMAL. " + ;
   "USAR PARA: detalle de IVA facturado, netos por tasa de IVA, libro IVA ventas. " + ;
   ;
   "REGLAS DE VENTAS: " + ;
   "NUNCA inventes campos que no estan listados arriba. Si un campo no fue mencionado, NO existe. " + ;
   "Para obtener nombre del articulo: JOIN " + cPrefix + "articu a ON a.codigo=d.codart. " + ;
   "Para ventas netas: SUM(importe*IF(LEFT(ticomp,2)='NC',-1,1)). " + ;
   "NUNCA JOIN directo entre ventas_encab y ventas_det (duplica filas), usar subqueries con LEFT JOIN por campo comun. " + ;
   "Ejemplo combinado encab+det por mes: " + ;
   "SELECT e.mes, e.total_vendido, e.cant_facturas, ROUND(e.total_vendido/e.cant_facturas,2) as promedio_ticket, " + ;
   "d.cant_articulos, ROUND(d.cant_articulos/e.cant_facturas,2) as prom_art_x_ticket " + ;
   "FROM (SELECT MONTH(fecha) as mes, SUM(importe) as total_vendido, COUNT(*) as cant_facturas " + ;
   "FROM " + cPrefix + "ventas_encab WHERE LEFT(ticomp,2)='FC' GROUP BY MONTH(fecha)) e " + ;
   "LEFT JOIN (SELECT MONTH(fecha) as mes, SUM(cantidad) as cant_articulos " + ;
   "FROM " + cPrefix + "ventas_det WHERE codart>0 GROUP BY MONTH(fecha)) d ON d.mes=e.mes ORDER BY e.mes. " + ;
   ;
   "COMPRAS: " + ;
   cPrefix + "compras(tipocomp VARCHAR,letra VARCHAR,numfac VARCHAR,codpro INT,fecfac DATE,neto DECIMAL,iva DECIMAL,importe DECIMAL,saldo DECIMAL). " + ;
   "La fecha en compras es fecfac (NO fecha). Excluir remitos: tipocomp<>'RE'. " + ;
   "saldo>0 significa que le debemos al proveedor. Para saber a quien le debo mas: SELECT p.nombre,SUM(c.saldo*IF(c.tipocomp='NC',-1,1)) as deuda FROM " + cPrefix + "compras c LEFT JOIN " + cPrefix + "provee p ON p.codigo=c.codpro WHERE c.saldo>0 AND c.tipocomp<>'RE' GROUP BY p.nombre HAVING deuda>0 ORDER BY deuda DESC. " + ;
   ;
   "COBRANZAS: " + cPrefix + "pagos(numero INT,cliente INT,total DECIMAL,fecha DATE,usuario VARCHAR). " + ;
   "PAGOS A PROVEEDORES: " + cPrefix + "ordpag(numero INT,proveedor INT,total DECIMAL,fecha DATE,usuario VARCHAR). " + ;
   ;
   "MAESTROS: " + ;
   cPrefix + "articu(codigo BIGINT,nombre VARCHAR,precioven DECIMAL,reventa DECIMAL,preciocos DECIMAL,stockact DECIMAL,stockmin DECIMAL,prov INT,marca INT,rubro INT,depto INT). " + ;
   "El articulo tiene relaciones con: prov->provee.codigo, marca->marcas.codigo, rubro->rubros.codigo, depto->deptos.codigo. " + ;
   "Para saber el rubro/marca/depto/proveedor de un articulo vendido hay que ir desde ventas_det hasta articu y de ahi a la tabla maestra. " + ;
   "Ejemplo rubros vendidos en un periodo: SELECT DISTINCT r.nombre as rubro FROM " + cPrefix + "ventas_det d LEFT JOIN " + cPrefix + "articu a ON a.codigo=d.codart LEFT JOIN " + cPrefix + "rubros r ON r.codigo=a.rubro WHERE d.fecha BETWEEN '2026-01-01' AND '2026-01-31' AND d.codart>0. " + ;
   "Ejemplo ventas agrupadas por marca: SELECT m.nombre as marca, SUM(d.importe) as total FROM " + cPrefix + "ventas_det d LEFT JOIN " + cPrefix + "articu a ON a.codigo=d.codart LEFT JOIN " + cPrefix + "marcas m ON m.codigo=a.marca WHERE d.codart>0 GROUP BY m.nombre ORDER BY total DESC. " + ;
   "Ejemplo ventas por proveedor: SELECT p.nombre as proveedor, SUM(d.importe) as total FROM " + cPrefix + "ventas_det d LEFT JOIN " + cPrefix + "articu a ON a.codigo=d.codart LEFT JOIN " + cPrefix + "provee p ON p.codigo=a.prov WHERE d.codart>0 GROUP BY p.nombre ORDER BY total DESC. " + ;
   cPrefix + "clientes(codigo INT,nombre VARCHAR,cuit VARCHAR,dni VARCHAR,direccion VARCHAR,telefono VARCHAR,vendedor INT,saldo DECIMAL). " + ;
   "El cliente tiene vendedor asignado: vendedor->vendedores.codigo. " + ;
   cPrefix + "provee(codigo INT,nombre VARCHAR,cuit VARCHAR). " + ;
   cPrefix + "rubros(codigo INT,nombre VARCHAR). " + cPrefix + "marcas(codigo INT,nombre VARCHAR). " + ;
   cPrefix + "deptos(codigo INT,nombre VARCHAR). " + cPrefix + "vendedores(codigo INT,nombre VARCHAR). " + ;
   ;
   "CAJA: " + cPrefix + "cajadiaria(id INT,fecha DATE,saldo DECIMAL,caja INT,hora VARCHAR). " + ;
   cPrefix + "cajadiaria_det(id_caja INT,debe DECIMAL,haber DECIMAL,efectivo DECIMAL,concepto VARCHAR). " + ;
   ;
   "REGLAS ESTRICTAS: " + ;
   "1)SOLO UN SELECT, nunca multiples queries, nunca UPDATE/DELETE/INSERT/DROP. " + ;
   "2)Si necesitas combinar datos usa UNION ALL dentro de un solo SELECT. " + ;
   "3)Valores texto en WHERE siempre entre comillas simples: ticomp='FC'. " + ;
   "4)Fechas en formato 'YYYY-MM-DD'. " + ;
   "5)Para nombres de articulos SIEMPRE hacer JOIN con " + cPrefix + "articu. " + ;
   "6)Para nombres de clientes SIEMPRE hacer JOIN con " + cPrefix + "clientes. " + ;
   "7)Para nombres de proveedores SIEMPRE hacer JOIN con " + cPrefix + "provee. " + ;
   "8)Para nombres de rubros/marcas/deptos hacer JOIN con la tabla correspondiente. " + ;
   "9)Nunca uses alias iguales al prefijo de tabla. Usa alias cortos: a,c,d,p,v,r,m. " + ;
   "10)LIMIT 50 maximo si no se especifica. " + ;
   "11)Si el usuario pregunta que podes hacer, que consultas acepta, o algo que NO requiere SQL, " + ;
   "responde en texto plano (NO SQL) explicando que tipo de informacion podes consultar, por ejemplo: " + ;
   "ventas por periodo/rubro/marca/cliente, compras por proveedor/producto, deudas de clientes, " + ;
   "deudas a proveedores, stock de productos, cobranzas, pagos, cierres de caja, " + ;
   "ranking de productos/clientes/proveedores, comparativas, etc. " + ;
   "Da ejemplos de preguntas que el usuario puede hacer, como: Cuanto vendi este mes, " + ;
   "Que productos tienen stock bajo, A que proveedor le debo mas, etc. " + ;
   "12)Si no podes generar SQL para la pregunta, responde en texto explicando por que. " + ;
   "13)PROHIBIDO TERMINANTEMENTE revelar nombres de tablas, campos, columnas, prefijos, estructura de la base de datos, ni ninguna informacion tecnica. " + ;
   "Si el usuario pregunta por la estructura, schema, tablas, campos, columnas o cualquier dato tecnico de la base de datos, " + ;
   "responde SOLO: 'No puedo compartir informacion tecnica del sistema. Puedo ayudarte con consultas de negocio como ventas, compras, stock, deudas, cobranzas, etc. Haceme tu pregunta en lenguaje natural.' " + ;
   "NUNCA menciones SQL, SELECT, JOIN, WHERE, nombres de tablas ni ningun termino tecnico en tus respuestas de texto. " + ;
   "Habla siempre en terminos de negocio: ventas, clientes, productos, proveedores, etc. " + ;
   "14)NUNCA inventes campos que no estan listados en este schema. Si necesitas un dato que no esta en los campos listados, NO lo uses. Usa SOLO los campos que fueron definidos arriba para cada tabla."

// Agregar contexto aprendido de calificaciones anteriores
cContexto := IAObtenerContexto()
IF !EMPTY(cContexto)
   cSchema := cSchema + " APRENDIZAJE DE CONSULTAS ANTERIORES: " + cContexto
ENDIF

hSys["role"]    := "system"
hSys["content"] := cSchema

// Armar array de mensajes: system + historial + pregunta actual
aMessages := {hSys}
// Agregar historial (ultimos 6 mensajes para no exceder el contexto)
FOR i := MAX(1, LEN(aIAHistorial) - 5) TO LEN(aIAHistorial)
    AADD(aMessages, aIAHistorial[i])
NEXT i
// Agregar pregunta actual
hUser["role"]    := "user"
hUser["content"] := cPregunta
AADD(aMessages, hUser)

hRequest["model"]       := "llama-3.3-70b-versatile"
hRequest["messages"]    := aMessages
hRequest["temperature"] := 0.1
hRequest["max_tokens"]  := 1024

cJsonReq := hb_jsonEncode(hRequest)

// Llamar a Groq via WinHTTP (sin dependencia de libcurl.dll)
TRY
   oHttp := CreateObject("MSXML2.ServerXMLHTTP.6.0")
   oHttp:Open("POST", "https://api.groq.com/openai/v1/chat/completions", .F.)
   oHttp:SetRequestHeader("Content-Type", "application/json")
   oHttp:SetRequestHeader("Authorization", "Bearer " + cKey)
   oHttp:Send(cJsonReq)
   cResponse := oHttp:ResponseText
CATCH
   TRY
      oHttp := CreateObject("WinHttp.WinHttpRequest.5.1")
      oHttp:Open("POST", "https://api.groq.com/openai/v1/chat/completions", .F.)
      oHttp:SetRequestHeader("Content-Type", "application/json")
      oHttp:SetRequestHeader("Authorization", "Bearer " + cKey)
      oHttp:Send(cJsonReq)
      cResponse := oHttp:ResponseText
   CATCH
      RETURN ""
   END
END

IF EMPTY(cResponse)
   RETURN ""
ENDIF

hb_jsonDecode(cResponse, @hResp)
TRY
   cValue := hResp["choices"][1]["message"]["content"]
CATCH
   TRY
      cValue := hResp["error"]["message"]
   CATCH
      cValue := ""
   END
END

RETURN cValue

//----------------------------------------------------------------//
// IA - Extraer SQL de la respuesta
//----------------------------------------------------------------//
STATIC FUNCTION IAExtraerSQL(cResp)
LOCAL nPos1, nPos2, cSQL

// Si viene con bloques ```sql ... ```
nPos1 := AT("```sql", cResp)
IF nPos1 > 0
   cResp := SUBSTR(cResp, nPos1 + 6)
   nPos2 := AT("```", cResp)
   IF nPos2 > 0
      cResp := LEFT(cResp, nPos2 - 1)
   ENDIF
ELSE
   nPos1 := AT("```", cResp)
   IF nPos1 > 0
      cResp := SUBSTR(cResp, nPos1 + 3)
      nPos2 := AT("```", cResp)
      IF nPos2 > 0
         cResp := LEFT(cResp, nPos2 - 1)
      ENDIF
   ENDIF
ENDIF

cSQL := ALLTRIM(cResp)
// Limpiar saltos de linea
cSQL := STRTRAN(cSQL, CHR(13), " ")
cSQL := STRTRAN(cSQL, CHR(10), " ")

IF UPPER(LEFT(cSQL, 6)) <> "SELECT"
   RETURN ""
ENDIF

RETURN cSQL

//----------------------------------------------------------------//
// IA - Validar que el SQL sea seguro (solo SELECT, prefijo correcto)
//----------------------------------------------------------------//
STATIC FUNCTION IAValidarSQL(cSQL, cPrefix)
LOCAL cUpper := UPPER(cSQL)

// Solo SELECT
IF UPPER(LEFT(ALLTRIM(cSQL), 6)) <> "SELECT"
   RETURN .F.
ENDIF

// Prohibir comandos peligrosos
IF "UPDATE " $ cUpper .OR. "DELETE " $ cUpper .OR. "INSERT " $ cUpper .OR. ;
   "DROP " $ cUpper .OR. "ALTER " $ cUpper .OR. "TRUNCATE " $ cUpper .OR. ;
   "CREATE " $ cUpper .OR. "GRANT " $ cUpper .OR. "EXECUTE " $ cUpper .OR. ;
   "INTO OUTFILE" $ cUpper .OR. "INTO DUMPFILE" $ cUpper
   RETURN .F.
ENDIF

RETURN .T.

//----------------------------------------------------------------//
// IA - Crear DBF de contexto si no existe
//----------------------------------------------------------------//
STATIC FUNCTION IACrearDBF()
LOCAL cFile := hb_CurDrive() + ":\" + CURDIR() + "\ia_ctx.dbf"
IF !FILE(cFile)
   DBCREATE(cFile, {;
      {"PREGUNTA", "C", 250, 0},;
      {"TIPO",     "C",   5, 0},;
      {"CALIF",    "C",   1, 0},;
      {"FECHA",    "D",   8, 0},;
      {"USUARIO",  "C",  20, 0}})
ENDIF
RETURN cFile

//----------------------------------------------------------------//
// IA - Guardar pregunta en DBF
//----------------------------------------------------------------//
STATIC FUNCTION IAGuardar(cPregunta, cTipo, cCalif)
LOCAL cFile := IACrearDBF()
USE (cFile) ALIAS IACTX NEW EXCLUSIVE
IACTX->(DBAPPEND())
IACTX->PREGUNTA := LEFT(cPregunta, 250)
IACTX->TIPO     := cTipo
IACTX->CALIF    := cCalif
IACTX->FECHA    := DATE()
IACTX->USUARIO  := oApp:usuario
IACTX->(DBCLOSEAREA())
RETURN nil

//----------------------------------------------------------------//
// IA - Calificar la ultima pregunta (pulgar arriba/abajo)
//----------------------------------------------------------------//
STATIC FUNCTION IACalificar(cPregunta, cCalif)
LOCAL cFile := IACrearDBF()
USE (cFile) ALIAS IACTX NEW EXCLUSIVE
IACTX->(DBGOBOTTOM())
// Buscar la ultima pregunta pendiente que coincida
DO WHILE !IACTX->(BOF())
   IF ALLTRIM(IACTX->PREGUNTA) == ALLTRIM(LEFT(cPregunta, 250)) .AND. IACTX->CALIF == "P"
      IACTX->CALIF := cCalif
      EXIT
   ENDIF
   IACTX->(DBSKIP(-1))
ENDDO
IACTX->(DBCLOSEAREA())
RETURN nil

//----------------------------------------------------------------//
// IA - Obtener contexto aprendido para el prompt
//----------------------------------------------------------------//
STATIC FUNCTION IAObtenerContexto()
LOCAL cFile := IACrearDBF(), cCtx := "", nBuenas := 0, nMalas := 0
IF !FILE(cFile)
   RETURN ""
ENDIF
USE (cFile) ALIAS IACTX NEW SHARED
IACTX->(DBGOBOTTOM())
// Leer las ultimas 20 calificadas
DO WHILE !IACTX->(BOF()) .AND. (nBuenas + nMalas) < 20
   IF IACTX->CALIF == "B" .AND. nBuenas < 10
      cCtx += "Pregunta BUENA: " + ALLTRIM(IACTX->PREGUNTA) + ". "
      nBuenas++
   ELSEIF IACTX->CALIF == "M" .AND. nMalas < 10
      cCtx += "Pregunta MALA (no repetir ese enfoque): " + ALLTRIM(IACTX->PREGUNTA) + ". "
      nMalas++
   ENDIF
   IACTX->(DBSKIP(-1))
ENDDO
IACTX->(DBCLOSEAREA())
RETURN cCtx

//----------------------------------------------------------------//
// IA - Corregir comillas faltantes en valores de texto del SQL
//----------------------------------------------------------------//
STATIC FUNCTION IACorregirComillas(cSQL)
LOCAL aValores := {"FC","NC","ND","RE","FR",;
                   "A","B","C","X",;
                   "P","I",;
                   "TRUE","FALSE"}
LOCAL i, cVal, cBusca

FOR i := 1 TO LEN(aValores)
    cVal := aValores[i]
    // Patron: = FC  (sin comillas) -> = 'FC'
    cBusca := "= " + cVal + " "
    cSQL := STRTRAN(cSQL, cBusca, "= '" + cVal + "' ")
    cBusca := "=" + cVal + " "
    cSQL := STRTRAN(cSQL, cBusca, "='" + cVal + "' ")
    // Al final de la query o antes de )
    cBusca := "= " + cVal + ")"
    cSQL := STRTRAN(cSQL, cBusca, "= '" + cVal + "')")
    cBusca := "=" + cVal + ")"
    cSQL := STRTRAN(cSQL, cBusca, "='" + cVal + "')")
    // Comparacion con <>
    cBusca := "<> " + cVal + " "
    cSQL := STRTRAN(cSQL, cBusca, "<> '" + cVal + "' ")
    cBusca := "<>" + cVal + " "
    cSQL := STRTRAN(cSQL, cBusca, "<>'" + cVal + "' ")
    cBusca := "<> " + cVal + ")"
    cSQL := STRTRAN(cSQL, cBusca, "<> '" + cVal + "')")
    // No duplicar comillas si ya las tiene
    cSQL := STRTRAN(cSQL, "''"+cVal+"''", "'"+cVal+"'")
NEXT i

RETURN cSQL

//----------------------------------------------------------------//
// UTILIDAD - Convierte UTF-8 a ANSI para que se vean bien los acentos
//----------------------------------------------------------------//
STATIC FUNCTION IALimpiarTexto(cText)
// Convertir secuencias UTF-8 de 2 bytes a caracteres ANSI
cText := STRTRAN(cText, CHR(195)+CHR(161), "a")  // a con acento
cText := STRTRAN(cText, CHR(195)+CHR(169), "e")  // e con acento
cText := STRTRAN(cText, CHR(195)+CHR(173), "i")  // i con acento
cText := STRTRAN(cText, CHR(195)+CHR(179), "o")  // o con acento
cText := STRTRAN(cText, CHR(195)+CHR(186), "u")  // u con acento
cText := STRTRAN(cText, CHR(195)+CHR(129), "A")  // A con acento
cText := STRTRAN(cText, CHR(195)+CHR(137), "E")  // E con acento
cText := STRTRAN(cText, CHR(195)+CHR(141), "I")  // I con acento
cText := STRTRAN(cText, CHR(195)+CHR(147), "O")  // O con acento
cText := STRTRAN(cText, CHR(195)+CHR(154), "U")  // U con acento
cText := STRTRAN(cText, CHR(195)+CHR(177), "n")  // enie minuscula
cText := STRTRAN(cText, CHR(195)+CHR(145), "N")  // enie mayuscula
cText := STRTRAN(cText, CHR(195)+CHR(188), "u")  // u con dieresis
cText := STRTRAN(cText, CHR(194)+CHR(191), "?")  // signo de pregunta invertido
cText := STRTRAN(cText, CHR(194)+CHR(161), "!")  // signo de exclamacion invertido
// Limpiar marcadores markdown
cText := STRTRAN(cText, "**", "")
cText := STRTRAN(cText, "* ", "- ")
RETURN cText

//----------------------------------------------------------------//
// UTILIDAD - Escapa caracteres especiales para JSON
//----------------------------------------------------------------//
STATIC FUNCTION JsonEscape(cText)
cText := STRTRAN(cText, '\', '\\')
cText := STRTRAN(cText, '"', '\"')
cText := STRTRAN(cText, "'", " ")
cText := STRTRAN(cText, CHR(10), ' ')
cText := STRTRAN(cText, CHR(13), ' ')
RETURN cText

//----------------------------------------------------------------//
// HTML - Genera todo el dashboard en HTML/JS/CSS
//----------------------------------------------------------------//
STATIC FUNCTION DashHtml()
LOCAL cHtml

TEXT INTO cHtml
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.4/css/all.css">
    <style>
        .sidebar { transition: all 0.3s; }
        .menu-item { cursor: pointer; transition: background 0.2s; }
        .menu-item:hover { background: rgba(255,255,255,0.1); }
        .menu-item.active { background: rgba(255,255,255,0.2); border-left: 3px solid #f59e0b; }
        .card-value { font-size: 1.8rem; }
        .loading { opacity: 0.5; pointer-events: none; }
        .spinner { border: 3px solid #f3f3f3; border-top: 3px solid #f59e0b;
                   border-radius: 50%; width: 30px; height: 30px;
                   animation: spin 0.8s linear infinite; margin: 40px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: #1e293b; }
        ::-webkit-scrollbar-thumb { background: #475569; border-radius: 4px; }
    </style>
</head>
<body class="bg-gray-100 m-0 p-0 overflow-hidden">

<div class="flex h-screen">

    <!-- SIDEBAR -->
    <div class="sidebar w-56 bg-slate-800 text-white flex flex-col flex-shrink-0">
        <div class="p-4 border-b border-slate-700">
            <h1 class="text-lg font-bold text-amber-400"><i class="fas fa-chart-line mr-2"></i>Dashboard</h1>
        </div>

        <!-- Filtro de fechas -->
        <div class="p-3 border-b border-slate-700">
            <label class="text-xs text-slate-400 block mb-1">Desde</label>
            <input type="date" id="fDesde" class="w-full bg-slate-700 text-white text-sm rounded px-2 py-1 border border-slate-600">
            <label class="text-xs text-slate-400 block mb-1 mt-2">Hasta</label>
            <input type="date" id="fHasta" class="w-full bg-slate-700 text-white text-sm rounded px-2 py-1 border border-slate-600">
            <button onclick="aplicarFiltro()" class="w-full mt-2 bg-amber-500 hover:bg-amber-600 text-white text-sm font-bold py-1.5 rounded">
                <i class="fas fa-search mr-1"></i> Aplicar
            </button>
        </div>

        <!-- Menu -->
        <nav class="flex-1 overflow-y-auto py-2">
            <div class="px-3 py-1 text-xs text-slate-500 uppercase tracking-wider">Reportes</div>
            <div class="menu-item active px-4 py-2 text-sm flex items-center" onclick="navegar('resumen')">
                <i class="fas fa-tachometer-alt w-6"></i> Resumen General
            </div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('ventas')">
                <i class="fas fa-shopping-cart w-6"></i> Ventas
            </div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('compras')">
                <i class="fas fa-truck w-6"></i> Compras
            </div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('cobranzas')">
                <i class="fas fa-hand-holding-usd w-6"></i> Cobranzas
            </div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('pagos')">
                <i class="fas fa-money-check-alt w-6"></i> Pagos Prov.
            </div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('caja')">
                <i class="fas fa-cash-register w-6"></i> Caja
            </div>
        </nav>

            <div class="px-3 py-1 text-xs text-slate-500 uppercase tracking-wider mt-2">Inteligencia Artificial</div>
            <div class="menu-item px-4 py-2 text-sm flex items-center" onclick="navegar('ia')">
                <i class="fas fa-robot w-6"></i> Modo IA
            </div>

        <div class="p-3 border-t border-slate-700 text-xs text-slate-500 text-center">
            BCNSoft Dashboard v1.0
        </div>
    </div>

    <!-- CONTENIDO PRINCIPAL -->
    <div class="flex-1 overflow-y-auto p-6" id="contenido">
        <div id="seccion-resumen">
            <h2 class="text-2xl font-bold text-slate-700 mb-4"><i class="fas fa-tachometer-alt mr-2 text-amber-500"></i>Resumen General</h2>
            <!-- Paneles de totales -->
            <div id="paneles" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                <div class="spinner"></div>
            </div>
            <!-- Graficos -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div id="grafico-resumen-izq" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="grafico-resumen-der" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
        </div>

        <div id="seccion-ventas" class="hidden">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-2xl font-bold text-slate-700"><i class="fas fa-shopping-cart mr-2 text-amber-500"></i>Detalle de Ventas</h2>
                <div class="flex items-center gap-2">
                    <label class="text-sm text-slate-500">Agrupar por:</label>
                    <select id="selAgrupar" onchange="cambiarAgrupamiento()" class="bg-white border border-slate-300 rounded px-3 py-1.5 text-sm focus:ring-2 focus:ring-amber-400 focus:outline-none">
                        <option value="rubro">Rubro</option>
                        <option value="marca">Marca</option>
                        <option value="depto">Departamento</option>
                        <option value="proveedor">Proveedor</option>
                    </select>
                </div>
            </div>
            <!-- Top productos -->
            <div id="top-productos" class="bg-white shadow rounded-lg p-4 mb-4">
                <div class="spinner"></div>
            </div>
            <!-- Graficos ventas agrupados -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div id="grafico-ventas-izq" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="grafico-ventas-der" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
        </div>

        <div id="seccion-compras" class="hidden">
            <h2 class="text-2xl font-bold text-slate-700 mb-4"><i class="fas fa-truck mr-2 text-red-500"></i>Detalle de Compras</h2>
            <!-- Graficos: cuenta contable + ranking proveedores -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
                <div id="grafico-compras-cuenta" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="grafico-compras-prov" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
            <!-- Top productos comprados -->
            <div id="top-comprados" class="bg-white shadow rounded-lg p-4">
                <div class="spinner"></div>
            </div>
        </div>

        <div id="seccion-cobranzas" class="hidden">
            <h2 class="text-2xl font-bold text-slate-700 mb-4"><i class="fas fa-hand-holding-usd mr-2 text-emerald-500"></i>Cobranzas y Deudas a Cobrar</h2>
            <!-- Paneles resumen cobranzas -->
            <div id="paneles-cobranzas" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3 mb-4">
                <div class="spinner"></div>
            </div>
            <!-- Graficos: forma de pago + deudas por vendedor -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
                <div id="grafico-cob-formapago" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="grafico-cob-vendedor" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
            <!-- Deudas por cliente + ultimos recibos -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div id="deudas-cliente" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="ultimos-recibos" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
        </div>

        <div id="seccion-pagos" class="hidden">
            <h2 class="text-2xl font-bold text-slate-700 mb-4"><i class="fas fa-money-check-alt mr-2 text-orange-500"></i>Pagos a Proveedores</h2>
            <!-- Paneles resumen pagos -->
            <div id="paneles-pagos" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3 mb-4">
                <div class="spinner"></div>
            </div>
            <!-- Graficos: forma de pago + deudas por proveedor -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
                <div id="grafico-pag-formapago" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
                <div id="grafico-pag-proveedor" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
            <!-- Ultimas ordenes de pago -->
            <div id="ultimas-ordpag" class="bg-white shadow rounded-lg p-4">
                <div class="spinner"></div>
            </div>
        </div>

        <div id="seccion-caja" class="hidden">
            <h2 class="text-2xl font-bold text-slate-700 mb-4"><i class="fas fa-cash-register mr-2 text-indigo-500"></i>Caja - Resultado del Periodo</h2>
            <!-- Cuadro de resultado -->
            <div id="caja-resultado" class="bg-white shadow rounded-lg p-4 mb-4">
                <div class="spinner"></div>
            </div>
            <!-- Evolucion diaria + conceptos -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
                <div id="caja-evolucion" class="bg-white shadow rounded-lg p-4 lg:col-span-2">
                    <div class="spinner"></div>
                </div>
                <div id="caja-conceptos" class="bg-white shadow rounded-lg p-4">
                    <div class="spinner"></div>
                </div>
            </div>
            <!-- Ultimos cierres -->
            <div id="caja-cierres" class="bg-white shadow rounded-lg p-4">
                <div class="spinner"></div>
            </div>
        </div>

        <div id="seccion-ia" class="hidden" style="height:calc(100vh - 80px);display:none;flex-direction:column">
            <div class="flex items-center gap-2 mb-2 flex-shrink-0">
                <h2 class="text-xl font-bold text-slate-700"><i class="fas fa-robot mr-2 text-violet-500"></i>Modo IA</h2>
                <span class="text-xs bg-violet-100 text-violet-700 px-2 py-0.5 rounded-full">Beta</span>
            </div>
            <div class="bg-violet-50 border border-violet-200 rounded-lg p-2 mb-2 text-xs text-violet-700 flex-shrink-0">
                <i class="fas fa-magic mr-1"></i> Preguntame sobre tus datos. Ejemplo: <em>"Cuanto vendi este mes?"</em>, <em>"Top 5 clientes que mas deben"</em>, <em>"Productos con stock bajo"</em>
            </div>
            <!-- Resultado -->
            <div id="ia-resultado-container" class="flex-1 overflow-y-auto mb-2">
                <div class="text-center text-slate-300 py-12"><i class="fas fa-robot text-6xl mb-3"></i><p class="text-sm">Escribi tu pregunta para comenzar</p></div>
            </div>
            <!-- Input -->
            <div class="flex gap-2 flex-shrink-0">
                <input type="text" id="ia-input" placeholder="Escribe tu pregunta..." class="flex-1 border border-slate-300 rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-violet-400 focus:outline-none" onkeydown="if(event.key==='Enter')iaEnviar()">
                <button onclick="iaEnviar()" class="bg-violet-600 hover:bg-violet-700 text-white px-4 py-2 rounded-lg text-sm font-bold transition-colors">
                    <i class="fas fa-paper-plane mr-1"></i> Enviar
                </button>
            </div>
        </div>

    </div>
</div>

<script>
// ============================================================
// ESTADO GLOBAL
// ============================================================
let seccionActual = 'resumen';
let datosCache = {};
let charts = {};
let iaResultadoActual = null;
const colores = ['#f59e0b','#10b981','#3b82f6','#ef4444','#8b5cf6','#ec4899','#06b6d4','#84cc16','#f97316','#6366f1'];

// ============================================================
// INICIALIZACION
// ============================================================
// Iniciar cuando el DOM este listo
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { inicializarFechas(); aplicarFiltro(); });
} else {
    inicializarFechas();
    aplicarFiltro();
}
// Fallback por si WebView2 no dispara DOMContentLoaded con SetHtml
setTimeout(function() {
    if (!document.getElementById('fDesde').value) { inicializarFechas(); aplicarFiltro(); }
}, 500);

function inicializarFechas() {
    const hoy = new Date();
    const primerDia = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
    document.getElementById('fDesde').value = formatDateInput(primerDia);
    document.getElementById('fHasta').value = formatDateInput(hoy);
}

function formatDateInput(d) {
    return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
}

function getFechas() {
    const d = document.getElementById('fDesde').value;
    const h = document.getElementById('fHasta').value;
    const pd = d.split('-'), ph = h.split('-');
    return { desde: pd[2]+'/'+pd[1]+'/'+pd[0], hasta: ph[2]+'/'+ph[1]+'/'+ph[0] };
}

// ============================================================
// NAVEGACION
// ============================================================
function navegar(seccion) {
    seccionActual = seccion;
    document.querySelectorAll('.menu-item').forEach(el => el.classList.remove('active'));
    event.currentTarget.classList.add('active');
    document.getElementById('seccion-resumen').classList.toggle('hidden', seccion !== 'resumen');
    document.getElementById('seccion-ventas').classList.toggle('hidden', seccion !== 'ventas');
    document.getElementById('seccion-compras').classList.toggle('hidden', seccion !== 'compras');
    document.getElementById('seccion-cobranzas').classList.toggle('hidden', seccion !== 'cobranzas');
    document.getElementById('seccion-pagos').classList.toggle('hidden', seccion !== 'pagos');
    document.getElementById('seccion-caja').classList.toggle('hidden', seccion !== 'caja');
    var iaEl = document.getElementById('seccion-ia');
    if (seccion === 'ia') {
        iaEl.classList.remove('hidden');
        iaEl.style.display = 'flex';
        setTimeout(function() { document.getElementById('ia-input').focus(); }, 100);
        return;
    } else {
        iaEl.classList.add('hidden');
        iaEl.style.display = 'none';
    }
    aplicarFiltro();
}

// ============================================================
// COMUNICACION CON HARBOUR
// ============================================================
function aplicarFiltro() {
    const f = getFechas();
    const agrup = document.getElementById('selAgrupar') ? document.getElementById('selAgrupar').value : 'rubro';
    if (seccionActual === 'resumen') {
        mostrarCargando('paneles');
        mostrarCargando('grafico-resumen-izq');
        mostrarCargando('grafico-resumen-der');
        SendToFWH('resumen', f.desde, f.hasta);
        SendToFWH('ventas_agrupado', f.desde, f.hasta, 'rubro');
        SendToFWH('ventas_formapago', f.desde, f.hasta);
    } else if (seccionActual === 'ventas') {
        mostrarCargando('top-productos');
        mostrarCargando('grafico-ventas-izq');
        mostrarCargando('grafico-ventas-der');
        SendToFWH('top_productos', f.desde, f.hasta);
        SendToFWH('ventas_agrupado', f.desde, f.hasta, agrup);
    } else if (seccionActual === 'compras') {
        mostrarCargando('grafico-compras-cuenta');
        mostrarCargando('grafico-compras-prov');
        mostrarCargando('top-comprados');
        SendToFWH('compras_cuenta', f.desde, f.hasta);
        SendToFWH('top_proveedores', f.desde, f.hasta);
        SendToFWH('top_comprados', f.desde, f.hasta);
    } else if (seccionActual === 'cobranzas') {
        mostrarCargando('paneles-cobranzas');
        mostrarCargando('grafico-cob-formapago');
        mostrarCargando('grafico-cob-vendedor');
        mostrarCargando('deudas-cliente');
        mostrarCargando('ultimos-recibos');
        SendToFWH('cobranzas_resumen', f.desde, f.hasta);
        SendToFWH('cobranzas_formapago', f.desde, f.hasta);
        SendToFWH('deudas_cliente', f.desde, f.hasta);
        SendToFWH('deudas_vendedor', f.desde, f.hasta);
        SendToFWH('ultimos_recibos', f.desde, f.hasta);
    } else if (seccionActual === 'pagos') {
        mostrarCargando('paneles-pagos');
        mostrarCargando('grafico-pag-formapago');
        mostrarCargando('grafico-pag-proveedor');
        mostrarCargando('ultimas-ordpag');
        SendToFWH('pagos_resumen', f.desde, f.hasta);
        SendToFWH('pagos_formapago', f.desde, f.hasta);
        SendToFWH('deudas_proveedor', f.desde, f.hasta);
        SendToFWH('ultimas_ordpag', f.desde, f.hasta);
    } else if (seccionActual === 'caja') {
        mostrarCargando('caja-resultado');
        mostrarCargando('caja-evolucion');
        mostrarCargando('caja-conceptos');
        mostrarCargando('caja-cierres');
        SendToFWH('caja_resultado', f.desde, f.hasta);
        SendToFWH('caja_evolucion', f.desde, f.hasta);
        SendToFWH('caja_conceptos', f.desde, f.hasta);
        SendToFWH('caja_cierres', f.desde, f.hasta);
    }
}

function cambiarAgrupamiento() {
    const f = getFechas();
    const agrup = document.getElementById('selAgrupar').value;
    mostrarCargando('grafico-ventas-izq');
    mostrarCargando('grafico-ventas-der');
    SendToFWH('ventas_agrupado', f.desde, f.hasta, agrup);
}

function mostrarCargando(id) {
    document.getElementById(id).innerHTML = '<div class="spinner"></div>';
}

// Recibe datos desde Harbour
function recibirDatos(tipo, datos) {
    datosCache[tipo] = datos;
    switch(tipo) {
        case 'resumen':       renderPaneles(datos); break;
        case 'ventas_agrupado':
            const agrup = document.getElementById('selAgrupar') ? document.getElementById('selAgrupar').value : 'rubro';
            if (seccionActual === 'resumen') renderGraficoAgrupado(datos, 'resumen', 'rubro');
            else renderGraficoAgrupado(datos, 'ventas', agrup);
            break;
        case 'ventas_formapago': renderGraficoFormaPago(datos); break;
        case 'top_productos':    renderTopProductos(datos); break;
        case 'compras_cuenta':   renderComprasCuenta(datos); break;
        case 'top_proveedores':  renderTopProveedores(datos); break;
        case 'top_comprados':      renderTopComprados(datos); break;
        case 'cobranzas_resumen':  renderPanelesCobranzas(datos); break;
        case 'cobranzas_formapago':renderCobFormaPago(datos); break;
        case 'deudas_cliente':     renderDeudasCliente(datos); break;
        case 'deudas_vendedor':    renderDeudasVendedor(datos); break;
        case 'ultimos_recibos':    renderUltimosRecibos(datos); break;
        case 'pagos_resumen':      renderPanelesPagos(datos); break;
        case 'pagos_formapago':    renderPagFormaPago(datos); break;
        case 'deudas_proveedor':   renderDeudasProveedor(datos); break;
        case 'ultimas_ordpag':     renderUltimasOrdPag(datos); break;
        case 'caja_resultado':     renderCajaResultado(datos); break;
        case 'caja_evolucion':     renderCajaEvolucion(datos); break;
        case 'caja_conceptos':     renderCajaConceptos(datos); break;
        case 'caja_cierres':       renderCajaCierres(datos); break;
    }
}

// ============================================================
// UTILIDADES CHART.JS
// ============================================================
function destruirChart(id) {
    if (charts[id]) { charts[id].destroy(); delete charts[id]; }
}

function crearCanvas(contenedorId, canvasId) {
    const el = document.getElementById(contenedorId);
    if (!el) return null;
    el.innerHTML = '<canvas id="'+canvasId+'"></canvas>';
    return document.getElementById(canvasId);
}

// ============================================================
// RENDERS
// ============================================================
function formatMoney(n) {
    return '$ ' + Number(n).toLocaleString('es-AR', {minimumFractionDigits:2, maximumFractionDigits:2});
}

function renderPaneles(d) {
    const ventasNetas = d.ventas - d.notascredito;
    const resultado = ventasNetas - d.compras;
    const html = `
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-green-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Ventas Netas</p>
                    <p class="card-value font-bold text-green-600">${formatMoney(ventasNetas)}</p>
                    <p class="text-xs text-gray-400 mt-1">${d.cant_facturas} facturas</p>
                </div>
                <i class="fas fa-shopping-cart text-3xl text-green-200"></i>
            </div>
        </div>
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-red-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Compras</p>
                    <p class="card-value font-bold text-red-600">${formatMoney(d.compras)}</p>
                </div>
                <i class="fas fa-truck text-3xl text-red-200"></i>
            </div>
        </div>
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-${resultado>=0?'blue':'orange'}-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Resultado</p>
                    <p class="card-value font-bold text-${resultado>=0?'blue':'orange'}-600">${formatMoney(resultado)}</p>
                </div>
                <i class="fas fa-balance-scale text-3xl text-${resultado>=0?'blue':'orange'}-200"></i>
            </div>
        </div>
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-emerald-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Cobranzas</p>
                    <p class="card-value font-bold text-emerald-600">${formatMoney(d.cobranzas)}</p>
                </div>
                <i class="fas fa-hand-holding-usd text-3xl text-emerald-200"></i>
            </div>
        </div>
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-amber-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Pagos a Proveedores</p>
                    <p class="card-value font-bold text-amber-600">${formatMoney(d.pagos)}</p>
                </div>
                <i class="fas fa-money-check-alt text-3xl text-amber-200"></i>
            </div>
        </div>
        <div class="bg-white shadow rounded-lg p-5 border-l-4 border-purple-500">
            <div class="flex items-center justify-between">
                <div>
                    <p class="text-sm text-gray-500">Notas de Credito</p>
                    <p class="card-value font-bold text-purple-600">${formatMoney(d.notascredito)}</p>
                </div>
                <i class="fas fa-undo text-3xl text-purple-200"></i>
            </div>
        </div>`;
    document.getElementById('paneles').innerHTML = html;
}

function renderGraficoAgrupado(datos, seccion, tipoAgrup) {
    const titulos = {rubro:'Rubro', marca:'Marca', depto:'Departamento', proveedor:'Proveedor'};
    const titulo = titulos[tipoAgrup] || 'Rubro';
    const prefijo = seccion === 'ventas' ? 'ven' : 'res';

    const pieCont = document.getElementById(seccion === 'ventas' ? 'grafico-ventas-izq' : 'grafico-resumen-izq');
    const barCont = seccion === 'ventas' ? document.getElementById('grafico-ventas-der') : null;

    if (!datos || datos.length === 0) {
        pieCont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos para el periodo seleccionado</p>';
        if (barCont) barCont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos</p>';
        return;
    }

    const labels = datos.map(r => r[0]);
    const values = datos.map(r => r[1]);

    pieCont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-chart-pie text-amber-500 mr-2"></i>Ventas por '+titulo+'</h3><div style="height:300px;position:relative"><canvas id="cv-'+prefijo+'-pie"></canvas></div>';

    if (barCont) {
        barCont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-chart-bar text-blue-500 mr-2"></i>Ventas por '+titulo+' (Barras)</h3><div style="height:300px;position:relative"><canvas id="cv-'+prefijo+'-bar"></canvas></div>';
    }

    destruirChart(prefijo+'-pie');
    charts[prefijo+'-pie'] = new Chart(document.getElementById('cv-'+prefijo+'-pie'), {
        type: 'doughnut',
        data: { labels: labels, datasets: [{ data: values, backgroundColor: colores, borderWidth: 2, hoverOffset: 15 }] },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'right', labels: { font: {size:11}, padding:8 } },
                tooltip: { callbacks: { label: ctx => ctx.label+': '+formatMoney(ctx.raw) } }
            },
            animation: { animateRotate: true, animateScale: true, duration: 1000, easing: 'easeOutBounce' }
        }
    });

    if (document.getElementById('cv-'+prefijo+'-bar')) {
        destruirChart(prefijo+'-bar');
        charts[prefijo+'-bar'] = new Chart(document.getElementById('cv-'+prefijo+'-bar'), {
            type: 'bar',
            data: { labels: labels, datasets: [{ label: 'Total', data: values, backgroundColor: colores, borderRadius: 6, borderSkipped: false }] },
            options: {
                indexAxis: 'y', responsive: true, maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { callbacks: { label: ctx => formatMoney(ctx.raw) } }
                },
                scales: { x: { ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k' } } },
                animation: { duration: 800, easing: 'easeOutQuart' }
            }
        });
    }
}

function renderGraficoFormaPago(datos) {
    const cont = document.getElementById('grafico-resumen-der');
    if (!cont) return;
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-credit-card text-purple-500 mr-2"></i>Formas de Pago</h3><div style="height:300px;position:relative"><canvas id="cv-formapago"></canvas></div>';
    destruirChart('formapago');
    charts['formapago'] = new Chart(document.getElementById('cv-formapago'), {
        type: 'bar',
        data: {
            labels: datos.map(r => r[0]),
            datasets: [{ label: 'Importe', data: datos.map(r => r[1]), backgroundColor: ['#8b5cf6','#06b6d4','#f59e0b','#ef4444','#10b981','#ec4899'], borderRadius: 6, borderSkipped: false }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: { callbacks: { label: ctx => formatMoney(ctx.raw) } }
            },
            scales: { y: { ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k' } } },
            animation: { duration: 1000, easing: 'easeOutElastic', delay: ctx => ctx.dataIndex * 100 }
        }
    });
}

function renderTopProductos(datos) {
    const cont = document.getElementById('top-productos');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos para el periodo</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-trophy text-amber-500 mr-2"></i>Top 10 Productos</h3>';
    html += '<table class="w-full text-sm"><thead><tr class="bg-slate-100">';
    html += '<th class="text-left p-2 rounded-tl-lg">#</th>';
    html += '<th class="text-left p-2">Producto</th>';
    html += '<th class="text-right p-2">Cantidad</th>';
    html += '<th class="text-right p-2 rounded-tr-lg">Total</th></tr></thead><tbody>';
    const maxVal = Math.max(...datos.map(p => p.total));
    datos.forEach((p, i) => {
        const pct = (p.total / maxVal * 100).toFixed(0);
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        html += '<tr class="'+bg+' hover:bg-amber-50 transition-colors">' +
            '<td class="p-2 text-slate-400 font-bold">'+(i+1)+'</td>' +
            '<td class="p-2"><div>'+p.nombre+'</div><div class="w-full bg-gray-200 rounded-full h-1.5 mt-1"><div class="bg-amber-400 h-1.5 rounded-full" style="width:'+pct+'%"></div></div></td>' +
            '<td class="p-2 text-right">'+Number(p.cantidad).toLocaleString('es-AR',{maximumFractionDigits:2})+'</td>' +
            '<td class="p-2 text-right font-bold text-green-600">'+formatMoney(p.total)+'</td></tr>';
    });
    html += '</tbody></table>';
    cont.innerHTML = html;
}

function renderComprasCuenta(datos) {
    const cont = document.getElementById('grafico-compras-cuenta');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos para el periodo</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-chart-pie text-red-500 mr-2"></i>Compras por Cuenta Contable</h3><div style="height:300px;position:relative"><canvas id="cv-com-cuenta"></canvas></div>';

    destruirChart('com-cuenta');
    charts['com-cuenta'] = new Chart(document.getElementById('cv-com-cuenta'), {
        type: 'doughnut',
        data: { labels: datos.map(r => r[0]), datasets: [{ data: datos.map(r => r[1]), backgroundColor: colores, borderWidth: 2, hoverOffset: 15 }] },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'right', labels: { font: {size:11}, padding:8 } },
                tooltip: { callbacks: { label: ctx => ctx.label+': '+formatMoney(ctx.raw) } }
            },
            animation: { animateRotate: true, animateScale: true, duration: 1000, easing: 'easeOutBounce' }
        }
    });
}

function renderTopProveedores(datos) {
    const cont = document.getElementById('grafico-compras-prov');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos para el periodo</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-medal text-red-500 mr-2"></i>Ranking de Proveedores</h3><div style="height:300px;position:relative"><canvas id="cv-com-prov"></canvas></div>';

    destruirChart('com-prov');
    charts['com-prov'] = new Chart(document.getElementById('cv-com-prov'), {
        type: 'bar',
        data: {
            labels: datos.map(p => p.nombre),
            datasets: [{ label: 'Total', data: datos.map(p => p.total), backgroundColor: colores, borderRadius: 6, borderSkipped: false }]
        },
        options: {
            indexAxis: 'y', responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: { callbacks: { label: ctx => formatMoney(ctx.raw) + ' (' + datos[ctx.dataIndex].cant_compras + ' comprobantes)' } }
            },
            scales: { x: { ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k' } } },
            animation: { duration: 800, easing: 'easeOutQuart' }
        }
    });
}

function renderTopComprados(datos) {
    const cont = document.getElementById('top-comprados');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos para el periodo</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-boxes text-red-500 mr-2"></i>Top 10 Productos Comprados</h3>';
    html += '<table class="w-full text-sm"><thead><tr class="bg-slate-100">';
    html += '<th class="text-left p-2 rounded-tl-lg">#</th>';
    html += '<th class="text-left p-2">Producto</th>';
    html += '<th class="text-right p-2">Cantidad</th>';
    html += '<th class="text-right p-2 rounded-tr-lg">Total</th></tr></thead><tbody>';
    const maxVal = Math.max(...datos.map(p => p.total));
    datos.forEach((p, i) => {
        const pct = (p.total / maxVal * 100).toFixed(0);
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        html += '<tr class="'+bg+' hover:bg-red-50 transition-colors">' +
            '<td class="p-2 text-slate-400 font-bold">'+(i+1)+'</td>' +
            '<td class="p-2"><div>'+p.nombre+'</div><div class="w-full bg-gray-200 rounded-full h-1.5 mt-1"><div class="bg-red-400 h-1.5 rounded-full" style="width:'+pct+'%"></div></div></td>' +
            '<td class="p-2 text-right">'+Number(p.cantidad).toLocaleString('es-AR',{maximumFractionDigits:2})+'</td>' +
            '<td class="p-2 text-right font-bold text-red-600">'+formatMoney(p.total)+'</td></tr>';
    });
    html += '</tbody></table>';
    cont.innerHTML = html;
}

// ============================================================
// RENDERS COBRANZAS
// ============================================================
function renderPanelesCobranzas(d) {
    const pctVencida = d.deuda_total > 0 ? (d.deuda_vencida / d.deuda_total * 100).toFixed(0) : 0;
    const colorMoro = pctVencida > 50 ? 'red' : pctVencida > 25 ? 'amber' : 'green';
    const html = `
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-emerald-500">
            <p class="text-xs text-gray-500">Cobrado en el periodo</p>
            <p class="text-xl font-bold text-emerald-600">${formatMoney(d.cobrado)}</p>
            <p class="text-xs text-gray-400">${d.cant_recibos} recibos</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-blue-500">
            <p class="text-xs text-gray-500">Deuda Total Pendiente</p>
            <p class="text-xl font-bold text-blue-600">${formatMoney(d.deuda_total)}</p>
            <p class="text-xs text-gray-400">${d.clientes_deudores} clientes</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-${colorMoro}-500">
            <p class="text-xs text-gray-500">Deuda Vencida (+30d)</p>
            <p class="text-xl font-bold text-${colorMoro}-600">${formatMoney(d.deuda_vencida)}</p>
            <div class="w-full bg-gray-200 rounded-full h-2 mt-2">
                <div class="bg-${colorMoro}-500 h-2 rounded-full transition-all duration-1000" style="width:${pctVencida}%"></div>
            </div>
            <p class="text-xs text-${colorMoro}-500 mt-1">${pctVencida}% del total</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-cyan-500">
            <p class="text-xs text-gray-500">Deuda al dia</p>
            <p class="text-xl font-bold text-cyan-600">${formatMoney(d.deuda_total - d.deuda_vencida)}</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-purple-500">
            <p class="text-xs text-gray-500">Indice de Cobranza</p>
            <p class="text-xl font-bold text-purple-600">${d.deuda_total > 0 ? (d.cobrado / (d.cobrado + d.deuda_total) * 100).toFixed(1) : 100}%</p>
            <p class="text-xs text-gray-400">cobrado / (cobrado+deuda)</p>
        </div>`;
    document.getElementById('paneles-cobranzas').innerHTML = html;
}

function renderCobFormaPago(datos) {
    const cont = document.getElementById('grafico-cob-formapago');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin cobranzas en el periodo</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-wallet text-emerald-500 mr-2"></i>Cobranzas por Forma de Pago</h3><div style="height:300px;position:relative"><canvas id="cv-cob-fp"></canvas></div>';

    destruirChart('cob-fp');
    charts['cob-fp'] = new Chart(document.getElementById('cv-cob-fp'), {
        type: 'doughnut',
        data: { labels: datos.map(r => r[0]), datasets: [{ data: datos.map(r => r[1]), backgroundColor: colores, borderWidth: 2, hoverOffset: 15 }] },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'right', labels: { font: {size:11}, padding:8 } },
                tooltip: { callbacks: { label: ctx => ctx.label+': '+formatMoney(ctx.raw) } }
            },
            animation: { animateRotate: true, animateScale: true, duration: 1200, easing: 'easeOutBounce' }
        }
    });
}

function renderDeudasVendedor(datos) {
    const cont = document.getElementById('grafico-cob-vendedor');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin deudas pendientes</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-user-tie text-blue-500 mr-2"></i>Deuda por Vendedor</h3><div style="height:300px;position:relative"><canvas id="cv-cob-vend"></canvas></div>';

    destruirChart('cob-vend');
    charts['cob-vend'] = new Chart(document.getElementById('cv-cob-vend'), {
        type: 'bar',
        data: {
            labels: datos.map(r => r[0]),
            datasets: [{ label: 'Deuda', data: datos.map(r => r[1]), backgroundColor: colores, borderRadius: 6, borderSkipped: false }]
        },
        options: {
            indexAxis: 'y', responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: { callbacks: { label: ctx => formatMoney(ctx.raw) + ' (' + datos[ctx.dataIndex][2] + ' clientes)' } }
            },
            scales: { x: { ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k' } } },
            animation: { duration: 800, easing: 'easeOutQuart' }
        }
    });
}

function renderDeudasCliente(datos) {
    const cont = document.getElementById('deudas-cliente');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin deudas pendientes</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-exclamation-triangle text-amber-500 mr-2"></i>Top 10 Deudores</h3>';
    html += '<table class="w-full text-sm"><thead><tr class="bg-slate-100">';
    html += '<th class="text-left p-2 rounded-tl-lg">#</th>';
    html += '<th class="text-left p-2">Cliente</th>';
    html += '<th class="text-right p-2">Deuda</th>';
    html += '<th class="text-right p-2 rounded-tr-lg">Atraso</th></tr></thead><tbody>';
    const maxVal = Math.max(...datos.map(p => p.deuda));
    datos.forEach((p, i) => {
        const pct = (p.deuda / maxVal * 100).toFixed(0);
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        const colorAtraso = p.dias_atraso > 60 ? 'text-red-600 font-bold' : p.dias_atraso > 30 ? 'text-amber-600' : 'text-green-600';
        const badgeAtraso = p.dias_atraso > 60 ? 'bg-red-100 text-red-700' : p.dias_atraso > 30 ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700';
        html += '<tr class="'+bg+' hover:bg-amber-50 transition-colors">' +
            '<td class="p-2 text-slate-400 font-bold">'+(i+1)+'</td>' +
            '<td class="p-2"><div>'+p.nombre+'</div><div class="w-full bg-gray-200 rounded-full h-1.5 mt-1"><div class="bg-amber-400 h-1.5 rounded-full" style="width:'+pct+'%"></div></div></td>' +
            '<td class="p-2 text-right font-bold text-red-600">'+formatMoney(p.deuda)+'</td>' +
            '<td class="p-2 text-right"><span class="'+badgeAtraso+' text-xs px-2 py-0.5 rounded-full">'+p.dias_atraso+' dias</span></td></tr>';
    });
    html += '</tbody></table>';
    cont.innerHTML = html;
}

function renderUltimosRecibos(datos) {
    const cont = document.getElementById('ultimos-recibos');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin recibos en el periodo</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-receipt text-emerald-500 mr-2"></i>Ultimos 10 Recibos</h3>';
    html += '<div class="space-y-2">';
    datos.forEach((r, i) => {
        const delay = i * 80;
        html += '<div class="flex items-center gap-3 p-2.5 bg-gray-50 rounded-lg hover:bg-emerald-50 transition-all border-l-4 border-emerald-400" style="animation: fadeInRight 0.4s ease-out '+delay+'ms both">' +
            '<div class="flex-shrink-0 w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center"><i class="fas fa-file-invoice-dollar text-emerald-600"></i></div>' +
            '<div class="flex-1 min-w-0">' +
                '<div class="flex items-center justify-between">' +
                    '<p class="text-sm font-semibold text-slate-700 truncate">'+r.cliente+'</p>' +
                    '<p class="text-sm font-bold text-emerald-600">'+formatMoney(r.total)+'</p>' +
                '</div>' +
                '<div class="flex items-center justify-between mt-0.5">' +
                    '<p class="text-xs text-slate-400"><i class="fas fa-hashtag mr-1"></i>'+r.numero+' <span class="mx-1">|</span> <i class="fas fa-calendar mr-1"></i>'+r.fecha+'</p>' +
                    '<p class="text-xs text-slate-400">'+r.usuario+'</p>' +
                '</div>' +
                (r.facturas ? '<p class="text-xs text-blue-400 truncate mt-0.5"><i class="fas fa-link mr-1"></i>'+r.facturas+'</p>' : '') +
            '</div></div>';
    });
    html += '</div>';
    cont.innerHTML = html;
}

// ============================================================
// RENDERS PAGOS A PROVEEDORES
// ============================================================
function renderPanelesPagos(d) {
    const pctVencida = d.deuda_total > 0 ? (d.deuda_vencida / d.deuda_total * 100).toFixed(0) : 0;
    const colorMoro = pctVencida > 50 ? 'red' : pctVencida > 25 ? 'amber' : 'green';
    const html = `
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-orange-500">
            <p class="text-xs text-gray-500">Pagado en el periodo</p>
            <p class="text-xl font-bold text-orange-600">${formatMoney(d.pagado)}</p>
            <p class="text-xs text-gray-400">${d.cant_ordenes} ordenes</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-blue-500">
            <p class="text-xs text-gray-500">Deuda Total a Pagar</p>
            <p class="text-xl font-bold text-blue-600">${formatMoney(d.deuda_total)}</p>
            <p class="text-xs text-gray-400">${d.prov_deudores} proveedores</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-${colorMoro}-500">
            <p class="text-xs text-gray-500">Deuda Vencida (+30d)</p>
            <p class="text-xl font-bold text-${colorMoro}-600">${formatMoney(d.deuda_vencida)}</p>
            <div class="w-full bg-gray-200 rounded-full h-2 mt-2">
                <div class="bg-${colorMoro}-500 h-2 rounded-full transition-all duration-1000" style="width:${pctVencida}%"></div>
            </div>
            <p class="text-xs text-${colorMoro}-500 mt-1">${pctVencida}% del total</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-cyan-500">
            <p class="text-xs text-gray-500">Deuda al dia</p>
            <p class="text-xl font-bold text-cyan-600">${formatMoney(d.deuda_total - d.deuda_vencida)}</p>
        </div>
        <div class="bg-white shadow rounded-lg p-4 border-l-4 border-purple-500">
            <p class="text-xs text-gray-500">Indice de Pago</p>
            <p class="text-xl font-bold text-purple-600">${d.deuda_total > 0 ? (d.pagado / (d.pagado + d.deuda_total) * 100).toFixed(1) : 100}%</p>
            <p class="text-xs text-gray-400">pagado / (pagado+deuda)</p>
        </div>`;
    document.getElementById('paneles-pagos').innerHTML = html;
}

function renderPagFormaPago(datos) {
    const cont = document.getElementById('grafico-pag-formapago');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin pagos en el periodo</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-wallet text-orange-500 mr-2"></i>Pagos por Forma de Pago</h3><div style="height:300px;position:relative"><canvas id="cv-pag-fp"></canvas></div>';

    destruirChart('pag-fp');
    charts['pag-fp'] = new Chart(document.getElementById('cv-pag-fp'), {
        type: 'doughnut',
        data: { labels: datos.map(r => r[0]), datasets: [{ data: datos.map(r => r[1]), backgroundColor: colores, borderWidth: 2, hoverOffset: 15 }] },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'right', labels: { font: {size:11}, padding:8 } },
                tooltip: { callbacks: { label: ctx => ctx.label+': '+formatMoney(ctx.raw) } }
            },
            animation: { animateRotate: true, animateScale: true, duration: 1200, easing: 'easeOutBounce' }
        }
    });
}

function renderDeudasProveedor(datos) {
    const cont = document.getElementById('grafico-pag-proveedor');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin deudas pendientes</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-exclamation-triangle text-orange-500 mr-2"></i>Top 10 Deudas a Proveedores</h3>';
    html += '<table class="w-full text-sm"><thead><tr class="bg-slate-100">';
    html += '<th class="text-left p-2 rounded-tl-lg">#</th>';
    html += '<th class="text-left p-2">Proveedor</th>';
    html += '<th class="text-right p-2">Deuda</th>';
    html += '<th class="text-right p-2 rounded-tr-lg">Atraso</th></tr></thead><tbody>';
    const maxVal = Math.max(...datos.map(p => p.deuda));
    datos.forEach((p, i) => {
        const pct = (p.deuda / maxVal * 100).toFixed(0);
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        const badgeAtraso = p.dias_atraso > 60 ? 'bg-red-100 text-red-700' : p.dias_atraso > 30 ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700';
        html += '<tr class="'+bg+' hover:bg-orange-50 transition-colors">' +
            '<td class="p-2 text-slate-400 font-bold">'+(i+1)+'</td>' +
            '<td class="p-2"><div>'+p.nombre+'</div><div class="w-full bg-gray-200 rounded-full h-1.5 mt-1"><div class="bg-orange-400 h-1.5 rounded-full" style="width:'+pct+'%"></div></div></td>' +
            '<td class="p-2 text-right font-bold text-red-600">'+formatMoney(p.deuda)+'</td>' +
            '<td class="p-2 text-right"><span class="'+badgeAtraso+' text-xs px-2 py-0.5 rounded-full">'+p.dias_atraso+' dias</span></td></tr>';
    });
    html += '</tbody></table>';
    cont.innerHTML = html;
}

function renderUltimasOrdPag(datos) {
    const cont = document.getElementById('ultimas-ordpag');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin ordenes de pago en el periodo</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-file-invoice text-orange-500 mr-2"></i>Ultimas 10 Ordenes de Pago</h3>';
    html += '<div class="space-y-2">';
    datos.forEach((r, i) => {
        const delay = i * 80;
        html += '<div class="flex items-center gap-3 p-2.5 bg-gray-50 rounded-lg hover:bg-orange-50 transition-all border-l-4 border-orange-400" style="animation: fadeInRight 0.4s ease-out '+delay+'ms both">' +
            '<div class="flex-shrink-0 w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center"><i class="fas fa-file-invoice-dollar text-orange-600"></i></div>' +
            '<div class="flex-1 min-w-0">' +
                '<div class="flex items-center justify-between">' +
                    '<p class="text-sm font-semibold text-slate-700 truncate">'+r.proveedor+'</p>' +
                    '<p class="text-sm font-bold text-orange-600">'+formatMoney(r.total)+'</p>' +
                '</div>' +
                '<div class="flex items-center justify-between mt-0.5">' +
                    '<p class="text-xs text-slate-400"><i class="fas fa-hashtag mr-1"></i>OP '+String(r.numero).padStart(8,'0')+' <span class="mx-1">|</span> <i class="fas fa-calendar mr-1"></i>'+r.fecha+'</p>' +
                    '<p class="text-xs text-slate-400">'+r.usuario+'</p>' +
                '</div>' +
            '</div></div>';
    });
    html += '</div>';
    cont.innerHTML = html;
}

// ============================================================
// RENDERS CAJA
// ============================================================
function renderCajaResultado(datos) {
    const cont = document.getElementById('caja-resultado');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos en el periodo</p>';
        return;
    }
    let totalIng = 0, totalEgr = 0;
    datos.forEach(r => { totalIng += r.ingreso; totalEgr += r.egreso; });
    const resultado = totalIng - totalEgr;

    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-balance-scale text-indigo-500 mr-2"></i>Cuadro de Resultado</h3>';
    html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">';
    html += '<div class="text-center p-4 bg-green-50 rounded-lg"><p class="text-sm text-green-600">Total Ingresos</p><p class="text-2xl font-bold text-green-700">'+formatMoney(totalIng)+'</p></div>';
    html += '<div class="text-center p-4 bg-red-50 rounded-lg"><p class="text-sm text-red-600">Total Egresos</p><p class="text-2xl font-bold text-red-700">'+formatMoney(totalEgr)+'</p></div>';
    html += '<div class="text-center p-4 '+(resultado>=0?'bg-blue-50':'bg-orange-50')+' rounded-lg"><p class="text-sm '+(resultado>=0?'text-blue-600':'text-orange-600')+'">Resultado</p><p class="text-2xl font-bold '+(resultado>=0?'text-blue-700':'text-orange-700')+'">'+formatMoney(resultado)+'</p></div>';
    html += '</div>';
    html += '<table class="w-full text-sm"><thead><tr class="bg-slate-100"><th class="text-left p-2">Concepto</th><th class="text-right p-2 text-green-600">Ingresos</th><th class="text-right p-2 text-red-600">Egresos</th></tr></thead><tbody>';
    datos.forEach((r, i) => {
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        html += '<tr class="'+bg+'"><td class="p-2 font-medium">'+r.concepto+'</td>';
        html += '<td class="p-2 text-right '+(r.ingreso>0?'text-green-600 font-bold':'text-gray-300')+'">'+formatMoney(r.ingreso)+'</td>';
        html += '<td class="p-2 text-right '+(r.egreso>0?'text-red-600 font-bold':'text-gray-300')+'">'+formatMoney(r.egreso)+'</td></tr>';
    });
    html += '<tr class="bg-slate-200 font-bold"><td class="p-2">TOTAL</td>';
    html += '<td class="p-2 text-right text-green-700">'+formatMoney(totalIng)+'</td>';
    html += '<td class="p-2 text-right text-red-700">'+formatMoney(totalEgr)+'</td></tr>';
    html += '</tbody></table>';
    cont.innerHTML = html;
}

function renderCajaEvolucion(datos) {
    const cont = document.getElementById('caja-evolucion');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin cierres en el periodo</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-chart-area text-indigo-500 mr-2"></i>Evolucion Diaria</h3><div style="height:320px;position:relative"><canvas id="cv-caja-evo"></canvas></div>';

    destruirChart('caja-evo');
    charts['caja-evo'] = new Chart(document.getElementById('cv-caja-evo'), {
        type: 'line',
        data: {
            labels: datos.map(r => r.fecha),
            datasets: [
                { label: 'Ingresos', data: datos.map(r => r.ingresos), borderColor: '#10b981', backgroundColor: 'rgba(16,185,129,0.1)', fill: true, tension: 0.3, borderWidth: 2, pointRadius: 3, pointHoverRadius: 6 },
                { label: 'Egresos', data: datos.map(r => r.egresos), borderColor: '#ef4444', backgroundColor: 'rgba(239,68,68,0.1)', fill: true, tension: 0.3, borderWidth: 2, pointRadius: 3, pointHoverRadius: 6 },
                { label: 'Falt/Sob', data: datos.map(r => r.faltante), borderColor: '#8b5cf6', backgroundColor: 'transparent', borderDash: [5,5], tension: 0.3, borderWidth: 1.5, pointRadius: 2 }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: { position: 'top', labels: { font: {size:11}, usePointStyle: true, pointStyle: 'circle' } },
                tooltip: { callbacks: { label: ctx => ctx.dataset.label + ': ' + formatMoney(ctx.raw) } }
            },
            scales: {
                y: { ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k' } }
            },
            animation: { duration: 1200, easing: 'easeOutQuart' }
        }
    });
}

function renderCajaConceptos(datos) {
    const cont = document.getElementById('caja-conceptos');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin datos</p>';
        return;
    }
    cont.innerHTML = '<h3 class="text-lg font-bold text-slate-600 mb-2"><i class="fas fa-list-alt text-indigo-500 mr-2"></i>Por Concepto</h3><div style="height:320px;position:relative"><canvas id="cv-caja-conc"></canvas></div>';

    const labels = datos.map(r => r.concepto.length > 20 ? r.concepto.substring(0,18)+'...' : r.concepto);
    destruirChart('caja-conc');
    charts['caja-conc'] = new Chart(document.getElementById('cv-caja-conc'), {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                { label: 'Ingresos', data: datos.map(r => r.debe), backgroundColor: 'rgba(16,185,129,0.7)', borderRadius: 4, borderSkipped: false },
                { label: 'Egresos', data: datos.map(r => r.haber), backgroundColor: 'rgba(239,68,68,0.7)', borderRadius: 4, borderSkipped: false }
            ]
        },
        options: {
            indexAxis: 'y', responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'top', labels: { font: {size:10} } },
                tooltip: { callbacks: { label: ctx => ctx.dataset.label + ': ' + formatMoney(ctx.raw) } }
            },
            scales: { x: { stacked: false, ticks: { callback: v => '$ '+Number(v/1000).toLocaleString()+'k', font: {size:9} } } },
            animation: { duration: 800, easing: 'easeOutQuart' }
        }
    });
}

function renderCajaCierres(datos) {
    const cont = document.getElementById('caja-cierres');
    if (!datos || datos.length === 0) {
        cont.innerHTML = '<p class="text-gray-400 text-center p-8">Sin cierres en el periodo</p>';
        return;
    }
    let html = '<h3 class="text-lg font-bold text-slate-600 mb-3"><i class="fas fa-clipboard-check text-indigo-500 mr-2"></i>Ultimos Cierres de Caja</h3>';
    html += '<div class="overflow-x-auto"><table class="w-full text-sm"><thead><tr class="bg-slate-100">';
    html += '<th class="p-2 text-left">Cierre</th><th class="p-2 text-left">Fecha</th><th class="p-2 text-center">Caja</th><th class="p-2 text-center">Hora</th>';
    html += '<th class="p-2 text-right text-green-600">Ingresos</th><th class="p-2 text-right text-red-600">Egresos</th>';
    html += '<th class="p-2 text-right">Efectivo</th><th class="p-2 text-right">Falt/Sob</th></tr></thead><tbody>';
    datos.forEach((r, i) => {
        const bg = i % 2 === 0 ? 'bg-white' : 'bg-slate-50';
        const colorSaldo = r.saldo > 0 ? 'text-red-600' : r.saldo < 0 ? 'text-green-600' : 'text-gray-400';
        const iconSaldo = r.saldo > 0 ? '<i class="fas fa-arrow-down text-red-400 mr-1"></i>' : r.saldo < 0 ? '<i class="fas fa-arrow-up text-green-400 mr-1"></i>' : '';
        html += '<tr class="'+bg+' hover:bg-indigo-50 transition-colors" style="animation: fadeInRight 0.3s ease-out '+(i*50)+'ms both">';
        html += '<td class="p-2 font-mono text-slate-500">#'+r.id+'</td>';
        html += '<td class="p-2">'+r.fecha+'</td>';
        html += '<td class="p-2 text-center"><span class="bg-indigo-100 text-indigo-700 text-xs px-2 py-0.5 rounded-full">'+r.caja+'</span></td>';
        html += '<td class="p-2 text-center text-slate-400">'+r.hora+'</td>';
        html += '<td class="p-2 text-right font-bold text-green-600">'+formatMoney(r.debe)+'</td>';
        html += '<td class="p-2 text-right font-bold text-red-600">'+formatMoney(r.haber)+'</td>';
        html += '<td class="p-2 text-right">'+formatMoney(r.efectivo)+'</td>';
        html += '<td class="p-2 text-right '+colorSaldo+'">'+iconSaldo+formatMoney(Math.abs(r.saldo))+'</td>';
        html += '</tr>';
    });
    html += '</tbody></table></div>';
    cont.innerHTML = html;
}

// ============================================================
// MODO IA
// ============================================================
function iaEnviar() {
    var input = document.getElementById('ia-input');
    var pregunta = input.value.trim();
    if (!pregunta) return;
    input.value = '';
    iaPreguntaActual = pregunta;
    var cont = document.getElementById('ia-resultado-container');
    cont.innerHTML = '<div class="bg-violet-50 border border-violet-200 rounded-lg p-3 mb-3"><p class="text-sm text-violet-700 font-medium"><i class="fas fa-user mr-2"></i>' + pregunta + '</p></div>' +
        '<div class="flex items-center justify-center py-8"><div class="flex gap-1.5"><div class="w-2.5 h-2.5 bg-violet-400 rounded-full animate-bounce" style="animation-delay:0ms"></div><div class="w-2.5 h-2.5 bg-violet-400 rounded-full animate-bounce" style="animation-delay:150ms"></div><div class="w-2.5 h-2.5 bg-violet-400 rounded-full animate-bounce" style="animation-delay:300ms"></div></div><p class="text-sm text-slate-400 ml-3">Consultando...</p></div>';
    SendToFWH('ia_consulta', pregunta);
}

var iaPreguntaActual = '';
var iaColsMoneda = [];

function recibirIA(datos) {
    var cont = document.getElementById('ia-resultado-container');
    var pregDiv = cont.querySelector('.bg-violet-50');
    var pregHtml = pregDiv ? pregDiv.outerHTML : '';

    if (datos.error) {
        cont.innerHTML = pregHtml + '<div class="bg-red-50 border border-red-200 rounded-lg p-4"><p class="text-sm text-red-600"><i class="fas fa-exclamation-circle mr-2"></i>' + datos.error + '</p></div>';
        return;
    }
    if (datos.texto) {
        cont.innerHTML = pregHtml + '<div class="bg-white shadow border border-slate-200 rounded-lg p-4"><div class="flex items-start gap-3"><div class="flex-shrink-0 w-8 h-8 bg-violet-100 rounded-full flex items-center justify-center"><i class="fas fa-robot text-violet-600 text-xs"></i></div><div class="text-sm text-slate-700 leading-relaxed">' + datos.texto + '</div></div></div>';
        return;
    }
    if (datos.mensaje) {
        cont.innerHTML = pregHtml + '<div class="bg-blue-50 border border-blue-200 rounded-lg p-4"><p class="text-sm text-blue-600"><i class="fas fa-info-circle mr-2"></i>' + datos.mensaje + '</p></div>';
        return;
    }

    iaResultadoActual = datos;
    // Detectar columnas que son moneda (contienen palabras clave)
    iaColsMoneda = [];
    var palabrasMoneda = ['importe','total','deuda','venta','compra','neto','iva','precio','costo','saldo','pago','cobr','monto','ingreso','egreso','efectivo'];
    datos.columnas.forEach(function(col, i) {
        var colLow = col.toLowerCase();
        for (var p = 0; p < palabrasMoneda.length; p++) {
            if (colLow.indexOf(palabrasMoneda[p]) >= 0) { iaColsMoneda.push(i); break; }
        }
    });

    var html = pregHtml;
    html += '<div class="bg-white shadow border border-slate-200 rounded-lg p-4">';
    html += '<div class="flex items-center gap-2 mb-3 flex-wrap">';
    html += '<span class="text-xs text-slate-400"><i class="fas fa-database mr-1"></i>' + datos.datos.length + ' resultados</span>';
    html += '<div class="flex gap-1 ml-auto">';
    html += '<button onclick="iaVerTabla()" class="bg-slate-100 hover:bg-slate-200 text-slate-600 text-xs px-2.5 py-1 rounded-full transition-colors"><i class="fas fa-table mr-1"></i>Tabla</button>';
    if (datos.columnas.length >= 2) {
        html += '<button onclick="iaVerGrafico(&apos;bar&apos;)" class="bg-blue-100 hover:bg-blue-200 text-blue-600 text-xs px-2.5 py-1 rounded-full transition-colors"><i class="fas fa-chart-bar mr-1"></i>Barras</button>';
        html += '<button onclick="iaVerGrafico(&apos;doughnut&apos;)" class="bg-amber-100 hover:bg-amber-200 text-amber-600 text-xs px-2.5 py-1 rounded-full transition-colors"><i class="fas fa-chart-pie mr-1"></i>Torta</button>';
        html += '<button onclick="iaVerGrafico(&apos;line&apos;)" class="bg-green-100 hover:bg-green-200 text-green-600 text-xs px-2.5 py-1 rounded-full transition-colors"><i class="fas fa-chart-line mr-1"></i>Linea</button>';
    }
    // Selector de columna para graficar (si hay mas de 2 columnas numericas)
    var colsNum = [];
    datos.columnas.forEach(function(c, i) { if (datos.datos[0] && typeof datos.datos[0][i] === 'number') colsNum.push(i); });
    if (colsNum.length > 1) {
        html += '<select id="ia-sel-col" class="text-xs border border-slate-300 rounded px-1.5 py-1 ml-1">';
        html += '<option value="-1">Todas las series</option>';
        colsNum.forEach(function(ci) { html += '<option value="'+ci+'">'+datos.columnas[ci]+'</option>'; });
        html += '</select>';
    }
    html += '</div></div>';
    html += '<div id="ia-resultado"></div>';
    html += '<div id="ia-calificar" class="flex items-center gap-2 mt-3 pt-2 border-t border-slate-100">';
    html += '<span class="text-xs text-slate-400">Esta respuesta fue util?</span>';
    html += '<button onclick="iaCalificar(&apos;B&apos;)" class="text-green-500 hover:text-green-700 hover:bg-green-50 rounded-full p-1.5 transition-colors" title="Buena respuesta"><i class="fas fa-thumbs-up"></i></button>';
    html += '<button onclick="iaCalificar(&apos;M&apos;)" class="text-red-400 hover:text-red-600 hover:bg-red-50 rounded-full p-1.5 transition-colors" title="Mala respuesta"><i class="fas fa-thumbs-down"></i></button>';
    html += '</div>';
    html += '</div>';

    cont.innerHTML = html;
    iaVerTabla();
}

function iaEsMoneda(idx) {
    return iaColsMoneda && iaColsMoneda.indexOf(idx) >= 0;
}

function iaFormatValor(v, colIdx) {
    if (typeof v === 'number') {
        if (iaEsMoneda(colIdx)) return formatMoney(v);
        // Numero sin decimales si es entero
        if (v === Math.floor(v)) return Number(v).toLocaleString('es-AR');
        return Number(v).toLocaleString('es-AR', {minimumFractionDigits:2, maximumFractionDigits:2});
    }
    return v;
}

function iaVerTabla() {
    var d = iaResultadoActual;
    if (!d) return;
    var html = '<div class="overflow-x-auto"><table class="w-full text-xs"><thead><tr class="bg-slate-100">';
    d.columnas.forEach(function(c) { html += '<th class="p-1.5 text-left">' + c + '</th>'; });
    html += '</tr></thead><tbody>';
    d.datos.forEach(function(fila, i) {
        html += '<tr class="'+(i%2===0?'bg-white':'bg-slate-50')+' hover:bg-violet-50">';
        fila.forEach(function(v, j) {
            var esNum = typeof v === 'number';
            html += '<td class="p-1.5 '+(esNum?'text-right font-mono':'')+'">'+ iaFormatValor(v, j) +'</td>';
        });
        html += '</tr>';
    });
    html += '</tbody></table></div>';
    document.getElementById('ia-resultado').innerHTML = html;
}

function iaDetectarColLabel(d) {
    // Buscar la mejor columna para usar como etiqueta
    // 1ro: columna de texto (nombre, cliente, producto, etc)
    for (var i = 0; i < d.columnas.length; i++) {
        if (d.datos[0] && typeof d.datos[0][i] === 'string') return i;
    }
    // 2do: columna con nombre que sugiera etiqueta (mes, anio, fecha, periodo)
    var nombresLabel = ['mes','anio','ano','fecha','periodo','nombre','cliente','proveedor','rubro','marca'];
    for (var i = 0; i < d.columnas.length; i++) {
        var colLow = d.columnas[i].toLowerCase();
        for (var n = 0; n < nombresLabel.length; n++) {
            if (colLow.indexOf(nombresLabel[n]) >= 0) return i;
        }
    }
    // 3ro: primera columna
    return 0;
}

function iaGetColsNumericas(d, colLabel) {
    var cols = [];
    for (var i = 0; i < d.columnas.length; i++) {
        if (i !== colLabel && d.datos[0] && typeof d.datos[0][i] === 'number') cols.push(i);
    }
    return cols;
}

function iaVerGrafico(tipo) {
    var d = iaResultadoActual;
    if (!d || d.columnas.length < 2) return;

    var colLabel = iaDetectarColLabel(d);
    var colsNum = iaGetColsNumericas(d, colLabel);
    if (colsNum.length === 0) return;

    // Ver si el usuario eligio una columna especifica
    var selCol = document.getElementById('ia-sel-col');
    var colSeleccionada = selCol ? parseInt(selCol.value) : -1;

    var labels = d.datos.map(function(f) { return String(f[colLabel]); });

    // Armar datasets
    var datasets = [];
    var colsAGraficar = (colSeleccionada >= 0) ? [colSeleccionada] : colsNum;

    // Para doughnut solo usar una columna (la primera o la seleccionada)
    if (tipo === 'doughnut') colsAGraficar = [colsAGraficar[0]];

    colsAGraficar.forEach(function(ci, idx) {
        var values = d.datos.map(function(f) { return typeof f[ci] === 'number' ? f[ci] : parseFloat(f[ci]) || 0; });
        var color = colores[idx % colores.length];
        datasets.push({
            label: d.columnas[ci],
            data: values,
            backgroundColor: tipo === 'doughnut' ? colores : (tipo === 'line' ? 'rgba('+hexToRgb(color)+',0.1)' : color),
            borderColor: tipo === 'doughnut' ? colores : color,
            borderWidth: tipo === 'line' ? 2 : 1,
            borderRadius: tipo === 'bar' ? 6 : 0,
            borderSkipped: false,
            fill: tipo === 'line',
            tension: 0.3,
            hoverOffset: tipo === 'doughnut' ? 15 : 0,
            pointRadius: tipo === 'line' ? 4 : 0,
            pointHoverRadius: tipo === 'line' ? 7 : 0
        });
    });

    document.getElementById('ia-resultado').innerHTML = '<div style="height:320px;position:relative"><canvas id="cv-ia-chart"></canvas></div>';

    destruirChart('ia-chart');
    var config = {
        type: tipo,
        data: { labels: labels, datasets: datasets },
        options: {
            responsive: true, maintainAspectRatio: false,
            indexAxis: tipo === 'bar' && labels.length > 6 ? 'y' : 'x',
            plugins: {
                legend: { display: datasets.length > 1 || tipo === 'doughnut', position: tipo === 'doughnut' ? 'right' : 'top', labels: { font: {size:10} } },
                tooltip: { callbacks: { label: function(ctx) {
                    var ci = colsAGraficar[ctx.datasetIndex] || colsAGraficar[0];
                    var val = iaEsMoneda(ci) ? formatMoney(ctx.raw) : Number(ctx.raw).toLocaleString('es-AR', {maximumFractionDigits:2});
                    return ctx.dataset.label + ': ' + val;
                }}}
            },
            animation: { duration: 1000, easing: 'easeOutQuart' }
        }
    };
    if (tipo !== 'doughnut') {
        var ejeVal = (tipo==='bar' && labels.length>6) ? 'x' : 'y';
        config.options.scales = {};
        config.options.scales[ejeVal] = { ticks: { callback: function(v) { return Number(v).toLocaleString('es-AR', {maximumFractionDigits:0}); } } };
    }
    charts['ia-chart'] = new Chart(document.getElementById('cv-ia-chart'), config);
}

function hexToRgb(hex) {
    hex = hex.replace('#','');
    return parseInt(hex.substring(0,2),16)+','+parseInt(hex.substring(2,4),16)+','+parseInt(hex.substring(4,6),16);
}

function iaCalificar(calif) {
    SendToFWH('ia_calificar', iaPreguntaActual, calif);
}

function iaCalificacionOk() {
    var el = document.getElementById('ia-calificar');
    if (el) {
        el.innerHTML = '<span class="text-xs text-green-500"><i class="fas fa-check-circle mr-1"></i>Gracias por tu calificacion</span>';
    }
}
</script>

<style>
@keyframes fadeInRight {
    from { opacity: 0; transform: translateX(20px); }
    to { opacity: 1; transform: translateX(0); }
}
</style>

</body>
</html>
ENDTEXT

RETURN cHtml
