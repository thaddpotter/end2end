pro write_temp_force, start=start
;------------------------------------------------------------------
;Writes flight data to csv files
;Currently, only for flight 1, but if flight 2 is similarly packaged...
;
;Keys:
;start - starting time to be used for data
;
;output:
;csv file containing flight data
;------------------------------------------------------------------

;Load Settings block
sett = e2e_load_settings()
if ~keyword_set(start) then start = 12

file = sett.outpath + 'temp/flight_1_temp.csv'

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Trim to desired sensors                         
sel = [where(strmatch(t.abbr,'OBB?') or strmatch(t.abbr,'OBM?'),ntemp),$     ;Inst]
       where( (t.location eq 'Primary') AND (t.abbr NE 'MTR1') ,ntemp),$        ;M1
       where(t.location eq 'Truss' and not strmatch(t.abbr, 'OBM*'),ntemp),$ ;Truss
       where( strmatch(t.abbr,'M2??') ,ntemp)]                               ;M2

ss = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*] + 273.15
abbr = t[sel].abbr

;Trim to desired time range
n = n_elements(abbr)
m = n_elements(ftemp[0,*])

;Abbreviation array
for i = 0, n-1 do begin
    abbr[i] = strjoin(strsplit(abbr[i],'-',/extract))
endfor

;Trim to time range, manage n_elements
a = min(abs(time-start),ind)
time  = time[ind:m-1:100]
ftemp = ftemp[*,ind:m-1:100]
m = n_elements(ftemp[0,*])

;Define format and header strings
delim = ','
format = '('
header = string('TIME',format = '(A15)')

for i = 0, n-1 do begin
    format += 'A15,A1,'
    header += string(delim, abbr[i],format = '(A1,A15)')
endfor
format += 'A15)'

;Open file, print header
openw, 1, file
printf, 1, header

;Loop over rows
for i = 0, m-1 do begin

    ftime = n2s(time[i])

    ;loop over columns to assign variables
    print_str = 'printf,1,ftime,delim,'
    for j = 0, n-2 do begin
        void = execute( n2s(abbr[j]) + '= ' + n2s(ftemp[j,i]) )
        print_str += n2s(abbr[j]) + ',' + 'delim' + ','
    endfor
    void = execute( n2s(abbr[n-1]) + '= ' + n2s(ftemp[n-1,i]) )
    print_str += n2s(abbr[n-1]) + ',' + 'format = format'
    void = execute(print_str)

endfor
close,1
print, 'Wrote file: ', n2s(file)

end