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

;year=1980
;month="01"
;grid="ne30"

outputdir="/glade/scratch/zarzycki/AMIPmonthly/"+year+"/"
;outputdir="/glade/scratch/zarzycki/"+year+"/"
outputdaystr="daily"

if (grid .eq. "ne30") then
  output = "homme"
else
  output = "latlon"
end if

;========================
; get list of all files and open as "one big file"
;========================     
all_files = systemfunc ("ls /glade/scratch/zarzycki/"+grid+"amip/"+year+"/*.cam.h0."+year+"-"+month+"*")
;all_files = systemfunc ("ls /glade/scratch/zarzycki/"+grid+"amip/"+year+"/*.cam.h3."+year+"-"+month+"-01*")
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
;========================
; choose how files are combined and read in variable across files
;========================  
ListSetType (fall, "cat")             ; concatenate or "merge" (default)

lev = fall[0]->lev    ; Only get the first lev otherwise it's just time x nlev
time = fall[:]->time
NTIM = dimsizes(time)

print("Getting PRECT")
PRECT = fall[:]->PRECT
print("Getting PRECL")
PRECL = fall[:]->PRECL
print("Getting PRECC")
PRECC = fall[:]->PRECC
print("Getting FLUT")
FLUT = fall[:]->FLUT
print("Getting CLDTOT")
CLDTOT = fall[:]->CLDTOT
print("Getting LHFLX")
LHFLX = fall[:]->LHFLX
print("Getting SHFLX")
SHFLX = fall[:]->SHFLX

;*******************************************
; Create daily averages                              
;*******************************************

dailyfile = addfile(outputdir+"/"+grid+"_"+outputdaystr+"_"+year+month+"_UVTpreslevs.nc" ,"w")  ; open output netCDF file

; output variables directly
print("Writing daily average file")
dailyfile->PRECT  = PRECT
dailyfile->PRECL  = PRECL
dailyfile->PRECC  = PRECC
dailyfile->CLDTOT  = CLDTOT
dailyfile->FLUT  = FLUT
dailyfile->LHFLX  = LHFLX
dailyfile->SHFLX  = SHFLX

  
end
