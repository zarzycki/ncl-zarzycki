;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
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

plot_only=True
plot_file="/glade/p/work/zarzycki/slab/ncl/CX-traj_slab.txt_CATTED.nc"

;stIx=0
;enIx=1

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
traj_filename = "cat_traj_slab_08_4.7_900.txt"
;traj_filename = "traj_slab_1201.txt"
out_type = "pdf"

if (plot_only .eq. False)
  outFileName="/glade/p/work/zarzycki/slab/ncl/CX-"+traj_filename+"__"+sprinti("%06d",stIx)+"_"+sprinti("%06d",enIx)+".nc"
end if

stday = -2.0  ;2
enday = 16.0  ; 16
ndays = toint(enday-stday)
interval = 2 ; number slices per day  ;2
dayArray = fspan(stday,enday,(ndays*interval)+1)
dayArray@units="days"

minWind = 32.0
maxWind = 1000.0

maxAllowAnom = 10.0     ; maximum allowable anomaly

filehead="nhemi_30_x4_slab"
filestrg="h7"
filetail="nc_regrid.nc"

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

;-----------------------------------------------------------
if (plot_only)
  if (isdefined("plot_file"))
    outFileName=plot_file
  end if
  f=addfile(outFileName,"r")
  ;SSTanom=f->SSTanom({-2:10},{-400:400},:,:)
  SSTanom=f->SSTanom(:,:,:,:)
  traj_wind=f->traj_10m_wind
  
  do k = 0,dimsizes(SSTanom&time)-1
  do z = 0,dimsizes(SSTanom&dist)-1
    SSTanom(k,z,:,:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SSTanom(k,z,:,:),SSTanom@_FillValue)
  end do
  end do
else ; do everything else

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

print(ntimes)

;--------------------------------------------------------

voverf = traj_lon
voverf = voverf@_FillValue

traj_bearing = traj_lon
traj_bearing = traj_bearing@_FillValue

traj_speed = traj_lon
traj_speed = traj_speed@_FillValue

;offsetArr    = (/-12.0,-5.0,-2.0,0.0,2.0,5.0,12.0/)
;offsetArr = fspan(-20, 20, 41)
offsetArr = fspan(-500.0, 500.0, 41)
print(offsetArr)

SSTanom = new((/dimsizes(dayArray),dimsizes(offsetArr),nstorms,ntimes/),"float")
SSTanom = SSTanom@_FillValue

storm_times=new((/nstorms,ntimes/),"float")
storm_times = storm_times@_FillValue
storm_times@units="days since 0001-01-01 00:00"

;----------------Universal calcs-----------------------------------



;----------------Loop-----------------------------------

;do j = 0,nstorms-1
do j = 0,nstorms-1
print(" Storm #"+(j+1)+" of "+nstorms)

do k = 0,dimsizes(dayArray)-1
;print("Doing time slice #"+(k+1)+" of "+dimsizes(dayArray))

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

      trackoffset = tracktime
      offset = dayArray(k)
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
            SSTanom(k,z,j,i) = SSTfile->SST({trackoffset},{offLat},{offLon})
            if(abs(SSTanom(k,z,j,i)) .ge. maxAllowAnom)
              SSTanom(k,z,j,i) = SSTanom@_FillValue
            end if
          end if

        end do
      end if  
    end if

  end if ; check for missing
end do
end do
end do

;======================================================================================
; write file

system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "Spatial SSTanom profile as function of time"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

SSTanom!0="time"
SSTanom!1="dist"
SSTanom!2="storm"
SSTanom!3="stormtime"
SSTanom&time = dayArray
SSTanom&dist = offsetArr
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

;filedimdef(ncdf,"storm",-1,True)

;======================================================================================

end if ; PLOT_ONLY IF STATEMENT


if (plot_only) then

wks   = gsn_open_wks (out_type,"cx-cooling")


; GET DATA

res                   = True
res@gsnDraw          = False
res@gsnFrame         = False

res@cnFillOn             = True
cmap = read_colormap_file("WhiteBlue")
res@cnFillPalette = cmap(::-1,:)     ; reverse color map

res@trXMinF = -400.
res@trXMaxF = 400.
res@trYMinF = -2.0
res@trYMaxF = 15.0

res@tiDeltaF = 1.2  ; default 1.5
res@tiXAxisOffsetYF = .187
res@tiYAxisOffsetXF = .002
res@tiXAxisOn = True
res@tiXAxisString     = "Cross-track distance (km)"
res@tiYAxisString     = "Time relative to passage (days)"

res@tiXAxisFontHeightF = 0.02 ; default 0.025
res@tiYAxisFontHeightF = res@tiXAxisFontHeightF

res@lbLabelBarOn = True  ; draw labelbar
res@pmLabelBarOrthogonalPosF = 0.017

plot = gsn_csm_contour(wks,dim_avg_Wrap(dim_avg_Wrap(SSTanom)),res)      ; contour the variable

zlineres = True
zlineres@gsLineColor = "black"
zlineres@gsLineThicknessF = 10.0
dummy_horiz = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0,0/),zlineres)
dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

draw(plot)
frame(wks)

end if
;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

exit

end

