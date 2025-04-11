pro test_disturb
;---------------------------------------------------------------------------------
;;Test procedure for converting optical prescription and STOP data into:
;(1) a set of 6-D displacements, and map of residuals usable by ZEMAX
;(2) an updated csv prescription file readable by PICCSIM?
;-------------------------------------------------------------------------------
;Required Data Files:
;COMSOL surface data table for the three main test surfaces: M1, M2, and the Optical Bench
;Piccsim prescription csv file
;Matching Zemax prescription report
;   format TBD
;------------------------------------------------------------------------------
;;Arguments:
;
;-------------------------------------------------------------------------------
;;Keywords
;
;-------------------------------------------------------------------------------
;;Outputs
;

;error maps?

;---------------------------------------------------------------------------------


;---Startup----------------------------
;Load Settings Block
sett = e2e_load_settings()

;Change WD to STOP data folder
cd, sett.datapath+'stop/'

;Initialize structures
data_struct = {m1:'',$
               m2:'',$
               bench:'' $
               }

optics = {name: tag_names(data_struct),$
          roc: [3.048d, 0.508d],$           ;IN METERS
          conic: [-1.0d, -0.422335d] $
          }

fit_struct = {fit: '',$
              resid: '' $
              }

out = data_struct

;---Read COMSOL Surface data---------------------
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

;COMSOL Registration Points
coord_reg = identity(3)

;---Read Zemax prescription data--------------
;;TODO:
;Vertex Coordinates in Global
;Coordinate registration points

;Read prescription report



zemax_reg = transform_3d(coord_reg, [45d,10d,-25d], [0d,0d,0d],/center)



;---Generate Test displacement data-----

disp_mat = dblarr(6,3)
foreach element, optics.name, ind do begin

    ;Choose random rotation angle | < 2 degrees
    angle = 2d * randomu(seed, 3, /double)
    ;Choose random bulk displacement | < 5 mm
    disp = 5d-3 * randomu(seed, 3, /double)
    ;Choose Random Residuals | Abs < 10 um
    resid = 0.5d-6 + 1d-5 * randomu(seed, 3, n_elements(data_struct.(ind).(3)), /double)
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

;---Convert to Zemax Global Frame------------------------

foreach element, optics.name, ind do begin
    ;Find transform
    conv = fit_transform(coord_reg,zemax_reg)

    ;check rotation angles against comsol inputs


    ;Convert coordinates
    zminit = TRANSPOSE([[data_struct.(ind).(0)],[data_struct.(ind).(1)],[data_struct.(ind).(2)]])
    zmdisps = TRANSPOSE([[data_struct.(ind).(3)],[data_struct.(ind).(4)],[data_struct.(ind).(5)]])      

    zmcoords =  transpose([transform_3d(zminit, conv[0:2], conv[3:5], /center), $
                 transform_3d(zmdisps, conv[0:2], [0d,0d,0d], /center)]) ;Only rotate the the displacement vectors

    ;Replace data fields
    tmp_struct = data_struct.(ind)
    foreach tag, ['x','Y','Z','U1','V1','W1'], i do begin
        tmp = zmcoords[*,i]
        struct_replace_field, tmp_struct, tag, zmcoords[*,i]
    endforeach
    struct_replace_field,data_struct,element,tmp_struct

endforeach

;---Calculate Displacements------------------------------

foreach element, optics.name, ind do begin

    init = TRANSPOSE([[data_struct.(ind).(0)],[data_struct.(ind).(1)],[data_struct.(ind).(2)]])
    dist = init + TRANSPOSE([[data_struct.(ind).(3)],[data_struct.(ind).(4)],[data_struct.(ind).(5)]])

    ;Fit parameters
    fit = fit_transform(init, dist)
    struct_replace_field, fit_struct, 'fit', fit

    ;Get residuals
    resid = transform_3d(init, fit[0:2], fit[3:5], /center) - dist
    struct_replace_field, fit_struct, 'resid', resid

    ;Write to output
    struct_replace_field, out, element, fit_struct

endforeach

stop

end