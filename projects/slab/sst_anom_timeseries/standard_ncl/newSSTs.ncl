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

plot_only = False
plot_file="/glade/p/work/zarzycki/slab/ncl/CX-traj_slab.txt_CATTED.nc"

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
;traj_filename = "cat_traj_slab_08_11.75_900.txt"
traj_filename = "cat_traj_slab3_900.txt"
out_type = "pdf"

if (.not. isdefined("minWind"))
  minWind=0.0
end if
if (.not. isdefined("maxWind"))
  maxWind=999.0
end if

latBoxArr=(/0.25,1.0,3.6,5.0/)

print("Using minwind: "+minWind+"   maxwind: "+maxWind)

maxAllowAnom = 10.0     ; maximum allowable anomaly

filehead="nhemi_30_x4_slab3"
filestrg="h7"
filetail="nc_regrid.nc"

if (plot_only .eq. False)
  outFileName="/glade/p/work/zarzycki/slab/ncl/SST-"+traj_filename+"__"+sprinti("%06d",stIx)+"_"+sprinti("%06d",enIx)+".nc"
end if

if (plot_only)
  if (isdefined("plot_file"))
    outFileName=plot_file
  end if
  f=addfile(outFileName,"r")
  SSTanom=f->SSTanom
  traj_wind=f->traj_10m_wind
  voverf=f->voverf
else ; do everything else

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

thefile=traj_dir+traj_filename
ncols = 12                     ; assign number of columns
maxLines = -1
traj_data = getTrajectories(thefile,ncols,maxLines)

traj_lon = traj_data(stIx:enIx,3,:)
traj_lat = traj_data(stIx:enIx,4,:)
traj_wind = traj_data(stIx:enIx,5,:)*factor
traj_pres = traj_data(stIx:enIx,7,:)/100.
traj_yyyy = traj_data(stIx:enIx,8,:)
traj_mm = traj_data(stIx:enIx,9,:)
traj_dd = traj_data(stIx:enIx,10,:) 
traj_hh = traj_data(stIx:enIx,11,:)

ndims = dimsizes(traj_lon)
;nstorms = ndims(0)
nstorms = toint((enIx-stIx)+1)
;storm_index=ispan(0,nstorms-1,1)
storm_index=ispan(stIx,enIx,1)
ntimes = ndims(1)

;--------------------------------------------------------

voverf = traj_lon
voverf = 1.0

traj_bearing = traj_lon
traj_bearing = traj_bearing@_FillValue

traj_speed = traj_lon
traj_speed = traj_speed@_FillValue

;offsetArr    = (/-12.0,-5.0,-2.0,0.0,2.0,5.0,12.0/)
;offsetArr = fspan(-20, 20, 41)
offsetArr = fspan(-20, 40, 61)
print(offsetArr)

SSTanom = new((/dimsizes(latBoxArr),dimsizes(offsetArr),nstorms,ntimes/),"float")
SSTanom = SSTanom@_FillValue

storm_times=new((/nstorms,ntimes/),"float")
storm_times = storm_times@_FillValue
storm_times@units="days since 0001-01-01 00:00"

;----------------Universal calcs-----------------------------------

latBoxHalfArr = latBoxArr/2.0

;----------------Loop-----------------------------------

do j = 0,nstorms-1
print(" Storm #"+(j+1)+" of "+nstorms)
do i = 0,ntimes-1   ; need to start at 1 for heading calculation
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
    
    tracktime   = cd_inv_calendar(yyyy,mm,dd,hh,0,0,units,0)
    storm_times(j,i) = tofloat( cd_convert(tracktime,storm_times@units) )

      if (i .gt. 0) then
        dist = gc_latlon(traj_lat(j,i),traj_lon(j,i),traj_lat(j,i-1),traj_lon(j,i-1),2,3)
				if (dist .lt. 25*6*3600) then
					v = dist / (6.*3600.)
					traj_speed(j,i) = v
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
      end if

		do k = 0,dimsizes(offsetArr)-1
			offset = offsetArr(k)
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
        do y = 0,dimsizes(latBoxArr)-1
          latBoxHalf=latBoxHalfArr(y)
          SSTanom(y,k,j,i) = avg(SSTfile->SST({trackoffset},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
          if(abs(SSTanom(y,k,j,i)) .ge. maxAllowAnom)
            SSTanom(y,k,j,i) = SSTanom@_FillValue
          end if
        end do ;  y loop
			end if
		
		end do ; k loop
  end if ; check for missing
end do
end do

; ========= OUTPUT FILE ==============================================

system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "Spatial SSTanom profile as function of time"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

SSTanom!0="latbox"
SSTanom!1="time"
SSTanom!2="storm"
SSTanom!3="stormtime"
SSTanom&latbox = latBoxArr
SSTanom&time = offsetArr
SSTanom&storm = storm_index
SSTanom@long_name = "SST anomaly"
ncdf->SSTanom  = SSTanom     

storm_times!0="storm"
storm_times!1="stormtime"
storm_times&storm = storm_index
ncdf->storm_times = storm_times

copy_VarCoords(storm_times,traj_lat)
traj_lat@long_name = "Latitude"
traj_lat@units = "degrees north"
ncdf->traj_lat=traj_lat

copy_VarCoords(storm_times,traj_lon)
traj_lon@long_name = "Longitude"
traj_lon@units = "degrees east"
ncdf->traj_lon=traj_lon

copy_VarCoords(storm_times,traj_bearing)
traj_bearing@long_name = "Storm bearing"
traj_bearing@units = "degrees"
ncdf->traj_bearing = traj_bearing

copy_VarCoords(storm_times,traj_speed)
traj_speed@long_name = "Translational speed"
traj_speed@units = "m/s"
ncdf->traj_speed = traj_speed

copy_VarCoords(storm_times,voverf)
voverf@long_name = "V over F"
voverf@units = ""
ncdf->voverf = voverf

copy_VarCoords(storm_times,traj_wind)
traj_wind@long_name = "10-m wind"
traj_wind@units = "m/s"
ncdf->traj_10m_wind = traj_wind

copy_VarCoords(storm_times,traj_pres)
traj_pres@long_name = "Sea level pressure"
traj_pres@units = "hPa"
ncdf->traj_pres = traj_pres

copy_VarCoords(storm_times,traj_yyyy)
ncdf->traj_yyyy = traj_yyyy

copy_VarCoords(storm_times,traj_mm)
ncdf->traj_mm = traj_mm

copy_VarCoords(storm_times,traj_dd)
ncdf->traj_dd = traj_dd

copy_VarCoords(storm_times,traj_hh)
ncdf->traj_hh = traj_hh
;======================================================================================

end if

exit

SSTanom_all=SSTanom
SSTanom_slow=SSTanom
SSTanom_fast=SSTanom
SSTanom_td=SSTanom
SSTanom_ts=SSTanom
SSTanom_c1=SSTanom
SSTanom_c2=SSTanom
SSTanom_c3=SSTanom
SSTanom_c4=SSTanom
SSTanom_c5=SSTanom

do j = 0,dimsizes(SSTanom&time)-1
  SSTanom_all(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_slow(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .lt. 1.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_fast(j,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .gt. 1.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_td(j,:,:) = where(traj_wind .ge. 000.0 .and. traj_wind .lt. 017.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_ts(j,:,:) = where(traj_wind .ge. 017.0 .and. traj_wind .lt. 032.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c1(j,:,:) = where(traj_wind .ge. 032.0 .and. traj_wind .lt. 042.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c2(j,:,:) = where(traj_wind .ge. 042.0 .and. traj_wind .lt. 049.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c3(j,:,:) = where(traj_wind .ge. 049.0 .and. traj_wind .lt. 058.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c4(j,:,:) = where(traj_wind .ge. 058.0 .and. traj_wind .lt. 070.0,SSTanom(j,:,:),SSTanom@_FillValue)
  SSTanom_c5(j,:,:) = where(traj_wind .ge. 070.0                           ,SSTanom(j,:,:),SSTanom@_FillValue)
end do

maxSSTanom = new(7,"float")
maxSSTanom(0)=min(dim_avg_n_Wrap(SSTanom_td,(/1,2/)))
maxSSTanom(1)=min(dim_avg_n_Wrap(SSTanom_ts,(/1,2/)))
maxSSTanom(2)=min(dim_avg_n_Wrap(SSTanom_c1,(/1,2/)))
maxSSTanom(3)=min(dim_avg_n_Wrap(SSTanom_c2,(/1,2/)))
maxSSTanom(4)=min(dim_avg_n_Wrap(SSTanom_c3,(/1,2/)))
maxSSTanom(5)=min(dim_avg_n_Wrap(SSTanom_c4,(/1,2/)))
maxSSTanom(6)=min(dim_avg_n_Wrap(SSTanom_c5,(/1,2/)))

print(maxSSTanom)

print("num fast moving points: "+num(SSTanom_fast(0,:,:)))
avgSSTfast=dim_avg_n_Wrap(SSTanom_fast,(/1,2/))
print(avgSSTfast)

print("num slow moving points: "+num(SSTanom_slow(0,:,:)))
avgSSTslow=dim_avg_n_Wrap(SSTanom_slow,(/1,2/))
print(avgSSTslow)

print("all points: "+num(SSTanom_all(0,:,:)))
avgSSTall=dim_avg_n_Wrap(SSTanom_all,(/1,2/))
print(avgSSTall)

asciiwrite("text/maxSSTanom_.txt",maxSSTanom)

;======================================================================================

; GET DATA
ncol = 2
data_as = readAsciiTable("lvas.txt", ncol, "float", 0)
data_c1 = readAsciiTable("lvc1.txt", ncol, "float", 0)
data_c2 = readAsciiTable("lvc2.txt", ncol, "float", 0)
data_c3 = readAsciiTable("lvc3.txt", ncol, "float", 0)
data_c4 = readAsciiTable("lvc4.txt", ncol, "float", 0)
data_c5 = readAsciiTable("lvc5.txt", ncol, "float", 0)

do zz = 0,2

if (zz .eq. 0) then
  speed="slow"
  avgSSTvTIME=avgSSTslow
  plot_refs=True
else if (zz .eq. 1) then
  speed="fast"
  avgSSTvTIME=avgSSTfast
  plot_refs=False
else
  speed="all"
  avgSSTvTIME=avgSSTall
  plot_refs=False
end if
end if

wks   = gsn_open_wks ("pdf","SSTvTIME_"+speed+"_"+minWind+"_"+maxWind)

res                   = True
res@gsnMaximize      = True
res@gsnPaperOrientation = "portrait"
res@gsnDraw          = False
res@gsnFrame         = False
res@tiMainString      = "SST rel. to TC passage; slab1; "+speed+" "+minWind+"_"+maxWind+" m/s"

;res@xyLineColor      = "blue"
res@tiXAxisString = "Time relative to passage (days)"
res@tiYAxisString = "SST anom. (K)"

res@trYMinF = min((/-2.0,min(avgSSTslow)/))-0.25
res@trYMaxF = 0.5
res@trXMinF = -20
res@trXMaxF = 20

res@xyLineThicknessF = 6.0
res@xyLineColor     = "blue"
plot = gsn_csm_xy(wks,offsetArr,avgSSTvTIME,res)

if(plot_refs)
  res@xyLineThicknessF = 1.25

  res@xyLineColor      = "magenta4"
  plot1  = gsn_csm_xy (wks,data_c1(:,0),data_c1(:,1),res) ; create plot
  overlay(plot,plot1)

  res@xyLineColor      = "magenta3"
  plotc2  = gsn_csm_xy (wks,data_c2(:,0),data_c2(:,1),res) ; create plot
  overlay(plot,plotc2)

  res@xyLineColor      = "magenta2"
  plotc3  = gsn_csm_xy (wks,data_c3(:,0),data_c3(:,1),res) ; create plot
  overlay(plot,plotc3)

  res@xyLineColor      = "magenta1"
  plotc4  = gsn_csm_xy (wks,data_c4(:,0),data_c4(:,1),res) ; create plot
  overlay(plot,plotc4)

  res@xyLineColor      = "magenta"
  plotc5  = gsn_csm_xy (wks,data_c5(:,0),data_c5(:,1),res) ; create plot
  overlay(plot,plotc5)

  res@xyLineColor      = "magenta"
  ;plotas  = gsn_csm_xy (wks,data_as(:,0),data_as(:,1),res) ; create plot
  ;overlay(plot,plotas)
end if

zlineres = True
zlineres@gsLineColor = "gray90"
zlineres@gsLineThicknessF = 4.0
zlineres@tfPolyDrawOrder = "Draw" ;Force polylines to be behind plot
dummy_horiz = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0,0/),zlineres)
dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

;***********************************************
; legend resources
;***********************************************

lgres                    = True

lgres@lgMonoDashIndex = False
lgres@lgMonoLineThickness = False
lgres@lgItemType         = "Lines"
if(plot_refs)
  labelStr=(/"LV2011","This study"/)
  lgres@lgLineColors     = (/"magenta1","blue"/)
  lgres@lgLineThicknesses   = (/1.25,6.0/)
  lgres@lgDashIndexes = (/0,0/)
else
  labelStr=(/"This study"/)
  lgres@lgLineColors     = (/"blue"/)
  lgres@lgLineThicknesses   = (/6.0/)
  lgres@lgDashIndexes = (/0/)
end if
lgres@lgLabelFontHeightF = .08            ; set the legend label font thickness
lgres@vpWidthF           = 0.15           ; width of legend (NDC)
lgres@vpHeightF          = 0.1            ; height of legend (NDC)
lgres@lgPerimColor       = "Black"       ; draw the box perimeter in orange
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lbid = gsn_create_legend(wks,dimsizes(labelStr),labelStr,lgres)

amres = True
amres@amParallelPosF   = 0.35		    ; move legend to the right
amres@amOrthogonalPosF = 0.30             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

draw(plot)
frame(wks)

delete(plot)
delete(lgres)
delete(res)
delete(amres)
delete(dummy_horiz)
delete(dummy_vert)
delete(zlineres)
delete(wks)
delete(labelStr)

end do


;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

