#include "report.ch"
#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

//********************************************************************
// Proposito: Generar los reportes de compras
// .prg     : liscom.prg
// Autor    : Cesar Gomez CM Soft
MEMVAR oApp
**************************************************************
**** Listado de Compras por fecha
PROCEDURE RepCom()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oBot3, oQryCue,oQryPro,;
      cTodos := "----------- Todos/as -----------", mnomcue := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mcuenta := 0, lImputaIva := .f.,nTipo:=1,aTipo:={"Sistema","Demo","Ambos"}, mprov := 0, mnompro := SPACE(30)
oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"plancont") 
oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Compras por fecha" FROM 03,15 TO 15,75 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 70,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 70,10 RIGHT 
   @ 37, 01 SAY "Proveedor (0 Todos):" OF oDlg1 PIXEL SIZE 70,10 RIGHT 
   @ 52, 01 SAY "Cuenta (0 Todas):" OF oDlg1 PIXEL SIZE 70,10 RIGHT 
   @ 05, 75 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 75 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 75 GET oGet[5] VAR mprov  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[5]:value = 0 .or. Buscar(oQryPro,oDlg1,oGet[5],oGet[6]));
                ACTION (oGet[5]:cText:= 0, Buscar(oQryPro,oDlg1,oGet[5],oGet[6])) BITMAP "BUSC1" 
   @ 35,110 GET oGet[6] VAR mnompro PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[6]:cText := IF(mprov=0,cTodos,oQryPro:nombre)) = SPACE(30))
   @ 50, 75 GET oGet[3] VAR mcuenta OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryCue,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryCue,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 50,110 GET oGet[4] VAR mnomcue PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mcuenta=0,cTodos,oQryCue:nombre)) = SPACE(30))

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ 05,140 BUTTON oBot3 PROMPT "&Articulos" OF oDlg1 SIZE 30,10 ;
           ACTION (oDlg1:End(),mrta := .f., RepCom2()) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
IF !mrta   
   RETURN
ENDIF
lImputaIva := IF(nTipo=1,.t.,.f.)
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT CONCAT(c.tipocomp, c.letra, c.numfac) AS compro, c.fecfac as fecha, "+;                          
                          " p.nombre AS provee, p.cuit as cuit, c.neto*IF(c.tipocomp='NC',-1,1) AS neto,"+;
                         " c.iva*IF(c.tipocomp='NC',-1,1) AS iva,"+;
                         " c.nograbado*IF(c.tipocomp='NC',-1,1) AS nograbado,"+;                         
                         " c.importe*IF(c.tipocomp='NC',-1,1) AS importe, "+;
                         " c.saldo*IF(c.tipocomp='NC',-1,1) AS saldo, "+;
                         " cu.nombre as nomcue, cu.tipo AS tipcue,"+;
                         " c.usuario, ca.caja "+;
                          " FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"provee p ON c.codpro = p.codigo "+;
                          " LEFT JOIN ge_"+oApp:cId+"plancont cu ON c.codcue = cu.codigo "+;
                          " LEFT JOIN ge_"+oApp:cId+"punto ca ON c.ip = ca.ip "+;
                          " WHERE c.tipocomp <> 'RE' AND c.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
                          " c.fecfac <= "+ ClipValue2Sql(mhasta) + " AND "+;
                          IF(mcuenta = 0,"TRUE"," c.codcue = " + ClipValue2Sql(mcuenta)) + " AND "+;//                          IF(lImputaIva ," AND c.imputaiva "," AND NOT c.imputaiva  ") +;
                          IF(mprov   = 0,"TRUE"," c.codpro = " + ClipValue2Sql(mprov)) +;
                          " ORDER BY c.fecfac" )
REPORT oRep TITLE "Reporte de compras - Cuenta " + ALLTRIM(mnomcue)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta),;
                  "Proveedor:"+ALLTRIM(mnompro);
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Compras por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Compras por fecha"

COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 14 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Proveedor" DATA oQry:provee    SIZE 25 FONT 1
COLUMN TITLE "Cuenta"    DATA oQry:nomcue    SIZE 15 FONT 1
COLUMN TITLE "Tipo Cuenta"  DATA IF(oQry:tipcue='G','Gasto','Compra')   SIZE 7 FONT 1
COLUMN TITLE "C.U.I.T."  DATA oQry:cuit      SIZE 11 FONT 1
COLUMN TITLE "Neto "     DATA oQry:neto      PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "I.V.A."    DATA oQry:iva       PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Otros"     DATA oQry:nograbado  PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Importe"   DATA oQry:importe     PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Adeuda"    DATA oQry:saldo     PICTURE "9,999,999,999.99" ;
                         SIZE 10 FONT 2 TOTAL 
COLUMN TITLE "Cargó"     DATA oQry:usuario   SIZE 7 FONT 1
COLUMN TITLE "PV"        DATA oQry:caja      SIZE 2 FONT 1

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
oQry:End()
RETURN  




***********************************************************
** Compras por articulo
PROCEDURE RepCom2()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      oQryMar, oQryRub, i, aRub, aMar, oBrwMar, oBrwRub, oQryPro, cSql,;
      cMarca, cRubro, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., mprov := 0, mnompro := SPACE(30),;
      cTodos := "----------- Todos -----------", n
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas  ORDER BY nombre")
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")      
oQryPro:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"provee")      
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
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Compras por articulo" FROM 03,15 TO 27,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Marcas a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Marca","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwMar
      :nEdittYPEs := 1
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
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwRub,0)
   @ 112, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 127, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 112,135 SAY "Proveedor (0 Todos):" OF oDlg1 PIXEL SIZE 70,10 RIGHT 
   @ 110, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 125, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 110,210 GET oGet[3] VAR mprov  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryPro,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= -1, Buscar(oQryPro,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 125,145 GET oGet[4] VAR mnompro PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mprov=0,cTodos,oQryPro:nombre)) = SPACE(30))
   @ 140, 05 CHECKBOX oGet[5] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
oQryRub:End()
oQryMar:End()
IF !mrta
   RETURN
ENDIF
n := 0
cMarca := "("
FOR i := 1 TO LEN(aMar)
    IF aMar[i,1]
       cMarca := cMarca + IF(cMarca=="(","",",") + STR(aMar[i,3])  
       n++
    ENDIF
NEXT i
IF n = 0 
   MsgInfo("Marque al menos una Marca","Atencion")
   LOOP
ENDIF
cMarca := cMarca + ")"
n := 0
cRubro := "("
FOR i := 1 TO LEN(aRub)
    IF aRub[i,1]
       cRubro := cRubro + IF(cRubro=="(","",",") + STR(aRub[i,3])  
       n++
    ENDIF
NEXT i
cRubro := cRubro + ")"
IF n = 0 
   MsgInfo("Marque al menos un Rubro","Atencion")
   LOOP
ENDIF
EXIT
ENDDO
IF !lResu
cSql := "SELECT c.codart AS codart, a.nombre AS detart, m.nombre AS marca, r.nombre AS rubro,"+;
        "c.cantidad *IF(c.tipocomp='NC',-1,1) AS cantidad, c.cantidad*c.punit*IF(c.tipocomp='NC',-1,1) AS precio, co.fecfac AS fecha,"+;
        "CONCAT(c.tipocomp,c.letra,c.numfac) AS numfac FROM ge_"+oApp:cId+"compradet c "
   ELSE
cSql := "SELECT c.codart AS codart, a.nombre AS detart, m.nombre AS marca, r.nombre AS rubro,"+;
        "SUM(c.cantidad*IF(c.tipocomp='NC',-1,1)) AS cantidad,  SUM(c.cantidad*c.punit*IF(c.tipocomp='NC',-1,1)) AS precio, co.fecfac AS fecha,"+;
        "CONCAT(c.tipocomp,c.letra,c.numfac) AS numfac FROM ge_"+oApp:cId+"compradet c "   
ENDIF
cSql := cSql + ;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;
        "LEFT JOIN ge_"+oApp:cId+"rubros r ON a.rubro = r.codigo "+;
        "LEFT JOIN ge_"+oApp:cId+"marcas m ON a.marca = m.codigo "+;
        "LEFT JOIN ge_"+oApp:cId+"compras co ON co.codpro = c.codpro AND co.tipocomp = c.tipocomp AND co.letra = c.letra AND c.numfac = co.numfac "+;
        "WHERE co.fecfac >= " + ClipValue2Sql(mdesde) +;
        "  AND co.fecfac <= " + ClipValue2Sql(mhasta) +;
        if(mprov=0," "," AND c.codpro = " + STR(mprov))
cSql := cSql + " AND a.rubro IN " + cRubro + " AND a.marca IN " + cMarca
IF lResu
   cSql := cSql + " GROUP BY c.codart ORDER BY r.nombre, m.nombre, a.nombre"
   ELSE
   cSql := cSql + " ORDER BY r.nombre, m.nombre, a.nombre"
ENDIF   
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Articulos comprados por fecha del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Articulos comprados por fecha",;
       "Proveedor: "+ALLTRIM(mnompro) CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Articulos comprados por fecha"
GROUP oGru ON oQry:Rubro HEADER oQry:rubro FOOTER "Totales Rubro"  FONT 3       
GROUP oGru ON oQry:Marca HEADER oQry:marca FOOTER "Totales Marca"  FONT 2

IF !lResu
   GROUP oGru ON oQry:detart HEADER oQry:detart FOOTER "Totales Articulo"  FONT 3
ENDIF   
IF !lResu
   COLUMN TITLE "Nro.Fact." DATA oQry:numfac   SIZE 15 FONT 1
   COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 10 FONT 1   
   ELSE
   COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
   COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 06 FONT 1
ENDIF   
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Importe"   DATA oQry:precio ;
                         PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
                ON POSTGROUP oRep:NewLine()
oQry:End()
RETURN 

STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil  

**************************************************************
**** Listado resumen por cuentas contable
PROCEDURE RepCom3()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont, oGru,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCue,;
      cTodos := "Todos las cuentas            ", mnomcue := SPACE(30),;
      mdesde := DATE(), mhasta := DATE(),;
      mcuenta := 0, lImputaIva := .f.,nTipo:=1,aTipo:={"Todas","Solo Imputables","Solo no imputables"}

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Resumen por cuentas" FROM 03,15 TO 11,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 50 COMBOBOX oGet[3] VAR nTipo ITEMS atipo OF oDlg1 PIXEL SIZE 70,24

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC     
oQry := oApp:oServer:Query(;
"SELECT * FROM ( "+;
"SELECT ct.codigo as codigo,SUM(ci.neto*IF(ci.tipocomp='NC',-1,1)) AS neto, "+;
"       SUM(ci.iva*IF(ci.tipocomp='NC',-1,1)) AS iva, 0 AS percep, "+;
"       i.nombre AS nombre, ct.nombre AS cuenta, 0 as total "+;
"       FROM ge_"+oApp:cId+"compivadet ci "+;
"       LEFT JOIN ge_"+oApp:cId+"ivas i ON ci.codiva = i.codigo  "+;
"       LEFT JOIN ge_"+oApp:cId+"compras co ON ci.codpro = co.codpro AND ci.tipocomp = co.tipocomp  "+;
"            AND ci.letra = co.letra AND ci.numfac = co.numfac "+;
"       LEFT JOIN ge_"+oApp:cId+"plancont ct ON co.codcue = ct.codigo         "+;
"       WHERE co.tipocomp <> 'RE' AND co.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
"             co.fecfac <= "+ ClipValue2Sql(mhasta) +;
IF(nTipo=1,"",IF(nTipo=2 ," AND co.imputaiva "," AND NOT co.imputaiva  ")) +;
"       GROUP BY i.nombre,ct.nombre "+;
"UNION  "+;
"SELECT ct.codigo as codigo, 0 AS neto, "+;
"       0 AS iva, SUM(ci.importe*IF(ci.tipocomp='NC',-1,1)) AS percep, "+;
"       i.nombre AS nombre, ct.nombre AS cuenta, 0 as total "+;
"       FROM ge_"+oApp:cId+"compretdet ci "+;
"       LEFT JOIN ge_"+oApp:cId+"retencio i ON ci.codret = i.codigo  "+;
"       LEFT JOIN ge_"+oApp:cId+"compras co ON ci.codpro = co.codpro AND ci.tipocomp = co.tipocomp  "+;
"            AND ci.letra = co.letra AND ci.numfac = co.numfac "+;
"       LEFT JOIN ge_"+oApp:cId+"plancont ct ON co.codcue = ct.codigo         "+;
"       WHERE co.tipocomp <> 'RE' AND co.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
"             co.fecfac <= "+ ClipValue2Sql(mhasta) +;
IF(nTipo=1,"",IF(nTipo=2 ," AND co.imputaiva "," AND NOT co.imputaiva  ")) +;
"       GROUP BY i.nombre,ct.nombre "+;
"UNION  "+;
"SELECT ct.codigo as codigo, 0 AS neto, "+;
"       0 AS iva, 0 as percep, "+;
"       '(Sin detalle)' AS nombre, ct.nombre AS cuenta, SUM(co.importe*IF(co.tipocomp='NC',-1,1)) AS total"+;
"       FROM ge_"+oApp:cId+"compras co "+;
"       LEFT JOIN ge_"+oApp:cId+"compivadet ci ON ci.codpro = co.codpro AND ci.tipocomp = co.tipocomp  "+;
"            AND ci.letra = co.letra AND ci.numfac = co.numfac "+;
"       LEFT JOIN ge_"+oApp:cId+"compivadet ci1 ON ci1.codpro = co.codpro AND ci1.tipocomp = co.tipocomp  "+;
"            AND ci1.letra = co.letra AND ci1.numfac = co.numfac "+;
"       LEFT JOIN ge_"+oApp:cId+"plancont ct ON co.codcue = ct.codigo         "+;
"       WHERE co.tipocomp <> 'RE' AND co.fecfac >= " + ClipValue2Sql(mdesde) + " AND "+;
"             co.fecfac <= "+ ClipValue2Sql(mhasta) + " AND ci.codpro IS NULL AND ci1.codpro IS NULL "+;
IF(nTipo=1,"",IF(nTipo=2 ," AND co.imputaiva "," AND NOT co.imputaiva  ")) +;
"       GROUP BY ct.nombre "+;
"        ) res "+;
"       GROUP BY res.cuenta , res.nombre")                         
                         
REPORT oRep TITLE "Resumen de compras " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;// IF(lImputaIva," (Sistema)"," (Demo)");
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Resumen de compras" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen de compras"
GROUP oGru ON oQry:codigo HEADER oQry:cuenta FOOTER "Total Cuenta"  FONT 3 

COLUMN TITLE "Descripcion" DATA oQry:nombre    SIZE 25 FONT 1
COLUMN TITLE "Neto "       DATA oQry:neto      PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "I.V.A."      DATA oQry:iva       PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Perc/Ret"    DATA oQry:percep    PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Totales"     DATA oQry:neto+oQry:iva+oQry:percep+oQry:total     PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 2 TOTAL 
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
oRep:cGrandTotal := 'Totales Generales'

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()
RETURN 

**************************************************************
**** Libro de I.V.A. compras
PROCEDURE RepCom4()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      mdesde := DATE(), mhasta := DATE(), lImputaIva := .f.

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Libro de I.V.A. Compras" FROM 03,15 TO 12,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ 35, 55 CHECKBOX oGet[4] VAR lImputaIva PROMPT "Libro I.V.A en Excel" SIZE 80,12 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
IF lImputaIva
   libroivaExcel(mdesde,mhasta)
   RETURN 
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-6.5
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
oQry := oApp:oServer:Query(;
"SELECT res.orden, res.fecfac,res.fecvto, CONCAT(res.tipocomp,res.letra,res.numfac) AS compro, "+;
"      p.nombre, p.cuit, LEFT(ti.nombre,3) AS ti, res.importe,res.netoi, "+;
"       res.ivai,res.detalle,res.total,res.fecing  FROM ( "+;
"SELECT 1 AS orden,codpro,tipocomp,letra,numfac,fecfac,fecvto, 0 AS importe, "+;
"       0 AS netoi, 0 AS ivai, '' AS detalle, importe*IF(tipocomp='NC',-1,1) AS total,fecing  FROM ge_"+oApp:cId+"compras  "+;
"WHERE imputaiva AND nomostrar = FALSE "+;
"UNION "+;
"SELECT 2 AS orden,c.codpro,c.tipocomp,c.letra,c.numfac, co.fecfac AS fecfac,co.fecvto AS fecvto, 0 AS importe,  "+;
"       c.neto*IF(c.tipocomp='NC',-1,1) AS netoi, c.iva*IF(c.tipocomp='NC',-1,1) AS ivai, i.nombre AS detalle, 0 AS total,co.fecing as fecing FROM ge_"+oApp:cId+"compivadet c        "+;
"LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = c.codiva "+;
"LEFT JOIN ge_"+oApp:cId+"compras co ON c.codpro = co.codpro AND c.tipocomp = co.tipocomp  "+;
"     AND c.letra = co.letra AND c.numfac = co.numfac "+;
"WHERE co.imputaiva AND co.nomostrar = FALSE "+;
"UNION  "+;
"SELECT 3 AS orden,c.codpro,c.tipocomp,c.letra,c.numfac,co.fecfac AS fecfac,co.fecvto AS fecvto, c.importe *IF(c.tipocomp='NC',-1,1) AS importe,  "+;
"       0 AS netoi, 0 AS ivai, r.nombre AS detalle, 0 AS total,co.fecing as fecing  FROM ge_"+oApp:cId+"compretdet c "+;
"LEFT JOIN ge_"+oApp:cId+"compras co ON c.codpro = co.codpro AND c.tipocomp = co.tipocomp  "+;
"     AND c.letra = co.letra AND c.numfac = co.numfac "+;
"LEFT JOIN ge_"+oApp:cId+"retencio r ON r.codigo = c.codret "+;
"WHERE co.imputaiva ) res "+;
"LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = res.codpro "+;
"LEFT JOIN ge_"+oApp:cId+"tipoiva ti ON p.coniva = ti.codigo   "+;
" WHERE res.fecing >= " + ClipValue2Sql(mdesde) + " AND "+;
"       res.fecing <= "+ ClipValue2Sql(mhasta) +;
"ORDER BY res.fecfac,res.codpro,res.tipocomp,res.letra,res.numfac, res.orden ")                          
REPORT oRep TITLE "SUBDIARIO I.V.A. Compras " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2  ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "SUBDIARIO I.V.A. Compras" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "SUBDIARIO I.V.A. Compras"

COLUMN TITLE "Fecha"       DATA IF(oQry:orden=1,oQry:fecfac," ")    SIZE 08 FONT 1
COLUMN TITLE "Comprobante" DATA IF(oQry:orden=1,oQry:compro," ")    SIZE 16 FONT 1
COLUMN TITLE "Proveedor"   DATA IF(oQry:orden=1,oQry:nombre," ")    SIZE 30 FONT 1
COLUMN TITLE "C.U.I.T."    DATA IF(oQry:orden=1,oQry:cuit," ")      SIZE 12 FONT 1
COLUMN TITLE "SI"          DATA IF(oQry:orden=1,oQry:ti," ")        SIZE  2 FONT 1
COLUMN TITLE "Neto "       DATA IF(oQry:netoi<>0,oQry:netoi," ")    PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 1  RIGHT
COLUMN TITLE "I.V.A."      DATA IF(oQry:ivai<>0,oQry:ivai," ")      PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 1  RIGHT
COLUMN TITLE "Tasa/Concepto"     DATA LEFT(oQry:detalle,14) SIZE 14 FONT 1
COLUMN TITLE "Perc/Rete/No Gr"  DATA IF(oQry:importe<>0,oQry:importe," ")  PICTURE "9,999,999,999.99" ;
                           SIZE 11 FONT 1  RIGHT
COLUMN TITLE "Total"       DATA IF(oQry:total<>0,oQry:total," ")     PICTURE "9,999,999,999.99" ;
                           SIZE 10 FONT 1  RIGHT

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| Saltar(oQry,oRep) }
oRep:cPageTotal := 'Transporte'
oRep:cGrandTotal := 'Totales'

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
         ON POSTEND Resume(oRep,mdesde,mhasta)
oQry:End()
mrta := MsgNoYes("Desea dar por cerrado el libro de "+chr(10)+"IVA compras a ese periodo?"+chr(10)+;
                 "(Si indica que si, no podrá agregar comprobantes "+chr(10)+;
                 "de compras con fecha de imputacion anterior al "+dtoc(mhasta),"Cerrar el LIBRO I.V.A.")
IF mrta
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"parametros SET cierrecompra = "+ClipValue2Sql(mhasta))
ENDIF
RETURN 

STATIC FUNCTION Saltar(oQry,oRep)
LOCAL nOrden := oQry:orden
oRep:aColumns[6]:nTotal += oQry:netoi
oRep:aColumns[7]:nTotal += oQry:ivai
oRep:aColumns[9]:nTotal += oQry:importe
oRep:aColumns[10]:nTotal += oQry:total

IF nOrden = 1
   oQry:Skip()
   IF oQry:orden = 1 
      RETURN nil 
   ENDIF
   oRep:aColumns[6]:nTotal += oQry:netoi
   oRep:aColumns[7]:nTotal += oQry:ivai
   oRep:aColumns[9]:nTotal += oQry:importe
   oRep:aColumns[10]:nTotal += oQry:total
   IF oQry:orden = 2
      oRep:Say(6,STR(oQry:netoi,12,2),1,2,oRep:nRow-oRep:nStdLineHeight)
      oRep:Say(7,STR(oQry:ivai,12,2),1,2,oRep:nRow-oRep:nStdLineHeight)
      oRep:Say(8,LEFT(oQry:detalle,14),1,1,oRep:nRow-oRep:nStdLineHeight)   
      oQry:Skip()   
      ELSE
      IF oQry:orden = 3
         oRep:Say(9,STR(oQry:importe,12,2),1,2,oRep:nRow-oRep:nStdLineHeight)         
         oRep:Say(8,LEFT(oQry:detalle,14),1,1,oRep:nRow-oRep:nStdLineHeight)
         oQry:Skip()
      ENDIF
   ENDIF   
   ELSE
   oQry:Skip()   
ENDIF
RETURN nil

STATIC FUNCTION Resume(oRep,mdesde,mhasta)
LOCAL oQry, nIva := 0, nNeto := 0
oQry := oApp:oServer:Query(;
"SELECT SUM(ci.neto*IF(ci.tipocomp='NC',-1,1)) AS neto, "+;
"       SUM(ci.iva*IF(ci.tipocomp='NC',-1,1)) AS iva, "+;
"       CONCAT('Tasa IVA ',i.nombre) AS nombre "+;
"       FROM ge_"+oApp:cId+"compivadet ci "+;
"       LEFT JOIN ge_"+oApp:cId+"ivas i ON ci.codiva = i.codigo  "+;
"       LEFT JOIN ge_"+oApp:cId+"compras co ON ci.codpro = co.codpro AND ci.tipocomp = co.tipocomp  "+;
"       AND ci.letra = co.letra AND ci.numfac = co.numfac "+;
" WHERE co.fecing >= " + ClipValue2Sql(mdesde) + " AND "+;
"       co.fecing <= "+ ClipValue2Sql(mhasta) + " AND "+;
"       co.imputaiva = 1 "+;
"       GROUP BY i.nombre ")
oRep:TotalLine( RPT_DOUBLELINE )
oRep:Say(1,"TOTALES GENERALES",2)
oRep:Say(6,STR(oRep:aColumns[6]:nTotal,12,2),1,2)
oRep:Say(7,STR(oRep:aColumns[7]:nTotal,12,2),1,2)
oRep:Say(9,STR(oRep:aColumns[9]:nTotal,12,2),1,2)
oRep:Say(10,STR(oRep:aColumns[10]:nTotal,12,2),1,2)
oRep:NewLine()
oRep:StartLine()
IF oRep:NeedNewPage() 
   oRep:EndPage()
   oRep:StarPage()
ENDIF
oRep:Say(3,"TOTAL DE OPERACIONES QUE GENERAN CREDITO FISCAL",2,1)
oRep:NewLine()
DO WHILE !oQry:Eof()
   oRep:Say(3,oQry:nombre)
   oRep:Say(6,STR(oQry:neto,12,2),1,2)
   oRep:Say(7,STR(oQry:iva,12,2),1,2)   
   nNeto := nNeto+ oQry:neto
   nIva := nIva+ oQry:iva
   oRep:NewLine()
   oRep:StartLine()
   IF oRep:NeedNewPage() 
      oRep:EndPage()
      oRep:StarPage()
   ENDIF
   oQry:Skip()
ENDDO
oRep:TotalLine( RPT_DOUBLELINE )
oRep:Say(6,STR(nneto,12,2),1,2)
oRep:Say(7,STR(niva,12,2),1,2)    
oQry:End()
oQry := oApp:oServer:Query(;
"SELECT SUM(cr.importe*IF(cr.tipocomp='NC',-1,1)) AS neto, "+;
"       r.nombre AS nombre "+;
"       FROM ge_"+oApp:cId+"compretdet cr "+;
"       LEFT JOIN ge_"+oApp:cId+"retencio r ON cr.codret = r.codigo  "+;
"       LEFT JOIN ge_"+oApp:cId+"compras co ON cr.codpro = co.codpro AND cr.tipocomp = co.tipocomp  "+;
"       AND cr.letra = co.letra AND cr.numfac = co.numfac "+;
" WHERE co.fecing >= " + ClipValue2Sql(mdesde) + " AND "+;
"       co.fecing <= "+ ClipValue2Sql(mhasta) + " AND "+;
"       co.imputaiva = 1 "+;
"       GROUP BY r.nombre ")
oRep:NewLine()
oRep:StartLine()
IF oRep:NeedNewPage() 
   oRep:EndPage()
   oRep:StarPage()
ENDIF
oRep:Say(3,"REGIMENES ESPECIALES",2,1)
oRep:NewLine()
nNeto := 0
DO WHILE !oQry:Eof()
   oRep:Say(3,oQry:nombre)
   oRep:Say(6,STR(oQry:neto,12,2),1,2)
   nNeto := nNeto+ oQry:neto
   oRep:NewLine()
   oRep:StartLine()
   IF oRep:NeedNewPage() 
      oRep:EndPage()
      oRep:StarPage()
   ENDIF
   oQry:Skip()
ENDDO
oRep:TotalLine( RPT_DOUBLELINE )
oRep:Say(6,STR(nneto,12,2),1,2)   

RETURN nil


***********************************
** Reporte de Retenciones IIBB
PROCEDURE RepCom5()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont, Han, mlinea, nBytes,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE()
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Generar archivo de retenciones II.BB. RETEN.TXT" FROM 03,15 TO 11,55 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
oQry:= oApp:oServer:Query("SELECT p.cuit AS cuit,p.nombre as nombre,op.fecha AS fecha,o.id AS numero,o.importe AS importe "+;
                          "FROM ge_"+oApp:cId+"ordret o "+;
                          "LEFT JOIN ge_"+oApp:cId+"ordpag op ON o.numero = op.numero "+;
                          "LEFT JOIN ge_"+oApp:cId+"provee p  ON p.codigo = op.proveedor "+;
                          " WHERE op.fecha >= " + ClipValue2Sql(mdesde) +;
                          " AND   op.fecha <= " + ClipValue2Sql(mhasta) )

  REPORT oRep TITLE "Retenciones II.BB. entre " + DTOC(mdesde) + " y el " + DTOC(mhasta) ;
         HEADER OemToAnsi(oApp:nomb_emp) , ;
         "Retenciones II.BB. (RETEN.TXT)" CENTER ;
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Retenciones II.BB."

  COLUMN TITLE "C.U.I.T"    DATA oQry:cuit        SIZE 15
  COLUMN TITLE "Proveedor"  DATA oQry:nombre      SIZE 30
  COLUMN TITLE "Fecha"      DATA oQry:fecha       SIZE 08
  COLUMN TITLE "Numero"     DATA oQry:numero      SIZE 10
  COLUMN TITLE "Retencion"  DATA oQry:importe        PICTURE "9,999,999,999.99" SIZE 15 TOTAL


  // Digo que el titulo lo escriba con al letra 2

  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }

  END REPORT
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
Han := LCREAT("EXPORTA\RETEN.TXT")
oQry:GoTop()
DO WHILE !oQry:Eof()
   mlinea := oQry:cuit+;
             DTOC(oQry:fecha)+;
             "0001"+;
             STRTRAN(STR(oQry:numero,8)," ","0") +;
             STRTRAN(STR(oQry:importe,11,2)," ","0")+;
             "A"+CHR(13)+CHR(10)
   nBytes := FWRITE(Han,mlinea,49)
   oQry:Skip()
ENDDO  
LCLOSE(Han)
MsgInfo("Se ha creado el archivo RETEN.TXT")
oQry:End()
RETURN 
***********************************
** Reporte de Retenciones de IVA
PROCEDURE RepCom6()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont, Han, mlinea, nBytes,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE()
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Generar archivo de retenciones I.V.A. RETENIVA.TXT" FROM 03,15 TO 11,55 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
oQry:= oApp:oServer:Query("SELECT p.cuit AS cuit,p.nombre as nombre,op.fecha AS fecha,o.id AS numero,o.importe AS importe "+;
                          "FROM ge_"+oApp:cId+"ordretiva o "+;
                          "LEFT JOIN ge_"+oApp:cId+"ordpag op ON o.numero = op.numero "+;
                          "LEFT JOIN ge_"+oApp:cId+"provee p  ON p.codigo = op.proveedor "+;
                          " WHERE op.fecha >= " + ClipValue2Sql(mdesde) +;
                          " AND   op.fecha <= " + ClipValue2Sql(mhasta) )

  REPORT oRep TITLE "Retenciones I.V.A. entre " + DTOC(mdesde) + " y el " + DTOC(mhasta) ;
         HEADER OemToAnsi(oApp:nomb_emp) , ;
         "Retenciones I.V.A. (RETENIVA.TXT)" CENTER ;
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Retenciones I.V.A."

  COLUMN TITLE "C.U.I.T"    DATA oQry:cuit        SIZE 15
  COLUMN TITLE "Proveedor"  DATA oQry:nombre      SIZE 30
  COLUMN TITLE "Fecha"      DATA oQry:fecha       SIZE 08
  COLUMN TITLE "Numero"     DATA oQry:numero      SIZE 10
  COLUMN TITLE "Retencion"  DATA oQry:importe        PICTURE "9,999,999,999.99" SIZE 15 TOTAL


  // Digo que el titulo lo escriba con al letra 2

  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }

  END REPORT
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
Han := LCREAT("EXPORTA\RETENIVA.TXT")
oQry:GoTop()
DO WHILE !oQry:Eof()
   mlinea := "264"+;
             oQry:cuit+;
             DTOC(oQry:fecha)+;
             "0005"+;
             "0001"+;
             STRTRAN(STR(oQry:numero,8)," ","0") +;
             STRTRAN(STR(oQry:importe,16,2)," ","0")+;
             CHR(13)+CHR(10)
   nBytes := FWRITE(Han,mlinea,60)
   oQry:Skip()
ENDDO  
LCLOSE(Han)
MsgInfo("Se ha creado el archivo RETENIVA.TXT")
oQry:End()
RETURN 

***********************************
** Reporte de Retenciones Ganancias
PROCEDURE RepCom7()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont, Han, mlinea, nBytes,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE()
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Generar archivo de retenciones Ganancias RETENGAN.TXT" FROM 03,15 TO 11,55 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:"  OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Generar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
oQry:= oApp:oServer:Query("SELECT p.cuit AS cuit,p.nombre as nombre, o.fecha AS fecha,"+;
                          "o.id AS numero,o.reten AS importe, o.neto as neto,op.total as total "+;
                          "FROM ge_"+oApp:cId+"ordretgan o "+;
                          "LEFT JOIN ge_"+oApp:cId+"ordpag op ON o.numero = op.numero "+;
                          "LEFT JOIN ge_"+oApp:cId+"provee p  ON p.codigo = op.proveedor "+;
                          " WHERE op.fecha >= " + ClipValue2Sql(mdesde) +;
                          " AND   op.fecha <= " + ClipValue2Sql(mhasta) )

  REPORT oRep TITLE "Retenciones Gan. entre " + DTOC(mdesde) + " y el " + DTOC(mhasta) ;
         HEADER OemToAnsi(oApp:nomb_emp) , ;
         "Retenciones Gan. (RETENGAN.TXT)" CENTER ;
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Retenciones Gan."

  COLUMN TITLE "C.U.I.T"    DATA oQry:cuit        SIZE 15
  COLUMN TITLE "Proveedor"  DATA oQry:nombre      SIZE 30
  COLUMN TITLE "Fecha"      DATA oQry:fecha       SIZE 08
  COLUMN TITLE "Numero"     DATA oQry:numero      SIZE 10
  COLUMN TITLE "Retencion"  DATA oQry:importe     PICTURE "9,999,999,999.99" SIZE 15 TOTAL


  // Digo que el titulo lo escriba con al letra 2

  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }

  END REPORT
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
Han := LCREAT("EXPORTA\RETENGAN.TXT")
oQry:GoTop()
DO WHILE !oQry:Eof()
   mlinea := "06"+;
            DTOC(oQry:fecha)+;
            STRTRAN(STR(oQry:numero,16)," ","0")+;
            STRTRAN(STRTRAN(STR(oQry:total,16,2)," ","0"),".",",")+;
            "217"+;
            "078"+;
            "1"+;
            STRTRAN(STRTRAN(STR(oQry:neto,14,2)," ","0"),".",",")+;
            DTOC(oQry:fecha)+;
            "01"+;
            "0"+;
            STRTRAN(STRTRAN(STR(oQry:importe,14,2)," ","0"),".",",")+;
            "000,00"+;
            SPACE(10)+;
            "80"+;
            STRTRAN(oQry:cuit,"-","")+REPLICATE(" ",9)+;
            STRTRAN(STR(0,14)," ","0")+;
            SPACE(30)+;
            "0"+;
             SPACE(22)+;             
             CHR(13)+CHR(10)
   nBytes := FWRITE(Han,mlinea,199)
   oQry:Skip()
ENDDO  
LCLOSE(Han)
MsgInfo("Se ha creado el archivo RETENGAN.TXT")
oQry:End()
RETURN 


STATIC function libroivaExcel(mdesde,mhasta)
   local cSql, oQry   
   local oDlg,  oBrw, aHead, oBtn
   cSql    :=;
   "(SELECT p.nombre,p.cuit,c.fecfac,ci.codpro,ci.tipocomp,ci.letra,ci.numfac,CONCAT('Neto ',i.nombre) AS concepto, ci.neto*if(ci.tipocomp='NC',-1,1) AS importe, "+;
      "CONCAT(CAST(c.codpro AS CHAR),c.tipocomp,c.letra,c.numfac) AS comprobante "+;
   "FROM ge_"+oApp:cId+"compivadet ci  "+;
   "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = ci.codiva  "+;
   "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = ci.codpro "+;
   "LEFT JOIN ge_"+oApp:cId+"compras c ON ci.codpro=c.codpro AND ci.tipocomp = c.tipocomp AND ci.letra = c.letra AND ci.numfac = c.numfac "+;
   "WHERE c.imputaiva IS TRUE AND c.fecing >= "+ClipValue2Sql(mdesde)+" AND c.fecing <= "+ClipValue2Sql(mhasta)+") "+;
   "UNION ALL "+;
   "(SELECT p.nombre,p.cuit,c.fecfac,ci.codpro,ci.tipocomp,ci.letra,ci.numfac,CONCAT('IVA ',i.nombre) AS concepto, ci.iva*if(ci.tipocomp='NC',-1,1) AS importe, "+;
      "CONCAT(CAST(c.codpro AS CHAR),c.tipocomp,c.letra,c.numfac) AS comprobante "+;
   "FROM ge_"+oApp:cId+"compivadet ci  "+;
   "LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = ci.codiva  "+;
   "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = ci.codpro "+;
   "LEFT JOIN ge_"+oApp:cId+"compras c ON ci.codpro=c.codpro AND ci.tipocomp = c.tipocomp AND ci.letra = c.letra AND ci.numfac = c.numfac "+;
   "WHERE c.imputaiva IS TRUE AND c.fecing >= "+ClipValue2Sql(mdesde)+" AND c.fecing <= "+ClipValue2Sql(mhasta)+") "+;
   "UNION ALL "+;
   "(SELECT p.nombre,p.cuit,c.fecfac,ci.codpro,ci.tipocomp,ci.letra,ci.numfac,i.nombre AS concepto, ci.importe*if(ci.tipocomp='NC',-1,1) AS importe, "+;
      "CONCAT(CAST(c.codpro AS CHAR),c.tipocomp,c.letra,c.numfac) AS comprobante "+;
   "FROM ge_"+oApp:cId+"compretdet ci  "+;
   "LEFT JOIN ge_"+oApp:cId+"retencio i ON i.codigo = ci.codret  "+;
   "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = ci.codpro "+;
   "LEFT JOIN ge_"+oApp:cId+"compras c ON ci.codpro=c.codpro AND ci.tipocomp = c.tipocomp AND ci.letra = c.letra AND ci.numfac = c.numfac "+;
   "WHERE c.imputaiva IS TRUE AND c.fecing >= "+ClipValue2Sql(mdesde)+" AND c.fecing <= "+ClipValue2Sql(mhasta)+") "+;
   "UNION ALL "+;
   "(SELECT p.nombre,p.cuit,c.fecfac,c.codpro,c.tipocomp,c.letra,c.numfac,'Total' AS concepto, c.importe*if(c.tipocomp='NC',-1,1) AS importe, "+;
      "CONCAT(CAST(c.codpro AS CHAR),c.tipocomp,c.letra,c.numfac) AS comprobante "+;
   "FROM ge_"+oApp:cId+"compras c  "+;
   "LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro "+;
   "WHERE c.imputaiva IS TRUE AND c.fecing >= "+ClipValue2Sql(mdesde)+" AND c.fecing <= "+ClipValue2Sql(mhasta)+") "
   
   oQry := ColsVariables( oApp:oServer, ' ('+cSql+') as res', 'res.comprobante', 'res.concepto', 'res.importe', 'SUM', ;
               'res.nombre,res.cuit,res.fecfac,res.codpro,res.tipocomp,res.letra,res.numfac',.t.,'res.fecfac') 

   DEFINE DIALOG oDlg SIZE 980,400 PIXEL TITLE "IVA COMPRAS PARA EXPORTAR A EXCEL"
   oDlg:lHelpIcon := .f.
   @ 40,10 XBROWSE oBrw SIZE -10,-10 PIXEL OF oDlg ;
      DATASOURCE oQry AUTOCOLS ;
      CELL LINES FOOTERS NOBORDER
   PintaBrw(oBrw,0)   
   WITH OBJECT oBrw
      :CreateFromCode()
   END

   @ 08,10 BTNBMP oBtn ;
      PROMPT "Exportar" RESOURCE "EXCE" SIZE 30,30;
      PIXEL OF oDlg FLAT TOP ;
      ACTION oBrw:ToExcel()

   @ 08,50 BTNBMP oBtn ;
      PROMPT "Report" RESOURCE "IMPR" SIZE 30,30;
      PIXEL OF oDlg FLAT TOP ;
      ACTION (oBrw:Report("Libro de IVA Compras para Excel",.f.,.f.),oDlg:End())

   @ 08,90 BTNBMP oBtn ;
      PROMPT "Salir" RESOURCE "SALE" SIZE 30,30;
      PIXEL OF oDlg FLAT TOP ;
      ACTION oDlg:End()      

   ACTIVATE DIALOG oDlg CENTERED
   

return nil