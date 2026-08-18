#include "FiveWin.ch"
MEMVAR oApp
/*
 * ==========================================================================
 *  PADRON.PRG  -  Consulta de Constancia de Inscripcion por CUIT (ARCA/AFIP)
 *  Servicio : ws_sr_constancia_inscripcion   Metodo: getPersona_v2
 *
 *  Depende de la clase WSAFip (ARCA2.PRG) SOLO para resolver el WSAA
 *  (Login -> Token + Sign). El resto (armado del SOAP, envio y parseo)
 *  se resuelve aca en el mismo estilo que ARCA2.PRG (AT()/SUBSTR()).
 *
 *  USO:
 *     LOCAL aDatos := PadronConsultaCUIT( "20214424666", "30500010912", .F. )
 *     IF aDatos[1]                       // .T. = OK ; .F. = error
 *        ? aDatos[2]                     // hash con los datos
 *        ? aDatos[2]["nombre"]
 *        ? aDatos[2]["condicionIva"]
 *        ? aDatos[2]["direccion"]
 *     ELSE
 *        ? "Error: " + aDatos[3]         // texto del error
 *     ENDIF
 * ==========================================================================
 */

/*
 * PadronConsultaCUIT
 * @param cCuitRepresentada  CUIT que consulta (el titular del certificado)
 * @param cCuitConsultado    CUIT del contribuyente a averiguar
 * @param lTestMode          .T. homologacion / .F. produccion (default .F.)
 * @param cCertFile          Ruta al certificado  (default .\DRIVERSFC\MiCertificado.crt)
 * @param cPrivKeyFile       Ruta a la clave priv (default .\DRIVERSFC\MiClavePrivada)
 *
 * @return Array { lOk, hDatos, cError }
 *         lOk     -> Logico
 *         hDatos  -> Hash con las claves:
 *                      "cuit"            -> CUIT consultado
 *                      "tipoPersona"     -> FISICA / JURIDICA
 *                      "nombre"          -> razon social o apellido+nombre
 *                      "estadoClave"     -> ACTIVO / INACTIVO ...
 *                      "condicionIva"    -> texto ("Responsable Inscripto",
 *                                           "Monotributo", "Exento", etc.)
 *                      "codigoIva"       -> indice 1..15 de la tabla atipoiva
 *                                           (0 = no derivable del WS)
 *                      "direccion"       -> calle y numero domicilio fiscal
 *                      "localidad"       -> localidad
 *                      "provincia"       -> descripcionProvincia
 *                      "codPostal"       -> CP
 *                      "domicilioCompleto" -> todo el domicilio en una linea
 *                      "impuestos"       -> array de { idImpuesto, descripcion }
 *                      "actividades"     -> array de { idActividad, descripcion }
 *                      "xml"             -> respuesta cruda (por si haces falta)
 *         cError  -> Texto del error si lOk = .F.
 */
FUNCTION PadronConsultaCUIT( cCuitConsultado, cCuitRepresentada, lTestMode, ;
                             cCertFile, cPrivKeyFile )

   LOCAL oAFIP, aRet := { .F., NIL, "" }
   LOCAL cUrl, cAction, cXML, cResp, cCuerpo, hDatos

   DEFAULT lTestMode    := .F.
   DEFAULT cCertFile    := ".\DRIVERSFC\MiCertificado.crt"
   DEFAULT cPrivKeyFile := ".\DRIVERSFC\MiClavePrivada"
   DEFAULT cCuitRepresentada := oApp:cuit_emp

   // --- Validaciones basicas -------------------------------------------
   cCuitRepresentada := ALLTRIM( STRTRAN( STRTRAN( cCuitRepresentada, "-", "" ), " ", "" ) )
   cCuitConsultado   := ALLTRIM( STRTRAN( STRTRAN( cCuitConsultado,   "-", "" ), " ", "" ) )

   IF LEN( cCuitConsultado ) <> 11 .OR. EMPTY( VAL( cCuitConsultado ) )
      aRet[3] := "CUIT a consultar invalido: " + cCuitConsultado
      RETURN aRet
   ENDIF

   IF !FILE( cCertFile )
      aRet[3] := "No se encuentra el certificado: " + cCertFile
      RETURN aRet
   ENDIF
   IF !FILE( cPrivKeyFile )
      aRet[3] := "No se encuentra la clave privada: " + cPrivKeyFile
      RETURN aRet
   ENDIF

   // --- 1) WSAA: reutilizamos tu clase para obtener Token + Sign -------
   //     OJO: el service DEBE ser el del padron, no "wsfe"
   oAFIP := WSAFip():New( cCuitRepresentada, lTestMode )

   IF !oAFIP:Login( cCertFile, cPrivKeyFile, "ws_sr_constancia_inscripcion" )
      aRet[3] := "Error de login WSAA: " + oAFIP:GetLastError()
      RETURN aRet
   ENDIF

   // --- 2) URL y SOAPAction del servicio de padron ---------------------
   IF lTestMode
      cUrl := "https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5"
   ELSE
      cUrl := "https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5"
   ENDIF
   cAction := ""   // este WS no exige SOAPAction; se manda vacio

   // --- 3) Armado del sobre SOAP (getPersona_v2) -----------------------
   cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:a5="http://a5.soap.ws.server.puc.sr/">' + ;
           '<soapenv:Header/>' + ;
           '<soapenv:Body>' + ;
           '<a5:getPersona_v2>' + ;
           '<token>'  + oAFIP:cToken + '</token>' + ;
           '<sign>'   + oAFIP:cSign  + '</sign>' + ;
           '<cuitRepresentada>' + cCuitRepresentada + '</cuitRepresentada>' + ;
           '<idPersona>'        + cCuitConsultado   + '</idPersona>' + ;
           '</a5:getPersona_v2>' + ;
           '</soapenv:Body>' + ;
           '</soapenv:Envelope>'

   // --- 4) Envio: POST SOAP propio (no usamos el SendRequest protegido) -
   cResp := PadEnviaSOAP( cUrl, cAction, cXML, @aRet )

   IF EMPTY( cResp )
      IF EMPTY( aRet[3] )
         aRet[3] := "Sin respuesta del padron."
      ENDIF
      RETURN aRet
   ENDIF

   // Decodificar entidades XML por si vienen escapadas
   cResp := STRTRAN( cResp, "&lt;",   "<" )
   cResp := STRTRAN( cResp, "&gt;",   ">" )
   cResp := STRTRAN( cResp, "&quot;", '"' )
   cResp := STRTRAN( cResp, "&apos;", "'" )
   cResp := STRTRAN( cResp, "&amp;",  "&" )

   // --- 5) Errores devueltos por el WS ---------------------------------
   IF AT( "<faultstring>", cResp ) > 0
      aRet[3] := "Fault: " + PadExtrae( cResp, "<faultstring>", "</faultstring>" )
      RETURN aRet
   ENDIF
   // Nodo de error de constancia (CUIT inexistente, sin datos, etc.)
   IF AT( "<errorConstancia>", cResp ) > 0
      aRet[3] := "ARCA: " + PadExtrae( cResp, "<error>", "</error>" )
      IF EMPTY( ALLTRIM( aRet[3] ) ) .OR. aRet[3] == "ARCA: "
         aRet[3] := "El CUIT no registra datos de constancia."
      ENDIF
      RETURN aRet
   ENDIF

   IF AT( "<personaReturn>", cResp ) == 0
      aRet[3] := "Respuesta sin datos de persona (CUIT inexistente?)."
      RETURN aRet
   ENDIF

   // --- 6) Parseo de la respuesta --------------------------------------
   hDatos := PadronParsea( cResp, cCuitConsultado )

   aRet[1] := .T.
   aRet[2] := hDatos
   aRet[3] := ""

RETURN aRet

/*
 * PadronParsea - Extrae los campos del <personaReturn> a un hash
 */
STATIC FUNCTION PadronParsea( cResp, cCuit )
   LOCAL hDatos := { => }
   LOCAL cGrales, cDomi, cNombre, cApe, cNom, cRazon
   LOCAL cCondIva := "", cTipoPersona
   LOCAL lTieneMono, lTieneRG
   LOCAL aImpuestos := {}, aActividades := {}
   LOCAL cDomiCompleto := ""
   LOCAL nCodIva := 0, lMonoSocial

   HB_HSetCaseMatch( hDatos, .F. )   // claves case-insensitive

   // Aislar el bloque de datos generales para no confundir con otros nodos
   cGrales := PadExtrae( cResp, "<datosGenerales>", "</datosGenerales>" )

   cTipoPersona := PadExtrae( cGrales, "<tipoPersona>", "</tipoPersona>" )

   // Nombre / Razon social
   cRazon := PadExtrae( cGrales, "<razonSocial>", "</razonSocial>" )
   cApe   := PadExtrae( cGrales, "<apellido>",    "</apellido>" )
   cNom   := PadExtrae( cGrales, "<nombre>",      "</nombre>" )
   IF !EMPTY( cRazon )
      cNombre := cRazon
   ELSE
      cNombre := ALLTRIM( cApe + " " + cNom )
   ENDIF

   // Domicilio fiscal
   cDomi := PadExtrae( cResp, "<domicilioFiscal>", "</domicilioFiscal>" )

   hDatos[ "cuit" ]        := cCuit
   hDatos[ "tipoPersona" ] := cTipoPersona
   hDatos[ "nombre" ]      := cNombre
   hDatos[ "estadoClave" ] := PadExtrae( cGrales, "<estadoClave>", "</estadoClave>" )
   hDatos[ "direccion" ]   := PadExtrae( cDomi, "<direccion>",  "</direccion>" )
   hDatos[ "localidad" ]   := PadExtrae( cDomi, "<localidad>",  "</localidad>" )
   hDatos[ "provincia" ]   := PadExtrae( cDomi, "<descripcionProvincia>", "</descripcionProvincia>" )
   hDatos[ "codPostal" ]   := PadExtrae( cDomi, "<codPostal>",  "</codPostal>" )

   cDomiCompleto := ALLTRIM( hDatos[ "direccion" ] )
   IF !EMPTY( hDatos[ "localidad" ] )
      cDomiCompleto += " - " + ALLTRIM( hDatos[ "localidad" ] )
   ENDIF
   IF !EMPTY( hDatos[ "provincia" ] )
      cDomiCompleto += " (" + ALLTRIM( hDatos[ "provincia" ] ) + ")"
   ENDIF
   IF !EMPTY( hDatos[ "codPostal" ] )
      cDomiCompleto += " CP " + ALLTRIM( hDatos[ "codPostal" ] )
   ENDIF
   hDatos[ "domicilioCompleto" ] := cDomiCompleto

   // --- Condicion frente al IVA ----------------------------------------
   // No viene un campo unico: se deduce de los bloques presentes.
   lTieneMono := ( AT( "<datosMonotributo>", cResp ) > 0 )
   lTieneRG   := ( AT( "<datosRegimenGeneral>", cResp ) > 0 )

   // Impuestos del regimen general (buscamos IVA = id 30)
   PadExtraeImpuestos( cResp, @aImpuestos )
   PadExtraeActividades( cResp, @aActividades )

   //  Codigos segun la tabla atipoiva del usuario (1..15):
   //   1 IVA Responsable Inscripto      4 IVA Sujeto Exento
   //   5 Consumidor Final               6 Responsable Monotributo
   //  13 Monotributista Social
   //  El WS de constancia SOLO permite deducir estos con fiabilidad;
   //  el resto de la tabla no es derivable y queda en 0 (desconocido).
   lMonoSocial := ( AT( "MONOTRIBUTO SOCIAL", UPPER( cResp ) ) > 0 .OR. ;
                    AT( "MONOTRIBUTISTA SOCIAL", UPPER( cResp ) ) > 0 )

   IF lTieneMono
      IF lMonoSocial
         nCodIva  := 13
         cCondIva := "Monotributista Social"
      ELSE
         nCodIva  := 6
         cCondIva := "Responsable Monotributo"
      ENDIF
      // agregar categoria si aparece
      IF AT( "<categoriaMonotributo>", cResp ) > 0
         cCondIva += " - Cat. " + ;
            PadExtrae( cResp, "<descripcionCategoria>", "</descripcionCategoria>" )
      ENDIF
   ELSEIF lTieneRG
      IF PadTieneImpuesto( aImpuestos, "30" )
         nCodIva  := 1
         cCondIva := "IVA Responsable Inscripto"
      ELSEIF PadTieneImpuesto( aImpuestos, "32" )
         nCodIva  := 4
         cCondIva := "IVA Sujeto Exento"
      ELSE
         // Regimen general sin IVA declarado: no se puede afirmar cual es
         nCodIva  := 0
         cCondIva := "Regimen General (IVA a verificar)"
      ENDIF
   ELSE
      // Sin monotributo ni regimen general: tentativamente Consumidor Final
      nCodIva  := 5
      cCondIva := "Consumidor Final"
   ENDIF

   hDatos[ "condicionIva" ] := cCondIva
   hDatos[ "codigoIva" ]    := nCodIva
   hDatos[ "impuestos" ]    := aImpuestos
   hDatos[ "actividades" ]  := aActividades
   hDatos[ "xml" ]          := cResp

RETURN hDatos

/*
 * PadExtrae - Devuelve el texto entre dos etiquetas (primera ocurrencia)
 *             Estilo AT()/SUBSTR() igual que en ARCA2.PRG
 */
STATIC FUNCTION PadExtrae( cTexto, cIni, cFin )
   LOCAL cRes := "", nIni, nFin

   IF EMPTY( cTexto )
      RETURN ""
   ENDIF

   nIni := AT( cIni, cTexto )
   IF nIni > 0
      nIni += LEN( cIni )
      nFin := AT( cFin, SUBSTR( cTexto, nIni ) )
      IF nFin > 0
         cRes := SUBSTR( cTexto, nIni, nFin - 1 )
      ENDIF
   ENDIF

RETURN ALLTRIM( cRes )

/*
 * PadExtraeImpuestos - Recorre todos los nodos <impuesto>..</impuesto>
 *                      dentro de <datosRegimenGeneral> y arma un array
 *                      { { idImpuesto, descripcion }, ... }
 */
STATIC FUNCTION PadExtraeImpuestos( cResp, aImp )
   LOCAL cRG, cResto, cBloque, nP, nPFin
   LOCAL cId, cDesc

   cRG := PadExtrae( cResp, "<datosRegimenGeneral>", "</datosRegimenGeneral>" )
   IF EMPTY( cRG )
      RETURN NIL
   ENDIF

   cResto := cRG
   DO WHILE ( nP := AT( "<impuesto>", cResto ) ) > 0
      nPFin := AT( "</impuesto>", cResto )
      IF nPFin == 0
         EXIT
      ENDIF
      cBloque := SUBSTR( cResto, nP, nPFin - nP + LEN( "</impuesto>" ) )

      cId   := PadExtrae( cBloque, "<idImpuesto>",  "</idImpuesto>" )
      cDesc := PadExtrae( cBloque, "<descripcionImpuesto>", "</descripcionImpuesto>" )
      IF !EMPTY( cId )
         AAdd( aImp, { cId, cDesc } )
      ENDIF

      cResto := SUBSTR( cResto, nPFin + LEN( "</impuesto>" ) )
   ENDDO

RETURN NIL

/*
 * PadExtraeActividades - Recorre nodos <actividad>..</actividad>
 */
STATIC FUNCTION PadExtraeActividades( cResp, aAct )
   LOCAL cResto, cBloque, nP, nPFin
   LOCAL cId, cDesc

   cResto := cResp
   DO WHILE ( nP := AT( "<actividad>", cResto ) ) > 0
      nPFin := AT( "</actividad>", cResto )
      IF nPFin == 0
         EXIT
      ENDIF
      cBloque := SUBSTR( cResto, nP, nPFin - nP + LEN( "</actividad>" ) )

      cId   := PadExtrae( cBloque, "<idActividad>", "</idActividad>" )
      cDesc := PadExtrae( cBloque, "<descripcionActividad>", "</descripcionActividad>" )
      IF !EMPTY( cId )
         AAdd( aAct, { cId, cDesc } )
      ENDIF

      cResto := SUBSTR( cResto, nPFin + LEN( "</actividad>" ) )
   ENDDO

RETURN NIL

/*
 * PadTieneImpuesto - .T. si el array de impuestos contiene el id buscado
 */
STATIC FUNCTION PadTieneImpuesto( aImp, cId )
   LOCAL nI, lRet := .F.
   FOR nI := 1 TO LEN( aImp )
      IF ALLTRIM( aImp[ nI ][ 1 ] ) == ALLTRIM( cId )
         lRet := .T.
         EXIT
      ENDIF
   NEXT
RETURN lRet

/*
 * PadEnviaSOAP - POST SOAP con MSXML2.XMLHTTP.
 *   Clon del metodo WSAFip:SendRequest (que es PROTECTED y no se puede
 *   llamar desde este modulo). Devuelve el ResponseText o "" si falla,
 *   dejando el detalle del error en aRet[3].
 */
STATIC FUNCTION PadEnviaSOAP( cURL, cAction, cXML, aRet )
   LOCAL cResponse := "", oXMLHTTP, nStatus, oError

   TRY
      oXMLHTTP := CreateObject( 'MSXML2.XMLHTTP' )
      oXMLHTTP:Open( 'POST', cURL, .F. )                       // sincrono
      oXMLHTTP:SetRequestHeader( 'Content-Type', 'text/xml; charset=utf-8' )
      IF !EMPTY( cAction )
         oXMLHTTP:SetRequestHeader( 'SOAPAction', cAction )
      ENDIF
      oXMLHTTP:Send( cXML )

      nStatus := oXMLHTTP:Status

      IF nStatus == 200
         cResponse := oXMLHTTP:ResponseText
      ELSE
         aRet[3] := "Error HTTP " + ALLTRIM( STR( nStatus ) ) + " - " + ;
                    oXMLHTTP:StatusText
         // intentar sacar el detalle del cuerpo
         IF AT( "<faultstring>", oXMLHTTP:ResponseText ) > 0
            aRet[3] += CRLF + ;
               PadExtrae( oXMLHTTP:ResponseText, "<faultstring>", "</faultstring>" )
         ENDIF
      ENDIF

   CATCH oError
      aRet[3] := "Error al enviar la solicitud: " + oError:Description
   END

   oXMLHTTP := NIL

RETURN cResponse


/*
 * ==========================================================================
 *  ARCA_CERTVTO.PRG - Aviso de vencimiento del certificado digital ARCA
 *
 *  Lee el subject y la fecha "notAfter" del certificado X.509 (.crt) usando
 *  el mismo OPENSSL.EXE de .\DRIVERSFC que ya se usa para firmar el TRA
 *  (WSAA) en ARCA2.PRG:
 *
 *     openssl x509 -in MiCertificado.crt -noout -subject
 *     -> subject= /C=AR/O=.../CN=.../serialNumber=CUIT 20214424666
 *
 *     openssl x509 -in MiCertificado.crt -noout -enddate
 *     -> notAfter=Jun 30 12:00:00 2027 GMT
 *
 *  USO (al arrancar el sistema, despues de cargar oApp:cuit_emp):
 *
 *     ChequeaVtoCertArca( oApp:cuit_emp )      // avisa si vence en 5 dias o menos
 *     ChequeaVtoCertArca( oApp:cuit_emp, 10 )  // idem con 10 dias de aviso
 *
 *  Solo avisa si el certificado instalado pertenece al CUIT del sistema.
 *  Si la terminal no tiene certificados (no factura), o tiene los
 *  certificados demo/homologacion de otro CUIT, no muestra nada.
 * ==========================================================================
 */

/*
 * ChequeaVtoCertArca - Si el certificado instalado es del CUIT del sistema
 *                      y vencio o esta proximo a vencer, muestra un aviso.
 *                      Pensada para llamar al inicio del sistema: si todo
 *                      esta bien (o el certificado es de otro CUIT) no
 *                      molesta.
 *
 * @param cCuitSistema  CUIT de la empresa (oApp:cuit_emp), con o sin guiones
 * @param nDiasAviso    Dias de anticipacion del aviso (default 5)
 * @param cCertFile     Ruta al certificado (default .\DRIVERSFC\MiCertificado.crt)
 * @param cPathOpenSSL  Carpeta del openssl.exe (default .\DRIVERSFC)
 *
 * @return nDias  Dias que faltan para el vencimiento (negativo si ya vencio)
 *                o NIL si no hay certificado del CUIT del sistema o no se
 *                pudo leer.
 */
FUNCTION ChequeaVtoCertArca( cCuitSistema, nDiasAviso, cCertFile, cPathOpenSSL )

   LOCAL cCuitCert, dVto, nDias

   DEFAULT nDiasAviso := 5, cCuitSistema := oApp:cuit_emp

   cCuitSistema := SoloDigitos( cCuitSistema )

   IF EMPTY( cCuitSistema )
      RETURN NIL
   ENDIF

   cCuitCert := CertCuit( cCertFile, cPathOpenSSL )

   // Sin certificado, o certificado de otro CUIT (demo/homologacion):
   // esta terminal no factura con este CUIT, no avisamos nada.
   IF EMPTY( cCuitCert ) .OR. !( cCuitCert == cCuitSistema )
      RETURN NIL
   ENDIF

   dVto := CertVencimiento( cCertFile, cPathOpenSSL )

   IF EMPTY( dVto )
      RETURN NIL
   ENDIF

   nDias := dVto - DATE()

   IF nDias < 0
      MsgStop( "El certificado digital de ARCA VENCIO el " + DTOC( dVto ) + "." + CRLF + CRLF + ;
               "No se podra facturar electronicamente ni consultar el padron." + CRLF + ;
               "Genere un certificado nuevo desde el sitio de ARCA" + CRLF + ;
               "(Administracion de Certificados Digitales).", ;
               "Certificado ARCA VENCIDO" )
   ELSEIF nDias <= nDiasAviso
      MsgInfo( "El certificado digital de ARCA vence el " + DTOC( dVto ) + ;
                " (faltan " + ALLTRIM( STR( nDias, 4 ) ) + " dias)." + CRLF + CRLF + ;
                "Renuevelo antes de esa fecha para no dejar de facturar.", ;
                "Certificado ARCA proximo a vencer" )
   ENDIF

RETURN nDias

/*
 * CertCuit - Devuelve el CUIT del titular del certificado (11 digitos,
 *            sin guiones), o "" si no se pudo leer.
 *
 *            Los certificados de ARCA traen el CUIT en el subject:
 *            .../serialNumber=CUIT 20214424666
 */
FUNCTION CertCuit( cCertFile, cPathOpenSSL )

   LOCAL cCuit    := ""
   LOCAL cTmpFile := "cert_cuit.tmp"
   LOCAL cSalida, cComando, cChar
   LOCAL nPos, nI

   DEFAULT cCertFile    := ".\DRIVERSFC\MiCertificado.crt"
   DEFAULT cPathOpenSSL := ".\DRIVERSFC"

   IF !FILE( cCertFile ) .OR. !FILE( cPathOpenSSL + "\openssl.exe" )
      RETURN ""
   ENDIF

   FERASE( cTmpFile )

   cComando := 'cmd /c ' + cPathOpenSSL + '\openssl x509 -in "' + ;
               cCertFile + '" -noout -subject > ' + cTmpFile

   WaitRun( cComando, 0 )

   IF !FILE( cTmpFile )
      RETURN ""
   ENDIF

   cSalida := MemoRead( cTmpFile )
   FERASE( cTmpFile )

   // Formato esperado: ...serialNumber=CUIT 20214424666
   // (segun la version de openssl puede venir "serialNumber = CUIT 20...")
   nPos := AT( "CUIT", UPPER( cSalida ) )
   IF nPos == 0
      RETURN ""
   ENDIF

   // Tomamos los 11 digitos que siguen a "CUIT", tolerando espacios,
   // "=" y guiones en el medio
   FOR nI := nPos + 4 TO LEN( cSalida )
      cChar := SUBSTR( cSalida, nI, 1 )
      IF cChar >= "0" .AND. cChar <= "9"
         cCuit += cChar
         IF LEN( cCuit ) == 11
            EXIT
         ENDIF
      ELSEIF cChar == " " .OR. cChar == "=" .OR. cChar == "-"
         // separador: seguimos
      ELSE
         EXIT
      ENDIF
   NEXT

   IF LEN( cCuit ) != 11
      RETURN ""
   ENDIF

RETURN cCuit

/*
 * CertVencimiento - Devuelve la fecha de vencimiento (notAfter) del
 *                   certificado, o fecha vacia si no se pudo obtener.
 */
FUNCTION CertVencimiento( cCertFile, cPathOpenSSL )

   LOCAL dVto     := CTOD( "" )
   LOCAL cTmpFile := "cert_vto.tmp"
   LOCAL cMeses   := "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
   LOCAL cSalida, cFecha, cComando
   LOCAL nPos, nMes, nDia, nAnio

   DEFAULT cCertFile    := ".\DRIVERSFC\MiCertificado.crt"
   DEFAULT cPathOpenSSL := ".\DRIVERSFC"

   IF !FILE( cCertFile ) .OR. !FILE( cPathOpenSSL + "\openssl.exe" )
      RETURN dVto
   ENDIF

   FERASE( cTmpFile )

   // openssl escribe "notAfter=..." por stdout; lo capturamos via cmd /c
   cComando := 'cmd /c ' + cPathOpenSSL + '\openssl x509 -in "' + ;
               cCertFile + '" -noout -enddate > ' + cTmpFile

   WaitRun( cComando, 0 )

   IF !FILE( cTmpFile )
      RETURN dVto
   ENDIF

   cSalida := MemoRead( cTmpFile )
   FERASE( cTmpFile )

   // Formato esperado: notAfter=Jun 30 12:00:00 2027 GMT
   //                   (el dia puede venir con espacio extra: "Jun  3 ...")
   nPos := AT( "notAfter=", cSalida )
   IF nPos == 0
      RETURN dVto
   ENDIF

   cFecha := ALLTRIM( SUBSTR( cSalida, nPos + LEN( "notAfter=" ) ) )

   // Mes: tres letras en ingles
   nMes := AT( UPPER( SUBSTR( cFecha, 1, 3 ) ), cMeses )
   IF nMes == 0 .OR. ( nMes - 1 ) % 3 != 0
      RETURN dVto
   ENDIF
   nMes := ( nMes + 2 ) / 3

   // Dia: primer numero despues del mes (VAL ignora los espacios previos)
   nDia := VAL( SUBSTR( cFecha, 4 ) )

   // Anio: las 4 cifras antes de " GMT"
   nPos := AT( " GMT", UPPER( cFecha ) )
   IF nPos < 5 .OR. nDia < 1 .OR. nDia > 31
      RETURN dVto
   ENDIF
   nAnio := VAL( SUBSTR( cFecha, nPos - 4, 4 ) )

   IF nAnio < 2000
      RETURN dVto
   ENDIF

   dVto := STOD( STRZERO( nAnio, 4 ) + STRZERO( nMes, 2 ) + STRZERO( nDia, 2 ) )

RETURN dVto

/*
 * SoloDigitos - Deja solo los digitos de una cadena ("20-21442466-6"
 *               -> "20214424666"). Devuelve "" si no es cadena.
 */
STATIC FUNCTION SoloDigitos( cTexto )

   LOCAL cLimpio := ""
   LOCAL cChar
   LOCAL nI

   IF VALTYPE( cTexto ) != "C"
      RETURN ""
   ENDIF

   FOR nI := 1 TO LEN( cTexto )
      cChar := SUBSTR( cTexto, nI, 1 )
      IF cChar >= "0" .AND. cChar <= "9"
         cLimpio += cChar
      ENDIF
   NEXT

RETURN cLimpio
