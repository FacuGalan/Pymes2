#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
************************************************************************************************
** Compras
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, oBrw, oDlg, cVentana,oQry, oQryBrw,nIvaArt, nCant,oQryIvaDet,oBrwIvas,oBrwRet, ;
       oQryComprasDet, oQryCue, oQryPro, oQryArt,  oQryIva, oQryTip, oQryRet, oQryCom, oGet, oBot, base, baseDet,;
       oQry2,oQry3,oQry4,oQry5,oQry6,oQry7
PROCEDURE Compras(cPermisos) 
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQryBrw    := oApp:oServer:Query( "SELECT c.tipocomp,c.letra,c.numfac,c.fecfac,c.importe,"+;
                                  "c.estado,c.observa,p.nombre AS nompro,c.codpro "+;
                                  "FROM compras c LEFT JOIN provee p ON p.codigo = c.codpro "+;
                                  "ORDER BY c.fecfac")
  

  oQryIva := oApp:oServer:Query("SELECT * FROM ivas      ORDER BY codigo")
  oQryCue := oApp:oServer:Query("SELECT * FROM plancont")
  oQry2  := oApp:oServer:Query( "SELECT * FROM provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT * FROM ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT * FROM marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT * FROM rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT * FROM deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT * FROM empresas ORDER BY codigo")


 DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Compras" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Compras",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .and. "R"$cPermisos)
        DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Registros"  ;
            ACTION (Filt(), oBrw:Refresh());
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "tipocomp","letra","numfac","fecfac","nompro","importe","estado","observa";
              HEADERS "Tipo","Letra","Numero","Fecha","Proveedor","Importe","Estado","Obsevaciones";
              SIZES 40,30,110,80,200,100,55,50;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu( .f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[7]:bStrData := {|| IF(oQryBrw:RecCount()> 0 .and. oQryBrw:estado="I","IMPAGA","PAGA")}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


STATIC FUNCTION Formu(lAlta)
LOCAL oGet:=ARRAY(45),oBot:=ARRAY(6),oFontTotal, lRta := .f., aTipoDoc, nTipoComp, nBultos:=0,;
      cNomPro,  cCuit, cConIva, cNomCue, nDeuda, nCodArt, cDetArt, nCantidad, oError, ;
      nPunit, nPTotal, cNomRet1, cNomRet2, cNomRet3, cNomRet4, cNomRet5, oDlg1, oQryDoc,nRenglon,;
      nSaldoIni:=0, nImporteIni:=0
  
  //TABLA TEMPORAL PARA EL DETALLE DE LA COMPRA
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS comprasdet_H ";
    +"("; 
    +"`RENGLON` INT(2) NOT NULL AUTO_INCREMENT,";
    +"`CODPRO` INT(8) NOT NULL,";
    +"`TIPOCOMP`  VARCHAR(2) NOT NULL,";
    +"`LETRA`  VARCHAR(1) NOT NULL,";
    +"`NUMFAC` VARCHAR(13) NOT NULL,";
    +"`CODART` BIGINT(14) NOT NULL,";
    +"`DETART`  VARCHAR(50) NOT NULL,";
    +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0',";
    +"`PCOSTO` DECIMAL(12,2) DEFAULT '0.00',";
    +"`NETO` DECIMAL(12,2) DEFAULT '0.00',";
    +"`IVA` DECIMAL(12,2) DEFAULT '0.00',";
    +"`CODIVA` DECIMAL(2) DEFAULT '0.00',";
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")   
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE comprasdet_H")
  oApp:oServer:NextResult()
  
  //TABLA TEMPORAL PARA LOS MONTOS DE LOS IVAS
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS ivas_temp ";
    +"("; 
    +"`CODIGO` INT(2) NOT NULL,";
    +"`NOMBRE` VARCHAR(25) NOT NULL,";
    +"`TASA` DECIMAL(5,2) DEFAULT '0.00',";
    +"`NETO` DECIMAL(12,2) DEFAULT '0.00',";
    +"`IVA` DECIMAL(12,2) DEFAULT '0.00',";
    +" PRIMARY KEY (CODIGO)) ENGINE=INNODB DEFAULT CHARSET=utf8")   
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE ivas_temp")
  oApp:oServer:NextResult()

  oApp:oServer:Execute("INSERT INTO ivas_temp (CODIGO,NOMBRE,TASA,NETO,IVA) "+;
  	                   "(SELECT codigo,nombre,tasa,0,0 FROM ivas)")
  oQryIvaDet:= oApp:oServer:Query("SELECT * FROM ivas_temp ORDER BY nombre ")
  
  //TABLA TEMPORAL PARA LOS MONTOS DE LAS RETENCIONES
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reten_temp ";
    +"("; 
    +"`CODIGO` INT(2) NOT NULL,";
    +"`NOMBRE` VARCHAR(25) NOT NULL,";
    +"`IMPORTE` DECIMAL(12,3) DEFAULT '0.00',";
    +" PRIMARY KEY (CODIGO)) ENGINE=INNODB DEFAULT CHARSET=utf8")   
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE reten_temp")
  oApp:oServer:NextResult()

  oApp:oServer:Execute("INSERT INTO reten_temp (CODIGO,NOMBRE,IMPORTE) "+;
  	                   "(SELECT codigo,nombre,0 FROM retencio)")
  oQryRet:= oApp:oServer:Query("SELECT * FROM reten_temp")
  
  oQryArt := oApp:oServer:Query("SELECT * FROM articu    ORDER BY codigo")
  oQryTip := oApp:oServer:Query("SELECT * FROM tipocomp  ORDER BY codigo")
  oQryCom := oApp:oServer:Query("SELECT * FROM Compras   LIMIT 0")
  aTipoDoc:={"Factura","Nota de credito","Nota de debito","Presupuesto","Remito"} 
        
  aTipoDoc:={"Factura","Nota de credito","Nota de debito","Presupuesto","Remito"}
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
  IF lAlta
    oQry    := oApp:oServer:Query( "SELECT * FROM compras LIMIT 0")
    base    := oQry:GetBlankRow()
    base:fecfac:= DATE()
    base:fecing:= DATE()
    base:imputaiva := .t.
    base:estado := "I"
    nTipoComp:= 1
    base:numfac:= "    -        "
    base:usuario:= oApp:usuario 
  ELSE
    oQry    := oApp:oServer:Query( "SELECT * FROM compras WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac))
    base:= oQry:GetRowObj() 
    nSaldoIni:= base:saldo
    nImporteIni:= base:importe
    DO CASE
       CASE base:tipocomp = "FC"
           nTipoComp = 1
       CASE base:tipocomp = "NC"
           nTipoComp = 2
       CASE base:tipocomp = "ND"
           nTipoComp = 3
       CASE base:tipocomp = "PR"
           nTipoComp = 4
       CASE base:tipocomp = "RE"
           nTipoComp = 5
    ENDCASE
    oApp:oServer:Execute("INSERT INTO comprasdet_H (renglon,codpro,tipocomp,letra,numfac,codart,detart,cantidad,ptotal,pcosto,neto,iva,codiva)"+;
                       "SELECT c.renglon,c.codpro,c.tipocomp,c.letra,c.numfac,c.codart,a.nombre,c.cantidad,c.cantidad*c.pcosto,c.pcosto,c.cantidad*c.pcosto,c.iva,c.codiva FROM compradet c "+;
                       "LEFT JOIN articu a ON a.codigo = c.codart "+;
                       "WHERE tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(base:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac))
    oApp:oServer:Execute("UPDATE ivas_temp it LEFT JOIN compivadet id ON it.codigo = id.codiva AND "+;
    	                 "id.tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                         "AND id.letra = " + ClipValue2Sql(base:letra)+" "+;
                         "AND id.codpro = " + ClipValue2Sql(base:codpro)+" "+;
                         "AND id.numfac = " + ClipValue2Sql(base:numfac)+" "+;
                         "SET it.neto = id.neto, it.iva = id.iva ")
    oQryIvaDet:Refresh()
    oApp:oServer:Execute("UPDATE reten_temp rt LEFT JOIN compretdet rd ON rt.codigo = rd.codret AND "+;
    	                 "rd.tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                         "AND rd.letra = " + ClipValue2Sql(base:letra)+" "+;
                         "AND rd.codpro = " + ClipValue2Sql(base:codpro)+" "+;
                         "AND rd.numfac = " + ClipValue2Sql(base:numfac)+" "+;
                         "SET rt.importe = rd.importe ")
    oQryRet:Refresh()
  ENDIF
  
  oQryComprasDet :=oApp:oServer:Query("SELECT * FROM comprasdet_H")
  baseDet := oQryComprasDet:GetBlankRow()
  DO WHILE .T.
    DEFINE DIALOG oDlg1 RESOURCE "COMPRAS" OF oWnd1
    oDlg1:lHelpIcon := .f.
    REDEFINE COMBOBOX oGet[01] VAR nTipoComp ITEMS aTipoDoc ID 110 OF oDlg1 WHEN(lAlta)      
    REDEFINE GET oGet[02] VAR base:letra   ID 111  OF oDlg1 VALID( base:letra $ "ABC RMX") WHEN(lAlta)
    REDEFINE GET oGet[03] VAR base:numfac  ID 112 OF oDlg1 PICTURE "9999-99999999" WHEN(lAlta);
                 VALID(base:numfac <> "    -        ")
    REDEFINE GET oGet[04] VAR oApp:usuario ID 113 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[05] VAR base:fecfac  ID 114 OF oDlg1
    REDEFINE GET oGet[06] VAR base:fecing  ID 115 OF oDlg1  
    REDEFINE GET oGet[07] VAR base:codpro  ID 116 OF oDlg1 PICTURE "99999999" WHEN(lAlta);
                 VALID(ValidaPro(oGet,lAlta,oDlg1));
                 ACTION (oGet[07]:cText:= 0, ValidaPro(oGet,lAlta,oDlg1)) BITMAP "BUSC1"
    REDEFINE GET oGet[08] VAR cNomPro      ID 117 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[09] VAR cCuit        ID 118 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[10] VAR cConIva      ID 119 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[11] VAR base:codcue  ID 120 OF oDlg1;
                VALID(Buscar(oQryCue,oDlg1,oGet[11],oGet[12]));
                ACTION (oGet[11]:cText:= 0, Buscar(oQryCue,oDlg1,oGet[11],oGet[12])) BITMAP "BUSC1"
    REDEFINE GET oGet[12] VAR cNomCue      ID 121 OF oDlg1 WHEN(.F.)            
    REDEFINE GET oGet[13] VAR nDeuda       ID 122 OF oDlg1 WHEN(.F.) PICTURE "999999999.99"
    REDEFINE CHECKBOX oGet[14] VAR base:imputaiva   ID 123 OF oDlg1 
    REDEFINE GET oGet[16] VAR base:observa    ID 125 OF oDlg1 PICTURE "@!"
    REDEFINE GET oGet[17] VAR baseDet:codart  ID 126 OF oDlg1; 
                 VALID(ValidaArt(oDlg1,oGet));
                 ACTION (oGet[17]:cText:= -1, ValidaArt(oDlg1,oGet)) BITMAP "BUSC1" PICTURE "999999999999999"
    REDEFINE GET oGet[18] VAR basedet:detart  ID 127 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[19] VAR basedet:cantidad ID 128 OF oDlg1 PICTURE "9999999.99"
    REDEFINE GET oGet[20] VAR basedet:pcosto   ID 129 OF oDlg1 PICTURE "999999999.99"
    REDEFINE GET oGet[21] VAR basedet:ptotal   ID 130 OF oDlg1 PICTURE "999999999.99";
                 WHEN((oGet[21]:cText := basedet:cantidad * basedet:pcosto) = "-1")
    REDEFINE BUTTON oBot[1] ID 131 OF oDlg1 ACTION(AgregarItem(oGet,nTipoComp),oBrw:MakeTotals(),;
                                                               oQryComprasDet:GetBlankRow(),;
                                                               CalcTot(oGet,.T.),oBot[1]:oJump := oGet[17])

    //GRILLA ---------------------------------------------------------------      
    REDEFINE XBROWSE oBrw DATASOURCE oQryComprasDet;
       COLUMNS "CODART","DETART","CANTIDAD","PCOSTO", "PTOTAL","NETO","IVA";
       HEADERS "Codigo","Articulo","Cantidad","Precio U", "Importe","Neto","I.V.A";
       FOOTERS ;
       SIZES 60,303,80,80,80,80,80;
       ID 132 OF oDlg1 
    PintaBrw(oBrw,0)

    oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,(oGet[17]:nLastkey:=11,oBot[3]:Click),.t.) }
    oBrw:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(oQryComprasDet:lAppend := .f., oQryComprasDet:Delete(),oBrw:MakeTotals(),oBrw:Refresh()),.t.) }
    oBrw:aCols[3]:nFooterTypE := AGGR_SUM
    oBrw:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw:MakeTotals()

    //DETALLE DE IVAS --------------------------------------------------------
    REDEFINE XBROWSE oBrwIvas DATASOURCE oQryIvaDet;
    	COLUMNS "CODIGO","NOMBRE","NETO","IVA";
    	HEADERS "Codigo","Nombre","Neto","Iva";
    	FOOTERS;
    	SIZES 40,87,80,80 ID 400 OF oDlg1
    PintaBrw(oBrwIvas,0)
    oBrwIvas:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwIvas:aCols[4]:nFooterTypE := AGGR_SUM
    oBrwIvas:aCols[3]:lAutoSave := .t.
    oBrwIvas:nMoveType := 4
    oBrwIvas:aCols[3]:nEditType := EDIT_GET
    oBrwIvas:aCols[3]:bOnChange := {|| CalcTot(oGet,.F.)}
    oBrwIvas:aCols[4]:lAutoSave := .t.
    oBrwIvas:aCols[4]:nEditType := EDIT_GET
    oBrwIvas:aCols[4]:bOnChange := {|| CalcTot(oGet,.F.)}
    oBrwIvas:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | (oQryIvaDet:neto:= xVal,oQryIvaDet:iva:= xVal * oQryIvaDet:tasa/100,oQryIvaDet:Save()) }
    oBrwIvas:MakeTotals()

    //DETALLE DE RETENCIONES --------------------------------------------------------
    REDEFINE XBROWSE oBrwRet DATASOURCE oQryRet;
    	COLUMNS "CODIGO","NOMBRE","IMPORTE";
    	HEADERS "Codigo","Nombre","Importe";
    	FOOTERS;
    	SIZES 40,113,90 ID 401 OF oDlg1
    PintaBrw(oBrwRet,0)
    oBrwRet:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwRet:aCols[3]:lAutoSave := .t.
    oBrwRet:nMoveType := 4
    oBrwRet:aCols[3]:nEditType := EDIT_GET
    oBrwRet:aCols[3]:bOnChange := {|| CalcTot(oGet,.F.)}
   
   
    // No Grabado
    REDEFINE GET oGet[41] VAR base:nograbado  ID 152 OF oDlg1 PICTURE "9999999999.99"
    oGet[41]:bLostFocus:= { || (oGet[41]:Assign(), CalcTot(oGet,.F.))}

        REDEFINE GET oGet[42] VAR base:importe    ID 300 OF oDlg1 FONT oFontTotal COLOR CLR_RED,CLR_WHITE PICTURE "9999999999.99";
        
    //BOTONES ---------------------------------------------------------------
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg1 ACTION(Cancela())    
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg1 ACTION(lRta:=.t.,oDlg1:End()) WHEN(base:importe>0)    
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg1 ACTION(lRta:=.f.,oDlg1:End()) CANCEL    
    REDEFINE BUTTON oBot[5] ID 105 OF oDlg1 ACTION(FormuArt(oDlg1))      
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg1 CENTER ON INIT IF(!lAlta,ValidaPro(oGet,lAlta,oDlg1),.f.) 

IF !lRta
   RETURN nil
ENDIF

IF nSaldoIni = nImporteIni
   base:saldo:= base:importe
ENDIF


IF lAlta
   oQry:GetBlankRow()
ELSE
   IF nImporteIni <> base:importe
     msginfo(nImporteIni)
     msginfo(base:importe)
     lRta:= MsgNoYes("Ya se realizo un pago por este comprobante,"+CHR(10)+;
                    "el saldo no se modificara, ¿desea grabar los cambios de todas formas?","Atencion!")
   ENDIF
   IF !lRta
      RETURN nil
   ENDIF
   oApp:oServer:Execute("DELETE FROM compradet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac)) 
ENDIF

oQryDoc := oApp:oServer:Query("SELECT * FROM tipocomp WHERE codigo = " + ClipValue2Sql(nTipoComp))
base:tipocomp:= oQryDoc:prefijo
base:neto := oBrwIvas:aCols[3]:nTotal
base:iva  := oBrwIvas:aCols[4]:nTotal
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()    
  oQry:Save()
  oApp:oServer:Execute("DELETE FROM compradet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac))
  oApp:oServer:Execute("INSERT INTO compradet  (renglon,codpro,tipocomp,letra,numfac,codart,cantidad,pcosto,iva,codiva) "+;
                       "SELECT renglon,codpro,tipocomp,letra,numfac,codart,cantidad,pcosto,iva,codiva "+;
                       "FROM comprasdet_H ")
  oApp:oServer:NextResult()
  oApp:oServer:Execute("DELETE FROM compivadet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac))
  oApp:oServer:Execute("INSERT INTO compivadet (codpro,tipocomp,letra,numfac,codiva,neto,iva) "+;
                       "(SELECT "+ClipValue2SQL(base:codpro)+","+ClipValue2Sql(oQryDoc:prefijo)+","+ClipValue2SQL(base:letra)+","+;
                       ClipValue2SQL(base:numfac)+",codigo,neto,iva "+;
                       "FROM ivas_temp WHERE neto > 0) ")
  oApp:oServer:Execute("DELETE FROM compretdet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac))
  oApp:oServer:NextResult()
  oApp:oServer:Execute("INSERT INTO compretdet (codpro,tipocomp,letra,numfac,codret,importe) "+;
                       "(SELECT "+ClipValue2SQL(base:codpro)+","+ClipValue2Sql(oQryDoc:prefijo)+","+ClipValue2SQL(base:letra)+","+;
                       ClipValue2SQL(base:numfac)+",codigo,importe "+;
                       "FROM reten_temp WHERE importe > 0) ")
  oQryBrw:Refresh(.f.)
  oApp:oServer:CommitTransaction()
CATCH oError
    MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

**********************************************************************************************
***** CALCULAR IMPORTE FINAL
STATIC FUNCTION CalcTot(oGet,lCalcular)
IF lCalcular
oQryComprasDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE ivas_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("INSERT INTO ivas_temp (codigo,nombre,tasa,neto,iva) "+;
                       "(SELECT i.codigo,i.nombre,i.tasa,SUM(c.neto), "+;
                       "SUM(c.iva) FROM ivas i "+;
                       "LEFT JOIN comprasdet_H c ON i.codigo = c.codiva GROUP BY i.codigo)")
oApp:oServer:NextResult()
oQryIvaDet:Refresh(.t.)
oBrwIvas:Refresh()
ENDIF
oBrwRet:MakeTotals()
oBrwIvas:MakeTotals()
oGet[42]:cText:= oBrwIvas:aCols[3]:nTotal + oBrwIvas:aCols[4]:nTotal +  oBrwRet:aCols[3]:nTotal + base:nograbado
                       
oGet[42]:Refresh()
RETURN .t.

**********************************************************************************************
STATIC FUNCTION ValidaArt(oDlg1,oGet)
   IF baseDet:codart <> 0
    oQryArt := oApp:oServer:Query("SELECT a.*, i.nombre AS cNomIva, i.tasa AS tasaiva, a.iva AS codiva FROM articu a "+;
                                  "LEFT JOIN ivas i ON a.iva = i.codigo "+;
                                  "WHERE a.codigo = " + ClipValue2SQL(oGet[17]:value))
    IF oQryArt:RecCount()=0
       BUSCAR(oQryArt,oDlg1,oGet[17],oGet[18])
    ENDIF
    nIvaArt:= oQryArt:iva
    nCant:= 1
    oGet[18]:cText:= oQryArt:nombre
    oGet[19]:cText:= 1
    oGet[20]:cText:= oQryArt:preciocos
   ELSE
    oGet[18]:cText:= "---------------------------------------------------------------------------------------------------------------------------------------"
    oGet[41]:SetFocus()
   ENDIF
   oQryArt:SetNewFilter(SET_WHERE,"true",.t.)
RETURN .t.

**********************************************************************************************

STATIC FUNCTION AgregarItem(oGet,nTipoComp)
LOCAL oQryDoc 
  IF basedet:codart > 0 
   oQryDoc := oApp:oServer:Query("SELECT * FROM tipocomp WHERE codigo = " + ClipValue2Sql(nTipoComp))
   basedet:renglon:=oApp:oServer:GetAutoIncrement("comprasdet_H")
   basedet:codpro:= base:codpro
   basedet:tipocomp:= oQryDoc:prefijo
   basedet:codpro:= base:codpro
   basedet:numfac:= base:numfac
   basedet:letra:= base:letra
   basedet:neto:=basedet:ptotal
   basedet:codiva := oApp:oServer:Query("SELECT iva FROM articu WHERE codigo = "+ClipValue2Sql(basedet:codart)):iva
   basedet:iva := basedet:ptotal * oApp:oServer:Query("SELECT tasa FROM ivas WHERE codigo = "+ClipValue2Sql(basedet:codiva)):tasa/100
   oQryComprasDet:oRow := basedet 
   oQryComprasDet:Save()
   oQryComprasDet:Refresh(.t.)
   oBrw:Refresh()
  ENDIF 
   oGet[17]:SetFocus()
RETURN .T.

                            
******************************************************************************************************

STATIC FUNCTION ValidaPro(oGet,lAlta,oDlg1)
   LOCAL oQryDeu
   oQryPro := oApp:oServer:Query("SELECT codigo,nombre,localidad,cuit,coniva,codcue  FROM provee")
   BUSCAR(oQryPro,oDlg1,oGet[07],oGet[08])
   oQryPro := oApp:oServer:Query("SELECT codigo,nombre,localidad,cuit,coniva,codcue FROM provee  WHERE codigo = " + ClipValue2SQL(base:codpro))
   oQryIva := oApp:oServer:Query("SELECT * FROM tipoiva   WHERE codigo = " + ClipValue2SQL(oQryPro:coniva))   
   oGet[09]:cText:= oQryPro:cuit
   oGet[10]:cText:= oQryIva:nombre
   IF lAlta 
   oQryCue := oApp:oServer:Query("SELECT * FROM plancont WHERE codigo = " + ClipValue2SQL(oQryPro:codcue))
    oGet[11]:cText:= oQryPro:codcue
    oGet[12]:cText:= oQryCue:nombre
   ELSE
   oQryCue := oApp:oServer:Query("SELECT * FROM plancont WHERE codigo = " + ClipValue2SQL(oGet[11]:Value))
     oGet[12]:cText:= oQryCue:nombre
   ENDIF
   oQryDeu := oApp:oServer:Query("SELECT SUM(importe) AS deuda FROM compras WHERE codpro = " + ClipValue2Sql(base:codpro) +;
                                 " AND estado = 'I' ")
   oGet[13]:cText:= oQryDeu:deuda  
   oQryPro:End()
   RELEASE oQryPro
RETURN .t.



**********************************************************************************************

STATIC FUNCTION Cancela()
  oQryComprasDet:ZAP()
  baseDet := oQryComprasDet:GetBlankRow()
  oBrw:Refresh()
  oGet[17]:cText:= 0
  oGet[18]:cText:= ""
  oGet[19]:cText:= 0.00
  oGet[20]:cText:= 0.00
  oGet[21]:cText:= 0.00
  oGet[22]:cText:= 0.00
  oGet[23]:cText:= 0.00
  oGet[24]:cText:= 0.00
  oGet[25]:cText:= 0.00
  oGet[26]:cText:= 0
  oGet[27]:cText:= ""
  oGet[28]:cText:= 0.00
  oGet[29]:cText:= 0
  oGet[30]:cText:= ""
  oGet[31]:cText:= 0.00
  oGet[32]:cText:= 0
  oGet[33]:cText:= ""
  oGet[34]:cText:= 0.00
  oGet[35]:cText:= 0
  oGet[36]:cText:= ""
  oGet[37]:cText:= 0.00
  oGet[38]:cText:= 0
  oGet[39]:cText:= ""
  oGet[40]:cText:= 0.00
  oGet[41]:cText:= 0.00
  oGet[42]:cText:= 0.00
  oGet[17]:SetFocus()
RETURN NIL  

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
LOCAL aNueva := {}, i, j
IF oQry<> nil
   oQry:End()
   RELEASE oQry
ENDIF
oQryBrw:End()
RELEASE oQryBrw
oQryIva:End()
RELEASE oQryIva
oQryCue:End()
RELEASE oQryCue

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
LOCAL mrta := .f., oError

mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el documento Numero "+oQryBrw:letra+" "+oQryBrw:numfac,"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM compras WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro))
   oApp:oServer:Execute("DELETE FROM compradet WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac))                    
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)
CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
RETURN nil 


*************************************
** Agregar un registro nuevo
STATIC FUNCTION FormuArt (oDlg1)
LOCAL oGet := ARRAY(50), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oGru, cProve:=SPACE(30), nNeto,;
      cIvaNom:=SPACE(30), cMarc:=SPACE(30), cRub:=SPACE(30), cDept:=SPACE(30), cEmp:=SPACE(30), nIva,oError,nPrecioven:=0,;
      nova1,nova2,oSay1,oSay2


   oQry:= oApp:oServer:Query("SELECT * FROM articu LIMIT 0")
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("articu")

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Alta de Articulo" RESOURCE "ABMART1" OF oDlg1
 oForm:lHelpIcon := .f.
 
 REDEFINE GET oGet[01] VAR base:codigo PICTURE "99999999999999" ID 100 OF oForm 
  REDEFINE GET oGet[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!" 
  REDEFINE CHECKBOX oGet[46] VAR base:pesable ID 4011 OF oForm 
  REDEFINE CHECKBOX oGet[34] VAR base:nosale ID 103 OF oForm 
  REDEFINE CHECKBOX oGet[43] VAR base:combustible ID 4005 OF oForm
  REDEFINE CHECKBOX oGet[44] VAR base:mprima      ID 4007 OF oForm
  REDEFINE CHECKBOX oGet[45] VAR base:produccion  ID 4008 OF oForm
  REDEFINE CHECKBOX oGet[46] VAR base:endolares   ID 4012 OF oForm

  REDEFINE GET oGet[04] VAR base:prov ID 104 OF oForm PICTURE "99999";
                VALID(Buscar(oQry2,oForm,oGet[4],oGet[5]));
                ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oForm,oGet[4],oGet[5])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oForm WHEN (.F.)
  REDEFINE GET oGet[21] VAR base:marca      ID 122 OF oForm PICTURE "999";
               VALID(Buscar(oQry4,oForm,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oForm,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc           ID 123 OF oForm WHEN (.F.)
  REDEFINE GET oGet[23] VAR base:rubro      ID 124 OF oForm PICTURE "999";
               VALID(Buscar(oQry5,oForm,oGet[23],oGet[24]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oForm,oGet[23],oGet[24])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub            ID 125 OF oForm WHEN (.F.)
  REDEFINE GET oGet[27] VAR base:empresa    ID 126 OF oForm PICTURE "999";
               VALID(Buscar(oQry7,oForm,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oForm,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp            ID 127 OF oForm WHEN (.F.)
  REDEFINE GET oGet[25] VAR base:depto      ID 128 OF oForm PICTURE "999";
               VALID(Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept           ID 129 OF oForm WHEN (.F.)

  REDEFINE GET oGet[35] VAR base:unimed     ID 135 OF oForm PICTURE "@!"
  REDEFINE GET oGet[47] VAR base:medida     ID 500 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[48] VAR base:entero     ID 501 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[49] VAR base:uxbulto    ID 502 OF oForm PICTURE "99999"
  REDEFINE GET oGet[50] VAR base:pxbulto    ID 503 OF oForm PICTURE "999999999.99";
               VALID((oGet[06]:cText:= (base:pxbulto/base:uxbulto)) <> "xxx")


  REDEFINE CHECKBOX oGet[46] VAR base:siniva  ID 4003 OF oForm
  REDEFINE GET oGet[06] VAR base:precossiva ID 106 OF oForm PICTURE "999999999.99" 
  REDEFINE GET oGet[07] VAR base:desc1      ID 107 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[08] VAR base:desc2      ID 108 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[09] VAR base:desc3      ID 109 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[10] VAR base:desc4      ID 110 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[11] VAR base:desc5      ID 111 OF oForm PICTURE "999.99"  
  REDEFINE GET oGet[39] VAR nNeto           ID 112 OF oForm PICTURE "999999999.99";
                 WHEN((oGet[39]:cText:= base:precossiva - (base:precossiva * base:desc1)/100 - ;
                 (base:precossiva * base:desc2)/100 - (base:precossiva * base:desc3)/100 - ;
                 (base:precossiva * base:desc4)/100 - (base:precossiva * base:desc5)/100) = "-99999999")
  REDEFINE GET oGet[12] VAR base:impint     ID 113 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[13] VAR base:flete      ID 114 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[14] VAR base:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet[14]:cText:= 0, (Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
  REDEFINE GET oGet[16] VAR base:preciocos  ID 117 OF oForm PICTURE "999999999.99";
                        WHEN((oGet[16]:cText:= nNeto + (base:precossiva * base:impint)/100 +;
                        (base:precossiva * base:flete)/100 + IF(base:siniva,((base:precossiva * oQry3:tasa )/100),0)) = "-999999")
  REDEFINE GET oGet[17] VAR base:porcentaje ID 118 OF oForm PICTURE "99999.99";
               VALID(CalcularPrecio(oGet,base))
  REDEFINE GET oGet[18] VAR base:preciopro  ID 119 OF oForm PICTURE "999999999.99" WHEN(.F.)
  REDEFINE GET oGet[19] VAR base:reventa    ID 120 OF oForm PICTURE "999999999.99"
  REDEFINE GET oGet[20] VAR base:precioven  ID 121 OF oForm PICTURE "999999999.99"
  
  
    //FECHAS
  REDEFINE SAY oSay1 ID 801 OF oForm 
  REDEFINE GET oGet[41] VAR nova1          ID 1300 OF oForm
  REDEFINE GET oGet[29] VAR base:fecultcom ID 130 OF oForm WHEN(.F.)
  REDEFINE GET oGet[30] VAR base:fecmod    ID 131 OF oForm WHEN (.F.)
  REDEFINE SAY oSay2 ID 804 OF oForm
  REDEFINE GET oGet[42] VAR nova2          ID 1311 OF oForm


  REDEFINE GET oGet[31] VAR base:stockmin   ID 132 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[33] VAR base:stockide   ID 134 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[36] VAR base:observa    ID 136 OF oForm PICTURE "@!"

  REDEFINE BUTTON oBot[1] ID 137 OF oForm PROMPT "&Grabar";
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
  REDEFINE BUTTON oBot[3] ID 4009 OF oForm ACTION Reseta(base,oForm) WHEN (base:produccion)
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet[01]:SetFocus(),oGet[41]:Hide(),oGet[42]:Hide(),;
                                                          oSay1:Hide(),oSay2:Hide())
IF !lRta
   RETURN nil
ENDIF
IF base:preciocos = 0 .or. base:iva = 0
   msginfo("Campos obligatorios como 'Precio costo' e 'IVA' tienen que estar completos","Atencion!")
   LOOP
ENDIF

IF base:precioven <> nPrecioven
      base:fecmod := DATE()
ENDIF  
base:porcentaje := (base:precioven * 100) / base:preciocos - 100
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh()
  oQryBrw:Refresh(.f.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


*************************************************************************************************************
********* Modificar reseta del articulo 
STATIC FUNCTION Reseta(base,oForm)
LOCAL oDlgR,oGet:=ARRAY(5),oBot:=ARRAY(4),oBrwRes,oQryRes,nPara:=base:cantprod,oQryArt,;
      nCodart:=0,cDetArt:=SPACE(30),nCantidad:=1,nTotal:=0,oFontTotal,lRta:=.F.,oError
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reseta_temp ";
    +"( `CODART` BIGINT(14) NOT NULL,";  
    +"`DETART` VARCHAR(40) NOT NULL,";
    +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`PTOTAL` DECIMAL(12,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`CODART`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE reseta_temp")
oApp:oServer:NextResult()

oApp:oServer:Execute("INSERT INTO reseta_temp (codart,detart,cantidad,punit,ptotal) "+;
                   "(SELECT r.codusa,a.nombre,r.cantidad,a.preciocos,(r.cantidad * a.preciocos) "+;
                    "FROM reseta r LEFT JOIN articu a ON a.codigo = r.codusa "+;
                    "WHERE r.codart = "+ClipValue2SQL(base:codigo)+")")
oApp:oServer:NextResult()
oQryRes:= oApp:oServer:Query("SELECT * FROM reseta_temp")
oQryArt:= oApp:oServer:Query("SELECT * FROM articu WHERE mprima = true")

DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
DO WHILE .T.
DEFINE DIALOG oDlgR RESOURCE "RESETA" OF oForm 
  oDlgR:lHelpIcon := .f.

  REDEFINE GET oGet[1] VAR nPara     ID 100 OF oDlgR PICTURE "9999999.999"
  REDEFINE GET oGet[2] VAR nCodArt   ID 101 OF oDlgR PICTURE "99999999999999";
               VALID(Buscar(oQryArt,oDlgR,oGet[2],oGet[3],"true","mprima"));
                 ACTION (oGet[2]:cText:= 0, Buscar(oQryArt,oDlgR,oGet[2],oGet[3],"true","mprima")) BITMAP "BUSC1"
  REDEFINE GET oGet[3] VAR cDetArt   ID 102 OF oDlgR PICTURE "@!"
  REDEFINE GET oGet[4] VAR nCantidad ID 103 OF oDlgR PICTURE "9999999.999" 
  REDEFINE GET oGet[5] VAR nTotal    ID 104 OF oDlgR COLOR CLR_RED , CLR_YELLOW READONLY;
                 PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)

  REDEFINE XBROWSE oBrwRes DATASOURCE oQryRes;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","PTOTAL";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total";
       FOOTERS ;
       SIZES 80,281,60,80,80;
    ID 300 OF oDlgR 
    PintaBrw(oBrwRes,0)
    oBrwRes:aCols[5]:nFooterTypE := AGGR_SUM
    oBrwRes:MakeTotals()
    oGet[5]:cText := oBrwRes:aCols[5]:nTotal


    oBrwRes:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(EliminarItem(oQryRes,oBrwRes,oGet),;
                                   nTotal:= oBrw:aCols[5]:nTotal,oGet[4]:Refresh()),)}
    oDlgR:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[3]:Click,.f.) }

  REDEFINE BUTTON oBot[1] ID 200 OF oDlgR ACTION (AgregaItem(oQryRes,oBrwRes,oGet),oGet[2]:SetFocus());
          WHEN(nCantidad >0 .AND. nCodArt > 0)
  REDEFINE BUTTON oBot[2] ID 201 OF oDlgR ACTION (EliminarItem(oQryRes,oBrwRes,oGet),oGet[2]:SetFocus());
                  WHEN(oQryRes:RecCount()>0)
  REDEFINE BUTTON oBot[3] ID 202 OF oDlgR ACTION (lRta:=.t.,oDlgR:End()) 
  REDEFINE BUTTON oBot[4] ID 203 OF oDlgR ACTION (lRta:=.f.,oDlgR:End()) CANCEL
ACTIVATE DIALOG oDlgR CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
  RETURN nil 
ENDIF
base:cantprod:= nPara
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM reseta WHERE codart = " +ClipValue2Sql(base:codigo))
  oApp:oServer:NextResult()
  oApp:oServer:Execute("INSERT INTO reseta (codart,codusa,cantidad) "+;
                       "(SELECT "+ClipValue2Sql(base:codigo)+",codart,cantidad FROM reseta_temp)")
  oApp:oServer:Execute("UPDATE articu SET cantprod = "+ClipValue2Sql(base:cantprod)+","+;
                                         "produccion = TRUE "+;
                       "WHERE codigo = "+ClipValue2Sql(base:codigo))
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

************************************************************************************
** Borrar item del detalle
STATIC FUNCTION EliminarItem(oQryRes,oBrwRes,oGet)
oQryRes:DELETE()
oBrwRes:Refresh()
oQryRes:Refresh()
oBrwRes:Maketotals()  
oGet[5]:cText := oBrwRes:aCols[5]:nTotal
RETURN .t.




************************************************************************************
** Agregar item al detalle
STATIC FUNCTION AgregaItem(oQryRes,oBrwRes,oGet)
LOCAL oError
TRY
  oApp:oServer:BeginTransaction()
oApp:oServer:Execute("INSERT INTO reseta_temp (codart,detart,cantidad,punit,ptotal) "+;
                   "(SELECT "+ClipValue2SQL(oGet[2]:cText)+",a.nombre,"+ClipValue2Sql(oGet[4]:cText)+;
                   ",a.preciocos,"+ClipValue2Sql(oGet[4]:cText)+"*a.preciocos "+;
                    "FROM articu a WHERE codigo = "+ClipValue2Sql(oGet[2]:cText)+")")
CATCH oError
    ValidaError(oError)
END TRY
oQryRes:Refresh()
oBrwRes:Refresh()
oBrwRes:MakeTotals()
oGet[5]:cText := oBrwRes:aCols[5]:nTotal
RETURN nil

*************************************************************************************************************
********* Calular precio venta
STATIC FUNCTION CalcularPrecio(oGet,base)
oGet[18]:cText:=base:preciocos + (base:preciocos * base:porcentaje)/100
oGet[20]:cText:=base:preciocos + (base:preciocos * base:porcentaje)/100
RETURN .t.

******************************************
** Calculo del precio de venta
STATIC FUNCTION calcupre(lis,costo,marca,codiva)
LOCAL iv, precio, por,oQryAux
oQryAux:=oApp:oServer:Query("SELECT tasa FROM ivas WHERE codigo = " + ClipValue2Sql(codiva))
IF oQryAux:RecCount()>0
 iv:=oQryAux:tasa   
 por    := marca
 precio := costo  + costo  * iv/100    && calculo % iva
 precio := precio + precio * por/100   && calculo % ganancia segun lista
ELSE
 precio:=0
ENDIF
RETURN ROUND(precio,3)

****************************************FILTRADO**********************
STATIC FUNCTION FILT( )
   LOCAL oFilt,oGet:=ARRAY(4),oBot:=ARRAY(2),acor:=ARRAY(4),vProv:=0,cNomProv:=SPACE(30),;
   vDesde:=CTOD("  /  /    "),vHasta:=DATE(),oQryPro,lRta:=.f.,oFont,cWhere
   
oQryPro:= oApp:oServer:Query("SELECT * FROM provee")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.                        
DEFINE DIALOG oFilt TITLE "Filtrado de compras";
       FROM 05,15 TO 14,70 OF oWnd1 FONT oFont
   
   @ 07, 05 SAY "Proveedor:"              OF oFilt PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Desde:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
   @ 22, 75 SAY "Hasta:"                  OF oFilt PIXEL SIZE 50,20 RIGHT


   @ 05, 60 GET oGet[01] VAR vProv     OF oFilt PIXEL PICTURE "99999999" ;
                VALID(oGet[01]:value = 0 .or. Buscar(oQryPro,oFilt,oGet[01],oGet[02]));
                ACTION (oGet[01]:cText:= 0, Buscar(oQryPro,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"
   @ 05,100 GET oGet[02] VAR cNomProv  OF oFilt PIXEL PICTURE "@!" WHEN(.F.)
   @ 20, 60 GET oGet[03] VAR vDesde    OF oFilt PIXEL PICTURE "@D" CENTER                      
   @ 20,130 GET oGet[04] VAR vHasta    OF oFilt PIXEL PICTURE "@D" CENTER  

      
   acor := AcepCanc(oFilt)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .t.), oFilt:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
ACTIVATE DIALOG oFilt CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
         RETURN nil
      ENDIF    

   cWhere = " 1=1 " + IF(EMPTY(vProv),""," and c.codpro =" + ClipValue2SQL(vProv) + "") ;
      + "" + IF(EMPTY(Vdesde),""," and c.fecfac >=" + ClipValue2SQL(Vdesde) + "") ; 
      + "" + IF(EMPTY(Vhasta),""," and c.fecfac <=" + ClipValue2SQL(Vhasta) + "") ;



  * MSGINFO(" "+ cWhere)
      EXIT
   ENDDO
   oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
   oQryBrw:Refresh()
   oBrw:Refresh()
RETURN nil