#include "fivewin.ch"
#include "report.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

MEMVAR oApp
STATIC oQryFue, oQryEti, oBrw, nOrientation, nWidthPage, nHeightPage,;
       lImprimeLista2,cNombreLista1,cNombreLista2 // Las defino globales para no tener que pasarla a todos lados (CAMBIO FACU)

// Constantes de separaci贸n entre etiquetas y m谩rgenes internos (en CM)
// GAP: espacio ENTRE recuadros de etiquetas (evita solapamiento de bordes)
#define GAP_V         0.30
#define GAP_H         0.30
// MARGEN: espacio entre el borde del recuadro y el contenido interior
#define MARGEN_SUP    0.15
#define MARGEN_INF    0.10
#define MARGEN_LAT    0.15

PROCEDURE planil
LOCAL aFon1, aFon2, aFon3, nCol1 := 0, nCol2 := 0, nCol3:= 0, lCodBarra :=.f., mbarra1,;
      oSay1, oSay2, oSay3, oBot1, oBot2, oDlg1, oDlg2, oDlg3, oFld,;
      oBot01,oBot02,oBot03,oBot04,oBot05,oBot06, oBot07, oBot08, oBot09, oBot10, oBot11, oLbx,;
      oFon1 , oFon2, oFon3, oFon4, oFont5, oCom, oGet, oGet1, oGet2, oGet3, oGet4, oGet5, oGet6,oGet7,oGet8,;
      mfecha := DATE(), ;
      mfechah := DATE(), mhorad := "00:00:00", mhorah := "23:59:59", hHand, oQryAux, aText := {},;
      aSay := ARRAY(3),;
      mopc:=2, aTipo := {"Todos los Articulos", "Solo novedades","Articulos Puntuales"},;
      base, nFila, lOferta := .f., lLogo := .f., lVto := .f.,;
      mrta := .f., aCor, oPrn, i, j, nRow, nCol,;
      x1, x2, x3, x4, x5, y, MaxFil, MaxCol, aFont, oChe, oChe1, oChe2, oChe3, oChe4, oChe5,;
      aMod := {"Modelo 1","Modelo 2","Modelo 3"}, mmod := 1, oCom1,  oFont, oError, aUnit,;
      lSinDecimales := .f., nDecimales := 2,nAncho, ;
      aOrientacion := {"Vertical","Horizontal"}, oCom2
nOrientation := 1
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryFue  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fuentes")
lImprimeLista2:=.F.
cNombreLista1:= "Lista 1"+SPACE(100)
cNombreLista2:= "Lista 2"+SPACE(100)
IF oQryFue:FieldName(1) <> 'id'
  CreateFont()   
  oQryFue  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fuentes")
  oQryFue:GoTop()
  mmod := oQryFue:id
  ELSE 
  oQryFue:GoTop()
  mmod := oQryFue:id
ENDIF
//CREO TABLA TEMPORAL PARA EL DETALLE DE LA FACTURA
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS etiqueT ( ";
    + "`CODIGO` bigint(14) NOT NULL,";
    + "`NOMBRE` varchar(200) DEFAULT NULL,";
    + "`PRECIOVEN` decimal(12,3) DEFAULT '0.00',";
    + "`REVENTA` decimal(12,3) DEFAULT '0.00',";
    + "`NETO` decimal(12,3) DEFAULT '0.00',";
    + "`NETO2` decimal(12,3) DEFAULT '0.00',";
    + "`CANT` INT(3) DEFAULT '1',";
    + "`HORAMOD` TIME DEFAULT NULL,";
    + "`FECMOD` DATE DEFAULT NULL,";
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
AADD(aText,oFon1:cFaceName + " de " + STR(oFon1:nWeight,5))
AADD(aText,oFon2:cFaceName + " de " + STR(oFon2:nWeight,5))
AADD(aText,oFon3:cFaceName + " de " + STR(oFon1:nWeight,5))
DEFINE DIALOG oDlg1 TITLE "Impresion de Etiquetas de precios" FROM 05,15 TO 37,115 OF oApp:oWnd ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
      
   @ 07, 05 SAY "Emite etiquetas con:" OF oDlg1 PIXEL SIZE 49,10
   @ 22, 05 SAY "Rango de fechas:"     OF oDlg1 PIXEL SIZE 49,10
   @ 37, 05 SAY "Rango de horas:"      OF oDlg1 PIXEL SIZE 49,10
   @ 52, 05 SAY "Filas por hoja:"      OF oDlg1 PIXEL SIZE 49,10
   @ 52, 75 SAY "Columnas por hoja: "  OF oDlg1 PIXEL SIZE 49,10

   @ 05, 60 COMBOBOX oCom VAR mopc ITEMS aTipo SIZE 85,15 ;
            OF oDlg1 PIXEL ON CHANGE (Reto(mopc,mfecha,mfechah,mhorad, mhorah),oGet1:SetFocus())
   @ 20, 60 GET oGet  VAR mfecha  OF oDlg1 PIXEL WHEN (mopc = 2)
   @ 20,105 GET oGet3 VAR mfechah OF oDlg1 PIXEL WHEN (mopc = 2)
   @ 35, 60 GET oGet5 VAR mhorad  OF oDlg1 PIXEL WHEN (mopc = 2)
   @ 35,105 GET oGet6 VAR mhorah  OF oDlg1 PIXEL WHEN (mopc = 2)
   @ 20,145 BUTTON oBot10 PROMPT "Elegir" OF oDlg1 SIZE 19,12  PIXEL;
        ACTION Reto(mopc,mfecha,mfechah,mhorad,mhorah) WHEN(mopc = 2 )
   @ 50, 60 GET oGet1 VAR MaxFil PICTURE "99" OF oDlg1 PIXEL
   @ 50,130 GET oGet2 VAR MaxCol PICTURE "99" OF oDlg1 PIXEL

   @ 05,170 CHECKBOX oGet4 VAR lCodBarra  PROMPT "C骴igo Barras" OF oDlg1 PIXEL SIZE 45,10
   @ 18,170 CHECKBOX oChe2 VAR lVto    PROMPT "C/Fecha cambio" OF oDlg1 PIXEL SIZE 45,10 WHEN (!lCodBarra)
   @ 31,170 CHECKBOX oChe1 VAR lLogo   PROMPT "Con Logo" OF oDlg1 PIXEL SIZE 40,10
   @ 44,170 CHECKBOX oChe  VAR lOferta PROMPT "Cartel oferta" OF oDlg1 PIXEL SIZE 40,10
   @ 57,170 CHECKBOX oChe3 VAR lSinDecimales    PROMPT "Precios sin decimales" OF oDlg1 PIXEL SIZE 65,10


   @ 70,200 BUTTON oBot07 PROMPT "Agregar" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION Alta(oBrw,oDlg1,lCodBarra) WHEN(mopc > 1 )
   @ 85,200 BUTTON oBot08 PROMPT "Modificar" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION Modi(oBrw,oDlg1) WHEN(mopc > 1 )
   @100,200 BUTTON oBot09 PROMPT "Borrar" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION Baja(oBrw) WHEN(mopc > 1 )
   @115,200 BUTTON oBot11 PROMPT "X Compras" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION PorCompra(oBrw) WHEN(mopc > 1 )
   @130,200 SAY "Orientacion" OF oDlg1 SIZE 40,12 PIXEL     
   @140,200 COMBOBOX oCom2 VAR nOrientation ITEMS aOrientacion  OF oDlg1 SIZE 50,12 PIXEL
   
   @ 70, 05 XBROWSE oBrw DATASOURCE oQryEti;
              COLUMNS "Codigo","Nombre","PrecioVen","Cant","fecmod","horamod";
              HEADERS "Codigo","Nombre","Precio","Cant","fecha","hora";
              SIZES 50,200,80,40,80,80;
              AUTOSORT OF oDlg1 ;
     SIZE 190,150 PIXEL 
   oBrw:aCols[4]:nEditType := EDIT_GET  
   oBrw:aCols[4]:bEditWhen := {|| lCodBarra}

   PintaBrw(oBrw,6)
   oBrw:nFreeze := 2
   oBrw:CreateFromcode()     

   @ 05, 255 SAY "Modelo" OF oDlg1 PIXEL SIZE 60,10
   @ 13, 255 COMBOBOX oCom1 VAR mmod ITEMS aMod SIZE 60,12 PIXEL ;
         OF oDlg1 ;
         ON CHANGE  refrefont(mmod,oSay1,oSay2,oSay3,oGet1,oGet2)

   @ 25, 255 SAY "Fuente Nombre articulo" OF oDlg1 PIXEL SIZE 60,10
   @ 35, 255 SAY aSay[1] PROMPT aText[1] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color1
   @ 25, 300 SAY oSay1 PROMPT IF(oQryEti:nRecCount>0,oQryEti:nombre,"NOMBRE ARTICULO") SIZE 200,55 FONT oFon1;
         OF oDlg1 PIXEL
   @ 57, 255 BUTTON oBot01 PROMPT "Elegir letra" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION (oSay1:SelFont(oQryFue:color1), oSay1:Refresh(),aText[1]:=oSay1:oFont:cFaceName + " de " + STR(oSay1:oFont:nWeight,5),aSay[1]:nClrText := oSay1:nClrText,aSay[1]:Refresh())

   @ 75, 255 SAY "Fuente para precio" OF oDlg1 PIXEL SIZE 60,10
   @ 85, 255 SAY aSay[2] PROMPT aText[2] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color2
   @ 85, 255 SAY oSay2 PROMPT IF(oQryEti:nRecCount>0,"$ "+STR(oQryEti:precioven,2),"$ 9999.99") SIZE 200,55 OF oDlg1 ;
         FONT oFon2 PIXEL
   @107, 255 BUTTON oBot02 PROMPT "Elegir letra" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION (oSay2:SelFont(oQryFue:color2), oSay2:Refresh(),aText[2]:=oSay2:oFont:cFaceName + " de " + STR(oSay2:oFont:nWeight,5),aSay[2]:nClrText := oSay2:nClrText,aSay[2]:Refresh())


   @125, 255 SAY "Fuente para codigo" OF oDlg1 PIXEL SIZE 60,10
   @135, 255 SAY aSay[3] PROMPT aText[3] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color3
   @135, 255 SAY oSay3 PROMPT IF(oQryEti:nRecCount>0,"C骴igo: "+STR(oQryEti:codigo),"C骴igo: 9999999") SIZE 200,55 FONT oFon3;
         OF oDlg1 PIXEL
   @157, 255 BUTTON oBot03 PROMPT "Elegir letra" OF oDlg1 SIZE 40,12  PIXEL;
        ACTION (oSay3:SelFont(oQryFue:color3), oSay3:Refresh(),aText[3]:=oSay3:oFont:cFaceName + " de " + STR(oSay3:oFont:nWeight,5),aSay[3]:nClrText := oSay3:nClrText, aSay[3]:Refresh())
   
   @175, 255 CHECKBOX oChe4 VAR lImprimeLista2  PROMPT "Imprimir precio de lista 1 y 2" OF oDlg1 PIXEL SIZE 120,12
   @192, 255 SAY "Nombre lista 1:" OF oDlg1 PIXEL SIZE 40,12 RIGHT PICTURE "@" 
   @190, 300 GET oGet7 VAR cNombreLista1  OF oDlg1 PIXEL SIZE 80,12 WHEN(lImprimeLista2)
   @207, 255 SAY "Nombre lista 2:" OF oDlg1 PIXEL SIZE 40,12 RIGHT PICTURE "@"
   @205, 300 GET oGet8 VAR cNombreLista2  OF oDlg1 PIXEL SIZE 80,12 WHEN(lImprimeLista2)

   

   @200 ,200 BUTTON oBot1 PROMPT "&Previsualizar" OF oDlg1 SIZE 40,20 ;
           ACTION Prev(MaxFil,MaxCol, oSay1, oSay2, oSay3, oQryEti, lCodBarra, lLogo, lOferta, lVto,IF(lSinDecimales,0,2)) PIXEL WHEN(oQryEti:nRecCount>0)


   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir (F9)" OF oDlg1 SIZE 35,12 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL WHEN(oQryEti:nRecCount>0)
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 35,12 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}
   oSay1:nClrText := oQryFue:color1
   oSay2:nClrText := oQryFue:color2
   oSay3:nClrText := oQryFue:color3
ACTIVATE DIALOG oDlg1 CENTER ON INIT (oSay1:Hide(), oSay2:Hide(), oSay3:Hide())
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
Procesando(.t.)
nDecimales := IF(lSinDecimales,0,2)
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
oFon4 := TFont():New(oSay2:oFont:cFaceName,oSay2:oFont:nWidth*.2,oSay2:oFont:nHeight*.2,.f.,oSay2:oFont:lBold,;
                   oSay2:oFont:nEscapement,oSay2:oFont:norientation,oSay2:oFont:nWeight,oSay2:oFont:lItalic,;
                   oSay2:oFont:lUnderline,oSay2:oFont:lStrikeout,oSay2:oFont:nCharset,oSay2:oFont:nOutPrecision,;
                   oSay2:oFont:nClipprecision,oSay2:oFont:nQuality)
ACTIVATE FONT oFon1
ACTIVATE FONT oFon2
ACTIVATE FONT oFon3
IF !lCodBarra
   IF !lOferta
      // ============================================================
      // IMPRESION NORMAL (sin oferta, sin codigo de barras)
      // ============================================================
      PRINT oPrn NAME "Previsualizar" PREVIEW
         ConfigPagina(oPrn, MaxFil, MaxCol)
         oPrn:SetPage(9) 
         i  := 1
         j  := 1
         PAGE          
         
         DO WHILE !oQryEti:EOF()  
             FOR x2 := 1 TO oQryEti:cant           
             nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
             nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
             
             ImprimirEtiquetaNormal(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                    nRow, nCol, MaxFil, MaxCol, ;
                                    lLogo, lVto, nDecimales, aSay)
             
             AvanzarPosicion(@i, @j, @oPrn, MaxFil, MaxCol)
             NEXT x2
             oQryEti:Skip()
         ENDDO  
         ENDPAGE
         Procesando(.f.)
      ENDPRINT
      ELSE
      // ============================================================
      // IMPRESION CON CARTEL DE OFERTA
      // ============================================================
      PRINT oPrn NAME "Previsualizar" PREVIEW
         ConfigPagina(oPrn, MaxFil, MaxCol)
         oPrn:SetPage(9)
         PAGE
         i  := 1
         j  := 1
         DO WHILE !oQryEti:EOF()            
             nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
             nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
             
             ImprimirEtiquetaOferta(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                    nRow, nCol, MaxFil, MaxCol, ;
                                    lLogo, lVto, nDecimales, aSay)
             
             AvanzarPosicion(@i, @j, @oPrn, MaxFil, MaxCol)
             oQryEti:Skip()
            ENDDO
         ENDPAGE
         Procesando(.f.)
      ENDPRINT
   ENDIF
   ELSE 
   // ============================================================
   // IMPRESION CON CODIGO DE BARRAS
   // ============================================================
   AddFontResource( "i2of5txt.ttf" )      
   DEFINE FONT oFont5 NAME "Interleaved 2of5 Text"    SIZE oFon1:nWidth,oFon1:nHeight
   PRINT oPrn NAME "Previsualizar" PREVIEW 
   ConfigPagina(oPrn, MaxFil, MaxCol)
   oPrn:SetPage(9)   
   PAGE
     i  := 1    
     j  := 1 
     DO WHILE !oQryEti:EOF()      
         FOR x2 := 1 TO oQryEti:cant       
         nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
         nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
         
         ImprimirEtiquetaBarras(oPrn, oFon1, oFon2, oFont5, ;
                                nRow, nCol, MaxFil, MaxCol, ;
                                lLogo, nDecimales, aSay)
         
         AvanzarPosicion(@i, @j, @oPrn, MaxFil, MaxCol)
         NEXT x2            
         oQryEti:Skip()
         
      ENDDO
   ENDPAGE
   Procesando(.f.)
ENDPRINT
ENDIF
oQryFue:cFace1   := oSay1:oFont:cFaceName
oQryFue:cFace2   := oSay2:oFont:cFaceName
oQryFue:cFace3   := oSay3:oFont:cFaceName
oQryFue:nHeight1 := oSay1:oFont:nHeight  
oQryFue:nHeight2 := oSay2:oFont:nHeight  
oQryFue:nHeight3 := oSay3:oFont:nHeight  
oQryFue:nwidth1  := oSay1:oFont:nwidth   
oQryFue:nwidth2  := oSay2:oFont:nwidth   
oQryFue:nwidth3  := oSay3:oFont:nwidth   
oQryFue:color1   := oSay1:nClrText       
oQryFue:color2   := oSay2:nClrText       
oQryFue:color3   := oSay3:nClrText       
oQryFue:lBold1   := oSay1:oFont:lBold    
oQryFue:lBold2   := oSay2:oFont:lBold    
oQryFue:lBold3   := oSay3:oFont:lBold    
oQryFue:nEscape1 := oSay1:oFont:nEscapement
oQryFue:nEscape2 := oSay2:oFont:nEscapement
oQryFue:nEscape3 := oSay3:oFont:nEscapement
oQryFue:nOrienta1 := oSay1:oFont:nOrientation
oQryFue:nOrienta2 := oSay2:oFont:nOrientation
oQryFue:nOrienta3 := oSay3:oFont:nOrientation
oQryFue:nWeight1 := oSay1:oFont:nWeight     
oQryFue:nWeight2 := oSay2:oFont:nWeight     
oQryFue:nWeight3 := oSay3:oFont:nWeight     
oQryFue:lItalic1 := oSay1:oFont:lItalic     
oQryFue:lItalic2 := oSay2:oFont:lItalic     
oQryFue:lItalic3 := oSay3:oFont:lItalic     
oQryFue:lUnder1  := oSay1:oFont:lUnderline  
oQryFue:lUnder2  := oSay2:oFont:lUnderline  
oQryFue:lUnder3  := oSay3:oFont:lUnderline  
oQryFue:lStrik1  := oSay1:oFont:lStrikeOut  
oQryFue:lStrik2  := oSay2:oFont:lStrikeOut  
oQryFue:lStrik3  := oSay3:oFont:lStrikeOut  
oQryFue:ncharset1 := oSay1:oFont:nCharset    
oQryFue:ncharset2 := oSay2:oFont:nCharset    
oQryFue:ncharset3 := oSay3:oFont:nCharset    
oQryFue:nOutPre1 := oSay1:oFont:nOutPrecision
oQryFue:nOutPre2 := oSay2:oFont:nOutPrecision
oQryFue:nOutPre3 := oSay3:oFont:nOutPrecision
oQryFue:nClippr1 := oSay1:oFont:nClipPrecision
oQryFue:nClippr2 := oSay2:oFont:nClipPrecision
oQryFue:nClippr3 := oSay3:oFont:nClipPrecision
oQryFue:nQuality1 := oSay1:oFont:nQuality     
oQryFue:nQuality2 := oSay2:oFont:nQuality     
oQryFue:nQuality3 := oSay3:oFont:nQuality     
oQryFue:nMaxFil   := Maxfil
oQryFue:nMaxCol   := MaxCol
oQryFue:Save()
cerrar()
DEACTIVATE FONT oFon1
DEACTIVATE FONT oFon2
DEACTIVATE FONT oFon3
DEACTIVATE FONT oFon4
RELEASE FONT oFon1
RELEASE FONT oFon2
RELEASE FONT oFon3
RELEASE FONT oFon4
RETURN

// ============================================================
// FUNCIONES AUXILIARES DE IMPRESION DE ETIQUETAS
// ============================================================

************************************
** Configura orientaci髇 y tama駉o de p醙ina
STATIC FUNCTION ConfigPagina(oPrn, MaxFil, MaxCol)
   IF nOrientation = 1
      oPrn:SetPortrait()
      nWidthPage := (21.0-1.6)
      nHeightPage := (29.7-2.4)
   ELSE 
      oPrn:SetLandscape()
      nWidthPage := (29.7-2.4)
      nHeightPage := (21.0-1.6)
   ENDIF   
RETURN NIL

************************************
** Avanza posici髇 de fila/columna y maneja salto de p醙ina
STATIC FUNCTION AvanzarPosicion(i, j, oPrn, MaxFil, MaxCol)
   j++
   IF j > MaxCol
      j := 1               
      i++               
   ENDIF
   IF i > MaxFil
      ENDPAGE
      PAGE
      i := 1
      j := 1
   ENDIF
RETURN NIL

************************************
** Dibuja el recuadro de la etiqueta y retorna dimensiones y posici髇 del contenido
** El recuadro se dibuja DENTRO de la celda, dejando GAP_V/2 arriba/abajo y GAP_H/2 izq/der
** El contenido se ubica DENTRO del recuadro con m醨genes MARGEN_SUP/INF/LAT
** Par醡etros de salida (por referencia):
**   nAltoContenido  - altura disponible para el contenido
**   nAnchoContenido - ancho disponible para el contenido  
**   nIniRow         - fila donde empieza el contenido
**   nIniCol         - columna donde empieza el contenido
STATIC FUNCTION DibujarRecuadro(oPrn, nRow, nCol, MaxFil, MaxCol, ;
                                nAltoContenido, nAnchoContenido, nIniRow, nIniCol)
LOCAL aUnit, nAltoCelda, nAnchoCelda, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight, ;
      nBoxAlto, nBoxAncho

   nAltoCelda  := nHeightPage / MaxFil
   nAnchoCelda := nWidthPage / MaxCol
   
   // Posici髇 del recuadro: inset GAP/2 en cada lado de la celda
   nBoxTop    := nRow + (GAP_V / 2)
   nBoxLeft   := nCol + (GAP_H / 2)
   nBoxBottom := nRow + nAltoCelda - (GAP_V / 2)
   nBoxRight  := nCol + nAnchoCelda - (GAP_H / 2)
   
   // Dibujar recuadro
   aUnit := oPrn:Units2Pix(nBoxTop, nBoxLeft, nBoxBottom, nBoxRight, 'CM')
   oPrn:RoundBox(aUnit[2], aUnit[1], aUnit[4], aUnit[3], 50, 50)
   
   // Tama駉 del recuadro
   nBoxAlto  := nBoxBottom - nBoxTop
   nBoxAncho := nBoxRight - nBoxLeft
   
   // Posici髇 y tama駉 del 羠ea de contenido (dentro del recuadro)
   nIniRow         := nBoxTop + MARGEN_SUP
   nIniCol         := nBoxLeft + MARGEN_LAT
   nAltoContenido  := nBoxAlto - MARGEN_SUP - MARGEN_INF
   nAnchoContenido := nBoxAncho - (MARGEN_LAT * 2)

RETURN NIL

************************************
** Imprime una etiqueta NORMAL (sin oferta, sin c骴igo de barras)
** Proporciones del contenido (suman 1.0 sobre nAltoContenido):
**   Con 1 lista: Nombre 0.35 + Precio 0.25 + SinImp 0.20 + C骴igo 0.20
**   Con 2 listas: Nombre 0.30 + T韙ulos 0.12 + Precios 0.20 + SinImp 0.18 + C骴igo 0.20
STATIC FUNCTION ImprimirEtiquetaNormal(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                        nRow, nCol, MaxFil, MaxCol, ;
                                        lLogo, lVto, nDecimales, aSay)
LOCAL x1, oQryAux, nAncho, nAltoContenido := 0, nAnchoContenido := 0, ;
      nIniRow := 0, nIniCol := 0

   DibujarRecuadro(oPrn, nRow, nCol, MaxFil, MaxCol, ;
                   @nAltoContenido, @nAnchoContenido, @nIniRow, @nIniCol)
   
   oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed,fecmod FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codigo))
   
   IF lLogo 
      @ nIniRow, nIniCol;
      PRINT TO oPrn IMAGE '.\LOGO.JPG' SIZE 1.2,1.2 CM 
   ENDIF
   
   IF lImprimeLista2
      // --- MODO 2 LISTAS ---
      // Nombre del art铆culo (30%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.30 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText
      
      // T铆tulos de listas (12%)
      nAncho := nAnchoContenido / 2
      @ x1, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista1) ;
                SIZE nAncho, nAltoContenido * 0.12 CM FONT oFon2 ALIGN "TC"      
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista2) ;
                SIZE nAncho, nAltoContenido * 0.12 CM FONT oFon2 ALIGN "TC" LASTROW x1
      
      // Precios (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" COLOR aSay[2]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:reventa,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
      
      // Precios sin impuestos (18%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.18 CM FONT oFon4 ALIGN "TC" COLOR aSay[2]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto2,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.18 CM FONT oFon4 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
      
      // C贸digo y precio por unidad (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + ALLTRIM(oQryAux:unimed) + " $"+;
                ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + ALLTRIM(oQryAux:unimed) + " $"+;
                ALLTRIM(STR(oQryEti:reventa*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText
   ELSE
      // --- MODO 1 LISTA ---
      // Nombre del art铆culo (35%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.35 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText
      
      // Precio (25%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,10,nDecimales)) ;
                SIZE nAnchoContenido, nAltoContenido * 0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
      
      // Precio sin impuestos (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto,10,nDecimales)) ;
                SIZE nAnchoContenido, nAltoContenido * 0.20 CM FONT oFon4 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
      
      // C贸digo y precio por unidad (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + ALLTRIM(oQryAux:unimed) + " $"+;
                ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAnchoContenido, nAltoContenido * 0.20 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText
   ENDIF

RETURN NIL

************************************
** Imprime una etiqueta con CARTEL DE OFERTA
** Proporciones del contenido (suman 1.0 sobre nAltoContenido):
**   Con 1 lista: Oferta 0.15 + Nombre 0.30 + Precio 0.25 + SinImp 0.15 + C贸digo 0.15
**   Con 2 listas: Oferta 0.12 + Nombre 0.23 + T铆tulos 0.10 + Precios 0.20 + SinImp 0.15 + C贸digo 0.20
STATIC FUNCTION ImprimirEtiquetaOferta(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                        nRow, nCol, MaxFil, MaxCol, ;
                                        lLogo, lVto, nDecimales, aSay)
LOCAL x1, oQryAux, nAncho, nAltoContenido := 0, nAnchoContenido := 0, ;
      nIniRow := 0, nIniCol := 0

   DibujarRecuadro(oPrn, nRow, nCol, MaxFil, MaxCol, ;
                   @nAltoContenido, @nAnchoContenido, @nIniRow, @nIniCol)
   
   oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed,fecmod FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codigo))
   
   IF lLogo 
      @ nIniRow, nIniCol;
      PRINT TO oPrn IMAGE '.\LOGO.JPG' SIZE 1.0,1.0 CM 
   ENDIF
   
   IF lImprimeLista2
      // --- OFERTA + 2 LISTAS ---
      // Cartel OFERTA (12%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT " O F E R T A " ;
                SIZE nAnchoContenido, nAltoContenido * 0.12 CM FONT oFon2 ALIGN "TC" LASTROW x1
      
      // Nombre del art铆culo (23%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.23 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText
      
      // T铆tulos de listas (10%)
      nAncho := nAnchoContenido / 2
      @ x1, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista1) ;
                SIZE nAncho, nAltoContenido * 0.10 CM FONT oFon2 ALIGN "TC"      
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista2) ;
                SIZE nAncho, nAltoContenido * 0.10 CM FONT oFon2 ALIGN "TC" LASTROW x1
      
      // Precios (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" COLOR aSay[2]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:reventa,12,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
      
      // Precios sin impuestos (15%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.15 CM FONT oFon4 ALIGN "TC" COLOR aSay[2]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto2,10,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.15 CM FONT oFon4 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
      
      // C贸digo y precio por unidad (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x" + ALLTRIM(oQryAux:unimed) + " $" +;
                ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText 
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x" + ALLTRIM(oQryAux:unimed) + " $" +;
                ALLTRIM(STR(oQryEti:reventa*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText 
   ELSE
      // --- OFERTA + 1 LISTA ---
      // Cartel OFERTA (15%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT " O F E R T A " ;
                SIZE nAnchoContenido, nAltoContenido * 0.15 CM FONT oFon2 ALIGN "TC" LASTROW x1
      
      // Nombre del art铆culo (30%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.30 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText
      
      // Precio (25%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                SIZE nAnchoContenido, nAltoContenido * 0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
      
      // Precio sin impuestos (15%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "Sin imp. $" + ALLTRIM(STR(oQryEti:neto,10,nDecimales)) ;
                SIZE nAnchoContenido, nAltoContenido * 0.15 CM FONT oFon4 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText   
      
      // C贸digo y precio por unidad (15%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x" + ALLTRIM(oQryAux:unimed) + " $" +;
                ALLTRIM(STR(oQryEti:precioven*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                " "),"")+ " C骴." +ALLTRIM(STR(oQryEti:codigo))+;
                IF(lVto," "+DTOC(oQryAux:fecmod),"");
                SIZE nAnchoContenido, nAltoContenido * 0.15 CM FONT oFon3 ALIGN "TC" COLOR aSay[3]:nClrText     
   ENDIF

RETURN NIL

************************************
** Imprime una etiqueta con CODIGO DE BARRAS
** Proporciones del contenido (suman 1.0 sobre nAltoContenido):
**   Con 1 lista: Nombre 0.35 + Precio 0.25 + CodBarras 0.40
**   Con 2 listas: Nombre 0.30 + T铆tulos 0.10 + Precios 0.20 + CodBarras 0.40
STATIC FUNCTION ImprimirEtiquetaBarras(oPrn, oFon1, oFon2, oFont5, ;
                                        nRow, nCol, MaxFil, MaxCol, ;
                                        lLogo, nDecimales, aSay)
LOCAL x1, oQryAux, nAncho, nAltoContenido := 0, nAnchoContenido := 0, ;
      nIniRow := 0, nIniCol := 0, mbarra1

   DibujarRecuadro(oPrn, nRow, nCol, MaxFil, MaxCol, ;
                   @nAltoContenido, @nAnchoContenido, @nIniRow, @nIniCol)
   
   oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codigo))
   
   IF lLogo 
      @ nIniRow, nIniCol;
      PRINT TO oPrn IMAGE '.\LOGO.JPG' SIZE 1.0,1.0 CM 
   ENDIF
   
   IF lImprimeLista2
      // --- BARRAS + 2 LISTAS ---
      // Nombre del art铆culo (30%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.30 CM FONT oFon1 ALIGN "C" LASTROW x1 COLOR aSay[1]:nClrText
      
      // T铆tulos de listas (10%)
      nAncho := nAnchoContenido / 2
      @ x1, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista1) ;
                SIZE nAncho, nAltoContenido * 0.10 CM FONT oFon2 ALIGN "TC"      
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT ALLTRIM(cNombreLista2) ;
                SIZE nAncho, nAltoContenido * 0.10 CM FONT oFon2 ALIGN "TC" LASTROW x1
      
      // Precios (20%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" COLOR aSay[2]:nClrText
      @ x1, nIniCol + nAncho;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:reventa,12,nDecimales)) ;
                SIZE nAncho, nAltoContenido * 0.20 CM FONT oFon2 ALIGN "TC" LASTROW x1 COLOR aSay[2]:nClrText
   ELSE
      // --- BARRAS + 1 LISTA ---
      // Nombre del art铆culo (35%)
      @ nIniRow, nIniCol;
         PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                SIZE nAnchoContenido, nAltoContenido * 0.35 CM FONT oFon1 ALIGN "C" LASTROW x1 COLOR aSay[1]:nClrText
      
      // Precio (25%)
      @ x1, nIniCol;
         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                SIZE nAnchoContenido, nAltoContenido * 0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
   ENDIF
   
   // C贸digo de barras (40%)
   mbarra1 := STR(oQryEti:codigo,14)
   mbarra1 := STRTRAN(mbarra1," ","0") 
   mbarra1 := CodigoBarra( mbarra1)  
   @ x1, nIniCol PRINT TO oPrn TEXT mbarra1;
             SIZE nAnchoContenido, nAltoContenido * 0.40 CM FONT oFont5 ALIGN "C"

RETURN NIL


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
      mbarra1 := 0, mbarra2 := 0, mbarra3 := 0, mcant := 1, mneto :=0, mneto2 :=0,nReventa:= 0
DO WHILE mrta
DEFINE DIALOG oDlg1 TITLE "Agregar articulos" FROM 05,15 TO 15,70 OF oDlg
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Codigo:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 37, 05 SAY "Precio:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT


   @ 05, 45 GET oGet1 VAR mcodigo PICTURE "999999999999999" OF oDlg1 PIXEL;
                VALID(ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1,@mneto,@mneto2,@nReventa)) RIGHT;
                ACTION(oGet1:cText:=0,ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1,@mneto,@mneto2,@nReventa)) BITMAP "BUSC1"  
   @ 20, 45 GET oGet2 VAR mnombre PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 35, 45 GET oGet3 VAR mprecio PICTURE "999999999.999" OF oDlg1 PIXEL WHEN(.F.) RIGHT
   IF lCodBarra
      @ 37, 95 SAY "Cant:"  OF oDlg1 PIXEL SIZE 15,12 RIGHT   
      @ 35,120 GET oGet4 VAR mcant PICTURE "999" OF oDlg1 PIXEL RIGHT
   ENDIF

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Continuar" OF oDlg1 SIZE 30,10 ;
           ACTION (Alta1(@mcodigo,oGet1,oGet2,oGet3,mcant,mneto,mneto2,nReventa),mrta := .t., oDlg1:End()) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Finalizar" OF oDlg1 SIZE 30,10 ;
           ACTION (mrta := .f., oDlg1:End())  PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
ENDDO
oQryEti:Refresh()
oLbx:Refresh()
RETURN nil

STATIC FUNCTION Alta1(mcodigo,oGet1,oGet2,oGet3,mcant,mneto,mneto2,nReventa)
LOCAL oError 
TRY 
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven,reventa,cant,neto,neto2)"+;
                        " VALUES ("+oGet1:cText+","+ClipValue2Sql(oGet2:cText)+","+oGet3:cText+","+ClipValue2Sql(nReventa)+","+;
                        STR(mcant)+","+STR(mneto,12,2)+","+STR(mneto2,12,2)+")")
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

STATIC FUNCTION ExisteCod(mcodigo,oGet1,oGet2,oGet3,oDlg,mneto,mneto2,nReventa)
LOCAL oQryArt := oApp:oServer:Query("SELECT codigo,nombre,precioven,reventa,iva,impint FROM ge_"+oApp:cId+"articu WHERE codigo = " +oGet1:cText)
IF oQryArt:nRecCount > 0
   oGet2:cText := oQryArt:nombre
   oGet3:cText := oQryArt:precioven
   mneto := oQryArt:precioven - oQryArt:impint 
   mneto := mneto - IF(oQryArt:iva = 5, mneto * 21 / 121,IF(oQryArt:iva = 4, mneto * 10.5 / 110.5,mneto ))
   mneto2 := oQryArt:reventa - oQryArt:impint 
   mneto2 := mneto2 - IF(oQryArt:iva = 5, mneto2 * 21 / 121,IF(oQryArt:iva = 4, mneto2 * 10.5 / 110.5,mneto2 ))
   nReventa:= oQryArt:reventa
   RETURN .t.
   ELSE
   BuscarArt(oQryArt,oDlg,oGet1,oGet2)
   oGet3:cText := oQryArt:precioven
   mneto := oQryArt:precioven - oQryArt:impint
   mneto := mneto - IF(oQryArt:iva = 5, mneto * 21 / 121,IF(oQryArt:iva = 4, mneto * 10.5 / 110.5,mneto ))
   mneto2 := oQryArt:reventa - oQryArt:impint
   mneto2 := mneto2 - IF(oQryArt:iva = 5, mneto2 * 21 / 121,IF(oQryArt:iva = 4, mneto2 * 10.5 / 110.5,mneto2 ))
   nReventa:= oQryArt:reventa
ENDIF
RETURN .t.

STATIC FUNCTION Modi(oLbx,oDlg)
LOCAL mcodigo := oQryEti:codigo, oDlg1,oGet1, oGet2, oGet3, oGet4,oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, acor, oBot1, oBot2,;
      mnombre := SPACE(45), mrta := .t., mprecio := 0, mincru := 0, mincrp := 0, muxb1 := 0, muxb2 := 0,;
      mbarra1 := 0, mbarra2 := 0, mbarra3 := 0, mcant := 1, mneto :=0, mneto2 :=0,nReventa:= 0, oError
DEFINE DIALOG oDlg1 TITLE "Modificar articulos" FROM 05,15 TO 15,70 OF oDlg
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Codigo:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @ 37, 05 SAY "Precio:"         OF oDlg1 PIXEL SIZE 35,12 RIGHT


   @ 05, 45 GET oGet1 VAR mcodigo PICTURE "999999999999999" OF oDlg1 PIXEL;
                VALID(ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1,@mneto,@mneto2,@nReventa)) RIGHT;
                ACTION(oGet1:cText:=0,ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1,@mneto,@mneto2,@nReventa)) BITMAP "BUSC1"  
   @ 20, 45 GET oGet2 VAR mnombre PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 35, 45 GET oGet3 VAR mprecio PICTURE "999999999.999" OF oDlg1 PIXEL WHEN(.F.) RIGHT
   //IF lCodBarra
      @ 37, 95 SAY "Cant:"  OF oDlg1 PIXEL SIZE 15,12 RIGHT   
      @ 35,120 GET oGet4 VAR mcant PICTURE "999" OF oDlg1 PIXEL RIGHT
   //ENDIF

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION (mrta := .t., oDlg1:End()) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Salir" OF oDlg1 SIZE 30,10 ;
           ACTION (mrta := .f., oDlg1:End())  PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mrta 
   RETURN nil 
ENDIF
TRY 
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("UPDATE etiqueT SET codigo = "+ClipValue2Sql(mcodigo)+","+;
                               "nombre = "+ClipValue2Sql(mnombre)+","+;
                               "precioven = "+ClipValue2Sql(mprecio)+","+;
                               "reventa = "+str(nReventa)+","+;
                               "cant = "+STR(mcant)+","+;
                               "neto = "+STR(mneto,12,2)+","+;
                               "neto2 = "+STR(mneto2,12,2)+" "+;
                               " WHERE codigo = "+STR(oQryEti:codigo))
   oApp:oServer:CommitTransaction()
CATCH oError
   ValidaError(oError)
END TRY    
oQryEti:Refresh()
oLbx:Refresh()
RETURN nil

STATIC FUNCTION Baja(oLbx)
LOCAL mcodigo := oQryEti:codigo
IF mcodigo = 0
   RETURN nil
ENDIF
oQryEti:Delete()
oLbx:Refresh()
RETURN nil

STATIC FUNCTION Reto(mopc,mfecha,mfechah,mhorad,mhorah)
DO CASE 
   CASE mopc = 1 
        oQryEti:ZAP()
        oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven,reventa,neto,neto2) " + ;
                             "(SELECT codigo,nombre,precioven,reventa,precioven / IF(iva=5,1.21,IF(iva=4,1.105,1)),reventa / IF(iva=5,1.21,IF(iva=4,1.105,1)) "+;
                             "FROM ge_"+oApp:cId+"articu)")
        oQryEti:Refresh()
   CASE mopc = 2
   		oQryEti:ZAP()
        oApp:oServer:Execute("INSERT INTO etiqueT (codigo,nombre,precioven,reventa,fecmod,horamod,neto,neto2) " + ;
                             "(SELECT codigo,nombre,precioven,reventa,fecmod,horamod,precioven / IF(iva=5,1.21,IF(iva=4,1.105,1)),reventa / IF(iva=5,1.21,IF(iva=4,1.105,1)) "+;
                             "FROM ge_"+oApp:cId+"articu "+;
                             " WHERE fecmod >= "+ClipValue2Sql(mfecha)+;
                             " AND fecmod <= "+ClipValue2Sql(mfechah)+;
                             IF(mhorad = "00:00:00"," ",;
                              " AND horamod >= " +ClipValue2Sql(mhorad) +;
                              " AND horamod <= "+ClipValue2Sql(mhorah))+;
                             " ORDER BY fecmod,horamod)")
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


************************************
** Codigo de barra de un numero
STATIC FUNCTION CodigoBarra( x )
LOCAL i, bar := {}, j := 0, bar1 := {}, cBarr := ""
   FOR i := 48 TO 97
       AADD(bar ,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
   FOR i := 192 TO 241
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
FOR j := 1 TO LEN(x)-1 STEP 2
    i := ASCAN(bar1,SUBSTR(x,j,2))
    cBarr := cBarr + bar[i]
NEXT j
RETURN "("+cBarr+")"

********************************
** Previsualizacion
** Usa las mismas funciones de impresi贸n que la impresi贸n real
STATIC FUNCTION Prev(MaxFil,MaxCol, oSay1, oSay2, oSay3, oQryEti, lCodBarra, lLogo, lOferta, lVto,nDecimales)
LOCAL oFon1, oFon2, oFon3, oFon4,  nRow, nCol, oPrn , i, j , x1, x2, x3, x4, x5, y , h, oQryAux, oFont5, ;
      mbarra1, aUnit, nAncho, aSay := ARRAY(3)
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
oFon4 := TFont():New(oSay2:oFont:cFaceName,oSay2:oFont:nWidth*.2,oSay2:oFont:nHeight*.2,.f.,oSay2:oFont:lBold,;
                   oSay2:oFont:nEscapement,oSay2:oFont:norientation,oSay2:oFont:nWeight,oSay2:oFont:lItalic,;
                   oSay2:oFont:lUnderline,oSay2:oFont:lStrikeout,oSay2:oFont:nCharset,oSay2:oFont:nOutPrecision,;
                   oSay2:oFont:nClipprecision,oSay2:oFont:nQuality)
ACTIVATE FONT oFon1
ACTIVATE FONT oFon2
ACTIVATE FONT oFon3

// Crear array aSay simulado para la previsualizaci贸n con los colores actuales
aSay[1] := oSay1
aSay[2] := oSay2
aSay[3] := oSay3

IF !lCodBarra
    IF !lOferta
       // ============================================================
       // PREVIEW NORMAL (sin oferta, sin c贸digo de barras)
       // ============================================================
       PRINT oPrn NAME "Etiquetas de precios" PREVIEW MODAL
          ConfigPagina(oPrn, MaxFil, MaxCol)
          oPrn:SetPage(9)
          i := 1
          j := 1
          PAGE
          FOR h := 1 TO 3
            nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
            nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
            
            ImprimirEtiquetaNormal(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                   nRow, nCol, MaxFil, MaxCol, ;
                                   lLogo, lVto, nDecimales, aSay)
            
            oQryEti:Skip()
            j++
            IF j > MaxCol
               j := 1               
               i ++               
            ENDIF
            IF i > MaxFil
               ENDPAGE
               PAGE
               i  := 1
               j  := 1
            ENDIF
          NEXT h  
          ENDPAGE
       ENDPRINT
       ELSE 
       // ============================================================
       // PREVIEW CON CARTEL DE OFERTA
       // ============================================================
       PRINT oPrn NAME "Etiquetas de precios" PREVIEW MODAL
         ConfigPagina(oPrn, MaxFil, MaxCol)
         oPrn:SetPage(9)
          i := 1
          j := 1
          PAGE
          FOR h := 1 TO 3
              nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
              nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
              
              ImprimirEtiquetaOferta(oPrn, oFon1, oFon2, oFon3, oFon4, ;
                                     nRow, nCol, MaxFil, MaxCol, ;
                                     lLogo, lVto, nDecimales, aSay)
              
              oQryEti:Skip()
              j++
              IF j > MaxCol
                 j := 1               
                 i ++               
              ENDIF
              IF i > MaxFil
                 ENDPAGE
                 PAGE
                 i  := 1
                 j  := 1
              ENDIF
          NEXT h  
          ENDPAGE
       ENDPRINT
    ENDIF
    ELSE 
    // ============================================================
    // PREVIEW CON CODIGO DE BARRAS
    // ============================================================
    AddFontResource( "i2of5txt.ttf" )      
    DEFINE FONT oFont5 NAME "Interleaved 2of5 Text"    SIZE oFon1:nWidth,oFon1:nHeight
     PRINT oPrn NAME "Etiquetas de Barras" PREVIEW MODAL
          ConfigPagina(oPrn, MaxFil, MaxCol)
          oPrn:SetPage(9)
          i := 1
          j := 1
          PAGE
          FOR h := 1 TO 3
            nRow := 0.8 + ((i-1) * (nHeightPage/MaxFil))
            nCol := 0.8 + ((j-1) * (nWidthPage/MaxCol))
            
            ImprimirEtiquetaBarras(oPrn, oFon1, oFon2, oFont5, ;
                                   nRow, nCol, MaxFil, MaxCol, ;
                                   lLogo, nDecimales, aSay)
            
            oQryEti:Skip()
            j++
            IF j > MaxCol
               j := 1               
               i ++               
            ENDIF
            IF i > MaxFil
               ENDPAGE
               PAGE
               i  := 1
               j  := 1
            ENDIF
          NEXT h  
        ENDPAGE       
 ENDPRINT
ENDIF
DEACTIVATE FONT oFon1
DEACTIVATE FONT oFon2
DEACTIVATE FONT oFon3
RELEASE FONT oFon1
RELEASE FONT oFon2
RELEASE FONT oFon3
RETURN NIL

STATIC FUNCTION CreateFont()
LOCAL cSql
oApp:oServer:Execute("DROP TABLE ge_"+oApp:cId+"fuentes")
oApp:oServer:Execute("CREATE TABLE `ge_"+oApp:cId+"fuentes` ( "+;
" `id` int(1) NOT NULL AUTO_INCREMENT,"+;
" `CFACE1` varchar(50) DEFAULT NULL,"+;
" `CFACE2` varchar(50) DEFAULT NULL,"+;
" `CFACE3` varchar(50) DEFAULT NULL,"+;
" `NHEIGHT1` double DEFAULT NULL,"+;
" `NHEIGHT2` double DEFAULT NULL,"+;
" `NHEIGHT3` double DEFAULT NULL,"+;
" `NWIDTH1` double DEFAULT NULL,"+;
" `NWIDTH2` double DEFAULT NULL,"+;
" `NWIDTH3` double DEFAULT NULL,"+;
" `COLOR1` double DEFAULT NULL,"+;
" `COLOR2` double DEFAULT NULL,"+;
" `COLOR3` double DEFAULT NULL,"+;
" `LBOLD1` tinyint(1) NOT NULL,"+;
" `LBOLD2` tinyint(1) NOT NULL,"+;
" `LBOLD3` tinyint(1) NOT NULL,"+;
" `NESCAPE1` double DEFAULT NULL,"+;
" `NESCAPE2` double DEFAULT NULL,"+;
" `NESCAPE3` double DEFAULT NULL,"+;
" `NORIENTA1` double DEFAULT NULL,"+;
" `NORIENTA2` double DEFAULT NULL,"+;
" `NORIENTA3` double DEFAULT NULL,"+;
" `NWEIGHT1` double DEFAULT NULL,"+;
" `NWEIGHT2` double DEFAULT NULL,"+;
" `NWEIGHT3` double DEFAULT NULL,"+;
" `LITALIC1` tinyint(1) NOT NULL,"+;
" `LITALIC2` tinyint(1) NOT NULL,"+;
" `LITALIC3` tinyint(1) NOT NULL,"+;
" `LUNDER1` tinyint(1) NOT NULL,"+;
" `LUNDER2` tinyint(4) NOT NULL,"+;
" `LUNDER3` tinyint(1) NOT NULL,"+;
" `LSTRIK1` tinyint(1) NOT NULL,"+;
" `LSTRIK2` tinyint(1) NOT NULL,"+;
" `LSTRIK3` tinyint(1) NOT NULL,"+;
" `NCHARSET1` double DEFAULT NULL,"+;
" `NCHARSET2` double DEFAULT NULL,"+;
" `NCHARSET3` double DEFAULT NULL,"+;
" `NOUTPRE1` double DEFAULT NULL,"+;
" `NOUTPRE2` double DEFAULT NULL,"+;
" `NOUTPRE3` double DEFAULT NULL,"+;
" `NCLIPPR1` double DEFAULT NULL,"+;
" `NCLIPPR2` double DEFAULT NULL,"+;
" `NCLIPPR3` double DEFAULT NULL,"+;
" `NQUALITY1` double DEFAULT NULL,"+;
" `NQUALITY2` double DEFAULT NULL,"+;
" `NQUALITY3` double DEFAULT NULL,"+;
" `NMAXFIL` double DEFAULT NULL,"+;
" `NMAXCOL` double DEFAULT NULL,"+;
"  PRIMARY KEY (`id`)"+;
") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8")

TEXT INTO cSql 
              (`CFACE1`,`CFACE2`,`CFACE3`,`NHEIGHT1`,`NHEIGHT2`,`NHEIGHT3`,`NWIDTH1`,`NWIDTH2`,
              `NWIDTH3`,`COLOR1`,`COLOR2`,`COLOR3`,`LBOLD1`,`LBOLD2`,`LBOLD3`,`NESCAPE1`,`NESCAPE2`,`NESCAPE3`,
              `NORIENTA1`,`NORIENTA2`,`NORIENTA3`,`NWEIGHT1`,`NWEIGHT2`,`NWEIGHT3`,`LITALIC1`,`LITALIC2`,`LITALIC3`,
              `LUNDER1`,`LUNDER2`,`LUNDER3`,`LSTRIK1`,`LSTRIK2`,`LSTRIK3`,`NCHARSET1`,`NCHARSET2`,`NCHARSET3`,`NOUTPRE1`,
              `NOUTPRE2`,`NOUTPRE3`,`NCLIPPR1`,`NCLIPPR2`,`NCLIPPR3`,`NQUALITY1`,`NQUALITY2`,`NQUALITY3`,`NMAXFIL`,`NMAXCOL`)
 values ('Courier New','Courier New','Times New Roman',160,227,100,70,100,44,0,0,0,0,0,0,0,0,0,0,0,0,700,700,700,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,2,2,2,1,1,1,8,2),
        ('Arial','Courier New','Arial',333,360,133,147,158,59,8421504,16711935,0,0,0,0,0,0,0,0,0,0,700,700,700,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,2,2,2,1,1,1,3,1),
        ('Arial','Arial','Arial',29,64,16,13,28,7,255,8421376,65280,0,0,0,0,0,0,0,0,0,700,700,700,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,2,2,2,1,1,1,12,4)
ENDTEXT
cSql := "insert  into `ge_"+oApp:cId+"fuentes` "+cSql
oApp:oServer:Execute(cSql)
RETURN nil

STATIC FUNCTION PorCompra()
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oDlg1, oFont, mnumfac, cFacRemitada,;
      mrta := .f., aCor, base, marchi, mtotal, mdescp := 0, mdeuda := 0, oError,;
      aTipo  := {"Factura","Nota Credito","Nota Debito","Factura x Remito","Remito"}, oQry,;
      aTip1  := {"FC","NC","ND","FR","RE"}, mtipo := 1, mletra := "A", mprefijo := 3,;
      mnumero := 0, oQryDet1, lConsulta := .f., oChe, oQryUlt, oBrw1, oQryDet
oQryUlt := oApp:oServer:Query("SELECT c.tipocomp,c.letra,c.numfac,p.nombre,c.importe,c.fecfac, c.codpro "+;
                              " FROM ge_"+oApp:cId+"compras c "+;
                              " LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro "+;
                              " ORDER BY c.fecfac DESC LIMIT 25")

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5      
DEFINE DIALOG oDlg1 TITLE "Etiquetas por compra" FROM 03,20 TO 20,90 OF oBrw1 FONT oFont
   acor := AcepCanc(oDlg1)
   @ 01, 05 SAY "Seleccione el comprobante" OF oDlg1 PIXEL CENTER SIZE 230,10
   @ 12, 05 XBROWSE oBrw1 DATASOURCE oQryUlt;
              COLUMNS "tipocomp","letra","numfac","fecfac","nombre","importe";
              HEADERS "Tipo","Letra","Numero Comp","Fecha","Proveedor","Importe";
              SIZES 30,30,100,100,140,80;
              AUTOSORT OF oDlg1 ;
     SIZE 250,70 PIXEL 
   PintaBrw(oBrw1,6)   
   oBrw1:CreateFromcode()
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Cargar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN nil
ENDIF

TRY 
   oApp:oServer:Execute("INSERT IGNORE INTO etiqueT (codigo,nombre,precioven,reventa,neto,neto2,cant,horamod,fecmod) "+;
                         "(SELECT c.codart,a.nombre,a.precioven, a.reventa,a.precioven / (1+IF(a.iva=5,.21,.105)), "+;
                         "        a.reventa / (1+IF(a.iva=5,.21,.105)),1,a.horamod,a.fecmod "+;
                         "     FROM ge_"+oApp:cId+"compradet c LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = c.codart "+;
                         "     WHERE c.tipocomp = " + ClipValue2Sql(oQryUlt:tipocomp)+" "+;
                         "     AND c.letra = " + ClipValue2Sql(oQryUlt:letra)+" "+;
                         "     AND c.codpro = " + ClipValue2Sql(oQryUlt:codpro)+" "+;
                         "     AND c.numfac = " + ClipValue2Sql(oQryUlt:numfac)+")")
CATCH oError
   ValidaError(oError)
END TRY  
oQryEti:Refresh()  
oBrw:Refresh()
RETURN nil 