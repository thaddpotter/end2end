pro write_optical_table, unit, m1_err, m2_err, opt_err,
  compile_opt idl2
  ; ;Writes out table of optical displacements for use with zemax
  ; Called by convert_displacements

  ed = '' ; Empty string
  md = ',' ; Delimiter
  ef = 'A0' ; Format code prefix
  f1 = '(A-15,A1,$)' ; Element and delimiter format code

  ; Get number of data points
  sz = size(m1_err)
  ncols = sz[2]

  ; Print header
  header = ['Optic']
  printf, unit, header, format = hformat
end