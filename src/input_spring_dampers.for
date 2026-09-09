      SUBROUTINE  INPUT_SPRING_DAMPERS
!C
!C                                                   Rev. V.3 12/15/2002 
!C    This subroutine reads in the parameters for
!C     the spring dampers supplied on Cards D.8.
!C
!C    It is called only by: INPUT_DCARDS.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       UNITL,                                 ! /CNSNTS/
     &       NSD,                                   ! /CONTRL/
     &       APSDM, APSDN, ASD, MSDM, MSDN,         ! /DAMPER/
     &       INTEGER_STD, LUAIN, LUAOU, I_0, I_1,   ! parameters
     &       AIN_CONVERT, LIN_FLAG, LULIN           ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:
     &       NODSD,               ! /FXFRC/
     &       IBODN, NFBOD         ! /FXVAR/
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, IIFB, J
!C
!C    Card D.8   spring dampers function input.                          
!C
      DO  J=1,NSD                                                        
!C
!C     Check for comments.
!C
       CALL  CHECK_COMMENT
!C
       IF ( LIN_FLAG )  THEN
        READ ( LULIN, * )  MSDM(J), MSDN(J), ( APSDM(I,J), I=1,3 ),      
     &                     ( APSDN(I,J), I=1,3 ), ( ASD(I,J), I=1,5 )      
       ELSE
        READ ( LUAIN, 100 )  MSDM(J), MSDN(J), ( APSDM(I,J), I=1,3 ),      
     &                    ( APSDN(I,J), I=1,3 ), ( ASD(I,J), I=1,5 )      
  100   FORMAT ( 2I3, 11F6.0 )                                            
        IF ( AIN_CONVERT )  THEN
         WRITE ( LULIN, 105 )  MSDM(J), MSDN(J), ( APSDM(I,J), I=1,3 ),      
     &                        ( APSDN(I,J), I=1,3 ), 
     &                        ( ASD(I,J), I=1,5 ), 'Card D.8.a'      
  105    FORMAT ( 1X, 2( I4, 1X ), 11( F15.7, 1X), 1X, A )                                            
        END IF
       END IF
       IIFB = I_0                                                  
       DO  I=1,NFBOD                                                   
        IF ( ( IBODN(I) .EQ. MSDM(J) ) .OR. 
     &       ( IBODN(I) .EQ. MSDN(J) ) )  IIFB = I_1                
       END DO
       IF ( IIFB .EQ. I_1 )   THEN
        IF ( LIN_FLAG )  THEN
         READ ( LULIN, * )  NODSD(1,J), NODSD(2,J)                    
        ELSE
         READ ( LUAIN, 110 )  NODSD(1,J), NODSD(2,J)                    
  110    FORMAT ( 2I5 )                                                 
         IF ( AIN_CONVERT )  THEN
          WRITE ( LULIN, 115 )  NODSD(1,J), NODSD(2,J), 'Card D.8.b'                    
  115     FORMAT ( 1X, 2( I6, 1X ), A )                                                 
         END IF
        END IF
       END IF
      END DO                                                           
!C
      WRITE ( LUAOU, 120 ) UNITL                                          
  120 FORMAT ( '0', 5X, 'Spring  Dampers  Function  Input', 82X,
     &         'Cards D.8', //, 18X,
     &         'Coordinates of Attachment Points (', A4, ')', /,         
     &         5X, 'Segment',9X,'Segment M', 16X, 'Segment N', 15X,      
     &         'Spring Force Function', 12X, 'Damping Force Function', 
     &         /, ' No.  M   N', 2( 6X, 'X', 7X, 'Y', 7X, 'Z', 2X ),
     &         7X, 'D0', 9X, 'A1', 11X, 'A2', 13X, 'B1', 10X, 'B2', 
     &         // )                                                      
      DO  J=1,NSD                                                        
       WRITE  ( LUAOU, 125 )  J, MSDM(J), MSDN(J), 
     &                       ( APSDM(I,J), I=1,3 ),                      
     &                       ( APSDN(I,J), I=1,3 ), 
     &                       ( ASD(I,J),   I=1,5 )                       
  125  FORMAT ( I3, 2I4, 2( 1X, 3F8.2 ), F11.2, 2F12.3, F15.3, F12.3 )   
      END DO
!C
      RETURN
      END