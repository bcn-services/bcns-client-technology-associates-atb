      SUBROUTINE HICCSI ( NPTS, IDBDY, SPAN, JDTPTS, Z_LCL )              
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    Computes HIC, HSI and CSI for CVS program.                          
!C                                                                        
!C    Assumes Z array contains:                                           
!C    Z_LCL(I,1 ),I=1,NPTS : time points ( milliseconds)                   
!C    Z_LCL(I,JH),I=1,NPTS : head resultant accelerations (G's)           
!C    Z_LCL(I,JC),I=1,NPTS : chest resultant accelerations (G's)          
!C                                                                        
!C    Note:                                                               
!C    if JDTPTS(1)=0, head resultant is not available (JH=NULL,JC=2).     
!C    if JDTPTS(2)=0, chest resultant is not available (JH=2,JC=NULL).    
!C    otherwise, JH=2 and JC=3.                                           
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS,                                       ! /CNSNTS/
     &        NPG,                                       ! /CONTRL/
     &        INTEGER_STD, IREAL_STD, LUAOU, MXHIC,      ! parameters
     &        I_0, I_1, I_2, I_3, R_0, R_HALF, R_1000    ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              I, IDBDY, JC, JDTPTS, JH, K, L, MIN_HIC_PNTS,
     &              N_SPAN, NPTS
      DIMENSION  JDTPTS(2)
      PARAMETER   ( MIN_HIC_PNTS = 25_INTEGER_STD )
!C
      
      REAL  ( KIND = IREAL_STD )
     &           AREA_LCL, AVE, CMT, CMX, CSI, DH, DT_LCL, H1, H2, 
     &           HA1, HA2, HIC, HM, HMT, HMX, HSI, HT_LCL, HT1, HT2,
     &           SPAN, SPAN_LIMIT, Z_LCL, T_SPAN
      DIMENSION  AREA_LCL(MXHIC), Z_LCL(MXHIC,3)                          
!C
      PARAMETER  ( SPAN_LIMIT = 36.0E0_IREAL_STD )
!C
      INTENT (    IN )  NPTS, IDBDY, JDTPTS, Z_LCL
      INTENT ( INOUT )  SPAN
!C
      IF ( NPTS .LT. MIN_HIC_PNTS )  THEN
       WRITE ( LUAOU, 100 )  NPTS, MIN_HIC_PNTS                           
  100  FORMAT ( 1X, //, 2X, 'HIC, HSI and CSI not computed because ',
     &          'the number of points to be used in the computation =',
     &          I2, ',', /, 2X,
     &          'is less than the minimum requirement of ', 
     &          I3, ' points.', / )                                        
       RETURN
      END IF
!C
      WRITE  ( LUAOU, 105 )  NPG                                             
      NPG = NPG + I_1                                                   
  105 FORMAT ( '1','  HIC, HSI, CSI, and MSC Results', 89X, 'Page', I5 )       
      JH  = I_2                                                         
      JC  = I_3                                                      
      IF  ( JDTPTS(1) .EQ. I_0 )  JC = I_2                               
      CSI = R_0                                                      
      HSI = R_0                                                     
      HIC = R_0                                                      
      CMX = Z_LCL(1,JC)                                                   
      HMX = Z_LCL(1,JH)                                                   
      IF  ( JDTPTS(2) .NE. I_0 )   THEN                               
!C                                                                        
!C     Compute CSI - chest severity index                                 
!C                                                                        
       H1  = SQRT ( Z_LCL(1,JC) ) * Z_LCL(1,JC)**2                        
       DO  I=2,NPTS                                                       
        H2  = SQRT ( Z_LCL(I,JC) ) * Z_LCL(I,JC)**2                       
        DT_LCL  = Z_LCL(I,1) - Z_LCL(I-1,1)                               
        CSI = CSI + R_HALF * DT_LCL * ( H1 + H2 )                           
        IF  ( CMX .LE. Z_LCL(I,JC) )  THEN                                
         CMX = Z_LCL(I,JC)                                                
         CMT = Z_LCL(I,1)                                                 
        END IF
        H1  = H2                                                          
       END DO
       CSI = REAL ( EPS(3), IREAL_STD ) * CSI                             
      END IF
      IF  ( JDTPTS(1) .NE. I_0 )  THEN                              
!C                                                                        
!C     Compute HSI - head severity index - and area table                 
!C                                                                        
       AREA_LCL(1) = R_0                                             
       H1  = SQRT ( Z_LCL(1,JH) ) * Z_LCL(1,JH)**2                        
       DO  I=2,NPTS                                                       
        H2  = SQRT ( Z_LCL(I,JH) ) * Z_LCL(I,JH)**2                       
        DT_LCL  = R_HALF * ( Z_LCL(I,1) - Z_LCL(I-1,1) )               
        AREA_LCL(I) = AREA_LCL(I-1) +
     &                DT_LCL * ( Z_LCL(I-1,JH) + Z_LCL(I,JH) )            
        HSI = HSI + DT_LCL * ( H1 + H2 )                                  
        IF  ( HMX .LE. Z_LCL(I,JH) )  THEN                                
         HMX = Z_LCL(I,JH)                                                
         HMT = Z_LCL(I,1)                                                 
        END IF
        H1  = H2                                                          
       END DO
       HSI = REAL ( EPS(3), IREAL_STD ) * HSI                            
!C
!C     Compute HIC - head injury criterion - and time duration HT1,HT2     
!C     FMVSS 208 limits the search for the max HIC value to HIC time      
!C     intervals of 36 ms or less.                                        
!C
       IF ( IDBDY .EQ. I_1 )  THEN                                   
        IF ( ABS ( SPAN ) .LT. REAL ( EPS(6), IREAL_STD ) ) THEN       
         SPAN = SPAN_LIMIT                                                
        ELSE                                                             
         SPAN = SPAN * R_1000                                     
        END IF                                                          
       END IF                                                           
       DO  K=2,NPTS 
        N_SPAN = K
        T_SPAN = Z_LCL(N_SPAN, 1) - Z_LCL(K-1,1)
        DO WHILE ( (T_SPAN .LT. SPAN) .AND. (N_SPAN .LT. NPTS) )
         N_SPAN = N_SPAN + 1
         T_SPAN = Z_LCL(N_SPAN, 1) - Z_LCL(K-1,1)
        END DO                                                           
        DO  L=K,N_SPAN                                                   
         DT_LCL  = Z_LCL(L,1)  -  Z_LCL(K-1,1)                            
         DH  = AREA_LCL(L) - AREA_LCL(K-1)                                
         HT_LCL  = DH / DT_LCL                                            
         HM  = DT_LCL * SQRT ( HT_LCL ) * HT_LCL**2                       
         IF  ( HM .GT. HIC )  THEN                                        
          HIC = HM                                                        
          HT1 = Z_LCL(K-1,1)                                              
          HT2 = Z_LCL(L,1)                                                
          HA2 = Z_LCL(L,JH)                                               
          HA1 = Z_LCL(K-1,JH)                                             
          AVE = HT_LCL                                                    
         END IF   
        END DO                                                            
       END DO                                                             
       HIC = REAL ( EPS(3), IREAL_STD ) * HIC                        
       WRITE  ( LUAOU, 110 ) IDBDY                                       
  110  FORMAT ( 10X, 'Body Number ', I2, ' HIC Results', // )           
       WRITE  ( LUAOU, 115 )  HIC, HT1, HT2, HA1, HA2, AVE                 
  115   FORMAT ( '0', '   Head Injury Criterion', //,                      
     &          '    HIC = ', F12.4, 9X,                                 
     &          'Time duration = ', F9.3, '  TO ', F9.3, ' msec', /,      
     &          20X, 'with head resultants = ', F9.3, ' and ', 
     &          F9.3, ' G''s', //, 14X,                                   
     &          'Average head resultant for time duration = ', 
     &          F9.3, ' G''S' )                                           
       WRITE  ( LUAOU, 120 )  HSI, HMX, HMT                                
  120   FORMAT ( '0', '   Head Severity Index', //,                        
     &          '    HSI = ', F12.4, //                                  
     &          '    Max  head resultant = ', F9.3, ' G''s at ',
     &          F9.3, ' msec' )                                           
      END IF
!C
      IF  ( JDTPTS(2) .NE. I_0 )  THEN                                 
       WRITE  ( LUAOU, 125 )  CSI, CMX, CMT                                
  125   FORMAT ( '0', '   Chest Severity Index', //,                       
     &          '    CSI = ', F12.4, //,                                   
     &          '    Max chest resultant = ', F9.3, ' G''s at ',
     &          F9.3, ' msec' )                                           
      END IF
!C
      RETURN                                                              
      END                                                                 
