pro e2e_gen_maps, target_overwrite=target_overwrite

;Generates Raw Brightness maps of target stars

;Keywords:
;target_overwrite - Disable file check for targetlist of same name. If used, will run exotargets and overwrite.


;Startup                                                    
;-----------------------------------------------------------

;Load Simulation Parameters
sett = e2e_load_settings()

cd, sett.path

;Check for target list, run exotargets if needed
;-----------------------------------------------------------

target_file='input/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_targets.idl'

if keyword_set(target_overwrite) or not file_test(target_file) then begin

  print, 'Getting targetlist...'

  cd, sett.exo.path
  exo_target_file = 'output/targets/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_targets.idl'
  
  if not file_test(exo_target_file) then begin

    print, 'exotargets catalog not found, running exotargets...'

    ;Check exotarget directories for needed catalogs, build if not there
    cat_test = 0
    if not file_test('output/catalog/catalog_'+sett.exo.catalog+'.idl') then cat_test = 2
    if not file_test('output/catalog/'+sett.exo.catalog+'.idl') then cat_test = 1

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

    exotargets, sett.exo.instname, sett.exo.catalog, force_include=sett.exo.force_include, plot_skip=sett.exo.plot_skip, hilton_phase=sett.exo.hilton_phase, $
                rayleigh_scatter=sett.exo.rayleigh_scatter, picasso=sett.exo.picasso, calc_maxtime=sett.exo.calc_maxtime, postfactor=sett.exo.postfactor
  endif

  ;Open Target and Instrument Structures
  restore, exo_target_file

  ;Trim Catalog to IWA, OWA
  sel = where((planet.use AND (planet.psepa ge inst.iwa) AND (planet.psepa le inst.owa)) OR planet.force, nplanet)
  print, n2s(nplanet)+' planets within FOV'
  targets = planet[sel]

  ;Trim Catalog to times in observation window
  ;;

  ;Add fields to planet and instrument structures
  struct_add_field, inst, 'pixnum', fix(16*ceil(2*inst.owa*1.1/inst.platescale/16) > 144)     ;Number of pixels/line (From Exotargets Default)

  cd,sett.path
  print, 'Wrote: '+'input/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_targets.idl'
  save,inst,targets,filename=target_file

endif

restore, target_file

;Create Raw Brightness Maps
;------------------------------------------------------------

;Initialize Arrays
sz = size(targets.pname)

star_map = dblarr(inst.pixnum,inst.pixnum,sz[1]) ;On-Axis Sources (Star)
dust_map = star_map ;All off-Axis Sources (Planet, Disk)
plan_map = star_map ;Only planet brightness

print,'Creating brightness maps...'
for ii = 0, sz[1]-1 do begin
  star_map[*,*,ii] = starbright(star_map[*,*,ii],targets[ii].sfluxe) 
  dust_map[*,*,ii] = planlight(dust_map[*,*,ii], targets[ii], inst, /dust)
  plan_map[*,*,ii] = planlight(plan_map[*,*,ii], targets[ii],inst)
endfor

save, star_map, dust_map, plan_map, filename = 'output/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_raw_maps.idl'

end