#include "FiveWin.ch"
#include "report.ch"
#include "Tdolphin.ch"
#include "xbrowse.ch"
MEMVAR oApp
STATIC oQry, oWnd1, cVentana, oForm
PROCEDURE RepHor(cUser,cOpcion)   
   LOCAL oExpBar
   LOCAL oPanel1, bBloque
   LOCAL hHand   
      
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
   AADD(oApp:aVentanas,cVentana)
   
   DEFINE WINDOW oWnd1 TITLE "Reportes" MDICHILD OF oApp:oWnd NOZOOM ICON oApp:oIco
   
   oWnd1:SetSize( 350, oApp:oWnd:oWndClient:nHeight())

   oExpBar = TExplorerBar():New()
   *--
   oPanel1 = oExpBar:AddPanel( " Reportes " , ".\BITMAPS\rbnmenu.bmp"  )
   oPanel1:lSpecial:=.T.
   oPanel1:AddLink( "Parte diario de inasistencias    ",{|| RepSuel1()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Fichadas por empleado            ",{|| RepSuel2()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Resumen de fichadas por sector   ",{|| RepSuel3()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Planilla mensual de inasistencias",{|| RepSuel4()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Planilla anual por empleado      ",{|| RepSuel5()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Planilla por tipo de inasistencia",{|| RepSuel6()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Reporte de pagos a empleados     ",{|| RepSuel7()}, ".\BITMAPS\REPORT.BMP")
   oPanel1:AddLink( "Reporte consumo interno          ",{|| RepSuel8()}, ".\BITMAPS\REPORT.BMP")

      
   oWnd1:oClient = oExpBar
   ACTIVATE WINDOW oWnd1 ON INIT oWnd1:move(0,0) VALID(Cerrar())
 
RETURN

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.
***********************************
** Parte diario de inasistencias
PROCEDURE RepSuel1()
LOCAL oRep, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f., mdesde := DATE(), oQry,;
      mhora := 0, mgrupo := 1, lMensual := .f., mhasta := DATE(), j, cSql, lSolo := .t.
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Parte diario de inasistencias" FROM 03,15 TO 18,65 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Fecha de parte:"     OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 37, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 05, 70 GET oGet[1] VAR mdesde  OF oDlg1 PIXEL   
   @ 20, 01 CHECKBOX oGet[4] VAR lMensual  PROMPT "Emitir informe mensual de parte diario" SIZE 120, 12 OF oDlg1 PIXEL
   @ 35, 70 GET oGet[5] VAR mhasta  OF oDlg1 PIXEL WHEN(lMensual)
   @ 50, 01 CHECKBOX oGet[6] VAR lSolo  PROMPT "Listar solo ausentes" SIZE 120, 12 OF oDlg1 PIXEL
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL 
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
IF !lMensual
    oQry := oApp:oServer:Query("SELECT  "+;
                           "m.codigo as legajo, m.nombre, h.hora1ent,h.hora1sal,"+;
                           " h.hora2ent,h.hora2sal,"+;
                           " h.hora3ent,h.hora3sal,"+;
                           " nov1.codigo, CONCAT(RTRIM(c.nombre),' (',RTRIM(c.observa),')') AS nomcod  "+; 
                           "FROM ge_"+oApp:cId+"emp_empleado  m  "+;
                           "LEFT OUTER JOIN ge_"+oApp:cId+"emp_horas h ON h.codtar = m.codigo and h.fecha = "+ClipValue2Sql(mdesde)+" "+;
                           "LEFT OUTER JOIN (SELECT codigo, legajo FROM ge_"+oApp:cId+"emp_inasi WHERE fecinasi = "+ClipValue2Sql(mdesde)+") "+;
                           "nov1 ON  nov1.legajo = m.codigo " +;
                           "LEFT JOIN  ge_"+oApp:cId+"emp_inasistencia c ON c.codigo = nov1.codigo ORDER BY m.codigo")
    ELSE
    cSql := ""
    FOR j := mdesde TO mhasta
        IF DOW(j) = 1 .OR. DOW(j) = 7
           LOOP
        ENDIF
        cSql := cSql + "SELECT  "+;
                       "m.codigo as legajo, m.nombre, h.hora1ent,h.hora1sal,"+;
                       " h.hora2ent,h.hora2sal,"+;
                       " h.hora3ent,h.hora3sal,"+;
                       " nov1.codigo, CONCAT(RTRIM(c.nombre),' (',RTRIM(c.observa),')') AS nomcod , "+; 
                       ClipValue2Sql(j)+ " AS fec "+; 
                       "FROM ge_"+oApp:cId+"emp_empleado m  "+;
                       "LEFT OUTER JOIN ge_"+oApp:cId+"emp_horas h ON m.codigo = h.codtar and h.fecha = "+ClipValue2Sql(j)+" "+;
                       "LEFT OUTER JOIN (SELECT codigo, legajo FROM ge_"+oApp:cId+"emp_inasi WHERE fecinasi = "+ClipValue2Sql(j)+") "+;
                       "nov1 ON  nov1.legajo = m.codigo " +;
                       "LEFT JOIN  ge_"+oApp:cId+"emp_inasistencia c ON c.codigo = nov1.codigo WHERE h.hora1ent IS NULL AND h.hora1sal IS NULL AND nov1.codigo IS NULL "
         IF j < mhasta
            cSql := cSql + " UNION "
         ENDIF   
      NEXT j
      IF RIGHT(cSql,6) = "UNION "
         cSql := LEFT(cSql,LEN(cSql)-6)
      ENDIF   
      oQry := oApp:oServer:Query("SELECT * FROM (" + cSql + ") res ORDER BY res.fec, res.legajo ")
ENDIF
REPORT oRep TITLE IF(lMensual,"Parte Mensual inasistencias " + DTOC(mdesde) + " al " +  DTOC(mhasta),"Parte diario del dia " + DTOC(mdesde));
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       IF(lMensual,"Parte Mensual", "Parte diario") CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  IF(lMensual,"Parte Mensual", "Parte diario")
       oRep:nCounter := 1
       IF lMensual
          COLUMN TITLE "Fecha"        DATA oQry:fec      SIZE 08 FONT 1
       ENDIF   
       COLUMN TITLE "Legajo"          DATA oQry:legajo   SIZE 06 FONT 1       
       COLUMN TITLE "Nombre"          DATA oQry:nombre   SIZE 20 FONT 2
       COLUMN TITLE "Entrada"         DATA oQry:hora1ent SIZE 10 FONT 2
       COLUMN TITLE "Salida"          DATA oQry:hora1sal SIZE 10 FONT 2
       COLUMN TITLE "Entrada"         DATA oQry:hora2ent SIZE 10 FONT 2
       COLUMN TITLE "Salida"          DATA oQry:hora2sal  SIZE 10 FONT 2
       COLUMN TITLE "Entrada"         DATA oQry:hora3ent SIZE 10 FONT 2
       COLUMN TITLE "Salida"          DATA oQry:hora3sal SIZE 10 FONT 2
       COLUMN TITLE "Cod"             DATA oQry:codigo  SIZE 03 FONT 1
       COLUMN TITLE "Detalle"         DATA IF(EMPTY(oQry:hora1ent) .AND. EMPTY(oQry:hora1sal) .AND. oQry:codigo=0,"**FALTA FICHAR**",;
                                              oQry:nomcod)  SIZE 30 FONT 1

       
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
                FOR IF(lSolo,EMPTY(oQry:hora1ent),.T.);
ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
// Cierro los archivos
oQry:End()
RETURN

***********************************
** Fichadas por empleado
PROCEDURE RepSuel2()
LOCAL oGet := ARRAY(7), oQryEmp, oQry, mdesde := DATE(), mhasta := DATE(), oForm,;
      mcodemp := 0, mnomemp := SPACE(30), aCor, mrta := .f., oBot1, oBot2,;
      oRep, oFont1, oFont2, oFont3,nTipo:=2,aTipo:={"Sistema","Demo"}, lSinValor := .t.,;
      mlimite := 0, cSql

oQryEmp := oApp:oServer:Query("SELECT codigo,nombre,hor_hab_desde1,hor_hab_hasta1,hor_hab_desde2,hor_hab_hasta2  FROM ge_"+oApp:cId+"emp_empleado")
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-11 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-12.5
DEFINE DIALOG oForm TITLE "Detalle de fichadas por empleado" FROM 03,15 TO 14,75 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oForm)
   @ 05, 01 SAY "Legajo Nro::"    OF oForm PIXEL SIZE 60,12 RIGHT
   @ 20, 01 SAY "Desde Fecha:" OF oForm PIXEL SIZE 60,12 RIGHT
   @ 35, 01 SAY "Hasta Fecha:" OF oForm PIXEL SIZE 60,12 RIGHT
   //@ 50, 01 SAY "Limite:"      OF oForm PIXEL SIZE 60,12 RIGHT
   @ 05, 70 GET oGet[1] VAR mcodemp   PICTURE "999999" OF oForm PIXEL RIGHT SIZE 40,10;
     VALID(buscar(oQryEmp, oForm, oGet[1], oGet[2])) ;
     ACTION (oGet[1]:cText := 0,buscar(oQryEmp, oForm, oGet[1], oGet[2])) BITMAP "BUSC1"
   @ 05,115 GET oGet[2] VAR mnomemp OF oForm PIXEL WHEN(.f.) SIZE 80,10 
   @ 20, 70 GET oGet[3] VAR mdesde PICTURE "@D" OF oForm PIXEL CENTER
   @ 35, 70 GET oGet[4] VAR mhasta PICTURE "@D" OF oForm PIXEL CENTER
   //@ 35,140 CHECKBOX oGet[5] VAR lSinValor PROMPT "Sin Valores" SIZE 50,12 OF oForm PIXEL
   //IF oApp:lEstado
   //   @ 20,115 COMBOBOX oGet[6] VAR nTipo ITEMS aTipo PIXEL SIZE 50,12
   //ENDIF
   //@ 50, 70 GET oGet[7] VAR mlimite   PICTURE "99" OF oForm PIXEL RIGHT VALID(mlimite >0 .and. mlimite<32)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oForm SIZE 30,10 ACTION ((mrta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oForm SIZE 30,10 ACTION ((mrta := .f.), oForm:End() ) PIXEL CANCEL 
ACTIVATE DIALOG oForm CENTER 
IF !mrta   
   RETURN
ENDIF
mRta := oApp:oServer:Query("( SELECT 1 FROM Information_schema.Routines WHERE specific_name = 'horas' "+;
                            " AND Routine_schema = '"+ALLTRIM(oApp:oServer:cDBName)+"'"+;
                            " AND Routine_Type = 'FUNCTION' )"):nRecCount
IF mRta = 0
    TEXT INTO cSql 

        CREATE FUNCTION `horas`(fecha DATE, hora1 VARCHAR(8),hora2 VARCHAR(8),
                                              hora3 VARCHAR(8),hora4 VARCHAR(8),hora5 VARCHAR(8),
                      hora6 VARCHAR(8)) RETURNS DECIMAL(7,2)
        BEGIN
          DECLARE horasT DECIMAL(7,2) DEFAULT 0;
          IF hora1 <> ' ' AND hora2 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora1),  CONCAT(fecha,' ',hora2) );
          END IF;
          IF hora3 <> ' ' AND hora4 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora3),  CONCAT(fecha,' ',hora4) );
          END IF;
          IF hora5 <> ' ' AND hora6 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora5),  CONCAT(fecha,' ',hora6) );
          END IF;
          SET horasT = horasT / 60 ; 
          RETURN horasT;
          END 
        ENDTEXT 

    oApp:oServer:Execute(cSql)
ENDIF    
mRta := oApp:oServer:Query("( SELECT 1 FROM Information_schema.Routines WHERE specific_name = 'horasE' "+;
                            " AND Routine_schema = '"+ALLTRIM(oApp:oServer:cDBName)+"'"+;
                            " AND Routine_Type = 'FUNCTION' )"):nRecCount
IF mRta = 0
    TEXT INTO cSql 
        CREATE FUNCTION `horasE`(fecha DATE, hora1 VARCHAR(8),hora2 VARCHAR(8),hora3 VARCHAR(8),
                                              hora4 VARCHAR(8),hora5 VARCHAR(8),
                                              hora6 VARCHAR(8), maxhor INT(2)) RETURNS DECIMAL(7,2)
        BEGIN
          DECLARE horasT DECIMAL(7,2) DEFAULT 0;
          IF hora1 <> ' ' AND hora2 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora1),  CONCAT(fecha,' ',hora2) );
          END IF;
          IF hora3 <> ' ' AND hora4 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora3),  CONCAT(fecha,' ',hora4) );
          END IF;
          IF hora5 <> ' ' AND hora5 <> ' ' THEN
              SET horasT  = horasT + TIMESTAMPDIFF(MINUTE,CONCAT(fecha,' ',hora5),  CONCAT(fecha,' ',hora6) );
          END IF;
          SET horasT = horasT / 60 ;
          IF horasT > maxhor THEN
              SET horasT = horasT - maxhor;
              ELSE
              SET horasT = horasT - maxhor;
          END IF;
          RETURN horasT;
        END

    ENDTEXT 

    oApp:oServer:Execute(cSql)
ENDIF

oQry := oApp:oServer:Query("SELECT * FROM ("+;
                           "(SELECT h.codtar as legajo, h.fecha, h.hora1ent,h.hora1sal,"+;
                           " h.hora2ent,h.hora2sal, h.hora3ent,h.hora3sal,"+;
                           "horas(h.fecha,h.hora1ent,h.hora1sal,h.hora2ent,h.hora2sal, h.hora3ent,h.hora3sal) as horastra,"+;
                           "horasE(h.fecha,h.hora1ent,h.hora1sal,h.hora2ent,h.hora2sal, h.hora3ent,h.hora3sal,s.horas) as horasExt,"+;
                           "cat.valorhora as importe,"+;
                           "'' as obs, s.horas as horas "+;
                           "FROM ge_"+oApp:cId+"emp_horas h "+;
                           "LEFT JOIN ge_"+oApp:cId+"emp_empleado m ON m.codigo  = h.codtar "+;                           
                           "LEFT JOIN ge_"+oApp:cId+"emp_emplcat cat ON cat.codigo  = m.catego "+;
                           "LEFT JOIN ge_"+oApp:cId+"emp_sector  s   ON s.codigo  = m.sector "+;
                           "WHERE h.fecha >= "+ClipValue2Sql(mdesde)+" AND h.fecha <= "+ClipValue2Sql(mhasta)+" AND "+;
                           "      h.codtar = "+ClipValue2Sql(mcodemp)+ ") "+;
                           "UNION "+;
                           "(SELECT i.legajo as legajo, i.fecinasi as fecha, '00:00:00' as hora1ent,'00:00:00' as hora1sal,"+;
                           " '00:00:00' as hora2ent,'00:00:00' as hora2sal, '00:00:00' as hora3ent,'00:00:00' as hora3sal,"+;
                           " 0 as horastra, 0 as horasExt, 0 as importe, "+;
                           " c.nombre as obs, 0 as horas "+;
                           "FROM ge_"+oApp:cId+"emp_inasi i "+;
                           "LEFT JOIN ge_"+oApp:cId+"emp_inasistencia c ON c.codigo  = i.codigo "+;                           
                           "WHERE i.fecinasi >= "+ClipValue2Sql(mdesde)+" AND i.fecinasi <= "+ClipValue2Sql(mhasta)+" AND "+;
                           "      i.legajo = "+ClipValue2Sql(mcodemp)+ ") "+;
                           "UNION "+;
                           "(SELECT ps.codemp as legajo, ps.fecha as fecha, '00:00:00' as hora1ent,'00:00:00' as hora1sal,"+;
                           " '00:00:00' as hora2ent,'00:00:00' as hora2sal, '00:00:00' as hora3ent,'00:00:00' as hora3sal,"+;
                           " 0 as horastra, 0 as horasExt, -importe as importe, "+;
                           " ps.observa as obs, 0 as horas "+;
                           "FROM ge_"+oApp:cId+"emp_pagsueldo ps "+;                           
                           "WHERE ps.fecha >= "+ClipValue2Sql(mdesde)+" AND ps.fecha <= "+ClipValue2Sql(mhasta)+" AND "+;
                           "      ps.codemp = "+ClipValue2Sql(mcodemp)+ " ) "+;
                           ") res "+;
                           "ORDER BY res.fecha")

oQry:GoTop()
REPORT oRep TITLE "Detalle de horas de " + mnomemp + " Legajo:" + STR(mcodemp,6) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Fichadas " + DTOC(mdesde) + " al "  + DTOC(mhasta),;
       "Horario Habitual: " + oQryEmp:hor_hab_desde1+" "+oQryEmp:hor_hab_hasta1+" "+;
                              IF(oQryEmp:hor_hab_desde2<> '00:00:00',oQryEmp:hor_hab_desde2+" "+oQryEmp:hor_hab_hasta2,"") CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) + ;
              "  Firma responsable operativo:_______________________" + ;
              "  Firma responsable area:____________________________" CENTER;
       PREVIEW CAPTION  "Detalle de horas"
       COLUMN TITLE "Dia"     DATA CDOW(oQry:fecha) SIZE 8  FONT 1        
       COLUMN TITLE "Fecha"   DATA oQry:fecha       SIZE 08 FONT 1 CENTER PICTURE "@D"
       COLUMN TITLE "Entrada" DATA oQry:hora1ent  SIZE 08 FONT 1 PICTURE "99:99:99"
       COLUMN TITLE "Salida"  DATA oQry:hora1sal  SIZE 08 FONT 1 PICTURE "99:99:99"
       COLUMN TITLE "Entrada" DATA oQry:hora2ent  SIZE 08 FONT 1 PICTURE "99:99:99" 
       COLUMN TITLE "Salida"  DATA oQry:hora2sal  SIZE 08 FONT 1 PICTURE "99:99:99"
       COLUMN TITLE "Entrada" DATA oQry:hora3Ent    SIZE 08 FONT 1 PICTURE "99:99:99"
       COLUMN TITLE "Salida"  DATA oQry:hora3Sal    SIZE 08 FONT 1 PICTURE "99:99:99"
       COLUMN TITLE "Hs. Trab."      DATA oQry:horastra PICTURE "999.99" SIZE 06 FONT 1 RIGHT TOTAL
       COLUMN TITLE "Extras"         DATA oQry:horasExt PICTURE "999.99" SIZE 06 FONT 1 RIGHT TOTAL       
       COLUMN TITLE "Observaciones"  DATA oQry:obs    SIZE 25 FONT 1 
       

END REPORT
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop()}
oRep:bSkip := {|| oQry:Skip() }

ACTIVATE REPORT oRep WHILE !oQry:Eof();
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",1.5,.5)
oQry:End()
RETURN

STATIC FUNCTION HorasVar(nDia,cHora,nTipo,mlimite,cHoraFija,cObs,nDow)
LOCAL nSec := TimeToSec(cHoraFija) +  HB_Random( -100, 100 )
IF !EMPTY(cObs)
   RETURN cHora
ENDIF
IF nDow = 1 .or. nDow = 7
   RETURN cHora
ENDIF
IF nTipo = 1 .and. nDia < mlimite
   cHoraFija := SecToTime(nSec)
   cHora := cHoraFija
ENDIF
IF nTipo = 2 .and. nDia >= mlimite
   cHoraFija := SecToTime(nSec)
   cHora := cHoraFija
ENDIF
RETURN cHora


***********************************
** Fichadas por Sector
PROCEDURE RepSuel3()
LOCAL oGet := ARRAY(6), mdesde := DATE(), mhasta := DATE(), oForm,;
      mcodemp := 0, mnomemp := SPACE(30), aCor, mrta := .f., oBot1, oBot2,;
      oQryDep, oQry, oRep, oFont1, oFont2, oFont3,nTipo:=2,mlimite := 0
oQryDep := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_sector")      
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oForm TITLE "Detalle de fichadas por Sector" FROM 03,15 TO 14,75 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oForm)
   @ 05, 01 SAY "Sector:"       OF oForm PIXEL SIZE 60,12 RIGHT
   @ 20, 01 SAY "Desde Fecha:" OF oForm PIXEL SIZE 60,12 RIGHT
   @ 35, 01 SAY "Hasta Fecha:" OF oForm PIXEL SIZE 60,12 RIGHT
   *@ 50, 01 SAY "Limite:"      OF oForm PIXEL SIZE 60,12 RIGHT
   @ 05, 70 GET oGet[1] VAR mcodemp   PICTURE "999999" OF oForm PIXEL RIGHT SIZE 40,10;
     VALID(Buscar(oQryDep,oForm,oGet[1],oGet[2]));
              ACTION (oGet[1]:cText:= 0,Buscar(oQryDep,oForm,oGet[1],oGet[2])) BITMAP "BUSC1"  
   @ 05,115 GET oGet[2] VAR mnomemp OF oForm PIXEL WHEN(.f.) SIZE 80,10 
   @ 20, 70 GET oGet[3] VAR mdesde PICTURE "@D" OF oForm PIXEL CENTER
   @ 35, 70 GET oGet[4] VAR mhasta PICTURE "@D" OF oForm PIXEL CENTER   
   *@ 50, 70 GET oGet[6] VAR mlimite PICTURE "99" OF oForm PIXEL CENTER RIGHT
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oForm SIZE 30,10 ACTION ((mrta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oForm SIZE 30,10 ACTION ((mrta := .f.), oForm:End() ) PIXEL CANCEL 
ACTIVATE DIALOG oForm CENTER 
IF !mrta   
   RETURN
ENDIF
oQry := oApp:oServer:Query(+;
"SELECT res.codigo, res.nombre, SUM(res.horastra) as horastra,SUM(res.extras) as extras FROM ( "+; 
"SELECT e.codigo, e.nombre,  "+;
"horas(h.fecha,h.hora1ent,h.hora1sal,h.hora2ent,h.hora2sal, h.hora3ent,h.hora3sal) as horastra,"+;
"horasE(h.fecha,h.hora1ent,h.hora1sal,h.hora2ent,h.hora2sal, h.hora3ent,h.hora3sal,s.horas)  AS extras "+;
"FROM ge_"+oApp:cId+"emp_horas h  "+;
"LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON e.codigo = h.codtar  "+;
"LEFT JOIN ge_"+oApp:cId+"emp_emplcat cat ON cat.codigo  = e.catego "+;
"LEFT JOIN ge_"+oApp:cId+"emp_sector s ON s.codigo  = e.sector "+;
"WHERE h.fecha >= "+ClipValue2Sql(mdesde)+" AND h.fecha <= "+ClipValue2Sql(mhasta)+" "+;
" AND  e.sector =  "+ClipValue2Sql(mcodemp)+;
" ) res "+;
"GROUP BY res.codigo ")
IF oQry:nRecCount = 0
   MsgInfo("Sin fichadas para mostrar")   
   RETURN
ENDIF
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10
REPORT oRep TITLE "Detalle de horas sector " + STR(mcodemp,4)+ " " + mnomemp;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Fichadas " + DTOC(mdesde) + " al " + DTOC(mhasta) CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Resumen de horas"
       COLUMN TITLE "Legajo"   DATA oQry:codigo SIZE 08 FONT 1
       COLUMN TITLE "Nombre"   DATA oQry:nombre SIZE 30 FONT 1
       COLUMN TITLE "Trabajadas" DATA oQry:horastra SIZE 10 FONT 1 PICTURE "9999.99" TOTAL
       COLUMN TITLE "Extras"   DATA oQry:extras SIZE 10 FONT 1 PICTURE "9999.99" TOTAL
       //COLUMN TITLE "Importe"  DATA oQry:importe*oQry:extras SIZE 10 FONT 1 PICTURE "9999999.99" TOTAL
       //COLUMN TITLE "Antici."  DATA oQry:anti                SIZE 10 FONT 1 PICTURE "9999999.99" TOTAL
END REPORT
// Activo el reporte
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
ACTIVATE REPORT oRep WHILE !oQry:Eof() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",1.5,.5)
// Cierro los archivos
oQry:End()
RETURN

***************************************
** Calculo de horas transcurridas entre
** dos horas dadas
STATIC FUNCTION HorasTra(mhora1,mhora2)
LOCAL mh1, mh2, mm1, mm2, mh
IF EMPTY(mhora1) .OR. EMPTY(mhora2) .or. mhora1 ="  :  :  " .or. mhora2 ="  :  :  " .or.;
   mhora1 =":  :  " .or. mhora2 = ":  :  "
   RETURN 0
ENDIF

mh2 := VAL(LEFT(mhora1,2))
mh1 := VAL(LEFT(mhora2,2))
mm2 := VAL(SUBSTR(mhora1,4,2))
mm1 := VAL(SUBSTR(mhora2,4,2))
IF mh1 = mh2
   IF mm1 < mm2
      RETURN 0
   ENDIF
   IF mm1 = mm2
      RETURN 0
   ENDIF
   RETURN (mm1 - mm2) / 60
ENDIF
IF mh1 > mh2
   mh := mh1 - mh2
   IF mm1 <= mm2
      mh := mh - 1
      mh := mh + (mm1 + 60 - mm2) / 60
      RETURN mh
   ENDIF
ENDIF
mh := (mh1 + mm1 / 60)  - (mh2 + mm2 / 60)
RETURN mh



*************************************************************************
*** Inasistencias por mes
PROCEDURE RepSuel4()
LOCAL oRep, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f.,;
      mdesde := DATE(), mhasta := DATE()+30, mlegajo := 0, mdepto := 0, mcodigo := 0, oQry
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Planilla mensual de inasistencias" FROM 03,15 TO 16,65 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 37, 01 SAY "Empleado (0:Todos):" OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 52, 01 SAY "Sector (0:Todos):"   OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 67, 01 SAY "Motivo (0:Todos):"   OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL   
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL   
   @ 35, 70 GET oGet[3] VAR mlegajo   OF oDlg1 PIXEL PICTURE "99999999" RIGHT
   @ 50, 70 GET oGet[4] VAR mdepto    OF oDlg1 PIXEL PICTURE "9999"     RIGHT
   @ 65, 70 GET oGet[5] VAR mcodigo   OF oDlg1 PIXEL PICTURE "9999"     RIGHT
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
oQry := oApp:oServer:Query("SELECT mo.fecinasi AS fecha, mo.legajo AS legajo, ma.nombre AS nombre, mo.codigo AS codigo, "+;
                           " CONCAT(RTRIM(co.nombre),' (',RTRIM(co.observa),')')  AS nomcod, de.nombre AS depto "+;                           
                           " FROM ge_"+oApp:cId+"emp_inasi mo "+;
                           " LEFT JOIN ge_"+oApp:cId+"emp_empleado ma ON mo.legajo = ma.codigo "+;
                           " LEFT JOIN ge_"+oApp:cId+"emp_inasistencia co ON mo.codigo = co.codigo "+;
                           " LEFT JOIN ge_"+oApp:cId+"emp_sector     de ON ma.sector = de.codigo "+;
                           " WHERE mo.fecinasi >= "+ClipValue2Sql(mdesde) + ;
                           " AND   mo.fecinasi <= "+ClipValue2Sql(mhasta) + ;
                           " AND   "+IF(mlegajo=0," TRUE "," mo.legajo = "+ClipValue2Sql(mlegajo) )+ ;
                           " AND   "+IF(mcodigo=0," TRUE "," mo.codigo = "+ClipValue2Sql(mcodigo) )+ ;
                           " AND   "+IF(mdepto =0," TRUE "," ma.sector = "+ClipValue2Sql(mdepto) ) + ;
                           " ORDER BY mo.legajo" )
REPORT oRep TITLE "Inasistencias desde el " + DTOC(mdesde) + " al " + DTOC(mhasta);
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Inasistencias Mensuales"

COLUMN TITLE "Legajo"    DATA oQry:legajo      PICTURE "9999999"     SIZE 08 FONT 1
COLUMN TITLE "Empleado"  DATA oQry:nombre      PICTURE "@!"          SIZE 25 FONT 1
COLUMN TITLE "Fecha"     DATA oQry:fecha       PICTURE "@D"          SIZE 08 FONT 1
COLUMN TITLE "Codigo"    DATA oQry:codigo      PICTURE "9999"        SIZE 08 FONT 1 
COLUMN TITLE "Motivo"    DATA oQry:nomcod      PICTURE "@!"          SIZE 25 FONT 1 
COLUMN TITLE "Depto"     DATA oQry:depto       PICTURE "@!"          SIZE 20 FONT 1 
       
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
// Cierro los archivos
oQry:End()
RETURN

*************************************************************************
*** Planilla anual por empleado
PROCEDURE RepSuel5()
LOCAL oRep, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f.,;
      mano := YEAR(DATE()), mlegajo := 0, mnombre := SPACE(30), oQry, oQryEmp
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-11.5
oQryEmp := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"emp_empleado")
DEFINE DIALOG oDlg1 TITLE "Planilla anual por empleado" FROM 03,15 TO 12,75 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Año:"                OF oDlg1 PIXEL SIZE 50,12 RIGHT   
   @ 22, 01 SAY "Empleado:"           OF oDlg1 PIXEL SIZE 50,12 RIGHT   
   @ 05, 55 GET oGet[1] VAR mano      OF oDlg1 PIXEL   
   @ 20, 55 GET oGet[2] VAR mlegajo   OF oDlg1 PIXEL PICTURE "99999999" RIGHT SIZE 35,12;
     VALID(buscar(oQryEmp, oDlg1,  oGet[2], oGet[3]));
     ACTION (oGet[2]:cText := 0,buscar(oQryEmp, oDlg1,  oGet[2], oGet[3])) BITMAP "BUSC1"
   @ 20,95 GET oGet[3] VAR mnombre   OF oDlg1 PIXEL WHEN(.F.)   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
oQry := oApp:oServer:Query(;
  "SELECT CODIGO, NOMBRE, SUM(ENERO) AS ENE ,SUM(FEB) AS FEB, SUM(MARZ) AS MAR , SUM(ABRIL) AS ABR ,SUM(MAYO) AS MAY ,SUM(JUNIO) AS JUN "+;
        ", SUM(JULIO) AS JUL , SUM(AGOST) AS AGO, SUM(SEPT) AS SEP, SUM(OCTU) AS OCT,SUM(NOV) AS NOV,SUM(DIC) AS DIC "+;
        "FROM ( "+;
"SELECT C.CODIGO, C.NOMBRE, COUNT(LEGAJO) AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , "+;
"0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC " +;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 1 GROUP BY C.CODIGO, C.NOMBRE UNION ALL "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,COUNT(LEGAJO) AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 2 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , COUNT(LEGAJO) AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 3 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , COUNT(LEGAJO) AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 4 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , COUNT(LEGAJO) AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 5 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , COUNT(LEGAJO) AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 6 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , COUNT(LEGAJO) AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 7 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , COUNT(LEGAJO) AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 8 GROUP BY C.CODIGO, C.NOMBRE  UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , COUNT(LEGAJO) AS SEPT,   0 AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 9 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,  COUNT(LEGAJO) AS OCTU, 0 AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 10 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, COUNT(LEGAJO) AS NOV, 0 AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 11 GROUP BY C.CODIGO, C.NOMBRE UNION ALL  "+;
"SELECT C.CODIGO, C.NOMBRE, 0 AS ENERO ,0 AS FEB , 0 AS MARZ , 0 AS ABRIL , 0 AS MAYO , 0 AS JUNIO , 0 AS JULIO , 0 AS AGOST , 0 AS SEPT,   0 AS OCTU, 0 AS NOV, COUNT(LEGAJO) AS DIC "+;
"FROM `ge_"+oApp:cId+"emp_inasi` m LEFT OUTER JOIN ge_"+oApp:cId+"emp_inasistencia C ON C.CODIGO = m.CODIGO WHERE YEAR(m.fecinasi) = " + ClipValue2SQL(mano) + " AND m.LEGAJO = " + ClipValue2SQL(mlegajo) + " AND MONTH(m.FECINASI) = 12 GROUP BY C.CODIGO, C.NOMBRE  "+;
") V "+;
"GROUP BY CODIGO, NOMBRE")
REPORT oRep TITLE "Inasistencias de " + STR(mlegajo,8)+ " " + ALLTRIM(mnombre) + " del Año " + STR(mano,4);
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Inasistencias Anuales"

COLUMN TITLE "Cod."      DATA oQry:codigo      PICTURE "9999"        SIZE 04 FONT 1
COLUMN TITLE "Motivo"    DATA oQry:nombre      PICTURE "@!"          SIZE 25 FONT 1
COLUMN TITLE "Ene"       DATA oQry:ene         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Feb"       DATA oQry:feb         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Mar"       DATA oQry:mar         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Abr"       DATA oQry:abr         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "May"       DATA oQry:may         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Jun"       DATA oQry:jun         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Jul"       DATA oQry:jul         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Ago"       DATA oQry:ago         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Sep"       DATA oQry:sep         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Oct"       DATA oQry:oct         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Nov"       DATA oQry:nov         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Dic"       DATA oQry:dic         PICTURE "999"         SIZE 03 FONT 1 TOTAL
COLUMN TITLE "Tot"       DATA oQry:ene+oQry:feb+oQry:mar+oQry:abr+oQry:may+oQry:jun+;
                              oQry:jul+oQry:ago+oQry:sep+oQry:oct+oQry:nov+oQry:dic;
                                               PICTURE "999"         SIZE 03 FONT 1 TOTAL
       
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
// Cierro los archivos
oQry:End()
RETURN

*************************************************************************
*** Inasistencias por CODIGO
PROCEDURE RepSuel6()
LOCAL oRep, oGru, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f.,;
      mdesde := DATE(), mhasta := DATE()+30, mlegajo := 0, mdepto := 0, mcodigo := 0, oQry, oQryCod, mnombre := SPACE(30)
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-10
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-10 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-11.5
oQryCod := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasistencia")     
DEFINE DIALOG oDlg1 TITLE "Planilla por codigo" FROM 03,15 TO 16,65 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 37, 01 SAY "Sector (0:Todos):"   OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 52, 01 SAY "Codigo:"             OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL   
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL      
   @ 35, 70 GET oGet[4] VAR mdepto    OF oDlg1 PIXEL PICTURE "9999"     RIGHT
   @ 50, 70 GET oGet[5] VAR mcodigo   OF oDlg1 PIXEL PICTURE "9999"     RIGHT;
   VALID(buscar(oQryCod, oDlg1, oGet[5], oGet[6]));
     ACTION (oGet[5]:cText := 0,buscar(oQryCod, oDlg1, oGet[5], oGet[6])) BITMAP "BUSC1" SIZE 30,12
   @ 50,105 GET oGet[6] VAR mnombre   OF oDlg1 PIXEL WHEN(.F.)   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
oQry := oApp:oServer:Query("SELECT COUNT(mo.fecinasi) AS cant, mo.legajo AS legajo, ma.nombre AS nombre, de.nombre AS depnom "+;                           
                           " FROM ge_"+oApp:cId+"emp_inasi mo "+;
                           " LEFT JOIN ge_"+oApp:cId+"emp_empleado ma ON mo.legajo = ma.codigo "+;                           
                           " LEFT JOIN ge_"+oApp:cId+"emp_sector   de ON ma.sector  = de.codigo "+;
                           " WHERE mo.fecinasi >= "+ClipValue2Sql(mdesde) + ;
                           " AND   mo.fecinasi <= "+ClipValue2Sql(mhasta) + ;                           
                           " AND   mo.codigo = "+ClipValue2Sql(mcodigo) + ;
                           " AND   "+IF(mdepto =0," TRUE "," ma.sector  = "+ClipValue2Sql(mdepto) ) + ;
                           " GROUP BY mo.legajo, mo.codigo "+;
                           " ORDER BY de.nombre, ma.nombre" )
REPORT oRep TITLE "Inasistencias por "+ALLTRIM(mnombre)+" del " + DTOC(mdesde) + " al " + DTOC(mhasta);
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Inasistencias por codigo"
IF mdepto = 0
   GROUP oGru ON oQry:depnom HEADER oQry:depnom FOOTER "Totales"
ENDIF   
COLUMN TITLE "Legajo"    DATA oQry:legajo      PICTURE "9999999"     SIZE 08 FONT 1
COLUMN TITLE "Empleado"  DATA oQry:nombre      PICTURE "@!"          SIZE 25 FONT 1
COLUMN TITLE "Cantidad"  DATA oQry:cant        PICTURE "9999"        SIZE 10 FONT 1 TOTAL
IF mdepto <> 0
COLUMN TITLE "Depto"     DATA oQry:depnom      PICTURE "@!"          SIZE 25 FONT 1
ENDIF
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
// Cierro los archivos
oQry:End()
RETURN

*************************************************************************
*** Listado de pagos            
PROCEDURE RepSuel7()
LOCAL oRep, oGru, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f.,;
      mdesde := DATE(), mhasta := DATE()+30, mlegajo := 0, manti := "N", mcodigo := 0, oQry, oQryCod,;
      mnombre := SPACE(30), nRecibo := 0, lReim := .f., mmes := 0, mano := 0, lMostraLiq := .f.
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-10
oQryCod := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado")     
DEFINE DIALOG oDlg1 TITLE "Planilla de pagos a empleados" FROM 03,15 TO 18,65 OF oApp:oWnd 
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT     
   @ 37, 01 SAY "Empleado(0:Todos)"   OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 52, 01 SAY "Mostrar solo periodo:" OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL   
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL      
   @ 35, 70 GET oGet[5] VAR mcodigo   OF oDlg1 PIXEL PICTURE "9999"     RIGHT;
   VALID(mcodigo = 0 .or. buscar(oQryCod, oDlg1, oGet[5], oGet[6]));
     ACTION (oGet[5]:cText := -1,buscar(oQryCod, oDlg1, oGet[5], oGet[6])) BITMAP "BUSC1" SIZE 30,12
   @ 35,105 GET oGet[6] VAR mnombre   OF oDlg1 PIXEL WHEN(.F.)   
   @ 50, 70 GET oGet[7] VAR mmes      OF oDlg1 PIXEL PICTURE "99"     RIGHT
   @ 50, 90 GET oGet[8] VAR mano      OF oDlg1 PIXEL PICTURE "9999"   RIGHT
   @ 65, 95 CHECKBOX oGet[9] VAR lMostraLiq PROMPT "Incluir Liquidaciones" OF oDlg1 PIXEL SIZE 70,10 
   @ 80, 95 CHECKBOX oGet[4] VAR lReim PROMPT "Reimprime Rec Nro" OF oDlg1 PIXEL SIZE 70,10 
   @ 80, 60 GET oGet[3] VAR nRecibo OF oDlg1 PIXEL PICTURE "99999999" RIGHT WHEN(lReim)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
IF lReim
   ReciPago(nRecibo)
   RETURN 
ENDIF
IF !lMostraLiq
    oQry := oApp:oServer:Query("SELECT ps.*, e.nombre  "+;                           
                               " FROM ge_"+oApp:cId+"emp_pagsueldo ps "+;
                               " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON ps.codemp = e.codigo "+;                                                      
                               " WHERE ps.fecha    >= "+ClipValue2Sql(mdesde) + ;
                               " AND   ps.fecha    <= "+ClipValue2Sql(mhasta) + ;                                                      
                               " AND   "+IF(manti ="N"," TRUE "," TRUE   ")+ ;
                               " AND   "+IF(mcodigo =0," TRUE "," ps.codemp  = "+ClipValue2Sql(mcodigo) ) + ;
                               " AND   "+IF(mmes =0 ," TRUE "," ps.mes  = "+ClipValue2Sql(mmes) ) + ;
                               " AND   "+IF(mano =0 ," TRUE "," ps.ano  = "+ClipValue2Sql(mano) ) + ;
                               " ORDER BY e.nombre, ps.fecha" )
    REPORT oRep TITLE "Pagos de sueldo del " + DTOC(mdesde) + " al " + DTOC(mhasta);
           FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Pagos de sueldo"
    GROUP oGru ON oQry:nombre HEADER oQry:nombre FOOTER "Totales"

    COLUMN TITLE "Legajo"    DATA oQry:codemp      PICTURE "9999999"     SIZE 08 FONT 1
    COLUMN TITLE "Recibo"    DATA oQry:numero      PICTURE "9999999"     SIZE 08 FONT 1
    COLUMN TITLE "Fecha Pag" DATA oQry:fecha       PICTURE "@D"          SIZE 08 FONT 1
    COLUMN TITLE "Concepto"  DATA oQry:observa     PICTURE "@!"          SIZE 28 FONT 1
    COLUMN TITLE "Mes"       DATA oQry:mes         PICTURE "99"          SIZE 02 FONT 1 
    COLUMN TITLE "Año"       DATA oQry:ano         PICTURE "9999"        SIZE 04 FONT 1 
    COLUMN TITLE "Importe"   DATA oQry:importe     PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL
    COLUMN TITLE "Usuario"   DATA oQry:usuario     PICTURE "@!"          SIZE 10 FONT 1 
    COLUMN TITLE "F.Pago"    DATA IF(oQry:tipo=1,"Efect.","Transf.")     PICTURE "@!"  SIZE 07 FONT 1 


    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }
    END REPORT
    // Activo el reporte
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
    // Cierro los archivos
    oQry:End()
    ELSE 
    oQry := oApp:oServer:Query("SELECT * FROM ("+;
                               " SELECT ps.codemp,ps.numero,ps.fecha,ps.observa, ps.mes,ps.ano,ps.importe,ps.usuario,ps.tipo, e.nombre, 1 as impu  "+;                           
                               " FROM ge_"+oApp:cId+"emp_pagsueldo ps "+;
                               " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON ps.codemp = e.codigo "+;                                                      
                               " WHERE ps.fecha    >= "+ClipValue2Sql(mdesde) + ;
                               " AND   ps.fecha    <= "+ClipValue2Sql(mhasta) + ;                                                      
                               " AND   "+IF(manti ="N"," TRUE "," TRUE   ")+ ;
                               " AND   "+IF(mcodigo =0," TRUE "," ps.codemp  = "+ClipValue2Sql(mcodigo) ) + ;
                               " AND   "+IF(mmes =0 ," TRUE "," ps.mes  = "+ClipValue2Sql(mmes) ) + ;
                               " AND   "+IF(mano =0 ," TRUE "," ps.ano  = "+ClipValue2Sql(mano) ) + ;
                               " UNION ALL "+;
                               " SELECT ps.codemp,ps.numero,ps.fecha,ps.observa, ps.mes,ps.ano,ps.total as importe,ps.usuario,0 as tipo,e.nombre, 2 as impu  "+;                           
                               " FROM ge_"+oApp:cId+"emp_liqsueldo ps "+;
                               " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON ps.codemp = e.codigo "+;                                                      
                               " WHERE ps.fecha    >= "+ClipValue2Sql(mdesde) + ;
                               " AND   ps.fecha    <= "+ClipValue2Sql(mhasta) + ;                                                      
                               " AND   "+IF(manti ="N"," TRUE "," TRUE   ")+ ;
                               " AND   "+IF(mcodigo =0," TRUE "," ps.codemp  = "+ClipValue2Sql(mcodigo) ) + ;
                               " AND   "+IF(mmes =0 ," TRUE "," ps.mes  = "+ClipValue2Sql(mmes) ) + ;
                               " AND   "+IF(mano =0 ," TRUE "," ps.ano  = "+ClipValue2Sql(mano) ) + ;
                               " ) res ORDER BY res.nombre, res.fecha, res.tipo" )
    REPORT oRep TITLE "Liquidaciones y Pagos de sueldo del " + DTOC(mdesde) + " al " + DTOC(mhasta);
           FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Pagos de sueldo"
    GROUP oGru ON oQry:nombre HEADER oQry:nombre FOOTER "Totales"
    COLUMN TITLE "Tipo"      DATA IF(oQry:tipo = 0,"Liquidacion","Pago") SIZE 10 FONT 1
    COLUMN TITLE "Legajo"    DATA oQry:codemp      PICTURE "9999999"     SIZE 08 FONT 1
    COLUMN TITLE "Recibo"    DATA oQry:numero      PICTURE "9999999"     SIZE 08 FONT 1
    COLUMN TITLE "Fecha Pag" DATA oQry:fecha       PICTURE "@D"          SIZE 08 FONT 1
    COLUMN TITLE "Concepto"  DATA oQry:observa     PICTURE "@!"          SIZE 28 FONT 1
    COLUMN TITLE "Mes"       DATA oQry:mes         PICTURE "99"          SIZE 02 FONT 1 
    COLUMN TITLE "Año"       DATA oQry:ano         PICTURE "9999"        SIZE 04 FONT 1 
    COLUMN TITLE "Importe"   DATA IF(oQry:impu = 1, -1,1) * oQry:importe     PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL
    COLUMN TITLE "Usuario"   DATA oQry:usuario     PICTURE "@!"          SIZE 10 FONT 1 
    COLUMN TITLE "F.Pago"    DATA IF(oQry:tipo=1,"Efect.",IF(oQry:tipo=2,"Transf."," "))     PICTURE "@!"  SIZE 07 FONT 1 


    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }
    END REPORT
    // Activo el reporte
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1)
    // Cierro los archivos
    oQry:End()
ENDIF    
RETURN


*************************************************************************
*** Listado de consumo interno
PROCEDURE RepSuel8()
LOCAL oRep, oGru, oFont1, oFont2, oFont3, acor, oDlg1, oGet := ARRAY(10), oBot := ARRAY(2), mrta := .f.,;
      mdesde := DATE(), mhasta := DATE()+30, mlegajo := 0, manti := "N", mcodigo := 0, oQry, oQryCod,;
      mnombre := SPACE(30), nRecibo := 0,  lAgrupa := .f.
// Defino los distintos tipos de letra
     DEFINE FONT oFont1 NAME "ARIAL"  SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL"  SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "TAHOMA" SIZE 0,-10
oQryCod := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado")     
DEFINE DIALOG oDlg1 TITLE "Consumo interno de empleados" FROM 03,15 TO 14,65 OF oApp:oWnd FONT oFont3
   acor := AcepCanc(oDlg1)
   @ 07, 01 SAY "Desde Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 22, 01 SAY "Hasta Fecha:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT     
   @ 37, 01 SAY "Empleado(0:Todos)"   OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL   
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL      
   @ 35, 70 GET oGet[5] VAR mcodigo   OF oDlg1 PIXEL PICTURE "9999"     RIGHT;
   VALID(mcodigo = 0 .or. buscar(oQryCod, oDlg1, oGet[5], oGet[6]));
     ACTION (oGet[5]:cText := -1,buscar(oQryCod, oDlg1, oGet[5], oGet[6])) BITMAP "BUSC1" SIZE 30,12
   @ 35,105 GET oGet[6] VAR mnombre   OF oDlg1 PIXEL WHEN(.F.)    
   @ 05,115 CHECKBOX oGet[4] VAR lAgrupa PROMPT "Agrupa por producto" OF oDlg1 PIXEL SIZE 60,10   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN
ENDIF
IF !lAgrupa
  oQry := oApp:oServer:Query("SELECT c.*, e.nombre  "+;                           
                             " FROM ge_"+oApp:cId+"emp_consumoint c "+;
                             " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON c.codemp = e.codigo "+;                                                      
                             " WHERE c.fecha    >= "+ClipValue2Sql(mdesde) + ;
                             " AND   c.fecha    <= "+ClipValue2Sql(mhasta) + ;                                                                                 
                             " AND   "+IF(mcodigo =0," TRUE "," c.codemp  = "+ClipValue2Sql(mcodigo) ) + ;
                             " ORDER BY e.nombre, c.fecha" )
  IF oQry:nRecCount = 0
     MsgInfo("Sin datos para listar","Atencion")
     RETURN  
  ENDIF   
  REPORT oRep TITLE "Consumo Interno " + DTOC(mdesde) + " al " + DTOC(mhasta);
         FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Consumo Interno"
  GROUP oGru ON oQry:nombre HEADER oQry:nombre FOOTER "Totales"

  COLUMN TITLE "Legajo"    DATA oQry:codemp      PICTURE "9999999"     SIZE 08 FONT 1
  COLUMN TITLE "Producto"  DATA oQry:codart      PICTURE "9999999"     SIZE 08 FONT 1
  COLUMN TITLE "Detalle"   DATA oQry:nomart      PICTURE "@!"          SIZE 20 FONT 1
  COLUMN TITLE "Fecha"     DATA oQry:fecha       PICTURE "@D"          SIZE 08 FONT 1
  COLUMN TITLE "Hora"      DATA oQry:hora                              SIZE 08 FONT 1 
  COLUMN TITLE "Cant"      DATA oQry:cantidad    PICTURE "9999"        SIZE 04 FONT 1 TOTAL
  COLUMN TITLE "P.Unit."   DATA oQry:punit       PICTURE "9999999.99"  SIZE 08 FONT 1        
  COLUMN TITLE "Importe"   DATA oQry:ptotal      PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL
  COLUMN TITLE "A Liquidar"  DATA oQry:ptotal * IF(oQry:liquidado,0,1)      PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL


  oRep:oTitle:aFont[1] := {|| 2 }
  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }
  END REPORT
  // Activo el reporte
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
  // Cierro los archivos
  oQry:End()
  ELSE
  oQry := oApp:oServer:Query("SELECT codart, nomart, sum(cantidad) as cant, sum(ptotal) as total,sum(ptotal*IF(liquidado,0,1)) as saldo  "+;                           
                             " FROM ge_"+oApp:cId+"emp_consumoint "+;                             
                             " WHERE fecha    >= "+ClipValue2Sql(mdesde) + ;
                             " AND   fecha    <= "+ClipValue2Sql(mhasta) + ;                                                                                 
                             " AND   "+IF(mcodigo =0," TRUE "," codemp  = "+ClipValue2Sql(mcodigo) ) + ;
                             " GROUP BY codart" )
  IF oQry:nRecCount = 0
     MsgInfo("Sin datos para listar","Atencion")
     RETURN  
  ENDIF
  REPORT oRep TITLE "Consumo Interno por producto " + DTOC(mdesde) + " al " + DTOC(mhasta),IF(mcodigo=0,"Todos",ALLTRIM(mnombre));
         FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) ;       
         FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
         PREVIEW CAPTION  "Consumo Interno por producto"

  COLUMN TITLE "Codigo"    DATA oQry:codart      PICTURE "9999999"     SIZE 08 FONT 1  
  COLUMN TITLE "Detalle"   DATA oQry:nomart      PICTURE "@!"          SIZE 20 FONT 1  
  COLUMN TITLE "Cant"      DATA oQry:cant        PICTURE "9999999"     SIZE 04 FONT 1 TOTAL  
  COLUMN TITLE "Importe"   DATA oQry:total       PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL
  COLUMN TITLE "A liquidar" DATA oQry:saldo      PICTURE "9999999.99"  SIZE 08 FONT 2 TOTAL


  oRep:oTitle:aFont[1] := {|| 2 }
  oRep:bInit := {|| oQry:GoTop() }
  oRep:bSkip := {|| oQry:Skip() }
  END REPORT
  // Activo el reporte
  ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.JPG",.3,.3)
  // Cierro los archivos
  oQry:End()
ENDIF  
RETURN