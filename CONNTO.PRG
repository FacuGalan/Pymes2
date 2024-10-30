
FUNCTION ConnectTo( n, cDB , cHost, lLocal)
   LOCAL c 
   LOCAL oIni      
   LOCAL oServer   
   LOCAL cServer, cUser, cPassword, nPort, cDBName,nFlags    
   LOCAL oErr   

/*   INI oIni FILE ".\connect.ini"
      oServer := nil
      GET cServer    SECTION "mysql" ENTRY "host"   OF oIni 
      GET cUser      SECTION "mysql" ENTRY "user"   OF oIni 
      GET cPassword  SECTION "mysql" ENTRY "psw"    OF oIni 
      GET nPort      SECTION "mysql" ENTRY "port"   OF oIni 
      GET cDBName    SECTION "mysql" ENTRY "dbname" OF oIni 
      GET nFlags     SECTION "mysql" ENTRY "flags"  OF oIni 
   ENDINI
*/

IF n = 1
    cServer := cHost
    nPort := 3317
    nFlags := 0
    cDBName := cDB
    IF lLocal
       cUser := 'root'
       cPassword := ""
       IF FILE(".\connect.ini")
           INI oIni FILE ".\connect.ini"
              oServer := nil
              GET cServer    SECTION "mysql" ENTRY "host"   OF oIni 
              GET cUser      SECTION "mysql" ENTRY "user"   OF oIni 
              GET cPassword  SECTION "mysql" ENTRY "psw"    OF oIni 
              GET nPort      SECTION "mysql" ENTRY "port"   OF oIni 
              GET cDBName    SECTION "mysql" ENTRY "dbname" OF oIni 
              GET nFlags     SECTION "mysql" ENTRY "flags"  OF oIni 
           ENDINI
       ENDIF
    ELSE
       cUser := 'cesar'
       cPassword := 'App_BCN_Cesar12#$'
    ENDIF    
    TRY
      CONNECT oServer HOST cServer ;
                      USER cUser ;
                      PASSWORD cPassword ;
                      PORT nPort ;
                      FLAGS nFlags;
                      DATABASE cDBName
                                
    CATCH oErr 
      RETURN NIL
    END
ELSE
    cServer := 'app.bcnsoft.com.ar'
    cUser := 'cesar'
    cPassword := 'App_BCN_Cesar12#$'
    nPort := 3317
    nFlags := 0
    cDBName := 'bcn_config'
    TRY
      CONNECT oServer HOST cServer ;
                      USER cUser ;
                      PASSWORD cPassword ;
                      PORT nPort ;
                      FLAGS nFlags;
                      DATABASE cDBName
                                
    CATCH oErr 
      RETURN NIL
    END
ENDIF

   
RETURN oServer