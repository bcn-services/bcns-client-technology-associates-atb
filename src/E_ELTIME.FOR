      SUBROUTINE ELTIME ( L, N )                                          
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                      
!C    Counts the number of times certain basic subroutines are called    
!C    and accounts for all computer CPU time used by these routines.     
!C                                                                       
!C      Arguments L: 1 Indicates call is at start of routine            
!C                   2 Indicates call is at end of routine.               
!C                  >2 Is the PAGE number when the subroutine is called 
!C                      at the end of the run.                          
!C                N: The subroutine identification number.                
!C                                                                      
!C     The numbering of the subroutines is as follows:                  
!C                                                                      
!C      1. MAIN3D    11. CHAIN     21. PLELP     31. EJOINT             
!C      2. INPUT     12. CONTCT    22. BELTRT    32. SPDAMP             
!C      3. DINT      13. VISPR     23. SEGSEG    33. DAUX44             
!C      4. PRIPLT    14. DAUX11    24. AIRBAG    34. FLXSEG             
!C      5. DZP       15. DAUX12    25. RSTART    35. EQUILB             
!C      6. PDAUX     16. DAUX22    26. SETUP2    36. POSTPR             
!C      7. UPDATE    17. DAUX31    27. IMPULS    37. WINDY              
!C      8. OUTPUT    18. DAUX32    28. IMPLS2    38. HBELT              
!C      9. DAUX      19. DAUX33    29. AIRBG3    39. HPTURB             
!C     10. SETUP1    20. FSMSOL    30. DAUX55    40.                    
!C                                                                      
!C                                                                        
!C      Assumes Function L_LTIME(1) is giving elapsed CPU time in         
!C       integer units of 0.01 seconds since Function L_LTIME(0)        
!C       was called.                                                      
!C                                                                        
!C      NOTE:  the function L_LTIME was called LTIME in versions of the
!C             code before V.2.  It was renamed to avoid conflicts with
!C             intrinsic functions and variables named LTIME that
!C             are present on some machines.
!C
!C      Subroutines called by: see list above.                          
!C                                                                      
!C      Functions called:  L_LTIME                                      
!C                                                                      
!C      STOP(s): 1500                                                   
!C                                                                      
!C      Parameters used: MAXSUB - maximum number of subroutines for     
!C                                 which time accounting information    
!C                                 can be kept.                         
!C                                                                      
!C
      USE  MODULE_STANDARD,  ONLY:  
     &        ICHAR_STD, INTEGER_STD, IREAL_STD, LUAOU,  ! parameters
     &        FALSE, TRUE, I_0, I_1,  R_0, R_100         ! parameters
!C
      IMPLICIT  NONE
!C                                                                      
      INTEGER  ( KIND = INTEGER_STD )  MAXSUB                           
      PARAMETER ( MAXSUB = 40_INTEGER_STD )                              
!C                                                                      
      INTEGER  ( KIND = INTEGER_STD ) 
     &                  I, IND, J, L, MTIN, MTOUT, N, NC, 
     &                  NDIFF, NSUB, NT, NTSUM           
      DIMENSION    IND(MAXSUB), MTIN(MAXSUB), NC(MAXSUB), NT(MAXSUB)     
!C                                                                      
      INTEGER  (KIND = INTEGER_STD )  L_LTIME                            
      EXTERNAL                        L_LTIME
!C                                                                      
      REAL  ( KIND = IREAL_STD )  PC, PCSUM, RNTJ, RNTSUM, TIME_CPU         
!C                                                                      
      CHARACTER ( LEN = 8, KIND = ICHAR_STD )  SUBNAM                   
      DIMENSION              SUBNAM(MAXSUB)                        
!C                                                                      
      INTENT  ( IN )  L, N
!C
      SAVE   IND, MTIN, NC, NSUB, NT                                           
!C                                                                      
!C                                                                      
!C    Define the names of the subroutines for which time accounting     
!C     information will be kept.                                        
!C                                                                      
      DATA   SUBNAM /                                                     
     &   ICHAR_STD_' MAIN3D ', ICHAR_STD_' INPUT  ',
     &   ICHAR_STD_' DINT   ', ICHAR_STD_' PRIPLT ',
     &   ICHAR_STD_' DZP    ', ICHAR_STD_' PDAUX  ',
     &   ICHAR_STD_' UPDATE ', ICHAR_STD_' OUTPUT ',
     &   ICHAR_STD_' DAUX   ', ICHAR_STD_' SETUP1 ',
     &   ICHAR_STD_' CHAIN  ', ICHAR_STD_' CONTCT ',
     &   ICHAR_STD_' VISPR  ', ICHAR_STD_' DAUX11 ',
     &   ICHAR_STD_' DAUX12 ', ICHAR_STD_' DAUX22 ',
     &   ICHAR_STD_' DAUX31 ', ICHAR_STD_' DAUX32 ',
     &   ICHAR_STD_' DAUX33 ', ICHAR_STD_' FSMSOL ', 
     &   ICHAR_STD_' PLELP  ', ICHAR_STD_' BELTRT ',
     &   ICHAR_STD_' SEGSEG ', ICHAR_STD_' AIRBAG ',
     &   ICHAR_STD_' RSTART ', ICHAR_STD_' SETUP2 ',
     &   ICHAR_STD_' IMPULS ', ICHAR_STD_' IMPLS2 ',
     &   ICHAR_STD_' AIRBG3 ', ICHAR_STD_' DAUX55 ',
     &   ICHAR_STD_' EJOINT ', ICHAR_STD_' SPDAMP ',
     &   ICHAR_STD_' DAUX44 ', ICHAR_STD_' FLXSEG ',
     &   ICHAR_STD_' EQUILB ', ICHAR_STD_' POSTPR ',
     &   ICHAR_STD_' WINDY  ', ICHAR_STD_' HBELT  ',
     &   ICHAR_STD_' HPTURB ', ICHAR_STD_'        ' /          
!C                                                                      
!C    Trap improper arguments passed to ELTIME.                          
!C                                                                      
      IF ( (N .LT. I_1 ) .OR. (N .GT. MAXSUB) 
     &                     .OR. (L .LT. I_1) ) THEN     
       WRITE( LUAOU, 100 )                                              
  100  FORMAT ( 1X, 'Internal error, improper argument passed to',      
     &              ' Subroutine ELTIME.' )                             
       STOP 1500                                                        
      END IF                                                            
!C                                                                        
!C     Initialize the time counter, LTIME, and the following            
!C      arrays for each of the timed subroutines:                       
!C                                                                      
!C       NC(j)   - the counter for the number of calls to subroutine J, 
!C       NT(j)   - the counter for the number of time units used by     
!C                  subroutine J,                                       
!C       IND(j)  - the array containing the numbers of the subroutines  
!C                  that were called during the run,                    
!C       MTIN(j) - the array containing the beginning (minimum) time    
!C                  count value that will be subtracted from the        
!C                  total time count to give the actual number of time  
!C                  counts used by the Jth subroutine.  This value is   
!C                  always incremented for each of the subroutines with 
!C                  running counts every time any time is expended in   
!C                  any of the other subroutines.                       
!C                                                                        
!C      when ELTIME is call the first time (L=1) by .MAIN (N=1).        
!C                                                                      
!C     Also, initialize the counter for the number of different         
!C      subroutines that have been called, NSUB.                        
!C                                                                      
      IF ( N .EQ. I_1 ) THEN                                         
       IF ( L .EQ. I_1 ) THEN                                         
!C
!C      Get the starting time and date.
!C
        CALL DATE_TIME ( TRUE, LUAOU )
        NSUB    =  I_1                                              
        MTIN(1) =  L_LTIME( I_0 )                                      
        IND(1)  =  I_1                                                   
        NC(1)   =  I_1                                                  
        MTIN(1) =  I_0                                                 
        NT(1)   =  I_0                                               
        DO  I=2,MAXSUB                                                    
         IND(I)  =  I_0                                                
         NC(I)   =  I_0                                                
         MTIN(I) = -I_1                                               
         NT(I)   =  I_0                                              
        END DO                                                            
       ELSE                                                             
!C                                                                        
!C     For subsequent calls from the MAIN program (L > 1), print the    
!C       summary table.                                                   
!C                                                                        
        NTSUM = L_LTIME( I_1 )                                          
        NT(I_1) = NTSUM - MTIN(I_1)                                     
        TIME_CPU = REAL ( NTSUM, IREAL_STD ) / R_100                         
        WRITE( LUAOU, 110 )  TIME_CPU, L                                
  110   FORMAT ( '1 Elapsed CPU Time =', F10.2, ' Seconds', 85X,        
     &            'Page', I5, //,                                       
     &            '    Sub        Calls      Time       %    ',// )       
!C                                                                      
!C      For each subroutine that has time accounting, print out:        
!C         SUBNAM(j) - the name of the Jth subroutine                   
!C         NC(j)  - the total number of calls to the Jth subroutine,    
!C         RNTJ   - the total CPU time used by the Jth subroutine, and  
!C         PC     - the percentage to the total CPU time used by the    
!C                   Jth subroutine.                                    
!C                                                                      
        PCSUM = R_0                                                 
        NTSUM = I_0                                                  
        DO  I=1,NSUB                                                      
         J = IND(I)                                                       
         PC = REAL ( NT(J), IREAL_STD ) / TIME_CPU                            
         PCSUM = PCSUM + PC                                               
         RNTJ  = REAL ( NT(J), IREAL_STD ) / R_100                    
         NTSUM = NTSUM + NT(J)                                            
         WRITE( LUAOU, 120 )  SUBNAM(J), NC(J), RNTJ, PC                 
  120    FORMAT( A10, I10, F10.2, F10.2 )                                 
        END DO                                                          
!C                                                                      
!C      Print out the total time, RNTSUM, and the total percent, PCSUM  
!C       for the run.                                                   
!C                                                                      
        RNTSUM = REAL ( NTSUM, IREAL_STD ) / R_100                     
        WRITE( LUAOU, 130 )  RNTSUM, PCSUM                               
  130   FORMAT( '0Total', 14X, F10.2, F10.2 )                             
!C                                                                     
!C      Print out run information at the very end of the run.          
!C                                                                     
       CALL DATE_TIME ( FALSE, LUAOU )                                            
       END IF                                                           
       RETURN                                                             
      END IF                                                            
!C                                                                        
!C    If the call is at the beginning of the Nth subroutine (L=1) then  
!C     get the value of the time counter when the subroutine is entered,
!C     LTIME(1), and store it in MTIN(n).                               
!C                                                                      
      IF ( L .EQ. I_1 )   THEN                                        
       MTIN(N) = L_LTIME( I_1 )                                          
!C                                                                      
!C     If this is the first call to the Nth subroutine, NC(n) = 0, then 
!C      increment the total number of subroutines call, NSUB, and       
!C      store the number of the subroutine that called ELTIME in IND(n).
!C                                                                      
       IF ( NC(N) .EQ. I_0 ) THEN                                       
        NSUB = NSUB + I_1                                             
        IND(NSUB) = N                                                     
       END IF                                                           
!C                                                                      
!C     Increment the number of calls made to subroutine N, as stored    
!C      in counter array NC.                                            
!C                                                                      
       NC(N) = NC(N) + I_1                                             
      ELSE                                                                
!C                                                                        
!C    If the call is at the end of the Nth subroutine (L=2) then        
!C     compute the actual number of time units used by the Nth          
!C     subroutine during the time interval called, NDIFF, and add this  
!C     to the total count of time units used by the the Nth             
!C     subroutine, NT(n).  Also, set MTIN(n) to -1 to prevent the Nth     
!C     subroutine from having the time count for this call added to its 
!C     starting count when all the other subroutines have their starting 
!C     incremented by the Nth subroutines time count (see below).       
!C                                                                      
       MTOUT = L_LTIME( I_1 )                                        
       NDIFF = MTOUT - MTIN(N)                                            
       MTIN(N) = -I_1                                                  
       IF ( NDIFF .NE. I_0 ) THEN                                    
        NT(N) = NT(N) + NDIFF                                             
!C                                                                      
!C      For a nonzero time count, besides adding the time count used    
!C       by Subroutine N to its total time counter, NT, add this time   
!C       count to the beginning (base) time count of all of the other   
!C       subroutines that have been called and have running time        
!C       counters.  This is needed so that timed subroutines which      
!C       have timed subroutines within them will correctly attribute    
!C       CPU time used by the calling subroutine only and will not      
!C       include the CPU time used by the called subroutine.            
!C                                                                      
        DO  I=1,MAXSUB                                                    
         IF ( MTIN(I) .NE. -I_1 )   MTIN(I) = MTIN(I) + NDIFF          
        END DO                                                            
       END IF                                                           
      END IF                                                            
!C                                                                      
!C    Return to the Nth subroutine which called ELTIME.                 
!C                                                                      
      RETURN                                                            
      END                                                               
