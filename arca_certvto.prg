#include "FiveWin.ch"

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

   DEFAULT nDiasAviso := 5

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
      MsgAlert( "El certificado digital de ARCA vence el " + DTOC( dVto ) + ;
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
