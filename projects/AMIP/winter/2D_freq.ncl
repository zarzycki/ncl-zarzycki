load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "~/ncl/functions/rainratetodbz.ncl"
load "~/ncl/functions/plot_hommegrid_fcn.ncl"

begin

grid="ne30"

;fils = systemfunc ("ls /glade/scratch/zarzycki/winter/"+grid+"*h8*01*.nc /glade/scratch/zarzycki/winter/"+grid+"*h8*02*.nc /glade/scratch/zarzycki/winter/"+grid+"*h8*03*.nc") ; file paths
fils = systemfunc ("ls /glade/scratch/zarzycki/winter/"+grid+"*.nc") ; file paths
f    = addfiles (fils, "r")   

ListSetType (f, "cat")
FZRA    = f[:]->PRECT_FZRA

FZRA = where((FZRA*141732.283).gt.0.01, 1, 0)

FZRA_FRQ = dim_sum_n_Wrap(FZRA,0)

FZRA_FRQ = smth9(FZRA_FRQ, 0.50,  0.25, True)

maxlat = 75.           ; choose subregion           
minlat = 25.
maxlon = 305. 
minlon = 220. 

out_type = "x11"
wks = gsn_open_wks(out_type,"weatherplot")

gsn_define_colormap(wks,"3gauss")          ; choose colormap

  
  res                 = True
  
  ;res@gsnDraw      = False                        ; don't draw yet
  ;res@gsnFrame     = False                        ; don't advance frame yet
  res@gsnMaximize = True
  
  res@gsnAddCyclic = False                    ; Don't add a cyclic point.
  
  res_rain                      = res
    
  res_rain@cnFillOn		  = True
  res_rain@cnLinesOn   = False 
    
  res_rain@mpFillOn                    = False        ; turn off gray fill
  res_rain@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
  res_rain@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
  res_rain@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

  res_rain@mpMaxLatF  = maxlat           ; choose subregion           
  res_rain@mpMinLatF  = minlat
  res_rain@mpMinLonF = minlon 
  res_rain@mpMaxLonF = maxlon 
  res_rain@mpCenterLonF = (res_rain@mpMinLonF+res_rain@mpMaxLonF)/2. 

  res_rain@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res_rain@cnMinLevelValF  = 0.			; set the minimum contour level
  res_rain@cnMaxLevelValF  = 8.0		; set the maximum contour level
  res_rain@cnLevelSpacingF = .2		; set the interval between contours
  

  plot = gsn_csm_contour_map(wks,FZRA_FRQ(:,:),res_rain)


end
