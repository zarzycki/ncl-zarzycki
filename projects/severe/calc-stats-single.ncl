load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

month="may"

if (month .eq. "mar") then
  date="1991-03-02-00000"
end if
if (month .eq. "apr") then
  date="1991-04-01-00000"
end if
if (month .eq. "may") then
  date="1991-05-01-00000"
end if
if (month .eq. "jun") then
  date="1991-05-31-00000"
end if
if (month .eq. "jul") then
  date="1991-06-30-00000"
end if
if (month .eq. "aug") then
  date="1991-07-30-00000"
end if
if (month .eq. "sep") then
  date="1991-08-29-00000"
end if
if (month .eq. "oct") then
  date="1991-09-28-00000"
end if

mmdaythresh=50.
minlat=25.
maxlat=50.
minlon=-125.
maxlon=-65.

;f1=addfile("/glade/scratch/zarzycki/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.cam.h9."+date+".nc","r")
f1=addfile("/glade/scratch/zarzycki/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.cam.h9."+date+".nc","r")
;f2=addfile("/glade/scratch/zarzycki/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h9."+date+".nc","r")
f2=addfile("/glade/scratch/zarzycki/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004.cam.h9."+date+".nc","r")
;f1coord=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc","r")
f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp120a_topo_150430.nc","r")
;f2coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/USGS_smoothed_ne0np4conus30x8_c161115.nc","r")
f2coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
;f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1glob_patch.nc"
f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp120a_to_1x1glob_patch.nc"
;f2map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
f2map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"
lat1=f1coord->lat
lon1=f1coord->lon

lat2=f2coord->lat
lon2=f2coord->lon

phis1=f1coord->PHIS
phis2=f2coord->PHIS

ntimes=120

PRECT1=f1->PRECT
SIGTOR1=f1->SIGTOR

PRECT1(0:ntimes-2,:)=PRECT1(1:ntimes-1,:)
PRECT1(ntimes-1,:)=0.0

PRECT2=f2->PRECT
SIGTOR2=f2->SIGTOR

PRECT2(0:ntimes-2,:)=PRECT2(1:ntimes-1,:)
PRECT2(ntimes-1,:)=0.0

Opt                = True
Opt@PrintTimings   = True
PRECT1_regrid = ESMF_regrid_with_weights(PRECT1,f1map,Opt)
SIGTOR1_regrid = ESMF_regrid_with_weights(SIGTOR1,f1map,Opt)
phis1_regrid = ESMF_regrid_with_weights(phis1,f1map,Opt)

PRECT2_regrid = ESMF_regrid_with_weights(PRECT2,f2map,Opt)
SIGTOR2_regrid = ESMF_regrid_with_weights(SIGTOR2,f2map,Opt)
phis2_regrid = ESMF_regrid_with_weights(phis2,f2map,Opt)

printVarSummary(PRECT1_regrid)


thresh = mmdaythresh*1.15741e-8

SIGTOR1_regrid=where(PRECT1_regrid.ge.thresh,SIGTOR1_regrid,0.0)
SIGTOR2_regrid=where(PRECT2_regrid.ge.thresh,SIGTOR2_regrid,0.0)

SIGTORFREQ1=toint(SIGTOR1_regrid)
SIGTORFREQ2=toint(SIGTOR2_regrid)

SIGTORFREQ1=where(SIGTOR1_regrid.ge.1.0,1,0)
SIGTORFREQ2=where(SIGTOR2_regrid.ge.1.0,1,0)

copy_VarMeta(SIGTOR1_regrid,SIGTORFREQ1)
copy_VarMeta(SIGTOR2_regrid,SIGTORFREQ2)

SIGTORCUM1 = dim_sum_n_Wrap(SIGTORFREQ1,0)
SIGTORCUM2 = dim_sum_n_Wrap(SIGTORFREQ2,0)

SIGTORCUM1 = where(phis1_regrid.le.40.0,SIGTORCUM1@_FillValue,SIGTORCUM1)
SIGTORCUM2 = where(phis2_regrid.le.40.0,SIGTORCUM2@_FillValue,SIGTORCUM2)

;AVGSIGTORCUM = tofloat(SIGTORCUM1+SIGTORCUM2) / 2.
;copy_VarMeta(SIGTORCUM1,AVGSIGTORCUM)

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("x11","homme")               ; open workstation
  map = new(2,"graphic")
  gsn_define_colormap(wks,"MPL_Reds")   ; choose colormap

  res                     = True         ; plot modifications desired
;  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnDraw=False
  res@gsnFrame=False

  res@gsnSpreadColors     = True         ; Use full colormap, but start
  res@lbLabelBarOn         = False              ; turn off indiv. label bars

  res@mpMaxLatF = maxlat
  res@mpMinLatF = minlat
  res@mpMaxLonF = maxlon
  res@mpMinLonF = minlon

  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       =  1.
  res@cnMaxLevelValF       =  6.
  res@cnLevelSpacingF      = 1.
  res@gsnAddCyclic = False

  res@mpOutlineBoundarySets     = "geophysicalandusstates"; turn on states
  res@mpDataBaseVersion         = "mediumres"             ; select database
  res@mpDataSetName             = "Earth..2"


  res@cnFillOn            = True         ; Turn on contour fill
  res@cnFillMode          = "RasterFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

  ;res@sfXArray            = lon1        ; Required to tell NCL where to
  ;res@sfYArray            = lat1        ; overlay data on globe.
  map(0) = gsn_csm_contour_map_ce(wks,SIGTORCUM1,res)
  delete(res@sfXArray)
  delete(res@sfYArray)

  ;res@sfXArray            = lon2        ; Required to tell NCL where to
  ;res@sfYArray            = lat2        ; overlay data on globe.
  map(1) = gsn_csm_contour_map_ce(wks,SIGTORCUM2,res)

resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,map,(/1,2/),resP)             ; now draw as one plot
end
