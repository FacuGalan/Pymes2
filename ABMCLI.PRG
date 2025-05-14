#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"
#include "Report.ch"
*************************************************
** CLIENTES
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana, oQryF, oBrw1
PROCEDURE Clientes(cPermisos)
   LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol, oGetSeek, cSeek := SPACE(50)
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
   AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE CODIGO > 1 ORDER BY NOMBRE ")
   // Defino el dialogo tomado del recurso ABM
   oApp:oIco:Refresh()
    DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Clientes" ;
       OF oApp:oWnd NOZOOM ICON oApp:oIco
      DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
      DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
        TOOLTIP "Agregar Registro"  ;
        ACTION Formu( .t. );
        PROMPT "Alta" TOP WHEN("A"$cPermisos)
      DEFINE BUTTON RESOURCE "MODI" OF oBar ;
        TOOLTIP "Modificar Registro"  ;
        ACTION Formu( .f. );
        PROMPT "Modi" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
      DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
        TOOLTIP "Eliminar Registro"  ;
        ACTION Baja( );
        PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
        DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
      TOOLTIP "Exportar a Excel" ;
        ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .AND. "E"$cPermisos);
        PROMPT "Excel" TOP
      DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
        TOOLTIP "Imprimir Planilla"  ;
        ACTION oBrw:Report("Reporte de Clientes",.T.,.F.);
        PROMPT "Impr." TOP WHEN(oQry:RecCount()>0 .AND. "R"$cPermisos)
      DEFINE BUTTON RESOURCE "FILT" OF oBar ;
        TOOLTIP "Filtrar Registros"  ;
        ACTION (Filt(), oBrw:Refresh());
        PROMPT "Filtra" TOP
      IF oApp:usar_puntos
        DEFINE BUTTON RESOURCE "TRANSF" OF oBar ;
          TOOLTIP "Canjear puntos acumulados"  ;
          ACTION (CanjearPuntos(), oBrw:Refresh());
          PROMPT "Canje" TOP
        DEFINE BUTTON RESOURCE "REPVEN" OF oBar ;
          TOOLTIP "Reporte de Canjes"  ;
          ACTION CanjearReport();
          PROMPT "Reporte" TOP  
      ENDIF
      IF !oApp:usua_es_vendedor
        DEFINE BUTTON RESOURCE "GRAFVEN" OF oBar ;
          TOOLTIP "Reporte de Clientes por vendedor"  ;
          ACTION ReporteCliexVend();
          PROMPT "Rep.x Vend." TOP
      ENDIF
      DEFINE BUTTON RESOURCE "FICH" OF oBar ;
        TOOLTIP "Ficha de Seguimiento"  ;
        ACTION (Fich(), oBrw:Refresh());
        PROMPT "Ficha" TOP WHEN("A"$cPermisos  .or. "M"$cPermisos)
      DEFINE BUTTON RESOURCE "BACKU" OF oBar ;
        TOOLTIP "Importar Registros"  ;
        ACTION (Importar(), oBrw:Refresh());
        PROMPT "Importar" TOP WHEN("A"$cPermisos)
      // Este boton cierra la aplicacion
      DEFINE BUTTON RESOURCE "SALE" OF oBar;
        TOOLTIP "Cerrar Ventana" ;
        ACTION oWnd1:End();
      PROMPT "Sale [Esc]" TOP
      oWnd1:bGotFocus := { || oDlg:SetFocus}
      oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
      
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
      REDEFINE XBROWSE oBrw DATASOURCE oQry;
         COLUMNS "codigo","nombre","alias","dni", "CUIT", "Direccion","localidad","Telefono";
         HEADERS "Codigo","Nombre y Apellido","Alias","DNI", "CUIT", "Direccion","Localidad","Telefono";
         SIZES 100,290,60,60,90,210,200;
         ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     
      REDEFINE GET oGetSeek VAR cSeek ID 113 OF oDlg
      oQry:bOnChangePage := {|| oBrw:Refresh() }
      //oBrw:SetDolphin(oQry,.f.,.t.)
      PintaBrw(oBrw,7)
      oDlg:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
      oGetSeek:bKeyDown := { |nKey,nFlag| FiltraArt(oQry, oGetSeek, oBrw, nKey) }
      // Activo el dialogo y al iniciar muevo a 0,0
      ACTIVATE DIALOG oDlg NOWAIT ON INIT (oGetSeek:SetFocus(),oDlg:Move(0,0)) VALID( oWnd1:End() )
      ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
 
RETURN


*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta)
LOCAL oGet:=ARRAY(27), oBot1, oBot2, oBot3, oDlg1,base,oError, ;
      aListas:={"Lista 1","Lista 2"},cLisPre:="SIN LISTA ESPECIAL"+SPACE(31),;
      oQryLisPre:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre"),;
      aEstado := {"Activo","Inactivo"}, nEstado, nCuit := 0, cObserva := "",;
      atipoiva  := {;
"1 IVA Responsable Inscripto",;
"2 IVA Responsable no Inscripto",;
"3 IVA no Responsable",;
"4 IVA Sujeto Exento",;
"5 Consumidor Final",;
"6 Responsable Monotributo",;
"7 Sujeto no Categorizado",;
"8 Proveedor del Exterior",;
"9 Cliente del Exterior",;
"10  IVA Liberado – Ley Nº 19.640",;
"11  IVA Responsable Inscripto – Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social",;
"15  IVA NO Alcanzado"},;
      mrta := .f., aCor,cNomVen:=SPACE(30),;
      oQryVen:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores"), lCambiar := .t.



IF lAlta
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"clientes") 
   base:coniva:=5
   base:fecing:=DATE()
   base:fecult:=DATE()
   base:fecnac:=DATE()
   base:lispre:=1
   nEstado := 1
   ELSE
   base := oQry:GetRowObj()   
   nEstado := IF(base:zona = "2",2,1)
   oQry:lAppend := .f.   
   oQryVen:GoTop()
   IF oQryVen:Seek(base:vendedor,1) > 0
      cNomVen:= oQryVen:nombre
   ENDIF
   IF base:lispreesp > 0
     oQryLisPre:GoTop()
     IF oQryLisPre:Seek(base:lispreesp,1) > 0
        cLisPre:= oQryLisPre:nombre
     ENDIF
    ENDIF
    cObserva := oApp:oServer:Query("SELECT observa FROM ge_"+oApp:cId+"cliobs WHERE fecha is null AND codcli = "+STR(base:codigo)):observa
ENDIF

DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE IF(lAlta,"Alta","Modificacion") + " de Clientes" FROM 05,10 TO 37,105 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Codigo:"           OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 07,180 SAY "Alias:"            OF oDlg1 PIXEL SIZE 30,12 RIGHT
   @ 22, 05 SAY "Nombre:"           OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Direccion:"        OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 52, 05 SAY "Telefono:"         OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 67, 05 SAY "Localidad:"        OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 67,175 SAY "Codigo postal:"    OF oDlg1 PIXEL SIZE 40,12 RIGHT
   *@ 82, 80 SAY "Zona:"            OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 82, 05 SAY "Fecha nac:"        OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 82, 95 SAY "Fecha ingreso:"    OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 97, 05 SAY "Fecha ult. op.:"   OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 97, 95 SAY "Limite de cedito:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @112, 05 SAY "Descto. general:"  OF oDlg1 PIXEL SIZE 50,12 RIGHT   
   @127, 05 SAY "C.U.I.T.:"         OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @127, 95 SAY "D.N.I.:"           OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @142, 05 SAY "Condicion IVA:"    OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @157, 05 SAY "Mail:"             OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @172, 05 SAY "Vendedor:"         OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @187, 05 SAY "Lista de precios:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @202, 05 SAY "Lista especial:"   OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @113,225 SAY "Observaciones:"    OF oDlg1 PIXEL SIZE 50,12
   IF lAlta
      @07,290 SAY "CUIT Afip:"   OF oDlg1 PIXEL SIZE 28,12 RIGHT
      @05,320 GET oGet[24] VAR nCuit PICTURE "99999999999"   OF oDlg1 PIXEL SIZE 45,12 RIGHT;
      VALID(ConsultaCuit(nCuit,oGet,{2,3,5,11,13},@lCambiar))
   ENDIF
   
   @ 05, 60 GET oGet[01] VAR base:codigo PICTURE "99999" OF oDlg1 PIXEL WHEN(.F.)
   @ 05,212 GET oGet[27] VAR base:alias  OF oDlg1 PIXEL 
   @ 20, 60 GET oGet[02] VAR base:nombre PICTURE "@!"  OF oDlg1 PIXEL VALID(base:nombre<>SPACE(30))
   @ 35, 60 GET oGet[03] VAR base:direccion OF oDlg1 PIXEL PICTURE "@!"
   @ 50, 60 GET oGet[04] VAR base:telefono  OF oDlg1 PIXEL
   @ 65, 60 GET oGet[05] VAR base:localidad OF oDlg1 PIXEL PICTURE "@!"
   @ 65,220 GET oGet[06] VAR base:codpos    OF oDlg1 PIXEL RIGHT PICTURE "9999" 
   *@ 80,145 GET oGet[07] VAR base:zona      OF oDlg1 PIXEL RIGHT PICTURE "9"
   @ 80, 60 GET oGet[10] VAR base:fecnac    OF oDlg1 PIXEL CENTER PICTURE "@D"
   @ 80,150 GET oGet[08] VAR base:fecing    OF oDlg1 PIXEL CENTER PICTURE "@D"
   @ 95, 60 GET oGet[09] VAR base:fecult    OF oDlg1 PIXEL CENTER PICTURE "@D"
   @ 95,150 GET oGet[18] VAR base:limite    OF oDlg1 PIXEL RIGHT PICTURE "99999999.99"
   IF oApp:usar_puntos
      @ 97,195 SAY "Puntos:" OF oDlg1 PIXEL SIZE 20,12 RIGHT
      @ 95,220 GET oGet[20] VAR base:puntos OF oDlg1 PIXEL PICTURE "9999999" RIGHT 
   ENDIF
   @110, 60 GET oGet[15] VAR base:descuento OF oDlg1 PIXEL RIGHT PICTURE "999.99"
    IF oApp:percep_iibb
      @ 112,95 SAY "% I.I.B.B.:" OF oDlg1 PIXEL SIZE 50,12 RIGHT
      @ 110,150 GET oGet[21] VAR base:iibb OF oDlg1 PIXEL PICTURE "999.99" RIGHT 
   ENDIF
   @125, 60 GET oGet[11] VAR base:cuit     PICTURE "99-99999999-9" SIZE 45,12 ;
         VALID(ValidaCuit(base:cuit)) OF oDlg1 PIXEL
   @125,150 GET oGet[12]  VAR base:dni      PICTURE "99999999"  OF oDlg1 PIXEL RIGHT
   @140, 60 COMBOBOX oGet[13] VAR base:coniva  ITEMS aTipoIva SIZE 150,80 PIXEL WHEN(lCambiar)
   @155, 60 GET oGet[14] VAR base:mail   OF oDlg1 PIXEL PICTURE "@S40"
   @170, 60 GET oGet[16] VAR base:vendedor  PICTURE "99" RIGHT OF oDlg1 SIZE 25,12 PIXEL;
                VALID(Buscar(oQryVen,oDlg1,oGet[16],oGet[17]));
                ACTION (oGet[16]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[16],oGet[17])) BITMAP "BUSC1" 
   @170, 90 GET oGet[17] VAR cNomVen    PICTURE "@!" OF oDlg1 PIXEL SIZE 120,12 WHEN(.F.) 
   @185, 60 COMBOBOX oGet[19] VAR base:lispre ITEMS aListas OF oDlg1 SIZE 40,40 PIXEL
   @200, 60 GET oGet[22] VAR base:lispreesp  OF oDlg1 PICTURE "999" SIZE 25,12 RIGHT PIXEL;
                 VALID((base:lispreesp = 0 .and. IF(base:lispreesp=0,(oGet[23]:cText:="SIN LISTA ESPECIAL"+SPACE(31))<>"xxx",.T.)) .or.;
                       Buscar(oQryLisPre,oDlg1,oGet[22],oGet[23]));
                 ACTION (oGet[22]:cText:= 0, Buscar(oQryLisPre,oDlg1,oGet[22],oGet[23])) BITMAP "BUSC1"
   @200, 90 GET oGet[23] VAR cLisPre OF oDlg1 PIXEL PICTURE "@!" SIZE 150,12 WHEN(.F.)
   @ 07,130 COMBOBOX oGet[25] VAR nEstado  ITEMS aEstado SIZE 60,80 PIXEL
   @125,225 GET oGet[26] VAR cObserva  SIZE 140,70 MEMO OF oDlg1 PIXEL
   IF !lAlta
      IF base:saldo > 0
         @ 20,250 SAY "SALDO A FAVOR $: " + STR(base:saldo,12,2) OF oDlg1 SIZE 90,12 COLOR CLR_RED PIXEL
         @ 40,250 BTNBMP oBot3 PROMPT "&Devolver"+CHR(10)+"Anticipo" OF oDlg1 SIZE 32,32 FLAT ;
           ACTION (DevolverAnt(base,oDlg1),oDlg1:End() ) PIXEL 
      ENDIF
   ENDIF

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mRta
   RETURN nil
ENDIF
IF base:coniva > 6 .and. base:coniva <12
   MsgStop("Condicion de I.V.A. no soportada por este programa")
   LOOP
ENDIF
IF base:coniva <> 5 .and. (EMPTY(base:cuit) .Or. base:cuit = "  -        - ")
   MsgStop("Debe poner un CUIT para esa condicion de I.V.A.")
   LOOP
ENDIF
//Validar si el cuit es repetido
IF base:cuit <> "  -        - "
   IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"clientes WHERE codigo <> "+str(base:codigo)+;
         " AND cuit = "+ClipValue2SQL( base:cuit)):nRecCount > 0
      mRta := MsgNoYes("Ya existe un cliente con ese cuit, continua igual?","Atencion")
      IF !mRta 
         LOOP
      ENDIF
   ENDIF
ENDIF
   
base:zona := IF(nEstado=1,"1","2")
base:usuario:= oApp:usuario
base:ip     := oApp:cIp
base:fecmod := DATE()

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh()
  IF !EMPTY(cObserva)
     oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"cliobs WHERE fecha is null AND codcli = "+STR(base:codigo))
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"cliobs (codcli,fecha,observa) VALUES "+;
                          " ("+ClipValue2SQL(base:codigo)+",null,"+ClipValue2Sql(cObserva)+")")
  ENDIF
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

**************************************************************************************************
****** CANJEAR PUNTOS ACUMULADOS 
STATIC FUNCTION CanjearPuntos()
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(4),oBot1,oBot2,lRta:=.f.,nCanjear:=0,nRestantes:=oQry:puntos,;
      cObserva:=SPACE(255),oError

DO WHILE .T.
DEFINE DIALOG oDlgD TITLE "Canjear puntos acumulados" OF oWnd1 FROM 05,15 TO 17,80
  acor := AcepCanc(oDlgD)
  

   @ 07, 05 SAY "Puntos acumulados:" OF oDlgD PIXEL SIZE 70,12 RIGHT
   @ 22, 05 SAY "Puntos a canjear:"  OF oDlgD PIXEL SIZE 70,12 RIGHT
   @ 37, 05 SAY "Puntos restantes:"  OF oDlgD PIXEL SIZE 70,12 RIGHT
   @ 52, 05 SAY "Observaciones:"     OF oDlgD PIXEL SIZE 70,12 RIGHT 

   @ 05, 80 GET oGet1[1] VAR oQry:puntos OF oDlgD PIXEL PICTURE "9999999" RIGHT WHEN(.F.)
   @ 20, 80 GET oGet1[2] VAR nCanjear    OF oDlgD PIXEL PICTURE "9999999" RIGHT VALID(nCanjear <= oQry:puntos)
   @ 35, 80 GET oGet1[3] VAR nRestantes  OF oDlgD PIXEL PICTURE "9999999" RIGHT;
                WHEN((oGet1[3]:cText:= oQry:puntos - nCanjear) = "XXX" )
   @ 50, 80 GET oGet1[4] VAR cObserva    OF oDlgD PIXEL PICTURE "@!" SIZE 150,12


   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[2]:SetFocus
IF !lRta
   RETURN .f.
ENDIF

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"canjes (fecha,codcli,numtar,puntos,usados,observa) "+;
                       "VALUES(CURDATE(),"+ClipValue2SQL(oQry:codigo)+","+ClipValue2SQL(STR(oQry:codigo))+","+;
                       ClipValue2SQL(oQry:puntos)+","+ClipValue2SQL(nCanjear)+","+ClipValue2SQL(cObserva)+")")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET puntos = "+ClipValue2SQL(nRestantes)+" WHERE codigo = "+ClipValue2SQL(oQry:codigo))
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO


RETURN .t.
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
                 "el registro codigo Nro:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrw:Refresh()
RETURN nil 

******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, ;
     VCODIGO := 0, VNOMBRE := SPACE(40), VDIRECCION := SPACE(40), VLOCALIDAD := SPACE(40), ;
     VTELEFONO:= SPACE(40),VMAIL:= SPACE(50), ;
     VCUIT:= SPACE(13), VDNI := 0, VCONIVA := 15 
LOCAL oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet19,;
      oGet10, oGet11, oGet12, oGet13, oGet14, oGet15, oGet16, oGet17, oGet18,;
      oGet20, oGet22, oBot1, oBot2,oDlg1,base,oError, ;
      atipoiva  := {;
"1 IVA Responsable Inscripto",;
"2 IVA Responsable no Inscripto",;
"3 IVA no Responsable",;
"4 IVA Sujeto Exento",;
"5 Consumidor Final",;
"6 Responsable Monotributo",;
"7 Sujeto no Categorizado",;
"8 Proveedor del Exterior",;
"9 Cliente del Exterior",;
"10  IVA Liberado – Ley Nº 19.640",;
"11  IVA Responsable Inscripto – Agente de Percepción",;
"12  Pequeño Contribuyente Eventual",;
"13  Monotributista Social",;
"14  Pequeño Contribuyente Eventual Social",""},;
      mrta := .f., aCor,cNomVen:=SPACE(30)

DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "FILTRADO de Clientes" FROM 05,10 TO 25,80 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Codigo:"         OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Nombre:"         OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Direccion:"      OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Telefono:"       OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 67, 05 SAY "Localidad:"      OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 82, 05 SAY "C.U.I.T.:"       OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 82,125 SAY "D.N.I.:"         OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 97, 05 SAY "Condicion IVA:"  OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @112, 05 SAY "Mail:"           OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vcodigo PICTURE "99999" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vnombre PICTURE "@!"  OF oDlg1 PIXEL 
   @ 35, 70 GET oGet3 VAR vdireccion OF oDlg1 PIXEL
   @ 50, 70 GET oGet4 VAR vtelefono  OF oDlg1 PIXEL
   @ 65, 70 GET oGet7 VAR vlocalidad OF oDlg1 PIXEL
   @ 80, 70 GET oGet10 VAR vcuit     PICTURE "99-99999999-9" ;
         VALID(ValidaCuit(vcuit)) OF oDlg1 PIXEL
   @ 80,200 GET oGet6  VAR vdni      PICTURE "99999999"  OF oDlg1 PIXEL RIGHT
   @ 95, 70 COMBOBOX oGet11 VAR vconiva  ITEMS aTipoIva SIZE 150,80 PIXEL
   @110, 70 GET oGet19 VAR vmail   OF oDlg1 PIXEL PICTURE "@!"
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " 1=1 " + IF(EMPTY(vCodigo)," AND codigo > 1"," and codigo > 1 and codigo =" + ClipValue2SQL(VCodigo) + "") ;
      + "" + IF(EMPTY(VNOMBRE),"","  and TRIM(NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
      + "" + IF(EMPTY(VDIRECCION),""," and TRIM(DIRECCION) like '%" + ALLTRIM(VDIRECCION) + "%'") ;
      + "" + IF(EMPTY(VLOCALIDAD),""," and TRIM(LOCALIDAD) like '%" + ALLTRIM(VLOCALIDAD) + "%'") ;
      + "" + IF(EMPTY(VTELEFONO),""," and TRIM(TELEFONO) like '%" + ALLTRIM(VTELEFONO) + "%'") ;
      + "" + IF(EMPTY(VMAIL),""," and TRIM(MAIL) like '%" + ALLTRIM(VMAIL) + "%'") ;
      + "" + IF(EMPTY(VCUIT),""," and TRIM(CUIT) like '%" + ALLTRIM(VCUIT) + "%'") ;
      + "" + IF(EMPTY(VDNI),""," and DNI =" + ClipValue2SQL(VDNI) + "") ;   
      + "" + IF(Vconiva=15,""," and coniva =" + ClipValue2SQL(Vconiva) + "") 

   EXIT
ENDDO
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil

*****************************************************************
** Importar Clientes
STATIC FUNCTION Importar()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      aCols := {{0,SPACE(30),SPACE(30),SPACE(30),SPACE(30),SPACE(13),0,SPACE(30),0}},;
      i, cError, cSql
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Importar Clientes" FROM 03,15 TO 35,140
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oDlg1 ARRAY aCols ;
      HEADERS "Codigo", "Razon Social","Direccion","Telefono","Localidad","CUIT","IVA","Email","Vendedor";
      COLUMNS 1, 2 ,3, 4, 5,6,7,8,9;
      SIZES 60,150,100,100,200,90,40,100,100;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwTmp
      :nEditTypes := 1  
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
   END  
   @ 205,05 SAY "Use el boton PEGAR para incluir los datos o edite manualmente los campos. "+;
                "Tenga en cuenta que el codigo de cliente no puede estar ya en la base de datos"+;
                " y que la condicion de IVA tiene que ser un valor valido segun el programa. Si no"+;
                " tiene el CUIT del cliente dejelo en blanco." SIZE 465,60 OF oDlg1 PIXEL 
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
    IF EMPTY(aCols[i,2])
       AADD(cError,"Columna 2 en posicion " + STR(i,6) + " no puede estar en blanco ")
    ENDIF
    IF !EMPTY(aCols[i,6]) .AND. !ValidaCuit(aCols[i,6],.f.)
       AADD(cError,"Columna 6 en posicion " + STR(i,6) + " CUIT no valido ")
    ENDIF
    IF aCols[i,7] < 1 .OR. aCols[i,7] > 14
       AADD(cError,"Columna 7 en posicion " + STR(i,6) + " solo valores de 1 a 14 ")
    ENDIF
    IF (aCols[i,7] <> 5 .and. aCols[i,7] <> 0)  .AND. EMPTY(aCols[i,6]) 
       AADD(cError,"En posicion " + STR(i,6) + " con condicion de IVA <> 5 debe tener CUIT ")
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
cSql := "INSERT INTO ge_"+oApp:cId+"clientes "+;
        " (codigo,nombre,direccion,telefono,localidad,cuit,coniva,mail,vendedor,lispre) VALUES "
FOR i := 1 TO LEN(aCols)
    cSql := cSql + "("+ClipValue2SQL(aCols[i,1]) + "," + ;
                       ClipValue2SQL(aCols[i,2]) + "," + ;
                       ClipValue2SQL(aCols[i,3]) + "," + ;
                       ClipValue2SQL(aCols[i,4]) + "," + ;
                       ClipValue2SQL(aCols[i,5]) + "," + ;
                       ClipValue2SQL(aCols[i,6]) + "," + ;
                       ClipValue2SQL(aCols[i,7]) + "," + ;
                       ClipValue2SQL(aCols[i,8]) + "," + ;
                       ClipValue2SQL(aCols[i,9]) + ",1), "
NEXT i
cSql := LEFT(cSql,LEN(cSql)-2)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute(cSql)
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)
CATCH cError
  MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
  oApp:oServer:RollBack()
END TRY    
RETURN nil

*********************************************
** Ficha de Seguimiento del Cliente
STATIC FUNCTION Fich()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      i, cError, cSql,;
      oQrySeg:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cliobs WHERE codcli = " +;
       ClipValue2SQL(oQry:codigo) + " AND fecha IS NOT NULL ORDER BY fecha")
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Ficha de Seguimiento de Clientes " + oQry:nombre FROM 03,15 TO 35,90
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 280,180 pixel OF oDlg1 DATASOURCE oQrySeg ;
      HEADERS "Fecha", "Anotaciones";
      COLUMNS "fecha","observa";
      SIZES 80,450;
      CELL LINES NOBORDER 
   WITH OBJECT oBrwTmp
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
      :nFreeze := 2
   END  
   PintaBrw(oBrwTmp,0)
   @ 05, acor[2] BUTTON oBot1 PROMPT "&Nueva" OF oDlg1 SIZE 30,10 ;
           ACTION (NuevaObs(oQrySeg,oBrwTmp, oDlg1)) PIXEL
   @ 05, acor[4] BUTTON oBot1 PROMPT "&Ver" OF oDlg1 SIZE 30,10 ;
           ACTION (VerObs(oQrySeg,oBrwTmp,oDlg1)) PIXEL WHEN(oQrySeg:nRecCount > 0)   
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Salir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN nil 
ENDIF 
ENDDO 
RETURN nil

STATIC FUNCTION NuevaObs(oQrySeg,oBrwTmp, oWnd)
LOCAL oGet := ARRAY(6), oDlg1, oBot := ARRAY(2), aCor, base, lRta := .f., lAgendar := .F.,;
      mfecha := CTOD('  /  /    '), mhora := TIME(), oError, aUsua, oBrwU
aUsua := oApp:oServer:Query("SELECT usuario,altas FROM ge_"+oApp:cId+"usuarios"):FillArray(,{'usuario','altas'})
FOR aCor := 1 TO LEN(aUsua)
   aUsua[aCor,2] := oApp:usuario = aUsua[aCor,1]
NEXT
base := oQrySeg:GetBlankRow()
base:fecha := DATE()
base:codcli := oQry:codigo 
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Nueva Anotacion" FROM 03,15 TO 24,90 OF oWnd
   acor := AcepCanc(oDlg1)  
   @ 07, 05 SAY "Fecha:"         OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Detalle:"       OF oDlg1 PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:fecha   PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 65 GET oGet[2] VAR base:observa OF oDlg1 PIXEL MEMO SIZE 90,50
   @ 75, 65 CHECKBOX oGet[3] VAR lAgendar PROMPT "Registrar en Agenda" SIZE 60,10 OF oDlg1 PIXEL
   @ 90, 65 GET      oGet[4] VAR mfecha PICTURE "@D" OF oDlg1 PIXEL VALID(mfecha >= DATE()) WHEN(lAgendar)
   @ 90,115 GET      oGet[5] VAR mhora  PICTURE "99:99" OF oDlg1 PIXEL WHEN(lAgendar)
   @ 90,145 XBROWSE oBrwU SIZE 90,50 pixel OF oDlg1 ARRAY aUsua ;
      HEADERS "Usuario", "Agendar";
      COLUMNS 1, 2 ;
      CELL LINES NOBORDER WHEN(lAgendar .AND. oApp:usua_es_supervisor)
   WITH OBJECT oBrwU
      :aCols[2]:nEditType := EDIT_GET 
      :lRecordSelector := .f.
      :aCols[ 2 ]:SetCheck()
      :nFreeze := 2
      :CreateFromCode()
      :lHScroll := .f.
   END  
   PintaBrw(oBrwU,0)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !lRta
   RETURN nil
ENDIF
IF EMPTY(base:fecha)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAgendar .and. EMPTY(mfecha)
   MsgStop("Ponga la fecha para agendar","Error")
   LOOP
ENDIF
oQrySeg:GetBlankRow()
oQrySeg:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQrySeg:Save()
  IF lAgendar
     FOR aCor := 1 TO LEN(aUsua)
         IF aUsua[aCor,2]
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+;
          "citas (fecha,hora,horafin,motivo,contacto,usuario,estado,alerta) "+;
          "VALUES ("+ClipValue2SQL(mfecha)+","+ClipValue2SQL(mhora)+","+ClipValue2SQL(mhora)+",";
          +ClipValue2SQL(base:observa)+","+ClipValue2SQL(base:codcli)+","+ClipValue2SQL(aUsua[aCor,1])+",FALSE,TRUE)")
         ENDIF  
     NEXT    
  ENDIF
  oApp:oServer:CommitTransaction()
  oQrySeg:Refresh()
  oBrwTmp:Refresh()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil 

STATIC FUNCTION VerObs(oQrySeg,oBrwTmp,oWnd)
LOCAL oGet := ARRAY(6), oDlg1, oBot := ARRAY(2), aCor, base, lRta := .f., oError
base := oQrySeg:GetRowObj()
oQrySeg:lAppend := .f. 
DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "Ver Anotacion" FROM 03,15 TO 15,60 OF oWnd
   acor := AcepCanc(oDlg1)  
   @ 07, 05 SAY "Fecha:"         OF oDlg1 PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Detalle:"       OF oDlg1 PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:fecha   PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 65 GET oGet[2] VAR base:observa OF oDlg1 PIXEL MEMO SIZE 90,50
      
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg1:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !lRta
   RETURN nil
ENDIF
IF EMPTY(base:fecha)
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQrySeg:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQrySeg:Save()  
  oApp:oServer:CommitTransaction()
  oQrySeg:Refresh()
  oBrwTmp:Refresh()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


/***********************************************************/
STATIC FUNCTION CanjearReport()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(8), oBot1, oBot2, oQryVen,;
      cTodos := "Todos                   ", mnomven := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      lDeta := .f.,mvendedor := 0,nTipo:=1,aTipo:={"Sistema","Demo","Ambos"},lTipo,;
      oQryCli, mcliente := 0, mnomcli := SPACE(30)  
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte de Canjes y Puntos" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[7] VAR mcliente OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[7]:value = 0 .or. Buscar(oQryCli,oDlg1,oGet[7],oGet[8]));
                ACTION (oGet[7]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[7],oGet[8])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[8] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[8]:cText := IF(mcliente=0,cTodos,oQryCli:nombre)) = SPACE(30))

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta   
   RETURN nil
ENDIF
CursorWait()
DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
oQry := oApp:oServer:Query(" SELECT res.* FROM ("+;
                         "(SELECT v.codcli AS codcli, c.nombre AS nombre, c.direccion AS direccion, "+;
                         " c.telefono AS telefono, c.puntos AS puntos, "+;
                         " v.id,v.fecha, v.puntos as pun, v.usados, v.observa"+;
                         " FROM ge_"+oApp:cId+"canjes v LEFT JOIN ge_"+oApp:cId+"clientes c ON v.codcli = c.codigo "+;
                         " WHERE " + IF(mcliente=0,"TRUE ","v.codcli = "+ClipValue2Sql(mcliente)) +" AND v.codcli >1) "+;
                         " UNION ALL "+;
                         "(SELECT c.codigo AS codcli, c.nombre AS nombre, c.direccion AS direccion, "+;
                         " c.telefono AS telefono, c.puntos AS puntos, "+;
                         " v.id,v.fecha, v.puntos as pun, v.usados, v.observa"+;
                         " FROM ge_"+oApp:cId+"clientes c LEFT JOIN ge_"+oApp:cId+"canjes v ON v.codcli = c.codigo "+;
                         " WHERE " + IF(mcliente=0,"TRUE ","c.codigo = "+ClipValue2Sql(mcliente)) +" AND"+;
                         " c.puntos > 0 AND v.id IS NULL  AND c.codigo >1) "+;
                         " ) res"+;
                         " ORDER BY res.codcli, res.fecha")
                         
REPORT oRep TITLE "Detalle de Puntos y Canjes";
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp)  , ;
       "Detalle de Puntos y Canjes" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Detalle de Puntos y Canjes"       
GROUP ON oQry:codcli HEADER "Cliente: ("+ STR(oQry:codcli) + ") " + ALLTRIM(oQry:nombre)+;
      " Puntos actuales:" + STR(oQry:puntos,7);
      FOOTER "Total Cliente" FONT 3

COLUMN TITLE "Canje Nro"    DATA oQry:id         SIZE 10 PICTURE "999999999" FONT 1
COLUMN TITLE "Fecha Canje"  DATA oQry:fecha      PICTURE "@D" SIZE 10 FONT 1
COLUMN TITLE "Puntos"       DATA oQry:pun        SIZE 10 PICTURE "999999999"  FONT 2 
COLUMN TITLE "Canjeados"    DATA oQry:usados     SIZE 10 PICTURE "999999999"  FONT 2 TOTAL
COLUMN TITLE "Motivo"       DATA IF(oQry:id = 0, "Sin Canjes",oQry:observa)    SIZE 30 FONT 1


// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",1,1);
         ON POSTGROUP oRep:NewLine()
oQry:End()
RETURN nil

/***********************************************************/
STATIC FUNCTION ReporteCliexVend()
LOCAL oRep, oFont1, oFont2, oFont3, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(8), oBot1, oBot2, ;
      cTodos := "Todos                   ", mnomven := SPACE(30), mdesde := DATE(), mhasta := DATE(),;
      lDeta := .f.,mvendedor := 0,nTipo:=1,aTipo:={"Sistema","Demo","Ambos"},lTipo,;
      oQry, mcliente := 0, mnomcli := SPACE(30)  ,atipoiva  := {;
"Responsable Inscripto",;
"Responsable no Inscripto",;
"No Responsable",;
"Sujeto Exento",;
"Consumidor Final",;
"Responsable Monotributo",;
"Sujeto no Categorizado",;
"Proveedor del Exterior",;
"Cliente del Exterior",;
"IVA Liberado – Ley Nº 19.640",;
"IVA Responsable Inscripto – Agente de Percepción",;
"Pequeño Contribuyente Eventual",;
"Monotributista Social",;
"Pequeño Contribuyente Eventual Social",;
"IVA NO Alcanzado"}
oQry:= oApp:oServer:Query("SELECT c.*, v.nombre as nomven FROM ge_"+oApp:cId+"clientes c "+;
                             " LEFT JOIN ge_"+oApp:cId+"vendedores v ON v.codigo = c.vendedor ORDER BY c.vendedor, c.nombre")           
CursorWait()
DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
                         
REPORT oRep TITLE "Reporte de Clientes por vendedor";
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp)  , ;
       "Reporte de Clientes por vendedor","Todos los vendedores","" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Reporte de Clientes por vendedor"       
GROUP ON oQry:vendedor HEADER "Vendedor: ("+ STR(oQry:vendedor) + ") " + ALLTRIM(oQry:nomven);
      FOOTER "Total Clientes" FONT 3

COLUMN TITLE "Codigo"       DATA oQry:codigo     SIZE 5 PICTURE "999999" FONT 1
COLUMN TITLE "Nombre"       DATA oQry:nombre     SIZE 20 FONT 2
COLUMN TITLE "Direccion"    DATA oQry:direccion  SIZE 20 FONT 1
COLUMN TITLE "Telefono"     DATA oQry:telefono   SIZE 12 FONT 1 
COLUMN TITLE "Localidad"    DATA oQry:localidad  SIZE 12 FONT 1 
COLUMN TITLE "CUIT"         DATA oQry:cuit       SIZE 10 FONT 1 
COLUMN TITLE "Cond.Iva"     DATA IF(oQry:coniva=0,"",aTipoIva[oQry:coniva])       SIZE 12 FONT 1 
COLUMN TITLE "Dto"          DATA oQry:descuento  SIZE 3 FONT 1 
COLUMN TITLE "Lta"          DATA oQry:lispre  SIZE 3 FONT 1 
COLUMN TITLE "Esp."         DATA oQry:lispreesp  SIZE 3 FONT 1 



// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.jpg",.5,.5);
         ON POSTGROUP oRep:NewLine()
oQry:End()
RETURN nil


************************************************
** Devolver Anticipo 
STATIC FUNCTION DevolverAnt(base,oWnd)
LOCAL lComan, oError, mRta:=.f., nCodCue:=0, nNumOpe:=0,cObserva:=SPACE(255), nNumDep,;
      lCuenta:=.f.,  nPago, mobserva
lComan := SiNoCancelar("Atencion","Como desea devolver el anticipo?",{"Efectivo","Transferencia","Cancelar"})
IF lComan == nil 
   RETURN nil 
ENDIF
IF !lComan
     lCuenta:=  DatosTransferencia(@nCodCue,@nNumOpe,@cObserva,oWnd)
     IF !lCuenta
        RETURN .f.
     ENDIF
ENDIF
mrta := MsgYesNo("Confirma la devolucion del anticipo?","Atencion")
IF !mRta
   RETURN .f.
ENDIF
TRY 
     oApp:oServer:BeginTransaction()
     mobserva := "DEVOLUCION DE ANTICIPO"
     ** Agrego pago 
     oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagos " + ;                                       //INTERESES???
                          " (cliente, total, facturas, observa, fecha,caja, usuario,vendedor, fecmod, ip, demo,interes) VALUES "+;
                         " ("+;
                             ClipValue2Sql(base:codigo)+","+;
                             ClipValue2Sql(-base:saldo)+","+;
                             ClipValue2Sql(0)+","+;
                             ClipValue2Sql(mobserva)+","+;
                             ClipValue2Sql(DATE())+","+;
                             ClipValue2Sql(oApp:prefijo)+","+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2Sql(oApp:usuario)+","+;
                             ClipValue2SQL(DATE())+","+;
                             ClipValue2SQL(oApp:cIp)+","+;
                             "0,"+;
                             ClipValue2SQL(0)+;
                             ")")
     nPago:= oApp:oServer:Query("SELECT MAX(numero) AS orden FROM ge_"+oApp:cId+"pagos"):orden
     
     ** Grabo las formas de pago
     // INGRESO CONCEPTO EFECTIVO
     IF lComan
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                               "codcon  = 1, "+;
                                               "tipocon  = 1, "+;
                                               "importe = "+ ClipValue2Sql(-base:saldo)+","+;
                                               "observa = 'EFECTIVO'")        
        ELSE
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,numope,detalle,usuario,fecmod,ip,importe) VALUES "+;
                        " ("+;
                          ClipValue2SQL(nCodCue)+","+;
                          "'R',"+;
                          ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2Sql(nNumOpe)+","+;
                            ClipValue2SQL(cObserva)+","+;
                            ClipValue2SQL(oApp:usuario)+","+;
                            ClipValue2SQL(DATE())+","+;
                            ClipValue2SQL(oApp:cIp)+","+;
                            ClipValue2SQL(base:saldo)+")")
        nNumDep:= oApp:oServer:Query("SELECT MAX(id) AS numero FROM ge_"+oApp:cId+"deposito"):numero 
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pagos SET iddepo = "+ ClipValue2Sql(nNumDep) + " WHERE numero = "+ClipValue2Sql(nPago))
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon SET numero  = " + ClipValue2Sql(nPago)+","+;
                                               "codcon  = 2, "+;
                                               "tipocon  = 2, "+;
                                               "importe = "+ ClipValue2Sql(-base:saldo)+","+;
                                               "observa = 'TRANSFERENCIA'")
     ENDIF

     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = 0 WHERE codigo = "+ClipValue2Sql(base:codigo))
    /* ELSE
        oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldod = saldod -" +ClipValue2Sql(nAnticipo)+" + "+ClipValue2Sql(ABS(nFaltante))+" "+;
                             "WHERE codigo = "+ClipValue2Sql(mcodcli))
     ENDIF*/

    oApp:oServer:CommitTransaction()
    CATCH oError
    ValidaError(oError)
    RETURN .f.
END TRY
mobserva:=SPACE(255)
mrta := MsgYesNo("Desea Imprimir el Recibo?","Atencion")
IF mrta   
   Reci(nPago,.t.)
ENDIF
RETURN nil

***********************************************************************************************************************************
***** SI ES UNA TRANSFERENCIA PIDO LOS DATOS DE LA CUENTA 
STATIC FUNCTION DatosTransferencia(nCodCue,nNumOpe,cObserva,oWnd)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomCue:=SPACE(50),oQryCue,oDlg1

oQryCue:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"cuentas")


DEFINE DIALOG oForm TITLE "Cuenta de la transferencia";
       FROM 05,15 TO 15,85 OF oWnd FONT oApp:oFont
   
   @ 07, 05 SAY "Cuenta:"            OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Operacion:"         OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Observaciones:"     OF oForm PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet[1] VAR nCodCue OF oForm SIZE 25,12 RIGHT PICTURE "99" PIXEL;
                VALID(Buscar(oQryCue,oDlg1,oGet[1],oGet[2]));
                ACTION (oGet[1]:cText:= 0, Buscar(oQryCue,oDlg1,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 05, 80 GET oGet[2] VAR cNomCue PICTURE "@!" OF oForm PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR nNumOpe PICTURE "99999999999999999999" OF oForm PIXEL RIGHT 
   @ 35, 50 GET oGet[4] VAR cObserva PICTURE "@!" OF oForm PIXEL SIZE 200,12
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN .F.
ENDIF

RETURN .T.