load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"

begin 



;yyyy=1986  ;max for gx1v6 is 1994 it appears
conv=86400000.
numberBins=20
wind_factor = "log"
thresh=33.0
sizeond=10000   ;1 year seems to be around 4-6k with no thresh

; Get wind factor to correct from UBOT to U10
factor = surfaceWindCorrFactor(-1,-1,wind_factor)

lat=new((/2,sizeond/),"float")
lon=new((/2,sizeond/),"float")
time=new((/2,sizeond/),"double")
prect=new((/2,sizeond/),"float")
yyyy_arr=new((/2,sizeond/),"float")
mm_arr=new((/2,sizeond/),"float")
dd_arr=new((/2,sizeond/),"float")
hh_arr=new((/2,sizeond/),"float")

do z = 0,1
  counter=0
  if z .eq. 0 then             
    f1=addfile("/glade/u/home/zarzycki/work/atm-ocn-coupling/tracking/FAMIPC5_ne120_79to05_03_omp2_10m_tracfile.nc","r")
  else
    f1=addfile("/glade/u/home/zarzycki/work/atm-ocn-coupling/tracking/f.e13.FAMIPC5.ne120_ne120.1979_2012.002_tracfile.nc","r")
  end if
  wind1=f1->wind*factor
  windSize=dimsizes(wind1)
  nstorms=windSize(0)
  ntimes=windSize(1)
  delete(windSize)
  lat1=f1->lat
  lon1=f1->lon

  time1=f1->source_time
  utctime1=cd_calendar(time1,0)
  printVarSummary(utctime1)
  yyyy1=utctime1(:,:,0)
  mm1=utctime1(:,:,1)
  dd1=utctime1(:,:,2)
  hh1=utctime1(:,:,3)


  do i = 0,nstorms-1
    ;print(wind1(i,:))
    ;print(utctime1(i,:,0)+" "+utctime1(i,:,1)+" "+utctime1(i,:,2)+" "+utctime1(i,:,3)+" "+utctime1(i,:,4))
  do j = 0,ntimes-1
    if (.not.ismissing(wind1(i,j)) .and. wind1(i,j) .ge. thresh .and. yyyy1(i,j) .eq. yyyy) then
      lat1(i,j)=lat1(i,j)
      lon1(i,j)=lon1(i,j)
      lat(z,counter)=tofloat(lat1(i,j))
      lon(z,counter)=tofloat(lon1(i,j))
      time(z,counter)=time1(i,j)
      yyyy_arr(z,counter)=yyyy1(i,j)
      mm_arr(z,counter)=mm1(i,j)
      dd_arr(z,counter)=dd1(i,j)
      hh_arr(z,counter)=hh1(i,j)
      counter=counter+1
    else
      lat1(i,j)=lat1@_FillValue
      lon1(i,j)=lat1@_FillValue 
    end if
  end do
  end do

  ;onedlat=ndtooned(lat1)
  ;onedlon=ndtooned(lon1)
  ;print(num(.not.ismissing(onedlat)))
  ;delete(onedlat)
  ;delete(onedlon)
  print("num counted "+counter)
  ;print(lat(z,:))
  delete([/wind1,nstorms,ntimes,time1,utctime1,yyyy1,mm1,dd1,hh1,lat1,lon1/])

end do
             

deltaDeg=2.0
     
ne120_ne120_files = systemfunc ("ls /glade/p/cgd/ccr/f.e13.FAMIPC5.ne120_ne120.1979_2012.002/atm/proc/tseries/hourly3_regrid/f.e13.FAMIPC5.ne120_ne120.1979_2012.002.cam.h4.PRECT."+yyyy+"010100Z-"+yyyy+"123121Z.nc")
ne120_ne120_all   = addfiles (ne120_ne120_files, "r")
ListSetType (ne120_ne120_all, "cat")
ne120_time=ne120_ne120_all[:]->time
cal=1
cal@calendar="noleap"
do k = 0,sizeond-1
  if(.not.ismissing(lat(1,k))) then
    thisTime=cd_inv_calendar(toint(yyyy_arr(1,k)),toint(mm_arr(1,k)),toint(dd_arr(1,k)),toint(hh_arr(1,k)),0,0,ne120_time@units,cal)
    prect(1,k)=avg(ne120_ne120_all[:]->PRECT({thisTime},{lat(1,k)-deltaDeg:lat(1,k)+deltaDeg},{lon(1,k)-deltaDeg:lon(1,k)+deltaDeg}))
  end if
end do

ne120_gx1v6_files = systemfunc ("ls /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/regrid/FAMIPC5_ne120_79to05_03_omp2.cam.h4."+yyyy+"*_PRECT.nc")
;ne120_gx1v6_files = systemfunc ("ls /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/regrid/FAMIPC5_ne120_79to05_03_omp2.cam.h4."+yyyy+"*0.nc")
ne120_gx1v6_all   = addfiles (ne120_gx1v6_files, "r")
ListSetType (ne120_gx1v6_all, "cat")
gx1v6_time=ne120_gx1v6_all[:]->time
cal=1
cal@calendar="noleap"
do k = 0,sizeond-1
  if(.not.ismissing(lat(0,k))) then
    thisTime=cd_inv_calendar(toint(yyyy_arr(0,k)),toint(mm_arr(0,k)),toint(dd_arr(0,k)),toint(hh_arr(0,k)),0,0,gx1v6_time@units,cal)
    prect(0,k)=avg(ne120_gx1v6_all[:]->PRECT({thisTime},{lat(0,k)-deltaDeg:lat(0,k)+deltaDeg},{lon(0,k)-deltaDeg:lon(0,k)+deltaDeg}))
  end if
end do

prect=prect*conv

print("ne120 avg: "+avg(prect(1,:)))
print("gx1v6 avg: "+avg(prect(0,:)))

ne120 = pdfx(prect(1,:), numberBins, False)
gx1v6 = pdfx(prect(0,:), numberBins, False)

nVar    = 2
nBin    = gx1v6@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(gx1v6))

xx(0,:) = gx1v6@bin_center
xx(1,:) = ne120@bin_center

yy      = new ( (/nVar, nBin/), typeof(gx1v6))
yy(0,:) = (/ gx1v6 /)
yy(1,:) = (/ ne120 /)

wks  = gsn_open_wks ("pdf","PRECT_freq_histo_"+yyyy)
res  = True
res@xyLineThicknesses        = (/2.0,2.0,2.0,2.0/)
res@xyLineColors             = (/"blue","red"/)
res@xyMonoDashPattern        = True              ; all solid
res@tiYAxisString            = "PDF (%)"

res@gsnXYBarChart            = True              ; Create bar plot
res@gsnXYBarChartOutlineOnly = True

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of
res@pmLegendParallelPosF   = .25                 ; move units right
res@pmLegendOrthogonalPosF = -0.4                ; move units down
res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height
res@xyExplicitLegendLabels = (/"gx1v6","ne120"/)  ; create explicit labels

xx = where(xx.le.0, 1.e-10, xx)
yy = where(yy.le.0, 1.e-10, yy)
res@trXMinF           = 30.
res@trXMaxF           = 900.
res@trYMinF           = 10.^-4
res@trYMaxF           = 100.
res@xyXStyle          = "Log"
res@xyYStyle          = "Log"

res@tiMainString           = "Precip loading, aquaplanet"
plot = gsn_csm_xy (wks, xx, yy, res)



outFileName="TXT_"+yyyy+".csv"
system("rm "+outFileName)
system("echo "+yyyy+","+avg(prect(0,:))+","+avg(prect(1,:))+","+num(.not.ismissing(prect(0,:)))+","+num(.not.ismissing(prect(1,:))) +" >> "+outFileName)




end

