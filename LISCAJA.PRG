#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "hbcompat.ch"
#include "report.ch"
*************************************************
** LISTADO DE CAJAS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana, oError
PROCEDURE RepVen8(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol, oMen, nOpt := 1
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

   CursorWait()   
   oQry  := oApp:oServer:Query( "SELECT c.id,c.fecha,c.saldo,c.caja,c.hora,cd.debe,"+;
    "cd.haber,cd.efectivo FROM ge_"+oApp:cId+"cajadiaria c "+;
    "LEFT JOIN "+;
    "(SELECT id_caja, SUM(debe) AS debe,SUM(haber) AS haber,SUM(efectivo) AS efectivo "+;
    " FROM ge_"+oApp:cId+"cajadiaria_det WHERE LEFT(concepto,1) <> '*'  GROUP BY id_caja) cd ON cd.id_caja = c.id "+;
    IF(oApp:usua_es_supervisor,""," WHERE c.caja = "+str(oApp:prefijo)) +" "+;
    "ORDER BY c.id DESC ")
   
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Control de cajas" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MOVIM" OF oBar ;
            TOOLTIP "Reimprimir cierre de caja"  ;
            ACTION ImprimirCaja(oQry:Id,.T.);
            PROMPT "Ver Cierre" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "FORM" OF oBar ;
            TOOLTIP "Ver detalle de formas de pago"  ;
            ACTION ImprimirDetCaja1(oQry:Id);
            PROMPT "Ver formas" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "CIETUR" OF oBar ;
            TOOLTIP "Detalle de Ingresos / Egresos por fecha"  ;
            ACTION ReportePorFecha();
            PROMPT "Informe" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "GRAFVEN" OF oBar ;
            TOOLTIP "Auditoria" ;
            ACTION (oWnd1:End(),Audita(cPermisos)) WHEN("A"$cPermisos);
            PROMPT "Auditoria" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Cierres",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)    
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
   DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
        REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Id","caja","fecha","hora","debe","haber","saldo","efectivo";
              HEADERS "Cierre","Caja","Fecha","Hora","Ingresos","Egresos","Falt/Sob","Efectivo";
              SIZES   80,80,80,80,80,80,80,80;
              ID 111 OF oDlg  
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     PintaBrw(oBrw,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE     
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
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

************************************
** Reporte Por Fechas
STATIC FUNCTION ReportePorFecha()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,  mdesde := CTOD("01/01/2010"), mhasta := DATE(),;
      mTotal := 0, lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"}
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Detalle de Ingresos / Egresos por fecha" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN NIL
ENDIF
CursorWait()
lTipo:= IF(nTipo=1,.f.,.t.)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC     
oQry  := oApp:oServer:Query( "SELECT c.id,c.fecha,c.saldo,c.caja,c.hora,cd.debe,cd.haber,cd.efectivo,cd.concepto "+;
  " FROM ge_"+oApp:cId+"cajadiaria_det cd "+;
    "LEFT JOIN "+;
    " ge_"+oApp:cId+"cajadiaria c ON cd.id_caja = c.id "+;
    "WHERE c.fecha BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +" "+;
    "ORDER BY cd.concepto, c.fecha ")
REPORT oRep TITLE "Detalle de Cajas " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp)  , ;
       "Detalle de Ingresos / Egresos por fecha " CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Detalle de Ingresos / Egresos por fecha"
GROUP ON oQry:concepto HEADER "Concepto:"+ oQry:concepto FOOTER "Total Concepto" FONT 3
COLUMN TITLE "Cierre"      DATA oQry:id    SIZE 6 FONT 1
COLUMN TITLE "Fecha"       DATA FechaSql(oQry:fecha)     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Debe"        DATA oQry:debe      PICTURE "999999999.99" ;
                           SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Haber"       DATA oQry:haber PICTURE "999999999.99" ;
                           SIZE 10 FONT 2 TOTAL


// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop()}
oRep:bSkip := {|| oQry:Skip()}

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)         

oQry:End()
RETURN NIL


************************************
** Reporte Resultado
STATIC FUNCTION ReporteResultado()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,  mdesde := CTOD("01/01/2010"), mhasta := DATE(),;
      mTotal := 0, lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"}
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte Resultado" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN NIL
ENDIF
CursorWait()
lTipo:= IF(nTipo=1,.f.,.t.)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
oQry  := oApp:oServer:Query( "SELECT RES.* FROM (("+;
  "SELECT 'Ventas periodo' as concepto, SUM(importe*if(ticomp='NC',-1,1)) as debe, 0 as haber FROM  ge_"+oApp:cId+"ventas_encab "+;
  "WHERE fecha BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +") "+;
  "UNION ALL ("+;
  "SELECT 'Compras periodo' as concepto, 0 as debe, SUM(importe*if(tipocomp='NC',-1,1)) as haber FROM  ge_"+oApp:cId+"compras "+;
  "WHERE fecfac BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +") "+;
  "UNION ALL ("+;
  "SELECT 'Cobranzas periodo' as concepto, SUM(total) as debe, 0 as haber FROM  ge_"+oApp:cId+"pagos "+;
  "WHERE fecha BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +") "+;
  "UNION ALL ("+;
  "SELECT 'Pagos periodo' as concepto, 0 as debe, SUM(total) as haber FROM  ge_"+oApp:cId+"ordpag "+;
  "WHERE fecha BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +") "+;
  "UNION ALL ("+;
  "SELECT 'Faltantes / Sobrantes de caja' as concepto, 0 as debe, SUM(saldo) as haber FROM  ge_"+oApp:cId+"cajadiaria "+;
  "WHERE fecha BETWEEN " + ClipValue2Sql(mdesde) + " AND " + ClipValue2Sql(mhasta) +")) RES "  )
REPORT oRep TITLE "Reporte Resultado " + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp)  , ;
       "Reporte Resultado" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Reporte Resultado"
COLUMN TITLE "Concepto"    DATA oQry:concepto    SIZE 35 FONT 1
COLUMN TITLE "Ingresos"    DATA oQry:debe      PICTURE "999999999.99" ;
                           SIZE 10 FONT 2 
COLUMN TITLE "Haber"       DATA oQry:haber PICTURE "999999999.99" ;
                           SIZE 10 FONT 2 


// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop()}
oRep:bSkip := {|| oQry:Skip()}

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)         

oQry:End()
RETURN NIL


************************************
** Reporte Por Fechas de formas de pago
STATIC FUNCTION ImprimirDetCaja1(nId)
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,  mdesde := CTOD("01/01/2010"), mhasta := DATE(),;
      mTotal := 0, lTipo := .f.,nTipo:=1,aTipo:={"Sistema","Demo"}
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Detalle por concepto por fecha" FROM 03,15 TO 13,60 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Turno:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 35, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[3] VAR nId       OF oDlg1 PIXEL PICTURE "99999" WHEN(.f.)
   @ 05, 95 CHECKBOX oGet[4] VAR lTipo PROMPT "Por rango de fecha" OF oDlg1 SIZE 90,12 PIXEL
   @ 20, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL WHEN(lTipo)
   @ 35, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) WHEN(lTipo)
  
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN NIL
ENDIF
IF !lTipo
   ImprimirDetCaja(nId)
   ELSE 
   ImprimirDetCaja(0,mdesde,mhasta)
ENDIF 
RETURN NIL   