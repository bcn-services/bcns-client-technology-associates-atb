      SUBROUTINE FDINIT ( IFLAG_LCL )                                     
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C    Replaces code previously in Subroutines FINPUT and HINPUT.          
!C    From five function numbers in NF array                              
!C     1. set up KTITLE                                                   
!C     2. set up NTAB and TAB arrays                                      
!C     3. increment counters MXNTB and MXTB2                              
!C                                                                        
!C
      USE  MODULE_STANDARD, ONLY: 
     &        MXNTB, MXTB2, NTAB, NTI, TAB,      ! /TABLES/
     &        FUNC_TITLE, KTITLE, NF_FUNCT,      ! /CINPUT_TEMPVS/
     &        INTEGER_STD, IREAL_HIGH,           ! parameters
     &        LUAOU, MAXNTB, MAXTAB,             ! parameters
     &        D_0, I_0, I_1, I_5                 ! parameters
!C
      IMPLICIT  NONE
!C
      INTEGER  ( KIND = INTEGER_STD )
     &             IFLAG_LCL, J1, J2, JJ, KJ, KK, L, NT, NTPL_LCL, NX
!C
      REAL  ( KIND = IREAL_HIGH )   DX  
!C
      REAL  ( KIND = IREAL_HIGH )   EVALFD
      EXTERNAL  EVALFD
!C
      INTENT ( IN )  IFLAG_LCL
!C
      J1 = MXTB2 + I_1                                                  
      NT = MXNTB + I_1                                                  
      NTAB(NT) = J1                                                       
      IF ( IFLAG_LCL .EQ. I_1 ) THEN                                  
       NT = NT + I_1                                                  
       DO  L=1,5                                                          
        NX = ABS ( NF_FUNCT(L) )                                          
        NTAB(NT) = I_0                                                 
        IF ( NX .EQ. I_0 )  THEN                                      
         NT = NT + I_1
         CYCLE
        END IF
        NTAB(NT) = SIGN ( NTI(NX), NF_FUNCT(L) )                          
        DO  KK = 1,5                                                      
         KJ = I_5 * L + KK + I_1                                         
         KTITLE(KJ) = FUNC_TITLE(NX)( ( KK*4 - 3 ) : KK*4 )                   
        END DO
        IF  ( NTI(NX) .NE. I_0 )  THEN                                
         NT = NT + I_1
        ELSE
         WRITE ( LUAOU, 100 )  NX                                       
  100    FORMAT ( '0 Function no.', I4, ' has not been defined. ',        
     &            '  Program terminated.')                                
         STOP 15                                                          
        END IF
       END DO
!C                                                                        
!C     Initialize TAB array to zero except for DMAX, DINER, FDMAX.        
!C                                                                        
       J2 = J1 + 30_INTEGER_STD                                         
       DO  JJ=J1,J2                                                       
        TAB(JJ) = D_0                                                   
       END DO
       NX = NTAB(NT-5)                                                    
       IF ( NX .GT. I_0 )  THEN                                       
        TAB(J1+8) = ABS ( TAB(NX+1) )                                     
        IF ( TAB(NX+2) .NE. D_0 )  TAB(J1+8) = ABS ( TAB(NX+2) )        
        DX = TAB(J1+8)                                                    
        TAB(J1+10) = EVALFD ( DX, NX, I_1 )                             
        NX = NTAB(NT-4)                                                   
        IF ( NX .GT. I_0 )  THEN                                      
         TAB(J1+9) = ABS ( TAB(NX+1) )                                    
         IF ( TAB(NX+2) .NE. D_0 )   TAB(J1+9) = ABS ( TAB(NX+2) )       
        END IF
       END IF
       J1 = J2 + I_1                                                     
       MXNTB = NT - I_1                                                 
       MXTB2 = J1 - I_1                                                
!C                                                                      
      ELSE                                                              
!C                                                                      
!C      The statements in this "else" block have been added to set      
!C      up storage for the loading history of multiple belt segments.   
!C      The offset to JJ of 62 is required because FDINIT is called     
!C      twice for each belt point; once for the belt force/strain       
!C      data and once for the contact point force/displacement data.    
!C      (E. Sieveka, UVA - 11/28/92)                                    
!C                                                                      
        J2 = J1 + 30_INTEGER_STD                                                    
        DO  JJ=J1,J2                                                    
         TAB(JJ)=TAB(JJ-62)                                             
        END DO                                                          
        DO  L=1,5                                                       
         NTPL_LCL = NT + L                                              
         NTAB(NTPL_LCL) = NTAB(NTPL_LCL-12)                             
        END DO                                                          
        MXNTB = NT + I_5                                             
        MXTB2 = J1 + 30_INTEGER_STD                                    
      END IF                                                            
!C
      IF  ( MXTB2 .GT. MAXTAB )  THEN
       WRITE ( LUAOU, 105 )  MXTB2               
  105  FORMAT ('0 Error in Subroutine FDINIT, size of TAB array =',
     &          I8, //, '  Program terminated.' )                         
       STOP 16
      ELSE IF ( MXNTB .GT. MAXNTB )  THEN
       WRITE ( LUAOU, 110 )  MXNTB                
  110  FORMAT ( '0 Error in Subroutine FDINIT, size of NTAB array =',
     &          I8, //, '  Program terminated.' )                         
       STOP 16
      END IF
!C
      RETURN                                                              
      END                                                                 
