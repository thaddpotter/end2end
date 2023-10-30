pro write_sag, filename, sag_z, xarr, yarr, mask, unitflag, optic, tstep
  compile_opt idl2
  sett = e2e_load_settings()
  ; Given some list of x and y points, as well as x,y,z displacements, calculates the sag surface to be applied to an optic, and outputs the corresponding .GRD file readable by ZEMAX
  ; note, this does not generate derivative interpolation, so ensure that linear interpolation is used in zemax, rather than bicubic spline
  ;
  ; INPUTS:
  ; filename - full filepath of .GRD file to be created
  ; sag_z - Matrix of surface errors (x,y)
  ; xarr, yarr - Corresponding x and y values for the sag grid
  ; MUST BE ORDERED MIN TO MAX and evenly sampled!
  ; MUST BE IN THE UNITS SPECIFIED BY UNITFLAG!
  ;
  ; Header values
  ; nx - number of points in the x direction
  ; ny - ...y direction
  ; delx - point spacing in the x direction
  ; dely - ... y direction
  ; unitflag: 0 for mm, 1 for cm, 2 for in, 3 for m
  ; xdec - x decenter (of the -x limit) from axis?
  ; ydec - y decenter (of the +y limit) from optical axis?
  ;
  ;
  ; TODO: How is this handled for decentered/off-axis aperture optics?
  ; Will that shift be applied automatically?
  ; Do we need to convert units to match prescription?
  ;
  ;
  ; OUTPUTS:
  ; Zemax Sag surface file
  ;

  ; Setup formatting
  hformat = '(2I4,2F10.6,I3,2F12.6)'
  format = '(F14.10,4I3)'

  ; Get values for header
  delx = xarr[1] - xarr[0]
  dely = yarr[1] - yarr[0]
  xdec = min(xarr)
  ydec = max(yarr)
  npoints = n_elements(xarr)

  ; Open Lun
  check_and_mkdir, sett.outpath + 'ZEMAX/'
  openw, 1, filename + '.GRD'

  ; Write comment label line
  printf, 1, '! ' + n2s(optic) + ' Sag Surface for timestep: ' + n2s(tstep)

  ; Write header
  printf, 1, npoints, npoints, delx, dely, unitflag, xdec, ydec, $
    format = hformat

  ; Index over y(note that we go from max to min here!)
  for i = 1, npoints do begin
    ; Index over x
    for j = 0, npoints - 1 do begin
      if mask[j, (npoints - i)] then $
        outline = [sag_z[j, (npoints - i)], 0d, 0d, 0d, 0d] else $
        outline = [sag_z[j, (npoints - i)], 0d, 0d, 0d, 1d]
      printf, 1, outline, format = format
    endfor
  endfor

  close, 1
end