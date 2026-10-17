#include "FiveWin.ch"
#include "Tdolphin.ch"

*************************************************
** TABLERO DE CONTROL (dashboard) - solo ADMIN con permiso de crear usuarios
**
** La pagina es HTML/JS (dashboard\dashboard.html) mostrada en el Internet
** Explorer embebido (ActiveX "Shell.Explorer.2"), la misma tecnica que el
** display del cliente: no necesita DLLs ni instalar nada en las PCs.
** El HTML viaja dentro del exe (HtmlEmbebido, al final) y se escribe en
** .\dashboard\ cuando falta o cambia la version.
**
** Puente pagina <-> sistema: dos <textarea> ocultos.
**   #req : la pagina deja un array JSON de pedidos {id, accion, ...}
**   #resp: el sistema deja un array JSON de respuestas {id, datos | error}
** Un timer lee #req, atiende y escribe #resp cuando la pagina lo vacio.
**
** Seguridad: la pagina nunca recibe nombres de tablas, campos ni SQL. El
** asistente de IA solo puede leer tablas de negocio del cliente actual (lista
** blanca de tablas), en una transaccion de solo lectura.
*************************************************
MEMVAR oApp

#define DW_INI      ".\dashboard\dashboard.ini"
#define DW_HTML     ".\dashboard\dashboard.html"
#define DW_LOG      ".\dashboard\dashboard.log"
#define DW_TIMEOUT  45000        // ms por llamada a la IA

STATIC oWndDW, oWebDW, oTmrDW, cVentanaDW, hDW

*************************************************
PROCEDURE DashboardWeb()
LOCAL hHand, cHtml

cVentanaDW := PROCNAME()
IF ASCAN(oApp:aVentanas, cVentanaDW) > 0
   hHand := ASCAN(oApp:aVentanas, cVentanaDW)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
IF !DashPermitido()
   MsgStop("El tablero de control solo lo puede ver un usuario ADMIN con permiso para crear usuarios.","Atencion")
   RETURN
ENDIF
cHtml := DashAsegurarHtml()
IF EMPTY(cHtml)
   MsgStop("No se pudo preparar la pagina del tablero en la carpeta dashboard.","Atencion")
   RETURN
ENDIF
DashCrearTablas()
AADD(oApp:aVentanas, cVentanaDW)

hDW := { "listo" => .f., "salida" => {}, "ia" => nil, "iaCfg" => nil, "hist" => {} }

DEFINE WINDOW oWndDW MDICHILD TITLE "Tablero de control" OF oApp:oWnd ICON oApp:oIco

ACTIVATE WINDOW oWndDW MAXIMIZED ;
   ON INIT DashCrearWeb(cHtml) ;
   ON RESIZE DashAjustar() ;
   VALID DashCerrar()
RETURN

*************************************************
** ADMIN y con permiso de crear usuarios (modulo CREUSU con ABMRE)
STATIC FUNCTION DashPermitido()
LOCAL lSup := oApp:usua_es_supervisor
RETURN VALTYPE(lSup) = "L" .AND. lSup .AND. CtaProvEsAdmin()

*************************************************
** Crea el navegador. El timer va aca (ON INIT): TTimer necesita el hWnd.
STATIC FUNCTION DashCrearWeb(cHtml)
LOCAL bErr := ErrorBlock({|e| Break(e)}), oErr
BEGIN SEQUENCE
   oWebDW := TActiveX():New(oWndDW, "Shell.Explorer.2")
   DashAjustar()
   oWebDW:oOleAuto:Silent := .T.
   oWebDW:oOleAuto:Navigate(DashUrl(cHtml) + "?pos=1")
RECOVER USING oErr
   DashLog("No se pudo crear el navegador: " + DashErrTxt(oErr))
   oWebDW := nil
END SEQUENCE
ErrorBlock(bErr)
IF oWebDW == nil
   MsgStop("No se pudo abrir el navegador interno de Windows.","Atencion")
   RETURN nil
ENDIF
DEFINE TIMER oTmrDW INTERVAL 80 ACTION DashTick() OF oWndDW
ACTIVATE TIMER oTmrDW
RETURN nil

// El navegador ocupa el area interna de la ventana
STATIC FUNCTION DashAjustar()
LOCAL aR
IF oWebDW <> nil .AND. oWndDW <> nil
   aR := GetClientRect(oWndDW:hWnd)
   oWebDW:Move(0, 0, aR[4] - aR[2], aR[3] - aR[1], .T.)
ENDIF
RETURN nil

*************************************************
STATIC FUNCTION DashCerrar()
LOCAL aNueva := {}, i, j
IF oTmrDW <> nil
   oTmrDW:End()
   oTmrDW := nil
ENDIF
oWebDW := nil
hDW    := nil
j := ASCAN(oApp:aVentanas, cVentanaDW)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva, oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

*************************************************
** Timer: toma los pedidos de la pagina, avanza la IA y entrega respuestas
STATIC FUNCTION DashTick()
LOCAL cReq, aReq, i, uRes
IF hDW == nil .OR. oWebDW == nil
   RETURN nil
ENDIF
IF !(DashOle({|| oWebDW:oOleAuto:ReadyState}) == 4)
   RETURN nil
ENDIF
IF !hDW["listo"]
   hDW["listo"] := .t.
   DashOle({|| oWebDW:oOleAuto:ExecWB(63, 2, 100, nil), .t.})   // zoom 100%
ENDIF
oTmrDW:DeActivate()     // que no reentre mientras se atiende (consultas largas)
cReq := DashOle({|| oWebDW:oOleAuto:Document:getElementById("req"):value})
IF VALTYPE(cReq) = "C" .AND. !EMPTY(cReq)
   DashOle({|| oWebDW:oOleAuto:Document:getElementById("req"):value := "", .t.})
   aReq := nil
   hb_jsonDecode(cReq, @aReq)
   IF VALTYPE(aReq) = "A"
      FOR i := 1 TO LEN(aReq)
          IF VALTYPE(aReq[i]) = "H"
             uRes := DashAtender(aReq[i])
             IF hDW == nil         // cerraron la ventana mientras se armaba (DashProg)
                RETURN nil
             ENDIF
             IF uRes <> nil        // nil = queda pendiente (IA)
                AADD(hDW["salida"], uRes)
             ENDIF
          ENDIF
      NEXT i
   ENDIF
ENDIF
IF hDW <> nil .AND. hDW["ia"] <> nil
   uRes := IAAvanzar()
   IF uRes <> nil
      AADD(hDW["salida"], uRes)
   ENDIF
ENDIF
IF hDW <> nil .AND. LEN(hDW["salida"]) > 0
   IF DashOle({|| oWebDW:oOleAuto:Document:getElementById("resp"):value}) == ""
      IF DashOle({|| oWebDW:oOleAuto:Document:getElementById("resp"):value := DashJsonAscii(hb_jsonEncode(hDW["salida"])), .t.}) == .t.
         hDW["salida"] := {}
      ENDIF
   ENDIF
ENDIF
IF hDW <> nil .AND. hb_HGetDef(hDW, "cerrar", .f.) .AND. oWndDW <> nil
   // El timer se apaga antes (estamos dentro de su accion); End() pasa por el
   // VALID igual que la X de la ventana (en una MDI hija WM_CLOSE no alcanza)
   IF oTmrDW <> nil
      oTmrDW:End()
      oTmrDW := nil
   ENDIF
   oWndDW:End()
   RETURN nil
ENDIF
IF oTmrDW <> nil
   oTmrDW:Activate()
ENDIF
RETURN nil

*************************************************
** Atiende un pedido. Devuelve { id, datos } o { id, error }; nil si queda
** pendiente (consulta a la IA, la responde IAAvanzar).
STATIC FUNCTION DashAtender(h)
LOCAL nId := hb_HGetDef(h, "id", 0), cAcc := hb_HGetDef(h, "accion", ""), uDat, oErr, cD, cH, cPD, cPH
LOCAL bErr := ErrorBlock({|e| Break(e)})
BEGIN SEQUENCE
   cD  := DashFec(hb_HGetDef(h, "desde", ""))
   cH  := DashFec(hb_HGetDef(h, "hasta", ""))
   cPD := DashFec(hb_HGetDef(h, "pdesde", ""))
   cPH := DashFec(hb_HGetDef(h, "phasta", ""))
   DO CASE
      CASE cAcc == "init"
         uDat := { "empresa" => DashTxt(oApp:nomb_emp), "usuario" => DashTxt(oApp:usuario), ;
                   "tema" => DashTema(), "hoy" => DashFecTxt(DATE()), "ia" => IADisponible() }
      CASE cAcc == "tema"
         DashGuardarTema(hb_HGetDef(h, "tema", "oscuro"))
         uDat := .t.
      CASE cAcc == "resumen"
         uDat := DatResumen(cD, cH, cPD, cPH)
      CASE cAcc == "ventas"
         uDat := DatVentas(cD, cH, cPD, cPH, hb_HGetDef(h, "agrupar", "rubro"))
      CASE cAcc == "ranking"
         uDat := DatRanking(cD, cH, hb_HGetDef(h, "agrupar", "rubro"))
      CASE cAcc == "clientes"
         uDat := DatClientes(cD, cH)
      CASE cAcc == "compras"
         uDat := DatCompras(cD, cH)
      CASE cAcc == "stock"
         uDat := DatStock()
      CASE cAcc == "caja"
         uDat := DatCaja(cD, cH)
      CASE cAcc == "ia"
         IF hDW["ia"] <> nil
            uDat := { "texto" => "Todav" + CHR(237) + "a estoy respondiendo la pregunta anterior. Esper" + CHR(225) + " un momento." }
         ELSE
            IAIniciar(nId, ALLTRIM(IADesdeUrl(DashTxt(hb_HGetDef(h, "pregunta", "")))))
            uDat := nil
         ENDIF
      CASE cAcc == "ia_calif"
         IACalificar(hb_HGetDef(h, "log", 0), hb_HGetDef(h, "calif", ""))
         uDat := .t.
      CASE cAcc == "ia_nueva"
         hDW["hist"] := {}
         uDat := .t.
      CASE cAcc == "cerrar"
         // Boton Cerrar de la pagina: se cierra al terminar el tick (no
         // desde adentro del timer, que se destruye al cerrar)
         hDW["cerrar"] := .t.
         uDat := .t.
      OTHERWISE
         uDat := { "error" => "Pedido desconocido" }
   ENDCASE
RECOVER USING oErr
   ErrorBlock(bErr)
   DashLog(cAcc + ": " + DashErrTxt(oErr))
   RETURN { "id" => nId, "error" => "No se pudieron leer los datos." }
END SEQUENCE
ErrorBlock(bErr)
IF cAcc == "ia" .AND. uDat == nil
   RETURN nil
ENDIF
RETURN { "id" => nId, "datos" => uDat }

*************************************************
** DATOS DE CADA SECCION
** cD/cH = periodo, cPD/cPH = periodo anterior (fechas ya entre comillas).
** Cada bloque va en su propio TRY (DashQ): si a un cliente le falta una
** columna, ese bloque sale vacio y el resto del tablero se ve igual.
*************************************************
STATIC FUNCTION DatResumen(cD, cH, cPD, cPH)
LOCAL h := {=>}, cP := "ge_"+oApp:cId, cGrp := DashAgrupa(cD, cH)
h["agrupa"] := cGrp
DashProg("Ventas del per&iacute;odo", 5)
h["kpi"]    := DashKpis(cD, cH)
DashProg("Comparando con el per&iacute;odo anterior", 18)
h["kpiAnt"] := DashKpis(cPD, cPH)
DashProg("Evoluci&oacute;n de las ventas", 32)
h["serie"]    := DashSerieVentas(cD, cH, cGrp)
h["serieAnt"] := DashSerieVentas(cPD, cPH, cGrp)
DashProg("M&aacute;rgenes, cobranzas y pagos", 45)
h["spark"] := DashSparks(cD, cH, cGrp)
DashProg("Formas de pago", 65)
h["formas"] := DashQ("SELECT IFNULL(f.nombre,'Otras') AS n, SUM(c.importe*IF(c.ticomp='NC',-1,1)) AS v "+;
     "FROM "+cP+"concfact c LEFT JOIN "+cP+"forpag f ON f.codigo = c.codcon "+;
     "WHERE c.fecha BETWEEN "+cD+" AND "+cH+" GROUP BY n HAVING v > 0 ORDER BY v DESC")
DashProg("Productos m&aacute;s vendidos", 75)
h["top"] := DashQ("SELECT IFNULL(a.nombre, MAX(d.detart)) AS n, SUM(d.importe*"+DashSigDet()+") AS v, "+;
     "SUM(d.cantidad*"+DashSigDet()+") AS c "+;
     "FROM "+cP+"ventas_det d LEFT JOIN "+cP+"articu a ON a.codigo = d.codart "+;
     "WHERE d.fecha BETWEEN "+cD+" AND "+cH+" AND d.codart > 0 GROUP BY d.codart HAVING v > 0 ORDER BY v DESC LIMIT 6")
DashProg("Deudas de clientes y proveedores", 85)
h["posicion"] := DashPosicion()
DashProg("Avisos del d&iacute;a", 95)
h["alertas"]  := DashAlertas()
RETURN h

STATIC FUNCTION DatVentas(cD, cH, cPD, cPH, cAgr)
LOCAL h := {=>}, cP := "ge_"+oApp:cId, cGrp := DashAgrupa(cD, cH), cS := DashSigDet()
h["agrupa"] := cGrp
DashProg("Ventas del per&iacute;odo", 5)
h["kpi"]    := DashKpis(cD, cH)
DashProg("Comparando con el per&iacute;odo anterior", 15)
h["kpiAnt"] := DashKpis(cPD, cPH)
DashProg("Unidades y devoluciones", 25)
h["extra"] := DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(d.cantidad*"+cS+"),0) FROM "+cP+"ventas_det d WHERE d.fecha BETWEEN "+cD+" AND "+cH+" AND d.codart > 0) AS unidades, "+;
     "(SELECT IFNULL(SUM(importe),0) FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp = 'NC') AS devol")
DashProg("Evoluci&oacute;n de las ventas", 35)
h["serie"]    := DashSerieVentas(cD, cH, cGrp)
h["serieAnt"] := DashSerieVentas(cPD, cPH, cGrp)
// Dia de la semana (1 = domingo) x hora
DashProg("Ventas por d&iacute;a y hora", 50)
h["calor"] := DashQ("SELECT DAYOFWEEK(fecha) AS d, CAST(LEFT(hora,2) AS UNSIGNED) AS h, COUNT(*) AS c, SUM(importe) AS v "+;
     "FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp = 'FC' "+;
     "AND hora IS NOT NULL AND LENGTH(TRIM(hora)) >= 2 GROUP BY d, h")
DashProg("Ventas por categor&iacute;a", 62)
h["ranking"] := DatRanking(cD, cH, cAgr)
DashProg("Productos m&aacute;s vendidos", 75)
h["productos"] := DashQ("SELECT IFNULL(a.nombre, MAX(d.detart)) AS n, SUM(d.cantidad*"+cS+") AS c, SUM(d.importe*"+cS+") AS v, "+;
     DashSqlMargen("d")+" AS m "+;
     "FROM "+cP+"ventas_det d LEFT JOIN "+cP+"articu a ON a.codigo = d.codart "+;
     "WHERE d.fecha BETWEEN "+cD+" AND "+cH+" AND d.codart > 0 GROUP BY d.codart HAVING v > 0 ORDER BY v DESC LIMIT 12")
DashProg("Ventas por vendedor", 90)
h["vendedores"] := DashQ("SELECT IF(TRIM(IFNULL(vendedor,'')) <> '', TRIM(vendedor), TRIM(IFNULL(usuario,''))) AS n, "+;
     "SUM(importe*IF(ticomp='NC',-1,1)) AS v, SUM(ticomp='FC') AS c "+;
     "FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp IN ('FC','NC','ND') "+;
     "GROUP BY n HAVING v > 0 ORDER BY v DESC LIMIT 10")
RETURN h

STATIC FUNCTION DatRanking(cD, cH, cAgr)
LOCAL cP := "ge_"+oApp:cId, cJoin, cSin
DO CASE
   CASE cAgr == "marca"
      cJoin := "LEFT JOIN "+cP+"marcas t ON t.codigo = a.marca "
      cSin  := "Sin marca"
   CASE cAgr == "depto"
      cJoin := "LEFT JOIN "+cP+"deptos t ON t.codigo = a.depto "
      cSin  := "Sin departamento"
   CASE cAgr == "proveedor"
      cJoin := "LEFT JOIN "+cP+"provee t ON t.codigo = a.prov "
      cSin  := "Sin proveedor"
   OTHERWISE
      cJoin := "LEFT JOIN "+cP+"rubros t ON t.codigo = a.rubro "
      cSin  := "Sin rubro"
ENDCASE
RETURN DashQ("SELECT IFNULL(t.nombre,'"+cSin+"') AS n, SUM(d.importe*"+DashSigDet()+") AS v, "+DashSqlMargen("d")+" AS m "+;
     "FROM "+cP+"ventas_det d LEFT JOIN "+cP+"articu a ON a.codigo = d.codart "+cJoin+;
     "WHERE d.fecha BETWEEN "+cD+" AND "+cH+" AND d.codart > 0 GROUP BY n HAVING v > 0 ORDER BY v DESC LIMIT 12")

STATIC FUNCTION DatClientes(cD, cH)
LOCAL h := {=>}, cP := "ge_"+oApp:cId, cS := "IF(v.tipo='NC',-1,1)", cDias := "DATEDIFF(CURDATE(), "+DashVtoCli("v")+")"
DashProg("Cobranzas y deuda de clientes", 5)
h["kpi"] := DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"pagos WHERE fecha BETWEEN "+cD+" AND "+cH+") AS cobrado, "+;
     "(SELECT COUNT(*) FROM "+cP+"pagos WHERE fecha BETWEEN "+cD+" AND "+cH+") AS recibos, "+;
     "(SELECT IFNULL(SUM(v.saldo*"+cS+"),0) FROM "+cP+"ventas_cuota v WHERE v.saldo > 0) AS deuda, "+;
     "(SELECT IFNULL(SUM(v.saldo*"+cS+"),0) FROM "+cP+"ventas_cuota v WHERE v.saldo > 0 AND "+cDias+" > 0) AS vencida, "+;
     "(SELECT COUNT(DISTINCT v.cliente) FROM "+cP+"ventas_cuota v WHERE v.saldo > 0) AS deudores")
DashProg("Antig&uuml;edad de la deuda", 25)
h["aging"] := DashQ1("SELECT "+;
     "SUM(IF("+cDias+" <= 0, v.saldo*"+cS+", 0)) AS a0, "+;
     "SUM(IF("+cDias+" BETWEEN 1 AND 30, v.saldo*"+cS+", 0)) AS a30, "+;
     "SUM(IF("+cDias+" BETWEEN 31 AND 60, v.saldo*"+cS+", 0)) AS a60, "+;
     "SUM(IF("+cDias+" BETWEEN 61 AND 90, v.saldo*"+cS+", 0)) AS a90, "+;
     "SUM(IF("+cDias+" > 90, v.saldo*"+cS+", 0)) AS a91 "+;
     "FROM "+cP+"ventas_cuota v WHERE v.saldo > 0")
DashProg("Clientes que m&aacute;s deben", 45)
h["deudores"] := DashQ("SELECT IFNULL(c.nombre, CONCAT('Cliente ', v.cliente)) AS n, SUM(v.saldo*"+cS+") AS v, "+;
     "MAX("+cDias+") AS d FROM "+cP+"ventas_cuota v LEFT JOIN "+cP+"clientes c ON c.codigo = v.cliente "+;
     "WHERE v.saldo > 0 GROUP BY v.cliente, c.nombre HAVING v > 0 ORDER BY v DESC LIMIT 10")
DashProg("Formas de cobro", 60)
h["formas"] := DashQ("SELECT CASE pc.tipocon WHEN 1 THEN 'Efectivo' WHEN 2 THEN 'Transferencia' WHEN 3 THEN 'Cheque' "+;
     "WHEN 4 THEN 'Tarjeta' WHEN 5 THEN 'Retenciones' WHEN 7 THEN 'Anticipo' WHEN 8 THEN 'Mercado Pago' ELSE 'Otras' END AS n, "+;
     "SUM(pc.importe) AS v FROM "+cP+"pagcon pc JOIN "+cP+"pagos p ON p.numero = pc.numero "+;
     "WHERE p.fecha BETWEEN "+cD+" AND "+cH+" GROUP BY n HAVING v > 0 ORDER BY v DESC")
DashProg("Cobranzas por d&iacute;a", 72)
h["cobros"] := DashQ("SELECT fecha AS f, SUM(total) AS v FROM "+cP+"pagos WHERE fecha BETWEEN "+cD+" AND "+cH+" GROUP BY fecha ORDER BY fecha")
DashProg("Mejores clientes", 85)
h["mejores"] := DashQ("SELECT IFNULL(c.nombre, MAX(e.nombre)) AS n, SUM(e.importe*IF(e.ticomp='NC',-1,1)) AS v, SUM(e.ticomp='FC') AS c "+;
     "FROM "+cP+"ventas_encab e LEFT JOIN "+cP+"clientes c ON c.codigo = e.codcli "+;
     "WHERE e.fecha BETWEEN "+cD+" AND "+cH+" AND e.ticomp IN ('FC','NC','ND') AND e.codcli > 1 "+;
     "GROUP BY e.codcli HAVING v > 0 ORDER BY v DESC LIMIT 10")
RETURN h

STATIC FUNCTION DatCompras(cD, cH)
LOCAL h := {=>}, cP := "ge_"+oApp:cId, cS := "IF(c.tipocomp='NC',-1,1)", cVto := "IFNULL(c.fecvto, c.fecfac)"
DashProg("Compras y deuda con proveedores", 5)
h["kpi"] := DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(c.importe*"+cS+"),0) FROM "+cP+"compras c WHERE c.fecfac BETWEEN "+cD+" AND "+cH+" AND c.tipocomp <> 'RE') AS compras, "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"ordpag WHERE fecha BETWEEN "+cD+" AND "+cH+" AND "+CtaProvSqlSinAjuste()+") AS pagado, "+;
     "(SELECT IFNULL(SUM(c.saldo*"+cS+"),0) FROM "+cP+"compras c WHERE c.saldo > 0 AND c.tipocomp <> 'RE') AS deuda, "+;
     "(SELECT IFNULL(SUM(c.saldo*"+cS+"),0) FROM "+cP+"compras c WHERE c.saldo > 0 AND c.tipocomp <> 'RE' AND "+cVto+" < CURDATE()) AS vencida, "+;
     "(SELECT IFNULL(SUM(c.saldo*"+cS+"),0) FROM "+cP+"compras c WHERE c.saldo > 0 AND c.tipocomp <> 'RE' AND "+cVto+" BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY) AS semana, "+;
     "(SELECT IFNULL(SUM(saldo),0) FROM "+cP+"provee WHERE saldo > 0) AS anticipos")
// Calendario de vencimientos: semanas desde hoy
DashProg("Calendario de pagos", 30)
h["vtos"] := DashQ1("SELECT "+;
     "SUM(IF("+cVto+" < CURDATE(), c.saldo*"+cS+", 0)) AS s0, "+;
     "SUM(IF("+cVto+" BETWEEN CURDATE() AND CURDATE() + INTERVAL 6 DAY, c.saldo*"+cS+", 0)) AS s1, "+;
     "SUM(IF("+cVto+" BETWEEN CURDATE() + INTERVAL 7 DAY AND CURDATE() + INTERVAL 13 DAY, c.saldo*"+cS+", 0)) AS s2, "+;
     "SUM(IF("+cVto+" BETWEEN CURDATE() + INTERVAL 14 DAY AND CURDATE() + INTERVAL 20 DAY, c.saldo*"+cS+", 0)) AS s3, "+;
     "SUM(IF("+cVto+" BETWEEN CURDATE() + INTERVAL 21 DAY AND CURDATE() + INTERVAL 27 DAY, c.saldo*"+cS+", 0)) AS s4, "+;
     "SUM(IF("+cVto+" > CURDATE() + INTERVAL 27 DAY, c.saldo*"+cS+", 0)) AS s5 "+;
     "FROM "+cP+"compras c WHERE c.saldo > 0 AND c.tipocomp <> 'RE'")
DashProg("Compras por proveedor", 50)
h["proveedores"] := DashQ("SELECT IFNULL(p.nombre, CONCAT('Proveedor ', c.codpro)) AS n, SUM(c.importe*"+cS+") AS v, COUNT(*) AS c "+;
     "FROM "+cP+"compras c LEFT JOIN "+cP+"provee p ON p.codigo = c.codpro "+;
     "WHERE c.fecfac BETWEEN "+cD+" AND "+cH+" AND c.tipocomp <> 'RE' GROUP BY c.codpro, p.nombre HAVING v > 0 ORDER BY v DESC LIMIT 10")
DashProg("Compras por cuenta", 70)
h["cuentas"] := DashQ("SELECT IFNULL(t.nombre,'Sin cuenta') AS n, SUM(c.importe*"+cS+") AS v "+;
     "FROM "+cP+"compras c LEFT JOIN "+cP+"plancont t ON t.codigo = c.codcue "+;
     "WHERE c.fecfac BETWEEN "+cD+" AND "+cH+" AND c.tipocomp <> 'RE' GROUP BY n HAVING v > 0 ORDER BY v DESC LIMIT 8")
DashProg("Deuda por proveedor", 85)
h["deuda"] := DashQ("SELECT IFNULL(p.nombre, CONCAT('Proveedor ', c.codpro)) AS n, SUM(c.saldo*"+cS+") AS v, "+;
     "MIN("+cVto+") AS f FROM "+cP+"compras c LEFT JOIN "+cP+"provee p ON p.codigo = c.codpro "+;
     "WHERE c.saldo > 0 AND c.tipocomp <> 'RE' GROUP BY c.codpro, p.nombre HAVING v > 0 ORDER BY v DESC LIMIT 10")
RETURN h

STATIC FUNCTION DatStock()
LOCAL h := {=>}, cP := "ge_"+oApp:cId
DashProg("Valorizando el stock", 5)
h["kpi"] := DashQ1("SELECT "+;
     "SUM(IF(stockact > 0, stockact*preciocos, 0)) AS costo, "+;
     "SUM(IF(stockact > 0, stockact*precioven, 0)) AS venta, "+;
     "SUM(stockact > 0) AS con_stock, "+;
     "SUM(stockmin > 0 AND stockact < stockmin) AS bajo_min "+;
     "FROM "+cP+"articu")
DashProg("Art&iacute;culos sin stock que se venden", 25)
h["faltantes"] := DashQ1("SELECT COUNT(*) AS n FROM "+cP+"articu a "+;
     "JOIN (SELECT DISTINCT codart FROM "+cP+"ventas_det WHERE fecha >= CURDATE() - INTERVAL 30 DAY AND codart > 0) v ON v.codart = a.codigo "+;
     "WHERE a.stockact <= 0")
DashProg("Art&iacute;culos bajo el m&iacute;nimo", 40)
h["bajo"] := DashQ("SELECT nombre AS n, stockact AS s, stockmin AS m, (stockmin - stockact) AS f "+;
     "FROM "+cP+"articu WHERE stockmin > 0 AND stockact < stockmin ORDER BY (stockmin - stockact)*preciocos DESC LIMIT 15")
DashProg("Mercader&iacute;a sin movimiento", 55)
h["quietos"] := DashQ("SELECT a.nombre AS n, a.stockact AS s, a.stockact*a.preciocos AS v, a.fecultcom AS f "+;
     "FROM "+cP+"articu a LEFT JOIN (SELECT DISTINCT codart FROM "+cP+"ventas_det WHERE fecha >= CURDATE() - INTERVAL 90 DAY AND codart > 0) v "+;
     "ON v.codart = a.codigo WHERE a.stockact > 0 AND a.preciocos > 0 AND v.codart IS NULL ORDER BY v DESC LIMIT 15")
h["quietosTot"] := DashQ1("SELECT IFNULL(SUM(a.stockact*a.preciocos),0) AS v, COUNT(*) AS n "+;
     "FROM "+cP+"articu a LEFT JOIN (SELECT DISTINCT codart FROM "+cP+"ventas_det WHERE fecha >= CURDATE() - INTERVAL 90 DAY AND codart > 0) v "+;
     "ON v.codart = a.codigo WHERE a.stockact > 0 AND a.preciocos > 0 AND v.codart IS NULL")
DashProg("Stock por rubro", 85)
h["rubros"] := DashQ("SELECT IFNULL(r.nombre,'Sin rubro') AS n, SUM(a.stockact*a.preciocos) AS v "+;
     "FROM "+cP+"articu a LEFT JOIN "+cP+"rubros r ON r.codigo = a.rubro WHERE a.stockact > 0 "+;
     "GROUP BY n HAVING v > 0 ORDER BY v DESC LIMIT 8")
RETURN h

STATIC FUNCTION DatCaja(cD, cH)
LOCAL h := {=>}, cP := "ge_"+oApp:cId
DashProg("Resultado del per&iacute;odo", 10)
h["resultado"] := DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(importe*IF(ticomp='NC',-1,1)),0) FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp IN ('FC','NC','ND')) AS ventas, "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"pagos WHERE fecha BETWEEN "+cD+" AND "+cH+") AS cobranzas, "+;
     "(SELECT IFNULL(SUM(importe*IF(tipocomp='NC',-1,1)),0) FROM "+cP+"compras WHERE fecfac BETWEEN "+cD+" AND "+cH+" AND tipocomp <> 'RE') AS compras, "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"ordpag WHERE fecha BETWEEN "+cD+" AND "+cH+" AND "+CtaProvSqlSinAjuste()+") AS pagos, "+;
     "(SELECT IFNULL(SUM(saldo),0) FROM "+cP+"cajadiaria WHERE fecha BETWEEN "+cD+" AND "+cH+") AS diferencias")
DashProg("Movimiento de caja por d&iacute;a", 45)
h["evolucion"] := DashQ("SELECT c.fecha AS f, SUM(IFNULL(cd.debe,0)) AS i, SUM(IFNULL(cd.haber,0)) AS e "+;
     "FROM "+cP+"cajadiaria c LEFT JOIN (SELECT id_caja, SUM(debe) AS debe, SUM(haber) AS haber FROM "+cP+"cajadiaria_det "+;
     "WHERE LEFT(concepto,1) <> '*' GROUP BY id_caja) cd ON cd.id_caja = c.id "+;
     "WHERE c.fecha BETWEEN "+cD+" AND "+cH+" GROUP BY c.fecha ORDER BY c.fecha")
DashProg("Cierres de caja", 75)
h["cierres"] := DashQ("SELECT c.fecha AS f, c.caja AS c, CAST(c.hora AS CHAR) AS h, c.saldo AS d, "+;
     "IFNULL(cd.debe,0) AS i, IFNULL(cd.haber,0) AS e, IFNULL(cd.efectivo,0) AS x "+;
     "FROM "+cP+"cajadiaria c LEFT JOIN (SELECT id_caja, SUM(debe) AS debe, SUM(haber) AS haber, SUM(efectivo) AS efectivo "+;
     "FROM "+cP+"cajadiaria_det WHERE LEFT(concepto,1) <> '*' GROUP BY id_caja) cd ON cd.id_caja = c.id "+;
     "WHERE c.fecha BETWEEN "+cD+" AND "+cH+" ORDER BY c.id DESC LIMIT 15")
RETURN h

*************************************************
** Bloques compartidos
*************************************************
STATIC FUNCTION DashKpis(cD, cH)
LOCAL cP := "ge_"+oApp:cId, h, hM, cS := DashSigDet()
h := DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(importe*IF(ticomp='NC',-1,1)),0) FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp IN ('FC','NC','ND')) AS ventas, "+;
     "(SELECT COUNT(*) FROM "+cP+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp = 'FC') AS comprobantes, "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"pagos WHERE fecha BETWEEN "+cD+" AND "+cH+") AS cobranzas, "+;
     "(SELECT IFNULL(SUM(importe*IF(tipocomp='NC',-1,1)),0) FROM "+cP+"compras WHERE fecfac BETWEEN "+cD+" AND "+cH+" AND tipocomp <> 'RE') AS compras, "+;
     "(SELECT IFNULL(SUM(total),0) FROM "+cP+"ordpag WHERE fecha BETWEEN "+cD+" AND "+cH+" AND "+CtaProvSqlSinAjuste()+") AS pagos")
// Margen: solo renglones con costo cargado (pcosto = costo unitario con IVA)
hM := DashQ1("SELECT IFNULL(SUM(IF(pcosto > 0, (importe - pcosto*cantidad)*"+cS+", 0)),0) AS margen, "+;
     "IFNULL(SUM(IF(pcosto > 0, importe*"+cS+", 0)),0) AS base, IFNULL(SUM(importe*"+cS+"),0) AS total "+;
     "FROM "+cP+"ventas_det WHERE fecha BETWEEN "+cD+" AND "+cH+" AND codart > 0")
IF h <> nil .AND. hM <> nil
   h["margen"]  := hM["margen"]
   h["mbase"]   := hM["base"]
   h["mtotal"]  := hM["total"]
ENDIF
RETURN h

STATIC FUNCTION DashSerieVentas(cD, cH, cGrp)
RETURN DashQ("SELECT "+DashSqlGrp("fecha", cGrp)+" AS f, SUM(importe*IF(ticomp='NC',-1,1)) AS v, SUM(ticomp='FC') AS c "+;
     "FROM ge_"+oApp:cId+"ventas_encab WHERE fecha BETWEEN "+cD+" AND "+cH+" AND ticomp IN ('FC','NC','ND') GROUP BY f ORDER BY f")

// Minigraficos de las tarjetas: margen, cobranzas, compras y pagos por dia/mes
STATIC FUNCTION DashSparks(cD, cH, cGrp)
LOCAL cP := "ge_"+oApp:cId, h := {=>}, cS := DashSigDet()
h["margen"] := DashQ("SELECT "+DashSqlGrp("fecha", cGrp)+" AS f, "+;
     "SUM(IF(pcosto > 0, (importe - pcosto*cantidad)*"+cS+", 0)) AS v FROM "+cP+"ventas_det "+;
     "WHERE fecha BETWEEN "+cD+" AND "+cH+" AND codart > 0 GROUP BY f ORDER BY f")
h["cobranzas"] := DashQ("SELECT "+DashSqlGrp("fecha", cGrp)+" AS f, SUM(total) AS v FROM "+cP+"pagos "+;
     "WHERE fecha BETWEEN "+cD+" AND "+cH+" GROUP BY f ORDER BY f")
h["compras"] := DashQ("SELECT "+DashSqlGrp("fecfac", cGrp)+" AS f, SUM(importe*IF(tipocomp='NC',-1,1)) AS v FROM "+cP+"compras "+;
     "WHERE fecfac BETWEEN "+cD+" AND "+cH+" AND tipocomp <> 'RE' GROUP BY f ORDER BY f")
h["pagos"] := DashQ("SELECT "+DashSqlGrp("fecha", cGrp)+" AS f, SUM(total) AS v FROM "+cP+"ordpag "+;
     "WHERE fecha BETWEEN "+cD+" AND "+cH+" AND "+CtaProvSqlSinAjuste()+" GROUP BY f ORDER BY f")
RETURN h

// Lo que me deben y lo que debo (hoy, no depende del periodo)
STATIC FUNCTION DashPosicion()
LOCAL cP := "ge_"+oApp:cId
RETURN DashQ1("SELECT "+;
     "(SELECT IFNULL(SUM(saldo*IF(tipo='NC',-1,1)),0) FROM "+cP+"ventas_cuota WHERE saldo > 0) AS cobrar, "+;
     "(SELECT IFNULL(SUM(v.saldo*IF(v.tipo='NC',-1,1)),0) FROM "+cP+"ventas_cuota v WHERE v.saldo > 0 AND "+DashVtoCli("v")+" < CURDATE()) AS cobrarVenc, "+;
     "(SELECT IFNULL(SUM(saldo*IF(tipocomp='NC',-1,1)),0) FROM "+cP+"compras WHERE saldo > 0 AND tipocomp <> 'RE') AS pagar, "+;
     "(SELECT IFNULL(SUM(saldo*IF(tipocomp='NC',-1,1)),0) FROM "+cP+"compras WHERE saldo > 0 AND tipocomp <> 'RE' AND IFNULL(fecvto, fecfac) < CURDATE()) AS pagarVenc")

STATIC FUNCTION DashAlertas()
LOCAL cP := "ge_"+oApp:cId
RETURN DashQ1("SELECT "+;
     "(SELECT COUNT(*) FROM "+cP+"articu WHERE stockmin > 0 AND stockact < stockmin) AS bajoMin, "+;
     "(SELECT COUNT(*) FROM "+cP+"compras WHERE saldo > 0 AND tipocomp <> 'RE' AND fecvto BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY) AS vtosN, "+;
     "(SELECT IFNULL(SUM(saldo*IF(tipocomp='NC',-1,1)),0) FROM "+cP+"compras WHERE saldo > 0 AND tipocomp <> 'RE' AND fecvto BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY) AS vtosV, "+;
     "(SELECT COUNT(DISTINCT v.cliente) FROM "+cP+"ventas_cuota v WHERE v.saldo > 0 AND "+DashVtoCli("v")+" < CURDATE() - INTERVAL 60 DAY) AS morosos")

// Vencimiento efectivo de una deuda de cliente: el cargado si es posterior a
// la factura; si no (casi siempre viene igual a la fecha), 30 dias
STATIC FUNCTION DashVtoCli(cA)
RETURN "IF("+cA+".fecvto > "+cA+".fecha, "+cA+".fecvto, "+cA+".fecha + INTERVAL 30 DAY)"

// Progreso mientras se arma una seccion: actualiza el cartel de la pagina
// (texto con entidades HTML: va por OLE) y le da un instante al navegador para
// dibujarlo. Sin esto, con muchos datos la pantalla queda en blanco.
STATIC FUNCTION DashProg(cTxt, nPct)
IF hDW == nil .OR. oWebDW == nil
   RETURN nil
ENDIF
DashOle({|| oWebDW:oOleAuto:Document:getElementById("progTxt"):innerHTML := cTxt, .t.})
DashOle({|| oWebDW:oOleAuto:Document:getElementById("progTrack"):innerHTML := '<div class="fill" id="progBar" style="width:' + LTRIM(STR(nPct)) + '%"></div>', .t.})
SysRefresh()
RETURN nil

// Signo de un renglon de venta (las NC restan)
STATIC FUNCTION DashSigDet()
RETURN "IF(LEFT(nrofac,2)='NC',-1,1)"

// Margen % de un grupo de renglones (solo los que tienen costo)
STATIC FUNCTION DashSqlMargen(cA)
LOCAL cS := "IF(LEFT("+cA+".nrofac,2)='NC',-1,1)"
RETURN "ROUND(100*SUM(IF("+cA+".pcosto > 0, ("+cA+".importe - "+cA+".pcosto*"+cA+".cantidad)*"+cS+", 0)) / "+;
       "NULLIF(SUM(IF("+cA+".pcosto > 0, "+cA+".importe*"+cS+", 0)),0),1)"

// Hasta 92 dias por dia; mas largo, por mes
STATIC FUNCTION DashAgrupa(cD, cH)
RETURN IF(STOD(STRTRAN(SUBSTR(cH,2,10),"-","")) - STOD(STRTRAN(SUBSTR(cD,2,10),"-","")) > 92, "mes", "dia")

STATIC FUNCTION DashSqlGrp(cCampo, cGrp)
RETURN IF(cGrp == "mes", "DATE_FORMAT("+cCampo+",'%Y-%m-01')", "CAST("+cCampo+" AS CHAR)")

*************************************************
** Consultas -> estructuras para JSON
*************************************************
// Varias filas: array de hashes (nombres de columna en minuscula). nil si falla.
STATIC FUNCTION DashQ(cSql)
LOCAL oQ, aRes := {}, h, i, bErr := ErrorBlock({|e| Break(e)}), oErr
BEGIN SEQUENCE
   oQ := oApp:oServer:Query(cSql)
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      h := {=>}
      FOR i := 1 TO oQ:FCount()
          h[LOWER(oQ:FieldName(i))] := DashValor(oQ:FieldGet(i))
      NEXT i
      AADD(aRes, h)
      oQ:Skip()
   ENDDO
RECOVER USING oErr
   DashLog("Consulta: " + DashErrTxt(oErr) + " | " + LEFT(cSql, 300))
   aRes := nil
END SEQUENCE
ErrorBlock(bErr)
RETURN aRes

// Una fila: hash. nil si falla o no hay filas.
STATIC FUNCTION DashQ1(cSql)
LOCAL a := DashQ(cSql)
RETURN IF(a <> nil .AND. LEN(a) > 0, a[1], nil)

STATIC FUNCTION DashValor(u)
DO CASE
   CASE VALTYPE(u) = "C" ; RETURN DashTxt(u)
   CASE VALTYPE(u) = "D" ; RETURN DashFecTxt(u)
   CASE VALTYPE(u) = "T" ; RETURN DashFecTxt(hb_TToD(u))
   CASE VALTYPE(u) = "L" ; RETURN IF(u, 1, 0)
ENDCASE
RETURN u

// Fecha de la pagina 'AAAA-MM-DD' -> literal SQL validado
STATIC FUNCTION DashFec(c)
IF VALTYPE(c) = "C" .AND. LEN(c) = 10 .AND. hb_RegExLike("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", c) .AND. !EMPTY(STOD(STRTRAN(c,"-","")))
   RETURN "'" + c + "'"
ENDIF
RETURN "'" + DashFecTxt(DATE()) + "'"

STATIC FUNCTION DashFecTxt(d)
IF EMPTY(d)
   RETURN ""
ENDIF
RETURN TRANSFORM(DTOS(d), "@R 9999-99-99")

STATIC FUNCTION DashTxt(c)
RETURN IF(VALTYPE(c) = "C", ALLTRIM(c), "")

*************************************************
** Pagina, tema, tablas, log
*************************************************
// El tema elegido se guarda por usuario en .\dashboard\dashboard.ini
STATIC FUNCTION DashTema()
LOCAL c := LOWER(ALLTRIM(GetPvProfString("temas", ALLTRIM(oApp:usuario), "claro", DashAbs(DW_INI))))
RETURN IF(c == "oscuro", "oscuro", "claro")

STATIC FUNCTION DashGuardarTema(cTema)
WritePProString("temas", ALLTRIM(oApp:usuario), IF(cTema == "claro", "claro", "oscuro"), DashAbs(DW_INI))
RETURN nil

// Ruta absoluta (las funciones de .ini de Windows sin ruta van a C:\Windows)
STATIC FUNCTION DashAbs(cFile)
LOCAL cDir := CURDIR()
IF LEFT(cFile, 2) == ".\"
   cFile := hb_CurDrive() + ":\" + IF(EMPTY(cDir), "", cDir + "\") + SUBSTR(cFile, 3)
ENDIF
RETURN cFile

STATIC FUNCTION DashCrearTablas()
LOCAL bErr := ErrorBlock({|e| Break(e)})
BEGIN SEQUENCE
   oApp:oServer:Execute("CREATE TABLE IF NOT EXISTS ge_"+oApp:cId+"ia_log ("+;
        "id INT(10) NOT NULL AUTO_INCREMENT, fecha DATETIME NULL, usuario VARCHAR(15) NOT NULL DEFAULT '', "+;
        "pregunta VARCHAR(500) NOT NULL DEFAULT '', titulo VARCHAR(200) NOT NULL DEFAULT '', "+;
        "consulta TEXT NULL, estado VARCHAR(10) NOT NULL DEFAULT '', filas INT(10) NOT NULL DEFAULT 0, "+;
        "ms INT(10) NOT NULL DEFAULT 0, calif CHAR(1) NOT NULL DEFAULT '', "+;
        "PRIMARY KEY (id), KEY calif (calif)) ENGINE=INNODB DEFAULT CHARSET=utf8")
END SEQUENCE
ErrorBlock(bErr)
RETURN nil

// Texto como literal SQL (escapa comillas y barras; vacio queda '', no NULL)
STATIC FUNCTION DashSqlTxt(c)
c := IF(VALTYPE(c) = "C", c, "")
RETURN "'" + STRTRAN(STRTRAN(c, "\", "\\"), "'", "\'") + "'"

// JSON hacia la pagina en ASCII puro: cada caracter Latin-1 como 00XX (la
// conversion de textos de OLE depende de la pagina de codigos del exe)
STATIC FUNCTION DashJsonAscii(c)
LOCAL r := "", i, n
FOR i := 1 TO LEN(c)
    n := ASC(SUBSTR(c, i, 1))
    r += IF(n < 128, CHR(n), "\u00" + LOWER(hb_NumToHex(n, 2)))
NEXT i
RETURN r

STATIC FUNCTION DashOle(bAccion)
LOCAL bErr := ErrorBlock({|e| Break(e)}), uRet, oErr
BEGIN SEQUENCE
   uRet := EVAL(bAccion)
RECOVER USING oErr
   uRet := nil
END SEQUENCE
ErrorBlock(bErr)
RETURN uRet

STATIC FUNCTION DashErrTxt(oErr)
IF VALTYPE(oErr) = "O"
   RETURN cValToChar(oErr:description) + " " + cValToChar(oErr:operation)
ENDIF
RETURN cValToChar(oErr)

STATIC FUNCTION DashLog(cTxt)
LOCAL nH
IF !hb_DirExists(".\dashboard")
   RETURN nil
ENDIF
nH := IF(FILE(DW_LOG), FOPEN(DW_LOG, 2), FCREATE(DW_LOG))
IF nH >= 0
   FSEEK(nH, 0, 2)
   FWRITE(nH, DTOC(DATE()) + " " + TIME() + " " + cTxt + CHR(13) + CHR(10))
   FCLOSE(nH)
ENDIF
RETURN nil

// Escribe la pagina si falta o es de otra version. Devuelve la ruta o "".
STATIC FUNCTION DashAsegurarHtml()
LOCAL cHtml := HtmlEmbebido(), cVer := DashVersion(cHtml), cAct
IF FILE(DW_HTML)
   cAct := MEMOREAD(DW_HTML)
   IF DashVersion(cAct) == cVer
      RETURN DW_HTML
   ENDIF
ENDIF
IF !hb_DirExists(".\dashboard")
   hb_DirCreate(".\dashboard")
ENDIF
IF !hb_MemoWrit(DW_HTML, cHtml)
   RETURN ""
ENDIF
RETURN DW_HTML

STATIC FUNCTION DashVersion(cHtml)
LOCAL n := AT("dashweb-version: ", cHtml)
RETURN IF(n > 0, SUBSTR(cHtml, n + 17, 10), "")

STATIC FUNCTION DashUrl(cFile)
LOCAL cDir := CURDIR()
IF !(SUBSTR(cFile, 2, 1) == ":" .OR. LEFT(cFile, 2) == "\\")
   cFile := hb_CurDrive() + ":\" + IF(EMPTY(cDir), "", cDir + "\") + IF(LEFT(cFile, 2) == ".\", SUBSTR(cFile, 3), cFile)
ENDIF
RETURN "file:///" + STRTRAN(STRTRAN(cFile, "\", "/"), " ", "%20")

*************************************************
** ASISTENTE DE IA
** 1) Planificador: la pregunta + el contexto del negocio -> JSON con la
**    consulta (o una respuesta de texto si no hacen falta datos).
** 2) Se valida (lista blanca de tablas del cliente), se ejecuta en solo lectura.
**    Si falla, se le devuelve el error al modelo una vez para que la corrija.
** 3) Redactor: la pregunta + los resultados -> respuesta en castellano.
** Las llamadas HTTP son asincronas: el tablero no se congela.
** Proveedor/modelo/clave: tabla config_ia de bcn_config (ver
** dashboard\config_ia.sql). Hoy GROQ; preparado para cambiar de proveedor.
*************************************************
STATIC FUNCTION IADisponible()
LOCAL h := IACfg()
RETURN !EMPTY(h["key"])

STATIC FUNCTION IACfg()
LOCAL oSer, oQ, h := { "prov" => "", "modelo" => "", "modelo2" => "", "key" => "", "url" => "" }
LOCAL bErr := ErrorBlock({|e| Break(e)}), oErr
IF hDW <> nil .AND. hDW["iaCfg"] <> nil
   RETURN hDW["iaCfg"]
ENDIF
BEGIN SEQUENCE
   oSer := ConnectTo(2)
   IF oSer <> nil
      oQ := oSer:Query("SELECT proveedor, modelo, modelo_redaccion, api_key, url FROM config_ia WHERE activo = 1 ORDER BY id DESC LIMIT 1")
      IF oQ:RecCount() > 0
         h["prov"]    := UPPER(ALLTRIM(oQ:proveedor))
         h["modelo"]  := ALLTRIM(oQ:modelo)
         h["modelo2"] := ALLTRIM(IF(EMPTY(oQ:modelo_redaccion), oQ:modelo, oQ:modelo_redaccion))
         h["key"]     := ALLTRIM(oQ:api_key)
         h["url"]     := ALLTRIM(cValToChar(IF(oQ:url == nil, "", oQ:url)))
      ENDIF
      oSer:End()
   ENDIF
RECOVER USING oErr
   DashLog("IA config: " + DashErrTxt(oErr))
END SEQUENCE
ErrorBlock(bErr)
IF hDW <> nil
   hDW["iaCfg"] := h
ENDIF
RETURN h

STATIC FUNCTION IAIniciar(nId, cPregunta)
LOCAL aMsg, i
IF EMPTY(cPregunta)
   AADD(hDW["salida"], { "id" => nId, "datos" => { "texto" => "Escrib" + CHR(237) + " tu pregunta, por ejemplo: " + CHR(191) + "cu" + CHR(225) + "nto vend" + CHR(237) + " este mes?" } })
   RETURN nil
ENDIF
IF !IADisponible()
   AADD(hDW["salida"], { "id" => nId, "datos" => { "texto" => "El asistente todav" + CHR(237) + "a no est" + CHR(225) + " configurado para esta empresa." } })
   RETURN nil
ENDIF
hDW["ia"] := { "id" => nId, "pregunta" => LEFT(cPregunta, 500), "etapa" => "plan", "intento" => 1, ;
               "t0" => hb_MilliSeconds(), "tCall" => 0, "http" => nil, "plan" => nil, ;
               "filas" => nil, "cols" => nil, "sql" => "" }
aMsg := { { "role" => "system", "content" => IAPromptPlan() } }
FOR i := MAX(1, LEN(hDW["hist"]) - 5) TO LEN(hDW["hist"])
    AADD(aMsg, hDW["hist"][i])
NEXT i
AADD(aMsg, { "role" => "user", "content" => cPregunta })
hDW["ia"]["msgs"] := aMsg
IAPost(hDW["ia"]["msgs"], hDW["ia"], .f.)
RETURN nil

// Se llama en cada tick mientras hay una pregunta en curso
STATIC FUNCTION IAAvanzar()
LOCAL hIA := hDW["ia"], cResp, hPlan, cErr, aRes, nId := hIA["id"]
IF hIA["http"] == nil
   RETURN IAFin(nId, { "error" => "No me pude comunicar con el asistente. Prob" + CHR(225) + " de nuevo en un rato." }, "ERROR")
ENDIF
IF !(DashOle({|| hIA["http"]:readyState}) == 4)
   IF hb_MilliSeconds() - hIA["tCall"] > DW_TIMEOUT
      DashOle({|| hIA["http"]:abort(), .t.})
      RETURN IAFin(nId, { "error" => "El asistente tard" + CHR(243) + " demasiado en responder. Prob" + CHR(225) + " de nuevo." }, "TIMEOUT")
   ENDIF
   RETURN nil
ENDIF
cResp := IALeerRespuesta(hIA["http"], @cErr)
hIA["http"] := nil
IF cResp == nil
   DashLog("IA http: " + cErr)
   RETURN IAFin(nId, { "error" => "El asistente no pudo responder (" + cErr + ")." }, "ERROR")
ENDIF

IF hIA["etapa"] == "plan"
   hPlan := IADecodificar(IAJsonDe(cResp))
   IF VALTYPE(hPlan) <> "H"
      RETURN IAFin(nId, { "texto" => IALimpiar(IADesdeUtf8(cResp)) }, "TEXTO")
   ENDIF
   IF !(LOWER(cValToChar(hb_HGetDef(hPlan, "tipo", ""))) == "consulta") .OR. VALTYPE(hb_HGetDef(hPlan, "sql", "")) <> "C" .OR. ;
      EMPTY(hb_HGetDef(hPlan, "sql", ""))
      RETURN IAFin(nId, { "texto" => IALimpiar(hb_HGetDef(hPlan, "texto", "No tengo una respuesta para eso.")) }, "TEXTO")
   ENDIF
   hIA["plan"] := hPlan
   hIA["sql"]  := ALLTRIM(hPlan["sql"])
   aRes := IAEjecutar(hIA["sql"], @cErr)
   IF aRes == nil
      DashLog("IA sql (" + cErr + "): " + hIA["sql"])
      IF hIA["intento"] < 2
         // Una correccion: se le devuelve el error al modelo (nunca a la pagina)
         hIA["intento"]++
         AADD(hIA["msgs"], { "role" => "assistant", "content" => hb_jsonEncode(hPlan) })
         AADD(hIA["msgs"], { "role" => "user", "content" => "La consulta no se pudo usar: " + cErr + ;
              ". Corregila respetando las reglas y devolve el JSON completo de nuevo." })
         IAPost(hIA["msgs"], hIA, .f.)
         RETURN nil
      ENDIF
      RETURN IAFin(nId, { "error" => "No pude armar esa consulta. Prob" + CHR(225) + " preguntarlo de otra forma." }, "ERROR")
   ENDIF
   hIA["filas"] := aRes[2]
   hIA["cols"]  := aRes[1]
   IF LEN(aRes[2]) = 0
      RETURN IAFin(nId, IAResultado(hIA, "No encontr" + CHR(233) + " datos para esa consulta en el per" + CHR(237) + "odo pedido."), "OK")
   ENDIF
   hIA["etapa"] := "redac"
   IAPost({ { "role" => "system", "content" => IAPromptRedac() }, ;
            { "role" => "user", "content" => IAContextoRedac(hIA) } }, hIA, .t.)
   RETURN nil
ENDIF

// Redaccion
hPlan := IADecodificar(IAJsonDe(cResp))
RETURN IAFin(nId, IAResultado(hIA, IF(VALTYPE(hPlan) = "H", hb_HGetDef(hPlan, "respuesta", ""), IALimpiar(IADesdeUtf8(cResp)))), "OK")

STATIC FUNCTION IAResultado(hIA, cTexto)
LOCAL hP := hIA["plan"], aCols := {}, i, aFmt := hb_HGetDef(hP, "columnas", {}), cNom, cFmt
FOR i := 1 TO LEN(hIA["cols"])
    cNom := hIA["cols"][i]
    cFmt := ""
    IF VALTYPE(aFmt) = "A" .AND. i <= LEN(aFmt) .AND. VALTYPE(aFmt[i]) = "H"
       cNom := IALimpiar(hb_HGetDef(aFmt[i], "nombre", cNom))
       cFmt := LOWER(hb_HGetDef(aFmt[i], "formato", ""))
    ENDIF
    AADD(aCols, { "n" => cNom, "f" => cFmt })
NEXT i
RETURN { "texto" => IALimpiar(cTexto), "titulo" => IALimpiar(hb_HGetDef(hP, "titulo", "")), ;
         "grafico" => LOWER(hb_HGetDef(hP, "grafico", "ninguno")), "cols" => aCols, "filas" => hIA["filas"] }

// Termina la pregunta: guarda el log y la memoria de la conversacion
STATIC FUNCTION IAFin(nId, hDat, cEstado)
LOCAL hIA := hDW["ia"], nLog := 0, bErr := ErrorBlock({|e| Break(e)}), oErr
BEGIN SEQUENCE
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ia_log (fecha,usuario,pregunta,titulo,consulta,estado,filas,ms) VALUES (NOW(),"+;
        DashSqlTxt(LEFT(oApp:usuario,15))+","+DashSqlTxt(LEFT(hIA["pregunta"],500))+","+;
        DashSqlTxt(LEFT(cValToChar(hb_HGetDef(hDat,"titulo","")),200))+","+DashSqlTxt(hIA["sql"])+","+;
        DashSqlTxt(cEstado)+","+ClipValue2Sql(IF(hIA["filas"] == nil, 0, LEN(hIA["filas"])))+","+;
        ClipValue2Sql(INT(hb_MilliSeconds() - hIA["t0"]))+")")
   nLog := oApp:oServer:LastInsertID()
RECOVER USING oErr
   DashLog("ia_log: " + DashErrTxt(oErr))
END SEQUENCE
ErrorBlock(bErr)
hDat["log"] := nLog
// Memoria corta para preguntas encadenadas ("y el mes anterior?")
AADD(hDW["hist"], { "role" => "user", "content" => hIA["pregunta"] })
AADD(hDW["hist"], { "role" => "assistant", "content" => IF(EMPTY(hIA["sql"]), hb_HGetDef(hDat, "texto", ""), ;
     hb_jsonEncode({ "tipo" => "consulta", "titulo" => hb_HGetDef(hDat, "titulo", ""), "sql" => hIA["sql"] })) })
DO WHILE LEN(hDW["hist"]) > 6
   hb_ADel(hDW["hist"], 1, .t.)
ENDDO
hDW["ia"] := nil
RETURN { "id" => nId, "datos" => hDat }

STATIC FUNCTION IACalificar(nLog, cCalif)
IF VALTYPE(nLog) = "N" .AND. nLog > 0 .AND. cCalif $ "BM" .AND. LEN(cCalif) = 1
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ia_log SET calif = "+ClipValue2Sql(cCalif)+" WHERE id = "+ClipValue2Sql(nLog))
ENDIF
RETURN nil

*************************************************
** HTTP asincrono (MSXML2.ServerXMLHTTP: tiene timeouts propios)
STATIC FUNCTION IAPost(aMsgs, hIA, lRedac)
LOCAL hCfg := IACfg(), hReq, oHttp, bErr := ErrorBlock({|e| Break(e)}), oErr, i, aM := {}
FOR i := 1 TO LEN(aMsgs)
    AADD(aM, { "role" => aMsgs[i]["role"], "content" => IAUtf8(aMsgs[i]["content"]) })
NEXT i
// max_tokens con margen: los modelos que razonan (gpt-oss) gastan parte en pensar
hReq := { "model" => IF(lRedac, hCfg["modelo2"], hCfg["modelo"]), "messages" => aM, ;
          "temperature" => IF(lRedac, 0.4, 0.1), "max_tokens" => IF(lRedac, 1500, 4000), ;
          "response_format" => { "type" => "json_object" } }
IF "gpt-oss" $ LOWER(hReq["model"])
   hReq["reasoning_effort"] := IF(lRedac, "low", "medium")
ENDIF
hIA["http"]  := nil
hIA["tCall"] := hb_MilliSeconds()
BEGIN SEQUENCE
   oHttp := CreateObject("MSXML2.ServerXMLHTTP.6.0")
   oHttp:setTimeouts(5000, 10000, 15000, DW_TIMEOUT)
   oHttp:Open("POST", IF(EMPTY(hCfg["url"]), IAUrl(hCfg["prov"]), hCfg["url"]), .T.)
   oHttp:SetRequestHeader("Content-Type", "application/json")
   oHttp:SetRequestHeader("Authorization", "Bearer " + hCfg["key"])
   oHttp:Send(hb_jsonEncode(hReq))
   hIA["http"] := oHttp
RECOVER USING oErr
   DashLog("IA post: " + DashErrTxt(oErr))
END SEQUENCE
ErrorBlock(bErr)
RETURN nil

STATIC FUNCTION IAUrl(cProv)
HB_SYMBOL_UNUSED(cProv)   // hoy solo GROQ (API compatible con OpenAI)
RETURN "https://api.groq.com/openai/v1/chat/completions"

// Texto del modelo (en UTF-8), o nil (cErr dice por que).
// Se leen los bytes crudos (responseBody): responseText pasa por ANSI.
STATIC FUNCTION IALeerRespuesta(oHttp, cErr)
LOCAL cTxt, hR := nil, nStatus
nStatus := DashOle({|| oHttp:status})
cTxt    := DashOle({|| oHttp:responseBody})
IF VALTYPE(cTxt) <> "C"
   cTxt := IAUtf8(cValToChar(DashOle({|| oHttp:responseText})))
ENDIF
IF EMPTY(cTxt)
   cErr := "sin respuesta"
   RETURN nil
ENDIF
hb_jsonDecode(IAJsonUnescape(cTxt), @hR)
IF VALTYPE(hR) <> "H"
   cErr := "respuesta invalida"
   RETURN nil
ENDIF
IF nStatus <> 200 .OR. hb_HHasKey(hR, "error")
   // El motivo que da el servicio (ej: modelo inexistente, clave invalida,
   // limite de uso) se muestra: lo ve solo el ADMIN y no es del sistema
   cErr := "codigo " + cValToChar(nStatus)
   IF hb_HHasKey(hR, "error") .AND. VALTYPE(hR["error"]) = "H" .AND. VALTYPE(hb_HGetDef(hR["error"], "message", nil)) = "C"
      cErr += ": " + LEFT(IADesdeUtf8(hR["error"]["message"]), 200)
   ENDIF
   DashLog("IA error: " + LEFT(cTxt, 400))
   RETURN nil
ENDIF
cTxt := DashOle({|| hR["choices"][1]["message"]["content"]})
IF VALTYPE(cTxt) <> "C"
   cErr := "respuesta sin contenido"
   RETURN nil
ENDIF
RETURN cTxt

// JSON del modelo (UTF-8) -> hash con todos los textos en Latin-1
STATIC FUNCTION IADecodificar(cJson)
LOCAL h := nil
hb_jsonDecode(IAJsonUnescape(cJson), @h)
RETURN IALatin1(h)

STATIC FUNCTION IALatin1(u)
LOCAL i, k
DO CASE
   CASE VALTYPE(u) = "C"
      RETURN IADesdeUtf8(u)
   CASE VALTYPE(u) = "A"
      FOR i := 1 TO LEN(u)
          u[i] := IALatin1(u[i])
      NEXT i
   CASE VALTYPE(u) = "H"
      FOR EACH k IN hb_HKeys(u)
          u[k] := IALatin1(u[k])
      NEXT
ENDCASE
RETURN u

// Este Harbour no decodifica bien los \uXXXX de JSON: se pasan antes a bytes
// UTF-8 (incluidos los pares sustitutos). \ y \" quedan como estan.
STATIC FUNCTION IAJsonUnescape(c)
LOCAL r := "", i := 1, nL := LEN(c), ch, cp, cp2
IF !("\u" $ c)
   RETURN c
ENDIF
DO WHILE i <= nL
   ch := SUBSTR(c, i, 1)
   IF ch == "\" .AND. i < nL
      IF SUBSTR(c, i + 1, 1) == "u" .AND. hb_RegExLike("[0-9a-fA-F]{4}", SUBSTR(c, i + 2, 4))
         cp := hb_HexToNum(SUBSTR(c, i + 2, 4))
         i += 6
         IF cp >= 55296 .AND. cp <= 56319 .AND. SUBSTR(c, i, 2) == "\u"
            cp2 := hb_HexToNum(SUBSTR(c, i + 2, 4))
            cp  := 65536 + (cp - 55296) * 1024 + (cp2 - 56320)
            i   += 6
         ENDIF
         IF cp == 34 .OR. cp == 92
            r += "\" + CHR(cp)          // comilla o barra: siguen escapadas
         ELSEIF cp < 32
            r += " "
         ELSE
            r += IACodigoUtf8(cp)
         ENDIF
      ELSE
         r += ch + SUBSTR(c, i + 1, 1)
         i += 2
      ENDIF
   ELSE
      r += ch
      i++
   ENDIF
ENDDO
RETURN r

STATIC FUNCTION IACodigoUtf8(cp)
DO CASE
   CASE cp < 128   ; RETURN CHR(cp)
   CASE cp < 2048  ; RETURN CHR(192 + INT(cp / 64)) + CHR(128 + cp % 64)
   CASE cp < 65536 ; RETURN CHR(224 + INT(cp / 4096)) + CHR(128 + INT(cp / 64) % 64) + CHR(128 + cp % 64)
ENDCASE
RETURN CHR(240 + INT(cp / 262144)) + CHR(128 + INT(cp / 4096) % 64) + CHR(128 + INT(cp / 64) % 64) + CHR(128 + cp % 64)

// Texto que manda la pagina con encodeURIComponent (UTF-8 en %XX) -> Latin-1
STATIC FUNCTION IADesdeUrl(c)
LOCAL r := "", i := 1, nL := LEN(c), ch
DO WHILE i <= nL
   ch := SUBSTR(c, i, 1)
   IF ch == "%" .AND. i + 2 <= nL
      r += CHR(hb_HexToNum(SUBSTR(c, i + 1, 2)))
      i += 3
   ELSE
      r += ch
      i++
   ENDIF
ENDDO
RETURN IADesdeUtf8(r)

// El JSON del modelo puede venir rodeado de texto o de ```
STATIC FUNCTION IAJsonDe(c)
LOCAL n1 := AT("{", c), n2 := RAT("}", c)
RETURN IF(n1 > 0 .AND. n2 > n1, SUBSTR(c, n1, n2 - n1 + 1), c)

*************************************************
** Validacion y ejecucion (solo lectura, solo tablas del cliente)
** Devuelve { aColumnas, aFilas } o nil (cErr = motivo, para el modelo)
STATIC FUNCTION IAEjecutar(cSql, cErr)
LOCAL oSrv := oApp:oServer, oQ, aFil := {}, aCol := {}, aF, i, lTrans := .f.
LOCAL bErr := ErrorBlock({|e| Break(e)}), oErr
cErr := IAValidar(@cSql)
IF !EMPTY(cErr)
   ErrorBlock(bErr)
   RETURN nil
ENDIF
BEGIN SEQUENCE
   IF EMPTY(cErr)
      oSrv:Execute("START TRANSACTION READ ONLY")
      lTrans := .t.
      oQ := oSrv:Query(cSql)
      FOR i := 1 TO oQ:FCount()
          AADD(aCol, LOWER(oQ:FieldName(i)))
      NEXT i
      oQ:GoTop()
      DO WHILE !oQ:Eof() .AND. LEN(aFil) < 200
         aF := ARRAY(oQ:FCount())
         FOR i := 1 TO oQ:FCount()
             aF[i] := DashValor(oQ:FieldGet(i))
         NEXT i
         AADD(aFil, aF)
         oQ:Skip()
      ENDDO
   ENDIF
RECOVER USING oErr
   cErr := "error de MySQL: " + cValToChar(IF(VALTYPE(oErr) = "O", oErr:description, oErr))
END SEQUENCE
IF lTrans
   DashOle({|| oSrv:Execute("ROLLBACK"), .t.})
ENDIF
ErrorBlock(bErr)
RETURN IF(EMPTY(cErr), { aCol, aFil }, nil)

// Tablas de negocio que el asistente puede leer (nunca usuarios, claves, config)
STATIC FUNCTION IATablas()
RETURN { "ventas_encab", "ventas_det", "ventas_cuota", "ventivadet", "concfact", "pagos", "pagcon", ;
         "compras", "compradet", "ordpag", "ordcon", "articu", "clientes", "provee", "rubros", "marcas", ;
         "deptos", "vendedores", "forpag", "plancont", "cajadiaria", "cajadiaria_det" }

// Chequeo lexico. Agrega LIMIT si falta. Devuelve "" si esta bien.
STATIC FUNCTION IAValidar(cSql)
LOCAL c, cL, aProh, i, aTab, aM, cId := LOWER(oApp:cId), cT
cSql := ALLTRIM(STRTRAN(STRTRAN(cSql, CHR(13), " "), CHR(10), " "))
DO WHILE RIGHT(cSql, 1) == ";"
   cSql := ALLTRIM(LEFT(cSql, LEN(cSql) - 1))
ENDDO
// Sin los textos entre comillas, para no confundir su contenido con SQL
c  := IASinTextos(cSql)
cL := LOWER(STRTRAN(c, "`", ""))
IF !(LEFT(cL, 6) == "select")
   RETURN "tiene que ser un unico SELECT"
ENDIF
aProh := { ";", "--", "#", "/*", "*/", "information_schema", "performance_schema", "mysql.", " into ", ;
           "outfile", "dumpfile", "load_file", "sleep(", "benchmark(", "get_lock", "release_lock", ;
           "for update", "lock in share", "procedure", "database(", "schema(", "user(", "version(", ;
           "@@", "connection_id", "found_rows", "handler ", "ia_log" }
FOR i := 1 TO LEN(aProh)
    IF aProh[i] $ cL
       RETURN "usa algo no permitido (" + ALLTRIM(aProh[i]) + ")"
    ENDIF
NEXT i
// Toda tabla del prefijo tiene que ser del cliente actual y de la lista blanca
aTab := IATablas()
aM := hb_RegExAll("ge_[0-9a-z_]+", cL,,,, 0, .t.)
FOR i := 1 TO LEN(aM)
    cT := IF(VALTYPE(aM[i]) = "A", aM[i][1], aM[i])
    IF !(LEFT(cT, 3 + LEN(cId)) == "ge_" + cId) .OR. ASCAN(aTab, {|t| t == SUBSTR(cT, 4 + LEN(cId))}) = 0
       RETURN "usa una tabla no permitida"
    ENDIF
NEXT i
// Cualquier palabra que sea una tabla real no permitida, u otra base (base.algo)
cT := IANombresProhibidos(cL)
IF !EMPTY(cT)
   RETURN cT
ENDIF
// Lo que sigue a FROM / JOIN: una tabla del prefijo o una subconsulta
aM := hb_RegExAll("\b(?:from|join|straight_join)\s+([^\s,()]+|\()", cL,,,, 2, .t.)
FOR i := 1 TO LEN(aM)
    cT := IF(VALTYPE(aM[i]) = "A", aM[i][1], aM[i])
    IF !(cT == "(") .AND. !(LEFT(cT, 3 + LEN(cId)) == "ge_" + cId)
       RETURN "solo se pueden usar las tablas del sistema"
    ENDIF
NEXT i
// Sin uniones con coma (FROM a, b): usar JOIN
IF hb_RegExHas("\bfrom\s+[^\s,()]+(\s+(as\s+)?[a-z_][a-z0-9_]*)?\s*,", cL)
   RETURN "usa JOIN en lugar de tablas separadas por coma"
ENDIF
IF !hb_RegExLike(".*\blimit\s+[0-9]+(\s*,\s*[0-9]+)?\s*$", cL)
   cSql += " LIMIT 200"
ENDIF
RETURN ""

// Recorre las palabras de la consulta: si alguna es una tabla de esta base que
// no esta en la lista blanca, o es el nombre de otra base seguido de un punto,
// la rechaza. Las listas de tablas y bases se leen una vez por base.
STATIC FUNCTION IANombresProhibidos(cL)
STATIC cBaseCache := "", hTablas, hBases
LOCAL oQ, cDb, aW, i, cW, nPos, aTab := IATablas(), cId := LOWER(oApp:cId), lOk
cDb := LOWER(cValToChar(oApp:oServer:Query("SELECT DATABASE() AS d"):d))
IF !(cDb == cBaseCache)
   hTablas := {=>}
   hBases  := {=>}
   oQ := oApp:oServer:Query("SHOW TABLES")
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      hTablas[LOWER(ALLTRIM(cValToChar(oQ:FieldGet(1))))] := .t.
      oQ:Skip()
   ENDDO
   oQ := oApp:oServer:Query("SHOW DATABASES")
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      hBases[LOWER(ALLTRIM(cValToChar(oQ:FieldGet(1))))] := .t.
      oQ:Skip()
   ENDDO
   cBaseCache := cDb
ENDIF
aW := hb_RegExAll("[a-z_][a-z0-9_$]*", cL,,,, 0, .f.)
FOR i := 1 TO LEN(aW)
    cW   := aW[i][1][1]
    nPos := aW[i][1][3]          // posicion final de la palabra
    IF hb_HHasKey(hBases, cW) .AND. SUBSTR(cL, nPos + 1, 1) == "."
       RETURN "usa otra base de datos"
    ENDIF
    IF hb_HHasKey(hTablas, cW)
       lOk := LEFT(cW, 3 + LEN(cId)) == "ge_" + cId .AND. ASCAN(aTab, {|t| t == SUBSTR(cW, 4 + LEN(cId))}) > 0
       IF !lOk
          RETURN "usa una tabla no permitida"
       ENDIF
    ENDIF
NEXT i
RETURN ""

// Vacia el contenido de los textos entre comillas ('...' o "..."), para que
// lo que diga un texto no se confunda con SQL
STATIC FUNCTION IASinTextos(c)
LOCAL r := "", i := 1, ch, cQ := "", nL := LEN(c)
DO WHILE i <= nL
   ch := SUBSTR(c, i, 1)
   IF EMPTY(cQ)
      r += ch
      IF ch == "'" .OR. ch == '"'
         cQ := ch
      ENDIF
   ELSEIF ch == "\"
      i++                                     // caracter escapado
   ELSEIF ch == cQ
      IF SUBSTR(c, i + 1, 1) == cQ
         i++                                  // '' dentro del texto
      ELSE
         r  += ch
         cQ := ""
      ENDIF
   ENDIF
   i++
ENDDO
RETURN r


*************************************************
** Prompts
*************************************************
STATIC FUNCTION IAPromptPlan()
LOCAL cP := "ge_"+oApp:cId, d := DATE(), aDias := { "domingo","lunes","martes","miercoles","jueves","viernes","sabado" }
LOCAL cEj := IAEjemplos()
RETURN ;
"Sos el asistente de datos del sistema de gestion de una empresa argentina. Tu tarea es convertir la pregunta del duenio "+;
"del negocio en UNA consulta SELECT de MySQL 5 (MariaDB 10.0: sin WITH, sin funciones de ventana) o, si la pregunta no "+;
"necesita datos, contestar en texto. "+;
"Hoy es "+aDias[DOW(d)]+" "+DashFecTxt(d)+". 'Este mes' = desde "+DashFecTxt(d - DAY(d) + 1)+" hasta hoy. "+;
"'El mes pasado' = el mes calendario anterior completo. 'Este anio' = desde "+STR(YEAR(d),4)+"-01-01. "+;
"Si comparan este mes con el mes pasado (o este anio con el anterior), compara los MISMOS dias: del 1 al "+STR(DAY(d),2)+" de cada mes (o hasta la misma fecha del anio anterior), y ponelo en el titulo. "+;
"Si no dicen periodo y hace falta uno, usa este mes. "+;
"RESPONDE SIEMPRE con un unico objeto JSON, sin texto alrededor, con una de estas dos formas: "+;
'{"tipo":"consulta","titulo":"titulo corto para mostrar","sql":"SELECT ...","grafico":"barras|lineas|torta|ninguno",'+;
'"columnas":[{"nombre":"Nombre visible","formato":"texto|moneda|numero|cantidad|porcentaje|fecha"}]} '+;
'o {"tipo":"respuesta","texto":"..."}. '+;
"En 'columnas' va una entrada por cada columna del SELECT, en el mismo orden, con un nombre claro en castellano. "+;
"grafico: barras para rankings o comparaciones (hasta 15 filas), lineas para evolucion en el tiempo, torta para partes "+;
"de un total (hasta 8 filas), ninguno para listados largos o un solo numero. "+;
;
"DATOS DISPONIBLES (prefijo de tablas "+cP+"): "+;
cP+"ventas_encab = un comprobante de venta por fila: ticomp (FC factura, NC nota de credito, ND nota de debito), letra, "+;
"numcomp, codcli, fecha, hora (texto 'HH:MM:SS'), neto, iva, importe (total), usuario, vendedor (texto). "+;
"Venta neta = SUM(importe*IF(ticomp='NC',-1,1)) con ticomp IN ('FC','NC','ND'). Cantidad de ventas = facturas FC. "+;
cP+"ventas_det = renglones vendidos: codart, detart, cantidad, punit, importe (total del renglon con IVA), neto, fecha, "+;
"codcli, nrofac (empieza con el tipo: las 'NC...' restan, usar IF(LEFT(nrofac,2)='NC',-1,1)), pcosto (costo UNITARIO con "+;
"IVA, 0 si no se cargo). Margen = importe - pcosto*cantidad, solo con pcosto > 0. Excluir codart = 0. "+;
cP+"ventas_cuota = deuda de clientes por comprobante: tipo (FC/NC), letra, numero, cliente, fecha, fecvto, importe, saldo "+;
"(lo que falta cobrar; las NC restan). Deuda de clientes SIEMPRE de esta tabla con saldo > 0. "+;
cP+"concfact = como se cobro cada venta: ticomp, fecha, codcon (forma de pago -> "+cP+"forpag.codigo, nombre), importe. "+;
cP+"pagos = recibos de cobranza: numero, cliente, fecha, total. "+cP+"pagcon = conceptos del recibo: numero, tipocon "+;
"(1 efectivo, 2 transferencia, 3 cheque, 4 tarjeta, 5 retenciones, 7 anticipo, 8 Mercado Pago), importe. "+;
cP+"compras = comprobantes de proveedores: codpro, tipocomp (FC, NC, RE remito: excluir RE), letra, numfac, fecfac "+;
"(fecha), fecvto (vencimiento), neto, iva, importe, saldo (lo que falta pagar; NC restan), codcue (-> "+cP+"plancont). "+;
cP+"compradet = renglones de compra: codpro, tipocomp, letra, numfac, codart, cantidad, punit. "+;
cP+"ordpag = pagos a proveedores: numero, proveedor, fecha, total, observa. Excluir observa LIKE 'AJUSTE%' (no son pagos). "+;
cP+"articu = articulos: codigo, nombre, preciocos (costo), precioven (precio de venta), stockact (stock actual), "+;
"stockmin, prov (-> provee), marca (-> marcas), rubro (-> rubros), depto (-> deptos), fecultcom (ultima compra). "+;
cP+"clientes: codigo, nombre, cuit, localidad, telefono, vendedor (-> vendedores). "+cP+"provee: codigo, nombre, cuit, "+;
"saldo (anticipo a favor nuestro). "+cP+"rubros, "+cP+"marcas, "+cP+"deptos, "+cP+"vendedores: codigo, nombre. "+;
cP+"cajadiaria = cierres de caja: id, fecha, caja, hora, saldo (diferencia de caja). "+cP+"cajadiaria_det: id_caja, "+;
"concepto, debe, haber, efectivo. "+;
;
"REGLAS: 1) Un solo SELECT, sin punto y coma, sin comentarios. 2) Usa SOLO las tablas y columnas de arriba; si un dato "+;
"no esta, decilo en una respuesta de texto. 3) Fechas como 'AAAA-MM-DD'; textos entre comillas simples. 4) Para mostrar "+;
"nombres hace JOIN con articu, clientes, provee, rubros, etc. (alias cortos: a, c, d, p, v, r). No muestres codigos internos (de articulo, cliente o proveedor) salvo que los pidan: mostra el nombre. 5) Si agrupas por "+;
"nombre, agrupa tambien por el codigo. 6) Redondea importes a 2 decimales y porcentajes a 1. 7) Ordena de mayor a menor "+;
"en rankings y pone LIMIT (10 por defecto, maximo 100). Si preguntan cual es el que mas o el que menos (producto, rubro, cliente, etc.), devolve el ranking de 10 y no solo el primero, asi se ve el contexto. Si piden margen, trae el importe y el porcentaje. 8) Nunca escribas datos. "+;
"9) En el campo texto de una respuesta, y en los titulos, JAMAS menciones tablas, columnas, SQL, prefijos, la base de "+;
"datos ni nada tecnico: habla en terminos de negocio (ventas, clientes, productos, proveedores, caja, stock). Si piden la "+;
"estructura del sistema o datos tecnicos, responde que no podes compartir informacion tecnica y ofrece ayuda con "+;
"preguntas de negocio. 10) Si preguntan que podes hacer, contesta con ejemplos concretos: ventas por periodo, rubro o "+;
"vendedor, margen, productos mas vendidos, horarios de mayor venta, deudas de clientes, pagos a proveedores y "+;
"vencimientos, stock bajo o sin movimiento, cobranzas y caja. Responde en castellano rioplatense, con voseo."+;
IF(EMPTY(cEj), "", " EJEMPLOS QUE EL USUARIO MARCO COMO BUENOS: " + cEj)

STATIC FUNCTION IAPromptRedac()
RETURN ;
"Sos un analista que le explica resultados al duenio de un comercio argentino. Te paso su pregunta y los datos que "+;
"salieron del sistema. Escribi la respuesta en castellano rioplatense con voseo, en 2 a 4 oraciones, directa y util: "+;
"primero la respuesta concreta, despues lo mas destacado (el mayor, el menor, una concentracion, una tendencia) y, si "+;
"aplica, una sugerencia breve. Importes con signo y separador de miles argentino ($ 1.234.567; con decimales solo si "+;
"son menores a 100), porcentajes con coma (12,5 %), fechas como 15/10/2026. No inventes nada que no este en los datos. "+;
"Si hay mas filas de las que ves, aclaralo sin dar numeros falsos. Si la consulta trae un ranking, destaca el primero y compara con los siguientes; nunca digas que es el unico dato salvo que de verdad haya una sola fila posible. Nunca menciones tablas, columnas, SQL ni nada "+;
"tecnico, y no repitas la tabla entera. Sin markdown, sin listas, sin emojis. "+;
'Responde solo un JSON: {"respuesta":"..."}'

STATIC FUNCTION IAContextoRedac(hIA)
LOCAL hP := hIA["plan"], aF := hIA["filas"], aMuestra := {}, i, aNom := {}, aFmt := hb_HGetDef(hP, "columnas", {})
FOR i := 1 TO MIN(40, LEN(aF))
    AADD(aMuestra, aF[i])
NEXT i
FOR i := 1 TO LEN(hIA["cols"])
    AADD(aNom, IF(VALTYPE(aFmt) = "A" .AND. i <= LEN(aFmt) .AND. VALTYPE(aFmt[i]) = "H", hb_HGetDef(aFmt[i], "nombre", hIA["cols"][i]), hIA["cols"][i]))
NEXT i
RETURN "Pregunta: " + hIA["pregunta"] + CHR(10) + ;
       "Hoy: " + DashFecTxt(DATE()) + CHR(10) + ;
       "Titulo: " + hb_HGetDef(hP, "titulo", "") + CHR(10) + ;
       "Columnas: " + hb_jsonEncode(aNom) + CHR(10) + ;
       "Filas (" + ALLTRIM(STR(LEN(aF))) + " en total" + IF(LEN(aF) > 40, ", se muestran las primeras 40", "") + "): " + ;
       hb_jsonEncode(aMuestra)

// Preguntas bien calificadas como ejemplos (pregunta -> consulta)
STATIC FUNCTION IAEjemplos()
LOCAL oQ, c := "", bErr := ErrorBlock({|e| Break(e)})
BEGIN SEQUENCE
   oQ := oApp:oServer:Query("SELECT pregunta, consulta FROM ge_"+oApp:cId+"ia_log WHERE calif = 'B' AND estado = 'OK' "+;
                            "ORDER BY id DESC LIMIT 5")
   oQ:GoTop()
   DO WHILE !oQ:Eof()
      c += "Pregunta: " + ALLTRIM(oQ:pregunta) + " -> SQL: " + ALLTRIM(oQ:consulta) + ". "
      oQ:Skip()
   ENDDO
END SEQUENCE
ErrorBlock(bErr)
RETURN c

*************************************************
** Texto: Latin-1 <-> UTF-8 (sin depender del codepage del exe) y limpieza
*************************************************
STATIC FUNCTION IAUtf8(c)
LOCAL i, n, r := ""
IF VALTYPE(c) <> "C"
   RETURN ""
ENDIF
FOR i := 1 TO LEN(c)
    n := ASC(SUBSTR(c, i, 1))
    IF n < 128
       r += CHR(n)
    ELSE
       r += CHR(192 + INT(n / 64)) + CHR(128 + n % 64)
    ENDIF
NEXT i
RETURN r

STATIC FUNCTION IADesdeUtf8(c)
LOCAL i := 1, n, n2, n3, r := "", cp, nL := LEN(c)
DO WHILE i <= nL
   n := ASC(SUBSTR(c, i, 1))
   IF n < 128
      r += CHR(n)
      i++
   ELSEIF n >= 192 .AND. n < 224 .AND. i < nL
      n2 := ASC(SUBSTR(c, i + 1, 1))
      cp := (n - 192) * 64 + (n2 - 128)
      r += IF(cp < 256, CHR(cp), "?")
      i += 2
   ELSEIF n >= 224 .AND. n < 240 .AND. i + 1 < nL
      n2 := ASC(SUBSTR(c, i + 1, 1))
      n3 := ASC(SUBSTR(c, i + 2, 1))
      cp := (n - 224) * 4096 + (n2 - 128) * 64 + (n3 - 128)
      DO CASE
         CASE cp == 8216 .OR. cp == 8217 ; r += "'"
         CASE cp == 8220 .OR. cp == 8221 ; r += '"'
         CASE cp == 8211 .OR. cp == 8212 ; r += "-"
         CASE cp == 8230                 ; r += "..."
         CASE cp == 8364                 ; r += "EUR"
         OTHERWISE                       ; r += " "
      ENDCASE
      i += 3
   ELSE
      i += IF(n >= 240, 4, 1)
   ENDIF
ENDDO
RETURN r

// Saca markdown y cualquier rastro tecnico que se le escape al modelo
STATIC FUNCTION IALimpiar(c)
IF VALTYPE(c) <> "C"
   RETURN ""
ENDIF
c := STRTRAN(STRTRAN(STRTRAN(c, "**", ""), "`", ""), "##", "")
IF "ge_" $ LOWER(c) .OR. "select " $ LOWER(c)
   c := "Tengo la respuesta, pero no puedo mostrar detalles t" + CHR(233) + "cnicos del sistema."
ENDIF
RETURN ALLTRIM(c)

*************************************************
** dashboard\dashboard.html embebido. NO EDITAR A MANO: la fuente es
** FUENTES2\dashboard\dashboard.html y este bloque se regenera con
** dashboard\embeber.ps1. Debe ser ASCII puro.
*************************************************
STATIC FUNCTION HtmlEmbebido()
LOCAL cHtml
//<<HTML
   TEXT INTO cHtml
<!DOCTYPE html>
<html lang="es">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta charset="utf-8">
<title>Tablero</title>
<!-- dashweb-version: 2026101603 -->
<!-- Este archivo lo escribe BCN.exe (DASHWEB.PRG) y lo reemplaza cuando cambia la version.
     Fuente: FUENTES2\\dashboard\\dashboard.html (ASCII puro: acentos como &aacute; o \\u00e1).
     Se embebe en DASHWEB.PRG con dashboard\\embeber.ps1. -->
<script>
  window.onerror = function (m, u, l) { document.title = "ERR " + l + ": " + m; };
</script>
<style>
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }
body { font-family: "Segoe UI", Tahoma, Arial, sans-serif; font-size: 13px; -ms-user-select: none; }
#req, #resp { position: absolute; left: -9999px; top: 0; width: 10px; height: 10px; }
.num { font-feature-settings: "tnum" 1; }

/* ---------- temas (IE11 no tiene variables CSS: reglas por tema) ---------- */
.t-oscuro { background: #0b0f1f; color: #e7eaf6; }
.t-claro  { background: #eef1f7; color: #1a2040; }
.t-oscuro #cont { scrollbar-face-color: #232b4d; scrollbar-track-color: #0b0f1f; scrollbar-arrow-color: #5f6893;
                  scrollbar-shadow-color: #232b4d; scrollbar-highlight-color: #232b4d; scrollbar-3dlight-color: #0b0f1f; scrollbar-darkshadow-color: #0b0f1f; }
.t-claro  #cont { scrollbar-face-color: #cfd5e3; scrollbar-track-color: #eef1f7; scrollbar-arrow-color: #8a92b4;
                  scrollbar-shadow-color: #cfd5e3; scrollbar-highlight-color: #cfd5e3; scrollbar-3dlight-color: #eef1f7; scrollbar-darkshadow-color: #eef1f7; }
.t-oscuro .card { background: #141a30; border: 1px solid #222a48; }
.t-claro  .card { background: #ffffff; border: 1px solid #e1e5ef; box-shadow: 0 1px 2px rgba(20,30,70,.04), 0 10px 28px rgba(20,30,70,.06); }
.t-oscuro .mut { color: #8a92b4; }
.t-claro  .mut { color: #687090; }
.t-oscuro #top { background: #0b0f1f; border-bottom: 1px solid #1b2240; }
.t-claro  #top { background: #eef1f7; border-bottom: 1px solid #dfe3ee; }
.t-oscuro .chip { background: #151b33; border: 1px solid #262e50; color: #c5cbe6; }
.t-claro  .chip { background: #ffffff; border: 1px solid #dde2ee; color: #3a4266; }
.t-oscuro .chip:hover { border-color: #3a4475; }
.t-claro  .chip:hover { border-color: #b9c1d8; }
.t-oscuro .tabla th { color: #8a92b4; border-bottom: 1px solid #252d4d; }
.t-claro  .tabla th { color: #687090; border-bottom: 1px solid #e3e7f0; }
.t-oscuro .tabla td { border-bottom: 1px solid #1c2340; }
.t-claro  .tabla td { border-bottom: 1px solid #eef0f6; }
.t-oscuro .tabla tr:hover td { background: #192040; }
.t-claro  .tabla tr:hover td { background: #f6f8fc; }
.t-oscuro .track { background: #1d2443; }
.t-claro  .track { background: #eef1f7; }
.t-oscuro .esq { background: #1a2140; }
.t-claro  .esq { background: #e9edf5; }
.t-oscuro .inp { background: #10152a; border: 1px solid #283058; color: #e7eaf6; }
.t-claro  .inp { background: #ffffff; border: 1px solid #d6dbe8; color: #1a2040; }
.t-oscuro .tabs span { color: #8a92b4; }
.t-claro  .tabs span { color: #687090; }
.t-oscuro .tabs span.on { background: #222a4a; color: #fff; }
.t-claro  .tabs span.on { background: #1a2040; color: #fff; }
.t-oscuro .burbuja-ia { background: #141a30; border: 1px solid #222a48; }
.t-claro  .burbuja-ia { background: #ffffff; border: 1px solid #e1e5ef; }
.t-oscuro .alerta { background: #171d36; }
.t-claro  .alerta { background: #f7f8fc; }
.t-oscuro .sep { border-top: 1px solid #1f2745; }
.t-claro  .sep { border-top: 1px solid #edf0f6; }

/* ---------- estructura ---------- */
#app { position: absolute; left: 0; top: 0; right: 0; bottom: 0; }
#side { position: absolute; left: 0; top: 0; bottom: 0; width: 214px; background: #111632; color: #c9cfe8;
        overflow-y: auto; overflow-x: hidden;
        scrollbar-face-color: #232b4d; scrollbar-track-color: #111632; scrollbar-arrow-color: #5f6893;
        scrollbar-shadow-color: #232b4d; scrollbar-highlight-color: #232b4d; scrollbar-3dlight-color: #111632; scrollbar-darkshadow-color: #111632; }
/* El pie (usuario y tema) queda abajo si sobra lugar; si no entra todo, el menu se desplaza */
#sideIn { position: relative; min-height: 100%; padding-bottom: 118px; }
@media (max-height: 640px) {
  .logo { height: 56px; padding-top: 12px; }
  .nav { padding-top: 2px; }
  .nav a { padding-top: 7px; padding-bottom: 7px; margin-bottom: 1px; }
  .nav a svg { top: 6px; }
  .nav .grupo { padding-top: 10px; }
}
#main { position: absolute; left: 214px; top: 0; right: 0; bottom: 0; }
#top { position: absolute; left: 0; right: 0; top: 0; height: 70px; padding: 14px 26px 0 26px; z-index: 5; }
#cont { position: absolute; left: 0; right: 0; top: 70px; bottom: 0; overflow-y: auto; overflow-x: hidden; padding: 20px 26px 30px 26px; }

.logo { height: 70px; padding: 18px 20px 0 20px; }
/* Logo bcnsoft: Montserrat ExtraBold convertida a trazos (no depende de fuentes instaladas) */
.logo .marca { display: block; }
.logo span { display: block; font-size: 10.5px; letter-spacing: 1.6px; text-transform: uppercase; color: #8a92b4; margin: 3px 0 0 2px; }
.nav { padding: 10px 10px; }
.nav a { display: block; position: relative; padding: 10px 12px 10px 42px; margin-bottom: 3px; border-radius: 10px; color: #aab1d2;
         text-decoration: none; cursor: pointer; font-size: 13.5px; transition: background .15s, color .15s; }
.nav a svg { position: absolute; left: 13px; top: 9px; }
.nav a:hover { background: #1a2046; color: #fff; }
.nav a.on { background: #FFAF22; color: #141833; font-weight: 600; }
.nav .grupo { font-size: 10.5px; letter-spacing: 1.2px; text-transform: uppercase; color: #5f6893; padding: 16px 12px 6px 12px; }
.pie { position: absolute; left: 0; right: 0; bottom: 0; padding: 14px 18px; border-top: 1px solid #1e2550; }
.pie .usu { font-size: 12px; color: #8a92b4; }
.pie .usu b { color: #e7eaf6; font-weight: 600; display: block; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tema { margin-top: 12px; background: #0c1028; border-radius: 10px; padding: 3px; height: 34px; position: relative; cursor: pointer; }
.tema div { position: absolute; top: 3px; width: 50%; height: 28px; text-align: center; line-height: 28px; font-size: 12px; color: #8a92b4; z-index: 2; }
.tema .izq { left: 0; } .tema .der { right: 0; }
.tema .sel { position: absolute; top: 3px; left: 3px; width: 50%; height: 28px; background: #232a52; border-radius: 8px; z-index: 1; transition: left .25s ease; }
.tema.claro .sel { left: 50%; margin-left: -3px; background: #FFAF22; }
.tema.claro .der { color: #141833; font-weight: 600; }
.tema.oscuro .izq { color: #fff; font-weight: 600; }
.tema svg { vertical-align: middle; margin-right: 5px; margin-top: -2px; }

.tit { float: left; }
.tit h1 { margin: 0; font-size: 21px; font-weight: 600; letter-spacing: -.3px; }
.tit div { font-size: 12.5px; margin-top: 3px; }
.periodo { float: right; margin-top: 4px; position: relative; }
.cerrar { float: right; margin: 4px 0 0 12px; padding: 7px 14px 7px 11px; border-radius: 20px; cursor: pointer; font-size: 12.5px; font-weight: 600;
          background: rgba(255,107,107,.14); color: #ff6b6b; transition: background .15s, color .15s; }
.cerrar:hover { background: #ff6b6b; color: #fff; }
.cerrar svg { vertical-align: middle; margin: -2px 5px 0 0; }
.chip { display: inline-block; padding: 7px 12px; border-radius: 20px; font-size: 12.5px; cursor: pointer; margin-left: 5px; transition: border-color .15s; }
.chip.on { background: #FFAF22 !important; border-color: #FFAF22 !important; color: #141833 !important; font-weight: 600; }
.chip.ico { padding: 7px 9px 6px 9px; }
.chip.ico svg { vertical-align: middle; }
/* Periodo "Otro": panel flotante debajo de los chips (en linea no entraba y quedaba tapado por #cont) */
.otro { display: none; position: absolute; right: 0; top: 42px; z-index: 30; padding: 14px 16px; border-radius: 14px; white-space: nowrap; }
.otro.on { display: block; }
.t-oscuro .otro { background: #141a30; border: 1px solid #2a3358; box-shadow: 0 12px 32px rgba(0,0,0,.45); }
.t-claro  .otro { background: #ffffff; border: 1px solid #dde2ee; box-shadow: 0 12px 32px rgba(20,30,70,.16); }
.otro .campo { display: inline-block; vertical-align: bottom; margin-right: 8px; }
.otro .campo div { font-size: 11px; margin: 0 0 4px 2px; }
.otro .chip { vertical-align: bottom; margin-left: 2px; }
.inp { border-radius: 8px; padding: 6px 9px; font-family: inherit; font-size: 12.5px; outline: none; width: 96px; -ms-user-select: text; }
.inp:focus { border-color: #FFAF22 !important; }

/* ---------- grilla ---------- */
.fila { margin: 0 -8px; overflow: hidden; }
.fila:after { content: ""; display: table; clear: both; }
.col { float: left; padding: 0 8px; margin-bottom: 16px; }
.c3 { width: 25%; } .c4 { width: 33.333%; } .c5 { width: 41.666%; } .c6 { width: 50%; } .c7 { width: 58.333%; } .c8 { width: 66.666%; } .c12 { width: 100%; }
.card { border-radius: 16px; padding: 18px 20px; position: relative; overflow: hidden; }
.card h3 { margin: 0 0 2px 0; font-size: 14.5px; font-weight: 600; }
.card .sub { font-size: 12px; margin-bottom: 14px; }
.card .acc { position: absolute; right: 18px; top: 16px; }

/* ---------- KPIs ---------- */
.kpi { width: 16.666%; }
@media (max-width: 1500px) { .kpi { width: 33.333%; } }
.kpi .card { padding: 16px 18px 12px 18px; height: 132px; }
.kpi .lab { font-size: 11px; text-transform: uppercase; letter-spacing: .8px; font-weight: 600; }
.kpi .val { font-size: 25px; font-weight: 700; letter-spacing: -.6px; margin-top: 7px; white-space: nowrap; }
.kpi .pie2 { margin-top: 6px; font-size: 11.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.kpi .spark { position: absolute; right: 0; bottom: 0; left: 0; height: 40px; opacity: .9; }
.delta { display: inline-block; font-weight: 600; font-size: 11.5px; padding: 2px 7px; border-radius: 10px; margin-right: 6px; }
.d-up { background: rgba(52,211,153,.15); color: #19b382; }
.d-dn { background: rgba(248,113,113,.16); color: #ef5b5b; }
.d-ne { background: rgba(138,146,180,.16); color: #7f88ad; }

/* ---------- graficos ---------- */
.graf { position: relative; }
.graf svg text { font-family: "Segoe UI", Tahoma, Arial, sans-serif; }
#tip { position: absolute; display: none; z-index: 50; pointer-events: none; background: #0a0d1c; color: #fff; border-radius: 10px;
       padding: 9px 12px; font-size: 12px; box-shadow: 0 8px 24px rgba(0,0,0,.35); white-space: nowrap; }
#tip .t1 { font-weight: 600; margin-bottom: 4px; color: #FFAF22; }
#tip i { display: inline-block; width: 8px; height: 8px; border-radius: 4px; margin-right: 6px; }
.leyenda { font-size: 12px; margin-top: 4px; }
.leyenda span { display: inline-block; margin-right: 16px; }
.leyenda i { display: inline-block; width: 10px; height: 10px; border-radius: 3px; margin-right: 6px; vertical-align: -1px; }
.leyenda i.lin { height: 3px; border-radius: 2px; vertical-align: 3px; width: 14px; }

.hb { margin-bottom: 11px; }
.hb .r1 { overflow: hidden; font-size: 12.5px; margin-bottom: 5px; }
.hb .r1 .n { float: left; max-width: 60%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.hb .r1 .v { float: right; font-weight: 600; }
.hb .r1 .x { float: right; margin-right: 10px; font-size: 11.5px; }
.track { height: 9px; border-radius: 6px; overflow: hidden; }
.fill { height: 9px; border-radius: 6px; width: 0; transition: width .9s cubic-bezier(.2,.8,.2,1); }

.dona { overflow: hidden; }
.dona .g { float: left; }
.dona .ley { margin-left: 194px; padding-top: 4px; }
.dona.angosta .g { float: none; text-align: center; }
.dona.angosta .ley { margin-left: 0; padding-top: 10px; }
.dona table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 12.5px; }
.dona td { padding: 6px 6px; cursor: default; transition: background .15s; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.dona td.c1 { width: 22px; padding-right: 0; }
.dona td.c3 { width: 74px; text-align: right; }
.dona td.c4 { width: 44px; text-align: right; font-weight: 600; }
.dona td i { display: inline-block; width: 10px; height: 10px; border-radius: 3px; }
.t-oscuro .dona tr.hl td { background: #1b2244; }
.t-claro  .dona tr.hl td { background: #f1f3f9; }

.calor { width: 100%; border-collapse: separate; border-spacing: 3px; }
.calor td { height: 26px; border-radius: 5px; text-align: center; font-size: 10.5px; padding: 0; opacity: 0; transition: opacity .6s ease; }
.calor td.ver { opacity: 1; }
.calor td.dia { text-align: right; padding-right: 6px; width: 34px; font-size: 11.5px; opacity: 1; }
.calor th { font-weight: 400; font-size: 10.5px; padding-bottom: 2px; }

.apil { height: 16px; border-radius: 8px; overflow: hidden; white-space: nowrap; font-size: 0; }
.apil div { display: inline-block; height: 16px; width: 0; transition: width .9s cubic-bezier(.2,.8,.2,1); }

/* ---------- tablas ---------- */
.tabla { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.tabla th { text-align: left; font-weight: 600; font-size: 11px; text-transform: uppercase; letter-spacing: .6px; padding: 0 8px 8px 8px; }
.tabla td { padding: 8px 8px; }
.tabla .der { text-align: right; }
.tabla .ell { max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pill { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 600; }
.p-rojo { background: rgba(248,113,113,.16); color: #ef5b5b; }
.p-amar { background: rgba(255,175,34,.18); color: #d98d00; }
.p-verd { background: rgba(52,211,153,.15); color: #19b382; }

/* ---------- varios ---------- */
.tabs { display: inline-block; }
.tabs span { display: inline-block; padding: 5px 11px; border-radius: 8px; font-size: 12px; cursor: pointer; margin-left: 2px; }
.alerta { border-radius: 12px; padding: 12px 14px 12px 50px; margin-bottom: 10px; position: relative; min-height: 46px; }
.alerta .ic { position: absolute; left: 12px; top: 11px; width: 28px; height: 28px; border-radius: 9px; text-align: center; padding-top: 5px; }
.alerta b { display: block; font-size: 13px; }
.alerta span { font-size: 12px; }
.big { font-size: 30px; font-weight: 700; letter-spacing: -.8px; }
.esq { border-radius: 8px; height: 14px; margin-bottom: 10px;
       background-image: linear-gradient(90deg, rgba(255,255,255,0) 0%, rgba(255,255,255,.08) 50%, rgba(255,255,255,0) 100%);
       background-size: 400px 100%; background-repeat: no-repeat; animation: brillo 1.2s infinite linear; }
@keyframes brillo { 0% { background-position: -400px 0; } 100% { background-position: 900px 0; } }
.vacio { text-align: center; padding: 30px 10px; font-size: 12.5px; }
.entra { animation: entra .45s ease both; }
@keyframes entra { 0% { opacity: 0; transform: translateY(8px); } 100% { opacity: 1; transform: translateY(0); } }
.pos { overflow: hidden; margin-bottom: 14px; }
.pos .n { float: left; font-size: 12.5px; }
.pos .v { float: right; font-weight: 700; font-size: 15px; }

/* ---------- cartel de carga ---------- */
#carga { position: absolute; left: 0; right: 0; top: 70px; bottom: 0; z-index: 20; display: none; }
#carga.on { display: block; }
.t-oscuro #carga { background: rgba(11,15,31,.80); }
.t-claro  #carga { background: rgba(238,241,247,.82); }
#carga .caja { width: 380px; margin: 90px auto 0 auto; text-align: center; padding: 26px 28px 22px 28px; }
#carga h3 { font-size: 16px; margin: 14px 0 6px 0; }
#carga #progTxt { font-size: 12.5px; min-height: 17px; }
#carga #progBar { background: #FFAF22; }
#carga .nota { font-size: 11px; margin-top: 12px; }
.giro { width: 34px; height: 34px; margin: 0 auto; border-radius: 50%; border: 3px solid rgba(255,175,34,.25); border-top-color: #FFAF22;
        animation: girar .8s linear infinite; }
@keyframes girar { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

/* ---------- asistente ---------- */
#ia { max-width: 980px; margin: 0 auto; }
.sug { display: inline-block; margin: 0 6px 8px 0; cursor: pointer; }
.msg-u { text-align: right; margin: 18px 0 10px 0; }
.msg-u span { display: inline-block; background: #FFAF22; color: #141833; padding: 10px 15px; border-radius: 16px 16px 4px 16px;
              max-width: 70%; text-align: left; font-size: 13.5px; }
.burbuja-ia { border-radius: 4px 16px 16px 16px; padding: 16px 18px; margin-bottom: 10px; }
.burbuja-ia .tt { font-weight: 600; font-size: 14.5px; margin-bottom: 6px; }
.burbuja-ia .tx { font-size: 13.5px; line-height: 1.55; }
.burbuja-ia .err { color: #ef5b5b; }
.califica { margin-top: 12px; font-size: 12px; }
.califica a { cursor: pointer; margin-left: 8px; padding: 3px 9px; border-radius: 8px; text-decoration: none; }
.t-oscuro .califica a { background: #1b2244; color: #c5cbe6; }
.t-claro  .califica a { background: #f0f2f8; color: #3a4266; }
.califica a.ok { background: #FFAF22 !important; color: #141833 !important; }
.ver-datos { cursor: pointer; font-size: 12px; margin-top: 12px; display: inline-block; }
.puntos span { display: inline-block; width: 7px; height: 7px; border-radius: 4px; background: #FFAF22; margin-right: 4px; animation: salto 1s infinite ease-in-out; }
.puntos span.b { animation-delay: .15s; } .puntos span.c { animation-delay: .3s; }
@keyframes salto { 0%, 80%, 100% { opacity: .25; } 40% { opacity: 1; } }
#iaBarra { margin-top: 14px; }
#iaTxt { width: 100%; height: 46px; resize: none; overflow: hidden; border-radius: 14px; padding: 12px 120px 12px 16px; font-size: 13.5px; font-family: inherit; }
#iaEnviar { position: absolute; right: 7px; top: 7px; background: #FFAF22; color: #141833; font-weight: 600; border-radius: 10px;
            padding: 8px 16px; cursor: pointer; font-size: 13px; }
</style>
</head>
<body class="t-claro">
<textarea id="req"></textarea>
<textarea id="resp"></textarea>
<div id="app">
  <div id="side"><div id="sideIn">
    <div class="logo"><svg class="marca" width="130" height="25" viewBox="0 24 407 78" aria-label="bcnsoft"><path fill="#FFAF22" d="M40.2 100.9L40.2 100.9Q29.6 100.9 24.2 94.6L24.2 94.6L24.2 100L6.1 100L6.1 25.8L25.1 25.8L25.1 50.5Q30.6 44.9 40.2 44.9L40.2 44.9Q47.6 44.9 53.6 48.3Q59.6 51.7 63.2 57.9Q66.8 64.2 66.8 72.8L66.8 72.8Q66.8 81.5 63.2 87.8Q59.6 94 53.6 97.5Q47.6 100.9 40.2 100.9ZM36.2 85.8L36.2 85.8Q41 85.8 44.3 82.4Q47.6 79 47.6 72.8L47.6 72.8Q47.6 66.7 44.3 63.4Q41 60 36.2 60L36.2 60Q31.4 60 28.1 63.4Q24.8 66.7 24.8 72.8L24.8 72.8Q24.8 79 28.1 82.4Q31.4 85.8 36.2 85.8ZM103.3 100.9L103.3 100.9Q94.2 100.9 87.2 97.3Q80.2 93.7 76.2 87.4Q72.2 81.1 72.2 72.8L72.2 72.8Q72.2 64.7 76.2 58.3Q80.2 52 87.2 48.4Q94.2 44.9 103.3 44.9L103.3 44.9Q112.5 44.9 119.2 48.8Q125.9 52.7 128.7 59.8L128.7 59.8L114 67.3Q112.1 63.5 109.3 61.8Q106.5 60 103.2 60L103.2 60Q98.3 60 94.8 63.4Q91.4 66.7 91.4 72.8L91.4 72.8Q91.4 79.1 94.8 82.5Q98.3 85.8 103.2 85.8L103.2 85.8Q106.5 85.8 109.3 84.0Q112.1 82.3 114 78.5L114 78.5L128.7 86Q125.9 93 119.2 97.0Q112.5 100.9 103.3 100.9ZM154.9 100L135.9 100L135.9 45.8L154 45.8L154 51.7Q157.2 48.3 161.7 46.6Q166.1 44.9 171.2 44.9L171.2 44.9Q177.5 44.9 182.6 47.4Q187.7 50 190.7 55.3Q193.6 60.6 193.6 69L193.6 69L193.6 100L174.6 100L174.6 72.1Q174.6 66.3 172.2 63.6Q169.8 61 165.7 61L165.7 61Q161.1 61 158 64.0Q154.9 67.1 154.9 73.8L154.9 73.8L154.9 100Z"/><path fill="#ffffff" d="M225.2 100.9L225.2 100.9Q218.3 100.9 211.8 99.3Q205.2 97.7 201.2 95.3L201.2 95.3L206.9 82.3Q210.7 84.6 215.8 86.0Q220.9 87.3 225.8 87.3L225.8 87.3Q230.6 87.3 232.5 86.3Q234.3 85.3 234.3 83.6L234.3 83.6Q234.3 81.6 231.5 80.9Q228.6 80.2 224.6 79.6L224.6 79.6Q221 79.1 217.2 78.3Q213.3 77.6 209.9 76.0Q206.5 74.3 204.4 71.2Q202.3 68 202.3 62.9L202.3 62.9Q202.3 57.8 205.3 53.7Q208.4 49.6 214.3 47.3Q220.2 44.9 228.7 44.9L228.7 44.9Q234.4 44.9 240.3 46.0Q246.1 47.2 250.1 49.5L250.1 49.5L244.4 62.4Q240.4 60.1 236.4 59.3Q232.4 58.4 228.8 58.4L228.8 58.4Q224 58.4 222.1 59.5Q220.1 60.7 220.1 62.2L220.1 62.2Q220.1 64.3 223.0 65.0Q225.8 65.8 230 66.4L230 66.4Q233.5 66.9 237.4 67.7Q241.2 68.5 244.6 70.2Q247.9 71.9 250.0 75.0Q252 78 252 83.1L252 83.1Q252 88.1 249.0 92.1Q245.9 96.1 240.0 98.5Q234 100.9 225.2 100.9ZM287.4 100.9L287.4 100.9Q278.5 100.9 271.6 97.3Q264.7 93.7 260.8 87.3Q256.8 81 256.8 72.8L256.8 72.8Q256.8 64.7 260.8 58.3Q264.7 52 271.6 48.4Q278.5 44.9 287.4 44.9L287.4 44.9Q296.3 44.9 303.3 48.4Q310.2 52 314.1 58.3Q318 64.7 318 72.8L318 72.8Q318 81 314.1 87.3Q310.2 93.7 303.3 97.3Q296.3 100.9 287.4 100.9ZM287.4 85.8L287.4 85.8Q292.3 85.8 295.6 82.4Q298.8 79 298.8 72.8L298.8 72.8Q298.8 66.7 295.6 63.4Q292.3 60 287.4 60L287.4 60Q282.6 60 279.3 63.4Q276 66.7 276 72.8L276 72.8Q276 79 279.3 82.4Q282.6 85.8 287.4 85.8ZM348.0 100L329.0 100L329.0 62L321.1 62L321.1 47.8L329.0 47.8L329.0 46.4Q329.0 36.6 334.9 30.8Q340.7 24.9 351.6 24.9L351.6 24.9Q355.0 24.9 358.5 25.6Q361.9 26.3 364.2 27.7L364.2 27.7L359.5 41.1Q358.3 40.4 356.8 39.9Q355.3 39.5 353.8 39.5L353.8 39.5Q350.8 39.5 349.2 41.3Q347.5 43 347.5 46.6L347.5 46.6L347.5 47.8L360.4 47.8L360.4 62L348.0 62L348.0 100ZM391.6 100.9L391.6 100.9Q381.2 100.9 375.4 95.8Q369.6 90.6 369.6 80.2L369.6 80.2L369.6 59.9L361.7 59.9L361.7 45.8L369.6 45.8L369.6 33.7L388.6 33.7L388.6 45.8L401.0 45.8L401.0 59.9L388.6 59.9L388.6 80Q388.6 83 390.2 84.6Q391.7 86.2 394.3 86.2L394.3 86.2Q397.6 86.2 400.1 84.5L400.1 84.5L404.8 97.8Q402.3 99.4 398.8 100.2Q395.3 100.9 391.6 100.9Z"/></svg><span>Tablero</span></div>
    <div class="nav" id="nav"></div>
    <div class="pie">
      <div class="usu" id="usu"></div>
      <div class="tema claro" id="tema">
        <div class="sel"></div>
        <div class="izq" id="tOsc"></div>
        <div class="der" id="tCla"></div>
      </div>
    </div>
  </div></div>
  <div id="main">
    <div id="top">
      <div class="tit"><h1 id="secTit">Tablero</h1><div class="mut" id="secSub"></div></div>
      <div class="cerrar" id="btnCerrar" title="Cerrar el tablero" onclick="pedir('cerrar', {})"></div>
      <div class="periodo" id="periodo"></div>
    </div>
    <div id="cont"></div>
    <div id="carga"><div class="card caja">
      <div class="giro"></div>
      <h3>Armando el tablero</h3>
      <div class="mut" id="progTxt">Preparando las consultas</div>
      <div class="track" id="progTrack" style="margin-top:14px"><div class="fill" id="progBar"></div></div>
      <div class="mut nota">Con mucho movimiento puede tardar unos segundos.</div>
    </div></div>
  </div>
</div>
<div id="tip"></div>

<script>
// =====================================================================
// Utilidades
// =====================================================================
var NS = "http://www.w3.org/2000/svg";
var PAL = ["#FFAF22", "#4F8CFF", "#22C3A6", "#9B7BFF", "#FF6B6B", "#38BDF8", "#A3E635", "#F472B6", "#F59E0B", "#64748B"];
var TEMAS = {
  oscuro: { grid: "#1f2745", eje: "#7f88ad", txt: "#e7eaf6", card: "#141a30", ant: "#58618a", track: "#1d2443" },
  claro:  { grid: "#e8ebf3", eje: "#7a819c", txt: "#1a2040", card: "#ffffff", ant: "#b6bccf", track: "#eef1f7" }
};
var MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
var MESES_L = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
var DIAS = ["Dom", "Lun", "Mar", "Mi\\u00e9", "Jue", "Vie", "S\\u00e1b"];
var raf = window.requestAnimationFrame || function (f) { return setTimeout(f, 16); };
var uid = 0;

function $(id) { return document.getElementById(id); }
function ahora() { return (window.performance && performance.now) ? performance.now() : new Date().getTime(); }
function ease(t) { return 1 - Math.pow(1 - t, 3); }
function anima(ms, paso, fin) {
  var t0 = ahora();
  function f() { var t = Math.min(1, (ahora() - t0) / ms); paso(ease(t)); if (t < 1) { raf(f); } else if (fin) { fin(); } }
  raf(f);
}
function S(tag, at, padre) {
  var e = document.createElementNS(NS, tag), k;
  for (k in at) { if (at.hasOwnProperty(k)) { e.setAttribute(k, at[k]); } }
  if (padre) { padre.appendChild(e); }
  return e;
}
function esc(s) {
  return String(s === null || s === undefined ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function num(v) { v = parseFloat(v); return isNaN(v) ? 0 : v; }
function fmtN(n, dec) {
  n = num(n); dec = dec || 0;
  var neg = n < 0, s = Math.abs(n).toFixed(dec), p = s.split(".");
  var e = p[0].replace(/\\B(?=(\\d{3})+(?!\\d))/g, ".");
  return (neg ? "-" : "") + e + (p.length > 1 ? "," + p[1] : "");
}
function fmtM(n) { n = num(n); return "$\\u00a0" + fmtN(n, (Math.abs(n) < 100 && n % 1 !== 0) ? 2 : 0); }
function fmtC(n) {   // corto para ejes: 1,2 M / 350 k
  n = num(n); var a = Math.abs(n);
  if (a >= 1e9) { return fmtN(n / 1e9, 1) + " mil M"; }
  if (a >= 1e6) { return fmtN(n / 1e6, a >= 1e7 ? 0 : 1) + " M"; }
  if (a >= 1e3) { return fmtN(n / 1e3, 0) + " k"; }
  return fmtN(n, 0);
}
function fmtMC(n) { return "$\\u00a0" + fmtC(n); }
// "MERCADO PAGO" -> "Mercado Pago" (los maestros suelen estar en mayusculas)
function capital(s) {
  s = String(s || "");
  if (s !== s.toUpperCase()) { return s; }
  return s.toLowerCase().replace(/(^|[\\s\\.\\-\\/(])([a-z\\u00e0-\\u00fe])/g, function (m, a, b) { return a + b.toUpperCase(); });
}
function fmtP(n, dec) { return fmtN(n, dec === undefined ? 1 : dec) + "\\u00a0%"; }
function fmtCant(n) { n = num(n); return fmtN(n, n % 1 === 0 ? 0 : (Math.round(n * 100) % 100 === 0 ? 1 : 2)); }
function fecTxt(s) { if (!s || s.length < 10) { return s || ""; } return s.substr(8, 2) + "/" + s.substr(5, 2) + "/" + s.substr(0, 4); }
function iso(d) { function z(n) { return (n < 10 ? "0" : "") + n; } return d.getFullYear() + "-" + z(d.getMonth() + 1) + "-" + z(d.getDate()); }
function deIso(s) { return new Date(parseInt(s.substr(0, 4), 10), parseInt(s.substr(5, 2), 10) - 1, parseInt(s.substr(8, 2), 10)); }
function sumaDias(d, n) { var r = new Date(d.getTime()); r.setDate(r.getDate() + n); return r; }
function finMes(a, m) { return new Date(a, m + 1, 0).getDate(); }
function maxDe(a, f) { var m = 0, i; for (i = 0; i < a.length; i++) { m = Math.max(m, f ? f(a[i]) : a[i]); } return m; }
function niceMax(v) {
  if (v <= 0) { return 1; }
  var e = Math.pow(10, Math.floor(Math.log(v) / Math.LN10)), f = v / e;
  return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10) * e;
}
// Maximo del eje con 4 escalones redondos (0, 1, 2, 3, 4 M en vez de 0, 1,3, 2,5...)
function ejeMax(v) { return niceMax(Math.max(v, 1) / 4) * 4; }
function th() { return TEMAS[estado.tema]; }
function contador(el, valor, fmt) {
  var v = num(valor);
  anima(900, function (t) { el.innerHTML = fmt(v * t); });
}

// ---------- tooltip ----------
function tip(html, x, y) {
  var t = $("tip");
  t.innerHTML = html; t.style.display = "block";
  var w = t.offsetWidth, h = t.offsetHeight, W = document.documentElement.clientWidth;
  var l = x + 16; if (l + w > W - 8) { l = x - w - 16; }
  t.style.left = l + "px"; t.style.top = Math.max(6, y - h - 10) + "px";
}
function sinTip() { $("tip").style.display = "none"; }

// =====================================================================
// Iconos (SVG inline)
// =====================================================================
var ICON = {
  resumen: "M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z",
  ventas: "M3 17l6-6 4 4 8-8M15 7h6v6",
  clientes: "M16 11a4 4 0 1 0-4-4 4 4 0 0 0 4 4zM8 11a3 3 0 1 0-3-3 3 3 0 0 0 3 3zm8 2c-2.7 0-8 1.3-8 4v3h16v-3c0-2.7-5.3-4-8-4zM8 13c-.3 0-.7 0-1.1.1C4.4 13.5 0 14.6 0 17v3h6v-3c0-1.5.8-2.8 2-3.9z",
  compras: "M3 3h2l2.4 12.2a2 2 0 0 0 2 1.6h8.7a2 2 0 0 0 2-1.5L22 7H6M9 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm10 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2z",
  stock: "M21 8l-9-5-9 5v8l9 5 9-5V8zM3 8l9 5 9-5M12 13v8",
  caja: "M3 7h18v12H3zM3 11h18M7 15h3",
  ia: "M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9zM19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9z",
  sol: "M12 7a5 5 0 1 0 5 5 5 5 0 0 0-5-5zM12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4",
  luna: "M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z",
  refrescar: "M21 12a9 9 0 1 1-2.6-6.4M21 3v6h-6",
  cerrar: "M18 6L6 18M6 6l12 12",
  alerta: "M12 9v4M12 17h.01M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z",
  reloj: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 6v6l4 2",
  caja2: "M20 7l-8-4-8 4v10l8 4 8-4V7z",
  usuario: "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"
};
function icono(n, tam, color, rell) {
  return '<svg width="' + (tam || 18) + '" height="' + (tam || 18) + '" viewBox="0 0 24 24"><path d="' + ICON[n] + '" fill="' + (rell ? (color || "currentColor") : "none") +
    '" stroke="' + (rell ? "none" : (color || "currentColor")) + '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
}

// =====================================================================
// Puente con el sistema: #req (pagina -> sistema), #resp (sistema -> pagina)
// =====================================================================
var puente = { seq: 0, cola: [], cb: {}, vivo: false };
function pedir(accion, params, cb) {
  var p = params || {}, id = ++puente.seq;
  p.id = id; p.accion = accion;
  puente.cola.push(p); puente.cb[id] = cb;
  enviar();
  return id;
}
function enviar() {
  var r = $("req");
  if (puente.cola.length && r.value === "") { r.value = JSON.stringify(puente.cola); puente.cola = []; }
}
function sondear() {
  enviar();
  var s = $("resp"), v = s.value, arr, i, f;
  if (!v) { return; }
  s.value = "";
  puente.vivo = true;
  try { arr = JSON.parse(v); } catch (e) { return; }
  for (i = 0; i < arr.length; i++) {
    f = puente.cb[arr[i].id];
    delete puente.cb[arr[i].id];
    if (f) { try { f(arr[i].datos, arr[i].error); } catch (e2) { document.title = "ERR cb: " + e2.message; } }
  }
}
setInterval(sondear, 60);

// =====================================================================
// Estado, periodo y navegacion
// =====================================================================
var estado = { tema: "claro", sec: "resumen", per: "mes", hoy: new Date(), desde: null, hasta: null, pdesde: null, phasta: null,
               txtAnt: "", ia: false, cache: {}, ultimo: null, agrupar: "rubro" };
var SECC = [
  { id: "resumen", t: "Resumen", sub: "La foto del negocio", grupo: "Tablero" },
  { id: "ventas", t: "Ventas", sub: "Qu\\u00e9, cu\\u00e1ndo y cu\\u00e1nto se vende" },
  { id: "clientes", t: "Clientes y cobranzas", sub: "Deuda, antig\\u00fcedad y cobros" },
  { id: "compras", t: "Compras y proveedores", sub: "Gastos, deuda y vencimientos" },
  { id: "stock", t: "Stock", sub: "Mercader\\u00eda, faltantes y capital inmovilizado", sinPer: true },
  { id: "caja", t: "Caja", sub: "Entradas, salidas y cierres" },
  { id: "ia", t: "Asistente", sub: "Preguntale a tus datos en lenguaje natural", sinPer: true, grupo: "Inteligencia" }
];
var PER = [
  { id: "hoy", t: "Hoy" }, { id: "7d", t: "7 d\\u00edas" }, { id: "mes", t: "Este mes" }, { id: "mant", t: "Mes anterior" },
  { id: "anio", t: "Este a\\u00f1o" }, { id: "12m", t: "12 meses" }, { id: "otro", t: "Otro" }
];

function calcPeriodo() {
  var h = estado.hoy, d, a, pd, ph, y = h.getFullYear(), m = h.getMonth(), largo, txt;
  switch (estado.per) {
    case "hoy": d = h; a = h; pd = sumaDias(h, -1); ph = pd; txt = "vs. ayer"; break;
    case "7d": d = sumaDias(h, -6); a = h; pd = sumaDias(h, -13); ph = sumaDias(h, -7); txt = "vs. 7 d\\u00edas anteriores"; break;
    case "mant":
      d = new Date(y, m - 1, 1); a = new Date(y, m, 0);
      pd = new Date(y, m - 2, 1); ph = new Date(y, m - 1, 0); txt = "vs. el mes anterior"; break;
    case "anio":
      d = new Date(y, 0, 1); a = h; pd = new Date(y - 1, 0, 1);
      ph = new Date(y - 1, m, Math.min(h.getDate(), finMes(y - 1, m))); txt = "vs. mismo per\\u00edodo del a\\u00f1o pasado"; break;
    case "12m":
      d = new Date(y - 1, m + 1, 1); a = h; pd = new Date(y - 2, m + 1, 1); ph = new Date(y - 1, m, finMes(y - 1, m)); txt = "vs. 12 meses anteriores"; break;
    case "otro":
      d = estado.desde || h; a = estado.hasta || h;
      largo = Math.round((a - d) / 86400000);
      ph = sumaDias(d, -1); pd = sumaDias(ph, -largo); txt = "vs. per\\u00edodo anterior de igual largo"; break;
    default:   // este mes: contra los mismos dias del mes anterior
      d = new Date(y, m, 1); a = h; pd = new Date(y, m - 1, 1);
      ph = new Date(y, m - 1, Math.min(h.getDate(), finMes(y, m - 1))); txt = "vs. mismos d\\u00edas del mes anterior";
  }
  estado.desde = d; estado.hasta = a; estado.pdesde = pd; estado.phasta = ph; estado.txtAnt = txt;
}
function paramsPer(extra) {
  var p = { desde: iso(estado.desde), hasta: iso(estado.hasta), pdesde: iso(estado.pdesde), phasta: iso(estado.phasta) }, k;
  if (extra) { for (k in extra) { if (extra.hasOwnProperty(k)) { p[k] = extra[k]; } } }
  return p;
}
function textoPer() {
  var d = estado.desde, a = estado.hasta;
  if (iso(d) === iso(a)) { return DIAS[d.getDay()] + " " + d.getDate() + " de " + MESES_L[d.getMonth()] + " de " + d.getFullYear(); }
  if (d.getDate() === 1 && a.getDate() === finMes(a.getFullYear(), a.getMonth()) && d.getMonth() === a.getMonth() && d.getFullYear() === a.getFullYear()) {
    return MESES_L[d.getMonth()].charAt(0).toUpperCase() + MESES_L[d.getMonth()].substr(1) + " " + d.getFullYear();
  }
  return "Del " + fecTxt(iso(d)) + " al " + fecTxt(iso(a));
}

function armarNav() {
  var h = "", i, s;
  for (i = 0; i < SECC.length; i++) {
    s = SECC[i];
    if (s.grupo) { h += '<div class="grupo">' + s.grupo + "</div>"; }
    h += '<a id="nav-' + s.id + '" onclick="ir(\\'' + s.id + '\\')">' + icono(s.id, 18) + s.t + "</a>";
  }
  $("nav").innerHTML = h;
}
function armarPeriodo() {
  var sec = secc(estado.sec), h = "", i;
  if (sec.sinPer) {
    h = sec.id === "ia" ? '<span class="chip" onclick="iaNueva()">Nueva conversaci\\u00f3n</span>' : "";
    $("periodo").innerHTML = h; return;
  }
  for (i = 0; i < PER.length; i++) {
    h += '<span class="chip' + (estado.per === PER[i].id || (PER[i].id === "otro" && estado.otroAb) ? " on" : "") +
         '" onclick="cambiarPer(\\'' + PER[i].id + '\\')">' + PER[i].t + "</span>";
  }
  h += '<span class="chip ico" title="Actualizar" onclick="refrescar()">' + icono("refrescar", 16) + "</span>";
  h += '<div class="otro' + (estado.otroAb ? " on" : "") + '" id="otro">' +
       '<div class="campo"><div class="mut">Desde</div><input class="inp" id="fDesde" placeholder="dd/mm/aaaa" value="' + fecTxt(iso(estado.desde)) + '"></div>' +
       '<div class="campo"><div class="mut">Hasta</div><input class="inp" id="fHasta" placeholder="dd/mm/aaaa" value="' + fecTxt(iso(estado.hasta)) + '"></div>' +
       '<span class="chip on" onclick="aplicarOtro()">Aplicar</span><span class="chip" onclick="cerrarOtro()">Cancelar</span></div>';
  $("periodo").innerHTML = h;
  if (estado.otroAb) {
    $("fDesde").onkeydown = $("fHasta").onkeydown = function (e) {
      e = e || window.event;
      if (e.keyCode === 13) { aplicarOtro(); return false; }
      if (e.keyCode === 27) { cerrarOtro(); return false; }
    };
  }
}
function secc(id) { var i; for (i = 0; i < SECC.length; i++) { if (SECC[i].id === id) { return SECC[i]; } } return SECC[0]; }
function cambiarPer(p) {
  // "Otro" solo abre/cierra el panel de fechas; el periodo cambia recien al Aplicar
  if (p === "otro") {
    estado.otroAb = !estado.otroAb; armarPeriodo();
    if (estado.otroAb) { try { $("fDesde").focus(); $("fDesde").select(); } catch (e) { } }
    return;
  }
  estado.per = p; estado.otroAb = false;
  calcPeriodo(); armarPeriodo(); mostrar();
}
function cerrarOtro() { estado.otroAb = false; armarPeriodo(); }
function leerFecha(s) {
  var m = /^\\s*(\\d{1,2})\\/(\\d{1,2})\\/(\\d{2,4})\\s*$/.exec(s || ""), y;
  if (!m) { return null; }
  y = parseInt(m[3], 10); if (y < 100) { y += 2000; }
  return new Date(y, parseInt(m[2], 10) - 1, parseInt(m[1], 10));
}
function aplicarOtro() {
  var d = leerFecha($("fDesde").value), a = leerFecha($("fHasta").value);
  if (!d || !a || d > a) { $("fDesde").style.borderColor = "#ef5b5b"; $("fHasta").style.borderColor = "#ef5b5b"; return; }
  estado.per = "otro"; estado.otroAb = false;
  estado.desde = d; estado.hasta = a; calcPeriodo(); armarPeriodo(); mostrar();
}
function refrescar() { estado.cache = {}; mostrar(); }
function ir(id) {
  estado.sec = id; estado.otroAb = false;
  var i;
  for (i = 0; i < SECC.length; i++) { $("nav-" + SECC[i].id).className = SECC[i].id === id ? "on" : ""; }
  armarPeriodo(); mostrar();
}
function mostrar() {
  var s = secc(estado.sec);
  sinTip();
  $("secTit").innerHTML = s.t;
  $("secSub").innerHTML = s.sinPer ? s.sub : (textoPer() + " &middot; " + estado.txtAnt);
  $("cont").scrollTop = 0;
  cartelCarga(false);   // las secciones que piden datos lo vuelven a mostrar
  RENDER[s.id]();
}

// ---------- tema ----------
function aplicarTema(t, guardar) {
  estado.tema = t === "claro" ? "claro" : "oscuro";
  document.body.className = "t-" + estado.tema;
  $("tema").className = "tema " + estado.tema;
  if (guardar) { pedir("tema", { tema: estado.tema }); redibujar(); }
}
function redibujar() { if (estado.ultimo) { estado.ultimo(true); } }

// Pide datos con cache; mientras tanto, esqueletos
function cargar(accion, extra, pintar) {
  var p = paramsPer(extra), k = accion + "|" + JSON.stringify(p), sec = estado.sec;
  estado.ultimo = function (sinAnim) { if (estado.cache[k]) { pintar(estado.cache[k], sinAnim); } };
  if (estado.cache[k]) { cartelCarga(false); pintar(estado.cache[k]); return; }
  cartelCarga(true, "Preparando las consultas", 2);
  // El pedido sale despues de que se dibuje el cartel: mientras el sistema
  // consulta, el navegador solo se redibuja cuando el sistema le da paso
  setTimeout(function () {
    pedir(accion, p, function (d, err) {
      if (estado.sec !== sec) { return; }
      cartelCarga(false);
      if (err || !d) { $("cont").innerHTML = '<div class="card vacio mut">' + esc(err || "No se pudieron leer los datos.") + "</div>"; return; }
      estado.cache[k] = d; pintar(d);
    });
  }, 120);
}
// Cartel "Armando el tablero" (el sistema le actualiza #progTxt y #progBar)
function cartelCarga(on, txt, pct) {
  $("carga").className = on ? "on" : "";
  if (on) { $("progTxt").innerHTML = txt || ""; $("progTrack").innerHTML = '<div class="fill" id="progBar" style="width:' + (pct || 0) + '%"></div>'; }
}

// =====================================================================
// Componentes
// =====================================================================
function card(id, titulo, sub, extraCls, acc) {
  return '<div class="card entra ' + (extraCls || "") + '">' + (acc ? '<div class="acc">' + acc + "</div>" : "") +
         "<h3>" + titulo + "</h3>" + (sub ? '<div class="sub mut">' + sub + "</div>" : '<div class="sub"></div>') +
         '<div id="' + id + '"><div class="esq" style="width:70%"></div><div class="esq" style="width:90%"></div><div class="esq" style="width:55%"></div></div></div>';
}
function vacio(el, txt) { el.innerHTML = '<div class="vacio mut">' + (txt || "Sin datos en este per\\u00edodo") + "</div>"; }

// Variacion contra el periodo anterior. bueno: 1 si subir es bueno, -1 si es malo, 0 neutro
function delta(act, ant, bueno) {
  act = num(act); ant = num(ant);
  if (!ant) { return act ? '<span class="delta d-ne">sin datos previos</span>' : ""; }
  var v = (act - ant) / Math.abs(ant) * 100, cls = "d-ne";
  if (Math.abs(v) >= 0.5 && bueno) { cls = ((v > 0) === (bueno > 0)) ? "d-up" : "d-dn"; }
  return '<span class="delta ' + cls + '">' + (v >= 0 ? "\\u25b2 " : "\\u25bc ") + fmtN(Math.abs(v), Math.abs(v) < 10 ? 1 : 0) + "\\u00a0%</span>";
}
function kpiHtml(id, lab, color) {
  return '<div class="col kpi"><div class="card entra"><div class="lab mut">' + lab + '</div><div class="val num" id="' + id + '-v">&nbsp;</div>' +
         '<div class="pie2 mut" id="' + id + '-p">&nbsp;</div><div class="spark" id="' + id + '-s"></div></div></div>';
}
function kpiPintar(id, valor, fmt, ant, bueno, txtAnt, serie, color, sinAnim) {
  var el = $(id + "-v");
  if (!el) { return; }
  if (sinAnim) { el.innerHTML = fmt(valor); } else { contador(el, valor, fmt); }
  $(id + "-p").innerHTML = (ant === null ? "" : delta(valor, ant, bueno)) + (txtAnt || "");
  if (serie && serie.length > 1) { sparkline($(id + "-s"), serie, color, sinAnim); }
}

// ---------- minigrafico ----------
function sparkline(box, data, color, sinAnim) {
  box.innerHTML = "";
  var W = box.clientWidth || 200, H = box.clientHeight || 40, mx = maxDe(data), mn = Math.min.apply(null, data), i, d = "", x, y, n = data.length;
  if (mx === mn) { mx = mn + 1; }
  var svg = S("svg", { width: W, height: H }, box), id = "sp" + (++uid);
  var defs = S("defs", {}, svg), lg = S("linearGradient", { id: id + "g", x1: 0, y1: 0, x2: 0, y2: 1 }, defs);
  S("stop", { offset: "0%", "stop-color": color, "stop-opacity": 0.35 }, lg);
  S("stop", { offset: "100%", "stop-color": color, "stop-opacity": 0 }, lg);
  var cp = S("clipPath", { id: id + "c" }, defs), r = S("rect", { x: 0, y: 0, width: sinAnim ? W : 0, height: H }, cp);
  for (i = 0; i < n; i++) {
    x = (i / (n - 1)) * W; y = 6 + (1 - (data[i] - mn) / (mx - mn)) * (H - 10);
    d += (i ? "L" : "M") + x.toFixed(1) + " " + y.toFixed(1);
  }
  var g = S("g", { "clip-path": "url(#" + id + "c)" }, svg);
  S("path", { d: d + "L" + W + " " + H + "L0 " + H + "Z", fill: "url(#" + id + "g)" }, g);
  S("path", { d: d, fill: "none", stroke: color, "stroke-width": 2, "stroke-linejoin": "round" }, g);
  if (!sinAnim) { anima(1100, function (t) { r.setAttribute("width", W * t); }); }
}

// ---------- lineas / areas (con periodo anterior punteado) ----------
function lineas(box, o, sinAnim) {
  box.innerHTML = "";
  var W = box.clientWidth || 600, H = o.alto || 270, pl = 62, pr = 16, pt = 14, pb = 30, w = W - pl - pr, h = H - pt - pb;
  var n = o.etiquetas.length, mx = 0, i, j, s, x, y, d, svg, defs, cp, r, g, step, id = "ln" + (++uid);
  if (!n) { vacio(box); return; }
  for (j = 0; j < o.series.length; j++) { mx = Math.max(mx, maxDe(o.series[j].datos)); }
  mx = ejeMax(mx * 1.05);
  svg = S("svg", { width: W, height: H }, box);
  defs = S("defs", {}, svg);
  for (i = 0; i <= 4; i++) {
    y = pt + h - (i / 4) * h;
    S("line", { x1: pl, x2: W - pr, y1: y, y2: y, stroke: th().grid, "stroke-width": 1 }, svg);
    S("text", { x: pl - 10, y: y + 4, "text-anchor": "end", fill: th().eje, "font-size": 11 }, svg).appendChild(document.createTextNode((o.fmtEje || fmtMC)(mx * i / 4)));
  }
  step = Math.max(1, Math.ceil(n / Math.max(2, Math.floor(w / 70))));
  function px(k) { return pl + (n === 1 ? w / 2 : (k / (n - 1)) * w); }
  for (i = 0; i < n; i += step) {
    S("text", { x: px(i), y: H - 8, "text-anchor": "middle", fill: th().eje, "font-size": 11 }, svg).appendChild(document.createTextNode(o.etiquetas[i]));
  }
  cp = S("clipPath", { id: id }, defs); r = S("rect", { x: 0, y: 0, width: sinAnim ? W : 0, height: H }, cp);
  g = S("g", { "clip-path": "url(#" + id + ")" }, svg);
  for (j = o.series.length - 1; j >= 0; j--) {
    s = o.series[j]; d = "";
    var nUlt = n - 1;
    while (nUlt > 0 && (s.datos[nUlt] === null || s.datos[nUlt] === undefined)) { nUlt--; }
    for (i = 0; i <= nUlt; i++) { x = px(i); y = pt + h - (num(s.datos[i]) / mx) * h; d += (i ? "L" : "M") + x.toFixed(1) + " " + y.toFixed(1); }
    if (s.area) {
      var lg = S("linearGradient", { id: id + "g" + j, x1: 0, y1: 0, x2: 0, y2: 1 }, defs);
      S("stop", { offset: "0%", "stop-color": s.color, "stop-opacity": 0.28 }, lg);
      S("stop", { offset: "100%", "stop-color": s.color, "stop-opacity": 0 }, lg);
      S("path", { d: d + "L" + px(nUlt) + " " + (pt + h) + "L" + px(0) + " " + (pt + h) + "Z", fill: "url(#" + id + "g" + j + ")" }, g);
    }
    S("path", { d: d, fill: "none", stroke: s.color, "stroke-width": s.ancho || 2.4, "stroke-dasharray": s.punteado ? "5 5" : "none", "stroke-linejoin": "round", "stroke-linecap": "round" }, g);
  }
  if (!sinAnim) { anima(1300, function (t) { r.setAttribute("width", W * t); }); }
  // interaccion
  var guia = S("line", { x1: 0, x2: 0, y1: pt, y2: pt + h, stroke: th().eje, "stroke-width": 1, "stroke-dasharray": "3 3", opacity: 0 }, svg);
  var puntos = [];
  for (j = 0; j < o.series.length; j++) { puntos.push(S("circle", { r: 4.5, fill: o.series[j].color, stroke: th().card, "stroke-width": 2, opacity: 0 }, svg)); }
  var capa = S("rect", { x: pl, y: pt, width: w, height: h, fill: "transparent" }, svg);
  capa.addEventListener("mousemove", function (e) {
    var b = svg.getBoundingClientRect(), k = Math.round(((e.clientX - b.left - pl) / w) * (n - 1)), html, q, v;
    k = Math.max(0, Math.min(n - 1, k));
    guia.setAttribute("x1", px(k)); guia.setAttribute("x2", px(k)); guia.setAttribute("opacity", 1);
    html = '<div class="t1">' + esc(o.titulos ? o.titulos[k] : o.etiquetas[k]) + "</div>";
    for (q = 0; q < o.series.length; q++) {
      v = o.series[q].datos[k];
      puntos[q].setAttribute("cx", px(k)); puntos[q].setAttribute("cy", pt + h - (num(v) / mx) * h); puntos[q].setAttribute("opacity", v === null ? 0 : 1);
      if (v !== null && v !== undefined) {
        html += '<div><i style="background:' + o.series[q].color + '"></i>' + esc(o.series[q].nombre) + ": <b>" + (o.fmt || fmtM)(v) +
                "</b>" + (o.series[q].titulos ? ' <span style="opacity:.6">(' + esc(o.series[q].titulos[k]) + ")</span>" : "") + "</div>";
      }
    }
    tip(html, e.clientX + document.documentElement.scrollLeft, e.clientY);
  });
  capa.addEventListener("mouseleave", function () { guia.setAttribute("opacity", 0); var q; for (q = 0; q < puntos.length; q++) { puntos[q].setAttribute("opacity", 0); } sinTip(); });
}

// ---------- columnas ----------
function columnas(box, o, sinAnim) {
  box.innerHTML = "";
  var W = box.clientWidth || 500, H = o.alto || 240, pl = 58, pr = 10, pt = 16, pb = 30, w = W - pl - pr, h = H - pt - pb;
  var n = o.datos.length, mx = ejeMax(maxDe(o.datos) * 1.08), i, bw, gap, svg, x, y, rects = [], v;
  if (!n) { vacio(box); return; }
  svg = S("svg", { width: W, height: H }, box);
  for (i = 0; i <= 4; i++) {
    y = pt + h - (i / 4) * h;
    S("line", { x1: pl, x2: W - pr, y1: y, y2: y, stroke: th().grid }, svg);
    S("text", { x: pl - 10, y: y + 4, "text-anchor": "end", fill: th().eje, "font-size": 11 }, svg).appendChild(document.createTextNode((o.fmtEje || fmtMC)(mx * i / 4)));
  }
  gap = Math.max(3, Math.min(14, (w / n) * 0.3)); bw = Math.max(3, (w - gap * (n + 1)) / n);
  var step = Math.max(1, Math.ceil(n / Math.max(2, Math.floor(w / 62))));
  for (i = 0; i < n; i++) {
    v = num(o.datos[i]); x = pl + gap + i * (bw + gap);
    var col = o.colores ? o.colores[i] : (o.color || PAL[0]);
    var rc = S("rect", { x: x, y: pt + h, width: bw, height: 0, rx: Math.min(5, bw / 2), fill: col }, svg);
    rc.setAttribute("data-i", i);
    rects.push({ el: rc, h: Math.max(0, v / mx * h) });
    if (i % step === 0) {
      S("text", { x: x + bw / 2, y: H - 9, "text-anchor": "middle", fill: th().eje, "font-size": 11 }, svg).appendChild(document.createTextNode(o.etiquetas[i]));
    }
    (function (k, el) {
      el.addEventListener("mousemove", function (e) {
        el.setAttribute("opacity", 0.8);
        tip('<div class="t1">' + esc(o.titulos ? o.titulos[k] : o.etiquetas[k]) + "</div><b>" + (o.fmt || fmtM)(o.datos[k]) + "</b>" + (o.extra ? "<div>" + o.extra(k) + "</div>" : ""), e.clientX, e.clientY);
      });
      el.addEventListener("mouseleave", function () { el.setAttribute("opacity", 1); sinTip(); });
    })(i, rc);
  }
  function pinta(t) {
    var k, hh, tt;
    for (k = 0; k < rects.length; k++) {
      tt = Math.max(0, Math.min(1, (t * 1.6) - (k / rects.length) * 0.6));
      hh = rects[k].h * ease(tt);
      rects[k].el.setAttribute("y", pt + h - hh); rects[k].el.setAttribute("height", hh);
    }
  }
  if (sinAnim) { pinta(1); } else { anima(1100, function (t) { pinta(t); }); }
}

// ---------- barras horizontales (rankings) ----------
function barrasH(box, filas, o, sinAnim) {
  o = o || {};
  if (!filas || !filas.length) { vacio(box); return; }
  var mx = maxDe(filas, function (f) { return num(f.v); }) || 1, h = "", i, f, col;
  for (i = 0; i < filas.length; i++) {
    f = filas[i]; col = o.color ? o.color(f, i) : PAL[o.unColor ? 0 : i % PAL.length];
    h += '<div class="hb"><div class="r1"><span class="n" title="' + esc(f.n) + '">' + (o.rank ? '<span class="mut">' + (i + 1) + ".&nbsp;</span>" : "") + esc(capital(f.n)) + "</span>" +
         '<span class="v num">' + (o.fmt || fmtM)(f.v) + "</span>" + (o.extra ? '<span class="x mut num">' + o.extra(f) + "</span>" : "") +
         '</div><div class="track"><div class="fill" style="background:' + col + ";transition-delay:" + (sinAnim ? 0 : i * 45) + 'ms" data-w="' +
         Math.max(1.5, num(f.v) / mx * 100).toFixed(1) + '"></div></div></div>';
  }
  box.innerHTML = h;
  var fs = box.getElementsByTagName("div");
  setTimeout(function () { for (var k = 0; k < fs.length; k++) { if (fs[k].className === "fill") { fs[k].style.width = fs[k].getAttribute("data-w") + "%"; } } }, sinAnim ? 0 : 40);
}

// ---------- dona ----------
function dona(box, filas, o, sinAnim) {
  o = o || {};
  if (!filas || !filas.length) { vacio(box); return; }
  var tot = 0, i, max = o.max || 7, fs = [], resto = 0;
  for (i = 0; i < filas.length; i++) { if (i < max) { fs.push({ n: filas[i].n, v: num(filas[i].v) }); } else { resto += num(filas[i].v); } }
  if (resto > 0) { fs.push({ n: "Otros", v: resto }); }
  for (i = 0; i < fs.length; i++) { tot += fs[i].v; }
  if (tot <= 0) { vacio(box); return; }
  var R = 74, grosor = 22, C = 86, angosta = (box.clientWidth || 400) < 470;
  box.innerHTML = '<div class="dona' + (angosta ? " angosta" : "") + '"><div class="g"></div><div class="ley"></div></div>';
  var g = box.firstChild.firstChild, ley = box.firstChild.lastChild, svg = S("svg", { width: C * 2, height: C * 2 }, g), arcs = [], hl = "<table>";
  S("circle", { cx: C, cy: C, r: R, fill: "none", stroke: th().track, "stroke-width": grosor }, svg);
  for (i = 0; i < fs.length; i++) {
    arcs.push(S("path", { fill: "none", stroke: PAL[i % PAL.length], "stroke-width": grosor, "stroke-linecap": "butt" }, svg));
    hl += '<tr><td class="c1"><i style="background:' + PAL[i % PAL.length] + '"></i></td><td title="' + esc(fs[i].n) + '">' + esc(capital(fs[i].n)) +
          '</td><td class="c3 mut num">' + (o.fmtLey || fmtMC)(fs[i].v) + '</td><td class="c4 num">' + fmtN(fs[i].v / tot * 100, 0) + "%</td></tr>";
  }
  hl += "</table>";
  var t1 = S("text", { x: C, y: C - 2, "text-anchor": "middle", fill: th().txt, "font-size": 17, "font-weight": 700 }, svg);
  t1.appendChild(document.createTextNode((o.fmtCentro || fmtMC)(tot)));
  var t2 = S("text", { x: C, y: C + 17, "text-anchor": "middle", fill: th().eje, "font-size": 11 }, svg);
  t2.appendChild(document.createTextNode(o.centro || "total"));
  ley.innerHTML = hl;
  function arco(a0, a1) {
    if (a1 - a0 >= Math.PI * 2 - 0.0001) { a1 = a0 + Math.PI * 2 - 0.0001; }
    var x0 = C + R * Math.sin(a0), y0 = C - R * Math.cos(a0), x1 = C + R * Math.sin(a1), y1 = C - R * Math.cos(a1);
    return "M" + x0.toFixed(2) + " " + y0.toFixed(2) + "A" + R + " " + R + " 0 " + (a1 - a0 > Math.PI ? 1 : 0) + " 1 " + x1.toFixed(2) + " " + y1.toFixed(2);
  }
  function pinta(t) {
    var a = 0, k, s, lim = Math.PI * 2 * t;
    for (k = 0; k < fs.length; k++) {
      s = fs[k].v / tot * Math.PI * 2;
      if (a >= lim) { arcs[k].setAttribute("d", ""); } else { arcs[k].setAttribute("d", arco(a, Math.min(a + s, lim) - (fs.length > 1 ? 0.012 : 0))); }
      a += s;
    }
  }
  if (sinAnim) { pinta(1); } else { anima(1200, pinta); }
  function resalta(k, on) {
    var q; for (q = 0; q < arcs.length; q++) { arcs[q].setAttribute("stroke-width", on && q === k ? grosor + 7 : grosor); arcs[q].setAttribute("opacity", on && q !== k ? 0.45 : 1); }
    var its = ley.getElementsByTagName("tr"); for (q = 0; q < its.length; q++) { its[q].className = on && q === k ? "hl" : ""; }
  }
  var trs = ley.getElementsByTagName("tr");
  for (i = 0; i < fs.length; i++) {
    (function (k) {
      arcs[k].addEventListener("mousemove", function (e) { resalta(k, true); tip('<div class="t1">' + esc(fs[k].n) + "</div><b>" + (o.fmt || fmtM)(fs[k].v) + "</b> &middot; " + fmtP(fs[k].v / tot * 100), e.clientX, e.clientY); });
      arcs[k].addEventListener("mouseleave", function () { resalta(k, false); sinTip(); });
      trs[k].onmouseenter = function () { resalta(k, true); };
      trs[k].onmouseleave = function () { resalta(k, false); };
    })(i);
  }
}

// ---------- barra apilada (antiguedad) ----------
function apilada(box, partes, sinAnim) {
  var tot = 0, i, h = '<div class="apil">', ley = '<div class="leyenda" style="margin-top:12px">';
  for (i = 0; i < partes.length; i++) { tot += Math.max(0, num(partes[i].v)); }
  if (tot <= 0) { vacio(box, "No hay saldos pendientes"); return; }
  for (i = 0; i < partes.length; i++) {
    h += '<div style="background:' + partes[i].c + '" data-w="' + (Math.max(0, num(partes[i].v)) / tot * 100).toFixed(2) + '" title="' + esc(partes[i].n) + '"></div>';
    ley += '<span><i style="background:' + partes[i].c + '"></i>' + partes[i].n + ' <b class="num">' + fmtMC(partes[i].v) + '</b> <span class="mut">' + fmtN(num(partes[i].v) / tot * 100, 0) + "%</span></span>";
  }
  box.innerHTML = h + "</div>" + ley + "</div>";
  var ds = box.firstChild.childNodes;
  setTimeout(function () { for (var k = 0; k < ds.length; k++) { ds[k].style.width = ds[k].getAttribute("data-w") + "%"; } }, sinAnim ? 0 : 40);
}

// ---------- mapa de calor dia x hora ----------
function calor(box, filas, sinAnim) {
  if (!filas || !filas.length) { vacio(box, "No hay ventas con hora registrada en este per\\u00edodo"); return; }
  var m = {}, hMin = 23, hMax = 0, mx = 0, i, f, k, d, hr, orden = [2, 3, 4, 5, 6, 7, 1], h, c, a, tot = {};
  for (i = 0; i < filas.length; i++) {
    f = filas[i]; hr = num(f.h); if (hr < 0 || hr > 23) { continue; }
    m[f.d + "-" + hr] = f; hMin = Math.min(hMin, hr); hMax = Math.max(hMax, hr); mx = Math.max(mx, num(f.v));
  }
  h = '<table class="calor"><tr><th></th>';
  for (k = hMin; k <= hMax; k++) { h += '<th class="mut">' + k + "</th>"; }
  h += "</tr>";
  for (i = 0; i < 7; i++) {
    d = orden[i]; h += '<tr><td class="dia mut">' + DIAS[d - 1] + "</td>";
    for (k = hMin; k <= hMax; k++) {
      f = m[d + "-" + k]; a = f ? Math.max(0.08, num(f.v) / mx) : 0;
      c = f ? "rgba(255,175,34," + a.toFixed(3) + ")" : (estado.tema === "oscuro" ? "#141a30" : "#f4f6fa");
      h += '<td style="background:' + c + ";transition-delay:" + (sinAnim ? 0 : (k - hMin) * 25 + i * 12) + 'ms" data-k="' + d + "-" + k + '"></td>';
    }
    h += "</tr>";
  }
  box.innerHTML = h + "</table>";
  var tds = box.getElementsByTagName("td");
  setTimeout(function () { for (var q = 0; q < tds.length; q++) { if (tds[q].className !== "dia mut") { tds[q].className = "ver"; } } }, sinAnim ? 0 : 30);
  box.onmousemove = function (e) {
    var t = e.target || e.srcElement, key = t.getAttribute ? t.getAttribute("data-k") : null, ff, p;
    if (!key) { sinTip(); return; }
    ff = m[key]; p = key.split("-");
    tip('<div class="t1">' + DIAS[parseInt(p[0], 10) - 1] + " de " + p[1] + " a " + (parseInt(p[1], 10) + 1) + " h</div>" +
        (ff ? "<b>" + fmtM(ff.v) + "</b> &middot; " + fmtN(ff.c) + " ventas" : "Sin ventas"), e.clientX, e.clientY);
  };
  box.onmouseleave = sinTip;
}

// ---------- tabla ----------
function tabla(box, cols, filas, vacioTxt) {
  if (!filas || !filas.length) { vacio(box, vacioTxt); return; }
  var h = '<table class="tabla"><tr>', i, j, c;
  for (j = 0; j < cols.length; j++) { h += "<th" + (cols[j].der ? ' class="der"' : "") + ">" + cols[j].t + "</th>"; }
  h += "</tr>";
  for (i = 0; i < filas.length; i++) {
    h += "<tr>";
    for (j = 0; j < cols.length; j++) {
      c = cols[j]; h += '<td class="' + (c.der ? "der num" : "") + (c.ell ? " ell" : "") + '"' + (c.ell ? ' title="' + esc(filas[i][c.k]) + '"' : "") + ">" +
           (c.f ? c.f(filas[i][c.k], filas[i]) : esc(c.ell ? capital(filas[i][c.k]) : filas[i][c.k])) + "</td>";
    }
    h += "</tr>";
  }
  box.innerHTML = h + "</table>";
}

// Arma etiquetas y datos alineados (dia a dia o mes a mes) del periodo
function serieAlineada(filas, desde, hasta, agrupa) {
  var m = {}, i, et = [], tit = [], dat = [], cant = [], d, k, dd;
  for (i = 0; i < (filas || []).length; i++) { m[filas[i].f.substr(0, agrupa === "mes" ? 7 : 10)] = filas[i]; }
  if (agrupa === "mes") {
    d = new Date(desde.getFullYear(), desde.getMonth(), 1);
    while (d <= hasta) {
      k = iso(d).substr(0, 7); et.push(MESES[d.getMonth()] + (d.getMonth() === 0 || !et.length ? " " + String(d.getFullYear()).substr(2) : ""));
      tit.push(MESES_L[d.getMonth()] + " " + d.getFullYear());
      dat.push(m[k] ? num(m[k].v) : 0); cant.push(m[k] ? num(m[k].c) : 0);
      d = new Date(d.getFullYear(), d.getMonth() + 1, 1);
    }
  } else {
    d = new Date(desde.getTime());
    while (d <= hasta) {
      k = iso(d); dd = d.getDate();
      et.push(dd + "/" + (d.getMonth() + 1)); tit.push(DIAS[d.getDay()] + " " + fecTxt(k));
      dat.push(m[k] ? num(m[k].v) : 0); cant.push(m[k] ? num(m[k].c) : 0);
      d = sumaDias(d, 1);
    }
  }
  return { et: et, tit: tit, dat: dat, cant: cant };
}
function valores(filas) { var a = [], i; for (i = 0; i < (filas || []).length; i++) { a.push(num(filas[i].v)); } return a; }

// =====================================================================
// Secciones
// =====================================================================
var RENDER = {};

// ---------------------------- RESUMEN ----------------------------
RENDER.resumen = function () {
  $("cont").innerHTML =
    '<div class="fila">' + kpiHtml("kVen", "Ventas netas") + kpiHtml("kMar", "Margen bruto") + kpiHtml("kTic", "Ticket promedio") +
    kpiHtml("kCob", "Cobranzas") + kpiHtml("kCom", "Compras") + kpiHtml("kPag", "Pagos a proveedores") + "</div>" +
    '<div class="fila"><div class="col c8">' + card("gVen", "Evoluci\\u00f3n de las ventas", '<span id="gVenLey"></span>') + "</div>" +
    '<div class="col c4">' + card("gFor", "C\\u00f3mo te pagan", "Ventas por forma de pago") + "</div></div>" +
    '<div class="fila"><div class="col c4">' + card("gTop", "Lo que m\\u00e1s se vende", "Productos por facturaci\\u00f3n") + "</div>" +
    '<div class="col c4">' + card("gPos", "Posici\\u00f3n financiera", "Hoy, sin importar el per\\u00edodo") + "</div>" +
    '<div class="col c4">' + card("gAle", "Para prestar atenci\\u00f3n", "Avisos de hoy") + "</div></div>";
  cargar("resumen", {}, pintarResumen);
};
function pintarKpis(d, sinAnim) {
  var k = d.kpi || {}, a = d.kpiAnt || {}, sp = d.spark || {}, s = serieAlineada(d.serie, estado.desde, estado.hasta, d.agrupa), txt = "";
  var mar = num(k.mbase) ? num(k.margen) / num(k.mbase) * 100 : 0, marA = num(a.mbase) ? num(a.margen) / num(a.mbase) * 100 : 0;
  var tic = num(k.comprobantes) ? num(k.ventas) / num(k.comprobantes) : 0, ticA = num(a.comprobantes) ? num(a.ventas) / num(a.comprobantes) : 0;
  var ticS = [], i;
  for (i = 0; i < s.dat.length; i++) { ticS.push(s.cant[i] ? s.dat[i] / s.cant[i] : 0); }
  kpiPintar("kVen", k.ventas, fmtM, a.ventas, 1, "", s.dat, PAL[0], sinAnim);
  kpiPintar("kMar", mar, function (v) { return fmtP(v); }, null, 0,
            '<span class="mut">' + fmtMC(k.margen) + (num(k.mtotal) && num(k.mbase) / num(k.mtotal) < 0.95 ? " &middot; " + fmtN(num(k.mbase) / num(k.mtotal) * 100, 0) + "% con costo" : "") + "</span>",
            serieAlineada(sp.margen, estado.desde, estado.hasta, d.agrupa).dat, PAL[2], sinAnim);
  if (marA) { $("kMar-p").innerHTML = '<span class="delta ' + (mar >= marA ? "d-up" : "d-dn") + '">' + (mar >= marA ? "\\u25b2 " : "\\u25bc ") + fmtN(Math.abs(mar - marA), 1) + " pts</span>" + $("kMar-p").innerHTML; }
  kpiPintar("kTic", tic, fmtM, ticA, 1, '<span class="mut">' + fmtN(k.comprobantes) + " ventas</span>", ticS, PAL[3], sinAnim);
  kpiPintar("kCob", k.cobranzas, fmtM, a.cobranzas, 1, "", serieAlineada(sp.cobranzas, estado.desde, estado.hasta, d.agrupa).dat, PAL[1], sinAnim);
  kpiPintar("kCom", k.compras, fmtM, a.compras, 0, "", serieAlineada(sp.compras, estado.desde, estado.hasta, d.agrupa).dat, PAL[5], sinAnim);
  kpiPintar("kPag", k.pagos, fmtM, a.pagos, 0, "", serieAlineada(sp.pagos, estado.desde, estado.hasta, d.agrupa).dat, PAL[4], sinAnim);
}
function graficoVentas(boxId, leyId, d, sinAnim) {
  var s = serieAlineada(d.serie, estado.desde, estado.hasta, d.agrupa), sa = serieAlineada(d.serieAnt, estado.pdesde, estado.phasta, d.agrupa), datA = [], titA = [], i;
  for (i = 0; i < s.dat.length; i++) { datA.push(i < sa.dat.length ? sa.dat[i] : null); titA.push(i < sa.tit.length ? sa.tit[i] : ""); }
  $(leyId).innerHTML = '<span class="leyenda"><span><i class="lin" style="background:' + PAL[0] + '"></i>Per\\u00edodo actual</span>' +
                       '<span><i class="lin" style="background:' + th().ant + '"></i>Per\\u00edodo anterior</span></span>';
  lineas($(boxId), { etiquetas: s.et, titulos: s.tit, series: [
    { nombre: "Actual", datos: s.dat, color: PAL[0], area: true, ancho: 2.6 },
    { nombre: "Anterior", datos: datA, color: th().ant, punteado: true, ancho: 1.8, titulos: titA }] }, sinAnim);
}
function pintarResumen(d, sinAnim) {
  pintarKpis(d, sinAnim);
  graficoVentas("gVen", "gVenLey", d, sinAnim);
  dona($("gFor"), d.formas, { centro: "vendido" }, sinAnim);
  barrasH($("gTop"), d.top, { rank: true, unColor: true, extra: function (f) { return fmtCant(f.c) + " u."; } }, sinAnim);
  var p = d.posicion || {}, mx = Math.max(num(p.cobrar), num(p.pagar), 1), h = "";
  h += '<div class="pos"><span class="n mut">Te deben tus clientes</span><span class="v num" style="color:#22C3A6">' + fmtM(p.cobrar) + "</span></div>" +
       '<div class="track" style="height:12px"><div class="fill" style="height:12px;background:#22C3A6" data-w="' + (num(p.cobrar) / mx * 100).toFixed(1) + '"></div></div>' +
       '<div class="mut" style="font-size:11.5px;margin:6px 0 18px 0">Vencido: <b class="num">' + fmtM(p.cobrarvenc) + "</b></div>" +
       '<div class="pos"><span class="n mut">Le deb\\u00e9s a proveedores</span><span class="v num" style="color:#FF6B6B">' + fmtM(p.pagar) + "</span></div>" +
       '<div class="track" style="height:12px"><div class="fill" style="height:12px;background:#FF6B6B" data-w="' + (num(p.pagar) / mx * 100).toFixed(1) + '"></div></div>' +
       '<div class="mut" style="font-size:11.5px;margin:6px 0 16px 0">Vencido: <b class="num">' + fmtM(p.pagarvenc) + "</b></div>" +
       '<div class="sep" style="padding-top:12px"><span class="mut">Balance</span><span class="big num" style="float:right;font-size:20px;color:' +
       (num(p.cobrar) - num(p.pagar) >= 0 ? "#22C3A6" : "#FF6B6B") + '">' + fmtM(num(p.cobrar) - num(p.pagar)) + "</span></div>";
  $("gPos").innerHTML = h;
  var fills = $("gPos").getElementsByTagName("div");
  setTimeout(function () { for (var q = 0; q < fills.length; q++) { if (fills[q].className === "fill") { fills[q].style.width = fills[q].getAttribute("data-w") + "%"; } } }, sinAnim ? 0 : 40);
  var a = d.alertas || {}, al = "";
  if (num(a.vtosn)) { al += alerta("reloj", "#FFAF22", fmtN(a.vtosn) + (num(a.vtosn) === 1 ? " factura de compra vence" : " facturas de compra vencen") + " esta semana", "Total a pagar: " + fmtM(a.vtosv)); }
  if (num(a.morosos)) { al += alerta("usuario", "#FF6B6B", fmtN(a.morosos) + (num(a.morosos) === 1 ? " cliente" : " clientes") + " con deuda de m\\u00e1s de 60 d\\u00edas", "Revis\\u00e1 Clientes y cobranzas"); }
  if (num(a.bajomin)) { al += alerta("caja2", "#4F8CFF", fmtN(a.bajomin) + (num(a.bajomin) === 1 ? " art\\u00edculo" : " art\\u00edculos") + " por debajo del stock m\\u00ednimo", "Mir\\u00e1 el detalle en Stock"); }
  if (!al) { al = alerta("ia", "#22C3A6", "Todo en orden", "No hay vencimientos ni alertas para hoy"); }
  $("gAle").innerHTML = al;
}
function alerta(ic, color, t1, t2) {
  return '<div class="alerta"><div class="ic" style="background:' + color + '22;color:' + color + '">' + icono(ic, 17, color) + "</div><b>" + t1 + '</b><span class="mut">' + t2 + "</span></div>";
}

// ---------------------------- VENTAS ----------------------------
RENDER.ventas = function () {
  var tabs = '<span class="tabs" id="tabsRank">' + tabsHtml() + "</span>";
  $("cont").innerHTML =
    '<div class="fila">' + kpiHtml("vVen", "Ventas netas") + kpiHtml("vCan", "Cantidad de ventas") + kpiHtml("vTic", "Ticket promedio") +
    kpiHtml("vUni", "Unidades vendidas") + kpiHtml("vMar", "Margen bruto") + kpiHtml("vDev", "Devoluciones (NC)") + "</div>" +
    '<div class="fila"><div class="col c12">' + card("gEvo", "Ventas en el tiempo", '<span id="gEvoLey"></span>') + "</div></div>" +
    '<div class="fila"><div class="col c7">' + card("gCal", "\\u00bfCu\\u00e1ndo vend\\u00e9s m\\u00e1s?", "Importe vendido por d\\u00eda de la semana y hora") + "</div>" +
    '<div class="col c5">' + card("gRank", "Ventas por categor\\u00eda", "Con margen bruto estimado", "", tabs) + "</div></div>" +
    '<div class="fila"><div class="col c7">' + card("gProd", "Productos m\\u00e1s vendidos", "Por facturaci\\u00f3n, con unidades y margen") + "</div>" +
    '<div class="col c5">' + card("gVend", "Ventas por vendedor", "Importe neto y cantidad de ventas") + "</div></div>";
  cargar("ventas", { agrupar: estado.agrupar }, pintarVentas);
};
function tabsHtml() {
  var t = [["rubro", "Rubro"], ["marca", "Marca"], ["depto", "Depto."], ["proveedor", "Proveedor"]], h = "", i;
  for (i = 0; i < t.length; i++) { h += '<span class="' + (estado.agrupar === t[i][0] ? "on" : "") + '" onclick="cambiarRank(\\'' + t[i][0] + '\\')">' + t[i][1] + "</span>"; }
  return h;
}
function cambiarRank(a) {
  estado.agrupar = a; $("tabsRank").innerHTML = tabsHtml();
  $("gRank").innerHTML = '<div class="esq" style="width:80%"></div><div class="esq" style="width:60%"></div>';
  pedir("ranking", paramsPer({ agrupar: a }), function (d, err) { if (estado.sec === "ventas" && !err) { pintarRanking(d); } });
}
function pintarRanking(filas, sinAnim) {
  barrasH($("gRank"), filas, { rank: true, extra: function (f) { return f.m === null || f.m === undefined ? "" : fmtP(f.m) + " margen"; } }, sinAnim);
}
function pintarVentas(d, sinAnim) {
  var k = d.kpi || {}, a = d.kpiAnt || {}, x = d.extra || {}, s = serieAlineada(d.serie, estado.desde, estado.hasta, d.agrupa), ticS = [], i;
  var mar = num(k.mbase) ? num(k.margen) / num(k.mbase) * 100 : 0;
  for (i = 0; i < s.dat.length; i++) { ticS.push(s.cant[i] ? s.dat[i] / s.cant[i] : 0); }
  kpiPintar("vVen", k.ventas, fmtM, a.ventas, 1, "", s.dat, PAL[0], sinAnim);
  kpiPintar("vCan", k.comprobantes, function (v) { return fmtN(v); }, a.comprobantes, 1, "", s.cant, PAL[1], sinAnim);
  kpiPintar("vTic", num(k.comprobantes) ? num(k.ventas) / num(k.comprobantes) : 0, fmtM,
            num(a.comprobantes) ? num(a.ventas) / num(a.comprobantes) : 0, 1, "", ticS, PAL[3], sinAnim);
  kpiPintar("vUni", x.unidades, function (v) { return fmtN(v); }, null, 0, '<span class="mut">art\\u00edculos en el per\\u00edodo</span>', null, null, sinAnim);
  kpiPintar("vMar", mar, function (v) { return fmtP(v); }, null, 0, '<span class="mut">' + fmtMC(k.margen) + " de ganancia bruta</span>", null, null, sinAnim);
  kpiPintar("vDev", x.devol, fmtM, null, 0, '<span class="mut">' + (num(k.ventas) ? fmtP(num(x.devol) / (num(k.ventas) + num(x.devol)) * 100) + " de lo facturado" : "") + "</span>", null, null, sinAnim);
  graficoVentas("gEvo", "gEvoLey", d, sinAnim);
  calor($("gCal"), d.calor, sinAnim);
  pintarRanking(d.ranking, sinAnim);
  tabla($("gProd"), [
    { t: "Producto", k: "n", ell: true },
    { t: "Unidades", k: "c", der: true, f: function (v) { return fmtCant(v); } },
    { t: "Vendido", k: "v", der: true, f: function (v) { return fmtM(v); } },
    { t: "Margen", k: "m", der: true, f: function (v) { return v === null || v === undefined ? '<span class="mut">-</span>' : '<span class="pill ' + (v < 10 ? "p-rojo" : v < 25 ? "p-amar" : "p-verd") + '">' + fmtP(v) + "</span>"; } }
  ], d.productos);
  barrasH($("gVend"), d.vendedores, { rank: true, unColor: true, color: function () { return PAL[1]; }, extra: function (f) { return fmtN(f.c) + " ventas"; } }, sinAnim);
}

// ---------------------------- CLIENTES ----------------------------
RENDER.clientes = function () {
  $("cont").innerHTML =
    '<div class="fila">' + kpiHtml("cCob", "Cobrado en el per\\u00edodo") + kpiHtml("cRec", "Recibos") + kpiHtml("cDeu", "Te deben") +
    kpiHtml("cVen", "Deuda vencida") + kpiHtml("cCli", "Clientes con deuda") + kpiHtml("cPro", "Deuda promedio") + "</div>" +
    '<div class="fila"><div class="col c7">' + card("gAge", "Antig\\u00fcedad de la deuda", "Saldos seg\\u00fan d\\u00edas desde el vencimiento") + "</div>" +
    '<div class="col c5">' + card("gCfp", "C\\u00f3mo te pagan las cuentas", "Cobranzas por forma de pago") + "</div></div>" +
    '<div class="fila"><div class="col c12">' + card("gCob", "Cobranzas en el tiempo", "") + "</div></div>" +
    '<div class="fila"><div class="col c6">' + card("gDeu", "Los que m\\u00e1s te deben", "Saldo y d\\u00edas de la deuda m\\u00e1s vieja") + "</div>" +
    '<div class="col c6">' + card("gMej", "Tus mejores clientes", "Por compras en el per\\u00edodo") + "</div></div>";
  cargar("clientes", {}, pintarClientes);
};
function pintarClientes(d, sinAnim) {
  var k = d.kpi || {}, g = d.aging || {}, s = serieAlineada(d.cobros, estado.desde, estado.hasta, "dia");
  kpiPintar("cCob", k.cobrado, fmtM, null, 0, "", s.dat, PAL[1], sinAnim);
  kpiPintar("cRec", k.recibos, function (v) { return fmtN(v); }, null, 0, '<span class="mut">recibos emitidos</span>', null, null, sinAnim);
  kpiPintar("cDeu", k.deuda, fmtM, null, 0, '<span class="mut">saldo total a cobrar</span>', null, null, sinAnim);
  kpiPintar("cVen", k.vencida, fmtM, null, 0, '<span class="mut">' + (num(k.deuda) ? fmtP(num(k.vencida) / num(k.deuda) * 100) + " del total" : "") + "</span>", null, null, sinAnim);
  kpiPintar("cCli", k.deudores, function (v) { return fmtN(v); }, null, 0, '<span class="mut">con saldo pendiente</span>', null, null, sinAnim);
  kpiPintar("cPro", num(k.deudores) ? num(k.deuda) / num(k.deudores) : 0, fmtM, null, 0, '<span class="mut">por cliente</span>', null, null, sinAnim);
  apilada($("gAge"), [
    { n: "Al d\\u00eda", v: g.a0, c: "#22C3A6" }, { n: "1-30 d\\u00edas", v: g.a30, c: "#A3E635" }, { n: "31-60", v: g.a60, c: "#FFAF22" },
    { n: "61-90", v: g.a90, c: "#FB923C" }, { n: "M\\u00e1s de 90", v: g.a91, c: "#FF6B6B" }], sinAnim);
  // Lectura rapida: que parte de la deuda es dificil de cobrar
  var tot = num(g.a0) + num(g.a30) + num(g.a60) + num(g.a90) + num(g.a91), p90 = tot ? (num(g.a90) + num(g.a91)) / tot * 100 : 0;
  if (tot > 0) {
    $("gAge").insertAdjacentHTML("beforeend", '<div class="sep" style="margin-top:16px;padding-top:14px;line-height:1.55">' +
      (p90 >= 50 ? '<span class="pill p-rojo">Atenci\\u00f3n</span> ' : p90 >= 20 ? '<span class="pill p-amar">Ojo</span> ' : '<span class="pill p-verd">Bien</span> ') +
      "El <b>" + fmtP(p90, 0) + "</b> de lo que te deben tiene m\\u00e1s de 60 d\\u00edas de atraso (" + fmtM(num(g.a90) + num(g.a91)) + "). " +
      '<span class="mut">Las facturas sin vencimiento cargado se consideran vencidas a los 30 d\\u00edas.</span></div>');
  }
  dona($("gCfp"), d.formas, { centro: "cobrado" }, sinAnim);
  lineas($("gCob"), { etiquetas: s.et, titulos: s.tit, alto: 220, series: [{ nombre: "Cobrado", datos: s.dat, color: PAL[1], area: true }] }, sinAnim);
  tabla($("gDeu"), [
    { t: "Cliente", k: "n", ell: true },
    { t: "D\\u00edas", k: "d", der: true, f: function (v) { v = num(v); return '<span class="pill ' + (v > 90 ? "p-rojo" : v > 30 ? "p-amar" : "p-verd") + '">' + (v > 0 ? fmtN(v) : "al d\\u00eda") + "</span>"; } },
    { t: "Saldo", k: "v", der: true, f: function (v) { return "<b>" + fmtM(v) + "</b>"; } }
  ], d.deudores, "Ning\\u00fan cliente te debe");
  barrasH($("gMej"), d.mejores, { rank: true, unColor: true, color: function () { return PAL[2]; }, extra: function (f) { return fmtN(f.c) + " compras"; } }, sinAnim);
}

// ---------------------------- COMPRAS ----------------------------
RENDER.compras = function () {
  $("cont").innerHTML =
    '<div class="fila">' + kpiHtml("pCom", "Compras del per\\u00edodo") + kpiHtml("pPag", "Pagado a proveedores") + kpiHtml("pDeu", "Le deb\\u00e9s") +
    kpiHtml("pVen", "Ya vencido") + kpiHtml("pSem", "Vence esta semana") + kpiHtml("pAnt", "Anticipos a favor") + "</div>" +
    '<div class="fila"><div class="col c7">' + card("gVto", "Calendario de pagos", "Saldos de facturas de compra seg\\u00fan su vencimiento") + "</div>" +
    '<div class="col c5">' + card("gCta", "En qu\\u00e9 se gasta", "Compras por cuenta") + "</div></div>" +
    '<div class="fila"><div class="col c6">' + card("gPrv", "A qui\\u00e9n le compr\\u00e1s m\\u00e1s", "Compras del per\\u00edodo por proveedor") + "</div>" +
    '<div class="col c6">' + card("gDpr", "A qui\\u00e9n le deb\\u00e9s", "Saldo y vencimiento m\\u00e1s pr\\u00f3ximo") + "</div></div>";
  cargar("compras", {}, pintarCompras);
};
function pintarCompras(d, sinAnim) {
  var k = d.kpi || {}, v = d.vtos || {};
  kpiPintar("pCom", k.compras, fmtM, null, 0, '<span class="mut">sin remitos</span>', null, null, sinAnim);
  kpiPintar("pPag", k.pagado, fmtM, null, 0, '<span class="mut">\\u00f3rdenes de pago</span>', null, null, sinAnim);
  kpiPintar("pDeu", k.deuda, fmtM, null, 0, '<span class="mut">saldo total</span>', null, null, sinAnim);
  kpiPintar("pVen", k.vencida, fmtM, null, 0, '<span class="mut">' + (num(k.deuda) ? fmtP(num(k.vencida) / num(k.deuda) * 100) + " de la deuda" : "") + "</span>", null, null, sinAnim);
  kpiPintar("pSem", k.semana, fmtM, null, 0, '<span class="mut">pr\\u00f3ximos 7 d\\u00edas</span>', null, null, sinAnim);
  kpiPintar("pAnt", k.anticipos, fmtM, null, 0, '<span class="mut">pagos a cuenta</span>', null, null, sinAnim);
  columnas($("gVto"), { etiquetas: ["Vencido", "Esta semana", "En 2 semanas", "En 3 semanas", "En 4 semanas", "M\\u00e1s adelante"],
    datos: [num(v.s0), num(v.s1), num(v.s2), num(v.s3), num(v.s4), num(v.s5)], colores: ["#FF6B6B", "#FFAF22", "#4F8CFF", "#4F8CFF", "#4F8CFF", "#64748B"], alto: 250 }, sinAnim);
  dona($("gCta"), d.cuentas, { centro: "comprado" }, sinAnim);
  barrasH($("gPrv"), d.proveedores, { rank: true, unColor: true, color: function () { return PAL[5]; }, extra: function (f) { return fmtN(f.c) + " comp."; } }, sinAnim);
  tabla($("gDpr"), [
    { t: "Proveedor", k: "n", ell: true },
    { t: "Vence", k: "f", der: true, f: function (x) { var dd = x ? Math.round((deIso(x) - estado.hoy) / 86400000) : 0; return '<span class="pill ' + (dd < 0 ? "p-rojo" : dd <= 7 ? "p-amar" : "p-verd") + '">' + fecTxt(x) + "</span>"; } },
    { t: "Saldo", k: "v", der: true, f: function (x) { return "<b>" + fmtM(x) + "</b>"; } }
  ], d.deuda, "No le deb\\u00e9s a ning\\u00fan proveedor");
}

// ---------------------------- STOCK ----------------------------
RENDER.stock = function () {
  $("cont").innerHTML =
    '<div class="fila">' + kpiHtml("sCos", "Stock a costo") + kpiHtml("sVen", "Stock a precio de venta") + kpiHtml("sArt", "Art\\u00edculos con stock") +
    kpiHtml("sBaj", "Bajo el m\\u00ednimo") + kpiHtml("sFal", "Sin stock que se venden") + kpiHtml("sQui", "Capital inmovilizado") + "</div>" +
    '<div class="fila"><div class="col c5">' + card("gRub", "D\\u00f3nde est\\u00e1 la plata", "Stock valorizado a costo por rubro") + "</div>" +
    '<div class="col c7">' + card("gBaj", "Para reponer", "Art\\u00edculos por debajo del stock m\\u00ednimo") + "</div></div>" +
    '<div class="fila"><div class="col c12">' + card("gQui", "Mercader\\u00eda sin movimiento", "Con stock y sin ventas en los \\u00faltimos 90 d\\u00edas, ordenada por valor") + "</div></div>";
  cargar("stock", {}, pintarStock);
};
function pintarStock(d, sinAnim) {
  var k = d.kpi || {}, q = d.quietosTot || {}, f = d.faltantes || {};
  kpiPintar("sCos", k.costo, fmtM, null, 0, '<span class="mut">valor de reposici\\u00f3n</span>', null, null, sinAnim);
  kpiPintar("sVen", k.venta, fmtM, null, 0, '<span class="mut">' + (num(k.costo) ? "+" + fmtP((num(k.venta) / num(k.costo) - 1) * 100, 0) + " sobre costo" : "") + "</span>", null, null, sinAnim);
  kpiPintar("sArt", k.con_stock, function (v) { return fmtN(v); }, null, 0, '<span class="mut">art\\u00edculos distintos</span>', null, null, sinAnim);
  kpiPintar("sBaj", k.bajo_min, function (v) { return fmtN(v); }, null, 0, '<span class="mut">para reponer</span>', null, null, sinAnim);
  kpiPintar("sFal", f.n, function (v) { return fmtN(v); }, null, 0, '<span class="mut">vendidos en 30 d\\u00edas, hoy sin stock</span>', null, null, sinAnim);
  kpiPintar("sQui", q.v, fmtM, null, 0, '<span class="mut">' + fmtN(q.n) + " art\\u00edculos sin venta en 90 d\\u00edas</span>", null, null, sinAnim);
  dona($("gRub"), d.rubros, { centro: "a costo" }, sinAnim);
  tabla($("gBaj"), [
    { t: "Art\\u00edculo", k: "n", ell: true },
    { t: "Stock", k: "s", der: true, f: function (v) { return '<span class="pill ' + (num(v) <= 0 ? "p-rojo" : "p-amar") + '">' + fmtCant(v) + "</span>"; } },
    { t: "M\\u00ednimo", k: "m", der: true, f: function (v) { return fmtCant(v); } },
    { t: "Faltan", k: "f", der: true, f: function (v) { return "<b>" + fmtCant(v) + "</b>"; } }
  ], d.bajo, "Ning\\u00fan art\\u00edculo est\\u00e1 por debajo del m\\u00ednimo");
  tabla($("gQui"), [
    { t: "Art\\u00edculo", k: "n", ell: true },
    { t: "\\u00daltima compra", k: "f", der: true, f: function (v) { return v ? fecTxt(v) : '<span class="mut">-</span>'; } },
    { t: "Stock", k: "s", der: true, f: function (v) { return fmtCant(v); } },
    { t: "Valor a costo", k: "v", der: true, f: function (v) { return "<b>" + fmtM(v) + "</b>"; } }
  ], d.quietos, "Todo lo que ten\\u00e9s en stock se vendi\\u00f3 en los \\u00faltimos 90 d\\u00edas");
}

// ---------------------------- CAJA ----------------------------
RENDER.caja = function () {
  $("cont").innerHTML =
    '<div class="fila"><div class="col c5">' + card("gRes", "Resultado del per\\u00edodo", "Lo que entr\\u00f3 y lo que sali\\u00f3") + "</div>" +
    '<div class="col c7">' + card("gCev", "Movimiento de caja por d\\u00eda", '<span class="leyenda"><span><i style="background:#22C3A6"></i>Ingresos</span><span><i style="background:#FF6B6B"></i>Egresos</span></span>') + "</div></div>" +
    '<div class="fila"><div class="col c12">' + card("gCie", "Cierres de caja", "\\u00daltimos cierres del per\\u00edodo") + "</div></div>";
  cargar("caja", {}, pintarCaja);
};
function pintarCaja(d, sinAnim) {
  var r = d.resultado || {}, filas = [
    { n: "Ventas", v: num(r.ventas), c: "#22C3A6" }, { n: "Cobranzas", v: num(r.cobranzas), c: "#4F8CFF" },
    { n: "Compras", v: num(r.compras), c: "#FF6B6B" }, { n: "Pagos a proveedores", v: num(r.pagos), c: "#FB923C" }];
  barrasH($("gRes"), filas, { color: function (f) { return f.c; } }, sinAnim);
  // Dos lecturas que no se mezclan (las ventas en cuenta corriente vuelven como cobranzas)
  var bal1 = num(r.ventas) - num(r.compras), bal2 = num(r.cobranzas) - num(r.pagos);
  function linea(t, v, grande) {
    return '<div style="margin-top:10px;overflow:hidden"><span class="mut">' + t + '</span><span class="num' + (grande ? " big" : "") +
           '" style="float:right;font-weight:700;' + (grande ? "font-size:19px;" : "") + "color:" + (v >= 0 ? "#22C3A6" : "#FF6B6B") + '">' + fmtM(v) + "</span></div>";
  }
  $("gRes").insertAdjacentHTML("beforeend", '<div class="sep" style="padding-top:4px;margin-top:6px">' +
    linea("Ventas menos compras", bal1, true) + linea("Cobranzas menos pagos a proveedores", bal2, false) +
    '<div style="margin-top:10px;overflow:hidden"><span class="mut">Diferencias en los cierres de caja</span><b class="num" style="float:right">' + fmtM(r.diferencias) + "</b></div></div>");
  var ev = d.evolucion || [], et = [], ing = [], egr = [], i, tit = [];
  for (i = 0; i < ev.length; i++) { et.push(fecTxt(ev[i].f).substr(0, 5)); tit.push(fecTxt(ev[i].f)); ing.push(num(ev[i].i)); egr.push(num(ev[i].e)); }
  if (!ev.length) { vacio($("gCev"), "No hay cierres de caja en este per\\u00edodo"); }
  else { lineas($("gCev"), { etiquetas: et, titulos: tit, alto: 230, series: [
    { nombre: "Ingresos", datos: ing, color: "#22C3A6", area: true }, { nombre: "Egresos", datos: egr, color: "#FF6B6B", area: true }] }, sinAnim); }
  tabla($("gCie"), [
    { t: "Fecha", k: "f", f: function (v) { return fecTxt(v); } },
    { t: "Caja", k: "c", der: true },
    { t: "Hora", k: "h", der: true, f: function (v) { return esc(String(v || "").substr(0, 5)); } },
    { t: "Ingresos", k: "i", der: true, f: function (v) { return fmtM(v); } },
    { t: "Egresos", k: "e", der: true, f: function (v) { return fmtM(v); } },
    { t: "Efectivo", k: "x", der: true, f: function (v) { return fmtM(v); } },
    { t: "Diferencia", k: "d", der: true, f: function (v) { v = num(v); return Math.abs(v) < 1 ? '<span class="pill p-verd">sin diferencia</span>' : '<span class="pill ' + (v < 0 ? "p-rojo" : "p-amar") + '">' + fmtM(v) + "</span>"; } }
  ], d.cierres, "No hay cierres de caja en este per\\u00edodo");
}

// ---------------------------- ASISTENTE ----------------------------
var SUGERENCIAS = [
  "\\u00bfCu\\u00e1nto vend\\u00ed este mes comparado con el mes pasado?",
  "\\u00bfCu\\u00e1les son los 10 productos que m\\u00e1s vend\\u00ed esta semana?",
  "\\u00bfQu\\u00e9 rubro me deja m\\u00e1s margen este a\\u00f1o?",
  "\\u00bfQu\\u00e9 clientes me deben hace m\\u00e1s de 60 d\\u00edas?",
  "\\u00bfQu\\u00e9 facturas de proveedores vencen esta semana?",
  "\\u00bfEn qu\\u00e9 d\\u00eda y horario vendo m\\u00e1s?",
  "\\u00bfQu\\u00e9 art\\u00edculos con stock no se vendieron en 3 meses?",
  "\\u00bfC\\u00f3mo vienen las ventas de los \\u00faltimos 12 meses?"
];
var iaHist = "", iaOcupado = false, iaN = 0;
RENDER.ia = function () {
  estado.ultimo = null;
  if (!estado.ia) {
    $("cont").innerHTML = '<div id="ia"><div class="card entra"><h3>El asistente no est\\u00e1 configurado</h3><div class="sub mut" style="margin-top:8px;line-height:1.6">' +
      "Para usarlo hace falta cargar la clave del servicio de inteligencia artificial en la configuraci\\u00f3n central del sistema. " +
      "Consult\\u00e1 con soporte de BCN.</div></div></div>";
    return;
  }
  var sug = "", i;
  for (i = 0; i < SUGERENCIAS.length; i++) { sug += '<span class="chip sug" onclick="iaPreguntar(this.innerText)">' + SUGERENCIAS[i] + "</span>"; }
  $("cont").innerHTML = '<div id="ia">' +
    (iaHist ? "" : '<div class="card entra" id="iaBienv"><div style="overflow:hidden"><div style="float:left;width:46px;height:46px;border-radius:14px;background:#FFAF22;text-align:center;padding-top:11px">' +
      icono("ia", 24, "#141833") + '</div><div style="margin-left:62px"><h3 style="font-size:17px">Hola, \\u00bfqu\\u00e9 quer\\u00e9s saber de tu negocio?</h3>' +
      '<div class="mut" style="margin-top:4px">Pregunt\\u00e1 como le preguntar\\u00edas a tu contador: ventas, m\\u00e1rgenes, clientes, proveedores, stock o caja. ' +
      "Respondo con los datos de esta empresa.</div></div></div>" + '<div style="margin-top:16px">' + sug + "</div></div>") +
    '<div id="iaMsgs">' + iaHist + "</div>" +
    '<div id="iaBarra" style="position:relative"><textarea id="iaTxt" class="inp" placeholder="Escrib\\u00ed tu pregunta y apret\\u00e1 Enter..."></textarea>' +
    '<span id="iaEnviar" onclick="iaPreguntar()">Preguntar</span></div>' +
    '<div class="mut" style="font-size:11px;margin-top:8px;text-align:center">Las respuestas se generan con inteligencia artificial a partir de tus datos. Verific\\u00e1 los n\\u00fameros importantes.</div></div>';
  $("iaTxt").onkeydown = function (e) { e = e || window.event; if (e.keyCode === 13 && !e.shiftKey) { if (e.preventDefault) { e.preventDefault(); } iaPreguntar(); return false; } };
  setTimeout(function () { try { $("iaTxt").focus(); } catch (e) {} }, 50);
  iaBajar();
};
function iaBajar() { var c = $("cont"); c.scrollTop = c.scrollHeight; }
function iaNueva() { iaHist = ""; pedir("ia_nueva", {}); if (estado.sec === "ia") { RENDER.ia(); } }
function iaPreguntar(txt) {
  var t = (txt || ($("iaTxt") ? $("iaTxt").value : "") || "").replace(/^\\s+|\\s+$/g, "");
  if (!t || iaOcupado) { return; }
  if ($("iaTxt")) { $("iaTxt").value = ""; }
  if ($("iaBienv")) { $("iaBienv").parentNode.removeChild($("iaBienv")); }
  iaOcupado = true;
  var n = ++iaN;
  $("iaMsgs").insertAdjacentHTML("beforeend", '<div class="msg-u entra"><span>' + esc(t) + "</span></div>" +
    '<div class="burbuja-ia entra" id="iaR' + n + '"><span class="puntos"><span></span><span class="b"></span><span class="c"></span></span> <span class="mut">Analizando tus datos...</span></div>');
  iaBajar();
  pedir("ia", { pregunta: encodeURIComponent(t) }, function (d, err) {
    iaOcupado = false;
    var box = $("iaR" + n);
    if (!box) { return; }
    iaPintar(box, d || {}, err, n);
    iaHist = $("iaMsgs").innerHTML;
    // Que se lea desde el principio de la respuesta (con la pregunta arriba)
    var c = $("cont"), r = $("iaR" + n), y = 0, e = r;
    while (e && e !== c) { y += e.offsetTop; e = e.offsetParent; }
    c.scrollTop = Math.max(0, y - 70);
  });
}
function iaFmt(v, f) {
  if (v === null || v === undefined || v === "") { return ""; }
  switch (f) {
    case "moneda": return fmtM(v);
    case "porcentaje": return fmtP(v);
    case "cantidad": return fmtCant(v);
    case "numero": return fmtN(v, num(v) % 1 === 0 ? 0 : 2);
    case "fecha": return /^\\d{4}-\\d{2}-\\d{2}$/.test(String(v)) ? fecTxt(String(v)) : esc(v);
    case "texto": return esc(String(v));   // codigos: sin separador de miles
  }
  return typeof v === "number" ? fmtN(v, v % 1 === 0 ? 0 : 2) : esc(v);
}
// Columna de valor para el grafico: primero importes, despues cantidades o
// numeros; nunca un codigo (columna de texto o con "codigo" en el nombre)
function iaColValor(cols, fila) {
  var pref = ["moneda", "cantidad", "numero", "porcentaje"], p, j, nom;
  for (p = 0; p < pref.length; p++) {
    for (j = 0; j < cols.length; j++) {
      nom = String(cols[j].n || "").toLowerCase();
      if (cols[j].f === pref[p] && typeof fila[j] === "number" && nom.indexOf("c\\u00f3digo") < 0 && nom.indexOf("codigo") < 0) { return j; }
    }
  }
  for (j = 0; j < cols.length; j++) {
    nom = String(cols[j].n || "").toLowerCase();
    if (typeof fila[j] === "number" && !cols[j].f && nom.indexOf("codigo") < 0 && nom.indexOf("c\\u00f3digo") < 0) { return j; }
  }
  return -1;
}
function iaPintar(box, d, err, n) {
  var h = "", cols = d.cols || [], filas = d.filas || [], i, j, iLab = -1, iVal = -1, g = d.grafico;
  if (err || d.error) { box.innerHTML = '<div class="tx err">' + esc(err || d.error) + "</div>"; return; }
  if (d.titulo) { h += '<div class="tt">' + esc(d.titulo) + "</div>"; }
  if (d.texto) { h += '<div class="tx">' + esc(d.texto) + "</div>"; }
  for (j = 0; j < cols.length; j++) {
    if (iLab < 0 && filas.length && typeof filas[0][j] === "string" && cols[j].f !== "fecha" &&
        String(cols[j].n || "").toLowerCase().indexOf("digo") < 0) { iLab = j; }
  }
  if (filas.length) { iVal = iaColValor(cols, filas[0]); }
  if (cols.length === 1 && filas.length === 1) {
    h += '<div class="big num" style="margin-top:12px;color:#FFAF22">' + iaFmt(filas[0][0], cols[0].f) + "</div>";
  } else if (filas.length > 1 && iVal >= 0 && g && g !== "ninguno") {
    h += '<div class="graf" id="iaG' + n + '" style="margin-top:16px"></div>';
  }
  if (filas.length && !(cols.length === 1 && filas.length === 1)) {
    h += '<div class="ver-datos mut" onclick="var t=document.getElementById(\\'iaT' + n + '\\');t.style.display=t.style.display===\\'none\\'?\\'block\\':\\'none\\'">' +
         "Ver datos (" + filas.length + (filas.length === 1 ? " fila" : " filas") + ")</div>" +
         '<div id="iaT' + n + '" style="display:' + (filas.length <= 8 && (!g || g === "ninguno") ? "block" : "none") + ';margin-top:10px;max-height:340px;overflow:auto"></div>';
  }
  if (d.log) {
    h += '<div class="califica mut">\\u00bfTe sirvi\\u00f3?<a id="iaB' + n + '" onclick="iaCalif(' + n + "," + d.log + ',\\'B\\')">S\\u00ed</a><a id="iaM' + n + '" onclick="iaCalif(' + n + "," + d.log + ',\\'M\\')">No</a></div>';
  }
  box.innerHTML = h;
  if ($("iaT" + n)) {
    var tc = [];
    for (j = 0; j < cols.length; j++) {
      (function (jj) {
        var der = filas.length && typeof filas[0][jj] === "number";
        tc.push({ t: esc(cols[jj].n), k: jj, der: der, ell: !der, f: function (v) { return iaFmt(v, cols[jj].f); } });
      })(j);
    }
    tabla($("iaT" + n), tc, filas);
  }
  if ($("iaG" + n)) {
    var datos = [];
    for (i = 0; i < filas.length; i++) { datos.push({ n: iLab >= 0 ? String(filas[i][iLab]) : String(i + 1), v: num(filas[i][iVal]) }); }
    var fmtV = function (v) { return iaFmt(v, cols[iVal].f || "numero"); };
    if (g === "torta" && datos.length <= 10) { dona($("iaG" + n), datos, { fmt: fmtV, fmtCentro: function (v) { return cols[iVal].f === "moneda" ? fmtMC(v) : fmtC(v); }, centro: "total" }); }
    else if (g === "lineas") {
      var et = [], dv = [];
      for (i = 0; i < datos.length; i++) { et.push(String(datos[i].n).length > 10 ? String(datos[i].n).substr(0, 10) : datos[i].n); dv.push(datos[i].v); }
      lineas($("iaG" + n), { etiquetas: et, alto: 230, fmt: fmtV, fmtEje: cols[iVal].f === "moneda" ? fmtMC : fmtC, series: [{ nombre: cols[iVal].n, datos: dv, color: PAL[0], area: true }] });
    } else { barrasH($("iaG" + n), datos.slice(0, 15), { rank: true, unColor: true, fmt: fmtV }); }
  }
}
function iaCalif(n, log, c) {
  pedir("ia_calif", { log: log, calif: c });
  var b = $("iaB" + n), m = $("iaM" + n);
  if (b) { b.className = c === "B" ? "ok" : ""; }
  if (m) { m.className = c === "M" ? "ok" : ""; }
  iaHist = $("iaMsgs").innerHTML;
}

// =====================================================================
// Arranque
// =====================================================================
function iniciar() {
  armarNav();
  $("btnCerrar").innerHTML = icono("cerrar", 15) + "Cerrar";
  $("tOsc").innerHTML = icono("luna", 14) + "Oscuro";
  $("tCla").innerHTML = icono("sol", 14) + "Claro";
  $("tema").onclick = function () { aplicarTema(estado.tema === "oscuro" ? "claro" : "oscuro", true); };
  $("cont").innerHTML = "";
  cartelCarga(true, "Abriendo el tablero", 1);
  pedir("init", {}, function (d) {
    d = d || {};
    if (d.hoy) { estado.hoy = deIso(d.hoy); }
    estado.ia = !!d.ia;
    // ?tema=claro&sec=ventas: para abrir directo en una seccion (pruebas)
    var q = location.search, mt = /[?&]tema=(\\w+)/.exec(q), ms = /[?&]sec=(\\w+)/.exec(q);
    aplicarTema(mt ? mt[1] : (d.tema || "claro"), false);
    $("usu").innerHTML = "<b>" + esc(d.empresa || "") + '</b><span>Usuario: ' + esc(d.usuario || "") + "</span>";
    var mpe = /[?&]per=(\\w+)/.exec(q);
    if (mpe) { estado.per = mpe[1]; }
    calcPeriodo();
    ir(ms && $("nav-" + ms[1]) ? ms[1] : "resumen");
    var mp = /[?&]preguntar=([^&]+)/.exec(q);
    if (mp && estado.sec === "ia") { setTimeout(function () { iaPreguntar(decodeURIComponent(mp[1].replace(/\\+/g, " "))); }, 600); }
    var mb = /[?&]bajar=(\\d+)/.exec(q);
    if (mb) { setTimeout(function () { $("cont").scrollTop = parseInt(mb[1], 10); }, 2500); }
  });
  setTimeout(function () {
    if (!puente.vivo) { $("cont").innerHTML = '<div class="card vacio mut">Esta p\\u00e1gina se usa desde el sistema BCN (Tablero de control).</div>'; }
  }, 10000);
  var tRes = null;
  window.onresize = function () { clearTimeout(tRes); tRes = setTimeout(function () { if (estado.sec !== "ia") { redibujar(); } }, 250); };
}
iniciar();
</script>
</body>
</html>
   ENDTEXT
//HTML>>
RETURN cHtml
