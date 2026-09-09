      SUBROUTINE FSMSOL ( C_LCL, R, NN_LCL, MX, MAXN, JN, MAXDIM )        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C       Solves a set of simultaneous equations  of size 3*MM             
!C       where the matrix consists of a set of 3*3 submatrices            
!C       stored in  C(3,3,IJ). The location of the I,J element            
!C       is  stored in   NN(I,J).  I.e.  IJ= NN(I,J)                      
!C                                                                        
!C       A negative IJ implies that C( , ,!IJ!) is an                     
!C       identity and the right side is zero. A negative                  
!C       IJ will only occur on a diagonal entry of NN.                    
!C                                                                        
!C           The  basic equation is   CX=R                                
!C                                                                        
!C          During the solution the C matrix is destroyed ,it may         
!C          be necessary to add to the C array.                           
!C          The solution is stored in R.                                  
!C                                                                        
!C     Input                                                              
!C                                                                        
!C          C(3,3,K)  given array                                         
!C          R(3,MM)   given right hand side                               
!C          NN(JJ,JJ) given array containing locations of I,J,element     
!C          MX        size of system of submatrices (positive indicates   
!C                    that C matrix is symmetric, negative it is not.)    
!C          MAXN      largest value in NN array                           
!C          JN        dimension of NN                                     
!C          MAXDIM    third dimension of C in calling routine             
!C                                                                        
      USE  MODULE_STANDARD,  ONLY: 
     &       INTEGER_STD, IREAL_HIGH,         ! parameters
     &       D_0, D_1, I_0, I_1, I_2, I_20    ! parameter
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, II, IJ_LCL, IK, IM1, IP, J, JI, JK, JN, K, KI, KJ, 
     &          L, M, MAXDIM, MAXN, MM, MM1, MP1, MX, N, NN_LCL
      DIMENSION  NN_LCL(JN,JN)
!C
      REAL  ( KIND = IREAL_HIGH )  C_LCL, R, A, B_LCL, D_LCL
      DIMENSION         C_LCL(3,3,MAXDIM), R(3,JN)                         
!C
      CALL ELTIME ( I_1, I_20 )                                               
!C
      MM = ABS ( MX )                                                     
      IF  ( MM .LE. I_0 )  THEN                                        
       CALL ELTIME ( I_2, I_20 )                                              
       RETURN
      END IF
!C
!C     MM1 = MM - 1                                                       
!C
      MM1 = MM - I_1
      MP1 = MM + I_1                                                    
      DO  50  II=1,MM                                                     
       I = MP1 - II                                                        
!C                                                                         
!C     Start pivot at bottom - find pivot - invert.                        
!C                                                                         
       L = NN_LCL(I,I)                                                     
       IF  ( L .LE. I_0 )   CYCLE                                   
       DO  M=1,3                                                           
        B_LCL        = D_1 / C_LCL(M,M,L)                               
        C_LCL(M,M,L) = D_1                                                
        C_LCL(M,1,L) = B_LCL * C_LCL(M,1,L)                                
        C_LCL(M,2,L) = B_LCL * C_LCL(M,2,L)                                
        C_LCL(M,3,L) = B_LCL * C_LCL(M,3,L)                                
        R(M,I)       = B_LCL * R(M,I)                                      
        DO  N=1,3                                                          
         IF  ( N .EQ. M )  CYCLE                                           
         B_LCL = C_LCL(N,M,L)                                              
         C_LCL(N,M,L) = D_0                                             
         C_LCL(N,1,L) = C_LCL(N,1,L) - B_LCL * C_LCL(M,1,L)                
         C_LCL(N,2,L) = C_LCL(N,2,L) - B_LCL * C_LCL(M,2,L)                
         C_LCL(N,3,L) = C_LCL(N,3,L) - B_LCL * C_LCL(M,3,L)                
         R(N,I)       = R(N,I)       - B_LCL * R(M,I)                      
        END DO                                                             
       END DO                                                              
!C                                                                         
!C     Check if done.                                                      
!C                                                                         
       IF  ( I .EQ. I_1 )  CYCLE                                     
        IM1 = I - I_1                                                    
!C                                                                         
!C     Calculate pivot row.                                                
!C                                                                         
       DO  J=1,IM1                                                         
        IF  ( NN_LCL(I,J) .EQ. I_0 )  CYCLE                            
        M = NN_LCL(I,J)                                                    
        DO  N=1,3                                                          
         A =       C_LCL(1,1,L) * C_LCL(1,N,M) 
     &           + C_LCL(1,2,L) * C_LCL(2,N,M)
     &           + C_LCL(1,3,L) * C_LCL(3,N,M)                             
         B_LCL =   C_LCL(2,1,L) * C_LCL(1,N,M) 
     &           + C_LCL(2,2,L) * C_LCL(2,N,M) 
     &           + C_LCL(2,3,L) * C_LCL(3,N,M)                             
         D_LCL =   C_LCL(3,1,L) * C_LCL(1,N,M) 
     &           + C_LCL(3,2,L) * C_LCL(2,N,M)
     &           + C_LCL(3,3,L) * C_LCL(3,N,M)                             
         C_LCL(1,N,M) = A                                                  
         C_LCL(2,N,M) = B_LCL                                              
         C_LCL(3,N,M) = D_LCL                                              
        END DO
       END DO                                                              
!C                                                                         
!C     Done with pivot row - zero column I above diagonal.                 
!C                                                                         
!C     1,1                                                                 
!C         .                                                               
!C            .                                                            
!C              K,K .  . K,J .  . K,I            C   = C   - C  *C         
!C               .  .     .        .              KJ    KJ    KI  IJ       
!C               .     .  .        .                                       
!C              J,K .  . J,J .  . J,I            C   = C   - C  *C         
!C               .        .  .     .              JK    JK    JI  IK       
!C               .        .     .  .                                       
!C              I,K .  . I,J .  . I,I            C   = 0                   
!C                                    .           KI                       
!C                                       .                                 
!C                                         M,M                             
!C                                                                         
       DO  40  K=1,IM1                                                     
        KI = NN_LCL(K,I)                                                    
        IK = NN_LCL(I,K)                                                    
        IF  ( ( KI .EQ. I_0 ) .AND. ( IK .EQ. I_0 ) )  CYCLE       
        DO  30  J=K,IM1                                                     
         IJ_LCL = NN_LCL(I,J)                                                
         JI     = NN_LCL(J,I)                                                
         IF  ( ( KI .EQ. I_0 ) .OR. ( IJ_LCL .EQ. I_0 ) )  THEN  
          CONTINUE
         ELSE
          KJ = NN_LCL(K,J)                                                    
          IF  ( KJ .EQ. I_0 )  THEN                                  
           MAXN = MAXN + I_1                                                
           IF  ( MAXN .GT. MAXDIM )  THEN
            CALL FSMSOL_STOP ( JN, MAXDIM, MAXN, MM, NN_LCL, C_LCL, R )
           END IF
           KJ = MAXN                                                           
           NN_LCL(K,J) = KJ                                                    
           DO  M=1,3                                                           
            DO  N=1,3                                                          
             C_LCL(N,M,KJ) = D_0                                              
            END DO
           END DO
          END IF
          DO  M=1,3                                                           
           DO  N=1,3                                                          
            C_LCL(N,M,KJ) = C_LCL(N,M,KJ) 
     &                    - C_LCL(N,1,KI) * C_LCL(1,M,IJ_LCL)                 
     &                    - C_LCL(N,2,KI) * C_LCL(2,M,IJ_LCL)                 
     &                    - C_LCL(N,3,KI) * C_LCL(3,M,IJ_LCL)                 
           END DO
          END DO
         END IF
!C
         IF  ( J .EQ. K )  CYCLE                                          
         IF  ( ( JI .EQ. I_0 ) .OR. ( IK .EQ. I_0 )  )   CYCLE      
         JK = NN_LCL(J,K)                                                    
         IF  ( JK .EQ. I_0 )  THEN                                        
          MAXN = MAXN + I_1                                                
          IF  ( MAXN .GT. MAXDIM )  THEN
           CALL FSMSOL_STOP ( JN, MAXDIM, MAXN, MM, NN_LCL, C_LCL, R )
          END IF
          JK = MAXN                                                          
          NN_LCL(J,K) = JK                                                   
          DO  M=1,3                                                          
           DO  N=1,3                                                         
            C_LCL(N,M,JK) = D_0                                         
           END DO
          END DO
         END IF
         IF  ( MX .GE. I_0 )  THEN                                      
          DO  M=1,3                                                          
           DO  N=1,3                                                         
            C_LCL(N,M,JK) = C_LCL(M,N,KJ)                                    
           END DO
          END DO
          CYCLE                                                           
         END IF
         DO  M=1,3                                                           
          DO  N=1,3                                                          
           C_LCL(N,M,JK) =   C_LCL(N,M,JK)
     &                     - C_LCL(N,1,JI) * C_LCL(1,M,IK)                   
     &                     - C_LCL(N,2,JI) * C_LCL(2,M,IK)                   
     &                     - C_LCL(N,3,JI) * C_LCL(3,M,IK)                   
          END DO
         END DO
   30   CONTINUE                                                            
        IF  ( KI .NE. I_0 )   THEN                                    
         DO  N=1,3                                                           
          R(N,K) = R(N,K) - C_LCL(N,1,KI) * R(1,I)                           
     &                    - C_LCL(N,2,KI) * R(2,I)                           
     &                    - C_LCL(N,3,KI) * R(3,I)                           
         END DO
        END IF
   40  CONTINUE                                                            
   50 CONTINUE                                                            
!C                                                                        
!C    Backdown solution                                                   
!C                                                                        
      IF  ( MM .NE. I_1 )  THEN                                        
       DO  J=1,MM1                                                        
        IP = J + I_1                                                    
        DO  I=IP,MM                                                       
         IF  ( NN_LCL(I,J) .EQ. I_0 )  CYCLE                           
         IJ_LCL = NN_LCL(I,J)                                             
         DO  N=1,3                                                        
          R(N,I) = R(N,I) - C_LCL(N,1,IJ_LCL) * R(1,J)                    
     &                    - C_LCL(N,2,IJ_LCL) * R(2,J)                    
     &                    - C_LCL(N,3,IJ_LCL) * R(3,J)                    
         END DO
        END DO                                                            
       END DO                                                             
      END IF
!C
      CALL ELTIME ( I_2, I_20 )                                               
!C
      RETURN                                                              
      END                                                                 
      