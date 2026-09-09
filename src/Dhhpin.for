      SUBROUTINE DHHPIN ( DD, BN, L, M, HB_LCL )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Sets DD = D(L) if joint M is not pinned                             
!C      or DD = (I-HH.)(D(L)) if pinned                                   
!C
!C    Arguments:
!C         DD     = 
!C         BN     = 
!C         L      =  segment number
!C         M      =  joint number
!C         HB_LCL =  joint HB vector
!C                                                            
      USE  MODULE_STANDARD,  ONLY:      
     &       IEULER,                                   ! /CEULER/
     &       SEG, JNT,                                 ! structures
     &       INTEGER_STD, IREAL_HIGH, D_0, D_1,        ! parameters
     &       I_1, I_2, I_3, I_4, I_5, I_6, I_7, I_8,   ! parameters
     &       I_9, I_10, I_11, I_12, I_13, I_14, I_15   ! parameters
!C
!C    DIR_COS          %SEG
!C    JTYPE            %JNT
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  I, J, L, LGO, M
!C
      REAL  ( KIND = IREAL_HIGH )   BN,  DD, HB_LCL, TSIGN
      DIMENSION  DD(3,3), BN(3), HB_LCL(3)                                        
!C
      INTENT (  IN )  L, M, HB_LCL
      INTENT ( OUT )  DD, BN
!C
      BN = D_0
      DD = SEG(L)%DIR_COS                                     
      LGO = JNT(M)%JTYPE + I_8                                                
      TSIGN = -D_1                                                       
!C
      IF ( ( LGO .EQ.  I_1 )   .OR. ( LGO .EQ.  I_2 ) .OR. 
     &     ( LGO .EQ.  I_3 )   .OR. ( LGO .EQ.  I_5 ) .OR.
     &     ( LGO .EQ.  I_6 )   .OR. ( LGO .EQ.  I_7 ) .OR.
     &     ( LGO .EQ.  I_8 )   .OR. ( LGO .EQ. I_10 ) .OR.
     &     ( LGO .EQ.  I_11 )  .OR. ( LGO .EQ. I_12 ) .OR.
     &     ( LGO .EQ.  I_13 ) )  THEN
       RETURN 
      ELSE IF ( LGO .EQ. I_4 )  THEN
       IF ( IEULER(M) .GE. I_7 )  RETURN                             
       IF ( IEULER(M) .LT. I_4 )  THEN                               
        TSIGN = D_1                                                      
        DD = D_0
       END IF
!C
       DO  J=1,3                                                    
        BN(J) =   HB_LCL(1) * SEG(L)%DIR_COS(1,J) 
     &          + HB_LCL(2) * SEG(L)%DIR_COS(2,J)
     &          + HB_LCL(3) * SEG(L)%DIR_COS(3,J)                  
        DO  I=1,3                                                   
         DD(I,J) = DD(I,J) + TSIGN * BN(J) * HB_LCL(I)                     
        END DO
       END DO
       RETURN
      ELSE IF ( ( LGO .EQ. I_9 ) .OR. ( LGO .EQ. I_14 ) 
     &                           .OR. ( LGO .EQ. I_15 ) )  THEN
       DO  J=1,3                                                       
        BN(J) =   HB_LCL(1) * SEG(L)%DIR_COS(1,J) 
     &          + HB_LCL(2) * SEG(L)%DIR_COS(2,J)
     &          + HB_LCL(3) * SEG(L)%DIR_COS(3,J)                
        DO  I=1,3                                                     
         DD(I,J) = DD(I,J) + TSIGN * BN(J) * HB_LCL(I)                    
        END DO
       END DO
       RETURN
      END IF
!C
      RETURN
!C
      END                                                           
