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
;traj_filename = "cat_traj_slab_8day.txt"
traj_filename = "traj_slab_short.txt"
out_type = "x11"

offset = 1.0   ; offset is days following passage

plot_refs=True

minWind = 32.0
maxWind = 1000.0

maxAllowAnom = 10.0     ; maximum allowable anomaly
latBox = 1.0           ; size of box surrounding cyclone center to calc anom

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

;offsetArr    = (/-0.75,-0.5,-0.25,0.0,2.0,5.0,12.0/)
offsetArr = fspan(-500.0, 500.0, 81)
print(offsetArr)

SSTanom = new((/dimsizes(offsetArr),nstorms,ntimes/),"float")
SSTanom = SSTanom@_FillValue

;----------------Universal calcs-----------------------------------



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
      if (dist .lt. 25*6*3600) then
        v = dist / (6.*3600.)
        lat2rad = lat*pi/180.
        f = 2*omega*sin(lat2rad)
        voverf(j,i) = v/f/100000
      end if

      traj_bearing(j,i) = bearing(traj_lat(j,i-1),traj_lon(j,i-1),traj_lat(j,i),traj_lon(j,i))

      bearLeft=traj_bearing(j,i)-90.
      bearRight=traj_bearing(j,i)+90.
      if (bearLeft .lt. 0.0) then
        bearLeft = bearLeft+360.
      end if
      if (bearRight .gt. 360.0) then
        bearRight = bearRight-360.
      end if

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
        do z = 0,dimsizes(offsetArr)-1
          offsetDist=offsetArr(z)
          if (offsetDist .gt. 0)
            ; use right bearing
            thisBear = bearRight
          else
            thisBear = bearLeft
            offsetDist = -offsetDist ; need to flip offsetDist to go correction direction
          end if
          loc2 = LLfromDistBear(lat,lon,thisBear,offsetDist)
          offLat=loc2(0)
          offLon=loc2(1)
          ;print(offLat+" "+offLon)
          if (offLat .ge. 0.125 .and. offLat .le. 59.875 .and. offLon .ge. 95.125 .and. offLon .le. 354.875) then ; NEED THIS CHECK TO SEE IF IN DOMAIN
            SSTanom(z,j,i) = SSTfile->SST({trackoffset},{offLat},{offLon})
            if(abs(SSTanom(z,j,i)) .ge. maxAllowAnom)
              SSTanom(z,j,i) = SSTanom@_FillValue
            end if
          end if

        end do
      end if  
    end if

  end if ; check for missing
end do
end do

SSTanom_slow=SSTanom
SSTanom_fast=SSTanom
do z = 0,dimsizes(offsetArr)-1
  SSTanom_slow(z,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .lt. 1.0,SSTanom(z,:,:),SSTanom@_FillValue)
  SSTanom_fast(z,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .gt. 1.0,SSTanom(z,:,:),SSTanom@_FillValue)
end do

profile=new((/3,dimsizes(offsetArr)/),"float")

profile(0,:)=dim_avg_n_Wrap(dim_avg_n_Wrap(SSTanom_slow,2),1)
profile(1,:)=dim_avg_n_Wrap(dim_avg_n_Wrap(SSTanom_fast,2),1)
profile(2,:)=dim_avg_n_Wrap(dim_avg_n_Wrap(SSTanom,2),1)

;======================================================================================

ncol = 2
data_as = readAsciiTable("data_MP13_Fig3a_all.txt", ncol, "float", 0)

;======================================================================================

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

