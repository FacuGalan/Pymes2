#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** DATOS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE DATOS()
LOCAL oGet:=ARRAY(5), hHand,base, oBot := ARRAY(2), aCor, lRta:=.F., oFont
   DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"datos ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE DIALOG oDlg TITLE "Datos de la empreza" FROM 05,15 TO 19,65;
   OF oApp:oWnd ICON oApp:oIco FONT oFont
   acor := AcepCanc(oDlg)
   base := oQry:GetRowObj()
   
   @ 07, 05 SAY "Razón social:"         OF oDlg PIXEL RIGHT SIZE 60,12
   @ 22, 05 SAY "Dirección:"            OF oDlg PIXEL RIGHT SIZE 60,12
   @ 37, 05 SAY "Localidad:"            OF oDlg PIXEL RIGHT SIZE 60,12
   @ 52, 05 SAY "N° de C.U.I.T:"        OF oDlg PIXEL RIGHT SIZE 60,12
   @ 67, 05 SAY "Recargo segundo Vto.:" OF oDlg PIXEL RIGHT SIZE 60,12

         
   @ 05, 70 GET oGet[1] VAR base:nomb_emp OF oDlg PIXEL PICTURE "@!" 
   @ 20, 70 GET oGet[2] VAR base:dire_emp OF oDlg PIXEL PICTURE "@!"
   @ 35, 70 GET oGet[3] VAR base:loca_emp OF oDlg PIXEL PICTURE "@!"
   @ 50, 70 GET oGet[4] VAR base:cuit_emp OF oDlg PIXEL PICTURE "99-99999999-9" RIGHT
   @ 65, 70 GET oGet[5] VAR base:reca  OF oDlg PIXEL PICTURE "9999999999.99" RIGHT

   
   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg:End() ) PIXEL CANCEL
  ACTIVATE DIALOG oDlg CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   cerrar(oQry) 
   RETURN 
ENDIF

TRY
   oQry:oRow := base 
   oQry:Save()
CATCH oError
   MsgStop(oError:description,"Error al grabar en la base")
END  


RETURN 


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( oQry )
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.


 