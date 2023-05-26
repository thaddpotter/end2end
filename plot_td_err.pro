pro plot_td_err,day=day,night=night
;Plots comparisons of thermal desktop data
;Arguments:
;dir - thermal desktop case set directory
;   Must contain a *.dlo file



;TODO:
;How to plot error over time for multiple iterations
;Unroll, seperate plots?

;Setup
;-------------------------------------
sett = e2e_load_settings()

file = sett.tdpath + 'td_pm/night_correlation.dlo'
meas_file = sett.tdpath + 'tsense_data/tsense_f1.txt'

;Read in Data
;------------------------------------;
data_struct = read_td_corr(file,measure_file=meas_file,/twoD)              ;TD Correlation Data
restore, sett.path + 'data/flight/picture_c1_temp_data.idl'          ;Flight Data

newtag = strarr(n_elements(t.abbr))                                  ;Remove '-' from tags
for i = 0, n_elements(t.abbr)-1 do begin
    newtag[i] = strjoin(strsplit(t[i].abbr,'-',/EXTRACT))
endfor

;Plot settings
;----------------------------------------

;Xlimits
if keyword_set(day) then begin
    tmin = 12.45 
    dir = 'td_day/'
endif else if keyword_set(night) then begin
    tmin = 21.95
    dir = 'td_night/'
endif else begin
    print, 'Please specify timeslot'
    stop
endelse
tmax = max(data_struct.time)/3600d + tmin

;Directory
check_and_mkdir, sett.plotpath + dir

;Time array for TD Datapoints
tdt = tmin + data_struct.time/3600d

;Filled circle symbol
symbol_arr = FINDGEN(17) * (!PI*2/16.)
usersym, cos(symbol_arr), sin(symbol_arr), thick=0.5

stop 

;Loop over all sensors in the list
foreach element, prefix, ind do begin

    ;Match to flight data
    sel  = where(strmatch(newtag,element))

    ;Trim Flight Data to correct sensor
    ss   = sort(t[sel].abbr)
    sel  = sel[ss]
    ftemp = adc_temp[sel,*]
    abbr = t[sel].abbr

    ;Trim flight data by time
    sel2 = where(time GE tmin AND time LE tmax)
    tt = time[sel2]
    ftemp = ftemp[*,sel2]

    ;Plot
    plotfile= element
    mkeps, sett.plotpath + dir + plotfile
    color=bytscl(dindgen(ntemp),top=254)
    loadct,39

    ;Initialize Plot, symbols
    plot,tt,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-40,40],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

    ;Loop over iterations
    for i=0,ntemp-1 do begin

        ;Match tag to structure
        j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ntd)
        ;Plot TD Data
        if not keyword_set(flight_only) then begin
            if ntd eq 1 then $
            oplot,tdt, data_struct.(j)-273.15,color=color[i],psym=8
        endif
    endfor

    cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
    mkeps,/close
    print,'Wrote: '+ sett.plotpath + dir + plotfile

endforeach
end