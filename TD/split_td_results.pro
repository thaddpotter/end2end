pro split_td_results, file
  compile_opt idl2

  sett = e2e_load_settings()

  ; Open files
  openr, 1, sett.tdpath + 'ansys/thermal_desktop_export/' + file + '.dat'
  openw, 2, sett.tdpath + 'ansys/thermal_desktop_export/' + file + '_split.dat'

  line = ''

  ; Print header and first time line (T=0 not allowed, unlike in TD)
  readf, 1, line
  printf, 2, line

  readf, 1, line
  printf, 2, 'TIME, 1.'

  while not eof(1) do begin
    ; Read in data from initial file
    readf, 1, line
    ; if this line starts a loop, add an additional line
    if (strmatch(line, '*TIME*')) then printf, 2, 'solve'

    ; Print line out to file
    printf, 2, line
  end

  printf, 2, '\EOF'

  free_lun, 1, 2
end