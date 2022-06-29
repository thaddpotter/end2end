function dist_min, rotate
;Minimizing function for use in finding the correct rotations of the bench

;Read in Common Block
COMMON benchblock, input, target

x = rotate[0]
y = rotate[1]
z = rotate[2]

;Do the rotation
tmp = rotate_displace(input,x,y,z,[0,0,0])

;Calculate total square distance
return, total( (target - tmp)^2 )

end

function calc_bench_displace, tmp_struct, quiet=quiet
;-----------------------------------------------------
;Converts displacement of the optical bench to a coordinate system readable by ZEMAX
;Specifically, about the focus before m3, where the acquisition mirror is located
;Uses the unit vectors in the zemax frame as test points to solve for rotation angles
;(X,Y,Z Euler Angle Rotation)

;Coordinate system used: zemax global frame
;x: Along bench, away from electronics fin (short axis)
;y: Bench surface normal (X x Z)
;z: Along bench, away from M2 (long axis)
;Origin: Center of bench

;Arguments:
;tmp_struct - structure that contains lists of coordinates for the bench

;Outputs:
;Displacement Vector:
;[X,Y,Z,U,V,W,e^2] | e^2 is the RMS error in mm

;-----------------------------------------------------

;--Setup--------------------
COMMON benchblock, zframe1, zframe2 ;Common Block Variables

;Get column vectors, combine into arrays
x = tmp_struct.X
y = tmp_struct.Y
z = tmp_struct.Z
pointarray = transpose([[x],[y],[z]])

u = tmp_struct.U1
v = tmp_struct.V1
w = tmp_struct.W1
disparray = transpose([[u],[v],[w]])

disppoint = pointarray + disparray ;Displaced Coordinates

;Split into vectors
a1 = pointarray[*,0]
b1 = pointarray[*,1]
c1 = pointarray[*,2]
d1 = pointarray[*,3]

a2 = disppoint[*,0]
b2 = disppoint[*,1]
c2 = disppoint[*,2]
d2 = disppoint[*,3]

;Coordinates of the focus in the frame of the bench 
f_b = [0.034036d, 0.09144d, 0.075438d] ;meters

;--Find Coord Relations------

;Find origins
o1 = (a1 + b1 + c1 + d1)/4
o2 = (a2 + b2 + c2 + d2)/4

;Unit Vectors
x1 = (b1 - a1)/norm(b1 - a1)
z1 = (d1 - b1)/norm(d1 - b1)
y1 = crossp(x1,z1)

x2 = (b2 - a2)/norm(b2 - a2)
z2 = (d2 - b2)/norm(d2 - b2)
y2 = crossp(x2,z2)

;Find location of foci
f1 = o1 + total(f_b[0] * x1) + total(f_b[1] * y1) + total(f_b[2] * z1)
f2 = o2 + total(f_b[0] * x2) + total(f_b[1] * y2) + total(f_b[2] * z2)

;--Calculate Displacement Vector------------

;Adjust angles of basis vectors from secondary rotation? (beam not parallel to z here...)


;get translation, convert to zemax basis
translate = convert_basis( f2 - f1 , [[x1],[y1],[z1]] )

;shift origins to foci
zframe1 = pointarray - rebin(f1, 3,4)
zframe2 = disppoint - rebin(f2, 3,4)

;--Solve for rotation angles-----------------
guess = [0d,0d,0d]
gi = IDENTITY(3)
ftol = 1e-8

Powell, guess, gi,ftol,fmin, 'dist_min'

if not keyword_set(quiet) then begin
    print, 'Rotation about x: ' + n2s(guess[0])
    print, 'Rotation about y: ' + n2s(guess[1])
    print, 'Rotation about z: ' + n2s(guess[2])
    print, 'Mean Error (mm): ' +  n2s(250d*fmin)
endif

return, [translate,guess,250d*fmin]

end