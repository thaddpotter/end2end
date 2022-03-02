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
picc_sett = piccsim_load_settings()

;Brightness maps
mapfile='output/'+strlowcase(sett.exo.instbase)+'_'+strjoin(sett.exo.catalog,'_')+'_raw_maps.idl'
restore, mapfile

n = n_elements(pnames)

;Gaussian PSF (Inst PSF?)
lod = 0.381      ;lod/px
sigma = 0.5*0.45/lod 

for i = 0,n-1 do begin
    star_map[*,*,i] = gauss_smooth(star_map[*,*,i],sigma,/edge_truncate)
    dust_map[*,*,i] = gauss_smooth(dust_map[*,*,i],sigma,/edge_truncate)
    plan_map[*,*,i] = gauss_smooth(plan_map[*,*,i],sigma,/edge_truncate)
endfor



;Contrast Maps


;VVC Transmission Map



;--Generate Images---------------------------------------

;Convolve with PSF


;Run Through Coronagraph

;On Axis Sources (VVC Transmission)

;Off Axis Sources (Contrast Map)

;Add results






end