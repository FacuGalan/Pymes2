#include "FiveWin.ch"
FUNCTION Main()
   LOCAL oAFIP, nUltimoComprobante
   LOCAL cCertFile := ".\DRIVERSFC\MiCertificado.crt"  // Rutas correctas
   LOCAL cPrivKeyFile := ".\DRIVERSFC\MiClavePrivada"
   
   // Verificar que existan los archivos
   IF !FILE(cCertFile)
      ? "Error: No se encuentra el archivo de certificado: " + cCertFile
      RETURN nil
   ENDIF
   
   IF !FILE(cPrivKeyFile)
      ? "Error: No se encuentra el archivo de clave privada: " + cPrivKeyFile
      RETURN nil
   ENDIF
   
   // Crear instancia de la clase WSAFip
   oAFIP := WSAFip():New("20214424666", .t.)
   
   // Intentar login para obtener Token y Sign
   IF oAFIP:Login(cCertFile, cPrivKeyFile, "wsfe")
      ? "Login exitoso!"
      
      // Consultar último número de comprobante para 
      // punto de venta 3 y tipo de comprobante 6 (Factura B)
      nUltimoComprobante := oAFIP:SFRecuperaLastCMP(3, 6)
      
      IF nUltimoComprobante > 0
         ? "Último comprobante: " + ALLTRIM(STR(nUltimoComprobante))
         
         // Ejemplo de carga de una factura B por $10
         // Tipo 6 (Factura B), CUIT, Nro documento, Nro factura, Total, No gravado, Neto, Exento
         IF oAFIP:AgregaFactura(6, 80, 30000000007, nUltimoComprobante + 1, 10.00, 0.00, 8.26, 0.00, , , , "PES", 1, 1, 5)
            ? "Factura agregada con éxito"
            
            // Agregar el IVA (21% sobre 8.26 = 1.74)
            oAFIP:AgregaIVA(5, 8.26, 1.74)  // 5 = Tasa 21%
            ? "IVA agregado"
            
            // Solicitar el CAE
            IF oAFIP:Autorizar(3, 6)
               ? "CAE obtenido: " + oAFIP:GetCAE()
               ? "Vencimiento: " + DTOC(oAFIP:GetCAEVto())
            ELSE
               ? "Error de autorización: " + oAFIP:GetLastError()
            ENDIF
         ELSE
            ? "Error al agregar factura: " + oAFIP:GetLastError()
         ENDIF
      ELSE
         ? "Error al consultar último comprobante: " + oAFIP:GetLastError()
      ENDIF
   ELSE
      ? "Error de login: " + oAFIP:GetLastError()
   ENDIF

RETURN nil
/**
 * WSAFip - Clase para trabajar con WebServices AFIP/ARCA
 * Para Harbour y FiveWin
 */
CLASS WSAFip

   DATA cToken         // Token de autenticación
   DATA cSign          // Firma de autenticación
   DATA cCuitRepresentada  // CUIT del representado
   DATA dTokenExpiry   // Fecha de expiración del token
   
   DATA cLastError     // Último mensaje de error
   DATA nLastCode      // Último código de error
   DATA aErrors        // Array de errores devueltos por WS
   DATA aObservaciones // Array de observaciones

   DATA cUrlWsaa       // URL del servicio de autenticación
   DATA cUrlWsfe       // URL del servicio de facturación
   
   DATA cCAE           // CAE obtenido
   DATA dCAEVto        // Fecha de vencimiento del CAE
   DATA cResultado     // Resultado de la operación (A: Aprobado, R: Rechazado)
   
   DATA aCabeceraFE    // Cabecera de la factura electrónica
   DATA aDetallesFE    // Array de detalles de factura
   DATA aIvaItems      // Array con detalles de IVA
   DATA aTributos      // Array con tributos
   DATA aCompAsociados // Array con comprobantes asociados
   DATA aActividades   // Array con actividades
   DATA cLogFile       // Archivo de log
   
   // Métodos públicos principales
   METHOD New(cCuit, lTestMode)
   METHOD Login(cCertFile, cPrivKeyFile, cService)
   METHOD SFRecuperaLastCMP(nPuntoVta, nTipoComp)
   METHOD Reset()
   METHOD AgregaFactura(nTipoFac, nTipoDoc, nNroDoc, nFacturaNro, nTotal, nNoGrav, nNeto, nExento, dFecDes, dFecHas, dFchVto, cMoneda, nCotiza, nConcepto)
   METHOD AgregaCompAsoc(nTipoComp, nPuntoVta, nComprAsoc, cCuit, dFechaComp)
   METHOD AgregaIVA(nTasa, nNeto, nIva)
   METHOD AgregaTributo(nCodigo, cDetalle, nBaseImp, nCoef, nImporte)
   METHOD AgregaActividad(nCodigo)
   METHOD Autorizar(nPuntoVta, nTipoComp)
   
   // Métodos de consulta
   METHOD ConsultaCAE(nPuntoVta, nTipoComp, nNumComp)
   METHOD GetTiposComprobantes()
   METHOD GetTiposDocumentos()
   METHOD GetTiposIva()
   METHOD GetTiposMonedas()
   METHOD GetTiposTributos()
   METHOD GetPuntosVenta()
   METHOD GetActividades()
   METHOD GetCondicionesIvaReceptor(cClaseComp)
   
   // Métodos auxiliares
   METHOD GetLastError()
   METHOD GetLastErrorCode()
   METHOD GetCAE()
   METHOD GetCAEVto()
   METHOD GetResultado()
   METHOD WriteLog(cMsg)
   
   // Métodos privados
   METHOD CheckTAExpired() PROTECTED
   METHOD GenerarTRA(cService) PROTECTED
   METHOD FirmarTRA(cTRA, cCertFile, cPrivKeyFile) PROTECTED
   METHOD EnviarTRA(cTraFirmadoBase64) PROTECTED
   METHOD ParseLoginTicketResponse(cResponse) PROTECTED
   METHOD GenerarXMLCAESolicitar() PROTECTED
   METHOD ParseFECAESolicitarResponse(cResponse) PROTECTED
   METHOD SendRequest(cURL, cAction, cXML) PROTECTED
   METHOD Base64Encode1(cData) PROTECTED
   METHOD Base64Decode1(cData) PROTECTED
   METHOD XMLEncode(cData) PROTECTED
   METHOD DateToWSDate(dDate) PROTECTED

ENDCLASS

/**
 * Constructor de la clase
 * @param cCuit      CUIT del representado
 * @param lTestMode  Modo de prueba (.T.) o producción (.F.)
 */
METHOD New(cCuit, lTestMode) CLASS WSAFip
   LOCAL cHomoUrl := "https://wswhomo.afip.gov.ar/"
   LOCAL cProdUrl := "https://servicios1.afip.gov.ar/"
   
   ::cCuitRepresentada := cCuit
   ::cToken := ""
   ::cSign := ""
   ::dTokenExpiry := CTOD("")
   
   ::cLastError := ""
   ::nLastCode := 0
   ::aErrors := {}
   ::aObservaciones := {}
   
   ::cCAE := ""
   ::dCAEVto := CTOD("")
   ::cResultado := ""
   
   IF lTestMode
      ::cUrlWsaa := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
      ::cUrlWsfe := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
   ELSE
      ::cUrlWsaa := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
      ::cUrlWsfe := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
   ENDIF
   
   ::aCabeceraFE := {0, 0, 0}  // CantReg, CbteTipo, PtoVta
   ::aDetallesFE := {}
   ::aIvaItems := {}
   ::aTributos := {}
   ::aCompAsociados := {}
   ::aActividades := {}
   
   ::cLogFile := "wsafip_" + DTOS(DATE()) + ".log"

RETURN SELF

/**
 * Login - Obtiene Token y Sign para autenticación
 * @param cCertFile   Ruta al archivo del certificado
 * @param cPrivKeyFile  Ruta al archivo de clave privada
 * @param cService    Servicio a utilizar (wsfe)
 * @return Logical   .T. si el login fue exitoso, .F. en caso contrario
 */
METHOD Login(cCertFile, cPrivKeyFile, cService) CLASS WSAFip
   LOCAL cLoginTicketResponse, cTA, cTra, cTraFirmado, cTraFirmadoBase64
   LOCAL lSuccess := .F.
   LOCAL cTAFilename := "TA_" + cService + ".xml"
   
   // Verificar si tenemos un TA válido almacenado localmente
   IF FILE(cTAFilename)
      ::WriteLog("Encontrado archivo TA local: " + cTAFilename)
      cTA := MemoRead(cTAFilename)
      
      // Extraer token, sign y expiration del archivo
      IF !EMPTY(cTA)
         IF AT("<token>", cTA) > 0
            ::cToken := SUBSTR(cTA, AT("<token>", cTA) + 7, AT("</token>", cTA) - AT("<token>", cTA) - 7)
         ENDIF
         
         IF AT("<sign>", cTA) > 0
            ::cSign := SUBSTR(cTA, AT("<sign>", cTA) + 6, AT("</sign>", cTA) - AT("<sign>", cTA) - 6)
         ENDIF
         
         IF AT("<expirationTime>", cTA) > 0
            cExpiration := SUBSTR(cTA, AT("<expirationTime>", cTA) + 16, AT("</expirationTime>", cTA) - AT("<expirationTime>", cTA) - 16)
            ::WriteLog("cExpiration: " + cExpiration)
            // Convertir fecha ISO a Date
            cExpYear := LEFT(cExpiration, 4)
            cExpMonth := SUBSTR(cExpiration, 6, 2)
            cExpDay := SUBSTR(cExpiration, 9, 2)
            
            ::dTokenExpiry := CTOD(cExpDay + "/" + cExpMonth + "/" + cExpYear)
         ENDIF
      ENDIF

      ::WriteLog("dTokenExpiry: " + DTOC(::dTokenExpiry))
      
      // Verificar si el TA almacenado es válido
      IF !EMPTY(::cToken) .AND. !EMPTY(::cSign) .AND. !EMPTY(::dTokenExpiry)
         IF ::dTokenExpiry > DATE()
            ::WriteLog("TA local válido encontrado. Expira: " + DTOC(::dTokenExpiry))
            RETURN .T.
         ELSE
            ::WriteLog("TA local expirado. Fecha expiración: " + DTOC(::dTokenExpiry))
            // Eliminar el archivo expirado para evitar confusiones
            FERASE(cTAFilename)
         ENDIF
      ENDIF
   ENDIF
   
   // Si llegamos aquí, no tenemos un TA válido almacenado, solicitamos uno nuevo
   ::WriteLog("Generando TRA para servicio " + cService)
   
   // Generar TRA (Ticket de Requerimiento de Acceso)
   cTRA := ::GenerarTRA(cService)
   IF EMPTY(cTRA)
      ::cLastError := "Error al generar TRA"
      ::nLastCode := 1001
      RETURN .F.
   ENDIF
   
   // Firmar el TRA
   ::WriteLog("Firmando TRA con certificado " + cCertFile)
   cTraFirmado := ::FirmarTRA(cTRA, cCertFile, cPrivKeyFile)
   IF EMPTY(cTraFirmado)
      ::cLastError := "Error al firmar TRA"
      ::nLastCode := 1002
      RETURN .F.
   ENDIF
   
   // Codificar en Base64
   cTraFirmadoBase64 := ::Base64Encode1(cTraFirmado)
   
   // Enviar solicitud a WSAA
   ::WriteLog("Enviando TRA a WSAA")
   cLoginTicketResponse := ::EnviarTRA(cTraFirmadoBase64)
   
   IF !EMPTY(cLoginTicketResponse)
      // Verificar si hay error de "ya autenticado"
      IF AT("coe.alreadyAuthenticated", cLoginTicketResponse) > 0
         ::WriteLog("Ya existe un TA válido para este servicio según WSAA")
         
         // Buscar el TA válido en la carpeta actual
         // Si existe un TA pero no lo encontramos antes, puede estar en otro formato
         // o ubicación que esperábamos
         IF ::BuscarTAExistente(cService)
            ::WriteLog("Se ha recuperado un TA existente")
            RETURN .T.
         ENDIF
         
         // Alternativamente, podríamos intentar una operación simple para ver si el 
         // certificado sigue siendo válido para AFIP
         ::WriteLog("No se pudo encontrar el TA existente. Generando uno nuevo con otro servicio...")
         
         // Intentar generar un nuevo TA con un servicio ligeramente diferente 
         // Solo para propósitos de prueba/bypass
         RETURN ::Login(cCertFile, cPrivKeyFile, cService + "_alt")
      ENDIF
      
      // Procesar respuesta normal
      lSuccess := ::ParseLoginTicketResponse(cLoginTicketResponse)
      
      IF lSuccess
         ::WriteLog("Login exitoso. Token obtenido con vencimiento " + DTOC(::dTokenExpiry))
         
         // Guardar el TA para uso futuro
         cTA := '<loginTicketResponse>' + ;
                '<header>' + ;
                '<expirationTime>' + SUBSTR(DTOS(::dTokenExpiry), 1, 4) + '-' + ;
                                   SUBSTR(DTOS(::dTokenExpiry), 5, 2) + '-' + ;
                                   SUBSTR(DTOS(::dTokenExpiry), 7, 2) + ;
                                   'T00:00:00.000-03:00</expirationTime>' + ;
                '</header>' + ;
                '<credentials>' + ;
                '<token>' + ::cToken + '</token>' + ;
                '<sign>' + ::cSign + '</sign>' + ;
                '</credentials>' + ;
                '</loginTicketResponse>'
         
         MemoWrit2(cTAFilename, cTA)
         ::WriteLog("TA guardado en archivo: " + cTAFilename)
      ELSE
         ::WriteLog("Error al procesar respuesta de login: " + ::cLastError)
      ENDIF
   ELSE
      ::cLastError := "Error al enviar solicitud de login"
      ::nLastCode := 1003
      ::WriteLog("Error al enviar solicitud de login")
   ENDIF
   
RETURN lSuccess

METHOD BuscarTAExistente(cService) CLASS WSAFip
   LOCAL cTAFilename := "TA_" + cService + ".xml"
   LOCAL cTAAlternativeFilename := "TA_" + cService + "*.xml"
   LOCAL cFileName, aFiles := DIRECTORY(cTAAlternativeFilename)
   LOCAL cTA, cExpiration, cExpYear, cExpMonth, cExpDay
   LOCAL lFound := .F.
   
   ::WriteLog("Buscando TA existente para el servicio " + cService)
   
   // Primera verificación - buscar archivos TA que puedan contener el TA del servicio
   FOR EACH cFileName IN aFiles
      cTA := MemoRead(cFileName[1])
      
      // Verificar si el archivo contiene un TA válido para el servicio
      IF AT("<service>" + cService + "</service>", cTA) > 0 .OR. ;
         AT("<service>" + cService, cTA) > 0
         
         // Extraer token, sign y expiration
         IF AT("<token>", cTA) > 0
            ::cToken := SUBSTR(cTA, AT("<token>", cTA) + 7, AT("</token>", cTA) - AT("<token>", cTA) - 7)
         ENDIF
         
         IF AT("<sign>", cTA) > 0
            ::cSign := SUBSTR(cTA, AT("<sign>", cTA) + 6, AT("</sign>", cTA) - AT("<sign>", cTA) - 6)
         ENDIF
         
         IF AT("<expirationTime>", cTA) > 0
            cExpiration := SUBSTR(cTA, AT("<expirationTime>", cTA) + 15, AT("</expirationTime>", cTA) - AT("<expirationTime>", cTA) - 15)
            
            // Convertir fecha ISO a Date
            cExpYear := LEFT(cExpiration, 4)
            cExpMonth := SUBSTR(cExpiration, 6, 2)
            cExpDay := SUBSTR(cExpiration, 9, 2)
            
            ::dTokenExpiry := CTOD(cExpDay + "/" + cExpMonth + "/" + cExpYear)
         ENDIF
         
         // Verificar si el TA sigue siendo válido
         IF !EMPTY(::cToken) .AND. !EMPTY(::cSign) .AND. !EMPTY(::dTokenExpiry)
            IF ::dTokenExpiry > DATE()
               ::WriteLog("TA válido encontrado en archivo alternativo: " + cFileName[1])
               
               // Guardar en el archivo estándar para futuras referencias
               MemoWrit2(cTAFilename, cTA)
               ::WriteLog("TA copiado a archivo estándar: " + cTAFilename)
               
               lFound := .T.
               EXIT
            ENDIF
         ENDIF
      ENDIF
   NEXT
   
   // Si no encontramos ningún TA válido, crear un archivo de marcador
   // para evitar intentar repetidamente
   IF !lFound
      ::WriteLog("No se encontró ningún TA válido para el servicio " + cService)
      
      // Crear archivo de marcador para indicar que buscamos y no encontramos
      MemoWrit2(cTAFilename + ".notfound", DTOC(DATE()) + " " + TIME())
   ENDIF
   
RETURN lFound

/**
 * SFRecuperaLastCMP - Obtiene el último número de comprobante autorizado
 * @param nPuntoVta  Punto de venta
 * @param nTipoComp  Tipo de comprobante
 * @return Numeric   Número del último comprobante o 0 en caso de error
 */
METHOD SFRecuperaLastCMP(nPuntoVta, nTipoComp) CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL nUltimo := 0
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode := 1004
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN 0
      ENDIF
   ENDIF
   
   ::WriteLog("Consulta de último comprobante - Pto.Vta: " + ALLTRIM(STR(nPuntoVta)) + ", Tipo: " + ALLTRIM(STR(nTipoComp)))
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FECompUltimoAutorizado>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '<ar:PtoVta>' + ALLTRIM(STR(nPuntoVta)) + '</ar:PtoVta>' + ;
           '<ar:CbteTipo>' + ALLTRIM(STR(nTipoComp)) + '</ar:CbteTipo>' + ;
           '</ar:FECompUltimoAutorizado>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud
   cResponse := ::SendRequest(::cUrlWsfe, "http://ar.gov.afip.dif.FEV1/FECompUltimoAutorizado", cXML)
   
   IF !EMPTY(cResponse)
      // Procesar respuesta - Extraer número de comprobante
      // Buscar patrón <CbteNro>XXXX</CbteNro>
      cNroComp := SUBSTR(cResponse, AT("<CbteNro>", cResponse) + 9, AT("</CbteNro>", cResponse) - AT("<CbteNro>", cResponse) - 9)
      
      IF !EMPTY(cNroComp)
         nUltimo := VAL(cNroComp)
         ::WriteLog("Último comprobante recuperado: " + ALLTRIM(STR(nUltimo)))
      ELSE
         // Verificar si hay errores
         IF AT("<Errors>", cResponse) > 0
            // Procesar errores
            cErrorMsg := SUBSTR(cResponse, AT("<Msg>", cResponse) + 5, AT("</Msg>", cResponse) - AT("<Msg>", cResponse) - 5)
            cErrorCode := SUBSTR(cResponse, AT("<Code>", cResponse) + 6, AT("</Code>", cResponse) - AT("<Code>", cResponse) - 6)
            
            ::cLastError := cErrorMsg
            ::nLastCode := VAL(cErrorCode)
            ::WriteLog("Error al recuperar último comprobante: " + ::cLastError + " (Código: " + cErrorCode + ")")
         ELSE
            ::cLastError := "Error desconocido al recuperar último comprobante"
            ::nLastCode := 1005
            ::WriteLog("Error desconocido al recuperar último comprobante")
         ENDIF
      ENDIF
   ELSE
      ::cLastError := "Error al enviar solicitud de último comprobante"
      ::nLastCode := 1006
      ::WriteLog("Error al enviar solicitud de último comprobante")
   ENDIF
   
RETURN nUltimo

/**
 * Reset - Limpia los datos cargados para un nuevo comprobante
 */
METHOD Reset() CLASS WSAFip
   ::aCabeceraFE := {0, 0, 0}  // CantReg, CbteTipo, PtoVta
   ::aDetallesFE := {}
   ::aIvaItems := {}
   ::aTributos := {}
   ::aCompAsociados := {}
   ::aActividades := {}
   
   ::cCAE := ""
   ::dCAEVto := CTOD("")
   ::cResultado := ""
   ::aErrors := {}
   ::aObservaciones := {}
   
   ::WriteLog("Reset completado - Datos de comprobante limpiados")
RETURN NIL

/**
 * AgregaFactura - Agrega datos básicos de la factura
 * @param nTipoFac    Tipo de comprobante
 * @param nTipoDoc    Tipo de documento del receptor
 * @param nNroDoc     Número de documento del receptor
 * @param nFacturaNro Número de factura
 * @param nTotal      Importe total
 * @param nNoGrav     Importe no gravado
 * @param nNeto       Importe neto gravado
 * @param nExento     Importe exento
 * @param dFecDes     Fecha servicio desde (opcional)
 * @param dFecHas     Fecha servicio hasta (opcional)
 * @param dFchVto     Fecha vencimiento pago (opcional)
 * @param cMoneda     Moneda (por defecto PES)
 * @param nCotiza     Cotización (por defecto 1)
 * @param nConcepto   Concepto (1=Productos, 2=Servicios, 3=Ambos)
 * @return Logical    .T. si los datos son válidos
 */
METHOD AgregaFactura(nTipoFac, nTipoDoc, nNroDoc, nFacturaNro, nTotal, nNoGrav, nNeto, nExento, dFecDes, dFecHas, dFchVto, cMoneda, nCotiza, nConcepto, nCondicionIVA) CLASS WSAFip
   LOCAL aDetalle := {}
   
   // Valores por defecto
   DEFAULT cMoneda := "PES"
   DEFAULT nCotiza := 1
   DEFAULT nConcepto := 1
   DEFAULT nCondicionIVA := 5  // Por defecto Consumidor Final
   
   // Limpia datos previos
   ::aDetallesFE := {}
   
   // Configurar cabecera
   ::aCabeceraFE[1] := 1  // CantReg = 1
   ::aCabeceraFE[2] := nTipoFac  // CbteTipo
   
   // Crear detalle
   aDetalle := {;
      nConcepto,;    // Concepto
      nTipoDoc,;     // DocTipo
      nNroDoc,;      // DocNro
      nFacturaNro,;  // CbteDesde
      nFacturaNro,;  // CbteHasta
      "",;           // CbteFch (se completará en Autorizar)
      nTotal,;       // ImpTotal
      nNoGrav,;      // ImpTotConc
      nNeto,;        // ImpNeto
      nExento,;      // ImpOpEx
      0,;            // ImpTrib (se calculará en Autorizar)
      0,;            // ImpIVA (se calculará en Autorizar)
      ::DateToWSDate(dFecDes),; // FchServDesde
      ::DateToWSDate(dFecHas),; // FchServHasta
      ::DateToWSDate(dFchVto),; // FchVtoPago
      cMoneda,;      // MonId
      nCotiza,;      // MonCotiz
      nCondicionIVA;             // CondicionIVAReceptorId 
   }
   
   AADD(::aDetallesFE, aDetalle)
   ::WriteLog("Factura agregada - Tipo: " + ALLTRIM(STR(nTipoFac)) + ", Nro: " + ALLTRIM(STR(nFacturaNro)) + ", Total: " + ALLTRIM(STR(nTotal)))
   
RETURN .T.

/**
 * AgregaCompAsoc - Agrega un comprobante asociado
 * @param nTipoComp   Tipo de comprobante asociado
 * @param nPuntoVta   Punto de venta del comprobante asociado
 * @param nComprAsoc  Número de comprobante asociado
 * @param cCuit       CUIT del emisor del comprobante asociado
 * @param dFechaComp  Fecha del comprobante asociado
 * @return Logical    .T. si se agregó correctamente
 */
METHOD AgregaCompAsoc(nTipoComp, nPuntoVta, nComprAsoc, cCuit, dFechaComp) CLASS WSAFip
   LOCAL aCompAsoc := {}
   
   aCompAsoc := {;
      nTipoComp,;
      nPuntoVta,;
      nComprAsoc,;
      cCuit,;
      ::DateToWSDate(dFechaComp);
   }
   
   AADD(::aCompAsociados, aCompAsoc)
   ::WriteLog("Comprobante asociado agregado - Tipo: " + ALLTRIM(STR(nTipoComp)) + ", Pto.Vta: " + ALLTRIM(STR(nPuntoVta)) + ", Nro: " + ALLTRIM(STR(nComprAsoc)))
   
RETURN .T.

/**
 * AgregaIVA - Agrega un ítem de IVA
 * @param nTasa       Identificador de tipo de IVA (5=21%, 4=10.5%, etc.)
 * @param nNeto       Base imponible
 * @param nIva        Importe de IVA
 * @return Logical    .T. si se agregó correctamente
 */
METHOD AgregaIVA(nTasa, nNeto, nIva) CLASS WSAFip
   LOCAL aIvaItem := {}
   
   aIvaItem := {;
      nTasa,;  // Id
      nNeto,;  // BaseImp
      nIva;    // Importe
   }
   
   AADD(::aIvaItems, aIvaItem)
   ::WriteLog("Ítem IVA agregado - Tasa: " + ALLTRIM(STR(nTasa)) + ", Base: " + ALLTRIM(STR(nNeto)) + ", Importe: " + ALLTRIM(STR(nIva)))
   
RETURN .T.

/**
 * AgregaTributo - Agrega un tributo
 * @param nCodigo     Código de tributo
 * @param cDetalle    Descripción del tributo
 * @param nBaseImp    Base imponible
 * @param nCoef       Alícuota
 * @param nImporte    Importe del tributo
 * @return Logical    .T. si se agregó correctamente
 */
METHOD AgregaTributo(nCodigo, cDetalle, nBaseImp, nCoef, nImporte) CLASS WSAFip
   LOCAL aTributo := {}
   
   aTributo := {;
      nCodigo,;    // Id
      cDetalle,;   // Desc
      nBaseImp,;   // BaseImp
      nCoef,;      // Alic
      nImporte;    // Importe
   }
   
   AADD(::aTributos, aTributo)
   ::WriteLog("Tributo agregado - Código: " + ALLTRIM(STR(nCodigo)) + ", Detalle: " + cDetalle + ", Importe: " + ALLTRIM(STR(nImporte)))
   
RETURN .T.

/**
 * AgregaActividad - Agrega una actividad
 * @param nCodigo     Código de actividad
 * @return Logical    .T. si se agregó correctamente
 */
METHOD AgregaActividad(nCodigo) CLASS WSAFip
   AADD(::aActividades, nCodigo)
   ::WriteLog("Actividad agregada - Código: " + ALLTRIM(STR(nCodigo)))
   
RETURN .T.

/**
 * Autorizar - Solicita autorización para el comprobante
 * @param nPuntoVta   Punto de venta
 * @param nTipoComp   Tipo de comprobante
 * @return Logical    .T. si el comprobante fue autorizado, .F. en caso contrario
 */
METHOD Autorizar(nPuntoVta, nTipoComp) CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL lSuccess := .F.
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode  := 1016
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN .F.
      ENDIF
   ENDIF
   
   // Verificar que haya datos cargados
   IF LEN(::aDetallesFE) == 0
      ::cLastError := "No hay datos de factura para autorizar"
      ::nLastCode  := 1017
      ::WriteLog("No hay datos de factura para autorizar")
      RETURN .F.
   ENDIF
   
   // Establecer el punto de venta en la cabecera
   ::aCabeceraFE[3] := nPuntoVta
   
   // Verificar que el tipo de comprobante coincida
   IF ::aCabeceraFE[2] != nTipoComp
      ::cLastError := "El tipo de comprobante no coincide con el cargado"
      ::nLastCode  := 1018
      ::WriteLog("El tipo de comprobante no coincide: Cargado=" + ALLTRIM(STR(::aCabeceraFE[2])) + ", Solicitado=" + ALLTRIM(STR(nTipoComp)))
      RETURN .F.
   ENDIF
   
   ::WriteLog("Iniciando autorización - Pto.Vta: " + ALLTRIM(STR(nPuntoVta)) + ", Tipo: " + ALLTRIM(STR(nTipoComp)))
   
   // Generar XML para SOAP
   cXML := ::GenerarXMLCAESolicitar()
   
   // Enviar solicitud
   cResponse := ::SendRequest(::cUrlWsfe, "http://ar.gov.afip.dif.FEV1/FECAESolicitar", cXML)
   
   IF !EMPTY(cResponse)
      // Procesar respuesta
      lSuccess := ::ParseFECAESolicitarResponse(cResponse)
   ELSE
      ::cLastError := "Error al enviar solicitud de autorización"
      ::nLastCode  := 1019
      ::WriteLog("Error al enviar solicitud de autorización")
   ENDIF
   
RETURN lSuccess

/**
 * ConsultaCAE - Consulta un comprobante por CAE
 * @param nPuntoVta   Punto de venta
 * @param nTipoComp   Tipo de comprobante
 * @param nNumComp    Número de comprobante
 * @return Logical    .T. si la consulta fue exitosa, .F. en caso contrario
 */
METHOD ConsultaCAE(nPuntoVta, nTipoComp, nNumComp) CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL lSuccess := .F.
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode  := 1020
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN .F.
      ENDIF
   ENDIF
   
   ::WriteLog("Consulta de comprobante - Pto.Vta: " + ALLTRIM(STR(nPuntoVta)) + ", Tipo: " + ALLTRIM(STR(nTipoComp)) + ", Nro: " + ALLTRIM(STR(nNumComp)))
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FECompConsultar>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '<ar:FeCompConsReq>' + ;
           '<ar:CbteTipo>' + ALLTRIM(STR(nTipoComp)) + '</ar:CbteTipo>' + ;
           '<ar:CbteNro>' + ALLTRIM(STR(nNumComp)) + '</ar:CbteNro>' + ;
           '<ar:PtoVta>' + ALLTRIM(STR(nPuntoVta)) + '</ar:PtoVta>' + ;
           '</ar:FeCompConsReq>' + ;
           '</ar:FECompConsultar>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud
   cResponse := ::SendRequest(::cUrlWsfe, "http://ar.gov.afip.dif.FEV1/FECompConsultar", cXML)
   
   IF !EMPTY(cResponse)
      // Limpiar datos anteriores
      ::Reset()
      
      // Procesar respuesta - Extraer CAE y otros datos
      IF AT("<CAE>", cResponse) > 0
         ::cCAE := SUBSTR(cResponse, AT("<CAE>", cResponse) + 5, AT("</CAE>", cResponse) - AT("<CAE>", cResponse) - 5)
         ::cResultado := SUBSTR(cResponse, AT("<Resultado>", cResponse) + 11, AT("</Resultado>", cResponse) - AT("<Resultado>", cResponse) - 11)
         
         cFchVto := SUBSTR(cResponse, AT("<FchVto>", cResponse) + 8, AT("</FchVto>", cResponse) - AT("<FchVto>", cResponse) - 8)
         IF !EMPTY(cFchVto)
            ::dCAEVto := STOD(SUBSTR(cFchVto, 1, 4) + SUBSTR(cFchVto, 5, 2) + SUBSTR(cFchVto, 7, 2))
         ENDIF
         
         ::WriteLog("Consulta exitosa - CAE: " + ::cCAE + ", Resultado: " + ::cResultado)
         lSuccess := .T.
      ELSE
         // Verificar si hay errores
         IF AT("<Errors>", cResponse) > 0
            // Procesar errores
            cErrorMsg := SUBSTR(cResponse, AT("<Msg>", cResponse) + 5, AT("</Msg>", cResponse) - AT("<Msg>", cResponse) - 5)
            cErrorCode := SUBSTR(cResponse, AT("<Code>", cResponse) + 6, AT("</Code>", cResponse) - AT("<Code>", cResponse) - 6)
            
            ::cLastError := cErrorMsg
            ::nLastCode := VAL(cErrorCode)
            ::WriteLog("Error en consulta de comprobante: " + ::cLastError + " (Código: " + cErrorCode + ")")
         ELSE
            ::cLastError := "Error desconocido en consulta de comprobante"
            ::nLastCode := 1021
            ::WriteLog("Error desconocido en consulta de comprobante")
         ENDIF
      ENDIF
   ELSE
      ::cLastError := "Error al enviar solicitud de consulta de comprobante"
      ::nLastCode := 1022
      ::WriteLog("Error al enviar solicitud de consulta de comprobante")
   ENDIF
   
RETURN lSuccess

/**
 * GetTiposComprobantes - Obtiene los tipos de comprobantes
 * @return Array    Array con tipos de comprobantes o NIL si hay error
 */
METHOD GetTiposComprobantes() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aTipos := {}
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode := 1023
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN NIL
      ENDIF
   ENDIF
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FEParamGetTiposCbte>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '</ar:FEParamGetTiposCbte>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud
   cResponse := ::SendRequest(::cUrlWsfe, "http://ar.gov.afip.dif.FEV1/FEParamGetTiposCbte", cXML)
   
   IF !EMPTY(cResponse)
      // Procesar respuesta - Extraer los tipos de comprobantes
      // Implementar un parser XML para extraer los elementos CbteTipo
      // Este es un ejemplo simplificado
      
      // Para cada <CbteTipo> en el response, extraer <Id> y <Desc>
      nPos := 1
      DO WHILE .T.
         nIniTag := AT("<CbteTipo>", SUBSTR(cResponse, nPos))
         IF nIniTag == 0
            EXIT
         ENDIF
         
         nIniTag := nPos + nIniTag - 1
         nFinTag := AT("</CbteTipo>", SUBSTR(cResponse, nIniTag)) + nIniTag + 10
         
         cTipoData := SUBSTR(cResponse, nIniTag, nFinTag - nIniTag)
         
         cId := SUBSTR(cTipoData, AT("<Id>", cTipoData) + 4, AT("</Id>", cTipoData) - AT("<Id>", cTipoData) - 4)
         cDesc := SUBSTR(cTipoData, AT("<Desc>", cTipoData) + 6, AT("</Desc>", cTipoData) - AT("<Desc>", cTipoData) - 6)
         
         AADD(aTipos, {VAL(cId), cDesc})
         
         nPos := nFinTag
      ENDDO
      
      ::WriteLog("Obtenidos " + ALLTRIM(STR(LEN(aTipos))) + " tipos de comprobantes")
   ELSE
      ::cLastError := "Error al obtener tipos de comprobantes"
      ::nLastCode := 1024
      ::WriteLog("Error al obtener tipos de comprobantes")
      RETURN NIL
   ENDIF
   
RETURN aTipos

/**
 * GetTiposDocumentos - Obtiene los tipos de documentos
 * @return Array    Array con tipos de documentos o NIL si hay error
 */
METHOD GetTiposDocumentos() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aTipos := {}
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode := 1025
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN NIL
      ENDIF
   ENDIF
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FEParamGetTiposDoc>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '</ar:FEParamGetTiposDoc>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud y procesar respuesta similar a GetTiposComprobantes
   cResponse := ::SendRequest(::cUrlWsfe, "http://ar.gov.afip.dif.FEV1/FEParamGetTiposDoc", cXML)
   
   // Procesar respuesta (similar a GetTiposComprobantes pero con tags DocTipo)
   // Implementación simplificada
   
RETURN aTipos

/**
 * GetTiposIva - Obtiene los tipos de alícuotas de IVA
 * @return Array    Array con tipos de IVA o NIL si hay error
 */
METHOD GetTiposIva() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aTipos := {}
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode := 1026
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN NIL
      ENDIF
   ENDIF
   
   // Generar XML para SOAP para FEParamGetTiposIva
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FEParamGetTiposIva>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '</ar:FEParamGetTiposIva>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud y procesar respuesta
   
RETURN aTipos

/**
 * GetTiposMonedas - Obtiene los tipos de monedas
 * @return Array    Array con tipos de monedas o NIL si hay error
 */
METHOD GetTiposMonedas() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aTipos := {}
   
   // Implementación similar a los métodos anteriores para FEParamGetTiposMonedas
   
RETURN aTipos

/**
 * GetTiposTributos - Obtiene los tipos de tributos
 * @return Array    Array con tipos de tributos o NIL si hay error
 */
METHOD GetTiposTributos() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aTipos := {}
   
   // Implementación similar a los métodos anteriores para FEParamGetTiposTributos
   
RETURN aTipos

/**
 * GetPuntosVenta - Obtiene los puntos de venta
 * @return Array    Array con puntos de venta o NIL si hay error
 */
METHOD GetPuntosVenta() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aPuntos := {}
   
   // Implementación para FEParamGetPtosVenta
   
RETURN aPuntos

/**
 * GetActividades - Obtiene las actividades del contribuyente
 * @return Array    Array con actividades o NIL si hay error
 */
METHOD GetActividades() CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aActividades := {}
   
   // Implementación para FEParamGetActividades
   
RETURN aActividades

/**
 * GetCondicionesIvaReceptor - Obtiene las condiciones de IVA para el receptor
 * @param cClaseComp  Clase de comprobante (A, B, C o M)
 * @return Array      Array con condiciones o NIL si hay error
 */
METHOD GetCondicionesIvaReceptor(cClaseComp) CLASS WSAFip
   LOCAL cXML, cResponse
   LOCAL aCondiciones := {}
   
   // Verificar que tengamos Token y Sign
   IF EMPTY(::cToken) .OR. EMPTY(::cSign)
      IF !::CheckTAExpired()
         // TA válido, usar Token y Sign
      ELSE
         ::cLastError := "Se requiere login para obtener Token y Sign"
         ::nLastCode := 1027
         ::WriteLog("Se requiere login para obtener Token y Sign")
         RETURN NIL
      ENDIF
   ENDIF
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FEParamGetCondicionIvaReceptor>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '<ar:ClaseCmp>' + cClaseComp + '</ar:ClaseCmp>' + ;
           '</ar:FEParamGetCondicionIvaReceptor>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
   // Enviar solicitud y procesar respuesta
   
RETURN aCondiciones

/**
 * Métodos de obtención de datos
 */
METHOD GetLastError() CLASS WSAFip
RETURN ::cLastError

METHOD GetLastErrorCode() CLASS WSAFip
RETURN ::nLastCode

METHOD GetCAE() CLASS WSAFip
RETURN ::cCAE

METHOD GetCAEVto() CLASS WSAFip
RETURN ::dCAEVto

METHOD GetResultado() CLASS WSAFip
RETURN ::cResultado

/**
 * WriteLog - Escribe mensaje en el archivo de log
 * @param cMsg  Mensaje a escribir
 */
METHOD WriteLog(cMsg) CLASS WSAFip
   LOCAL nHandle, cTimeStamp
   
   cTimeStamp := DTOC(DATE()) + " " + TIME()
   
   nHandle := FOPEN(::cLogFile, 1)
   IF nHandle < 0
      nHandle := FCREATE(::cLogFile)
   ELSE
      FSEEK(nHandle, 0, 2)  // Ir al final del archivo
   ENDIF
   
   IF nHandle >= 0
      FWRITE(nHandle, cTimeStamp + " - " + cMsg + CRLF)
      FCLOSE(nHandle)
   ENDIF
   
RETURN NIL

/**
 * CheckTAExpired - Verifica si el Token de Acceso ha expirado
 * @return Logical   .T. si ha expirado o no existe, .F. si está vigente
 */
METHOD CheckTAExpired() CLASS WSAFip
   LOCAL lExpired := .T.
   
   IF !EMPTY(::cToken) .AND. !EMPTY(::cSign) .AND. !EMPTY(::dTokenExpiry)
      IF DATE() < ::dTokenExpiry
         lExpired := .F.
      ENDIF
   ENDIF
   
RETURN lExpired

/**
 * GenerarTRA - Genera el XML de Ticket de Requerimiento de Acceso
 * @param cService   Nombre del servicio (wsfe)
 * @return String    XML del TRA generado o cadena vacía en caso de error
 */
METHOD GenerarTRA(cService) CLASS WSAFip
   LOCAL cTRA := ""
   LOCAL cUniqueId, cGenerationTime, cExpirationTime
   LOCAL dNow, dTomorrow, cDateTime
   
   // Generar ID único
   cUniqueId := ALLTRIM(STR(INT(SECONDS() * 100)))
   
   // Obtener fecha y hora actual
   dNow := DATE()
   dTomorrow := dNow + 1
   
   // Formato ISO 8601 exacto que espera AFIP
   // Formato: YYYY-MM-DDThh:mm:ss-03:00
   cGenerationTime := SUBSTR(DTOS(dNow), 1, 4) + "-" + ;
                      SUBSTR(DTOS(dNow), 5, 2) + "-" + ;
                      SUBSTR(DTOS(dNow), 7, 2) + "T" + ;
                      TIME() + "-03:00"
   
   cExpirationTime := SUBSTR(DTOS(dTomorrow), 1, 4) + "-" + ;
                      SUBSTR(DTOS(dTomorrow), 5, 2) + "-" + ;
                      SUBSTR(DTOS(dTomorrow), 7, 2) + "T" + ;
                      TIME() + "-03:00"
   
   // Crear XML del TRA
   cTRA := '<?xml version="1.0" encoding="UTF-8"?>' + ;
           '<loginTicketRequest version="1.0">' + ;
           '<header>' + ;
           '<uniqueId>' + cUniqueId + '</uniqueId>' + ;
           '<generationTime>' + cGenerationTime + '</generationTime>' + ;
           '<expirationTime>' + cExpirationTime + '</expirationTime>' + ;
           '</header>' + ;
           '<service>' + cService + '</service>' + ;
           '</loginTicketRequest>'
   
RETURN cTRA

/**
 * FirmarTRA - Firma el TRA con certificado y clave privada
 * @param cTRA         XML del TRA
 * @param cCertFile    Ruta al archivo del certificado
 * @param cPrivKeyFile Ruta al archivo de clave privada
 * @return String      TRA firmado o cadena vacía en caso de error
 */
METHOD FirmarTRA(cTRA, cCertFile, cPrivKeyFile) CLASS WSAFip
   LOCAL cTraFirmado := ""
   LOCAL cComando
   
   // Guardar TRA en archivo temporal
   MemoWrit2("tra_temp.xml", cTRA)
   ::WriteLog("TRA guardado en tra_temp.xml para firmar")
   
   // Comando OpenSSL específico para AFIP
   cComando := ".\DRIVERSFC\openssl cms -sign -in tra_temp.xml -out tra_signed.cms" + ;
               " -signer .\DRIVERSFC\MiCertificado.crt" + ;
               " -inkey .\DRIVERSFC\MiClavePrivada" + ;
               " -nodetach -outform DER -md sha256" + ;
               " -binary -keyform PEM -certform PEM"
   
   ::WriteLog("Ejecutando comando: " + cComando)
   
   // Ejecutar comando OpenSSL
   WaitRun(cComando, 0)
   
   // Verificar si se generó el archivo
   IF FILE("tra_signed.cms")
      ::WriteLog("Archivo tra_signed.cms generado correctamente")
      cTraFirmado := MemoRead("tra_signed.cms")
      ::WriteLog("Tamaño del archivo firmado: " + ALLTRIM(STR(LEN(cTraFirmado))) + " bytes")
   ELSE
      ::cLastError := "Error al firmar TRA con OpenSSL: El archivo tra_signed.cms no fue generado"
      ::nLastCode := 1010
      ::WriteLog("Error al firmar TRA con OpenSSL: El archivo tra_signed.cms no fue generado")
   ENDIF
   
RETURN cTraFirmado

/**
 * EnviarTRA - Envía el TRA al servicio de autenticación (WSAA)
 * @param cTraFirmadoBase64  TRA firmado codificado en Base64
 * @return String           Respuesta XML del servicio o cadena vacía en caso de error
 */
METHOD EnviarTRA(cTraFirmadoBase64) CLASS WSAFip
   LOCAL cXML, cResponse
   
   // Verificar que tenemos datos para enviar
   IF EMPTY(cTraFirmadoBase64)
      ::cLastError := "No hay datos CMS válidos para enviar"
      ::nLastCode := 1080
      ::WriteLog("Error: No hay datos CMS válidos para enviar")
      RETURN ""
   ENDIF
   
   ::WriteLog("Tamaño del CMS codificado en Base64: " + ALLTRIM(STR(LEN(cTraFirmadoBase64))) + " bytes")
   
   // Verificación básica del contenido Base64
   IF LEN(cTraFirmadoBase64) < 100
      ::cLastError := "El CMS codificado parece demasiado corto o vacío"
      ::nLastCode := 1060
      ::WriteLog("Error: El CMS codificado parece demasiado corto o vacío")
      RETURN ""
   ENDIF
   
   // Guardar el CMS codificado para verificación
   MemoWrit2("cms_base64.txt", cTraFirmadoBase64)
   ::WriteLog("CMS codificado guardado en cms_base64.txt para verificación")
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsaa="http://wsaa.view.sua.dvadac.desein.afip.gov">' + ;
       '<soapenv:Header/>' + ;
       '<soapenv:Body>' + ;
       '<wsaa:loginCms>' + ;
       '<wsaa:in0>' + cTraFirmadoBase64 + '</wsaa:in0>' + ;
       '</wsaa:loginCms>' + ;
       '</soapenv:Body>' + ;
       '</soapenv:Envelope>'
   
   // Guardar para depuración
   MemoWrit2("wsaa_request.xml", cXML)
   
   // Enviar solicitud al WSAA
   cResponse := ::SendRequest(::cUrlWsaa, "http://wsaa.view.sua.dvadac.desein.afip.gov/loginCms", cXML)
   
   // Guardar respuesta para depuración
   IF !EMPTY(cResponse)
      MemoWrit2("wsaa_response.xml", cResponse)
      
      // Decodificar caracteres especiales XML 
      cResponse := STRTRAN(cResponse, "&lt;", "<")
      cResponse := STRTRAN(cResponse, "&gt;", ">")
      cResponse := STRTRAN(cResponse, "&quot;", '"')
      cResponse := STRTRAN(cResponse, "&apos;", "'")
      cResponse := STRTRAN(cResponse, "&amp;", "&")
      
      // Guardar la versión decodificada
      MemoWrit2("wsaa_response_decoded.xml", cResponse)
   ENDIF
   
RETURN cResponse

/**
 * ParseLoginTicketResponse - Procesa la respuesta del WSAA
 * @param cResponse  Respuesta XML del WSAA
 * @return Logical   .T. si se procesó correctamente, .F. en caso de error
 */
METHOD ParseLoginTicketResponse(cResponse) CLASS WSAFip
   LOCAL lSuccess := .F.
   LOCAL cToken, cSign, cExpiration
   LOCAL cCdata, cLoginCmsReturn
   
   // Guardar la respuesta para depuración
   MemoWrit2("login_response_full.xml", cResponse)
   ::WriteLog("Respuesta completa guardada en login_response_full.xml")
   
   // Buscar patrones en la respuesta
   ::WriteLog("Analizando respuesta para extraer credenciales...")
   
   // Verificar si hay un error en la respuesta
   IF AT("<faultstring>", cResponse) > 0
      cErrorMsg := SUBSTR(cResponse, AT("<faultstring>", cResponse) + 13, AT("</faultstring>", cResponse) - AT("<faultstring>", cResponse) - 13)
      ::WriteLog("Error reportado por AFIP: " + cErrorMsg)
      ::cLastError := cErrorMsg
      ::nLastCode := 1099
      RETURN .F.
   ENDIF
   
   // Extraer el elemento loginCmsReturn
   cLoginCmsReturn := ""
   IF AT("<loginCmsReturn>", cResponse) > 0 .AND. AT("</loginCmsReturn>", cResponse) > 0
      nStart := AT("<loginCmsReturn>", cResponse) + 16
      nEnd := AT("</loginCmsReturn>", cResponse)
      cLoginCmsReturn := SUBSTR(cResponse, nStart, nEnd - nStart)
      ::WriteLog("Contenido de loginCmsReturn extraído, longitud: " + ALLTRIM(STR(LEN(cLoginCmsReturn))))
   ENDIF
   
   // Buscar elementos de autenticación
   // 1. Buscar token
   IF AT("<token>", cResponse) > 0 .AND. AT("</token>", cResponse) > 0
      nStart := AT("<token>", cResponse) + 7
      nEnd := AT("</token>", cResponse)
      ::cToken := SUBSTR(cResponse, nStart, nEnd - nStart)
      ::WriteLog("Token extraído, longitud: " + ALLTRIM(STR(LEN(::cToken))))
   ENDIF
   
   // 2. Buscar sign
   IF AT("<sign>", cResponse) > 0 .AND. AT("</sign>", cResponse) > 0
      nStart := AT("<sign>", cResponse) + 6
      nEnd := AT("</sign>", cResponse)
      ::cSign := SUBSTR(cResponse, nStart, nEnd - nStart)
      ::WriteLog("Sign extraído, longitud: " + ALLTRIM(STR(LEN(::cSign))))
   ENDIF
   
   // 3. Buscar fecha de expiración
   IF AT("<expirationTime>", cResponse) > 0 .AND. AT("</expirationTime>", cResponse) > 0
      nStart := AT("<expirationTime>", cResponse) + 15
      nEnd := AT("</expirationTime>", cResponse)
      cExpiration := SUBSTR(cResponse, nStart, nEnd - nStart)
      ::WriteLog("Valor de expirationTime extraído: '" + cExpiration + "'")
      
      // Extracción más flexible de la fecha
      // El formato es: 2025-03-08T01:22:56.044-03:00
      // Queremos extraer solo 2025-03-08
      IF LEN(cExpiration) >= 10  // Asegurar que tenga suficientes caracteres
         cExpYear := SUBSTR(cExpiration, 1, 4)
         cExpMonth := SUBSTR(cExpiration, 6, 2)
         cExpDay := SUBSTR(cExpiration, 9, 2)
         
         ::WriteLog("Componentes de fecha: Año=" + cExpYear + ", Mes=" + cExpMonth + ", Día=" + cExpDay)
         
         // Validar componentes de fecha
         IF VAL(cExpYear) >= 2023 .AND. VAL(cExpMonth) >= 1 .AND. VAL(cExpMonth) <= 12 .AND. ;
            VAL(cExpDay) >= 1 .AND. VAL(cExpDay) <= 31
            
            ::dTokenExpiry := CTOD(cExpDay + "/" + cExpMonth + "/" + cExpYear)
            ::WriteLog("Fecha de expiración convertida: " + DTOC(::dTokenExpiry))
         ELSE
            ::WriteLog("Error: Componentes de fecha inválidos")
            // Intentar una alternativa - usar la fecha actual + 1 día como fallback
            ::dTokenExpiry := DATE() + 1
            ::WriteLog("Usando fecha alternativa: " + DTOC(::dTokenExpiry))
         ENDIF
      ELSE
         ::WriteLog("Error: Formato de expirationTime inesperado - muy corto")
         // Fallback: usar la fecha actual + 1 día
         ::dTokenExpiry := DATE() + 1
         ::WriteLog("Usando fecha alternativa: " + DTOC(::dTokenExpiry))
      ENDIF
   ELSE
      ::WriteLog("Error: No se encontró el elemento expirationTime")
      // Fallback: usar la fecha actual + 1 día
      ::dTokenExpiry := DATE() + 1
      ::WriteLog("Usando fecha alternativa: " + DTOC(::dTokenExpiry))
   ENDIF
   
   // Verificar si tenemos token y sign 
   IF !EMPTY(::cToken) .AND. !EMPTY(::cSign) .AND. !EMPTY(::dTokenExpiry)
      lSuccess := .T.
      ::WriteLog("Extracción de credenciales exitosa - Token, Sign y Fecha de Expiración obtenidos")
   ELSE
      ::cLastError := "Error al extraer credenciales del LoginTicketResponse"
      ::nLastCode := 1011
      ::WriteLog("Error al extraer credenciales del LoginTicketResponse")
      
      // Mostrar más información sobre el contenido
      ::WriteLog("Contenido de la respuesta (resumen):")
      ::WriteLog("Longitud total: " + ALLTRIM(STR(LEN(cResponse))))
      
      // Mostrar el inicio del XML para diagnóstico
      IF LEN(cResponse) > 300
         ::WriteLog("Primeros 300 caracteres: " + LEFT(cResponse, 300))
      ELSE
         ::WriteLog("Contenido completo: " + cResponse)
      ENDIF
   ENDIF
   
RETURN lSuccess

/**
 * GenerarXMLCAESolicitar - Genera el XML para solicitar CAE
 * @return String    XML generado para la solicitud
 */
METHOD GenerarXMLCAESolicitar() CLASS WSAFip
   LOCAL cXML := ""
   LOCAL cDetalle := ""
   LOCAL aDetalle, cFecha, nImpIVA, nImpTrib
   LOCAL cIvaItems := ""
   LOCAL cTributos := ""
   LOCAL cCompAsoc := ""
   LOCAL cActividades := ""
   LOCAL nI
   
   // Verificar que haya datos cargados
   IF LEN(::aDetallesFE) == 0
      RETURN ""
   ENDIF
   
   aDetalle := ::aDetallesFE[1]
   
   // Completar la fecha si es necesario
   IF EMPTY(aDetalle[6])
      cFecha := DTOS(DATE())  // Formato YYYYMMDD sin guiones
      aDetalle[6] := cFecha
   ENDIF
   
   // Calcular ImpIVA (sumatoria de IVA)
   nImpIVA := 0
   FOR nI := 1 TO LEN(::aIvaItems)
      nImpIVA += ::aIvaItems[nI][3]
   NEXT
   aDetalle[12] := nImpIVA
   
   // Calcular ImpTrib (sumatoria de tributos)
   nImpTrib := 0
   FOR nI := 1 TO LEN(::aTributos)
      nImpTrib += ::aTributos[nI][5]
   NEXT
   aDetalle[11] := nImpTrib
   
   // Generar detalle de IVA
   FOR nI := 1 TO LEN(::aIvaItems)
      cIvaItems += '<ar:AlicIva>' + ;
                  '<ar:Id>' + ALLTRIM(STR(::aIvaItems[nI][1])) + '</ar:Id>' + ;
                  '<ar:BaseImp>' + ALLTRIM(STR(::aIvaItems[nI][2], 15, 2)) + '</ar:BaseImp>' + ;
                  '<ar:Importe>' + ALLTRIM(STR(::aIvaItems[nI][3], 15, 2)) + '</ar:Importe>' + ;
                  '</ar:AlicIva>'
   NEXT
   
   // Generar detalle de tributos
   FOR nI := 1 TO LEN(::aTributos)
      cTributos += '<ar:Tributo>' + ;
                   '<ar:Id>' + ALLTRIM(STR(::aTributos[nI][1])) + '</ar:Id>' + ;
                   '<ar:Desc>' + ::XMLEncode(::aTributos[nI][2]) + '</ar:Desc>' + ;
                   '<ar:BaseImp>' + ALLTRIM(STR(::aTributos[nI][3], 15, 2)) + '</ar:BaseImp>' + ;
                   '<ar:Alic>' + ALLTRIM(STR(::aTributos[nI][4], 5, 2)) + '</ar:Alic>' + ;
                   '<ar:Importe>' + ALLTRIM(STR(::aTributos[nI][5], 15, 2)) + '</ar:Importe>' + ;
                   '</ar:Tributo>'
   NEXT
   
   // Generar detalle de comprobantes asociados
   FOR nI := 1 TO LEN(::aCompAsociados)
      cCompAsoc += '<ar:CbteAsoc>' + ;
                  '<ar:Tipo>' + ALLTRIM(STR(::aCompAsociados[nI][1])) + '</ar:Tipo>' + ;
                  '<ar:PtoVta>' + ALLTRIM(STR(::aCompAsociados[nI][2])) + '</ar:PtoVta>' + ;
                  '<ar:Nro>' + ALLTRIM(STR(::aCompAsociados[nI][3])) + '</ar:Nro>'
      
      // Agregar CUIT si existe
      IF !EMPTY(::aCompAsociados[nI][4])
         cCompAsoc += '<ar:Cuit>' + ::aCompAsociados[nI][4] + '</ar:Cuit>'
      ENDIF
      
      // Agregar fecha si existe
      IF !EMPTY(::aCompAsociados[nI][5])
         cCompAsoc += '<ar:CbteFch>' + ::aCompAsociados[nI][5] + '</ar:CbteFch>'
      ENDIF
      
      cCompAsoc += '</ar:CbteAsoc>'
   NEXT
   
   // Generar detalle de actividades
   FOR nI := 1 TO LEN(::aActividades)
      cActividades += '<ar:Actividad>' + ;
                     '<ar:Id>' + ALLTRIM(STR(::aActividades[nI])) + '</ar:Id>' + ;
                     '</ar:Actividad>'
   NEXT
   
   // Generar XML para SOAP
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ar="http://ar.gov.afip.dif.FEV1/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<ar:FECAESolicitar>' + ;
           '<ar:Auth>' + ;
           '<ar:Token>' + ::XMLEncode(::cToken) + '</ar:Token>' + ;
           '<ar:Sign>' + ::XMLEncode(::cSign) + '</ar:Sign>' + ;
           '<ar:Cuit>' + ALLTRIM(::cCuitRepresentada) + '</ar:Cuit>' + ;
           '</ar:Auth>' + ;
           '<ar:FeCAEReq>' + ;
           '<ar:FeCabReq>' + ;
           '<ar:CantReg>' + ALLTRIM(STR(::aCabeceraFE[1])) + '</ar:CantReg>' + ;
           '<ar:PtoVta>' + ALLTRIM(STR(::aCabeceraFE[3])) + '</ar:PtoVta>' + ;
           '<ar:CbteTipo>' + ALLTRIM(STR(::aCabeceraFE[2])) + '</ar:CbteTipo>' + ;
           '</ar:FeCabReq>' + ;
           '<ar:FeDetReq>' + ;
           '<ar:FECAEDetRequest>' + ;
           '<ar:Concepto>' + ALLTRIM(STR(aDetalle[1])) + '</ar:Concepto>' + ;
           '<ar:DocTipo>' + ALLTRIM(STR(aDetalle[2])) + '</ar:DocTipo>' + ;
           '<ar:DocNro>' + ALLTRIM(STR(aDetalle[3])) + '</ar:DocNro>' + ;
           '<ar:CbteDesde>' + ALLTRIM(STR(aDetalle[4])) + '</ar:CbteDesde>' + ;
           '<ar:CbteHasta>' + ALLTRIM(STR(aDetalle[5])) + '</ar:CbteHasta>' + ;
           '<ar:CbteFch>' + aDetalle[6] + '</ar:CbteFch>' + ;
           '<ar:ImpTotal>' + ALLTRIM(STR(aDetalle[7], 15, 2)) + '</ar:ImpTotal>' + ;
           '<ar:ImpTotConc>' + ALLTRIM(STR(aDetalle[8], 15, 2)) + '</ar:ImpTotConc>' + ;
           '<ar:ImpNeto>' + ALLTRIM(STR(aDetalle[9], 15, 2)) + '</ar:ImpNeto>' + ;
           '<ar:ImpOpEx>' + ALLTRIM(STR(aDetalle[10], 15, 2)) + '</ar:ImpOpEx>' + ;
           '<ar:ImpTrib>' + ALLTRIM(STR(aDetalle[11], 15, 2)) + '</ar:ImpTrib>' + ;
           '<ar:ImpIVA>' + ALLTRIM(STR(aDetalle[12], 15, 2)) + '</ar:ImpIVA>'
   
   // Agregar fechas de servicio si existen
   IF !EMPTY(aDetalle[13])
      cXML += '<ar:FchServDesde>' + aDetalle[13] + '</ar:FchServDesde>'
   ENDIF
   
   IF !EMPTY(aDetalle[14])
      cXML += '<ar:FchServHasta>' + aDetalle[14] + '</ar:FchServHasta>'
   ENDIF
   
   IF !EMPTY(aDetalle[15])
      cXML += '<ar:FchVtoPago>' + aDetalle[15] + '</ar:FchVtoPago>'
   ENDIF
   
   // Agregar moneda y cotización
   cXML += '<ar:MonId>' + aDetalle[16] + '</ar:MonId>' + ;
          '<ar:MonCotiz>' + ALLTRIM(STR(aDetalle[17], 10, 6)) + '</ar:MonCotiz>' + ;
          '<ar:CondicionIVAReceptorId>' + ALLTRIM(STR(aDetalle[18])) + '</ar:CondicionIVAReceptorId>'
   
   // Agregar comprobantes asociados si existen
   IF !EMPTY(cCompAsoc)
      cXML += '<ar:CbtesAsoc>' + cCompAsoc + '</ar:CbtesAsoc>'
   ENDIF
   
   // Agregar IVA si existe
   IF !EMPTY(cIvaItems)
      cXML += '<ar:Iva>' + cIvaItems + '</ar:Iva>'
   ENDIF
   
   // Agregar tributos si existen
   IF !EMPTY(cTributos)
      cXML += '<ar:Tributos>' + cTributos + '</ar:Tributos>'
   ENDIF
   
   // Agregar actividades si existen
   IF !EMPTY(cActividades)
      cXML += '<ar:Actividades>' + cActividades + '</ar:Actividades>'
   ENDIF
   
   // Cerrar XML
   cXML += '</ar:FECAEDetRequest>' + ;
           '</ar:FeDetReq>' + ;
           '</ar:FeCAEReq>' + ;
           '</ar:FECAESolicitar>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'
   
RETURN cXML

/**
 * ParseFECAESolicitarResponse - Procesa la respuesta de la solicitud de CAE
 * @param cResponse   Respuesta XML del servicio
 * @return Logical    .T. si se procesó correctamente, .F. en caso de error
 */
METHOD ParseFECAESolicitarResponse(cResponse) CLASS WSAFip
   LOCAL lSuccess := .F.
   
   // Reiniciar datos
   ::cCAE := ""
   ::dCAEVto := CTOD("")
   ::cResultado := ""
   ::aErrors := {}
   ::aObservaciones := {}
   
   // Verificar si hay errores
   IF AT("<Errors>", cResponse) > 0
      // Procesar errores
      nPos := 1
      DO WHILE .T.
         nIniTag := AT("<Err>", SUBSTR(cResponse, nPos))
         IF nIniTag == 0
            EXIT
         ENDIF
         
         nIniTag := nPos + nIniTag - 1
         nFinTag := AT("</Err>", SUBSTR(cResponse, nIniTag)) + nIniTag + 6
         
         cErrorData := SUBSTR(cResponse, nIniTag, nFinTag - nIniTag)
         
         cCode := SUBSTR(cErrorData, AT("<Code>", cErrorData) + 6, AT("</Code>", cErrorData) - AT("<Code>", cErrorData) - 6)
         cMsg := SUBSTR(cErrorData, AT("<Msg>", cErrorData) + 5, AT("</Msg>", cErrorData) - AT("<Msg>", cErrorData) - 5)
         
         AADD(::aErrors, {VAL(cCode), cMsg})
         
         nPos := nFinTag
      ENDDO
      
      IF LEN(::aErrors) > 0
         ::cLastError := ::aErrors[1, 2]
         ::nLastCode := ::aErrors[1, 1]
      ELSE
         ::cLastError := "Error desconocido en la solicitud de CAE"
         ::nLastCode := 1014
      ENDIF
      
      ::WriteLog("Error en solicitud de CAE: " + ::cLastError + " (Código: " + ALLTRIM(STR(::nLastCode)) + ")")
      RETURN .F.
   ENDIF
   
   // Extraer resultado
   IF AT("<Resultado>", cResponse) > 0
      ::cResultado := SUBSTR(cResponse, AT("<Resultado>", cResponse) + 11, AT("</Resultado>", cResponse) - AT("<Resultado>", cResponse) - 11)
   ENDIF
   
   // Si hay CAE, extraerlo junto con la fecha de vencimiento
   IF AT("<CAE>", cResponse) > 0
      ::cCAE := SUBSTR(cResponse, AT("<CAE>", cResponse) + 5, AT("</CAE>", cResponse) - AT("<CAE>", cResponse) - 5)
      
      cFchVto := SUBSTR(cResponse, AT("<CAEFchVto>", cResponse) + 11, AT("</CAEFchVto>", cResponse) - AT("<CAEFchVto>", cResponse) - 11)
      IF !EMPTY(cFchVto)
         ::dCAEVto := STOD(SUBSTR(cFchVto, 1, 4) + SUBSTR(cFchVto, 5, 2) + SUBSTR(cFchVto, 7, 2))
      ENDIF
      
      // Procesar observaciones si las hay
      IF AT("<Obs>", cResponse) > 0
         nPos := 1
         DO WHILE .T.
            nIniTag := AT("<Observaciones>", SUBSTR(cResponse, nPos))
            IF nIniTag == 0
               EXIT
            ENDIF
            
            nIniTag := nPos + nIniTag - 1
            nFinTag := AT("</Observaciones>", SUBSTR(cResponse, nIniTag)) + nIniTag + 16
            
            cObsData := SUBSTR(cResponse, nIniTag, nFinTag - nIniTag)
            
            cCode := SUBSTR(cObsData, AT("<Code>", cObsData) + 6, AT("</Code>", cObsData) - AT("<Code>", cObsData) - 6)
            cMsg := SUBSTR(cObsData, AT("<Msg>", cObsData) + 5, AT("</Msg>", cObsData) - AT("<Msg>", cObsData) - 5)
            
            AADD(::aObservaciones, {VAL(cCode), cMsg})
            
            nPos := nFinTag
         ENDDO
      ENDIF
      
      lSuccess := .T.
      ::WriteLog("Solicitud de CAE exitosa: " + ::cCAE + ", Venc: " + DTOC(::dCAEVto))
   ELSE
      ::cLastError := "No se encontró CAE en la respuesta"
      ::nLastCode := 1015
      ::WriteLog("No se encontró CAE en la respuesta")
   ENDIF
   
RETURN lSuccess

/**
 * SendRequest - Envía una solicitud SOAP utilizando MSXML2.XMLHTTP
 * @param cURL      URL del servicio
 * @param cAction   Action para la cabecera SOAPAction
 * @param cXML      XML de la solicitud
 * @return String   Respuesta del servicio o cadena vacía en caso de error
 */
METHOD SendRequest(cURL, cAction, cXML) CLASS WSAFip
   LOCAL cResponse := ""
   LOCAL oXMLHTTP, nStatus, oError
   
   // Registra en el log la información de la petición
   ::WriteLog("Enviando solicitud a URL: " + cURL)
   ::WriteLog("SOAPAction: " + cAction)
   
   TRY
      // Crear objeto MSXML2.XMLHTTP
      oXMLHTTP := CreateObject('MSXML2.XMLHTTP')
      
      // Iniciar la conexión con método POST
      oXMLHTTP:Open('POST', cURL, .F.)  // Llamada síncrona
      
      // Establecer cabeceras
      oXMLHTTP:SetRequestHeader('Content-Type', 'text/xml; charset=utf-8')
      oXMLHTTP:SetRequestHeader('SOAPAction', cAction)
      
      // Enviar la solicitud XML
      oXMLHTTP:Send(cXML)
      
      // Obtener estado de la respuesta
      nStatus := oXMLHTTP:Status
      
      IF nStatus == 200
          // Obtener el cuerpo de la respuesta
          cResponse := oXMLHTTP:ResponseText
          ::WriteLog("Solicitud enviada con éxito. Estado: 200 OK")
          // Guardar la respuesta para análisis
          MemoWrit2("wsaa_response.xml", cResponse)
      ELSE
         ::cLastError := "Error en la solicitud HTTP. Estado: " + ALLTRIM(STR(nStatus))
         ::nLastCode := nStatus
         ::WriteLog(::cLastError + " - " + oXMLHTTP:StatusText)
         ::WriteLog("Respuesta de error: " + oXMLHTTP:ResponseText)
      ENDIF
      
   CATCH oError
      ::cLastError := "Error al enviar la solicitud: "+oError:Description      
      ::nLastCode := oError:subcode
      ::WriteLog(::cLastError)
   END
   
   // Liberar recursos
   oXMLHTTP := NIL
   
RETURN cResponse

/**
 * Base64Encode - Codifica en Base64
 * @param cData    Datos a codificar
 * @return String  Datos codificados
 */
/*
METHOD Base64Encode1(cData) CLASS WSAFip
   LOCAL cEncoded := ""
   
   // Implementar codificación Base64
   // Por ahora utilizamos un comando externo
   //MemoWrit2("temp_data.bin", cData)
   //RUN base64 temp_data.bin > temp_encoded.bin
   cEncoded := Base64Encode(cData)
   
   /*IF FILE("temp_encoded.bin")
      cEncoded := MemoRead("temp_encoded.bin")
      //DELETE FILE temp_data.bin
      //DELETE FILE temp_encoded.bin
   ENDIF*/
   
//RETURN cEncoded
*/
METHOD Base64Encode1(cData) CLASS WSAFip
   LOCAL cEncoded := ""
   
   // Usar una función más simple para codificar en Base64
   TRY
      // Guardar los datos binarios en un archivo temporal
      MemoWrit2("temp_bin.dat", cData)
      
      // Utilizar el comando base64 de OpenSSL para codificar
      WaitRun(".\DRIVERSFC\openssl base64 -in temp_bin.dat -out temp_b64.dat", 0)
      
      // Leer el archivo codificado
      IF FILE("temp_b64.dat")
         cEncoded := MemoRead("temp_b64.dat")
         cEncoded := STRTRAN(cEncoded, CHR(13), "")  // Eliminar retornos de carro
         cEncoded := STRTRAN(cEncoded, CHR(10), "")  // Eliminar saltos de línea
         ::WriteLog("Codificación Base64 exitosa. Tamaño: " + ALLTRIM(STR(LEN(cEncoded))) + " bytes")
      ELSE
         ::cLastError := "Error al codificar en Base64: No se pudo crear el archivo temp_b64.dat"
         ::nLastCode := 1070
         ::WriteLog(::cLastError)
      ENDIF
      
      // Limpiar archivos temporales
      IF FILE("temp_bin.dat")
         FERASE("temp_bin.dat")
      ENDIF
      IF FILE("temp_b64.dat")
         FERASE("temp_b64.dat")
      ENDIF
      
   CATCH oError
      ::cLastError := "Error al codificar en Base64: " + oError:Description
      ::nLastCode := 1071
      ::WriteLog(::cLastError)
   END
   
RETURN cEncoded
/**
 * Base64Decode - Decodifica de Base64
 * @param cData    Datos codificados
 * @return String  Datos decodificados
 */
METHOD Base64Decode1(cData) CLASS WSAFip
   LOCAL cDecoded := ""
   
   // Implementar decodificación Base64
   // Por ahora utilizamos un comando externo
   //MemoWrit2("temp_encoded.bin", cData)
   cDecoded := Base64Decode(cData)
   //RUN base64 -d temp_encoded.bin > temp_data.bin

   
   /*IF FILE("temp_data.bin")
      cDecoded := MemoRead("temp_data.bin")
      DELETE FILE temp_data.bin
      DELETE FILE temp_encoded.bin
   ENDIF*/
   
RETURN cDecoded

/**
 * XMLEncode - Escapa caracteres especiales para XML
 * @param cStr      Cadena a escapar
 * @return String   Cadena escapada
 */
METHOD XMLEncode(cStr) CLASS WSAFip
   LOCAL cResult := cStr
   
   cResult := STRTRAN(cResult, "&", "&amp;")
   cResult := STRTRAN(cResult, "<", "&lt;")
   cResult := STRTRAN(cResult, ">", "&gt;")
   cResult := STRTRAN(cResult, '"', "&quot;")
   cResult := STRTRAN(cResult, "'", "&apos;")
   
RETURN cResult

/**
 * DateToWSDate - Convierte una fecha a formato de fecha para WebService
 * @param dDate     Fecha a convertir
 * @return String   Fecha en formato AAAAMMDD
 */
METHOD DateToWSDate(dDate) CLASS WSAFip
   LOCAL cDate := ""
   
   IF !EMPTY(dDate)
      cDate := DTOS(dDate)
   ENDIF
   
RETURN cDate

static function MemoWrit2(cFile, cText)
LOCAL Han := LCREAT(cFile), nBytes

nBytes := FWRITE(Han,cText,LEN(cText))   
LCLOSE(Han)
RETURN nil

/**
 * Base64Encode - Codifica en Base64 (versión nativa)
 * @param cData    Datos a codificar
 * @return String  Datos codificados
 */
STATIC FUNCTION  Base64Encode(cData)
   LOCAL cBase64Chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
   LOCAL cResult := "", nLen, nValue, nBits, nChar, nI
   LOCAL nPad := 0
   
   
   // Procesar los datos en grupos de 3 bytes
   nLen := LEN(cData)
   
   // Calcular padding necesario
   IF MOD(nLen, 3) == 1
      nPad := 2
   ELSEIF MOD(nLen, 3) == 2
      nPad := 1
   ENDIF
   
   // Procesar cada trío de bytes
   FOR nI := 1 TO nLen STEP 3
      // Obtener los valores de los bytes (hasta 3)
      nValue := ASC(SUBSTR(cData, nI, 1)) * 65536
      
      IF nI + 1 <= nLen
         nValue += ASC(SUBSTR(cData, nI + 1, 1)) * 256
      ENDIF
      
      IF nI + 2 <= nLen
         nValue += ASC(SUBSTR(cData, nI + 2, 1))
      ENDIF
      
      // Convertir a 4 caracteres Base64
      nBits := 18
      FOR nChar := 1 TO 4
         IF nI + (nChar - 1) / 1.33 <= nLen
            cResult += SUBSTR(cBase64Chars, INT(nValue / (2 ^ nBits)) % 64 + 1, 1)
         ELSE
            cResult += "="  // Padding
         ENDIF
         nBits -= 6
      NEXT
   NEXT
RETURN cResult

/**
 * Base64Decode - Decodifica de Base64 (versión nativa)
 * @param cData    Datos codificados
 * @return String  Datos decodificados
 */
STATIC FUNCTION Base64Decode(cData)
   LOCAL cBase64Chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
   LOCAL cResult := "", nLen, nValue, nPad, nI, nJ, nPos
   
   
   
   // Eliminar caracteres que no son Base64
   cData := STRTRAN(cData, CHR(13), "")
   cData := STRTRAN(cData, CHR(10), "")
   cData := STRTRAN(cData, " ", "")
   
   // Contar padding
   nPad := 0
   IF RIGHT(cData, 1) == "="
      nPad++
      cData := LEFT(cData, LEN(cData) - 1)
      IF RIGHT(cData, 1) == "="
         nPad++
         cData := LEFT(cData, LEN(cData) - 1)
      ENDIF
   ENDIF
   
   nLen := LEN(cData)
   
   // Decodificar
   FOR nI := 1 TO nLen STEP 4
      nValue := 0
      
      // Procesar 4 caracteres Base64
      FOR nJ := 0 TO 3
         IF nI + nJ <= nLen
            nPos := AT(SUBSTR(cData, nI + nJ, 1), cBase64Chars) - 1
            IF nPos >= 0
               nValue := nValue * 64 + nPos
            ENDIF
         ENDIF
      NEXT
      
      // Convertir a bytes originales
      cResult += CHR(INT(nValue / 65536) % 256)
      
      IF nI + 1 <= nLen - nPad
         cResult += CHR(INT(nValue / 256) % 256)
      ENDIF
      
      IF nI + 2 <= nLen - nPad
         cResult += CHR(nValue % 256)
      ENDIF
   NEXT
RETURN cResult