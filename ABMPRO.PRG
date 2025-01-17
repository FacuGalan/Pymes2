#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


*************************************************
** ABM DE PROVEEDORES
*************************************************
MEMVAR oApp
STATIC oQryBrw,oWnd1, oBrw, oDlg, cVentana
PROCEDURE PROVEE(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQryBrw:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee ORDER BY nombre")
                         
  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Proveedores" ;
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
            ACTION oBrw:Report("Reporte de Proveedores",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar clientes"  ;
            ACTION (FILT(),oBrw:Refresh());
            PROMPT "Filtrar" TOP 
         DEFINE BUTTON RESOURCE "BACKU" OF oBar ;
            TOOLTIP "Importar Registros"  ;
            ACTION (Importar(), oBrw:Refresh());
            PROMPT "Importar" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "POS" OF oBar ;
            TOOLTIP "Códigos de artículos del proveedor"  ;
            ACTION (CodigosProv(), oBrw:Refresh());
            PROMPT "Art. Prov." TOP WHEN("A"$cPermisos)
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "Codigo","nombre","alias","localidad","telefono";
              HEADERS "Código","Nombre","Alias","Localidad","Telefonos";
              SIZES 60,345,70,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
    *oBrw:aCols[2]:SetOrder()
     //oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


/************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
STATIC FUNCTION Acelerador2(nKey, oBar,cPermisos)

IF nKey = 13
   IF "M"$cPermisos
      oBar:aControls[2]:Click()
      oBrw:GoLeftMost()
  ENDIF
ENDIF

RETURN NIL*/

*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(21), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,oSay,;
	    cCuenta:=SPACE(50),aTipoIva :=  {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
                                       "EXENTO         .","CONSUMIDOR FINAL", "MONOTRIBUTO    ."},;
      oQryCue, nCuit := 0

oQryCue:= oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"plancont ORDER BY codigo")


IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee LIMIT 0")
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"provee")
   base:coniva := 1
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
   base := oQry:GetRowObj()
   oQry:lAppend:= .f.
   oQryCue:GoTop()
   IF oQryCue:Seek(base:codcue,1) > 0
      cCuenta := oQryCue:nombre
   ENDIF

ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Proveedores";
       FROM 05,15 TO 36,87 OF oWnd1 FONT oApp:oFont
   
   @ 07, 00 SAY "Número de proveedor:" OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @ 22, 00 SAY "Razón social:"        OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @ 37, 00 SAY "Alias:"               OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @ 52, 00 SAY "Localidad:"           OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT  
   @ 67, 00 SAY "C.P:"                 OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @ 82, 00 SAY "Direccion:"           OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @ 97, 00 SAY "Telefono/Fax:"        OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @112, 00 SAY "C.U.I.T:"             OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @127, 00 SAY "Condicion IVA:"       OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @142, 00 SAY "Imputación Cta:"      OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT  
   @157, 00 SAY "Anticipo:"            OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @172, 00 SAY "Mail:"                OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @187, 00 SAY "Cuenta bancaria:"     OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   @202, 00 SAY "Observaciones:"       OF oForm PIXEL SIZE 60,10 TRANSPARENT RIGHT
   IF lAlta
      @07, 90 SAY "CUIT Afip:"   OF oForm PIXEL SIZE 28,12 RIGHT
      @05,121 GET oGet[21] VAR nCuit PICTURE "99999999999"   OF oForm PIXEL SIZE 45,12 RIGHT;
      VALID(ConsultaCuit(nCuit,oGet,{2,6,4,8,9}))
   ENDIF
   @ 05, 65 GET oGet[01] VAR base:codigo     OF oForm PIXEL PICTURE "999999" RIGHT WHEN(.F.)
   @ 20, 65 GET oGet[02] VAR base:nombre     OF oForm PIXEL PICTURE "@!" ;
                VALID(base:nombre<>SPACE(30))
   @ 35, 65 Get oGet[03] VAR base:alias      OF oForm PIXEL PICTURE "@!"             
   @ 50, 65 GET oGet[04] VAR base:localidad  OF oForm PIXEL PICTURE "@!"
   @ 65, 65 GET oGet[05] VAR base:codpos     OF oForm PIXEL PICTURE "9999" RIGHT
   @ 80, 65 GET oGet[06] VAR base:direccion  OF oForm PIXEL PICTURE "@!"
   @ 95, 65 GET oGet[07] VAR base:telefono   OF oForm PIXEL PICTURE "@!" 
   @110, 65 GET oGet[08] VAR base:cuit       OF oForm PIXEL PICTURE "99-99999999-9"   ;
                       VALID(ValidarCuit(base:cuit,oGet,lAlta))
   IF oApp:usar_reten_iibb
     @112,115 SAY "% Ret I.I.B.B.:"      OF oForm PIXEL SIZE 40,10 TRANSPARENT RIGHT
     @110,160 GET oGet[14] VAR base:retencio   OF oForm PIXEL PICTURE "999.99" RIGHT 
   ENDIF
   IF oApp:usar_reten_iva
     @112,190 SAY "% Ret. I.V.A.:"       OF oForm PIXEL SIZE 40,10 TRANSPARENT RIGHT
     @110,235 GET oGet[18] VAR base:retiva     OF oForm PIXEL PICTURE "999.99" RIGHT 
   ENDIF
   @125, 65 COMBOBOX oGet[09] VAR base:coniva  ITEMS aTipoIva SIZE 80,80 PIXEL
   IF oApp:usar_reten_gan
     @125,160 CHECKBOX oGet[20] VAR base:exgana OF oForm PIXEL SIZE 70,12 PROMPT "Excento en ganancias"
   ENDIF
   @140, 65 GET oGet[10] VAR base:codcue     OF oForm PIXEL SIZE 25,12 RIGHT PICTURE "9999";
                         VALID(Buscar(oQryCue,oForm,oGet[10],oGet[11]));
                         ACTION (oGet[10]:cText:= 0, Buscar(oQryCue,oForm,oGet[10],oGet[11])) BITMAP "BUSC1"  
   @140, 95 GET oGet[11] VAR cCuenta         OF oForm PIXEL PICTURE "@!" WHEN(.F.)       
   @155, 65 GET oGet[12] VAR base:saldo      OF oForm PIXEL PICTURE "99999999.99" RIGHT WHEN(.F.)
   @170, 65 GET oGet[17] VAR base:mail       OF oForm PIXEL 
   @185, 65 GET oGet[15] VAR base:ctabanco   OF oForm PIXEL PICTURE "@!"
   @185,215 CHECKBOX oGet[19] VAR base:gasto OF oForm PIXEL SIZE 60,12 PROMPT "No aplicar retenciones"
   @200, 65 GET oGet[16] VAR base:observa    OF oForm PIXEL SIZE 215,12 PICTURE "@!"
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER

IF !lRta
   RETURN nil
ENDIF

//Validar si el cuit es repetido
IF base:cuit <> "  -        - "
   IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"provee WHERE codigo <> "+str(base:codigo)+;
         " AND cuit = "+ClipValue2SQL( base:cuit)):nRecCount > 0
      lRta := MsgNoYes("Ya existe un proveedor con ese cuit, continua igual?","Atencion")
      IF !lRta 
         LOOP
      ENDIF
   ENDIF
ENDIF
  
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    IF oError:Subcode = 1062 
       base:codigo:= base:codigo +1 
       oQry:oRow := base
       oApp:oServer:BeginTransaction()
       oQry:Save()
       oApp:oServer:CommitTransaction()
    ELSE
       ValidaError(oError)
       LOOP
    ENDIF 
END TRY
EXIT
ENDDO
oQryBrw:Refresh()
RETURN nil

*******************************************************************************************
*****VALIDAR CUIT Y CARGAR PERCEPCIONES
STATIC FUNCTION ValidarCuit(cuit,oGet,lAlta)
LOCAL mcuit:=STRTRAN(cuit,"-","")
IF !ValidaCuit(cuit)
   RETURN .f.
ENDIF
IF EMPTY(mcuit) .or. !lAlta
   RETURN .t. 
ENDIF

USE padron INDEX padron SHARED NEW  
IF padron->(dbseek("R"+mcuit))
   IF padron->(found())
      oGet[14]:cText:= VAL(STRTRAN(padron->percep,",","."))
   ENDIF
ENDIF
CLOSE padron

RETURN .t.

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
IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE prov = "+str(nNum)):nRecCount > 0
   MsgStop("No puede borrar este proveedor porque tiene"+CHR(10)+;
                 "articulos asociados","Atencion")
   RETURN nil 
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"provee WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)

CATCH oError
    ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, ;
    VNOMBRE := SPACE(50), VLOCALIDAD := SPACE(60),;
    VCONIVA := 7, VCUENTA:=SPACE(3),;
    cNomCue:=SPACE(50)
LOCAL oGet:=ARRAY(12), oBot1, oBot2,oDlg1,base,oError,;
      oQryCuenta:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"plancont"),;
      atipoiva  := {"RESPO. INSCRIPTO","RES.NO INSCRIPTO", "NO RESPONSABLE .",;
                    "EXENTO         .","CONSUMIDOR FINAL", "MONOTRIBUTO    .",""},;
      mrta := .f., aCor


DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "FILTRADO de Proveedores" FROM 05,10 TO 16,85 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Nombre:"           OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Localidad:"        OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Condicion I.V.A.:" OF oDlg1 PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Cuenta:"           OF oDlg1 PIXEL SIZE 40,12 RIGHT
   
 
   
   @ 05, 50 GET oGet[1] VAR vnombre      OF oDlg1 PIXEL PICTURE "@!"  
   @ 20, 50 GET oGet[2] VAR vlocalidad   OF oDlg1 PIXEL PICTURE "@!"   
   @ 35, 50 COMBOBOX oGet[4] VAR vconiva  ITEMS aTipoIva SIZE 135,80 PIXEL
   @ 50, 50 GET oGet[5] VAR vcuenta OF oDlg1 PIXEL PICTURE "@!" SIZE 25,12 RIGHT;
                VALID(EMPTY(oGet[5]:cText) .or. Buscar(oQryCuenta,oDlg1,oGet[5],oGet[6]));
                ACTION (oGet[5]:cText:= 0, Buscar(oQryCuenta,oDlg1,oGet[5],oGet[6])) BITMAP "BUSC1"
   @ 50, 80 GET oGet[6] VAR cNomCue    OF oDlg1 PIXEL PICTURE "@!" WHEN(.F.)
  

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet[1]:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " 1=1 " + IF(EMPTY(VNOMBRE),"","  and TRIM(NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
      + "" + IF(EMPTY(VLOCALIDAD),""," and TRIM(LOCALIDAD) like '%" + ALLTRIM(VLOCALIDAD) + "%'") ;
      + "" + IF(Vconiva=7,""," and coniva =" + ClipValue2SQL(Vconiva) + "") ;
      + "" + IF(EMPTY(VCUENTA),""," and codcue =" + ClipValue2SQL(VCUENTA) + "") ;

   EXIT
ENDDO
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil

*****************************************************************
** Importar Proveedores
STATIC FUNCTION Importar()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      aCols := {{0,SPACE(30),SPACE(30),SPACE(30),SPACE(30),SPACE(13),0,SPACE(30)}},;
      i, cError, cSql
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Importar Proveedores" FROM 03,15 TO 35,140
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oDlg1 ARRAY aCols ;
      HEADERS "Codigo", "Razon Social","Direccion","Telefono","Localidad","CUIT","IVA","Email";
      COLUMNS 1, 2 ,3, 4, 5,6,7,8;
      SIZES 60,150,100,100,200,90,40,100;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwTmp
      :nEditTypes := 1  
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
   END  
   @ 205,05 SAY "Use el boton PEGAR para incluir los datos o edite manualmente los campos. "+;
                "Tenga en cuenta que el codigo de proveedor no puede estar ya en la base de datos"+;
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
    IF aCols[i,7] < 1 .OR. aCols[i,7] > 6
       AADD(cError,"Columna 7 en posicion " + STR(i,6) + " solo valores de 1 a 6 ")
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
cSql := "INSERT INTO ge_"+oApp:cId+"provee "+;
        " (codigo,nombre,direccion,telefono,localidad,cuit,coniva,mail,codcue) VALUES "
FOR i := 1 TO LEN(aCols)
    cSql := cSql + "("+ClipValue2SQL(aCols[i,1]) + "," + ;
                       ClipValue2SQL(aCols[i,2]) + "," + ;
                       ClipValue2SQL(aCols[i,3]) + "," + ;
                       ClipValue2SQL(aCols[i,4]) + "," + ;
                       ClipValue2SQL(aCols[i,5]) + "," + ;
                       ClipValue2SQL(aCols[i,6]) + "," + ;
                       ClipValue2SQL(aCols[i,7]) + "," + ;
                       ClipValue2SQL(aCols[i,8]) + ",1), "
NEXT i
cSql := LEFT(cSql,LEN(cSql)-2)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute(cSql)
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)
CATCH cError
  MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
  oApp:oServer:RollBack()
END TRY    
RETURN nil

*****************************************************
** Codigos de artículos de proveedor 
STATIC FUNCTION CodigosProv()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot := ARRAY(5), oBrwTmp,;
      aCols := {{0,SPACE(30),SPACE(14)}},;
      i, cError, cSql, oQryI
oQryI := oApp:oServer:Query("SELECT c.codart, a.nombre, c.codarp FROM ge_"+oApp:cId+"codpro c "+;
         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = c.codart "+;
         " WHERE codpro = " + ClipValue2SQL(oQryBrw:codigo))
IF oQryI:nRecCount > 0
   aCols:= oQryI:FillArray(,{"codart","nombre","codarp"})
ENDIF
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Codigos de articulos de proveedor "+oQryBrw:nombre FROM 03,15 TO 35,140
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oDlg1 ARRAY aCols ;
      HEADERS "Codigo Sistema", "Producto","Codigo Proveedor";
      COLUMNS 1, 2 ,3;
      SIZES 150,400,150;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwTmp
      :nEditTypes := 1  
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
   END  
   @ 205,05 SAY "Aquí podrá indicar los Códigos que el proveedor  "+ALLTRIM(oQryBrw:nombre)+;
                " maneja, y su correspondencia con los codigos de su sistema."+;
                "También puede pegarlos desde un Excel, con formato identico a esta grilla."+;
                "El campo 'codigo sistema' y 'codigo proveedor' son obligatorios." SIZE 465,60 OF oDlg1 PIXEL 
   PintaBrw(oBrwTmp,0)
   @ 00, 00 BUTTON oBot[1] PROMPT "&Pegar" OF oDlg1 SIZE 30,10 ;
           ACTION (Procesando(.t.),oBrwTmp:Paste(),Procesando(.f.)) PIXEL
   @ 80,480 BUTTON oBot[2] PROMPT "&+" OF oDlg1 SIZE 10,10 ;
           ACTION AgregarArtManual(oBrwTmp,@aCols) PIXEL
   oBot[2]:cTooltip := "Agregar articulo manualmente"        
   @120,480 BUTTON oBot[3] PROMPT "&-" OF oDlg1 SIZE 10,10 ;
           ACTION oBrwTmp:Delete() PIXEL WHEN(oBrwTmp:nDataLines > 0)
   @ acor[1],acor[2] BUTTON oBot[4] PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[5] PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta 
   RETURN nil 
ENDIF 
Procesando(.t.)
** Validaciones
cError := {}
FOR i := 1 TO LEN(aCols)
    IF aCols[i,1] = 0
       AADD(cError,"Columna 1 en posicion " + STR(i,6) + " no puede estar en cero ")
       ELSE 
       IF oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2SQL(aCols[i,1])):nRecCount = 0
          AADD(cError,"Columna 1 en posicion " + STR(i,6) + " codigo "+STR(aCols[i,1])+ " NO EXISTE en tu sistema ")
       ENDIF
    ENDIF
    IF EMPTY(aCols[i,3])
       AADD(cError,"Columna 3 en posicion " + STR(i,6) + " no puede estar en blanco ")
    ENDIF    
NEXT
Procesando(.f.)
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
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Volver" OF oDlg1 SIZE 30,10 ;
           ACTION oDlg1:End()  PIXEL   
   ACTIVATE DIALOG oDlg1 CENTER 
   LOOP
ENDIF
EXIT
ENDDO
cSql := "INSERT INTO ge_"+oApp:cId+"codpro "+;
        " (codpro,codart,codarp) VALUES "
FOR i := 1 TO LEN(aCols)
    cSql := cSql + "("+ClipValue2SQL(oQryBrw:codigo) + "," + ;
                       ClipValue2SQL(aCols[i,1]) + "," + ;
                       ClipValue2SQL(aCols[i,3]) + "), "
NEXT i
cSql := LEFT(cSql,LEN(cSql)-2)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"codpro WHERE codpro ="+ClipValue2SQL(oQryBrw:codigo))
  IF LEN(aCols) > 0
     oApp:oServer:Execute(cSql)
  ENDIF   
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)
CATCH cError
  MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
  oApp:oServer:RollBack()
END TRY    
RETURN nil

**************************************
** Agregar articulo manualmente
STATIC FUNCTION AgregarArtManual(oBrw,aCols)
LOCAL mcodigo := 0, oDlg1,oGet1, oGet2, oGet3, acor, oBot1, oBot2,;
      mnombre := SPACE(45), mrta := .t., mcodpro := SPACE(14)
DO WHILE mrta
DEFINE DIALOG oDlg1 TITLE "Agregar articulos" FROM 05,15 TO 15,70 OF oDlg
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Codigo Sistema:"         OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 22, 05 SAY "Nombre:"                 OF oDlg1 PIXEL SIZE 55,12 RIGHT
   @ 37, 05 SAY "Codigo Proveedor:"       OF oDlg1 PIXEL SIZE 55,12 RIGHT


   @ 05, 65 GET oGet1 VAR mcodigo PICTURE "999999999999999" OF oDlg1 PIXEL;
                VALID(ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1)) RIGHT;
                ACTION(oGet1:cText:=0,ExisteCod(@mcodigo,oGet1,oGet2,oGet3,oDlg1)) BITMAP "BUSC1"  
   @ 20, 65 GET oGet2 VAR mnombre PICTURE "@!"  OF oDlg1 PIXEL WHEN(.F.)
   @ 35, 65 GET oGet3 VAR mcodpro OF oDlg1 PIXEL VALID(!EMPTY(mcodpro)) 

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Continuar" OF oDlg1 SIZE 30,10 ;
           ACTION (Alta1(@mcodigo,oGet1,oGet2,oGet3,@aCols),mrta := .t., oDlg1:End()) PIXEL;
           WHEN(!EMPTY(mcodpro))
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Finalizar" OF oDlg1 SIZE 30,10 ;
           ACTION (mrta := .f., oDlg1:End())  PIXEL CANCEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
ENDDO
oBrw:Refresh()
RETURN NIL

STATIC FUNCTION Alta1(mcodigo,oGet1,oGet2,oGet3,aCols)
LOCAL oError 
AADD(aCols,{oGet1:value,oGet2:cText,oGet3:cText})
mcodigo := 0
oGet1:SetFocus()
oGet1:Refresh()
oGet2:cText := SPACE(45)
oGet3:cText := SPACE(14)
RETURN nil

STATIC FUNCTION ExisteCod(mcodigo,oGet1,oGet2,oGet3,oDlg)
LOCAL oQryArt := oApp:oServer:Query("SELECT codigo,nombre,precioven FROM ge_"+oApp:cId+"articu WHERE codigo = " +oGet1:cText)
IF oQryArt:nRecCount > 0
   oGet2:cText := oQryArt:nombre
   RETURN .t.
   ELSE
   BuscarArt(oQryArt,oDlg,oGet1,oGet2)
ENDIF
RETURN .t.