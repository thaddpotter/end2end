function planlight, map1, target, inst, npixel, zodis = zodis, dust = dust
  compile_opt idl2
  ; --------------------------------------------------------------------------------
  ; Function for making off-axis brightness maps for end2end using ZODIPIC
  ;
  ; Args:
  ; npixel - Size of image (in pixels) zodipic will be evaluating
  ; map1 - npixel x npixel array to which the map will be written to
  ; target - target structure for system of interest
  ; inst - instrument structure
  ; zodis - zodiacal dust density (default is 1, which correlates to density in our solar system)
  ;
  ; Keywords:
  ; /dust - set this keyword to run zodipic and generate dust maps. Do not set to generate planet brightness map.

  ; Returns:
  ; map1 - Brightness map of system including the source of choice

  ; Currently, radin is 90% of IWA and radout is set to 110% of the OWA, (maximum dust case)

  ; --TODO---------------------------------------------------------------------------
  ; Need to check how to set up zodis keyword (Multiplier on zodi brightness). Example from zodipic lists eps eri as 67000 from:
  ; https://arxiv.org/pdf/astro-ph/9808224.pdf
  ; Have flux from zodi, way to relate this to an absolute flux?

  ; Will also need catalog of dust disk inner and outer radii! If planet is inside of dust disk, then it is highly unlikely to be seen!
  ; Look through Glenn's thesis and citations

  ; Cache results of zodipic to speed up if running multiple runs for same targets?
  ; ----------------------------------------------------------------------------------
  if not keyword_set(zodis) then zodis = 1

  if keyword_set(dust) then begin
    zodipic, fnu, 1000 * inst.platescale * inst.pixnum / npixel, inst.lambda / 1000, pixnum = npixel, $
      inclination = target.pinc, albedo = target.palb_geo, zodis = zodis, radin = 0.9 * target.sdist * inst.iwa, radout = 1.1 * target.sdist * inst.owa, $
      starname = target.sname, rstar = target.srad, lstar = 10. ^ target.slum, tstar = target.stmod, distance = target.sdist, $
      blob = 1, ring = 1, radring = 1.03 * target.orbit.sep[0], earthlong = target.orbit.tht[0], /nodisplay, /quiet

    map1 += fnu
  endif else begin
    ; ;Locate planet on sky, scale to pixels
    xf = target.orbit.sep[0] * [cos(target.orbit.tht[0]), sin(target.orbit.tht[0])]
    x_scale = ceil(xf / (inst.platescale * target.sdist))

    ; ;add planet brightness
    map1[inst.pixnum / 2 + x_scale[0], inst.pixnum / 2 + x_scale[1]] += target.pfluxe
  endelse

  return, map1
end