      SUBROUTINE  DINTG_HALF ( K, CONVERGE )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY: 
     &       ICNT, IDBL, H, HPRINT,  TSTART,           ! /CDINT/
     &       EPS,                                      ! /CNSNTS/
     &       HMIN,                                     ! /COMAIN/
     &       TIME, NPRT,                               ! /CONTRL/
     &       INTEGER_STD, LUTERM_OUT,                  ! parameters
     &       LOGICAL_STD, LUAOU, TRUE, FALSE,          ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_6, D_HALF ! parameters
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )  K
!C
      LOGICAL ( KIND = LOGICAL_STD )  CONVERGE                             
!
      INTENT  (   OUT )  CONVERGE
      INTENT  ( INOUT )  K
!C
      WRITE  ( LUAOU, 100 )   TIME, H                                         
  100 FORMAT ( '0 Test failed at time = ', F10.6, ' for H = ', F10.6 )  
!C
      ICNT = I_0                                                    
      IDBL = IDBL + I_2                                             
      IF  ( IDBL .GT. I_6 )  IDBL = I_6                            
      IF  ( K .LT. I_0 )  THEN                                       
       IF  ( H .GT. ( HMIN + EPS(8) ) )   THEN                      
        TIME = TSTART                                                     
        H = D_HALF * H                                                     
        HPRINT = D_HALF * HPRINT                                            
        K = I_2                                                         
        CONVERGE = FALSE
        RETURN       
       ELSE
        WRITE  ( LUTERM_OUT, 105 )                                              
        WRITE  ( LUAOU, 105 )                                              
  105   FORMAT ( '0 Program terminated. PDAUX neg sqrt.',
     &           ' H < HMIN+EPS8.', /,   
     &           '  Rerun program with smaller HMIN on input Card A.4' ) 
        STOP 'STOP 31 in Subroutine DINTG_HALF'                                                          
       END IF
      END IF
!C
      IF  ( H .LE. ( HMIN + EPS(8) ) )  THEN
       CONVERGE = TRUE
      ELSE
       CONVERGE = FALSE
       IF  ( NPRT(26) .EQ. I_2 )  CALL OUTPUT ( I_1 )                  
       TIME = TSTART                                                     
       H = D_HALF * H                                                     
       HPRINT = D_HALF * HPRINT                                            
       K = I_2                                                         
      END IF
!C
      RETURN
      END