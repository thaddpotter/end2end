pro convert_displacements_3pt, reread = reread
  compile_opt idl2
  sett = e2e_load_settings()

  ; Path and tag setup
  part_tags = ['M1', 'M2', 'OPT']
  time_tags = ['am', 'pm']
  basepath = sett.tdpath + 'ansys/data_export/'
  ntimes = n_elements(time_tags)
  nsteps = 8
  data_file = sett.datapath + 'stop/ANSYS_disp.idl'

  plotdir = sett.plotpath + 'ansys/'
  check_and_mkdir, plotdir

  ; Zemax Mapping parameters
  osize = 0.00 ; Fractional Oversize for Sag Grid (1% adds ~ 2.5 radial pxls)
  npoints = 512 ; Number of points on sag grid
  r = 254 ; How many radial pixels to keep for final output (Trims ~0.4% per pxl less than 256)
  unitflag = 2 ; 0 for mm, 1 for cm, 2 for in, 3 for m

  ; note: Units for prescription and others must be the same!

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
    [-11.85, 16d, conic_z(-11.85, 16, m1roc, m1conic)], $
    [0d, 27.8d, conic_z(0, 27.8, m1roc, m1conic)], $
    [0d, 4.325d, conic_z(0, 4.325, m1roc, m1conic)]]
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
  print, ''

  ; Calculate the coordinate conversion
  m1_test = [m1_struct[0].cx, m1_struct[0].cy, m1_struct[0].cz]
  m2_test = [m2_struct[0].cx, m2_struct[0].cy, m2_struct[0].cz]
  opt_test = [opt_struct[0].cx, opt_struct[0].cy, opt_struct[0].cz]

  m1_shift = calc_frameshift(m1_test, m1_control, /flag)
  m2_shift = calc_frameshift(m2_test, m2_control, /flag)
  opt_shift = calc_frameshift(opt_test, opt_control, $
    guess = [-50, 170, 0, 0.1, 0.1, 0.1], /flag)

  ; Convert position and displacement data to local frame
  ; Assuming that the structures have the same number of time points here...
  ;
  ; Structure is a bit annoying to use at this point, so getting an array of
  ; initial coordinates for each optic, and making an array of displacements
  ; through time
  m1_points = n_elements(m1_struct[0].x)
  m2_points = n_elements(m2_struct[0].x)
  opt_points = n_elements(opt_struct[0].x)
  tsteps = n_elements(m1_struct)

  ; Initial points in Zemax Initial Frame
  m1_init = apply_shift([m1_struct[0].x, m1_struct[0].y, m1_struct[0].z], m1_shift[0 : 5], /flag)
  m2_init = apply_shift([m2_struct[0].x, m2_struct[0].y, m2_struct[0].z], m2_shift[0 : 5], /flag)
  opt_init = apply_shift([opt_struct[0].x, opt_struct[0].y, opt_struct[0].z], opt_shift[0 : 5], /flag)

  ; Displaced points in Zemax Initial Frame
  m1_disp = dblarr(3, m1_points, tsteps)
  m2_disp = dblarr(3, m2_points, tsteps)
  opt_disp = dblarr(3, opt_points, tsteps)

  print, 'M1 displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
  print, m1_shift, format = '(6F8.3, F10.2)'
  print, 'M2 displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
  print, m2_shift, format = '(6F8.3, F10.2)'
  print, 'Optical bench displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
  print, opt_shift, format = '(6F8.3, F10.2)'
  print, ''

  for i = 0, tsteps - 1 do begin
    ; Apply displacements
    m1_tmp = [m1_struct[i].x + m1_struct[i].dx, $
      m1_struct[i].y + m1_struct[i].dy, $
      m1_struct[i].z + m1_struct[i].dz]
    m2_tmp = [m2_struct[i].x + m2_struct[i].dx, $
      m2_struct[i].y + m2_struct[i].dy, $
      m2_struct[i].z + m2_struct[i].dz]
    opt_tmp = [opt_struct[i].x + opt_struct[i].dx, $
      opt_struct[i].y + opt_struct[i].dy, $
      opt_struct[i].z + opt_struct[i].dz]

    ; Apply shift
    m1_disp[*, *, i] = apply_shift(m1_tmp, m1_shift[0 : 5], /flag)
    m2_disp[*, *, i] = apply_shift(m2_tmp, m2_shift[0 : 5], /flag)
    opt_disp[*, *, i] = apply_shift(opt_tmp, opt_shift[0 : 5], /flag)
  endfor

  ; ----------------------------------------------------------------------
  ; Calculate Displacement data in the local frame
  ; ----------------------------------------------------------------------
  ;
  ; With all the points in the correct reference frame, now we need to apply
  ; the displacements over time and get the transformation that was applied to
  ; get there
  ;
  ;
  ;

  ; First, get three points on the surface (index from the initial coordinates):
  xi = m1_init[0, *]
  yi = m1_init[1, *]
  zi = m1_init[2, *]

  p1 = min((xi - mean(xi)) ^ 2 + (yi - mean(yi)) ^ 2, ind1) ; Closest to average
  p2 = min((xi - max(xi)) ^ 2, ind2) ; Max x
  p3 = min((yi - max(yi)) ^ 2, ind3) ; max y

  ; Transformation parameters from the nominal to displaced frame
  m1_err = dblarr(n_elements(m1_shift), tsteps)

  ; Output redisuals
  m1_res = dblarr(3, m1_points, tsteps)

  ; Point array to fit on
  start_m1 = dblarr(3, 3)
  fin_m1 = start_m1
  start_m1[*, 0] = m1_init[*, ind1]
  start_m1[*, 1] = m1_init[*, ind2]
  start_m1[*, 2] = m1_init[*, ind3]

  ; Convert these three points int a set of basis vectors
  m1_initcoords = get_basis(start_m1)

  for i = 0, tsteps - 1 do begin
    ; Get displaced points for this timestep
    fin_m1[*, 0] = m1_disp[*, ind1, i]
    fin_m1[*, 1] = m1_disp[*, ind2, i]
    fin_m1[*, 2] = m1_disp[*, ind3, i]

    ; Convert to basis vectors
    m1_fincoords = get_basis(fin_m1)

    ; Calc Rotation Angles
    ext_rot = m1_fincoords ## transpose(m1_initcoords)
    matrix_to_angles, ext_rot, tx, ty, tz

    translate = fin_m1[*, 0] - start_m1[*, 0]

    ; Record Translation Parameters
    m1_err[*, i] = [tx / !dtor, ty / !dtor, tz / !dtor, translate, 0]

    ; Get residuals
    m1_res[*, *, i] = apply_shift(identity(3), m1_err[0 : 5, i], /nomove, /rev) # (m1_disp[*, *, i] - apply_shift(m1_init, m1_err[0 : 5, i]))
  endfor

  print, 'Average M1 displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) | '
  print, mean(m1_err, dimension = 2), format = '(6F8.3, F10.2)'
  print, 'RMS Residual: ', 1e6 * mean(sqrt(total(m1_res ^ 2, 1))), ' um'

  ; --------------------------------------------------------------------
  ; Interpolate and Calculate Sag Surface
  ; --------------------------------------------------------------------
  ; We want to get a map of z errors over the aperture, but we currently have:
  ; x, y, and z displacements
  ; To get rid of the x and y replacements without relying on the accuracy of
  ; the map of ANSYS global to Zemax local, we have an intermediate
  ; interpolation

  ; Get center of output grids
  m1_c = [mean(m1_init[0, *]), mean(m1_init[1, *])]

  ; edge effects in zemax are bad, so oversize the extrapolation area for the optical surfaces
  m1_xlim = m1_c[0] + (1 + osize) * [min(m1_init[0, *] - m1_c[0]), $
    max(m1_init[0, *]) - m1_c[0]]
  m1_ylim = m1_c[1] + (1 + osize) * [min(m1_init[1, *] - m1_c[1]), $
    max(m1_init[1, *]) - m1_c[1]]

  m1_xstep = (m1_xlim[1] - m1_xlim[0]) / (npoints - 1)
  m1_ystep = (m1_ylim[1] - m1_ylim[0]) / (npoints - 1)

  m1_x = dindgen(npoints, start = m1_xlim[0], increment = m1_xstep)
  m1_y = dindgen(npoints, start = m1_ylim[0], increment = m1_ystep)

  ; Output: Regularly gridded map of z errors over the aperture
  m1_sag = dblarr(npoints, npoints, tsteps)

  ; Make aperture mask for saggrid
  xyimage, npoints, npoints, xim, yim, rim, /quadrant
  masksel = where((rim lt r), complement = nmasksel)
  mask = 0 * rim
  mask[masksel] = 1

  print, 'Calculating Surface Error maps...'
  ; for i = 0, tsteps - 1 do begin
  i = 0
  counter, i + 1, tsteps, 'Timestep '
  ; Create a representation of the surface with residuals applied, and interpolate those heights onto the initial x,y values
  ; Note, in the displaced frame, the reference surface is at the same place
  m1_zprime = ineff_interp(m1_init + m1_res[*, *, i], m1_init)

  ; Interpolate new z errors onto a regular grid
  triangulate, m1_init[0, *], m1_init[1, *], m1_tr, m1_b

  ; Get sag surfaces in microns
  m1_sag[*, *, i] = trigrid(m1_init[0, *], m1_init[1, *], $
    1e6 * (m1_zprime - m1_init[2, *]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)

  ; what if we dont do the interp?
  m1_zout = trigrid(m1_init[0, *], m1_init[1, *], $
    1e6 * (m1_res[2, *]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)

  ; and what do the x and y shifts look like?
  m1_xout = trigrid(m1_init[0, *], m1_init[1, *], $
    1e6 * (m1_res[0, *]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)
  m1_yout = trigrid(m1_init[0, *], m1_init[1, *], $
    1e6 * (m1_res[1, *]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)

  ; What if instead, we subtract all residual TTP?
  nz = 24
  m1_fitmap = zernike_fit_aperture(m1_zout, mask, nz, zernike_cf = mapcf)

  ttpmap = m1_zout
  ttpmap -= mapcf[0] * ZERNIKE_APERTURE(1, mask)
  ttpmap -= mapcf[1] * ZERNIKE_APERTURE(2, mask)
  ttpmap -= mapcf[2] * ZERNIKE_APERTURE(3, mask)
  ; --------------------------------------------------------------------
  ; Make plots
  ; -------------------------------------------------------------------
  ;
  ;

  ; M1
  plotfile = plotdir + 'M1_Rawx_' + n2s(i)
  implot, m1_xout, plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Raw X Residuals'

  plotfile = plotdir + 'M1_Rawy_' + n2s(i)
  implot, m1_yout, plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Raw Y Residuals'

  plotfile = plotdir + 'M1_Rawz_' + n2s(i)
  implot, m1_zout, plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Raw Z Residuals'

  plotfile = plotdir + 'M1_zinterp_' + n2s(i)
  implot, m1_sag[*, *, i], plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Interpolated Z Residuals'

  plotfile = plotdir + 'M1_zernike_' + n2s(i)
  implot, m1_fitmap, plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Zernike fit of Raw Z'

  plotfile = plotdir + 'M1_TTP_' + n2s(i)
  implot, ttpmap, plotfile, cbtitle = 'um', ncolor = 255, $
    blackout = nmasksel, title = 'Raw Z Residual, TTP Subtracted'

  print, ''
  print, 'DONE'
  print, ''
  ; endfor
  stop
end
