;========================================================
; Reads a trajectory file and calculates the fraction of CW
; under TC center due to new parameterization and due to fluxes
; outputs a NetCDF file which contains these fractions to be plotted
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

;---------------User settings----------------------------

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"
traj_filename = "cat_traj_slab_08_4.7_900.txt"
;traj_filename = "traj_slab2_1201.txt"
filehead="nhemi_30_x4_slab"
out_type = "pdf"

if (.not. isdefined("minWind"))
  minWind=0.0
end if
if (.not. isdefined("maxWind"))
  maxWind=999.0
end if
if (.not. isdefined("latBox"))
  latBox = 1.0 ; size of box surrounding cyclone center to calc anom
end if

print("Using minwind: "+minWind+"   maxwind: "+maxWind+"    latBox: "+latBox)

maxAllowAnom = 10.0     ; maximum allowable anomaly


outFileName="data_"+traj_filename+".nc"
filestrg="h8"
filetail="nc_regrid.nc"

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;--------------------------------------------------------

;print("Getting TC Mask")
;maskspacing=2
;tcMask = mask_tc(0,-999,-999,maskspacing,360)
;tcMaskIB = mask_tc(0,-999,-999,maskspacing,180)

;--------------------------------------------------------

print("Read in TC locations from CAM")
traj_cleanfile = "traj_filt_clean.TMP.getSSTs" ; hardcoded temp file name, feel free to change
print("Removing text headers from trajectories")
system("grep -v '^start' "+ traj_dir+traj_filename +" > "+traj_cleanfile+"")

traj_ncols = numAsciiCol(traj_cleanfile)
traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
      " columns of data.")
print("Removing temporary file:"+traj_cleanfile)
system("rm -rf "+traj_cleanfile)

;print(traj_data)

traj_lon = traj_data(:,3)
traj_lat = traj_data(:,4)
traj_wind = traj_data(:,5)*factor
traj_pres = traj_data(:,7)/100.
traj_yyyy = traj_data(:,8)
traj_mm = traj_data(:,9)
traj_dd = traj_data(:,10)
traj_hh = traj_data(:,11)

voverf = traj_lon
voverf = voverf@_FillValue
voverf = 1.0

SST_turb = new(traj_nrows,"float")
SST_flux = new(traj_nrows,"float")
SST_turb = SST_turb@_FillValue
SST_flux = SST_flux@_FillValue

;----------------Universal calcs-----------------------------------

latBoxHalf = latBox/2.0

;----------------Loop-----------------------------------

do i = 0,traj_nrows-1
  if ( mod(i,100).eq.0) then
    print ("done with "+i+" out of "+(traj_nrows-1)+" rows")
  end if
  thisYear=traj_yyyy(i)
  SSTdir="/glade/u/home/zarzycki/scratch/"+filehead+"/run/"+thisYear+"/"
  units="days since "+thisYear+"-05-01 00:00:00"

  yyyy=toint(traj_yyyy(i))
  mm=toint(traj_mm(i))
  dd=toint(traj_dd(i))
  hh=toint(traj_hh(i))
  sssss=hh*3600

  lat=traj_lat(i)
  lon=traj_lon(i)
  wind=traj_wind(i)
  pres=traj_pres(i)

  mindate   = cd_inv_calendar(yyyy,05,01,00,0,0,units,0)
  maxdate   = cd_inv_calendar(yyyy,11,30,18,0,0,units,0)

  if (i .gt. 0) then
    dist = gc_latlon(traj_lat(i),traj_lon(i),traj_lat(i-1),traj_lon(i-1),2,3)
    if (dist .lt. 25*6*3600) then
    v = dist / (6.*3600.)
    lat2rad = lat*pi/180.
    f = 2*omega*sin(lat2rad)
    voverf(i) = v/f/100000
    end if
  end if

  tracktime   = cd_inv_calendar(yyyy,mm,dd,hh,0,0,units,0)

  if(tracktime .ge. mindate .and. tracktime .le. maxdate)
    SSTfilename=SSTdir+"/"+filehead+".cam."+filestrg+"."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
    SSTfile = addfile(SSTfilename,"r")
    SST_turb(i) = avg(SSTfile->dSST_turb({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
    SST_flux(i) = avg(SSTfile->dSST_flux({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))

;    if(abs(SSTanom(j,i)) .ge. maxAllowAnom)
;      SSTanom(j,i) = SSTanom@_FillValue
;    end if
  end if

end do

SST_frac = SST_turb
SST_frac = abs(SST_turb) / abs(SST_turb + SST_flux)

;printVarSummary(traj_wind)
;printVarSummary(voverf)
;printVarSummary(SSTanom)

SSTanom_slow=SST_frac
SSTanom_fast=SST_frac
SSTanom_slow(:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .lt. 1.0,SST_frac(:),SST_frac@_FillValue)
SSTanom_fast(:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind .and. voverf .gt. 1.0,SST_frac(:),SST_frac@_FillValue)

;SSTanom_all=SST_frac
;SSTanom_td=SST_frac
;SSTanom_ts=SST_frac
;SSTanom_c1=SST_frac
;SSTanom_c2=SST_frac
;SSTanom_c3=SST_frac
;SSTanom_c4=SST_frac
;SSTanom_c5=SST_frac
;SSTanom_all(:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SST_frac(:),SST_frac@_FillValue)
;SSTanom_td(:) = where(traj_wind .ge. 000.0 .and. traj_wind .lt. 017.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_ts(:) = where(traj_wind .ge. 017.0 .and. traj_wind .lt. 032.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_c1(:) = where(traj_wind .ge. 032.0 .and. traj_wind .lt. 042.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_c2(:) = where(traj_wind .ge. 042.0 .and. traj_wind .lt. 049.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_c3(:) = where(traj_wind .ge. 049.0 .and. traj_wind .lt. 058.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_c4(:) = where(traj_wind .ge. 058.0 .and. traj_wind .lt. 070.0,SST_frac(:),SST_frac@_FillValue)
;SSTanom_c5(:) = where(traj_wind .ge. 070.0                           ,SST_frac(:),SST_frac@_FillValue)

windCuts=(/0.0,17.0,32.0,42.0,49.0,58.0,70.0,999.9/)
windCutStrs=(/"TD","TS","C1","C2","C3","C4","C5"/)
windCutStrLocs=(/1.0,2.0,3.0,4.0,5.0,6.0,7.0/)
nWinds = dimsizes(windCuts)
avgArray=new((/7,dimsizes(windCuts)/),"float",-999.0)

statopt   = False
do i = 0,nWinds-2
  tmpSST=SST_frac
  tmpSST(:)=where(traj_wind .ge. windCuts(i) .and. traj_wind .le. windCuts(i+1),SST_frac(:),SST_frac@_FillValue)
  stats = stat_dispersion(tmpSST, statopt )
  avgArray(0,i)=stats(2)
  avgArray(1,i)=stats(6)
  avgArray(2,i)=stats(0)
  avgArray(3,i)=stats(8)
  avgArray(4,i)=stats(10)
  avgArray(5,i)=stats(14)
  avgArray(6,i)=stats(1)
  delete(stats)
  delete(tmpSST)
end do

statsDesc=(/"Min","LowQuart","Mean","Median","HighQuart","Max","SD"/)

stats = stat_dispersion(SST_frac,statopt)
avgArray(0,dimsizes(windCuts)-1)=stats(2)
avgArray(1,dimsizes(windCuts)-1)=stats(6)
avgArray(2,dimsizes(windCuts)-1)=stats(0)
avgArray(3,dimsizes(windCuts)-1)=stats(8)
avgArray(4,dimsizes(windCuts)-1)=stats(10)
avgArray(5,dimsizes(windCuts)-1)=stats(14)
avgArray(6,dimsizes(windCuts)-1)=stats(1)
delete(stats)

do i = 0,nWinds-1
  if (i .eq. nWinds-1) then
    print("ALL: "+avgArray(1,i)+"  "+avgArray(3,i)+"  "+avgArray(4,i))
  else
    print(windCutStrs(i)+": "+avgArray(1,i)+"  "+avgArray(3,i)+"  "+avgArray(4,i))
  end if
end do

; OUTPUT NETCDF FILE

system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

avgArray!0    = "stat"
avgArray!1    = "category"
ncdf->avgArray = avgArray
ncdf->windCuts = windCuts
ncdf->windCutStrLocs = windCutStrLocs
;ncdf->windCutStrs=windCutStrs



;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

