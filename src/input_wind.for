      SUBROUTINE INPUT_WIND                                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C     This subroutine reads in Cards E.6, the definitions of 
!C       wind force functions and drag coefficient functions                  
!C                                                                       
!C    This subroutine is called only by Subroutine INPUT_ECARDS.
!C
      USE  MODULE_STANDARD,   ONLY: 
     &       NPG, NGRND, NWINDF,                               ! /CONTRL/
     &       MXTB1, NTI, TAB,                                  ! /TABLES/
     &       FUNC_TITLE,                                       ! /CINPUT_TEMPVS/
     &       SEG,                                              ! structures
     &       ICHAR_STD, INTEGER_STD, IREAL_HIGH, LUAIN, LUAOU, ! parameters
     &       I_1, I_0, I_4, D_0, LULIN, LIN_FLAG,              ! parameters
     &       AIN_CONVERT, LUTERM_OUT, MAX_FUNC                 ! parameters
!C
!C    NAME        SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, J, J1, J2, K, L, 
     &           NSR, NSV, NTMPTS
!C
      CHARACTER  ( LEN =  20, KIND = ICHAR_STD )  IN_TITLE, ATEMP20
      CHARACTER  ( LEN =  22, KIND = ICHAR_STD )  ATEMP22
!C
      J1 = MXTB1 + I_1                                                 
!C
      DO  K=1,NWINDF                                                   
!C                                                                        
!C     Input Card E.6.a - function no. and title                         
!C                                                                       
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  I, IN_TITLE                                   
       ELSE
        READ ( LUAIN, 100 )  I, IN_TITLE                                   
  100   FORMAT ( I4, 4X, A20 )                                            
        IF ( AIN_CONVERT )  THEN
         ATEMP20 = ADJUSTL ( IN_TITLE )
         L = LEN_TRIM ( ATEMP20 )
         ATEMP22(1:L+2) = '"' // ATEMP20(1:L) // '"'       
         WRITE ( LULIN, 105 )  I, ATEMP22(1:L+2), 'Card E.6.a'                                   
  105    FORMAT ( 1X, I4, 1X, A, 2X, A )                                            
        END IF
       END IF
!C
       WRITE ( LUAOU, 110 )  I, IN_TITLE, I, J1, NPG                        
       NPG = NPG + I_1                                                     
  110  FORMAT ( '1 Wind Force Function No.', I4, 4X, A20, 10X,
     &          'NTI(', I2, ') =', I5, 46X, 'Page', I5, /, 120X,
     &          'Cards E.6', / )                                            
       IF ( ( I .LE. I_0 ) .OR. ( I .GT. MAX_FUNC ) )   THEN
        WRITE ( LUAOU, 115 )  I       
  115   FORMAT ( '0 Improper function number, ', I4, 
     &           '.  Program terminated.' )           
        STOP 11        
       END IF
       IF ( NTI(I) .NE. I_0 )   THEN
        WRITE ( LUAOU, 120 )   I                                            
  120   FORMAT ( '0 Function no.', I4, 
     &           ' has already been inputted and will be replaced',        
     &           ' by this function.' )                                    
       END IF
       NTI(I) = J1                                                         
       FUNC_TITLE(I) = IN_TITLE                                              
       J2 = J1 + I_4                                                    
!C                                                                       
!C     Input Card E.6.b                                                   
!C                                                                        
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  ( TAB(J), J=J1,J2-2 ), NSV, NSR               
       ELSE
        READ  ( LUAIN, 125 )  ( TAB(J), J=J1,J2-2 ), NSV, NSR               
  125   FORMAT ( 3F12.0, 2I12 )                                            
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 130 )  ( TAB(J), J=J1,J2-2 ), NSV, NSR,
     &                          'Card E.6.b'               
  130    FORMAT ( 1X, 3( F19.11, 1X ),  2( I12, 1X ), 1X, A )                                            
        END IF
       END IF
       IF ( ( NSV .GT. NGRND ) .OR. ( NSV .LT. I_0 ) )  THEN
        WRITE ( LUTERM_OUT, 131 )  NSV, K
  131   FORMAT ( 1X, ' Invalid segment number for the wind velocity, ',
     &           I4, ' for wind force ', I4, '.' )
        STOP ' STOP 384 in Subroutine INPUT_WIND '
       END IF
       IF ( ( NSR .GT. NGRND ) .OR. ( NSR .LT. I_0 ) )  THEN
        WRITE ( LUTERM_OUT, 132 )  NSR, K
  132   FORMAT ( 1X, ' Invalid segment number for the wind velocity, ',
     &           I4, ' for wind force ', I4, '.' )
        STOP ' STOP 385 in Subroutine INPUT_WIND '
       END IF
!C
       IF ( NSV .EQ. I_0 )  NSV = NGRND                               
       IF ( NSR .EQ. I_0 )  NSR = NGRND                                
       TAB(J2-1) = REAL ( NSV, IREAL_HIGH )                               
       TAB(J2) = REAL ( NSR, IREAL_HIGH )                                   
       IF ( TAB(J1) .NE. D_0 )   THEN                                   
        WRITE ( LUAOU, 135 )  ( TAB(J), J=J1,J2-2 ), NSV, SEG(NSV)%NAME, 
     &                         NSR, SEG(NSR)%NAME                        
  135   FORMAT ( ' Spec. Heat Ratio    Sonic Vel.    Abs. Press.', 7X,    
     &           'Segment     Ref. Segment', /, 3F15.4, 
     &           2( I10, 1X, A4 ), // )   
        J1 = J2 + I_1                                                    
        CYCLE                                                             
       END IF
       WRITE ( LUAOU, 140 ) ( TAB(J), J=J1,J2 )                             
  140  FORMAT ( 10X, 'D0', 13X, 'D1', 13X, 'D2', 13X, 'D3', 8X,
     &          'Ref. Segment', /, 5F15.4, // )                           
       J1 = J2 + I_1                                                     
!C                                                                         
!C     Input Card E.6.c - NTMPTS                                           
!C                                                                       
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  NTMPTS                                        
       ELSE
        READ  ( LUAIN, 145 )  NTMPTS                                        
  145   FORMAT( I6 )                                                     
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 150 )  NTMPTS, 'Card E.6.c'                                        
  150    FORMAT( 1X, I6, 2X, A )                                                     
        END IF
       END IF
!C
       WRITE ( LUAOU, 155 ) NTMPTS                                        
  155  FORMAT ( '0 Wind Force Tables for ', I6, ' Time Points.', //,      
     &          11X, 'T', 14X, 'FX(T)', 15X, 'FY(T)', 15X, 'FZ(T)', / )   
       TAB(J1) = NTMPTS                                                  
       J1 = J1 + I_1                                                     
       J2 = J1 + I_4 * NTMPTS - I_1                                       
!C                                                                      
!C     Input Cards E.6.d - NTMPTS cards of T, FX(T), FY(T), FZ(T)            
!C                                                                         
       IF ( LIN_FLAG )  THEN
        READ  ( LULIN, * )  ( TAB(J), J=J1,J2 )                           
       ELSE
        READ  ( LUAIN, 160 )  ( TAB(J), J=J1,J2 )                           
  160   FORMAT ( 4F12.0 )                                                
        IF ( AIN_CONVERT )  THEN
         WRITE  ( LULIN, 165 )  ( TAB(J), J=J1,J2 )                           
  165    FORMAT ( 1X, 4( F19.11, 1X ) )                                                
        END IF
       END IF
!C
       WRITE ( LUAOU, 170 )  ( TAB(J), J=J1,J2 )                           
  170  FORMAT ( 3X, F12.6, 3G20.6 )                                      
       J1 = J2 + I_1                                                   
      END DO                                                         
!C
      MXTB1 = J1 - I_1                                                 
!C
      RETURN
      END