load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"

begin

;---------------User settings----------------------------

plot_only=True

configs=(/"fixedSST","slab","slab2"/)

resolution=0.25
gridSized2=6.0
numComposite=15
whichVar="WIND850"
out_type = "pdf"

wind_factor = "log"
traj_dir = "/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/"

traj_filename = "cat_traj_slab_08_4.7_900.txt"
traj_filename = "cat_traj_fixedSST_900.txt"
;traj_filename = "traj_slab_1201.txt"



filestrg="h4"
filetail="nc_regrid.nc"

;----------------Constants-----------------------------------

ms_to_kts = 1.94384449
pi = 3.14159265358979
omega = 7.2921E-5

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,wind_factor)

;-------------Figure out composite box---------------------

numCellsAcross=2*toint(gridSized2/resolution)+1
numCellsOut=toint(gridSized2/resolution)

latArr=fspan(-gridSized2,gridSized2,numCellsAcross)
lonArr=fspan(-gridSized2,gridSized2,numCellsAcross)

PRECT_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
FLUT_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
U10_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
U850_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
V850_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
MSLP_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
WIND850_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")
TMQ_COMPOSITE=new((/dimsizes(configs),numComposite,numCellsAcross,numCellsAcross/),"float")

; === DO LOOP

do z = 0,dimsizes(configs)-1

  thisConfig=configs(z)
  if (thisConfig .eq. "fixedSST") then
    traj_filename = "cat_traj_fixedSST_900.txt"
    filehead="nhemi_30_x4_fixedSST"
  end if
  if (thisConfig .eq. "slab") then
    traj_filename = "cat_traj_slab_08_4.7_900.txt"
    filehead="nhemi_30_x4_slab"
  end if
  if (thisConfig .eq. "slab2") then
    traj_filename = "cat_traj_slab2_08_4.7_900.txt"
    filehead="nhemi_30_x4_slab2"
  end if
;-------------Get trajectories------------------------------

thefile=traj_dir+traj_filename
ncols = 12                     ; assign number of columns
maxLines = -1
traj_data = getTrajectories(thefile,ncols,maxLines)

traj_lon = traj_data(:,3,:)
traj_lat = traj_data(:,4,:)
traj_wind = traj_data(:,5,:)*factor
traj_pres = traj_data(:,7,:)/100.
traj_yyyy = traj_data(:,8,:)
traj_mm = traj_data(:,9,:)
traj_dd = traj_data(:,10,:) 
traj_hh = traj_data(:,11,:)

ndims = dimsizes(traj_lon)
nstorms = ndims(0)
storm_index=ispan(0,nstorms-1,1)
ntimes = ndims(1)

;-------------Find top 10 storms---------------------

traj_wind_MAX = dim_max_n_Wrap(traj_wind,1)
traj_wind_unsort = traj_wind_MAX
qsort(traj_wind_MAX)

topTenStorms=traj_wind_MAX(nstorms-numComposite:nstorms-1)

intenseMatches=new(nstorms,"integer")
intenseMatches=0

do i = 0,numComposite-1
  intenseMatches=where(traj_wind_unsort.eq.topTenStorms(i),intenseMatches+1,intenseMatches+0)
end do


;-------------Do composite---------------------

compIx=0

do j = 0,nstorms-1
  if (intenseMatches(j) .gt. 0) then
    ; find time
    maxInd=maxind(traj_wind(j,:))
    wind=traj_wind(j,maxInd)
    yyyy=toint(traj_yyyy(j,maxInd))
    mm=toint(traj_mm(j,maxInd))
    dd=toint(traj_dd(j,maxInd))
    hh=toint(traj_hh(j,maxInd))
    sssss=hh*3600
    lat=traj_lat(j,maxInd)
    lon=traj_lon(j,maxInd)
    print("Max wind: "+wind+"    on "+yyyy+" "+mm+"/"+dd+" "+hh+"Z     for storm: "+j)
    
    dataDir="/glade/u/home/zarzycki/scratch/"+filehead+"/run/"+yyyy+"/"
    units="days since "+yyyy+"-05-01 00:00:00"
    trackTime   = cd_inv_calendar(yyyy,mm,dd,hh,0,0,units,0)

    dataFileName=dataDir+"/"+filehead+".cam."+filestrg+"."+sprinti("%0.4i",yyyy)+"-"+sprinti("%0.2i",mm)+"-"+sprinti("%0.2i",dd)+"-"+"00000"+"."+filetail
    dataFile = addfile(dataFileName,"r")

    minLat=lat-gridSized2
    maxLat=lat+gridSized2
    minLon=lon-gridSized2
    maxLon=lon+gridSized2

    ;print("minlat: "+minLat+"   maxlat: "+maxLat)
    ;print("minlon: "+minLon+"   maxlon: "+maxLon)
    ;printVarSummary(dataFile->PRECT({trackTime},{minLat:maxLat},{minLon:maxLon}))
    PRECT_COMPOSITE(z,compIx,:,:) = dataFile->PRECT({trackTime},{minLat:maxLat},{minLon:maxLon})
    U10_COMPOSITE(z,compIx,:,:) = dataFile->U10({trackTime},{minLat:maxLat},{minLon:maxLon})
    FLUT_COMPOSITE(z,compIx,:,:) = dataFile->FLUT({trackTime},{minLat:maxLat},{minLon:maxLon})
    U850_COMPOSITE(z,compIx,:,:) = dataFile->U850({trackTime},{minLat:maxLat},{minLon:maxLon})
    V850_COMPOSITE(z,compIx,:,:) = dataFile->V850({trackTime},{minLat:maxLat},{minLon:maxLon})
    MSLP_COMPOSITE(z,compIx,:,:) = dataFile->PSL({trackTime},{minLat:maxLat},{minLon:maxLon})
    TMQ_COMPOSITE(z,compIx,:,:) = dataFile->TMQ({trackTime},{minLat:maxLat},{minLon:maxLon})

    WIND850_COMPOSITE(z,compIx,:,:) = sqrt(U850_COMPOSITE(z,compIx,:,:)^2+V850_COMPOSITE(z,compIx,:,:)^2)
    PRECT_COMPOSITE(z,compIx,:,:)=PRECT_COMPOSITE(z,compIx,:,:)*8.64E+7/24. ; mm/hr
    compIx=compIx+1
  end if
end do

delete(compIx)
delete([/thefile,traj_data,traj_lat,traj_lon,traj_wind,traj_pres,traj_yyyy,traj_mm,traj_dd,traj_hh/])
delete([/topTenStorms,intenseMatches,traj_wind_unsort,traj_wind_MAX/])
delete([/dataDir,dataFileName,dataFile,units/])
delete(storm_index)
delete(ndims)

end do

PRECT_COMPOSITE!2="lat"
PRECT_COMPOSITE!3="lon"
PRECT_COMPOSITE&lat=latArr
PRECT_COMPOSITE&lon=lonArr

copy_VarCoords(PRECT_COMPOSITE,FLUT_COMPOSITE)
copy_VarCoords(PRECT_COMPOSITE,WIND850_COMPOSITE)
copy_VarCoords(PRECT_COMPOSITE,TMQ_COMPOSITE)
copy_VarCoords(PRECT_COMPOSITE,MSLP_COMPOSITE)
copy_VarCoords(PRECT_COMPOSITE,U10_COMPOSITE)

  wks = gsn_open_wks(out_type,"composite_"+whichVar)              ; open a png file

  plot = new(3,graphic)
  plotmslp = new(3,graphic)
  
  res                     = True
  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnFillOn             = True
  res@cnLinesOn            = False
  res@cnLineLabelsOn = False
  res@cnInfoLabelOn = False 
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@gsnLeftString=whichVar
  res@gsnRightString="SLAB1"

  res@gsnStringFontHeightF = 0.026


if (whichVar .eq. "PRECT") then
  cmap = read_colormap_file("radar_1")
  printVarSummary(cmap)
  res@cnFillPalette = cmap(7:23,:)   ; subset color map
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels    = (/0.15,0.3,0.5,1.0,2.0,5.0,10.0,15.0,20.0,25.0,30.0,35.0,40.0/)
  unitsStr="mm hr~S~-1"
  panelStrings=(/"g.","h.","i."/)

  res@gsnRightString="FIXEDSST"
  plot(0) = gsn_csm_contour(wks,dim_avg_n_Wrap(PRECT_COMPOSITE(0,:,:,:),0),res)
  res@gsnRightString="SLAB1"
  plot(1) = gsn_csm_contour(wks,dim_avg_n_Wrap(PRECT_COMPOSITE(1,:,:,:),0),res)
  res@gsnRightString="SLAB2"
  plot(2) = gsn_csm_contour(wks,dim_avg_n_Wrap(PRECT_COMPOSITE(2,:,:,:),0),res)

  
end if

if (whichVar .eq. "WIND850") then
  res@cnFillPalette       = "WhViBlGrYeOrReWh"
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 17.5
  res@cnMaxLevelValF       = 75.
  res@cnLevelSpacingF      =  2.5 
  unitsStr="m s~S~-1"
  panelStrings=(/"a.","b.","c."/)

  res@gsnRightString="FIXEDSST"
  plot(0) = gsn_csm_contour(wks,dim_avg_n_Wrap(WIND850_COMPOSITE(0,:,:,:),0),res)
  res@gsnRightString="SLAB1"
  plot(1) = gsn_csm_contour(wks,dim_avg_n_Wrap(WIND850_COMPOSITE(1,:,:,:),0),res)
  res@gsnRightString="SLAB2"
  plot(2) = gsn_csm_contour(wks,dim_avg_n_Wrap(WIND850_COMPOSITE(2,:,:,:),0),res)

  ;res_mslp = True
  ;res_mslp@gsnDraw = False    
  ;res_mslp@gsnFrame = False
  ;res_mslp@cnFillOn  = False
  ;res_mslp@cnLinesOn   = True
  ;res_mslp@cnLabelMasking = False
  ;res_mslp@cnLineLabelsOn = False
  ;res_mslp@cnLevelSelectionMode = "ManualLevels"
  ;res_mslp@cnLevelSpacingF      =  8.0
  ;res_mslp@cnMinLevelValF       =  900.0 
  ;res_mslp@cnMaxLevelValF       =  1060.0 ; Use 80.0 -> 60 for this
  ;res_mslp@gsnRightString   = ""
  ;res_mslp@gsnLeftString    = ""
  ;res_mslp@gsnCenterString  = ""
  ;res_mslp@cnLineColor      = "Black"
  ;res_mslp@cnLineThicknessF = 2.
  ;res_mslp@cnFillDrawOrder="PostDraw"
  ;MSLP_COMPOSITE=MSLP_COMPOSITE/100.
  ;plotmslp(0) = gsn_csm_contour(wks,dim_avg_n_Wrap(MSLP_COMPOSITE(0,:,:,:),0),res_mslp)
  ;plotmslp(1) = gsn_csm_contour(wks,dim_avg_n_Wrap(MSLP_COMPOSITE(1,:,:,:),0),res_mslp)
  ;plotmslp(2) = gsn_csm_contour(wks,dim_avg_n_Wrap(MSLP_COMPOSITE(2,:,:,:),0),res_mslp)
  ;do k = 0,dimsizes(configs)-1
  ;  overlay(plot(k),plotmslp(k))
  ;end do
end if

if (whichVar .eq. "FLUT") then
  res@cnFillPalette       = "irsat"
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 90.
  res@cnMaxLevelValF       = 240.
  res@cnLevelSpacingF      =  5.
  FLUT_COMPOSITE = where(FLUT_COMPOSITE.ge.240,FLUT_COMPOSITE@_FillValue,FLUT_COMPOSITE)
  unitsStr="W m~S~-2"
  panelStrings=(/"d.","e.","f."/)

  res@gsnRightString="FIXEDSST"
  plot(0) = gsn_csm_contour(wks,dim_avg_n_Wrap(FLUT_COMPOSITE(0,:,:,:),0),res)
  res@gsnRightString="SLAB1"
  plot(1) = gsn_csm_contour(wks,dim_avg_n_Wrap(FLUT_COMPOSITE(1,:,:,:),0),res)
  res@gsnRightString="SLAB2"
  plot(2) = gsn_csm_contour(wks,dim_avg_n_Wrap(FLUT_COMPOSITE(2,:,:,:),0),res)
end if

if (whichVar .eq. "TMQ") then
  res@cnFillPalette       = "BlGrYeOrReVi200"
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 40.
  res@cnMaxLevelValF       = 90.
  res@cnLevelSpacingF      =  4.
  unitsStr="mm"
  panelStrings=(/"j.","k.","l."/)

  res@gsnRightString="FIXEDSST"
  plot(0) = gsn_csm_contour(wks,dim_avg_n_Wrap(TMQ_COMPOSITE(0,:,:,:),0),res)
  res@gsnRightString="SLAB1"
  plot(1) = gsn_csm_contour(wks,dim_avg_n_Wrap(TMQ_COMPOSITE(1,:,:,:),0),res)
  res@gsnRightString="SLAB2"
  plot(2) = gsn_csm_contour(wks,dim_avg_n_Wrap(TMQ_COMPOSITE(2,:,:,:),0),res)
end if


;************************************************
; create panel
;************************************************
resP                     = True
;resP@txString            = "Init: alid: +72h"
resP@gsnPanelLabelBar    = True
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
resP@lbTitleString = unitsStr
resP@lbTitleExtentF = 0.02
resP@lbTitlePosition  = "Right"              ; title position
resP@lbTitleFontHeightF= .015                ; make title smaller
resP@lbTitleDirection = "Across"             ; title direction
resP@lbTitleExtentF = 0.01

resP@gsnPanelDebug = True 

resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.023
resP@gsnPanelFigureStrings= panelStrings

gsn_panel(wks,plot,(/1,3/),resP)               ; now draw as one plot

end
