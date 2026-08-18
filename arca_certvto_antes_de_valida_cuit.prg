#include "FiveWin.ch"

/*
 * ==========================================================================
 *  ARCA_CERTVTO.PRG - Aviso de vencimiento del certificado digital ARCA
 *
 *  Lee la fecha "notAfter" del certificado X.509 (.crt) usando el mismo
 *  OPENSSL.EXE de .\DRIVERSFC que ya se usa para firmar el TRA (WSAA)
 *  en ARCA2.PRG:
 *
 *     openssl x509 -in MiCertificado.crt -noout -enddate
 *     -> notAfter=Jun 30 12:00:00 2027 GMT
 *
 *  USO (al arrancar el sistema, o antes del primer Login):
 *
 *     ChequeaVtoCertArca( 30 )          // avisa si vence en 30 dias o menos
 *
 *     LOCAL dVto := CertVencimiento()   // o pedir la fecha directamente
 *     ? dVto                            // fecha vacia si no pudo leerla
 * ==========================================================================
 */

/*
 * ChequeaVtoCertArca - Muestra un aviso si el certificado vencio o esta
 *                      proximo a vencer. Pensada para llamar al inicio
 *                      del sistema: si todo esta bien no molesta.
 *
 * @param nDiasAviso    Dias de anticipacion del aviso (default 30)
 * @param cCertFile     Ruta al certificado (default .\DRIVERSFC\MiCertificado.crt)
 * @param cPathOpenSSL  Carpeta del openssl.exe (default .\DRIVERSFC)
 *
 * @return nDias  Dias que faltan para el vencimiento (negativo si ya vencio)
 *                o NIL si no se pudo leer la fecha.
 */
FUNCTION ChequeaVtoCertArca( nDiasAviso, cCertFile, cPathOpenSSL )

   LOCAL dVto, nDias

   DEFAULT nDiasAviso := 30

   dVto := CertVencimiento( cCertFile, cPathOpenSSL )

   IF EMPTY( dVto )
      // Falta el .crt o el openssl, o no se pudo parsear: no molestamos
      // al usuario en cada arranque; devolvemos NIL para que el que llama
      // decida si quiere avisar.
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
