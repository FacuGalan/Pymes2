#include "fivewin.ch"
#include "report.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

MEMVAR oApp
STATIC oQryFue, oQryEti, oBrw
PROCEDURE planil
LOCAL aFon1, aFon2, aFon3, nCol1 := 0, nCol2 := 0, nCol3:= 0, lCodBarra :=.f., mbarra1,;
      oSay1, oSay2, oSay3, oBot1, oBot2, oDlg1, oDlg2, oDlg3, oFld, oBot10,;
      oBot01,oBot02,oBot03,oBot04,oBot05,oBot06, oBot07, oBot08, oBot09, oLbx,;
      oFon1 , oFon2, oFon3, oFont5, oCom, oGet, oGet1, oGet2, oGet3, oGet4,mfecha := DATE(), ;
      mfechah := DATE(), hHand, oQryAux,;
      mopc:=2, aTipo := {"Todos los Articulos", "Solo novedades","Articulos Puntuales"},;
      base, nFila, lOferta := .f., lDoble := .f., ;
      mrta := .f., aCor, oPrn, i, j, nRow, nCol,;
      x1, x2, x3, x4, x5, y, MaxFil, MaxCol, aFont, oChe, oChe1,;
      aMod := {"Modelo 1","Modelo 2","Modelo 3"}, mmod := 1, oCom1, aText, oFont
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryFue  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fuentes")
//CREO TABLA TEMPORAL PARA EL DETALLE DE LA FACTURA
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS etiqueT ( ";
    + "`CODIGO` bigint(14) NOT NULL,";
    + "`NOMBRE` varchar(50) DEFAULT NULL,";
    + "`PRECIOVEN` decimal(10,3) DEFAULT '0.00',";
    + "`CANT` INT(3) DEFAULT '1',";
    + "PRIMARY KEY (`CODIGO`)";
    + ") ENGINE=InnoDB DEFAULT CHARSET=utf8")
    
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE etiqueT")
oApp:oServer:NextResult()
oQryEti  := oApp:oServer:Query( "SELECT * FROM etiqueT")
oQryEti:Zap()

oFon1 := TFont():New(alltrim(oQryFue:cFace1)  ,oQryFue:nWidth1  ,oQryFue:nHeight1 ,.f.,oQryFue:lBold1,;
                   oQryFue:nEscape1,oQryFue:norienta1,oQryFue:nWeight1 ,oQryFue:lItalic1,;
                   oQryFue:lUnder1 ,oQryFue:lStrik1  ,oQryFue:nCharset1,oQryFue:nOutPre1,;
                   oQryFue:nClippr1,oQryFue:nQuality1)
oFon2 := TFont():New(alltrim(oQryFue:cFace2)  ,oQryFue:nWidth2  ,oQryFue:nHeight2 ,.f.,oQryFue:lBold2,;
                   oQryFue:nEscape2,oQryFue:norienta2,oQryFue:nWeight2 ,oQryFue:lItalic2,;
                   oQryFue:lUnder2 ,oQryFue:lStrik2  ,oQryFue:nCharset2,oQryFue:nOutPre2,;
                   oQryFue:nClippr2,oQryFue:nQuality2)
oFon3:= TFont():New(alltrim(oQryFue:cFace3)  ,oQryFue:nWidth3  ,oQryFue:nHeight3 ,.f.,oQryFue:lBold3,;
                   oQryFue:nEscape3,oQryFue:norienta3,oQryFue:nWeight3 ,oQryFue:lItalic3,;
                   oQryFue:lUnder3 ,oQryFue:lStrik3  ,oQryFue:nCharset3,oQryFue:nOutPre3,;
                   oQryFue:nClippr3,oQryFue:nQuality3)
ACTIVATE FONT oFon1
ACTIVATE FONT oFon2
ACTIVATE FONT oFon3
MaxFil := oQryFue:nMaxFil
MaxCol := oQryFue:nMaxCol

DEFINE DIALOG oDlg1 TITLE "Impresion de Etiquetas de precios" ;
       FROM 05,15 TO 26,75 OF oApp:oWnd ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
   
   @ 01, 01 FOLDEREX oFld OF oDlg1 PIXEL  PROMPT  {"Etiquetas","Configurar"} SIZE 237,acor[1]-12
   @ 05, 05 SAY "Emite etiquetas con:" OF oFld:aDialogs[1] PIXEL SIZE 49,10
   @ 20, 05 SAY "Rango de fechas:"     OF oFld:aDialogs[1] PIXEL SIZE 49,10
   @ 35, 05 SAY "Filas por hoja:"      OF oFld:aDialogs[1] PIXEL SIZE 49,10
   @ 35, 75 SAY "Columnas por hoja: "  OF oFld:aDialogs[1] PIXEL SIZE 49,10
   @ 05, 55 COMBOBOX oCom VAR mopc ITEMS aTipo SIZE 100,15 ;
            OF oFld:aDialogs[1] PIXEL ON CHANGE (Reto(mopc,mfecha,mfechah),oGet1:SetFocus())
   @ 20, 55 GET oGet  VAR mfecha  OF oFld:aDialogs[1] PIXEL WHEN (mopc = 2)
   @ 20,100 GET oGet3 VAR mfechah OF oFld:aDialogs[1] PIXEL WHEN (mopc = 2)
   @ 20,140 BUTTON oBot10 PROMPT "Elegir" OF oFld:aDialogs[1] SIZE 15,10  PIXEL;
        ACTION Reto(mopc,mfecha,mfechah) WHEN(mopc = 2 )
   @ 35, 55 GET oGet1 VAR MaxFil PICTURE "99" OF oFld:aDialogs[1] PIXEL
   @ 35,125 GET oGet2 VAR MaxCol PICTURE "99" OF oFld:aDialogs[1] PIXEL
   @ 25,160 CHECKBOX oChe1 VAR lDoble  PROMPT "Unidad+Bulto" OF oFld:aDialogs[1] PIXEL SIZE 40,10
   @ 37,160 CHECKBOX oChe  VAR lOferta PROMPT "Cartel oferta" OF oFld:aDialogs[1] PIXEL SIZE 40,10
   @ 55,200 BUTTON oBot07 PROMPT "Agr." OF oFld:aDialogs[1] SIZE 15,10  PIXEL;
        ACTION Alta(oBrw,oDlg1,lCodBarra) WHEN(mopc <> 2 )
   @ 70,200 BUTTON oBot08 PROMPT "Mod." OF oFld:aDialogs[1] SIZE 15,10  PIXEL;
        ACTION Modi(oBrw) WHEN(mopc <> 2 )
   @ 85,200 BUTTON oBot09 PROMPT "Bor." OF oFld:aDialogs[1] SIZE 15,10  PIXEL;
        ACTION Baja(oBrw) WHEN(mopc <> 2 )
   @ 07,160 CHECKBOX oGet4 VAR lCodBarra  PROMPT "Código Barras" OF oFld:aDialogs[1] PIXEL SIZE 45,10
   @ 55, 05 XBROWSE oBrw DATASOURCE oQryEti;
              COLUMNS "Codigo","Nombre","PrecioVen","Cant";
              HEADERS "Codigo","Nombre","Precio","Cant";
              SIZES 50,200,80,40;
              AUTOSORT OF oFld:aDialogs[1] ;
     SIZE 190,55 PIXEL 
   PintaBrw(oBrw,4)
   oBrw:CreateFromcode()     
   @ 05, 05 SAY "Fuente Nombre articulo:" OF oFld:aDialogs[2] PIXEL SIZE 60,10
   @ 35, 05 SAY "Fuente para precio:" OF oFld:aDialogs[2] PIXEL SIZE 60,10
   @ 65, 05 SAY "Fuente para codigo:" OF oFld:aDialogs[2] PIXEL SIZE 60,10
   @ 05, 70 SAY oSay1 PROMPT "ARTICULO NN" SIZE 100,25 FONT oFon1;
         OF oFld:aDialogs[2] PIXEL
   @ 20, 30 BUTTON oBot01 PROMPT "Fuente" OF oFld:aDialogs[2] SIZE 20,10  PIXEL;
        ACTION (oSay1:SelFont(oQryFue:color1), oSay1:Refresh())
   @ 35, 70 SAY oSay2 PROMPT "123.45" SIZE 100,25 OF oFld:aDialogs[2] ;
         FONT oFon2 PIXEL
   @ 50, 30 BUTTON oBot02 PROMPT "Fuente" OF oFld:aDialogs[2] SIZE 20,10  PIXEL;
        ACTION (oSay2:SelFont(oQryFue:color2), oSay2:Refresh())
   @ 65, 70 SAY oSay3 PROMPT "Codigo:999999" SIZE 100,25 FONT oFon3;
         OF oFld:aDialogs[2] PIXEL
   @ 80, 30 BUTTON oBot03 PROMPT "Fuente" OF oFld:aDialogs[2] SIZE 20,10  PIXEL;
        ACTION (oSay3:SelFont(oQryFue:color3), oSay3:Refresh())
   @ 95, 55 COMBOBOX oCom1 VAR mmod ITEMS aMod SIZE 100,100 PIXEL ;
         OF oFld:aDialogs[2] ;
         ON CHANGE  refrefont(mmod,oSay1,oSay2,oSay3,oGet1,oGet2)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir (F9)" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}
   oSay1:nClrText := oQryFue:color1
   oSay2:nClrText := oQryFue:color2
   oSay3:nClrText := oQryFue:color3
ACTIVATE DIALOG oDlg1 CENTER ON INIT oSay1:SetFocus()
IF !mrta
   cerrar()
   DEACTIVATE FONT oFon1
   DEACTIVATE FONT oFon2
   DEACTIVATE FONT oFon3
   RELEASE FONT oFon1
   RELEASE FONT oFon2
   RELEASE FONT oFon3
   RETURN
ENDIF
oQryFue:nMaxFil := MaxFil
oQryFue:nMaxCol := MaxCol
oQryFue:Save()
oQryEti:GOTOP()
oFon1 := TFont():New(oSay1:oFont:cFaceName,oSay1:oFont:nWidth,oSay1:oFont:nHeight,.f.,oSay1:oFont:lBold,;
                   oSay1:oFont:nEscapement,oSay1:oFont:norientation,oSay1:oFont:nWeight,oSay1:oFont:lItalic,;
                   oSay1:oFont:lUnderline,oSay1:oFont:lStrikeout,oSay1:oFont:nCharset,oSay1:oFont:nOutPrecision,;
                   oSay1:oFont:nClipprecision,oSay1:oFont:nQuality)
oFon2 := TFont():New(oSay2:oFont:cFaceName,oSay2:oFont:nWidth,oSay2:oFont:nHeight,.f.,oSay2:oFont:lBold,;
                   oSay2:oFont:nEscapement,oSay2:oFont:norientation,oSay2:oFont:nWeight,oSay2:oFont:lItalic,;
                   oSay2:oFont:lUnderline,oSay2:oFont:lStrikeout,oSay2:oFont:nCharset,oSay2:oFont:nOutPrecision,;
                   oSay2:oFont:nClipprecision,oSay2:oFont:nQuality)
oFon3 := TFont():New(oSay3:oFont:cFaceName,oSay3:oFont:nWidth,oSay3:oFont:nHeight,.f.,oSay3:oFont:lBold,;
                   oSay3:oFont:nEscapement,oSay3:oFont:norientation,oSay3:oFont:nWeight,oSay3:oFont:lItalic,;
                   oSay3:oFont:lUnderline,oSay3:oFont:lStrikeout,oSay3:oFont:nCharset,oSay3:oFont:nOutPrecision,;
                   oSay3:oFont:nClipprecision,oSay3:oFont:nQuality)
ACTIVATE FONT oFon1
ACTIVATE FONT oFon2
ACTIVATE FONT oFon3
IF !lCodBarra
    IF !lOferta
       PRINT oPrn NAME "Etiquetas de precios" PREVIEW
          nRow = oPrn:nVertRes() / MaxFil
          nCol = oPrn:nHorzRes() / MaxCol
          PAGE
          i  := 1
          j  := 1
          x1 := 10
          y  := 10
          x2 := 10 + oFon1:nHeight*2
          x3 := 10 + oFon1:nHeight*2 + oFon2:nHeight
          x4 := 10 + oFon1:nHeight*2 + oFon2:nHeight + oFon3:nHeight
             DO WHILE !oQryEti:EOF()             
                oPrn:Line(x1,00,x1,oPrn:nHorzRes())
                oPrn:Line(x1,y,oPrn:nVertRes(),y)
                oPrn:Say(x1,y,LEFT (oQryEti:nombre,25)   ,oFon1,,oSay1:nClrText,1,0)
                oPrn:Say(x1+oFon1:nHeight+10,y,RIGHT(oQryEti:nombre,25)   ,oFon1,,oSay1:nClrText,1,0)
                oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codigo))
                IF lDoble
                   oPrn:Say(x2,y,"$" + STR(oQryEti:precioven,10,2),oFon2,,oSay2:nClrText,1,0)
                   IF !Empty(oQryAux:medida) 
                      oPrn:Say(x3,y,"Precio x " + oQryAux:unimed + " " + ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,10,2)),oFon3,nCol,oSay3:nClrText,1,0)
                   ENDIF     
                   oPrn:Say(x4,y,"Cod. " +STR(oQryEti:codigo),oFon3,,oSay3:nClrText,1,0)
                   ELSE
                   oPrn:Say(x2,y,"$" + STR(oQryEti:precioven),oFon2,,oSay2:nClrText,1,0)               
                   IF !Empty(oQryAux:medida) 
                      oPrn:Say(x3,y,"Precio x " + oQryAux:unimed + " " + ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,10,2)),oFon3,nCol,oSay3:nClrText,1,0)
                   ENDIF     
                   oPrn:Say(x4,y,"Cod. " +STR(oQryEti:codigo) ,oFon3,,oSay3:nClrText,1,0)
                ENDIF
                oQryEti:Skip()
                IF j = MaxCol
                   y := 10
                   x1 := 10 + nRow*i
                   x2 := 10 + nRow*i + oFon1:nHeight *2
                   x3 := 10 + nRow*i + oFon1:nHeight *2 + oFon2:nHeight
                   x4 := 10 + nRow*i + oFon1:nHeight *2 + oFon2:nHeight + oFon3:nHeight
                   i ++
                   j := 1
                   ELSE
                   y := 10 + nCol*j
                   j ++
                ENDIF
                IF i > MaxFil
                   ENDPAGE
                   PAGE
                   x1 := 10
                   y  := 10
                   x2 := 10 + oFon1:nHeight*2
                   x3 := 10 + oFon1:nHeight*2 + oFon2:nHeight
                   x4 := 10 + oFon1:nHeight*2 + oFon2:nHeight + oFon3:nHeight
                   i  := 1
                   j  := 1
                ENDIF
             ENDDO
          ENDPAGE
       ENDPRINT
       ELSE
       PRINT oPrn NAME "Etiquetas de precios" PREVIEW
          nRow = oPrn:nVertRes() / MaxFil
          nCol = oPrn:nHorzRes() / MaxCol
          PAGE
          i  := 1
          j  := 1
          x1 := 10
          y  := 10
          x2 := 10 + oFon2:nHeight
          x3 := 10 + oFon1:nHeight + oFon2:nHeight
          x4 := 10 + oFon1:nHeight + oFon2:nHeight*2
          x5 := 10 + oFon1:nHeight + oFon2:nHeight*3         
             DO WHILE !oQryEti:EOF()            
                oPrn:Say(x1,y,"OFERTA"                     ,oFon2,,oSay2:nClrText,1,0)
                oPrn:Say(x2,y,LEFT(oQryEti:nombre,25)   ,oFon1,,oSay1:nClrText,1,0)
                oPrn:Say(x3,y,"$" + STR(oQryEti:precioven),oFon2,,oSay2:nClrText,1,0)
                oPrn:Say(x5,y,"Codigo " +STR(oQryEti:codigo),oFon3,,oSay3:nClrText,1,0)
                oQryEti:SKIP()
                IF j = MaxCol
                   y := 10
                   x1 := 10 + nRow*i
                   x2 := 10 + nRow*i + oFon2:nHeight
                   x3 := 10 + nRow*i + oFon1:nHeight + oFon2:nHeight
                   x4 := 10 + nRow*i + oFon1:nHeight + oFon2:nHeight*2
                   x5 := 10 + nRow*i + oFon1:nHeight + oFon2:nHeight*3
                   i ++
                   j := 1
                   ELSE
                   y := 10 + nCol*j
                   j ++
                ENDIF
                IF i > MaxFil
                   ENDPAGE
                   PAGE
                   x1 := 10
                   x1 := 10
                   y  := 10
                   x2 := 10 + oFon2:nHeight
                   x3 := 10 + oFon1:nHeight + oFon2:nHeight
                   x4 := 10 + oFon1:nHeight + oFon2:nHeight*2
                   x5 := 10 + oFon1:nHeight + oFon2:nHeight*3
                   i  := 1
                   j  := 1
                ENDIF
             ENDDO
          ENDPAGE
       ENDPRINT
    ENDIF
    ELSE 
    //Con codigo de barras
    AddFontResource( "Bar25ifh.ttf" )      
    DEFINE FONT oFont5 NAME "Bar 25i f HR"    SIZE oFon1:nWidth,oFon1:nHeight
    PRINT oPrn NAME "Etiquetas de Barras" PREVIEW
    nRow = oPrn:nVertRes() / MaxFil
    nCol = oPrn:nHorzRes() / MaxCol
    PAGE
    i  := 1
    j  := 1
    x1 := 10
    y  := 10
    x2 := 10 + oFon1:nHeight*2
    x3 := 10 + oFon1:nHeight*2 + oFon2:nHeight
    x4 := 10 + oFon1:nHeight*2 + oFon2:nHeight + oFont5:nHeight
       DO WHILE !oQryEti:EOF()             
          oPrn:Line(x1,00,x1,oPrn:nHorzRes())
          oPrn:Line(x1,y,oPrn:nVertRes(),y)
          oPrn:Say(x1,y,LEFT (oQryEti:nombre,25)   ,oFon1,,oSay1:nClrText,1,0)
          oPrn:Say(x1+oFon1:nHeight+10,y,RIGHT(oQryEti:nombre,25)   ,oFon1,,oSay1:nClrText,1,0)
          oPrn:Say(x2,y,"$" + STR(oQryEti:precioven,10,2),oFon2,,oSay2:nClrText,1,0)  
          mbarra1 := STR(oQryEti:codigo,14)
          mbarra1 := STRTRAN(mbarra1," ","0") 
          mbarra1 := CodigoBarra( mbarra1)             
          oPrn:Say(x3,y+100,mbarra1,oFont5,,oSay1:nClrText)          
          oQryEti:Skip()
          IF j = MaxCol
             y := 10
             x1 := 10 + nRow*i
             x2 := 10 + nRow*i + oFon1:nHeight *2
             x3 := 10 + nRow*i + oFon1:nHeight *2 + oFon2:nHeight
             x4 := 10 + nRow*i + oFon1:nHeight *2 + oFon2:nHeight + oFont5:nHeight
             i ++
             j := 1
             ELSE
             y := 10 + nCol*j
             j ++
          ENDIF
          IF i > MaxFil
             ENDPAGE
             PAGE
             x1 := 10
             y  := 10
             x2 := 10 + oFon1:nHeight*2
             x3 := 10 + oFon1:nHeight*2 + oFon2:nHeight
             x4 := 10 + oFon1:nHeight*2 + oFon2:nHeight + oFont5:nHeight
             i  := 1
             j  := 1
          ENDIF
       ENDDO
    ENDPAGE
 ENDPRINT
ENDIF

cerrar()
DEACTIVATE FONT oFon1
DEACTIVATE FONT oFon2
DEACTIVATE FONT oFon3
RELEASE FONT oFon1
RELEASE FONT oFon2
RELEASE FONT oFon3
RETURN

** Cerrar el archivo abierto
*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
oQryFue:End()
oQryEti:End()
oQryEti:End()
RELEASE oQryFue
RELEASE oQryEti
RELEASE oQryEti
RETURN .t.


*** Refrescar los fonts segun el modelo de etiqueta
STATIC FUNCTION RefreFont(mmod,oSay1,oSay2,oSay3,oGet1,oGet2)
LOCAL oF1,oF2,oF3
oQryFue:GOTO(mmod)
oF1 := TFont():New(alltrim(oQryFue:cFace1)  ,oQryFue:nWidth1  ,oQryFue:nHeight1 ,.f.,oQryFue:lBold1,;
                   oQryFue:nEscape1,oQryFue:norienta1,oQryFue:nWeight1 ,oQryFue:lItalic1,;
                   oQryFue:lUnder1 ,oQryFue:lStrik1  ,oQryFue:nCharset1,oQryFue:nOutPre1,;
                   oQryFue:nClippr1,oQryFue:nQuality1)
oF2 := TFont():New(alltrim(oQryFue:cFace2)  ,oQryFue:nWidth2  ,oQryFue:nHeight2 ,.f.,oQryFue:lBold2,;
                   oQryFue:nEscape2,oQryFue:norienta2,oQryFue:nWeight2 ,oQryFue:lItalic2,;
                   oQryFue:lUnder2 ,oQryFue:lStrik2  ,oQryFue:nCharset2,oQryFue:nOutPre2,;
                   oQryFue:nClippr2,oQryFue:nQuality2)
oF3:= TFont():New(alltrim(oQryFue:cFace3)  ,oQryFue:nWidth3  ,oQryFue:nHeight3 ,.f.,oQryFue:lBold3,;
                   oQryFue:nEscape3,oQryFue:norienta3,oQryFue:nWeight3 ,oQryFue:lItalic3,;
                   oQryFue:lUnder3 ,oQryFue:lStrik3  ,oQryFue:nCharset3,oQryFue:nOutPre3,;
                   oQryFue:nClippr3,oQryFue:nQuality3)
oSay1:nClrText := oQryFue:color1
oSay2:nClrText := oQryFue:color2
oSay3:nClrText := oQryFue:color3
oSay1:SetFont(oF1)
oSay2:SetFont(oF2)
oSay3:SetFont(oF3)
oSay1:Refresh()
oSay2:Refresh()
oSay3:Refresh()
oGet1:cText := oQryFue:nMaxFil
oGet2:cText := oQryFue:nMaxCol
oGet1:Refresh()
oGet2:Refresh()
RETURN nil


STATIC FUNCTION Alta(oLbx,oDlg,lCodBarra)
LOCAL mcodigo := 0, oDlg1,oGet1, oGet2, oGet3, oGet4,oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, acor, oBot1, oBot2,;
      mnombre := SPACE(45), mrta := .t., mprecio := 0, mincru := 0, mincrp := 0, muxb1 := 0, muxb2 := 0,;
      mbarra1 := 0, mbarra2 := 0, mbarra3 := 0, mcant := 1
DO WHILE mrta
DEFINE DIALOG oDlg1 TITLE "Agregar articulos" FROM 05,15 TO 15,70 OF oDlg
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Codigo:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 37, 05 SAY "Precio:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT


   @ 05, 45 GET oGet1 VAR mcodigo PICTURE "999999999999999" OF oDlg1 PIXEL;
                VALID(ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1)) RIGHT;
                ACTION(oGet1:cText:=0,ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1)) BITMAP "BUSC1"  
   @ 20, 45 GET oGet2 VAR mnombre PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 35, 45 GET oGet3 VAR mprecio PICTURE "99999999.999" OF oDlg1 PIXEL WHEN(.F.) RIGHT
   IF lCodBarra
      @ 37, 95 SAY "Cant:"  OF oDlg1 PIXEL SIZE 15,12 RIGHT   
      @ 35,120 GET oGet4 VAR mcant PICTURE "999" OF oDlg1 PIXEL RIGHT
   ENDIF

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Continuar" OF oDlg1 SIZE 30,10 ;
           ACTION (Alta1(@mcodigo,oGet1,oGet2,oGet3,mcant),mrta := .t., oDlg1:End()) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Finalizar" OF oDlg1 SIZE 30,10 ;
           ACTION (mrta := .f., oDlg1:End())  PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
ENDDO
oQryEti:Refresh()
oLbx:Refresh()
RETURN nil

STATIC FUNCTION Alta1(mcodigo,oGet1,oGet2,oGet3,mcant)
LOCAL oError 
TRY 
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven,cant)"+;
                        " VALUES ("+oGet1:cText+","+ClipValue2Sql(oGet2:cText)+","+oGet3:cText+","+STR(mcant)+")")
    oApp:oServer:CommitTransaction()
CATCH oError
   ValidaError(oError)
END TRY
mcodigo := 0
oGet1:SetFocus()
oGet1:Refresh()
oGet2:cText := SPACE(45)
oGet3:cText := 0
RETURN nil

STATIC FUNCTION ExisteCod(mcodigo,oGet1,oGet2,oGet3,oDlg)
LOCAL oQryArt := oApp:oServer:Query("SELECT codigo,nombre,precioven FROM ge_"+oApp:cId+"articu WHERE codigo = " +oGet1:cText)
IF oQryArt:nRecCount > 0
   oGet2:cText := oQryArt:nombre
   oGet3:cText := oQryArt:precioven
   RETURN .t.
   ELSE
   Buscar(oQryArt,oDlg,oGet1,oGet2)
   oGet3:cText := oQryArt:precioven
ENDIF
RETURN .t.

STATIC FUNCTION Modi(oLbx)
/*
LOCAL mcodigo := etiq->codigo
IF mcodigo = 0
   RETURN nil
ENDIF
MsgGet("Ingresar un codigo para etiquetas","Codigo:",@mcodigo,"9999999999999")
IF arti06->(DBSEEK(mcodigo))
   REPLACE etiq->codigo    WITH arti06->codigo,;
           etiq->nombre    WITH arti06->nombre,;
           etiq->precioven WITH arti06->precioven
   ELSE
   MsgAlert("Articulo no existe")
ENDIF
arti06->(DBSETORDER(1))
oLbx:Refresh()
*/
RETURN nil

STATIC FUNCTION Baja(oLbx)
LOCAL mcodigo := oQryEti:codigo
IF mcodigo = 0
   RETURN nil
ENDIF
oQryEti:Delete()
oLbx:Refresh()
RETURN nil

STATIC FUNCTION Reto(mopc,mfecha,mfechah)
DO CASE 
   CASE mopc = 1 
        oQryEti:ZAP()
        oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven) " + ;
                             "(SELECT codigo,nombre,precioven "+;
                             "FROM ge_"+oApp:cId+"articu)")
        oQryEti:Refresh()
   CASE mopc = 2
   		oQryEti:ZAP()
        oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven) " + ;
                             "(SELECT codigo,nombre,precioven "+;
                             "FROM ge_"+oApp:cId+"articu WHERE fecmod >= "+ClipValue2Sql(mfecha)+;
                             " AND fecmod <= "+ClipValue2Sql(mfechah)+")")
        oQryEti:Refresh()
   CASE mopc = 3

ENDCASE

oQryEti:GOTOP()
oBrw:Refresh()
oBrw:SetFocus()
RETURN nil


STATIC FUNCTION FormatText(oPrn,oFont,cText,nAncho)
LOCAL cFrase := "", nPosUltEsp := 0, aPalabras := {}, i, aLineas := {}
cText := ALLTRIM(cText)
FOR i := 1 TO LEN(cText)
    cFrase := cFrase + SUBSTR(cText,i,1)
    IF SUBSTR(cText,i,1) = " "
       IF !Empty(cFrase)
          AADD(aPalabras,cFrase)          
       ENDIF
       cFrase := ""
    ENDIF
NEXT i
IF !Empty(cFrase)
   AADD(aPalabras,cFrase)
ENDIF   
cFrase := ""
FOR i := 1 TO LEN(aPalabras)       
    IF oFont:nWidth*LEN(cFrase+aPalabras[i]) >= nAncho
       AADD(aLineas,cFrase)
       cFrase := ""
    ENDIF          
    cFrase := cFrase + aPalabras[i] + " "
NEXT i
IF !Empty(cFrase)
   AADD(aLineas,cFrase)
ENDIF   
RETURN aLineas


STATIC FUNCTION CodigoBarra( x )
LOCAL i, bar := {}, j := 0, bar1 := {}, cBarr := ""
   FOR i:= 33 to 122
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
   FOR i:= 161 to 170
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
FOR j := 1 TO LEN(x) STEP 2
    i := ASCAN(bar1,SUBSTR(x,j,2))
    cBarr := cBarr + bar[i]
NEXT j
RETURN "{"+cBarr+"}"