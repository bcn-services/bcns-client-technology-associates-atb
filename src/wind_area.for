      SUBROUTINE  WIND_AREA ( BET_LCL, BTE_LCL, BTS, FT, LOGI_RETURN,
     &                        M, MM, P, RM, TM, TQM, TTF )
!C
!C                                                   Rev. V.3 12/15/2002 
!C                                                                        
!C    This subroutine computes the wind force as the total area
!C     presented to the wind.
!C                                                                      
!C    This subroutine is called only by Subroutine WINDY.
!C
      USE  MODULE_STANDARD,  ONLY:
     &       PI,                              ! /CNSNTS/
     &       BD,                              ! /CNTSRF/
     &       NPRT, TIME,                      ! /CONTRL/
     &       SEG,                             ! structures
     &       INTEGER_STD, IREAL_HIGH,         ! parameters
     &       LOGICAL_STD, LUAOU, FALSE, TRUE, ! parameters
     &       I_0, D_0, D_1                    ! parameters
!C
!C    SEG%DIR_COS
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )  I, M, MM
!C
      REAL  ( KIND = IREAL_HIGH )  
     &              AF, AREA_LCL, BET_LCL, BREF, BTE_LCL, BTS,
     &              FAF, FF_LCL, FT, P, RLM, RM,  
     &              SCALE_LCL, TEMP, TF, TM, TRACER, TQM, TTF
      DIMENSION     AF(3), FF_LCL(3), FT(3), RLM(3), RM(3), TM(3),
     &              TQM(3), TTF(3)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LOGI_RETURN
!C
      INTENT  (    IN )  BET_LCL, BTE_LCL, BTS, M, MM, P, RM, TM
      INTENT  (   OUT )  LOGI_RETURN, TQM, TTF
      INTENT  ( INOUT )  FT
!C
      LOGI_RETURN = FALSE
      TTF = D_0
      CALL MAT31 ( SEG(M)%DIR_COS, FT, FF_LCL )                                 
      CALL MAT31 ( BD(7,MM), FF_LCL, AF )                               
      FAF = DOT_PRODUCT ( FF_LCL, AF )
      IF ( FAF .LE. D_0 )  THEN
       LOGI_RETURN = TRUE
       RETURN
      END IF
      TF = DOT_PRODUCT ( TM, FF_LCL )
      BREF = D_0                                                         
      TEMP = BTS - TF * TF / FAF                                        
      IF ( TEMP .GT. D_0 )   BREF = SQRT ( TEMP )                      
      SCALE_LCL = ( -BET_LCL + BREF ) / ( -BTE_LCL + BREF )            
      IF ( SCALE_LCL .GE. D_1 )  THEN
       LOGI_RETURN = TRUE
       RETURN
      ELSE IF ( SCALE_LCL .LT. D_0 )  THEN
       SCALE_LCL = D_0                                                 
      END IF                          
      TRACER =   ( BD( 7,MM) - AF(1)**2 / FAF )
     &         * ( BD(11,MM) - AF(2)**2 / FAF )                          
     &         + ( BD( 7,MM) - AF(1)**2 / FAF )
     &         * ( BD(15,MM) - AF(3)**2 / FAF )                          
     &         + ( BD(11,MM) - AF(2)**2 / FAF )
     &         * ( BD(15,MM) - AF(3)**2 / FAF )                          
     &         - ( BD( 8,MM) - AF(1) * AF(2) / FAF )**2                 
     &         - ( BD( 9,MM) - AF(1) * AF(3) / FAF )**2                   
     &         - ( BD(12,MM) - AF(2) * AF(3) / FAF )**2                 
      AREA_LCL = ( D_1 - SCALE_LCL**2 ) * PI / SQRT ( TRACER )           
!C                                                                        
!C    Compute force and torques to add to U1 and U2 arrays for segment M.          
!C                                                                       
      SCALE_LCL = SCALE_LCL / BTE_LCL                                    
      DO  I=1,3                                                         
       RLM(I) = RM(I) * SCALE_LCL + BD(I+3,MM)                          
      END DO
      FT     = FT * AREA_LCL                                         
      FF_LCL = FF_LCL * AREA_LCL                                 
      CALL CROSS ( RLM, FF_LCL, TQM )                                  
!C
!C    Add to the nodal forces for deformable body M                 
!C
      CALL FXCAHW ( M, RLM, FT, D_1 )                                 
!C
!C    Print out optional debugging output.
!C
      IF ( NPRT(14) .NE. I_0 )  THEN
       WRITE ( LUAOU, 110 ) TIME, M, P, AREA_LCL, FT, TQM                
  110  FORMAT ( ' Wind Force', F14.6, I6, 2F10.3, 3X, 3F12.5, 
     &          3X, 3F12.5 )                                             
      END IF
!C
      TTF = FT
!C
      RETURN
      END
