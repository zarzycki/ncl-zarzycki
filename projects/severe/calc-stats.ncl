load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

mmdaythresh=50.
minlat=25.
maxlat=50.
minlon=-125.
maxlon=-65.

NYRS=5
nfiles=59

;NYRS=10
;nfiles=121

f1=addfile("/glade/scratch/zarzycki/cat_mp15a-120a-US.nc","r")
f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"

;f1=addfile("/glade/scratch/zarzycki/cat2.nc","r")
;f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/USGS_smoothed_ne0np4conus30x8_c161115.nc","r")
;f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"

;f1=addfile("/glade/scratch/zarzycki/cat_mp120a.nc","r")
;f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp120a_topo_150430.nc","r")
;f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp120a_to_1x1reg_patch.nc"

;f1=addfile("/glade/scratch/zarzycki/cat_ne30.nc","r")
;f1coord=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc","r")
;f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1reg_patch.nc"

lat1=f1coord->lat
lon1=f1coord->lon


phis1=f1coord->PHIS

ntimes=120*nfiles

PRECT1=f1->PRECT
SIGTOR1=f1->SIGTOR

PRECT1(0:ntimes-2,:)=PRECT1(1:ntimes-1,:)
PRECT1(ntimes-1,:)=0.0



Opt                = True
Opt@PrintTimings   = True
PRECT1_regrid = ESMF_regrid_with_weights(PRECT1,f1map,Opt)
SIGTOR1_regrid = ESMF_regrid_with_weights(SIGTOR1,f1map,Opt)
phis1_regrid = ESMF_regrid_with_weights(phis1,f1map,Opt)


thresh = mmdaythresh*1.15741e-8

SIGTOR1_regrid=where(PRECT1_regrid.ge.thresh,SIGTOR1_regrid,0.0)

SIGTORFREQ1=toint(SIGTOR1_regrid)

SIGTORFREQ1=where(SIGTOR1_regrid.ge.0.8,1,0)

copy_VarMeta(SIGTOR1_regrid,SIGTORFREQ1)

SIGTORCUM1 = dim_sum_n_Wrap(SIGTORFREQ1,0)

SIGTORCUM1 = where(phis1_regrid.le.20.0,SIGTORCUM1@_FillValue,SIGTORCUM1)

SIGTORCUM1NORM = tofloat(SIGTORCUM1)/tofloat(NYRS)
copy_VarMeta(SIGTORCUM1,SIGTORCUM1NORM)
;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("pdf","sigtorplot")               ; open workstation
  map = new(1,"graphic")
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
  res@cnMinLevelValF       =  0.5
  res@cnMaxLevelValF       =  5.
  res@cnLevelSpacingF      = 0.5
  res@gsnAddCyclic = False

  res@gsnLeftString="MPAS 15km 03-1991 to 10-1991"
  res@gsnRightString="SIGTOR > 0.8 .and. PRECT > 50mm/day"

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
  map(0) = gsn_csm_contour_map_ce(wks,SIGTORCUM1NORM,res)


resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot
end
