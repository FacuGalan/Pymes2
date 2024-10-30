#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** Novedades individuales
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana, oForm
PROCEDURE Inasi(cPermisos)
LOCAL oBar, hHand, oChe, lChe := .f.
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQry  := oApp:oServer:Query( "SELECT n.certifi as certifi, n.legajo AS legajo, n.codigo AS codigo, "+;
                             " n.fecinasi AS fecha, m.nombre AS nombre, c.nombre AS codnom, n.cargo, n.modifico "+;
                             " FROM ge_"+oApp:cId+"emp_inasi n LEFT JOIN ge_"+oApp:cId+"emp_empleado m ON m.codigo = n.legajo LEFT JOIN ge_"+oApp:cId+"emp_inasistencia c ON c.codigo = n.codigo "+;
                             "WHERE n.fecinasi > "+ ClipValue2Sql(DATE()-30)+" "+;
                             "ORDER BY n.fecinasi,n.legajo")
 DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Inasistencias" OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0) .and. "E"$cPermisos;
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Inasistencias",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar datos"  ;
            ACTION Filt();
            PROMPT "Filtrar" TOP         
         DEFINE BUTTON RESOURCE "PAGO" OF oBar ;
            TOOLTIP "Cargar Certificado"  ;
            ACTION Scan();
            PROMPT "Certif." TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "REPORT" OF oBar ;
            TOOLTIP "Ver Certificado"  ;
            ACTION VerCert();
            PROMPT "Ver" TOP WHEN(oQry:RecCount()>0)
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "certifi","legajo","nombre","fecha","codigo","codnom","cargo","modifico";
              HEADERS "Cert","Legajo","Nombre Empleado","Fecha Inas.","Codigo","Detalle Inasistencia","Cargo","Modifico";
              SIZES 30,60,250,90,60,250,80,80;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,Formu(  .f. ),.F.)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oBrw:aCols[1]:AddBitMap( 'FORMU.BMP' )
     oBrw:aCols[1]:bBmpData := {|| IF(oQry:certifi,1,0)}
     oBrw:aCols[1]:bEditValue :=  {|| " "}
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT (oDlg:Move(0,0)) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(8), oBot := ARRAY(3), lRta := .f., aCor, base, oError, oFont, oQry1, oQry2,;
      cNombre := SPACE(30), nLegajo := 0, nCodigo := 0, cCodNom := SPACE(30), dDesde := DATE(), dHasta := DATE(), cSql, i
IF lAlta   
   oQry1 := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"emp_empleado")
   oQry2 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasistencia")  
   ELSE
   oQry1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasi WHERE legajo = " + ClipValue2Sql(oQry:legajo) + " AND fecinasi = " + ClipValue2Sql(oQry:fecha))
   oQry2 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasistencia")
   cNombre := oQry:nombre
   nLegajo := oQry:legajo
   dDesde  := oQry:fecha
   dHasta  := oQry:fecha
   nCodigo := oQry:codigo
   cCodNom := oQry:codnom
   base := oQry1:GetRowObj()
   oQry1:lAppend := .f.
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Inasistencias" FROM 05,10 TO 18,90 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)
   @ 07, 05 SAY "Legajo:"              OF oForm PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Apellido y Nombres:"  OF oForm PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Codigo Inasistencia:" OF oForm PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Fecha desde:"         OF oForm PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Fecha hasta:"         OF oForm PIXEL SIZE 60,12 RIGHT
   @ 05, 70 GET oGet[1] VAR nLegajo   PICTURE "999999" OF oForm PIXEL RIGHT WHEN(lAlta) SIZE 40,10;
     VALID(buscar(oQry1, oForm,  oGet[1], oGet[2])) ACTION (oGet[1]:cText := 0,Buscar(oQry1, oForm,  oGet[1], oGet[2])) BITMAP "BUSC1"
   @ 20, 70 GET oGet[2] VAR cNombre        OF oForm PIXEL WHEN(.F.) SIZE 100,10
   @ 35, 70 GET oGet[3] VAR nCodigo        OF oForm PICTURE "999" SIZE 25,10 PIXEL RIGHT VALID(buscar(oQry2, oForm,oGet[3], oGet[4]));
     ACTION  (oGet[3]:cText := 0, buscar(oQry2, oForm,oGet[3], oGet[4])) BITMAP "BUSC1"
   @ 35, 95 GET oGet[4] VAR cCodNom        OF oForm PICTURE "@!" PIXEL WHEN(.F.) SIZE 100,10
   @ 50, 70 GET oGet[5] VAR dDesde         OF oForm PICTURE "@D" PIXEL  WHEN(lAlta)
   @ 65, 70 GET oGet[6] VAR dHasta         OF oForm PICTURE "@D" PIXEL VALID(dHasta >= dDesde) WHEN(lAlta)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   oQry1:End()
   oQry2:End()
   RETURN nil
ENDIF
IF nLegajo = 0 .or. nCodigo = 0 .or. EMPTY(dDesde)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   IF !valific(nLegajo,dDesde,dHasta)
      LOOP
   ENDIF
   *IF !valicod(nLegajo,nCodigo,dDesde,dHasta, oQry2)
   *   LOOP
   *ENDIF
ENDIF   
IF !lAlta
   base:codigo   := nCodigo
   base:fecinasi := dDesde
   base:legajo   := nLegajo
   base:modifico := oApp:usuario
   oQry1:oRow := base
   TRY
     oApp:oServer:BeginTransaction()
     oQry1:Save()
     oApp:oServer:CommitTransaction()
     oQry:Refresh()
     oBrw:Refresh()
   CATCH oError
     MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
     oApp:oServer:RollBack()
     LOOP
  END TRY
  ELSE
  IF dDesde <> dHasta
     lRta := MsgNoYes("Desea Generar " + STR(dHasta - dDesde + 1,3) + " novedades ","Atencion")
     IF !lRta
        LOOP
     ENDIF
  ENDIF   
  cSql := "INSERT INTO ge_"+oApp:cId+"emp_inasi (legajo,codigo,fecinasi,cargo) VALUES ("
  FOR i := dDesde TO dHasta
      cSql := cSql + STR(nLegajo,6) + " , "+STR(nCodigo,4) + "," + ClipValue2Sql(i) + ","+ClipValue2Sql(oApp:usuario)+") , ("
  NEXT i
  cSql := LEFT(cSql,LEN(cSql) - 3)
  TRY
     oApp:oServer:BeginTransaction()
     oApp:oServer:Execute(cSql)
     oApp:oServer:CommitTransaction()
     oQry:Refresh()
     oQry:Locate( {dDesde,nLegajo}, {"fecha","legajo"})     
     oBrw:Refresh()
  CATCH oError
     MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
     oApp:oServer:RollBack()
     LOOP
  END TRY
ENDIF  
EXIT
ENDDO
oQry1:End()
oQry2:End()
RETURN nil

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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQry:codigo
IF oQry:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro codigo N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"emp_inasi WHERE legajo = " + ClipValue2Sql(oQry:legajo) + " AND fecinasi = " + ClipValue2Sql(oQry:fecha) )
  oApp:oServer:CommitTransaction()
  oQry:Refresh()
CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrw:Refresh()
RETURN nil 


**************************************************
** Filtrar registros
STATIC FUNCTION Filt()
LOCAL oGet := ARRAY(40), oBot := ARRAY(2), lRta := .f., aCor, oFont, csecnom := SPACE(30), ctarnom := SPACE(30),;
      cdepnom := SPACE(30), chornom := SPACE(30), oQrySec, oQryTar, oQryDep, oQryTip, oFilt, ;
      mlegajo1 := 0, mlegajo2 := 999999, mfecha1 := CTOD("01/01/"+STR(YEAR(DATE()),4)), mfecha2 := DATE(), mcodigo1 := 0, mcodigo2 := 999,;
      cWhere

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oFilt TITLE "Filtrado de Inasistencias" FROM 05,10 TO 16,100 OF oWnd1 FONT oFont
   acor := AcepCanc(oFilt)   
   @ 07, 05 SAY "Rango Legajo:"         OF oFilt PIXEL RIGHT SIZE 65,10
   @ 22, 05 SAY "Rango Fechas inasis.:" OF oFilt PIXEL RIGHT SIZE 65,10
   @ 37, 05 SAY "Rango Codigos:"        OF oFilt PIXEL RIGHT SIZE 65,10   
   @ 05, 70 GET oGet[01] VAR mlegajo1   PICTURE "999999"        OF oFilt PIXEL  RIGHT 
   @ 05,120 GET oGet[02] VAR mlegajo2   PICTURE "999999"        OF oFilt PIXEL  RIGHT VALID (mlegajo2>= mlegajo1)
   @ 20, 70 GET oGet[03] VAR mfecha1    PICTURE "@D"            OF oFilt PIXEL
   @ 20,120 GET oGet[04] VAR mfecha2    PICTURE "@D"            OF oFilt PIXEL VALID (mfecha2>= mfecha1)
   @ 35, 70 GET oGet[05] VAR mcodigo1   PICTURE "999"           OF oFilt PIXEL RIGHT
   @ 35,120 GET oGet[06] VAR mcodigo2   PICTURE "999"           OF oFilt PIXEL RIGHT VALID (mcodigo2>= mcodigo1) 
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .t.), oFilt:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
ACTIVATE DIALOG oFilt CENTER
IF !lRta
   RETURN nil
ENDIF   
cWhere = " 1=1 ";
        + " and n.legajo >=" + ClipValue2SQL(mlegajo1) + " AND n.legajo <= " + ClipValue2SQL(mlegajo2) ;        
        + " and n.fecinasi >=" + ClipValue2SQL(mfecha1) + " AND n.fecinasi <= " + ClipValue2SQL(mfecha2) ;
        + " and n.codigo >=" + ClipValue2SQL(mcodigo1) + " AND n.codigo <= " + ClipValue2SQL(mcodigo2)             
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil

************************************************************
** Validar que el codigo sea valido en cuanto a limites
STATIC FUNCTION valicod(xlegajo,xcodigo,xfecha,xfechahas, oQry2)
LOCAL cont := 0, xfec, retorno := .t., oQryM 
oQryM := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasi WHERE legajo = " + ClipValue2SQL(xlegajo) +;
                            " AND fecinasi < " + ClipValue2Sql(xfecha) + " AND codigo = " + ClipValue2SQL(xcodigo) )
IF oQry2:tope <> 0
   IF oQry2:continuas
      oQryM:GoBottom()
      xfec := xfecha
      DO WHILE !oQryM:BOF()         
         IF oQryM:fecinasi = xfec - 1
            cont ++
            xfec := xfec -1
         ENDIF
         oQryM:SKIP(-1)
      ENDDO      
      IF oQry2:tope < cont + (xfechahas - xfecha) + 1
         MsgInfo("Limite superado."+CHR(10)+;
                  "Limite:" + STR(oQry2:tope,4)+CHR(10)+;
                  "Tiene:"  + STR(cont,4) + CHR(10)+;
                  "Agrega:" + STR((xfechahas - xfecha) + 1,4) +CHR(10)+;
                  "Total:"  + STR(cont  + (xfechahas - xfecha) + 1,4))
         retorno = .F.
      ENDIF
      ELSE
      // No continuas
      oQryM:GoTop()
      DO WHILE !oQryM:EOF()         
         IF YEAR(oQryM:fecinasi) = YEAR(xfecha)
            cont++
         ENDIF
         oQryM:SKIP()
      ENDDO      
      IF oQry2:tope < cont + (xfechahas - xfecha) + 1
          MsgInfo("Limite superado."+CHR(10)+;
                  "Limite:" + STR(oQry2:tope,4)+CHR(10)+;
                  "Tiene:"  + STR(cont,4) + CHR(10)+;
                  "Agrega:" + STR((xfechahas - xfecha) + 1,4) +CHR(10)+;
                  "Total:"  + STR(cont  + (xfechahas - xfecha) + 1,4))
         retorno = .F.
      ENDIF
   ENDIF
ENDIF
RETURN retorno

***************************************************************
*** Validar que no haya fichadas para el rango de inasistencias
STATIC FUNCTION valific(mlegajo,mdesde,mhasta)
LOCAL oQryFic, oDlg, oBrwErr, oFont
oQryFic := oApp:oServer:Query("SELECT h.codtar AS legajo, h.fecha as fecha, h.hora1ent, "+;
                              " h.hora1sal, h.hora2ent, h.hora2sal, "+;
                              " h.hora3ent, h.hora3sal, m.codigo, "+;
                              " m.nombre AS nombre, h.tipo FROM ge_"+oApp:cId+"emp_horas h "+;
                              " LEFT JOIN ge_"+oApp:cId+"emp_empleado m ON m.codigo = h.codtar  "+;
                              " WHERE h.codtar = " + ClipValue2SQL(mlegajo) +;
                               " AND h.fecha >= " + ClipValue2SQL(mdesde) +;
                                 "AND h.fecha <= " + ClipValue2SQL(mhasta))
IF oQryFic:nRecCount > 0
   DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5   
   DEFINE DIALOG oDlg TITLE "ERROR!! Tiene fichadas registrada ese legajo" FROM 05,10 TO 20,100 OF oWnd1 FONT oFont
   @ 05,05 XBROWSE oBrwErr DATASOURCE oQryFic;
              COLUMNS "legajo","nombre","fecha","hora1ent","hora1sal","tipo";
              HEADERS "Legajo","Apellido y nombres","Fecha","Hora Ent","Hora Sal","Tipo";
              SIZES 80,260,80,80,80,40;
              OF oDlg AUTOSORT CELL SIZE 340,100 PIXEL 
   oBrwErr:CreateFromCode()
   PintaBrw(oBrwErr,0)
   ACTIVATE DIALOG oDlg CENTER 
   RETURN .f.
ENDIF
RETURN .t.


****************************************************************
** Digitalizar Certificado
STATIC FUNCTION Scan()
LOCAL cFile
cFile := cGetFile( "Foto certificado (*.jpg)|*.jpg", "Elija la foto",, ".\xxxx", .f. )
IF EMPTY(cFile)
   RETURN nil 
ENDIF
IF UPPER(cFile) <> UPPER(hb_curDrive()+":\"+CurDir()+"\iconos\"+STRTRAN(STR(oQry:legajo,8)," ","0")+"-"+DTOS(oQry:Fecha)+".jpg")     
   COPY FILE (cFile) TO (hb_curDrive()+":\"+CurDir()+"\iconos\"+STRTRAN(STR(oQry:legajo,8)," ","0")+"-"+DTOS(oQry:Fecha)+".jpg")
ENDIF
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"emp_inasi SET certifi = TRUE WHERE legajo = " +;
                    ClipValue2SQL(oQry:legajo) + " AND fecinasi = " + ClipValue2Sql(oQry:fecha) )
oQry:Refresh()
oBrw:Refresh()
RETURN nil

****************************************************************
** Ver el certificado
STATIC FUNCTION VerCert()
LOCAL oImg, cFoto, oDlg
IF !oQry:certifi
   RETURN nil    
ENDIF
cFoto := hb_CurDrive()+":\"+CurDir()+"\iconos\"+STRTRAN(STR(oQry:legajo,8)," ","0")+"-"+DTOS(oQry:Fecha)+".jpg"
DEFINE DIALOG oDlg TITLE "Certificado" FROM 05,10 TO 42,100 OF oWnd1 
oDlg:lHelpIcon := .f.
@ 00, 00 IMAGE oImg  OF oDlg PIXEL SIZE 350,260 SCROLL
ACTIVATE DIALOG oDlg CENTER ON INIT oImg:LoadImage(nil, cFoto) 
RETURN nil