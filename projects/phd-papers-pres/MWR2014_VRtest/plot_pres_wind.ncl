;========================================================
; Aquaplanet pressure-wind relationship
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

ms_to_kts = 1.94384449
wind_factor = "log"

; Wind speed power relation
if (wind_factor .eq. "power") then
  z_10 = 10.
  z_r = 64.
  alpha = 0.11
  factor = (z_10/z_r)^alpha
  print("Using factor: "+factor)
else if (wind_factor .eq. "log") then
  ; Garret 1992 -- Wind profile formulation
  ; Wieringa 1993 -- roughness coefficient
  z_10 = 10.
  z_r = 64.
  z_0 = 0.01 ; roughness coeff
  factor = 1 + log(z_10/z_r)/log(z_r/z_0)
  print("Using factor: "+factor)
else if (wind_factor .eq. "none") then
  print("No correction used.")
else
  print("Incorrect wind correction type.")
  exit
end if
end if
end if

print("Read in TC locations from CAM")

  traj_filename = "traj_APE_clean"
  traj_ncols = numAsciiCol(traj_filename)
; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_filename,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
        
  ; wind is column 2, pressure is column 3
  
  do i = 0,traj_nrows-1
    cyclon = traj_data(i,0)
    cyclat = traj_data(i,1)
  end do
    
print("Get ibTracs data")
; READ IBTRACS
 ibdir = "/glade/p/work/zarzycki/ibtracs/"
 ibfile = addfile(ibdir+"Allstorms.ibtracs_all.v03r04.nc.nc","r")
 
 iblat = ibfile->lat_for_mapping*.01
 iblon = ibfile->lon_for_mapping*.01
 ibpres = ibfile->source_pres(:,:,0)*.1
 ibyear = ibfile->season
 ibwind = ibfile->source_wind(:,:,0)*.1/ms_to_kts
 
 ibdimsizes = dimsizes(iblat)
 ibnumstorms = ibdimsizes(0)
 
 do i = 0,ibnumstorms-1
;   if (ibyear(i) .ge. 1981 .and. ibyear(i) .le. 2008 .and. mod(i,3) .eq. 0) then
   if (ibyear(i) .ge. 1981 .and. ibyear(i) .le. 2008) then
   else
   ibpres(i,:) = ibpres@_FillValue
   ibwind(i,:) = ibwind@_FillValue
   end if
 end do
 
 onedpres = ndtooned(ibpres)
 onedwind = ndtooned(ibwind)
 
  polyn = 3
  quad_obs = lspoly(onedwind, onedpres , 1, polyn)    ; all weights are set to one
  quad_cam = lspoly(traj_data(:,2)*factor, traj_data(:,3) , 1, polyn)
  print(quad_cam) ; Y = c(0) + c(1)*x + c(2)*x^2
  regx = fspan(0,100,750)
  camregy = new(dimsizes(regx),float)
  obsregy = new(dimsizes(regx),float)
  camregy = quad_cam(0) + quad_cam(1)*regx + quad_cam(2)*regx^2
  obsregy = quad_obs(0) + quad_obs(1)*regx + quad_obs(2)*regx^2
  

  wks  = gsn_open_wks("pdf","APE_pres_wind")            ; open a ps file
  
  res  = True
  res@gsnMaximize            = True       ; Maximize plot in frame.
  res@gsnDraw    = False                         ; don't draw
  res@gsnFrame   = False                         ; don't advance frame
   
  res@tiMainString  = "Pressure-Wind Relationship"	; title
  res@tiYAxisString = "Wind speed (m/s)" 	; y axis title
  res@tiXAxisString = "Surface pressure (hPa)" 	; y axis title
  
  res@tiYAxisFontHeightF = 0.018
  res@tiXAxisFontHeightF = 0.018
  res@tiMainFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.015
  res@tmYLLabelFontHeightF = 0.015
  
  res@trXMinF           = 870.
  res@trXMaxF           = 1030.
  res@trYMinF           = 0.
  res@trYMaxF           = 85.
   
   res@xyMarkLineMode = "Markers"

   
    ; Draw ibTracks data
    res@xyMarkerColors = "blue"
       res@xyMarker      = 6
       res@xyMarkerSizeF = 0.005
    plot = gsn_csm_xy(wks,onedpres,onedwind,res)

    ; Draw CAM-SE data
    res@xyMarkerColors = "red"
       res@xyMarker      = 1
             res@xyMarkerSizeF = 0.025
    plot2 = gsn_csm_xy(wks,traj_data(:,3),traj_data(:,2)*factor,res)
    
    overlay(plot,plot2)
    
    ; Now we will plot the quad fit lines
    
    res@xyMarkerSizeF = 0.020
    res@xyMarkerColors = "blue"
    plot3 = gsn_csm_xy(wks,obsregy,regx,res)
    overlay(plot,plot3)
    
    res@xyMarkerColors = "red"
    plot4 = gsn_csm_xy(wks,camregy,regx,res)
    overlay(plot,plot4)


  lgres                    = True
  lgres@lgMarkerColors     = (/"red","blue"/)
  lgres@lgItemType         = "Markers"        ; show lines only (default)
  lgres@lgMonoMarkerIndex = False
  lgres@lgMarkerIndexes = (/1,6/)
  lgres@lgMonoMarkerSize = False
  lgres@lgMarkerSizes = (/0.028,0.008/)
  lgres@lgLabelFontHeightF = .12            ; set the legend label font thickness
  lgres@vpWidthF           = 0.2           ; width of legend (NDC)
  lgres@vpHeightF          = 0.07            ; height of legend (NDC)
  lgres@lgPerimColor       = "black"       ; draw the box perimeter in orange
  lgres@lgPerimThicknessF  = 1.0            ; thicken the box perimeter
  lbid = gsn_create_legend(wks,2,(/"CAM-SE","IBTrACS"/),lgres)         ; create legend

  amres = True
  amres@amParallelPosF   = 0.3		    ; move legend to the right
  amres@amOrthogonalPosF = -.4             ; move the legend down
  annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot
    
  draw(plot)


  frame(wks)
 
end

