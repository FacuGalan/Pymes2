// Ejemplo de uso de la clase WSAFip para autenticación
FUNCTION AutenticarAFIP()
   LOCAL oAFIP
   LOCAL cCertFile := "c:\certificados\certificado.crt"
   LOCAL cPrivKeyFile := "c:\certificados\clave_privada.key"
   LOCAL lSuccess := .F.
   
   // Crear instancia de la clase WSAFip
   // Parámetros: CUIT del contribuyente, Modo de prueba (.T.)
   oAFIP := WSAFip():New("30123456789", .T.)
   
   // Intentar login para obtener Token y Sign
   lSuccess := oAFIP:Login(cCertFile, cPrivKeyFile, "wsfe")
   
   IF lSuccess
      // Login exitoso, mostrar información
      ? "Login exitoso!"
      ? "Token obtenido: " + oAFIP:cToken
      ? "Sign obtenido: " + oAFIP:cSign 
      ? "Vencimiento: " + DTOC(oAFIP:dTokenExpiry)
      
      // Ahora puedes usar estos valores para autorizar comprobantes
      // u otras operaciones con los webservices de AFIP
   ELSE
      // Error de login
      ? "Error de login: " + oAFIP:GetLastError()
      ? "Código de error: " + ALLTRIM(STR(oAFIP:GetLastErrorCode()))
   ENDIF
   
RETURN lSuccess

// Otra forma de verificar el token
FUNCTION VerificarToken()
   LOCAL oAFIP
   LOCAL cCertFile := "c:\certificados\certificado.crt"
   LOCAL cPrivKeyFile := "c:\certificados\clave_privada.key"
   
   // Crear instancia de la clase
   oAFIP := WSAFip():New("30123456789", .T.)
   
   // Verificar si tenemos un token vigente
   IF oAFIP:CheckTAExpired()
      // Token expirado o no existe, obtener uno nuevo
      ? "Token expirado o no existe. Solicitando uno nuevo..."
      
      IF oAFIP:Login(cCertFile, cPrivKeyFile, "wsfe")
         ? "Token obtenido correctamente."
      ELSE
         ? "Error al obtener token: " + oAFIP:GetLastError()
      ENDIF
   ELSE
      ? "Token vigente hasta: " + DTOC(oAFIP:dTokenExpiry)
   ENDIF
   
RETURN NIL



// ESTO ES EL EJEMPLO PRACTICO QUE DEFINIO
FUNCTION EjemploCompletoAFIP()
   LOCAL oAFIP, nUltimoComprobante
   LOCAL cCertFile := "c:\certificados\certificado.crt"
   LOCAL cPrivKeyFile := "c:\certificados\clave_privada.key"
   
   // Crear instancia de la clase WSAFip
   oAFIP := WSAFip():New("30123456789", .T.)
   
   // Intentar login para obtener Token y Sign
   IF oAFIP:Login(cCertFile, cPrivKeyFile, "wsfe")
      ? "Login exitoso!"
      
      // Consultar último número de comprobante para 
      // punto de venta 1 y tipo de comprobante 1 (Factura A)
      nUltimoComprobante := oAFIP:SFRecuperaLastCMP(1, 1)
      
      IF nUltimoComprobante > 0
         ? "Último comprobante: " + ALLTRIM(STR(nUltimoComprobante))
      ELSE
         ? "Error al consultar último comprobante: " + oAFIP:GetLastError()
      ENDIF
   ELSE
      ? "Error de login: " + oAFIP:GetLastError()
   ENDIF
   
RETURN NIL