;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bearing.ncl"
load "/glade/u/home/zarzycki/ncl/functions/LLfromDistBear.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

;---------------User settings----------------------------

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
traj_filename = "cat_traj_slab_08_4.7_900.txt"
;traj_filename = "traj_slab_1220.txt"
out_type = "x11"

offset = 1.0   ; offset is days following passage

plot_refs=True

minWind = 32.0
maxWind = 1000.0

maxAllowAnom = 10.0     ; maximum allowable anomaly
latBox = 5.0           ; size of box surrounding cyclone center to calc anom

filehead="nhemi_30_x4_slab"
filestrg="h7"
filetail="nc_regrid.nc"

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

thefile=traj_dir+traj_filename
ncols = 12                     ; assign number of columns
maxLines = 150
traj_data = getTrajectories(thefile,ncols,maxLines)

traj_lon = traj_data(:,3,:)
traj_lat = traj_data(:,4,:)
traj_wind = traj_data(:,5,:)*factor
traj_pres = traj_data(:,7,:)/100.
traj_yyyy = traj_data(:,8,:)
traj_mm = traj_data(:,9,:)
traj_dd = traj_data(:,10,:) 
traj_hh = traj_data(:,11,:)

ndims = dimsizes(traj_lon)
nstorms = ndims(0)
ntimes = ndims(1)

;--------------------------------------------------------

voverf = traj_lon
voverf = voverf@_FillValue

traj_bearing = traj_lon
traj_bearing = traj_bearing@_FillValue

traj_velo = traj_lon
traj_velo = traj_velo@_FillValue

SSTanom = new((/nstorms,ntimes/),"float")
SSTanom = SSTanom@_FillValue

;----------------Universal calcs-----------------------------------

latBoxHalf = latBox/2.0

;----------------Loop-----------------------------------

do j = 0,nstorms-1
print("Doing storm #"+(j+1)+" of "+nstorms)
do i = 1,ntimes-1   ; need to start at 1 for heading calculation
  if .not.ismissing(traj_yyyy(j,i)) then
    thisYear=traj_yyyy(j,i)
    SSTdir="/glade/u/home/zarzycki/scratch/"+filehead+"/run/"+thisYear+"/"
    units="days since "+thisYear+"-05-01 00:00:00"

    yyyy=toint(traj_yyyy(j,i))
    mm=toint(traj_mm(j,i))
    dd=toint(traj_dd(j,i))
    hh=toint(traj_hh(j,i))
    sssss=hh*3600

    lat=traj_lat(j,i)
    lon=traj_lon(j,i)
    wind=traj_wind(j,i)
    pres=traj_pres(j,i)

    mindate   = cd_inv_calendar(yyyy,05,01,00,0,0,units,0)
    maxdate   = cd_inv_calendar(yyyy,11,30,18,0,0,units,0)

    if (i .gt. 0) then
      dist = gc_latlon(traj_lat(j,i),traj_lon(j,i),traj_lat(j,i-1),traj_lon(j,i-1),2,3)
      
      traj_velo(j,i) = dist / (6.*3600.)
      traj_bearing(j,i) = bearing(traj_lat(j,i-1),traj_lon(j,i-1),traj_lat(j,i),traj_lon(j,i))

      tracktime   = cd_inv_calendar(yyyy,mm,dd,hh,0,0,units,0)
      trackoffset = tracktime
      trackoffset = tracktime+offset

      offsettime=cd_calendar(trackoffset,0)
      offyyyy = tointeger(offsettime(:,0)) 
      offmm = tointeger(offsettime(:,1)) 
      offdd = tointeger(offsettime(:,2)) 
      offhh = tointeger(offsettime(:,3)) 

      if(trackoffset .ge. mindate .and. trackoffset .le. maxdate)
        SSTfilename=SSTdir+"/"+filehead+".cam."+filestrg+"."+sprinti("%0.4i",offyyyy)+"-"+sprinti("%0.2i",offmm)+"-"+sprinti("%0.2i",offdd)+"-"+"00000"+"."+filetail
        SSTfile = addfile(SSTfilename,"r")
				SSTanom(j,i) = avg(SSTfile->SST({trackoffset},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
				if(abs(SSTanom(j,i)) .ge. maxAllowAnom)
					SSTanom(j,i) = SSTanom@_FillValue
				end if
      end if  
    end if

  end if ; check for missing
end do
end do

SSTanom=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SSTanom,SSTanom@_FillValue)


strat_by_speed=fspan(0.0,15.0,16)
SST_by_speed = new((/dimsizes(strat_by_speed)-1,nstorms,ntimes/),"float")
SST_by_speed = SST_by_speed@_FillValue

do k = 0,dimsizes(strat_by_speed)-2
  SST_by_speed(k,:,:)=where(traj_velo .ge. strat_by_speed(k) .and. traj_velo .lt. strat_by_speed(k+1) ,SSTanom,SSTanom@_FillValue)
end do

print(dim_avg_Wrap(dim_avg_Wrap(SST_by_speed)))

exit

wks   = gsn_open_wks (out_type,"cx-cooling")

; GET DATA

res                   = True
res@gsnMaximize      = True
res@gsnPaperOrientation = "portrait"
res@gsnDraw          = False
res@gsnFrame         = False

res@tiMainString = "Cross-track SST; +2days; slab1"
res@tiXAxisString = "Radius (km)"
res@tiYAxisString = "SST anom. (K)"

res@xyLineThicknesses = (/3.0,3.0,3.0/)               ; make 2nd lines thicker
res@xyLineColors      = (/"blue","red","black"/)          ; change line color
res@xyDashPatterns = (/0,0,0/)
res@lgPerimFill            = "SolidFill"      ; Fill legend box w/white
res@lgPerimFillColor       = "white"          ; so it masks XY curves
res@xyExplicitLegendLabels = (/"v/f < 1 (slow)","v/f > 1 (fast)","all"/)

res@lgItemOrder  = (/ 2,1,0 /)   ; Reorder the legends
res@pmLegendOrthogonalPosF = -0.45            ; Move legend inside plot
res@pmLegendParallelPosF   =  0.8             ; Move legend to right
res@pmLegendWidthF         = 0.15             ; Change width and height
res@pmLegendHeightF        = 0.12
res@pmLegendDisplayMode    = "Always"    ; Turn legend back on
res@lgTitleFontHeightF = .05
res@lgBoxMinorExtentF      = 0.15       ; Shorten the legend lines

;res@trYMinF = min((/-2.0,min(avgSSTslow)/))-0.25
;res@trYMaxF = 0.5
;res@trXMinF = -20
;res@trXMaxF = 2
res@trYMinF = -2.5

plot  = gsn_csm_xy (wks,offsetArr,profile,res)

if(plot_refs)
  res@xyLineThicknessF = 1.25
  res@xyLineColor      = "gray"
  plot1  = gsn_csm_xy (wks,data_as(:,0)*100,data_as(:,1),res) ; create plot
  overlay(plot,plot1)
end if

zlineres = True
zlineres@gsLineColor = "gray"
zlineres@gsLineThicknessF = 4.0
zlineres@tfPolyDrawOrder = "Draw" ;Force polylines to be behind plot
dummy_horiz = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0,0/),zlineres)
dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

draw(plot)
frame(wks)

;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

