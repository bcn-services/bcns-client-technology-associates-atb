      SUBROUTINE CONTCT                                                   
!C
!C                                                  Rev. V.3 12/15/2002 
!C
!C    Controls the calling of subroutines required to compute those       
!C    external forces and torques acting on the body segments.            
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &        NRTORQ,                                 ! /ACTR/
     &        NBLT, NPL, NSEG, NSD, NHRNSS, NBAG,     ! /CONTRL/
     &        NPSF, NBSF, NSSF,                       ! /FORCES/
     &        NBLTPH,                                 ! /HRNESS/
     &        MNSEG, MNPL, MPL, NTPL, MNBLT,  MBLT,   ! /JBARTZ/
     &        NTBLT, MSEG, NTSEG,                     ! /JBARTZ/
     &        TAB, NTAB,                              ! /TABLES/
     &        MWSEG, NFORCE,                          ! /WINDFR/
     &        INTEGER_STD, MAXSSF, MAXPSF,            ! parameters
     &        MAX_NUM_BELTS, D_0,                     ! parameters
     &        I_0, I_1, I_2, I_6, I_12                ! parameters
!C
      USE  MODULE_WATER,  ONLY:  NWATER               ! /WATINF1/
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &            I, J, J1, J2, JT, KBLT, KNL0, KPL, KSEG, 
     &            M, M1, M2, M3, NF, NT 
!C                                                                        
!C    MAXSSF is allowed to overflow into BAGSF                            
!C                                                                        
      CALL ELTIME ( I_1, I_12 )                                              
!C
      NPSF = I_0                                                       
      NBSF = I_0                                                        
      NSSF = I_0                                                       
      IF ( NPL .GT. I_0 )  THEN                                        
!C                                                                        
!C     Call PLELP routine for each allowed plane-segment contact.         
!C                                                                        
       DO  J=1,NPL                                                        
        IF ( MNPL(J) .NE. I_0 )  THEN                                 
         KPL = MNPL(J)                                                    
         DO  I=1,KPL                                                      
          NPSF = NPSF + I_1                                            
          IF ( NPSF .GT. MAXPSF )  STOP 57                                
          M1 = MPL(1,I,J)                                                 
          M2 = MPL(2,I,J)                                                 
          M3 = ABS ( MPL(3,I,J) )                                         
          NT = NTPL(I,J)                                                  
          JT = NTAB(NT)                                                   
          TAB(JT) = D_0                                                 
          CALL PLELP ( M2, M3, M1, J, NT )                                
         END DO
        END IF
       END DO
      END IF
      IF ( NBLT .GT. I_0 )  THEN                                      
!C                                                                        
!C     Call BELTRT routine for each allowed belt-segment contact.         
!C                                                                        
       DO  J=1,NBLT                                                      
        IF ( MNBLT(J) .NE. I_0 )  THEN                                 
         KBLT = MNBLT(J)                                                  
         DO  I=1,KBLT                                                     
          NBSF = NBSF + I_1                                             
          IF ( NBSF .GT. MAX_NUM_BELTS )   STOP 58                         
          M1 = MBLT(1,I,J)                                                
          M2 = MBLT(2,I,J)                                               
          M3 = MBLT(3,I,J)                                               
          NT = NTBLT(I,J)                                                 
          JT = NTAB(NT)                                                   
          TAB(JT) = D_0                                                
          NF = NTAB(NT+5)                                                 
          IF ( NF .NE. I_0 )  JT = NTAB(NT+6)                        
          IF ( NF .NE. I_0 )  TAB(JT) = D_0                             
          CALL BELTRT ( M2, M3, M1, J, NT )                               
         END DO
        END IF
       END DO
      END IF
!C                                                                        
!C    Call SEGSEG routine for each allowed segment-segment contact.       
!C                                                                        
      DO  J=1,NSEG                                                       
       IF ( MNSEG(J) .NE. I_0 )  THEN                                  
        KSEG = MNSEG(J)                                                  
        DO  I=1,KSEG                                                     
         NSSF = NSSF + I_1                                              
         IF( NSSF .GT. ( MAXSSF + I_6 ) )   STOP 59                     
         M1 = MSEG(1,I,J)                                                 
         M2 = MSEG(2,I,J)                                                 
         M3 = MSEG(3,I,J)                                                
         NT = NTSEG(I,J)                                                  
         JT = NTAB(NT)                                                    
         TAB(JT) = D_0                                                
         CALL SEGSEG ( J, M1, M2, M3, NT )                                
        END DO
       END IF
      END DO
!C                                                                        
!C    Call AIRBAG routine for allowed bag-segment contacts, if any.       
!C                                                                        
      IF ( NBAG .NE. I_0 )  CALL AIRBAG                              
!C                                                                        
!C    Call WINDY routine for wind forces on each segment.                 
!C                                                                        
      DO  J=1,NSEG                                                        
       IF ( MWSEG(1,J) .NE. I_0 )  THEN                              
        M  = MWSEG(1,J)                                                   
        M1 = MWSEG(2,J)                                                   
        M2 = MWSEG(3,J)                                                   
        M3 = MWSEG(4,J)                                                   
        NT = MWSEG(5,J)                                                   
        CALL WINDY ( M, M1, M2, M3, NT )                                  
       END IF
      END DO
!C                                                                        
!C    Call FORCE_TORQE for force function calculations specified
!C     on Cards D.9.         
!C                                                                        
      IF ( NFORCE .GT. I_0 )  CALL FORCE_TORQUE              
!C                                                                        
!C    Call APPLY for driving joint torque calculations                   
!C                                                                        
      IF ( NRTORQ .GT. I_0 )  CALL APPLY                               
!C                                                                        
!C    Call HBELT routine for each harness-belt system.                  
!C                                                                       
      IF  ( NHRNSS .GT. I_0 )  THEN                                    
       J1 = I_1                                                          
       KNL0 = I_0                                                      
       DO  I=1,NHRNSS                                                    
        IF  ( NBLTPH(I) .GT. I_0 )  THEN                                
         J2 = J1 + NBLTPH(I) - I_1                                      
         CALL HBELT ( J1, J2, KNL0, I_0 )                              
         J1 = J2 + I_1                                                 
        END IF                                                            
       END DO
      END IF
!C                                                                        
!C    Call SPDAMP for spring damper forces, if any                       
!C                                                                        
      IF  ( NSD .NE. I_0 )  CALL SPDAMP                              
!C                                                                       
      IF ( NWATER .NE. I_0 ) CALL WATER_FORCE                             
!C
!C    Call SEG_DAMPING for the segment damping forces, if any.
!C
!C     CALL  SEG_DAMPING ( J )
!C                                                                      
      CALL ELTIME ( I_2, I_12 )                                               
!C
      RETURN                                                              
      END                                                                
