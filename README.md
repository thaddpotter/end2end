# end2end

Wrapper for piccsim and exotargets to incorporate thermal and mechanical loads into optical simulations of coronagraphic imagers.

## Documentation

Git Repository Dependencies:
  git clone git@gitlab:tpotter/end2end.git
  git clone git@gitlab:dotpro/piccsim.git
  git clone git@gitlab:dotpro/proper.git
  git clone git@gitlab:dotpro/tdemidl.git
  git clone git@gitlab:dotpro/cbmidl.git
  git clone git@gitlab:dotpro/astron.git
  git clone git@gitlab:dotpro/castelli.git
  git clone git@gitlab:dotpro/coyote.git
  git clone git@gitlab:dotpro/carsten.git
  git clone git@gitlab:dotpro/zodipic.git
	
Setup:
  Setup Dependencies according to their instructions
  Set Repository Paths in Settings File
  Add line in inst.csv in exotargets for instrument if not included
  Add base prescription file into piccsim if not included
  Add settings block to piccsim_load settings for this prescription


## Example Sim:

# Initialize: 

# I Make Raw Brightness Maps

IDL> e2e_gen_maps

# II Run base model in piccsim (Fast)

Calculate throughput (few seconds)
    IDL> calc_throughput,'rx_base'
Initialize the model
    IDL> run_piccsim,'sim_system','rx_base',/init,/broadband=[xi],save_fields=[yi]
Run the model
    IDL> run_piccsim,'sim_system','rx_base',/broadband=[xi],save_fields=[yi]
Plot output
    IDL> plot_piccsim,'sim_system'

# III Run EFC in piccsim (Slow)

Calculate occulter transmission (~1hr)
    IDL> calc_transmission,'sim_system','rx_base',broadband=[xi]
Collect the DM matrix data (~2 hrs)
    IDL> run_piccsim,'sim_system','rx_base',caldm='dm2',broadband=[xi]
Read the DM matrix data
    IDL> read_matrix,'sim_system','rx_base','sci','dm2',/zero_ref
Calculate the DM matrix
    IDL> calc_matrix,'sim_system','rx_base','sci','dm2'
Run EFC & plot results without focal plane sensing
    IDL> test_efc,'sim_system','rx_base',broadband=[xi]

# IV Run disturbed model

Read COMSOL Displacement Field Data, convert to idl data file
    IDL> e2e_read_COMSOL,'file_name','disp_file.idl'
Disturb Prescription
    IDL> e2e_disturb_prescription,'rx_base','rx_dist', 'dist_file'


Repeat steps 2,3 with 'rx_base' -> 'rx_dist'    

# V Run brightness maps through instrument

IDL> 




## TODO

Planet and Disk Brightness
    Assemble library of dust disk parameters for targets of interest
    (Inner and outer radii, density in zodis, ...?)
    >>Add these values to planlight (currently set to use IWA, OWA for radii)

e2e_disturb_prescription:
    Take input prescription and list of 6-D displacements
    Convert prescription to 6-D?
    Displace Optics
    Conver
    write out a new csv prescription







