      SUBROUTINE DAUX22                                                   
!C
!C                                                 Rev. V.3 12/15/2002 
!C
!C     Called by Subroutine DAUX to compute                               
!C                                                                        
!C                                                                        
!C                           -1                                           
!C         (C22) = (B22)(PHI)  (A22) - (B24)                              
!C                                                                        
!C                           -1                                           
!C         (R2)  = (B22)(PHI)  (U2)  - (V2)                               
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:  
     &       IEULER,                                            ! /CEULER/
     &       V2,                                                ! /CMATRX/
     &       NJNT,                                              ! /CONTRL/
     &       RHS, NQ2S, IJ, IJK,                                ! /DAUX_TEMPVS/
     &       JNT,                                               ! structures
     &       INTEGER_STD, IREAL_HIGH, LOGICAL_STD,              ! parameters
     &       TRUE, FALSE,                                       ! parameters
     &       D_0, I_0, I_1, I_2, I_3, I_4, I_5, I_6, I_7,       ! parameters
     &       I_8, I_9, I_10, I_11, I_12, I_13, I_14, I_15, I_16 ! parameters
!C
!C    PROX_SEG, SLIP_FREE, JTYPE     ! JNT%
!C
      USE  MODULE_FLEXIBLE,  ONLY:  NFBOD, IBODN   ! /FXVAR/
!C
      IMPLICIT  NONE
!C
!C     Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )
     &         I, II, LGO,  M, MB, MJNT, N, NB, NQSJNT
!C
      REAL  ( KIND = IREAL_HIGH )   HH 
      DIMENSION                     HH(3,3)                                 
!C
      LOGICAL  ( KIND = LOGICAL_STD )  MFLG, NFLG, TEST, SKIP                 
!C
      CALL ELTIME ( I_1, I_16 )                                               
!C
      NQSJNT = NQ2S + NJNT                                                
      DO 20 M=1,NJNT                                                      
       MJNT = NQSJNT + M                                                   
       DO  I=1,3                                                           
        RHS(I,MJNT) = V2(I,M)                                              
       END DO
       N = ABS ( JNT(M)%PROX_SEG )                                       
       IF ( N .EQ. I_0 )  CYCLE                                        
!C
!C     Check to see if N and M+1 are deformable.                         
!C
       NFLG = FALSE                                                 
       MFLG = FALSE                                                 
       IF ( NFBOD .NE. I_0 )  THEN                                  
        DO  II=1,NFBOD                                                   
         IF ( IBODN(II) .EQ. N )  THEN                                   
          NFLG = TRUE                                               
          NB = II                                                        
         ELSE IF ( IBODN(II) .EQ. ( M + I_1 ) ) THEN                  
          MFLG = TRUE                                               
          MB = II                                                        
         END IF                                                          
        END DO                                                           
       END IF
       IF ( JNT(M)%SLIP_FREE )  CYCLE                                      
       IJ = IJ + I_1                                                     
       IJK(MJNT,MJNT) = IJ                                               
       HH = D_0                                                        
       LGO = JNT(M)%JTYPE + I_8                                                
       TEST = FALSE                                                     
       IF ( ( LGO .EQ.  I_1 )  .OR. ( LGO .EQ.  I_2 ) .OR.
     &      ( LGO .EQ.  I_3 )  .OR. ( LGO .EQ.  I_5 ) .OR.
     &      ( LGO .EQ.  I_6 )  .OR. ( LGO .EQ.  I_7 ) .OR.
     &      ( LGO. EQ.  I_8 )  .OR. ( LGO .EQ. I_10 ) .OR.
     &      ( LGO .EQ. I_11 )  .OR. ( LGO .EQ. I_12 ) .OR.
     &      ( LGO .EQ. I_13 ) )  THEN
        SKIP = TRUE
       ELSE IF  ( LGO .EQ. I_4 )  THEN
        IF ( IEULER(M) .GE. I_7 )  THEN
         SKIP = TRUE
        ELSE
         TEST = IEULER(M) .LT. I_4                                       
         SKIP = FALSE
        END IF
       ELSE IF  ( ( LGO .EQ.  I_9  ) .OR. 
     &            ( LGO .EQ.  I_14 ) .OR.
     &            ( LGO .EQ.  I_15 ) )  THEN  
        SKIP = FALSE
       ELSE 
        IF ( IEULER(M) .GE. I_7 )  THEN
         SKIP = TRUE
        ELSE
         TEST = IEULER(M) .LT. I_4                                       
         SKIP = FALSE
        END IF
       END IF
       CALL DAUX22_SUB ( M, MB, MJNT, MFLG, N, NB, NFLG, NQSJNT,
     &                        SKIP, TEST,  HH )                                                  
   20 CONTINUE                                                            
!C
      CALL ELTIME ( I_2, I_16 )                                               
!C
      RETURN                                                              
      END                                                                 
