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

function read_td_corr_dyn, dlo_file, measure_file=measure_file, steady=steady
;Reads correlation *.dlo files from Dynamic SINDA Runs
;Unlike read_td_corr, this checks the 
;TODO: write check for complete processor in transient runs

;Get number of columns
openr, lun , dlo_file, /GET_LUN

str = ''
readf, lun, str
fields = strsplit(str,' ',/EXTRACT)
fieldcount = n_elements(fields)
close,lun

;Construct execute strings
struct_str = 'struct_base = {time: 0d, LOOPCT: 0d, '
read_str = 'readcol, dlo_file, time, loopct, '
format_str = "format = 'D,D,D"
for i = 1,fieldcount-3 do begin
    struct_str = struct_str + 'TC_'+n2s(i)+': 0d,'
    read_str = read_str + 'TC_'+n2s(i)+', '
    format_str = format_str + ',D'
endfor
struct_str = struct_str + 'err: 0d}'
read_str = read_str + 'err, ' + format_str + "'"

;Create base structure
void = execute(struct_str)
if not void then stop

;Read Table
void = execute(read_str)
if not void then stop

;Fix Loopcount field
if not keyword_set(steady) then begin
    sel1 = where(time EQ max(time),count1)
    sel2 = where(time EQ min(time),count2)
    for i = 0, count1 - 1 do begin
        a = sel2[i]
        b = sel1[i]
        loopct[a:b] = i
    endfor
    if sel1[count1-1] LT n_elements(time) then $
        loopct[b+1:n_elements(loopct)-1] = i  ;Incomplete loop at end
endif

struct_full = replicate(struct_base,n_elements(time))

;Fill output structure
struct_full[*].time = roundn(time,3)
struct_full[*].loopct = loopct

for i = 1, fieldcount-3 do begin
fill_str = 'struct_full[*].TC_' + n2s(i) + '= TC_' + n2s(i) 
void = execute(fill_str)
if not void then stop
endfor

struct_full[*].err = err

;Fix extras if processor completed
if keyword_set(steady) then begin
    sel = where(struct_full.time EQ 0)
    struct_full = struct_full[sel]
endif

;Rename fields to temperature sensors
if keyword_set(measure_file) then begin
    key_arr = read_td_measure(measure_file)

    for i = 2,n_elements(key_arr)/2 + 1 do begin
        tag = key_arr[i-2,1]
        newtag = key_arr[i-2,0]
        struct_replace_field, struct_full, tag, struct_full.(i), newtag = newtag
    endfor
endif

return, struct_full
end