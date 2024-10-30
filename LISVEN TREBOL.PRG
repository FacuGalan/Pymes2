#include "report.ch"
#include "FiveWin.ch"
#include "tdolphin.ch"
#include "xbrowse.ch"

//********************************************************************
// Proposito: Generar los reportes de ventas
// .prg     : lisven.prg
// Autor    : Cesar Gomez CM Soft
MEMVAR oApp
**************************************************************
**** Listado de Ventas por fecha
PROCEDURE RepVen()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryVen,;
      cTodos := "Todos los vendedores            ", mnomven := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mvendedor := 0, aTipoForm, oQryTip, nTipo, lCompara := .f.
oQryTip:= oApp:oServer:Query("SELECT prefijo FROM tipocomp")
aTipoForm := oQryTip:FillArray(,{"prefijo"})
AADD(aTipoForm,"Sin TR")
AADD(aTipoForm,"  ")
nTipo := LEN(aTipoForm)
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por fecha" FROM 03,15 TO 15,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Tipo Formulario:"    OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 CHECKBOX oGet[3] VAR lCompara PROMPT "Emitir comparativo compra/venta" OF oDlg1 PIXEL SIZE 50,12
   @ 50, 65 COMBOBOX oGet[5] VAR nTipo ITEMS aTipoForm OF oDlg1 SIZE 40,10 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
IF lCompara
   RepCom3(mdesde,mhasta)
   RETURN 
ENDIF
nTipo := aTipoForm[nTipo]
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha as fecha, "+;
                          " c.nombre AS cliente, v.importe*IF(v.ticomp='NC',-1,1) AS importe "+;
                          " FROM ventas_encab v LEFT JOIN clientes c ON v.codcli = c.codigo "+;
                          " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                          " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                          IF(nTipo = "  "," TRUE ",IF(nTipo="Sin TR"," v.ticomp <> 'TR'"," v.ticomp = " + ClipValue2Sql(nTipo))) + IF(nTipo = "FC"," OR v.ticomp = 'FR'", " ")+;
                          " ORDER BY v.fecha,v.numcomp " )
REPORT oRep TITLE "Ventas vendedor " + ALLTRIM(mnomven)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas por fecha"

COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Cliente"   DATA oQry:cliente   SIZE 30 FONT 1
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 


**************************************************************
**** Listado de Ventas por Cliente
PROCEDURE RepVen1()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := SPACE(30), mdesde := DATE(), mhasta := DATE(), mcodcli := 0
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM clientes ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por cliente" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodcli  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(Buscar(oQryCli,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)                
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT CONCAT(v.tipo, v.letra,v.numero) AS compro, v.fecha as fecha, "+;
                         " v.importe*IF(v.tipo='NC',-1,1) AS importe,"+;
                         " v.saldo*IF(v.tipo='NC' ,-1,1) AS saldo"+;
                         " FROM ventas_cuota v  "+;
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                         " v.cliente = " + ClipValue2Sql(mcodcli) +;
                         " ORDER BY v.fecha" )
REPORT oRep TITLE "Ventas al cliente " + ALLTRIM(mnomcli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas por cliente" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas por cliente"

COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Saldo"     DATA oQry:saldo PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 

***********************************************************
** Ventas por articulo
PROCEDURE RepVen2()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      oQryMar, oQryRub, i, aRub, aMar, oBrwMar, oBrwRub, cSql,;
      cMarca, cRubro, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., mtotal := 0
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM deptos  ORDER BY nombre")
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM rubros  ORDER BY nombre")      
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
DEFINE DIALOG oDlg1 TITLE "Ventas por articulo" FROM 03,15 TO 27,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Deptos a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Deptos","Codigo";
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
   @ 110, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 125, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 140, 05 CHECKBOX oGet[3] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1
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
IF !lResu
cSql := "SELECT v.codart AS codart, v.detart AS detart, d.nombre AS marca, r.nombre AS rubro,"+;
        "v.cantidad * IF(LEFT(v.nrofac,2) = 'NC',-1,1) AS cantidad, v.importe * IF(LEFT(v.nrofac,2) = 'NC',-1,1) AS precio, v.fecha AS fecha,"+;
        "v.nrofac AS numfac, v.pcosto * v.cantidad * IF(LEFT(v.nrofac,2) = 'NC',-1,1) AS costo FROM ventas_det v "
   ELSE
cSql := "SELECT v.codart AS codart, v.detart AS detart, d.nombre AS marca, r.nombre AS rubro,"+;
        "SUM(v.cantidad * IF(LEFT(v.nrofac,2) = 'NC',-1,1)) AS cantidad, SUM(v.importe * IF(LEFT(v.nrofac,2) = 'NC',-1,1)) AS precio, v.fecha AS fecha,"+;
        "v.nrofac AS numfac, SUM(v.pcosto*v.cantidad * IF(LEFT(v.nrofac,2) = 'NC',-1,1)) AS costo FROM ventas_det v "   
ENDIF
cSql := cSql + ;
        "LEFT JOIN articu a ON v.codart = a.codigo "+;
        "LEFT JOIN rubros r ON a.rubro = r.codigo "+;
        "LEFT JOIN deptos d ON a.depto = d.codigo "+;
        "WHERE v.fecha >= " + ClipValue2Sql(mdesde) +;
        "  AND v.fecha <= " + ClipValue2Sql(mhasta) +;
        " AND LEFT(v.nrofac,2) <> 'TR' "
cSql := cSql + " AND a.rubro IN " + cRubro + " AND a.depto IN " + cMarca
IF lResu
   cSql := cSql + " GROUP BY v.codart ORDER BY r.nombre, d.nombre, v.detart"
   ELSE
   cSql := cSql + " ORDER BY r.nombre, d.nombre, v.detart"
ENDIF   
CursorWait()
oQry = oApp:oServer:Query(cSql)
DO WHILE !oQry:Eof()
   mtotal := mtotal + oQry:precio
   oQry:Skip()
ENDDO
oQry:GoTop()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Articulos vendidos por fecha del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Articulos por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Articulos por fecha"
GROUP oGru ON oQry:Rubro HEADER oQry:rubro FOOTER "Totales Rubro"  FONT 3       
GROUP oGru ON oQry:Marca HEADER oQry:marca FOOTER "Totales Depto"  FONT 2

IF !lResu
   GROUP oGru ON oQry:detart HEADER oQry:detart FOOTER "Totales Articulo"  FONT 3
ENDIF   
IF !lResu
   COLUMN TITLE "Nro.Fact." DATA oQry:numfac   SIZE 15 FONT 1
   COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 10 FONT 1   
   ELSE
   COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
   COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 15 FONT 1
ENDIF   
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Importe"   DATA oQry:precio ;
                         PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
COLUMN TITLE "Utilidad"     DATA oQry:precio - oQry:costo ;
                         PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
IF lResu
   COLUMN TITLE "% Part."     DATA oQry:precio * 100 / mtotal;
                         PICTURE "999.99" SIZE 6 FONT 1

ENDIF
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5);
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
**** Articulos vendidos por Cliente
PROCEDURE RepVen3()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := SPACE(30), mdesde := DATE(), mhasta := DATE(), mcodcli := 0, oGru
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM clientes ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Articulos por cliente" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodcli  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(Buscar(oQryCli,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)                
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT v.nrofac AS compro, v.fecha as fecha, "+;                         
                         " v.detart AS articulo,"+;
                         " v.codart AS codigo,"+;
                         " v.cantidad AS cantidad, v.importe AS importe "+;
                         " FROM ventas_det v  "+;                         
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                         " v.codcli = " + ClipValue2Sql(mcodcli) +;
                         " ORDER BY v.codart" )
REPORT oRep TITLE "Articulos vendidos al cliente " + ALLTRIM(mnomcli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Articulos por cliente" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Articulos por cliente"
GROUP oGru ON oQry:codigo HEADER oQry:Articulo FOOTER "Totales"
COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Codigo"    DATA oQry:codigo    PICTURE "99999999999999" SIZE 15 FONT 1
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "9999999" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 

**************************************************************
**** Estadisticas por rubro
PROCEDURE RepVen4()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE(), mtotal := 0
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por Rubro" FROM 03,15 TO 11,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT SUM(v.cantidad) AS cantidad, "+;
                         " SUM(v.importe) AS importe, "+;
                         " IF(v.codart>0,r.nombre,r2.nombre) AS rubro "+;                         
                         " FROM ventas_det v  "+;
                         " LEFT JOIN articu a ON a.codigo = v.codart "+;
                         " LEFT JOIN rubros r ON r.codigo = a.rubro "+;
                         " LEFT JOIN rubros r2 ON r2.codigo = v.codart "+;
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) +;
                         " GROUP BY rubro " +;
                         " ORDER BY rubro" )
DO WHILE !oQry:Eof()
   mtotal := mtotal + oQry:importe
   oQry:Skip()
ENDDO
REPORT oRep TITLE "Ventas por rubros" + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas por Rubros" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas por Rubros"

COLUMN TITLE "Rubro"     DATA oQry:rubro     SIZE 30 FONT 1
COLUMN TITLE "Unidades"  DATA oQry:cantidad  PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Importe"   DATA oQry:importe   PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "% Part."   DATA oQry:importe*100/mtotal PICTURE "9999.99";
                              SIZE 06 FONT 1
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 

*********************************************************
*** Resumen ventas por vendedor
PROCEDURE RepVen7()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryVen,;
      cTodos := "Todos los vendedores            ", mnomven := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mvendedor := 0
oQryVen:= oApp:oServer:Query("SELECT * FROM vendedor")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por fecha" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT v.CLIENTE AS codigo, c.nombre as nombre, "+;
                         " SUM(v.importe*IF(v.tipo='NC' OR v.tipo='DE',-1,1)) AS importe, "+;
                         " SUM(v.saldo*IF(v.tipo='NC' OR v.tipo='DE',-1,1)) AS saldo, "+;
                         " COUNT(v.cliente) AS casos "+;
                         " FROM ventas_cuota v LEFT JOIN clientes c ON v.cliente = c.codigo "+;                         
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                         IF(mvendedor = 0,"TRUE"," c.vendedor = " + ClipValue2Sql(mvendedor)) +;
                         " GROUP BY v.cliente ORDER BY casos DESC " )
REPORT oRep TITLE "Resumen Ventas vendedor " + ALLTRIM(mnomven)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Resumen Ventas por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen Ventas por fecha"

COLUMN TITLE "Codigo"    DATA oQry:codigo    PICTURE "9999999" SIZE 08 FONT 1
COLUMN TITLE "Cliente"   DATA oQry:nombre    SIZE 30 FONT 1
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Adeuda"    DATA oQry:saldo PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Operac."   DATA oQry:casos    PICTURE "99999" SIZE 09 FONT 1
COLUMN TITLE "Pr.X.Op."  DATA oQry:importe/oQry:casos    PICTURE "999999999.99" SIZE 09 FONT 1

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 

***********************************
** Reporte de caja diaria
PROCEDURE RepVen8()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCaj,;
      cTodos := "Todos las cajas            ", mnomcaj := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mcaja := 0, mTotal := 0, i, mEfec := 0
mcaja := oApp:oServer:Query("SELECT caja FROM punto WHERE ip = " +ClipValue2Sql(oApp:cIp)):caja           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Caja Diaria" FROM 03,15 TO 11,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Fecha:"       OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   *@ 22, 01 SAY "Caja Nro:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   
   *@ 20, 65 GET oGet[3] VAR mcaja OF oDlg1 SIZE 30,12 PIXEL RIGHT PICTURE "9999"  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
CursorWait()
/*
oQry := oApp:oServer:Query("SELECT 'Fondo   ' AS concepto, SUM(importe) AS debe, 0 AS haber, SUM(importe) AS efec "+;
                         " FROM fondo "+;
                         " WHERE fecha = " + ClipValue2Sql(mdesde) +" AND  caja =  " +ClipValue2Sql(mcaja)+;
                         " UNION "+;
                         "SELECT 'Retiros ' AS concepto, 0 as debe, SUM(importe) AS haber, SUM(-importe) AS efec "+;
                         " FROM retiros "+;
                         " WHERE fecha = " + ClipValue2Sql(mdesde) +" AND  caja =  " +ClipValue2Sql(mcaja)+;
                         " UNION "+;
                         "SELECT 'Efectivo' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec   "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +" AND  p.caja =  " +ClipValue2Sql(mcaja)+;
                         " AND pc.tipcom = 1 "+;
                         " UNION "+;
                         "SELECT 'Tarjeta ' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +" AND  p.caja =  " +ClipValue2Sql(mcaja)+;
                         " AND pc.tipcom = 2 "+;
                         " UNION "+;
                         "SELECT 'Cheques ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec  "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +" AND  p.caja =  " +ClipValue2Sql(mcaja)+;
                         " AND pc.tipcom = 4 "+;
                         " UNION "+;
                         "SELECT 'Vales   ' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec   "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +" AND  p.caja =  " +ClipValue2Sql(mcaja)+;
                         " AND pc.tipcom = 5 ")*/
oQry := oApp:oServer:Query("SELECT 'Fondo   ' AS concepto, SUM(importe) AS debe, 0 AS haber, SUM(importe) AS efec "+;
                         " FROM fondo "+;
                         " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                         " UNION "+;
                         "SELECT 'Retiros ' AS concepto, 0 as debe, SUM(importe) AS haber, SUM(-importe) AS efec "+;
                         " FROM retiros "+;
                         " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                         " UNION "+;
                         "SELECT 'Efectivo' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec   "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                         " AND pc.tipcom = 1 "+;
                         " UNION "+;
                         "SELECT 'Tarjeta ' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                         " AND pc.tipcom = 2 "+;
                         " UNION "+;
                         "SELECT 'Cheques ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec  "+;
                         " FROM pagos p LEFT JOIN pagcon pc ON p.numero = pc.numero "+;
                         " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                         " AND pc.tipcom = 4 "+;
                         " UNION "+;
                         "SELECT 'Falt/Sobr ' AS concepto, 0 AS debe,0 AS haber, importe AS efec  "+;
                         " FROM balances WHERE fecha = " + ClipValue2Sql(mdesde) )
REPORT oRep TITLE "Resumen de caja diaria del " + DTOC(mdesde) ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Resumen Caja diaria" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen Caja diaria"

COLUMN TITLE "Concepto"   DATA oQry:concepto    SIZE 15
COLUMN TITLE "Ingreso"    DATA oQry:debe        PICTURE "999999999.99" SIZE 10 TOTAL
COLUMN TITLE "Egreso"     DATA oQry:haber       PICTURE "999999999.99" SIZE 10 TOTAL
COLUMN TITLE "Efectivo"   DATA oQry:efec        PICTURE "999999999.99" SIZE 10 TOTAL


// Digo que el titulo lo escriba con al letra 2

oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN 