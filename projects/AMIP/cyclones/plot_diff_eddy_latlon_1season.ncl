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

levs = (/500./)
do whichlev = 0,dimsizes(levs)-1

var1 = "V"
var2 = "V"
var12 = "VV"
level = levs(whichlev)
add_MERRA = False
horizstride = 4
testMult = True

seasons = (/"ASO"/)
numseasons = dimsizes(seasons)
out_type = "pdf"
wks  = gsn_open_wks(out_type,"pdf/eddydiff_"+var12+"_"+level)            ; open a ps file
;wks  = gsn_open_wks(out_type,"test")            ; open a ps file
plot = new(1,graphic)

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

refvar1star = refvar1
refvar2star = refvar2
refvar1star = dim_rmvmean_Wrap(refvar1)
refvar2star = dim_rmvmean_Wrap(refvar2)
univar1star = univar1
univar2star = univar2
univar1star = dim_rmvmean_Wrap(univar1)
univar2star = dim_rmvmean_Wrap(univar2)


refvar12eddy = refvar12
refvar12eddy = refvar12 - refvar1*refvar2 - refvar1star*refvar2star

univar12eddy = univar12
univar12eddy = univar12 - univar1*univar2 - univar1star*univar2star

print("Calculating differences")
diffvar = refvar12eddy
diffvar = refvar12eddy - univar12eddy

avgLatMin = 40
avgLatMax = 60
avgLonMin = 290
avgLonMax = 350

rad    = 4.0*atan(1.0)/180.0
clat   = cos(reflat*rad)
clat!0 = "lat"
clat&lat = reflat
  
refvarAvg = wgt_areaave(refvar12eddy({avgLatMin:avgLatMax},{avgLonMin:avgLonMax}), clat({avgLatMin:avgLatMax}), 1.0, 1)
univarAvg = wgt_areaave(univar12eddy({avgLatMin:avgLatMax},{avgLonMin:avgLonMax}), clat({avgLatMin:avgLatMax}), 1.0, 1)
diffvarAvg = wgt_areaave(diffvar({avgLatMin:avgLatMax},{avgLonMin:avgLonMax}), clat({avgLatMin:avgLatMax}), 1.0, 1)
print("Refvar Avg: "+refvarAvg)
print("univar Avg: "+univarAvg)
print("diffvar Avg: "+diffvarAvg)

;======================================================================

basin = "global" ; Valid values: atlantic, wpac, (anything else for global)
modelgrid = "vr" ; valid are varres, coarse, ibtracs
factor = 0.85 ; correction for model winds
cutwind = 0 ; 0 for all, 17 for TS+, 33 for cat1+, 49 for cat3+
ibstyr=1980
ibenyr=1990

  print("Plotting CAM data")
  traj_dir = "/glade/u/home/zarzycki/tcstats/"
  traj_dir = "/glade/u/home/zarzycki/scratch/OLDTRACKS/camsetracking_jan22_88ths_nolat/"
  if (modelgrid .eq. "vr") then
    traj_filename = "traj_vr"
    traj_filename = "traj"
  else if (modelgrid .eq. "1deg") then
    traj_filename = "traj_1deg"
  else
    print("No model grid")
    exit
  end if
  end if
  
  traj_cleanfile = "traj_filt_clean.TMP"
  
  print("Removing text headers from trajectories")
  system("grep -v '^start' "+ traj_dir+traj_filename +" > "+traj_cleanfile+"")
  
  traj_ncols = numAsciiCol(traj_cleanfile)
  ; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  
  print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
  
  print("Removing temporary file:"+traj_cleanfile)
  system("rm -rf "+traj_cleanfile)
        
  ;do i = 0,traj_nrows-1
  ;  if (traj_data(i,4) .ge. 1985)
  ;    traj_data(i,2) = traj_data@_FillValue
  ;  end if
  ;end do
  
  onedwind = traj_data(:,2)*factor
  onedlon = traj_data(:,0)
  onedlat = traj_data(:,1)
  onedyear = traj_data(:,4)
  
  onedwind = where(onedwind.ge.cutwind,onedwind,onedwind@_FillValue)
  onedlat = where(onedwind.ge.cutwind,onedlat,onedlat@_FillValue)
  onedlon = where(onedwind.ge.cutwind,onedlon,onedlon@_FillValue)
  
  onedwind = where(onedyear.lt.ibstyr,onedwind@_FillValue,onedwind)
  onedlat = where(onedyear.lt.ibstyr,onedlat@_FillValue,onedlat)
  onedlon = where(onedyear.lt.ibstyr,onedlon@_FillValue,onedlon)
  
  onedwind = where(onedyear.gt.ibenyr,onedwind@_FillValue,onedwind)
  onedlat = where(onedyear.gt.ibenyr,onedlat@_FillValue,onedlat)
  onedlon = where(onedyear.gt.ibenyr,onedlon@_FillValue,onedlon)

;======================================================================


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
res@mpMaxLatF   = 62.                      ; set the maximum latitude  
res@mpMinLonF   = -66.                     ; set the minimum longitude  
res@mpMaxLonF   = 0.
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
res@cnMinLevelValF       =  -18.
res@cnMaxLevelValF       =  18.
res@cnLevelSpacingF      =  (res@cnMaxLevelValF - res@cnMinLevelValF) / 18.


res_diff = res
res_diff@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
;-1e-3 for VQ ; 8 for VT


res_diff@gsnStringFontHeightF = 0.02
if (var12 .eq. "VU") then
  res_diff@cnMinLevelValF       =  -15.
  res_diff@cnMaxLevelValF       =  15.
  res_diff@cnLevelSpacingF      =  (res_diff@cnMaxLevelValF - res_diff@cnMinLevelValF) / 10.
  res_diff@gsnLeftString = "(V'U')~B~avg~N~"
  res_diff@gsnRightString = "m~S~2~N~ s~S~-2~N~"
  panel_label = "a."
end if
if (var12 .eq. "VV") then
  res_diff@cnMinLevelValF       =  -20.
  res_diff@cnMaxLevelValF       =  20.
  res_diff@cnLevelSpacingF      =  (res_diff@cnMaxLevelValF - res_diff@cnMinLevelValF) / 10.
  res_diff@gsnLeftString = "(V'V')~B~avg~N~"
  res_diff@gsnRightString = "m~S~2~N~ s~S~-2~N~"
  panel_label = "b."
end if
if (var12 .eq. "VT") then
  res_diff@cnMinLevelValF       =  -6.
  res_diff@cnMaxLevelValF       =  6.
  res_diff@cnLevelSpacingF      =  (res_diff@cnMaxLevelValF - res_diff@cnMinLevelValF) / 12.
  res_diff@gsnLeftString = "(V'T')~B~avg~N~"
  res_diff@gsnRightString = "K m s~S~-1~N~"
  panel_label = "c."
end if
if (var12 .eq. "VQ") then
  res_diff@cnMinLevelValF       =  -1.e-3
  res_diff@cnMaxLevelValF       =  1.e-3
  res_diff@cnLevelSpacingF      =  (res_diff@cnMaxLevelValF - res_diff@cnMinLevelValF) / 10.
  res_diff@gsnLeftString = "(V'Q')~B~avg~N~"
  res_diff@gsnRightString = "kg m kg~S~-1~N~ s~S~-1~N~"
  panel_label = "d."
end if

;plot(3*k + 0) = gsn_csm_contour_map(wks,refvar12eddy,res)
;plot(3*k + 1) = gsn_csm_contour_map(wks,univar12eddy,res)
;plot(3*k + 2) = gsn_csm_contour_map(wks,diffvar,res_diff)

plot(0) = gsn_csm_contour_map(wks,diffvar,res_diff)

print("Adding outline")
;plot(3*k + 0) = plot_outline_fcn(wks,plot(3*k + 0),"black",1.0)
;plot(3*k + 2) = plot_outline_fcn(wks,plot(3*k + 2),"black",1.0)

  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new(traj_nrows,graphic)

do i = 0,traj_nrows-1
if (basin .eq. "global") then
  linethicknesses = (/0.2,0.3,1.3,1.9,2.3,2.7/)
else
  linethicknesses = (/1.8,1.9,2.0,2.25,2.5,2.75/)
end if

if (.not.ismissing(onedwind(i)))

  if (onedwind(i) .lt. 17)
    polyres@gsMarkerColor = (/"black"/)
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (onedwind(i) .ge. 17 .and. onedwind(i) .lt. 33)
    polyres@gsMarkerColor = (/"black"/)
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (onedwind(i) .ge. 33 .and. onedwind(i) .lt. 43)
    polyres@gsMarkerColor = (/"black"/)
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (onedwind(i) .ge. 43 .and. onedwind(i) .lt. 49)
    polyres@gsMarkerColor = (/"black"/)
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (onedwind(i) .ge. 49 .and. onedwind(i) .lt. 58)
    polyres@gsMarkerColor = (/"black"/)
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerColor = (/"black"/) 
    lineres@gsLineColor = (/"black"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
  
  if (i .ne. 0) then
  if (gc_latlon(onedlat(i),onedlon(i),onedlat(i-1),onedlon(i-1),2,4) .lt. 400) then
    if(onedwind(i) .ge. cutwind) then
      dum(i) = gsn_add_polyline(wks,plot,(/onedlon(i),onedlon(i-1)/),(/onedlat(i),onedlat(i-1)/),lineres)
      ;if (mod(i,4) .eq. 0) then
      ;  str = sprintf("%4.0f",traj_data(i,4))+sprintf("%2.0f",traj_data(i,5))+sprintf("%2.0f",traj_data(i,6))
      ;  gsn_text(wks,map,str,traj_data(i,0),traj_data(i,1),txres)
      ;end if
      if (modelgrid .eq. "ibtracs") then
        if (mod(i,1000) .eq. 0) then
          print("Working on lat/lon number: "+i+" of traj_nrows: "+traj_nrows+" which is year: "+onedyear(i))
        end if
      end if
    end if
  end if
  end if
  
end if

end do



; Modify panel plots and whatnot
resP                     = True                ; modify the panel plot
resP@txString            = ""

end do

resP@amJust = "BottomRight"
resP@gsnPanelFigureStringsFontHeightF = 0.04
if (add_MERRA) then
  resP@gsnPanelFigureStrings= (/"VR","Uni","VR-Uni","MERRA"/)
  gsn_panel(wks,plot,(/2,2/),resP)
else
  panel_strings = panel_label
  resP@gsnPanelFigureStrings= panel_strings
  ;gsn_panel(wks,plot,(/numseasons,3/),resP)
  gsn_panel(wks,plot,(/numseasons,1/),resP)
end if


delete([/univar12_all,refvar2_all,refvar1_all,refvar12,diffvar,res,refvar12eddy,refvar2,refvar1,res_diff,univar1,univar2,univar12,univar2_all,univar1_all,univar12eddy,refvar12_all/])
;list_vars()

end do

end

