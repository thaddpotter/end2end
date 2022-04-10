pro e2e_gen_images
;-------------------------------------------------------
;Runs the raw brightness maps through the instrument using outputs from piccsim
;
;Args:
;
;Keywords:
;
;Returns:
;
;------------------------------------------------------


;--Load input data---------------------------------------

;Settings block
sett = e2e_load_settings()
picc_sett = piccsim_load_settings(sett.picc.rx_base)

;Brightness maps
mapfile= sett.path + 'output/rawmaps/'+strlowcase(sett.exo.instname)+'_'+strjoin(sett.exo.catalog,'_')+'_rawmaps.idl'
restore, mapfile

n = n_elements(pnames)

;Gaussian PSF (Inst PSF?)
lod = 0.381      ;lod/px
sigma = 0.5*0.45/lod 

;Contrast Map
cpath = sett.picc.path + 'plots/sim_system/' + sett.picc.rx_base + '/'
cfile = 'sim_system_' + sett.picc.rx_base + '_pol0_sci_contrast_0024.fits'
contrast = readfits(cpath + cfile)

;Occulter Transmission Map
opath = sett.picc.path + 'output/transmission/' + sett.picc.rx_base + '/'
ofile = 'transmission_600000_512_pol0.fits'
occulter = readfits(opath + ofile)


stop

;--Generate Images---------------------------------------

;--Convolve with PSF
for i = 0,n-1 do begin
    star_map[*,*,i] = gauss_smooth(star_map[*,*,i],sigma,/edge_truncate)
    dust_map[*,*,i] = gauss_smooth(dust_map[*,*,i],sigma,/edge_truncate)
    plan_map[*,*,i] = gauss_smooth(plan_map[*,*,i],sigma,/edge_truncate)
endfor

;--Run Through Coronagraph



;--On Axis Sources (Occulter Transmission)

;Off Axis Sources (Contrast Map)

;Add results






end