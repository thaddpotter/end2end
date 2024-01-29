pro e2e_run_inst, runbase = RUNBASE, rundist = RUNDIST
  compile_opt idl2

  ; Documentation Goes Here

  ; ----------------------------------------------------------
  ; Startup
  ; ----------------------------------------------------------
  ; Load Simulation Settings
  sett = e2e_load_settings()

  ; Initialize piccsim
  print, 'Starting piccsim...'
  cd, sett.picc.path
  if file_test(sett.picc.path + 'piccsim_materials') ne 1 then make_materials

  ; Run Undisturbed Prescription
  ; ----------------------------------------------------------
  if keyword_set(RUNBASE) then begin
    ; Calculate throughput
    calc_throughput, sett.picc.rx_base

    ; Initialize model
    run_piccsim, 'sim_system', sett.picc.rx_base, /init, broadband = [0, 1, 2, 3, 4]

    ; Calculate occulter transmission
    calc_transmission, 'sim_system', sett.picc.rx_base, broadband = [0, 1, 2, 3, 4]

    ; DM Matrix Operations
    ; Collect DM matrix data
    run_piccsim, 'sim_system', sett.picc.rx_base, caldm = 'dm2', broadband = [0, 1, 2, 3, 4]

    ; Read DM matrix data
    read_matrix, 'sim_system', sett.picc.rx_base, 'sci', 'dm2'
    ; Calculate DM matrix
    calc_matrix, 'sim_system', sett.picc.rx_base, 'sci', 'dm2'

    ; Run EFC, plot results without focal plane sensing
    test_efc, 'sim_system', sett.picc.rx_base, broadband = [0, 1, 2, 3, 4]

    ; Save ouputs to file
  endif

  ; Disturb Prescription
  ; -----------------------------------------------------------
  disturb_rx,

  ; Run Disturbed Prescription
  ; -----------------------------------------------------------

  if keyword_set(RUNDIST) then begin
    ; Calculate throughput
    calc_throughput, sett.picc.rx_dist

    ; Initialize model
    run_piccsim, 'sim_system', sett.picc.rx_dist, /init

    ; TODO: FILE CHECK TO SKIP THESE STEPS IF ALREADY COMPLETED {

    ; Calculate occulter transmission
    calc_transmission, 'sim_system', sett.picc.rx_dist
    ; DM Matrix Operations
    ; Collect DM matrix data
    run_piccsim, 'sim_system', sett.picc.rx_dist, caldm = 'dm2'

    ; Read DM matrix data
    read_matrix, 'sim_system', sett.picc.rx_dist, 'sci', 'dm2'

    ; Calculate DM matrix
    calc_matrix, 'sim_system', sett.picc.rx_dist, 'sci', 'dm2'

    ; Run EFC, plot results without focal plane sensing
    test_efc, 'sim_system', sett.picc.rx_dist

    ; Save ouputs to file
  endif
end