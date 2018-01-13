load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

DATA="MP15A-120A-US"  ; NE0CONUS30X8, NE30, CFSR
mmdaythresh=2.5
SEVEREVAR="SIGTOR"
severethresh=1.0
out_type="pdf"

minlat=25.
maxlat=50.
minlon=-125.
maxlon=-65.

;f1=addfile("/glade/scratch/zarzycki/cat_mp15a-120a-US.nc","r")
;f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
;f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"

if (DATA .eq. "MP15A-120A-US") then
  fili = systemfunc("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004/atm/hist/*h9*200*nc")
  f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
  f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"
end if

if (DATA .eq. "NE0CONUS30X8") then
  fili = systemfunc("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003/atm/hist/*h9*200*nc")
  f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/USGS_smoothed_ne0np4conus30x8_c161115.nc","r")
  f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
end if

;f1coord=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp120a_topo_150430.nc","r")
;f1map="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp120a_to_1x1reg_patch.nc"

if (DATA .eq. "NE30") then
  fili = systemfunc("ls /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16/atm/hist/*h9*200*nc")
  f1coord=addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc","r")
  f1map="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1reg_patch.nc"
end if

if (DATA .eq. "CFSR") then
  fili = systemfunc("ls /glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/*200*")
end if

nfili= dimsizes(fili)
print("nfili="+nfili)
f1 = addfiles(fili,"r") 

if (DATA .eq. "CFSR") then
  lat1=f1[0]->lat
  lon1=f1[0]->lon
else
  lat1=f1coord->lat
  lat1=f1coord->lat
  phis1=f1coord->PHIS
end if

print("Loading PRECT")
PRECT1=f1[:]->PRECT
print("Loading "+SEVEREVAR)
SIGTOR1=f1[:]->$SEVEREVAR$
time=f1[:]->time
ntimes=dimsizes(time)

thresh = mmdaythresh*1.15741e-8

if (DATA .eq. "CFSR") then
  PRECT1(0:ntimes-2,:,:)=(PRECT1(1:ntimes-1,:,:)+PRECT1(0:ntimes-2,:,:)) / 2.
  PRECT1(ntimes-1,:,:)=PRECT1(ntimes-1,:,:)
  PRECT1 = PRECT1/1000.
else
  PRECT1(0:ntimes-2,:)=PRECT1(1:ntimes-1,:)
  PRECT1(ntimes-1,:)=0.0
end if

Opt                = True
Opt@PrintTimings   = True

;PRECT1_regrid = ESMF_regrid_with_weights(PRECT1,f1map,Opt)
;SIGTOR1_regrid = ESMF_regrid_with_weights(SIGTOR1,f1map,Opt)
;phis1_regrid = ESMF_regrid_with_weights(phis1,f1map,Opt)

PRECT1_regrid = PRECT1
SIGTOR1_regrid = SIGTOR1
if (DATA .ne. "CFSR") then
  phis1_regrid = phis1
end if

SIGTOR1_regrid=where(SIGTOR1_regrid.ge.0.0,SIGTOR1_regrid,0.0)
SIGTOR1_regrid=where(PRECT1_regrid.ge.thresh,SIGTOR1_regrid,0.0)

SIGTORFREQ1=toint(SIGTOR1_regrid)

SIGTORFREQ1=where(SIGTOR1_regrid.ge.severethresh,1,0)

copy_VarMeta(SIGTOR1_regrid,SIGTORFREQ1)

SIGTORCUM1 = dim_sum_n_Wrap(SIGTORFREQ1,0)

if (DATA .ne. "CFSR") then
  SIGTORCUM1 = where(phis1_regrid.le.40.,SIGTORCUM1@_FillValue,SIGTORCUM1)
end if

SIGTORCUM1NORM = tofloat(SIGTORCUM1)*(1440./ntimes)   ; days/yr
copy_VarMeta(SIGTORCUM1,SIGTORCUM1NORM)

if (DATA .ne. "CFSR") then
  SIGTORCUM1NORM_regrid=ESMF_regrid_with_weights(SIGTORCUM1NORM,f1map,Opt)
else
  SIGTORCUM1NORM_regrid=SIGTORCUM1NORM
end if

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks(out_type,DATA+"_"+SEVEREVAR+"_"+severethresh+"_2000-09")               ; open workstation
  map = new(1,"graphic")

  maxcontour=15.0
  if ( SEVEREVAR .eq. "SHIP" ) then
    gsn_define_colormap(wks,"MPL_Greens")   ; choose colormap
    maxcontour=10.
  else if (SEVEREVAR .eq. "SIGTOR" ) then
    gsn_define_colormap(wks,"MPL_Reds")   ; choose colormap
    maxcontour=10.
  else
    gsn_define_colormap(wks,"MPL_Blues")   ; choose colormap
    maxcontour=10.
  end if
  end if

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
  res@cnMinLevelValF       =  1.0
  res@cnMaxLevelValF       =  maxcontour
  res@cnLevelSpacingF      = 1.0
  res@gsnAddCyclic = False

  res@gsnLeftString=DATA+" 2000-2009"
  res@gsnRightString=SEVEREVAR+" > "+severethresh+" .and. PRECT > "+mmdaythresh+"mm/day"

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
  map(0) = gsn_csm_contour_map_ce(wks,SIGTORCUM1NORM_regrid,res)


resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot
end
