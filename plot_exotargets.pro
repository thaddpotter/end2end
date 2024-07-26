pro plot_exotargets
  compile_opt idl2
  sett = e2e_load_settings()
  data_struct = read_csv(sett.datapath + 'exo_table.csv', header = header, n_table_header = 37, count = count)

  ; Fields of interest:
  ; 4 - discovery method
  ; 7 - orbit sma
  ; 12 - p mass

  file = sett.plotpath + 'mass_sep'

  mkeps, file

  color = bytscl(dindgen(4), top = 254)
  loadct, 39

  method = ['Radial Velocity', 'Imaging', 'Transit', 'Microlensing']
  psym = [7, 2, 1, 4]

  sel = where((data_struct.(4) eq method[0]) and (data_struct.(7) gt 0.0) and (data_struct.(12) gt 0.0))

  plot, data_struct.(7)[sel], data_struct.(12)[sel], psym = psym[0], /xlog, /ylog, color = color[0], xtitle = 'Orbital SMA (AU)', ytitle = 'Planet Mass (Earth Masses)', title = 'Confirmed Exoplanets', position = [0.16, 0.12, 0.82, 0.94]

  for i = 1, 3 do begin
    sel = where((data_struct.(4) eq method[i]) and (data_struct.(7) gt 0.0) and (data_struct.(12) gt 0.0))
    oplot, data_struct.(7)[sel], data_struct.(12)[sel], psym = psym[i], color = color[i]
  endfor

  cbmlegend, ['RV', 'Imaging', 'Transit', 'Lensing'], psym, color, [0.825, 0.94], linsize = 0.5, $
  /psym
  mkeps, /close

  stop
end