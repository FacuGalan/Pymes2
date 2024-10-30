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
      mvendedor := 0, aTipoForm, oQryTip, nTipo, lIva := .F.

aTipoForm := {"FC","NC","ND","  "}
nTipo := LEN(aTipoForm)
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por fecha" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Tipo Formulario:"    OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   *@ 37, 65 CHECKBOX oGet[3] VAR lIva PROMPT "Solo Fiscales" OF oDlg1 PIXEL SIZE 60,10 
   @ 35, 65 COMBOBOX oGet[5] VAR nTipo ITEMS aTipoForm OF oDlg1 SIZE 40,10 PIXEL WHEN(!lIva)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF
nTipo := aTipoForm[nTipo]
CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha as fecha, v.hora as hora, "+;
                          " c.nombre AS cliente,c.cuit, v.neto*IF(v.ticomp='NC',-1,1) AS neto,"+;
                          " v.iva*IF(v.ticomp='NC',-1,1) AS iva, v.cae AS cae,"+;
                          "  v.importe*IF(v.ticomp='NC',-1,1) AS importe, v.vendedor AS vendedor, v.usuario as usuario "+;
                          " FROM ge_"+oApp:cId+"ventas_encab v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;
                          " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                          " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                          IF(nTipo = "  "," TRUE "," v.ticomp = " + ClipValue2Sql(nTipo)) + IF(nTipo = "FC"," OR v.ticomp = 'FR'", " ")+;
                          " AND " + IF(lIva,"v.letra <> 'X' "," TRUE ")+;
                          " ORDER BY v.fecha,v.numcomp" )
REPORT oRep TITLE IF(lIva,"Reporte I.V.A. Ventas","Reporte de Ventas " )  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas por fecha" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas por fecha"

COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Hora"      DATA oQry:hora      SIZE 08 FONT 1
COLUMN TITLE "Cliente"   DATA oQry:cliente   SIZE 30 FONT 1
IF lIva
   COLUMN TITLE "C.U.I.T."   DATA oQry:cuit   SIZE 13 FONT 1
   COLUMN TITLE "Neto "      DATA oQry:neto PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
   COLUMN TITLE "I.V.A."     DATA oQry:iva  PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
   COLUMN TITLE "CAE"        DATA oQry:cae  SIZE 20 FONT 1
ENDIF
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Facturó"   DATA oQry:usuario    SIZE 10 FONT 1
COLUMN TITLE "Vendedor"  DATA oQry:vendedor   SIZE 10 FONT 1

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


**************************************************************
**** Listado de Ventas por Cliente
PROCEDURE RepVen1()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := SPACE(30), mdesde := DATE(), mhasta := DATE(), mcodcli := 0, oGru
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"clientes ORDER BY nombre")           
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
oQry := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha as fecha, v.codcli as codcli, "+;
                          " c.nombre AS cliente,c.cuit, v.neto*IF(v.ticomp='NC',-1,1) AS neto,"+;
                          " v.iva*IF(v.ticomp='NC',-1,1) AS iva, v.cae AS cae, vc.saldo*IF(v.ticomp='NC',-1,1) as saldo,"+;
                          "  v.importe*IF(v.ticomp='NC',-1,1) AS importe, v.vendedor AS vendedor, v.usuario as usuario "+;
                          " FROM ge_"+oApp:cId+"ventas_encab v "+;
                          " LEFT JOIN ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;
                          " LEFT JOIN ge_"+oApp:cId+"ventas_cuota vc ON v.ticomp = vc.tipo AND v.letra = vc.letra AND v.numcomp = vc.numero "+;
                          " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                          " v.fecha <= "+ ClipValue2Sql(mhasta) + " "+;                          
                          IF(mcodcli <> 0," AND v.codcli = " + ClipValue2Sql(mcodcli),"")+;
                          " ORDER BY v.codcli,v.fecha,v.numcomp" )
mnomcli := IF(mcodcli=0,"Todos",mnomcli)
REPORT oRep TITLE "Ventas al cliente " + ALLTRIM(mnomcli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas por cliente" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas por cliente"
IF mcodcli = 0
   GROUP oGru ON oQry:codcli HEADER oQry:cliente FOOTER "Totales Cliente"  FONT 2
ENDIF
COLUMN TITLE "Nro.Fact." DATA oQry:compro    SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

COLUMN TITLE "Saldo"     DATA oQry:saldo PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

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
** Ventas por articulo
PROCEDURE RepVen2()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(11), oBot1 := ARRAY(5), oBot2,;
      oQryMar, oQryRub, oQryPro, oQryDep, oQryEmp, i, aRub, aMar, aPro, aDep, aEmp, oBrwMar, oBrwRub, oBrwPro, oBrwDep, oBrwEmp, cSql,;
      cMarca, cRubro, cProvee, cDepto, cEmpresa, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., lProv := .f., nTipo := 3,;
      aTipo := {"Sistema","Demo","Ambos"}, oQryCli, nCliente := 0, cNomCli := "Todos"+SPACE(30), lPorFactura := .f.,;
      aTipo1 := {"Facturas","Presupuestos","Ambos"}, nTipo1 := 3, lRanking := .f., n,;
      cTodos := "TODOS                  ", oQryVen,;
      aOrden := {"Departamento","Rubro","Marca","Proveedor"}, nOrden := 1, ;
      aOrdenTabla := {"deptos","rubros","marcas","provee"},aOrdenCampo := {"depto","rubro","marca","prov"},;      
      mvendedor := 0, aVendedores := {"TODOS                  "}, cVendedor := "TODOS                  " 
oQryCli:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"clientes")     
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas  ORDER BY nombre")
oQryPro:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"provee  ORDER BY nombre")
oQryDep:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos  ORDER BY nombre")  
oQryEmp:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas  ORDER BY nombre")  
IF oApp:usua_es_vendedor 
   oQryVen:= oApp:oServer:Query("SELECT usuario FROM ge_"+oApp:cId+"usuarios")
   oQryVen:GoTop()
   DO WHILE !oQryVen:Eof()
       AADD(aVendedores,oQryVen:usuario)
       oQryVen:Skip()
   ENDDO        
   ELSE
   oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")           
ENDIF     
aMar   := {}
DO WHILE !oQryMar:Eof()
   AADD(aMar,{.t.,oQryMar:Nombre, oQryMar:codigo})
   oQryMar:Skip()
ENDDO
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")     
aRub   := {}
DO WHILE !oQryRub:Eof()
   AADD(aRub,{.t.,oQryRub:Nombre, oQryRub:codigo})
   oQryRub:Skip()
ENDDO
aPro   := {}
DO WHILE !oQryPro:Eof()
   AADD(aPro,{.t.,oQryPro:Nombre, oQryPro:codigo})
   oQryPro:Skip()
ENDDO
aDep   := {}
DO WHILE !oQryDep:Eof()
   AADD(aDep,{.t.,oQryDep:Nombre, oQryDep:codigo})
   oQryDep:Skip()
ENDDO
aEmp   := {}
DO WHILE !oQryEmp:Eof()
   AADD(aEmp,{.t.,oQryEmp:Nombre, oQryEmp:codigo})
   oQryEmp:Skip()
ENDDO
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Ventas por articulo" FROM 03,15 TO 30,153
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Marcas a Incluir" OF oDlg1 PIXEL
   @ 05, 80 BUTTON oBot1[1] PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 100,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Marca","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER WHEN (!lPorFactura)
   WITH OBJECT oBrwMar
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :aCols[ 2 ]:SetOrder()
      :CreateFromCode()
   END  
   PintaBrw(oBrwMar,0)

   @ 05, 110 SAY "Rubros a Incluir" OF oDlg1 PIXEL
   @ 05, 190 BUTTON oBot1[2] PROMPT "Inc" ACTION Cambiar(@aRub,oBrwRub) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 110 XBROWSE oBrwRub SIZE 100,80 pixel OF oDlg1 ARRAY aRub ;
      HEADERS "Incluir", "Rubro","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER  WHEN (!lPorFactura)
   WITH OBJECT oBrwRub
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :aCols[ 2 ]:SetOrder()
      :CreateFromCode()
   END  
   PintaBrw(oBrwRub,0)

   @ 05, 215 SAY "Proveedores a Incluir" OF oDlg1 PIXEL
   @ 05, 295 BUTTON oBot1[3] PROMPT "Inc" ACTION Cambiar(@aPro,oBrwPro) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 215 XBROWSE oBrwPro SIZE 100,80 pixel OF oDlg1 ARRAY aPro ;
      HEADERS "Incluir", "Proveedor","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER  WHEN (!lPorFactura)
   WITH OBJECT oBrwPro
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :aCols[ 2 ]:SetOrder()
      :CreateFromCode()
   END  
   PintaBrw(oBrwPro,0)

   @ 05, 320 SAY "Departamentos a Incluir" OF oDlg1 PIXEL
   @ 05, 400 BUTTON oBot1[4] PROMPT "Inc" ACTION Cambiar(@aDep,oBrwDep) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 320 XBROWSE oBrwDep SIZE 100,80 pixel OF oDlg1 ARRAY aDep ;
      HEADERS "Incluir", "Depto","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER  WHEN (!lPorFactura)
   WITH OBJECT oBrwDep
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :aCols[ 2 ]:SetOrder()
      :CreateFromCode()
   END  
   PintaBrw(oBrwDep,0) 

   @ 05, 425 SAY "Empresas a Incluir" OF oDlg1 PIXEL
   @ 05, 505 BUTTON oBot1[5] PROMPT "Inc" ACTION Cambiar(@aEmp,oBrwEmp) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 425 XBROWSE oBrwEmp SIZE 100,80 pixel OF oDlg1 ARRAY aEmp ;
      HEADERS "Incluir", "Empresa","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER  WHEN (!lPorFactura)
   WITH OBJECT oBrwEmp
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :aCols[ 2 ]:SetOrder()
      :CreateFromCode()
   END  
   PintaBrw(oBrwEmp,0)    
   
   @ 112, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 127, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   IF !oApp:usua_es_vendedor 
      @ 170, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
      ELSE 
      @ 170, 01 SAY "Vendedor :" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   ENDIF
   @ 110, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 125, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 110,170 CHECKBOX oGet[7] VAR lPorFactura PROMPT "Mostrar detalle por factura"  SIZE 110,10 PIXEL OF oDlg1
   @ 140, 05 CHECKBOX oGet[3] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1 WHEN (!lPorFactura)
   @ 155, 05 CHECKBOX oGet[3] VAR lRanking PROMPT "Mostrar Ranking de articulos"  SIZE 110,10 PIXEL OF oDlg1 WHEN (lResu)
   IF !oApp:usua_es_vendedor  
      @ 170, 65 GET oGet[09] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[09]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[09],oGet[10]));
                ACTION (oGet[09]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[09],oGet[10])) BITMAP "BUSC1" WHEN (!lPorFactura)
      @ 170,100 GET oGet[10] VAR cVendedor PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[10]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))
      ELSE
      @ 170, 65 COMBOBOX oGet[9] VAR cVendedor OF oDlg1 ITEMS aVendedores PIXEL SIZE 90,12 WHEN (!lPorFactura)
   ENDIF  
   @ 125,170 CHECKBOX oGet[4] VAR lProv PROMPT "Mostrar por cliente"  SIZE 110,10 PIXEL OF oDlg1 WHEN (!lPorFactura)
   @ 140,170 GET oGet[5] VAR nCliente PICTURE "999999" SIZE 25,12  OF oDlg1 PIXEL ;
             VALID(nCliente = 0 .or. Buscar(oQryCli,oDlg1,oGet[5],oGet[6]));
                ACTION (oGet[5]:cText:= -9, Buscar(oQryCli,oDlg1,oGet[5],oGet[6])) BITMAP "BUSC1" 
   @ 140,200 GET oGet[6] VAR cNomCli PICTURE "@!"  OF oDlg1 PIXEL ;
       WHEN((oGet[6]:cText := IF(nCliente=0,"Todos"+Space(25),oGet[6]:cText)) = "xxx") 
   @ 155,200 COMBOBOX oGet[8] VAR nTipo1 ITEMS aTipo1 OF oDlg1 SIZE 90,30 PIXEL 
   @ 112,300 SAY "Orden:" OF oDlg1 PIXEL SIZE 30,10 RIGHT
   @ 110,332 COMBOBOX oGet[11] VAR nOrden ITEMS aOrden OF oDlg1 SIZE 90,30 PIXEL WHEN(!lRanking .and. !lProv .and. !lPorFactura) 
   @ acor[1],acor[2] BUTTON oBot1[5] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
oQryMar:End()
oQryRub:End()
oQryPro:End()
oQryDep:End()
IF !mrta
   RETURN
ENDIF
cMarca := "("
n := 0
FOR i := 1 TO LEN(aMar)
    IF aMar[i,1]
       cMarca := cMarca + IF(cMarca=="(","",",") + STR(aMar[i,3])  
       n++
    ENDIF
NEXT i
cMarca := cMarca + ")"
IF n = 0 
   MsgInfo("Marque al menos una Marca","Atencion")
   LOOP
ENDIF
cRubro := "("
n := 0
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
cProvee := "("
n := 0
FOR i := 1 TO LEN(aPro)
    IF aPro[i,1]
       cProvee := cProvee + IF(cProvee=="(","",",") + STR(aPro[i,3])  
       n++
    ENDIF
NEXT i
cProvee := cProvee + ")"
IF n = 0 
   MsgInfo("Marque al menos un Proveedor","Atencion")
   LOOP
ENDIF
cDepto := "("
n := 0
FOR i := 1 TO LEN(aDep)
    IF aDep[i,1]
       cDepto := cDepto + IF(cDepto=="(","",",") + STR(aDep[i,3])  
       n++
    ENDIF
NEXT i
cDepto := cDepto + ")"
IF n = 0 
   MsgInfo("Marque al menos un Departamento","Atencion")
   LOOP
ENDIF
cEmpresa := "("
n := 0
FOR i := 1 TO LEN(aEmp)
    IF aEmp[i,1]
       cEmpresa := cEmpresa + IF(cEmpresa=="(","",",") + STR(aEmp[i,3])  
       n++
    ENDIF
NEXT i
cEmpresa := cEmpresa + ")"
IF n = 0 
   MsgInfo("Marque al menos una Empresa","Atencion")
   LOOP
ENDIF
EXIT
ENDDO
IF ((cVendedor <> "TODOS") .and. !lPorFactura) .or. lProv
   oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS ventas_encab_report AS (SELECT * FROM ge_"+oApp:cId+"ventas_encab LIMIT 0)")
   oApp:oServer:Execute("TRUNCATE ventas_encab_report")
   oApp:oServer:Execute("INSERT INTO ventas_encab_report (SELECT * FROM ge_"+oApp:cId+"ventas_encab "+;
                     " WHERE fecha >= " + ClipValue2Sql(mdesde) +;
                     "  AND fecha <= " + ClipValue2Sql(mhasta) + ")" )
ENDIF   
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS ventas_det_report AS (SELECT * FROM ge_"+oApp:cId+"ventas_det LIMIT 0)")

oApp:oServer:Execute("TRUNCATE ventas_det_report")
oApp:oServer:Execute("INSERT INTO ventas_det_report (SELECT * FROM ge_"+oApp:cId+"ventas_det "+;
                     " WHERE fecha >= " + ClipValue2Sql(mdesde) +;
                     "  AND fecha <= " + ClipValue2Sql(mhasta) + ")")

IF !lProv .and. !lPorFactura    
    IF !lResu
    cSql := "SELECT v.codart AS codart, v.detart AS detart, a.codigopro as codigopro, d.nombre AS marca, "+;
            "v.cantidad * IF(LEFT(v.nrofac,2)='NC',-1,1) AS cantidad, v.importe * IF(LEFT(v.nrofac,2)='NC',-1,1) AS precio, v.fecha AS fecha,"+;
            "v.nrofac AS numfac,v.cantidad * v.pcosto * IF(LEFT(v.nrofac,2)='NC',-1,1) AS costo  FROM ventas_det_report v "
       ELSE
    cSql := "SELECT v.codart AS codart, v.detart AS detart, a.codigopro as codigopro, d.nombre AS marca,"+;
            "SUM(v.cantidad* IF(LEFT(v.nrofac,2)='NC',-1,1)) AS cantidad, SUM(v.importe * IF(LEFT(v.nrofac,2)='NC',-1,1)) AS precio, ANY_VALUE(v.fecha) AS fecha, "+;
            "SUM(v.cantidad * v.pcosto * IF(LEFT(v.nrofac,2)='NC',-1,1)) AS costo "+;
            "FROM ventas_det_report v "   
    ENDIF
    cSql := cSql + ;
            "LEFT JOIN ge_"+oApp:cId+"articu a ON v.codart = a.codigo "+;
            "LEFT JOIN ge_"+oApp:cId+aOrdenTabla[nOrden]+" d ON a."+aOrdenCampo[nOrden]+" = d.codigo "
    IF(cVendedor <> "TODOS")
            cSql := cSql + ;        
            "LEFT JOIN ventas_encab_report ve "+;
            " ON ve.ticomp = LEFT(v.nrofac,2) AND ve.letra = SUBSTR(v.nrofac,3,1) AND RIGHT(v.nrofac,13) = ve.numcomp "
    ENDIF        
    cSql := cSql + ;        
            "WHERE v.fecha >= " + ClipValue2Sql(mdesde) +;
            "  AND v.fecha <= " + ClipValue2Sql(mhasta)  
    IF(cVendedor <> "TODOS")      
       cSql := cSql +" AND "+ IF(cVendedor = "TODOS","TRUE"," ve.vendedor = " + ClipValue2Sql(cVendedor)) 
    ENDIF        

    cSql := cSql + " AND a.marca IN " + cMarca + " AND a.rubro IN " + cRubro + ;
            " AND a.prov IN " + cProvee + " AND a.depto IN "+cDepto + " AND a.empresa IN "+cEmpresa
    cSql := cSql + " AND "+IF(nTipo1 = 3," TRUE ",IF(nTipo1 = 1," SUBSTR(v.nrofac,3,1) <> 'X' "," SUBSTR(v.nrofac,3,1) = 'X' "))
    IF lResu
       IF lRanking
          cSql := cSql + "GROUP BY v.codart"
          cSql := " SELECT res.* FROM ("+cSql+") res ORDER BY res.cantidad DESC"
          ELSE 
          cSql := cSql + " GROUP BY v.codart,v.detart,d.nombre ORDER BY d.nombre, v.detart"
       ENDIF   
       ELSE
       cSql := cSql + " ORDER BY d.nombre, v.detart"
    ENDIF   
    CursorWait()
    Procesando(.t.)
    oQry = oApp:oServer:Query(cSql)
    Procesando(.f.)
         DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
         DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
         DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
    REPORT oRep TITLE "Articulos vendidos por fecha del " + ;
                      DTOC(mdesde) + " al " + DTOC(mhasta), IF(lRanking,"Ranking","")+" Vendedor:"+ALLTRIM(cVendedor) ;
           FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Articulos por fecha" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Articulos por fecha"    
    IF !lRanking       
       GROUP oGru ON oQry:Marca HEADER oQry:marca FOOTER "Totales Grupo"  FONT 2
    ENDIF   

    IF !lResu
       GROUP oGru ON oQry:detart ;
       HEADER ALLTRIM(oQry:detart)+" "+IF(EMPTY(oQry:codigopro),"","- Cod Prov.:"+oQry:codigopro);
       FOOTER "Totales Articulo"  FONT 3
    ENDIF   
    IF !lResu
       COLUMN TITLE "Nro.Fact." DATA oQry:numfac   SIZE 15 FONT 1
       COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 10 FONT 1   
       ELSE
       COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
       COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 12 FONT 1
       COLUMN TITLE "Codigo Pro" DATA oQry:codigopro   SIZE 12 FONT 1
    ENDIF   
    COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999.99" ;
                                SIZE 10 FONT 2 TOTAL
    COLUMN TITLE "Importe"   DATA oQry:precio ;
                             PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
    COLUMN TITLE "Costo"     DATA oQry:costo ;
                             PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
    COLUMN TITLE "Utilidad"   DATA oQry:precio - oQry:costo ;
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
ELSE
    IF !lPorFactura
      cSql := "SELECT v.codart AS codart, v.detart AS detart, a.codigopro as codigopro, d.nombre AS prov,"+;
              "SUM(v.cantidad* IF(LEFT(v.nrofac,2)='NC',-1,1)) AS cantidad, SUM(v.importe* IF(LEFT(v.nrofac,2)='NC',-1,1)) AS precio, v.fecha AS fecha, "+;
              "SUM(v.cantidad*v.pcosto* IF(LEFT(v.nrofac,2)='NC',-1,1)) AS costo "+;
              " FROM ventas_det_report v "
      cSql := cSql + ;
              "LEFT JOIN ge_"+oApp:cId+"articu a ON v.codart = a.codigo "+;        
              "LEFT JOIN ge_"+oApp:cId+"clientes d ON v.codcli = d.codigo "+;
              "LEFT JOIN ventas_encab_report ve "+;
              " ON ve.ticomp = LEFT(v.nrofac,2) AND ve.letra = SUBSTR(v.nrofac,3,1) AND RIGHT(v.nrofac,13) = ve.numcomp "+;
              "WHERE v.fecha >= " + ClipValue2Sql(mdesde) +;
              "  AND v.fecha <= " + ClipValue2Sql(mhasta) +;   
              " AND a.marca IN " + cMarca + " AND a.rubro IN " + cRubro + " "+;
              " AND a.prov IN " + cProvee + " AND a.depto IN "+cDepto +" "+ " AND a.empresa IN "+cEmpresa+;
              IF(nCliente = 0,""," AND v.codcli = " + ClipValue2Sql(nCliente))+;
              " AND "+ IF(nTipo1 = 3," TRUE ",IF(nTipo1 = 1," SUBSTR(v.nrofac,3,1) <> 'X' "," SUBSTR(v.nrofac,3,1) = 'X' ")) 
      IF(cVendedor <> "TODOS")      
        cSql := cSql + " AND "+ IF(cVendedor = "TODOS","TRUE"," ve.vendedor = " + ClipValue2Sql(cVendedor)) 
      ENDIF               
      cSql := cSql + " GROUP BY v.codcli,v.codart ORDER BY d.nombre, v.detart"
      CursorWait()
      Procesando(.t.)
      oQry = oApp:oServer:Query(cSql)
      Procesando(.f.)
           DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
           DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
           DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
      REPORT oRep TITLE "Articulos vendidos por fecha del "+ ;
                        DTOC(mdesde) + " al " + DTOC(mhasta) , "Vendedor:"+ALLTRIM(cVendedor)  ;
             FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Articulos por fecha" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Articulos por fecha"
      GROUP oGru ON oQry:prov HEADER oQry:prov FOOTER "Totales Clientes"  FONT 3       

      COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
      COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 12 FONT 1
      COLUMN TITLE "Codigo Pro" DATA oQry:codigopro   SIZE 12 FONT 1
      COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999.99" ;
                                  SIZE 10 FONT 2 TOTAL
      COLUMN TITLE "Importe"   DATA oQry:precio ;
                               PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Utilidad"   DATA oQry:precio - oQry:costo ;
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
    ELSE
    //Por Factura
    cSql := "SELECT v.codart AS codart, v.detart AS detart, a.codigopro as codigopro, c.nombre as nomcli, v.nrofac as nrofac,"+;
              "v.cantidad* IF(LEFT(v.nrofac,2)='NC',-1,1) AS cantidad, "+;
              "v.importe* IF(LEFT(v.nrofac,2)='NC',-1,1) AS precio,"+;
              "v.neto* IF(LEFT(v.nrofac,2)='NC',-1,1) AS neto,"+;
              "v.iva* IF(LEFT(v.nrofac,2)='NC',-1,1) AS iva,"+;
              "v.impint* IF(LEFT(v.nrofac,2)='NC',-1,1) AS impint,"+;
              "v.fecha AS fecha, "+;
              "v.descu  AS descu, "+;
              "v.descup AS descup, "+;
              "v.cantidad*v.pcosto* IF(LEFT(v.nrofac,2)='NC',-1,1) AS costo "+;
              " FROM ventas_det_report v "
    cSql := cSql + ;              
              "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+; 
              "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+; 
              "WHERE v.fecha >= " + ClipValue2Sql(mdesde) +;
              "  AND v.fecha <= " + ClipValue2Sql(mhasta)+;
              " AND a.marca IN " + cMarca + " AND a.rubro IN " + cRubro+;
              " AND a.prov IN " + cProvee + " AND a.depto IN "+cDepto+ " AND a.empresa IN "+cEmpresa+;
              " AND "+IF(nTipo1 = 3," TRUE ",IF(nTipo1 = 1," SUBSTR(v.nrofac,3,1) <> 'X' "," SUBSTR(v.nrofac,3,1) = 'X' "))+;              
              IF(nCliente = 0,""," AND v.codcli = " + ClipValue2Sql(nCliente))+;
              " ORDER BY v.fecha,v.nrofac"
    CursorWait()
    Procesando(.t.)
    oQry = oApp:oServer:Query(cSql)
    Procesando(.f.)
           DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
           DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
           DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
    REPORT oRep TITLE "Articulos vendidos por fecha del " + ;
                        DTOC(mdesde) + " al " + DTOC(mhasta) ;
             FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Detalle de Factura" CENTER ;
             FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
             PREVIEW CAPTION  "Articulos por fecha"
      GROUP oGru ON oQry:nrofac HEADER oQry:nrofac+" "+oQry:nomcli FOOTER "Totales Factura"  FONT 3       

      COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
      COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 12 FONT 1
      COLUMN TITLE "Codigo Pro" DATA oQry:codigopro   SIZE 12 FONT 1
      COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999.99" ;
                                  SIZE 6 FONT 1 TOTAL
      COLUMN TITLE "Total"     DATA oQry:precio PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Neto"      DATA oQry:neto   PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "IVA"       DATA oQry:iva    PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Imp.Int"   DATA oQry:impint PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Desc.%"    DATA oQry:descup PICTURE "999.99" SIZE 6 FONT 1
      COLUMN TITLE "Desc.$"    DATA oQry:descu  PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Utilidad"  DATA oQry:precio - oQry:costo PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
      COLUMN TITLE "Costo Unit" DATA oQry:costo / oQry:cantidad PICTURE "9999999999.99" SIZE 10 FONT 1
      // Digo que el titulo lo escriba con al letra 2
      oRep:oTitle:aFont[1] := {|| 3 }
      oRep:bInit := {|| oQry:GoTop() }
      oRep:bSkip := {|| oQry:Skip() }
      END REPORT
      // Activo el reporte
      ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                      ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",.3,.3);
                      ON POSTGROUP oRep:NewLine()
      oQry:End()
    ENDIF
ENDIF
RETURN 

STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil  

**************************************************************
**** Estadisticas por rubro
PROCEDURE RepVen4()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE(), mtotal := 0, aTipo := {"Por Rubro","Por Depto"}, nTipo := 1
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por Rubro/Depto" FROM 03,15 TO 12,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ 35, 40 COMBOBOX oGet[3] VAR nTipo ITEMS aTipo OF oDlg1 PIXEL SIZE 80,12 
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
IF nTipo = 1     
   oQry := oApp:oServer:Query("SELECT SUM(IF(LEFT(v.nrofac,2)='NC',-v.cantidad,v.cantidad)) AS cantidad,  "+;
                         " SUM(IF(LEFT(v.nrofac,2)='NC',-v.importe,v.importe)) AS importe, "+;
                         " SUM(IF(LEFT(v.nrofac,2)='NC',-v.pcosto,v.pcosto)) AS costo, "+;
                         " r.nombre AS rubro "+;                         
                         " FROM ge_"+oApp:cId+"ventas_det v  "+;
                         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                         " LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) +;
                         " GROUP BY r.nombre " +;
                         " ORDER BY r.nombre" )
   ELSE 
   oQry := oApp:oServer:Query("SELECT SUM(IF(LEFT(v.nrofac,2)='NC',-v.cantidad,v.cantidad)) AS cantidad,  "+;
                         " SUM(IF(LEFT(v.nrofac,2)='NC',-v.importe,v.importe)) AS importe, "+;
                         " SUM(IF(LEFT(v.nrofac,2)='NC',-v.pcosto,v.pcosto)) AS costo, "+;
                         " r.nombre AS rubro "+;                         
                         " FROM ge_"+oApp:cId+"ventas_det v  "+;
                         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;
                         " LEFT JOIN ge_"+oApp:cId+"deptos r ON IF(v.codart > 0,r.codigo = a.depto, ABS(v.codart) = r.codigo) "+;
                         " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) +;
                         " GROUP BY r.nombre " +;
                         " ORDER BY r.nombre" )
ENDIF   
DO WHILE !oQry:Eof()
   mtotal := mtotal + oQry:importe
   oQry:Skip()
ENDDO
REPORT oRep TITLE "Ventas "+aTipo[nTipo] + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Ventas " +aTipo[nTipo] CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Ventas "+aTipo[nTipo]

COLUMN TITLE IF(nTipo=1,"Rubro","Depto")     DATA IF(EMPTY(oQry:rubro),IF(nTipo=1,"(Rubro","(Depto")+" sin definir)",oQry:rubro);
                         SIZE 30 FONT 1
COLUMN TITLE "Unidades"  DATA oQry:cantidad  PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Importe"   DATA oQry:importe   PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Utilidad"  DATA oQry:importe - oQry:costo   PICTURE "999999999.99" ;
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
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()
RETURN 

*********************************************************
*** Resumen ventas por vendedor
PROCEDURE RepVen7()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,oGru,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(7), oBot1, oBot2, oQryVen,;
      cTodos := "Todos los vendedores            ", mnomven := SPACE(30), mdesde := DATE(),;
      mhasta := DATE(), lAdmin,;
      mvendedor := 0, lTipo := .f.,nTipo:=3,aTipo:={"Sistema","Demo","Ambos"}, lResu := .f.,;
      lSoloDeuda := .f., aVendedores := {"TODOS"}, cVendedor := "TODOS", nTipo1 := 1, aTipo1:= {"Ventas Concretadas","Presupuestos"}
IF oApp:usua_es_vendedor 
   oQryVen:= oApp:oServer:Query("SELECT usuario FROM ge_"+oApp:cId+"usuarios")
   oQryVen:GoTop()
   DO WHILE !oQryVen:Eof()
       AADD(aVendedores,oQryVen:usuario)
       oQryVen:Skip()
   ENDDO        
   ELSE
   oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")           
ENDIF  
lAdmin := oApp:oServer:Query("SELECT IF(tipo='ADMIN',1,0) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin = 1
IF !lAdmin 
   cVendedor = oApp:usuario 
ENDIF   
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Ventas por fecha por vendedor" FROM 03,15 TO 15,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   IF !oApp:usua_es_vendedor 
      @ 37, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
      ELSE 
      @ 37, 01 SAY "Vendedor :" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   ENDIF   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   IF !oApp:usua_es_vendedor  
      @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
      @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))
      ELSE
      @ 35, 65 COMBOBOX oGet[3] VAR cVendedor OF oDlg1 ITEMS aVendedores PIXEL SIZE 90,12 WHEN(lAdmin)
   ENDIF             
   @ 50, 05 CHECKBOX oGet[6] VAR lResu      PROMPT "Emitir resumen" PIXEL SIZE 50,12 OF oDlg1
   @ 50, 100 COMBOBOX oGet[7] VAR nTipo1 OF oDlg1 ITEMS aTipo1 PIXEL SIZE 90,12

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
IF !mrta   
   RETURN
ENDIF
IF oApp:usua_es_vendedor .and. cVendedor = "TODOS"
   mvendedor := 0
ELSE
   IF oApp:usua_es_vendedor 
      mnomven := cVendedor
      mvendedor = -1
   ENDIF
ENDIF   
mnomven:= alltrim(mnomven)
CursorWait()
lTipo:= IF(nTipo=1,.t.,.f.)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC  
IF nTipo1 = 1
    IF lResu
    oQry := oApp:oServer:Query("SELECT v.codcli AS codigo, c.nombre as nombre, "+;
                             " SUM(v.importe*IF(v.ticomp='NC' OR v.ticomp='DE',-1,1)) AS importe, "+;
                             " COUNT(v.codcli) AS casos "+;
                             " FROM ge_"+oApp:cId+"ventas_encab v "+;
                             " LEFT JOIN ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;                         
                             " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                             " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                             " v.letra " + IF(lTipo,"<> 'X'","<> ' '") + " AND "+;
                             IF(mvendedor = 0,"TRUE"," v.vendedor = " + ClipValue2Sql(mnomven)) +;
                             " GROUP BY v.codcli ORDER BY casos DESC " )

    REPORT oRep TITLE "Resumen Ventas vendedor " + ALLTRIM(mnomven)  + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) + IF(!lTipo," (Sistema)"," (Demo)");
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Resumen Ventas por fecha" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Resumen Ventas por fecha"

    COLUMN TITLE "Codigo"    DATA oQry:codigo    PICTURE "9999999" SIZE 08 FONT 1
    COLUMN TITLE "Cliente"   DATA oQry:nombre    SIZE 30 FONT 1
    COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "9999999999.99" ;
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
             ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
    oQry:End()
    ELSE
    oQry := oApp:oServer:Query("SELECT v.codcli AS codigo, c.nombre as nombre,v.fecha, "+;
                             " v.importe*IF(v.ticomp='NC',-1,1) AS importe,IF(v.vendedor IS NULL, v.usuario,v.vendedor) AS nomven, "+;                         
                             " CONCAT(v.ticomp,v.letra,v.numcomp) AS compro "+;
                             " FROM ge_"+oApp:cId+"ventas_encab v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;                         
                             " WHERE v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                             " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                             " v.letra " + IF(lTipo,"<> 'X'","<> ' '") + " AND "+;
                             IF(mvendedor = 0,"TRUE"," (v.vendedor = " + ClipValue2Sql(mnomven)+" OR v.usuario = " + ClipValue2Sql(mnomven)+") " ) +;                         
                             " ORDER BY v.vendedor,v.fecha " )

    REPORT oRep TITLE "Detalle Ventas vendedor " + ALLTRIM(mnomven)  + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) + IF(!lTipo," (Sistema)"," (Demo)");
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Detalle Ventas por vendedor" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Detalle Ventas por vendedor"
    IF mvendedor = 0
       GROUP oGru ON oQry:nomven HEADER oQry:nomven FOOTER "Totales por vendedor"  FONT 3
    ENDIF  

    COLUMN TITLE "Codigo"    DATA oQry:codigo    PICTURE "9999999" SIZE 08 FONT 1
    COLUMN TITLE "Cliente"   DATA oQry:nombre    SIZE 30 FONT 1
    COLUMN TITLE "Fecha"     DATA oQry:fecha     SIZE 08 FONT 1
    COLUMN TITLE "Comprob."  DATA oQry:compro    SIZE 16 FONT 1
    COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "9999999999.99" ;
                             SIZE 10 FONT 2 TOTAL

    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                    ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3);
                    ON POSTGROUP oRep:NewLine()
    oQry:End()
    ENDIF
ELSE 
    IF lResu
    oQry := oApp:oServer:Query("SELECT * "+;
                             " FROM ge_"+oApp:cId+"presupuestos "+;                             
                             " WHERE fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                             " fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                             IF(mvendedor = 0,"TRUE"," (vendedor = " + ClipValue2Sql(mnomven)+" OR usuario = " + ClipValue2Sql(mnomven)+") " ) +;
                             " ORDER BY fecha " )

    REPORT oRep TITLE "Presupuestos del Vendedor " + ALLTRIM(mnomven)  + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Presupuestos por fecha" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Presupuesto por fecha"

    COLUMN TITLE "Codigo"    DATA oQry:codcli    PICTURE "9999999" SIZE 08 FONT 1
    COLUMN TITLE "Cliente"   DATA oQry:nombre    SIZE 25 FONT 1
    COLUMN TITLE "Direccion" DATA oQry:direccion SIZE 25 FONT 1
    COLUMN TITLE "Importe"   DATA oQry:importe PICTURE "9999999999.99" ;
                             SIZE 10 FONT 2 TOTAL
    COLUMN TITLE "Fecha Emi." DATA oQry:fecha     SIZE 09 FONT 1
    COLUMN TITLE "Fecha Vto." DATA oQry:fecvto    SIZE 09 FONT 1
    COLUMN TITLE "Vendedor"   DATA oQry:vendedor  SIZE 12 FONT 1
    COLUMN TITLE "Caja"       DATA oQry:caja      SIZE 04 FONT 1
    COLUMN TITLE "Estado"     DATA IF(oQry:estado=1,"Presupuestado","Facturado")      SIZE 11 FONT 1


    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
             ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
    oQry:End()
    ELSE
    oQry := oApp:oServer:Query("SELECT p.*, p1.* "+;
                             " FROM ge_"+oApp:cId+"presupuestos p "+;
                             " LEFT JOIN ge_"+oApp:cId+"presupuestos_det p1 ON p.id = p1.numven "+;        
                             " WHERE fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                             " fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                             IF(mvendedor = 0,"TRUE"," vendedor = " + ClipValue2Sql(mnomven)) +;
                             " ORDER BY p.id " )

    REPORT oRep TITLE "Detalle Presupuestos vendedor " + ALLTRIM(mnomven)  + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Detalle Presupuestos por vendedor" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Detalle Presupuestos por vendedor"
    GROUP oGru ON oQry:id HEADER ALLTRIM(oQry:nombre)+ " Ven:"+ALLTRIM(oQry:vendedor) + ;
            " Emisión:"+DTOC(oQry:fecha)+" Vto:"+DTOC(oQry:fecvto)  FOOTER "Total Presupuesto"  FONT 3

    COLUMN TITLE "Codigo"    DATA oQry:codart    PICTURE "999999999999" SIZE 08 FONT 1
    COLUMN TITLE "Detalle"   DATA oQry:detart    SIZE 30 FONT 1
    COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "999999999" SIZE 10 FONT 2 TOTAL
    COLUMN TITLE "P.Unitar"  DATA oQry:punit    PICTURE "999999999.99" SIZE 10 FONT 2 TOTAL
    COLUMN TITLE "Desc.%"    DATA oQry:descup   PICTURE "999.99" SIZE 08 FONT 1
    COLUMN TITLE "Desc.$"    DATA oQry:descu    PICTURE "999999999.99" SIZE 08 FONT 1 TOTAL 
    COLUMN TITLE "Subtotal"  DATA oQry:importe  PICTURE "999999999.99" SIZE 10 FONT 2 TOTAL
    COLUMN TITLE "Estado"     DATA IF(oQry:estado=1,"Presupuestado","Facturado")      SIZE 11 FONT 1

    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                    ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3);
                    ON POSTGROUP oRep:NewLine()
    oQry:End()
    ENDIF

ENDIF    
RETURN 
/*
***********************************
** Reporte de caja diaria
PROCEDURE RepVen8()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCaj,lDemo:=.f.,;
      cTodos := "Todos las cajas            ", mnomcaj := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      mcaja := 0, mTotal := 0, i, mEfec := 0,lResu:=.f., nTipo := 3,;
      aTipo := {"Sistema","Demo","Ambos"},cUsua:= oApp:usuario,aUsua:={},;
      oQryUsu:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"usuarios"),;
      lAdmin:= oApp:oServer:Query("SELECT IF(tipo='ADMIN',TRUE,FALSE) AS admin FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):admin
oQryUsu:GoTop()
AADD(aUsua,"TODOS")
DO WHILE !oQryUsu:Eof()
   AADD(aUsua,oQryUsu:usuario)
   oQryUsu:Skip()
ENDDO
*caja := oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = " +ClipValue2Sql(oApp:cIp)):caja           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Caja Diaria" FROM 03,15 TO 10,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Fecha:"       OF oDlg1 PIXEL SIZE 40,10 RIGHT 
   
   *@ 22, 01 SAY "Caja Nro:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 50 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 50 COMBOBOX oGet[2] VAR cUsua OF oDlg1 PIXEL ITEMS aUsua SIZE 60,12 WHEN(lAdmin=1)

   @ 05,100 CHECKBOX oGet[2] VAR lResu OF oDlg1 PROMPT "Mostrar detalle"      PIXEL SIZE 45,12

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
IF !mrta   
   RETURN
ENDIF
CursorWait()
lDemo:= IF(nTipo=1,.f.,.t.)
IF !lResu
    oQry := oApp:oServer:Query("SELECT 'FONDO DE CAJA' AS concepto, SUM(importe) AS debe, 0 AS haber, SUM(importe) AS efec "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND usuario = " +ClipValue2Sql(cUsua))+;
                             " UNION "+;
                             "SELECT 'INGRESOS/RETIROS MANUAL' AS concepto, SUM(IF(tipo='I',importe,0)) as debe, SUM(IF(tipo='R',importe,0)) AS haber, SUM(-importe*IF(tipo='I',-1,1)) AS efec "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND usuario = " +ClipValue2Sql(cUsua))+;
                             " UNION "+;
                             "SELECT 'INGRESOS EN EFECTIVO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+; 
                             " AND pc.codcon = 1 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS EN EFECTIVO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, SUM(-oc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND oc.codcon = 1 "+;
                             " UNION "+;
                             "SELECT 'INGRESOS POR TRANSFERENCIAS' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+; 
                             " AND pc.codcon = 2 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS POR TRANSFERENCIAS' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND oc.codcon = 2 "+;
                             " UNION "+;
                             "SELECT 'INGRESOS DE CHEQUES ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND pc.codcon = 3 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS DE CHEQUES' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND (oc.codcon = 3 OR oc.codcon = 4)"+;
                             " UNION "+;
                             "SELECT 'Falt/Sobr ' AS concepto, 0 AS debe,0 AS haber, SUM(importe) AS efec  "+;
                             " FROM ge_"+oApp:cId+"balances WHERE fecha = " + ClipValue2Sql(mdesde)) 
ELSE
    oQry := oApp:oServer:Query("SELECT 'FONDO DE CAJA' AS concepto,' ' AS nombre, importe AS debe, 0 AS haber, importe AS efec,' ' as usuario "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND usuario = " +ClipValue2Sql(cUsua))+;
                             " UNION "+;
                             "SELECT CONCAT(IF(tipo='I','INGRESO','RETIRO'),' ',TRIM(observa)) AS concepto,' ' AS nombre, IF(tipo='I',importe,0) as debe, IF(tipo='R',importe,0) AS haber, importe*IF(tipo='R',-1,1) AS efec, usuario "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND usuario = " +ClipValue2Sql(cUsua))+;
                             " UNION "+;
                             "SELECT CONCAT(pc.observa,' RECIBO ',p.numero) AS concepto, c.nombre AS nombre, pc.importe AS debe,0 AS haber, pc.importe AS efec, p.usuario as usuario   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND pc.codcon = 1 "+;
                             " UNION "+;
                             "SELECT CONCAT(oc.observa,' O.PAGO ',o.numero) AS concepto,p.nombre AS nombre, 0 AS debe, oc.importe AS haber, -oc.importe AS efec , o.usuario as usuario  "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND oc.codcon = 1 "+;
                             " UNION "+;
                             "SELECT CONCAT(pc.observa,' RECIBO ',p.numero) AS concepto,c.nombre AS nombre, pc.importe AS debe,0 AS haber, 0 AS efec, p.usuario as usuario  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND pc.codcon = 2 "+;
                             " UNION "+;
                             "SELECT CONCAT(oc.observa,' O.PAGO ',o.numero) AS concepto,p.nombre AS nombre, 0 AS debe,oc.importe AS haber, 0 AS efec, o.usuario  as usuario  "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND oc.codcon = 2 "+;
                             " UNION "+;
                             "SELECT CONCAT('Ch. ',pc.observa) AS concepto,c.nombre AS nombre, importe AS debe,0 AS haber, 0 AS efec, p.usuario as usuario    "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p.cliente "+;
                             " WHERE p.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND p.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND pc.codcon = 3 "+;
                             " UNION "+;
                             "SELECT CONCAT('Ch. ',oc.observa) AS concepto,p.nombre AS nombre, 0 AS debe,oc.importe AS haber, 0 AS efec, o.usuario as usuario     "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = o.proveedor "+;
                             " WHERE o.fecha = " + ClipValue2Sql(mdesde) +;
                             IF(cUsua="TODOS"," "," AND o.usuario = " +ClipValue2Sql(cUsua))+;
                             " AND (oc.codcon = 3 OR oc.codcon = 4) "+;
                             " UNION "+;
                             "SELECT 'Falt/Sobr ' AS concepto, 'Balance' AS nombre, 0 AS debe,0 AS haber, importe AS efec, '' AS usuario  "+;
                             " FROM ge_"+oApp:cId+"balances WHERE fecha = " + ClipValue2Sql(mdesde))
ENDIF
REPORT oRep TITLE "Resumen de caja diaria del " + DTOC(mdesde)+if(lDemo," (Demo)"," (Sistema)") ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Resumen Caja diaria Usuario: "+ cUsua CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen Caja diaria "+if(lDemo,"(Demo)","(Sistema)")

IF !lResu
    COLUMN TITLE "Concepto"   DATA oQry:concepto    SIZE 30    
    COLUMN TITLE "Ingreso"    DATA oQry:debe        PICTURE "999999999.99" SIZE 10 TOTAL
    COLUMN TITLE "Egreso"     DATA oQry:haber       PICTURE "999999999.99" SIZE 10 TOTAL
    COLUMN TITLE "Efectivo"   DATA oQry:efec        PICTURE "999999999.99" SIZE 10 TOTAL
ELSE
    COLUMN TITLE "Concepto"   DATA oQry:concepto    SIZE 50
    COLUMN TITLE "Nombre"     DATA oQry:nombre      SIZE 30
    COLUMN TITLE "Ingreso"    DATA oQry:debe        PICTURE "999999999.99" SIZE 10 TOTAL
    COLUMN TITLE "Egreso"     DATA oQry:haber       PICTURE "999999999.99" SIZE 10 TOTAL
    COLUMN TITLE "Efectivo"   DATA oQry:efec        PICTURE "999999999.99" SIZE 10 TOTAL
    COLUMN TITLE "Usuario"    DATA oQry:usuario     SIZE 07
ENDIF
// Digo que el titulo lo escriba con al letra 2

oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()
RETURN 
*/
**************************************************************
**** Historial de stock
PROCEDURE RepVen9()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := SPACE(30), mdesde := DATE(), mhasta := DATE(), mcodcli := 0
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"articu ORDER BY codigo")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Historial de stock" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Articulo:"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
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

oQry := oApp:oServer:Query("SELECT * FROM ("+;
                           " SELECT codart, fecha, IF(tipocomp='NC',-cantidad,cantidad) AS debe, 0 AS haber FROM ge_"+oApp:cId+"compradet WHERE codart ="+ ClipValue2Sql(mcodcli)+;
                           " UNION "+; 
                         " SELECT codart, fecha, suma AS debe, resta AS haber FROM ge_"+oApp:cId+"stockman WHERE codart ="+ ClipValue2Sql(mcodcli)+;
                         " UNION "+;
                         " SELECT codart, fecha, 0 AS debe, IF(LEFT(nrofac,2)='NC',-cantidad,cantidad) AS haber FROM ge_"+oApp:cId+"ventas_det WHERE codart = "+ClipValue2Sql(mcodcli)+;
                         ") res1 WHERE res1.fecha >= " + ClipValue2Sql(mdesde) + " AND res1.fecha <= " + ClipValue2Sql(mhasta) )
REPORT oRep TITLE "Historial de stock del articulo " + ALLTRIM(mnomcli)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Historial de stock" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Historial de stock"

COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Ingreso"   DATA oQry:debe PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Egreso"     DATA oQry:haber PICTURE "9999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:Eof()  ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()
RETURN 

**********************************************************
** Reporte de comisiones camioneros
PROCEDURE RepComi()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryVen,;
      cTodos := "Todos los camioneros       ", mnomven := SPACE(30),;
      mdesde := DATE(), mhasta := DATE(), lControl := .f.,;
      mvendedor := 0, lTipo := .f., oGru,nTipo:=1,aTipo:={"Sistema","Demo"}
oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"camioneros")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Comisiones Trasporte" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Transporte (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30))

   @ 20,150 CHECKBOX oGet[6] VAR lControl PROMPT "Emitir reporte control" SIZE 60,12 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
IF !mrta   
   RETURN
ENDIF
CursorWait()
lTipo:= IF(nTipo=1,.f.,.t.)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC 
IF !lControl   
oQry := oApp:oServer:Query("SELECT res.*, cam.nombre AS nomcam FROM ("+;
"SELECT ve.camionero AS camionero, ve.fecha AS fecha, c.nombre as cliente, "+;
"       CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS comprobante,"+; 
"       ( (ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1) ) AS neto, "+;
"       ( (ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1) ) * ((SELECT comiexp FROM parametros)/100) AS comiexp, "+;
"       0 AS comicli, "+;
"       0 AS comifam "+;
"FROM ge_"+oApp:cId+"ventas_encab ve "+;
"LEFT JOIN ge_"+oApp:cId+"clientes c ON ve.codcli = c.codigo  "+;
"WHERE ve.cae IS "+IF(lTipo,"","NOT ")+"NULL "+;
"AND   ve.fecasi >= "+ClipValue2Sql(mdesde)+" "+;
"AND   ve.fecasi <= "+ClipValue2Sql(mhasta)+" "+;
"AND   c.transporte > 0 "+;
"UNION "+;
"SELECT ve.camionero AS camionero, ve.fecha AS fecha, c.nombre as cliente, "+;
"       CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS comprobante,  "+;
"       ((ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1)) AS neto, "+;
"       0 AS comiexp, "+;
"       ((ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1)) * (cc.comision/100) AS comicli, "+;
"       0 AS comifam "+;
"FROM ge_"+oApp:cId+"ventas_encab ve "+;
"LEFT JOIN ge_"+oApp:cId+"comicli cc ON ve.codcli = cc.codcli  "+;
"LEFT JOIN ge_"+oApp:cId+"clientes c ON ve.codcli = c.codigo  "+;
"WHERE ve.cae IS "+IF(lTipo,"","NOT ")+" NULL "+;
"AND   ve.fecasi >= "+ClipValue2Sql(mdesde)+" "+;
"AND   ve.fecasi <= "+ClipValue2Sql(mhasta)+" "+;
"AND   cc.codcli IS NOT NULL "+;
"UNION "+;
"SELECT ve.camionero AS camionero, ve.fecha AS fecha, c.nombre as cliente, "+;
"       CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS comprobante,  "+;
"       ((ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1)) AS neto, "+;
"       0 AS comiexp, "+;
"       0 AS comicli, "+;
"       (SELECT SUM( ( (vd.neto - vd.recargo) * IF(ve.ticomp='NC',-1,1)) * (g.comision/100))  "+;
"        FROM ge_"+oApp:cId+"ventas_det vd  "+;
"        LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = vd.codart "+;
"        LEFT JOIN ge_"+oApp:cId+"grupos g ON g.codigo = a.grupo  "+;
"        WHERE vd.ticomp = ve.ticomp AND vd.letra = ve.letra AND vd.numcomp = ve.numcomp) AS comifam  "+;
"FROM ge_"+oApp:cId+"ventas_encab ve "+;
"LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = ve.codcli  "+;
"LEFT JOIN ge_"+oApp:cId+"comicli cc ON cc.codcli = c.codigo "+;
"WHERE ve.cae IS "+IF(lTipo,"","NOT ")+" NULL "+;
"AND   ve.fecasi >= "+ClipValue2Sql(mdesde)+" "+;
"AND   ve.fecasi <= "+ClipValue2Sql(mhasta)+" "+;
"AND   cc.codcli IS NULL "+;
"AND   c.transporte = 0) res "+;
" LEFT JOIN ge_"+oApp:cId+"camioneros cam ON cam.codigo = res.camionero "+;
" WHERE res.camionero "+IF(mvendedor=0," > 0"," = " +ClipValue2Sql(mvendedor))+;
" ORDER BY res.camionero, res.fecha")

REPORT oRep TITLE "Comisiones por Transporte del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta)+ IF(!lTipo," (Sistema)"," (Demo)") ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Transporte " + mnomven CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Comisiones Transporte"    
IF mvendedor = 0
GROUP oGru ON oQry:camionero HEADER oQry:nomcam FOOTER "Totales Transporte"  FONT 2
ENDIF
COLUMN TITLE "Nro.Fact." DATA oQry:comprobante   SIZE 15 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 10 FONT 1   
COLUMN TITLE "Cliente"   DATA oQry:cliente  SIZE 25 FONT 1
COLUMN TITLE "Neto"      DATA oQry:neto      PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
COLUMN TITLE "A Expreso" DATA oQry:comiexp   PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
COLUMN TITLE "A Cl.Esp." DATA oQry:comicli   PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
COLUMN TITLE "Por Flia." DATA oQry:comifam   PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
    
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3);
                ON POSTGROUP oRep:NewLine()
ELSE
oQry := oApp:oServer:Query("SELECT * FROM("+;
"SELECT ve.camionero AS camionero, ca.nombre as nomcam, ve.fecha AS fecha, ve.fecasi, c.nombre as cliente, "+;
"       CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS comprobante,"+; 
"       (ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1) AS neto, "+;
"       ve.importe * IF(ve.ticomp='NC',-1,1)  AS importe,"+;
"       ve.saldo * IF(ve.ticomp='NC',-1,1) AS saldo, ve.rendida "+;
"FROM ge_"+oApp:cId+"ventas_encab ve "+;
"LEFT JOIN ge_"+oApp:cId+"clientes c ON ve.codcli = c.codigo  "+;
"LEFT JOIN ge_"+oApp:cId+"camioneros ca ON ve.camionero = ca.codigo  "+;
"WHERE ve.cae IS "+IF(lTipo,"","NOT ")+"NULL "+;
"AND   ve.fecasi >= "+ClipValue2Sql(mdesde)+" "+;
"AND   ve.fecasi <= "+ClipValue2Sql(mhasta)+" "+;
"AND   ve.camionero "+IF(mvendedor=0," > 0"," = " +ClipValue2Sql(mvendedor))+;
IF(mvendedor = 0,;
" UNION "+;
"SELECT ve.camionero AS camionero, '*** SIN ASIGNAR ***' as nomcam, ve.fecha AS fecha, ve.fecasi, c.nombre as cliente, "+;
"       CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS comprobante,"+; 
"       (ve.neto - ve.recargo) * IF(ve.ticomp='NC',-1,1) AS neto, "+;
"       ve.importe * IF(ve.ticomp='NC',-1,1)  AS importe,"+;
"       ve.saldo * IF(ve.ticomp='NC',-1,1) AS saldo, ve.rendida "+;
"FROM ge_"+oApp:cId+"ventas_encab ve "+;
"LEFT JOIN ge_"+oApp:cId+"clientes c ON ve.codcli = c.codigo  "+;
"WHERE ve.cae IS "+IF(lTipo,"","NOT ")+"NULL "+;
"AND   ve.camionero = 0 "," ")+;
") res ORDER BY res.camionero, res.fecasi")
REPORT oRep TITLE "Reporte control asignaciones " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta)+ IF(!lTipo," (Sistema)"," (Demo)") ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Transporte " + mnomven CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Control Asignaciones"    
IF mvendedor = 0
GROUP oGru ON oQry:camionero HEADER oQry:nomcam FOOTER "Totales Transporte"  FONT 2
ENDIF
COLUMN TITLE "Nro.Fact."     DATA oQry:comprobante   SIZE 15 FONT 1
COLUMN TITLE "F.Comprob."    DATA oQry:fecha    PICTURE "@D"   SIZE 10 FONT 1   
COLUMN TITLE "F.Asignac."    DATA oQry:fecasi   PICTURE "@D"   SIZE 10 FONT 1   
COLUMN TITLE "Cliente"       DATA oQry:cliente  SIZE 25 FONT 1
COLUMN TITLE "Neto"          DATA oQry:neto     PICTURE "9999999999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Total Comp."   DATA oQry:importe  PICTURE "9999999999.99" SIZE 12 FONT 1 TOTAL
COLUMN TITLE "Observaciones" DATA IF(oQry:saldo = 0, "Pago completo",;
                                  IF(oQry:saldo<oQry:importe,"Pago parcial",;
                                  IF(oQry:rendida,"Rendida Cta.Cte.","Sin Rendir"))) ;
                                  SIZE 20 FONT 2 
    
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3);
                ON POSTGROUP oRep:NewLine()

ENDIF
oQry:End()
RETURN


**************************************************************************
** Citi Ventas 
FUNCTION CitiVentas()
LOCAL mcuit, mtexto, mnombre, mtexto1
LOCAL oGet1, oGet2, oGet3, mdesde := DATE(), oDlg1, aCor, mrta := .f.,;
      oBot1, oBot2, oGet4, mhasta := DATE(), ;
      aEmp := {}, aNov := {}, i, oRep, oFont1, oFont2, oFont3, lIVA := .F.,;
      marchivo, mindice, mgrupo := 1, j, cDoc, ventas, oQryDet
mdesde = DATE()
mhasta = DATE()
DEFINE DIALOG oDlg1 TITLE "Exportar a CITI Ventas" FROM 03,15 TO 12,55 
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL RIGHT SIZE 45,12
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL RIGHT SIZE 45,12   
   @ 05, 55 GET oGet1 VAR mdesde PICTURE "@D" OF oDlg1 PIXEL CENTER
   @ 20, 55 GET oGet2 VAR mhasta PICTURE "@D" OF oDlg1 PIXEL CENTER  
   @ 35, 55 CHECKBOX oGet3 VAR lIVA PROMPT "Libro I.V.A Ventas Digital" SIZE 80,12 PIXEL 
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Exportar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN nil
ENDIF                      
ventas := oApp:oServer:Query("SELECT v.*, c.* FROM ge_"+oApp:cId+"ventas_encab v LEFT JOIN "+;
                             "ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;
                             "WHERE letra <> 'X' AND "+; 
                             "v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                             "       v.fecha <= "+ ClipValue2Sql(mhasta) + " ORDER BY v.fecha ")
mtexto := ""
mtexto1:= ""
DO WHILE !ventas:EOF()
// Anterior
    cDoc := "0"+ventas:tipfor
    mcuit := ventas:cuit
    mcuit := STRTRAN(mcuit,"-","")
    mcuit := STR(VAL(mcuit),20)
    mcuit := STRTRAN(mcuit," ","0")
    mnombre := LEFT(ventas:nombre,30) 
    oQryDet:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventivadet WHERE tipocomp = "+ClipValue2Sql(ventas:ticomp)+;
                             " AND letra = "+ClipValue2Sql(ventas:letra)+" AND numfac = "+ClipValue2Sql(ventas:numcomp))
    mtexto := mtexto +;
              DTOS(ventas:fecha) + cDoc + "0" + SUBSTR(ventas:numcomp,1,4)  + REPLICATE("0",12)+;
              SUBSTR(ventas:numcomp,6,8) + + REPLICATE("0",12)+;
              SUBSTR(ventas:numcomp,6,8) + IF(mcuit=REPLICATE("0",20),"99","80") +;
              mcuit + ;
              mnombre +;
              STRTRAN(STR((ventas:neto+ventas:iva+ventas:iibb+ventas:sobretasa)*100,15)," ","0") + ;
              STRTRAN(STR((ventas:iibb+ventas:sobretasa)*100,15)," ","0") + ;//REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              REPLICATE("0",15)+;
              "PES"+;
              "0001000000"+;
              STR(oQryDet:RecCount(),1)+;
              IF(oQryDet:codiva=3 .and. oQryDet:RecCount()=1,"N"," ")+;
              REPLICATE("0",15)+;
              IF(ventas:ticomp="FC",DTOS(ventas:fecha),REPLICATE("0",8)) +  CHR(13) + CHR(10)
    oQryDet:GoTop()
    DO WHILE !oQryDet:eof()
          mtexto1 := mtexto1 +;
                     cDoc+;
                     "0" + SUBSTR(ventas:numcomp,1,4)  +;
                     REPLICATE("0",12)+SUBSTR(ventas:numcomp,6,8)+;
                     +""+; //"80"+;
                     +""+;//mcuit + ;
                     STRTRAN(STR(oQryDet:neto*100,15)," ","0")+;
                     STRTRAN(STR(oQryDet:codiva,4)," ","0")+;
                     STRTRAN(STR(oQryDet:iva*100,15)," ","0")+;
                     CHR(13) + CHR(10)
          oQryDet:Skip()
    ENDDO
    ventas:SKIP()
ENDDO              
mtexto  := LEFT(mtexto,LEN(mtexto)-2)
mtexto1 := LEFT(mtexto1,LEN(mtexto1)-2)  
IF !lIVA   
  GrabaArchivo("EXPORTA\REGINFO_CV_VENTAS_CBTE.TXT",mtexto)         
  GrabaArchivo("EXPORTA\REGINFO_CV_VENTAS_ALICUOTAS.TXT",mtexto1)
  ELSE 
  GrabaArchivo("EXPORTA\LIBRO_IVA_DIGITAL_VENTAS_CBTE.TXT",mtexto)
  GrabaArchivo("EXPORTA\LIBRO_IVA_DIGITAL_VENTAS_ALICUOTAS.TXT",mtexto1)
ENDIF  
MsgInfo("Proceso Terminado")
RETURN nil


**************************************************************
**** Libro de I.V.A. Ventas
PROCEDURE RepVen3()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      mdesde := DATE(), mhasta := DATE(), lImputaIva := .t., nPunto, ;
      oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip)) 
nPunto := oQryPun:caja

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Libro de I.V.A. Ventas" FROM 03,15 TO 12,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "PV (0:Todos)" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ 35, 65 GET oGet[3] VAR nPunto    OF oDlg1 PIXEL PICTURE "9999" 
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN
ENDIF

CursorWait()
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-6.5
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
Procesando(.t.)     
oQry := oApp:oServer:Query(;
"SELECT CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS compro, ve.fecha, ve.nombre, ve.cuit, LEFT(ti.nombre,3) AS tip, "+;
"   vd.neto * IF(ve.ticomp='NC',-1,1) AS exento , "+;
"   vd1.neto * IF(ve.ticomp='NC',-1,1) AS neto, "+;
"   vd2.neto * IF(ve.ticomp='NC',-1,1) AS neto1, "+;
"   ve.sobretasa * IF(ve.ticomp='NC',-1,1) AS impint, "+;
"   t.tasa AS tasa, "+;
"   t1.tasa AS tasa2, "+;
"   vd1.iva* IF(ve.ticomp='NC',-1,1) AS iva1, "+;
"   vd2.iva* IF(ve.ticomp='NC',-1,1) AS iva2, "+;
"   ve.percep, ve.iibb* IF(ve.ticomp='NC',-1,1) AS iibb "+;
" FROM ge_"+oApp:cId+"ventas_encab ve "+;
" LEFT JOIN ge_"+oApp:cId+"ventivadet vd ON  vd.tipocomp = ve.ticomp AND vd.letra = ve.letra AND vd.numfac=ve.numcomp AND vd.codiva =3 "+;
" LEFT JOIN ge_"+oApp:cId+"ventivadet vd1 ON  vd1.tipocomp = ve.ticomp AND vd1.letra = ve.letra AND vd1.numfac=ve.numcomp AND vd1.codiva = 5 "+;
" LEFT JOIN ge_"+oApp:cId+"ventivadet vd2 ON  vd2.tipocomp = ve.ticomp AND vd2.letra = ve.letra AND vd2.numfac=ve.numcomp AND vd2.codiva = 4 "+;
" LEFT JOIN ge_"+oApp:cId+"ivas t ON t.codigo = vd1.codiva "+;
" LEFT JOIN ge_"+oApp:cId+"ivas t1 ON t1.codigo = vd2.codiva "+;
" LEFT JOIN ge_"+oApp:cId+"tipoiva ti ON ti.codigo = ve.coniva  "+;
" WHERE ve.letra <> 'X' "+;
IF(nPunto = 0," "," AND LEFT(numcomp,4) = " + ClipValue2Sql(STRTRAN(STR(nPunto,4)," ","0")))+;
" AND ve.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
"     ve.fecha <= "+ ClipValue2Sql(mhasta) +;
" ORDER BY ve.fecha")  
/*
"SELECT CONCAT(ve.ticomp,ve.letra,ve.numcomp) AS compro, ve.fecha, ve.nombre, ve.cuit, LEFT(ti.nombre,3) AS tip, "+;
"(SELECT vd.neto * IF(ve.ticomp='NC',-1,1) FROM ventivadet vd  "+;
"   WHERE vd.ticomp = ve.ticomp AND vd.letra = ve.letra AND vd.numcomp=ve.numcomp AND vd.codiva =2) AS exento , "+;
"   ve.neto * IF(ve.ticomp='NC',-1,1) AS neto, "+;
" (SELECT t.tasa FROM ventivadet vd LEFT JOIN ivas t ON t.codigo = vd.codiva  "+;
"   WHERE vd.ticomp = ve.ticomp AND vd.letra = ve.letra AND vd.numcomp=ve.numcomp AND vd.codiva <>2) AS tasa, "+;
"    ve.iva* IF(ve.ticomp='NC',-1,1) AS iva, ve.percep, ve.iibb* IF(ve.ticomp='NC',-1,1) AS iibb, ve.importe * IF(ve.ticomp='NC',-1,1) AS importe "+;
"    FROM ventas_encab ve "+;
"    LEFT JOIN tipoiva ti ON ti.codigo = ve.coniva  "+;
"WHERE ve.cae IS NOT NULL "+;
" AND ve.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
"     ve.fecha <= "+ ClipValue2Sql(mhasta) +;
"ORDER BY ve.fecha")    
*/             
Procesando(.f.)           
REPORT oRep TITLE "SUBDIARIO I.V.A. Ventas " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2  ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "SUBDIARIO I.V.A. Ventas" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "SUBDIARIO I.V.A. Ventas"

COLUMN TITLE "Fecha"       DATA oQry:fecha    SIZE 08 FONT 1
COLUMN TITLE "Comprobante" DATA oQry:compro   SIZE 16 FONT 1
COLUMN TITLE "Cliente"     DATA oQry:nombre   SIZE 30 FONT 1
COLUMN TITLE "C.U.I.T."    DATA oQry:cuit     SIZE 12 FONT 1
COLUMN TITLE "SI"          DATA oQry:tip      SIZE  2 FONT 1
COLUMN TITLE "Exento "     DATA oQry:exento   PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Neto "       DATA oQry:neto     PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Neto2"       DATA oQry:neto1    PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "I.V.A. "     DATA oQry:iva1     PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "I.V.A. 2"    DATA oQry:iva2     PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Tasa 1"      DATA oQry:tasa     PICTURE "99.99"        SIZE 05 FONT 1 
COLUMN TITLE "Tasa 2"      DATA oQry:tasa2    PICTURE "99.99"        SIZE 05 FONT 1 
COLUMN TITLE "Perc"        DATA oQry:percep   PICTURE "99.99"        SIZE 05 FONT 1 
COLUMN TITLE "IIBB"        DATA oQry:iibb     PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Imp.Int"     DATA oQry:impint   PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Total"       DATA oQry:exento+oQry:neto+oQry:neto1+oQry:iva1+oQry:iva2+oQry:percep+oQry:impint  PICTURE "99999999999.99" SIZE 10 FONT 1 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
oRep:cPageTotal := 'Transporte'
oRep:cGrandTotal := 'Totales'

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()

// Resumen por tico de comprador
oQry := oApp:oServer:Query(;
"SELECT vd.codiva as codiva,ve.ticomp as tico,ve.letra as let, LEFT(ti.nombre,3) AS tip, ti.nombre as tip1,"+;
"   SUM(vd.neto * IF(vd.tipocomp='NC',-1,1)) AS neto , "+;
"   t.tasa AS tasa, "+;
"   SUM(vd.iva* IF(vd.tipocomp='NC',-1,1)) AS iva, "+;
"   0 as impint, 0 as iibb,"+;
"   SUM((vd.neto + vd.iva  ) * IF(vd.tipocomp='NC',-1,1)) AS importe "+;
" FROM ge_"+oApp:cId+"ventivadet vd "+;
" LEFT JOIN ge_"+oApp:cId+"ventas_encab ve ON   vd.tipocomp = ve.ticomp AND vd.letra = ve.letra AND vd.numfac=ve.numcomp"+;
" LEFT JOIN ge_"+oApp:cId+"ivas t ON t.codigo = vd.codiva "+;
" LEFT JOIN ge_"+oApp:cId+"tipoiva ti ON ti.codigo = ve.coniva  "+;
" WHERE vd.letra <> 'X' "+;
" AND ve.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
"     ve.fecha <= "+ ClipValue2Sql(mhasta) +;
IF(nPunto = 0," "," AND LEFT(numcomp,4) = " + ClipValue2Sql(STRTRAN(STR(nPunto,4)," ","0")))+;
" GROUP BY vd.tipocomp,vd.letra,LEFT(ti.nombre,3),ti.nombre,vd.codiva " +;
" UNION ALL " +;
"SELECT 1 as codiva,ve.ticomp as tico,ve.letra as let, LEFT(ti.nombre,3) AS tip, ti.nombre as tip1,"+;
"   0 AS neto , "+;
"   0 AS tasa, "+;
"   0 AS iva, "+;
"   SUM(ve.sobretasa * IF(ve.ticomp='NC',-1,1)) AS impint, "+;
"   SUM(ve.iibb* IF(ve.ticomp='NC',-1,1)) AS iibb, "+;
"   SUM((ve.sobretasa + ve.iibb) * IF(ve.ticomp='NC',-1,1)) AS importe "+;
" FROM ge_"+oApp:cId+"ventas_encab ve "+;
" LEFT JOIN ge_"+oApp:cId+"tipoiva ti ON ti.codigo = ve.coniva  "+;
" WHERE ve.letra <> 'X' AND (ve.sobretasa > 0 or ve.iibb > 0) "+;
" AND ve.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
"     ve.fecha <= "+ ClipValue2Sql(mhasta) +;
IF(nPunto = 0," "," AND LEFT(numcomp,4) = " + ClipValue2Sql(STRTRAN(STR(nPunto,4)," ","0")))+;
" GROUP BY ve.ticomp,ve.letra,LEFT(ti.nombre,3),ti.nombre " )  

REPORT oRep TITLE "SUBDIARIO I.V.A. Ventas RESUMEN " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2  ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "SUBDIARIO I.V.A. Ventas - Resumn por tipo de comprador" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "SUBDIARIO I.V.A. Ventas"

COLUMN TITLE "Tipo"        DATA oQry:tico     SIZE  4 FONT 1
COLUMN TITLE "Let"         DATA oQry:let      SIZE  3 FONT 1
COLUMN TITLE "Situación I.V.A."  DATA oQry:tip1     SIZE  20 FONT 1
COLUMN TITLE "Exento "     DATA IF(oQry:codiva=3,oQry:neto,0)   PICTURE "999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Neto "       DATA IF(oQry:codiva=3,0,oQry:neto)     PICTURE "999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Tasa "       DATA oQry:tasa     PICTURE "99.99"        SIZE 05 FONT 1 
COLUMN TITLE "I.V.A. "     DATA oQry:iva      PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "IIBB"        DATA oQry:iibb     PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Imp.Int"     DATA oQry:impint   PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL
COLUMN TITLE "Total"       DATA oQry:importe  PICTURE "9999999999.99" SIZE 10 FONT 1 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
oQry:End()
RETURN 

***********************************
** Reporte de Pecepciones
PROCEDURE RepVen10()
LOCAL oRep, oQry, oQryPun, oDlg1, oFont, Han, mlinea, nBytes,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE()
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Generar archivo percepciones PERCEP.TXT" FROM 03,15 TO 11,70 Of oApp:oWnd
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
oQry := oApp:oServer:Query("SELECT v.cuit,v.fecha,IF(v.ticomp='NC','C',IF(v.ticomp='FC','F','D')) as tipo,v.letra,"+;
                           " CONCAT(LEFT(v.numcomp,4),RIGHT(v.numcomp,8)) as compro,"+;
                           "v.neto*IF(v.ticomp='NC',-1,1) as neto,v.iibb*IF(v.ticomp='NC',-1,1) as iibb"+;
                           " FROM ge_"+oApp:cId+"ventas_encab v "+;
                           " WHERE v.fecha >= " + ClipValue2Sql(mdesde) +;
                           " AND   v.fecha <= " + ClipValue2Sql(mhasta) +;
                           " AND   v.iibb > 0 AND v.letra <> 'X'")
  REPORT oRep TITLE "Percepciones entre " + DTOC(mdesde) + " y el " + DTOC(mhasta) ;
         HEADER OemToAnsi(oApp:nomb_emp) , ;
         "Percepciones (PERCEP.TXT)" CENTER ;
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Percepciones"

  COLUMN TITLE "C.U.I.T"    DATA oQry:cuit        SIZE 15
  COLUMN TITLE "Fecha"      DATA oQry:fecha       SIZE 08
  COLUMN TITLE "Tipo"       DATA oQry:tipo        SIZE 03
  COLUMN TITLE "Letra"      DATA oQry:letra       SIZE 03
  COLUMN TITLE "Comprob."   DATA oQry:compro      SIZE 12
  COLUMN TITLE "Neto"       DATA oQry:neto        PICTURE "9999999999.99" SIZE 10 TOTAL
  COLUMN TITLE "Percepc."   DATA oQry:iibb        PICTURE "9999999999.99" SIZE 10 TOTAL


  // Digo que el titulo lo escriba con al letra 2

  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }

  END REPORT
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",.3,.3)
Han := LCREAT("EXPORTA\PERCEP.TXT")
oQry:GoTop()
DO WHILE !oQry:Eof()
   mlinea := oQry:cuit+;
             DTOC(oQry:fecha)+;
             oQry:tipo+oQry:letra+oQry:compro+;
             IF(oQry:neto>0,"0","-")+STRTRAN(STR(ABS(oQry:neto),11,2)," ","0") +;
             IF(oQry:neto>0,"0","-")+STRTRAN(STR(ABS(oQry:iibb),10,2)," ","0")+;
             "A"+CHR(13)+CHR(10)
   nBytes := FWRITE(Han,mlinea,63)
   oQry:Skip()
ENDDO  
LCLOSE(Han)
MsgInfo("Se ha creado el archivo PERCEP.TXT")
oQry:End()
RETURN 