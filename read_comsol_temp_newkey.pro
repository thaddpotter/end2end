function read_comsol_temp_newkey, file

;;Define Structure
struct_base = {Time: 0d,$     ;Keys for temperature probes
                T25: 0d,$       ;Out of order due to COMSOL geometric point ordering
                T35: 0d,$
                OBM2: 0d,$
                OBM3: 0d,$
                M1B2: 0d,$
                M1P2: 0d,$
                M1G2: 0d,$
                M1B1: 0d,$
                M1B3: 0d,$
                T15: 0d,$
                T45: 0d,$
                M1P1: 0d,$
                M1P3: 0d,$
                M1G1: 0d,$
                T24: 0d,$
                T34: 0d,$
                M1G3: 0d,$
                OBM1: 0d,$
                T33: 0d,$
                T23: 0d,$
                T14: 0d,$
                T44: 0d,$
                T22: 0d,$
                T32: 0d,$
                T13: 0d,$
                T43: 0d,$
                T12: 0d,$
                T42: 0d,$
                M2PL: 0d,$
                T21: 0d,$
                T31: 0d,$
                T11: 0d,$
                T41: 0d,$
                OBB2: 0d,$
                OBB3: 0d,$
                OBB1: 0d,$
                M2GL: 0d $
                }

;Read table
readcol, file, time,T25,T35,OBM2,OBM3,M1B2,M1P2,M1G2,M1B1,M1B3,T15,T45,M1P1,M1P3,M1G1,T24,T34,M1G3,OBM1, $
    T33,T23,T14,T44,T22,T32,T13,T43,T12,T42,M2PL,T21,T31,T11,T41,OBB2,OBB3,OBB1,M2GL, $
    comment='%', FORMAT = 'D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D'

struct_full = replicate(struct_base,n_elements(time))

;Fill output structure
struct_full[*].time = time
struct_full[*].t11 = t11
struct_full[*].t12 = t12
struct_full[*].t13 = t13
struct_full[*].t14 = t14
struct_full[*].t15 = t15
struct_full[*].t21 = t21
struct_full[*].t22 = t22
struct_full[*].t23 = t23
struct_full[*].t24 = t24
struct_full[*].t25 = t25
struct_full[*].t31 = t31
struct_full[*].t32 = t32
struct_full[*].t33 = t33
struct_full[*].t34 = t34
struct_full[*].t35 = t35
struct_full[*].t41 = t41
struct_full[*].t42 = t42
struct_full[*].t43 = t43
struct_full[*].t44 = t44
struct_full[*].t45 = t45
struct_full[*].obb1 = obb1
struct_full[*].obb2 = obb2
struct_full[*].obb3 = obb3
struct_full[*].obm1 = obm1
struct_full[*].obm2 = obm2
struct_full[*].obm3 = obm3
struct_full[*].m1b1 = m1b1
struct_full[*].m1b2 = m1b2
struct_full[*].m1b3 = m1b3
struct_full[*].m1p1 = m1p1
struct_full[*].m1p2 = m1p2
struct_full[*].m1p3 = m1p3
struct_full[*].m1g1 = m1g1
struct_full[*].m1g2 = m1g2
struct_full[*].m1g3 = m1g3
struct_full[*].m2pl = m2pl
struct_full[*].m2gl = m2gl

return, struct_full

end