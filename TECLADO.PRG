#include "Fivewin.ch"
MEMVAR oApp
STATIC cTexto := ""
FUNCTION TeclaVir(oGet1,lLog,oWnd)
LOCAL oDlg, oBrw, oGet := ARRAY(6), ;
      oBit := ARRAY(45), i, j, aVar := ARRAY(6), oFont, oFont1, oFont2, oFont3,;
      oFont4, n := 1, aNumeros := {7,8,9,4,5,6,1,2,3,0},;
      aLogico := {.t.,.f.,.f.}, mimpresion
IF oWnd == nil
   oWnd := oApp:oWnd
ENDIF
aVar[1] := 0

     DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
     DEFINE DIALOG oDlg RESOURCE "KEYB_VIR" OF oWnd
     oDlg:lHelpIcon := .f.
     FOR i := 1 TO  10
         REDEFINE BTNBMP oBit[i] NAME "TEC1" ;
                       ACTION Teclado(::nId,n,oGet,aNumeros,oBit) ID i+179;
                       PROMPT STR(aNumeros[i],3) FONT oFont OF oDlg NOBORDER
     NEXT i
     REDEFINE BTNBMP oBit[11] NAME "TEC1" ACTION Punto(n,oGet) ID 190;
                       PROMPT " 00" FONT oFont OF oDlg NOBORDER
     REDEFINE BTNBMP oBit[12] NAME "TEC1" ACTION Borrar(n,oGet) ID 191;
                       PROMPT "<---" OF oDlg NOBORDER
     REDEFINE BTNBMP oBit[16] NAME "TEC3" ACTION oDlg:End();
                       ID 195;
                       PROMPT "E N T E R" OF oDlg NOBORDER
     REDEFINE GET oGet[1]  VAR aVar[1]  ID 192 PICTURE "99999999999.99" OF oDlg;
                       WHEN(aLogico[1])  FONT oFont
     oGet[1]:bGotFocus := {|| cTexto := "",n := 1}
     ACTIVATE DIALOG oDlg ON PAINT oGet[1]:SetFocus()
oGet1:cText := aVar[1]
oGet1:Refresh()
RETURN VAL(oGet[1]:cText) > 0

*********************************************
** Teclado Numerico
STATIC FUNCTION Teclado(i,n,oGet,aNum,oBit)
LOCAL numero := aNum[i-179]
IF LEN(cTexto) = 13
   RETURN nil
ENDIF
cTexto := cTexto + STR(numero,1)
IF !"."$oGet[n]:cText
   oGet[n]:cText := VAL(cTexto)
   ELSE
   oGet[n]:cText := VAL(cTexto) / 100
ENDIF
oBit[i-179]:GoUp()
oBit[i-179]:Refresh()
*oGet[n]:SetFocus()
oGet[n]:Refresh()
RETURN nil

*********************************************
** Tecla Punto
STATIC FUNCTION Punto(n,oGet)
cTexto := cTexto + "00"
IF !"."$oGet[n]:cText
   oGet[n]:cText := VAL(cTexto)
   ELSE
   oGet[n]:cText := VAL(cTexto) / 100
ENDIF
*oGet[n]:SetFocus()
oGet[n]:Refresh()
RETURN nil

*********************************************
** Tecla Backspace
STATIC FUNCTION Borrar(n,oGet)
cTexto := LEFT(cTexto,LEN(cTexto)-1)
oGet[n]:cText := VAL(cTexto)
oGet[n]:Refresh()
RETURN nil
 