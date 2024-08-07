pro e2e_remove_bulk, dir
  ; Takes data generated by ANSYS "Export to STAR module" and zeros the bulk displacement of each surface based on the primary mirror (or lowest numbered surface in the prescription)
  compile_opt idl2

  sett = e2e_load_settings()

  ; Get list of timestep directories
  dir_list = file_search(sett.starpath + dir + '/', '*', /test_directory,/mark_directory, count=n)

  ;Make output directory
  outdir = sett.starpath + dir + '_staticM1/'
  check_and_mkdir, outdir

  ;Loop over timesteps
  count=0
  for i = 0, n-1 do begin

    ;Get list of optics files
    file_list = file_search(dir_list[i],'Surface*')

    ;Loop over optics
    for k = 0, n_elements(file_list)-1 do begin
      ;Read file
      readcol, file_list[k], x, y, z, dx, dy, dz, format='D,D,D,D,D,D'
      m = n_elements(x)

      ;If we are looking at M1, calculate the bulk motion to subtract
      if (k EQ 0) then begin
        mean_dx = total(dx,/DOUBLE) / m
        mean_dy = total(dy,/DOUBLE) / m
        mean_dz = total(dz,/DOUBLE) / m
      endif

      ;Subtract
      dx = dx - mean_dx
      dy = dy - mean_dy
      dz = dz - mean_dz

      ;Write out File
      tmp = strsplit(file_list[k],'/',/EXTRACT)
      tmp2 = strsplit(dir_list[i],'/',/EXTRACT)

      check_and_mkdir, outdir + tmp2[n_elements(tmp2)-1]
      outfile = outdir + tmp2[n_elements(tmp2)-1] + '/' + tmp[n_elements(tmp)-1]

      openw, 1, outfile
      for j = 0, m-1 do begin
        printf,1, x[j], y[j], z[j], dx[j], dy[j], dz[j], format = '(6F-20.15)'
      endfor
      close,1
      count += 1
    endfor
  endfor

  print,'Wrote: ' + n2s(count) + ' files in ' + outdir

end