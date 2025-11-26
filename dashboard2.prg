#include "FiveWin.ch"

FUNCTION Dashboard()
local oWebView, oBtn
Local oWnd, oExBar,  oPanelExplorer, oPanelWeb, oPanel, oGet := ARRAY(2), dDesde := DATE(), dHasta := DATE()
REQUEST HB_LANG_ESWIN
REQUEST HB_CODEPAGE_ESMWIN
SET DATE FORMAT "DD/MM/YYYY"
SET 3DLOOK ON
HB_LANGSELECT( 'ESWIN' )

//Si mi aplicacion es MDI asi debería definir la ventana
//DEFINE WINDOW oWnd MDICHILD OF oApp:oWnd TITLE "Dashboard " ICON oApp:oIco
DEFINE WINDOW oWnd TITLE "Dashboard " 
   *** Paneles
   oPanelExplorer := TPanel():New( 0, 0, oWnd:nHeight, 280, oWnd )
   
   oPanelWeb := TPanel():New( 0, 281, oWnd:nHeight, oWnd:nWidth, oWnd ) 

   oExBar := TExplorerBar():New( 0, 0, 250, 300, oPanelExplorer )
   
   oPanelExplorer:oClient = oExBar
   
   oPanel := oExBar:AddPanel( "Seleccionar Fecha", "..\bitmaps\calendar.bmp", 255 )
   oPanel:AddLink( "Prueba Silvio" , { || oWebView:SetHtml(MiHtml(0)) }, "..\bitmaps\go.bmp" )
   oPanel:AddLink( "Ventas del Periodo" , { || oWebView:SetHtml(MiHtml(1)) }, "..\bitmaps\go.bmp" )
   oPanel:AddLink( "Compras del Periodo " , { || oWebView:SetHtml(MiHtml(2)) }, "..\bitmaps\go.bmp" )
   oPanel:AddLink( "Cobros del Periodo"  , { || oWebView:SetHtml(MiHtml(3))  }, "..\bitmaps\go.bmp" )
   oPanel:AddLink( "Pagos del Periodo" , { || oWebView:SetHtml(MiHtml(4)) }, "..\bitmaps\go.bmp" )
   
   /*
   @170, 15 SAY "Desde Fecha:"      OF oPanel TRANSPARENT PIXEL SIZE 40,12
   @200, 15 SAY "Hasta Fecha:"      OF oPanel TRANSPARENT PIXEL SIZE 40,12
       
   @170,90 GET oGet[1] VAR dDesde OF oPanel PIXEL 
   @200,90 GET oGet[2] VAR dHasta OF oPanel PIXEL 
   @230,50 BUTTON oBtn PROMPT "Cambiar Fechas" OF oPanel PIXEL SIZE 110,25*/
   
   oWebView := TWebView2():New(oPanelWeb)   

   oWebView:SetUserAgent( "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.53 Mobile Safari/537.36" )   
   oWebView:SetHtml( MiHtml(1) ) 
   oWebView:Run()   

ACTIVATE WINDOW oWnd MAXIMIZED ON RESIZE (oPanelExplorer:Move( , , , oWnd:nHeight ),;
                                oPanelWeb:Move   ( , , oWnd:nWidth - oPanelExplorer:nRight, oWnd:nHeight - 60 ),;
                                oWebView:SetSize(oPanelWeb:nWidth,oPanelWeb:nHeight));
            ON INIT (oWebView:SetSize(oPanelWeb:nWidth,oPanelWeb:nHeight),oWnd:Move(0,0))
//Si mi app es MDI deberia agregar aqui
//ON INIT (oWnd:SetSize(oApp:oWnd:oWndclient:nWidth, oApp:oWnd:oWndclient:nHeight)            

RETURN nil

STATIC FUNCTION MiHtml(n)
LOCAL oDashBoard, aData, cImgHome := "data:image/png;base64," + hb_base64encode( hb_memoRead( '..\bitmaps\pngs\2.png' ) )
oDashBoard = TDashboard():New()
DO CASE
   CASE n = 0
        oDashBoard:cHtml := '<!DOCTYPE html> '+;
                            '<html lang="it"> '+;
                            '<span class="section-title"><img src="'+cImgHome+'" alt="Home"> home</span>'+;
                            '</body>'+;
                            '</html>'
   CASE n = 1        
        oDashBoard:AddPanel('Ventas','$1,000,000','dollar-sign','green','Alert("Hola")')
        oDashBoard:AddPanel('Costo' ,'$900,000','boxes','blue')
        oDashBoard:AddPanel('Productos' ,'12,000','cubes','lime')
        aData := {{'Carniceria', 1000000},;
                  {'Fiambreria', 1170000},;
                  {'Comestibles', 660000},;
                  {'Bazar', 1030000}}
        oDashBoard:AddGraph('Ventas', 'Ventas del periodo',  'PieChart', {'Rubro', 'Totales'}, aData, 'emerald' )
        aData := {{'Mercado Pago', 1000000},;
                  {'Efectivo', 1170000},;
                  {'Tarjeta', 660000},;
                  {'Transferencia', 1030000},;
                  {'Cuenta Corriente', 1030000}}
        oDashBoard:AddGraph('Cobros', 'Por Forma de pago',  'ColumnChart', {'Concepto', 'Importe'}, aData, 'purple' )        
   CASE n = 2
        oDashBoard:AddPanel('Compras','$750,000','dollar-sign','emerald')
        oDashBoard:AddPanel('Gastos' ,'$350,000','desktop','indigo')
        oDashBoard:AddPanel('Stock' ,'7,000','cubes','indigo')
        oDashBoard:AddPanel('Reciclado' ,'$90,000','recycle','purple')
        aData := {{'Materia Prima', 300000},;
                  {'Productos Compraventa', 850000},;
                  {'Gastos', 690000}}
        oDashBoard:AddGraph('Compras', 'Por Tipo de compra',  'BarChart', {'Concepto', 'Importe'}, aData, 'purple' )
   CASE n = 3
        oDashBoard:AddPanel('Tarjetas','$960,000','credit-card','pink')
        oDashBoard:AddPanel('Efectivo','$1,050,000','dollar-sign','blue') 
   CASE n = 4
        oDashBoard:AddPanel('Transferencias','$660,000','university','cyan')
        oDashBoard:AddPanel('Efectivo','$550,000','dollar-sign','orange') 
ENDCASE
RETURN oDashBoard:cHtml



********************************************
** Generar Html 
CLASS TDashboard
   DATA cHtml
   DATA aGraph INIT {}

   METHOD New() CONSTRUCTOR
   METHOD AddPanel(cTexto, cValor, cFaFaIcon, cColor )
   METHOD AddGraph (cNombre, cTitulo,  cTipo, aColumnsData, aData, cColor )   

ENDCLASS

//----------------------------------------------------------------//

METHOD New() CLASS TDashboard
      TEXT INTO ::cHtml
      <!DOCTYPE html>
         <html lang="es">
         <head>
             <meta charset="UTF-8">
             <meta name="viewport" content="width=device-width, initial-scale=1.0">
             <title>Dashboard</title>
             <script src="https://cdn.tailwindcss.com"></script>
             <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
             <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.12.1/css/all.css" crossorigin="anonymous">
             

             <script type="text/javascript">
                 // Cargar Google Charts
                 google.charts.load('current', {'packages':['corechart']});
                 google.charts.setOnLoadCallback(drawCharts);

                 // Función para dibujar los gráficos
                 function drawCharts() {
                     //AgregarChar                     
                 }

                 //FuncionGrafico                 

                 window.onresize = function () {
                     drawCharts();  // Redibujar gráficos cuando la ventana cambia de tamaño
                 };
                 
             </script>

         </head>
         <body class="bg-gray-100">

             <div class="flex flex-col lg:flex-row min-h-screen">     

                 <!-- Main Content -->
                 <div class="flex-1 p-8 overflow-y-auto">
                     <div id="values" class="section">
                         <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                             <!-- AddPanel -->                             
                         </div>
                     </div>
                     <div class="section p-2">
                         <hr>
                     </div>
                     <!-- Gráficos Section -->
                     <div id="charts" class="section">                
                         <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
                             <!-- idgrafico -->
                         </div>
                     </div>
                 </div>
             </div>

         </body>
         </html>
ENDTEXT
   
return Self

METHOD AddPanel(cTexto, cValor, cFaFaIcon, cColor ,cMiFuncion) CLASS TDashboard
Local cPanel
DEFAULT cMiFuncion := ''
cPanel := '<div class="bg-white shadow-md p-6 h-50 rounded-lg text-center border-t-4 border-'+cColor+'-500">'+;
                 '   <h3 class="text-lg font-bold text-'+cColor+'-500"><i class="fas fa-'+cFaFaIcon+' fa-3x"></i></h3>'+;
                 '   <p class="text-xl mt-4 text-'+cColor+'-700">'+cTexto+'</p>'+;
                 '   <p class="text-3xl mt-2 text-'+cColor+'-500 font-bold">'+cValor+'</p>'
                 if !empty(cMiFuncion)
                    cPanel := cPanel + '<button type="button" class="text-white bg-purple-700 hover:bg-purple-800 focus:outline-none focus:ring-4 focus:ring-purple-300 font-medium rounded-full text-sm px-5 py-2.5 text-center mb-2 dark:bg-purple-600 dark:hover:bg-purple-700 dark:focus:ring-purple-900" onclick="SendToFWH('+cMiFuncion+')">Mas</button>'
                 endif
                 cPanel := cPanel + '</div>'+;
                 '<!-- AddPanel -->'                 
::cHtml := strtran(::cHtml,"<!-- AddPanel -->",cPanel)                 
return Self

METHOD AddGraph (cNombre, cTitulo,  cTipo, aColumnsData, aData, cColor )
Local cGraph, cFuncion, cId, i
cGraph := cNombre+'();//AgregarChar'
::cHtml := strtran(::cHtml,"//AgregarChar",cGraph)  
cFuncion := "function "+cNombre+"() { "+;
                     "var data = google.visualization.arrayToDataTable(["+;
                     "    ['"+aColumnsData[1]+"', '"+aColumnsData[2]+"'], "
                      for i := 1 to len(aData)  
                         cFuncion := cFuncion + "['"+aData[i,1]+"', "+STR(aData[i,2])+"],"
                      next i
cFuncion := cFuncion + "   ]);"+;
                     "var options = { "+;
                     "   title: '"+cTitulo+"',"+;
                     "    widht: '100%',"+;
                     "    height: 300, "+;
                     "    is3D: true "+;
                     "};"+;
                     "var chart = new google.visualization."+cTipo+"(document.getElementById('"+cNombre+"'));"+;
                     "chart.draw(data, options);"+;
                 "}"+;
                 "//FuncionGrafico"
::cHtml := strtran(::cHtml,"//FuncionGrafico",cFuncion)
cId := '<div class="bg-white shadow-md p-6 rounded-lg">'+;
            '<h2 class="text-xl font-bold mb-4 text-'+cColor+'-500">'+cTitulo+'</h2>'+;
            '<div id="'+cNombre+'"></div>'+;
        '</div>'+;
        '<!-- idgrafico -->' 
::cHtml := strtran(::cHtml,"<!-- idgrafico -->",cId)
return Self

#pragma BEGINDUMP

void __get_std_stream() {}
void _chdir() {}

#pragma ENDDUMP