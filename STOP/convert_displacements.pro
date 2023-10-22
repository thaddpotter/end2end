pro convert_displacements, reread = reread
  ; Startup

  compile_opt idl2
  sett = e2e_load_settings()

  ; Path and tag setup
  part_tags = ['M1', 'M2', 'OPT']
  time_tags = ['am', 'pm']
  basepath = sett.tdpath + 'ansys/data_export/'
  ntimes = n_elements(time_tags)
  nsteps = 8
  data_file = sett.datapath + 'stop/ANSYS_disp.idl'

  ; Other parameters
  osize = 0.05 ; Fractional Oversize for Sag Grid
  ; Size of grid
  npoints = 512 ; Number of points on sag grid
  ; note: Units for prescription and others must be the same!
  unitflag = 2 ; 0 for mm, 1 for cm, 2 for in, 3 for m

  ; ----------------------------------------------------------------
  ; Read Data into Structures
  ; ----------------------------------------------------------------
  if ((not file_test(data_file)) or keyword_set(reread)) then begin
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

    save, m1_struct, m2_struct, opt_struct, filename = data_file
  endif else begin
    print, 'Found existing ANSYS data: ' + n2s(data_file)
    restore, data_file
  endelse
  ; -------------------------------------------------------------------
  ; Register Local Coordinate Frames to ANSYS Global
  ; -------------------------------------------------------------------

  m1roc = 120
  m2roc = 20
  m1conic = -1
  m2conic = -0.422335

  m1_control = [[0d, 16d, conic_z(0, 16, m1roc, m1conic)], $
    [-11.8, 16d, conic_z(-11.8, 16, m1roc, m1conic)], $
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

  print, 'Calculating conversion from ANSYS frame to Zemax Frame...'
  ; Calculate the coordinate conversion
  m1_test = [m1_struct[0].cx, m1_struct[0].cy, m1_struct[0].cz]
  m2_test = [m2_struct[0].cx, m2_struct[0].cy, m2_struct[0].cz]
  opt_test = [opt_struct[0].cx, opt_struct[0].cy, opt_struct[0].cz]

  m1_shift = calc_frameshift(m1_test, m1_control)
  m2_shift = calc_frameshift(m2_test, m2_control)
  opt_shift = calc_frameshift(opt_test, opt_control)

  ; Convert position and displacement data to local frame
  ; Assuming that the structures have the same number of time points here...
  ;
  ; Structure is a bit annoying to use at this point, so getting an array of
  ; initial coordinates for each optic, and making an array of displacements
  ; through time
  ;
  m1_points = n_elements(m1_struct[0].x)
  m2_points = n_elements(m2_struct[0].x)
  opt_points = n_elements(opt_struct[0].x)
  tsteps = n_elements(m1_struct)

  local_m1 = apply_shift([m1_struct[0].x, m1_struct[0].y, m1_struct[0].z], m1_shift[0 : 5])
  local_m2 = apply_shift([m2_struct[0].x, m2_struct[0].y, m2_struct[0].z], m2_shift[0 : 5])
  local_opt = apply_shift([opt_struct[0].x, opt_struct[0].y, opt_struct[0].z], opt_shift[0 : 5])

  locd_m1 = dblarr(3, m1_points, tsteps)
  locd_m2 = dblarr(3, m2_points, tsteps)
  locd_opt = dblarr(3, opt_points, tsteps)

  for i = 0, tsteps - 1 do begin
    disp_m1 = [m1_struct[i].dx, m1_struct[i].dy, m1_struct[i].dz]
    disp_m2 = [m2_struct[i].dx, m2_struct[i].dy, m2_struct[i].dz]
    disp_opt = [opt_struct[i].dx, opt_struct[i].dy, opt_struct[i].dz]

    ; Displacements only need to be rotated
    locd_m1[*, *, i] = apply_shift(disp_m1, m1_shift[0 : 5], /nomove)
    locd_m2[*, *, i] = apply_shift(disp_m2, m2_shift[0 : 5], /nomove)
    locd_opt[*, *, i] = apply_shift(disp_opt, opt_shift[0 : 5], /nomove)
  endfor

  ; ----------------------------------------------------------------------
  ; Calculate Displacement data in the local frame
  ; ----------------------------------------------------------------------
  ;
  ; With all the points in the correct reference frame, now we need to apply
  ; the displacements over time and get the transformation that was applied to
  ; get there
  ;

  ; Transformation parameters from the nominal to displaced frame
  m1_err = dblarr(n_elements(m1_shift), tsteps)
  m2_err = m1_err
  opt_err = m1_err

  ; List of residuals in the displaced frame, with xy coords
  m1_omap = dblarr(3, m1_points, tsteps)
  m2_omap = dblarr(3, m2_points, tsteps)
  opt_omap = dblarr(3, opt_points, tsteps)

  print, 'Calculating Local Displacements of M1, M2, and Opt...'
  for i = 0, tsteps - 1 do begin
    ; Apply displacement
    m1_tmp = local_m1 + locd_m1[*, *, i]
    m2_tmp = local_m2 + locd_m2[*, *, i]
    opt_tmp = local_opt + locd_opt[*, *, i]

    ; Calculate 6-D Displacement
    m1_err[*, i] = calc_frameshift(local_m1, m1_tmp)
    m2_err[*, i] = calc_frameshift(local_m2, m2_tmp)
    opt_err[*, i] = calc_frameshift(local_opt, opt_tmp)

    ; Get Residuals in the displaced frame by:
    ; Getting initial residuals in the initial frame
    ; Rotate to get new unit vectors, and project onto them by matrix multiplication
    m1_res = (m1_tmp - apply_shift(local_m1, m1_err[0 : 5])) ## apply_shift(identity(3), m1_err[0 : 5], /nomove)
    m2_res = (m2_tmp - apply_shift(local_m2, m2_err[0 : 5])) ## apply_shift(identity(3), m2_err[0 : 5], /nomove)
    opt_res = (opt_tmp - apply_shift(local_opt, opt_err[0 : 5])) ## apply_shift(identity(3), opt_err[0 : 5], /nomove)

    ; Apply x,y,z shift to the local frame data
    ; Note: If we rotated the initial coords, then project along the new coordinates,
    ; they will be back where they started!
    m1_omap[*, *, i] = local_m1 + m1_res
    m2_omap[*, *, i] = local_m2 + m2_res
    opt_omap[*, *, i] = local_opt + opt_res

    ; Calculate new z error by subtracting the change in "correct" surface height
    ; from shifting in X and Y
    ; Dont need to do this for the bench, since its flat nominally
    m1_omap[2, *, i] += conic_z(local_m1[0, *], local_m1[1, *], m1roc, m1conic) - $
      conic_z(m1_omap[0, *, i], m1_omap[2, *, i], m1roc, m1conic)
    m2_omap[2, *, i] += conic_z(local_m2[0, *], local_m2[1, *], m2roc, m2conic) - $
      conic_z(m2_omap[0, *, i], m2_omap[2, *, i], m2roc, m2conic)
  endfor

  stop
  ; --------------------------------------------------------------------
  ; Process displacements
  ; --------------------------------------------------------------------
  ; TODO:
  ; Ask Chris about his residual tip-tilt calculations in displacements.pro
  ; Figure out the interpolation calculations
  ; Just use zernike_aperture?
  ;
  ;
  for i = 0, tsteps - 1 do begin
    ; Apply displacement
    m1_tmp = local_m1 + locd_m1[*, *, i]
    m2_tmp = local_m2 + locd_m2[*, *, i]
    opt_tmp = local_opt + locd_opt[*, *, i]

    ; get new bounding rectangle
    m1_x = (1 + osize) * minmax(m1_tmp[0, *, i])
    m2_x = (1 + osize) * minmax(m2_tmp[0, *, i])
    opt_x = (1 + osize) * minmax(opt_tmp[0, *, i])

    m1_y = (1 + osize) * minmax(m1_tmp[1, *, i])
    m2_y = (1 + osize) * minmax(m2_tmp[1, *, i])
    opt_y = (1 + osize) * minmax(opt_tmp[1, *, i])

    triangulate, m1_tmp[0, *, i], m1_tmp[1, *, i], m1_tri, b = m1_bound
    triangulate, m2_tmp[0, *, i], m2_tmp[1, *, i], m2_tri, b = m2_bound
    triangulate, opt_tmp[0, *, i], opt_tmp[1, *, i], opt_tri, b = opt_bound

    ; Interpolate onto regular grid (coord shift for .grd later)
  endfor

  stop
  ; --------------------------------------------------------------------
  ; Write output files, make plots
  ; -------------------------------------------------------------------
  ;
  ; TODO: should I make point maps for mesh, similar to what chris had done?
  ;
  for i = 0, nsteps do begin

  endfor

  stop
end