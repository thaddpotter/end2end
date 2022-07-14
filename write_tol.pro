pro write_tol, unit, tolfile, tscfile, val
;----------------------------------------------------
;Writes tolerance files for use with Zemax, which can be imported to run wavefront error analysis




;Outputs:
;'filename.tol' - Tolerance Script, which uses displacement values from the 

;------------------------------------------------------

;--Setup----------------------------------
optic = ['M1','M2','Bench']
surf1tilt = [3,5,6]
surf2tilt = [3,5,0]
surf1thick = [0,4,6]
surf2thick = [0,5,0]

format_tol =  '('    +$  ;Format string for tolerance Lines
              'A-4,' +$
              'A-7,' +$
              'I-4,' +$
              'I-2,' +$
              'E23.21,' +$
              'E23.21,' +$
              'I4,' +$
              'I2' +$
              ')'

format_com =  '('    +$   ;Format string for comment lines
              'A-5,' +$
              'A-'   +$
              ')'

;--Write out tolerance file---------------------------------------

openw, unit, tolfile
;Header
printf,unit,'VERS 130723' 
printf,unit, 'TOL', 'TWAV', 0, 0, 0.6, 0, 0, 0,format=format_tol
printf,unit,'TCMM Default test wavelength', format=format_com

;Loop over elements
for i = 0, 2 do begin

    ;Displacements
    printf,unit, 'TOL', 'TEDX', surf1tilt[i], surf2tilt[i], val[i].disp[0], val[i].disp[0], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TEDX',format=format_com
    printf,unit, 'TOL', 'TEDY', surf1tilt[i], surf2tilt[i], val[i].disp[1], val[i].disp[1], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TEDY',format=format_com
    printf,unit, 'TOL', 'TTHI', surf1thick[i], surf2thick[i], val[i].disp[2], val[i].disp[2], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TTHI',format=format_com

    ;Rotations
    printf,unit, 'TOL', 'TETX', surf1tilt[i], surf2tilt[i], val[i].disp[3], val[i].disp[3], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TETX',format=format_com
    printf,unit, 'TOL', 'TETY', surf1tilt[i], surf2tilt[i], val[i].disp[4], val[i].disp[4], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TETY',format=format_com
    printf,unit, 'TOL', 'TETZ', surf1tilt[i], surf2tilt[i], val[i].disp[5], val[i].disp[5], 0, 0, format=format_tol
    printf,unit,'TCMM ', n2s(optic[i]) + 'TETZ',format=format_com

endfor
close, unit


;--Write tolerance script-----------------------------------------

;openw, unit, tscfile

;Compensators





;closew

end