#include "Fivewin.ch"
#include "XBROWSE.ch"
#include "Report.ch"
#include "Tdolphin.ch"

*************************************************
** Pagos a empleados 
*************************************************
MEMVAR oApp
STATIC oGet, oDlg, oBot, mfecha, mdesde, mhasta, mhabitual, mefectivo, mcodpro, mvalorhora, mmesp, manop,;
       oBrw, oQry, oQryDet, mtotal, lEdita, oQryBan, oQryCue, oQryPro, oQryChe, nTipo,lSalir:=.f., lMuestra
PROCEDURE pagemp(cPermisos)
LOCAL oFont, oFo1,  oSay1, mnompro, mrta := .f., aFormas := {"Liquidacion","Efectivo","Transferencia","C.Interno"},oDlg1,oFont1,oBot1:=ARRAY(3),;
       aMeses:={"Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto",;
               "Septiembre","Octubre","Noviembre","Diciembre"}
IF !"B"$cPermisos
   PagoAdelantoSimpre()
   RETURN  
ENDIF   
lMuestra := "B"$cPermisos 
oGet := ARRAY(14)
oBot := ARRAY(04)
mhabitual := 0
mtotal  := 0
mcodpro := 0
mvalorhora := 0
lEdita := .t.
mfecha  := DATE()
mdesde  := DATE()-30
mhasta  := DATE()
mmesp   := 0
manop   := YEAR(DATE())
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_pagemp` ("+;
                           "`numero` int(10) DEFAULT 0 NOT NULL,"+;
                           "`ano` int(4) NOT NULL,"+;
                           "`mes` int(2) NOT NULL DEFAULT 0 ,"+;                           
                           "`importe` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;                           
                           "`observa` VARCHAR(20) , "+;
                           "`usuario` VARCHAR(10) , "+;
                           "`tipo` INT(2) DEFAULT 0 NOT NULL , "+;
                           "`fecha` DATE  "+;
                           " ) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_pagemp")
oApp:oServer:NextResult()
oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,sueldo,valorhora FROM ge_"+oApp:cId+"emp_empleado")

DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.
   oQry:= oApp:oServer:Query("SELECT * FROM transi_pagemp")
   DEFINE FONT oFont NAME "ARIAL" SIZE 12,-16 BOLD
   DEFINE FONT oFo1  NAME "COURIER NEW" SIZE 08,-10
   DEFINE DIALOG oDlg RESOURCE "PAGEMP" OF oApp:oWnd TITLE "Pagos a empleados"
    oDlg:lHelpIcon := .f.
    REDEFINE GET oGet[1] VAR mcodpro  ID 112 OF oDlg PICTURE "99999";
             VALID(Buscar(oQryPro,oDlg,oGet[01],oGet[02]));
             ACTION (oGet[01]:cText:= 0, Buscar(oQryPro,oDlg,oGet[01],oGet[02])) BITMAP "BUSC1" WHEN(lEdita)
    REDEFINE GET oGet[2] VAR mnompro   ID 113 OF oDlg PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[3] VAR mhabitual ID 114 OF oDlg PICTURE "99999999.99" WHEN((oGet[3]:cText := oQryPro:sueldo) = 'XXX' )
    REDEFINE GET oGet[14] VAR mvalorhora ID 4001 OF oDlg PICTURE "999999.99" WHEN((oGet[14]:cText := oQryPro:valorhora) = 'XXX' )
    REDEFINE GET oGet[4] VAR mdesde ID 115 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[5] VAR mhasta ID 116 OF oDlg PICTURE "@D" 
    REDEFINE GET oGet[6] VAR mfecha ID 117 OF oDlg PICTURE "@D" WHEN(.F.)
    REDEFINE GET oGet[7] VAR mmesp ID 4002 OF oDlg PICTURE "99"
    REDEFINE GET oGet[8] VAR manop ID 4003 OF oDlg PICTURE "9999"
    REDEFINE BUTTON oBot[1] ID 118 OF oDlg ACTION Mostrar() WHEN(lEdita)
    REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "ano","mes","numero","fecha","observa","importe","usuario","tipo";
              HEADERS "Año","Mes","Recibo","Fecha","Concepto","Pago","Usuario","F.Pago" FOOTERS;
              SIZES 40,70,90,80,160,90,80,80 ID 120 OF oDlg       
    oBrw:aCols[6]:nFooterType := AGGR_SUM
    oBrw:aCols[2]:bStrData := {|| IF(oQry:mes=0,"",aMeses[oQry:mes])}
    oBrw:aCols[8]:bStrData := {|| aFormas[oQry:tipo+1]}
    PintaBrw(oBrw,0)                   
    REDEFINE GET oGet[10] VAR mtotal  ID 121 OF oDlg COLOR CLR_RED , CLR_YELLOW FONT oFont PICTURE "99999999.99" WHEN(.F.)
    REDEFINE BUTTON oBot[2] ID 102 OF oDlg ACTION graba(oDlg) WHEN(!lEdita) PROMPT "Pagar"
    REDEFINE BUTTON oBot[3] ID 103 OF oDlg ACTION Cancela()
    REDEFINE BUTTON oBot[4] ID 104 OF oDlg ACTION (oDlg:End(),mrta:=.f.) CANCEL
   ACTIVATE DIALOG oDlg CENTER ON INIT IF(!lMuestra,(oGet[3]:Hide(),oGet[14]:Hide()),nil)
   IF !mrta
      EXIT
   ENDIF
ENDDO
Cerrar(oGet[1],oDlg)
oQryPro:End()
oFont:End()
oFo1:End()
RETURN

*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaSaldo(n)
LOCAL base := oQry:GetRowObj()
base:pagado := n 
base:saldonue := ABS(oQry:saldo-n) * IF(base:saldo<0,-1,1)
oQry:oRow := base
oQry:Save()
oQry:Refresh()
RETURN nil




*****************************************
** Controla saldo
STATIC FUNCTION ControlSaldo(n,n1)
LOCAL lRet
IF n1 < 0
   IF ABS(n) <= ABS(n1) .and. n <= 0
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
   ELSE
   IF n <= n1
      lRet := .t.
      ELSE
      lRet := .f.
   ENDIF
ENDIF
IF !lRet
   MsgStop("No puede abonar mas de lo adeudado","Error")
ENDIF
RETURN lRet         


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (oGet,oWnd)
LOCAL j, i, aNueva := {}
oGet:SetFocus()
oWnd:Refresh()
oQry:End()
RETURN .t.

*****************************************
** Grabar
STATIC FUNCTION Graba(oWnd1)
LOCAL oGet := ARRAY(12), oBot := ARRAY(2), oForm, lRta := .f., aCor, oError, oQryCue, mresto1, mresto2 := 0, oQr,;
      mresto := -oBrw:aCols[6]:nTotal, mpago :=  - oBrw:aCols[6]:nTotal, mcuenta := 0, mcuennom := SPACE(30), mobserva := SPACE(30),;
      mmes := MONTH(DATE()), mano := YEAR(DATE()), nForma := 1, aFormas := {"Efectivo","Transferencia Bancaria"}, nId
mresto1 := mpago
mpago := IF(mpago<0,0,mpago)
oQr := oApp:oServer:Query("SELECT SUM(total) as total FROM ge_"+oApp:cId+"emp_liqsueldo "+;
                     "WHERE codemp = " + ClipValue2Sql(mcodpro) + " AND " +;
                     " fecha between "+ClipValue2Sql(mdesde)+" AND  "+ClipValue2Sql(mhasta)+" ")

oQryCue:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cuentas")
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Registro de pago a Empleado" FROM 05,15 TO 25,70 OF oWnd1
   
   @ 07, 05 SAY "Empleado:"              OF oForm PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Liquidado Período:"     OF oForm PIXEL SIZE 50,20 RIGHT
   @ 37, 05 SAY "Pagos del período:"     OF oForm PIXEL SIZE 50,20 RIGHT
   @ 37,110 SAY "Resto:"                 OF oForm PIXEL SIZE 50,20 RIGHT
   @ 52, 05 SAY "SU PAGO:"               OF oForm PIXEL SIZE 50,20 RIGHT
   @ 52,110 SAY "Nuevo Saldo:"           OF oForm PIXEL SIZE 50,20 RIGHT
   @ 67, 05 SAY "Período al que aplica:" OF oForm PIXEL SIZE 50,20 RIGHT
   @ 82, 05 SAY "Forma de Pago:"         OF oForm PIXEL SIZE 50,20 RIGHT
   @ 97, 05 SAY "Cuenta Bancaria:"       OF oForm PIXEL SIZE 50,20 RIGHT   
   @112, 05 SAY "Observaciones:"         OF oForm PIXEL SIZE 50,20 RIGHT   
  
   @ 05, 65 GET oGet[1] VAR oQryPro:nombre              OF oForm PIXEL WHEN(.F.)
   @ 20, 65 GET oGet[2] VAR oQr:total       PICTURE "999999999.99"    OF oForm PIXEL WHEN(.F.) RIGHT
   @ 35, 65 GET oGet[3] VAR mresto          PICTURE "999999999.99"    OF oForm PIXEL WHEN(.F.) RIGHT
   @ 35,165 GET oGet[11] VAR mresto1        PICTURE "999999999.99"    OF oForm PIXEL WHEN(.F.) RIGHT
   @ 50, 65 GET oGet[4] VAR mpago           PICTURE "999999999.99"    OF oForm PIXEL RIGHT
   @ 50,165 GET oGet[12] VAR mresto2        PICTURE "999999999.99"    OF oForm PIXEL ;
     WHEN((oGet[12]:cText := mresto1-mpago)="-919191") RIGHT UPDATE
   @ 65, 65 GET oGet[5] VAR mmes            PICTURE "99"              OF oForm PIXEL RIGHT VALID(mmes>0 .and. mmes<13)
   @ 65, 90 GET oGet[6] VAR mano            PICTURE "9999"            OF oForm PIXEL RIGHT VALID(mano>=YEAR(DATE()))
   @ 80, 65 COMBOBOX oGet[7] VAR nForma ITEMS aFormas  OF oForm PIXEL SIZE 100,12 ON CHANGE (oGet[8]:Refresh(), oGet[4]:SetFocus(),oGet[7]:SetFocus())
   @ 95, 65 GET oGet[8] VAR mcuenta         PICTURE "9999"            OF oForm PIXEL RIGHT SIZE 30,12;
      WHEN(oGet[7]:nAt==2);
      VALID(buscar(oQryCue, oForm,  oGet[8], oGet[9])) ;
      ACTION (oGet[8]:cText := 0,buscar(oQryCue, oForm, oGet[8], oGet[9])) BITMAP "BUSC1" 
   @ 95, 95 GET oGet[9] VAR mcuennom    OF oForm PIXEL WHEN(.F.)
   @110, 65 GET oGet[10] VAR mobserva   OF oForm PIXEL 
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL WHEN(mpago>0)
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
mresto2 := ROUND(mresto2,2)

IF mresto2 < 0.00
   lRta := MsgNoYes("Seguro de pagar mas de lo adeudado??","ATENCION!")
   IF !lRta 
      RETURN nil 
   ENDIF
ENDIF   
TRY
  oApp:oServer:BeginTransaction()  
  IF nForma = 2
     mobserva := ALLTRIM(mobserva)+" ("+ALLTRIM(mcuennom)+")"
  ENDIF   
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_pagsueldo (mes,ano,importe , fecha, observa, tipo, codemp, usuario  ) VALUES ("+;
                       ClipValue2Sql(mmes)+","+ClipValue2Sql(mano)+","+ClipValue2Sql(mpago)+",CURDATE(),"+;
                       ClipValue2Sql(mobserva)+","+ClipValue2Sql(nForma)+","+ClipValue2Sql(oQryPro:codigo)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
  nId := oApp:oServer:LastInsertID()
  IF nForma = 1
     mobserva := ALLTRIM(mobserva)+" (P.Sueldo: "+ALLTRIM(oQryPro:nombre)+")"
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (importe,fecha, observa, tipo, checkeado, caja, usuario  ) "+;
                          " VALUES ("+;
                       ClipValue2Sql(mpago)+",CURDATE(),"+ClipValue2Sql(mobserva)+",'R',false,"+ClipValue2Sql(oApp:prefijo)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
     ELSE
     mobserva := ALLTRIM(mobserva)+" (P.Sueldo: "+ALLTRIM(oQryPro:nombre)+")"
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito (importe,fecemi,fecacr,codtip,tipo, detalle, banco, usuario) "+;
                          " VALUES ("+;
                       ClipValue2Sql(mpago)+",CURDATE(),CURDATE(),1,'R',"+ClipValue2Sql(mobserva)+","+ClipValue2Sql(mcuenta)+","+;
                       ClipValue2Sql(oApp:usuario)+")")

  ENDIF 
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
ReciPago(nId)
Cancela()
RETURN nil

*****************************************
** Cancelar
STATIC FUNCTION Cancela()
oQry:Zap()
oBrw:Refresh()
lEdita := .t.
oGet[1]:SetFocus()
RETURN nil

*****************************************
** Cargar deuda
STATIC FUNCTION Mostrar()
LOCAL mentre := 0 , lRta := .f., oError, nNro
oQry:Zap()
oApp:oServer:Execute("INSERT INTO transi_pagemp (mes,ano,importe,fecha,observa,numero,tipo,usuario) "+;
                     "SELECT res.* FROM ("+;
                     "SELECT mes,ano,-total , fecha, observa,sub, 0, usuario "+;
                     "FROM ge_"+oApp:cId+"emp_liqsueldo "+;
                     "WHERE codemp = " + ClipValue2Sql(mcodpro) + " AND " +;
                     if(mmesp = 0,;
                     " fecha between "+ClipValue2Sql(mdesde)+" AND  "+ClipValue2Sql(mhasta),;
                     " mes = " + ClipValue2Sql(mmesp) + " AND ano = "+ClipValue2Sql(manop));
                     +" "+;
                     "UNION "+; 
                     "SELECT mes,ano,importe , fecha, observa,numero, tipo, usuario "+;
                     "FROM ge_"+oApp:cId+"emp_pagsueldo "+;
                     "WHERE codemp = " + ClipValue2Sql(mcodpro) + " AND " +;
                     if(mmesp = 0,;
                     " fecha between "+ClipValue2Sql(mdesde)+" AND  "+ClipValue2Sql(mhasta),;
                     " mes = " + ClipValue2Sql(mmesp) + " AND ano = "+ClipValue2Sql(manop));
                     +") res ")
oApp:oServer:NextResult()
oQry:Refresh()
oQry:GoTop()
oBrw:Refresh()
oBrw:MakeTotals()
mtotal := -ROUND(oBrw:aCols[6]:nTotal,2)
oGet[10]:Refresh()   
oBrw:SetFocus()
lEdita := .f.
RETURN nil 


****************************************
** Recibo de Pagos
FUNCTION ReciPago(n)
LOCAL oRep, oQry, nRow, nCol, oFont1, oFont2, oQryP, config,  nAncho, oPrn
oQry := oApp:oServer:Query("SELECT ps.*, e.nombre FROM ge_"+oApp:cId+"emp_pagsueldo ps "+;
                           "LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON e.codigo = ps.codemp "+;
                           "WHERE ps.numero = " + ClipValue2Sql(n))
IF oQry:nRecCount = 0
   MsgStop("El pago de sueldo no existe!!","Error")
   RETURN NIL
ENDIF
oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
DO CASE
      CASE !oQryP:imprimeTic // NO Factura por comandera
         ** FACTURACION CON FORMATO PARA FACTURA ELECTRONICA     
         IF config:fon < 14
             config:fon := config:fon *2.8
         ENDIF     
         DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*3 BOLD         
         DEFINE FONT oFont1  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD        
         PRINT oPrn NAME "Pago de Sueldo" PREVIEW MODAL 
         oPrn:SetPortrait()
         oPrn:SetPage(9)
           PAGE                         
           oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
           oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
           oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente    
           oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
           @ .8, 01.15 PRINT TO oPrn TEXT "ORIGINAL";
                    SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
           @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                        SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
           @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                        SIZE 9,1 CM FONT oFont1 LASTROW nRow ALIGN "C"                         
           oPrn:CmSay( 2  , 11, "PAGO A EMPLEADO", oFont2 )   

           oPrn:CmSay( 2.5, 11, "Recibo Nro:"+STR(oQry:numero,8),oFont2)
           oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(oQry:fecha),oFont1)

           oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont1)
           oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont1) 
           oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont1)    
                           
           @ 6, 9.5  PRINT TO oPrn TEXT "Empleado:" ;
                    SIZE 2.5,1 CM FONT oFont1 ALIGN "R"
           @ 6, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQry:nombre) ;
                    SIZE 8,1 CM FONT oFont2 LASTROW nRow ALIGN "L"
           @ 6,1  PRINT TO oPrn TEXT "Legajo:" ;
                     SIZE 3,1 CM FONT oFont1 ALIGN "R"
           @ 6,4.1 PRINT TO oPrn TEXT STR(oQry:codemp) ;
                    SIZE 6,1 CM FONT oFont2 ALIGN "L"
           
           @ 8,1  PRINT TO oPrn TEXT "Mes:" +STR(oQry:mes);
                    SIZE 3,.5 CM FONT oFont1 ALIGN "R"           
           @ 9,1  PRINT TO oPrn TEXT "Año:" + STR(oQry:ano) ;
                    SIZE 3,.5 CM FONT oFont1 ALIGN "R"           
           @ 10,1  PRINT TO oPrn TEXT "Detalle del pago" ;
                    SIZE 20,.5 CM FONT oFont1 ALIGN "C"
           @ 10.5,1 PRINT TO oPrn TEXT oQry:observa ;
                    SIZE 20,.5 CM FONT oFont2 ALIGN "L"
           @ 11,1  PRINT TO oPrn TEXT "TOTAL PAGADO:"+STR(oQry:importe,12,2) ;
                    SIZE 10,.5 CM FONT oFont1 ALIGN "L"           

           @ 22.5, 12 PRINT TO oPrn TEXT REPLICATE("_",45) ;
                      SIZE 9,.5 CM FONT oFont2 ALIGN "L"
           @ 23, 12 PRINT TO oPrn TEXT oQry:nombre ;
                      SIZE 9,.5 CM FONT oFont1 ALIGN "L"
           @ 23, 01 PRINT TO oPrn TEXT "Recibí de " + ALLTRIM(oApp:nomb_emp) + " la " +;
                        " suma de Pesos: "+ Letra(oQry:importe) + " ($"+STR(oQry:importe)+")";
                      SIZE 10.8,3 CM FONT oFont1
           ENDPAGE
         ENDPRINT
     OTHERWISE
           *********** Impresion de Ticket 
           IF config:fon > 25
              config:fon := config:fon /3
           ENDIF                     
           DEFINE FONT oFont1  NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont2  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD
           IF !oApp:tick80
              nAncho := 4.7
              ELSE 
              nAncho := 7.9
           ENDIF
           PRINT oPrn TO  ALLTRIM(oQryP:impresoraT) //Imprime por comandera
              PAGE                                  
                 nRow := 0                     
                 @ 0, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE nAncho,1 CM FONT oFont2 ALIGN "C" LASTROW nRow
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"                       
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                              
                 @ nRow, .1 PRINT TO oPrn TEXT "PAGO A EMPLEADO" ;
                              SIZE nAncho,.5 CM FONT oFont2 LASTROW nRow ALIGN "C" 
                 @ nRow, .1 PRINT TO oPrn TEXT "RECIBO N° "+ STR(oQry:numero) ;
                              SIZE nAncho,.5 CM FONT oFont2 LASTROW nRow ALIGN "C"                     
                 @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQry:fecha);
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"                                                  
                 @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQry:nombre);
                              SIZE nAncho,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                     
                 @ nRow,.1  PRINT TO oPrn TEXT "Legajo:"+STR(oQry:codemp,6) ;
                          SIZE nAncho,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow
                 
                 @ nRow,.1  PRINT TO oPrn TEXT "Mes:"+STR(oQry:mes) ;
                          SIZE nAncho,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow                     
                 @ nRow,.1  PRINT TO oPrn TEXT "Año:"+STR(oQry:ano) ;
                          SIZE nAncho,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow                     
                 @ nRow,.1  PRINT TO oPrn TEXT "Detalle:" + oQry:observa ;
                          SIZE nAncho,1 CM FONT oFont1 ALIGN "L" LASTROW nRow                     
                 @ nRow,.1  PRINT TO oPrn TEXT "TOTAL PAGADO:" + STR(oQry:importe,12,2);
                          SIZE nAncho,.5 CM FONT oFont2 ALIGN "L" LASTROW nRow                     
                 @ nRow,.1 PRINT TO oPrn TEXT REPLICATE("_",45) ;
                            SIZE nAncho,.5 CM FONT oFont2 ALIGN "C" LASTROW nRow
                 @ nRow,.1 PRINT TO oPrn TEXT ALLTRIM(oQry:nombre) ;
                            SIZE nAncho,.5 CM FONT oFont1 ALIGN "C" 
              ENDPAGE
           ENDPRINT 
ENDCASE   
RETURN NIL

*********************************************
**Pago simple de adelanto
STATIC FUNCTION PagoAdelantoSimpre()
LOCAL oGet := ARRAY(12), oBot := ARRAY(2), oForm, lRta := .f., aCor, oError, oQryCue, mresto1, mresto2 := 0, oQr,;
      mresto := 0, mpago :=  0, mcuenta := 0, mcuennom := SPACE(30), mobserva := SPACE(30),;
      mmes := MONTH(DATE()), mano := YEAR(DATE()), nForma := 1, aFormas := {"Efectivo"}, nId,;
      oQryPro, nCodEmp := 0, cNomEmp := SPACE(30)
mresto1 := mpago
mpago := IF(mpago<0,0,mpago)
oQryPro:= oApp:oServer:Query("SELECT codigo,nombre,sueldo FROM ge_"+oApp:cId+"emp_empleado")
oQryCue:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"cuentas")
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Registro de pago a Empleado" FROM 05,15 TO 21,70 OF oApp:oWnd
   
   @ 07, 05 SAY "Empleado:"              OF oForm PIXEL SIZE 50,20 RIGHT   
   @ 22, 05 SAY "SU PAGO:"               OF oForm PIXEL SIZE 50,20 RIGHT   
   @ 37, 05 SAY "Período al que aplica:" OF oForm PIXEL SIZE 50,20 RIGHT
   @ 52, 05 SAY "Forma de Pago:"         OF oForm PIXEL SIZE 50,20 RIGHT
   @ 67, 05 SAY "Cuenta Bancaria:"       OF oForm PIXEL SIZE 50,20 RIGHT   
   @ 82, 05 SAY "Observaciones:"         OF oForm PIXEL SIZE 50,20 RIGHT   
  
   @ 05, 65 GET oGet[1] VAR nCodEmp         PICTURE "999999"            OF oForm PIXEL RIGHT SIZE 30,12;      
      VALID(buscar(oQryPro, oForm,  oGet[1], oGet[2])) ;
      ACTION (oGet[1]:cText := 0,buscar(oQryPro, oForm, oGet[1], oGet[2])) BITMAP "BUSC1" 
   @ 05, 95 GET oGet[2] VAR cNomEmp    OF oForm PIXEL WHEN(.F.)   
   @ 20, 65 GET oGet[4] VAR mpago           PICTURE "999999999.99"    OF oForm PIXEL RIGHT   
   @ 35, 65 GET oGet[5] VAR mmes            PICTURE "99"              OF oForm PIXEL RIGHT VALID(mmes>0 .and. mmes<13)
   @ 35, 90 GET oGet[6] VAR mano            PICTURE "9999"            OF oForm PIXEL RIGHT VALID(mano>=YEAR(DATE()))
   @ 50, 65 COMBOBOX oGet[7] VAR nForma ITEMS aFormas  OF oForm PIXEL SIZE 100,12 ON CHANGE (oGet[8]:Refresh(), oGet[4]:SetFocus(),oGet[7]:SetFocus())
   @ 65, 65 GET oGet[8] VAR mcuenta         PICTURE "9999"            OF oForm PIXEL RIGHT SIZE 30,12;
      WHEN(oGet[7]:nAt==2);
      VALID(buscar(oQryCue, oForm,  oGet[8], oGet[9])) ;
      ACTION (oGet[8]:cText := 0,buscar(oQryCue, oForm, oGet[8], oGet[9])) BITMAP "BUSC1" 
   @ 65, 95 GET oGet[9] VAR mcuennom    OF oForm PIXEL WHEN(.F.)
   @ 80, 65 GET oGet[10] VAR mobserva   OF oForm PIXEL 
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL WHEN(mpago>0)
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()  
  IF nForma = 2
     mobserva := ALLTRIM(mobserva)+" ("+ALLTRIM(mcuennom)+")"
  ENDIF   
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_pagsueldo (mes,ano,importe , fecha, observa, tipo, codemp, usuario  ) VALUES ("+;
                       ClipValue2Sql(mmes)+","+ClipValue2Sql(mano)+","+ClipValue2Sql(mpago)+",CURDATE(),"+;
                       ClipValue2Sql(mobserva)+","+ClipValue2Sql(nForma)+","+ClipValue2Sql(nCodEmp)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
  nId := oApp:oServer:LastInsertID()
  IF nForma = 1
     mobserva := ALLTRIM(mobserva)+" (P.Sueldo: "+ALLTRIM(cNomEmp)+")"
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"retiros (importe,fecha, observa, tipo, checkeado, caja, usuario  ) "+;
                          " VALUES ("+;
                       ClipValue2Sql(mpago)+",CURDATE(),"+ClipValue2Sql(mobserva)+",'R',false,"+ClipValue2Sql(oApp:prefijo)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
     ELSE
     mobserva := ALLTRIM(mobserva)+" (P.Sueldo: "+ALLTRIM(cNomEmp)+")"
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito (importe,fecemi,fecacr,codtip,tipo, detalle, banco, usuario) "+;
                          " VALUES ("+;
                       ClipValue2Sql(mpago)+",CURDATE(),CURDATE(),1,'R',"+ClipValue2Sql(mobserva)+","+ClipValue2Sql(mcuenta)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
  ENDIF 
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
ReciPago(nId)
RETURN nil