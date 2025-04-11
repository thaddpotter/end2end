pro e2e_read_targetlist, overwrite = OVERWRITE
  compile_opt idl2

  ; Generates Raw Brightness maps of target stars

  ; Keywords:
  ; OVERWRITE - Disable file check for targetlist of same name. If used, will run exotargets and overwrite.

  ; --Startup-----------------------------------------------------------

  ; Load Simulation Parameters
  sett = e2e_load_settings()
  cd, sett.path

  ; --Check for target list, run exotargets if needed---------------------
  target_file = sett.datapath + 'targets/' + strlowcase(sett.exo.instname) + '_' + strjoin(sett.exo.catalog, '_') + '_targets.idl'

  if keyword_set(OVERWRITE) or not file_test(target_file) then begin
    print, 'Getting targetlist from exotargets...'

    cd, sett.exo.path
    exo_target_file = 'output/targets/' + strlowcase(sett.exo.instname) + '_' + strjoin(sett.exo.catalog, '_') + '_targets.idl'

    if not file_test(exo_target_file) then begin
      print, 'exotargets catalog not found, running exotargets...'

      ; Check exotarget directories for needed catalogs, build if not there
      cat_test = 0
      if not file_test('output/catalog/catalog_' + sett.exo.catalog + '.idl') then cat_test = 2
      if not file_test('output/catalog/' + sett.exo.catalog + '.idl') then cat_test = 1

      case cat_test of
        0: break
        1: begin
          print, 'exotargets input catalog(s) missing, rebuilding...'
          mkcatalog, /rebuild
        end
        2: begin
          print, 'exotargets output catalog(s) missing, writing...'
          mkcatalog
        end
      endcase

      exotargets, sett.exo.instname, sett.exo.catalog, force_include = sett.exo.force_include, plot_skip = sett.exo.plot_skip, calc_maxtime = sett.exo.calc_maxtime
    endif

    ; Open Target and Instrument Structures
    restore, exo_target_file

    ; --Catalog Trimming----------------------------------------

    ; IWA, OWA
    sel = where((planet.use and (planet.psepa ge inst.iwa) and (planet.psepa le inst.owa)) or planet.force, nplanet)
    print, n2s(nplanet) + ' planets within FOV'
    targets = planet[sel]

    ; Add fields to planet and instrument structures
    struct_add_field, inst, 'pixnum', fix(16 * ceil(2 * inst.owa * 1.1 / inst.platescale / 16) > 144) ; Number of pixels/line (From Exotargets Default)

    ; Write Structure to File
    cd, sett.path
    check_and_mkdir, sett.datapath + 'targets'
    save, inst, targets, filename = target_file
    print, 'Wrote targetlist for ' + strlowcase(sett.exo.instname) + ' to: ' + sett.datapath + 'targets'
  endif else print, 'Targetlist already exists'
end
