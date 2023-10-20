pro check_dist, array1, array2
  compile_opt idl2
  sz = size(array1)
  distarr = dblarr(sz[2])
  for i = 0, sz[2] - 1 do begin
    for j = 0, sz[2] - 1 do begin
      distarr[j] = sqrt((array1[0, i] - array1[0, j]) ^ 2 + (array1[1, i] - array1[1, j]) ^ 2 + (array1[2, i] - array1[2, j]) ^ 2)
      distarr[j] -= sqrt((array2[0, i] - array2[0, j]) ^ 2 + (array2[1, i] - array2[1, j]) ^ 2 + (array2[2, i] - array2[2, j]) ^ 2)
    endfor
    print, distarr * 39.3701
  endfor
end