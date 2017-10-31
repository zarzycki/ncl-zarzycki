;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_gpi.ncl"
;========================================================
begin

domask = 1 ; 0 = true, 1 = false
grid = "ne30" ; Options are "ne30" and "refined"

startyear = 2000
endyear = 2001 ; The last year of data
numyears = endyear-startyear+1      
monGPIarray = new(12*numyears,"float")
yeararray = new(12*numyears,"integer")
monarray = new(12*numyears,"integer")
monstr = new(12,"string")

monstr(:) = (/ "01","02","03","04","05","06","07","08","09","10","11","12" /)

horizstride = 2
print("With horizstride = "+horizstride+" the effective resolution is: "+(0.25*horizstride)+" degrees")

;tcMask = mask_tc(0,-2,-2,horizstride/4,360)

a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
lsdata = a->LSMASK

if (grid .eq. "refined") then
  filesdir = "/glade/scratch/zarzycki/AMIP_monthly/"
  monavgleadstr = "monavg_"
else if (grid .eq. "ne30") then
  filesdir = "/glade/scratch/zarzycki/ne30amip/2005/"
  monavgleadstr = "ne30amip_monavg_"
  wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_AMIP_ref_latlon_patc.130523.nc"
else
  print("Incorrect grid specified")
  exit
end if
end if

;========================
; get list of all files and open as "one big file"
;========================                             
all_files = systemfunc("ls "+ filesdir+"/ne30amip.cam.h3.2005-01*.nc " \
                          )
print(all_files)
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
  ;========================
  ; choose how files are combined and read in variable across files
  ;========================  
ListSetType (fall, "cat")             ; concatenate or "merge" (default)

lev  = fall[0]->lev
time = fall[:]->time

print(lev)

print("Loading the data")

if (grid .eq. "refined") then
  SST = h1file->TREFHT(:,::horizstride,::horizstride)
  T = h3file->T(:,{800:400},::horizstride,::horizstride)
  Q = h3file->Q(:,{800:400},::horizstride,::horizstride)
  U = h3file->U(:,{1000:100},::horizstride,::horizstride)
  V = h3file->V(:,{1000:100},::horizstride,::horizstride)
  lat = h3file->lat(::horizstride)
  lon = h3file->lon(::horizstride)
else if (grid .eq. "ne30") then
  T_native = fall[:]->T(:,{900:800},:)
  V_native = fall[:]->V(:,{900:800},:)
  
  print("Regridding the data")
  Opt         = True
  Opt@CopyVarCoords = True
  T_full  = ESMF_regrid_with_weights(T_native,wgt_file,Opt)
  V_full  = ESMF_regrid_with_weights(V_native,wgt_file,Opt)
  lat_full = T_full&lat
  lon_full = T_full&lon
  
  delete([/T_native,V_native/])
  
  T = T_full(:,:,::horizstride,::horizstride)
  V = V_full(:,:,::horizstride,::horizstride)
  lat = lat_full(::horizstride)
  lon = lon_full(::horizstride)
  
  delete([/T_full,V_full,lat_full,lon_full/])
else
  print("Incorrect grid specified")
  exit
end if
end if

print("Interpolating to vertical levels")

Tlev = lev({900:800})
print(Tlev)
printVarSummary(T)
T850_interp = int2p_n_Wrap(Tlev,T,(/ 850. /),2,1)
T850 = rm_single_dims(T850_interp)
delete(T)
delete(Tlev)

Vlev = lev({900:800})
V850_interp = int2p_n_Wrap(Vlev,V,(/ 850. /),2,1)
V850 = rm_single_dims(V850_interp)
delete(V)
delete(Vlev)

printVarSummary(V850)

vt = fluxEddy(V850(lat|:,lon|:,time|:),T850(lat|:,lon|:,time|:))


V850avg = dim_avg( V850(lat|:, lon|:, time|:) )

;printVarSummary(vt)

vt!0    = "lat"                      ; assign named dimensions
vt!1    = "lon"
       
vt&lat = T850&lat
vt&lon = T850&lon

wks = gsn_open_wks("pdf","eddy")               ; open a ps file
  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap

  res                       = True               ; plot mods desired
  res@cnFillOn              = True               ; turn on color fill
  res@cnLinesOn             = False              ; turn off contour lines

;---This resource not needed in V6.1.0
  res@gsnSpreadColors       = True               ; use full range of color map

  plot = gsn_csm_contour_map_ce(wks,vt,res)
  
end
