pro plot_temp_comsol, filename, key=key, flight_only=flight_only, model_only=model_only, start=start

;Plots flight 1 data and COMSOL simulation temperature data for comparison
;The majority of this code is adapted from plot_flight_temp.pro in the picctest repository

;Arguments:


;Outputs:
;generates postscript plots for different parts of the instrument

;Keywords:
;oldkey - flag for old list of subscripts (use for backwards compatibility with previous COMSOL models)
;flight_only - only plot flight data
;model_only - only plot model points (NOT IMPLEMENTED)
;cross - a four character string which will be used to filter the temperature sensor keys for a final plot
;   example (cross = 'T1**')

;---Startup-------------------------------------

;Load Settings block
sett = e2e_load_settings()

;Restore flight data from picctest
restore, 'data/flight/temp_data.idl'

;Read COMSOL output file to structure
ctemp = read_comsol_temp('data/temp/'+filename, key)

tmp = strsplit(filename,'_',/extract)
tmp = strjoin(tmp[1:n_elements(tmp)-1],'_')
tmp = strsplit(tmp,'.',/extract)

check_and_mkdir, sett.plotpath + 'temp/' + tmp[0]

;Get actual times from COMSOL output
if not keyword_set(start) then start = 14
ctime = ctemp.time + start

;Filled circle symbol
symbol_arr = FINDGEN(17) * (!PI*2/16.)
usersym, cos(symbol_arr), sin(symbol_arr), thick=0.5

;Plot settings for stripcharts
xstart = 0.06
xend   = 0.99
yspace = 0.94
ybuf   = 0.01

cross = ['T1**','T2**','T**1','T**5']
prefix = ['inst','M1','Truss','M2']
stb = ['STB1','STB2','STB3','STB4']

;---Standard Plots---------------------------------

foreach element, prefix, ind do begin

    case ind of
        0: sel  = where(strmatch(t.abbr,'OBB?') or strmatch(t.abbr,'OBM?'),ntemp)   ;Inst
        1: sel  = where( (t.location eq 'Primary') AND (t.abbr NE 'MTR1') ,ntemp)   ;M1
        2: sel  = where(t.location eq 'Truss' and not strmatch(t.abbr, 'OBM*'),ntemp)  ;Truss
        3: sel  = where( strmatch(t.abbr,'M2??') ,ntemp)
    endcase

    ;Trim Flight Data
    ss   = sort(t[sel].abbr)
    sel  = sel[ss]
    ftemp = adc_temp[sel,*]
    abbr = t[sel].abbr

    ;--stripchart
    plotfile= element + '_stripchart.eps'
    mkeps,name=sett.plotpath +'temp/'+ tmp[0] + '/' + plotfile,aspect=2.5
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
    print,'Wrote: '+sett.plotpath+'temp/'+tmp[0] + '/' +plotfile

    ;--Combined Plot
    plotfile= element + '.eps'
    mkeps,name= sett.plotpath +'temp/'+ tmp[0] + '/' + plotfile
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
    print,'Wrote: '+sett.plotpath+'temp/'+tmp[0] + '/' +plotfile

endforeach

;---Search Plots-------------------------------------------

foreach element, cross, ind do begin
    
    filename = element.Replace('*','x')

    ;Trim Flight Data
    sel  = where( strmatch(t.abbr,element) ,ntemp)
    ss   = sort(t[sel].abbr)
    sel  = sel[ss]
    ftemp = adc_temp[sel,*]
    abbr = t[sel].abbr

    ;--stripchart
    plotfile= filename + '_stripchart.eps'
    mkeps,name=sett.plotpath +'temp/'+ tmp[0] + '/' +plotfile,aspect=2.5
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
    print,'Wrote: '+sett.plotpath+'temp/'+tmp[0] + '/' +plotfile

    ;--Combined Plot
    plotfile= filename + '.eps'
    mkeps,name= sett.plotpath +'temp/'+ tmp[0] + '/' +plotfile

    if element eq 'T**5' then $
        color=bytscl(dindgen(ntemp+4),top=254) else $
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

    if element eq 'T**5' then begin
        for i = 0,3 do begin
            j = where(tag_names(ctemp) eq 'STB'+n2s(i+1))
            oplot,ctime, ctemp.(j)-273.15,color=color[i+ntemp],psym=4
        endfor
    endif

    if element eq 'T**5' then $
        cbmlegend,[abbr,stb],intarr(ntemp+4),color,[0.845,0.94],linsize=0.5 else $
        cbmlegend,abbr,intarr(ntemp),color,[0.845,0.94],linsize=0.5
    mkeps,/close
    print,'Wrote: '+sett.plotpath+'temp/'+tmp[0] + '/' +plotfile

endforeach
    stop
    
end