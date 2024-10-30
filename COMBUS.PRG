#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
*************************************************
** CARGA DE SURTIDORES
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana,oError
PROCEDURE Combus(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"combus ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Registro de combustible" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu(.t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(.f. ),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Combustible",.T.,.F.);
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
              COLUMNS "fecha","saldoini","saldofin","ventasfac","ventasrem","ventasdir","preciolit";
              HEADERS "Fecha","Lectura In.","Lectura Fin","Contado","Cta.Cte.","Sin.Doc.","$ x Litro";
              SIZES 110,110,110,110,110,110,110;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(.f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[4]:bStrData := {|| oQry:ventasfac*oQry:preciolit}
     oBrw:aCols[5]:bStrData := {|| oQry:ventasrem*oQry:preciolit}
     oBrw:aCols[6]:bStrData := {|| oQry:ventasdir*oQry:preciolit}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,7) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
RETURN

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(20), oBot := ARRAY(3), oForm, lRta := .f., aCor, base, aVar := ARRAY(10),;
      oBrwFac, oBrwRem, oQryFac, oQryRem, oFld
AFILL(aVar,0)

IF lAlta
   base := oQry:GetBlankRow()
   base:fecha := oApp:oServer:Query("SELECT MAX(fecha) as fecha FROM ge_"+oApp:cId+"combus"):fecha + 1
   base:saldoini := oApp:oServer:Query("SELECT MAX(saldofin) as saldoini FROM ge_"+oApp:cId+"combus"):saldoini
   base:preciolit := oApp:oServer:Query("SELECT precioven FROM ge_"+oApp:cId+"articu WHERE combustible LIMIT 1"):precioven
   ELSE
   base := oQry:GetRowObj()
   oQry:lAppend := .f.
   base:fecha := oQry:fecha
ENDIF

DO WHILE .T.
   
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Estado de Surtidor";
       FROM 05,15 TO 36,90 OF oWnd1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Fecha Lectura:"    OF oForm PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Lectura Inic.:"    OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Lectura Final:"    OF oForm PIXEL SIZE 50,12 RIGHT
   @ 52, 05 SAY "Facturado:"        OF oForm PIXEL SIZE 50,12 RIGHT 
   @ 67, 05 SAY "Remitado:"         OF oForm PIXEL SIZE 50,12 RIGHT
   @ 82, 05 SAY "A facturar:"       OF oForm PIXEL SIZE 50,12 RIGHT
   @ 97, 05 SAY "Precio x Litro:"   OF oForm PIXEL SIZE 50,12 RIGHT


   @ 22,105 SAY "Dif.Lecturas:"     OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37,105 SAY "Total Combust.:"   OF oForm PIXEL SIZE 50,12 RIGHT
   @ 52,105 SAY "Contado $:"        OF oForm PIXEL SIZE 50,12 RIGHT 
   @ 67,105 SAY "Cta.Cte.$"         OF oForm PIXEL SIZE 50,12 RIGHT
   @ 82,105 SAY "Sin Documentar $:" OF oForm PIXEL SIZE 50,12 RIGHT
   @ 97,105 SAY "Caja Combust. $:"  OF oForm PIXEL SIZE 50,12 RIGHT

 
   @ 05, 60 GET oGet[01] VAR base:fecha  PICTURE "@D" OF oForm PIXEL WHEN(lAlta)
   @ 20, 60 GET oGet[02] VAR base:saldoini OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(lAlta) 
   @ 35, 60 GET oGet[03] VAR base:saldofin OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(lAlta)
   @ 50, 60 GET oGet[04] VAR base:ventasfac OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(.f.)   
   @ 65, 60 GET oGet[05] VAR base:ventasrem OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(.f.)   
   @ 80, 60 GET oGet[06] VAR base:ventasdir OF oForm PICTURE "99999999" PIXEL RIGHT WHEN(.f.)
   @ 95, 60 GET oGet[07] VAR base:preciolit OF oForm PICTURE "99999.99" PIXEL RIGHT WHEN(.f.)
   
  
   /* Calculados */
   @ 20,160 GET oGet[10] VAR aVar[1] OF oForm PICTURE "9999999999" PIXEL RIGHT ;
     WHEN((oGet[10]:cText := (base:saldofin - base:saldoini)) = " ")
   @ 35,160 GET oGet[11] VAR aVar[2] OF oForm PICTURE "9999999.99" PIXEL RIGHT ;
     WHEN((oGet[11]:cText := (base:saldofin - base:saldoini)*base:preciolit) = " ")
   @ 50,160 GET oGet[12] VAR aVar[3] OF oForm PICTURE "9999999.99" PIXEL RIGHT ;
     WHEN((oGet[12]:cText := base:ventasfac * base:preciolit) = " ")
   @ 65,160 GET oGet[13] VAR aVar[4] OF oForm PICTURE "9999999.99" PIXEL RIGHT ;
     WHEN((oGet[13]:cText := base:ventasrem * base:preciolit) = " ")
   @ 80,160 GET oGet[14] VAR aVar[5] OF oForm PICTURE "9999999.99" PIXEL RIGHT ;
     WHEN((oGet[14]:cText := base:ventasdir * base:preciolit) = " ")  
   @ 95,160 GET oGet[15] VAR aVar[6] OF oForm PICTURE "9999999.99" PIXEL RIGHT ;
     WHEN((oGet[15]:cText := aVar[3] + aVar[5]) = " ")  
   /* Folders */
   oQryFac := oApp:oServer:Query("SELECT vd.nrofac AS numfac, c.nombre AS cliente, "+;
                              "vd.cantidad AS cantidad, vd.importe AS importe FROM ge_"+oApp:cId+"ventas_det vd "+;
                              "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = vd.codcli "+;
                              "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = vd.codart "+;
                              "WHERE vd.fecha = "+ClipValue2Sql(oGet[1]:value) +;
                              " AND LEFT(vd.nrofac,2) = 'FC' "+;
                              " AND a.combustible ")
   oQryRem := oApp:oServer:Query("SELECT vd.nrorem AS numfac, c.nombre AS cliente, "+;
                              "vd.cantidad AS cantidad, vd.importe AS importe FROM ge_"+oApp:cId+"remitos vd "+;
                              "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = vd.codcli "+;
                              "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = vd.codart "+;
                              "WHERE vd.fecha = "+ClipValue2Sql(oGet[1]:value) +;
                              " AND a.combustible ")

   @110, 01 FOLDEREX oFld PROMPT ;
     "Ventas Contado","Cuentas corrientes";
      OF oForm SIZE 400, 100 PIXEL 
   @ 00,00 XBROWSE oBrwFac DATASOURCE oQryFac;
                 COLUMNS "numfac","cliente","cantidad","importe";    
                 HEADERS "Comprobante","Cliente","Litros","Importe";
         SIZES 110,200,100,100;
         OF oFld:aDialogs[1] SIZE 390,95 PIXEL   
   PintaBrw(oBrwFac,0)
   oBrwFac:CreateFromCode()
   @ 00,00 XBROWSE oBrwRem DATASOURCE oQryRem;
                 COLUMNS "numfac","cliente","cantidad","importe";    
                 HEADERS "Comprobante","Cliente","Litros","Importe";
         SIZES 110,200,100,100;
         OF oFld:aDialogs[2] SIZE 390,95 PIXEL  
   PintaBrw(oBrwRem,0)
   oBrwRem:CreateFromCode()
   IF lAlta
      Calcular(oGet)
   ENDIF   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
   IF lAlta        
      @ 05,110 BUTTON oBot[3] PROMPT "Calcu&lar" OF oForm SIZE 30,10;
        ACTION (Calcular(oGet),Refresca(oQryFac,oQryRem,oBrwFac,oBrwRem,oGet)) PIXEL;
        WHEN(base:saldofin>0)
   ENDIF           
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF EMPTY(base:fecha) .or. base:ventasfac+base:ventasrem+base:ventasdir = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
    LOOP
END TRY
EXIT
ENDDO
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ( oQry )
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
LOCAL mrta := .f.
mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
oQry:Delete()
RETURN nil

***********************************
** Calcular los litros vendidos
STATIC FUNCTION Calcular(oGet)
LOCAL oQry1
/* Calcular Ventas por factura */
oGet[4]:cText := oApp:oServer:Query("SELECT SUM(cantidad) AS cantidad FROM ge_"+oApp:cId+"ventas_det "+;
                            "LEFT JOIN ge_"+oApp:cId+"articu ON ge_"+oApp:cId+"articu.codigo = ge_"+oApp:cId+"ventas_det.codart "+;
                            "WHERE ge_"+oApp:cId+"ventas_det.fecha = "+ClipValue2Sql(oGet[1]:value) +;
                            " AND LEFT(ge_"+oApp:cId+"ventas_det.nrofac,2) = 'FC' "+;
                            " AND ge_"+oApp:cId+"articu.combustible "):cantidad
oGet[5]:cText := oApp:oServer:Query("SELECT SUM(cantidad) AS cantidad FROM ge_"+oApp:cId+"remitos "+;
                            "LEFT JOIN ge_"+oApp:cId+"articu ON ge_"+oApp:cId+"articu.codigo = ge_"+oApp:cId+"remitos.codart "+;
                            "WHERE ge_"+oApp:cId+"remitos.fecha = "+ClipValue2Sql(oGet[1]:value) +" AND ge_"+oApp:cId+"articu.combustible "):cantidad
oGet[6]:cText := oGet[10]:value - oGet[4]:value - oGet[5]:value  

RETURN nil

STATIC FUNCTION Refresca(oQryFac,oQryRem,oBrwFac,oBrwRem,oGet)
LOCAL cWhere
cWhere := "vd.fecha = "+ClipValue2Sql(oGet[1]:value) +;
          " AND LEFT(vd.nrofac,2) = 'FC' "+;
          " AND a.combustible "
oQryFac:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwFac:Refresh()
cWhere := "vd.fecha = "+ClipValue2Sql(oGet[1]:value) +;
          " AND a.combustible "
oQryRem:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwRem:Refresh()
RETURN nil