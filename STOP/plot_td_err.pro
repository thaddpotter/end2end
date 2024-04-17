pro plot_steady, data_struct, abbr, ftemp, element
  compile_opt idl2
  ; -------------------------------------------------------------------------
  ; Plots individual sensors for steady-state optimization runs in thermal desktop
  ; -------------------------------------------------------------------------

  n = n_elements(data_struct.time)

  j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr, '-', /extract)), 2)))

  ; Color Settings
  color = bytscl(dindgen(2), top = 254)
  loadct, 39

  plot, indgen(n), replicate(ftemp, n), position = [0.12, 0.12, 0.84, 0.94], yrange = minmax(ftemp) + [-30, 20], /xs, /ys, xtitle = 'Iteration', ytitle = 'Temperature [C]', color = color[0], title = element

  oplot, indgen(n), data_struct.(j) - 273.15, color = color[1]

  cbmlegend, ['Flight', 'TD'], intarr(2), color, [0.845, 0.94], linsize = 0.5
end

pro plot_indiv, data_struct, abbr, tt, ftemp, tmin, newinds, element, flight_only = flight_only
  compile_opt idl2
  ; -------------------------------------------------------------------------
  ; Plots individual sensors for transient optimization runs in thermal desktop
  ; Loops over iterations to view progress as the solver runs
  ; -------------------------------------------------------------------------

  ; Trim to fewer transient loops so graph is more readable
  ntemp = max(data_struct.loopct) + 1
  n_loops = 10
  if ntemp gt n_loops then begin
    inc = ntemp / double(n_loops - 1)
    newinds = floor(dindgen(n_loops, increment = inc))
    newinds[n_loops - 1] = ntemp - 1
  endif else begin
    newinds = indgen(ntemp)
  endelse

  ; String array for legend
  leg = strarr(ntemp + 1)
  leg[0] = 'Flight'
  for i = 1, ntemp do leg[i] = 'Iter ' + n2s(i - 1)
  leg = leg[newinds]
  ; Color Settings
  nel = min([n_loops, ntemp])
  color = bytscl(dindgen(nel + 1), top = 254)
  loadct, 39

  ; Initialize Plot, symbols
  plot, tt, ftemp, position = [0.12, 0.12, 0.8, 0.94], yrange = minmax(ftemp) + [-10, 10], /xs, /ys, xtitle = 'Time [hrs]', ytitle = 'Temperature [C]', color = color[0], title = element

  ; Match tag to structure
  j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr, '-', /extract)), 2)), ntd)

  ; Loop over TD iterations

  foreach i, newinds, ind2 do begin
    ; Trim to loop
    tdt = data_struct.time[where(data_struct.loopct eq i)] / 3600d + tmin
    tmp = data_struct.(j)[where(data_struct.loopct eq i)]

    ; Plot TD Data
    if ntd eq 1 then begin
      if not keyword_set(flight_only) then $
        oplot, tdt, tmp - 273.15, color = color[ind2 + 1]
    endif
  endforeach

  cbmlegend, leg, intarr(nel), color, [0.815, 0.92], linsize = 0.5
end

pro plot_groups, t, adc_temp, ftemp, tmin, tmax, data_struct, time, basedir, flight_only = flight_only
  compile_opt idl2
  ; -------------------------------------------------------------------------
  ; Plots groups of sensors for transient optimization runs in thermal desktop
  ; Loops over individual sensors to see related behaviour
  ; -------------------------------------------------------------------------

  prefix = ['Beam_1', 'Beam_2', 'Beam_3', 'Beam_4', 'Rear', 'Bench', 'Kinematic', 'Secondary']

  ; Filled circle symbol
  symbol_arr = findgen(17) * (!pi * 2 / 16.)
  usersym, cos(symbol_arr), sin(symbol_arr), thick = 0.5

  ; Replace Sensors that get averaged
  sel = where(strmatch(t.abbr, 'M1B*') or strmatch(t.abbr, 'M1G*') or strmatch(t.abbr, 'HEX*'), complement = nsel)

  t2 = t[nsel]
  adc2 = adc_temp[nsel, *]

  ; Replace abbr field
  newabbr = [t[nsel].abbr, 'M1B', 'M1G', 'HEX']
  struct_replace_field, t2, 'abbr', newabbr

  ; Add corresponding entries into adc_temp
  sel = where(strmatch(t.abbr, 'M1B*'))
  adc2 = [adc2, transpose(mean(adc_temp[sel, *], dimension = 1, /double))]

  sel = where(strmatch(t.abbr, 'M1G*'))
  adc2 = [adc2, transpose(mean(adc_temp[sel, *], dimension = 1, /double))]

  sel = where(strmatch(t.abbr, 'HEX*'))
  adc2 = [adc2, transpose(mean(adc_temp[sel, *], dimension = 1, /double))]

  ; Cut model data to best iteration (lowest error on last time step)
  sel1 = where(data_struct.time eq max(data_struct.time))
  sel2 = where(data_struct.err[sel1] eq min(data_struct.err[sel1]))
  tmp = data_struct.loopct[sel1]
  bestloop = tmp[sel2]

  sel3 = where(data_struct.loopct eq fix(bestloop[0] + 0.5))

  ; Loop over groups
  foreach element, prefix, ind do begin
    ; Match to flight data
    case ind of
      0: sel = where(strmatch(t2.abbr, 'T1**'), ntemp)
      1: sel = where(strmatch(t2.abbr, 'T2**'), ntemp)
      2: sel = where(strmatch(t2.abbr, 'T3**'), ntemp)
      3: sel = where(strmatch(t2.abbr, 'T4**'), ntemp)
      4: sel = where(strmatch(t2.abbr, 'T**5') or $
        strmatch(t2.abbr, 'M1B') or strmatch(t2.abbr, 'M1G'), ntemp)
      5: sel = where(strmatch(t2.abbr, 'OBB?') or strmatch(t2.abbr, 'OBM?'), ntemp)
      6: sel = where(strmatch(t2.abbr, 'OBM?') or strmatch(t2.abbr, 'T3*2') or $
        strmatch(t2.abbr, 'T3*3') or strmatch(t2.abbr, 'T3*4'), ntemp)
      7: sel = where(strmatch(t2.abbr, 'T3*1') or strmatch(t2.abbr, 'T3*2') or $
        strmatch(t2.abbr, 'M2GL') or strmatch(t2.abbr, 'HEX'), ntemp)
    endcase

    ftemp = adc2[sel, *]
    abbr = t2.abbr[sel]

    ; Trim to correct time
    sel2 = where((time ge tmin) and (time le tmax))
    tt = time[sel2]
    ftemp = ftemp[*, sel2]

    ; Make file
    plotfile = element
    mkeps, basedir + plotfile

    ; Color Settings
    color = bytscl(dindgen(ntemp), top = 254)
    loadct, 39

    ; Initialize Plot, symbols
    plot, tt, ftemp[0, *], position = [0.12, 0.12, 0.8, 0.94], yrange = minmax(ftemp) + [-10, 10], /xs, /ys, xtitle = 'Time [hrs]', ytitle = 'Temperature [C]', color = color[0], title = element + ': Iteration ' + n2s(bestloop)

    ; Get and plot matching model data
    j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr[0], '-', /extract)), 2)), ntd)
    tdt = data_struct.time[sel3] / 3600d + tmin
    tmp = data_struct.(j)[sel3]

    if not keyword_set(flight_only) then oplot, tdt, tmp - 273.15, color = color[0], psym = 8

    ; Loop over sensors
    for i = 1, ntemp - 1 do begin
      ; Plot Flight Data
      oplot, tt, ftemp[i, *], color = color[i]

      ; Get and plot matching model data
      if not keyword_set(flight_only) then begin
        j = where(tag_names(data_struct) eq strupcase(strtrim(strjoin(strsplit(abbr[i], '-', /extract)), 2)), ntd)
        tdt = data_struct.time[sel3] / 3600d + tmin
        tmp = data_struct.(j)[sel3]

        oplot, tdt, tmp - 273.15, color = color[i], psym = 8
      endif
    endfor

    cbmlegend, abbr, intarr(ntemp), color, [0.815, 0.92], linsize = 0.5

    mkeps, /close
    print, 'Wrote: ' + basedir + plotfile
  endforeach
end

pro plot_td_err, day = day, night = night, steady = steady, plotdir = plotdir, flight_only = flight_only
  compile_opt idl2
  ; -----------------------------------------------------------------------------
  ; Plots comparisons of thermal desktop data

  ; Keywords
  ; steady - Flag for if the file being read in is from a steady state optimization
  ; day/night - Flag for time slot
  ; plotdir - directory to save plots to inside end2end/plots/td_(night/day)/
  ; defaults to mm_dd_type_i
  ; ----------------------------------------------------------------------------

  ; Startup
  ; -------------------------------------------------------------------
  sett = e2e_load_settings()

  ; Filepath
  case 1 of
    keyword_set(steady) and keyword_set(day): $
      file = sett.tdpath + 'init_am/correlation_data_am.dlo'
    keyword_set(steady) and keyword_set(night): $
      file = sett.tdpath + 'init_pm/correlation_data_pm.dlo'
    (not keyword_set(steady)) and keyword_set(day): $
      file = sett.tdpath + 'td_am/correlation_data_am.dlo'
    (not keyword_set(steady)) and keyword_set(night): $
      file = sett.tdpath + 'td_pm/correlation_data_pm.dlo'
    else: begin
      print, 'Wrong keyword selection'
    end
  endcase

  meas_file = sett.tdpath + 'tsense_data/tsense_f5.txt'

  ; TD Correlation Data
  data_struct = read_td_corr_dyn(file, measure_file = meas_file, steady = steady)
  ; Flight Data
  restore, sett.path + 'data/flight/picture_c1_temp_data.idl'

  ; Remove '-' from tags
  newtag = strarr(n_elements(t.abbr))
  for i = 0, n_elements(t.abbr) - 1 do begin
    newtag[i] = strjoin(strsplit(t[i].abbr, '-', /extract))
  endfor

  ; Plot settings
  ; --------------------------------------------------------------------

  ; Xlimits
  if keyword_set(day) then begin
    tmin = 13.75
    dir = 'td_day/'
  endif else if keyword_set(night) then begin
    tmin = 22.95
    dir = 'td_night/'
  endif else begin
    print, 'Please specify timeslot'
    stop
  endelse
  tmax = max(data_struct.time) / 3600d + tmin

  ; Directory
  if not keyword_set(plotdir) then begin
    jd = systime(/julian)
    caldat, jd, mon, day
    plotdir = n2s(mon) + '_' + n2s(day) + '_'

    if not keyword_set(steady) then plotdir = plotdir + 'td1' else $
      plotdir = plotdir + '1'

    ; Find lowest unused number for filepath
    i = 2
    while file_test(sett.plotpath + dir + plotdir, /directory) do begin
      plotdir = plotdir.remove(-1)
      plotdir = plotdir + n2s(i)
      i++
    endwhile
  endif

  basedir = sett.plotpath + dir + plotdir + '/'
  check_and_mkdir, basedir

  ; Sensors to iterate over
  prefix = tag_names(data_struct)
  prefix = prefix[2 : n_elements(prefix) - 2]

  ; Loop over sensors
  ; --------------------------------------------------------------------------
  foreach element, prefix do begin
    ; Match to flight data
    sel = where(strmatch(newtag, element))

    ; Trim Flight Data to correct sensor
    if sel le 0 then begin
      ; If theres no perfect match, average over the numbered sensors with the same name
      string2 = element.substring(0, 2) + '?'
      sel = where(strmatch(newtag, string2))
      ss = sort(t[sel].abbr)
      sel = sel[ss]
      ftemp = mean(adc_temp[sel, *], dimension = 1, /double)
      abbr = element
    endif else begin
      ss = sort(t[sel].abbr)
      sel = sel[ss]
      ftemp = adc_temp[sel, *]
      abbr = t[sel].abbr
    endelse

    ; Trim flight data by time
    if keyword_set(steady) then begin
      v = min(abs(time - tmin), sel2)
    endif else begin
      sel2 = where((time ge tmin) and (time le tmax))
      tt = time[sel2]
    endelse
    ftemp = ftemp[sel2]

    ; Plot
    plotfile = element
    mkeps, basedir + plotfile

    ; Plot Steady State
    if keyword_set(steady) then begin
      plot_steady, data_struct, abbr, ftemp, element

      ; Plot Transient
    endif else begin
      plot_indiv, data_struct, abbr, tt, ftemp, tmin, newinds, element, flight_only = flight_only
    endelse

    mkeps, /close
    print, 'Wrote: ' + basedir + plotfile
  endforeach

  ; Make group plots
  if not keyword_set(steady) then $
    plot_groups, t, adc_temp, ftemp, tmin, tmax, data_struct, time, basedir, flight_only = flight_only

  ; Overall error plot for steady state
  if keyword_set(steady) then begin
    plotfile = 'err'
    mkeps, basedir + plotfile
    n = n_elements(data_struct.time)

    plot, indgen(n), data_struct.err, position = [0.12, 0.12, 0.84, 0.94], /xs, /ys, xtitle = 'Iteration', ytitle = 'RMS Error (K)', title = 'Average Error on Initial Temperature Values'

    mkeps, /close
    print, 'Wrote: ' + basedir + plotfile
  endif
end