; ===========================================
; hov_5.ncl
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ===========================================
begin

;---Names of source and weight file
;    src_file = "/glade/p/work/mlevy/HOMME_APE/uniform_15/camrun.cam.h1.0000-10-28-00000.nc"
    src_file = "/glade/scratch/zarzycki/APE_levy/CAM4/uniform_15/fullavg.nc"
    wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"

    src_file1 = "/glade/scratch/zarzycki/APE_levy/CAM4/quadrant_15_x8/fullavg.nc"
    wgt_file1 = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"
    

    Opt         = True

;---Open files containing source HOMME and destination FV grids
    ;sfile = addfile(src_file,"r")
    
    ;u  = sfile->U(:,{200},:)            ; time (1) x ncol
    ;u_regrid  = ESMF_regrid_with_weights(u,wgt_file,Opt) 
    ;v  = sfile->V(:,{200},:)            ; time (1) x ncol
    ;v_regrid  = ESMF_regrid_with_weights(v,wgt_file,Opt)  

    sfile1 = addfile(src_file1,"r")
    
    u1 = sfile1->U(:,{200},:)
    u_regrid1  = ESMF_regrid_with_weights(u1,wgt_file1,Opt)

    v1 = sfile1->V(:,{200},:)
    v_regrid1  = ESMF_regrid_with_weights(v1,wgt_file1,Opt)

    prect1 = sfile1->PRECT(:,:)
    prect_regrid1  = ESMF_regrid_with_weights(prect1,wgt_file1,Opt)    


    u_diff = u_regrid1
    ;u_diff = u_regrid - u_regrid1
    v_diff = v_regrid1
    prec_diff = prect_regrid1
    ;v_diff = v_regrid - v_regrid1

    ;v = sfile->V(:,{200},:)            ; time (1) x ncol

    
    ;v_regrid  = ESMF_regrid_with_weights(v,wgt_file,Opt)

;    u_regrid1 = u_regrid
 

  
    sizes = (dimsizes(v_regrid1))
    nlat = sizes(1)
    nlon = sizes(2)
      
    u_zonal1 = dim_avg_n_Wrap(u_regrid1,2)
    v_zonal1 = dim_avg_n_Wrap(v_regrid1,2)
    prec_zonal1 = dim_avg_n_Wrap(prect_regrid1,2)
    
    do i = 0,nlon-1
      u_diff(0,:,i) = u_regrid1(0,:,i) - u_zonal1(0,:)
      v_diff(0,:,i) = v_regrid1(0,:,i) - v_zonal1(0,:)
      prec_diff(0,:,i) = prec_diff(0,:,i) - prec_zonal1(0,:)
    end do

    
    steamvel = uv2sfvpF(u_diff(0,:,:),v_diff(0,:,:))
    stream = steamvel(0,:,:)/10e6
    velpot = steamvel(1,:,:)/10e6
    
    copy_VarMeta(u_diff(0,:,:),stream)
    copy_VarMeta(u_diff(0,:,:),velpot)

 ;   printVarSummary(stream)

	add_box = True
;	add_box = False

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
  wks  = gsn_open_wks ("x11", "gill" )            ; open ps file
  gsn_define_colormap(wks,"precip3_16lev")             ; choose colormap

  res                      = True               ; plot mods desired
  		res_p = True
  res@cnFillOn             = True               ; turn on color fill
  res@cnLinesOn       = False                   ; turn off contour lines
  res@cnLineLabelsOn  = False                   ; tuen off line labels
		res@gsnFrame = False
		res@gsnDraw = False

;---This resource not needed in V6.1.0
  res@gsnSpreadColors      = True               ; use full range of colors

;  res@tiMainString         = "Pacific Region"   ; title

;  res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
;  res@cnMinLevelValF       = -10.	        ; min level
;  res@cnMaxLevelValF       =  10.               ; max level
;  res@cnLevelSpacingF      = 2.                 ; contour level spacing

;  res@stLineStartStride = 10

;res@vcRefMagnitudeF       = 2.0

  contour = gsn_csm_contour_map(wks,prec_diff(0,::5,::5),res)
;  plot = gsn_csm_streamline_map_ce(wks,u_diff(0,::5,::5),v_diff(0,::5,::5),res)
;plot = gsn_csm_vector_map(wks,u_diff(0,::40,::40),v_diff(0,::40,::40),res)


draw(contour)
					

					gsn_polyline(wks, contour, -(/lambda, lambda/), (/-theta, theta/), res_p)
					gsn_polyline(wks, contour,  (/lambda, lambda/), (/-theta, theta/), res_p)

					do j=0,num_int-1
						gsn_polyline(wks, contour, (/lamb(j), lamb(j+1)/), -(/thet(j), thet(j+1)/), res_p)
						gsn_polyline(wks, contour, (/lamb(j), lamb(j+1)/),  (/thet(j), thet(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0

					gsn_polyline(wks, contour, -(/lambda2, lambda2/), (/-theta2, theta2/), res_p)
					gsn_polyline(wks, contour,  (/lambda2, lambda2/), (/-theta2, theta2/), res_p)

					do j=0,num_int-1
						gsn_polyline(wks, contour, (/lamb2(j), lamb2(j+1)/), -(/thet2(j), thet2(j+1)/), res_p)
						gsn_polyline(wks, contour, (/lamb2(j), lamb2(j+1)/),  (/thet2(j), thet2(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0

				frame(wks)

  
end
