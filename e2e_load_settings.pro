function e2e_load_settings
  common sim_settings, settings

  ;;Loads Setting needed to run a full simulation
  ;--------------------------------------------------------------------------------
  
  ;;General Parameters
  date = 2459473.5                         ;;Date of Observation (JD)
  path = '~/idl/end2end/'                  ;;Path to main directory
  datapath = path + 'data/'                ;;Path to data directory
  outpath = path + 'output/'               ;;Path to output directory
  plotpath = path + 'plots/'               ;;Path to plots directory
  tdpath = '/mnt/c/Users/locsst/Desktop/TD_picture_working/'     ;;Path to Thermal Desktop Directory

  ;;Exotargets Parameters
  exo = {$
    path:'~/idl/repo/exotargets/', $       ;;Path to exotarget directory                    
    instname:'PICTURE_C2', $               ;;Name of instrument (must be included in inst.csv in exotargets directory)
                                           ;;Add functionality to write to inst.csv later?
    catalog:'nasa', $                      ;;Catalog to be used for planet search
    force_include:'eps eri', $             ;;Array of planet names to be required on targetlist
    plot_skip:0, $                         ;;Array of planet names to skip plotting
    hilton_phase:0, $                      ;;Use Hilton Phase Function for Planet Brightness
    rayleigh_scatter:0, $                  ;;Use Rayleigh Scattering
    picasso:0, $                           ;;Use PICASSO model prediction for Planet Brightness
    calc_maxtime:1, $                      ;;Calculate Maximum Integration time for Mission
    ;output_tag:0, $                       ;;Tags written files, prevents overwrite on successive runs of exotargets with same instname and catalogs
    postfactor:1d $                        ;;Instrument Post-Processing Factor (Speckle Noise)    
  }

  ;;Optical Model Parameters
  picc = {$
    path:'~/idl/repo/piccsim/', $                            ;;Path to piccsim directory
    rx_base:'rx_picture_c2_ch4', $                           ;;Base prescription to use from piccsim (Make sure the same instrument is used in exotargets)
    rx_dist:'picture_c2_ch4_thermal', $                      ;;Disturbed prescription (WILL BE WRITTEN TO, ADD SUBSCRIPTING TO PREVENT OVERWRITE)
    a: 1 $
  }

  ;;Write settings block
  ;;-----------------------------------------------------------------------------------------------------
  settings = {$

    date:date, $
    
    path:path, $                           
    datapath:datapath,$                    
    outpath:outpath,$
    plotpath:plotpath,$
    tdpath:tdpath,$                       

    exo: exo, $
    picc:picc $
    }

  return, settings
end

