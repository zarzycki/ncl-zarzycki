;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
out_type = "pdf"
wind_factor = 0.85
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
;======================= Constants ================================
ms_to_kts = 1.94384449

styr=2003
enyr=2012
nyears=enyr-styr+1
yearArr=ispan(styr,enyr,1)

stmon=1
enmon=12
nmonths=enmon-stmon+1
monArr=ispan(stmon,enmon,1)

;======================= Masking ================================

basin=1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
files=(/"ibtracs-2003-2015-GLOB.txt", \
"trajectories.txt.CFSR", \
"trajectories.txt.JRA", \
"trajectories.txt.MERRA", \
"trajectories.txt.MERRA2", \
"trajectories.txt.ERA5", \
"trajectories.txt.ERAI", \
"trajectories.txt.MP15A-120A-US-EXP213", \
"trajectories.txt.NE0CONUS30X8-EXP211", \
"trajectories.txt.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.ALL.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.CHEY.111.GLOB.CAM5.4CLM5.0.dtime1800.ALL"/)

strs=(/"IBTrACS","CFSR","JRA","MERRA","MERRA2","ERA5","ERAI","MPAS","SE","CAMWAT","CAMREF","CAMEXT","CAMALL","CAMLR"/)
isUnstruct=(/False,False,False,False,False,False,False,True,True,True,True,True,True,True/)
ensmembers=(/1,1,1,1,1,1,1,1,1,3,3,3,9,3/)

nfiles=dimsizes(files)

nmonths=12

stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")

stormsByMonth=new((/nfiles,12/),"float")
aceByMonth=new((/nfiles,12/),"float")
tcdByMonth=new((/nfiles,12/),"float")

do zz = 0,nfiles-1

  thefile=files(zz)
  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  if (zz .ne. 0) then
    wind_factor = 0.85
  else
    wind_factor = 1.0
  end if

  ; load in trajectory data (need to be modified if using different tempest output
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres  = traj_data(:,4,:)/100.
  xwind  = traj_data(:,5,:)*wind_factor
  xyear  = toint(traj_data(:,7,:))
  xmonth  = toint(traj_data(:,8,:))

  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

;  if (zz.eq.3 .or. zz.eq.4) then
;    xlon = where(xlon.lt.0,xlon+360.,xlon)
;  end if

  do ii = 0,nstorms-1
    orilat=xlat(ii,0)
    orilon=xlon(ii,0)
    if (orilon .gt. 360.0-maskspacing) then
      orilon=360.0-maskspacing
      print("    original lon: "+xlon(ii,0)+"   modified lon: "+orilon)
    end if
    if (tcMask({orilat},{orilon}) .ne. basin)
      xlon(ii,:)=xlon@_FillValue
      xlat(ii,:)=xlat@_FillValue
      xpres(ii,:)=xpres@_FillValue
      xwind(ii,:)=xwind@_FillValue
      xyear(ii,:)=xyear@_FillValue
      xmonth(ii,:)=xmonth@_FillValue
    end if
  end do

if (zz.eq.0)
  ;xlon=where(xwind.gt.35/ms_to_kts,xlon,xlon@_FillValue)
  ;xlat=where(xwind.gt.35/ms_to_kts,xlat,xlat@_FillValue)
  xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
  xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)
  ;xyear=where(xwind.gt.35/ms_to_kts,xyear,xyear@_FillValue)
  ;xmonth=where(xwind.gt.35/ms_to_kts,xmonth,xmonth@_FillValue)

  ;xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
  ;xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
  xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
  xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
  ;xyear=where(xpres.lt.850.,xyear@_FillValue,xyear)
  ;xmonth=where(xpres.lt.850.,xmonth@_FillValue,xmonth)
end if

  xtcd = xwind
  xtcd = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  xlon  := xlon(:,0)
  xlat  := xlat(:,0)
  xace  := 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
  xpres := dim_min_n(xpres,1)
  xwind := dim_max_n(xwind,1)
  xtcd  := dim_sum_n(xtcd,1)
  xyear := xyear(:,0)
  xmonth := xmonth(:,0)

  ;xyear=where(xpres.lt.990.,xyear,xyear@_FillValue)
  
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  cpres = ndtooned(xpres)
  cwind = ndtooned(xwind)
  ctcd = ndtooned(xtcd)
  cace = ndtooned(xace)
  cyear = ndtooned(xyear)
  cmonth = ndtooned(xmonth)

  do ii = 0,nyears-1
    thisYr=ii+styr

    stormsByYear(zz,ii)=num(cyear.eq.thisYr)

    tmpace=where(cyear.eq.thisYr,cace,cace@_FillValue)
    aceByYear(zz,ii)=sum(tmpace)

    tmptcd=where(cyear.eq.thisYr,ctcd,ctcd@_FillValue)
    tcdByYear(zz,ii)=sum(tmptcd)

    delete([/tmpace,tmptcd/])
  end do

  do ii = 1,nmonths
    stormsByMonth(zz,ii-1)=num(cmonth.eq.ii)

    tmpace=where(cmonth.eq.ii,cace,cace@_FillValue)
    aceByMonth(zz,ii-1)=sum(tmpace)

    tmptcd=where(cmonth.eq.ii,ctcd,ctcd@_FillValue)
    tcdByMonth(zz,ii-1)=sum(tmptcd)

    delete([/tmpace,tmptcd/])
  end do

  delete([/xlon,xlat,xpres,xwind,xace,xyear,xmonth,xtcd,clon,clat,cpres,cace,cwind,ctcd,cyear,cmonth/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/thisYr/])

end do

stormsByYear=where(stormsByYear.eq.0,stormsByYear@_FillValue,stormsByYear)

; Correct for number of ensemble members
do mm = 0,nfiles-1
  stormsByYear(mm,:)=stormsByYear(mm,:)/ensmembers(mm)
  aceByYear(mm,:)=aceByYear(mm,:)/ensmembers(mm)
  tcdByYear(mm,:)=tcdByYear(mm,:)/ensmembers(mm)
  stormsByMonth(mm,:)=stormsByMonth(mm,:)/ensmembers(mm)
  aceByMonth(mm,:)=aceByMonth(mm,:)/ensmembers(mm)
  tcdByMonth(mm,:)=tcdByMonth(mm,:)/ensmembers(mm)
end do

delim=","
print("MEAN CLIMO")
do mm = 0,nfiles-1
  print(strs(mm)+delim+avg(stormsByYear(mm,:))+delim+avg(tcdByYear(mm,:))+delim+avg(aceByYear(mm,:)))
end do

; Bias correct
stormsCorrected=tofloat(stormsByYear)
sumobs=avg(stormsCorrected(0,:))
do kk = 1,nfiles-1
  summod=avg(stormsCorrected(kk,:))
  ratio=sumobs/summod
  stormsCorrected(kk,:)=ratio*stormsCorrected(kk,:)
end do

print("INTERANNUAL")
do jj = 1,nfiles-1
  print(strs(jj)+delim+escorc(stormsByYear(0,:),stormsByYear(jj,:))+delim+escorc(tcdByYear(0,:),tcdByYear(jj,:))+delim+escorc(aceByYear(0,:),aceByYear(jj,:)))
end do
print("SEASONAL CYCLE")
do jj = 1,nfiles-1
  print(strs(jj)+delim+escorc(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+escorc(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+escorc(aceByMonth(0,:),aceByMonth(jj,:)))
end do

wks   = gsn_open_wks ("x11","xy") 

res                   = True                      ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False
res@tiMainString      = "Reanalysis vs. IBTrACS"       ; add title

res@xyMonoDashPattern=True
res@xyMonoLineThickness=True
res@xyLineThicknessF = 5.0

res@trYMinF=0.0

res@xyLineColors      = (/"black","red","blue","green","darkgreen","orange","purple","red1","red2","yellow","yellow","yellow","gold","gold2"/)          ; change line color

;plot  = gsn_csm_xy (wks,yearArr,aceByYear,res) ; create plot
plot  = gsn_csm_xy (wks,monArr,aceByMonth,res) ; create plot

textres=True
lineres=True
textres@lgLabels     = strs
lineres@lgLineColors = res@xyLineColors
plot = simple_legend(wks,plot,res,lineres,textres)

draw(plot)
frame(wks)

end
