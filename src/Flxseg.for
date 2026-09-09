      SUBROUTINE FLXSEG                                                   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       RADIAN,                         ! /CNSNTS/
     &       NFLX,                           ! /CONTRL/
     &       NFLEX, HF, V4, B42,             ! /FLXBLE/
     &       SEG,                            ! structures
     &       INTEGER_STD, IREAL_HIGH,        ! parameters
     &       D_0, D_HALF, D_1,               ! parameters
     &       I_0, I_1, I_2, I_3, I_4         ! parameters
!C
!C    SEG%ANG_VEL, SEG%DIR_COS
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              I, IDYPR, IFX, J, JM, K, KK, M, N1, N2, N3
      DIMENSION  IDYPR(3)                                                 
!C
      REAL  ( KIND = IREAL_HIGH )  CSC, CSS, CT1, CT2, CT22, ST1, ST2 
      REAL  ( KIND = IREAL_HIGH )  
     &                  TT, THN, CN1, CN_LCL, WNM1, THND, PTD, 
     &                  WCSN, RHSN, RHS1, RHS2, GF, GC, CGC, THA,
     &                  THAD, THADEG, DN2N1, RMG
      DIMENSION  TT(3,3), THN(4), CN1(3,3), CN_LCL(3,3), WNM1(3),         
     &           THND(4), PTD(3), WCSN(3), RHSN(3), RHS1(3),              
     &           RHS2(3), GF(3,4), GC(3,3), CGC(3,3), THA(3),             
     &           THAD(3), THADEG(3), DN2N1(3,3), RMG(3)                   
!C
      REAL  ( KIND = IREAL_HIGH )  XDY
      EXTERNAL  XDY
!C
      DATA      IDYPR / I_3, I_2, I_1 / 
!C
      IF ( NFLX .EQ. I_0 )  RETURN                                    
!C
      CALL ELTIME ( I_1, 34_INTEGER_STD )                                               
!C
      IFX = I_1                                                         
      DO
       N1 = NFLEX(1,IFX)                                                   
       N3 = NFLEX(3,IFX)                                                   
       CALL DOTT33 ( SEG(N3)%DIR_COS, SEG(N1)%DIR_COS, TT )                     
       THN(1) =  ATAN2 ( TT(1,2), TT(1,1) )                                
       THN(2) = -ASIN ( TT(1,3) )                                       
       THN(3) =  ATAN2 ( TT(2,3), TT(3,3) )                         
       THN(4) =  D_1                                                     
       CT22 = D_1 - TT(1,3)**2                                             
       CT2  = SQRT ( CT22 )                                                
       ST2  = -TT(1,3)                                                     
       CT1  =  TT(1,1) / CT2                                               
       ST1  =  TT(1,2) / CT2                                               
       CN1(1,1) = -TT(1,1) * TT(1,3) / CT22                                
       CN1(1,2) = -TT(1,2) * TT(1,3) / CT22                                
       CN1(1,3) =  D_1                                                    
       CN1(2,1) = -ST1                                                     
       CN1(2,2) =  CT1                                                     
       CN1(2,3) =  D_0                                                   
       CN1(3,1) =  TT(1,1) / CT22                                          
       CN1(3,2) =  TT(1,2) / CT22                                          
       CN1(3,3) =  D_0                                                  
       CALL DOT31 ( TT, SEG(N3)%ANG_VEL, WNM1 )             
       WNM1 = WNM1 - SEG(N1)%ANG_VEL                          
       CALL MAT31 ( CN1, WNM1, THND )                                      
       THND(4) =  D_0                                                    
       CALL CROSS ( SEG(N1)%ANG_VEL, WNM1, WCSN )                     
       RHSN(1) = 
     &     (  ( -THND(1) * ST1 * ST2 + THND(2) * CT1 / CT2) * WNM1(1)    
     &      + (  THND(1) * CT1 * ST2 + THND(2) * ST1 / CT2) * WNM1(2) )
     &                              / CT2                                  
       RHSN(2) =  -THND(1) * ( CT1 * WNM1(1) + ST1 * WNM1(2) )             
       RHSN(3) =  
     &     (  ( -THND(1) * ST1 + THND(2) * CT1 * ST2 / CT2) * WNM1(1)      
     &      + (  THND(1) * CT1 + THND(2) * ST1 * ST2 / CT2) * WNM1(2) )
     &                             / CT2                                   
       DO
        N2 = NFLEX(2,IFX)                                                   
        M = I_0                                                         
        DO  I=1,3                                                           
         DO  J=1,4                                                          
          JM = J + M                                                        
          GF(I,J) = D_0                                                  
          DO  K=1,4                                                         
           GF(I,J) = GF(I,J) + HF(K,JM,IFX) * THN(K)                        
          END DO
         END DO
         M = M + I_4                                                   
        END DO
        DO  I=1,3                                                           
         THA(I)  = D_0                                                    
         THAD(I) = D_0                                                    
         DO  J=1,4                                                          
          THA (I) = THA (I) + GF(I,J) * THN (J)                             
          THAD(I) = THAD(I) + GF(I,J) * THND(J)                             
         END DO
         THA (I) = D_HALF * THA(I)                                            
         THADEG(I) = THA(I) / RADIAN                                        
        END DO
        CALL DRCYPR ( DN2N1, THADEG, IDYPR )                                
        CALL MAT33 ( DN2N1, SEG(N1)%DIR_COS, SEG(N2)%DIR_COS )            
        CSC = COS ( THA(2) )                                                
        CSS = SIN ( THA(2) )                                                
        CN_LCL(1,1) =   D_0                                              
        CN_LCL(2,1) =   D_0                                               
        CN_LCL(3,1) =   D_1                                                 
        CN_LCL(1,2) =  -SIN ( THA(1) )                                    
        CN_LCL(2,2) =   COS ( THA(1) )                                      
        CN_LCL(3,2) =   D_0                                                
        CN_LCL(1,3) =   CSC * CN_LCL(2,2)                                   
        CN_LCL(2,3) =  -CSC * CN_LCL(1,2)                                   
        CN_LCL(3,3) =  -CSS                                                 
        CALL MAT33  ( GF,     CN1, GC  )                                    
        CALL MAT33  ( CN_LCL, GC,  CGC )                                    
        CALL DOT33  ( SEG(N1)%DIR_COS ,CGC, B42(1,1,3*IFX-2) )              
        CALL DOTT33 ( B42(1,1,3*IFX-2), TT, B42(1,1,3*IFX) )                
        DO  I=1,3                                                           
         DO  J=1,3                                                          
          B42(I,J,3*IFX-2) = B42(I,J,3*IFX-2) - SEG(N1)%DIR_COS(J,I)  
          B42(I,J,3*IFX-1) = SEG(N2)%DIR_COS(J,I)                               
          B42(I,J,3*IFX  ) = -B42(I,J,3*IFX)                                
         END DO
        END DO
!C                                                                          
!C      Compute V4                                                          
!C                                                                          
        CALL MAT31 ( CGC, WNM1, RHS1 )                                      
        RMG = RHS1 + SEG(N1)%ANG_VEL                           
        CALL MAT31 ( DN2N1, RMG, SEG(N2)%ANG_VEL )                 
        CALL CROSS ( SEG(N1)%ANG_VEL, RHS1, RHS2 )                  
        CALL MAT31 ( CGC, WCSN, RHS1 )                                      
        RHS1 = RHS2 - RHS1                      
        CALL MAT31 ( GC, WNM1, RHS2 )                                       
        RHS1(1) = RHS1(1) - THAD(1) * (   CN_LCL(2,2)       * RHS2(2)
     &                                  - CN_LCL(1,2) * CSC * RHS2(3) )     
     &                    - THAD(2) *     CN_LCL(2,2) * CSS * RHS2(3)       
        RHS1(2) = RHS1(2) + THAD(1) * (   CN_LCL(1,2)       * RHS2(2)
     &                                  + CN_LCL(2,2) * CSC * RHS2(3) )     
     &                    + THAD(2) *     CN_LCL(1,2) * CSS * RHS2(3)       
        RHS1(3) = RHS1(3) - THAD(2) * CSC * RHS2(3)                         
        CALL MAT31 ( GF, RHSN, RHS2 )                                       
        M = I_1                                                           
        DO  I=1,3                                                           
         DO  J=1,3                                                          
          PTD(J) = D_0                                                  
          DO  K=1,3                                                         
           KK = K + M - I_1                                             
           PTD(J) = PTD(J) + HF(J,KK,IFX) * THND(K)                         
          END DO
         END DO
         RHS2(I) = RHS2(I) + XDY ( PTD, CN1, WNM1 )                         
         M = M + I_4                                                   
        END DO
        CALL MAT31 ( CN_LCL, RHS2, PTD )                                    
        DO  I=1,3                                                           
         RHS1(I) = RHS1(I) + PTD(I)                                         
        END DO
        CALL DOT31 ( SEG(N1)%DIR_COS, RHS1, V4(1,IFX) )             
        IF ( IFX .EQ. NFLX )  EXIT                                      
        IFX = IFX + I_1                                                   
        IF ( ( NFLEX(1,IFX) .EQ. N1 ) .AND. 
     &      ( NFLEX(3,IFX) .EQ. N3 ) )   THEN
         CYCLE
        ELSE
         EXIT
        END IF                            
       END DO
      END DO
!C
      CALL ELTIME ( I_2, 34_INTEGER_STD )                                               
!C
      RETURN                                                              
      END                                                                 
