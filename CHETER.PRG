#include "Fivewin.ch"
#include "xbrowse.ch"
#include "Tdolphin.ch"
#include "hbcompat.ch"
*************************************************
** Cheques de Terceros
*************************************************
MEMVAR oApp
STATIC oQryBrw,oQry,oQry2,oQry3,oQry4,oQry5, oWnd1,oForm, oBrw, oDlg, lEdit := .f., cVentana, oError
PROCEDURE Cheter(cPermisos)
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
   oQryBrw:= oApp:oServer:Query("SELECT c.*, b.nombre AS nomban " +; 
                                " FROM ge_"+oApp:cId+"cheter c" +;
                                " LEFT JOIN ge_"+oApp:cId+"bancos b ON b.codigo = c.numban")
   
   oQry2 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"bancos ORDER BY codigo")
   oQry3 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"provee ORDER BY codigo")
   oQry4 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"clientes ORDER BY codigo")
   oQry5 := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"cuentas")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Cheques de terceros" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
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
            ACTION oBrw:ToExcel() ;
            PROMPT "Exporta" TOP WHEN(oQryBrw:RecCount()>0 .AND. "E"$cPermisos)
         DEFINE BUTTON RESOURCE "IMPR" OF oBar ;
            TOOLTIP "Imprimir Planilla"  ;
            ACTION oBrw:Report("Reporte de Cheques de terceros",.T.,.F.);
            PROMPT "Reporte" TOP WHEN(oQryBrw:RecCount()>0 .AND. "R"$cPermisos)
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
              COLUMNS "numche","nomban","fecing","fecvto","importe","estado";
              HEADERS "Numero","Banco","Emisión","Vencimiento","Importe","Estado";
              FOOTERS;
              SIZES   80,250,100,100,100,50;
             ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,(Formu( .f.),oBrw:Refresh()),nil)
     REDEFINE SAY oBrw:oSeek PROMPT oBrw:cSeek ID 113 OF oDlg
     oQryBrw:bOnChangePage := {|| oBrw:Refresh() }
     oBrw:aCols[5]:nFooterType := AGGR_SUM
     oBrw:aCols[6]:bStrData := {|| IF(oQryBrw:RecCount()> 0 .and. (oQryBrw:estado="C"),"En Cartera",;
     	                             IF(oQryBrw:RecCount()> 0 .and. (oQryBrw:estado="D"),"Depositado",;
                                   IF(oQryBrw:RecCount()> 0 .and. (oQryBrw:estado="R"),"Rechazado","Entregado")))}
     oBrw:aCols[6]:bClrStd := { || IF(oQryBrw:RecCount()> 0 .and. (oQryBrw:estado="R"), ;
                         { CLR_WHITE, RGB(255,55,55) },Eval(oBrw:bClrStd))} 
     PintaBrw(oBrw,6)
     oBrw:Maketotals()
     oBrw:bKeyDown := {|nKey,nFlags| Acelerador2(nKey,oBar, oBrw,cPermisos,6)}
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg NOWAIT ON INIT oDlg:Move(0,0)    VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())
RETURN

*****************************************************************************
*****************************************************************************
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(13), oBot := ARRAY(5), lRta := .F., aCor, base,oGru,bGar,cCuenta:= SPACE(30),;
      banco2:= SPACE(30), nompro:= SPACE(30),nomcli:= SPACE(30),;
      vItems:={"Endoso","Despositado","Anulado"}, oFont
 

IF lAlta
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"cheter LIMIT 0")
   base := oQry:GetBlankRow()
   base:fecing:= DATE()
   base:fecvto:= DATE()+1   
   base:estado:= " "
   ELSE
   oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2SQL(oQryBrw:numban) +;
                                " and numche = " + ClipValue2SQL(oQryBrw:numche))
   base := oQry:GetRowObj()
   oQry2:GoTop()
   IF oQry2:Seek(base:numban,1) > 0
      cCuenta := oQry2:nombre
   ENDIF
   oQry3:GoTop()
   IF oQry3:Seek(base:codpro,1) > 0
      nompro := LTRIM(oQry3:nombre)
      ELSE
      nompro := "******************************"
   ENDIF  
   oQry4:GoTop()
   IF oQry4:Seek(base:codcli,1) > 0
      nomcli := LTRIM(oQry4:nombre)
   ENDIF 
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.
   DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Cheques de terceros";
       FROM 05,10 TO 34,65 OF oWnd1 FONT oFont ICON oApp:oIco
   acor := AcepCanc(oForm)

   
   @ 07, 05 SAY "Banco:"                OF oForm PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Número de cheque:"     OF oForm PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Entregado a:"          OF oForm PIXEL SIZE 50,12 RIGHT
   @ 52, 05 SAY "Orden de pago:"        OF oForm PIXEL SIZE 50,12 RIGHT
   @ 67, 05 SAY "Fecha de emisión:"     OF oForm PIXEL SIZE 50,12 RIGHT
   @ 82, 05 SAY "Fecha de Vto.:"        OF oForm PIXEL SIZE 50,12 RIGHT
   @ 97, 05 SAY "Importe:"              OF oForm PIXEL SIZE 50,12 RIGHT
   @112, 05 SAY "Recibido de:"          OF oForm PIXEL SIZE 50,12 RIGHT
   @127, 05 SAY "Recibo:"               OF oForm PIXEL SIZE 50,12 RIGHT
   @142, 05 SAY "Observaciones:"        OF oForm PIXEL SIZE 50,12 RIGHT

************************************************************************************************   
   @ 05, 60 GET oGet[01] VAR base:numban OF oForm PIXEL RIGHT PICTURE "999" SIZE 30,12 WHEN(lAlta);
                VALID(Buscar(oQry2,oForm,oGet[01],oGet[02]));
                ACTION (oGet[01]:cText:= 0, Buscar(oQry2,oForm,oGet[01],oGet[02])) BITMAP "BUSC1"
   @ 05,100 GET oGet[02] VAR cCuenta OF oForm PIXEL PICTURE "@!" WHEN(.f.)
   @ 20, 60 GET oGet[03] VAR base:numche  OF oForm PIXEL PICTURE "9999999999" RIGHT WHEN(lAlta);
                VALID(base:numche>0)
   @ 35, 60 GET oGet[04] VAR base:codpro  OF oForm PIXEL PICTURE "999999" RIGHT SIZE 30,12;
                VALID(IF(base:codpro=0,.t.,Buscar(oQry3,oForm,oGet[04],oGet[05])));
                ACTION (oGet[04]:cText:= 0, Buscar(oQry3,oForm,oGet[04],oGet[05])) BITMAP "BUSC1"  
   @ 35, 95 GET oGet[05] VAR nompro  OF oForm PIXEL PICTURE "@!" WHEN(.F.)
   @ 50, 60 GET oGet[06] VAR base:orden OF oForm PIXEL PICTURE "99999999" RIGHT
   @ 65, 60 GET oGet[07] VAR base:fecing OF oForm PIXEL CENTER PICTURE "@D"  
   @ 80, 60 GET oGet[08] VAR base:fecvto OF oForm PIXEL CENTER PICTURE "@D"
   @ 95, 60 GET oGet[09] VAR base:importe  OF oForm PIXEL PICTURE "999999999.99" RIGHT;
                VALID(base:importe>0)
   @110, 60 GET oGet[10] VAR base:codcli  OF oForm PIXEL PICTURE "999999" RIGHT SIZE 30,12;
                VALID(IF(base:codcli=0,.t.,Buscar(oQry4,oForm,oGet[10],oGet[11])));
                ACTION (oGet[10]:cText:= 0, Buscar(oQry4,oForm,oGet[10],oGet[11])) BITMAP "BUSC1"  
   @110, 95 GET oGet[11] VAR nomcli  OF oForm PIXEL PICTURE "@!" SIZE 110,12 WHEN(.F.)   
   @125, 60 GET oGet[12] VAR base:recibo OF oForm PIXEL PICTURE "9999999" RIGHT
   @140, 60 GET oGet[13] VAR base:observa OF oForm PIXEL MEMO SIZE 130,35
   @185, 20 BUTTON oBot[3] PROMPT "Depositar" OF oForm SIZE 50,12 PIXEL ACTION(IF(Deposita(@base),(lRta:=.t.,oForm:End()),nil));
                   WHEN(base:estado="C" .AND. base:codpro = 0)
   @185, 80 BUTTON oBot[5] PROMPT "RECHAZADO" OF oForm SIZE 50,12 PIXEL ACTION(IF(Rechazado(@base),(lRta:=.t.,oForm:End()),nil));
            WHEN(!lAlta)
   @185,140 BUTTON oBot[4] PROMPT "Volver a cartera" OF oForm SIZE 50,12 PIXEL ACTION(Devolver(@base),lRta:=.t.,oForm:End());
                   WHEN(base:estado$"DR")

   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[01]:SetFocus()
IF !lRta
   RETURN nil
ENDIF

IF lAlta
   oQry:GetBlankRow()
   base:estado:= "C"
ENDIF
IF base:codpro > 0 .and. base:estado <> "R"
	base:estado:= "E"
ENDIF

base:usuario:= oApp:usuario
base:ip     := oApp:cIp
base:fecmod := DATE()

oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQryBrw:Refresh(.t.)
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN nil

*********************************************************************************************
******* DEPOSITAR CHEQUE
STATIC FUNCTION Deposita(base)
LOCAL oError,oDlgC,oGet1:=ARRAY(2),oBot1:=ARRAY(2),acor,lRta:=.f.,nBanco:=0,cNomBan:=SPACE(30)

DEFINE DIALOG oDlgC TITLE "Elegir banco para depositar el cheque" FROM 05,15 TO 12,70 OF oForm
acor := AcepCanc(oDlgC)
	
	@ 12, 05 SAY "Banco:"   OF oDlgC PIXEL SIZE 30,12 RIGHT

    @ 10, 40 GET oGet1[1] VAR nBanco  PICTURE "99" OF oDlgC PIXEL RIGHT SIZE 25,12;
                 VALID(Buscar(oQry5,oDlgC,oGet1[01],oGet1[02]));
                 ACTION (oGet1[01]:cText:= 0, Buscar(oQry5,oDlgC,oGet1[01],oGet1[02])) BITMAP "BUSC1"
    @ 10, 70 GET oGet1[2] VAR cNomBan PICTURE "@!" OF oDlgC PIXEL WHEN(.F.)

    @ acor[1],acor[2] BUTTON oBot1[1] PROMPT "&Grabar" OF oDlgC SIZE 30,10 ;
           ACTION ((lRta := .t.), oDlgC:End() ) PIXEL
    @ acor[3],acor[4] BUTTON oBot1[2] PROMPT "&Cancelar" OF oDlgC SIZE 30,10 ;
           ACTION ((lRta := .f.), oDlgC:End() ) PIXEL CANCEL
ACTIVATE DIALOG oDlgC CENTER ON INIT oGet1[1]:SetFocus()
IF !lRta
	RETURN .F.
ENDIF

TRY
  oApp:oServer:BeginTransaction()
  base:nrodep:= oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"deposito")
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"deposito " + ;
                        " (banco,tipo,fecemi,fecacr,codtip,numope,detalle,importe) VALUE "+;
                        " ("+;
                          ClipValue2SQL(nBanco)+","+;
                          "'D',"+;
                          ClipValue2SQL(DATE())+","+;
                          ClipValue2SQL(DATE())+","+;
                          "2,0,'DEP.CHEQUE 3ro Nro "+STR(base:numche,8)+"',"+ClipValue2SQL(base:importe)+")")
  base:estado:="D"
  oApp:oServer:CommitTransaction()
CATCH oError
  ValidaError(oError)
END TRY
RETURN .T.

***************************************************************************************************
******* DEVOLVER CHEQUE A cartera
STATIC FUNCTION Devolver(base)
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"deposito WHERE id = "+ ClipValue2Sql(base:nrodep))
  base:nrodep:= 0
  base:estado:="C"
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
RETURN .t.

***************************************************************************************************
******* CHEQUE RECHAZADO
STATIC FUNCTION Rechazado(base)
TRY
  oApp:oServer:BeginTransaction()
  base:estado:="R"
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
END TRY
RETURN .t.

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
LOCAL mrta := .f., oError

mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"cheter WHERE numban = " + ClipValue2SQL(oQryBrw:numban) +;
                              " and numche = " + ClipValue2SQL(oQryBrw:numche))
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQryBrw:Refresh(.t.)
CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
oBrw:Refresh()
RETURN nil 

******************************************

STATIC FUNCTION FILT( )

LOCAL CWHERE, vdesde := CTOD("01/01/1990"), vhasta := CTOD("31/12/2500"), nEstado := 1 
LOCAL oGet1, oGet2, oGet3, oBot1, oBot2,oDlg1,base,oError, ;
      mrta := .f., aCor, aEstado := {"Todos","En cartera","Depositados","Entregados"} 


DEFINE DIALOG oDlg1 TITLE "FILTRADO de Cheques de Terceros" FROM 05,10 TO 14,60 OF oWnd1
   acor := AcepCanc(oDlg1)
  
   @ 07, 05 SAY "Desde Fecha Vto:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 22, 05 SAY "Hasta Fecha Vto:" OF oDlg1 PIXEL SIZE 60,12 RIGHT
   @ 37, 05 SAY "Estado:"          OF oDlg1 PIXEL SIZE 60,12 RIGHT
   
   @ 05, 70 GET oGet1 VAR vdesde PICTURE "@D" OF oDlg1 PIXEL 
   @ 20, 70 GET oGet2 VAR vhasta PICTURE "@D"  OF oDlg1 PIXEL 
   @ 35, 70 COMBOBOX oGet3 VAR nEstado  ITEMS aEstado SIZE 80,80 PIXEL
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Filtrar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER ON INIT oGet1:SetFocus()
IF !mRta
   RETURN nil
ENDIF    

cWhere = " fecvto >=" + ClipValue2SQL(vdesde) +;
      + "  and fecvto <= " + ClipValue2SQL(vhasta) ;
      + "  and " + IF(nEstado = 1," TRUE ", IF(nEstado = 2, " estado = 'C'",IF(nEstado=3," estado = 'D'"," estado = 'E'")))
oQryBrw:SetNewFilter(SET_WHERE,cWhere,.t.)
oBrw:Maketotals()
oBrw:Refresh()
RETURN nil