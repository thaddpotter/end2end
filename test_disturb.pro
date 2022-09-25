pro test_disturb

;Load Settings Block
sett = e2e_load_settings()

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


;---Generate Test displacement data-----

disp_mat = dblarr(6,3)
foreach element, optics.name, ind do begin

    ;Choose random rotation angle | < 2 degrees
    angle = 2d * randomu(seed, 3, /double)
    ;Choose random bulk displacement | < 5 mm
    disp = 5d-3 * randomu(seed, 3, /double)
    ;Choose Random Residuals | Abs < 1 um
    resid = 0.5d-7 + 1d-6 * randomu(seed, 3, n_elements(data_struct.(ind).(3)), /double)
    disp_mat[*,ind] = [angle, disp]

    init_points = TRANSPOSE([[data_struct.(ind).(0)],[data_struct.(ind).(1)],[data_struct.(ind).(2)]])

    ;Run displacements, apply residuals
    disp_points = transform_3d(init_points, angle, disp,/center) - init_points + resid

    ;Replace fields
    tmp_struct = data_struct.(ind)
    foreach tag, ['U1','V1','W1'], i do begin
        struct_replace_field, tmp_struct, tag, TRANSPOSE(disp_points[i,*])
    endforeach
    struct_replace_field, data_struct, element, tmp_struct

endforeach


;---Calculate Displacements------------------------------


;--Mirrors---------------------------------------------------
foreach element, optics.name[0:1], ind do begin
    if typename(data_struct.(ind)) EQ 'STRING' then print, '--Skipping '+element+'...' else begin

        print, '--Calculating Displacement for ' + element
        tmp_struct = data_struct.(ind)
        
        mirror_sol = calc_mirror_displace(tmp_struct, optics.roc[ind], optics.conic[ind], element, quiet=quiet)

        out[ind].fit = mirror_sol[*,0]
        out[ind].disp = mirror_sol[*,1]

        stop
    endelse
endforeach

stop


;foreach element, optics.name, ind do begin
;
;    init = TRANSPOSE([[data_struct.(ind).(0)],[data_struct.(ind).(1)],[data_struct.(ind).(2)]])
;    dist = init + TRANSPOSE([[data_struct.(ind).(3)],[data_struct.(ind).(4)],[data_struct.(ind).(5)]])
;
;    a = fit_transform(init, dist)
;
;endforeach

end