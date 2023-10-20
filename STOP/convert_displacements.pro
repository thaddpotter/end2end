; Documentation
pro convert_displacements
  ; Startup

  compile_opt idl2
  sett = e2e_load_settings()

  ; Path and tag setup
  part_tags = ['M1', 'M2', 'OPT']
  time_tags = ['am', 'pm']
  basepath = sett.tdpath + 'ansys/data_export/'
  ntimes = n_elements(time_tags)
  nsteps = 8

  ; ----------------------------------------------------------------
  ; Read Data into Structures
  ; ----------------------------------------------------------------
  print, 'Reading Data From: ' + basepath

  ; Fill M1 Struct
  ; Loop over windows
  for j = 0, ntimes - 1 do begin
    ; Loop over time steps
    for k = 1, nsteps do begin
      file = basepath + part_tags[0] + '_' + time_tags[j] + n2s(k) + '.out'
      if file_test(file) then begin
        tmp = read_displacements(file)
        ; If Data struct exists, set equal to tmp, else concatenate
        if not isa(m1_struct) then $
          m1_struct = tmp else $
          m1_struct = [m1_struct, tmp]
      endif
    endfor
  endfor

  ; Fill M2 Struct
  ; Loop over windows
  for j = 0, ntimes - 1 do begin
    ; Loop over time steps
    for k = 1, nsteps do begin
      file = basepath + part_tags[1] + '_' + time_tags[j] + n2s(k) + '.out'
      if file_test(file) then begin
        tmp = read_displacements(file)
        ; If Data struct exists, set equal to tmp, else concatenate
        if not isa(m2_struct) then $
          m2_struct = tmp else $
          m2_struct = [m2_struct, tmp]
      endif
    endfor
  endfor

  ; Fill OPT Struct
  ; Loop over windows
  for j = 0, ntimes - 1 do begin
    ; Loop over time steps
    for k = 1, nsteps do begin
      file = basepath + part_tags[2] + '_' + time_tags[j] + n2s(k) + '.out'
      if file_test(file) then begin
        tmp = read_displacements(file)
        ; If Data struct exists, set equal to tmp, else concatenate
        if not isa(opt_struct) then $
          opt_struct = tmp else $
          opt_struct = [opt_struct, tmp]
      endif
    endfor
  endfor

  ; -------------------------------------------------------------------
  ; Register Local Coordinate Frames to ANSYS Global
  ; -------------------------------------------------------------------

  m1roc = 120
  m2roc = 20
  m1conic = -1
  m2conic = -0.422335

  m1_control = [[0d, 16d, conic_z(0, 16, m1roc, m1conic)], $
    [-11.85, 16d, conic_z(-11.8, 16, m1roc, m1conic)], $
    [0d, 27.85d, conic_z(0, 27.85, m1roc, m1conic)], $
    [0d, 4.2d, conic_z(0, 4.2, m1roc, m1conic)]]
  m2_control = [[0d, 3.3837d, conic_z(0, 3.3837, m2roc, m2conic)], $
    [0d, 6.1437d, conic_z(0, 6.1437, m2roc, m2conic)], $
    [2.75d, 3.3837d, conic_z(2.75, 3.3837, m2roc, m2conic)], $
    [0d, 0.642d, conic_z(0, 0.642, m2roc, m2conic)]]
  opt_control = [[11d, -2.97d, -20.2d], $
    [11d, -2.97d, 27.8d], $
    [-13d, -2.97d, 27.8d], $
    [-13d, -2.97d, -20.2d]]

  ; Convert to meters
  m1_control *= 0.0254
  m2_control *= 0.0254
  opt_control *= 0.0254

  m1_test = [m1_struct[0].cx, m1_struct[0].cy, m1_struct[0].cz]
  m2_test = [m2_struct[0].cx, m2_struct[0].cy, m2_struct[0].cz]
  opt_test = [opt_struct[0].cx, opt_struct[0].cy, opt_struct[0].cz]

  m1_disp = calc_frameshift(m1_test, m1_control)
  m2_disp = calc_frameshift(m2_test, m2_control)
  opt_disp = calc_frameshift(opt_test, opt_control)

  print, m1_disp
  print, m2_disp
  print, opt_disp

  stop
end