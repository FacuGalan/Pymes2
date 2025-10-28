#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** TRANSFORMACION DE ARTICULOS
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot, nCodArtP, oQryRes, oQryHace,;
       oBrw1, oBrw2, oQry, oQryArtP, nHacer, oSay1, oQryPun
PROCEDURE PRODUCC(cPermisos)
LOCAL oFont, oFo1, cNomArt:=SPACE(30),  mobserva, Lrta := .f., aObserva := {}, oFontTotal,;
      nCosto :=0, nValor:=0, oError
oGet := ARRAY(12)
oBot := ARRAY(07)
oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip))
nCodArtP:=0
nHacer:=0
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reseta_temp ";
    +"( `CODART` BIGINT(14) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";   //PRIMARY KEY (`CODART`)
    +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`PTOTAL` DECIMAL(12,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`CODART`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE reseta_temp")
oApp:oServer:NextResult()
oQryRes:= oApp:oServer:Query("SELECT * FROM reseta_temp")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reseta_temp1 ";
    +"( `CODART` BIGINT(14) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";
    +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`PTOTAL` DECIMAL(12,2) DEFAULT '0.00',";
    +"`STOCK` DECIMAL(12,3) DEFAULT '0.00',";
    +"PRIMARY KEY (`CODART`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE reseta_temp1")
oApp:oServer:NextResult()
oQryHace:= oApp:oServer:Query("SELECT * FROM reseta_temp1")

oQryArtP:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE produccion")
DO WHILE .T.
   DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
   DEFINE DIALOG oDlg RESOURCE "TRANSF" OF oApp:oWnd 
    oDlg:lHelpIcon := .f. 
    REDEFINE GET oGet[1] VAR nCodArtP ID 100 OF oDlg PICTURE "99999999999999";
                 VALID (ValidaArt());
                 ACTION (oGet[01]:cText:= 0, ValidaArt()) BITMAP "BUSC1" 
    REDEFINE GET oGet[2] VAR cNomArt ID 101 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE BUTTON oBot[3] ID 4001 OF oDlg ACTION (oDlg:End(),ReporteProd()) CANCEL
    REDEFINE SAY oSay1 PROMPT "Receta para "+ALLTRIM(STR(oQryArtP:cantprod))+" "+ALLTRIM(oQryArtP:unimed) ID 200 OF oDlg
    REDEFINE XBROWSE oBrw1 DATASOURCE oQryRes;
              COLUMNS "CODART","DETART","CANTIDAD","PUNIT","PTOTAL";
              HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total";
              FOOTERS ;
              SIZES 80,281,60,80,80 ID 300 OF oDlg 
    PintaBrw(oBrw1,0)
    oBrw1:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw1:MakeTotals()
    REDEFINE GET oGet[3] VAR nHacer ID 102 OF oDlg PICTURE "9999999.999"
    oGet[3]:bLostFocus := {|| oGet[3]:assign(),ActualizaBrw()}
    REDEFINE XBROWSE oBrw2 DATASOURCE oQryHace;
              COLUMNS "CODART","DETART","CANTIDAD","PUNIT","PTOTAL","STOCK";
              HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total","Stock";
              FOOTERS ;
              SIZES 80,281,60,80,80,80 ID 301 OF oDlg 
    PintaBrw(oBrw2,0)
    oBrw2:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw2:aCols[3]:nEditType := 1
    oBrw2:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,)}     
    oBrw2:MakeTotals()
    IF oQryPun:pidestock <> 2
       oBrw2:aCols[6]:Hide()
    ENDIF   


    REDEFINE GET oGet[4] VAR nCosto    ID 103 OF oDlg COLOR CLR_RED , CLR_YELLOW READONLY;
                 PICTURE "999999999.99" FONT oFontTotal 
    REDEFINE GET oGet[5] VAR nValor   ID 104 OF oDlg COLOR CLR_RED , CLR_YELLOW READONLY;
                 PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)

    REDEFINE BUTTON oBot[1] ID 201 OF oDlg ACTION (lRta:=.t.,oDlg:End()) PROMPT "&Producir"
    REDEFINE BUTTON oBot[2] ID 202 OF oDlg ACTION (lRta:=.f.,oDlg:End()) CANCEL
    *oDlg:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBrw:Report("Estado de deuda de " + mnomcli),.f.) }
   ACTIVATE DIALOG oDlg CENTER ON INIT (oGet[1]:SetFocus(),Ocultar(cPermisos,oGet)) 
   IF !Lrta
      EXIT
   ENDIF
  IF oQryPun:pidestock = 2 
     IF oApp:oServer:Query("SELECT * FROM reseta_temp1 WHERE stock < cantidad"):nRecCount > 0
        MsgStop("No puede producir el articulo seleccionado porque no estan en stock"+CHR(10)+;
           "algunos de sus componentes","Atencion")
        LOOP 
     ENDIF     
  ENDIF   
  TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE reseta_temp1 r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                       "SET a.stockact = a.stockact - r.cantidad ")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET stockact = stockact + "+ClipValue2Sql(nHacer)+" "+;
                       "WHERE codigo = " + ClipValue2Sql(oQryArtP:codigo))
  //Agrego al movimiento de stock el ingreso
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"stoman (codart,entradas,salidas,fecha,motivo,costo,usuario) VALUES "+;
                       "("+ClipValue2Sql(oQryArtP:codigo)+","+;
                       ClipValue2Sql(nHacer)+","+;
                       "0,"+;
                       "CURDATE(),"+;
                       "9,"+;
                       ClipValue2Sql(oQryArtP:preciocos)+","+;
                       ClipValue2Sql(oApp:usuario)+;
                       ")") 
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"stoman (codart,entradas,salidas,fecha,motivo,costo,usuario) "+;
                       "(SELECT codart,0,cantidad,CURDATE(),9,punit,"+ClipValue2Sql(oApp:usuario)+" FROM reseta_temp1) ")  
  IF !oApp:oServer:TableExist("ge_"+oApp:cId+"produccion")
      oApp:oServer:Execute("";
      + "CREATE TABLE ge_"+oApp:cId+"produccion";
      +"( ID INT(8) NOT NULL AUTO_INCREMENT, "+; 
      +"`FECHA` DATE NOT NULL,";  
      +"`CODART` BIGINT(14) NOT NULL,";  
      +"`DETART` VARCHAR(60) NOT NULL,";   
      +"`DETALLE` VARCHAR(100) NOT NULL,";   
      +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
      +"`PRECIO` DECIMAL(10,2) DEFAULT '0.00', ";
      +"`CODPRO` BIGINT(14) NOT NULL DEFAULT 0,";
      +"`USUARIO` VARCHAR(15) NULL DEFAULT 'MIGRA',";  
      +"PRIMARY KEY (`ID`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
  ENDIF    
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"produccion (fecha,codart,detart, detalle,cantidad,precio,codpro,usuario) "+;
                       "(SELECT curdate(),codart,detart,'Produccion "+ALLTRIM(cNomArt)+" x "+;
                       ALLTRIM(STR(nHacer,12,2))+"',cantidad,punit,"+ClipValue2Sql(nCodArtP)+","+ClipValue2Sql(oApp:usuario)+" FROM reseta_temp1) ")  
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN

STATIC FUNCTION Ocultar(cPermisos,oGet)
IF !'B'$cPermisos
   oBrw1:aCols[4]:Hide()
   oBrw1:aCols[5]:Hide()
   oBrw2:aCols[4]:Hide()
   oBrw2:aCols[5]:Hide()
   oGet[4]:Hide()
   oGet[5]:Hide()
ENDIF
RETURN nil   

****************************************************************************************************************************
****** ACTUALIZA EL BROWSE CON LOS ARTICULOS A USAR
STATIC FUNCTION ActualizaBrw()
LOCAL nMultiplica:=0
SET DECIMALS TO 12
nMultiplica:= nHacer / oQryArtP:cantprod
oApp:oServer:Execute("TRUNCATE reseta_temp1")
oApp:oServer:Execute("INSERT INTO reseta_temp1 (codart,detart,cantidad,punit,ptotal,stock) "+;
                     "(SELECT r.codusa,a.nombre,r.cantidad*"+ClipValue2Sql(nMultiplica)+;
                     ",a.preciocos,r.cantidad*a.preciocos*"+ClipValue2Sql(nMultiplica)+", a.stockact "+;
                     "FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codusa "+;
                     "WHERE r.codart = " + ClipValue2Sql(oQryArtP:codigo)+")")
oQryHace:Refresh()
oBrw2:Refresh()
oBrw2:MakeTotals()
SET DECIMALS TO 2
oGet[4]:cText:= oBrw2:aCols[5]:nTotal
oGet[5]:cText:= nHacer * oQryArtP:precioven
RETURN nil
*****************************************************************************************************************************
****** VALIDO EL ARTICULO Y BUSCO LA RESETA 
STATIC FUNCTION ValidaArt()
LOCAL oQryValid:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE produccion AND codigo = "+ ClipValue2Sql(nCodArtP))
IF oQryValid:RecCount() > 0 
   oGet[02]:cText:= oQryValid:nombre 
   oQryArtP:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE produccion AND codigo = "+ ClipValue2Sql(nCodArtP))
ELSE
   Buscar(oQryArtP,oDlg,oGet[01],oGet[02],"TRUE","produccion")   
ENDIF
IF oQryArtP:produccion = .f.
   MsgStop("El articulo no es de produccion","Error")
   RETURN nil 
ENDIF
oApp:oServer:Execute("DELETE FROM reseta_temp")
oApp:oServer:Execute("INSERT INTO reseta_temp (codart,detart,cantidad,punit,ptotal) "+;
                     "(SELECT r.codusa,a.nombre,r.cantidad,a.preciocos,r.cantidad*a.preciocos "+;
                     "FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codusa "+;
                     "WHERE r.codart = " + ClipValue2Sql(oQryArtP:codigo)+")")
oQryRes:Refresh()
oBrw1:Refresh()
oBrw1:MakeTotals()
oApp:oServer:Execute("DELETE FROM reseta_temp1")
oApp:oServer:Execute("TRUNCATE reseta_temp1")
oApp:oServer:Execute("INSERT INTO reseta_temp1 (codart,detart,cantidad,punit,ptotal) "+;
                     "(SELECT r.codusa,a.nombre,r.cantidad,a.preciocos,r.cantidad*a.preciocos "+;
                     "FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codusa "+;
                     "WHERE r.codart = " + ClipValue2Sql(oQryArtP:codigo)+")")
oQryHace:Refresh()
oBrw2:Refresh()
oBrw2:MakeTotals()
IF oQryRes:RecCount() = 0
   MsgStop("El articulo seleccionado no tiene una receta cargada para la transformacion ","Atencion!")
   RETURN .f.
ENDIF
oGet[3]:cText:= oQryArtP:cantprod
oGet[4]:cText:= oBrw2:aCols[5]:nTotal
oGet[5]:cText:= nHacer * oQryArtP:precioven
oSay1:Refresh()
RETURN .t.

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.

**********************************************
** Reporte de Movimientos produccion
STATIC FUNCTION ReporteProdAnt()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      cSql, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f.
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Materia prima usada para produccion" FROM 03,15 TO 13,60
   acor := AcepCanc(oDlg1)         
   @ 07, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 22, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 05 CHECKBOX oGet[3] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF
IF !lResu
   cSql := "SELECT * FROM ge_"+oApp:cId+"produccion "
   ELSE
   cSql := "SELECT codart, detart, SUM(cantidad) AS cantidad,  SUM(cantidad * precio) as precio  FROM ge_"+oApp:cId+"produccion "   
ENDIF
cSql := cSql + ;
        "WHERE fecha >= " + ClipValue2Sql(mdesde) +;
        "  AND fecha <= " + ClipValue2Sql(mhasta) 
IF lResu
   cSql := cSql + " GROUP BY codart ORDER BY detart"
   ELSE
   cSql := cSql + " ORDER BY fecha"
ENDIF   
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Movimientos de stock por produccion del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Produccion" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Produccion"
IF !lResu   
   COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 9 FONT 1      
ENDIF   
COLUMN TITLE "Mat.Prima" DATA oQry:detart   SIZE 30 FONT 1
COLUMN TITLE "Codigo"    DATA oQry:codart   SIZE 13 FONT 1
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "9999999.99" ;
                            SIZE 10 FONT 2 TOTAL
IF !lResu                            
   COLUMN TITLE "Costo"     DATA oQry:precio PICTURE "9999999999.99" ;
                            SIZE 10 FONT 1
   COLUMN TITLE "Total"     DATA oQry:precio*oQry:cantidad PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL
   ELSE
   COLUMN TITLE "Total"     DATA oQry:precio PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL                             
ENDIF
IF !lResu
   COLUMN TITLE "Para"    DATA oQry:detalle SIZE 40 
   COLUMN TITLE "Cod"     DATA oQry:codpro SIZE 20 
   COLUMN TITLE "Usuario" DATA oQry:usuario SIZE 10 
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
RETURN NIL

*****************************************
** Cambiar Cantidad
STATIC FUNCTION CambiaCant(n)
LOCAL base := oQryHace:GetRowObj()

base:ptotal:= base:punit * n
base:cantidad := n 
oQryHace:oRow := base
oQryHace:Save()
oQryHace:Refresh()
oBrw2:Refresh()
oBrw2:Maketotals()
oGet[4]:cText:= oBrw2:aCols[5]:nTotal
oGet[4]:Refresh()
RETURN nil

**********************************************
** Reporte de Movimientos produccion
STATIC FUNCTION ReporteProd()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(13), oBot1 := ARRAY(5), oBot2,;
      oQryMar, oQryRub, oQryPro, oQryDep, oQryEmp, i, aRub, aMar, aPro, aDep, aEmp, oBrwMar, oBrwRub, oBrwPro, oBrwDep, oBrwEmp, cSql,;
      cMarca, cRubro, cProvee, cDepto, cEmpresa, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., lProv := .f., nTipo := 3,;
      oQryCli, nCliente := 0, cNomCli := "Todos"+SPACE(30), lPorFactura := .f.,;
      n, cTodos := "TODOS                  ", oQryVen
      
oQryMar:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas  ORDER BY nombre")
oQryPro:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"provee  ORDER BY nombre")
oQryDep:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos  ORDER BY nombre")  
oQryEmp:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas  ORDER BY nombre")  
oQryRub:= oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros  ORDER BY nombre")
aMar   := {}
DO WHILE !oQryMar:Eof()
   AADD(aMar,{.t.,oQryMar:Nombre, oQryMar:codigo})
   oQryMar:Skip()
ENDDO     
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
    DEFINE DIALOG oDlg1 TITLE "Produccion de articulo" FROM 03,15 TO 24,153
       acor := AcepCanc(oDlg1)    
       @ 05, 05 SAY "Marcas a Incluir" OF oDlg1 PIXEL
       @ 05, 80 BUTTON oBot1[1] PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
       @ 20, 05 XBROWSE oBrwMar SIZE 100,80 pixel OF oDlg1 ARRAY aMar ;
          HEADERS "Incluir", "Marca","Codigo";
          COLUMNS 1, 2 ,3;
          CELL LINES NOBORDER 
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
          CELL LINES NOBORDER  
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
          CELL LINES NOBORDER 
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
          CELL LINES NOBORDER  
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
          CELL LINES NOBORDER 
       WITH OBJECT oBrwEmp
          :nEdittYPEs := 1
          :aCols[ 1 ]:SetCheck()
          :aCols[ 2 ]:SetOrder()
          :CreateFromCode()
       END  
       PintaBrw(oBrwEmp,0)    
       
       @ 112, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
       @ 127, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT   
       @ 110, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
       @ 125, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
       @ 110,145 CHECKBOX oGet[3] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1 

       @ acor[1],acor[2] BUTTON oBot1[5] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT(oGet[1]:SetFocus())
    IF !mrta
       oQryMar:End()
       oQryRub:End()
       oQryPro:End()
       oQryDep:End() 
       RETURN nil
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
    oQryMar:End()
    oQryRub:End()
    oQryPro:End()
    oQryDep:End() 
    EXIT
ENDDO
IF !lResu
   cSql := "SELECT p.* FROM ge_"+oApp:cId+"produccion p "+;
           "LEFT JOIN ge_"+oApp:cId+"articu a ON p.codart = a.codigo "
   ELSE
   cSql := "SELECT p.codart as codart, p.detart as detart, SUM(p.cantidad) AS cantidad,  SUM(p.cantidad * p.precio) as precio "+;
           "  FROM ge_"+oApp:cId+"produccion p "   +;
           "LEFT JOIN ge_"+oApp:cId+"articu a ON p.codart = a.codigo "
ENDIF
cSql := cSql + " WHERE a.marca IN " + cMarca + " AND a.rubro IN " + cRubro + ;
            " AND a.prov IN " + cProvee + " AND a.depto IN "+cDepto + " AND a.empresa IN "+cEmpresa
cSql := cSql + " AND p.fecha >= "+ClipValue2Sql(mdesde) + " AND p.fecha <= " + ClipValue2Sql(mhasta)           
IF lResu
   cSql := cSql + " GROUP BY p.codart ORDER BY p.detart"
   ELSE
   cSql := cSql + " ORDER BY p.fecha"
ENDIF   
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Movimientos de stock por produccion del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Produccion" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Produccion"
IF !lResu   
   COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 9 FONT 1      
ENDIF   
COLUMN TITLE "Mat.Prima" DATA oQry:detart   SIZE 30 FONT 1
COLUMN TITLE "Codigo"    DATA oQry:codart   SIZE 13 FONT 1
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "9999999.99" ;
                            SIZE 10 FONT 2 TOTAL
IF !lResu                            
   COLUMN TITLE "Costo"     DATA oQry:precio PICTURE "9999999999.99" ;
                            SIZE 10 FONT 1
   COLUMN TITLE "Total"     DATA oQry:precio*oQry:cantidad PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL
   ELSE
   COLUMN TITLE "Total"     DATA oQry:precio PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL                             
ENDIF
IF !lResu
   COLUMN TITLE "Para"    DATA oQry:detalle SIZE 40 
   COLUMN TITLE "Cod"     DATA oQry:codpro SIZE 20 
   COLUMN TITLE "Usuario" DATA oQry:usuario SIZE 10 
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
RETURN NIL            

STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil  