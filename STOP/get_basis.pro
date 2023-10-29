function get_basis, arr
  compile_opt idl2
  ; Get points from the rows of the array
  p1 = arr[*, 0]
  p2 = arr[*, 1]
  p3 = arr[*, 2]

  ; Using point 1 as the origin, get two vectors along the surface
  ; The first one will be the new x axis, so normalize it
  x = (p2 - p1) / norm(p2 - p1)
  v1 = (p3 - p1)

  ; Z is the normalized crossproduct of the two vectors
  z = crossp(x, v1)
  z /= norm(z)

  ; Z cross X equals Y
  y = crossp(z, x)
  return, [[x], [y], [z]]
end