;========================================================
; stuff here
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")
                          
docnfilename="/glade/p/work/zarzycki/slab/docn_files/climo_1x1_slab_exp003.nc"
docnfile=addfile(docnfilename,"r")

dlat=docnfile->yc
dlon=docnfile->xc
hn_d=docnfile->hblt(0,:,:)
delta_d=docnfile->qdp(:,:,:)

print("Daily interpolation...")
delta_d_daily=clmMon2clmDay(delta_d,0,0)
print("... done daily interpolation.")

natfile=addfile("/glade/u/home/zarzycki/work/slab/SSTclimo/nhemi_30_x4.cam.SSTclimo.0000-08-21-00000.nc","r")
hlon=natfile->lon
hlat=natfile->lat

;hn_single = linint2_Wrap(dlon,dlat,hn_nat,False,hlon,hlat,0)
;hn = conform_dims(dimsizes(u10), hn_single, (/1,2/)) 
;copy_VarCoords(u10,hn)

print("LL to SE interp...")
hn_n = linint2_points_Wrap (dlon,dlat,hn_d,True,hlon,hlat, 0)
delta_n = linint2_points_Wrap (dlon,dlat,delta_d_daily,True,hlon,hlat, 0)
print("...done LL to SE interp.")

printVarSummary(hn_n)
printVarSummary(delta_n)

hn_n!0="ncol"
delta_n!0="time"
delta_n!1="ncol"

oldtime=delta_n&time
print(oldtime)
oldtime@units="days since 1200-12-31 00:00:00"
newtime=new(dimsizes(delta_n&time),"double")
newtime@units="days since 1201-05-01 00:00:00"

printVarSummary(oldtime)
printVarSummary(newtime)

newtime = cd_convert( oldtime, newtime@units )

testtime=cd_calendar(newtime,-3)

delete(delta_n&time)
delta_n&time=newtime


printVarSummary(hn_n)
printVarSummary(delta_n)

delete(hn_n@xcoord)
delete(hn_n@ycoord)
delete(delta_n@xcoord)
delete(delta_n@ycoord)

if (0.eq.1) then
wks = gsn_open_wks("x11","homme")               ; open workstation
gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap

res                     = True         ; plot modifications desired
res@gsnSpreadColors     = True         ; Use full colormap, but start

res@sfXArray            = hlon        ; Required to tell NCL where to
res@sfYArray            = hlat        ; overlay data on globe.

res@cnFillOn            = True         ; Turn on contour fill

res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels

res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;map = gsn_csm_contour_map_ce(wks,delta_n(20,:),res)

end if

system("/bin/rm -f simple-slab-remapped.nc")   ; remove any pre-existing file
ncdf = addfile("simple-slab-remapped.nc" ,"c")  ; open output netCDF file

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
ncdf->deltaT  = delta_n            
ncdf->hn = hn_n
ncdf->lat = hlat
ncdf->lon = hlon

exit

ORO!0    = "lat"                      ; assign named dimensions
ORO!1    = "lon"

ORO&lat  = T&lat                      ; copy lat from T to ORO
ORO&lon  = T&lon 

ORO@long_name = "orography"           ; assign attributes 
ORO@units     = "m"

ncdf->TOPOGRAPHY = ORO                ; name on file different from name in code



wallClockElapseTime(wcStrt, "Time to complete script", 0)

end
