

#pragma BEGINDUMP

#include <hbapi.h>
#include <windows.h>

void WindowBoxBlack( HDC hDC, RECT * pRect );

LRESULT static CALLBACK LabelProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
   if( uMsg == WM_ERASEBKGND )
   {
      return 1;
   }
   else if( uMsg == WM_UPDATEUISTATE )
   {
      LONG lResult = CallWindowProc( ( WNDPROC ) GetProp( hWnd, "__FWTRANS" ), hWnd, uMsg, wParam, lParam );
      InvalidateRect( hWnd, NULL, TRUE );
      return lResult;
   }
   else if( uMsg == WM_PAINT )
   {
      PAINTSTRUCT ps;
      char text[ 256 ];
      RECT rct;
      HDC hDC = BeginPaint( hWnd, &ps );
      HGDIOBJ hOldFont;

      GetWindowText( hWnd, text, 255 );
      GetClientRect( hWnd, &rct );
      SetBkMode( hDC, TRANSPARENT );
      SelectObject( hDC, GetStockObject( DEFAULT_GUI_FONT ) );

      SendMessage( GetParent( hWnd ), WM_CTLCOLORSTATIC, ( WPARAM ) hDC, ( LPARAM ) hWnd );
      hOldFont = SelectObject( hDC, ( HGDIOBJ ) SendMessage( hWnd, WM_GETFONT, 0, 0 ) );

      if( ( GetWindowLong( hWnd, GWL_STYLE ) & SS_BLACKFRAME ) ==   SS_BLACKFRAME )
      {
         RECT rct;
         GetClientRect( hWnd, &rct );
         WindowBoxBlack( hDC, &rct );
      }
      else if( GetWindowLong( hWnd, GWL_STYLE ) & SS_CENTER )
      {
         DrawText( hDC, text, lstrlen( text ), &rct,  DT_CENTER | DT_WORDBREAK );
      }
      else if( GetWindowLong( hWnd, GWL_STYLE ) & SS_RIGHT )
      {
         DrawText( hDC, text, lstrlen( text ), &rct,  DT_RIGHT | DT_WORDBREAK );
      }
      else if( GetWindowLong( hWnd, GWL_STYLE ) & SS_LEFTNOWORDWRAP )
      {
         DrawText( hDC, text, lstrlen( text ), &rct,  DT_LEFT );
      }
      else
      {
         DrawText( hDC, text, lstrlen( text ), &rct,  DT_LEFT );
      }
      SelectObject( hDC, hOldFont );
      EndPaint( hWnd, &ps );
      return 0;
   }
   else
   {
      return CallWindowProc( ( WNDPROC ) GetProp( hWnd, "__FWTRANS" ), hWnd, uMsg, wParam, lParam );
   }
}

HB_FUNC( FIXSAYS )
{
   HWND hDlg = ( HWND ) hb_parnl( 1 );
   HWND hCtrl = GetWindow( hDlg, GW_CHILD );
   char className[ 64 ];
   WNDPROC pLabelProc;

   while( hCtrl != NULL )
   {
      GetClassName( hCtrl, className, sizeof( className ) );

      if( ! lstrcmp( "Static", className ) && ! ( ( GetWindowLong( hCtrl, GWL_STYLE ) & SS_ICON ) == SS_ICON ) && ! ( ( GetWindowLong( hCtrl, GWL_STYLE ) & WS_BORDER ) == WS_BORDER ) )
      {
         if( GetWindowLong( hCtrl, GWL_WNDPROC ) != ( LONG ) LabelProc )
         {
            pLabelProc = ( WNDPROC ) SetWindowLong( hCtrl, GWL_WNDPROC, ( LONG ) LabelProc );
            SetProp( hCtrl, "__FWTRANS", ( HANDLE ) pLabelProc );
         }
      }

      hCtrl = GetWindow( hCtrl, GW_HWNDNEXT );

   }
}

#pragma ENDDUMP