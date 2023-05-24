pro plot_td_err, file,
;Plots comparisons of 

;Setup
;-------------------------------------
sett = e2e_load_settings()
file = sett.tdpath + 'td_pm/night_correlation.dlo'
meas_file = sett.tdpath + 'tsense_data/tsense_f1.txt'


;Read in Data
;------------------------------------;
data_struct = read_td_corr(file,measure_file=meas_file)     ;TD Correlation Data
restore, sett.path + 'data/flight/temp_data.idl'          ;Flight Data

stop



end