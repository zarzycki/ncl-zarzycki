load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"


begin
;   out_type = "x11"
	out_type = "pdf"
;	out_type = "ps"

variable = "TMQ"
wks = gsn_open_wks(out_type,"pdf/AMIP_vort")
                   
all_files = systemfunc ("ls /glade/scratch/patc/archive/f.e15b2.FAMPIC5.ne120_ne120.Club_Test.006/atm/hist/*.h3.2004-09*nc")
;all_files = systemfunc ("ls /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/FAMIPC5_ne120_79to05_03_omp2.cam.h4.1991-09*.nc")
sfile = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (sfile, "cat")             ; concatenate or "merge" (default)

do time = 0,200,2
;0-120

;plot2 = new(2,graphic)                         ; create graphic array

regrid = False ;NOTE, this is just a debug flag. Need to modify varnames to run

print("Doing time number: "+time)
    
if (regrid) then
    wgt_file = "/glade/u/home/zarzycki/mapping/gen_mapping_files/map_atl_30_x4_TO_0.25x0.25_patc.130225.nc"
;---Open files containing source HOMME and destination FV grids

;---Get two variables to regrid and the source lat/lon grid
    u_se = sfile->U(:,{200},:)            ; time (1) x nlev x ncol
    v_se = sfile->V(:,{200},:)            ; time (1) x nlev x ncol
    Opt         = True
    u  = ESMF_regrid_with_weights(u_se,wgt_file,Opt)
    v = ESMF_regrid_with_weights(v_se,wgt_file,Opt)
    printVarSummary(u)
    printVarSummary(v)
end if

var = sfile[:]->$variable$(time,:)            ; time (1) x nlev x ncol
lat1d = ndtooned(sfile[0]->lat)          ; Pull off lat/lon variable and
lon1d = ndtooned(sfile[0]->lon)          ; convert both to 1D.

;************************************************

res2 = True




res2@tiMainString = ""

res2@gsnDraw = False
res2@gsnFrame = False
res2@gsnMaximize = True


res2@sfXArray            = lon1d        ; Required to tell NCL where to
res2@sfYArray            = lat1d        ; overlay data on globe.

res2@lbLabelBarOn         = False              ; turn off indiv. label bars
res2@lbBoxLinesOn         = False
res2@cnInfoLabelOn       = False           ; turn off cn info label

res2@cnFillOn		  = True

res2@gsnAddCyclic = True
    
; WIND
gsn_define_colormap(wks,"MPL_gist_yarg")          ; choose colormap
res2@gsnSpreadColors     = True	        ; use full colormap  
res2@gsnSpreadColorStart  = -1                 ; start with last color
res2@gsnSpreadColorEnd   = 2                   ; end with a beginning color
res2@cnFillMode = "RasterFill"
;res2@cnSmoothingOn = True
;res2@cnRasterCellSizeF = 0.0004
res2@cnRasterSampleFactorF = 0.0

res2@cnLineLabelsOn       = False             ; turn off line labels
res2@cnLinesOn   = False		   				; turn off the contour lines
res2@gsnSpreadColors      = True              ; use full colormap
res2@lbLabelStride        = 4
res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res2@cnLevelSpacingF      =  1.                ;
res2@cnMinLevelValF       =  5.0           ;
res2@cnMaxLevelValF       =  72.0 ; Use 80.0 -> 60 for this
res2@mpGreatCircleLinesOn=True

res2@tmXBOn=False
res2@tmXTOn=False
res2@tmYLOn=False
res2@tmYROn=False

res2@mpMaxLatF=90.
res2@mpMinLatF=0.

res2@gsnLeftString = ""
res2@gsnCenterString = ""
res2@gsnRightString = ""

res2@mpOutlineOn = True
res2@mpFillOn = False
res2@mpFillColors = (/"background","transparent","LightGray","transparent"/)
res2@mpGridAndLimbOn = False

;plot2(0) = gsn_csm_contour_map(wks,vort,res2)

;res2@mpMinLatF   = -40.                      ; set the minimum latitude  
;res2@mpMaxLatF   = 90.                      ; set the maximum latitude  
;res2@mpMinLonF   = -165.                     ; set the minimum longitude  
;res2@mpMaxLonF   = 57.
;res2@mpCenterLonF = (res2@mpMinLonF+res2@mpMaxLonF)/2. 

plot2 = gsn_csm_contour_map(wks,var,res2)


resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True                ; add common colorbar
resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
resP@lbLabelStride    = 4

;  resP@gsnPanelFigureStrings= (/"Day 1","Day 4","Day 6","Day 8"/)
;  resP@amJust = "TopRight"

resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF

;gsn_panel(wks,plot2,(/2,1/),resP)
draw(plot2)
frame(wks)

delete(var)
delete(res2)
delete(resP)
delete(plot2)
	
;************************************************

end do

end

