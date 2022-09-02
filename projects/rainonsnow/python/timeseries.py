import numpy as np
import xarray as xr

ds_disk = xr.open_mfdataset('/storage/home/cmz5202/group/arp5873/E3SM/RoS-F2010C5-ne30-001-control/1996011600/RoS-F2010C5-ne30-001-control.eam.h0.1996-01-*_regrid.nc',
             concat_dim="time", data_vars='minimal', coords='minimal', compat='override')
             
print(ds_disk)