;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
out_type = "pdf"
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
trajDir="./TRAJ_FINAL/"
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
filename = "hyp_configs.csv"
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

;=================== Init arrays ================================

nfiles=dimsizes(files)

; Init PAIRED per year arrays
stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
paceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")

; Init per month arrays
stormsByMonth=new((/nfiles,nmonths/),"float")
aceByMonth=new((/nfiles,nmonths/),"float")
paceByMonth=new((/nfiles,nmonths/),"float")
tcdByMonth=new((/nfiles,nmonths/),"float")

; Init per year arrays
avgStormsPY=new((/nfiles/),"float")
avgTcdPY=new((/nfiles/),"float")
avgAcePY=new((/nfiles/),"float")
avgPacePY=new((/nfiles/),"float")

; Init per storm arrays
avgTcdPS=new((/nfiles/),"float")
avgLmiPS=new((/nfiles/),"float")
avgAcePS=new((/nfiles/),"float")
avgPacePS=new((/nfiles/),"float")
avgLatgenPS=new((/nfiles/),"float")

;=================== Loop over data files ================================

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

  ; get nstorms + ntimes (max) from dims of one of the returned arrays
  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

  ; if basin filtering requested, loop over all storms to filter using TC mask
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
    xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
    xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)

    xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
    xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
  end if

  ; Get location of maximum intensity
  xlatmi=new(nstorms,typeof(xlat))
  xlonmi=xlatmi
  do kk = 0,nstorms-1
    if(.not.all(ismissing(xpres(kk,:)))) then
      locMI=minind(xpres(kk,:))
      ;print(""+locMI)
      xlatmi(kk)=xlat(kk,locMI)
      xlonmi(kk)=xlon(kk,locMI)
    end if
  end do

  ; Count the number of TC days per storm (i.e., trajectory length)
  xtcd = xwind
  xtcd = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  ; Get genesis latitude and longitude
  xlon  := xlon(:,0)
  xlat  := xlat(:,0)

  xace  := 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
  xace = where(ismissing(xace) .and. .not.(ismissing(xlon)),0.0,xace)
  ; if ace is missing BUT xlon is not missing (storm in this basin) set ACE to zero
  ; if xlon is missing, will leave ace as missing since storm isn't in basin

  ;do jj=0,nstorms-1
  ;  print(xlon(jj,:)+" "+xlat(jj,:)+" "+xwind(jj,:)+" "+tostring(1e-4*(ms_to_kts*xwind(jj,:))^2.))
  ;end do

  print("min: "+min(xpres)+"   max: "+max(xpres))
  xprestmp = where(xpres.lt.1010,xpres,1010.)
  xpace := 1e-4*dim_sum_n( (4.4*(1010.-xprestmp)^0.76)^2.,1)
  xpace = where(ismissing(xpace) .and. .not.(ismissing(xlon)),0.0,xpace)
  delete(xprestmp)
  print("min: "+min(xpace)+"   max: "+max(xpace))

  xpres := dim_min_n(xpres,1)
  xwind := dim_max_n(xwind,1)
  xtcd  := dim_sum_n(xtcd,1)
  xyear := xyear(:,0)
  xmonth := xmonth(:,0)

  ; Convert to 1-D masked arrays for ease of processing
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

;  print(cace)
;  print(" SUM "+sum(cace)+"")

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

  ; Calculate bulk averages per calendar year
  DENOM=ensmembers(zz)*yearspermember(zz)
  avgStormsPY(zz) = tofloat(num(.not.ismissing(cpres)))/DENOM
  avgTcdPY(zz) = sum(ctcd)/DENOM
  avgPacePY(zz) = sum(cpace)/DENOM
  avgAcePY(zz) = sum(cace)/DENOM

  ; Calculate individual per storm averages
  avgTcdPS(zz) = avg(ctcd)
  avgPacePS(zz) = avg(cpace)
  avgAcePS(zz) = avg(cace)
  avgLmiPS(zz) = avg(abs(clatmi))
  avgLatgenPS(zz) = avg(abs(clat))

  delete([/xlon,xlat,xpres,xwind,xace,xpace,xyear,xmonth,xtcd,xlatmi,xlonmi/])
  delete([/clon,clat,cpres,cwind,cace,cpace,cyear,cmonth,ctcd,clatmi,clonmi/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/thisYr/])

  print("---------------------------------------------------- DONE")
end do

; if we don't have any storms, assume we didn't have data for year...
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
  ;print(yearArr+" "+stormsByYear(mm,:)+" "+aceByYear(mm,:)+" "+tcdByYear(mm,:))
end do

;print("Bias correction.")
;stormsCorrected=tofloat(stormsByYear)
;sumobs=avg(stormsCorrected(0,:))
;do kk = 1,nfiles-1
;  summod=avg(stormsCorrected(kk,:))
;  ratio=sumobs/summod
;  stormsCorrected(kk,:)=ratio*stormsCorrected(kk,:)
;end do

print("Setting CSV parameters")
quote = inttochar(34)
delim=","
OPT=0

;; this is MATCHED basin mean statistics, i.e., only overlapping years
;; so if ibtracs is 1980-2000 but model is only 1988-1990, n = 3 and match those years.
print("... doing PAIRED basin-mean statistics")
outputname=csvdir+"/"+"metrics_climo_pairmean.csv"
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
print("... doing un-paired basin-mean statistics")
outputname=csvdir+"/"+"metrics_climo_mean.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
do mm = 0,nfiles-1
  OUTSTR=strs(mm)+delim+ \
    avgStormsPY(mm)+delim+ \
    avgTcdPY(mm)+delim+ \
    avgAcePY(mm)+delim+ \
    avgPacePY(mm)
  system("echo "+OUTSTR+" >> "+outputname)
end do

print("... doing un-paired storm-mean statistics")
outputname=csvdir+"/"+"metrics_storm_mean.csv"
system("rm "+outputname)
system("echo ,Model,TCDays,ACE1,ACE2,LatGen,LMI >> "+outputname)
do mm = 0,nfiles-1
  OUTSTR=strs(mm)+delim+ \
    avgTcdPS(mm)+delim+ \
    avgAcePS(mm)+delim+ \
    avgPacePS(mm)+delim+ \
    avgLatgenPS(mm)+delim+ \
    avgLmiPS(mm)
  system("echo "+OUTSTR+" >> "+outputname)
end do

outputname=csvdir+"/"+"metrics_temporal_pcorr.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
print("... doing Pearson seasonal cycle correlation.")
do jj = 0,nfiles-1
  OUTSTR=strs(jj)+delim+escorc(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+escorc(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+escorc(aceByMonth(0,:),aceByMonth(jj,:))+delim+escorc(paceByMonth(0,:),paceByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

outputname=csvdir+"/"+"metrics_temporal_scorr.csv"
system("rm "+outputname)
system("echo ,Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
print("... doing Spearman seasonal cycle correlation.")
do jj = 0,nfiles-1
  OUTSTR=strs(jj)+delim+spcorr(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+spcorr(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+spcorr(aceByMonth(0,:),aceByMonth(jj,:))+delim+spcorr(paceByMonth(0,:),paceByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

print("... doing interannual linear correlation")
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
