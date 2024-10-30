#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM DE CUENTAS BANCATIAS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana
PROCEDURE VERCOMP(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ventas_encab ORDER BY ticomp,numcomp")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Comprobantes" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Ver datos del comprobante"  ;
            ACTION (Formu( ),oBrw:Refresh());
            PROMPT "Ver" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Cuentas bancarias",.T.,.F.);
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
              COLUMNS "ticomp","numcomp","nombre","fecha","importe";
              HEADERS "Comprobante","Numero","Cliente","Fecha","Importe";
              SIZES 50,95,300,90,10;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu(),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,5) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(35), oBot := ARRAY(4), oForm, lRta := .f., aCor, base, oError,poriva,oBrw1,;
      cDescu:="Descuento:",cNumComp,cLetra,oQryDet,oDlg1,oWnd2,nDeuda:=0,cRemitos:=" ",nTipoDoc,;
      oFontLetra,oFontTotal,aTipoDoc := {"Factura","Nota de Débito","Nota de Crédito","Presupuesto","Remito"},;
      oSay1,oSay2,oSay3,nColor,;
      aTipoiva  := {;
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
              "14  Pequeño Contribuyente Eventual Social"}

   base := oQry:GetRowObj()
   DO CASE 
      CASE base:ticomp = "FC"
        nTipoDoc:=1
      CASE base:ticomp = "ND"
        nTipoDoc:=2
      CASE base:ticomp = "NC"
        nTipoDoc:=3
      CASE base:ticomp = "PR"
        nTipoDoc:=4
   ENDCASE
   cNumComp:=RIGHT(base:numcomp,13)
   cLetra:=LEFT(base:numcomp,1)
   oQryDet:= oApp:oServer:Query("SELECT *,neton/cantidad AS punit,neton-descu AS stotal "+;
                                "FROM ge_"+oApp:cId+"ventas_det WHERE nrofac ="+ClipValue2Sql(base:ticomp+base:numcomp))
   nDeuda:= oApp:oServer:Query("SELECT SUM(saldo) AS deuda FROM ge_"+oApp:cId+"ventas_cuota "+;
                                       "WHERE cliente = "+ClipValue2Sql(base:codcli)):deuda
  IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"remitos WHERE codcli = " + ClipValue2Sql(base:codcli)):RecCount() > 0
      cRemitos:= "CLIENTE CON REMITOS "+CHR(10)+"PENDIENTES"
      nColor:=CLR_RED
  ELSE
      cRemitos:= "CLIENTE SIN REMITOS "+CHR(10)+"PENDIENTES"
      nColor:=CLR_GREEN
  ENDIF

//FUENTES -----------------------------------------------
  DEFINE FONT oFontLetra NAME "ARIAL" SIZE 35,60
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30

  DEFINE WINDOW oWnd2 MDICHILD TITLE "Facturacion por ventas" OF oApp:oWnd NOZOOM ICON oApp:oIco
   
    *oWnd1:bGotFocus := { || oDlg1:SetFocus}
    oWnd2:bResized := { || Incrusta( oWnd2, oDlg1, .t.) }

    //DLG -----------------------------------------------
    DEFINE DIALOG oDlg1 RESOURCE "VERCOMP" OF oWnd2
    //Fechas y tipo de Comprobante
    REDEFINE GET oGet[01] VAR base:fecha ID 176  OF oDlg1 WHEN(.F.)
    REDEFINE COMBOBOX oGet[02] VAR nTipoDoc ITEMS aTipoDoc ID 177 OF oDlg1 WHEN(.F.)
    REDEFINE SAY oSay1    VAR cLetra  ID 180  OF oDlg1 FONT oFontLetra
    REDEFINE SAY oSay2    VAR cDescu  ID 999 OF oDlg1
    //Numero de comprobante 
    REDEFINE GET oGet[03] VAR cNumComp   ID 182 OF oDlg1 WHEN (.f.) PICTURE "9999-99999999"

    //CLIENTE
    REDEFINE GET oGet[04] VAR base:codcli ID 185 OF oDlg1 PICTURE "999999" WHEN(.F.) 
    REDEFINE GET oGet[05] VAR base:nombre ID 186 OF oDlg1 PICTURE "@!"  WHEN(.F.)
    REDEFINE GET oGet[06] VAR base:direccion ID 187  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[07] VAR base:localidad ID 188  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[08] VAR base:CUIT      ID 189 OF oDlg1 PICTURE "99-99999999-9" WHEN(.F.)
    REDEFINE GET oGet[09] VAR base:DNI      ID 201 OF oDlg1 PICTURE "99999999" WHEN(.F.)
    REDEFINE COMBOBOX oGet[10] VAR base:ConIva ID 190 OF oDlg1 ITEMS aTipoIva WHEN(.F.) 
    REDEFINE GET oGet[11] VAR base:descu ID 308 OF oDlg1 PICTURE "999.99" WHEN(.F.)
    REDEFINE GET oGet[12] VAR base:Observa  ID 307 OF oDlg1 TEXT WHEN(.F.)
    REDEFINE GET oGet[13] VAR nDeuda    ID 4001 OF oDlg1 PICTURE "99999999.99" WHEN(.F.)
    
    REDEFINE SAY oSay3 VAR cRemitos ID 4002 OF oDlg1 COLOR nColor
          
    //neto y IVA y total
    REDEFINE GET oGet[14] VAR base:Neto  ID 198 OF oDlg1 PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[15] VAR base:IVA   ID 199 OF oDlg1 PICTURE "99999999.99" WHEN(.F.)
    REDEFINE GET oGet[16] VAR base:importe ID 200 OF oDlg1 COLOR CLR_RED , CLR_YELLOW READONLY;
           PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)
       
    //GRILLA ---------------------------------------------------------------      
    
    REDEFINE XBROWSE oBrw1 DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","NETO","DESCU","STOTAL","IVA","IMPORTE","CODIVA";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Neto","Dto./Rec.","Sub Total","IVA","Total","Tasa";
       FOOTERS ;
       SIZES 40,243,55,55,55,55,55,55,55;
    ID 197 OF oDlg1 AUTOSORT
    PintaBrw(oBrw1,0)
    
    oBrw1:aCols[9]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[5]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[6]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[8]:nFooterTypE := AGGR_SUM
    oBrw1:aCols[10]:Hide()
    
    //BOTONES ---------------------------------------------------------------
    REDEFINE BUTTON oBot[4] ID 104 ACTION (oDlg1:End()) CANCEL 
    // F9 Para grabar             
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg1 CENTER NOWAIT ON INIT oDlg1:Move(0,0) VALID(oWnd2:End())
    ACTIVATE WINDOW oWnd2 ON INIT Incrusta( oWnd2, oDlg1, .T.) 
RETURN nil


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

