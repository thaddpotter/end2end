# end2end

Wrapper for piccsim and exotargets to incorporate thermal and mechanical loads into optical simulations of coronagraphic imagers.

## Documentation

Git Repository Dependencies:
  tpotter/end2end.git
  dotpro/piccsim.git
  dotpro/proper.git
  dotpro/tdemidl.git
  dotpro/cbmidl.git
  dotpro/astron.git
  dotpro/castelli.git
  dotpro/coyote.git
  dotpro/carsten.git
  dotpro/zodipic.git
	
Setup:
  Setup Dependencies according to their instructions
  Set Repository Paths in Settings File
  Add line in inst.csv in exotargets for instrument if not included
  Add base prescription file into piccsim if not included
  Add settings block to piccsim_load settings for this prescription


## Example Sim:

# Initialize: 

# I Make Raw Brightness Maps (Fast for Best Case, extremely slow otherwise)

IDL> e2e_read_targetlist

# II Run base model in piccsim (Fast, must be run inside piccsim directory)

Calculate throughput (few seconds)
    IDL> calc_throughput,'rx_base'
Initialize the model
    IDL> run_piccsim,'sim_system','rx_base',/init,broadband=[xi]
Run the model
    IDL> run_piccsim,'sim_system','rx_base',broadband=[xi],save_fields=[yi]
Plot output (make sure things are working correctly)
    IDL> plot_piccsim,'sim_system','rx_base'

# III Run EFC in piccsim (Slow, must be run inside piccsim directory)

Calculate occulter transmission (~1hr)
    IDL> calc_transmission,'sim_system','rx_base',broadband=[xi]
Collect the DM matrix data (~2 hrs)
    IDL> run_piccsim,'sim_system','rx_base',caldm='dm2',broadband=[xi]
Read the DM matrix data
    IDL> read_matrix,'sim_system','rx_base','sci','dm2',[/zero_ref]
Calculate the DM matrix
    IDL> calc_matrix,'sim_system','rx_base','sci','dm2'
Run EFC & plot results without focal plane sensing
    IDL> test_efc,'sim_system','rx_base','sci','dm2',broadband=[xi]
Plot final outputs, include fits files (needed for contrast maps)
    IDL> plot_piccsim,'sim_system','rx_base',/save_fits

# IV Run disturbed model

Read COMSOL Displacement Field Data, convert to idl data file
    IDL> read_COMSOL,file_names,optic_names,'disp_file.idl'
Calculate Displacements
    IDL> disturb_rx,'rx_base','rx_dist', ['dist_files',]


Repeat steps 2,3 with 'rx_base' -> 'rx_dist'    

# V Run brightness maps through instrument

IDL> 




## TODO

Planet and Disk Brightness
    Assemble library of dust disk parameters for targets of interest
    (Inner and outer radii, density in zodis, ...?)
    >>Add these values to planlight (currently set to use IWA, OWA for radii)
    Sample 1 in 10 points during obs window? May need to make some edits to exotargets to handle this...

Running from Displaced coordinates
    ZEMAX vs piccsim?







