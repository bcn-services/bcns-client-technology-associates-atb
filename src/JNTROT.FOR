      SUBROUTINE  JNTROT ( JS, J, I, IRUN )                               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C
!C    XF: coord. system built from 3 nodes around joint location.       
!C    XJ: A coord. system, fixed with XF, aligned with segment
!C        local deformation reference system at time zero.
!C    XS: Segment local deformation reference system.
!C    Subroutine JNTROT computes the rotational displacement ROTJ()     
!C     and angular velocity ROTVJ() of XJ w.r.t. to XS, due to            
!C     deformation.  The joint axes are considered moving together with  
!C     XJ.                                                                
!C                                                                       
!C      IRUN: 0=initial run to compute AJF()                             
!C            1=called in middle of integration step                    
!C            2=called for update ROTOLD() and output result             
!C      JS:   1=joint on segment JNT(J), 2=joint on segment J+1          
!C      J:    joint number                                               
!C      I:    deformable segment number                                  
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:  
     &         DT,                                        ! /COMAIN/
     &         INTEGER_STD, IREAL_HIGH,                   ! parameters 
     &         I_0, I_1, I_2, I_3, I_6, D_0, D_1, D_180   ! parameters
!C
      USE  MODULE_FLEXIBLE,  ONLY:  
     &         FMODES, QNOD,                              ! /FXBODY/
     &         ANF, DNP, ROTJ, ROTVJ,                     ! /FXJROT/
     &         AMP, NMOD, NODJ,                           ! /FXVAR/
     &         FMODM,                                     ! /FXXTRA/
     &         AMPOLD, FMODO, ROTOLD                      ! /OLDDAT/      
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  
     &              I, IRUN, J, JJ, JS, KK, KM, L0, M, N  
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  XNOD, RVEC, VEC, AFS, ANS, T1, T2_LCL,
     &                  DEG, RT1, RT2
      DIMENSION         XNOD(3,3), RVEC(2), VEC(3,2), AFS(3,3),
     &                  ANS(3,3), T1(3), T2_LCL(3)                      
!C                                                                      
      DEG = D_180 / ACOS ( -D_1 )                                 
!C                                                                     
!C    Build 'XF' system by VEC1 X VEC2                                   
!C    VEC1= origin to point 1, VEC2 = origin to point 2                 
!C
      IF ( IRUN .EQ. I_0 ) THEN                                     
       DO  M = 1,3                                                        
        DO  KK = 1,3                                                    
         XNOD(KK,M) = QNOD(KK,NODJ(M,JS,J),I)                           
        END DO 
       END DO                                                           
      ELSE                                                              
       DO  M = 1,3                                                       
        L0 = I_6 * ( NODJ(M,JS,J) - I_1 )                          
        DO  KK = 1,3                                                    
         XNOD(KK,M) = QNOD(KK,NODJ(M,JS,J),I)                           
         DO  JJ = 1,NMOD(I)                                             
          XNOD(KK,M) = XNOD(KK,M) + FMODES(L0+KK,JJ,I) * AMP(JJ,I)      
         END DO
        END DO
       END DO                                                          
      END IF                                                           
!C                                                                      
!C    Compute length of VEC1 and VEC2                                   
!C
      DO  N = 1,2                                                      
       RVEC(N) = D_0                                                   
       DO  KK = 1,3                                                     
        RVEC(N) = RVEC(N) + ( XNOD(KK,N+1) - XNOD(KK,1) )**2            
       END DO                                                           
       RVEC(N) = SQRT ( RVEC(N) )                                       
      END DO                                                            
!C                                                                      
!C    Compute VEC1 and VEC2                                              
!C
      DO  N = 1,2                                                      
       DO  M = 1,3                                                      
        VEC(M,N) = ( XNOD(M,N+1) - XNOD(M,1) ) / RVEC(N)                 
       END DO
      END DO                                                             
!C                                                                      
!C    Compute consine matrix ASF, corresponding to transformation       
!C    from 'XS' to 'XF'                                                 
!C
      CALL CROSS ( VEC(1,1), VEC(1,2), T1     )                         
      CALL CROSS ( T1,       VEC(1,1), T2_LCL )                         
      RT1 = D_0                                                        
      RT2 = D_0                                                        
      DO  M = 1,3                                                       
       RT1 = RT1 + T1(M)**2                                             
       RT2 = RT2 + T2_LCL(M)**2                                          
      END DO
      RT1 = SQRT ( RT1 )                                                
      RT2 = SQRT ( RT2 )                                                
      DO  M = 1,3                                                       
       AFS(1,M) = VEC(M,1)                                              
       AFS(2,M) = T2_LCL(M) / RT2                                      
       AFS(3,M) = T1(M) / RT1
      END DO                                                            
!C                                                                      
!C    Compute the constant matrix ANF, corresponding to transformation  
!C    from 'XF' to 'XJ', 'XF' and 'XJ' are fixed together               
!C
      KM = ( J - I_1 ) * I_2 + JS                                   
      IF ( IRUN .EQ. I_0 )  THEN                                     
       CALL TRNPOS ( AFS, ANF(1,1,KM), I_3, I_3, I_3, I_3 )              
       DO  M = 1,3                                                      
        ROTJ(M,KM)  = D_0                                              
        ROTVJ(M,KM) = D_0                                              
       END DO
       RETURN                                                           
      END IF                                                            
!C                                                                      
!C    Compute cosine matrix ANS, corresponding to transformation         
!C    from 'XS' to 'XJ'. compute ROTJ(), ROTVJ() for IRUN =1.            
!C    If IRUN=2, update ROTOLD() at end of each integration step        
!C
      CALL MAT33 ( ANF(1,1,KM), AFS, ANS )                              
      CALL YPRDEG ( ANS, ROTJ(1,KM) )                                   
      DO  M = 1,3                                                       
       ROTJ(M,KM) = ROTJ(M,KM) / DEG                                     
      END DO
      IF ( IRUN .EQ. I_1 )  THEN                                     
       DO  M = 1,3                                                      
        ROTVJ(M,KM) = ( ROTJ(M,KM) - ROTOLD(M,KM) ) / DT                
       END DO
       DO  M = 1,3                                                      
        DO  N = 1,3                                                     
         DNP(M,N,KM) = ANS(M,N)                                         
        END DO
       END DO
       RETURN                                                           
      ELSE                                                              
       DO  M = 1,3                                                      
        ROTOLD(M,KM) = ROTJ(M,KM)                                       
       END DO
       DO  M=1,3                                                        
        DO  JJ=1,NMOD(I)                                                
         FMODO(M,JJ,KM) = FMODM(M,JJ,KM)                                
        END DO
       END DO
       DO  JJ=1,NMOD(I)                                                 
        AMPOLD(JJ,I) = AMP(JJ,I)                                        
       END DO
      END IF                                                            
!C                                                                      
      RETURN                                                            
      END                                                                
