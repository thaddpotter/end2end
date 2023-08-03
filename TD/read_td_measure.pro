function read_td_measure, measure_file
;Reads measure file to register temperature measures to PICC temp sensor ID's
;Dont need the whole structure, since we dont care about any data outside of column 1

;Read Table
readcol, measure_file, temp_ID, x, y, z, sz, FORMAT='A,D,D,D,D'

;Add Temp Codes
id_arr = strarr(n_elements(temp_ID),2)
id_arr[*,0]= n2s(temp_ID)

;Reformat (- is an illegal char for struct field name)
;Add Measure Values
for i = 0, n_elements(temp_ID)-1 do begin
    id_arr[i,0] = strjoin(strsplit(id_arr[i,0],'-',/EXTRACT))
    id_arr[i,1] = 'TC_'+n2s(i+1)
endfor

return, id_arr
end