#include "report.ch"
#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

//********************************************************************
// Proposito: Generar los reportes
// .prg     : abmlista.prg
// Autor    : Cesar Gomez CM Soft
MEMVAR oApp
**************************************************************
**** Listado de Articulos

FUNCTION LisArti()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, cOrden, oFont,;
      acor:= ARRAY(4), norden:=1, mrta:=.F., oGet:= ARRAY(7), oBot1, oBot2,;
      cSql, aOrden, oQryMar, oQryRub, oQryArt, aEst, i, nOrden2 := 1, oCom, oBrw, aRub, aMar, oBrwMar, oBrwRub,;
      cMarca, cRubro, oGru, oCol, oError, aTipo := {"Todos los productos","Solo los vendibles","Solo los no vendibles"}, ;
      nTipo := 1, lOrdenPrecio := .f.
CursorWait()      
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos  ORDER BY nombre")
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")
oQryArt := oApp:oServer:Query("SELECT  a.nombre AS Nombre, a.codigo AS Codigo,"+;
                              "a.marca AS Marca, a.rubro AS Rubro, a.depto AS depart, d.nombre AS Depto_Descr, "+;
                              "a.empresa AS empresa, e.nombre AS Empresa_Descr, "+;
                              "m.nombre AS Marca_Descr, r.nombre AS Rubro_Descr, a.iva AS Tasa_Iva, a.preciocos AS Precio_Costo, "+;
                              "a.porcentaje AS Porcentaje,"+;
                              "a.precioven AS Precio_Venta,"+;
                              "a.reventa AS Precio_Venta2,"+;
                              "a.porcentajerev AS Porcentaje2,"+;
                              "a.fecmod AS Fecha_Cambio, a.stockact AS Stock, "+;
                              "a.prov AS Codigo_provee,pr.nombre as Prov_Descr, "+;
                              "a.desc1 AS Desc_1,a.desc2 as Desc_2, "+;
                              "a.desc3 AS Desc_3,a.desc4 as Desc_4, "+;
                              "a.desc5 AS Desc_5,a.impint as ImpInt, "+;
                              "a.flete AS Flete, a.uxbulto As UxB, a.pxbulto as Precio_bulto, "+;
                              " a.stockmin as Stock_Minimo, a.stockide as Stock_Ideal "+;
                              "FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                              "LEFT JOIN ge_"+oApp:cId+"deptos d ON d.codigo = a.depto "+;
                              "LEFT JOIN ge_"+oApp:cId+"empresas e ON e.codigo = a.empresa "+;
                              "LEFT JOIN ge_"+oApp:cId+"provee pr ON pr.codigo = a.prov "+;
                              "LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = a.marca LIMIT 0")
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
FOR i := 1 TO LEN(oQryArt:aStructure)
    AADD(aEst,{.f.,oQryArt:FieldName(i)})
    AADD(aOrden,oQryArt:FieldName(i))
NEXT i
aEst[1,1] := .t.
aEst[2,1] := .t.
aEst[6,1] := .t.
aEst[8,1] := .t.
aEst[12,1] := .t.


DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Articulos" FROM 03,15 TO 35,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Deptos a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Depto","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER FASTEDIT
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
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwRub
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwRub,0)
   @ 110, 10 SAY "Campos a incluir" OF oDlg1 PIXEL
   @ 110,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aEst,oBrw) PIXEL SIZE 20,10 OF oDlg1
   @ 125, 10 XBROWSE oBrw SIZE 105,80 pixel OF oDlg1 ARRAY aEst ;
      HEADERS "Muestra", "Campo";
      COLUMNS 1, 2 ;
      SIZES 40,140;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrw
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrw,0)
   @ 110,130 SAY "Ordenar por" OF oDlg1 PIXEL
   @ 120,130 COMBOBOX oCom VAR nOrden2 ITEMS aOrden OF oDlg1 PIXEL SIZE 70,12  
   @ 135,130 CHECKBOX oGet[7] VAR lOrdenPrecio PROMPT "Y Ordena por precio" OF oDlg1 PIXEL SIZE 80,12
   @ 110,210 SAY "Listar" OF oDlg1 PIXEL
   @ 120,210 COMBOBOX oGet[1] VAR nTipo ITEMS aTipo OF oDlg1 PIXEL SIZE 70,12  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN  NIL
ENDIF
cSql :=  "SELECT  a.nombre AS Nombre, a.codigo AS Codigo,"+;
                              "a.marca AS Marca, a.rubro AS Rubro, a.depto AS depart, d.nombre AS Depto_Descr, "+;
                              "a.empresa AS empresa, e.nombre AS Empresa_Descr, "+;
                              "m.nombre AS Marca_Descr, r.nombre AS Rubro_Descr, a.iva AS Tasa_Iva, a.preciocos AS Precio_Costo, "+;
                              "a.porcentaje AS Porcentaje,"+;
                              "a.precioven AS Precio_Venta,"+;
                              "a.reventa AS Precio_Venta2,"+;
                              "a.porcentajerev AS Porcentaje2,"+;
                              "a.fecmod AS Fecha_Cambio, a.stockact AS Stock, "+;
                              "a.prov AS Codigo_provee,pr.nombre as Prov_Descr, "+;
                              "a.desc1 AS Desc_1,a.desc2 as Desc_2, "+;
                              "a.desc3 AS Desc_3,a.desc4 as Desc_4, "+;
                              "a.desc5 AS Desc_5,a.impint as ImpInt, "+;
                              "a.flete AS Flete, a.uxbulto As UxB, a.pxbulto as Precio_bulto, "+;
                              " a.stockmin as Stock_Minimo, a.stockide as Stock_Ideal "+;
                              "FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                              "LEFT JOIN ge_"+oApp:cId+"empresas e ON e.codigo = a.empresa "+;
                              "LEFT JOIN ge_"+oApp:cId+"deptos d ON d.codigo = a.depto "+;
                              "LEFT JOIN ge_"+oApp:cId+"provee pr ON pr.codigo = a.prov "+;
                              "LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = a.marca "
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
cSql := cSql + " WHERE a.rubro IN " + cRubro + " AND a.depto IN " + cMarca
cSql := cSql + IF(nTipo = 1,"",IF(nTipo = 3," AND nosale IS TRUE "," AND nosale IS FALSE "))
cSql := cSql +   " ORDER BY "+ aorden[nOrden2] + if(lOrdenPrecio,',precioven','')
CursorWait()
TRY
oQry = oApp:oServer:Query(cSql)
CATCH oError
  MsgStop("Error en la consulta,"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY  
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
REPORT oRep TITLE "Listado de Articulos" FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) RIGHT ;
       FOOTER "Hoja:" + STR(oRep:npage,3) + SPACE(40)+"Fecha:"+DTOC(DATE());
       PREVIEW
IF nOrden2 = 3
   GROUP oGru ON oQry:FieldGet(3)  HEADER  oQry:FieldGet(6) ;
         FOOTER "Items:"+STR(oGru:nCounter) FONT 3
ENDIF       
IF nOrden2 = 4   
   GROUP oGru ON oQry:FieldGet(4)  HEADER  oQry:FieldGet(8);
         FOOTER "Items:"+STR(oGru:nCounter) FONT 3
ENDIF       
IF nOrden2 = 18
   GROUP oGru ON oQry:FieldGet(18)  HEADER  oQry:FieldGet(19);
         FOOTER "Items:"+STR(oGru:nCounter) FONT 3
ENDIF       
FOR i := 1 TO LEN(aEst)
    IF aEst[i,1]
       oCol := MakeRepCol( @oRep, i, oQry )
    ENDIF
NEXT i

oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
                ON POSTGROUP oRep:NewLine()
oQry:End()
RETURN NIL

*************************************************************************************************
FUNCTION LisStock()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, cOrden, oFont,;
      acor:= ARRAY(4), norden:=1, mrta:=.F., oGet:= ARRAY(9), oBot1, oBot2,;
      cSql, aOrden, oQryMar, oQryRub, oQryArt, aEst, i, nOrden2 := 1, oCom, oCom1, oCom2, oBrw,;
      aRub, aMar, oBrwMar, oBrwRub, cMarca, cRubro, oGru, oCol, oError, mfecha := DATE(), lAFecha := .f.,;
      aFiltro := {"Todos los productos","Solo mayor a cero","Solo negativos","Solo Faltantes"}, nFiltro := 2,;
      nTipoArt := 1, aTipoArt := {"Todos los tipos","Solo productos","Solo Materia prima"}, lNoVendibles := .t.
CursorWait()      
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos  ORDER BY nombre")
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")
oQryArt := oApp:oServer:Query("SELECT  a.nombre AS Nombre, a.codigo AS Codigo,"+;
                              "d.nombre AS Depto_Descr, r.nombre AS Rubro_Descr, a.preciocos AS Precio_Costo, "+;                              
                              "a.stockact AS Stock, ROUND(a.stockact * a.preciocos,2) AS ValorizaCost, "+;
                              " ROUND(a.stockact * a.precioven,2) AS ValorizaVent, a.stockmin as StockMin , a.stockide as StockIde "+;
                              "FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                              "LEFT JOIN ge_"+oApp:cId+"deptos d ON d.codigo = a.depto LIMIT 0")
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
FOR i := 1 TO LEN(oQryArt:aStructure)
    AADD(aEst,{.t.,oQryArt:FieldName(i)})
    AADD(aOrden,oQryArt:FieldName(i))
NEXT i
aEst[3,1] := .f.
aEst[4,1] := .f.
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Stock" FROM 03,15 TO 35,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Deptos a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Depto","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER FASTEDIT
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
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwRub
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwRub,0)
   @ 110, 10 SAY "Campos a incluir" OF oDlg1 PIXEL
   @ 110,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aEst,oBrw) PIXEL SIZE 20,10 OF oDlg1
   @ 125, 10 XBROWSE oBrw SIZE 105,80 pixel OF oDlg1 ARRAY aEst ;
      HEADERS "Muestra", "Campo";
      COLUMNS 1, 2 ;
      SIZES 40,140;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrw
      :aCols[ 1 ]:nEditType := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrw,0)
   @ 110,130 SAY "Ordenar por" OF oDlg1 PIXEL
   @ 120,130 COMBOBOX oCom VAR nOrden2 ITEMS aOrden OF oDlg1 PIXEL SIZE 70,12   
   @ 120,215 COMBOBOX oCom1 VAR nFiltro ITEMS aFiltro OF oDlg1 PIXEL SIZE 70,12   
   @ 140,130 COMBOBOX oCom2 VAR nTipoArt ITEMS aTipoArt OF oDlg1 PIXEL SIZE 70,12   
   @ 140,215 CHECKBOX oGet[7] VAR lNoVendibles PROMPT "Incluir NO VENDIBLES" OF oDlg1 PIXEL SIZE 80,12   
   @ 155,130 CHECKBOX oGet[8] VAR lAFecha PROMPT "Calcular stock a fecha" OF oDlg1 PIXEL SIZE 80,12
   @ 155,215 GET oGet[9] VAR mfecha OF oDlg1 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN  NIL
ENDIF
IF lAFecha
   LisStockAFecha(mfecha,lNoVendibles,nFiltro, nTipoArt, nOrden2, aOrden)
   RETURN nil 
ENDIF
cSql :=  "SELECT  a.nombre AS Nombre, a.codigo AS Codigo,"+;
                              "d.nombre AS Depto_Descr, r.nombre AS Rubro_Descr, a.preciocos AS Precio_Costo, "+;                              
                              "a.stockact AS Stock, ROUND(a.stockact * a.preciocos,2) AS ValorizaCost, "+;
                              " ROUND(a.stockact * a.precioven,2) AS ValorizaVent , a.stockmin as StockMin, a.stockide as StockIde "+;
                              "FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                              "LEFT JOIN ge_"+oApp:cId+"deptos d ON d.codigo = a.depto "
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
cSql := cSql + " WHERE a.rubro IN " + cRubro + " AND a.depto IN " + cMarca
cSql := cSql + IF(nFiltro=1,"",IF(nFiltro = 2, " AND a.stockact > 0 ",IF(nFiltro = 3, " AND a.stockact < 0 "," AND a.stockact < a.stockmin ")))
cSql := cSql + IF(lNoVendibles," "," AND nosale IS FALSE")
cSql := cSql + IF(nTipoArt = 1," ",IF(nTipoArt=2," AND mprima IS FALSE"," AND mprima IS TRUE"))
cSql := cSql +   " ORDER BY "+ aorden[nOrden2]
CursorWait()
TRY
oQry = oApp:oServer:Query(cSql)
CATCH oError
  MsgStop("Error en la consulta,"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  return nil
END TRY 
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
REPORT oRep TITLE "Listado de Articulos" FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) RIGHT ;
       FOOTER "Hoja:" + STR(oRep:npage,3) + SPACE(40)+"Fecha:"+DTOC(DATE());
       PREVIEW
IF nOrden2 = 3
   GROUP oGru ON oQry:FieldGet(3)  HEADER  oQry:FieldGet(3) ;
         FOOTER "Items:"+STR(oGru:nCounter) FONT 3
ENDIF       
IF nOrden2 = 4   
   GROUP oGru ON oQry:FieldGet(4)  HEADER  oQry:FieldGet(4);
         FOOTER "Items:"+STR(oGru:nCounter) FONT 3
ENDIF       
FOR i := 1 TO LEN(aEst)
    IF aEst[i,1]
       oCol := MakeRepCol( @oRep, i, oQry )
       IF i > 5
          oCol:lTotal := .T.
       ENDIF
    ENDIF    
NEXT i

oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
                ON POSTGROUP oRep:NewLine()
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


static function MakeRepCol( oRep, i , oQry)

   local oCol, bData, cPic, nSize
   local cAlign

   
   bData := { || oQry:FieldGet(i) }
   
   nSize       := IF(oQry:FieldLen(i)>150,100,oQry:FieldLen(i))*IF(oQry:FieldType(i)=="C",.3,1)
   cPic        := IF(oQry:FieldType(i)=="N",;
                       REPLICATE("9",oQry:FieldLen( i ))+"."+REPLICATE("9",MIN(oQry:FieldDec( i ),3)),NIL)
   cPic        := IF(RIGHT(cPic,1)=".",LEFT(cPic,LEN(cPic)-1),cPic)
   if bData != nil

      cAlign   := If( oQry:FieldType(i) == "C", "LEFT", "RIGHT" )
      oCol := RptAddColumn( { { || oQry:FieldName(i) } }, nil ,;
                            { bData }, nSize, { cPic } ,;
                            nil, .f., nil ,;
                            cAlign, .F., .F., nil, ;
                            .f.,.f., ;
                            nil, nil, nil, nil )

   endif

return oCol

STATIC FUNCTION LisStockAFecha(mfecha,lNoVendibles,nFiltro, nTipoArt,nOrden2,aOrden)
LOCAL oRep, oFont1, oFont2, oFont3, oQry, cSql, oError
cSql := "SELECT * FROM ("+;
        "SELECT res.codigo,res.nombre, SUM(res.stockact) AS stockact, SUM(res.entradas) AS entradas, "+;
        " SUM(res.salidas) AS salidas, SUM(res.costo) as costo FROM ( "+;
        "SELECT codigo, nombre, stockact, 0 AS entradas, 0 AS salidas, preciocos as costo FROM ge_"+oApp:cId+"articu "+;
        "UNION ALL "+;
        "SELECT s.codart AS codigo, a.nombre, 0 AS stockact, SUM(s.entradas) AS entradas, "+;
        "SUM(s.salidas) AS salidas, 0 as costo FROM ge_"+oApp:cId+"stoman s "+;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = s.codart "+;
        " WHERE s.fecha > "+ClipValue2Sql(mfecha)+" AND s.codart > 0 GROUP BY s.codart "+;
        "UNION ALL "+;
        "SELECT s.codart AS codigo, a.nombre,0 AS stockact, SUM(s.cantidad*IF(s.tipocomp='NC',-1,1)) AS entradas, "+;
        " 0 AS salidas , 0 as costo FROM ge_"+oApp:cId+"compradet s "+;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = s.codart "+;
        "LEFT JOIN ge_"+oApp:cId+"compras c ON s.codpro = c.codpro "+;
        " AND CONCAT(s.tipocomp,s.letra,s.numfac) = CONCAT(c.tipocomp,c.letra,c.numfac) "+;
        "WHERE c.fecfac > "+ClipValue2Sql(mfecha)+" AND s.codart > 0 GROUP BY s.codart "+;
        "UNION ALL  "+;
        "SELECT s.codart AS codigo, a.nombre,0 AS stockact, 0 AS entradas, "+;
        "SUM(s.cantidad) AS salidas, 0 as costo FROM ge_"+oApp:cId+"emp_consumoint s "+;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = s.codart "+;
        "WHERE s.fecha > "+ClipValue2Sql(mfecha)+" AND s.codart > 0 GROUP BY s.codart "+;
        "UNION ALL  "+;
        "SELECT r.codart AS codigo, r.detart AS nombre,0 AS stockact, 0 AS entradas, "+;
        "SUM(r.cantidad) AS salidas, 0 as costo FROM ge_"+oApp:cId+"remitos r "+;
        "WHERE r.fecha > "+ClipValue2Sql(mfecha)+" AND r.codart > 0 AND NOT r.facturado GROUP BY r.codart "+;
        " UNION ALL "+;
       " SELECT r.codusa as codigo, a.nombre as nombre, 0 AS stockact,"+;
       " 0 as entradas, vd.cantidad * r.cantidad * IF(LEFT(vd.nrofac,2) = 'NC',-1,1) AS salidas, 0 as costo "+;
       " FROM  ge_"+oApp:cId+"reseta r "+; 
       " INNER JOIN  ge_"+oApp:cId+"articu a ON a.codigo = r.codusa "+; 
       " INNER JOIN  ge_"+oApp:cId+"ventas_det vd ON vd.codart = r.codart "+; 
       " WHERE vd.fecha > "+ClipValue2Sql(mfecha)+;
       " AND vd.codart IS NOT NULL "+;
        "UNION ALL  "+;        
        "SELECT s.codart AS codigo, a.nombre,0 AS stockact, 0 AS entradas, "+;
        "SUM(s.cantidad*IF(LEFT(s.nrofac,2)='NC',-1,1)) AS salidas, 0 as costo FROM ge_"+oApp:cId+"ventas_det s "+;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = s.codart "+;
        "WHERE s.fecha > "+ClipValue2Sql(mfecha)+" AND s.codart > 0 GROUP BY s.codart) res "+;
        " GROUP BY res.codigo) res2 LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = res2.codigo  WHERE 1=1  "
cSql := cSql + IF(nFiltro=1,"",IF(nFiltro = 2, " AND (res2.stockact + res2.salidas - res2.entradas)  > 0 ",;
               IF(nFiltro = 3, " AND (res2.stockact + res2.salidas - res2.entradas) < 0 ",;
                " AND (res2.stockact + res2.salidas - res2.entradas) < a.stockmin ")))
cSql := cSql + IF(lNoVendibles," "," AND a.nosale IS FALSE")
cSql := cSql + IF(nTipoArt = 1," ",IF(nTipoArt=2," AND a.mprima IS FALSE"," AND a.mprima IS TRUE"))
cSql := cSql +   " ORDER BY a."+ aorden[nOrden2]
CursorWait()
TRY
  oQry = oApp:oServer:Query(cSql)
CATCH oError
  MsgStop("Error en la consulta,"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  RETURN nil
END TRY 
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
REPORT oRep TITLE "Listado de Stock a Fecha (Calculado) "+DTOC(mfecha) FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) RIGHT ;
       FOOTER "Hoja:" + STR(oRep:npage,3) + SPACE(40)+"Fecha:"+DTOC(DATE());
       PREVIEW

COLUMN TITLE "Codigo"    DATA oQry:codigo    SIZE 14 FONT 1
COLUMN TITLE "Nombre"    DATA oQry:nombre    SIZE 50 FONT 1
COLUMN TITLE "Stock al "+DTOC(mfecha)    DATA oQry:stockact + oQry:salidas - oQry:entradas   ;
              SIZE 15 FONT 2 PICTURE "99999999.999"
COLUMN TITLE "Entradas posteriores"    DATA oQry:entradas   ;
              SIZE 15 FONT 2 PICTURE "99999999.999"
COLUMN TITLE "Salidas posteriores"    DATA oQry:salidas   ;
              SIZE 15 FONT 2 PICTURE "99999999.999"
COLUMN TITLE "Stock Ahora"    DATA oQry:stockact   ;
              SIZE 15 FONT 2 PICTURE "99999999.999"
COLUMN TITLE "Valorizacion"    DATA oQry:costo * oQry:stockact   ;
              SIZE 15 FONT 2 PICTURE "99999999999.99" TOTAL

oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
                
oQry:End()
RETURN NIL