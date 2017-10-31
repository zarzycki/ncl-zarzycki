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
;traj_filename = "cat_traj_slab_08_4.7_900.txt"
traj_filename = "cat_traj_fixedSST_900.txt"
;traj_filename = "traj_fixedSST_1202.txt"
filehead="nhemi_30_x4_fixedSST"
out_type = "pdf"


minWind=0.0
maxWind=999.0
latBox = 1.0 ; size of box surrounding cyclone center to calc anom

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

SST = new(traj_nrows,"float")
dSST = new(traj_nrows,"float")
SST = SST@_FillValue
dSST = dSST@_FillValue

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

  tracktime   = cd_inv_calendar(yyyy,mm,dd,hh,0,0,units,0)

  if(tracktime .ge. mindate .and. tracktime .le. maxdate)
    SSTfilename=SSTdir+"/"+filehead+".cam."+filestrg+"."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
    SSTfile = addfile(SSTfilename,"r")
    SST_turb = avg(SSTfile->dSST_turb({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
    SST_flux = avg(SSTfile->dSST_flux({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
    dSST(i) = SST_turb + SST_flux
    delete(SST_turb)
    delete(SST_flux)
    SSTbasename="/glade/u/home/zarzycki/work/slab/SSTclimo/nhemi_30_x4.cam.SSTclimo.0000-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-00000.nc_regrid.nc"
    SSTbase=addfile(SSTbasename,"r")
    SST(i)=avg(SSTbase->SST(0,{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
  end if

end do

;SST=where(SST.lt.290,SST@_FillValue,SST)

; OUTPUT NETCDF FILE
outFileName="dSST_"+filehead+".nc"

system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

ncdf->SST = SST
ncdf->dSST = dSST
ncdf->traj_lon = traj_lon
ncdf->traj_lat = traj_lat
ncdf->traj_wind = traj_wind
ncdf->traj_pres = traj_pres
ncdf->traj_yyyy = traj_yyyy
ncdf->traj_mm = traj_mm
ncdf->traj_dd = traj_dd
ncdf->traj_hh = traj_hh



;  wks = gsn_open_wks ("x11","scatter")            ; open workstation
;
;  res                   = True                     ; plot mods desired
;  res@gsnMaximize       = True
;
;  res@tiMainString      = "least-squares polynomial fit (lspoly)"
;  res@xyMarkLineModes   = (/"Markers"/)
;
;  res@xyMarker          =  16                  ; Change type, size, and
;  res@xyMarkerSizeF     = 0.008                ; color of marker
;  res@xyMarkerColor     = "purple4"
;
;  plot = gsn_csm_xy (wks, traj_wind, dSST, res)

;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

