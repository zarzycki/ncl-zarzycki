import os
import numpy as np
import xarray as xr
import metpy.calc as mpcalc
from metpy.units import units
import calpreciptype
from tqdm import tqdm
import math
import argparse

# positional args

#python -m numpy.f2py --opt='-O3' -c calpreciptype.f90 -m calpreciptype
#print(calpreciptype.calwxt_ramer.__doc__)
#print(calpreciptype.calwxt_bourg.__doc__)
#print(calpreciptype.calwxt_revised.__doc__)
#print(calpreciptype.calwxt.__doc__)

#ncar_pylib 20200417

parser = argparse.ArgumentParser()
parser.add_argument('stix',type=int)
args = parser.parse_args()

grav=9.80665
d608=0.608
rog=287.04/grav
h1=1.0
d00=0.0

stride=1

STAIX=args.stix
FINIX=STAIX+16
LOOPIX=FINIX-STAIX

#--  data file name
#fname  = "T.nc"
#fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_mdl.011_tmp.reg_tl319.2013010100_2013011018.grb2"
#ds = xr.open_dataset(fname, engine='pynio')
fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_mdl.011_tmp.reg_tl319.2013*.nc"
ds = xr.open_mfdataset(fname, coords="minimal", data_vars="minimal", compat="override", combine='by_coords')

### Check if the maximum time length is beyond finix, if so, truncate
timeArr = ds.initial_time0_hours.values
MAXIX=len(timeArr)
FINIX=min([FINIX, MAXIX])
LOOPIX=FINIX-STAIX
print(STAIX,' ',FINIX)

T = ds.TMP_GDS4_HYBL[STAIX:FINIX,:,::stride,::stride]
T = T.rename({'initial_time0_hours':'time','lv_HYBL1':'lev','g4_lat_2':'lat','g4_lon_3':'lon'})
T.load()
ds.close()

TLLLcoords = T.coords
TLLcoords = {'time': T.coords['time'], 'lat': T.coords['lat'], 'lon': T.coords['lon']}

formattedDate = T['time'].dt.strftime('%Y%m%d%H')
#outFileName = (formattedDate[0].values,'saved_on_disk.nc',sep='')
outFileName = os.path.join('/glade/u/home/zarzycki/scratch/JRA-ptype/' + formattedDate[0].values + '_ptype.nc')

#fname  = "Q.nc"
#fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_mdl.051_spfh.reg_tl319.2013010100_2013011018.grb2"
#ds = xr.open_dataset(fname, engine='pynio')
fname="/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_mdl.051_spfh.reg_tl319.2013*.nc"
ds = xr.open_mfdataset(fname, coords="minimal", data_vars="minimal", compat="override", combine='by_coords')
Q = ds.SPFH_GDS4_HYBL[STAIX:FINIX,:,::stride,::stride]
Q = Q.rename({'initial_time0_hours':'time','lv_HYBL1':'lev','g4_lat_2':'lat','g4_lon_3':'lon'})
Q.load()
ds.close()

f = open('JRA-55.model_level_coef_L60.csv', 'r')
data = np.genfromtxt(f, delimiter=',')
hyai_ = data[:,0]
hybi_ = data[:,1]
nlevi=len(hyai_)
nlev=nlevi-1

hyam_ = np.empty([nlev])
hybm_ = np.empty([nlev])
for ii in range(nlev):
  hyam_[ii] = (hyai_[ii] + hyai_[ii+1]) / 2.
  hybm_[ii] = (hybi_[ii] + hybi_[ii+1]) / 2.

hyam = xr.DataArray(hyam_, dims=['lev'])
hybm = xr.DataArray(hybm_, dims=['lev'])
hyai = xr.DataArray(hyai_, dims=['ilev'])
hybi = xr.DataArray(hybi_, dims=['ilev'])

## This handles model level data by reading PS and "building" p at model levels
#fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_surf.001_pres.reg_tl319.2013010100_2013123118.grb2"
#ds = xr.open_dataset(fname, engine='pynio')
fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/anl_surf.001_pres.reg_tl319.2013*.nc"
ds = xr.open_mfdataset(fname, combine='by_coords')
PS=ds.PRES_GDS4_SFC[STAIX:FINIX,::stride,::stride]
PS = PS.rename({'initial_time0_hours':'time','g4_lat_1':'lat','g4_lon_2':'lon'})
PS.load()
ds.close()

pmid = hyam + hybm*PS
pmid.name="PMID"
pmid.attrs['units'] = 'Pa'
pmid = pmid.transpose('time', 'lev', 'lat', 'lon')
pint = hyai + hybi*PS
pint.name="PINT"
pint.attrs['units'] = 'Pa'
pint = pint.transpose('time', 'ilev', 'lat', 'lon')

### This code reads a level file and expands the dimensions to match lat/lon
#lev = T.coords['level']  #.values
#pmid = lev.expand_dims({'latitude': T.coords['latitude'], 'longitude': T.coords['longitude']},(1,2))
### CMZ needs to add pint


## This handles model level data by reading PS and "building" p at model levels
fname  = "/glade/u/home/zarzycki/scratch/JRAsym/2013/tl319.006_gp.reg_tl319.2013.nc"
ds = xr.open_dataset(fname)
PHIS=ds.GP_GDS4_SFC[::stride,::stride]
PHIS = PHIS.rename({'g4_lat_0':'lat','g4_lon_1':'lon'})
ds.close()

tq = mpcalc.virtual_temperature(T, Q)
TKV = xr.DataArray(np.asarray(tq), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
TKV.name="TKV"
del tq

#zint = np.empty(T.sizes)
#TVBAR = np.empty(T.sizes)

#zint = xr.DataArray(np.empty(   ), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
#TVBAR = xr.DataArray(np.empty(   ), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)

# 
# c calculate geopotential height if initial z available [hydrostatic eq]
# 
#       ZH(1) = ZSFC
#       DO NL = 2,NLVL
# C same as [ln(p(nl)+ln(p(nl-1)]
#           TVBAR = (TKV(NL)*DLOG(P(NL))+TKV(NL-1)*DLOG(P(NL-1)))/
#      +            DLOG(P(NL)*P(NL-1))
#           ZH(NL) = ZH(NL-1) + RDAG*TVBAR*DLOG(P(NL-1)/P(NL))
#       END DO


zint=xr.zeros_like(pint)
#TVBAR=xr.zeros_like(T)

for zz in range(LOOPIX):
  zint[zz,0,:,:] = PHIS/grav
  for kk in tqdm(range(nlevi-1)):
    #print(kk,' ',pint[zz,kk+1,0,0].values)
    #TVBAR[zz,kk+1,:,:] = ( TKV[zz,kk+1,:,:]*np.log(pint[zz,kk+1,:,:]) + TKV[zz,kk,:,:]*np.log(pint[zz,kk,:,:]) ) / np.log(pint[zz,kk,:,:] * pint[zz,kk+1,:,:])
    #zint[zz,kk+1,:,:] = zint[zz,kk+1,:,:] + rog * TVBAR[zz,kk+1,:,:] * np.log(pint[zz,kk,:,:]/pint[zz,kk+1,:,:])
    zint[zz,kk+1,:,:] = zint[zz,kk,:,:] + rog * TKV[zz,kk,:,:] * np.log(pint[zz,kk,:,:]/pint[zz,kk+1,:,:])

#zintarr = xr.DataArray(np.asarray(zint), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
zint.name="ZINT"
zint.attrs['units'] = 'm'

del TKV





#zint_std=mpcalc.pressure_to_height_std(pint).to('m')
#zint2 = xr.DataArray(np.asarray(zint_std), dims=('time', 'ilev', 'lat', 'lon'), coords={'time': T.coords['time'], 'ilev': pint.coords['ilev'], 'lat': T.coords['lat'], 'lon': T.coords['lon']})
#zint2.name="ZINT2"
#int2.attrs['units'] = 'm'







#### This is all non-model specific stuff

##rh = mpcalc.relative_humidity_from_specific_humidity(Q, T, pmid)
##rharr = xr.DataArray(np.asarray(rh), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
##rharr.name="RH"

##td = mpcalc.dewpoint_from_specific_humidity(Q, T, pmid).to('K')
##tdarr = xr.DataArray(np.asarray(td), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
##tdarr.name="TD"
##tdarr.attrs['units'] = 'K'

##TW = (T-273.15)*np.arctan(0.151977*((rharr*100.)+8.313659)**(0.5))+np.arctan((T-273.15) + (rharr*100.)) - np.arctan((rharr*100.) - 1.676331) + 0.00391838*(rharr*100.)**(3/2)*np.arctan(0.023101*(rharr*100.)) - 4.686035
##TW = TW + 273.15
##TWET = xr.DataArray(np.asarray(TW), dims=('time', 'lev', 'lat', 'lon'), coords=TLLLcoords)
##TWET.name="TWET"
##TWET.attrs['units'] = 'K'

#ptypea = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=TLLcoords)
#ptypea.name="PTYPEA"
ptypeb = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=TLLcoords)
ptypeb.name="PTYPEB"
#ptypec = xr.DataArray(0, dims=('time', 'lat', 'lon'), coords=TLLcoords)
#ptypec.name="PTYPEC"

print("LOOP")
for zz in range(LOOPIX):
  for jj in tqdm(range(T.sizes['lon'])):
    for ii in range(T.sizes['lat']):
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

      #ptypea[zz,ii,jj] = calpreciptype.calwxt_ramer(T[zz,::-1,ii,jj],pmid[zz,::-1,ii,jj],rharr[zz,::-1,ii,jj],tdarr[zz,::-1,ii,jj])
      ptypeb[zz,ii,jj] = calpreciptype.calwxt_bourg(np.random.rand(2),grav,T[zz,::-1,ii,jj],Q[zz,::-1,ii,jj],pmid[zz,::-1,ii,jj],pint[zz,::-1,ii,jj],zint[zz,::-1,ii,jj])
      #ptypec[zz,ii,jj] = calpreciptype.calwxt_bourg(np.random.rand(2),grav,T[zz,::-1,ii,jj],Q[zz,::-1,ii,jj],pmid[zz,::-1,ii,jj],pint[zz,::-1,ii,jj],zint2[zz,::-1,ii,jj])

      # add logic for pmid dims

      #ptypea[zz,ii,jj] = calpreciptype.calwxt_ramer(T[zz,:,ii,jj],pmid[zz,:,ii,jj],rharr[zz,:,ii,jj],tdarr[zz,:,ii,jj])
      #ptypeb[zz,ii,jj] = calpreciptype.calwxt_bourg(np.random.rand(2),grav,T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'))
      #ptypec[zz,ii,jj] = calpreciptype.calwxt(T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],d608,rog,1.0E-10,mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'),TWET[zz,:,ii,jj])
      #ptyped[zz,ii,jj] = calpreciptype.calwxt_revised(T[zz,:,ii,jj],Q[zz,:,ii,jj],pmid[zz,:,ii,jj],pint[zz,:,ii,jj],d608,rog,1.0E-10,mpcalc.pressure_to_height_std(pint[zz,:,ii,jj]).to('m'),TWET[zz,:,ii,jj])

      #print(ptype[zz,ii,jj])

#rh.transpose('time', 'lev', 'lat', 'lon')

#ptype = calpreciptype.calwxt_ramer(t,pmid,rh,td)

#sum = xr.merge([ptypea,ptypeb,ptypec,T,TWET,tdarr,rharr,pmid,zint])

ptypeb.to_netcdf(outFileName, unlimited_dims = "time", encoding={'time':{'units':'days since 1950-01-01'}} )

