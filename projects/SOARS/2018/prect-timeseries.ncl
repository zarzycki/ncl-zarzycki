;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;========================================================

begin

filename     = "indices.csv"
lines        = asciiread(filename,-1,"string")
delim        = ","
ix_var       = tointeger(str_get_field(lines,1,delim))
name_var     =           str_get_field(lines,2,delim)
lat_var      =   tofloat(str_get_field(lines,3,delim))
lon_var      =   tofloat(str_get_field(lines,4,delim))
longname_var =           str_get_field(lines,5,delim)

print("Name is '" + name_var + "', ix is " + ix_var)

TCDISTTHRESH=500.
ENSMEM="003"
SIMYRS="1979_2012"     ; 1979_2012, RCP85_2070_2099, 

thefile="~/tempest-scripts/nan-ne120/trajectories.txt.TEST.NE120."+SIMYRS+"."+ENSMEM
filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h2.PRECT.*.nc") ; file paths

if (SIMYRS .eq. "1979_2012") then
  yrlabel="1980_2009"
else
  yrlabel="2070_2099"
end if

f    = addfiles (filelist, "r")   
ListSetType (f, "cat")        ; concatenate (=default)
ftime = f[:]->time
lat=f[0]->lat
lon=f[0]->lon
nftim = dimsizes(ftime)

; LOAD TRAJECTORIES

basin="atlantic"
cutwind=0.0
factor = surfaceWindCorrFactor(-1,-1,"log")
factorland = surfaceWindCorrFactor(-1,1.0,"log")

basinfilt = 1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

ncols = 10                     ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
traj_data = getTrajectories(thefile,ncols,maxLines,headerDelimStr,delimStr,isHeader)

tlon = traj_data(:,1,:)
tlat = traj_data(:,2,:)
twind = traj_data(:,4,:)*factor
tpres = traj_data(:,3,:)/100.
tyyyy=  traj_data(:,6,:)
tmm= traj_data(:,7,:)
tdd= traj_data(:,8,:)
thh= traj_data(:,9,:)

ndims = dimsizes(tlon)
nstorms = ndims(0)
ntimes = ndims(1)

onedtlat=ndtooned(tlat)
onedtlon=ndtooned(tlon)
onedtpres=ndtooned(tpres)
onedtwind=ndtooned(twind)
onedtyyyy=ndtooned(tyyyy)
onedtmm=ndtooned(tmm)
onedtdd=ndtooned(tdd)
onedthh=ndtooned(thh)
onedtmin=onedthh
onedtmin=0.0
onedtsssss=onedtmin

opt=1
opt@calendar=ftime@calendar
opt@return_type=typeof(ftime)
onedtcal=cd_inv_calendar(onedtyyyy,onedtmm,onedtdd,onedthh,onedtmin,onedtsssss,ftime@units,opt)

iz = ind(.not.ismissing(onedtlon))
if (.not.all(ismissing(iz))) 
  tlonfilt=onedtlon(iz)  
  tlatfilt=onedtlat(iz) 
  tcalfilt=onedtcal(iz)
  tpresfilt=onedtpres(iz) 
  twindfilt=onedtwind(iz) 
else
  print ("something is wrong, all traj values are missing...")
end if

; LOAD OTHER FILES
filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h2.TMQ.*.nc") ; file paths
fTMQ = addfiles (filelist, "r")
ListSetType (fTMQ, "cat")

filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h4.PSL.*.nc") ; file paths
fPSL = addfiles (filelist, "r")
ListSetType (fPSL, "cat")

filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h4.UBOT.*.nc") ; file paths
fUBOT = addfiles (filelist, "r")
ListSetType (fUBOT, "cat")

filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h4.VBOT.*.nc") ; file paths
fVBOT = addfiles (filelist, "r")
ListSetType (fVBOT, "cat")

filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/f.e13.*.ne120_ne120."+SIMYRS+"."+ENSMEM+".cam.h4.TS.*.nc") ; file paths
fTS = addfiles (filelist, "r")
ListSetType (fTS, "cat")

do zz = 0,dimsizes(ix_var)-1

  TESTLAT=lat_var(zz)
  TESTLON=lon_var(zz)
  CITYNAME=name_var(zz)
  print(zz+" "+TESTLAT+" "+TESTLON+" "+CITYNAME)

  gcdist = gc_latlon(TESTLAT,TESTLON,lat,lon,2,4)
  ;print(gcdist)
  ;print(min(gcdist))
  ;print(max(gcdist))
  ix = minind(gcdist)

  print(ix+"")
  print(lat(ix)+"")
  print(lon(ix)+"")

  PRECT    = f[:]->PRECT(:,ix)
  PRECT = PRECT*8.64e7/4.  ; convert to mm/6hr
  PRECT@_FillValue=-9.999e-9
  PRECT = where(PRECT.lt.1e-3,0,PRECT)   ; correct for small eps values

  TMQ = fTMQ[:]->TMQ(:,ix)

  PSL = fPSL[:]->PSL(::2,ix)
  PSL = PSL/100.  ; convert to hPa/mb from Pa

  UBOT = fUBOT[:]->UBOT(::2,ix)
  VBOT = fVBOT[:]->VBOT(::2,ix)
  U10 = UBOT
  U10 = factorland*sqrt(UBOT^2 + VBOT^2)
  delete(UBOT)
  delete(VBOT)

  TS = fTS[:]->TS(::2,ix)
  TS = TS - 273.15

  ; -------------------------------------------------------------------------

  outputname="station."+CITYNAME+"."+yrlabel+"."+ENSMEM+".csv"
  system("rm "+outputname)
  quote = inttochar(34)
  delim = ","

  TCorNO=new(nftim,"logical")
  TCorNO=False
  TCorNOstr=new(nftim,"string")
  TCpres=new(nftim,"float")
  TCpres=-999.
  TCwind=TCpres
  TClat=TCpres
  TClon=TCpres

  do ii = 0,nftim-1
    thisTime=ftime(ii)
    ;print(thisTime+"")
    ; find what times in the trajectory file match this time
    ia = ind(tcalfilt.eq.thisTime)
  
    ; if ia returns non-missing values, need to check storms...
    if(.not.all(ismissing(ia)))
      ;print(ia+"")
      numposs=dimsizes(ia)
      do jj = 0,dimsizes(ia)-1
        ib = ia(jj)
        ;print(ib+"")
        disttoTC=gc_latlon(TESTLAT,TESTLON,tlatfilt(ib),tlonfilt(ib),2,4)
        if (disttoTC .lt. TCDISTTHRESH) then
          ;print("we have found a TC: "+disttoTC+" "+tlatfilt(ib)+" "+tlonfilt(ib))
          TCorNO(ii) = True
          TCpres(ii) = tpresfilt(ib)
          TCwind(ii) = twindfilt(ib)
          TClat(ii) = tlatfilt(ib)
          TClon(ii) = tlonfilt(ib)
          break
        else
          ;print("no TC "+disttoTC+" "+tlatfilt(ib)+" "+tlonfilt(ib))
        end if
        delete(ib)
      end do
    end if
    delete(ia)

    ;system("echo "+quote+cd_calendar(thisTime,2)+delim+PRECT(ii)+delim+TCorNO(ii)+     quote+" >> "+outputname)
  end do

  TCorNOstr=where(TCorNO.eq.True,"     TRUE","    FALSE")

  alist   = [/conform(ftime,CITYNAME,-1),conform(ftime,TESTLAT,-1),conform(ftime,TESTLON,-1),"   "+tostring(cd_calendar(ftime,-3)),PRECT,PSL,TMQ,U10,TS,TCorNOstr,TClat,TClon,TCpres,TCwind/]
  write_table(outputname, "w", alist, "%s,%7.1f,%7.1f,%s,%7.1f,%9.1f,%7.1f,%7.1f,%7.1f,%s,%7.1f,%7.1f,%9.1f,%7.1f")

  ;alist   = [/cd_calendar(ftime,-3),PRECT,TCorNO/]
  ;write_table(outputname, "w", alist, "%i,%6.1f,%s")

  ;print(TCorNO+" "+cd_calendar(ftime,2)+" "+tofloat(PRECT)+" "+ftime)

  ; plotting

  wks          = gsn_open_wks ("png","img."+CITYNAME+"."+yrlabel+"."+ENSMEM) ; send graphics to PNG file

  res          = True                   ; plot mods desired
  res@gsnFrame = False                  ; don't advance frame yet      
  res@gsnDraw = False

  res@tiYAxisString    = "PRECT (mm/6hr)"    ; y-axis label      
  res@tiMainString     = CITYNAME+" precip." ; title
  restick           = True
  restick@ttmFormat = "%N/%y"
  time_axis_labels(ftime,res,restick)  

  plot = gsn_csm_xy (wks,ftime,PRECT,res)        ; create plot

  PRECT=where(TCorNO.eq.True,PRECT,PRECT@_FillValue)
  res@xyLineColor="red"
  res@xyLineThicknessF=3.0
  plotTC = gsn_csm_xy (wks,ftime,PRECT,res)        ; create plot

  overlay(plot,plotTC)

  draw(plot)
  frame(wks)

  delete(res)
  delete(plot)
  delete(plotTC)
  delete(PRECT)
  delete(wks)
  delete(TCorNO)

end do

end
