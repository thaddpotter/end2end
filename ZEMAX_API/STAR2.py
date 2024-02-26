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
import matplotlib.pyplot as plt

def transpose(data):
    """Transposes a 2D list (Python3.x or greater).  
    
    Useful for converting mutli-dimensional line series (i.e. FFT PSF)
    
    Parameters
    ----------
    data      : Python native list (if using System.Data[,] object reshape first)    
    
    Returns
    -------
    res       : transposed 2D list
    """
    if type(data) is not list:
        data = list(data)
    return list(map(list, zip(*data)))
    
def reshape(data, x, y, transpose = False):
    """Converts a System.Double[,] to a 2D list for plotting or post processing
    
    Parameters
    ----------
    data      : System.Double[,] data directly from ZOS-API 
    x         : x width of new 2D list [use var.GetLength(0) for dimension]
    y         : y width of new 2D list [use var.GetLength(1) for dimension]
    transpose : transposes data; needed for some multi-dimensional line series data
    
    Returns
    -------
    res       : 2D list; can be directly used with Matplotlib or converted to
                a numpy array using numpy.asarray(res)
    """
    if type(data) is not list:
        data = list(data)
    var_lst = [y] * x;
    it = iter(data)
    res = [list(islice(it, i)) for i in var_lst]
    if transpose:
        return self.transpose(res);
    return res

##STAR Setup
analysis = TheSystem.Analyses
tools = TheSystem.Tools
surf_inds = [3,8,13,18,23,27,31,36,40]
surf_names = ['M1','M2','M3','LODM','Dicro','OAP1','OAP2','BMC','OAP3']
n_surf = len(surf_inds)

#
nsteps = 72

# Get Surfaces
TheLDE = TheSystem.LDE
move_m2 = TheLDE.GetSurfaceAt(7)

#File IO setup
data_dir = 'c:\\Users\\locsst\\Desktop\\TD_picture_working\\ansys\\STAR\\pm\\' 

#Clear Any Leftover STAR Data from previous runs
for i in range(n_surf):
    TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.FEAData.UnloadData()

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

#Set up arrays
chief_arr = np.zeros((n_surf,2,nsteps))
nominal_chief_arr = np.zeros((n_surf,2))

wf = TheSystem.Analyses.New_Analysis(ZOSAPI.Analysis.AnalysisIDM.WavefrontMap)
wf.ApplyAndWaitForCompletion()
wfresults = wf.GetResults()
wfgrid = wfresults.GetDataGrid(0).Values
wfsize = [wfgrid.GetLength(0),wfgrid.GetLength(1)]

wfcube = np.zeros((wfsize[0],wfsize[1],nsteps))

#Get data from nominal system
for i in range(n_surf):
    nominal_chief_arr[i,0] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAX, surf_inds[i],0,0,0,0,0,0,0)
    nominal_chief_arr[i,1] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAY, surf_inds[i],0,0,0,0,0,0,0)

##Run initial timestep
#Open displacement data
for i in range(n_surf):
    disp_file = data_dir + '00_Timestep_00001_20240206' + '\\Surface_' + str(surf_inds[i]).zfill(2) + '_Deformation.txt'
    TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.SetDataIsGlobal()
    TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.FEAData.ImportDeformations(disp_file)

#Run optimizer (some set of change weights and running with various algorithms to get to a minimum?)
LocalOpt = TheSystem.Tools.OpenLocalOptimization()
if (LocalOpt != None):

    LocalOpt.Algorithm = ZOSAPI.Tools.Optimization.OptimizationAlgorithm.OrthogonalDescent
    LocalOpt.Cycles = ZOSAPI.Tools.Optimization.OptimizationCycles.Fixed_10_Cycles
    LocalOpt.NumberOfCores = 32
    print('Local Optimization...')
    print('Initial Merit Function ', LocalOpt.InitialMeritFunction)
    
    LocalOpt.RunAndWaitForCompletion()
    print('Intermediate Merit Function: ', LocalOpt.CurrentMeritFunction)
    LocalOpt.Close()

HammerOpt = tools.OpenHammerOptimization()
if (HammerOpt != None):
    
    HammerOpt.Algorithm = ZOSAPI.Tools.Optimization.OptimizationAlgorithm.DampedLeastSquares
    HammerOpt.NumberOfCores = 32
    print('Hammering...')

    HammerOpt.RunAndWaitWithTimeout(60)
    HammerOpt.Cancel()
    HammerOpt.WaitForCompletion()
    print('Final Merit Function: ', HammerOpt.CurrentMeritFunction)
    
    HammerOpt.Close()

    #Clear variables just in case
tools.RemoveAllVariables()

#Get chief ray location at each optic (in lens coords)
#Note, may need to set hx,hy (field 4) to 1!
for i in range(n_surf):
    chief_arr[i,0,0] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAX, surf_inds[i],0,0,0,0,0,0,0)
    chief_arr[i,1,0] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAY, surf_inds[i],0,0,0,0,0,0,0)

wf.ApplyAndWaitForCompletion()
wfresults = wf.GetResults()
wfgrid = wfresults.GetDataGrid(0).Values
wfarr = reshape(wfgrid,wfgrid.GetLength(0),wfgrid.GetLength(1))

wfcube[:,:,0] = wfarr

#Clear STAR Data for start of looping
for i in range(n_surf):
    TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.FEAData.UnloadData()

for j in range(1,nsteps):
    print(f'Timestep: {str(j+1)} of {str(nsteps)}' ,end='\r')
    
    #Open displacement data
    for i in range(n_surf):
        disp_file = data_dir + str(j).zfill(2) + '_Timestep_0'+str(j).zfill(2)+'00_20240206' + '\\Surface_' + str(surf_inds[i]).zfill(2) + '_Deformation.txt'
        TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.FEAData.ImportDeformations(disp_file)
        #Set dz = 180 deg for nominal system alignment
        #TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.CoordinateTransform.SetTransformValuesWithAngles(0,0,180,0,0,0)

    #Plot initial system error?

    #Get chief ray location at each optic (in lens coords)
    #Note, may need to set hx,hy (field 4) to 1!
    for i in range(n_surf):
        chief_arr[i,0,j] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAX, surf_inds[i],0,0,0,0,0,0,0)
        chief_arr[i,1,j] = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.REAY, surf_inds[i],0,0,0,0,0,0,0)

    wf.ApplyAndWaitForCompletion()
    wfresults = wf.GetResults()
    wfgrid = wfresults.GetDataGrid(0).Values
    wfarr = reshape(wfgrid,wfgrid.GetLength(0),wfgrid.GetLength(1))

    wfcube[:,:,j] = wfarr

    #Clear STAR Data for next timestep
    for i in range(n_surf):
        TheLDE.GetSurfaceAt(surf_inds[i]).STARData.Deformations.FEAData.UnloadData()


##Plot Outputs
bwalk = np.zeros((n_surf,2,nsteps))

for k in range(nsteps):
    bwalk[:,:,k] = chief_arr[:,:,k] - nominal_chief_arr

axis = ['X','Y']

tarr = np.zeros(nsteps)
for i in range(nsteps):
    tarr[i] = 5./3 * i

for j in range(2):
    minv = np.min(bwalk[:,j,:])
    maxv = np.max(bwalk[:,j,:])

    minv -= 0.1*(maxv-minv)
    maxv += 0.1*(maxv-minv)

    plt.figure()
    plt.ylim(minv,maxv)
    plt.title(f'AM Beamwalk over time : {axis[j]} Direction')
    plt.xlabel('Time (Mins)')
    plt.ylabel('Beamwalk (in)')

    for i in range(n_surf):
        plt.plot(tarr,bwalk[i,j,:])

    plt.legend(surf_names,bbox_to_anchor=(1.02, 1), loc='upper left', borderaxespad=0)