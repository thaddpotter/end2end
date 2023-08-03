function read_comsol_disp, file, delim=delim

;Read Data to Structure
input_struct = tp_read_txt(file, n_table_header=8, header=oldtags,delim=delim)

sz = n_tags(input_struct)
newtags = strarr(sz)
newtags[0] = ['X','Y','Z'] 

i = 3
while (i LT sz) do begin
  newtags[i] = [strcompress('U'+string(i/4+1),/remove_all),$
                strcompress('V'+string(i/4+1),/remove_all),$
                strcompress('W'+string(i/4+1),/remove_all),$
                strcompress('T'+string(i/4+1),/remove_all)]
  i += 4
endwhile

;Initialize output structure
output_struct = create_struct(newtags[0],input_struct.(0))
;Fill output structure
for i = 1,sz-1 do begin
  output_struct = create_struct(output_struct,newtags[i],input_struct.(i))
endfor

;check for parameter sweep
if sz GT 7 then begin
  ;Grab parameter sweep values
  sweep = strarr(sz-3)

  for i = 3, sz-1 do begin
    tmp = strsplit(oldtags[i],'@',/EXTRACT)
    sweep[i-3] = strtrim(tmp[1],2)
  endfor

  params = sweep(uniq(sweep))

  ;add parameter sweep values to structure
  output_struct = create_struct(output_struct,'params',params)
endif

return, output_struct

end