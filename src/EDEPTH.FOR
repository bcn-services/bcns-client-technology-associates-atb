      SUBROUTINE EDEPTH ( A, B_LCL, XM, T, Y_LCL, XA, XB, XL, XU )        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Determines XA and XB, the points of maximum penetration of two      
!C     intersecting ellipsoids A and B.                                    
!C    Arguments A, B, XM, T and X same as for Subroutine INTERS.            
!C    Arguments XL and XU, If nonzero, are final results of last call.    
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       EPS,                                    ! /CNSNTS/
     &       NPRT,                                   ! /CONTRL/
     &       INTEGER_STD, IREAL_HIGH, LUAOU,         ! parameters
     &       D_0, D_1, D_2, I_0, I_1, I_3, I_50      ! parameter
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, ITER, J
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  C11, C12, C13, C21, C22, C23, D1, D2, D3, 
     &                  DET, DL, DU, T, XL, XU, XLAU,
     &                  A, B_LCL, XM, Y_LCL, XA, XB,
     &                  C1_LCL, C2, C3, XBM, PXBL, PXAU, AB_LCL,
     &                  AXA, BXBM, PXAL, PXBU
      DIMENSION   A(3,3), B_LCL(3,3), XM(3), Y_LCL(3), XA(3), XB(3),      
     &            C1_LCL(3,4), C2(3,4), C3(3,4), XBM(3), PXBL(3),
     &            PXAU(3), AB_LCL(3,3), AXA(3), BXBM(3), 
     &            PXAL(3), PXBU(3)                                        
!C
      EQUIVALENCE ( XBM(1), C1_LCL(1,4) ),
     &            ( PXBL(1), C2(1,4) ), ( PXAU(1), C3(1,4) )              
!C                                                                        
!C                                   Initial guesses                      
!C                                   XA = Y / T                             
!C                                   XB = M + ( Y - M ) / T                       
!C                                   L = -! XB - XA ! / ! AXA !                   
!C                                   U = -! XB - XA ! / ! B( XB - M ) !               
!C                                                                        
      D1 = D_0                                                          
      D2 = D_0                                                         
      DO  I=1,3                                                           
       XA(I) = Y_LCL(I) / T                                               
       XBM(I) = ( Y_LCL(I) - XM(I) ) / T                                  
       XB (I) = XBM(I) + XM(I)                                            
       D1 = D1 + ( XB(I) - XA(I) )**2                                     
      END DO
      IF ( ABS ( T - D_1 ) .LE. EPS(6) )  RETURN                          
      CALL MAT33 ( A, B_LCL, AB_LCL )                                     
      IF  ( ( XL .EQ. D_0 )  .AND.                                     
     &      ( XU .EQ. D_0 ) )  THEN                                    
       D3 = D_0                                                        
       DO  I=1,3                                                          
        AXA(I) =   A(I,1) * XA(1)                                         
     &            + A(I,2) * XA(2)                                        
     &            + A(I,3) * XA(3)                                        
        D2 = D2 + AXA(I)**2                                               
        BXBM(I) =   B_LCL(I,1) * XBM(1)                                   
     &            + B_LCL(I,2) * XBM(2)                                   
     &            + B_LCL(I,3) * XBM(3)                                   
        D3 = D3 + BXBM(I)**2                                              
       END DO
       XL = -SQRT ( D1 / D2 )                                             
       XU = -SQRT ( D1 / D3 )                                             
      END IF
!C                                                                        
!C    Iterate                
!C                                                                        
      ITER = I_0                                                       
      DO
       ITER = ITER + I_1                                             
       IF ( NPRT(17) .NE. I_0 )  THEN
        WRITE ( LUAOU, 110 ) ITER, XL, XU, XA, XB  
  110   FORMAT ( ' EDEPTH ITER', I6, 8G14.6 )                              
       END IF
       IF ( ITER .GT. I_50 )  THEN                            
        WRITE ( LUAOU, 120 )                                               
  120   FORMAT( ' EDEPTH iteration did not converge' )                     
        RETURN                                                             
       END IF
!C                                                                         
!C     Form matrices                     
!C          C1 = LUAB + LA + UB                 
!C          C2 = C1                           
!C          C3 = C1'                           
!C                                                                        
       XLAU = XU * XL                                                      
       DO  I=1,3                                                           
        XBM(I) = D_0                                                     
        DO  J=1,3                                                          
         C1_LCL(I,J) = XLAU * AB_LCL(I,J) + XL * A(I,J) 
     &                                    + XU * B_LCL(I,J)   
         C2(I,J)     = C1_LCL(I,J)                                         
         C3(J,I)     = C1_LCL(I,J)                                         
         XBM(I) = XBM(I) - XL * A(I,J) * XM(J)                             
        END DO
       END DO
!C                                                                         
!C     Solve for ( XB - M )                  
!C      C1( XB - M ) = -LAM                  
!C                                                                        
       CALL DSMSOL ( C1_LCL, 3 )                                           
!C                                                                        
!C     Evaluate                          
!C       XB = ( XB - M ) + M                      
!C       B( XB - M )                          
!C       AXA                              
!C       C13 = ( 1 - XA'AXA ) / 2                
!C       C23 = ( 1 - ( XB - M )'B( XB - M ) ) / 2        
!C                                                                         
       C13 = D_0                                                         
       C23 = D_0                                                         
       DO  I=1,3                                                           
        XB(I) = XBM(I) + XM(I)                                             
        BXBM(I) =   B_LCL(I,1) * XBM(1)                                    
     &            + B_LCL(I,2) * XBM(2)                                    
     &            + B_LCL(I,3) * XBM(3)                                    
        XA(I) = XB(I) + XU * BXBM(I)                                       
       END DO
       DO  I=1,3                                                           
        AXA(I) =   A(I,1) * XA(1)                                          
     &           + A(I,2) * XA(2)                                          
     &           + A(I,3) * XA(3)                                          
        C13 = C13 + XA(I)  * AXA(I)                                        
        C23 = C23 + XBM(I) * BXBM(I)                                       
        PXBL(I) = -AXA(I)                                                  
       END DO
       C13 = ( D_1 - C13 ) / D_2                                         
       C23 = ( D_1 - C23 ) / D_2                                       
!C        *         DXB                    
!C        Solve for ---                      
!C        *         DL                       
!C                                                                         
!C        * DXB                             
!C        C2--- = -AXA                       
!C        * DL                              
!C                                                                         
       CALL DSMSOL ( C2, I_3 )                                     
!C                                                                         
!C      Calculate                         
!C      DXA   DXB     DXB                  
!C      --- = --- + UB---                 
!C      DL    DL      DL                
!C                                                                         
!C       *         DXA                      
!C       C11 = XA'A---                     
!C       *         DL                      
!C                                                                         
!C       *             DXB                
!C       C21 = (XB-M)'B---                
!C       *             DL                  
!C                                                                         
       C11 = D_0                                                       
       C21 = D_0                                                       
       DO  I=1,3                                                           
        PXAL(I) =   B_LCL(I,1) * PXBL(1)                                   
     &            + B_LCL(I,2) * PXBL(2)                                   
     &            + B_LCL(I,3) * PXBL(3)                                   
        PXAL(I) = PXBL(I) + XU * PXAL(I)                                   
        C11 = C11 + AXA(I)  * PXAL(I)                                      
        C21 = C21 + BXBM(I) * PXBL(I)                                      
        PXAU(I) = -BXBM(I)                                                 
       END DO
!C                                                                          
!C      *         DXA                      
!C      Solve for ---                    
!C      *         DU                      
!C                                                                         
!C      * DXA                              
!C      C3--- = -B(XB-M)                
!C      * DU                             
!C                                                                         
       CALL DSMSOL ( C3, 3 )                                               
!C                                                                         
!C      Calculate                         
!C      DXB   DXA     DXA                  
!C      --- = --- + LA---                 
!C      DU    DU      DU                  
!C                                                                         
!C      *         DXA                      
!C      C12 = XA'A---                       
!C      *         DU                       
!C                                                                         
!C      *             DXB                 
!C      C22 = (XB-M)'B---                  
!C      *             DU                   
!C                                                                         
       C12 = D_0                                                          
       C22 = D_0                                                          
       DO  I=1,3                                                           
        PXBU(I) = PXAU(I) + XL *
     &        ( A(I,1) * PXAU(1) + A(I,2) * PXAU(2) + A(I,3) * PXAU(3) )   
        C12 = C12 + AXA(I)*PXAU(I)                                         
        C22 = C22 + BXBM(I)*PXBU(I)                                        
       END DO
!C                                                                         
!C      Solve for DL and DU                
!C      C11 * DL + C12 * DU = C13              
!C      C21 * DL + C22 * DU = C23               
!C                                                                         
       DET =  C11 * C22 - C12 * C21                                        
       DL = ( C13 * C22 - C12 * C23 ) / DET                                
       DU = ( C11 * C23 - C13 * C21 ) / DET                                
!C                                                                         
!C      Increment L and U                  
!C      Test for convergence            
!C                                                                         
       XL = XL + DL                                                        
       XU = XU + DU                                                        
       IF ( ABS ( DL / XL ) .LE. EPS(12) )  EXIT                       
       IF ( ABS ( DU / XU ) .LE. EPS(12) )  EXIT                       
      END DO
! C
      RETURN                                                              
      END                                                                 
