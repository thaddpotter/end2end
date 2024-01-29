#Connect to Opticstudio
import clr, os, winreg
from itertools import islice

#READ ME
#For the following to function, you MUST have your optics file open in Optic Studio, and
#you MUST go to "Programming" and then click on "Interactive Extension", then run the
#python program.

# determine the Zemax working directory
aKey = winreg.OpenKey(winreg.ConnectRegistry(None, winreg.HKEY_CURRENT_USER), r"Software\Zemax", 0, winreg.KEY_READ)
zemaxData = winreg.QueryValueEx(aKey, 'ZemaxRoot')
NetHelper = os.path.join(os.sep, zemaxData[0], r'ZOS-API\Libraries\ZOSAPI_NetHelper.dll')
winreg.CloseKey(aKey)

# add the NetHelper DLL for locating the OpticStudio install folder
clr.AddReference(NetHelper)
import ZOSAPI_NetHelper

pathToInstall = ''
# uncomment the following line to use a specific instance of the ZOS-API assemblies
#pathToInstall = r'C:\C:\Program Files\Zemax OpticStudio'

# connect to OpticStudio
success = ZOSAPI_NetHelper.ZOSAPI_Initializer.Initialize(pathToInstall)

zemaxDir = ''
if success:
    zemaxDir = ZOSAPI_NetHelper.ZOSAPI_Initializer.GetZemaxDirectory()
    print('Found OpticStudio at:   %s' + zemaxDir)
else:
    raise Exception('Cannot find OpticStudio')

# load the ZOS-API assemblies
clr.AddReference(os.path.join(os.sep, zemaxDir, r'ZOSAPI.dll'))
clr.AddReference(os.path.join(os.sep, zemaxDir, r'ZOSAPI_Interfaces.dll'))
import ZOSAPI

TheConnection = ZOSAPI.ZOSAPI_Connection()
if TheConnection is None:
    raise Exception("Unable to intialize NET connection to ZOSAPI")

TheApplication = TheConnection.ConnectAsExtension(0)
if TheApplication is None:
    raise Exception("Unable to acquire ZOSAPI application")

if TheApplication.IsValidLicenseForAPI == False:
    raise Exception("License is not valid for ZOSAPI use.  Make sure you have enabled 'Programming > Interactive Extension' from the OpticStudio GUI.")

TheSystem = TheApplication.PrimarySystem
if TheSystem is None:
    raise Exception("Unable to acquire Primary system")

print('Connected to OpticStudio')
####################################################################################################


#Program Setup
import numpy as np
import scipy
import scipy.io as scipyio
import sys

##STAR Setup
analysis = TheSystem.Analyses
tools = TheSystem.Tools
surf_inds = [3,8,13,18,23,27,31,36,40,43,44,46]

#Field heights (1 is Default for on-axis)
hx = 1
hy = 1


# Get Surfaces
TheLDE = TheSystem.LDE
move_m2 = TheLDE.GetSurfaceAt(7)

#File IO setup
data_dir = 'c:\\Users\locsst\Desktop\TD_picture_working\\ansys\\STAR\\'

#Functions



####################################################################################################


#Clear Any Leftover STAR Data from previous runs
surf_m1.STARData.Deformations.FEAData.UnloadData()
surf_m2.STARData.Deformations.FEAData.UnloadData()
surf_m3.STARData.Deformations.FEAData.UnloadData()

#Clear and set Variables for optimization, reset M2 Correction
tools.RemoveAllVariables()
move_m2.ThicknessCell.set_DoubleValue(0)
move_m2.GetCellAt(12).set_DoubleValue(0)
move_m2.GetCellAt(13).set_DoubleValue(0)
move_m2.GetCellAt(14).set_DoubleValue(0)
move_m2.GetCellAt(15).set_DoubleValue(0)

move_m2.ThicknessCell.MakeSolveVariable()
move_m2.GetCellAt(12).MakeSolveVariable()
move_m2.GetCellAt(13).MakeSolveVariable()
move_m2.GetCellAt(14).MakeSolveVariable()
move_m2.GetCellAt(15).MakeSolveVariable()

#Get data from nominal system
nominal_chief_arr = np.zeros((10,2))

for i in range(10):
    nominal_chief_arr[i-1,0] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAX, surf_inds[i-1],0,0,0,0,0,0,0)
    nominal_chief_arr[i-1,1] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAY, surf_inds[i-1],0,0,0,0,0,0,0)

#FEA
surf_m1.STARData.Deformations.FEAData.ImportDeformations(file_m1)
surf_m2.STARData.Deformations.FEAData.ImportDeformations(file_m2)
surf_m3.STARData.Deformations.FEAData.ImportDeformations(file_m3)

#Open displacement data
file_m1 = data_dir + 'pm1_Surface_03_Deformation.txt'
file_m2 = data_dir + 'pm1_Surface_08_Deformation.txt'
file_m3 = data_dir + 'pm1_Surface_13_Deformation.txt'

surf_m1.STARData.Deformations.FEAData.ImportDeformations(file_m1)
surf_m2.STARData.Deformations.FEAData.ImportDeformations(file_m2)
surf_m3.STARData.Deformations.FEAData.ImportDeformations(file_m3)

#Set dz = 180 deg for nominal system alignment
surf_m1.STARData.Deformations.CoordinateTransform.SetTransformValuesWithAngles(0,0,180,0,0,0)
surf_m2.STARData.Deformations.CoordinateTransform.SetTransformValuesWithAngles(0,0,180,0,0,0)
surf_m3.STARData.Deformations.CoordinateTransform.SetTransformValuesWithAngles(0,0,180,0,0,0)

if not surf_m1.STARData.Deformations.FEAData.AreDeformationsApplied():
    sys.exit('Deformations not applied for timestep: X')

#Plot initial system error?


#Run optimizer (some set of change weights and running with various algorithms to get to a minimum?)
LocalOpt = TheSystem.Tools.OpenLocalOptimization()
if (LocalOpt != None):

    LocalOpt.Algorithm = ZOSAPI.Tools.Optimization.OptimizationAlgorithm.OrthogonalDescent
    LocalOpt.Cycles = ZOSAPI.Tools.Optimization.OptimizationCycles.Fixed_10_Cycles
    LocalOpt.NumberOfCores = 32
    print('Local Optimization...')
    print('Initial Merit Function ', LocalOpt.InitialMeritFunction)
    
    LocalOpt.RunAndWaitForCompletion()
    print('Intermediate Merit Function   ', LocalOpt.CurrentMeritFunction)
    LocalOpt.Close()

HammerOpt = tools.OpenHammerOptimization()
if (HammerOpt != None):
    
    HammerOpt.Algorithm = ZOSAPI.Tools.Optimization.OptimizationAlgorithm.DampedLeastSquares
    HammerOpt.NumberOfCores = 32
    print('Hammering...')

    HammerOpt.RunAndWaitWithTimeout(90)
    print('Final Merit Function ', HammerOpt.CurrentMeritFunction)
    HammerOpt.Close


#loop over timesteps (2-N)

chief_arr = np.zeros(10,2)
#Get chief ray location at each optic (in lens coords)
#Note, may need to set hx,hy (field 4) to 1!
for i in range(10):
    chief_arr[i-1,0] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAX, surf_inds[i-1],0,0,0,0,0,0,0)
    chief_arr[i-1,1] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAY, surf_inds[i-1],0,0,0,0,0,0,0)



#Wavefront map @ surf ???
ZOSAPI.Analysis.I_Analyses.New_WavefrontMap()


# Beamwalk parameters at optics (this seems to be factored into wavefront calcs...?)







#Open new displacement data

#If flag, optimize again

#endloop


#Final timestep

# export data


