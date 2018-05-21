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

filename = "indices.csv"
lines = asciiread(filename,-1,"string")
delim = ","
ix_var   = tointeger(str_get_field(lines,1,delim))
name_var =           str_get_field(lines,2,delim)
lat_var =   tofloat(str_get_field(lines,3,delim))
lon_var =   tofloat(str_get_field(lines,4,delim))

print("Name is '" + name_var + "', ix is " + ix_var)

TCDISTTHRESH=800.

thefile="~/tempest-scripts/hyperion/trajectories.txt.CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900"
filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/*cam.h2*") ; file paths

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
else
  print ("something is wrong, all traj values are missing...")
end if

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

  PSL = f[:]->PSL(:,ix)
  PSL = PSL/100.  ; convert to hPa/mb from Pa
  
  ; -------------------------------------------------------------------------

  outputname="timeseries."+CITYNAME+".csv"
  system("rm "+outputname)
  quote = inttochar(34)
  delim = ","

  filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/*cam.h2*") ; file paths
  ;filelist = systemfunc ("ls ~/scratch/archive/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900/atm/hist/*cam.h2*") ; file paths

  TCorNO=new(nftim,"logical")
  TCorNO=False
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

  alist   = [/cd_calendar(ftime,-2),PRECT,PSL,TCorNO/]
  write_table(outputname, "w", alist, "%i,%6.1f,%8.1f,%s")

  ;print(TCorNO+" "+cd_calendar(ftime,2)+" "+tofloat(PRECT)+" "+ftime)

  ; plotting

  wks          = gsn_open_wks ("png","series."+CITYNAME) ; send graphics to PNG file

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
  res@xyLineThicknessF=4.0
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
