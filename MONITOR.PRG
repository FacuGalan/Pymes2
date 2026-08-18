#include "FiveWin.ch"
#include "tdolphin.ch"
#include "gif.ch"
#include "ttitle.ch"
#include "layout.ch"
#include "xbrowse.ch"
STATIC oQry, oActiveX, oBrw, oSay
MEMVAR oApp
function main()
	local oWnd
	local oMainLay
	local hLays := {=>}
	local hButtons := {=>}
	local hBrowses := {=>}
	local oFld, oTitle2, oFont3
	
	oApp := TApplication():New()
	oApp:oServer := Conectar()
	oQry := oApp:oServer:Query("SELECT t.*,te.nombre as ter FROM tur_turnos t "+;
                             "LEFT JOIN tur_terminal te on t.terminal = te.id "+;
                             "WHERE fecha = CURDATE() AND t.estado in (1,2)  and t.terminal is not null "+;
                             " ORDER BY t.horallama DESC LIMIT 20")

  AddFontResource( "AntennaComp-Regular.otf" )
  DEFINE FONT oFont3 NAME "AntennaComp Regular"     SIZE 30, 60 
	//DEFINE FONT oFont3 NAME "klavika-bold" size 30, 60 BOLD 

	define window oApp:oWnd STYLE nOr( WS_POPUP, WS_VISIBLE ) 
  oApp:oWnd:oFont := oFont3
	DEFINE TIMER oApp:oTimerReloj INTERVAL 4000 OF oApp:oWnd ACTION LlamaTurno()
    ACTIVATE TIMER oApp:oTimerReloj

	define layout hLays["MAIN"] of oApp:oWnd

	*define horizontal layout hLays["H1"] of hLays["MAIN"] size 75

	*@  0, 0  TITLE oTitle2 size 60, 460 of hLays["H1"] SHADOW topleft SHADOWSIZE 2 Round ;
  *   GRADIENT { { 1, RGB(96,250,62), RGB(96,195,82) } }
	*set layout control oTitle2 of hLays["H1"]

  *oTitle2:bResized = {| nType, nWidth, nHeight |  oTitle2:atext[1][1] := ( nHeight / 2 ) + ( GetTextWidth( oApp:oWnd:hDC, oTitle2:atext[1][3], oFont3:hFont ) / 2 ) }

    *@ 500, 10  TITLETEXT OF oTitle2 TEXT "Turnos Recaudación"  FONT oFont3 COLOR nRGB(238,091,153)

  	define horizontal layout hLays["H2"] of hLays["MAIN"]
    define horizontal layout hLays["H3"] of hLays["MAIN"]
  	 
    define vertical layout of hLays["H2"]
	  
  	define vertical layout hLays["H1_1"] of hLays["H2"]:aVLayout[1]
  	define vertical layout hLays["H1_2"] of hLays["H2"]:aVLayout[1]
  	
  	
	PlayVideo ( hLays["H1_1"] )
	Imagen( hLays["H1_2"] )
	Browse_turnos( hLays["H3"], oQry, oFont3 )

	activate window oApp:oWnd MAXIMIZED ON init ( hLays["H1_1"] ):SetFocus()

return nil

STATIC function Browse_turnos( oWnd, oQry, oFont )
LOCAL oFontG
DEFINE FONT oFontG NAME "AntennaComp Regular"     SIZE 60, 120
	@ 00, 00 XBROWSE oBrw DATASOURCE oQry;
		COLUMNS "turno","ter";
		HEADERS "Turno","Puesto";
		SIZES 350,350 OF oWnd SIZE 150, 400 PIXEL ON DBLCLICK oApp:oWnd:End()    COLOR  CLR_WHITE, nrgb(110,140,190) FONT oFont
   oBrw:aCols[1]:nDataStrAlign := 2
   oBrw:aCols[2]:nDataStrAlign := 2 
   oBrw:aCols[1]:nHeadStrAlign := 2
   oBrw:aCols[2]:nHeadStrAlign := 2 
   oBrw:aCols[1]:oDataFont := oFontG
   oBrw:aCols[2]:oDataFont := oFontG
   oBrw:aCols[2]:bStrData := {|| right( ALLTRIM(oQry:ter), 1 )}
   PintaBrw(oBrw,0,oFont) 
   oBrw:CreateFromCode()
   PintaBrw(oBrw,0,oFont)
   set layout control oBrw of oWnd
return nil

STATIC function Pone_hora( oWnd,oFont )
	@ 00, 00 SAY oSay PROMPT DTOC(DATE())+ " - " + LEFT(Time(),5) OF oWnd SIZE 88, 200 PIXEL  FONT oFont COLOR CLR_WHITE, nRGB(19, 141, 117)
   set layout control oSay of oWnd
return nil



// ----------------------------------------------//
// -----------  Variables Globales del PRG ------//
// ----------------------------------------------//

//----------------------------------------------------------------------------//
 CLASS TApplication
   DATA   oWnd       // Pantalla Principal
   DATA   oServer    // Conexion con el servidor de base de datos
   DATA   nPosTur    // Posicion Turnos
   DATA   nPosPue    // Posicion puesto
   DATA   nPosTip    // Posicion tipo tramite
   DATA   nPos1      // Posicion 1ra linea
   DATA   nPos2      // Posicion 2ra linea
   DATA   nCada      // Espacio entre lineas
   DATA   prefijo    // Punto de venta
   DATA   oTimerReloj// Timer Reloj
   DATA   oFontReloj // Font Reloj             
   DATA   ultimo     //Ultimo turno llamado
   DATA   cTime      // Ultimo llamado   
   DATA   nTamLet1   // Fuente turnos 1
   DATA   nTamLet2   // Fuente turnos 2

   METHOD New() CONSTRUCTOR


ENDCLASS

//----------------------------------------------------------------//

METHOD New() CLASS TApplication

   SET DATE FORMAT "DD/MM/YYYY"
   SET DELETE ON
   SET CONFIRM ON
   SET SOFTSEEK ON
   SET 3DLOOK ON
   SetHandleCount(100)
   SetBalloon(.t.)
   D_SetCaseSensitive(.f.)
   HB_LANGSELECT( 'ESWIN' )
   HB_SetCodePage("ESMWIN")   
   // Inicializacion de valores   
   ::ultimo := 0
   ::prefijo   := 0   
return Self



****************************************************
** Llama turno en recaudacion
STATIC FUNCTION LlamaTurno()
LOCAL i, lLlamar := .f., aRellamar := {}, cLocucion := "", cText := " ", nLen
*oSay:SetText(DTOC(DATE())+ " - " + LEFT(Time(),5))
oQry:GoTop()
nLen := oQry:nRecCount
cText := oQry:turno
oQry:Refresh()
oBrw:Refresh()
IF oQry:turno <> cText .or. nLen <> oQry:nRecCount
   lLlamar := .t.
   cLocucion := '"'+ALLTRIM(oQry:turno)+';'+ALLTRIM(oQry:ter)+'"'
   IF EMPTY(oQry:ter) .or. oQry:nRecCount = 0
      cLocucion := '"Reinicio del turnero;aguarde por favor "'
   ENDIF
ENDIF

IF lLlamar 
   SndPlaySound("BITMAPS\dingdong.wav",0)   
   WinExec( "balcon.exe -v 100 -s -2 -n helena -t "+cLocucion ,0)
ENDIF
RETURN nil


******************************
** Mostrar Video
STATIC FUNCTION PlayVideo( oWnd)
oActiveX = TActiveX():New( oWnd, "WMPlayer.OCX" )
__KeyBoard(chr(13))
oWnd:oClient = oActiveX
oActiveX:Settings:Volume := 1.5
oActiveX:Settings:SetMode("loop",.t.)
oActiveX:uiMode = "none"
oActiveX:url =".\BITMAPS\video.mp4"
set layout control oActiveX of oWnd
Return NIL
******************************
** Mostrar Imagen
STATIC function Imagen (oWnd)
local oImg
@ 00, 00 IMAGE oImg OF oWnd FILE ".\BITMAPS\FONDOMONI.JPG" SIZE 350,350 NOBORDER ADJUST UPDATE
set layout control oImg of oWnd
return nil

***************************************************************************
** Pinta los browse
FUNCTION PintaBrw(oBrw,C,oFont)
LOCAL i,nColTam,nFaltante 
     
     oBrw:bClrStd := { || If( oBrw:KeyNo() % 2 == 0, ;
                         { CLR_WHITE,nrgb(110,140,190) }, ;
                         { CLR_WHITE,nrgb(80,160,120) } ) }
     oBrw:SetFont( oFont, .t. )
     oBrw:nStretchCol := STRETCHCOL_LAST
     oBrw:l2007 := .f.
     oBrw:bClrHeader := { || { CLR_WHITE, nRGB(170,100,130) } }
     *oBrw:lColDividerComplete  := .t.                    
     oBrw:nColDividerStyle     := 0
     oBrw:nRowDividerStyle     := 0
     oBrw:nHeadDividerStyle    := 0
     oBrw:lFooter := oBrw:lHScroll := oBrw:lVScroll := oBrw:lRecordSelector := .f.


     **************************************AJUSTAR COLUMNAS********************************
     IF C> 0 
      nColTam:=0
      FOR i := 1 TO C
       nColTam:= (nColTam + oBrw:aCols[ i ]:nWidth)
      NEXT
      IF nColTam < 761
         nFaltante:= 761 - nColTam - 1.5
         oBrw:aCols[ C ]:nWidth:= (oBrw:aCols[ C ]:nWidth + nFaltante)
      ENDIF   
     ENDIF
RETURN nil 

DLL32 FUNCTION BWCCRegister( hInst AS LONG) AS WORD PASCAL LIB "BWCC32.DLL" 

REQUEST HB_LANG_ESWIN
REQUEST HB_CODEPAGE_ESMWIN


