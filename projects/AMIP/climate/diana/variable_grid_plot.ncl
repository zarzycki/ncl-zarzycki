;********************************************
; Use these libraries for running on cees

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "./data/"


wks = gsn_open_wks("pdf", "var_grid")

; setvalues NhlGetWorkspaceObjectId() 
;      "wsMaximumSize" : 33554432 
;   end setvalues 

;gsn_define_colormap( wks, "precip3_16lev")
gsn_define_colormap( wks, "BlGrYeOrReVi200")


; NAME THE FILES TO BE USED

   fili6 = "v700_atl30x4_daily_198106*.nc"

; ADD FILENAME TO THE CORRESPONDING DIRECTORY

files = systemfunc("ls "+diri+fili6)

f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

 V = f1[:]->V700(0,:,:)

; WITH PIVOT ----------------------
longitude_in = f1[0]->lon
longitude_in!0 = "lon"
longitude_in&lon = longitude_in

V_piv = lonPivot(V,180)
longitude_piv = lonPivot(longitude_in,180)

printVarSummary(V_piv)
printVarSummary(longitude_piv)
;print(longitude_piv)

longitude = longitude_piv

 Vplt = V_piv
 print(Vplt&lon)

;*********************************************


; PLOT THE OUTPUT


  res                        = True               ; plot mods desired

  res@gsnFrame   = False
  res@gsnDraw    = False

  res@mpOutlineBoundarySets  = "National"
  res@cnRasterModeOn        =False 
  res@cnFillOn               = True               ; color fill
  res@cnLinesOn              = False              
  res@cnLineLabelsOn         = False              ; no contour labels
  res@gsnSpreadColors        = True               ; use total colormap
  res@gsnSpreadColorStart    = 2
  res@gsnSpreadColorEnd      = 201
  res@cnInfoLabelOn          =False
  res@gsnAddCyclic           =False

; res@mpLimitMode   = "LatLon"                 ; control map zoom with lat/lons
;   res@mpMaxLatF     =  maxLat                   ; Af
;   res@mpMinLatF     =  minLat
;   res@mpMinLonF     =  minLon
;   res@mpMaxLonF     =  maxLon


;  res@lbLabelBarOn        = False              ; turn off individual cb's
;  res@cnLevelSelectionMode   = "ManualLevels"
; res@cnLevelSpacingF        = .5
; res@cnMinLevelValF         = 0
; res@cnMaxLevelValF         = 12
;  res@mpPerimOn              = True

   res@tiMainString = "Variable Resolution"

;   res@tiYAxisString = "Latitude"
;   res@tiXAxisString = "Longitude"
   plot = gsn_csm_contour_map(wks,Vplt,res)
   plot = plot_outline_fcn(wks,plot,"blue",2.0)


draw(wks)
frame(wks)

end
