      SUBROUTINE VINTST ( LOPT, AT0, ADT, VTIME, NATAB, NUMVEH_LCL,
     &                    LTYPE, LFIT, NPTS,VIPS )                        
!C
!C                                                   Rev. V.3 12/15/2002 
!C
!C                                                                        
!C    This subroutine performs tests on the input data for the            
!C    four types of vehicle input options.  In cases where unnecessary    
!C    data are entered, a warning message is printed and the              
!C    data are ignored.  More severe types of errors result in a          
!C    message explaining the problem followed by a STOP.                  
!C                                                                        
!C                                                                        
!C    Subroutines called by:  VINO12, VINO34                              
!C                                                                        
!C    STOPS: 79, 80, 81, 82, 83, 205, 206, 207, 208, 209, 210, 211, 212   
!C                                                                        
!C    Global variables used but not altered: X0, ANGLE, VMEG                                   
!C                                                                       
!C                                                                       
      USE  MODULE_STANDARD,  ONLY:
     &       ANGLE, VMEG, X0,                   ! /VIN_TEMPVS/
     &       INTEGER_STD, IREAL_HIGH,           ! parameters
     &       LUAOU, MAXVT2, MAXVT3, MAXVT4,     ! parameters
     &       D_0, I_0, I_1, I_2, I_3            ! parameters
!C
      IMPLICIT   NONE                                                     
!C
      INTEGER  ( KIND = INTEGER_STD )
     &              LFIT, LOPT, LTYPE, MATAB, NATAB, NPTS, NUMVEH_LCL
!C                                                                        
      REAL  ( KIND = IREAL_HIGH )   ADT, AT0, VIPS, VTIME
!C
      INTENT ( IN )  LOPT, AT0, ADT, VTIME, NATAB, NUMVEH_LCL,
     &                    LTYPE, LFIT, NPTS,VIPS
!C
!C    Use the appropriate section depending on which type of vehicle        
!C    input option data are to be checked.                               
!C                                                                        
      IF ( LOPT .EQ. I_1 ) THEN                                         
!C                                                                      
!C     Perform tests on input data for Option 1.                          
!C                                                                        
       IF ( ANGLE(3) .NE. D_0 ) THEN                                   
        WRITE ( LUAOU, 100 )  ANGLE(3)                                     
  100   FORMAT ( /, 1X, 'ANGLE(3) = ', F12.4,
     &          ' from Card C.2.a is not',                                 
     &          ' needed for vehicle input option 1.', /, ' Input',       
     &          ' value ignored.', / )                                     
       END IF                                                             
!C
       IF ( AT0 .NE. D_0 )  THEN                                         
        WRITE ( LUAOU, 102 )  AT0                                         
  102   FORMAT ( /, 1X, 'AT0 = ', F12.4,
     &           ' from Card C.2.a IS not needed',                        
     &           ' for vehicle input option 1.', /, ' Input value',       
     &           ' ignored.', / )                                         
       END IF                                                             
!C
       IF ( ADT .NE. D_0 ) THEN                                          
        WRITE ( LUAOU, 104 )  ADT                                        
  104   FORMAT ( /, 1X, 'ADT = ', F12.4, 
     &           ' from Card C.2.a is not needed',                        
     &           ' for vehicle input option 1.', /, ' Input value',      
     &           ' ignored.', / )                                       
       END IF                                                            
!C
       IF ( VTIME .LE. D_0 ) THEN                                        
        WRITE ( LUAOU, 106 )                                            
  106   FORMAT ( /, 1X,
     &           'VTIME from Card C.2.a can not be negative or ',        
     &           ' equal to zero for input option 1.', // )              
        STOP ' STOP 206 in Subroutine VINTST'                              
       END IF                                                            
      ELSE IF ( LOPT .EQ. I_2 ) THEN                                  
!C                                                                      
!C     Perform tests on vehicle input data for Option 2.                   
!C                                                                       
       IF ( NATAB .GT. MAXVT2 )  THEN                                    
        WRITE ( LUAOU, 108 )  MAXVT2, NUMVEH_LCL                           
  108   FORMAT ( /, 1X,
     &           'The maximum number of data points allowed for',         
     &           ' option 2,', I4, ', was exceeded for vehicle number',    
     &           I4, '.', // )                                            
        STOP ' STOP 79 in Subroutine VINTST'                             
       END IF                                                              
!C
       IF ( VTIME .NE. D_0 )  THEN                                       
        WRITE ( LUAOU, 110 )  VTIME                                       
  110   FORMAT ( /, 1X, 'VTIME = ', F12.4, 
     &           ' from Card C.2.a is not needed',                         
     &           ' for vehicle input option 2.', /,
     &           ' Input value ignored.', / )                             
       END IF                                                             
!C
       IF ( ANGLE(3) .NE. D_0 )  THEN                                  
        WRITE ( LUAOU, 112 )  ANGLE(3)                                     
  112   FORMAT ( /, 1X, 'ANGLE(3) = ', F12.4,
     &           ' from Card C.2.a is not',   
     &          ' needed for vehicle input option 2.', /,
     &          ' Input value ignored.', / )                               
       END IF                                                              
!C
       IF ( AT0 .LT. D_0 )  THEN                                         
        WRITE ( LUAOU, 114 )  AT0                                         
  114   FORMAT ( /, 1X, 'AT0 = ', F12.6,
     &           ' from Card C.2.a can not be negative.', // )             
        STOP ' STOP 207 in Subroutine VINTST'                             
       END IF                                                              
       IF ( ADT .LE. D_0 ) THEN                                        
        WRITE ( LUAOU, 116 )  ADT                                          
  116   FORMAT ( /, 1X, 'ADT = ', F12.6,
     &           ' from Card C.2.a can not be',  
     &           ' less than or equal to zero for', /,                     
     &           ' vehicle input option 2.', // )                          
        STOP ' STOP 208 in Subroutine VINTST'                              
       END IF                                                              
      ELSE IF ( LOPT .EQ. I_3 )  THEN                                
!C                                                                        
!C     Perform tests on input data for vehicle input Option 3.             
!C                                                                        
       MATAB = -NATAB                                                     
       IF ( MATAB .GT. MAXVT3 ) THEN                                       
        WRITE ( LUAOU, 118 ) MATAB, MAXVT3                                 
  118   FORMAT ( 1X, 'The number of data points to be read for',           
     &          ' option 3, ', I4, /, 1X, 'exceeds the maximum number',  
     &          ' of allowable points,', I4, '.', // )                     
        STOP ' STOP 80 in Subroutine VINTST'                               
       END IF                                                              
!C
       IF ( LFIT .NE. I_0 ) THEN                                        
        WRITE ( LUAOU, 120 ) LFIT                                          
  120   FORMAT ( 1X, 'LFIT =', I4, 
     &           ' from Card C.2.b is not needed for',                     
     &           ' vehicle input option 3.', /,
     &           ' Input value ignored.', / )                              
       END IF                                                             
!C
       IF ( NPTS .NE. I_0 ) THEN                                        
        WRITE ( LUAOU, 122 )  NPTS                                         
  122   FORMAT ( 1X, 'NPTS =', I4, 
     &           ' from Card C.2.b is not needed for',                     
     &           ' vehicle input option 3.', /,
     &           ' Input value ignored.', / )                              
       END IF                                                              
!C
       IF ( VTIME .NE. D_0 ) THEN                                      
        WRITE ( LUAOU, 124 )  VTIME                                       
  124   FORMAT ( 1X, 'VTIME = ', F12.6, 
     &           ' from Card C.2.a is not needed',                        
     &           ' for vehicle input option 3.', /,
     &          ' Input value ignored.', / )                             
       END IF                                                             
!C
       IF ( AT0 .LT. D_0 )  THEN                                    
        WRITE ( LUAOU, 126 )  AT0                                          
  126   FORMAT ( 1X, 'AT0 = ', F12.6, ' from Card C.2.a can not be',      
     &           ' NEgative for vehicle input option 3.', // )            
        STOP ' STOP 209 in Subroutine VINTST'                             
       END IF                                                             
!C
       IF ( ADT .LE. D_0 )  THEN                                         
        WRITE ( LUAOU, 128 )  ADT                                         
  128   FORMAT ( 1X, 'ADT = ', F12.6, ' from Card C.2.a can not be',     
     &          ' zero or negative for vehicle input option 3.', // )      
        STOP ' STOP 210 in Subroutine VINTST'                              
       END IF                                                           
      ELSE                                                                
!C                                                                        
!C     Perform tests on input data for vehicle input Option 4.            
!C                                                                       
       IF ( NPTS .GT. MAXVT4 )  THEN                                       
        WRITE ( LUAOU, 130 )  NPTS, MAXVT4                                
  130   FORMAT ( /, 1X, 'The number of data points for option 4,', I4,   
     &           ', exceeds the maximum number of data points',          
     &           ' permitted,', I4, '.', // )                            
        STOP ' STOP 81 in Subroutine VINTST'                               
       END IF                                                             
!C
       IF ( ( LTYPE .EQ. I_2 ) .AND. ( LFIT .EQ. I_0 ) )  THEN        
        WRITE ( LUAOU, 132 )                                              
  132   FORMAT ( /, 1X,
     &           'The degree of the polynomial when velocity data',        
     &           ' are supplied, LTYPE=2, must be 1, 2, or 3,',            
     &           ' not LFIT = 0.', // )                                    
        STOP ' STOP 83 in Subroutine VINTST'                               
       END IF                                                              
!C
       IF ( ( LTYPE .EQ. I_1 ) .AND.
     &      ( ( LFIT .EQ. I_1 ) .OR. ( LFIT .EQ. I_0 ) ) ) THEN      
        WRITE ( LUAOU, 134 )  LFIT                                        
  134   FORMAT ( /, 1X,
     &           'The degree of the polynomial when position data',        
     &           ' are supplied, LTYPE=1, must be 2 or 3',                
     &           ' not', I4, '.', // )                                   
        STOP ' STOP 82 in Subroutine VINTST'                              
       END IF                                                              
!C
       IF  ( ( LFIT .LT. I_0 ) .OR. ( LFIT .GT. I_3 ) )  THEN      
        WRITE ( LUAOU, 136 )  LFIT                                         
  136   FORMAT ( /, 1X, 'the degree of the polynomial supplied,', I4,      
     &           ', is not allowed.', // )                                 
        STOP ' STOP 205 in Subroutine VINTST'                              
       END IF                                                             
!C
       IF ( ( ANGLE(1) .NE. D_0 ) .OR. ( ANGLE(2) .NE. D_0 ) 
     &                             .OR. ( ANGLE(3) .NE. D_0 ) )  THEN      
        WRITE ( LUAOU, 138 )   ANGLE(1), ANGLE(2), ANGLE(3)                
  138   FORMAT ( /, 1X, 'ANGLE(1) = ', F12.6, 3X, 'ANGLE(2) = ', F12.6,    
     &           3X, 'ANGLE(3) = ', F12.6, ' from Card C.2.a are', /,      
     &           ' not needed for vehicle input option 4.  Input',         
     &           ' value(s) ignored.', / )                                 
       END IF                                                             
!C
       IF ( VIPS .NE. D_0 )  THEN                                    
        WRITE ( LUAOU, 140 ) VIPS                                         
  140   FORMAT ( /, 1X, 'VIPS = ', F12.4,
     &           ' from Card C.2.a is not needed',                         
     &           ' for vehicle input option 4.', /,
     &           ' Input value ignored.', / )                              
       END IF                                                              
!C
       IF ( VTIME .NE. D_0 ) THEN                                     
        WRITE ( LUAOU, 142 )  VTIME                                        
  142   FORMAT ( /, 1X, 'VTIME = ', F12.4,
     &           ' from Card C.2.a is not needed',                        
     &           ' for vehicle input option 4.', /,
     &           ' Input value ignored.', / )                           
       END IF                                                              
!C
       IF ( ( X0(1) .NE. D_0 ) .OR. ( X0(2) .NE. D_0 ) 
     &                          .OR. ( X0(3) .NE. D_0 ) )  THEN       
        WRITE ( LUAOU, 144 )  X0(1), X0(2), X0(3)                         
  144   FORMAT ( /, 1X, 'X0(1) = ', F12.5, 3X, 'X0(2) = ',
     &           F12.5, 3X, 'X0(3) = ',  
     &           F12.5, ' from Card C.2.a are', /, ' not needed for',      
     &          ' vehicle input option 4.  Input value(s) ignored.', / )   
       END IF                                                              
!C
       IF ( AT0 .LT. D_0 )  THEN                                        
        WRITE  ( LUAOU, 146 )  AT0                                        
  146   FORMAT ( /, 1X, 'AT0 = ', F12.6, ' from Card C.2.a can not',      
     &           ' be negative for vehicle input option 4.', // )          
        STOP ' STOP 211 IN SUBROUTINE VINTST'                             
       END IF                                                            
!C
       IF ( ADT .LE. D_0 )  THEN                                        
        WRITE ( LUAOU, 148 )  ADT                                         
  148   FORMAT ( /, 1X, 'ADT = ', F12.6, ' from Card C.2.a can not',       
     &           ' be less than or equal to zero for vehicle ',            
     &           'input option 4.', // )                                   
        STOP ' STOP 212 in Subroutine VINTST'                            
       END IF                                                            
!C
       IF ( ( VMEG(1) .NE. D_0 ) .OR. ( VMEG(2) .NE. D_0 ) 
     &                            .OR. ( VMEG(3) .NE. D_0 ) )  THEN     
        WRITE ( LUAOU, 150 )  VMEG(1), VMEG(2), VMEG(3)                  
  150   FORMAT ( /, 1X, 'VMEG(1) = ', F12.5,3X, 'VMEG(2) = ', F12.5,
     &           3X, 'VMEG(3) = ', F12.5, ' from Card C.2.b are', /,      
     &          ' not needed for vehicle input option 4.  Input',         
     &          ' value(s) ignored.', / )                                 
       END IF                                                             
!C
      END IF                                                              
!C
      RETURN                                                              
      END                                                                 
