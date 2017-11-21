; ===========================================
; hov_5.ncl
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ===========================================
begin

numpanels = 2
phys_type = "CAM5"
plot_type = "pdf"

wks = gsn_open_wks(plot_type, "gill_"+phys_type)
plot = new(numpanels,graphic)
cont = new(numpanels,graphic)   

dum = new((/numpanels,1000/),graphic)   

do z = 0,numpanels-1

  if z .eq. 0 then
    plottype = "intdt"
  else
    plottype = "divstream"
  end if
  
  print("plottype is: "+plottype)
  
;---Names of source and weight file
;    src_file = "/glade/p/work/mlevy/HOMME_APE/uniform_15/camrun.cam.h1.0000-10-28-00000.nc"
;    src_file = "/glade/scratch/zarzycki/APE_levy/CAM4/uniform_15/h0avg.nc"
;    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"

;    src_file1 = "/glade/scratch/zarzycki/APE_levy/CAM4/quadrant_15_x8/fullavg.nc"

    ;plottype = "velopot"

    ;precipstream, velopot
    add_box = True

    src_file1 = "/glade/scratch/zarzycki/APE_levy/"+phys_type+"/quadrant_15_x8/h0avg.nc"
    ;src_file1 = "/glade/scratch/zarzycki/cam5_work/quad_15_x8_cam4_bam_ape/h0avg.nc"

    wgt_file1 = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"

    Opt         = True

;---Open files containing source HOMME and destination FV grids
    ;sfile = addfile(src_file,"r")
    
    ;u  = sfile->U(:,{200},:)            ; time (1) x ncol
    ;u_regrid  = ESMF_regrid_with_weights(u,wgt_file,Opt) 
    ;v  = sfile->V(:,{200},:)            ; time (1) x ncol
    ;v_regrid  = ESMF_regrid_with_weights(v,wgt_file,Opt)  

    sfile1 = addfile(src_file1,"r")
    
    lev = sfile1->lev
    hyam = sfile1->hyam
    hybm = sfile1->hybm
    P0 = sfile1->P0/100
    PS_se = rm_single_dims(sfile1->PS)
    PS  = ESMF_regrid_with_weights(PS_se,wgt_file1,Opt)
    pnew = (/ 200.0 /)
    
    levPa = lev*100
    levPa@units = "Pa"    ; to match PS

    ptop=0  ; integrate to top of atmosphere
    
    
    dp  = dpres_plevel(levPa, PS, ptop, 0)
    


    

; type of interpolation: 1 = linear, 2 = log, 3 = loglog
   interp = 2 
; is extrapolation desired if data is outside the range of PS
   extrap = True
    
    U = rm_single_dims(sfile1->U)
    u1  = ESMF_regrid_with_weights(U,wgt_file1,Opt)
    u_regrid = vinth2p(u1,hyam,hybm,pnew,PS,interp,P0,1,extrap)
    u_regrid1 = rm_single_dims(u_regrid)
    delete([/U,u1,u_regrid/])

    lat = u_regrid1&lat
    lon = u_regrid1&lon
    
    V = rm_single_dims(sfile1->V)
    v1  = ESMF_regrid_with_weights(V,wgt_file1,Opt)
    v_regrid = vinth2p(v1,hyam,hybm,pnew,PS,interp,P0,1,extrap)
    v_regrid1 = rm_single_dims(v_regrid)
    delete([/V,v1,v_regrid/])

    DTCOND = rm_single_dims(sfile1->DTCOND)
    dtcond1  = ESMF_regrid_with_weights(DTCOND,wgt_file1,Opt)
    dtcond_regrid = vinth2p(dtcond1,hyam,hybm,pnew,PS,interp,P0,1,extrap)
    dtcond_regrid1 = rm_single_dims(dtcond_regrid)
    ;delete([/DTCOND,dtcond1,dtcond_regrid/])



;    v1 = sfile1->V(:,{200},:)
;    v_regrid1  = ESMF_regrid_with_weights(v1,wgt_file1,Opt)

    prect1 = rm_single_dims(sfile1->PRECT)*86400*1000
    prect_regrid1  = ESMF_regrid_with_weights(prect1,wgt_file1,Opt)    
    delete([/prect1/])
    
    vort = uv2vrF_Wrap(u_regrid1,v_regrid1)
    vort = vort/1e-5
    
    div = uv2dvF_Wrap(u_regrid1,v_regrid1)
    div = div/1e-5


    u_diff = u_regrid1
    ;u_diff = u_regrid - u_regrid1
    v_diff = v_regrid1
    prec_diff = prect_regrid1
    vort_diff = vort
    div_diff = div
    dtcond_diff = dtcond_regrid1
    ;v_diff = v_regrid - v_regrid1

    ;v = sfile->V(:,{200},:)            ; time (1) x ncol

    
    ;v_regrid  = ESMF_regrid_with_weights(v,wgt_file,Opt)

;    u_regrid1 = u_regrid

; Vertically integrate DT

    dt_int_tmp = dtcond1*dp          ; temporary variable
    copy_VarCoords(dtcond1, dt_int_tmp)
    dt_int  = dim_sum_Wrap( dt_int_tmp(lat|:,lon|:,lev|:) )   ; LE(ntim,nlat,mlon)
    delete(dt_int_tmp)
    ;printVarSummary(dt_int)
    delete(dtcond_regrid1)
    dtcond_regrid1 = dt_int
    dtcond_diff = dtcond_regrid1
 

  
    sizes = (dimsizes(v_regrid1))
    nlat = sizes(0)
    nlon = sizes(1)
      
    u_zonal1 = dim_avg_n_Wrap(u_regrid1,1)
    v_zonal1 = dim_avg_n_Wrap(v_regrid1,1)
    prec_zonal1 = dim_avg_n_Wrap(prect_regrid1,1)
    vort_zonal1 = dim_avg_n_Wrap(vort,1)
    div_zonal1 = dim_avg_n_Wrap(div,1)
    dtcond_zonal1 = dim_avg_n_Wrap(dtcond_regrid1,1)
    
    do i = 0,nlon-1
      u_diff(:,i) = u_regrid1(:,i) - u_zonal1(:)
      v_diff(:,i) = v_regrid1(:,i) - v_zonal1(:)
      prec_diff(:,i) = prec_diff(:,i) - prec_zonal1(:)
      vort_diff(:,i) = vort_diff(:,i) - vort_zonal1(:)
      div_diff(:,i) = div_diff(:,i) - div_zonal1(:)
      dtcond_diff(:,i) = dtcond_diff(:,i) - dtcond_zonal1(:)
    end do
    
    uzonal2D = conform(u_regrid1,u_zonal1,0)
    vzonal2D = conform(v_regrid1,v_zonal1,0)
    
    steamvel = uv2sfvpF(uzonal2D,vzonal2D)
    streamavg = steamvel(0,:,:)/10e6
    velpotavg = steamvel(1,:,:)/10e6
    delete(steamvel)
    steamvel = uv2sfvpF(u_regrid1,v_regrid1)
    streamact = steamvel(0,:,:)/10e6
    velpotact = steamvel(1,:,:)/10e6   
    delete(steamvel)
    
    stream =  streamact - streamavg
    velpot = velpotact - velpotavg
    
    
;    prec_zonal_zonal = dim_avg_n_Wrap(prec_diff,2)
;    print(prec_zonal_zonal)

    
    ;steamvel = uv2sfvpF(u_diff,v_diff)
    ;stream = steamvel(0,:,:)/10e6
    ;velpot = steamvel(1,:,:)/10e6
    copy_VarMeta(u_diff,stream)
    copy_VarMeta(u_diff,velpot)
    
    prec_diff@units = "mm/day"
    prec_diff!0 = "lat"
    prec_diff!1 = "lon"
    prec_diff&lat = lat
    prec_diff&lon = lon
    prec_diff@long_name = "Precipitation deviation from zonal average"

    stream@units = "10e6 m2 s-1"
    stream!0 = "lat"
    stream!1 = "lon"
    stream&lat = lat
    stream&lon = lon
    stream@long_name = "200 hPa eddy streamfunction"
    
    dtcond_diff@units = "K/s"
    dtcond_diff!0 = "lat"
    dtcond_diff!1 = "lon"
    dtcond_diff&lat = lat
    dtcond_diff&lon = lon
    dtcond_diff@long_name = "Vertically Integrated Moist Temperature Tendency Zonal Anamoly"

    velpot@units = "10e6 m2 s-1"
    velpot!0 = "lat"
    velpot!1 = "lon"
    velpot&lat = lat
    

    
conserve_remap = True
gridsize = 2.0
if (conserve_remap) then
  latS = -90
  latN =  90
  lonW = 0
  lonE = 360
  dlat =  gridsize
  dlon =  gridsize
  noutlat = toint((latN-latS)/dlat) + 1
  moutlon = toint((lonE-lonW)/dlon)
  outlat  = fspan(latS, latN, noutlat)
  outlon  = fspan(lonW, lonE-dlon, moutlon)
  outlat@units = "degrees_north"
  outlon@units = "degrees_east"
  div_remap = area_conserve_remap_Wrap (div&lon,div&lat,div_diff,outlon,outlat,False)
  div_remap@long_name = "200 hPa Divergence Zonal Anomaly (Shaded)"
end if




	if (add_box) then
		mesh_color = "Grey55" 
		region_color = "Black"

		color_map2 = (/mesh_color, region_color/)

		res_p = True
		res_p@gsLineThicknessF = 3.0
		res_p@gsLineColor = region_color

		; Set up coordinates for refinement zone
		pi = 2.d*acos(0)
		lambda = 36.d ; Pi / 5 radians in degrees
		theta = atan(sin(pi/5.d))*180.d/pi ; map from (Pi/5,Pi/5) on cube sphere -> latlon
		lambda2 = 45.d ; Pi / 4 radians in degrees
		theta2 = atan(sin(pi/4.d))*180.d/pi ; map from (Pi/4,Pi/4) on cube sphere -> latlon

		num_int = 10
		lamb = new((/num_int+1/),"double")
		thet = new((/num_int+1/),"double")
		lamb2 = new((/num_int+1/),"double")
		thet2 = new((/num_int+1/),"double")
		do j=0,num_int
			alpha = -pi/5.d + 2*j*pi/(5.d*num_int)
			beta = -pi/5.d
			alpha2 = -pi/4.d + 2*j*pi/(4.d*num_int)
			beta2 = -pi/4.d

			lamb(j) = alpha*180.d/pi
			thet(j) = atan(tan(beta)*cos(alpha))*180.d/pi
			lamb2(j) = alpha2*180.d/pi
			thet2(j) = atan(tan(beta2)*cos(alpha2))*180.d/pi
		end do

	end if
	
	
	
;==============================================
; create color plot
;=============================================
  ;wks  = gsn_open_wks (plot_type, plottype+"_"+phys_type )            ; open ps file
  gsn_define_colormap(wks,"BlueWhiteOrangeRed")             ; choose colormap

  res                      = True               ; plot mods desired
  res_p = True
  res@cnFillOn             = True               ; turn on color fill
  res@cnLinesOn       = False                   ; turn off contour lines
  res@cnLineLabelsOn  = False                   ; tuen off line labels
	res@gsnFrame = False
	res@gsnDraw = False
	
	res@mpOutlineOn = False
		
print(plottype)
if (plottype .eq. "velopot") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = -0.25
  res@cnMaxLevelValF  = 0.25
  res@cnLevelSpacingF = 0.05
  ; This is the velo potential from Rauscher (2013)
  plot(z) = gsn_csm_contour_map(wks,velpot(::2,::2),res)
  ;contour = gsn_csm_streamline_map_ce(wks,u_diff(::5,::5),v_diff(::5,::5),res)
  ;contour = gsn_csm_vector_map(wks,u_diff(::40,::40),v_diff(::40,::40),res)
  ;draw(contour)
else if (plottype .eq. "intdt") then
  print("Got here")
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = -3.0
  res@cnMaxLevelValF  = 3.0
  res@cnLevelSpacingF = 0.3
  plot(z) = gsn_csm_contour_map(wks,dtcond_diff(::1,::1),res)
  print("Got here")
  ;draw(contour)
else if (plottype .eq. "precipstream")
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = -16
  res@cnMaxLevelValF  = 16
  res@cnLevelSpacingF = 2
  res2 = True
  res2@gsnContourNegLineDashPattern = 1
  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res2@cnMinLevelValF  = -.55			; set the minimum contour level
  res2@cnMaxLevelValF  = .55			; set the maximum contour level
  res2@cnLevelSpacingF = .1			; set the interval between contours
  ;res2@tiMainString = phys_type
  ; Uncomment this to overlay zonally different precip and streamfunction
  plot(z) = gsn_csm_contour_map_overlay(wks,prec_diff(::8,::8),stream(::8,::8),res,res2)
  ;draw(contour)
else if (plottype .eq. "divstream")
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = -0.5
  res@cnMaxLevelValF  = 0.5
  res@cnLevelSpacingF = 0.1
  res2 = True
  res2@gsnContourNegLineDashPattern = 1
  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res2@cnMinLevelValF  = -.55			; set the minimum contour level
  res2@cnMaxLevelValF  = .55			; set the maximum contour level
  res2@cnLevelSpacingF = .1			; set the interval between contours
  res2@cnLineLabelsOn = False
  res2@tiMainString = ""
  ; Uncomment this to overlay zonally different precip and streamfunction
  plot(z) = gsn_csm_contour_map_overlay(wks,div_remap(::1,::1),stream(::8,::8),res,res2)
  ;draw(contour)
end if
end if
end if
end if

  res@gsnSpreadColors      = True               ; use full range of colors

					

					dum(z,0) = gsn_add_polyline(wks, plot(z), -(/lambda, lambda/), (/-theta, theta/), res_p)
					dum(z,1) = gsn_add_polyline(wks, plot(z),  (/lambda, lambda/), (/-theta, theta/), res_p)

					do j=0,num_int-1
						dum(z,4+j) = gsn_add_polyline(wks, plot(z), (/lamb(j), lamb(j+1)/), -(/thet(j), thet(j+1)/), res_p)
						dum(z,4+num_int+j) = gsn_add_polyline(wks, plot(z), (/lamb(j), lamb(j+1)/),  (/thet(j), thet(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0

					dum(z,2) = gsn_add_polyline(wks, plot(z), -(/lambda2, lambda2/), (/-theta2, theta2/), res_p)
					dum(z,3) = gsn_add_polyline(wks, plot(z),  (/lambda2, lambda2/), (/-theta2, theta2/), res_p)

					do j=0,num_int-1
						dum(z,4+(2*num_int)+j) = gsn_add_polyline(wks, plot(z), (/lamb2(j), lamb2(j+1)/), -(/thet2(j), thet2(j+1)/), res_p)
						dum(z,4+(3*num_int)+j) = gsn_add_polyline(wks, plot(z), (/lamb2(j), lamb2(j+1)/),  (/thet2(j), thet2(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0

				;frame(wks)
				
delete(res)
;delete(res2)

end do

;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  ;resP@gsnPanelLabelBar = True                   ; add common colorbar

  ;resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
  ;resP@lbLabelStride    = 4
  ;resP@pmLabelBarWidthF = 0.7
  
  amres = True
  amres@amJust           = "TopLeft"
  resP@gsnPanelFigureStrings= (/"a.","b."/)
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  
  gsn_panel(wks,plot,(/numpanels,1/),resP)               ; now draw as one plot
  
end

