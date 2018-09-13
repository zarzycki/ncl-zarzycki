import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
import sys

ensnum='001'
indir  = '/glade/u/home/zarzycki/scratch/LENS-snow/'
files  = [indir+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PTYPE.1990010100Z-2005123118Z.nc']
indir2 = '/glade/p_old/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly6/PRECT/'
files2 = [indir2+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PRECT.1990010100Z-2005123118Z.nc']
indir3 = indir
files3 = [indir3+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PRECT_SNOW.1990010100Z-2005123118Z.nc']

for idx, val in enumerate(files):
  ds  = xr.open_dataset(files[idx])
  ds2 = xr.open_dataset(files2[idx])
  ds3 = xr.open_dataset(files3[idx])

  ptype  = ds.PTYPE[1:11,:,:]
  prect1 = ds2.PRECT[1:11,:,:]
  prect2 = ds3.PRECT_SNOW[1:11,:,:]
  print('---------')
  print(ptype)
  print(prect1)
  print(prect2)

  ptype1 = ptype.where((ptype > -0.1) & (ptype < 0.1) & (prect1 > 1e-8))
  ptype2 = ptype.where((ptype > -0.1) & (ptype < 0.1) & (prect2 > 1e-8))
  print('---------')
  print(ptype1)
  print(ptype2)

exit()