#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"
#include "report.ch"

MEMVAR oApp
*******************************
** Listado de Cambios de precio
STATIC oQryBrw, oWnd1, oBrw, oDlg, cVentana
PROCEDURE LisPre(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw:=oApp:oServer:Query("SELECT codigo, nombre,precioven,fecmod "+;
                            "FROM ge_"+oApp:cId+"articu WHERE fecmod = CURDATE() ORDER BY nombre")
  DEFINE WINDOW oWnd1 MDICHILD TITLE "Cambio de precios de Articulos" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010         
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Reporte"  ;
            ACTION oBrw:Report("Reporte de Cambio de precios",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar cambio de precios"  ;
            ACTION (FILT(),oBrw:Refresh());
            PROMPT "Filtrar" TOP                
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Lista de Precios"  ;
            ACTION ListaPre();
            PROMPT "Listas" TOP WHEN("R"$cPermisos)   
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "Codigo","Nombre","precioven","fecmod";
              HEADERS "Codigo","Nombre articulo","Precio","Cambio";
              SIZES 120,250,90,90;
              ID 111 OF oDlg AUTOSORT 
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,4) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

STATIC FUNCTION FILT()
LOCAL oDlg1, aCor, oGet := ARRAY(2), mvar := ARRAY(2), oBot1, oBot2, mrta := .F., cWhere
AFILL(mvar,DATE())
DEFINE DIALOG oDlg1 TITLE "Cambios entre fechas" FROM 02,01 TO 10,50 OF oWnd1
   acor := AcepCanc( oDlg1 )
   @ 05, 05 SAY "Desde fecha:"   OF oDlg1 PIXEL
   @ 20, 05 SAY "Hasta fecha:"   OF oDlg1 PIXEL
   @ 05, 55 GET oGet[1] VAR mVar[1] OF oDlg1 PIXEL
   @ 20, 55 GET oGet[2] VAR mvar[2] OF oDlg1 PIXEL VALID(mvar[2]>=mvar[1])
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Listar" OF oDlg1 SIZE 30,10 ;
            ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
            ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()
IF !mrta
   RETURN nil
ENDIF
cWhere := " fecmod >= " + ClipValue2Sql(mvar[1]) + " AND fecmod <= " +  ClipValue2Sql(mvar[2])
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQryBrw:End()
RELEASE oQryBrw
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

FUNCTION ListaPre()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, cOrden, oFont,;
      acor:= ARRAY(4), norden:=1, mrta:=.F., oGet:= ARRAY(7), oBot1, oBot2,;
      cSql, aOrden, oQryMar, oQryRub,oQryProv, oQryArt, aEst, i, nOrden2 := 1, oCom, oBrw, aRub, aMar, oBrwMar, oBrwRub,;
      cMarca, cRubro,cProvee, oGru, oCol,aProv,oBrwProv, lCompleta := .f., aOrdenada := .f.,;
      aListas := {.t.,.f.,.f.}, nLispre := 0, oQryLis
CursorWait()      
oQryMar := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas  ORDER BY nombre")
oQryRub := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")
oQryProv:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"provee  ORDER BY nombre")
oQryLis := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"lispre  ORDER BY nombre")
aEst   := {}
aOrden := {}
aMar   := {}
DO WHILE !oQryMar:Eof()
   AADD(aMar,{.t.,oQryMar:Nombre, oQryMar:codigo})
   oQryMar:Skip()
ENDDO
aRub := {}
DO WHILE !oQryRub:Eof()
   AADD(aRub,{.t.,oQryRub:Nombre, oQryRub:codigo})
   oQryRub:Skip()
ENDDO
aProv := {}
DO WHILE !oQryProv:Eof()
   AADD(aProv,{.t.,oQryProv:Nombre, oQryProv:codigo})
   oQryProv:Skip()
ENDDO
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Articulos" FROM 03,15 TO 37,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Marcas a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Marca","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER AUTOSORT
   WITH OBJECT oBrwMar
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwMar,0)
   @ 05, 145 SAY "Rubros a Incluir" OF oDlg1 PIXEL
   @ 05, 230 BUTTON oBot1  PROMPT "Inc" ACTION Cambiar(@aRub,oBrwRub) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 145 XBROWSE oBrwRub SIZE 125,80 pixel OF oDlg1 ARRAY aRub ;
      HEADERS "Incluir", "Rubro","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER AUTOSORT
   WITH OBJECT oBrwRub
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwRub,0)
   @ 110, 05 SAY "Proveedores a Incluir" OF oDlg1 PIXEL
   @ 110,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aProv,oBrwProv) PIXEL SIZE 20,10 OF oDlg1
   @ 125, 05 XBROWSE oBrwProv SIZE 125,80 pixel OF oDlg1 ARRAY aProv ;
      HEADERS "Incluir", "Proveedor","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER AUTOSORT
   WITH OBJECT oBrwProv
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END 
   @ 200, 155 CHECKBOX oGet[7] VAR aOrdenada PROMPT "Separar x Rubro/Marca" OF oDlg1 SIZE  100,12 PIXEL   
   @ 220, 005 CHECKBOX oGet[2] VAR aListas[1] PROMPT "Lista 1" OF oDlg1 SIZE  25,12 PIXEL
   @ 220, 035 CHECKBOX oGet[3] VAR aListas[2] PROMPT "Lista 2" OF oDlg1 SIZE  25,12 PIXEL
   @ 220, 065 CHECKBOX oGet[4] VAR aListas[3] PROMPT "Lista Especial" OF oDlg1 SIZE  60,12 PIXEL
   @ 220, 125 GET oGet[5] VAR nLispre OF oDlg1 SIZE  25,12 PIXEL WHEN(aListas[3]) ;
     VALID(Buscar(oQryLis,oDlg1,oGet[5]));
     ACTION (oGet[5]:cText:= 0,Buscar(oQryLis,oDlg1,oGet[5])) BITMAP "BUSC1"  
   
   PintaBrw(oBrwProv,0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN  NIL
ENDIF

cSql :=  "SELECT  a.nombre AS Nombre, a.codigo AS Codigo,"+;
                              "a.marca AS Marca, "+;
                              "a.rubro AS Rubro,"+;
                              "m.nombre AS Marca_Descr, r.nombre AS Rubro_Descr, "+;                              
                              "a.precioven AS precioven, a.reventa AS reventa,"+;
                              "IF(l.precio IS NOT NULL,l.precio,a.precioven) AS especial "+;                              
                              "FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                              "LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = a.marca "+;
                              "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = a.prov "+;
                              "LEFT JOIN ge_"+oApp:cId+"lispredet l ON a.codigo = l.codart and l.codlis = "+str(nLispre)
cMarca := "("
FOR i := 1 TO LEN(aMar)
    IF aMar[i,1]
       cMarca := cMarca + IF(cMarca=="(","",",") + STR(aMar[i,3])  
    ENDIF
NEXT i
cMarca := cMarca + ")"
cRubro := "("
FOR i := 1 TO LEN(aRub)
    IF aRub[i,1]
       cRubro := cRubro + IF(cRubro=="(","",",") + STR(aRub[i,3])  
    ENDIF
NEXT i
cRubro := cRubro + ")"
cProvee := "("
FOR i := 1 TO LEN(aProv)
    IF aProv[i,1]
       cProvee := cProvee + IF(cProvee=="(","",",") + STR(aProv[i,3])  
    ENDIF
NEXT i
cProvee := cProvee + ")"
IF cMarca = "()" .or. cRubro = "()" .or. cProvee = "()"
   MsgStop("Debe al menos elegir una marca o un rubro","Error")
   RETURN NIL
ENDIF
cSql := cSql + " WHERE nosale is false and a.rubro IN " + cRubro + " AND a.marca IN " + cMarca + " AND a.prov IN " + cProvee 
cSql := cSql + " ORDER BY r.nombre, m.nombre,  a.nombre "
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-12 BOLD      
REPORT oRep TITLE "LISTA DE PRECIOS MAYORISTA" ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER " ", " ", " ", " "," ", " ", " ", " "," ", " ", " " RIGHT ;
       FOOTER "Fecha de Emisión:" + DTOC(DATE()),"Hoja:" + STR(oRep:npage,3) ,"(Los precios incluyen I.V.A.)",;
       "Lista sujeta a variacion sin previo aviso" CENTER;
       PREVIEW CAPTION  "Lista de precios"
IF aOrdenada       
  GROUP ON oQry:rubro HEADER oQry:Rubro_Descr FOOTER " " FONT 3
  GROUP ON oQry:marca HEADER oQry:Marca_Descr FOOTER " " FONT 3
ENDIF

  COLUMN TITLE "Codigo"          DATA oQry:codigo             SIZE 10 FONT 1
  COLUMN TITLE "Descripción del Producto"       DATA oQry:nombre             SIZE 60 FONT 1
  IF aListas[1]
    COLUMN TITLE "Precio Unitario" DATA oQry:precioven SIZE 14 FONT 2 PICTURE "9999999999.99"
  ENDIF  
  IF aListas[2]     
     COLUMN TITLE "Lista 2"        DATA oQry:reventa  SIZE 14 FONT 2 PICTURE "9999999999.99"
  ENDIF   
  IF aListas[3]     
     COLUMN TITLE "Lista Esp."     DATA oQry:especial  SIZE 14 FONT 2 PICTURE "9999999999.99"
  ENDIF     


// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.5,"LOGOPRECIOS.JPG",07.5,4)
oQry:End()
RETURN NIL



**************************************************************************************************
STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil   