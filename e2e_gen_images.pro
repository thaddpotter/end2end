pro e2e_gen_images

;Documentation goes here

;Load settings block
sett = e2e_load_settings()

;--Load input data---------------------------------------

;Brightness maps
mapfile='output/'+strlowcase(sett.exo.instbase)+'_'+strjoin(sett.exo.catalog,'_')+'_raw_maps.idl'
restore, mapfile

;Inst PSF


;Contrast Maps


;VVC Transmission Map



;--Generate Images---------------------------------------

;Convolve with PSF


;Run Through Coronagraph

;On Axis Sources (VVC Transmission)

;Off Axis Sources (Contrast Map)




end