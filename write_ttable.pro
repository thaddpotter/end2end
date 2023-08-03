pro write_ttable,unit,table, key_arr
;;Writes out table of temperature data from flight
;;Called by gen_flight_temp

  ed  = ''              ;Empty string
  md  = ','             ;Delimiter
  ef = 'A0'             ;Format code prefix
  f1 = '(A-15,A1,$)'    ;Element and delimiter format code

ncols = n_elements(key_arr[*,0])
tmin = min(table[0].(0))

;Write Headers
printf, unit, 'TIME', md, format = f1
for j=0, ncols-1 do begin
    printf, unit, 'TC_' + n2s(j+1), md, format = f1
endfor
printf,unit, '' ;Carriage Return

printf, unit, 'sec', md, format = f1
for j=0,ncols-1 do begin
    printf, unit, 'K', md, format = f1
endfor
printf,unit, '' ;Carriage Return

;Write Data
;Loop over rows
for j=0,n_elements(table)-1 do begin

    ;Convert Time to seconds from T0
    time = (table[j].(0) - tmin) * 3600d

    if j EQ 3 then stop
    printf, unit, time, md, format = f1
    ;Loop over columns
    for i = 1, ncols-1 do begin
        printf, unit, table[j].(i), md, format = f1
    endfor
    printf,unit, '' ;Carriage Return

endfor
end