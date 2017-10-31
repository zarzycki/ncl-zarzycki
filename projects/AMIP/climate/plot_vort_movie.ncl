load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"


begin
   out_type = "x11"
;	out_type = "pdf"
;	out_type = "ps"

wks = gsn_open_wks(out_type,"pdf/AMIP_vort")
                   
all_files = systemfunc ("ls /glade/u/home/zarzycki/scratch/for-jared/1984/atl_30_x4_refine_nochem.cam.h3*.nc")
sfile = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (sfile, "cat")             ; concatenate or "merge" (default)

do time = 73,73

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

u = sfile[:]->U(time,{500},::1,::1)            ; time (1) x nlev x ncol
v = sfile[:]->V(time,{500},::1,::1)            ; time (1) x nlev x ncol
    
vort = uv2vrF_Wrap(u,v)
vort = vort/1e-5

delete(u)
delete(v)
;************************************************

res2 = True
res2@tiMainString = ""

res2@gsnDraw = False
res2@gsnFrame = False
res2@gsnMaximize = True

res2@lbLabelBarOn         = False              ; turn off indiv. label bars
res2@lbBoxLinesOn         = False
res2@cnInfoLabelOn       = False           ; turn off cn info label

res2@cnFillOn		  = True

res2@gsnAddCyclic = True
    
; WIND
gsn_define_colormap(wks,"BlueRed")          ; choose colormap
res2@cnLineLabelsOn       = False             ; turn off line labels
res2@gsnSpreadColors      = True              ; use full colormap
res2@lbLabelStride        = 4
res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res2@cnLevelSpacingF      =  5                ;
res2@cnMinLevelValF       =  -25.0           ;
res2@cnMaxLevelValF       =  25.0 ; Use 80.0 -> 60 for this
res2@mpGreatCircleLinesOn=True

res2@cnFillMode = "RasterFill"
;res2@cnSmoothingOn = True
;res2@cnRasterCellSizeF = 0.0004
res2@cnRasterSampleFactorF = 0.0

res2@cnLinesOn   = False		   				; turn off the contour lines

;res2@vpWidthF     = 2
;res2@vpHeightF    = 1

res2@mpOutlineOn = True
res2@mpFillOn = False
res2@mpFillColors = (/"background","transparent","LightGray","transparent"/)
res2@mpGridAndLimbOn = False

;plot2(0) = gsn_csm_contour_map(wks,vort,res2)

res2@mpMinLatF   = -30.                      ; set the minimum latitude  
res2@mpMaxLatF   = 85.                      ; set the maximum latitude  
res2@mpMinLonF   = -145.                     ; set the minimum longitude  
res2@mpMaxLonF   = 37.
res2@mpCenterLonF = (res2@mpMinLonF+res2@mpMaxLonF)/2. 

plot2 = gsn_csm_contour_map(wks,vort,res2)
plot2 = plot_outline_fcn(wks,plot2,"black",1.0)

;  

resP                     = True                ; modify the panel plot
;  resP@txString            = "A plot with a common label bar"
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

delete(vort)
delete(res2)
delete(resP)
delete(plot2)
	
;************************************************

end do

end

