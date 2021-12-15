function planlight, map1, inst, pinc, radout, albedo, zodis=ZODIS, sname, rstar, lstar, tstar, sdist, radring, tht, pflux, dust=dust

  ;;Run Zodipic
  ;;Need to check how to set up zodis keyword (Multiplier on zodi brightness). Example from zodipic lists eps eri as 67000 from:
  ;;https://arxiv.org/pdf/astro-ph/9808224.pdf
  ;;Have flux from zodi, way to relate this to an absolute flux?

  ;;Also, look into setting up the ring keyword for planetary dust trail (ring = 1, radring = 1.03*target.psepd, earthlong = 0?)

  ;;Will also need catalog of dust disk inner and outer radii! If planet is inside of dust disk, then it is highly unlikely to be seen!
  ;;Look through Glenn's thesis and citations

  ;;Cache ZODIPIC results to speed up, running 30k iterations of zodipic is a bit ridiculous....

  if not keyword_set(zodis) then zodis = 1


  if keyword_set(dust) then begin
    zodipic, fnu, 1000*inst.platescale, inst.lambda, pixnum = inst.pixnum, $
      inclination = pinc, radout = radout, albedo = albedo, zodis = zodis, $
      starname = sname, rstar = rstar, lstar = lstar, tstar = tstar, distance = sdist, $
      blob=1, ring = 1, radring = radring, earthlong = tht, /nodisplay, /quiet

      map1 += fnu
  endif else begin

    ;;Locate planet on sky, scale to pixels
    xf = radring*[cos(tht), sin(tht)]
    x_scale = ceil(xf / (inst.platescale*sdist))
    
    ;;add planet brightness
    map1[inst.pixnum/2 + x_scale[0], inst.pixnum/2 + x_scale[1]] += pflux
  endelse

  return, map1
end