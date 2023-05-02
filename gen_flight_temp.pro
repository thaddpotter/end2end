pro gen_flight_temp, start_time, stop_time, interval
;------------------------------------------------
;Generates a list of temperatures from flight 1 data for some time window
;------------------------------------------------
;Inputs
;start_time - time to start recording
;stop_time - time to stop recording
;interval - time interval to record to sheet
;Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Make array of time points fit to output times
n_points = ceil( (stop_time - start_time)/interval + 1 )
points = dindgen(n_points, start = start_time, increment=interval)

t_list = dblarr(n_points)
for i = 0, n_points-1 do begin
    tmp = min( Abs(time - points[i]), ind )
    t_list[i] = ind
endfor

;make output struct
tmp = { TIME:   0d  ,$
        M2GL:	0d	,$
        OBM1:	0d	,$
        OBM2:	0d	,$
        HEX	:	0d	,$
        OBM3:	0d	,$
        M2PL:	0d	,$
        M1B1:	0d	,$
        M1B2:	0d	,$
        M1B3:	0d	,$
        M1G1:	0d	,$
        M1G2:	0d	,$
        M1G3:	0d	,$
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
        OBB :	0d $
}

out = replicate(tmp,n_points)

;Get tag names
flight_tags = strarr(n_elements(t.abbr))
for i = 0,n_elements(t.abbr)-1 do begin
    flight_tags[i] = strjoin(strsplit(t[i].abbr,'-',/EXTRACT))
endfor
newtags = tag_names(tmp)

;Fill output
n_abbr = 37
out.time = time[t_list]

for j = 1, n_abbr-1 do begin
    a = where(strmatch(flight_tags,newtags[j]))
    ind = fix(a[0])
    out.(j) = reform(adc_temp[ind,t_list]) + 273.15
endfor


;fix time formatting for filename
t1 = strjoin(strsplit(n2s(start_time,format='(F5.2)'),'.',/EXTRACT))
t2 = strjoin(strsplit(n2s(stop_time,format='(F5.2)'),'.',/EXTRACT))

;write to csv
filename = 'output/temp/tvals_' + t1 + '_' + t2 + '.csv'
check_and_mkdir, 'output/temp/'

openw, 1, filename
write_ttable, 1, out, newtags
close, 1
print, 'Wrote: ' + filename

end