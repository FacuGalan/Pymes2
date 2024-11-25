#include "FiveWin.ch"
#include "tdolphin.ch"
#include "ribbon.ch"
#include "metro.ch"
// ----------------------------------------------//
// -----------  Variables Globales del PRG ------//
// ----------------------------------------------//

STATIC oClock, oDate, oKeyb, lMostrar_novedades
// ---------------------------------------------//
// ----------- Programa Principal --------------// 
// ---------------------------------------------//
//********************************************************************
// Proposito: Programa de control de farmacias
// .prg     : farmacon.prg
// Autor    : Cesar Gomez CM Soft
// Funciones: Main() - HazMenu()
***************************************************************************
// Funcion  : Main()
MEMVAR oApp, nCliente
FUNCTION Main()
LOCAL  oBar,oBar2, oQryParmatros, i, oMetro,oFontBarra
    IF IsExeRunning("BCN.EXE")
       MsgStop("La Aplicación ya esta en uso en esta PC","Error")
       QUIT
    ENDIF 
    lMostrar_novedades:=.f.    
    nCliente := 0
    oApp := TApplication():New()
    oApp:oServer := Conectar()
    TGet():lDisColors = .F.
    SetGetColorFocus(RGB( 238, 232, 170 ))
    SetDlgGradient( { { 1, RGB( 189, 216, 237 ), RGB( 237, 242, 248 ) } } )
    i := IF_SERIAL("27-0163848-435")
    // Principio del Programa
    // Autentificacion de Usuario
     IF !Ingreso()
        oApp:oServer:End()
        QUIT
     ENDIF 
     Procesando(.t.)
    oApp:cNombreEquipo := GetHostName()    
    CargarConfiguracion()

    // Defino la ventana principal tipo MDI (Ver funcion HAZMENU para ver menu)
    DEFINE BITMAP oApp:oBmp FILE ".\BITMAPS\LOGO.BMP" // Hace un bmp que se llame logo
    DEFINE FONT oFontBarra NAME "CALIBRI" SIZE 13,26 BOLD
    DEFINE WINDOW oApp:oWnd ;
       TITLE "Sistema de Gestion BCN - "+oApp:nomb_emp; 
       ICON oApp:oIco MDI COLOR CLR_RED,CLR_WHITE; && MENUINFO oApp:nItems
       MENU HazMenu(oApp:usuario,oApp:nItems)  
    // Defino la barra de botones con los accesos a las funciones del programa
    DEFINE RIBBONBAR oBar WINDOW oApp:oWnd PROMPT "Salir" HEIGHT 135 TOPMARGIN 25 
    
    oBar2 = TRBtn():New( 4, 0, 60, 20, "bitmaps\rbnmenu.bmp", { || llamametro()}, oBar,;
                         ,,,,,, .T., .T.,,,,,,/* "POPUP"*/, ,,,,,,,,,,,,, , nRGB( 125, 172, 215 ),;
                         nRGB( 65, 106, 189 ) ) 
    oApp:ancho:=oBar:nHeight
    ArmaBarra(oBar,oBar2)
    // Seteo la barra de estado con mi nombre y para que muestre la hora,
    // la fecha y el estado del teclado
    SET MESSAGE TO ("BCN Soft "+STR(YEAR(DATE()))) OF oApp:oWnd
    DEFINE MSGITEM  oApp:oMsg[1] OF oApp:oWnd:oMsgBar PROMPT "Usuario: "+oApp:usuario;
           SIZE 150 ;
           ACTION MsgInfo("Ud. accedio al sistema como:" + CHR(10) + ;
                           oApp:usuanom,"Usuario activo")
    //DEFINE TIMER oApp:oTimer  INTERVAL 10000 ACTION Pinguear(oApp:oServer,oApp:oWnd) OF oApp:oWnd  
  
    oApp:cNombreEquipo := GetHostName()    
    DEFINE TIMER oApp:oTimer INTERVAL 10000 ACTION Pinguear(oApp:oServer,oApp:oWnd) OF oApp:oWnd       
    DEFINE MSGITEM  oApp:oMsg[2] OF oApp:oWnd:oMsgBar PROMPT ;
           IF(oApp:prefijo=0,"Terminal administrativa","Punto de Venta: "+ STR(oApp:prefijo)) ;
           SIZE 150 ;
           ACTION MsgInfo("Punto de Venta: "+STR(oApp:prefijo)+ CHR(10) + ;
                           "Nombre del punto: "+ALLTRIM(oApp:nomcaja)+ CHR(10) + ;
                           "IP: "+oApp:cIP+ CHR(10) + ;
                           "Nombre del equipo: "+oApp:cNombreEquipo,"Punto de venta")  
   DEFINE MSGITEM  oApp:oMsg[3] OF oApp:oWnd:oMsgBar PROMPT "Número de cliente: "+ALLTRIM(STR(VAL(oApp:cId)));
           SIZE 150 
   DEFINE MSGITEM  oApp:oMsg[4] OF oApp:oWnd:oMsgBar PROMPT ;
                             "ATENCIÓN AL CLIENTE" FONT oFontBarra COLOR rgb(253,154,20);
          ACTION(VentanaAtencion());
           SIZE 300        
    // Activo la ventana principal con reloj fecha y teclado
    oApp:oWnd:oMsgBar:nHeight:= 30
    oApp:oWnd:oMsgBar:DateOn()
    oApp:oWnd:oMsgBar:ClockOn()
    oApp:oWnd:bPainted = { | hDC | BmpTiled( hDC, oApp:oWnd , oApp:oBmp ) }
    oApp:oWnd:bResized = { | hDC | BmpTiled( hDC, oApp:oWnd , oApp:oBmp ) }    
    Procesando(.f.)
    //ConsultaVencimiento(,.t.)
    ACTIVATE WINDOW oApp:oWnd MAXIMIZED   ON INIT (oApp:oTimer:Activate(),Alertas(.t.),IF(lMostrar_novedades,MostrarNovedades(),nil)) 
    RELEASE oApp:oBmp
    oApp:oServer:End()
RETURN NIL

// --------------------------------------------------------------------//
// ------------- Funcion men£ de la pantalla principal ----------------//
// --------------------------------------------------------------------//
STATIC FUNCTION HazMenu()
LOCAL i, oMenu, j, oMenuItem, nivel, nivel1, ult, oQry
MENU oMenu 2010
ENDMENU
RETURN oMenu


*********************************************************************
**VENTANA ATENCION AL CLIENTE
*********************************************************************
STATIC FUNCTION VentanaAtencion()
LOCAL oBot, oDlg, oSay, oSay2, oSay3, oSay4, oSay5, oBrw, aTabla := {}, oSer, oQry, oQry1, oFont, oFontGrande, oFontGrande2, oBot1,oImg1

GeneraQRAtencion()

DEFINE FONT oFont NAME "CALIBRI" SIZE 0,-13.5 BOLD
DEFINE FONT oFontGrande NAME "CALIBRI" SIZE 15,30 BOLD
DEFINE FONT oFontGrande2 NAME "CALIBRI" SIZE 15,30 BOLD
DEFINE DIALOG oDlg RESOURCE "ATENCION" OF oApp:oWnd TITLE "Panel de atención al cliente" FONT oFont
  oDlg:lHelpIcon := .f.

  REDEFINE SAY oSay  ID 101 OF oDlg  

  REDEFINE XIMAGE oImg1 ID 200 OF oDlg FILE "https://bcnresto.com/img/atencion.jpg"

  REDEFINE SAY oSay2 ID 102 OF oDlg

  IF .f. //oQryParametros:lWhatsapp_escr
      REDEFINE BUTTON ID 300 OF oDlg ;
      ACTION(ShellExecute( oDlg:hwnd,'open',"whatsapp://send?phone=5491128654468"))
  ELSE 
      REDEFINE BUTTON ID 300 OF oDlg ;
      ACTION(ShellExecute( oDlg:hwnd,'open',"https://api.whatsapp.com/send?phone=5491128654468"))
  ENDIF

  REDEFINE SAY oSay3 ID 103 OF oDlg FONT oFontGrande
  REDEFINE SAY oSay4 ID 104 OF oDlg FONT oFontGrande2 COLOR rgb(253,154,20)
  oSay4:SetText(ALLTRIM(STR(VAL(oApp:cId))))

  

  REDEFINE SAY oSay5 ID 105 OF oDlg

ACTIVATE DIALOG oDlg CENTER
RETURN nil

STATIC FUNCTION GeneraQRAtencion()
LOCAL cOrigen, cDestino

cOrigen:="https://api.whatsapp.com/send?phone=5491128654468"

cDestino:="atencion.bmp"

QRCode(cOrigen,cDestino)

Return NIL

DLL32 STATIC FUNCTION QRCode(cStr As STRING, cFile As STRING) AS LONG PASCAL ;
FROM "FastQRCode" LIB "QRCodelib.Dll"

// --------------------------------------------------------------------//
// ----- Funcion que carga los datos de configuracion del sistema -----//
// --------------------------------------------------------------------//
FUNCTION CargarConfiguracion()
LOCAL oQryParmetros, oSer, aPlacas, i, lExiste := .f., nPV := 1, oQryPun, oIni
    aPlacas := GetNetCardInfo()
    
    IF nCliente <> 0
       MsgGet("Punto a operar","Punto a operar",@nPV)      
       oApp:cIP := oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE caja = " + ClipValue2SQL(nPv)):ip
       lExiste := .t.
    ENDIF   
    FOR i := 1 TO LEN(aPlacas)
        IF lExiste
           EXIT 
        ENDIF   
        oApp:cIP :=  GetNetCardInfo()[i,1]
        IF oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2SQL(oApp:cIp)):RecCount > 0
           lExiste := .t.
           EXIT
           ELSE 
           IF oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ipbackup = " + ClipValue2SQL(oApp:cIp)):RecCount > 0
              lExiste := .t.
              oApp:cIp := oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ipbackup = " + ClipValue2SQL(oApp:cIp)):ip
              EXIT
           ENDIF   
        ENDIF 
    NEXT i 
    IF !FILE('terminal.ini')
       oIni := '[terminal]'+chr(10)+space(10)+'caja=0'+chr(10)
       memowrit( 'terminal.ini', oIni )
    ENDIF 
    IF !lExiste  
       MsgStop("La terminal no esta registrada para acceder al sistema "+CHR(10)+;
            "Contacte al proveedor","Atencion")
       MsgGet("Su terminal","Cliente:"+oApp:cId,@oApp:cIp)
       oApp:oServer:End()
       QUIT
    ENDIF
    oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2SQL(oApp:cIP))
    oApp:prefijo:= oQryPun:caja    
    oApp:nomcaja := oQryPun:nombre
    oApp:factura:= oQryPun:tipofac 
    oApp:tick80 := oQryPun:tick80
    oApp:usavales:= oQryPun:usavales

    // Abro el archivo que contiene el nombre de propietario y la secuencia
    oQryParmetros := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"parametros LIMIT 1")

    lMostrar_novedades := oQryPun:novedades    
    
    //DATOS GENERALES
    oApp:nomb_emp := ALLTRIM(oQryParmetros:nomb_emp)
    oApp:dire_emp := ALLTRIM(oQryParmetros:dire_emp)+","+ALLTRIM(oQryParmetros:loca_emp)
    oApp:cuit_emp := oQryParmetros:cuit_emp    
    oApp:tipo_iva := oQryParmetros:coniva
    oApp:inac_emp := oQryParmetros:inac_emp
    oApp:ingb_emp := oQryParmetros:ingb_emp

    // CONFIGURACION
    //General
    oApp:clave_autorizacion := oQryParmetros:claveadm
    oApp:usar_clave         := oQryParmetros:usaclave 
    oApp:dolar              := oQryParmetros:dolar
    oApp:cierre_turno       := oQryParmetros:cierreturno 
    oApp:unifica_cajas      := oQryParmetros:unificacaja

    //Ventas
    oApp:modifica_precios := oQryParmetros:modifpre
    oApp:usar_cuotas      := oQryParmetros:usacuotas
    oApp:modifica_descu   := oQryParmetros:modifdesc
    oApp:modifica_vend    := oQryParmetros:modifvend
    oApp:usar_dias_precio := oQryParmetros:usadiasv
    oApp:dias_precio      := oQryParmetros:diasv
    oApp:usar_dias_deuda  := oQryParmetros:usadiasdeu
    oApp:dias_deuda       := oQryParmetros:diasdeu
    oApp:usua_es_vendedor := oQryParmetros:usuavend
    oApp:percep_iibb      := oQryParmetros:percepiibb
    oApp:usar_puntos      := oQryParmetros:usapuntos 
    oApp:pesos_x_punto    := oQryParmetros:pesoxpunto
    oApp:usar_remitos     := oQryParmetros:usaremitos
    oApp:usar_tactil      := oQryParmetros:usatactil
    oApp:usar_limite_cred := oQryParmetros:usalimite

    //Pago a proveedores
    oApp:usar_reten_gan   := oQryParmetros:usaretgan
    oApp:usar_reten_iibb  := oQryParmetros:usaretiibb
    oApp:usar_reten_iva   := oQryParmetros:usaretiva 

    //Articulos
    oApp:usar_produccion  := oQryParmetros:usaproduccion 
    oApp:usar_bultos      := oQryParmetros:usabultos 
    oApp:usar_codpro      := oQryParmetros:usacodpro
    oApp:impcodpro        := oQryParmetros:impcodpro
    oApp:anticipoesvuelto := oQryParmetros:anticipoesvuelto

    //Presupuestos
    oApp:presudiscriva      := oQryParmetros:presudiscriva
    oApp:artievenmasiva     := oQryParmetros:artievenmasiva
    oApp:artievenendolar    := oQryParmetros:artievenendolar
    oApp:utilfija           := oQryParmetros:utilfija

    //Ventas con bultos
    oApp:usabultosventa     := oQryParmetros:usabultosventa   
    //Repartidores
    oApp:usareparto         := oQryParmetros:usareparto    

    oQryParmetros:End()
    oQryParmetros:=nil
    oSer := ConnectTo(2) 
    oApp:lDemo := oSer:Query("SELECT demo FROM config_clientes WHERE id = " + oApp:cId):demo
    oSer:End()
    oSer:= nil
    

RETURN nil 

// --------------------------------------------------------------------//
// ------------- Funcion que ejecuta las funciones del menu -----------//
// --------------------------------------------------------------------//


********************************************
** Validacion de Usuarios
STATIC FUNCTION ingreso()
LOCAL retorno := .f., aVar := ARRAY(2), oDlg, oBot := ARRAY(2),oGet := ARRAY(2),;
      oQry, oBit
IF FILE("BCN_administra.DLL") .and. nCliente > 0   

   ELSE
   ValidarVersion()   
ENDIF       

oApp:oServer:Execute("SET SESSION wait_timeout = 36600")
IF FILE("C:\FWH16\GENERAL\FUENTES\ABMART.PRG")
   aVar[1] :="MARKET      "
   aVar[2] :="1           "
   ELSE
   aVar[1] :="            "
   aVar[2] :="            "
ENDIF
DO WHILE .T.
DEFINE DIALOG oDlg RESOURCE "ACCESO" TITLE "Acceso al Sistema" FONT oApp:oFont
   oDlg:lHelpIcon := .f.
   REDEFINE XIMAGE oBit NAME "CANDA" ID 105 OF oDlg
   REDEFINE GET oGet[1] VAR aVar[1] ID 110 OF oDlg
   REDEFINE GET oGet[2] VAR aVar[2] ID 111 OF oDlg
   oGet[2]:lPassword := .t.
   REDEFINE BUTTON oBot[1] ID 102 ACTION (retorno := .t.,oDlg:end())
   REDEFINE BUTTON oBot[2] ID 103 ACTION (retorno := .f.,oDlg:end())
ACTIVATE DIALOG oDlg CENTER
IF !retorno   
   RETURN retorno
ENDIF
oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"usuarios WHERE usuario = " +;
       ClipValue2Sql(aVar[1]) + " AND clave = " + ClipValue2Sql(aVar[2]))
IF oQry:nRecCount > 0
   oApp:usuario := oQry:usuario
   oApp:usuanom := oQry:nombre
   retorno := .t.
   ELSE
   retorno := .f.
   MsgStop("Clave No Valida","Error")
   aVar[2]:= "            "
   LOOP
ENDIF   
oQry:End()
EXIT
ENDDO
RETURN retorno


//** Actualizar la version
STATIC FUNCTION ValidarVersion()
LOCAL oQryPun, oSer, oQry, aPlacas, cIP, lExiste:= .f., i, oIni
aPlacas := GetNetCardInfo()
FOR i := 1 TO LEN(aPlacas)
    cIP :=  GetNetCardInfo()[i,1]
    IF oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ip = " + ClipValue2SQL(cIp)):RecCount > 0
       lExiste := .t.
       EXIT
       ELSE 
       IF oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ipbackup = " + ClipValue2SQL(cIp)):RecCount > 0
          lExiste := .t.
          cIp := oApp:oServer:Query("SELECT ip FROM ge_"+oApp:cId+"punto WHERE ipbackup = " + ClipValue2SQL(cIp)):ip
          EXIT
       ENDIF   
    ENDIF 
NEXT i 
IF !lExiste  
   INI oIni FILE ".\terminal.ini"
   i := oIni:Get('terminal', 'caja') 
   MsgGet1("Error al ingresar","La terminal no esta registrada para acceder al sistema "+CHR(10)+;
        "Contacte al proveedor"+CHR(10)+"Cliente:"+oApp:cId+" Terminal:"+i+chr(10)+;
        "Copie y pegue este código y envíelo al Soporte Técnico de BCN Soft",@cIp)
   oApp:oServer:End()
   QUIT
ENDIF
INI oIni FILE ".\terminal.ini"
oIni:lAutoSet := .t.
oIni:Set( 'terminal', 'caja', STR(oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(cIP)):caja ))
oQryPun:= oApp:oServer:Query("SELECT version FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(cIP))
// Conectarse al general
oSer := ConnectTo(2)
oQry := oSer:Query("SELECT version_actual FROM config_packs  WHERE codigo = 'GE3' ")
IF(oQry:version_actual > oQryPun:version)    
   Actualizar(oQry:version_actual,'GE3',.t.,cIP)
ENDIF                   
oSer:End()
oSer:= nil
RETURN nil

*******************************************************
** Armar la barra de botones
STATIC FUNCTION ArmaBarra(oBar,oBar2)
LOCAL oQry, oBot, bBloque, nGrupo :=0, i := 2, oGr, aTab , aGrupo, cPadre, lProcesos,;
      oQryPun:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2SQL(oApp:cIp)),;
      cExcluidos:="('XXX'"
oApp:usua_es_supervisor := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo WHERE (usuario="+;
        ClipValue2SQL(oApp:usuario)+ " AND modulo = 'CREUSU' AND permisos = 'ABMRE') ORDER BY codigo"):nRecCount > 0      
IF oApp:usua_es_vendedor
   cExcluidos:= cExcluidos+",'VENDE'"
ENDIF
IF !oApp:usar_remitos
   cExcluidos:= cExcluidos+",'FACREM'"
   cExcluidos:= cExcluidos+",'MODREM'"
ENDIF
IF !oApp:usar_tactil
   cExcluidos:= cExcluidos+",'POS1'"
ENDIF	
IF !oApp:usar_produccion
   cExcluidos:= cExcluidos+",'PRODUCC'"
ENDIF
IF oQryPun:tipofac = 1
  cExcluidos:= cExcluidos+",'CierreX'"
  cExcluidos:= cExcluidos+",'CierreZ'"
ENDIF
IF !oApp:usareparto
  cExcluidos:= cExcluidos+",'ABMREPAR'"
  cExcluidos:= cExcluidos+",'ASIREPAR'"
  cExcluidos:= cExcluidos+",'LISASIREP'"
ENDIF
cExcluidos:= cExcluidos+")"
oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario="+;
        ClipValue2SQL(oApp:usuario)+ " AND codigo = padre AND modulo NOT IN "+cExcluidos+" ORDER BY codigo")
lProcesos := oApp:oServer:TableExist( "ge_"+oApp:cId+"procesos_per" )
aGrupo := oQry:FillArray(,{"codigo"})
oGr  := ARRAY(oQry:nRecCount+1)
aTab := ARRAY(oQry:nRecCount+1)
AFILL(aTab,.f.)
aTab[1] := .t.
ADD GROUP oGr[1] RIBBON oBar TO OPTION 1 PROMPT "Inicio" width 540 
oQry:GoTop()
DO WHILE !oQry:Eof()
   oBar:AddTab( ALLTRIM(oQry:etiqueta) )    
   ADD GROUP oGr[i] RIBBON oBar TO OPTION i PROMPT ALLTRIM(oQry:detalle) WIDTH 630
   oQry:Skip() 
   i++
ENDDO
@ 2,05 ADD BUTTON oBot PROMPT "Salir"  GROUP oGr[1] BITMAP "SALIR" ;   
    ROUND SIZE 80,85  TOOLTIP "Salir del Sistema" ACTION oApp:oWnd:End()
@ 2,95 ADD BUTTON oBot PROMPT "Calculadora"  GROUP oGr[1]  BITMAP "CALCU" ;   
    ROUND SIZE 80,85  TOOLTIP "Calculadora" ACTION WinExec("calc.exe")    
@ 2,185 ADD BUTTON oBot PROMPT "Acerca"  GROUP oGr[1]  BITMAP "Confirma" ;   
    ROUND SIZE 80,85  TOOLTIP "Acerca de Este Software" ACTION About()
@ 2,275 ADD BUTTON oBot PROMPT "Impresoras"  GROUP oGr[1]  BITMAP "IMPR" ;   
    ROUND SIZE 80,85  TOOLTIP "Configurar impresora" ACTION PrinterSetup()    
@ 2,365 ADD BUTTON oBot PROMPT "Agenda"  GROUP oGr[1]  BITMAP "VENT1" ;   
    ROUND SIZE 80,85  TOOLTIP "Agenda personalizada por usuario" ACTION Agenda()  
@ 2,455 ADD BUTTON oBot PROMPT "Certificados"  GROUP oGr[1]  BITMAP "CERTIFI" ;   
    ROUND SIZE 80,85  TOOLTIP "Generacion de certificados digitales" ACTION GeneraCert()  
@ 2,545 ADD BUTTON oBot PROMPT "Novedades"  GROUP oGr[1]  BITMAP "DEL_NOTIFICA" ;   
    ROUND SIZE 80,85  TOOLTIP "Nuevas funciones" ACTION MostrarNovedades()
IF lProcesos  .and. oApp:usua_es_supervisor 
   oGr[1]:setSize(730)
   @ 2,635 ADD BUTTON oBot PROMPT "Procesos"  GROUP oGr[1]  BITMAP "CONF" ;   
    ROUND SIZE 80,85  TOOLTIP "Procesos Personalizados" ACTION ProcesosPer()  
ENDIF    
oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo WHERE (usuario="+;
        ClipValue2SQL(oApp:usuario)+ ") AND codigo <> padre AND modulo NOT IN "+cExcluidos+" ORDER BY codigo")
i := 1
cPadre := "   "
DO WHILE !oQry:Eof()
   *IF oApp:oServer:Query("SELECT ("+ClipValue2SQL(oQry:modulo)+" NOT IN "+cExcluidos+") AS noesta"):noesta = 1 //!(ASCAN(oQry:modulo,aExcluidos) > 0)
       IF oQry:reporte = "S"
          bBloque := "{|| Reporte('"+ALLTRIM(oApp:usuario)+"','"+ALLTRIM(oQry:codigo)+"')}"
          ELSE
          bBloque := "{|| "+ALLTRIM(oQry:modulo)+"('"+oQry:permisos+"')}"
       ENDIF
       *bBloque := "{|| "+ALLTRIM(oQry:modulo)+"('"+oQry:permisos+"')}"
       bBloque := &bBloque
   i := IF(cPadre<>oQry:padre,1,i)
   nGrupo := ASCAN(aGrupo,oQry:padre) + 1
   IF nGrupo = 1
      cPadre := oQry:padre
      oQry:Skip()      
      LOOP
   ENDIF   
   aTab[nGrupo] := .t.
   @ 2,i ADD BUTTON oBot PROMPT RTRIM(oQry:etiqueta)  GROUP oGr[nGrupo]  BITMAP ALLTRIM(oQry:recurso);   
     ROUND SIZE 80,85  TOOLTIP ALLTRIM(oQry:detalle)
   i := i + 90
   oGr[nGrupo]:setSize(i)
   oBot:bAction := bBloque         
   cPadre := oQry:padre
   *ENDIF
   oQry:Skip()
ENDDO
nGrupo := 1
FOR i := 1 TO LEN(aTab)
    IF !aTab[i] 
       oBar:DeleteTab(nGrupo)
       ELSE
       nGrupo ++
    ENDIF
NEXT i
RETURN .t.


*********************************************************************
** Panel de novedades
*********************************************************************
FUNCTION MostrarNovedades()
LOCAL cTime := TIME(), oDlg, oSay, oBot1,oBot2,cUrl,cUrlMon,oQryNov,lRta:=.f.,;
      oImg1,oImg2,oFontGrande,cTitulo,oSer,nRow,oBrwNov,acor:=ARRAY(4),oBot:=array(2)

oSer := ConnectTo(2) 
oQryNov := oSer:Query("SELECT *,DATEDIFF(CURDATE(), fecha) AS dias_diferencia FROM pendientes WHERE estado = 4 AND tipo = 1 AND lMostrar_cli ORDER BY id")

DEFINE FONT oFontGrande NAME "TAHOMA" SIZE 15,22 BOLD 

DEFINE DIALOG oDlg TITLE "Novedades para vos!";
       FROM 05,15 TO 40,120 OF oApp:oWnd FONT oApp:oFont 
   oDlg:lHelpIcon := .f.


   @ 05, 05 SAY "Tenes nuevas soluciones para tu comercio!"    OF oDlg PIXEL SIZE 425,20 CENTER COLOR CLR_GREEN FONT oFontGrande
   @ 20, 05 XBROWSE oBrwNov DATASOURCE oQryNov SIZE 400,220 pixel OF oDlg  ;
           COLUMNS "Fecha","Nombre","descripcion_cli";
           HEADERS "Fecha","Nombre","Descripcion";
           FOOTERS ;
           SIZES 70,200,475 
   WITH OBJECT oBrwNov
      :CreateFromCode()
      :nRowHeight:=40
      PintaBrw(oBrwNov,0)
      :bClrStd := { || if(oQryNov:dias_diferencia < 7,{ CLR_BLACK, CLR_GREEN } ,If( oBrwNov:KeyNo() % 2 == 0, ;
                         { CLR_BLACK, RGB(193,221,255) }, ;
                         { CLR_BLACK, RGB(221,245,255) } )) }
   END


   acor := AcepCanc(oDlg)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Aceptar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Salir" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg CENTERED 

IF lRta 
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET novedades = FALSE WHERE ip = "+ClipValue2Sql(oApp:cIP))
ENDIF
RETURN nil

**************************************************
** Poner una imagen de fondo
*************************************************
STATIC FUNCTION BmpTiled( hDC, oWnd, oBmp )

   local nWidth := oWnd:nWidth(), nHeight := oWnd:nHeight()
   local nRow := 0, nCol := 0, n
   local nBmpWidth  := oBmp:nWidth(),  nBmpHeight := oBmp:nHeight()
    
   if oBmp:hBitmap == 0
      return nil
   endif
   nCol := nWidth /2 - nBmpWidth /2
   nRow := nHeight /2 - nBmpHeight /2
   nRow = 0
   PalBmpDraw( hDC, nRow, nCol, oBmp:hBitmap )
return nil


*********************************************************************
**ACERCA 
*********************************************************************
STATIC FUNCTION About()
LOCAL oBot, oDlg, oSay, oSay2, oBrw, aTabla := {}, oSer, oQry, oQry1, oFont, oBot1, lDesac := .f.,;
      lSoloExe:=.f., dFecVto,;
      oQryPun:= oApp:oServer:Query("SELECT version FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cIP))
// Conectarse al general
ConsultaVencimiento(@dFecVto,.f.)
oSer := ConnectTo(2)
oQry := oSer:Query("SELECT c.mail, c.nombre, c.vto, c.demo, c.pack, c.version,"+;
                         " v.nombre as packnom, d.fechavto, v.version_actual FROM config_clientes c "+;
                   " LEFT JOIN config_packs v ON v.codigo = c.pack "+;
                   " LEFT JOIN (SELECT id_cliente,MIN(fechavto) as fechavto "+;
                               " FROM config_deuda "+;
                               " WHERE id_cliente = "+oApp:cId+" AND pago = FALSE) d "+;
                               " ON c.id = d.id_cliente "+;
                   " WHERE id = " + oApp:cId)
oQry1 := oSer:Query("SELECT * FROM config_versiones WHERE cod_pack = " + ClipValue2Sql(oQry:pack) + " AND "+;
                    "version > " + ClipValue2Sql(oQry:version))
AADD( aTabla, {"Mail registro",oQry:mail})
AADD( aTabla, {"Registrado por",oQry:nombre})
AADD( aTabla, {"Codigo Pack",oQry:pack})
AADD( aTabla, {"Detalle Pack",oQry:packnom})
AADD( aTabla, {"Version",STR(oQryPun:version,10,2)})
AADD( aTabla, {"Tipo",IF(oQry:demo,"Demo","Licencia")})
AADD( aTabla, {"Vto Certificados AFIP ",DTOC(dFecVto)+if(dFecVto<date()," Vencido"," Quedan "+STR(dfecvto-date(),5)+" dias para renovar")})
IF oQry:demo
   AADD( aTabla, {"Vencimiento Demo",DTOC(oQry:vto)})
   ELSE 
   AADD( aTabla, {"Vencimiento Abono",DTOC(oQry:fechavto)})
ENDIF
IF ((oQry:version_actual > oQry:version) .or. (oQry:version_actual > oQryPun:version)) 
   AADD( aTabla, {"Estado","Desactualizado"})
   AADD( aTabla, {" "," "})
   AADD( aTabla, {"Novedades Versiones"," "})
   lDesac := .t.
   IF oQry:version_actual = oQry:version
      lSoloExe:=.t.
   ENDIF
ENDIF
DO WHILE !oQry1:Eof()
   AADD( aTabla, {"Version:"+STR(oQry1:version,10,2),oQry1:noticias})
   oQry1:Skip()
ENDDO
DEFINE FONT oFont NAME "CALIBRI" SIZE 0,-13.5 BOLD
DEFINE DIALOG oDlg RESOURCE "ACERCA" OF oApp:oWnd TITLE "Acerca de BCN GESTION PyMEs" FONT oFont
  oDlg:lHelpIcon := .f.
  REDEFINE SAY oSay  ID 100 OF oDlg 
  REDEFINE SAY oSay2 ID 104 OF oDlg
  REDEFINE BTNBMP ID 102 NAME "ICONO1" OF oDlg   ADJUST TRANSPARENT NOBORDER
  oSay:SetText(  "   &Sistema de GESTION PyMEs" +CHR(10)+CHR(10)+;
                 "   BCN Software - "+STR(YEAR(DATE()))+CHR(10)+CHR(10)+;
                 "   www.bcnsoft.com.ar"+CHR(10)+CHR(10)+;
                 "   Desarrollo de sistemas"+CHR(10)+CHR(10)+;
                 "   Licencia exclusiva de : "+chr(10)+;
                 "   "+ oApp:nomb_emp)
   oSay2:SetText("Todos los derechos reservados")
   REDEFINE XBROWSE oBrw ARRAY aTabla;
              COLUMNS 1,2;
              HEADERS "Concepto","Detalle";
              SIZES 150,250;
              ID 105 OF oDlg 
  PintaBrw(oBrw,2)
  oBrw:aCols[2]:bRClickData     := { |  | MemoEdit(oBrw:aCols[2]:bStrData) }


  REDEFINE BUTTON oBot  ID 101 OF oDlg ACTION  oDlg:End() 
  REDEFINE BUTTON oBot1 ID 103 OF oDlg ACTION  (Actualizar(oQry:version_actual,oQry:pack,lSoloExe),oDlg:End()) WHEN .f.
ACTIVATE DIALOG oDlg CENTER
RETURN nil


*********************************************************************
**Backup
*********************************************************************
FUNCTION Backup()
MsgInfo("El backup se realiza de manera automatica"+chr(10)+;
        "en los servidores de AWS","Atencion!")
RETURN NIL

STATIC FUNCTION Pinguear()
LOCAL oQry,oError, lCerrar := .f.
IF oApp:lPingueando 
   RETURN nil 
ENDIF 
oApp:lPingueando := .t.
IF oApp:oServer <> nil
   TRY 
       oQry := oApp:oServer:Query("SELECT 1")
       IF oQry:RecCount() = 0
          MsgWait("Reconectando con el servidor......")
          oApp:oServer:Ping()
          ELSE
          oApp:oWnd:SetMsg("Pingueando...")      
       ENDIF
    CATCH oError
      MsgStop("Se perdio la conexion con el servidor, SE CERRARA EL PROGRAMA"+CHR(10)+;
              "Verifique su acceso a la red antes de volver a entrar","Atencion!")
      oApp:oServer:End()
      lCerrar := .t.
    END TRY

ENDIF
*oApp:lEstado:= FILE(oApp:ruta) .OR. FILE("C:\FWH16\CEF\FUENTES\ABMART.PRG")
IF lCerrar
   QUIT
ENDIF
oApp:lPingueando := .f.
Alertas()
RETURN nil       


//----------------------------------------------------------------------------//
 CLASS TApplication
   DATA   cId        // Id del cliente para acceder a sus tablas de la base de datos
   DATA   oWnd       // Pantalla Principal
   DATA   oServer    // Conexion con el servidor de base de datos
   DATA   nItems     // Numero de item para el menu info
   DATA   oIco       // Icono de la aplicacion
   DATA   oMsg       // Barra de mensajes de la ventana principal
   DATA   aProce     // Arreglo que tiene los procedimientos a ejecutar x el menu
   DATA   aVentanas  // Arreglo que contiene las ventanas activas
   DATA   tamlet     // Tamaño de letra para recibos
   DATA   interlinea // Tamaño de interlineado para recibos
   DATA   oBmp
   DATA   oTimer     // Timer para pinguear
   DATA   cNombreEquipo  // Nombre de la PC
   DATA   oFont      //Fuente para los dialogos creados desde el codigo
   DATA   ancho      //ancho de la barra ribborn
   DATA   lPingueando//Determina si el programa esta haciendo ping
   DATA   oDlgP      //Dialgo para procesando...
   DATA   lDemo      // Esta en verdadero si el sistema es demo

   // DATOS DE LA EMPRESA
   DATA   nomb_emp   // Nombre de la empresa propietaria
   DATA   dire_emp   // Direccion          
   DATA   cuit_emp   // CUIT
   DATA   tipo_iva   // Condicion de iva del usuario
   DATA   ingb_emp   // Nro de ingresos brutos
   DATA   inac_emp   // Fecha de inicio de actividades

   // DATOS DEL PUNTO DE VENTA
   DATA   cIP            // Direccion MAC de la PC
   DATA   prefijo    // Punto de venta
   DATA   nomcaja

   // DATOS DEL USUARIO
   DATA   usuario    // Nombre del usuario activo
   DATA   usuanom    // Nombre del usuario activo (Ampliado)
   DATA   usua_es_supervisor // Si el usuario tiene acceso a crear usuarios

   // CONFIGURACION

   //General
   DATA clave_autorizacion // Clave que concede permisos en ciertos casos
   DATA usar_clave         // Boolean que dice si pedir la clave o no 
   DATA dolar              // Valor del dolar en pesos
   DATA cierre_turno       // Boolean que dice si usa el cierre de caja por turnos
   DATA unifica_cajas      // Boolean que dice si el cierre de turos se divide por cajas o no

   //Ventas
   DATA modifica_precios // Boolean que permite modificar precios en la venta
   DATA usar_cuotas      // Boolean que permite armar plan de pago en cuotas
   DATA modifica_descu   // Boolean que permite aplicar descuentos en la venta 
   DATA modifica_vend    // Boolean que permite modificar el vendedor en ventas
   DATA usar_dias_precio // Boolean que dice si valida los dias de vigencia de precios   
   DATA dias_precio      // Cantidad de dias permitidos despues de la modificacion del precio de un articulo para poder ser usado
   DATA usar_dias_deuda  // Boolean que dice si valida los dias de deuda del cliente
   DATA dias_deuda       // Cantidad de dias de atraso en la deuda permitidos para el cliente 
   DATA usua_es_vendedor // Boolean que dice si los usuarios son vendedores o se pueden administrar los vendedores
   DATA percep_iibb      // Boolean que dice si se aplican percepciones de IIBB
   DATA usar_puntos      // Boolean que permite el uso del sistema de puntos 
   DATA pesos_x_punto    // Cuantos pesos equivale un punto 
   DATA usar_remitos     // Boolean que permite usar remitos y factuarlos 
   DATA usar_tactil      // Boolean que permite usar el punto de venta tactil
   DATA usar_limite_cred // Boolean que dice si se controlan los limites de credito del cliente

   //Pago a proveedores
   DATA usar_reten_gan   // Boolean que dice si hace retenciones de ganancias
   DATA usar_reten_iibb  // Boolean que dice si hace retenciones de IIBB
   DATA usar_reten_iva   // Boolean que dice si hace retenciones de IVA

   //Articulos

   DATA usar_produccion  // Boolean que habilita los modulos de produccion de articulos
   DATA usar_bultos      // Boolean que habilita las casillas de unidades por bulto y precio
   DATA usar_codpro      // Boolean que habilita la casilla de codigo de proveedor
   DATA impcodpro        // Boolean que habilita la la impresion de codigos de proveedor en factura
   
   DATA factura          // Tipo de facturacion: 1 Factura Electronica, 2: Controlador Fiscal

   DATA tick80           // Usa impresora de ticket de 80 mm
   DATA usavales         // Usa vales de clientes               
   DATA anticipoesvuelto // Considera el anticipo como vuelto en ventas
   DATA presudiscriva    // Presupuestos discriminan IVA
   DATA artievenmasiva   // Articulo eventual precio mas iva
   DATA artievenendolar  // Articulo eventual precio en dolares
   DATA cDestinoMail     // Mail para enviar formularios a clientes y proveedores
   DATA utilfija         // Mantener la utilidad cuando se cambian manualmento los precios de articulos
   DATA usabultosventa   // Pide bultos al hacer la venta por factura grande
   DATA usareparto       // Usar sistema de reparto con hoja de ruta



   METHOD New() CONSTRUCTOR


ENDCLASS

//----------------------------------------------------------------//

METHOD New() CLASS TApplication

   SET DATE FORMAT "DD/MM/YYYY"
   SET DELETE ON
   SET CONFIRM ON
   SET SOFTSEEK ON
   SET 3DLOOK ON
   SetHandleCount(100)
   SetBalloon(.t.)
   D_SetCaseSensitive(.t.)
   HB_LANGSELECT( 'ESWIN' )
   DEFINE ICON ::oIco RESOURCE "socie"
   // Inicializacion de valores
   ::lDemo              := .f.
   ::cId                := SPACE(6)
   ::oMsg               := ARRAY(4)
   ::usuario            := SPACE(10)
   ::usuanom            := "NADIE"
   ::usua_es_supervisor := .f.
   ::ancho              := 0
   ::aProce             := {}
   ::prefijo            := 0
   ::nomcaja            := " "
   ::lPingueando        := .f.
   ::aVentanas          := {}
   ::nomb_emp           := ""
   ::dire_emp           := ""
   ::cuit_emp           := ""
   ::tipo_iva           := 1
   ::inac_emp           := CTOD("  /  /    ")
   ::ingb_emp           := ""
   ::tamLet             := 30
   ::interlinea         := 1
   ::clave_autorizacion := ""
   ::usar_clave         := .f.
   ::dolar              := 0
   ::cierre_turno       := .f.
   ::unifica_cajas      := .f.
   ::modifica_precios   := .f.
   ::usar_cuotas        := .f.
   ::modifica_descu     := .f.
   ::modifica_vend      := .f.
   ::usar_dias_precio   := .f.
   ::dias_precio        := 0
   ::usar_dias_deuda    :=.f.
   ::dias_deuda         := 0
   ::usua_es_vendedor   := .f.
   ::percep_iibb        := .f.
   ::usar_puntos        := .f.
   ::pesos_x_punto      := 0
   ::usar_remitos       := .f.
   ::usar_tactil        := .f.
   ::usar_limite_cred   := 0
   ::usar_reten_gan     := .f.
   ::usar_reten_iibb    := .f.
   ::usar_reten_iva     := .f.
   ::usar_produccion    := .f. 
   ::usar_bultos        := .f. 
   ::usar_codpro        := .f.
   ::factura            := 1
   ::anticipoesvuelto   := .f.
   ::presudiscriva      := .f.
   ::artievenmasiva     := .f.
   ::artievenendolar    := .f.
   ::cDestinoMail       := ""
   ::usabultosventa     := .f.
   ::usareparto         := .f.


   DEFINE FONT ::oFont NAME "TAHOMA" SIZE 0,-11.5   

return Self

DLL32 FUNCTION BWCCRegister( hInst AS LONG) AS WORD PASCAL LIB "BWCC32.DLL" 

function llamametro()

   local oMetro, oQryMen, aModulos, aPermisos, lRta:=.T.
   oQryMen:= oApp:oServer:Query("SELECT modulo,permisos FROM ge_"+oApp:cId+"menu_nuevo WHERE (modulo = 'ARTIC' "+;
                                                                          "OR modulo = 'COMPRAS' "+;
                                                                          "OR modulo = 'POS1' "+;
                                                                          "OR modulo = 'COBRAN' "+;
                                                                          "OR modulo = 'ORDPAG' "+;
                                                                          "OR modulo = 'PLANIL') "+;
                                                                          "AND usuario = " +ClipValue2Sql(oApp:usuario)+" "+;
                                "ORDER BY modulo")

   DEFINE METRO oMetro ;
      TITLE "Accesos Directos";
      BACKGROUND "BITMAPS\FONDO.bmp"
      
   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Articulos" COLOR CLR_WHITE, RGB( 70, 23, 80) ;
      IMAGE "BITMAPS\ARTICU1.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('ARTIC',1)>0,Artic(oQryMen:permisos),Cartel()))

   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Compras" COLOR CLR_WHITE, CLR_BLUE ;
      IMAGE "BITMAPS\COMP1.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('COMPRAS',1)>0,Compras(oQryMen:permisos),Cartel())) LARGE
   
   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Venta" COLOR CLR_WHITE, RGB(176, 30, 0 )  ;
      IMAGE "BITMAPS\VENT1.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('POS1',1)>0,Pos1(oQryMen:permisos),Cartel()))  LARGE

   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Cobro" COLOR CLR_WHITE, RGB( 240, 150, 9) ;
      IMAGE "BITMAPS\COBRO.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('COBRAN',1)>0,Cobran(oQryMen:permisos),Cartel())) 
    
   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Pagos" COLOR CLR_WHITE, RGB( 60, 145 , 654) ;
      IMAGE "BITMAPS\PAGOS1.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('ORDPAG',1)>0,Ordpag(oQryMen:permisos),Cartel())) 
      
   DEFINE METROBUTTON OF oMetro ;
      PROMPT "Etiquetas" COLOR CLR_WHITE, RGB(0, 74, 0)  ;
      IMAGE "BITMAPS\ETIQUE1.bmp" ACTION (oMetro:End(),oQryMen:GoTop(),IF(oQryMen:Seek('PLANIL',1)>0,Planil(oQryMen:permisos),Cartel())) LARGE
 
  

   ACTIVATE METRO oMetro

RETURN nil

STATIC FUNCTION Cartel()
LOCAL oDlg, oBot
DEFINE DIALOG oDlg TITLE "¡ATENCIÓN!" OF oApp:oWnd FROM 05,05 TO 10,45
 oDlg:lHelpIcon := .f.
 @ 05,05 SAY "El usuario logeado no tiene el acceso permitido a este modulo" PIXEL 
 @ 20,60 BUTTON oBot PROMPT "OK" ACTION (oDlg:End()) PIXEL SIZE 30,12
ACTIVATE DIALOG oDlg CENTER
return nil

REQUEST HB_LANG_ESWIN
REQUEST HB_CODEPAGE_ESMWIN