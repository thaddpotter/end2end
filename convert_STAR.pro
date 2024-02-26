pro rr_STAR, file, unit
  compile_opt idl2

  mtoin = 1 / 0.0254d

  ; Read in data from file
  readcol, file, x, y, z, dx, dy, dz, format = 'D,D,D,D,D,D'

  ; Convert units
  x *= mtoin
  y *= mtoin
  z *= mtoin
  dx *= mtoin
  dy *= mtoin
  dz *= mtoin
  nlines = n_elements(x)

  ; Open File
  openw, unit, file

  for i = 0, nlines - 1 do begin
    printf, 1, x[i], y[i], z[i], dx[i], dy[i], dz[i], format = '(6(D16.12,TR1))'
  endfor

  close, unit
  print, 'Converted: ' + file
end

pro convert_STAR
  compile_opt idl2
  sett = e2e_load_settings()

  basepath = sett.tdpath + 'ansys/STAR/Flight1_'
  time = ['AM', 'PM']
  optic = ['M1', 'M2', 'M3', 'LODM', 'Dicro', 'OAP1', 'OAP2', 'BMC', 'OAP3', 'OAP4']
  nsteps = 8

  for k = 0, n_elements(time) - 1 do begin
    for j = 0, n_elements(optic) - 1 do begin
      for i = 5, nsteps do begin
        rr_STAR, basepath + time[k] + n2s(i) + '_' + optic[j] + '.txt', 1
      endfor
    endfor
  endfor
end