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

;---Read COMSOL data---------------------

;Initialize structures
data_struct = {m1:'',$
               m2:''}

optics = {name: tag_names(data_struct),$
                roc: [120.0, 20.0],$
                conic: [-1.0, -0.422335]}

out_struct = {fit: dblarr(6),$
              disp: dblarr(6),$
              zco: dblarr(25)}

out = REPLICATE(out_struct,n_elements(optics.name))  

;Read in COMSOL Data
count = 0
foreach element, optics.name, ind do begin
    ;Find file that contains keyword
    data_file = file_search(element+'*',count=count)
    ;Check that only one file matches string 
    CASE count of
        0: print, 'No files matching: ' + element
        1: begin
            tmp_struct = read_comsol_disp(data_file, delim=';')          ;Read Data from file
            struct_replace_field, data_struct, element, tmp_struct  ;Add to final structure
        end
        else: print, 'Error, more than one file matching: ' + element
    endcase 
endforeach

;---Calculate Displacements------------------------------


;--Loop over parameter sweep?--------------------------------------
;(Needs to be higher than elements, since displacements must be grouped by parameter val)


;--Loop over elements---------------------------------------------------
foreach element, optics.name, ind do begin
    if typename(data_struct.(ind)) EQ 'STRING' then print, 'Skipping '+element+'...' else begin

        tmp_struct = data_struct.(ind)
        
        ;Get column vectors
        x = tmp_struct.X
        y = tmp_struct.Y
        z = tmp_struct.Z

        ;Find initial coordinates of parent
        base_data = transpose([[x],[y],[z]])
        base_sol = fit_conic(base_data, optics.roc[ind], optics.conic[ind])
        print, 'RMS Distance from Base Fit: '+n2s(1000*SQRT(base_sol[5]/n_elements(x)))+' mm'

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
        disp_sol = fit_conic(base_local+disp_local, optics.roc[ind], optics.conic[ind])
        print, 'RMS Distance from Disp Fit: '+n2s(1000*SQRT(disp_sol[5]/n_elements(x)))+' mm'

        ;Calculate Residual Displacements
        res_disp = (base_local + disp_local) - rotate_displace(base_local,disp_sol[0],0,disp_sol[1],disp_sol[2:4])

        ;Get coordinates of residual points
        res = base_local
        res[2,*] = 0
        res += res_disp

        ;Fit to zernikes
        z_coeff = fit_zernike(res)

        ;Save values
        out[ind].fit = base_sol
        out[ind].disp = disp_sol
        out[ind].zco = z_coeff

    endelse
endforeach

;---Save Data-----------------------------------------------------

;Perturbation Data
save, out, filename = sett.outpath + rx_base_name + '_displace.idl'


stop

;Write out disturbed prescription to piccsim directories
rx_file = sett.picc.path+'/data/prescriptions/'+rx_dist_name+'.csv'
openw, 1, rx_file
write_rx, 1, rx_dist
close,1 

;change path back to main directory
cd, sett.path

end