#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "Report.ch"

*************************************************
** Cierre de turno
*************************************************
MEMVAR oApp
STATIC oQry,  oBrw, cVentana
PROCEDURE CIERRET(cPermisos)
LOCAL oBar, hHand
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, oError,i, nId,;
      lSuper:=.f., mfecha := DATE(), mefect := 0, mresul := 0, nCaja:= oApp:prefijo, cTexto := SPACE(10)
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
IF nCaja = 0
   MsgInfo("Hay un error en el numero de caja","Error")
   RETURN  
ENDIF
IF oApp:oServer:Query("SELECT * "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND caja = " +ClipValue2Sql(nCaja))):nRecCount = 0
   MsgStop("El turno esta cerrado","Error")
   RETURN 
ENDIF 
AADD(oApp:aVentanas,cVentana)
    oQry := oApp:oServer:Query("SELECT 'FONDO DE CAJA' AS concepto, SUM(importe) AS debe, 0 AS haber, SUM(importe) AS efec "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND caja = " +ClipValue2Sql(nCaja))+;
                             " UNION "+;
                             "SELECT 'INGRESOS/RETIROS MANUAL' AS concepto, SUM(IF(tipo='I',importe,0)) as debe, SUM(IF(tipo='R',importe,0)) AS haber, SUM(-importe*IF(tipo='I',-1,1)) AS efec "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE  checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND caja = "+ClipValue2Sql(nCaja))+;
                             " UNION "+;
                             "SELECT 'INGRESOS EN EFECTIVO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.tipocon = 1 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS EN EFECTIVO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, SUM(-oc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND o.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND oc.codcon = 1 "+;
                             " UNION "+;
                             "SELECT 'INGRESOS POR TARJETAS DEB/CRED' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.tipocon = 4 "+;
                             " UNION "+;
                             "SELECT 'INGRESOS POR MERCADO PAGO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                              " AND pc.tipocon = 8 "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " UNION "+;
                             "SELECT 'EGRESOS POR MERCADO PAGO' AS concepto, 0 AS debe,SUM(pc.importe) AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"ordpag p LEFT JOIN ge_"+oApp:cId+"ordcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.codcon = 8 "+;
                             " UNION "+;
                             "SELECT 'INGRESOS POR TRANSFERENCIAS' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.tipocon = 2 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS POR TRANSFERENCIAS' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND o.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND oc.codcon = 2"+;
                             " UNION "+;
                             "SELECT 'INGRESOS DE CHEQUES ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.tipocon = 3 "+;
                             " UNION "+;
                             "SELECT 'EGRESOS DE CHEQUES' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND o.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND (oc.codcon = 3 OR oc.codcon = 4) "+;
                             " UNION "+;
                             "SELECT '**VENTAS TOTALES TURNO**' AS concepto, SUM(v.importe) AS debe,0 AS haber, 0 AS efec "+;
                             " FROM ge_"+oApp:cId+"concfact v "+;                             
                             "WHERE v.id_cierre IS NULL "+;
                             IF(oApp:unifica_cajas," "," AND v.caja = " +ClipValue2Sql(nCaja))) 
DEFINE DIALOG oForm TITLE "Cierre de turno de caja " + STR(nCaja,2);
       FROM 05,15 TO 28,85 OF oApp:oWnd
   
   @ 07, 05 SAY "Fecha de cierre:"  OF oForm PIXEL SIZE 70,12 RIGHT
   @ 22, 05 SAY "Efectivo rendido:" OF oForm PIXEL SIZE 70,12 RIGHT
   @127, 05 SAY "Resultado       :" OF oForm PIXEL SIZE 70,12 RIGHT
  
   @ 05, 80 GET oGet[1] VAR mfecha   PICTURE "@D"  OF oForm PIXEL CENTER WHEN(.f.)
   @ 20, 80 GET oGet[2] VAR mefect PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                VALID(mefect>0)
   
   @ 35, 05 XBROWSE oBrw SIZE 250,80 pixel OF oForm DATASOURCE oQry ;
      HEADERS "Concepto", "Ingreso","Egreso","Efectivo";
      COLUMNS "concepto", "debe" ,"haber","efec";
      SIZES IF('A'$cPermisos,200,1000),90,90,90;
      CELL LINES NOBORDER FOOTERS
   WITH OBJECT oBrw
      :aCols[1]:cFooter := "Totales - ->"
      :aCols[2]:nFooterTypE := AGGR_SUM
      :aCols[3]:nFooterTypE := AGGR_SUM
      :aCols[4]:nFooterTypE := AGGR_SUM
      WITH OBJECT :Ingreso
         :nFooterType   := AGGR_SUM
         :bSumCondition := { || LEFT(oQry:concepto,1) <> '*' }
      END      
      IF('A'$cPermisos)
        :lFooter := .t.
        ELSE 
        :aCols[2]:Hide()
        :aCols[3]:Hide()
        :aCols[4]:Hide()
      ENDIF
      :MakeTotals()   
      :CreateFromCode()
   END        
   PintaBrw(oBrw,0)
   @125, 80 GET oGet[3] VAR mresul PICTURE "99999999.99"    OF oForm PIXEL RIGHT;
                WHEN((oGet[3]:cText := oBrw:aCols[4]:nTotal - oGet[2]:value) = "xxxx" )
   @125,140 GET oGet[4] VAR cTexto OF oForm PIXEL ;
                WHEN((oGet[4]:cText := IF(oGet[3]:value>0,"Faltante","Sobrante")) = "xxxx" )
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT (oGet[1]:SetFocus(),IF('A'$cPermisos,NIL,(oGet[3]:Hide(),oGet[4]:Hide())))
IF !lRta
   Cerrar()
   RETURN 
ENDIF
TRY
   oApp:oServer:BeginTransaction()
   nId := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"cajadiaria")
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cajadiaria (id,fecha,caja,saldo,hora) VALUES ("+;
                        ClipValue2Sql(nId)+","+;
                        ClipValue2Sql(mfecha)+","+;
                        IF(oApp:unifica_cajas,"0",ClipValue2Sql(nCaja))+","+;
                        ClipValue2Sql(mresul)+",CURTIME())" )
   oQry:Gotop()
   FOR i := 1 TO oQry:nRecCount
       IF oQry:debe <> 0 .or. oQry:haber <> 0
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cajadiaria_det (id_caja,concepto,debe,haber,efectivo) VALUES ("+;
                          ClipValue2Sql(nId)+","+;
                          ClipValue2Sql(oQry:concepto)+","+;
                          ClipValue2Sql(oQry:debe)+","+;
                          ClipValue2Sql(oQry:haber)+","+;
                          ClipValue2Sql(oQry:efec)+")" )
       ENDIF
       oQry:Skip()
   NEXT i
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"fondo    SET checkeado = TRUE, id_cierre = "+ClipValue2Sql(nId)+;
                        " WHERE "+IF(oApp:unifica_cajas,"TRUE","caja = " + ClipValue2Sql(nCaja))+" AND checkeado = FALSE")
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"retiros  SET checkeado = TRUE, id_cierre = "+ClipValue2Sql(nId)+;
                        " WHERE "+IF(oApp:unifica_cajas,"TRUE","caja = " + ClipValue2Sql(nCaja))+" AND checkeado = FALSE")
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagos    SET checkeado = TRUE, id_cierre = "+ClipValue2Sql(nId)+;
                        " WHERE "+IF(oApp:unifica_cajas,"TRUE","caja = " + ClipValue2Sql(nCaja))+" AND checkeado = FALSE")
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ordpag   SET checkeado = TRUE, id_cierre = "+ClipValue2Sql(nId)+;
                        " WHERE "+IF(oApp:unifica_cajas,"TRUE","caja = " + ClipValue2Sql(nCaja))+" AND checkeado = FALSE")
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"concfact SET id_cierre = "+ClipValue2Sql(nId)+;
                        " WHERE "+IF(oApp:unifica_cajas,"TRUE","caja = " + ClipValue2Sql(nCaja))+" AND id_cierre IS NULL") 
   Auditar(5," Caja "+STR(nCaja,4))
   oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)    
END TRY
ImprimirCaja(nId)
IF oApp:oServer:Query("SELECT enviamail FROM ge_"+oApp:cId+"parametros"):enviamail
   EnviarCierre(nId)
ENDIF 
cerrar()
RETURN 

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQry:End()
RELEASE oQry
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

*************************************
** Imprimir la caja
FUNCTION ImprimirCaja(nId,lPrev)
LOCAL oParame, oPrn, i, oFont, config, oQry, oFont1, y, nAnt := 0, nTotD := 0,;
      nTotH := 0, nTotE := 0, nTotEfe := 0, oGru, lComan,oPr,nRenglon,nRow, oQryP,nTotalVentas, ;
      oQryFor, nMargen, nTotalX, nTotalB
DEFAULT lPrev := .f.
oQry := oApp:oServer:Query("SELECT cd.*,c.*,c.id AS num FROM ge_"+oApp:cId+"cajadiaria c LEFT JOIN "+;
                             "("+;
                             "(SELECT 'SALDO INICIAL ' AS concepto, importe AS debe, 0 AS haber, importe AS efec,id_cierre,1 AS orden "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" ) "+;
                             " UNION "+;
                             "(SELECT CONCAT('INGRESO A CAJA ',TRIM(observa),' ',id) AS concepto, importe as debe, 0 AS haber, importe AS efec,id_cierre,2 AS orden  "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" AND tipo = 'I' )  "+;
                             " UNION "+;
                             "(SELECT CONCAT('RETIRO DE CAJA ',TRIM(observa), ' ', id) AS concepto, 0 as debe, importe AS haber, importe*(-1) AS efec,id_cierre,3 AS orden  "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" AND tipo = 'R' )  "+;
                             " UNION "+;
                             "(SELECT 'INGRESOS EN EFECTIVO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec,id_cierre,4 AS orden   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 1 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'PAGOS EN EFECTIVO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, SUM(-oc.importe) AS efec,id_cierre,5 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 1 "+;
                             "GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS CON TARJETAS DEB/CRED' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,6 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 4 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS POR TRANSFERENCIAS' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,7 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 2 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS POR TRANSFERENCIAS' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,8 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 2 "+;
                             " GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS POR MERCADO PAGO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,7 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 8 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS POR MERCADO PAGO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,8 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 8 "+;
                             " GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS DE CHEQUES ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec,id_cierre,9 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 3 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS DE CHEQUES' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,10 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND (oc.codcon = 3 OR oc.codcon = 4) GROUP BY o.id_cierre) "+;
                             ") cd ON cd.id_cierre =  "+ClipValue2Sql(nId)+;
                             " WHERE c.id = " + ClipValue2Sql(nId)+ ;
                             " ORDER BY  c.id,cd.orden" )
IF oQry:nRecCount = 0
   MsgInfo("Cierre no existe","Error")
   RETURN NIL 
ENDIF

//lComan := MsgNoYes("Emite por comandera?")
lComan := SiNoCancelar("Atencion","Por donde desea emitir el reporte de caja?",{"Comandera","Impresora","No imprimir"})
IF lComan == nil 
   RETURN nil 
ENDIF
oParame := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")
config := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
/*nTotalVentas := oApp:oServer:Query("SELECT SUM(v.importe*IF(v.ticomp='NC',-1,1)) AS ventas "+;
                             " FROM ge_"+oApp:cId+"pagos p "+;
                             "LEFT JOIN ge_"+oApp:cId+"pagfac pf ON p.numero = pf.numero "+;
                             "LEFT JOIN ge_"+oApp:cId+"ventas_encab v ON pf.ticomp = v.ticomp AND pf.letra = v.letra AND pf.numcomp = v.numcomp "+;
                             "WHERE p.id_cierre = "+ClipValue2Sql(nId)+;
                             " AND v.fecha = p.fecha "):ventas*/
nTotalVentas := oApp:oServer:Query("SELECT SUM(v.importe) AS ventas "+;
                             " FROM ge_"+oApp:cId+"concfact v "+;                             
                             "WHERE v.id_cierre = "+ClipValue2Sql(nId)):ventas
nTotalX := oApp:oServer:Query("SELECT SUM(v.importe) AS ventas "+;
                             " FROM ge_"+oApp:cId+"concfact v "+;                             
                             "WHERE v.letra = 'X' AND v.id_cierre = "+ClipValue2Sql(nId)):ventas
nTotalB := nTotalVentas - nTotalX
IF lComan
   IF config:fon > 25
      config:fon := config:fon /3
   ENDIF 
   oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
   oQryFor := oApp:oServer:Query("SELECT ANY_VALUE(caja) AS caja, ANY_VALUE(fecha) AS fecha, ANY_VALUE(observa) AS observa, SUM(importe) as importe, "+;
                           "count(importe) AS casos  FROM ge_"+oApp:cId+"concfact "+;
                           " WHERE id_cierre = "+ClipValue2Sql(nId) +;
                           " GROUP BY observa" )
   DEFINE FONT oFont   NAME "COURIER NEW"       SIZE -config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "COURIER NEW"       SIZE -config:fon,config:fon*3.5 BOLD
   nMargen := IF(oQryP:tick80,7.2,4.6)
   PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
      oPrn:oFont := oFont
      PAGE
      @ 1, .01 PRINT TO oPrn TEXT ALLTRIM(oParame:nomb_emp) ;
                          SIZE nMargen,0.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
      @ nRow, .01 PRINT TO oPrn TEXT "Direccion:"+ALLTRIM(oParame:dire_emp) ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT ALLTRIM(oParame:cuit_emp) ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT ALLTRIM(oParame:loca_emp) ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Caja:"+STR(oQry:caja,4) ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Dia:"+DTOC(oQry:fecha);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Hora cierre:"+ oQry:hora ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Cierre de turno Nro " + STR(nId,4) ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Concepto" ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "   Ingreso   Egresos  Efectivo" ;
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "R"                


      oQry:GoTop()
      y := nRow
      FOR i = 1 TO oQry:nRecCount
          IF nAnt < oQry:orden 
             nAnt := oQry:orden
             IF nTotD <> 0 .or.  nTotH <> 0  .or. nTotE <>0 
                @ nRow, .01 PRINT TO oPrn TEXT "TOTALES";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
                @ nRow, .01 PRINT TO oPrn TEXT  STR(nTotD,12,2)+STR(nTotH,12,2)+STR(nTotE,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "R"
                @ nRow, .01 PRINT TO oPrn TEXT  REPLICATE("-",30);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "C"
                nTotE := 0
                nTotH := 0
                nTotD := 0
              ENDIF
          ENDIF
          nTotEfe := nTotEfe + oQry:efec
          nTotE := nTotE + oQry:efec
          nTotD := nTotD + oQry:debe
          nTotH := nTotH + oQry:haber
          @ nRow, .01 PRINT TO oPrn TEXT  LEFT(oQry:concepto,30);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
          @ nRow, .01 PRINT TO oPrn TEXT  STR(oQry:debe,12,2)+STR(oQry:haber,12,2)+STR(oQry:efec,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "R"
          oQry:SKIP()
      NEXT i
      IF nTotD <> 0 .or.  nTotH <> 0  .or. nTotE <>0 
          @ nRow, .01 PRINT TO oPrn TEXT  "TOTALES";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
          @ nRow, .01 PRINT TO oPrn TEXT   STR(nTotD,12,2)+STR(nTotH,12,2)+STR(nTotE,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "R"
          @ nRow, .01 PRINT TO oPrn TEXT   REPLICATE("-",30);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "C"               
      ENDIF
      IF oQryFor:nRecCount > 0
          @ nRow+.3, .01 PRINT TO oPrn TEXT "Formas de pago de ventas";
                          SIZE nMargen,0.5 CM FONT oFont1 LASTROW nRow ALIGN "L"          
          oQryFor:GoTop()
          FOR i = 1 TO oQryFor:nRecCount              
              @ nRow+.3, .01 PRINT TO oPrn TEXT LEFT(oQryFor:observa,15)+STR(oQryFor:importe,10,2)+STR(oQryFor:casos,4)+ " Op.";
                          SIZE nMargen,0.5 CM FONT oFont1 LASTROW nRow ALIGN "L"              
              oQryFor:SKIP()
          NEXT i
      ENDIF
      @ nRow, .01 PRINT TO oPrn TEXT "Total Efectivo caja:"+ STR(nTotEfe,10,2);
                          SIZE nMargen,0.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Efectivo declarado :"+ STR(nTotEfe-oQry:saldo,10,2);
                          SIZE nMargen,0.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT IF(oQry:saldo>0,"Faltante:","Sobrante:")+ STR(ABS(oQry:saldo),10,2);
                          SIZE nMargen,0.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "_________________    _________________";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "C"
      @ nRow, .01 PRINT TO oPrn TEXT "Firma operador       Firma encarg.";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "C"
      @ nRow, .01 PRINT TO oPrn TEXT "Venta turno: $"+STR(nTotalVentas,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Facturado: $"+STR(nTotalB,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
      @ nRow, .01 PRINT TO oPrn TEXT "Presup.: $"+STR(nTotalX,12,2);
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"                    
      @ nRow, .01 PRINT TO oPrn TEXT "  -  - - - FIN DE CAJA - - - - - - - ";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "C"
      @ nRow, .01 PRINT TO oPrn TEXT "....";
                          SIZE nMargen,0.5 CM FONT oFont LASTROW nRow ALIGN "L"
   
      ENDPAGE
   ENDPRINT
   ELSE 
   DEFINE FONT oFont  NAME "ARIAL" SIZE 0,-8
   DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8 BOLD
   oQryFor := oApp:oServer:Query("SELECT ANY_VALUE(caja) AS caja, ANY_VALUE(fecha) AS fecha, ANY_VALUE(observa) AS observa, SUM(importe) as importe, "+;
                           "count(importe) AS casos  FROM ge_"+oApp:cId+"concfact "+;
                           " WHERE id_cierre = "+ClipValue2Sql(nId) +;
                           " GROUP BY observa" )
   oQry:GoTop()
   IF !lPrev
       PRINT oPr
       REPORT oPrn TITLE "Cierre de turno" + DTOC(oQry:fecha) + " Caja:"+ STR(oQry:caja,4) + " Cierre Nro:"+STR(nId,4) ;       
           HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)),;       
           IF(oQry:saldo>0,"Faltante:","Sobrante:")+ STR(ABS(oQry:saldo),10,2),;
           "Ventas Total Turno: $"+STR(nTotalVentas,12,2),"Facturado: $"+STR(nTotalB,12,2),"Presupuestos:$"+STR(nTotalX,12,2) CENTER ;       
           FOOTER "Firma operador:____________________    Firma del Encargado:_____________________";
           TO DEVICE oPr;
           FONT oFont,oFont1;
           CAPTION  "Cierre de turno" PREVIEW
       ELSE 
       REPORT oPrn TITLE "Cierre de turno" + DTOC(oQry:fecha) + " Caja:"+ STR(oQry:caja,4) + " Cierre Nro:"+STR(nId,4) ;       
           HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)),;       
           IF(oQry:saldo>0,"Faltante:","Sobrante:")+ STR(ABS(oQry:saldo),10,2) ,;
           "Ventas Total Turno: $"+STR(nTotalVentas,12,2),"Facturado: $"+STR(nTotalB,12,2),"Presupuestos:$"+STR(nTotalX,12,2) CENTER ;       
           FOOTER "Firma operador:____________________    Firma del Encargado:_____________________";         
           FONT oFont,oFont1;
           CAPTION  "Cierre de turno" PREVIEW
    ENDIF
       GROUP oGru ON oQry:orden HEADER STR(oQry:orden,2) FOOTER "Parciales"  FONT 2
        COLUMN TITLE "Concepto"  DATA oQry:concepto  SIZE 30
        COLUMN TITLE "Ingresos"  DATA oQry:debe      PICTURE "999999999.99" SIZE 12 TOTAL
        COLUMN TITLE "Egresos"   DATA oQry:haber     PICTURE "999999999.99" SIZE 12 TOTAL
        COLUMN TITLE "Efectivo"  DATA oQry:efec      PICTURE "999999999.99" SIZE 12 TOTAL

        // Digo que el titulo lo escriba con al letra 2        
        oPrn:bInit := {|| oQry:GoTop() }
        oPrn:bSkip := {|| oQry:Skip() }

        END REPORT

        ACTIVATE REPORT oPrn WHILE !oQry:EOF() ON INIT CursorArrow() ;
                 ON STARTPAGE oPrn:SayBitmap(.1,.1,"LOGO.JPG",.5,.5);
                 ON STARTGROUP oPrn:NewLine();
                 ON POSTGROUP oPrn:NewLine();
                 ON POSTEND Resume(oPrn,oQry:saldo,oQryFor)

ENDIF
RELEASE oFont
RETURN NIL

STATIC FUNCTION Resume(oRep,n, oQryFor)
LOCAL i
IF oQryFor:nRecCount > 0
    oRep:NewLine()
    oRep:StartLine()
    oRep:NewLine()
    oRep:StartLine()
    oRep:Say( 1, "Formas de pago de ventas",2)
    oQryFor:GoTop()    
    FOR i = 1 TO oQryFor:nRecCount 
        oRep:NewLine()
        oRep:StartLine()             
        oRep:Say(1, LEFT(oQryFor:observa,15))
        oRep:Say(2, STR(oQryFor:importe,12,2),1,2)
        oRep:Say(3, STR(oQryFor:casos,4)+ " Op.",1,2)
        oQryFor:SKIP()
    NEXT i
ENDIF
oRep:NewLine()
oRep:StartLine()
oRep:NewLine()
oRep:TotalLine( RPT_DOUBLELINE )
oRep:Say(1,"TOTALES GENERALES",2)
oRep:NewLine()
oRep:StartLine()
IF oRep:NeedNewPage() 
   oRep:EndPage()
   oRep:StartPage()
ENDIF
oRep:Say(1,"EFECTIVO DECLARADO",2)
oRep:Say(6,STR(oRep:aColumns[4]:nTotal-n,12,2),1,2)
oRep:NewLine()
oRep:StartLine()
IF oRep:NeedNewPage() 
   oRep:EndPage()
   oRep:StartPage()
ENDIF
oRep:NewLine()
oRep:StartLine()
IF oRep:NeedNewPage() 
   oRep:EndPage()
   oRep:StartPage()
ENDIF
oRep:Say(1,IF(n<0,"SOBRANTE DE CAJA","FALTANTE DE CAJA"),2)
oRep:Say(6,STR(n*IF(n>0,1,-1),12,2),1,2)
RETURN nil

*************************************
** Imprimir la caja detalle por forma de pago
FUNCTION ImprimirDetCaja(nId, dDesde, dHasta)
LOCAL oParame, oPrn, i, oFont, config, oQry, oFont1, y, nAnt := 0, nTotD := 0,;
      nTotH := 0, nTotE := 0, nTotEfe := 0, oGru, lComan,oPr
IF nId > 0      
    oQry := oApp:oServer:Query("SELECT caja, fecha, observa, SUM(importe) as importe, "+;
                               "count(importe) AS casos  FROM ge_"+oApp:cId+"concfact "+;
                               " WHERE id_cierre = "+ClipValue2Sql(nId) +;
                               " GROUP BY observa" )
    IF oQry:nRecCount = 0
       MsgInfo("Cierre no existe","Error")
       RETURN NIL 
    ENDIF
       DEFINE FONT oFont  NAME "ARIAL" SIZE 0,-8
       DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8 BOLD
       oQry:GoTop()
       REPORT oPrn TITLE "Detalle de formas de pago " + DTOC(oQry:fecha) + " Caja:"+ STR(oQry:caja,4) + " Cierre Nro:"+STR(nId,4) ;       
               HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)) CENTER ;                             
               FONT oFont,oFont1;
               CAPTION  "Detalle por forma de pago" PREVIEW

            COLUMN TITLE "Concepto"  DATA oQry:observa  SIZE 30
            COLUMN TITLE "Importe"   DATA oQry:importe      PICTURE "999999999.99" SIZE 12 TOTAL
            COLUMN TITLE "Casos"     DATA oQry:casos         PICTURE "99999" SIZE 12 TOTAL
            

            // Digo que el titulo lo escriba con al letra 2        
            oPrn:bInit := {|| oQry:GoTop() }
            oPrn:bSkip := {|| oQry:Skip() }

            END REPORT

            ACTIVATE REPORT oPrn WHILE !oQry:EOF() ON INIT CursorArrow() ;
                     ON STARTPAGE oPrn:SayBitmap(.1,.1,"LOGO.JPG",.5,.5)
   ELSE
   oQry := oApp:oServer:Query("SELECT caja, fecha, observa, SUM(importe) as importe, "+;
                               "count(importe) AS casos  FROM ge_"+oApp:cId+"concfact "+;
                               " WHERE fecha >= "+ClipValue2Sql(dDesde) +;
                               " AND fecha <= "+ClipValue2Sql(dHasta) +;
                               " GROUP BY observa" )
    IF oQry:nRecCount = 0
       MsgInfo("Cierre no existe","Error")
       RETURN NIL 
    ENDIF
       DEFINE FONT oFont  NAME "ARIAL" SIZE 0,-8
       DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8 BOLD
       oQry:GoTop()
       REPORT oPrn TITLE "Detalle de formas de pago " + DTOC(oQry:fecha) + " Caja:"+ STR(oQry:caja,4) + " Desde: "+DTOC(dDesde) +;
               " Hasta: "+DTOC(dHasta) ;
               HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)) CENTER ;                             
               FONT oFont,oFont1;
               CAPTION  "Detalle por forma de pago" PREVIEW

            COLUMN TITLE "Concepto"  DATA oQry:observa  SIZE 30
            COLUMN TITLE "Importe"   DATA oQry:importe      PICTURE "999999999.99" SIZE 12 TOTAL
            COLUMN TITLE "Casos"     DATA oQry:casos         PICTURE "99999" SIZE 12 TOTAL
            

            // Digo que el titulo lo escriba con al letra 2        
            oPrn:bInit := {|| oQry:GoTop() }
            oPrn:bSkip := {|| oQry:Skip() }

            END REPORT

            ACTIVATE REPORT oPrn WHILE !oQry:EOF() ON INIT CursorArrow() ;
                     ON STARTPAGE oPrn:SayBitmap(.1,.1,"LOGO.JPG",.5,.5)
ENDIF
RELEASE oFont, oFont1
RETURN NIL


STATIC FUNCTION EnviarCierre(nId)
LOCAL oParame, oPrn, i, oFont, config, oQry, oFont1, y, nAnt := 0, nTotD := 0, oQryFor,;
      nTotH := 0, nTotE := 0, nTotEfe := 0, oGru, lComan,oPr, nTotalVentas,nRow,nRow1,nTotalComensales,oQryV,;
      oFontEncab,oFontSubTit,oFontSubTitN,oFontOpc,oFontTot,oFontCombina,cText,oFontDet,oFontDetN,oQryComand,;
      nTotalX, nTotalB
oQry := oApp:oServer:Query("SELECT cd.*,c.*,c.id AS num FROM ge_"+oApp:cId+"cajadiaria c LEFT JOIN "+;
                             "("+;
                             "(SELECT 'SALDO INICIAL ' AS concepto, importe AS debe, 0 AS haber, importe AS efec,id_cierre,1 AS orden "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" ) "+;
                             " UNION "+;
                             "(SELECT CONCAT('INGRESO A CAJA ',TRIM(observa),' ',id) AS concepto, importe as debe, 0 AS haber, importe AS efec,id_cierre,2 AS orden  "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" AND tipo = 'I' )  "+;
                             " UNION "+;
                             "(SELECT CONCAT('RETIRO DE CAJA ',TRIM(observa), ' ', id) AS concepto, 0 as debe, importe AS haber, importe*(-1) AS efec,id_cierre,3 AS orden  "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE id_cierre = " + ClipValue2Sql(nId) +" AND tipo = 'R' )  "+;
                             " UNION "+;
                             "(SELECT 'VENTAS EN EFECTIVO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, SUM(pc.importe) AS efec,id_cierre,4 AS orden   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 1 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'PAGOS EN EFECTIVO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, SUM(-oc.importe) AS efec,id_cierre,5 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 1 "+;
                             "GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'VENTAS CON TARJETAS DEB/CRED' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,6 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 4 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS POR TRANSFERENCIAS' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,7 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 2 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS POR TRANSFERENCIAS' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,8 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 2 "+;
                             " GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS POR MERCADO PAGO' AS concepto, SUM(pc.importe) AS debe,0 AS haber, 0 AS efec,id_cierre,7 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 8 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS POR MERCADO PAGO' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,8 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND oc.codcon = 8 "+;
                             " GROUP BY o.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'INGRESOS DE CHEQUES ' AS concepto, SUM(importe) AS debe,0 AS haber, 0 AS efec,id_cierre,9 AS orden  "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND pc.tipocon = 3 "+;
                             " GROUP BY p.id_cierre )"+;
                             " UNION "+;
                             "(SELECT 'EGRESOS DE CHEQUES' AS concepto, 0 AS debe,SUM(oc.importe) AS haber, 0 AS efec,id_cierre,10 AS orden   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.id_cierre =  "+ClipValue2Sql(nId)+;
                             " AND (oc.codcon = 3 OR oc.codcon = 4) GROUP BY o.id_cierre) "+;
                             ") cd ON cd.id_cierre =  "+ClipValue2Sql(nId)+;
                             " WHERE c.id = " + ClipValue2Sql(nId)+ ;
                             " ORDER BY  c.id,cd.orden" )
IF oQry:nRecCount = 0
   MsgInfo("Cierre no existe","Error")
   RETURN NIL 
ENDIF

oParame := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")

nTotalVentas := oApp:oServer:Query("SELECT SUM(v.importe) AS ventas "+;
                             " FROM ge_"+oApp:cId+"concfact v "+;                             
                             "WHERE v.id_cierre = "+ClipValue2Sql(nId)):ventas
nTotalX := oApp:oServer:Query("SELECT SUM(v.importe) AS ventas "+;
                             " FROM ge_"+oApp:cId+"concfact v "+;                             
                             "WHERE v.letra = 'X' AND v.id_cierre = "+ClipValue2Sql(nId)):ventas
nTotalB := nTotalVentas - nTotalX

oQryFor := oApp:oServer:Query("SELECT ANY_VALUE(caja) AS caja, ANY_VALUE(fecha) AS fecha, ANY_VALUE(observa) AS observa, SUM(importe) as importe, "+;
                           "count(importe) AS casos  FROM ge_"+oApp:cId+"concfact "+;
                           " WHERE id_cierre = "+ClipValue2Sql(nId) +;
                           " GROUP BY observa" )
   DEFINE FONT oFont  NAME "ARIAL" SIZE 0,-8
   DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8 BOLD
   oQry:GoTop()
   PRINT oPr FILE "ADJUNTO.PDF"

       REPORT oPrn TITLE "Cierre de turno" + DTOC(oQry:fecha) + " Caja:"+ STR(oQry:caja,4) + " Cierre Nro:"+STR(nId,4) ;       
           HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)),;       
           IF(oQry:saldo>0,"Faltante:","Sobrante:")+ STR(ABS(oQry:saldo),10,2),;
           "Ventas Total Turno: $"+STR(nTotalVentas,12,2),"Facturado: $"+STR(nTotalB,12,2),"Presupuestos:$"+STR(nTotalX,12,2) CENTER ;       
           FOOTER "Firma operador:____________________    Firma del Encargado:_____________________";
           TO DEVICE oPr;
           FONT oFont,oFont1;
           CAPTION  "Cierre de turno" PREVIEW    
   
       GROUP oGru ON oQry:orden HEADER STR(oQry:orden,2) FOOTER "Parciales"  FONT 2
        COLUMN TITLE "Concepto"  DATA oQry:concepto  SIZE 30
        COLUMN TITLE "Ingresos"  DATA oQry:debe      PICTURE "999999999.99" SIZE 12 TOTAL
        COLUMN TITLE "Egresos"   DATA oQry:haber     PICTURE "999999999.99" SIZE 12 TOTAL
        COLUMN TITLE "Efectivo"  DATA oQry:efec      PICTURE "999999999.99" SIZE 12 TOTAL

        // Digo que el titulo lo escriba con al letra 2        
        oPrn:bInit := {|| oQry:GoTop() }
        oPrn:bSkip := {|| oQry:Skip() }

        END REPORT

        ACTIVATE REPORT oPrn WHILE !oQry:EOF() ON INIT CursorArrow() ;
                 ON STARTPAGE oPrn:SayBitmap(.1,.1,"LOGO.JPG",.5,.5);
                 ON STARTGROUP oPrn:NewLine();
                 ON POSTGROUP oPrn:NewLine();
                 ON POSTEND Resume(oPrn,oQry:saldo,oQryFor)

    ENDPRINT
    EnviarPorMail(ALLTRIM(oParame:email),"Cierre de caja Nro: "+STR(nId,6))
RELEASE oFont
RETURN nil


FUNCTION SaldoCaja(nCaja)
LOCAL oQry 
oQry := oApp:oServer:Query("SELECT SUM(res.efec) as efectivo FROM ("+;
                             " SELECT SUM(importe) AS efec "+;
                             " FROM ge_"+oApp:cId+"fondo "+;
                             " WHERE checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND caja = " +ClipValue2Sql(nCaja))+;
                             " UNION "+;
                             "SELECT SUM(-importe*IF(tipo='I',-1,1)) AS efec "+;
                             " FROM ge_"+oApp:cId+"retiros "+;
                             " WHERE  checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND caja = "+ClipValue2Sql(nCaja))+;
                             " UNION "+;
                             "SELECT SUM(pc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"pagos p LEFT JOIN ge_"+oApp:cId+"pagcon pc ON p.numero = pc.numero "+;
                             " WHERE  p.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND p.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND pc.tipocon = 1 "+;
                             " UNION "+;
                             "SELECT SUM(-oc.importe) AS efec   "+;
                             " FROM ge_"+oApp:cId+"ordpag o LEFT JOIN ge_"+oApp:cId+"ordcon oc ON o.numero = oc.numero "+;
                             " WHERE  o.checkeado = FALSE "+;
                             IF(oApp:unifica_cajas," "," AND o.caja = " +ClipValue2Sql(nCaja))+; 
                             " AND oc.codcon = 1 ) res")
RETURN oQry:efectivo 

**************************************************************************************************************
**** Consultar si el efectivo en caja necesita retiro
FUNCTION ValidarSaldoCaja()
LOCAL nLimite := oApp:oServer:Query("SELECT limitepesos FROM ge_"+oApp:cId+"punto WHERE caja = "+ClipValue2Sql(oApp:prefijo)):limitepesos
IF nLimite = 0
   RETURN .t. 
ENDIF   
IF nLimite < SaldoCaja(oApp:prefijo)
   MsgStop("No se puede continuar sin hacer un retiro de caja"+CHR(10)+;
           "Ha llegado al limite permitido","Atencion!")
   RETURN .f.
ENDIF      
RETURN .t.