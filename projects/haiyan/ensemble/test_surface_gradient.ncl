load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

config=(/"All-Hist","Nat-Hist","Nat-Hist ATM only","Nat-Hist SST only","Nat-Hist ATM only (corr)"/)
atmDir="/global/cscratch1/sd/czarzyck/unigridFiles/haiyan_48_x8/inic/"
sstDir="/global/cscratch1/sd/czarzyck/unigridFiles/haiyan_48_x8/sst/"
atmfilename=(/"haiyan_48_x8_FILTERED_2013-11-04-54000.nc_NOPERT.nc","haiyan_48_x8_FILTERED_2013-11-04-54000.nc_PERT.nc","haiyan_48_x8_FILTERED_2013-11-04-54000.nc_PERT.nc","haiyan_48_x8_FILTERED_2013-11-04-54000.nc_NOPERT.nc","haiyan_48_x8_FILTERED_2013-11-04-54000.nc_FULLPERT_CAM5_sfccor.nc"/)
sstfilename=(/"sst_1x1.nc","sst_1x1_Nat-Hist-CMIP5-est1-v1-0.nc","sst_1x1.nc","sst_1x1_Nat-Hist-CMIP5-est1-v1-0.nc","sst_1x1.nc"/)

latPt=10.
lonPt=132.
ix=381130     ; if negative, will find closest index to latPt, lonPt

CtoK=273.15

do ii = 0,dimsizes(config)-1
  print(""+config(ii))
  atmFile=addfile(atmDir+"/"+atmfilename(ii),"r")
  sstFile=addfile(sstDir+"/"+sstfilename(ii),"r")



  T_atm=atmFile->T(0,29,:)
  T_sst=sstFile->SST_cpl(9,:,:)

  if (ix .lt. 0)   ; if
    if (ii .eq. 0)
      ;find ncol indices
      lat=atmFile->lat
      lon=atmFile->lon
      minDist=10000.
      ix=0
      do jj = 0,dimsizes(lat)-1
        dist_to_point=gc_latlon(lat(jj),lon(jj),latPt,lonPt,2,1)
        if(dist_to_point .lt. minDist)
          ix=jj
          minDist=tofloat(dist_to_point)
          print("new min: "+lat(ix)+" "+lon(ix)+" ix: "+ix)
        end if
      end do
    end if
  end if

  deltaT = (T_sst({latPt},{lonPt}) + CtoK) - T_atm(ix)
  print("deltaT "+deltaT)
  print("-----------------------------------------------------------")
end do


end
