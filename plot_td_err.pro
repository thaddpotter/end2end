pro plot_td_err,day=day,night=night, steady=steady, plotdir=plotdir
;Plots comparisons of thermal desktop data
;Arguments:
;plotdir - directory to save plots to inside end2end/plots/td_(night/day)/
;Keywords
;steady - Flag for if the file being read in is from a steady state optimization
;           If yes, then set steady=1 during call
;day/night - Flag for time slot, call /night if night, /day if day

;Setup
;-------------------------------------
sett = e2e_load_settings()

if keyword_set(steady) then $
file = sett.tdpath + 'init_pm2/bootstrap_test2.dlo' else $
file = sett.tdpath + 'td_pm/bootstrap_test.dlo'

meas_file = sett.tdpath + 'tsense_data/tsense_m2.txt'

;Read in Data
;------------------------------------;
data_struct = read_td_corr_dyn(file,measure_file=meas_file,steady=steady)   ;TD Correlation Data
restore, sett.path + 'data/flight/picture_c1_temp_data.idl'             ;Flight Data

newtag = strarr(n_elements(t.abbr))                                     ;Remove '-' from tags
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
check_and_mkdir, sett.plotpath + dir + plotdir

;Sensors to iterate over
prefix = tag_names(data_struct)
prefix = prefix[2:n_elements(prefix)-2]

;Trim to fewer loops so graph is more readable
ntemp = max(data_struct.loopct)+1
n_loops = 10
if ntemp GT n_loops then begin
    inc = ntemp / double(n_loops -1)
    newinds = floor(dindgen(n_loops,increment = inc))
    newinds[n_loops-1] = ntemp-1
endif else begin
    newinds = indgen(ntemp)
endelse

;String array for legend
leg = strarr(ntemp+1)
leg[0] = 'Flight'
for i = 1, ntemp do $
    leg[i] = 'Iter ' + n2s(i-1)
leg = leg[newinds]

;Loop over all sensors in the list
foreach element, prefix, ind do begin

    ;Match to flight data
    sel  = where(strmatch(newtag,element))

    ;Trim Flight Data to correct sensor
    if sel LE 0 then begin
    ;If theres no perfect match, average over the numbered sensors with the same name
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

    ;Trim flight data by time
    if keyword_set(steady) then begin
        v = min(abs(time - tmin),sel2)
    endif else begin
        sel2 = where((time GE tmin) AND (time LE tmax))
        tt = time[sel2]
    endelse
    ftemp = ftemp[sel2]

    ;Plot
    ;-------------------------------------------------------------------------
    plotfile= element
    mkeps, sett.plotpath + dir + plotdir + plotfile

    ;Plot Steady State

    if keyword_set(steady) then begin

        n = n_elements(data_struct.time)
        j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr,'-',/EXTRACT)),2)),ntd)
        
        ;Color Settings
        color=bytscl(dindgen(2),top=254)
        loadct,39

        plot, indgen(n), replicate(ftemp,n), position=[0.12,0.12,0.84,0.94],yrange=[-80,30],/xs,/ys,xtitle='Iteration', ytitle='Temperature [C]', color=color[0], Title = element
            
        oplot,indgen(n), data_struct.(j)-273.15, color=color[1]

        cbmlegend,['Flight', 'TD'],intarr(2),color,[0.845,0.94],linsize=0.5

    endif else begin

    ;Color Settings
    color=bytscl(dindgen(ntemp+1),top=254)
    loadct,39

    ;Initialize Plot, symbols
    plot,tt,ftemp,position=[0.1,0.1,0.8,0.94],yrange=[-50,30],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]',color=color[0],Title = element

    ;Match tag to structure
    j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr,'-',/EXTRACT)),2)),ntd)

    ;Loop over TD iterations
    foreach i, newinds do begin

        ;Trim to loop
        tdt = data_struct.time[where(data_struct.loopct EQ i)]/3600d + tmin
        tmp = data_struct.(j)[where(data_struct.loopct EQ i)]
        
        ;Plot TD Data
        if not keyword_set(flight_only) then begin
            if ntd eq 1 then $
            oplot,tdt, tmp-273.15,color=color[i+1]
        endif
    endforeach

    cbmlegend,leg,intarr(ntemp),color,[0.845,0.94],linsize=0.5
    endelse

    mkeps,/close
    print,'Wrote: '+ sett.plotpath + dir + plotdir + plotfile

endforeach

;Overall error plot for steady state
if keyword_set(steady) then begin
    plotfile= 'err'
    mkeps, sett.plotpath + dir + plotdir + plotfile
    n = n_elements(data_struct.time)

    plot, indgen(n), data_struct.err, position=[0.12,0.12,0.84,0.94],/xs,/ys,    xtitle='Iteration', ytitle='RMS Error', Title = 'RMS Error on Init'

    mkeps,/close
    print,'Wrote: '+ sett.plotpath + dir + plotdir + plotfile

endif




end