pro e2e_gen_maps, best_case = BEST_CASE

;Startup                                                    
;-----------------------------------------------------------

;Load Simulation Parameters
sett = e2e_load_settings()

;Read in target structure
target_file= sett.datapath+'exotargets/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_targets.idl'
restore, target_file

;Array lengths
l = n_tags(targets.orbit)
n = n_elements(targets.pname)
m = n_elements(targets.window.time)

;Create Best-Case Brightness Maps (for the orbit tag this is set to first time entry)
;------------------------------------------------------------

;Initialize Arrays
star_map = dblarr(inst.pixnum,inst.pixnum,n) ;On-Axis Sources (Star)
best_dust_map = star_map ;All off-Axis Sources (Planet, Disk)
best_plan_map = star_map ;Only planet brightness

print,'Creating best case brightness maps...'
  for ii = 0, n-1 do begin
    star_map[*,*,ii] = starbright(star_map[*,*,ii],targets[ii].sfluxe) 
    best_plan_map[*,*,ii] = planlight2(best_plan_map[*,*,ii], inst, targets[ii].pinc, targets[ii].sdist*inst.owa*1.1, targets[ii].palb_geo, targets[ii].sname, targets[ii].srad, 10.^targets[ii].slum, targets[ii].stmod, targets[ii].sdist, 1.03*targets[ii].orbit.sep[0], targets[ii].orbit.tht[0],targets[ii].pfluxe)
    best_dust_map[*,*,ii] = planlight2(best_dust_map[*,*,ii], inst, targets[ii].pinc, targets[ii].sdist*inst.owa*1.1, targets[ii].palb_geo, targets[ii].sname, targets[ii].srad, 10.^targets[ii].slum, targets[ii].stmod, targets[ii].sdist, 1.03*targets[ii].orbit.sep[0], targets[ii].orbit.tht[0],targets[ii].pfluxe , /dust)
  endfor

check_and_mkdir, 'data/rawmaps'
save, star_map, best_dust_map, best_plan_map, filename = 'data/rawmaps/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'bestcase_rawmaps.idl'
print, 'Saved: data/rawmaps/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'bestcase_rawmaps.idl'

;Create Brightness maps for all time points in Obs Window
;-----------------------------------------------------
if not keyword_set(best_case) then begin

  ;Initialize Arrays
  dust_maps = dblarr(inst.pixnum,inst.pixnum,n,m) ;All off-Axis Sources (Planet, Disk)
  plan_maps = star_map ;Only planet brightness

  print,'Generating brightness maps for targets during obervation window...'

  for ii = 0, n-1 do begin
    for jj = 0,m-1 do begin
      plan_maps[*,*,ii,jj] = planlight2(plan_maps[*,*,ii,jj], inst, targets[ii].pinc, targets[ii].sdist*inst.owa*1.1, targets[ii].palb_geo, targets[ii].sname, targets[ii].srad, 10.^targets[ii].slum, targets[ii].stmod, targets[ii].sdist, 1.03*targets[ii].window.sep[jj], targets[ii].window.tht[jj],targets[ii].pfluxe)
      dust_maps[*,*,ii,jj] = planlight2(dust_maps[*,*,ii,jj], inst, targets[ii].pinc, targets[ii].sdist*inst.owa*1.1, targets[ii].palb_geo, targets[ii].sname, targets[ii].srad, 10.^targets[ii].slum, targets[ii].stmod, targets[ii].sdist, 1.03*targets[ii].window.sep[jj], targets[ii].window.tht[jj], targets[ii].pfluxe, /dust)
    endfor

    counter, ii, n, 'Target '
  endfor

  check_and_mkdir, 'data/rawmaps'
  save, star_map, dust_maps, plan_maps, filename = 'data/rawmaps/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'obs_rawmaps.idl'

endif

end