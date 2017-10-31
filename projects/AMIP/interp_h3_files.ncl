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

;year=1986
;month="02"
;grid="ne30"

outputdir="/glade/scratch/zarzycki/AMIPmonthly/"+year+"/"
outputdaystr="daily"
outputhourstr="6hrly"

if (grid .eq. "ne30") then
 ; output = "homme"
  output = "latlon"
else
  output = "latlon"
end if

;========================
; get list of all files and open as "one big file"
;========================     
all_files = systemfunc ("ls /glade/p/p05010048/zarzycki/"+grid+"amip/"+year+"/*.cam.h3."+year+"-"+month+"*")
;all_files = systemfunc ("ls /glade/scratch/zarzycki/h3files/"+grid+"/"+year+"/*.cam.h3."+year+"-"+month+"*")
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
;========================
; choose how files are combined and read in variable across files
;========================  
ListSetType (fall, "cat")             ; concatenate or "merge" (default)

lev = fall[0]->lev    ; Only get the first lev otherwise it's just time x nlev
time = fall[:]->time
NTIM = dimsizes(time)

print("Getting U")
U = fall[:]->U
print("Getting V")
V = fall[:]->V
print("Getting T")
T = fall[:]->T

print("vertically interpolating U")
U850int = int2p_n_Wrap(lev,U,(/ 850. /),2,1)
U700int = int2p_n_Wrap(lev,U,(/ 700. /),2,1)
U500int = int2p_n_Wrap(lev,U,(/ 500. /),2,1)
U300int = int2p_n_Wrap(lev,U,(/ 300. /),2,1)
U200int = int2p_n_Wrap(lev,U,(/ 200. /),2,1)
U100int = int2p_n_Wrap(lev,U,(/ 100. /),2,1)
if (output .eq. "homme") then
  U850 = U850int(:,0,:)
  U700 = U700int(:,0,:)
  U500 = U500int(:,0,:)
  U300 = U300int(:,0,:)
  U200 = U200int(:,0,:)
  U100 = U100int(:,0,:)
else
  U850 = U850int(:,0,:,:)
  U700 = U700int(:,0,:,:)
  U500 = U500int(:,0,:,:)
  U300 = U300int(:,0,:,:)
  U200 = U200int(:,0,:,:)
  U100 = U100int(:,0,:,:)
end if
delete(U850int)
delete(U700int)
delete(U500int)
delete(U300int)
delete(U200int)

print("vertically interpolating V")
V850int = int2p_n_Wrap(lev,V,(/ 850. /),2,1)
V700int = int2p_n_Wrap(lev,V,(/ 700. /),2,1)
V500int = int2p_n_Wrap(lev,V,(/ 500. /),2,1)
V300int = int2p_n_Wrap(lev,V,(/ 300. /),2,1)
V200int = int2p_n_Wrap(lev,V,(/ 200. /),2,1)
V100int = int2p_n_Wrap(lev,V,(/ 100. /),2,1)
if (output .eq. "homme") then
  V850 = V850int(:,0,:)
  V700 = V700int(:,0,:)
  V500 = V500int(:,0,:)
  V300 = V300int(:,0,:)
  V200 = V200int(:,0,:)
  V100 = V100int(:,0,:)
else
  V850 = V850int(:,0,:,:)
  V700 = V700int(:,0,:,:)
  V500 = V500int(:,0,:,:)
  V300 = V300int(:,0,:,:)
  V200 = V200int(:,0,:,:)
  V100 = V100int(:,0,:,:)
end if
;V850 = rm_single_dims(V850int)
;V700 = rm_single_dims(V700int)
;V500 = rm_single_dims(V500int)
;V300 = rm_single_dims(V300int)
;V200 = rm_single_dims(V200int)
;V100 = rm_single_dims(V100int)
delete(V850int)
delete(V700int)
delete(V500int)
delete(V300int)
delete(V200int)

print("vertically interpolating T")
T850int = int2p_n_Wrap(lev,T,(/ 850. /),2,1)
T700int = int2p_n_Wrap(lev,T,(/ 700. /),2,1)
T500int = int2p_n_Wrap(lev,T,(/ 500. /),2,1)
T300int = int2p_n_Wrap(lev,T,(/ 300. /),2,1)
T200int = int2p_n_Wrap(lev,T,(/ 200. /),2,1)
T100int = int2p_n_Wrap(lev,T,(/ 100. /),2,1)
if (output .eq. "homme") then
  T850 = T850int(:,0,:)
  T700 = T700int(:,0,:)
  T500 = T500int(:,0,:)
  T300 = T300int(:,0,:)
  T200 = T200int(:,0,:)
  T100 = T100int(:,0,:)
else
  T850 = T850int(:,0,:,:)
  T700 = T700int(:,0,:,:)
  T500 = T500int(:,0,:,:)
  T300 = T300int(:,0,:,:)
  T200 = T200int(:,0,:,:)
  T100 = T100int(:,0,:,:)
end if
delete(T850int)
delete(T700int)
delete(T500int)
delete(T300int)
delete(T200int)

delete(U)
delete(V)
delete(T)

;*******************************************
; Create daily averages                              
;*******************************************
ntJump  = 4                     ; number of samples per day (24/HH)

if (output .eq. "homme") then
  U850day = U850(::ntJump,:)  ; trick: create array with meta
  U700day = U700(::ntJump,:)
  U500day = U500(::ntJump,:)
  U300day = U300(::ntJump,:)
  U200day = U200(::ntJump,:)
  U100day = U100(::ntJump,:)
  V850day = V850(::ntJump,:)  ; trick: create array with meta
  V700day = V700(::ntJump,:)
  V500day = V500(::ntJump,:)
  V300day = V300(::ntJump,:)
  V200day = V200(::ntJump,:)
  V100day = V100(::ntJump,:)
  T850day = T850(::ntJump,:)  ; trick: create array with meta
  T700day = T700(::ntJump,:)
  T500day = T500(::ntJump,:)
  T300day = T300(::ntJump,:)
  T200day = T200(::ntJump,:)
  T100day = T100(::ntJump,:)
else
  U850day = U850(::ntJump,:,:)  ; trick: create array with meta
  U700day = U700(::ntJump,:,:)
  U500day = U500(::ntJump,:,:)
  U300day = U300(::ntJump,:,:)
  U200day = U200(::ntJump,:,:)
  U100day = U100(::ntJump,:,:)
  V850day = V850(::ntJump,:,:)  ; trick: create array with meta
  V700day = V700(::ntJump,:,:)
  V500day = V500(::ntJump,:,:)
  V300day = V300(::ntJump,:,:)
  V200day = V200(::ntJump,:,:)
  V100day = V100(::ntJump,:,:)
  T850day = T850(::ntJump,:,:)  ; trick: create array with meta
  T700day = T700(::ntJump,:,:)
  T500day = T500(::ntJump,:,:)
  T300day = T300(::ntJump,:,:)
  T200day = T200(::ntJump,:,:)
  T100day = T100(::ntJump,:,:)
end if


print("entering daily averaging loop")
ntStrt  = 0
ntLast  = ntJump-1
do nt=0,NTIM-1,ntJump            ; dim_avg_n v5.1.1
  if (output .eq. "homme") then
    U850day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U850(ntStrt:ntLast,:), 0) /)  ; (/.../) ignore meta
    U700day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U700(ntStrt:ntLast,:), 0) /)
    U500day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U500(ntStrt:ntLast,:), 0) /)
    U300day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U300(ntStrt:ntLast,:), 0) /)
    U200day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U200(ntStrt:ntLast,:), 0) /)
    U100day(nt/ntJump,:) = (/ dim_avg_n_Wrap(U100(ntStrt:ntLast,:), 0) /)
    V850day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V850(ntStrt:ntLast,:), 0) /)  ; (/.../) ignore meta
    V700day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V700(ntStrt:ntLast,:), 0) /)
    V500day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V500(ntStrt:ntLast,:), 0) /)
    V300day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V300(ntStrt:ntLast,:), 0) /)
    V200day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V200(ntStrt:ntLast,:), 0) /)
    V100day(nt/ntJump,:) = (/ dim_avg_n_Wrap(V100(ntStrt:ntLast,:), 0) /)
    T850day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T850(ntStrt:ntLast,:), 0) /)  ; (/.../) ignore meta
    T700day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T700(ntStrt:ntLast,:), 0) /)
    T500day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T500(ntStrt:ntLast,:), 0) /)
    T300day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T300(ntStrt:ntLast,:), 0) /)
    T200day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T200(ntStrt:ntLast,:), 0) /)
    T100day(nt/ntJump,:) = (/ dim_avg_n_Wrap(T100(ntStrt:ntLast,:), 0) /)
  else
    U850day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U850(ntStrt:ntLast,:,:), 0) /)  ; (/.../) ignore meta
    U700day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U700(ntStrt:ntLast,:,:), 0) /)
    U500day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U500(ntStrt:ntLast,:,:), 0) /)
    U300day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U300(ntStrt:ntLast,:,:), 0) /)
    U200day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U200(ntStrt:ntLast,:,:), 0) /)
    U100day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(U100(ntStrt:ntLast,:,:), 0) /)
    V850day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V850(ntStrt:ntLast,:,:), 0) /)  ; (/.../) ignore meta
    V700day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V700(ntStrt:ntLast,:,:), 0) /)
    V500day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V500(ntStrt:ntLast,:,:), 0) /)
    V300day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V300(ntStrt:ntLast,:,:), 0) /)
    V200day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V200(ntStrt:ntLast,:,:), 0) /)
    V100day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(V100(ntStrt:ntLast,:,:), 0) /)
    T850day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T850(ntStrt:ntLast,:,:), 0) /)  ; (/.../) ignore meta
    T700day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T700(ntStrt:ntLast,:,:), 0) /)
    T500day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T500(ntStrt:ntLast,:,:), 0) /)
    T300day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T300(ntStrt:ntLast,:,:), 0) /)
    T200day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T200(ntStrt:ntLast,:,:), 0) /)
    T100day(nt/ntJump,:,:) = (/ dim_avg_n_Wrap(T100(ntStrt:ntLast,:,:), 0) /)
  end if
  ntStrt  = ntStrt+ntJump
  ntLast  = ntLast+ntJump
end do
U850day@info_tag     = "daily average"
U700day@info_tag     = "daily average"
U500day@info_tag     = "daily average"
U300day@info_tag     = "daily average"
U200day@info_tag     = "daily average"
U100day@info_tag     = "daily average"
V850day@info_tag     = "daily average"
V700day@info_tag     = "daily average"
V500day@info_tag     = "daily average"
V300day@info_tag     = "daily average"
V200day@info_tag     = "daily average"
V100day@info_tag     = "daily average"
T850day@info_tag     = "daily average"
T700day@info_tag     = "daily average"
T500day@info_tag     = "daily average"
T300day@info_tag     = "daily average"
T200day@info_tag     = "daily average"
T100day@info_tag     = "daily average"


print("writing output files")
system("mkdir -p "+outputdir)
;system("/bin/rm -f "+outputdir+"/"+grid+"_"+outputdaystr+"_"+year+month+"_UVTpreslevs.nc")   ; remove any pre-existing file
system("/bin/rm -f "+outputdir+"/"+grid+"_"+outputhourstr+"_"+year+month+"_UVTpreslevs.nc")   ; remove any pre-existing file
;dailyfile = addfile(outputdir+"/"+grid+"_"+outputdaystr+"_"+year+month+"_UVTpreslevs.nc" ,"c")  ; open output netCDF file
hourlyfile = addfile(outputdir+"/"+grid+"_"+outputhourstr+"_"+year+month+"_UVTpreslevs.nc" ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
;filedimdef(dailyfile,"time",-1,True) 
filedimdef(hourlyfile,"time",-1,True) 

; output variables directly
print("Writing daily average file")
;dailyfile->U850  = U850day
;dailyfile->U700  = U700day
;dailyfile->U500  = U500day
;dailyfile->U300  = U300day
;dailyfile->U200  = U200day
;dailyfile->U100  = U100day

;dailyfile->V850  = V850day
;dailyfile->V700  = V700day
;dailyfile->V500  = V500day
;dailyfile->V300  = V300day
;dailyfile->V200  = V200day
;dailyfile->V100  = V100day

;dailyfile->T850  = T850day
;dailyfile->T700  = T700day
;dailyfile->T500  = T500day
;dailyfile->T300  = T300day
;dailyfile->T200  = T200day
;dailyfile->T100  = T100day

print("Writing hourly file")
hourlyfile->U850  = U850
hourlyfile->U700  = U700
hourlyfile->U500  = U500
hourlyfile->U300  = U300
hourlyfile->U200  = U200
hourlyfile->U100  = U100

hourlyfile->V850  = V850
hourlyfile->V700  = V700
hourlyfile->V500  = V500
hourlyfile->V300  = V300
hourlyfile->V200  = V200
hourlyfile->V100  = V100

hourlyfile->T850  = T850
hourlyfile->T700  = T700
hourlyfile->T500  = T500
hourlyfile->T300  = T300
hourlyfile->T200  = T200
hourlyfile->T100  = T100
  
end
