#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** TRANSFORMACION DE ARTICULOS
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot,nCodArtP,oQryRes,oQryHace,;
       oBrw1, oBrw2, oQry, oQryArtP,nHacer,oSay1
PROCEDURE PRODUCC(cPermisos)
LOCAL oFont, oFo1, cNomArt:=SPACE(30),  mobserva, Lrta := .f., aObserva := {},oFontTotal,;
      nCosto:=0,nValor:=0,oError
oGet := ARRAY(12)
oBot := ARRAY(07)
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
              COLUMNS "CODART","DETART","CANTIDAD","PUNIT","PTOTAL";
              HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total";
              FOOTERS ;
              SIZES 80,281,60,80,80 ID 301 OF oDlg 
    PintaBrw(oBrw2,0)
    oBrw2:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw2:aCols[3]:nEditType := 1
    oBrw2:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,)}     
    oBrw2:MakeTotals()

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

  TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE reseta_temp1 r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                       "SET a.stockact = a.stockact - r.cantidad ")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET stockact = stockact + "+ClipValue2Sql(nHacer)+" "+;
                       "WHERE codigo = " + ClipValue2Sql(oQryArtP:codigo))
  //Agrego al movimiento de stock el ingreso
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"stoman (codart,entradas,salidas,fecha,motivo,costo) VALUES "+;
                       "("+ClipValue2Sql(oQryArtP:codigo)+","+;
                       ClipValue2Sql(nHacer)+","+;
                       "0,"+;
                       "CURDATE(),"+;
                       "9,"+;
                       ClipValue2Sql(oQryArtP:preciocos)+;
                       ")") 
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"stoman (codart,entradas,salidas,fecha,motivo,costo) "+;
                       "(SELECT codart,0,cantidad,CURDATE(),9,punit FROM reseta_temp1) ")  
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
      +"PRIMARY KEY (`ID`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
  ENDIF    
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"produccion (fecha,codart,detart, detalle,cantidad,precio,codpro) "+;
                       "(SELECT curdate(),codart,detart,'Produccion "+ALLTRIM(cNomArt)+" x "+;
                       ALLTRIM(STR(nHacer,12,2))+"',cantidad,punit,"+ClipValue2Sql(nCodArtP)+" FROM reseta_temp1) ")  
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
oApp:oServer:Execute("INSERT INTO reseta_temp1 (codart,detart,cantidad,punit,ptotal) "+;
                     "(SELECT r.codusa,a.nombre,r.cantidad*"+ClipValue2Sql(nMultiplica)+;
                     ",a.preciocos,r.cantidad*a.preciocos*"+ClipValue2Sql(nMultiplica)+" "+;
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
STATIC FUNCTION ReporteProd()
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
   COLUMN TITLE "Para"   DATA oQry:detalle SIZE 40 
   COLUMN TITLE "Cod"    DATA oQry:codpro SIZE 20 
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