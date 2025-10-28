#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"
#include "report.ch"
*************************************************
** MODIFICAR DETALLE DE REMITOS
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana, oQryF, oBrw1,oQryCli
PROCEDURE ModRem(cPermisos)
   LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
   AADD(oApp:aVentanas,cVentana)
   oQry  := oApp:oServer:Query("SELECT ANY_VALUE(r.id) as id,ANY_VALUE(r.codart) as codart,ANY_VALUE(r.detart) as detart,ANY_VALUE(r.cantidad) as cantidad,ANY_VALUE(r.fecha) AS fecha,ANY_VALUE(r.codcli) as codcli,"+;
                               "ANY_VALUE(r.nrorem) AS nrorem,ANY_VALUE(r.codiva) as codiva,ANY_VALUE(r.facturado) as facturado,ANY_VALUE(r.incrp) as incrp,ANY_VALUE(r.importe) as importe,ANY_VALUE(r.iva) as iva,"+;
                               "ANY_VALUE(r.neto) as neto,ANY_VALUE(r.neton) as neton,ANY_VALUE(r.tipo) as tipo,ANY_VALUE(r.vendedor) as vendedor,ANY_VALUE(r.factura) as factura,ANY_VALUE(r.usuario) as usuario,"+;
                               "ANY_VALUE(r.fecmod) as fecmod,ANY_VALUE(r.ip) as ip,ANY_VALUE(c.nombre) AS nomcli FROM ge_"+oApp:cId+"remitos r "+;
                               "LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = r.codcli "+;
                               " WHERE r.facturado = 0 GROUP BY r.nrorem ")
   oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ")
   oApp:oServer:NextResult()
   oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS remito_det_temp ";
    +"( `CODART` BIGINT(13) NOT NULL, ";
    +"`id` INT(10) NOT NULL,";
    +"`DETART` VARCHAR(50) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,2) DEFAULT '0', "+;
    +"`CANTORIG` DECIMAL(8,2) DEFAULT '0', "+;
    +"`CANTDEVO` DECIMAL(8,2) DEFAULT '0', "+;
    +"`CODIVA`   INT(3) DEFAULT '5', "+;
    +"`IMPORTE`  DECIMAL(12,2) DEFAULT '0', "+;
    +"`VENDEDOR` VARCHAR(15) DEFAULT ' ', "+;
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
   oApp:oServer:NextResult()

   // Defino el dialogo tomado del recurso ABM
   oApp:oIco:Refresh()
    DEFINE WINDOW oWnd1 MDICHILD TITLE "Modificar detalle de remitos pendientes" ;
       OF oApp:oWnd NOZOOM ICON oApp:oIco
      DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
      DEFINE BUTTON RESOURCE "MODI" OF oBar ;
        TOOLTIP "Modificar Registro"  ;
        ACTION Formu();
        PROMPT "Modi" TOP WHEN(oQry:RecCount()>0)
      DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
        TOOLTIP "Eliminar Registro"  ;
        ACTION Baja();
        PROMPT "Borra" TOP WHEN(oQry:RecCount()>0)
      DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
      TOOLTIP "Exportar a Excel" ;
        ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0);
        PROMPT "Excel" TOP
      DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
        TOOLTIP "Imprimir Planilla"  ;
        ACTION oBrw:Report("Reporte de remitos pendientes",.T.,.F.);
        PROMPT "Impr." TOP WHEN(oQry:RecCount()>0)
      DEFINE BUTTON RESOURCE "FILT" OF oBar ;
        TOOLTIP "Filtrar Registros"  ;
        ACTION (Filt(), oBrw:Refresh());
        PROMPT "Filtra" TOP
      DEFINE BUTTON RESOURCE "REPORT" OF oBar ;
        TOOLTIP "Reimprimir remito"  ;
        ACTION ReImpr();
        PROMPT "Reimprime" TOP
      DEFINE BUTTON RESOURCE "DUPL" OF oBar ;
        TOOLTIP "Reporte remitos pendientes"  ;
        ACTION ReporPend();
        PROMPT "Reporte" TOP 
      DEFINE BUTTON RESOURCE "PAGO" OF oBar ;
        TOOLTIP "Acopios pendientes"  ;
        ACTION ReporAcop();
        PROMPT "Acopios" TOP  
      DEFINE BUTTON RESOURCE "GRUPO" OF oBar ;
        TOOLTIP "Dividir Remito"  ;
        ACTION Dividir();
        PROMPT "Dividir" TOP 
      DEFINE BUTTON RESOURCE "CONF" OF oBar ;
        TOOLTIP "Articulos en Service"  ;
        ACTION (oWnd1:End(),Service(cPermisos));
        PROMPT "Service" TOP      
      // Este boton cierra la aplicacion
      DEFINE BUTTON RESOURCE "SALE" OF oBar;
        TOOLTIP "Cerrar Ventana" ;
        ACTION oWnd1:End();
      PROMPT "Salir" TOP
      oWnd1:bGotFocus := { || oDlg:SetFocus}
      oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
      
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
      REDEFINE XBROWSE oBrw DATASOURCE oQry;
         COLUMNS "nrorem","nomcli","fecha";
         HEADERS "Nro. remito","Cliente","Fecha";
         SIZES 120,350,100;
         ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu( ),oBrw:Refresh())
     
      REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
      oQry:bOnChangePage := {|| oBrw:Refresh() }
      //oBrw:SetDolphin(oQry,.f.,.t.)
      PintaBrw(oBrw,3)
      oDlg:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar)}
      // Activo el dialogo y al iniciar muevo a 0,0
      ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID( oWnd1:End() )
      ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar(oQry))
 
RETURN

************************************************
** Acelerador2 de Teclas + - y Enter para la barra de tareas
STATIC FUNCTION Acelerador2(nKey, oBar)
IF nKey = VK_F3 .OR. nKey = 13
   oBar:aControls[1]:Click()
ENDIF
IF nKey = VK_F4
   oBar:aControls[2]:Click()
ENDIF
IF nKey = VK_F5
   oBar:aControls[3]:Click()
ENDIF
IF nKey = VK_F6
   oBar:aControls[4]:Click()
ENDIF
IF nKey = VK_F7
   oBar:aControls[5]:Click()
ENDIF
RETURN NIL


*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu ()
LOCAL oGet:=ARRAY(25), oBot:=ARRAY(2),oDlg1,base,oError,oQryDet,oBrw1, oQryStock, ;
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
      mrta := .f., aCor,cNumero:=SPACE(13),;
      cNomCli:=SPACE(30),cDireccion:=SPACE(30),;
      cLocalidad:=SPACE(30),cCUIT:=SPACE(13),nDni:=0,cConiva,nConIva:=1

  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE remito_det_temp ")
  oApp:oServer:NextResult()

  oApp:oServer:Execute("INSERT INTO remito_det_temp (id,codart,detart,cantidad,cantorig,cantdevo,codiva) "+;
                     "(SELECT id,codart,detart,cantidad,cantidad,0,codiva FROM ge_"+oApp:cId+"remitos WHERE nrorem = "+ClipValue2SQL(oQry:nrorem)+")")
  oQryDet:= oApp:oServer:Query("SELECT * FROM remito_det_temp")

  base := oQry:GetRowObj()   

  cNumero:=RIGHT(base:nrorem,13)


DO WHILE .T.
DEFINE DIALOG oDlg1 RESOURCE "DETREM" OF oWnd1
 oDlg1:lHelpIcon := .f.


  REDEFINE GET oGet[01] VAR base:nrorem ID 100 OF oDlg1 PICTURE "@!" WHEN(.F.)
  REDEFINE GET oGet[02] VAR base:fecha            ID 101 OF oDlg1 PICTURE "@D" WHEN(.F.)
  REDEFINE GET oGet[08] VAR base:codcli ID 185 OF oDlg1 PICTURE "999999" WHEN(.F.)
    REDEFINE GET oGet[09] VAR cNomCli ID 186 OF oDlg1 PICTURE "@!"  WHEN(.F.)
    REDEFINE GET oGet[10] VAR cDireccion ID 187  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[11] VAR cLocalidad ID 188  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[12] VAR cCUIT      ID 189 OF oDlg1 PICTURE "99-99999999-9" ;
             WHEN(.F.) VALID(ValidaCuit(cCuit))
    REDEFINE GET oGet[22] VAR nDNI      ID 201 OF oDlg1 PICTURE "99999999" ;
             WHEN(.F.)
    REDEFINE COMBOBOX oGet[13] VAR nConIva ID 190 OF oDlg1 WHEN(.F.) ITEMS aTipoIva 

    REDEFINE XBROWSE oBrw1 DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","CANTORIG","CANTDEVO";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Original","Devuelve";
       FOOTERS ;
       SIZES 100,330,80,80,80;
    ID 200 OF oDlg1 AUTOSORT
    PintaBrw(oBrw1,0)
    oBrw1:aCols[3]:nEditType := EDIT_GET    
    oBrw1:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,oQryDet,oBrw1)}
    oBrw1:nMoveType := 4

    //grabar
    REDEFINE BUTTON oBot[1] ID 103 ACTION (MRTA:=.t.,oDlg1:End()) WHEN(oQryDet:RecCount()>0) 
    //salir
    REDEFINE BUTTON oBot[2] ID 104 ACTION (mrta:=.f.,oDlg1:End()) CANCEL 
    
    oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[2]:Click,.f.) }
  
ACTIVATE DIALOG oDlg1 CENTER ON INIT (ValidaCli(oGet),oBrw1:SetFocus())

IF !mRta
   RETURN nil
ENDIF
oQryDet:Refresh()
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE remito_det_temp rt LEFT JOIN ge_"+oApp:cId+"remitos r ON r.id=rt.id LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = rt.codart "+;
                       "SET a.stockact = a.stockact - (rt.cantidad - r.cantidad) WHERE a.stockotro IS FALSE")
  // En los que tienen otro stock
  // Primero borro lo que tenia el remito
  oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                     "d.codart AS codart FROM ge_"+oApp:cId+"remitos d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE d.nrorem = "+ClipValue2SQL(oQry:nrorem)+" AND a.stockotro = TRUE ")
  oQryStock:GoTop()
  DO WHILE !oQryStock:EOF()
     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                          " ON m.codigo = r.codusa "+;
                          "SET m.stockact = m.stockact + (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                          "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
     oQryStock:Skip()
  ENDDO
  //Actualizo el stock con los nuevos
  oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                     "d.codart AS codart FROM remito_det_temp d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE a.stockotro = TRUE ")
      oQryStock:GoTop()
      DO WHILE !oQryStock:EOF()
         oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                              " ON m.codigo = r.codusa "+;
                              "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                              "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
         oQryStock:Skip()
      ENDDO
  // Fin stock
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"remitos r LEFT JOIN remito_det_temp rt ON r.id=rt.id SET r.cantidad = rt.cantidad, "+;
                       "r.usuario = "+ClipValue2SQL(oApp:usuario)+","+;
                       "r.fecmod  = CURDATE(),"+;
                       "r.ip      = "+ClipValue2SQL(oApp:cIp)+" "+;
                       "WHERE r.nrorem = " +ClipValue2SQL(oQry:nrorem))
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
mRta := MsgNoYes("Desea imprimir las modificaciones?","Atencion")
IF mRta 
   PrintRemito1(base,oQryDet)
ENDIF
RETURN nil

************************************************************************************
STATIC FUNCTION ValidaCli(oGet)
LOCAL cLetra

  Buscar(oQryCli,oDlg,oGet[08])
  oGet[09]:cText := oQryCli:nombre
  oGet[10]:cText := oQryCli:direccion
  oGet[11]:ctext := oQryCli:localidad
  oGet[12]:cText := oQryCli:cuit
  oGet[22]:cText := oQryCli:dni
  oGet[13]:Set(oQryCli:coniva)
 /* oGet[09]:Refresh()
  oGet[10]:Refresh()
  oGet[11]:Refresh()
  oGet[12]:Refresh()
  oGet[22]:Refresh()
  oGet[13]:Refresh()
 */
RETURN .T.

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
LOCAL mrta := .f., oError, nNum := oQry:nrorem, oQryStock
IF EMPTY(nNum)
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el remito Nro:"+nNum,"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"remitos r "+;
                       " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+;
                       "SET a.stockact = a.stockact + r.cantidad WHERE r.nrorem = "+ClipValue2SQL(nNum) +;
                       " AND a.stockotro IS FALSE" )
  // En los que tienen otro stock
  // Primero borro lo que tenia el remito
  oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                     "d.codart AS codart FROM ge_"+oApp:cId+"remitos d "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                     "WHERE d.nrorem = "+ClipValue2SQL(nNum)+" AND a.stockotro = TRUE ")
  oQryStock:GoTop()
  DO WHILE !oQryStock:EOF()
     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                          " ON m.codigo = r.codusa "+;
                          "SET m.stockact = m.stockact + (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                          "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
     oQryStock:Skip()
  ENDDO
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"remitos WHERE nrorem = "+ClipValue2SQL(nNum))
  Auditar(1," Remito:"+nNum)
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
     VCODIGO := 0, VDESDE := CTOD("01/01/100"), VHASTA := DATE(), VREMITO := SPACE(13)     
LOCAL oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet19,;
      oGet10, oGet11, oGet12, oGet13, oGet14, oGet15, oGet16, oGet17, oGet18,;
      oGet20, oGet22, oBot1, oBot2,oDlg1,base,oError, ;      
      mrta := .f., aCor,cNomVen:=SPACE(30)

DO WHILE .T.
DEFINE DIALOG oDlg1 TITLE "FILTRADO de Remitos" FROM 05,10 TO 19,80 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Cliente:"        OF oDlg1 PIXEL SIZE 60,12 RIGHT   
   @ 22, 05 SAY "Fecha desde:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Fecha Hasta:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 52, 05 SAY "Remito Nro:"     OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   
   @ 05, 70 GET oGet1 VAR vcodigo PICTURE "99999" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR VDESDE PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 GET oGet3 VAR VHASTA PICTURE "@D" OF oDlg1 PIXEL
   @ 50, 70 GET oGet4 VAR VREMITO  OF oDlg1 PIXEL   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " 1=1 " + IF(EMPTY(vCodigo),""," and r.codcli =" + ClipValue2SQL(VCodigo) + "") ;
      + "" + IF(EMPTY(VREMITO),"","  and TRIM(r.nrorem) like '%" + ALLTRIM(VREMITO) + "%'") ;      
      + "" + " and r.fecha >=" + ClipValue2SQL(VDESDE)  ;   
      + "" + " and r.fecha <=" + ClipValue2SQL(VHASTA)  + " AND facturado = 0 "

   EXIT
ENDDO
oQry:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil


STATIC FUNCTION ReImpr()
LOCAL oQryDet, cFacRemitada
oQryDet := oApp:oServer:Query("SELECT codart,detart,cantidad,auto as bultos, factura FROM ge_"+oApp:cId+;
	       "remitos WHERE nrorem = "+ClipValue2SQL(oQry:nrorem))
cFacRemitada := IF(EMPTY(oQryDet:factura),"",oQryDet:factura)
PrintRemito(oQryDet,,, RIGHT(oQry:nrorem,13),oQry:codcli,cFacRemitada)
RETURN NIL


*****************************************
** Cambiar pendientes
STATIC FUNCTION CambiaCant(n,oQryDet,oBrw)

oQryDet:cantidad := n 
oQryDet:cantdevo := oQryDet:cantorig - n 
oQryDet:Save()
oBrw:Refresh()

RETURN nil


******************************************************
**Impresion
STATIC FUNCTION PrintRemito1(base,oQryDet)
LOCAL aiva := { "IVA Responsable Inscripto","IVA Responsable no Inscripto",;
                "IVA no Responsable","IVA Sujeto Exento",;
                "Consumidor Final","Responsable Monotributo",;
                "Sujeto no Categorizado","Proveedor del Exterior",;
                "Cliente del Exterior","IVA Liberado – Ley Nº 19.640",;
                "IVA Responsable Inscripto – Agente de Percepción",;
                "Pequeño Contribuyente Eventual","Monotributista Social",;
                "Pequeño Contribuyente Eventual Social","IVA NO Alcanzado"},;
      i, x, y, oPrn, nRow, oFont, oFont1, oFont2, oFont3, oFont4, oFont5,  config,;
       aCor, oQryP, nRow1, nHoja, oQryVen1, oQryPar, lComan
   oQryVen1 := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes WHERE codigo = " + ClipValue2Sql(base:codcli))
   oQryPar := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros")   
   oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))   
   config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config") 
   IF oQryP:preguntaimpr 
      lComan := SiNoCancelar("Atencion","Por donde desea emitir el Comprobante?",{"Comandera","Impresora","No imprimir"})
      IF lComan == nil 
         RETURN nil 
      ENDIF
      oQryP:imprimeTic := lComan
   ENDIF   
   DO CASE
      CASE !oQryP:imprimeTic   
           ** FACTURACION CON FORMATO PARA FACTURA ELECTRONICA
           DEFINE FONT oFont   NAME "ARIAL"       SIZE config:fon,config:fon*2.5
           DEFINE FONT oFont1  NAME "CALIBRI"     SIZE config:fon*1.5,config:fon*4 BOLD
           DEFINE FONT oFont2  NAME "CALIBRI"     SIZE config:fon*4,config:fon*7 BOLD
           DEFINE FONT oFont3  NAME "ARIAL"       SIZE config:fon,config:fon*2.5 BOLD  
           DEFINE FONT oFont5  NAME "ARIAL"       SIZE config:fon*.8,config:fon*1.9 BOLD 
           PRINT oPrn NAME "Devolucion Remito" PREVIEW MODAL
           oPrn:SetPortrait()
           oPrn:SetPage(9)
           FOR x := 1 TO 2
             PAGE 
             nHoja := 1   
             *@ 0,0 PRINT TO oPrn IMAGE "fondofac.jpg" SIZE oPrn:nHorzRes(), oPrn:nVertRes() PIXEL GRAY
             *oPrn:SayImage(0,0, "fondofac.jpg",;
             *                   oPrn:nHorzRes(), oPrn:nVertRes() ,   nil, .t. )     
             oPrn:CmBox( .5, .5, 1.5, 20.5 ) // Box arriba
             oPrn:CmBox( 1.5, .5, 5, 20.5 ) // Box datos del comprobante
             oPrn:CmBox( 5.3, .5, 7.5, 20.5 ) // Box datos del cliente
             oPrn:CmBox(   8, .5, 9, 20.5 ) // Box titulos     
             oPrn:CmBox( 22, .5, 25, 20.5 )   // Box datos del iva
             @ .8, 01.15 PRINT TO oPrn TEXT IF(x=1,"ORIGINAL","DUPLICADO") ;
                      SIZE 18,.9 CM FONT oFont1 ALIGN "C" 
             IF oQryP:imprimeDat            
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
             ENDIF
             oPrn:CmSay( 1.7  , 11, "REM. DEVOLUCION ", oFont1 )   
             oPrn:CmBox( 1.5, 9.4, 2.7, 10.7 )   // Box cuadrito comprobante
             oPrn:CmSay( 1.5, 9.8, 'R',oFont2)
             
             oPrn:CmSay( 2.5, 11, " Comprobante Nro:"+base:nrorem,oFont)
             oPrn:CmSay( 3.0, 11, "Fecha de cambio:"+DTOC(DATE()),oFont)                    

             
             @ 5.5, 1   PRINT TO oPrn TEXT "C.U.I.T.:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 4.1 PRINT TO oPrn TEXT oQryVen1:cuit ;
                      SIZE 6,.5 CM FONT oFont ALIGN "L"
             @ 5.5, 9.5  PRINT TO oPrn TEXT "Razon Social:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre) ;
                      SIZE 8,1 CM FONT oFont LASTROW nRow 
             @ 6,1  PRINT TO oPrn TEXT "Condicion IVA:" ;
                      SIZE 3,.5 CM FONT oFont3 ALIGN "R"
             @ 6,4.1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva] ;
                      SIZE 6,.5 CM FONT oFont 
             nRow := IF(nRow<6,6,nRow)
             @ nRow, 9.5 PRINT TO oPrn TEXT "Direccion:" ;
                      SIZE 2.5,.5 CM FONT oFont3 ALIGN "R"
             @ nRow, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                   ALLTRIM(oQryVen1:localidad) ;
                      SIZE 8,1 CM FONT oFont                          

             @ 8.2, 0.7 PRINT TO oPrn TEXT "Codigo" ;
                      SIZE 2.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 3.5 PRINT TO oPrn TEXT "Descripcion del producto" ;
                      SIZE 6.5,.9 CM FONT oFont5 ALIGN "L"
             @ 8.2, 10 PRINT TO oPrn TEXT "Cantidad" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             @ 8.2, 12 PRINT TO oPrn TEXT "Original" ;
                      SIZE 2,.9 CM FONT oFont5 ALIGN "R"
             @ 8.2, 14 PRINT TO oPrn TEXT "Devuelve" ;
                      SIZE 1.5,.9 CM FONT oFont5 ALIGN "C"             

             y := 9.2
             oQryDet:GoTop()
             FOR i = 1 TO oQryDet:nRecCount           
                 
                 @ y-0.07, 01 PRINT TO oPrn TEXT STR(oQryDet:codart,13) ;
                      SIZE 2.5,.5 CM FONT oFont5 ALIGN "L"
                 @ y+.07, 03.5 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart) ;
                      SIZE 6.5,1.5 CM FONT oFont5 LASTROW nRow 
                 @ y-0.07, 10 PRINT TO oPrn TEXT STR(oQryDet:cantidad,08,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "R"
                 @ y-0.07, 12 PRINT TO oPrn TEXT STR(oQryDet:cantorig,08,2) ;
                      SIZE 2,.5 CM FONT oFont5 ALIGN "R"
                 @ y-0.07, 14 PRINT TO oPrn TEXT STR(oQryDet:cantdevo,08,2) ;
                      SIZE 1.5,.5 CM FONT oFont5 ALIGN "R"                  
  
                 y := nRow + .1                 
                 oQryDet:Skip()                 
              NEXT       
              y := y + .5
              @ y, 1 PRINT TO oPrn TEXT ".............................................." ;
                      SIZE 18,3 CM FONT oFont ALIGN "L"              
              
             ENDPAGE
           NEXT x
           ENDPRINT
          OTHERWISE
           IF !oApp:tick80
               *** Impresion 48 mm
               *********** Impresion de Ticket NO FISCAL 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 1
                     IF oQryP:imprimeDat
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
                                      
                         @ nRow, .1 PRINT TO oPrn TEXT "REM.DEVOLUCION "  ;
                                      SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "No Valido como factura " ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Cambio:" + +DTOC(DATE());
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT "DOC. NO VALIDO COMO FACTURA" ;
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"                     
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Cambio:" + +DTOC(DATE());
                                      SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:nombre);
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT oQryVen1:cuit;
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT aIva[oQryVen1:coniva];
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     
                     nRow1 := nRow + .5
                     @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03 PRINT TO oPrn TEXT "Cant";
                                  SIZE .8,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 03.9 PRINT TO oPrn TEXT "Devol";
                                  SIZE 0.9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     oQryDet:GoTop()                 
                     FOR i = 1 TO oQryDet:nRecCount           
                         nRow1 := nRow  
                         @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                              SIZE 2.9,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06);
                              SIZE 0.7,.5 CM FONT oFont  ALIGN "R"
                         @ nRow1, 3.8 PRINT TO oPrn TEXT STR(oQryDet:cantdevo,6);
                              SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"                   
                         oQryDet:Skip()                     
                      NEXT                           
                      @ nRow, .1 PRINT TO oPrn TEXT "...............................";
                                  SIZE 5,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                                  
                  ENDPAGE
               ENDPRINT
              ELSE
               *** Impresion 80 mm
               *********** Impresion de Ticket NO FISCAL 
               IF config:fon > 25
                  config:fon := config:fon /3
               ENDIF
               DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5
               DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon*1.5,config:fon*4 BOLD
               PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
                  oPrn:oFont := oFont
                  PAGE                                  
                     nRow := 1
                     IF oQryP:imprimeDat
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
                                      
                         @ nRow, .1 PRINT TO oPrn TEXT "REM.DEVOLUCION " ;
                                      SIZE 8,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
                         @ nRow, .1 PRINT TO oPrn TEXT "No Valido como factura " ;
                                      SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                 
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Cambio:" + +DTOC(DATE());
                                      SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                         ELSE 
                         @ nRow, .1 PRINT TO oPrn TEXT "DOC. NO VALIDO COMO FACTURA" ;
                                      SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"                     
                         @ nRow, .1 PRINT TO oPrn TEXT "Fecha Emision:" + +DTOC(oQryVen1:fecha);
                                      SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "C"
                     ENDIF
                        @ nRow, .1 PRINT TO oPrn TEXT "Cliente: "+ALLTRIM(oQryVen1:nombre);
                                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT oQryVen1:cuit;
                                  SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT "Cond. Fiscal: "+aIva[oQryVen1:coniva];
                                  SIZE 8,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                        @ nRow, .1 PRINT TO oPrn TEXT ALLTRIM(oQryVen1:direccion) + " " + ;
                                                           ALLTRIM(oQryVen1:localidad);
                                  SIZE 8,1 CM FONT oFont LASTROW nRow ALIGN "L"

                     nRow1 := nRow + .5                     
                     @ nRow1, 00.00 PRINT TO oPrn TEXT "Descripcion";
                                  SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                     @ nRow1, 03.60 PRINT TO oPrn TEXT "Cant";
                                  SIZE .9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 04.65 PRINT TO oPrn TEXT "Devol";
                                  SIZE 1,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     @ nRow1, 05.70 PRINT TO oPrn TEXT "Original";
                                  SIZE 1.4,.5 CM FONT oFont LASTROW nRow ALIGN "R"
                     oQryDet:GoTop()  
                     oPrn:CmLine( nRow,0, nRow,9 )               
                     nRow := nRow + .2                     
                     FOR i = 1 TO oQryDet:nRecCount           
                         nRow1 := nRow
                         @ nRow1, 00.00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:detart);
                              SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
                         @ nRow1, 03.60 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,2);
                              SIZE .9,.5 CM FONT oFont  ALIGN "R"
                         @ nRow1, 04.65 PRINT TO oPrn TEXT STR(oQryDet:cantdevo,06,2);
                              SIZE 1,.5   CM FONT oFont ALIGN "R"
                         @ nRow1, 05.70 PRINT TO oPrn TEXT STR(oQryDet:cantorig,06,2);
                              SIZE 1.4,.5 CM FONT oFont LASTROW nRow ALIGN "R"                     
                         oQryDet:Skip()                     
                     NEXT                       
                     nRow1 := nRow
                     oPrn:CmLine( nRow1,0, nRow1,9 )
                     nRow := nRow + .3
                     @ nRow, .1 PRINT TO oPrn TEXT ".................................";
                                  SIZE 8,.5 CM FONT oFont1 LASTROW nRow ALIGN "L"                                 
                  ENDPAGE
               ENDPRINT
            ENDIF 
ENDCASE
RETURN nil


STATIC FUNCTION ReporPend()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := "TODOS..."+SPACE(22), mdesde := DATE(), mhasta := DATE(), mcodcli := 0, oGru, oGru1
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"clientes ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte Remitos pendientes" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente (0:Todos):"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodcli  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(mcodcli = 0 .or. Buscar(oQryCli,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, mcodcli = 0 .or. Buscar(oQryCli,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL ;
            WHEN(IF(mcodcli=0,(oGet[4]:cText:="TODOS..."+SPACE(22))="A",.F.))                
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
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC     
oQry := oApp:oServer:Query("SELECT c.nombre AS cliente,v.codcli AS codcli,v.nrorem AS compro, v.fecha as fecha, "+;                         
                         " v.detart AS articulo,"+;
                         " v.codart AS codigo,"+;
                         " v.cantidad AS cantidad, a.precioven AS importe "+;
                         " FROM ge_"+oApp:cId+"remitos v  "+;  
                         " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;                       
                         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = v.codart "+;                       
                         " WHERE v.facturado is false and  v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " v.fecha <= "+ ClipValue2Sql(mhasta) + " AND "+;
                         " v.codcli = " + IF(mcodcli = 0,"v.codcli",ClipValue2Sql(mcodcli)) +;
                         " ORDER BY c.nombre,v.nrorem" )
REPORT oRep TITLE "Remitos pendientes de facturacion  del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Remitos pendientes" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Remitos pendientes"
GROUP oGru  ON oQry:cliente HEADER oQry:cliente FOOTER "Totales Cliente" FONT 3 
GROUP oGru1 ON oQry:compro HEADER oQry:compro FOOTER "Totales Remito" FONT 2
COLUMN TITLE "Fecha"     DATA oQry:fecha     PICTURE "@D" SIZE 08 FONT 1
COLUMN TITLE "Codigo"    DATA oQry:codigo    PICTURE "99999999999999" SIZE 15 FONT 1
COLUMN TITLE "Articulo"  DATA oQry:articulo SIZE 30 FONT 1
COLUMN TITLE "Cantidad"  DATA oQry:cantidad PICTURE "9999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Estimado $"  DATA oQry:cantidad * oQry:importe PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN NIL


STATIC FUNCTION ReporAcop()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2, oQryCli,;
      mnomcli := "TODOS..."+SPACE(22), mdesde := ctod('01/01/2020'), mhasta := DATE(), mcodcli := 0, oGru, oGru1
oQryCli:= oApp:oServer:Query("SELECT codigo,nombre,direccion FROM ge_"+oApp:cId+"clientes ORDER BY nombre")           
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte Acopios pendientes" FROM 03,15 TO 13,70 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Desde Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Cliente (0:Todos):"     OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 35, 65 GET oGet[3] VAR mcodcli  OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(mcodcli = 0 .or. Buscar(oQryCli,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= -999, mcodcli = 0 .or. Buscar(oQryCli,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL ;
            WHEN(IF(mcodcli=0,(oGet[4]:cText:="TODOS..."+SPACE(22))="A",.F.))                
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
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-10 BOLD ITALIC     
oQry := oApp:oServer:Query(" SELECT CONCAT(v.ticomp,v.letra,v.numcomp) as compro,v.codcli,c.nombre, vd.codart,vd.detart,"+;
                           " vd.cantidad as afacturar, rd.cantidad as facturado "+;
                           " FROM ge_"+oApp:cId+"ventas_encab v "+;
                           " LEFT JOIN (SELECT nrofac ,codart,detart, SUM(cantidad) AS cantidad "+;
                           " FROM ge_"+oApp:cId+"ventas_det GROUP BY nrofac,codart) vd ON vd.nrofac = CONCAT(v.ticomp,v.letra,v.numcomp) "+;
                           " LEFT JOIN (SELECT factura,codart,detart, SUM(cantidad) AS cantidad "+;
                           " FROM ge_"+oApp:cId+"remitos GROUP BY factura,codart) rd "+;
                           " ON rd.factura = CONCAT(v.ticomp,v.letra,v.numcomp) AND rd.codart = vd.codart "+;
                           " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;                           
                           " WHERE v.acopio AND "+;                           
                           " v.fecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                           " v.fecha <= "+ ClipValue2Sql(mhasta) + " "+;
                           IF(mcodcli = 0,""," AND v.codcli = "+str(mcodcli))+;
                           " GROUP BY vd.nrofac,vd.codart ")
REPORT oRep TITLE "Facturas Pendientes de Remitar por acopio";
       FONT  oFont1,oFont2,oFont3 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Facturas de acopio" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Facturas de acopio"
GROUP oGru1 ON oQry:compro HEADER oQry:compro+" "+alltrim(oQry:nombre) + " ("+STR(oQry:codcli)+")" FOOTER "Totales Factura" FONT 2
COLUMN TITLE "Codigo"    DATA oQry:codart    PICTURE "99999999999999" SIZE 15 FONT 1
COLUMN TITLE "Articulo"  DATA oQry:detart SIZE 30 FONT 1
COLUMN TITLE "Facturado"  DATA oQry:afacturar PICTURE "9999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Remitado"  DATA oQry:facturado PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Pendiente"  DATA oQry:afacturar - oQry:facturado PICTURE "999999999.99" ;
                         SIZE 10 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN NIL


*****************************************************
** Dividir Remito 
STATIC FUNCTION Dividir()
LOCAL oGet:=ARRAY(25), oBot:=ARRAY(2),oDlg1,base,oError,oQryDet,oBrw1, oQryStock, cNumComp,;
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
      mrta := .f., aCor,cNumero:=SPACE(13),;
      cNomCli:=SPACE(30),cDireccion:=SPACE(30),;
      cLocalidad:=SPACE(30),cCUIT:=SPACE(13),nDni:=0,cConiva,nConIva:=1

  oApp:oServer:NextResult()
  oApp:oServer:Execute("TRUNCATE remito_det_temp ")
  oApp:oServer:NextResult()

  oApp:oServer:Execute("INSERT INTO remito_det_temp (id,codart,detart,cantidad,cantorig,cantdevo,codiva,importe,vendedor) "+;
                     "(SELECT id,codart,detart,cantidad,cantidad,0,codiva,importe,vendedor FROM ge_"+oApp:cId+"remitos WHERE nrorem = "+ClipValue2SQL(oQry:nrorem)+")")
  oQryDet:= oApp:oServer:Query("SELECT * FROM remito_det_temp")

  base := oQry:GetRowObj()   

  cNumero:=RIGHT(base:nrorem,13)

DO WHILE .T.
DEFINE DIALOG oDlg1 RESOURCE "DETREM" OF oWnd1 TITLE "Dividir Remito en 2"
 oDlg1:lHelpIcon := .f.


  REDEFINE GET oGet[01] VAR base:nrorem ID 100 OF oDlg1 PICTURE "@!" WHEN(.F.)
  REDEFINE GET oGet[02] VAR base:fecha            ID 101 OF oDlg1 PICTURE "@D" WHEN(.F.)
  REDEFINE GET oGet[08] VAR base:codcli ID 185 OF oDlg1 PICTURE "999999" WHEN(.F.)
    REDEFINE GET oGet[09] VAR cNomCli ID 186 OF oDlg1 PICTURE "@!"  WHEN(.F.)
    REDEFINE GET oGet[10] VAR cDireccion ID 187  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[11] VAR cLocalidad ID 188  OF oDlg1 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[12] VAR cCUIT      ID 189 OF oDlg1 PICTURE "99-99999999-9" ;
             WHEN(.F.) VALID(ValidaCuit(cCuit))
    REDEFINE GET oGet[22] VAR nDNI      ID 201 OF oDlg1 PICTURE "99999999" ;
             WHEN(.F.)
    REDEFINE COMBOBOX oGet[13] VAR nConIva ID 190 OF oDlg1 WHEN(.F.) ITEMS aTipoIva 

    REDEFINE XBROWSE oBrw1 DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","CANTORIG","CANTDEVO";
       HEADERS "Codigo","Detalle Articulo","Transfiere","Original","Quedan";
       FOOTERS ;
       SIZES 100,330,80,80,80;
    ID 200 OF oDlg1 AUTOSORT
    PintaBrw(oBrw1,0)
    oBrw1:aCols[3]:nEditType := EDIT_GET    
    oBrw1:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | DividirCant(xval,oQryDet,oBrw1)}
    oBrw1:nMoveType := 4

    //grabar
    REDEFINE BUTTON oBot[1] ID 103 ACTION (MRTA:=.t.,oDlg1:End()) WHEN(oQryDet:RecCount()>0) 
    //salir
    REDEFINE BUTTON oBot[2] ID 104 ACTION (mrta:=.f.,oDlg1:End()) CANCEL 
    
    oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[2]:Click,.f.) }
  
ACTIVATE DIALOG oDlg1 CENTER ON INIT (ValidaCli(oGet),oBrw1:SetFocus())

IF !mRta
   RETURN nil
ENDIF
oQryDet:Refresh()
TRY
  oApp:oServer:BeginTransaction()  
  //Actualizo el remito viejo     
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"remitos r LEFT JOIN remito_det_temp rt ON r.id=rt.id SET r.cantidad = rt.cantdevo, "+;
                       "r.usuario = "+ClipValue2SQL(oApp:usuario)+","+;
                       "r.fecmod  = CURDATE(),"+;
                       "r.ip      = "+ClipValue2SQL(oApp:cIp)+" "+;
                       "WHERE r.nrorem = " +ClipValue2SQL(oQry:nrorem)+ " AND rt.cantdevo > 0")
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"remitos   "+;
                       "WHERE nrorem = " +ClipValue2SQL(oQry:nrorem)+;
                       " AND id IN ( SELECT id FROM remito_det_temp WHERE cantdevo  = 0)")

  // Agrego el remito nuevo creado
  cNumComp:= STRTRAN(STR(oApp:oServer:Query("SELECT caja FROM ge_"+oApp:cId+;
    "punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):caja,4)+;
    "-"+STR(oApp:oServer:Query("SELECT remito FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip)):remito+1,8)," ","0")  
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"remitos "+;
                        " (codart,detart,cantidad,fecha,codcli,nrorem,codiva,facturado,incrp,importe,iva,neto,neton,tipo,auto,vendedor) "+;
                        " (SELECT codart,detart,cantidad,"+ClipValue2Sql(base:fecha)+","+ClipValue2Sql(base:codcli)+","+;
                        + ClipValue2Sql("RE"+cNumComp)+",codiva,FALSE,0,importe,0,0,0, "+;
                        "'I',"+ClipValue2Sql(0)+",vendedor "+;
                        "   FROM remito_det_temp WHERE cantidad > 0)")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"punto SET remito = remito + 1 WHERE ip = "+ ClipValue2Sql(oApp:cip))
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*****************************************
** Dividir
STATIC FUNCTION DividirCant(n,oQryDet,oBrw)
IF n > oQryDet:cantorig 
   MsgStop("No puede transferir mas de lo que tiene","Atencion")
   RETURN nil 
ENDIF   
oQryDet:cantidad := n 
oQryDet:cantdevo := oQryDet:cantorig - n 
oQryDet:Save()
oBrw:Refresh()
RETURN nil