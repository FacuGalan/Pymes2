#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "Report.ch"


*************************************************
** ABM DE EMPLEADOS
*************************************************
MEMVAR oApp
STATIC oQryBrw,oWnd1, oBrw, oDlg, cVentana
PROCEDURE ABMEMPL(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado ORDER BY nombre")
                         
  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Empleados" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Empleados",.T.,.F., { |oRep,brw| ReporteE( oRep, brw ) });
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "CODBAR1" OF oBar ;
            TOOLTIP "Emitir tarjeta para fichada"  ;
            ACTION Tarjeta() ;
            PROMPT "Tarjeta" TOP
         DEFINE BUTTON RESOURCE "PAGO" OF oBar ;
            TOOLTIP "Cargar liquidación Mensual"  ;
            ACTION Liquida();
            PROMPT "Liquidación" TOP WHEN(oQryBrw:RecCount()>0 .and. "AB"$cPermisos) 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "Codigo","nombre","inactivo";
              HEADERS "Legajo","Nombre","Inactivo";
              SIZES 60,445,60;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     *oBrw:aCols[2]:SetOrder()
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     oBrw:aCols[3]:bEditValue := {|| IF( oQryBrw:inactivo, .t., .f. )  }
     oBrw:aCols[3]:SetCheck(,.t.)
     PintaBrw(oBrw,3) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
STATIC FUNCTION Acelerador2(nKey, oBar,cPermisos)

IF nKey = 13
   IF "M"$cPermisos
      oBar:aControls[2]:Click()
      oBrw:GoLeftMost()
  ENDIF
ENDIF

RETURN NIL

*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(31), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
	    cNomSec:=SPACE(50),oQrySec:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_sector"),;
      cNomCat:=SPACE(50),oQryCat:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_emplcat"),;
      mfoto := ".\iconos\nofoto.jpg", aConsumo_por := {"Por precio Costo","Por precio Venta"},;
      manti := SPACE(20)


IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado LIMIT 0")
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"emp_empleado")
   base:sueldo:=0
   base:hor_hab_desde1:= "07:00:00"
   base:hor_hab_hasta1:= "12:00:00"
   base:hor_hab_desde2:= "13:00:00"
   base:hor_hab_hasta2:= "17:00:00"
   base:consumo_por := 2
   base:tipocontrato := "MENSUAL"+SPACE(13)
   base:tope_adelanto := 0
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
   base := oQry:GetRowObj()
   oQry:lAppend:= .f.
   oQrySec:GoTop()
   IF oQrySec:Seek(base:sector,1) > 0
      cNomSec := oQrySec:nombre
   ENDIF
   oQryCat:GoTop()
   IF oQryCat:Seek(base:catego,1) > 0
      cNomCat := oQryCat:nombre
   ENDIF

ENDIF

mfoto := ;
  IF(FILE(".\iconos\"+STRTRAN(STR(base:codigo,8)," ","0")+".jpg"),;
     ".\iconos\"+STRTRAN(STR(base:codigo,8)," ","0")+".jpg",;
     mfoto)

DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Empleados";
       FROM 05,15 TO 38,95 OF oWnd1 FONT oApp:oFont
   
   @ 07, 05 SAY "Legajo:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 05 SAY "Nombre:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 05 SAY "Sector:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 52, 05 SAY "Localidad:"   OF oForm PIXEL SIZE 40,20 RIGHT
   @ 67, 05 SAY "Direccion:"   OF oForm PIXEL SIZE 40,20 RIGHT
   @ 82, 05 SAY "Telefono:"    OF oForm PIXEL SIZE 40,20 RIGHT
   @ 97, 05 SAY "Mail:"        OF oForm PIXEL SIZE 40,20 RIGHT
   @112, 05 SAY "Sueldo:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @127, 05 SAY "Categoria:"   OF oForm PIXEL SIZE 40,20 RIGHT
   @112,105 SAY "C.U.I.L.:"    OF oForm PIXEL SIZE 30,20 RIGHT
   @112,200 SAY "Fecha Ing.:"  OF oForm PIXEL SIZE 30,20 RIGHT
   @142, 50 SAY "HORARIO HABITUAL" OF oForm PIXEL SIZE 50,12 RIGHT
   @157, 05 SAY "Entrada:" OF oForm PIXEL SIZE 40,20 RIGHT
   @157,105 SAY "Salida:" OF oForm PIXEL SIZE 30,20 RIGHT
   @172, 05 SAY "Entrada:" OF oForm PIXEL SIZE 40,20 RIGHT
   @172,105 SAY "Salida:" OF oForm PIXEL SIZE 30,20 RIGHT
   @157,175 SAY "Tipo Contratación:" OF oForm PIXEL SIZE 50,20 RIGHT
   @172,175 SAY "Valor Hora:" OF oForm PIXEL SIZE 50,20 RIGHT
   @187,005 SAY "Consumo interno:" OF oForm PIXEL SIZE 40,20 RIGHT
   @187,175 SAY "Descuento:" OF oForm PIXEL SIZE 30,12 RIGHT
   @187,235 SAY "Limite:" OF oForm PIXEL SIZE 30,12 RIGHT
   @202, 05 SAY "Talle Pantalon:" OF oForm PIXEL SIZE 50,12 RIGHT
   @202,105 SAY "Talle Rem./Chomba:" OF oForm PIXEL SIZE 50,12 RIGHT
   @202,205 SAY "Talle Campera/Buzo:" OF oForm PIXEL SIZE 50,12 RIGHT
   @217, 05 SAY "Contacto Emerg.:" OF oForm PIXEL SIZE 50,12 RIGHT
   @217,205 SAY "Tope adelanto:" OF oForm PIXEL SIZE 50,12 RIGHT


   @ 05, 50 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(lAlta)
   @ 05, 90 CHECKBOX oGet[21] VAR base:inactivo PROMPT "Inactivo" OF oForm PIXEL SIZE 30,12
   @ 20, 50 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(50))  
   @ 35, 50 GET oGet[3] VAR base:sector OF oForm PIXEL RIGHT PICTURE "999" SIZE 30,12;
                VALID(Buscar(oQrySec,oForm,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQrySec,oForm,oGet[3],oGet[4])) BITMAP "BUSC1"
   @ 35, 85 GET oGet[4] VAR cNomSec OF oForm PIXEL PICTURE "@!" SIZE 145,12 WHEN(.f.)
   @ 50, 50 GET oGet[5] VAR base:localidad PICTURE "@!"          OF oForm PIXEL
   @ 65, 50 GET oGet[6] VAR base:direccion PICTURE "@!"          OF oForm PIXEL
   @ 80, 50 GET oGet[7] VAR base:telefono  PICTURE "@!"          OF oForm PIXEL
   @ 95, 50 GET oGet[8] VAR base:mail      PICTURE "@!"          OF oForm PIXEL
   @110, 50 GET oGet[9] VAR base:sueldo    PICTURE "99999999.99" OF oForm PIXEL RIGHT
   @110,140 GET oGet[17] VAR base:cuil OF oForm PIXEL PICTURE "99-99999999-9" SIZE 55,12;
                VALID(ValidaCuit(base:cuil))
   @110,240 GET oGet[23] VAR base:fecing OF oForm PIXEL PICTURE "@D" VALID(Antiguedad(base:fecing,oGet[24]))
   @125,240 GET oGet[24] VAR manti OF oForm PIXEL WHEN(.F.) COLOR CLR_RED

   @125, 50 GET oGet[11] VAR base:catego OF oForm PIXEL RIGHT PICTURE "999" SIZE 30,12;
                VALID(Buscar(oQryCat,oForm,oGet[11],oGet[12]));
                ACTION (oGet[11]:cText:= 0, Buscar(oQryCat,oForm,oGet[11],oGet[12])) BITMAP "BUSC1"
   @125, 85 GET oGet[12] VAR cNomCat OF oForm PIXEL PICTURE "@!" SIZE 145,12 WHEN(.f.)   
   @ 15,235 IMAGE oGet[10] FILE mfoto OF oForm ON CLICK CambiaImagen(oGet[10],@mfoto);
     ADJUST PIXEL SIZE 75,75

   @155, 50 GET oGet[13] VAR base:hor_hab_desde1 PICTURE "99:99:99" OF oForm PIXEL CENTER
   @155,140 GET oGet[14] VAR base:hor_hab_hasta1 PICTURE "99:99:99" OF oForm PIXEL CENTER
   @170, 50 GET oGet[15] VAR base:hor_hab_desde2 PICTURE "99:99:99" OF oForm PIXEL CENTER
   @170,140 GET oGet[16] VAR base:hor_hab_hasta2 PICTURE "99:99:99" OF oForm PIXEL CENTER
   @155,230 GET oGet[18] VAR base:tipocontrato OF oForm PIXEL
   @170,230 GET oGet[29] VAR base:valorhora OF oForm PIXEL RIGHT PICTURE "9999999.99"
   @185, 50 COMBOBOX oGet[19] VAR base:consumo_por ITEMS aConsumo_por OF oForm PIXEL SIZE 100,12
   @185,210 GET oGet[20] VAR base:consumo_desc  OF oForm PIXEL RIGHT PICTURE "999.99" WHEN(base:consumo_por = 2)
   @185,265 GET oGet[22] VAR base:consumo_limite  OF oForm PIXEL RIGHT PICTURE "9999999.99"
   @200, 60 GET oGet[25] VAR base:tallepan  OF oForm PIXEL PICTURE "@S10"
   @200,160 GET oGet[26] VAR base:tallerem  OF oForm PIXEL PICTURE "@S10"
   @200,260 GET oGet[27] VAR base:tallebuz  OF oForm PIXEL PICTURE "@S10"
   @215, 60 GET oGet[28] VAR base:contacto  OF oForm PIXEL 
   @215,260 GET oGet[31] VAR base:tope_adelanto  OF oForm PIXEL PICTURE "9999999999.99" RIGHT

   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT Antiguedad(oQry:fecing,oGet[24])

IF !lRta
   RETURN nil
ENDIF
base:consumo_desc := IF(base:consumo_por=1,0,base:consumo_desc)  
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  IF UPPER(mfoto) <> UPPER(".\iconos\"+STRTRAN(STR(base:codigo,8)," ","0")+".jpg")     
     COPY FILE (mfoto) TO (".\iconos\"+STRTRAN(STR(base:codigo,8)," ","0")+".jpg")
  ENDIF
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
oQryBrw:Refresh()
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQryBrw:End()
RELEASE oQryBrw
  

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
LOCAL mrta := .f., oError, nNum := oQryBrw:codigo
IF oQryBrw:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)

CATCH oError
    ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


****************************************
** Cambiar foto 
STATIC FUNCTION CambiaImagen(oImg,mfoto)
LOCAL cFile
cFile := cGetFile( "Foto empleado (*.jpg)|*.jpg", "Elija la foto",, ".\iconos", .f. )
IF EMPTY(cFile)
   RETURN nil 
ENDIF
mfoto := cFile 
oImg:LoadImage( , cFile )
oImg:Refresh()
RETURN nil

*************************************************
STATIC function ReporteE( oRep, oBrw )

   COLUMN TITLE "Apellido y Nombre"  DATA oQryBrw:nombre SIZE 35 GRID
   COLUMN TITLE "Legajo"             DATA oQryBrw:codigo SIZE 08 GRID
   COLUMN TITLE "Observaciones"      DATA " " SIZE 45 GRID
   oRep:CellView()
return .t.


**********************************************************************************
** Emitir tarjeta para fichada
STATIC FUNCTION Tarjeta()
LOCAL oPrn, oFont1, oFont2, oFont3 , oFont4, oFont5, oFon, i, mbarra1,;
      nRow := 0, nCol := 0, n, m, nRowStep, nColStep, mlegajo, mnombre
// PrnSetSize( 2100, 1200 )     To adjust a different printer paper size!
   PRINT oPrn NAME "Tarjetas" PREVIEW      
      AddFontResource( "Bar25ifh.ttf" )
      DEFINE FONT oFont1 NAME "TAHOMA"          SIZE 0, 14  OF oPrn
      DEFINE FONT oFont2 NAME "Arial"           SIZE 0, 08  BOLD OF oPrn      
      DEFINE FONT oFont5 NAME "Bar 25i f HR"    SIZE 110, 30 OF oPrn      
      PAGE
         mlegajo := oQryBrw:codigo
         mnombre := oQryBrw:nombre
         mnombre := ALLTRIM(mnombre) + " - Legajo:"+STR(mlegajo,6)
         mbarra1 := STR(mlegajo,6)
         mbarra1 := STRTRAN(mbarra1," ","0") 
         mbarra1 := CodigoBarra( mbarra1)
         *** Tarjeta
         oPrn:CmBox( .5, .5, 6, 10 ) // Box arriba
         @ 1,7 PRINT TO oPrn IMAGE "logo.jpg" SIZE 2.9, 2.9 CM 
         @ 1, 1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                        SIZE 5.9,1 CM FONT oFont1 ALIGN "C"
         @ 2, 1 PRINT TO oPrn TEXT ALLTRIM(mnombre) ;
                        SIZE 5.9,.8 CM FONT oFont2
         oPrn:CmSay( 3, 1, mbarra1,oFont5)         
         @ 5, 1 PRINT TO oPrn TEXT "TARJETA DE FICHADA" ;
                        SIZE 8.7,1 CM FONT oFont2 ALIGN "R"
      ENDPAGE      
   ENDPRINT

   oFont1:End()      // Destroy the font object
   oFont2:End()      // Destroy the font object   
   oFont5:End()      // Destroy the font object
RETURN NIL

STATIC FUNCTION CodigoBarra( x )
LOCAL i, bar := {}, j := 0, bar1 := {}, cBarr := ""
   FOR i:= 33 to 122
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
   FOR i:= 161 to 170
       AADD(bar,CHR(i))
       AADD(bar1,STRTRAN(STR(j,2)," ","0"))
       j++
   NEXT i
FOR j := 1 TO LEN(x) STEP 2
    i := ASCAN(bar1,SUBSTR(x,j,2))
    cBarr := cBarr + bar[i]
NEXT j
RETURN "{"+cBarr+"}"


********************************************
** Liquidaciones de sueldos
STATIC FUNCtION Liquida()
LOCAL oQry, oDlg1, oFont, acor:= ARRAY(4), nMes:=MONTH(DATE()), nAno := YEAR(DATE()), mrta:=.F., oGet:= ARRAY(6),;
      oBot1, oBot2, oBot3, oBrwLiq, aLiqu, nSub := 0, dFecha := DATE(), oQryE , cDetalle := SPACE(30), oError

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_liqemp` ("+;
                           "`codemp` INT(6) DEFAULT 0 NOT NULL, "+;
                           "`nombre` VARCHAR(40) , "+;
                           "`sueldo` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;                           
                           "`extras` DECIMAL(12,2) DEFAULT 0 NOT NULL, "+;                           
                           "`total`  DECIMAL(12,2) DEFAULT 0 NOT NULL "+;                                                      
                           ") ENGINE=INNODB DEFAULT CHARSET=utf8") 
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_liqemp")
oApp:oServer:NextResult()
mrta := SiNoCancelar("Liquidación", "Indique a quien desea liquidar... "+;
     " Tenga en cuenta que si elige A Todos, solo se liquidará a los que estén activos...",;
      {"A todos","A "+LEFT(oQryBrw:nombre,9),"Cancelar"})
IF mrta = nil 
   RETURN nil 
ENDIF
IF mrta   
   oApp:oServer:Execute(" INSERT INTO transi_liqemp (SELECT codigo,nombre,sueldo,0 as extra,sueldo as total "+;
                        " FROM ge_"+oApp:cId+"emp_empleado WHERE inactivo IS FALSE ORDER BY nombre)")
   ELSE 
   oApp:oServer:Execute(" INSERT INTO transi_liqemp (SELECT codigo,nombre,sueldo,0 as extra,sueldo as total "+;
                        " FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = "+STR(oQryBrw:codigo)+" ORDER BY nombre)")   
ENDIF  
oQryE := oApp:oServer:Query("SELECT * FROM transi_liqemp")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Carga de Liquidación de Sueldos" FROM 03,15 TO 30,100
   acor := AcepCanc(oDlg1)       
   @ 07, 05 SAY "Periodo:"                OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "SubLiq.:"                OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 75 SAY "Fecha Imputación:"       OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 37, 05 SAY "Detalle:"                OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 07,175 BTNBMP oBot3 PROMPT "&Calcular Aguinaldo según liquidaciones" OF oDlg1 SIZE 65,30 ;
           ACTION (oGet[05]:cText := "Aguinaldo",oGet[03]:cText := -1, CalculaAguinaldo(oQryE),oBrwLiq:Refresh()) PIXEL 2007 CENTER NOBORDER


   @ 05, 60 GET oGet[01] VAR nMes     OF oDlg1 PIXEL PICTURE "99" VALID(nMes>0 .and. nMes < 13) RIGHT
   @ 05,100 GET oGet[02] VAR nAno     OF oDlg1 PIXEL PICTURE "9999" RIGHT
   @ 20, 60 GET oGet[03] VAR nSub     OF oDlg1 PIXEL PICTURE "99" RIGHT                       
   @ 20,130 GET oGet[04] VAR dFecha   OF oDlg1 PIXEL PICTURE "@D" CENTER  
   @ 35, 60 GET oGet[05] VAR cDetalle OF oDlg1 PIXEL PICTURE "@!"          

   @ 55, 05 XBROWSE oBrwLiq SIZE 315,100 pixel OF oDlg1 DATASOURCE oQryE ;
      HEADERS "Empleado", "Sueldo","Extras","Total";
      COLUMNS "nombre", "sueldo" ,"extras", "total";
      FOOTERS;
      CELL LINES NOBORDER UPDATE
   WITH OBJECT oBrwLiq 
      :aCols[2]:nFooterType := AGGR_SUM
      :aCols[3]:nFooterType := AGGR_SUM
      :aCols[4]:nFooterType := AGGR_SUM
      :aCols[2]:cEditPicture := "999999999.99"
      :aCols[3]:cEditPicture := "999999999.99"
      :aCols[4]:cEditPicture := "999999999.99"
      :nMoveType := 1
      :aCols[2]:nEditType := EDIT_GET
      :aCols[2]:bOnPostEdit := {|oCol, xVal, nKey | (CambiaValor(1,xval,oQryE,oBrwLiq,oGet[1]))}
      :aCols[3]:nEditType := EDIT_GET
      :aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | (CambiaValor(2,xval,oQryE,oBrwLiq,oGet[1]))}
      :MakeTotals()
      :CreateFromCode()
   END  
   PintaBrw(oBrwLiq,0)
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN  NIL
ENDIF
// Valido si hay liquidacion
IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_liqsueldo WHERE codemp IN (SELECT codemp FROM transi_liqemp) AND "+;
                      " mes = " + ClipValue2Sql(nMes)+;
                      " AND ano = " + ClipValue2Sql(nAno)+ " AND sub = "+ClipValue2Sql(nSub)):nRecCount > 0
   mrta := MsgNoYes("Existe ya esa liquidacion!"+chr(10)+"Desea reemplazarla por esta??","Atencion")
   IF !mrta
      RETURN nil
   ENDIF
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"emp_liqsueldo WHERE codemp IN (SELECT codemp FROM transi_liqemp) AND mes = " + ClipValue2Sql(nMes)+;
                      " AND ano = " + ClipValue2Sql(nAno)+ " AND sub = "+ClipValue2Sql(nSub))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_liqsueldo (mes,ano,sub,codemp,fecha,sueldo,extras,total,observa,usuario) "+;
                       " (SELECT "+ClipValue2Sql(nMes)+","+ ClipValue2Sql(nAno)+","+ClipValue2Sql(nSub)+",codemp,"+;
                       ClipValue2Sql(dFecha)+",sueldo,extras,total,"+ClipValue2Sql(cDetalle)+"," + ClipValue2Sql(oApp:usuario)+;
                       " FROM transi_liqemp)")
  oApp:oServer:CommitTransaction()
  MsgInfo("Proceso Terminado con Exito!","Atencion")
CATCH oError
    ValidaError(oError)
END TRY      

RETURN nil

*****************************************
** Cambiar pendientes
STATIC FUNCTION CambiaValor(n,nImporte,oQryE,oBrwLiq)
LOCAL base1 := oQryE:GetRowObj()
IF n = 1
   base1:sueldo:= nImporte
   base1:total := nImporte + base1:extras 
   ELSE 
   base1:extras:= nImporte
   base1:total := nImporte + base1:sueldo
ENDIF   
 
oQryE:lAppend:= .f.
oQryE:oRow := base1
oQryE:Save()
oBrwLiq:Refresh(.t.)
oBrwLiq:MakeTotals(oBrwLiq:aCols[4])
RETURN nil


FUNCTION Antiguedad(dFecha,oGet)
LOCAL oQ
IF EMPTY(dFecha)
   oGet:cText := SPACE(20)
   ELSE
   oQ := oApp:oServer:Query("SELECT TIMESTAMPDIFF(YEAR, "+ClipValue2Sql(dfecha)+", CURDATE()) AS anios, "+;
                            "TIMESTAMPDIFF(MONTH, "+ClipValue2Sql(dfecha)+", CURDATE()) % 12 AS meses")
   oGet:cText := STR(oQ:anios,2) + " Años "+STR(oQ:meses,2) + " Meses"
ENDIF
RETURN .t.    


STATIC FUNCTION CalculaAguinaldo(oQry)
LOCAL oDlg1, oFont, acor:= ARRAY(4), dDesde,dHasta, mrta:=.F.,oGet:= ARRAY(2),;
      oBot1, oBot2, aData, nCod , oQ, oBrw
IF MONTH(DATE())> 6
   dDesde := STR(YEAR(DATE()),4)+"/01"
   dHasta := STR(YEAR(DATE()),4)+"/06"
   ELSE 
   dDesde := STR(YEAR(DATE())-1,4)+"/07"
   dHasta := STR(YEAR(DATE())-1,4)+"/12"
ENDIF

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Calcular Aguinaldo Segun liquidaciones" FROM 03,15 TO 11,60
   acor := AcepCanc(oDlg1)       
   @ 07, 05 SAY "Desde Período:"                OF oDlg1 PIXEL SIZE 50,20 RIGHT 
   @ 22, 05 SAY "Hasta Período:"                OF oDlg1 PIXEL SIZE 50,20 RIGHT 

   @ 05, 60 GET oGet[01] VAR dDesde   OF oDlg1 PIXEL PICTURE "9999/99"
   @ 20, 60 GET oGet[02] VAR dHasta   OF oDlg1 PIXEL PICTURE "9999/99"
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Calcular" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN nil 
ENDIF
oQ := oApp:oServer:Query("SELECT res.codemp as codemp, COUNT(res.mes) as meses, MAX(res.sueldo) AS mejor,a.nombre as nombre, "+;
                         "MAX(res.sueldo)*.5*COUNT(res.mes)/6 AS aguinaldo,COUNT(res.mes)/6 AS proporcional "+;
                         " FROM ( "+;
                         "SELECT ano,mes,codemp,MAX(sueldo) AS sueldo FROM ge_"+oApp:cId+"emp_liqsueldo "+;
                         " WHERE CONCAT(ano,'/',LPAD(mes,2,'0')) >= "+ClipValue2Sql(dDesde)+;
                         " AND CONCAT(ano,'/',LPAD(mes,2,'0')) <= "+ClipValue2Sql(dHasta)+;
                         " GROUP BY codemp, ano, mes ) res "+;
                         " LEFT JOIN ge_"+oApp:cId+"emp_empleado a ON a.codigo = res.codemp "+;
                         " GROUP BY res.codemp")
mrta := .f.
DEFINE DIALOG oDlg1 TITLE "Resultado del Cálculo" FROM 03,15 TO 25,100
   acor := AcepCanc(oDlg1)       
   @ 05, 05 XBROWSE oBrw SIZE 315,100 pixel OF oDlg1 DATASOURCE oQ ;
      HEADERS "Empleado","Mejor Liq.", "Aguinaldo","Meses Trab.","Indice";
      COLUMNS "nombre", "mejor","aguinaldo" ,"meses", "proporcional";      
      FOOTERS;
      CELL LINES NOBORDER UPDATE
   WITH OBJECT oBrw 
      
      :aCols[2]:cEditPicture := "999999999.99"
      :aCols[3]:cEditPicture := "999999999.99"
      :aCols[4]:cEditPicture := "99"
      :aCols[5]:cEditPicture := "9.999"      
      :MakeTotals()
      :CreateFromCode()
   END  
   PintaBrw(oBrw,0)
   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Pasar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN nil 
ENDIF 
oQ:GoTop()
DO WHILE !oQ:Eof()
   oApp:oServer:Execute("UPDATE transi_liqemp SET sueldo = "+ClipValue2Sql(oQ:aguinaldo)+","+;
                        " total = " +ClipValue2Sql(oQ:aguinaldo)+" + extras "+;
                        " WHERE codemp = "+ClipValue2Sql(oQ:codemp))
   oQ:Skip()
ENDDO
oQry:Refresh()
RETURN nil