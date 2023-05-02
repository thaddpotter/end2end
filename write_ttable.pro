pro write_ttable,unit,table, header
;;Writes out table of temperature data from flight
;;Called by gen_flight_temp

  ed  = ''              ;Empty string
  md  = ','             ;Delimiter
  ef = 'A0'             ;Format code prefix
  f1 = '(A-15,A1,$)'    ;Element and delimiter format code

;Write Header
for j=0,n_elements(header)-1 do begin
    printf, unit, header[j], md, format = f1
endfor
printf,unit, ''

;Write Data
;Loop over rows
for j=1,n_elements(table)-1 do begin
    ;Loop over columns
    for i = 0, n_elements(header)-1 do begin
        printf, unit, table[j].(i), md, format = f1
    endfor
    ;Carriage Return
    printf,unit, ''

endfor
end