;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

fils = systemfunc ("ls /glade2/collections/rda/data/ds526.0/gridded/NorAm.199*.nc /glade2/collections/rda/data/ds526.0/gridded/NorAm.200{0..5}*.nc") ; file paths
;fils = systemfunc ("ls /glade2/collections/rda/data/ds526.0/gridded/NorAm.199*.nc /glade2/collections/rda/data/ds526.0/gridded/NorAm.198*.nc") ; file paths
;fils = systemfunc ("ls /glade2/collections/rda/data/ds526.0/gridded/NorAm.19*.nc") ; file paths

nyrs = dimsizes(fils)
print(nyrs)
f1   = addfiles (fils, "r")   
ListSetType (f1, "cat")        ; concatenate (=default)
;fname="./NorAm.1993.daily.SNOW.gridded.nc"
;f1=addfile(fname,"r")

flat=f1[0]->lat
flon=f1[0]->lon
fsnow=f1[:]->snow
ftime=f1[:]->time

fsnow_sum = dim_sum_n_Wrap(fsnow,0)
fsnow_sum = fsnow_sum/tofloat(nyrs)
fsnow_sum = fsnow_sum * 0.393701 / 10. ; cm to inches

;=================== Create grid ==================================

gridsize=1.

latS = min(flat)-1.
latN = max(flat)+1.
lonW = min(flon)-1.
lonE = max(flon)+1.

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

count     = new( (/nlat,mlon/), "float", 1e20)
count!0   = "lat"
count!1   = "lon"
count&lat =  lat
count&lon =  lon

printVarSummary(count)

;=================== Count data ==================================

do zz = 0,dimsizes(flat)-1
  thisLat=flat(zz)
  thisLon=flon(zz)
  count({thisLat},{thisLon})=(/fsnow_sum(zz)/)
end do

 system("/bin/rm -f NorAm.ANNMEAN.daily.SNOW.gridded.nc")   ; remove any pre-existing file
       ncdf = addfile("NorAm.ANNMEAN.daily.SNOW.gridded.nc" ,"c")  ; open output netCDF file

    ;===================================================================
    ; create global attributes of the file (optional)
    ;===================================================================
       fAtt               = True            ; assign file attributes
       fAtt@title         = "NCL Simple Approach to netCDF Creation"
       fAtt@source_file   =  "original-file.nc"
       fAtt@Conventions   = "None"
       fAtt@creation_date = systemfunc ("date")
       fileattdef( ncdf, fAtt )            ; copy file attributes

    ;===================================================================
    ; make time an UNLIMITED dimension; recommended  for most applications
    ;===================================================================
       filedimdef(ncdf,"time",-1,True) 

    ;===================================================================
    ; output variables directly; NCL will call appropriate functions
    ; to write the meta data associated with each variable
    ;===================================================================
       ncdf->SNOW=count


end


