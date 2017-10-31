;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

filedir = "/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/"
;filename = "ne30_climo_h0.all.nc_regrid.nc"
ccmname = "atl30x4_monthlyavg_climo_01_3D.nc"
vertfile = "atl30x4_climo.nc"
psfile = "atl30x4_monthlyavg_climo_h0.01.nc"

fccm  = addfile (filedir+"/"+ccmname, "r")
fvert = addfile (filedir+"/"+vertfile, "r")
fps = addfile (filedir+"/"+psfile, "r")

hyam  = fvert->hyam(0,:)                   
hybm  = fvert->hybm(0,:) 
hyai  = fvert->hyai(0,:)                    
hybi  = fvert->hybi(0,:) 
p0    = fvert->P0(0) 
psfc  = fps->PS
u     = fccm->U 
v     = fccm->V

print(p0)

omega = omega_ccm_driver(p0,psfc,u,v,hyam,hybm,hyai,hybi)

system("/bin/rm -f "+filedir+"/omega.nc")   ; remove any pre-existing file
ncdf     = addfile(filedir+"/omega.nc" ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->OMEGA  = omega                          ; 4D               
  
end
