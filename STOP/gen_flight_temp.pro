pro gen_flight_temp, start_time, stop_time, interval, label = label, celsius = celsius, all = all
  compile_opt idl2
  ; ------------------------------------------------
  ; Generates a list of temperatures from flight 1 data for some time window
  ; ------------------------------------------------
  ; Inputs
  ; start_time - time to start recording
  ; stop_time - time to stop recording
  ; interval - time interval to record to sheet

  ; Keywords
  ; label - set to output sensor names in headers instead of Thermal Desktop Measure Key
  ; (Easier to read and debug table, but will not be readable as a dlc!)

  ; Settings block
  sett = e2e_load_settings()

  ; Restore flight data from picctest
  restore, sett.path + 'data/flight/picture_c1_temp_data.idl'

  ; Read in measure file
  measure_file = sett.tdpath + 'tsense_data/tsense_f5.txt'
  key_arr = read_td_measure(measure_file)

  ; Make array of time points fit to output times
  n_points = ceil((stop_time - start_time) / interval + 1)
  points = dindgen(n_points, start = start_time, increment = interval)

  t_list = intarr(n_points)
  for i = 0, n_points - 1 do begin
    tmp = min(abs(time - points[i]), ind)
    t_list[i] = ind
  endfor

  ; Find total number of time points in interval, make index list
  total_points = t_list[n_points - 1] - t_list[0]
  full_t_list = indgen(total_points, start = t_list[0])

  ; make output struct (TODO: Make dynamic from measure file?)
  tmp = {time: 0d, $
    m2Gl: 0d, $
    obm1: 0d, $
    obm2: 0d, $
    hex: 0d, $
    obm3: 0d, $
    m1B: 0d, $
    m1G: 0d, $
    m1P2: 0d, $
    t45: 0d, $
    t44: 0d, $
    t43: 0d, $
    t42: 0d, $
    t41: 0d, $
    t35: 0d, $
    t34: 0d, $
    t33: 0d, $
    t32: 0d, $
    t31: 0d, $
    m1P3: 0d, $
    m1P1: 0d, $
    t25: 0d, $
    t24: 0d, $
    t23: 0d, $
    t22: 0d, $
    t21: 0d, $
    t15: 0d, $
    t14: 0d, $
    t13: 0d, $
    t12: 0d, $
    t11: 0d, $
    obb1: 0d, $
    obb2: 0d, $
    obb3: 0d $
    }

  out = replicate(tmp, n_points)
  linout = replicate(tmp, n_points)
  fullout = replicate(tmp, total_points)

  ; Get tag names
  flight_tags = strarr(n_elements(t.abbr))
  for i = 0, n_elements(t.abbr) - 1 do begin
    flight_tags[i] = strjoin(strsplit(t[i].abbr, '-', /extract))
  endfor
  newtags = tag_names(tmp)

  ; Fill output
  n_abbr = n_elements(key_arr[*, 0])
  out.time = time[t_list]
  linout.time = time[t_list]
  fullout.time = time[full_t_list]

  for j = 1, n_abbr do begin
    sel = where(strmatch(flight_tags, newtags[j]))

    ; If theres no perfect match, average over the numbered sensors with the same name
    if not keyword_set(celsius) then t_adj = 273.15 else t_adj = 0

    if sel le 0 then begin
      string2 = newtags[j].substring(0, 2) + '?'
      sel = where(strmatch(flight_tags, string2))
      tmp = mean(adc_temp[sel, *], dimension = 1, /double)
      out.(j) = reform(tmp[t_list]) + t_adj
    endif else begin
      ind = fix(sel[0])
      out.(j) = reform(adc_temp[ind, t_list]) + t_adj
    endelse
  endfor

  ; fix time formatting for filename
  t1 = strjoin(strsplit(n2s(start_time, format = '(F5.2)'), '.', /extract))
  t2 = strjoin(strsplit(n2s(stop_time, format = '(F5.2)'), '.', /extract))

  ; write to csv
  filename = 'tvals_' + t1 + '_' + t2 + '.csv'
  check_and_mkdir, sett.outpath + 'temp/'

  openw, 1, sett.outpath + 'temp/' + filename
  write_ttable, 1, out, key_arr, label = label
  close, 1
  print, 'Wrote: ' + filename

  ; ;Regression for ANSYS linear temps
  tarr = out.time
  tmp = dblarr(n_points)

  for j = 1, n_abbr do begin
    ; Fit to line
    reg = linfit(tarr, out.(j))

    ; use linfit to generate new temps
    for i = 0, n_points - 1 do begin
      tmp[i] = reg[0] + reg[1] * tarr[i]
    endfor

    ; write to struct
    linout.(j) = tmp
  endfor

  ; write out
  filename = 'tvals_' + t1 + '_' + t2 + '_linear.csv'

  openw, 1, sett.outpath + 'temp/' + filename
  write_ttable, 1, linout, key_arr, label = label
  close, 1
  print, 'Wrote: ' + filename

  if keyword_set(all) then begin
    for j = 1, n_abbr do begin
      sel = where(strmatch(flight_tags, newtags[j]))

      ; If theres no perfect match, average over the numbered sensors with the same name
      if not keyword_set(celsius) then t_adj = 273.15 else t_adj = 0

      if sel le 0 then begin
        string2 = newtags[j].substring(0, 2) + '?'
        sel = where(strmatch(flight_tags, string2))
        tmp = mean(adc_temp[sel, *], dimension = 1, /double)
        fullout.(j) = reform(tmp[full_t_list]) + t_adj
      endif else begin
        ind = fix(sel[0])
        fullout.(j) = reform(adc_temp[ind, full_t_list]) + t_adj
      endelse
    endfor

    ; fix time formatting for filename
    t1 = strjoin(strsplit(n2s(start_time, format = '(F5.2)'), '.', /extract))
    t2 = strjoin(strsplit(n2s(stop_time, format = '(F5.2)'), '.', /extract))

    ; write to csv
    filename = 'tvals_' + t1 + '_' + t2 + '_all.csv'
    check_and_mkdir, sett.outpath + 'temp/'

    openw, 1, sett.outpath + 'temp/' + filename
    write_ttable, 1, fullout, key_arr, label = label
    close, 1
    print, 'Wrote: ' + filename
  endif
end
