#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "constant.ch"

*************************************************
** PROMOCIONES POR GRUPO DE ARTICULOS
**
** Modelo unico que cubre dos casos:
**   Mix      (mismo_grupo = 1): cada N unidades sumadas entre los articulos del
**            grupo van al beneficio; el excedente queda a precio normal.
**            Sirve para "10 unidades a $1000 combinando sabores/fragancias".
**            Z es el mismo conjunto que A y M = N.
**   Cruzada  (mismo_grupo = 0): llevando N unidades del grupo A se benefician
**            M unidades del grupo Z.
**
** Un articulo PUEDE estar en A y en Z (por eso el rol entra en la clave unica
** del detalle). El Mix es justamente el caso en que A y Z son el mismo conjunto.
**
** Reglas acordadas con el cliente:
**   - k = piso(sumaA / N), topeado por max_aplica (0 = sin tope)
**   - se benefician las unidades MAS CARAS primero
**   - beneficio = precio unitario fijo, o porcentaje de descuento
**   - disparar no consume la unidad; recibir el beneficio si la consume
**
** Este archivo es solo el ABM. El motor de calculo va aparte.
*************************************************
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana

PROCEDURE PromosGrupo(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
ValidarTablas()
AADD(oApp:aVentanas,cVentana)
oQry := oApp:oServer:Query(SqlLista())

  DEFINE WINDOW oWnd1 MDICHILD TITLE "A/B/M de Promociones por Grupo" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Agregar Registro" ;
            ACTION (Formu(.t.),oQry:Refresh(),oBrw:Refresh());
            PROMPT "Alta" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Registro" ;
            ACTION (Formu(.f.),oQry:Refresh(),oBrw:Refresh());
            PROMPT "Modifica" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro" ;
            ACTION (Baja(),oQry:Refresh(),oBrw:Refresh());
            PROMPT "Baja" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "EXCE" OF oBar ;
            TOOLTIP "Exportar a Excel" ;
            ACTION oBrw:ToExcel() WHEN(oQry:RecCount()>0 .and. "E"$cPermisos);
            PROMPT "Exporta" TOP
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla" ;
            ACTION oBrw:Report("Reporte de Promos por Grupo",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQry:RecCount()>0 .and. "R"$cPermisos)
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "id","nompromo","modo","cant_a","cant_z","beneficio","max_aplica","prioridad","fecha_inicio","fecha_fin";
              HEADERS "#","Promo","Modalidad","Lleva","Benef.","Beneficio","Max.","Prior.","Desde","Hasta";
              SIZES 40,200,130,45,45,90,40,40,80,80;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK (IF("M"$cPermisos,Formu(.f.),MsgInfo("Sin Permiso")),oQry:Refresh(),oBrw:Refresh())
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:bKeyDown := {| nKey,nFlags | IF(nKey==13,(Formu(.f.),oQry:Refresh(),oBrw:GoLeftMost(),oBrw:Refresh()),.t.)}
     PintaBrw(oBrw,10)
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(Cerrar())
RETURN


***********************************
** SQL de la grilla principal
STATIC FUNCTION SqlLista()
RETURN "SELECT g.id, g.nompromo, "+;
       " IF(g.mismo_grupo = 1,'Mix (mismos art.)','Cruzada A -> Z') AS modo, "+;
       " g.cant_a, g.cant_z, "+;
       " IF(g.tipo_benef = 1, CONCAT('$ ',FORMAT(g.precio_unitario,2)), CONCAT(FORMAT(g.porcentaje,2),' %')) AS beneficio, "+;
       " g.max_aplica, g.prioridad, g.fecha_inicio, g.fecha_fin, g.hora_inicio, g.hora_fin, "+;
       " g.formapago, g.mismo_grupo, g.tipo_benef, g.precio_unitario, g.porcentaje "+;
       "FROM ge_"+oApp:cId+"promo_grupo g ORDER BY g.nompromo"


***********************************
** Creacion / migracion idempotente de las tablas.
** Se llama al entrar al modulo, igual que validarqueexista() de promos.prg.
** OJO con los TINYINT: Dolphin los devuelve como LOGICOS (.T./.F.), no como 1/0.
** Por eso mismo_grupo (TINYINT) se lee directo (lMismo := oQry:mismo_grupo) y NO con "== 1",
** y por eso tipo_benef va INT(1) A PROPOSITO: se compara contra 1 y 2, asi que si alguien
** lo "normaliza" a TINYINT se rompen los WHEN del beneficio y el alta.
STATIC FUNCTION ValidarTablas()
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promo_grupo")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"promo_grupo ( "+;
     "`id` INT(8) AUTO_INCREMENT,"+;
     "`nompromo` VARCHAR(40) DEFAULT NULL,"+;
     "`fecha_inicio` DATE DEFAULT NULL,"+;
     "`fecha_fin` DATE DEFAULT NULL,"+;
     "`hora_inicio` TIME DEFAULT '00:00:00' NOT NULL,"+;
     "`hora_fin` TIME DEFAULT '23:59:59' NOT NULL,"+;
     "`formapago` VARCHAR(20) DEFAULT '1,2,3,4,5,6' NOT NULL,"+;
     "`cant_a` INT(6) DEFAULT 0 NOT NULL,"+;
     "`cant_z` INT(6) DEFAULT 0 NOT NULL,"+;
     "`mismo_grupo` TINYINT(1) DEFAULT 1 NOT NULL,"+;
     "`tipo_benef` INT(1) DEFAULT 1 NOT NULL,"+;
     "`precio_unitario` DECIMAL(12,3) DEFAULT 0 NOT NULL,"+;
     "`porcentaje` DECIMAL(5,2) DEFAULT 0 NOT NULL,"+;
     "`max_aplica` INT(6) DEFAULT 0 NOT NULL,"+;
     "`prioridad` INT DEFAULT 0 NOT NULL,"+;
     "PRIMARY KEY (`id`)"+;
   ") ENGINE=INNODB DEFAULT CHARSET=utf8")
ENDIF
IF !oApp:oServer:TableExist('ge_'+oApp:cId+"promo_grupo_det")
   oApp:oServer:Execute("CREATE TABLE ge_"+oApp:cId+"promo_grupo_det ( "+;
     "`id` INT(8) AUTO_INCREMENT,"+;
     "`grupo_id` INT(8) NOT NULL,"+;
     "`codart` BIGINT(14) NOT NULL,"+;
     "`rol` CHAR(1) DEFAULT 'A' NOT NULL,"+;
     "PRIMARY KEY (`id`),"+;
     "UNIQUE KEY `uk_grupo_art` (`grupo_id`,`codart`,`rol`),"+;
     "KEY `k_grupo` (`grupo_id`),"+;
     "FOREIGN KEY (grupo_id) REFERENCES ge_"+oApp:cId+"promo_grupo(id) ON DELETE CASCADE,"+;
     "FOREIGN KEY (codart) REFERENCES ge_"+oApp:cId+"articu(codigo)"+;
   ") ENGINE=INNODB DEFAULT CHARSET=utf8")
ENDIF
RETURN nil


***************************************
** Alta y modificacion
STATIC FUNCTION Formu(lAlta)
LOCAL oForm, oFont, aCor, oBot := ARRAY(8), oGet := ARRAY(17), lRta := .f., oError,;
      oBrwA, oBrwZ, oSayZ, oChk, oCbo, i, nId := 0,;
      aDetA := {}, aDetZ := {},;
      cNomPromo := SPACE(40), dDesde := DATE(), dHasta := DATE(),;
      cHoraIni := "00:00", cHoraFin := "23:59",;
      nCantA := 0, nCantZ := 0, nMaxAplica := 0, nPrioridad := 0,;
      lMismo := .t., nTipoBenef := 1, nPrecioUni := 0, nPorcentaje := 0,;
      aForma := {.T.,.T.,.T.,.T.,.T.,.T.}, cFormaPago := "",;
      aBenef := {"Precio unitario","% de descuento"}

IF !lAlta
   IF oQry:nRecCount == 0
      RETURN nil
   ENDIF
   nId         := oQry:id
   cNomPromo   := PADR(ALLTRIM(cValToChar(oQry:nompromo)),40)
   dDesde      := oQry:fecha_inicio
   dHasta      := oQry:fecha_fin
   cHoraIni    := LEFT(cValToChar(oQry:hora_inicio),5)
   cHoraFin    := LEFT(cValToChar(oQry:hora_fin),5)
   nCantA      := oQry:cant_a
   nCantZ      := oQry:cant_z
   nMaxAplica  := oQry:max_aplica
   nPrioridad  := oQry:prioridad
   lMismo      := (oQry:mismo_grupo)
   nTipoBenef  := oQry:tipo_benef
   nPrecioUni  := oQry:precio_unitario
   nPorcentaje := oQry:porcentaje
   FOR i := 1 TO 6
      aForma[i] := (STR(i,1) $ ALLTRIM(cValToChar(oQry:formapago)))
   NEXT
   aDetA := CargaDetalle(nId,"A")
   aDetZ := CargaDetalle(nId,"Z")
ENDIF

DEFINE FONT oFont NAME "Tahoma" SIZE 0,-11
DO WHILE .T.
DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Promocion por Grupo";
       FROM 04,10 TO 36,140 OF oWnd1 FONT oFont
   oForm:lHelpIcon := .f.

   @ 07, 05 SAY "Nombre Promo:"     OF oForm PIXEL SIZE 70,12 RIGHT
   @ 07,300 SAY "Prioridad:"        OF oForm PIXEL SIZE 55,12 RIGHT COLOR CLR_BLUE
   @ 22, 05 SAY "Desde:"            OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22,125 SAY "Hasta:"            OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22,300 SAY "Max. veces:"       OF oForm PIXEL SIZE 55,12 RIGHT COLOR CLR_BLUE
   @ 37, 05 SAY "Forma de pago:"    OF oForm PIXEL SIZE 70,12 RIGHT COLOR CLR_BLUE
   @ 67, 05 SAY "Lleva (N):"        OF oForm PIXEL SIZE 70,12 RIGHT
   @ 67,150 SAY "Beneficia (M):"    OF oForm PIXEL SIZE 70,12 RIGHT
   @ 82, 05 SAY "Beneficio:"        OF oForm PIXEL SIZE 70,12 RIGHT
   @ 82,235 SAY "Valor:"            OF oForm PIXEL SIZE 40,12 RIGHT

   @ 05, 80 GET oGet[1] VAR cNomPromo PICTURE "@!" OF oForm SIZE 190,12 PIXEL;
            VALID(!EMPTY(cNomPromo))
   @ 05,360 GET oGet[2] VAR nPrioridad PICTURE "9999" RIGHT OF oForm SIZE 35,12 PIXEL
   @ 20, 50 GET oGet[3] VAR dDesde   PICTURE "@D"    OF oForm SIZE 42,12 PIXEL
   @ 20, 95 GET oGet[4] VAR cHoraIni PICTURE "99:99" OF oForm SIZE 22,12 PIXEL VALID(HoraOK(cHoraIni))
   @ 20,170 GET oGet[5] VAR dHasta   PICTURE "@D"    OF oForm SIZE 42,12 PIXEL
   @ 20,215 GET oGet[6] VAR cHoraFin PICTURE "99:99" OF oForm SIZE 22,12 PIXEL VALID(HoraOK(cHoraFin))
   @ 20,360 GET oGet[7] VAR nMaxAplica PICTURE "9999" RIGHT OF oForm SIZE 35,12 PIXEL

   @ 35, 80 CHECKBOX oGet[8]  VAR aForma[1] PROMPT "Efectivo"      OF oForm SIZE 55,12 PIXEL
   @ 35,140 CHECKBOX oGet[9]  VAR aForma[2] PROMPT "Transferencia" OF oForm SIZE 65,12 PIXEL
   @ 35,208 CHECKBOX oGet[10] VAR aForma[3] PROMPT "Cheques"       OF oForm SIZE 50,12 PIXEL
   @ 35,262 CHECKBOX oGet[11] VAR aForma[4] PROMPT "Tarjetas"      OF oForm SIZE 50,12 PIXEL
   @ 35,316 CHECKBOX oGet[12] VAR aForma[5] PROMPT "Cta.Cte."      OF oForm SIZE 50,12 PIXEL
   @ 35,370 CHECKBOX oGet[13] VAR aForma[6] PROMPT "M.Pago"        OF oForm SIZE 50,12 PIXEL

   @ 51, 78 CHECKBOX oChk VAR lMismo ;
            PROMPT "El beneficio se aplica sobre los MISMOS articulos (mix de sabores/fragancias)";
            OF oForm SIZE 300,12 PIXEL ;
            ON CHANGE (IF(lMismo,nCantZ := nCantA,nil),ModoZ(lMismo,oSayZ,oBrwZ,oBot),oForm:Refresh())

   @ 65, 80 GET oGet[14] VAR nCantA PICTURE "9999" RIGHT OF oForm SIZE 35,12 PIXEL;
            VALID(IF(lMismo,(nCantZ := nCantA)>=0,.t.))
   @ 65,225 GET oGet[15] VAR nCantZ PICTURE "9999" RIGHT OF oForm SIZE 35,12 PIXEL WHEN(!lMismo)

   @ 80, 80 COMBOBOX oCbo VAR nTipoBenef ITEMS aBenef OF oForm PIXEL SIZE 100,12 ;
            ON CHANGE oForm:Refresh()
   @ 80,280 GET oGet[16] VAR nPrecioUni PICTURE "999999999.99" RIGHT OF oForm SIZE 60,12 PIXEL;
            WHEN(nTipoBenef = 1)
   @ 80,345 GET oGet[17] VAR nPorcentaje PICTURE "999.99" RIGHT OF oForm SIZE 40,12 PIXEL;
            WHEN(nTipoBenef = 2)
   @ 82,388 SAY "%" OF oForm PIXEL SIZE 10,12

   @ 97, 05 SAY "Articulos que participan / disparan (A)" OF oForm PIXEL SIZE 200,12 COLOR CLR_BLUE
   @ 97,245 SAY oSayZ PROMPT "Articulos que reciben el beneficio (Z)" OF oForm PIXEL SIZE 200,12 COLOR CLR_BLUE

   @110, 05 XBROWSE oBrwA ARRAY aDetA;
            COLUMNS 1,2;
            HEADERS "Codigo","Nombre del articulo";
            SIZES 80,340;
            OF oForm SIZE 205,90 PIXEL
   oBrwA:CreateFromCode()
   PintaBrw(oBrwA,0)
   oBrwA:bKeyDown := {|nKey| IF(nKey == VK_DELETE, QuitaArt(aDetA,oBrwA), nil)}

   @110,245 XBROWSE oBrwZ ARRAY aDetZ;
            COLUMNS 1,2;
            HEADERS "Codigo","Nombre del articulo";
            SIZES 80,340;
            OF oForm SIZE 205,90 PIXEL
   oBrwZ:CreateFromCode()
   PintaBrw(oBrwZ,0)
   oBrwZ:bKeyDown := {|nKey| IF(nKey == VK_DELETE, QuitaArt(aDetZ,oBrwZ), nil)}

   @110,215 BUTTON oBot[1] PROMPT " + "  SIZE 22,12 OF oForm PIXEL ACTION(AgregaUno(oForm,aDetA,oBrwA))
   @125,215 BUTTON oBot[2] PROMPT " ++ " SIZE 22,12 OF oForm PIXEL ACTION(AgregaFiltro(oForm,aDetA,oBrwA))
   @140,215 BUTTON oBot[3] PROMPT " -  "  SIZE 22,12 OF oForm PIXEL ACTION(QuitaArt(aDetA,oBrwA))
   @110,455 BUTTON oBot[4] PROMPT " + "  SIZE 22,12 OF oForm PIXEL ACTION(AgregaUno(oForm,aDetZ,oBrwZ))
   @125,455 BUTTON oBot[5] PROMPT " ++ " SIZE 22,12 OF oForm PIXEL ACTION(AgregaFiltro(oForm,aDetZ,oBrwZ))
   @140,455 BUTTON oBot[6] PROMPT " -  "  SIZE 22,12 OF oForm PIXEL ACTION(QuitaArt(aDetZ,oBrwZ))

   aCor := AcepCanc(oForm)
   @ aCor[1],aCor[2] BUTTON oBot[7] PROMPT "&Grabar"   OF oForm SIZE 30,10 ACTION ((lRta := .t.), oForm:End()) PIXEL
   @ aCor[3],aCor[4] BUTTON oBot[8] PROMPT "&Cancelar" OF oForm SIZE 30,10 ACTION ((lRta := .f.), oForm:End()) PIXEL CANCEL

ACTIVATE DIALOG oForm CENTER ON INIT ModoZ(lMismo,oSayZ,oBrwZ,oBot)

IF !lRta
   EXIT
ENDIF

//---- Validaciones ----
IF lMismo
   nCantZ := nCantA
ENDIF
cFormaPago := ""
FOR i := 1 TO 6
   cFormaPago += IF(aForma[i],ALLTRIM(STR(i))+",","")
NEXT
cFormaPago := IF(EMPTY(cFormaPago),"",LEFT(cFormaPago,LEN(cFormaPago)-1))

IF EMPTY(ALLTRIM(cNomPromo))
   MsgStop("Hay que cargar el nombre de la promo.","Error")
   LOOP
ENDIF
IF EMPTY(cFormaPago)
   MsgStop("Hay que marcar al menos una forma de pago.","Error")
   LOOP
ENDIF
IF dDesde > dHasta
   MsgStop("La fecha 'Desde' no puede ser posterior a la fecha 'Hasta'.","Error")
   LOOP
ENDIF
IF nCantA <= 0
   MsgStop("Hay que cargar la cantidad que dispara la promo (N), mayor a cero.","Error")
   LOOP
ENDIF
IF nCantZ <= 0
   MsgStop("Hay que cargar la cantidad que recibe el beneficio (M), mayor a cero.","Error")
   LOOP
ENDIF
IF nTipoBenef = 1 .and. nPrecioUni <= 0
   MsgStop("Con beneficio por precio unitario hay que cargar un precio mayor a cero.","Error")
   LOOP
ENDIF
IF nTipoBenef = 2 .and. (nPorcentaje <= 0 .or. nPorcentaje > 100)
   MsgStop("El porcentaje de descuento tiene que estar entre 0 y 100.","Error")
   LOOP
ENDIF
IF LEN(aDetA) == 0
   MsgStop("Hay que cargar al menos un articulo en el grupo que participa (A).","Error")
   LOOP
ENDIF
IF !lMismo .and. LEN(aDetZ) == 0
   MsgStop("Hay que cargar al menos un articulo en el grupo que recibe el beneficio (Z),"+CHR(10)+;
           "o tildar que el beneficio se aplica sobre los mismos articulos.","Error")
   LOOP
ENDIF

IF Grabar(lAlta,nId,cNomPromo,dDesde,dHasta,cHoraIni,cHoraFin,cFormaPago,;
          nCantA,nCantZ,lMismo,nTipoBenef,nPrecioUni,nPorcentaje,nMaxAplica,nPrioridad,;
          aDetA,aDetZ)
   EXIT
ENDIF
ENDDO
oFont:End()
RETURN nil


***********************************
** Muestra u oculta el bloque Z segun la modalidad
STATIC FUNCTION ModoZ(lMismo, oSayZ, oBrwZ, oBot)
IF lMismo
   oSayZ:Hide()
   oBrwZ:Hide()
   oBot[4]:Hide()
   oBot[5]:Hide()
   oBot[6]:Hide()
ELSE
   oSayZ:Show()
   oBrwZ:Show()
   oBot[4]:Show()
   oBot[5]:Show()
   oBot[6]:Show()
ENDIF
RETURN nil


***********************************
** Detalle de un grupo, para un rol, como array {codart, nombre}
STATIC FUNCTION CargaDetalle(nId, cRol)
LOCAL aRet := {}, oQryDet
oQryDet := oApp:oServer:Query("SELECT d.codart, a.nombre FROM ge_"+oApp:cId+"promo_grupo_det d "+;
           "LEFT JOIN ge_"+oApp:cId+"articu a ON a.codigo = d.codart "+;
           "WHERE d.grupo_id = "+ClipValue2Sql(nId)+" AND d.rol = "+ClipValue2Sql(cRol)+" ORDER BY a.nombre")
oQryDet:GoTop()
DO WHILE !oQryDet:Eof()
   AADD(aRet,{oQryDet:codart, PADR(ALLTRIM(cValToChar(oQryDet:nombre)),50)})
   oQryDet:Skip()
ENDDO
oQryDet:End()
RETURN aRet


***********************************
** Agrega un articulo por codigo
STATIC FUNCTION AgregaUno(oForm, aDet, oBrw)
LOCAL oDlgA, oQryArt, nArticu := 0, cNomArt := SPACE(50), oGet1, oGet2,;
      oBot := ARRAY(2), aCor := ARRAY(4), lRta := .f.
oQryArt := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"articu ")
DEFINE DIALOG oDlgA TITLE "Seleccione el articulo" FROM 05,15 TO 13,90 OF oForm
   @ 12, 05 SAY "Articulo:" OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 10, 50 GET oGet1 VAR nArticu OF oDlgA PIXEL PICTURE "99999999999999" SIZE 45,12 RIGHT;
               VALID(BuscarArt(oQryArt,oDlgA,oGet1,oGet2));
               ACTION (oGet1:cText:= 0, BuscarArt(oQryArt,oDlgA,oGet1,oGet2)) BITMAP "BUSC1"
   @ 25, 50 GET oGet2 VAR cNomArt OF oDlgA PIXEL PICTURE "@!" WHEN(.f.)
   aCor := AcepCanc(oDlgA)
   @ aCor[1],aCor[2] BUTTON oBot[1] PROMPT "&Agregar"  OF oDlgA SIZE 30,10 ACTION ((lRta := .t.), oDlgA:End()) PIXEL
   @ aCor[3],aCor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ACTION ((lRta := .f.), oDlgA:End()) PIXEL CANCEL
   oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)}
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet1:SetFocus()
IF lRta .and. nArticu > 0
   IF ASCAN(aDet,{|x| x[1] == nArticu}) > 0
      MsgInfo("Ese articulo ya esta en la lista.","Atencion")
   ELSE
      AADD(aDet,{nArticu, PADR(ALLTRIM(oGet2:VarGet()),50)})
      oBrw:GoBottom()
      oBrw:Refresh()
   ENDIF
ENDIF
oQryArt:End()
RETURN nil


***********************************
** Agrega articulos en forma masiva por filtro (rubro, marca, empresa, proveedor, depto)
STATIC FUNCTION AgregaFiltro(oForm, aDet, oBrw)
LOCAL oDlgA, oGet := ARRAY(10), oBot := ARRAY(2), aCor := ARRAY(4), lRta := .f.,;
      cWhere, oQryArt, nAgreg := 0, nRepe := 0,;
      nCodProv:=0,cNomProv:="TODOS"+SPACE(45),oQryProv:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"provee"),;
      nCodMar:=0,cNomMar:="TODOS"+SPACE(25),oQryMar:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"marcas"),;
      nCodRub:=0,cNomRub:="TODOS"+SPACE(25),oQryRub:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"rubros"),;
      nCodEmp:=0,cNomEmp:="TODOS"+SPACE(25),oQryEmp:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"empresas"),;
      nCodDto:=0,cNomDto:="TODOS"+SPACE(25),oQryDto:= oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"deptos")

DEFINE DIALOG oDlgA TITLE "Agregar articulos por filtro" FROM 05,15 TO 19,90 OF oForm
   @ 12, 05 SAY "Proveedor:"    OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 27, 05 SAY "Marca:"        OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 42, 05 SAY "Empresa:"      OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 57, 05 SAY "Departamento:" OF oDlgA PIXEL SIZE 40,12 RIGHT
   @ 72, 05 SAY "Rubro:"        OF oDlgA PIXEL SIZE 40,12 RIGHT

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

   aCor := AcepCanc(oDlgA)
   @ aCor[1],aCor[2] BUTTON oBot[1] PROMPT "&Filtrar"  OF oDlgA SIZE 30,10 ACTION ((lRta := .t.), oDlgA:End()) PIXEL
   @ aCor[3],aCor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oDlgA SIZE 30,10 ACTION ((lRta := .f.), oDlgA:End()) PIXEL CANCEL
   oDlgA:bKeyDown = { | nKey, nFlags | IF(nKey==120,oBot[1]:Click,.f.)}
ACTIVATE DIALOG oDlgA CENTER ON INIT oGet[1]:SetFocus()

IF lRta
   IF EMPTY(nCodProv) .and. EMPTY(nCodMar) .and. EMPTY(nCodRub) .and. EMPTY(nCodEmp) .and. EMPTY(nCodDto)
      IF !MsgNoYes("No pusiste ningun filtro: se van a agregar TODOS los articulos."+CHR(10)+"Confirma?","Atencion")
         lRta := .f.
      ENDIF
   ENDIF
ENDIF
IF lRta
   cWhere := " WHERE 1=1 " ;
             + IF(EMPTY(nCodProv),""," AND prov ="    + ClipValue2Sql(nCodProv)) ;
             + IF(EMPTY(nCodMar), ""," AND marca ="   + ClipValue2Sql(nCodMar)) ;
             + IF(EMPTY(nCodRub), ""," AND rubro ="   + ClipValue2Sql(nCodRub)) ;
             + IF(EMPTY(nCodEmp), ""," AND empresa =" + ClipValue2Sql(nCodEmp)) ;
             + IF(EMPTY(nCodDto), ""," AND depto ="   + ClipValue2Sql(nCodDto))
   Procesando(.t.)
   oQryArt := oApp:oServer:Query("SELECT codigo,nombre FROM ge_"+oApp:cId+"articu"+cWhere+" ORDER BY nombre")
   oQryArt:GoTop()
   DO WHILE !oQryArt:Eof()
      IF ASCAN(aDet,{|x| x[1] == oQryArt:codigo}) > 0
         nRepe++
      ELSE
         AADD(aDet,{oQryArt:codigo, PADR(ALLTRIM(cValToChar(oQryArt:nombre)),50)})
         nAgreg++
      ENDIF
      oQryArt:Skip()
   ENDDO
   oQryArt:End()
   Procesando(.f.)
   oBrw:GoTop()
   oBrw:Refresh()
   MsgInfo("Se agregaron "+ALLTRIM(STR(nAgreg))+" articulo(s)."+CHR(10)+;
           IF(nRepe>0,ALLTRIM(STR(nRepe))+" ya estaban en la lista y no se repitieron.",""),"Listo")
ENDIF
oQryProv:End()
oQryMar:End()
oQryRub:End()
oQryEmp:End()
oQryDto:End()
RETURN nil


***********************************
** Saca de la lista el articulo posicionado
STATIC FUNCTION QuitaArt(aDet, oBrw)
LOCAL n
IF LEN(aDet) == 0
   RETURN nil
ENDIF
n := oBrw:nArrayAt
IF n < 1 .or. n > LEN(aDet)
   RETURN nil
ENDIF
ADEL(aDet,n)
ASIZE(aDet,LEN(aDet)-1)
IF LEN(aDet) == 0
   oBrw:nArrayAt := 1
ELSE
   oBrw:nArrayAt := MIN(n,LEN(aDet))
ENDIF
oBrw:Refresh()
RETURN nil


***********************************
** Grabado de cabecera + detalle en una transaccion.
** Devuelve .T. si grabo bien.
STATIC FUNCTION Grabar(lAlta,nId,cNomPromo,dDesde,dHasta,cHoraIni,cHoraFin,cFormaPago,;
                       nCantA,nCantZ,lMismo,nTipoBenef,nPrecioUni,nPorcentaje,nMaxAplica,nPrioridad,;
                       aDetA,aDetZ)
LOCAL oError, i, cCampos, lOk := .f.
cCampos := "nompromo,fecha_inicio,fecha_fin,hora_inicio,hora_fin,formapago,cant_a,cant_z,"+;
           "mismo_grupo,tipo_benef,precio_unitario,porcentaje,max_aplica,prioridad"
Procesando(.t.)
TRY
   oApp:oServer:BeginTransaction()
   IF lAlta
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"promo_grupo ("+cCampos+") VALUES ("+;
         ClipValue2Sql(ALLTRIM(cNomPromo))+","+ClipValue2Sql(dDesde)+","+ClipValue2Sql(dHasta)+","+;
         ClipValue2Sql(cHoraIni+":00")+","+ClipValue2Sql(cHoraFin+":59")+","+;
         ClipValue2Sql(cFormaPago)+","+ClipValue2Sql(nCantA)+","+ClipValue2Sql(nCantZ)+","+;
         ClipValue2Sql(IF(lMismo,1,0))+","+ClipValue2Sql(nTipoBenef)+","+;
         ClipValue2Sql(nPrecioUni)+","+ClipValue2Sql(nPorcentaje)+","+;
         ClipValue2Sql(nMaxAplica)+","+ClipValue2Sql(nPrioridad)+")")
      //LAST_INSERT_ID() es por conexion: con dos terminales dando de alta a la vez
      //un SELECT MAX(id) podria devolver el id del otro y cruzar los detalles
      //Si fallara, los INSERT del detalle rebotan contra la FK y cae en el CATCH
      nId := oApp:oServer:Query("SELECT LAST_INSERT_ID() AS nuevo"):nuevo
   ELSE
      oApp:oServer:Execute("UPDATE ge_"+oApp:cId+"promo_grupo SET "+;
         "nompromo = "+ClipValue2Sql(ALLTRIM(cNomPromo))+","+;
         "fecha_inicio = "+ClipValue2Sql(dDesde)+","+;
         "fecha_fin = "+ClipValue2Sql(dHasta)+","+;
         "hora_inicio = "+ClipValue2Sql(cHoraIni+":00")+","+;
         "hora_fin = "+ClipValue2Sql(cHoraFin+":59")+","+;
         "formapago = "+ClipValue2Sql(cFormaPago)+","+;
         "cant_a = "+ClipValue2Sql(nCantA)+","+;
         "cant_z = "+ClipValue2Sql(nCantZ)+","+;
         "mismo_grupo = "+ClipValue2Sql(IF(lMismo,1,0))+","+;
         "tipo_benef = "+ClipValue2Sql(nTipoBenef)+","+;
         "precio_unitario = "+ClipValue2Sql(nPrecioUni)+","+;
         "porcentaje = "+ClipValue2Sql(nPorcentaje)+","+;
         "max_aplica = "+ClipValue2Sql(nMaxAplica)+","+;
         "prioridad = "+ClipValue2Sql(nPrioridad)+" "+;
         "WHERE id = "+ClipValue2Sql(nId))
   ENDIF
   //El detalle se reescribe completo: es chico y evita tener que diferenciar altas de bajas
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"promo_grupo_det WHERE grupo_id = "+ClipValue2Sql(nId))
   FOR i := 1 TO LEN(aDetA)
      oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"promo_grupo_det (grupo_id,codart,rol) VALUES ("+;
         ClipValue2Sql(nId)+","+ClipValue2Sql(aDetA[i][1])+",'A')")
   NEXT
   //En el Mix, Z es el mismo conjunto que A y no se duplica en la base: el motor lo resuelve
   IF !lMismo
      FOR i := 1 TO LEN(aDetZ)
         oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"promo_grupo_det (grupo_id,codart,rol) VALUES ("+;
            ClipValue2Sql(nId)+","+ClipValue2Sql(aDetZ[i][1])+",'Z')")
      NEXT
   ENDIF
   oApp:oServer:CommitTransaction()
   lOk := .t.
CATCH oError
   oApp:oServer:RollBack()
   Procesando(.f.)
   ValidaError(oError)
END TRY
IF lOk
   Procesando(.f.)
ENDIF
RETURN lOk


***********************************
** Baja (el detalle se va solo por el ON DELETE CASCADE)
STATIC FUNCTION Baja()
LOCAL oError, nNum
IF oQry:nRecCount == 0
   RETURN nil
ENDIF
nNum := oQry:id
IF !MsgNoYes("Seguro de eliminar la promo por grupo Nro. "+ALLTRIM(STR(nNum))+"?"+CHR(10)+;
             "Se borran tambien los articulos que tenga cargados.","Atencion")
   RETURN nil
ENDIF
TRY
   oApp:oServer:BeginTransaction()
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"promo_grupo_det WHERE grupo_id = "+ClipValue2Sql(nNum))
   oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"promo_grupo WHERE id = "+ClipValue2Sql(nNum))
   oApp:oServer:CommitTransaction()
CATCH oError
   oApp:oServer:RollBack()
   ValidaError(oError)
END TRY
RETURN nil


*************************************
** Cerrar el modulo
STATIC FUNCTION Cerrar()
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
