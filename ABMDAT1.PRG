#include "Fivewin.ch"
#include "Tdolphin.ch"
*************************************************
** DATOS DEL PUNTO DE VENTA
*************************************************
MEMVAR oApp
STATIC oDlg1
FUNCTION Punto()
LOCAL oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet10,;
      oGet11, oGet12, oGet13, oGet14, oGet15, oGet16, oGet17, oGet18, oGet19, oGet20, ;
      oGet21, oGet22, oGet23, oGet24, oGet25, oGet26, oGet27, oGet28, oGet29, oGet30, oGet31, oGet32, oGet33,;
      oGet34, oGet35, oGet36, oGet37,;
      oBot1, oBot2, oBot3, oDlg1, base, hHand, oQry, oError, aCor, mrta := .f.,;
      aCobrar := {"Cobro Salon","Cobro distribucion","Cobro ambos"}, oFont,;
      aTipos :={"Facturacion electronica","Facturacion con control. fiscal"}, aTipoC:={"Codigo interno","Codigo de barras"},;
      aStock :={"Avisar falta de stock","Prohibir falta de stock","No controlar stock"},;
      aCosto :={"No controlar costo","Avisar venta debajo de costo","Prohibir venta debajo de costo"},;
      aMayo  :={"Mayorista","Minorista"},;
      aListaPos := {"Elije Libre","Asigna Lista 1","Asigna Lista 2"},;
      oGru, oGetC, oGetT, aImp := aGetPrinters(), nImp, nCosto,;
      oQryPun := oApp:oServer:Query( "SELECT caja as codigo, nombre FROM ge_"+oApp:cId+"punto WHERE caja <> "+str(oApp:prefijo)) 

oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2Sql(oApp:cIp))
base:=oQry:GetRowObj() 
nCosto := base:validacosto + 1  
base:lispreclientepos := base:lispreclientepos + 1   
IF oQry:nRecCount = 0
   MsgStop("Esta terminal no es un punto de venta habilitado!!")
   oQry:End()
   RETURN nil
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Datos del punto de venta" FROM 05,15 TO 40,75 OF oApp:oWnd ICON oApp:oIco FONT oFont
   acor := AcepCanc(oDlg1)   
   
   @ 07, 05 SAY "Ultima Fact. A:"      OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 07, 90 SAY "Ultima Fact. B:"      OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 22, 90 SAY "Ultimo Remito:"       OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 22, 05 SAY "Ultimo Presupuesto:"  OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 37, 90 SAY "N° Caja:"      OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 95, 05 SAY "Copias de impresion:" OF oDlg1 PIXEL SIZE 80,11 
   @ 94,05 GROUP oGru TO 170,270  OF oDlg1 PIXEL
   
   @112, 10 SAY "Facturas:"     OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @112, 65 SAY "Presupuesto:"    OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @112,105 SAY "Remitos:"      OF oDlg1 PIXEL SIZE 35,12 RIGHT 
   //@127, 10 SAY "Presupuesto:"  OF oDlg1 PIXEL SIZE 35,12 RIGHT
   //@127, 65 SAY "Nota credito:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   
 
   
   @ 77, 10 SAY "Nombre Equipo: " + oApp:cNombreEquipo OF oDlg1 PIXEL SIZE 80,12 
   @ 65, 10 SAY "ID Equipo: "     + oApp:cIp           OF oDlg1 PIXEL SIZE 200,12 
   @ 77,105 SAY "(Usar este pto. de venta electronica):" OF oDlg1 PIXEL SIZE 80,12
   @ 92,105 SAY "Domicilio PV:" OF oDlg1 PIXEL SIZE 40,12 

   @172, 10 SAY "Limite Efectivo en caja:" OF oDlg1 PIXEL SIZE 55,20 RIGHT
   
   @172,170 SAY "Clave:" OF oDlg1 PIXEL SIZE 20,12 RIGHT

   @187, 60 SAY "Desde:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @187,160 SAY "Hasta:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @202, 60 SAY "Desde:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @202,160 SAY "Hasta:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   @217, 05 SAY "Limite Facturacion:" OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @232,120 SAY "A caja:" OF oDlg1 PIXEL SIZE 35,12 RIGHT
   
   @ 05, 65 GET oGet1 VAR base:facturaa PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(.F.)
   @ 05,150 GET oGet2 VAR base:facturab PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(.F.)
   @ 20,150 GET oGet3 VAR base:remito   PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(.F.)
   @ 20, 65 GET oGet4 VAR base:presupu  PICTURE "99999999" OF oDlg1 PIXEL RIGHT WHEN(.F.)
   
   @ 35, 10 COMBOBOX oGet8 VAR base:tipofac ITEMS aTipos OF oDlg1 PIXEL SIZE 85,12
   @ 52,100 BUTTON oBot3 PROMPT "Conf.Fiscal" OF oDlg1 SIZE 45,10 ;
     ACTION ConfiguFis(@base:imprfiscal) PIXEL WHEN(base:tipofac = 2)
   @ 35,150 GET oGet5 VAR base:caja     PICTURE "9999"     OF oDlg1 PIXEL RIGHT
   

   @ 50, 10 COMBOBOX oGet9 VAR base:pidestock ITEMS aStock OF oDlg1 PIXEL SIZE 85,12
   @ 50,150 COMBOBOX oGet14 VAR nCosto ITEMS aCosto OF oDlg1 PIXEL SIZE 85,12
   @ 75,190 GET oGet21 VAR base:punto  PICTURE "9999" OF oDlg1 PIXEL RIGHT WHEN(base:tipofac = 1)
   @ 90,150 GET oGet22 VAR base:direccionf  PICTURE "@S20" OF oDlg1 PIXEL WHEN(base:tipofac = 1 .and. base:punto > 0)
            
   @110, 50 GET oGet10 VAR base:copiafa  PICTURE "99" OF oDlg1 PIXEL RIGHT
   @110,105 GET oGet11 VAR base:copiafb  PICTURE "99" OF oDlg1 PIXEL RIGHT
   @110,145 GET oGet12 VAR base:copiare  PICTURE "99" OF oDlg1 PIXEL RIGHT
   /*@125, 50 GET oGet13 VAR base:copiapr  PICTURE "99" OF oDlg1 PIXEL RIGHT
   @125,105 GET oGet16 VAR base:copianc  PICTURE "99" OF oDlg1 PIXEL RIGHT*/
   @125,145 CHECKBOX oGet25 VAR base:sonarpedidos PROMPT "Alerta Pedidos nuevos" OF oDlg1 PIXEL SIZE 90,12
   oGet25:cToolTip:= "Emitir una alerta sonora cuando haya un pedido nuevo"

   //Impresora de ticket para el punto de venta
   nImp := IF(EMPTY(base:impresorat),1,ASCAN(aImp,ALLTRIM(base:impresorat)))
   @140, 10 CHECKBOX oGet17 VAR base:imprimeTic  PROMPT "Usa impresora Ticket" OF oDlg1 PIXEL SIZE 65,12   
   @140, 85 CHECKBOX oGet18 VAR base:imprimeDat  PROMPT "Imprime encabezado"   OF oDlg1 PIXEL SIZE 65,12
   @140,155 COMBOBOX oGet19 VAR nImp ITEMS aImp  SIZE 65,12 OF oDlg1 PIXEL
   @155, 10 CHECKBOX oGet17 VAR base:tick80  PROMPT "De 80mm" OF oDlg1 PIXEL SIZE 65,12 WHEN(base:imprimeTic)  
   @155, 85 CHECKBOX oGet24 VAR base:preguntaimpr  PROMPT "Impresión Selecciona"   OF oDlg1 PIXEL SIZE 65,12;
            WHEN(base:imprimeTic)
   oGet24:cToolTip := "Esto permite que al momento de imprimir, pueda elegir entre impresion de ticket o formulario A4"
   @155,155 CHECKBOX oGet20 VAR base:usavales  PROMPT "Usa Vales de clientes" OF oDlg1 PIXEL SIZE 95,12 
   @170, 70 GET oGet23 VAR base:limitepesos PICTURE "99999999.99" OF oDlg1 PIXEL RIGHT
   @170,120 CHECKBOX oGet26 VAR base:retiroconclave PROMPT "Retiros con clave" OF oDlg1 PIXEL SIZE 50,12
   @170,195 GET oGet27 VAR base:retiroclave OF oDlg1 PIXEL PICTURE "@S7" PASSWORD  WHEN(base:retiroconclave)  
   @185, 05 CHECKBOX oGet28 VAR base:cierrexhora PROMPT "Cierro con horario" OF oDlg1 PIXEL SIZE 54,12
   @185, 95 GET oGet29 VAR base:desdehora1 OF oDlg1 PIXEL PICTURE "99:99:99" WHEN(base:cierrexhora)
   @185,195 GET oGet30 VAR base:hastahora1 OF oDlg1 PIXEL PICTURE "99:99:99" WHEN(base:cierrexhora)  
   @200, 95 GET oGet31 VAR base:desdehora2 OF oDlg1 PIXEL PICTURE "99:99:99" WHEN(base:cierrexhora)
   @200,195 GET oGet32 VAR base:hastahora2 OF oDlg1 PIXEL PICTURE "99:99:99" WHEN(base:cierrexhora) 
   @215, 65 GET oGet33 VAR base:limitefacturacion OF oDlg1 PIXEL PICTURE "999999999.99" RIGHT
   oGet33:cToolTip := "Este limite impide que facture por encima de ese importe, dejar en 0 para omitir"
   @215,150 COMBOBOX oGet34 VAR base:lispreclientepos ITEMS aListaPos OF oDlg1 PIXEL SIZE 85,12
   oGet34:cToolTip := "Para alta de clientes en POS que lista de precios permite asignar?"
   @230, 05 CHECKBOX oGet35 VAR base:transfiereefec PROMPT "Transfiere efectivo al cierre" OF oDlg1 PIXEL SIZE 95,12
   oGet35:cToolTip := "Transferir el importe resultante de efectivo a la caja indicada al cierre del turno"
   @230, 105 GET oGet36 VAR base:transfierecaja OF oDlg1 PICTURE "9999" WHEN(base:transfiereefec) RIGHT PIXEL SIZE 30,12;
            VALID(Buscar(oQryPun,oDlg1,oGet36,,,,,, 'caja'));
            ACTION ((oGet36:cText := 0,Buscar(oQryPun,oDlg1,oGet36,,,,,, 'caja'))) BITMAP "BUSC1" 
   @230,175 CHECKBOX oGet37 VAR base:agrupaimpresion PROMPT "Agrupa impresión" OF oDlg1 PIXEL SIZE 95,12
   oGet37:cToolTip := "Agrupa la impresion de items iguales en las facturas de venta"
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mrta
   oQry:End()
   RETURN nil
ENDIF
base:impresorat := IF(nImp=0," ",aImp[nImp])
base:tick80 := IF(base:imprimeTic,base:tick80,.f.)
base:preguntaimpr := IF(base:imprimeTic,base:preguntaimpr,.f.)
oApp:usavales := base:usavales
oApp:sonarpedidos := base:sonarpedidos
base:validacosto := nCosto - 1
base:lispreclientepos := base:lispreclientepos - 1

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh(.t.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
oQry:End()
RETURN nil

STATIC FUNCTION ConfiguFis(cFiscal)
LOCAL oDlg2, aCor, oGet := ARRAY(2), oBot1, oBot2,;      
      aImp  := {"Controlador Fiscal Epson","Controlador Fiscal Hasar","Impresora Fiscal Hasar",;
                "Controlador Fiscal Hasar 2da Generacion"}, nCom, nOpc,;
      aOpc  := {"TICKETE","TICKETH","TICKET3","TICKET2"}, mRta := .f.
IF !FILE("config.DBF")
   MsgStop("Falta archivo de configuracion","Error")
   RETURN nil 
   ELSE                
   USE config ALIAS "conf" SHARED NEW
   nCom := conf->com
ENDIF
nOpc := ASCAN(aOpc,ALLTRIM(cFiscal))

DEFINE DIALOG oDlg2 TITLE "Configurar Fiscal" FROM 05,15 TO 17,63 
   acor := AcepCanc(oDlg2) 
   @ 07,05 SAY "Puerto COM        :" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 22,05 SAY "Controlador Fiscal:" OF  oDlg2 PIXEL SIZE 70,12 RIGHT
   @ 37,05 SAY "Elija el controlador fiscal que tenga conectado a su PC. Tenga en "+;
    " cuenta que si es un controlador compatible, debe elegir el que emula."+;
    " (si Ud. posee una impresora que no esta por favor comuniquese con nosotros)";
     OF  oDlg2 PIXEL SIZE 170,36   
   @ 05,080 GET oGet[1] VAR nCom    PICTURE "99" OF oDlg2 PIXEL RIGHT SIZE 20,10
   @ 20,080 COMBOBOX oGet[2] VAR nOpc ITEMS aImp OF oDlg2 PIXEL SIZE 110,10
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg2 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg2:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg2 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg2:End() ) PIXEL
ACTIVATE DIALOG oDlg2 CENTER 
IF !mRta
   CLOSE conf
   RETURN nil
ENDIF
cFiscal := aOpc [nOpc]
IF conf->(rlock())
   REPLACE conf->com WITH nCom 
ENDIF
CLOSE conf
RETURN nil