; Documentation
function apply_shift, points, shifts, nomove = nomove, rev = rev
  compile_opt idl2
  ; Applies coordiate shift according to Zemax's order conventions
  ; dx, dy, dz (dz is preceding surface thickness)
  ; X, Y', Z'' (Rotation about new axis after rotation)
  ; KEYWORDS:
  ; nomove - sets displacement to be 0
  ; rev - performs the reverse translation (needed to shift back after the surface)
  ;
  ; Variable import/setup
  disp = double(shifts[3 : 5])
  angle = double(shifts[0 : 2])

  ; Convert angles to radians
  a = angle[0] * !dtor
  b = angle[1] * !dtor
  c = angle[2] * !dtor

  ; Make rotation matrices for axes
  Rx = ax_angle([1, 0, 0], a)

  ; Y axis has changed!
  Ry = ax_angle(Rx # [0, 1, 0], b)

  ; Zaxis has changed twice!
  Rz = ax_angle(Ry # Rx # [0, 0, 1], c)

  Rfull = Rz # Ry # Rx

  ; Make translation matrix
  sz = size(points)
  trans = rebin(disp, 3, sz[2])

  case 1 of
    keyword_set(nomove) and (~keyword_set(rev)): $
      Rout = Rfull # points
    (~keyword_set(nomove)) and (~keyword_set(rev)): $
      Rout = Rfull # (points + trans)
    keyword_set(nomove) and keyword_set(rev): $
      Rout = transpose(Rfull) # points
    (~keyword_set(nomove)) and keyword_set(rev): $
      Rout = (transpose(Rfull) # points) - trans
  endcase
  return, Rout
end