//********************************************************************
#include "fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
MEMVAR oApp
STATIC cVentana
PROCEDURE REP_PERSONA
   LOCAL oExpBar
   LOCAL oPanel1, bBloque
   LOCAL hHand, oWnd1, oQry
   
   oQry := oApp:oServer:Query( "SELECT item,id  FROM ge_"+oApp:cId+"consultas_per")
   IF oQry:nRecCount = 0
      MsgStop("No tiene reportes personalizados","Atencion")
      RETURN 
   ENDIF
   
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
   AADD(oApp:aVentanas,cVentana)
   
   DEFINE WINDOW oWnd1 TITLE "Reportes Personalizados" MDICHILD OF oApp:oWnd NOZOOM ICON oApp:oIco
   
   oWnd1:SetSize( 350, oApp:oWnd:oWndClient:nHeight())

   oExpBar = TExplorerBar():New()
   *--
   oPanel1 = oExpBar:AddPanel( " Reportes Personalizados" , ".\BITMAPS\rbnmenu.bmp"  )
   oPanel1:lSpecial:=.T.
   DO WHILE !oQry:Eof()
      bBloque := "{|| ArmaCons("+STR(oQry:id,3)+")}"
      bBloque := &bBloque
      oPanel1:AddLink( oQry:item, bBloque, ".\BITMAPS\REPORT.BMP")
      oQry:Skip()
   ENDDO
   
   oWnd1:oClient = oExpBar
   ACTIVATE WINDOW oWnd1 ON INIT oWnd1:move(0,0) VALID(cerrar(oQry))
 
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


******************************************************
** Armado de la consulta Sql
FUNCTION ArmaCons(i)
LOCAL cSql, oQryRes, oErr, aDatos := ARRAY(10), j, hIni, cOpc, aPic:=" ", aTit:=" ", aLen:= " ", oQry
oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"consultas_per WHERE id = " + ClipValue2Sql(i))
AFILL(aDatos," ")
IF !PideDatos(oQry,@adatos)
   RETURN nil
ENDIF   
cSql := ALLTRIM(oQry:sql)
FOR j := 1 to 10
    IF !EMPTY(aDatos[j])
       cSql := STRTRAN(cSql,"//PARAM"+STR(j,1)+"//",aDatos[j])
    ENDIF   
NEXT j
cSql := STRTRAN(cSql,"//ID//",oApp:cId)
CursorWait()
TRY
   oQryRes := oApp:oServer:Query(cSql)
CATCH oErr
   MsgStop( "Error en la consulta, verifique!!"+CHR(10)+;
            oErr:Operation+CHR(10)+oErr:Description,"Error SQL")
   RETURN nil         
END TRY
aPic      := oQry:Formato
aTit      := oQry:Titulo
aLen      := oQry:Ancho
aLen := ListToArray(aLen,"N")
aPic := ListToArray(aPic,"C")
aTit := ListToArray(aTit,"C")
Show(oQryRes)

oQryRes:End()
RETURN nil

*********************************************
** Pide datos por pantallas para setear Sql
STATIC FUNCTION PideDatos(oQry,aDatos)
LOCAL aSay := {}, aVar := {}, oBot := ARRAY(2), oGet := ARRAY(10), oDlg, lRta := .f., j, cTipo, aCor, oFont
FOR j := 1 to 10
    IF !EMPTY(oQry:FIELDGET(j+2))
       AADD(aSay,oQry:FIELDGET(j+12))
       cTipo := oQry:FIELDGET(j+2)
       DO CASE
          CASE cTipo = "F"
               AADD(aVar,DATE())
          CASE cTipo = "N"
               AADD(aVar,0)
          CASE cTipo = "A"
               AADD(aVar,SPACE(30))
       ENDCASE
    ENDIF   
NEXT j   
IF LEN(aVar) = 0
   RETURN .T.
ENDIF   
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg TITLE "Ingreso de datos" FROM 05,20 TO 2*LEN(aVar)+10,70 FONT oFont
   aCor := AcepCanc(oDlg)
   @ 05, 05 SAY aSay[1]             OF oDlg PIXEL
   @ 05, 65 GET oGet[1] VAR aVar[1] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[1])="N","999999","@!")
   IF LEN(aVar) > 1
      @ 20, 05 SAY aSay[2]             OF oDlg PIXEL
      @ 20, 65 GET oGet[2] VAR aVar[2] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[2])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 2
      @ 35, 05 SAY aSay[3]             OF oDlg PIXEL
      @ 35, 65 GET oGet[3] VAR aVar[3] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[3])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 3
      @ 50, 05 SAY aSay[4]             OF oDlg PIXEL
      @ 50, 65 GET oGet[4] VAR aVar[4] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[4])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 4
      @ 65, 05 SAY aSay[5]             OF oDlg PIXEL
      @ 65, 65 GET oGet[5] VAR aVar[5] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[5])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 5
      @ 80, 05 SAY aSay[6]             OF oDlg PIXEL
      @ 80, 65 GET oGet[6] VAR aVar[6] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[6])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 6
      @ 95, 05 SAY aSay[7]             OF oDlg PIXEL
      @ 95, 65 GET oGet[7] VAR aVar[7] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[7])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 7
      @110, 05 SAY aSay[8]             OF oDlg PIXEL
      @110, 65 GET oGet[8] VAR aVar[8] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[8])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 8
      @125, 05 SAY aSay[9]             OF oDlg PIXEL
      @125, 65 GET oGet[9] VAR aVar[9] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[9])="N","999999","@!")
   ENDIF   
   IF LEN(aVar) > 9
      @140, 05 SAY aSay[10]             OF oDlg PIXEL
      @140, 65 GET oGet[10] VAR aVar[10] OF oDlg PIXEL PICTURE IF(VALTYPE(aVar[10])="N","999999","@!")
   ENDIF   
   FOR j := 1 TO LEN(aVar)
       IF VALTYPE(aVar[j]) = "N"
          oGet[j]:nStyle:= nOr( oGet[j]:nStyle, ES_RIGHT )
          *SetWindowLong( oGet[j]:hWnd, GWL_STYLE,;
          *           nOr( GetWindowLong( oGet[j]:hWnd, GWL_STYLE ), SS_CENTER ) )   
       ENDIF              
   NEXT j
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Ok" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg:End() ) PIXEL
ACTIVATE DIALOG oDlg CENTER 
IF !lRta
   RETURN .F.
ENDIF

FOR j := 1 TO LEN(aVar)
   cTipo := ClipValue2Sql(aVar[j])   
   aDatos[j] := cTipo
NEXT j
RETURN .t. 


*** Convierte un texto separado por comas en un array
STATIC FUNCTION ListToArray(cText,cTipo)
LOCAL j, cIt:="", lEsp := .t., aArr := {}, cChar
FOR j := 1 TO LEN(cText)
   cChar := SUBSTR(cText,j,1)
   IF cChar = ","
      IF lEsp
         AADD(aArr,IF(cTipo="C",cIt,VAL(cIt)))
         cIt := ""
         lEsp := .t.
         ELSE
         lEsp := .t.
      ENDIF   
      ELSE
      cIt := cIt + cChar
   ENDIF   
NEXT j   
RETURN aArr  

*************************************************
** Visualizar consulta
*************************************************
STATIC function Show(oQryRes)

   local oDlg, oFont, oBrw, aCor


   DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-12
   DEFINE DIALOG oDlg SIZE 950,500 PIXEL TRUEPIXEL  FONT oFont ;
      TITLE "RESULTADO DEL REPORTE PERSONALIZADO"
   oDlg:lHelpIcon := .f.
   @  40,05 XBROWSE oBrw SIZE -20,-20 PIXEL OF oDlg ;
      DATASOURCE oQryRes AUTOCOLS CELL LINES NOBORDER

   XbrSetupBar( oBrw,oDlg )

   WITH OBJECT oBrw
      :CreateFromCode()
   END
   PintaBrw(oBrw,0)
   ACTIVATE DIALOG oDlg CENTERED
   RELEASE FONT oFont
return nil

STATIC function XbrSetupBar( oBrw,oDlg )   
      local oBtn
      @ 05,05 BTNBMP oBtn RESOURCE "EXCE" SIZE 36,36 PIXEL OF oDlg NOBORDER ;
        ACTION oBrw:ToExcel() TOOLTIP "Exportar a Excel"
      @ 05,45 BTNBMP oBtn RESOURCE "REPORT" SIZE 36,36 PIXEL OF oDlg NOBORDER ;
        ACTION oBrw:Report() TOOLTIP "Reporte impreso"  
      @ 05,85 BTNBMP oBtn RESOURCE "SALE" SIZE 36,36 PIXEL OF oDlg NOBORDER ;
        ACTION oDlg:End() TOOLTIP "Salir"      
return nil
