load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

douuvv = False
numloops = 1
if (douuvv) then
  numloops = 2
end if

var = (/"T","V"/)
pinterp = 850.
horizstride = 4
reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_all_climo_3D.nc","r")
unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_all_climo_3D.nc","r")
wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_AMIP_ref_latlon_patc.130523.nc"

do i = 1,numloops
  print("Doing loop number "+i+" of "+numloops)
  print("Loading the data")
  if (i .eq. 1) then
    Aref = reffile->V(0,:,::horizstride,::horizstride)
    Bref = reffile->V(0,:,::horizstride,::horizstride)
    ABref = reffile->VV(0,:,::horizstride,::horizstride)
    
    A_native = unifile->V(0,:,:)
    B_native = unifile->V(0,:,:)
    AB_native = unifile->VV(0,:,:)
  else
    Aref = reffile->V(0,:,::horizstride,::horizstride)
    Bref = reffile->V(0,:,::horizstride,::horizstride)
    ABref = reffile->VV(0,:,::horizstride,::horizstride)
    
    A_native = unifile->V(0,:,:)
    B_native = unifile->V(0,:,:)
    AB_native = unifile->VV(0,:,:)
  end if
    
  print("Regridding the data")
  Opt         = True
  Opt@CopyVarCoords = True
  A_full  = ESMF_regrid_with_weights(A_native,wgt_file,Opt)
  B_full  = ESMF_regrid_with_weights(B_native,wgt_file,Opt)
  AB_full  = ESMF_regrid_with_weights(AB_native,wgt_file,Opt)
  lat_full = A_full&lat
  lon_full = A_full&lon
    
  delete([/A_native,B_native,AB_native/])
  
  Auni = A_full(:,::horizstride,::horizstride)
  Buni = B_full(:,::horizstride,::horizstride)
  ABuni = AB_full(:,::horizstride,::horizstride)
  lat = lat_full(::horizstride)
  lon = lon_full(::horizstride)
    
  delete([/A_full,B_full,AB_full,lat_full,lon_full/])
  
  lev = reffile->lev

  minlat = -20.
  maxlat = 75.
  minlon = -120.
  maxlon = 20.
  Aref_sub = Aref(:,{minlat:maxlat},{minlon:maxlon})
  Bref_sub = Bref(:,{minlat:maxlat},{minlon:maxlon})
  ABref_sub = ABref(:,{minlat:maxlat},{minlon:maxlon})
  Auni_sub = Auni(:,{minlat:maxlat},{minlon:maxlon})
  Buni_sub = Buni(:,{minlat:maxlat},{minlon:maxlon})
  ABuni_sub = ABuni(:,{minlat:maxlat},{minlon:maxlon})
  ;Aref_sub = Aref
  ;Bref_sub = Bref
  ;ABref_sub = ABref
  ;Auni_sub = Auni
  ;Buni_sub = Buni
  ;ABuni_sub = ABuni
  
  Aref_zonal = dim_avg_n_Wrap(Aref_sub,2)
  Bref_zonal = dim_avg_n_Wrap(Bref_sub,2)
  ABref_zonal = dim_avg_n_Wrap(ABref_sub,2)
  Auni_zonal = dim_avg_n_Wrap(Auni_sub,2)
  Buni_zonal = dim_avg_n_Wrap(Buni_sub,2)
  ABuni_zonal = dim_avg_n_Wrap(ABuni_sub,2)
  
  ABref_prime = ABref_zonal
  ABref_prime = ABref_zonal - Aref_zonal*Bref_zonal
  ABuni_prime = ABuni_zonal
  ABuni_prime = ABuni_zonal - Auni_zonal*Buni_zonal
  
  if (douuvv) then
    if (i .eq. 1) then
      print("Storing results")
      AB_ref_temp1 = ABref_prime
      AB_uni_temp1 = ABuni_prime
    end if
  end if  
end do

if (douuvv) then
  print("Calculating new results")
  ABref_prime = ABref_prime+AB_ref_temp1
  ABuni_prime = ABuni_prime+AB_uni_temp1
end if  

diffvar = ABref_prime
diffvar = ABref_prime - ABuni_prime

printVarSummary(diffvar)

;varmax = max(refvar)
;varmin = min(refvar)

wks  = gsn_open_wks("x11","pdfs/diffplots_"+var(0))            ; open a ps file
;gsn_define_colormap(wks,"amwg")
plot = new(3,graphic)                         ; create graphic array

res                             = True
res@mpFillOn                    = True        ; turn off gray fill
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@gsnFrame = False
res@gsnDraw = False
res@mpGreatCircleLinesOn=True
;res@mpMinLatF   = -20.                      ; set the minimum latitude  
;res@mpMaxLatF   = 75.                      ; set the maximum latitude  
;res@mpMinLonF   = -120.                     ; set the minimum longitude  
;res@mpMaxLonF   = 20.


res@mpOutlineOn            = True
res@mpPerimOn              = False
res@cnFillOn=True
res@gsnLeftString=""

res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels

res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
;res@cnLevelSpacingF      =  4.              ;
;res@cnMinLevelValF       =  -50.0           ;
;res@cnMaxLevelValF       =  50.0 ; Use 80.0 -> 60 for this

ABref_prime&lev@units = "hPa" 
ABuni_prime&lev@units = "hPa" 
diffvar&lev@units = "hPa" 

plot(0)  = gsn_csm_pres_hgt(wks, ABref_prime({2000:100},:), res )
plot(1)  = gsn_csm_pres_hgt(wks, ABuni_prime({2000:100},:), res )


;res@cnLevelSpacingF      =  5.              ;
;res@cnMinLevelValF       =  -50.0           ;
;res@cnMaxLevelValF       =  50.0 ; Use 80.0 -> 60 for this

plot(2)  = gsn_csm_pres_hgt(wks, diffvar({2000:100},:), res )

;plot(0) = plot_outline_fcn(wks,plot(0),"black",2.0)
;plot(2) = plot_outline_fcn(wks,plot(2),"black",2.0)
  
; Modify panel plots and whatnot
resP                     = True                ; modify the panel plot
resP@txString            = var(0)
;resP@gsnPanelLabelBar    = True                ; add common colorbar
;resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
;resP@lbLabelStride    = 4

resP@gsnPanelFigureStrings= (/"VR","Uni","Diff"/)
resP@amJust = "TopRight"

;resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF

gsn_panel(wks,plot,(/3,1/),resP)

end


