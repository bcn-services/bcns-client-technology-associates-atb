      SUBROUTINE FSMSOL_STOP ( JN, MAXDIM, MAXN, MM, NN_LCL, C_LCL, R )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine is called by Subroutine FSMSOL if the set of
!C     equations exceeds the size of the maximum size of the 
!C     array used by the program for the solution.
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       NPG,                                   ! /CONTRL/
     &       INTEGER_STD, IREAL_HIGH, LUAOU, I_1    ! parameter
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, JN, K, L, MAXDIM, MAXN, MM,  NN_LCL
      DIMENSION  NN_LCL(JN,JN)
!C
      REAL  ( KIND = IREAL_HIGH )  C_LCL, R
      DIMENSION         C_LCL(3,3,MAXDIM), R(3,JN)                         
!C
      INTENT ( IN )  JN, MAXDIM, MAXN, MM, NN_LCL, C_LCL, R
!C
!C
      WRITE  ( LUAOU, 100 )  MAXDIM, NPG, ( L, L=1,MM )                      
  100 FORMAT ( '1 Maximum dimension of',I4,
     &         ' on C array has been exceeded',  
     &         ' in Subroutine FSMSOL.', 46X, 'Page', I5, //,
     &         ' If > 200, Call is from Subroutine DAUX. If 200',       
     &         ' call is from Subroutine HPTURB.', //, 
     &         ' Program is being terminated.',
     &         ' Complete print-out of IJK, RHS and C arrays follow.',  
     &         //, ' FSMSOL print of IJK matrix', //, ( 6X, 40I3 ) )      
!C
      NPG = NPG + I_1                                                    
      DO  I=1,MM                                                          
       WRITE  ( LUAOU, 105 )  I, ( NN_LCL(I,L), L=1,MM )                   
  105  FORMAT ( I3, 3X, 40I3, 3X, /, 6X, 40I3 )                           
      END DO
      WRITE  ( LUAOU, 110 ) NPG                                              
  110 FORMAT ( '1 FSMSOL print of RHS array', 96X, 'Page', I5, // )         
!C
      NPG = NPG + I_1                                                    
!C
      DO  K=1,MM                                                          
       WRITE  ( LUAOU, 115 )  K, ( R(I,K), I=1,3 )                         
  115  FORMAT ( I6, 9G14.7 )                                              
      END DO
!C
      WRITE  ( LUAOU, 120 ) NPG                                              
  120 FORMAT ( '1 FSMSOL print of C array elements', 89X,
     &         'Page', I5, // )                                             
      NPG = NPG + I_1                                                    
      DO  K=1,MAXN                                                        
       WRITE  ( LUAOU, 135 )   K, ( ( C_LCL(I,L,K), L=1,3 ), I=1,3 )       
  135  FORMAT ( I6, 9G14.7 )                                              
      END DO
      STOP 35                                                             
!C
      RETURN
      END 