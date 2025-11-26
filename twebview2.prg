#include "FiveWin.ch"

#define GWL_STYLE        -16

static aWebViews := {}

//----------------------------------------------------------------------------//

CLASS TWebView2

   DATA   hWebView
   DATA   oWnd
   DATA   bOnBind
   DATA   bOnNavigationCompleted
   DATA   bOnEval

   METHOD New( oWndParent ) CONSTRUCTOR

   METHOD Navigate( cURL ) INLINE WebView2_Navigate( ::hWebView, cURL )

   METHOD Center() INLINE ::oWnd:Center()

   METHOD SetHtml( cHtml ) INLINE WebView2_SetHtml( ::hWebView, cHTML )

   METHOD SetTitle( cText ) INLINE SetWindowText( ::oWnd:hWnd, cText )

   METHOD SetSize( nWidth, nHeight ) INLINE WebView2_SetSize( ::hWebView, nWidth, nHeight )

   METHOD SetUserAgent( cUserAgent ) INLINE WebView2_SetUserAgent( ::hWebView, cUserAgent )

   METHOD OpenDevToolsWindow( lOnOff ) INLINE WebView2_OpenDevToolsWindow( ::hWebView, lOnOff )

   METHOD Run() INLINE ::oWnd:Activate()

   METHOD SetParent( oWnd ) INLINE ( ::oWnd := oWnd, SetWindowLong( ::GetWindow(), GWL_STYLE, nOr( WS_CHILD, WS_VISIBLE ) ),;
          SetWindowPos( ::GetWindow(), 0, 0, 0, oWnd:nWidth, oWnd:nHeight, 4 ),;
          SetParent( ::GetWindow(), oWnd:hWnd ) )

   METHOD GetWindow() INLINE ::oWnd:hWnd

   METHOD Eval( cJavaScript ) INLINE WebView2_Eval( ::hWebView, cJavaScript )

   METHOD InjectJavascript( cScript )

   METHOD Terminate() VIRTUAL

   METHOD Destroy() VIRTUAL

   METHOD End() INLINE ( WebView2_End( ::hWebView ), ::hWebView := nil )

   METHOD ShowDownloads( lOnOff ) INLINE WebView2_ShowDownloads( ::hWebView, lOnOff )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oWndParent ) CLASS TWebView2

   if ! Empty( oWndParent ) .and. ! Empty( oWndParent:hWnd )
      ::hWebView = WebView2_New( oWndParent:hWnd )
      ::oWnd = oWndParent
   else
      DEFINE WINDOW ::oWnd TITLE "WebView" COLOR "N/B"
      ::hWebView = WebView2_New( ::oWnd:hWnd )
      ::oWnd:bResized = { | nType, nWidth, nHeight | nType, ::SetSize( nWidth, nHeight ) }
   endif

   ::bOnBind = { | cJson | MsgInfo( cJson ) }

   AAdd( aWebViews, Self )

return Self

//----------------------------------------------------------------------------//

METHOD InjectJavascript( cScript ) CLASS TWebView2

   local cInjection

   cInjection := "var script = document.createElement('script');" + CRLF
   cInjection += "script.textContent = `" + CRLF

   cInjection += cScript + CRLF

   cInjection += "`;" + CRLF
   cInjection += "document.head.appendChild(script);"

   ::Eval( cInjection )

return nil

//----------------------------------------------------------------------------//

static function GetWebView( hWebView )

return aWebViews[ AScan( aWebViews, { | o | o:hWebView == hWebView } ) ]

//----------------------------------------------------------------------------//

function WebView2_OnBind( cParams, hWebView ) // SendToFWH() has been called from javascript

   local oWebView := GetWebView( hWebView )
   local hJson

   hb_jsonDecode( cParams, @hJson )

   if ! Empty( oWebView:bOnBind )
      Eval( oWebView:bOnBind, hJson[ "params" ], oWebView )
   endif

return nil

//----------------------------------------------------------------------------//

function WebView2_OnNavigationCompleted( cUrl, hWebView )

   local nAt := AScan( aWebViews, { | o | o:hWebView == hWebView } ), nResult

   if nAt != 0 .and. ! Empty( aWebViews[ nAt ]:bOnNavigationCompleted )
      nResult = Eval( aWebViews[ nAt ]:bOnNavigationCompleted, cUrl, hWebView )
   endif

return nResult

//----------------------------------------------------------------------------//

function WebView2_OnEval( cJson, hWebView )

   local nAt := AScan( aWebViews, { | o | o:hWebView == hWebView } ), nResult

   if nAt != 0 .and. ! Empty( aWebViews[ nAt ]:bOnEval )
      nResult = Eval( aWebViews[ nAt ]:bOnEval, cJson, hWebView )
   endif

return nResult

//----------------------------------------------------------------------------//

function FW_WebView( cHtml, oWnd )

   local oWebView

   if oWnd != nil .and. oWnd:IsKindOf( "TWEBVIEW2" )
      if Empty( oWnd:oWnd:hWnd )
         oWnd:End()
         oWnd  := nil
      elseif Empty( oWnd:hWebView )
         oWnd  := oWnd:oWnd
      endif
   endif

   if oWnd == nil
      if WndMain() != nil .and. WndMain():ClassName() == "TMDIFRAME"
         DEFINE WINDOW oWnd MDICHILD OF WndMain()
         oWebView := TWebView2():New( oWnd )
         WebViewSetSource( cHtml, oWebView, .t. )
         ACTIVATE WINDOW oWnd
         return oWebView
      else
         DEFINE DIALOG oWnd TRUEPIXEL
         oWnd:lModal := Empty( WndMain() )
         oWnd:bInit := <||
         oWebView := TWebView2():New( oWnd )
         WebViewSetSource( cHtml, oWebView, .t. )
         return nil
         >
         ACTIVATE DIALOG oWnd CENTERED
         return oWebView
      endif
   elseif oWnd:IsKindOf( "TWEBVIEW2" )
      oWebView := oWnd
      WebViewSetSource( cHtml, oWebView )
      return oWebView
   endif

   oWebView := TWebView2():New( oWnd )
   WebViewSetSource( cHtml, oWebView, .t. )

return oWebView

//----------------------------------------------------------------------------//

static function WebViewSetSource( cSrc, oWeb, lNew )

   local o, w, h, cTitle := "WEB VIEW"
   local lText

   if Empty( cSrc )
      return nil
   endif

   if !( lText := ( "<html>" $ Left( cSrc, 200 ) ) )
      if Len( cSrc ) < 300 .and. File( cSrc )
         cSrc    := TrueName( cSrc )
         cTitle   := cSrc
         if IsImageExt( cSrc )
            cSrc := ( o := TImageBase64():New( cSrc ) ):MakeText( .t., .t., .t., cSrc )
            w     := o:nImgWidth  + 60
            h     := o:nImgHeight + 90
            lText := .t.
         endif
      else
         cTitle   := cSrc
      endif
   endif

   WITH OBJECT oWeb
      if lText
         :SetHTML( cSrc )
      else
         :Navigate( cSrc )
      endif
      DEFAULT lNew := .f.
/* .. keep this for using google
      if lNew
         oWeb:SetUserAgent( "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.53 Mobile Safari/537.36" )
         sleep( 300 )
      endif
*/
      if oWeb:oWnd:ClassName() == "TDIALOG"
         :SetTitle( cTitle )
         DEFAULT w := ScreenWidth() * 0.8
         DEFAULT h := ScreenHeight() * 0.8
         :SetSize( w, h )
         :oWnd:SetSize( w, h )
         :center()
         if !lNew
            :oWnd:GoTop()
         endif
      endif
   END

   if lNew
      SetWebWndValid( oWeb )
   endif

return nil

static function SetWebWndValid( oWeb )

   local oWnd     := oWeb:oWnd
   local bValid   := { || oWeb:End(), .t. }

   if oWnd:IsKindOf( "TCONTROL" )
      oWnd  := oWnd:oWnd
   endif

   if oWnd:IsKindOf( "TMDICHILD" )
      oWnd:bPostEnd  := bValid
   else
      oWnd:bValid    := bValid
   endif

return nil
