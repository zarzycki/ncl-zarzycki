load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

debug=False

if (debug) then
ncols=360
nrows=143
xllcorner=-180
yllcorner=-58
cellsize=1.0
NODATA_value=-9999
data = readAsciiTable("glp00g60.asc", ncols, "float", 6)
else
ncols=8640
nrows=3432
xllcorner=-180
yllcorner=-58
cellsize=0.0416666666667
NODATA_value=-9999
data = readAsciiTable("glp00g.asc", ncols, "float", 6)
end if

;print(data)

;ncols         360
;nrows         143
;xllcorner     -180
;yllcorner     -58
;cellsize      1.0000000000008
;NODATA_value  -9999

mlon = ncols
lon  = lonGlobeF(mlon, "lon", "longitude", "degrees_east")
lon = (/ lon - 180. /)  ; subtract 180 from all values 
lon&lon = lon           ; update coordinates

ytlcorner=yllcorner+cellsize*nrows-1
print(ytlcorner)
lat = fspan(ytlcorner, yllcorner, nrows)
lat@units="degrees_north"
lat!0="lat"
lat&lat=lat

data!0="lat"
data!1="lon"
data&lat=lat
data&lon=lon

nglat = toint(180/cellsize)
glat = fspan(90, -90, nglat + 1)
glat@units="degrees_north"
glat!0="glat"
glat&glat=glat


gdata = new((/nglat+1,mlon/),"float")
gdata =0

stinx = get1Dindex(glat,ytlcorner)
eninx = stinx+(dimsizes(lat)-1)
gdata(stinx:eninx,:)=data

gdata!0="lat"
gdata!1="lon"
gdata&lat=glat
gdata&lon=lon


wks = gsn_open_wks("pdf","pop")

setvalues NhlGetWorkspaceObjectId() 
  "wsMaximumSize": 10000000000 
end setvalues 

gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")

res = True
;res@gsnDraw         = False                   ; don't draw yet
;res@gsnFrame        = False                   ; don't advance frame yet
res@cnFillOn        = True                    ; turn on color
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels

res@mpMinLatF             = 10
res@mpMaxLatF             = 50 
;res@mpMinLonF             = -100
;res@mpMaxLonF             = -40

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 0.			; set the minimum contour level
res@cnMaxLevelValF  = 30000.			; set the maximum contour level
res@cnLevelSpacingF = 1000.			; set the interval between contours

plot = gsn_csm_contour_map_ce(wks,gdata({50:10},:),res)

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf     = addfile("simple.nc" ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->POP  = gdata


end
