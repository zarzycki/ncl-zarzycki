load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

mmdaythresh=0.1
SEVEREVAR="SHIP"
severethresh=1.0

minlat=25.
maxlat=50.
minlon=-125.
maxlon=-65.

fili = systemfunc("ls /glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/*200*")
print(fili)
nfili= dimsizes(fili)
print("nfili="+nfili)
f1 = addfiles(fili,"r") 

lat1=f1[0]->lat
lon1=f1[0]->lon

print("Loading PRECT")
PRECT1=f1[:]->PRECT
print("Loading "+SEVEREVAR)
SIGTOR1=f1[:]->$SEVEREVAR$
time=f1[:]->time
ntimes=dimsizes(time)

PRECT1(0:ntimes-2,:,:)=(PRECT1(1:ntimes-1,:,:)+PRECT1(0:ntimes-2,:,:)) / 2.
PRECT1(ntimes-1,:,:)=PRECT1(ntimes-1,:,:)
PRECT1 = PRECT1/1000.

PRECT1_regrid=PRECT1
SIGTOR1_regrid=SIGTOR1

thresh = mmdaythresh*1.15741e-8

SIGTOR1_regrid=where(SIGTOR1_regrid.ge.0.0,SIGTOR1_regrid,0.0)
SIGTOR1_regrid=where(PRECT1_regrid.ge.thresh,SIGTOR1_regrid,0.0)

SIGTORFREQ1=toint(SIGTOR1_regrid)

SIGTORFREQ1=where(SIGTOR1_regrid.ge.severethresh,1,0)

copy_VarMeta(SIGTOR1_regrid,SIGTORFREQ1)

SIGTORCUM1 = dim_sum_n_Wrap(SIGTORFREQ1,0)

SIGTORCUM1NORM = tofloat(SIGTORCUM1)*(1440./ntimes)   ; days/yr
copy_VarMeta(SIGTORCUM1,SIGTORCUM1NORM)

print(max(SIGTORCUM1NORM))
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
  res@cnMinLevelValF       =  1.0
  res@cnMaxLevelValF       =  15.0
  res@cnLevelSpacingF      = 1.0
  res@gsnAddCyclic = False

  res@gsnLeftString=""
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
  map(0) = gsn_csm_contour_map_ce(wks,SIGTORCUM1NORM,res)


resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot




system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================
ncdf->SIGTORCUM1NORM  = SIGTORCUM1NORM            




end
