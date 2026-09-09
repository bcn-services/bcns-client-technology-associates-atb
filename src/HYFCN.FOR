      FUNCTION HYFCN ( C_LCL, Z, A, P )               
!C
!C                                                   Rev. V.3 12/15/2002 
!C
      USE  MODULE_STANDARD,  ONLY:
     &       IREAL_HIGH, D_0                ! parameters
!C
      IMPLICIT  NONE                                                       
!C
      REAL  ( KIND = IREAL_HIGH )   HYFCN
      REAL  ( KIND = IREAL_HIGH )   C_LCL, Z, A, P, Q, Q_LIMIT
!C
      PARAMETER  ( Q_LIMIT = -88.5_IREAL_HIGH )
!C
      INTENT (  IN )  C_LCL, Z, A, P
!C
      HYFCN = C_LCL                                                        
      IF ( P .EQ. D_0 )  THEN
       RETURN                                                              
      END IF
!C
      HYFCN = D_0                                                        
      IF ( Z .EQ. D_0 )   THEN
       RETURN                                                              
      END IF   
!C
      Q = P * ( LOG ( ABS ( Z ) ) - LOG ( A ) )                            
      IF ( Q .GT. Q_LIMIT )  THEN  
       HYFCN = C_LCL * EXP ( Q )                                           
      END IF
!C
      RETURN                                                               
      END                                                                  
