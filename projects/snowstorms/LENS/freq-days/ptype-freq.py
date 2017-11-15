import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
import sys

ensnum=sys.argv[1]
print(ensnum)

indir='/glade/u/home/zarzycki/scratch/LENS-snow/'
files = [indir+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PTYPE.1990010100Z-2005123118Z.nc', indir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PTYPE.2026010100Z-2035123118Z.nc', indir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.PTYPE.2071010100Z-2080123118Z.nc']

#indir='/glade/p/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly6/TS/'
#files = [indir+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TS.1990010100Z-2005123118Z.nc', indir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TS.2026010100Z-2035123118Z.nc', indir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TS.2071010100Z-2080123118Z.nc']

nyrs = [16, 10, 10]
outdir=indir

outvarname='PRECBSN_FREQ'
fileout = [outdir+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.'+outvarname+'.1990010100Z-2005123118Z.nc', outdir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.'+outvarname+'.2026010100Z-2035123118Z.nc', outdir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.'+outvarname+'.2071010100Z-2080123118Z.nc']
#fileout = [outdir+'/b.e11.B20TRC5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TSFZ_FREQ.1990010100Z-2005123118Z.nc', outdir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TSFZ_FREQ.2026010100Z-2035123118Z.nc', outdir+'/b.e11.BRCP85C5CNBDRD.f09_g16.'+ensnum+'.cam.h2.TSFZ_FREQ.2071010100Z-2080123118Z.nc']

for idx, val in enumerate(files):
  if idx == 1:
    ptype1 = ptype
  ds = xr.open_dataset(val)
  
  ptype = ds.PTYPE[:,:,:]
  ptype=ptype.where((ptype > -0.1) & (ptype < 0.1))
  ptype=ptype+1
  ptype=ptype.sum(dim='time')
  ptype=ptype/nyrs[idx]/4.

  #ptype = ds.TS[:,:,:]
  #ptype=ptype.where( ptype < 273.15 )
  #ptype=ptype/ptype
  #ptype=ptype.sum(dim='time')
  #ptype=ptype/nyrs[idx]/4.

  ptype = ptype.rename(outvarname)
  print(ptype)
  ptype.attrs['long_name'] = 'Frequency of snow PTYPE from Bourgoin'
  ptype.attrs['units'] = 'days/year'
  ptype_ds = ptype.to_dataset()
  ptype_ds.to_netcdf(path=fileout[idx],mode="w")

exit()

ptype = ptype1-ptype
ptype_ds = ptype.to_dataset()
ptype_ds.to_netcdf(path="diff.nc",mode="w")

ptype.plot()
plt.show()

#airtemps = xr.tutorial.load_dataset('air_temperature')
#air = airtemps.air - 273.15
#air1d = air.isel(lat=10, lon=10)
#print(air1d)
#air1d.plot()