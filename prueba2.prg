#include "fivewin.ch"
MEMVAR oApp
STATIC oQry, oWnd1, oBrw, oDlg, cVentana, oForm
PROCEDURE Reporte(cUser,cOpcion)   
   LOCAL oExpBar
   LOCAL oPanel1, bBloque
   LOCAL hHand
   oQry := oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo"+;
                            " WHERE usuario = "+ClipValue2SQL(cUser)+ ;
                            " AND padre = " + + ClipValue2Sql(cOpcion) +;
                            " ORDER BY codigo ")
      
   cVentana := PROCNAME()
   IF ASCAN(oApp:aVentanas,cVentana) > 0
      hHand := ASCAN(oApp:aVentanas,cVentana)
      oApp:oWnd:Select(hHand)
      oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
      RETURN
   ENDIF
   IF oApp:oServer:Query( "SELECT * FROM ge_"+oApp:cId+"menu_nuevo"+;
                            " WHERE usuario = "+ClipValue2SQL(cUser)+ ;
                            " AND modulo = 'CREUSU' "):nRecCount > 0   // Si tiene permiso a usuarios
      IF !oApp:oServer:TableExist("ge_"+oApp:cId+"consultas_per")
         oApp:oServer:Execute("CREATE TABLE `ge_"+oApp:cId+"consultas_per` ( "+;
          "`ID` int(4) NOT NULL AUTO_INCREMENT, "+;
          "`ITEM` varchar(40) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM1` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM2` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM3` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM4` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM5` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM6` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM7` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM8` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM9` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`PARAM0` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO1` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO2` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO3` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO4` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO5` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO6` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO7` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO8` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO9` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TEXTO0` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`SQL` text COLLATE utf8_spanish_ci, "+;
          "`FORMATO` varchar(250) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`TITULO` varchar(250) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "`ANCHO` varchar(250) COLLATE utf8_spanish_ci DEFAULT NULL, "+;
          "PRIMARY KEY (`ID`) "+;
        ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci")
      ENDIF
   ENDIF
   AADD(oApp:aVentanas,cVentana)
   
   DEFINE WINDOW oWnd1 TITLE "Reportes" MDICHILD OF oApp:oWnd NOZOOM ICON oApp:oIco
   
   oWnd1:SetSize( 350, oApp:oWnd:oWndClient:nHeight())

   oExpBar = TExplorerBar():New()
   *--
   oPanel1 = oExpBar:AddPanel( " Reportes " , ".\BITMAPS\rbnmenu.bmp"  )
   oPanel1:lSpecial:=.T.
   DO WHILE !oQry:Eof()
      bBloque := "{|| "+ALLTRIM(oQry:modulo)+"('"+oQry:permisos+"')}"
      bBloque := &bBloque
      oPanel1:AddLink( oQry:detalle, bBloque, "IMPR1")
      oQry:Skip()
   ENDDO
   IF oApp:usua_es_supervisor
       bBloque := "{|| (REP_PERSONA())}"
       bBloque := &bBloque
       oPanel1:AddLink( "Reportes personalizados", bBloque, "IMPR1")
   ENDIF
   oWnd1:oClient = oExpBar
   ACTIVATE WINDOW oWnd1 ON INIT oWnd1:move(0,0) VALID(cerrar())
 
RETURN

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