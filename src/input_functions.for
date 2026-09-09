      SUBROUTINE INPUT_FUNCTIONS                                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input cards E.1 - E.4 for the force-deflection, inertial spike,     
!C    R factor, G factor and friction coefficient function definitions    
!C                                                                        
!C    This subroutine is called only by .MAIN
!C
      USE  MODULE_STANDARD, ONLY: 
     &       NPG,                                          ! /CONTRL/
     &       NTI, TAB, MXTB1,                              ! /TABLES/
     &       FUNC_TITLE,                                   ! /CINPUT_TEMPVS/
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH, MAX_FUNC, ! parameters
     &       LUAIN, LUAOU, LULIN, LIN_FLAG, AIN_CONVERT,   ! parameters
     &       I_0, I_1, I_2, I_4, I_5, I_50, D_0            ! parameters
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, IS, J, J1, J2, L, NPI
!C
      REAL  ( KIND = IREAL_HIGH )   D1, D2
!C                                                                        
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  IN_TITLE, ATEMP20
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      IS = I_0                                                         
      NTI = I_0                                                           
      J1 = I_1                                                         
!C                                                                        
!C    Input Card E.1 - function no. and title, if no. > MAX_FUNC skip out.      
!C                                                                        
      DO
!C
!C     Check for comments.
!C
       CALL CHECK_COMMENT
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) I, IN_TITLE                                    
       ELSE
        READ ( LUAIN, 100 ) I, IN_TITLE                                    
  100   FORMAT ( I4, 4X, A20 )                                             
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( IN_TITLE )
         L = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:L+2) = '"' // ATEMP20(1:L) // '"'       
         WRITE ( LULIN, 105 ) I, ATEMP22(1:L+2), 'Card E.1'                                     
  105    FORMAT ( 1X, I4, 1X, A, 2X, A )                                             
        END IF
       END IF
!C
!C     Exit the subroutine if the last function is encountered.
!C
       IF ( I .GT. MAX_FUNC )  THEN                                 
        MXTB1 = J1 - I_1                                              
        RETURN                                                            
       END IF
!C
       FUNC_TITLE(I) = IN_TITLE                                               
!C                                                                        
!C     Has function no. been already used?                                
!C                                                                        
       IF  ( NTI(I) .NE. I_0 )   WRITE ( LUAOU, 110 )  I              
  110  FORMAT ( '0 FUNCTION NO.', I4,
     &          ' Has already been inputted and will be replaced by ',  
     &          'next function' )                                         
       NTI(I) = J1                                                        
       J2 = J1 + I_4                                                   
!C                                                                        
!C     Input Card E.2                                                     
!C                                                                       
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * ) ( TAB(J), J = J1,J2 )                          
       ELSE
        READ ( LUAIN, 115 ) ( TAB(J), J = J1,J2 )                          
  115   FORMAT ( 6F12.0 )                                                  
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 118 ) ( TAB(J), J = J1,J2 ), 'Card E.2'                          
  118    FORMAT ( 1X, 5( E17.10, 1X ), 1X, A )                                                  
        END IF
       END IF
       IS = I_1 - IS                                                   
       IF ( IS .EQ. I_0 ) THEN
        WRITE ( LUAOU, 120 )                              
  120   FORMAT ( ///// )                                                  
       ELSE
        WRITE ( LUAOU, 125 )  NPG                                           
  125   FORMAT ( '1', 122X, 'Page', I5 )                                    
        NPG = NPG + I_1                                                  
       END IF
       WRITE ( LUAOU, 130 )  I,  FUNC_TITLE(I), I, NTI(I), 
     &                      ( TAB(J),J=J1,J2 )                              
  130  FORMAT ( ' Function No.', I4, 4X, A20, 20X, 'NTI(', I2, 
     &          ') =', I5, 45X, 'Cards E', //, 10X, 'D0', 13X,
     &          'D1', 13X, 'D2', 13X, 'D3', 13X, 'D4', /, 5F15.4, // )    
       D1 = TAB(J1+1)                                                     
       D2 = TAB(J1+2)                                                     
       J1 = J2 + I_1                                                  
       IF ( D1 .EQ. D_0 )   THEN                                        
!C                                                                       
!C     Function is constant  D2 for all D.                                
!C                                                                        
        WRITE ( LUAOU, 135 )  D2                                          
  135   FORMAT ( 7X, 'Function is Constant', F12.6 )                      
        CYCLE                                                             
       ELSE IF ( D1 .GT. D_0 )  THEN
!C                                                                        
!C       5th order polynomial ...  1st function                           
!C       input Card E.3                                                   
!C                                                                        
        J2 = J1 + I_5                                                
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( TAB(J), J = J1,J2 )                        
        ELSE
         READ ( LUAIN, 140 )  ( TAB(J), J = J1,J2 )                        
  140    FORMAT ( 6F12.0 )                                                  
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 145 )  ( TAB(J), J = J1,J2 ), 'Card E.3'                        
  145     FORMAT ( 1X, 6( E17.10, 1X ), 1X, A )                                                  
         END IF
        END IF
!C
        WRITE ( LUAOU, 150 )  ( TAB(J), J = J1,J2 )                       
  150   FORMAT ( 7X, 'First Part of Function - 5th Degree Polynomial',    
     &           //, 8X, 'A0', 13X, 'A1', 13X, 'A2', 13X, 'A3', 13X, 
     &           'A4', 13X, 'A5', 13X, /, 6F15.6, // )                   
        J1 = J2 + I_1                                              
       ELSE 
!C                                                                        
!C         Table load ...  1st function                                   
!C         Input Cards E.4.a - E.4.b                                        
!C                                                                        
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  NPI                                          
        ELSE
         READ ( LUAIN, 155 )  NPI                                          
  155    FORMAT ( 12I6 )                                                   
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 160 )  NPI, 'Card E.4.a'                                          
  160     FORMAT ( 1X, I6, 2X, A )                                                   
         END IF
        END IF
!C
        TAB(J1) = NPI                                                     
        J1 = J1 + I_1                                                   
        J2 = J1 + I_2 * NPI - I_1                                   
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( TAB(J), J = J1,J2 )                        
        ELSE
         READ ( LUAIN, 165 )  ( TAB(J), J = J1,J2 )                        
  165    FORMAT ( 6F12.0 )                                                 
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 170 )  ( TAB(J), J = J1,J2 )                        
  170     FORMAT ( 1X, 6( E17.10, 1X ) )                                                 
         END IF
        END IF
!C
        WRITE ( LUAOU, 175 )  NPI, ( TAB(J), J = J1, J2 )               
  175   FORMAT ( 7X, 'First Part of Function - ', I4, ' Tabular Points',  
     &           //, 8X, 'D', 16X, 'F(D)', /, ( F15.6, F15.4 ) )          
        J1 = J2 + I_1                                                    
       END IF
!C                                                                        
!C        Check for second function                                       
!C                                                                        
       IF ( D2 .GT. D_0 )   THEN                                          
!C                                                                        
!C       Second function ...  5th order polynomial                        
!C       Input Card E.3                                                   
!C                                                                        
        J2 = J1 + I_5                                                  
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( TAB(J), J = J1,J2 )                        
        ELSE
         READ ( LUAIN, 180 )  ( TAB(J), J = J1,J2 )                        
  180    FORMAT ( 6F12.0 )                                                  
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 185 )  ( TAB(J), J = J1,J2 ), 'Card E.3'                        
  185     FORMAT ( 1X, 6( E17.10, 1X ), 1X, A )                                                  
         END IF
        END IF
!C
        WRITE ( LUAOU, 190 )  ( TAB(J), J = J1,J2 )                      
  190   FORMAT ( 7X, 'Second Part of Function - 5th Degree Polynomial',   
     &           //, 8X, 'B0', 13X, 'B1', 13X, 'B2', 13X, 'B3', 13X,
     &           'B4', 13X, 'B5', 13X, /, 6F15.6, // )                    
        J1 = J2 + I_1                                                 
        CYCLE                                                             
!C
       ELSE IF ( D2 .EQ. D_0 )  THEN
        CYCLE
       ELSE
!C                                                                        
!C       Second function ...  table load                                  
!C       Input Cards E.4.a - E.4.b                                          
!C                                                                        
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  NPI                                          
        ELSE
         READ ( LUAIN, 195 )  NPI                                          
  195    FORMAT ( 12I6 )                                                  
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 200 )  NPI, 'Card E.4.a'                                          
  200     FORMAT ( 1X, I6, 2X, A )                                                  
         END IF
        END IF
!C
        TAB(J1) = NPI                                                     
        J1 = J1 + I_1                                                 
        J2 = J1 + I_2 * NPI - I_1                                     
!C
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  ( TAB(J), J = J1,J2 )                        
        ELSE
         READ ( LUAIN, 205 )  ( TAB(J), J = J1,J2 )                        
  205    FORMAT ( 6F12.0 )                                                 
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 210 )  ( TAB(J), J = J1,J2 )                        
  210     FORMAT ( 1X, 6( E17.10, 1X ) )                                                 
         END IF
        END IF
!C
        WRITE ( LUAOU, 215 )  NPI,  ( TAB(J),  J = J1,J2 )                
  215   FORMAT ( 7X, 'Second Part of Function - ', I4, 
     &           ' Tabular Points', //, 8X, 'D', 16X, 'F(D)', /,
     &           ( F15.6, F15.4 ) )                                       
        J1 = J2 + I_1                                                  
        CYCLE                                                            
       END IF
!C
      END DO
!C
      END                                                                
