function write_zemax, unit, file
  ; ----------------------------------------------
  ; Documentation goes here
  ; ----------------------------------------------
  compile_opt idl2

  ; Open file
  openw, unit, file

  ; Write Headers
  ; -------------------------------------------------------
  printf, unit, 'VERS 130723 1235 34697'
  printf, unit, 'MODE SEQ'
  printf, unit, 'NAME'

  printf, unit, 'PFIL 0 0 0'
  printf, unit, 'UNIT IN X W X CM MR CPMM'

  ; Entrance Pupil information
  printf, unit, 'ENPD 2.35E+1'
  printf, unit, 'ENVD 2.0E+1 1 0'

  ; Glass Catalog
  printf, unit, 'GFAC 0 0'
  printf, unit, 'GCAT SCHOTT INFRARED HIKARI MISC'

  ; Other general settings
  printf, unit, 'RAIM 0 0 1 1 0 0 0 0 0'
  printf, unit, 'PUSH 0 0 0 0 0 0'
  printf, unit, 'SDMA 0 1 0'
  printf, unit, 'FTYP 0 0 1 5 0 0 1'
  printf, unit, 'ROPD 2'
  printf, unit, 'PICB 1'

  ; Fields?
  printf, unit, 'XFLN 0 -8.333E-2 2.777E-3 5.5555E-3 8.3333E-3 6.6667E-2 0 5.0E-2 3.333E-2 0 0 0'
  printf, unit, 'YFLN 0 0 0 0 0 0 1.667E-2 0 0 0 0 0'
  printf, unit, 'FWGN 1 1 1 1 1 1 1 1 1 1 1 1'
  printf, unit, 'VDXN 0 0 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'VDYN 0 0 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'VCXN 0 0 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'VCYN 0 0 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'VANN 0 0 0 0 0 0 0 0 0 0 0 0'

  ; Waves
  printf, unit, 'WAVM 1 6.0E-1 1'
  printf, unit, 'WAVM 2 5.4E-1 1'
  printf, unit, 'WAVM 3 5.7E-1 1'
  printf, unit, 'WAVM 4 6.3E-1 1'
  printf, unit, 'WAVM 5 6.6E-1 1'
  printf, unit, 'WAVM 6 5.5E-1 1'
  printf, unit, 'WAVM 7 5.5E-1 1'
  printf, unit, 'WAVM 8 5.5E-1 1'
  printf, unit, 'WAVM 9 5.5E-1 1'
  printf, unit, 'WAVM 10 5.5E-1 1'
  printf, unit, 'WAVM 11 5.5E-1 1'
  printf, unit, 'WAVM 12 5.5E-1 1'
  printf, unit, 'WAVM 13 5.5E-1 1'
  printf, unit, 'WAVM 14 5.5E-1 1'
  printf, unit, 'WAVM 15 5.5E-1 1'
  printf, unit, 'WAVM 16 5.5E-1 1'
  printf, unit, 'WAVM 17 5.5E-1 1'
  printf, unit, 'WAVM 18 5.5E-1 1'
  printf, unit, 'WAVM 19 5.5E-1 1'
  printf, unit, 'WAVM 20 5.5E-1 1'
  printf, unit, 'WAVM 21 5.5E-1 1'
  printf, unit, 'WAVM 22 5.5E-1 1'
  printf, unit, 'WAVM 23 5.5E-1 1'
  printf, unit, 'WAVM 24 5.5E-1 1'

  ; Pol and ???
  printf, unit, 'PWAV 1'
  printf, unit, 'POLS 0 1 0 0 0 1 0'
  printf, unit, 'GLRS 3 0'
  printf, unit, 'GSTD 0 100.000 100.000 100.000 100.000 100.000 100.000 0 1 1 0 0 1 1 1 1 1 1'
  printf, unit, 'NSCD 100 500 0 1.0E-3 5 1.0E-6 0 0 0 0 0 0 1000000 0 2'
  printf, unit, 'COFN QF "COATING_mendillo.DAT" "SCATTER_PROFILE.DAT" "ABG_DATA.DAT" "PROFILE.GRD"'
  printf, unit, 'COFN COATING_mendillo.DAT SCATTER_PROFILE.DAT ABG_DATA.DAT PROFILE.GRD'

  ; Surfaces
  ; -----------------------------------------
  printf, unit, 'SURF 0'
  printf, unit, 'TYPE STANDARD'
  printf, unit, 'CURV 0.0 0 0 0 0 ""'
  printf, unit, 'HIDE 0 0 1 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 4'
  printf, unit, 'DISZ INFINITY'
  printf, unit, 'DIAM 0 1 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'

  printf, unit, 'SURF 1'
  printf, unit, 'COMM To M1'
  printf, unit, 'STOP'
  printf, unit, 'TYPE STANDARD'
  printf, unit, 'CURV 0.0 0 0 0 0 ""'
  printf, unit, 'HIDE 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 9'
  printf, unit, 'DISZ 7.5E+1'
  printf, unit, 'DIAM 1.175E+1 1 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'
  printf, unit, 'CLAP 0 1.175E+1 0'

  ; FLAG FOR M1 DISPLACE
  printf, unit, 'SURF 2'
  printf, unit, 'COMM Decenter to M1'
  printf, unit, 'TYPE COORDBRK'
  printf, unit, 'CURV 0.0 0 0.0 0.0 0'
  printf, unit, 'HIDE 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 2'
  printf, unit, 'SCBD 3 -1 -1'
  printf, unit, 'PARM 1 0'
  printf, unit, 'PARM 2 -1.6E+1'
  printf, unit, 'PARM 3 0'
  printf, unit, 'PARM 4 0'
  printf, unit, 'PARM 5 0'
  printf, unit, 'PARM 6 0'
  printf, unit, 'DISZ 0'
  printf, unit, 'DIAM 0 0 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'

  ; FLAG FOR M1 Sag
  printf, unit, 'SURF 3'
  printf, unit, 'COMM M1'
  printf, unit, 'TYPE STANDARD'
  printf, unit, 'CURV -8.333333333333000200E-003 0 0 0 0 ""'
  printf, unit, 'COAT QUANTUM_FSS99'
  printf, unit, 'HIDE 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 4.0'
  printf, unit, 'SLAB 1'
  printf, unit, 'DISZ -6.E+1'
  printf, unit, 'GLAS MIRROR 0 0 1.5 4.0E+1 0 0 0 0 0 0 '
  printf, unit, 'CONI -1.'
  printf, unit, 'DIAM 2.8E+1 1 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'
  printf, unit, 'CLAP 0 1.3E+1 0'
  printf, unit, 'OBDC 0.000000000000E+000 1.600000000000E+001'

  ; FLAG for M2 Displace, error check on coord return
  printf, unit, 'SURF 4'
  printf, unit, 'COMM F1 to M2'
  printf, unit, 'TYPE COORDBRK'
  printf, unit, 'CURV 0.0 0 0.0 0.0 0'
  printf, unit, 'HIDE 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 18'
  printf, unit, 'PARM 1 0'
  printf, unit, 'PARM 2 0'
  printf, unit, 'PARM 3 0'
  printf, unit, 'PARM 4 1.273570113001'
  printf, unit, 'PARM 5 0'
  printf, unit, 'PARM 6 0'
  printf, unit, 'DISZ -1.21221445045E+1'
  printf, unit, 'DIAM 0 0 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'

  ; Flag for M2 Displace
  printf, unit, 'SURF 5'
  printf, unit, 'COMM Element Tilt'
  printf, unit, 'TYPE COORDBRK'
  printf, unit, 'CURV 0.0 0 0.0 0.0 0'
  printf, unit, 'HIDE 0 0 0 1 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 10'
  printf, unit, 'PARM 1 0'
  printf, unit, 'PARM 2 0'
  printf, unit, 'PARM 3 0'
  printf, unit, 'PARM 4 0'
  printf, unit, 'PARM 5 0'
  printf, unit, 'PARM 6 0'
  printf, unit, 'DISZ 0'
  printf, unit, 'DIAM 0 0 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'

  ; Flag for M2 Sag
  printf, unit, 'SURF 6'
  printf, unit, 'COMM M2'
  printf, unit, 'TYPE STANDARD'
  printf, unit, 'CURV 5.000000000000000300E-002 0 0 0 2 ""'
  printf, unit, 'COAT EMF_AG99'
  printf, unit, 'HIDE 0 0 0 0 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 1'
  printf, unit, 'SLAB 6'
  printf, unit, 'DISZ 0'
  printf, unit, 'GLAS MIRROR 0 0 1.5 4.0E+1 0 0 0 0 0 0 '
  printf, unit, 'CONI -4.223350319295E-1'
  printf, unit, 'DIAM 6.0 1 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'
  printf, unit, 'CLAP 0 3.55 0'
  printf, unit, 'OBDC 2.631050000000E-001 -3.373494000000E+000'

  ; Flag for error checking on coord return
  printf, unit, 'SURF 7'
  printf, unit, 'COMM Element Tilt:return'
  printf, unit, 'TYPE COORDBRK'
  printf, unit, 'CURV 0.0 0 0.0 0.0 0'
  printf, unit, 'HIDE 0 0 0 1 0 0 0 0 0 0'
  printf, unit, 'MIRR 2 0'
  printf, unit, 'SLAB 11'
  printf, unit, 'PARM 1 0'
  printf, unit, 'PPAR 1 5 -1.000000000000E+000 0.000000000000E+000 0'
  printf, unit, 'PARM 2 0'
  printf, unit, 'PPAR 2 5 -1.000000000000E+000 0.000000000000E+000 0'
  printf, unit, 'PARM 3 0'
  printf, unit, 'PPAR 3 5 -1.000000000000E+000 0.000000000000E+000 0'
  printf, unit, 'PARM 4 0'
  printf, unit, 'PPAR 4 5 -1.000000000000E+000 0.000000000000E+000 0'
  printf, unit, 'PARM 5 0'
  printf, unit, 'PPAR 5 5 -1.000000000000E+000 0.000000000000E+000 0'
  printf, unit, 'PARM 6 1'
  printf, unit, 'DISZ 5.71221445045E+1'
  printf, unit, 'DIAM 0 0 0 0 1 ""'
  printf, unit, 'POPS 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0'

  return, !null
end