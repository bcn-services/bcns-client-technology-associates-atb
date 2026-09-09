      SUBROUTINE AIRBG3 ( IRESET )                                        
!C                                                   Rev. V.3 12/15/2002 
!C                                                                       
!C    This subroutine is called by Subroutine UPDATE at start (IRESET=1)  
!C    and end (IRESET=2) of each integration step to determine if each    
!C    airbag has been fully inflated.                                     
!C                                                                        
!C
      USE  MODULE_STANDARD,  
     &       ONLY:  PREVT, IFULL, PD, PCYV, PCYMIN, CYMIN,     ! /ABDATA/ 
     &              PVBAG, VBAG, VOLBP, SCALEX, VBAGG, CYMOUT, ! /ABDATA/
     &              SWITCH, BAGPV, DEPLOY, DBR, AB, PYMOUT,    ! /ABDATA/
     &              DPVCTR,                                    ! /ABDATA/
     &              D_THIRD,                                   ! /CNSNTS/
     &              BD,                                        ! /CNTSRF/
     &              TIME, NBAG, NVEH,                          ! /CONTRL/
     &              CYV, CYPA, CYK, CYT, CYP,                  ! /CYDATA/
     &              NBGSF, BAGSF, NPANEL,                      ! /FORCES/
     &              MNBAG,                                     ! /JBARTZ/
     &              SEG,                                       ! structures
     &              INTEGER_STD, IREAL_HIGH, LUAOU,            ! parameters
     &              I_0, I_1, I_2, I_3, I_5, D_0, D_1          ! parameters
!C
!C    DIR_COS, LIN_DISP    ! SEG%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  J, K, IRESET, JB, JRESET, JFULL
!C 
      REAL  ( KIND = IREAL_HIGH )  TMP, TMP3, PSW1, PSW2
      DIMENSION         TMP(9), TMP3(3)
!C
      INTENT ( INOUT )  IRESET
!C
      CALL ELTIME ( I_1, 29_INTEGER_STD )                                               
!C
      JRESET = IRESET                                                     
      IF  ( JRESET .EQ. I_1 )  PREVT = TIME                             
      NBGSF = I_0                                                     
      DO  50  J=1,NBAG                                                    
       IF  ( MNBAG(J) .EQ. I_0 )  CYCLE                                
       JB = NVEH + J                                                      
       JFULL = IFULL(J) + I_2                                           
       IF  ( ( JFULL .LT. I_1 ) .OR. ( JFULL .GT. I_3 ) )  THEN  
        WRITE ( LUAOU, 100 )   TIME                                         
  100   FORMAT ( '0 Error in Subroutine AIRBG3 at time =', F10.6 )         
        STOP 32                                                            
       END IF
!C
       IF  ( ( JRESET - I_1 ) .LE. I_0  ) THEN
        IF  ( ( JFULL - I_2 ) .LT. I_0 )  THEN
!C                                                                       
!C       Start of integration step with IFULL = -1, reset integrator.      
!C                                                                         
         IFULL(J) =  I_1                                                   
         IRESET   = -I_1                                                    
         PYMOUT(J) = CYMOUT(J)                                              
         CYCLE
        ELSE
         PYMOUT(J) = CYMOUT(J)                                            
         CYCLE
        END IF
       END IF
!C
       IF ( ( JFULL - I_2 ) .LT. I_0 )  THEN
        WRITE ( LUAOU, 105 )   TIME                                         
  105   FORMAT ( '0 Error in Subroutine AIRBG3 at time =', F10.6 )         
        STOP 32                                                            
       ELSE IF ( ( JFULL - I_2 ) .EQ. I_0 )  THEN
!C                                                                        
!C      End of integration step when IFULL=0. Test for full inflation.     
!C                                                                        
        PD(J) = D_0                                                      
        PCYV(J) = CYV(J)                                                  
        PCYMIN(J) = CYMIN(J)                                               
        PVBAG(J) = VBAG(J)                                                 
        DO
         CALL AIRBGG ( J )                                                  
         VBAG(J) = CYV(J) + VOLBP(J)                                        
         IF  ( SCALEX(J) .EQ. D_1 )   THEN                             
          IFULL(J) = -I_1                                                  
          CYMOUT(J) = D_0                                                 
          PSW1 = ( VBAG (J) - VBAGG(J) ) * PCYV(J) / PCYMIN(J)               
          PSW2 = ( VBAGG(J) - PVBAG(J) ) * CYV(J)  / CYMIN(J)                
          SWITCH(J) = ( PSW1 + PSW2 ) / ( VBAG(J) - PVBAG(J) )               
          BAGPV(J) = CYPA(J) * ( CYMIN(J) * SWITCH(J) )**CYK(J)              
          PD(J) = BAGPV(J) / ( CYV(J) **CYK(J) ) - CYPA(J)                   
         ELSE
          SCALEX(J) = ( VBAG(J) / VBAGG(J) )**D_THIRD                         
         END IF
         IF  ( SCALEX(J) .LT. D_1 )  EXIT 
          SCALEX(J) = D_1                                                  
        END DO
!C
        DO  K=1,3                                                         
         BD(K,JB) = SCALEX(J) * AB(K,J)                                     
         IF  ( SCALEX(J) .EQ. D_0 )  CYCLE                               
         BD(4*K+12,JB) = BD(K,JB)**2                                      
         BD(4*K+ 3,JB) = D_1 / BD(4*K+12,JB)                              
         TMP(K) = DEPLOY(K,J) + BD(1,JB) * DPVCTR(K,J)                  
        END DO
        CALL PANEL ( DBR(1,1,J), TMP, JB )                                 
       END IF
!C                                                                        
!C     Set up BAGSF array for output.                                     
!C                                                                        
       BAGSF(1,NBGSF+1) = CYP(J)                                          
       BAGSF(2,NBGSF+1) = CYT(J)                                          
       BAGSF(3,NBGSF+1) =  PD(J)                                          
       CALL DOT31 ( SEG(JB)%DIR_COS, BD(4,JB), TMP3 )                    
       TMP3 = TMP3 + SEG(JB)%LIN_DISP - SEG(NVEH)%LIN_DISP        
       DO  K=1,3                                                          
        BAGSF(K,NBGSF+3) = BD(K,JB)                                       
       END DO
       CALL MAT31 ( SEG(NVEH)%DIR_COS, TMP3, BAGSF(1,NBGSF+2) )            
       CALL YPRDEG ( SEG(JB)%DIR_COS, BAGSF(1,NBGSF+4) )                  
       NBGSF = NBGSF + I_5 + NPANEL(J) + MNBAG(J)                      
  50  CONTINUE                                                            
!C
      CALL ELTIME ( I_2, 29_INTEGER_STD )                                              
!C
      RETURN                                                              
      END                                                                
