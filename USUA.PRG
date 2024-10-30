#include "Fivewin.ch"
#include "xbrowse.ch"
#include "tdolphin.ch"
*************************************************
** Generacion de usuarios
*************************************************
MEMVAR oApp 
STATIC oBrw, oWnd1, oDlg, cVentana, oQry, oQry1
PROCEDURE CreUsu(cPermisos)
LOCAL oBar, hHand
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN
ENDIF
AADD(oApp:aVentanas,cVentana)
oQry  := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"usuarios WHERE usuario <> 'BCNSOFT' ORDER BY nombre")
   // Defino el dialogo tomado del recurso ABMCAJA
   DEFINE WINDOW oWnd1 MDICHILD TITLE "Mantenimiento de usuarios" ;
          OF oApp:oWnd NOZOOM ICON oApp:oIco
         DEFINE BUTTONBAR oBar  SIZE 60,60 OF oWnd1 2010
         DEFINE BUTTON RESOURCE "ALTA" OF oBar ;
            TOOLTIP "Crear un nuevo usuario"  ;
            ACTION (Form( .t.),oBrw:Refresh());
            PROMPT "Agregar" TOP WHEN("A"$cPermisos)
         DEFINE BUTTON RESOURCE "MODI" OF oBar ;
            TOOLTIP "Modificar Usuario"  ;
            ACTION (Form( .f.),oBrw:Refresh());
            PROMPT "Modificar" TOP WHEN(oQry:RecCount()>0 .and. "M"$cPermisos)
         DEFINE BUTTON RESOURCE "BAJA" OF oBar ;
            TOOLTIP "Eliminar Registro"  ;
            ACTION (Baja(  ),oBrw:Refresh());
            PROMPT "Borrar" TOP WHEN(oQry:RecCount()>0 .and. "B"$cPermisos)
         DEFINE BUTTON RESOURCE "DUPL" OF oBar ;
            TOOLTIP "Crear nuevo usuario por permisos idénticos"  ;
            ACTION (Duplicar(  ),oBrw:Refresh());
            PROMPT "Duplicar" TOP WHEN(oQry:RecCount()>0 .and. "A"$cPermisos)
         // Este boton cierra la aplicacion
         DEFINE BUTTON RESOURCE "SALE" OF oBar;
            TOOLTIP "Cerrar Ventana" ;
            ACTION oWnd1:End();
            PROMPT "Cerrar" TOP
   oWnd1:bGotFocus := { || oDlg:SetFocus}
   oWnd1:bResized := { || Incrusta( oWnd1, oDlg, .t.) }
     DEFINE DIALOG oDlg RESOURCE "ABMS" OF oWnd1
     REDEFINE XBROWSE oBrw DATASOURCE oQry;
              COLUMNS "usuario","nombre";
              HEADERS "Usuario","Nombre Completo";
              SIZES 120,400;
              ID 111 OF oDlg AUTOSORT ON DBLCLICK IF("M"$cPermisos,Form( .f.),NIL)
     oQry:bOnChangePage := {|| oBrw:Refresh() }
     REDEFINE SAY oBrw:oSeek PROMPT "" ID 113 OF oDlg
     PintaBrw(oBrw,2)
     // Activo el dialogo y al iniciar muevo a 0,0
     ACTIVATE DIALOG oDlg CENTER NOWAIT ON INIT oDlg:Move(0,0) VALID(oWnd1:End())
   ACTIVATE WINDOW oWnd1 ON INIT Incrusta( oWnd1, oDlg, .T.) VALID(cerrar())

******************************************
** Formulario de Usuarios
STATIC FUNCTION Form ( lAlta )
LOCAL oGet1, oGet2, oGet3, oGet4, oCom, oBtn, oBot1, oBot2, oBot3, oDlg1,;
      mrta := .f., base, mclave1 := SPACE(15), mclave2 := SPACE(15), oBrw1,  oError, lSuper := .f.
IF lAlta
   base := oQry:GetBlankRow()
   ELSE
   base := oQry:GetRowObj()
   oQry:lAppend := .f.
   mclave1 := base:clave
   mclave2 := base:clave
   lSuper := (upper(base:tipo) = "ADMIN")
ENDIF
SetearPermisos(base:usuario)
DEFINE DIALOG oDlg1 RESOURCE "CREAUSU" OF oWnd1
   oDlg1:lhelpIcon := .f.
   REDEFINE GET oGet1 VAR base:nombre   OF oDlg1 ID 109
   REDEFINE GET oGet2 VAR base:usuario  OF oDlg1 ID 110 WHEN(lAlta)
   REDEFINE GET oGet3 VAR mclave1       OF oDlg1 ID 111
   REDEFINE GET oGet4 VAR mclave2       OF oDlg1 ID 112
   oGet3:lPassword := .t.
   oGet4:lPassword := .t.
   REDEFINE CHECKBOX oCom VAR lSuper    OF oDlg1 ID 305
   REDEFINE BTNBMP oBtn RESOURCE "OJO"  OF oDlg1 ID 304 ACTION(VerClave(oGet3,oGet4)) WHEN(oApp:usua_es_supervisor)
   
   REDEFINE XBROWSE oBrw1 DATASOURCE oQry1;
              COLUMNS "modulo","detalle","codigo","permiso","permisos";
              HEADERS "Modulo","Descripcion Modulo","Orden","Permiso","Permisos";
              SIZES 100,250,50,80,113;
              ID 200 OF oDlg1 
   //oBrw1:SetRdd()              
   *PintaBrw(oBrw1,0)
   oBrw1:bClrStd := { || IF(oQry1:codigo = oQry1:padre,{CLR_BLACK, RGB(36,125,133)},;
                         If( oBrw1:KeyNo() % 2 == 0, ;
                         { CLR_BLACK, RGB(193,221,255) }, ;
                         { CLR_BLACK, RGB(221,245,255) } )) }  
   oBrw1:bClrSel := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }
   oBrw1:lColDividerComplete  := .t.                    
   oBrw1:nColDividerStyle     := LINESTYLE_INSET
   oBrw1:nRowDividerStyle     := LINESTYLE_INSET
   oBrw1:bClrSelFocus  := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }  // para barra de linea selecc cuando el control tiene el foco
   oBrw1:nMarqueeStyle    := MARQSTYLE_HIGHLCELL   
   oBrw1:aCols[4]:bLDClickData := {|| CambiaChek(oBrw1)}
   oBrw1:aCols[4]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oBrw1))}
   oBrw1:aCols[4]:bOnChange := {|| (oQry1:permisos:=IF(oQry1:permiso,"ABMRE","     "),oQry1:Save(),oBrw1:Refresh())}
   oBrw1:aCols[4]:nEditType := 1
   oBrw1:aCols[4]:bEditValue := {|| IF( oQry1:permiso="S", .t., .f. )  }
   oBrw1:aCols[4]:SetCheck(,.t.)
   oBrw1:aCols[5]:nEditType := EDIT_GET

   //oBrw1:aCols[4]:nEditType := EDIT_GET
   //*oBrw1:aCols[4]:bEditValue := {|| IF( oQry1:permiso=0, .f., .t. )  }
   
   REDEFINE BUTTON oBot3 ID 104 OF oDlg1 ACTION (InvertirTildes(oBrw1))
   REDEFINE BUTTON oBot1 ID 102 OF oDlg1 ACTION ((mrta := .t.), oDlg1:End() )
   REDEFINE BUTTON oBot2 ID 103 OF oDlg1 ACTION ((mrta := .f.), oDlg1:End() ) CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
oQry1:End()
IF !mrta
   RETURN nil
ENDIF
IF mclave1 <>mclave2
   MsgStop("No coinciden las claves","Error")
   RETURN nil
ENDIF
base:clave := mclave1
base:tipo := IF(lSuper,'admin','')
IF lAlta
   oQry:GetBlankRow()
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario = "+ ClipValue2Sql(base:usuario))
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"menu_nuevo "+;
                        "(codigo,usuario,modulo,etiqueta,detalle,recurso,padre,permisos,reporte) " +;
                        " SELECT codigo, "+ClipValue2Sql(base:usuario)+",modulo,etiqueta,detalle,recurso,padre,permisos,reporte"+;
                        " FROM menues_temp WHERE permiso = 'S' ")
  IF oApp:usua_es_vendedor
    IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores WHERE nombre = "+ClipValue2Sql(base:usuario)):RecCount() = 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"vendedores (nombre,comision) VALUES("+;
                             ClipValue2Sql(base:usuario)+",0)")
    ENDIF
  ENDIF
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
RETURN nil

STATIC FUNCTION VerClave(oGet3,oGet4)
oGet3:lPassword := !oGet3:lPassword
oGet4:lPassword := !oGet4:lPassword
oGet3:Refresh()
oGet4:Refresh()
RETURN nil

STATIC FUNCTION CambiaChek(oBrw1)
LOCAL valor
valor := IF(oQry1:permiso='S','N','S')
oQry1:permiso := valor
oQry1:permisos := IF(valor='S',"ABMRE","     ")
oQry1:Save()
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil

*************************************
** Dar de baja un registro
STATIC FUNCTION Baja ( )
LOCAL mrta := .f., mnro, oError
mrta := MsgNoYes("Seguro de eliminar","Atencion")
IF !mrta
   RETURN nil
ENDIF
TRY
  oApp:oServer:BeginTransaction()
  oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario = "+ ClipValue2Sql(oQry:usuario))
  oQry:Delete()
  oApp:oServer:CommitTransaction()
  oQry:Refresh(.t.)

CATCH oError
  MsgStop("Error al borrar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
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

*******************************************
** Setea los permisos del usuario
STATIC FUNCTION SetearPermisos(usua)
LOCAL cSql, i
TEXT into  cSql
CREATE TEMPORARY TABLE IF NOT EXISTS `menues_temp` (
  `ITEM` int(6) NOT NULL AUTO_INCREMENT,
  `CODIGO` varchar(4) NOT NULL DEFAULT ' ' ,
  `USUARIO` varchar(15) ,
  `MODULO` varchar(15) NOT NULL DEFAULT ' ' ,
  `ETIQUETA` varchar(20) NOT NULL DEFAULT ' ' ,
  `DETALLE` varchar(40) NOT NULL DEFAULT ' ' ,
  `RECURSO` varchar(10) NOT NULL DEFAULT ' ' ,
  `PADRE` varchar(4) NOT NULL DEFAULT ' ' ,
  `PERMISOS` varchar(5) ,
  `REPORTE` varchar(1) NOT NULL DEFAULT ' ',
  `PERMISO` varchar(1) default ' ' ,
  PRIMARY KEY (`ITEM`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1
ENDTEXT

oApp:oServer:Execute(cSql)
*oQry1 := oApp:oServer:Query( "SELECT * FROM menues_temp")
*oQry1:Zap()
oApp:oServer:Execute("TRUNCATE menues_temp")
oApp:oServer:NextResult()
oApp:oServer:Execute("INSERT INTO menues_temp "+;
                     "(codigo,usuario,modulo,etiqueta,detalle,recurso,padre,permiso,permisos,reporte) "+;
                     "(SELECT m.codigo,"+ClipValue2Sql(usua)+;
                     ",m.modulo, m.etiqueta, m.detalle,m.recurso,m.padre,"+;
                     "IF(b.codigo IS NOT NULL,'S','N') , b.permisos,m.reporte FROM ge_"+oApp:cId+"menu_nuevo m   "+;
                     "LEFT JOIN (SELECT codigo,permisos FROM ge_"+oApp:cId+"menu_nuevo WHERE usuario = "+ClipValue2Sql(usua)+" "+;
                     "ORDER BY codigo) b ON m.codigo = b.codigo "+;
                     "WHERE m.usuario = '%%%%%%' ORDER BY m.codigo)")
*oApp:oServer:Execute("UPDATE menues_temp SET permiso = IF(permiso=0,0,1) ")
oApp:oServer:NextResult()
oQry1 := oApp:oServer:Query( "SELECT * FROM menues_temp")
oQry1:Refresh()
RETURN nil

*******************************************************
** CAMBIA TODOS LOS TILDES
STATIC FUNCTION InvertirTildes(oBrw1)
oApp:oServer:Execute("UPDATE menues_temp SET permiso = IF(permiso='S','N','S'), "+;
                                            "permisos = IF(permiso='N','     ','ABMRE')")
oQry1:Refresh()
oBrw1:Refresh()
RETURN nil

*******************************************************
** Duplicar Usuario 
STATIC FUNCTION Duplicar (  )
LOCAL oGet1, oGet2, oGet3, oGet4, oBot1, oBot2, oBot3, oDlg1,;
      mrta := .f., base, mclave1 := SPACE(15), mclave2 := SPACE(15), oBrw1,  oError, cUserDup
cUserDup := oQry:usuario      
base := oQry:GetBlankRow()
SetearPermisos(cUserDup)
DEFINE DIALOG oDlg1 RESOURCE "CREAUSU" OF oWnd1
   oDlg1:lhelpIcon := .f.
   REDEFINE GET oGet1 VAR base:nombre   OF oDlg1 ID 109
   REDEFINE GET oGet2 VAR base:usuario  OF oDlg1 ID 110 
   REDEFINE GET oGet3 VAR mclave1       OF oDlg1 ID 111
   REDEFINE GET oGet4 VAR mclave2       OF oDlg1 ID 112
   oGet3:lPassword := .t.
   oGet4:lPassword := .t.
   REDEFINE XBROWSE oBrw1 DATASOURCE oQry1;
              COLUMNS "modulo","detalle","codigo","permiso","permisos";
              HEADERS "Modulo","Descripcion Modulo","Orden","Permiso","Permisos";
              SIZES 100,250,50,80,113;
              ID 200 OF oDlg1 
   //oBrw1:SetRdd()              
   *PintaBrw(oBrw1,0)
   oBrw1:bClrStd := { || IF(oQry1:codigo = oQry1:padre,{CLR_BLACK, RGB(36,125,133)},;
                         If( oBrw1:KeyNo() % 2 == 0, ;
                         { CLR_BLACK, RGB(193,221,255) }, ;
                         { CLR_BLACK, RGB(221,245,255) } )) }  
   oBrw1:bClrSel := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }
   oBrw1:lColDividerComplete  := .t.                    
   oBrw1:nColDividerStyle     := LINESTYLE_INSET
   oBrw1:nRowDividerStyle     := LINESTYLE_INSET
   oBrw1:bClrSelFocus  := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }  // para barra de linea selecc cuando el control tiene el foco
   oBrw1:nMarqueeStyle    := MARQSTYLE_HIGHLCELL   
   oBrw1:aCols[4]:bLDClickData := {|| CambiaChek(oBrw1)}
   oBrw1:aCols[4]:bKeyDown := {|nKey, nFlags| IF(nKey==13,nil,CambiaChek(oBrw1))}
   oBrw1:aCols[4]:bOnChange := {|| (oQry1:permisos:=IF(oQry1:permiso,"ABMRE","     "),oQry1:Save(),oBrw1:Refresh())}
   oBrw1:aCols[4]:nEditType := 1
   oBrw1:aCols[4]:bEditValue := {|| IF( oQry1:permiso="S", .t., .f. )  }
   oBrw1:aCols[4]:SetCheck(,.t.)
   oBrw1:aCols[5]:nEditType := EDIT_GET

   //oBrw1:aCols[4]:nEditType := EDIT_GET
   //*oBrw1:aCols[4]:bEditValue := {|| IF( oQry1:permiso=0, .f., .t. )  }
   
   REDEFINE BUTTON oBot3 ID 104 OF oDlg1 ACTION (InvertirTildes(oBrw1))
   REDEFINE BUTTON oBot1 ID 102 OF oDlg1 ACTION ((mrta := .t.), oDlg1:End() )
   REDEFINE BUTTON oBot2 ID 103 OF oDlg1 ACTION ((mrta := .f.), oDlg1:End() ) CANCEL
ACTIVATE DIALOG oDlg1 CENTER 
oQry1:End()
IF !mrta
   RETURN nil
ENDIF
IF mclave1 <>mclave2
   MsgStop("No coinciden las claves","Error")
   RETURN nil
ENDIF
base:clave := mclave1
oQry:GetBlankRow()
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()  
  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"menu_nuevo "+;
                        "(codigo,usuario,modulo,etiqueta,detalle,recurso,padre,permisos,reporte) " +;
                        " SELECT codigo, "+ClipValue2Sql(base:usuario)+",modulo,etiqueta,detalle,recurso,padre,permisos,reporte"+;
                        " FROM menues_temp WHERE permiso = 'S' ")
  IF oApp:usua_es_vendedor
    IF oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"vendedores WHERE nombre = "+ClipValue2Sql(base:usuario)):RecCount() = 0
        oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+"vendedores (nombre,comision) VALUES("+;
                             ClipValue2Sql(base:usuario)+",0)")
    ENDIF
  ENDIF
  oApp:oServer:CommitTransaction()
CATCH oError
  MsgStop("Error al grabar"+CHR(10)+oError:description,"Error")
  oApp:oServer:RollBack()
END TRY
RETURN nil