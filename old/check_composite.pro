pro check_composite
  compile_opt idl2

  raw = '~/idl/end2end/data/stop/Composite_Test_Raw2.txt'
  proc = '~/idl/end2end/data/stop/Composite_Test_Proc.txt'

  raw_struct = read_comsol_disp(raw, delim = ';')
  proc_struct = read_comsol_disp(proc, delim = ';')

  raw_data = transpose([[raw_struct.x], [raw_struct.y], [raw_struct.z]])
  proc_data = transpose([[proc_struct.x], [proc_struct.y], [proc_struct.z]])

  roc = 3.048d
  k = -1
  init = [90d, 0, 0d, 0d, 0d]

  rawsol = fit_conic(raw_data[*, 0 : 5000 : 10], roc, k, guess = init)
  print, 'RMS Distance for Raw: ' + n2s(1000 * sqrt(rawsol[5] / n_elements(501d))) + ' mm'

  procsol = fit_conic(proc_data[*, 0 : 3000 : 6], roc, k, guess = init)
  print, 'RMS Distance for Proc: ' + n2s(1000 * sqrt(procsol[5] / n_elements(501d))) + ' mm'
end
