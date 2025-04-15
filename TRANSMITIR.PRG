#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** TRANSMITIR A BALANZA KRETS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE Transmitir(cPermisos)
LOCAL oBar, hHand, oGetSeek, cSeek := SPACE(50), oPop2
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQry:= oApp:oServer:Query("SELECT a.codigo as codigo,RIGHT(a.codigo,5) as plu,LEFT(a.nombre,26) as nombre,"+;
	                            " a.depto as depto, d.nombre as nomdep, a.rubro as rubro, r.nombre as nomrub,"+;
	                            " a.precioven as precio,a.fecmod as fecmod,IF(a.pesable,'P','N') as pesable  "+;
                                " FROM ge_"+oApp:cId+"articu a "+;
                                " LEFT JOIN ge_"+oApp:cId+"deptos d ON d.codigo = a.depto "+;
                                " LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro "+;
                                " WHERE a.codigo >= 2000000 AND a.codigo <= 3000000"+;
                                " AND a.nosale IS FALSE ORDER BY a.nombre")
  DEFINE WINDOW oWnd1 MDICHILD TITLE "Transmision de precios a Balanza";
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Transmitir precios a la Balanza"  ;
            ACTION Transmite();
            PROMPT "Transmitir" TOP WHEN(oQry:RecCount()>0 .and. "A"$cPermisos)          
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Articulos de Balanza",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "CONF" OF oBar ;
            TOOLTIP "Configurar Conexion con Balanza"  ;
            ACTION ConfigurarBal();
            PROMPT "Conexion" TOP WHEN(oQry:RecCount()>0 .AND. "B"$cPermisos)   
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Articulos"  ;
            ACTION (Filtrar(),oBrw:Refresh()) MENU oPop2;
            PROMPT "Filtrar" TOP              
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1     
         REDEFINE XBROWSE oBrw DATASOURCE oQry;
                  COLUMNS "codigo","plu","nombre","precio","pesable","nomrub","nomdep","fecmod";
                  HEADERS "Código art.","PLU","Nombre","Precio","Pesable","Rubro","Departamento","Fecha Cambio";
                  SIZES 90,70,230,70,70,100,100,70;
                  ID 111 OF oDlg AUTOSORT 
         REDEFINE GET oGetSeek VAR oBrw:cSeek ID 113 OF oDlg
         PintaBrw(oBrw,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE     
     //oBrw:SetDolphin(oQry,.f.,.t.)
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT (oDlg:Move(0,0)) VALID(oWnd1:End())
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

//Generar archivo para enviar a la balanza y lanzar programa JDataGate
STATIC FUNCTION Transmite()
LOCAL cTexto := '', nNro, cPath, cTitulo, aDepto1 := {}, aDepto2 := {}, aRubro1 := {}, aRubro2 := {}, aRubro3 := {}, i
oQry:GoTop()
DO WHILE !oQry:Eof()
   IF ASCAN(aDepto1,oQry:depto) = 0
      AADD(aDepto1,oQry:depto)
      AADD(aDepto2,oQry:nomdep)
   ENDIF   
   IF ASCAN(aRubro1,oQry:rubro) = 0
      AADD(aRubro1,oQry:rubro)
      AADD(aRubro2,oQry:nomrub)
      AADD(aRubro3,oQry:depto)
   ENDIF   
   oQry:Skip()
ENDDO
USE BCNBALAN
nNro := BCNBALAN->nro 
cPath := ALLTRIM(BCNBALAN->camino)
cTitulo := BCNBALAN->texto
FOR i := 1 TO LEN(aDepto1)
    cTexto := cTexto + "C"+;
             STRTRAN(STR(nNro,2),' ','0')+; //Nro de balanza
             "2003"+;
             STRTRAN(STR(aDepto1[i],3),' ','0')+; //Nro de departamento
             LEFT(aDepto2[i],16)+; //Nombre depto             
             CHR(10)+CHR(13)
NEXT i

//Transmitir Articulos
oQry:GoTop()
DO WHILE !oQry:Eof()
   cTexto := cTexto + "C"+;
             STRTRAN(STR(nNro,2),' ','0')+; //Nro de balanza
             "2005"+; //Nro de comando de envio de datos de PLU
             "0"+oQry:plu + ; // Nro de PLU
             STRTRAN(STR(oQry:depto,3),' ','0')+; //Nro de departamento
             STRTRAN(STR(0,3),' ','0')+; //Nro de Rubro
             oQry:nombre +; //Nombre del producto 
             cTitulo     +; //Titulo de etiqueta
             oQry:plu + ; // Codigo de PLU (igual a nro)
             oQry:pesable + ; // Si es pesable o no
             '0000000' +; //Texto fijo todos ceros
             STRTRAN(STR(oQry:precio,6),' ','0')+; //Precio del producto
             '000000' +; //Texto fijo todos ceros
             '000002' +; //Texto fijo que indica que no use decimales
             '0000000000000000000000010000000000000000'+; //Texto fijo que indica que use etiqueta 1
             CHR(10)+CHR(13)   
   oQry:Skip()
ENDDO
MemoWrit2(cPath+"INFO.JDG",cTexto) //Grabo el archivo de info a enviar
WaitRun(cPath+'JDataGate.exe', 0)  //Lanzo el programa de comunicacion

RETURN nil 


****************************************FILTRADO**********************
STATIC FUNCTION Filtrar( )
   LOCAL oFilt,oGet:=ARRAY(7),oBot:=ARRAY(2),acor:=ARRAY(4),vProv:=0,cNomProv:=SPACE(30),;
   vDesde:=CTOD("01/01/2000"),vHasta:=DATE(),oQryPro,lRta:=.f.,oFont,cWhere,;
   vPDesde:=DATE(),vPHasta := CTOD("01/01/2100") , nEstado := 1, aEstado := {"Solo Pendientes","Todos"}
   

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

                       
    DEFINE DIALOG oFilt TITLE "Filtrado de Precios";
           FROM 05,15 TO 11,70 OF oWnd1 FONT oFont
              
       @ 07, 05 SAY "Desde:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 07, 75 SAY "Hasta:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
              
       @ 05, 60 GET oGet[03] VAR vDesde    OF oFilt PIXEL PICTURE "@D" CENTER                      
       @ 05,130 GET oGet[04] VAR vHasta    OF oFilt PIXEL PICTURE "@D" CENTER  
       
          
       acor := AcepCanc(oFilt)
       @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .t.), oFilt:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oFilt CENTER 

    IF !lRta
        RETURN nil
    ENDIF    


    cWhere = " 1=1 " + ;
          + "" + IF(EMPTY(Vdesde),""," and a.fecmod >=" + ClipValue2SQL(Vdesde) + "") ; 
          + "" + IF(EMPTY(Vhasta),""," and a.fecmod <=" + ClipValue2SQL(Vhasta) + "") ;
          + "" + " AND a.codigo >= 2000000 AND a.codigo <= 3000000"+;
                                " AND a.nosale IS FALSE "

oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oQry:Refresh()
oBrw:Refresh()
RETURN nil


******************************************************
** Configurar Conexion con balanza 
STATIC FUNCTION ConfigurarBal()
LOCAL nNro, cPath, cTexto, oFilt, oFont, oGet := ARRAY(3), acor, oBot := ARRAY(2), lRta
IF !FILE('.\BCNBALAN.DBF')
   DBCREATE('BCNBALAN',;
   	{ {"nro","N",2,0} ,;
   	  {"camino","C",100,0} ,;
   	  {"texto","C",26,0} ;
   	} ) 
   use BCNBALAN 
   BCNBALAN->(dbappend(.T.))
   REPLACE BCNBALAN->nro WITH 1, BCNBALAN->camino WITH "C:\JDataGate\kSolutions\DataGate",;
   BCNBALAN->texto WITH oApp:nomb_emp
   nNro := 1
   cPath := "C:\JDataGate\kSolutions\DataGate" 
   cTexto := LEFT(oApp:nomb_emp,26)
   ELSE 
   use BCNBALAN 
   nNro := BCNBALAN->nro
   cPath := BCNBALAN->camino
   cTexto := BCNBALAN->texto
ENDIF 

DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.
    lRta := .f.                      
    DEFINE DIALOG oFilt TITLE "Configuracion datos comunicacion";
           FROM 05,15 TO 14,70 OF oWnd1 FONT oFont
              
       @ 07, 05 SAY "Balanza Nro:"            OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 22, 05 SAY "Path JDataGate:"         OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 37, 05 SAY "Texto Etiquetas:"        OF oFilt PIXEL SIZE 50,20 RIGHT
              
       @ 05, 60 GET oGet[01] VAR nNro  PICTURE "99"  OF oFilt PIXEL RIGHT
       @ 20, 60 GET oGet[02] VAR cPath ACTION (oGet[2]:cText := cGetFile( "Archivo JDataGate|JDataGate.exe|Todos los Archivos (*.*)|*.*", "Seleccione Carpeta",, cPath, .f. ));
             OF oFilt PICTURE "@S30" PIXEL SIZE 95,12 BITMAP "BUSC1"
       @ 35, 60 GET oGet[03] VAR cTexto OF oFilt PIXEL
       
          
       acor := AcepCanc(oFilt)
       @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .t.), oFilt:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oFilt CENTER 

    IF !lRta
        CLOSE BCNBALAN
        RETURN nil        
    ENDIF
    IF !'JDataGate.exe'$cPath
       MsgInfo('El archivo no fue encontrado','Error')
       LOOP
       ELSE
       cPath := STRTRAN(cPath,'JDataGate.exe','')
    ENDIF
    EXIT
ENDDO
REPLACE BCNBALAN->nro WITH nNro, BCNBALAN->camino WITH cPath, BCNBALAN->texto WITH cTexto
CLOSE BCNBALAN
RETURN NIL


static function MemoWrit2(cFile, cText)
LOCAL Han := FCreate(cFile), nBytes

nBytes := FWRITE(Han,cText,LEN(cText))   
FClose(Han)
RETURN nil