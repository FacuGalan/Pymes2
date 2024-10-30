#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"


*************************************************
** ABM DE PEDIDOS A PROVEEDOR
*************************************************
MEMVAR oApp
STATIC oQryBrw,oQry,;
       oWnd1, oBrw, oDlg, cVentana,oBrw1,oQryDet,oBrwDet
PROCEDURE PEDPROV(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS detalle_temp ";
    +"(";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(50) NOT NULL,";
    +"`CANTIDAD` DECIMAL(12,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`TOTAL` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(12,2) DEFAULT '0.00', ";
    +"PRIMARY KEY (codart) ";
    +") ENGINE=INNODB DEFAULT CHARSET=utf8")


oQryBrw:= oApp:oServer:Query("SELECT p.id AS id, p.codpro AS codpro, p.fecha AS fecha, pr.nombre AS nompro "+;
                             "FROM ge_"+oApp:cId+"pedprov p LEFT JOIN ge_"+oApp:cId+"provee pr ON pr.codigo = p.codpro")
                        
 
  DEFINE WINDOW oWnd1 MDICHILD TITLE "Pedidos a proveedores" ;
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
            ACTION oBrw:Report("Reporte de Pedidos a Proveedores",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)      
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
         REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
                  COLUMNS "id","fecha","nompro";
                  HEADERS "Pedido","Fecha","Proveedor";
                  SIZES 70,70,200;
                  ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil))
     PintaBrw(oBrw,3) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[2]:SetOrder()
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,5)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN



*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(6), oForm, lRta := .F., aCor, base,;
      oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"provee"),cNomPro:=SPACE(50),;
      nSubTotal:=0,nRetencio:=0,nTotal:=0,oError

oApp:oServer:Execute("TRUNCATE detalle_temp")

oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS articulos_temp ";
    +"(";  
    +"`codigo` VARCHAR(16) NOT NULL,";
    +"`nombre` VARCHAR(70) NOT NULL,";
    +"`costo` DECIMAL(12,3),";
    +"`palets` INT(4),";
    +"`baja` TINYINT(1),";
    +"`cantidad` DECIMAL(12,3) NOT NULL default 0,";
    +"`bultos` INT(6) NOT NULL default 0) ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:Execute("TRUNCATE articulos_temp")

IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"pedprov LIMIT 0")
   base := oQry:GetBlankRow()
   base:id := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pedprov")
   base:fecha := DATE()
   base:descuento:= 0
   base:reten    := 0
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"pedprov WHERE id = " + ClipValue2Sql(oQryBrw:id))
   base := oQry:GetRowObj()
   oApp:oServer:Execute("INSERT INTO detalle_temp (codart,detart,cantidad,punit,descuento,total) "+;
                        "(SELECT codart,detart,cantidad,punit,descuento,total FROM ge_"+oApp:cId+"pedprov_det WHERE numero = "+ClipValue2Sql(oQryBrw:id)+")")
   oQryPro:GoTop()
   IF oQryPro:Seek(base:codpro,1) > 0
      cNomPro := oQryPro:nombre
   ENDIF
  
ENDIF

oQryDet:= oApp:oServer:Query("SELECT * FROM detalle_temp")

DO WHILE .T.
DEFINE DIALOG oForm RESOURCE "PEDPROV" OF oWnd1
 oForm:lHelpIcon := .f.
 
 REDEFINE GET oGet[01] VAR base:id PICTURE "9999999999" ID 101 OF oForm WHEN(.F.)
 REDEFINE GET oGet[02] VAR base:codpro PICTURE "999999" ID 102 OF oForm ;
              VALID(Buscar(oQryPro,oForm,oGet[2],oGet[3]) .AND. (oGet[06]:cText:=oQryPro:retencio) <> "xxx");
              ACTION (oGet[2]:cText:= 0, Buscar(oQryPro,oForm,oGet[2],oGet[3])) BITMAP "BUSC1"
 REDEFINE GET oGet[03] VAR cNomPro ID 103 OF oForm  PICTURE "@!" WHEN(.F.)
 REDEFINE GET oGet[04] VAR base:fecha     PICTURE "@D" ID 104 OF oForm
 REDEFINE GET oGet[05] VAR base:descuento PICTURE "999.99" ID 105 OF oForm WHEN(oQryDet:RecCount()=0)
 REDEFINE GET oGet[06] VAR base:reten     PICTURE "999.99" ID 106 OF oForm WHEN(.F.)

 REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","DESCUENTO","TOTAL";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Descu","Total";
       FOOTERS ;
       SIZES 60,300,60,60,60,80;
    ID 201 OF oForm AUTOSORT 
    PintaBrw(oBrwDet,0)
oBrwDet:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(EliminarItem(),;
                                   CalcTot(oGet)),)}

oBrwDet:aCols[3]:nFooterTypE := AGGR_SUM
oBrwDet:aCols[3]:nEditType   := EDIT_GET
oBrwDet:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,base:descuento,oGet)} 
oBrwDet:aCols[4]:nEditType   := EDIT_GET
oBrwDet:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(,xval,base:descuento,oGet)} 
oBrwDet:aCols[5]:nFooterTypE := AGGR_SUM
oBrwDet:aCols[6]:nFooterTypE := AGGR_SUM
oBrwDet:Maketotals()


 REDEFINE GET oGet[07] VAR nSubTotal PICTURE "999999999.99" ID 107 OF oForm WHEN(.F.)
 REDEFINE GET oGet[08] VAR nRetencio PICTURE "999999999.99" ID 108 OF oForm WHEN(.F.)
 REDEFINE GET oGet[09] VAR nTotal    PICTURE "999999999.99" ID 109 OF oForm WHEN(.F.)

  REDEFINE BUTTON oBot[1] ID 301 OF oForm PROMPT "&Grabar";
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 302 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
  REDEFINE BUTTON oBot[3] ID 303 OF oForm ACTION (EligeArt(oForm,oGet),CalcTot(oGet))

  REDEFINE BUTTON oBot[4] ID 4001 OF oForm ACTION oBrwDet:ToExcel()
  REDEFINE BUTTON oBot[5] ID 4002 OF oForm ACTION PrintPedidoPro(oQryDet,base,cNomPro)
  REDEFINE BUTTON oBot[6] ID 4003 OF oForm ACTION EligeArtMul(oQryDet,base,cNomPro,oForm,oGet)

 
ACTIVATE DIALOG oForm CENTER ON INIT (CalcTot(oGet),oGet[2]:SetFocus())

IF !lRta
   RETURN nil
ENDIF

base:usuario:= oApp:usuario
base:fecmod := DATE()
base:ip     := oApp:cIp
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedprov_det WHERE numero = "+ClipValue2Sql(base:id))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedprov_det (numero,codart,detart,cantidad,punit,descuento,total) "+;
                       "(SELECT "+ClipValue2Sql(base:id)+",codart,detart,cantidad,punit,descuento,total FROM detalle_temp)")
  oQry:Refresh()
  oQryBrw:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

***********************************************************************************************************************************
***** ELEGIR ARTICULO
STATIC FUNCTION EligeArt(oDlg,oGet1)
LOCAL oGet := ARRAY(4), oBot := ARRAY(3), oForm, lRta := .F., aCor, base, oError, oQry,;
      cNomArt:=SPACE(50),oQryArt,nCantidad:=1,nCodArt:=0,nPrecio:=0

oQryArt:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu")


DEFINE DIALOG oForm TITLE "Encargar articulo";
       FROM 05,15 TO 15,90 OF oDlg FONT oApp:oFont
   
   @ 07, 05 SAY "Articulo:"   OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Precio:"     OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Cantidad:"   OF oForm PIXEL SIZE 40,12 RIGHT
  
   @ 05, 50 GET oGet[1] VAR nCodArt OF oForm SIZE 40,12 RIGHT PICTURE "99999999999999" PIXEL;
                VALID(ValidaArt(oQryArt,oForm,oGet));
                ACTION (oGet[1]:cText:= 0, ValidaArt(oQryArt,oForm,oGet)) BITMAP "BUSC1"
   @ 05, 95 GET oGet[2] VAR cNomArt   PICTURE "@!" OF oForm PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[3] VAR nPrecio   PICTURE "99999999.999" OF oForm PIXEL RIGHT 
   @ 35, 50 GET oGet[4] VAR nCantidad PICTURE "9999999.999" OF oForm PIXEL RIGHT;
                VALID(nCantidad>0)
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Agregar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL

ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
   RETURN .F.
ENDIF
TRY 
  oApp:oServer:Execute("INSERT INTO detalle_temp (codart,detart,cantidad,punit,descuento,total) "+;
                     "VALUES("+ClipValue2Sql(nCodArt)+","+ClipValue2Sql(cNomArt)+","+ClipValue2Sql(nCantidad)+","+;
                               ClipValue2Sql(nPrecio)+","+;
                               ClipValue2Sql((nPrecio*nCantidad)*(oGet1[5]:value/100))+","+;
                               ClipValue2Sql((nPrecio*nCantidad)-((nPrecio*nCantidad)*(oGet1[5]:value/100)))+")")
CATCH oError
    ValidaError(oError)
END TRY
RETURN .T.

**************************************************************************************************
***** VALIDAR ARTICULO 
STATIC FUNCTION ValidaArt(oQryArt,oForm,oGet)
LOCAL oQryIva
BuscarArt(oQryArt,oForm,oGet[1],oGet[2])

oQryIva:= oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+ClipValue2Sql(oQryArt:iva))

oGet[3]:cText:= IF(oQryArt:siniva,oQryArt:precossiva,oQryArt:precossiva/(1+oQryIva:tasa/100))

RETURN .t.

**************************************************************************************************
***** CALCULAR TOTALES 
STATIC FUNCTION CalcTot(oGet)
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:Maketotals()
oGet[07]:cText := oBrwDet:aCols[6]:nTotal 
oGet[08]:cText := oBrwDet:aCols[6]:nTotal * (oGet[06]:value/100)
oGet[09]:cText := oBrwDet:aCols[6]:nTotal + oGet[08]:value

RETURN nil 


************************************************************************************
** Borrar item de la venta
STATIC FUNCTION EliminarItem()
LOCAL cLetra
IF oQryDet:nRecCount > 0
  oQryDet:DELETE()
  oBrwDet:Refresh()
  oQryDet:Refresh()
  oBrwDet:Maketotals()
ENDIF
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
LOCAL mrta := .f., oError, nNum := oQryBrw:id
IF oQryBrw:id = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedprov WHERE id = "+ClipValue2Sql(oQryBrw:id))
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedprov_det WHERE numero = "+ClipValue2Sql(oQryBrw:id))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh()

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


****************************************
** Imprimir Pedido
STATIC FUNCTION PrintPedidoPro(oQryDet,base,cNomPro)
LOCAL i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, config, nTotal := 0, nTotRet := 0
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
   ** PEDIDO
   DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
   DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
   DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD
   DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD
   
   PRINT oPrn NAME "Orden de Compra" PREVIEW MODAL
   oPrn:SetPortrait()
   oPrn:SetPage(9)
   FOR x := 1 TO 1
     PAGE            
       oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
       oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
       oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
       oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
       oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
       @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
              SIZE 18,.9 CM FONT oFont1 ALIGN "C"    
       IF config:x1 = 2 .or. config:x1 = 3
          @ 1.6,.6 PRINT TO oPrn IMAGE "logo.jpg" SIZE 8, 3 CM 
       ENDIF
       IF config:x1 = 1 .or. config:x1 = 3
           @ 2, 01 PRINT TO oPrn TEXT ALLTRIM(oApp:nomb_emp) ;
                    SIZE 9,1 CM FONT oFont1 ALIGN "C" LASTROW nRow
           @ nRow, 01 PRINT TO oPrn TEXT "Domicilio Comercial:"+oApp:dire_emp ;
                    SIZE 9,1 CM FONT oFont LASTROW nRow ALIGN "C"    
       ENDIF
       
       oPrn:CmSay( 2  , 11, "Orden de Compra", oFont1 )       
       oPrn:CmSay( 2.5, 11, "Nro de Orden de Compra:"+STRTRAN(STR(base:id,8)," ","0"),oFont)
       oPrn:CmSay( 3.0, 11, "Fecha de emision:"+DTOC(base:fecha),oFont)

       oPrn:CmSay( 3.5, 11, "CUIT:"+oApp:cuit_emp,oFont)
       oPrn:CmSay( 4.0, 11, "Ingresos brutos:"+oApp:ingb_emp,oFont) 
       oPrn:CmSay( 4.5, 11, "Inicio de Actividades:"+DTOC(oApp:inac_emp),oFont)    
            

       @ 5.5, 1  PRINT TO oPrn TEXT "Razon Social:" ;
                  SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
       @ 5.5, 1 PRINT TO oPrn TEXT ALLTRIM(cNomPro) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "R"
       @ 5.5, 9  PRINT TO oPrn TEXT "Dto pactado: %" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
       @ 5.5, 12 PRINT TO oPrn TEXT STR(base:descuento,6,2) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
       @ 6.5, 9  PRINT TO oPrn TEXT "Retencion: %" ;
                  SIZE 2.5,1 CM FONT oFont3 ALIGN "R"
       @ 6.5, 12 PRINT TO oPrn TEXT STR(base:reten,6,2) ;
                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"

       @ 8.2, 0.7 PRINT TO oPrn TEXT "Codigo" ;
                SIZE 2.5,.9 CM FONT oFont3 ALIGN "R"
       @ 8.2, 3.5 PRINT TO oPrn TEXT "Descripcion del producto" ;
                SIZE 6.5,.9 CM FONT oFont3 ALIGN "L"
       @ 8.2, 10 PRINT TO oPrn TEXT "Cantidad" ;
                SIZE 2,.9 CM FONT oFont3 ALIGN "R"
       @ 8.2, 13 PRINT TO oPrn TEXT "Pr.Unitario" ;
                SIZE 2,.9 CM FONT oFont3 ALIGN "R"
       @ 8.2, 15.7 PRINT TO oPrn TEXT "Desc." ;
                      SIZE 1.5,.9 CM FONT oFont1 ALIGN "C"
       @ 8.2, 18 PRINT TO oPrn TEXT "Subtotal" ;
                SIZE 2,.9 CM FONT oFont3 ALIGN "R"             
               
       y := 9.2
       oQryDet:GoTop()      
       DO WHILE !oQryDet:Eof()           
           @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                        SIZE 2.5,.5 CM FONT oFont3 ALIGN "L"
           @ y+.07, 03.5 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                SIZE 6.5,1.5 CM FONT oFont3 LASTROW nRow 
           @ y-0.07, 10 PRINT TO oPrn TEXT STR(oQryDet:cantidad,12,2) ;
                SIZE 2,.5 CM FONT oFont3 ALIGN "R"
           @ y-0.07, 13 PRINT TO oPrn TEXT STR(oQryDet:punit,12,2) ;
                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
           @ y-0.07, 15.7 PRINT TO oPrn TEXT STR(oQryDet:descuento,12,2) ;
                SIZE 2,.5 CM FONT oFont3 ALIGN "R" 
           @ y-0.07, 18 PRINT TO oPrn TEXT STR(oQryDet:total,12,2) ;
                SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"   
           nTotal := nTotal + oQryDet:total        
           oQryDet:Skip()
           y := nRow + .1    
       ENDDO
       oQryDet:GoTop()
       @ 22.5, 12 PRINT TO oPrn TEXT "Subtotal $:" ;
                      SIZE 4,.5 CM FONT oFont3 ALIGN "R"
       @ 22.5, 17 PRINT TO oPrn TEXT STR(nTotal,12,2) ;
            SIZE 3,.5 CM FONT oFont1 ALIGN "R"
       @ 23, 12 PRINT TO oPrn TEXT "Retenciones $:" ;
            SIZE 4,.5 CM FONT oFont3 ALIGN "R"
       @ 23, 17 PRINT TO oPrn TEXT STR(nTotal  * (base:reten/100),12,2) ;
            SIZE 3,.5 CM FONT oFont1 ALIGN "R"
       @ 23.5, 12 PRINT TO oPrn TEXT "Total $:" ;
            SIZE 4,.5 CM FONT oFont3 ALIGN "R"
       @ 23.5, 17 PRINT TO oPrn TEXT STR(nTotal  *(1+ (base:reten/100)),12,2) ;
            SIZE 3,.5 CM FONT oFont1 ALIGN "R"           
       ENDPAGE
     NEXT x
   ENDPRINT
RETURN nil


**********************************************************************************************************************
****** AGREGAR ARTICULO A LA ORDEN 
STATIC FUNCTION EligeArtMul(oQryDet,base,cNomPro,oWnd1,oGet1)
LOCAL oDlg1,oBrwLis,oQryLis,oBot1,oBot2,mRta:=.f.,acor:=ARRAY(4), lBorra := .t., oChe, oError
ActualizaArt(base:codpro)
oQryLis:= oApp:oServer:Query("SELECT * FROM articulos_temp")

DEFINE DIALOG oDlg1 TITLE "Indique con cantidad cuales desea cargar" OF oWnd1 FROM 05,15 TO 30,100
        oDlg1:lHelpIcon:=.f.

    @ 05,05 XBROWSE oBrwLis DATASOURCE oQryLis;
                     COLUMNS "codigo","nombre","costo","cantidad","bultos";    
                     HEADERS "codigo","Nombre","Costo","Unidades","Stock Act.";
                     SIZES 100,305,80,80,80;
             OF oDlg1 SIZE 330,160 PIXEL  AUTOSORT 
    //oQryLis:bOnChangePage := {|| oBrwLis:Refresh() }
    oBrwLis:CreateFromcode()
    oBrwLis:aCols[3]:lAutoSave := .t.
    oBrwLis:aCols[3]:nEditType := EDIT_GET   
    //oBrwLis:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCosto(oQryLis,xval),oBrwLis:Refresh()}  
    oBrwLis:aCols[4]:lAutoSave := .t.
    oBrwLis:aCols[4]:nEditType := EDIT_GET      
    //oBrwLis:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCosto(oQryLis,,xval),oBrwLis:Refresh()}
    oBrwLis:nMoveType:=4
    PintaBrw(oBrwLis,0)

    acor := AcepCanc(oDlg1)
    @ acor[1],acor[4]-aCor[2]-25 CHECKBOX oChe VAR lBorra PROMPT "&Borrar los cargados" OF oDlg1 SIZE 60,10 PIXEL
    @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .t.), oDlg1:End() ) PIXEL DEFAULT 
    @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
               ACTION ((mrta := .f.), oDlg1:End() ) PIXEL CANCEL
    ACTIVATE DIALOG oDlg1 CENTER ON INIT oBrwLis:SetFocus()

    IF !mrta
       RETURN nil
    ENDIF
IF lBorra
   oApp:oServer:Execute("TRUNCATE detalle_temp")
ENDIF
TRY 
   oApp:oServer:Execute("INSERT INTO detalle_temp (codart,detart,cantidad,punit,total,descuento) "+;
                    "(SELECT codigo,nombre,cantidad,costo,cantidad*costo,0 FROM articulos_temp WHERE cantidad >0)")
CATCH oError 
   ValidaError(oError) 
END TRY   
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:Maketotals()
CalcTot(oGet1)
RETURN nil


STATIC FUNCTION ActualizaArt(nCodPro)
LOCAL tipo :=Alert( "Elija la opcion", {"Todos los productos del proveedor","Solo los productos del proveedor faltantes"}, "Seleccione", 1 )

oApp:oServer:Execute("TRUNCATE articulos_temp")
oApp:oServer:Execute("INSERT INTO articulos_temp(codigo,nombre,cantidad,bultos,palets,costo,baja) "+;
                     "(SELECT a.codigo,a.nombre,0,a.stockact,0, "+;
                     " IF(a.siniva,a.precossiva,a.precossiva/(1+i.tasa/100)) "+;
                     ",false FROM ge_"+oApp:cId+"articu a "+;
                     " LEFT JOIN ge_"+oApp:cId+"ivas i ON i.codigo = a.iva "+;
                     " WHERE a.prov = "+ClipValue2Sql(nCodPro)+;
                     if(tipo = 1," "," AND a.stockact < a.stockmin AND a.stockmin > 0")+;
                     " ORDER BY a.nombre)")

RETURN .t.

STATIC FUNCTION CambiaCosto(oQryLis,n,cantidad)
LOCAL base := oQryLis:GetRowObj()
DEFAULT n := base:costo, cantidad := base:cantidad
base:costo := n 
base:cantidad:= cantidad
oQryLis:lAppend:=.f.
oQryLis:oRow := base
oQryLis:Save()
oQryLis:Refresh()

RETURN nil

*****************************************
** Cambiar pendientes
STATIC FUNCTION CambiaCant(n,nPUnit,nDescu, oGet)
LOCAL base := oQryDet:GetRowObj(),nPrecio2,nDescuento,nPrecio1,nIvaPes,nSubTotal,nTotalcIva,;
      oQryIva,nCodIva1,;
      oQryArt:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
DEFAULT n := base:cantidad,nPUnit := base:punit, nDescu := base:descuento
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryArt:iva))
nCodIva1 := oQryArt:iva
IF base:codart > 0    
    IF VALTYPE(nPunit) <> "N" .OR. VALTYPE(n) <> "N" 
       RETURN nil 
    ENDIF
    IF nPunit = base:punit       
       nPunit:= IF(oQryArt:siniva,oQryArt:precossiva,oQryArt:precossiva/(1+oQryIva:tasa/100))    
    ENDIF    
ENDIF      
nPrecio2:= nPUnit * n
nDescuento:= nPrecio2 * (nDescu/100)
nPrecio1:= nPrecio2 - nDescuento
nSubTotal:= nPrecio1
base:descuento:= nDescuento
base:cantidad := n 
base:total:=nSubtotal
base:descuento:=nDescuento
base:punit:= nPUnit
oQryDet:oRow := base
oQryDet:Save()
oQryDet:Refresh()
oBrw:Refresh()
CalcTot(oGet)
RETURN nil