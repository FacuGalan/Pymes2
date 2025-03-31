#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
**ASIGNACION DE FACTURAS A CAMIONEROS
*************************************************
MEMVAR oApp
STATIC oDlg,oBrw,oQry,oGet,cNomCam,nCamionero
PROCEDURE ASIREPAR()
LOCAL mrta := .f.,nCodCam:=0,nCodBar:=0,oQryCam,oBot:=ARRAY(3),oError, nCartaPorte, oQryAux, dFecha
oGet:=ARRAY(3)
cNomCam:=SPACE(50)
nCamionero:=0
// TABLA TEMPORAL DE DEUDA
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_fact` ("+;
                           "`id` int(10) NOT NULL AUTO_INCREMENT ,"+;
                           "`ticomp` VARCHAR(2) NOT NULL,"+;
                           "`letra` VARCHAR(1) NOT NULL,"+;
                           "`numcomp` VARCHAR(14) NOT NULL,"+;
                           "`fecha` DATE NOT NULL,"+;
                           "`codbar` INT(8) NOT NULL,"+;
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`cliente` VARCHAR(50) DEFAULT 0 NOT NULL,"+;
                           "`deuda` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "PRIMARY KEY (id,ticomp,letra,numcomp) ) ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_fact")
oApp:oServer:NextResult()

oQryCam:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"reparto")
dFecha := oApp:oServer:Query("SELECT CURDATE() AS fecha FROM ge_"+oApp:cId+"reparto LIMIT 1"):fecha

   oQry:= oApp:oServer:Query("SELECT * FROM transi_fact")
   DEFINE DIALOG oDlg RESOURCE "ASIGNA" OF oApp:oWnd
    oDlg:lHelpIcon := .f.
    
    REDEFINE GET oGet[1] VAR nCodCam ID 101 OF oDlg PICTURE "999";
                 VALID(Buscar(oQryCam,oDlg,oGet[1],oGet[2]) .and. BorrarDet(nCodCam));
                 ACTION (oGet[1]:cText:= 0, Buscar(oQryCam,oDlg,oGet[1],oGet[2]),BorrarDet(nCodCam)) BITMAP "BUSC1"
    REDEFINE GET oGet[2] VAR cNomCam ID 102 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR nCodBar ID 103 OF oDlg PICTURE "999999999999";
                 VALID(IF(CargarCodigo(nCodBar,nCodCam),oGet[3]:SetFocus(),nil) = NIL)

    REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ticomp","letra","numcomp","fecha","cliente","importe";
              HEADERS "Tipo","Let","Nro. Compr.","Fecha","Cliente","Importe" FOOTERS;
              SIZES 30,20,100,80,173,80 ID 300 OF oDlg       
    PintaBrw(oBrw,0)    
    oBrw:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(oQry:Delete(),;
                                  oBrw:MakeTotals(),oBrw:Refresh(),oGet[3]:SetFocus()),.t.) } 
    oBrw:aCols[1]:nFooterTypE := AGGR_COUNT
    oBrw:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw:MakeTotals()


    REDEFINE BUTTON oBot[1] ID 202 OF oDlg ACTION (oDlg:End(),mrta:=.t.)
    REDEFINE BUTTON oBot[2] ID 203 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
   ACTIVATE DIALOG oDlg CENTER ON INIT oGet[1]:SetFocus()
   IF !mrta
      RETURN  
   ENDIF

TRY
  oApp:oServer:BeginTransaction()
  oQryAux := oApp:oServer:Query("SELECT cartaporte AS carta FROM ge_"+oApp:cId+"ventas_encab "+;
                                   " WHERE  fechaasig = CURDATE() "+;
                                   " AND codrep = "+ClipValue2Sql(nCodCam))
  IF oQryAux:nRecCount > 0 
     mrta := MsgYesNo("Ya existe una carta de porte para este dia"+chr(10)+;
                      "para este repartidor. Desea agregar la asignacion"+chr(10)+;
                      "a la carta de porte Nro "+STR(oQryAux:carta,5)+"?","Atencion!")
     IF mrta 
        nCartaPorte := oQryAux:carta
        ELSE
        nCartaPorte  := oApp:oServer:Query("SELECT MAX(cartaporte)+1 AS carta FROM ge_"+oApp:cId+"ventas_encab"):carta
     ENDIF
     ELSE
     nCartaPorte  := oApp:oServer:Query("SELECT MAX(cartaporte)+1 AS carta FROM ge_"+oApp:cId+"ventas_encab"):carta        
  ENDIF   
  oApp:oServer:Execute("UPDATE transi_fact t LEFT JOIN ge_"+oApp:cId+"ventas_encab v "+;
                       "ON v.codbarra = t.codbar "+;
                       " SET v.codrep = "+ClipValue2Sql(nCodCam)+;
                       ", v.fechaasig =  "+ ClipValue2Sql(dFecha) + ;
                       ", v.cartaporte = "+ClipValue2Sql(nCartaPorte))
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
    RETURN
END TRY
IF oQry:nRecCount > 0 
   Planilla(nCartaPorte)
ENDIF
Cerrar(oGet[1],oDlg)

RETURN


**************************************************************************************************************************
************ 
STATIC FUNCTION BorrarDet(nCodCam)
LOCAL lResp
IF nCodCam <> nCamionero
    
    IF oQry:RecCount() > 0
       lResp:= MsgNoYes("Hay facturas cargadas sin guardar ¿desea seleccionar otro reparto sin guardarlas?","Atencion!")
       
       IF lResp
          oApp:oServer:Execute("TRUNCATE transi_fact")
          oQry:Refresh()
          oBrw:Refresh()
          nCamionero:= nCodCam
       ELSE 
          oGet[1]:cText:= nCamionero
          oGet[2]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"reparto WHERE codigo = "+ClipValue2Sql(nCamionero))
       ENDIF

    ELSE
       nCamionero:= nCodCam
    ENDIF
oBrw:GoBottom()
oBrw:MakeTotals()
ENDIF
RETURN .T.

***********************************************************************************************************************
***** AGREGO FACTURA AL DETALLE 
STATIC FUNCTION CargarCodigo(nCodBar,nCodCam)
LOCAL oQryAux,lResp
IF nCodBar = 0
   RETURN .F.
ENDIF
IF oApp:oServer:Query("SELECT * FROM transi_fact WHERE codbar = "+ClipValue2Sql(int(nCodBar*.1))):RecCount() = 0

    oQryAux:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE codbarra = "+ClipValue2Sql(int(nCodBar*.1))+" LIMIT 1")

    IF oQryAux:RecCount() = 0
       MsgStop("Factura no encontrada, codigo de barras inexistente","Error")
       RETURN .T. 
    ENDIF
    
    IF oQryAux:codrep > 0 .and. oQryAux:codrep <> nCodCam
       lResp := MsgYesNo("La factura esta asignada al reparto N° "+STR(oQryAux:codrep)+CHR(10)+;
                         "del dia "+DTOC(oQryAux:fechaasig)+chr(10)+;
                         "¿Desea reasignarla a este reparto?","Atencion!")
       IF !lResp
          RETURN .T. 
       ENDIF
    ENDIF
    IF oQryAux:codrep > 0 .and. oQryAux:codrep = nCodCam
       lResp := MsgYesNo("La factura ya fue asignada a este reparto el dia "+DTOC(oQryAux:fechaasig)+CHR(10)+;
                         "¿Desea reasignarla con fecha de hoy?","Atencion!")
       IF !lResp
          RETURN .T. 
       ENDIF
    ENDIF
    oApp:oServer:Execute("INSERT INTO transi_fact (ticomp,letra,numcomp,fecha,cliente,importe,codbar) "+;
                         "(SELECT v.ticomp,v.letra,v.numcomp,v.fecha,c.nombre,v.importe,v.codbarra FROM ge_"+oApp:cId+"ventas_encab v "+;
                          "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;
                          "WHERE v.codbarra = "+ClipValue2Sql(int(nCodBar*.1))+")")
ENDIF
oGet[3]:cText:= 0
oQry:Refresh()
oBrw:GoBottom()
oBrw:Refresh()
oBrw:MakeTotals()
RETURN .T.

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.

************************************************************
** Listado de planilla
STATIC FUNCTION Planilla(nCartaPorte)
LOCAL oQryRep, oQryFac, oQryRepa, nTotDeu,;
      i, x, y, oPrn, nRow, oFont, oFont2, oFont1, oFont3, config, nHoja := 1, aCor
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_fact_det` ("+;
                           "`id` int(10) NOT NULL AUTO_INCREMENT ,"+;
                           "`codart` BIGINT(14) NOT NULL,"+;
                           "`detart` VARCHAR(50) NOT NULL,"+;
                           "`vendidos` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`devueltos` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "PRIMARY KEY (id) ) ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1")
oApp:oServer:Execute("TRUNCATE transi_fact_det")
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_fact1` ("+;
                           "`codcli` int(10) NOT NULL ,"+;                           
                           "`cliente` VARCHAR(250) DEFAULT 0 NOT NULL,"+;
                           "`facturas` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`presupuestos` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`deuda` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "PRIMARY KEY (codcli) ) ENGINE=INNODB")
oApp:oServer:Execute("TRUNCATE transi_fact1")
//Leo las facturas de la carta de porte
oQryFac := oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"ventas_encab WHERE cartaporte = "+ClipValue2Sql(nCartaPorte))
oQryRepa := oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"reparto WHERE codigo = "+ClipValue2Sql(oQryFac:codrep))
IF oQryFac:nRecCount = 0
   MsgStop("Hoja de Ruta No EXISTE","Error")
   RETURN nil 
ENDIF 
DO WHILE !oQryFac:Eof()
   IF oApp:oServer:Query("SELECT codcli FROM transi_fact1 WHERE codcli = " + ClipValue2Sql(oQryFac:codcli)):nReccount > 0
      //Sumar
      IF oQryFac:letra = "X"
         oApp:oServer:Execute("UPDATE transi_fact1 SET presupuestos = presupuestos + " +;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe)) +;
               " WHERE codcli =  " + ClipValue2Sql(oQryFac:codcli))
         ELSE
         oApp:oServer:Execute("UPDATE transi_fact1 SET facturas = facturas + " +;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe)) +;
               " WHERE codcli =  " + ClipValue2Sql(oQryFac:codcli))       
      ENDIF         
      ELSE 
      //Agregar
      IF oQryFac:letra = "X"
         oApp:oServer:Execute("INSERT INTO transi_fact1 (codcli,cliente,facturas,presupuestos,deuda) VALUES ("+;
               ClipValue2Sql(oQryFac:codcli)+","+;
               ClipValue2Sql(ALLTRIM(oQryFac:nombre)+" - "+ALLTRIM(oQryFac:direccion)+" - "+ALLTRIM(oQryFac:localidad))+","+; 
               ClipValue2Sql(0)+","+;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe))+",0)")
         ELSE
         oApp:oServer:Execute("INSERT INTO transi_fact1 (codcli,cliente,facturas,presupuestos,deuda) VALUES ("+;
               ClipValue2Sql(oQryFac:codcli)+","+;
               ClipValue2Sql(ALLTRIM(oQryFac:nombre)+" - "+ALLTRIM(oQryFac:direccion)+" - "+ALLTRIM(oQryFac:localidad))+","+; 
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe))+",0,0)")         
      ENDIF         
   ENDIF 
   //Agrego los articulos
   IF oQryFac:ticomp = "FC"  
      oApp:oServer:Execute("INSERT INTO transi_fact_det (codart,detart,vendidos) "+;
        " (SELECT codart,detart,cantidad FROM ge_"+oApp:cId+"ventas_det WHERE NROFAC = "+;
        ClipValue2Sql(oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp)+")")
      ELSE
      oApp:oServer:Execute("INSERT INTO transi_fact_det (codart,detart,devueltos) "+;
        " (SELECT codart,detart,cantidad FROM ge_"+oApp:cId+"ventas_det WHERE NROFAC = "+;
        ClipValue2Sql(oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp)+")")      
   ENDIF
   oQryFac:Skip()   
ENDDO   
oQryFac := oApp:oServer:Query("SELECT *  FROM transi_fact1")
DO WHILE !oQryFac:Eof()
   nTotDeu := oApp:oServer:Query("SELECT SUM(saldo * IF(tipo='NC',-1,1)) as totdeu "+;
             " FROM ge_"+oApp:cId+"ventas_cuota WHERE cliente = "+ClipValue2Sql(oQryFac:codcli)):totdeu
   oQryFac:deuda := nTotDeu
   oQryFac:Save()
   oQryFac:Skip()   
ENDDO   
oQryFac:GoTop()
oQryRep := oApp:oServer:Query("SELECT codart,detart,SUM(vendidos) as vendidos, SUM(devueltos) as devueltos "+;
           "  FROM transi_fact_det GROUP BY codart,detart")
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
//Hoja de ruta   
   DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
   DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
   DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
   PRINT oPrn NAME "Hoja de Ruta "+STR(nCartaPorte) PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
     PAGE
     nHoja := 1     
     nRow := (oPrn:nHorzRes() / 80) / 47     
     oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
     @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
              SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
     oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
     oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
     oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
     IF config:x1 = 2 .or. config:x1 = 3
        @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
     ENDIF
     IF config:x1 = 1 .or. config:x1 = 3
         @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                  SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
         @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
         
     ENDIF
     oPrn:CmSay( 1.7  , 11, "HOJA DE RUTA", oFont1 )   
     oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
     oPrn:CmSay( 1.5, 9.8, "X",oFont2)
     oPrn:CmSay( 2.0, 16, "N°: "+STR(nCartaPorte),oFont)         
     oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
     oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
     oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
     oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)
     @ 5.5, 1   PRINT TO oPrn TEXT "Reparto:" ;
              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
     @ 5.5, 4.1 PRINT TO oPrn TEXT STR(oQryRepa:codigo);
              SIZE 6,.5 CM FONT oFont ALIGN "L"
     @ 5.5, 9.5  PRINT TO oPrn TEXT "Nombre:" ;
              SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
     @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryRepa:nombre) ;
              SIZE 8,1 CM FONT oFont LASTROW nRow      
     
     @ 7.5, 01 PRINT TO oPrn TEXT "Productos" ;
              SIZE 20,.5 CM FONT oFont1 ALIGN "C"
     @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
              SIZE 7,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 11 PRINT TO oPrn TEXT "Vendidos" ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 14 PRINT TO oPrn TEXT "Devueltos" ;
              SIZE 2.1,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 17 PRINT TO oPrn TEXT "Total" ;
              SIZE 3,.5 CM FONT oFont ALIGN "R"
     y := 9.2
     oQryRep:GoTop()
           
     FOR i = 1 TO oQryRep:nRecCount                               
         @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryRep:codart,14) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "L"
         @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryRep:detart) ;
              SIZE 7,1.5 CM FONT oFont LASTROW nRow 
         @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryRep:vendidos,08,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryRep:devueltos,08,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryRep:vendidos-oQryRep:devueltos,08,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "R"              
         y := nRow + .1
         IF y > 26
             @ 26.5, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
             IF config:x1 = 2 .or. config:x1 = 3
                @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
             ENDIF
             IF config:x1 = 1 .or. config:x1 = 3
                 @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                          SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                 @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                 
             ENDIF
             oPrn:CmSay( 1.7  , 11, "HOJA DE RUTA", oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             oPrn:CmSay( 1.5, 9.8, "X",oFont2)
             oPrn:CmSay( 2.0, 16, "N°: "+STR(nCartaPorte),oFont)         
             oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
             oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
             oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
             oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)
             @ 5.5, 1   PRINT TO oPrn TEXT "Reparto:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 4.1 PRINT TO oPrn TEXT STR(oQryRepa:codigo);
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 5.5, 9.5  PRINT TO oPrn TEXT "Nombre:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryRepa:nombre) ;
                      SIZE 8,1 CM FONT oFont LASTROW nRow      
             

             @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                      SIZE 2.8,.5 CM FONT oFont ALIGN "L"
             @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                      SIZE 7,.5 CM FONT oFont ALIGN "L"
             @ 8.2, 11 PRINT TO oPrn TEXT "Vendidos" ;
                      SIZE 2,.5 CM FONT oFont ALIGN "R"
             @ 8.2, 14 PRINT TO oPrn TEXT "Devueltos" ;
                      SIZE 2.1,.5 CM FONT oFont ALIGN "R"
             @ 8.2, 17 PRINT TO oPrn TEXT "Total" ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
             y := 9.2
         ENDIF
         oQryRep:Skip()
      NEXT    
      y := y + 1
      oQryFac:GoTop()
       
       @ y, 01 PRINT TO oPrn TEXT "Clientes" ;
              SIZE 20,.5 CM FONT oFont1 ALIGN "C" LASTROW y
       oPrn:CmBox(   y, .5, y+1, 20.5 ) // Box titulos
       y := y + .2
       @ y, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 1,.5 CM FONT oFont ALIGN "L"
       @ y, 02.1 PRINT TO oPrn TEXT "Cliente" ;
                SIZE 8.9,.5 CM FONT oFont ALIGN "L"                
       @ y, 11 PRINT TO oPrn TEXT "Facturas" ;
                SIZE 2,.5 CM FONT oFont ALIGN "R"
       @ y, 13.5 PRINT TO oPrn TEXT "Presupuestos" ;
                SIZE 2.1,.5 CM FONT oFont ALIGN "R"
       @ y, 15.3 PRINT TO oPrn TEXT "Entrega" ;
                SIZE 2.1,.5 CM FONT oFont ALIGN "R"         
       @ y, 17.5 PRINT TO oPrn TEXT "Saldo Actual" ;
                SIZE 2.5,.5 CM FONT oFont ALIGN "R"     
       y := y + 1.2
      FOR i = 1 TO oQryFac:nRecCount                               
         @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryFac:codcli,06) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "L"
         @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryFac:cliente) ;
              SIZE 7,1.5 CM FONT oFont LASTROW nRow 
         @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryFac:facturas,12,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryFac:presupuestos,12,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryFac:deuda,12,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "R"              
         y := nRow + .1
         IF y > 26
             @ 26.5, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             IF config:x1 = 2 .or. config:x1 = 3
                @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
             ENDIF
             IF config:x1 = 1 .or. config:x1 = 3
                 @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                          SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                 @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                 
             ENDIF
             oPrn:CmSay( 1.7  , 11, "HOJA DE RUTA", oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             oPrn:CmSay( 1.5, 9.8, "X",oFont2)
             oPrn:CmSay( 2.0, 16, "N°: "+STR(nCartaPorte),oFont)         
             oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
             oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
             oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
             oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)
             @ 5.5, 1   PRINT TO oPrn TEXT "Reparto:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 4.1 PRINT TO oPrn TEXT STR(oQryRepa:codigo);
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 5.5, 9.5  PRINT TO oPrn TEXT "Nombre:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryRepa:nombre) ;
                      SIZE 8,1 CM FONT oFont LASTROW nRow      
             
             y := 8.2
             @ y, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
             @ y, 04 PRINT TO oPrn TEXT "Cliente" ;
                      SIZE 7,.5 CM FONT oFont ALIGN "L"
             @ y, 11 PRINT TO oPrn TEXT "Facturas" ;
                      SIZE 2,.5 CM FONT oFont ALIGN "R"
             @ y, 14 PRINT TO oPrn TEXT "Presupuestos" ;
                      SIZE 2.1,.5 CM FONT oFont ALIGN "R"
             @ y, 17 PRINT TO oPrn TEXT "Saldo Actual" ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R" 
             y := 9.2
         ENDIF
         oQryFac:Skip()
      NEXT   
      
     ENDPAGE
  ENDPRINT
// Nuevo para cliente nuevo
  DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon*.7,config:fon*2.5
  PRINT oPrn NAME "Hoja de Ruta "+STR(nCartaPorte) + " Entregas" PREVIEW MODAL
     oPrn:SetLandscape()
     oPrn:SetPage(9)
     PAGE
     nHoja := 1     
     nRow := (oPrn:nHorzRes() / 80) / 47     

     //oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
     //oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
     
     oPrn:CmSay( 1.7  , 11, "HOJA DE RUTA", oFont1 )   
     oPrn:CmSay( 1.5, 9.8, "X",oFont2)
     oPrn:CmSay( 2.0, 16, "N°: "+STR(nCartaPorte),oFont)         
     oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)          
     @ 3.0, 1   PRINT TO oPrn TEXT "Reparto:" ;
              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
     @ 3.0, 4.1 PRINT TO oPrn TEXT STR(oQryRepa:codigo);
              SIZE 6,.5 CM FONT oFont ALIGN "L"
     @ 3.0, 9.5  PRINT TO oPrn TEXT "Nombre:" ;
              SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
     @ 3.0, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryRepa:nombre) ;
              SIZE 8,1 CM FONT oFont LASTROW nRow      
          
       y := 3.5
       oQryFac := oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"ventas_encab WHERE cartaporte = "+ClipValue2Sql(nCartaPorte))
       oQryFac:GoTop()
              
       @ y, .5 PRINT TO oPrn TEXT "Fecha" ;
              SIZE 1,.5 CM FONT oFont ALIGN "L"
       @ y, 01.6 PRINT TO oPrn TEXT "Cliente" ;
                SIZE 8.0,.5 CM FONT oFont ALIGN "L"                
       @ y, 10.0 PRINT TO oPrn TEXT "Comprobante" ;
                SIZE 2,.5 CM FONT oFont ALIGN "R"
       @ y, 11.5 PRINT TO oPrn TEXT "Importe" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"
       @ y, 13.0 PRINT TO oPrn TEXT "Devolucion" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"         
       @ y, 14.5 PRINT TO oPrn TEXT "Entrega" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"
       @ y, 16.0 PRINT TO oPrn TEXT "A Cobrar" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"  
       @ y, 17.5 PRINT TO oPrn TEXT "Cza.Anter." ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"   
       @ y, 19.0 PRINT TO oPrn TEXT "N.Cobrado" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"
       @ y, 20.5 PRINT TO oPrn TEXT "Efectivo" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"
       @ y, 22.0 PRINT TO oPrn TEXT "M.Pago" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"
       @ y, 23.5 PRINT TO oPrn TEXT "Tras/Cheque" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"  
       @ y, 25.0 PRINT TO oPrn TEXT "Com.Entrega" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"   
       @ y, 26.5 PRINT TO oPrn TEXT "Com.Venta" ;
                SIZE 1.4,.5 CM FONT oFont ALIGN "R"    
       y := y + .7
      FOR i = 1 TO oQryFac:nRecCount                               
         @ y-0.07, .5 PRINT TO oPrn TEXT DTOC(oQryFac:fecha) ;
                      SIZE 1.1,.5 CM FONT oFont ALIGN "TL"
         @ y-0.07, 01.7 PRINT TO oPrn TEXT ALLTRIM(oQryFac:nombre)+" - "+ALLTRIM(oQryFac:direccion) ;
              SIZE 8,1.5 CM FONT oFont LASTROW nRow ALIGN "TL"
         @ y-0.07, 10 PRINT TO oPrn TEXT oQryFac:numcomp ;
              SIZE 2,.5 CM FONT oFont ALIGN "TR"
         @ y-0.07, 11.5 PRINT TO oPrn TEXT STR(oQryFac:importe,12,2) ;
                  SIZE 1.4,.5 CM FONT oFont ALIGN "TR"
         
         y := nRow + .1
         IF y > 26
             @ 26.5, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       oPrn:CmSay( 1.7  , 11, "HOJA DE RUTA", oFont1 )   
                       oPrn:CmSay( 1.5, 9.8, "X",oFont2)
                       oPrn:CmSay( 2.0, 16, "N°: "+STR(nCartaPorte),oFont)         
                       oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)          
                       @ 3.0, 1   PRINT TO oPrn TEXT "Reparto:" ;
                                SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                       @ 3.0, 4.1 PRINT TO oPrn TEXT STR(oQryRepa:codigo);
                                SIZE 6,.5 CM FONT oFont ALIGN "L"
                       @ 3.0, 9.5  PRINT TO oPrn TEXT "Nombre:" ;
                                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
                       @ 3.0, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryRepa:nombre) ;
                                SIZE 8,1 CM FONT oFont LASTROW nRow      
                            
                         y := 3.5
                    @ y, .5 PRINT TO oPrn TEXT "Fecha" ;
                          SIZE 1,.5 CM FONT oFont ALIGN "L"
                   @ y, 01.6 PRINT TO oPrn TEXT "Cliente" ;
                            SIZE 8.0,.5 CM FONT oFont ALIGN "L"                
                   @ y, 10.0 PRINT TO oPrn TEXT "Comprobante" ;
                            SIZE 2,.5 CM FONT oFont ALIGN "R"
                   @ y, 11.5 PRINT TO oPrn TEXT "Importe" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
                   @ y, 13.0 PRINT TO oPrn TEXT "Devolucion" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"         
                   @ y, 14.5 PRINT TO oPrn TEXT "Entrega" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
                   @ y, 16.0 PRINT TO oPrn TEXT "A Cobrar" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"  
                   @ y, 17.5 PRINT TO oPrn TEXT "Cza.Anter." ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"   
                   @ y, 19.0 PRINT TO oPrn TEXT "N.Cobrado" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
                   @ y, 20.5 PRINT TO oPrn TEXT "Efectivo" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
                   @ y, 22.0 PRINT TO oPrn TEXT "M.Pago" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
                   @ y, 23.5 PRINT TO oPrn TEXT "Tras/Cheque" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"  
                   @ y, 25.0 PRINT TO oPrn TEXT "Com.Entrega" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"   
                   @ y, 26.5 PRINT TO oPrn TEXT "Com.Venta" ;
                            SIZE 1.4,.5 CM FONT oFont ALIGN "R"
             y := y + 1.2
         ENDIF
         oQryFac:Skip()
      NEXT   
      
     ENDPAGE


   ENDPRINT
RETURN nil

///Repòrte de Hojas de ruta
FUNCTION LISASIREP
LOCAL oRep, oFont1, oFont2, oFont3, oQryRep, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oBot3, oBot4, oQryVen,;
      cVendedor, aVen, oBrwVen,i,j,mvende, mdesde := DATE(), mhasta := DATE(),;
      oGru, lReimp, nCartaPorte := 0, lOrden := .f., lResumen := .f.
oQryVen:= oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"reparto ORDER BY nombre") 
aVen   := {}
DO WHILE !oQryVen:Eof()
   AADD(aVen,{.t.,oQryVen:Nombre, oQryVen:codigo})
   oQryVen:Skip()
ENDDO  

DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,8
DEFINE DIALOG oDlg1 TITLE "Asignaciones por repartidor" FROM 03,15 TO 23,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 22, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Repartos a Incluir:" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 67,130 SAY "Hoja de Ruta Nro:   " OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 05, 65 CHECKBOX oGet[5] VAR lReimp PROMPT "Reimprimir Hoja de Ruta" SIZE 120,12 OF oDlg1 PIXEL   
   @ 20, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 35, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) WHEN(!lReimp)
   @ 95,130 BUTTON oBot4 PROMPT "ORDEN TRABAJO" ACTION (lOrden := .t., oDlg1:End()) PIXEL SIZE 60,25 OF oDlg1
   @ 35,165 CHECKBOX oGet[3] VAR lResumen PROMPT "Resumido" SIZE 100,12 OF oDlg1 PIXEL WHEN(!lReimp)
   @ 50,130 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aVen,oBrwVen) PIXEL SIZE 20,10 OF oDlg1
   @ 50, 05 XBROWSE oBrwVen SIZE 125,80 pixel OF oDlg1 ARRAY aVen ;
      HEADERS "Incluir", "Repartidor","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER AUTOSORT 
   WITH OBJECT oBrwVen
      :aCols[ 1 ]:nEditType := EDIT_GET
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwVen,0)
   @ 80,150 GET oGet[6] VAR nCartaPorte PICTURE "99999" OF oDlg1 PIXEL RIGHT WHEN(lReimp)   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF lOrden
   OrdTra()
   RETURN nil
ENDIF
IF !mrta   
   RETURN nil
ENDIF 
IF lReimp
   Planilla(nCartaPorte)
   RETURN nil 
ENDIF    
cVendedor := "("
FOR i := 1 TO LEN(aVen)
    IF aVen[i,1]
       cVendedor := cVendedor + IF(cVendedor=="(","",",") + STR(aVen[i,3])  
    ENDIF
NEXT i
cVendedor := cVendedor + ")"
    IF !lResumen
      oQryRep := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra,v.numcomp) AS compro, "+;
                                    "v.fecha AS fecha, v.fechaasig AS fecasi, c.nombre as nombre, v.codcli AS codcli, "+;
                                    "r.nombre as repar, v.cartaporte,"+;
                                    "(v.importe)*IF(v.ticomp='NC',-1,1) as importe " +;                                   
                                    " FROM ge_"+oApp:cId+"ventas_encab v "+;
                                    "INNER JOIN ge_"+oApp:cId+"reparto r ON v.codrep = r.codigo "+;
                                    "INNER JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;                              
                                    "WHERE v.fechaasig >= "+ClipValue2Sql(mdesde)+" AND "+;
                                    "      v.fechaasig <= "+ClipValue2Sql(mhasta)+" AND "+;
                                    "v.codrep IN "+cVendedor+" ORDER BY r.nombre,v.fechaasig" )      
      REPORT oRep TITLE "Asignaciones por reparto " + ;
                        DTOC(mdesde) + " al " + DTOC(mhasta) ;
             HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Asignaciones de " + cVendedor CENTER ;
             PREVIEW CAPTION  "Asignaciones por Reparto"    
      GROUP oGru ON oQryRep:repar HEADER oQryRep:repar FOOTER "Total Repartidor"  

      COLUMN TITLE "Nro.Fact." DATA oQryRep:compro   SIZE 15  
      COLUMN TITLE "Hoja Ruta" DATA oQryRep:cartaporte SIZE 10  
      COLUMN TITLE "Fecha"     DATA oQryRep:fecha    PICTURE "@D"   SIZE 10    
      COLUMN TITLE "Fecha Ent" DATA oQryRep:fecasi   PICTURE "@D"   SIZE 10    
      COLUMN TITLE "Importe"   DATA oQryRep:importe  PICTURE "99999999.99" ;
                                  SIZE 10  TOTAL
      COLUMN TITLE "Sin IVA"   DATA oQryRep:importe/1.21  PICTURE "99999999.99" ;
                                  SIZE 10  TOTAL

      // Digo que el titulo lo escriba con al letra 2

      oRep:bInit := {|| oQryRep:GoTop() }
      oRep:bSkip := {|| oQryRep:Skip() }
      END REPORT
      // Activo el reporte
      ACTIVATE REPORT oRep WHILE !oQryRep:EOF() ON INIT CursorArrow();
                      ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.5,.5);
                      ON POSTGROUP oRep:NewLine()
      oQryRep:End()
    ELSE
      oQryRep := oApp:oServer:Query("SELECT COUNT(v.ticomp) AS casos, "+;                                   
                                    "r.nombre as repar,"+;
                                    "SUM((v.importe)*IF(v.ticomp='NC',-1,1)) as importe " +;
                                    " FROM ge_"+oApp:cId+"ventas_encab v "+;
                                    "INNER JOIN ge_"+oApp:cId+"reparto r ON v.codrep = r.codigo "+;
                                    "INNER JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;                              
                                    "WHERE v.fechaasig >= "+ClipValue2Sql(mdesde)+" AND "+;
                                    "      v.fechaasig <= "+ClipValue2Sql(mhasta)+" AND "+;
                                    "v.codrep IN "+cVendedor+" GROUP BY v.codrep ORDER BY r.nombre" )
      DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,24
      DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,8
      REPORT oRep TITLE "Asignaciones por reparto (Resumen)" + ;
                        DTOC(mdesde) + " al " + DTOC(mhasta) ;
             HEADER OemToAnsi(oApp:nomb_emp) , ;
             "Asignaciones de " + cVendedor CENTER FONT oFont,oFont1 ;
             PREVIEW CAPTION  "Asignaciones por Reparto (Resumen)"    
      COLUMN TITLE "Repartidor" DATA oQryRep:repar   SIZE 25  FONT 1 
      COLUMN TITLE "Oper."      DATA oQryRep:casos   PICTURE "9999" SIZE 05 TOTAL FONT 1 
      COLUMN TITLE "Importe"   DATA oQryRep:importe  PICTURE "99999999.99"  FONT 1;
                                  SIZE 10  TOTAL 
      COLUMN TITLE "Sin IVA"   DATA oQryRep:importe/1.21  PICTURE "99999999.99"  FONT 1;
                                  SIZE 10  TOTAL 
      COLUMN TITLE "Firma"   DATA " " SIZE 15 FONT 2 

      // Digo que el titulo lo escriba con al letra 2

      oRep:bInit := {|| oQryRep:GoTop() }
      oRep:bSkip := {|| oQryRep:Skip() }
      
      END REPORT
      // Activo el reporte
      ACTIVATE REPORT oRep WHILE !oQryRep:EOF() ON INIT CursorArrow();
                      ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.5,.5)
      oQryRep:End()
    ENDIF

RETURN nil

STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil 


************************************************************
** Orden de trabajo
STATIC FUNCTION OrdTra()
LOCAL oQryRep, oQryFac, oQryRepa, nTotDeu,;
      i, x, y, oPrn, nRow, oFont, oFont2, oFont1, oFont3, config, nHoja := 1
LOCAL oQryVen, oDlg1, ;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oBot3,;
      cVendedor, aVen, oBrwVen,j,mvende, mdesde := DATE(), mhasta := DATE()      
oQryVen:= oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"vendedores ORDER BY nombre") 
aVen   := {}
DO WHILE !oQryVen:Eof()
   AADD(aVen,{.t.,oQryVen:Nombre, oQryVen:codigo})
   oQryVen:Skip()
ENDDO  

DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,8
DEFINE DIALOG oDlg1 TITLE "Orden de trabajo de ventas x vendedor" FROM 03,15 TO 23,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 22, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Vendedores a Incluir:" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 20, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 35, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) 
   @ 50,130 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aVen,oBrwVen) PIXEL SIZE 20,10 OF oDlg1
   @ 50, 05 XBROWSE oBrwVen SIZE 125,80 pixel OF oDlg1 ARRAY aVen ;
      HEADERS "Incluir", "Vendedor","Codigo";
      COLUMNS 1, 2 ,3;
      CELL LINES NOBORDER AUTOSORT 
   WITH OBJECT oBrwVen
      :aCols[ 1 ]:nEditType := EDIT_GET
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwVen,0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN nil
ENDIF 
cVendedor := "("
FOR i := 1 TO LEN(aVen)
    IF aVen[i,1]
       cVendedor := cVendedor + IF(cVendedor=="(","",",") + ClipValue2Sql(aVen[i,2])  
    ENDIF
NEXT i
cVendedor := cVendedor + ")"
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_fact_det` ("+;
                           "`id` int(10) NOT NULL AUTO_INCREMENT ,"+;
                           "`codart` BIGINT(14) NOT NULL,"+;
                           "`detart` VARCHAR(50) NOT NULL,"+;
                           "`vendidos` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "`devueltos` DECIMAL(10,2) DEFAULT 0 NOT NULL,"+;
                           "PRIMARY KEY (id) ) ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1")
oApp:oServer:Execute("TRUNCATE transi_fact_det")
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_fact1` ("+;
                           "`codcli` int(10) NOT NULL ,"+;                           
                           "`cliente` VARCHAR(50) DEFAULT 0 NOT NULL,"+;
                           "`facturas` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`presupuestos` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "`deuda` DECIMAL(12,2) DEFAULT 0 NOT NULL,"+;
                           "PRIMARY KEY (codcli) ) ENGINE=INNODB")
oApp:oServer:Execute("TRUNCATE transi_fact1")
//Leo las facturas de la carta de porte
oQryFac := oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"ventas_encab "+;
           " WHERE fechaasig IS NULL AND fecha  >= "+ClipValue2Sql(mdesde) + " AND fecha <= "+ClipValue2Sql(mhasta) + ;
           " AND vendedor IN "+cVendedor+"")
IF oQryFac:nRecCount = 0
   MsgStop("No hay facturas sin asignar para ese rango y vendedores","Error")
   RETURN nil 
ENDIF 
DO WHILE !oQryFac:Eof()
   IF oApp:oServer:Query("SELECT codcli FROM transi_fact1 WHERE codcli = " + ClipValue2Sql(oQryFac:codcli)):nReccount > 0
      //Sumar
      IF oQryFac:letra = "X"
         oApp:oServer:Execute("UPDATE transi_fact1 SET presupuestos = presupuestos + " +;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe)) +;
               " WHERE codcli =  " + ClipValue2Sql(oQryFac:codcli))
         ELSE
         oApp:oServer:Execute("UPDATE transi_fact1 SET facturas = facturas + " +;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe)) +;
               " WHERE codcli =  " + ClipValue2Sql(oQryFac:codcli))       
      ENDIF         
      ELSE 
      //Agregar
      IF oQryFac:letra = "X"
         oApp:oServer:Execute("INSERT INTO transi_fact1 (codcli,cliente,facturas,presupuestos,deuda) VALUES ("+;
               ClipValue2Sql(oQryFac:codcli)+","+;
               ClipValue2Sql(oQryFac:nombre)+","+; 
               ClipValue2Sql(0)+","+;
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe))+",0)")
         ELSE
         oApp:oServer:Execute("INSERT INTO transi_fact1 (codcli,cliente,facturas,presupuestos,deuda) VALUES ("+;
               ClipValue2Sql(oQryFac:codcli)+","+;
               ClipValue2Sql(oQryFac:nombre)+","+; 
               ClipValue2Sql(IF(oQryFac:ticomp = "NC",-oQryFac:importe,oQryFac:importe))+",0,0)")         
      ENDIF         
   ENDIF 
   //Agrego los articulos
   IF oQryFac:ticomp = "FC"  
      oApp:oServer:Execute("INSERT INTO transi_fact_det (codart,detart,vendidos) "+;
        " (SELECT codart,detart,cantidad FROM ge_"+oApp:cId+"ventas_det WHERE NROFAC = "+;
        ClipValue2Sql(oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp)+")")
      ELSE
      oApp:oServer:Execute("INSERT INTO transi_fact_det (codart,detart,devueltos) "+;
        " (SELECT codart,detart,cantidad FROM ge_"+oApp:cId+"ventas_det WHERE NROFAC = "+;
        ClipValue2Sql(oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp)+")")      
   ENDIF
   oQryFac:Skip()   
ENDDO   
oQryFac := oApp:oServer:Query("SELECT *  FROM transi_fact1")
DO WHILE !oQryFac:Eof()
   nTotDeu := oApp:oServer:Query("SELECT SUM(saldo * IF(tipo='NC',-1,1)) as totdeu "+;
             " FROM ge_"+oApp:cId+"ventas_cuota WHERE cliente = "+ClipValue2Sql(oQryFac:codcli)):totdeu
   oQryFac:deuda := nTotDeu
   oQryFac:Save()
   oQryFac:Skip()   
ENDDO   
oQryFac:GoTop()
oQryRep := oApp:oServer:Query("SELECT codart,detart,SUM(vendidos) as vendidos, SUM(devueltos) as devueltos "+;
           "  FROM transi_fact_det GROUP BY codart,detart")
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
//Hoja de ruta   
   DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
   DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
   DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
   PRINT oPrn NAME "Orden de trabajo Deposito" PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
     PAGE
     nHoja := 1     
     nRow := (oPrn:nHorzRes() / 80) / 47     
     oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
     @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
              SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
     oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
     oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
     oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
     IF config:x1 = 2 .or. config:x1 = 3
        @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
     ENDIF
     IF config:x1 = 1 .or. config:x1 = 3
         @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                  SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
         @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
         
     ENDIF
     oPrn:CmSay( 1.7  , 11, "ORDEN DE TRABAJO DEPOSITO", oFont1 )   
     oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
     oPrn:CmSay( 1.5, 9.8, "X",oFont2)        
     oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
     oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
     oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
     oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)      
     
     @ 7.5, 01 PRINT TO oPrn TEXT "Productos" ;
              SIZE 20,.5 CM FONT oFont1 ALIGN "C"
     @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
              SIZE 7,.5 CM FONT oFont ALIGN "L"
     @ 8.2, 11 PRINT TO oPrn TEXT "Vendidos" ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 14 PRINT TO oPrn TEXT "Devueltos" ;
              SIZE 2.1,.5 CM FONT oFont ALIGN "R"
     @ 8.2, 17 PRINT TO oPrn TEXT "Total" ;
              SIZE 3,.5 CM FONT oFont ALIGN "R"
     y := 9.2
     oQryRep:GoTop()
           
     FOR i = 1 TO oQryRep:nRecCount                               
         @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryRep:codart,14) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "L"
         @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryRep:detart) ;
              SIZE 7,1.5 CM FONT oFont LASTROW nRow 
         @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryRep:vendidos,08,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryRep:devueltos,08,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryRep:vendidos-oQryRep:devueltos,08,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "R"              
         y := nRow + .1
         IF y > 26
             @ 26.5, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
             IF config:x1 = 2 .or. config:x1 = 3
                @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
             ENDIF
             IF config:x1 = 1 .or. config:x1 = 3
                 @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                          SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                 @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                 
             ENDIF
             oPrn:CmSay( 1.7  , 11, "ORDEN DE TRABAJO", oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             oPrn:CmSay( 1.5, 9.8, "X",oFont2)  
             oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
             oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
             oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
             oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)
             

             @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                      SIZE 2.8,.5 CM FONT oFont ALIGN "L"
             @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                      SIZE 7,.5 CM FONT oFont ALIGN "L"
             @ 8.2, 11 PRINT TO oPrn TEXT "Vendidos" ;
                      SIZE 2,.5 CM FONT oFont ALIGN "R"
             @ 8.2, 14 PRINT TO oPrn TEXT "Devueltos" ;
                      SIZE 2.1,.5 CM FONT oFont ALIGN "R"
             @ 8.2, 17 PRINT TO oPrn TEXT "Total" ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R"
             y := 9.2
         ENDIF
         oQryRep:Skip()
      NEXT    
      y := y + 1
      oQryFac:GoTop()
       
       @ y, 01 PRINT TO oPrn TEXT "Clientes" ;
              SIZE 20,.5 CM FONT oFont1 ALIGN "C" LASTROW y
       oPrn:CmBox(   y, .5, y+1, 20.5 ) // Box titulos
       y := y + .2
       @ y, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
       @ y, 04 PRINT TO oPrn TEXT "Cliente" ;
                SIZE 7,.5 CM FONT oFont ALIGN "L"
       @ y, 11 PRINT TO oPrn TEXT "Facturas" ;
                SIZE 2,.5 CM FONT oFont ALIGN "R"
       @ y, 14 PRINT TO oPrn TEXT "Presupuestos" ;
                SIZE 2.1,.5 CM FONT oFont ALIGN "R"
       @ y, 17 PRINT TO oPrn TEXT "Saldo Actual" ;
                SIZE 3,.5 CM FONT oFont ALIGN "R"     
       y := y + 1.2
      FOR i = 1 TO oQryFac:nRecCount                               
         @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryFac:codcli,06) ;
                      SIZE 2.9,.5 CM FONT oFont ALIGN "L"
         @ y-0.07, 04 PRINT TO oPrn TEXT ALLTRIM(oQryFac:cliente) ;
              SIZE 7,1.5 CM FONT oFont LASTROW nRow 
         @ y-0.07, 11 PRINT TO oPrn TEXT STR(oQryFac:facturas,12,2) ;
              SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryFac:presupuestos,12,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ y-0.07, 17 PRINT TO oPrn TEXT STR(oQryFac:deuda,12,2);
                  SIZE 3,.5 CM FONT oFont ALIGN "R"              
         y := nRow + .1
         IF y > 26
             @ 26.5, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    nHoja ++
                    PAGE     
                       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL" ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             IF config:x1 = 2 .or. config:x1 = 3
                @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
             ENDIF
             IF config:x1 = 1 .or. config:x1 = 3
                 @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                          SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                 @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                          SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                 
             ENDIF
             oPrn:CmSay( 1.7  , 11, "ORDEN DE TRABAJO", oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             oPrn:CmSay( 1.5, 9.8, "X",oFont2)    
             oPrn:CmSay( 2.5, 11, "Fecha de emision:"+DTOC(DATE()),oFont)     
             oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
             oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
             oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)     
             
             y := 8.2
             @ y, 01 PRINT TO oPrn TEXT "Codigo" ;
              SIZE 2.8,.5 CM FONT oFont ALIGN "L"
             @ y, 04 PRINT TO oPrn TEXT "Cliente" ;
                      SIZE 7,.5 CM FONT oFont ALIGN "L"
             @ y, 11 PRINT TO oPrn TEXT "Facturas" ;
                      SIZE 2,.5 CM FONT oFont ALIGN "R"
             @ y, 14 PRINT TO oPrn TEXT "Presupuestos" ;
                      SIZE 2.1,.5 CM FONT oFont ALIGN "R"
             @ y, 17 PRINT TO oPrn TEXT "Saldo Actual" ;
                      SIZE 3,.5 CM FONT oFont ALIGN "R" 
             y := 9.2
         ENDIF
         oQryFac:Skip()
      NEXT   
      
     ENDPAGE
   ENDPRINT
RETURN nil