begin

;cases = (/"FHIST-ne30-betacast-ERA5-x001","FHIST-ne30-betacast-ERA5-x003","FHIST-ne30-betacast-ERA5-x004","FHIST-ne30-betacast-ERA5-x005","FHIST-ne30-betacast-ERA5-x006","FHIST-ne30-betacast-ERA5-x010","FHIST-ne30-betacast-ERA5-x008","FHIST-ne30-betacast-ERA5-x009"/)
;names = (/"L23_CAM6_ndg","L32_CAM6_ndg_ERA5","CAM6_no_ndg","CAM6_window","L31_CAM6_ndg_ERA5","L19_CAM6_ndg","L32_CAM6_ndg_ERA5_24","L21_CAM6_ndg"/)

cases = (/"FHIST-ne30-betacast-ERA5-x003","FHIST-ne30-betacast-ERA5-x005"/)
names = (/"L32_CAM6_ndg_ERA5","CAM6_window"/)

ncases=dimsizes(cases)

do jj = 0,ncases-1
  thisCase=cases(jj)
  
  print(thisCase+"")
  
  folder = "/glade/u/home/zarzycki/scratch/"+thisCase+"/run/regrid/"

  all_files = systemfunc("ls "+folder+"/"+thisCase+".cam.h3.20??-07-??-00000.nc_regrid.nc_NLLJ.nc")

  fall = addfiles (all_files, "r")
  ListSetType (fall, "join") 
  nllj = fall[:]->NLLJIX   ; note syntax [:]

  if (jj .eq. 0) then
    lljdims = dimsizes(nllj)
    nllj_avg = new((/ncases,lljdims(1),lljdims(2)/),typeof(nllj))
  end if
  
  nllj_avg(jj,:,:) = dim_avg_n_Wrap(nllj,0)
  
end do


wks = gsn_open_wks("png","llj_comparison")          ; send graphics to PNG file
map = new(ncases,"graphic")

cmap = read_colormap_file("BlAqGrYeOrReVi200") ; read color data

res                 = True                    ; plot mods desired
res@gsnFrame = False
res@gsnDraw = False

res@cnLinesOn       = False
res@cnFillOn        = True
res@cnFillPalette = cmap
;res@cnFillPalette   = cmap(:15,:)        ; set color map
res@cnLineLabelsOn  = False              ; turn off contour lines

res@mpPerimOn              = True                    ; draw box around map
res@mpGridLineDashPattern  = 2                       ; lat/lon lines as dashed
res@mpOutlineBoundarySets = "GeophysicalAndUSStates" ; add state boundaries

res@mpMinLatF   = 25.                      ; set the minimum latitude  
res@mpMaxLatF   = 50.                      ; set the maximum latitude  
res@mpMinLonF   = -110.                     ; set the minimum longitude  
res@mpMaxLonF   = -85.
res@mpCenterLonF = (res@mpMinLonF+res@mpMaxLonF)/2. 

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 1.			; set the minimum contour level
res@cnMaxLevelValF  = 13.			; set the maximum contour level
res@cnLevelSpacingF = 1.			; set the interval between contours

do ii = 0,ncases-1
  res@tiMainString    = names(ii)
  map(ii) = gsn_csm_contour_map(wks,nllj_avg(ii,:,:),res)    ; Draw contours over a map.
end do

panel_res=True
gsn_panel(wks,map,(/2,4/),panel_res)
  
end
