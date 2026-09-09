      SUBROUTINE OUTPUT_FORCES ( LTAPE8, LTHIST, NT, USEC_LCL )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    This subroutine outputs the various force tabular time
!C     histories to either Tape8 or to the individual time
!C     history files.  It is called only by Subroutine OUTPUT.
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       BELT_FORCE,                                  ! /CNTSRF/
     &       NBAG, NBLT, NHRNSS, NPL, NSD, NSEG,          ! /CONTRL/
     &       NOUTPS, NOUTSS,                              ! /COUT/
     &       DAMP_FORCE,                                  ! /DAMPER/
     &       BAGSF, HARNESS_FORCE, NPANEL, PSF, SSF,      ! /FORCES/ 
     &       NBLTPH,                                      ! /HRNESS/
     &       MNBAG, MNBLT, MNPL, MNSEG, MPL,              ! /JBARTZ/
     &       TDATA,                                       ! /HEDING_TEMPVS/
     &       AIRBAG_TTH, BELT_TTH, HARNESS_TTH, SEG,      ! structures
     &       PLANE_SEG_TTH, SEG_SEG_TTH, SPRING_DAMP_TTH, ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD, LUTP8, ! parameters
     &       MAXPSF, MAXSSF, NUM_TTH_OFFSET,              ! parameters
     &       D_0, I_0, I_1, I_2, I_3, I_5                 ! parameters
!C
!C    DIR_COS, DRC_PHI, LIN_DISP, ROT_PHI        ! SEG%
!C
      USE  MODULE_WATER,  ONLY: NWATER    ! /WATINF1/
!C
!C
      IMPLICIT  NONE
!C
      INTEGER   ( KIND = INTEGER_STD )
     &           I, J, J1, J2, JEND, JPS, JSS,
     &           K, K1, K2, KBAG, KK, KPS, KSS, 
     &           MBSF, MBSF1, MP1, MP2, MPSF, MSF, MSS, MSSF, NT
      DIMENSION  JPS(MAXPSF), JSS(MAXSSF) 
!C
      REAL  ( KIND = IREAL_HIGH )  T8, T9, T10, T11, T12, USEC_LCL
      DIMENSION         T8(3,3), T9(3), T10(3), T11(3,3), T12(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTAPE8, LTHIST           
!C
      INTENT ( IN )     LTAPE8, LTHIST, USEC_LCL
      INTENT ( INOUT )  NT
!C                                                                        
!C    Print plane forces                                                  
!C                                                                        
      MPSF = I_0                                                       
      KPS = I_0                                                       
      IF  ( PLANE_SEG_TTH%PRINT )  THEN                                   
       DO  J=1,NPL                                                    
        IF ( MNPL(J) .NE. I_0 )   THEN                                 
!C                                                                        
!C       Transform to segment 2 reference frame if requested.              
!C                                                                        
         DO  K=1,MNPL(J)                                               
          IF ( MPL(3,K,J) .LT. I_0 ) THEN                              
           MP1 = MPL(1,K,J)                                               
           MP2 = MPL(2,K,J)                                               
           MSF = MPSF + K                                                 
           IF ( PSF(1,MSF) .GT. D_0 ) THEN                          
            IF  ( .NOT. SEG(MP1)%ROT_PHI )  THEN                          
             T8 = SEG(MP1)%DIR_COS
            ELSE                                                          
             CALL DOT33 ( SEG(MP1)%DRC_PHI, SEG(MP1)%DIR_COS, T8 )           
            END IF                                                        
            CALL DOT31 ( T8, PSF(5,MSF), T9 )                             
            T10 = T9 + SEG(MP1)%LIN_DISP - SEG(MP2)%LIN_DISP       
            IF ( .NOT. SEG(MP2)%ROT_PHI  )  THEN                     
             T11 = SEG(MP2)%DIR_COS
            ELSE                                                          
             CALL DOT33 ( SEG(MP2)%DRC_PHI, SEG(MP2)%DIR_COS, T11 )        
            END IF                                                        
            CALL MAT31 ( T11, T10, T12 )                                  
            DO  I=1,3                                                     
             PSF(I+4,MSF) = T12(I)                                        
            END DO
           END IF                                                         
          END IF                                                          
         END DO                                                         
         DO  K = 1,MNPL(J)                                               
          MSF = MPSF + K                                                
          IF ( NOUTPS(MSF) .EQ. I_1 )  THEN                          
           KPS = KPS + I_1                                          
           JPS(KPS) = MSF                                                
          END IF                                                         
         END DO                                                         
         MPSF = MPSF + MNPL(J)                                            
        END IF
       END DO
!C
!C     The real output plane/segment number                             
!C
       MPSF = KPS                                                       
       DO  J1=1,MPSF,2                                                    
        J2 = MIN ( ( J1 + I_1 ), MPSF )                        
        NT = NT + I_1                                                   
        IF  ( LTAPE8 )   THEN                                            
         KK = I_0                                                     
         DO  J=J1,J2                                                      
          DO  I=1,7                                                       
           KK = KK + I_1  
           TDATA(KK,NT-NUM_TTH_OFFSET) = PSF(I,JPS(J))                   
          END DO         
         END DO
        END IF
        IF  ( LTHIST )   THEN
         WRITE ( NT, 100 )  USEC_LCL, 
     &                     ( ( PSF(I,JPS(J)), I=1,7 ), J=J1,J2 )        
  100    FORMAT ( F9.3, 2( F9.3, 3F9.2, 3F8.3 ) )                         
        END IF
       END DO                                                           
      END IF
!C                                                                        
!C    Print simple belt forces.                                        
!C                                                                        
      IF  ( BELT_TTH%PRINT )  THEN                                        
       JEND = I_0
       DO  J=1,NBLT                                                       
        JEND = JEND + MNBLT(J)                                            
       END DO
       IF  ( JEND .NE. I_0 )  THEN                                        
        DO  J1=1,JEND,2                                                  
        J2 = MIN ( ( J1 + I_1 ), JEND )                          
         NT = NT + I_1                                                 
         IF  ( LTAPE8 )   THEN                                            
          KK = I_0                                                     
          DO  J=J1,J2                                                     
           DO  I=1,4                                                      
            KK = KK + I_1                                            
            TDATA(KK,NT-NUM_TTH_OFFSET) = BELT_FORCE(I,J)                 
           END DO
          END DO
         END IF
         IF  ( LTHIST )   THEN
          WRITE ( NT, 105 )  USEC_LCL, 
     &                      ( ( BELT_FORCE(I,J), I=1,4), J=J1,J2 )   
  105     FORMAT ( F9.3, 4( F15.6, F12.2, 3X ) )                          
         END IF
        END DO
       END IF
      END IF
!C                                                                        
!C    Print harness-belt endpoint forces 
!C                         (stored in HARNESS_FORCE array).      
!C                                                                        
      MBSF = I_0
      IF  ( HARNESS_TTH%PRINT )  THEN                                     
       MBSF1 = MBSF + I_1                                              
       DO  I=1,NHRNSS                                                     
        MBSF = MBSF + NBLTPH(I)                                           
       END DO
       DO  J1=MBSF1,MBSF,2                                                
        J2 = MIN ( ( J1 + I_1 ), MBSF )                          
        NT = NT + I_1                                                   
        IF  ( LTAPE8 )   THEN                                             
         KK = I_0                                                      
         DO  J=J1,J2                                                      
          DO  I=1,4                                                       
           KK = KK + I_1                                               
           TDATA(KK,NT-NUM_TTH_OFFSET) = HARNESS_FORCE(I,J)               
          END DO
         END DO
        END IF
        IF  ( LTHIST )   THEN
         WRITE ( NT, 107 ) USEC_LCL, 
     &                    ( ( HARNESS_FORCE(I,J), I=1,4 ), J=J1,J2 )    
  107     FORMAT ( F9.3, 4( F15.6, F12.2, 3X ) )                          
        END IF
       END DO
      END IF
!C                                                                        
!C     Print spring damper forces (stored in DAMP_FORCE array).           
!C                                                                        
      IF  ( SPRING_DAMP_TTH%PRINT )  THEN                                 
       JEND = NSD                                      
       DO  J1=1,JEND,2                                               
        J2 = MIN ( ( J1 + I_1 ), JEND )                          
        NT = NT + I_1                                                  
        IF  ( LTAPE8 )  THEN                                              
         KK = I_0                                                     
         DO  J=J1,J2                                                      
          DO  I=1,4                                                       
           KK = KK + I_1                                              
           TDATA(KK,NT-NUM_TTH_OFFSET) = DAMP_FORCE(I,J)   
          END DO
         END DO
        END IF
        IF  ( LTHIST )  THEN
         WRITE ( NT, 110 ) USEC_LCL, 
     &                    ( ( DAMP_FORCE(I,J), I=1,4 ), J=J1,J2 )  
  110    FORMAT ( F9.3, 2( F14.3, 1X, 3F12.2, 4X ) )                           
        END IF
       END DO
      END IF
!C                                                                        
!C    Print segment contact forces.                                        
!C                                                                        
      MSSF = I_0                                                      
      KSS = I_0                                                      
      IF  ( SEG_SEG_TTH%PRINT )  THEN  
       DO  J=1,NSEG                                                       
        IF ( MNSEG(J) .GT. I_0 )  THEN                              
         DO  K=1,MNSEG(J)                                                
          MSS = MSSF + K                                                
          IF ( NOUTSS(MSS) .EQ. I_1 )  THEN                           
           KSS = KSS + I_1                                            
           JSS(KSS) = MSS                                                
          END IF                                                         
         END DO                                                         
        END IF                                                          
        MSSF = MSSF + MNSEG(J)                                            
       END DO
!C
!C     The real output segment/segment number.                           
!C
       MSSF = KSS                                                       
       IF  ( MSSF .NE. I_0 )   THEN                                    
        DO  J=1,MSSF                                                      
         NT = NT + I_1                                               
         IF  ( LTAPE8 )  THEN                                             
          DO  I=1,10                                                      
           TDATA(I,NT-NUM_TTH_OFFSET) = SSF(I,JSS(J))                   
          END DO
         END IF
         IF  ( LTHIST )   THEN
          WRITE ( NT, 115 ) USEC_LCL, ( SSF(I,JSS(J)), I=1,10 )           
  115     FORMAT ( 2F9.3, 3F9.2, 3F8.3, 2X, 3F8.3 )                       
         END IF
        END DO
       END IF                                                           
      END IF                                                              
!C                                                                        
!C    Print airbag forces                                                 
!C                                                                        
      IF  ( AIRBAG_TTH%PRINT )  THEN                                      
       K1 = I_1                                                         
       DO  J=1,NBAG                                                   
        IF ( MNBAG(J) .EQ. I_0 )  CYCLE                            
        KBAG = MNBAG(J) + NPANEL(J) + I_5                             
        DO  J1=1,KBAG,4                                                
         J2 = MIN ( ( J1 + I_3 ), KBAG )                        
         K2 = K1 + J2 - J1                                                
         NT = NT + I_1                                                 
         IF  ( LTAPE8 )  THEN                                             
          KK = I_0                                                     
          DO  K=K1,K2                                                     
           DO  I=1,3                                                      
            KK = KK + I_1                                               
            TDATA(KK,NT-NUM_TTH_OFFSET) = BAGSF(I,K)                      
           END DO
          END DO
         END IF
         IF  ( LTHIST )  THEN                                             
          IF  ( J1 .EQ. I_1 )  THEN
           WRITE ( NT, 120 )  USEC_LCL, 
     &                       ( ( BAGSF(I,K), I=1,3 ), K=K1,K2 )           
  120      FORMAT ( F9.3, 3X, 3F9.2, 2( 3X, 3F9.3 ), 3X, 3F9.2 )          
          ELSE
           WRITE ( NT, 125 )  USEC_LCL, 
     &                     ( ( BAGSF(I,K), I=1,3 ), K=K1,K2 )             
  125      FORMAT ( F9.3, 4( 3X, 3F9.2 ) )                                
          END IF
         END IF
         K1 = K2 + I_1                                                
        END DO
       END DO                                                         
      END IF
!C                                                                        
!C    Print the water forces                                              
!C                                                                       
      IF  ( NWATER .GT. I_0 )   THEN
       CALL OUTPUT_WATER ( LTHIST, LTAPE8, NT, USEC_LCL )    
      END IF
!C                                                                       
!C    Write all the data to the array TDATA.
!C
      NT = NT - NUM_TTH_OFFSET                                           
      IF  ( LTAPE8 )  THEN
       WRITE ( LUTP8 ) NT, USEC_LCL, 
     &         ( ( TDATA(I,J), I=1,14 ), J=1,NT )                         
      END IF
!C
      RETURN
      END
      