pro loop_disp
  compile_opt idl2

  folders = ['t_test']
  n = n_elements(folders)

  for i = 0, n - 1 do convert_displacements, folders[i]
end