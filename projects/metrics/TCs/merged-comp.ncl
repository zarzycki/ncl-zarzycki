;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"
load "./taylor_diagram_cam.ncl"

begin

;=================== User Settings ================================

out_type = "pdf"
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
trajDir="./TRAJ_FINAL/"
csvdir="./csv-files/"
gridsize = 8.0
;basin=(/1,2,3,4/)
basin=1
filename = "hyp_configs.csv"

defineMIbypres=False

;======================= Constants ================================
ms_to_kts = 1.94384449

; this is really only for correlations
styr=1980
enyr=2016
nyears=enyr-styr+1
yearArr=ispan(styr,enyr,1)

stmon=1
enmon=12
nmonths=enmon-stmon+1
monArr=ispan(stmon,enmon,1)

;======================= Masking ================================

if (any(basin.gt.0)) then
  if (dimsizes(basin) .eq. 1) then
    basinstr=getbasinmaskstr(basin)
  else
    basinstr="user"
  end if
else
  basinstr="GLOB"
end if
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
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

;=================== Internal logic ================================

namesplit = get_file_suffix(filename,0)
basecsv = namesplit@fBase

;=================== Init arrays ================================

nfiles=dimsizes(files)

; Init PAIRED per year arrays
stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
paceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")
lmiByYear=new((/nfiles,nyears/),"float")

; Init per month arrays
stormsByMonth=new((/nfiles,nmonths/),"float")
aceByMonth=new((/nfiles,nmonths/),"float")
paceByMonth=new((/nfiles,nmonths/),"float")
tcdByMonth=new((/nfiles,nmonths/),"float")
lmiByMonth=new((/nfiles,nmonths/),"float")

; Init per year arrays
avgStormsPY=new((/nfiles/),"float")
avgTcdPY=new((/nfiles/),"float")
avgAcePY=new((/nfiles/),"float")
avgPacePY=new((/nfiles/),"float")
avgLmiPY=new((/nfiles/),"float")

; Init per storm arrays
avgTcdPS=new((/nfiles/),"float")
avgLmiPS=new((/nfiles/),"float")
avgAcePS=new((/nfiles/),"float")
avgPacePS=new((/nfiles/),"float")
avgLatgenPS=new((/nfiles/),"float")

;=================== Loop over data files ================================

valid_files=new(nfiles,"integer")

do zz = 0,nfiles-1
if (str_get_cols(files(zz),0,0).ne."!") then

  valid_files(zz) = zz

  print("    starting "+zz+" of "+(nfiles-1))

  nmodyears=ensmembers(zz)*yearspermember(zz)
  wind_factor = windcorrs(zz)

  thefile=trajDir+"/"+files(zz)

  print("******************************************************")
  print("analyzing: "+thefile)
  print("... contains "+nmodyears+" years of analysis")
  print("Is grid unstructured? "+isUnstruct(zz))
  print("corr wind: "+wind_factor)
  print("******************************************************")

  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)



  ; load in trajectory data (need to be modified if using different tempest output
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres  = tofloat(traj_data(:,4,:))/100.
  xwind  = traj_data(:,5,:)*wind_factor
  xyear  = toint(traj_data(:,7,:))
  xmonth  = toint(traj_data(:,8,:))
  xday  = toint(traj_data(:,9,:))
  xhour  = toint(traj_data(:,10,:))

  ; get nstorms + ntimes (max) from dims of one of the returned arrays
  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

  ; Get genesis latitude and longitude
  ; Note, we scan for genesis locations that may not occur at time t=0 due to filtering
  xlontmp=xlon
  xlattmp=xlat
  xyeartmp=xyear
  xmonthtmp=xmonth
  do kk = 0,nstorms-1
    indtmp=ind(.not.ismissing(xlon(kk,:)))
    if (.not.all(ismissing(indtmp)))
      xlontmp(kk,0)=xlon(kk,indtmp(0))
      xlattmp(kk,0)=xlat(kk,indtmp(0))
      xmonthtmp(kk,0)=xmonth(kk,indtmp(0))
      xyeartmp(kk,0)=xyear(kk,indtmp(0))
    end if
    delete(indtmp)
  end do
  xglon   = xlontmp(:,0)
  xglat   = xlattmp(:,0)
  xgyear  = xyeartmp(:,0)
  xgmonth = xmonthtmp(:,0)
  delete([/xlontmp,xlattmp,xmonthtmp,xyeartmp/])

  ; if basin filtering requested, loop over all storms to filter using TC mask
  if (any(basin .gt. 0)) then
    do ii = 0,nstorms-1
      orilat=xglat(ii)
      orilon=xglon(ii)
      if (orilon .gt. 360.0-maskspacing) then
        orilon=360.0-maskspacing
        print("    original lon: "+xglon(ii)+"   modified lon: "+orilon)
      end if
      if (all(basin .ne. tcMask({orilat},{orilon}))) then
        xlon(ii,:)=xlon@_FillValue
        xlat(ii,:)=xlat@_FillValue
        xpres(ii,:)=xpres@_FillValue
        xwind(ii,:)=xwind@_FillValue
        xyear(ii,:)=xyear@_FillValue
        xmonth(ii,:)=xmonth@_FillValue
        xglon(ii)=xglon@_FillValue
        xglat(ii)=xglat@_FillValue
        xgyear(ii)=xgyear@_FillValue
        xgmonth(ii)=xgmonth@_FillValue
      end if
    end do
  end if

  ; Filter observational records
  if (zz.eq.0) then
    xlon=where(xwind.gt.35/ms_to_kts,xlon,xlon@_FillValue)
    xlat=where(xwind.gt.35/ms_to_kts,xlat,xlat@_FillValue)
    xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
    xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)

    xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
    xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
    xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
    xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
  end if

  ; Get location of maximum intensity for each trajectory
  xlatmi=new(nstorms,typeof(xlat))
  xlonmi=xlatmi
  do kk = 0,nstorms-1
    if(.not.all(ismissing(xpres(kk,:)))) then
      if defineMIbypres then
        locMI=minind(xpres(kk,:))
      else
        locMI=maxind(xwind(kk,:))
      end if
      xlatmi(kk)=xlat(kk,locMI)
      xlonmi(kk)=xlon(kk,locMI)
    end if
  end do

  abs_LMI=True
  if abs_LMI then
    xlatmi=abs(xlatmi)
  end if

  ; Count the number of TC days per storm (i.e., trajectory length)
  xtcdpp = xwind
  xtcdpp = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  ; Calculate ACE for each storm
  xace = 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
  ; if ace is missing BUT xlon is not missing (storm in this basin) set ACE to zero
  ; if xlon is missing, will leave ace as missing since storm isn't in basin
  xace = where(ismissing(xace) .and. .not.(ismissing(xglon)),0.0,xace)

  ; Calculate PACE for each storm
  calcPolyFitPACE=True
  if calcPolyFitPACE then
    if (zz .eq. 0) then
      print("Calculating regression for best-fit line")
      polyn = 3
      xprestmp = where(xpres.lt.1010,xpres,1010.)
      quad_a = lspoly(ndtooned(xpres), ndtooned(xwind) , 1, polyn)
    end if
    xwindtmp = quad_a(0) + quad_a(1)*xpres + quad_a(2)*xpres^2
    xpace = 1e-4*dim_sum_n((ms_to_kts*xwindtmp)^2.,1)
    delete(xwindtmp)
  else
    ;print("min: "+min(xpres)+"   max: "+max(xpres))
    xpace = 1e-4*dim_sum_n( (4.4*(1010.-xprestmp)^0.76)^2.,1)
    xpace = where(ismissing(xpace) .and. .not.(ismissing(xglon)),0.0,xpace)
    delete(xprestmp)
    ;print("min: "+min(xpace)+"   max: "+max(xpace))
  end if


  ; Find maximum intensity, integrated TC days, and genesis year/month
  xmpres  = dim_min_n(xpres,1)
  xmwind  = dim_max_n(xwind,1)
  xtcd    = dim_sum_n(xtcdpp,1)

  ; Convert to 1-D masked arrays for ease of processing
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  clatmi = ndtooned(xlatmi)
  clonmi = ndtooned(xlonmi)
  cglat = ndtooned(xglat)
  cglon = ndtooned(xglon)
  cpres = ndtooned(xpres)
  cwind = ndtooned(xwind)
  cmpres = ndtooned(xmpres)
  cmwind = ndtooned(xmwind)
  ctcd = ndtooned(xtcd)
  cace = ndtooned(xace)
  cpace = ndtooned(xpace)
  cgyear = ndtooned(xgyear)
  cgmonth = ndtooned(xgmonth)

  do ii = 0,nyears-1
    thisYr=ii+styr

    stormsByYear(zz,ii)=num(cgyear.eq.thisYr)

    tmpace=where(cgyear.eq.thisYr,cace,cace@_FillValue)
    aceByYear(zz,ii)=sum(tmpace)

    tmppace=where(cgyear.eq.thisYr,cpace,cpace@_FillValue)
    paceByYear(zz,ii)=sum(tmppace)

    tmptcd=where(cgyear.eq.thisYr,ctcd,ctcd@_FillValue)
    tcdByYear(zz,ii)=sum(tmptcd)

    tmplmi=where(cgyear.eq.thisYr,clatmi,clatmi@_FillValue)
    lmiByYear(zz,ii)=avg(tmplmi)

    delete([/tmpace,tmppace,tmptcd,tmplmi/])
  end do

  do ii = 1,nmonths
    stormsByMonth(zz,ii-1)=num(cgmonth.eq.ii)

    tmpace=where(cgmonth.eq.ii,cace,cace@_FillValue)
    aceByMonth(zz,ii-1)=sum(tmpace)

    tmppace=where(cgmonth.eq.ii,cpace,cpace@_FillValue)
    paceByMonth(zz,ii-1)=sum(tmppace)

    tmptcd=where(cgmonth.eq.ii,ctcd,ctcd@_FillValue)
    tcdByMonth(zz,ii-1)=sum(tmptcd)

    tmplmi=where(cgmonth.eq.ii,clatmi,clatmi@_FillValue)
    lmiByMonth(zz,ii-1)=avg(tmplmi)

    delete([/tmpace,tmppace,tmptcd,tmplmi/])
  end do

  ; Calculate bulk averages per calendar year
  avgStormsPY(zz) = tofloat(num(.not.ismissing(cmpres)))/nmodyears
  avgTcdPY(zz) = sum(ctcd)/nmodyears
  avgPacePY(zz) = sum(cpace)/nmodyears
  avgAcePY(zz) = sum(cace)/nmodyears
  avgLmiPY(zz) = avg(clatmi)

  ; Calculate individual per storm averages
  avgTcdPS(zz) = avg(ctcd)
  avgPacePS(zz) = avg(cpace)
  avgAcePS(zz) = avg(cace)
  avgLmiPS(zz) = avg(abs(clatmi))
  avgLatgenPS(zz) = avg(abs(cglat))

  trackdens = track_density(gridsize,0.0,clat,clon,False)
  trackdens = trackdens/nmodyears

  gendens = track_density(gridsize,0.0,cglat,cglon,False)
  gendens = gendens/nmodyears

  minpres = track_minmax(gridsize,0.0,clat,clon,cpres,"min",20)
  maxwind = track_minmax(gridsize,0.0,clat,clon,cwind,"max",20)

  if (sum(trackdens).eq.0) then
    trackdens=trackdens@_FillValue
    gendens=trackdens@_FillValue
    minpres=trackdens@_FillValue
    maxwind=trackdens@_FillValue
  end if

  if (zz.eq.0) then
    print("Generating cosine weights...")
    deg2rad = get_d2r("float")
    denslatwgt = cos(deg2rad*trackdens&lat)
  end if

  ; if first data file, build structure to hold all density grids
  if (zz.eq.0) then
    tmpdims=dimsizes(trackdens)
    fulldens=new((/nfiles,tmpdims(0),tmpdims(1)/),typeof(trackdens))
    fulldens!1="lat"
    fulldens!2="lon"
    fulldens&lat=trackdens&lat
    fulldens&lon=trackdens&lon
    fullpres=fulldens
    fullwind=fulldens
    fullgen=fulldens
    delete(tmpdims)
  end if
  
  fulldens(zz,:,:)=trackdens(:,:)
  fullpres(zz,:,:)=minpres(:,:)
  fullwind(zz,:,:)=maxwind(:,:)
  fullgen(zz,:,:)=gendens(:,:)

spapltvarsstr=(/"trackdens","minpres","maxwind","gendens"/)
spapltvars=[/ trackdens, minpres, maxwind, gendens /] 
spapltmincontour=(/0.,880.,0.,0./)
spapltmaxcontour=(/20.,1010.,100.,1./)
do bb = 0,3
  wks = gsn_open_wks("pdf","./pdfs/"+tostring(spapltvarsstr(bb))+"."+basinstr+"_"+files(zz))
  plot = new(1,"graphic")
  ;print(spapltvars[bb])
  toPlot=spapltvars[bb]
  toPlot = where(toPlot.gt.0.,toPlot,toPlot@_FillValue)
  colorMap1="WhiteBlueGreenYellowRed"
  ;colorMap1="prcp_1"
  res                       = True     ; plot mods desired
  res@gsnDraw = False
  res@gsnFrame = False
  res@gsnAddCyclic          = False    
  res@cnFillOn              = True     ; turn on color fill
  res@cnFillMode            = "RasterFill"       ; Raster Mode
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnLineLabelsOn  = False
  res@lbLabelStride = 2
  res@gsnCenterString       = ""
  ;res@mpMinLatF             = 5.
  ;res@mpMaxLatF             = 55.
  ;res@mpMinLonF             = 260.
  ;res@mpMaxLonF             = 350.
  res@mpMinLatF             = -60.
  res@mpMaxLatF             = 60.
  res@mpMinLonF             = 0.
  res@mpMaxLonF             = 360.
  res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = spapltmincontour(bb)
  ;res@cnMaxLevelValF        = 20.0
  res@cnMaxLevelValF        = spapltmaxcontour(bb)
  res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 10.
  res@cnFillPalette=colorMap1
  plot(0) = gsn_csm_contour_map_ce(wks,toPlot,res)
  resP=True
  resP@txString           = "Annual TC track density, all storms"
  resP@amJust           = "TopLeft"
  gsn_panel(wks,plot,(/1,1/),resP)

end do

  ; clean up arrays before returning to start of loop
  delete([/xtcdpp,xyear,xmonth,xhour,xday/])
  delete([/xlon,xlat,xpres,xwind,xace,xpace,xtcd,xlatmi,xlonmi,xglon,xglat,xmpres,xmwind,xgyear,xgmonth/])
  delete([/clon,clat,cpres,cwind,cace,cpace,ctcd,clatmi,clonmi,cglon,cglat,cmpres,cmwind,cgyear,cgmonth/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/thisYr/])
  delete([/trackdens,minpres,maxwind/])

  print("---------------------------------------------------- DONE")

end if
end do

; Eliminate files that were not valid for some reason
iz = ind(.not.ismissing(valid_files)) 
valid_files := valid_files(iz)
valid_strs := strs(iz)
nfiles=dimsizes(valid_files)

; if we don't have any storms, assume we didn't have data for year...
stormsByYear=where(stormsByYear.eq.0,stormsByYear@_FillValue,stormsByYear)

print("Correcting for number of ensemble members")
do qq = 0,nfiles-1
  mm = valid_files(qq)
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
outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_climo_pairmean.csv"
system("rm "+outputname)
system("echo Model,Count,TCDays,ACE1,ACE2 >> "+outputname)
do qq = 0,nfiles-1
  mm = valid_files(qq)
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
;>print("... doing basin-mean statistics2")
;>outputname=csvdir+"/"+"metrics_climo_mean2.csv"
;>system("rm "+outputname)
;>system("echo ,Model,Count,TCDays,ACE1,ACE2,Length >> "+outputname)
;>do mm = 1,nfiles-1
;>  OUTSTR=strs(mm)+delim+ \
;>    (avgStorms(mm)-avgStorms(0))+delim+ \
;>    (avgTcd(mm)-avgTcd(0))+delim+ \
;>    (avgAce(mm)-avgAce(0))+delim+ \
;>    (avgPace(mm)-avgPace(0))+delim+ \
;>    (avgLatgen(mm)-avgLatgen(0))+delim+ \
;>    (avgLMI(mm)-avgLMI(0))+delim+ \
;>    (avgLength(mm)-avgLength(0))
;>  system("echo "+OUTSTR+" >> "+outputname)
;>end do


print("... doing un-paired basin-mean statistics")
outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_climo_mean.csv"
system("rm "+outputname)
system("echo Model,Count,TCDays,ACE1,ACE2,LMI >> "+outputname)
do qq = 0,nfiles-1
  mm = valid_files(qq)
  OUTSTR=strs(mm)+delim+ \
    avgStormsPY(mm)+delim+ \
    avgTcdPY(mm)+delim+ \
    avgAcePY(mm)+delim+ \
    avgPacePY(mm)+delim+ \
    avgLmiPY(mm)
  system("echo "+OUTSTR+" >> "+outputname)
end do

print("... doing un-paired storm-mean statistics")
outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_storm_mean.csv"
system("rm "+outputname)
system("echo Model,TCDays,ACE1,ACE2,LatGen,LMI >> "+outputname)
do qq = 0,nfiles-1
  mm = valid_files(qq)
  OUTSTR=strs(mm)+delim+ \
    avgTcdPS(mm)+delim+ \
    avgAcePS(mm)+delim+ \
    avgPacePS(mm)+delim+ \
    avgLatgenPS(mm)+delim+ \
    avgLmiPS(mm)
  system("echo "+OUTSTR+" >> "+outputname)
end do

outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_temporal_pcorr.csv"
system("rm "+outputname)
system("echo Model,Count,TCDays,ACE1,ACE2,LMI >> "+outputname)
print("... doing Pearson seasonal cycle correlation.")
do qq = 0,nfiles-1
  jj = valid_files(qq)
  OUTSTR=strs(jj)+delim+escorc(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+escorc(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+escorc(aceByMonth(0,:),aceByMonth(jj,:))+delim+escorc(paceByMonth(0,:),paceByMonth(jj,:))+delim+escorc(lmiByMonth(0,:),lmiByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_temporal_scorr.csv"
system("rm "+outputname)
system("echo Model,Count,TCDays,ACE1,ACE2,LMI >> "+outputname)
print("... doing Spearman seasonal cycle correlation.")
do qq = 0,nfiles-1
  jj = valid_files(qq)
  OUTSTR=strs(jj)+delim+spcorr(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+spcorr(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+spcorr(aceByMonth(0,:),aceByMonth(jj,:))+delim+spcorr(paceByMonth(0,:),paceByMonth(jj,:))+delim+spcorr(lmiByMonth(0,:),lmiByMonth(jj,:))
  system("echo "+OUTSTR+" >> "+outputname)
end do

;print("... doing interannual linear correlation")
;do jj = 0,nfiles-1
;  print(strs(jj)+delim+escorc(stormsByYear(0,:),stormsByYear(jj,:))+delim+escorc(tcdByYear(0,:),tcdByYear(jj,:))+delim+escorc(aceByYear(0,:),aceByYear(jj,:))+delim+escorc(paceByYear(0,:),paceByYear(jj,:)))
;end do

;; PATTERN STUFF

taylor_cco=new((/2,nfiles-1/),"float")
taylor_rat=new((/2,nfiles-1/),"float")
taylor_bia=new((/2,nfiles-1/),"float")
taylor_rms=new((/2,nfiles-1/),"float")

print("... doing spatial correlation and Taylor")
outputname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_spatial_corr.csv"
quote = inttochar(34)
delim=","
OPT=0
system("rm "+outputname)
system("echo Model,Track,Genesis,U10,SLP >> "+outputname)
do qq = 0,nfiles-1
  mm = valid_files(qq)
  tmprefr=fulldens(0,:,:)
  tmptest=fulldens(mm,:,:)
  tmprefr=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmprefr@_FillValue,tmprefr)
  tmptest=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmptest@_FillValue,tmptest)
  tm2refr=fullgen(0,:,:)
  tm2test=fullgen(mm,:,:)
  tm2refr=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2refr@_FillValue,tm2refr)
  tm2test=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2test@_FillValue,tm2test)

  taylorVals=taylor_stats(tmptest,tmprefr,denslatwgt,1)
  
  if (mm .ne. 0) then
    taylor_cco(0,qq-1)=taylorVals(0)
    taylor_rat(0,qq-1)=taylorVals(1)
    taylor_bia(0,qq-1)=taylorVals(2)
    taylor_rms(0,qq-1)=taylorVals(7);/stddev(tmptest)
  end if

  ; these are equivalent...
  ;pattern_cor(tmprefr,tmptest,denslatwgt,OPT)
  ;taylor_cco(0,mm-1)

  OUTSTR=strs(mm)+delim+ \
    pattern_cor(tmprefr,tmptest,denslatwgt,OPT)+delim+ \
    pattern_cor(fullpres(0,:,:),fullpres(mm,:,:),denslatwgt,OPT)+delim+ \
    pattern_cor(fullwind(0,:,:),fullwind(mm,:,:),denslatwgt,OPT)+delim+ \
    pattern_cor(tm2refr,tm2test,denslatwgt,OPT)
  print(OUTSTR+"")
  system("echo "+OUTSTR+" >> "+outputname)

  ;taylorVals=taylor_stats(tm2test,tm2refr,1.,0)
  ;taylor_cco(1,mm-1)=taylorVals(0)
  ;taylor_rat(1,mm-1)=taylorVals(1)
end do


dimslatlon=dimsizes(fulldens(0,:,:))
print("... doing RMSE")
outrmsname=csvdir+"/"+"metrics_"+basecsv+"_"+basinstr+"_spatial_rmse.csv"
system("rm "+outrmsname)
system("echo Model,Track,Genesis,U10,SLP >> "+outrmsname)
do qq = 0,nfiles-1
  mm = valid_files(qq)
  tmprefr=fulldens(0,:,:)
  tmptest=fulldens(mm,:,:)
  tmprefr=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmprefr@_FillValue,tmprefr)
  tmptest=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmptest@_FillValue,tmptest)

  ;rmean   = avg(tmprefr)            ; area weighted means
  ;tmean   = avg(tmptest)
  ;tmprefr=tmprefr-rmean
  ;tmptest=tmptest-tmean
  ;print(sqrt(sum(tmptest^2)/sum(tmprefr^2)))

  tm2refr=fullgen(0,:,:)
  tm2test=fullgen(mm,:,:)
  tm2refr=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2refr@_FillValue,tm2refr)
  tm2test=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2test@_FillValue,tm2test)
;  OUTSTR=strs(mm)+delim+wgt_arearmse2(tmprefr,tmptest,conform_dims(dimslatlon,denslatwgt,0),0)+delim+ \

  ; these are equivalent...
  ;wgt_arearmse2(tmprefr,tmptest,conform_dims(dimslatlon,denslatwgt,0),0)
  ;taylor_rms(0,mm-1)

    ;wgt_arearmse2(tmprefr,tmptest,conform_dims(dimslatlon,denslatwgt,0),0)/stddev(tmptest)+delim+ \
    ;wgt_arearmse2(fullpres(0,:,:),fullpres(mm,:,:),conform_dims(dimslatlon,denslatwgt,0),0)/stddev(fullpres(mm,:,:))+delim+ \
    ;wgt_arearmse2(fullwind(0,:,:),fullwind(mm,:,:),conform_dims(dimslatlon,denslatwgt,0),0)/stddev(fullwind(mm,:,:))+delim+ \
    ;wgt_arearmse2(tm2refr,tm2test,conform_dims(dimslatlon,denslatwgt,0),0)/stddev(tm2test)
  OUTSTR=strs(mm)+delim+ \
    wgt_arearmse2(tmprefr,tmptest,conform_dims(dimslatlon,denslatwgt,0),0)/ (max(tmptest)-min(tmptest)) +delim+ \
    wgt_arearmse2(fullpres(0,:,:),fullpres(mm,:,:),conform_dims(dimslatlon,denslatwgt,0),0)/(max(fullpres(mm,:,:))-min(fullpres(mm,:,:)))+delim+ \
    wgt_arearmse2(fullwind(0,:,:),fullwind(mm,:,:),conform_dims(dimslatlon,denslatwgt,0),0)/(max(fullwind(mm,:,:))-min(fullwind(mm,:,:)))+delim+ \
    wgt_arearmse2(tm2refr,tm2test,conform_dims(dimslatlon,denslatwgt,0),0)/(max(tm2test)-min(tm2test))
  print(OUTSTR+"")
  system("echo "+OUTSTR+" >> "+outrmsname)
end do

; do some additional taylor stats

taylor_bia2=new((/2,nfiles-1/),"float")
do qq = 1,nfiles-1
  mm = valid_files(qq)
  taylor_bia2(0,qq-1)=100.*(avgStormsPY(mm)-avgStormsPY(0))/avgStormsPY(0)
end do

; plot Taylor diagram
wks   = gsn_open_wks("pdf","./pdfs/taylor_"+basecsv+"_"+basinstr)      ; send graphics to PNG file
res   = True
res@txFontHeightF = 0.02
res@markerTxYOffset = 0.03
res@Colors = (/"blue","red"/)
res@varLabels = valid_strs(1:nfiles-1)  ; don't include obs
plot  = taylor_diagram_cam(wks, taylor_rat, taylor_cco, taylor_bia2, res)

print(res@varLabels+" ")
print(taylor_rat+" "+taylor_cco+" "+taylor_bia+" "+taylor_bia2)
end
