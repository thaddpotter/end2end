function read_comsol_bench, file, delim=delim

;Read Data to Structure
input_struct = tp_read_txt(file, n_table_header=5, header=oldtags,delim=delim)

list = input_struct.(0)

print, list

tags = ['X','Y','Z','U','V','W']

output_struct = {X: 0, $
                 Y: 0, $
                 Z: 0, $
                 U: 0, $
                 V: 0, $
                 W: 0, $
                 T: 0}

j = dblarr(7,4)
for i = 1, n_elements(j)-1 do begin
    j[(i-1) MOD 4, (i-1)/4 ] = list[i]
endfor

stop

return, output_struct

end