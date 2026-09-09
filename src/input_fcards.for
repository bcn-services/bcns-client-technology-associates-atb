      SUBROUTINE INPUT_FCARDS                                         
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Input Cards F.1-F.4 specifying the allowed contacts of the crash    
!C    victim body segments with vehicle panels, belts, airbags and other  
!C    body segments along with the associated functions to be used for    
!C    each contact.                                                       
!C    Also sets up tables to control time history information for         
!C    each function for each allowed contact, as well as inputting
!C    the airbag and wind force functions.                       
!C                                                                        
!C    This subroutine is called only by Subroutine INITIALIZE.
!C                                                                        
      USE  MODULE_STANDARD,  ONLY:
     &         NRTORQ,                               ! /ACTFR/
     &         NPG, NPL, NBLT, NSEG, NGRND, NJNT,    ! /CONTRL/ 
     &         NWINDF, NHRNSS,                       ! /CONTRL/
     &         NBAG,                                 ! /JBARTZ/
     &         MXNTB, MXTB1, MXTB2,                  ! /TABLES/
     &         MWSEG,                                ! /WINDFR/
     &         INTEGER_STD, LUAOU, I_0, I_1          ! parameters
!C
      USE  MODULE_WATER,  ONLY:   NWATER             ! /WATINF1/
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )   I
!C
!C    Initialize function counters.
!C
      MXNTB = I_0                                                    
      MXTB2 = MXTB1                                                      
!C                                                                        
!C    Write the header denoting the beginning of the echo
!C     for the F cards.                    
!C                                                                        
      WRITE ( LUAOU, 100 )  NPG                                            
      NPG = NPG + I_1                                                     
  100 FORMAT ( '1 Allowed Contacts and Associated Functions', 80X,         
     &         'Page', I5 )                                                 
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input the force functions for the plane-segment contacts,
!C     Cards F.1.
!C
      IF ( NPL .GT. I_0 ) CALL INPUT_PLANE_FORCE
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input the force functions for the belt-segment contacts,
!C     Cards F.2.
!C
      IF ( NBLT .GT. I_0 ) CALL INPUT_BELT_FORCE
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input the force functions for the segment-segment contacts,
!C     Cards F.3.
!C
      IF ( NSEG .GT. I_0 )  CALL INPUT_SEG_SEG_FORCE                                
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input the force functions for the globalgraphic joint,
!C     functions, Cards F.4.
!C
      IF ( NJNT .GT. I_0 )  CALL INPUT_GLOBALGRAPHIC_FORCE                                
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C                                                                      
!C    Input contact segments for airbag, if any, from the F.6 cards.      
!C                                                                        
      IF ( NBAG .GT. I_0 )  CALL INPUT_AIRBAG_FORCE                                     
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Initialize the array denoting whether segments have a 
!C     wind force applied to them.
!C
      DO  I=1,NGRND                                                       
       MWSEG(1,I) = I_0                                               
      END DO
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C                                                                        
!C    Input Cards F.7.a-F.7.b for the wind force functions.              
!C                                                                        
      IF ( NWINDF .NE. I_0 )  CALL INPUT_WIND_FORCE                                 
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input Cards F.8.a-F.8.d for the harness belts.
!C
!C
      IF ( NHRNSS .NE. I_0 )  CALL INPUT_HARNESS                                               
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input Cards F.9.a-F.9.m for the water forces.
!C
      IF ( NWATER .NE. I_0 )  CALL INPUT_WATER                      
!C
!C    Check for comments.
!C
      CALL CHECK_COMMENT
!C
!C    Input Cards F.10 for the joint actuator functions.
!C
      IF ( NRTORQ .GT. I_0 )  CALL INPUT_ROBOTICS                  
!C
      RETURN                                                              
      END                                                                 
