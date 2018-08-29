;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ================================================;
begin
;=================================================;
; open file and read in data
;=================================================;

  whois = "colin"   ; options are colin, diana
  
  ; if alltimes is true, script will just read all times on data file(s)
  ; if false, timestart and timestop specify the DIRECT indices in the input[:]
  ; array we want to extract
  alltimes=True
  timestart=0
  timestop=3
  ; Pick region for indexing -- for global domain, input:
  ; -90 -> 90 and 0 -> 360
  minlat=25.
  maxlat=50.
  minlon=235.
  maxlon=290.
  
  out_format = "pdf"
  
  ; Only turn on for debugging purposes (puts print statements in if debug
  ; logical checks)
  debug = False
  
  ; if conserve_remap is true, NCL will re-bin values from native grid
  ; to a lat-lon grid of uniform dx/dy spacing defined by gridsize
  ; Typically gridsize is 5.0 in Williamson papers, but can also be set to
  ; 2.0 or 1.0 for "higher-res" simulations
  conserve_remap = True
  gridsize = 2.0

  variable = "PRECT"        ; variable name
  xmin = (/0.0,0.0/)             ; x axis minimums
  xmax = (/100.,300./)           ; x axis maximums
  ymin = (/1e-8/)                ; y minimum (both panels)
  ymax = (/1e0/)                 ; y maximum (both panels)
  titles = (/" "," "/)           ; titles
  axis_labels = (/"fraction"," "/)               ; y axis labels
  colorAll = (/"red3","blue3","pink2","skyblue2"/)      ; line colors
  
    gridlist = (/"conus_30_x8","ne30","mp15a-120a-US","mp120a"/)
    physpkg = "CAM6"
    nfiles = dimsizes(gridlist)
    dycore_labelsAll = (/"conus_30_x8","ne30","mp15a-120a-US","mp120a"/)
    needs_regrid=True
  
  panels1 = new(2,graphic)

; Input data --------------------------
print("Variable: "+variable)

do file_step=0,nfiles-1  ; dycore loop
print("      File "+file_step)

    gridname = gridlist(file_step)
    print("Doing grid: "+gridname)
    
    if (gridname .eq. "conus_30_x8") then
      fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp211/atm/hist/"
      wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.125x0.125reg_patch.nc"
    else if (gridname .eq. "ne30") then
      fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.exp212/atm/hist/"
      wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1reg_patch.nc"
    else if (gridname .eq. "mp15a-120a-US") then
      fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp213/atm/hist/"
      wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"
    else if (gridname .eq. "mp120a") then
      fdir1="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp214/atm/hist/"
      wgt_file = "/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_mp120a_to_1x1reg_patch.nc"
    else
      print("Uh, don't have a grid for that!")
      exit
    end if
    end if
    end if
    end if

   fnam1 = fdir1+"/*.cam.h2.2011*nc"

   files1 = systemfunc("ls "+fnam1)
   input = addfiles(files1,"r")
   ListSetType(input,"cat")

;---------------

if (alltimes) then
  timestart = 0
  timestop = dimsizes(input[:]->time)-1
end if

print("Using grid: "+gridname+"      minlon="+minlon+" maxlon="+maxlon)
if (needs_regrid .eq. True) then
  var_se = input[:]->$variable$(timestart:timestop,:)
  Opt         = True
  var_in1  = ESMF_regrid_with_weights(var_se,wgt_file,Opt)
  delete(var_se)
  var_in = var_in1(:,{minlat:maxlat},{minlon:maxlon})
  delete(var_in1)
else
  var_in  = input[:]->$variable$(timestart:timestop,{minlat:maxlat},{minlon:maxlon})
end if

if (conserve_remap) then
  print("Remapping...")
  latS = minlat
  latN =  maxlat
  lonW = minlon
  lonE = maxlon

  dlat =  gridsize
  dlon =  gridsize
  noutlat = toint((latN-latS)/dlat) + 1
  moutlon = toint((lonE-lonW)/dlon)
  outlat  = fspan(latS, latN, noutlat)
  outlon  = fspan(lonW, lonE-dlon, moutlon)
  outlat@units = "degrees_north"
  outlon@units = "degrees_east"
  print("fo")
  fo = new((/timestop+1,noutlat,moutlon/),"float")
  do ii = 0,timestop
    print(ii+"")
    fo(ii,:,:) = area_conserve_remap_Wrap (var_in&lon,var_in&lat,var_in(ii,:,:),outlon,outlat,False)
  end do
  print("f1")
  delete(var_in)
  var_in = fo
  delete(fo)
end if

  var = var_in*86400000          ; convert to mm/day
  var_reshape = ndtooned(var)    ; reshape to 1D
  if (debug) then
    nor   = random_normal(200., 30., dimsizes(var_reshape))  ; normal(10, 100)
    delete(var_reshape)
    var_reshape = nor
    delete(nor)
  end if
  hist_size = floattointeger(ceil(max(var_reshape)))  ; find max bin size 
printMinMax(var_reshape,True)
print("Number of samples: "+dimsizes(var_reshape))
print("Histsize is "+hist_size)
   hist = new(hist_size,float)
   hist10 = new(floattointeger(ceil(hist_size/10.)),float)

; set initial histogram values to zero
   do i = 0,dimsizes(hist) - 1
      hist(i) = 0.0
   end do
   do i = 0,dimsizes(hist10) - 1
      hist10(i) = 0.0
   end do

; bin precipitation data, excluding negative values
   do i = 0,dimsizes(var_reshape)-1
      tmp = floattointeger(floor(var_reshape(i)))
      tmp10 = floattointeger(floor(var_reshape(i)/10))
      if (tmp .ge. 0.0) then
          ;if mod(i,10) .eq. 0 then
          ;  print(" "+tmp+"  "+tmp10)
          ;end if
          hist(tmp) = hist(tmp) + 1
          hist10(tmp10) = hist10(tmp10) + 1
;;; Uncomment out the below to stick negative and zero values in first
;;; histogram box
;      else
;          hist(0) = hist(0) + 1
      end if
   end do

;printVarSummary(hist)
;printVarSummary(hist10)
;   do i = 0,dimsizes(hist)-10,10
;      if (i+10 .lt. dimsizes(hist)) then
;      do j = i,i+10
;         hist10(i/10) = hist10(i/10) + hist(j)
;      end do
;      else
;      do j = i,dimsizes(hist)-1
;         hist10(i/10) = hist10(i/10) + hist(j)
;      end do
;      end if
;   end do
   
   

print(sum(hist))
;print("  ")
print(sum(hist10))

   hist2 = new(2*dimsizes(hist)-2,float)
   hist210 = new(floattointeger(ceil(2*(dimsizes(hist10)))),float)
   xval = new(dimsizes(hist2),integer)
   xval10 = new(dimsizes(hist210),integer)

; create arrays for plotting
   tmp = 0
   do i = 0,dimsizes(hist2)-2,2
      hist2(i) = hist(i/2)
      hist2(i+1) = hist(i/2)
      xval(i) = tmp
      xval(i+1) = tmp+1
      tmp = tmp + 1
   end do

   tmp = 0
   do i = 0,dimsizes(hist210)-2,2
       hist210(i) = hist10(i/2)
       hist210(i+1) = hist10(i/2)
       xval10(i) = tmp*10
       xval10(i+1) = (tmp+1)*10
       tmp = tmp + 1
   end do

; reset all zeros to fill value
  do j = 0,dimsizes(hist2)-1
     if (hist2(j) .eq. 0) then
        hist2(j) = hist2@_FillValue
     end if
  end do
  do j = 0,dimsizes(hist210)-1
     if (hist210(j) .eq. 0) then
        hist210(j) = hist210@_FillValue
     end if
  end do

   if (file_step .eq. 0) then
      var0 = hist2/sum(hist)
      var01 = hist210/sum(hist)
      printMinMax(var0,True)
      xval0 = xval
      xval01 = xval10
   else if (file_step .eq. 1) then
      var1 = hist2/sum(hist)
      var11 = hist210/sum(hist)
      printMinMax(var1,True)
      xval1 = xval
      xval11 = xval10
   else if (file_step .eq. 2) then
      var2 = hist2/sum(hist)
      var21 = hist210/sum(hist)
      printMinMax(var2,True)
      xval2 = xval
      xval21 = xval10
   else if (file_step .eq. 3) then
      var3 = hist2/sum(hist)
      var31 = hist210/sum(hist)
      printMinMax(var3,True)
      xval3 = xval
      xval31 = xval10
   end if
   end if
   end if
   end if

   delete([/files1,input,var_in,var,var_reshape,hist,hist10,hist2,hist210,xval,xval10/])

end do   ; dycore loop
;----------------
; Print sums to make sure they are close to 1
; We have to divide by 2 because we duplicate the array to draw left
; and right corners of boxes in histogram

print("1 bin sum of "+gridlist(0)+" is: "+(sum(var0)/2))
print("-------------")
print("10 bin sum of "+gridlist(0)+" is: "+(sum(var01)/2))

   wks  = gsn_open_wks(out_format,"precip_hist_all")

; First Panel ---------------------------------

  ; Truncate colors and labels arrays
  color = colorAll(0:nfiles-1)
  dycore_labels = dycore_labelsAll(0:nfiles-1)
  
  res = True
  res@tiMainString = titles(0)
  res@tiYAxisString = axis_labels(0)
  res@tiXAxisString = "mm day:S:-1:N:"
  res@gsnDraw = False
  res@gsnFrame = False
  res@trYLog = True
  res@trYMinF = ymin
  res@trYMaxF = ymax
  res@trXMinF = xmin(0)
  res@trXMaxF = xmax(0)
  ;res@xyLineThicknessF = 2.0
  res@xyMonoLineThickness = False
  res@xyLineThicknesses = (/3.0,3.0,2.0,2.0/)


  res@xyLineColor = color(0)  
  plot0 = gsn_csm_xy(wks,xval0,var0,res)

  res@xyLineColor = color(1)
  plot1 = gsn_csm_xy(wks,xval1,var1,res)

  res@xyLineColor = color(2)
  plot2 = gsn_csm_xy(wks,xval2,var2,res)

  res@xyLineColor = color(3)
  plot3 = gsn_csm_xy(wks,xval3,var3,res)

  overlay(plot0,plot1)
  overlay(plot0,plot2) 
  overlay(plot0,plot3)

  panels1(0) = plot0

; Attach a legend ------------------

  lgres                    = True
  lgres@lgLineColors       = color(::-1)    ; reverse color order in legend
  lgres@lgDashIndexes      = (/0,0,0,0/)    ; all solid lines
  lgres@lgLineThicknesses   = res@xyLineThicknesses
  lgres@lgLabelFontHeightF = .20            ; legend label font thickness
  lgres@lgBoxMinorExtentF  = 0.60          ; adjust legend size
  lgres@vpWidthF           = 0.13           ; width of legend (NDC)
  lgres@vpHeightF          = 0.10           ; height of legend (NDC)
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter

  labels = dycore_labels(::-1)              ; reverse dycore order in legend
  legend = gsn_create_legend (wks, nfiles, labels,lgres)

  amres                  = True
  amres@amJust           = "BottomRight"    ; Use bottom right corner of box
                                            ; for determining its location.
  amres@amParallelPosF   = 0.5              ; Move legend to right
  amres@amOrthogonalPosF = -0.334              ; Move legend down.

  annoid = gsn_add_annotation(plot0,legend,amres)  ; add legend to plot

; Second Panel ---------------------------------

  res@tiMainString = titles(1)
  res@tiYAxisString = axis_labels(1)
  res@trXMinF = xmin(1)
  res@trXMaxF = xmax(1)

  res@xyLineColor = color(0)
  plot0 = gsn_csm_xy(wks,xval01,var01,res)

  res@xyLineColor = color(1)
  plot1 = gsn_csm_xy(wks,xval11,var11,res)

  res@xyLineColor = color(2)
  plot2 = gsn_csm_xy(wks,xval21,var21,res)

  res@xyLineColor = color(3)
  plot3 = gsn_csm_xy(wks,xval31,var31,res)

  overlay(plot0,plot1)
  overlay(plot0,plot2)
  overlay(plot0,plot3)

  panels1(1) = plot0

; Attach a legend ------------------

  legend = gsn_create_legend (wks, nfiles, labels,lgres)

  annoid = gsn_add_annotation(plot0,legend,amres)  ; add legend to plot


;-------------------------


  resP = True
  resP@gsnMaximize = True
  resP@gsnPanelXF = (/-1,0.59/)
  gsn_panel(wks,panels1,(/1,2/),resP)

  end
