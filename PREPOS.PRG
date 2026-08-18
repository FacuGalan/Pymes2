#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

************************************************************************************************
** Precios posdatados
** Cambios de precio pendientes que se aplican cuando el cliente decide
** (uso tipico: supermercados que necesitan reimprimir etiquetas de gondola)
************************************************************************************************
MEMVAR oApp
STATIC oQryBrw, oQry3, oWnd1, oBrw, oDlg, cVentana

PROCEDURE PrePos(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas, cVentana) > 0
   hHand := ASCAN(oApp:aVentanas, cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas, cVentana)

CrearTabla()
oQry3 := oApp:oServer:Query("SELECT codigo, nombre, tasa FROM ge_"+oApp:cId+"ivas ORDER BY codigo")

oQryBrw := oApp:oServer:Query("SELECT p.id, p.codigo, p.nombre, "+;
   "a.preciocos AS preciocos_act, p.preciocos AS preciocos_nue, "+;
   "a.precioven AS precioven_act, p.precioven AS precioven_nue, "+;
   "a.reventa  AS reventa_act,  p.reventa  AS reventa_nue, "+;
   "p.fecprev, p.fecalta, p.usuario, p.observa "+;
   "FROM ge_"+oApp:cId+"prepos p "+;
   "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codigo "+;
   "ORDER BY p.fecprev, p.nombre")

DEFINE WINDOW oWnd1 MDICHILD TITLE "Precios Posdatados - cambios pendientes de aplicar" ;
   OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50

   DEFINE BUTTONBAR oBar SIZE 60,60 OF oWnd1 2010
      DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
         TOOLTIP "Agregar articulo pendiente" ;
         ACTION (Formu(.t., 0), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Alta" TOP WHEN("A"$cPermisos)      
      DEFINE BUTTON RESOURCE "MODI" OF oBar ;
         TOOLTIP "Modificar pendiente" ;
         ACTION (Formu(.f., oQryBrw:id), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .AND. "M"$cPermisos)
      DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
         TOOLTIP "Eliminar pendiente" ;
         ACTION (Baja(), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .AND. "B"$cPermisos)
      DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
         TOOLTIP "Exportar a Excel" ;
         ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
         PROMPT "Exporta" TOP
      DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
         TOOLTIP "Imprimir Planilla" ;
         ACTION oBrw:Report("Precios Posdatados", .t., .f.) ;
         PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
      DEFINE BUTTON RESOURCE "CONFIRMA" OF oBar ;
         TOOLTIP "Aplicar los cambios pendientes a los articulos" ;
         ACTION (Aplicar(), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Aplicar" TOP WHEN(oQryBrw:RecCount()>0 .AND. "AB"$cPermisos)
      DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
         TOOLTIP "Carga masiva por filtro de articulos" ;
         ACTION (AltaMasiva(), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "C. Masiva" TOP WHEN("A"$cPermisos)
      DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
         TOOLTIP "Carga masiva por lista de proveedor" ;
         ACTION (AltaMasivaLis(), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Lista Prov." TOP WHEN("A"$cPermisos)
      DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
         TOOLTIP "Vaciar la tabla de precios posdatados" ;
         ACTION (Vaciar(), oQryBrw:Refresh(.f.), oBrw:Refresh()) ;
         PROMPT "Vaciar" TOP WHEN(oQryBrw:RecCount()>0 .AND. "B"$cPermisos)
      DEFINE BUTTON RESOURCE "SALE" OF oBar ;
         TOOLTIP "Cerrar Ventana" ;
         ACTION oWnd1:End() ;
         PROMPT "Cerrar" TOP

   oWnd1:bGotFocus := { || oDlg:SetFocus }
   oWnd1:bResized  := { || Incrusta(oWnd1, oDlg, .t.) }

   DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
      REDEFINE XBROWSE oBrw DATASOURCE oQryBrw ;
         COLUMNS "codigo","nombre","preciocos_act","preciocos_nue",;
                 "precioven_act","precioven_nue","reventa_act","reventa_nue",;
                 "fecprev","usuario","observa" ;
         HEADERS "Cod.","Articulo","Costo actual","Costo nuevo",;
                 "Venta actual","Venta nuevo","Reventa actual","Reventa nuevo",;
                 "Fecha prevista","Cambio","Observacion" ;
         SIZES 85,260,80,80,80,80,80,80,80,80,200 ;
         ID 111 OF oDlg AUTOSORT ;
         ON DBLCLICK IF("M"$cPermisos, (Formu(.f., oQryBrw:id), oQryBrw:Refresh(.f.), oBrw:Refresh()), nil)
      REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
      oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
      oBrw:bClrStd := { || If(oBrw:KeyNo() % 2 == 0, ;
                              { CLR_BLACK, RGB(193,221,255) }, ;
                              { CLR_BLACK, RGB(221,245,255) } ) }
      PintaBrw(oBrw, 11)
   ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
ACTIVATE WINDOW oWnd1 ON INIT Incrusta(oWnd1, oDlg, .t.) VALID(cerrar())
RETURN


***********************************************************************************
** Crea la tabla prepos si no existe (idempotente, se ejecuta al entrar al modulo)
STATIC FUNCTION CrearTabla()
LOCAL cSql
cSql := "CREATE TABLE IF NOT EXISTS ge_"+oApp:cId+"prepos ("+;
   "id INT(8) NOT NULL AUTO_INCREMENT, "+;
   "codigo BIGINT(14) NOT NULL, "+;
   "nombre VARCHAR(150) NOT NULL DEFAULT '', "+;
   "siniva TINYINT(1) DEFAULT 0, "+;
   "iva INT(2) DEFAULT 0, "+;
   "precossiva DECIMAL(12,2) DEFAULT 0, "+;
   "desc1 DECIMAL(5,2) DEFAULT 0, "+;
   "desc2 DECIMAL(5,2) DEFAULT 0, "+;
   "desc3 DECIMAL(5,2) DEFAULT 0, "+;
   "desc4 DECIMAL(5,2) DEFAULT 0, "+;
   "desc5 DECIMAL(5,2) DEFAULT 0, "+;
   "impint DECIMAL(7,2) DEFAULT 0, "+;
   "flete DECIMAL(5,2) DEFAULT 0, "+;
   "preciocos DECIMAL(12,2) DEFAULT 0, "+;
   "porcentaje DECIMAL(10,2) DEFAULT 0, "+;
   "precioven DECIMAL(12,2) DEFAULT 0, "+;
   "porcentajerev DECIMAL(10,2) DEFAULT 0, "+;
   "reventa DECIMAL(12,2) DEFAULT 0, "+;
   "fecprev DATE, "+;
   "fecalta DATE, "+;
   "horalta TIME, "+;
   "usuario VARCHAR(15) DEFAULT '', "+;
   "ip VARCHAR(20) DEFAULT '', "+;
   "observa VARCHAR(255) DEFAULT '', "+;
   "PRIMARY KEY (id), "+;
   "UNIQUE KEY codigo_unq (codigo)) ENGINE=INNODB DEFAULT CHARSET=utf8"
oApp:oServer:Execute(cSql)
oApp:oServer:NextResult()
RETURN .t.


***********************************************************************************
** Selector de articulo (para Alta): devuelve el codigo seleccionado o 0
STATIC FUNCTION SeleccionarArticulo()
LOCAL oDlgS, oBot1, oBot2, oGet1, mrta := .f., nCodNue := 0, oQryArt
oQryArt := oApp:oServer:Query("SELECT codigo,nombre,precioven FROM ge_"+oApp:cId+"articu")
DEFINE DIALOG oDlgS TITLE "Seleccionar Articulo (codigo o codigo de barras)" FROM 03,15 TO 10,75
   oDlgS:lHelpIcon := .f.
   @ 07,05 SAY "Codigo:" OF oDlgS SIZE 50,12 PIXEL RIGHT
   @ 05,60 GET oGet1 VAR nCodNue OF oDlgS PIXEL PICTURE "99999999999999" RIGHT;
    VALID(BuscarArt(oQryArt,oDlgS,oGet1));
    ACTION (oGet1:cText:= 0, BuscarArt(oQryArt,oDlgs,oGet1)) BITMAP "BUSC1"
   @ 25,40 BUTTON oBot1 PROMPT "&Aceptar"  OF oDlgS SIZE 40,12 ACTION ((mrta := .t.), oDlgS:End()) PIXEL
   @ 25,90 BUTTON oBot2 PROMPT "&Cancelar" OF oDlgS SIZE 40,12 ACTION ((mrta := .f.), oDlgS:End()) PIXEL CANCEL
ACTIVATE DIALOG oDlgS CENTER ON INIT oGet1:SetFocus()
IF !mrta 
   RETURN 0
ENDIF   
RETURN nCodNue


***********************************************************************************
** Alta / Modificacion de un cambio pendiente
STATIC FUNCTION Formu(lAlta, nId)
LOCAL oForm, oGet := ARRAY(25), oBot := ARRAY(2), lRta := .f., aCor, base, oQry, oError,;
      nNeto := 0, cIvaNom := SPACE(30), cArtNom := SPACE(150), nCodArt, oQryArt
LOCAL nPrecCosAnt := 0, nPrecVenAnt := 0, nRevAnt := 0

IF lAlta
   nCodArt := SeleccionarArticulo()
   IF nCodArt = 0
      RETURN nil
   ENDIF
   IF oApp:oServer:Query("SELECT id FROM ge_"+oApp:cId+"prepos WHERE codigo = "+ClipValue2Sql(nCodArt)):RecCount() > 0
      MsgStop("Este articulo ya tiene un cambio pendiente."+CHR(10)+;
              "Modifiquelo desde el boton 'Modifica' o borrelo primero.","Atencion")
      RETURN nil
   ENDIF
   oQryArt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(nCodArt))
   IF oQryArt:RecCount() = 0
      MsgStop("Articulo no encontrado.","Error")
      RETURN nil
   ENDIF
   oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"prepos LIMIT 0")
   base := oQry:GetBlankRow()
   base:codigo        := oQryArt:codigo
   base:nombre        := oQryArt:nombre
   base:siniva        := oQryArt:siniva
   base:iva           := oQryArt:iva
   base:precossiva    := oQryArt:precossiva
   base:desc1         := oQryArt:desc1
   base:desc2         := oQryArt:desc2
   base:desc3         := oQryArt:desc3
   base:desc4         := oQryArt:desc4
   base:desc5         := oQryArt:desc5
   base:impint        := oQryArt:impint
   base:flete         := oQryArt:flete
   base:preciocos     := oQryArt:preciocos
   base:porcentaje    := oQryArt:porcentaje
   base:precioven     := oQryArt:precioven
   base:porcentajerev := oQryArt:porcentajerev
   base:reventa       := oQryArt:reventa
   base:fecprev       := DATE()
   base:observa       := SPACE(255)
   nPrecCosAnt := oQryArt:preciocos
   nPrecVenAnt := oQryArt:precioven
   nRevAnt     := oQryArt:reventa
ELSE
   IF nId = 0
      RETURN nil
   ENDIF
   oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"prepos WHERE id = "+ClipValue2Sql(nId))
   IF oQry:RecCount() = 0
      RETURN nil
   ENDIF
   base := oQry:GetRowObj()
   oQry:lAppend := .f.
   base:observa := IF(EMPTY(base:observa), SPACE(255), ALLTRIM(base:observa) + SPACE(255-LEN(ALLTRIM(base:observa))))
   oQryArt := oApp:oServer:Query("SELECT preciocos, precioven, reventa FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codigo))
   IF oQryArt:RecCount() > 0
      nPrecCosAnt := oQryArt:preciocos
      nPrecVenAnt := oQryArt:precioven
      nRevAnt     := oQryArt:reventa
   ENDIF
ENDIF

cArtNom := base:nombre
oQry3:GoTop()
IF oQry3:Seek(base:iva, 1) > 0
   cIvaNom := STR(oQry3:tasa, 6, 2) + "%"
ENDIF

DO WHILE .t.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Precio Posdatado" ;
       FROM 02,10 TO 25,115 OF oWnd1 FONT oApp:oFont
   oForm:lHelpIcon := .f.

   // Cabecera: articulo
   @ 07, 05 SAY "Articulo:"                OF oForm PIXEL SIZE 60,10
   @ 05, 70 GET oGet[1]  VAR base:codigo   OF oForm PIXEL PICTURE "99999999999999"  WHEN(.f.) RIGHT
   @ 05,140 GET oGet[2]  VAR cArtNom       OF oForm PIXEL SIZE 200,10 WHEN(.f.)

   // Precios actuales (informativos)
   @ 22, 05 SAY "Pr. costo actual:"        OF oForm PIXEL SIZE 45,10
   @ 20, 70 GET oGet[3]  VAR nPrecCosAnt   OF oForm PIXEL PICTURE "999999999.99" COLOR CLR_BLACK, RGB(220,220,220) WHEN(.f.)  RIGHT
   @ 22,120 SAY "Venta actual:"            OF oForm PIXEL SIZE 45,10
   @ 20,170 GET oGet[4]  VAR nPrecVenAnt   OF oForm PIXEL PICTURE "999999999.99" COLOR CLR_BLACK, RGB(220,220,220) WHEN(.f.)  RIGHT
   @ 22,220 SAY "Reventa actual:"          OF oForm PIXEL SIZE 45,10
   @ 20,260 GET oGet[5]  VAR nRevAnt       OF oForm PIXEL PICTURE "999999999.99" COLOR CLR_BLACK, RGB(220,220,220) WHEN(.f.)  RIGHT

   // Costo s/IVA + descuentos
   @ 42, 05 SAY "Costo s/IVA:"             OF oForm PIXEL SIZE 60,10
   @ 40, 70 GET oGet[6]  VAR base:precossiva OF oForm PIXEL PICTURE "999999999.99"  RIGHT
   @ 42,120 SAY "Dto1:" OF oForm PIXEL SIZE 20,10
   @ 40,145 GET oGet[7]  VAR base:desc1    OF oForm PIXEL PICTURE "999.99" RIGHT
   @ 42,175 SAY "Dto2:" OF oForm PIXEL SIZE 20,10
   @ 40,195 GET oGet[8]  VAR base:desc2    OF oForm PIXEL PICTURE "999.99" RIGHT
   @ 42,235 SAY "Dto3:" OF oForm PIXEL SIZE 20,10
   @ 40,265 GET oGet[9]  VAR base:desc3    OF oForm PIXEL PICTURE "999.99" RIGHT
   @ 42,295 SAY "Dto4:" OF oForm PIXEL SIZE 20,10
   @ 40,325 GET oGet[10] VAR base:desc4    OF oForm PIXEL PICTURE "999.99" RIGHT
   @ 42,365 SAY "Dto5:" OF oForm PIXEL SIZE 20,10
   @ 40,385 GET oGet[11] VAR base:desc5    OF oForm PIXEL PICTURE "999.99" RIGHT

   // Neto + impuestos
   @ 60, 05 SAY "Neto:"                    OF oForm PIXEL SIZE 60,10
   @ 58, 70 GET oGet[12] VAR nNeto         OF oForm PIXEL PICTURE "999999999.99" RIGHT;
            WHEN(CalcularNetoP(base, oGet))
   @ 60,125 SAY "Imp.Int.:" OF oForm PIXEL SIZE 30,10
   @ 58,150 GET oGet[13] VAR base:impint   OF oForm PIXEL PICTURE "99999.99" RIGHT
   @ 60,195 SAY "Flete %:" OF oForm PIXEL SIZE 25,10
   @ 58,225 GET oGet[14] VAR base:flete    OF oForm PIXEL PICTURE "99999.9" RIGHT
   @ 60,265 SAY "IVA:" OF oForm PIXEL SIZE 20,10
   @ 58,285 GET oGet[15] VAR base:iva      OF oForm PIXEL PICTURE "99" RIGHT SIZE 25,10;
            VALID(buscar(oQry3, oForm, oGet[15], nil) .AND. ;
                  (oGet[16]:cText := STR(oQry3:tasa,6,2)+"%") <> "xxx") ;
            ACTION (oGet[15]:cText := 0, buscar(oQry3, oForm, oGet[15], nil), ;
                    oGet[16]:cText := STR(oQry3:tasa,6,2)+"%") BITMAP "BUSC1"
   @ 58,325 GET oGet[16] VAR cIvaNom       OF oForm PIXEL WHEN(.f.) SIZE 30,10

   // Precio costo (calculado)
   @ 78, 05 SAY "Precio costo (final):"    OF oForm PIXEL SIZE 60,10
   @ 76, 70 GET oGet[17] VAR base:preciocos OF oForm PIXEL PICTURE "999999999.99"  RIGHT;
            WHEN((oGet[17]:cText := nNeto + base:impint + nNeto * (base:flete/100) + ((nNeto * oQry3:tasa)/100)) = "-999999")

   // Utilidad + precio venta
   @ 96, 05 SAY "% utilidad:"              OF oForm PIXEL SIZE 60,10
   @ 94, 70 GET oGet[18] VAR base:porcentaje    OF oForm PIXEL PICTURE "999.99" RIGHT;
            VALID(CalcularPrecioP(oGet, base, .t.))
   @ 96,105 SAY "Precio venta:"            OF oForm PIXEL SIZE 40,10
   @ 94,145 GET oGet[19] VAR base:precioven     OF oForm PIXEL PICTURE "999999999.99" RIGHT
   @ 96,205 SAY "% util.rev:"              OF oForm PIXEL SIZE 40,10
   @ 94,245 GET oGet[20] VAR base:porcentajerev OF oForm PIXEL PICTURE "999.99" RIGHT;
            VALID(CalcularPrecioP(oGet, base, .f.))
   @ 96,275 SAY "Reventa:"                 OF oForm PIXEL SIZE 40,10
   @ 94,315 GET oGet[21] VAR base:reventa       OF oForm PIXEL PICTURE "999999999.99" RIGHT

   // Fecha prevista + observacion
   @ 116, 05 SAY "Fecha prevista:"         OF oForm PIXEL SIZE 60,10
   @ 114, 70 GET oGet[22] VAR base:fecprev OF oForm PIXEL RIGHT
   @ 116,145 SAY "Observacion:"            OF oForm PIXEL SIZE 60,10
   @ 114,205 GET oGet[23] VAR base:observa OF oForm PIXEL PICTURE "@S30"

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar"  OF oForm SIZE 40,12 ;
           ACTION ((lRta := .t.), oForm:End()) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 40,12 ;
           ACTION ((lRta := .f.), oForm:End()) PIXEL CANCEL

ACTIVATE DIALOG oForm CENTER ON INIT oGet[6]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:preciocos = 0 .OR. base:iva = 0
   MsgInfo("Los campos 'Precio costo' e 'IVA' son obligatorios","Atencion!")
   LOOP
ENDIF
IF base:iva <> 3 .AND. base:iva <> 4 .AND. base:iva <> 5
   MsgStop("Tasa de IVA no valida para facturacion","Error")
   LOOP
ENDIF
IF EMPTY(base:fecprev)
   base:fecprev := DATE()
ENDIF
base:fecalta := oApp:oServer:Query("SELECT CURDATE() AS fecha"):fecha
base:horalta := oApp:oServer:Query("SELECT CURTIME() AS hora"):hora
base:usuario := oApp:usuario
base:ip      := oApp:cIp
base:nombre  := STRTRAN(base:nombre, "'", "`")

oQry:oRow := base
TRY
   oApp:oServer:BeginTransaction()
   oQry:Save()
   oApp:oServer:CommitTransaction()
CATCH oError
   ValidaError(oError)
   LOOP
END TRY
EXIT
ENDDO
RETURN nil


***********************************************************************************
** Calcula el neto del articulo a partir de costo s/IVA y descuentos en cascada
STATIC FUNCTION CalcularNetoP(base, oGet)
LOCAL nTotalNeto
nTotalNeto := IF(base:siniva, base:precossiva, base:precossiva / (1 + oQry3:tasa/100))
nTotalNeto := nTotalNeto - nTotalNeto * (base:desc1/100)
nTotalNeto := nTotalNeto - nTotalNeto * (base:desc2/100)
nTotalNeto := nTotalNeto - nTotalNeto * (base:desc3/100)
nTotalNeto := nTotalNeto - nTotalNeto * (base:desc4/100)
nTotalNeto := nTotalNeto - nTotalNeto * (base:desc5/100)
oGet[12]:cText := nTotalNeto
RETURN .f.


***********************************************************************************
** Calcula precio venta (lventa=.t.) o reventa (lventa=.f.) desde la utilidad
STATIC FUNCTION CalcularPrecioP(oGet, base, lventa)
IF lventa
   oGet[19]:cText := base:preciocos + (base:preciocos * base:porcentaje)/100
ELSE
   oGet[21]:cText := base:preciocos + (base:preciocos * base:porcentajerev)/100
ENDIF
RETURN .t.


***********************************************************************************
** Baja de un cambio pendiente (no toca articu)
STATIC FUNCTION Baja()
LOCAL mrta := .f., oError, nId := oQryBrw:id, cNom := ALLTRIM(oQryBrw:nombre)
IF nId = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar el cambio pendiente"+CHR(10)+;
                 "para el articulo: "+cNom+"?", "Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"prepos WHERE id = "+ClipValue2Sql(nId))
   oApp:oServer:CommitTransaction()
   oQryBrw:Refresh(.f.)
CATCH oError
   ValidaError(oError)
END TRY
RETURN nil

***********************************************************************************
** Vaciar
STATIC FUNCTION Vaciar()
LOCAL mrta := .f., oError, nId := oQryBrw:id, cNom := ALLTRIM(oQryBrw:nombre)
mrta := MsgNoYes("Seguro de VACIAR TODOS los cambios pendientes?", "Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("TRUNCATE ge_"+oApp:cId+"prepos")
   oApp:oServer:CommitTransaction()
   oQryBrw:Refresh(.f.)
CATCH oError
   ValidaError(oError)
END TRY
RETURN nil


***********************************************************************************
** Aplicar todos los pendientes: actualiza articu, inserta en campre, propaga grupos
** Toda la operacion va en una sola transaccion (rollback total si algo falla)
STATIC FUNCTION Aplicar()
LOCAL oQryPen, oError, nTotal := 0, nGrupo
oQryPen := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"prepos ORDER BY codigo")
nTotal := oQryPen:RecCount()
IF nTotal = 0
   MsgInfo("No hay cambios pendientes para aplicar","Atencion")
   RETURN nil
ENDIF
IF !MsgNoYes("Se aplicaran "+LTRIM(STR(nTotal))+" cambios de precio."+CHR(10)+;
             "Esta operacion modifica los precios de los articulos."+CHR(10)+CHR(10)+;
             "Confirma?", "Aplicar cambios posdatados")
   RETURN nil
ENDIF

TRY
   oApp:oServer:BeginTransaction()
   oQryPen:GoTop()
   DO WHILE !oQryPen:Eof()
      // 1) Actualizar el articulo con los nuevos valores
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET "+;
         "siniva        = "+ClipValue2Sql(oQryPen:siniva)+", "+;
         "iva           = "+ClipValue2Sql(oQryPen:iva)+", "+;
         "precossiva    = "+ClipValue2Sql(oQryPen:precossiva)+", "+;
         "desc1         = "+ClipValue2Sql(oQryPen:desc1)+", "+;
         "desc2         = "+ClipValue2Sql(oQryPen:desc2)+", "+;
         "desc3         = "+ClipValue2Sql(oQryPen:desc3)+", "+;
         "desc4         = "+ClipValue2Sql(oQryPen:desc4)+", "+;
         "desc5         = "+ClipValue2Sql(oQryPen:desc5)+", "+;
         "impint        = "+ClipValue2Sql(oQryPen:impint)+", "+;
         "flete         = "+ClipValue2Sql(oQryPen:flete)+", "+;
         "preciocos     = "+ClipValue2Sql(oQryPen:preciocos)+", "+;
         "porcentaje    = "+ClipValue2Sql(oQryPen:porcentaje)+", "+;
         "precioven     = "+ClipValue2Sql(oQryPen:precioven)+", "+;
         "porcentajerev = "+ClipValue2Sql(oQryPen:porcentajerev)+", "+;
         "reventa       = "+ClipValue2Sql(oQryPen:reventa)+", "+;
         "fecmod        = CURDATE(), "+;
         "horamod       = CURTIME(), "+;
         "usuario       = "+ClipValue2Sql(oApp:usuario)+", "+;
         "ip            = "+ClipValue2Sql(oApp:cIp)+" "+;
         "WHERE codigo  = "+ClipValue2Sql(oQryPen:codigo))

      // 2) Registrar en el historial campre (motivo 'Posdatado' en el campo ip)
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre "+;
         "(codigo, preciocos, precossiva, precioven, reventa, fecmod, usuario, ip) "+;
         "VALUES ("+ClipValue2Sql(oQryPen:codigo)+", "+;
         ClipValue2Sql(oQryPen:preciocos)+", "+;
         ClipValue2Sql(oQryPen:precossiva)+", "+;
         ClipValue2Sql(oQryPen:precioven)+", "+;
         ClipValue2Sql(oQryPen:reventa)+", CURDATE(), "+;
         ClipValue2Sql(oApp:usuario)+", 'Posdatado')")

      // 3) Si el articulo pertenece a un grupo de precios, propagar a todos
      nGrupo := oApp:oServer:Query("SELECT codgru FROM ge_"+oApp:cId+"gruposdet "+;
                                   "WHERE codart = "+ClipValue2Sql(oQryPen:codigo)):codgru
      IF nGrupo <> 0
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"gruposdet g "+;
            "LEFT JOIN ge_"+oApp:cId+"articu a ON g.codart = a.codigo "+;
            "AND g.codgru = "+ClipValue2Sql(nGrupo)+" "+;
            "SET a.siniva        = "+ClipValue2Sql(oQryPen:siniva)+", "+;
            "    a.iva           = "+ClipValue2Sql(oQryPen:iva)+", "+;
            "    a.precossiva    = "+ClipValue2Sql(oQryPen:precossiva)+", "+;
            "    a.desc1         = "+ClipValue2Sql(oQryPen:desc1)+", "+;
            "    a.desc2         = "+ClipValue2Sql(oQryPen:desc2)+", "+;
            "    a.desc3         = "+ClipValue2Sql(oQryPen:desc3)+", "+;
            "    a.desc4         = "+ClipValue2Sql(oQryPen:desc4)+", "+;
            "    a.desc5         = "+ClipValue2Sql(oQryPen:desc5)+", "+;
            "    a.impint        = "+ClipValue2Sql(oQryPen:impint)+", "+;
            "    a.flete         = "+ClipValue2Sql(oQryPen:flete)+", "+;
            "    a.preciocos     = "+ClipValue2Sql(oQryPen:preciocos)+", "+;
            "    a.porcentaje    = "+ClipValue2Sql(oQryPen:porcentaje)+", "+;
            "    a.precioven     = "+ClipValue2Sql(oQryPen:precioven)+", "+;
            "    a.porcentajerev = "+ClipValue2Sql(oQryPen:porcentajerev)+", "+;
            "    a.reventa       = "+ClipValue2Sql(oQryPen:reventa)+", "+;
            "    a.fecmod        = CURDATE(), "+;
            "    a.horamod       = CURTIME() ")
      ENDIF

      oQryPen:Skip()
   ENDDO

   // 4) Vaciar la tabla de pendientes (DELETE en vez de TRUNCATE: TRUNCATE
   //    causa commit implicito en MySQL y romperia la transaccion)
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"prepos")

   oApp:oServer:CommitTransaction()
   MsgInfo(LTRIM(STR(nTotal))+" articulos actualizados con exito","Aplicacion exitosa")
CATCH oError
   oApp:oServer:RollBack()
   MsgStop("Error al aplicar los cambios. Ningun precio fue modificado."+CHR(10)+CHR(10)+;
           oError:description, "Error")
END TRY
oQryPen:End()
RETURN nil


***********************************************************************************
** Cerrar el modulo (libera queries y saca de aVentanas)
STATIC FUNCTION cerrar()
LOCAL aNueva := {}, i, j
oQryBrw:End()
RELEASE oQryBrw
oQry3:End()
RELEASE oQry3

j := ASCAN(oApp:aVentanas, cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva, oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.


***********************************************************************************
** Carga masiva de Precios Posdatados - Por filtro de articulos
** Reusa la misma logica de calculo que PREGEN (porcentaje/importe/utilidad/redondeo)
** pero el destino es la tabla prepos en vez de articu.
STATIC FUNCTION AltaMasiva()
LOCAL oForm, oForm2, oGet := ARRAY(15), oBot := ARRAY(5), oBrw2, oQryTemp, acor
LOCAL nPorc := 0, nImpo := 0, nPorcUn := 0, nPorcUnR := 0
LOCAL lVenta := .t., lSumaUtilidad := .f., nRedondeo := 2
LOCAL dFecPrev := DATE(), cObserva := SPACE(255)
LOCAL aRedondeo := {"Sin Redondear","Entero","Multiplo de 10","Multiplo de 50","Multiplo de 100"}
LOCAL cWhere := "", lFiltrado := .f., lConf := .f., lVolver := .f., nTotal := 0

CrearTempArt()

DO WHILE .t.
   lFiltrado := .f.
   lConf     := .f.
   lVolver   := .f.

   // ----- Dialog 1: parametros + filtro -----
   DEFINE DIALOG oForm TITLE "Carga masiva de Precios Posdatados - Por filtro" ;
          FROM 02,10 TO 22,115 OF oWnd1 FONT oApp:oFont
      oForm:lHelpIcon := .f.

      @ 10, 05 SAY "% Porcentaje:"  OF oForm PIXEL SIZE 60,10
      @ 08, 70 GET oGet[1] VAR nPorc    OF oForm PIXEL PICTURE "999.99"     RIGHT ;
               WHEN(nImpo=0 .and. nPorcUn=0 .and. nPorcUnR=0)
      @ 10,140 SAY "Importe Fijo:"  OF oForm PIXEL SIZE 50,10
      @ 08,200 GET oGet[2] VAR nImpo    OF oForm PIXEL PICTURE "999999.999" RIGHT ;
               WHEN(nPorc=0 .and. nPorcUn=0 .and. nPorcUnR=0)

      @ 25, 05 SAY "% Utilidad:"    OF oForm PIXEL SIZE 60,10
      @ 23, 70 GET oGet[3] VAR nPorcUn  OF oForm PIXEL PICTURE "999.99" RIGHT ;
               WHEN(nImpo=0 .and. nPorc=0)
      @ 25,140 SAY "% Util.Rev:"    OF oForm PIXEL SIZE 50,10
      @ 23,200 GET oGet[4] VAR nPorcUnR OF oForm PIXEL PICTURE "999.99" RIGHT ;
               WHEN(nImpo=0 .and. nPorc=0)

      @ 43, 70 CHECKBOX oGet[5] VAR lVenta OF oForm PIXEL ;
               PROMPT "Aplicar incremento solo a precios de venta" SIZE 200,10
      @ 56, 70 CHECKBOX oGet[6] VAR lSumaUtilidad OF oForm PIXEL ;
               PROMPT "Sumar utilidad a la existente" SIZE 200,10 ;
               WHEN(nPorcUn>0 .or. nPorcUnR>0)

      @ 73, 05 SAY "Redondeo:"      OF oForm PIXEL SIZE 60,10
      @ 71, 70 COMBOBOX oGet[7] VAR nRedondeo ITEMS aRedondeo OF oForm PIXEL SIZE 100,80

      @ 90, 05 SAY "Fecha prevista:" OF oForm PIXEL SIZE 60,10
      @ 88, 70 GET oGet[8] VAR dFecPrev OF oForm PIXEL RIGHT

      @ 105, 05 SAY "Observacion:"   OF oForm PIXEL SIZE 60,10
      @ 103, 70 GET oGet[9] VAR cObserva OF oForm PIXEL PICTURE "@S30" SIZE 250,10

      @ 125, 5   BUTTON oBot[1] PROMPT "&Filtrar y previsualizar" OF oForm SIZE 100,12 ;
               ACTION (cWhere := FiltrarPos(oForm), ;
                       IF(LEN(cWhere)>0, ;
                          (CalcularTemp(nPorc,nImpo,nPorcUn,nPorcUnR,lVenta,lSumaUtilidad,nRedondeo,cWhere), ;
                           lFiltrado := .t., ;
                           oForm:End()), nil)) PIXEL ;
               WHEN((nPorc+nImpo+nPorcUn+nPorcUnR>0) .or. nPorc<0)
      @ 125, 115 BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 60,12 ;
               ACTION (lFiltrado := .f., oForm:End()) PIXEL CANCEL
   ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

   IF !lFiltrado
      EXIT
   ENDIF

   nTotal := oApp:oServer:Query("SELECT COUNT(*) AS n FROM articu_temp"):n
   IF nTotal = 0
      MsgInfo("El filtro no devolvio articulos.","Atencion")
      LOOP
   ENDIF

   // ----- Dialog 2: preview -----
   oQryTemp := oApp:oServer:Query("SELECT * FROM articu_temp")
   DEFINE DIALOG oForm2 TITLE "Previsualizacion - "+LTRIM(STR(nTotal))+" articulos a posdatar" ;
          FROM 02,01 TO 40,140 OF oWnd1 FONT oApp:oFont
      oForm2:lHelpIcon := .f.

      @ 05, 02 XBROWSE oBrw2 DATASOURCE oQryTemp ;
               COLUMNS "codigo","nombre","preciocos","incru","precioven","incruR","reventa",;
                       "preciocos1","costofin","incru1","precioven1","incruR1","reventa1" ;
               HEADERS "Codigo","Articulo","Costo","Util.","Venta","Util.Rev","Reventa",;
                       "Nuevo Costo","Costo Final","Util.Nueva","Venta Nueva","Util.Rev.N.","Reventa Nueva" ;
               SIZES 50,200,70,50,70,50,70,70,80,55,70,55,70 ;
               OF oForm2 SIZE 600,210 AUTOSORT PIXEL
      oBrw2:CreateFromCode()
      oBrw2:nFreeze := 2
      PintaBrw(oBrw2, 0)

      @ 220, 5   SAY "Fecha prevista: "+DTOC(dFecPrev) OF oForm2 PIXEL SIZE 150,10
      @ 220, 160 SAY "Observacion: "+ALLTRIM(cObserva) OF oForm2 PIXEL SIZE 400,10

      @ 235, 5   BUTTON oBot[3] PROMPT "&Confirmar" OF oForm2 SIZE 70,12 ;
                 ACTION (lConf := .t., oForm2:End()) PIXEL
      @ 235, 80  BUTTON oBot[4] PROMPT "&Volver"    OF oForm2 SIZE 70,12 ;
                 ACTION (lVolver := .t., oForm2:End()) PIXEL
      @ 235, 155 BUTTON oBot[5] PROMPT "Ca&ncelar"  OF oForm2 SIZE 70,12 ;
                 ACTION (lConf := .f., lVolver := .f., oForm2:End()) PIXEL CANCEL
   ACTIVATE DIALOG oForm2 CENTER

   oQryTemp:End()

   IF lVolver
      LOOP
   ENDIF
   IF !lConf
      EXIT
   ENDIF

   // ----- INSERT INTO prepos -----
   IF GrabarPosFiltro(dFecPrev, cObserva)
      MsgInfo("Cambios posdatados grabados con exito.","Proceso exitoso")
      EXIT
   ENDIF
   LOOP
ENDDO

oApp:oServer:Execute("DROP TABLE IF EXISTS articu_temp")
oApp:oServer:NextResult()
RETURN nil


***********************************************************************************
** Crea tabla temporal articu_temp con la misma estructura que usa PREGEN
STATIC FUNCTION CrearTempArt()
oApp:oServer:Execute("DROP TABLE IF EXISTS articu_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("CREATE TEMPORARY TABLE articu_temp ("+;
   "codigo     BIGINT(14) NOT NULL,"+;
   "nombre     VARCHAR(150) NOT NULL,"+;
   "preciocos  DECIMAL(12,2) DEFAULT '0',"+;
   "preciocos1 DECIMAL(12,2) DEFAULT '0',"+;
   "uxb        DECIMAL(10,2) DEFAULT '0',"+;
   "pxb        DECIMAL(12,2) DEFAULT '0',"+;
   "costofin   DECIMAL(12,2) DEFAULT '0',"+;
   "incru      DECIMAL(12,2) DEFAULT '0',"+;
   "incru1     DECIMAL(12,2) DEFAULT '0',"+;
   "precioven  DECIMAL(12,2) DEFAULT '0',"+;
   "precioven1 DECIMAL(12,2) DEFAULT '0',"+;
   "incruR     DECIMAL(12,2) DEFAULT '0',"+;
   "incruR1    DECIMAL(12,2) DEFAULT '0',"+;
   "reventa    DECIMAL(12,2) DEFAULT '0',"+;
   "reventa1   DECIMAL(12,2) DEFAULT '0'"+;
   ") ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
RETURN .t.


***********************************************************************************
** Pobla articu_temp con las formulas de PREGEN segun los parametros elegidos
STATIC FUNCTION CalcularTemp(nPorc, nImpo, nPorcUn, nPorcUnR, lVenta, lSumaUtilidad, nRedondeo, cWhere)
LOCAL cCostoDesc, cCostoFlete, cCostoFin, cIncrCostoF, cIncrCostoB, cPorUti1, cPorUti2

cCostoDesc := "IF(a.siniva,a.precossiva,100*a.precossiva/(100+(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)))"

cCostoFlete := "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100)) ) "
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc2/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc3/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc4/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc5/100)) )"

cCostoFin := "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100))) "
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc2/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc3/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc4/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc5/100)))"
cCostoFin := "("+cCostoFin+" + (("+cCostoFin+"*(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)/100)) + "+;
             " impint + ("+cCostoFlete+"*flete/100) ) "

cIncrCostoF := "("+cCostoFin+" + "+IF(lVenta,"0",ClipValue2SQL(nImpo))+" + "+cCostoFin+" * ("+ClipValue2SQL(nPorc/100)+"))"
cIncrCostoB := "(a.precossiva + "+IF(lVenta,"0",ClipValue2SQL(nImpo))+" + a.precossiva * ("+ClipValue2SQL(nPorc/100)+"))"

oApp:oServer:Execute("TRUNCATE articu_temp")
oApp:oServer:NextResult()

IF ((nPorc + nImpo + nPorcUn) = 0) .or. (nPorcUn > 0)
   IF lSumaUtilidad
      cPorUti1 := "(a.porcentaje + "+STR(nPorcUn)+")"
      cPorUti2 := "(a.porcentajerev + "+STR(nPorcUnR)+")"
   ELSE
      IF nPorcUn > 0
         cPorUti1 := "("+STR(nPorcUn)+")"
      ELSE
         cPorUti1 := "(a.porcentaje)"
      ENDIF
      IF nPorcUnR > 0
         cPorUti2 := "("+STR(nPorcUnR)+")"
      ELSE
         cPorUti2 := "(a.porcentajerev)"
      ENDIF
   ENDIF
   oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru, precioven, incruR, reventa, "+;
                        "preciocos1, costofin, incru1, precioven1, incruR1, reventa1, uxb, pxb) "+;
                        "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje, a.precioven, a.porcentajerev, a.reventa, "+;
                        "a.precossiva, "+cCostoFin+", "+;
                        cPorUti1+", "+cCostoFin+"+("+cCostoFin+"*"+cPorUti1+"/100), "+;
                        cPorUti2+", "+cCostoFin+"+("+cCostoFin+"*"+cPorUti2+"/100), "+;
                        "a.uxbulto, a.pxbulto "+;
                        "FROM ge_"+oApp:cId+"articu a WHERE "+cWhere+")")
ENDIF

IF (nPorc + nImpo) <> 0
   IF lVenta
      oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru, precioven, incruR, reventa, "+;
                           "preciocos1, costofin, incru1, precioven1, incruR1, reventa1, uxb, pxb) "+;
                           "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje, a.precioven, a.porcentajerev, a.reventa, "+;
                           "a.precossiva, "+cCostoFin+", "+;
                           "((a.precioven+(a.precioven*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+")*100)/"+cCostoFin+" -100, "+;
                           "a.precioven+(a.precioven*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+", "+;
                           "((a.reventa+(a.reventa*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+")*100)/"+cCostoFin+" -100, "+;
                           "a.reventa+(a.reventa*"+ClipValue2SQL(nPorc)+"/100)+"+ClipValue2SQL(nImpo)+", "+;
                           "a.uxbulto, a.pxbulto "+;
                           "FROM ge_"+oApp:cId+"articu a WHERE "+cWhere+")")
   ELSE
      oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru, precioven, incruR, reventa, "+;
                           "preciocos1, costofin, incru1, precioven1, incruR1, reventa1, uxb, pxb) "+;
                           "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje, a.precioven, a.porcentajerev, a.reventa, "+;
                           cIncrCostoB+", "+cIncrCostoF+", "+;
                           "a.porcentaje, "+cIncrCostoF+"+"+cIncrCostoF+"*(a.porcentaje/100), "+;
                           "a.porcentajerev, "+cIncrCostoF+"+"+cIncrCostoF+"*(a.porcentajerev/100), "+;
                           "a.uxbulto, a.pxbulto "+;
                           "FROM ge_"+oApp:cId+"articu a WHERE "+cWhere+")")
   ENDIF
ENDIF

DO CASE
   CASE nRedondeo = 1
   CASE nRedondeo = 2
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1), reventa1 = ROUND(reventa1)")
   CASE nRedondeo = 3
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1,-1), reventa1 = ROUND(reventa1,-1)")
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = 10 WHERE precioven1 = 0")
        oApp:oServer:Execute("UPDATE articu_temp SET reventa1 = 10 WHERE reventa1 = 0")
   CASE nRedondeo = 4
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1/50)*50, reventa1 = ROUND(reventa1/50)*50")
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = 50 WHERE precioven1 = 0")
        oApp:oServer:Execute("UPDATE articu_temp SET reventa1 = 50 WHERE reventa1 = 0")
   CASE nRedondeo = 5
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = ROUND(precioven1,-2), reventa1 = ROUND(reventa1,-2)")
        oApp:oServer:Execute("UPDATE articu_temp SET precioven1 = 100 WHERE precioven1 = 0")
        oApp:oServer:Execute("UPDATE articu_temp SET reventa1 = 100 WHERE reventa1 = 0")
ENDCASE
RETURN nil


***********************************************************************************
** Dialogo de seleccion de articulos (reutiliza el resource ABMART1).
** Devuelve un string SQL con el WHERE o "" si el usuario cancela.
STATIC FUNCTION FiltrarPos(oDlg)
LOCAL oFilt, oBot:=ARRAY(2), oGet:=ARRAY(50), lRta:=.f., oSay1, oSay2
LOCAL oQry2, oQry3p, oQry4, oQry5, oQry6, oQry7
LOCAL vMarca, cMarc:=SPACE(30), vRubro, cRub:=SPACE(30), vempresa, cEmp:=SPACE(30)
LOCAL vdepto, cDept:=SPACE(30), vProv, cProve:=SPACE(30), vcodigo
LOCAL vnombre:=SPACE(30), vnomregi:=SPACE(30), vstockmin, vstockact, vstockide
LOCAL vpreciocos, viva, cIvaNom:=SPACE(30)
LOCAL vdesc1, vdesc2, vdesc3, vdesc4, vdesc5, vprecioven, vpresugeri, vprecossiva
LOCAL vpreciopro, vporcentaje
LOCAL vfecmodd:="  /  /    ", vfecmodh:="  /  /    "
LOCAL vfecultcomd:="  /  /    ", vfecultcomh:="  /  /    "
LOCAL vneto, vimpint, vflete, vunimed, vobserva
LOCAL vpesable:=.f., vmprima:=.f., vproduccion:=.f., vnosale:=.f.
LOCAL vmedida, ventero, vuxbulto, vpxbulto, vsiniva:=.f.
LOCAL cWhere := ""

oQry2  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
oQry3p := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
oQry4  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
oQry5  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
oQry6  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
oQry7  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")

DEFINE DIALOG oFilt TITLE "Seleccion de articulos" RESOURCE "ABMART1" OF oDlg
   oFilt:lHelpIcon := .f.
   REDEFINE GET oGet[01] VAR vcodigo  ID 100 OF oFilt
   REDEFINE GET oGet[02] VAR vnombre  PICTURE "@!" ID 101 OF oFilt
   REDEFINE GET oGet[03] VAR vnomregi ID 102 OF oFilt
   REDEFINE CHECKBOX oGet[34] VAR vnosale     ID 103
   REDEFINE CHECKBOX oGet[46] VAR vpesable    ID 4011 OF oFilt
   REDEFINE CHECKBOX oGet[44] VAR vmprima     ID 4007 OF oFilt
   REDEFINE CHECKBOX oGet[45] VAR vproduccion ID 4008 OF oFilt

   REDEFINE GET oGet[04] VAR vprov ID 104 OF oFilt ;
            VALID(EMPTY(oGet[04]:cText) .or. Buscar(oQry2,oFilt,oGet[04],oGet[05])) ;
            ACTION (oGet[04]:cText := 0, Buscar(oQry2,oFilt,oGet[04],oGet[05])) BITMAP "BUSC1"
   REDEFINE GET oGet[05] VAR cProve ID 105 OF oFilt WHEN(.F.)
   REDEFINE GET oGet[21] VAR vmarca ID 122 OF oFilt ;
            VALID(EMPTY(oGet[21]:cText) .or. Buscar(oQry4,oFilt,oGet[21],oGet[22])) ;
            ACTION (oGet[21]:cText := 0, Buscar(oQry4,oFilt,oGet[21],oGet[22])) BITMAP "BUSC1"
   REDEFINE GET oGet[22] VAR cMarc  ID 123 OF oFilt WHEN(.F.)
   REDEFINE GET oGet[23] VAR vrubro ID 124 OF oFilt ;
            VALID(EMPTY(oGet[23]:cText) .or. Buscar(oQry5,oFilt,oGet[23],oGet[24])) ;
            ACTION (oGet[23]:cText := 0, Buscar(oQry5,oFilt,oGet[23],oGet[24])) BITMAP "BUSC1"
   REDEFINE GET oGet[24] VAR cRub ID 125 OF oFilt WHEN(.F.)
   REDEFINE GET oGet[27] VAR vempresa ID 126 OF oFilt ;
            VALID(EMPTY(oGet[27]:cText) .or. Buscar(oQry7,oFilt,oGet[27],oGet[28])) ;
            ACTION (oGet[27]:cText := 0, Buscar(oQry7,oFilt,oGet[27],oGet[28])) BITMAP "BUSC1"
   REDEFINE GET oGet[28] VAR cEmp ID 127 OF oFilt WHEN(.F.)
   REDEFINE GET oGet[25] VAR vdepto ID 128 OF oFilt ;
            VALID(EMPTY(oGet[25]:cText) .or. Buscar(oQry6,oFilt,oGet[25],oGet[26])) ;
            ACTION (oGet[25]:cText := 0, Buscar(oQry6,oFilt,oGet[25],oGet[26])) BITMAP "BUSC1"
   REDEFINE GET oGet[26] VAR cDept ID 129 OF oFilt WHEN(.F.)

   REDEFINE GET oGet[35] VAR vunimed  ID 135 OF oFilt PICTURE "@!"
   REDEFINE GET oGet[47] VAR vmedida  ID 500 OF oFilt PICTURE "9999999"
   REDEFINE GET oGet[48] VAR ventero  ID 501 OF oFilt PICTURE "9999999"
   REDEFINE GET oGet[49] VAR vuxbulto ID 502 OF oFilt PICTURE "99999"
   REDEFINE GET oGet[50] VAR vpxbulto ID 503 OF oFilt PICTURE "99999999.99"

   REDEFINE CHECKBOX oGet[46] VAR vsiniva ID 4003 OF oFilt
   REDEFINE GET oGet[06] VAR vprecossiva ID 106 OF oFilt
   REDEFINE GET oGet[07] VAR vdesc1      ID 107 OF oFilt
   REDEFINE GET oGet[08] VAR vdesc2      ID 108 OF oFilt
   REDEFINE GET oGet[09] VAR vdesc3      ID 109 OF oFilt
   REDEFINE GET oGet[10] VAR vdesc4      ID 110 OF oFilt
   REDEFINE GET oGet[11] VAR vdesc5      ID 111 OF oFilt
   REDEFINE GET oGet[39] VAR vNeto       ID 112 OF oFilt
   REDEFINE GET oGet[12] VAR vimpint     ID 113 OF oFilt
   REDEFINE GET oGet[13] VAR vflete      ID 114 OF oFilt
   REDEFINE GET oGet[14] VAR viva        ID 115 OF oFilt ;
            VALID(EMPTY(oGet[14]:cText) .or. (Buscar(oQry3p,oFilt,oGet[14],oGet[15]) .and. ;
                  ((oGet[15]:cText := STR(oQry3p:tasa,6,2)+"%") <> "xxx"))) ;
            ACTION (oGet[14]:cText := 0, Buscar(oQry3p,oFilt,oGet[14],oGet[15]), ;
                    (oGet[15]:cText := STR(oQry3p:tasa,6,2)+"%") <> "xxx") BITMAP "BUSC1"
   REDEFINE GET oGet[15] VAR cIvaNom     ID 116 OF oFilt WHEN(.F.)
   REDEFINE GET oGet[16] VAR vpreciocos  ID 117 OF oFilt
   REDEFINE GET oGet[17] VAR vporcentaje ID 118 OF oFilt
   REDEFINE GET oGet[18] VAR vpreciopro  ID 119 OF oFilt
   REDEFINE GET oGet[19] VAR vpresugeri  ID 120 OF oFilt
   REDEFINE GET oGet[20] VAR vprecioven  ID 121 OF oFilt

   REDEFINE GET oGet[41] VAR vfecultcomd ID 1300 OF oFilt PICTURE "@D"
   REDEFINE SAY oSay1 PROMPT "Hasta ultima compra:" ID 802 OF oFilt
   REDEFINE GET oGet[29] VAR vfecultcomh ID 130  OF oFilt PICTURE "@D"
   REDEFINE SAY oSay2 PROMPT "Desde cambio precio:" ID 803 OF oFilt
   REDEFINE GET oGet[30] VAR vfecmodd    ID 131  OF oFilt PICTURE "@D"
   REDEFINE GET oGet[42] VAR vfecmodh    ID 1311 OF oFilt PICTURE "@D"

   REDEFINE GET oGet[31] VAR vstockmin ID 132 OF oFilt
   REDEFINE GET oGet[32] VAR vstockact ID 133 OF oFilt
   REDEFINE GET oGet[33] VAR vstockide ID 134 OF oFilt
   REDEFINE GET oGet[36] VAR vobserva  ID 136 OF oFilt

   REDEFINE BUTTON oBot[1] ID 137 OF oFilt ;
            ACTION ((lRta := .t.), oFilt:End())
   REDEFINE BUTTON oBot[2] ID 138 OF oFilt ;
            ACTION ((lRta := .f.), oFilt:End()) CANCEL

ACTIVATE DIALOG oFilt CENTER ON INIT (oGet[01]:SetFocus(), oGet[34]:Hide())

oQry2:End()
oQry3p:End()
oQry4:End()
oQry5:End()
oQry6:End()
oQry7:End()

IF !lRta
   RETURN ""
ENDIF

cWhere := " 1=1 " + IF(EMPTY(vcodigo),""," and a.CODIGO ="+ClipValue2SQL(vcodigo)+"") ;
   + IF(EMPTY(vnombre),"","  and TRIM(a.NOMBRE) like '%"+ALLTRIM(vnombre)+"%'") ;
   + IF(EMPTY(vnomregi),"","  and TRIM(a.nomregi) like '%"+ALLTRIM(vnomregi)+"%'") ;
   + IF(!vnosale,""," and a.nosale = TRUE ") ;
   + IF(!vpesable,""," and a.pesable = TRUE ") ;
   + IF(!vmprima,""," and a.mprima = TRUE ") ;
   + IF(!vproduccion,""," and a.produccion = TRUE ") ;
   + IF(!vsiniva,""," and a.siniva = TRUE ") ;
   + IF(EMPTY(vProv),""," and a.prov ="+ClipValue2SQL(vProv)+"") ;
   + IF(EMPTY(vMarca),""," and a.marca ="+ClipValue2SQL(vMarca)+"") ;
   + IF(EMPTY(vRubro),""," and a.rubro ="+ClipValue2SQL(vRubro)+"") ;
   + IF(EMPTY(vempresa),""," and a.empresa ="+ClipValue2SQL(vempresa)+"") ;
   + IF(EMPTY(vdepto),""," and a.depto ="+ClipValue2SQL(vdepto)+"") ;
   + IF(EMPTY(vstockmin),""," and a.stockmin ="+ClipValue2SQL(vstockmin)+"") ;
   + IF(EMPTY(vmedida),""," and a.medida ="+ClipValue2SQL(vmedida)+"") ;
   + IF(EMPTY(ventero),""," and a.entero ="+ClipValue2SQL(ventero)+"") ;
   + IF(EMPTY(vuxbulto),""," and a.uxbulto ="+ClipValue2SQL(vuxbulto)+"") ;
   + IF(EMPTY(vpxbulto),""," and a.pxbulto ="+ClipValue2SQL(vpxbulto)+"") ;
   + IF(EMPTY(vstockact),""," and a.stockact ="+ClipValue2SQL(vstockact)+"") ;
   + IF(EMPTY(vstockide),""," and a.stockide ="+ClipValue2SQL(vstockide)+"") ;
   + IF(EMPTY(vunimed),"","  and TRIM(a.unimed) like '%"+ALLTRIM(vunimed)+"%'") ;
   + IF(EMPTY(vpreciocos),""," and a.preciocos ="+ClipValue2SQL(vpreciocos)+"") ;
   + IF(EMPTY(vporcentaje),""," and a.porcentaje ="+ClipValue2SQL(vporcentaje)+"") ;
   + IF(EMPTY(vprecossiva),""," and a.precossiva ="+ClipValue2SQL(vprecossiva)+"") ;
   + IF(EMPTY(vneto),""," and a.neto ="+ClipValue2SQL(vneto)+"") ;
   + IF(EMPTY(vimpint),""," and a.impint ="+ClipValue2SQL(vimpint)+"") ;
   + IF(EMPTY(vflete),""," and a.flete ="+ClipValue2SQL(vflete)+"") ;
   + IF(EMPTY(viva),""," and a.iva ="+ClipValue2SQL(viva)+"") ;
   + IF(EMPTY(vdesc1),""," and a.desc1 ="+ClipValue2SQL(vdesc1)+"") ;
   + IF(EMPTY(vdesc2),""," and a.desc2 ="+ClipValue2SQL(vdesc2)+"") ;
   + IF(EMPTY(vdesc3),""," and a.desc3 ="+ClipValue2SQL(vdesc3)+"") ;
   + IF(EMPTY(vdesc4),""," and a.desc4 ="+ClipValue2SQL(vdesc4)+"") ;
   + IF(EMPTY(vdesc5),""," and a.desc5 ="+ClipValue2SQL(vdesc5)+"") ;
   + IF(EMPTY(vprecioven),""," and a.precioven ="+ClipValue2SQL(vprecioven)+"") ;
   + IF(EMPTY(vpreciopro),""," and a.preciopro ="+ClipValue2SQL(vpreciopro)+"") ;
   + IF(EMPTY(vpresugeri),""," and a.presugeri ="+ClipValue2SQL(vpresugeri)+"") ;
   + IF(vfecultcomd="  /  /    ",""," and a.fecultcom >="+ClipValue2SQL(CTOD(vfecultcomd))+"") ;
   + IF(vfecultcomh="  /  /    ",""," and a.fecultcom <="+ClipValue2SQL(CTOD(vfecultcomh))+"") ;
   + IF(vfecmodd="  /  /    ",""," and a.fecmod >="+ClipValue2SQL(CTOD(vfecmodd))+"") ;
   + IF(vfecmodh="  /  /    ",""," and a.fecmod <="+ClipValue2SQL(CTOD(vfecmodh))+"") ;
   + IF(EMPTY(vobserva),"","  and TRIM(a.observa) like '%"+ALLTRIM(vobserva)+"%'")

RETURN cWhere


***********************************************************************************
** Inserta en prepos a partir de articu_temp (modo filtro).
** Sobrescribe pendientes existentes del mismo codigo (ON DUPLICATE KEY UPDATE).
** Devuelve .t. si grabo OK, .f. si hubo error.
STATIC FUNCTION GrabarPosFiltro(dFecPrev, cObserva)
LOCAL oError
TRY
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"prepos "+;
      "(codigo, nombre, siniva, iva, precossiva, desc1, desc2, desc3, desc4, desc5, "+;
      " impint, flete, preciocos, porcentaje, precioven, porcentajerev, reventa, "+;
      " fecprev, fecalta, horalta, usuario, ip, observa) "+;
      "SELECT a.codigo, a.nombre, a.siniva, a.iva, t.preciocos1, "+;
      "       a.desc1, a.desc2, a.desc3, a.desc4, a.desc5, a.impint, a.flete, "+;
      "       t.costofin, t.incru1, TRUNCATE(t.precioven1,0), t.incruR1, TRUNCATE(t.reventa1,0), "+;
      "       "+ClipValue2Sql(dFecPrev)+", CURDATE(), CURTIME(), "+;
      "       "+ClipValue2Sql(oApp:usuario)+", "+ClipValue2Sql(oApp:cIp)+", "+;
      "       "+ClipValue2Sql(ALLTRIM(cObserva))+" "+;
      "FROM articu_temp t "+;
      "INNER JOIN ge_"+oApp:cId+"articu a ON a.codigo = t.codigo "+;
      "WHERE (a.preciocos <> t.costofin "+;
      "    OR a.precioven <> TRUNCATE(t.precioven1,0) "+;
      "    OR a.reventa <> TRUNCATE(t.reventa1,0)) "+;
      "ON DUPLICATE KEY UPDATE "+;
      "nombre        = VALUES(nombre), "+;
      "siniva        = VALUES(siniva), "+;
      "iva           = VALUES(iva), "+;
      "precossiva    = VALUES(precossiva), "+;
      "desc1         = VALUES(desc1), "+;
      "desc2         = VALUES(desc2), "+;
      "desc3         = VALUES(desc3), "+;
      "desc4         = VALUES(desc4), "+;
      "desc5         = VALUES(desc5), "+;
      "impint        = VALUES(impint), "+;
      "flete         = VALUES(flete), "+;
      "preciocos     = VALUES(preciocos), "+;
      "porcentaje    = VALUES(porcentaje), "+;
      "precioven     = VALUES(precioven), "+;
      "porcentajerev = VALUES(porcentajerev), "+;
      "reventa       = VALUES(reventa), "+;
      "fecprev       = VALUES(fecprev), "+;
      "fecalta       = VALUES(fecalta), "+;
      "horalta       = VALUES(horalta), "+;
      "usuario       = VALUES(usuario), "+;
      "ip            = VALUES(ip), "+;
      "observa       = VALUES(observa)")
   oApp:oServer:CommitTransaction()
CATCH oError
   oApp:oServer:RollBack()
   MsgStop("Error al grabar"+CHR(10)+oError:description, "Error")
   RETURN .f.
END TRY
RETURN .t.


***********************************************************************************
** Carga masiva por lista de proveedor (equivalente a PREGENLIS pero graba en prepos)
STATIC FUNCTION AltaMasivaLis()
LOCAL oForm, oForm2, oGet := ARRAY(5), oBot := ARRAY(6), oBrwTmp, oBrw2, oQryTemp, acor
LOCAL oQryPro, mcodpro := 0, cNomPro := SPACE(30)
LOCAL aCols, i, nError, lYaApreto := .f.
LOCAL dFecPrev := DATE(), cObserva := SPACE(255)
LOCAL lRta := .f., lConf := .f., nTotal := 0

oQryPro := oApp:oServer:Query("SELECT codigo, nombre FROM ge_"+oApp:cId+"provee")
aCols := {{SPACE(14), SPACE(30), 0.00, SPACE(30), 0, 0, 0}}

DO WHILE .t.
   lRta := .f.
   lYaApreto := .f.

   // ----- Dialog 1: pegar lista + fecha prevista -----
   DEFINE DIALOG oForm TITLE "Carga masiva de Precios Posdatados - Lista de Proveedor" ;
          FROM 02,01 TO 36,110 OF oWnd1 FONT oApp:oFont
      oForm:lHelpIcon := .f.
      acor := AcepCanc(oForm)

      @ 07, 05 SAY "Proveedor:"      OF oForm PIXEL RIGHT SIZE 50,10
      @ 05, 60 GET oGet[01] VAR mcodpro OF oForm PICTURE "999999" PIXEL SIZE 30,12 RIGHT ;
               VALID(Buscar(oQryPro,oForm,oGet[01],oGet[02])) ;
               ACTION (oGet[01]:cText := 0, Buscar(oQryPro,oForm,oGet[01],oGet[02])) BITMAP "BUSC1"
      @ 05, 95 GET oGet[02] VAR cNomPro OF oForm PIXEL PICTURE "@!" SIZE 130,10 WHEN(.F.)

      @ 07, 240 SAY "Fecha prevista:" OF oForm PIXEL RIGHT SIZE 60,10
      @ 05, 305 GET oGet[03] VAR dFecPrev OF oForm PIXEL RIGHT SIZE 50,10

      @ 20, 205 SAY "Observacion:"    OF oForm PIXEL RIGHT SIZE 55,10
      @ 20, 270 GET oGet[04] VAR cObserva OF oForm PIXEL PICTURE "@S20" SIZE 120,10

      @ 40, 05 XBROWSE oBrwTmp SIZE 500,140 PIXEL OF oForm ARRAY aCols ;
         HEADERS "Cod.Prov.","Producto","Costo","Observaciones","Cod.Propio","UxB","Costo Bulto" ;
         PICTURE "@!","@!","999999999.999","@!","99999999999999","999","999999999.99" ;
         COLUMNS 1, 2, 3, 4, 5, 6, 7 ;
         SIZES 80,200,70,180,90,40,80 ;
         CELL LINES NOBORDER
      WITH OBJECT oBrwTmp
         :nEditTypes := 1
         :bKeyDown   := { |nKey| IF(nKey == VK_DELETE, oBrwTmp:Delete(), )}
         :CreateFromCode()
         :aCols[3]:nEditType   := EDIT_GET
         :aCols[6]:nEditType   := EDIT_GET
         :aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCantPos(xVal, oBrwTmp, @aCols)}
      END
      PintaBrw(oBrwTmp, 0)

      @ 210, 5 SAY "Pegue la lista del proveedor (Cod.Prov. en columna 1, Costo en columna 3). "+CHR(10)+;
                   "Los codigos del proveedor deben estar previamente mapeados en ge_codpro. "+CHR(10)+;
                   "El Cod.Propio se completa automaticamente al validar." OF oForm PIXEL SIZE 540,40

      @ 20, 005 BUTTON oBot[3] PROMPT "&Pegar" OF oForm SIZE 50,12 ;
                ACTION (Procesando(.t.), oBrwTmp:Paste(), RecalcPos(oBrwTmp), Procesando(.f.)) PIXEL ;
                WHEN(mcodpro > 0)

      @ acor[1], acor[2]      BUTTON oBot[1] PROMPT "&Procesar"          OF oForm SIZE 50,12 ;
                ACTION ((lRta := .t.), oForm:End()) PIXEL
      @ acor[1], acor[2]+60   BUTTON oBot[4] PROMPT "&Borrar Errores"    OF oForm SIZE 60,12 ;
                ACTION (BorrarErrPos(oBrwTmp, @aCols)) PIXEL
      @ acor[1], acor[2]+130  BUTTON oBot[5] PROMPT "Procesar con &UxB"  OF oForm SIZE 70,12 ;
                ACTION (ProcesarUxBPos(oBrwTmp, @aCols, mcodpro), lYaApreto := .t.) PIXEL ;
                WHEN(!lYaApreto)
      @ acor[3], acor[4]      BUTTON oBot[2] PROMPT "&Cancelar"          OF oForm SIZE 50,12 ;
                ACTION ((lRta := .f.), oForm:End()) PIXEL CANCEL
   ACTIVATE DIALOG oForm CENTER ON INIT oGet[01]:SetFocus()

   IF !lRta
      oQryPro:End()
      RETURN nil
   ENDIF

   Procesando(.t.)
   nError := 0
   FOR i := 1 TO LEN(aCols)
      IF EMPTY(aCols[i,1])
         aCols[i,4] := "No puede estar vacio"
         nError++
      ELSE
         IF oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
            "WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):nRecCount = 0
            nError++
            aCols[i,4] := "NO EXISTE en su sistema para este proveedor"
         ELSE
            aCols[i,5] := oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
               "WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):codart
         ENDIF
      ENDIF
      IF EMPTY(aCols[i,3])
         nError++
         aCols[i,4] := "Costo no puede estar en cero"
      ENDIF
      IF aCols[i,6] > 0 .and. aCols[i,7] > 0
         aCols[i,3] := ROUND(aCols[i,7] / aCols[i,6], 2)
      ENDIF
   NEXT
   Procesando(.f.)

   IF nError > 0
      MsgStop("Hay "+LTRIM(STR(nError))+" errores. Revise la lista o use 'Borrar Errores'.","Errores")
      LOOP
   ENDIF

   // articu_temp para preview
   oApp:oServer:Execute("DROP TABLE IF EXISTS articu_temp")
   oApp:oServer:NextResult()
   oApp:oServer:Execute("CREATE TEMPORARY TABLE articu_temp ("+;
      "codigo     BIGINT(14) NOT NULL,"+;
      "nombre     VARCHAR(150) NOT NULL,"+;
      "preciocos  DECIMAL(12,2) DEFAULT '0',"+;
      "preciocos1 DECIMAL(12,2) DEFAULT '0',"+;
      "incru      DECIMAL(12,2) DEFAULT '0',"+;
      "incru1     DECIMAL(12,2) DEFAULT '0',"+;
      "uxbulto    INT(4) DEFAULT '0',"+;
      "pxbulto    DECIMAL(12,2) DEFAULT '0.00'"+;
      ") ENGINE=INNODB DEFAULT CHARSET=utf8")
   oApp:oServer:NextResult()

   FOR i := 1 TO LEN(aCols)
      IF !EMPTY(aCols[i,5])
         oApp:oServer:Execute("INSERT INTO articu_temp (codigo, nombre, preciocos, incru, preciocos1, incru1, uxbulto, pxbulto) "+;
            "(SELECT a.codigo, a.nombre, a.precossiva, a.porcentaje, "+;
            ClipValue2Sql(aCols[i,3])+", a.porcentaje, "+;
            ClipValue2Sql(aCols[i,6])+", "+ClipValue2Sql(aCols[i,7])+" "+;
            "FROM ge_"+oApp:cId+"articu a WHERE a.codigo = "+ClipValue2Sql(aCols[i,5])+")")
      ENDIF
   NEXT i

   oQryTemp := oApp:oServer:Query("SELECT * FROM articu_temp")
   nTotal   := oQryTemp:RecCount()

   IF nTotal = 0
      MsgInfo("No quedaron articulos validos para procesar.","Atencion")
      oQryTemp:End()
      LOOP
   ENDIF

   // ----- Dialog 2: preview -----
   lConf := .f.
   DEFINE DIALOG oForm2 TITLE "Previsualizacion - "+LTRIM(STR(nTotal))+" articulos a posdatar" ;
          FROM 02,05 TO 36,115 OF oWnd1 FONT oApp:oFont
      oForm2:lHelpIcon := .f.
      acor := AcepCanc(oForm2)
      @ 05, 02 XBROWSE oBrw2 DATASOURCE oQryTemp ;
               COLUMNS "codigo","nombre","preciocos","incru","preciocos1","incru1","uxbulto","pxbulto" ;
               HEADERS "Codigo","Articulo","Costo Act.","Util.","Nuevo Costo","Util.Nueva","UxBto","PxBto" ;
               SIZES 50,200,70,50,80,60,50,80 ;
               OF oForm2 SIZE 480,140 AUTOSORT PIXEL
      oBrw2:CreateFromCode()
      PintaBrw(oBrw2, 0)

      @ acor[1], acor[2] BUTTON oBot[1] PROMPT "&Confirmar" OF oForm2 SIZE 50,12 ;
              ACTION ((lConf := .t.), oForm2:End()) PIXEL
      @ acor[3], acor[4] BUTTON oBot[2] PROMPT "&Cancelar"  OF oForm2 SIZE 50,12 ;
              ACTION ((lConf := .f.), oForm2:End()) PIXEL CANCEL
   ACTIVATE DIALOG oForm2 CENTER

   oQryTemp:End()

   IF !lConf
      oApp:oServer:Execute("DROP TABLE IF EXISTS articu_temp")
      oApp:oServer:NextResult()
      LOOP
   ENDIF

   IF GrabarPosLista(dFecPrev, cObserva)
      MsgInfo("Cambios posdatados grabados con exito.","Proceso exitoso")
      EXIT
   ENDIF
   LOOP
ENDDO

oQryPro:End()
oApp:oServer:Execute("DROP TABLE IF EXISTS articu_temp")
oApp:oServer:NextResult()
RETURN nil


***********************************************************************************
** Inserta en prepos a partir de articu_temp (modo lista de proveedor).
** Calcula costo final con descuentos/flete/iva/impint y aplica el % utilidad
** y % util.rev actuales del articulo para venta y reventa.
STATIC FUNCTION GrabarPosLista(dFecPrev, cObserva)
LOCAL oError, cCostoDesc, cCostoFlete, cCostoFin

cCostoDesc := "IF(a.siniva,t.preciocos1,100*t.preciocos1/(100+(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)))"

cCostoFlete := "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100)) ) "
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc2/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc3/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc4/100)) )"
cCostoFlete := "("+cCostoFlete+" - ("+cCostoFlete+"*(a.desc5/100)) )"

cCostoFin := "("+cCostoDesc+"  - ("+cCostoDesc+"*(a.desc1/100))) "
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc2/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc3/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc4/100)))"
cCostoFin := "("+cCostoFin+" - ("+cCostoFin+" *(a.desc5/100)))"
cCostoFin := "("+cCostoFin+" + (("+cCostoFin+"*(SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = a.iva)/100)) + "+;
             "a.impint + ("+cCostoFlete+"*a.flete/100) )"

TRY
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"prepos "+;
      "(codigo, nombre, siniva, iva, precossiva, desc1, desc2, desc3, desc4, desc5, "+;
      " impint, flete, preciocos, porcentaje, precioven, porcentajerev, reventa, "+;
      " fecprev, fecalta, horalta, usuario, ip, observa) "+;
      "SELECT a.codigo, a.nombre, a.siniva, a.iva, t.preciocos1, "+;
      "       a.desc1, a.desc2, a.desc3, a.desc4, a.desc5, a.impint, a.flete, "+;
      "       "+cCostoFin+", a.porcentaje, "+;
      "       TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentaje/100), 0), "+;
      "       a.porcentajerev, "+;
      "       TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentajerev/100), 0), "+;
      "       "+ClipValue2Sql(dFecPrev)+", CURDATE(), CURTIME(), "+;
      "       "+ClipValue2Sql(oApp:usuario)+", "+ClipValue2Sql(oApp:cIp)+", "+;
      "       "+ClipValue2Sql(ALLTRIM(cObserva))+" "+;
      "FROM ge_"+oApp:cId+"articu a "+;
      "INNER JOIN articu_temp t ON t.codigo = a.codigo "+;
      "WHERE (a.preciocos <> "+cCostoFin+" "+;
      "    OR a.precioven <> TRUNCATE("+cCostoFin+" + "+cCostoFin+" * (a.porcentaje/100), 0)) "+;
      "ON DUPLICATE KEY UPDATE "+;
      "nombre        = VALUES(nombre), "+;
      "siniva        = VALUES(siniva), "+;
      "iva           = VALUES(iva), "+;
      "precossiva    = VALUES(precossiva), "+;
      "desc1         = VALUES(desc1), "+;
      "desc2         = VALUES(desc2), "+;
      "desc3         = VALUES(desc3), "+;
      "desc4         = VALUES(desc4), "+;
      "desc5         = VALUES(desc5), "+;
      "impint        = VALUES(impint), "+;
      "flete         = VALUES(flete), "+;
      "preciocos     = VALUES(preciocos), "+;
      "porcentaje    = VALUES(porcentaje), "+;
      "precioven     = VALUES(precioven), "+;
      "porcentajerev = VALUES(porcentajerev), "+;
      "reventa       = VALUES(reventa), "+;
      "fecprev       = VALUES(fecprev), "+;
      "fecalta       = VALUES(fecalta), "+;
      "horalta       = VALUES(horalta), "+;
      "usuario       = VALUES(usuario), "+;
      "ip            = VALUES(ip), "+;
      "observa       = VALUES(observa)")
   oApp:oServer:CommitTransaction()
CATCH oError
   oApp:oServer:RollBack()
   MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
   RETURN .f.
END TRY
RETURN .t.


***********************************************************************************
** Helpers de la lista de proveedor (equivalentes a CambiaCant/Recalc/BorrarErr/ProcesarUxB
** de PREGENLIS, adaptados a este modulo)
STATIC FUNCTION CambiaCantPos(n, oBrw, aCols)
LOCAL i := oBrw:keyno()
aCols[i,6] := n
IF aCols[i,6] > 0
   aCols[i,3] := aCols[i,7] / aCols[i,6]
ENDIF
oBrw:Refresh()
RETURN nil


STATIC FUNCTION RecalcPos(oBrw)
LOCAL i
oBrw:GoTop()
FOR i := 1 TO LEN(oBrw:aArrayData)
   IF oBrw:aArrayData[i,6] = 0
      oBrw:aArrayData[i,7] := oBrw:aArrayData[i,3]
      oBrw:aArrayData[i,6] := 1
   ELSE
      oBrw:aArrayData[i,3] := oBrw:aArrayData[i,7] / oBrw:aArrayData[i,6]
   ENDIF
NEXT i
RETURN nil


STATIC FUNCTION BorrarErrPos(oBrw, aCols)
LOCAL i := 1, nTotal := LEN(oBrw:aArrayData)
oBrw:GoTop()
DO WHILE !oBrw:Eof()
   IF !EMPTY(oBrw:aCols[4]:Value())
      oBrw:Delete()
   ELSE
      oBrw:Skip()
   ENDIF
   i++
   IF i > nTotal
      EXIT
   ENDIF
ENDDO
RETURN nil


STATIC FUNCTION ProcesarUxBPos(oBrw, aCols, mcodpro)
LOCAL i, nError, oQryA
Procesando(.t.)
nError := 0
FOR i := 1 TO LEN(aCols)
   IF EMPTY(aCols[i,1])
      aCols[i,4] := "No puede estar vacio"
      nError++
   ELSE
      IF oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
         "WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):nRecCount = 0
         nError++
         aCols[i,4] := "NO EXISTE en su sistema para este proveedor"
      ELSE
         aCols[i,5] := oApp:oServer:Query("SELECT codart FROM ge_"+oApp:cId+"codpro "+;
            "WHERE codpro = "+ClipValue2SQL(mcodpro)+" AND codarp = "+ClipValue2SQL(aCols[i,1])):codart
         aCols[i,2] := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu "+;
            "WHERE codigo = "+ClipValue2SQL(aCols[i,5])):nombre
      ENDIF
   ENDIF
   IF EMPTY(aCols[i,3])
      nError++
      aCols[i,4] := "Costo no puede estar en cero"
   ENDIF
   IF aCols[i,5] <> 0
      oQryA := oApp:oServer:Query("SELECT uxbulto FROM ge_"+oApp:cId+"articu "+;
         "WHERE codigo = "+ClipValue2SQL(aCols[i,5]))
      IF oQryA:uxbulto > 0
         aCols[i,6] := oQryA:uxbulto
         aCols[i,7] := aCols[i,3]
         aCols[i,3] := aCols[i,7] / aCols[i,6]
      ENDIF
   ENDIF
NEXT
Procesando(.f.)
IF nError > 0
   MsgStop("Hay "+LTRIM(STR(nError))+" errores","Errores")
ENDIF
oBrw:Refresh()
RETURN nil
