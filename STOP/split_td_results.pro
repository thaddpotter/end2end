pro split_td_results, file,split=split
  compile_opt idl2

  sett = e2e_load_settings()

  ; Open files
  counter = 1
  openr, 1, sett.tdpath + 'ansys/thermal_desktop_export/' + file + '.dat'

  if keyword_set(split) then $
  openw, 2, sett.tdpath + 'ansys/thermal_desktop_export/' + file + '_split' + n2s(counter) + '.dat' else $
  openw,2,sett.tdpath + 'ansys/thermal_desktop_export/' + file + '_split.dat'

  line = ''

  ; Ignore Header
  readf, 1, line

  ; first time line (T=0 not allowed, unlike in TD)
  readf, 1, line
  if strmatch(line, ' 0.*') then printf, 2, 'TIME, 1.' $
  else printf, 2, line

  while not eof(1) do begin
    ; Read in data from initial file
    readf, 1, line
    ; if this line starts a loop: start a new file for output
    if (strmatch(line, '*TIME*')) then begin
      if keyword_set(split) then begin
        close, 2
        print, 'Wrote: ' + file + '_split' + n2s(counter) + '.dat'

        counter++
        openw, 2, sett.tdpath + 'ansys/thermal_desktop_export/' + file + '_split' + n2s(counter) + '.dat'
      endif else printf,2,'solve'
    endif

    ; Print line out to file
    printf, 2, line
  end

  close, 1, 2
  if keyword_set(split) then $
  print, 'Wrote: ' + file + '_split' + n2s(counter) + '.dat' else $
  print, 'Wrote: ' + file + '_split.dat'
end