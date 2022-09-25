pro disturb_rx, rx_base_name,suffix=suffix, quiet=quiet

;;Procedure to convert COMSOL Output into:
;(1) a set of displacements usable by ZEMAX
;(2) an updated csv prescription file readable by PICCSIM
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
;disp_arr - Structure of displacement vectors for the primary and secondary mirrors, as well as the optical bench
;NOTE: Displacement vector for the optical bench uses the secondary focus (donut mirror) as the origin

;error maps?
;-------------------------------------------------------------------------------
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
               m2:'',$
               bench:''}

optics = {name: tag_names(data_struct),$
                roc: [3.048d, 0.508d],$           ;IN METERS
                conic: [-1.0d, -0.422335d]}

out_struct = {fit: dblarr(7),$
              disp: dblarr(7)}

out = REPLICATE( out_struct,n_elements(optics.name) + 1)  

;Read in COMSOL Data
count = 0
foreach element, optics.name, ind do begin
    ;Find file that contains keyword
    data_file = file_search(strlowcase(element)+'*',count=count)
    ;Check that only one file matches string 
    CASE count of
        0: print, 'No files matching: ' + element
        1: begin
            tmp_struct = read_comsol_disp(data_file, delim=';')         ;Read Data from file
            struct_replace_field, data_struct, element, tmp_struct      ;Add to final structure
        end
        else: print, 'Error, more than one file matching: ' + element
    endcase 
endforeach

;---Calculate Displacements------------------------------


;--Loop over parameter sweep?--------------------------------------
;(Needs to be higher than elements, since displacements must be grouped by parameter val)


;--Mirrors---------------------------------------------------
foreach element, optics.name[0:1], ind do begin
    if typename(data_struct.(ind)) EQ 'STRING' then print, '--Skipping '+element+'...' else begin

        print, '--Calculating Displacement for ' + element
        tmp_struct = data_struct.(ind)
        
        mirror_sol = calc_mirror_displace(tmp_struct, optics.roc[ind], optics.conic[ind], element, quiet=quiet)

        out[ind].fit = mirror_sol[*,0]
        out[ind].disp = mirror_sol[*,1]
    endelse
endforeach

;--Optical Bench-----------------------------------------------

print, '--Calculating Displacement for optical bench'
tmp_struct = data_struct.(2)

bench_disp = calc_bench_displace(tmp_struct, /quiet)

out[2].disp = bench_disp

;---Create Displaced Prescription------------------------------

rx_dist = rx_base

;---Output-----------------------------------------------------

;Perturbation Data
check_and_mkdir, sett.outpath+'displacement/'
save, out, filename = sett.outpath +'displacement/'+ rx_base_name + '_displace.idl'
print, 'Saved: ' + sett.outpath +'displacement/'+ rx_base_name + '_displace.idl'

;Write out tolerance file
tolfile = sett.outpath +'displacement/'+ rx_base_name + '.tol' 
tscfile = sett.outpath +'displacement/'+ rx_base_name + '.tsc'
write_tol, 1, tolfile, tscfile, out

;Write out disturbed prescription to piccsim directories
;rx_file = sett.picc.path+'/data/prescriptions/'+rx_base_name + suffix +'.csv'
;openw, 1, rx_file
;write_rx, 1, rx_dist
;close,1
;print, 'Wrote: ' + sett.picc.path+'/data/prescriptions/'+rx_base_name + suffix +'.csv'

;change path back to main directory
cd, sett.path

end