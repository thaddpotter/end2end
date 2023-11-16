pro loop_disp
  compile_opt idl2

  folders = ['fullmodel_newbounds']
  n = n_elements(folders)

  for i = 0, n - 1 do convert_displacements, folders[i], /reread, /vector
end