pro gen_comsol_init, init_time=init_time
;------------------------------------------------
;Generates a list of temperatures from flight 1 data at some time
;Defaults to noon (approximately when instrument reaches float altitude)
;------------------------------------------------

;Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Trim to initial time
if not keyword_set(init_time) then t0 = 12 else t0 = init_time
near = min( Abs(time - t0), ind )

;make output struct
n = n_elements(t.abbr)
tmp = {abbr: '' ,$
       t0: 0d}
out = replicate(tmp,n)

;find values
for i = 0, n-1 do begin
    out[i].abbr = t[i].abbr
    out[i].t0 = adc_temp[i,ind]
endfor

;write to csv
filename = 'output/temp/init.csv'
check_and_mkdir, 'output/temp/'

write_csv, filename, out.abbr, out.t0, header = ['sensor key','temp at t='+n2s(t0)]

end