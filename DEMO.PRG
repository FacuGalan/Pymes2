#include "Fivewin.ch"
#include "hbcompat.ch"
*************************************************
** Demostracion
*************************************************

PROCEDURE Demo()
   LOCAL oForm, oBot    
       
       DEFINE DIALOG oForm TITLE  "Atención!";
       FROM 05,10 TO 12,37
       oForm:lHelpIcon := .f.
       @ 05,10 SAY "Este es un programa de demostración" OF oForm PIXEL
       @ 15,10 SAY "la funcion que acaba de seleccionar " OF oForm PIXEL
       @ 25,20 SAY "no se encuentra disponible" OF oForm PIXEL
       @ 40,38 BUTTON oBot PROMPT "&Aceptar" OF oForm SIZE 30,10 ;
           ACTION (oForm:End()) PIXEL CANCEL
       ACTIVATE DIALOG oForm CENTER
RETURN       
       