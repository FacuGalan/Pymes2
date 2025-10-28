#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"


************************************************************************************************
** NOTAS DE CREDITO
************************************************************************************************
MEMVAR oApp
static oQryFac
************************************************************************************
***** Elegir factura para nota de credito
PROCEDURE NotaCred()
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oDlg1, oFont, mnumfac, ;
      mrta := .f., aCor,  mtotal, ;
      aTipo  := {"Factura","Factur x Rem.","Nota Debito"}, oRep,;
      aTip1  := {"FC","FR","ND"}, mtipo := 1, mletra := "A", mprefijo := oApp:prefijo,;
      mnumero := 0, oQryUlt, oBrwB

LOCAL cOrigenNC,dFecVtoC,cCae,nTipfor,lFisc,oQryPun,nPunLocal,nPuntoVta,aTablaIva,nNumero,nNro,;
      cLetra,cNumcomp,cTipoDoc,oQryT,nPagoOri,nRecibo,nPuntosAcu,nPuntos,nCliente,lAcopio,cSql,;
      oQryPar, oErr, oError



DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5   
oQryPar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
    oQryUlt := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp IN ('FC','FR','ND') ORDER BY fecha DESC,hora DESC LIMIT 30")
    DEFINE DIALOG oDlg1 TITLE "Elejir factura para nota de credito" FROM 03,20 TO 28,80 FONT oFont
       acor := AcepCanc(oDlg1)
       @ 01, 05 SAY "Ultmos comprobantes emitidos" OF oDlg1 PIXEL CENTER SIZE 230,10
       @ 12, 05 XBROWSE oBrwB DATASOURCE oQryUlt;
                  COLUMNS "ticomp","letra","numcomp","nombre","importe";
                  HEADERS "Tipo","Letra","Numero Comp","Cliente","Importe";
                  SIZES 30,30,100,140,80;
                  AUTOSORT OF oDlg1 ;
         SIZE 230,90 PIXEL ON CHANGE Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt)
       PintaBrw(oBrwB,5)   
       oBrwB:CreateFromcode()
       @ 107, 05 SAY "Tipo Docum.:" OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 122, 05 SAY "Letra:"       OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 137, 05 SAY "Prefijo:"     OF oDlg1 PIXEL RIGHT SIZE 40,10
       @ 152, 05 SAY "Numero:"      OF oDlg1 PIXEL RIGHT SIZE 40,10
       
       @ 105, 50 COMBOBOX oGet1 VAR mtipo ITEMS aTipo OF oDlg1 SIZE 79,50 PIXEL
       @ 120, 50 GET      oGet2 VAR mletra PICTURE "@!" OF oDlg1 SIZE 20,10 PIXEL;
                         VALID(mletra$"ABCMX")
       @ 135, 50 GET      oGet3 VAR mprefijo PICTURE "9999" OF oDlg1 PIXEL RIGHT
       @ 150, 50 GET      oGet4 VAR mnumero  PICTURE "99999999" OF oDlg1 PIXEL RIGHT
       oBrwB:bGotFocus := {|| Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt)}
       
       @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Elegir" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT (Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt),oGet1:SetFocus())
    IF !mrta
       RETURN 
    ENDIF
    oQryFac:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ventas_encab WHERE ticomp = "+ClipValue2Sql(aTip1[mtipo])+;
                                 "AND letra = "+ClipValue2Sql(mletra)+;
                                 "AND numcomp = "+ClipValue2Sql(STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0")))
    IF oQryFac:RecCount() = 0
       MsgStop("La factura no existe","Atencion!")
       RETURN  
    ENDIF                                   
   oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIp)) 
   cOrigenNC := oQryFac:ticomp+oQryFac:letra+oQryFac:numcomp
   nCliente := oQryFac:codcli 
   lAcopio  := oQryFac:acopio 
   nPuntoVta := oApp:prefijo  
   cLetra := oQryFac:letra

   dFecVtoC:= DATE()
   cCae:= ""
   nTipFor:=01
   lFisc:= mletra <> 'X'
   IF lFisc
      IF oQryPun:tipofac = 1
         nPunLocal :=  oApp:oServer:Query("SELECT punto FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):punto
         IF nPunLocal > 0
             nPuntoVta := nPunLocal
             ELSE 
             nPuntoVta:= oApp:oServer:Query("SELECT prefijo FROM ge_"+oApp:cId+"parametros LIMIT 1"):prefijo
         ENDIF
         oQryT := oApp:oServer:Query("SELECT codiva, neto, iva FROM ge_"+oApp:cId+"ventivadet "+;
                                         "WHERE tipocomp = "+ClipValue2Sql(aTip1[mtipo]) + ;
                                         " AND letra = " + ClipValue2Sql(mletra) + " AND numfac = " + ;
                                         ClipValue2Sql(STRTRAN(STR(mprefijo,4)+"-"+STR(mnumero,8)," ","0") ))
         aTablaIva := {}
         DO WHILE !oQryT:Eof()
           AADD(aTablaIva,{oQryT:codiva,oQryT:neto,oQryT:iva})
           oQryT:Skip()
         ENDDO
         FacturaElec2( nPuntoVta, 3, mLetra, aTablaIva, @nNro, @cCae, @dFecVtoC,@nTipFor,;
                   DATE(),oQryFac:cuit,oQryFac:dni,oQryFac:neto,oQryFac:iva,oQryFac:importe,oQryFac:iibb,oQryFac:coniva,oQryFac:sobretasa)
         IF nNro = 0
             MsgStop("Fallo el Comunicacion con WebService AFIP","Error")
             Return 
         ENDIF
         ELSE                              
         MsgStop("Opcion no soportada para controladores fiscales","Error")
         Return
      ENDIF     
   ELSE
     nNro := oApp:oServer:Query("SELECT presupu FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):presupu+1
     cLetra := "X"
     cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
     cTipoDoc := "NC"
     
   ENDIF

  cNumComp := cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nNro,8)," ","0")
  cTipoDoc := "NC"  
  TRY 
      oApp:oServer:BeginTransaction()
      //Primero agrego los pagos
      //Primer paso, evaluo cual fue el recibo que genero la factura original
      oQryT := oApp:oServer:Query("SELECT numero FROM ge_"+oApp:cId+;
      	                          "pagfac WHERE CONCAT(ticomp,letra,numcomp) = "+ClipValue2Sql(cOrigenNC))
      IF oQryT:nRecCount > 0
         nPagoOri := oQryT:numero 
         nRecibo :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
         //Agrego recibo negativo      
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagos (numero,cliente,total,fecha,usuario,"+;
         	"vendedor,interes,iddepo,facturas,id_cierre,checkeado,caja)  (SELECT "+;
         	Clipvalue2sql(nRecibo)+",cliente,-total,CURDATE(),"+Clipvalue2sql(oApp:usuario)+","+;
         	"vendedor,interes,iddepo,-facturas,0,0,"+ClipValue2Sql(oApp:prefijo)+;
         	" FROM ge_"+oApp:cId+"pagos WHERE numero = " + STR(nPagoOri)+")")
         //Agrego Conceptos de pago
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagfac (numero,ticomp,letra,numcomp,fecha,importe) "+;
         	"(SELECT "+;
         	Clipvalue2sql(nRecibo)+",'NC',"+ClipValue2Sql(mletra)+","+ClipValue2Sql(RIGHT(cNumcomp,13))+;
         		",curdate(),-importe "+;
         	" FROM ge_"+oApp:cId+"pagfac WHERE numero = " + STR(nPagoOri)+")")
         //Forma de pago
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon (numero,codcon,importe,observa,tipocon) "+;
         	"(SELECT "+;
         	Clipvalue2sql(nRecibo)+",codcon,-importe,observa,tipocon "+;
         	" FROM ge_"+oApp:cId+"pagcon WHERE numero = " + STR(nPagoOri)+")")
      ENDIF   
     //Agrego conceptos facturados
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"concfact (ticomp,letra,numcomp,codcon,tipocon,importe,observa,"+;
     	                          "fecha,caja,id_cierre) "+;
                       "(SELECT 'NC',"+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                  ClipValue2Sql(RIGHT(cNumComp,13))+",codcon,tipocon,-importe,observa,curdate(),"+;
                                  ClipValue2Sql(oApp:prefijo)+",0 FROM ge_"+oApp:cId+"concfact "+;
                                  "WHERE CONCAT(ticomp,letra,numcomp) = "+ClipValue2Sql(cOrigenNC)+")")
     //Agrego las cuotas
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_cuota (tipo,letra,numero,cuota,cantcuo,fecha,cliente,neto,importe,saldo,estado,fecvto,"+;
                                                    "nombre,cuit,dni,direccion,localidad,usuario,vendedor,fecmod,ip,saldodolar) "+;
                          "(SELECT 'NC',"+ClipValue2Sql(LEFT(cNumComp,1))+","+;
                                    ClipValue2Sql(RIGHT(cNumComp,13))+",0,0,"+;
                                     "CURDATE(),cliente,neto,importe,saldo,estado,fecvto,nombre,cuit,dni,"+;
                                     "direccion,localidad,"+ ClipValue2Sql(oApp:usuario)+",vendedor,curdate(),"+;
                                     ClipValue2SQL(oApp:cIp)+", saldodolar "+;                                         
                          " FROM ge_"+oApp:cId+"ventas_cuota WHERE CONCAT(tipo,letra,numero) = "+ClipValue2Sql(cOrigenNC)+")")
        
      
      //-- DETALLE DE IVA DE LA VENTA
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventivadet (tipocomp,letra,numfac,codiva,neto,iva) "+;
                           "(SELECT "+ClipValue2Sql('NC')+","+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+;
                            ", codiva, neto,iva FROM ge_"+oApp:cId+"ventivadet "+;
                            " WHERE CONCAT(tipocomp,letra,numfac) = "+ClipValue2Sql(cOrigenNC)+")")
      //-- detalle de venta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_det "+;
                        " (codart,detart,cantidad,punit,fecha,codcli,nrofac,importe,neto,iva,"+;
                           "codiva,neton,descu,pcosto,impint,descup,bultos) "+;
                        " (SELECT codart,detart,cantidad,punit,fecha,codcli,"+ClipValue2Sql("NC"+cNumcomp)+",importe,neto,iva,"+;
                        "codiva,neton,descu,pcosto,impint,descup,bultos FROM ge_"+oApp:cId+"ventas_det "+;
                        " WHERE nrofac = "+ClipValue2Sql(cOrigenNC)+")")

      //-- encabezado de venta
      IF oApp:usar_puntos
         nPuntosAcu := oApp:oServer:Query("SELECT puntos FROM ge_"+oApp:cId+"clientes  WHERE codigo = "+ClipValue2Sql(oQryFac:codcli) ):puntos
         nPuntosAcu := nPuntosAcu - INT(oQryFac:importe/oApp:pesos_x_punto)
         nPuntos :=  -INT(oQryFac:importe/oApp:pesos_x_punto)
      ENDIF
           
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"ventas_encab (ticomp,letra,numcomp,codcli,coniva,fecha,neto,iva,iibb,importe,tipopag,observa,"+;
                             "nombre,cuit,dni,direccion,localidad,percep,cae,fecvto,tipfor,usuario,fecmod,ip,vendedor,condven,"+;
                             "formapag,sobretasa,acopio,endolares,cotiza,hora,puntos,puntosacu) (SELECT "+;
                           " 'NC',"+ClipValue2Sql(LEFT(cNumComp,1))+","+ClipValue2Sql(RIGHT(cNumComp,13))+","+;
                           "codcli,coniva,CURDATE(),neto,iva,iibb,importe,tipopag,"+ClipValue2Sql(cOrigenNC)+","+;
                             "nombre,cuit,dni,direccion,localidad,percep,"+;
                             ClipValue2Sql(cCae)+","+ClipValue2Sql(dFecVtoC)+","+ClipValue2Sql(STRTRAN(STR(nTipFor,2)," ","0"))+;
                             ","+ClipValue2Sql(oApp:usuario)+",CURDATE(),"+ClipValue2SQL(oApp:cIp)+",vendedor,condven,"+;
                             "formapag,sobretasa,acopio,endolares,cotiza,CURTIME(),"+;
                             Clipvalue2sql(nPuntos)+","+ClipValue2Sql(nPuntosAcu) +;
                             " FROM ge_"+oApp:cId+"ventas_encab "+;
                             " WHERE CONCAT(ticomp,letra,numcomp) = "+ClipValue2Sql(cOrigenNC)+")")                            
      
      IF oApp:usar_puntos
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = puntos - "+ClipValue2Sql(INT(oQryFac:importe/oApp:pesos_x_punto)) +;
          " WHERE codigo = "+ClipValue2Sql(nCliente) )
      ENDIF      

      //ACTUALIZO EL STOCK DE LOS ARTICULOS VENDIDOS (SI NO ES ACOPIO)
      //oApp:oServer:Execute("UPDATE  ge_"+oApp:cId+"articu a SET a.stockact = a.stockact - "+;
      //                     "(SELECT SUM(v.cantidad * IF("+ClipValue2Sql(cTipoDoc)+"='NC',(-1),1)) FROM ventas_det_H v WHERE v.codart = a.codigo GROUP BY v.codart ) ")

      // Primero actualizo los que tienen stock propio
      lAcopio := oQryFac:acopio
      cTipoDoc := 'NC'
      IF !lAcopio
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
                   "INNER JOIN "+; 
                   "("+; 
                   "SELECT codart, SUM(cantidad) as suma "+;
                   "FROM ge_"+oApp:cId+"ventas_det "+;
                   "WHERE  nrofac = "+Clipvalue2sql(cOrigenNC)+" AND punit > 0 "+;
                   "GROUP BY codart "+;
                   ") v ON a.codigo = v.codart "+;
                   "SET a.stockact = a.stockact - (v.suma * "+IF(cTipoDoc="NC","-1","1")+") WHERE a.stockotro IS FALSE")          
          cSQL := "UPDATE ge_"+oApp:cId+"articu m " + ;
          "JOIN ( " + ;
          "  SELECT r.codusa AS codigo_usado, SUM(d.cantidad * r.cantidad) AS total_a_restar " + ;
          "  FROM ge_"+oApp:cId+"ventas_det d " + ;
          "  JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart " + ;
          "  JOIN ge_"+oApp:cId+"reseta r ON r.codart = d.codart " + ;
          "  WHERE a.stockotro = TRUE AND d.punit > 0 AND d.nrofac = "+Clipvalue2sql(cOrigenNC)+" " + ;
          "  GROUP BY r.codusa " + ;
          ") AS t ON t.codigo_usado = m.codigo " + ;
          "SET m.stockact = m.stockact + t.total_a_restar "

          oApp:oServer:Execute( cSQL )
      ENDIF
      IF lFisc       
         IF cLetra = "A"
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturaa = "+ClipValue2Sql(nNro)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))
         ELSE  
          oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET facturab = "+ClipValue2Sql(nNro)+" WHERE ip = "+ ClipValue2Sql(oApp:cip))          
         ENDIF 
      ELSE
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET presupu = presupu+1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
      ENDIF         
      oApp:oServer:CommitTransaction()
      IF lFisc 
         IF oApp:factura = 1
            PrintFactuElec(cTipoDoc,cNumComp)  
         ENDIF
      ELSE 
        IF oQryPar:pregunta_ticket
          IF MsgYesNo("¿Desea imprimir el ticket no fiscal?","Atencion!")
            FacturaNoFiscal(cTipoDoc,cNumComp)            
          ENDIF
          ELSE
          FacturaNoFiscal(cTipoDoc,cNumComp)
        ENDIF 
      ENDIF       
  CATCH oErr
      MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN 
  END TRY

RETURN 

STATIC FUNCTION Llenar(oGet1,oGet2,oGet3,oGet4,oQryUlt)
DO CASE 
   CASE oQryUlt:ticomp = "FC"
        oGet1:Set(1)
   CASE oQryUlt:ticomp = "FR"
        oGet1:Set(2)
   CASE oQryUlt:ticomp = "ND"
        oGet1:Set(3)
ENDCASE
oGet2:cText := oQryUlt:letra 
oGet3:cText := VAL(LEFT(oQryUlt:numcomp,4))
oGet4:cText := VAL(RIGHT(oQryUlt:numcomp,8))
RETURN NIL


******************************************************************************************
** Factura electronica para tickets
FUNCTION FacturaElec2( nPuntoVta, nTipoDoc, cLetra, aTablasIvas, nNro, cCae, dFecVto, nTipfor,;
                     dFecComp,cCuit,nDni,nImpNeto,nImpIva,nImpTotal,nImpInt, nConIva, nIIBB)
LOCAL urlwsaa, urlwsw, wsfev1, i, lFallo := .f., j, TipoComp, fechacmp, nFacturaNro, nNroDoc,;
      nTotal, nIva, nNeto, dFecDes, dFecHas, aXml, hFile, oXmlDoc, oXmlIter, oTagActual, oError, lRta
   
nNro := 0      

DO CASE 
   //Facturas
   CASE nTipoDoc = 1 .AND. cLetra = "A"
        Tipocomp := 1
   CASE nTipoDoc = 1 .AND. cLetra = "B"     
        Tipocomp := 6
   CASE nTipoDoc = 1 .AND. cLetra = "C"     
        Tipocomp := 11
   CASE nTipoDoc = 1 .AND. cLetra = "M"     
        Tipocomp := 51
   //Notas de debito
   CASE nTipoDoc = 2 .AND. cLetra = "A"
        Tipocomp := 2
   CASE nTipoDoc = 2 .AND. cLetra = "B"     
        Tipocomp := 7
   CASE nTipoDoc = 2 .AND. cLetra = "C"     
        Tipocomp := 12
   CASE nTipoDoc = 2 .AND. cLetra = "M"     
        Tipocomp := 52
   //Notas de credito
   CASE nTipoDoc = 3 .AND. cLetra = "A"
        Tipocomp := 3
   CASE nTipoDoc = 3 .AND. cLetra = "B"     
        Tipocomp := 8
   CASE nTipoDoc = 3 .AND. cLetra = "C"     
        Tipocomp := 13
   CASE nTipoDoc = 3 .AND. cLetra = "M"     
        Tipocomp := 53
ENDCASE          

IF EMPTY(STRTRAN(cCuit,"-","")) .AND. cLetra = 'A'
   nNro := 0
   MsgStop("El cliente elegido es INSCRIPTO y no tiene CUIT"+CHR(10)+"Corrija","Error")
   RETURN nil
ENDIF

IF oApp:lDemo
    //URLWSAA := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
    //URLWSW := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
    wsfev1 := WSAFip():New("20214424666", .t.)
ELSE 
    //URLWSAA := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
    //URLWSW := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
    wsfev1 := WSAFip():New(STRTRAN(oApp:cuit_emp,"-",""), .F.)
ENDIF


*Tipocomp := 011 &&Factura C( A:001 B:006 NDA: 002 NCA:003 NDB:007 NCB:008 NDC:012 NCC:013)
fechacmp := DTOS(dFecComp)

IF !EMPTY(STRTRAN(cCuit,"-",""))
   //CUIT
   nTipoDoc := 80
   nNroDoc  := VAL(STRTRAN(cCuit,"-",""))
   ELSE
   //DNI
   nTipoDoc := 96
   nNroDoc  := nDni
   IF nNroDoc = 0
      nTipoDoc := 99
   ENDIF
ENDIF

// Valores
nNeto  := IF(cLetra="C",ROUND(nImpTotal,2),ROUND(nImpNeto,2))
nNeto  := IF(nImpInt>0 .AND. cLetra= 'C', nNeto - nImpInt, nNeto)
nTotal := ROUND(nImpTotal,2)
nIva   := IF(cLetra="C",0,ROUND(nImpIva,2))
IF nNeto + nIva + nImpInt > nTotal .and. nImpInt > 0
   nImpInt := nImpInt - (nTotal - nNeto - nIva - nImpInt)
ENDIF
dFecDes := ""
dFecHas := ""
lRta := .f.
TRY   
  lRta := wsfev1:Login(".\DRIVERSFC\MiCertificado.crt", ".\DRIVERSFC\MiClavePrivada", "wsfe")
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN 0 
END TRY 
IF lRta 
   TRY
       nFacturaNro := wsfev1:SFRecuperaLastCMP(nPuntoVta, Tipocomp) 
       IF nFacturaNro >= 0 &&Devolucion el ultimo comprobante          
          lRta := .t.
          ELSE
          MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:cLastError+chr(10);
             +"CONECTANDO CON WEB SERVICE","Error" ) 
          nFacturaNro := 0
          lRta := .f.
       ENDIF
    CATCH oError 
        MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al buscar ultimo comprobante" ) 
        RETURN 0 
   END TRY 
   IF nFacturaNro = 0 .and. !lRta
      RETURN 0
   ENDIF
   TRY 
     wsfev1:Reset()  
     nFacturaNro := nFacturaNro + 1 
     //wsfev1:AgregaFactura(1, nTipoDoc, nNroDoc, nFacturaNro, nFacturaNro, fechacmp,;
     //                     nTotal, 0, nNeto, 0, dFecDes, dFecHas, "", "PES", 1)   
     wsfev1:AgregaFactura(Tipocomp, nTipoDoc, nNroDoc, nFacturaNro, fechacmp, ;
                          nTotal, nIIBB, nNeto, 0, dFecDes, dFecHas, "", "PES",;
                           1, 1, 'N' ,nConIva) 
     IF ASCAN({1,6,11,51},Tipocomp) = 0
        IF oQryFac:ticomp = "ND"
           wsfev1:AgregaCompAsoc(IF(cLetra = 'A',2,IF(cLetra = "B",7,IF(cLetra = "C",12,52))),;
               VAL(LEFT(oQryFac:numcomp,4)),VAL(RIGHT(oQryFac:numcomp,8)),wsfev1:cCuitRepresentada,DTOS(oQryFac:fecha))  
           ELSE
           wsfev1:AgregaCompAsoc(IF(cLetra = 'A',1,IF(cLetra = "B",6,IF(cLetra = "C",11,51))),;
               VAL(LEFT(oQryFac:numcomp,4)),VAL(RIGHT(oQryFac:numcomp,8)),wsfev1:cCuitRepresentada,DTOS(oQryFac:fecha))  
        ENDIF   
     ENDIF   
     // Agregar IVAS
     IF cLetra <> "C"
        FOR i := 1 TO LEN(aTablasIvas)
            wsfev1:AgregaIVA(aTablasIvas[i,1], ROUND(aTablasIvas[i,2],2), ROUND(aTablasIvas[i,3],2))
        NEXT i
     ENDIF
     IF nImpInt > 0
        wsfev1:AgregaTributo(4, 'Impuestos Internos', 0,0, nImpInt) 
     ENDIF
     If wsfev1:Autorizar(nPuntoVta, Tipocomp)      
        If wsfev1:cResultado<>"A"              
           lFallo := .t.
           nNro := 0
        ENDIF 
        ELSE
        MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
                wsfev1:cLastError+chr(10);
               +"FEAFIP AUTORIZAR","Error" ) 
        lFallo := .t.
        nNro := 0
     ENDIF     
   CATCH oError 
      MsgInfo( "Error en el Web Service de AFIP "+chr(10)+;
              oError:description+chr(10);
             ,"ENVIO DATOS DE COMPROBANTE" ) 
      RETURN 0 
   END TRY  
   ELSE
   MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:cLastError+chr(10);
             +"FEAFIP CERTIFICADOS","Error" ) 
   lFallo := .t.
   nNro := 0
ENDIF
IF lFallo
   Procesando(.f.)
   IF !EMPTY(wsfev1:aObservaciones)
      xBrowse(wsfev1:aObservaciones,"Error al enviar al WS de ARCA")
   ENDIF   
   RETURN nil
ENDIF
nNro := nFacturaNro
cCae := wsfev1:cCAE
dFecVto := wsfev1:dCAEVto
nTipfor := TipoComp
RETURN nil

STATIC FUNCTION SFecha(f)
LOCAL cF := RIGHT(f,2) + "/" + substr( f, 5, 2 ) + "/" + LEFT(f,4)
RETURN CTOD(cF)