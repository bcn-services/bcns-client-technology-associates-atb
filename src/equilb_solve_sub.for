      SUBROUTINE  EQUILB_SOLVE_SUB ( I1, I2, IAV, J, NAV, NTV, X, 
     &                               DPN, XDEV, SX, IYPR, YPR )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This subroutine was created from Subroutine	EQUILB_SOLVE
!C     to improve the coding appearance and is called only by
!C     Subroutine	EQUILB_SOLVE.
!C
!C
      USE  MODULE_STANDARD,  ONLY:  
     &       HT,                                            ! /DESCRP/
     &       SEG,                                           ! structures
     &       INTEGER_STD, IREAL_HIGH,                       ! parameters
     &       LUAOU, MAXSEG,                                 ! parameters
     &       I_0, I_1, I_2, D_0                             ! parameters
!C
!C    LIN_DISP         ! SEG%
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &           I1, I2, IAV, J, J2, K 
      INTEGER  ( KIND = INTEGER_STD )
     &           IYPR, NTV, NAV, KSGE 
      DIMENSION  IYPR(4, MAXSEG), NTV(10), NAV(10), KSGE(5,10)          
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  YPR, X, DPN, XDEV, SX
      DIMENSION  YPR(3,MAXSEG), X(10),  DPN(5,10), XDEV(10), SX(10)            
!C                                                                        
      INTENT (    IN )  I1, I2, IAV, J, NAV, NTV, X, DPN, 
     &                  XDEV, SX, IYPR
      INTENT ( INOUT )  YPR
!C

      IF  ( XDEV(J) .GT. D_0 )  THEN                           
       IF  ( ABS ( X(J) - SX(J) ) .GT. XDEV(J) )  THEN              
        WRITE  ( LUAOU, 100 )  J, X(J), SX(J), XDEV(J)                    
  100   FORMAT ( '0 Program is being terminated in Subroutine',
     &           'EQUILB_SOLVE_SUB.', //, 
     &           '  Iteration for variable no.' 
     &           ,I3, ' is not converging.', //,  
     &           '  Value of X is out of range. Values of X,SX,',
     &           'XDEV are', //, 3G20.8 )                             
        STOP 'STOP 27 in Subroutine EQUILB_SOLVE_SUB '                                                          
       END IF
      END IF
!C
      IF  ( NTV(J) .EQ. I_1 )  THEN
       SEG(I2)%LIN_DISP(I1) = X(J)         
      ELSE
       YPR(I1,I2) = X(J)                  
       CALL DRCIJK ( YPR, IYPR, HT, I2 )   
      END IF
!C
      IF  ( NAV(J) .LE. I_0 )  RETURN                           
!C
      DO  K=1,IAV                                                     
       J2 = KSGE(K,J)                                                  
       IF       ( NTV(J) .EQ. I_1 )  THEN
        SEG(J2)%LIN_DISP(I1) = X(J) - DPN(K,J)    
       ELSE IF  ( NTV(J) .EQ. I_2 )  THEN   
        YPR(I1,J2) = X(J) - DPN(K,J)                                   
        CALL DRCIJK ( YPR, IYPR, HT, J2 )  
       END IF
      END DO
!C
      RETURN
      END