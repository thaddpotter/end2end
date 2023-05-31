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
data_struct = read_td_corr(file,measure_file=meas_file)              ;TD Correlation Data
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

;Sensors to iterate over
prefix = tag_names(data_struct)
prefix = prefix[2:n_elements(prefix)-2]

;String array for legend
ntemp = max(data_struct.loopct)+1
leg = strarr(ntemp+1)
leg[0] = 'Flight'
for i = 1, ntemp do $
    leg[i] = 'Iter ' + n2s(i-1)

;Loop over all sensors in the list
foreach element, prefix, ind do begin

    ;Match to flight data
    sel  = where(strmatch(newtag,element))

    ;Trim Flight Data to correct sensor
    if sel LE 0 then begin
    ;If theres no match, average over the numbered sensors with the same name
        string2 = element.substring(0,2) + '?'
        sel  = where(strmatch(newtag,string2))
        ss   = sort(t[sel].abbr)
        sel  = sel[ss]
        ftemp = mean(adc_temp[sel,*],dimension=1,/DOUBLE)
        abbr = element
    endif else begin
        ss   = sort(t[sel].abbr)
        sel  = sel[ss]
        ftemp = adc_temp[sel,*]
        abbr = t[sel].abbr
    endelse
    ;CASE WHERE (M1B...) temps averaged over sensors?

    ;Trim flight data by time
    sel2 = where(time GE tmin AND time LE tmax)
    tt = time[sel2]
    ftemp = ftemp[*,sel2]

    ;Plot
    plotfile= element
    mkeps, sett.plotpath + dir + plotfile

    ;Color Settings
    color=bytscl(dindgen(ntemp+1),top=254)
    loadct,39

    ;Initialize Plot, symbols
    plot,tt,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-80,30],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]',color=color[0],Title = element

    ;Match tag to structure
    j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr,'-',/EXTRACT)),2)),ntd)

    ;Loop over TD iterations
    for i=0,ntemp-1 do begin

        ;Trim to loop
        tdt = data_struct.time[where(data_struct.loopct EQ i)]/3600d + tmin
        tmp = data_struct.(j)[where(data_struct.loopct EQ i)]
        
        ;Plot TD Data
        if not keyword_set(flight_only) then begin
            if ntd eq 1 then $
            oplot,tdt, tmp-273.15,color=color[i+1]
        endif
    endfor

    cbmlegend,leg,intarr(ntemp+1),color,[0.845,0.94],linsize=0.5
    mkeps,/close
    print,'Wrote: '+ sett.plotpath + dir + plotfile

endforeach
end