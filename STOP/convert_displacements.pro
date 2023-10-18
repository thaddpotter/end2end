pro convert_displacements, datapath, M1_ROTATE=M1_ROTATE, PRECISION=PRECISION, PART=PART
plotpath=strsplit(datapath,'/',/extract)
plottag=plotpath[1]
plotpath='plots/'+plottag+'/'
check_and_mkdir,plotpath

;;Precision -- number of decimal places in text file
ndp=1
if keyword_set(PRECISION) then ndp=PRECISION

;;Build mask
gs       = 512
theta=(dindgen(1000)/1000)*2*!dpi
r=253
xc=gs/2
yc=gs/2
xarr = r*cos(theta) + xc
yarr = r*sin(theta) + yc
xyimage,gs,gs,xim,yim,rim,/quadrant
masksel = where(rim lt r,complement=notmasksel)
mask = rim*0
mask[masksel]=1
surmap = mask

;;Part tags
part_tags  = ['001'       ,'104'         ,'105'           ,'106'          ,'107'          ,'m1','bench']
part_names = ['Strongback','Bench Pad 104','Bench Pad 105','Bench Pad 106','Hexapod Mount','M1','Optical Bench']
face_dim   = ['y','z','z','z','z','','']
face_val   = [-4.5,18.5,18.5,18.5,18.5,0,0]
nparts     = n_elements(part_tags)

;;Parts structure
part_struct={tag:'',name:'',found:0,face_dim:'',face_val:0d,$
             pdx:0d,pdy:0d,pdz:0d,ptx:0d,pty:0d,ptz:0d,$
             x:ptr_new(/allocate_heap),y:ptr_new(/allocate_heap),z:ptr_new(/allocate_heap),$
             dx:ptr_new(/allocate_heap),dy:ptr_new(/allocate_heap),dz:ptr_new(/allocate_heap)}
part=replicate(part_struct,nparts)
part.tag  = part_tags
part.name = part_names
part.face_dim = face_dim
part.face_val = face_val 

;;Read parts
print,'Reading from: '+datapath
print,'Found parts:'
for i=0,nparts-1 do begin
   ;;Read files
   xfiles = file_search(datapath+'*'+part[i].tag+'*_x.out',count=nxf)
   yfiles = file_search(datapath+'*'+part[i].tag+'*_y.out',count=nyf)
   zfiles = file_search(datapath+'*'+part[i].tag+'*_z.out',count=nzf)
   if nxf eq 0 OR nyf eq 0 OR nzf eq 0 then continue
   x=read_disp(file_search(datapath+'*'+part[i].tag+'*_x.out'))
   y=read_disp(file_search(datapath+'*'+part[i].tag+'*_y.out'))
   z=read_disp(file_search(datapath+'*'+part[i].tag+'*_z.out'))
   
   ;;Remove zero displacement nodes
   sel = where(x.d eq 0 OR y.d eq 0 or z.d eq 0,nsel,complement=notsel)
   if nsel gt 0 then begin
      x = x[notsel]
      y = y[notsel]
      z = z[notsel]
   endif

   ;;Pick face
   if part[i].face_dim eq 'x' then begin
      sel = where(x.x eq part[i].face_val,nsel)
      if nsel eq 0 then stop,'No nodes found for '+part[i].face_dim+' = '+n2s(part[i].face_val)+' on part '+part[i].tag
      x = x[sel]
      y = y[sel]
      z = z[sel]
   endif
   if part[i].face_dim eq 'y' then begin
      sel = where(x.y eq part[i].face_val,nsel)
      if nsel eq 0 then stop,'No nodes found for '+part[i].face_dim+' = '+n2s(part[i].face_val)+' on part '+part[i].tag
      x = x[sel]
      y = y[sel]
      z = z[sel]
   endif
   if part[i].face_dim eq 'z' then begin
      sel = where(x.z eq part[i].face_val,nsel)
      if nsel eq 0 then stop,'No nodes found for '+part[i].face_dim+' = '+n2s(part[i].face_val)+' on part '+part[i].tag
      x = x[sel]
      y = y[sel]
      z = z[sel]
   endif
   
   ;;Assign pointers
   part[i].x  = ptr_new(x.x)
   part[i].y  = ptr_new(x.y)
   part[i].z  = ptr_new(x.z)
   part[i].dx = ptr_new(x.d)
   part[i].dy = ptr_new(y.d)
   part[i].dz = ptr_new(z.d)

   ;;Mark part found
   part[i].found=1
   print,' -- '+part[i].name
endfor


;;Fix M1 coordinate system (flip Y-axis, swap x & z)
m1 = where(part.tag eq 'm1')
if part[m1].found then begin 
   ;;-- posisiton
   (*part[m1].y) *= -1
   tempx = (*part[m1].x)
   tempz = (*part[m1].z)
   (*part[m1].x) = tempz
   (*part[m1].z) = tempx
   ;;-- displacement
   (*part[m1].dy) *= -1
   tempdx = (*part[m1].dx)
   tempdz = (*part[m1].dz)
   (*part[m1].dx) = tempdz
   (*part[m1].dz) = tempdx
endif

;;Tie M1 into strongback movement
sb = where(part.tag eq '001')
if part[m1].found AND part[sb].found then begin
   print,'Tying M1 into strongback movement'
   
   ;;--pad 1
   cx=4.5
   cz=-6.2
   r=sqrt(((*part[sb].x)-cx)^2 + ((*part[sb].z)-cz)^2)
   sel = where(r lt 2)
   dx_pad1 = mean((*part[sb].dx)[sel])
   dy_pad1 = mean((*part[sb].dy)[sel])
   dz_pad1 = mean((*part[sb].dz)[sel])

   ;;--pad 2
   cx=-2.25
   cz=-2.3
   r=sqrt(((*part[sb].x)-cx)^2 + ((*part[sb].z)-cz)^2)
   sel = where(r lt 2)
   dx_pad2 = mean((*part[sb].dx)[sel])
   dy_pad2 = mean((*part[sb].dy)[sel])
   dz_pad2 = mean((*part[sb].dz)[sel])

   ;;--pad 3
   cx=-2.25
   cz=-10.1
   r=sqrt(((*part[sb].x)-cx)^2 + ((*part[sb].z)-cz)^2)
   sel = where(r lt 2)
   dx_pad3 = mean((*part[sb].dx)[sel])
   dy_pad3 = mean((*part[sb].dy)[sel])
   dz_pad3 = mean((*part[sb].dz)[sel])

   ;;Take average of 3 pads
   dx_pads = (dx_pad1 + dx_pad2 + dx_pad3)/3
   dy_pads = (dy_pad1 + dy_pad2 + dy_pad3)/3
   dz_pads = (dz_pad1 + dz_pad2 + dz_pad3)/3

   ;;Add to m1 displacements
   (*part[m1].dx) += dx_pads
   (*part[m1].dy) += dy_pads
   (*part[m1].dz) += dz_pads
endif 

;;Create the optical bench part using the 3 pads as 3 nodes
sela= where(part.tag eq '104')
selb= where(part.tag eq '105')
selc= where(part.tag eq '106')
sel = where(part.tag eq 'bench')
if part[sela].found AND part[selb].found AND part[selc].found then begin
   x   = [mean(*part[sela].x),mean(*part[selb].x),mean(*part[selc].x)]
   y   = [mean(*part[sela].y),mean(*part[selb].y),mean(*part[selc].y)]
   z   = [mean(*part[sela].z),mean(*part[selb].z),mean(*part[selc].z)]
   dx  = [mean(*part[sela].dx),mean(*part[selb].dx),mean(*part[selc].dx)]
   dy  = [mean(*part[sela].dy),mean(*part[selb].dy),mean(*part[selc].dy)]
   dz  = [mean(*part[sela].dz),mean(*part[selb].dz),mean(*part[selc].dz)]
   part[sel].x  = ptr_new(x)
   part[sel].y  = ptr_new(y)
   part[sel].z  = ptr_new(z)
   part[sel].dx = ptr_new(dx)
   part[sel].dy = ptr_new(dy)
   part[sel].dz = ptr_new(dz)
   part[sel].found = 1
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;NOW CALCULATE THE ROTATION OF EACH PART
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


for i=0, nparts-1 do begin
   if part[i].found then begin
      ;;-- initial (x,y,z) locations of 3 nodes
      na = 0
      nb = 1
      pa1 = [(*part[i].x)[na],(*part[i].y)[na],(*part[i].z)[na]]
      pb1 = [(*part[i].x)[nb],(*part[i].y)[nb],(*part[i].z)[nb]]
      nnodes = n_elements(*part[i].x)
      for n=2,nnodes-1 do begin
         nc  = n
         pc1 = [(*part[i].x)[nc],(*part[i].y)[nc],(*part[i].z)[nc]]
         d = rss(crossp(pa1-pb1,pa1-pc1))/rss(pc1-pb1)
         if d gt 0.1 then break
      endfor
      if n eq nnodes then stop,'Could not find 3 points on a plane'

      ;;-- final (x,y,z) locations of 3 nodes
      pa2 = [(*part[i].dx)[na],(*part[i].dy)[na],(*part[i].dz)[na]] + pa1
      pb2 = [(*part[i].dx)[nb],(*part[i].dy)[nb],(*part[i].dz)[nb]] + pb1
      pc2 = [(*part[i].dx)[nc],(*part[i].dy)[nc],(*part[i].dz)[nc]] + pc1

      ;;get rotation
      ;;-- define initial normal vector at point a in global x,y,z coordinates
      vab = pb1 - pa1
      vac = pc1 - pa1
      nor = crossp(vac,vab)
      ;;-- define the inital principle axis vectors in global coordinates
      z1 = unitize(nor)
      x1 = unitize(vab)
      y1 = crossp(z1,x1)
      ;;-- define final normal vector at point a in global x,y,z coordinates
      vab = pb2 - pa2
      vac = pc2 - pa2
      nor = crossp(vac,vab)
      ;;-- define the final principle axis vectors in global coordinates
      z2 = unitize(nor)
      x2 = unitize(vab)
      y2 = crossp(z2,x2)

      ;;test rotation from initial to final in global coordinates
      if 0 then begin
         ;;Test Matrix for tx = -75 deg, ty = -7 deg, tz = 20 deg     
         trot12 = dblarr(3,3)
         trot12[0,0] = 0.892454
         trot12[0,1] = -0.0885058
         trot12[0,2] = -0.442372
         trot12[1,0] = 0.450035
         trot12[1,1] = 0.243213
         trot12[1,2] = 0.859253
         trot12[2,0] = 0.0315417
         trot12[2,1] = -0.965927
         trot12[2,2] = 0.256887
         trot12      = transpose(trot12) ;;convert to idl convention
         x2 = reform(trot12 ## x1)
         y2 = reform(trot12 ## y1)
         z2 = reform(trot12 ## z1)
         print,'Testing '+part[i].name+' with:'
         print,trot12
      endif

      
      ;;calculate rotation matrix from initial to final, rotating
      ;;around global coordinates (extrinsic rotation)
      R1  = transpose([[x1],[y1],[z1]])
      R2  = transpose([[x2],[y2],[z2]])
      rot12 = R2 ## invert(R1) 

      ;;decompose rotation matrix into euler angles.
      ;;use Zemax convention (X-Y'-Z") --> roll around local X,
      ;;then around new Y, then around new Z. 
      matrix_to_angles,rot12,tx,ty,tz

      ;;save rotation angles (mdeg)
      part[i].ptx = 1000 * tx / !dtor
      part[i].pty = 1000 * ty / !dtor
      part[i].ptz = 1000 * tz / !dtor

      ;;save average displacements (thou)
      part[i].pdx = 1000 * mean((*part[i].dx))
      part[i].pdy = 1000 * mean((*part[i].dy))
      part[i].pdz = 1000 * mean((*part[i].dz))
      if part[i].tag eq 'bench' then begin
         ;;The Y component of the bench displacement should only include the 2 Aft
         ;;mounting pads because the Forward pad is the flat and will
         ;;slide.
         part[i].pdy = 1000 * mean((*part[i].dy)[[0,1]])
      endif
   endif
endfor

;;Create M1 surface map -- mirror surface is mainly in X,Z plane with
;;                         tilt about X equal to off-axis angle
if part[m1].found then begin
   ;;Transform inital x,y,z into surface coordinates
   xi = (*part[m1].x)
   yi = (*part[m1].y)
   zi = (*part[m1].z)
   found = 0
   ;;Find 3 points (a,b,c) on the surface: 2 with same Z, 1 with different Z
   ;; --> Forms a reference plane
   ;; --> This plane should really be normal to the optical axis (but it isnt here!)
   for i=0,n_elements(xi)-1 do begin
      sel = where(zi eq zi[i],nsel)
      if nsel gt 1 then begin
         na  = sel[0]
         nb  = sel[1]
         sel = where((zi ne zi[na]) AND (zi ne zi[nb]),nsel)
         if nsel gt 0 then begin
            nc = sel[0]
            found = 1
            break
         endif
      endif
   endfor
   if NOT found then stop,'Could not set M1 axes!'

   ;;Define point coordinate arrays
   p0i = [xi[na],yi[na],zi[na]]
   p1i = [xi[nb],yi[nb],zi[nb]]
   p2i = [xi[nc],yi[nc],zi[nc]]

   ;;Create x,y,z unit vectors
   vec1 = unitize(p1i - p0i)
   vec2 = unitize(p2i - p0i)
   xvec = vec1
   zvec = unitize(crossp(vec1,vec2))
   yvec = crossp(zvec,xvec)

   ;;Create transformation matrix
   RM   = invert(transpose([[xvec],[yvec],[zvec]])) 

   ;;Transform inital x,y,z points into mirror surface coordinates
   xil  = xi
   yil  = yi
   zil  = zi
   for i=0,n_elements(xil)-1 do begin
      vec = RM ## [xi[i],yi[i],zi[i]]
      xil[i] = vec[0]
      yil[i] = vec[1]
      zil[i] = vec[2]
   endfor
 
   ;;Transform final x,y,z points into mirror surface coordinates
   xo  = xi + (*part[m1].dx)
   yo  = yi + (*part[m1].dy)
   zo  = zi + (*part[m1].dz)
   p0o = [xo[na],yo[na],zo[na]]
   p1o = [xo[nb],yo[nb],zo[nb]]
   p2o = [xo[nc],yo[nc],zo[nc]]
   vec1 = unitize(p1o - p0o)
   vec2 = unitize(p2o - p0o)
   xvec = vec1
   zvec = unitize(crossp(vec1,vec2))
   yvec = crossp(zvec,xvec)
   RM   = invert(transpose([[xvec],[yvec],[zvec]])) 
   xol  = xo
   yol  = yo
   zol  = zo
   for i=0,n_elements(xol)-1 do begin
      vec = RM ## [xo[i],yo[i],zo[i]]
      xol[i] = vec[0]
      yol[i] = vec[1]
      zol[i] = vec[2]
   endfor

   ;;Make the 0th node the origin
   iorg = [xil[0],yil[0],zil[0]]
   oorg = [xol[0],yol[0],zol[0]]
   for i=0,n_elements(xil)-1 do begin
      xil[i] -= iorg[0]
      yil[i] -= iorg[1]
      zil[i] -= iorg[2]
      xol[i] -= oorg[0]
      yol[i] -= oorg[1]
      zol[i] -= oorg[2]
   endfor

   ;;Save nodes
   m1na = na
   m1nb = nb
   m1nc = nc
   
   ;;Now we have zil as the initial surface height above the (xil,yil) plane
   ;;And zol as the final surface height above the (xol,yol) plane
   ;;These two planes pass through the same three nodes (na,nb,nc) on the initial
   ;;and final surface and they have their origin at the 0th node. The
   ;;X,Y,Z unit vectors have the same orientation in both coordinate
   ;;systems relative to the three nodes.
   ;;We first interpolate the zol values onto the (xil,yil) grid, then
   ;;subtract the zil values to find the change in the surface.
  

   ;;Create surface map
   zii = tri_surf(zil,xil,yil,NX=gs,NY=gs,gs=igs)
   xii = findgen(gs)*igs[0] + min(xil)
   yii = findgen(gs)*igs[1] + min(yil)
   zoo = tri_surf(zol,xol,yol,NX=gs,NY=gs,gs=ogs)
   xoo = findgen(gs)*ogs[0] + min(xol)
   yoo = findgen(gs)*ogs[1] + min(yol)
   
   ;;interpolate output map onto input coordinates
   tmp = dblarr(gs,gs)
   zoi = dblarr(gs,gs)
   for i=0,gs-1 do tmp[i,*] = interpol(zoo[i,*],xoo,xii)    ;;interpolate into xii coordinates
   for i=0,gs-1 do zoi[*,i] = interpol(tmp[*,i],yoo,yii)    ;;interpolate into yii coordinates
   
   ;;subtract input map from output map, apply mask, and convert to nm
   surmap = (zoi - zii)*mask*2.54e7

   ;;rotate
   if keyword_set(M1_ROTATE) then surmap = rotate(surmap,M1_ROTATE)

   ;;Fit Zernikes
   nz=24
   fitmap = zernike_fit_aperture(surmap,mask,nz,zernike_cf=mapcf)

   ;;Eventhough each surface is now referenced to a plane built from
   ;;the same 3 nodes, there still may be residual tilt of the surface
   ;;relative to that plane, and thus residual tilt in the difference
   ;;between the two surfaces. 

   ;;Subtract TTP
   ttpmap  = surmap
   ttpmap -= mapcf[0] * zernike_aperture(1,mask) 
   ttpmap -= mapcf[1] * zernike_aperture(2,mask) 
   ttpmap -= mapcf[2] * zernike_aperture(3,mask) 
   
   ;;Get fit residual
   resmap = ttpmap-fitmap

   ;;Plot M1 surface deformation
   plotfile=plotpath+plottag+'_m1_surface'
   items=['RMS: '+n2s(stdev(surmap[masksel]),format='(F10.1)'),'PTV: '+n2s(ptv(surmap[masksel]),format='(F10.1)')]
   implot,surmap,plotfile,cbtitle='nm',title='M1 Deformation',$
          blackout=notmasksel,ncolor=255,legend_items=items,/noclose,cbformat='(F10.1)'
   loadct,0
   oplot,xarr,yarr,linestyle=1,thick=2,color=255
   implot,/close

   ;;Plot M1 surface deformation (TTP Subtracted)
   plotfile=plotpath+plottag+'_m1_surface_ttp_sub'
   items=['RMS: '+n2s(stdev(ttpmap[masksel]),format='(F10.1)'),'PTV: '+n2s(ptv(ttpmap[masksel]),format='(F10.1)')]
   implot,ttpmap,plotfile,cbtitle='nm',title='M1 Deformation (TTP Subtracted)',$
          blackout=notmasksel,ncolor=255,legend_items=items,/noclose,cbformat='(F10.1)'
   loadct,0
   oplot,xarr,yarr,linestyle=1,thick=2,color=255
   implot,/close
endif

;;Plot Nodes
sel104 = where(part.tag eq '104')
sel105 = where(part.tag eq '105')
sel106 = where(part.tag eq '106')
if part[sel104].found AND part[sel105].found AND part[sel106].found then begin
   mkeps,plotpath+plottag+'_bench_nodes'
   linecolor
   x104 = *part[sel104].x
   y104 = *part[sel104].y
   x105 = *part[sel105].x
   y105 = *part[sel105].y
   x106 = *part[sel106].x
   y106 = *part[sel106].y
   plotsym,0,/fill
   plot,[x104,x105,x106],[y104,y105,y106],title='Bench Node Locations',/iso,psym=8,symsize=0.1,xtitle='X [inches]',ytitle='Y [inches]'
   xyouts,mean(x104),mean(y104)+3,'104',alignment=0.5
   xyouts,mean(x105),mean(y105)+3,'105',alignment=0.5
   xyouts,mean(x106),mean(y106)+6,'106',alignment=0.5
   mkeps,/close
endif

for i=0,nparts-1 do begin
   if part[i].found then begin
      mkeps,plotpath+plottag+'_'+fileify(part[i].name)+'_nodes_xz'
      linecolor
      plotsym,0,/fill
      plot,(*part[i].x),(*part[i].z),title=part[i].name+' Node Locations X-Z Plane',/iso,psym=8,symsize=0.1,xtitle='X [inches]',ytitle='Z [inches]'
      if i eq m1 then oplot,(*part[i].x)[[m1na]],(*part[i].z)[[m1na]],color=1,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].x)[[m1nb]],(*part[i].z)[[m1nb]],color=2,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].x)[[m1nc]],(*part[i].z)[[m1nc]],color=3,psym=8,symsize=0.3
      mkeps,/close
      mkeps,plotpath+plottag+'_'+fileify(part[i].name)+'_nodes_xy'
      linecolor
      plotsym,0,/fill
      plot,(*part[i].x),(*part[i].y),title=part[i].name+' Node Locations X-Y Plane',/iso,psym=8,symsize=0.1,xtitle='X [inches]',ytitle='Y [inches]'
      if i eq m1 then oplot,(*part[i].x)[[m1na]],(*part[i].y)[[m1na]],color=1,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].x)[[m1nb]],(*part[i].y)[[m1nb]],color=2,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].x)[[m1nc]],(*part[i].y)[[m1nc]],color=3,psym=8,symsize=0.3
      mkeps,/close
      mkeps,plotpath+plottag+'_'+fileify(part[i].name)+'_nodes_yz'
      linecolor
      plotsym,0,/fill
      plot,(*part[i].y),(*part[i].z),title=part[i].name+' Node Locations Y-Z Plane',/iso,psym=8,symsize=0.1,xtitle='Y [inches]',ytitle='Z [inches]'
      if i eq m1 then oplot,(*part[i].y)[[m1na]],(*part[i].z)[[m1na]],color=1,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].y)[[m1nb]],(*part[i].z)[[m1nb]],color=2,psym=8,symsize=0.3
      if i eq m1 then oplot,(*part[i].y)[[m1nc]],(*part[i].z)[[m1nc]],color=3,psym=8,symsize=0.3
      mkeps,/close
   endif
endfor

;;Write logfile
openw,unit,plotpath+plottag+'_displacement.txt',/get_lun

;;Zernikes
namezern=zernike_names(nz)
if part[m1].found then begin
   printf,unit,'M1 Surface Deformation [nm RMS]'
   for i=0,nz/2-1 do printf,unit,'Z'+n2s(i+1),mapcf[i],'Z'+n2s(i+nz/2+1),mapcf[i+nz/2],format='(A5,F12.2,A10,F12.2)'
   printf,unit,''
   printf,unit,'M1 Wavefront Error [waves @ 600nm] for Zemax'
   for i=0,nz/2-1 do printf,unit,'Z'+n2s(i+1),-2*mapcf[i]/600,'Z'+n2s(i+nz/2+1),-2*mapcf[i+nz/2]/600,format='(A5,E12.2,A10,E12.2)'
   printf,unit,''
   for i=0,nz/2-1 do printf,unit,'Z'+n2s(i+1),namezern[i],'Z'+n2s(i+nz/2+1),namezern[i+nz/2],format='(A5,A17,A5,A17)'
   printf,unit,''
endif

;;Displacement
nch = 7+ndp
f1  = '(F'+n2s(nch)+'.'+n2s(ndp)+')'
f2  = '(F+'+n2s(nch)+'.'+n2s(ndp)+')'
restore,'zemax_matrix.idl'
bsel = where(part.tag eq 'bench')
for coords=0,1 do begin
   if coords eq 0 then printf,unit,'Absolute Displacement (Relative to M1) Solidworks Coordinates'
   if coords eq 1 then printf,unit,'Absolute Displacement (Relative to M1) Zemax Coordinates'
   printf,unit,''
   printf,unit,'Part','dX [thou]','dY [thou]','dZ [thou]','tX [mdeg]','tY [mdeg]','tZ [mdeg]',format='(A15,6A'+n2s(2*nch)+')'
   for i=0,nparts-1 do begin
      lydx=0
      if part[i].found then begin
         dx   = part[i].pdx
         dy   = part[i].pdy
         dz   = part[i].pdz
         tx   = part[i].ptx
         ty   = part[i].pty
         tz   = part[i].ptz
         ddx  = part[i].pdx - part[m1].pdx
         ddy  = part[i].pdy - part[m1].pdy
         ddz  = part[i].pdz - part[m1].pdz
         dtx  = part[i].ptx - part[m1].ptx
         dty  = part[i].pty - part[m1].pty
         dtz  = part[i].ptz - part[m1].ptz
         if coords eq 0 then begin 
            ;;cad coordinates
            sdx  = n2s(dx,format=f1)
            sdy  = n2s(dy,format=f1)
            sdz  = n2s(dz,format=f1)
            stx  = n2s(tx,format=f1)
            sty  = n2s(ty,format=f1)
            stz  = n2s(tz,format=f1)
            sddx = '('+n2s(ddx,format=f2)+')'
            sddy = '('+n2s(ddy,format=f2)+')'
            sddz = '('+n2s(ddz,format=f2)+')'
            sdtx = '('+n2s(dtx,format=f2)+')'
            sdty = '('+n2s(dty,format=f2)+')'
            sdtz = '('+n2s(dtz,format=f2)+')'
         endif
         if coords eq 1 then begin 
            ;;zemax coordinates
            sdx  = n2s(dx,format=f1)
            sdy  = n2s(-dz,format=f1)
            sdz  = n2s(dy,format=f1)
            stx  = n2s(tx,format=f1)
            sty  = n2s(-tz,format=f1)
            stz  = n2s(ty,format=f1)
            sddx = '('+n2s(ddx,format=f2)+')'
            sddy = '('+n2s(-ddz,format=f2)+')'
            sddz = '('+n2s(ddy,format=f2)+')'
            sdtx = '('+n2s(dtx,format=f2)+')'
            sdty = '('+n2s(-dtz,format=f2)+')'
            sdtz = '('+n2s(dty,format=f2)+')'
         endif
         printf,unit,part[i].name,sdx,sddx,sdy,sddy,sdz,sddz,stx,sdtx,sty,sdty,stz,sdtz,format='(A15,12A'+n2s(nch)+')'
         ;;get lyot stop & dm beam displacements
         if i eq bsel then begin
            lydxy = ly_matrix ## [ddx,-ddz,ddy,dtx,-dtz,dty]*(-1) ;;zemax [dx,dy,dz,tx,ty,tz] = cad [dx,-dz,dy,tx,-tz,ty]
            dmdxy = dm_matrix ## [ddx,-ddz,ddy,dtx,-dtz,dty]*(-1) ;;negative because this is the bench motion, not M1
            lydx   = lydxy[0]
            lydy   = lydxy[1]
            lydr   = rss(lydxy)
            dmdx   = dmdxy[0]
            dmdy   = dmdxy[1]
            dmdr   = rss(dmdxy)
         endif
      endif
   endfor
   printf,unit,''
endfor
if lydx ne 0 then begin
   printf,unit,''
   printf,unit,'Lyot Stop and DM Beam Displacement'
   printf,unit,''
   printf,unit,'','dX [thou]','dY [thou]','dR [thou]',format='(4A12)'
   printf,unit,'Lyot',lydx,lydy,lydr,format='(A12,3F12.3)'
   printf,unit,'DM',dmdx,dmdy,dmdr,format='(A12,3F12.3)'
endif

free_lun,unit

;;Save outfile
save,part,surmap,mask,filename=plotpath+plottag+'_displacement.idl'


end
