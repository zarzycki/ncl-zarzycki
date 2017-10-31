load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

whichprecip = "TRMM" ; TRMM or GPCP
conserve_remap=True

; Get lat/lon and gw arrays from model
print("Getting lat lon and gw from CAM-SE grid")
SElatlonfile = addfile("/glade/scratch/zarzycki/regrid/other_regrid.nc","r")
;SElatlonfile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/atl30x4_climo_new_conserve_2.5.nc","r")
seLat = SElatlonfile->lat
seLon = SElatlonfile->lon

print("Getting various fields from files")
ncepfileT = addfile("/glade/p/work/zarzycki/ncep/air.mon.ltm.nc","r")
; we have to invert lat array since ncep goes from 90 -> -90 and 
; NCL interp requires monotonic increase
ncepLat = ncepfileT->lat(::-1)
ncepLon = ncepfileT->lon
T500_n = ncepfileT->air(:,{500},::-1,:)
T850_n = ncepfileT->air(:,{850},::-1,:)

ncepfileOMEGA = addfile("/glade/p/work/zarzycki/ncep/omega.mon.ltm.nc","r")
OMEGA500_n = ncepfileOMEGA->omega(:,{500},::-1,:)
OMEGA850_n = ncepfileOMEGA->omega(:,{850},::-1,:)

ncepfileU = addfile("/glade/p/work/zarzycki/ncep/uwnd.mon.ltm.nc","r")
U_n = ncepfileU->uwnd(:,:,::-1,:)

ncepfileV = addfile("/glade/p/work/zarzycki/ncep/vwnd.mon.ltm.nc","r")
V_n = ncepfileV->vwnd(:,:,::-1,:)

ncepfileRH = addfile("/glade/p/work/zarzycki/ncep/rhum.mon.ltm.nc","r")
RELHUM_n = ncepfileRH->rhum(:,:,::-1,:)
; Going to try and rename levels dimension since other NCEP state vars use
; 17 levs instead of 8
RELHUM_n!1 = "level8"

ncepfilePSL = addfile("/glade/p/work/zarzycki/ncep/slp.mon.ltm.nc","r")
PSL_orig = ncepfilePSL->slp(:,::-1,:)
PSL_n = PSL_orig*100.

ceresfilesfc = addfile("/glade/p/work/zarzycki/ncep/CERES_EBAF-Surface_Ed2.7_Subset_CLIM01-CLIM12.nc","r")
ceresLat = ceresfilesfc->lat
ceresLon = ceresfilesfc->lon
FSNS_n = ceresfilesfc->sfc_net_sw_clr_clim(:,:,:)

isccpfiles = addfile("/glade/p/work/zarzycki/ncep/isccp_d2_climo.nc","r")
isccpLat = isccpfiles->lat
isccpLon = isccpfiles->lon
CLDTOT_orig = isccpfiles->MnCldAmt(:,:,:)
CLDTOT_n = CLDTOT_orig/100.
CLDTOT_n=lonFlip(CLDTOT_n)
isccpLon = lonFlip(isccpLon)

if (whichprecip .eq. "GPCP") then
  gpcpfile = addfile("/glade/p/work/zarzycki/ncep/precip.mon.ltm.nc","r")
  gpcpLat = gpcpfile->lat(::-1)
  gpcpLon = gpcpfile->lon
  PRECT_orig = gpcpfile->precip(:,::-1,:)
  PRECT_n = PRECT_orig / 1000 / 86400
else if (whichprecip .eq. "TRMM") then
  trmmfiles = addfile("/glade/p/work/zarzycki/ncep/trmm_climo.nc","r")
  trmmLat = trmmfiles->latitude
  trmmLon = trmmfiles->longitude
  trmmMaxLat = max(trmmLat)
  trmmMinLat = min(trmmLat)
  PRECT_orig = trmmfiles->pcp
  PRECT_n = PRECT_orig / 1000 / 3600
  PRECT_n=lonFlip(PRECT_n)
  trmmLon = lonFlip(trmmLon)
else
  print("Bad precip choice")
  exit()
end if
end if

merrafilesTMQ = addfile("/glade/p/work/zarzycki/ncep/merraclimo.nc","r")
merraLat = merrafilesTMQ->latitude
merraLon = merrafilesTMQ->longitude
TMQ_n = merrafilesTMQ->tqv(:,:,:)
TMQ_n=lonFlip(TMQ_n)
merraLon = lonFlip(merraLon)

merrafilesflux = addfile("/glade/u/home/zarzycki/work/ncep/MERRA/sfc_flx/sfc_flx_MERRA_climo.nc","r")
LHFLX_n = merrafilesflux->eflux(:,:,:)
SHFLX_n = merrafilesflux->hflux(:,:,:)
LHFLX_n=lonFlip(LHFLX_n)
SHFLX_n=lonFlip(SHFLX_n)

merraLon = where(merraLon.lt.0, 360.+merraLon, merraLon) 
isccpLon = where(isccpLon.lt.0, 360.+isccpLon, isccpLon)
if (whichprecip .eq. "TRMM") then
  trmmLon = where(trmmLon.lt.0, 360.+trmmLon, trmmLon) 
end if


if (conserve_remap) then
  print("Starting conserve remap")
  T500 = area_conserve_remap_Wrap (ncepLon,ncepLat,T500_n,seLon,seLat, False)
  T850 = area_conserve_remap_Wrap (ncepLon,ncepLat,T850_n,seLon,seLat, False)
  OMEGA500 = area_conserve_remap_Wrap (ncepLon,ncepLat,OMEGA500_n,seLon,seLat, False)
  OMEGA850 = area_conserve_remap_Wrap (ncepLon,ncepLat,OMEGA850_n,seLon,seLat, False)
  U = area_conserve_remap_Wrap (ncepLon,ncepLat,U_n,seLon,seLat, False)
  V = area_conserve_remap_Wrap (ncepLon,ncepLat,V_n,seLon,seLat, False)
  RELHUM = area_conserve_remap_Wrap (ncepLon,ncepLat,RELHUM_n,seLon,seLat, False)
  PSL = area_conserve_remap_Wrap (ncepLon,ncepLat,PSL_n,seLon,seLat, False)
  FSNS = area_conserve_remap_Wrap (ceresLon,ceresLat,FSNS_n,seLon,seLat, False)
  TMQ = area_conserve_remap_Wrap (merraLon,merraLat,TMQ_n,seLon,seLat, False)
  LHFLX = area_conserve_remap_Wrap (merraLon,merraLat,LHFLX_n,seLon,seLat, False)
  SHFLX = area_conserve_remap_Wrap (merraLon,merraLat,SHFLX_n,seLon,seLat, False)
  CLDTOT = area_conserve_remap_Wrap (isccpLon,isccpLat,CLDTOT_n,seLon,seLat, False)
  if (whichprecip .eq. "GPCP") then
    PRECT = area_conserve_remap_Wrap (gpcpLon,gpcpLat,PRECT_n,seLon,seLat, False)
  else if (whichprecip .eq. "TRMM") then
    PRECT = area_conserve_remap_Wrap (trmmLon,trmmLat,PRECT_n,seLon,seLat, False)
    guess     = 1                ; use zonal means
    is_cyclic = True             ; cyclic [global]
    nscan     = 1500             ; usually much less than this
    eps       = 1.e-2            ; variable dependent
    relc      = 0.6              ; relaxation coefficient
    opt       = 0                ; not used
    PRECT = where(conform(PRECT,PRECT&lat,1).gt.trmmMaxLat,PRECT@_FillValue,PRECT)
    PRECT = where(conform(PRECT,PRECT&lat,1).lt.trmmMinLat,PRECT@_FillValue,PRECT)
    ;poisson_grid_fill( PRECT, is_cyclic, guess, nscan, eps, relc, opt)
  else
    print("Bad precip choice")
    exit()
  end if
  end if
else
  print("Starting lin int")
  T500 = linint2_Wrap (ncepLon,ncepLat,T500_n,True,seLon,seLat, 0)
  T850 = linint2_Wrap (ncepLon,ncepLat,T850_n,True,seLon,seLat, 0)
  OMEGA500 = linint2_Wrap (ncepLon,ncepLat,OMEGA500_n,True,seLon,seLat, 0)
  OMEGA850 = linint2_Wrap (ncepLon,ncepLat,OMEGA850_n,True,seLon,seLat, 0)
  U = linint2_Wrap (ncepLon,ncepLat,U_n,True,seLon,seLat, 0)
  V = linint2_Wrap (ncepLon,ncepLat,V_n,True,seLon,seLat, 0)
  RELHUM = linint2_Wrap (ncepLon,ncepLat,RELHUM_n,True,seLon,seLat, 0)
  PSL = linint2_Wrap (ncepLon,ncepLat,PSL_n,True,seLon,seLat, 0)
  FSNS = linint2_Wrap (ceresLon,ceresLat,FSNS_n,True,seLon,seLat, 0)
  TMQ = linint2_Wrap (merraLon,merraLat,TMQ_n,True,seLon,seLat, 0)
  LHFLX = linint2_Wrap (merraLon,merraLat,LHFLX_n,True,seLon,seLat, 0)
  SHFLX = linint2_Wrap (merraLon,merraLat,SHFLX_n,True,seLon,seLat, 0)
  CLDTOT = linint2_Wrap (isccpLon,isccpLat,CLDTOT_n,True,seLon,seLat, 0)
  if (whichprecip .eq. "GPCP") then
    PRECT = linint2_Wrap (gpcpLon,gpcpLat,PRECT_n,True,seLon,seLat, 0)
  else if (whichprecip .eq. "TRMM") then
    PRECT = linint2_Wrap (trmmLon,trmmLat,PRECT_n,True,seLon,seLat, 0)
    guess     = 1                ; use zonal means
    is_cyclic = True             ; cyclic [global]
    nscan     = 1500             ; usually much less than this
    eps       = 1.e-2            ; variable dependent
    relc      = 0.6              ; relaxation coefficient
    opt       = 0                ; not used
    ;poisson_grid_fill( PRECT, is_cyclic, guess, nscan, eps, relc, opt)
  else
    print("Bad precip choice")
    exit()
  end if
  end if
end if

print("Done with interpolation")

print("Copying metadata")
copy_VarCoords(TMQ,PRECT)
copy_VarCoords(TMQ,CLDTOT)
copy_VarCoords(TMQ,PSL)
;copy_VarCoords(TMQ,FSNS)

seGW  = latRegWgt(seLat, "double", 0)
;=====================================================================
; Assume variables T, PS exist and that they have coordinate variables 
;      T  is four  dimensional:  T(time,lev,lat,lon)
;      PS is three dimensional: PS(time,lat,lon)
;
; Assume that ORO exists. ORO is two dimensional
; but it does not have any coordinate variables
; or attributes associated with it. 
; These must then be explicitly assigned. Assume the
; lat/lon coordinate arrays can be taken from variable T. 
; Note that the file name does not have to be same as variable name  
;=====================================================================
print("Writing file")
system("/bin/rm -f /glade/p/work/zarzycki/ncep/ncep_climo.nc")   ; remove any pre-existing file
ncdf     = addfile("/glade/p/work/zarzycki/ncep/ncep_climo.nc" ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->gw = seGW
ncdf->T500 = T500     
ncdf->T850 = T850 
ncdf->OMEGA500 = OMEGA500     
ncdf->OMEGA850 = OMEGA850 
ncdf->U = U     
ncdf->V = V
ncdf->RELHUM = RELHUM 
ncdf->PSL = PSL 
ncdf->PRECT = PRECT
ncdf->FSNS = FSNS
ncdf->TMQ = TMQ
ncdf->LHFLX = LHFLX
ncdf->SHFLX = SHFLX
ncdf->CLDTOT = CLDTOT

end

