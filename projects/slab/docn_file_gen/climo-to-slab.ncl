load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

SST_write_dir = "/glade/u/home/zarzycki/ncl/projects/slab/"

SST_climo_file = "/glade/p/cesmdata/cseg/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc"
climFile = addfile(SST_climo_file,"r")

print("Writing 1x1 SSTs")
in = addfile(SST_write_dir+"climo_1x1.nc","w")

sstClim = climFile->SST_cpl
sstlat = climFile->lat
sstlon = climFile->lon

regrid =False
;-- if (regrid) then
;--   fvlat  = in->yc
;--   fvlon  = in->xc
;--   numfvlat = dimsizes(fvlat)
;--   numfvlon = dimsizes(fvlon)
;-- 
;--     sst_fv = linint2_Wrap(sstlon,sstlat,sst_gfs,True,fvlon,fvlat,0)
;--     ice_fv = linint2_Wrap(sstlon,sstlat,ice_gfs,True,fvlon,fvlat,0)
;-- 
;-- sst_fv = linmsg(sst_fv,-1)
;-- sst_fv = linmsg_n(sst_fv,-1,0)
;-- 
;-- print("Sorting bad SST")
;-- do i = 0,dimsizes(fvlat)-1
;--     do j = 0,dimsizes(fvlon)-1
;--             if (ismissing(sst_fv(i,j))) then
;--                 print("Found missing SST")
;--                 sst_fv(i,j) = 271.5
;--             else if (sst_fv(i,j) .gt. 500) then
;--                 print("Found bad value")
;--                 sst_fv(i,j) = 271.5
;--             end if
;--             end if
;--         sst_fv(i,j) = sst_fv(i,j); - 273.15
;--     end do
;-- end do
;-- 
;-- print("Converting SST floats to doubles")
;-- sst_fv_dbl = tofloat(sst_fv)
;-- print("Copying SST metadata")
;-- copy_VarMeta(sst_fv,sst_fv_dbl)
;-- delete(sst_fv)
;-- print("Correcting SST time records")
;-- ; Add time record
;-- sst_fv_dbl_time = new((/12,numfvlat,numfvlon/),float)
;-- 
;-- do i = 0,11
;--     sst_fv_dbl_time(i,:,:) = sst_fv_dbl
;-- end do
;-- 
;-- 
;-- end if


; Write to NetCDF
  print("Writing file...")
  
  in->T = (/sstClim/)


  print("done")
  

end
