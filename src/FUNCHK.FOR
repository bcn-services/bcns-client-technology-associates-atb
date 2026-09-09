      SUBROUTINE FUNCHK                                                 
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Check whether functions used for external forces, spring-dampers, 
!C    and joint functions have been defined in E cards.                 
!C                                                                      
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:    
     &       NSD, NJNT,              ! /CONTRL/
     &       ASD,                    ! /DAMPER/
     &       JOINTF,                 ! /DESCRP/
     &       NTI,                    ! /TABLES/
     &       NFVNT, NFORCE,          ! /WINDFR/ 
     &       INTEGER_STD, LUAOU, I_0 ! parameter
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, JF
!C
!C    Check spring-damper functions                                     
!C
      IF ( NSD .NE. I_0 ) THEN                                       
       DO  J=1,NSD                                                      
        IF ( ASD(1,J) .LT. I_0 ) THEN                                
         DO  I=2,4,2                                                    
          IF ( ASD(I,J) .NE. I_0 ) THEN                            
           JF = ASD(I,J)                                                
           IF ( NTI(JF) .EQ. I_0 ) THEN                             
            WRITE ( LUAOU, 100 )  JF                                    
  100       FORMAT ( '0 Spring-damper function no.', I4, ' has not ',   
     &               'been defined.  Program terminated.' )             
            STOP 17                                                     
           END IF                                                       
          END IF                                                        
         END DO                                                         
        END IF                                                          
       END DO                                                           
      END IF                                                            
!C                                                                      
!C    Check for external force functions                                
!C
      IF ( NFORCE .NE. I_0 ) THEN                                    
       DO  J=1,NFORCE                                                   
        JF = NFVNT(J)                                                   
        IF ( NTI(JF) .EQ. I_0 ) THEN                                  
         WRITE ( LUAOU, 110 ) JF                                        
  110    FORMAT ( '0 Force function no.', I4, 
     &            ' has not been defined.  Program terminated.')        
         STOP 17                                                        
        END IF                                                          
       END DO                                                           
      END IF                                                            
!C                                                                      
!C    Check for joint torque functions                                  
!C
      IF ( NJNT .NE. I_0 ) THEN                                      
       DO  J=1,NJNT                                                     
        DO  I=1,3                                                       
         JF = JOINTF(I,J)                                               
         IF ( ( JF .NE. I_0 ) .AND. ( NTI(JF) .EQ. I_0 ) )  THEN  
          WRITE ( LUAOU, 120 )  JF                                      
  120     FORMAT ( '0 Joint function no.', I4,
     &             ' has not been defined.  Program terminated.')       
          STOP 18                                                       
         END IF                                                         
        END DO                                                          
       END DO                                                           
      END IF                                                            
!C                                                                      
      RETURN                                                            
      END                                                               
