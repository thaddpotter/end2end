pro gen_flight_temp, start_time, stop_time, interval, label = label
;------------------------------------------------
;Generates a list of temperatures from flight 1 data for some time window
;------------------------------------------------
;Inputs
;start_time - time to start recording
;stop_time - time to stop recording
;interval - time interval to record to sheet

;Keywords
;label - set to output sensor names in headers instead of Thermal Desktop Measure Key
;       (Easier to read and debug table, but will not be readable as a dlc!)

;Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, sett.path + 'data/flight/picture_c1_temp_data.idl'

;Read in measure file
measure_file = sett.tdpath + 'tsense_data/tsense_f5.txt'
key_arr = read_td_measure(measure_file)

;Make array of time points fit to output times
n_points = ceil( (stop_time - start_time)/interval + 1 )
points = dindgen(n_points, start = start_time, increment=interval)

t_list = dblarr(n_points)
for i = 0, n_points-1 do begin
    tmp = min( Abs(time - points[i]), ind )
    t_list[i] = ind
endfor

;make output struct (TODO: Make dynamic from measure file?)
tmp = { TIME:   0d  ,$
        M2GL:	0d	,$
        OBM1:	0d	,$
        OBM2:	0d	,$
        HEX	:	0d	,$
        OBM3:	0d	,$
        M1B:	0d	,$
        M1G:    0d	,$
        M1P2:	0d	,$
        T45:	0d	,$
        T44:	0d	,$
        T43:	0d	,$
        T42:	0d	,$
        T41:	0d	,$
        T35:	0d	,$
        T34:	0d	,$
        T33:	0d	,$
        T32:	0d	,$
        T31:	0d	,$
        M1P3:	0d	,$
        M1P1:	0d	,$
        T25:	0d	,$
        T24:	0d	,$
        T23:	0d	,$
        T22:	0d	,$
        T21:	0d	,$
        T15:	0d	,$
        T14:	0d	,$
        T13:	0d	,$
        T12:	0d	,$
        T11:	0d	,$
        OBB1:	0d  ,$
        OBB2:	0d  ,$
        OBB3:	0d  $
}

out = replicate(tmp,n_points)

;Get tag names
flight_tags = strarr(n_elements(t.abbr))
for i = 0,n_elements(t.abbr)-1 do begin
    flight_tags[i] = strjoin(strsplit(t[i].abbr,'-',/EXTRACT))
endfor
newtags = tag_names(tmp)

;Fill output
n_abbr = n_elements(key_arr[*,0])
out.time = time[t_list]

for j = 1, n_abbr do begin
    sel = where(strmatch(flight_tags,newtags[j]))

    ;If theres no perfect match, average over the numbered sensors with the same name
    if sel LE 0 then begin
        string2 = newtags[j].substring(0,2) + '?'
        sel  = where(strmatch(flight_tags,string2))
        tmp = mean(adc_temp[sel,*],dimension=1,/DOUBLE)
        out.(j) =  reform(tmp[t_list]) + 273.15

    endif else begin
        ind = fix(sel[0])
        out.(j) = reform(adc_temp[ind,t_list]) + 273.15
    endelse
endfor

;fix time formatting for filename
t1 = strjoin(strsplit(n2s(start_time,format='(F5.2)'),'.',/EXTRACT))
t2 = strjoin(strsplit(n2s(stop_time,format='(F5.2)'),'.',/EXTRACT))

;write to csv
filename = 'tvals_' + t1 + '_' + t2 + '.csv'
check_and_mkdir, sett.outpath + 'temp/'

openw, 1, sett.outpath + 'temp/' + filename
write_ttable, 1, out, key_arr, label=label
close, 1
print, 'Wrote: ' + filename

end