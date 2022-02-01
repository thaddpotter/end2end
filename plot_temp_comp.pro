pro plot_temp_comp

;Plots flight 1 data and COMSOL simulation temperature data for comparison


;The majority of this code is adapted from plot_flight_temp.pro in the picctest repository

;---Startup-------------------------------------

;Load Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Read COMSOL output file to structure
ctemp = read_comsol_temp('data/stop/Tsense_test.csv')

;Get actual times from COMSOL output
ctime = ctemp.time + 16d

;Filled circle symbol
symbol_arr = FINDGEN(17) * (!PI*2/16.)
usersym, cos(symbol_arr), sin(symbol_arr), thick=0.5

;---Instrument Plots---------------------------------

stop


;Trim Flight Data
sel  = where(strmatch(t.abbr,'OBB?'),ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

plotfile='temp_inst.eps'
mkeps,name= sett.plotpath + plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot, symbols
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=minmax(ftemp),/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]',title='Bench Temperatures'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if ncomsol eq 1 then $
    oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+plotfile


;---Primary Plots---------------------------------

;Trim Flight Data
sel  = where(t.location eq 'Primary',ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

plotfile='temp_primary.eps'
mkeps,name= sett.plotpath + plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot, symbols
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=minmax(ftemp),/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]',title='Primary Temperatures'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if ncomsol eq 1 then $
    oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+plotfile


;---Truss Plots---------------------------------

;Trim Flight Data
sel  = where(t.location eq 'Truss',ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

plotfile='temp_truss.eps'
mkeps,name= sett.plotpath + plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=minmax(ftemp),/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]',title='Truss Temperatures'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)))
    ;Plot COMSOL Data
    oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+plotfile



end