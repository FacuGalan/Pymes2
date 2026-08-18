#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "constant.ch"

*************************************************
** FACTURACION POR LOTE (cuenta corriente)
** Toma los articulos cargados por cliente en ge_<id>clides y genera
** una factura por cada cliente, reutilizando la logica de ventas.prg.
** Reutiliza FacturaElec1 (fe.prg) para la fiscal. El grabado se replica aca.
** Lanzar con: VentasLote(cPermisos)
*************************************************
MEMVAR oApp
STATIC oBrwL, oQryLote, dFecLote
// Contexto de facturacion (se setea una vez y por cliente)
STATIC aFormaNom, aFormaInc, aFormaTip, aFormaCod, nFormaPago, nFormaCodCC
STATIC oQryPar, oQryPun
// Variables del cliente en curso (las usa CalcularPromosLote)
STATIC nCodCli, oQryCliVL, nLista, nLisPre, nDescCli, nConIva, cVendedor


PROCEDURE VentasLote( cPermisos )
LOCAL oForm, oFont, aCor, oBot := ARRAY(2)
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"clides")
   MsgInfo("No hay articulos cargados para facturar por lote.","Ventas por lote")
   RETURN
ENDIF
IF oApp:oServer:Query("SELECT COUNT(DISTINCT codcli) AS n FROM ge_"+oApp:cId+"clides"):n == 0
   MsgInfo("No hay clientes con articulos cargados para facturar por lote.","Ventas por lote")
   RETURN
ENDIF

dFecLote := DATE()
CargarContextoLote()
IF nFormaCodCC == 0
   MsgStop("No hay una forma de pago de tipo 'Cuenta Corriente' (tipo 5) configurada en forpag.","Ventas por lote")
   RETURN
ENDIF
ArmarStagingLote( dFecLote )

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oForm TITLE "Facturacion por Lote (Cuenta Corriente)" FROM 05,15 TO 32,90 OF oApp:oWnd FONT oFont
   acor := AcepCanc(oForm)
   @ 07,010 SAY "Fecha:" OF oForm PIXEL SIZE 35,12 RIGHT
   @ 05,050 GET dFecLote PICTURE "@D" OF oForm PIXEL SIZE 50,12 ;
            VALID(ArmarStagingLote(dFecLote),oBrwL:Refresh(),.T.)
   @ 05,108 BUTTON "Inv.Fiscal"  OF oForm SIZE 55,12 PIXEL ACTION InvertirTilde("fiscal")
   @ 05,170 BUTTON "Inv.NoFact."  OF oForm SIZE 62,12 PIXEL ACTION InvertirTilde("nofacturar")
   @ 25,010 SAY "Click en Fiscal / NO facturar para tildar.  DELETE saca de la lista.  Doble clic = ver detalle." ;
            OF oForm PIXEL SIZE 430,12 COLOR CLR_GRAY

   @ 40,010 XBROWSE oBrwL DATASOURCE oQryLote ;
            COLUMNS "codcli","nombre","total","fiscal","nofacturar" ;
            HEADERS "Codigo","Cliente","Total a facturar","Fiscal","NO facturar" ;
            SIZES 55,250,100,50,70 OF oForm SIZE 420,120 AUTOSORT PIXEL
   oBrwL:CreateFromCode()
   oBrwL:nFreeze := 2
   //Tildes editables (click o barra espaciadora) que impactan en lote_clientes
   oBrwL:aCols[4]:SetCheck( , .T. )
   oBrwL:aCols[4]:lAutoSave := .T.
   oBrwL:aCols[5]:SetCheck( , .T. )
   oBrwL:aCols[5]:lAutoSave := .T.   
   oBrwL:aCols[4]:bEditValue:= {|| IF(oQryLote:fiscal,.t.,.f.) }
   oBrwL:aCols[5]:bEditValue:= {|| IF(oQryLote:nofacturar,.t.,.f.) }
   oBrwL:aCols[4]:bLDClickData := {|| CambiaChek(oQryLote,oBrwL,1)}
   oBrwL:aCols[4]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oQryLote,oBrwL,1))}
   oBrwL:aCols[5]:bLDClickData := {|| CambiaChek(oQryLote,oBrwL,2)}
   oBrwL:aCols[5]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oQryLote,oBrwL,2))}
   PintaBrw(oBrwL,0)
   oBrwL:bClrStd := { || IF(oQryLote:nofacturar, { CLR_BLACK, RGB(225,225,225) }, { CLR_BLACK, RGB(221,245,255) }) }
   oBrwL:bKeyDown := { |nKey| IF(nKey==VK_DELETE .and. oQryLote:nRecCount>0,;
                       (oApp:oServer:Execute("DELETE FROM lote_clientes WHERE codcli="+ClipValue2Sql(oQryLote:codcli)),;
                        oQryLote:Refresh(),oBrwL:Refresh()),) }
   //Doble clic = ver el detalle de articulos/promos que arman ese total
   oBrwL:bLDblClick := { || IF(oQryLote:nRecCount>0,VerDetalleLote(oQryLote:codcli),) }

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Generar" OF oForm SIZE 30,10 PIXEL ACTION GenerarLote()
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cerrar"  OF oForm SIZE 30,10 PIXEL ACTION oForm:End()
ACTIVATE DIALOG oForm CENTER
IF oQryLote != nil
   oQryLote:End()
   oQryLote := nil
ENDIF
oFont:End()
RETURN

*************************************************
** Invierte un tilde (fiscal / nofacturar) en TODAS las filas del lote
STATIC FUNCTION InvertirTilde( cCampo )
IF oQryLote == nil .or. oQryLote:nRecCount == 0
   RETURN nil
ENDIF
oApp:oServer:Execute("UPDATE lote_clientes SET "+cCampo+" = NOT "+cCampo)
oQryLote:Refresh()
oBrwL:Refresh()
RETURN nil


*************************************************
** Toggle de la fila actual al clickear/teclear el check (1=fiscal, 2=nofacturar)
STATIC FUNCTION CambiaChek(oQry1,oBrw1,n)
LOCAL valor
IF n = 1
   valor := IF(oQry1:fiscal=.f.,.t.,.f.)
   oQry1:fiscal := valor
   oQry1:Save()
   oQry1:Refresh()
   oBrw1:Refresh()
   ELSE 
   valor := IF(oQry1:nofacturar=.f.,.t.,.f.)
   oQry1:nofacturar := valor
   oQry1:Save()
   oQry1:Refresh()
   oBrw1:Refresh()
ENDIF   
RETURN nil


*************************************************
** Carga el contexto base (parametros, punto, formas de pago, forma cta cte)
STATIC FUNCTION CargarContextoLote()
LOCAL oQryFormas
oQryPar := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip))
aFormaNom := {}
aFormaInc := {}
aFormaTip := {}
aFormaCod := {}
nFormaPago := 1
nFormaCodCC := 0
oQryFormas := oApp:oServer:Query("SELECT codigo,nombre,incremento,tipo FROM ge_"+oApp:cId+"forpag ORDER BY codigo")
oQryFormas:GoTop()
DO WHILE !oQryFormas:Eof()
   AADD(aFormaNom,oQryFormas:nombre)
   AADD(aFormaInc,oQryFormas:incremento)
   AADD(aFormaTip,oQryFormas:tipo)
   AADD(aFormaCod,oQryFormas:codigo)
   IF oQryFormas:tipo == 5 .and. nFormaCodCC == 0   //tipo 5 = cuenta corriente
      nFormaPago  := LEN(aFormaTip)
      nFormaCodCC := oQryFormas:codigo
   ENDIF
   oQryFormas:Skip()
ENDDO
oQryFormas:End()
RETURN nil


*************************************************
** Arma la tabla de staging con un renglon por cliente (total + tildes)
STATIC FUNCTION ArmarStagingLote( dFec )
LOCAL oQryC, aTot, nNeto, nTotal, lYaFact
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS lote_clientes ("+;
   "codcli bigint(14) NOT NULL,"+;
   "nombre varchar(100) DEFAULT '',"+;
   "total decimal(13,2) DEFAULT 0,"+;
   "fiscal tinyint(1) DEFAULT 0,"+;
   "nofacturar tinyint(1) DEFAULT 0,"+;
   "PRIMARY KEY(codcli)) ENGINE=INNODB")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE lote_clientes")
oApp:oServer:NextResult()
oQryC := oApp:oServer:Query("SELECT DISTINCT l.codcli, c.nombre FROM ge_"+oApp:cId+"clides l "+;
                            "JOIN ge_"+oApp:cId+"clientes c ON c.codigo = l.codcli ORDER BY c.nombre")
oQryC:GoTop()
DO WHILE !oQryC:Eof()
   ArmarDetalleCliente( oQryC:codcli )
   aTot   := TotalesLote()
   nNeto  := aTot[1]
   nTotal := aTot[3] + IibbLote(nNeto)
   //Inteligente: si ya se le facturo en esa fecha, marcar NO facturar
   lYaFact := oApp:oServer:Query("SELECT COUNT(*) AS n FROM ge_"+oApp:cId+"ventas_encab "+;
              "WHERE codcli = "+ClipValue2Sql(oQryC:codcli)+" AND fecha = "+ClipValue2Sql(dFec)+;
              " AND ticomp = 'FC'"):n > 0
   oApp:oServer:Execute("INSERT INTO lote_clientes (codcli,nombre,total,fiscal,nofacturar) VALUES ("+;
      ClipValue2Sql(oQryC:codcli)+","+ClipValue2Sql(oQryC:nombre)+","+ClipValue2Sql(nTotal)+",0,"+;
      IF(lYaFact,"1","0")+")")
   oQryC:Skip()
ENDDO
oQryC:End()
IF oQryLote == nil
   oQryLote := oApp:oServer:Query("SELECT * FROM lote_clientes")
ELSE
   oQryLote:Refresh()
ENDIF
RETURN .T.


*************************************************
** Doble clic: muestra el detalle (articulos + promos) que arman el total del cliente
STATIC FUNCTION VerDetalleLote( nCli )
LOCAL oDlg, oFont, oBrwD, oQryD, aTot, cTot, oBot
ArmarDetalleCliente( nCli )
oQryD := oApp:oServer:Query("SELECT detart,cantidad,punit,stotal,iva,ptotal,espromo FROM ventas_det_H ORDER BY espromo,id")
aTot := TotalesLote()
cTot := "Neto: "+TRANSFORM(aTot[1],"999,999,999.99")+"    IVA: "+TRANSFORM(aTot[2],"999,999,999.99")+;
        "    IIBB: "+TRANSFORM(IibbLote(aTot[1]),"999,999.99")+;
        "    TOTAL: "+TRANSFORM(aTot[3]+IibbLote(aTot[1]),"999,999,999.99")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11
DEFINE DIALOG oDlg TITLE "Detalle a facturar - Cliente "+ALLTRIM(STR(nCli)) ;
       FROM 05,15 TO 22,95 OF oApp:oWnd FONT oFont
   oDlg:lHelpIcon := .f.
   @ 05,05 XBROWSE oBrwD DATASOURCE oQryD ;
           COLUMNS "detart","cantidad","punit","stotal","iva","ptotal","espromo" ;
           HEADERS "Detalle","Cant.","P.Unit","Neto","IVA","Total","Promo?" ;
           SIZES 175,50,65,75,75,75,50 OF oDlg SIZE 320,90 PIXEL
   oBrwD:CreateFromCode()
   oBrwD:aCols[7]:SetCheck(nil,.f.)
   oBrwD:aCols[7]:bEditValue:= {|| IF(oQryD:espromo,.t.,.f.) }
   PintaBrw(oBrwD,0)
   @ 100,05 SAY cTot OF oDlg PIXEL SIZE 320,12
   @ 115,140 BUTTON oBot PROMPT "&Cerrar" OF oDlg SIZE 40,12 PIXEL ACTION oDlg:End()
ACTIVATE DIALOG oDlg CENTER
oQryD:End()
oFont:End()
RETURN nil


*************************************************
** Arma ventas_det_H para un cliente (precio + descuento general + promos)
STATIC FUNCTION ArmarDetalleCliente( nCli )
LOCAL oQryItems, oQryArt, oQryIva, nPrecioVen, nPunit, nTasa,;
      nPrecio2, nDescuento, nPrecio1, nIvaCalc, nIvaPes, nSubTotal, nTotalcIva, oQryPrecio
CrearVentasDetH()
oApp:oServer:Execute("TRUNCATE ventas_det_H")
oApp:oServer:NextResult()
//Contexto del cliente
nCodCli := nCli
oQryCliVL := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCli))
IF oQryCliVL:nRecCount == 0
   RETURN .F.
ENDIF
nLista   := oQryCliVL:lispre
nLisPre  := oQryCliVL:lispreesp
nDescCli := oQryCliVL:descuento
nConIva  := oQryCliVL:coniva
cVendedor := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"vendedores WHERE codigo = "+ClipValue2Sql(oQryCliVL:vendedor)):nombre
IF cVendedor == nil
   cVendedor := ""
ENDIF
//Renglones del cliente
oQryItems := oApp:oServer:Query("SELECT codart,cantidad FROM ge_"+oApp:cId+"clides WHERE codcli = "+ClipValue2Sql(nCli))
oQryItems:GoTop()
DO WHILE !oQryItems:Eof()
   oQryArt := oApp:oServer:Query("SELECT codigo,nombre,precioven,iva,reventa,preciocos,endolares,marca,impint,stockotro "+;
              "FROM ge_"+oApp:cId+"articu WHERE nosale is false AND codigo = "+ClipValue2Sql(oQryItems:codart))
   IF oQryArt:nRecCount == 0
      oQryItems:Skip()
      LOOP
   ENDIF
   //Precio: lista especial del cliente -> sino precioven/reventa. SIN incremento por forma de pago.
   oQryPrecio := oApp:oServer:Query("SELECT precio FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPre)+;
                 " AND codart = "+ClipValue2Sql(oQryArt:codigo))
   IF oQryPrecio:nRecCount == 0
      nPrecioVen := IF(nLista==1,oQryArt:precioven,oQryArt:reventa)
   ELSE
      nPrecioVen := oQryPrecio:precio
   ENDIF
   nPunit := nPrecioVen * IF(oQryArt:endolares,oQryPar:dolar,1)
   nTasa  := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(oQryArt:iva)):tasa
   //Calculos identicos a AgregaItem de ventas.prg (descuento = general del cliente, sin marca/articulo)
   nPrecio2   := (nPunit - oQryArt:impint) * oQryItems:cantidad
   nDescuento := nPrecio2 * (nDescCli/100)
   nPrecio1   := nPrecio2 - nDescuento
   nIvaCalc   := nPrecio2 - (nPrecio2 / (1 + nTasa/100))
   nIvaPes    := nPrecio1 - (nPrecio1 / (1 + nTasa/100))
   nSubTotal  := nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1 + (oQryArt:impint * oQryItems:cantidad)
   oApp:oServer:Execute("INSERT INTO ventas_det_H (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,descup,stotal,pcosto,impint,bultos) "+;
      "VALUE ("+ClipValue2Sql(oQryArt:codigo)+","+ClipValue2Sql(STRTRAN(oQryArt:nombre,"'","`"))+","+;
      ClipValue2Sql(oQryItems:cantidad)+","+ClipValue2Sql(nPunit)+","+ClipValue2Sql(nTotalcIva)+","+;
      ClipValue2Sql(nPrecio2-nIvaCalc)+","+ClipValue2Sql(nIvaPes)+","+ClipValue2Sql(oQryArt:iva)+","+;
      ClipValue2Sql(nDescuento)+","+ClipValue2Sql(nDescCli)+","+ClipValue2Sql(nSubTotal)+","+;
      ClipValue2Sql(oQryArt:preciocos)+","+ClipValue2Sql(oQryArt:impint*oQryItems:cantidad)+",0)")
   oQryArt:End()
   oQryItems:Skip()
ENDDO
oQryItems:End()
//Promos (misma logica de ventas.prg, incluida la franja horaria)
CalcularPromosLote()
RETURN .T.


*************************************************
** Crea la tabla temporal de detalle (igual a ventas.prg)
STATIC FUNCTION CrearVentasDetH()
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS ventas_det_H ("+;
   "`id` INT(6) NOT NULL AUTO_INCREMENT,"+;
   "`CODART` bigint(14) NOT NULL,"+;
   "`DETART` VARCHAR(500) NOT NULL,"+;
   "`CANTIDAD` DECIMAL(8,3) DEFAULT '0',"+;
   "`PUNIT` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`NETO` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`DESCUENTO` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`DESCUP` DECIMAL(5,2) DEFAULT '0.00',"+;
   "`STOTAL` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`IVA` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`CODIVA` INT(2) DEFAULT '0',"+;
   "`PTOTAL` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`PCOSTO` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`IMPINT` DECIMAL(13,3) DEFAULT '0.00',"+;
   "`BULTOS` DECIMAL(6,1) DEFAULT '0.0',"+;
   "`ESPROMO` TINYINT(1) DEFAULT '0' NOT NULL,"+;
   "PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
RETURN nil


*************************************************
** Totales de ventas_det_H -> {neto(stotal), iva, total(ptotal), impint}
STATIC FUNCTION TotalesLote()
LOCAL o
o := oApp:oServer:Query("SELECT IFNULL(SUM(stotal),0) AS neto, IFNULL(SUM(iva),0) AS iva, "+;
     "IFNULL(SUM(ptotal),0) AS total, IFNULL(SUM(impint),0) AS impint FROM ventas_det_H")
RETURN { o:neto, o:iva, o:total, o:impint }


*************************************************
** Percepcion de IIBB del cliente sobre el neto (si esta activa)
STATIC FUNCTION IibbLote( nNeto )
RETURN nNeto * (oQryCliVL:iibb/100) * IF(oApp:percep_iibb,1,0)


*************************************************
** GENERA el lote: una factura por cliente no marcado. Para al primer error.
STATIC FUNCTION GenerarLote()
LOCAL oQryG, nOk := 0, cMsg
IF oQryLote == nil .or. oApp:oServer:Query("SELECT COUNT(*) AS n FROM lote_clientes WHERE NOT nofacturar"):n == 0
   MsgInfo("No hay clientes para facturar (todos estan marcados como NO facturar).","Ventas por lote")
   RETURN nil
ENDIF
IF !MsgYesNo("Se van a generar las facturas en CUENTA CORRIENTE de los clientes no marcados."+CHR(10)+;
             "Fecha: "+DTOC(dFecLote)+CHR(10)+"Confirma?","Ventas por lote")
   RETURN nil
ENDIF
Procesando(.t.)
oQryG := oApp:oServer:Query("SELECT codcli,nombre,fiscal,total FROM lote_clientes WHERE NOT nofacturar ORDER BY nombre")
oQryG:GoTop()
DO WHILE !oQryG:Eof()
   cMsg := ""
   IF !FacturarCliente( oQryG:codcli, oQryG:fiscal, dFecLote, @cMsg )
      Procesando(.f.)
      MsgStop("Se detuvo el proceso."+CHR(10)+;
              "Cliente "+ALLTRIM(STR(oQryG:codcli))+" - "+ALLTRIM(oQryG:nombre)+CHR(10)+;
              cMsg+CHR(10)+CHR(10)+;
              "Facturas generadas correctamente antes del error: "+ALLTRIM(STR(nOk)),"Ventas por lote")
      oQryG:End()
      ArmarStagingLote(dFecLote)
      oBrwL:Refresh()
      RETURN nil
   ENDIF
   nOk++
   oQryG:Skip()
ENDDO
oQryG:End()
Procesando(.f.)
MsgInfo("Proceso finalizado. Facturas generadas: "+ALLTRIM(STR(nOk)),"Ventas por lote")
ArmarStagingLote(dFecLote)
oBrwL:Refresh()
RETURN nil


*************************************************
** Factura un cliente. Devuelve .T. ok / .F. error (cMsg con el detalle).
STATIC FUNCTION FacturarCliente( nCli, lFiscal, dFec, cMsg )
LOCAL aTot, nNeto, nIva, nBase, nImpInt, nIibb, nTotal, cLetra, nPuntoVta, nNro := 0,;
      cCae := "", dFecVtoC := DATE(), nTipFor := 1, aTablaIva := {}, oTabIva, cNumComp, cTipoDoc,;
      oError, nPuntosAcu := 0, nPuntos := 0, nPercep
DEFAULT cMsg := ""
//1) Detalle + promos del cliente
ArmarDetalleCliente( nCli )
aTot    := TotalesLote()
nNeto   := aTot[1]
nIva    := aTot[2]
nBase   := aTot[3]
nImpInt := aTot[4]
nIibb   := IibbLote( nNeto )
nPercep := oQryCliVL:iibb * IF(oApp:percep_iibb,1,0)
nTotal  := nBase + nIibb
IF nTotal <= 0
   cMsg := "El cliente no tiene importe a facturar (total 0)."
   RETURN .F.
ENDIF
//2) Letra
IF lFiscal
   cLetra := IF(oApp:tipo_iva<>6,IF(nConIva==1 .or. nConIva==2 .or. nConIva==6,"A","B"),"C")
ELSE
   cLetra := "X"
ENDIF
//3) Numeracion + AFIP (fiscal)
IF lFiscal
   nPuntoVta := oQryPun:punto
   IF nPuntoVta <= 0
      nPuntoVta := oQryPar:prefijo
   ENDIF
   IF cLetra == "A" .and. !ConsultaCuitRapida(VAL(STRTRAN(oQryCliVL:cuit,"-","")),oQryCliVL:coniva)
      cMsg := "CUIT invalido para comprobante A."
      RETURN .F.
   ENDIF
   oTabIva := oApp:oServer:Query("SELECT codiva, SUM(stotal) AS neto, SUM(iva) AS iva FROM ventas_det_H GROUP BY codiva")
   DO WHILE !oTabIva:Eof()
      AADD(aTablaIva,{oTabIva:codiva,oTabIva:neto,oTabIva:iva})
      oTabIva:Skip()
   ENDDO
   oTabIva:End()
   FacturaElec1( nPuntoVta, 1, cLetra, aTablaIva, @nNro, @cCae, @dFecVtoC, @nTipFor,;
                 dFec, oQryCliVL:cuit, oQryCliVL:dni, nNeto, nIva, nBase, nImpInt, nConIva )
   IF nNro == 0
      cMsg := "Fallo la comunicacion con el WebService de AFIP."
      RETURN .F.
   ENDIF
ELSE
   nPuntoVta := oQryPun:caja
   nNro := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip)):presupu + 1
ENDIF
cNumComp := cLetra + STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
cTipoDoc := "FC"
//4) Puntos
IF oApp:usar_puntos
   nPuntosAcu := oApp:oServer:Query("SELECT puntos FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(nCli)):puntos
   nPuntos    := INT(nTotal/oApp:pesos_x_punto)
   nPuntosAcu := nPuntosAcu + nPuntos
ENDIF
//5) Grabado en transaccion
TRY
   oApp:oServer:BeginTransaction()
   //Detalle de IVA
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventivadet (tipocomp,letra,numfac,codiva,neto,iva) "+;
      "(SELECT "+ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+;
      ", codiva, SUM(stotal) AS neto, SUM(iva) AS iva FROM ventas_det_H GROUP BY codiva)")
   //Detalle de venta (stock baja por cantidad)
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
      "(codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,codiva,neton,descu,pcosto,impint,descup,bultos) "+;
      "(SELECT codart,detart,cantidad,punit,"+ClipValue2Sql(dFec)+","+ClipValue2Sql(nCli)+","+;
      ClipValue2Sql(cTipoDoc+cNumComp)+",ptotal,stotal,iva,codiva,neto,descuento,pcosto,impint,descup,bultos FROM ventas_det_H)")
   //Encabezado
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,coniva,fecha,neto,iva,iibb,importe,tipopag,observa,"+;
      "nombre,cuit,dni,direccion,localidad,percep,cae,fecvto,tipfor,usuario,fecmod,ip,vendedor,condven,"+;
      "formapag,sobretasa,acopio,endolares,cotiza,hora,puntos,puntosacu) VALUES ("+;
      ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+","+;
      ClipValue2Sql(nCli)+","+ClipValue2Sql(nConIva)+","+ClipValue2Sql(dFec)+","+;
      ClipValue2Sql(nNeto)+","+ClipValue2Sql(nIva)+","+ClipValue2Sql(nIibb)+","+ClipValue2Sql(nTotal)+",2,"+;
      ClipValue2Sql("FACTURACION POR LOTE")+","+;
      ClipValue2Sql(oQryCliVL:nombre)+","+ClipValue2Sql(oQryCliVL:cuit)+","+ClipValue2Sql(oQryCliVL:dni)+","+;
      ClipValue2Sql(oQryCliVL:direccion)+","+ClipValue2Sql(oQryCliVL:localidad)+","+ClipValue2Sql(nPercep)+","+;
      ClipValue2Sql(cCae)+","+ClipValue2Sql(dFecVtoC)+","+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+","+;
      ClipValue2Sql(oApp:usuario)+","+ClipValue2Sql(dFec)+","+ClipValue2Sql(oApp:cIp)+","+ClipValue2Sql(cVendedor)+","+;
      ClipValue2Sql(nFormaCodCC)+","+ClipValue2Sql(nFormaCodCC)+",0,FALSE,FALSE,0,CURTIME(),"+;
      ClipValue2Sql(nPuntos)+","+ClipValue2Sql(nPuntosAcu)+")")
   IF oApp:usar_puntos
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos + "+ClipValue2Sql(nPuntos)+;
         " WHERE codigo = "+ClipValue2Sql(nCli))
   ENDIF
   //Cuota en cuenta corriente (una sola, queda como saldo deudor)
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
      "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip,saldodolar) VALUES ("+;
      ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+",0,1,"+;
      ClipValue2Sql(dFec)+","+ClipValue2Sql(nCli)+",0,"+ClipValue2Sql(nTotal)+","+ClipValue2Sql(nTotal)+",'P',"+;
      ClipValue2Sql(dFec)+","+ClipValue2Sql(oQryCliVL:nombre)+","+ClipValue2Sql(oQryCliVL:cuit)+","+;
      ClipValue2Sql(oQryCliVL:dni)+","+ClipValue2Sql(oQryCliVL:direccion)+","+ClipValue2Sql(oQryCliVL:localidad)+","+;
      ClipValue2Sql(oApp:usuario)+","+ClipValue2Sql(cVendedor)+","+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:cIp)+",0)")
   //Concepto en concfact (fijo, cta cte, igual a linea 1741 de ventas.prg)
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,fecha,caja) VALUES ("+;
      ClipValue2Sql(cTipoDoc)+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+",5,5,"+;
      ClipValue2Sql(nTotal)+",'CTA. CTE.',"+ClipValue2Sql(DATE())+","+ClipValue2Sql(oApp:prefijo)+")")
   //Stock: articulos con stock propio
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+;
      "INNER JOIN (SELECT codart, SUM(cantidad) as suma FROM ventas_det_H "+;
      "WHERE ESPROMO IS FALSE AND codart > 0 GROUP BY codart) v ON a.codigo = v.codart "+;
      "SET a.stockact = a.stockact - v.suma WHERE a.stockotro IS FALSE")
   //Stock: articulos que descuentan de otros (recetas)
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu m "+;
      "JOIN (SELECT r.codusa AS codigo_usado, SUM(d.cantidad * r.cantidad) AS total_a_restar "+;
      "FROM ventas_det_H d "+;
      "JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
      "JOIN ge_"+oApp:cId+"reseta r ON r.codart = d.codart "+;
      "WHERE a.stockotro = TRUE AND d.ESPROMO IS FALSE GROUP BY r.codusa) AS t ON t.codigo_usado = m.codigo "+;
      "SET m.stockact = m.stockact - t.total_a_restar")
   //Numeracion del punto
   IF lFiscal
      IF cLetra == "A"
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturaa = "+ClipValue2Sql(nNro)+" WHERE ip = "+ClipValue2Sql(oApp:cip))
      ELSE
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturab = "+ClipValue2Sql(nNro)+" WHERE ip = "+ClipValue2Sql(oApp:cip))
      ENDIF
   ELSE
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET presupu = presupu + 1 WHERE ip = "+ClipValue2Sql(oApp:cip))
   ENDIF
   oApp:oServer:CommitTransaction()
CATCH oError
   oApp:oServer:RollBackTransaction()
   cMsg := "Error al grabar: "+oError:description
   RETURN .F.
END TRY
RETURN .T.


//////// Calcular Promos (portado de ventas.prg, sin la parte de UI)
STATIC FUNCTION CalcularPromosLote()
LOCAL cText, oQryTem, nNeto, nIva, nCurCodart, nTierPrio, nCodForma, nTot, oQryFp, oQryIva
STATIC cPrioChk := ""
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promociones")
   RETURN nil
ENDIF
IF cPrioChk != oApp:cId
   IF oApp:oServer:Query("SHOW COLUMNS FROM ge_"+oApp:cId+"promociones LIKE 'prioridad'"):nRecCount == 0
      oApp:oServer:Execute("ALTER TABLE ge_"+oApp:cId+"promociones ADD COLUMN prioridad INT DEFAULT 0 NOT NULL")
   ENDIF
   IF oApp:oServer:Query("SHOW COLUMNS FROM ge_"+oApp:cId+"promociones LIKE 'hora_inicio'"):nRecCount == 0
      oApp:oServer:Execute("ALTER TABLE ge_"+oApp:cId+"promociones ADD COLUMN hora_inicio TIME DEFAULT '00:00:00' NOT NULL")
   ENDIF
   IF oApp:oServer:Query("SHOW COLUMNS FROM ge_"+oApp:cId+"promociones LIKE 'hora_fin'"):nRecCount == 0
      oApp:oServer:Execute("ALTER TABLE ge_"+oApp:cId+"promociones ADD COLUMN hora_fin TIME DEFAULT '23:59:59' NOT NULL")
   ENDIF
   cPrioChk := oApp:cId
ENDIF
oApp:oServer:Execute("DELETE FROM ventas_det_H WHERE ESPROMO = TRUE")
IF nCodCli > 1 .and. oApp:oServer:Query("SELECT excluyepromo FROM ge_"+oApp:cId+"clientes WHERE codigo = "+str(nCodCli)):excluyepromo
   //Cliente excluido de promos
ELSE
   TEXT INTO cText
   (SELECT
       prom.CODART,
       prom.TIPO,
       prom.id,
     prom.prioridad,
       prom.nompromo AS DETART,
       CASE
           WHEN prom.tipo = 2 AND FLOOR(p.CANTIDAD / prom.cantidad_requerida) > 0 THEN
               p.cantidad - (FLOOR(p.CANTIDAD / prom.cantidad_requerida) * prom.cantidad_a_pagar + MOD(p.CANTIDAD, prom.cantidad_requerida))
           ELSE p.CANTIDAD
       END AS CANTIDAD,
       CASE
           WHEN prom.tipo = 1 THEN p.punit - prom.precio_especial
           WHEN prom.tipo = 4 AND p.CANTIDAD BETWEEN prom.cantidad_minima AND prom.cantidad_maxima THEN p.punit - prom.precio_unitario
           ELSE p.PUNIT
       END AS PUNIT,
       CASE
           WHEN prom.tipo = 3 AND p.CANTIDAD >= prom.descuento_a_unidad THEN
               prom.descuento_porcentual * FLOOR(p.CANTIDAD / prom.descuento_a_unidad)
           ELSE 0
       END AS DESCUENTO,
       p.CODIVA
   FROM  ge_000001promociones AS prom
   JOIN (SELECT CODART, DETART, SUM(CANTIDAD) AS CANTIDAD, PUNIT AS PUNIT, SUM(NETO) AS NETO,
          0 AS DESCUENTO, SUM(STOTAL) AS STOTAL, SUM(IVA) AS IVA, CODIVA, SUM(PTOTAL) AS PTOTAL,
          0 AS PCOSTO, 0 AS IMPINT, 0 AS ESPROMO FROM ventas_det_H GROUP BY CODART) AS p
       ON p.CODART = prom.codart
   WHERE
       CURRENT_DATE BETWEEN prom.fecha_inicio AND prom.fecha_fin
       AND CURTIME() BETWEEN prom.hora_inicio AND prom.hora_fin
       AND (
           (prom.tipo = 1) OR
           (prom.tipo = 2 AND p.CANTIDAD >= prom.cantidad_requerida) OR
           (prom.tipo = 3 AND p.CANTIDAD >= prom.descuento_a_unidad) OR
           (prom.tipo = 4 AND p.CANTIDAD BETWEEN prom.cantidad_minima AND prom.cantidad_maxima)
       )
       AND @FPSEL@
       GROUP BY prom.CODART, prom.TIPO, prom.prioridad ORDER BY prom.CODART, prom.prioridad DESC)
   ENDTEXT
   cText := STRTRAN(cText,'ge_000001promociones','ge_'+oApp:cId+'promociones')
   cText := STRTRAN(cText,'@FPSEL@',"FIND_IN_SET('"+ALLTRIM(STR(IF(EMPTY(aFormaTip[nFormaPago]),0,aFormaTip[nFormaPago])))+"', prom.formapago) > 0")
   oQryTem := oApp:oServer:Query(cText)
   oQryTem:GoTop()
   IF oQryTem:nRecCount > 0
      DO WHILE !oQryTem:Eof()
         IF oQryTem:codart != nCurCodart
            nCurCodart := oQryTem:codart
            nTierPrio  := oQryTem:prioridad
         ENDIF
         IF oQryTem:prioridad != nTierPrio
            oQryTem:Skip()
            LOOP
         ENDIF
         DO CASE
            CASE oQryTem:codiva = 3
                 nNeto := oQryTem:punit * oQryTem:cantidad
                 nIva  := 0
            CASE oQryTem:codiva = 4
                 nNeto := oQryTem:punit * oQryTem:cantidad / 1.105
                 nIva  := oQryTem:punit * oQryTem:cantidad - nNeto
            CASE oQryTem:codiva = 5
                 nNeto := oQryTem:punit * oQryTem:cantidad / 1.21
                 nIva  := oQryTem:punit * oQryTem:cantidad - nNeto
         ENDCASE
         DO CASE
            CASE oQryTem:tipo = 1 .or. oQryTem:tipo = 2 .or. oQryTem:tipo = 4
                 oApp:oServer:Execute("INSERT INTO ventas_det_H (CODART, DETART, CANTIDAD, PUNIT, "+;
                   +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, PCOSTO, IMPINT, ESPROMO) VALUES ("+;
                   ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                   ClipValue2Sql(oQryTem:cantidad)+","+ClipValue2Sql(-oQryTem:punit)+","+;
                   ClipValue2Sql(-nNeto)+",0,"+ClipValue2Sql(-nNeto)+","+Clipvalue2Sql(-nIva)+","+;
                   ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql(-nNeto-nIva)+",0,0,1)")
            CASE oQryTem:tipo = 3
                 nNeto := nNeto / oQryTem:cantidad
                 nIva  := nIva  / oQryTem:cantidad
                 oApp:oServer:Execute("INSERT INTO ventas_det_H (CODART, DETART, CANTIDAD, PUNIT, "+;
                   +" NETO, DESCUENTO, STOTAL, IVA, CODIVA, PTOTAL, PCOSTO, IMPINT, ESPROMO) VALUES ("+;
                   ClipValue2Sql(oQryTem:codart)+","+Clipvalue2Sql(oQryTem:DETART)+","+;
                   ClipValue2Sql(1)+","+ClipValue2Sql(-oQryTem:punit*oQryTem:descuento/100)+","+;
                   ClipValue2Sql(-nNeto*oQryTem:descuento/100)+;
                   ",0,"+ClipValue2Sql(-nNeto*oQryTem:descuento/100)+;
                     ","+Clipvalue2Sql(-nIva*oQryTem:descuento/100)+","+;
                   ClipValue2Sql(oQryTem:codiva)+","+ClipValue2Sql((-nNeto-nIva)*oQryTem:descuento/100)+",0,0,1)")
         ENDCASE
         oQryTem:Skip()
      ENDDO
   ENDIF
   //Descuento por forma de pago segun rango de importe
   IF oApp:oServer:TableExist('ge_'+oApp:cId+"forpag_desc")
      nCodForma := IF(EMPTY(aFormaCod[nFormaPago]),0,aFormaCod[nFormaPago])
      nTot := oApp:oServer:Query("SELECT IFNULL(SUM(PTOTAL),0) AS t FROM ventas_det_H"):t
      oQryFp := oApp:oServer:Query("SELECT porcentaje FROM ge_"+oApp:cId+"forpag_desc "+;
                "WHERE codfor = "+ClipValue2Sql(nCodForma)+;
                " AND "+ClipValue2Sql(nTot)+" BETWEEN desde_importe AND hasta_importe LIMIT 1")
      IF oQryFp:nRecCount > 0 .and. oQryFp:porcentaje > 0
         oQryIva := oApp:oServer:Query("SELECT CODIVA AS codiva, SUM(NETO) AS net, SUM(IVA) AS iva FROM ventas_det_H GROUP BY CODIVA")
         DO WHILE !oQryIva:Eof()
            oApp:oServer:Execute("INSERT INTO ventas_det_H (CODART,DETART,CANTIDAD,PUNIT,NETO,DESCUENTO,STOTAL,IVA,CODIVA,PTOTAL,PCOSTO,IMPINT,ESPROMO) VALUES (0,"+;
               ClipValue2Sql("Desc. "+ALLTRIM(aFormaNom[nFormaPago]))+",1,"+;
               ClipValue2Sql(-(oQryIva:net+oQryIva:iva)*oQryFp:porcentaje/100)+","+;
               ClipValue2Sql(-oQryIva:net*oQryFp:porcentaje/100)+",0,"+;
               ClipValue2Sql(-oQryIva:net*oQryFp:porcentaje/100)+","+;
               ClipValue2Sql(-oQryIva:iva*oQryFp:porcentaje/100)+","+;
               ClipValue2Sql(oQryIva:codiva)+","+;
               ClipValue2Sql(-(oQryIva:net+oQryIva:iva)*oQryFp:porcentaje/100)+",0,0,1)")
            oQryIva:Skip()
         ENDDO
      ENDIF
   ENDIF
ENDIF
RETURN nil
