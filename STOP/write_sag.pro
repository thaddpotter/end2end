pro write_sag, filename, pos, disp, unitcode
  compile_opt idl2
  sett = e2e_load_settings()
  ; Given some list of x and y points, as well as x,y,z displacements, calculates the sag surface to be applied to an optic, and outputs the corresponding .GRD file readable by ZEMAX
  ; note, this does not generate derivative interpolation, so ensure that linear interpolation is used in zemax, rather than bicubic spline
  ;
  ; INPUTS:
  ; filename - filename of .GRD file to be created in output/ZEMAX
  ; pos - 3xN array of initial locations (Z is unused?)
  ; disp - 3xN array of x,y,z displacements for corresponding points in pos
  ;
  ;
  ; Header values
  ; nx - number of points in the x direction
  ; ny - ...y direction
  ; delx - point spacing in the x direction
  ; dely - ... y direction
  ; unitflag: 0 for mm, 1 for cm, 2 for in, 3 for m
  ; xdec - x decenter from optical axis
  ; ydec - y decenter from optical axis?
  ;
  ; TODO: Are these measured to the corner or the center of the grid?
  ;
  ; KEYWORDS:
  ;
  ;
  ; OUTPUTS:
  ;
  ;
  ;

  
  ; How much to oversize the grid by (reflections from edges may be inaccurate)
  osize = 0.1

  ; Setup formatting
  hformat = '(2I4,2F12.6,I1,2F12.6)'
  format = '(F12.6,I3)'

  stop
  ; Time to write the file!
  check_and_mkdir, sett.outpath + 'ZEMAX/'
  openw, 1, sett.outpath + 'ZEMAX' + filename + '.GRD'

  ; Write header
  printf, 1, npoints, npoints, delx, dely, unitflag, xdec, ydec, format = hformat

  for i = 0, npoints do begin
    printf, 1, sag_z[i], 0, 0, 0, format = format
  endfor

  close, 1
end