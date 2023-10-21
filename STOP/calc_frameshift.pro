function frameshift_opt, params
  compile_opt idl2
  ; Optimization function for calculated coordinate fram transformations
  ; -----------------------------------------------
  ; Arguments:
  ; input: matrix of input points
  ; output: matrix of output points
  ; ----------------------------------------------
  ; Since this will also be used for calcuating in the Zemax frame, uses the following order convention:
  ; dx, dy, dz (dz is preceding surface thickness)
  ; X, Y', Z'' (Rotation about new axis after rotation)
  ;

  ; Variable import/setup
  common frameshift_opt, input, output

  disp = double(params[3 : 5])
  angle = double(params[0 : 2])

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

  ; Make translation matrix
  sz = size(input)
  trans = rebin(disp, 3, sz[2])

  Rfull = Rz # Ry # Rx
  Rout = Rfull # (input + trans)

  return, total((Rout - output) ^ 2) / sz[2]
end

function calc_frameshift, r1, r2, guess = guess
  compile_opt idl2
  ; Performs a least squares fit for the rotation and displacement between two sets of points

  ; Return vector
  ; disp = [x,y,z,theta,phi,psi]
  ;
  common frameshift_opt, input, output

  input = r1
  output = r2

  ; Minimization Settings
  ftol = 1e-11 ; Fractional Tolerance
  if ~keyword_set(guess) then $
    guess = [0.0d, 0.0d, 0.0d, 0.1d, 0.1d, 0.1d] ; Initial Guess
  xi = identity(6) ; Starting Direction Vector

  powell, guess, xi, ftol, fmin, 'frameshift_opt', /double

  return, [guess, sqrt(fmin)]
end