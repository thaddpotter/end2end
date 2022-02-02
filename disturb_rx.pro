pro disturb_rx, rx_base_name,rx_dist_name=rx_dist_name

;;Procedure to convert COMSOL Output into a distance basis usable by PICCSIM
;-------------------------------------------------------------------------------
;;Arguments:
;rx_base_name - name of prescription to modify
;rx_dist name - name of prescription to write out (WARNING: Will overwrite this prescription)
;data_file    - filename of 
;-------------------------------------------------------------------------------
;;Keywords
;
;-------------------------------------------------------------------------------
;;Outputs
;rx_dist - PICCSIM readable csv file with the same structure/order as rx_base
;error maps?

;Load Settings Block
sett = e2e_load_settings()

;Read in base prescription
rx_file = sett.picc.path+'/data/prescriptions/'+rx_base_name+'.csv'
rx_base = piccsim_readrx(rx_file)

;Change WD to STOP data folder
cd, sett.datapath+'stop/'

;---Read COMSOL data into structure---------------------

optics = ['m1','m2']
dist_struct = {m1:'test',$
               m2:'test'}
optics = tag_names(dist_struct)                          ;Necessary for indexing later...

count = 0
foreach element, optics, index do begin
    ;Find file that contains keyword
    data_file = file_search(element+'*',count=count)
    ;Check that only one file matches string 
    CASE count of
        0: print, 'No files matching: ' + element
        1: begin
            tmp_struct = read_comsol_disp(data_file, delim=';')          ;Read Data from file
            struct_replace_field, dist_struct, element, tmp_struct  ;Add to final structure
        end
        else: print, 'Error, more than one file matching: ' + element
    endcase 
endforeach

;---Calculate Displacements------------------------------

;--Loop over elements---------------------------------------------------
foreach element, optics, index do begin
    tmp_struct = dist_struct.(index)   ;Only one type conversion error...
    
    ;Get column vectors
    x = tmp_struct.X
    y = tmp_struct.Y
    z = tmp_struct.Z

    ;Find initial coordinates of parent
    base_data = transpose([[x],[y],[z]])
    base_sol = fit_conic(base_data)
    if base_sol[5] GT 1 then begin
        print, 'Error in conic fit, total square distance greater than 1m'
        stop
    endif

    ;--Loop over parameter sweep?--------------------------------------


    ;Get displacement data
    u = tmp_struct.U1
    v = tmp_struct.V1
    w = tmp_struct.W1

    ;Transform base conic to local coords
    base_local = rotate_displace(base_data,base_sol[0],0,base_sol[1],base_sol[2:4],/INVERSE)

    ;Rotate displacement vectors into local frame
    disp_global = transpose([[u],[v],[w]])
    disp_local = rotate_displace(disp_global,base_sol[0],0,base_sol[1],[0,0,0],/INVERSE)
    
    ;Find coordinates of displaced optic in local frame
    disp_sol = fit_conic(base_local+disp_local)
    if disp_sol[5] GT 1 then begin
        print, 'Error in conic fit, total square distance greater than 1m'
        stop
    endif

    ;Calculate Residual Displacements
    res_disp = (base_local + disp_local) - rotate_displace(base_local,disp_sol[0],0,disp_sol[1],disp_sol[2:4])

    ;Get coordinates of residual points
    res = base_local
    res[2,*] = 0
    res += res_disp

    ;Fit to zernikes
    z_coeff = fit_zernike(res)




    stop
endforeach




stop
;---Write out disturbed prescription---------------------
rx_file = sett.picc.path+'/data/prescriptions/'+rx_dist_name+'.csv'
openw, 1, rx_file
write_rx, 1, rx_dist
close,1 

;change path back to main directory
cd, sett.path

end

;Previous notes on how to calculate surface data

    ;Fit points to zernikes
      ;x,y,z point list -> Zernike Fit

    ;Take new surface vertex, calculate distance to next optic, check against base
    ;Take surface focal length, check against base
    
    ;Record relevant zernike coeffients (Deviation from ideal for focus) and write out to a better sampled phase error map for piccsim
    ;Save to file

    ;Write new distances and focal lengths to structure