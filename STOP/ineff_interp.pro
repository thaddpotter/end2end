; Uses a massive oversampling of TRIGRID to get results at arbitrary points
function ineff_interp, surf_points, eval_points
  compile_opt idl2

  ; get eval points for output (must be sorted and contain no duplicates)
  x1 = eval_points[0, *]
  y1 = eval_points[1, *]

  xout = x1[uniq(x1, sort(x1))]
  yout = y1[uniq(y1, sort(y1))]

  ; Triangulate
  triangulate, surf_points[0, *], surf_points[1, *], triangles, bounds

  ; make a really dense trigrid evaluation
  bigmap = trigrid(surf_points[0, *], surf_points[1, *], surf_points[2, *], triangles, extra = bounds, xout = xout, yout = yout)

  ; >Loop through the points to find the vertices that match our initial points
  ; >"where" would work, but just in case of any precision errors that cause EQ
  ; to fail, I grab the nearest point and use its value to avoid NaNs
  zout = dblarr(1, n_elements(x1))
  for i = 0, n_elements(x1) - 1 do begin
    dx = min(abs(xout - x1[i]), ix)
    dy = min(abs(yout - y1[i]), iy)
    zout[i] = bigmap[ix, iy]
  endfor

  return, zout
end