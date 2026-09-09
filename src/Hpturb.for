      SUBROUTINE HPTURB                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       UNITL, UNITM,                           ! /CNSNTS/
     &       NHRNSS, TIME, NPRT, NPG,                ! /CONTRL/
     &       HRN_MAX_ITR,                            ! /HPTRB/
     &       BB, BAR, HTIME, NBLTPH,                 ! /HRNESS/ 
     &       PTLOSS, OLDBB,                          ! /HRN_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH, LUAOU, MAXHPT, ! parameters
     &       D_0, D_1000, I_0, I_1, I_2              ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, ITER, J, J1, J2, K0, K1, KNL0, KNL1, KNLN, 
     &          NH, NHPASS 
!C
      REAL  ( KIND = IREAL_HIGH )
     &              DELMAX, DHT, SCALE_LCL, TSEC
!C
      CALL ELTIME ( I_1, 39_INTEGER_STD )                                               
!C
      CALL HBPLAY                                                         
!C
      DHT = D_0                                                         
      IF  ( TIME .NE. D_0 )  DHT = TIME - HTIME(1)                      
      HTIME(1) = TIME                                                     
      PTLOSS = D_0
      OLDBB = BB
      DO  J=1,MAXHPT                                                         
       DO  I=1,3                                                          
        BAR(I,J) = BAR(I+3,J)                                             
       END DO
      END DO
      TSEC = D_1000 * TIME                                            
      IF  ( NPRT(28) .NE. I_0 )    THEN
       WRITE ( LUAOU, 100 ) TSEC, NPG, UNITL, UNITM, UNITL,                 
     &                     UNITL, UNITM, UNITL, UNITM                    
  100  FORMAT ( '1   Harness Belt Results for Time =', F9.3, 
     &          ' msec.', 73X, 'Page', I5, ///, 36X,                       
     &          'Belt Strain', 6X, '(Local or Ellipsoid)', 18X,           
     &          '(inertial)', 14X, 'Penetration', /,                      
     &          '     Point   Point  Segment Length  Energy Loss', 5X,    
     &          'Reference Point (', A4, ')', 13X, 'Belt Forces  (',
     &          A4, ')', 9X, 'Energy Loss', /,                            
     &          '      No.    Index    No.   (', A4, ')  (', 2A4, 
     &          ')', 7X, 'X', 8X, 'Y', 8X, 'Z', 13X, 'X', 10X, 'Y',
     &          10X, 'Z', 8X, '(', 2A4, ')', / )                          
       NPG = NPG + I_1                                                    
      END IF
      J1 = I_1                                                          
      K0 = I_1                                                         
      KNL0 = I_0                                                   
!C
      DO  NH=1,NHRNSS                                                 
       NHPASS = NH
       IF  ( NBLTPH(NH) .LE. I_0 )  CYCLE                           
       ITER = I_1                                                      
       KNL1 = KNL0                                                        
       KNLN = I_0                                                     
       CALL HPTURB_SETUP ( ITER, J1, J2, K0, K1, KNL0, KNL1, KNLN, 
     &                     NHPASS, DHT, DELMAX, SCALE_LCL  )  
!C
       IF  ( ITER .GT. HRN_MAX_ITR ) THEN
        WRITE  ( LUAOU, 105 )  HRN_MAX_ITR, TSEC, DELMAX, SCALE_LCL              
  105   FORMAT ( '0 HPTURB ITER =', I4, ' at time =', F8.3,               
     &           ' msec.  DELMAX =', F10.6, '  SCALE_LCL =', F10.6 )       
       END IF
!C
       J1 = J2 + I_1                                                     
       K0 = K1                                                             
       KNL0 = KNLN                                                         
      END DO                                                            
!C
      IF  ( NPRT(28) .LT. I_0 )   NPRT(28) = I_0                   
!C
      CALL ELTIME ( I_2, 39_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
