pro plot_temp_comp, filename, oldkey=oldkey, newkey=newkey, flight_only=flight_only, model_only=model_only, search=search

;Plots flight 1 data and COMSOL simulation temperature data for comparison
;The majority of this code is adapted from plot_flight_temp.pro in the picctest repository

;Arguments:


;Outputs:
;generates postscript plots for different parts of the instrument

;Keywords:
;oldkey - flag for old list of subscripts (use for backwards compatibility with previous COMSOL models)
;flight_only - only plot flight data
;model_only - only plot model points (NOT IMPLEMENTED)
;search - a four character string which will be used to filter the temperature sensor keys for a final plot
;   example (search = 'T1**')

;---Startup-------------------------------------

;Load Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Read COMSOL output file to structure
if keyword_set(oldkey) then ctemp = read_comsol_temp_oldkey('data/temp/'+filename) else $
if keyword_set(newkey) then ctemp = read_comsol_temp_newkey('data/temp/'+filename) else $
ctemp = read_comsol_temp('data/temp/'+filename)

check_and_mkdir, sett.plotpath + 'temp/'

;Get actual times from COMSOL output
ctime = ctemp.time + 12d

;Filled circle symbol
symbol_arr = FINDGEN(17) * (!PI*2/16.)
usersym, cos(symbol_arr), sin(symbol_arr), thick=0.5

;Plot settings for stripcharts
xstart = 0.06
xend   = 0.99
yspace = 0.94
ybuf   = 0.01

;---Instrument Plots---------------------------------

;Trim Flight Data
sel  = where(strmatch(t.abbr,'OBB?'),ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

;--stripchart
plotfile='inst_stripchart.eps'
mkeps,name=sett.plotpath +'temp/'+ plotfile,aspect=2.5
!P.Multi = [0, 1, ntemp]
dy = yspace / ntemp

for i=0,ntemp-1 do begin
    ystart = 1 - (i+1) * dy
    yend   = ystart + dy - ybuf
    position = [xstart,ystart,xend,yend]
    xtickname = replicate(' ',10)
    if i eq ntemp-1 then xtickname=''
    xtitle=''
    if i eq ntemp-1 then xtitle='Time [hrs]'
    plot,time,ftemp[i,*],ytitle=abbr[i]+' [C]',thick=2,charthick=2,xthick=2,ythick=2,$
        position=position,xtickname=xtickname,xtitle=xtitle,/xs
    
    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,psym=8
    endif
endfor

mkeps,/close
!P.Multi = 0
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;--Combined Plot
plotfile='inst.eps'
mkeps,name= sett.plotpath +'temp/'+ plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot, symbols
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-40,40],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
    endif
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+'temp/'+plotfile


;---Primary Plots---------------------------------

;Trim Flight Data
sel  = where( (t.location eq 'Primary') AND (t.abbr NE 'MTR1') ,ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

;--stripchart
plotfile='primary_stripchart.eps'
mkeps,name=sett.plotpath +'temp/'+ plotfile,aspect=2.5
!P.Multi = [0, 1, ntemp]
dy = yspace / ntemp

for i=0,ntemp-1 do begin
    ystart = 1 - (i+1) * dy
    yend   = ystart + dy - ybuf
    position = [xstart,ystart,xend,yend]
    xtickname = replicate(' ',10)
    if i eq ntemp-1 then xtickname=''
    xtitle=''
    if i eq ntemp-1 then xtitle='Time [hrs]'
    plot,time,ftemp[i,*],ytitle=abbr[i]+' [C]',yrange=[-20,30],thick=2,charthick=2,xthick=2,ythick=2,$
        position=position,xtickname=xtickname,xtitle=xtitle,/xs
    
    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,psym=8
    endif
endfor

mkeps,/close
!P.Multi = 0
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;--Combined Plot
plotfile='primary.eps'
mkeps,name= sett.plotpath +'temp/'+ plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot, symbols
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-20,30],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
    endif
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+'temp/'+plotfile


;---Truss Plots---------------------------------

;Trim Flight Data
sel  = where(t.location eq 'Truss',ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

;--stripchart
plotfile='truss_stripchart.eps'
mkeps,name=sett.plotpath +'temp/'+ plotfile,aspect=2.5
!P.Multi = [0, 1, ntemp]
dy = yspace / ntemp

for i=0,ntemp-1 do begin
    ystart = 1 - (i+1) * dy
    yend   = ystart + dy - ybuf
    position = [xstart,ystart,xend,yend]
    xtickname = replicate(' ',10)
    if i eq ntemp-1 then xtickname=''
    xtitle=''
    if i eq ntemp-1 then xtitle='Time [hrs]'
    plot,time,ftemp[i,*],ytitle=abbr[i]+' [C]',thick=2,charthick=2,xthick=2,ythick=2,$
        position=position,xtickname=xtickname,xtitle=xtitle,/xs
    
    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,psym=8
    endif
endfor

mkeps,/close
!P.Multi = 0
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;--Combined Plot
plotfile='truss.eps'
mkeps,name= sett.plotpath +'temp/'+ plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-60,30],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)))
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
    endif
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;---Secondary Plots---------------------------------

;Trim Flight Data
sel  = where( strmatch(t.abbr,'M2??') ,ntemp)
ss   = sort(t[sel].abbr)
sel  = sel[ss]
ftemp = adc_temp[sel,*]
abbr = t[sel].abbr

;--stripchart
plotfile='secondary_stripchart.eps'
mkeps,name=sett.plotpath +'temp/'+ plotfile,aspect=2.5
!P.Multi = [0, 1, ntemp]
dy = yspace / ntemp

for i=0,ntemp-1 do begin
    ystart = 1 - (i+1) * dy
    yend   = ystart + dy - ybuf
    position = [xstart,ystart,xend,yend]
    xtickname = replicate(' ',10)
    if i eq ntemp-1 then xtickname=''
    xtitle=''
    if i eq ntemp-1 then xtitle='Time [hrs]'
    plot,time,ftemp[i,*],ytitle=abbr[i]+' [C]',thick=2,charthick=2,xthick=2,ythick=2,$
        position=position,xtickname=xtickname,xtitle=xtitle,/xs
    
    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,psym=8
    endif
endfor

mkeps,/close
!P.Multi = 0
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;--Combined Plot
plotfile='secondary.eps'
mkeps,name= sett.plotpath +'temp/'+ plotfile
color=bytscl(dindgen(ntemp),top=254)
loadct,39

;Initialize Plot, symbols
plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],yrange=[-50,30],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

;Loop over key values
for i=0,ntemp-1 do begin
    ;Plot Remainder of flight data
    oplot,time,ftemp[i,*],color=color[i],thick = 0.5

    ;Match tag to structure
    j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
    ;Plot COMSOL Data
    if not keyword_set(flight_only) then begin
        if ncomsol eq 1 then $
        oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
    endif
endfor

cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
mkeps,/close
print,'Wrote: '+sett.plotpath+'temp/'+plotfile

;---Search Plot-------------------------------------------

if keyword_set(search) then begin
    if not strmatch(search, '????') then print, 'Search not set to 4 character string' else begin
    
    filename = search.Replace('*','x')

    ;Trim Flight Data
    sel  = where( strmatch(t.abbr,search) ,ntemp)
    ss   = sort(t[sel].abbr)
    sel  = sel[ss]
    ftemp = adc_temp[sel,*]
    abbr = t[sel].abbr

    ;--stripchart
    plotfile= filename + '_stripchart.eps'
    mkeps,name=sett.plotpath +'temp/'+ plotfile,aspect=2.5
    !P.Multi = [0, 1, ntemp]
    dy = yspace / ntemp

    for i=0,ntemp-1 do begin
        ystart = 1 - (i+1) * dy
        yend   = ystart + dy - ybuf
        position = [xstart,ystart,xend,yend]
        xtickname = replicate(' ',10)
        if i eq ntemp-1 then xtickname=''
        xtitle=''
        if i eq ntemp-1 then xtitle='Time [hrs]'
        plot,time,ftemp[i,*],ytitle=abbr[i]+' [C]',thick=2,charthick=2,xthick=2,ythick=2,$
            position=position,xtickname=xtickname,xtitle=xtitle,/xs
        
        ;Match tag to structure
        j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
        ;Plot COMSOL Data
        if not keyword_set(flight_only) then begin
            if ncomsol eq 1 then $
            oplot,ctime, ctemp.(j)-273.15,psym=8
        endif
    endfor

    mkeps,/close
    !P.Multi = 0
    print,'Wrote: '+sett.plotpath+'temp/'+plotfile

    ;--Combined Plot
    plotfile= filename + '.eps'
    mkeps,name= sett.plotpath +'temp/'+ plotfile
    color=bytscl(dindgen(ntemp),top=254)
    loadct,39

    ;Initialize Plot, symbols
    plot,time,ftemp[0,*],position=[0.12,0.12,0.84,0.94],/xs,/ys,xtitle='Time [hrs]',ytitle='Temperature [C]'

    ;Loop over key values
    for i=0,ntemp-1 do begin
        ;Plot Remainder of flight data
        oplot,time,ftemp[i,*],color=color[i],thick = 0.5

        ;Match tag to structure
        j = where(tag_names(ctemp) eq strupcase(strtrim(strjoin(strsplit(abbr[i],'-',/EXTRACT)),2)),ncomsol)
        ;Plot COMSOL Data
        if not keyword_set(flight_only) then begin
            if ncomsol eq 1 then $
            oplot,ctime, ctemp.(j)-273.15,color=color[i],psym=8
        endif
    endfor

    cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
    mkeps,/close
    print,'Wrote: '+sett.plotpath+'temp/'+plotfile

    endelse

endif

end