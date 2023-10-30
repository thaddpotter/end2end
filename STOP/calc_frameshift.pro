function frameshift_opt, params
  compile_opt idl2
  ; Optimization function for calculated coordinate fram transformations
  ; Objective function is the RMS error of all points
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
  common frameshift_opt, input, output, orderflag

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
  if orderflag then $
    Rout = (Rfull # input) + trans else $
    Rout = Rfull # (input + trans)

  return, 1e6 * sqrt(total((Rout - output) ^ 2) / sz[2])
end

function frameshift_zonly, params
  compile_opt idl2
  ; Optimization function for calculated coordinate frame transformations
  ; Zonly - Maps planar set of points onto the xy plane, with the average
  ; position at the origin
  ; -----------------------------------------------
  ; Arguments:
  ; input: matrix of input points
  ; ----------------------------------------------
  ; Since this will also be used for calcuating in the Zemax frame, uses the following order convention:
  ; dx, dy, dz (dz is preceding surface thickness)
  ; X, Y', Z'' (Rotation about new axis after rotation)
  ;

  ; Variable import/setup
  common frameshift_opt, input

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

  Rfull = Rz # Ry # Rx
  Rout = Rfull # input

  trans = rebin(mean(Rout, dimension = 2), 3, sz[2])
  Rout -= trans

  return, 1e6 * sqrt(total((Rout[2, *] ^ 2)) / sz[2])
end

function calc_frameshift, r1, r2, guess = guess, flag = flag, zonly = zonly
  compile_opt idl2
  ; Performs a least squares fit for the rotation and displacement between two sets of points

  ; Return vector
  ; disp = [x,y,z,theta,phi,psi]
  ;
  common frameshift_opt, input, output, orderflag

  input = r1
  output = r2
  if keyword_set(flag) then orderflag = 1 else orderflag = 0

  ; Minimization Settings
  if ~keyword_set(guess) then $
    guess = [0.0d, 0.0d, 0.0d, 0.1d, 0.1d, 0.1d] ; Initial Guess
  ; Bounds on parameters
  xbnd = [[-360, -360, -360, -10d, -10d, -10d], $
    [360, 360, 360, 10d, 10d, 10d]]
  ; Bound on function
  gbnd = [[-1], [1e30]]

  if keyword_set(zonly) then begin
    constrained_min, guess, xbnd, gbnd, 0, 'frameshift_zonly', inform, epstop = 1e-18, limser = 100000, nstop = 100
    fmin = frameshift_zonly(guess)
  endif else begin
    constrained_min, guess, xbnd, gbnd, 0, 'frameshift_opt', inform, epstop = 1e-18, limser = 100000, nstop = 100
    fmin = frameshift_opt(guess)
  endelse

  ; Return error in RMS ppm
  return, [guess, fmin]
end