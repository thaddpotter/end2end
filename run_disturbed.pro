pro run_disturbed, sub_dir
  compile_opt idl2

  ; Startup
  rx_name = 'rx_picture_c2_ch6'
  sim_name = 'sim_system'
  cam_name = 'sci'
  dm_name = 'dm2'
  broadband = [0, 1, 2, 3, 4]

  sett = e2e_load_settings()
  piccsett = piccsim_load_settings('rx_picture_c2_ch6')
  rx = piccsim_readrx(piccsett.rx_path + 'rx_picture_c2_ch6.csv')

  ; Read Beamwalk data
  csv_file = sett.datapath + 'STAR_res/' + sub_dir + '/beamwalk.csv'
  bwalk_struct = read_csv(csv_file, count = nsteps)
  ncols = n_tags(bwalk_struct)
  nrows = n_elements((bwalk_struct.(0)))

  bwalk = dblarr(ncols, nrows)
  bwalk[0, *] = bwalk_struct.(0)
  bwalk[1, *] = bwalk_struct.(1)
  bwalk[2, *] = bwalk_struct.(2)
  for i = 3, ncols - 1, 2 do begin
    bwalk[i, *] = bwalk_struct.(i) - bwalk[1, *]
    bwalk[i + 1, *] = bwalk_struct.(i + 1) - bwalk[2, *]
  endfor
  bwalk[1, *] -= bwalk_struct.(1)
  bwalk[2, *] -= bwalk_struct.(2)

  ; Read Fits Data
  fits_file = sett.datapath + 'STAR_res/' + sub_dir + '/pm1'
  readmap, fits_file, fits_data, mapsamp, mapunits
  ; Calculate magnification
  ; Correct error where map sampling was increased without changing the key value
  mag = double(mapsamp) * 2 * 1.04d * (piccsett.gridsize * piccsett.beamratio) / (2 * rx[0].radius)

  ; Make aperture mask
  xyimage, piccsett.gridsize, piccsett.gridsize, xim, yim, rim, /quadrant, /index
  masksel = where((rim lt 256. * piccsett.beamratio), complement = nmasksel)
  mask = 0 * rim
  mask[masksel] = 1

  ; Initial map
  initmap = fits_data

  ; Run piccsim
  ; Initialization
  if 0 then begin
    calc_throughput, rx_name
    run_piccsim, sim_name, rx_name, broadband = broadband, /init
    run_piccsim, sim_name, rx_name, broadband = broadband, /rebuild
    plot_piccsim, sim_name, rx_name
  endif

  ; ;DM calibration
  if 0 then begin
    run_piccsim, sim_name, rx_name, broadband = broadband, caldm = dm_name
    read_matrix, sim_name, rx_name, cam_name, dm_name
    calc_matrix, sim_name, rx_name, cam_name, dm_name
  endif

  ; ;Dark hole generation
  if 0 then test_efc, sim_name, rx_name, cam_name, dm_name, broadband = broadband, sim_tag = 'stop_efc'

  ; Get final DM command from optval
  files = file_search('output/' + rx_name + '/' + sim_name + '_stop_efc/*optval*.idl', count = nfiles)
  restore, files[-1]

  dm_cmd = list()
  for i = 0, n_elements(optval.dm_name) - 1 do begin
    cmd = {name: optval.dm_name[i], cmd: optval.dm_command[i]}
    dm_cmd.add, cmd
  endfor

  nsteps = 70

  ; only beamwalk
  if 0 then begin
    for i = 0, nsteps - 1 do begin
      disp_mat = [bwalk[0, *], bwalk[2 * i + 1 : 2 * i + 2, *]] ;

      ; ;Run simulation
      run_piccsim, sim_name, rx_name, dm_cmd = dm_cmd, continue_sim = (i gt 0), $
        sim_tag = sub_dir + '_bw', live_contrast = 'sci', optic_displacement = disp_mat
    endfor
    plot_piccsim, 'sim_system_' + sub_dir + '_bw', 'rx_picture_c2_ch6'
  endif

  ; only WF
  if 1 then begin
    for i = 0, nsteps - 1 do begin
      ; ;Read wavefront
      fits_file = sett.datapath + 'STAR_res/' + sub_dir + '/pm' + n2s(i + 1)
      readmap, fits_file, fits_data, mapsamp, mapunits

      ; Subtract at native resolution, magnify to piccsim sampling
      err_map = magnify(fits_data - initmap, mag, piccsett.gridsize, cubic = -0.5)
      err_map[where(finite(err_map, /nan))] = 0 ; Mask nans
      err_map[nmasksel] = 0 ; Mask aperture before filtering

      fmap = filter_map(err_map, high = 2, /period)
      fmap[nmasksel] = 0

      check_and_mkdir, sett.plotpath + 'wferr/' + sub_dir
      mkeps, sett.plotpath + 'wferr/' + sub_dir + '/' + n2s(i)
      implot, 1d9 * fmap, blackout = nmasksel
      mkeps, /close

      ; ;Run simulation
      run_piccsim, sim_name, rx_name, dm_cmd = dm_cmd, continue_sim = (i gt 0), $
        sim_tag = sub_dir + '_WF', live_contrast = 'sci', phase_map = 0.85d * fmap
      print, max(fmap)
    endfor
    plot_piccsim, 'sim_system_' + sub_dir + '_WF', 'rx_picture_c2_ch6'
  endif

  ; All error sources
  if 0 then begin
    for i = 0, nsteps - 1 do begin
      ; ;Read wavefront
      fits_file = sett.datapath + 'STAR_res/' + sub_dir + '/pm' + n2s(i + 1)
      readmap, fits_file, fits_data, mapsamp, mapunits

      ; Subtract at native resolution, magnify to piccsim sampling
      err_map = magnify(fits_data - initmap, mag, piccsett.gridsize, cubic = -0.5)
      err_map[where(finite(err_map, /nan))] = 0 ; Mask nans
      err_map[nmasksel] = 0 ; Mask aperture before filtering

      fmap = filter_map(err_map, high = 2, /period)
      fmap[nmasksel] = 0

      disp_mat = [bwalk[0, *], bwalk[2 * i + 1 : 2 * i + 2, *]]

      ; ;Run simulation
      run_piccsim, sim_name, rx_name, dm_cmd = dm_cmd, continue_sim = (i gt 0), $
        sim_tag = sub_dir + '_All', live_contrast = 'sci', phase_map = 0.85d * fmap, $
        optic_displacement = disp_mat
    endfor
    plot_piccsim, 'sim_system_' + sub_dir + '_All', 'rx_picture_c2_ch6'
  endif
end
