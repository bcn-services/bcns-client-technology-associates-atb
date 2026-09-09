       FUNCTION WAVE_HEIGHT ( WX, WY )
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    This function evaluates the wave height for wave K at the point 
!C    (WX,WY) on the water frame.  
!C      
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        TIME,                          ! /CONTRL/
     &        INTEGER_STD, IREAL_HIGH, D_0   ! parameters
!C
      USE  MODULE_WATER, 
     &        ONLY:  NWAVES, WNUM, FREQ, WPHS, WAMP, WDIR  ! /WAVEDAT/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD ) I
!C
      REAL  ( KIND = IREAL_HIGH )   WAVE_HEIGHT
      REAL  ( KIND = IREAL_HIGH )   TEMP, WX, WY
!C
      INTENT  ( IN )  WX, WY
!C
      WAVE_HEIGHT = D_0
      DO  I = 1,NWAVES
       TEMP = WX * COS ( WDIR(I) ) - WY * SIN ( WDIR(I) )
       TEMP = TEMP * WNUM(I) - FREQ(I) * TIME + WPHS(I) 
       TEMP = WAMP(I) * COS ( TEMP )
       WAVE_HEIGHT  = WAVE_HEIGHT + TEMP
      END DO
!C
      RETURN
      END
