#include "fivewin.ch"
#include "calendar.ch"
#include "calex.ch"
#include "tselex.ch"
#include "ord.ch"
#include "tdolphin.ch"
#include "Report.ch"

MEMVAR oApp
//----------------------------------------------------------------------------//
STATIC oCalex, oBrw, oQryBrw, cVentana, oDlgBrw, nFilter, nSeekWild, oSelec

FUNCTION Agenda()
LOCAL oWnd, oExBar, oDtPick, oPanelExplorer, oPanelCalex, oPanel, oPanel1, oPanel2, hHand, oGet := ARRAY(10),;
      oBot := ARRAY(5), nOption:=5, dDate := DATE()
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   hHand := ASCAN(oApp:aVentanas,cVentana)
   oApp:oWnd:Select(hHand)
   oApp:oWnd:oWndClient:aWnd[hHand]:Restore()
   RETURN nil
ENDIF
AADD(oApp:aVentanas,cVentana)

DEFINE WINDOW oWnd MDICHILD OF oApp:oWnd TITLE "Agenda " + oApp:usuanom ICON oApp:oIco
   *** Paneles
   oPanelExplorer = TPanel():New( 0, 0, oWnd:nHeight, 280, oWnd )
   
   oPanelCalex    = TPanel():New( 0, 281, oWnd:nHeight, oWnd:nWidth, oWnd )

   oExBar := TExplorerBar():New( 0, 0, 250, 300, oPanelExplorer )
   
   oPanel := oExBar:AddPanel( "Seleccionar Fecha", ".\bitmaps\CALENDAR2.bmp", 255 )
   oPanel:AddLink( "Ver Dia"    , { || oCalex:SetDayView() , SetDatas() }, ".\bitmaps\CALENDAR.bmp" )
   oPanel:AddLink( "Ver Semana" , { || oCalex:SetWeekView(), SetDatas() }, ".\bitmaps\CALENDAR.bmp" )
   oPanel:AddLink( "Ver mes"    , { || oCalex:SetMonthView(),SetDatas() }, ".\bitmaps\CALENDAR.bmp" )
   oPanel:AddLink( "Agregar cita"   , { || Cita("A",oCalex:oView) }, ".\bitmaps\additem.bmp" )
   oPanel:AddLink( "Modificar cita" , { || Cita("M",oCalex:oView),SetDatas() }, ".\bitmaps\edit.bmp" )
   oPanel:AddLink( "Eliminar cita " , { || Cita("B",oCalex:oView) }, ".\bitmaps\delete.bmp" )
   oPanel:AddLink( "Imprimir Citas" , { || Imprime(oCalex:dDate) }, ".\bitmaps\printer.bmp" )

   oPanel:bMMoved  := {|| oDlgBrw:Hide(), oCalex:Show(),  oPanelCalex:oClient := oCalex} 

    
   oPanel1 := oExBar:AddPanel( "Agenda", ".\bitmaps\people.bmp", 100 )
   oPanel1:AddLink( "Agregar contacto"  , { || Formu(.t.) }, ".\bitmaps\additem.bmp" )
   oPanel1:AddLink( "Eliminar contacto" , { || IF(MsgNoYes("Seguro de eliminar","Eliminar"),(oQryBrw:Delete(),oBrw:Refresh),.t.) }, ".\bitmaps\delete.bmp" )
   oPanel1:AddLink( "Modificar contacto", { || Formu(.f.) }, ".\bitmaps\edit.bmp" )   
   oPanel1:AddLink( "Exportar a Excel"  , { || oBrw:ToExcel() }, ".\bitmaps\excel.bmp" )   
   oPanel1:AddLink( "Reporte"           , { || oBrw:Report("Agenda de " + oApp:usuanom) }, ".\bitmaps\report.bmp" )   

   oPanel1:bMMoved := {|| oCalex:Hide(), oDlgBrw:Show(), oBrw:Refresh(), oBrw:SetFocus()} 

   oPanelExplorer:oClient = oExBar
   
   // Calendario 
   DEFINE CALEX oCalex OF oPanelCalex FIRST_DATE 0
   /*@170, 15 CALENDAR oDtPick VAR oCalex:dDateSelected OF oPanel PIXEL;
              SIZE 220, 157*/
   //Mes
   DEFINE MONTH VIEW OF oCalex ACTIVATE;
          START HOUR 7 ;
          END HOUR 20;
          ON SELECT VIEW SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),oDtPick:Refresh(), SetDatas()) ;
          ON SELECT DAY  SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),oDtPick:Refresh(), SetDatas()) ;
          ON SELECT WEEK SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),oDtPick:Refresh(), SetDatas()) ;
          ON NEXT        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),oDtPick:Refresh(), SetDatas()) ;
          ON PREV        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),oDtPick:Refresh(), SetDatas())
   //Dia
   DEFINE DAY VIEW OF oCalex ;
          INTERVAL 30 ;
          START HOUR 7 ;
          END HOUR 20;
          ON SELECT VIEW SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas()) ;
          ON NEXT        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas());
          ON PREV        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas())
   
   //Semana
   DEFINE WEEK VIEW OF oCalex ;
          INTERVAL 30 ;
          START HOUR 7 ;
          END HOUR 20 ;
          ON SELECT VIEW SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas()) ;
          ON NEXT        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas());
          ON PREV        SetDatas() ;//( oDtPick:SetDate( oCalex:dDateSelected ),SetDatas())
     // Calendario en el panel. Lo pono aca porque debe estar inicializado oCalex
  
   /*oDtPick:bChange =   { | o | ChangeDate( o ) }
   oCalex:bLClicked =  { | nRow,nCol | oDtPick:SetDate( oCalex:oView:dDateSelected )}
   oCalex:bLClicked =  { | nRow,nCol | oDtPick:SetDate( ;
   oCalex:oView:GetDateFromPos(oCalex:oMonthView:GetPosition( nRow, nCol )[1],oCalex:oMonthView:GetPosition( nRow, nCol )[2]))}
   */
   @180, 15 SAY "Intervalo (En minutos):" PIXEL OF oPanel TRANSPARENT
   @257, 15 SAY "Rango horario:"     PIXEL OF oPanel TRANSPARENT
   @200, 15 SELEX oSelec VAR nOption OF oPanel PIXEL SIZE 200, 45;
      ITEMS "5", "10", "15", "20", "30", "60" ;
      GRADIENT OUTTRACK { { 1/2, nRGB( 219, 230, 244 ), nRGB( 207-50, 221-25, 255 ) }, ;
                          { 1/2, nRGB( 201-50, 217-25, 255 ), nRGB( 231, 242, 255 ) } }; 
      LINECOLORS nRGB( 237, 242, 248 ), nRGB( 141, 178, 227 );
      COLORTEXT  CLR_BLACK, CLR_GREEN ;
      ACTION (oCalex:oView:SetInterval( Val( oSelec:aOptions[ nOption ])) , oCalex:Refresh() )
     
   @255,100 GET oGet[2] VAR oCalex:oView:nStartHour PICTURE "99" SIZE 30,20 PIXEL OF oPanel RIGHT ;
                VALID( oCalex:oView:nStartHour>=0 .AND. oCalex:oView:nStartHour <= (oCalex:oView:nEndHour - 1 ))
   @255,170 GET oGet[3] VAR oCalex:oView:nEndHour PICTURE "99" SIZE 30,20 PIXEL OF oPanel RIGHT ;
                VALID( oCalex:oView:nEndHour>=(oCalex:oView:nStartHour + 1) .and. oCalex:oView:nEndHour <= 24)
   oPanelCalex:oClient = oCalex
   oCalex:bLDblClick := {|nRow, nCol, nKeyFlags| MostrarInfo(nRow,nCol) }
   /*
   oCalex:bLDblClick := {|nRow, nCol, nKeyFlags| IF(oCalex:oView:oCalex:oCalInfoSelected==nil,.f.,;
                  MsgInfo("Inicio cita: " + STR(oCalex:oView:oCalex:oCalInfoSelected:nStart) + CHR(10) +;
                  "Fin cita: "+ STR(oCalex:oView:oCalex:oCalInfoSelected:nEnd) + CHR(10) +;
                  "Del dia: " + DTOC(oCalex:oView:oCalex:oCalInfoSelected:dStart) + CHR(10)+;
                  "Motivo: " + oCalex:oView:oCalex:oCalInfoSelected:cSubject + CHR(10)+;
                  "Estado: " + IF(!oCalex:oView:oCalex:oCalInfoSelected:lAplicado,"Hecha","Pendiente") + CHR(10)+;
                  "ID Cita: " + STR(oCalex:oView:oCalex:oCalInfoSelected:nIdx),"Info"))}          
    */              
   // Browse agenda
   ArmarBrowse(oPanelCalex)
   oDlgBrw:Hide()

ACTIVATE WINDOW oWnd ON RESIZE (oPanelExplorer:Move( , , , oWnd:nHeight ),;
                                oPanelCalex:Move   ( , , oWnd:nWidth - oPanelExplorer:nRight, oWnd:nHeight - 60 ));
            ON INIT (oWnd:SetSize(oApp:oWnd:oWndclient:nWidth, oApp:oWnd:oWndclient:nHeight),oWnd:Move(0,0));
            VALID(Cerrar())

return nil

*** Mostrar Info 
STATIC FUNCTION MostrarInfo(nRow,nCol)
LOCAL oCI , cIni, cFin
IF nRow < 50 .or. nCol < 50
   RETURN nil 
ENDIF    
IF oCalex:IsKindOf( "TDAYVIEW" )
   oCI := oCalex:oDayView:oCalex:oCalInfoSelected
   ELSE
   oCI := oCalex:oWeekView:oCalex:oCalInfoSelected
ENDIF 
IF ! (oCI == nil )
   cIni := STR(oCI:nStart,4)
   cFin := STR(oCI:nStart,4)
   cIni := LEFT(cIni,2)+":"+RIGHT(cIni,2)
   cFin := LEFT(cFin,2)+":"+RIGHT(cFin,2)

   MsgInfo("Inicio cita: " + cIni + CHR(10) +;
                  "Fin cita: "+ cFin + CHR(10) +;
                  "Del dia: " + DTOC(oCI:dStart) + CHR(10)+;
                  "Motivo: " + oCI:cSubject + CHR(10)+;
                  "Estado: " + IF(!oCI:lAplicado,"Hecha","Pendiente") + CHR(10)+;
                  "ID Cita: " + STR(oCI:nIdx),"Info")
ENDIF
RETURN nil

*********************************
** Poner citas en agenda
STATIC FUNCTION SetDatas()
LOCAL i, j, dAnt, oQry, cColor, cCli
oCalex:Reset()
cColor := { { 1, nRGB( 145, 0, 204 ), nRGB( 145, 0, 053 ) } }
oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"citas WHERE fecha >= " + ClipValue2Sql(oCalex:oMonthView:GetDateFromPos( 1, 1 )) + " AND "+;
                           "fecha <= " + ClipValue2Sql(oCalex:oMonthView:GetDateFromPos( 5, 7 )) + ;
                           " AND usuario = "+ClipValue2Sql(oApp:usuario)+ " ORDER BY fecha,hora,id ")
oQry:GoTop()
do while !oQry:Eof()
   IF oQry:contacto > 0
      cCli := oApp:oServer:Query("SELECT nombre FROM ge_"+oApp:cId+"clientes WHERE codigo = "+ClipValue2Sql(oQry:contacto)):nombre 
      cCli := "Cliente: "+ALLTRIM(cCli) +" -"
      ELSE 
      cCli := ""
   ENDIF   
   oCalex:LoadDates( VAL(STRTRAN(oQry:hora,":","")), VAL(STRTRAN(oQry:horafin,":","")), ;
                     oQry:fecha, oQry:fecha, ALLTRIM(oQry:motivo), ALLTRIM(cCli)+ALLTRIM(oQry:motivo) + "-", oQry:id,.T.,!oQry:estado)
   oQry:Skip()
enddo
oCalex:Refresh()
RETURN nil  

*******************************************************************************
** Citas
STATIC FUNCTION Cita(cTipo, oV)
LOCAL cText, oV1, lRta, oQry 
IF oCalex:oView:IsKindOf( "TMONTHVIEW" ) 
   MsgStop("Agregar, modificar y eliminar en vista dia o mes","Error")
   RETURN nil
ENDIF
IF oV:oCalex:oCalInfoSelected == NIL .and. cTipo$"MB"
   MsgStop("No hay datos en ese horario para " + IF(cTipo="M","modificar","Eliminar"),"Error")
   RETURN nil
 ENDIF 
 DO CASE 
    CASE cTipo$"AM"
         oV1 := oV:oCalex:oCalInfoSelected
         oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"citas " + IF(ctipo="A","LIMIT 0","WHERE id="+ ClipValue2Sql(oV1:nIdx)))
         IF Formu1(oQry,cTipo="A",oV1)
            SetDatas()
            oV:BuildDates()
         ENDIF
    CASE cTipo = "B"
         oV1 := oV:oCalex:oCalInfoSelected
         cText := "Inicio cita:" + STR(oV1:nStart) + CHR(10) +;
                  "Fin cita:"    + STR(oV1:nEnd) + CHR(10) +;
                  "Del dia:" + DTOC(oV1:dStart) + CHR(10)+;
                  "Motivo:" + oV1:cSubject + CHR(10)+;
                  "ID Cita:" + STR(oV1:nIdx) 
         IF MsgNoYes(cText,"Seguro de eliminar?")            
            oApp:oServer:Execute("DELETE FROM ge_"+oApp:cId+"citas WHERE id=" + ClipValue2Sql(oV1:nIdx))       
            oCalex:DelCalInfo()            
         ENDIF 
ENDCASE
RETURN nil

************************************************
** Formulario de altas y modificaciones de citas
STATIC FUNCTION Formu1 (oQry,lAlta,oV)
LOCAL oGet := ARRAY(20), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oFont, oError, nHora, nHoraFin,;
      mhasta, mcada, lRepite := .f., i, aDias := ARRAY(7), aUsua, oBrwU

IF !lAlta .and. oQry:nRecCount = 0
   MsgStop("La cita fue borrada","Error")
   oCalex:Refresh()
   RETURN .t.
ENDIF   
afill(aDias, .f.)
IF lAlta
   aUsua := oApp:oServer:Query("SELECT usuario,altas FROM ge_"+oApp:cId+"usuarios"):FillArray(,{'usuario','altas'})
   FOR aCor := 1 TO LEN(aUsua)
       aUsua[aCor,2] := oApp:usuario = aUsua[aCor,1]
   NEXT
   base := oQry:GetBlankRow()
   base:id := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"citas")
   base:usuario := oApp:usuario
   IF oCalex:oView:nLastRow == nil
      nHora    := oCalex:oView:nStartHour * 100
      nHoraFin := oCalex:oView:nStartHour * 100
      ELSE
      nHora := oCalex:oView:GetTimeFromRow( oCalex:oView:nLastRow )
      nHorafin := oCalex:oView:GetTimeFromRow( oCalex:oView:nLastRow+1 )
   ENDIF   
   base:hora    := LEFT(STRTRAN(STR(nhora   ,4)," ","0"),2)+":" +RIGHT(STR(nhora,4),2)
   base:horafin := LEFT(STRTRAN(STR(nhorafin,4)," ","0"),2)+":" +RIGHT(STR(nhorafin,4),2)
   base:fecha := oCalex:oView:dDateSelected
   mhasta := base:fecha 
   mcada  := 7
   base:alerta := .t.
   ELSE
   base := oQry:GetRowObj()
   oQry:lAppend := .f.
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.

DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Citas";
       FROM 05,15 TO IF(lAlta,30,25),90 FONT oFont
   acor := AcepCanc(oForm)
   @ 07, 05 SAY "Id:"                OF oForm PIXEL SIZE 60,20 RIGHT
   @ 22, 05 SAY "Hora Inciio:"       OF oForm PIXEL SIZE 60,20 RIGHT
   @ 37, 05 SAY "Hora Final:"        OF oForm PIXEL SIZE 60,16 RIGHT
   @ 52, 05 SAY "Fecha Cita:"        OF oForm PIXEL SIZE 60,16 RIGHT
   @ 67, 05 SAY "Motivo:"            OF oForm PIXEL SIZE 60,16 RIGHT
   IF lAlta
      @127, 70 SAY "Repetir cada "   OF oForm PIXEL SIZE 55,16 RIGHT
      @127,150 SAY "dias"            OF oForm PIXEL SIZE 20,16  
      @142, 70 SAY "Hasta el dia:"   OF oForm PIXEL SIZE 55,16 RIGHT
   ENDIF   
   
 
   @ 05, 70 GET oGet[1] VAR base:id        OF oForm PICTURE "9999999" PIXEL RIGHT WHEN(.F.)
   @ 20, 70 GET oGet[2] VAR base:hora      OF oForm PIXEL RIGHT PICTURE "99:99" WHEN(!lAlta)
   @ 35, 70 GET oGet[3] VAR base:horafin   OF oForm PIXEL RIGHT PICTURE "99:99" WHEN(!lAlta)
   @ 50, 70 GET oGet[4] VAR base:fecha     OF oForm PIXEL CENTER 
   @ 65, 70 GET oGet[5] VAR base:motivo    OF oForm PIXEL CUEBANNER "Escriba el motivo de la cita" PICTURE "@S55"
   @ 80, 70 CHECKBOX oGet[7] VAR base:estado PROMPT "Esta cita esta cumplida" SIZE 100,13  OF oForm PIXEL 
   @ 95, 70 CHECKBOX oGet[8] VAR base:alerta PROMPT "Emitir alerta cuando llegue la hora" SIZE 100,13  OF oForm PIXEL 
   IF lAlta
      @ 110, 05 CHECKBOX oGet[9] VAR lRepite PROMPT "Repetir esta tarea" SIZE 100,13  OF oForm PIXEL 
      @ 125, 05 RADIO oGet[12] VAR i PROMPT "Cada","Los dias" OF oForm PIXEL SIZE 30, 12 WHEN(lRepite)
      @ 125,130 GET oGet[10] VAR mcada   PICTURE "999" OF oForm PIXEL VALID mcada > 0 WHEN(lRepite .AND. i=1) 
      @ 140,130 GET oGet[11] VAR mhasta  OF oForm PIXEL CENTER VALID mhasta > base:fecha WHEN(lRepite)
      @ 155, 02 CHECKBOX oGet[13] VAR aDias[1] PROMPT "Domingo" OF oForm PIXEL SIZE 30,12 WHEN(lRepite .AND. i=2) 
      @ 155, 40 CHECKBOX oGet[14] VAR aDias[2] PROMPT "Lunes"   OF oForm PIXEL SIZE 25,12 WHEN(lRepite .AND. i=2)
      @ 155, 80 CHECKBOX oGet[15] VAR aDias[3] PROMPT "Martes"  OF oForm PIXEL SIZE 25,12 WHEN(lRepite .AND. i=2)
      @ 155,120 CHECKBOX oGet[16] VAR aDias[4] PROMPT "Miercoles" OF oForm PIXEL SIZE 30,12 WHEN(lRepite .AND. i=2)
      @ 155,160 CHECKBOX oGet[17] VAR aDias[5] PROMPT "Jueves"  OF oForm PIXEL SIZE 25,12 WHEN(lRepite .AND. i=2)
      @ 155,200 CHECKBOX oGet[18] VAR aDias[6] PROMPT "Viernes" OF oForm PIXEL SIZE 25,12 WHEN(lRepite .AND. i=2)
      @ 155,240 CHECKBOX oGet[19] VAR aDias[7] PROMPT "Sabados" OF oForm PIXEL SIZE 30,12 WHEN(lRepite .AND. i=2)
      IF oApp:usua_es_supervisor
          @ 95,195 XBROWSE oBrwU SIZE 90,50 pixel OF oForm ARRAY aUsua ;
              HEADERS "Usuario", "Agendar";
              COLUMNS 1, 2 ;
              CELL LINES NOBORDER WHEN(oApp:usua_es_supervisor)
           WITH OBJECT oBrwU
              :aCols[2]:nEditType := EDIT_GET 
              :lRecordSelector := .f.
              :aCols[ 2 ]:SetCheck()
              :nFreeze := 2
              :CreateFromCode()
              :lHScroll := .f.
           END  
           PintaBrw(oBrwU,0)
      ENDIF     
   ENDIF
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 
IF !lRta
   RELEASE oFont
   RETURN .f.
ENDIF
IF lAlta
   oQry:GetBlankRow()
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  IF !lAlta
     oQry:Save()
     ELSE 
     FOR aCor := 1 TO LEN(aUsua)
         IF aUsua[aCor,2]
          oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+;
          "citas (fecha,hora,horafin,motivo,contacto,usuario,estado,alerta) "+;
          "VALUES ("+ClipValue2SQL(base:fecha)+","+ClipValue2SQL(base:hora)+","+ClipValue2SQL(base:horafin)+",";
          +ClipValue2SQL(base:motivo)+","+ClipValue2SQL(0)+","+ClipValue2SQL(aUsua[aCor,1])+","+;
          ClipValue2Sql(base:estado)+","+ClipValue2Sql(base:alerta)+")")
         ENDIF  
     NEXT 
  ENDIF
  IF lAlta .and. lRepite
     IF i = 1
        FOR i := base:fecha+mcada TO mhasta STEP mcada 
             FOR aCor := 1 TO LEN(aUsua)
                 IF aUsua[aCor,2]
                  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+;
                  "citas (fecha,hora,horafin,motivo,contacto,usuario,estado,alerta) "+;
                  "VALUES ("+ClipValue2SQL(i)+","+ClipValue2SQL(base:hora)+","+ClipValue2SQL(base:horafin)+",";
                  +ClipValue2SQL(base:motivo)+","+ClipValue2SQL(0)+","+ClipValue2SQL(aUsua[aCor,1])+","+;
                  ClipValue2Sql(base:estado)+","+ClipValue2Sql(base:alerta)+")")
                 ENDIF  
             NEXT 
        NEXT i 
        ELSE
        FOR i := base:fecha+1 TO mhasta
            IF aDias[DOW(i)] 
              FOR aCor := 1 TO LEN(aUsua)
                 IF aUsua[aCor,2]
                  oApp:oServer:Execute("INSERT INTO ge_"+oApp:cId+;
                  "citas (fecha,hora,horafin,motivo,contacto,usuario,estado,alerta) "+;
                  "VALUES ("+ClipValue2SQL(i)+","+ClipValue2SQL(base:hora)+","+ClipValue2SQL(base:horafin)+",";
                  +ClipValue2SQL(base:motivo)+","+ClipValue2SQL(0)+","+ClipValue2SQL(aUsua[aCor,1])+","+;
                  ClipValue2Sql(base:estado)+","+ClipValue2Sql(base:alerta)+")")
                 ENDIF  
              NEXT 
            ENDIF
        NEXT i
     ENDIF   
  ENDIF       
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RELEASE oFont
RETURN .t.

*******************************************************************************
** Browse de la agenda
STATIC FUNCTION ArmarBrowse(oWnd)
nFilter := 1
nSeekWild := 1
    oQryBrw := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"agenda WHERE usuario = "+;
               ClipValue2Sql(oApp:usuario)+ " ORDER BY nombre ")
     DEFINE WINDOW oDlgBrw FROM 0,0 TO oApp:oWnd:nWidth-200, oApp:oWnd:nHeight - 300;
        NOSYSMENU NOCAPTION NOMINIMIZE NOMAXIMIZE  OF oWnd 
     @ 05,01 XBROWSE oBrw DATASOURCE oQryBrw SIZE oApp:oWnd:nWidth-200, oApp:oWnd:nHeight - 300;
       OF oDlgBrw AUTOSORT ;
       COLUMNS "id","nombre","direccion","Telefono","celular","mail","empresa";
       HEADERS "Id","Apellido y Nombre","Direccion","Tel.Fijo","Tel.Celular","Email","Empresa";
       SIZES 35,250,95,80,80,200,200;
       ON DBLCLICK (Formu(.f.),oBrw:Refresh())
     @ 00,00 SAY oBrw:oSeek PROMPT "Buscar:"  OF oDlgBrw COLOR CLR_BLACK,CLR_WHITE  
     @ 00,10 SAY oBrw:oSeek PROMPT ""  SIZE 500,20 OF oDlgBrw COLOR CLR_WHITE,CLR_GRAY
     @ 02,10 COMBOBOX nFilter SIZE 200,60 OF oDlgBrw ;
         ITEMS { "Buscar por...", "Filtrar por..." } ;
         ON CHANGE ( oBrw:Seek( "" ), oBrw:lIncrFilter := nFilter > 1,  oBrw:SetFocus() )

     @ 02,72 COMBOBOX nSeekWild SIZE 200, 60 OF oDlgBrw ;
         ITEMS { "Que comience con..", "Que contenga" } ;
         ON CHANGE ( oBrw:lSeekWild := ( nSeekWild > 1 ), oBrw:Seek( "" ), oBrw:SetFocus() )

     //oBrw:SetDolphin(oQry,.f.,.t.)
     oBrw:bClrStd := { || If( oBrw:KeyNo() % 2 == 0, ;
                         { CLR_BLACK, RGB(193,221,255)}, ;
                         { CLR_BLACK, RGB(221,245,255)} ) }
     oBrw:bClrSel := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }
     oBrw:lColDividerComplete  := .t.                    
     oBrw:nColDividerStyle := LINESTYLE_INSET
     oBrw:nRowDividerStyle := LINESTYLE_INSET
     oBrw:bClrSelFocus     := {|| { nRGB(  0,  0,  0), nRGB(248,195, 34) } }  // para barra de linea selecc cuando el control tiene el foco
     oBrw:nMarqueeStyle    := MARQSTYLE_HIGHLCELL  //solo ilumina la celda actual
     oBrw:nFreeze := 7
     oBrw:CreateFromCode()
     ACTIVATE WINDOW oDlgBrw  ON INIT oDlgBrw:Move(0,0)
     oQryBrw:GoTop()
     // Activo el dialogo y al iniciar muevo a 0,0     
RETURN nil

***************************************
** Formulario de altas y modificaciones
STATIC FUNCTION Formu (lAlta)
LOCAL oGet := ARRAY(7), oBot := ARRAY(2), oForm, lRta := .f., aCor, base, oFont, oError
IF lAlta
   base := oQryBrw:GetBlankRow()
   base:id := oApp:oServer:GetAutoIncrement("ge_"+oApp:cId+"agenda")
   base:usuario := oApp:usuario
   ELSE
   base := oQryBrw:GetRowObj()
   oQryBrw:lAppend := .f.
ENDIF
DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-11.5
DO WHILE .T.

DEFINE DIALOG oForm TITLE IF(lAlta,"Alta","Modificacion") + " de Contacto";
       FROM 05,15 TO 25,80 FONT oFont
   acor := AcepCanc(oForm)
   @ 07, 05 SAY "Id:"                OF oForm PIXEL SIZE 60,20 RIGHT
   @ 22, 05 SAY "Apellido y Nombre:" OF oForm PIXEL SIZE 60,20 RIGHT
   @ 37, 05 SAY "Direccion:"         OF oForm PIXEL SIZE 60,16 RIGHT
   @ 52, 05 SAY "Telefono:"          OF oForm PIXEL SIZE 60,16 RIGHT
   @ 67, 05 SAY "Celular:"           OF oForm PIXEL SIZE 60,16 RIGHT
   @ 82, 05 SAY "Mail:"              OF oForm PIXEL SIZE 60,16 RIGHT
   @ 97, 05 SAY "Empresa:"           OF oForm PIXEL SIZE 60,16 RIGHT
 
   @ 05, 70 GET oGet[1] VAR base:id        OF oForm PICTURE "9999999" PIXEL RIGHT WHEN(.F.)
   @ 20, 70 GET oGet[2] VAR base:nombre    OF oForm PIXEL CUEBANNER "Nombre contacto"
   @ 35, 70 GET oGet[3] VAR base:direccion OF oForm PIXEL CUEBANNER "Domiclio contacto"
   @ 50, 70 GET oGet[4] VAR base:telefono  OF oForm PIXEL CUEBANNER "Telefono fijo contacto"
   @ 65, 70 GET oGet[5] VAR base:celular   OF oForm PIXEL CUEBANNER "Telefono movil contacto"
   @ 80, 70 GET oGet[6] VAR base:mail      OF oForm PIXEL CUEBANNER "Direccion de correo electronico"
   @ 95, 70 GET oGet[7] VAR base:empresa   OF oForm PIXEL CUEBANNER "Empresa para la que trabaja"
 
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER 
IF !lRta
   RELEASE oFont
   RETURN nil
ENDIF
IF lAlta
   oQryBrw:GetBlankRow()
ENDIF
oQryBrw:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQryBrw:Save()
  oQryBrw:Refresh()
  oBrw:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RELEASE oFont
RETURN nil

*************************************
** Cerrar el archivo abierto
STATIC FUNCTION cerrar ()
LOCAL aNueva := {}, i, j
j := ASCAN(oApp:aVentanas,cVentana)
FOR i := 1 TO LEN(oApp:aVentanas)
    IF i <> j
       AADD(aNueva,oApp:aVentanas[i])
    ENDIF
NEXT i
oApp:aVentanas := ACLONE(aNueva)
RETURN .t.

STATIC FUNCTION ChangeDate( oDatePick )

   oCalex:oView:SetDate( oDatePick:GetDate() )
   if oCalex:oView:IsKindOf( "TMONTHVIEW" )
      oCalex:SetMonthView()
   elseif oCalex:oView:IsKindOf( "TWEEKVIEW" )
      oCalex:SetWeekView()
   else
      oCalex:SetDayView()
   endif
   *oDatePick:Refresh()
RETURN NIL


********************************************
** Alertas
FUNCTION Alertas(lPrimerVez)
LOCAL oQry, oDlg, oSay, oBot, aNueva, i,j, cVentana, oFont, oBrw1
DEFAULT lPrimerVez := .f.
cVentana := PROCNAME()
IF ASCAN(oApp:aVentanas,cVentana) > 0
   RETURN nil
ENDIF
oQry := oApp:oServer:Query("SELECT * FROM ge_"+oApp:cId+"citas WHERE alerta = TRUE AND estado = FALSE AND usuario = " +ClipValue2Sql(oApp:usuario)+ ;
         " AND fecha " + IF(lPrimerVez,"<" + ClipValue2Sql(DATE()),;
                        "= " + ClipValue2Sql(DATE()) + " AND hora <=  " + ClipValue2Sql(LEFT(TIME(),5))) )

IF oQry:nRecCount > 0
   AADD(oApp:aVentanas,cVentana)
   DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-13.5
   DEFINE DIALOG oDlg TITLE "Alertas " + IF(lPrimerVez," pendientes de dias anteriores"," para el dia " + DTOC(DATE())) + " para usuario " + oApp:usuanom;
          FROM 09,15 TO 28,135 OF oApp:oWnd
   oDlg:lHelpIcon := .f.
   //Reproduzco un sonido que esta guardado en el archivo ringin.wav
   SndPlaySound("ringin.wav",1)
   @ 01,001 BITMAP FILE "BITMAPS\ALERT.PNG" SIZE 65,140 ADJUST PIXEL OF oDlg NOBORDER
   @ 01,080 XBROWSE oBrw1 DATASOURCE oQry SIZE 325,140 OF oDlg PIXEL ;
       COLUMNS "id","fecha","hora","horafin","motivo","contacto","estado","alerta";
       HEADERS "id","Fecha","Hora","Hasta","Motivo","Cliente","Hecha?","Alerta?";
       SIZES   25,65,45,45,225,55,55,55   
   PintaBrw(oBrw1,8)
   *oBrw1:aCols[6]:bStrData := { || If( oQry:estado, " ","Sin Hacer" ) }
   oBrw1:aCols[ 7 ]:bEditValue := { || oQry:estado = .T. }
   *oBrw1:aCols[7]:bStrData := { || If( oQry:alerta, "Con Alerta"," " ) }
   oBrw1:aCols[ 8 ]:bEditValue := { || oQry:alerta = .T. }
   oBrw1:aCols[7]:SetCheck(,.t.)
   oBrw1:aCols[8]:SetCheck(,.t.)
   oBrw1:nFreeze := 8 
   oBrw1:CreateFromCode()
   @01,408 GROUP TO 140,468  PIXEL OF oDlg 
   @10,423 BUTTON oBot PROMPT "&Salir" OF oDlg SIZE 30,10 ACTION oDlg:End() PIXEL
   @25,423 BUTTON oBot PROMPT "&Silenciar" OF oDlg SIZE 30,10 ;
    ACTION IF(MsgNoYes("Seguro de sacar alerta?","Atencion"),(oQry:alerta:=.f.,oQry:Save(),oBrw1:Refresh()),.t.);
     PIXEL WHEN(oQry:nRecCount>0)
   @40,423 BUTTON oBot PROMPT "&Realizada" OF oDlg SIZE 30,10 ;
    ACTION IF(MsgNoYes("Confirma como realizada esta tarea?","Atencion"),;
      (oQry:estado:=.t.,oQry:Save(),oBrw1:Refresh()),.t.) PIXEL WHEN(oQry:nRecCount>0)
   @55,423 BUTTON oBot PROMPT "&Mover" OF oDlg SIZE 30,10 ;
    ACTION IF(Mover(oQry,oDlg),oBrw1:Refresh(),.t.) PIXEL  WHEN(oQry:nRecCount>0)
   // Activo el dialog
   ACTIVATE DIALOG oDlg CENTER ON INIT DlgOnTop( .t.,oDlg:hWnd )
   RELEASE oFont 
   j := ASCAN(oApp:aVentanas,cVentana)
   aNueva := {}
   FOR i := 1 TO LEN(oApp:aVentanas)
       IF i <> j
          AADD(aNueva,oApp:aVentanas[i])
       ENDIF
   NEXT i
   IF LEN(aNueva) > 0
      oApp:aVentanas := ACLONE(aNueva)
      ELSE
      oApp:aVentanas := {}
   ENDIF   
ENDIF
RETURN nil 

STATIC FUNCTION Mover(oQry,oDlg)
LOCAL lRta := .f., oForm, oBot := ARRAY(2), oGet := ARRAY(8), aCor, base, aVar := ARRAY(3), oError
base := oQry:GetRowObj()
aVar[1] := base:fecha
aVar[2] := base:hora
aVar[3] := base:horafin
DO WHILE .T.
DEFINE DIALOG oForm TITLE "Mover Cita" FROM 05,15 TO 18,60 OF oDlg
   acor := AcepCanc(oForm)
 
   @ 07, 05 SAY "Tarea:"        OF oForm PIXEL SIZE 40,12 RIGHT
   @ 22, 05 SAY "Dia:"          OF oForm PIXEL SIZE 40,12 RIGHT
   @ 37, 05 SAY "Hora:"         OF oForm PIXEL SIZE 40,12 RIGHT
   @ 52, 05 SAY "Mover a Dia:"  OF oForm PIXEL SIZE 40,12 RIGHT
   @ 67, 05 SAY "Hora:"         OF oForm PIXEL SIZE 40,12 RIGHT
 
   @ 05, 50 GET oGet[01] VAR base:motivo OF oForm PIXEL WHEN(.F.)
   @ 20, 50 GET oGet[02] VAR aVar[1]     OF oForm PIXEL WHEN(.F.)
   @ 35, 50 GET oGet[03] VAR aVar[2]     OF oForm PIXEL WHEN(.f.)
   @ 35, 90 GET oGet[04] VAR aVar[3]     OF oForm PIXEL WHEN(.f.)
   @ 50, 50 GET oGet[05] VAR base:fecha  OF oForm PIXEL 
   @ 65, 50 GET oGet[06] VAR base:hora   OF oForm PIXEL PICTURE "99:99"
   @ 65, 90 GET oGet[07] VAR base:horafin OF oForm PIXEL PICTURE "99:99"
 
   @ acor[1],acor[2] BUTTON oBot[1] PROMPT "&Grabar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .t.), oForm:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot[2] PROMPT "&Cancelar" OF oForm SIZE 30,10 ;
           ACTION ((lRta := .f.), oForm:End() ) PIXEL CANCEL
ACTIVATE DIALOG oForm CENTER ON INIT oGet[2]:SetFocus()
IF !lRta
   RETURN lRta
ENDIF
oQry:oRow := base
TRY
  oApp:oServer:BeginTransaction()
  oQry:Save()
  oQry:Refresh()
  oApp:oServer:CommitTransaction()
CATCH oError
    ValidaError(oError)
  LOOP
END TRY
EXIT
ENDDO
RETURN lrta

****** Imprimir Dia
STATIC FUNCTION Imprime(dFecha)
LOCAL oRep, oFont1, oFont2, acor, oDlg1, oGet1, oGet2, oGet3, ;
      oBot1, oBot2, mrta := .f., mdesde := dFecha, mhasta := dFecha, oQryRep, mestado := 1
// Defino los distintos tipos de letra
DEFINE FONT oFont1 NAME "ARIAL" SIZE 0,-10
DEFINE FONT oFont2 NAME "ARIAL" SIZE 0,-10 BOLD
DEFINE DIALOG oDlg1 TITLE "Reporte de Citas" FROM 03,15 TO 13,70 ;
       OF oApp:oWnd
   acor := AcepCanc(oDlg1)
   @ 07, 05 SAY "Estado:"               OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 22, 05 SAY "Desde Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   @ 37, 05 SAY "Hasta Fecha:"          OF oDlg1 PIXEL SIZE 50,12 RIGHT
   
   @ 05, 60 COMBOBOX oGet1 VAR mestado OF oDlg1 SIZE 60,12 PIXEL ITEMS {"Todas","Solo pendientes","Solo Realizadas"}
   @ 20, 60 GET oGet2 VAR mdesde  OF oDlg1 PIXEL
   @ 35, 60 GET oGet3 VAR mhasta  OF oDlg1 PIXEL VALID(mhasta >= mdesde)
   @ acor[1],acor[2] BUTTON oBot1 PROMPT "&Imprimir" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .t.), oDlg1:End() ) PIXEL
   @ acor[3],acor[4] BUTTON oBot2 PROMPT "&Cancelar" OF oDlg1 SIZE 30,10 ;
           ACTION ((mrta := .f.), oDlg1:End() ) PIXEL
ACTIVATE DIALOG oDlg1 CENTER
IF !mrta
   RETURN nil
ENDIF
mestado := IF(mestado=1," TRUE ",IF(mestado=3," estado = TRUE "," estado = FALSE"))
oQryRep := oApp:oServer:Query("SELECT c.*,cli.nombre as nomcli FROM ge_"+oApp:cId+"citas c "+;
           " LEFT JOIN ge_"+oApp:cId+"clientes cli ON c.contacto = cli.codigo "+; 
           " WHERE "+mestado+" AND "+;
           "c.fecha >= "+ClipValue2Sql(mdesde)+" AND c.fecha <= "+ClipValue2Sql(mhasta) + ;
           " ORDER BY c.fecha,c.hora,c.id")
IF oQryRep:nRecCount = 0
   MsgStop("Sin datos para listar en ese rango","Error")
   RELEASE oFont1
   RELEASE oFont1
   RETURN nil 
ENDIF   
REPORT oRep TITLE "Citas de " + ALLTRIM(oApp:usuanom)  + ;
                  " del " + DTOC(mdesde) + " al " + DTOC(mhasta) ;
       FONT  oFont1,oFont2 HEADER OemToAnsi(oApp:nomb_emp)  CENTER ;
       FOOTER "Hoja:" + STR(oRep:npage,3) ,"Fecha:"+DTOC(DATE()) CENTER;
       PREVIEW CAPTION  "Citas"
COLUMN TITLE "Id"      DATA oQryRep:id      SIZE 03 FONT 1
COLUMN TITLE "Fecha"   DATA oQryRep:fecha   SIZE 08 FONT 2
COLUMN TITLE "Desde"   DATA oQryRep:hora    SIZE 05 FONT 1
COLUMN TITLE "Hasta"   DATA oQryRep:horafin SIZE 05 FONT 1 
COLUMN TITLE "Motivo"  DATA oQryRep:motivo  SIZE 20 FONT 1 MEMO
COLUMN TITLE "Cliente Asociado" DATA oQryRep:nomcli SIZE 20 FONT 1 MEMO
COLUMN TITLE "Alm"  DATA IF(oQryRep:alerta,"SI","NO") SIZE 02 FONT 1
COLUMN TITLE "Estado"  DATA IF(oQryRep:estado,"Realizada  ","Pendiente") SIZE 08 FONT 1
COLUMN TITLE "Obser."  DATA REPLICATE("_",20)  SIZE 15 FONT 1

// Digo que el titulo lo escriba con al letra 2
oRep:oTitle:aFont[1] := {|| 2 }
oRep:oTitle:aFont[1] := {|| 2 }
oRep:bInit := {|| oQryRep:GoTop() }
oRep:bSkip := {|| oQryRep:Skip() }

END REPORT

ACTIVATE REPORT oRep WHILE !oQryRep:EOF() ON INIT CursorArrow() ON STARTPAGE oRep:SayBitmap(.1,.1,"LOGO.BMP",.5,.5)

oQryRep:End()
RELEASE oFont1, oFont2 
RETURN nil