;========================================================
; stuff here
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

;====== if running in non command line mode, these should be specified...
;whatConfig="fixedSST"
;whatYear=1201
;outDir="/glade/scratch/zarzycki/"

plot_orig_SSTA=False     ; plot original anomaly and diff from slab
plot_diag=False          ; plot SSTcorr and hn
outStride=2              ; 2 = 6hrly, 4 = 12hrly, 8 = daily

;if (whatConfig .eq. "fixedSST")
;  do_corr=False
;else
;  do_corr=True
;end if
;always set do_corr to true if using slab1 config! cmz 2/14/16
do_corr=True

; convert whatyear to int
whatYear=toint(whatYear)

docnFile=addfile("simple-slab-remapped.nc","r")
hn=docnFile->hn
delete(hn&ncol)
print("min hn: "+min(hn)+"    max hn: "+max(hn))
                          
dSSTfiles = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_"+whatConfig+"/run/"+whatYear+"/nhemi_30_x4_"+whatConfig+".cam.h5."+whatYear+"-*.nc | grep -v regrid.nc")
dSSTf      = addfiles (dSSTfiles, "r")
backSSTfiles = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_fixedSST/run/"+whatYear+"/nhemi_30_x4_fixedSST.cam.h5."+whatYear+"-*.nc | grep -v regrid.nc")
backSSTf = addfiles (backSSTfiles, "r")

print("Getting ATM forcings...")
ListSetType (dSSTf, "cat")
time=dSSTf[:]->time
print("min time: "+min(time)+"    max time: "+max(time))
u10=dSSTf[:]->U10
print("min u10: "+min(u10)+"    max u10: "+max(u10))
lhflx=dSSTf[:]->LHFLX
print("min lhflx: "+min(lhflx)+"    max lhflx: "+max(lhflx))
shflx=dSSTf[:]->SHFLX
print("min shflx: "+min(shflx)+"    max shflx: "+max(shflx))
lwflx=dSSTf[:]->FLNS
print("min lwflx: "+min(lwflx)+"    max lwflx: "+max(lwflx))
swflx=dSSTf[:]->FSNS
print("min swflx: "+min(swflx)+"    max swflx: "+max(swflx))
print("... done getting ATM forcings")

print("Getting SST forcing...")
sst_back=backSSTf[:]->SST
sst_back@_FillValue=-999.0
print("min sst_back: "+min(sst_back)+"    max sst_back: "+max(sst_back))
do i = 0,dimsizes(time)-1
  sst_back(i,:)=where(ismissing(hn),sst_back@_FillValue,sst_back(i,:))
end do
sst=sst_back
print("... done getting SST forcing.")

if (plot_orig_SSTA) then
  oAnomfiles=systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+whatYear+"/nhemi_30_x4_slab.cam.h7."+whatYear+"-*.nc | grep -v regrid.nc")
  oAnomf = addfiles (oAnomfiles, "r")
  oSSTA_preint=oAnomf[:]->SST
  oSSTA  = linint1_n_Wrap (oSSTA_preint&time,oSSTA_preint,False,time,0,0)
  counter=0
  do i = 0,dimsizes(time)-1
    if(ismissing(oSSTA(i,0))) then
      oSSTA(i,:) = oSSTA(counter-1,:)
    else
      counter=counter+1
    end if
  end do
end if

if (do_corr) then
  print("Getting correction data...")
  SSTcorr_full=docnFile->deltaT
  print("min SSTcorr_full: "+min(SSTcorr_full)+"    max SSTcorr_full: "+max(SSTcorr_full))
  print("Interpolating correction data...")
  SSTcorr_preint=SSTcorr_full({min(time):max(time)},:)
  SSTcorr  = linint1_n_Wrap (SSTcorr_preint&time,SSTcorr_preint,False,time,0,0) 
  copy_VarMeta(sst,SSTcorr)
  counter=0
  do i = 0,dimsizes(time)-1
    if(ismissing(SSTcorr(i,0))) then
      SSTcorr(i,:) = SSTcorr(counter-1,:)
    else
      counter=counter+1
    end if
  end do
  delete(SSTcorr&ncol)
  print("... done interpolating correction data")
end if


;========================================================================================
TkFrzSw=271.0
dt=3.*3600.
;hn=30
R_cool=4.7
cpsw=3.996e3
rhosw=1.026e3
tau=8.*24.*3600.
;========================================================================================

do i = 3,dimsizes(time)-1
  logwgt = 1.0/(1.0 + exp(-0.5*(u10(i,:)-30.0)))
  dSSTdt_flux=-(lhflx(i,:)+shflx(i,:)+lwflx(i,:)-swflx(i,:))*dt/(hn*cpsw*rhosw)
  dSSTdt_turb=-logwgt*(R_cool/86400.)*((sst(i-1,:)-TkFrzSw)/27.0)*(30./hn)*dt
  if(do_corr) then
    dSSTdt_back=(1./tau)*((sst_back(i-1,:)-SSTcorr(i,:))-sst(i-1,:))*dt
  else
    dSSTdt_back=(1./tau)*(sst_back(i-1,:)-sst(i-1,:))*dt
  end if
  sst(i,:)=sst(i-1,:)+dSSTdt_flux+dSSTdt_turb+dSSTdt_back
end do

SST_anom = sst
SST_anom = sst-sst_back

print("Adding correct time variable....")
sst&time=time
sst_back&time=time
SST_anom&time=time

if (plot_orig_SSTA) then
  deltaSSTA=SST_anom
  deltaSSTA=SST_anom-oSSTA
  deltaSSTA&time=time
  oSSTA&time=time
end if
if (plot_diag) then
  SSTcorr&time=time
end if

ndays=(dimsizes(time)-1)/8 + 1

do z = 0,ndays-1

ix=(z*8)
thisDate=cd_calendar(time(ix),3)

print(thisDate)


outFileName="offline_SSTA_"+whatConfig+"_"+whatYear+"_"+thisDate+".nc"
system("/bin/rm -f "+outDir+"/"+outFileName+" "+outDir+"/"+outFileName+"_regrid.nc")   ; remove any pre-existing file
ncdf = addfile(outDir+"/"+outFileName,"c")  ; open output netCDF file
setfileoption("nc","Format","LargeFile")

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

stix=toint(z*8)
enix=toint(((z+1)*8)-1)
if (z .eq. (ndays-1)) then
  enix = stix
end if

ncdf->SST  = sst(stix:enix:outStride,:)
ncdf->SST_fixed = sst_back(stix:enix:outStride,:)
ncdf->SSTA = SST_anom(stix:enix:outStride,:)
if (plot_orig_SSTA) then
  ncdf->oSSTA = oSSTA(stix:enix:outStride,:)
  ncdf->delSSTA=deltaSSTA(stix:enix:outStride,:)
end if
if (plot_diag) then
  ncdf->hn=hn(:)
  ncdf->SSTcorr=SSTcorr(stix:enix:outStride,:)
end if

end do
            
wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

