function planlight_old, map1, target, inst, dust=dust

  ;;Run Zodipic
  ;;Need to check how to set up zodis keyword (Multiplier on zodi brightness). Example from zodipic lists eps eri as 67000 from:
  ;;https://arxiv.org/pdf/astro-ph/9808224.pdf
  ;;Have flux from zodi, way to relate this to an absolute flux?

  ;;Also, look into setting up the ring keyword for planetary dust trail (ring = 1, radring = 1.03*target.psepd, earthlong = 0?)

  ;;Will also need catalog of dust disk inner and outer radii! If planet is inside of dust disk, then it is highly unlikely to be seen!
  ;;Look through Glenn's thesis and citations

  if keyword_set(dust) then begin
    zodipic, fnu, 1000*inst.platescale, inst.lambda, pixnum = inst.pixnum, $
      inclination = target.pinc, radout = target.sdist*inst.owa*1.1, albedo = target.palb_geo, zodis = 1, $
      starname = target.sname, rstar = target.srad, lstar = 10.^target.slum, tstar = target.stmod, distance = target.sdist, $
      blob=1, ring = 1, radring = 1.03*target.psepd, earthlong = target.orbit.tht, /nodisplay, /quiet
  endif else fnu = dblarr(inst.pixnum,inst.pixnum)

  ;;Check if planet is larger than 1 pixel
  

  ;;Locate planet on sky, scale to pixels
  xf = target.psepd*[cos(target.orbit.tht), sin(target.orbit.tht)]
  x_scale = ceil(xf / (inst.platescale*target.sdist))
  
  ;;add planet brightness
  fnu[inst.pixnum/2 + x_scale[0], inst.pixnum/2 + x_scale[1]] += target.pfluxe

  map1 = fnu

  return, map1
end