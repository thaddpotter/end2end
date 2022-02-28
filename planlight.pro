function planlight, map1, target, inst, npixel, zodis = zodis, dust = dust

    ;Function for making off-axis brightness maps for end2end

    ;Need to check how to set up zodis keyword (Multiplier on zodi brightness). Example from zodipic lists eps eri as 67000 from:
    ;https://arxiv.org/pdf/astro-ph/9808224.pdf
    ;Have flux from zodi, way to relate this to an absolute flux?

    ;Will also need catalog of dust disk inner and outer radii! If planet is inside of dust disk, then it is highly unlikely to be seen!
    ;Look through Glenn's thesis and citations
    ;Currently, radin is the default: thermal destruction radius, and radout is set to 110% of the OWA, (maximum dust case)

    ;Cache results of zodipic to speed up if running multiple runs for same targets?

    if not keyword_set(zodis) then zodis = 1

    if keyword_set(dust) then begin
        zodipic, fnu, 1000*inst.platescale*inst.pixnum/npixel, inst.lambda/1000, pixnum = npixel, $
            inclination = target.pinc, albedo = target.palb_geo, zodis = zodis,radout = target.sdist*inst.owa*1.1, $
            starname = target.sname, rstar = target.srad, lstar = 10.^target.slum, tstar = target.stmod, distance = target.sdist, $
            blob=1, ring = 1, radring = 1.03*target.orbit.sep[0], earthlong = target.orbit.tht[0], /nodisplay, /quiet

    map1 += fnu
    endif else begin
        ;;Locate planet on sky, scale to pixels
        xf = target.orbit.sep[0]*[cos(target.orbit.tht[0]), sin(target.orbit.tht[0])]
        x_scale = ceil(xf / (inst.platescale*target.sdist))

        ;;add planet brightness
        map1[inst.pixnum/2 + x_scale[0], inst.pixnum/2 + x_scale[1]] += target.pfluxe
    endelse

    return, map1
    end