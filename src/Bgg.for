      SUBROUTINE BGG ( A, ZA, DA, BFA, VA, WA,                              
     &                 B_BGG, ZB, DB, BFB, VB, WB,                           
     &                 VSCS_BGG, IFULL_BGG, TV, FRA, TORQ_LCL, TQB,
     &                 VOL, YFB_BGG )   
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Computes the volume of intersection of an ellipsoidal airbag           
!C    with an ellipsoidal body segment or reaction panel.                    
!C    Also computes the force per unit pressure and torque per unit          
!C    pressure on both the bag and the intersecting object.                  
!C                                                                           
!C    Arguments:                                                             
!C     Airbag inputs : A(3,3) - ellipsoid matrix                             
!C                     ZA(3)  - c.g.                                         
!C                     DA(3,3)- direction cosine matrix                      
!C                     BFA(3) - offset                                       
!C                     VA(3)  - cg velocity(inertial ref.)                   
!C                     WA(3)  - angular velocity (local ref.)                
!C                                                                           
!C     Contact surface B_BGG(3,3) - ellipsoid matrix                         
!C                     ZB(3)  - c.g.                                         
!C                     DB(3,3)- direction cosine matrix                      
!C                     BFB(3) - offset                                       
!C                     VB(3)  - cg velocity (inertial ref.)                  
!C                     WB(3)  - angular velocity (local ref.)               
!C                     VSCS_BGG   - coefficient of sliding friction          
!C                     IFULL_BGG  - if zero, compute vol only.              
!C                     TV(3)  - memory for Subroutines INTERS & EDEPTH.      
!C                                                                          
!C           Output  : FRA(3) - force on bag                                
!C                     TORQ(3)- torque on bag                                
!C                     TOB(3) - torque on contact surface                  
!C                     VOL    - volume of intersection                      
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        EPS, PI,                            ! /CNSNTS/
     &        INTEGER_STD, IREAL_HIGH, I_0,       ! parameters
     &        D_0, D_HALF, D_1, D_2, D_3, D_10    ! parameters
!C
      IMPLICIT  NONE
!C
      REAL  ( KIND = IREAL_HIGH )  RCRT, VECMAG
      EXTERNAL                     RCRT, VECMAG
!C
!C    Local variables.
!C
      INTEGER  ( KIND = INTEGER_STD )   I, IFULL_BGG, J, K, L
!C
      REAL  ( KIND = IREAL_HIGH )
     &                  A, ZA, DA, BFA, VA, WA, B_BGG, ZB, DB, BFB,
     &                  VB, WB, FRA, TORQ_LCL, TQB, TV, YFB_BGG, AB_BGG,
     &                  DAB, BA, TEMP, Y, CPA, CPB, PLANE, FORCE_LCL,
     &                  CBB, VLM, FRB, YFA, ZBB, T1, T2_LCL, T3, T4,
     &                  T5, T6, S3TEST, VOL, TB, P, RA, RB, R, RC,
     &                  VP, VD, ALP, BET, FM, PP, AREA, SUM, SQ3,
     &                  VSCS_BGG, FF_BGG
      DIMENSION  A(3,3),     ZA(3), DA(3,3), BFA(3), VA(3), WA(3),
     &           B_BGG(3,3), ZB(3), DB(3,3), BFB(3), VB(3), WB(3),
     &           FRA(3), TORQ_LCL(3), TQB(3), TV(3), YFB_BGG(3),        
     &           DAB(3,3), BA(3,4), TEMP(3,3), Y(3), CPA(3),     
     &           CPB(3), PLANE(4,3), FORCE_LCL(3), CBB(3), VLM(3),
     &           FRB(3), YFA(3), ZBB(3), T1(3), T2_LCL(3), T3(3), 
     &           T4(3),  T5(3), T6(3)                                     
!C                                                                         
!C    Initialization                                                         
!C                                                                          
      S3TEST = D_10                                            
      VOL = D_0                                                             
      FRA(I)  = D_0                                                     
      TORQ_LCL(I) = D_0                                                     
      TQB (I) = D_0                                                      
      DO  I=1,3                                                             
       BA(I,4) = -BFA(I)                                                     
       DO  J=1,3                                                             
        BA(I,4) = BA(I,4) + DA(I,J) * ( ZB(J) - ZA(J) )                      
        DAB(I,J) = D_0                                                   
        DO  K=1,3                                                           
         DAB(I,J) = DAB(I,J) + DA(I,K) * DB(J,K)                             
        END DO
       END DO
      END DO
!C                                                                          
!C    Compute distance between ellipsoid centers and                         
!C    convert ellipsoid matrix of object to airbag reference.                
!C                                                                           
      DO  I=1,3                                                             
       DO  J=1,3                                                             
        TEMP(I,J) = D_0                                                   
        BA(I,4)=BA(I,4)+DAB(I,J)*BFB(J)                                      
        DO  K=1,3                                                            
         TEMP(I,J) = TEMP(I,J) + B_BGG(I,K) * DAB(J,K)                       
        END DO
       END DO
      END DO
      CALL MAT33 ( DAB, TEMP, BA )                                           
!C                                                                           
!C    Check for intersection and determine points of maximum penetration     
!C                                                                          
      TB = D_1                                                             
      CALL INTERS ( A, BA, BA(1,4), TB, Y, TV(1), T1 )                      
      IF ( TB .GT. D_1 )  RETURN                                        
      CALL EDEPTH ( A, BA, BA(1,4), TB, Y, CPA, CPB, TV(2), TV(3) )         
!C                                                                           
!C    Set up orthogonal system using vector between points                   
!C    of maximum penetration as one axis.                                    
!C                                                                           
      P = D_0                                                             
      DO  I=1,3                                                              
       PLANE(I,3) = CPA(I) - CPB(I)                                          
       P = PLANE(I,3)**2 + P                                               
      END DO
      IF  ( P .LT. EPS(6) )  RETURN                                         
      PP = SQRT ( P )                                                        
      DO  I=1,3                                                              
       TEMP(I,1) = PLANE(I,3) / PP                                          
      END DO
      CALL ORTHO ( PLANE, TEMP, 4 )                                         
!C                                                                          
!C    Define planes at maximum penetration points.                          
!C                                                                           
      DO  I=1,3                                                              
       PLANE(4,I) = D_0                                                    
       DO  J=1,3                                                            
        PLANE(4,I) = PLANE(4,I) + PLANE(J,I) * CPB(J)                       
       END DO
      END DO
      DO  K=1,3                                                              
       CBB(K) = CPB(K) - BA(K,4)                                            
      END DO
!C                                                                          
!C    Estimates of volume and area based on radii of curvature               
!C        and penetration.                                                  
!C                                                                           
      AREA=PI                                                           
      DO  L=1,2                                                              
       RA=RCRT ( A, PLANE, CPA, L )                                         
       RB=RCRT ( BA, PLANE, CBB, L )                                        
       IF ( PP .GT. RA )  RA = PP                                            
       R  = ( RA - RB ) * D_HALF                                              
       RC = ( RA + RB ) * D_HALF                                               
       VP = PP / ( RA + RB )                                               
       VD = VP                                                               
       ALP = RC * SQRT ( VP * ( D_2 - VP ) )                               
       IF ( R .LT. D_0 )  THEN                                             
        AB_BGG = RA + RB - PP                                                
        BET = ( RA**2 - RB**2 + AB_BGG**2 ) * D_HALF / AB_BGG                 
        ALP = SQRT ( RA**2 - BET**2 )                                       
        R = D_0                                                           
        VD = D_1 - BET / RA                                              
        VP = ( PP + BET - RA ) / RB                                          
       END IF
       VLM(L) =   RB * ( RB * VP )**2 * ( D_1 - VP / D_3 )
     &          + RA * ( RA * VD )**2 * ( D_1 - VD / D_3 )            
       IF ( R .GT. D_0 )  THEN
        VLM(L) = VLM(L) - ALP * R * R * ( PI - D_2 * 
     &           ( ASIN ( D_1 - VP ) + ( D_1 - VP ) * ALP / RC ) )          
       END IF
       VLM(L) = VLM(L) * PI                                               
       AREA = AREA * ALP                                                 
      END DO                                                            
      VOL = ( VLM(1) + VLM(2) ) * D_HALF                                     
      IF  ( IFULL_BGG .EQ. I_0 )  RETURN                                  
!C                                                                           
!C    Set up force vector along line of maximum penetration.               
!C                                                                        
      CALL DOT31 ( DAB, CBB, ZBB )                                          
      YFA = CPB + BFA                                         
      YFB_BGG = ZBB + BFB                                     
      DO  K=1,3                                                             
       FORCE_LCL(K) = -AREA * PLANE(K,3)                                    
      END DO
      T1 = VA - VB                                       
!C                                                                           
!C    Compute angular velocity components,relative velocity, components      
!C    of relative velocity along max penetration line and magnitude of       
!C    force.                                                                
!C                                                                          
      CALL MAT31 ( DA, T1, T2_LCL )                                         
      CALL CROSS ( WA, YFA, T1)                                             
      CALL CROSS ( WB, YFB_BGG, T3 )                                        
      CALL MAT31 ( DAB, T3, T4 )                                             
      FM = D_0                                                            
      SUM = D_0                                                            
      DO  K=1,3                                                              
       T5(K) = T2_LCL(K) + T1(K) - T4(K)                                     
       SUM = SUM + T5(K) * PLANE(K,3)                                        
       FM = FM + FORCE_LCL(K)**2                                          
      END DO
!C                                                                          
!C    Compute components of relative velocity in tangent plane,              
!C    friction force and total force vector.                                 
!C                                                                          
      DO  K=1,3                                                              
       T6(K) = T5(K) - SUM * PLANE(K,3)                                    
      END DO
      SQ3 = VECMAG ( T6 )                                                    
      IF ( SQ3 .LT. S3TEST )  SQ3 = S3TEST / ( D_2 - SQ3 / S3TEST )         
      FF_BGG = VSCS_BGG * SQRT( FM ) / SQ3                                 
      FORCE_LCL = FORCE_LCL - FF_BGG * T6                   
!C                                                                          
!C    Compute FRB: force on reaction surface in its local reference.         
!C           TORQ: torque on airbag in airbag reference.                    
!C            TQB: torque on reaction surface in its local reference.       
!C            FRA: force on airbag in inertial reference.                   
!C                                                                          
      CALL DOT31 ( DAB, FORCE_LCL, FRB )                                 
      CALL CROSS ( YFA, FORCE_LCL, TORQ_LCL )                                  
      CALL CROSS ( FRB, YFB_BGG, TQB )                                       
      CALL DOT31 ( DA, FORCE_LCL, FRA )                                    
!C
      RETURN                                                                 
      END                                                                  
