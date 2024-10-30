#include "FiveWin.ch"
#include "tdolphin.ch"

// ---------------------------------------------//
// ----------- BUSCADOR DE PRECIOS--------------// 
// ---------------------------------------------//
MEMVAR oApp
STATIC mtiempo := 11, lEstamarcando := .f.

PROCEDURE BUSCAPRE(vez)
LOCAL oIco, oGet, oSay1, oSay2, oSay3, oFont1, oFont2, oFont3, oFont4, oDlg,;
      mCodTar := 0, mnombre := SPACE(60), mfecha := DATE(), mhora := TIME(),;
      mpath, oSay4, oBit, i

    DEFINE ICON oIco RESOURCE "cmsoft" 
    DEFINE FONT oFont1 NAME "ARIAL" SIZE 14,-18 BOLD
    DEFINE FONT oFont2 NAME "ARIAL" SIZE 10, -20 BOLD
    DEFINE FONT oFont3 NAME "ARIAL" SIZE 20,-30 BOLD
    DEFINE FONT oFont4 NAME "ARIAL" SIZE 60,-120 BOLD
    DEFINE DIALOG oDlg RESOURCE "FICHADA" &&COLOR RGB(000,000,000),RGB(124,124,124)
    *oSay3:nClrFore := nRGB(255,0,0)
    oDlg:lHelpIcon := .f.
    REDEFINE GET oGet  VAR mCodtar  ID 113 PICTURE "99999999999999" OF oDlg;
                       FONT oFont1
    REDEFINE SAY oSay1 ID 114 OF oDlg FONT oFont2
    REDEFINE SAY oSay2 ID 115 OF oDlg FONT oFont3 COLOR CLR_BLUE &&RGB(125,125,0)
    REDEFINE SAY oSay3 ID 116 OF oDlg FONT oFont4
    REDEFINE SAY oSay4 ID 117 OF oDlg FONT oFont3 COLOR RGB(255,0,0)
    REDEFINE BTNBMP oBit NAME "BUSCAPRE" ID 199 OF oDlg ADJUST TRANSPARENT NOBORDER
    oSay1:SetText("Pase el producto por el lector")
    oSay2:SetText(" ")
    oSay3:SetText(" ")
    oSay4:SetText("CONSULTE SU PRECIO AQUI")
    oSay4:nClrText(RGB(nRandom(255),nRandom(255),nRandom(255)))
    oGet:bKeyDown := { | nKey, nFlags | IF(nKey==13,;
                     Fichada(mcodtar,oGet, oSay1, oSay2, oSay3,oDlg,oFont2),.f.)}

    ACTIVATE DIALOG oDlg CENTER ;
             ON PAINT oGet:SetFocus() ON INIT (DlgOnTop( .t.,oDlg:hWnd ) )
RETURN 

STATIC FUNCTION Fichada(mcodtar,oGet, oSay1, oSay2, oSay3,oWnd,oFont)
LOCAL cMensaje1 := "", cMensaje2 := "", lHuboError := .f., mfecha := DATE(), ;
      mhora := TIME(), multimo, oQry
IF lEstaMarcando
   RETURN nil
ENDIF
oGet:Assign()
mcodtar := oGet:Value
mtiempo := 0
IF mcodtar = 0
   RETURN nil
ENDIF
lEstaMarcando := .t.
oQry := oApp:oServer:Query("SELECT codigo,nombre,precioven FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(mcodtar))
IF oQry:nRecCount > 0
   oSay1:SetText("Codigo:"+STR(oQry:codigo,14))
   oSay2:SetText(ALLTRIM(oQry:nombre))
   oSay3:SetText(ALLTRIM("$ "+ALLTRIM(STR(oQry:precioven,10,2))))
   ELSE
   MsgBeep()
   oSay1:SetText("E R R O R      ARTICULO NO ENCONTRADO")
   oSay2:SetText(" ")
   oSay3:SetText(" ")
   lHuboError := .t.
ENDIF
oSay1:Refresh()
oSay2:Refresh()
oSay3:Refresh()
oGet:cText := 0
oGet:Refresh()
oQry:End()
lEstaMarcando := .f.
RETURN nil



******************************************************************************
// Funcion   : Abrirar
// Proposito : Abrir un archivo en red o exclusivo
// Parametros: archivo dbf, forma de apertura 1 o 2, y alias
// Variables : retorno: Variable logica que indica el exito o no


STATIC FUNCTION Cambiacolor(oDlg,oSay4)
*oSay4:nClrText := RGB(nRandom(255),nRandom(255),nRandom(255))
*oSay4:Refresh()
*oDlg:Setfocus()
RETURN nil

// Antonio Carlos Pantaglione
// Toninho@fwi.com.br
// Ago/2001



//----------------------------------------------------------------------------//

dll32 static function AcpOnTop( hWnd AS LONG, hWndInsertAfter AS LONG, x AS LONG, y AS LONG, cx AS LONG, cy AS LONG, wFlags AS LONG ) ;
      AS LONG PASCAL  FROM "SetWindowPos" LIB "User32.dll"

//----------------------------------------------------------------------------//