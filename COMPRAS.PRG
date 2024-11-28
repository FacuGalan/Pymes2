#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
************************************************************************************************
** Compras
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, oBrw, oDlg, cVentana,oQry, oQryBrw,nIvaArt, nCant,oQryIvaDet,oBrwIvas,oBrwRet,lIncluido, ;
       oQryComprasDet, oQryCue, oQryPro, oQryArt,  oQryIva, oQryTip, oQryRet, oQryCom, oGet, oBot, base, baseDet,;
       oQry2,oQry3,oQry4,oQry5,oQry6,oQry7,nCodpro,cNumRe1,cNumRe2,oBrwDet,lPaga, lUsoPedido
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
                                  "c.estado,c.observa,p.nombre AS nompro,c.codpro ,c.saldo "+;
                                  "FROM ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"provee p ON p.codigo = c.codpro "+;
                                  "WHERE YEAR(c.fecfac) = " + STR(YEAR(DATE()))+" "+;
                                  "ORDER BY c.fecfac")
  

  oQryIva := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas      ORDER BY codigo")
  oQryCue := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"plancont")
  oQry2  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")

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
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Compras",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
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
              COLUMNS "tipocomp","letra","numfac","fecfac","nompro","importe","saldo","estado","observa";
              HEADERS "Tipo","Letra","Numero","Fecha","Proveedor","Importe","Saldo","Estado","Obsevaciones";
              FOOTERS ;
              SIZES 40,30,110,80,200,100,100,55,50;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[8]:bStrData := {|| IF(oQryBrw:RecCount()> 0 .and. abs(oQryBrw:saldo)=0,"PAGA","IMPAGA")}
     oBrw:aCols[6]:nFooterTypE := AGGR_SUM
     oBrw:aCols[7]:nFooterTypE := AGGR_SUM
     //oBrw:SetDolphin(oQry,.f.,.t.)
     oBrw:MakeTotals()
     PintaBrw(oBrw,9) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


STATIC FUNCTION Formu(lAlta)
LOCAL oGet:=ARRAY(45),oBot:=ARRAY(7),oFontTotal, lRta := .f., aTipoDoc, nTipoComp, nBultos:=0,;
      cNomPro,  cCuit, cConIva, cNomCue, nDeuda, nCodArt, cDetArt, nCantidad, oError, i, ;
      nPunit, nPTotal, cNomRet1, cNomRet2, cNomRet3, cNomRet4, cNomRet5, oDlg1, oQryDoc,nRenglon,;
      nSaldoIni:=0, nImporteIni:=0,oQryCodigos,nMaximo,nOrden, lPuedeCobrar, oQryPedPen, cInPed, cNumCompAnt,;
      dCierrecompras := oApp:oServer:Query( "SELECT cierrecompra FROM ge_"+oApp:cId+"parametros"):cierrecompra
lUsoPedido := {} 
lPuedeCobrar := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo WHERE (usuario="+;
        ClipValue2SQL(oApp:usuario)+ " AND modulo = 'ORDPAG' AND permisos = 'ABMRE') ORDER BY codigo"):nRecCount > 0
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
    +"`SINIVA`  TINYINT(1) NOT NULL DEFAULT '1',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0',";
    +"`DESC1` DECIMAL(5,2) DEFAULT '0',";
    +"`DESC2` DECIMAL(5,2) DEFAULT '0',";
    +"`DESC3` DECIMAL(5,2) DEFAULT '0',";
    +"`DESC4` DECIMAL(5,2) DEFAULT '0',";
    +"`DESC5` DECIMAL(5,2) DEFAULT '0',";
    +"`NETO_UNIT` DECIMAL(12,2) DEFAULT '0',";
    +"`NETO` DECIMAL(12,2) NOT NULL DEFAULT '0',";
    +"`IVA` DECIMAL(12,2) NOT NULL DEFAULT '0',";
    +"`TOTAL` DECIMAL(12,2) NOT NULL DEFAULT '0',";
    +"`CANTIDAD` DECIMAL(12,3) DEFAULT '0',";
    +"`CODIVA` DECIMAL(2) DEFAULT '0.00',";
    +"`CODIGOPRO` VARCHAR(30) NOT NULL DEFAULT '                             0',";
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
                       "(SELECT codigo,nombre,tasa,0,0 FROM ge_"+oApp:cId+"ivas)")
  oQryIvaDet:= oApp:oServer:Query("SELECT * FROM ivas_temp ORDER BY nombre ")
  
  //TABLA TEMPORAL PARA LOS MONTOS DE LAS RETENCIONES
  oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reten_temp ";
    +"("; 
    +"`CODIGO` INT(2) NOT NULL,";
    +"`NOMBRE` VARCHAR(25) NOT NULL,";
    +"`TIPO`   INT(1) NOT NULL,";
    +"`IMPORTE` DECIMAL(12,3) DEFAULT '0.00',";
    +" PRIMARY KEY (CODIGO)) ENGINE=INNODB DEFAULT CHARSET=utf8")   
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE reten_temp")
  oApp:oServer:NextResult()

  oApp:oServer:Execute("INSERT INTO reten_temp (CODIGO,NOMBRE,TIPO,IMPORTE) "+;
                       "(SELECT codigo,nombre,tipo,0 FROM ge_"+oApp:cId+"retencio WHERE retecli IS FALSE) ")
  oQryRet:= oApp:oServer:Query("SELECT * FROM reten_temp")
  
  oQryArt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu    ORDER BY codigo")
  oQryTip := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipocomp  ORDER BY codigo")
  oQryCom := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"compras   LIMIT 0")
  aTipoDoc:={"Factura","Nota de credito","Nota de debito","Presupuesto","Remito"} 
        
  aTipoDoc:={"Factura","Nota de credito","Nota de debito","Presupuesto","Remito"}
  lPaga:=.f.
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
  IF lAlta
    oQry    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"compras LIMIT 0")
    base    := oQry:GetBlankRow()
    base:fecfac:= DATE()
    base:fecing:= DATE()
    base:imputaiva := .t.
    base:estado := "I"
    nTipoComp:= 1
    cNumRe1:=SPACE(4)
    cNumRe2:=SPACE(8)
  ELSE
    oQry    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"compras WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac))
    base:= oQry:GetRowObj() 
    nSaldoIni:= base:saldo
    nImporteIni:= base:importe
    cNumRe1:=LEFT(base:numfac,4)
    cNumRe2:=RIGHT(base:numfac,8)
    cNumCompAnt := base:numfac
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
    oApp:oServer:Execute("INSERT INTO comprasdet_H (renglon,codpro,tipocomp,letra,numfac,codart,detart,cantidad,"+;
                       "punit,neto,iva,total,codiva,desc1,desc2,desc3,desc4,desc5,siniva) "+;
                       "SELECT c.renglon,c.codpro,c.tipocomp,c.letra,c.numfac,c.codart,a.nombre,c.cantidad,"+;
                       "c.punit,c.neto,c.iva,(c.neto+c.iva),c.codiva,c.desc1,c.desc2,c.desc3,c.desc4,c.desc5,c.siniva FROM ge_"+oApp:cId+"compradet c "+;
                       "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = c.codart "+;
                       "WHERE tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(base:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(base:numfac))
    oApp:oServer:Execute("UPDATE ivas_temp it LEFT JOIN ge_"+oApp:cId+"compivadet id ON it.codigo = id.codiva AND "+;
                       "id.tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                         "AND id.letra = " + ClipValue2Sql(base:letra)+" "+;
                         "AND id.codpro = " + ClipValue2Sql(base:codpro)+" "+;
                         "AND id.numfac = " + ClipValue2Sql(base:numfac)+" "+;
                         "SET it.neto = id.neto, it.iva = id.iva ")
    oQryIvaDet:Refresh()
    oApp:oServer:Execute("UPDATE reten_temp rt LEFT JOIN ge_"+oApp:cId+"compretdet rd ON rt.codigo = rd.codret AND "+;
                       "rd.tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                         "AND rd.letra = " + ClipValue2Sql(base:letra)+" "+;
                         "AND rd.codpro = " + ClipValue2Sql(base:codpro)+" "+;
                         "AND rd.numfac = " + ClipValue2Sql(base:numfac)+" "+;
                         "SET rt.importe = rd.importe ")
    oQryRet:Refresh()
  ENDIF
  nCodPro:= SPACE(30)
  oQryComprasDet :=oApp:oServer:Query("SELECT * FROM comprasdet_H")
  baseDet := oQryComprasDet:GetBlankRow()
  DO WHILE .T.
    DEFINE DIALOG oDlg1 RESOURCE "COMPRAS" OF oWnd1
    oDlg1:lHelpIcon := .f.
    REDEFINE COMBOBOX oGet[01] VAR nTipoComp ITEMS aTipoDoc ID 110 OF oDlg1 WHEN(lAlta)      
    REDEFINE GET oGet[02] VAR base:letra   ID 111  OF oDlg1 VALID( base:letra $ "ABCRMXE") WHEN(lAlta)
    oGet[2]:bLostFocus := {|| IF(oGet[2]:cText = 'X',(base:imputaiva:=.f.,oGet[14]:Refresh()),(base:imputaiva:=.t.,oGet[14]:Refresh()))}
    REDEFINE GET oGet[03] VAR cNumRe1      ID 500 OF oDlg1 PICTURE "9999" ;
                VALID((oGet[03]:cText:= STRTRAN(STR(VAL(oGet[03]:cText),4)," ","0")) <> "xxx")
    oGet[03]:bGotFocus:={|| oGet[03]:SelectAll()}
    REDEFINE GET oGet[28] VAR cNumRe2      ID 501 OF oDlg1 PICTURE "99999999" ;
                 VALID((oGet[28]:cText:= STRTRAN(STR(VAL(oGet[28]:cText),8)," ","0")) <> "xxx")
    oGet[28]:bGotFocus:={|| oGet[28]:SelectAll()}
    REDEFINE GET oGet[04] VAR oApp:usuario ID 113 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[05] VAR base:fecfac  ID 114 OF oDlg1
    REDEFINE GET oGet[06] VAR base:fecing  ID 115 OF oDlg1  
    REDEFINE GET oGet[07] VAR base:codpro  ID 116 OF oDlg1 PICTURE "99999999" WHEN(lAlta .and. oQryComprasDet:RecCount()=0);
                 VALID(ValidaPro(oGet,lAlta,oDlg1));
                 ACTION (oGet[07]:cText:= 0, ValidaPro(oGet,lAlta,oDlg1)) BITMAP "BUSC1"
    REDEFINE GET oGet[08] VAR cNomPro      ID 117 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[09] VAR cCuit        ID 118 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[10] VAR cConIva      ID 119 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[11] VAR base:codcue  ID 120 OF oDlg1 PICTURE "9999";
                VALID(Buscar(oQryCue,oDlg1,oGet[11],oGet[12]));
                ACTION (oGet[11]:cText:= 0, Buscar(oQryCue,oDlg1,oGet[11],oGet[12])) BITMAP "BUSC1"
    REDEFINE GET oGet[12] VAR cNomCue      ID 121 OF oDlg1 WHEN(.F.)            
    REDEFINE GET oGet[13] VAR nDeuda       ID 122 OF oDlg1 WHEN(.F.) PICTURE "999999999.99"
    REDEFINE CHECKBOX oGet[14] VAR base:imputaiva   ID 123 OF oDlg1 
    REDEFINE CHECKBOX oGet[45] VAR lPaga   ID 4026 OF oDlg1  WHEN(lPuedeCobrar .and. lAlta)
    REDEFINE GET oGet[16] VAR base:observa    ID 125 OF oDlg1 PICTURE "@!"
    REDEFINE GET oGet[17] VAR baseDet:codart  ID 126 OF oDlg1; 
                 VALID(basedet:codart = 0 .OR. ValidaArt(oDlg1,oGet));
                 ACTION (oGet[17]:cText:= 0, ValidaArt(oDlg1,oGet)) BITMAP "BUSC1" PICTURE "99999999999999"
    REDEFINE GET oGet[15] VAR nCodpro  ID 4020 OF oDlg1 WHEN(oApp:usar_codpro);
                 VALID(oGet[15]:cText=SPACE(30) .OR. ValidaArtP(oDlg1,oGet,.F.));
                 ACTION (oGet[15]:cText:= "-1", ValidaArtP(oDlg1,oGet,.T.)) BITMAP "BUSC1" PICTURE "@!"
    oGet[15]:bGotFocus:={|| oGet[15]:SelectAll()}
    REDEFINE GET oGet[18] VAR basedet:detart  ID 127 OF oDlg1 WHEN(.F.)
    REDEFINE GET oGet[19] VAR basedet:cantidad ID 128 OF oDlg1 PICTURE "9999999999.99";
                 VALID((oGet[21]:cText:= basedet:cantidad * basedet:punit) <> "XXX")
    REDEFINE GET oGet[20] VAR basedet:punit  ID 129 OF oDlg1 PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[21] VAR basedet:total  ID 130 OF oDlg1 PICTURE "999999999.99" WHEN(.F.)

    REDEFINE BUTTON oBot[1] ID 131 OF oDlg1 ACTION(oQryComprasDet:lAppend:=.t.,AgregarItem(oGet,nTipoComp),oBrwDet:MakeTotals(),;
                                                               oQryComprasDet:GetBlankRow(),;
                                                               CalcTot(oGet,.T.),oBot[1]:oJump := oGet[17]);
                                            WHEN(basedet:codart>0 .and. basedet:cantidad >0)


    //GRILLA ---------------------------------------------------------------      
    REDEFINE XBROWSE oBrwDet DATASOURCE oQryComprasDet;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","DESC1","DESC2","DESC3","DESC4","DESC5","NETO_UNIT","NETO","IVA","TOTAL";
       HEADERS "Codigo","Articulo","Cantidad","P. Unit","Desc. 1","Desc. 2","Desc. 3","Desc. 4","Desc. 5","Net. Un.","Neto","I.V.A","Total";
       FOOTERS ;
       SIZES 50,260,60,55,45,45,45,45,45,60,60,60,80;
       ID 132 OF oDlg1 WHEN(oQryComprasDet:nRecCount > 0)
    PintaBrw(oBrwDet,0)

    oBrwDet:aCols[3]:lAutoSave := .t.
    oBrwDet:aCols[3]:nEditType := EDIT_GET 
    oBrwDet:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,oGet)}
    oBrwDet:aCols[4]:lAutoSave := .t.
    oBrwDet:aCols[4]:nEditType := EDIT_GET 
    oBrwDet:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,xval,oGet)}
    oBrwDet:aCols[5]:lAutoSave := .t.
    oBrwDet:aCols[5]:nEditType := EDIT_GET 
    oBrwDet:aCols[5]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,oGet,xval)}
    oBrwDet:aCols[6]:lAutoSave := .t.
    oBrwDet:aCols[6]:nEditType := EDIT_GET 
    oBrwDet:aCols[6]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,oGet,,xval)}
    oBrwDet:aCols[7]:lAutoSave := .t.
    oBrwDet:aCols[7]:nEditType := EDIT_GET 
    oBrwDet:aCols[7]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,oGet,,,xval)}
    oBrwDet:aCols[8]:lAutoSave := .t.
    oBrwDet:aCols[8]:nEditType := EDIT_GET 
    oBrwDet:aCols[8]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,oGet,,,,xval)}
    oBrwDet:aCols[9]:lAutoSave := .t.
    oBrwDet:aCols[9]:nEditType := EDIT_GET 
    oBrwDet:aCols[9]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,,oGet,,,,,xval)}

    oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,(oGet[17]:nLastkey:=11,oBot[3]:Click),.t.) }
    oBrwDet:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(oQryComprasDet:lAppend := .f., oQryComprasDet:Delete(),;
                                                     oBrwDet:MakeTotals(),CalcTot(oGet,.T.),oBrwDet:Refresh(),oGet[17]:SetFocus()),.t.) }
    oBrwDet:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwDet:aCols[11]:nFooterTypE := AGGR_SUM
    oBrwDet:aCols[12]:nFooterTypE := AGGR_SUM
    oBrwDet:aCols[13]:nFooterTypE := AGGR_SUM
    oBrwDet:MakeTotals()

    //DETALLE DE IVAS --------------------------------------------------------
    REDEFINE XBROWSE oBrwIvas DATASOURCE oQryIvaDet;
      COLUMNS "CODIGO","NOMBRE","NETO","IVA";
      HEADERS "Codigo","Nombre","Neto","Iva";
      FOOTERS;
      SIZES 40,87,80,80 ID 400 OF oDlg1 ON CHANGE (CalcTot(oGet,.F.),oBrwRet:SetFocus(),oBrwIvas:SetFocus())
    PintaBrw(oBrwIvas,0)
    oBrwIvas:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwIvas:aCols[4]:nFooterTypE := AGGR_SUM
    oBrwIvas:aCols[3]:lAutoSave := .t.
    oBrwIvas:nMoveType := 4
    oBrwIvas:aCols[3]:nEditType := EDIT_GET
    *oBrwIvas:aCols[3]:bOnChange := {|| CalcTot(oGet,.F.)}
    oBrwIvas:aCols[4]:lAutoSave := .t.
    oBrwIvas:aCols[4]:nEditType := EDIT_GET
    *oBrwIvas:aCols[4]:bOnChange := {|| CalcTot(oGet,.F.)}
    oBrwIvas:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | (oQryIvaDet:neto:= xVal,oQryIvaDet:iva:= xVal * oQryIvaDet:tasa/100,oQryIvaDet:Save()) }
    oBrwIvas:MakeTotals()

    //DETALLE DE RETENCIONES --------------------------------------------------------
    REDEFINE XBROWSE oBrwRet DATASOURCE oQryRet;
      COLUMNS "CODIGO","NOMBRE","IMPORTE";
      HEADERS "Codigo","Nombre","Importe";
      FOOTERS;
      SIZES 40,113,90 ID 401 OF oDlg1  ON CHANGE (CalcTot(oGet,.F.),oBrwIvas:SetFocus(),oBrwRet:SetFocus()) 
    PintaBrw(oBrwRet,0)
    oBrwRet:aCols[3]:nFooterTypE := AGGR_SUM
    oBrwRet:aCols[3]:lAutoSave := .t.
    oBrwRet:nMoveType := 4
    oBrwRet:aCols[3]:nEditType := EDIT_GET
    *oBrwRet:aCols[3]:bOnChange := {|| CalcTot(oGet,.F.)}
    oBrwRet:MakeTotals()
   
   
    // No Grabado
    REDEFINE GET oGet[41] VAR base:nograbado  ID 152 OF oDlg1 PICTURE "9999999999.99"
    oGet[41]:bLostFocus:= { || (oGet[41]:Assign(), CalcTot(oGet,.F.))}
    *oGet[24]:bLostFocus:= { || (oGet[24]:Assign(), oGet[20]:SetFocus())}
    *oGet[26]:bLostFocus:= { || (oGet[26]:Assign(), oGet[20]:SetFocus())}
    *oGet[27]:bLostFocus:= { || (oGet[27]:Assign(), oGet[20]:SetFocus())}

        REDEFINE GET oGet[42] VAR base:importe    ID 300 OF oDlg1 FONT oFontTotal COLOR CLR_RED,CLR_WHITE PICTURE "9999999999.99";
        
    //BOTONES ---------------------------------------------------------------
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg1 ACTION(Cancela(oGet))    
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg1 ACTION(lRta:=.t.,oDlg1:End()) WHEN(base:importe>0 .or.  nTipoComp = 5)    
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg1 ACTION(lRta:=.f.,oDlg1:End()) CANCEL    
    REDEFINE BUTTON oBot[5] ID 105 OF oDlg1 ACTION(FormuArt(oDlg1))      
    REDEFINE BUTTON oBot[6] ID 106 OF oDlg1 ACTION(ActualizaPrecios(oGet,oDlg1)) WHEN(oQryComprasDet:RecCount()>0)

    REDEFINE BUTTON oBot[7] ID 4011 OF oDlg1 ACTION(BuscaPedidos(base,oGet)) WHEN(lAlta .and. base:codpro > 0)    
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg1 CENTER ON INIT IF(!lAlta,ValidaPro(oGet,lAlta,oDlg1),.f.) 

IF !lRta
   RETURN nil
ENDIF


IF base:imputaiva .and. base:fecing <= dCierreCompras
     MsgStop("No puede agregar ni modificar comprobantes anteriores al "+dtoc(dCierreCompras)+chr(10)+;
      "El libro de IVA esta cerrado a esa fecha","Atencion!")
     LOOP
ENDIF

//Validar que el turno este abierto si quiere cargar como paga
IF lAlta .and. lPaga
    IF oApp:cierre_turno
      IF !ValidarTurno(oApp:oWnd)
         LOOP
      ENDIF
    ENDIF
ENDIF

IF EMPTY(base:letra) .or. empty(cNumRe1) .or. empty(cNumRe2) .or. base:codpro = 0 .or. cNumRe1 = '0000' .or. cNumRe2 = '00000000'
     MsgStop("Faltan datos del encabezado del comprobante","Atencion!")
     LOOP
ENDIF

IF nSaldoIni = nImporteIni
   base:saldo:= base:importe
ENDIF

base:numfac:=cNumRe1+"-"+cNumRe2

IF lAlta
   oQry:GetBlankRow()
   IF lPaga
      base:saldo = 0
      base:estado = 'P'
   ENDIF
ELSE
   IF nImporteIni <> base:importe
     lRta:= MsgNoYes("¿Desea realizar los cambios al comprobante? Tenga en cuenta que si ya tiene pagos realizados permaneceran igual","Atencion!")
   ENDIF
   IF !lRta
      RETURN nil
   ENDIF
ENDIF
oQryDoc := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipocomp WHERE codigo = " + ClipValue2Sql(nTipoComp))
base:tipocomp:= oQryDoc:prefijo

base:usuario:= oApp:usuario 
base:ip     := oApp:cIp
base:fecmod := DATE()

base:neto := oBrwIvas:aCols[3]:nTotal 
base:iva  := oBrwIvas:aCols[4]:nTotal

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()    
  oQry:Save()
  IF !lAlta
     oApp:oServer:Execute("UPDATE (SELECT codart, tipocomp, sum(cantidad) as cantidad FROM ge_"+oApp:cId+"compradet WHERE "+;
                       " codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(cNumCompAnt) +;
                       " GROUP BY codart) c "+;
                       " LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;
                       " SET a.stockact = a.stockact - IF(c.tipocomp='NC',c.cantidad*(-1),c.cantidad)") 

  ENDIF
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compradet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(cNumCompAnt))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"compradet  (renglon,codpro,tipocomp,letra,numfac,codart,cantidad,punit,neto,iva,codiva,desc1,desc2,desc3,desc4,desc5,siniva) "+;
                       "SELECT renglon,codpro,"+ClipValue2Sql(oQryDoc:prefijo)+","+ClipValue2SQL(base:letra)+","+;
                       ClipValue2SQL(base:numfac)+",codart,cantidad,punit,neto,iva,codiva,desc1,desc2,desc3,desc4,desc5,siniva "+;
                       "FROM comprasdet_H ")
  oApp:oServer:Execute("UPDATE (SELECT codart, tipocomp, sum(cantidad) as cantidad FROM comprasdet_H "+;                      
                       " GROUP BY codart) c "+;
                       " LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;
                       " SET a.stockact = a.stockact + IF(c.tipocomp='NC',c.cantidad*(-1),c.cantidad), "+;
                       " a.fecultcom = " + ClipValue2Sql(base:fecfac)  )

  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compivadet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(cNumCompAnt))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"compivadet (codpro,tipocomp,letra,numfac,codiva,neto,iva) "+;
                       "(SELECT "+ClipValue2SQL(base:codpro)+","+ClipValue2Sql(oQryDoc:prefijo)+","+ClipValue2SQL(base:letra)+","+;
                       ClipValue2SQL(base:numfac)+",codigo,neto,iva "+;
                       "FROM ivas_temp WHERE neto > 0) ")
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compretdet WHERE codpro = " + ClipValue2Sql(base:codpro)+" "+; 
                       "AND tipocomp = " + ClipValue2Sql(base:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(base:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(cNumCompAnt))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"compretdet (codpro,tipocomp,letra,numfac,codret,importe,tipo) "+;
                       "(SELECT "+ClipValue2SQL(base:codpro)+","+ClipValue2Sql(oQryDoc:prefijo)+","+ClipValue2SQL(base:letra)+","+;
                       ClipValue2SQL(base:numfac)+",codigo,importe,tipo "+;
                       "FROM reten_temp WHERE importe > 0) ")
  IF lPaga .and. nTipoComp <> 5
     nMaximo:= oApp:oServer:Query("SELECT MAX(numero)+1 AS num FROM ge_"+oApp:cId+"ordpag"):num
     ** Agrego pago 
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordpag " + ;
                          " (proveedor, total, facturas, observa, fecha, usuario,fecmod,ip,caja,checkeado,demo,numero) VALUES "+;
                         " ("+;
                             ClipValue2Sql(base:codpro)+","+;
                             ClipValue2Sql(base:importe)+","+;
                             ClipValue2Sql(base:importe)+","+;
                             "'PAGO DIRECTO EN EFECTIVO',"+;
                             "CURDATE(),"+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2Sql(DATE())+","+;
                             ClipValue2Sql(oApp:cIp)+","+;
                             ClipValue2Sql(oApp:prefijo)+",FALSE,"+;
                             "1,"+;
                             ClipValue2Sql(nMaximo)+")")
         nOrden:= oApp:oServer:Query("SELECT MAX(numero) AS orden FROM ge_"+oApp:cId+"ordpag"):orden

         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordfac SET numero = "+ ClipValue2Sql(nOrden)+","+;
                              "tipocomp = "+ ClipValue2Sql(base:tipocomp)+","+;
                              "letra = "+ ClipValue2Sql(base:letra)+","+;
                              "numfac = "+ ClipValue2Sql(base:numfac)+","+;
                              "fecha = CURDATE(),"+;
                              "importe = "+ClipValue2Sql(base:importe)+","+;
                              "netogan = 0,"+;
                              "neto = "+ClipValue2Sql(oQry:neto))              

        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ordcon SET numero  = " + ClipValue2Sql(nOrden)+","+;
                                               "codcon  = 1, "+;
                                               "importe = "+ ClipValue2Sql(base:importe)+","+;
                                               "observa = 'EFECTIVO'")

        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"usuarios SET saldo = saldo - "+ClipValue2Sql(base:importe)+" "+;
                             "WHERE usuario = "+ClipValue2Sql(oApp:usuario))

  ENDIF
  IF lAlta
    IF oApp:usar_codpro
      oApp:oServer:Execute("UPDATE comprasdet_H c LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;
                           "SET a.codigopro = c.codigopro ")
    ENDIF
  ENDIF
  IF lAlta .and. LEN(lUsoPedido) > 0 
     //Primero me fijo si hay faltantes
     cInPed := ""
     FOR i := 1 TO LEN(lUsoPedido)
         cInPed := cInPed + STR(lUsoPedido[i])+","
     NEXT i 
     cInPed := LEFT(cInped,LEN(cInPed)-1)
     oQryPedPen := ;
     oApp:oServer:Query("SELECT res.codart, res.detart, res.punit, SUM(res.comprado) AS comprado, "+;
                        " SUM(res.pedido) as pedido FROM ("+;
      "SELECT codart,detart, SUM(cantidad) as comprado, 0 as pedido, punit "+;
         " FROM comprasdet_H GROUP BY codart "+;
         " UNION "+;
      "SELECT codart,detart, 0 as comprado, SUM(cantidad) as pedido, punit "+;
      " FROM ge_"+oApp:cId+"pedprov_det WHERE numero IN ("+cInped+") GROUP BY codart ) res GROUP BY res.codart")
     i := .f.
     DO WHIlE !oQryPedPen:eof()
        IF (oQryPedPen:comprado < oQryPedPen:pedido)
           i := .t.
        ENDIF    
        oQryPedPen:Skip()
     ENDDO 
     IF i 
        i := MsgNoYes("La compra tiene productos de pedidos que no cubren las "+CHR(10)+;
                      "cantidades pedidas. Desea generar un pedido automático"+CHR(10)+;
                      "con los productos faltantes?","Atencion")
        IF i 
            oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedprov (codpro,fecha,usuario,fecmod) VALUES ("+;
                                ClipValue2Sql(base:codpro)+",CURDATE(),"+ClipValue2SQL(oApp:usuario)+",CURDATE())")
            i := oApp:oServer:LastInsertID()
            oQryPedPen:GoTop()
            DO WHIlE !oQryPedPen:eof()
               IF (oQryPedPen:comprado < oQryPedPen:pedido)
                  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedprov_det "+;
                                " (numero,codart,detart,cantidad,punit,total) VALUES ("+;
                                ClipValue2Sql(i)+","+ClipValue2SQL(oQryPedPen:codart)+","+;
                                ClipValue2SQL(oQryPedPen:detart)+","+;
                                ClipValue2SQL(oQryPedPen:pedido - oQryPedPen:comprado)+","+;
                                ClipValue2SQL(oQryPedPen:punit)+","+;
                                ClipValue2SQL(oQryPedPen:punit * (oQryPedPen:pedido - oQryPedPen:comprado) )+""+;
                                ")")
               ENDIF    
               oQryPedPen:Skip()
            ENDDO 
        ENDIF
     ENDIF                    
     //Despues borro los pedidos
     FOR i := 1 TO LEN(lUsoPedido)
         oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedprov WHERE id = " + ClipValue2Sql(lUsoPedido[i]))
         oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedprov_det WHERE numero = " + ClipValue2Sql(lUsoPedido[i]))
     NEXT i
  ENDIF
  oApp:oServer:CommitTransaction()
CATCH oError
    MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO
IF lAlta .AND. !lPaga .and. nTipoComp <> 5 .and. lPuedeCobrar
   lRta := MsgNoYes("¿Desea Hacer la Orden de Pago ahora?","Atencion")
   IF lRta 
      OrdPag(,base:codpro)
   ENDIF
ENDIF
oQryBrw:Refresh()
RETURN nil


*****************************************
** Actualizar precios de articulo 
STATIC FUNCTION ActualizaPrecios(oGet1,oWnd)
LOCAL base1 := oQryComprasDet:GetRowObj(), oForm,oGet:=ARRAY(46),oQryAux,baseArt,oBot:=ARRAY(2),lRta:=.f.,;
      nNeto:=0,cIvaNom:=SPACE(15),oError


oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(base1:codart))
baseArt   := oQryAux:GetRowObj()
oQry3:GoTop()
IF oQry3:Seek(baseArt:iva,1) > 0
  cIvaNom := STR(oQry3:tasa,6,2) + "%"
ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Actualizar precios de " RESOURCE "PRECIOCOMP" OF oWnd
 oForm:lHelpIcon := .f.
 
  REDEFINE CHECKBOX oGet[46] VAR baseArt:siniva  ID 4003 OF oForm
  REDEFINE GET oGet[06] VAR baseArt:precossiva ID 106 OF oForm PICTURE "999999999.99" 
  REDEFINE GET oGet[07] VAR baseArt:desc1      ID 107 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[08] VAR baseArt:desc2      ID 108 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[09] VAR baseArt:desc3      ID 109 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[10] VAR baseArt:desc4      ID 110 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[11] VAR baseArt:desc5      ID 111 OF oForm PICTURE "999.99"  
  REDEFINE GET oGet[39] VAR nNeto           ID 112 OF oForm PICTURE "999999999.99";
           WHEN(CalcularNeto(baseArt,oGet))
  REDEFINE GET oGet[12] VAR baseArt:impint     ID 113 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[13] VAR baseArt:flete      ID 114 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[14] VAR baseArt:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet[14]:cText:= 0, (Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
  REDEFINE GET oGet[16] VAR baseArt:preciocos  ID 117 OF oForm PICTURE "999999999.99";
                        WHEN((oGet[16]:cText:= nNeto + nNeto * (baseArt:impint/100) +;
                        nNeto * (baseArt:flete/100) + ((nNeto * oQry3:tasa )/100)) = "-999999")
  REDEFINE GET oGet[17] VAR baseArt:porcentaje ID 118 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,baseArt,.t.))
  REDEFINE GET oGet[18] VAR baseArt:porcentajerev  ID 119 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,baseArt,.f.))
  REDEFINE GET oGet[19] VAR baseArt:reventa    ID 120 OF oForm PICTURE "999999999.99"
  REDEFINE GET oGet[20] VAR baseArt:precioven  ID 121 OF oForm PICTURE "999999999.99"

  REDEFINE BUTTON oBot[1] ID 137 OF oForm PROMPT "&Actualizar";
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL

ACTIVATE DIALOG oForm CENTER 

IF !lRta
   RETURN nil
ENDIF


baseArt:porcentaje := (baseArt:precioven * 100) / baseArt:preciocos - 100
baseArt:porcentajerev := (baseArt:reventa * 100) / baseArt:preciocos - 100

baseArt:usuario:= oApp:usuario
baseArt:fecmod := DATE()
baseArt:ip     := oApp:cIp

ActualizarGrupo(baseArt)

base1:total := base1:cantidad * baseArt:precossiva
base1:codiva := oApp:oServer:Query("SELECT iva FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base1:codart)):iva
IF base1:siniva
 base1:neto:= base1:total
 base1:iva := base1:total * oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(base1:codiva)):tasa/100
 base1:total := base1:neto + base1:iva 
ELSE
 base1:neto:= base1:total / (1+ oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(basedet:codiva)):tasa/100)
 base1:iva := base1:total - base1:neto 
ENDIF

base1:punit    := baseArt:precossiva

oQryComprasDet:lAppend:= .f.
oQryComprasDet:oRow := base1
oQryAux:oRow := baseArt
TRY
  oApp:oServer:BeginTransaction()  
  //oQryAux:Save()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu  "+; 
                       " SET  "+;
                       " siniva ="+ClipValue2Sql(baseArt:siniva)+","+;
                       " precossiva ="+ClipValue2Sql(baseArt:precossiva)+","+;
                       " desc1 ="+ClipValue2Sql(baseArt:desc1)+","+;
                       " desc2 ="+ClipValue2Sql(baseArt:desc2)+","+;
                       " desc3 ="+ClipValue2Sql(baseArt:desc3)+","+;
                       " desc4 ="+ClipValue2Sql(baseArt:desc4)+","+;
                       " desc5 ="+ClipValue2Sql(baseArt:desc5)+","+;
                       " impint ="+ClipValue2Sql(baseArt:impint)+","+;
                       " flete ="+ClipValue2Sql(baseArt:flete)+","+;
                       " iva ="+ClipValue2Sql(baseArt:iva)+","+;
                       " preciocos ="+ClipValue2Sql(baseArt:preciocos)+","+;
                       " porcentaje ="+ClipValue2Sql(baseArt:porcentaje)+","+;
                       " porcentajerev ="+ClipValue2Sql(baseArt:porcentajerev)+","+;
                       " precioven ="+ClipValue2Sql(baseArt:precioven)+","+;
                       " reventa ="+ClipValue2Sql(baseArt:reventa)+","+;
                       " ip ="+ClipValue2Sql(baseArt:ip)+","+;
                       " fecmod ="+ClipValue2Sql(baseArt:fecmod)+","+;
                       " usuario ="+ClipValue2Sql(baseArt:usuario)+" WHERE codigo = "+ClipValue2Sql(baseArt:codigo))
  oQryComprasDet:Save()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                        "VALUES ("+ClipValue2Sql(oQryAux:codigo)+","+ClipValue2Sql(oQryAux:preciocos)+","+;
                        ClipValue2Sql(oQryAux:precossiva)+","+ClipValue2Sql(oQryAux:precioven)+","+ClipValue2Sql(oQryAux:reventa)+",CURDATE(),"+;
                        ClipValue2Sql(oApp:usuario)+",'Cambio x compras')")
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO

oQryComprasDet:Refresh()
oBrwDet:Refresh()
oBrwDet:Maketotals()
CalcTot(oGet1,.T.)


RETURN nil


*************************************************************************************************************
********** ACTUALIZA EL PRECIO DE LOS ARTICULOS QUE SE ENCUENTRAN EN EL MISMO GRUPO QUE EL MODIFICADO
STATIC FUNCTION ActualizarGrupo(base)
LOCAL nGrupo:= oApp:oServer:Query("SELECT codgru FROM ge_"+oApp:cId+"gruposdet WHERE codart = "+ClipValue2Sql(base:codigo)):codgru

oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET precossiva = "+ClipValue2Sql(base:precossiva)+","+;
                                       "desc1      = "+ClipValue2Sql(base:desc1)+","+;
                                       "desc2      = "+ClipValue2Sql(base:desc2)+","+;
                                       "desc3      = "+ClipValue2Sql(base:desc3)+","+;
                                       "desc4      = "+ClipValue2Sql(base:desc4)+","+;
                                       "desc5      = "+ClipValue2Sql(base:desc5)+","+;
                                       "impint     = "+ClipValue2Sql(base:impint)+","+;
                                       "flete      = "+ClipValue2Sql(base:flete)+","+;
                                       "iva        = "+ClipValue2Sql(base:iva)+","+;
                                       "preciocos  = "+ClipValue2Sql(base:preciocos)+","+;
                                       "porcentaje = "+ClipValue2Sql(base:porcentaje)+","+;
                                       "precioven  = "+ClipValue2Sql(base:precioven)+","+;
                                       "preciopro  = "+ClipValue2Sql(base:preciopro)+","+;
                                       "porcentajerev = "+ClipValue2Sql(base:porcentajerev)+","+;
                                       "reventa    = "+ClipValue2Sql(base:reventa)+","+;
                                       "fecmod     = "+ClipValue2Sql(DATE())+","+;
                                       "siniva     = "+ClipValue2Sql(base:siniva)+" "+;
                     "WHERE codigo IN (SELECT codart FROM ge_"+oApp:cId+"gruposdet WHERE codgru = "+ClipValue2Sql(nGrupo)+")")
RETURN nil

*****************************************
** Cambiar pendientes
STATIC FUNCTION CambiaCant(n,nPUnit,oGet,nDesc1,nDesc2,nDesc3,nDesc4,nDesc5)
LOCAL base1 := oQryComprasDet:GetRowObj()
DEFAULT n := base1:cantidad,nPUnit:= base1:punit,nDesc1:=base1:desc1,nDesc2:=base1:desc2,nDesc3:=base1:desc3,nDesc4:=base1:desc4,nDesc5:=base1:desc5

base1:codiva := oApp:oServer:Query("SELECT iva FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base1:codart)):iva

IF base1:siniva
 base1:neto_unit:= nPunit
ELSE
 base1:neto_unit:= nPunit / (1+ oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(base1:codiva)):tasa/100)
ENDIF


base1:neto_unit:= base1:neto_unit - base1:neto_unit * (nDesc1/100)
base1:neto_unit:= base1:neto_unit - base1:neto_unit * (nDesc2/100)
base1:neto_unit:= base1:neto_unit - base1:neto_unit * (nDesc3/100)
base1:neto_unit:= base1:neto_unit - base1:neto_unit * (nDesc4/100)
base1:neto_unit:= base1:neto_unit - base1:neto_unit * (nDesc5/100)

base1:neto:= base1:neto_unit * n 
base1:iva := base1:neto * oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(base1:codiva)):tasa/100
base1:total := base1:neto + base1:iva


base1:desc1:= nDesc1
base1:desc2:= nDesc2
base1:desc3:= nDesc3
base1:desc4:= nDesc4
base1:desc5:= nDesc5
base1:cantidad := n 
base1:punit    := nPUnit
oQryComprasDet:lAppend:= .f.
oQryComprasDet:oRow := base1
oQryComprasDet:Save()
oQryComprasDet:Refresh()
oBrwDet:Refresh()
oBrwDet:Maketotals()
CalcTot(oGet,.T.)

RETURN nil

************************************************************************************************************
********* CALCULA EL NETO DEL ARTICULO 
STATIC FUNCTION CalcularNeto(baseart,oGet1)
LOCAL nTotalNeto

nTotalNeto:= IF(baseart:siniva,baseart:precossiva,baseart:precossiva/(1+oQry3:tasa/100))
nTotalNeto:= nTotalNeto - nTotalNeto * (baseart:desc1/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (baseart:desc2/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (baseart:desc3/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (baseart:desc4/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (baseart:desc5/100)

oGet1[39]:cText:= nTotalNeto

RETURN .f.


**********************************************************************************************
STATIC FUNCTION ValidaArtP(oDlg1,oGet,lBuscar)
LOCAL oQryArt2, lEncontro, oQryArtP

    oQryArt2 := oApp:oServer:Query("SELECT a.codigopro AS codigo,a.nombre AS nombre,a.codigo AS codart, i.nombre AS cNomIva, i.tasa AS tasaiva, a.iva AS codiva, "+;
                                  "a.siniva,a.precossiva FROM ge_"+oApp:cId+"articu a "+;
                                  "LEFT JOIN ge_"+oApp:cId+"ivas i ON a.iva = i.codigo "+;
                                  "WHERE a.codigopro = " + ClipValue2SQL(oGet[15]:cText))

    IF oQryArt2:RecCount() = 0 
       lEncontro := .f.
       IF lBuscar
          BuscarArt(oQryArt2,oDlg1,oGet[15],oGet[18],"true","(a.codigopro IS NOT NULL)")
          lEncontro := .t.
       ENDIF       
       ELSE 
       lEncontro := .t.
    ENDIF
    IF !lEncontro
       oQryArtP := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"codpro WHERE codarp = "+ClipValue2SQL(oGet[15]:cText)+ " AND codpro = "+ ClipValue2SQL(oGet[7]:cText)) 
       IF oQryArtP:nRecCount > 0
          oQryArt2 := oApp:oServer:Query("SELECT a.codigopro AS codigo,a.nombre AS nombre,a.codigo AS codart, i.nombre AS cNomIva, i.tasa AS tasaiva, a.iva AS codiva, "+;
                                  "a.siniva,a.precossiva FROM ge_"+oApp:cId+"articu a "+;
                                  "LEFT JOIN ge_"+oApp:cId+"ivas i ON a.iva = i.codigo "+;
                                  "WHERE a.codigo = " + ClipValue2SQL(oQryArtP:codart))
       ENDIF                                     
    ENDIF
    oGet[17]:cText:= oQryArt2:codart
    oGet[18]:cText:= oQryArt2:nombre
    nCant:= 1
    oGet[19]:cText:= 1
    oGet[20]:cText:= oQryArt2:precossiva
    oGet[21]:cText:= oQryArt2:precossiva
    basedet:siniva:= oQryArt2:siniva
    oQryArt2:SetNewFilter(SET_WHERE,"true",.t.)
RETURN .t.

**********************************************************************************************
***** CALCULAR IMPORTE FINAL
STATIC FUNCTION CalcTot(oGet,lCalcular)
IF lCalcular
  oQryComprasDet:Refresh()
  oBrwDet:Refresh()
  oBrwDet:MakeTotals()
  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE ivas_temp")
  oApp:oServer:NextResult()
  oApp:oServer:Execute("INSERT INTO ivas_temp (codigo,nombre,tasa,neto,iva) "+;
                         "(SELECT i.codigo,i.nombre,i.tasa,SUM(c.neto), "+;
                         "SUM(c.iva) FROM ge_"+oApp:cId+"ivas i "+;
                         "LEFT JOIN comprasdet_H c ON i.codigo = c.codiva GROUP BY i.codigo)")
  oApp:oServer:NextResult()
  oQryIvaDet:Refresh(.t.)
  oBrwIvas:Refresh()
ENDIF
oBrwRet:MakeTotals()
oBrwIvas:MakeTotals()
oGet[42]:cText:= (oBrwIvas:aCols[3]:nTotal + oBrwIvas:aCols[4]:nTotal +  oBrwRet:aCols[3]:nTotal + base:nograbado) *;
                 IF( oGet[1]:nAt = 5,0,1) 
                       
oGet[42]:Refresh()
RETURN .t.

**********************************************************************************************
STATIC FUNCTION ValidaArt(oDlg1,oGet)

    oQryArt := oApp:oServer:Query("SELECT a.*, i.nombre AS cNomIva, i.tasa AS tasaiva, a.iva AS codiva, a.codigopro AS codigopro, a.uxbulto AS uxbulto FROM ge_"+oApp:cId+"articu a "+;
                                  "LEFT JOIN ge_"+oApp:cId+"ivas i ON a.iva = i.codigo "+;
                                  "WHERE a.codigo = " + ClipValue2SQL(basedet:codart))
    IF oQryArt:RecCount() = 0
       BuscarArt(oQryArt,oDlg1,oGet[17],oGet[18])
    ENDIF
    nIvaArt:= oQryArt:iva
    nCant:= 1
    IF !EMPTY(oQryArt:codigopro) .and. oQryArt:codigopro <> "0" 
       oGet[15]:cText:= oQryArt:codigopro
    ELSE 
       oGet[15]:cText:= SPACE(30)
    ENDIF
    oGet[18]:cText:= oQryArt:nombre
    oGet[19]:cText:= 1
    oGet[20]:cText:= oQryArt:precossiva
    oGet[21]:cText:= oQryArt:precossiva
    basedet:siniva:= oQryArt:siniva

    oQryArt:SetNewFilter(SET_WHERE,"true",.t.)
RETURN .t.

**********************************************************************************************

STATIC FUNCTION AgregarItem(oGet,nTipoComp)
LOCAL oQryDoc,oQryArt
  IF EMPTY(oGet[2]:cText) .or. empty(oGet[3]:cText) .or. empty(oGet[28]:cText) .or. oGet[7]:value =0 .or. oGet[3]:cText = '0000' .or. oGet[28]:cText = '00000000'
     MsgStop("Ingrese los datos del comprobante antes de agregar el detalle","Atencion!")
     RETURN nil 
  ENDIF
  IF basedet:codart > 0 
   oQryArt:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(basedet:codart))
   oQryDoc := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipocomp WHERE codigo = " + ClipValue2Sql(nTipoComp))
   basedet:renglon:=oApp:oServer:GetAutoIncrement("comprasdet_H")
   basedet:codpro:= base:codpro
   basedet:tipocomp:= oQryDoc:prefijo
   basedet:numfac:= base:numfac
   basedet:letra:= base:letra
   basedet:codiva := oQryArt:iva
   basedet:codigopro:= nCodPro
   basedet:desc1:= oQryArt:desc1
   basedet:desc2:= oQryArt:desc2
   basedet:desc3:= oQryArt:desc3
   basedet:desc4:= oQryArt:desc4
   basedet:desc5:= oQryArt:desc5
   IF basedet:siniva
     basedet:neto:= basedet:total
   ELSE
     basedet:neto:= basedet:total / (1+ oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(basedet:codiva)):tasa/100)
   ENDIF

     basedet:neto:= basedet:neto - basedet:neto * ( oQryArt:desc1/100 )
     basedet:neto:= basedet:neto - basedet:neto * ( oQryArt:desc2/100 )
     basedet:neto:= basedet:neto - basedet:neto * ( oQryArt:desc3/100 )
     basedet:neto:= basedet:neto - basedet:neto * ( oQryArt:desc4/100 )
     basedet:neto:= basedet:neto - basedet:neto * ( oQryArt:desc5/100 )
     basedet:iva := basedet:neto * oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(basedet:codiva)):tasa/100
     basedet:total := basedet:neto + basedet:iva
     basedet:neto_unit:= basedet:neto / basedet:cantidad
   

   oQryComprasDet:lAppend:= .t.
   oQryComprasDet:oRow := basedet 
   oQryComprasDet:Save()
   oQryComprasDet:Refresh(.t.)
   oBrwDet:Refresh()
   oBrwDet:GoBottom()
  ENDIF 
   oGet[15]:cText:= SPACE(30)
   oGet[17]:SetFocus()
RETURN .T.

                            
******************************************************************************************************

STATIC FUNCTION ValidaPro(oGet,lAlta,oDlg1)
   LOCAL oQryDeu,oQryCue
   oQryPro := oApp:oServer:Query("SELECT codigo,nombre,alias,localidad,cuit,coniva,codcue,saldo  FROM ge_"+oApp:cId+"provee")
   BuscarArt(oQryPro,oDlg1,oGet[07],oGet[08])
   oQryPro := oApp:oServer:Query("SELECT codigo,nombre,alias,localidad,cuit,coniva,codcue,saldo FROM ge_"+oApp:cId+"provee  WHERE codigo = " + ClipValue2SQL(base:codpro))
   oQryIva := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"tipoiva   WHERE codigo = " + ClipValue2SQL(oQryPro:coniva))   
   oGet[09]:cText:= oQryPro:cuit
   oGet[10]:cText:= oQryIva:nombre
   IF lAlta 
   oQryCue := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"plancont WHERE codigo = " + ClipValue2SQL(oQryPro:codcue))
    oGet[11]:cText:= oQryPro:codcue
    oGet[12]:cText:= oQryCue:nombre
   ELSE
   oQryCue := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"plancont WHERE codigo = " + ClipValue2SQL(oGet[11]:Value))
     oGet[12]:cText:= oQryCue:nombre
   ENDIF
   oQryDeu := oApp:oServer:Query("SELECT SUM(saldo*IF(tipocomp='NC',-1,1)) AS deuda FROM ge_"+oApp:cId+"compras WHERE codpro = " + ClipValue2Sql(base:codpro) +;
                                 " AND saldo > 0 ")
   oGet[13]:cText:= oQryDeu:deuda  - oQryPro:saldo
   oQryPro:End()
   RELEASE oQryPro
RETURN .t.



**********************************************************************************************

STATIC FUNCTION Cancela(oGet)
  oQryComprasDet:ZAP()
  baseDet := oQryComprasDet:GetBlankRow()
  oBrwDet:Refresh()
  oGet[17]:cText:= 0
  oGet[18]:cText:= ""
  oGet[19]:cText:= 0.00
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

IF oQryBrw:saldo < oQryBrw:importe 
  MsgStop("No se puede eliminar el comprobante porque ya tiene un pago imputado","Atencion!")
  RETURN nil
ENDIF

mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el documento Numero "+oQryBrw:letra+" "+oQryBrw:numfac,"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compras WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"compradet c LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;
                       "SET a.stockact = a.stockact - IF(c.tipocomp='NC',c.cantidad*(-1),c.cantidad) " +;
                       "WHERE c.tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND c.letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND c.codpro = " + ClipValue2Sql(oQryBrw:codpro)+" "+;
                       "AND c.numfac = " + ClipValue2Sql(oQryBrw:numfac))
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compradet WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
                       "AND letra = " + ClipValue2Sql(oQryBrw:letra)+" "+;
                       "AND codpro = " + ClipValue2Sql(oQryBrw:codpro)+" "+;
                       "AND numfac = " + ClipValue2Sql(oQryBrw:numfac))
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"compivadet WHERE tipocomp = " + ClipValue2Sql(oQryBrw:tipocomp)+" "+;
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
LOCAL oGet := ARRAY(52), oBot := ARRAY(8), oForm, lRta := .F., aCor, base, cProve:=SPACE(30), nNeto,;
      cIvaNom:=SPACE(30), cMarc:=SPACE(30), cRub:=SPACE(30), cDept:=SPACE(30), cEmp:=SPACE(30), nIva,oError,nPrecioven:=0,;
      nova1,nova2,oSay:=ARRAY(8),oGru:=ARRAY(2),nPreciocos:=0,oQryArt

   oQryArt:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu LIMIT 0")
   base := oQryArt:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"articu")
   base:iva := 5
   oQry3:GoTop()
   IF oQry3:Seek(base:iva,1) > 0
      cIvaNom := STR(oQry3:tasa,6,2) + "%"
   ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Alta de Articulo" RESOURCE "ABMART1" OF oWnd1
 oForm:lHelpIcon := .f.
 
  REDEFINE GET oGet[01] VAR base:codigo PICTURE "99999999999999" ID 100 OF oForm 
  REDEFINE GET oGet[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!"
  REDEFINE SAY oSay[8] ID 4002 OF oForm
  REDEFINE GET oGet[51] VAR base:codigopro ID 4017 OF oForm PICTURE "@!"
  REDEFINE CHECKBOX oGet[46] VAR base:endolares   ID 4012 OF oForm
  REDEFINE CHECKBOX oGet[52] VAR base:pesable ID 4011 OF oForm 
  REDEFINE CHECKBOX oGet[34] VAR base:nosale ID 103 OF oForm 

  REDEFINE GROUP oGru[1] ID 401 OF oForm
  REDEFINE CHECKBOX oGet[44] VAR base:mprima      ID 4007 OF oForm
  REDEFINE CHECKBOX oGet[45] VAR base:produccion  ID 4008 OF oForm
  REDEFINE BUTTON oBot[3] ID 4009 OF oForm ACTION Reseta(base,oForm) WHEN (base:produccion)
  

  REDEFINE GET oGet[04] VAR base:prov ID 104 OF oForm PICTURE "99999";
                VALID(Buscar(oQry2,oForm,oGet[4],oGet[5]));
                ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oForm,oGet[4],oGet[5])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oForm WHEN (.F.)
  REDEFINE GET oGet[21] VAR base:marca      ID 122 OF oForm PICTURE "9999";
               VALID(Buscar(oQry4,oForm,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oForm,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc           ID 123 OF oForm WHEN (.F.)
  REDEFINE GET oGet[23] VAR base:rubro      ID 124 OF oForm PICTURE "9999";
                VALID(Buscar(oQry5,oForm,oGet[23],oGet[24]) .and. (oGet[25]:cText:= oQry5:depto) <> 'XXX' .and. Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oForm,oGet[23],oGet[24]),oGet[25]:cText:= oQry5:depto,Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub            ID 125 OF oForm WHEN (.F.)
  REDEFINE GET oGet[27] VAR base:empresa    ID 126 OF oForm PICTURE "9999";
               VALID(Buscar(oQry7,oForm,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oForm,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp            ID 127 OF oForm WHEN (.F.)
  REDEFINE GET oGet[25] VAR base:depto      ID 128 OF oForm PICTURE "9999";
               VALID(Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept           ID 129 OF oForm WHEN (.F.)

  REDEFINE BUTTON oBot[4] ID 301 OF oForm ACTION AltaMar()
  REDEFINE BUTTON oBot[5] ID 302 OF oForm ACTION AltaRub()
  REDEFINE BUTTON oBot[6] ID 303 OF oForm ACTION AltaEmp()
  REDEFINE BUTTON oBot[7] ID 304 OF oForm ACTION AltaDep()


  REDEFINE GROUP oGru[2] ID 402 OF oForm
  REDEFINE SAY oSay[3] ID 4066 OF oForm 
  REDEFINE SAY oSay[4] ID 4067 OF oForm
  REDEFINE SAY oSay[5] ID 4069 OF oForm
  REDEFINE SAY oSay[6] ID 4070 OF oForm
  REDEFINE SAY oSay[7] ID 4071 OF oForm
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
           WHEN(CalcularNeto(base,@oGet))
           
  REDEFINE GET oGet[12] VAR base:impint     ID 113 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[13] VAR base:flete      ID 114 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[14] VAR base:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet[14]:cText:= 0, (Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
  REDEFINE GET oGet[16] VAR base:preciocos  ID 117 OF oForm PICTURE "999999999.99";
                        WHEN((oGet[16]:cText:= nNeto + nNeto * (base:impint/100) +;
                        nNeto * (base:flete/100) + ((nNeto * oQry3:tasa )/100)) = "-999999")
  REDEFINE GET oGet[17] VAR base:porcentaje ID 118 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.t.))
  REDEFINE GET oGet[18] VAR base:porcentajerev  ID 119 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.f.))
  REDEFINE GET oGet[19] VAR base:reventa    ID 120 OF oForm PICTURE "999999999.99"
  REDEFINE GET oGet[20] VAR base:precioven  ID 121 OF oForm PICTURE "999999999.99"
  
  
    //FECHAS
  REDEFINE SAY oSay[1] ID 801 OF oForm 
  REDEFINE GET oGet[41] VAR nova1          ID 1300 OF oForm
  REDEFINE GET oGet[29] VAR base:fecultcom ID 130 OF oForm WHEN(.F.)
  REDEFINE GET oGet[30] VAR base:fecmod    ID 131 OF oForm WHEN (.F.)
  REDEFINE SAY oSay[2] ID 804 OF oForm
  REDEFINE GET oGet[42] VAR nova2          ID 1311 OF oForm


  REDEFINE GET oGet[31] VAR base:stockmin   ID 132 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[33] VAR base:stockide   ID 134 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[36] VAR base:observa    ID 136 OF oForm PICTURE "@!"

  REDEFINE BUTTON oBot[1] ID 137 OF oForm PROMPT "&Grabar";
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet[01]:SetFocus(),EsconderPermisos(oGet,oSay,oGru,oBot))
IF !lRta
   RETURN nil
ENDIF
IF base:preciocos = 0 .or. base:iva = 0
   msginfo("Campos obligatorios como 'Precio costo' e 'IVA' tienen que estar completos","Atencion!")
   LOOP
ENDIF

IF nPrecioven <> base:precioven .OR. nPreciocos <> base:preciocos 
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                        "VALUES ("+ClipValue2Sql(base:codigo)+","+ClipValue2Sql(base:preciocos)+","+;
                        ClipValue2Sql(base:precossiva)+","+ClipValue2Sql(base:precioven)+","+ClipValue2Sql(base:reventa)+",CURDATE() ,"+;
                        ClipValue2Sql(oApp:usuario)+",'Cambio x compras')")
ENDIF

base:porcentaje := (base:precioven * 100) / base:preciocos - 100
base:porcentajerev := (base:reventa * 100) / base:preciocos - 100

base:usuario:= oApp:usuario
base:fecmod := DATE()
base:ip     := oApp:cIp
oQryArt:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryArt:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*************************************************************************************************************
********* Calular precio venta
STATIC FUNCTION CalcularPrecio(oGet,base,lventa)
IF lventa
   oGet[20]:cText:=INT(base:preciocos + (base:preciocos * base:porcentaje)/100)
ELSE
   oGet[19]:cText:=INT(base:preciocos + (base:preciocos * base:porcentajerev)/100)
ENDIF
RETURN .t.



******************************************
** Calculo del precio de venta
STATIC FUNCTION calcupre(lis,costo,marca,codiva)
LOCAL iv, precio, por,oQryAux
oQryAux:=oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(codiva))
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
   
oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee")
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
   oBrw:Maketotals()
   oBrw:Refresh()
RETURN nil

*******************************************************************************************
******* MOSTRAR PEDIDOS A FACTURAR
STATIC FUNCTION BuscaPedidos(base,oGet)
LOCAL oDlg1,oBrwRem,oQryRem,oBot1,oBot2,acor:=ARRAY(4),mRta:=.f., cRemitos := ""
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS pedidosp_temp ";
    +"( `NUMPED` INT(10) NOT NULL, ";
    +"`TILDE` TINYINT(1),";
    +"`FECHA` DATE NOT NULL,";  
    +"`IMPORTE` DECIMAL(12,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`NUMPED`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE pedidosp_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("INSERT INTO pedidosp_temp (tilde,numped,fecha) "+;
                     "(SELECT 0,id,fecha "+;
                     "FROM ge_"+oApp:cId+"pedprov "+;
                     "WHERE codpro = "+ClipValue2Sql(base:codpro)+")")
oQryRem:= oApp:oServer:Query("SELECT * FROM pedidosp_temp ORDER BY fecha,numped")

DEFINE DIALOG oDlg1 TITLE "Pedidos a facturar" OF oWnd1 FROM 05,15 TO 21,65
    oDlg1:lHelpIcon:=.f.

@ 05,05 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "tilde","numped","fecha";    
                 HEADERS " ","Numero","Fecha";
                 SIZES 40,120,70;
         OF oDlg1 SIZE 190,97 PIXEL 
oQryRem:bOnChangePage := {|| oBrwRem:Refresh() }
oBrwRem:aCols[1]:SetCheck(nil,.f.)   
oBrwRem:aCols[1]:bLDClickData := {|| CambiaChek(oQryRem,oBrwRem)}
oBrwRem:aCols[1]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oQryRem,oBrwRem))}
oBrwRem:aCols[1]:nEditType := 1
oBrwRem:aCols[1]:bEditValue:= {|| IF(oQryRem:tilde,.t.,.f.) }
oBrwRem:CreateFromcode()
PintaBrw(oBrwRem,0)

oBrwRem:bKeyDown = { | nKey, nFlags | IF(nKey==13,oBot1:Click,.f.) }

acor := AcepCanc(oDlg1)
@ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
@ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwRem:SetFocus()

IF !mRta
  RETURN nil 
ENDIF

oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE comprasdet_H")
oApp:oServer:NextResult()


oApp:oServer:Execute("INSERT INTO comprasdet_H (codpro,tipocomp,letra,numfac,codart,detart,siniva,punit,"+;
                                 "desc1,desc2,desc3,desc4,desc5,neto_unit,neto,iva,total,cantidad,codiva,codigopro)"+;
                      " (SELECT "+ClipValue2Sql(base:codpro)+",'FC','X','0000-0000000',codart,detart,true,punit,descuento,"+;
                      "0,0,0,0,punit,punit*cantidad,punit*cantidad*0.21,punit*cantidad*0.21+punit*cantidad,cantidad,5,'' "+;                      
                      "FROM ge_"+oApp:cId+"pedprov_det  "+;
                      "WHERE numero IN (SELECT numped FROM pedidosp_temp WHERE tilde = 1 ) )")
oApp:oServer:NextResult()
oQryComprasDet:Refresh()
oBrwDet:Refresh()
CalcTot(oGet,.T.)
oBrwDet:MakeTotals()
oQryRem:GoTop()
DO WHILE !oQryRem:Eof()
   IF oQryRem:tilde 
      AADD(lUsoPedido,oQryRem:numped)
   ENDIF
   oQryRem:Skip()   
ENDDO
RETURN nil

**************************************
STATIC FUNCTION CambiaChek(oQry1,oBrw1)
LOCAL valor
valor := IF(oQry1:tilde=.f.,.t.,.f.)
oQry1:tilde := valor
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil