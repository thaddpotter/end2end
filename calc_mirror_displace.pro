function calc_mirror_displace, tmp_struct, roc, conic, key, quiet = quiet
  compile_opt idl2
  ; -----------------------------------------------------
  ; Converts displacement of the optical bench to a coordinate system readable by ZEMAX
  ; Specifically, about the focus before m3, where the acquisition mirror is located
  ; Uses the unit vectors in the zemax frame as test points to solve for rotation angles
  ; (X,Y,Z Euler Angle Rotation)

  ; Coordinate system used: zemax global frame
  ; x: Along bench, away from electronics fin (short axis)
  ; y: Bench surface normal (X x Z)
  ; z: Along bench, away from M2 (long axis)
  ; Origin: Center of bench

  ; Arguments:
  ; tmp_struct - Structure Containing Lists of Coordinates
  ; roc - known radius of curvature for the optic
  ; conic - known conic constant for the optic
  ; key - id string for the optic

  ; Outputs:
  ; Displacement Vector:
  ; [X,Y,Z,U,V,W,e^2] | e^2 is the RMS error in mm

  ; -----------------------------------------------------

  ; Get column vectors
  x = tmp_struct.x
  y = tmp_struct.y
  z = tmp_struct.z

  u = tmp_struct.u1
  v = tmp_struct.v1
  w = tmp_struct.w1

  ; Trim list of test points to less than 1000 (speeds up computations)
  nx = n_elements(x)
  vec1 = transpose([[x], [y], [z]])
  if nx ge 1000 then begin
    div = n_elements(x) / 500
    base_data = vec1[*, 0 : nx - 1 : div]
  endif else base_data = vec1

  ; Initial guess
  case key of
    'M1': guess = [90d, 0d, 0.5d, 0d, 0.3d]
    'M2': guess = [-90d, 0d, 0d, 0d, 0d]
    else: begin
      print, 'No matching initial guess string'
      guess = [0d, 0d, 0d, 0d, 0d]
    endelse
  endcase

  ; Find initial coordinates of parent
  base_sol = fit_conic(base_data, roc, conic, guess = guess)

  if not keyword_set(quiet) then begin
    print, '--Initial Position Vector'
    print, 'Rx (deg): ' + n2s(base_sol[0])
    print, 'Rz (deg): ' + n2s(base_sol[1])
    print, 'X (m): ' + n2s(base_sol[2])
    print, 'Y (m): ' + n2s(base_sol[3])
    print, 'Z (m): ' + n2s(base_sol[4])
    print, 'RMS Distance from Base Fit: ' + n2s(1000 * sqrt(base_sol[5] / n_elements(x))) + ' mm'
  endif

  ; Transform base conic to local coords
  base_local = rotate_displace(base_data, base_sol[0], 0, base_sol[1], base_sol[2 : 4], /inverse)

  ; Rotate displacement vectors into local frame
  disp_global = transpose([[u], [v], [w]])
  disp_local = rotate_displace(disp_global, base_sol[0], 0, base_sol[1], [0, 0, 0], /inverse)

  ; Find coordinates of displaced optic in local frame
  disp_sol = fit_conic(base_local + disp_local, roc, conic)

  if not keyword_set(quiet) then begin
    print, '--Displacement Vector (in Initial Frame)'
    print, 'Rx (deg): ' + n2s(disp_sol[0])
    print, 'Rz (deg): ' + n2s(disp_sol[1])
    print, 'X (m): ' + n2s(disp_sol[2])
    print, 'Y (m): ' + n2s(disp_sol[3])
    print, 'Z (m): ' + n2s(disp_sol[4])
    print, 'RMS Distance from Disp Fit: ' + n2s(1000 * sqrt(disp_sol[5] / n_elements(x))) + ' mm'
  endif

  ; Calculate Residual Displacements
  res_disp = (base_local + disp_local) - rotate_displace(base_local, disp_sol[0], 0, disp_sol[1], disp_sol[2 : 4])

  ; Get coordinates of residual points
  res = base_local
  res[2, *] = 0
  res += res_disp

  return, [[base_sol[2 : 4], base_sol[0], base_sol[1], 1000 * sqrt(base_sol[5] / n_elements(x))], $
    [disp_sol[2 : 4], disp_sol[0], disp_sol[1], 1000 * sqrt(disp_sol[5] / n_elements(x))]]
end