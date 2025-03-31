#include "FiveWin.ch"
#include "Tdolphin.ch"
MEMVAR oApp

PROCEDURE CierreZ
LOCAL cComando , oDlg2, oGet, oBot1, cRta
IF oApp:factura <> 2
   MsgStop("Zeta solo en facturadores fiscales","Error")
   RETURN
ENDIF
IF !FILE("cabecera.dbf") .or. !FILE("cuerpo.dbf") .or. !FILE("config.dbf")
   MsgStop("Faltan archivos fundamentales para la ejecucion del programa","Error")
ENDIF
cComando := oApp:oServer:Query("SELECT imprfiscal FROM ge_"+oApp:cId+"punto WHERE ip ="+;
            ClipValue2Sql(oApp:cIp)):imprfiscal
DELETE FILE RTA.TXT
//Primero cierro por si estaba abierto 
KillP(alltrim(cComando)+'.exe')
WaitRun( cComando + " Z", 0 )
cRta := MemoRead("rta.txt")
IF LEFT(cRta,2) <> "Ok"
   DEFINE DIALOG oDlg2 TITLE "Error Fiscal" FROM 05,15 TO 27,83    
   @ 05,05 SAY  oGet VAR  cRta OF  oDlg2 PIXEL SIZE 170,76      
   @ 90,250 BUTTON oBot1 PROMPT "&Ok" OF oDlg2 SIZE 30,10 ;
           ACTION oDlg2:End() PIXEL   
   ACTIVATE DIALOG oDlg2 CENTER 
ENDIF
RETURN

PROCEDURE CierreX
LOCAL cComando , oDlg2, oGet, oBot1, cRta
IF oApp:factura <> 2
   MsgStop("Zeta solo en facturadores fiscales","Error")
   RETURN
ENDIF
IF !FILE("cabecera.dbf") .or. !FILE("cuerpo.dbf") .or. !FILE("config.dbf")
   MsgStop("Faltan archivos fundamentales para la ejecucion del programa","Error")
ENDIF
cComando := oApp:oServer:Query("SELECT imprfiscal FROM ge_"+oApp:cId+"punto WHERE ip ="+;
            ClipValue2Sql(oApp:cIp)):imprfiscal
DELETE FILE RTA.TXT
//Primero cierro por si estaba abierto 
KillP(alltrim(cComando)+'.exe')
WaitRun( cComando + " X", 0 )
cRta := MemoRead("rta.txt")
IF LEFT(cRta,2) <> "Ok"
   DEFINE DIALOG oDlg2 TITLE "Error Fiscal" FROM 05,15 TO 22,83 
   @ 05, 05 SAY oGet VAR cRta OF  oDlg2 PIXEL SIZE 170,76      
   @120,235 BUTTON oBot1 PROMPT "&Ok" OF oDlg2 SIZE 30,10 ;
           ACTION oDlg2:End()  PIXEL   
   ACTIVATE DIALOG oDlg2 CENTER 
ENDIF
RETURN


FUNCTION FacturaFiscal(oQry,nCliente,cPago,nPago,nDescu,cTipo)
LOCAL cComando , oDlg2, oGet, oBot1, cRta, oQryCli, nFactura, nTasa
DEFAULT cPago := "Su Pago", nPago := 0, nDescu := 0, cTipo := "T"
IF oApp:factura <> 2
   MsgStop("Zeta solo en facturadores fiscales","Error")
   RETURN 0
ENDIF
IF !FILE("cabecera.dbf") .or. !FILE("cuerpo.dbf") .or. !FILE("config.dbf")
   MsgStop("Faltan archivos fundamentales para la ejecucion del programa","Error")
   RETURN 0
ENDIF
cComando := oApp:oServer:Query("SELECT imprfiscal FROM ge_"+oApp:cId+"punto WHERE ip ="+;
            ClipValue2Sql(oApp:cIp)):imprfiscal
KillP(alltrim(cComando)+'.exe')
DELETE FILE RTA.TXT
CLOSE ALL
nCliente := IF(nCliente=0,-1,nCliente)

oQryCli := oApp:oServer:Query("SELECT nombre,direccion,localidad,cuit,coniva "+;
                             " FROM ge_"+oApp:cId+"clientes WHERE codigo = " + ClipValue2Sql(nCliente))
   
   USE cabecera ALIAS "cabe" EXCLUSIVE NEW
   cabe->(DBZAP()) 
   cabe->(DBAPPEND())
   REPLACE cabe->coniva     WITH oQryCli:coniva, cabe->nombre WITH oQryCli:nombre,;
           cabe->direccion  WITH ALLTRIM(oQryCli:direccion) + " "+ ALLTRIM(oQryCli:localidad),;
           cabe->cuit       WITH oQryCli:cuit,;
           cabe->pago       WITH cPago,  cabe->pagoi WITH nPago, cabe->descuen WITH nDescu
   CLOSE cabe 
   USE cuerpo ALIAS "cuer" EXCLUSIVE NEW
   cuer->(DBZAP()) 
   oQry:GoTop()
   DO WHILE !oQry:Eof()
      nTasa := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQry:codiva)):tasa
      cuer->(DBAPPEND())
      REPLACE cuer->detart WITH oQry:detart, cuer->cantidad WITH oQry:cantidad,;
              cuer->precio WITH oQry:punit,;
              cuer->iva    WITH nTasa
      oQry:Skip(1)
   ENDDO
   CLOSE cuer
Procesando(.t.)
//Primero cierro por si estaba abierto 

WaitRun( cComando + " "+cTipo, 0 )
Procesando(.f.)
cRta := MemoRead("rta.txt")
IF LEFT(cRta,2) <> "Ok"
   DEFINE DIALOG oDlg2 TITLE "Error Fiscal" FROM 05,15 TO 22,83 
   @ 05, 05 SAY oGet VAR cRta OF  oDlg2 PIXEL SIZE 170,76      
   @120,235 BUTTON oBot1 PROMPT "&Ok" OF oDlg2 SIZE 30,10 ;
           ACTION oDlg2:End()  PIXEL   
   ACTIVATE DIALOG oDlg2 CENTER 
   RETURN 0
   ELSE
   nFactura := SUBSTR(cRta,3,12)
   nFactura := VAL(nFactura)
ENDIF
RETURN nFactura


************************************************************
** Factura electronica para facturas 
FUNCTION FacturaElec(oGet, nTipoFac, nPuntoVta, nTipoDoc, cLetra, aTablasIvas, oBrw, nNro, ;
         cCae, dFecVto, nTipfor,lRemito, lFacturaD, nCot, cNotaCre)
LOCAL urlwsaa, urlwsw, wsfev1, i, lFallo := .f., j, TipoComp, fechacmp, nFacturaNro, nNroDoc,;
      nTotal, nIva, nNeto, dFecDes, dFecHas, aXml, hFile, oXmlDoc, oXmlIter, oTagActual, oError,;
      nTip := nTipoDoc, nImpInt, nPerce,;
      lRta, oDlg2, aCor, oGet1 := array(3), nComprAsoc := 1, dFecCompAsoc := DATE(), oBot := ARRAY(2),;
      nCotiza := oApp:oServer:Query("SELECT dolar FROM ge_"+oApp:cId+"parametros"):dolar,;
      /*Nuevo*/ oWebSer := TAfip():New()
DEFAULT lRemito:=.f. , lFacturaD := .f.     
nNro := 0      
IF oApp:lDemo
    oWebSer:cWebLogin := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
    oWebSer:cWebService := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
    oWebSer:lProduccion := .f.
ELSE 
    oWebSer:cWebLogin := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
    oWebSer:cWebService := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
    oWebSer:lProduccion := .t.
ENDIF

DO CASE 
   //Facturas
   CASE nTipoDoc = 1 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 1
   CASE nTipoDoc = 1 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 6
   CASE nTipoDoc = 1 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 11
   CASE nTipoDoc = 1 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 51
   //Notas de debito
   CASE nTipoDoc = 2 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 2
   CASE nTipoDoc = 2 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 7
   CASE nTipoDoc = 2 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 12
   CASE nTipoDoc = 2 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 52
   //Notas de credito
   CASE nTipoDoc = 3 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 3
   CASE nTipoDoc = 3 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 8
   CASE nTipoDoc = 3 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 13 
   CASE nTipoDoc = 3 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 53          
ENDCASE  

IF nTip = 3 .or. nTip = 2 
  lRta := .T.
  DEFINE DIALOG oDlg2 TITLE "Comprobante Original" FROM 05,15 TO 12,60 OF oBrw 
   acor := AcepCanc(oDlg2)
   @ 07, 05 SAY "Cbte. Original:" OF oDlg2 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Fecha Cbte:"     OF oDlg2 PIXEL SIZE 40,12 RIGHT   
  
   @ 05, 50 GET oGet1[1] VAR nComprAsoc  PICTURE "99999999" OF oDlg2 PIXEL SIZE 25,12 RIGHT;
                VALID(nComprAsoc > 0 )   
   @ 20, 50 GET oGet1[3] VAR dFecCompAsoc  PICTURE "@d"  OF oDlg2 PIXEL    
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .t.), oDlg2:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .f.), oDlg2:End() ) PIXEL CANCEL
  ACTIVATE DIALOG oDlg2 CENTER ON INIT oGet1[1]:SetFocus()
  IF !lRta
    RETURN 0
  ENDIF  
  cNotaCre := "FC"+cLetra+STRTRAN(STR(nPuntoVta,4)+"-"+STR(nComprAsoc,8)," ","0")  
ENDIF  

IF lFacturaD
  lRta := .T.
  DEFINE DIALOG oDlg2 TITLE "Cotizacion Dolar" FROM 05,15 TO 12,60 OF oBrw 
   acor := AcepCanc(oDlg2)
   @ 07, 05 SAY "Precio por dolar:" OF oDlg2 PIXEL SIZE 60,12 RIGHT
  
   @ 05, 70 GET oGet1[1] VAR nCotiza  PICTURE "99999999.99" OF oDlg2 PIXEL SIZE 25,12 RIGHT;
                VALID(nCotiza > 0 )      
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .t.), oDlg2:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .f.), oDlg2:End() ) PIXEL CANCEL
  ACTIVATE DIALOG oDlg2 CENTER ON INIT oGet1[1]:SetFocus()
  IF !lRta
    RETURN 0
  ENDIF 
  nCot := nCotiza  
  oWebSer:Cotizacion := nCotiza 
ENDIF        

*Tipocomp := 011 &&Factura C( A:001 B:006 NDA: 002 NCA:003 NDB:007 NCB:008 NDC:012 NCC:013)
//fechacmp := DTOS(oGet[01]:value)
oWebSer:FechaOperacion := oGet[01]:value

IF !EMPTY(STRTRAN(oGet[12]:cText,"-",""))
   //CUIT
   oWebSer:DocTipo := 80
   oWebSer:NroCUIT  := VAL(STRTRAN(oGet[12]:cText,"-",""))
   ELSE
   //DNI
   oWebSer:DocTipo := 96
   oWebSer:NroCUIT  := oGet[22]:value
   IF oWebSer:NroCUIT = 0
      oWebSer:DocTipo := 99
   ENDIF
ENDIF

// Valores
nNeto  := IF(cLetra="C",ROUND(oGet[21]:value,2),ROUND(IF(lRemito,oBrw:aCols[6]:nTotal,oBrw:aCols[7]:nTotal),2))
nTotal := ROUND(oGet[21]:value,2)
nIva   := IF(cLetra="C",0,ROUND(IF(lRemito,oBrw:aCols[7]:nTotal,oBrw:aCols[8]:nTotal),2))
nImpInt := 0
IF LEN(oBrw:aCols) > 11
   nImpInt := ROUND(oBrw:aCols[11]:nTotal,2) //Impuestos internos
ENDIF
oWebSer:ImpTotal := nTotal
oWebSer:IVA      := nIva 
oWebSer:subtotal := nNeto 
oWebSer:ImpTrib   := nImpInt
IF nTipoFac=2 .or. nTipoFac = 3
   lRta := .T.
   DEFINE DIALOG oDlg2 TITLE "Datos Período" FROM 05,15 TO 12,60 OF oBrw 
   acor := AcepCanc(oDlg2)
   dFecDes := DATE()
   dFecHas := DATE()
   @ 07, 05 SAY "Desde Fecha:" OF oDlg2 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha:"     OF oDlg2 PIXEL SIZE 40,12 RIGHT   
  
   @ 05, 50 GET oGet1[1] VAR dFecDes  OF oDlg2 PIXEL 
   @ 20, 50 GET oGet1[3] VAR dFecHas  OF oDlg2 PIXEL    
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .t.), oDlg2:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg2 SIZE 30,10 ;
           ACTION ((lrta := .f.), oDlg2:End() ) PIXEL CANCEL
   ACTIVATE DIALOG oDlg2 CENTER ON INIT oGet1[1]:SetFocus()
   IF !lRta
      RETURN 0
   ENDIF
   oWebSer:FechaServ := DTOS(dFecDes)
   oWebSer:FechaVto  := DTOS(dFecHas)
   ELSE 
   oWebSer:FechaServ := ""
   oWebSer:FechaVto  := ""
ENDIF   
IF oApp:lDemo
    oWebSer:CuitEmisor := 20214424666
ELSE
    oWebSer:CuitEmisor := VAL(STRTRAN(oApp:cuit_emp,"-",""))
ENDIF
lRta := oWebSer:login("MiCertificado.crt", "MiClavePrivada")
IF lRta 
   oWebSer:PuntodeVenta :=  nPuntoVta
   nFacturaNro := oWebSer:SFRecuperaLastCMP(@lRta)
   IF nFacturaNro = 0 .and. !lRta
      RETURN 0
   ENDIF
   nFacturaNro := nFacturaNro + 1
   oWebSer:CmpteDesde := int(nFacturaNro)
   oWebSer:CmpteHasta := int(nFacturaNro)
   oWebSer:Percep := ROUND(oGet[38]:value,2)
   oWebSer:Exento := 0
   IF lFacturaD
      oWebSer:ImpTotal := ROUND(nTotal / nCotiza,2)
      oWebSer:subtotal  := ROUND(nNeto / nCotiza,2) 
      oWebSer:Percep := ROUND(oWebSer:Percep / nCotiza,2)       
   ENDIF
   oWebSer:FechaPag := IF(nTipoFac>=2,DTOS(oWebSer:FechaOperacion),"")
   oWebSer:conceptos := nTipoFac   
   oWebSer:CondIva := oGet[13]:nAt
   oWebSer:CantReg := 1
   oWebSer:Cabecera()
   //TRY 
     IF lFacturaD
        oWebSer:moneda := "DOL"
        oWebSer:AgregaFactura() 
        oWebSer:AbonaEnDolar := "S"
        ELSE  
        oWebSer:moneda := "PES"
        oWebSer:Cotizacion := 1
        oWebSer:AbonaEnDolar := "N"
        oWebSer:AgregarFactura()   
     ENDIF   
     IF nTip = 3 .or. nTip = 2
        oWebSer:aComprobantesAsociados := {{IF(cLetra = 'A',1,IF(cLetra = "B",6,IF(cLetra = "C",11,53))),;
                                           nPuntoVta,nComprAsoc,,DTOS(dFecCompAsoc)}}
        oWebSer:AgregaCompAsoc()  //IF(cLetra = 'A',1,IF(cLetra = "B",6,IF(cLetra = "C",11,53))),nPuntoVta,nComprAsoc,wsfev1:CUIT,DTOS(dFecCompAsoc))
     ENDIF
   /*CATCH oError 
        MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al Agregar factura /Comp.Asociado " ) 
        RETURN 0 
   END TRY */
   // Agregar IVAS
   TRY 
     IF cLetra <> "C"
        FOR i := 1 TO LEN(aTablasIvas)
            IF lFacturaD
               AADD(oWebSer:aTasasIva,{aTablasIvas[i,1], ROUND(aTablasIvas[i,2]/nCotiza,2), ROUND(aTablasIvas[i,3]/nCotiza,2)})
               //wsfev1:AgregaIVA(aTablasIvas[i,1], ROUND(aTablasIvas[i,2]/nCotiza,2), ROUND(aTablasIvas[i,3]/nCotiza,2))
               ELSE
               AADD(oWebSer:aTasasIva,{aTablasIvas[i,1], ROUND(aTablasIvas[i,2],2), ROUND(aTablasIvas[i,3],2)})
               //wsfev1:AgregaIVA(aTablasIvas[i,1], ROUND(aTablasIvas[i,2],2), ROUND(aTablasIvas[i,3],2))
            ENDIF   
        NEXT i
        oWebSer:AgregaIva()
     ENDIF
     IF nImpInt > 0
        IF lFacturaD
           nImpInt := ROUND(nImpInt / nCotiza,2) 
        ENDIF 
        oWebSer:aOtrosTributos := {{4, 'Impuestos Internos', 0,0, nImpInt}}   
        oWebSer:AgregaTributo()
     ENDIF
     oWebSer:Pie()
     If oWebSer:Autorizar()    
        lFallo := .f.     
        ELSE 
        nNro := 0
        lFallo := .t.
     ENDIF
   CATCH oError 
         MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al Agregar Autorizar " ) 
        RETURN 0 
   END TRY  
   ELSE
   MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oWebSer:oFeAfip:ErrorDesc+chr(10);
             +"FEAFIP CERTIFICADOS","Error" ) 
   lFallo := .t.
   nNro := 0
ENDIF
IF lFallo   
   RETURN nil
ENDIF
nNro := oWebSer:nNro
cCae := oWebSer:cCae
dFecVto := sFecha(oWebSer:dFecVto)
nTipfor := oWebSer:TipoComprobante
RETURN nil

******************************************************************************************
** Factura electronica para tickets
FUNCTION FacturaElec1( nPuntoVta, nTipoDoc, cLetra, aTablasIvas, nNro, cCae, dFecVto, nTipfor,;
                     dFecComp,cCuit,nDni,nImpNeto,nImpIva,nImpTotal,nImpInt)
LOCAL urlwsaa, urlwsw, wsfev1, i, lFallo := .f., j, TipoComp, fechacmp, nFacturaNro, nNroDoc,;
      nTotal, nIva, nNeto, dFecDes, dFecHas, aXml, hFile, oXmlDoc, oXmlIter, oTagActual, oError, lRta,;
      /*Nuevo*/ oWebSer := TAfip():New()
     
nNro := 0      

IF oApp:lDemo
    oWebSer:cWebLogin := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
    oWebSer:cWebService := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
    oWebSer:lProduccion := .f.
ELSE 
    oWebSer:cWebLogin := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
    oWebSer:cWebService := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
    oWebSer:lProduccion := .t.
ENDIF

DO CASE 
   //Facturas
   CASE nTipoDoc = 1 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 1
   CASE nTipoDoc = 1 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 6
   CASE nTipoDoc = 1 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 11
   CASE nTipoDoc = 1 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 51
   //Notas de debito
   CASE nTipoDoc = 2 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 2
   CASE nTipoDoc = 2 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 7
   CASE nTipoDoc = 2 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 12
   CASE nTipoDoc = 2 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 52
   //Notas de credito
   CASE nTipoDoc = 3 .AND. cLetra = "A"
        oWebSer:TipoComprobante := 3
   CASE nTipoDoc = 3 .AND. cLetra = "B"     
        oWebSer:TipoComprobante := 8
   CASE nTipoDoc = 3 .AND. cLetra = "C"     
        oWebSer:TipoComprobante := 13 
   CASE nTipoDoc = 3 .AND. cLetra = "M"     
        oWebSer:TipoComprobante := 53          
ENDCASE            

IF EMPTY(STRTRAN(cCuit,"-","")) .AND. cLetra = 'A'
   nNro := 0
   MsgStop("El cliente elegido es INSCRIPTO y no tiene CUIT"+CHR(10)+"Corrija","Error")
   RETURN nil
ENDIF


*Tipocomp := 011 &&Factura C( A:001 B:006 NDA: 002 NCA:003 NDB:007 NCB:008 NDC:012 NCC:013)

oWebSer:FechaOperacion := dFecComp

IF !EMPTY(STRTRAN(cCuit,"-",""))
   //CUIT
   oWebSer:DocTipo := 80
   oWebSer:NroCUIT  := VAL(STRTRAN(cCuit,"-",""))
   ELSE
   //DNI
   oWebSer:DocTipo := 96
   oWebSer:NroCUIT  := nDni
   IF oWebSer:NroCUIT = 0
      oWebSer:DocTipo := 99
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
oWebSer:ImpTotal := nTotal
oWebSer:IVA      := nIva 
oWebSer:subtotal := nNeto 
oWebSer:ImpTrib   := nImpInt

oWebSer:FechaServ := ""
oWebSer:FechaVto  := ""
IF oApp:lDemo
    oWebSer:CuitEmisor := 20214424666
ELSE
    oWebSer:CuitEmisor := VAL(STRTRAN(oApp:cuit_emp,"-",""))
ENDIF
lRta := oWebSer:login("MiCertificado.crt", "MiClavePrivada")
IF lRta 
   oWebSer:PuntodeVenta :=  nPuntoVta
   nFacturaNro := oWebSer:SFRecuperaLastCMP(@lRta)
   IF nFacturaNro = 0 .and. !lRta
      RETURN 0
   ENDIF   
   nFacturaNro := nFacturaNro + 1
   oWebSer:CmpteDesde := int(nFacturaNro)
   oWebSer:CmpteHasta := int(nFacturaNro)
   oWebSer:Percep := 0.00
   oWebSer:Exento := 0.00
   
   oWebSer:FechaPag := ""
   oWebSer:conceptos := 1   
   oWebSer:CondIva := 5
   oWebSer:CantReg := 1
   oWebSer:Cabecera()
   oWebSer:moneda := "PES"
   oWebSer:Cotizacion := 1
   oWebSer:AbonaEnDolar := "N"
   oWebSer:AgregarFactura()
   TRY 
     IF cLetra <> "C"
        FOR i := 1 TO LEN(aTablasIvas)
            AADD(oWebSer:aTasasIva,{aTablasIvas[i,1], ROUND(aTablasIvas[i,2],2), ROUND(aTablasIvas[i,3],2)})            
        NEXT i
        oWebSer:AgregaIva()
     ENDIF
     IF nImpInt > 0        
        oWebSer:aOtrosTributos := {{4, 'Impuestos Internos', 0,0, nImpInt}}   
        oWebSer:AgregaTributo()
     ENDIF
     oWebSer:Pie()
     If oWebSer:Autorizar()    
        lFallo := .f.     
        ELSE 
        nNro := 0
        lFallo := .t.
     ENDIF
   CATCH oError 
         MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al Agregar Autorizar " ) 
        RETURN 0 
   END TRY    
   ELSE
   MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:ErrorDesc+chr(10);
             +"FEAFIP CERTIFICADOS","Error" ) 
   lFallo := .t.
   nNro := 0
ENDIF
IF lFallo   
   RETURN nil
ENDIF
nNro := oWebSer:nNro
cCae := oWebSer:cCae
dFecVto := sFecha(oWebSer:dFecVto)
nTipfor := oWebSer:TipoComprobante
RETURN nil

STATIC FUNCTION SFecha(f)
LOCAL cF := RIGHT(f,2) + "/" + substr( f, 5, 2 ) + "/" + LEFT(f,4)
RETURN CTOD(cF)

********************************
** Consultar comprobante en AFIP
FUNCTION ConsultarComprobante(nTipoDoc,cLetra,nPto,nNumero)
LOCAL urlwsaa, urlwsw, wsfev1, i, lFallo := .f., j, TipoComp, fechacmp, nFacturaNro, nNroDoc,;
      nTotal, nIva, nNeto, dFecDes, dFecHas, aXml, hFile, oXmlDoc, oXmlIter, oTagActual, oError
         
IF oApp:lDemo
    URLWSAA := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
    URLWSW := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
ELSE 
    URLWSAA := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
    URLWSW := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
ENDIF

DO CASE 
   //Facturas
   CASE nTipoDoc = 1 .AND. cLetra = "A"
        Tipocomp := 1
   CASE nTipoDoc = 1 .AND. cLetra = "B"     
        Tipocomp := 6
   CASE nTipoDoc = 1 .AND. cLetra = "C"     
        Tipocomp := 11
   //Notas de debito
   CASE nTipoDoc = 2 .AND. cLetra = "A"
        Tipocomp := 2
   CASE nTipoDoc = 2 .AND. cLetra = "B"     
        Tipocomp := 7
   CASE nTipoDoc = 2 .AND. cLetra = "C"     
        Tipocomp := 12
   //Notas de credito
   CASE nTipoDoc = 3 .AND. cLetra = "A"
        Tipocomp := 3
   CASE nTipoDoc = 3 .AND. cLetra = "B"     
        Tipocomp := 8
   CASE nTipoDoc = 3 .AND. cLetra = "C"     
        Tipocomp := 13          
ENDCASE          

TRY 
    wsfev1 := CreateObject("FEAFIPLib.wsfev1")
    IF oApp:lDemo
        wsfev1:CUIT := 20214424666
    ELSE
        wsfev1:CUIT := VAL(STRTRAN(oApp:cuit_emp,"-",""))
    ENDIF
CATCH oError 
    MsgInfo( "No esta el Driver fiscal registrado..."+chr(10)+;
             "Para poder emitir factura electronica"+chr(10)+;
             "debe tener instalado el driver fiscal."+chr(10)+;
             "Ejecute el programa REGISTRA.EXE que"+chr(10)+;
             "Esta en la carpeta DRIVERFC dentro de"+chr(10)+;
             "la carpeta donde instalo el sistema."+chr(10)+;
             "Hagalo con permisos de administrador";
             ,"Error" ) 
    RETURN 0 
END TRY 
wsfev1:URL  := URLWSW
If wsfev1:login("MiCertificado.crt", "MiClavePrivada", URLWSAA)
   If wsfev1:SFCmpConsultar(Tipocomp,nPto,nNumero) 
       MemoWrit("error.xml",wsfev1:xmlresponse)    
       aXml := {}
       hFile    := FOpen( "error.xml" ) 
       oXmlDoc  := TXmlDocument():New( hFile )
       oXmlIter := TXmlIterator():New( oXmlDoc:oRoot )
       while .T.
          oTagActual = oXmlIter:Next()
          If oTagActual != nil
             AADD(aXml, {oTagActual:cName, oTagActual:cData} )
             HEval( oTagActual:aAttributes, { | cKey, cValue | AADD(aXml, {cKey, cValue} ) } )
          Else
             Exit
          Endif
       End
       FClose( hFile )       
       xBrowse(aXml,"Resultado del Consulta")
      ELSE
      MsgInfo(wsfev1:ErrorDesc, "FEAFIP RECUPERANDO ULTIMO COMPROBANTE")
      RETURN nil
   ENDIF
ENDIF
RETURN nil


STATIC function KillP(cFile)

   KillProcessByName( cFile )

return nil

#pragma BEGINDUMP

#include <Windows.h>
#include <hbapi.h>
#include <string.h>
#include <tlhelp32.h>

void killProcessByName(const char *filename)
{
    HANDLE hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, NULL);
    PROCESSENTRY32 pEntry;
    BOOL hRes;

    pEntry.dwSize = sizeof (pEntry);
    hRes = Process32First(hSnapShot, &pEntry);
   
    while (hRes)
    {
        if (strcmp(pEntry.szExeFile, filename) == 0)
        {
            HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, 0,
                                          (DWORD) pEntry.th32ProcessID);
            if (hProcess != NULL)
            {
                TerminateProcess(hProcess, 9);
                CloseHandle(hProcess);
            }
        }
        hRes = Process32Next(hSnapShot, &pEntry);
    }
    CloseHandle(hSnapShot);
}

HB_FUNC( KILLPROCESSBYNAME )
{
   killProcessByName( hb_parc( 1 ) );
}

#pragma ENDDUMP