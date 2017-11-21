;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin
;========================================================
; USER OPTIONS
;========================================================
;========================================================
 gdir = "/ptmp/zarzycki/archive/atl_30_x4_refine_cam5/atm/hist/"
 in1 = addfile(gdir+"atl_30_x4_refine_cam5.cam.h0.1979-01-08-00000.nc","r")

 lat  = in1->lat
 lon  = in1->lon

 var  = in1->T850(0,:,:)           ; read in data (time,lev,lat,lon)
 
 varmax = max(var)
 varmin = min(var)
 
 ;************************************************
; Plot underlying field
;************************************************

;   out_type = "eps"
;	out_type = "pdf"
;	out_type = "x11"
	out_type = "ps"

wks = gsn_open_wks(out_type,"2DsingleTime")

	; polygon resources
	res2 = True
	res2@tiMainString = ""

	res2@gsnDraw = False
	res2@gsnFrame = False
  
	res2@mpOutlineOn = False
	res2@mpGreatCircleLinesOn = True

	res2@mpGridAndLimbOn = True
	res2@mpGridLineDashPattern = 2

	res2@gsnMajorLonSpacing = 60
	res2@mpGridLonSpacingF = 60
	res2@gsnMajorLatSpacing = 45
	res2@mpGridLatSpacingF = 45

    res2@cnFillOn		  = True

; WIND
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
 res2@cnLineLabelsOn       = False             ; turn off line labels
 res2@gsnSpreadColors      = True              ; use full colormap
 res2@lbLabelStride        = 4
 res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 res2@cnLevelSpacingF      =  1 
 res2@cnMinLevelValF       =  varmin
 res2@cnMaxLevelValF       =  varmax
  
  res2@cnLinesOn   = False		   				; turn off the contour lines
  
	plot2 = gsn_csm_contour_map(wks,var,res2) 
	draw(plot2)
 

end
