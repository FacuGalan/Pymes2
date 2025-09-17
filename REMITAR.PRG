#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


************************************************************************************************
** REMITAR FACTURAS
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, lAcopio
PROCEDURE RemitarFactura() 
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oBot3, oDlg1, oFont, mnumfac, ;
      mrta := .f., aCor, base, marchi, mtotal, mdescp := 0, mdeuda := 0,;
      aTipo  := {"Factura","Nota de Credito"}, oQry,;
      aTip1  := {"FC","NC","ND","FR"}, mtipo := 1, mletra := IF(oApp:tipo_iva=1,"A","C"), mprefijo := oApp:prefijo,;
      mnumero := 0
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5      
DEFINE DIALOG oDlg1 TITLE "Remitar Factura" FROM 03,20 TO 19,70 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oDlg1)

   @ 05, 50 BUTTON oBot3 PROMPT "Buscar" OF oDlg1 PIXEL SIZE 30,12;
           ACTION(BuscarFactura(@mletra,@mprefijo,@mnumero,oDlg1,@mtipo),oGet1:Refresh(),oGet2:Refresh(),oGet3:Refresh(),oGet4:Refresh(),oBot1:SetFocus())

   
   @ 22, 05 SAY "Tipo Docum.:" OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 37, 05 SAY "Letra:"       OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 52, 05 SAY "Prefijo:"     OF oDlg1 PIXEL RIGHT SIZE 40,10
   @ 67, 05 SAY "Numero:"      OF oDlg1 PIXEL RIGHT SIZE 40,10
   
   @ 22, 50 COMBOBOX oGet1 VAR mtipo ITEMS aTipo OF oDlg1 SIZE 79,50 PIXEL
   @ 35, 50 GET      oGet2 VAR mletra PICTURE "@!" OF oDlg1 SIZE 20,10 PIXEL;
                     VALID(mletra$"ABCX")
   @ 50, 50 GET      oGet3 VAR mprefijo PICTURE "9999" OF oDlg1 PIXEL RIGHT
   @ 65, 50 GET      oGet4 VAR mnumero  PICTURE "99999999" OF oDlg1 PIXEL RIGHT
   @ 80, 05 SAY "Este proceso permite hacer remitos de Facturas ya realizadas. Los remitos no descontarán stock. "+;
                "Podrá controlar las unidades que lleva remitadas hasta el momento de la factura seleccionada. ";
                 OF oDlg1 PIXEL SIZE 190,40
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Remitar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mrta
   RETURN
ENDIF
oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = " + ClipValue2Sql(aTip1[mtipo]) + ;
                   " AND letra = " + ClipValue2Sql(mletra) + " AND numcomp = " + ;
                   ClipValue2Sql(STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0") ))
IF oQry:nRecCount = 0
   MsgStop("Factura no existe","Error")
   RETURN 
ENDIF
Remitar(oQry,aTip1[mtipo])
oQry:End()
RETURN 


STATIC FUNCTION Remitar(oQry,cTipo)
LOCAL oQryDet, oFont, oDlg1, oBrw, oBot1, oBot2, oGet := ARRAY(10), aCor, mrta := .f., cFactura,;
      cTipoDoc, cNumComp, oError, oQryStock, nIndice := IF(cTipo = "NC",-1,1)

lAcopio := oQry:acopio


oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS VENTAS_DET_H5 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(40) NOT NULL,";
    +"`CANTIDAD` DECIMAL(9,2) DEFAULT '0.00',";
    +"`REMITADAS` DECIMAL(9,2) DEFAULT '0.00',";
    +"`AREMITAR`  DECIMAL(9,2) DEFAULT '0.00',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUP`  DECIMAL(5,2) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`COSTO`  DECIMAL(12,3) DEFAULT '0.00',";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:Execute("TRUNCATE VENTAS_DET_H5")

oApp:oServer:Execute("INSERT INTO VENTAS_DET_H5 (codart,detart,cantidad,remitadas,aremitar,punit,neto,descuento,"+;
  "descup,stotal,iva,codiva,costo,ptotal) (SELECT codart,detart,SUM(cantidad),0.00,0.00,punit,neto,descu,"+;
  "descup,neton,iva,codiva,pcosto,importe "+;
  " FROM ge_"+oApp:cId+"ventas_det WHERE punit > 0 AND  nrofac = "+ClipValue2Sql(oQry:ticomp+oQry:letra+oQry:numcomp)+" GROUP BY codart) ")

oApp:oServer:Execute("UPDATE VENTAS_DET_H5 v LEFT JOIN  (SELECT codart,SUM(cantidad) as cantidad "+;  
  " FROM ge_"+oApp:cId+"remitos WHERE factura = "+ClipValue2Sql(oQry:ticomp+oQry:letra+oQry:numcomp) + "GROUP BY codart) res "+;
  " ON v.codart = res.codart SET v.remitadas = res.cantidad WHERE res.cantidad IS NOT NULL")
oApp:oServer:Execute("UPDATE VENTAS_DET_H5 SET aremitar = cantidad - remitadas ")

oQryDet :=oApp:oServer:Query("SELECT * FROM VENTAS_DET_H5")

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Listado de Articulos" FROM 03,15 TO 22,100
   acor := AcepCanc(oDlg1)    
   cFactura := oQry:ticomp+oQry:letra+oQry:numcomp
   @ 07, 05 SAY "Cliente:" OF oDlg1 PIXEL SIZE 40,12
   @ 22, 05 SAY "Factura:" OF oDlg1 PIXEL SIZE 40,12  
   @ 05, 50 GET oGet[1] VAR oQry:nombre OF oDlg1 PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[2] VAR cFactura OF oDlg1 PIXEL WHEN(.F.) 
   IF lAcopio
      @ 22, 150 SAY "FACTURA DE ACOPIO!!" OF oDlg1 PIXEL SIZE 80,12  COLOR CLR_RED,CLR_WHITE
   ENDIF
   @ 37, 05 XBROWSE oBrw SIZE 325,90 PIXEL OF oDlg1 DATASOURCE oQryDet ;
      HEADERS "Codigo", "Producto","Origen","Remitadas","A Remitar";
      COLUMNS "codart", "detart","cantidad","remitadas","ARemitar";
      SIZES 90, 250,90,90,90;
      PICTURE ,,"99999.99","99999.99","99999.99";
      FOOTERS;
      CELL LINES NOBORDER 
   WITH OBJECT oBrw
      :aCols[5]:nEditType := EDIT_GET  
      :aCols[3]:nFooterTypE := AGGR_SUM    
      :aCols[4]:nFooterTypE := AGGR_SUM    
      :aCols[5]:nFooterTypE := AGGR_SUM 
      :aCols[5]:bEditValid  := {| oGet | IF(VAL(oGet:cText) > oQryDet:cantidad - oQryDet:remitadas,;
                                           MsgStop("No puede remitar mas de lo facturado..","Atención")<>nil,.t. ) }   
      :CreateFromCode()
      :MakeTotals()
   END  
   PintaBrw(oBrw,0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Remitar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL WHEN(oBrw:aCols[5]:nTotal > 0)
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT IF(oBrw:aCols[5]:nTotal = 0, MsgInfo("Factura remitada por completo","Atencion"),nil)
IF !mrta
   RETURN  NIL
ENDIF
cTipoDoc:="RE"
cNumComp:= STRTRAN(STR(oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip)):caja,4)+;
          "-"+STR(oApp:oServer:Query("SELECT remito FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):remito+1,8)," ","0")  
TRY
  oApp:oServer:BeginTransaction()                     
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"remitos "+;
                        " (codart,detart,cantidad,fecha,codcli,nrorem,codiva,facturado,incrp,importe,iva,neto,neton,tipo,auto,vendedor,factura) "+;
                        " (SELECT codart,detart,aremitar,CURDATE(),"+ClipValue2Sql(oQry:codcli)+","+;
                        + ClipValue2Sql(cTipoDoc+cNumComp)+",codiva,TRUE,0,0,0,0,0, "+;
                        "'I',0,"+ClipValue2Sql(oApp:usuario)+","+ClipValue2Sql(cFactura)+;
                        "   FROM VENTAS_DET_H5 WHERE aremitar > 0 )")
  IF lAcopio 
     //Actualizo el stock si la factura era de acopio     
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
               "INNER JOIN "+; 
               "("+; 
               "SELECT codart, SUM(aremitar) as suma "+;
               "FROM VENTAS_DET_H5 "+;
               "GROUP BY codart "+;
               ") v ON a.codigo = v.codart "+;
               "SET a.stockact = a.stockact - (v.suma * "+STR(nIndice)+") WHERE a.stockotro IS FALSE")

      // Actualizo el stock de los que descuentan de otros articulos
      oQryStock:= oApp:oServer:Query("SELECT SUM(d.aremitar)  AS cantidad,"+;
                                     "d.codart AS codart FROM VENTAS_DET_H5 d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE a.stockotro = TRUE GROUP BY d.codart")
      oQryStock:GoTop()
      DO WHILE !oQryStock:EOF()
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                              " ON m.codigo = r.codusa "+;
                              "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad * "+STR(nIndice)+") "+;
                              "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
         oQryStock:Skip()
      ENDDO
  ENDIF   

  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET remito = remito + 1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
  oApp:oServer:CommitTransaction()  
CATCH oError
   ValidaError(oError)
END TRY
oQryDet := oApp:oServer:Query("SELECT *, 0 as bultos, 0 as promo FROM ge_"+oApp:cId+"remitos WHERE nrorem="+ClipValue2Sql(cTipoDoc+cNumComp))
PrintRemito(oQryDet,,, cNumComp,oQry:codcli,cFactura)
RETURN nil 