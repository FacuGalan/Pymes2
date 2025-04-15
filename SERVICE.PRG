#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"
#include "report.ch"
************************************************************************************************
** Services
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, oBrwG, aEstado, oQryBrw, cVentana, oDlg, lAdmin

PROCEDURE Service(cPermisos) 
LOCAL oBar, hHand
cVentana := PROCNAME()     
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

aEstado := {'En revisión','Reparado', 'No reparado', 'Entregado', 'Descartado','Baja Stock'}
lAdmin:= oApp:oServer:Query("SELECT tipo FROM ge_"+oApp:cId+"usuarios WHERE usuario = "+ClipValue2Sql(oApp:usuario)):tipo = 'admin'
validarqueexista()
oQryBrw:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"service")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Productos en Service" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu(.t.),oBrwG:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(.f.),oBrwG:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrwG:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPOR" OF oBar ;
            TOOLTIP "Recuperar de Stock"  ;
            ACTION (Recupera( ),oBrwG:Refresh());
            PROMPT "Recupera" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrwG:ToExcel() WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrwG:Report("Reporte de Services",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)  
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Listar Services"  ;
            ACTION ReporSer();
            PROMPT "Informe" TOP WHEN("R"$cPermisos)      
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Services"  ;
            ACTION Filtrar();
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
     oWnd1:bGotFocus := { || oDlg:SetFocus}
     oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrwG DATASOURCE oQryBrw;
              COLUMNS "id","CODCLI","CLIENTE","FECHA_INGRESO","fecha_reparacion","Observa","fecha_entrega","ESTADO";
              HEADERS "Nro Pedido","Código Cliente","Nombre","Fecha Ing","Fecha Rep","Observaciones","Fecha Ent.","Estado";
              SIZES 70,65,270,90,90,200,100,100;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu(.f.),oBrwG:Refresh()),.T.))
     REDEFINE SAY oBrwG:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrwG:Refresh() }
     oQryBrw:SetOrder("cliente")
     //oBrwG:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrwG,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrwG:aCols[8]:bStrData := {|| IF(oQryBrw:Reccount()>0,aEstado[oQryBrw:estado],"")}     
     oBrwG:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     oBrwG:cSeek := ""
     oBrwG:oSeek:SetText("")
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

**********************************************************************
** Formulario de carga
STATIC FUNCTION Formu(lAlta)
LOCAL oGet := ARRAY(15), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,;
      cNomCli:=SPACE(30),oQryCli, cNomArt := SPACE(50), oQry2, oQry, nEst
oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")
oQry2   := oApp:oServer:Query("SELECT codigo,nombre,precossiva FROM ge_"+oApp:cId+"articu")
IF lAlta
   oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"service LIMIT 0")
   base := oQry:GetBlankRow()
   base:id:= oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"service")
   base:estado:= 1
   base:fecha_ingreso:=DATE()
   nEst:=0

   ELSE
   oQry   := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"service WHERE id = " + ClipValue2SQL(oQryBrw:id))
   base := oQry:GetRowObj()
   nEst:=base:estado
   oQry2:GoTop()
   IF oQry2:Seek(base:codart,1) > 0
      cNomArt := oQry2:nombre
   ENDIF       
ENDIF

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Registro de producto en Service" FROM 05,15 TO 36,100 OF oWnd1
   
   @ 07, 05 SAY "Cliente:"                 OF oForm PIXEL SIZE 70,12 RIGHT 
   @ 22, 05 SAY "Fecha ingreso:"           OF oForm PIXEL SIZE 70,12 RIGHT  
   @ 37, 05 SAY "Articulo:"                OF oForm PIXEL SIZE 70,12 RIGHT
   @ 52, 05 SAY "Numero identificatorio:"  OF oForm PIXEL SIZE 70,12 RIGHT
   @ 67, 05 SAY "Comprobante Venta:"       OF oForm PIXEL SIZE 70,12 RIGHT
   @ 82, 05 SAY "Motivo Reclamo:"          OF oForm PIXEL SIZE 70,12 RIGHT
   @112, 05 SAY "Diagnostico Service:"     OF oForm PIXEL SIZE 70,12 RIGHT
   @142, 05 SAY "Estado:"                  OF oForm PIXEL SIZE 70,12 RIGHT
   @157, 05 SAY "Fecha Reparacion:"        OF oForm PIXEL SIZE 70,12 RIGHT
   @172, 05 SAY "Fecha Entrega:"           OF oForm PIXEL SIZE 70,12 RIGHT
   @187, 05 SAY "Notas Adicionales:"       OF oForm PIXEL SIZE 70,12 RIGHT

   
   @ 05, 85 GET oGet[1] VAR base:codcli PICTURE "99999999" OF oForm PIXEL RIGHT;
                  VALID(Buscar(oQryCli,oForm,oGet[1],oGet[2]));
                  ACTION (oGet[1]:cText:= 0, Buscar(oQryCli,oForm,oGet[1],oGet[2])) BITMAP "BUSC1" WHEN(lAlta)
   @ 05,120 GET oGet[2] VAR base:cliente PICTURE "@S60" OF oForm PIXEL
   @ 20, 85 GET oGet[6] VAR base:fecha_ingreso    PICTURE "@D"  OF oForm PIXEL CENTER WHEN(lAlta)   
   @ 35, 85 GET oGet[3] VAR base:codart OF oForm PIXEL PICTURE "99999999999999" SIZE 70,12 RIGHT;
                VALID(Buscar(oQry2,oForm,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQry2,oForm,oGet[3],oGet[4])) BITMAP "BUSC1" WHEN(lAlta)
   @ 35,160 GET oGet[4] VAR cNomArt OF oForm PIXEL PICTURE "@S40" WHEN(.F.)
   @ 50, 85 GET oGet[5] VAR base:numero_serie OF oForm PIXEL PICTURE "@S40"
   @ 65, 85 GET oGet[7] VAR base:facturanro OF oForm PIXEL PICTURE "!!!9999-99999999"
   @ 80, 85 GET oGet[8] VAR base:observa OF oForm PIXEL SIZE 240,25 MEMO
   @110, 85 GET oGet[9] VAR base:diagnostico OF oForm PIXEL SIZE 240,25 MEMO 
   @140, 85 COMBOBOX oGet[10] VAR base:estado  ITEMS aEstado  SIZE 50,20 PIXEL
   @155, 85 GET oGet[11] VAR base:fecha_reparacion  PICTURE "@D"  OF oForm PIXEL CENTER
   @170, 85 GET oGet[12] VAR base:fecha_entrega  PICTURE "@D"  OF oForm PIXEL CENTER
   @185, 85 GET oGet[13] VAR base:notas_adicionales OF oForm PIXEL SIZE 240,25 MEMO
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL WHEN(nEst < 6 )
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER
IF !lRta
   RETURN nil
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  IF base:estado = 6 //Baja de stock
     oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha","motivo","costo"},;
                           {base:codart,0,1,DATE(),5,oQry2:precossiva})
     oApp:oServer:Execute('UPDATE ge_'+oApp:cId+'articu SET STOCKACT = STOCKACT - 1 WHERE codigo = '+Clipvalue2sql(base:codart))
  ENDIF  
  oQryBrw:Refresh(.t.)   
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


****************************************FILTRADO**********************
STATIC FUNCTION Filtrar( )
   LOCAL oFilt,oGet:=ARRAY(7),oBot:=ARRAY(2),acor:=ARRAY(4),vProv:=0,cNomProv:=SPACE(30),;
   vDesde:=CTOD("01/01/2000"),vHasta:=DATE(),oQryPro,lRta:=.f.,oFont,cWhere,;
   vPDesde:=DATE(),vPHasta := CTOD("01/01/2100") , nEstado := 1,;
   aEstado := {'TODOS','En revisión', 'Reparado', 'No reparado', 'Entregado', 'Descartado','Baja Stock'}
   
oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.                        
    DEFINE DIALOG oFilt TITLE "Filtrado de Pedidos";
           FROM 05,15 TO 18,70 OF oWnd1 FONT oFont
       
       @ 07, 05 SAY "Cliente:"                OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 22, 05 SAY "Desde:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 22, 75 SAY "Hasta:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 37, 05 SAY "Ent. fecha:"             OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 37, 75 SAY "Ent. Hasta:"             OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 52, 05 SAY "Estado:"                 OF oFilt PIXEL SIZE 50,20 RIGHT


       @ 05, 60 GET oGet[01] VAR vProv     OF oFilt PIXEL PICTURE "99999999" ;
                    VALID(oGet[01]:value = 0 .or. Buscar(oQryPro,oFilt,oGet[01],oGet[02]));
                    ACTION (oGet[01]:cText:= 0, Buscar(oQryPro,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"
       @ 05,100 GET oGet[02] VAR cNomProv  OF oFilt PIXEL PICTURE "@!" WHEN(.F.)
       @ 20, 60 GET oGet[03] VAR vDesde    OF oFilt PIXEL PICTURE "@D" CENTER                      
       @ 20,130 GET oGet[04] VAR vHasta    OF oFilt PIXEL PICTURE "@D" CENTER  
       @ 35, 60 GET oGet[05] VAR vPDesde   OF oFilt PIXEL PICTURE "@D" CENTER                      
       @ 35,130 GET oGet[06] VAR vPHasta   OF oFilt PIXEL PICTURE "@D" CENTER 
       @ 55, 60 COMBOBOX oGet[07] VAR nEstado ITEMS aEstado   OF oFilt PIXEL SIZE 90,12

          
       acor := AcepCanc(oFilt)
       @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Filtrar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .t.), oFilt:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oFilt CENTER ON INIT oGet[1]:SetFocus()

    IF !lRta
        RETURN nil
    ENDIF    


    cWhere = " 1=1 " + IF(EMPTY(vProv),""," and codcli = " + ClipValue2SQL(vProv) + "") ;
          + "" + IF(EMPTY(Vdesde),""," and fecha_ingreso >=" + ClipValue2SQL(Vdesde) + "") ; 
          + "" + IF(EMPTY(Vhasta),""," and fecha_ingreso <=" + ClipValue2SQL(Vhasta) + "") ;
          + "" + IF(EMPTY(VPdesde),""," and fecha_entrega >=" + ClipValue2SQL(VPdesde) + "") ; 
          + "" + IF(EMPTY(VPhasta),""," and fecha_entrega <=" + ClipValue2SQL(VPhasta) + "") ;
          + "" + IF(nEstado = 1," "," and estado =  " + ClipValue2Sql(nEstado-1) ) 
   EXIT
ENDDO
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oQryBrw:Refresh()
oBrwG:Refresh()
RETURN nil


************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
STATIC FUNCTION Acelerador2(nKey, oBar,cPermisos)
IF nkey = VK_F2
   oBar:aControls[1]:Click()
ENDIF
IF nKey = VK_F3 
   oBar:aControls[2]:Click()
ENDIF
IF nKey = VK_F4
   oBar:aControls[3]:Click()
ENDIF
IF nKey = VK_F6
   oBar:aControls[5]:Click()
ENDIF
IF nKey = VK_F7
   oBar:aControls[6]:Click()
ENDIF

RETURN NIL


************************************************************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( )
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



**************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQryBrw:id
IF oQryBrw:estado = 6
   MsgStop("No se puede eliminar este service porque fue dado de baja de stock","Atencion")
   RETURN nil 
ENDIF   
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el pedido  N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"service WHERE id = " + ClipValue2Sql(oQryBrw:id))
  oApp:oServer:CommitTransaction()
  Auditar(1," "+ALLTRIM(oQryBrw:cliente)+ " Service. N° "+alltrim(STR(oQryBrw:ID,10)))
  oQryBrw:Refresh()
CATCH oError
    ValidaError(oError)
END TRY
oBrwG:Refresh()
RETURN nil 


STATIC FUNCTION ReporSer()
RETURN nil
/*
*******************************************
** Impresion de Service
FUNCTION ImprimirPedido(base)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado – Ley Nº 19.640",;
                "IVA Responsable Inscripto – Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA NO Alcanzado"},oQryDet1,;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, config, oQryCli, lRta := .F.,;
      oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))
   IF base:codcli = nil
      nCodcli := oGet[08]:value       
   ENDIF
   IF oQryP:imprimeTic
      lRta := MsgNoYes("Desea reporte por comandera?","Atencion")
   ENDIF      
   oQryDet1:= oApp:oServer:Query("SELECT * FROM ventas_det_h2")
   oQryCli := oApp:oServer:Query("SELECT c.*,v.nombre as nomven FROM ge_"+oApp:cId+"clientes c "+;
                                 "LEFT JOIN ge_"+oApp:cId+"vendedores v ON v.codigo = c.vendedor "+;
                                 " WHERE c.codigo = "+Clipvalue2sql(base:codcli))
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   oApp:cDestinoMail := oApp:oServer:Query("SELECT mail FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(base:codcli)):mail
   IF !lRta
       ** PEDIDOS
       DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
       DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
       DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD   
       DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
       PRINT oPrn NAME "Pedido"  PREVIEW MODAL
       oPrn:SetPortrait()
       oPrn:SetPage(9)
       FOR x := 1 TO 2
         PAGE
         nRow := (oPrn:nHorzRes() / 80) / 47
         @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
         *oPrn:SayImage(0,0, "fondofac.jpg",;
         *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
         oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
         @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                  SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
         oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
         oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
         oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos 
         oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva   
         
         IF config:x1 = 2 .or. config:x1 = 3
            @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
         ENDIF
         IF config:x1 = 1 .or. config:x1 = 3
             @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                      SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
             @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                      SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
             @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                      SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
         ENDIF

         oPrn:CmSay( 2  , 11, "PEDIDO", oFont1 )   
         *oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
         oPrn:CmSay( 1.5, 9.8, " ",oFont2)
         oPrn:CmSay( 2.5, 11, "Pedido Nro:"+STR(base:id,8),oFont)    
         oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(base:fecha),oFont)

         oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
         oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
         oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

         @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 5.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:cuit);
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
         @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
         @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
         @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryCli:coniva] ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
         @ 7,1  PRINT TO oPrn TEXT "Telefono:" ;
                  SIZE 3,.5 CM FONT oFont3 ALIGN "R"
         @ 7,4.1 PRINT TO oPrn TEXT oQryCli:telefono ;
                  SIZE 6,.5 CM FONT oFont ALIGN "L"
         nRow := IF(nRow<6,6,nRow)
         @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
         @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                               ALLTRIM(oQryCli:localidad) ;
                  SIZE 8,1 CM FONT oFont ALIGN "L"
         
         @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                          SIZE 2.8,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                  SIZE 7,.5 CM FONT oFont ALIGN "L"
         @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unitario" ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"
         @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal" ;
                  SIZE 3,.5 CM FONT oFont ALIGN "R"
             
         y := 9.2
         oQryDet1:GoTop()
         FOR i = 1 TO oQryDet1:nRecCount          
               @ y, 01 PRINT TO oPrn TEXT STR(oQryDet1:codart,13) ;
                  SIZE 2.8,.5 CM FONT oFont ALIGN "R"
               @ y+0.06, 04 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart) ;
                  SIZE 7,1.5 CM FONT oFont LASTROW nRow
               @ y, 11 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,08,2) ;
                  SIZE 2,.5 CM FONT oFont ALIGN "R"  
               @ y, 14 PRINT TO oPrn TEXT oQryDet1:ptotal/oqrydet1:cantidad ;
                          SIZE 2,.5 CM FONT oFont ALIGN "R"
               @ y, 17 PRINT TO oPrn TEXT oQryDet1:ptotal;
                    SIZE 3,.5 CM FONT oFont ALIGN "R"             
               y := nRow + .1
               IF y > 21
                    @ 23, 05 PRINT TO oPrn TEXT "CONTINUA EN OTRA HOJA";
                      SIZE 9,2 CM FONT oFont
                    ENDPAGE 
                    PAGE
                     nRow := (oPrn:nHorzRes() / 80) / 47
                     @ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
                     *oPrn:SayImage(0,0, "fondofac.jpg",;
                     *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )
                     oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
                     @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                              SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
                     oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
                     oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
                     oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos 
                     oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva   
                     
                     IF config:x1 = 2 .or. config:x1 = 3
                        @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
                     ENDIF
                     IF config:x1 = 1 .or. config:x1 = 3
                         @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                                  SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
                         @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
                         @ nRow, 01 PRINT TO oPrn TEXT aiva[oApp:tipo_iva] ;
                                  SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF

                     oPrn:CmSay( 2  , 11, "PEDIDO", oFont1 )   
                     *oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
                     oPrn:CmSay( 1.5, 9.8, " ",oFont2)
                     oPrn:CmSay( 2.5, 11, "Pedido Nro:"+STR(base:id,8),oFont)    
                     oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(base:fecha),oFont)

                     oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
                     oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
                     oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)

                     @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                     @ 5.5, 4.1 PRINT TO oPrn TEXT ALLTRIM(oQryCli:cuit);
                              SIZE 6,.5 CM FONT oFont ALIGN "L"
                     @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                              SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                     @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre) ;
                              SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                     @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryCli:coniva] ;
                              SIZE 6,.5 CM FONT oFont ALIGN "L"
                     @ 7,1  PRINT TO oPrn TEXT "Telefono:" ;
                              SIZE 3,.5 CM FONT oFont3 ALIGN "R"
                     @ 7,4.1 PRINT TO oPrn TEXT oQryCli:telefono ;
                              SIZE 6,.5 CM FONT oFont ALIGN "L"
                     nRow := IF(nRow<6,6,nRow)
                     @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                              SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
                     @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:direccion) + " " + ;
                                                           ALLTRIM(oQryCli:localidad) ;
                              SIZE 8,1 CM FONT oFont ALIGN "L"
                     
                     @ 8.2, 01 PRINT TO oPrn TEXT "Codigo" ;
                                      SIZE 2.8,.5 CM FONT oFont ALIGN "R"
                     @ 8.2, 04 PRINT TO oPrn TEXT "Descripcion del producto" ;
                              SIZE 7,.5 CM FONT oFont ALIGN "L"
                     @ 8.2, 11 PRINT TO oPrn TEXT "Cantidad" ;
                              SIZE 2,.5 CM FONT oFont ALIGN "R"
                     @ 8.2, 14 PRINT TO oPrn TEXT "Pr.Unitario" ;
                              SIZE 2,.5 CM FONT oFont ALIGN "R"
                     @ 8.2, 17 PRINT TO oPrn TEXT "Subtotal" ;
                              SIZE 3,.5 CM FONT oFont ALIGN "R"
                         
                     y := 9.2
                 ENDIF
               oQryDet1:Skip()
         NEXT    
         @ y, 1 PRINT TO oPrn TEXT ALLTRIM(oGet[42]:cText) ;
                          SIZE 18,3 CM FONT oFont ALIGN "L"   
         @ 23.0,1  PRINT TO oPrn TEXT IF(!empty(oQryCli:nomven),"Vendedor: "+ALLTRIM(oQryCli:nomven),"") ;
                      SIZE 5,.5 CM FONT oFont3                 
         @ 23.5, 12 PRINT TO oPrn TEXT "Total $:" ;
                          SIZE 4,.5 CM FONT oFont3 ALIGN "R"
                     @ 23.5, 17 PRINT TO oPrn TEXT STR(nTotal,12,2) ;
                          SIZE 3,.5 CM FONT oFont ALIGN "R"  
       ENDPAGE
       NEXT x
       ENDPRINT
       oApp:cDestinoMail := " "
       /// Reporte por comandera
       ELSE 
       ** PEDIDOS
       IF config:fon > 25
          config:fon := config:fon /3
       ENDIF  
       DEFINE FONT oFont   NAME "COURIER NEW" SIZE config:fon,config:fon*2.5
       DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
       IF !oApp:tick80
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT) 
               PAGE
                 nRow := 1
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1 PRINT TO oPrn IMAGE "logo.jpg" SIZE 3, 1.5 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 5,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     
                 @ nRow, 00 PRINT TO oPrn TEXT "PEDIDO" ;
                          SIZE 4.8,1 CM FONT oFont LASTROW nRow ALIGN "C"
                 nRow := nRow + .5
                 @ nRow, 00 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(oQryCli:nombre) ;
                      SIZE 4.8,1 CM FONT oFont1 LASTROW nRow
                 @ nRow, 00 PRINT TO oPrn TEXT "Direccion: "+ALLTRIM(oQryCli:direccion) + " "+ ALLTRIM(oQryCli:localidad) ;
                      SIZE 4.8,1.5 CM FONT oFont LASTROW nRow
                 @ nRow, 00 PRINT TO oPrn TEXT "Telefono: "+ALLTRIM(oQryCli:telefono)  ;
                      SIZE 4.8,1 CM FONT oFont LASTROW nRow
                 nRow := nRow + 1
                 @ nRow, 00 PRINT TO oPrn TEXT "Producto" ;
                              SIZE 3,.5 CM FONT oFont 
                 @ nRow, 03.1 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 1.5,.5 CM FONT oFont ALIGN "R"
                 oQryDet1:GoTop()
                 y := nRow + .5
                 FOR i = 1 TO oQryDet1:nRecCount          
                       
                       @ y, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart) ;
                          SIZE 3,1 CM FONT oFont LASTROW nRow
                       @ y, 3.1 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,08,2) ;
                          SIZE 1.5,.5 CM FONT oFont ALIGN "R"  
                         y := nRow + .1
                       oQryDet1:Skip()
                 NEXT  
                 y := y + .5  
                 @ y, 0 PRINT TO oPrn TEXT ALLTRIM(oGet[42]:cText) ;
                              SIZE 4.5,3 CM FONT oFont ALIGN "L" LASTROW nRow   
                 @ nRow, 00 PRINT TO oPrn TEXT "Total $:" + STR(nTotal,12,2);
                              SIZE 4,.5 CM FONT oFont1 ALIGN "R"
                 @ nRow+.5,.1 PRINT TO oPrn TEXT "...";
                              SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"
           ENDPAGE
           ENDPRINT
           ELSE
           // Ticket 80 mm
           PRINT oPrn TO ALLTRIM(oQryP:impresoraT) 
               PAGE
                 nRow := 0
                 IF config:x1 = 2 .or. config:x1 = 3
                    @ 0,1.5 PRINT TO oPrn IMAGE "logo.jpg" SIZE 5, 2 CM LASTROW nRow
                 ENDIF
                 IF config:x1 = 1 .or. config:x1 = 3
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                              SIZE 8,.5 CM FONT oFont1 ALIGN "C" LASTROW nRow
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oApp:dire_emp) ;
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"    
                     @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(aiva[oApp:tipo_iva]) ;
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 ENDIF
                 @ nRow, .1 PRINT TO oPrn TEXT "CUIT:"+oApp:cuit_emp ;
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Ing.br:"+ALLTRIM(oApp:ingb_emp);
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                 @ nRow, .1 PRINT TO oPrn TEXT "Inic.Act.:"+DTOC(oApp:inac_emp);
                              SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                              
                 @ nRow, 00 PRINT TO oPrn TEXT "PEDIDO" ;
                          SIZE 7.5,1 CM FONT oFont1 LASTROW nRow ALIGN "C"
                 nRow := nRow + .5
                 @ nRow, 00 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(oQryCli:nombre) ;
                      SIZE 7.5,1 CM FONT oFont1 LASTROW nRow
                 @ nRow, 00 PRINT TO oPrn TEXT "Direccion: "+ALLTRIM(oQryCli:direccion) + " "+ ALLTRIM(oQryCli:localidad) ;
                      SIZE 7.5,1.5 CM FONT oFont LASTROW nRow
                 @ nRow, 00 PRINT TO oPrn TEXT "Telefono: "+ALLTRIM(oQryCli:telefono)  ;
                      SIZE 7.5,1 CM FONT oFont LASTROW nRow
                 nRow := nRow + 1
                 @ nRow, 00 PRINT TO oPrn TEXT "Producto" ;
                              SIZE 4,.5 CM FONT oFont
                 @ nRow, 04.1 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 1.5,.5 CM FONT oFont ALIGN "R"
                 @ nRow, 05.6 PRINT TO oPrn TEXT "Total" ;
                      SIZE 1.7,.5 CM FONT oFont ALIGN "R"
                 oQryDet1:GoTop()
                 y := nRow + .5
                 FOR i = 1 TO oQryDet1:nRecCount          
                       
                       @ y, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet1:detart) ;
                          SIZE 4,1 CM FONT oFont LASTROW nRow
                       @ y, 4.1 PRINT TO oPrn TEXT STR(oQryDet1:cantidad,08,2) ;
                          SIZE 1.5,.5 CM FONT oFont ALIGN "R" 
                       @ y, 5.6 PRINT TO oPrn TEXT STR(oQryDet1:ptotal,12,2) ;
                          SIZE 1.7,.5 CM FONT oFont ALIGN "R"  
                         y := nRow + .1
                       oQryDet1:Skip()
                 NEXT  
                 y := y + .2  
                 @ y, 0 PRINT TO oPrn TEXT ALLTRIM(oGet[42]:cText) ;
                              SIZE 7.5,3 CM FONT oFont ALIGN "L" LASTROW nRow   
                 @ nRow, 00 PRINT TO oPrn TEXT "Total $:" + STR(nTotal,12,2);
                              SIZE 7.5,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow   
                 @ nRow, 00 PRINT TO oPrn TEXT "...";
                              SIZE 7.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
           ENDPAGE
           ENDPRINT
        ENDIF
    ENDIF
RETURN nil





***********************************
** Reporte de pedidos 
STATIC FUNCTION ReporPed()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,oGru,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(3), oBot1, oBot2, ;
      mdesde := DATE(), mhasta := DATE(), mtotal := 0, lResu := .t.
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte de Pedidos Pendientes" FROM 03,15 TO 13,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Para Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) 
   @ 35 ,65 CHECKBOX oGet[3] VAR lResu PROMPT "Resumido" OF oDlg1 PIXEL SIZE 90,12   
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
IF lResu
    oQry := oApp:oServer:Query("SELECT SUM(p.cantidad) AS cantidad, SUM(p.punitario * p.cantidad) as importe, "+;                         
                         " p.detart, p.codart"+;                         
                         " FROM ge_"+oApp:cId+"pedidos_det p "+;                         
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_encab p1 ON p1.id = p.idpedido "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         " AND p1.estado = 'P' "+;
                         " GROUP BY p.codart,p.detart ")
    REPORT oRep TITLE "Pedidos Pendientes" + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Pedidos Pendientes" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Pedidos Pendientes"

    COLUMN TITLE "Producto"   DATA oQry:detart     SIZE 30 FONT 1
    COLUMN TITLE "Unidades"   DATA oQry:cantidad  PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
    COLUMN TITLE "Total $"    DATA oQry:importe   PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
    COLUMN TITLE "Codigo"     DATA oQry:codart   PICTURE "99999999999999" SIZE 12 FONT 1
    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
             ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
    oQry:End()
    ELSE
    oQry := oApp:oServer:Query("SELECT p1.id,p.cantidad,p.detart,p.codart,p1.parafecha,"+;
                         "c.nombre,c.codigo as codcli, p1.observa,p.cantidad*p.punitario as importe "+;                         
                         " FROM ge_"+oApp:cId+"pedidos_encab p1 "+;
                         " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p1.codcli "+;
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_det p ON p.idpedido = p1.id "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         " AND p1.estado = 'P' "+;
                         " ORDER BY p1.id,p.codart ")
    REPORT oRep TITLE "Pedidos Pendientes (Detalle) " + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Pedidos Pendientes" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Pedidos Pendientes (Detalle) "
    GROUP oGru ON oQry:id HEADER "Cliente: "+ALLTRIM(STR(oQry:codcli))+" "+ALLTRIM(oQry:nombre) + " "+ALLTRIM(oQry:observa) FOOTER "Totales Cliente"  FONT 3
    COLUMN TITLE "N° Pedido"  DATA oQry:id         SIZE 08 FONT 1
    COLUMN TITLE "Producto"   DATA oQry:detart     SIZE 30 FONT 1 
    COLUMN TITLE "Unidades"   DATA oQry:cantidad  PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
    COLUMN TITLE "Importe"    DATA oQry:importe  PICTURE "999999999.999" SIZE 10 FONT 1 TOTAL
    COLUMN TITLE "Codigo"     DATA oQry:codart   PICTURE "99999999999999" SIZE 12 FONT 1
    COLUMN TITLE "Para Fecha" DATA oQry:parafecha    SIZE 8 FONT 1
    // Digo que el titulo lo escriba con al letra 2
    oRep:oTitle:aFont[1] := {|| 2 }
    oRep:bInit := {|| oQry:GoTop() }
    oRep:bSkip := {|| oQry:Skip() }

    END REPORT
    ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
             ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
    oQry:End()
ENDIF    
RETURN nil

*/


****************************************FILTRADO**********************
STATIC FUNCTION Recupera()
   LOCAL oFilt,oGet:=ARRAY(7),oBot:=ARRAY(2),acor:=ARRAY(4),oError,lRta:=.f.,oFont,cWhere,;
   nEstado := 1,;
   aEstado := {'En revisión', 'Reparado', 'No reparado', 'Entregado', 'Descartado'}
   
IF oQryBrw:estado <> 6
   MsgStop('Este producto no esta en estado de BAJA',"Error")
   RETURN NIL 
ENDIF   
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

                        
    DEFINE DIALOG oFilt TITLE "Recuperar estado de baja";
           FROM 05,15 TO 18,70 OF oWnd1 FONT oFont
       @ 07, 05 SAY "Pasar a Estado:"                 OF oFilt PIXEL SIZE 50,20 RIGHT 
       @ 05, 60 COMBOBOX oGet[07] VAR nEstado ITEMS aEstado   OF oFilt PIXEL SIZE 90,12

          
       acor := AcepCanc(oFilt)
       @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Recupera" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .t.), oFilt:End() ) PIXEL
       @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oFilt SIZE 30,10 ;
               ACTION ((lRta := .f.), oFilt:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oFilt CENTER 

    IF !lRta
        RETURN nil
    ENDIF    
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha","motivo","costo"},;
                           {oQryBrw:codart,1,0,DATE(),6,0})
  oApp:oServer:Execute('UPDATE ge_'+oApp:cId+'articu SET STOCKACT = STOCKACT + 1 WHERE codigo = '+Clipvalue2sql(oQryBrw:codart))  
  oApp:oServer:Execute('UPDATE ge_'+oApp:cId+'service SET estado = '+Clipvalue2sql(nEstado)+' WHERE id = '+Clipvalue2sql(oQryBrw:id))  
  oQryBrw:Refresh(.t.)   
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrwG:Refresh()
RETURN nil



STATIC FUNCTION validarqueexista()

IF !oApp:oServer:TableExist('ge_'+oApp:cId+"service")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"service ( "+;
  "`id` INT(10) NOT NULL AUTO_INCREMENT, "+;
  "`codart` bigint(14) NOT NULL,"+;
  "`numero_serie` VARCHAR(100) NOT NULL,"+;
  "`codcli` int(8) NOT NULL,"+;
  "`cliente` varchar(60) NOT NULL,"+;
  "`facturanro` VARCHAR(16) NULL,"+;
  "`fecha_ingreso` DATE NOT NULL,"+;
  "`observa` TEXT NOT NULL,"+;
  "`diagnostico` TEXT NULL,"+;
  "`estado` INT(2) DEFAULT '1',"+;
  "`fecha_reparacion` DATE NULL,"+;  
  "`fecha_entrega` DATE NULL,"+;
  "`notas_adicionales` TEXT NULL,"+; 
  "PRIMARY KEY (`id`)"+;   
  ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")

ENDIF
RETURN nil 