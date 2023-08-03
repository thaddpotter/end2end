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

function read_td_corr, dlo_file, measure_file=measure_file, steady=steady
;Reads correlation *.dlo files from Dynamic SINDA Runs

;Define Structure
struct_base = {time: 0d,$     ;Keys for temperature probes
                LOOPCT: 0d,$
                TC_1: 0d,$
                TC_2: 0d,$
                TC_3: 0d,$
                TC_4: 0d,$
                TC_5: 0d,$
                TC_6: 0d,$
                TC_7: 0d,$
                TC_8: 0d,$
                TC_9: 0d,$
                TC_10: 0d,$
                TC_11: 0d,$
                TC_12: 0d,$
                TC_13: 0d,$
                TC_14: 0d,$
                TC_15: 0d,$
                TC_16: 0d,$
                TC_17: 0d,$
                TC_18: 0d,$
                TC_19: 0d,$
                TC_20: 0d,$
                TC_21: 0d,$
                TC_22: 0d,$
                TC_23: 0d,$
                TC_24: 0d,$
                TC_25: 0d,$
                TC_26: 0d,$
                TC_27: 0d,$
                TC_28: 0d,$
                TC_29: 0d,$
                TC_30: 0d,$
                TC_31: 0d,$
;               TC_32: 0d,$ One less tag, leaving as comment in case I revert this before final
                err:0d}

;Read table
readcol, dlo_file, time, loopct,TC_1,TC_2,TC_3,TC_4,TC_5,TC_6,TC_7,TC_8, $
                TC_9,TC_10,TC_11,TC_12,TC_13,TC_14,TC_15,TC_16, $
                TC_17,TC_18,TC_19,TC_20,TC_21,TC_22,TC_23,TC_24, $
                TC_25,TC_26,TC_27,TC_28,TC_29,TC_30,TC_31,$
                ;TC_32,$
                err, FORMAT = 'D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D'

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
struct_full[*].TC_1 = TC_1
struct_full[*].TC_2 = TC_2
struct_full[*].TC_3 = TC_3
struct_full[*].TC_4 = TC_4
struct_full[*].TC_5 = TC_5
struct_full[*].TC_6 = TC_6
struct_full[*].TC_7 = TC_7
struct_full[*].TC_8 = TC_8
struct_full[*].TC_9 = TC_9
struct_full[*].TC_10 = TC_10
struct_full[*].TC_11 = TC_11
struct_full[*].TC_12 = TC_12
struct_full[*].TC_13 = TC_13
struct_full[*].TC_14 = TC_14
struct_full[*].TC_15 = TC_15
struct_full[*].TC_16 = TC_16
struct_full[*].TC_17 = TC_17
struct_full[*].TC_18 = TC_18
struct_full[*].TC_19 = TC_19
struct_full[*].TC_20 = TC_20
struct_full[*].TC_21 = TC_21
struct_full[*].TC_22 = TC_22
struct_full[*].TC_23 = TC_23
struct_full[*].TC_24 = TC_24
struct_full[*].TC_25 = TC_25
struct_full[*].TC_26 = TC_26
struct_full[*].TC_27 = TC_27
struct_full[*].TC_28 = TC_28
struct_full[*].TC_29 = TC_29
struct_full[*].TC_30 = TC_30
struct_full[*].TC_31 = TC_31
;struct_full[*].TC_32 = TC_32 See above note in struct def
struct_full[*].err = err

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