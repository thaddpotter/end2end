pro write_rx,unit,rx
;;Writes out piccsim-readable CSV File from RX Structure

  ed  = ''
  md  = ','
  ef='A0'

;;Define format
  format = '('+ef+','+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$           
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$           
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,A1,'+$
            'A-15,'+ef+')'
  
  ;;Define headers
  header1 = string(ed,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            'Non Circ/Sq',md,$
            '0:E, 1:R',md,$
            'Check Zemax',md,$
            '',md,$
            '',md,$
            'PTV [nm]',md,$
            'RMS [nm]',md,$
            '',md,$
            '',md,$
            'Cutoff [c/a]',md,$
            'PTW',md,$
            'RMS',md,$
            '',md,$
            '',md,$
            'Cutoff [c/a]',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',md,$
            '',ed,$
            format=format)
  
  header2 = string(ed,$
            '# Name',md,$
            'Type',md,$
            'Pupil',md,$
            'Focus',md,$
            'Init',md,$
            'Focal Length',md,$
            'Thickness',md,$
            'Optic R',md,$
            'Optic R2',md,$
            'Ell or Rec',md,$
            'Aper or Obsc',md,$
            'Beam R',md,$
            'Angle',md,$
            'Beamwalk [units/as]',md,$
            'Surf. Min',md,$
            'Surf. PSD A',md,$
            'Surf. PSD B',md,$
            'Surf. PSD C',md,$                   
            'Surf. PSD D',md,$
            'Ref. Min',md,$
            'Ref. PSD A',md,$
            'Ref. PSD B',md,$
            'Ref. PSD C',md,$                   
            'Ref. PSD D',md,$
            'Material',md,$
            'Wave Code',md,$
            'Extra 1',md,$
            'Extra 2',md,$
            'Extra 3',md,$
            'Extra 4',ed,$
            format=format)
    
  printf,unit,header1
  printf,unit,header2

  for i=0,n_elements(rx)-1 do begin

     ;;Define strings
    rx_longname = rx[i].name     
    rx_type =     rx[i].type
    rx_pupil =    n2s(rx[i].pupil,format='(B)')
    rx_focus =    n2s(rx[i].focus,format='(B)')
    rx_init =     n2s(rx[i].init,format='(I)')
    rx_fl =       n2s(rx[i].fl,format='(F0.8)')
    rx_dist  =    n2s(rx[i].dist,format='(F0.8)')  
    rx_zbeam =    n2s(rx[i].zbeam,format='(F0.8)')  
    rx_radius =   n2s(rx[i].radius,format='(F0.8)')
    rx_radiusB =  n2s(rx[i].radiusB,format='(B)')
    rx_ellrec =   n2s(rx[i].ellrec,format='(B)')
    rx_aperobsc = n2s(rx[i].aperobsc,format='(B)')
    rx_angle =    n2s(rx[i].angle,format='(F0.8)')    
    rx_beamwalk = n2s(rx[i].beamwalk,format='(F0.8)') 
    rx_sptv =     n2s(rx[i].sptv,format='(F0.3)')     
    rx_srms =     n2s(rx[i].srms,format='(F0.3)')    
    rx_spsdb =    n2s(rx[i].spsdb,format='(F0.3)')
    rx_spsdc =    n2s(rx[i].spsdc,format='(F0.3)')
    rx_spsdd =    n2s(rx[i].spsdd,format='(F0.3)')
    rx_rptv =     n2s(rx[i].spsdd,format='(F0.3)')
    rx_rrms =     n2s(rx[i].spsdd,format='(F0.3)')
    rx_rpsdb =    n2s(rx[i].spsdd,format='(F0.3)')
    rx_rpsdc =    n2s(rx[i].spsdd,format='(F0.3)')
    rx_rpsdd =    n2s(rx[i].spsdd,format='(F0.3)')
    rx_material = rx[i].material 
    rx_wave =     n2s(rx[i].wave,format='(I)')
    if rx_type eq 'lenslet' then rx_extra1 =  n2s(rx[i].extra1,format='(F0.8)') else rx_extra1 = rx[i].extra1
    rx_extra2 =   n2s(rx[i].extra2,format='(F0.9)')
    rx_extra3 =   n2s(rx[i].extra3,format='(F0.9)')   
    rx_extra4 =   n2s(rx[i].extra4,format='(F0.9)')   

     printf,unit,ed,$
          rx_longname,md,$
          rx_type,md,$
          rx_pupil,md,$
          rx_focus,md,$
          rx_init,md,$
          rx_fl,md,$
          rx_dist ,md,$
          rx_zbeam,md,$
          rx_radius,md,$
          rx_radiusB,md,$
          rx_ellrec,md,$
          rx_aperobsc,md,$
          rx_angle,md,$
          rx_beamwalk,md,$
          rx_sptv,md,$
          rx_srms,md,$
          rx_spsdb,md,$
          rx_spsdc,md,$
          rx_spsdd,md,$
          rx_rptv,md,$
          rx_rrms,md,$
          rx_rpsdb,md,$
          rx_rpsdc,md,$
          rx_rpsdd,md,$
          rx_material,md,$
          rx_wave,md,$
          rx_extra1,md,$
          rx_extra2,md,$
          rx_extra3,md,$
          rx_extra4,ed,$
          format=format
  endfor
end

pro disturb_rx, rx_base_name,rx_dist_name,base_file=base_file,dist_file=dist_file, dont_disturb=dont_disturb

;;Procedure to convert COMSOL Output into a distance basis usable by PICCSIM
;-------------------------------------------------------------------------------
;;Arguments:
;rx_base_name - name of prescription to modify
;rx_dist name - name of prescription to write out (WARNING: Will overwrite this prescription)
;base_file - file location of COMSOL output of initial mesh points
;dist_file - file location of COMSOL outpuf of disturbed mesh points
;-------------------------------------------------------------------------------
;;Keywords
;dont disturb - test keyword, sets disturbed prescription to be equal to base
;-------------------------------------------------------------------------------
;;Outputs
;rx_dist - PICCSIM readable csv file with the same structure/order as rx_base
;error maps?

;Load Settings Block
sett = e2e_load_settings()

;Read in base prescription
rx_file = sett.picc.path+'/data/prescriptions/'+rx_base_name+'.csv'
rx_base = piccsim_readrx(rx_file)

;Disturb Prescription
if keyword_set(dont_disturb) then rx_dist = rx_base else begin

read_dist, rx_base, base_file, dist_file, rx_dist_name


;Loop over resolved optics (double up base and dist (base to check accuracy, dist to calculate):

  ;Get approximate location and orientation of surface
    ;Optimize location of a plane to minimize distance to mesh points
    ;Project points onto plane coordinates (x,y,z)
    ;Average x,y -> Centerpoint?

  ;Fit points to zernikes
    ;x,y,z point list -> Zernike Fit

  ;Take new surface vertex, calculate distance to next optic, check against base
  ;Take surface focal length, check against base
  
  ;Record relevant zernike coeffients (Deviation from ideal for focus) and write out to a better sampled phase error map for piccsim
  ;Save to file

  ;Write new distances and focal lengths to structure


endelse 



;Write out disturbed prescription
rx_file = sett.picc.path+'/data/prescriptions/'+rx_dist_name+'.csv'
openw, 1, rx_file
write_rx, 1, rx_dist
close,1 

end