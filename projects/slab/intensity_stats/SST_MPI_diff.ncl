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

isProcess=True

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"

;traj_filename = "cat_traj_fixedSST_900.txt"
traj_filename = "cat_traj_slab2_08_4.7_900.txt"
config = "slab2"

ncFileName=config+"_"+traj_filename+".nc"
;ncFileName="test.nc"

out_type = "pdf"

if (.not. isdefined("minWind"))
  minWind=33.0
end if
if (.not. isdefined("maxWind"))
  maxWind=999.0
end if
if (.not. isdefined("latBox"))
  latBox = 1.0 ; size of box surrounding cyclone center to calc anom
end if

print("Using minwind: "+minWind+"   maxwind: "+maxWind+"    latBox: "+latBox)

maxAllowAnom = 10.0     ; maximum allowable anomaly

filehead="nhemi_30_x4_"+config
filetail="nc_regrid.nc"

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

if (isProcess) then
  f=addfile(ncFileName,"r")
  SST_slab_SST=f->SST_slab_SST
  SST_slab_anom=f->SST_slab_anom
  LHFLX_slab=f->LHFLX_slab
  SHFLX_slab=f->SHFLX_slab
  traj_wind=f->traj_10m_wind
  traj_pres=f->traj_pres
  traj_lat=f->traj_lat
  traj_lon=f->traj_lon
else
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

  SST_slab_anom  = new(traj_nrows,"float")
  SST_slab_SST   = new(traj_nrows,"float")
  SST_slab_climo = new(traj_nrows,"float")

  MPI_slab_anom  = new(traj_nrows,"float")
  MPI_slab_SST   = new(traj_nrows,"float")
  MPI_slab_climo = new(traj_nrows,"float")

  LHFLX_slab    = new(traj_nrows,"float")
  SHFLX_slab    = new(traj_nrows,"float")
  ENTHALPY_slab = new(traj_nrows,"float")

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
    tracktimep3 = cd_inv_calendar(yyyy,mm,dd,hh+3,0,0,units,0)

    if(tracktime .ge. mindate .and. tracktime .le. maxdate)
      if (config .ne. "fixedSST") then
        SST_anom_filename=SSTdir+"/"+filehead+".cam.h7."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
        SST_anom_file = addfile(SST_anom_filename,"r")
        SST_slab_anom(i)  = avg(SST_anom_file->SST({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
      end if
    
      SST_SST__filename=SSTdir+"/"+filehead+".cam.h4."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
      SST_SST__file = addfile(SST_SST__filename,"r")
      SST_slab_SST(i)   = avg(SST_SST__file->SST({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
    
      FLUX_filename    =SSTdir+"/"+filehead+".cam.h5."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
      FLUX_file     = addfile(FLUX_filename    ,"r")
      LHFLX_slab(i)     = avg(FLUX_file->LHFLX({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
      SHFLX_slab(i)     = avg(FLUX_file->SHFLX({tracktime},{lat-latBoxHalf:lat+latBoxHalf},{lon-latBoxHalf:lon+latBoxHalf}))
    end if
  end do

  ;======================================================================================
  ; write file

  system("/bin/rm -f "+ncFileName)   ; remove any pre-existing file
  ncdf = addfile(ncFileName,"c")  ; open output netCDF file

  fAtt               = True            ; assign file attributes
  fAtt@title         = "Spatial SSTanom profile as function of time"
  fAtt@Conventions   = "None"
  fAtt@creation_date = systemfunc ("date")
  fileattdef( ncdf, fAtt )            ; copy file attributes

  ;SSTanom!0="time"
  ;SSTanom!1="dist"
  ;SSTanom!2="storm"
  ;SSTanom!3="stormtime"
  ;SSTanom&time = dayArray
  ;SSTanom&dist = offsetArr
  ;SSTanom&storm = storm_index
  ;SSTanom@long_name = "SST anomaly"
  ncdf->LHFLX_slab  = LHFLX_slab     
  ncdf->SHFLX_slab  = SHFLX_slab
  ncdf->SST_slab_SST=SST_slab_SST
  ncdf->SST_slab_anom=SST_slab_anom
  ncdf->voverf=voverf
  ncdf->traj_lat=traj_lat
  ncdf->traj_lon=traj_lon
  ncdf->traj_10m_wind=traj_wind
  ncdf->traj_pres=traj_pres

  ;======================================================================================

end if ;isProcess

SST_slab_anom(:)=where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SST_slab_anom(:),SST_slab_anom@_FillValue)
SST_slab_SST(:) =where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SST_slab_SST(:) ,SST_slab_SST@_FillValue)
LHFLX_slab(:)   =where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,LHFLX_slab(:)   ,LHFLX_slab@_FillValue)
SHFLX_slab(:)   =where(traj_wind .ge. minWind .and. traj_wind .le. maxWind,SHFLX_slab(:)   ,SHFLX_slab@_FillValue)
SST_slab_climo = SST_slab_SST - SST_slab_anom
A=34.21
B=55.80
C=0.1813
T0=30.0
KtoC=273.15
MPI_slab_climo = A + B*exp(C* ((SST_slab_climo-KtoC)-T0))
MPI_slab_SST   = A + B*exp(C* ((SST_slab_SST  -KtoC)-T0))
MPI_slab_anom = MPI_slab_climo - MPI_slab_SST

print("LHFLUX avg: "+avg(LHFLX_slab))
print("SHFLUX avg: "+avg(SHFLX_slab))
    
print("SST_anom avg: "+avg(SST_slab_anom))
print("Avg SST slab avg: "+avg(SST_slab_SST))
print("Avg SST fixed avg: "+avg(SST_slab_climo))

print("MPI_slab_anom avg: "+avg(MPI_slab_anom))
print("MPI_slab avg: "+avg(MPI_slab_SST))
print("MPI_fixed avg: "+avg(MPI_slab_climo))

outFileName="mpistats/"+traj_filename+"_"+minWind+"_"+maxWind+".csv"

system("rm "+outFileName)
system("echo LHFLUX,SHFLUX,SST_anom,SST_exp_avg,SST_fixed_avg,MPI_slab_anom,MPI_exp_avg,MPI_fixed_avg >> "+outFileName)
system("echo "+avg(LHFLX_slab)+","+avg(SHFLX_slab)+","+avg(SST_slab_anom)+","+avg(SST_slab_SST)+","+avg(SST_slab_climo)+","+avg(MPI_slab_anom)+","+avg(MPI_slab_SST)+","+avg(MPI_slab_climo)+" >> "+outFileName)


opt = True
opt@PrintStat = True
statb = stat_dispersion(todouble(MPI_slab_anom), opt )



;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

