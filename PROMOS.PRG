#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** DEFINICION DE PROMOCIONES
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE Promociones(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
validarqueexista()
AADD(oApp:aVentanas,cVentana)
oQry  := oApp:oServer:Query( "SELECT p.*,a.nombre FROM ge_"+oApp:cId+"promociones p "+;
                             "LEFT JOIN ge_"+oApp:cId+"articu a ON p.codart = a.codigo ORDER BY p.nompromo")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Promociones" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Promociones",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "ETIQUE" OF oBar ;
            TOOLTIP "Etiqueta de promociones"  ;
            ACTION Etiquetas();
            PROMPT "Etiquetas" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
            // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "id","nompromo","nombre","tipo","fecha_inicio","fecha_fin";
              HEADERS "#","Promo","Para articulo","Tipo","Desde","Hasta";
              SIZES 50,250,250,40,90,90;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu( .f.),MsgInfo("Sin Permiso")),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     PintaBrw(oBrw,6) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(15), oBot := ARRAY(2),oQryPro, oQryArt, oForm, lRta := .f., aCor, base, oError, oGru,;
      oBrw1,oBrw2,oFont,aTipo:={"Precio Especial","Lleva n paga m","Descuento unidad N","Precio x cantidad"}, cNombre := SPACE(50)
oQryArt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu")
IF lAlta
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"promociones LIMIT 0")
   base := oQryPro:GetBlankRow()   
   base:tipo := 1
   base:fecha_inicio := DATE()
   base:fecha_fin := DATE() + 30
   ELSE
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"promociones WHERE id = " +ClipValue2Sql(oQry:id))
   base := oQryPro:GetRowObj()
   oQryArt:GoTop()
   IF oQryArt:Seek(base:codart,1) > 0
      cNombre := oQryArt:nombre
   ENDIF
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Promociones";
       FROM 05,15 TO 27,130 OF oWnd1
   
   @ 07, 05 SAY "Codigo Articulo:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @ 22, 05 SAY "Nombre Articulo:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @ 37, 05 SAY "Nombre Promo:"          OF oForm PIXEL SIZE 70,12 RIGHT   
   @ 52, 05 SAY "Tipo de promo:"         OF oForm PIXEL SIZE 70,12 RIGHT
   @ 67, 05 SAY "Valido desde:"          OF oForm PIXEL SIZE 70,12 RIGHT
   @ 67,105 SAY "Valido hasta:"          OF oForm PIXEL SIZE 70,12 RIGHT
   @ 82, 05 SAY "Promo Precio Especial"  OF oForm PIXEL SIZE 125,12 CENTER COLOR CLR_BLUE
   @ 82,105 SAY "Promo lleva n paga m"   OF oForm PIXEL SIZE 125,12 CENTER COLOR CLR_BLUE
   @ 82,205 SAY "Promo Desc. n unidad"   OF oForm PIXEL SIZE 125,12 CENTER COLOR CLR_BLUE
   @ 82,305 SAY "Promo por cantidad"     OF oForm PIXEL SIZE 125,12 CENTER COLOR CLR_BLUE

   @ 97, 05 SAY "Precio Especial:"       OF oForm PIXEL SIZE 70,12 RIGHT

   @ 97,105 SAY "Cant.Requerida:"        OF oForm PIXEL SIZE 70,12 RIGHT
   @112,105 SAY "Cant.a Pagar:"          OF oForm PIXEL SIZE 70,12 RIGHT

   @ 97,205 SAY "Aplica Desc. unidad:"   OF oForm PIXEL SIZE 70,12 RIGHT
   @112,205 SAY "% Desc.:"               OF oForm PIXEL SIZE 70,12 RIGHT

   @ 97,305 SAY "Cantidad Minima:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @112,305 SAY "Cantidad Maxima:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @127,305 SAY "Precio unitario:"       OF oForm PIXEL SIZE 70,12 RIGHT
  
   @ 05, 80 GET oGet[1] VAR base:codart PICTURE "99999999999999" RIGHT OF oForm SIZE 60,12 PIXEL;
                VALID(BuscarArt(oQryArt,oForm,oGet[1],oGet[2],'0','nosale'));
                ACTION (oGet[01]:cText:= 0, BuscarArt(oQryArt,oForm,oGet[01],oGet[02],'0','nosale')) BITMAP "BUSC1" WHEN(lAlta)
   @ 20, 80 GET oGet[2] VAR cNombre    PICTURE "@!" OF oForm PIXEL WHEN(.F.)  
   @ 35, 80 GET oGet[3] VAR base:nompromo PICTURE "@!"    OF oForm PIXEL VALID(base:nompromo<>SPACE(30))     
   @ 50, 80 COMBOBOX oGet[4] VAR base:tipo ITEMS aTipo OF oForm PIXEL SIZE 70,12
   @ 67, 80 GET oGet[5] VAR base:fecha_inicio  PICTURE "@D" OF oForm PIXEL
   @ 67,180 GET oGet[6] VAR base:fecha_fin     PICTURE "@D" OF oForm PIXEL
   //Promo precio especial
   @ 95, 80 GET oGet[7] VAR base:precio_especial     PICTURE "999999999.999" RIGHT OF oForm SIZE 50,12 PIXEL WHEN(base:tipo = 1)
   //Promo lleva n paga m
   @ 95,180 GET oGet[8] VAR base:cantidad_requerida  PICTURE "9999" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 2)
   @110,180 GET oGet[9] VAR base:cantidad_a_pagar    PICTURE "9999" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 2)
   //Promo Descuento unidad N
   @ 95,280 GET oGet[10] VAR base:descuento_a_unidad   PICTURE "9999" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 3)
   @110,280 GET oGet[11] VAR base:descuento_porcentual PICTURE "999.99" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 3)
   //Promo por cantidad
   @ 95,380 GET oGet[12] VAR base:cantidad_minima PICTURE "9999" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 4)
   @110,380 GET oGet[13] VAR base:cantidad_maxima PICTURE "9999" RIGHT OF oForm SIZE 40,12 PIXEL WHEN(base:tipo = 4)
   @125,380 GET oGet[14] VAR base:precio_unitario PICTURE "999999999.99" RIGHT OF oForm SIZE 50,12 PIXEL WHEN(base:tipo = 4)
   
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 
IF !lRta
   RETURN nil
ENDIF
IF base:codart = 0 .or. base:nompromo = SPACE(30) 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   oQryPro:GetBlankRow()
ENDIF
oQryPro:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryPro:Save()
  oQry:Refresh()
  oBrw:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
  ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

                              
*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQry:id
IF oQry:id = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"promociones WHERE id = "+str(nNum))
  oApp:oServer:CommitTransaction()
  oQry:Refresh()
CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 

//Etiquetas de promos
STATIC FUNCTION Etiquetas()
LOCAL oPrn, nRow, nCol, i, j, aUnit, oQryEti, lLogo := .f., x1, oFon1, oFon2, oFon3, oQryAux, lVto := .T., oBrw,;
      oQryFue  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"fuentesp"), nDecimales := 2, MaxFil := 2, MaxCol := 1,;
      nCol1 := 0, nCol2 := 0, nCol3:= 0, ;
      oSay1, oSay2, oSay3, oBot1, oBot2, oDlg1, oDlg2, oDlg3, oFld, oBot10,;
      oBot01,oBot02,oBot03,oBot04,oBot05,oBot06, oBot07, oBot08, oBot09, oLbx,;
      oCom, oGet, oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, hHand, aText := {}, aSay := ARRAY(3),;      
      nFila,  ;
      mrta := .f., aCor,  aFont, oChe, oChe1, oChe2, oChe3,;
      aMod := {"Modelo 1","Modelo 2","Modelo 3"}, mmod := 1, oCom1,  oFont, oError, ;
      lSinDecimales := .f., aTabla := {}, nIndi        
oQryEti := oApp:oServer:Query( "SELECT p.*,a.nombre as nombre, a.precioven as precioven FROM ge_"+oApp:cId+"promociones p "+;
                             "LEFT JOIN ge_"+oApp:cId+"articu a ON p.codart = a.codigo WHERE p.fecha_fin >= CURDATE() ORDER BY p.nompromo")      
DO WHILE !oQryEti:Eof()
   AADD(aTabla,{.t.,oQryEti:codart,oQryEti:nombre,oQryEti:precioVen})
   oQryEti:Skip()
ENDDO   
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
DEFINE DIALOG oDlg1 TITLE "Impresion de Etiquetas de precios de Promos" FROM 05,15 TO 35,135 OF oWnd1 ICON oApp:oIco FONT oFont
   oDlg1:lHelpIcon := .f.
   acor := AcepCanc(oDlg1)
      
   @ 07, 05 SAY "Filas por hoja:"      OF oDlg1 PIXEL SIZE 49,10 RIGHT
   @ 07, 70 SAY "Columnas por hoja: "  OF oDlg1 PIXEL SIZE 55,10 RIGHT
   
   @ 05, 55 GET oGet1 VAR MaxFil PICTURE "99" OF oDlg1 PIXEL
   @ 05,125 GET oGet2 VAR MaxCol PICTURE "99" OF oDlg1 PIXEL
   @ 25, 55 CHECKBOX oChe1 VAR lLogo   PROMPT "Con Logo" OF oDlg1 PIXEL SIZE 40,10
   @ 37, 55 CHECKBOX oChe3 VAR lSinDecimales    PROMPT "Precios sin decimales" OF oDlg1 PIXEL SIZE 65,10
   
   @ 50, 05 XBROWSE oBrw ARRAY aTabla;
              COLUMNS 1,2,3,4;
              HEADERS "?","Codigo","Nombre","Precio";
              SIZES nil,90,200,80;
              OF oDlg1 ;
     SIZE 190,120 PIXEL 
   //oBrw:aCols[1]:nEditType := EDIT_GET
   oBrw:aCols[1]:SetCheck(nil,.t.)
   PintaBrw(oBrw,0)
   oBrw:nFreeze := 2
   oBrw:CreateFromcode()     
   @ 05, 235 SAY "Fuente Nombre articulo:" OF oDlg1 PIXEL SIZE 65,10 RIGHT
   @ 65, 235 SAY "Fuente para precio:" OF oDlg1 PIXEL SIZE 65,10 RIGHT
   @125, 235 SAY "Fuente para codigo:" OF oDlg1 PIXEL SIZE 65,10 RIGHT
   @ 05, 330 SAY aSay[1] PROMPT aText[1] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color1
   @ 65, 330 SAY aSay[2] PROMPT aText[2] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color2
   @125, 330 SAY aSay[3] PROMPT aText[3] SIZE 120,20 OF oDlg1 PIXEL BORDER COLOR oQryFue:color3
   @ 05, 320 SAY oSay1 PROMPT IF(oQryEti:nRecCount>0,oQryEti:nombre,"NOMBRE ARTICULO") SIZE 200,55 FONT oFon1;
         OF oDlg1 PIXEL
   @ 20, 280 BUTTON oBot01 PROMPT "Elegir letra" OF oDlg1 SIZE 40,10  PIXEL;
        ACTION (oSay1:SelFont(oQryFue:color1), oSay1:Refresh(),aText[1]:=oSay1:oFont:cFaceName + " de " + STR(oSay1:oFont:nWeight,5),aSay[1]:nClrText := oSay1:nClrText,aSay[1]:Refresh())
   @ 65, 320 SAY oSay2 PROMPT IF(oQryEti:nRecCount>0,"$ "+STR(oQryEti:precioven,2),"$ 9999.99") SIZE 200,55 OF oDlg1 ;
         FONT oFon2 PIXEL
   @ 80, 280 BUTTON oBot02 PROMPT "Elegir letra" OF oDlg1 SIZE 40,10  PIXEL;
        ACTION (oSay2:SelFont(oQryFue:color2), oSay2:Refresh(),aText[2]:=oSay2:oFont:cFaceName + " de " + STR(oSay2:oFont:nWeight,5),aSay[2]:nClrText := oSay2:nClrText,aSay[2]:Refresh())
   @125, 320 SAY oSay3 PROMPT IF(oQryEti:nRecCount>0,"Código: "+STR(oQryEti:codart),"Código: 9999999") SIZE 200,55 FONT oFon3;
         OF oDlg1 PIXEL
   @140, 280 BUTTON oBot03 PROMPT "Elegir letra" OF oDlg1 SIZE 40,10  PIXEL;
        ACTION (oSay3:SelFont(oQryFue:color3), oSay3:Refresh(),aText[3]:=oSay3:oFont:cFaceName + " de " + STR(oSay3:oFont:nWeight,5),aSay[3]:nClrText := oSay3:nClrText, aSay[3]:Refresh())
   @195, 320 COMBOBOX oCom1 VAR mmod ITEMS aMod SIZE 100,100 PIXEL ;
         OF oDlg1 ;
         ON CHANGE  refrefont(oQryFue,mmod,oSay1,oSay2,oSay3,oGet1,oGet2)
   @140 ,200 BUTTON oBot1 PROMPT "&Previsualizar" OF oDlg1 SIZE 40,40 ;
           ACTION Prev(MaxFil,MaxCol, oSay1, oSay2, oSay3, oQryEti, lLogo,  lVto,IF(lSinDecimales,0,2),aTabla) PIXEL WHEN(oQryEti:nRecCount>0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir (F9)" OF oDlg1 SIZE 40,12 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL WHEN(oQryEti:nRecCount>0)
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 40,12 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot1:Click,.f.)}
   oSay1:nClrText := oQryFue:color1
   oSay2:nClrText := oQryFue:color2
   oSay3:nClrText := oQryFue:color3
ACTIVATE DIALOG oDlg1 CENTER ON INIT (oSay1:Hide(), oSay2:Hide(), oSay3:Hide())
IF !mrta
   //cerrar()
   DEACTIVATE FONT oFon1
   DEACTIVATE FONT oFon2
   DEACTIVATE FONT oFon3
   RELEASE FONT oFon1
   RELEASE FONT oFon2
   RELEASE FONT oFon3
   RETURN nil
ENDIF
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
Procesando(.t.)
nDecimales := IF(lSinDecimales,0,2)
oQryFue:nMaxFil := MaxFil
oQryFue:nMaxCol := MaxCol


        PRINT oPrn NAME "Previsualizar" PREVIEW
          oPrn:SetPortrait()
          oPrn:SetPage(9)                   
          PAGE
          i  := 1
          j  := 1
          nIndi := 1
          oQryEti:GoTop()
          DO WHILE !oQryEti:EOF() 
              IF !aTabla[nIndi,1]
                 oQryEti:Skip()
                 nIndi ++ 
                 LOOP
              ENDIF 
              nIndi ++  
              nRow := 0.8 + ((i-1) * ((29.7-2.4)/MaxFil))
              nCol := 0.8 + ((j-1) * ((21.0-1.6)/MaxCol))    
              aUnit := oPrn:Units2Pix(nRow, nCol, nRow+((29.7-2.4)/MaxFil)-0.05, nCol+((21.0-1.6)/MaxCol)-0.05,'CM')
              oPrn:RoundBox(aUnit[2],aUnit[1],aUnit[4],aUnit[3],50,50)                      
              oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed,fecmod FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codart))
              IF lLogo 
                 @ nRow+0.15, nCol+0.15;
                 PRINT TO oPrn IMAGE '.\LOGO.JPG' SIZE 1.2,1.2 CM 
              ENDIF
              @ nRow+0.15, nCol+0.15;
                PRINT TO oPrn TEXT " O F E R T A " ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.2 CM FONT oFon2 ALIGN "TC" LASTROW x1
              @ x1, nCol+0.15;
                PRINT TO oPrn TEXT ALLTRIM(oQryEti:nompromo) ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText
              @ x1, nCol+0.15;
                PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon1 ALIGN "TC" LASTROW x1 COLOR aSay[1]:nClrText              
              DO CASE 
                  CASE oQryEti:tipo = 1            
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precio_especial,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR(oQryEti:precio_especial*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 COLOR aSay[3]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Precio anterior: " + STR(oQryEti:precioven,12,nDecimales) ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" COLOR aSay[3]:nClrText
                  CASE oQryEti:tipo = 2
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven*oQryEti:cantidad_requerida/oQryEti:cantidad_a_pagar,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precioven*oQryEti:cantidad_requerida/oQryEti:cantidad_a_pagar)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 COLOR  aSay[3]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Lleva " + STR(oQryEti:cantidad_requerida,3) + " paga " + STR(oQryEti:cantidad_a_pagar) ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" COLOR aSay[3]:nClrText
                  CASE oQryEti:tipo = 3
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT STR(oQryEti:descuento_a_unidad,3)+"° unidad a $" +;
                                 ALLTRIM(STR(oQryEti:precioven*(oQryEti:descuento_porcentual/100),12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText          
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precioven)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" COLOR aSay[3]:nClrText
                  CASE oQryEti:tipo = 4                
                       @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precio_unitario,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 COLOR aSay[2]:nClrText
                       @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Llevando mas de " + STR(oQryEti:cantidad_minima,3) + " unidades "  ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 COLOR aSay[3]:nClrText
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precio_unitario)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" COLOR aSay[3]:nClrText
              ENDCASE
              oQryEti:Skip()
              j++
              IF j > MaxCol
                 j := 1               
                 i ++               
              ENDIF
              IF i > MaxFil .and. !oQryEti:Eof()
                 ENDPAGE
                 PAGE
                 i  := 1
                 j  := 1
              ENDIF
             ENDDO
          ENDPAGE
          Procesando(.f.)
        ENDPRINT
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
RETURN NIL


*** Refrescar los fonts segun el modelo de etiqueta
STATIC FUNCTION RefreFont(oQryFue,mmod,oSay1,oSay2,oSay3,oGet1,oGet2)
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


STATIC FUNCTION validarqueexista()

IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"promociones ( "+;
  "`id` INT(8) AUTO_INCREMENT,"+;
  "`codart` BIGINT(14) NOT NULL,"+;
  "`nompromo` VARCHAR(40) DEFAULT NULL,"+;
  "`tipo` INT(1) NOT NULL DEFAULT 1,"+;
  "`fecha_inicio` DATE DEFAULT NULL,"+;  
  "`fecha_fin` DATE DEFAULT NULL,"+;    
  "`precio_especial` DECIMAL(12,3) DEFAULT 0,"+;
  "`cantidad_requerida` INT(6) DEFAULT 0,"+;
  "`cantidad_a_pagar` INT(6) DEFAULT 0,"+;
  "`descuento_a_unidad` INT(6) DEFAULT 0,"+;
  "`descuento_porcentual` DECIMAL(5,2) DEFAULT 0,"+;
  "`cantidad_minima` INT(6) DEFAULT 0,"+;    
  "`cantidad_maxima` INT(6) DEFAULT 0,"+;    
  "`precio_unitario` DECIMAL(12,3) DEFAULT 0,"+;      
  "PRIMARY KEY (`id`),"+;
  "FOREIGN KEY (codart) REFERENCES ge_"+oApp:cId+"articu(codigo)"+;
") ENGINE=INNODB DEFAULT CHARSET=utf8")
ENDIF
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"fuentesp")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"fuentesp AS  SELECT * FROM ge_"+oApp:cId+"fuentes")
ENDIF
RETURN nil


********************************
** Previsualizacion
STATIC FUNCTION Prev(MaxFil,MaxCol, oSay1, oSay2, oSay3, oQryEti,  lLogo,  lVto,nDecimales,aTabla)
LOCAL oFon1, oFon2, oFon3, oFon4,  nRow, nCol, oPrn , i, j , x1, x2, x3, x4, x5, y , h, oQryAux, oFont5, ;
      mbarra1, aUnit, nIndi
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
    PRINT oPrn NAME "Previsualizar" PREVIEW MODAL
          oPrn:SetPortrait()
          oPrn:SetPage(9)                   
          PAGE
          i  := 1
          j  := 1
          nIndi := 1
          oQryEti:GoTop()
          DO WHILE !oQryEti:EOF() 
              IF !aTabla[nIndi,1]
                 oQryEti:Skip()
                 nIndi ++ 
                 LOOP
              ENDIF 
              nIndi ++  
              nRow := 0.8 + ((i-1) * ((29.7-2.4)/MaxFil))
              nCol := 0.8 + ((j-1) * ((21.0-1.6)/MaxCol))    
              aUnit := oPrn:Units2Pix(nRow, nCol, nRow+((29.7-2.4)/MaxFil)-0.05, nCol+((21.0-1.6)/MaxCol)-0.05,'CM')
              oPrn:RoundBox(aUnit[2],aUnit[1],aUnit[4],aUnit[3],50,50)                      
              oQryAux := oApp:oServer:Query("SELECT medida,entero,unimed,fecmod FROM ge_"+oApp:cId+"articu WHERE codigo = "+STR(oQryEti:codart))
              IF lLogo 
                 @ nRow+0.15, nCol+0.15;
                 PRINT TO oPrn IMAGE '.\LOGO.JPG' SIZE 1.2,1.2 CM 
              ENDIF
              @ nRow+0.15, nCol+0.15;
                PRINT TO oPrn TEXT " O F E R T A " ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.2 CM FONT oFon2 ALIGN "TC" LASTROW x1
              @ x1, nCol+0.15;
                PRINT TO oPrn TEXT ALLTRIM(oQryEti:nompromo) ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon1 ALIGN "TC" LASTROW x1
              @ x1, nCol+0.15;
                PRINT TO oPrn TEXT ALLTRIM(oQryEti:nombre) ;
                       SIZE ((21.0-1.6)/MaxCol)-0.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon1 ALIGN "TC" LASTROW x1
              DO CASE 
                  CASE oQryEti:tipo = 1            
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precio_especial,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR(oQryEti:precio_especial*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Precio anterior: " + STR(oQryEti:precioven,12,nDecimales) ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" 
                  CASE oQryEti:tipo = 2
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven*oQryEti:cantidad_requerida/oQryEti:cantidad_a_pagar,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precioven*oQryEti:cantidad_requerida/oQryEti:cantidad_a_pagar)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Lleva " + STR(oQryEti:cantidad_requerida,3) + " paga " + STR(oQryEti:cantidad_a_pagar) ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" 
                  CASE oQryEti:tipo = 3
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precioven,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT STR(oQryEti:descuento_a_unidad,3)+"° unidad a $" +;
                                 ALLTRIM(STR(oQryEti:precioven*(oQryEti:descuento_porcentual/100),12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precioven)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" 
                  CASE oQryEti:tipo = 4                
                       @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "$" + ALLTRIM(STR(oQryEti:precio_unitario,12,nDecimales)) ;
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon2 ALIGN "C" LASTROW x1 
                       @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT "Llevando mas de " + STR(oQryEti:cantidad_minima,3) + " unidades "  ;                                
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" LASTROW x1 
                      @ x1, nCol+0.15;
                         PRINT TO oPrn TEXT IF(!EMPTY(oQryAux:entero),"Precio x " + oQryAux:unimed + STR((oQryEti:precio_unitario)*oQryAux:entero/oQryAux:medida,12,nDecimales)+ ;
                                SPACE(10),"")+ "Cod. " +STR(oQryEti:codart)+;
                                IF(lVto," - Valido hasta el "+DTOC(oQryEti:fecha_fin),"");
                                SIZE (21/MaxCol)-.3,((29.7-2.4)/MaxFil)*0.25 CM FONT oFon3 ALIGN "C" 
              ENDCASE
              oQryEti:Skip()
              j++
              IF j > MaxCol
                 j := 1               
                 i ++               
              ENDIF
              IF i > MaxFil .and. !oQryEti:Eof()
                 ENDPAGE
                 PAGE
                 i  := 1
                 j  := 1
              ENDIF
             ENDDO
          ENDPAGE
          Procesando(.f.)
        ENDPRINT
DEACTIVATE FONT oFon1
DEACTIVATE FONT oFon2
DEACTIVATE FONT oFon3
RELEASE FONT oFon1
RELEASE FONT oFon2
RELEASE FONT oFon3
RETURN NIL