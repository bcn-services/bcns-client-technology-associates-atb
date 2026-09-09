      SUBROUTINE  HSETC_SUB ( IJ_LCL, K, KH, KI, KM, KNL, M, RH, SGN )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine was created from Subroutine HSETC to improve
!C     the coding appearance of Subroutine HSETC. 
!C     It is called only by Subroutine HSETC.
!C
!C
      USE  MODULE_STANDARD,  ONLY:
     &        NL, IBAR,                                  ! /HRNESS/
     &        IJK_HRN,  RHS_HRN, R_HRN, T_HRN, V_HRN,    ! /HRN_TEMPVS/
     &        S_HRN, E_HRN, B_HRN, C_HRN,                ! /HRN_TEMPVS/
     &        INTEGER_STD, IREAL_HIGH,                   ! parameters
     &        D_1, I_0, I_1, I_4, I_100                  ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I, IJ_LCL, J, K, KH, KHL, KI, KIL, 
     &           KK, KL, KM, KML, KNL, L, LL, M 
      DIMENSION  KM(3)                                           
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  EV, RH, SGN, VE, VEV
!C    
      REAL  ( KIND = IREAL_HIGH )  VECMAG
      EXTERNAL  VECMAG
!C
      INTENT (    IN )  K, KH, KI, KM, KNL, M, SGN
      INTENT ( INOUT )  IJ_LCL, RH
!C
      DO  LL=1,3                                                       
       L = I_4 - LL                                                          
       IF  ( KM(L) .EQ. I_0 )  RETURN                                  
       DO  J=1,3                                                           
        V_HRN(J) = R_HRN(M) * B_HRN(3,J,L) + SGN * B_HRN(M,J,L)            
       END DO
       KL = KM(L)                                                          
       KML = KNL + KL - K                                                  
       KIL = NL(1,KML)                                                     
!C
       IF  ( IBAR(5,KIL) .EQ. I_0 )   THEN                              
        KHL = KH + KL - K                                                  
        CALL DOT31 ( E_HRN(1,1,KHL), V_HRN, T_HRN )                        
        T_HRN(2) = R_HRN(M) * S_HRN(3,L) + SGN * S_HRN(M,L)                
        CALL MAT31 ( E_HRN(1,1,KHL), T_HRN, V_HRN )                        
       END IF
!C
       IF  ( LL .EQ. I_1 )  THEN                                        
        VE =   V_HRN(1) * E_HRN(1,M,KH) + V_HRN(2) * E_HRN(2,M,KH)
     &       + V_HRN(3) * E_HRN(3,M,KH)                                    
        EV = D_1                                                      
        IF  ( ABS ( IBAR(1,KI) ) .LT. I_100 )                    
     &     EV = SIGN ( D_1, VE ) / VECMAG ( V_HRN )
        RH = EV * RH                                                       
       END IF
!C
       IF  ( IJK_HRN(K,KL) .EQ. I_0 )  THEN                            
        IJ_LCL = IJ_LCL + I_1                                           
        IJK_HRN(K,KL) = IJ_LCL                                             
       END IF
       KK = IJK_HRN(K,KL)                                                  
       DO  J=1,3                                                           
        VEV = EV * V_HRN(J)                                                
        DO  I=1,3                                                          
         C_HRN(I,J,KK) = C_HRN(I,J,KK) + E_HRN(I,M,KH) * VEV               
        END DO
       END DO
      END DO                                                             
!C
      DO  I=1,3                                                            
       RHS_HRN(I,K) = RHS_HRN(I,K) + RH * E_HRN(I,M,KH)                    
      END DO
!C
      RETURN
      END