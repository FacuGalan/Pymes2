#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"

*************************************************
** ABM Listas de precios especiales
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana,nPorc,nLisBase
PROCEDURE ABMLISPRE(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
nPorc:=0
nLisBase:=1
oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"lispre ORDER BY nombre")

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Listas de precios" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro"  ;
            ACTION (Formu( .t. ),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu( .f. ),oBrw:Refresh());
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
            ACTION oBrw:Report("Reporte de Listas de precios",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Lista de Precios"  ;
            ACTION ListaPre();
            PROMPT "Listas" TOP WHEN("R"$cPermisos)   
         /*DEFINE BUTTON RESOURCE "PROMO" OF oBar ;
            TOOLTIP "Promociones"  ;
            ACTION (oWnd1:End(),Promociones(cPermisos));
            PROMPT "Promos" TOP WHEN("A"$cPermisos)   */

            // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codigo","Nombre";
              HEADERS "Codigo","Nombre";
              SIZES 50,350;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu( .f.),MsgInfo("Sin Permiso")),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     //oBrw:SetDolphin(oQry,.f.,.t.)
     PintaBrw(oBrw,2) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar,cPermisos)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN


***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu ( lAlta)
LOCAL oGet := ARRAY(9), oBot := ARRAY(6),oQryPar,oQryEnt,oQryPro, oForm, lRta := .f., aCor, base, oError,;
      oBrw1,oBrw2,oFont,aListas:={"Lista 1","Lista 2","Precio de costo"}

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_lispre` ("+;
                           "`codart` BIGINT(13) NOT NULL,"+;
                           "`nomart` VARCHAR(200),"+;
                           "`numpre` INT(1),"+;
                           "`porc` DECIMAL(5,2),"+;
                           "`precio` DECIMAL(12,2),"+;
                           "PRIMARY KEY (codart,nomart)) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_lispre ")
oApp:oServer:NextResult()


IF lAlta
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre LIMIT 0")
   base := oQryPro:GetBlankRow()
   base:codigo := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"lispre")
   ELSE
   oQryPro:= oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"lispre WHERE codigo = " +ClipValue2Sql(oQry:codigo))
   base := oQryPro:GetRowObj()
   oApp:oServer:Execute("INSERT INTO transi_lispre (codart,nomart,numpre,porc,precio) "+;
                     "SELECT p.codart,a.nombre,p.numpre,p.porc,p.precio FROM ge_"+oApp:cId+"lispredet p LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = p.codart "+;
                     "WHERE p.codlis = " + ClipValue2Sql(oQry:codigo))
   oApp:oServer:NextResult()
ENDIF

oQryPar:= oApp:oServer:Query("SELECT * FROM transi_lispre")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de lista de precios";
       FROM 05,15 TO 32,81 OF oWnd1 FONT oFont
   
   @ 07, 05 SAY "Codigo:"     OF oForm PIXEL SIZE 30,20 RIGHT
   @ 22, 05 SAY "Nombre:"     OF oForm PIXEL SIZE 30,20 RIGHT
   @ 37, 05 SAY "Lista base:" OF oForm PIXEL SIZE 30,20 RIGHT
   @ 37, 75 SAY "% Incr.:"    OF oForm PIXEL SIZE 30,20 RIGHT
   
   @ 52, 05 SAY "Articulos que participan"  OF oForm PIXEL

   @ 05, 40 GET oGet[1] VAR base:codigo PICTURE "99999" OF oForm PIXEL RIGHT WHEN(.F.)
   @ 20, 40 GET oGet[2] VAR base:nombre PICTURE "@!"    OF oForm PIXEL ;
                VALID(base:nombre<>SPACE(30))

   @ 35, 40 COMBOBOX oGet[3] VAR nLisBase ITEMS aListas OF oForm SIZE 40,40 PIXEL
   @ 35,110 GET oGet[5] VAR nPorc OF oForm PIXEL PICTURE "999.99" RIGHT;

   
   @ 35,145 BUTTON oBot[3] PROMPT "+"  SIZE 12,12 OF oForm PIXEL ACTION(AgregaArt(oForm),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())   
   @ 35,160 BUTTON oBot[4] PROMPT "+ +" SIZE 20,12 OF oForm PIXEL ACTION(AgregaArtGen(oForm),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())

   @ 35,200 BUTTON oBot[4] PROMPT "Actualizar" SIZE 40,12 OF oForm PIXEL ACTION(ActualizarPre(base:codigo),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())
   @ 60, 05 XBROWSE oBrw1 DATASOURCE oQryPar ;
           COLUMNS "codart","nomart","porc","precio","numpre";
           HEADERS "Codigo","Detalle del articulo","% Incr.","Precio","Base";
           SIZES   50,290,50,60,100 OF oForm SIZE 250,120 AUTOSORT PIXEL   
   oBrw1:CreateFromCode()  
   oBrw1:nFreeze:= 2
   PintaBrw(oBrw1,0) 
   oBrw1:aCols[4]:lAutoSave := .t.
   oBrw1:aCols[4]:nEditType := EDIT_GET  
   oBrw1:aCols[4]:bOnPostEdit := {|oCol, xVal, nKey | CambiaPrecio(xval,oQryPar),oBrw1:Refresh()}
   oBrw1:aCols[5]:bStrData := {|| IF(oQryPar:RecCount()>0,IF(oQryPar:numpre=1,'Lista 1',IF(oQryPar:numpre=2,'Lista 2','Precio costo')),nil)}

   oBrw1:bKeyDown := { |nKey| IF (nKey == VK_DELETE,(BorrarArt(oQryPar:codart),oQryPar:Refresh(),oBrw1:Refresh()),)}

   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
   @ 05,200 BUTTON oBot[5] PROMPT "Imprimir" OF oForm SIZE 40,12 ;
            ACTION (oBrw1:Report("Lista de precios "+ALLTRIM(STR(base:codigo))+" "+ALLTRIM(base:nombre),.T.,.F.),oForm:End()) PIXEL
   @ 05,150 BUTTON oBot[6] PROMPT "Exportar" OF oForm SIZE 40,12 ;
            ACTION (oBrw1:ToExcel(),oForm:End()) PIXEL
   oForm:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)}
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF

oQryPro:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryPro:Save()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"lispredet WHERE codlis = " + ClipValue2Sql(base:codigo))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"lispredet (codlis,codart,numpre,porc,precio) "+;
                       "SELECT "+ClipValue2Sql(base:codigo)+",codart,numpre,porc,precio FROM transi_lispre") 
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

************************************************************************************************************
************ ACTUALIZAR PRECIOS DE LOS ARTICULOS 
STATIC FUNCTION ActualizarPre(nCodlis)
LOCAL  oError,cPrecio:=" IF(l.numpre=1,a.precioven,IF(l.numpre=2,a.reventa,a.preciocos)) "

 IF !MsgYesNo("¿Seguro que desea actualizar los precios de la lista?","Atencion!")
 	RETURN nil 
 ENDIF

TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("UPDATE transi_lispre l LEFT JOIN ge_"+oApp:cId+"articu a ON l.codart = a.codigo "+;
	                 "SET l.precio = ROUND("+cPrecio+"+"+cPrecio+"*(l.porc/100),0) ")
  oApp:oServer:CommitTransaction()

CATCH oError
   ValidaError(oError)
END TRY

RETURN nil


************************************************************************************************************
************ CAMBIAR PRECIO DEL ARTICULO 
STATIC FUNCTION CambiaPrecio(nPrecio,oQryPar)
LOCAL  base := oQryPar:GetRowObj(),nPreBase

nPreBase:= oApp:oServer:Query("SELECT "+IF(base:numpre=1,"precioven",IF(base:numpre=2,"reventa","preciocos"))+" AS pre "+;
                              "FROM ge_"+oApp:cId+"articu WHERE codigo = "+ClipValue2Sql(base:codart)):pre

base:precio:= nPrecio
base:porc := (nPrecio * 100) / nPreBase - 100
oQryPar:oRow := base
oQryPar:Save()
oQryPar:Refresh()
RETURN nil


******************************************************************************
STATIC FUNCTION BorrarArt(codigo)
LOCAL mrta := .f., oError
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el artículo código N°:"+STR(codigo),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM transi_lispre WHERE codart = " + ClipValue2Sql(codigo))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 

*******************************************************************************************************
**** AGREGAR ARTICULOS CON FILTRADO
STATIC FUNCTION AgregaArtGen(oForm)
LOCAL oDlgA,oError,oQryArt,nArticu:=0,cNomArt:=SPACE(50),oGet:=ARRAY(12),oQryAux,;
      oBot:=ARRAY(2),acor:=ARRAY(4),lRta:=.f.,lBorrar:=.f., aListas := {"precioven","reventa","preciocos"},;
      cLista:=aListas[nLisBase],lBorrarFilt:=.f.,;
      nCodProv:=0,cNomProv:="TODOS"+SPACE(45),oQryProv:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"provee"),;
      nCodMar:=0,cNomMar:="TODOS"+SPACE(25),oQryMar:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas"),;
      nCodRub:=0,cNomRub:="TODOS"+SPACE(25),oQryRub:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros"),;
      nCodEmp:=0,cNomEmp:="TODOS"+SPACE(25),oQryEmp:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas"),;
      nCodDto:=0,cNomDto:="TODOS"+SPACE(25),oQryDto:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos")

                              
DEFINE DIALOG oDlgA TITLE "Seleccione el articulo" FROM 05,15 TO 19,90 OF oForm
   
   @ 12, 05 SAY "Proveedor:"    OF oDlgA PIXEL SIZE 40,12 RIGHT  
   @ 27, 05 SAY "Marca:"        OF oDlgA PIXEL SIZE 40,12 RIGHT 
   @ 42, 05 SAY "Empresa:"        OF oDlgA PIXEL SIZE 40,12 RIGHT 
   @ 57, 05 SAY "Departamento:"      OF oDlgA PIXEL SIZE 40,12 RIGHT 
   @ 72, 05 SAY "Rubro:" OF oDlgA PIXEL SIZE 40,12 RIGHT 


   
   @ 10, 50 GET oGet[1] VAR nCodProv OF oDlgA PIXEL PICTURE "999999" SIZE 45,12 RIGHT;
               VALID(IF(nCodProv= 0,(oGet[2]:cText:="TODOS"+SPACE(45))<>"XXX",Buscar(oQryProv,oDlgA,oGet[1],oGet[2])) );
               ACTION (oGet[1]:cText:= 0, Buscar(oQryProv,oDlgA,oGet[1],oGet[2])) BITMAP "BUSC1"
   @ 10,100 GET oGet[2] VAR cNomProv OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)

   @ 25, 50 GET oGet[3] VAR nCodMar OF oDlgA PIXEL PICTURE "999999" SIZE 45,12 RIGHT;
               VALID(IF(nCodMar= 0,(oGet[4]:cText:="TODOS"+SPACE(25))<>"XXX",Buscar(oQryMar,oDlgA,oGet[3],oGet[4])) );
               ACTION (oGet[3]:cText:= 0, Buscar(oQryMar,oDlgA,oGet[3],oGet[4])) BITMAP "BUSC1"
   @ 25,100 GET oGet[4] VAR cNomMar OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)

   @ 40, 50 GET oGet[7] VAR nCodEmp OF oDlgA PIXEL PICTURE "999999" SIZE 45,12 RIGHT;
               VALID(IF(nCodEmp= 0,(oGet[8]:cText:="TODOS"+SPACE(25))<>"XXX",Buscar(oQryEmp,oDlgA,oGet[7],oGet[8])) );
               ACTION (oGet[7]:cText:= 0, Buscar(oQryEmp,oDlgA,oGet[7],oGet[8])) BITMAP "BUSC1"
   @ 40,100 GET oGet[8] VAR cNomEmp OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)

   @ 55, 50 GET oGet[9] VAR nCodDto OF oDlgA PIXEL PICTURE "999999" SIZE 45,12 RIGHT;
               VALID(IF(nCodDto= 0,(oGet[10]:cText:="TODOS"+SPACE(25))<>"XXX",Buscar(oQryDto,oDlgA,oGet[9],oGet[10])) );
               ACTION (oGet[9]:cText:= 0, Buscar(oQryDto,oDlgA,oGet[9],oGet[10])) BITMAP "BUSC1"
   @ 55,100 GET oGet[10] VAR cNomDto OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)

   @ 70, 50 GET oGet[5] VAR nCodRub OF oDlgA PIXEL PICTURE "999999" SIZE 45,12 RIGHT;
               VALID(IF(nCodRub= 0,(oGet[6]:cText:="TODOS"+SPACE(25))<>"XXX",Buscar(oQryRub,oDlgA,oGet[5],oGet[6],;
                                                                        IF(nCodDto>0,ALLTRIM(STR(nCodDto)),nil),;
                                                                        IF(nCodDto>0,"depto",nil))));
               ACTION (oGet[5]:cText:= 0, Buscar(oQryRub,oDlgA,oGet[5],oGet[6],IF(nCodDto>0,ALLTRIM(STR(nCodDto)),nil),;
                                                                        IF(nCodDto>0,"depto",nil))) BITMAP "BUSC1"
   @ 70,100 GET oGet[6] VAR cNomRub OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)


   @ 40,220 CHECKBOX oGet[12] VAR lBorrarFilt OF oDlgA PIXEL PROMPT "Reemplazar articulos" SIZE 60,30 
   @ 70,220 CHECKBOX oGet[11] VAR lBorrar OF oDlgA PIXEL PROMPT "Borrar articulos cargados" SIZE 150,12 

   acor := AcepCanc(oDlgA)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgA:End() ) PIXEL CANCEL  
    oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)} 
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction() 
  IF lBorrar
     oApp:oServer:Execute("TRUNCATE transi_lispre")
  ENDIF
  IF lBorrarFilt
     oApp:oServer:Execute("DELETE FROM transi_lispre WHERE codart IN (SELECT a.codigo FROM ge_"+oApp:cId+"articu a "+;
									                       			"WHERE "+IF(nCodProv>0,"a.prov    = "+ClipValue2Sql(nCodProv)," TRUE ")+" AND "+;
									                                IF(nCodMar>0 ,"a.marca   = "+ClipValue2Sql(nCodMar) ," TRUE ")+" AND "+;
									                                IF(nCodEmp>0 ,"a.empresa = "+ClipValue2Sql(nCodEmp) ," TRUE ")+" AND "+;
									                                IF(nCodDto>0 ,"a.depto   = "+ClipValue2Sql(nCodDto) ," TRUE ")+" AND "+;
									                                IF(nCodRub>0 ,"a.rubro   = "+ClipValue2Sql(nCodRub) ," TRUE ")+")")
  ENDIF
  oApp:oServer:Execute("INSERT INTO transi_lispre (codart,nomart,numpre,porc,precio) "+;
                       "(SELECT a.codigo,a.nombre,"+ClipValue2Sql(nLisBase)+","+ClipValue2Sql(nPorc)+","+;
                              "ROUND(a."+cLista+" + a."+cLista+" * ("+ClipValue2Sql(nPorc)+"/100),0) "+;
                       "FROM ge_"+oApp:cId+"articu a "+;
                       "WHERE nosale IS FALSE AND "+;
                                IF(nCodProv>0,"a.prov    = "+ClipValue2Sql(nCodProv)," TRUE ")+" AND "+;
                                IF(nCodMar>0 ,"a.marca   = "+ClipValue2Sql(nCodMar) ," TRUE ")+" AND "+;
                                IF(nCodEmp>0 ,"a.empresa = "+ClipValue2Sql(nCodEmp) ," TRUE ")+" AND "+;
                                IF(nCodDto>0 ,"a.depto   = "+ClipValue2Sql(nCodDto) ," TRUE ")+" AND "+;
                                IF(nCodRub>0 ,"a.rubro   = "+ClipValue2Sql(nCodRub) ," TRUE ")+")" )
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
RETURN nil


*******************************************************************************
STATIC FUNCTION AgregaArt(oForm)
LOCAL oDlgA,oError,oQryArt,nArticu:=0,cNomArt:=SPACE(50),oGet1,oGet2,oGet3,oGet4,oGet5,lBorrar,;
      oBot:=ARRAY(2),acor:=ARRAY(4),lRta:=.f.,nPrecio:=0,nPrecioBase:=0,;
      aListas := {"precioven","reventa","preciocos"},;
      cLista:=aListas[nLisBase]
oQryArt:= oApp:oServer:Query("SELECT a.codigo AS codigo,a.nombre AS nombre,m.nombre AS Marca, "+;
                              "r.nombre AS Rubro, a."+cLista+" AS preciobase FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = a.marca "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro ") 
                              
DEFINE DIALOG oDlgA TITLE "Seleccione el articulo" FROM 05,15 TO 15,90 OF oForm
   @ 12, 05 SAY "Artículo:" OF oDlgA PIXEL SIZE 40,12 RIGHT  
   @ 27, 05 SAY "Precio lista:"   OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 42, 05 SAY "Precio venta:"   OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1 VAR nArticu OF oDlgA PIXEL PICTURE "99999999999999" SIZE 45,12 RIGHT;
               VALID(BuscarArt(oQryArt,oDlgA,oGet1,oGet2) .and. (oGet3:cText:= oQryArt:preciobase) <> "xxx" .and.;
                    (oGet4:cText:= (oQryArt:preciobase + oQryArt:preciobase * (nPorc/100) )) <> "xxx"  );
               ACTION (oGet1:cText:= 0, BuscarArt(oQryArt,oDlgA,oGet1,oGet2),oGet3:cText:= oQryArt:preciobase,;
                       oGet4:cText:= (oQryArt:preciobase + oQryArt:preciobase * (nPorc/100) )) BITMAP "BUSC1"
   @ 10,100 GET oGet2 VAR cNomArt OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)
   @ 25, 50 GET oGet3 VAR nPrecioBase OF oDlgA PIXEL PICTURE "99999999.99" RIGHT WHEN(.F.)
   @ 40, 50 GET oGet4 VAR nPrecio OF oDlgA PIXEL PICTURE "99999999.99" RIGHT 
   acor := AcepCanc(oDlgA)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgA:End() ) PIXEL CANCEL  
    oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)} 

    @ 40,110 CHECKBOX oGet5 VAR lBorrar OF oDlgA PIXEL PROMPT "Reemplazar articulo" SIZE 60,12 

ACTIVATE DIALOG oDlgA CENTER ON INIT oGet1:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction() 
  IF lBorrar
     oApp:oServer:Execute("DELETE FROM transi_lispre WHERE codart = "+ClipValue2Sql(nArticu))
  ENDIF
  oApp:oServer:Insert("transi_lispre",{"codart","nomart","precio","numpre","porc"},{nArticu,cNomArt,ROUND(nPrecio,0),nLisBase,nPorc})
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
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

***********************************
** Baja de registro
STATIC FUNCTION Baja (  )
LOCAL mrta := .f., oError, nNum := oQry:codigo
IF oQry:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar"+CHR(10)+;
                 "el registro código N°:"+STR(nNum),"Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 