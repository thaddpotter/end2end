pro write_rx, unit, rx
  compile_opt idl2
  ; ;Writes out piccsim-readable CSV File from RX Structure
  ; ;Effectively the reverse of piccsim_readrx

  ed = '' ; Empty string
  md = ',' ; Delimiter
  ef = 'A0' ; Format code prefix

  ; ;Define format
  format = '(' + ef + ',' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,A1,' + $
    'A-15,' + ef + ')'

  ; ;Define headers
  header1 = string(ed, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    'Non Circ/Sq', md, $
    '0:E, 1:R', md, $
    'Check Zemax', md, $
    '', md, $
    '', md, $
    'PTV [nm]', md, $
    'RMS [nm]', md, $
    '', md, $
    '', md, $
    'Cutoff [c/a]', md, $
    'PTW', md, $
    'RMS', md, $
    '', md, $
    '', md, $
    'Cutoff [c/a]', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', md, $
    '', ed, $
    format = format)

  header2 = string(ed, $
    '# Name', md, $
    'Type', md, $
    'Pupil', md, $
    'Focus', md, $
    'Init', md, $
    'Focal Length', md, $
    'Thickness', md, $
    'Optic R', md, $
    'Optic R2', md, $
    'Ell or Rec', md, $
    'Aper or Obsc', md, $
    'Beam R', md, $
    'Angle', md, $
    'Beamwalk [units/as]', md, $
    'Surf. Min', md, $
    'Surf. PSD A', md, $
    'Surf. PSD B', md, $
    'Surf. PSD C', md, $
    'Surf. PSD D', md, $
    'Ref. Min', md, $
    'Ref. PSD A', md, $
    'Ref. PSD B', md, $
    'Ref. PSD C', md, $
    'Ref. PSD D', md, $
    'Material', md, $
    'Wave Code', md, $
    'Extra 1', md, $
    'Extra 2', md, $
    'Extra 3', md, $
    'Extra 4', ed, $
    format = format)

  printf, unit, header1
  printf, unit, header2

  ; Loop over rows
  for i = 0, n_elements(rx) - 1 do begin
    ; ;Write data to variable
    rx_longname = rx[i].name
    rx_type = rx[i].type
    rx_pupil = n2s(rx[i].pupil, format = '(B)')
    rx_focus = n2s(rx[i].focus, format = '(B)')
    rx_init = n2s(rx[i].init, format = '(I)')
    rx_fl = n2s(rx[i].fl, format = '(F0.8)')
    rx_dist = n2s(rx[i].dist, format = '(F0.8)')
    rx_zbeam = n2s(rx[i].zbeam, format = '(F0.8)')
    rx_radius = n2s(rx[i].radius, format = '(F0.8)')
    rx_radiusB = n2s(rx[i].radiusB, format = '(B)')
    rx_ellrec = n2s(rx[i].ellrec, format = '(B)')
    rx_aperobsc = n2s(rx[i].aperobsc, format = '(B)')
    rx_angle = n2s(rx[i].angle, format = '(F0.8)')
    rx_beamwalk = n2s(rx[i].beamwalk, format = '(F0.8)')
    rx_sptv = n2s(rx[i].sptv, format = '(F0.3)')
    rx_srms = n2s(rx[i].srms, format = '(F0.3)')
    rx_spsdb = n2s(rx[i].spsdb, format = '(F0.3)')
    rx_spsdc = n2s(rx[i].spsdc, format = '(F0.3)')
    rx_spsdd = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_rptv = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_rrms = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_rpsdb = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_rpsdc = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_rpsdd = n2s(rx[i].spsdd, format = '(F0.3)')
    rx_material = rx[i].material
    rx_wave = n2s(rx[i].wave, format = '(I)')
    if rx_type eq 'lenslet' then rx_extra1 = n2s(rx[i].extra1, format = '(F0.8)') else rx_extra1 = rx[i].extra1
    rx_extra2 = n2s(rx[i].extra2, format = '(F0.9)')
    rx_extra3 = n2s(rx[i].extra3, format = '(F0.9)')
    rx_extra4 = n2s(rx[i].extra4, format = '(F0.9)')

    ; Write to file
    printf, unit, ed, $
      rx_longname, md, $
      rx_type, md, $
      rx_pupil, md, $
      rx_focus, md, $
      rx_init, md, $
      rx_fl, md, $
      rx_dist, md, $
      rx_zbeam, md, $
      rx_radius, md, $
      rx_radiusB, md, $
      rx_ellrec, md, $
      rx_aperobsc, md, $
      rx_angle, md, $
      rx_beamwalk, md, $
      rx_sptv, md, $
      rx_srms, md, $
      rx_spsdb, md, $
      rx_spsdc, md, $
      rx_spsdd, md, $
      rx_rptv, md, $
      rx_rrms, md, $
      rx_rpsdb, md, $
      rx_rpsdc, md, $
      rx_rpsdd, md, $
      rx_material, md, $
      rx_wave, md, $
      rx_extra1, md, $
      rx_extra2, md, $
      rx_extra3, md, $
      rx_extra4, ed, $
      format = format
  endfor
end