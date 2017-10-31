;================================================;
;	Example ncl script to produce the set of
;	lat-lon plots for DCMIP-2016 test case 1
; Created by James Kent, Christiane Jablonowski
;	and Paul Ullrich (University of Michigan) for DCMIP-2012 
;
; Modified by Colin Zarzycki for DCMIP-2016
;
; v1.01 - 6/7/16 
; v1.02 - 6/8/16 - Typo in var_choice options
;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"   
; ================================================;

; NOTE, if your model does not output T850 OR P at level
; midpoints OR you cannot calculate P from hybrid levels, you
; will need to make model specific additions denoted by
; CALCPHERE below

; PRECL needs to be in m/s for contours to plot correctly

begin

;=================================================;
; open file and read in data 
; GIVEN AS (time,lev,lat,lon) from 0 to n-1
;=================================================;

  ; NOTE, that this file needs to be a catted file including all times at daily interval
  ; if you are outputting 1 file per time, you can run "ncrcat dcmip1.files.*.nc cat.nc"
  ; for one file

   files = (/"/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/dtime900nsplit2/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/dtime900nsplit1/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/dtime1800nsplit2/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/dtime1800nsplit4/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/cjdtime900nsplit1/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/cjdtime1800nsplit2/dcmip1.cam.h0.2000-01-01-00000.nc",\
          "/glade/u/home/zarzycki/scratch/cam5_work/dcmip1/cjdtime1800nsplit4/dcmip1.cam.h0.2000-01-01-00000.nc"/)

  time_index = (/10,10,10,10,10,10,10/)

;  model = (/"CAM-SE","CSU","DYNAMICO","FV3","GEM","MPAS","NICAM","ICON","TEMPEST"/)
;  model = (/"CAM-SE","DYNAMICO","FV3","GEM","MPAS","NICAM","ICON","TEMPEST"/)
  model = (/"Colin dt=900s nsplit=2","Colin dt=900s nsplit=1","Colin dt=1800s nsplit=2","Colin dt=1800s nsplit=4","CJ dt=900s nsplit=1","CJ dt=1800s nsplit=2","CJ dt=1800s nsplit=4"/)

  pltType = "X11"
  pltType = "pdf"
  ;pltType = "eps"
  nfiles = dimsizes(files)             ; number of files
  panelSize = (/3,3/)    ; panel dimensions

  wks  = gsn_open_wks(pltType,"dcmip_161_preciponly_prect_day10_se_sensitivities")
;  gsn_define_colormap(wks,"gui_default")  
;  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
;  gsn_define_colormap(wks,"amwg256")
;  gsn_define_colormap(wks,"cosam")
  gsn_define_colormap(wks,"WhViBlGrYeOrRe")
;  plot = new(nfiles+1,graphic)
  plot = new(9,graphic)
;=================================================================
; Loop over all files --------------------------------------
;=================================================================
 do i = 0,nfiles-1       ; loop

  print("File "+files(i))

  f = addfile(files(i),"r")

		; Input useful parameters

  lat  = f->lat
  lon  = f->lon
  nlat   = getfilevardimsizes(f, "lat" )
  nlon   = getfilevardimsizes(f, "lon" )
  

    var = f->PRECT(time_index(i),{20:70},{30:210})

  printVarSummary(var)
  var@long_name = "PRECL"
  printMinMax(var,True)

	res1                      = True
	res1@gsnDraw              = False          		; panel plot 
	res1@gsnFrame             = False			; don't draw yet
	res1@cnFillOn             = True
	res1@cnLinesOn            = True
	res1@gsnSpreadColors      = True
	res1@lbLabelAutoStride    = True
	res1@gsnCenterString      = ""
	res1@tiMainString         = ""
	res1@vpWidthF             = 0.32
	res1@vpHeightF            = 0.16
	res1@cnLevelSelectionMode = "ManualLevels"
	res1@cnInfoLabelOn        = False			; don't give each
	res1@cnLineLabelsOn       = False			; panel its own
	res1@lbLabelBarOn         = False			; label bar

	pres                          = True
	pres@gsnMaximize              = True  
	pres@gsnPanelLabelBar         = True			; Communal label bar
	pres@gsnPanelLeft             = 0.1
	pres@gsnPanelRight            = 0.9
	pres@pmLabelBarOrthogonalPosF = -0.03
	pres@gsnFrame                 = False
	pres@lbLabelStride            = 1
        pres@lbTitleFontHeightF       = 0.06

;    if (i.eq.8) then
;	res1@sfXArray        = lon            			; uses lon as plot x-axis
;	res1@sfYArray        = lat            			; uses lat for y axis
;    end if
	res1@trYReverse      = False          			; reverses y-axis, false
	res1@tiYAxisString   = ""   	       			; y-axis title
	res1@tiXAxisString   = ""             			; x-axis title

	pltTitle="" 			; Plot title if required
	pres@txString = pltTitle

		; Convert to hPa 

        var=var*8.64e7
	var@units = "mm/day"

	res1@cnLevelSelectionMode = "ManualLevels" 
	res1@cnMaxLevelValF  = 60.0				; max contour color label
	res1@cnMinLevelValF  = 2.0				; min contour color label
	res1@cnLevelSpacingF = 2.0				; contour color spacing			; choose a colormap
;	res1@cnMaxLevelValF  = 1015.0				; max contour color label
;	res1@cnMinLevelValF  = 945.0				; min contour color label
;	res1@cnLevelSpacingF = 5.0				; contour color spacing			; choose a colormap

	res1@gsnCenterString = model(i)
	  plot(i) = gsn_csm_contour(wks,var(:,:),res1)		; plot var1

        delete (var)
        delete (lat)
        delete (lon)
        delete (nlat)
        delete (nlon)
end do
	gsn_panel(wks,plot,(/3,3/),pres)			; 3x3 plot

		; Add latitude and longitude labels

	txres3                = True

	txres3@txAngleF       = 90.
	txres3@txFontHeightF  = 0.015
	gsn_text_ndc(wks,"Latitude",0.08,0.49,txres3)

	txres3@txAngleF       = 0.
	gsn_text_ndc(wks,"Longitude",0.5,0.24,txres3)
        gsn_text_ndc(wks,"CAM-SE: DCMIP-2016 baroclinic wave with precip-only, Day 10",0.5,0.8,txres3)

	frame(wks)

   file1 = "/glade/scratch/cjablono/se_ne30L30_dcmip1/se_ne30L30_dcmip1.cam.h0.2000-01-01-00000.phys_dt_1800.ftype0.nc"
   file2 = "/glade/scratch/cjablono/se_ne30L30_dcmip1/se_ne30L30_dcmip1.cam.h0.2000-01-01-00000.phys_dt_1800.tstep_type1.nc"

   f1 = addfile(file1,"r")
   f2 = addfile(file2,"r")
   var1 = f1->PRECT(10,{20:70},{30:210})
   var2 = f2->PRECT(10,{20:70},{30:210})
   var3 = var2- var1
  printMinMax(var3,True)

end






