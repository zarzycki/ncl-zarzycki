import os
import numpy as np
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units
import calpreciptype
from tqdm import tqdm

#python -m numpy.f2py -c calpreciptype.f90 -m calpreciptype
print(calpreciptype.calwxt_ramer.__doc__)
print(calpreciptype.calwxt_bourg.__doc__)
print(calpreciptype.calwxt_revised.__doc__)
print(calpreciptype.calwxt.__doc__)

grav=9.81
d608=0.608
rog=287.04/grav
h1=1.0
d00=0.0

FINIX=3

#--  data file name
fname  = "T.nc"
ds = xr.load_dataset(fname)
T = ds.T[0:FINIX,:,:,:]

fname  = "Q.nc"
ds = xr.load_dataset(fname)
Q = ds.Q[0:FINIX,:,:,:]

fname  = "PS.nc"
ds = xr.load_dataset(fname)
PS=ds.PS[0:FINIX,:,:]
pmid = ds.hyam*ds.P0 + ds.hybm*PS
pmid.name="PMID"
pmid.attrs['units'] = 'Pa'
pmid = pmid.transpose('time', 'lev', 'lat', 'lon')

pint = ds.hyai*ds.P0 + ds.hybi*ds.PS
pint.name="PINT"
pint.attrs['units'] = 'Pa'
pint = pint.transpose('time', 'ilev', 'lat', 'lon')

rh = mpcalc.relative_humidity_from_specific_humidity(Q, T, pmid)
rharr = xr.DataArray(np.asarray(rh), dims=('time', 'lev', 'lat', 'lon'), coords=Q.coords)
rharr.name="RH"

td = mpcalc.dewpoint_from_specific_humidity(Q, T, pmid).to('K')
tdarr = xr.DataArray(np.asarray(td), dims=('time', 'lev', 'lat', 'lon'), coords=Q.coords)
tdarr.name="TD"
tdarr.attrs['units'] = 'K'


TW = (T-273.15)*np.arctan(0.151977*((rharr*100.)+8.313659)**(0.5))+np.arctan((T-273.15) + (rharr*100.)) - np.arctan((rharr*100.) - 1.676331) + 0.00391838*(rharr*100.)**(3/2)*np.arctan(0.023101*(rharr*100.)) - 4.686035
TW = TW + 273.15
TWET = xr.DataArray(np.asarray(TW), dims=('time', 'lev', 'lat', 'lon'), coords=PS.coords)
TWET.name="TWET"
TWET.attrs['units'] = 'K'

ptypea = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=PS.coords)
ptypea.name="PTYPEA"
ptypeb = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=PS.coords)
ptypeb.name="PTYPEB"
ptypec = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=PS.coords)
ptypec.name="PTYPEC"
ptyped = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=PS.coords)
ptyped.name="PTYPED"
print("LOOP")
for zz in range(FINIX):
  for ii in tqdm(range(191)):
    for jj in range(287):
      #tt = T[zz,:,ii,jj]
      #qq = Q[zz,:,ii,jj]
      #pp = pmid[zz,:,ii,jj]
      #pi = pint[zz,:,ii,jj]
      #zi = mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m')
      #rr = rharr[zz,:,ii,jj]
      #dd = tdarr[zz,:,ii,jj]
      #tw = TWET[zz,:,ii,jj]

      #if jj == 0:
        #print(grav)
        #print(tt)
        #print(qq)
        #print(pp)
        #print(pi)
        #print(zi)
      
      # everything needs to be arranged top to bottom
      #ptypea[zz,ii,jj] = calpreciptype.calwxt_ramer(tt,pp,rr,dd)
      #ptypeb[zz,ii,jj] = calpreciptype.calwxt_bourg(np.random.rand(2),grav,tt,qq,pp,pi,zi)
      #ptypec[zz,ii,jj] = calpreciptype.calwxt(tt,qq,pp,pi,d608,rog,1.0E-10,zi,tw)
      #ptyped[zz,ii,jj] = calpreciptype.calwxt_revised(tt,qq,pp,pi,d608,rog,1.0E-10,zi,tw)

      ptypea[zz,ii,jj] = calpreciptype.calwxt_ramer(T[zz,:,ii,jj],pmid[zz,:,ii,jj],rharr[zz,:,ii,jj],tdarr[zz,:,ii,jj])
      ptypeb[zz,ii,jj] = calpreciptype.calwxt_bourg(np.random.rand(2),grav,T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'))
      #ptypec[zz,ii,jj] = calpreciptype.calwxt(T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],d608,rog,1.0E-10,mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'),TWET[zz,:,ii,jj])
      ptyped[zz,ii,jj] = calpreciptype.calwxt_revised(T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],d608,rog,1.0E-10,mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'),TWET[zz,:,ii,jj])

      #print(ptype[zz,ii,jj])

#rh.transpose('time', 'lev', 'lat', 'lon')

#ptype = calpreciptype.calwxt_ramer(t,pmid,rh,td)

sum = xr.merge([ptypea,ptypeb,ptypec,ptyped,T,TWET,tdarr,rharr])

sum.to_netcdf('saved_on_disk.nc')

