      SUBROUTINE ADJUST ( M )                                           
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY: 
     &        UU, GH, GG, U, H, Y,                    ! /CDINT/
     &        VAR, DER, NEQ,                          ! /COMAIN/
     &        EPS,                                    ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH,                ! parameters
     &        I_0, I_1, I_2, I_3, I_5, D_0, D_HALF    ! parameters
!C            
      USE  MODULE_FLEXIBLE,  ONLY: NEQP,                 ! /FXINT/
     &                             NFBOD                 ! /FXVAR/
!C
      IMPLICIT  NONE
!C
!C    Local variables
!C
      INTEGER  ( KIND = INTEGER_STD ) I, M, N2, NEQP1
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  VARX, VARY, VARZ, Y1, Y2, Y3, Z, ZA, ZZ,
     &                  DERX, DERY, DERZ, H1, U3ABS, U4ABS, W1          
!C
      IF  ( M .EQ. I_1 )  THEN                                          
!C                                                                        
!C     M = 1:                                                             
!C                                                                        
       DO  I=1,NEQ                                                        
        W1 = VAR(I) - GG(1,I)                                           
        Z = DER(I) - GG(2,I)                                              
        ZZ = Z - GG(5,I) * W1 - GG(3,I) * UU(3) - GG(4,I) * UU(4)       
        GG(3,I) = GG(3,I) + ZZ * UU(1)                                    
        GG(4,I) = GG(4,I) + ZZ * UU(2)                                    
        Y(1,I) = VAR(I)                                                   
        Y(2,I) = DER(I)                                                   
       END DO
       RETURN                                                            
      END IF
      IF  ( M .EQ. I_3 )  THEN                                       
       DO  I=1,NEQ                                                        
        ZA = GG(5,I)                                                      
        Y1 = GG(2,I) - ZA * GG(1,I)                                      
        Y2 = Y(2,I)  - ZA * Y(1,I)                                       
        Y3 = DER(I)  - ZA * VAR(I)                                        
        GG(3,I) = -Y1 * GH(1,3) + Y2 * GH(2,3) - Y3 * GH(3,3)             
        GG(4,I) =  Y1 * GH(1,4) - Y2 * GH(2,4) + Y3 * GH(3,4)             
        U(1,I) = VAR(I)                                                   
        U(2,I) = DER(I)                                                   
       END DO
       RETURN                                                             
      END IF
!C                                                                        
!C    M = 2,4,5:                                                          
!C                                                                        
      H1 = EPS(1) / H                                                     
!C
!C    NEQP, instead of NEQ, is used to                                  
!C    exclude the deformation modes from rigid body motion adjustment   
!C
      N2 = NEQP / I_2                                                   
      DO  20  I=1,NEQP,3                                                  
       ZA = D_0                                             
       IF  ( I .LE. N2 )  CYCLE                                           
       IF  ( M .EQ. 4 )   THEN                                            
        VARX = VAR(I  ) - U(1,I  )                                        
        VARY = VAR(I+1) - U(1,I+1)                                        
        VARZ = VAR(I+2) - U(1,I+2)                                        
        DERX = DER(I  ) - U(2,I  )                                       
        DERY = DER(I+1) - U(2,I+1)                                        
        DERZ = DER(I+2) - U(2,I+2)                                        
       ELSE
        VARX = VAR(I  ) - Y(1,I  )                                        
        VARY = VAR(I+1) - Y(1,I+1)                                        
        VARZ = VAR(I+2) - Y(1,I+2)                                        
        DERX = DER(I  ) - Y(2,I  )                                        
        DERY = DER(I+1) - Y(2,I+1)                                        
        DERZ = DER(I+2) - Y(2,I+2)                                       
       END IF
       U(3,I) = U(3,I) + VARX * DERX + VARY * DERY + VARZ * DERZ          
       U(4,I) = U(4,I) + VARX**2 + VARY**2 + VARZ**2                      
       U3ABS = ABS ( U(3,I) )                                             
       U4ABS = ABS ( U(4,I) )                                             
       IF ( U3ABS .LT. EPS(24) )  U(3,I) = D_0                       
       IF ( U4ABS .LT. EPS(24) ) THEN                                     
        U(4,I) = D_0                                                
        GG(5,I+2) = ZA                                                   
        GG(5,I+1) = ZA                                                   
        GG(5,I  ) = ZA                                                    
        CYCLE
       END IF                                                            
       ZA = H1                                                            
       IF ( U(3,I) .LT.( H1 * U(4,I) ) )  ZA = U(3,I) / U(4,I)            
       GG(5,I+2) = ZA                                                     
       GG(5,I+1) = ZA                                                     
       GG(5,I  ) = ZA                                                     
  20  CONTINUE
!C                                                                      
!C    Perform deformation mode ajustment                                
!C
      IF ( NFBOD .NE. I_0 )  THEN                                    
       NEQP1 = 1 + ( NEQ + NEQP ) / I_2                              
       DO  I=NEQP1,NEQ                                                  
        ZA = D_0                                                    
        IF ( M .EQ. 4 ) THEN                                            
         VARX = VAR(I) - U(1,I)                                         
         DERX = DER(I) - U(2,I)                                         
        ELSE
         VARX = VAR(I) - Y(1,I)                                         
         DERX = DER(I) - Y(2,I)                                         
        END IF
        U(3,I) = U(3,I) + VARX * DERX                                   
        U(4,I) = U(4,I) + VARX**2                                       
        IF ( U(4,I) .NE. D_0 )  THEN                                  
         ZA = H1                                                        
         IF ( U(3,I) .LT. ( H1 * U(4,I) ) )  ZA = U(3,I) / U(4,I)        
        END IF
        GG(5,I) = ZA                                                    
       END DO                                                           
      END IF                                                            
!C                                                                      
      IF ( M .EQ. I_1 )  THEN
       CONTINUE
      ELSE IF ( M .EQ. I_2 )  THEN
!C                                                                        
!C     M = 2:                                                             
!C                                                                        
       DO  I=1,NEQ                                                        
        ZA = GG(5,I)                                                      
        Y1 = Y(4,I)  - ZA * Y(3,I)                                       
        Y2 = GG(2,I) - ZA * GG(1,I)                                       
        Y3 = DER(I)  - ZA * VAR(I)                                       
        GG(3,I) = -Y1 * GH(1,1) + Y2 * GH(2,1) + Y3 * GH(3,1)             
        GG(4,I) =  Y1 * GH(1,2) - Y2 * GH(2,2) + Y3 * GH(3,2)             
        Y(1,I) = D_HALF * ( Y(1,I) + VAR(I) )                              
        Y(2,I) = D_HALF * ( Y(2,I) + DER(I) )                               
       END DO
      ELSE IF ( M .EQ. 3 )  THEN
       CONTINUE
      ELSE IF ( M .EQ. 4 )  THEN
!C                                                                        
!C     M = 3,4:                                                           
!C                                                                        
       DO  I=1,NEQ                                                        
        ZA = GG(5,I)                                                      
        Y1 = GG(2,I) - ZA*GG(1,I)                                         
        Y2 = Y(2,I)  - ZA*Y(1,I)                                          
        Y3 = DER(I)  - ZA*VAR(I)                                          
        GG(3,I) = -Y1*GH(1,3) + Y2*GH(2,3) - Y3*GH(3,3)                   
        GG(4,I) =  Y1*GH(1,4) - Y2*GH(2,4) + Y3*GH(3,4)                   
        U(1,I) = VAR(I)                                                   
        U(2,I) = DER(I)                                                   
       END DO
      ELSE IF ( M .EQ. I_5 )  THEN
!C                                                                        
!C     M = 5:                                                             
!C                                                                        
       DO  I=1,NEQ                                                        
        ZA = GG(5,I)                                                      
        Y1 = GG(2,I) - ZA*GG(1,I)                                         
        Y2 = DER(I)  - ZA*VAR(I)                                         
        Y3 = U(2,I)  - ZA*U(1,I)                                          
        GG(3,I) = -Y1*GH(1,3) + Y2*GH(2,3) - Y3*GH(3,3)                   
        GG(4,I) =  Y1*GH(1,4) - Y2*GH(2,4) + Y3*GH(3,4)                   
        Y(1,I) = VAR(I)                                                   
        Y(2,I) = DER(I)                                                   
       END DO
      END IF
!C
      RETURN                                                              
      END                                                                
