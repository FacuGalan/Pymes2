#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** Fichadas Manuales
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana, oForm, lIncompletos, mdesde, mhasta, mtiempo := 11, lEstamarcando := .f.
PROCEDURE Fichada(cPermisos)
LOCAL oBar, hHand, oChe, lChe := .f.
cVentana := PROCNAME()
mdesde := DATE()-30
mhasta := CTOD("31/12/2250")
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
lIncompletos := .F.
oQry  := oApp:oServer:Query( "SELECT h.id AS id, h.codtar AS tarjeta, "+;
                             " h.fecha AS fecha, m.nombre AS nombre, h.hora1ent,hora1sal, "+;
                             " h.hora2ent,hora2sal, h.hora3ent,hora3sal,  "+;
                             " h.tipo AS tipo, h.enrecibo as enrecibo "+;
                             " FROM ge_"+oApp:cId+"emp_horas h LEFT JOIN ge_"+oApp:cId+"emp_empleado m ON m.codigo = h.codtar "+;                             
                             "WHERE h.fecha >= "+ ClipValue2Sql(mdesde)+" AND "+;
                             "      h.fecha <= "+ ClipValue2Sql(mhasta)+" "+;
                             "ORDER BY h.fecha")

 DEFINE WINDOW oWnd1 MDICHILD TITLE "Carga manual de fichadas" OF oApp:oWnd NOZOOM ICON oApp:oIco
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
            ACTION oBrw:Report("Reporte de Inasistencias " + DTOC(date()),.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar datos"  ;
            ACTION Filt();
            PROMPT "Filtrar" TOP
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Importar desde relojes" ;
            ACTION ImpoHoras1() WHEN("ABM"$cPermisos);
            PROMPT "Importar" TOP    
         DEFINE BUTTON RESOURCE "CODBAR1" OF oBar ;
            TOOLTIP "Fichar con tarjeta de codigo de barra" ;
            ACTION (Fichar(),oQry:Refresh(),oBrw:Refresh()) WHEN("A"$cPermisos);
            PROMPT "Fichar" TOP    
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "tarjeta","nombre","fecha","hora1ent","hora1sal","hora2ent","hora2sal","hora3ent","hora3sal","tipo","id";
              HEADERS "Legajo","Nombre Empleado","Fecha","Entrada","Salida","Entrada","Salida","Entrada","Salida","Tipo","Fichada Nro";
              SIZES 60,180,70,70,70,70,70,70,70,30;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,Formu(  .f. ),.F.)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg     
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,0) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT (oDlg:Move(0,0)) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(12), oBot := ARRAY(3), lRta := .f., aCor, base, oError, oFont, oQry1, oQry2,;
      cNombre := SPACE(30), nCodTar := 0, dFecha := DATE(), cSql, nId, lEnRecibo := .f.,;
      cHora1Ent:= "00:00:00", cHora2Ent:= "00:00:00", cHora3Ent:= "00:00:00", ;
      cHora1Sal:= "00:00:00", cHora2Sal:= "00:00:00", cHora3Sal:= "00:00:00"

IF lAlta   
   oQry1 := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"emp_empleado")
   ELSE
   oQry1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_horas WHERE id = " + ClipValue2Sql(oQry:id) )
   cNombre := oQry:nombre
   nCodtar := oQry:tarjeta
   dFecha  := oQry:fecha
   cHora1Ent := oQry:hora1Ent
   cHora2Ent := oQry:hora2Ent
   cHora3Ent := oQry:hora3Ent
   cHora1Sal := oQry:hora1Sal
   cHora2Sal := oQry:hora2Sal
   cHora3Sal := oQry:hora3Sal
   lEnRecibo := oQry:enrecibo
   base := oQry1:GetRowObj()
   oQry1:lAppend := .f.
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Fichadas" FROM 05,10 TO 20,90 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)
   @ 07, 05 SAY "Legajo:"              OF oForm PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Apellido y Nombres:"  OF oForm PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Fecha:"               OF oForm PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Entrada / Salida:"    OF oForm PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Entrada / Salida:"    OF oForm PIXEL SIZE 60,12 RIGHT
   @ 82, 05 SAY "Entrada / Salida:"    OF oForm PIXEL SIZE 60,12 RIGHT
   @ 05, 70 GET oGet[1] VAR nCodTar   PICTURE "999999" OF oForm PIXEL RIGHT WHEN(lAlta) SIZE 40,10;
     VALID(buscar(oQry1, oForm,  oGet[1], oGet[2])) ;
     ACTION (oGet[1]:cText := 0,buscar(oQry1, oForm, oGet[1], oGet[2])) BITMAP "BUSC1"
   @ 20, 70 GET oGet[2] VAR cNombre        OF oForm PIXEL WHEN(.F.) SIZE 100,10
   @ 35, 70 GET oGet[3] VAR dFecha         OF oForm PICTURE "@D" PIXEL 
   //@ 35,170 CHECKBOX oGet[10] VAR lEnRecibo PROMPT "En recibo" SIZE 35,12 OF oForm PIXEL 
   @ 50, 70 GET oGet[4] VAR cHora1Ent      OF oForm PICTURE "99:99:99" PIXEL     
   @ 50,170 GET oGet[5] VAR cHora1Sal      OF oForm PICTURE "99:99:99" PIXEL     
   @ 65, 70 GET oGet[6] VAR cHora2Ent      OF oForm PICTURE "99:99:99" PIXEL     
   @ 65,170 GET oGet[7] VAR cHora2Sal      OF oForm PICTURE "99:99:99" PIXEL     
   @ 80, 70 GET oGet[8] VAR cHora3Ent      OF oForm PICTURE "99:99:99" PIXEL     
   @ 80,170 GET oGet[9] VAR cHora3Sal      OF oForm PICTURE "99:99:99" PIXEL     

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT IF(lAlta,"&Graba/Sig","&Grabar") OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   oQry1:End()   
   RETURN nil
ENDIF
IF lAlta .and. oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_inasi WHERE legajo = "+ClipValue2Sql(nCodtar)+;
	              " AND fecinasi ="+ClipValue2Sql(dFecha)):nRecCount>0
	MsgStop("El empleado tiene cargada novedades","Error")
	LOOP
ENDIF
IF nCodTar = 0 .or. EMPTY(dFecha)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF 
IF !lAlta   
   base:fecha    := dFecha
   base:tipo     := "M"   
   base:hora1Ent := IF(cHora1Ent="  :  :  ",' ',cHora1Ent)
   base:hora1Sal := IF(cHora1Sal="  :  :  ",' ',cHora1Sal)
   base:hora2Ent := IF(cHora2Ent="  :  :  ",' ',cHora2Ent)
   base:hora2Sal := IF(cHora2Sal="  :  :  ",' ',cHora2Sal)
   base:hora3Ent := IF(cHora3Ent="  :  :  ",' ',cHora3Ent)
   base:hora3Sal := IF(cHora3Sal="  :  :  ",' ',cHora3Sal)
   base:enrecibo := lEnRecibo
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
  EXIT
  ELSE    
  chora1Ent := IF(cHora1Ent="  :  :  ",' ',cHora1Ent)
  chora1Sal := IF(cHora1Sal="  :  :  ",' ',cHora1Sal)
  chora2Ent := IF(cHora2Ent="  :  :  ",' ',cHora2Ent)
  chora2Sal := IF(cHora2Sal="  :  :  ",' ',cHora2Sal)
  chora3Ent := IF(cHora3Ent="  :  :  ",' ',cHora3Ent)
  chora3Sal := IF(cHora3Sal="  :  :  ",' ',cHora3Sal)
  cSql := "INSERT INTO ge_"+oApp:cId+"emp_horas (codtar,fecha,hora1ent,hora1sal,hora2ent,hora2sal,hora3ent,hora3sal,tipo,enrecibo) VALUES (" +;
          STR(nCodTar,6) + " , "+ClipValue2Sql(dFecha) + "," +;
          ClipValue2Sql(cHora1Ent) + "," + ClipValue2Sql(cHora1Sal) + ","+;
          ClipValue2Sql(cHora2Ent) + "," + ClipValue2Sql(cHora2Sal) + ","+;
          ClipValue2Sql(cHora3Ent) + "," + ClipValue2Sql(cHora3Sal) + ","+;
          "'M',"+ClipValue2Sql(lEnRecibo)+")"
  TRY
     oApp:oServer:BeginTransaction()
     oApp:oServer:Execute(cSql)
     oApp:oServer:CommitTransaction()
     oQry:Refresh()
     oQry:GoBottom()
     oBrw:Refresh()
  CATCH oError
     MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
     oApp:oServer:RollBack()
     LOOP
  END TRY
  nCodTar := 0  
  lRta := .f. 
ENDIF  
ENDDO
oQry1:End()
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
LOCAL mrta := .f., oError, nNum := oQry:id
IF nNum = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"emp_horas WHERE id = " + ClipValue2Sql(nNum))
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
LOCAL oGet := ARRAY(5), oBot := ARRAY(2), lRta := .f., aCor, oFont, csecnom := SPACE(30), ctarnom := SPACE(30),;
      cdepnom := SPACE(30), chornom := SPACE(30), oQrySec, oQryTar, oQryDep, oQryTip, oFilt, ;
      mlegajo1 := 0, mlegajo2 := 999999, mcodigo1 := 0, mcodigo2 := 999,;
      cWhere

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oFilt TITLE "Filtrado de Horas" FROM 05,10 TO 16,100 OF oWnd1 FONT oFont
   acor := AcepCanc(oFilt)   
   @ 07, 05 SAY "Rango Legajo:"         OF oFilt PIXEL RIGHT SIZE 65,10
   @ 22, 05 SAY "Rango Fechas horas:"   OF oFilt PIXEL RIGHT SIZE 65,10
   
   @ 05, 70 GET oGet[01] VAR mlegajo1   PICTURE "999999"        OF oFilt PIXEL  RIGHT 
   @ 05,120 GET oGet[02] VAR mlegajo2   PICTURE "999999"        OF oFilt PIXEL  RIGHT VALID (mlegajo2>= mlegajo1)
   @ 20, 70 GET oGet[03] VAR mdesde     PICTURE "@D"            OF oFilt PIXEL
   @ 20,120 GET oGet[04] VAR mhasta     PICTURE "@D"            OF oFilt PIXEL VALID (mhasta>= mdesde)
   @ 35, 70 CHECKBOX oGet[05] VAR lIncompletos PROMPT "Solo lIncompletos" SIZE 60,12 OF oFilt PIXEL

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .t.), oFilt:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
           ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
ACTIVATE DIALOG oFilt CENTER
IF !lRta
   RETURN nil
ENDIF   
cWhere = " 1=1 ";
        + " and m.codigo >=" + ClipValue2SQL(mlegajo1) + " AND m.codigo <= " + ClipValue2SQL(mlegajo2) ;        
        + " and h.fecha >=" + ClipValue2SQL(mdesde)   + " AND h.fecha <= " + ClipValue2SQL(mhasta) ;
        + IF(lIncompletos, " and (h.hora1sal = SPACE(8) or h.hora2ent = SPACE(8) or h.hora2sal = SPACE(8) ) ",;
          "")
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil


**************************************
** Importar horas desde txt
STATIC FUNCTION ImpoHoras1()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      aCols := {{0,CTOD("  /  /    "),SPACE(8)}},;
      i, cError, cSql, aFicha1 := {}, aFicha2 := {},  j
DO WHILE .T.       
  DEFINE DIALOG oDlg1 TITLE "Importar Fichadas" FROM 03,15 TO 35,140
     acor := AcepCanc(oDlg1)    
     @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oDlg1 ARRAY aCols ;
        HEADERS "Legajo", "Fecha","Hora";
        COLUMNS 1, 2 ,3;
        SIZES 80,150,150;
        CELL LINES NOBORDER FASTEDIT
     WITH OBJECT oBrwTmp
        :nEditTypes := 1  
        :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
        :CreateFromCode()
     END  
     @ 205,05 SAY "Use el boton PEGAR para incluir los datos o edite manualmente los campos. "+;
                  "Tenga en cuenta que el codigo de legajo tiene que ser valido"+;
                  " y que la fecha y hora deben ser valores validos. Tiene que importar de a un dia." SIZE 465,60 OF oDlg1 PIXEL 
     PintaBrw(oBrwTmp,0)
     @ 00, 00 BUTTON oBot1 PROMPT "&Pegar" OF oDlg1 SIZE 30,10 ;
             ACTION (Procesando(.t.),oBrwTmp:Paste(),Procesando(.f.)) PIXEL
     @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Importar" OF oDlg1 SIZE 30,10 ;
             ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
     @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
             ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
  ACTIVATE DIALOG oDlg1 CENTER 
  IF !mrta 
     RETURN nil 
  ENDIF 
  ** Validaciones
  cError := {}
  FOR i := 1 TO LEN(aCols)
      IF aCols[i,1] = 0
         AADD(cError,"Columna 1 en posicion " + STR(i,6) + " no puede estar en cero ")
      ENDIF
      IF EMPTY(aCols[i,2]) .or. VALTYPE(aCols[i,2]) <> "D"
         AADD(cError,"Columna 2 en posicion " + STR(i,6) + " tiene que ser una fecha ")
      ENDIF
      IF EMPTY(aCols[i,3])
         AADD(cError,"Columna 3 en posicion " + STR(i,6) + " no puede estar en blanco ")
      ENDIF    
      IF !EsHora(aCols[i,3])
         AADD(cError,"Columna 3 en posicion " + STR(i,6) + " no es una hora valida ")
      ENDIF
      IF !EsTarjeta(aCols[i,1])
         AADD(cError,"Columna 1 en posicion " + STR(i,6) + " no es una tarjeta valida ")
      ENDIF    
  NEXT
  IF !EMPTY(cError)
     DEFINE DIALOG oDlg1 TITLE "Errores" FROM 03,15 TO 35,120
     acor := AcepCanc(oDlg1)    
     @ 20, 05 XBROWSE oBrwTmp SIZE 365,180 pixel OF oDlg1 ARRAY cError ;
        HEADERS "Error";
        COLUMNS 1;
        SIZES 1000;
        CELL LINES NOBORDER FASTEDIT
     WITH OBJECT oBrwTmp
        :nEditTypes := 1      
        :CreateFromCode()
     END  
     PintaBrw(oBrwTmp,0)   
     @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Volver" OF oDlg1 SIZE 30,10 ;
             ACTION oDlg1:End()  PIXEL   
     ACTIVATE DIALOG oDlg1 CENTER 
     LOOP
  ENDIF
  EXIT
ENDDO

FOR i := 1 TO LEN(aCols)
    j := ASCAN(aFicha1,aCols[i,1]) 
    IF j = 0
       AADD(aFicha1, aCols[i,1])
       AADD(aFicha2, {aCols[i,1],aCols[i,2],aCols[i,3],'   ','   ','   ','   ','   '})
       ELSE 
       DO CASE 
          CASE aFicha2[j,4] = ' '
               aFicha2[j,4] := aCols[i,3]
          CASE aFicha2[j,5] = ' '
               aFicha2[j,5] := aCols[i,3]
          CASE aFicha2[j,6] = ' '
               aFicha2[j,6] := aCols[i,3]
          CASE aFicha2[j,7] = ' '
               aFicha2[j,7] := aCols[i,3]
          CASE aFicha2[j,8] = ' '
               aFicha2[j,8] := aCols[i,3]
       ENDCASE
    ENDIF    
NEXT i
XBROWSE(aFicha2)

cSql := "INSERT INTO ge_"+oApp:cId+"emp_horas "+;
        " (codtar,fecha,hora1ent,hora1sal,hora2ent,hora2sal,hora3ent,hora3sal) VALUES "
FOR i := 1 TO LEN(aFicha2)
    cSql := cSql + "("+ClipValue2SQL(aFicha2[i,1]) + "," + ;
                       ClipValue2SQL(aFicha2[i,2]) + ",'" + ;                       
                       aFicha2[i,3] + "','" + ;                       
                       aFicha2[i,4] + "','" + ;
                       aFicha2[i,5] + "','" + ;
                       aFicha2[i,6] + "','" + ;
                       aFicha2[i,7] + "','" + ;
                       aFicha2[i,8] + "'), " 
NEXT i
cSql := LEFT(cSql,LEN(cSql)-2)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute(cSql)
  oApp:oServer:CommitTransaction()
  oQry:Refresh()
  oBrw:Refresh()

CATCH cError
  MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
  oApp:oServer:RollBack()
END TRY    
RETURN nil

STATIC FUNCTION EsHora(cHora)
RETURN ISDIGIT(LEFT(cHora,1)) .AND. ISDIGIT(SUBSTR(cHora,2,1)) .AND. ISDIGIT(SUBSTR(cHora,4,1)) .AND. ISDIGIT(SUBSTR(cHora,5,1)) .AND.;
       ISDIGIT(SUBSTR(cHora,7,1)) .AND. ISDIGIT(SUBSTR(cHora,8,1)) .AND. SUBSTR(cHora,3,1) = ":" .AND. SUBSTR(cHora,6,1) = ":"

STATIC FUNCTION EsTarjeta(N)
IF n == 0 .OR. oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = " + ClipValue2Sql(n)):nRecCount == 0
   RETURN .f.
ENDIF
RETURN .t.

**************************************
** Fichar con reloj 
FUNCTION Fichar(cPermisos)
LOCAL oIco, oGet, oSay1, oSay2, oSay3, oFont1, oFont2, oFont3, oFont4, oDlg,;
      mCodTar := 0, mnombre := SPACE(60), mfecha := DATE(), mhora := TIME(),;
      oTimer, oBot1, oBot2, oBot3, nSalida := 0
DEFAULT cPermisos := ""
    DEFINE FONT oFont1 NAME "Segoe UI" SIZE 14,18 BOLD
    DEFINE FONT oFont2 NAME "Segoe UI" SIZE 10,20 BOLD
    DEFINE FONT oFont3 NAME "Segoe UI" SIZE 20,30 BOLD
    DEFINE FONT oFont4 NAME "Segoe UI" SIZE 40,80 BOLD
    DEFINE DIALOG oDlg TITLE "Fichadas por tarjeta" FROM 01,01 TO 30,50 OF oApp:oWnd   
    oDlg:lHelpIcon := .f.
    @ 05, 05 SAY "PASE SU TARJETA:" OF oDlg SIZE 200,20 FONT oFont1 PIXEL CENTER
    @ 30, 55 GET oGet  VAR mCodtar   SIZE 100,20 PICTURE "9999999999999" OF oDlg FONT oFont1 PIXEL RIGHT
    @ 55, 05 SAY oSay1 PROMPT "Pase la tarjeta por el lector" OF oDlg FONT oFont2 PIXEL SIZE 200,20 CENTER
    @ 70, 05 SAY oSay2 PROMPT DTOC(DATE()) OF oDlg FONT oFont3 PIXEL SIZE 200,40 CENTER
    @112, 05 SAY oSay3 PROMPT LEFT(TIME(),5) OF oDlg FONT oFont4 PIXEL SIZE 200,80 CENTER
    //oSay1:SetText("Pase la tarjeta por el lector")
    //oSay2:SetText(DTOC(DATE()))
    //oSay3:SetText(LEFT(TIME(),5))
    oGet:bKeyDown := { | nKey, nFlags | IF(nKey==13,;
                     Fichada1(mcodtar,oGet, oSay1, oSay2, oSay3,oDlg,oFont2,cPermisos),.f.)}
    ACTIVATE DIALOG oDlg CENTER ;
             ON PAINT (oGet:SetFocus() ,Timer1(oSay1, oSay2, oSay3))
Return nil

STATIC FUNCTION Fichada1(mcodtar,oGet, oSay1, oSay2, oSay3,oWnd,oFont,cPermisos)
LOCAL cMensaje1 := "", cMensaje2 := "", lHuboError := .f., mfecha := DATE(), ;
      mhora := TIME(), multimo, oQryEmp, oQryHor, cVar, aVar := {"hora1ent","hora1sal","hora2ent","hora2sal","hora3ent","hora3sal"}
oGet:Assign()
mcodtar := oGet:Value      
IF lEstaMarcando
   RETURN nil
ENDIF
mtiempo := 0
IF mcodtar = 0
   RETURN nil
ENDIF
lEstaMarcando := .t.
oQryEmp := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = " + ClipValue2Sql(mcodtar))
IF oQryEmp:nRecCount > 0
   DO CASE
      CASE mhora > "00:" .AND. mhora <= "12.00"
           cMensaje1 := "Buen dia "
      CASE mhora > "12:01" .AND. mhora <= "20.00"
           cMensaje1 := "Buenas Tardes "
      OTHERWISE
           cMensaje1 := "Buenas Noches "
   ENDCASE
   oQryHor := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_horas WHERE codtar = " + ClipValue2Sql(mcodtar) + ;
             " AND fecha = " + ClipValue2Sql(mfecha))
   multimo := 0
   IF oQryHor:nRecCount = 0
      multimo := 1
      ELSE
      multimo := Ultimo(oQryHor)
      IF multimo = 0
         MsgBeep()
         oSay1:SetText("E R R O R      Ya marco 6 veces")
         oSay2:SetText(DTOC(mfecha))
         oSay3:SetText(LEFT(mhora,5))
         lHuboError := .t.
         lEstaMarcando := .f.
         RETURN nil
      ENDIF
   ENDIF   
   IF multimo > 1
     cVar := aVar[multimo-1]
     IF HorasTra(mhora,oQryHor:&cVar) <= 0.016
        MsgBeep()
        MsgInfo("Ud. ya marco a las " + oQryHor:&cVar,"Atencion")
        lHuboError := .t.
        ELSE
        cMensaje2 := ALLTRIM(oQryEmp:nombre)
     ENDIF
   ENDIF
   IF EMPTY(cMensaje2)
      cMensaje2 := ALLTRIM(oQryEmp:nombre)
   ENDIF
   TONE(100.2,.9)
   oSay1:SetText(cMensaje1 + cMensaje2)
   oSay2:SetText(DTOC(mfecha))
   oSay3:SetText(LEFT(mhora,5))
   *oSay1:SetText("Pase la tarjeta por el lector...")
   IF !lHuboError
      MenWait(cMensaje1 + cMensaje2,"Fichada Registrada",2.5,oWnd,oFont)
   ENDIF
   IF empty(cPermisos)
      oQry:Refresh()
   ENDIF
   IF empty(cPermisos)
      oBrw:Refresh()
   ENDIF
   ELSE
   MsgBeep()
   oSay1:SetText("E R R O R      TARJETA NO VALIDA")
   oSay1:SetColor(CLR_BLACK)
   oSay2:SetText(DTOC(mfecha))
   oSay3:SetText(LEFT(mhora,5))
   lHuboError := .t.
ENDIF
oSay1:Refresh()
oSay2:Refresh()
oSay3:Refresh()
oGet:SetFocus()
oGet:cText := 0
oGet:Refresh()
IF !lHuboError
   IF multimo = 1
      IF mhora < '04:30' /// Marco salida de la noche y entrada de la mañana haciendo corte        
         oQryHor := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_horas WHERE codtar = " + ClipValue2Sql(mcodtar) + ;
             " AND fecha = " + ClipValue2Sql(mfecha-1))
         multimo := 0
         IF oQryHor:nRecCount = 0
            multimo := 0
            ELSE
            multimo := Ultimo(oQryHor)            
         ENDIF   
         IF multimo > 1
            oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_horas (codtar,fecha,hora1ent,hora1sal) VALUES "+;
                             "(" + ClipValue2Sql(mcodtar)+ ","+;
                                   ClipValue2Sql(mfecha)+ ",'00:00:01',"+;
                                   ClipValue2Sql(mhora)+")")
            oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"emp_horas SET "+aVar[multimo]+" = '23:59:59'" + ;
                           " WHERE codtar = " + ClipValue2Sql(mcodtar) + " AND fecha = " + ClipValue2Sql(mfecha-1) )      
         ENDIF            
         ELSE 
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_horas (codtar,fecha,hora1ent) VALUES "+;
                             "(" + ClipValue2Sql(mcodtar)+ ","+;
                                   ClipValue2Sql(mfecha)+ ","+;
                                   ClipValue2Sql(mhora)+")")
      ENDIF
      ELSE
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"emp_horas SET "+aVar[multimo]+" = "+ClipValue2Sql(mhora) + ;
                           " WHERE codtar = " + ClipValue2Sql(mcodtar) + " AND fecha = " + ClipValue2Sql(mfecha) )
   ENDIF
ENDIF
lEstaMarcando := .f.
RETURN nil

STATIC FUNCTION HorasTra(mhora1,mhora2)
LOCAL mh1, mh2, mm1, mm2, mh
mh1 := VAL(LEFT(mhora1,2))
mh2 := VAL(LEFT(mhora2,2))
mm1 := VAL(SUBSTR(mhora1,4,2))
mm2 := VAL(SUBSTR(mhora2,4,2))
IF mh1 < mh2
   RETURN 0
ENDIF
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
mh := mh1 - mh2 + (mm1 + 60 - mm2) / 60
RETURN mh


STATIC FUNCTION Timer1(oSay1, oSay2, oSay3)
LOCAL oTimer
    DEFINE TIMER oTimer INTERVAL 1000*30 ACTION Actualiza(oSay1,oSay2,oSay3)
    ACTIVATE TIMER oTimer
RETURN nil

STATIC FUNCTION Actualiza(oSay1, oSay2, oSay3)
mtiempo ++
oSay3:SetText(LEFT(TIME(),5))
*IF mtiempo > 10
   oSay1:SetText("Pase la tarjeta por el lector...")
   oSay1:SetText(CLR_RED)
   oSay2:SetText(DTOC(DATE()))
*   mtiempo := 0
*ENDIF
RETURN nil

STATIC FUNCTION MenWait(Mensaje,Titulo,Espera,oWnd,oFont)
LOCAL i, oDlg1, oBmp
SetDlgGradient( { { 1, RGB( 43, 255, 0 ), RGB( 237, 242, 248 ) } } )
DEFINE DIALOG oDlg1 TITLE Titulo FROM 01,01 TO 16,50 OF oWnd
   @ 02, 02 XIMAGE oBmp RESOURCE "VENT1" OF oDlg1 SIZE 32,32 NOBORDER   
   @ 40,05 SAY ALLTRIM(Mensaje)        OF oDlg1 PIXEL FONT oFont CENTER SIZE 170,19
   @ 60,05 SAY "Fichada registrada..." OF oDlg1 PIXEL FONT oFont CENTER SIZE 170,19
ACTIVATE DIALOG oDlg1 CENTER NOWAIT
SysRefresh()
SysWait(Espera)
SetDlgGradient( { { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } } )
oDlg1:End()
RETURN nil 

STATIC FUNCTION Ultimo(oQry)
LOCAL nUlt := 0
IF EMPTY(oQry:hora1ent)
   nUlt := 1
   ELSE
   IF EMPTY(oQry:hora1sal)
       nUlt := 2
       ELSE
        IF EMPTY(oQry:hora2ent)
           nUlt := 3
           ELSE
            IF EMPTY(oQry:hora2sal)
               nUlt := 4
               ELSE
                IF EMPTY(oQry:hora3ent)
                   nUlt := 5
                   ELSE
                   nUlt := 6
                ENDIF   
            ENDIF   
        ENDIF   
  ENDIF   
ENDIF
RETURN nUlt   