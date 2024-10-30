#include "FiveWin.ch"
*-------------------------------------------------*
Function EnviarPorMail(cdestino,cAsunto,cReplyTo,cFile)
*-------------------------------------------------*

LOCAL loCfg, loMsg, oError, isError := .F.
local cSMTP := "smtp.gmail.com"
Local cPuerto := 465
Local cLogin := "notificacionbcnsoft@gmail.com"
Local cPassword := "nopdjhukkzkhorov"
local cRemitente:= "<Sistemas BCN SOFT>"
Local cMensaje := "Envio automatico desde el sistema para Pymes"+CRLF+CRLF+CRLF
local cSSL := .T., cAuth := .T.
local cFichero := nil
DEFAULT cReplyTo := cDestino, cFile := hb_CurDrive()+":\"+CurDir()+"\ADJUNTO.PDF"

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
loMsg := CREATEOBJECT ( "CDO.Message" )
WITH OBJECT loMsg
:Configuration = loCfg
:From = cRemitente
:ReplyTo := cReplyTo
:To = cDestino
:Subject = cAsunto
:MDNRequested = .f.
:HTMLBody = "<h1>Mail automatico generador por BCN SOFT</h1>"
:AddAttachment(cFile) 
:Send()
END WITH
Procesando(.f.)
IF isError = .F.
    MsgWait( "Mensaje enviado correctamente a " + cDestino, " A V I S O ",0.2 )
    ELSE
    MsgStop("ERROR: Se ha producido un error al enviar un mensaje al buzon "+cDestino+CRLF+CRLF+"Descripción del Error: "+oError:Description, " E R R O R ")
ENDIF
return nil