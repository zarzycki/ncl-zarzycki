;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "getTrajectories.ncl"
;========================================================
begin

output_type="pdf"

thefile="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/traj_fixedSST_1201.txt"
ncols = 12                     ; assign number of columns
maxLines = -1
traj_data = getTrajectories(thefile,ncols,maxLines)

; You may have to change these depending on which rows your lon/lat are in
lon = traj_data(:,3,:)
lat = traj_data(:,4,:)

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks(output_type,"traj_plotted")
map = new(1,graphic)
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
 
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
polyres               = True          ; poly marker mods desired 
polyres@gsMarkerIndex = 1            ; choose circle as polymarker
lineres = True
  
dum = new((/nstorms,ntimes/),graphic)

do i = 0,nstorms-1
do j = 0,ntimes-1
  
txres               = True                            
txres@txFontHeightF = 0.01             ; Set the font height

if (j .ne. 0) then
  if (.not.ismissing(lon(i,j))) then
    dum(i,j) = gsn_add_polyline(wks,map,(/lon(i,j),lon(i,j-1)/),(/lat(i,j),lat(i,j-1)/),lineres)
  end if
end if
  
end do
end do
  
print("Drawing plot")
resP = True
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end
