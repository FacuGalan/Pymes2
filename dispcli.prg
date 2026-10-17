// DISPCLI.PRG - Display del cliente (segunda pantalla del punto de venta)
//
// Todo el display vive acá; el módulo de facturación (FACT.PRG) solo le pasa
// los datos de la venta en curso. Así se puede reusar desde FACT_multi/VENTAS.
//
// API pública:
//   DispCliAbrir( lForzarPrimario, bDatos ) -> toggle; .T. si quedó abierto.
//        bDatos: bloque que devuelve el hash de datos (ver DispCliActualizar).
//        lForzarPrimario: si no hay 2do monitor lo muestra en el principal
//        (para probar con Ctrl+F11 en PCs con un solo monitor).
//   DispCliActualizar( hDat ) -> refresca con los datos actuales. Seguro de
//        llamar siempre: si el display no está abierto no hace nada.
//        hDat = { "items"  => { { nCant, cDetalle, nPUnit, nImporte, lEsPromo, lOferta }, ... },
//                 "total"  => n, "pagado" => n, "vuelto" => n,
//                 "aviso"  => cTexto de la oferta del último artículo cargado }
//   DispCliCerrar()   -> cierra el display si está abierto.
//   DispCliAbierto()  -> .T. si el display está abierto.
//   DispCliLeerIni()  -> hash con la configuración de esta PC (display.ini).
//        hCfg[ "mensajes" ] = array con los renglones de texto libre del
//        cliente (sección [mensajes] msg1..msg20) para la pantalla de espera.
//   DispCliConfig( oWnd ) -> diálogo para configurar la 2da pantalla de esta
//        PC (graba display.ini; si el display está abierto lo reabre).
//   DispCliGrabarIni( hCfg ) -> graba la configuración (para el módulo de
//        configuración del punto de venta).
//
// Configuración por PC en .\display.ini (se crea solo la primera vez que se
// detecta un segundo monitor). Modelos: CLASICO / MODERNO / WEB.
// Por ahora (fase 1) MODERNO y WEB caen al CLASICO.

#include "Fivewin.ch"
#include "xbrowse.ch"

MEMVAR oApp

#define DISP_INI      ".\display.ini"
#define MAX_MENSAJES  20

static oDlgCust, oBrwCust, oSayTotalCust, oSayPagadoCust, oSayVueltoCust,;
       oVideoCust, oBrushBgCust, aItemsCust
static cModeloAct := "", hMod, oTmrCust                  // modelo MODERNO
static oWebCust, hWeb, lDispDebug := .F.                  // modelo WEB / diagnóstico
static bDatosAbrir, lForzarAbrir := .F.                   // para reabrir al cambiar la config
static hOfSet, nOfSetT := 0, aOfLista, nOfListaT := 0,;  // cache de ofertas
       cOfId := "", cTabId := "", lTabArt, lTabGrp, lHoraArt

//-----------------------------------------------------------------------------
// Abre (o cierra, si ya está abierto) el display del cliente.
//   - Sin parámetros: muestra en el monitor secundario. Si no hay segundo
//     monitor retorna .F. silenciosamente.
//   - lForzarPrimario: si .T. y no hay monitor secundario, lo muestra en el
//     principal (para pruebas con Ctrl+F11).
//-----------------------------------------------------------------------------
function DispCliAbrir( lForzarPrimario, bDatos )

   local aMonitores, aMonElegido, aRect, hCfg
   local nPrevDpiCtx := nil   // contexto DPI previo del hilo (para restaurarlo)

   default lForzarPrimario := .F.

   bDatosAbrir  := bDatos            // DispCliConfig lo reabre con lo mismo
   lForzarAbrir := lForzarPrimario

   // Toggle: si ya está abierto lo cierro
   if oDlgCust != nil
      DispCliCerrar()
      return .F.
   endif

   // ------------------------------------------------------------------
   // PASO 1: contar monitores SIN tocar todavía el DPI. La CANTIDAD de
   // monitores no depende del estado DPI (solo cambian los VALORES de las
   // coordenadas, no cuántos hay). Así si hay un solo monitor y no se fuerza
   // el primario, salimos SIN haber alterado el DPI, dejando intacta la
   // ventana principal del POS. Esto evita que a 125% (un solo monitor) se
   // redimensione la pantalla y cambien fuentes/iconos al invocar el display.
   // ------------------------------------------------------------------
   aMonitores := ObtenerMonitores()

   // Primera vez que esta PC tiene 2do monitor: dejo el ini básico
   if Len( aMonitores ) >= 2 .and. ! File( DISP_INI )
      CrearIniBasico()
   endif
   hCfg := DispCliLeerIni()
   lDispDebug := ( Upper( hCfg[ "debug" ] ) == "S" )

   aMonElegido := ElegirMonitor( aMonitores, hCfg, lForzarPrimario )
   if aMonElegido == nil
      return .F.       // un solo monitor (caso común): NO se toca el DPI
   endif

   // ------------------------------------------------------------------
   // PASO 2: ya sabemos que vamos a abrir el display. Hacemos DPI-aware SOLO
   // ESTE HILO y de forma REVERSIBLE con SetThreadDpiAwarenessContext, en vez
   // de SetProcessDPIAware (que era PERMANENTE y afectaba a TODA la app: por
   // eso a 125% se redimensionaba la ventana principal y cambiaban fuentes e
   // iconos). Usamos SYSTEM_AWARE (-2) para conservar la misma semántica de
   // coordenadas que tenía SetProcessDPIAware. Guardamos el contexto previo
   // para restaurarlo al final, de modo que el diálogo principal del POS que
   // se crea después siga escalado por Windows como siempre.
   // ------------------------------------------------------------------
   nPrevDpiCtx := SetThreadDpiAwarenessContext( -2 )   // -2 = SYSTEM_AWARE

   // Re-consultar monitores ya en modo aware: ahora aMonitorRect viene en
   // píxeles FÍSICOS reales del monitor secundario (a 125%, 150%, etc.).
   aMonitores  := ObtenerMonitores()
   aMonElegido := ElegirMonitor( aMonitores, hCfg, .T. )

   // FULLSCREEN en el monitor elegido: usa el MONITOR ENTERO (incluye barra
   // de tareas). aMonitorRect = {left, top, bottom, right} en píxeles reales.
   aRect := aMonElegido[ "aMonitorRect" ]

   aItemsCust := {}

   do case
   case hCfg[ "modelo" ] == "WEB"
      cModeloAct := "WEB"
      if ! ModeloWeb( aRect, hCfg )      // sin navegador o sin página: MODERNO
         DispLog( "WEB no disponible: abro MODERNO" )
         cModeloAct := "MODERNO"
         ModeloModerno( aRect, hCfg )
      endif
   case hCfg[ "modelo" ] == "MODERNO"
      cModeloAct := "MODERNO"
      ModeloModerno( aRect, hCfg )
   otherwise
      cModeloAct := "CLASICO"
      ModeloClasico( aRect, hCfg )
   endcase

   if bDatos != nil
      DispCliActualizar( Eval( bDatos ) )
   endif

   // Restaurar el DPI del hilo al estado original. El diálogo del cliente ya
   // quedó creado en modo aware (su tamaño y posición en el 2º monitor son
   // correctos); de aquí en adelante el hilo vuelve a NO-aware, para que la
   // ventana principal del POS (que se crea justo después de esta función)
   // la siga escalando Windows a 125% como siempre.
   if nPrevDpiCtx != nil .and. nPrevDpiCtx != 0
      SetThreadDpiAwarenessContext( nPrevDpiCtx )
   endif

   return .T.

//-----------------------------------------------------------------------------
function DispCliCerrar()

   if oDlgCust != nil
      oDlgCust:End()
   endif
   oDlgCust   := nil
   oVideoCust := nil

   return nil

//-----------------------------------------------------------------------------
function DispCliAbierto()
   return oDlgCust != nil

//-----------------------------------------------------------------------------
// Refresca el display con los datos de la venta. Seguro de llamar siempre.
//-----------------------------------------------------------------------------
function DispCliActualizar( hDat )

   if oDlgCust == nil .or. hDat == nil
      return nil
   endif

   if cModeloAct == "MODERNO"
      return ModernoActualizar( hDat )
   endif
   if cModeloAct == "WEB"
      return WebActualizar( hDat )
   endif

   if oBrwCust != nil
      aItemsCust := hDat[ "items" ]
      oBrwCust:SetArray( aItemsCust )
      oBrwCust:Refresh()
   endif

   if oSayTotalCust != nil
      oSayTotalCust:SetText( "$ " + Transform( hDat[ "total" ], "@E 999,999,999.99" ) )
   endif
   if oSayPagadoCust != nil
      oSayPagadoCust:SetText( "$ " + Transform( hDat[ "pagado" ], "@E 999,999,999.99" ) )
   endif
   if oSayVueltoCust != nil
      oSayVueltoCust:SetText( "$ " + Transform( hDat[ "vuelto" ], "@E 999,999,999.99" ) )
   endif

   return nil

//-----------------------------------------------------------------------------
// Configuración de esta PC (display.ini). Si el archivo no existe devuelve los
// valores por defecto (no lo crea: eso lo hace DispCliAbrir al detectar el 2do
// monitor).
//-----------------------------------------------------------------------------
function DispCliLeerIni()

   local hCfg := DefaultsIni(), oIni, cKey, cMsg, n

   hCfg[ "mensajes" ] := {}

   if File( DISP_INI )
      INI oIni FILE DISP_INI
      for each cKey in hb_HKeys( hCfg )
         if ! ( cKey == "mensajes" )
            hCfg[ cKey ] := AllTrim( oIni:Get( "display", cKey, hCfg[ cKey ] ) )
         endif
      next
      // Texto libre del cliente: un renglón por entrada msg1..msgN (los
      // vacíos se saltean, así puede borrar uno del medio sin renumerar)
      for n := 1 to MAX_MENSAJES
         cMsg := AllTrim( oIni:Get( "mensajes", "msg" + hb_ntos( n ), "" ) )
         if ! Empty( cMsg )
            AAdd( hCfg[ "mensajes" ], cMsg )
         endif
      next
   endif

   hCfg[ "modelo" ] := Upper( hCfg[ "modelo" ] )
   hCfg[ "tema" ]   := Upper( hCfg[ "tema" ] )

   return hCfg

//-----------------------------------------------------------------------------
// hCfg[ "mensajes" ] (array de renglones) es opcional: si no viene, no se tocan
// los mensajes grabados.
//-----------------------------------------------------------------------------
function DispCliGrabarIni( hCfg )

   local oIni, cKey, n, aMsg

   if ! File( DISP_INI )
      CrearIniBasico()
   endif
   INI oIni FILE DISP_INI
   for each cKey in hb_HKeys( hCfg )
      if ! ( cKey == "mensajes" )
         oIni:Set( "display", cKey, cValToChar( hCfg[ cKey ] ) )
      endif
   next
   if hb_HHasKey( hCfg, "mensajes" )
      aMsg := hCfg[ "mensajes" ]
      for n := 1 to MAX_MENSAJES
         oIni:Set( "mensajes", "msg" + hb_ntos( n ), IF( n <= Len( aMsg ), aMsg[ n ], "" ) )
      next
   endif

   return nil

//-----------------------------------------------------------------------------
// Diálogo de configuración de la segunda pantalla de ESTA PC (display.ini).
//-----------------------------------------------------------------------------
function DispCliConfig( oWnd )

   local oDlg, acor, oBot := Array( 4 ), lRta := .F., hCfg := DispCliLeerIni()
   local aModelos := { "CLASICO", "MODERNO", "WEB" }, aTemas := { "OSCURO", "CLARO" }
   local aMon := ObtenerMonitores(), aMonTxt := { "Automático (el que no es el principal)" }
   local cModelo, cTema, cMonTxt, cLogo, cVideo, nSeg, lEspera, lDebug, cMsg := "", aMsg, i, r

   for i := 1 to Len( aMon )
      r := aMon[ i ][ "aMonitorRect" ]
      AAdd( aMonTxt, hb_ntos( i ) + " - " + hb_ntos( r[ 4 ] - r[ 1 ] ) + " x " + hb_ntos( r[ 3 ] - r[ 2 ] ) + ;
                     IF( aMon[ i ][ "lPrimary" ], "  (principal)", "" ) )
   next

   cModelo := IF( AScan( aModelos, hCfg[ "modelo" ] ) > 0, hCfg[ "modelo" ], "CLASICO" )
   cTema   := IF( AScan( aTemas, hCfg[ "tema" ] ) > 0, hCfg[ "tema" ], "OSCURO" )
   i       := Val( hCfg[ "monitor" ] )
   cMonTxt := aMonTxt[ IF( i >= 1 .and. i < Len( aMonTxt ), i + 1, 1 ) ]
   cLogo   := PadR( hCfg[ "logo" ], 200 )
   cVideo  := PadR( hCfg[ "video" ], 200 )
   nSeg    := Max( 2, Val( hCfg[ "segaviso" ] ) )
   lEspera := !( Upper( hCfg[ "espera" ] ) == "N" )
   lDebug  := ( Upper( hCfg[ "debug" ] ) == "S" )
   AEval( hCfg[ "mensajes" ], { | m | cMsg += m + CRLF } )

   DEFINE DIALOG oDlg TITLE "Segunda pantalla del cliente (esta PC)" ;
      FROM 05,15 TO 32,130 ICON oApp:oIco FONT oApp:oFont OF oWnd
   acor := AcepCanc( oDlg )
   oDlg:lHelpIcon := .F.

   @ 07,05 SAY "Modelo:" OF oDlg PIXEL SIZE 70,10 RIGHT
   @ 05,80 COMBOBOX cModelo ITEMS aModelos OF oDlg PIXEL SIZE 80,60
   @ 07,200 SAY "Tema (solo WEB):" OF oDlg PIXEL SIZE 75,10 RIGHT
   @ 05,280 COMBOBOX cTema ITEMS aTemas OF oDlg PIXEL SIZE 70,40

   @ 22,05 SAY "Monitor:" OF oDlg PIXEL SIZE 70,10 RIGHT
   @ 20,80 COMBOBOX cMonTxt ITEMS aMonTxt OF oDlg PIXEL SIZE 200,60

   @ 37,05 SAY "Logo:" OF oDlg PIXEL SIZE 70,10 RIGHT
   @ 35,80 GET cLogo OF oDlg PIXEL SIZE 250,11
   @ 35,333 BUTTON oBot[3] PROMPT "..." OF oDlg PIXEL SIZE 14,11 ;
      ACTION ( cLogo := PadR( ElegirArchivo( "Imágenes (*.png;*.jpg)|*.png;*.jpg", "Logo del display", cLogo ), 200 ), oDlg:Update() )

   @ 52,05 SAY "Video:" OF oDlg PIXEL SIZE 70,10 RIGHT
   @ 50,80 GET cVideo OF oDlg PIXEL SIZE 250,11
   @ 50,333 BUTTON oBot[4] PROMPT "..." OF oDlg PIXEL SIZE 14,11 ;
      ACTION ( cVideo := PadR( ElegirArchivo( "Videos (*.mp4)|*.mp4", "Video del display", cVideo ), 200 ), oDlg:Update() )

   @ 67,05 SAY "Seg. cartel oferta:" OF oDlg PIXEL SIZE 70,10 RIGHT
   @ 65,80 GET nSeg OF oDlg PIXEL SIZE 20,11 PICTURE "99" VALID nSeg >= 2
   @ 66,120 CHECKBOX lEspera PROMPT "Pantalla de espera con ofertas y mensajes" OF oDlg PIXEL SIZE 170,10
   @ 66,300 CHECKBOX lDebug PROMPT "Diagnóstico (display.log)" OF oDlg PIXEL SIZE 110,10

   @ 82,05 SAY "Mensajes para el cliente (uno por renglón, hasta " + hb_ntos( MAX_MENSAJES ) + "). " + ;
               "Se ven en la pantalla de espera y pasan abajo en el modelo WEB:" OF oDlg PIXEL SIZE 435,10
   @ 95,05 GET cMsg MEMO OF oDlg PIXEL SIZE 435,60

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg SIZE 30,12 PIXEL ;
      ACTION ( lRta := .T., oDlg:End() )
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,12 PIXEL CANCEL ;
      ACTION ( lRta := .F., oDlg:End() )

   ACTIVATE DIALOG oDlg CENTER

   if ! lRta
      return .F.
   endif

   // mensajes: uno por renglón, sin vacíos, hasta MAX_MENSAJES
   aMsg := {}
   for each i in hb_ATokens( StrTran( cMsg, Chr( 13 ), "" ), Chr( 10 ) )
      if ! Empty( i ) .and. Len( aMsg ) < MAX_MENSAJES
         AAdd( aMsg, AllTrim( i ) )
      endif
   next

   hCfg[ "modelo" ]   := cModelo
   hCfg[ "tema" ]     := cTema
   i                  := AScan( aMonTxt, cMonTxt )
   hCfg[ "monitor" ]  := IF( i > 1, hb_ntos( i - 1 ), "" )
   hCfg[ "logo" ]     := AllTrim( cLogo )
   hCfg[ "video" ]    := AllTrim( cVideo )
   hCfg[ "segaviso" ] := hb_ntos( nSeg )
   hCfg[ "espera" ]   := IF( lEspera, "S", "N" )
   hCfg[ "debug" ]    := IF( lDebug, "S", "N" )
   hCfg[ "mensajes" ] := aMsg
   DispCliGrabarIni( hCfg )

   // si el display está abierto, se reabre para que tome la configuración nueva
   if DispCliAbierto()
      DispCliCerrar()
      DispCliAbrir( lForzarAbrir, bDatosAbrir )
   endif

   MsgInfo( "La configuración de la segunda pantalla se grabó correctamente.", "Aviso" )

   return .T.

// cGetFile que, si se cancela, deja el valor que había
static function ElegirArchivo( cMascara, cTitulo, cActual )

   local cFile := cGetFile( cMascara, cTitulo )

   return IF( Empty( cFile ), AllTrim( cActual ), cFile )

//-----------------------------------------------------------------------------
static function DefaultsIni()

   local hCfg := { => }

   hb_HCaseMatch( hCfg, .F. )
   hCfg[ "modelo" ]   := "CLASICO"   // CLASICO / MODERNO / WEB
   hCfg[ "tema" ]     := "OSCURO"    // modelo WEB: OSCURO / CLARO
   hCfg[ "logo" ]     := ""          // vacío = logo_cliente.png/.jpg del sistema
   hCfg[ "video" ]    := ""          // vacío = video.mp4 del sistema
   hCfg[ "espera" ]   := "S"         // pantalla de espera con las ofertas vigentes
   hCfg[ "segaviso" ] := "6"         // segundos que dura el cartel de oferta
   hCfg[ "html" ]     := ".\display\cliente.html"   // página del modelo WEB
   hCfg[ "monitor" ]  := ""          // vacío = el que no es el principal; o 1, 2, ...
   hCfg[ "debug" ]    := "N"         // S = diagnóstico en .\display.log

   return hCfg

//-----------------------------------------------------------------------------
static function CrearIniBasico()

   local hCfg := DefaultsIni(), cKey
   local cTxt := "; Display del cliente (segunda pantalla) - configuracion de ESTA PC" + CRLF + ;
                 "; modelo: CLASICO / MODERNO / WEB   tema (WEB): OSCURO / CLARO" + CRLF + ;
                 "; logo/video: ruta del archivo (vacio = los del sistema)" + CRLF + ;
                 "; espera: S/N pantalla de espera con ofertas   segaviso: segundos del cartel de oferta" + CRLF + ;
                 "; monitor: vacio = el que no es el principal; o el numero (1, 2...) si hay que forzarlo" + CRLF + ;
                 "[display]" + CRLF

   for each cKey in hb_HKeys( hCfg )
      cTxt += cKey + "=" + hCfg[ cKey ] + CRLF
   next
   cTxt += CRLF + ;
           "; Textos que se muestran en la pantalla de espera y pasan en la marquesina" + CRLF + ;
           "; del modelo WEB. Un renglon por linea: msg1, msg2, ... (hasta msg" + hb_ntos( MAX_MENSAJES ) + ")." + CRLF + ;
           "; Ejemplo:" + CRLF + ;
           ";   msg1=Lunes y Viernes 20% de descuento con Cuenta DNI" + CRLF + ;
           ";   msg2=Envios a domicilio sin cargo en compras mayores a $ 30.000" + CRLF + ;
           "[mensajes]" + CRLF + ;
           "msg1=" + CRLF
   MemoWrit( DISP_INI, cTxt )

   return nil

//-----------------------------------------------------------------------------
// Logo y video: los del ini o, si están vacíos, los de siempre del sistema.
//-----------------------------------------------------------------------------
static function ArchivoLogo( hCfg )

   local cLogo := hCfg[ "logo" ]

   if Empty( cLogo ) .or. ! File( cLogo )
      cLogo := IF( File( ".\logo_cliente.png" ), ".\logo_cliente.png", "C:\fwh16\general\logo_cliente.png" )
      if File( ".\logo_cliente.jpg" )
         cLogo := ".\logo_cliente.jpg"
      endif
   endif

   return cLogo

static function ArchivoVideo( hCfg )

   local cVideo := hCfg[ "video" ]

   if Empty( cVideo ) .or. ! File( cVideo )
      cVideo := IF( File( ".\video.mp4" ), ".\video.mp4", "C:\fwh16\general\video.mp4" )
   endif

   return cVideo

//=============================================================================
// MODELO CLASICO: el display original (navy + naranja, logo, video, browse y
// cards de TOTAL / PAGADO / VUELTO).
//=============================================================================
static function ModeloClasico( aRect, hCfg )

   local oImg
   local nLeft, nTop, nWidth, nHeight
   local nBrwY, nBrwH, nBrwX, nBrwW
   local nLogoX, nLogoY, nLogoW, nLogoH
   local nVideoX, nVideoY, nVideoW, nVideoH
   local nWCard, nXCardP
   local nYCard, nYCardVal, nYVue, nYVueVal
   local nHCardLbl, nHCardVal, nHTotLbl, nHTotVal
   local cLogo, cVideo
   local nSX, nSY, nSF        // factores de escala (X, Y, fuentes)

   // Colores corporativos (Siete Colinas)
   local nClrBg     := RGB(  34,  32,  54 )   // #222036 navy de marca
   local nClrAcc    := RGB( 255, 175,  34 )   // #ffaf22 naranja de marca
   local nClrFila1  := RGB( 255, 255, 255 )   // pijama oscura
   local nClrFila2  := RGB( 199, 200, 202 )   // pijama clara
   local nClrEncab  := RGB(  70,  68, 102 )   // encabezado browse
   local oFontBrw, oFontBrwH, oFontLbl, oFontVal, oFontTotLbl, oFontTot

   nWidth  := aRect[ 4 ] - aRect[ 1 ]   // 100% ancho
   nHeight := aRect[ 3 ] - aRect[ 2 ]   // 100% alto
   nLeft   := aRect[ 1 ]                // pegado al borde izquierdo del monitor
   nTop    := aRect[ 2 ]                // pegado al borde superior

   // Factores de escala basados en una referencia de 1180x680 (donde se ve
   // bien en la pc del usuario). Todo el layout se reescala proporcionalmente.
   nSX := nWidth  / 1180.0
   nSY := nHeight / 680.0
   nSF := Min( nSX, nSY )    // factor para fuentes (la menor para que entre)

   nBrwY     := Int( 75  * nSY )           // bajo header
   nBrwH     := Int( 215 * nSY )           // alto del browse
   nHCardLbl := Int( 22  * nSY )
   nHCardVal := Int( 38  * nSY )
   nHTotLbl  := nHCardLbl
   nHTotVal  := nHCardVal

   // Logo + video (escalados desde la referencia 1180x680)
   nLogoX  := Int(  11 * nSX )
   nLogoY  := Int(   1 * nSY )
   nLogoW  := Int( 270 * nSX )
   nLogoH  := Int(  70 * nSY )
   nVideoX := Int( 580 * nSX )
   nVideoY := nLogoY
   nVideoW := Int( 280 * nSX )
   nVideoH := Int( 140 * nSY )

   // Browse
   nBrwX := Int(  10 * nSX )
   nBrwW := Int( 420 * nSX )

   // Cards a la derecha del browse
   nXCardP := Int( 430 * nSX )
   nWCard  := Int( 160 * nSX )

   nYCard    := Int(  75 * nSY )           // PAGADO
   nYCardVal := nYCard + nHCardLbl
   nYVue     := Int( 140 * nSY )           // VUELTO
   nYVueVal  := nYVue + nHCardLbl

   // Fuentes ESCALADAS con nSF para que crezcan/disminuyan con el monitor.
   DEFINE FONT oFontBrwH   NAME "Montserrat" SIZE 0, -Int( 17 * nSF ) BOLD
   DEFINE FONT oFontBrw    NAME "Montserrat" SIZE 0, -Int( 18 * nSF )
   DEFINE FONT oFontLbl    NAME "Montserrat" SIZE 0, -Int( 14 * nSF ) BOLD
   DEFINE FONT oFontVal    NAME "Montserrat" SIZE 0, -Int( 22 * nSF ) BOLD
   DEFINE FONT oFontTotLbl NAME "Montserrat" SIZE 0, -Int( 16 * nSF ) BOLD
   DEFINE FONT oFontTot    NAME "Montserrat" SIZE 0, -Int( 28 * nSF ) BOLD

   DEFINE BRUSH oBrushBgCust COLOR nClrBg

   DEFINE DIALOG oDlgCust ;
      TITLE "Display Cliente" ;
      SIZE nWidth, nHeight ;
      STYLE nOr( WS_POPUP, WS_VISIBLE, WS_CLIPCHILDREN ) ;
      GRADIENT { { 1, nClrBg, nClrBg } } ;
      PIXEL
   oDlgCust:lTransparent := .f.

   // ---------- HEADER: logo (izq) + video (der) ----------
   cLogo  := ArchivoLogo( hCfg )
   cVideo := ArchivoVideo( hCfg )

   if File( cLogo )
      @ nLogoY, nLogoX XIMAGE oImg OF oDlgCust ;
             FILE cLogo ;
             SIZE nLogoW, nLogoH
      oImg:lBmpTransparent := .f.
   endif

   // ---------- XBROWSE (sobre array: ya no comparte el puntero de oQryDet
   // con la grilla del cajero) ----------
   @ nBrwY, nBrwX XBROWSE oBrwCust ;
        ARRAY aItemsCust ;
        COLUMNS 1, 2, 3, 4 ;
        HEADERS "Cant.","Detalle","P. Unitario","Importe" ;
        SIZES Int(100*nSX),Int(376*nSX),Int(177*nSX),Int(177*nSX);
        OF oDlgCust ;
        SIZE nBrwW, nBrwH PIXEL

   oBrwCust:SetFont( oFontBrwH )
   oBrwCust:oHeaderFonts := oFontBrwH
   oBrwCust:l2007        := .F.
   oBrwCust:lHScroll     := .F.
   oBrwCust:lVScroll     := .F.
   oBrwCust:lFooter      := .F.
   oBrwCust:lRecordSelector := .F.
   oBrwCust:nRowHeight    := Int( 38 * nSY )
   oBrwCust:nHeaderHeight := Int( 40 * nSY )
   oBrwCust:nDataLines    := 1
   oBrwCust:nColDividerStyle  := 0
   oBrwCust:nRowDividerStyle  := 0
   oBrwCust:nHeadDividerStyle := 0
   oBrwCust:bClrHeader := { || { nClrAcc, nClrEncab } }
   oBrwCust:bClrStd    := { || IF( oBrwCust:KeyNo() % 2 == 0, ;
                                   { CLR_BLACK, nClrFila2 }, ;
                                   { CLR_BLACK, nClrFila1 } ) }
   oBrwCust:bClrSel      := oBrwCust:bClrStd
   oBrwCust:bClrSelFocus := oBrwCust:bClrStd
   oBrwCust:lFullGrid       := .T.
   oBrwCust:lFitGridHeight  := .T.
   oBrwCust:lColDividerComplete  := .t.

   oBrwCust:aCols[ 1 ]:cEditPicture := "9,999.999"
   oBrwCust:aCols[ 3 ]:cEditPicture := "@E 999,999,999.99"
   oBrwCust:aCols[ 4 ]:cEditPicture := "@E 999,999,999.99"

   oBrwCust:aCols[ 1 ]:nDataStrAlign := AL_CENTER
   oBrwCust:aCols[ 1 ]:nHeadStrAlign := AL_CENTER
   oBrwCust:aCols[ 2 ]:nDataStrAlign := AL_LEFT
   oBrwCust:aCols[ 2 ]:nHeadStrAlign := AL_LEFT
   oBrwCust:aCols[ 3 ]:nDataStrAlign := AL_RIGHT
   oBrwCust:aCols[ 3 ]:nHeadStrAlign := AL_RIGHT
   oBrwCust:aCols[ 4 ]:nDataStrAlign := AL_RIGHT
   oBrwCust:aCols[ 4 ]:nHeadStrAlign := AL_RIGHT

   oBrwCust:CreateFromCode()

   // ---------- TOTAL A PAGAR ----------
   @ nBrwH, nXCardP SAY "TOTAL A PAGAR" OF oDlgCust ;
        SIZE nWCard, nHTotLbl PIXEL FONT oFontTot ;
        COLORS nClrBg,nClrAcc BORDER CENTER
   @ nBrwH+nHTotLbl+20, nXCardP SAY oSayTotalCust PROMPT "$ 0,00" OF oDlgCust ;
        SIZE nWCard -20, nHTotVal-20 PIXEL FONT oFontTot ;
        COLORS CLR_WHITE,nClrBg RIGHT

   // ---------- PAGADO ----------
   @ nYCard-50, nXCardP SAY "PAGADO" OF oDlgCust ;
        SIZE nWCard, nHCardLbl PIXEL FONT oFontTot ;
        COLOR nClrBg,nClrAcc BORDER CENTER
   @ nYCardVal-30, nXCardP SAY oSayPagadoCust PROMPT "$ 0,00" OF oDlgCust ;
        SIZE nWCard -20, nHCardVal-20 PIXEL FONT oFontTot ;
        COLORS CLR_WHITE,nClrBg RIGHT

   // ---------- VUELTO ----------
   @ nYVue-50, nXCardP SAY "VUELTO" OF oDlgCust ;
        SIZE nWCard, nHCardLbl PIXEL FONT oFontTot ;
        COLORS nClrBg,nClrAcc BORDER CENTER
   @ nYVueVal-30, nXCardP SAY oSayVueltoCust PROMPT "$ 0,00" OF oDlgCust ;
        SIZE nWCard -20, nHCardVal-20 PIXEL FONT oFontTot ;
        COLORS CLR_WHITE,nClrBg RIGHT

   // Cerrar con ESC (27) o F11 (122) desde el propio display.
   oDlgCust:bKeyDown := { | nKey | IF( nKey == 27 .or. nKey == 122, ;
                                       oDlgCust:End(), nil ) }

   ACTIVATE DIALOG oDlgCust ;
      ON INIT ( oDlgCust:Move( nTop, nLeft, nWidth, nHeight, .T. ), ;
                CrearVideoCust( cVideo, nVideoY, nVideoX, nVideoW, nVideoH ) ) ;
      VALID   ( oVideoCust := nil, oDlgCust := nil, oBrwCust := nil, ;
                oSayTotalCust := nil, oSayPagadoCust := nil, oSayVueltoCust := nil, .T. ) ;
      NOWAIT

   return nil

//-----------------------------------------------------------------------------
// Crea el reproductor de video (WMPlayer.OCX) si el archivo existe.
// Se llama desde ON INIT del diálogo del cliente.
//-----------------------------------------------------------------------------
static function CrearVideoCust( cVideo, nTop, nLeft, nWidth, nHeight )

   if oDlgCust == nil .or. ! File( cVideo )
      return nil
   endif

   BEGIN SEQUENCE
      oVideoCust := TActiveX():New( oDlgCust, "WMPlayer.OCX" )
      oVideoCust:Move( nTop, nLeft, nWidth, nHeight, .T. )
      oVideoCust:Settings:Volume   := 0      // mudo (es ambiente, no concurso con cajero)
      oVideoCust:Settings:SetMode( "loop", .T. )
      oVideoCust:uiMode := "none"
      oVideoCust:url    := cVideo
   RECOVER
      oVideoCust := nil
   END SEQUENCE

   return nil

//=============================================================================
// OFERTAS VIGENTES (promos por artículo + promos por grupo), respetando fecha
// y franja horaria. Las usan todos los modelos.
//=============================================================================

//-----------------------------------------------------------------------------
// .T. si el artículo participa de alguna promo vigente. Usa un cache de 60 s
// para no consultar la base con cada artículo que se carga.
//-----------------------------------------------------------------------------
function DispCliEnOferta( nCodArt )

   if ValType( nCodArt ) != "N" .or. nCodArt <= 0
      return .F.
   endif

   return hb_HHasKey( OfertasSet(), Int( nCodArt ) )

//-----------------------------------------------------------------------------
// Texto del cartel de oferta para un artículo ("" si no tiene ninguna).
// Ej: "Llevando 2 pagás 1" / "Mix sabores: Llevando 10 combinables: $ 1.000 c/u"
//-----------------------------------------------------------------------------
function DispCliTextoOferta( nCodArt )

   local oQ, cTxt := "", cId := oApp:cId

   if ValType( nCodArt ) != "N" .or. nCodArt <= 0
      return ""
   endif
   ChequeoTablas()

   if lTabArt
      oQ := oApp:oServer:Query( "SELECT " + SqlDescArt( "p" ) + " AS t " + ;
            "FROM ge_" + cId + "promociones p " + ;
            "WHERE p.codart = " + ClipValue2Sql( nCodArt ) + " AND " + SqlVigencia( "p", lHoraArt ) + ;
            " ORDER BY p.tipo, p.id" )
      do while ! oQ:Eof()
         cTxt += SumaTexto( cTxt, oQ:t )
         oQ:Skip()
      enddo
   endif

   if lTabGrp
      oQ := oApp:oServer:Query( "SELECT DISTINCT g.id, CONCAT( g.nompromo, ': ', " + SqlDescGrp( "g" ) + " ) AS t " + ;
            "FROM ge_" + cId + "promo_grupo g " + ;
            "JOIN ge_" + cId + "promo_grupo_det d ON d.grupo_id = g.id " + ;
            "WHERE d.codart = " + ClipValue2Sql( nCodArt ) + " AND " + SqlVigencia( "g", .T. ) + ;
            " ORDER BY g.id" )
      do while ! oQ:Eof()
         cTxt += SumaTexto( cTxt, oQ:t )
         oQ:Skip()
      enddo
   endif

   return cTxt

static function SumaTexto( cTxt, uNuevo )

   local cNuevo := AllTrim( IF( ValType( uNuevo ) == "C", uNuevo, "" ) )

   if Empty( cNuevo )
      return ""
   endif

   return IF( Empty( cTxt ), "", "  +  " ) + cNuevo

//-----------------------------------------------------------------------------
// Lista de ofertas vigentes para la pantalla de espera: { { cNombre, cTexto } }.
// Cache de 5 minutos (cambia con la franja horaria).
//-----------------------------------------------------------------------------
function DispCliOfertas()

   local oQ, cId := oApp:cId

   if aOfLista != nil .and. cOfId == cId .and. hb_MilliSeconds() - nOfListaT < 300000
      return aOfLista
   endif

   aOfLista := {}
   ChequeoTablas()

   if lTabGrp
      oQ := oApp:oServer:Query( "SELECT g.nompromo AS n, " + SqlDescGrp( "g" ) + " AS t " + ;
            "FROM ge_" + cId + "promo_grupo g " + ;
            "WHERE " + SqlVigencia( "g", .T. ) + " ORDER BY g.id DESC LIMIT 15" )
      do while ! oQ:Eof()
         AAdd( aOfLista, { Capitaliza( oQ:n ), AllTrim( cValToChar( oQ:t ) ) } )
         oQ:Skip()
      enddo
   endif

   if lTabArt
      oQ := oApp:oServer:Query( "SELECT a.nombre AS n, " + SqlDescArt( "p" ) + " AS t " + ;
            "FROM ge_" + cId + "promociones p " + ;
            "JOIN ge_" + cId + "articu a ON a.codigo = p.codart " + ;
            "WHERE " + SqlVigencia( "p", lHoraArt ) + " ORDER BY p.id DESC LIMIT 30" )
      do while ! oQ:Eof()
         AAdd( aOfLista, { Capitaliza( oQ:n ), AllTrim( cValToChar( oQ:t ) ) } )
         oQ:Skip()
      enddo
   endif

   nOfListaT := hb_MilliSeconds()
   cOfId     := cId

   return aOfLista

//-----------------------------------------------------------------------------
// Conjunto { codart => .T. } de artículos con promo vigente (cache 60 s).
// Va sin la tabla temporal del detalle: MySQL no deja usar una TEMPORARY dos
// veces en la misma consulta, y así sirve igual para FACT, VENTAS, etc.
//-----------------------------------------------------------------------------
static function OfertasSet()

   local oQ, cSql := "", cId := oApp:cId

   if hOfSet != nil .and. cOfId == cId .and. hb_MilliSeconds() - nOfSetT < 60000
      return hOfSet
   endif

   hOfSet := { => }
   ChequeoTablas()

   if lTabArt
      cSql := "SELECT p.codart FROM ge_" + cId + "promociones p WHERE " + SqlVigencia( "p", lHoraArt )
   endif
   if lTabGrp
      cSql += IF( Empty( cSql ), "", " UNION " ) + ;
              "SELECT d.codart FROM ge_" + cId + "promo_grupo_det d " + ;
              "JOIN ge_" + cId + "promo_grupo g ON g.id = d.grupo_id WHERE " + SqlVigencia( "g", .T. )
   endif

   if ! Empty( cSql )
      oQ := oApp:oServer:Query( cSql )
      do while ! oQ:Eof()
         hOfSet[ Int( oQ:codart ) ] := .T.
         oQ:Skip()
      enddo
   endif

   nOfSetT := hb_MilliSeconds()
   cOfId   := cId

   return hOfSet

//-----------------------------------------------------------------------------
// Qué tablas de promos existen (pueden no existir si nunca se entró a los ABM)
// y si promociones ya tiene la franja horaria. Una vez por empresa.
//-----------------------------------------------------------------------------
static function ChequeoTablas()

   local cId := oApp:cId

   if cTabId == cId
      return nil
   endif

   lTabArt  := oApp:oServer:TableExist( "ge_" + cId + "promociones" )
   lTabGrp  := oApp:oServer:TableExist( "ge_" + cId + "promo_grupo" ) .and. ;
               oApp:oServer:TableExist( "ge_" + cId + "promo_grupo_det" )
   lHoraArt := lTabArt .and. ;
               oApp:oServer:Query( "SHOW COLUMNS FROM ge_" + cId + "promociones LIKE 'hora_inicio'" ):nRecCount > 0
   cTabId   := cId

   return nil

//-----------------------------------------------------------------------------
// Fragmentos SQL
//-----------------------------------------------------------------------------
static function SqlVigencia( cA, lHora )

   return "(" + cA + ".fecha_inicio IS NULL OR " + cA + ".fecha_inicio <= CURDATE()) AND " + ;
          "(" + cA + ".fecha_fin IS NULL OR " + cA + ".fecha_fin >= CURDATE())" + ;
          IF( lHora, " AND CURTIME() BETWEEN " + cA + ".hora_inicio AND " + cA + ".hora_fin", "" )

// Importe con formato argentino y sin ",00": 4990 -> "4.990", 1250.5 -> "1.250,50"
static function SqlPlata( c )

   return "REPLACE(REPLACE(REPLACE(REPLACE(FORMAT(" + c + ",2),',','#'),'.',','),'#','.'),',00','')"

// Cantidad sin decimales de más: 10 -> "10", 0.5 -> "0,5"
static function SqlCant( c )

   return "IF(" + c + " = FLOOR(" + c + "), CAST(FLOOR(" + c + ") AS CHAR), " + ;
          "REPLACE(TRIM(TRAILING '0' FROM CAST(" + c + " AS CHAR)),'.',','))"

// Descripción de una promo por artículo (tipos 1 a 5 de promos.prg)
static function SqlDescArt( p )

   return "CASE " + p + ".tipo " + ;
          "WHEN 1 THEN CONCAT('Precio especial $ ', " + SqlPlata( p + ".precio_especial" ) + ") " + ;
          "WHEN 2 THEN CONCAT('Llevando ', " + SqlCant( p + ".cantidad_requerida" ) + ", ' pagás ', " + SqlCant( p + ".cantidad_a_pagar" ) + ") " + ;
          "WHEN 3 THEN CONCAT('La ', " + SqlCant( p + ".descuento_a_unidad" ) + ", 'º unidad con ', " + SqlCant( p + ".descuento_porcentual" ) + ", '% de descuento') " + ;
          "WHEN 4 THEN CONCAT('Llevando de ', " + SqlCant( p + ".cantidad_minima" ) + ", ' a ', " + SqlCant( p + ".cantidad_maxima" ) + ", ': $ ', " + SqlPlata( p + ".precio_unitario" ) + ", ' c/u') " + ;
          "WHEN 5 THEN CONCAT('Llevando ', " + SqlCant( p + ".cantidad_minima" ) + ", ': $ ', " + SqlPlata( p + ".precio_unitario" ) + ", ' c/u') " + ;
          "ELSE '' END"

// Descripción de una promo por grupo (Mix = mismo_grupo, o Cruzada A -> Z)
static function SqlDescGrp( g )

   local cBenef := "IF(" + g + ".tipo_benef = 1, CONCAT(' a $ ', " + SqlPlata( g + ".precio_unitario" ) + ", ' c/u'), " + ;
                   "CONCAT(' con ', " + SqlCant( g + ".porcentaje" ) + ", '% de descuento'))"

   return "IF(" + g + ".mismo_grupo = 1, " + ;
          "CONCAT('Llevando ', " + g + ".cant_a, ' combinables', " + cBenef + "), " + ;
          "CONCAT('Llevando ', " + g + ".cant_a, ', ', " + g + ".cant_z, " + cBenef + "))"

// "YERBA MATE 1 KG" -> "Yerba Mate 1 Kg"
static function Capitaliza( uTxt )

   local cTxt := Lower( AllTrim( cValToChar( uTxt ) ) ), cRes := "", i, lIni := .T., c

   for i := 1 to Len( cTxt )
      c := SubStr( cTxt, i, 1 )
      cRes += IF( lIni, Upper( c ), c )
      lIni := ( c == " " )
   next

   return cRes

//=============================================================================
// MODELO MODERNO: nativo FWH, sin navegador. Fondo oscuro, tarjetas planas,
// total grande, etiqueta OFERTA en la grilla, cartel de oferta titilante,
// pantalla de espera (ofertas + mensajes del ini) y "Gracias" al cobrar.
// Todo en píxeles reales (TRUEPIXEL) como fracción del monitor, así escala
// igual en cualquier resolución.
//=============================================================================
#define MC_FONDO    RGB(  12,  14,  28 )
#define MC_CARD     RGB(  28,  32,  56 )
#define MC_CARD2    RGB(  40,  44,  78 )
#define MC_FILA1    RGB(  22,  25,  45 )
#define MC_FILA2    RGB(  28,  32,  55 )
#define MC_FILAOF   RGB(  64,  49,  20 )   // fila en oferta: amarillo BCN apagado
#define MC_FILAPR   RGB(  14,  52,  42 )
#define MC_NARANJA  RGB( 255, 175,  34 )
#define MC_AMARILLO  RGB( 255, 175,  34 )   // #FFAF22 amarillo BCN (acento de ofertas)
#define MC_AMARILLO2 RGB( 255, 208, 120 )   // titileo del cartel
#define MC_VERDE    RGB(  63, 240, 166 )
#define MC_TEXTO    RGB( 238, 240, 255 )
#define MC_TENUE    RGB( 150, 156, 190 )

static function ModeloModerno( aRect, hCfg )

   local nW := aRect[ 4 ] - aRect[ 1 ], nH := aRect[ 3 ] - aRect[ 2 ]
   local nLeft := aRect[ 1 ], nTop := aRect[ 2 ]
   local nP, nHead, nFootY, nFootH, nBY, nBH, nXL, nWL, nXR, nWR, nY, nY2, nH2, nBrwY, nBrwH, nBanH, nPR
   local oImg, cLogo, cVideo, aF, nWEsp
   local oFHora, oFFecha, oFLbl, oFTotal, oFChip, oFBrw, oFBadge, oFBan1, oFBan2
   local oFOfN, oFOfT, oFPagV, oFVue, oFHola, oFSub, oFSlN, oFSlT, oFGr1, oFGr2, oFPie
   local oSay, oCol

   hMod := { => }
   hb_HCaseMatch( hMod, .F. )
   hMod[ "items" ]        := {}
   hMod[ "pagado" ]       := 0
   hMod[ "vuelto" ]       := 0
   hMod[ "avisoId" ]      := 0
   hMod[ "avisoHasta" ]   := 0
   hMod[ "blinkT" ]       := 0
   hMod[ "blink" ]        := .F.
   hMod[ "graciasHasta" ] := 0
   hMod[ "rotT" ]         := 0
   hMod[ "rot" ]          := 0
   hMod[ "hora" ]         := ""
   hMod[ "espera" ]       := ( Upper( hCfg[ "espera" ] ) != "N" )
   hMod[ "segaviso" ]     := Max( 2, Val( hCfg[ "segaviso" ] ) )
   hMod[ "mensajes" ]     := hCfg[ "mensajes" ]
   hMod[ "debug" ]        := ( Upper( hCfg[ "debug" ] ) == "S" )
   hMod[ "ticks" ]        := { => }
   DispLog( "abre MODERNO " + hb_ntos( nW ) + "x" + hb_ntos( nH ) )
   hMod[ "ofertas" ]      := DispCliOfertas()
   hMod[ "gVenta" ]       := {}
   hMod[ "gOferta" ]      := {}
   hMod[ "gPago" ]        := {}
   hMod[ "gEspera" ]      := {}
   hMod[ "gGracias" ]     := {}
   hMod[ "gCartel" ]      := {}
   hMod[ "gPie" ]         := {}

   // ---------- grilla de medidas (fracciones del monitor) ----------
   nP     := Int( nW * 0.025 )
   nHead  := Int( nH * 0.12 )
   nFootH := Int( nH * 0.055 )
   nFootY := nH - nFootH - Int( nH * 0.02 )
   nBY    := nHead
   nBH    := nFootY - nBY - Int( nH * 0.025 )
   nXL    := nP
   nWL    := Int( nW * 0.58 )
   nXR    := nXL + nWL + nP
   nWR    := nW - nXR - nP

   // ---------- fuentes (alto en píxeles, proporcional al monitor) ----------
   DEFINE FONT oFHora  NAME "Segoe UI Light" SIZE 0, -Int( nH * 0.060 )
   DEFINE FONT oFFecha NAME "Segoe UI"       SIZE 0, -Int( nH * 0.026 )
   DEFINE FONT oFLbl   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.026 ) BOLD
   DEFINE FONT oFTotal NAME "Segoe UI"       SIZE 0, -Int( nH * 0.105 ) BOLD
   DEFINE FONT oFChip  NAME "Segoe UI"       SIZE 0, -Int( nH * 0.028 ) BOLD
   DEFINE FONT oFBrw   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.036 ) BOLD
   DEFINE FONT oFBadge NAME "Segoe UI"       SIZE 0, -Int( nH * 0.024 ) BOLD
   DEFINE FONT oFBan1  NAME "Segoe UI"       SIZE 0, -Int( nH * 0.034 ) BOLD
   DEFINE FONT oFBan2  NAME "Segoe UI"       SIZE 0, -Int( nH * 0.046 ) BOLD
   DEFINE FONT oFOfN   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.045 ) BOLD
   DEFINE FONT oFOfT   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.032 ) BOLD
   DEFINE FONT oFPagV  NAME "Segoe UI"       SIZE 0, -Int( nH * 0.048 ) BOLD
   DEFINE FONT oFVue   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.072 ) BOLD
   DEFINE FONT oFHola  NAME "Segoe UI Black" SIZE 0, -Int( nH * 0.115 )
   DEFINE FONT oFSub   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.034 )
   DEFINE FONT oFSlN   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.062 ) BOLD
   DEFINE FONT oFSlT   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.040 ) BOLD
   DEFINE FONT oFGr1   NAME "Segoe UI Black" SIZE 0, -Int( nH * 0.100 )
   DEFINE FONT oFGr2   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.062 ) BOLD
   DEFINE FONT oFPie   NAME "Segoe UI"       SIZE 0, -Int( nH * 0.028 ) BOLD
   aF := { oFHora, oFFecha, oFLbl, oFTotal, oFChip, oFBrw, oFBadge, oFBan1, oFBan2, oFOfN, oFOfT, ;
           oFPagV, oFVue, oFHola, oFSub, oFSlN, oFSlT, oFGr1, oFGr2, oFPie }
   // Importes grandes: cada uno tiene fuentes más chicas de repuesto y se
   // usa la primera en la que el número entra (ver AjustaImporte)
   hMod[ "fTotal" ] := { oFTotal, TFont():New( "Segoe UI", 0, -Int( nH * 0.085 ), , .T. ), ;
                                  TFont():New( "Segoe UI", 0, -Int( nH * 0.068 ), , .T. ) }
   hMod[ "fPag" ]   := { oFPagV, TFont():New( "Segoe UI", 0, -Int( nH * 0.040 ), , .T. ) }
   hMod[ "fVue" ]   := { oFVue, TFont():New( "Segoe UI", 0, -Int( nH * 0.058 ), , .T. ), ;
                                TFont():New( "Segoe UI", 0, -Int( nH * 0.046 ), , .T. ) }
   AEval( hMod[ "fTotal" ], { | o | AAdd( aF, o ) }, 2 )
   AEval( hMod[ "fPag" ],   { | o | AAdd( aF, o ) }, 2 )
   AEval( hMod[ "fVue" ],   { | o | AAdd( aF, o ) }, 2 )
   hMod[ "fuentes" ] := aF

   DEFINE DIALOG oDlgCust ;
      TITLE "Display Cliente" ;
      SIZE nW, nH ;
      STYLE nOr( WS_POPUP, WS_VISIBLE, WS_CLIPCHILDREN ) ;
      COLOR MC_TEXTO, MC_FONDO ;
      GRADIENT { { 1, MC_FONDO, MC_FONDO } } ;   // pisa el SetDlgGradient global de bcn.prg
      PIXEL TRUEPIXEL
   oDlgCust:lTransparent := .F.

   // ---------- HEADER: logo + reloj ----------
   cLogo := ArchivoLogo( hCfg )
   if File( cLogo )
      @ Int( nH * 0.018 ), nP XIMAGE oImg OF oDlgCust FILE cLogo SIZE Int( nW * 0.22 ), Int( nH * 0.085 )
      oImg:lBmpTransparent := .F.
      oImg:SetColor( MC_TEXTO, MC_FONDO )     // sin franjas blancas al ajustar el logo
   endif
   @ Int( nH * 0.012 ), nW - nP - Int( nW * 0.3 ) SAY oSay PROMPT Left( Time(), 5 ) OF oDlgCust ;
     SIZE Int( nW * 0.3 ), Int( nH * 0.068 ) PIXEL FONT oFHora COLORS MC_TEXTO, MC_FONDO RIGHT
   hMod[ "oHora" ] := oSay
   @ Int( nH * 0.078 ), nW - nP - Int( nW * 0.3 ) SAY oSay PROMPT FechaLarga( Date() ) OF oDlgCust ;
     SIZE Int( nW * 0.3 ), Int( nH * 0.035 ) PIXEL FONT oFFecha COLORS MC_TENUE, MC_FONDO RIGHT
   hMod[ "oFecha" ] := oSay

   // ---------- VENTA: lista (izquierda) ----------
   @ nBY, nXL SAY oSay PROMPT "SU COMPRA" OF oDlgCust ;
     SIZE nWL, Int( nH * 0.045 ) PIXEL FONT oFLbl COLORS MC_NARANJA, MC_FONDO
   hMod[ "oTitulo" ] := oSay
   AAdd( hMod[ "gVenta" ], oSay )

   nBrwY := nBY + Int( nH * 0.05 )
   nBrwH := nBY + nBH - nBrwY
   @ nBrwY, nXL XBROWSE oBrwCust ;
        ARRAY aItemsCust ;
        COLUMNS 1, 2, 6, 4 ;
        OF oDlgCust ;
        SIZE nWL, nBrwH PIXEL NOBORDER

   oBrwCust:SetFont( oFBrw )
   oBrwCust:SetColor( MC_TEXTO, MC_FONDO )
   oBrwCust:lHeader          := .F.
   oBrwCust:lFooter          := .F.
   oBrwCust:lHScroll         := .F.
   oBrwCust:lVScroll         := .F.
   oBrwCust:lRecordSelector  := .F.
   oBrwCust:l2007            := .F.
   oBrwCust:nMarqueeStyle    := MARQSTYLE_NOMARQUEE
   oBrwCust:nColDividerStyle := LINESTYLE_NOLINES
   oBrwCust:nRowDividerStyle := LINESTYLE_NOLINES
   oBrwCust:nRowHeight       := Int( nH * 0.082 )
   oBrwCust:nDataLines       := 1
   oBrwCust:bClrStd          := { || ColorFila() }
   oBrwCust:bClrSel          := oBrwCust:bClrStd
   oBrwCust:bClrSelFocus     := oBrwCust:bClrStd

   oCol := oBrwCust:aCols[ 1 ]              // cantidad ("%" en las líneas de promo)
   oCol:nWidth        := Int( nWL * 0.10 )
   oCol:bStrData      := { || FmtCant( FilaCust() ) }
   oCol:cEditPicture  := nil
   oCol:nDataStrAlign := AL_CENTER
   oCol:bClrStd       := { || { IF( FilaCust()[ 5 ], MC_VERDE, MC_NARANJA ), ColorFila()[ 2 ] } }

   oCol := oBrwCust:aCols[ 2 ]              // detalle
   oCol:nWidth        := Int( nWL * 0.49 )
   oCol:bStrData      := { || " " + AllTrim( cValToChar( FilaCust()[ 2 ] ) ) }

   oCol := oBrwCust:aCols[ 3 ]              // etiqueta OFERTA
   oCol:nWidth        := Int( nWL * 0.13 )
   oCol:bStrData      := { || IF( FilaCust()[ 6 ] .and. ! FilaCust()[ 5 ], "OFERTA", "" ) }
   oCol:cEditPicture  := nil
   oCol:nDataStrAlign := AL_CENTER
   oCol:oDataFont     := oFBadge
   oCol:bClrStd       := { || IF( FilaCust()[ 6 ] .and. ! FilaCust()[ 5 ], { MC_FONDO, MC_AMARILLO }, ColorFila() ) }

   oCol := oBrwCust:aCols[ 4 ]              // importe
   oCol:nWidth        := nWL - Int( nWL * 0.10 ) - Int( nWL * 0.49 ) - Int( nWL * 0.13 ) - 4
   oCol:bStrData      := { || StrTran( FmtPlata( FilaCust()[ 4 ] ), "$" + Chr( 160 ), "" ) + "  " }   // sin "$": xBrowse lo separa del numero
   oCol:cEditPicture  := nil
   oCol:nDataStrAlign := AL_RIGHT

   AEval( oBrwCust:aCols, { | c | c:bClrSel := c:bClrStd, c:bClrSelFocus := c:bClrStd } )
   oBrwCust:nStyle := nOr( oBrwCust:nStyle, WS_CLIPSIBLINGS )   // que no pise el cartel
   oBrwCust:CreateFromCode()
   AAdd( hMod[ "gVenta" ], oBrwCust )

   // ---------- CARTEL DE OFERTA (sobre la parte baja de la lista) ----------
   // Tres SAYs de una línea (un SAY con CRLF no dibuja la segunda línea).
   nBanH := Int( nH * 0.26 )
   nY    := nBY + nBH - nBanH
   @ nY, nXL SAY oSay PROMPT "*  ¡ESTE PRODUCTO ESTÁ EN OFERTA!  *" OF oDlgCust ;
     SIZE nWL, Int( nBanH * 0.30 ) PIXEL FONT oFBan1 COLORS MC_FONDO, MC_AMARILLO CENTER
   hMod[ "oBan1" ] := oSay
   AAdd( hMod[ "gCartel" ], oSay )
   @ nY + Int( nBanH * 0.30 ), nXL SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWL, Int( nBanH * 0.34 ) PIXEL FONT oFBan2 COLORS MC_FONDO, MC_AMARILLO CENTER
   hMod[ "oBan2" ] := oSay
   AAdd( hMod[ "gCartel" ], oSay )
   @ nY + Int( nBanH * 0.64 ), nXL SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWL, nBanH - Int( nBanH * 0.64 ) PIXEL FONT oFBan1 COLORS MC_FONDO, MC_AMARILLO CENTER
   hMod[ "oBan3" ] := oSay
   AAdd( hMod[ "gCartel" ], oSay )

   // ---------- VENTA: tarjeta TOTAL (derecha) ----------
   // Los importes van alineados a la derecha con un margen (nPR) que es otro
   // SAY vacío del color de la tarjeta (DrawText ignora los espacios finales).
   nPR := Int( nWR * 0.05 )
   nY  := nBY
   @ nY, nXR SAY oSay PROMPT "   TOTAL A PAGAR" OF oDlgCust ;
     SIZE nWR, Int( nH * 0.065 ) PIXEL FONT oFLbl COLORS MC_NARANJA, MC_CARD2
   AAdd( hMod[ "gVenta" ], oSay )
   nY += Int( nH * 0.065 )
   @ nY, nXR SAY oSay PROMPT "$ 0,00" OF oDlgCust ;
     SIZE nWR - nPR, Int( nH * 0.135 ) PIXEL FONT oFTotal COLORS CLR_WHITE, MC_CARD2 RIGHT
   hMod[ "oTotal" ] := oSay
   AAdd( hMod[ "gVenta" ], oSay )
   Relleno( nY, nXR + nWR - nPR, nPR, Int( nH * 0.135 ), MC_CARD2, hMod[ "gVenta" ] )
   nY += Int( nH * 0.135 )
   @ nY, nXR SAY oSay PROMPT "" OF oDlgCust ;
     SIZE Int( nWR * 0.42 ), Int( nH * 0.06 ) PIXEL FONT oFChip COLORS MC_TENUE, MC_CARD2
   hMod[ "oCnt" ] := oSay
   AAdd( hMod[ "gVenta" ], oSay )
   @ nY, nXR + Int( nWR * 0.42 ) SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWR - Int( nWR * 0.42 ) - nPR, Int( nH * 0.06 ) PIXEL FONT oFChip COLORS MC_VERDE, MC_CARD2 RIGHT
   hMod[ "oAhorro" ] := oSay
   AAdd( hMod[ "gVenta" ], oSay )
   Relleno( nY, nXR + nWR - nPR, nPR, Int( nH * 0.06 ), MC_CARD2, hMod[ "gVenta" ] )

   // ---------- slot inferior derecho: OFERTAS DE HOY o PAGO ----------
   nY2 := nY + Int( nH * 0.06 ) + Int( nH * 0.025 )
   nH2 := nBY + nBH - nY2

   @ nY2, nXR SAY oSay PROMPT "   * OFERTAS DE HOY" OF oDlgCust ;
     SIZE nWR, Int( nH * 0.08 ) PIXEL FONT oFLbl COLORS MC_NARANJA, MC_CARD
   AAdd( hMod[ "gOferta" ], oSay )
   @ nY2 + Int( nH * 0.08 ), nXR SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWR, Int( nH * 0.08 ) PIXEL FONT oFOfN COLORS CLR_WHITE, MC_CARD
   hMod[ "oOfN" ] := oSay
   AAdd( hMod[ "gOferta" ], oSay )
   @ nY2 + Int( nH * 0.16 ), nXR SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWR, nH2 - Int( nH * 0.16 ) PIXEL FONT oFOfT COLORS MC_AMARILLO, MC_CARD
   hMod[ "oOfT" ] := oSay
   AAdd( hMod[ "gOferta" ], oSay )

   @ nY2, nXR SAY oSay PROMPT "   PAGADO" OF oDlgCust ;
     SIZE Int( nWR * 0.3 ), Int( nH * 0.1 ) PIXEL FONT oFLbl COLORS MC_TENUE, MC_CARD
   AAdd( hMod[ "gPago" ], oSay )
   @ nY2, nXR + Int( nWR * 0.3 ) SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWR - Int( nWR * 0.3 ) - nPR, Int( nH * 0.1 ) PIXEL FONT oFPagV COLORS CLR_WHITE, MC_CARD RIGHT
   hMod[ "oPag" ] := oSay
   AAdd( hMod[ "gPago" ], oSay )
   Relleno( nY2, nXR + nWR - nPR, nPR, Int( nH * 0.1 ), MC_CARD, hMod[ "gPago" ] )
   @ nY2 + Int( nH * 0.1 ), nXR SAY oSay PROMPT "   SU VUELTO" OF oDlgCust ;
     SIZE Int( nWR * 0.3 ), nH2 - Int( nH * 0.1 ) PIXEL FONT oFLbl COLORS MC_TENUE, MC_CARD
   AAdd( hMod[ "gPago" ], oSay )
   @ nY2 + Int( nH * 0.1 ), nXR + Int( nWR * 0.3 ) SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWR - Int( nWR * 0.3 ) - nPR, nH2 - Int( nH * 0.1 ) PIXEL FONT oFVue COLORS MC_VERDE, MC_CARD RIGHT
   hMod[ "oVue" ] := oSay
   AAdd( hMod[ "gPago" ], oSay )
   Relleno( nY2 + Int( nH * 0.1 ), nXR + nWR - nPR, nPR, nH2 - Int( nH * 0.1 ), MC_CARD, hMod[ "gPago" ] )

   // ---------- ESPERA (sin venta): bienvenida + ofertas/mensajes rotando ----------
   // Sin video el texto usa todo el ancho; el renglón principal tiene alto
   // para 3 líneas (los mensajes del ini pueden ser largos).
   cVideo := ArchivoVideo( hCfg )
   nWEsp  := IF( File( cVideo ), Int( nW * 0.55 ), nW - 4 * nP )
   nY := nBY + Int( nH * 0.04 )
   @ nY, nP * 2 SAY oSay PROMPT "¡Bienvenidos!" OF oDlgCust ;
     SIZE nWEsp, Int( nH * 0.15 ) PIXEL FONT oFHola COLORS CLR_WHITE, MC_FONDO
   AAdd( hMod[ "gEspera" ], oSay )
   @ nY + Int( nH * 0.15 ), nP * 2 SAY oSay PROMPT "Gracias por elegirnos" OF oDlgCust ;
     SIZE nWEsp, Int( nH * 0.05 ) PIXEL FONT oFSub COLORS MC_TENUE, MC_FONDO
   AAdd( hMod[ "gEspera" ], oSay )
   nY += Int( nH * 0.23 )
   @ nY, nP * 2 SAY oSay PROMPT "" OF oDlgCust ;
     SIZE Int( nW * 0.18 ), Int( nH * 0.05 ) PIXEL FONT oFLbl COLORS MC_FONDO, MC_AMARILLO CENTER
   hMod[ "oSlTag" ] := oSay
   AAdd( hMod[ "gEspera" ], oSay )
   @ nY + Int( nH * 0.07 ), nP * 2 SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWEsp, Int( nH * 0.23 ) PIXEL FONT oFSlN COLORS CLR_WHITE, MC_FONDO
   hMod[ "oSlN" ] := oSay
   AAdd( hMod[ "gEspera" ], oSay )
   @ nY + Int( nH * 0.31 ), nP * 2 SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nWEsp, Int( nH * 0.10 ) PIXEL FONT oFSlT COLORS MC_NARANJA, MC_FONDO
   hMod[ "oSlT" ] := oSay
   AAdd( hMod[ "gEspera" ], oSay )

   // ---------- GRACIAS (al terminar una venta cobrada) ----------
   @ Int( nH * 0.32 ), 0 SAY oSay PROMPT "¡Gracias por su compra!" OF oDlgCust ;
     SIZE nW, Int( nH * 0.14 ) PIXEL FONT oFGr1 COLORS CLR_WHITE, MC_FONDO CENTER
   AAdd( hMod[ "gGracias" ], oSay )
   @ Int( nH * 0.50 ), 0 SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nW, Int( nH * 0.1 ) PIXEL FONT oFGr2 COLORS MC_VERDE, MC_FONDO CENTER
   hMod[ "oGr2" ] := oSay
   AAdd( hMod[ "gGracias" ], oSay )

   // ---------- PIE: mensajes del ini (o las ofertas) rotando ----------
   @ nFootY, nP SAY oSay PROMPT "INFO" OF oDlgCust ;
     SIZE Int( nW * 0.08 ), nFootH PIXEL FONT oFPie COLORS MC_FONDO, MC_NARANJA CENTER
   hMod[ "oPieTag" ] := oSay
   AAdd( hMod[ "gPie" ], oSay )
   @ nFootY, nP + Int( nW * 0.08 ) SAY oSay PROMPT "" OF oDlgCust ;
     SIZE nW - 2 * nP - Int( nW * 0.08 ), nFootH PIXEL FONT oFPie COLORS MC_TEXTO, MC_CARD
   hMod[ "oPie" ] := oSay
   AAdd( hMod[ "gPie" ], oSay )

   // Cerrar con ESC (27) o F11 (122) desde el propio display.
   oDlgCust:bKeyDown := { | nKey | IF( nKey == 27 .or. nKey == 122, oDlgCust:End(), nil ) }

   ACTIVATE DIALOG oDlgCust ;
      ON INIT ( oDlgCust:Move( nTop, nLeft, nW, nH, .T. ), ;
                CrearVideoCust( cVideo, nBY + Int( nH * 0.04 ), Int( nW * 0.62 ), nW - Int( nW * 0.62 ) - nP, Int( nH * 0.6 ) ), ;
                RotarModerno(), ModVista(), ModTimer() ) ;
      VALID   ModCerrando() ;
      NOWAIT

   return nil

//-----------------------------------------------------------------------------
// Timer de 150 ms del modelo MODERNO. Se crea en el ON INIT a proposito:
// TTimer:New() guarda oWnd:hWnd al crearse y antes de activar el dialogo vale 0
// (el timer queda huerfano y nunca dispara: ni reloj, ni cartel, ni rotacion).
//-----------------------------------------------------------------------------
// Con debug=S en el ini, display.log anota la creacion y los ticks.
//-----------------------------------------------------------------------------
static function ModTimer()

   DEFINE TIMER oTmrCust INTERVAL 150 ACTION ModTick( "dialogo" ) OF oDlgCust
   ACTIVATE TIMER oTmrCust
   DispLog( "timer dialogo: hWndDlg=" + cValToChar( oDlgCust:hWnd ) + ;
            " owner=" + cValToChar( oTmrCust:hWndOwner ) + " nId=" + cValToChar( oTmrCust:nId ) )


   return nil

//-----------------------------------------------------------------------------
// Diagnóstico: con debug=S en display.ini agrega una línea a .\display.log
//-----------------------------------------------------------------------------
static function DispLog( cTxt )

   if lDispDebug
      hb_MemoWrit( ".\display.log", MemoRead( ".\display.log" ) + ;
                   DToC( Date() ) + " " + Time() + " " + cTxt + CRLF )
   endif

   return nil

//-----------------------------------------------------------------------------
// Elige la primera fuente (de mayor a menor) en la que el importe entra en el
// ancho del SAY, y pone el texto.
//-----------------------------------------------------------------------------
static function AjustaImporte( oSay, cTxt, aFuentes )

   local oF := ATail( aFuentes ), i

   for i := 1 to Len( aFuentes )
      if GetTextWidth( 0, cTxt, aFuentes[ i ]:hFont ) <= oSay:nWidth - 6
         oF := aFuentes[ i ]
         exit
      endif
   next
   if ! ( oSay:oFont == oF )         // != no compara objetos en Harbour
      oSay:SetFont( oF )
   endif
   oSay:SetText( cTxt )

   return nil

//-----------------------------------------------------------------------------
static function ModCerrando()

   if oTmrCust != nil
      oTmrCust:End()
      oTmrCust := nil
   endif
   if hMod != nil
      AEval( hMod[ "fuentes" ], { | o | o:End() } )
   endif
   hMod       := nil
   oVideoCust := nil
   oBrwCust   := nil
   oDlgCust   := nil

   return .T.

//-----------------------------------------------------------------------------
static function ModernoActualizar( hDat )

   local aIt := hDat[ "items" ], nArt := 0, nAhorro := 0, i, hAv
   local nAntes, nPagAnt, nVueAnt

   if hMod == nil
      return nil
   endif
   nAntes  := Len( hMod[ "items" ] )
   nPagAnt := hMod[ "pagado" ]
   nVueAnt := hMod[ "vuelto" ]

   for i := 1 to Len( aIt )
      if aIt[ i ][ 5 ]
         nAhorro -= aIt[ i ][ 4 ]
      else
         nArt++
      endif
   next

   hMod[ "items" ]  := aIt
   hMod[ "pagado" ] := hDat[ "pagado" ]
   hMod[ "vuelto" ] := hDat[ "vuelto" ]

   aItemsCust := aIt
   oBrwCust:SetArray( aItemsCust )
   oBrwCust:GoBottom()             // el último cargado siempre a la vista
   oBrwCust:Refresh()

   hMod[ "oTitulo" ]:SetText( "SU COMPRA" + IF( nArt > 0, "   (" + hb_ntos( nArt ) + ")", "" ) )
   AjustaImporte( hMod[ "oTotal" ], FmtPlata( hDat[ "total" ] ), hMod[ "fTotal" ] )
   hMod[ "oCnt" ]:SetText( "   " + hb_ntos( nArt ) + IF( nArt == 1, " artículo", " artículos" ) )
   hMod[ "oAhorro" ]:SetText( IF( nAhorro > 0.004, "Ahorrás " + FmtPlata( nAhorro ), "" ) )
   AjustaImporte( hMod[ "oPag" ], FmtPlata( hDat[ "pagado" ] ), hMod[ "fPag" ] )
   AjustaImporte( hMod[ "oVue" ], FmtPlata( hDat[ "vuelto" ] ), hMod[ "fVue" ] )

   // Terminó una venta cobrada (había pago y la lista quedó vacía) -> gracias
   if nAntes > 0 .and. Len( aIt ) == 0 .and. nPagAnt > 0.004
      hMod[ "oGr2" ]:SetText( IF( nVueAnt > 0.004, "Su vuelto " + FmtPlata( nVueAnt ), "" ) )
      hMod[ "graciasHasta" ] := hb_MilliSeconds() + 6000
   elseif Len( aIt ) > 0
      hMod[ "graciasHasta" ] := 0
   endif

   // Cartel de oferta: solo cuando llega un aviso nuevo (cambia el id)
   hAv := IF( hb_HHasKey( hDat, "aviso" ), hDat[ "aviso" ], nil )
   if ValType( hAv ) == "H" .and. hAv[ "id" ] > 0 .and. hAv[ "id" ] != hMod[ "avisoId" ]
      hMod[ "avisoId" ] := hAv[ "id" ]
      hMod[ "oBan2" ]:SetText( AllTrim( hAv[ "art" ] ) )
      hMod[ "oBan3" ]:SetText( AllTrim( hAv[ "txt" ] ) )
      MostrarCartel( .T. )
   endif
   if Len( aIt ) == 0
      MostrarCartel( .F. )
   endif

   ModVista()

   return nil

//-----------------------------------------------------------------------------
// Decide qué grupo de controles se ve: venta / espera / gracias.
//-----------------------------------------------------------------------------
static function ModVista()

   local lItems, lGracias, lEspera, lVenta, lPago

   if hMod == nil
      return nil
   endif
   lItems   := Len( hMod[ "items" ] ) > 0
   lGracias := hMod[ "graciasHasta" ] > 0
   lEspera  := ! lItems .and. ! lGracias .and. hMod[ "espera" ]
   lVenta   := ! lGracias .and. ! lEspera
   lPago    := lVenta .and. hMod[ "pagado" ] > 0.004

   if ! lVenta
      MostrarCartel( .F. )
   endif
   MostrarGrupo( hMod[ "gGracias" ], lGracias )
   MostrarGrupo( hMod[ "gEspera" ], lEspera )
   MostrarGrupo( hMod[ "gVenta" ], lVenta )
   MostrarGrupo( hMod[ "gPago" ], lPago )
   MostrarGrupo( hMod[ "gOferta" ], lVenta .and. ! lPago .and. Len( hMod[ "ofertas" ] ) > 0 )
   MostrarGrupo( hMod[ "gPie" ], ! lGracias .and. ! Empty( hMod[ "oPie" ]:GetText() ) )
   if oVideoCust != nil
      IF( lEspera, oVideoCust:Show(), oVideoCust:Hide() )
   endif

   return nil

static function MostrarGrupo( aCtl, lVer )

   local o

   for each o in aCtl
      if lVer != IsWindowVisible( o:hWnd )
         IF( lVer, o:Show(), o:Hide() )
      endif
   next

   return nil

//-----------------------------------------------------------------------------
// Cartel de oferta: se muestra segaviso segundos titilando (lo apaga ModTick).
//-----------------------------------------------------------------------------
static function MostrarCartel( lVer )

   local o

   if lVer
      hMod[ "avisoHasta" ] := hb_MilliSeconds() + hMod[ "segaviso" ] * 1000
      for each o in hMod[ "gCartel" ]
         o:SetColor( MC_FONDO, MC_AMARILLO )
         o:Show()
         SetWindowPos( o:hWnd, 0, 0, 0, 0, 0, nOr( 1, 2 ) )   // HWND_TOP, SWP_NOSIZE+SWP_NOMOVE
         Repinta( o )
      next
   else
      hMod[ "avisoHasta" ] := 0
      if IsWindowVisible( hMod[ "oBan1" ]:hWnd )
         AEval( hMod[ "gCartel" ], { | o | o:Hide() } )
         oBrwCust:Refresh()
      endif
   endif

   return nil

//-----------------------------------------------------------------------------
// Timer de 150 ms: reloj, titileo/fin del cartel, fin del "gracias" y
// rotación de ofertas/mensajes cada 6 s.
//-----------------------------------------------------------------------------
static function ModTick( cOrigen )

   local nNow := hb_MilliSeconds(), cHora := Left( Time(), 5 ), nClr, n

   if hMod == nil
      return nil
   endif

   if hMod[ "debug" ]
      n := hb_HGetDef( hMod[ "ticks" ], cOrigen, 0 ) + 1
      hMod[ "ticks" ][ cOrigen ] := n
      if n == 1 .or. n % 400 == 0          // el primero y uno por minuto
         DispLog( "tick " + cOrigen + " #" + hb_ntos( n ) )
      endif
   endif

   if ! ( cHora == hMod[ "hora" ] )     // == exacto: con SET EXACT OFF, x != "" da .F.
      hMod[ "hora" ] := cHora
      hMod[ "oHora" ]:SetText( cHora )
      hMod[ "oFecha" ]:SetText( FechaLarga( Date() ) )
   endif

   if hMod[ "avisoHasta" ] > 0
      if nNow >= hMod[ "avisoHasta" ]
         MostrarCartel( .F. )
      elseif nNow - hMod[ "blinkT" ] >= 450
         hMod[ "blinkT" ] := nNow
         hMod[ "blink" ]  := ! hMod[ "blink" ]
         nClr := IF( hMod[ "blink" ], MC_AMARILLO2, MC_AMARILLO )
         AEval( hMod[ "gCartel" ], { | o | o:SetColor( MC_FONDO, nClr ), Repinta( o ) } )
      endif
   endif

   if hMod[ "graciasHasta" ] > 0 .and. nNow >= hMod[ "graciasHasta" ]
      hMod[ "graciasHasta" ] := 0
      ModVista()
   endif

   if nNow - hMod[ "rotT" ] >= 6000
      RotarModerno()
   endif

   return nil

//-----------------------------------------------------------------------------
// Avanza la tarjeta de ofertas, la diapositiva de la espera y el pie.
//-----------------------------------------------------------------------------
static function RotarModerno()

   local aOf, aMsg, aSl := {}, n, x, aPie := {}

   if hMod == nil
      return nil
   endif
   hMod[ "rotT" ] := hb_MilliSeconds()
   hMod[ "rot" ]++
   n    := hMod[ "rot" ]
   aOf  := DispCliOfertas()             // cache de 5 min: respeta la franja horaria
   aMsg := hMod[ "mensajes" ]
   hMod[ "ofertas" ] := aOf

   // tarjeta "ofertas de hoy"
   if Len( aOf ) > 0
      x := aOf[ ( ( n - 1 ) % Len( aOf ) ) + 1 ]
      hMod[ "oOfN" ]:SetText( "   " + x[ 1 ] )
      hMod[ "oOfT" ]:SetText( "   " + x[ 2 ] )
   endif

   // diapositiva de la espera: ofertas + mensajes
   AEval( aOf,  { | o | AAdd( aSl, { "*  OFERTA", o[ 1 ], o[ 2 ] } ) } )
   AEval( aMsg, { | m | AAdd( aSl, { "", m, "" } ) } )
   if Len( aSl ) > 0
      x := aSl[ ( ( n - 1 ) % Len( aSl ) ) + 1 ]
      hMod[ "oSlTag" ]:SetText( x[ 1 ] )
      hMod[ "oSlTag" ]:SetColor( MC_FONDO, IF( Empty( x[ 1 ] ), MC_FONDO, MC_AMARILLO ) )   // mensaje: sin etiqueta
      Repinta( hMod[ "oSlTag" ] )
      hMod[ "oSlN" ]:SetText( x[ 2 ] )
      hMod[ "oSlT" ]:SetText( x[ 3 ] )
   endif

   // pie: los mensajes del cliente; si no cargó ninguno, las ofertas
   if Len( aMsg ) > 0
      aPie := aMsg
      hMod[ "oPieTag" ]:SetText( "INFO" )
   else
      AEval( aOf, { | o | AAdd( aPie, o[ 1 ] + ": " + o[ 2 ] ) } )
      hMod[ "oPieTag" ]:SetText( "OFERTAS" )
   endif
   hMod[ "oPie" ]:SetText( IF( Len( aPie ) > 0, "   " + aPie[ ( ( n - 1 ) % Len( aPie ) ) + 1 ], "" ) )

   ModVista()

   return nil

//-----------------------------------------------------------------------------
// Utilidades del modelo MODERNO
//-----------------------------------------------------------------------------
// Redibuja un SAY conservando su texto. OJO: TSay:Refresh() re-evalúa el
// PROMPT original (que acá es "") y borra lo puesto con SetText; y tampoco
// repinta un cambio de color. SetText -> WM_SETTEXT sí lo repinta.
static function Repinta( oSay )

   oSay:SetText( oSay:cCaption )

   return nil

// SAY vacío del color de la tarjeta: margen derecho de los importes
static function Relleno( nY, nX, nAncho, nAlto, nClr, aGrupo )

   local oSay

   @ nY, nX SAY oSay PROMPT "" OF oDlgCust SIZE nAncho, nAlto PIXEL COLORS nClr, nClr
   AAdd( aGrupo, oSay )

   return nil

static function FilaCust()

   if oBrwCust == nil .or. Empty( oBrwCust:aArrayData ) .or. ;
      oBrwCust:nArrayAt < 1 .or. oBrwCust:nArrayAt > Len( oBrwCust:aArrayData )
      return { 0, "", 0, 0, .F., .F. }
   endif

   return oBrwCust:aArrayData[ oBrwCust:nArrayAt ]

static function ColorFila()

   local a := FilaCust()

   do case
   case a[ 5 ]
      return { MC_VERDE, MC_FILAPR }
   case a[ 6 ]
      return { MC_TEXTO, MC_FILAOF }
   endcase

   return { MC_TEXTO, IF( oBrwCust:nArrayAt % 2 == 0, MC_FILA2, MC_FILA1 ) }

static function FmtCant( a )

   local n := a[ 1 ], cN

   if a[ 5 ]
      return "%"
   endif
   if Abs( n - Round( n, 0 ) ) < 0.0005
      return hb_ntos( Round( n, 0 ) )
   endif

   // hasta 3 decimales, sin ceros de mas: 0.750 -> "0,75"
   cN := AllTrim( Str( Round( n, 3 ), 15, 3 ) )
   do while Right( cN, 1 ) == "0"
      cN := Left( cN, Len( cN ) - 1 )
   enddo
   return StrTran( cN, ".", "," )

static function FmtPlata( n )

   n := IF( ValType( n ) == "N", n, 0 )

   // Chr(160) = espacio duro: que DrawText no corte entre el "$" y el numero
   return IF( n < -0.004, "- $" + Chr( 160 ), "$" + Chr( 160 ) ) + AllTrim( Transform( Abs( n ), "@E 999,999,999.99" ) )

static function FechaLarga( d )

   local aDias  := { "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" }
   local aMeses := { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", ;
                     "agosto", "septiembre", "octubre", "noviembre", "diciembre" }

   return aDias[ DoW( d ) ] + " " + hb_ntos( Day( d ) ) + " de " + aMeses[ Month( d ) ]

//=============================================================================
// MODELO WEB: la página display\cliente.html dentro del navegador que trae
// Windows (Shell.Explorer = motor de IE11) vía TActiveX. Sin DLLs ni nada que
// instalar: el HTML va embebido en el exe (HtmlEmbebido) y se escribe solo.
// El POS le pasa los datos como JSON en dos <textarea> ocultos (#cfgdata y
// #dispdata) que la página lee cada 150 ms: IE11 no tiene execScript y el
// DOM sí responde por OLE. Si algo falla, DispCliAbrir abre el MODERNO.
//=============================================================================
static function ModeloWeb( aRect, hCfg )

   local nW := aRect[ 4 ] - aRect[ 1 ], nH := aRect[ 3 ] - aRect[ 2 ]
   local cHtml, lOk := .F.

   cHtml := AsegurarHtml( hCfg[ "html" ] )
   if Empty( cHtml )
      return .F.
   endif

   hWeb := { => }
   hb_HCaseMatch( hWeb, .F. )
   hWeb[ "hCfg" ]    := hCfg
   hWeb[ "cfg" ]     := ""                    // último JSON entregado a la página
   hWeb[ "cfgPend" ] := ArmarCfgWeb( hCfg )   // el que hay que entregar
   hWeb[ "cfgT" ]    := hb_MilliSeconds()
   hWeb[ "dat" ]     := ""
   hWeb[ "datPend" ] := ""
   hWeb[ "listo" ]   := .F.
   hWeb[ "tituloT" ] := 0

   DEFINE DIALOG oDlgCust ;
      TITLE "Display Cliente" ;
      SIZE nW, nH ;
      STYLE nOr( WS_POPUP, WS_VISIBLE, WS_CLIPCHILDREN ) ;
      COLOR MC_TEXTO, MC_FONDO ;
      GRADIENT { { 1, MC_FONDO, MC_FONDO } } ;   // pisa el SetDlgGradient global de bcn.prg
      PIXEL TRUEPIXEL
   oDlgCust:lTransparent := .F.
   oDlgCust:bKeyDown := { | nKey | IF( nKey == 27 .or. nKey == 122, oDlgCust:End(), nil ) }

   ACTIVATE DIALOG oDlgCust ;
      ON INIT ( oDlgCust:Move( aRect[ 2 ], aRect[ 1 ], nW, nH, .T. ), ;
                lOk := CrearWeb( cHtml, nW, nH ) ) ;
      VALID   WebCerrando() ;
      NOWAIT

   if ! lOk
      DispCliCerrar()        // cierra el diálogo vacío; el que llama abre el MODERNO
   endif

   return lOk

//-----------------------------------------------------------------------------
// Crea el navegador y navega a la página (?pos=1: que no corra la demo).
// El timer se crea acá (ON INIT): TTimer:New() necesita el hWnd del diálogo.
//-----------------------------------------------------------------------------
static function CrearWeb( cHtml, nW, nH )

   local lOk := .F., bErr := ErrorBlock( { | e | Break( e ) } ), oErr

   BEGIN SEQUENCE
      oWebCust := TActiveX():New( oDlgCust, "Shell.Explorer.2" )
      oWebCust:Move( 0, 0, nW, nH, .T. )
      oWebCust:oOleAuto:Silent := .T.            // sin cartelitos de error de script
      oWebCust:oOleAuto:Navigate( UrlArchivo( cHtml ) + "?pos=1" )
      lOk := .T.
   RECOVER USING oErr
      DispLog( "WEB: no se pudo crear el navegador: " + ErrTexto( oErr ) )
      oWebCust := nil
   END SEQUENCE
   ErrorBlock( bErr )

   if lOk
      DispLog( "WEB: navegando a " + UrlArchivo( cHtml ) )
      DEFINE TIMER oTmrCust INTERVAL 200 ACTION WebTick() OF oDlgCust
      ACTIVATE TIMER oTmrCust
   endif

   return lOk

//-----------------------------------------------------------------------------
static function WebCerrando()

   if oTmrCust != nil
      oTmrCust:End()
      oTmrCust := nil
   endif
   oWebCust := nil
   hWeb     := nil
   oDlgCust := nil

   return .T.

//-----------------------------------------------------------------------------
// Datos de la venta -> JSON pendiente; se entrega ya si la página está lista.
//-----------------------------------------------------------------------------
static function WebActualizar( hDat )

   local aIt := {}, hAv

   if hWeb == nil
      return nil
   endif

   AEval( hDat[ "items" ], { | a | AAdd( aIt, { "c" => a[ 1 ], "d" => a[ 2 ], "pu" => a[ 3 ], ;
                                                "t" => a[ 4 ], "p" => a[ 5 ], "o" => a[ 6 ] } ) } )
   hAv := IF( hb_HHasKey( hDat, "aviso" ) .and. ValType( hDat[ "aviso" ] ) == "H", hDat[ "aviso" ], { "id" => 0 } )

   hWeb[ "datPend" ] := hb_jsonEncode( { "items" => aIt, "total" => hDat[ "total" ], ;
                                         "pagado" => hDat[ "pagado" ], "vuelto" => hDat[ "vuelto" ], ;
                                         "aviso" => hAv } )
   WebTick()

   return nil

//-----------------------------------------------------------------------------
// Timer de 200 ms: espera que la página termine de cargar y le entrega la
// configuración y los datos pendientes. Cada 5 minutos rearma la
// configuración (las ofertas vigentes cambian con la franja horaria).
//-----------------------------------------------------------------------------
static function WebTick()

   if hWeb == nil .or. oWebCust == nil
      return nil
   endif
   if ! ( WebOle( { || oWebCust:oOleAuto:ReadyState } ) == 4 )   // READYSTATE_COMPLETE
      return nil
   endif

   if ! hWeb[ "listo" ]
      hWeb[ "listo" ] := .T.
      // zoom al 100%: que el escalado de Windows no agrande la página
      WebOle( { || oWebCust:oOleAuto:ExecWB( 63, 2, 100, nil ), .T. } )
      DispLog( "WEB: página cargada" )
   endif

   if lDispDebug .and. hWeb[ "tituloT" ] > 0 .and. hb_MilliSeconds() > hWeb[ "tituloT" ]
      hWeb[ "tituloT" ] := 0
      DispLog( "WEB: titulo despues de procesar = " + cValToChar( WebOle( { || oWebCust:oOleAuto:Document:title } ) ) + ;
               "  items en pantalla = " + cValToChar( WebOle( { || oWebCust:oOleAuto:Document:getElementById( "listaIn" ):children:length } ) ) )
   endif

   if hb_MilliSeconds() - hWeb[ "cfgT" ] > 300000
      hWeb[ "cfgT" ]    := hb_MilliSeconds()
      hWeb[ "cfgPend" ] := ArmarCfgWeb( hWeb[ "hCfg" ] )
   endif

   // primero la configuración, después los datos
   if ! Empty( hWeb[ "cfgPend" ] ) .and. ! ( hWeb[ "cfgPend" ] == hWeb[ "cfg" ] )
      if WebPoner( "cfgdata", hWeb[ "cfgPend" ] )
         hWeb[ "cfg" ] := hWeb[ "cfgPend" ]
      endif
   endif
   if ! Empty( hWeb[ "datPend" ] ) .and. ! ( hWeb[ "datPend" ] == hWeb[ "dat" ] )
      if WebPoner( "dispdata", hWeb[ "datPend" ] )
         hWeb[ "dat" ] := hWeb[ "datPend" ]
      endif
   endif

   return nil

// Deja el JSON en el <textarea> cId de la página
static function WebPoner( cId, cJson )

   local lOk := WebOle( { || oWebCust:oOleAuto:Document:getElementById( cId ):value := cJson, .T. } ) == .T.

   if lDispDebug
      hWeb[ "tituloT" ] := hb_MilliSeconds() + 1500
      DispLog( "WEB: " + cId + IF( lOk, " entregado ", " FALLO " ) + Left( cJson, 200 ) )
      DispLog( "WEB: titulo = " + cValToChar( WebOle( { || oWebCust:oOleAuto:Document:title } ) ) + "  modo IE = " + cValToChar( WebOle( { || oWebCust:oOleAuto:Document:documentMode } ) ) )
   endif

   return lOk

// Evalúa una llamada OLE sin dejar que un error corte el POS
static function WebOle( bAccion )

   local bErr := ErrorBlock( { | e | Break( e ) } ), uRet, oErr

   BEGIN SEQUENCE
      uRet := Eval( bAccion )
   RECOVER USING oErr
      uRet := nil
      DispLog( "WEB OLE: " + ErrTexto( oErr ) )
   END SEQUENCE
   ErrorBlock( bErr )

   return uRet

static function ErrTexto( oErr )

   if ValType( oErr ) == "O"
      return cValToChar( oErr:description ) + " " + cValToChar( oErr:operation )
   endif

   return cValToChar( oErr )

//-----------------------------------------------------------------------------
// Configuración para la página (JSON): tema, tiempos, logo/video como URL,
// mensajes del ini y ofertas vigentes.
//-----------------------------------------------------------------------------
static function ArmarCfgWeb( hCfg )

   local aOf := {}, cLogo := ArchivoLogo( hCfg ), cVideo := ArchivoVideo( hCfg )

   AEval( DispCliOfertas(), { | o | AAdd( aOf, { "n" => o[ 1 ], "t" => o[ 2 ] } ) } )

   return hb_jsonEncode( { "tema"     => hCfg[ "tema" ], ;
                           "segaviso" => Max( 2, Val( hCfg[ "segaviso" ] ) ), ;
                           "espera"   => hCfg[ "espera" ], ;
                           "logo"     => IF( File( cLogo ), UrlArchivo( cLogo ), "" ), ;
                           "video"    => IF( File( cVideo ), UrlArchivo( cVideo ), "" ), ;
                           "tienda"   => "", ;
                           "mensajes" => hCfg[ "mensajes" ], ;
                           "ofertas"  => aOf } )

//-----------------------------------------------------------------------------
// Deja la página en disco: la escribe si falta o si es de otra versión que la
// embebida, salvo que el cliente la haya marcado con <!-- personalizado -->.
// Devuelve la ruta, o "" si no se pudo.
//-----------------------------------------------------------------------------
static function AsegurarHtml( cFile )

   local cHtml := HtmlEmbebido(), cVer := VersionHtml( cHtml ), cAct, cDir

   if Empty( cFile )
      cFile := ".\display\cliente.html"
   endif

   if File( cFile )
      cAct := MemoRead( cFile )
      if "<!-- personalizado -->" $ Lower( cAct ) .or. VersionHtml( cAct ) == cVer
         return cFile
      endif
   endif

   cDir := hb_FNameDir( cFile )
   if ! Empty( cDir ) .and. ! hb_DirExists( cDir )
      hb_DirCreate( cDir )
   endif
   if ! hb_MemoWrit( cFile, cHtml )
      DispLog( "WEB: no se pudo escribir " + cFile )
      return ""
   endif
   DispLog( "WEB: escribí " + cFile + " versión " + cVer )

   return cFile

static function VersionHtml( cHtml )

   local n := At( "dispcli-version: ", cHtml )

   return IF( n > 0, SubStr( cHtml, n + 17, 10 ), "" )

// ".\display\x.html" -> "file:///C:/fwh16/GENERAL/display/x.html"
static function UrlArchivo( cFile )

   local cDir

   if ! ( SubStr( cFile, 2, 1 ) == ":" .or. Left( cFile, 2 ) == "\\" )
      cDir  := CurDir()
      cFile := hb_CurDrive() + ":\" + IF( Empty( cDir ), "", cDir + "\" ) + ;
               IF( Left( cFile, 2 ) == ".\", SubStr( cFile, 3 ), cFile )
   endif

   return "file:///" + StrTran( StrTran( cFile, "\", "/" ), " ", "%20" )

//-----------------------------------------------------------------------------
// display\cliente.html embebido. NO EDITAR A MANO: la fuente es
// FUENTES2\display\cliente.html y este bloque se regenera con
// display\embeber.ps1 (copia el HTML entre las marcas). Debe ser ASCII puro.
//-----------------------------------------------------------------------------
static function HtmlEmbebido()

   local cHtml := ""

//<<HTML
   TEXT INTO cHtml
<!DOCTYPE html>
<html lang="es">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta charset="utf-8">
<title>Display Cliente</title>
<!-- dispcli-version: 2026100805 -->
<!-- Este archivo lo escribe BCN.exe (DISPCLI.PRG) y lo reemplaza cuando cambia la version.
     Para personalizarlo sin que se pise, agregar un comentario HTML cuyo unico texto sea
     la palabra personalizado (en minusculas). -->
<script>
  // cualquier error de JS queda en el titulo (lo puede leer el POS para diagnosticar)
  window.onerror = function (m, u, l) { document.title = "ERR: " + m + " (linea " + l + ")"; };
</script>
<!--
  Display del cliente - modelo WEB (BCN Soft)

  Funciona en WebView2 (Edge/Chromium) y en el navegador embebido de Windows
  (IE11). Por eso el JavaScript es ES5 puro (sin let/const/arrow/template) y el
  CSS no usa variables ni grid; lo moderno (blur) es "extra" que IE ignora.

  Lo maneja el POS (DISPCLI.PRG) con dos funciones globales:
    DISPCONFIG( cfg )  -> configuracion (una vez, al abrir)
       { tema:"OSCURO"|"CLARO", segaviso:6, espera:"S"|"N", logo:"file:///...",
         video:"file:///...", tienda:"Nombre", mensajes:["..."],
         ofertas:[ {n:"Producto", t:"Llevando 2 paga 1"} ] }
    DISPUPDATE( dat )  -> estado de la venta (cada vez que cambia)
       { items:[ {c:2, d:"DETALLE", pu:3500, t:7000, p:0|1 (linea de promo), o:0|1 (en oferta)} ],
         total:0, pagado:0, vuelto:0,
         aviso:{ id:0, art:"DETALLE", txt:"Llevando 2 paga 1" } }   (id cambia = cartel nuevo)
  Ambas aceptan objeto o string JSON. Si el host no puede llamar funciones
  (IE), deja el JSON en los <textarea> #cfgdata / #dispdata y la pagina los lee
  sola cada 150 ms.

  Abierta sin POS (doble clic) corre una DEMO. Parametros de prueba:
    ?tema=claro   ?estado=espera|venta|oferta|pago|gracias  (foto fija)
-->
<style>
html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }
body {
  font-family: "Segoe UI", "Segoe UI Web (West European)", Tahoma, Arial, sans-serif;
  font-size: 2.6vh;
  cursor: none;
  -ms-user-select: none; user-select: none;
}
* { box-sizing: border-box; }
.hide { display: none !important; }
.num { font-feature-settings: "tnum"; -ms-font-feature-settings: "tnum"; }

/* ===================== estructura ===================== */
#app { position: absolute; left: 0; top: 0; right: 0; bottom: 0; display: flex; flex-direction: column; }
#fondo { position: absolute; left: 0; top: 0; right: 0; bottom: 0; overflow: hidden; z-index: 0; }
.blob { position: absolute; width: 70vw; height: 70vw; border-radius: 50%; }
#b1 { left: -20vw; top: -35vw; animation: deriva1 26s ease-in-out infinite alternate; }
#b2 { right: -25vw; bottom: -40vw; animation: deriva2 32s ease-in-out infinite alternate; }
@keyframes deriva1 { from { transform: translate(0, 0); } to { transform: translate(25vw, 12vw); } }
@keyframes deriva2 { from { transform: translate(0, 0); } to { transform: translate(-22vw, -10vw); } }

header, main, footer { position: relative; z-index: 1; }
header { height: 12vh; display: flex; align-items: center; padding: 0 3vw; flex: 0 0 auto; }
#logo { max-height: 8.5vh; max-width: 30vw; border-radius: 1vh; }
#tienda { font-size: 4vh; font-weight: 700; letter-spacing: .05em; }
#reloj { margin-left: auto; text-align: right; line-height: 1.1; }
#hora { font-size: 4.6vh; font-weight: 300; }
#fecha { font-size: 2vh; opacity: .7; }

main { flex: 1 1 0%; display: flex; padding: 0 3vw 2.2vh 3vw; min-height: 0; }
footer { height: 6.5vh; flex: 0 0 auto; overflow: hidden; display: flex; align-items: center; }

/* ===================== lista ===================== */
#colLista { flex: 1 1 0%; display: flex; flex-direction: column; min-width: 0; margin-right: 2.4vw; }
.titulo { font-size: 2vh; font-weight: 700; letter-spacing: .25em; text-transform: uppercase; margin: 0 0 1.4vh .4vw; }
.titulo span { opacity: .55; font-weight: 400; letter-spacing: .05em; text-transform: none; margin-left: .8vw; }
#lista { flex: 1 1 0%; overflow: hidden; position: relative; min-height: 0; }
#listaIn { padding-right: .2vw; }
.it {
  display: flex; align-items: center; min-height: 8.4vh;
  margin-bottom: 1.1vh; padding: 1vh 1.4vw; border-radius: 1.6vh;
  position: relative;
}
.it .q {
  flex: 0 0 auto; min-width: 6.2vh; height: 5.4vh; line-height: 5.4vh; padding: 0 .9vh;
  border-radius: 2.7vh; text-align: center; font-weight: 700; font-size: 2.5vh; margin-right: 1.4vw;
}
.it .d { flex: 1 1 0%; min-width: 0; }
.it .n { font-size: 3vh; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.it .u { font-size: 1.9vh; opacity: .6; margin-top: .2vh; }
.it .t { flex: 0 0 auto; font-size: 3.2vh; font-weight: 700; margin-left: 1.4vw; text-align: right; }
.it .badge {
  flex: 0 0 auto; margin-left: 1vw; padding: .5vh 1.1vh; border-radius: 1vh;
  font-size: 1.7vh; font-weight: 800; letter-spacing: .12em; color: #1a1300;
  background: linear-gradient(90deg, #ffaf22, #ffc65c);
  animation: latido 1.4s ease-in-out infinite;
}
@keyframes latido {
  0%, 100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(255, 175, 34, .55); }   /* px: IE11 calcula mal vh dentro de keyframes */
  50%      { transform: scale(1.08); box-shadow: 0 0 0 10px rgba(255, 175, 34, 0); }
}
.it.oferta:before {
  content: ""; position: absolute; left: 0; top: 1.2vh; bottom: 1.2vh; width: .6vh; border-radius: .3vh;
  background: linear-gradient(180deg, #ffaf22, #ffd27a);
}
.it.promo .q { font-size: 2.8vh; }
.it.nuevo { animation: entra .55s cubic-bezier(.2, .9, .3, 1.25); }
@keyframes entra {
  from { opacity: 0; transform: translateX(-6vw) scale(.96); }
  to   { opacity: 1; transform: none; }
}
.it.cambio .t { animation: brillo 1s ease-out; }
@keyframes brillo { from { color: #ffaf22; transform: scale(1.15); } to { transform: none; } }

/* ===================== panel derecho ===================== */
#panel { flex: 0 0 34vw; width: 34vw; display: flex; flex-direction: column; }
.card { border-radius: 2.4vh; padding: 2.6vh 2vw; margin-bottom: 2vh; position: relative; overflow: hidden; }
.lbl { font-size: 1.9vh; font-weight: 700; letter-spacing: .25em; text-transform: uppercase; opacity: .75; }
#total { font-size: 10.5vh; font-weight: 800; line-height: 1.05; margin: 1vh 0 1.6vh; white-space: nowrap; letter-spacing: -.02em; overflow: hidden; }
#total small { font-size: 5.5vh; font-weight: 600; margin-right: .6vw; opacity: .8; }
.chips span { display: inline-block; padding: .6vh 1.2vh; border-radius: 2vh; font-size: 2vh; font-weight: 600; margin: 0 .6vw .6vh 0; }
#cardPago .fila { display: flex; align-items: baseline; justify-content: space-between; margin-top: .6vh; }
#cardPago .v { font-size: 4.4vh; font-weight: 700; white-space: nowrap; overflow: hidden; max-width: 72%; text-align: right; }
#cardPago .vuelto .v { font-size: 6.4vh; }

#cardOf { flex: 1 1 0%; margin-bottom: 0; display: flex; flex-direction: column; min-height: 0; }
#ofSlide { flex: 1 1 0%; display: flex; flex-direction: column; justify-content: center; position: relative; }
#ofSlide .on { font-size: 4.4vh; font-weight: 800; line-height: 1.1; margin: 0 0 1.2vh; position: relative; }
#ofSlide .ot {
  display: inline-block; align-self: flex-start; font-size: 2.7vh; font-weight: 700; padding: .8vh 1.6vh; border-radius: 1.2vh;
  color: #1a1300; background: linear-gradient(90deg, #ffaf22, #ffc65c); position: relative;
}
#ofSlide .op { font-size: 1.8vh; opacity: .5; margin-top: 2vh; position: relative; }
#ofEstrella { position: absolute; right: -4vh; bottom: -6vh; width: 26vh; height: 26vh; opacity: .07; animation: gira 40s linear infinite; }
.fade { animation: fadein .7s ease-out; }
@keyframes fadein { from { opacity: 0; transform: translateY(2vh); } to { opacity: 1; transform: none; } }

/* ===================== marquesina ===================== */
#ticker { white-space: nowrap; font-size: 2.5vh; font-weight: 600; display: inline-block; padding-left: 100%; animation: marquesina 30s linear infinite; }
#ticker b { margin: 0 2.4vw; }
@keyframes marquesina { from { transform: translateX(0); } to { transform: translateX(-100%); } }
#tickerTag {
  position: relative; z-index: 2; flex: 0 0 auto; height: 100%; padding: 0 2vw; display: flex; align-items: center;
  font-size: 2vh; font-weight: 800; letter-spacing: .2em; color: #1a1300; background: #ffaf22;
}
#tickerBox { flex: 1 1 0%; overflow: hidden; height: 100%; display: flex; align-items: center; }

/* ===================== pantalla de espera ===================== */
#espera { position: absolute; left: 0; top: 12vh; right: 0; bottom: 6.5vh; z-index: 5; display: flex; align-items: center; padding: 0 5vw; }
#espVideo { flex: 0 0 44vw; height: 62vh; margin-left: 4vw; border-radius: 3vh; overflow: hidden; background: #000; -ms-flex-order: 2; order: 2; display: flex; align-items: center; justify-content: center; }
#espVideo video { width: 100%; height: 100%; }
#espVideo.logoG { background: transparent; border-radius: 50%; width: 52vh; height: 52vh; flex: 0 0 52vh; margin-right: 4vw; }
#espVideo.logoG img { max-width: 70%; max-height: 70%; border-radius: 2vh; }
body.oscuro #espVideo.logoG { background: radial-gradient(circle, rgba(255, 175, 34, .18) 0%, rgba(255, 175, 34, 0) 70%); }
body.claro #espVideo.logoG { background: radial-gradient(circle, rgba(255, 175, 34, .25) 0%, rgba(255, 175, 34, 0) 70%); }
body.enEspera main { visibility: hidden; }
#espTexto { flex: 1 1 0%; min-width: 0; }
#espHola { font-size: 9vh; font-weight: 800; line-height: 1; letter-spacing: -.02em; }
#espSub { font-size: 3vh; opacity: .7; margin: 1.5vh 0 5vh; }
#espSlide { min-height: 26vh; border-radius: 3vh; padding: 4vh 3vw; position: relative; overflow: hidden; }
#espSlide .tag { display: inline-block; padding: .6vh 1.4vh; border-radius: 1vh; font-size: 2vh; font-weight: 800; letter-spacing: .2em; color: #1a1300; background: linear-gradient(90deg, #ffaf22, #ffc65c); }
#espSlide .s1 { font-size: 5.4vh; font-weight: 800; margin-top: 2vh; line-height: 1.1; }
#espSlide .s2 { font-size: 3.4vh; margin-top: 1.4vh; opacity: .85; }
#espSlide .msg { font-size: 4.6vh; font-weight: 700; line-height: 1.25; }
#espPuntos { margin-top: 2.4vh; }
#espPuntos i { display: inline-block; width: 1.2vh; height: 1.2vh; border-radius: .6vh; margin-right: 1vh; opacity: .3; }
#espPuntos i.on { width: 4vh; opacity: 1; }

/* ===================== cartel de oferta ===================== */
#velo { position: absolute; left: 0; top: 0; right: 0; bottom: 0; z-index: 20; background: rgba(5, 6, 15, .45); animation: fadein .3s; }
#toast {
  position: absolute; z-index: 21; left: 50%; top: 50%; width: 62vw; margin-left: -31vw; margin-top: -24vh;
  min-height: 48vh; border-radius: 4vh; padding: 5vh 4vw 6vh 4vw; text-align: center; color: #1a1300;
  background: linear-gradient(135deg, #ffaf22 0%, #ffc04d 50%, #ffd88a 100%);
  box-shadow: 0 3vh 10vh rgba(255, 175, 34, .55), 0 0 0 .6vh rgba(255, 255, 255, .25) inset;
  overflow: hidden;
}
#toast.sale { animation: toastIn .7s cubic-bezier(.2, 1.4, .4, 1); }
@keyframes toastIn {
  0%   { opacity: 0; transform: scale(.55) rotate(-4deg); }
  100% { opacity: 1; transform: scale(1) rotate(0); }
}
#toast .rayos {
  position: absolute; left: 50%; top: 50%; width: 140vh; height: 140vh; margin: -70vh 0 0 -70vh; opacity: .16;
  animation: gira 18s linear infinite;
}
@keyframes gira { from { transform: rotate(0); } to { transform: rotate(360deg); } }
#toast .brillo {
  position: absolute; top: 0; bottom: 0; width: 20vw; left: -30vw; transform: skewX(-20deg);
  background: linear-gradient(90deg, rgba(255,255,255,0), rgba(255,255,255,.45), rgba(255,255,255,0));
  animation: barre 2.6s ease-in-out .5s infinite;
}
@keyframes barre { from { left: -30vw; } to { left: 90vw; } }
#toast .in { position: relative; }
#toast .estrella { width: 11vh; height: 11vh; animation: latido 1.2s infinite; border-radius: 50%; }
#toast .t1 { font-size: 3vh; font-weight: 800; letter-spacing: .3em; margin-top: 1vh; text-transform: uppercase; }
#toast .t2 { font-size: 6.4vh; font-weight: 800; line-height: 1.05; margin-top: 1.8vh; text-shadow: 0 .4vh 1.4vh rgba(0,0,0,.25); }
#toast .t3 {
  display: inline-block; margin-top: 2.6vh; padding: 1.2vh 2.4vw; border-radius: 2vh; font-size: 4vh; font-weight: 700;
  background: rgba(0, 0, 0, .22);
}
#toast .barra { position: absolute; left: 0; right: 0; bottom: 0; height: 1vh; background: rgba(0,0,0,.2); }
#toast .barra i { display: block; height: 100%; width: 100%; background: #fff; }

/* ===================== gracias ===================== */
#gracias { position: absolute; left: 0; top: 0; right: 0; bottom: 0; z-index: 30; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
#gracias .g1 { font-size: 11vh; font-weight: 800; letter-spacing: -.02em; animation: toastIn .8s cubic-bezier(.2, 1.4, .4, 1); }
#gracias .g2 { font-size: 3.6vh; opacity: .75; margin-top: 1vh; }
#gracias .g3 { margin-top: 5vh; padding: 2.4vh 4vw; border-radius: 3vh; font-size: 3vh; }
#gracias .g3 b { display: block; font-size: 9vh; line-height: 1.1; white-space: nowrap; overflow: hidden; max-width: 80vw; }
.confeti { position: absolute; top: -4vh; width: 1.2vh; height: 2.4vh; border-radius: .3vh; animation: cae linear forwards; }
@keyframes cae { to { transform: translateY(112vh) rotate(720deg); } }

/* ===================== tema OSCURO ===================== */
body.oscuro { background: #0a0c18; color: #eef0ff; }
body.oscuro #b1 { background: radial-gradient(circle, rgba(255, 175, 34, .22) 0%, rgba(255, 175, 34, 0) 62%); }
body.oscuro #b2 { background: radial-gradient(circle, rgba(124, 77, 255, .24) 0%, rgba(124, 77, 255, 0) 62%); }
body.oscuro .it { background: rgba(255, 255, 255, .055); border: 1px solid rgba(255, 255, 255, .07); }
body.oscuro .it .q { background: rgba(255, 175, 34, .14); color: #ffc65c; }
body.oscuro .it.oferta { background: linear-gradient(90deg, rgba(255, 175, 34, .16), rgba(255, 255, 255, .05) 60%); border-color: rgba(255, 175, 34, .35); }
body.oscuro .it.promo { background: rgba(34, 214, 140, .08); border-color: rgba(34, 214, 140, .25); }
body.oscuro .it.promo .q, body.oscuro .it.promo .t { color: #3ff0a6; }
body.oscuro .it.promo .q { background: rgba(34, 214, 140, .14); }
body.oscuro .card { background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .08); -webkit-backdrop-filter: blur(18px); backdrop-filter: blur(18px); }
body.oscuro #cardTotal { background: linear-gradient(145deg, rgba(255, 175, 34, .2), rgba(255, 255, 255, .04) 70%); border-color: rgba(255, 175, 34, .35); }
body.oscuro #total { color: #fff; text-shadow: 0 0 4vh rgba(255, 175, 34, .45); }
body.oscuro .chips span { background: rgba(255, 255, 255, .09); }
body.oscuro .chips span.ok { background: rgba(34, 214, 140, .18); color: #3ff0a6; }
body.oscuro #cardPago .vuelto .v { color: #3ff0a6; }
body.oscuro footer { background: rgba(255, 255, 255, .04); border-top: 1px solid rgba(255, 255, 255, .07); }
body.oscuro #ticker b { color: #ffaf22; }
body.oscuro #espera { background: transparent; }
body.oscuro #espHola { color: #fff; text-shadow: 0 0 6vh rgba(255, 175, 34, .35); }
body.oscuro #espSlide { background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .08); }
body.oscuro #espPuntos i { background: #ffaf22; }
body.oscuro #ofSlide .on { color: #fff; }
body.oscuro #gracias { background: radial-gradient(circle at 50% 40%, #1d1640 0%, #0a0c18 70%); }
body.oscuro #gracias .g3 { background: rgba(34, 214, 140, .12); border: 1px solid rgba(34, 214, 140, .35); }
body.oscuro #gracias .g3 b { color: #3ff0a6; }

/* ===================== tema CLARO ===================== */
body.claro { background: #eef1f7; color: #1b1f3b; }
body.claro #b1 { background: radial-gradient(circle, rgba(255, 175, 34, .28) 0%, rgba(255, 175, 34, 0) 62%); }
body.claro #b2 { background: radial-gradient(circle, rgba(64, 140, 255, .18) 0%, rgba(64, 140, 255, 0) 62%); }
body.claro .it { background: #fff; box-shadow: 0 .5vh 2vh rgba(27, 31, 59, .07); }
body.claro .it .q { background: #fff3dc; color: #c77800; }
body.claro .it.oferta { background: linear-gradient(90deg, #fff3dc, #fff 60%); }
body.claro .it.promo { background: #e7f9f0; }
body.claro .it.promo .q, body.claro .it.promo .t { color: #0e9f63; }
body.claro .it.promo .q { background: #cdf3e0; }
body.claro .card { background: rgba(255, 255, 255, .85); box-shadow: 0 1vh 4vh rgba(27, 31, 59, .08); }
body.claro #cardTotal { background: linear-gradient(145deg, #1b1f3b, #2d3263); color: #fff; }
body.claro #total { color: #fff; }
body.claro #cardTotal .chips span { background: rgba(255, 255, 255, .14); }
body.claro #cardTotal .chips span.ok { background: rgba(63, 240, 166, .2); color: #6ff5bb; }
body.claro #cardPago .vuelto .v { color: #0e9f63; }
body.claro footer { background: #1b1f3b; color: #fff; }
body.claro #ticker b { color: #ffaf22; }
body.claro #espera { background: transparent; }
body.claro #espSlide { background: #fff; box-shadow: 0 1vh 4vh rgba(27, 31, 59, .08); }
body.claro #espPuntos i { background: #ff8a00; }
body.claro #gracias { background: radial-gradient(circle at 50% 40%, #ffffff 0%, #e4e8f2 75%); }
body.claro #velo { background: rgba(255, 255, 255, .6); -webkit-backdrop-filter: blur(6px); backdrop-filter: blur(6px); }   /* en el claro el velo oscuro quedaba gris sucio */
body.claro #gracias .g3 { background: #e7f9f0; }
body.claro #gracias .g3 b { color: #0e9f63; }

/* foto fija para capturas (?estado=...): sin animaciones de entrada */
body.foto .it, body.foto .fade, body.foto #toast, body.foto #gracias .g1, body.foto #velo { animation: none !important; }

/* textareas por donde el POS deja los datos cuando no puede llamar funciones (IE) */
#cfgdata, #dispdata { position: absolute; left: -9999px; top: 0; width: 10px; height: 10px; }
</style>
</head>
<body class="oscuro">

<div id="fondo"><div class="blob" id="b1"></div><div class="blob" id="b2"></div></div>

<div id="app">
  <header>
    <img id="logo" alt="" class="hide">
    <div id="tienda"></div>
    <div id="reloj"><div id="hora" class="num">--:--</div><div id="fecha"></div></div>
  </header>

  <main>
    <div id="colLista">
      <div class="titulo">Su compra <span id="cntTit"></span></div>
      <div id="lista"><div id="listaIn"></div></div>
    </div>
    <div id="panel">
      <div class="card" id="cardTotal">
        <div class="lbl">Total a pagar</div>
        <div id="total" class="num"><small>$</small>0,00</div>
        <div class="chips"><span id="cnt">0 art&iacute;culos</span><span id="ahorro" class="ok hide"></span></div>
      </div>
      <div class="card hide" id="cardPago">
        <div class="fila"><span class="lbl">Pagado</span><span class="v num" id="pagado"></span></div>
        <div class="fila vuelto"><span class="lbl">Su vuelto</span><span class="v num" id="vuelto"></span></div>
      </div>
      <div class="card" id="cardOf">
        <div class="lbl">&#9733; Ofertas de hoy</div>
        <svg id="ofEstrella" viewBox="0 0 100 100"><polygon fill="#ffaf22" points="50,2 62,36 98,37 69,58 80,93 50,72 20,93 31,58 2,37 38,36"/></svg>
        <div id="ofSlide"></div>
      </div>
    </div>
  </main>

  <footer id="pie">
    <div id="tickerTag">INFO</div>
    <div id="tickerBox"><div id="ticker"></div></div>
  </footer>
</div>

<div id="espera" class="hide">
  <div id="espVideo" class="hide"></div>
  <div id="espTexto">
    <div id="espHola">&iexcl;Bienvenidos!</div>
    <div id="espSub">Gracias por elegirnos</div>
    <div id="espSlide"></div>
    <div id="espPuntos"></div>
  </div>
</div>

<div id="velo" class="hide"></div>
<div id="toast" class="hide">
  <svg class="rayos" viewBox="0 0 100 100" preserveAspectRatio="none"><g id="rayosG" fill="#fff"></g></svg>
  <div class="brillo"></div>
  <div class="in">
    <svg class="estrella" viewBox="0 0 100 100"><circle cx="50" cy="50" r="48" fill="#fff"/><polygon fill="#ffaf22" points="50,14 60,39 87,40 66,57 73,84 50,69 27,84 34,57 13,40 40,39"/></svg>
    <div class="t1">&iexcl;Este producto est&aacute; en oferta!</div>
    <div class="t2" id="toastArt"></div>
    <div class="t3" id="toastTxt"></div>
  </div>
  <div class="barra"><i id="toastBar"></i></div>
</div>

<div id="gracias" class="hide">
  <div class="g1">&iexcl;Gracias por su compra!</div>
  <div class="g2">Lo esperamos pronto</div>
  <div class="g3 hide" id="gVuelto">Su vuelto<b class="num" id="gVueltoN"></b></div>
</div>

<textarea id="cfgdata"></textarea>
<textarea id="dispdata"></textarea>

<script>
(function () {
  var $ = function (id) { return document.getElementById(id); };

  var CFG = { tema: "OSCURO", segaviso: 6, espera: "S", logo: "", video: "", tienda: "", mensajes: [], ofertas: [] };
  var est = { items: [], total: 0, pagado: 0, vuelto: 0, aviso: { id: 0 } };
  var prevItems = [], totalMostrado = 0, ultAviso = 0, toastTimer = null, rafTotal = null;
  var huboPago = 0, graciasTimer = null, recibido = false, sinAnim = false;
  var ofIdx = 0, espIdx = 0;

  // ---------- utilidades ----------
  function money(n) {
    n = Number(n) || 0;
    var neg = n < 0, s = Math.abs(n).toFixed(2), p = s.split("."), e = p[0], r = "";
    while (e.length > 3) { r = "." + e.substr(e.length - 3) + r; e = e.substr(0, e.length - 3); }
    return (neg ? "- " : "") + e + r + "," + p[1];
  }
  function cant(n) {
    n = Number(n) || 0;
    if (Math.abs(n - Math.round(n)) < 0.0005) { return String(Math.round(n)); }
    return n.toFixed(3).replace(/0+$/, "").replace(".", ",");
  }
  function esc(s) {
    return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }
  function show(el, si) { if (si) { el.className = el.className.replace(/\\s*\\bhide\\b/g, ""); } else if (!/\\bhide\\b/.test(el.className)) { el.className += " hide"; } }
  function parse(x) { return (typeof x === "string") ? JSON.parse(x) : x; }
  function reanimar(el, clase) { el.className = el.className.replace(new RegExp("\\\\s*\\\\b" + clase + "\\\\b", "g"), ""); void el.offsetWidth; el.className += " " + clase; }

  // ---------- reloj ----------
  var DIAS = ["domingo", "lunes", "martes", "mi\\u00e9rcoles", "jueves", "viernes", "s\\u00e1bado"];
  var MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
  function reloj() {
    var d = new Date(), h = d.getHours(), m = d.getMinutes();
    $("hora").innerHTML = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
    var dia = DIAS[d.getDay()];
    $("fecha").innerHTML = dia.charAt(0).toUpperCase() + dia.substr(1) + " " + d.getDate() + " de " + MESES[d.getMonth()];
  }

  // ---------- total animado ----------
  // Achica la letra de un importe (en vh, de a medio) hasta que entre en su caja
  function ajustar(el, vhBase) {
    var vh = vhBase;
    el.style.fontSize = vh + "vh";
    while (vh > 2.5 && el.scrollWidth > el.clientWidth + 1) { vh -= 0.5; el.style.fontSize = vh + "vh"; }
  }
  function pintarTotal(v) { $("total").innerHTML = "<small>$</small>" + money(v); ajustar($("total"), 10.5); }
  function animarTotal(desde, hasta) {
    var t0 = null, dur = 650;
    if (window.cancelAnimationFrame && rafTotal) { cancelAnimationFrame(rafTotal); }
    if (sinAnim || !window.requestAnimationFrame || desde === hasta) { pintarTotal(hasta); return; }
    function paso(ts) {
      if (t0 === null) { t0 = ts; }
      var k = Math.min(1, (ts - t0) / dur), e = 1 - Math.pow(1 - k, 3);
      pintarTotal(desde + (hasta - desde) * e);
      if (k < 1) { rafTotal = requestAnimationFrame(paso); }
    }
    rafTotal = requestAnimationFrame(paso);
  }

  // ---------- lista ----------
  function renderLista() {
    var html = "", i, it, cls, nuevo, cambio, prev, n = est.items.length, arts = 0, ahorro = 0;
    for (i = 0; i < n; i++) {
      it = est.items[i];
      prev = prevItems[i];
      nuevo = !prev || prev.d !== it.d;
      cambio = !nuevo && (prev.c !== it.c || prev.t !== it.t);
      cls = "it" + (it.p ? " promo" : "") + (it.o && !it.p ? " oferta" : "") + (nuevo ? " nuevo" : "") + (cambio ? " cambio" : "");
      if (it.p) { ahorro -= Number(it.t) || 0; } else { arts += 1; }
      html += '<div class="' + cls + '">' +
        '<div class="q num">' + (it.p ? "%" : cant(it.c)) + '</div>' +
        '<div class="d"><div class="n">' + esc(it.d) + '</div>' +
        (it.p ? '<div class="u">Descuento aplicado</div>' : '<div class="u num">$ ' + money(it.pu) + ' c/u</div>') + '</div>' +
        (it.o && !it.p ? '<span class="badge">OFERTA</span>' : '') +
        '<div class="t num">' + (it.t < 0 ? '- $ ' + money(-it.t) : '$ ' + money(it.t)) + '</div></div>';
    }
    $("listaIn").innerHTML = html;
    $("lista").scrollTop = $("lista").scrollHeight;   // siempre a la vista el ultimo cargado
    $("cnt").innerHTML = arts + (arts === 1 ? " art&iacute;culo" : " art&iacute;culos");
    $("cntTit").innerHTML = arts ? "(" + arts + ")" : "";
    if (ahorro > 0.004) { $("ahorro").innerHTML = "Ahorr&aacute;s $ " + money(ahorro); show($("ahorro"), true); }
    else { show($("ahorro"), false); }
    prevItems = [];
    for (i = 0; i < n; i++) { prevItems.push({ d: est.items[i].d, c: est.items[i].c, t: est.items[i].t }); }
  }

  // ---------- cartel de oferta ----------
  function rayos() {
    var g = "", i, a1, a2, r = 75;
    for (i = 0; i < 24; i += 2) {
      a1 = i * Math.PI / 12; a2 = (i + 1) * Math.PI / 12;
      g += '<polygon points="50,50 ' + (50 + r * Math.cos(a1)).toFixed(1) + ',' + (50 + r * Math.sin(a1)).toFixed(1) + ' ' +
           (50 + r * Math.cos(a2)).toFixed(1) + ',' + (50 + r * Math.sin(a2)).toFixed(1) + '"/>';
    }
    $("rayosG").innerHTML = g;   // IE11 no soporta innerHTML en SVG: queda sin rayos (sin error)
  }
  function mostrarToast(art, txt) {
    var seg = Math.max(2, Number(CFG.segaviso) || 6), bar = $("toastBar"), t0 = new Date().getTime();
    $("toastArt").innerHTML = esc(art);
    $("toastTxt").innerHTML = esc(txt);
    show($("toastTxt"), !!txt);
    show($("velo"), true); show($("toast"), true);
    reanimar($("toast"), "sale");
    if (toastTimer) { clearInterval(toastTimer); }
    bar.style.width = "100%";
    toastTimer = setInterval(function () {
      var k = (new Date().getTime() - t0) / (seg * 1000);
      bar.style.width = Math.max(0, 100 - k * 100) + "%";
      if (k >= 1) { ocultarToast(); }
    }, 50);
  }
  function ocultarToast() {
    if (toastTimer) { clearInterval(toastTimer); toastTimer = null; }
    show($("toast"), false); show($("velo"), false);
  }

  // ---------- pantalla de espera / gracias ----------
  function slidesEspera() {
    var s = [], i;
    for (i = 0; i < CFG.ofertas.length; i++) { s.push({ of: CFG.ofertas[i] }); }
    for (i = 0; i < CFG.mensajes.length; i++) { s.push({ msg: CFG.mensajes[i] }); }
    return s;
  }
  function rotarEspera() {
    var s = slidesEspera(), el = $("espSlide"), dots = "", i, x;
    if (!s.length) { show(el, false); $("espPuntos").innerHTML = ""; return; }
    show(el, true);
    espIdx = espIdx % s.length;
    x = s[espIdx];
    el.innerHTML = x.of ? '<span class="tag">&#9733; OFERTA</span><div class="s1">' + esc(x.of.n) + '</div><div class="s2">' + esc(x.of.t) + '</div>'
                        : '<div class="msg">' + esc(x.msg) + '</div>';
    reanimar(el, "fade");
    for (i = 0; i < s.length && s.length > 1; i++) { dots += '<i' + (i === espIdx ? ' class="on"' : '') + '></i>'; }
    $("espPuntos").innerHTML = dots;
    espIdx++;
  }
  function rotarOfertaPanel() {
    var of = CFG.ofertas, el = $("ofSlide");
    if (!of.length) { show($("cardOf"), false); return; }
    show($("cardOf"), true);
    ofIdx = ofIdx % of.length;
    el.innerHTML = '<div class="on">' + esc(of[ofIdx].n) + '</div><div class="ot">' + esc(of[ofIdx].t) + '</div>' +
                   (of.length > 1 ? '<div class="op">' + (ofIdx + 1) + ' de ' + of.length + '</div>' : '');
    reanimar(el, "fade");
    ofIdx++;
  }
  function confeti() {
    var g = $("gracias"), i, c, cols = ["#ffaf22", "#ffd27a", "#3ff0a6", "#7c4dff", "#22d3ee"];
    for (i = 0; i < 46; i++) {
      c = document.createElement("i");
      c.className = "confeti";
      c.style.left = (Math.random() * 100) + "vw";
      c.style.background = cols[i % cols.length];
      c.style.animationDuration = (2.2 + Math.random() * 2.2) + "s";
      c.style.animationDelay = (Math.random() * .8) + "s";
      g.appendChild(c);
    }
    setTimeout(function () { var l = g.getElementsByTagName("i"), k; for (k = l.length - 1; k >= 0; k--) { if (l[k].className === "confeti") { g.removeChild(l[k]); } } }, 5500);
  }
  function mostrarGracias(vuelto) {
    $("gVueltoN").innerHTML = "$ " + money(vuelto);
    ajustar($("gVueltoN"), 9);
    show($("gVuelto"), vuelto > 0.004);
    show($("gracias"), true);
    confeti();
    if (graciasTimer) { clearTimeout(graciasTimer); }
    graciasTimer = setTimeout(function () { show($("gracias"), false); graciasTimer = null; aplicarEspera(); }, 6000);
  }
  function aplicarEspera() {
    var vacio = est.items.length === 0, conEspera = String(CFG.espera).toUpperCase() !== "N";
    var en = vacio && conEspera && !graciasTimer, b = document.body;
    show($("espera"), en);
    b.className = b.className.replace(/\\s*\\benEspera\\b/g, "") + (en ? " enEspera" : "");
  }

  // ---------- API para el POS ----------
  window.DISPCONFIG = function (x) {
    var c = parse(x), k;
    for (k in c) { if (c.hasOwnProperty(k)) { CFG[k] = c[k]; } }
    CFG.mensajes = CFG.mensajes || []; CFG.ofertas = CFG.ofertas || [];
    document.body.className = String(CFG.tema).toUpperCase() === "CLARO" ? "claro" : "oscuro";
    if (CFG.logo) { $("logo").src = CFG.logo; show($("logo"), true); $("tienda").innerHTML = ""; }
    else { show($("logo"), false); $("tienda").innerHTML = esc(CFG.tienda); }
    // marquesina: mensajes del cliente; si no hay, las ofertas
    var t = [], i;
    for (i = 0; i < CFG.mensajes.length; i++) { t.push(esc(CFG.mensajes[i])); }
    if (!t.length) { for (i = 0; i < CFG.ofertas.length; i++) { t.push(esc(CFG.ofertas[i].n + ": " + CFG.ofertas[i].t)); } }
    show($("pie"), t.length > 0);
    $("tickerTag").innerHTML = CFG.mensajes.length ? "INFO" : "OFERTAS";
    $("ticker").innerHTML = t.join("<b>&#9733;</b>");
    $("ticker").style.animationDuration = Math.max(14, $("ticker").innerHTML.length * 0.09) + "s";
    // espera: video si hay; si no, el logo grande
    var ev = $("espVideo");
    if (CFG.video)     { ev.className = ""; ev.innerHTML = '<video src="' + esc(CFG.video) + '" autoplay loop muted></video>'; }
    else if (CFG.logo) { ev.className = "logoG"; ev.innerHTML = '<img src="' + esc(CFG.logo) + '" alt="">'; }
    else               { ev.className = "hide"; ev.innerHTML = ""; }
    espIdx = 0; ofIdx = 0; rotarEspera(); rotarOfertaPanel();
    aplicarEspera();
  };

  window.DISPUPDATE = function (x) {
    var d = parse(x), antes = est.items.length;
    recibido = true;
    est.items = d.items || [];
    est.pagado = Number(d.pagado) || 0;
    est.vuelto = Number(d.vuelto) || 0;
    renderLista();
    if (Number(d.total) !== est.total) { animarTotal(totalMostrado, Number(d.total) || 0); totalMostrado = Number(d.total) || 0; }
    est.total = Number(d.total) || 0;

    show($("cardPago"), est.pagado > 0.004);
    $("pagado").innerHTML = "$ " + money(est.pagado);
    $("vuelto").innerHTML = "$ " + money(est.vuelto);
    if (est.pagado > 0.004) { ajustar($("pagado"), 4.4); ajustar($("vuelto"), 6.4); }
    if (est.pagado > 0.004) { huboPago = est.vuelto; }

    // cartel de oferta: solo cuando cambia el id
    if (d.aviso && d.aviso.id && d.aviso.id !== ultAviso) {
      ultAviso = d.aviso.id;
      mostrarToast(d.aviso.art, d.aviso.txt);
    }
    if (!est.items.length) { ocultarToast(); }

    // termino una venta cobrada -> gracias; cancelada -> directo a la espera
    if (antes > 0 && est.items.length === 0 && huboPago !== 0) { mostrarGracias(huboPago); }
    if (est.items.length === 0) { huboPago = 0; }
    if (est.items.length > 0 && graciasTimer) { clearTimeout(graciasTimer); graciasTimer = null; show($("gracias"), false); }
    aplicarEspera();
    // segundo ajuste de los importes cuando el navegador ya termino de armar la pagina
    setTimeout(function () { ajustar($("total"), 10.5); if (est.pagado > 0.004) { ajustar($("pagado"), 4.4); ajustar($("vuelto"), 6.4); } }, 250);
  };

  // IE: el POS deja el JSON en los textarea y la pagina los levanta
  var ultCfg = "", ultDat = "";
  function sondear() {
    var c = $("cfgdata").value, d = $("dispdata").value;
    if (c && c !== ultCfg) { ultCfg = c; try { window.DISPCONFIG(c); } catch (e) { document.title = "ERR config: " + e.message; } }
    if (d && d !== ultDat) { ultDat = d; try { window.DISPUPDATE(d); } catch (e) { document.title = "ERR datos: " + e.message; } }
  }

  // ---------- DEMO (abierta sin POS) ----------
  function qs(k) { var m = new RegExp("[?&]" + k + "=([^&]*)").exec(location.search); return m ? decodeURIComponent(m[1]) : ""; }
  var DEMO_CFG = {
    tema: qs("tema") || "OSCURO", segaviso: 5, espera: "S", tienda: "MI ALMAC\\u00c9N", logo: "../../logo_cliente.png",
    mensajes: ["Lunes y viernes 20% de descuento con Cuenta DNI", "Env\\u00edos a domicilio sin cargo en compras mayores a $ 30.000", "Seguinos en Instagram @mialmacen"],
    ofertas: [{ n: "Gaseosa Cola 2,25 L", t: "Llevando 2, pag\\u00e1s 1" }, { n: "Yerba Mate 1 kg", t: "Precio especial $ 4.990" }, { n: "Galletitas Surtidas", t: "La 3\\u00ba unidad al 50%" }]
  };
  var DEMO_ITEMS = [
    { c: 1, d: "GASEOSA COLA 2.25 L", pu: 3500, t: 3500, p: 0, o: 1 },
    { c: 1, d: "PAPAS FRITAS CL\\u00c1SICAS 250 G", pu: 4200, t: 4200, p: 0, o: 0 },
    { c: 0.75, d: "QUESO CREMOSO X KG", pu: 9800, t: 7350, p: 0, o: 0 },
    { c: 1, d: "YERBA MATE 1 KG", pu: 4990, t: 4990, p: 0, o: 1 },
    { c: 6, d: "AGUA MINERAL 500 ML", pu: 900, t: 5400, p: 0, o: 0 }
  ];
  function demoDatos(n, conPromo, pagado) {
    var it = [], i, tot = 0;
    for (i = 0; i < n; i++) { it.push(DEMO_ITEMS[i]); }
    if (n >= 1) { it[0] = { c: 2, d: it[0].d, pu: 3500, t: 7000, p: 0, o: 1 }; }
    if (conPromo) { it.push({ c: 1, d: "PROMO 2X1 GASEOSA COLA", pu: -3500, t: -3500, p: 1, o: 0 }); }
    for (i = 0; i < it.length; i++) { tot += it[i].t; }
    return { items: it, total: tot, pagado: pagado || 0, vuelto: pagado ? pagado - tot : 0, aviso: { id: 0 } };
  }
  function demo() {
    var paso = 0, pasos;
    window.DISPCONFIG(DEMO_CFG);
    pasos = [
      [3500, function () { window.DISPUPDATE({ items: [DEMO_ITEMS[0]], total: 3500, aviso: { id: 1, art: "Gaseosa Cola 2,25 L", txt: "Llevando 2, pag\\u00e1s 1" } }); }],
      [6500, function () { var d = demoDatos(1); window.DISPUPDATE(d); }],
      [2200, function () { window.DISPUPDATE(demoDatos(2)); }],
      [2200, function () { window.DISPUPDATE(demoDatos(3)); }],
      [2200, function () { var d = demoDatos(4); d.aviso = { id: 2, art: "Yerba Mate 1 kg", txt: "Precio especial $ 4.990" }; window.DISPUPDATE(d); }],
      [6000, function () { window.DISPUPDATE(demoDatos(5)); }],
      [2500, function () { window.DISPUPDATE(demoDatos(5, true)); }],
      [3000, function () { window.DISPUPDATE(demoDatos(5, true, 30000)); }],
      [4000, function () { window.DISPUPDATE({ items: [], total: 0, pagado: 0, vuelto: 0 }); }]
    ];
    function sig() {
      var p = pasos[paso % pasos.length];
      setTimeout(function () { p[1](); paso++; sig(); }, p[0]);
    }
    window.DISPUPDATE({ items: [], total: 0 });
    sig();
  }
  function foto(e) {   // ?estado=... foto fija para capturas
    sinAnim = true;
    window.DISPCONFIG(DEMO_CFG);
    document.body.className += " foto";
    if (e === "espera") { window.DISPUPDATE({ items: [], total: 0 }); return; }
    if (e === "oferta") { var d = demoDatos(4); d.aviso = { id: 9, art: "Yerba Mate 1 kg", txt: "Precio especial $ 4.990" }; window.DISPUPDATE(demoDatos(3)); window.DISPUPDATE(d); return; }
    if (e === "grande") { window.DISPUPDATE({ items: [{ c: 1, d: "HELADERA NO FROST 400 L", pu: 1250000, t: 1250000, p: 0, o: 0 }], total: 1250000, pagado: 1300000, vuelto: 50000 }); return; }
    if (e === "pago")   { window.DISPUPDATE(demoDatos(5, true, 30000)); return; }
    if (e === "gracias") { window.DISPUPDATE(demoDatos(5, true, 30000)); window.DISPUPDATE({ items: [], total: 0 }); return; }
    window.DISPUPDATE(demoDatos(5, true));
  }

  // ---------- arranque ----------
  rayos();
  reloj();
  setInterval(reloj, 1000);
  setInterval(sondear, 150);
  setInterval(rotarEspera, 6000);
  setInterval(rotarOfertaPanel, 5000);
  window.DISPCONFIG({});
  window.DISPUPDATE({ items: [], total: 0 });
  recibido = false;
  if (qs("estado")) { foto(qs("estado")); }
  else if (!qs("pos")) { setTimeout(function () { if (!recibido && !$("cfgdata").value) { demo(); } }, 1500); }
})();
</script>
</body>
</html>
   ENDTEXT
//HTML>>

   return cHtml

//=============================================================================
// Monitores
//=============================================================================

//-----------------------------------------------------------------------------
// Devuelve un array de hashes con la información de cada monitor.
//-----------------------------------------------------------------------------
static function ObtenerMonitores()

   local aMonitores := {}

   EnumDisplayMonitors( { | nMonitor, hMonitor, hdcMonitor, lPrimary, ;
                           aMonitorRect, aMonitorRectInfo, aWorkRect | ;
      AAdd( aMonitores, { ;
         "nMonitor"         => nMonitor, ;
         "hMonitor"         => hMonitor, ;
         "lPrimary"         => lPrimary, ;
         "aMonitorRect"     => aMonitorRect, ;
         "aMonitorRectInfo" => aMonitorRectInfo, ;
         "aWorkRect"        => aWorkRect } ), ;
      .T. } )

   return aMonitores

//-----------------------------------------------------------------------------
// Monitor donde va el display:
//   - monitor=N en el ini (1, 2, ...): ese, si existe (para PCs donde el
//     display del cliente quedó como monitor principal de Windows).
//   - si no: el primer monitor que no sea el principal.
//   - con un solo monitor: el principal solo si lForzar (Ctrl+F11).
//-----------------------------------------------------------------------------
static function ElegirMonitor( aMonitores, hCfg, lForzar )

   local n := Val( hCfg[ "monitor" ] )

   if n >= 1 .and. n <= Len( aMonitores )
      return aMonitores[ n ]
   endif
   if Len( aMonitores ) >= 2
      return BuscarSecundario( aMonitores )
   endif
   if Len( aMonitores ) >= 1 .and. lForzar
      return aMonitores[ 1 ]
   endif

   return nil

//-----------------------------------------------------------------------------
// Busca el primer monitor que NO sea el primario.
//-----------------------------------------------------------------------------
static function BuscarSecundario( aMonitores )

   local i

   for i := 1 to Len( aMonitores )
      if ! aMonitores[ i ][ "lPrimary" ]
         return aMonitores[ i ]
      endif
   next

return nil

// Hace el proceso DPI-aware: las APIs como EnumDisplayMonitors / GetMonitorInfo
// devuelven coords FISICAS reales en monitores con escalado >100% en vez de
// virtualizadas/escaladas. Disponible desde Windows Vista.
// (Ya NO se usa: era permanente y afectaba a TODA la app. Se reemplazó por
//  SetThreadDpiAwarenessContext, que es reversible y por hilo.)
DLL32 FUNCTION SetProcessDPIAware() AS BOOL PASCAL LIB "user32.dll"

// DPI-aware REVERSIBLE y por HILO. A diferencia de SetProcessDPIAware, solo
// afecta a las ventanas creadas en este hilo mientras el contexto está activo,
// y devuelve el contexto anterior para poder restaurarlo. Así el diálogo del 2º
// monitor se crea aware (coords físicas correctas) sin alterar la ventana
// principal del POS. Parámetro/retorno = DPI_AWARENESS_CONTEXT (-2 = SYSTEM
// AWARE). Existe desde Windows 10 1607: se busca en user32 en tiempo de
// ejecución (antes era DLL32), así en Windows 7/8 devuelve 0 y no hace nada en
// vez de dar error. Implementada en C al final de este archivo.

#pragma BEGINDUMP

#include <windows.h>
#include <hbapi.h>
#include <hbapiitm.h>

static int iMonitorCount;

static BOOL CALLBACK MonitorEnumProc( HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData )
{
    MONITORINFOEX mi;

    if( iMonitorCount >= MAX_MONITORS )
    {
       return FALSE;  // Stop enumeration if we've reached the maximum
    }

    mi.cbSize = sizeof( MONITORINFOEX );

    if( GetMonitorInfo( hMonitor, ( LPMONITORINFO ) &mi ) )
    {
       PHB_ITEM pMonitorCount   = hb_itemPutNL( NULL, ++iMonitorCount );
       PHB_ITEM pHandleMonitor  = hb_itemPutPtr( NULL, hMonitor );
       PHB_ITEM phdcMonitor     = hb_itemPutPtr( NULL, hdcMonitor );
       PHB_ITEM prctMonitor     = hb_itemArrayNew( 4 );
       PHB_ITEM pIsPrimary      = hb_itemPutL( NULL, ( mi.dwFlags & MONITORINFOF_PRIMARY) != 0 );
       PHB_ITEM prctMonitorInfo = hb_itemArrayNew( 4 );
       PHB_ITEM prctWork        = hb_itemArrayNew( 4 );

       PHB_ITEM pMonitorLeft    = hb_itemPutNL( NULL, lprcMonitor->left );
       PHB_ITEM pMonitorTop     = hb_itemPutNL( NULL, lprcMonitor->top );
       PHB_ITEM pMonitorBottom  = hb_itemPutNL( NULL, lprcMonitor->bottom );
       PHB_ITEM pMonitorRight   = hb_itemPutNL( NULL, lprcMonitor->right );

       PHB_ITEM pMonitorInfoLeft   = hb_itemPutNL( NULL, mi.rcMonitor.left );
       PHB_ITEM pMonitorInfoTop    = hb_itemPutNL( NULL, mi.rcMonitor.top );
       PHB_ITEM pMonitorInfoBottom = hb_itemPutNL( NULL, mi.rcMonitor.bottom );
       PHB_ITEM pMonitorInfoRight  = hb_itemPutNL( NULL, mi.rcMonitor.right );

       PHB_ITEM pWorkLeft   = hb_itemPutNL( NULL, mi.rcWork.left );
       PHB_ITEM pWorkTop    = hb_itemPutNL( NULL, mi.rcWork.top );
       PHB_ITEM pWorkBottom = hb_itemPutNL( NULL, mi.rcWork.bottom );
       PHB_ITEM pWorkRight  = hb_itemPutNL( NULL, mi.rcWork.right );

       hb_itemArrayPut( prctMonitor, 1, pMonitorLeft );
       hb_itemArrayPut( prctMonitor, 2, pMonitorTop );
       hb_itemArrayPut( prctMonitor, 3, pMonitorBottom );
       hb_itemArrayPut( prctMonitor, 4, pMonitorRight );

       hb_itemArrayPut( prctMonitorInfo, 1, pMonitorInfoLeft );
       hb_itemArrayPut( prctMonitorInfo, 2, pMonitorInfoTop );
       hb_itemArrayPut( prctMonitorInfo, 3, pMonitorInfoBottom );
       hb_itemArrayPut( prctMonitorInfo, 4, pMonitorInfoRight );

       hb_itemArrayPut( prctWork, 1, pWorkLeft );
       hb_itemArrayPut( prctWork, 2, pWorkTop );
       hb_itemArrayPut( prctWork, 3, pWorkBottom );
       hb_itemArrayPut( prctWork, 4, pWorkRight );

       hb_evalBlock( ( PHB_ITEM ) dwData, pMonitorCount, pHandleMonitor, phdcMonitor, pIsPrimary, prctMonitor,
                     prctMonitorInfo, prctWork, NULL );

       hb_itemRelease( pMonitorLeft );
       hb_itemRelease( pMonitorTop );
       hb_itemRelease( pMonitorBottom );
       hb_itemRelease( pMonitorRight );

       hb_itemRelease( pMonitorInfoLeft );
       hb_itemRelease( pMonitorInfoTop );
       hb_itemRelease( pMonitorInfoBottom );
       hb_itemRelease( pMonitorInfoRight );

       hb_itemRelease( pWorkLeft );
       hb_itemRelease( pWorkTop );
       hb_itemRelease( pWorkBottom );
       hb_itemRelease( pWorkRight );

       hb_itemRelease( prctWork );
       hb_itemRelease( prctMonitorInfo );
       hb_itemRelease( prctMonitor );
       hb_itemRelease( pIsPrimary );
       hb_itemRelease( phdcMonitor );
       hb_itemRelease( pHandleMonitor );
       hb_itemRelease( pMonitorCount );
    }

    return hb_parl( -1 );  // .T. continue enumeration
}

// SetThreadDpiAwarenessContext( nCtx ) -> nCtxAnterior (0 si el Windows no la tiene)
typedef HANDLE ( WINAPI * PFNSETTHREADDPICTX )( HANDLE );

HB_FUNC( SETTHREADDPIAWARENESSCONTEXT )
{
   static PFNSETTHREADDPICTX pfn = NULL;
   static int iBuscada = 0;

   if( ! iBuscada )
   {
      HMODULE hUser = GetModuleHandle( "user32.dll" );
      iBuscada = 1;
      if( hUser )
         pfn = ( PFNSETTHREADDPICTX ) GetProcAddress( hUser, "SetThreadDpiAwarenessContext" );
   }

   if( pfn )
      hb_retnl( ( LONG ) ( HB_PTRDIFF ) pfn( ( HANDLE ) ( HB_PTRDIFF ) hb_parnl( 1 ) ) );
   else
      hb_retnl( 0 );
}

HB_FUNC( ENUMDISPLAYMONITORS )
{
   iMonitorCount = 0;
   hb_retl( EnumDisplayMonitors( NULL, NULL, MonitorEnumProc, ( LPARAM ) hb_param( 1, HB_IT_BLOCK ) ) );
}

#pragma ENDDUMP
