; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

wcStrtRemap = systemfunc("date")

filename = "/glade/p/cesmdata/inputdata/atm/cam/topo/USGS_gtopo30_0.47x0.63_smooth2000-100_ne60np4_c061106.nc"
thefile = addfile(filename,"r")

dstGridFileName="/glade/u/home/zarzycki/scratch/cam5_work/toposmooth_tensorHV/camrun.cam.h0.0000-09-01-00000.nc"
dstGridFile=addfile(dstGridFileName,"r")

selat = thefile->lat
selon = thefile->lon
sevar = thefile->PHIS(:)

whatRes=0.5

;plat=dstGridFile->lat
;plon=dstGridFile->lon

nx = toint(180./whatRes)+1
ny = toint(360./whatRes)
plat =  90.*fspan(-1.,1.,nx)
plon = 360.*fspan(0.,1.,ny)
plat@units="degrees_north"
plon@units="degrees_east"

var_int = dsgrid2(selat,selon,sevar,plat,plon)

printVarSummary(var_int)

wallClockElapseTime(wcStrtRemap, "Graphics", 0)

; wks  = gsn_open_wks("x11","coneff")
; 
; res                 = True
; res@gsnMaximize     = True       ; maximize in frame
; res@cnLinesOn       = False
; res@cnFillOn        = True
; res@cnFillPalette   = "BlueYellowRed"   ; change the color palette
; res@tiMainString    = "Color contours mask filled land"
; res@mpMinLonF            =  60.               ; select a subregion
; res@mpMaxLonF            =  120.               ; select a subregion
; res@mpMinLatF            =  10.              ; select a subregion
; res@mpMaxLatF            =  45.               ; select a subregion
; 
; plot = gsn_csm_contour_map(wks,var_int,res)

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

var_int!0    = "lat"
var_int!1    = "lon"
var_int&lat  = plat
var_int&lon  = plon
var_int@long_name = "Surface geopotential"
var_int@units     = "m2/s2"
ncdf->PHIS  = var_int
  
end

