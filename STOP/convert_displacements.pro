pro convert_displacements, folder, reread = reread, vector = vector, global = global
  compile_opt idl2
  sett = e2e_load_settings()

  ; Path and tag setup
  part_tags = ['M1', 'M2', 'OPT', 'wedge']
  time_tags = ['am', 'pm']
  basepath = sett.tdpath + 'ansys/data_export/'
  ntimes = n_elements(time_tags)
  nsteps = 8

  check_and_mkdir, sett.datapath + 'stop/'
  data_file = sett.datapath + 'stop/' + folder + '_disp.idl'

  folder = strjoin([folder, '/'])
  plotdir = sett.plotpath + 'ansys/' + folder
  check_and_mkdir, plotdir

  outdir = sett.outpath + 'ansys/' + folder
  check_and_mkdir, outdir

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
    print, 'Reading Data From: ' + basepath + folder

    ; Fill M1 Struct
    ; Loop over windows
    for j = 0, ntimes - 1 do begin
      ; Loop over time steps
      for k = 1, nsteps do begin
        file = basepath + folder + part_tags[0] + '_' + time_tags[j] + n2s(k) + '.out'
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
        file = basepath + folder + part_tags[1] + '_' + time_tags[j] + n2s(k) + '.out'
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
        file = basepath + folder + part_tags[2] + '_' + time_tags[j] + n2s(k) + '.out'
        if file_test(file) then begin
          tmp = read_displacements(file)
          ; If Data struct exists, set equal to tmp, else concatenate
          if not isa(opt_struct) then $
            opt_struct = tmp else $
            opt_struct = [opt_struct, tmp]
        endif
      endfor
    endfor

    ; Fill Wedge Struct
    ; Loop over windows
    for j = 0, ntimes - 1 do begin
      ; Loop over time steps
      for k = 1, nsteps do begin
        file = basepath + folder + part_tags[3] + '_' + time_tags[j] + n2s(k) + '.out'
        if file_test(file) then begin
          tmp = read_displacements(file, /wedge)
          ; If Data struct exists, set equal to tmp, else concatenate
          if not isa(wedge_struct) then $
            wedge_struct = tmp else $
            wedge_struct = [wedge_struct, tmp]
        endif
      endfor
    endfor

    if isa(wedge_struct) then $
      save, m1_struct, m2_struct, opt_struct, wedge_struct, filename = data_file else $
      save, m1_struct, m2_struct, opt_struct, filename = data_file
  endif else begin
    print, 'Found existing ANSYS data: ' + n2s(data_file)
    restore, data_file
  endelse

  ; -------------------------------------------------------------------
  ; Remove Bulk motion of the payload as a result of boundary conditions
  ; -------------------------------------------------------------------
  ; Key to wedge? This will remove most of the motion of the primary...
  ;
  ;

  if keyword_set(global) then begin

    



  endif

  ; -------------------------------------------------------------------
  ; Register Local Coordinate Frames to ANSYS Global
  ; -------------------------------------------------------------------
  ; Below are in inches
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

  ; Map wedge onto xy plane
  if isa(wedge_struct) then begin
    wedge_test = [wedge_struct[0].x, wedge_struct[0].y, wedge_struct[0].z]
    wedge_shift = calc_frameshift(wedge_test, wedge_test, /zonly)

    wedge_points = n_elements(wedge_struct[0].x)
    wedge_init = apply_shift([wedge_struct[0].x, wedge_struct[0].y, $
      wedge_struct[0].z], wedge_shift[0 : 5], /nomove)

    wedge_trans = rebin(mean(wedge_init, dimension = 2), 3, wedge_points)
    wedge_init -= wedge_trans

    wedge_disp = dblarr(3, wedge_points, tsteps)
    for i = 0, tsteps - 1 do begin
      ; Apply Displacements
      wedge_tmp = [wedge_struct[0].x + wedge_struct[0].dx, $
        wedge_struct[0].y + wedge_struct[0].dy, $
        wedge_struct[0].z + wedge_struct[0].dz]
      ; Apply Shift
      wedge_disp[*, *, i] = apply_shift(wedge_tmp, wedge_shift[0 : 5], /nomove)
      ; Shift to origin
      wedge_disp[*, *, i] -= wedge_trans
    endfor
  endif

  ; ----------------------------------------------------------------------
  ; Calculate Displacement data in the local frame
  ; ----------------------------------------------------------------------
  ;
  ; With all the points in the correct reference frame, now we need to apply
  ; the displacements over time and get the transformation that was applied to
  ; get there
  ;
  ; Note: in the displaced coordinate frame, the 'perfect' coordinates are the
  ; same as the local coordinates from earlier! (m1,m2,opt_init)

  ; Transformation parameters from the nominal to displaced frame
  m1_err = dblarr(n_elements(m1_shift), tsteps)
  m2_err = m1_err
  opt_err = m1_err

  ; List of residuals in the displaced frame
  m1_res = dblarr(3, m1_points, tsteps)
  m2_res = dblarr(3, m2_points, tsteps)
  opt_res = dblarr(3, opt_points, tsteps)

  print, 'Calculating Thermal Displacements of M1, M2, and Opt...'
  for i = 0, tsteps - 1 do begin
    ; Calculate 6-D Displacement
    m1_err[*, i] = calc_frameshift(m1_init, m1_disp[*, *, i])
    m2_err[*, i] = calc_frameshift(m2_init, m2_disp[*, *, i])
    opt_err[*, i] = calc_frameshift(opt_init, opt_disp[*, *, i])

    ; Get Residuals in the displaced frame by:
    ; Getting initial residuals in the initial frame by subtracting mapped points from total
    ; Reverse rotate to get unit vectors of he new coords, and project the displacements onto them with matrix multiplication
    m1_res[*, *, i] = apply_shift(identity(3), m1_err[0 : 5, i], /nomove, /rev) # (m1_disp[*, *, i] - apply_shift(m1_init, m1_err[0 : 5, i]))

    m2_res[*, *, i] = apply_shift(identity(3), m2_err[0 : 5, i], /nomove, /rev) # (m2_disp[*, *, i] - apply_shift(m2_init, m2_err[0 : 5, i]))

    opt_res[*, *, i] = apply_shift(identity(3), opt_err[0 : 5, i], /nomove, /rev) # (opt_disp[*, *, i] - apply_shift(opt_init, opt_err[0 : 5, i]))
  endfor

  ; When running the standard fit, I tend to get a fair amount of residual tilt in the off-axis direction
  ; After tightening tolerances, I got rid of some of it, but the best way to do this may be to close the loop and try to minimize the low order zernikes in the fit

  print, 'Average M1 displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) | '
  print, mean(m1_err, dimension = 2), format = '(6F8.3, F10.2)'
  print, 'RMS Residual: ', 1e6 * mean(sqrt(total(m1_res ^ 2, 1))), ' um'
  print, 'Average M2 displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
  print, mean(m2_err, dimension = 2), format = '(6F8.3, F10.2)'
  print, 'RMS Residual: ', 1e6 * mean(sqrt(total(m2_res ^ 2, 1))), ' um'
  print, 'Average Optical bench displacement: '
  print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
  print, mean(opt_err, dimension = 2), format = '(6F8.3, F10.2)'
  print, 'RMS Residual: ', 1e6 * mean(sqrt(total(opt_res ^ 2, 1))), ' um'

  ; Repeat for wedge
  if isa(wedge_struct) then begin
    wedge_err = dblarr(n_elements(m1_shift), tsteps)
    wedge_res = dblarr(3, wedge_points, tsteps)
    for i = 0, tsteps - 1 do begin
      wedge_err[*, i] = calc_frameshift(wedge_init, wedge_disp[*, *, i])
      wedge_res[*, *, i] = apply_shift(identity(3), wedge_err[0 : 5, i], /nomove, /rev) # (wedge_disp[*, *, i] - apply_shift(wedge_init, wedge_err[0 : 5, i]))
    endfor
    print, 'Wedge Average Displacement'
    print, '| Theta |  Phi  |  Psi  |   X   |   Y   |   Z   | RMS ERR(um) |'
    print, mean(wedge_err, dimension = 2), format = '(6F8.3, F10.2)'
    print, 'RMS Residual: ', 1e6 * mean(sqrt(total(wedge_res ^ 2, 1))), ' um'
  endif

  print, ''

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
  m2_c = [mean(m2_init[0, *]), mean(m2_init[1, *])]

  ; edge effects in zemax are bad, so oversize the extrapolation area for the optical surfaces
  m1_xlim = m1_c[0] + (1 + osize) * [min(m1_init[0, *] - m1_c[0]), $
    max(m1_init[0, *]) - m1_c[0]]
  m1_ylim = m1_c[1] + (1 + osize) * [min(m1_init[1, *] - m1_c[1]), $
    max(m1_init[1, *]) - m1_c[1]]
  m2_xlim = m2_c[0] + (1 + osize) * [min(m2_init[0, *] - m2_c[0]), $
    max(m2_init[0, *]) - m2_c[0]]
  m2_ylim = m2_c[1] + (1 + osize) * [min(m2_init[1, *] - m2_c[1]), $
    max(m2_init[1, *]) - m2_c[1]]

  m1_xstep = (m1_xlim[1] - m1_xlim[0]) / (npoints - 1)
  m1_ystep = (m1_ylim[1] - m1_ylim[0]) / (npoints - 1)
  m2_xstep = (m2_xlim[1] - m2_xlim[0]) / (npoints - 1)
  m2_ystep = (m2_ylim[1] - m2_ylim[0]) / (npoints - 1)

  m1_x = dindgen(npoints, start = m1_xlim[0], increment = m1_xstep)
  m1_y = dindgen(npoints, start = m1_ylim[0], increment = m1_ystep)
  m2_x = dindgen(npoints, start = m2_xlim[0], increment = m2_xstep)
  m2_y = dindgen(npoints, start = m2_ylim[0], increment = m2_ystep)

  ; Output: Regularly gridded map of z errors over the aperture
  m1_sag = dblarr(npoints, npoints, tsteps)
  m2_sag = dblarr(npoints, npoints, tsteps)

  if isa(wedge_struct) then begin
    wedge_c = [mean(wedge_init[0, *]), mean(wedge_init[1, *])]

    wedge_xlim = wedge_c[0] + (1 + osize) * [min(wedge_init[0, *] - wedge_c[0]), max(wedge_init[0, *]) - wedge_c[0]]
    wedge_ylim = wedge_c[1] + (1 + osize) * [min(wedge_init[1, *] - wedge_c[1]), max(wedge_init[1, *]) - wedge_c[1]]

    wedge_xstep = (wedge_xlim[1] - wedge_xlim[0]) / (npoints - 1)
    wedge_ystep = (wedge_ylim[1] - wedge_ylim[0]) / (npoints - 1)

    wedge_x = dindgen(npoints, start = wedge_xlim[0], increment = wedge_xstep)
    wedge_y = dindgen(npoints, start = wedge_ylim[0], increment = wedge_ystep)
  endif

  ; Make aperture mask for saggrid
  xyimage, npoints, npoints, xim, yim, rim, /quadrant
  masksel = where((rim lt r), complement = nmasksel)
  mask = 0 * rim
  mask[masksel] = 1

  print, 'Calculating Surface Error maps...'
  for i = 0, tsteps - 1 do begin
    counter, i + 1, tsteps, 'Timestep '
    ; Create a representation of the surface with residuals applied, and interpolate those heights onto the initial x,y values
    ; Note, in the displaced frame, the reference surface is at the same place
    m1_zprime = ineff_interp(m1_init + m1_res[*, *, i], m1_init)
    m2_zprime = ineff_interp(m2_init + m2_res[*, *, i], m2_init)

    ; Interpolate new z errors onto a regular grid
    triangulate, m1_init[0, *], m1_init[1, *], m1_tr, m1_b
    triangulate, m2_init[0, *], m2_init[1, *], m2_tr, m2_b

    ; Get sag surfaces in microns
    m1_sag[*, *, i] = trigrid(m1_init[0, *], m1_init[1, *], $
      1e6 * (m1_zprime - m1_init[2, *]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)
    m2_sag[*, *, i] = trigrid(m2_init[0, *], m2_init[1, *], $
      1e6 * (m2_zprime - m2_init[2, *]), m2_tr, extra = m2_b, xout = m2_x, yout = m2_y)

    ; what if we dont do the interp?
    m1_zout = trigrid(m1_init[0, *], m1_init[1, *], $
      1e6 * (m1_res[2, *, i]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)
    m2_zout = trigrid(m2_init[0, *], m2_init[1, *], $
      1e6 * (m2_res[2, *, i]), m2_tr, extra = m2_b, xout = m2_x, yout = m2_y)

    ; and what do the x and y shifts look like?
    m1_xout = trigrid(m1_init[0, *], m1_init[1, *], $
      1e6 * (m1_res[0, *, i]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)
    m2_xout = trigrid(m2_init[0, *], m2_init[1, *], $
      1e6 * (m2_res[0, *, i]), m2_tr, extra = m2_b, xout = m2_x, yout = m2_y)
    m1_yout = trigrid(m1_init[0, *], m1_init[1, *], $
      1e6 * (m1_res[1, *, i]), m1_tr, extra = m1_b, xout = m1_x, yout = m1_y)
    m2_yout = trigrid(m2_init[0, *], m2_init[1, *], $
      1e6 * (m2_res[1, *, i]), m2_tr, extra = m2_b, xout = m2_x, yout = m2_y)

    ; What if we subtract all residual TTP?
    nz = 24
    m1_fitmap = zernike_fit_aperture(m1_zout, mask, nz, zernike_cf = mapcf)
    m1_interp = zernike_fit_aperture(m1_sag[*, *, i], mask, nz, zernike_cf = map_int_cf)

    m1_ttpmap = m1_zout
    m1_ttpmap -= mapcf[0] * ZERNIKE_APERTURE(1, mask)
    m1_ttpmap -= mapcf[1] * ZERNIKE_APERTURE(2, mask)
    m1_ttpmap -= mapcf[2] * ZERNIKE_APERTURE(3, mask)

    ttp_interp_map = m1_sag[*, *, i]
    ttp_interp_map -= map_int_cf[0] * ZERNIKE_APERTURE(1, mask)
    ttp_interp_map -= map_int_cf[1] * ZERNIKE_APERTURE(2, mask)
    ttp_interp_map -= map_int_cf[2] * ZERNIKE_APERTURE(3, mask)

    ; Do for m2
    m2_fitmap = zernike_fit_aperture(m2_zout, mask, nz, zernike_cf = m2_mapcf)

    m2_ttpmap = m2_zout
    m2_ttpmap -= m2_mapcf[0] * ZERNIKE_APERTURE(1, mask)
    m2_ttpmap -= m2_mapcf[1] * ZERNIKE_APERTURE(2, mask)
    m2_ttpmap -= m2_mapcf[2] * ZERNIKE_APERTURE(3, mask)

    ; Do for wedge
    if isa(wedge_struct) then begin
      wedge_zprime = ineff_interp(wedge_init + wedge_res[*, *, i], wedge_init)
      triangulate, wedge_init[0, *], wedge_init[1, *], wedge_tr, wedge_b

      wedge_sag = trigrid(wedge_init[0, *], wedge_init[1, *], $
        1e6 * (wedge_zprime - wedge_init[2, *]), wedge_tr, extra = wedge_b, $
        xout = wedge_x, yout = wedge_y)
      wedge_xout = trigrid(wedge_init[0, *], wedge_init[1, *], $
        1e6 * (wedge_res[0, *, i]), wedge_tr, extra = wedge_b, $
        xout = wedge_x, yout = wedge_y)
      wedge_yout = trigrid(wedge_init[0, *], wedge_init[1, *], $
        1e6 * (wedge_res[1, *, i]), wedge_tr, extra = wedge_b, $
        xout = wedge_x, yout = wedge_y)
      wedge_zout = trigrid(wedge_init[0, *], wedge_init[1, *], $
        1e6 * (wedge_res[2, *, i]), wedge_tr, extra = wedge_b, $
        xout = wedge_x, yout = wedge_y)
    endif

    ; --------------------------------------------------------------------
    ; Make plots
    ; -------------------------------------------------------------------
    ;
    ;

    ; Vector plot
    if keyword_set(vector) then begin
      lmax = max(sqrt(m1_xout ^ 2 + m1_yout ^ 2))
      scale = (lmax * 1e-6) / 0.6
      m1_xout[nmasksel] = 0
      m1_yout[nmasksel] = 0

      v = vector(rebin(m1_xout, 32, 32), rebin(m1_yout, 32, 32), $
        rebin(m1_x, 32), rebin(m1_y, 32), $
        auto_color = 1, rgb_table = 10, position = [0.10, 0.22, 0.95, 0.9], aspect_ratio = 1)

      c = colorbar(target = v, $
        position = [0.10, 0.1, 0.45, 0.15], $
        title = 'Magnitude')
    endif

    ; M1
    plotfile = plotdir + 'M1_Rawx_' + n2s(i)
    implot, 1e3 * m1_xout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = ' M1 Raw X error'

    plotfile = plotdir + 'M1_Rawy_' + n2s(i)
    implot, 1e3 * m1_yout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M1 Raw Y error'

    plotfile = plotdir + 'M1_Rawz_' + n2s(i)
    implot, 1e3 * m1_zout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M1 Raw Z error'

    plotfile = plotdir + 'M1_zinterp_' + n2s(i)
    implot, 1e3 * m1_sag[*, *, i], plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M1 Interpolated Z error'

    plotfile = plotdir + 'M1_TTP_' + n2s(i)
    implot, 1e3 * m1_ttpmap, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M1 Raw Z Residual, TTP Subtracted'

    plotfile = plotdir + 'M1_zinterp_TTP_' + n2s(i)
    implot, 1e3 * ttp_interp_map, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M1 Interpolated Z Residuals, TTP Subtracted'

    ; M2
    plotfile = plotdir + 'M2_Rawx_' + n2s(i)
    implot, 1e3 * m2_xout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M2 Raw X error'

    plotfile = plotdir + 'M2_Rawy_' + n2s(i)
    implot, 1e3 * m2_yout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M2 Raw Y error'

    plotfile = plotdir + 'M2_Rawz_' + n2s(i)
    implot, 1e3 * m2_zout, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M2 Raw Z error'

    plotfile = plotdir + 'M2_zinterp_' + n2s(i)
    implot, 1e3 * m2_sag[*, *, i], plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M2 Interpolated Z error'

    plotfile = plotdir + 'M2_TTP_' + n2s(i)
    implot, 1e3 * m2_ttpmap, plotfile, cbtitle = 'nm', ncolor = 255, $
      blackout = nmasksel, title = 'M2 Raw Z Residual, TTP Subtracted'

    ; Wedge
    if isa(wedge_struct) then begin
      plotfile = plotdir + 'Wedge_Rawx_' + n2s(i)
      implot, wedge_xout, plotfile, cbtitle = 'um', ncolor = 255, $
        blackout = nmasksel, title = 'wedge Raw X error'

      plotfile = plotdir + 'Wedge_Rawy_' + n2s(i)
      implot, wedge_yout, plotfile, cbtitle = 'um', ncolor = 255, $
        blackout = nmasksel, title = 'wedge Raw Y error'

      plotfile = plotdir + 'Wedge_Rawz_' + n2s(i)
      implot, wedge_zout, plotfile, cbtitle = 'um', ncolor = 255, $
        blackout = nmasksel, title = 'wedge Raw Z error'

      plotfile = plotdir + 'Wedge_zinterp_' + n2s(i)
      implot, wedge_sag, plotfile, cbtitle = 'um', ncolor = 255, $
        blackout = nmasksel, title = 'wedge Interpolated Z error'
    endif

    ; --------------------------------------------------------------------
    ; Write output files
    ; -------------------------------------------------------------------
    ;
    ;

    ; Placeholder for writing ZEMAX prescription or other file

    ; Write Sag surfaces
    filename = outdir + 'm1_sag' + n2s(i)
    write_sag, filename, m1_ttpmap, m1_x, m1_y, mask, unitflag, 'M1', i

    filename = outdir + 'm2_sag' + n2s(i)
    write_sag, filename, m2_zout, m2_x, m2_y, mask, unitflag, 'M2', i
    ; if i eq 2 then stop
  endfor
  print, ''
  stop
  ; stop
end