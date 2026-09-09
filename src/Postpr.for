      SUBROUTINE POSTPR ( PRDT )                                          
!C
!C                                                 Rev. V.3   12/15/2002 
!C
!C    This subroutine controls the computation of the HIC values
!C     and/or the outputting of the tabular time histories from
!C     the data that were stored in the Tape8 file.                                 
!C                                                                       
!C    PRDT = the time increment for which the data are to be outputted.
!C
!C                                                                      
      USE  MODULE_STANDARD,  ONLY:
     &       NPG, NPRT, TIME,                                  ! /CONTRL/
     &       INTEGER_STD, IREAL_HIGH, IREAL_STD, LOGICAL_STD,  ! parameters
     &       LUAIN, LUAOU, MXHIC, FALSE, LULIN, LUTERM_OUT,    ! parameters
     &       I_0, I_1, I_2, I_3, I_4, I_5, I_10, I_45, R_0,    ! parameters
     &       AIN_CONVERT, LIN_FLAG                             ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER    ( KIND = INTEGER_STD )   MAXJHD
      PARAMETER  ( MAXJHD = I_10 )                       
!C
      INTEGER  ( KIND = INTEGER_STD )
     &          I, I26, IDBDY, IHIC, ITST1, ITST2, 
     &          J, JDTPTS, JHDATA,
     &          LINES, LOOP, LPP, 
     &          NDPT, NHIC, NLOOP, NPRT4, NPTS, NTTH 
!C
      INTENT ( IN )  PRDT
!C
!C    In following, 10 is max. number of bodies.                         
!C
      DIMENSION  JDTPTS(2), JHDATA(MAXJHD,3)                            
!C
      REAL  ( KIND = IREAL_STD )   SPAN, ZZ, ZM
      REAL  ( KIND = IREAL_HIGH )  PRDT, ZMLG, ZMLT
      ALLOCATABLE  ZZ, ZM, ZMLG, ZMLT
      DIMENSION    ZZ(:,:), ZM(:,:), ZMLG(:,:), ZMLT(:,:)
!C
      LOGICAL  ( KIND = LOGICAL_STD )  LTABH                                
!C
!C    Set the number of lines of data per page, LPP, 
!C     when the tabular time histories are to output
!C     with headings for every page.
!C
      DATA  LPP / I_45 /                       
!C
!C
      CALL ELTIME ( I_1, 36_INTEGER_STD )                                               
!C
      LTABH = FALSE                                                    
      JDTPTS = I_0                                                  
      IDBDY = I_0                                                    
      NPRT4 = ABS ( NPRT(4) )                                             
      LTABH = ( NPRT4 .EQ. I_2 ) .OR. ( NPRT4 .EQ. I_3 )            
      IF ( NPRT(26) .EQ. I_4 ) LTABH = FALSE                          
      IF ( NPRT(26) .GE. I_5 )   THEN
       CALL ELTIME ( I_2, 36_INTEGER_STD )                                               
       RETURN
      END IF 
!C                                                                        
!C    Read input Card H.12 to control computation of HIC, HSI & CSI.      
!C                                                                        
      IF ( LIN_FLAG )  THEN
!C
!C     For list-directed output, have additional cards H.12.b,
!C      one for each of the injury calculations to be performed.
!C
       READ  ( LULIN, * )  NHIC, SPAN, ( JHDATA(1,J), J=1,3 )               
       IF ( NHIC .GT. I_1 ) THEN
        DO I=2,NHIC
         READ  ( LULIN, * )  ( JHDATA(I,J), J=1,3 )               
        END DO
       END IF
      ELSE
       READ  ( LUAIN, 100 )  NHIC, SPAN, 
     &                    ( ( JHDATA(I,J), J=1,3 ), I=1,NHIC )               
  100  FORMAT ( I4, F8.0, 15I4, /, 15I4 )                                
       IF ( AIN_CONVERT )  THEN
!C
!C      For list-directed output, have additional cards H.12.b,
!C       one for each of the injury calculations to be performed.
!C
        WRITE ( LULIN, 105 )  NHIC, SPAN, 
     &                        ( JHDATA(1,J), J=1,3 ), 'Card H.12.a'               
  105   FORMAT ( 1X, I4, 1X, F15.7, 3( I4, 1X ), 1X, A )                               
        IF ( NHIC .GT. I_1 )  THEN
         DO I=2,NHIC
          WRITE ( LULIN, 110 )  ( JHDATA(I,J), J=1,3 ), 'Card H.12.b'               
  110     FORMAT ( 1X, 3 ( I4, 1X ), 1X, A )                              
         END DO
        END IF
       END IF
      END IF
!C
!C    Test the value of NHIC.
!C
      IF ( ( NHIC .LT. I_0 ) .OR. ( NHIC .GT. MAXJHD ) )  THEN
       WRITE ( LUTERM_OUT, 115 ) NHIC
       WRITE ( LUAOU, 115 ) NHIC
  115  FORMAT ( 1X, ' The value supplied for NHIC, ', I4,  
     &          ' is invalid. ' )
       STOP 'STOP 478 in Subroutine POSTPR'
      END IF
!C
!C    Test the value of SPAN.
!C
      IF ( NHIC .GT. I_0 ) THEN
       IF ( SPAN .LT. R_0 )  THEN
        WRITE ( LUTERM_OUT, 120 )  SPAN
        WRITE ( LUAOU, 120 ) SPAN
  120   FORMAT ( 1X, ' The value supplied for SPAN, ', F15.7,  
     &           ' is invalid. ' )
        STOP 'STOP 479 in Subroutine POSTPR'
       END IF
      END IF
!C
      IF ( NHIC .GT. I_0 )  THEN
       ALLOCATE  ( ZZ(MXHIC,3) )
       ALLOCATE  ( ZM(MXHIC,3) )
       ALLOCATE  ( ZMLG(MXHIC,2) )
       ALLOCATE  ( ZMLT(MXHIC,2) )
      END IF
!C
!C    Create the tabular time histories from Tape 8,
!C     if requested, and compute the severity criteria
!C     NHIC number of times.
!C
      IF ( NHIC .GT. I_0 )  THEN
       NLOOP = NHIC
      ELSE 
       NLOOP = I_1
      END IF
!C
      DO LOOP=1,NLOOP
       IF ( NHIC .GT. I_0 )  THEN                                    
        IDBDY = JHDATA(LOOP,1)                                           
        DO  I = 1,2                                                      
         JDTPTS(I) = JHDATA(LOOP,I+1)                                    
        END DO
       END IF                                                            
!C
       WRITE ( LUAOU, 125 )  NPG                                             
  125  FORMAT ( '1', 122X, 'Page', I5, /, 2X,                                
     &          'Postprocessor Control Parameters', / )                     
       NPG = NPG + I_1                                                 
       WRITE ( LUAOU, 130 )                                                
  130  FORMAT ( 13X, 'HIC & HSI Point', 7X, 
     &          'CSI Point', 5X, 'Body Number' )                         
       WRITE ( LUAOU, 135 )  JDTPTS(1), JDTPTS(2), IDBDY                   
  135  FORMAT ( 5X, 'H.12', 10X, I2, 17X, I2, 10X, I2, / )                 
!C
       NDPT = I_0                                                      
       IHIC = I_0                                                      
       I26 = I_0                                                         
       ITST1 = I_0                                                      
       ITST2 = I_0                                                     
       IF ( NPRT(26) .LT. I_0 )  I26 = ABS ( NPRT(26) )               
       IF ( ( JDTPTS(1) .GT. I_0 ) .OR. 
     &      ( JDTPTS(2) .GT. I_0 ) ) IHIC = I_1   
       IF ( ( NPRT(30) .EQ. I_0 ) .AND. 
     &       ( NPRT(26) .EQ. I_3 ) )  ITST1 = I_1  
       IF ( NPRT(30) .LT. I26 )  ITST2 = I_1                            
       IF ( ( IHIC .EQ. I_1 ) .AND. ( ITST1 .EQ. I_1 ) )  THEN
        WRITE ( LUAOU, 140 )                                               
  140   FORMAT ( 3X, 'WARNING!  Logic of input indicates user ',
     &           'anticipates HIC, HSI and CSI to be computed based on',
     &           ' data for every successful', /, 10X,
     &           'integration step, yet data were stored ',
     &           '(written to TAPE8) every DT.')                           
       END IF
       IF ( ( IHIC .EQ. I_1 ) .AND. ( ITST2 .EQ. I_1 ) )  THEN
        WRITE ( LUAOU, 145 )  NPRT(30), I26                                
  145   FORMAT ( 3X, 'WARNING!  Logic of input indicates user ',
     &           'anticipates HIC, HSI and CSI to be computed based on',
     &           ' data for every ', I2, /, 10X,  
     &           'integer multiple of DT, yet data were stored ',
     &           '(written to TAPE8) every ',I2,
     &           ' integer multiple of DT.' )                              
       END IF
       IF ( ( JDTPTS(1) .GT. I_0 ) .AND. ( NPRT(26) .EQ. I_2 ) 
     &                         .AND. ( NPRT(30) .LT. I_1 ) )  STOP 91     
       IF ( ( JDTPTS(2) .GT. I_0 ) .AND. ( NPRT(26) .EQ. 2 )
     &                         .AND. ( NPRT(30) .LT. I_1 ) )  STOP 92     
       IF  ( JDTPTS(1) .NE. I_0 )   NDPT = NDPT + I_1                   
       IF  ( JDTPTS(2) .NE. I_0 )   NDPT = NDPT + I_1                   
       IF  ( ( .NOT. LTABH ) .AND. ( NDPT .EQ. I_0 )  )  THEN
        CALL ELTIME ( I_2, 36_INTEGER_STD )                                             
        RETURN
       END IF                                                             
!C
!C     Read the time history data from TAPE 8.                               
!C                                                                        
       CALL READ_TAPE_8 ( PRDT, LPP, NDPT, NPTS, NTTH, LTABH, JDTPTS,
     &                    ZZ, ZM )
!C
!C     If tabular time histories are to be outputted and
!C      not at the beginning of a page, call Subroutine
!C      HEDING to output the data.
!C
       IF  ( ( .NOT. LTABH ) .OR. ( LINES .EQ. I_0 ) )  THEN           
        CONTINUE
       ELSE
        IF  ( NTTH .NE. LPP )   CALL HEDING ( LINES, LPP )                 
       END IF
!C
!C     Compute the HIC and CSI numbers if the number of
!C      points for computation is not zero.
!C
       IF  ( NDPT .NE. I_0 )  THEN
        CALL HICCSI ( NPTS, IDBDY, SPAN, JDTPTS, ZZ )
        IF ( JDTPTS(1) .GT. I_0 ) THEN
          DO I = 1, MXHIC
            ZMLG(I,1) = ZM(I,1)
            ZMLT(I,1) = ZM(I,1)
            ZMLG(I,2) = ZM(I,2)
            ZMLT(I,2) = ZM(I,3)
          END DO
          CALL MSC( ZMLG, NPTS, 0 )
          CALL MSC( ZMLT, NPTS, 1 )
        END IF
       END IF
       LTABH = FALSE                                                  
      END DO
!C
      IF ( NHIC .GT. I_0 )  THEN
       DEALLOCATE  ( ZZ )
      END IF
!C
      CALL ELTIME ( I_2, 36_INTEGER_STD )                                               
!C
      RETURN                                                             
      END                                                                
