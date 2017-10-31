load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"

begin 

wind_factor = "log"
out_type="pdf"
thresh=17.5

; Get wind factor to correct from UBOT to U10
factor = surfaceWindCorrFactor(-1,-1,wind_factor)


fq1arr=new((/2,3000/),"integer")
fq1arr=0
legLabels=(/"ne120_gx1v6","ne120_ne120"/)  


do z = 0,1
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

  time1=f1->source_time
  utctime1=cd_calendar(time1,0)
  printVarSummary(utctime1)
  yyyy1=utctime1(:,:,0)


  ;do i = 0,nstorms-1
  ;  ;print(wind1(i,:))
  ;  ;print(utctime1(i,:,0)+" "+utctime1(i,:,1)+" "+utctime1(i,:,2)+" "+utctime1(i,:,3)+" "+utctime1(i,:,4))
  ;do j = 0,ntimes-1
  ;  if (.not.ismissing(wind1(i,j)) .and. wind1(i,j) .ge. thresh) then
  ;    fq1arr(z,i) = fq1arr(z,i)+1
  ;  end if
  ;end do
  ;end do

  fq1arr(z,0:nstorms-1) = dim_num_n(wind1,1)

  delete([/wind1,nstorms,ntimes,time1,utctime1,yyyy1/])

end do

fq1arr=where(fq1arr.eq.0,fq1arr@_FillValue,fq1arr)

print("avg of index 0: "+dim_avg_Wrap(3.*fq1arr(0,:)))
print("stdev of index 0: "+dim_stddev_Wrap(3.*fq1arr(0,:)))

print("avg of index 1: "+dim_avg_Wrap(3.*fq1arr(1,:)))
print("stdev of index 1: "+dim_stddev_Wrap(3.*fq1arr(1,:)))

;; do ibtracs
ibstyr=1980
ibenyr=2005
print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

ibfile = addfile(ibdir+ibfilename,"r")

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat_for_mapping(stix:enix,:)*.01
iblon = ibfile->lon_for_mapping(stix:enix,:)*.01
ibtype = toint(ibfile->nature_for_mapping(stix:enix,:))
ibtime = ibfile->source_time(stix:enix,:)


iblat = where(mod(ibtime,0.25) .ge. 0.00001 .or. mod(ibtime,0.25) .le. -0.00001,iblat@_FillValue,iblat)
iblat = where(ibtype .ne. 0,iblat@_FillValue,iblat)


ibarr = dim_num_n(iblat,1)
ibarr=where(ibarr.eq.0,ibarr@_FillValue,ibarr)
print("avg of ib: "+6.*dim_avg_Wrap(ibarr))
print("stdev of ib: "+6.*dim_stddev_Wrap(ibarr))
exit

ibyear = toint(ibfile->season(stix:enix))
ibtype = toint(ibfile->nature_for_mapping(stix:enix,:))
ibwind = ibfile->source_wind(stix:enix,:,:)*.1/ms_to_kts
ibnamechar = ibfile->name(stix:enix,:)
;ibname = conform(ibwind,ibnamesingle,0)

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

; Need to convert char to str for name
ibname = new(dimsizes(ibyear),"string")
do i = 0,dimsizes(ibyear)-1
  ibname(i)=oneDtostring(ibnamechar(i,:))
  ibname(i)=str_sub_str(ibname(i),",","")
end do
  
; Average over all centers -- for plotting, this is ok even if there
; are small discrepancies
ibwind_ = dim_avg_n_Wrap(ibwind,2)

end
