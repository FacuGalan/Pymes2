#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "FGet.ch"
#include "report.ch"
************************************************************************************************
** Pedidos
************************************************************************************************
MEMVAR oApp
STATIC oWnd1, nTipoDoc,nTipoEmp,nTipoFac, cVentana, oGet, oQryArt, oQryCli, oQryPar, oQryDet, oQryRub,oQryPag,;
       oBrwG, oBrw, oSay1,oSay3,cRemitos, oDlg,oDlg2,nCodCli,nTarjeta,nefectivo,oQryPun,nDescArt,nDescArt1,nConIva,lReemplaza,;
       nEfecti, nTarjet, nCheque, nCtaCte,nVales, nCuotas, nPuntoVta,cObserva,nPorIva,cNumComp,oQryBrw,nLisPre,nLisPreE,oQryLisPre,;
       cDetArt, nDescuGen, nCodIva, nTotal, nForPag, nRubro, nDeuda,oQryChe,mpagado,manticipo,dFecha,nPagado,nVuelto,lAdmin,;
       nLisPreEAnt

PROCEDURE Pedidos(cPermisos) 
LOCAL oBar, hHand,cDialog, cCod
 cVentana := PROCNAME()     
 IF ASCAN(oApp:aVentanas,cVentana) > 0
     hHand := ASCAN(oApp:aVentanas,cVentana)
     oApp:oWnd:Select(hHand)
     oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
     RETURN
  ENDIF
  AADD(oApp:aVentanas,cVentana)
oGet := ARRAY(43) 
lAdmin:= IF(oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario = "+ClipValue2Sql(oApp:usuario)+" AND modulo = 'CREUSU'"):RecCount()>0,.t.,.f.)
validarqueexista()
cDialog:= "ABMS"
oQryPar:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros LIMIT 1")
oQryBrw:= oApp:oServer:Query("SELECT p.nuevo, p.id,p.CODCLI,p.CLIENTE,p.FECHA,p.PARAFECHA,p.Observa,"+;
                             "p.VENDEDOR,p.ESTADO,ROUND(SUM(pd.cantidad * pd.punitario * (1-pd.descup/100)),2) as total "+;
                             " FROM ge_"+oApp:cId+"pedidos_encab p "+;
                             "LEFT JOIN ge_"+oApp:cId+"pedidos_det pd ON pd.idpedido = p.id "+;
                             " WHERE p.estado = 'P' GROUP BY p.id")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "Generacion de pedidos" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu(cPermisos,.t.),oBrwG:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(cPermisos,.f.),oBrwG:Refresh());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrwG:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrwG:ToExcel() WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrwG:Report("Reporte de Pedidos",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)  
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Listar pedidos"  ;
            ACTION ReporPed();
            PROMPT "Informe" TOP WHEN("R"$cPermisos)  
         DEFINE BUTTON RESOURCE "REPORT" OF oBar ;
            TOOLTIP "Reporte por Articulos"  ;
            ACTION ReporPedArt();
            PROMPT "Por Art." TOP WHEN("R"$cPermisos)     
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar pedidos"  ;
            ACTION Filtrar();
            PROMPT "Filtrar" TOP 
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE cDialog OF oWnd1
     REDEFINE XBROWSE oBrwG DATASOURCE oQryBrw;
              COLUMNS "nuevo","id","CODCLI","CLIENTE","FECHA","PARAFECHA","total","VENDEDOR","ESTADO","observa";
              HEADERS "","Nro Pedido","Código Cliente","Nombre","Fecha","Para Fecha","Total","Vendedor","Estado","Observaciones";
              SIZES 40,70,65,270,90,90,200,100,100,100;
              FOOTERS;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu(cPermisos,.f.),oBrwG:Refresh()),.T.))
     REDEFINE SAY oBrwG:oSeek PROMPT "" ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrwG:Refresh() }
     oQryBrw:SetOrder("cliente")
     //oBrwG:SetDolphin(oQry,.f.,.t.)          
     oBrwG:aCols[1]:bStrData := {|| IF(oQryBrw:Reccount()>0,IF(oQryBrw:nuevo,"Nuevo!",""),"")}
     oBrwG:bClrStd := { || IF(oQryBrw:nuevo,{ CLR_BLACK, RGB(255,50,50) },;
                          If( oBrwG:KeyNo() % 2 == 0, ;
                          { CLR_BLACK, RGB(193,221,255) }, ;
                          { CLR_BLACK, RGB(221,245,255) } )) }
     oBrwG:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     oBrwG:cSeek := ""
     oBrwG:oSeek:SetText("")
     oBrwG:aCols[7]:nFooterTypE := AGGR_SUM
     oBrwG:Maketotals()
     PintaBrw(oBrwG,10) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


****************************************FILTRADO**********************
STATIC FUNCTION Filtrar( )
   LOCAL oFilt,oGet:=ARRAY(9),oBot:=ARRAY(2),acor:=ARRAY(4),vProv:=0,cNomProv:=SPACE(30),;
   vDesde:=CTOD("01/01/2000"),vHasta:=DATE(),oQryPro,lRta:=.f.,oFont,cWhere,;
   vPDesde:=DATE(),vPHasta := CTOD("01/01/2100") , nEstado := 1, aEstado := {"Solo Pendientes","Todos"},;
   oQryVen := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"vendedores"), cNomVende := SPACE(30), vVende := 0
   
oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5

DO WHILE .T.                        
    DEFINE DIALOG oFilt TITLE "Filtrado de Pedidos";
           FROM 05,15 TO 19,70 OF oWnd1 FONT oFont
       
       @ 07, 05 SAY "Cliente:"                OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 22, 05 SAY "Desde:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 22, 75 SAY "Hasta:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 37, 05 SAY "Para fecha:"             OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 37, 75 SAY "Hasta:"                  OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 52, 05 SAY "Estado:"                 OF oFilt PIXEL SIZE 50,20 RIGHT
       @ 72, 05 SAY "Vendedor:"               OF oFilt PIXEL SIZE 50,20 RIGHT


       @ 05, 60 GET oGet[01] VAR vProv     OF oFilt PIXEL PICTURE "99999999" ;
                    VALID(oGet[01]:value = 0 .or. Buscar(oQryPro,oFilt,oGet[01],oGet[02]));
                    ACTION (oGet[01]:cText:= 0, Buscar(oQryPro,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"
       @ 05,100 GET oGet[02] VAR cNomProv  OF oFilt PIXEL PICTURE "@!" WHEN(.F.)
       @ 20, 60 GET oGet[03] VAR vDesde    OF oFilt PIXEL PICTURE "@D" CENTER                      
       @ 20,130 GET oGet[04] VAR vHasta    OF oFilt PIXEL PICTURE "@D" CENTER  
       @ 35, 60 GET oGet[05] VAR vPDesde   OF oFilt PIXEL PICTURE "@D" CENTER                      
       @ 35,130 GET oGet[06] VAR vPHasta   OF oFilt PIXEL PICTURE "@D" CENTER 
       @ 55, 60 COMBOBOX oGet[07] VAR nEstado ITEMS aEstado   OF oFilt PIXEL SIZE 90,12
       @ 70, 60 GET oGet[08] VAR vVende     OF oFilt PIXEL PICTURE "99999999" ;
                    VALID(oGet[08]:value = 0 .or. Buscar(oQryVen,oFilt,oGet[08],oGet[09]));
                    ACTION (oGet[08]:cText:= 0, Buscar(oQryVen,oFilt,oGet[08],oGet[09])) BITMAP "BUSC1"
       @ 70,100 GET oGet[09] VAR cNomVende  OF oFilt PIXEL PICTURE "@!" WHEN(.F.)

          
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
          + "" + IF(EMPTY(Vdesde),""," and fecha >=" + ClipValue2SQL(Vdesde) + "") ; 
          + "" + IF(EMPTY(Vhasta),""," and fecha <=" + ClipValue2SQL(Vhasta) + "") ;
          + "" + IF(EMPTY(VPdesde),""," and parafecha >=" + ClipValue2SQL(VPdesde) + "") ; 
          + "" + IF(EMPTY(VPhasta),""," and parafecha <=" + ClipValue2SQL(VPhasta) + "") ;
          + "" + IF(nEstado = 2," and estado <> 'A' "," and estado = 'P' " ) ;
          + "" + IF(vVende = 0,""," and codven =  "+str(vVende) ) 
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
*******************************************************************************************************************************************
***************VENTANA DE PEDIDOS 
STATIC FUNCTION Formu(cPermiso,lAlta)
LOCAL oBot := ARRAY(9) , aTipoIva, aTipoDoc, base, cDireccion:=SPACE(30), cLocalidad:=SPACE(30), aVendedor, oQryV,;
      cCUIT:=SPACE(13),  nCodArt:=0, nCantidad:=0, nPunit:=0, nPtotal:=0,  nNeto:=0, oQry, lUsoBorrar := .f.,;      
      nIVA:=0,  oFontLetra, oFontTotal,cDescu,oSay2,oDlg2,oWnd2,i,lResp:=.f.,oQryLis,cLisPre:="SIN LISTA ESPECIAL"+SPACE(31),;
      nNumFac:=0, nDNI := 0, nTiArt,oQryIvaT, cNomLis:=SPACE(50),aListas:={"Lista 1","Lista 2"}, cCodArtP := SPACE(30)
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
"14  Pequeño Contribuyente Eventual Social",;
"15  IVA NO Alcanzado"}
  
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS ventas_det_h2 ";
    +"( `id` INT(6) NOT NULL AUTO_INCREMENT, ";
    +"`CODART` bigint(14) NOT NULL,";  
    +"`DETART` VARCHAR(100) NOT NULL,";
    +"`CANTIDAD` DECIMAL(8,2) DEFAULT '0',";
    +"`FALTANTES` DECIMAL(8,2) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`NETO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`DESCUENTO`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`STOTAL`  DECIMAL(12,3) DEFAULT '0.00', ";
    +"`IVA` DECIMAL(12,3) DEFAULT '0.00', ";
    +"`CODIVA` INT(2) DEFAULT '0', ";
    +"`PTOTAL` DECIMAL(12,3) DEFAULT '0.00',";
    +"`PCOSTO` DECIMAL(12,3) DEFAULT '0.00',";
    +"`ESTADO` VARCHAR(1) NOT NULL,";
    +"`DESCP` DECIMAL(5,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
    //+"`COSTO` DECIMAL(10,2) DEFAULT '0.00', PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8")

oApp:oServer:NextResult()

IF lAlta 
    oQry    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pedidos_encab LIMIT 0")
    base    := oQry:GetBlankRow()
    base:fecha:= DATE()
    base:parafecha:= DATE()    
    base:estado := "P"
    base:id :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pedidos_encab")
    oQryDet :=oApp:oServer:Query("SELECT *,(cantidad-faltantes) AS disponibles FROM ventas_det_h2")
    oQryDet:ZAP()
    oQryV := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"vendedores")
    aVendedor := oQryV:FillArray(,{'nombre'})
    ELSE    
    oQry    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pedidos_encab WHERE id = " + ClipValue2Sql(oQryBrw:id)+" ")
    base:= oQry:GetRowObj() 
    oQry:lAppend:= .f.
    oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos_encab SET nuevo = FALSE WHERE id ="+ClipValue2Sql(oQryBrw:id)+" ")
    oApp:oMsg[5]:SetText(" ")
    
    oApp:oServer:Execute("DELETE FROM ventas_det_h2")           
    oApp:oServer:Execute("INSERT INTO ventas_det_h2 (codart,detart,cantidad,faltantes,punit,ptotal,stotal,iva,codiva,neto,descuento,estado,descp) "+;
                     "(SELECT p.codart,p.detart,p.cantidad,p.cantidad-cantidadreal,p.punitario,p.cantidadreal*p.punitario, "+;
                     "(p.cantidadreal*p.punitario) / (1+i.tasa/100),(p.cantidadreal*p.punitario) - (p.cantidadreal*p.punitario) / (1+i.tasa/100),"+;
                     "a.iva,(p.cantidadreal*p.punitario) / (1+i.tasa/100),descu,'A',descup FROM ge_"+oApp:cId+"pedidos_det p "+;
                     " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                     " LEFT JOIN ge_"+oApp:cId+"ivas i ON a.iva = i.codigo "+;
                      "WHERE p.idpedido = "+ClipValue2Sql(oQryBrw:id)+")")
    //oQryDet:ZAP()
    oApp:oServer:Execute("UPDATE ventas_det_h2 SET ptotal = ptotal * (1-descp/100), stotal = stotal * (1-descp/100) , "+;
                         " iva = iva  * (1-descp/100),  neto = neto * (1-descp/100) WHERE descp > 0")      
    oQryDet :=oApp:oServer:Query("SELECT *,(cantidad-faltantes) AS disponibles FROM ventas_det_h2")
    IF base:estado <> 'P'
       IF !MsgNoYes('Este pedido ya fue facturador con la factura '+base:facturanro+chr(10)+;
               'Queda bajo su responsabilidad la modificacion del mismo'+chr(10)+;
               'Desea continuar?','Atencion')
          RETURN .f.
       ENDIF   
    ENDIF   
    aVendedor := {base:vendedor}

ENDIF
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS formapag_temp";
    +"("; 
    +"`RENGLON`   INT(2) NOT NULL  AUTO_INCREMENT ,";
    +"`TIPOPAG`   INT(1) NOT NULL ,";
    +"`FORMAPAG`  VARCHAR(30) NOT NULL,";
    +"`CODFORMA`  INT(2) NOT NULL,";
    +"`IMPORTE`  DECIMAL(12,2) NOT NULL,"+;
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")  
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE formapag_temp")
oApp:oServer:NextResult()

nTipoDoc := 1 
oQryPun := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ClipValue2Sql(oApp:cip))

nPuntoVta := oQryPun:caja
oQryCli := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
oQryIvaT:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY tasa")
nPorIva:=21.00
nCodIva:= 5
nTiArt:=1
nDescuGen:=0
cDetArt:=SPACE(50)
nTotal:=0
nForPag:=2
nDeuda:= 0
nDescArt:=0
nDescArt1:=0
nPagado:=0
nVuelto:=0
nConIva:=1
lReemplaza:=.t.
cDescu:= "Descuento:"
cRemitos := base:vendedor + SPACE(200)
nLisPre:=1
nLisPreE:=0
nLisPreEAnt := 0
oQryLisPre:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre")

  //FUENTES -----------------------------------------------
  DEFINE FONT oFontLetra NAME "ARIAL" SIZE 35,60
  DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
    //DLG -----------------------------------------------
    DEFINE DIALOG oDlg2 RESOURCE "PEDIDO2" OF oWnd1
    oDlg2:lHelpIcon := .f.
    //Fechas y tipo de Comprobante
    REDEFINE GET oGet[01] VAR base:id        ID 174  OF oDlg2 WHEN (.f.)
    REDEFINE GET oGet[01] VAR base:fecha     ID 176  OF oDlg2 WHEN(.F.)
    REDEFINE GET oGet[02] VAR base:parafecha ID 175  OF oDlg2

    //CLIENTE
    REDEFINE GET oGet[08] VAR base:codcli ID 185 OF oDlg2 PICTURE "999999" WHEN(lAlta) ;
             ACTION (oGet[08]:cText:= 0, ValidaCli(,base:vendedor,lAlta))  BITMAP "BUSC1" VALID (ValidaCli(,base:vendedor,lAlta)) 
    REDEFINE GET oGet[09] VAR base:cliente ID 186 OF oDlg2 PICTURE "@!"  WHEN(.f.)
    REDEFINE GET oGet[10] VAR cDireccion ID 187  OF oDlg2 PICTURE "@!" WHEN(.f.)
    REDEFINE GET oGet[11] VAR cLocalidad ID 188  OF oDlg2 PICTURE "@!" WHEN(.f.)
    REDEFINE GET oGet[12] VAR cCUIT      ID 189 OF oDlg2 PICTURE "99-99999999-9" ;
             WHEN(.f.) VALID(ValidaCuit(cCuit))
    REDEFINE GET oGet[22] VAR nDNI      ID 201 OF oDlg2 PICTURE "99999999" ;
             WHEN(.f.)
    REDEFINE SAY oSay3 VAR cRemitos ID 4002 OF oDlg2 COLOR CLR_GREEN 

    REDEFINE COMBOBOX oGet[13] VAR nConIva ID 190 OF oDlg2 WHEN(.f.) ITEMS aTipoIva;
             ON CHANGE ValidaCli(.f.,base:vendedor) 

    REDEFINE COMBOBOX oGet[43] VAR base:vendedor ID 4014 OF oDlg2 WHEN(lAlta) ITEMS aVendedor

    REDEFINE GET oGet[31] VAR nDescuGen ID 308 OF oDlg2 PICTURE "999.99" WHEN(nTipoDoc = 5)
    REDEFINE GET oGet[32] VAR nDeuda    ID 4001 OF oDlg2 PICTURE "9999999999.99" WHEN(.F.)
    REDEFINE COMBOBOX oGet[36] VAR nLisPre   ID 4011  ITEMS aListas OF oDlg2 
    /*REDEFINE GET oGet[40] VAR nLisPreE ID 4017 OF oDlg2 PICTURE "999";
                 VALID((nLisPreE = 0 .and. IF(nLisPreE=0,(oGet[41]:cText:="SIN LISTA ESPECIAL"+SPACE(31))<>"xxx",.T.)) .or.;
                       Buscar(oQryLisPre,oDlg,oGet[40],oGet[41]));
                 ACTION (oGet[40]:cText:= 0, Buscar(oQryLisPre,oDlg,oGet[40],oGet[41])) BITMAP "BUSC1"*/
    REDEFINE GET oGet[40] VAR nLisPreE ID 4017 OF oDlg2 PICTURE "999" VALID(ValidaLista(oQryLisPre,oGet,oDlg2,.f.));
                 ACTION (ValidaLista(oQryLisPre,oGet,oDlg2,.T.)) BITMAP "BUSC1"
    REDEFINE GET oGet[41] VAR cLisPre ID 4018 OF oDlg2 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[42] VAR base:observa ID 4005 OF oDlg2  

    //TIPO ARTICULO
    REDEFINE RADIO oGet[24] VAR nTiArt  ID 300,301 OF oDlg2 WHEN(lAdmin);
             ON CLICK(nCodArt:=0        ,cDetArt:=SPACE(50),nCantidad:=0      ,nPunit:=0         ,nPTotal:=0,;
                      oGet[14]:Refresh(),oGet[15]:Refresh(),oGet[16]:Refresh(),oGet[17]:Refresh(),oGet[18]:Refresh(),;
                                         oGet[25]:Refresh(),oGet[26]:Refresh(),oGet[27]:Refresh(),oGet[28]:Refresh())
    
    //Datos del articulo registrado
    REDEFINE GET oGet[14] VAR nCodArt   ID 191  OF oDlg2 PICTURE "99999999999999" WHEN(nTiArt=1);
             ACTION (oGet[14]:cText:= 0, ValidaArt())  BITMAP "BUSC1" VALID(ValidaArt())
    REDEFINE GET oGet[15] VAR cDetArt   ID 192  OF oDlg2 PICTURE "@!" WHEN(.F.)
    REDEFINE GET oGet[16] VAR nCantidad ID 193  OF oDlg2 PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=1)
    REDEFINE GET oGet[17] VAR nPunit    ID 194  OF oDlg2 PICTURE "99999999.999" WHEN(lAdmin)
    REDEFINE GET oGet[33] VAR nDescArt  ID 4003 OF oDlg2 PICTURE "999.99" WHEN(lAdmin) VALID(nDescArt>=0 .and. nDescArt<=100)
    REDEFINE GET oGet[18] VAR nPtotal   ID 195  OF oDlg2 PICTURE "99999999.999" ;
            WHEN((oGet[18]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt/100)) = "-9" .and. nTiArt=1) 
    REDEFINE GET oGet[39] VAR cCodArtP   ID 4016  OF oDlg2 WHEN(nTiArt=1 .and. oApp:usar_codpro);
             VALID(oGet[39]:cText=SPACE(30) .OR. ValidaArtP())        
    //Datos del articulo ocacional
    REDEFINE GET oGet[25] VAR cDetArt   ID 302  OF oDlg2 PICTURE "@!" WHEN(nTiArt=2)
    REDEFINE GET oGet[26] VAR nCantidad ID 304  OF oDlg2 PICTURE "999999.999"  VALID(nCantidad>0) WHEN(nTiArt=2)
    REDEFINE GET oGet[27] VAR nPunit    ID 305  OF oDlg2 PICTURE "99999999.999" WHEN(nTiArt=2);
                 VALID((oGet[28]:cText := nCantidad*nPunit-(nCantidad*nPunit)*(nDescArt1/100)) <> "xxx" )
    REDEFINE GET oGet[34] VAR nDescArt1  ID 4004 OF oDlg2 PICTURE "999.99" WHEN(nTiArt=2)
    REDEFINE GET oGet[28] VAR nPtotal   ID 306  OF oDlg2 PICTURE "99999999.999" WHEN(.f.)
    REDEFINE GET oGet[30] VAR nPorIva   ID 303  OF oDlg2 PICTURE "999.99" WHEN(nTiArt=2); 
             VALID((oQryIvaT:Seek(nPorIva,3) > 0) .and. ((nCodIva:=oQryIvaT:codigo) >0 ))
          
    //neto y IVA y total
    REDEFINE GET oGet[19] VAR nNeto  ID 198 OF oDlg2 PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[20] VAR nIVA   ID 199 OF oDlg2 PICTURE "999999999.99" WHEN(.F.)
    REDEFINE GET oGet[21] VAR nTotal ID 200 OF oDlg2 COLOR CLR_RED , CLR_YELLOW READONLY;
           PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)
       
    //GRILLA ---------------------------------------------------------------      
    
    REDEFINE XBROWSE oBrw DATASOURCE oQryDet;
       COLUMNS "CODART","DETART","CANTIDAD","FALTANTES","DISPONIBLES","PUNIT","NETO","DESCP","DESCUENTO","STOTAL","IVA","PTOTAL","CODIVA";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Faltantes","Disponibles","Precio U","Neto","% Desc","Dto./Rec.","Sub Total","IVA","Total","Tasa";
       FOOTERS ;
       SIZES 75,350,65,65,65,65,65,65,65,65,65,70,60,66;
    ID 197 OF oDlg2 AUTOSORT
    PintaBrw(oBrw,0)
    
    oBrw:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(EliminarItem(base),lUsoBorrar := .t.,;
                                   nTotal:= oBrw:aCols[12]:nTotal,oGet[21]:Refresh()),)}
    oBrw:aCols[12]:nFooterTypE := AGGR_SUM
    oBrw:aCols[7]:nFooterTypE := AGGR_SUM
    oBrw:aCols[9]:nFooterTypE := AGGR_SUM
    oBrw:aCols[10]:nFooterTypE := AGGR_SUM
    oBrw:aCols[11]:nFooterTypE := AGGR_SUM
    FOR i:= 7 to 11
     oBrw:aCols[i]:Hide()
    NEXT i
    oBrw:aCols[8]:Show()
    oBrw:aCols[13]:Hide()
    oBrw:aCols[2]:lAutoSave := .t.
    oBrw:aCols[2]:nEditType := EDIT_GET  
    oBrw:aCols[3]:lAutoSave := .t.
    oBrw:aCols[3]:nEditType := EDIT_GET      
    oBrw:aCols[3]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval,,3)} 
    oBrw:aCols[4]:lAutoSave := .t.
    oBrw:aCols[4]:nEditType := EDIT_GET  
    oBrw:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaCant(xval)} 
    oBrw:aCols[8]:lAutoSave := .t.
    oBrw:aCols[8]:nEditType := EDIT_GET 
    oBrw:aCols[8]:bOnPostEdit := {|oCol, xVal, nKey | IF(lAdmin,CambiaCant(,xval),nil)} 

    
    //BOTONES ---------------------------------------------------------------
    //+
    REDEFINE BUTTON oBot[1] ID 196 ACTION(AgregaItem(nTiArt,@lUsoBorrar),IF(nTiArt=1,oGet[14]:Setfocus(),oGet[25]:Setfocus()) ) ;
                   WHEN(((nCodArt>0 .and. nTiArt=1 .and. (nPtotal>0 .or. nDescArt=100)) ;
                    .or. (nTiArt=2 .and. cDetArt<>SPACE(30) .and. nPtotal>0)) .and. nCantidad > 0)
    //cancelar
    REDEFINE BUTTON oBot[2] ID 102 ACTION (LimpiarForm()) 
    //grabar
    REDEFINE BUTTON oBot[3] ID 103 ACTION (lResp :=Validaciones(oQry,base,.f.,lAlta,lUsoBorrar),IF(lResp,(oDlg2:End(),lResp:=.t.),nil)) WHEN(oQryDet:RecCount() > 0)
    //grabar
    REDEFINE BUTTON oBot[4] ID 104 ACTION ImprimirPedido(base) WHEN(oQryDet:RecCount() > 0 .and. !lAlta .and. !lUsoBorrar) 
    //grabar
    REDEFINE BUTTON oBot[7] ID 107 ACTION (oBrw:ToExcel(),oDlg2:End(),lResp:=.f.) CANCEL
    //salir
    REDEFINE BUTTON oBot[6] ID 106 ACTION (oDlg2:End(),lResp:=.f.) CANCEL

    REDEFINE BUTTON oBot[9] ID 4013 ACTION GenAnticipo(base:codcli,oGet[32]) WHEN( base:codcli > 1)
    // Ver Historial
    REDEFINE BUTTON oBot[8] ID 4012 ACTION VerHistorial(base:codcli,oQryDet,oBrw) WHEN(base:codcli > 0)
    // F9 Para grabar             
    oDlg2:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[3]:Click,.f.) }
    //ACTiVACION   ---------------------------------------------------------------
    ACTIVATE DIALOG oDlg2 CENTER ON INIT IF(base:codcli>0,ValidaCli(,base:vendedor,.f.),nil)

RETURN lResp

*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaCant(n,nPorc,nCol,nPUnit)
LOCAL base := oQryDet:GetRowObj(), nPrecio2, nDescuento, nPrecio1, nIvaPes, nSubTotal, nTotalcIva, ;
      oQryIva, nCodIva1, nIvaCalc, oQryPrecio, oQryArt1
DEFAULT n := base:faltantes,nPorc:= base:descp,nCol := 4,nPUnit:= base:punit
oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(base:codiva))
IF nCol = 4
  IF base:codart > 0    
    IF VALTYPE(nPunit) <> "N" .OR. VALTYPE(n) <> "N" 
       RETURN nil 
    ENDIF
    IF nPunit = base:punit 
        oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPreE)+" AND "+;
                                    "codart = "+ClipValue2Sql(base:codart))
        IF oQryPrecio:RecCount() > 0
           nPunit:= oQryPrecio:precio 
        ELSE 
           oQryArt1:= oApp:oServer:Query("SELECT precioven,reventa FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
           nPunit:= IF(nLisPre=1,oQryArt1:precioven,oQryArt1:reventa)
        ENDIF
    ENDIF
  ENDIF  
      nPrecio2:= (nPUnit) * (base:cantidad-n)
      nDescuento:= nPrecio2 * (nPorc/100)
      nPrecio1:= nPrecio2 - nDescuento
      nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
      nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
      nSubTotal:= nPrecio1 - nIvaPes
      nTotalcIva := nPrecio1 

      base:descp:= nPorc
      base:faltantes := n 
      base:ptotal:=nTotalcIva
      base:neto:=nPrecio2-nIvaCalc
      base:iva:=nIvaPes
      base:descuento:=nDescuento
      base:stotal:=nSubTotal
      base:punit:= nPUnit
ELSE
  IF base:codart > 0    
    IF VALTYPE(nPunit) <> "N" .OR. VALTYPE(n) <> "N" 
       RETURN nil 
    ENDIF
    IF nPunit = base:punit 
        oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPreE)+" AND "+;
                                    "codart = "+ClipValue2Sql(base:codart))
        IF oQryPrecio:RecCount() > 0
           nPunit:= oQryPrecio:precio 
        ELSE 
           oQryArt1:= oApp:oServer:Query("SELECT precioven,reventa FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart))
           nPunit:= IF(nLisPre=1,oQryArt1:precioven,oQryArt1:reventa)
        ENDIF
    ENDIF
  ENDIF
      nPrecio2:= (nPUnit) * (n)
      nDescuento:= nPrecio2 * (nPorc/100)
      nPrecio1:= nPrecio2 - nDescuento
      nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
      nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
      nSubTotal:= nPrecio1 - nIvaPes
      nTotalcIva := nPrecio1 

      base:descp:= nPorc
      base:cantidad := n 
      base:ptotal:=nTotalcIva
      base:neto:=nPrecio2-nIvaCalc
      base:iva:=nIvaPes
      base:descuento:=nDescuento
      base:stotal:=nSubTotal
      base:punit:= nPUnit
ENDIF
oQryDet:oRow := base
oQryDet:Save()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[10]:nTotal 
oGet[20]:cText := oBrw:aCols[11]:nTotal      
oGet[21]:cText := oBrw:aCols[12]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
RETURN nil


************************************************************************************
** Vaciar el formulario despues de grabar o cancelar
STATIC FUNCTION LimpiarForm()
oQryDet:Zap()
IF oQryPag <> nil
   oQryPag:Zap()
ENDIF
oBrw:Refresh()
oBrw:Maketotals()
nTotal:=0
nPagado:=0
nVuelto:=0
oGet[19]:cText := oBrw:aCols[10]:nTotal 
oGet[20]:cText := oBrw:aCols[11]:nTotal      
oGet[21]:cText := oBrw:aCols[12]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
oGet[08]:cText := 1
oGet[08]:SetFocus()
oQryBrw:Refresh()
RETURN nil


************************************************************************************
** Agregar item a la venta
STATIC FUNCTION AgregaItem(nTiArt,lUsoBorrar)
LOCAL oQryIva, nTotalcIva, nIvaPes, nCodIva1, nSubTotal, nDescuento,;
      i,nCantidad,nPrecio1,nPrecio2,lRta:=.f.,nIvaCalc:=0,nPrecioVen,oQryOfe, nPUnit, oQryS

IF nTiArt = 1
   //Valido que tenga stock el producto cuando no es stock de otro
   IF oQryPun:pidestock = 1 .and. oQryArt:stockact-oGet[16]:value < 0 .and. !oQryArt:stockotro
      lRta:=MsgYesNo("El articulo que esta facturando esta fuera de stock,"+CHR(10)+;
              "verifique su disponibilidad ¿Desea continuar?"+CHR(10)+;
              "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
      IF !lRta 
         RETURN .f.
      ENDIF      
  ENDIF
  //Valido que tenga stock el producto que es stock de otro
  IF oQryPun:pidestock = 1 .and. oQryArt:stockotro 
      oQryS := oApp:oServer:Query("SELECT r.CODUSA, (a.STOCKACT - (r.CANTIDAD * "+STR(oGet[16]:value)+" )) AS STOCK_FINAL "+;
                                  " FROM ge_"+oApp:cId+"reseta r "+;
                                  " JOIN ge_"+oApp:cId+"articu a ON r.CODUSA = a.CODIGO "+;
                                  " JOIN ge_"+oApp:cId+"articu a1 ON r.CODART = a1.CODIGO "+;
                                  " WHERE r.CODART = "+STR(oQryArt:codigo)+;
                                  " HAVING STOCK_FINAL < 0")
      IF oQryS:nRecCount > 0
          lRta:=MsgYesNo("El articulo que esta facturando tiene receta, y los articulos"+chr(10)+;
                  "que la componen estan fuera de stock,"+CHR(10)+;
                  "verifique su disponibilidad ¿Desea continuar?","Atencion")
          IF !lRta 
             RETURN .f.
          ENDIF                
      ENDIF    
  ENDIF   
  IF oQryPun:pidestock = 2 .and. oQryArt:stockact-oGet[16]:value < 0 .and. !oQryArt:stockotro
     MsgStop("No puede facturar el articulo seleccionado porque no esta en stock"+CHR(10)+;
           "Stock actual: "+ALLTRIM(STR(oQryArt:stockact)),"Atencion")
     RETURN .F.
  ENDIF
  //No dejo vender por falta de stock de la receta
  IF oQryPun:pidestock = 2 .and. oQryArt:stockotro 
      oQryS := oApp:oServer:Query("SELECT r.CODUSA, (a.STOCKACT - (r.CANTIDAD * "+STR(oGet[16]:value)+" )) AS STOCK_FINAL "+;
                                  " FROM ge_"+oApp:cId+"reseta r "+;
                                  " JOIN ge_"+oApp:cId+"articu a ON r.CODUSA = a.CODIGO "+;
                                  " JOIN ge_"+oApp:cId+"articu a1 ON r.CODART = a1.CODIGO "+;
                                  " WHERE r.CODART = "+STR(oQryArt:codigo)+;
                                  " HAVING STOCK_FINAL < 0")
      IF oQryS:nRecCount > 0
          MsgStop("No puede facturar, el articulo seleccionado tiene receta, "+chr(10)+;
                  "y los articulos que la componen estan fuera de stock."+CHR(10),"Atencion")
          RETURN .F.
      ENDIF    
  ENDIF

   nPrecioVen:= oGet[17]:value
   oQryIva := oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(oQryArt:iva))
   nCodIva1 := oQryArt:iva
   nPrecio2:= nPrecioVen * oGet[16]:value
   nDescuento:= nPrecio2 * (IF(nDescArt>0,nDescArt,nDescuGen)/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaCalc := nPrecio2 - (nPrecio2 / (1 + oQryIva:tasa/100))
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + oQryIva:tasa/100))
   nSubTotal:= nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1
   oApp:oServer:Execute("INSERT INTO ventas_det_h2 (codart,detart,cantidad,faltantes,punit,ptotal,neto,iva,codiva,descuento,descp,stotal,pcosto,estado) "+;
                         "VALUE ( "+ClipValue2Sql(oQryArt:codigo)+","+;
                                 ClipValue2Sql(oGet[15]:value)+","+;
                                 ClipValue2Sql(oGet[16]:cText)+",0,"+;
                                 ClipValue2Sql(nPrecioVen)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio2-nIvaCalc)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva1)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(IF(nDescArt>0,nDescArt,nDescuGen))+","+;
                                 ClipValue2Sql(nSubTotal)+","+;
                                 ClipValue2Sql(oQryArt:preciocos)+",'P'"+;
                         " )" ) 
ELSE
 /*nDescuento:=oGet[18]:Value * (IF(nDescArt1>0,nDescArt1,nDescuGen)/100)
 nSubTotal:=oGet[18]:Value - nDescuento
 nIvaPes := nSubTotal * (nPorIva/100)
 nTotalcIva := nSubTotal + nIvaPes
 nCodIva := IF(nPorIva=0,3,nCodIva)
 oApp:oServer:Execute("INSERT INTO ventas_det_h2 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto,estado) "+;
                      "VALUE ( 0,"+;
                                 ClipValue2Sql(oGet[15]:value)+","+;
                                 ClipValue2Sql(oGet[16]:value)+","+;
                                 ClipValue2Sql(oGet[17]:value)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(oGet[18]:value)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(nSubTotal)+",0,'P'"+;
                       " )" )*/
   nPunit  := oGet[27]:value
   nPunit  := IF(oApp:artievenmasiva,nPunit*(1+nPorIva*0.01),nPunit)
   nPunit  := IF(oApp:artievenendolar,nPunit*oQryPar:dolar,nPunit)
   nPrecio2:= oGet[27]:value  * oGet[26]:value
   nPrecio2:= IF(oApp:artievenmasiva,nPrecio2*(1+nPorIva*0.01),nPrecio2)
   nPrecio2:= IF(oApp:artievenendolar,nPrecio2*oQryPar:dolar,nPrecio2)
   nDescuento:=nPrecio2 * (IF(nDescArt1>0,nDescArt1,nDescuGen)/100)
   nPrecio1:= nPrecio2 - nDescuento
   nIvaCalc := nPrecio2 - (nPrecio2 / (1 + nPorIva/100))
   nIvaPes := nPrecio1 - (nPrecio1 / (1 + nPorIva/100))
   nSubTotal:= nPrecio1 - nIvaPes
   nTotalcIva := nPrecio1 
   nCodIva := IF(nPorIva=0,3,nCodIva)

   oApp:oServer:Execute("INSERT INTO ventas_det_h2 (codart,detart,cantidad,punit,ptotal,neto,iva,codiva,descuento,stotal,pcosto,estado) "+;
                      "VALUE ( 0,"+;
                                 ClipValue2Sql(oGet[25]:value)+","+;
                                 ClipValue2Sql(oGet[26]:value)+","+;
                                 ClipValue2Sql(nPunit)+","+;
                                 ClipValue2Sql(nTotalcIva)+","+;
                                 ClipValue2Sql(nPrecio2-nIvaCalc)+","+;
                                 ClipValue2Sql(nIvaPes)+","+;
                                 ClipValue2Sql(nCodIva)+","+;
                                 ClipValue2Sql(nDescuento)+","+;
                                 ClipValue2Sql(nSubTotal)+",0,'P'"+;
                       " )" )
ENDIF                                 
oApp:oServer:NextResult()
oQryDet:Refresh()
oBrw:Refresh()
oBrw:MakeTotals()
oBrw:GoBottom()
oGet[19]:cText := oBrw:aCols[10]:nTotal 
oGet[20]:cText := oBrw:aCols[11]:nTotal 
oGet[14]:cText:=1
oGet[14]:Refresh()
oGet[15]:cText:=SPACE(30)
oGet[25]:cText:=SPACE(30)
oGet[25]:Refresh()
oGet[15]:Refresh()
oGet[33]:cText := 0
oGet[34]:cText := 0
FOR i:= 16 TO 18
   oGet[i]:cText:=0
   oGet[i+10]:cText:=0
   oGet[i]:Refresh()
   oGet[i+10]:Refresh()
NEXT i
oGet[21]:cText := oBrw:aCols[12]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
lUsoBorrar := .t.
RETURN .t.

************************************************************************************
** Borrar item de la venta
STATIC FUNCTION EliminarItem(base)
oQryDet:DELETE()
oBrw:Refresh()
oQryDet:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[10]:nTotal 
oGet[20]:cText := oBrw:aCols[11]:nTotal 
oGet[21]:cText := oBrw:aCols[12]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
Auditar(1," Item ped. "+alltrim(oQryDet:detart)+" "+ALLTRIM(Str(oQryDet:cantidad)) + " Ped N° "+ALLTRIM(STR(base:id)))
RETURN .t.


************************************************************************************
STATIC FUNCTION ValidaCli(lVerCli,cVendedor,lAlta)
LOCAL nNro:=0,oQryLis1
DEFAULT lVerCli := .T.

IF lVerCli
  BuscarArt(oQryCli,oDlg2,oGet[08],oGet[09])
  oGet[10]:cText := oQryCli:direccion
  oGet[11]:ctext := oQryCli:localidad
  oGet[12]:cText := oQryCli:cuit
  oGet[22]:cText := oQryCli:dni
  oGet[31]:cText := oQryCli:descuento
  oGet[32]:cText := oApp:oServer:Query("SELECT SUM(saldo) AS deuda FROM ge_"+oApp:cId+"ventas_cuota "+;
                                       "WHERE cliente = "+ClipValue2Sql(oQryCli:codigo)):deuda - oQryCli:saldo
  oGet[13]:Set(oQryCli:coniva)
  oGet[09]:Refresh()
  oGet[10]:Refresh()
  oGet[11]:Refresh()
  oGet[12]:Refresh()
  oGet[22]:Refresh()
  oGet[32]:Refresh()
  oGet[13]:Refresh()
  manticipo:=oQryCli:saldo
  IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"remitos WHERE codcli = " + ClipValue2Sql(oQryCli:Codigo)):RecCount() > 0
      cRemitos:= "Vend:"+alltrim(cVendedor)+"- CON REMITOS PENDIENTES"
      oSay3:setcolor(CLR_RED)
  ELSE
      cRemitos:= "Vend:"+alltrim(cVendedor)+"- SIN REMITOS PENDIENTES"
      oSay3:setcolor(CLR_GREEN)
  ENDIF
  
  oGet[36]:Set(oQryCli:lispre)
  nLisPreE:= oQryCli:lispreesp
  nLisPreEAnt := nLisPreE
  oGet[40]:Refresh()
  oGet[41]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"lispre WHERE codigo = "+ClipValue2Sql(oQryCli:lispreesp)):nombre
ELSE
  cRemitos:= SPACE(20)
  oGet[36]:Set(1)
ENDIF      
oSay3:Refresh()    
oGet[1]:Refresh()
oBrw:Refresh()
oBrw:Maketotals()
oGet[19]:cText := oBrw:aCols[10]:nTotal 
oGet[20]:cText := oBrw:aCols[11]:nTotal 
oGet[21]:cText := oBrw:aCols[12]:nTotal
oGet[19]:Refresh()
oGet[20]:Refresh()
oGet[21]:Refresh()
IF lAlta 
   oGet[43]:Set(oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"vendedores WHERE codigo = "+ClipValue2Sql(oQryCli:vendedor)):nombre)
ENDIF
RETURN .T.


************************************************************************************
** Validar Articulo
STATIC FUNCTION ValidaArt()
LOCAL oQryPrecio,nPrecioven:=0
oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,stockact,precioven,reventa,iva,fecmod,preciocos,endolares,stockotro  "+;
                             "FROM ge_"+oApp:cId+"articu WHERE nosale is false AND codigo = "+ClipValue2Sql(oGet[14]:cText))
IF oQryArt:RecCount() = 0 .OR. oGet[14]:value = 0
  oGet[14]:cText:= 0
  BuscarArt(oQryArt,oDlg2,oGet[14],,'0','nosale')
ENDIF
IF oApp:oServer:Query("SELECT codigo,nombre,stockact,precioven,reventa,iva,fecmod,preciocos,endolares  "+;
                             "FROM ge_"+oApp:cId+"articu WHERE nosale is false AND codigo = "+ClipValue2Sql(oGet[14]:cText)):RecCount = 0
   RETURN .f.
ENDIF   
IF oApp:usar_dias_precio
  IF oQryArt:fecmod < (DATE()- oApp:dias_precio)
    MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
            "Verifique la fecha de modificacion","Atencion!")
    RETURN .f.
  ENDIF
ENDIF
oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPreE)+" AND "+;
                              "codart = "+ClipValue2Sql(oQryArt:codigo))
IF oQryPrecio:RecCount() = 0
   nPrecioVen:= IF(nLisPre=1,oQryArt:precioven,oQryArt:reventa)
ELSE
   nPrecioVen:= oQryPrecio:precio 
ENDIF

oGet[15]:cText := oQryArt:nombre
oGet[16]:cText := 1
oGet[17]:ctext := nPrecioVen * IF(oQryArt:endolares,oQryPar:dolar,1)
oGet[18]:cText := nPrecioVen * IF(oQryArt:endolares,oQryPar:dolar,1)


     
oGet[14]:Refresh()
oGet[15]:Refresh()
oGet[16]:Refresh()
oGet[17]:Refresh()
oGet[18]:Refresh()
RETURN .t.

**********************************************************************************************
STATIC FUNCTION ValidaArtP()
LOCAL oQryPrecio,nPrecioven:=0
    oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,stockact,precioven,iva,fecmod,reventa,preciocos,endolares,marca,stockmin,impint "+;
                             "FROM ge_"+oApp:cId+"articu WHERE codigopro = "+ClipValue2Sql(oGet[39]:cText)) 
    

IF oQryArt:RecCount() = 0 
   MsgStop("Codigo de proveedor no existe","Error")
   RETURN .f.
ENDIF
IF oApp:usar_dias_precio
  IF oQryArt:fecmod < (DATE()- oApp:dias_precio)
    MsgStop("El precio del articulo seleccionado esta desactualizado "+CHR(10)+;
            "Verifique la fecha de modificacion","Atencion!")
    RETURN .f.
  ENDIF
ENDIF
oQryPrecio:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispredet WHERE codlis = "+ClipValue2Sql(nLisPreE)+" AND "+;
                              "codart = "+ClipValue2Sql(oQryArt:codigo))
IF oQryPrecio:RecCount() = 0
   nPrecioVen:= IF(nLisPre=1,oQryArt:precioven,oQryArt:reventa)
ELSE
   nPrecioVen:= oQryPrecio:precio 
ENDIF
oGet[14]:cText := oQryArt:codigo
oGet[15]:cText := oQryArt:nombre
oGet[16]:cText := 1
oGet[17]:ctext := nPrecioVen * IF(oQryArt:endolares,oQryPar:dolar,1)
oGet[18]:cText := nPrecioVen * IF(oQryArt:endolares,oQryPar:dolar,1)

     
oGet[14]:Refresh()
oGet[15]:Refresh()
oGet[16]:Refresh()
oGet[17]:Refresh()
oGet[18]:Refresh()
oGet[39]:oJump := oGet[16]
oGet[39]:cText := SPACE(30)
oGet[16]:SetFocus()
RETURN .t.

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

************************************************************************************
** Validaciones a hacer cuando quiere grabar (Incluye forma de pago y facturacion)
STATIC FUNCTION Validaciones(oQry,base,lCierra,lAlta,lUsoBorrar)
LOCAL cLetra, oGet1 := ARRAY(20), oBot := ARRAY(4), oForm, lRta := .f., oBrw2, oQryCuo, dFecVto,;
      cDetTar, cDetChe := SPACE(30), aTablaIva := {}, oTabIva, nNro , cCae, cTipoDoc,lFisc:=.f.,;
      oQryVen, oQryPag, oQryPagCon, oQryPagFac,  oErr, nRecibo, nTipFor, nSaldo := 0,nNumero:=0,;
      oQryTar, aTarjetas, oError, nCodPro:=0,nCodBan:=0,nNumeroOrd:=0,nNumDep:=0,nOpcion:=1

TRY 
      oApp:oServer:BeginTransaction()
      IF lAlta
         base:id := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pedidos_encab")
      ENDIF   
      oQry:oRow := base
      oQry:Save()
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos_det WHERE idpedido = "+ClipValue2Sql(oQry:id))
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pedidos_det "+;
                        " (idpedido,codart,detart,cantidad,cantidadreal,punitario,descu,descup) "+;
                        " (SELECT "+ClipValue2Sql(base:id)+",codart,detart,cantidad,cantidad-faltantes,punit,descuento,descp "+;
                        " FROM ventas_det_h2)")
      oApp:oServer:CommitTransaction()
      IF lAlta 
         IF MsgYesNo("Imprimir el nuevo pedido","Atencion")
            ImprimirPedido(base)
         ENDIF
      ENDIF 
      IF !lAlta .and. lUsoBorrar     
         IF MsgYesNo("Imprimir el nuevo pedido","Atencion")
            ImprimirPedido(base)
         ENDIF
      ENDIF
  CATCH oErr
      MsgStop("El pedido no se guardo porque otra terminal estaba actualizando"+CHR(10)+;
              "Vuelva a poner grabar para grabar este pedido"+CHR(10)+oErr:description,"Error")
      oApp:oServer:RollBack()
      RETURN .F.
 END TRY
LimpiarForm()
oBrwG:Refresh()
RETURN .t.


**************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQryBrw:id
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el pedido  N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"pedidos_encab WHERE id = " + ClipValue2Sql(oQryBrw:id))
  oApp:oServer:CommitTransaction()
  Auditar(1," "+ALLTRIM(oQryBrw:cliente)+ " Ped. N° "+alltrim(STR(oQryBrw:ID,10)))
  oQryBrw:Refresh()
CATCH oError
    ValidaError(oError)
END TRY
oBrwG:Refresh()
RETURN nil 


*******************************************
** Impresion de Pedido
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
      lRta := MsgNoYes("Desea imprimir por comandera?","Atencion")
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
         @ 5.5, 12.5 PRINT TO oPrn TEXT ALLTRIM(oQryCli:nombre) + " ("+ALlTRIM(STR(oQryCli:codigo))+")"; 
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
         @ 23.0,1  PRINT TO oPrn TEXT IF(!empty(base:vendedor),"Vendedor: "+ALLTRIM(base:vendedor),"") ;
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
                 @ nRow, 00 PRINT TO oPrn TEXT "Pedido N#: "+ALLTRIM(STR(base:id)) ;
                      SIZE 4.8,1 CM FONT oFont1 LASTROW nRow
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
                 @ nRow, 00 PRINT TO oPrn TEXT "V:" + ALLTRIM(base:vendedor);
                              SIZE 4.5,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow 
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
                 @ nRow, 00 PRINT TO oPrn TEXT "Pedido N#: "+ALLTRIM(STR(base:id)) ;
                      SIZE 7.5,1 CM FONT oFont1 LASTROW nRow
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
                 @ nRow, 00 PRINT TO oPrn TEXT "V:" + ALLTRIM(base:vendedor);
                              SIZE 7.5,.5 CM FONT oFont1 ALIGN "L" LASTROW nRow 
                 @ nRow, 00 PRINT TO oPrn TEXT "...";
                              SIZE 7.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
           ENDPAGE
           ENDPRINT
        ENDIF
    ENDIF
RETURN nil



**********************************************
** Historial de Ventas realizadas
STATIC FUNCTION VerHistorial(nCodcli,oQry,oBrw)
LOCAL oBot := ARRAY(2), oForm, lRta := .f., aCor, oFont, oFont1, oError,;
      oQryVen, oQryDet, oBrwVen, oBrwDet
oQryVen := oApp:oServer:Query("SELECT CONCAT(v.ticomp,v.letra, v.numcomp) AS compro, v.fecha as fecha, "+;                          
                          "  v.importe"+;
                          " FROM ge_"+oApp:cId+"ventas_encab v "+;
                          " WHERE v.codcli = " + ClipValue2Sql(nCodCli) + " AND v.ticomp IN ('FC','FR') "+;
                          " ORDER BY v.fecha DESC" )
oQryDet := oApp:oServer:Query("SELECT codart,cantidad,detart,punit,importe FROM ge_"+oApp:cId+"ventas_det LIMIT 0 ")
           
DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0,-22
DEFINE DIALOG oForm TITLE "Historial"  FROM 05,15 TO 25,130 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)   
   @ 05, 05 SAY "COMPROBANTES" OF oForm SIZE 100,14 PIXEL FONT oFont1
   @ 25, 05 XBROWSE oBrwVen SIZE 170,100 PIXEL OF oForm DATASOURCE oQryVen ;
      COLUMNS "fecha","compro","importe";
      HEADERS "Fecha","Comprobante","Importe";
              SIZES 80,100,100;
      FOOTERS CELL LINES NOBORDER AUTOSORT ON CHANGE Actuali(oQryVen,oQryDet,oBrwDet)
   oBrwVen:aCols[3]:nFooterType   := AGGR_SUM   
   oBrwVen:MakeTotals()
   oBrwVen:CreateFromCode()   
   PintaBrw(oBrwVen,0)
   @ 05,185 SAY "Detalle Comprobante" OF oForm SIZE 205,14 PIXEL FONT oFont1
   @ 25,185 XBROWSE oBrwDet SIZE 260,100 PIXEL OF oForm DATASOURCE oQryDet ;
          COLUMNS 'codart',"detart","cantidad","punit","importe";
          HEADERS 'Codigo',"Detalle Producto","Cant.","Unitario","Total";
          SIZES 70,220,60,60,80 FOOTERS;
          CELL LINES NOBORDER AUTOSORT          
   oBrwDet:aCols[3]:nFooterType   := AGGR_SUM
   oBrwDet:aCols[5]:nFooterType   := AGGR_SUM
   oBrwDet:MakeTotals()
   oBrwDet:CreateFromCode()
   PintaBrw(oBrwDet,0)   

  
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Repetir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT Actuali(oQryVen,oQryDet,oBrwDet)
IF !lRta 
   RETURN NIL
ENDIF
TRY
    oApp:oServer:BeginTransaction()
    oApp:oServer:Execute("DELETE FROM ventas_det_h2")           
    oApp:oServer:Execute("INSERT INTO ventas_det_h2 (codart,detart,cantidad,faltantes,punit,ptotal,stotal,iva,codiva,neto,descuento,estado) "+;
                     "(SELECT v.codart,v.detart,v.cantidad,0,a.precioven,a.precioven*v.cantidad,"+;
                     "a.precioven*v.cantidad/1.21,a.precioven*v.cantidad-a.precioven*v.cantidad/1.21,"+;
                     "a.iva,a.precioven*v.cantidad/1.21,0,0 FROM ge_"+oApp:cId+"ventas_det v "+;
                     "LEFT JOIN ge_"+oApp:cId+"articu a ON v.codart = a.codigo "+;
                     "WHERE v.nrofac = "+ClipValue2Sql(oQryVen:compro)+")")
    oApp:oServer:CommitTransaction()
    oQry:Refresh()
    oQry:GoTop()
    DO WHILE !oQry:EOF()
       CambiaCant(,,,)     
       oQry:Skip()
    ENDDO
    oBrw:Refresh()
    oBrw:Maketotals()
    oGet[19]:cText := oBrw:aCols[10]:nTotal 
    oGet[20]:cText := oBrw:aCols[11]:nTotal      
    oGet[21]:cText := oBrw:aCols[12]:nTotal
    oGet[19]:Refresh()
    oGet[20]:Refresh()
    oGet[21]:Refresh()
CATCH oError
    MsgStop("Error al repetir"+CHR(10)+oError:description,"Error")
    oApp:oServer:RollBack()
END TRY    
RETURN nil


***********************************************
** Busca los articulos vendidos en cada factura
STATIC FUNCTION Actuali(oQryVen,oQryDet,oBrwDet)
LOCAL cWhere
cWhere := "nrofac = " + ClipValue2Sql(oQryVen:compro) 
oQryDet:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwDet:MakeTotals()
oBrwDet:Refresh()
RETURN .t.

STATIC FUNCTION ValidaLista(oQryLisPre,oGet,oDlg2,lAyuda)
LOCAL lRta := .f., i
IF !lAyuda .and. ALLTRIM(oGet[40]:cText) = "0"
   oGet[41]:cText:="SIN LISTA ESPECIAL"+SPACE(31)
   RETURN .t.
   ELSE 
   IF lAyuda
      oGet[40]:cText := 0
   ENDIF   
   Buscar(oQryLisPre,oDlg2,oGet[40],oGet[41])
   IF oGet[40]:value <> nLisPreEAnt
      lRta := MsgNoYes("Desea aplicar la lista de precios a los articulos ya cargados?","Atencion")
      IF lRta 
         nLisPreEAnt := oGet[40]:value
         IF "Lista usada" $ oGet[42]:cText
            i := AT("Lista usada",oGet[42]:cText)
            oGet[42]:cText := STRTRAN(oGet[42]:cText,SUBSTR(oGet[42]:cText,i-1,18)," (Lista usada:"+STR(nLisPreEAnt,3)+")") 
            ELSE
            oGet[42]:cText := alltrim(oGet[42]:cText)+" (Lista usada:"+STR(nLisPreEAnt,3)+")" 
         ENDIF   
         ActualizarDet()
      ENDIF
   ENDIF 
ENDIF
RETURN .t.

**************************************************
*** ACTUALIZAR TODO EL DETALLE 
STATIC FUNCTION ActualizarDet(lPedido)
DEFAULT lPedido := .f.
oQryDet:GoTop()
DO WHILE !oQryDet:EOF()
   CambiaCant(,,,)     
   oQryDet:Skip()
ENDDO
RETURN .T.

***********************************
** Reporte de pedidos 
STATIC FUNCTION ReporPed()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,oGru,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(8), oBot1, oBot2, cTodos := "Todos                   ", ;
      mdesde := DATE(), mhasta := DATE(), mtotal := 0, lResu := .t., lFacturados := .f., oQryVen, oQryCli,;
      mnomven := SPACE(30),mvendedor := 0, mcliente := 0, mnomcli := SPACE(30)
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
oQryVen:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores")   
oQryCli:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"clientes")     
DEFINE DIALOG oDlg1 TITLE "Reporte de Pedidos Pendientes" FROM 03,15 TO 17,65 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Para Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 37, 01 SAY "Vendedor (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 52, 01 SAY "Cliente (0 Todos):" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) 
   @ 35, 65 GET oGet[3] VAR mvendedor OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[3]:value = 0 .or. Buscar(oQryVen,oDlg1,oGet[3],oGet[4]));
                ACTION (oGet[3]:cText:= 0, Buscar(oQryVen,oDlg1,oGet[3],oGet[4])) BITMAP "BUSC1" 
   @ 35,100 GET oGet[4] VAR mnomven PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[4]:cText := IF(mvendedor=0,cTodos,oQryVen:nombre)) = SPACE(30)) SIZE 90,12
   @ 50, 65 GET oGet[7] VAR mcliente OF oDlg1 SIZE 30,12 PIXEL RIGHT;
                VALID(oGet[7]:value = 0 .or. Buscar(oQryCli,oDlg1,oGet[7],oGet[8]));
                ACTION (oGet[7]:cText:= 0, Buscar(oQryCli,oDlg1,oGet[7],oGet[8])) BITMAP "BUSC1" 
   @ 50,100 GET oGet[8] VAR mnomcli PICTURE "@!"  OF oDlg1 PIXEL;
                WHEN((oGet[8]:cText := IF(mcliente=0,cTodos,oQryCli:nombre)) = SPACE(30)) SIZE 90,12
   @ 65 ,05 CHECKBOX oGet[5] VAR lResu PROMPT "Resumido" OF oDlg1 PIXEL SIZE 60,12   
   @ 65 ,70 CHECKBOX oGet[6] VAR lFacturados PROMPT "Incluye Facturados" OF oDlg1 PIXEL SIZE 90,12   
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
    oQry := oApp:oServer:Query("SELECT SUM(p.cantidad) AS cantidad, SUM(p.punitario * p.cantidad * (1-p.descup/100)) as importe, "+;                         
                         " p.detart, p.codart "+;                         
                         " FROM ge_"+oApp:cId+"pedidos_det p "+;                         
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_encab p1 ON p1.id = p.idpedido "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         IF(lFacturados," AND p1.estado IN ('P','F') "," AND p1.estado = 'P' ")+;
                         IF(mcliente = 0,""," AND p1.codcli = "+str(mcliente))+;
                         IF(mvendedor = 0,""," AND p1.vendedor = "+ClipValue2Sql(mnomven))+;
                         " GROUP BY p.codart,p.detart ")
    REPORT oRep TITLE IF(!lFacturados,"Pedidos Pendientes","Todos los Pedidos") + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           IF(!lFacturados,"Pedidos Pendientes","Todos los Pedidos") CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  IF(!lFacturados,"Pedidos Pendientes","Todos los Pedidos")

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
                         "c.nombre,c.codigo as codcli, c.direccion as direccion, "+;
                         " c.localidad as localidad, p1.vendedor as vendedor, "+;
                         " p1.observa,p.cantidad*p.punitario*(1+p.descup/100) as importe "+;                         
                         " FROM ge_"+oApp:cId+"pedidos_encab p1 "+;
                         " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p1.codcli "+;
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_det p ON p.idpedido = p1.id "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         IF(lFacturados," AND p1.estado IN ('P','F') "," AND p1.estado = 'P' ")+;
                         IF(mcliente = 0,""," AND p1.codcli = "+str(mcliente))+;
                         IF(mvendedor = 0,""," AND p1.vendedor = "+ClipValue2Sql(mnomven))+;
                         " ORDER BY p1.id,p.codart ")
    REPORT oRep TITLE IF(!lFacturados,"Pedidos Pendientes (Detalle) ","Todos los Pedidos (Detalle) ") + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           IF(!lFacturados,"Pedidos Pendientes","Todos los Pedidos") CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  IF(!lFacturados,"Pedidos Pendientes (Detalle) ","Todos los Pedidos (Detalle) ")
    GROUP oGru ON oQry:id HEADER "Cliente: "+ALLTRIM(STR(oQry:codcli))+" "+ALLTRIM(oQry:nombre) + " "+;
          ALLTRIM(oQry:observa) + " ("+ ALLTRIM(oQry:direccion)+" "+ALlTRIM(oQry:localidad)+")"+;
          IF(!Empty(oQry:vendedor)," Vendedor:"+ALLTRIM(oQry:vendedor),"") FOOTER "Totales Cliente"  FONT 3
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

//***************************************************** ANTICIPOS ************************************
//**** SERIAN LAS SEÑAS QUE DEJA EL CLIENTE POR EL PEDIDO ********************************************


STATIC FUNCTION GenAnticipo(nCli,oGet)
LOCAL oDlgC, oBot1:=ARRAY(27), oGet1:=ARRAY(3), oError, oBrwPag, nMonto:= 0,oFontF,;
      nVueltoT:=0, nPagadoT:=0,lRta:=.f.,;
      nEfecti, nTransf, nCheque, nTarjet, nMPago, oQryPag, oQryPagCon, nRecibo, base, oErr
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS formapag_temp";
    +"("; 
    +"`RENGLON`   INT(2) NOT NULL  AUTO_INCREMENT ,";
    +"`TIPOPAG`   INT(1) NOT NULL ,";
    +"`FORMAPAG`  VARCHAR(30) NOT NULL,";
    +"`CODFORMA`  INT(2) NOT NULL,";
    +"`IMPORTE`  DECIMAL(12,2) NOT NULL,"+;
    +" PRIMARY KEY (RENGLON)) ENGINE=INNODB DEFAULT CHARSET=utf8")  
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE formapag_temp")
oApp:oServer:NextResult()
oQryPag:= oApp:oServer:Query("SELECT * FROM formapag_temp")
DEFINE FONT oFontF NAME "ARIAL" SIZE 14,-17
DEFINE DIALOG oDlgC RESOURCE "FORMAPAGT" OF oGet
  oDlgC:lHelpIcon := .f.
    
     REDEFINE XBROWSE oBrwPag DATASOURCE oQryPag;
            COLUMNS "FormaPag","Importe";
            HEADERS "Forma de pago","Importe";
            FOOTERS ;
            SIZES 150,89 ID 500 OF oDlgC
   PintaBrw(oBrwPag,0)
   oBrwPag:aCols[2]:nFooterTypE := AGGR_SUM
   oBrwPag:MakeTotals()

   REDEFINE BTNBMP oBot1[01] OF oDlgC ID 201 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[01],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[02] OF oDlgC ID 202 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[02],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[03] OF oDlgC ID 203 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[03],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[04] OF oDlgC ID 204 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[04],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[05] OF oDlgC ID 205 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[05],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[06] OF oDlgC ID 206 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[06],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[07] OF oDlgC ID 207 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[07],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[08] OF oDlgC ID 208 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[08],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[09] OF oDlgC ID 209 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[09],oBrwPag,oQryPag,oGet1[1]),oGet1[01]:SetFocus())
   REDEFINE BTNBMP oBot1[10] OF oDlgC ID 210 2007 CENTER WHEN(nMonto > 0);
            ACTION(AgregarConcepto(oBot1[10],oBrwPag,oQryPag,oGet1[1],nCli),oGet1[01]:SetFocus())


   REDEFINE BTNBMP oBot1[13] ID 300 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[14] ID 301 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[15] ID 302 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[16] ID 303 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[17] ID 304 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[18] ID 305 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[19] ID 306 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[20] ID 307 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11)) 
   REDEFINE BTNBMP oBot1[21] ID 308 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[22] ID 309 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],::nId-300,11))
   REDEFINE BTNBMP oBot1[23] ID 310 OF oDlgC 2007 CENTER;
                   ACTION(CargarNum(oGet1[1],0,11),CargarNum(oGet1[1],0,11))
   REDEFINE BTNBMP oBot1[24] ID 311 OF oDlgC 2007 CENTER;
                   ACTION(BorrarNum(oGet1[1]))
   

   REDEFINE GET oGet1[1] VAR nMonto ID 101 OF oDlgC PICTURE "99999999.99" FONT oFontF
   REDEFINE GET oGet1[2] VAR nVueltoT ID 102 OF oDlgC PICTURE "99999999.99" FONT oFontF;
                WHEN((oGet1[2]:cText:= nTotal-oBrwPag:aCols[2]:nTotal) = "xxx")
   REDEFINE GET oGet1[3] VAR nTotal ID 103 OF oDlgC PICTURE "99999999.99" WHEN(.F.) FONT oFontF

   REDEFINE GROUP oBot1[25] ID 100 PROMPT "Resto" OF oDlgC 
   
   REDEFINE BTNBMP oBot1[26] ID 401 OF oDlgC PROMPT "Aceptar [F12]" 2007 CENTER ACTION(lRta:=.t.,oDlgC:End())
   *REDEFINE BTNBMP oBot[26] ID 402 OF oDlgC 2007 CENTER ACTION(lRta:=.f.,oDlgC:End()) 
   REDEFINE BTNBMP oBot1[27] ID 403 OF oDlgC 2007 CENTER ;
                   ACTION(oQryPag:Delete(),oBrwPag:Refresh(),oBrwPag:MakeTotals(),;
                          oGet1[1]:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)) WHEN(oQryPag:RecCount() > 0)
   oDlgC:bKeyDown = { | nKey, nFlags | IF(nKey==113,oBot1[01]:Click,;
                                       IF(nKey==114,oBot1[02]:Click,;
                                       IF(nKey==115,oBot1[03]:Click,;
                                       IF(nKey==123,oBot1[26]:Click,.F.))))}
ACTIVATE DIALOG oDlgC CENTER ON INIT (PoneFormas(oBot1)) VALID ((nPagadoT:=oBrwPag:aCols[2]:nTotal) >=0)
IF !lRta .or. oBrwPag:aCols[2]:nTotal == 0
    RETURN nil 
ENDIF
IF !MsgNoYes("Seguro de generar la seña?","Atencion")
   RETURN nil 
ENDIF
nEfecti:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 1"):monto
nTransf:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 2"):monto
nCheque:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 3"):monto
nTarjet:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 4"):monto
nMPago:= oApp:oServer:Query("SELECT SUM(importe) AS monto FROM formapag_temp WHERE tipopag = 6"):monto
oQryPag    := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagos LIMIT 0")
oQryPagCon := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"pagcon LIMIT 0")
nRecibo :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
 TRY 
  oApp:oServer:BeginTransaction()
          

  // Grabo el pago si no es todo Cuenta Corriente
  //1 - GRABACION DE PAGO -------------------------------------------------------------------
  nRecibo :=  oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"pagos")
  // Grabo el registro de PAGOS
  base := oQryPag:GetBlankRow()
  base:numero  := nRecibo
  base:cliente := nCli
  base:total   := nEfecti + nTarjet + nCheque + nTransf + nMPago
  base:fecha   := DATE()
  base:caja    := oApp:prefijo
  base:usuario := oApp:usuario
  base:fecmod  := DATE()
  base:ip      := oApp:cIp
  base:interes := 0
  oQryPag:oRow := base
  oQryPag:Save()
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"pagcon (numero,codcon,tipocon,importe,observa) "+;
                       "(SELECT "+ClipValue2Sql(nRecibo)+",codforma,IF(tipopag=6,8,tipopag),"+;
                       "importe,formapag"+;
                       " FROM formapag_temp)")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"clientes SET saldo = saldo + "+ClipValue2Sql(base:total) + " WHERE codigo = "+STR(ncli))
  oApp:oServer:CommitTransaction()
CATCH oErr
  MsgStop("Error al grabar"+CHR(10)+oErr:description,"Error")
  oApp:oServer:RollBack()
  RETURN .F.
END TRY
oGet:cText := VAL(oGet:cText) - oBrwPag:aCols[2]:nTotal
Reci(nRecibo)
RETURN nil  

********************************************************************************************
*********
STATIC FUNCTION AgregarConcepto(oBoton,oBrwPag,oQryPag,oGet1,nCliente)
LOCAL nRenglon
IF oBoton:nLastRow = 5 .and. nCliente < 2
   MsgStop("Consumidor final no puede pagar en Cta.Cte.","Error")
   RETURN nil 
ENDIF
nRenglon:= oApp:oServer:GetAutoIncrement("formapag_temp")
oApp:oServer:Execute("INSERT INTO formapag_temp (RENGLON,CODFORMA,TIPOPAG,FORMAPAG,IMPORTE) VALUES "+;
                     "("+ClipValue2Sql(nRenglon)+","+ClipValue2Sql(oBoton:cargo)+","+ClipValue2Sql(oBoton:nLastRow)+","+;
                      ClipValue2Sql(LEFT(oBoton:cCaption,LEN(oBoton:cCaption)-4))+","+ClipValue2Sql(oGet1:value)+")")
oQryPag:Refresh()
oBrwPag:Refresh()
oBrwPag:MakeTotals()
oGet1:cText:= IF((nTotal-oBrwPag:aCols[2]:nTotal) > 0,nTotal-oBrwPag:aCols[2]:nTotal,0)
RETURN nil


***************************************************************************************
**********
STATIC FUNCTION PoneFormas(oBot1)
LOCAL oQryForPag,i, cF
oQryForPag:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"forpag WHERE tactil = TRUE ORDER BY codigo")
oQryForPag:GoTop()
FOR i:= 1 TO 10
       cF := IF(i<5 .and. !oQryForPag:Eof(),'[F'+STR(i+1,1)+']','    ')
       oBot1[i]:cCaption:= IF(oQryForPag:Eof()," ",ALLTRIM(oQryForPag:nombre)+cF)
       oBot1[i]:cargo:= IF(oQryForPag:Eof(),0,oQryForPag:codigo)
       oBot1[i]:nLastRow:= IF(oQryForPag:Eof(),0,oQryForPag:tipo)
       oBot1[i]:Refresh()
       IF oQryForPag:Eof()
          oBot1[i]:Hide()
       ENDIF 
       oQryForPag:Skip()
    NEXT i
RETURN nil


**************************************************************************************
***** CARGAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION CargarNum(oGet,nNum,nPict,lString)
LOCAL cTexto,lTienePunto:="."$oGet:cText
DEFAULT lString:=.f.

IF lString 
IF lReemplaza
  oGet:cText:=SPACE(nPict)
  lReemplaza:= .f.
ENDIF
   cTexto:=oGet:cText
   cTexto := cTexto + STR(nNum,1)
   oGet:cText:= cTexto
ELSE
  IF lReemplaza
     oGet:cText:=0
     lReemplaza:= .f.
  ENDIF
  IF LEN(ALLTRIM(oGet:cText)) = nPict
   RETURN nil
  ENDIF
  cTexto:= ALLTRIM(STR(oGet:Value,nPict,IF(lTienePunto,2,0))) 
  cTexto:= strtran(cTexto,".","")
  cTexto := cTexto + STR(nNum,1)
  IF !lTienePunto
     oGet:cText:= VAL(cTexto)
  ELSE
    oGet:cText:= VAL(cTexto) / 100
  ENDIF

ENDIF
RETURN nil
***************************************************************************************
***** BORRAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION BorrarNum(oGet,lString)
LOCAL cTexto,lTienePunto:="."$oGet:cText
DEFAULT lString:=.f.
cTexto:= strtran(oGet:cText,".","")
cTexto := LEFT(cTexto,LEN(cTexto)-1)
IF !lTienePunto
     oGet:cText:= VAL(cTexto)
  ELSE
    oGet:cText:= VAL(cTexto) / 100
ENDIF
RETURN nil


STATIC FUNCTION validarqueexista()

IF !oApp:oServer:TableExist('ge_'+oApp:cId+"pedidos_encab")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"pedidos_encab ( "+;
  "`id` INT(10) NOT NULL AUTO_INCREMENT,"+;
  "`codcli` INT(6) NOT NULL,"+;
  "`cliente` VARCHAR(40) DEFAULT NULL,"+;
  "`codven` INT(4) NOT NULL,"+;
  "`vendedor` VARCHAR(40) DEFAULT NULL,"+;
  "`fecha` DATE DEFAULT NULL,"+;
  "`parafecha` DATE DEFAULT NULL,"+;
  "`estado` VARCHAR(1) DEFAULT NULL,"+;
  "`facturanro` VARCHAR(16) DEFAULT NULL,"+;
  "`observa` VARCHAR(200) DEFAULT NULL,"+;
  "`orden` INT(10) DEFAULT '0',"+;
  "`nuevo` TINYINT(1) DEFAULT '0',"+;
  "PRIMARY KEY (`id`),"+;
  "KEY `orden` (`orden`)"+;
") ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8")

oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"pedidos_det ("+;
  "`id` INT(10) NOT NULL AUTO_INCREMENT,"+;
  "`idpedido` INT(10) NOT NULL,"+;
  "`codart` bigint(14) NOT NULL,"+;
  "`detart` VARCHAR(80) NOT NULL,"+;
  "`cantidad` DECIMAL(10,2) NOT NULL,"+;
  "`cantidadreal` DECIMAL(10,2) NOT NULL,"+;
  "`punitario` DECIMAL(12,3) DEFAULT NULL,"+;
  "`renglon` INT(10) NOT NULL DEFAULT '0',"+;
  "`descu` DECIMAL(12,2) DEFAULT NULL,"+;
  "`descup` DECIMAL(5,2) DEFAULT NULL,"+;
  "PRIMARY KEY (`id`),"+;
  "KEY `idpedido` (`idpedido`),"+;
  "CONSTRAINT `pedidos_det_"+oApp:cId+"ibfk_1` FOREIGN KEY (`idpedido`) REFERENCES `ge_"+oApp:cId+"pedidos_encab` (`id`) ON DELETE CASCADE"+;
") ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8")
ENDIF
RETURN nil 

***********************************
** Reporte de pedidos por Articulo
STATIC FUNCTION ReporPedArt()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,oGru,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(3), oBot1, oBot2, oBot3, ;
      mdesde := DATE(), mhasta := DATE(), mtotal := 0, lResu := .t., cWhere := "1=1"
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte de Pedidos Por articulos" FROM 03,15 TO 13,50 Of oApp:oWnd
   acor := AcepCanc(oDlg1)    
   @ 07, 01 SAY "Para Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 22, 01 SAY "Hasta Fecha:" OF oDlg1 PIXEL SIZE 60,10 RIGHT 
   @ 05, 65 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 65 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde) 
   @ 35 ,65 CHECKBOX oGet[3] VAR lResu PROMPT "Resumido" OF oDlg1 PIXEL SIZE 90,12  
   @ 35 ,05 BUTTON oBot3 PROMPT "&Filtrar"  OF oDlg1 SIZE 30,10 ;
           ACTION (cWhere := FiltraArt()) PIXEL
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
    oQry := oApp:oServer:Query("SELECT SUM(p.cantidad) AS cantidad, SUM(p.punitario * p.cantidad*(1+p.descup/100)) as importe, "+;                         
                         " p.detart, p.codart"+;                         
                         " FROM ge_"+oApp:cId+"pedidos_det p "+;                         
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_encab p1 ON p1.id = p.idpedido "+;
                         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         " AND p1.estado = 'P' "+;
                         " AND "+cWhere+;
                         " GROUP BY p.codart,p.detart ")
    REPORT oRep TITLE "Articulos Pedidos Pendientes" + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Articulos Pedidos Pendientes" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Articulos Pedidos Pendientes"

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
                         "c.nombre,c.codigo as codcli, p1.observa,p.cantidad*p.punitario*(1+p.descup/100) as importe "+;                         
                         " FROM ge_"+oApp:cId+"pedidos_encab p1 "+;
                         " LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = p1.codcli "+;
                         " LEFT JOIN ge_"+oApp:cId+"pedidos_det p ON p.idpedido = p1.id "+;
                         " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                         " WHERE p1.parafecha >= " + ClipValue2Sql(mdesde) + " AND "+;
                         " p1.parafecha <= "+ ClipValue2Sql(mhasta) +;
                         " AND p1.estado = 'P' "+;
                         " AND "+cWhere+;
                         " ORDER BY p1.id,p.codart ")
    REPORT oRep TITLE "Articulos Pedidos Pendientes (Detalle) " + ;
                      " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
           FONT  oFont1,oFont2,oFont3 ;
           HEADER OemToAnsi(oApp:nomb_emp) , ;
           "Articulos Pedidos Pendientes" CENTER ;
           FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
           PREVIEW CAPTION  "Articulos Pedidos Pendientes (Detalle) "
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



**************************************************************************************************************
****** FILTRAR ARTICULOS
STATIC FUNCTION FiltraArt()
   
LOCAL vMarca,cMarc:=SPACE(30),vRubro,cRub:=SPACE(30),vempresa,cEmp:=SPACE(30),;
      vdepto,cDept:=SPACE(30),vProv,cProve:=SPACE(30),vcodigo,cNomArt:=SPACE(30),vnosale:=.f.,;
      vnombre:=SPACE(30),vnomregi:=SPACE(30),vstockmin,vstockact,vstockide,;
      vpreciocos,viva,cNomIva:=SPACE(30),vdesc1,vdesc2,vdesc3,vdesc4,vdesc5,;
      vprecioven,vpresugeri,vprecossiva,vpreciopro,vporcentaje,vfecmodd:="  /  /    ",vfecmodh:="  /  /    ",;
      vfecultcomd:="  /  /    ",vfecultcomh:="  /  /    ",oSay1,oSay2,;
      vneto,vimpint,vflete,vunimed,vobserva,cIvaNom:=SPACE(30),;
      oFilt, acor:=ARRAY(4), oBot:=ARRAY(2), lRta:=.f., oGet:=ARRAY(50),;
      vpesable:=.f.,vcombustible:=.f.,vmprima:=.f.,vproduccion:=.f.,;
      vmedida,ventero,vuxbulto,vpxbulto,vsiniva:=.f.,  oError, cWhere, ;
      oQry2, oQry3, oQry4, oQry5, oQry6, oQry7

   oQry2  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"empresas ORDER BY codigo")


  DEFINE DIALOG oFilt TITLE "Seleccion de articulos" RESOURCE "ABMART1" OF oDlg 
  oFilt:lHelpIcon := .f.
  REDEFINE GET oGet[01] VAR vcodigo ID 100 OF oFilt/* PICTURE "99999999999999" ;
               VALID(EMPTY(oGet[01]:cText) .or. Buscar(oQryArt,oFilt,oGet[01],oGet[02]));
              ACTION (oGet[01]:cText:= 0, Buscar(oQryArt,oFilt,oGet[01],oGet[02])) BITMAP "BUSC1"*/
  REDEFINE GET oGet[02] VAR vnombre PICTURE "@!" ID 101 OF oFilt 
  REDEFINE GET oGet[03] VAR vnomregi ID 102 OF oFilt 
  REDEFINE CHECKBOX oGet[34] VAR vnosale ID 103 
  REDEFINE CHECKBOX oGet[46] VAR vpesable ID 4011 OF oFilt 
  *REDEFINE CHECKBOX oGet[43] VAR vcombustible ID 4005 OF oFilt
  *REDEFINE CHECKBOX oGet[44] VAR vmprima      ID 4007 OF oFilt
  *REDEFINE CHECKBOX oGet[45] VAR vproduccion  ID 4008 OF oFilt

  REDEFINE GET oGet[04] VAR vprov ID 104 OF oFilt ;
               VALID(EMPTY(oGet[04]:cText) .or. Buscar(oQry2,oFilt,oGet[04],oGet[05]));
               ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oFilt,oGet[04],oGet[05])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[21] VAR vmarca ID 122 OF oFilt ;
               VALID(EMPTY(oGet[21]:cText) .or. Buscar(oQry4,oFilt,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oFilt,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc      ID 123 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[23] VAR vrubro ID 124 OF oFilt ;
               VALID(EMPTY(oGet[23]:cText) .or. Buscar(oQry5,oFilt,oGet[23],oGet[24]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oFilt,oGet[23],oGet[24])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub ID 125 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[27] VAR vempresa ID 126 OF oFilt ;
               VALID(EMPTY(oGet[27]:cText) .or. Buscar(oQry7,oFilt,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oFilt,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp ID 127 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[25] VAR vdepto ID 128 OF oFilt ;
               VALID(EMPTY(oGet[25]:cText) .or. Buscar(oQry6,oFilt,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oFilt,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept ID 129 OF oFilt WHEN (.F.)

  
  REDEFINE GET oGet[35] VAR vunimed     ID 135 OF oFilt PICTURE "@!"
  REDEFINE GET oGet[47] VAR vmedida     ID 500 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[48] VAR ventero     ID 501 OF oFilt PICTURE "9999999"
  REDEFINE GET oGet[49] VAR vuxbulto    ID 502 OF oFilt PICTURE "99999"
  REDEFINE GET oGet[50] VAR vpxbulto    ID 503 OF oFilt PICTURE "99999999.99"


  REDEFINE CHECKBOX oGet[46] VAR vsiniva  ID 4003 OF oFilt
  REDEFINE GET oGet[06] VAR vprecossiva ID 106 OF oFilt 
  REDEFINE GET oGet[07] VAR vdesc1      ID 107 OF oFilt 
  REDEFINE GET oGet[08] VAR vdesc2      ID 108 OF oFilt 
  REDEFINE GET oGet[09] VAR vdesc3      ID 109 OF oFilt 
  REDEFINE GET oGet[10] VAR vdesc4      ID 110 OF oFilt 
  REDEFINE GET oGet[11] VAR vdesc5      ID 111 OF oFilt 
  REDEFINE GET oGet[39] VAR vNeto ID 112 OF oFilt 
  REDEFINE GET oGet[12] VAR vimpint ID 113 OF oFilt 
  REDEFINE GET oGet[13] VAR vflete ID 114 OF oFilt 
  REDEFINE GET oGet[14] VAR viva ID 115 OF oFilt ;
              VALID(EMPTY(oGet[14]:cText) .or. (Buscar(oQry3,oFilt,oGet[14],oGet[15]) .and. ;             
               ((oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx"))  );
               ACTION (oGet[14]:cText:= 0, Buscar(oQry3,oFilt,oGet[14],oGet[15]),;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx" ) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom ID 116 OF oFilt WHEN (.F.)
  REDEFINE GET oGet[16] VAR vpreciocos ID 117 OF oFilt 
  REDEFINE GET oGet[17] VAR vporcentaje ID 118 OF oFilt 
  REDEFINE GET oGet[18] VAR vpreciopro ID 119 OF oFilt 
  REDEFINE GET oGet[19] VAR vpresugeri ID 120 OF oFilt 
  REDEFINE GET oGet[20] VAR vprecioven ID 121 OF oFilt 
  

  //FECHAS
  REDEFINE GET oGet[41] VAR vfecultcomd ID 1300 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay1 PROMPT "Hasta ultima compra:" ID 802 OF oFilt
  REDEFINE GET oGet[29] VAR vfecultcomh ID 130 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay2 PROMPT "Desde cambio precio:" ID 803 OF oFilt
  REDEFINE GET oGet[30] VAR vfecmodd    ID 131 OF oFilt PICTURE "@D"
  REDEFINE GET oGet[42] VAR vfecmodh    ID 1311 OF oFilt PICTURE "@D"

  REDEFINE GET oGet[31] VAR vstockmin ID 132 OF oFilt
  REDEFINE GET oGet[32] VAR vstockact ID 133 OF oFilt
  REDEFINE GET oGet[33] VAR vstockide ID 134 OF oFilt
  REDEFINE GET oGet[36] VAR vobserva  ID 136 OF oFilt

  REDEFINE BUTTON oBot[1] ID 137 OF oFilt;
           ACTION ((lRta := .t.), oFilt:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oFilt;
           ACTION ((lRta := .f.), oFilt:End() ) CANCEL
 
ACTIVATE DIALOG oFilt CENTER ON INIT (oGet[01]:SetFocus(),oGet[34]:Hide())

IF !lRta
   RETURN "1=1"
ENDIF

cWhere = " 1=1 " + IF(EMPTY(vCodigo),""," and a.CODIGO =" + ClipValue2SQL(VCodigo) + "") ;
            + "" + IF(EMPTY(VNOMBRE),"","  and TRIM(a.NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
            + "" + IF(EMPTY(Vnomregi),"","  and TRIM(a.nomregi) like '%" + ALLTRIM(Vnomregi) + "%'") ;
            + "" + IF(!vnosale,""," and a.nosale = TRUE ");
            + "" + IF(!vpesable,""," and a.pesable = TRUE ");
            + "" + IF(!vcombustible,""," and a.combustible = TRUE");
            + "" + IF(!vmprima,""," and a.mprima = TRUE ");
            + "" + IF(!vproduccion,""," and a.produccion = TRUE ");
            + "" + IF(!vsiniva,""," and a.siniva = TRUE ");
            + "" + IF(EMPTY(vProv),""," and a.prov =" + ClipValue2SQL(vProv) + "") ;
            + "" + IF(EMPTY(vMarca),""," and a.marca =" + ClipValue2SQL(vMarca) + "") ;
            + "" + IF(EMPTY(vRubro),""," and a.rubro =" + ClipValue2SQL(vRubro) + "") ;
            + "" + IF(EMPTY(vempresa),""," and a.empresa =" + ClipValue2SQL(vempresa) + "") ;
            + "" + IF(EMPTY(vdepto),""," and a.depto =" + ClipValue2SQL(vdepto) + "") ;
            + "" + IF(EMPTY(vStockmin),""," and a.stockmin =" + ClipValue2SQL(vstockmin) + "") ; 
            + "" + IF(EMPTY(vmedida),""," and a.medida =" + ClipValue2SQL(vmedida) + "") ;
            + "" + IF(EMPTY(ventero),""," and a.entero =" + ClipValue2SQL(ventero) + "") ;
            + "" + IF(EMPTY(vuxbulto),""," and a.uxbulto =" + ClipValue2SQL(vuxbulto) + "") ;
            + "" + IF(EMPTY(vpxbulto),""," and a.pxbulto =" + ClipValue2SQL(vpxbulto) + "") ;
            + "" + IF(EMPTY(vStockact),""," and a.stockact =" + ClipValue2SQL(vstockact) + "") ;
            + "" + IF(EMPTY(vstockide),""," and a.stockide =" + ClipValue2SQL(vstockide) + "") ;
            + "" + IF(EMPTY(vunimed),"","  and TRIM(a.unimed) like '%" + ALLTRIM(vunimed) + "%'");
            + "" + IF(EMPTY(vpreciocos),""," and a.preciocos =" + ClipValue2SQL(vpreciocos) + "") ;
            + "" + IF(EMPTY(vporcentaje),""," and a.porcentaje =" + ClipValue2SQL(vporcentaje) + "") ;
            + "" + IF(EMPTY(vprecossiva),""," and a.precossiva =" + ClipValue2SQL(vprecossiva) + "") ;
            + "" + IF(EMPTY(vneto),""," and a.neto =" + ClipValue2SQL(vneto) + "") ;
            + "" + IF(EMPTY(vimpint),""," and a.impint =" + ClipValue2SQL(vimpint) + "") ;
            + "" + IF(EMPTY(vflete),""," and a.flete =" + ClipValue2SQL(vflete) + "") ;
            + "" + IF(EMPTY(viva),""," and a.iva =" + ClipValue2SQL(viva) + "") ;
            + "" + IF(EMPTY(vdesc1),""," and a.desc1 =" + ClipValue2SQL(vdesc1) + "") ;
            + "" + IF(EMPTY(vdesc2),""," and a.desc2 =" + ClipValue2SQL(vdesc2) + "") ;
            + "" + IF(EMPTY(vdesc3),""," and a.desc3 =" + ClipValue2SQL(vdesc3) + "") ;
            + "" + IF(EMPTY(vdesc4),""," and a.desc4 =" + ClipValue2SQL(vdesc4) + "") ;
            + "" + IF(EMPTY(vdesc5),""," and a.desc5 =" + ClipValue2SQL(vdesc5) + "") ;            
            + "" + IF(EMPTY(vprecioven),""," and a.precioven =" + ClipValue2SQL(vprecioven) + "") ;
            + "" + IF(EMPTY(vpreciopro),""," and a.preciopro =" + ClipValue2SQL(vpreciopro) + "") ; 
            + "" + IF(EMPTY(vpresugeri),""," and a.presugeri =" + ClipValue2SQL(vpresugeri) + "") ; 
            + "" + IF(vfecultcomd="  /  /    ",""," and a.fecultcom >=" + ClipValue2SQL(CTOD(vfecultcomd)) + "") ;
            + "" + IF(vfecultcomh="  /  /    ",""," and a.fecultcom <=" + ClipValue2SQL(CTOD(vfecultcomh)) + "") ;
            + "" + IF(vfecmodd="  /  /    ",""," and a.fecmod >=" + ClipValue2SQL(CTOD(vfecmodd)) + "") ;
            + "" + IF(vfecmodh="  /  /    ",""," and a.fecmod <=" + ClipValue2SQL(CTOD(vfecmodh)) + "") ;
            + "" + IF(EMPTY(vobserva),"","  and TRIM(a.observa) like '%" + ALLTRIM(vobserva) + "%'") ;
 

RETURN cWhere