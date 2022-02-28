pro e2e_gen_maps, plot_maps=plot_maps

;--Startup----------------------------------------------------------

;Load Simulation Parameters
sett = e2e_load_settings()

;Read in target structure
target_file= sett.outpath+'targets/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_targets.idl'
restore, target_file

;Array lengths
l = n_tags(targets.orbit)
n = n_elements(targets.pname)
m = n_elements(targets.window.time) ;Old index for doing all points in obs window

;Constants
au = 1.496d11 ;AU in meters
rj = 7.1492d7 ;Jupter Radius in meters

;Sampling information from piccsim
piccsim_settings = piccsim_load_settings(sett.picc.rx_base)
ngrid = piccsim_settings.gridsize

;--Create Best-Case Brightness Maps---------------------------------

;Initialize Arrays
star_map = dblarr(ngrid,ngrid,n) ;On-Axis Sources (Star)
dust_map = star_map ;All off-Axis Sources (Planet, Disk)
plan_map = star_map ;Only planet brightness

print,'Calculating brightness maps...'

!except = 0 ;Zodipic Likes to send a lot of floating underflows
  for i = 0, n-1 do begin

    counter, i+1, n, 'Target '
    ;Star Brightness
    star_map[*,*,i] = starbright(star_map[*,*,i],targets[i].sfluxe)

    ;Check if planet is larger than 1 pixel
    if ( (20*rj*targets[i].prad) GE (au*targets[i].sdist*inst.platescale) ) then print, 'Warning: Target '+targets[i].pname+' is at least on the order of the final pixel size!'
    
    ;Dust and planet brightness
    plan_map[*,*,i] = planlight(plan_map[*,*,i], targets[i], inst, ngrid)
    dust_map[*,*,i] = planlight(plan_map[*,*,i], targets[i], inst, ngrid, /dust)
  endfor
!except = 1 ;Back to normal

;--Save data to file--------------------------------
check_and_mkdir, 'output/rawmaps'
pnames = targets.pname
save, pnames, star_map, dust_map, plan_map, filename = 'output/rawmaps/'+strlowcase(sett.exo.instname)+'_'+sett.exo.catalog+'_rawmaps.idl'
print, 'Saved: output/rawmaps/'+strlowcase(sett.exo.instname)+'_'+sett.exo.catalog+'_rawmaps.idl'

;--Plot Maps---------------------------------------------
if keyword_set(plot_maps) then begin

    plotdir = sett.plotpath + 'rawmaps/'
    check_and_mkdir, plotdir

    ;Loop over planets, save to fits
    for i=0,n-1 do begin
        plotfile=pnames[i]
        writefits, plotdir+plotfile, alog10(plan_map[*,*,i] + dust_map[*,*,i])
    endfor

    print,'Wrote: '+n2s(n)+' raw brightness maps to fits'
endif

end