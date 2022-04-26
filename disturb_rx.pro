pro disturb_rx, rx_base_name,suffix=suffix, quiet=quiet

;;Procedure to convert COMSOL Output into a distance basis usable by PICCSIM
;-------------------------------------------------------------------------------
;;Arguments:
;rx_base_name - name of prescription to modify
;suffix       - suffix to add to disturbed prescription
;               defaults to '_dist'
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
                roc: [3.048d, 0.508d],$           ;IN METERS FOR COMSOL
                conic: [-1.0d, -0.422335d]}

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
foreach element, optics.name[1], ind do begin
    if typename(data_struct.(ind)) EQ 'STRING' then print, '--Skipping '+element+'...' else begin

        print, '--Calculating Displacement for ' + element
        tmp_struct = data_struct.(ind)
        
        ;Get column vectors
        x = tmp_struct.X
        y = tmp_struct.Y
        z = tmp_struct.Z

        u = tmp_struct.U1
        v = tmp_struct.V1
        w = tmp_struct.W1

        ;Trim list of test points to less than 1000 (speeds up computations)
        nx = n_elements(x)
        vec1 = transpose([[x],[y],[z]])
        if nx GE 1000 then begin
            div = n_elements(x)/500
            base_data = vec1[*,0:nx-1:div]
        endif else base_data = vec1

        ;Initial guess
        case element of
            'M1': guess = [90d,0d,0d,0d,0d]
            'M2': guess = [-90d,0d,0d,0d,0d]
            else: begin
                print, 'No matching initial guess string'
                guess = [0d,0d,0d,0d,0d]
            endelse
        endcase

        ;Find initial coordinates of parent
        base_sol = fit_conic(base_data, optics.roc[ind], optics.conic[ind],guess=guess)
        
        if not keyword_set(quiet) then $
        print, 'RMS Distance from Base Fit: '+n2s(1000*SQRT(base_sol[5]/n_elements(x)))+' mm'

        ;Transform base conic to local coords
        base_local = rotate_displace(base_data,base_sol[0],0,base_sol[1],base_sol[2:4],/INVERSE)

        ;Rotate displacement vectors into local frame
        disp_global = transpose([[u],[v],[w]])
        disp_local = rotate_displace(disp_global,base_sol[0],0,base_sol[1],[0,0,0],/INVERSE)
        
        ;Find coordinates of displaced optic in local frame
        disp_sol = fit_conic(base_local+disp_local, optics.roc[ind], optics.conic[ind])
        
        if not keyword_set(quiet) then begin
            print, '--Displacement Vector' 
            print, 'Rx (deg): ' + n2s(disp_sol[0])
            print, 'Rz (deg): ' + n2s(disp_sol[1])
            print, 'X (m): ' + n2s(disp_sol[2])
            print, 'Y (m): ' + n2s(disp_sol[3])
            print, 'Z (m): ' + n2s(disp_sol[4])
            print, 'RMS Distance from Disp Fit: '+n2s(1000*SQRT(disp_sol[5]/n_elements(x)))+' mm'
        endif

        ;Calculate Residual Displacements
        res_disp = (base_local + disp_local) - rotate_displace(base_local,disp_sol[0],0,disp_sol[1],disp_sol[2:4])

        ;Get coordinates of residual points
        res = base_local
        res[2,*] = 0
        res += res_disp

        ;Fit to zernikes
        z_coeff = fit_zernike(res)
        max_z = max(z_coeff,ind_z)
        if not keyword_set(quiet) then begin
            print, 'Maximum Zernike Coefficient: ' + n2s(max_z)
            print, 'Zernike Term: ' + zernike_name(ind_z+1)
        endif

        ;Save values
        out[ind].fit = base_sol
        out[ind].disp = disp_sol
        out[ind].zco = z_coeff

    endelse
endforeach

;---Create Displaced Prescription------------------------------

rx_dist = rx_base

;---Output-----------------------------------------------------

;Perturbation Data
check_and_mkdir, sett.outpath+'displacement/'
save, out, filename = sett.outpath +'displacement/'+ rx_base_name + '_displace.idl'
print, 'Saved: ' + sett.outpath +'displacement/'+ rx_base_name + '_displace.idl'

;Write out disturbed prescription to piccsim directories
if not keyword_set(suffix) then suffix = '_dist'
rx_file = sett.picc.path+'/data/prescriptions/'+rx_base_name + suffix +'.csv'
openw, 1, rx_file
write_rx, 1, rx_dist
close,1
print, 'Wrote: ' + sett.picc.path+'/data/prescriptions/'+rx_base_name + suffix +'.csv'

;change path back to main directory
cd, sett.path

end