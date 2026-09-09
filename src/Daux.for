      SUBROUTINE DAUX ( I1 )                                                
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes derivatives for integrator routine by                        
!C     (1) Set up initial values for array of system equations.             
!C     (2) Modify arrays by constraints.                                    
!C     (3) Solve system of equation for F, TQ, QQ and V4.                   
!C     (4) Evaluate derivatives SEGLA and WMEGD.                            
!C                                                                          
      USE  MODULE_STANDARD,  ONLY:
     &       A11, A22, B12,                   ! /CMATRX/
     &       EPS,                             ! /CNSNTS/
     &       NPRT, NGRND, NJNT, NS, NPG, NQ,  ! /CONTRL/
     &       KQTYPE, KQ1, KQ2, QQ, A13, A23,  ! /CSTRNT/
     &       B42, NFLX, NFLEX, V4,            ! /FLXBLE/
     &       C, RHS, IJ, IJK, NQ2S,           ! /DAUX_TEMPVS/
     &       SEG, JNT,                        ! structures
     &       INTEGER_STD, IREAL_HIGH,         ! parameters
     &       LUAOU, MAXCMX, MAXRHS,           ! parameters
     &       D_0, I_0, I_1, I_2, I_4, I_9     ! parameters
!C
!C    ANG_ACCEL,  DRC_PHI,   EXT_ANG_ACL, EXT_LIN_ACL, LIN_ACCEL,  ! SEG%
!C    RECIP_MASS, RECIP_PHI, ROT_PHI,     SINGULAR,    WEIGHT      ! SEG%  
!C
!C    JFORCE, JTORQUE, PROX_SEG, SLIP_FREE                         ! JNT%
!C
      IMPLICIT  NONE
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &             I, I1, IS, J, K, L, M, MJ2, 
     &             N, N1, N2, N3, NI, NJ, NJ2 
!C
      REAL  ( KIND = IREAL_HIGH )   EPS_MIN 
!C
      INTENT ( IN )  I1
!C
      CALL ELTIME ( I_1, I_9 )                                                  
!C
!C    Define the smallest value that the solution variables can 
!C     have and not be considered to be 0.
!C
      EPS_MIN= EPS(12)                                                   
!C                                                                          
!C    If I1#0, U1 and U2 have been set up by calling routine.               
!C                                                                          
      IF ( I1 .EQ. I_0 )  THEN                                       
       CALL DAUX_SETUP
      END IF
!C                                                                          
!C    Initialize IJK array and IJ counter to zero.                          
!C                                                                          
      NQ2S = I_2 * NS + NFLX + NQ                                        
      NJ2  = NQ2S + I_2 * NJNT                                          
      IF ( NJ2 .GT. MAXRHS )  THEN
       WRITE ( LUAOU, 111 )  NS, NFLX, NQ, NJNT, NJ2                      
  111  FORMAT ( '0NS=', I6, ',NFLX=', I6, ',NQ=', I6, ',NJNT=', I6,
     &          ' and NJ2=', I6, /,  
     &          ' The value of NJ2 exceeds the array sizes for RHS ',
     &          'and IJK in Subroutine DAUX. Program terminated.')          
       STOP 34
      END IF
!C
      MJ2 = NJ2                                                             
      DO  I=1,NJ2                                                           
       DO  J=1,NJ2                                                          
        IJK(I,J) = I_0                                                   
       END DO
      END DO
      IJ = I_0                                                          
!C                                                                          
!C    Elminate SEGLA and WMEGD from system of equations.                    
!C                                                                          
      IF ( NS .GT. I_0 )    CALL DAUX55                                   
      IF ( NJNT .NE. I_0 )  THEN                                         
       IF ( NFLX .GT. I_0 )  CALL DAUX44                                
       CALL DAUX11                                                          
       CALL DAUX12                                                          
       CALL DAUX22                                                          
      END IF
      IF ( NQ .GT. I_0 )  THEN                                            
       IF ( NJNT .NE. I_0 )  THEN                                       
        CALL DAUX31                                                         
        CALL DAUX32                                                         
       END IF
       CALL DAUX33                                                          
       DO  I=1,NQ                                                           
        IF ( KQTYPE(I) .GE. I_4 )  MJ2 = -NJ2                           
       END DO
      END IF
!C
      IF ( NPRT(8) .NE. I_0 )  THEN                   
       WRITE ( LUAOU, 122 )  NPG, ( J, J=1,NJ2 )                              
  122  FORMAT ( '1 DAUX print of IJK matrix', 97X, 'Page', I5,
     &          //, 6X, 40I3 )         
       NPG = NPG + I_1                                                  
       DO  I=1,NJ2                                                          
        WRITE ( LUAOU, 124 )  I, ( IJK(I,J) , J=1,NJ2 )                
  124   FORMAT ( I3, 3X, 40I3 )                                             
       END DO
       WRITE ( LUAOU, 129 )                                            
  129  FORMAT ( '0 DAUX print of RHS array', // )                           
       DO  K=1,NJ2                                                          
        WRITE ( LUAOU, 127 )  K, ( RHS(I,K) ,I=1,3 )                      
       END DO
       WRITE ( LUAOU, 125 ) NPG                                          
  125  FORMAT ( '1 DAUX print of C array elements', 91X, 'Page', 
     &          I5, // )       
       NPG = NPG + I_1                                                 
       DO  K=1,IJ                                                           
        WRITE ( LUAOU, 127 )  K, ( ( C(I,J,K) ,J=1,3 ), I=1,3 )           
  127   FORMAT ( I6, 9G14.7 )                                               
       END DO
      END IF
!C
      IF ( NPRT(8) .NE. -I_2 )  THEN                                    
!C                                                                          
!C     Solve system of equations for F, TQ, QQ & V4.                        
!C                                                                          
       CALL FSMSOL ( C, RHS, IJK, MJ2, IJ, MAXRHS, MAXCMX )               
       IF ( NPRT(8) .EQ. I_2  )  THEN
        NPRT(8) = -I_2                        
        WRITE ( LUAOU, 130 )  NPG, ( J, J=1,NJ2 )                              
  130   FORMAT ( '1 DAUX print of IJK matrix', 97X, 'Page', I5,
     &           //, 6X, 40I3 )         
        NPG = NPG + I_1                                                  
        DO  I=1,NJ2                                                          
         WRITE ( LUAOU, 135 )  I, ( IJK(I,J) , J=1,NJ2 )                
  135    FORMAT ( I3, 3X, 40I3 )                                             
        END DO
        WRITE ( LUAOU, 140 )                                            
  140   FORMAT ( '0 DAUX print of RHS array', // )                           
        DO  K=1,NJ2                                                          
         WRITE ( LUAOU, 145 )  K, ( RHS(I,K) ,I=1,3 )                      
        END DO
        WRITE ( LUAOU, 150 ) NPG                                          
  150   FORMAT ( '1 DAUX print of C array elements', 91X, 'Page', 
     &           I5, // )       
        NPG = NPG + I_1                                                 
        DO  K=1,IJ                                                           
         WRITE ( LUAOU, 145 )  K, ( ( C(I,J,K) ,J=1,3 ), I=1,3 )           
  145    FORMAT ( I6, 9G14.7 )                                               
        END DO
       END IF
      END IF
      IF ( NPRT(8) .EQ. -I_2 ) NPRT(8) = I_0                                
!C
      IF ( NJNT .NE. I_0 )  THEN                                        
       DO  I=1,NJNT                                                         
        NJ = NQ2S + I                                                       
        NI = NJ + NJNT                                                      
        DO  K=1,3                                                           
         IF ( ABS ( RHS(K,NJ) ) .LT. EPS_MIN )  RHS(K,NJ) = D_0            
         IF ( ABS ( RHS(K,NI) ) .LT. EPS_MIN )  RHS(K,NI) = D_0             
         JNT(I)%JTORQUE(K) = JNT(I)%JTORQUE(K) - RHS(K,NI)
         JNT(I)%JFORCE(K)  = RHS(K,NJ)                                      
        END DO
       END DO
      END IF
!C
      IF ( NQ .NE. I_0 )  THEN                                           
       DO  I=1,NQ                                                           
        J = I_2 * NS + NFLX + I                                          
        DO  K=1,3                                                           
         IF  ( KQTYPE(I) .LT. I_0 )          RHS(K,J) = D_0           
         IF ( ABS ( RHS(K,J) ) .LT. EPS_MIN )   RHS(K,J) = D_0             
         QQ(K,I) = RHS(K,J)                                                 
        END DO
       END DO       
      END IF
!C
      IF ( NFLX .NE. I_0 )   THEN                                      
       DO  I=1,NFLX                                                         
        J = I_2 * NS + I                                                  
        DO  K=1,3                                                           
         IF ( ABS ( RHS(K,J) ) .LT. EPS_MIN )  RHS(K,J) = D_0           
         V4(K,I) = RHS(K,J)                                                 
        END DO
       END DO
      END IF
!C                                                                          
!C    Backup solution for segment linear and angular accelerations. 
!C                                                                          
      DO  J=1,NGRND                                                         
       SEG(J)%LIN_ACCEL = SEG(J)%EXT_LIN_ACL                                 
       SEG(J)%ANG_ACCEL = SEG(J)%EXT_ANG_ACL                             
      END DO
      IF ( NS .NE. I_0 )  THEN                                          
!C                                                                          
!C     Set up SEGLA & WMEGD for singular segments.                          
!C                                                                          
       IS = I_0                                                         
       DO  J=1,NGRND                                                        
        IF ( SEG(J)%SINGULAR .GT. I_0 )  THEN                               
         IS = IS + I_2                                                    
         DO  I=1,3                                                          
          IF ( ABS ( RHS(I,IS-1) ) .LT. EPS_MIN )  RHS(I,IS-1) = D_0       
          SEG(J)%LIN_ACCEL(I) = SEG(J)%LIN_ACCEL(I) + RHS(I,IS-1)        
          IF ( ABS ( RHS(I,IS  ) ) .LT. EPS_MIN )  RHS(I,IS  ) = D_0        
          SEG(J)%ANG_ACCEL(I) = SEG(J)%ANG_ACCEL(I) + RHS(I,IS)            
         END DO
        END IF
       END DO                                                               
      END IF
      IF ( NJNT .NE. I_0 )  THEN                                         
!C                                                                          
!C     Eliminate F                                                          
!C                                                                          
       DO  M=1,NJNT                                                    
        N = ABS ( JNT(M)%PROX_SEG )                                       
        IF ( N .NE. I_0 )  THEN                                         
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SEG(N  )%LIN_ACCEL(I) = SEG(N  )%LIN_ACCEL(I) - A11(I,J,M) 
     &                        * SEG(N  )%RECIP_MASS   * JNT(M)%JFORCE(J)  
           SEG(M+1)%LIN_ACCEL(I) = SEG(M+1)%LIN_ACCEL(I) + A11(I,J,M)
     &                        * SEG(M+1)%RECIP_MASS   * JNT(M)%JFORCE(J) 
           SEG(N)%ANG_ACCEL(I)   = SEG(N  )%ANG_ACCEL(I)
     &       - B12(J,I,2*M-1) * SEG(N  )%RECIP_PHI(I) * JNT(M)%JFORCE(J)         
           SEG(M+1)%ANG_ACCEL(I) = SEG(M+1)%ANG_ACCEL(I)
     &       - B12(J,I,2*M  ) * SEG(M+1)%RECIP_PHI(I) * JNT(M)%JFORCE(J)   
          END DO
         END DO
        END IF
!C                                                                          
!C      Eliminate TQ                                                        
!C                                                                          
        IF ( .NOT. JNT(M)%SLIP_FREE ) THEN                                  
         L = NQ2S + NJNT + M                                                
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SEG(N  )%ANG_ACCEL(I) = SEG(N  )%ANG_ACCEL(I)
     &              - A22(I,J,2*M-1) * SEG(N  )%RECIP_PHI(I) * RHS(J,L)      
           SEG(M+1)%ANG_ACCEL(I) = SEG(M+1)%ANG_ACCEL(I)
     &              + A22(I,J,2*M  ) * SEG(M+1)%RECIP_PHI(I) * RHS(J,L)    
          END DO
         END DO
        END IF
       END DO
!C                                                                      
!C     Compute deformable body accelerations                            
!C
       CALL FXMACC                                                      
      END IF
!C                                                                      
      IF ( NQ .NE. I_0 )  THEN                                           
!C                                                                          
!C     Eliminate QQ                                                         
!C                                                                          
       DO  K=1,NQ                                                           
        IF ( KQTYPE(K) .GE. I_0 )  THEN                                  
         N = KQ1(K)                                                         
         M = KQ2(K)                                                         
         DO  I=1,3                                                          
          DO  J=1,3                                                         
           SEG(N)%LIN_ACCEL(I) = SEG(N)%LIN_ACCEL(I) - A13(I,J,2*K-1) 
     &                              * SEG(N)%RECIP_MASS   * QQ(J,K)      
           SEG(M)%LIN_ACCEL(I) = SEG(M)%LIN_ACCEL(I) - A13(I,J,2*K  ) 
     &                              * SEG(M)%RECIP_MASS   * QQ(J,K)         
           SEG(N)%ANG_ACCEL(I) = SEG(N)%ANG_ACCEL(I) - A23(I,J,2*K-1) 
     &                              * SEG(N)%RECIP_PHI(I) * QQ(J,K)     
           SEG(M)%ANG_ACCEL(I) = SEG(M)%ANG_ACCEL(I) - A23(I,J,2*K  ) 
     &                              * SEG(M)%RECIP_PHI(I) * QQ(J,K)        
          END DO 
         END DO
        END IF
       END DO                                                              
      END IF
      IF ( NFLX .NE. I_0 ) THEN                                         
!C                                                                          
!C     Eliminate V4 (torques for flexible segments)                         
!C                                                                          
       DO  N=1,NFLX                                                         
        N1 = NFLEX(1,N)                                                     
        N2 = NFLEX(2,N)                                                     
        N3 = NFLEX(3,N)                                                     
        DO  I=1,3                                                           
         DO  J=1,3                                                          
          SEG(N1)%ANG_ACCEL(I) = SEG(N1)%ANG_ACCEL(I) - B42(J,I,3*N-2)
     &                                * SEG(N1)%RECIP_PHI(I) * V4(J,N)           
          SEG(N2)%ANG_ACCEL(I) = SEG(N2)%ANG_ACCEL(I) - B42(J,I,3*N-1)
     &                                * SEG(N2)%RECIP_PHI(I) * V4(J,N)        
          SEG(N3)%ANG_ACCEL(I) = SEG(N3)%ANG_ACCEL(I) - B42(J,I,3*N  )
     &                                * SEG(N3)%RECIP_PHI(I) * V4(J,N)      
         END DO
        END DO
       END DO
      END IF
!C
      DO  J=1,NGRND                                                         
       DO I=1,3
        IF ( ABS ( SEG(J)%ANG_ACCEL(I) ) .LE. EPS_MIN )  THEN
         SEG(J)%ANG_ACCEL(I) = D_0        
        END IF
        IF ( ABS ( SEG(J)%LIN_ACCEL(I) ) .LE. EPS_MIN )  THEN
         SEG(J)%LIN_ACCEL(I) = D_0   
        END IF
       END DO
      END DO
!C                                                                          
!C    Optional output of functions and derivatives.                         
!C                                                                          
      IF ( NPRT(9) .NE. I_0 )  CALL PRINT( ' DAUX ' )                   
!C                                                                          
      CALL ELTIME ( I_2,I_9 )                                                  
!C
      RETURN                                                                
      END                                                                   
