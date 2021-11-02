pro e2e_run_inst, runbase=RUNBASE

;Documentation Goes Here



;Load Simulation Settings
sett = e2e_load_settings()

;TODO: FILE CHECK FOR PICCSIM OUTPUTS (PSF, Contrast Map, ...) FOR SKIP



;Initialize piccsim
print, 'Starting piccsim...'
cd, sett.picc.path
if file_test(sett.picc.path+'piccsim_materials') NE 1 then make_materials

;Run Undisturbed Prescription
;----------------------------------------------------------
if keyword_set(RUNBASE) then begin

;Calculate throughput
if file_test(sett.picc.path+'output/throughput/'+sett.picc.rx_base+'_throughput.idl') NE 1 then begin
    print, 'Calculating Throughput for '+sett.picc.rx_base+'...'
    calc_throughput,sett.picc.rx_base

endif

;Initialize model 
if file_test(sett.picc.path+'output/surface/'+sett.picc.rx_base) NE 1 then begin
    print, 'Initializing model for '+sett.picc.rx_base+'...'
    run_piccsim,'sim_system',sett.picc.rx_base,/init,broadband=[0,1,2,3,4]

endif

;Calculate occulter transmission
if file_test(sett.picc.path+'output/transmission/'+sett.picc.rx_base+'/transmission_648000_512_pol0.fits') NE 1 then begin
    print, 'Calculating occulter transmission for '+sett.picc.rx_base+'...'
    calc_transmission,'sim_system',sett.picc.rx_base,broadband=[0,1,2,3,4]

endif else print, 'Already have occulter transmission. Skipping...'

;DM Matrix Operations
if file_test(sett.picc.path+'output/sim_system_cal_dm2_pol0/'+sett.picc.rx_base) NE 1 then begin ;EDIT FILE NAME
    print, 'Simulating DM actuators for '+sett.picc.rx_base+'...'
    ;Collect DM matrix data 
    run_piccsim,'sim_system',sett.picc.rx_base,caldm='dm2',broadband=[0,1,2,3,4]

endif else if file_test(sett.picc.path+'output/matrix/'+sett.picc.rx_base+'/'+sett.picc.rx_base+'_dm2_full_matrix_pol0_sci_read.idl') NE 1 then begin
    print, 'Getting DM Matrix for '+sett.picc.rx_base+'...'
    ;Read DM matrix data
    read_matrix,'sim_system',sett.picc.rx_base,'sci','dm2'
    ;Calculate DM matrix
    calc_matrix,'sim_system',sett.picc.rx_base,'sci','dm2'

endif else print, 'Have DM Matrix Data. Skipping...'



;Run EFC, plot results without focal plane sensing
test_efc,'sim_system',sett.picc.rx_base,broadband=[0,1,2,3,4]

endif


;Disturb Prescription
;-----------------------------------------------------------


;Read input files from COMSOL



;Telescope Optics Displacement



;Optics Deformation


;Bench Deformation -> Component Displacement




;convert to piccsim prescription



;Run Disturbed Prescription
;-----------------------------------------------------------

;Calculate throughput
if file_test(sett.picc.path+'output/throughput/'+sett.picc.rx_dist+'_throughput.idl') NE 1 then begin
    print, 'Calculating Throughput for '+sett.picc.rx_dist+'...'
    calc_throughput,sett.picc.rx_dist
endif

;Initialize model 
if file_test(sett.picc.path+'output/surface/'+sett.picc.rx_dist) NE 1 then begin
    print, 'Initializing model for '+sett.picc.rx_dist+'...'
    run_piccsim,'sim_system',sett.picc.rx_dist,/init,broadband=[0,1,2,3,4]
endif

;TODO: FILE CHECK TO SKIP THESE STEPS IF ALREADY COMPLETED {

;Calculate occulter transmission
if file_test(sett.picc.path+'output/transmission/'+sett.picc.rx_dist+'/transmission_648000_512_pol0.fits') NE 1 then begin
    print, 'Calculating occulter transmission for '+sett.picc.rx_dist+'...'
    calc_transmission,'sim_system',sett.picc.rx_dist,broadband=[0,1,2,3,4]
endif else print, 'Already have occulter transmission. Skipping...'

;Collect DM matrix data 
run_piccsim,'sim_system',sett.picc.rx_dist,caldm='dm2',broadband=[0,1,2,3,4]

;Read DM matrix data
read_matrix,'sim_system',sett.picc.rx_dist,'sci','dm2'

;Calculate DM matrix
calc_matrix,'sim_system',sett.picc.rx_dist,'sci','dm2'

;Run EFC, plot results without focal plane sensing
test_efc,'sim_system',sett.picc.rx_dist,broadband=[0,1,2,3,4]
;}



;Save ouputs to file



end