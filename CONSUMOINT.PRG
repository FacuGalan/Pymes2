#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "report.ch"
*************************************************
** Consumo Interno
*************************************************
MEMVAR oApp
STATIC oFont,oForm,oGet,oBrw1,oBrw2,oQryDet1,oQryDet2,oTimer,;
       nDocenasN,nCantN,nCantTotN,nImporte1,cPrecio,;
       nDocenasE,nCantE,nCantTotE,nImporte2,;
       nCant3,nImporte3,nImporteTot,oQryDatos,;
       oQryBrw,oQry,oWnd1,cVentana,oBrw,oDlg,oQryPag,lCobrados,;
       oBot,fDepto,nTotal,nUltDep,nPriDep,nUltArt,nPriArt,nCantidad,cMozo,;
       oBrwDet,oQryDet,oDlg1,oQryArt,dFecha,oQryDep,nDescuentoP,nMotivoDesc,nUsaBeeper,oGetP,nTipoFac,nTipoDoc, cPermi

PROCEDURE ConsuInt(cPermisos)
LOCAL  cBuscar := SPACE(50), oBar, hHand, oFol, oMen, nOpt := 1
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
cPermi := cPermisos   
oBot:=ARRAY(71)
nTipoFac:=1
nTipoDoc:=1
nDescuentoP:=0
nMotivoDesc:=0
nUsaBeeper:=0
AADD(oApp:aVentanas,cVentana)
   CursorWait()
   oQryBrw:= oApp:oServer:Query("SELECT c.*, e.nombre AS nombre " +; 
                                " FROM ge_"+oApp:cId+"emp_consumoint c" +;
                                " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON e.codigo = c.codemp "+;
                                " WHERE c.fecha > CURDATE() -30 ")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Consumo Interno" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Consu( cPermisos ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Consumo Interno",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "PAGO" OF oBar ;
            TOOLTIP "Marcar como liquidado"  ;
            ACTION (Liquidado(),oQryBrw:Refresh(),oBrw:Refresh());
            PROMPT "Liquidar" TOP WHEN(oQryBrw:RecCount()>0 .AND. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Registros"  ;
            ACTION (Filt(), oBrw:Refresh());
            PROMPT "Filtrar" TOP    
        // Este boton cierra la aplicacion            
            // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
              COLUMNS "nombre","fecha","nomart","punit","cantidad","ptotal",'usuario','liquidado';
              HEADERS "Empleado","Fecha","Producto","P.Unitario","Cantidad","Total",'Cargo','Liquidado';
              FOOTERS;
              SIZES   180,70,180,70,60,80,80,80;
             ID 111 OF oDlg AUTOSORT ON DBLCLICK (Formu( .f.),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT oBrw:cSeek ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[6]:nFooterType := AGGR_SUM     
     oBrw:aCols[8]:bEditValue := {|| IF( oQryBrw:liquidado, .t., .f. )  }
     oBrw:aCols[8]:SetCheck(,.t.) 
     PintaBrw(oBrw,8)
     oBrw:Maketotals()
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0)    VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

*****************************************************************************
*****************************************************************************
STATIC FUNCTION Formu (lAlta)

RETURN nil


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
LOCAL aNueva := {}, i, j
IF oQry <> nil
   oQry:End()
ENDIF  

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
LOCAL mrta := .f., oError, oQryStock,cDet

mrta := MsgNoYes("Seguro de eliminar el consumo interno?","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  //Subo el stock primero  

  oApp:oServer:Execute("UPDATE (SELECT codart,cantidad FROM ge_"+oApp:cId+"emp_consumoint WHERE id = "+ClipValue2Sql(oQryBrw:id)+;
                            ") d LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                           "SET a.stockact = a.stockact + d.cantidad WHERE a.stockotro IS FALSE ")


  oQryStock:= oApp:oServer:Query("SELECT d1.cantidad as cantidad,d1.codart AS codart FROM ge_"+oApp:cId+"emp_consumoint d1 "+;
                                     "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d1.codart "+;
                                     "WHERE a.stockotro = TRUE AND d1.id = "+ClipValue2Sql(oQryBrw:id))

  oQryStock:GoTop()
  DO WHILE !oQryStock:EOF()
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                          " ON m.codigo = r.codusa "+;
                          "SET m.stockact = m.stockact + (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                          "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
      oQryStock:Skip()
  ENDDO
  cDet := " "+ALLTRIM(oQryBrw:nombre)+" $"+STR(oQryBrw:ptotal)+" "+ALLTRIM(oQryBrw:nomart)
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"emp_consumoint WHERE id = "+ClipValue2Sql(oQryBrw:id))  
  *Auditar(14,,,cDet)                       
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
oQryBrw:Refresh()
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil 

******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEmp := 0
LOCAL oGet1, oGet2, oGet3, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, oQryEmp := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado")


DEFINE DIALOG oDlg1 TITLE "FILTRADO de Consumos" FROM 05,10 TO 14,60 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha Vto:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha Vto:"    OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Empleado (0:Todos):" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 GET oGet3 VAR nEmp  PIXEL PICTURE "999999"     RIGHT;
   VALID(nEmp = 0 .or. buscar(oQryEmp, oDlg1, oGet3));
     ACTION (oGet3:cText := -1,buscar(oQryEmp, oDlg1, oGet3)) BITMAP "BUSC1" SIZE 30,12
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " c.fecha >=" + ClipValue2SQL(vdesde) +;
      + "  and c.fecha <= " + ClipValue2SQL(vhasta) ;
      + "  and " + IF(nEmp = 0," TRUE ", " c.codemp = " + ClipValue2SQL(nEmp))
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil



STATIC FUNCTION Consu(cPermisos)
LOCAL i,oFont1,oFont2,oFont3,oFont4,nCodArt:=0,oQryPedido, oRes,base,nCodEmp:=0, cNomEmp := SPACE(30),;
      acor:=ARRAY(4),lRta:=.f.,oError,oDlg,  oSay, oQryEmp, oDlg1, oQryStock, npicture,;
      cNomArt := SPACE(30), nPrecio := 0, nDescuTot := 0, nRecarTot := 0, nPagado := 0, nVuelto := 0,;
      lReemplaza := .f., nTotalAcum
oGet := ARRAY(12)
oQryEmp := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado WHERE inactivo IS FALSE")      

DEFINE DIALOG oDlg TITLE "Elegir Empleado" OF oWnd1 FROM 05,15 TO 13,55
   acor := AcepCanc(oDlg)
  

   @ 07,05 SAY "Legajo:"  OF oDlg PIXEL SIZE 30,12 RIGHT
   @ 22,05 SAY "Nombre:"  OF oDlg PIXEL SIZE 30,12 RIGHT
   
   @ 05,40 GET oGet[1] VAR nCodEmp OF oDlg PIXEL PICTURE "999999" SIZE 35,12 RIGHT;
               VALID(Buscar(oQryEmp,oDlg,oGet[01],oGet[02],'0','inactivo'));
               ACTION (oGet[01]:cText:= 0, Buscar(oQryEmp,oDlg,oGet[01],oGet[02],'0','inactivo')) BITMAP "BUSC1"
   @ 20,40 GET oGet[2] var cNomEmp OF oDlg PIXEL PICTURE "@!" WHEN(.F.)

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Aceptar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlg:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlg SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlg:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlg CENTER
IF !lRta
   RETURN .f.
ENDIF
nTotal := 0
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS detalle_consumo ";
    +"( `ORDEN` INT(2) AUTO_INCREMENT NOT NULL, ";
    +"`CANTIDAD` DECIMAL(5,2) NOT NULL,";    
    +"`CODART` BIGINT(14) NOT NULL,";
    +"`NOMART` VARCHAR(50) NOT NULL DEFAULT '',";
    +"`PUNIT` DECIMAL(12,2) NOT NULL DEFAULT 0,";    
    +"`PTOTAL` DECIMAL(12,2) NOT NULL DEFAULT 0,";
    +"PRIMARY KEY (`ORDEN`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()

 DEFINE FONT oFont1 NAME "TAHOMA" SIZE 0,-11.5
 DEFINE FONT oFont2 NAME "ARIAL" SIZE 17,-25
 DEFINE FONT oFont3 NAME "ARIAL" SIZE 15,-20
 DEFINE FONT oFont4 NAME "ARIAL" SIZE 0,-11.5

nUltDep:=0
nPriDep:=0
nUltArt:=0
nPriArt:=0
nCantidad:=1

oApp:oServer:Execute("TRUNCATE detalle_consumo")

oQryDet:= oApp:oServer:Query("SELECT * FROM detalle_consumo")

oQryArt:= oApp:oServer:Query("SELECT codigo,nombre,preciocos,precioven,stockact FROM ge_"+oApp:cId+"articu ")

IF oQryEmp:consumo_por = 1
    nDescuentoP := 0
    cPrecio := "preciocos"
    ELSE 
    nDescuentoP := oQryEmp:consumo_desc
    cPrecio := "precioven"
ENDIF  

DO WHILE .T.
lRta := .F.
DEFINE DIALOG oDlg1 RESOURCE "POS" OF oWnd1 TITLE "CONSUMO INTERNO"
   oDlg1:lHelpIcon := .f.
  
   REDEFINE BTNBMP oBot[30] ID 301 OF oDlg1 2007 CENTER; //ALTA DE ARTICULO
                   PROMPT "&Alta rapida";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[31] ID 302 OF oDlg1 2007 CENTER; //DESCUENTOS
                   PROMPT "&Descuentos";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[32] ID 303 OF oDlg1 2007 CENTER; //BORRA ITEM
                   PROMPT "&Borrar item [F2]";
                   ACTION(oQryDet:Delete(),oBrwDet:Refresh(),oBrwDet:MakeTotals(),oGet[6]:Refresh(),oGet[02]:SetFocus());
                   WHEN(oQryDet:RecCount()>0) 
   REDEFINE BTNBMP oBot[33] ID 304 OF oDlg1 2007 CENTER; //SELECCIONA CLIENTE
                   PROMPT "&Elegi cliente [F3]";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[34] ID 305 OF oDlg1 2007 CENTER; //SALIR
                   PROMPT "&Salir [Esc]";
                   ACTION(lRta := .f.,oDlg1:End())
   REDEFINE BTNBMP oBot[35] ID 306 OF oDlg1 2007 CENTER; //ELIJE FORMAS DE PAGO
                   PROMPT "&Pagar [F4]";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[36] ID 307 OF oDlg1 2007 CENTER; //CONSULTA
                   PROMPT "&Consulta";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[37] ID 308 OF oDlg1 2007 CENTER; //CALCULADORA
                   PROMPT "Departamen&tos [F5]";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[38] ID 309 OF oDlg1 2007 CENTER; //ANULAR
                   PROMPT "A&nular";
                   WHEN(.F.)
   REDEFINE BTNBMP oBot[39] ID 310 OF oDlg1 2007 CENTER; //GRABA
                   PROMPT "&Grabar [F12]";
                   ACTION(lRta := .t.,oDlg1:End());
                   WHEN(oBrwDet:aCols[5]:nTotal > 0)
   REDEFINE BTNBMP oBot[19] ID 4004 OF oDlg1 2007 CENTER; //GRABA
                   PROMPT "&Vales" WHEN(.f.)
  
   //BOTONES DE NUMEROS (DERECHA)
   REDEFINE BTNBMP oBot[40] ID 400 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[41] ID 401 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[42] ID 402 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[43] ID 403 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[44] ID 404 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[45] ID 405 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[46] ID 406 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[47] ID 407 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture)) 
   REDEFINE BTNBMP oBot[48] ID 408 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[49] ID 409 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,::nId-400,nPicture))
   REDEFINE BTNBMP oBot[50] ID 410 OF oDlg1 2007 CENTER;
                   ACTION(oGet[01]:SetFocus())
   REDEFINE BTNBMP oBot[51] ID 411 OF oDlg1 2007 CENTER;
                   ACTION(CargarNum(oDlg1:cargo,0,nPicture),CargarNum(oDlg1:cargo,0,nPicture))
   REDEFINE BTNBMP oBot[53] ID 413 OF oDlg1 2007 CENTER;
                   ACTION(IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[2]:nTop+oGet[2]:nLeft .and. oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE "+;
                                                                   "codigo = "+ClipValue2Sql(nCodArt)):RecCount>0,;
                            (AgregarArticu(nCodArt),oGet[02]:SetFocus()),; //SI ESTA PARADO EN EL CODIGO DE ARTICULO Y EXISTE LO AGREGO AL DETALLE
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[3]:nTop+oGet[3]:nLeft .and. nCodArt < 0 .and.;
                             oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"deptos WHERE codigo = "+ClipValue2Sql(ABS(nCodArt))):RecCount>0 ,;
                            (AgregarArticu(nCodArt),oGet[02]:SetFocus()),oGet[02]:SetFocus())),; //SI ESTA PARADO EN EL PRECIO E INGRESO UN DEPTO LO AGREGO AL DETALLE
                          IF(oDlg1:cargo:nTop+oDlg1:cargo:nLeft=oGet[1]:nTop+oGet[1]:nLeft,oGet[2]:SetFocus(),nil))  //SI ESTA EN CANTIDAD VUELVE AL CODIGO DEL ARTICULO   
   REDEFINE BTNBMP oBot[54] ID 414 OF oDlg1 2007 CENTER;
                   ACTION(BorrarNum(oDlg1:cargo))
   REDEFINE XBROWSE oBrwDet DATASOURCE oQryDet;
            COLUMNS "CODART","NOMART","CANTIDAD","PUNIT","PTOTAL";
            HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total";
            FOOTERS ;
            SIZES 100,243,65,64,64 ID 1000 OF oDlg1 WHEN(oQryDet:RecCount()>0)
   PintaBrw(oBrwDet,0)
   oBrwDet:aCols[3]:nFooterTypE := AGGR_SUM
   oBrwDet:aCols[5]:nFooterTypE := AGGR_SUM   
   oBrwDet:aCols[1]:Hide()
   oBrwDet:MakeTotals()  
    IF "M"$cPermisos
      oBrwDet:aCols[3]:nEditType := EDIT_GET
   ENDIF
   oBrwDet:aCols[3]:bOnPostEdit := { |oCol,xval,nkey| CambiaCant(xval,1)}  
   
   REDEFINE GET oGet[02] VAR nCodArt   ID 10 OF oDlg1 PICTURE "99999999999999" FONT oFont2;
                ACTION (oGet[02]:cText:= 0, BuscarArt(oQryArt,oDlg1,oGet[2],oGet[7],'0','nosale'),;
                        oGet[01]:cText:=1,oGet[03]:cText:=oQryArt:precioven) BITMAP "BUSC"
   REDEFINE GET oGet[07] VAR cNomArt   ID 16 OF oDlg1 PICTURE "@!" FONT oFont3 ;
                WHEN(IF(nCodArt>0,(oGet[07]:cText:= oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[2]:cText)):nombre) = "xxxxx",.f.))
   REDEFINE GET oGet[01] VAR nCantidad ID 11 OF oDlg1 PICTURE "9999" FONT oFont2 
   REDEFINE GET oGet[03] VAR nPrecio   ID 12 OF oDlg1 PICTURE "999999999.99" FONT oFont2;
                WHEN(oGet[02]:value <= 0 .or. ((oGet[03]:cText:= oApp:oServer:Query("SELECT "+cPrecio+" as precioven FROM ge_"+oApp:cId+"articu WHERE nosale is false and codigo = "+ClipValue2Sql(oGet[2]:cText);
                                                                                    ):precioven*nCantidad) <> "xxx")) 

   *REDEFINE COMBOBOX oGet[10] VAR nFormaPago ID 4002 OF oDlg ITEMS aFormaNom ON CHANGE (ActualizarDet(),oGet[02]:SetFocus())
   REDEFINE GET oGet[08] VAR nDescuTot ID 17 OF oDlg1 PICTURE "999999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[09] VAR nRecarTot ID 18 OF oDlg1 PICTURE "999999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[04] VAR nPagado   ID 13 OF oDlg1 PICTURE "999999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[05] VAR nVuelto   ID 14 OF oDlg1 PICTURE "999999999.99" FONT oFont3 WHEN(.F.)
   REDEFINE GET oGet[06] VAR nTotal    ID 15 OF oDlg1 PICTURE "999999999.99" FONT oFont2 ;
       WHEN((oGet[06]:cText := oBrwDet:aCols[5]:nTotal) = 'xxx') UPDATE

   oGet[01]:bGotFocus := {|| oDlg1:cargo := oGet[1],nPicture:=2,lReemplaza:=.t.}
   oGet[02]:bGotFocus := {|| oDlg1:cargo := oGet[2],nPicture:=13,lReemplaza:=.t.}
   oGet[03]:bGotFocus := {|| oDlg1:cargo := oGet[3],nPicture:=10,lReemplaza:=.t.}
   oGet[06]:bGotFocus := {|| oDlg1:cargo := oGet[6],nPicture:=11}

   oDlg1:bKeyDown = { | nKey, nFlags | IF(nKey==106,oGet[1]:SetFocus(),;
                                       IF(nKey==113,(Eval(oGet[02]:bAction),oGet[1]:SetFocus()),;
                                       IF(nKey==117,oBot[32]:Click,;
                                       IF(nKey==114,oBot[33]:Click,;
                                       IF(nKey==115,oBot[35]:Click,;
                                       IF(nKey==116,oBot[37]:Click,;
                                       IF(nKey==118,Varios(oGet),;
                                       IF(nKey==119,PreCuenta(oQryDet),;
                                       IF(nKey==123,oBot[39]:Click,.F.)))))))))}
   oGet[03]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[3]:assign(),AgregarArticu(nCodArt),oGet[02]:SetFocus()),.t.)}
   oGet[02]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[2]:assign(),AgregarArticu(nCodArt)),.t.)}
   oGet[01]:bKeyDown := {| nKey,nFlags | IF(nKey==13,(oGet[1]:assign(),oGet[02]:SetFocus()),.t.)}


oDlg1:cargo:= oGet[02]
ACTIVATE DIALOG oDlg1 CENTER;
         ON INIT (oGet[02]:SetFocus())
oQryBrw:Refresh()
IF !lRta
   RETURN nil 
ENDIF

lRta:=.f.


//Primero miro si tiene credito
IF oQryEmp:consumo_limite > 0
   //Veo que tiene hasta ahora
   nTotalAcum := oApp:oServer:Query("SELECT SUM(ptotal) AS total FROM ge_"+oApp:cId+"emp_consumoint"+;
                 " WHERE liquidado IS FALSE AND codemp = " + ClipValue2Sql(nCodEmp)):total 
   IF nTotalAcum + nTotal > oQryEmp:consumo_limite
      MsgStop("El empleado excede su limite de consumo Interno"+chr(10)+;
              "Limite:"+STR(oQryEmp:consumo_limite,12,2)+chr(10)+;
              "Acumulado sin liquidar:"+STR(nTotalAcum,12,2)+chr(10)+;
              "Total con este consumo :"+STR(nTotalAcum+nTotal,12,2)+chr(10)+;
              "Excedente:"+STR(nTotalAcum+nTotal-oQryEmp:consumo_limite,12,2),"Error")
      LOOP
   ENDIF   
ENDIF   
TRY
  oApp:oServer:BeginTransaction()
  //Aca grabo
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_consumoint "+;
                        " (codart,nomart,cantidad,punit,fecha,codemp,ptotal,hora,usuario) "+;
                        " (SELECT codart,nomart,cantidad,punit,CURDATE(),"+ClipValue2Sql(nCodEmp)+","+;
                        "         ptotal,CURTIME() ,"+ClipValue2Sql(oApp:usuario)+;
                        " FROM detalle_consumo )")
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
           "INNER JOIN "+; 
           "("+; 
           "SELECT codart, SUM(cantidad) as suma "+;
           "FROM detalle_consumo "+;
           "GROUP BY codart "+;
           ") v ON a.codigo = v.codart "+;
           "SET a.stockact = a.stockact - v.suma WHERE a.stockotro IS FALSE")
  // Actualizo el stock de los que descuentan de otros articulos
  oQryStock:= oApp:oServer:Query("SELECT SUM(d.cantidad) AS cantidad,"+;
                                 "d.codart AS codart FROM detalle_consumo d "+;
                                 "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
                                 "WHERE a.stockotro = TRUE GROUP BY d.codart")
  oQryStock:GoTop()
  DO WHILE !oQryStock:EOF()
     oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu m "+;
                          " ON m.codigo = r.codusa "+;
                          "SET m.stockact = m.stockact - (("+ClipValue2Sql(oQryStock:cantidad)+") * r.cantidad) "+;
                          "WHERE r.codart = "+ClipValue2Sql(oQryStock:codart))
     oQryStock:Skip()
  ENDDO
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh()
  oBrw:Maketotals()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
IF MsgYesNo("Desea imprimir el consumo interno?","Atencion")
   PrintConsumoInt(nCodEmp,oQryDet)
ENDIF

RETURN nil




**************************************************************************************
***** CARGAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION CargarNum(oGet,nNum,nPict,lString)
LOCAL cTexto
DEFAULT lString:=.f.

IF lString 
   cTexto:=oGet:cText
   cTexto := cTexto + STR(nNum,1)
   oGet:cText:= cTexto
ELSE
  IF LEN(ALLTRIM(oGet:cText)) = nPict
   RETURN nil
  ENDIF
  cTexto:=ALLTRIM(STR(oGet:Value,nPict))
  cTexto := cTexto + STR(nNum,1)
  oGet:cText:= VAL(cTexto)
ENDIF
RETURN nil
***************************************************************************************
***** BORRAR NUMERO (FUNCION PARA LAS VENTANAS TACTILES)
STATIC FUNCTION BorrarNum(oGet,lString)
LOCAL cTexto
DEFAULT lString:=.f.
/*cTexto := LEFT(oGet:cText,LEN(oGet:cText)-1)
IF lString
   oGet:cText := cTexto
ELSE
   oGet:cText := VAL(cTexto)
ENDIF*/
oGet:cText := 0
RETURN nil

***************************************************************************
STATIC FUNCTION BorrarDet()
IF MsgNoYes("¿Seguro de eliminar el detalle del consumo? ","Atencion")
   oApp:oServer:Execute("TRUNCATE detalle_consumo")
ENDIF
RETURN nil

STATIC FUNCTION SiEsDepto(oQ)
RETURN oQ:codart < 0

STATIC FUNCTION Varios(oGet)
oGet[02]:cText := -1
oGet[07]:cText := "VARIOS                 "
oGet[03]:SetFocus()
RETURN nil

STATIC FUNCTION Precuenta()
RETURN nil


*****************************************
** Cambiar saldo
STATIC FUNCTION CambiaCant(nVal,n)
LOCAL nCantAnt
IF n = 1
   nCantAnt := oQryDet:cantidad
   oQryDet:cantidad := nVal
   oQryDet:ptotal    := oQryDet:ptotal / nCantAnt * nVal
   //oQryDet:neto     := oQryDet:neto / nCantAnt * nVal
   //oQryDet:iva      := oQryDet:iva / nCantAnt * nVal
   oQryDet:Save()
   oQryDet:Refresh()
   oBrwDet:Refresh()
   oBrwDet:MakeTotals()
   nTotal := oBrwDet:aCols[5]:nTotal
   oGet[06]:Refresh()
   ELSE 
   IF n = 2
      oQryDet:punit := nVal
      oQryDet:ptotal := nVal * oQryDet:cantidad      
      oQryDet:Save()
      oQryDet:Refresh()
      oBrwDet:Refresh()
      oBrwDet:MakeTotals()
      nTotal := oBrwDet:aCols[5]:nTotal
      oGet[06]:Refresh()
   ENDIF
ENDIF
RETURN nil


*************************************************************************************************
*** AGREGO ARTICULO AL DETALLE
STATIC FUNCTION AgregarArticu(nCodArt)
LOCAL nRenglon, oQryAux, oQryAux1, oQryAux2, aGuar := {}, aCara := {}, oDlgA, oCom := ARRAY(2),;
      oBot := ARRAY(2), cGuar := SPACE(30), cCara := SPACE(100), lRta := .f., aCor, i, nTasa,nTotal,;
      nUnit,nIva,nTotalPesado:=0,lPesado:=.f.,;
      oQrySab,nSabor1:=0,cSabor1:=SPACE(40),nSabor2:=0,cSabor2:=SPACE(40),nSabor3:=0,cSabor3:=SPACE(40),;
      nSabor4:=0,cSabor4:=SPACE(40),nSabor5:=0,cSabor5:=SPACE(40),cSabores:=" ",nLargo, nPrecioVen
IF nCodArt = 0
   RETURN nil 
ENDIF 
IF nCodArt > 2000000000000 .and. nCodArt < 3000000000000 //VERIFICO SI ES UN PESADO
      nTotalPesado := VAL(SUBSTR(STR(nCodArt,13),8,5)) / 1000 //GUARDO LA CANTIDAD PESADO
      nCodArt := VAL(LEFT(STR(nCodArt,13),7))  //TRUNCO LA PARTE DEL CODIGO 
      lPesado := .t.
   ENDIF
oQryDet:GoBottom()
nRenglon:=oQryDet:orden+1
oQryAux:= oApp:oServer:Query("SELECT *,"+cPrecio+" as prec FROM ge_"+oApp:cId+"articu WHERE codigo = " +;
                              ClipValue2Sql(nCodArt) +;
                              " LIMIT 1")
IF oQryAux:nRecCount = 0 
   MsgStop("Producto no encontrado","Atencion")
   RETURN nil
ENDIF
IF lPesado  //SI ES UN PESADO CALCULO LA CANTIDAD DEPENDIENDO DEL TOTAL
   nCantidad := nTotalPesado 
   nCantidad := round(nCantidad,3)
   IF !oQryAux:pesable
      nCantidad := nCantidad * 1000
   ENDIF
ENDIF
nPrecioVen := oQryAux:prec
IF oQryAux:pesable .and. !lPesado  //SI ES UN ARTICULO PESABLE PIDO QUE INGRESE LA CANTIDAD A FACTURAR
   //oGet[07]:cText:= oQryAux:nombre
    IF !PedirCantidad(nPrecioVen)
        RETURN .f.
    ENDIF
ENDIF
 
SET DECIMAL TO 3
nUnit := oQryAux:prec - (oQryAux:prec*(nDescuentoP/100))
nTotal:= nUnit*nCantidad
SET DECIMAL TO 2
oApp:oServer:Execute("INSERT INTO detalle_consumo "+;
  "(orden,codart,nomart,cantidad,punit,ptotal) VALUES "+;
                     "("+ClipValue2Sql(nRenglon)+","+;
                        +ClipValue2Sql(oQryAux:codigo)+","+;
                        +ClipValue2Sql(oQryAux:nombre)+","+;
                        +ClipValue2Sql(nCantidad)+","+;
                        +ClipValue2Sql(nUnit)+","+;                        
                        +ClipValue2Sql(nTotal)+""+;                        
                        +")")
oQryDet:Refresh()
oBrwDet:Refresh()
oBrwDet:MakeTotals()
nCantidad:=1
oGet[02]:cText := 0
oGet[02]:Refresh()
oBrwDet:GoBottom()
//oGet[06]:cText := oBrwDet:aCols[5]:nTotal
nTotal := ROUND(oBrwDet:aCols[5]:nTotal,2)
oGet[02]:SetFocus()
RETURN nil

**************************************************************************************************
****** PEDIR QUE INGRESE LA CANTIDAD SI ES UN PESABLE 
**************************************************************************************************
****** PEDIR QUE INGRESE LA CANTIDAD SI ES UN PESABLE 
STATIC FUNCTION PedirCantidad(nPre)
LOCAL acor:=ARRAY(4),oDlgD,oGet1:=ARRAY(2),oBot1,oBot2,lRta:=.f.,nCantTemp:=0, nPrecio := 0

DEFINE DIALOG oDlgD TITLE "Ingresar cantidad del articulo pesable a facturar" OF oWnd1 FROM 05,15 TO 14,65
  acor := AcepCanc(oDlgD)
  

   @ 12, 05 SAY "Cantidad:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1[1] VAR nCantTemp OF oDlgD PIXEL PICTURE "9999.999" RIGHT;
                 VALID((oGet1[2]:cText:= ROUND(nCantTemp*nPre,2)) <> 'xxx')


   @ 27, 05 SAY "Precio:" OF oDlgD PIXEL SIZE 40,12 RIGHT
   @ 25, 50 GET oGet1[2] VAR nPrecio OF oDlgD PIXEL PICTURE "99999999.99" RIGHT;
                 VALID((oGet1[1]:cText:= ROUND(nPrecio /nPre,3)) <> 'xxx');
                 WHEN ("M"$cPermi)

   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Aceptar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgD:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgD SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgD:End() ) PIXEL CANCEL 
           
ACTIVATE DIALOG oDlgD CENTER ON INIT oGet1[1]:SetFocus
IF !lRta
   RETURN .f.
ENDIF
IF nCantTemp = 0
   RETURN .f.
ENDIF
nCantidad:= nCantTemp
oGet[06]:SetFocus()
RETURN .t.


*****************************************
** Impresion de consumo Interno 
STATIC FUNCTION PrintConsumoInt(nCodEmp,oQryDet)
LOCAL oPrn, mtot := 0, i, oFont, oFont1, config, lRta := .t., oQryP,nDesc,cMozo, nRow1, nRow,;
      oParame := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"parametros"),oQryEmp

oQryP :=  oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"punto WHERE ip = "+ ClipValue2Sql(oApp:cip))

oQryEmp:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"emp_empleado WHERE codigo = "+ ClipValue2Sql(nCodEmp))
config   := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"config")
IF config:fon > 25
  config:fon := config:fon /3
ENDIF
DEFINE FONT oFont   NAME "COURIER NEW"       SIZE config:fon,config:fon*2.5 BOLD
DEFINE FONT oFont1  NAME "CALIBRI"           SIZE config:fon,config:fon*3.5 BOLD

IF oQryP:imprimeTic
      IF !oApp:tick80
       mtot := 0
       PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
          oPrn:oFont := oFont
          oPrn:SetPortrait()
          PAGE
          oPrn:Say( oApp:tamlet*1,1, "DOCUMENTO NO VALIDO",oFont)
          oPrn:Say( oApp:tamlet*2,1, "  COMO FACTURA",oFont)                          
          oPrn:Say( oApp:tamlet*5,1, "Consumo Interno",oFont1)
          oPrn:Say( oApp:tamlet*6,1, "Empleado: "+ALLTRIM(oQryEmp:nombre),oFont1)
          oPrn:Say( oApp:tamlet*7,1, DTOC(DATE())+" "+ TIME(),oFont)
          oPrn:Say( oApp:tamlet*9,1, "Detalle           Cant    Precio",oFont)
          oQryDet:GoTop()
          FOR i = 1 TO oQryDet:nRecCount
              oPrn:Say(  (oApp:tamlet*9) +  i*oApp:tamlet , 01 , LEFT(oQryDet:nomart,15) + ;
                                   " " + STR(oQryDet:cantidad,6,1) +;
                                   STR(oQryDet:ptotal,10,2),oFont)
              mtot := mtot + oQryDet:ptotal
              oQryDet:SKIP()
          NEXT i          
          oPrn:Say(  (oApp:tamlet*9) +  i*oApp:tamlet+oApp:tamlet*0,1, "Items " + STR(i-1,5),oFont )          
          oPrn:Say(  (oApp:tamlet*9) +  i*oApp:tamlet+oApp:tamlet*4,1,"T O T A L: $" + STR(mtot,12,2),oFont1 )                    
          oPrn:Say(  (oApp:tamlet*9) +  i*oApp:tamlet+oApp:tamlet*9,1, "..."    )
          ENDPAGE
       ENDPRINT
      ELSE
       mtot := 0
       PRINT oPrn TO ALLTRIM(oQryP:impresoraT)
          oPrn:oFont := oFont
          oPrn:SetPortrait()
          nRow := .5
          PAGE
          @ nRow, 00 PRINT TO oPrn TEXT "DOCUMENTO NO VALIDO" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"
          @ nRow, 00 PRINT TO oPrn TEXT "COMO FACTURA" ;
                                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow ALIGN "C"                          
          @ nRow, 00 PRINT TO oPrn TEXT  "Consumo Interno" ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow
          @ nRow, 00 PRINT TO oPrn TEXT  "Empleado: "+ALLTRIM(oQryEmp:nombre) ;
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow          
          @ nRow, 00 PRINT TO oPrn TEXT  "Fecha:"+DTOC(DATE())+" Hora:"+ TIME() ;
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow          
          nRow1 := nRow + .5
          @ nRow1, 00 PRINT TO oPrn TEXT "Descripcion";
                      SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
          @ nRow1, 3.7 PRINT TO oPrn TEXT "Cant";
                      SIZE .9,.5 CM FONT oFont LASTROW nRow ALIGN "R"
          @ nRow1, 4.7 PRINT TO oPrn TEXT "P.unit";
                      SIZE 1.2,.5 CM FONT oFont LASTROW nRow ALIGN "R"
          @ nRow1, 5.7 PRINT TO oPrn TEXT "Total";
                      SIZE 1.3,.5 CM FONT oFont LASTROW nRow ALIGN "R"
          oQryDet:GoTop() 
          oPrn:CmLine( nRow1,0, nRow1,9 )              
          nRow := nRow + .2                                             
          FOR i = 1 TO oQryDet:nRecCount
             nRow1 := nRow
             @ nRow1, 00 PRINT TO oPrn TEXT ALLTRIM(oQryDet:nomart);
                  SIZE 3.5,.5 CM FONT oFont LASTROW nRow ALIGN "L"
             @ nRow1, 3.7 PRINT TO oPrn TEXT STR(oQryDet:cantidad,06,1);
                  SIZE 0.9,.5 CM FONT oFont LASTROW nRow ALIGN "R"             
             @ nRow1, 4.7 PRINT TO oPrn TEXT STR(oQryDet:punit,9,2);
                  SIZE 1.2,.5 CM FONT oFont LASTROW nRow ALIGN "R"       
             @ nRow1, 5.7 PRINT TO oPrn TEXT STR(oQryDet:ptotal,10,2);
                  SIZE 1.3,.5 CM FONT oFont LASTROW nRow ALIGN "R"               
             mtot := mtot + oQryDet:ptotal
             oQryDet:SKIP()
          NEXT i
          nRow := nRow + .5
          @ nRow, 00 PRINT TO oPrn TEXT  "Items " + STR(i-1,5) ;
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow          
          @ nRow, 00 PRINT TO oPrn TEXT "TOTAL: $" + STR(mtot,12,2) ;
                  SIZE 7.4,.5 CM FONT oFont1 LASTROW nRow                    
          @ nRow, 00 PRINT TO oPrn TEXT  "...";
                  SIZE 7.4,.5 CM FONT oFont LASTROW nRow                                       
          ENDPAGE
       ENDPRINT 
      ENDIF
   ELSE 
   oQryDet:GoTop()
   REPORT oPrn TITLE "Consumo Interno " + oQryEmp:nombre ;       
       HEADER ALLTRIM(OemToAnsi(oApp:nomb_emp)) CENTER ;       
       PREVIEW CAPTION  "Consumo interno"

        COLUMN TITLE "Detalle"   DATA oQryDet:nomart    SIZE 30
        COLUMN TITLE "Cantidad"  DATA oQryDet:cantidad  PICTURE "9999.9" SIZE 08 TOTAL
        COLUMN TITLE "Importe"   DATA oQryDet:ptotal     SIZE 12 TOTAL        

        // Digo que el titulo lo escriba con al letra 2        
        oPrn:bInit := {|| oQryDet:GoTop() }
        oPrn:bSkip := {|| oQryDet:Skip() }

        END REPORT
        ACTIVATE REPORT oPrn WHILE !oQryDet:EOF() ON INIT CursorArrow() ;
                 ON STARTPAGE oPrn:SayBitmap(.1,.1,"LOGO.JPG",.5,.5)
ENDIF
RETURN NIL


********************************************
** Liquidaciones de consumos Internos
STATIC FUNCtION Liquidado()
LOCAL oQry, oDlg1, oFont, acor:= ARRAY(4), nMes:=MONTH(DATE()), nAno := YEAR(DATE()), mrta:=.F., oGet:= ARRAY(6),;
      oBot1, oBot2, oBot3, oBrwLiq, aLiqu, nSub := 0, dFecha := DATE(), oQryE , cDetalle := SPACE(30), oError,;
      lAplicar := .f.
oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_liqcon` ("+;
                           "`id` INT(10) NOT NULL, "+;
                           "`nombre`  VARCHAR(40) , "+;
                           "`fecha` DATE, "+;                           
                           "`nomart` VARCHAR(40), "+;
                           "`codemp` INT(8), "+;                             
                           "`ptotal`  DECIMAL(12,2), "+;
                           "`liquidado`  TINYINT(1) DEFAULT '0' NOT NULL "+;
                           ") ENGINE=INNODB DEFAULT CHARSET=utf8") 
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_liqcon")
oApp:oServer:NextResult()
mrta := SiNoCancelar("Liquidación", "Indique a quien desea cargar como liquidado el consumo interno... ",;
      {"A todos","A "+LEFT(oQryBrw:nombre,9),"Cancelar"})
IF mrta = nil 
   RETURN nil 
ENDIF
IF mrta
   oApp:oServer:Execute(" INSERT INTO transi_liqcon (id,nombre,fecha,nomart,ptotal,liquidado,codemp) "+;
                        "(SELECT  c.id,e.nombre, c.fecha,c.nomart,c.ptotal, false, c.codemp FROM ge_"+oApp:cId+"emp_consumoint c "+;
                        " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON e.codigo = c.codemp "+;
                        " WHERE c.liquidado IS FALSE)")   
   ELSE 
   oApp:oServer:Execute(" INSERT INTO transi_liqcon (id,nombre,fecha,nomart,ptotal,liquidado, codemp) "+;
                        "(SELECT  c.id,e.nombre, c.fecha,c.nomart,c.ptotal, false, c.codemp "+;
                        " FROM ge_"+oApp:cId+"emp_consumoint c "+;
                        " LEFT JOIN ge_"+oApp:cId+"emp_empleado e ON e.codigo = c.codemp "+;
                        " WHERE c.liquidado IS FALSE AND codemp = "+STR(oQryBrw:codemp)+")")   
ENDIF   
oQryE := oApp:oServer:Query("SELECT * FROM transi_liqcon")
IF oQryE:nRecCount = 0
   MsgStop("Sin datos para marcar como liquidado","Atencion")
   RETURN nil 
ENDIF   
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Marcar consumos como liquidados" FROM 03,15 TO 32,100
   acor := AcepCanc(oDlg1)       
   @ 05,20 BUTTON oBot3 PROMPT "Invertir todo" OF oDlg1 ACTION (InvertirTildes(oBrwLiq,oQryE)) PIXEL SIZE 45,12
   @ 20, 05 XBROWSE oBrwLiq SIZE 315,150 pixel OF oDlg1 DATASOURCE oQryE ;
      HEADERS "Empleado", "Producto","Fecha","Total","Liquidado";
      COLUMNS "nombre", "nomart" ,"fecha", "ptotal","liquidado";
      SIZES 150,150,80,90,80;
      FOOTERS;
      CELL LINES NOBORDER UPDATE
   WITH OBJECT oBrwLiq 
      :aCols[1]:cFooter := "Total Selección"
      :aCols[4]:nFooterType := AGGR_SUM            
      :aCols[5]:nEditType := EDIT_GET  
      :aCols[5]:bEditValue := {|| IF( oQryE:liquidado == .T., .t., .f. )  }    
      :aCols[5]:SetCheck(,.f.)
      :aCols[5]:bLDClickData := {|| CambiaChek(oBrwLiq,oQryE)}
      :aCols[4]:bSumCondition := { || oQryE:liquidado }
      :MakeTotals()
      :CreateFromCode()      
   END  
   PintaBrw(oBrwLiq,0)
   @ acor[1]-22,05  CHECKBOX oGet[1] VAR lAplicar PROMPT "Aplicar Pago a Liquidacion" SIZE 100,12 OF oDlg1 PIXEL 
   @ acor[1]-20,112  SAY "Mes:" OF oDlg1 PIXEL RIGHT SIZE 20,10
   @ acor[1]-20,153  SAY "Año:" OF oDlg1 PIXEL RIGHT SIZE 20,10
   @ acor[1]-22,135  GET oGet[2] VAR nMes PICTURE "99" OF oDlg1 PIXEL RIGHT WHEN(lAplicar) 
   @ acor[1]-22,175  GET oGet[3] VAR nAno PICTURE "9999" OF oDlg1 PIXEL RIGHT WHEN(lAplicar)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Grabar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER 
IF !mrta
   RETURN  NIL
ENDIF
TRY

  oApp:oServer:BeginTransaction()  
  IF lAplicar 
     oQryE :=  oApp:oServer:Query("SELECT SUM(ptotal) as importe, codemp FROM transi_liqcon WHERE liquidado IS TRUE GROUP BY codemp ")
     DO WHILE !oQryE:Eof()
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"emp_pagsueldo (mes,ano,importe , fecha, observa, tipo, codemp, usuario  ) VALUES ("+;
                       ClipValue2Sql(nMes)+","+ClipValue2Sql(nAno)+","+ClipValue2Sql(oQryE:importe)+",CURDATE(),"+;
                       ClipValue2Sql("LIQ. CONSUMO INTERNO")+","+ClipValue2Sql(3)+","+ClipValue2Sql(oQryE:codemp)+","+;
                       ClipValue2Sql(oApp:usuario)+")")
        oQryE:Skip()
     ENDDO   
  ENDIF  
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"emp_consumoint SET liquidado = TRUE WHERE id IN "+;
                       " (SELECT id FROM transi_liqcon WHERE liquidado IS TRUE)")
  oApp:oServer:CommitTransaction()
  MsgInfo("Proceso Terminado con Exito!","Atencion")
CATCH oError
    ValidaError(oError)
END TRY      
RETURN nil

STATIC FUNCTION CambiaChek(oBrw1,oQryE)
LOCAL valor
valor := IF(oQryE:liquidado,.f.,.t.)
oQryE:liquidado := valor
oQryE:Save()
oQryE:Refresh()
oBrw1:Maketotals()
oBrw1:Refresh()
RETURN nil

STATIC FUNCTION InvertirTildes(oBrw1,oQryE)
oApp:oServer:Execute("UPDATE transi_liqcon SET liquidado = NOT liquidado")
oQryE:Refresh()
oBrw1:Maketotals()
oBrw1:Refresh()
RETURN nil