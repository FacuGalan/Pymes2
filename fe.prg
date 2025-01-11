#include "FiveWin.ch"
#include "Tdolphin.ch"
MEMVAR oApp
/*
PROCEDURE ReportarError(Titulo)
 LOCAL cMsg := "", nI , aPRNStat := ARRAY(16), aFISStat := ARRAY(16)
 IF PCOUNT() = 0
    Titulo := "-"
 ENDIF

 aPRNStat[01] = "Bit  1 " + "Impresora Ocupada"
 aPRNStat[02] = "Bit  2 " + "Impresora Seleccionada"
 aPRNStat[03] = "Bit  3 " + "Error en la Impresora"
 aPRNStat[04] = "Bit  4 " + "Impresora Fuera de L¡nea"
 aPRNStat[05] = "Bit  5 " + "Poco papel auditor¡a"
 aPRNStat[06] = "Bit  6 " + "Poco papel"
 aPRNStat[07] = "Bit  7 " + "Buffer impresora lleno"
 aPRNStat[08] = "Bit  8 " + "Buffer impresora vacio"
 aPRNStat[09] = "Bit  9 " + "Sin uso"
 aPRNStat[10] = "Bit 10 " + "Sin uso"
 aPRNStat[11] = "Bit 11 " + "Sin uso"
 aPRNStat[12] = "Bit 12 " + "Sin uso"
 aPRNStat[13] = "Bit 13 " + "Caj¢n de Dinero Abierto"
 aPRNStat[14] = "Bit 14 " + "Sin uso"
 aPRNStat[15] = "Bit 15 " + "Impresora sin Papel"
 aPRNStat[16] = "Bit 16 " + "Bits 0-6 Activados"

 **  Estados FISCALES 

 aFISStat[01] =  "Bit  1 " + "Checkeo de Memoria Fiscal !MAL!"
 aFISStat[02] =  "Bit  2 " + "Checkeo RAM de Trabajo !MAL!"
 aFISStat[03] =  "Bit  3 " + "Bater¡a BAJA "
 aFISStat[04] =  "Bit  4 " + "Comando NO Reconocido "
 aFISStat[05] =  "Bit  5 " + "Campo de Datos INVALIDO "
 aFISStat[06] =  "Bit  6 " + "Comando Inv lido para el Estado L¢gico del Equipo"
 aFISStat[07] =  "Bit  7 " + "Se va a producir el OVERFLOW en los Acumuladores del equipo"
 aFISStat[08] =  "Bit  8 " + "La memoria Fiscal esta LLENA "
 aFISStat[09] =  "Bit  9 " + "La memoria fiscal se esta por LLENAR"
 aFISStat[10] =  "Bit 10 " + "El Impresor tiene N£mero de Serie(Certificado)"
 aFISStat[11] =  "Bit 11 " + "El controlador Fiscal esta Fiscalizado"
 aFISStat[12] =  "Bit 12 " + "Se llego al M ximo de Items o se requiere un cierre del d¡a"
 aFISStat[13] =  "Bit 13 " + "Documento Fiscal Abierto"
 aFISStat[14] =  "Bit 14 " + "Documento Abierto "
 aFISStat[15] =  "Bit 15 " + "Factura abierta, Hoja Suelta"
 aFISStat[16] =  "Bit 16 " + "OR de bits 0-8 da 1 "


 FOR nI = 0 TO 15
    IF IF_ERROR1(nI)
      cMsg = cMsg + aPRNStat[nI + 1] + CHR(10)
    ENDIF
 NEXT

 IF LEN(cMsg) > 0
    MsgAlert( cMsg, "Impresora " + Titulo )
 ENDIF

 cMsg = ""

 FOR nI = 0 TO 15
    IF IF_ERROR2(nI)
      cMsg = cMsg + aFISStat[nI + 1] + CHR(10)
    ENDIF
 NEXT

 IF LEN(cMsg) > 0
    MsgAlert( cMsg, "Controlador Fiscal " + Titulo )
 ENDIF

RETURN

PROCEDURE CierreZ
LOCAL port, err, oDlg, mimpresion
DEFINE DIALOG oDlg FROM 2, 2 TO 12, 40
oDlg:lHelpIcon := .f.
@ 05, 05 SAY "I M P R I M I E N D O . . ."    OF oDlg PIXEL
@ 20, 05 BITMAP NAME "RENDI" OF oDlg NOBORDER SIZE 40,40 ADJUST PIXEL
ACTIVATE DIALOG oDlg CENTERED NOWAIT
MsgWait("Preparando para imprimir","Atencion",1)
port = IF_OPEN("COM1",9600 )
IF port < 0
   oDlg:End()
   MsgInfo( "Error en la apertura del puerto de comunicaciones")
   RETURN
ENDIF
err = IF_WRITE("@Sincro")
err = IF_WRITE("@DailyClose|Z")
err =  IF_CLOSE(port)
IF err <> 0
   oDlg:End()
   ReportarError()
ENDIF
oDlg:End()
RETURN

************************************************************
PROCEDURE CierreX
LOCAL port, err, oDlg, mimpresion
DEFINE DIALOG oDlg FROM 2, 2 TO 12, 40
oDlg:lHelpIcon := .f.
@ 05, 05 SAY "I M P R I M I E N D O . . ."    OF oDlg PIXEL
@ 20, 05 BITMAP NAME "RENDI" OF oDlg NOBORDER SIZE 40,40 ADJUST PIXEL
ACTIVATE DIALOG oDlg CENTERED NOWAIT
MsgWait("Preparando para imprimir","Atencion",1)
port = IF_OPEN("COM1",9600 )
IF port < 0
   oDlg:End()
   MsgInfo( "Error en la apertura del puerto de comunicaciones")
   RETURN
ENDIF
err = IF_WRITE("@DailyClose|X")
err =  IF_CLOSE(port)
IF err <> 0
   oDlg:End()
   ReportarError()
ENDIF
oDlg:End()
RETURN

*****************************************
** Grabar
FUNCTION FacturaFiscal(oQry,nCliente)
LOCAL port, cCondi, Err, nFactura := 0, oDlg, aCondi := {"I","N","A","E","C","M"}, mcuit, oQryCli,nTasa, cLetra
   oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = " + ClipValue2Sql(nCliente))
   cLetra := IF(oQryCli:coniva = 1 .or. oQryCli:coniva = 2,"A","B")
    // Validar que el DATOS CLIENTE
    IF oQryCli:coniva <> 5 .and. (EMPTY(oQryCli:cuit) .OR. oQryCli:cuit = "  -        - ")
       MsgStop("C.U.I.T. Invalido para tipo de condicion de I.V.A.","Error")
       RETURN 0
    ENDIF       
   cCondi := aCondi[IF(oQryCli:coniva<=0 .or. oQryCli:coniva>6,5,oQryCli:coniva)]
   mcuit := STRTRAN(oQryCli:cuit," ","0")
   mcuit := STRTRAN(mcuit,"-","")
   DEFINE DIALOG oDlg FROM 2, 2 TO 12, 40
   oDlg:lHelpIcon := .f.
   @ 05, 05 SAY "I M P R I M I E N D O . . ."    OF oDlg PIXEL
   @ 20, 05 BITMAP NAME "RENDI" OF oDlg NOBORDER SIZE 40,40 ADJUST PIXEL
   ACTIVATE DIALOG oDlg CENTERED NOWAIT
   MsgWait("Preparando para imprimir","Atencion",1)
   port = IF_OPEN("COM1",9600 )
   IF port < 0
      oDlg:End()
      MsgInfo( "Error en la apertura del puerto de comunicaciones")
      RETURN 0
   ENDIF
   Err = IF_WRITE("@Sincro")
   Err = IF_WRITE("@OpenDrawer")
   Err = IF_WRITE("@SetCustomerData|"+ALLTRIM(oQryCli:nombre)+"|"+;
                   mcuit+"|"+cCondi+"|C|"+ALLTRIM(oQryCli:direccion)+" "+ALLTRIM(oQryCli:localidad))
   IF err <> 0
      oDlg:End()
      ReportarError("Datos del cliente")
   ENDIF
   IF cCondi$"IN"
      Err := IF_WRITE("@OpenFiscalReceipt|A|T")
      ELSE
      Err := IF_WRITE("@OpenFiscalReceipt|B|T")
   ENDIF
   * item 1:  tasa 21%, imp. int 0% y precio total $1.5 (incluido impuestos)
   oQry:GOTOP()
   DO WHILE !oQry:EOF()
      nTasa := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " +ClipValue2Sql(oQry:codiva)):tasa
      Err := IF_WRITE("@PrintLineItem|"+;
                       LEFT(ALLTRIM(oQry:detart),20)+"|"+;
                       ALLTRIM(STR(oQry:cantidad,10,2))+"|"+;
                       ALLTRIM(STR(oQry:ptotal/oQry:cantidad   ,10,2))+"|"+;
                       ALLTRIM(STR(nTasa,5,2 ))+"|M|0.0|1|T")
      IF err <> 0
         oDlg:End()
         ReportarError()
         RETURN 0
      ENDIF
      oQry:SKIP(1)
   ENDDO
   *Err = IF_WRITE("@Subtotal|P|Subtotal|0|")
   * Err = IF_WRITE("@TotalTender|Su Pago|"+oGet[21]:cText+"|T|0")
   
   Err = IF_WRITE("@CloseFiscalReceipt")
   oDlg:End()
   IF err <> 0
      oDlg:End()
      ReportarError()
      RETURN 0
      ELSE
      nFactura = VAL( IF_READ(3))
   ENDIF
   err =  IF_CLOSE(port)
   IF err <> 0
      oDlg:End()
      ReportarError()
      RETURN 0
   ENDIF

RETURN nFactura
*/

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
      nCotiza := oApp:oServer:Query("SELECT dolar FROM ge_"+oApp:cId+"parametros"):dolar
DEFAULT lRemito:=.f. , lFacturaD := .f.     
nNro := 0      
&& Los nombres de los parametros de las funciones se obtienen descomprimiendo FEAFIP DOC
&& y luego abriendo el archivo index.html de la carpeta "Doc Interfaces".

&& la interfaz correspondiente a este ejemplo es Iwsfev1 para facturas A y B.

&& URLs de autenticacion y negocio. Cambiarlas por las de producción al implementarlas en el cliente(abajo)


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
ENDIF        

*Tipocomp := 011 &&Factura C( A:001 B:006 NDA: 002 NCA:003 NDB:007 NCB:008 NDC:012 NCC:013)
fechacmp := DTOS(oGet[01]:value)

IF !EMPTY(STRTRAN(oGet[12]:cText,"-",""))
   //CUIT
   nTipoDoc := 80
   nNroDoc  := VAL(STRTRAN(oGet[12]:cText,"-",""))
   ELSE
   //DNI
   nTipoDoc := 96
   nNroDoc  := oGet[22]:value
   IF nNroDoc = 0
      nTipoDoc := 99
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
   dFecDes := DTOS(dFecDes)
   dFecHas := DTOS(dFecHas)
   ELSE 
   dFecDes := ""
   dFecHas := ""
ENDIF   
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
TRY 
  wsfev1:URL  := URLWSW
  lRta := wsfev1:login("MiCertificado.crt", "MiClavePrivada", URLWSAA)
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN 0 
END TRY    
IF lRta 
   TRY
       If wsfev1:SFRecuperaLastCMP(nPuntoVta, Tipocomp) 
          nFacturaNro := wsfev1:SFLastCmp &&Devolucion el ultimo comprobante
          *oGet[06]:cText := nFacturaNro + 1
          lRta := .t.
          ELSE
          MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:ErrorDesc+chr(10);
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
   nFacturaNro := nFacturaNro + 1
   nPerce := ROUND(oGet[38]:value,2)
   IF lFacturaD
      nTotal := ROUND(nTotal / nCotiza,2)
      nNeto  := ROUND(nNeto / nCotiza,2) 
      nPerce := ROUND(nPerce / nCotiza,2) 
   ENDIF
   TRY
     wsfev1:Reset()  
     IF lFacturaD
        wsfev1:AgregaFactura(nTipoFac, nTipoDoc, nNroDoc, nFacturaNro, nFacturaNro, fechacmp,;
                          nTotal, nPerce, nNeto, 0, dFecDes, dFecHas, IF(nTipoFac>=2,fechacmp,""), "DOL", nCotiza) 
        ELSE  
        wsfev1:AgregaFactura(nTipoFac, nTipoDoc, nNroDoc, nFacturaNro, nFacturaNro, fechacmp,;
                          nTotal, nPerce, nNeto, 0, dFecDes, dFecHas, IF(nTipoFac>=2,fechacmp,""), "PES", 1)   
     ENDIF   
     IF nTip = 3 .or. nTip = 2
        wsfev1:AgregaCompAsoc(IF(cLetra = 'A',1,IF(cLetra = "B",6,IF(cLetra = "C",11,53))),nPuntoVta,nComprAsoc,wsfev1:CUIT,DTOS(dFecCompAsoc))
     ENDIF
   CATCH oError 
        MsgInfo( "Error en el Web Service de AFIP"+;
             chr(10)+oError:description;
             ,"Error al Agregar factura /Comp.Asociado " ) 
        RETURN 0 
   END TRY 
   // Agregar IVAS
   TRY 
     IF cLetra <> "C"
        FOR i := 1 TO LEN(aTablasIvas)
            IF lFacturaD
               wsfev1:AgregaIVA(aTablasIvas[i,1], ROUND(aTablasIvas[i,2]/nCotiza,2), ROUND(aTablasIvas[i,3]/nCotiza,2))
               ELSE
               wsfev1:AgregaIVA(aTablasIvas[i,1], ROUND(aTablasIvas[i,2],2), ROUND(aTablasIvas[i,3],2))
            ENDIF   
        NEXT i
     ENDIF
     IF nImpInt > 0
        IF lFacturaD
           nImpInt := ROUND(nImpInt / nCotiza,2) 
        ENDIF    
        wsfev1:AgregaTributo(4, 'Impuestos Internos', 0,0, nImpInt)      
     ENDIF
     If wsfev1:Autorizar(nPuntoVta, Tipocomp) 
        *Memoedit(wsfev1:XmlRequest)      
        If wsfev1:SFresultado(0)<>"A"              
           lFallo := .t.
           nNro := 0
        ENDIF 
        ELSE
        MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
                wsfev1:ErrorDesc+chr(10);
               +"FEAFIP AUTORIZAR","Error" ) 
        lFallo := .t.
        nNro := 0
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
   //MsgStop(wsfev1:ErrorDesc+" "+wsfev1:SFresultado(0), "FEAFIP RESULTADO")
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
   Procesando(.f.)
   xBrowse(aXml,wsfev1:ErrorDesc)
   RETURN nil
ENDIF
nNro := nFacturaNro
cCae := wsfev1:SFCAE(0)
dFecVto := sFecha(wsfev1:SFVencimiento(0))
nTipfor := TipoComp
RETURN nil

******************************************************************************************
** Factura electronica para tickets
FUNCTION FacturaElec1( nPuntoVta, nTipoDoc, cLetra, aTablasIvas, nNro, cCae, dFecVto, nTipfor,;
                     dFecComp,cCuit,nDni,nImpNeto,nImpIva,nImpTotal,nImpInt)
LOCAL urlwsaa, urlwsw, wsfev1, i, lFallo := .f., j, TipoComp, fechacmp, nFacturaNro, nNroDoc,;
      nTotal, nIva, nNeto, dFecDes, dFecHas, aXml, hFile, oXmlDoc, oXmlIter, oTagActual, oError, lRta
     
nNro := 0      
&& Los nombres de los parametros de las funciones se obtienen descomprimiendo FEAFIP DOC
&& y luego abriendo el archivo index.html de la carpeta "Doc Interfaces".

&& la interfaz correspondiente a este ejemplo es Iwsfev1 para facturas A y B.

&& URLs de autenticacion y negocio. Cambiarlas por las de producción al implementarlas en el cliente(abajo)


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

IF EMPTY(STRTRAN(cCuit,"-","")) .AND. cLetra = 'A'
   nNro := 0
   MsgStop("El cliente elegido es INSCRIPTO y no tiene CUIT"+CHR(10)+"Corrija","Error")
   RETURN nil
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
nNeto  := IF(nImpInt>0, nNeto - nImpInt, nNeto)
nTotal := ROUND(nImpTotal,2)
nIva   := IF(cLetra="C",0,ROUND(nImpIva,2))
IF nNeto + nIva + nImpInt > nTotal .and. nImpInt > 0
   nImpInt := nImpInt - (nTotal - nNeto - nIva - nImpInt)
ENDIF
dFecDes := ""
dFecHas := ""
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
lRta := .f.
TRY 
  wsfev1:URL  := URLWSW
  lRta := wsfev1:login("MiCertificado.crt", "MiClavePrivada", URLWSAA)
CATCH oError
  MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"CONECTANDO CON WEB SERVICE" ) 
  RETURN 0 
END TRY    
IF lRta 
   TRY 
       If wsfev1:SFRecuperaLastCMP(nPuntoVta, Tipocomp) 
          nFacturaNro := wsfev1:SFLastCmp &&Devolucion el ultimo comprobante
          *oGet[06]:cText := nFacturaNro + 1
          nFacturaNro := nFacturaNro + 1
          ELSE          
          MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:ErrorDesc+chr(10);
             +"FEAFIP RECUPERANDO ULTIMO COMPROBANTE","Error" ) 
          nFacturaNro := -1
       ENDIF
   CATCH oError 
    MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              oError:description+chr(10);
             ,"RECUPERANDO ULTIMO COMPROBANTE" ) 
    RETURN 0 
   END TRY
   IF nFacturaNro = -1
      RETURN 0
   ENDIF
   TRY 
     wsfev1:Reset()   
     wsfev1:AgregaFactura(1, nTipoDoc, nNroDoc, nFacturaNro, nFacturaNro, fechacmp,;
                          nTotal, 0, nNeto, 0, dFecDes, dFecHas, "", "PES", 1)   
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
        If wsfev1:SFresultado(0)<>"A"              
           lFallo := .t.
           nNro := 0
        ENDIF 
        ELSE
        MsgInfo( "Error en el Web Service de AFIP"+chr(10)+;
              wsfev1:ErrorDesc+chr(10);
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
              wsfev1:ErrorDesc+chr(10);
             +"FEAFIP CERTIFICADOS","Error" ) 
   lFallo := .t.
   nNro := 0
ENDIF
IF lFallo
   //MsgStop(wsfev1:ErrorDesc+" "+wsfev1:SFresultado(0), "FEAFIP RESULTADO")
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
   Procesando(.f.)
   xBrowse(aXml,wsfev1:ErrorDesc)
   RETURN nil
ENDIF
nNro := nFacturaNro
cCae := wsfev1:SFCAE(0)
dFecVto := sFecha(wsfev1:SFVencimiento(0))
nTipfor := TipoComp
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