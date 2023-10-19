function read_displacements, file
  ; Returns structure!
  compile_opt idl2

  line = ''

  tmp = strsplit(file, '_', /extract)
  tmp = tmp[n_elements(tmp) - 1]
  time = tmp.substring(0, 1)

  openr, 1, file

  ; Read header
  readf, 1, line
  name = line

  readf, 1, line
  tmp = strsplit(line, ' ', /extract)
  tstep = fix(tmp[n_elements(tmp) - 1])

  ; Discard data header lines for control points
  readf, 1, line
  readf, 1, line

  ; Read control point data
  readf, 1, line
  carr = fix(strsplit(line, ' ', /extract), type = 5)

  for i = 1, 3 do begin
    readf, 1, line
    tmp = fix(strsplit(line, ' ', /extract), type = 5)
    carr = [[carr], [tmp]]
  endfor

  ; Discard data header lines for displacement data
  readf, 1, line
  readf, 1, line

  ; Read displacement data
  readf, 1, line
  disparr = fix(strsplit(line, ' ', /extract), type = 5)

  while not eof(1) do begin
    readf, 1, line
    tmp = fix(strsplit(line, ' ', /extract), type = 5)
    disparr = [[disparr], [tmp]]
  endwhile

  close, 1

  ; Write to structure
  struct = {time: time, $
    tstep: tstep, $
    npoints: n_elements(disparr[*, 0]), $
    cx: carr[0, *], $
    cy: carr[1, *], $
    cz: carr[2, *], $
    x: disparr[0, *], $
    y: disparr[1, *], $
    z: disparr[2, *], $
    dx: disparr[3, *], $
    dy: disparr[4, *], $
    dz: disparr[5, *]}

  print, 'READ: ' + file
  return, struct
end