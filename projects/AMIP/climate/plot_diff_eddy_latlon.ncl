; This routine takes a uniform grid, var-res grid (both interpolated to same
; lat/lon) and generates a panel plot of a specific variable from both grids
; as well as the absolute difference between the two grids. There is an option
; to download MERRA data (does not need to be on same grid) and plot that as a
; fourth panel.

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

levs = (/850.,700.,500.,300.,200.,100./)
do whichlev = 0,dimsizes(levs)-1

var1 = "V"
var2 = "T"
var12 = "VT"
level = levs(whichlev)
add_MERRA = False
horizstride = 4
testMult = True

seasons = (/"NDJ","FMA","MJJ","ASO","ANN"/)
numseasons = dimsizes(seasons)
out_type = "pdf"
wks  = gsn_open_wks(out_type,"pdf/eddydiff_"+var12+"_"+level)            ; open a ps file
;wks  = gsn_open_wks(out_type,"test")            ; open a ps file
plot = new(numseasons*3,graphic)

do k = 0,numseasons-1

monsea = seasons(k)

print("Now working on "+monsea+" for var: "+var12+" at level: "+level)

if (testMult) then
  reffilels = systemfunc("ls /glade/u/home/zarzycki/scratch/AMIPmonthly/climo/atl30x4_monthlyavg_climo_*3D.nc")
  reffile   = addfiles(reffilels, "r")   ; note the "s" of addfile
  ListSetType (reffile, "cat")             ; concatenate or "merge" (default)
  unifilels = systemfunc("ls /glade/u/home/zarzycki/scratch/AMIPmonthly/climo/ne30_monthlyavg_climo_*_3D.nc_regrid.nc")
  unifile   = addfiles(unifilels, "r")   ; note the "s" of addfile
  ListSetType (unifile, "cat")             ; concatenate or "merge" (default)
  
  lev  = reffile[0]->lev
  reflat = reffile[0]->lat(::horizstride)
  reflon = reffile[0]->lon(::horizstride)
  refvar1_all =  reffile[:]->$var1$(:,{level},::horizstride,::horizstride)
  refvar2_all =  reffile[:]->$var2$(:,{level},::horizstride,::horizstride)
  refvar12_all = reffile[:]->$var12$(:,{level},::horizstride,::horizstride)
  unilat = unifile[0]->lat(::horizstride)
  unilon = unifile[0]->lon(::horizstride)
  univar1_all =  unifile[:]->$var1$(:,{level},::horizstride,::horizstride)
  univar2_all =  unifile[:]->$var2$(:,{level},::horizstride,::horizstride)
  univar12_all = unifile[:]->$var12$(:,{level},::horizstride,::horizstride)
  
   month = (/"JAN","FEB","MAR","APR","MAY","JUN" \
            ,"JUL","AUG","SEP","OCT","NOV","DEC" /)
   sea3  = (/"DJF","JFM","FMA","MAM","AMJ","MJJ" \
            ,"JJA","JAS","ASO","SON","OND","NDJ" /)
   i3    = (/(/12,1,2/),(/1,2,3/),(/2,3,4/),(/3,4,5/) \ 
            ,(/ 4,5,6/),(/5,6,7/),(/6,7,8/),(/7,8,9/) \ 
            ,(/ 8,9,10/),(/9,10,11/),(/10,11,12/),(/11,12,1/) /)
   i3    = i3-1    ; NCL is zero based


       i = ind(month.eq.monsea)
       if (.not.ismissing(i)) then
           ; extract specific month
           refvar1 = refvar1_all(i,:,:)
           refvar2 = refvar2_all(i,:,:)
           refvar12 = refvar12_all(i,:,:)
           univar1 = univar1_all(i,:,:)
           univar2 = univar2_all(i,:,:)
           univar12 = univar12_all(i,:,:)    
       end if

       if (monsea.eq."ANN") then
          refvar1 = dim_avg_n_Wrap(refvar1_all,0)
          refvar2 = dim_avg_n_Wrap(refvar2_all,0)
          refvar12 = dim_avg_n_Wrap(refvar12_all,0)
          univar1 = dim_avg_n_Wrap(univar1_all,0)
          univar2 = dim_avg_n_Wrap(univar2_all,0)
          univar12 = dim_avg_n_Wrap(univar12_all,0)
       end if
       
       dNam  = getvardims (refvar1_all)     ; get dimension names
       i  = ind(sea3.eq.monsea)
       if (.not.ismissing(i)) then
       ;print(i3(i,:))
          refvar1 = dim_avg_Wrap( refvar1_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
          refvar2 = dim_avg_Wrap( refvar2_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
          refvar12 = dim_avg_Wrap( refvar12_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
          univar1 = dim_avg_Wrap( univar1_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
          univar2 = dim_avg_Wrap( univar2_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
          univar12 = dim_avg_Wrap( univar12_all($dNam(1)$|:,$dNam(2)$|:,$dNam(0)$|i3(i,:)) )
       end if

else
  print("Loading the data")
  reffile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_all_climo_3D.nc","r")
  unifile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_all_climo_3D.nc_regrid.nc","r")
  lev  = reffile->lev
  reflat = reffile->lat(::horizstride)
  reflon = reffile->lon(::horizstride)
  refvar1 =  reffile->$var1$(0,{level},::horizstride,::horizstride)
  refvar2 =  reffile->$var2$(0,{level},::horizstride,::horizstride)
  refvar12 = reffile->$var12$(0,{level},::horizstride,::horizstride)
  unilat = unifile->lat(::horizstride)
  unilon = unifile->lon(::horizstride)
  univar1 =  unifile->$var1$(0,{level},::horizstride,::horizstride)
  univar2 =  unifile->$var2$(0,{level},::horizstride,::horizstride)
  univar12 = unifile->$var12$(0,{level},::horizstride,::horizstride)
end if



refvar12eddy = refvar12
refvar12eddy = refvar12 - refvar1*refvar2

univar12eddy = univar12
univar12eddy = univar12 - univar1*univar2

print("Calculating differences")
diffvar = refvar12eddy
diffvar = refvar12eddy - univar12eddy


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
res@mpMinLatF   = 15.                      ; set the minimum latitude  
res@mpMaxLatF   = 65.                      ; set the maximum latitude  
res@mpMinLonF   = -80.                     ; set the minimum longitude  
res@mpMaxLonF   = 5.
;res@mpMinLatF   = -70.                      ; set the minimum latitude  
;res@mpMaxLatF   = 70.                      ; set the maximum latitude  
;res@mpMinLonF   = -180.                     ; set the minimum longitude  
;res@mpMaxLonF   = 180.
res@mpOutlineOn            = True
res@mpPerimOn              = False
res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn  = False                   ; tuen off line labels
res@cnFillOn=True
res@gsnLeftString=""
res@gsnSpreadColors = True

res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res@cnMinLevelValF       =  1.1*min(refvar12eddy({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))
res@cnMaxLevelValF       =  1.2*max(refvar12eddy({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))
res@cnLevelSpacingF      =  (res@cnMaxLevelValF - res@cnMinLevelValF) / 20.

res_diff = res
res_diff@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res_diff@cnMinLevelValF       =  - 1.1*max(abs(diffvar({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
res_diff@cnMaxLevelValF       =  1.1*max(abs(diffvar({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
res_diff@cnLevelSpacingF      =  (res_diff@cnMaxLevelValF - res_diff@cnMinLevelValF) / 20.



plot(3*k + 0) = gsn_csm_contour_map(wks,refvar12eddy,res)
plot(3*k + 1) = gsn_csm_contour_map(wks,univar12eddy,res)
plot(3*k + 2) = gsn_csm_contour_map(wks,diffvar,res_diff)

print("Adding outline")
plot(3*k + 0) = plot_outline_fcn(wks,plot(3*k + 0),"black",1.0)
plot(3*k + 2) = plot_outline_fcn(wks,plot(3*k + 2),"black",1.0)

; Modify panel plots and whatnot
resP                     = True                ; modify the panel plot
resP@txString            = var12

end do

resP@amJust = "BottomRight"
resP@gsnPanelFigureStringsFontHeightF = 0.008
if (add_MERRA) then
  resP@gsnPanelFigureStrings= (/"VR","Uni","VR-Uni","MERRA"/)
  gsn_panel(wks,plot,(/2,2/),resP)
else
  panel_strings = new(numseasons*3,"string")
  do i = 0,numseasons-1
    start_row = i*3
    sea = seasons(i)
    panel_strings(start_row:start_row+2) = (/"VR_"+sea,"Uni_"+sea,"VR-Uni_"+sea/)
  end do
  resP@gsnPanelFigureStrings= panel_strings
  gsn_panel(wks,plot,(/numseasons,3/),resP)
end if


delete([/univar12_all,refvar2_all,refvar1_all,refvar12,diffvar,res,refvar12eddy,refvar2,refvar1,res_diff,univar1,univar2,univar12,univar2_all,univar1_all,univar12eddy,refvar12_all/])
;list_vars()

end do

end

