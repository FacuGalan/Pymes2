#include "FiveWin.ch"
MEMVAR oApp
*-------------------------------------------------*
Function EnviarPorMail(cdestino,cAsunto,cReplyTo,cFile)
*-------------------------------------------------*

LOCAL loCfg, loMsg, oError, isError := .F.
local cSMTP := "smtp.gmail.com"
Local cPuerto := 465
/*Local cLogin := "notificacionbcnsoft@gmail.com"
Local cPassword := "nopdjhukkzkhorov"*/
Local cLogin := "notificacionbcnsoft@bcnsoft.com.ar"
Local cPassword := "twlkjxhvwuogezkr"
local cRemitente:= "<"+ALLTRIM(oApp:nomb_emp)+">"
Local cMensaje := "Envio automatico desde el sistema para Pymes"+CRLF+CRLF+CRLF
local cSSL := .T., cAuth := .T.
local cFichero := nil
local oIni, cIni := ".\mail.ini", lCustom := .F.
DEFAULT cReplyTo := cDestino, cFile := hb_CurDrive()+":\"+CurDir()+"\ADJUNTO.PDF"

// Si el cliente configuro su propia cuenta de correo en mail.ini, se usa esa.
// Si no, se sigue usando la cuenta predeterminada del sistema (la de arriba).
IF File( cIni )
   INI oIni FILE cIni
   IF ALLTRIM( oIni:Get( "cuenta", "usar", "0" ) ) == "1" .AND. ;
      !EMPTY( ALLTRIM( oIni:Get( "cuenta", "usuario", "" ) ) )
      lCustom   := .T.
      cSMTP     := IIF( EMPTY( ALLTRIM( oIni:Get( "cuenta", "smtp", "" ) ) ),;
                        "smtp.gmail.com", ALLTRIM( oIni:Get( "cuenta", "smtp", "" ) ) )
      cPuerto   := VAL( ALLTRIM( oIni:Get( "cuenta", "puerto", "465" ) ) )
      IF cPuerto == 0
         cPuerto := 465
      ENDIF
      cSSL      := ( ALLTRIM( oIni:Get( "cuenta", "ssl", "1" ) ) == "1" )
      cLogin    := ALLTRIM( oIni:Get( "cuenta", "usuario", "" ) )
      cPassword := STRTRAN( ALLTRIM( oIni:Get( "cuenta", "password", "" ) ), " ", "" )
   ENDIF
ENDIF

// Cuando se usa la cuenta propia del cliente, esa cuenta es tambien el
// remitente y la direccion de respuesta (ReplyTo).
IF lCustom
   cRemitente := ALLTRIM( oApp:nomb_emp ) + " <" + cLogin + ">"
   cReplyTo   := cLogin
ENDIF

loCfg := CREATEOBJECT( "CDO.Configuration" )
WITH OBJECT loCfg:Fields
:Item( "http://schemas.microsoft.com/cdo/configuration/smtpserver" ):Value := cSMTP // "smtp.gmail.com"
:Item( "http://schemas.microsoft.com/cdo/configuration/smtpserverport" ):Value := cPuerto //465
:Item( "http://schemas.microsoft.com/cdo/configuration/sendusing" ):Value := 2
:Item( "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate" ):Value := cAuth //.T.
:Item( "http://schemas.microsoft.com/cdo/configuration/smtpusessl" ):Value := cSSL // .T.
:Item( "http://schemas.microsoft.com/cdo/configuration/sendusername" ):Value := cLogin //tu cuenta de correo de salida
:Item( "http://schemas.microsoft.com/cdo/configuration/sendpassword" ):Value := cPassword //"" //con tu clave gmail. en este caso
:Item( "http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout"):Value := 30

:Update()
END WITH

Procesando(.t.)
TRY
	loMsg := CREATEOBJECT ( "CDO.Message" )
	WITH OBJECT loMsg
		:Configuration = loCfg
		:From = cRemitente
		:ReplyTo := cReplyTo
		:To = cDestino
		:Subject = cAsunto
		:MDNRequested = .f.
		:HTMLBody = '<!DOCTYPE html>' +;
            '<html>'+;
            '	<head>'+;
            '	    <meta charset="UTF-8">'+;
            '	    <meta name="viewport" content="width=device-width, initial-scale=1.0">'+;
            '       <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800;900&family=Poppins;display=swap" rel="stylesheet">'+;
            '	</head>'+;
            '	<body style="font-family: Montserrat, -apple-system, BlinkMacSystemFont, sans-serif; background-color: #f9fafb; color: #374151; margin: 0; padding: 0;">'+;
            '	    <div style="width: 100%; background-color: #f9fafb; padding-bottom: 40px;">'+;
            '	        <div style="background-color: #ffffff; width: 100%; max-width: 600px; margin: 0 auto; border-radius: 8px; border: 1px solid #e5e7eb; overflow: hidden; margin-top: 20px;">'+;
            '	            <div style="background-color: #FFAF22; padding: 20px; text-align: center;">'+;
            '	                <h1 style="color: #ffffff; margin: 0; font-family: Montserrat, Arial, sans-serif; font-size: 18px; font-weight: 800;">'+ALLTRIM(oApp:nomb_emp)+'</h1>'+;
            '	            </div>'+;
            ''+;
            '	            <div style="padding: 40px 30px; ">'+;
            '	                <p style="line-height: 1.5; margin-bottom: 20px;">Estimados,</p>'+;
            '	                <p style="line-height: 1.5; margin-bottom: 20px;">Le enviamos un documento importante generado automaticamente desde nuestro sistema de gestion.</p>'+;
            '	                '+;
            '	                <div style="background-color: #f3f4f6; border-radius: 6px; padding: 20px; border-left: 4px solid #4b5563; margin: 25px 0;">'+;
            '	                    <strong>Referencia:</strong> '+ALLTRIM(cAsunto)+'<br>'+;
            '	                </div>'+;
            ' '+;
            '	                <p style="line-height: 1.5; margin-bottom: 20px;">En el archivo adjunto encontrara todos los detalles relacionados con este envio.</p>'+;
            '	                '+;
            '	                <div style="font-size: 13px; color: #6b7280; font-style: italic; background-color: #eff6ff; padding: 10px; border-radius: 4px; border: 1px dashed #bfdbfe;">'+;
            '	                    <strong>Nota:</strong> Si tiene alguna duda o necesita realizar una consulta sobre este documento, puede <strong>responder directamente a este email</strong>. Su respuesta sera recibida por el departamento correspondiente.'+;
            '	                </div>'+;
            '	            </div>'+;
            '	            <div style="text-align: center; padding: 20px; font-size: 11px; color: #9ca3af;">'+;
            '					<p>Enviado de forma segura por <span>'+;
            '	                <a href="https://www.bcnsoft.com.ar" style="text-decoration: none; color: #FFAF22; font-weight: bold;">bcnsoft</a></span></p>'+;
            '	                <p>&copy; '+STR(YEAR(DATE()))+' Todos los derechos reservados.</p>'+;
            '	            </div>'+;
            '	        </div>'+;
            '	    </div>'+;
            '	</body>'+;
            '	</html>'
		:AddAttachment(cFile) 
		:Send()
	END WITH
CATCH oError
    MsgStop("Fallo en el servidor de mail, no se enviara el correo"+chr(10)+oError:description,"Atencion!")
END TRY
Procesando(.f.)
IF isError = .F.
    MsgWait( "Mensaje enviado correctamente a " + cDestino, " A V I S O ",0.2 )
    ELSE
    MsgStop("ERROR: Se ha producido un error al enviar un mensaje al buzon "+cDestino+CRLF+CRLF+"Descripción del Error: "+oError:Description, " E R R O R ")
ENDIF
return nil

*-------------------------------------------------*
Function ConfigMail(oWnd)
*-------------------------------------------------*
// Editor del archivo mail.ini: permite que el cliente defina la cuenta de
// correo (Gmail u otra) desde la cual se enviaran los mails. Si deja el
// usuario/contraseña vacios o destilda la opcion, el sistema sigue usando
// la cuenta predeterminada.

LOCAL oDlg, acor, oBot := ARRAY(2), lRta := .F.
LOCAL cIni := ".\mail.ini", oIni
LOCAL lUsar, lSSL, cSMTP, cPuerto, cUsuario, cPassword
LOCAL oChkUsar, oChkSSL, oGetSMTP, oGetPuerto, oGetUsu, oGetPass

INI oIni FILE cIni
lUsar     := ( ALLTRIM( oIni:Get( "cuenta", "usar", "0" ) ) == "1" )
cSMTP     := PADR( IIF( EMPTY( ALLTRIM( oIni:Get( "cuenta", "smtp", "" ) ) ),;
                        "smtp.gmail.com", ALLTRIM( oIni:Get( "cuenta", "smtp", "" ) ) ), 50 )
cPuerto   := PADR( IIF( EMPTY( ALLTRIM( oIni:Get( "cuenta", "puerto", "" ) ) ),;
                        "465", ALLTRIM( oIni:Get( "cuenta", "puerto", "" ) ) ), 6 )
lSSL      := ( ALLTRIM( oIni:Get( "cuenta", "ssl", "1" ) ) == "1" )
cUsuario  := PADR( ALLTRIM( oIni:Get( "cuenta", "usuario", "" ) ), 60 )
cPassword := PADR( ALLTRIM( oIni:Get( "cuenta", "password", "" ) ), 40 )

DEFINE DIALOG oDlg TITLE "Configuración de la cuenta de correo" ;
   FROM 05,15 TO 24,80 ICON oApp:oIco FONT oApp:oFont OF oWnd
oDlg:lHelpIcon := .F.

@ 08,10 CHECKBOX oChkUsar VAR lUsar ;
   PROMPT "Usar mi propia cuenta para enviar los correos" ;
   OF oDlg SIZE 230,12 PIXEL

@ 28,10 SAY "Servidor SMTP:" OF oDlg PIXEL SIZE 75,10 RIGHT
@ 26,90 GET oGetSMTP VAR cSMTP OF oDlg PIXEL SIZE 150,11

@ 44,10 SAY "Puerto:" OF oDlg PIXEL SIZE 75,10 RIGHT
@ 42,90 GET oGetPuerto VAR cPuerto OF oDlg PIXEL SIZE 40,11 PICTURE "@!"
@ 43,145 CHECKBOX oChkSSL VAR lSSL PROMPT "Usar SSL" OF oDlg SIZE 60,12 PIXEL

@ 60,10 SAY "Usuario (email):" OF oDlg PIXEL SIZE 75,10 RIGHT
@ 58,90 GET oGetUsu VAR cUsuario OF oDlg PIXEL SIZE 150,11

@ 76,10 SAY "Contraseña de aplicación:" OF oDlg PIXEL SIZE 75,10 RIGHT
@ 74,90 GET oGetPass VAR cPassword OF oDlg PIXEL SIZE 150,11

@ 96,10 SAY "Para Gmail: activá la verificación en 2 pasos y generá una " + ;
            "'contraseña de aplicación'. Si dejás el usuario y la contraseña " + ;
            "vacíos, se seguirá usando la cuenta predeterminada del sistema."+CHR(10)+ ;
            "(Solo aplicable a este punto de venta, puede usar un mail x PDV).";
   OF oDlg PIXEL SIZE 245,30

acor := AcepCanc( oDlg )
@ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Aceptar" OF oDlg SIZE 30,12 PIXEL ;
   ACTION ( lRta := .T., oDlg:End() )
@ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,12 PIXEL CANCEL ;
   ACTION ( lRta := .F., oDlg:End() )

ACTIVATE DIALOG oDlg CENTER

IF lRta
   oIni:Set( "cuenta", "usar",     IIF( lUsar, "1", "0" ) )
   oIni:Set( "cuenta", "smtp",     ALLTRIM( cSMTP ) )
   oIni:Set( "cuenta", "puerto",   ALLTRIM( cPuerto ) )
   oIni:Set( "cuenta", "ssl",      IIF( lSSL, "1", "0" ) )
   oIni:Set( "cuenta", "usuario",  ALLTRIM( cUsuario ) )
   oIni:Set( "cuenta", "password", STRTRAN( ALLTRIM( cPassword ), " ", "" ) )
   MsgInfo( "La configuración de correo se guardá correctamente.", "Aviso" )
ENDIF

RETURN nil