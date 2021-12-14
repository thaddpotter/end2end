pro read_comsol, file

;Read Data to Structure
data_struct = cbm_read_csv(file, n_table_header=9)

sz = n_tags(data_struct)

index = indgen(sz,start=1,/string)
if sz LE 9 then oldtags = strcompress('FIELD0'+index,/remove_all) else begin
  tmp1 = make_array(9,/string,value='FIELD0')
  tmp2 = make_array(sz-9,/string,value='FIELD')
  tmp = [tmp1,tmp2]
  oldtags = strcompress(tmp+index,/remove_all)
endelse

newtags = strarr(sz)
newtags[0] = ['X','Y','Z']

i = 3
while (i LT sz) do begin
  newtags[i] = [strcompress('U'+string(i/3),/remove_all),$
                strcompress('V'+string(i/3),/remove_all),$
                strcompress('W'+string(i/3),/remove_all),$
                strcompress('T'+string(i/3),/remove_all)]
  i += 4
endwhile

for i = 0,sz-1 do begin
struct_replace_field, data_struct, oldtags[i], data_struct.(oldtags[i]), newtag=newtags[i]
endfor

end