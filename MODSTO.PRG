#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "report.ch"
*************************************************
** Modificacion manual de stock
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, lEdit := .f., cVentana, oError
PROCEDURE MODSTOCK(cPermisos)
LOCAL oGet, cBuscar := SPACE(50), oBar, hHand, oFol, oMen, nOpt := 1
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)

   CursorWait()
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"articu ORDER BY codigo")
  

   
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Modific. manual de stock" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Modificacion de stock por salidas varias"  ;
            ACTION (Desperdicio(),oBrw:Refresh());
            PROMPT "Descarga" TOP WHEN(oQry:RecCount()>0 .and. "A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro"  ;
            ACTION (Formu(),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Stock actual",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Reporte de Entradas / Salidas manuales"  ;
            ACTION Reporte();
            PROMPT "Listado" TOP WHEN("R"$cPermisos)
         DEFINE BUTTON RESOURCE "REPORT" OF oBar ;
            TOOLTIP "Historial de movimeintos de stock"  ;
            ACTION Reporte2();
            PROMPT "Historial" TOP WHEN("R"$cPermisos)   
         DEFINE BUTTON RESOURCE "STOC" OF oBar ;
            TOOLTIP "Reporte de stock comprometido"  ;
            ACTION ReporteCom();
            PROMPT "Stock Comp." TOP WHEN("R"$cPermisos)        
         
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
   DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
        REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "Codigo","codigopro","Nombre","Stockact";
              HEADERS "Código articulo","Cod.Prov","Nombre","Stock actual";
              SIZES   100,100,350,80;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil))
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     PintaBrw(oBrw,4) // CAMBIAR DEPENDIENDO DE CUANTAS COLUMNAS TENGA EL BROWSE
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,3)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

*****************************************************************************
*****************************************************************************
STATIC FUNCTION Formu ()
LOCAL oGet := ARRAY(4), oBot := ARRAY(2), oForm, lRta := .F., aCor, base, nEntradas:= 0,;
      nSalidas:= 0, nStock
     
      
   base := oQry:GetRowObj()
   base:codigo := oQry:codigo
   nStock:= base:StockAct

IF oApp:oServer:Query("SELECT stockact FROM ge_"+oApp:cId+"articu WHERE codigo = "+str(base:codigo)):stockact <> base:stockact 
   MsgStop("El stock fue modificado en otra terminal","Actualice")
   oQry:Refresh()
   oBrw:Refresh()
   RETURN nil 
ENDIF


DEFINE DIALOG oForm TITLE "Modificación manual de stock";
   FROM 05,10 TO 17,50 OF oWnd1
   acor := AcepCanc(oForm)
   
   @ 07, 20 SAY "Stock actual:" OF oForm PIXEL SIZE 40,20 RIGHT
   @ 22, 20 SAY "Entradas:"     OF oForm PIXEL SIZE 40,20 RIGHT
   @ 37, 20 SAY "Salidas:"      OF oForm PIXEL SIZE 40,20 RIGHT
   @ 52, 20 SAY "Nuevo stock:"  OF oForm PIXEL SIZE 40,20 RIGHT
 ******************************************************************
   @ 05, 70 GET oGet[1] VAR base:stockact OF oForm PIXEL PICTURE "9999999.999" RIGHT WHEN(.F.)
   @ 20, 70 GET oGet[2] VAR nEntradas OF oForm PIXEL PICTURE "999999.999" RIGHT
   @ 35, 70 GET oGet[3] VAR nSalidas  OF oForm  PIXEL RIGHT PICTURE "999999.999"
   @ 50, 70 GET oGet[4] VAR nStock    OF oForm  PIXEL RIGHT  PICTURE "9999999.999";
     WHEN(( oGet[4]:cText := base:stockact - nSalidas + nEntradas) = "-9999999999")   
   
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL

ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()


IF !lRta
   RETURN nil
ENDIF
IF oApp:oServer:Query("SELECT stockact FROM ge_"+oApp:cId+"articu WHERE codigo = "+str(base:codigo)):stockact <> base:stockact 
    MsgStop("El stock fue modificado en otra terminal","Actualice")
    oQry:Refresh()
    oBrw:Refresh()
    RETURN nil 
ENDIF
TRY
   oApp:oServer:BeginTransaction()       
   base:stockact := base:stockact + nEntradas - nSalidas
   base:save()
   oApp:oServer:Insert("ge_"+oApp:cId+"stoman",{"codart","entradas","salidas","fecha","motivo","costo"},;
                           {base:codigo,nEntradas,nSalidas,DATE(),1,base:precossiva})
   oApp:oServer:CommitTransaction() 
CATCH oError
 MsgInfo(oError:description)
 oApp:oServer:RollBack()   
END TRY
oBrw:Refresh()
RETURN nil


*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
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
IF oQry:codigo = 0
   RETURN nil
ENDIF
mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
oQry:Delete()
RETURN nil


*************************************************************************************************************
********* Modificar stock por desperdicio y otros
STATIC FUNCTION Desperdicio()
LOCAL oGet := ARRAY(9), oBot := ARRAY(6),oQryPar,oForm, lRta := .f., aCor, base, oError,;
      oBrw1,oBrw2,oFont, aMotivos := {"Modificación Manual","Desperdicio","Vencido","Consumo Interno","Rotura","Otros"},;
      nMotivo := 2, dFecha := DATE()

oApp:oServer:Execute("CREATE TEMPORARY TABLE IF NOT EXISTS `transi_desper` ("+;
                           "`codart` BIGINT(14) NOT NULL,"+;
                           "`nomart` VARCHAR(50),"+;
                           "`cantidad` decimal(10,2),"+;
                           "`costo` decimal(10,2),"+;
                           "PRIMARY KEY (codart)) ENGINE=INNODB DEFAULT CHARSET=latin1")
oApp:oServer:NextResult()
oApp:oServer:Execute("TRUNCATE transi_desper ")
oApp:oServer:NextResult()
oQryPar:= oApp:oServer:Query("SELECT * FROM transi_desper")
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Salida de stock" FROM 05,15 TO 27,80 OF oWnd1 FONT oFont
   
   @ 07, 05 SAY "Fecha:"  OF oForm PIXEL SIZE 30,20 RIGHT   
   @ 22, 05 SAY "Motivo"  OF oForm PIXEL SIZE 30,20 RIGHT   

   @ 05, 40 GET oGet[1]      VAR dFecha PICTURE "@D" OF oForm PIXEL 
   @ 22, 40 COMBOBOX oGet[2] VAR nMotivo ITEMS aMotivos OF oForm PIXEL SIZE 60,12
   
   @ 70,243 BUTTON oBot[3] PROMPT "+" SIZE 12,12 OF oForm PIXEL ACTION(AgregaArt(oForm),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())   
   @ 35, 05 XBROWSE oBrw1 DATASOURCE oQryPar ;
           COLUMNS "codart","nomart","cantidad","costo";
           HEADERS "Codgio","Detalle del articulo","Cantidad","Costo";
           SIZES   90,290,90 OF oForm SIZE 236, 95 AUTOSORT PIXEL FASTEDIT
   oBrw1:aCols[3]:nEditType := 1        
   oBrw1:CreateFromCode()  
   PintaBrw(oBrw1,0) 
  
   @100,243 BUTTON oBot[4] PROMPT "-" SIZE 12,12 OF oForm PIXEL ACTION(BorrarArt(oQryPar:codart),oQryPar:Refresh(),;
                                                                       oBrw1:Refresh())
   acor := AcepCanc(oForm)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
   oForm:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)}
ACTIVATE DIALOG oForm CENTER ON INIT oGet[1]:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()  
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"stoman (codart,salidas,fecha,motivo,costo) "+;
                       "SELECT codart,cantidad,"+ClipValue2Sql(dFecha)+","+ClipValue2Sql(nMotivo)+",costo FROM transi_desper") 
  oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"articu a "+; 
               "INNER JOIN "+; 
               "("+; 
               "SELECT codart, cantidad "+;
               "FROM transi_desper "+;
               ") v ON a.codigo = v.codart "+;
               "SET a.stockact = a.stockact - v.cantidad WHERE a.stockotro IS FALSE")
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
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
  oApp:oServer:Execute("DELETE FROM transi_desper WHERE codart = " + ClipValue2Sql(codigo))
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
   ValidaError(oError)
END TRY
oBrw:Refresh()
RETURN nil 


*******************************************************************************
STATIC FUNCTION AgregaArt(oForm)
LOCAL oDlgA,oError,oQryArt,nArticu:=0,cNomArt:=SPACE(30),oGet1,oGet2,oGet3,;
      oBot:=ARRAY(2),acor:=ARRAY(4),lRta:=.f., nCantidad := 1
oQryArt:= oApp:oServer:Query("SELECT a.codigo AS codigo,a.nombre AS nombre,a.codigopro as codigopro, m.nombre AS Marca, "+;
                              "r.nombre AS Rubro, a.precossiva as costo FROM ge_"+oApp:cId+"articu a "+;
                              "LEFT JOIN ge_"+oApp:cId+"marcas m ON m.codigo = a.marca "+;
                              "LEFT JOIN ge_"+oApp:cId+"rubros r ON r.codigo = a.rubro WHERE a.stockotro IS FALSE") 
                              
DEFINE DIALOG oDlgA TITLE "Seleccione el articulo" FROM 05,15 TO 14,70 OF oForm
   @ 12, 05 SAY "Artículo:" OF oDlgA PIXEL SIZE 30,12 RIGHT   
   @ 27, 05 SAY "Cantidad:" OF oDlgA PIXEL SIZE 30,12 RIGHT   
   @ 10, 40 GET oGet1 VAR nArticu OF oDlgA PIXEL PICTURE "99999999999999" SIZE 45,12 RIGHT;
               VALID(Buscar(oQryArt,oDlgA,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, Buscar(oQryArt,oDlgA,oGet1,oGet2)) BITMAP "BUSC1"
   @ 10, 90 GET oGet2 VAR cNomArt OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)
   @ 25, 40 GET oGet3 VAR nCantidad OF oDlgA PIXEL PICTURE "999999.99" RIGHT VALID(nCantidad > 0)
   acor := AcepCanc(oDlgA)
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar (F9)" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgA:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgA:End() ) PIXEL CANCEL  
    oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)} 
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet1:SetFocus()
IF !lRta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction() 
  oApp:oServer:Insert("transi_desper",{"codart","nomart","cantidad","costo"},{nArticu,cNomArt,nCantidad, oQryArt:costo})
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
RETURN nil


**********************************************
** Reporte de Movimientos manuales de stock
STATIC FUNCTION Reporte()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      i, aMar, oBrwMar, cSql,;
      cMarca, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., aMotivos
aMotivos := {"Modificación Manual","Desperdicio","Vencido","Consumo Interno","Rotura","Otros","Transf.Interna Entrada","Transf.Interna Salida","Produccion"}
aMar   := {{.t.,"Modificación Manual"},{.t.,"Desperdicio"},{.t.,"Vencido"},{.t.,"Consumo Interno"},{.t.,"Rotura"},{.t.,"Otros"},;
           {.t.,"Transf.Interna Entrada"},{.t.,"Transf.Interna Salida"},{.t.,"Produccion"}}
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Modificacion manual de stock" FROM 03,15 TO 27,90
   acor := AcepCanc(oDlg1)    
   @ 05, 05 SAY "Conceptos a Incluir" OF oDlg1 PIXEL
   @ 05,100 BUTTON oBot1 PROMPT "Inc" ACTION Cambiar(@aMar,oBrwMar) PIXEL SIZE 20,10 OF oDlg1
   @ 20, 05 XBROWSE oBrwMar SIZE 125,80 pixel OF oDlg1 ARRAY aMar ;
      HEADERS "Incluir", "Concepto";
      COLUMNS 1, 2 ;
      CELL LINES NOBORDER FASTEDIT
   WITH OBJECT oBrwMar
      :nEdittYPEs := 1
      :aCols[ 1 ]:SetCheck()
      :CreateFromCode()
   END  
   PintaBrw(oBrwMar,0)   
   @ 112, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 127, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 110, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 125, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ 140, 05 CHECKBOX oGet[3] VAR lResu PROMPT "Mostrar solo resumen"  SIZE 110,10 PIXEL OF oDlg1
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF
cMarca := "("
FOR i := 1 TO LEN(aMar)
    IF aMar[i,1]
       cMarca := cMarca + IF(cMarca=="(","",",") + STR(i)  
    ENDIF
NEXT i
cMarca := cMarca + ")"
IF !lResu
cSql := "SELECT c.codart AS codart, a.nombre AS detart,"+;
        "c.entradas , c.salidas, c.fecha AS fecha,c.motivo, c.entradas*c.costo as costoe, c.salidas * c.costo as costos "+;
        "FROM ge_"+oApp:cId+"stoman c "
   ELSE
cSql := "SELECT c.codart AS codart, a.nombre AS detart, c.motivo, "+;
        "SUM(c.entradas) AS entradas,  SUM(c.salidas) AS salidas, c.fecha , SUM(c.entradas * c.costo) as costoe,  "+;
        "SUM(c.salidas * c.costo) as costos "+;
        "FROM ge_"+oApp:cId+"stoman c "   
ENDIF
cSql := cSql + ;
        "LEFT JOIN ge_"+oApp:cId+"articu a ON c.codart = a.codigo "+;                
        "WHERE c.fecha >= " + ClipValue2Sql(mdesde) +;
        "  AND c.fecha <= " + ClipValue2Sql(mhasta) 
cSql := cSql + " AND c.motivo IN " + cMarca
IF lResu
   cSql := cSql + " GROUP BY c.codart,c.motivo ORDER BY a.nombre"
   ELSE
   cSql := cSql + " ORDER BY c.fecha"
ENDIF   
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Movimientos de stock manual por fecha del " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Movimientos de stock manual" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Movimientos de stock manual"
IF !lResu   
   COLUMN TITLE "Fecha"     DATA oQry:fecha    PICTURE "@D"   SIZE 9 FONT 1      
ENDIF   
COLUMN TITLE "Articulo" DATA oQry:detart   SIZE 30 FONT 1
COLUMN TITLE "Codigo"   DATA oQry:codart   SIZE 13 FONT 1
COLUMN TITLE "Entradas"  DATA oQry:entradas PICTURE "9999999.99" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Salidas"  DATA oQry:salidas PICTURE "9999999.99" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Costo Ent."  DATA oQry:costoe PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Costo Sal."  DATA oQry:costos PICTURE "9999999999.99" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Motivo"   DATA aMotivos[IF(oQry:motivo=0,1,oQry:motivo)] ;
                         SIZE 15 
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5);
                ON POSTGROUP oRep:NewLine()
oQry:End()
RETURN NIL


STATIC FUNCTION Cambiar(Arr,oBr)
LOCAL i
FOR i := 1 TO LEN(Arr)
    Arr[i,1] := !Arr[i,1]
NEXT i
oBr:Refresh()
RETURN nil


**********************************************
** Reporte de stock comprometido
STATIC FUNCTION ReporteCom()
LOCAL oRep, oFont1, oFont2, oFont3, oQry, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      i, aMar, oBrwMar, cSql,;
      cMarca, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., aMotivos
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte de stock comprometido" FROM 03,20 TO 12,60
   acor := AcepCanc(oDlg1)    
   @ 07, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 22, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 05, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 20, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF

cSql := "SELECT * FROM ("+;
"SELECT codigo,nombre,SUM(res.stockact) AS stockact,SUM(res.entradas) AS entradas, SUM(res.salidas) AS salidas FROM ( "+;
"SELECT codigo,nombre,stockact, 0 AS entradas,0 AS salidas FROM ge_"+oApp:cId+"articu "+;
"UNION "+;
"SELECT codart AS codigo,detart AS nombre,0 AS stockact,SUM(cantidad) AS entradas,0 AS salidas FROM ge_"+oApp:cId+"pedprov_det GROUP BY codart "+;
"UNION "+;
"SELECT p.codart AS codigo,p.detart AS nombre,0 AS stockact,0 AS entradas,SUM(p.cantidad) AS salidas FROM ge_"+oApp:cId+"pedidos_encab pe  "+;
"LEFT JOIN ge_"+oApp:cId+"pedidos_det p ON p.idpedido = pe.id   "+;
"WHERE p.estado = 'P' pe.parafecha >= "+ClipValue2Sql(mdesde)+" AND pe.parafecha <=  "+ClipValue2Sql(mhasta)+"  GROUP BY p.codart "+;
") res GROUP BY res.codigo) res1 WHERE res1.salidas <> 0 ORDER BY res1.nombre" 
CursorWait()
oQry = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Reporte de stock comprometido " + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Stock comprometido" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Stock Comprometido"
COLUMN TITLE "Articulo" DATA oQry:nombre   SIZE 30 FONT 1
COLUMN TITLE "Codigo"   DATA oQry:codigo   SIZE 13 FONT 1
COLUMN TITLE "Actual"   DATA oQry:stockact PICTURE "999999999.99" ;
                            SIZE 10 FONT 2 TOTAL
COLUMN TITLE "Pedidos Prov."  DATA oQry:entradas PICTURE "999999999.99" ;
                            SIZE 12 FONT 2 TOTAL
COLUMN TITLE "Pedidos Clientes"  DATA oQry:salidas PICTURE "9999999999.99" ;
                            SIZE 12 FONT 2 TOTAL
COLUMN TITLE "Resultado"  DATA oQry:stockact+oQry:entradas-oQry:salidas PICTURE "9999999999.99" ;
                            SIZE 12 FONT 2 TOTAL
// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQry:GoTop() }
oRep:bSkip := {|| oQry:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQry:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQry:End()
RETURN NIL


**********************************************
** Reporte de historial de stock 
STATIC FUNCTION Reporte2()
LOCAL oRep, oFont1, oFont2, oFont3, oDlg1, oFont,;
      acor:= ARRAY(4), mrta:=.F., oGet:= ARRAY(6), oBot1, oBot2,;
      i, aMar, oBrwMar, cSql, oQryRep,;
      cMarca, oGru, mdesde := DATE(), mhasta := DATE(), lResu := .f., aMotivos
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DEFINE DIALOG oDlg1 TITLE "Reporte historial de stock" FROM 03,20 TO 14,60
   acor := AcepCanc(oDlg1)    
   @ 07, 05 SAY "Historial de "+ALLTRIM(oQry:nombre) OF oDlg1 PIXEL SIZE 150,10 CENTER
   @ 22, 05 SAY "Desde fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 37, 05 SAY "Hasta fecha" OF oDlg1 PIXEL SIZE 60,10 RIGHT
   @ 20, 70 GET oGet[1] VAR mdesde    OF oDlg1 PIXEL
   @ 35, 70 GET oGet[2] VAR mhasta    OF oDlg1 PIXEL VALID(mhasta >= mdesde)   
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF

cSql := " SELECT * FROM (" +;
       "SELECT concat(cd.tipocomp,cd.letra,cd.numfac) as compro, 'Compra' as motivo, "+;
       " (cd.cantidad * IF(cd.tipocomp='NC',-1,1)) as entrada, 0 as salida, c.fecfac as fecha FROM "+;
       " ge_"+oApp:cId+"compras c LEFT JOIN ge_"+oApp:cId+"compradet cd "+;
       " ON cd.tipocomp = c.tipocomp and cd.letra = c.letra and cd.numfac = c.numfac "+;
       " WHERE cd.codart = "+ClipValue2Sql(oQry:codigo)+;
       " AND c.fecfac >= "+ClipValue2Sql(mdesde)+" AND c.fecfac <=  "+ClipValue2Sql(mhasta)+;       
       " UNION "+;
       "SELECT nrofac as compro, 'Venta' as motivo, 0 as entrada, "+;
       " (cantidad * IF(LEFT(nrofac,2)='NC',-1,1)) as salida, fecha FROM "+;
       " ge_"+oApp:cId+"ventas_det "+;       
       " WHERE codart = "+ClipValue2Sql(oQry:codigo)+;
       " AND fecha >= "+ClipValue2Sql(mdesde)+" AND fecha <=  "+ClipValue2Sql(mhasta)+;
       " UNION "+;
       "SELECT nrorem as compro, 'Venta x Remito' as motivo, 0 as entrada, "+;
       " cantidad  as salida, fecha FROM "+;
       " ge_"+oApp:cId+"remitos "+;       
       " WHERE NOT facturado AND codart = "+ClipValue2Sql(oQry:codigo)+;
       " AND fecha >= "+ClipValue2Sql(mdesde)+" AND fecha <=  "+ClipValue2Sql(mhasta)+;
       " UNION "+;
       "SELECT CAST(id AS CHAR)  as compro, "+;
       "CASE "+;
        "WHEN motivo  = 1  THEN 'Modificación Manual'  "+;
        "WHEN motivo  = 2  THEN 'Desperdicio' "+;
        "WHEN motivo  = 3  THEN 'Vencido'  "+;
        "WHEN motivo  = 4  THEN 'Consumo Interno'  "+;
        "WHEN motivo  = 5  THEN 'Rotura' "+;
        "WHEN motivo  = 6  THEN 'Otros' "+;
        "WHEN motivo  = 7  THEN 'Transf.Interna Entrada'  "+;
        "WHEN motivo  = 8  THEN 'Transf.Interna Salida'  "+;
        "WHEN motivo  = 9  THEN 'Produccion'  "+;
        "END as motivo,"+;
       " entradas as entrada, salidas as salida, fecha FROM "+;
       " ge_"+oApp:cId+"stoman "+;       
       " WHERE codart = "+ClipValue2Sql(oQry:codigo)+;
       " AND fecha >= "+ClipValue2Sql(mdesde)+" AND fecha <=  "+ClipValue2Sql(mhasta)+;
       ") res ORDER BY res.fecha" 
CursorWait()
oQryRep = oApp:oServer:Query(cSql)
     DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-8
     DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-8 BOLD
     DEFINE FONT oFont3 NAME "ARIAL" SIZE 0,-8 BOLD ITALIC   
REPORT oRep TITLE "Reporte Historial de stock "+ALLTRIM(oQry:nombre) + ;
                  DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2,oFont3 HEADER OemToAnsi(oApp:nomb_emp) , ;
       "Historial Stock" CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Historial Stock "+ALLTRIM(oQry:nombre)
COLUMN TITLE "Fecha"    DATA oQryRep:fecha SIZE 08 FONT 1 
COLUMN TITLE "Motivo"   DATA oQryRep:motivo SIZE 20 FONT 1
COLUMN TITLE "Entradas" DATA oQryRep:entrada PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL
COLUMN TITLE "Salidas"  DATA oQryRep:salida  PICTURE "9999999999.99" SIZE 12 FONT 2 TOTAL

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 3 }
oRep:bInit := {|| oQryRep:GoTop() }
oRep:bSkip := {|| oQryRep:Skip() }
END REPORT
// Activo el reporte
ACTIVATE REPORT oRep WHILE !oQryRep:EOF() ON INIT CursorArrow();
                ON STARTGROUP oRep:NewLine() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)
oQryRep:End()
RETURN NIL