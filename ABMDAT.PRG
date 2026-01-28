#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** Configuración
*************************************************
MEMVAR oApp
STATIC oFont
PROCEDURE DatEmp()
LOCAL hHand, oGet := ARRAY(55), oBot := ARRAY(3), oForm, lRta := .f., aCor, base, oError, oQry, lProx:= .f.,oDlg1,oFld,;
      oBrw, oQryP,;
      oCheck:= ARRAY(3),;
      aConIva := {;
"1 IVA Responsable Inscripto",;
"2 IVA Responsable no Inscripto",;
"3 IVA no Responsable",;
"4 IVA Sujeto Exento",;
"5 Consumidor Final",;
"6 Responsable Monotributo",;
"7 Sujeto no Categorizado",;
"8 Proveedor del Exterior",;
"9 Cliente del Exterior",;
"10  IVA Liberado – Ley Nº 19.640",;
"11  IVA Responsable Inscripto – Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social"},;
aFactura := {"1  Producto / Exportación definitiva de bienes",;
"2 Servicios",;
"3 Productos y Servicios",;
"4 Otro"}

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"parametros")
oQry:GoTop()
IF EMPTY(oQry:email)
   use bcn.dll alias "bcn" shared new
   oQry:email := bcn->mail
   close bcn 
ENDIF   
DO WHILE .T.
base := oQry:GetRowObj()

DEFINE DIALOG oDlg1 RESOURCE "PARAMETROS" OF oApp:oWnd 
oDlg1:lHelpIcon := .f.
REDEFINE FOLDEREX oFld ID 100 OF oDlg1 ;/*PAGES son dialogos de recurso*/
        ITEMS "Datos generales","Ventas","Pago a proveedores","Articulos";
        PAGES "PARDATOS","PARVENTA","PARPROV","PARART";
        OPTION 1 ;
        ROUND 3
     
//PESTAÑA 1 ---- DATOS GENERALES
     REDEFINE GET oGet[1] VAR base:nomb_emp     OF oFld:aDialogs[1] ID 101 PICTURE "@!"
     REDEFINE GET oGet[2] VAR base:cuit_emp     OF oFld:aDialogs[1] ID 102 PICTURE "99-99999999-9";
                  VALID(ValidaCuit(base:cuit_emp))
     REDEFINE GET oGet[3] VAR base:dire_emp     OF oFld:aDialogs[1] ID 103 
     REDEFINE GET oGet[4] VAR base:loca_emp     OF oFld:aDialogs[1] ID 104 
     REDEFINE COMBOBOX oGet[5] VAR base:coniva  OF oFld:aDialogs[1] ID 105 ITEMS aConIva 
     REDEFINE COMBOBOX oGet[6] VAR base:factura OF oFld:aDialogs[1] ID 106 ITEMS aFactura 
     REDEFINE GET oGet[44] VAR base:ingb_emp    OF oFld:aDialogs[1] ID 4004 PICTURE "@!"
     REDEFINE GET oGet[45] VAR base:inac_emp    OF oFld:aDialogs[1] ID 4005 PICTURE "@D"
     REDEFINE GET oGet[7] VAR base:claveadm     OF oFld:aDialogs[1] ID 107 PICTURE "@!" WHEN(base:usaclave) 
     REDEFINE CHECKBOX oGet[8] VAR base:usaclave OF oFld:aDialogs[1] ID 200 ON CHANGE oGet[7]:SetFocus()
     oGet[8]:cToolTip:= "Solicitara la clave de administrador en ciertos casos criticos"
     REDEFINE GET oGet[9] VAR base:dolar         OF oFld:aDialogs[1] ID 108 PICTURE "9999999.99"
     REDEFINE GET oGet[10] VAR base:prefijo      OF oFld:aDialogs[1] ID 4001 PICTURE "9999"
     REDEFINE CHECKBOX oCheck[1] VAR base:cierreturno OF oFld:aDialogs[1] ID 109 
     oCheck[1]:cToolTip:= "Se habilitara la funcion de cierre de caja por turno"
     REDEFINE CHECKBOX oCheck[2] VAR base:unificacaja OF oFld:aDialogs[1] ID 110
     REDEFINE BUTTON oBot[3] ID 301 OF oFld:aDialogs[1]  ACTION ConfiguFac()
     REDEFINE CHECKBOX oCheck[3] VAR base:enviamail OF oFld:aDialogs[1] ID 4002
     REDEFINE GET oGet[35] VAR base:email      OF oFld:aDialogs[1] ID 4003 PICTURE "@S20" WHEN(base:enviamail)

//PESTAÑA 2 ---- DATOS DE LA VENTA
     
     REDEFINE CHECKBOX oGet[11] VAR base:modifpre  OF oFld:aDialogs[2] ID 101 
     oGet[11]:cToolTip:= "En la ventana de ventas el usuario podra modificar los precios manualmente"
     REDEFINE CHECKBOX oGet[12] VAR base:usacuotas OF oFld:aDialogs[2] ID 102
     oGet[12]:cToolTip:= "Se activara la opcion de plan de pago en cuotas para la cuenta corriente"
     REDEFINE CHECKBOX oGet[13] VAR base:modifdesc OF oFld:aDialogs[2] ID 103
     oGet[13]:cToolTip:= "En la ventana de ventas el usuario podra aplicar un descuento manualmente"
     REDEFINE CHECKBOX oGet[14] VAR base:modifvend OF oFld:aDialogs[2] ID 104
     oGet[14]:cToolTip:= "En la ventana de ventas el usuario podra modificar el responsable de la venta"

     REDEFINE GET oGet[15] VAR base:diasv   OF oFld:aDialogs[2] ID 105 PICTURE "9999" WHEN(base:usadiasv)
     oGet[15]:cToolTip:= "Si los dias transcurridos desde la actualizacion del precio del articulo son mayores a este no se podra facturar"
     REDEFINE CHECKBOX oGet[23] VAR base:usadiasv  OF oFld:aDialogs[2] ID 4001 ON CHANGE oGet[15]:SetFocus()
     REDEFINE GET oGet[16] VAR base:diasdeu OF oFld:aDialogs[2] ID 106 PICTURE "9999" WHEN(base:usadiasdeu)
     oGet[16]:cToolTip:= "Si los dias de atraso de pago del cliente son mayores a este no se le podra seguir facturando"
     REDEFINE CHECKBOX oGet[24] VAR base:usadiasdeu OF oFld:aDialogs[2] ID 4002 ON CHANGE oGet[16]:SetFocus()

     REDEFINE CHECKBOX oGet[23] VAR base:usalimite  OF oFld:aDialogs[2] ID 113
     oGet[23]:cToolTip:= "Controla que el limite de credito cargado al cliente no sea excedido cuando se hace una venta a cuenta"
     REDEFINE CHECKBOX oGet[17] VAR base:usuavend   OF oFld:aDialogs[2] ID 107
     oGet[17]:cToolTip:= "Cada usuario sera dado de alta como vendedor y no se podran modificar los vendedores manualmente"
     REDEFINE CHECKBOX oGet[18] VAR base:percepiibb OF oFld:aDialogs[2] ID 108
     oGet[18]:cToolTip:= "Aplica percepciones en la cobranza"
     REDEFINE CHECKBOX oGet[19] VAR base:usapuntos  OF oFld:aDialogs[2] ID 109
     oGet[19]:cToolTip:= "Activa el sistema de canje de puntos que se encuentra en CLIENTES"
     REDEFINE GET      oGet[20] VAR base:pesoxpunto OF oFld:aDialogs[2] ID 110 PICTURE "99999999.99" WHEN(base:usapuntos)
     oGet[20]:cToolTip:= "Monto en pesos equivalente a cada punto ganado"
     REDEFINE CHECKBOX oGet[21] VAR base:usaremitos OF oFld:aDialogs[2] ID 111
     oGet[21]:cToolTip:= "Activa la emision de remitos y la posibilidad de facturarlos"
     REDEFINE CHECKBOX oGet[22] VAR base:usatactil  OF oFld:aDialogs[2] ID 112
     oGet[22]:cToolTip:= "Activa el punto de venta tactil"
     REDEFINE CHECKBOX oGet[23] VAR base:emite_pie   OF oFld:aDialogs[2] ID 4003
     oGet[23]:cToolTip:= "Imprime un pie en los tickets no fiscales"
     REDEFINE CHECKBOX oGet[29] VAR base:anticipoesvuelto   OF oFld:aDialogs[2] ID 4009
     oGet[29]:cToolTip:= "Si lo pagado es mayor a lo facturado lo considera vuelto"
     REDEFINE GET      oGet[24] VAR base:texto_pie   OF oFld:aDialogs[2] ID 4004 PICTURE "@!" WHEN(base:emite_pie)
     REDEFINE CHECKBOX oGet[25] VAR base:pregunta_ticket   OF oFld:aDialogs[2] ID 4005
     REDEFINE GET      oGet[26] VAR base:letranofiscal   OF oFld:aDialogs[2] ID 4007 PICTURE "@!" 
     REDEFINE GET      oGet[27] VAR base:textonofiscal   OF oFld:aDialogs[2] ID 4006 PICTURE "@!" 
     REDEFINE CHECKBOX oGet[28] VAR base:imprimevendedor   OF oFld:aDialogs[2] ID 4008
     REDEFINE CHECKBOX oGet[34] VAR base:presudiscriva     OF oFld:aDialogs[2] ID 4010
     REDEFINE CHECKBOX oGet[35] VAR base:artievenmasiva    OF oFld:aDialogs[2] ID 4011
     REDEFINE CHECKBOX oGet[36] VAR base:artievenendolar   OF oFld:aDialogs[2] ID 4012
     REDEFINE CHECKBOX oGet[47] VAR base:usabultosventa    OF oFld:aDialogs[2] ID 4014
     oGet[47]:cToolTip:= "Pedir para cargar bultos al momento de vender en facturacion NO POS"
     REDEFINE CHECKBOX oGet[48] VAR base:usareparto    OF oFld:aDialogs[2] ID 4015
     oGet[48]:cToolTip:= "Usar repartidores para asignar facturas a hoja de ruta"
     REDEFINE CHECKBOX oGet[50] VAR base:imprimedescuimp    OF oFld:aDialogs[2] ID 4016
     oGet[50]:cToolTip:= "Si no esta tildado, solo imprime el % de descuento, no el importe"
     REDEFINE CHECKBOX oGet[53] VAR base:pedidossinimporte    OF oFld:aDialogs[2] ID 4017
     oGet[53]:cToolTip:= "Si esta tildado, poner cartel para imprimir con o sin importe los pedidos"
     REDEFINE CHECKBOX oGet[54] VAR base:imprimetickecc    OF oFld:aDialogs[2] ID 4018
     oGet[54]:cToolTip:= "Si esta tildado, imprime una copia extra para firmar para tickets cuenta corriente"

//PESTAÑA 3 ---- DATOS DE PAGO A PROVEEDORES
     
     REDEFINE CHECKBOX oGet[31] VAR base:usaretgan  OF oFld:aDialogs[3] ID 101 
     oGet[31]:cToolTip:= "Aplica retenciones cuando se emite una orden de pago"
     REDEFINE CHECKBOX oGet[32] VAR base:usaretiibb OF oFld:aDialogs[3] ID 102
     oGet[32]:cToolTip:= "Aplica retenciones cuando se emite una orden de pago"
     REDEFINE CHECKBOX oGet[33] VAR base:usaretiva  OF oFld:aDialogs[3] ID 103
     oGet[33]:cToolTip:= "Aplica retenciones cuando se emite una orden de pago"

//PESTAÑA 4 ---- DATOS DE LA PLANILLA DE ARTICULOS
     
     REDEFINE CHECKBOX oGet[41] VAR base:usaproduccion OF oFld:aDialogs[4] ID 101 
     oGet[41]:cToolTip:= "Habilita la carga de recetas y la creacion de articulos que son de produccion propia en base a otros articulos de materia prima"
     REDEFINE CHECKBOX oGet[42] VAR base:usabultos     OF oFld:aDialogs[4] ID 102
     oGet[42]:cToolTip:= "Habilita el calculo del precio de costo del articulo a partir de las unidades y costo por bulto"
     REDEFINE CHECKBOX oGet[43] VAR base:usacodpro     OF oFld:aDialogs[4] ID 103
     oGet[43]:cToolTip:= "Habilita la carga del codigo del proveedor para cada articulo para agilizar la carga de boletas de compra"
     REDEFINE CHECKBOX oGet[46] VAR base:impcodpro     OF oFld:aDialogs[4] ID 4001 WHEN(base:usacodpro)
     oGet[46]:cToolTip:= "Si el producto tiene codigo de proveedor, este es el que sale en la factura" 
     REDEFINE CHECKBOX oGet[47] VAR base:utilfija     OF oFld:aDialogs[4] ID 4002 
     oGet[47]:cToolTip:= "No se calculara la utilidad cuando modifique manualmente el precio de venta" 
     REDEFINE CHECKBOX oGet[51] VAR base:lvtostock     OF oFld:aDialogs[4] ID 4003 
     oGet[51]:cToolTip:= "Permite que al cargar stock o compras, registre vencimientos del producto"
     REDEFINE CHECKBOX oGet[52] VAR base:tilda_computaiva     OF oFld:aDialogs[4] ID 4004 
     oGet[52]:cToolTip:= "Permite que al cargar compras en comprobantes no fiscales, se tilde automaticamente NO COMPUTAR IVA" 
     REDEFINE GET oGet[55] VAR base:diasalertastock     OF oFld:aDialogs[4] ID 4005 PICTURE "99"

REDEFINE BUTTON oBot[1] ID 201 OF oDlg1 ;
             ACTION ((lRta := .t.), oDlg1:End() ) 
REDEFINE BUTTON oBot[2] ID 202 OF oDlg1  CANCEL;
             ACTION ((lRta := .f.), oDlg1:End() ) 
  
ACTIVATE DIALOG oDlg1 CENTER 
IF !lRta
   oQry:End()
   RELEASE oQry
   RETURN 
ENDIF
oQry:oRow := base
TRY
   oQry:Save()
   //Verificar si tiene permisos para repartidores
   IF base:usareparto   
      IF oApp:oServer:Query("SELECT item FROM ge_"+oApp:cId+"menu_nuevo WHERE codigo = '0412'"):nRecCount = 0
         //No tiene permisos
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"menu_nuevo (codigo,usuario,modulo,etiqueta,detalle,recurso,padre,permisos,reporte) VALUES "+;
          "('0412','%%%%%%','ABMREPAR','Repartidores','A/B/M de repartidores','REPAR','0400','ABMRE','N'),"+;
          "('0412','MARKET','ABMREPAR','Repartidores','A/B/M de repartidores','REPAR','0400','ABMRE','N'),"+;
          "('0413','%%%%%%','ASIREPAR','Asignar','Asignar facturas de repartidores','MODI','0400','ABMRE','N'),"+;
          "('0413','MARKET','ASIREPAR','Asignar','Asignar facturas de repartidores','MODI','0400','ABMRE','N'),"+;
          "('0465','%%%%%%','LISASIREP','Asignacion','Reporte de Hojas de Ruta','REPORT','0450','ABMRE','N'),"+;
          "('0465','MARKET','LISASIREP','Asignacion','Reporte de Hojas de Ruta','MODI','0450','ABMRE','N')")
      ENDIF   
      IF oApp:oServer:TableExist("ma_menu_nuevo")
          IF oApp:oServer:Query("SELECT item FROM ma_menu_nuevo WHERE codigo = '0412'"):nRecCount = 0
             //No tiene permisos
             oApp:oServer:Execute("INSERT INTO ma_menu_nuevo (codigo,usuario,modulo,etiqueta,detalle,recurso,padre,permisos,reporte) VALUES "+;
              "('0412','%%%%%%','ABMREPAR','Repartidores','A/B/M de repartidores','REPAR','0400','ABMRE','N'),"+;
              "('0412','MARKET','ABMREPAR','Repartidores','A/B/M de repartidores','REPAR','0400','ABMRE','N'),"+;
              "('0413','%%%%%%','ASIREPAR','Asignar','Asignar facturas de repartidores','MODI','0400','ABMRE','N'),"+;
              "('0413','MARKET','ASIREPAR','Asignar','Asignar facturas de repartidores','MODI','0400','ABMRE','N'),"+;
              "('0465','%%%%%%','LISASIREP','Asignacion','Reporte de Hojas de Ruta','REPORT','0450','ABMRE','N'),"+;
              "('0465','MARKET','LISASIREP','Asignacion','Reporte de Hojas de Ruta','MODI','0450','ABMRE','N')")
          ENDIF 
      ENDIF
   ENDIF
   IF base:lvtostock
      IF !oApp:oServer:TableExist("ge_"+oApp:cId+"stocklotes")
          oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"stocklotes ( "+;  
                              "`id` INT(10) NOT NULL AUTO_INCREMENT, "+;  
                              "`codart` BIGINT(14),"+;  
                              "`cantidad` DECIMAL(12,3),"+;  
                              "`restan` DECIMAL(12,3),"+;  
                              "`fechavto` DATE,"+;  
                              "PRIMARY KEY (`id`)"+;                                
                            ")")
      ENDIF    
   ENDIF
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
END TRY
EXIT
ENDDO
CargarConfiguracion()
RETURN 
 
STATIC FUNCTION ConfiguFac()
LOCAL oDlg2, aCor,oQryConf,base,oError,;
      oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, ;
      oGeta, oGetb, oGetc,;
      oGey1, oGey2, oGey3, oGey4, oGey5, oGey6, oGey7, oGey8, oGey9, oGeya, ;
      oGeyb, oGeyc,  oGext, oGeyt, oGetd, oBot1, oBot2, mrta:=.f., oGetx, oGetx1, ;
      aImp  := {"Imprime solo datos empresa","Imprime solo logo","Imprime ambos"}

oQryConf:=oApp:oServer:Query("SELECT *  FROM ge_"+oApp:cId+"config")
base:= oQryConf:GetRowObj()

DO WHILE .T.
DEFINE DIALOG oDlg2 TITLE "Configurar factura" FROM 05,15 TO 17,63 FONT oFont
   acor := AcepCanc(oDlg2)
 /*  @ 07,05 SAY "Tipo de formulario:" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 22,05 SAY "Numero de factura :" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 37,05 SAY "Fecha factura:"      OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 52,05 SAY "Cliente:"            OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 67,05 SAY "Direccion + Localidad:"  OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 82,05 SAY "Respons. IVA:"       OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 97,05 SAY "C.U.I.T./D.N.I.:"    OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @112,05 SAY "Observaciones:"      OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @127,05 SAY "Total factura:"      OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @142,05 SAY "Neto sin IVA:"       OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @157,05 SAY "Importe IVA:"        OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @172,05 SAY "Importe descuento:"  OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @187,05 SAY "Comienzo articulos:" OF  oDlg2 PIXEL SIZE 70,12 RIGHT */
   @ 07,05 SAY "Tamaño Letra      :" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 22,05 SAY "Logo en facturas  :" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 37,05 SAY "El logotipo debe guardarse en el archivo LOGO.JPG y debe tener 8 cm "+;
    " de ancho y 3 de alto (o ser proporcional a esos valores). El fondo de la factura "+;
    " (si Ud. desea poner una marca de agua), debe ser guardado en el archivo FONDOFAC.JPG.";
     OF  oDlg2 PIXEL SIZE 170,36 
  /* @ 05,080 GET oGet1 VAR base:x1     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 05,110 GET oGey1 VAR base:y1     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 20,080 GET oGet2 VAR base:x2     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 20,110 GET oGey2 VAR base:y2     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 35,080 GET oGet3 VAR base:x3     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 35,110 GET oGey3 VAR base:y3     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 50,080 GET oGet4 VAR base:x4     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 50,110 GET oGey4 VAR base:y4     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 65,080 GET oGet5 VAR base:x5     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 65,110 GET oGey5 VAR base:y5     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 80,080 GET oGet6 VAR base:x6     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 80,110 GET oGey6 VAR base:y6     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 95,080 GET oGet7 VAR base:x7     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 95,110 GET oGey7 VAR base:y7     PICTURE "9999" OF oDlg2 PIXEL RIGHT
  * @110,080 GET oGet8 VAR base:x8     PICTURE "9999" OF oDlg2 PIXEL RIGHT
  * @110,110 GET oGey8 VAR base:y8     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @125,080 GET oGet9 VAR base:x9     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @125,110 GET oGey9 VAR base:y9     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @140,080 GET oGeta VAR base:xa     PICTURE "9999" OF oDlg2 PIXEL RIGHT   
   @140,110 GET oGeya VAR base:ya     PICTURE "9999" OF oDlg2 PIXEL RIGHT
 *  @140,140 GET oGetx VAR base:xneto2 PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @155,080 GET oGetb VAR base:xb     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @155,110 GET oGeyb VAR base:yb     PICTURE "9999" OF oDlg2 PIXEL RIGHT
 *  @155,140 GET oGetx1 VAR base:xiva2 PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @170,080 GET oGetc VAR base:xc     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @170,110 GET oGeyc VAR base:yc     PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @185,080 GET oGetd VAR base:desdey PICTURE "9999" OF oDlg2 PIXEL RIGHT */
   @ 05,080 GET oGext VAR base:fon    PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ 20,080 COMBOBOX oGetc VAR base:x1 ITEMS aImp OF oDlg2 PIXEL SIZE 80,10
*  @200,120 GET oGeyt VAR myt PICTURE "9999" OF oDlg2 PIXEL RIGHT
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg2 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg2:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg2 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg2:End() ) PIXEL
ACTIVATE DIALOG oDlg2 CENTER 
IF !mRta
   RETURN nil
ENDIF

oQryConf:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryConf:Save()
  oQryConf:Refresh(.t.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil