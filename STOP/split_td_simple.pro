pro split_td_simple, split = split, celsius = celsius
  compile_opt idl2

  basepath = '/mnt/c/Users/locsst/Desktop/ansys_smallscale/thermal'

  ; Open file
  counter = 1
  openr, 1, basepath + '.dat'

  if keyword_set(split) then $
    openw, 2, basepath + '_' + n2s(counter) + '.dat' else $
    openw, 2, basepath + '_single.dat'

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
      printf, 2, 'solve'
      if keyword_set(split) then begin
        close, 2
        print, 'Wrote: ' + basepath + '_' + n2s(counter) + '.dat'

        counter++
        openw, 2, basepath + '_' + n2s(counter) + '.dat'
      endif
      ; If this line contains data, check units for output
    endif else begin
      if keyword_set(celsius) then begin
        tmp = strsplit(line, ',', /extract)
        tmp[3] = n2s(double(tmp[3]) - 273.15)
        line = strjoin(tmp, ',')
      endif
    endelse
    ; Print line out to file
    printf, 2, line
  end
  if not keyword_set(split) then printf, 2, 'EOF'

  close, 1, 2
  if keyword_set(split) then $
    print, 'Wrote: ' + basepath + '_' + n2s(counter) + '.dat' else $
    print, 'Wrote: ' + basepath + '_single.dat'
end