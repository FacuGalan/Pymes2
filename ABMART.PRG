#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "report.ch"


*************************************************
** ABM DE articulos
*************************************************
MEMVAR oApp
STATIC oQryBrw,oQry, oQry2, oQry3, oQry4, oQry5, oQry6, oQry7 ,;
       oWnd1, oBrw, oDlg, cVentana,oBrw1, oQryArt,oQryPun , lTipoArt, nActivos,cWhere, dDesde, dHasta
PROCEDURE Artic(cPermisos)
LOCAL oBar, hHand, oGetSeek, cSeek := SPACE(50), oPop2, oPop3
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
lTipoArt := nil
AADD(oApp:aVentanas,cVentana)
dDesde := CTOD('01/01/2000')
dHasta := DATE()
nActivos:= 1
cWhere:=''
oQryBrw:= oApp:oServer:Query("SELECT a.codigo,a.codigopro,a.nombre,a.stockact,a.Preciocos,a.Precioven,a.reventa,a.fecmod,LEFT(a.observa,50) AS observa,a.nosale,p.nombre AS nompro "+;
                             "FROM ge_"+oApp:cId+"articu a "+;
                             "LEFT JOIN ge_"+oApp:cId+"provee p ON a.prov = p.codigo "+;
                             "ORDER BY a.nombre")
MENU oPop2 POPUP
     MENUITEM "Todos los productos"  ACTION (FiltrarVen(nil),oGetSeek:SetFocus())
     MENUITEM "Solo Vendibles"       ACTION (FiltrarVen(.t.),oGetSeek:SetFocus())
     MENUITEM "Solo No vendibles"    ACTION (FiltrarVen(.f.),oGetSeek:SetFocus())
ENDMENU

MENU oPop3 POPUP
     IF "M"$cPermisos         
        MENUITEM "Historial de precios"   ACTION (Historial(),oGetSeek:SetFocus())
     ENDIF   
     IF "A"$cPermisos
        MENUITEM "Historial de ventas"    ACTION (HistorialVentas(),oGetSeek:SetFocus())
     ENDIF   
ENDMENU

   oQry2  := oApp:oServer:Query( "SELECT codigo,nombre,alias FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry3  := oApp:oServer:Query( "SELECT codigo,nombre,tasa FROM ge_"+oApp:cId+"ivas ORDER BY codigo")
   oQry4  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas ORDER BY codigo")
   oQry5  := oApp:oServer:Query( "SELECT codigo,nombre,depto FROM ge_"+oApp:cId+"rubros ORDER BY codigo")
   oQry6  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos ORDER BY codigo")
   oQry7  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas ORDER BY codigo")
   
 
  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Articulos: Solo articulos vendibles";
          OF oApp:oWnd NOZOOM ICON oApp:oIco FROM 05,05 TO 50,50
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ,oQryBrw:codigo),oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Modifica" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos) 
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja( ),oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Baja" TOP WHEN(oQryBrw:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "DUPL" OF oBar ;
            TOOLTIP "Duplicar Registro"  ;
            ACTION (Duplicar( ),oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Duplicar" TOP WHEN(oQryBrw:RecCount()>0 .AND. "A"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION (oBrw:ToExcel(),oGetSeek:SetFocus()) WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION (oBrw:Report("Reporte de Articulos",.T.,.F.),oGetSeek:SetFocus());
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "FILT" OF oBar ;
            TOOLTIP "Filtrar Articulos"  ;
            ACTION (FILT(),oBrw:Refresh(),oGetSeek:SetFocus()) MENU oPop2;
            PROMPT "Filtrar" TOP     
         DEFINE BUTTON RESOURCE "PRECIO" OF oBar ;
            TOOLTIP "Ver historial de precios"  ;
            ACTION (Historial(),oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Historial" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos)  MENU oPop3   
         DEFINE BUTTON RESOURCE "BACKU" OF oBar ;
            TOOLTIP "Importar Articulos"  ;
            ACTION Importar();
            PROMPT "Importar" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "CONFIRMA" OF oBar ;
            TOOLTIP "Info del producto, participacion en listas, grupos, recetas"  ;
            ACTION Info();
            PROMPT "Info" TOP WHEN("M"$cPermisos)    
         DEFINE BUTTON RESOURCE "ARTI" OF oBar ;
            TOOLTIP "Cambiar el Codigo / Codigo de barras"  ;
            ACTION (Cambiar(), oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Cambiar" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos)     
         DEFINE BUTTON RESOURCE "CODBAR1" OF oBar ;
            TOOLTIP "Buscar por codigo"  ;
            ACTION (BuscarxCod(), oBrw:Refresh(),oGetSeek:SetFocus());
            PROMPT "Buscar" TOP WHEN(oQryBrw:RecCount()>0 .and. "M"$cPermisos)    
         DEFINE BUTTON RESOURCE "PROD" OF oBar ;
            TOOLTIP "Reporte de Recetas"  ;
            ACTION (RepRecetas(),oGetSeek:SetFocus());
            PROMPT "Lista Rec." TOP WHEN("R"$cPermisos)         
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     IF "M"$cPermisos
         REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
                  COLUMNS "Codigo","codigopro","nombre","stockact","Preciocos","Precioven","reventa","fecmod","nompro","Observa";
                  HEADERS "Código art.","Cód.Prov.","Nombre","Stock","Precio costo","P. Venta 1","P. Venta 2","Fecha Cambio","Proveedor","Observaciones";
                  SIZES 90,70,230,60,70,75,75,70,200,200;
                  ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu( .f.,oQryBrw:codigo),oGetSeek:SetFocus()),nil))
         REDEFINE GET oGetSeek VAR cSeek ID 113 OF oDlg
         PintaBrw(oBrw,9) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     ELSE
         REDEFINE XBROWSE oBrw DATASOURCE oQryBrw;
                  COLUMNS "Codigo","codigopro","nombre","Preciocos","Precioven","reventa","fecmod","nompro","observa";
                  HEADERS "Código art","Cód.Prov.","Nombre","Precio costo","P. Venta 1","P. Venta 2","Fecha Cambio","Proveedor","Observaciones";
                  SIZES 90,70,350,70,70,70,70,200,200;
                  ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu( .f.,oQryBrw:codigo),oGetSeek:SetFocus()),nil))
         REDEFINE GET oGetSeek VAR cSeek ID 113 OF oDlg
         PintaBrw(oBrw,8) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     ENDIF
     oBrw:bClrStd := { || IF(oQryBrw:nosale,{ CLR_BLACK, RGB(255,50,50) },;
                          If( oBrw:KeyNo() % 2 == 0, ;
                          { CLR_BLACK, RGB(193,221,255) }, ;
                          { CLR_BLACK, RGB(221,245,255) } )) }
     
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     //oBrw:aCols[3]:SetOrder()
     oBrw:bKeyDown := {|nKey,nFlags| (Acelerador2(nKey,oBar, oBrw,cPermisos,8),IF(nKey>32,oGetSeek:SetFocus(),nil))}
     oGetSeek:bKeyDown := { |nKey,nFlag| FiltraArt2(oQryBrw, oGetSeek, oBrw, nKey,cWhere) }
     oBrw:aCols[ 9 ]:cSortOrder := LEFT(oQryBrw:observa,10)
     //oBrw:SetDolphin(oQry,.f.,.t.)
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT (oGetSeek:SetFocus(),oDlg:Move(0,0),FiltrarVen(.t.)) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN



*************************************
** Agregar un registro nuevo
STATIC FUNCTION Formu (lAlta,nCodArt)
LOCAL oGet := ARRAY(54), oBot := ARRAY(8), oForm, lRta := .F., aCor, base, cProve:=SPACE(30), nNeto,;
      cIvaNom:=SPACE(30), cMarc:=SPACE(30), cRub:=SPACE(30), cDept:=SPACE(30), cEmp:=SPACE(30), nIva,oError,nPrecioven:=0,nPreciocos:=0,;
      nova1,nova2,oSay:=ARRAY(8),oGru:=ARRAY(2), mstock := 0, lActualizaGrupo := .f.
IF !lAlta .and. nCodArt = 0
   RETURN nil 
ENDIF   
IF lAlta
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu LIMIT 0")
   base := oQry:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"articu")
   base:iva := 5
   base:prov  := oQry2:codigo
   base:marca := oQry4:codigo
   base:rubro := oQry5:codigo
   base:depto := oQry6:codigo
   base:empresa := oQry7:codigo   
   base:siniva := .t.
   ELSE
   oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(nCodArt))
   base := oQry:GetRowObj()
   
   nPrecioven:=base:precioven
   nPreciocos:=base:preciocos
   mstock := base:stockact
ENDIF
   oQry2  := oApp:oServer:Query( "SELECT codigo,nombre,alias FROM ge_"+oApp:cId+"provee WHERE codigo = "+str(base:prov))
   oQry3  := oApp:oServer:Query( "SELECT codigo,nombre,tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = "+str(base:iva))
   oQry4  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas WHERE codigo = "+str(base:marca))
   oQry5  := oApp:oServer:Query( "SELECT codigo,nombre,depto FROM ge_"+oApp:cId+"rubros WHERE codigo = "+str(base:rubro))
   oQry6  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos WHERE codigo = "+str(base:depto))
   oQry7  := oApp:oServer:Query( "SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas WHERE codigo = "+str(base:empresa))
   
   cProve := oQry2:nombre
   cIvaNom := STR(oQry3:tasa,6,2) + "%"
   cMarc := oQry4:nombre
   cRub := oQry5:nombre
   cDept := oQry6:nombre
   cEmp := oQry7:nombre
   

base:observa := IF(EMPTY(base:observa),SPACE(255),ALLTRIM(base:observa)+SPACE(255-LEN(ALLTRIM(base:observa))))

DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Articulo" RESOURCE "ABMART1" OF oWnd1
 oForm:lHelpIcon := .f.
 
 REDEFINE GET oGet[01] VAR base:codigo PICTURE "99999999999999" ID 100 OF oForm WHEN(lAlta)
  REDEFINE GET oGet[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!"
  REDEFINE SAY oSay[8] ID 4002 OF oForm
  REDEFINE GET oGet[51] VAR base:codigopro ID 4017 OF oForm PICTURE "@!"
  REDEFINE CHECKBOX oGet[46] VAR base:endolares   ID 4012 OF oForm
  REDEFINE CHECKBOX oGet[52] VAR base:pesable ID 4011 OF oForm 
  REDEFINE CHECKBOX oGet[34] VAR base:nosale ID 103 OF oForm 

  REDEFINE GROUP oGru[1] ID 401 OF oForm
  REDEFINE CHECKBOX oGet[44] VAR base:mprima      ID 4007 OF oForm
  REDEFINE CHECKBOX oGet[45] VAR base:produccion  ID 4008 OF oForm WHEN(!base:stockotro)
  REDEFINE BUTTON oBot[3] ID 4009 OF oForm ACTION (Reseta(base,oForm),oGet[06]:Refresh()) WHEN (base:produccion)
  

  REDEFINE GET oGet[04] VAR base:prov ID 104 OF oForm PICTURE "99999";
                VALID(Buscar(oQry2,oForm,oGet[4],oGet[5]));
                ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oForm,oGet[4],oGet[5])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oForm WHEN (.F.)
  REDEFINE GET oGet[21] VAR base:marca      ID 122 OF oForm PICTURE "9999";
               VALID(Buscar(oQry4,oForm,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oForm,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc           ID 123 OF oForm WHEN (.F.)
  REDEFINE GET oGet[23] VAR base:rubro      ID 124 OF oForm PICTURE "9999";
                VALID(Buscar(oQry5,oForm,oGet[23],oGet[24]) .and. (oGet[25]:cText:= oQry5:depto) <> 'XXX' .and. Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oForm,oGet[23],oGet[24]),oGet[25]:cText:= oQry5:depto,Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub            ID 125 OF oForm WHEN (.F.)
  REDEFINE GET oGet[27] VAR base:empresa    ID 126 OF oForm PICTURE "9999";
               VALID(Buscar(oQry7,oForm,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oForm,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp            ID 127 OF oForm WHEN (.F.)
  REDEFINE GET oGet[25] VAR base:depto      ID 128 OF oForm PICTURE "9999";
               VALID(Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept           ID 129 OF oForm WHEN (.F.)

  REDEFINE BUTTON oBot[4] ID 301 OF oForm ACTION AltaMar()
  REDEFINE BUTTON oBot[5] ID 302 OF oForm ACTION AltaRub()
  REDEFINE BUTTON oBot[6] ID 303 OF oForm ACTION AltaEmp()
  REDEFINE BUTTON oBot[7] ID 304 OF oForm ACTION AltaDep()


  REDEFINE GROUP oGru[2] ID 402 OF oForm
  REDEFINE SAY oSay[3] ID 4066 OF oForm 
  REDEFINE SAY oSay[4] ID 4067 OF oForm
  REDEFINE SAY oSay[5] ID 4069 OF oForm
  REDEFINE SAY oSay[6] ID 4070 OF oForm
  REDEFINE SAY oSay[7] ID 4071 OF oForm
  REDEFINE GET oGet[35] VAR base:unimed     ID 135 OF oForm PICTURE "@!"
  REDEFINE GET oGet[47] VAR base:medida     ID 500 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[48] VAR base:entero     ID 501 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[49] VAR base:uxbulto    ID 502 OF oForm PICTURE "9999"
  REDEFINE GET oGet[50] VAR base:pxbulto    ID 503 OF oForm PICTURE "999999999.99";
               VALID((oGet[06]:cText:= (base:pxbulto/base:uxbulto)) <> "xxx")


  REDEFINE CHECKBOX oGet[46] VAR base:siniva  ID 4003 OF oForm
  REDEFINE GET oGet[06] VAR base:precossiva ID 106 OF oForm PICTURE "999999999.99" 
  REDEFINE GET oGet[07] VAR base:desc1      ID 107 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[08] VAR base:desc2      ID 108 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[09] VAR base:desc3      ID 109 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[10] VAR base:desc4      ID 110 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[11] VAR base:desc5      ID 111 OF oForm PICTURE "999.99"  
  REDEFINE GET oGet[39] VAR nNeto           ID 112 OF oForm PICTURE "999999999.99";
           WHEN(CalcularNeto(base,oGet))
           
  REDEFINE GET oGet[12] VAR base:impint     ID 113 OF oForm PICTURE "99999.99"
  REDEFINE GET oGet[13] VAR base:flete      ID 114 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[14] VAR base:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet[14]:cText:= 0, (Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
  REDEFINE GET oGet[16] VAR base:preciocos  ID 117 OF oForm PICTURE "999999999.99";
                        WHEN((oGet[16]:cText:= nNeto + base:impint +;
                        nNeto * (base:flete/100) + ((nNeto * oQry3:tasa )/100)) = "-999999")
  REDEFINE GET oGet[17] VAR base:porcentaje ID 118 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.t.))
  REDEFINE GET oGet[18] VAR base:porcentajerev  ID 119 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.f.))
  REDEFINE GET oGet[19] VAR base:reventa    ID 120 OF oForm PICTURE "999999999.999"
  REDEFINE GET oGet[20] VAR base:precioven  ID 121 OF oForm PICTURE "999999999.999"
  
  
    //FECHAS
  REDEFINE SAY oSay[1] ID 801 OF oForm 
  REDEFINE GET oGet[41] VAR nova1          ID 1300 OF oForm
  REDEFINE GET oGet[29] VAR base:fecultcom ID 130 OF oForm WHEN(.F.)
  REDEFINE GET oGet[30] VAR base:fecmod    ID 131 OF oForm WHEN (.F.)
  REDEFINE SAY oSay[2] ID 804 OF oForm
  REDEFINE GET oGet[42] VAR nova2          ID 1311 OF oForm


  REDEFINE GET oGet[31] VAR base:stockmin   ID 132 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[33] VAR base:stockide   ID 134 OF oForm PICTURE "99999999.99"
  REDEFINE CHECKBOX oGet[53] VAR base:stockotro  ID 4005 OF oForm WHEN(!base:produccion)
  REDEFINE BUTTON oBot[8] ID 4015 OF oForm ACTION (Reseta(base,oForm,.f.)) WHEN (base:stockotro)
  REDEFINE GET oGet[54] VAR base:condicioncompra   ID 4020 OF oForm 

  REDEFINE GET oGet[36] VAR base:observa    ID 136 OF oForm 

  REDEFINE BUTTON oBot[1] ID 137 OF oForm PROMPT "&Grabar";
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
  
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet[01]:SetFocus(),EsconderPermisos(oGet,oSay,oGru,oBot))
IF !lRta
   RETURN nil
ENDIF
IF base:preciocos = 0 .or. base:iva = 0
   msginfo("Campos obligatorios como 'Precio costo' e 'IVA' tienen que estar completos","Atencion!")
   LOOP
ENDIF
IF base:iva <> 3 .and. base:iva <> 4 .and. base:iva <> 5
   MsgStop("Tasa de IVA no valida para facturacion","Error")
   LOOP
ENDIF
IF !lAlta
   IF mstock <> oApp:oServer:Query("SELECT stockact FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2SQL(base:codigo)):stockact
      MsgStop("El stock fue modificado en otra terminal"+CHR(10)+"No se actualizaran los datos. Reintente","Actualice")
      oQryBrw:Refresh()
      oBrw:Refresh()
      RETURN nil 
   ENDIF
ENDIF  
IF nPrecioven <> base:precioven .OR. nPreciocos <> ROUND(base:preciocos,3)
   oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"campre (codigo,preciocos,precossiva,precioven,reventa,fecmod,usuario,ip) "+;
                        "VALUES ("+ClipValue2Sql(base:codigo)+","+ClipValue2Sql(base:preciocos)+","+;
                        ClipValue2Sql(base:precossiva)+","+ClipValue2Sql(base:precioven)+","+ClipValue2Sql(base:reventa)+",CURDATE(),"+;
                        ClipValue2Sql(oApp:usuario)+",'Cambio puntual')")
   base:fecmod := oApp:oServer:Query("SELECT CURDATE() AS fecha"):fecha
   base:horamod := oApp:oServer:Query("SELECT CURTIME() AS hora"):hora   
   lActualizaGrupo := .t.
ENDIF
IF !oApp:utilfija
   base:porcentaje := (base:precioven * 100) / base:preciocos - 100
   base:porcentajerev := (base:reventa * 100) / base:preciocos - 100
ENDIF    
base:usuario:= oApp:usuario
base:ip     := oApp:cIp
base:nombre := STRTRAN(base:nombre,"'","´")
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  IF lAlta .and. base:stockact <> 0
     oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha","motivo","costo","usuario"},;
                           {base:codigo,base:stockact,0,DATE(),1,base:precossiva,oApp:usuario})
  ENDIF
  IF !lAlta .and. base:stockact <> mstock   
     oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha","motivo","costo","usuario"},;
                           {base:codigo,if(mstock < base:stockact, base:stockact - mstock,0),;
                            if(mstock > base:stockact, mstock - base:stockact,0),DATE(),1,base:precossiva,oApp:usuario}) 
  ENDIF  
  oApp:oServer:CommitTransaction()
  IF !lAlta .AND. lActualizaGrupo 
     ActualizarGrupo(base)
  ENDIF
  oQryBrw:Refresh(.f.)
  oBrw:Refresh()   
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


*************************************************************************************************************
********** ACTUALIZA EL PRECIO DE LOS ARTICULOS QUE SE ENCUENTRAN EN EL MISMO GRUPO QUE EL MODIFICADO
STATIC FUNCTION ActualizarGrupo(base)
LOCAL nGrupo, oError
nGrupo:= oApp:oServer:Query("SELECT codgru FROM ge_"+oApp:cId+"gruposdet WHERE codart = "+ClipValue2Sql(base:codigo)):codgru
IF nGrupo <> 0
  TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"gruposdet g LEFT JOIN ge_"+oApp:cId+"articu a "+;
                       " ON g.codart = a.codigo AND "+;
                       "    g.codgru = "+ClipValue2Sql(nGrupo)+;
                       " SET a.precossiva = "+ClipValue2Sql(base:precossiva)+","+;
                                         "a.desc1      = "+ClipValue2Sql(base:desc1)+","+;
                                         "a.desc2      = "+ClipValue2Sql(base:desc2)+","+;
                                         "a.desc3      = "+ClipValue2Sql(base:desc3)+","+;
                                         "a.desc4      = "+ClipValue2Sql(base:desc4)+","+;
                                         "a.desc5      = "+ClipValue2Sql(base:desc5)+","+;
                                         "a.impint     = "+ClipValue2Sql(base:impint)+","+;
                                         "a.flete      = "+ClipValue2Sql(base:flete)+","+;
                                         "a.iva        = "+ClipValue2Sql(base:iva)+","+;
                                         "a.preciocos  = "+ClipValue2Sql(base:preciocos)+","+;
                                         "a.porcentaje = "+ClipValue2Sql(base:porcentaje)+","+;
                                         "a.precioven  = "+ClipValue2Sql(base:precioven)+","+;
                                         "a.preciopro  = "+ClipValue2Sql(base:preciopro)+","+;
                                         "a.porcentajerev = "+ClipValue2Sql(base:porcentajerev)+","+;
                                         "a.reventa    = "+ClipValue2Sql(base:reventa)+","+;
                                         "a.fecmod     = CURDATE(),"+;
                                         "a.horamod    = CURTIME(),"+;
                                         "a.siniva     = "+ClipValue2Sql(base:siniva)+" ")
    oApp:oServer:CommitTransaction() 
  CATCH oError
    ValidaError(oError)
  END TRY    
ENDIF  
RETURN nil

************************************************************************************************************
********* CALCULA EL NETO DEL ARTICULO 
STATIC FUNCTION CalcularNeto(base,oGet)
LOCAL nTotalNeto

nTotalNeto:= IF(base:siniva,base:precossiva,base:precossiva/(1+oQry3:tasa/100))
nTotalNeto:= nTotalNeto - nTotalNeto * (base:desc1/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (base:desc2/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (base:desc3/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (base:desc4/100)
nTotalNeto:= nTotalNeto - nTotalNeto * (base:desc5/100)

oGet[39]:cText:= nTotalNeto

RETURN .f.

*************************************************************************************************************
********* Modificar reseta del articulo 
FUNCTION Reseta(base,oForm,lReceta)
LOCAL oDlgR,oGet:=ARRAY(5),oBot:=ARRAY(5),oBrwRes,oQryRes,nPara:=base:cantprod,oQryArt,;
      nCodart:=0,cDetArt:=SPACE(30),nCantidad:=1,nTotal:=0,oFontTotal,lRta:=.F.,oError
DEFAULT lReceta := .t.      
oApp:oServer:Execute("";
    + "CREATE TEMPORARY TABLE IF NOT EXISTS reseta_temp ";
    +"( `CODART` BIGINT(14) NOT NULL,";  
    +"`DETART` VARCHAR(60) NOT NULL,";
    +"`CANTIDAD` DECIMAL(10,3) DEFAULT '0',";
    +"`PUNIT` DECIMAL(12,2) DEFAULT '0.00', ";
    +"`PTOTAL` DECIMAL(12,2) DEFAULT '0.00',";
    +"PRIMARY KEY (`CODART`)) ENGINE=INNODB DEFAULT CHARSET=utf8")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE reseta_temp")
oApp:oServer:NextResult()

oApp:oServer:Execute("INSERT INTO reseta_temp (codart,detart,cantidad,punit,ptotal) "+;
                   "(SELECT r.codusa,a.nombre,r.cantidad,a.preciocos,(r.cantidad * a.preciocos) "+;
                    "FROM ge_"+oApp:cId+"reseta r LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codusa "+;
                    "WHERE r.codart = "+ClipValue2SQL(base:codigo)+")")
oApp:oServer:NextResult()
oQryRes:= oApp:oServer:Query("SELECT * FROM reseta_temp")
oQryArt:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu"+IF(lReceta," WHERE  mprima IS TRUE",""))
nPara := IF(lReceta,nPara,1)
DEFINE FONT oFontTotal NAME "ARIAL" SIZE 12,30
DO WHILE .T.
DEFINE DIALOG oDlgR RESOURCE "RESETA" OF oForm TITLE IF(lReceta,"Receta Produccion","Stock de Otros")
  oDlgR:lHelpIcon := .f.

  REDEFINE GET oGet[1] VAR nPara     ID 100 OF oDlgR PICTURE "9999999.999" WHEN(lReceta)
  IF lReceta
      REDEFINE GET oGet[2] VAR nCodArt   ID 101 OF oDlgR PICTURE "99999999999999";
                   VALID(BuscarArt(oQryArt,oDlgR,oGet[2],oGet[3],'1','mprima') .and. oGet[03]:SetFocus() = nil );
                     ACTION (oGet[2]:cText:= 0, BuscarArt(oQryArt,oDlgR,oGet[2],oGet[3],'1','mprima')) BITMAP "BUSC1" 
     ELSE 
     REDEFINE GET oGet[2] VAR nCodArt   ID 101 OF oDlgR PICTURE "99999999999999";
               VALID(BuscarArt(oQryArt,oDlgR,oGet[2],oGet[3]));
               ACTION (oGet[2]:cText:= 0, BuscarArt(oQryArt,oDlgR,oGet[2],oGet[3])) BITMAP "BUSC1"
  ENDIF   
  REDEFINE GET oGet[3] VAR cDetArt   ID 102 OF oDlgR PICTURE "@!" WHEN(.F.)
  REDEFINE GET oGet[4] VAR nCantidad ID 103 OF oDlgR PICTURE "9999999.999" 
  REDEFINE GET oGet[5] VAR nTotal    ID 104 OF oDlgR COLOR CLR_RED , CLR_YELLOW READONLY;
                 PICTURE "999999999.99" FONT oFontTotal WHEN(.F.)

  REDEFINE XBROWSE oBrwRes DATASOURCE oQryRes;
       COLUMNS "CODART","DETART","CANTIDAD","PUNIT","PTOTAL";
       HEADERS "Codigo","Detalle Articulo","Cantidad","Precio U","Total";
       FOOTERS ;
       SIZES 80,281,60,80,80;
    ID 300 OF oDlgR 
    PintaBrw(oBrwRes,0)
    oBrwRes:aCols[5]:nFooterTypE := AGGR_SUM
    oBrwRes:MakeTotals()
    oGet[5]:cText := oBrwRes:aCols[5]:nTotal


    oBrwRes:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(EliminarItem(oQryRes,oBrwRes,oGet),;
                                   nTotal:= oBrwRes:aCols[5]:nTotal,oGet[4]:Refresh()),)}
    oDlgR:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[3]:Click,.f.) }

  REDEFINE BUTTON oBot[1] ID 200 OF oDlgR ACTION (AgregaItem(oQryRes,oBrwRes,oGet),oGet[2]:SetFocus());
          WHEN(nCantidad >0 .AND. nCodArt > 0)
  REDEFINE BUTTON oBot[2] ID 201 OF oDlgR ACTION (EliminarItem(oQryRes,oBrwRes,oGet),oGet[2]:SetFocus());
                  WHEN(oQryRes:RecCount()>0)
  REDEFINE BUTTON oBot[3] ID 202 OF oDlgR ACTION (lRta:=.t.,oDlgR:End()) 
  REDEFINE BUTTON oBot[4] ID 203 OF oDlgR ACTION (lRta:=.f.,oDlgR:End()) CANCEL
  REDEFINE BUTTON oBot[5] ID 4001 OF oDlgR ACTION(ActualizarCosto(base,nTotal,nPara))
ACTIVATE DIALOG oDlgR CENTER ON INIT oGet[1]:SetFocus()

IF !lRta
  RETURN nil 
ENDIF
IF lReceta
    base:cantprod:= nPara
    TRY
      oApp:oServer:BeginTransaction()
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"reseta WHERE codart = " +ClipValue2Sql(base:codigo))
      oApp:oServer:NextResult()
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"reseta (codart,codusa,cantidad) "+;
                           "(SELECT "+ClipValue2Sql(base:codigo)+",codart,cantidad FROM reseta_temp)")
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET cantprod = "+ClipValue2Sql(base:cantprod)+","+;
                                             "produccion = TRUE "+;
                           "WHERE codigo = "+ClipValue2Sql(base:codigo))
      oApp:oServer:CommitTransaction()
    CATCH oError
        ValidaError(oError)
      LOOP
    END TRY
   ELSE 
    TRY
      oApp:oServer:BeginTransaction()
      oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"reseta WHERE codart = " +ClipValue2Sql(base:codigo))
      oApp:oServer:NextResult()
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"reseta (codart,codusa,cantidad) "+;
                           "(SELECT "+ClipValue2Sql(base:codigo)+",codart,cantidad FROM reseta_temp)")
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET stockotro = TRUE "+;
                           "WHERE codigo = "+ClipValue2Sql(base:codigo))
      oApp:oServer:CommitTransaction()
    CATCH oError
        ValidaError(oError)
      LOOP
    END TRY
ENDIF
EXIT
ENDDO
RETURN nil

*************************************************
STATIC FUNCTION ActualizarCosto(base,nTotal,nPara)
LOCAL nCosto
nCosto:= ROUND(nTotal/nPara,2)
oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET precossiva = "+ClipValue2Sql(nCosto)+" "+;
                     "WHERE codigo = "+ClipValue2Sql(base:codigo))
base:precossiva:= nCosto

msginfo("El precio de costo del articulo ha sido actualizado con exito")
RETURN nil

*****************************************************************************************************************************
****** VALIDO EL ARTICULO Y BUSCO LA RESETA 
STATIC FUNCTION ValidaArtR(nCodArt,oGet, oDlg)
LOCAL oQryValid:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"articu WHERE codigo = "+ ClipValue2Sql(nCodArt)+" and mprima = TRUE")
IF oQryValid:RecCount() > 0 
   oGet[03]:cText:= oQryValid:nombre 
ELSE
   BuscarArt(oQryValid,oDlg,oGet[02],oGet[03],"TRUE","mprima")
ENDIF
RETURN .t.


************************************************************************************
** Agregar item al detalle
STATIC FUNCTION AgregaItem(oQryRes,oBrwRes,oGet)
LOCAL oError
TRY
  oApp:oServer:BeginTransaction()
oApp:oServer:Execute("INSERT INTO reseta_temp (codart,detart,cantidad,punit,ptotal) "+;
                   "(SELECT "+ClipValue2SQL(oGet[2]:cText)+",a.nombre,"+ClipValue2Sql(oGet[4]:cText)+;
                   ",a.preciocos,"+ClipValue2Sql(oGet[4]:cText)+"*a.preciocos "+;
                    "FROM ge_"+oApp:cId+"articu a WHERE codigo = "+ClipValue2Sql(oGet[2]:cText)+")")
CATCH oError
    ValidaError(oError)
END TRY
oQryRes:Refresh()
oBrwRes:Refresh()
oBrwRes:MakeTotals()
oGet[5]:cText := oBrwRes:aCols[5]:nTotal
RETURN nil

************************************************************************************
** Borrar item del detalle
STATIC FUNCTION EliminarItem(oQryRes,oBrwRes,oGet)
oQryRes:DELETE()
oBrwRes:Refresh()
oQryRes:Refresh()
oBrwRes:Maketotals()  
oGet[5]:cText := oBrwRes:aCols[5]:nTotal
RETURN .t.


*************************************************************************************************************
********* Calular precio venta
STATIC FUNCTION CalcularPrecio(oGet,base,lventa)
IF lventa
   IF oGet[46]:lChecked
      oGet[20]:cText:=base:preciocos + (base:preciocos * base:porcentaje)/100
      ELSE
      oGet[20]:cText:=INT(base:preciocos + (base:preciocos * base:porcentaje)/100)
   ENDIF     
ELSE
   IF oGet[46]:lChecked
      oGet[19]:cText:=base:preciocos + (base:preciocos * base:porcentajerev)/100
      ELSE
      oGet[19]:cText:=INT(base:preciocos + (base:preciocos * base:porcentajerev)/100)
   ENDIF     
ENDIF
RETURN .t.


***********************************************************************************
******** Duplicar registro
STATIC FUNCTION Duplicar()
LOCAL oGet := ARRAY(54), oBot := ARRAY(8), oForm, lRta := .F., aCor, base, cProve:=SPACE(30), nNeto,;
      cIvaNom:=SPACE(30), cMarc:=SPACE(30), cRub:=SPACE(30), cDept:=SPACE(30), cEmp:=SPACE(30), nIva,oError,nPrecioven:=0,;
      nova1,nova2,oSay:=ARRAY(8),oGru:=ARRAY(2)
 
oQry:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
   base := oQry:GetRowObj()
   oQry2:GoTop()
   IF oQry2:Seek(base:prov,1) > 0
      cProve := oQry2:nombre
   ENDIF
   oQry3:GoTop()
   IF oQry3:Seek(base:iva,1) > 0
      cIvaNom := STR(oQry3:tasa,6,2) + "%"
   ENDIF
   oQry4:GoTop()
   IF oQry4:Seek(base:marca,1) > 0
      cMarc := oQry4:nombre
   ENDIF
   oQry5:GoTop()
   IF oQry5:Seek(base:rubro,1) > 0
      cRub := oQry5:nombre
   ENDIF
   oQry6:GoTop() 
   IF oQry6:Seek(base:depto,1) > 0
      cDept := oQry6:nombre
   ENDIF
   oQry7:GoTop()
   IF oQry7:Seek(base:empresa,1) > 0
      cEmp := oQry7:nombre
   ENDIF   
   base:nombre:=SPACE(50)
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"articu")
   base:stockotro := .f.
   

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Duplicado de Articulo" RESOURCE "ABMART1" OF oWnd1
 oForm:lHelpIcon := .f.
 
REDEFINE GET oGet[01] VAR base:codigo PICTURE "99999999999999" ID 100 OF oForm 
  REDEFINE GET oGet[02] VAR base:nombre PICTURE "@!" ID 101 OF oForm ;
               VALID(base:nombre<>space(30))
  REDEFINE GET oGet[03] VAR base:nomregi ID 102 OF oForm  PICTURE "@!"
  REDEFINE SAY oSay[8] ID 4002 OF oForm
  REDEFINE GET oGet[51] VAR base:codigopro ID 4017 OF oForm PICTURE "@!"
  REDEFINE CHECKBOX oGet[46] VAR base:endolares   ID 4012 OF oForm
  REDEFINE CHECKBOX oGet[52] VAR base:pesable ID 4011 OF oForm 
  REDEFINE CHECKBOX oGet[34] VAR base:nosale ID 103 OF oForm 

  REDEFINE GROUP oGru[1] ID 401 OF oForm
  REDEFINE CHECKBOX oGet[44] VAR base:mprima      ID 4007 OF oForm
  REDEFINE CHECKBOX oGet[45] VAR base:produccion  ID 4008 OF oForm
  REDEFINE BUTTON oBot[3] ID 4009 OF oForm ACTION (Reseta(base,oForm),oGet[06]:Refresh()) WHEN (base:produccion)
  

  REDEFINE GET oGet[04] VAR base:prov ID 104 OF oForm PICTURE "99999";
                VALID(Buscar(oQry2,oForm,oGet[4],oGet[5]));
                ACTION (oGet[04]:cText:= 0, Buscar(oQry2,oForm,oGet[4],oGet[5])) BITMAP "BUSC1"
  REDEFINE GET oGet[05] VAR cProve          ID 105 OF oForm WHEN (.F.)
  REDEFINE GET oGet[21] VAR base:marca      ID 122 OF oForm PICTURE "9999";
               VALID(Buscar(oQry4,oForm,oGet[21],oGet[22]));
               ACTION (oGet[21]:cText:= 0, Buscar(oQry4,oForm,oGet[21],oGet[22])) BITMAP "BUSC1"
  REDEFINE GET oGet[22] VAR cMarc           ID 123 OF oForm WHEN (.F.)
  REDEFINE GET oGet[23] VAR base:rubro      ID 124 OF oForm PICTURE "9999";
               VALID(Buscar(oQry5,oForm,oGet[23],oGet[24]));
               ACTION (oGet[23]:cText:= 0, Buscar(oQry5,oForm,oGet[23],oGet[24])) BITMAP "BUSC1"
  REDEFINE GET oGet[24] VAR cRub            ID 125 OF oForm WHEN (.F.)
  REDEFINE GET oGet[27] VAR base:empresa    ID 126 OF oForm PICTURE "9999";
               VALID(Buscar(oQry7,oForm,oGet[27],oGet[28]));
               ACTION (oGet[27]:cText:= 0, Buscar(oQry7,oForm,oGet[27],oGet[28])) BITMAP "BUSC1"
  REDEFINE GET oGet[28] VAR cEmp            ID 127 OF oForm WHEN (.F.)
  REDEFINE GET oGet[25] VAR base:depto      ID 128 OF oForm PICTURE "9999";
               VALID(Buscar(oQry6,oForm,oGet[25],oGet[26]));
               ACTION (oGet[25]:cText:= 0, Buscar(oQry6,oForm,oGet[25],oGet[26])) BITMAP "BUSC1"
  REDEFINE GET oGet[26] VAR cDept           ID 129 OF oForm WHEN (.F.)

  REDEFINE BUTTON oBot[4] ID 301 OF oForm ACTION AltaMar()
  REDEFINE BUTTON oBot[5] ID 302 OF oForm ACTION AltaRub()
  REDEFINE BUTTON oBot[6] ID 303 OF oForm ACTION AltaEmp()
  REDEFINE BUTTON oBot[7] ID 304 OF oForm ACTION AltaDep()


  REDEFINE GROUP oGru[2] ID 402 OF oForm
  REDEFINE SAY oSay[3] ID 4066 OF oForm 
  REDEFINE SAY oSay[4] ID 4067 OF oForm
  REDEFINE SAY oSay[5] ID 4069 OF oForm
  REDEFINE SAY oSay[6] ID 4070 OF oForm
  REDEFINE SAY oSay[7] ID 4071 OF oForm
  REDEFINE GET oGet[35] VAR base:unimed     ID 135 OF oForm PICTURE "@!"
  REDEFINE GET oGet[47] VAR base:medida     ID 500 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[48] VAR base:entero     ID 501 OF oForm PICTURE "9999999"
  REDEFINE GET oGet[49] VAR base:uxbulto    ID 502 OF oForm PICTURE "99999"
  REDEFINE GET oGet[50] VAR base:pxbulto    ID 503 OF oForm PICTURE "999999999.99";
               VALID((oGet[06]:cText:= (base:pxbulto/base:uxbulto)) <> "xxx")


  REDEFINE CHECKBOX oGet[46] VAR base:siniva  ID 4003 OF oForm
  REDEFINE GET oGet[06] VAR base:precossiva ID 106 OF oForm PICTURE "999999999.99" 
  REDEFINE GET oGet[07] VAR base:desc1      ID 107 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[08] VAR base:desc2      ID 108 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[09] VAR base:desc3      ID 109 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[10] VAR base:desc4      ID 110 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[11] VAR base:desc5      ID 111 OF oForm PICTURE "999.99"  
  REDEFINE GET oGet[39] VAR nNeto           ID 112 OF oForm PICTURE "999999999.99";
           WHEN(CalcularNeto(base,oGet))
           
  REDEFINE GET oGet[12] VAR base:impint     ID 113 OF oForm PICTURE "999.99"
  REDEFINE GET oGet[13] VAR base:flete      ID 114 OF oForm PICTURE "99999.9"
  REDEFINE GET oGet[14] VAR base:iva        ID 115 OF oForm PICTURE "99";
               VALID(Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx");
               ACTION  (oGet[14]:cText:= 0, (Buscar(oQry3,oForm,oGet[14]) .and. ;             
               (oGet[15]:cText := STR(oQry3:tasa,6,2) + "%") <> "xxx")) BITMAP "BUSC1"
  REDEFINE GET oGet[15] VAR cIvaNom         ID 116 OF oForm WHEN (.F.)
  REDEFINE GET oGet[16] VAR base:preciocos  ID 117 OF oForm PICTURE "999999999.99";
                        WHEN((oGet[16]:cText:= nNeto + base:impint +;
                        nNeto * (base:flete/100) + ((nNeto * oQry3:tasa )/100)) = "-999999")
  REDEFINE GET oGet[17] VAR base:porcentaje ID 118 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.t.))
  REDEFINE GET oGet[18] VAR base:porcentajerev  ID 119 OF oForm PICTURE "999.99";
               VALID(CalcularPrecio(oGet,base,.f.))
  REDEFINE GET oGet[19] VAR base:reventa    ID 120 OF oForm PICTURE "999999999.99"
  REDEFINE GET oGet[20] VAR base:precioven  ID 121 OF oForm PICTURE "999999999.99"
  
  
    //FECHAS
  REDEFINE SAY oSay[1] ID 801 OF oForm 
  REDEFINE GET oGet[41] VAR nova1          ID 1300 OF oForm
  REDEFINE GET oGet[29] VAR base:fecultcom ID 130 OF oForm WHEN(.F.)
  REDEFINE GET oGet[30] VAR base:fecmod    ID 131 OF oForm WHEN (.F.)
  REDEFINE SAY oSay[2] ID 804 OF oForm
  REDEFINE GET oGet[42] VAR nova2          ID 1311 OF oForm


  REDEFINE GET oGet[31] VAR base:stockmin   ID 132 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[32] VAR base:stockact   ID 133 OF oForm PICTURE "99999999.99"
  REDEFINE GET oGet[33] VAR base:stockide   ID 134 OF oForm PICTURE "99999999.99"
  REDEFINE CHECKBOX oGet[53] VAR base:stockotro  ID 4005 OF oForm WHEN(.f.)
  REDEFINE BUTTON oBot[8] ID 4015 OF oForm ACTION (Reseta(base,oForm,.f.)) WHEN (.f.)

  REDEFINE GET oGet[54] VAR base:condicioncompra   ID 4020 OF oForm 

  REDEFINE GET oGet[36] VAR base:observa    ID 136 OF oForm PICTURE "@!"

  REDEFINE BUTTON oBot[1] ID 137 OF oForm;
           ACTION ((lRta := .t.), oForm:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oForm;
           ACTION ((lRta := .f.), oForm:End() ) CANCEL
 
ACTIVATE DIALOG oForm CENTER ON INIT (oGet[02]:SetFocus(),EsconderPermisos(oGet,oSay,oGru,oBot))


IF !lRta
   RETURN nil
ENDIF
base:fecmod:= DATE() 
base:horamod:= TIME()     
oQry:GetBlankRow()
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh()
  oQryBrw:Refresh(.f.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


******************************************
** Calculo del precio de venta
STATIC FUNCTION calcupre(lis,costo,marca,codiva)
LOCAL iv, precio, por,oQryAux
oQryAux:=oApp:oServer:Query("SELECT tasa FROM ge_"+oApp:cId+"ivas WHERE codigo = " + ClipValue2Sql(codiva))
IF oQryAux:RecCount()>0
 iv:=oQryAux:tasa   
 por    := marca
 precio := costo  + costo  * iv/100    && calculo % iva
 precio := precio + precio * por/100   && calculo % ganancia segun lista
ELSE
 precio:=0
ENDIF
RETURN ROUND(precio,3)




*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar (  )
LOCAL aNueva := {}, i, j
oQryBrw:End()
RELEASE oQryBrw
RELEASE oQry2
oQry2:End()
RELEASE oQry3
oQry3:End()
RELEASE oQry4
oQry4:End()
RELEASE oQry5
oQry5:End()
RELEASE oQry6
oQry6:End()
RELEASE oQry7
oQry7:End()
  

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
IF oApp:oServer:Query("SELECT COUNT(codart) as casos FROM ge_"+oApp:cId+"ventas_det WHERE codart = "+str(nNum)):casos > 0
   MsgStop("No puede borrar este articulo porque tiene"+CHR(10)+;
                 "ventas asociadas","Atencion")
   RETURN nil 
ENDIF
IF oApp:oServer:Query("SELECT COUNT(codart) as casos FROM ge_"+oApp:cId+"reseta "+;
          " WHERE codart = "+str(nNum)+" OR codusa = "+str(nNum)):casos > 0
   MsgStop("No puede borrar este articulo porque tiene"+CHR(10)+;
                 "recetas asociadas","Atencion")
   RETURN nil 
ENDIF
IF oApp:oServer:Query("SELECT COUNT(codart) as casos FROM ge_"+oApp:cId+"remitos WHERE facturado is false and codart = "+str(nNum)):casos > 0
   MsgStop("No puede borrar este articulo porque tiene"+CHR(10)+;
                 "remitos asociados","Atencion")
   RETURN nil 
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY

  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"articu WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
  oApp:oServer:Execute("DELETE FROM  ge_"+oApp:cId+"gruposdet WHERE codart = "+ClipValue2SQL(oQryBrw:codigo))
  oApp:oServer:Execute("DELETE FROM  ge_"+oApp:cId+"lispredet WHERE codart = "+ClipValue2SQL(oQryBrw:codigo))
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)

CATCH oError
    ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 

***********************************************************************************
******* Mostrar historial de precios
STATIC FUNCTION Historial()
LOCAL oDlgH,oBot,oBrwH,oQryHist,oGet1,oGet2
oQryHist:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"campre WHERE codigo = " + ClipValue2Sql(oQryBrw:codigo))
DEFINE DIALOG oDlgH TITLE "Historial de precios" FROM 05,15 TO 23,82;
       OF oWnd1 ICON oApp:oIco
   oDlgH:lHelpIcon := .f.
   @ 07,05 SAY "Artículo:" OF oDlgH PIXEL   
   @ 05,30 GET oGet1 VAR oQryBrw:codigo OF oDlgH PIXEL PICTURE "99999999999999" RIGHT WHEN(.F.)
   @ 05,85 GET oGet2 VAR oQryBrw:nombre OF oDlgH PIXEL PICTURE "@!"     WHEN(.F.)
   @ 25,02 XBROWSE oBrwH DATASOURCE oQryHist ;
           COLUMNS "ID","fecmod","precossiva","preciocos","precioven","reventa","usuario","ip";
           HEADERS "ID","Fecha","Precio S/IVA","Precio Costo","Precio Venta 1","Precio Venta 2","Cambió","Motivo";
           SIZES   68,75,80,80,80,80,60,100;
           OF oDlgH SIZE 260, 88 AUTOSORT PIXEL
   oBrwH:CreateFromCode()  
   PintaBrw(oBrwH,0) 
   @ 120,115 BUTTON oBot PROMPT "&OK" OF oDlgH PIXEL SIZE 30,10 ACTION oDlgH:End()
ACTIVATE DIALOG oDlgH CENTER ON INIT oGet1:SetFocus()
RETURN nil
*************************************

****************************************FILTRADO**********************
STATIC FUNCTION FILT( )
LOCAL vMarca,cMarc:=SPACE(30),vRubro,cRub:=SPACE(30),vempresa,cEmp:=SPACE(30),;
      vdepto,cDept:=SPACE(30),vProv,cProve:=SPACE(30),vcodigo,cNomArt:=SPACE(30),vnosale:=.t., vtipo := nActivos,;
      aTipo := {"Todos","Vendibles","No Vendibles"},;
      vnombre:=SPACE(30),vnomregi:=SPACE(30),vstockmin,vstockact,vstockide,vReventa,;
      vpreciocos,viva,cNomIva:=SPACE(30),vdesc1,vdesc2,vdesc3,vdesc4,vdesc5,;
      vprecioven,vpresugeri,vprecossiva,vpreciopro,vporcentaje,vfecmodd:="  /  /    ",vfecmodh:="  /  /    ",;
      vfecultcomd:="  /  /    ",vfecultcomh:="  /  /    ",oSay1,oSay2,;
      vneto,vimpint,vflete,vunimed,vobserva,cIvaNom:=SPACE(30),;
      oFilt, acor:=ARRAY(4), oBot:=ARRAY(4), lRta:=.f., oGet:=ARRAY(53),;
      vpesable:=.f.,vcombustible:=.f.,vmprima:=.f.,vproduccion:=.f.,;
      vmedida,ventero,vuxbulto,vpxbulto,vsiniva:=.f.,vcodigopro:=SPACE(30), vstockotro := .f.

oQryArt:=oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu ORDER BY codigo ")

DO WHILE .T.
DEFINE DIALOG oFilt TITLE "Filtrado de Articulo" RESOURCE "ABMART1" OF oWnd1
 oFilt:lHelpIcon := .f.
 
  REDEFINE GET oGet[01] VAR vcodigo ID 100 OF oFilt 
  REDEFINE GET oGet[02] VAR vnombre PICTURE "@!" ID 101 OF oFilt 
  REDEFINE GET oGet[03] VAR vnomregi ID 102 OF oFilt 
  REDEFINE CHECKBOX oGet[34] VAR vnosale ID 103 WHEN(.F.)
  REDEFINE CHECKBOX oGet[46] VAR vpesable ID 4011 OF oFilt 
  REDEFINE GET oGet[51] VAR vcodigopro ID 4017 OF oFilt PICTURE "@!"
  REDEFINE BUTTON oBot[4] ID 4009 OF oFilt ACTION CambiaFilt(oGet[34], aTipo,@vTipo)


  REDEFINE CHECKBOX oGet[44] VAR vmprima      ID 4007 OF oFilt
  REDEFINE CHECKBOX oGet[45] VAR vproduccion  ID 4008 OF oFilt

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
  REDEFINE GET oGet[50] VAR vpxbulto    ID 503 OF oFilt PICTURE "999999999.99"


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
  REDEFINE GET oGet[19] VAR vreventa ID 120 OF oFilt 
  REDEFINE GET oGet[20] VAR vprecioven ID 121 OF oFilt 
  

  //FECHAS
  REDEFINE GET oGet[41] VAR vfecultcomd ID 1300 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay1 PROMPT "Hasta última compra:" ID 802 OF oFilt
  REDEFINE GET oGet[29] VAR vfecultcomh ID 130 OF oFilt PICTURE "@D"
  REDEFINE SAY oSay2 PROMPT "Desde cambio precio:" ID 803 OF oFilt
  REDEFINE GET oGet[30] VAR vfecmodd    ID 131 OF oFilt PICTURE "@D"
  REDEFINE GET oGet[42] VAR vfecmodh    ID 1311 OF oFilt PICTURE "@D"

  REDEFINE GET oGet[31] VAR vstockmin ID 132 OF oFilt
  REDEFINE GET oGet[32] VAR vstockact ID 133 OF oFilt
  REDEFINE GET oGet[33] VAR vstockide ID 134 OF oFilt
  REDEFINE CHECKBOX oGet[53] VAR vstockotro  ID 4005 OF oFilt 
  REDEFINE BUTTON oBot[3] ID 4015 OF oFilt WHEN(.f.)
  REDEFINE GET oGet[36] VAR vobserva  ID 136 OF oFilt

  REDEFINE BUTTON oBot[1] ID 137 OF oFilt;
           ACTION ((lRta := .t.), oFilt:End() )
  REDEFINE BUTTON oBot[2] ID 138 OF oFilt PROMPT "Quita Filt.";
           ACTION ((lRta := .f.), oFilt:End() ) CANCEL
 
ACTIVATE DIALOG oFilt CENTER ON INIT (oBot[4]:SetText ("Camb. tipo"),oGet[01]:SetFocus(),oGet[34]:SetText (aTipo[vtipo]))

IF !lRta
   nActivos:= 1
   cWhere:=""
   oQryBrw:SetNewFilter(SET_WHERE,"1=1",.t.)
   oBrw:Refresh()
   RETURN nil
ENDIF

nActivos:= vTipo

cWhere = " 1=1 " + IF(EMPTY(vCodigo),""," and a.CODIGO =" + ClipValue2SQL(VCodigo) + "") ;
            + "" + IF(EMPTY(VNOMBRE),"","  and TRIM(a.NOMBRE) like '%" + ALLTRIM(VNOMBRE) + "%'") ;
            + "" + IF(EMPTY(Vnomregi),"","  and TRIM(a.nomregi) like '%" + ALLTRIM(Vnomregi) + "%'") ;
            + "" + IF(EMPTY(vcodigopro),"","  and TRIM(a.codigopro) like '%" + ALLTRIM(vcodigopro) + "%'") ;
            + "" + IF(nActivos=1,"",IF(nActivos=2," and a.nosale IS FALSE "," and a.nosale IS TRUE "));
            + "" + IF(!vpesable,""," and a.pesable = TRUE ");
            + "" + IF(!vcombustible,""," and a.combustible = TRUE");
            + "" + IF(!vmprima,""," and a.mprima = TRUE ");
            + "" + IF(!vproduccion,""," and a.produccion = TRUE ");
            + "" + IF(!vstockotro,""," and a.stockotro = TRUE ");
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
            + "" + IF(EMPTY(vunimed),"","  and a.TRIM(unimed) like '%" + ALLTRIM(vunimed) + "%'");
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
            + "" + IF(EMPTY(vpreciopro),""," and a.porcentajeven =" + ClipValue2SQL(vpreciopro) + "") ; 
            + "" + IF(EMPTY(vreventa),""," and a.reventa =" + ClipValue2SQL(vreventa) + "") ; 
            + "" + IF(vfecultcomd="  /  /    ",""," and a.fecultcom >" + ClipValue2SQL(CTOD(vfecultcomd)) + "") ;
            + "" + IF(vfecultcomh="  /  /    ",""," and a.fecultcom <" + ClipValue2SQL(CTOD(vfecultcomh)) + "") ;
            + "" + IF(vfecmodd="  /  /    ",""," and a.fecmod >" + ClipValue2SQL(CTOD(vfecmodd)) + "") ;
            + "" + IF(vfecmodh="  /  /    ",""," and a.fecmod <" + ClipValue2SQL(CTOD(vfecmodh)) + "") ;
            + "" + IF(EMPTY(vobserva),"","  and TRIM(a.observa) like '%" + ALLTRIM(vobserva) + "%'") ;

            
EXIT
ENDDO
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Refresh()
RETURN nil

*******************************
** 
STATIC FUNCTION CambiaFilt(oGet, aTipo,vTipo)
vTipo ++
vTipo := if(vtipo>3,1,vtipo)
oGet:SetText(aTipo[vTipo])
RETURN nil


**** Filrado por tipo de articulos
STATIC FUNCTION FiltrarVen(lTipo)
lTipoArt := lTipo
IF lTipo = nil 
   nActivos:=1
   oQryBrw:SetNewFilter(SET_WHERE,"",.t.)
   oWnd1:cTitle("A/B/M de Articulos: TODOS los articulos")
ENDIF
IF lTipo = .t. 
   nActivos:=2
   oQryBrw:SetNewFilter(SET_WHERE,"a.NOSALE IS FALSE",.t.)
   oWnd1:cTitle("A/B/M de Articulos: Solo articulos vendibles")
ENDIF
IF lTipo = .f. 
   nActivos:=3
   oQryBrw:SetNewFilter(SET_WHERE,"a.NOSALE IS TRUE",.t.)
   oWnd1:cTitle("A/B/M de Articulos: Solo articulos NO VENDIBLES")
ENDIF
oBrw:Refresh()
RETURN nil

***************************************
** Formulario de altas y modificaciones
FUNCTION AltaMar(oForm1)
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,poriva,oQryM
   oQryM:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"marcas")
   base := oQryM:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"marcas")

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Alta de Marca";
       FROM 05,15 TO 13,65 OF oForm1
   
   @ 07, 05 SAY "Codigo:"                     OF oForm PIXEL SIZE 50,20 RIGHT
   @ 22, 05 SAY "Nombre:"                OF oForm PIXEL SIZE 50,20 RIGHT
  
   @ 05, 65 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 20, 65 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(30))         
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:codigo = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQryM:GetBlankRow()
oQryM:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryM:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


***************************************
** Formulario de altas y modificaciones
FUNCTION AltaRub(oForm1)
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oError,cNomDep:=SPACE(30),oQryR
   oQryR:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"rubros")
   base := oQryR:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"rubros")

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Alta de Rubros";
       FROM 05,15 TO 15,67 OF oForm1
   
   @ 07, 05 SAY "Codigo:"                OF oForm PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Nombre:"                OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Departamento:"          OF oForm PIXEL SIZE 50,12 RIGHT
  
   @ 05, 60 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 20, 60 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(30))     
   @ 35, 60 GET oGet[3] VAR base:depto  PICTURE "9999" RIGHT OF oForm SIZE 25,12 PIXEL;
                VALID(Buscar(oQry6,oForm,oGet[03],oGet[04]));
                ACTION (oGet[03]:cText:= 0, Buscar(oQry6,oForm,oGet[03],oGet[04])) BITMAP "BUSC1" 
   @ 35, 90 GET oGet[4] VAR cNomDep    PICTURE "@!" OF oForm PIXEL WHEN(.F.)   
   
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:codigo = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQryR:GetBlankRow()
oQryR:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryR:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


***************************************
** Formulario de altas y modificaciones
FUNCTION AltaEmp(oForm1)
LOCAL oGet := ARRAY(3), oBot := ARRAY(2), oForm, lRta := .f., aCor, base,oQryE,oError

   oQryE:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"empresas")
   base := oQryE:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"empresas")

DO WHILE .T.
DEFINE DIALOG oForm TITLE "Alta de Empresas de articulos";
       FROM 05,15 TO 12,60 OF oForm1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Código:"   OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Nombre:"   OF oForm PIXEL SIZE 40,12 RIGHT
 
   @ 05, 50 GET oGet[1] VAR base:codigo   OF oForm PICTURE "9999" PIXEL RIGHT WHEN(.F.)
   @ 20, 50 GET oGet[2] VAR base:nombre   OF oForm PICTURE "@!" PIXEL 
 
 @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[2]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:codigo = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQryE:GetBlankRow()
oQryE:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryE:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil


***************************************
** Formulario de altas y modificaciones
FUNCTION AltaDep(oForm1)
LOCAL oGet := ARRAY(5), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, cNomIva:=SPACE(25),;
      oQryIva, oChe,oQryD, oError
   oQryIva:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"ivas")
   oQryD  := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"deptos")
   base := oQryD:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"deptos")

DO WHILE .T.

DEFINE DIALOG oForm TITLE "Alta de Departametos de articulos";
       FROM 05,15 TO 12,60 OF oForm1
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Código:"          OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Nombre:"          OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Nombre resumido:" OF oForm PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "I.V.A:"           OF oForm PIXEL SIZE 40,12 RIGHT
 

   @ 05, 50 GET oGet[1] VAR base:codigo   OF oForm PICTURE "9999" PIXEL RIGHT WHEN(.F.)
   *@ 05, 80 CHECKBOX oChe VAR base:talon  OF oForm PIXEL PROMPT "Pide talon" SIZE 60,12
   @ 20, 50 GET oGet[2] VAR base:nombre   OF oForm PICTURE "@!" PIXEL;
                VALID(base:nombre <> SPACE(30))
  /* @ 35, 50 GET oGet[3] VAR base:resumido OF oForm PICTURE "@!" PIXEL;
                VALID(base:resumido <> SPACE(15))
   @ 50, 50 GET oGet[4] VAR base:iva      OF oForm PICTURE "99" PIXEL RIGHT SIZE 25,12;
                VALID(Buscar(oQryIva,oForm,oGet[4],oGet[5]));
                ACTION (oGet[04]:cText:= 0, Buscar(oQryIva,oForm,oGet[4],oGet[5])) BITMAP "BUSC1"
   @ 50, 80 GET oGet[5] VAR cNomIva       OF oForm PICTURE "@!" PIXEL WHEN(.F.)
 */
 @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[2]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF base:codigo = 0 
   MsgStop("Valores no validos","Error")
   LOOP
ENDIF
oQryD:GetBlankRow()
oQryD:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryD:Save()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

************************************************************************************************************
********* FUNCION QUE ESCONDE LOS GET DEPENDIENDO DE LA CONFIGURACION 
FUNCTION EsconderPermisos(oGet,oSay,oGru,oBot)
oGet[41]:Hide()
oGet[42]:Hide()
oSay[1]:Hide()
oSay[2]:Hide()
IF !oApp:usar_produccion
   oGru[1]:Hide()
   oGet[44]:Hide()
   oGet[45]:Hide()
   oBot[3]:Hide()
ENDIF
IF !oApp:usar_bultos
    oGru[2]:Hide() 
    oSay[3]:Hide()
    oSay[4]:Hide()
    oSay[5]:Hide()
    oSay[6]:Hide()
    oSay[7]:Hide()
    oGet[35]:Hide()
    oGet[47]:Hide()
    oGet[48]:Hide()
    oGet[49]:Hide()
    oGet[50]:Hide()
ENDIF
IF !oApp:usar_tactil 
   oGet[52]:Hide()
ENDIF
IF !oApp:usar_codpro 
   oSay[8]:Hide()
   oGet[51]:Hide()
ENDIF
               
RETURN nil 


*****************************************************************
** Importar Articulos
STATIC FUNCTION Importar()
LOCAL oDlg1, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, oBrwTmp,;
      aCols := {{0,SPACE(50),0,0,0,0,0,0,0,0,0,0,0,' '}},;
      i, cError, cSql, nDePro := 1, oChe
DO WHILE .T.       
DEFINE DIALOG oDlg1 TITLE "Importar Articulos" FROM 03,15 TO 35,140
   acor := AcepCanc(oDlg1)    
   @ 20, 05 XBROWSE oBrwTmp SIZE 465,180 pixel OF oDlg1 ARRAY aCols ;
      HEADERS "Codigo", "Descripcion","Costo","Utilidad","Precio Venta","Stock","Prov","Depto","Rubro","Marca","IVA","Utilidad 2","P.Venta 2","Cod.Prov";
      COLUMNS 1, 2 ,3, 4, 5,6,7,8,9,10,11,12,13,14;
      SIZES 60,250,50,50,50,50,50,50,50,50,50,50,50,90;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwTmp
      :nEditTypes := 1  
      :bKeyDown := { |nKey| IF (nKey == VK_DELETE,oBrwTmp:Delete(),)}    
      :CreateFromCode()
   END  
   @ 205,05 SAY "Use el boton PEGAR para incluir los datos o edite manualmente los campos. "+;
                "Tenga en cuenta que el codigo de articulo no puede estar ya en la base de datos"+;
                " y que la tasa de IVA tiene que ser 5 (21%) o 4 (10.5%). Si no"+;
                " tiene los codigos de proveedor, rubro, marca, etc. el programa los "+;
                "pondra en 1. Los precios, porcentaje y stock tienen que ser ENTEROS" SIZE 465,60 OF oDlg1 PIXEL 
   PintaBrw(oBrwTmp,0)
   @ 02, 02 BUTTON oBot1 PROMPT "&Pegar" OF oDlg1 SIZE 30,10 ;
           ACTION (Procesando(.t.),oBrwTmp:Paste(),Procesando(.f.)) PIXEL
   @ 02, 100 COMBOBOX oChe VAR nDePro ITEMS {"Asigna Cod. proveedor a articulo","Asignar código proveedor al proveedor","Asignar a Ambos"} OF oDlg1 SIZE 120,10 PIXEL         
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
    IF aCols[i,3] = 0
       AADD(cError,"Columna 3 en posicion " + STR(i,6) + " no puede estar en cero ")
    ENDIF    
    IF aCols[i,5] = 0
       //AADD(cError,"Columna 5 en posicion " + STR(i,6) + " no puede estar en cero ")
       aCols[i,5] := INT(aCols[i,3] * IF(aCols[i,11] = 5,1.21,1.105) * (1 + aCols[i,4]/100))
    ENDIF
    IF aCols[i,11] <> 5 .AND. aCols[i,11] <> 4 .AND. aCols[i,11] <> 0
       AADD(cError,"Columna 11 en posicion " + STR(i,6) + " solo valores de 4 a 5 ")
    ENDIF
    IF aCols[i,13] = 0
       //AADD(cError,"Columna 5 en posicion " + STR(i,6) + " no puede estar en cero ")
       aCols[i,13] := INT(aCols[i,3] * IF(aCols[i,11] = 5,1.21,1.105) * (1 + aCols[i,12]/100))
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
FOR i := 1 TO LEN(aCols)
    IF aCols[i,7] = 0
       aCols[i,7] := 1
    ENDIF
    IF aCols[i,8] = 0
       aCols[i,8] := 1
    ENDIF
    IF aCols[i,9] = 0
       aCols[i,9] := 1
    ENDIF
    IF aCols[i,10] = 0
       aCols[i,10] := 1
    ENDIF
    IF aCols[i,11] = 0
       aCols[i,11] := 5
    ENDIF
NEXT
cSql := "INSERT INTO ge_"+oApp:cId+"articu "+;
        " (codigo,nombre,nomregi,nosale,prov,precossiva,iva,preciocos,porcentaje,"+;
        " precioven,marca,rubro,empresa,depto,fecmod,stockact,siniva,porcentajerev,reventa,codigopro) VALUES "
FOR i := 1 TO LEN(aCols)
    cSql := cSql + "("+ClipValue2SQL(aCols[i,1]) + "," + ;
                       ClipValue2SQL(aCols[i,2]) + "," + ;
                       ClipValue2SQL(LEFT(aCols[i,2],15)) + "," + ;
                       "FALSE,"+;
                       ClipValue2SQL(aCols[i,7]) + "," + ;
                       ClipValue2SQL(aCols[i,3]) + "," + ;
                       ClipValue2SQL(aCols[i,11]) + "," + ;
                       ClipValue2SQL(aCols[i,3]) + "," + ;
                       ClipValue2SQL(aCols[i,4]) + "," + ;
                       ClipValue2SQL(aCols[i,5]) + "," + ;
                       ClipValue2SQL(aCols[i,10]) + "," + ;
                       ClipValue2SQL(aCols[i,9]) + "," + ;
                       "1," + ;
                       ClipValue2SQL(aCols[i,8]) + "," + ;
                       ClipValue2SQL(DATE()) + "," + ;
                       ClipValue2SQL(aCols[i,6]) + "," + ;
                       "TRUE,"+;
                       ClipValue2SQL(aCols[i,12]) + "," + ;
                       ClipValue2SQL(aCols[i,13]) + "," + ;
                       IF(nDePro=2,'" "', ClipValue2SQL(aCols[i,14])) + "), "
NEXT i
cSql := LEFT(cSql,LEN(cSql)-2)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute(cSql)
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.f.)
CATCH cError
  MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
  oApp:oServer:RollBack()
  RETURN nil
END TRY    
IF nDePro > 1
    cSql := "INSERT INTO ge_"+oApp:cId+"codpro "+;
        " (codpro,codart,codarp) VALUES "
    FOR i := 1 TO LEN(aCols)
        IF !EMPTY(aCols[i,14])
           cSql := cSql + "("+ClipValue2SQL(aCols[i,7]) + "," + ;
                           ClipValue2SQL(aCols[i,1]) + "," + ;
                           ClipValue2SQL(aCols[i,14]) + "), "
        ENDIF                    
    NEXT i
    cSql := LEFT(cSql,LEN(cSql)-2)
    TRY
      oApp:oServer:BeginTransaction()
      oApp:oServer:Execute(cSql)
      oApp:oServer:CommitTransaction()
      oQryBrw:Refresh(.f.)
    CATCH cError
      MsgStop("Error al Importar"+CHR(10)+cError:description,"Error")
      oApp:oServer:RollBack()
      RETURN nil
    END TRY    
ENDIF
RETURN nil


*************************************************
*** Cambiar el codigo del producto
STATIC FUNCTION Cambiar()
LOCAL oDlgH, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, nCodNue := 0,;
      i, oError, cSql, oGet1, oGet2       
DEFINE DIALOG oDlgH TITLE "Cambiar Codigo de Articulos" FROM 03,15 TO 14,55
   acor := AcepCanc(oDlgH)    
   @ 07,05 SAY "Codigo a Cambiar:" OF oDlgH SIZE 60,12 PIXEL RIGHT
   @ 22,05 SAY "Nuevo Código:"     OF oDlgH SIZE 60,12 PIXEL RIGHT
   @ 05,70 GET oGet1 VAR oQryBrw:codigo OF oDlgH PIXEL PICTURE "99999999999999" RIGHT WHEN(.F.)
   @ 20,70 GET oGet2 VAR nCodNue        OF oDlgH PIXEL PICTURE "99999999999999" RIGHT VALID(nCodNue>0)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Cambiar" OF oDlgH SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlgH:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgH SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlgH:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgH CENTER 
IF !mrta 
   RETURN nil 
ENDIF   
** Valido que no exista 
IF nCodNue = oQryBrw:codigo 
   RETURN nil 
ENDIF 
IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"articu WHERE codigo = " +ClipValue2Sql(nCodNue)):nRecCount > 0
   MsgStop("Ese codigo ya existe para otro articulo","Error")
   RETURN nil 
ENDIF
Procesando(.t.)
TRY 
   oApp:oServer:BeginTransaction() 
   *** Cambio el codigo 
   oApp:oServer:Execute("SET FOREIGN_KEY_CHECKS = 0")
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu SET codigo = "+ClipValue2SQL(nCodNue)+;
       " WHERE codigo = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_det SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"campre SET codigo = "+ClipValue2SQL(nCodNue)+;
       " WHERE codigo = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"codpro SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"compradet SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"gruposdet SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"lispredet SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedprov_det SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"remitos SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"reseta SET codusa = "+ClipValue2SQL(nCodNue)+;
       " WHERE codusa = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"ventas_det_p SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"stoman SET codart = "+ClipValue2SQL(nCodNue)+;
       " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   IF oApp:oServer:TableExist("ge_"+oApp:cId+"pedidos_det")
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"pedidos_det SET codart = "+ClipValue2SQL(nCodNue)+;
          " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   ENDIF
   IF oApp:oServer:TableExist("ge_"+oApp:cId+"promociones")
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"promociones SET codart = "+ClipValue2SQL(nCodNue)+;
          " WHERE codart = "+ClipValue2Sql(oQryBrw:codigo))
   ENDIF   
   oApp:oServer:Execute("SET FOREIGN_KEY_CHECKS = 1")
   oApp:oServer:CommitTransaction()
CATCH oError
   MsgStop("Error al Cambiar"+CHR(10)+oError:description,"Error")
   oApp:oServer:RollBack()
END TRY
Procesando(.f.)
oQryBrw:Refresh()
oBrw:Refresh()
RETURN nil


**********************************************
** Buscar por codigo 
STATIC FUNCTION BuscarxCod()
LOCAL oDlgH, acor:= ARRAY(4), mrta:=.F., oBot1, oBot2, nCodNue := SPACE(30),;
      i, oError, cSql, oGet1, oGet2       
DEFINE DIALOG oDlgH TITLE "Buscar Codigo de Articulos" FROM 03,15 TO 10,65
   acor := AcepCanc(oDlgH)    
   @ 07,05 SAY "Codigo a Buscar:" OF oDlgH SIZE 60,12 PIXEL RIGHT  
   @ 05,70 GET oGet2 VAR nCodNue        OF oDlgH PIXEL 
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Buscar" OF oDlgH SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlgH:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlgH SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlgH:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgH CENTER 
IF !mrta 
   RETURN nil 
ENDIF
IF oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2SQL(nCodNue)):RecCount() = 0 
   IF oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"articu WHERE codigopro = "+ClipValue2SQL(nCodNue)):RecCount() = 0 
       MsgInfo("No existe un articulo con el codigo ingresado, por favor verifique los datos","Atencion!")
       RETURN nil 
       ELSE 
       nCodNue := oApp:oServer:Query("SELECT codigo FROM ge_"+oApp:cId+"articu WHERE codigopro = "+ClipValue2SQL(nCodNue)):codigo
   ENDIF
   ELSE 
   nCodNue := VAL(nCodNue)    
ENDIF

Formu(.f.,nCodNue)
RETURN NIL


************************************************
** Historial de ventas de un producto 
STATIC FUNCTION HistorialVentas()
LOCAL oBot := ARRAY(3), oForm, lRta := .f., aCor, oFont, oFont1, oError,;
      oQryDet, oBrwDet, oGet := ARRAY(2)
oQryDet := oApp:oServer:Query("SELECT v.codart,v.cantidad,v.fecha,v.punit, "+;
  " v.importe*IF(LEFT(nrofac,2)='NC',-1,1) as importe,c.nombre,v.nrofac,v.descu "+;
  " FROM ge_"+oApp:cId+"ventas_det v LEFT JOIN ge_"+oApp:cId+"clientes c ON c.codigo = v.codcli "+;
  " WHERE v.codart = "+ClipValue2SQL(oQryBrw:codigo) + " AND v.fecha >= "+ClipValue2SQL(dDesde)+;
  " AND v.fecha <= "+ClipValue2Sql(dHasta) )
           
DEFINE FONT oFont  NAME "TAHOMA" SIZE 0,-11.5
DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0,-22
DEFINE DIALOG oForm TITLE "Historial de Ventas "+oQryBrw:nombre  FROM 05,15 TO 25,130 OF oWnd1 FONT oFont
   acor := AcepCanc(oForm)   
   @ 05, 05 SAY "VENTAS DEL PRODUCTO"  OF oForm SIZE 200,14 PIXEL FONT oFont1
   @ 25, 05 XBROWSE oBrwDet SIZE 400,100 PIXEL OF oForm DATASOURCE oQryDet ;
      COLUMNS "fecha","nrofac","nombre","cantidad","punit","importe","descu";
      HEADERS "Fecha","Comprobante","Cliente","Cant.","Unitario","Total","%Desc";
      SIZES 70,120,300,70,70,95,60 FOOTERS;
      CELL LINES NOBORDER AUTOSORT 
   oBrwDet:aCols[4]:nFooterType   := AGGR_SUM   
   oBrwDet:aCols[6]:nFooterType   := AGGR_SUM   
   oBrwDet:MakeTotals()
   oBrwDet:CreateFromCode()   
   PintaBrw(oBrwDet,0)   
   @07,210 SAY "Desde:" OF oForm PIXEL SIZE 30,12 
   @07,290 SAY "Hasta:" OF oForm PIXEL SIZE 30,12 
   @05,241 GET oGet[1] VAR dDesde OF oForm PIXEL 
   @05,321 GET oGet[2] VAR dHasta OF oForm PIXEL 
   @05,365 BUTTON oBot[3] PROMPT "Aplica" OF oForm PIXEL SIZE 20,12  ACTION FiltHis(oBrwDet,oQryDet,oQryBrw)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Exportar" OF oForm SIZE 30,10 ;
           ACTION (oBrwDet:ToExcel()) PIXEL WHEN(oQryDet:nRecCount()>0)
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Salir" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 
RETURN nil

STATIC FUNCTION FiltHis(oBrwDet,oQryDet,oQryBrw)
LOCAL cWhere := "v.codart = " +ClipValue2SQL(oQryBrw:codigo) + " AND v.fecha >= "+ClipValue2SQL(dDesde)+;
  " AND v.fecha <= "+ClipValue2Sql(dHasta) 
oQryDet:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrwDet:Refresh()
oBrwDet:Maketotals()
RETURN nil


*************************************************************************************
** Reporte de Recetas
STATIC FUNCTION RepRecetas()
LOCAL oGru, oQry, oRep, oFont1, oFont2
oQry := oApp:oServer:Query("SELECT a.nombre, r.codart,r.codusa,m.nombre AS materia,a.cantprod,r.cantidad, m.preciocos as pcosto, "+;
                   " m.preciocos* r.cantidad AS precio FROM ge_"+oApp:cId+"reseta r "+;
                   " LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = r.codart "+; 
                   " LEFT JOIN ge_"+oApp:cId+"articu m ON m.codigo = r.codusa "+; 
                   IF(lTipoArt == nil,""," WHERE a.nosale = "+ClipValue2SQL(!lTipoArt))+;
                   " ORDER BY r.codart, r.codusa"  )
IF oQry:nRecCount = 0
   MsgStop("No hay datos para listar","Error")
   RETURN nil
ENDIF
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
REPORT oRep TITLE "Reporte de Recetas ";
       FONT  oFont1,oFont2 ;
       HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Reporte detalle de recetas" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Reporte detalle de recetas "  
GROUP oGru ON oQry:codart HEADER "Para "+STR(oQry:cantprod,14)+" "+ ALLTRIM(oQry:nombre) + " ("+STR(oQry:codart)+")" FOOTER "Totales"  FONT 2   
  COLUMN TITLE "Codigo"         DATA oQry:codusa     PICTURE "99999999999999" SIZE 12 FONT 1
  COLUMN TITLE "Materia Prima"  DATA oQry:materia    SIZE 30 FONT 1
  COLUMN TITLE "Cantidad"       DATA oQry:cantidad   PICTURE "999999.99" SIZE 08 FONT 1 
  COLUMN TITLE "Costo"          DATA oQry:pcosto     SIZE 10 FONT 1 
  COLUMN TITLE "Total Costo"    DATA oQry:precio     SIZE 10 PICTURE "9999999999.99" FONT 1 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }

END REPORT
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow() ;
         ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5);
         ON POSTGROUP oRep:NewLine()
oQry:End()
RELEASE FONT oFont1
RELEASE FONT oFont2

RETURN NIL

FUNCTION FiltraArt2(base, oG, oLbx, nKey, cCampoFiltro,cAlias)
LOCAL cFiltro, cText, cNombre := if('a.'$base:cQuery,'a.nombre','nombre'),;
      cCodigo := if('a.'$base:cQuery,'a.codigo','codigo')
DEFAULT cCampoFiltro := '',cAlias:=''
IF LEN(cAlias) > 0
    cNombre := ALLTRIM(cAlias)+'.nombre'
    cCodigo := ALLTRIM(cAlias)+'.codigo'
ENDIF
/*
      cCodigo := if('a.'$base:cQuery,'a.codigo','codigo'),;
      cAlias := if(base:FieldPos('alias')>0,'alias','')
DEFAULT cCampoFiltro := '' 
*/
oG:Assign()
IF nKey = 38 .or. nKey = 40
   oLbx:SetFocus()
   RETURN nil 
ENDIF
IF nKey >= 32 .AND. nKey <= 122 
   IF nKey >= 96 .and. nKey <= 105
      nKey := nKey - 48
   ENDIF
   cText := LEFT(oG:cText,oG:nPos-1) + CHR(nKey)
   ELSE
   cText := ALLTRIM(oG:cText)
ENDIF
cText := STRTRAN(cText,"a.","a ")
cText := STRTRAN(cText,"'","")
cText := STRTRAN(cText,"%","")
cText := STRTRAN(cText," ","%' and "+cNombre+" like '%") 
cFiltro:= '('
IF !EMPTY(cCampoFiltro)
   cFiltro := cFiltro + cCampoFiltro  + " AND ( "+cNombre+" LIKE '%"+ cText +"%' OR " +;
              cCodigo + " LIKE '%"+ cText +"%' OR " +;
             "a.CODIGOPRO LIKE '%"+ cText +"%')" 
   ELSE 
   cFiltro := cFiltro + cNombre+" LIKE '%"+ cText +"%' OR " + cCodigo + " LIKE '%"+ cText +"%' OR " +;
               "a.CODIGOPRO LIKE '%"+ cText +"%'" 

ENDIF
cFiltro := cFiltro+") "+IF(nActivos=1,"",IF(nActivos=2," AND nosale = FALSE "," AND nosale = TRUE"))

base:SetNewFilter(SET_WHERE,cFiltro,.t.)
// Se refresca el listbox
oLbx:refresh()
RETURN .T.


STATIC FUNCTION Info()
LOCAL aTabla, oQryInfo, oDlg, oBot , oFont
oQryInfo := oApp:oServer:Query(""+;
"SELECT 'Está en lista de precio' AS concepto, l.nombre AS detalle FROM ge_"+oApp:cId+"lispredet ld  "+;
"LEFT JOIN ge_"+oApp:cId+"lispre l ON ld.codlis = l.codigo WHERE ld.codart = "+ClipValue2Sql(oQryBrw:codigo)+" "+;
"UNION ALL  "+;
"SELECT 'Participa en receta / Stock otro' AS concepto, a.nombre AS detalle FROM ge_"+oApp:cId+"reseta r  "+;
"LEFT JOIN ge_"+oApp:cId+"articu a ON r.codart = a.codigo WHERE r.codusa = "+ClipValue2Sql(oQryBrw:codigo)+" "+;
"UNION ALL "+;
"SELECT 'Participa en grupo precios' AS concepto, l.nombre AS detalle FROM ge_"+oApp:cId+"gruposdet ld  "+;
"LEFT JOIN ge_"+oApp:cId+"grupos l ON ld.codgru = l.codigo WHERE ld.codart = "+ClipValue2Sql(oQryBrw:codigo)+" "+;
IF(oApp:oServer:TableExist("ge_"+oApp:cId+"promociones"),;
"UNION ALL "+;
"SELECT 'Aplica en promocion' AS concepto, nompromo AS detalle FROM ge_"+oApp:cId+"promociones  "+;
"WHERE codart = "+ClipValue2Sql(oQryBrw:codigo)+" ","")) 
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-13.5
DEFINE DIALOG oDlg TITLE "Info del Producto" FROM 09,15 TO 28,135 OF oApp:oWnd
   oDlg:lHelpIcon := .f.
   @ 01,001 BITMAP RESOURCE "CONFIRMA" SIZE 65,140 ADJUST PIXEL OF oDlg NOBORDER
   @ 01,080 XBROWSE oBrw1 DATASOURCE oQryInfo SIZE 325,140 OF oDlg PIXEL ;
       COLUMNS "concepto","detalle";
       HEADERS "Concepto","Detalle";
       SIZES   350,350
   PintaBrw(oBrw1,2)
   oBrw1:nFreeze := 2 
   oBrw1:CreateFromCode()
   @01,408 GROUP TO 140,468  PIXEL OF oDlg 
   @10,423 BUTTON oBot PROMPT "&Salir" OF oDlg SIZE 30,10 ACTION oDlg:End() PIXEL   
ACTIVATE DIALOG oDlg CENTER 
RETURN nil