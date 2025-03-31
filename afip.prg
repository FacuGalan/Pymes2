#include "FiveWin.ch"

/*Clase para manejar Web Service Afip*/
CLASS TAfip
   DATA   Token           // Token devuelto por FEAFIP
   DATA   Sign            // Sign devuelto por FEAFIP
   DATA   lProduccion     // .f. modo homologacion .t. modo produccion
   DATA   oFeAfip         // Objeto FeAfip.dll 
   DATA   cXml            // xml para enviar 

   DATA   cCertificado    // Archivo de Certificados
   DATA   cClavePrivada   // Archivo de clave privada
   DATA   cWebService     // Ruta de WebService
   DATA   cWebLogin       // Ruta de WebLogin

   DATA   Conceptos       // Tipo de facturacion
   DATA   CuitEmisor      // Cuit con que se hace la factura Electronica
   DATA   CantReg         // Cantidad de comprobantes solicitados
   DATA   PuntodeVenta    // Nro de Punto de Venta
   DATA   TipoComprobante // Codigo de tipo de comprobante
   DATA   DocTipo         // Tipo de documento del cliente
   DATA   NroCUIT         //Nro de CUIT al que se le hace la factura
   DATA   CmpteDesde      //Comprobante desde
   DATA   CmpteHasta      //Comprobante Hasta
   DATA   FechaOperacion  //Fecha del comprobante
   DATA   ImpTotal        //Importe total del comprobante 
   DATA   Percep          //Total percepciones
   DATA   Subtotal        //Subtotal 
   DATA   Exento          //Conceptos Excentos
   DATA   FechaServ       //Fecha desde para Servicios
   DATA   FechaVto        //Fecha hasta para Servicios
   DATA   FechaPag        //Fecha pago Servicios
   DATA   Moneda          //Moneda de Pago
   DATA   Cotizacion      //Cotizacion de la moneda             
   DATA   ImpTrib         //Importe otros tributos             
   DATA   Iva             //Importe IVA
   DATA   AbonaEnDolar    //Indica si se va a cobrar en dolares             
   DATA   CondIva         //Condicion del IVA del cliente

   //Tablas
   DATA   aComprobantesAsociados //Tabla de comprobantes asociados
   DATA   aOtrosTributos         //Tabla de Otros tributos
   DATA   aTasasIva              //Tabla de IVAS
   DATA   aOpcionales            //Tabla de Opcionales
   DATA   aPeriodoAsociado       //Tabla de Periodos Asociados   

   //Data de Respuesta
   DATA  nNro 
   DATA  cCae 
   DATA  dFecVto
   DATA  cRespuesta 
   DATA  cMotivo


   METHOD New() 
   METHOD Login(cCertificado, cClavePrivada)
   METHOD SFRecuperaLastCMP()
   METHOD Cabecera()
   METHOD AgregarFactura()
   METHOD AgregaCompAsoc()
   METHOD AgregaTributo()
   METHOD AgregaIva()
   METHOD AgregaOpcional()
   METHOD PeriodoAsoc()  
   METHOD Pie()



   METHOD Autorizar()

ENDCLASS

//----------------------------------------------------------------//

METHOD New() CLASS TAfip
   ::Token := ""
   ::Sign  := ""
   ::lProduccion := .f.
   ::cXml := ""

   ::cCertificado  := 'MiCertificado.crt'
   ::cClavePrivada := 'MiClavePrivada'
   ::cWebService   := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
   ::cWebLogin     := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms" 
   ::CuitEmisor    := 20214424666
   ::PuntodeVenta  := 1
   ::Moneda        := 'PES'
   ::Cotizacion    := 1
   ::AbonaEnDolar  := "N"
   ::CondIva       := 5
   ::Exento        := 0.00

   //Tablas
   ::aComprobantesAsociados := {}
   ::aOtrosTributos         := {}
   ::aTasasIva         		:= {}
   ::aOpcionales       		:= {}
   ::aPeriodoAsociado  		:= {}
    

return Self

METHOD Login(cCertificado, cClavePrivada) CLASS TAfip
LOCAL oError, lRta := .F.
TRY 
    ::oFeAfip := CreateObject("FEAFIPLib.wsfev1")
    IF !::lProduccion        
        ::cWebLogin  := "https://wsaahomo.afip.gov.ar/ws/services/LoginCms"
        ::cWebService    := "https://wswhomo.afip.gov.ar/wsfev1/service.asmx"
    ELSE
        ::cWebLogin  := "https://wsaa.afip.gov.ar/ws/services/LoginCms"
        ::cWebService     := "https://servicios1.afip.gov.ar/wsfev1/service.asmx"
    ENDIF    
CATCH oError 
    MsgInfo( "No esta el Driver fiscal registrado..."+chr(10)+;
             "Para poder emitir factura electronica"+chr(10)+;
             "debe tener instalado el driver fiscal."+chr(10)+;
             "Ejecute el programa REGISTRA.BAT que"+chr(10)+;
             "Esta en la carpeta DRIVERFC dentro de"+chr(10)+;
             "la carpeta donde instalo el sistema."+chr(10)+;
             "Hagalo con permisos de administrador";
             ,"Error" ) 
    RETURN .f. 
END TRY 
TRY 
  ::oFeAfip:CUIT := ::CuitEmisor	
  ::oFeAfip:URL  := ::cWebService
  lRta := ::oFeAfip:login(cCertificado, cClavePrivada, ::cWebLogin)
  IF !lRta 
     MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              ::oFeAfip:ErrorDesc+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  ENDIF   
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN .f.
END TRY

::Token := ::oFeAfip:Token()
::Sign  := ::oFeAfip:Sign()
return lRta

METHOD SFRecuperaLastCMP(lRta)
LOCAL nFacturaNro := 0, oError
lRta := .f.
TRY
       If ::oFeAfip:SFRecuperaLastCMP(::PuntodeVenta, ::TipoComprobante) 
          nFacturaNro := ::oFeAfip:SFLastCmp &&Devolucion el ultimo comprobante          
          lRta := .t.
          ELSE
          MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              ::oFeAfip:ErrorDesc+chr(10);
             +"CONECTANDO CON WEB SERVICE","Error" ) 
          nFacturaNro := 0          
       ENDIF
CATCH oError 
        MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al buscar ultimo comprobante" ) 
        RETURN 0 
END TRY
RETURN nFacturaNro

METHOD Cabecera() CLASS TAfip
::oFeAfip:Reset() 
::cXml:='<?xml version="1.0" encoding="UTF-8"?>'+CRLF+;
      '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+CRLF+;
      '   <soap:Header/>'+CRLF+;
      '   <soap:Body>'+CRLF+;
      '       <FECAESolicitar xmlns="http://ar.gov.afip.dif.FEV1/">'+CRLF+;
      '           <Auth>'+CRLF+;
      '            <Token>'+alltrim(::Token)+'</Token>'+CRLF+;
      '             <Sign>'+alltrim(::Sign)+'</Sign>'+CRLF+;
      '             <Cuit>'+Alltrim(str(::CuitEmisor))+'</Cuit>'+CRLF+;
      '           </Auth>'+CRLF+;
      '           <FeCAEReq>'+CRLF+;
      '               <FeCabReq>'+CRLF+;
      '                  <CantReg>'+Alltrim(str(::CantReg))+'</CantReg>'+CRLF+;    // por ahora mando uno (cant de fact a autorizar)
      '                  <PtoVta>'+Alltrim(str(::PuntodeVenta))+'</PtoVta>'+CRLF+;
      '                   <CbteTipo>'+Alltrim(str(::TipoComprobante))+'</CbteTipo>'+CRLF+;
      '               </FeCabReq>'+CRLF+;
      '               <FeDetReq>'+CRLF+;
      '                  <FECAEDetRequest>'+CRLF
RETURN nil

METHOD Pie() CLASS TAfip
::cXml+='                   </FECAEDetRequest>'+CRLF+;
      '               </FeDetReq>'+CRLF+;
      '           </FeCAEReq>'+CRLF+;
      '       </FECAESolicitar>'+CRLF+;
      '   </soap:Body>'+CRLF+;
      '</soap:Envelope>'
RETURN nil

METHOD AgregarFactura() CLASS TAfip
::cXml+='                 <Concepto>'+NumeroAString(::Conceptos)+'</Concepto>'+CRLF+;
      '                   <DocTipo>'+NumeroAString(::DocTipo)+'</DocTipo>'+CRLF+;
      '                   <DocNro>'+NumeroAString(::NroCUIT)+'</DocNro>'+CRLF+;
      '                   <CbteDesde>'+NumeroAString(::CmpteDesde)+'</CbteDesde>'+CRLF+;
      '                   <CbteHasta>'+NumeroAString(::CmpteHasta)+'</CbteHasta>'+CRLF+;
      '                   <CbteFch>'+DTOS(::FechaOperacion)+'</CbteFch>'+CRLF+;
      '                   <ImpTotal>'+NumeroAString(::ImpTotal)+'</ImpTotal>'+CRLF+;
      '                   <ImpTotConc>'+NumeroAString(::Percep)+'</ImpTotConc>'+CRLF+;
      '                   <ImpNeto>'+NumeroAString(::SubTotal)+'</ImpNeto>'+CRLF+;
      '                   <ImpOpEx>'+NumeroAString(::Exento)+'</ImpOpEx>'+CRLF+;
      '                   <ImpTrib>'+NumeroAString(::ImpTrib)+'</ImpTrib>'+CRLF+;
      '                   <ImpIVA>'+NumeroAString(::IVA)+'</ImpIVA>'+CRLF+;
      '                   <FchServDesde>'+::FechaServ+'</FchServDesde>'+CRLF+;
      '                   <FchServHasta>'+::FechaVto+'</FchServHasta>'+CRLF+;
      '                   <FchVtoPago>'+::FechaPag+'</FchVtoPago>'+CRLF+;
      '                   <MonId>'+::Moneda+'</MonId>'+CRLF+;
      '                   <MonCotiz>'+NumeroAString(::Cotizacion)+'</MonCotiz>'+CRLF+;
      '                   <CanMisMonExt>'+::AbonaEnDolar+'</CanMisMonExt>'+CRLF+;
      '                   <CondicionIVAReceptorId>'+NumeroAString(::CondIva)+'</CondicionIVAReceptorId>'+CRLF
RETURN nil

METHOD AgregaCompAsoc() CLASS TAfip
LOCAL i
::cXml+='                   <CbtesAsoc>'+CRLF+;
        '                       <CbteAsoc>'+CRLF
FOR i:=1 TO LEN(::aComprobantesAsociados)
  ::cXml+='                         <Tipo>'+NumeroAString(::aComprobantesAsociados[i][1])+'</Tipo>'+CRLF+;
        '                           <PtoVta>'+NumeroAString(::aComprobantesAsociados[i][2])+'</PtoVta>'+CRLF+;
        '                           <Nro>'+NumeroAString(::aComprobantesAsociados[i][3])+'</Nro>'+CRLF+;
        '                           <Cuit>'+NumeroAString(::CuitEmisor)+'</Cuit>'+CRLF+;
        '                           <CbteFch>'+::aComprobantesAsociados[i][5]+'</CbteFch>'+CRLF
NEXT i
::cXml+='                       </CbteAsoc>'+CRLF+;
        '                   </CbtesAsoc>'+CRLF
RETURN nil

METHOD AgregaTributo() CLASS TAfip
LOCAL i
::cXml+='                   <Tributos>'+CRLF+;
        '                       <Tributo>'+CRLF
FOR i:=1 TO LEN(::aOtrosTributos)
  ::cXml+='                         <Id>'+NumeroAString(::aOtrosTributos[i][1])+'</Id>'+CRLF+;
        '                           <Desc>'+alltrim(::aOtrosTributos[i][2])+'</Desc>'+CRLF+;
        '                           <BaseImp>'+NumeroAString(::aOtrosTributos[i][3])+'</BaseImp>'+CRLF+;
        '                           <Alic>'+NumeroAString(::aOtrosTributos[i][4])+'</Alic>'+CRLF+;
        '                           <Importe>'+NumeroAString(::aOtrosTributos[i][5])+'</Importe>'+CRLF
NEXT        
::cXml+='                       </Tributo>'+CRLF+;
        '                   </Tributos>'+CRLF
RETURN nil

METHOD AgregaIva() CLASS TAfip
LOCAL i
::cXml+='                   <Iva>'+CRLF+;
        '                       <AlicIva>'+CRLF
FOR i := 1 TO LEN(::aTasasIva)
  ::cXml+='                           <Id>'+NumeroAString(::aTasasIva[i][1])+'</Id>'+CRLF+;
          '                           <BaseImp>'+NumeroAString(::aTasasIva[i][2])+'</BaseImp>'+CRLF+;
          '                           <Importe>'+NumeroAString(::aTasasIva[i][3])+'</Importe>'+CRLF
NEXT        
::cXml+='                       </AlicIva>'+CRLF+;
        '                   </Iva>'+CRLF
RETURN nil

METHOD AgregaOpcional() CLASS TAfip
LOCAL i
::cXml+='                   <Opcionales>'+CRLF+;
        '                       <Opcional>'+CRLF
FOR i := 1 TO LEN(::aOpcionales)
  ::cXml+='                           <Id>'+::aOpcional[i][1]+'</Id>'+CRLF+;
          '                           <Valor>'+::aOpcional[i][2]+'</Valor>'+CRLF
NEXT        
::cXml+='                       </Opcional>'+CRLF+;
        '                   </Opcionales>'+CRLF
RETURN nil

METHOD PeriodoAsoc() CLASS TAfip
LOCAL i
::cXml+='                   <PeriodoAsoc>'+CRLF+;
        '                       <FchDesde>'+::aPeriodoAsociado[i][1]+'</FchDesde>'+CRLF+;
        '                       <FchHasta>'+::aPeriodoAsociado[i][2]+'</FchHasta>'+CRLF+;
        '                   </PeriodoAsoc>'+CRLF
RETURN nil


METHOD Autorizar() CLASS TAfip

Local oWSFE:='', lRet := .f.
Local cRespuesta
// Creo y Valido el Objeto oWSFE
oWSFE := CreateObject('MSXML2.XMLHTTP')
IF Empty(oWSFE)
   MsgStop("No pudo crear el objeto oWSFE!","Error 1010")
   return .f.
ELSE  
  // Llamo al Webservice y Defino Opciones
  oWSFE:Open('POST',::cWebService + '?op=FECAESolicitar',.f.)
  oWSFE:SetRequestHeader('SOAPAction','http://ar.gov.afip.dif.FEV1/FECAESolicitar')
  oWSFE:SetRequestHeader("Content-Type","text/xml;charset=UTF-8")
  oWSFE:SetRequestHeader('Connection','Keep-Alive')
  // Envio el Archivo y Recibo la Respuesta del WS
  memowrit('xmlenvia.xml',::cXml)
  oWSFE:Send(::cXml)
  // Si el status es diferente a 200, ocurrió algún error de conectividad con el WS
  IF !Empty(oWSFE:ResponseText)
     memowrit('xmlresponse.xml',oWSFE:ResponseText)
    IF !Empty(cRespuesta:=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Resultado"},oWSFE:ResponseText))
      ::nNro := VAL(cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","CbteDesde"},oWSFE:ResponseText))
      DO CASE
        CASE cRespuesta="A"    // Aprobado
          ::cCae := cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","CAE"},oWSFE:ResponseText)
          ::dFecVto := cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","CAEFchVto"},oWSFE:ResponseText)
          ::cMotivo := ""
          lRet := .t.
          //aTabla["codebar"]:=CalculoCodigoVerificador(PADL(aTabla["CuitEmisor"],11,"0")+PADL(aTabla["TipoComprobante"],2,"0")+PADL(aTabla["PuntodeVenta"],4,"0")+PADL(aTabla["ncae"],14,"0")+alltrim(aTabla["fvto"]))
          //aReturn:={"A",aTabla["ncae"],aTabla["fvto"],aTabla["nro"],0,"",aTabla["codebar"]}
        CASE cRespuesta="P"    // Aprobado con Observaciones
          ::cCae := cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","CAE"},oWSFE:ResponseText)
          ::cFecVto := cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","CAEFchVto"},oWSFE:ResponseText)
          ::cMotivo := cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Obs","Observaciones","Msg"},oWSFE:ResponseText) 
          lRet := .t.
          MsgInfo("El comprobante ha sido autorizado con Observaciones: "+ALLTRIM(::cMotivo),"Atencion")
        CASE cRespuesta="R"    // Rechazado
          //::cMotivo :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Obs","Observaciones","Code"},oWSFE:ResponseText)  
          ::cMotivo :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Obs","Observaciones","Msg" },oWSFE:ResponseText)           
          MsgStop("El comprobante ha sido RECHAZADO con la siguiente Observación: "+ALLTRIM(::cMotivo),"Error")
        OTHERWISE
          //aTabla["err"] :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Obs","Observaciones","Code"},oWSFE:ResponseText) 
          ::cMotivo :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","FeDetResp","FECAEDetResponse","Obs","Observaciones","Msg"} ,oWSFE:ResponseText) 
          //aReturn:={"X","","",0,aTabla["err"],aTabla["obs"],""}
          MsgStop(::cMotivo,"Error")
      ENDCASE    
    ELSE
      //aTabla["err"] :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","Errors","Code"},oWSFE:ResponseText) 
      ::cMotivo :=cValorXML({"FECAESolicitarResponse","FECAESolicitarResult","Errors","Msg"} ,oWSFE:ResponseText) 
      //aReturn:={"X","","",0,aTabla["err"],aTabla["obs"],""}
      MsgStop(::cMotivo,"Error")
    ENDIF  
  ELSE
    //aReturn:={"X","","",0,-1,"Respuesta Vacía del WebService",""}
    ::cMotivo := "Error al conectarse con el Web Service de AFIP"
    MsgStop(::cMotivo,"Error")
  ENDIF
ENDIF  
RETURN lRet

//----------------------------------------------------------------------------//

STATIC FUNCTION cValorXML( caFieldName, cXML, cVarName, nStart )
*BUSCA VALORES DENTRO DE UNA CADENA XML
local cValue:= "", n
if ValType(caFieldName)$"C"
  caFieldName:= { caFieldName }
endif
for n = 1 to Len(caFieldName)
  cValue:= __cValorXML( caFieldName[n], ;
                        cXML, ;
                        if(n=Len(caFieldName),cVarName,),;
                        nStart )
  cXML:= cValue  // Proximas anidaciones !!!
  nStart:= NIL   // Hernan 19/02/2014 - Ya esta acotada la cadena cXML la primera interaccion recorta la repeticion
next
cValue:= StrTran(cValue,"&amp;#186",Chr(186))
return cValue

//----------------------------------------------------------------------------//

STATIC FUNCTION __cValorXML( cFieldName, cXML, cVarName, nStart )
local nAt1, nAt2
local cValue:= ""
local cDebug:= ""
local nOccurrence:= 0

DEFAULT nStart:= 1

cXML:= StrTran( cXML,'&lt;','<')
cXML:= StrTran( cXML,'&gt;','>')
cFieldName:= StrTran( cFieldName, "<", "" )
cFieldName:= StrTran( cFieldName, ">", "" )
cFieldName:= Upper( AllTrim( cFieldName ) )

// Hernan 27/04/2010 - Implementando AtNro anda mas rapido para un nStart > 1 !!!
nAt1:= AtNro( "<" + cFieldName + ">", Upper(cXML), nStart )
// Hernan 03/05/2011 - Primero lo busque estrictamente con Terminador >
// sino sin el terminador (hay algunos con espacio a la derecha y mas datos antes del terminador)
if nAt1 = 0
  nAt1:= AtNro( "<" + cFieldName, Upper(cXML), nStart )
endif
nAt2:= AtNro( "</" + cFieldName + ">", Upper(cXML), nStart )
if nAt1 > 0 .and. nAt2 > 0
  nAt1+= Len(cFieldName) + 2
  cValue:= SubStr(cXML, nAt1, nAt2-nAt1)
endif
// Si quiere un valor especifico de la cadena, tipico VAR=PEPE, VAR2=XXXXX
if ValType(cVarName)$"C" .and. !Empty(cValue)
  cVarName:= AllTrim(Upper(cVarName)) + "="
  nAt1:= At( cVarName , Upper(cValue) )
  if nAt1 > 0
    cValue:= SubStr( cValue, nAt1 + Len(cVarName) )
    nAt1:= At( ",", Upper( cValue ) )
    if nAt1 > 0
      cValue:= RTrim( SubStr( cValue, 1, nAt1-1 ) )
    endif
  endif
else
  cVarName:= ""
endif
return cValue

//----------------------------------------------------------------------------//

STATIC function AtNro( cSearch, cTarget, nOcurrence )
local nAt:= 0
local nDeletedBytes:= 0, nAtTmp:= 0, nOcurrenceTmp:= 0
if !ValType( nOcurrence )$"N"
  nOcurrence:= 1
endif
nOcurrence:= Max(nOcurrence,1)
while .T.
  if ( nAtTmp:= At( cSearch, cTarget ) ) > 0
    nOcurrenceTmp++
    if nOcurrenceTmp >= nOcurrence
      nAt:= nAtTmp + nDeletedBytes
      exit
    endif
    nDeletedBytes+= nAtTmp
    cTarget:= SubStr( cTarget, nAtTmp + 1 )
  else
    exit
  endif
enddo
return nAt

STATIC FUNCTION NumeroAString(nNumero)
RETURN LTRIM(STR(nNumero))