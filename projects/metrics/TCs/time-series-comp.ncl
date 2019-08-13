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
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
trajDir="./trajs/"
csvdir="./csv-files/"
;======================= Constants ================================
ms_to_kts = 1.94384449

styr=1980
enyr=2016
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
filename = "test_configs.csv"
lines = asciiread(filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))
linecolors = str_get_field(lines,7,delim)

isUnstruct = where(isUnstructStr.eq."True",True,False)

;=================== Get traj data ================================

nfiles=dimsizes(files)

nmonths=12

stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
paceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")

stormsByMonth=new((/nfiles,12/),"float")
aceByMonth=new((/nfiles,12/),"float")
paceByMonth=new((/nfiles,12/),"float")
tcdByMonth=new((/nfiles,12/),"float")

avgStorms=new((/nfiles/),"float")
avgLength=new((/nfiles/),"float")
avgTcd=new((/nfiles/),"float")
avgLMI=new((/nfiles/),"float")
avgAce=new((/nfiles/),"float")
avgPace=new((/nfiles/),"float")
avgLatgen=new((/nfiles/),"float")



do zz = 0,nfiles-1

  thefile=trajDir+"/"+files(zz)
  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  wind_factor = windcorrs(zz)
  print("corr wind: "+wind_factor)

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

  if (basin .gt. 0) then
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
  end if

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

  xlatmi=new(nstorms,typeof(xlat))
  xlonmi=xlatmi
  do kk = 0,nstorms-1
    if(.not.all(ismissing(xpres(kk,:)))) then
      locMI=minind(xpres(kk,:))
      print(""+locMI)
      xlatmi(kk)=xlat(kk,locMI)
      xlonmi(kk)=xlon(kk,locMI)
    end if
  end do

  xtcd = xwind
  xtcd = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  xlon  := xlon(:,0)
  xlat  := xlat(:,0)

  xnum := dim_num_n(.not.ismissing(xwind),1)
  xnum = where(xnum.le.0,xnum@_FillValue,xnum)

  xace  := 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
  xace = where(ismissing(xace) .and. .not.(ismissing(xlon)),0.0,xace)
  ; if ace is missing BUT xlon is not missing (storm in this basin) set ACE to zero
  ; if xlon is missing, will leave ace as missing since storm isn't in basin

  ;do jj=0,nstorms-1
  ;  print(xlon(jj,:)+" "+xlat(jj,:)+" "+xwind(jj,:)+" "+tostring(1e-4*(ms_to_kts*xwind(jj,:))^2.))
  ;end do

  print("min: "+min(xpres)+"   max: "+max(xpres))
  xprestmp = where(xpres.lt.1010,xpres,1010.)
  xpace := 1e-4*dim_sum_n( (ms_to_kts*3.2*(1010.-xprestmp)^0.76)^2.,1)
  xpace = where(ismissing(xpace) .and. .not.(ismissing(xlon)),0.0,xpace)

  delete(xprestmp)
  print("min: "+min(xpace)+"   max: "+max(xpace))
  xpres := dim_min_n(xpres,1)
  xwind := dim_max_n(xwind,1)
  xtcd  := dim_sum_n(xtcd,1)
  xyear := xyear(:,0)
  xmonth := xmonth(:,0)



  ;xyear=where(xpres.lt.990.,xyear,xyear@_FillValue)
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  clatmi = ndtooned(xlatmi)
  clonmi = ndtooned(xlonmi)
  cpres = ndtooned(xpres)
  cwind = ndtooned(xwind)
  ctcd = ndtooned(xtcd)
  cace = ndtooned(xace)
  cpace = ndtooned(xpace)
  cyear = ndtooned(xyear)
  cmonth = ndtooned(xmonth)
  cnum = ndtooned(xnum)

  print(cace)
  print(" SUM "+sum(cace)+"")

  do ii = 0,nyears-1
    thisYr=ii+styr

    stormsByYear(zz,ii)=num(cyear.eq.thisYr)

    tmpace=where(cyear.eq.thisYr,cace,cace@_FillValue)
    aceByYear(zz,ii)=sum(tmpace)

    tmppace=where(cyear.eq.thisYr,cpace,cpace@_FillValue)
    paceByYear(zz,ii)=sum(tmppace)

    tmptcd=where(cyear.eq.thisYr,ctcd,ctcd@_FillValue)
    tcdByYear(zz,ii)=sum(tmptcd)

    delete([/tmpace,tmppace,tmptcd/])
  end do

  do ii = 1,nmonths
    stormsByMonth(zz,ii-1)=num(cmonth.eq.ii)

    tmpace=where(cmonth.eq.ii,cace,cace@_FillValue)
    aceByMonth(zz,ii-1)=sum(tmpace)

    tmppace=where(cmonth.eq.ii,cpace,cpace@_FillValue)
    paceByMonth(zz,ii-1)=sum(tmppace)

    tmptcd=where(cmonth.eq.ii,ctcd,ctcd@_FillValue)
    tcdByMonth(zz,ii-1)=sum(tmptcd)

    delete([/tmpace,tmppace,tmptcd/])
  end do

  print("total sum: "+num(.not.ismissing(cyear)))

  avgStorms(zz) = tofloat(num(.not.ismissing(cyear)))/ensmembers(zz)/yearspermember(zz)
  avgTcd(zz) = avg(ctcd)*avgStorms(zz)
  avgPace(zz) = avg(cpace)*avgStorms(zz)
  avgAce(zz) = avg(cace)*avgStorms(zz)
  avgLength(zz) = avg(cnum)
  avgLMI(zz) = avg(abs(clatmi))
  avgLatgen(zz) = avg(abs(clat))
  print(avg(cace)+" "+avgStorms(zz))

  delete([/xlon,xlat,xpres,xwind,xace,xpace,xyear,xmonth,xtcd,xnum,xlatmi,xlonmi/])
  delete([/clon,clat,cpres,cwind,cace,cpace,cyear,cmonth,ctcd,cnum,clatmi,clonmi/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/thisYr/])

  print("---------------------------------------------------- DONE")
end do

stormsByYear=where(stormsByYear.eq.0,stormsByYear@_FillValue,stormsByYear)

print("Correcting for number of ensemble members")
do mm = 0,nfiles-1
  stormsByYear(mm,:)=stormsByYear(mm,:)/ensmembers(mm)
  aceByYear(mm,:)=aceByYear(mm,:)/ensmembers(mm)
  paceByYear(mm,:)=paceByYear(mm,:)/ensmembers(mm)
  tcdByYear(mm,:)=tcdByYear(mm,:)/ensmembers(mm)
  stormsByMonth(mm,:)=stormsByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  aceByMonth(mm,:)=aceByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  paceByMonth(mm,:)=paceByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  tcdByMonth(mm,:)=tcdByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  print(yearArr+" "+stormsByYear(mm,:)+" "+aceByYear(mm,:)+" "+tcdByYear(mm,:))
end do


print("Bias correction.")
stormsCorrected=tofloat(stormsByYear)
sumobs=avg(stormsCorrected(0,:))
do kk = 1,nfiles-1
  summod=avg(stormsCorrected(kk,:))
  ratio=sumobs/summod
  stormsCorrected(kk,:)=ratio*stormsCorrected(kk,:)
end do

print("Setting CSV parameters")
quote = inttochar(34)
delim=","
OPT=0

;; this is MATCHED basin mean statistics, i.e., only overlapping years
;; so if ibtracs is 1980-2000 but model is only 1988-1990, n = 3 and match those years.
print("... doing basin-mean statistics")
outputname=csvdir+"/"+"metrics_climo_mean.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
do mm = 0,nfiles-1
  if (mm .eq. 0) then
  OUTSTR=strs(mm)+delim+ \
    avg(stormsByYear(0,:))+delim+ \
    avg(tcdByYear(0,:))+delim+ \
    avg(aceByYear(0,:))+delim+ \
    avg(paceByYear(0,:))
  else
  OUTSTR=strs(mm)+delim+ \
    avg(stormsByYear(mm,:)-stormsByYear(0,:))+delim+ \
    avg(tcdByYear(mm,:)-tcdByYear(0,:))+delim+ \
    avg(aceByYear(mm,:)-aceByYear(0,:))+delim+ \
    avg(paceByYear(mm,:)-paceByYear(0,:))
  end if
  system("echo "+OUTSTR+" >> "+outputname)
end do

;; this is bias as OVERALL statistics, i.e., all available data for each product
/;
print("... doing basin-mean statistics2")
outputname=csvdir+"/"+"metrics_climo_mean2.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2,Length >> "+outputname)
do mm = 1,nfiles-1
  OUTSTR=strs(mm)+delim+ \
    (avgStorms(mm)-avgStorms(0))+delim+ \
    (avgTcd(mm)-avgTcd(0))+delim+ \
    (avgAce(mm)-avgAce(0))+delim+ \
    (avgPace(mm)-avgPace(0))+delim+ \
    (avgLatgen(mm)-avgLatgen(0))+delim+ \
    (avgLMI(mm)-avgLMI(0))+delim+ \
    (avgLength(mm)-avgLength(0))
  system("echo "+OUTSTR+" >> "+outputname)
end do
;/
print("... doing basin-mean statistics2")
outputname=csvdir+"/"+"metrics_climo_mean2.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2,LatGen,LMI,Length >> "+outputname)
do mm = 0,nfiles-1
  OUTSTR=strs(mm)+delim+ \
    avgStorms(mm)+delim+ \
    avgTcd(mm)+delim+ \
    avgAce(mm)+delim+ \
    avgPace(mm)+delim+ \
    avgLatgen(mm)+delim+ \
    avgLMI(mm)+delim+ \
    avgLength(mm)
  system("echo "+OUTSTR+" >> "+outputname)
end do


print("... doing spatial correlation and Taylor")
outputname=csvdir+"/"+"metrics_temporal_pcorr.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
print("... doing Pearson seasonal cycle.")
do jj = 0,nfiles-1
  OUTSTR=strs(jj)+delim+escorc(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+escorc(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+escorc(aceByMonth(0,:),aceByMonth(jj,:))+delim+escorc(paceByMonth(0,:),paceByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

outputname=csvdir+"/"+"metrics_temporal_scorr.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
print("... doing Spearman seasonal cycle.")
do jj = 0,nfiles-1
  OUTSTR=strs(jj)+delim+spcorr(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+spcorr(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+spcorr(aceByMonth(0,:),aceByMonth(jj,:))+delim+spcorr(paceByMonth(0,:),paceByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

print("... doing interannual")
do jj = 0,nfiles-1
  print(strs(jj)+delim+escorc(stormsByYear(0,:),stormsByYear(jj,:))+delim+escorc(tcdByYear(0,:),tcdByYear(jj,:))+delim+escorc(aceByYear(0,:),aceByYear(jj,:))+delim+escorc(paceByYear(0,:),paceByYear(jj,:)))
end do

wks   = gsn_open_wks ("pdf","./pdfs/xy") 

res                   = True                      ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False
;res@tiMainString      = "TC day seasonal cycle"       ; add title
res@tiMainString      = "ACE seasonal cycle"       ; add title

res@xyMonoDashPattern=True
res@xyMonoLineThickness=True
res@xyLineThicknessF = 5.0

res@trYMinF=0.0

res@xyLineColors      = linecolors

res@tiXAxisString = "Month"
res@tiYAxisString = "ACE (10~S~4~N~ kn~S~2~N~)"
;res@tiYAxisString = "TC Days"

res@trXMinF = 1
res@trXMaxF = 12

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
