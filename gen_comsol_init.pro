pro gen_comsol_init
;------------------------------------------------
;Generates a list of initial temperatures for the COMSOL model input
;Pulls from flight data
;------------------------------------------------

;Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Trim to initial time
t0 = 12
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
filename = 'data/stop/init.csv'

write_csv, filename, out.abbr, out.t0, header = ['sensor key','temp at t='+n2s(t0)]


end