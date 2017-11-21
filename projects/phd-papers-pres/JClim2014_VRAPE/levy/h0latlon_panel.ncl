; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

loop = True
var_loop_over = (/"PRECT","CLDTOT"/)
diff_loop_over = (/False,True/)
physicspkg_loop_over = (/"CAM4","CAM5"/)
output_format = "pdf"

do ii = 0,dimsizes(var_loop_over)-1
do jj = 0,dimsizes(diff_loop_over)-1
do kk = 0,dimsizes(physicspkg_loop_over)-1

;	output_format = "pdf"
;	output_format = "ps"

;	run_names = (/"quad_15_x4", "uniform_15", "uniform_60"/)
	run_names = (/"2~S~o~N~ (coarse)","VR", "0.25~S~o~N~ (fine)"/)
;	var_names = (/"PRECT", "PRECL", "PRECC", "PS","CLDTOT","OMEGA","OMEGA300","EKE100"/)
  var_names = var_loop_over(ii)
;	var_names = "CLDTOT"
;	var_names = "OMEGA"

do_both = False
physicspkg=physicspkg_loop_over(kk) ; if do_both = true, this is irrelevant
;	If diff is true, plot difference between refined and high-res
;	If add_box is also true, plot of difference will highlight refined region
diff = diff_loop_over(jj)
add_box = True

if do_both .eq. True then
  numphystypes = 2
  plotnames = var_names+"_CAM4CAM5"
  if diff .eq. True then
    plotnames = plotnames+"_diff"
  end if
else
  numphystypes = 1
  plotnames = var_names+"_"+physicspkg
  if diff .eq. True then
    plotnames = plotnames+"_diff"
  end if
end if

wks = gsn_open_wks(output_format,plotnames)
plot = new(3*numphystypes,graphic)

	
	dum = new((/2,3,1000/),graphic)
	
;quadrant, uni_120, uni15
do physloop = 0,numphystypes-1

if do_both .eq. True
  if (physloop .eq. 0) then
    physicspkg="CAM4"
  else
    physicspkg="CAM5"
  end if
end if
		
	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_15/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_120/h0avg_regrid_0.25x0.25.nc ; "\
		)

  wnames = (/"/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc",\
   "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc",\
   "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc"/)
 
 if_regrid = False

;/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc


if (diff) then
	color_map = "BlueWhiteOrangeRed"
	;color_map = "sunshine_diff_12lev"
else
	color_map = "WhiteBlueGreenYellowRed"
end if

;	color_map = "WhiteBlue"
;	color_map = "matlab_hot"

	
	



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





	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)
	print(fnames)
	print(wnames)
	
if (diff .eq. False) then

	do fk=0,fcnt-1
		f=fall[fk]
		wgt=wnames(fk)

		if (add_box) then
			if (fk.eq.0) then
				add_fine_region = False
				add_coarse_region = False
				add_fine_mesh = False
				add_coarse_mesh = False
			end if

			if (fk.eq.1) then
				add_fine_region = False
				add_coarse_region = False
				add_fine_mesh = True
				add_coarse_mesh = True
			end if

			if (fk.eq.2) then
				add_fine_region = False
				add_coarse_region = False
				add_fine_mesh = False
				add_coarse_mesh = False
			end if
		end if

    if (if_regrid .ne. True)
      nlat = dimsizes(f&lat)
      nlon = dimsizes(f&lon)
  
      name = run_names(fk)
      print (run_names(fk)+": nlat x nlon "+nlat+"x"+nlon)
		end if

		; type of interpolation: 1 = linear, 2 = log, 3 = loglog
		interp = 2 
		; is extrapolation desired if data is outside the range of PS
		extrap = True

		;
		;  contour plot
		;
		res                     = True
		res@gsnMaximize         = True         ; Maximize size of plot in frame
    res@gsnDraw = False
    res@gsnFrame = False
		res@gsnPaperOrientation = "portrait"
		res@gsnSpreadColors     = True         ; Use full colormap, but start
		res@cnFillOn            = True         ; Turn on contour fill
		res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
		res@cnLinesOn           = False        ; Turn off contour lines
		res@cnLineLabelsOn      = False        ; Turn off contour line labels
		res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
		res@lbBoxLinesOn        = False        ; Turn of labelbar box lines.
		res@mpOutlineOn          = False
		res@mpFillOn             = False
		res@gsnFrame = False
		res@gsnDraw = False
		res@gsnAddCyclic = True
		

    res@cnInfoLabelOn       = False
    res@lbLabelBarOn        = False           ; turn off individual cb's

		res@gsnStringFont = 21
		res@lbLabelFont = 21
		res@lgLabelFont = 21
		res@tmYLLabelFont = 21    ;  21 = helvetica
		res@tmXBLabelFont = 21    ;  22 = helvetica-bold 
		res@tmXTLabelFont = 21    ;  22 = helvetica-bold 
		
	  res@gsnLeftString = ""
    res@gsnRightString = ""

		res@cnLevelSelectionMode = "ManualLevels"
		if (physloop .eq. 0) then
		  res@tiMainString        = run_names(fk)
		else
		  res@tiMainString = ""
		end if

		do m=0,dimsizes(var_names)-1
			print("Plotting "+var_names(m)+" for "+run_names(fk))
			make_plot = False

			if (output_format.eq."ps") then
				output_vars = run_names(fk)+"-"+var_names(m)
				plotnames = "h0latlon-"+output_vars
				plotnames = "./"+output_format+"/"+plotnames
			end if
				
			if (var_names(m).eq."PRECT" ) then
				if (if_regrid .eq. True)
          ps_se = f->PRECT(0,:)
          ps = ESMF_regrid_with_weights(ps_se,wgt,False)
          delete(ps_se)
          lon = ps&lon
				else
				  ps = f->PRECT(0,:,:)
				end if
				; convert to mm/day
				ps=ps*1000*24*3600
				ps@units="mm/day"
				print((/min(ps),max(ps)/))

				res@cnMinLevelValF = 0.
				res@cnMaxLevelValF = 36.
				res@cnLevelSpacingF = 3.
				make_plot = True
			end if

			if (var_names(m).eq."PRECL" ) then
				ps = f->PRECL(0,:,:)
				; convert to mm/day
				ps=ps*1000*24*3600
				ps@units="mm/day"
				print((/min(ps),max(ps)/))
				
				res@cnMinLevelValF = 0.
				res@cnMaxLevelValF = 30.
				res@cnLevelSpacingF = 3.
				make_plot = True
			end if

			if (var_names(m).eq."PRECC") then
				ps = f->PRECC(0,:,:)
				; convert to mm/day
				ps=ps*1000*24*3600
				ps@units="mm/day"
				print((/min(ps),max(ps)/))
				
				res@cnMinLevelValF = 0.
				res@cnMaxLevelValF = 18.
				res@cnLevelSpacingF = 2.
				make_plot = True
			end if

			if (var_names(m).eq."PS") then
				ps = f->PS(0,:,:)
				copyatt( ps, f->PS(0,:,:))
				ps=ps/100
				ps@units="mb"
				print((/min(ps),max(ps)/))
				res@cnMinLevelValF = 990.
				res@cnMaxLevelValF = 1030.
				res@cnLevelSpacingF = 4.
				make_plot = True
			end if

			if (var_names(m).eq."CLDTOT") then

				if (if_regrid .eq. True)
          ps_se = f->CLDTOT(0,:)
          ps = ESMF_regrid_with_weights(ps_se,wgt,False)
          delete(ps_se)
          lon = ps&lon
				else
				  ps = f->CLDTOT(0,:,:)
				end if
				
				
				print((/min(ps),max(ps)/))
				res@cnMinLevelValF = .2
				res@cnMaxLevelValF = 1.0
				res@cnLevelSpacingF = .05
				make_plot = True
			end if

			if (var_names(m).eq."FLNT") then
				ps = f->FLNT(0,:,:)
				copyatt( ps, f->FLNT(0,:,:))
				print((/min(ps),max(ps)/))
				res@cnMinLevelValF = 160.
				res@cnMaxLevelValF = 290.
				res@cnLevelSpacingF = 10.
				make_plot = True
			end if
			
			if (var_names(m).eq."TMQ") then
				ps = f->TMQ(0,:,:)
				copyatt( ps, f->TMQ(0,:,:))
				print((/min(ps),max(ps)/))
				res@cnMinLevelValF = 8.
				res@cnMaxLevelValF = 60.
				res@cnLevelSpacingF = 4.
				make_plot = True
			end if

			if (var_names(m).eq."OMEGA") then
				ps = f->OMEGA(0,4,:,:)
				copyatt(ps, f->OMEGA(0,4,:,:))
				ps@long_name = ps@long_name+", 4th level"
				print((/min(ps),max(ps)/))
				res@cnMinLevelValF = -.0025
				res@cnMaxLevelValF = .0025
				res@cnLevelSpacingF = .00025
				make_plot = True
			end if

			if (var_names(m).eq."OMEGA300") then
				omega = f->OMEGA(0,:,:,:) 
				lev_p = 300
				P0mb=(f->P0)/100
				Up = vinth2p(f->OMEGA(0,:,:,:),f->hyam,f->hybm,lev_p,f->PS(0,:,:),interp,P0mb,1,extrap)
				ps = Up(0,:,:)
				copyatt(ps,omega(0,:,:))
				ps@long_name = omega@long_name + ", 300mb"
				print((/min(ps),max(ps)/))
				delete(omega)
				delete(Up)
				res@cnMinLevelValF = -.35
				res@cnMaxLevelValF = .05
				res@cnLevelSpacingF = .05
				make_plot = True
			end if

			if (var_names(m).eq."EKE100") then
				eke = (f->UU(0,:,:,:)-f->U(0,:,:,:)^2)
				eke = eke + (f->VV(0,:,:,:)-f->V(0,:,:,:)^2)
				eke= eke/2
				lev_p = 100
				P0mb=(f->P0)/100
				Up = vinth2p(eke,f->hyam,f->hybm,lev_p,f->PS(0,:,:),interp,P0mb,1,extrap)
				ps = Up(0,:,:)
				copyatt(ps,f->U(0,0,:,:)) ; Get lat/lon
				copyatt(ps,eke(0,:,:))
				print((/min(ps),max(ps)/))
				delete(eke)
				delete(Up)
				ps@long_name = "EKE "+lev_p+"mb"
				
				res@cnMinLevelValF = 0.
				res@cnMaxLevelValF = 150.
				res@cnLevelSpacingF = 15.
				make_plot = True
			end if

			if (make_plot) then

				if (run_names(fk).eq."quadrant_15_x8") then
				  if (if_regrid .ne. True)
					  lon = f->lon
					end if
					if ((lon(0).eq.0).and.(lon(dimsizes(lon)-1).ne.360)) then
						; Need to remove seam at prime meridian
						lon(0:dimsizes(lon)-2) = lon(1:dimsizes(lon)-1)
						lon(dimsizes(lon)-1) = 360.

						ps2 = (/ps/)
						ps2(:,0:dimsizes(lon)-2) = ps(:,1:dimsizes(lon)-1)
						ps2(:,dimsizes(lon)-1) = ps(:,0)
						ps = (/ps2/)
						delete(ps2)
					end if
					ps&lon = lon
				end if

				; Plot:
				if (output_format.eq."ps") then
					wks = gsn_open_wks(output_format,plotnames)
				end if

				gsn_define_colormap(wks,color_map)
				plot(physloop*3+fk) = gsn_csm_contour_map_ce(wks,ps,res)
				
				gsn_merge_colormaps(wks, color_map, color_map2)

				if (add_fine_region) then
					dum(physloop,fk,0) = gsn_add_polyline(wks, plot(physloop*3+fk), -(/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,fk,1) = gsn_add_polyline(wks, plot(physloop*3+fk),  (/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,fk,2) = gsn_add_polyline(wks, plot(physloop*3+fk),  (/-30., 30./), -(/ 25., 25./), res_p)
					dum(physloop,fk,3) = gsn_add_polyline(wks, plot(physloop*3+fk),  (/-30., 30./),  (/ 25., 25./), res_p)
				end if

				if (add_coarse_region) then
					dum(physloop,fk,4) = gsn_add_polyline(wks, plot(physloop*3+fk), -(/60., 60./), (/-90., 90./), res_p)
					dum(physloop,fk,5) = gsn_add_polyline(wks, plot(physloop*3+fk), (/60., 60./), (/-90., 90./), res_p)
				end if

				if (add_fine_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,fk,6) = gsn_add_polyline(wks, plot(physloop*3+fk), -(/lambda, lambda/), (/-theta, theta/), res_p)
					dum(physloop,fk,7) = gsn_add_polyline(wks, plot(physloop*3+fk),  (/lambda, lambda/), (/-theta, theta/), res_p)
					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,fk,10+j) = gsn_add_polyline(wks, plot(physloop*3+fk), (/lamb(j), lamb(j+1)/), -(/thet(j), thet(j+1)/), res_p)
						dum(physloop,fk,10+num_int+j) = gsn_add_polyline(wks, plot(physloop*3+fk), (/lamb(j), lamb(j+1)/),  (/thet(j), thet(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if

				if (add_coarse_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,fk,8) = gsn_add_polyline(wks, plot(physloop*3+fk), -(/lambda2, lambda2/), (/-theta2, theta2/), res_p)
					dum(physloop,fk,9) = gsn_add_polyline(wks, plot(physloop*3+fk),  (/lambda2, lambda2/), (/-theta2, theta2/), res_p)

					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,fk,10+(2*num_int)+j) = gsn_add_polyline(wks, plot(physloop*3+fk), (/lamb2(j), lamb2(j+1)/), -(/thet2(j), thet2(j+1)/), res_p)
						dum(physloop,fk,10+(3*num_int)+j) = gsn_add_polyline(wks, plot(physloop*3+fk), (/lamb2(j), lamb2(j+1)/),  (/thet2(j), thet2(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if
				;frame(wks)

				if (output_format.eq."ps") then
					delete(wks)
				end if
				delete(ps)
				if (run_names(fk).eq."quadrant_15_x8") then
					delete(lon)
				end if
			end if
		end do
	end do
	
	

end if ; if diff = false






	

if (diff) then

		res                     = True
		res@gsnMaximize         = True         ; Maximize size of plot in frame
    res@gsnDraw = False
    res@gsnFrame = False
		res@gsnPaperOrientation = "portrait"
		res@gsnSpreadColors     = True         ; Use full colormap, but start
		res@cnFillOn            = True         ; Turn on contour fill
		res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
		res@cnLinesOn           = False        ; Turn off contour lines
		res@cnLineLabelsOn      = False        ; Turn off contour line labels
		res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
		res@lbBoxLinesOn        = False        ; Turn of labelbar box lines.
		res@mpOutlineOn          = False
		res@mpFillOn             = False
		res@gsnFrame = False
		res@gsnDraw = False
		res@gsnAddCyclic = True
		

    res@cnInfoLabelOn       = False
    res@lbLabelBarOn        = False           ; turn off individual cb's

		res@gsnStringFont = 21
		res@lbLabelFont = 21
		res@lgLabelFont = 21
		res@tmYLLabelFont = 21    ;  21 = helvetica
		res@tmXBLabelFont = 21    ;  22 = helvetica-bold 
		res@tmXTLabelFont = 21    ;  22 = helvetica-bold 

	  res@gsnLeftString = ""
    res@gsnRightString = ""

		res@cnLevelSelectionMode = "ManualLevels"
    
    
    
    
    
    

		res@cnExplicitLabelBarLabelsOn = True
		res@lbLabelAlignment = "BoxCenters"
		res@lbLabelAutoStride = False
		res@lbLabelStride = 2

		f_mr     = fall[1]
		f_coarse = fall[0]
		f_fine   = fall[2]

		; Difference between variable resolution and high resolution
		;if ((dimsizes(f_mr&lat).eq.dimsizes(f_fine&lat)).and.(dimsizes(f_mr&lon).eq.dimsizes(f_fine&lon))) then
		;	nlat = dimsizes(f_mr&lat)
		;	nlon = dimsizes(f_mr&lon)
		;else
		;	print("Can not plot difference between variable res and high res unless they are interpolated to same grid")
		;	exit
		;end if

		res@tiMainString = "Difference between " + run_names(1) + " and " + run_names(2)
		if (add_box) then
			add_fine_region = False
			add_coarse_region = False
			add_fine_mesh = True
			add_coarse_mesh = True
		end if

		do m=0,dimsizes(var_names)-1
			print("Plotting difference for "+var_names(m))
			make_plot = False
			if (output_format.eq."ps") then
				output_vars = "diff-"+var_names(m)
				plotnames = "h0latlon-"+output_vars
				plotnames = "./"+output_format+"/"+plotnames
			end if

			if (var_names(m).eq."PRECL" ) then
			  ps_se = f_mr->PRECL(0,:)
				ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
				delete(ps_se)
				ps_se = f_fine->PRECL(0,:)
				ps_fine = ESMF_regrid_with_weights(ps_se,wnames(1),False)
				delete(ps_se)
				lon = ps&lon
				lat = ps&lat	
				ps = ps_mr - ps_fine
				delete(ps_mr)
				delete(ps_fine)
				
				;copyatt( ps, f_mr->PRECL(0,:,:))
				; convert to mm/day
				ps=ps*1000*24*3600
				ps@units="mm/day"
				print((/min(ps),max(ps)/))
				
				res@cnMinLevelValF = -18.75
				res@cnMaxLevelValF = 18.75
				res@cnLevelSpacingF = 2.5

				res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

				make_plot = True
			end if

            if (var_names(m).eq."PRECT" ) then
                 if (if_regrid .eq. True)
                    ps_se = f_mr->PRECT(0,:)
                    ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
                    delete(ps_se)
                    ps_se = f_fine->PRECT(0,:)
                    ps_fine = ESMF_regrid_with_weights(ps_se,wnames(1),False)
                    delete(ps_se)
                    lon = ps_fine&lon
                    lat = ps_fine&lat	
                    ps = ps_mr - ps_fine
                    copy_VarMeta(ps_fine,ps)
                    delete(ps_mr)
                    delete(ps_fine)
                 else
                    ps = f_mr->PRECT(0,:,:) - f_fine->PRECT(0,:,:)
                    copyatt( ps, f_mr->PRECT(0,:,:))                 
                 end if
                    ; convert to mm/day
                    ps=ps*1000*24*3600
                    ps@units="mm/day"
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -12.
                    res@cnMaxLevelValF = 12.
                    res@cnLevelSpacingF = 2.

                    res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if
            
            if (var_names(m).eq."PRECC" ) then
                    ps = f_mr->PRECC(0,:,:) - f_fine->PRECC(0,:,:)
                    copyatt( ps, f_mr->PRECC(0,:,:))
                    ; convert to mm/day
                    ps=ps*1000*24*3600
                    ps@units="mm/day"
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -18.75
                    res@cnMaxLevelValF = 18.75
                    res@cnLevelSpacingF = 2.5

                    res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if

            if (var_names(m).eq."TMQ" ) then
                    ps = f_mr->TMQ(0,:,:) - f_fine->TMQ(0,:,:)
                    copyatt( ps, f_mr->TMQ(0,:,:))
                    ; convert to mm/day
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -11.0
                    res@cnMaxLevelValF = 11.0
                    res@cnLevelSpacingF = 2.0

                    ;res@lbLabelStrings = (/"-30", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if


			if (var_names(m).eq."CLDTOT") then
			           if (if_regrid .eq. True)
                    ps_se = f_mr->CLDTOT(0,:)
                    ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
                    delete(ps_se)
                    ps_se = f_fine->CLDTOT(0,:)
                    ps_fine = ESMF_regrid_with_weights(ps_se,wnames(1),False)
                    delete(ps_se)
                    lon = ps_fine&lon
                    lat = ps_fine&lat	
                    ps = ps_mr - ps_fine
                    copy_VarMeta(ps_fine,ps)
                    delete(ps_mr)
                    delete(ps_fine)
                 else
                    ps = f_mr->CLDTOT(0,:,:) - f_fine->CLDTOT(0,:,:)
                    copyatt( ps, f_mr->CLDTOT(0,:,:))                 
                 end if
				print((/min(ps),max(ps)/))

				res@cnMinLevelValF = -0.4
				res@cnMaxLevelValF = 0.4
				res@cnLevelSpacingF = .05

				delete(res@lbLabelStrings)
				res@lbLabelStrings = (/"-0.4", "skip", "-0.3", "skip", "-0.2", "skip", "-0.1", "skip", "0", "skip", "0.1", "skip", "0.2", "skip", "0.3", "skip", "0.4"/)

				make_plot = True
			end if

			; PLOT DIFFERENCE
			if (make_plot) then
				if (output_format.eq."ps") then
					wks = gsn_open_wks(output_format,plotnames)
				end if

				gsn_define_colormap(wks,color_map)
				plot(physloop*2+1) = gsn_csm_contour_map_ce(wks,ps,res)
				gsn_merge_colormaps(wks, color_map, color_map2)
;				gsn_define_colormap(wks, (/ (/0.5, 0.5, 0.5/), (/0., 0., 0./) /) )

				if (add_fine_region) then
					dum(physloop,0,0) = gsn_add_polyline(wks, plot(physloop*2+1), -(/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,0,1) = gsn_add_polyline(wks, plot(physloop*2+1),  (/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,0,2) = gsn_add_polyline(wks, plot(physloop*2+1),  (/-30., 30./), -(/ 25., 25./), res_p)
					dum(physloop,0,3) = gsn_add_polyline(wks, plot(physloop*2+1),  (/-30., 30./),  (/ 25., 25./), res_p)
				end if

				if (add_coarse_region) then
					dum(physloop,0,4) = gsn_add_polyline(wks, plot(physloop*2+1), -(/60., 60./), (/-90., 90./), res_p)
					dum(physloop,0,5) = gsn_add_polyline(wks, plot(physloop*2+1), (/60., 60./), (/-90., 90./), res_p)
				end if

				if (add_fine_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,0,6) = gsn_add_polyline(wks, plot(physloop*2+1), -(/lambda, lambda/), (/-theta, theta/), res_p)
					dum(physloop,0,7) = gsn_add_polyline(wks, plot(physloop*2+1),  (/lambda, lambda/), (/-theta, theta/), res_p)
					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,0,10+j) = gsn_add_polyline(wks, plot(physloop*2+1), (/lamb(j), lamb(j+1)/), -(/thet(j), thet(j+1)/), res_p)
						dum(physloop,0,10+num_int+j) = gsn_add_polyline(wks, plot(physloop*2+1), (/lamb(j), lamb(j+1)/),  (/thet(j), thet(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if

				if (add_coarse_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,0,8) = gsn_add_polyline(wks, plot(physloop*2+1), -(/lambda2, lambda2/), (/-theta2, theta2/), res_p)
					dum(physloop,0,9) = gsn_add_polyline(wks, plot(physloop*2+1),  (/lambda2, lambda2/), (/-theta2, theta2/), res_p)

					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,0,10+(2*num_int)+j) = gsn_add_polyline(wks, plot(physloop*2+1), (/lamb2(j), lamb2(j+1)/), -(/thet2(j), thet2(j+1)/), res_p)
						dum(physloop,0,10+(3*num_int)+j) = gsn_add_polyline(wks, plot(physloop*2+1), (/lamb2(j), lamb2(j+1)/),  (/thet2(j), thet2(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if
				;frame(wks)

				if (output_format.eq."ps") then
					delete(wks)
				end if
				delete(ps)
			end if
		end do

		; Difference between variable resolution and low resolution
		;if ((dimsizes(f_mr&lat).eq.dimsizes(f_coarse&lat)).and.(dimsizes(f_mr&lon).eq.dimsizes(f_coarse&lon))) then
	;		nlat = dimsizes(f_mr&lat)
		;	nlon = dimsizes(f_mr&lon)
		;else
	;		print("Can not plot difference between variable res and low res unless they are interpolated to same grid")
		;	exit
		;end if

		res@tiMainString = "Difference between " + run_names(1) + " and " + run_names(0)
		if (add_box) then
			add_fine_region = False
			add_coarse_region = False
			add_fine_mesh = True
			add_coarse_mesh = True
		end if

		do m=0,dimsizes(var_names)-1
			print("Plotting difference for "+var_names(m))
			make_plot = False
			if (output_format.eq."ps") then
				output_vars = "diff2-"+var_names(m)
				plotnames = "h0latlon-"+output_vars
				plotnames = "./"+output_format+"/"+plotnames
			end if
				
			if (var_names(m).eq."PRECL" ) then
			           if (if_regrid .eq. True)
                    ps_se = f_mr->PRECL(0,:)
                    ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
                    delete(ps_se)
                    ps_se = f_coarse->PRECL(0,:)
                    ps_coarse = ESMF_regrid_with_weights(ps_se,wnames(2),False)
                    delete(ps_se)
                    lon = ps_coarse&lon
                    lat = ps_coarse&lat	
                    ps = ps_mr - ps_coarse
                    copy_VarMeta(ps_coarse,ps)
                    delete(ps_mr)
                    delete(ps_coarse)
                 else
                    ps = f_mr->PRECL(0,:,:) - f_coarse->PRECL(0,:,:)
                    copyatt( ps, f_mr->PRECL(0,:,:))                 
                 end if
				; convert to mm/day
				ps=ps*1000*24*3600
				ps@units="mm/day"
				print((/min(ps),max(ps)/))
				
				res@cnMinLevelValF = -18.75
				res@cnMaxLevelValF = 18.75
				res@cnLevelSpacingF = 2.5

				delete(res@lbLabelStrings)
				res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

				make_plot = True
			end if

            if (var_names(m).eq."PRECT" ) then
			           if (if_regrid .eq. True)
                    ps_se = f_mr->PRECT(0,:)
                    ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
                    delete(ps_se)
                    ps_se = f_coarse->PRECT(0,:)
                    ps_coarse = ESMF_regrid_with_weights(ps_se,wnames(2),False)
                    delete(ps_se)
                    lon = ps_coarse&lon
                    lat = ps_coarse&lat	
                    ps = ps_mr - ps_coarse
                    copy_VarMeta(ps_coarse,ps)
                    delete(ps_mr)
                    delete(ps_coarse)
                 else
                    ps = f_mr->PRECT(0,:,:) - f_coarse->PRECT(0,:,:)
                    copyatt( ps, f_mr->PRECT(0,:,:))                 
                 end if
                    ; convert to mm/day
                    ps=ps*1000*24*3600
                    ps@units="mm/day"
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -12.
                    res@cnMaxLevelValF = 12.
                    res@cnLevelSpacingF = 2.

                    delete(res@lbLabelStrings)
                    res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if
            
            if (var_names(m).eq."PRECC" ) then
                    ps = f_mr->PRECC(0,:,:) - f_coarse->PRECC(0,:,:)
                    copyatt( ps, f_mr->PRECC(0,:,:))
                    ; convert to mm/day
                    ps=ps*1000*24*3600
                    ps@units="mm/day"
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -18.75
                    res@cnMaxLevelValF = 18.75
                    res@cnLevelSpacingF = 2.5

                    delete(res@lbLabelStrings)
                    res@lbLabelStrings = (/"-20", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if



			if (var_names(m).eq."CLDTOT") then
			           if (if_regrid .eq. True)
                    ps_se = f_mr->CLDTOT(0,:)
                    ps_mr = ESMF_regrid_with_weights(ps_se,wnames(0),False)
                    delete(ps_se)
                    ps_se = f_coarse->CLDTOT(0,:)
                    ps_coarse = ESMF_regrid_with_weights(ps_se,wnames(2),False)
                    delete(ps_se)
                    lon = ps_coarse&lon
                    lat = ps_coarse&lat	
                    ps = ps_mr - ps_coarse
                    copy_VarMeta(ps_coarse,ps)
                    delete(ps_mr)
                    delete(ps_coarse)
                 else
                    ps = f_mr->CLDTOT(0,:,:) - f_coarse->CLDTOT(0,:,:)
                    copyatt( ps, f_mr->CLDTOT(0,:,:))                 
                 end if
				print((/min(ps),max(ps)/))

				res@cnMinLevelValF = -0.4
				res@cnMaxLevelValF = 0.4
				res@cnLevelSpacingF = .05

				delete(res@lbLabelStrings)
				res@lbLabelStrings = (/"-0.4", "skip", "-0.3", "skip", "-0.2", "skip", "-0.1", "skip", "0", "skip", "0.1", "skip", "0.2", "skip", "0.3", "skip", "0.4"/)

				make_plot = True
			end if
			
            if (var_names(m).eq."TMQ" ) then
                    ps = f_mr->TMQ(0,:,:) - f_coarse->TMQ(0,:,:)
                    copyatt( ps, f_mr->TMQ(0,:,:))
                    ; convert to mm/day
                    print((/min(ps),max(ps)/))

                    res@cnMinLevelValF = -11.0
                    res@cnMaxLevelValF = 11.0
                    res@cnLevelSpacingF = 2.0

                    ;res@lbLabelStrings = (/"-30", "skip", "-15", "skip", "-10", "skip", "-5", "skip", "0", "skip", "5", "skip", "10", "skip", "15", "skip", "20"/)

                    make_plot = True
            end if

			; PLOT DIFFERENCE
			if (make_plot) then
				if (output_format.eq."ps") then
					wks = gsn_open_wks(output_format,plotnames)
				end if

				gsn_define_colormap(wks,color_map)
				plot(physloop*2+0) = gsn_csm_contour_map_ce(wks,ps,res)
				gsn_merge_colormaps(wks, color_map, color_map2)
;				gsn_define_colormap(wks, (/ (/0.5, 0.5, 0.5/), (/0., 0., 0./) /) )

				if (add_fine_region) then
					dum(physloop,1,0) = gsn_add_polyline(wks, plot(physloop*2+0), -(/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,1,1) = gsn_add_polyline(wks, plot(physloop*2+0),  (/ 30., 30./),  (/-25., 25./), res_p)
					dum(physloop,1,2) = gsn_add_polyline(wks, plot(physloop*2+0),  (/-30., 30./), -(/ 25., 25./), res_p)
					dum(physloop,1,3) = gsn_add_polyline(wks, plot(physloop*2+0),  (/-30., 30./),  (/ 25., 25./), res_p)
				end if

				if (add_coarse_region) then
					dum(physloop,1,4) = gsn_add_polyline(wks, plot(physloop*2+0), -(/60., 60./), (/-90., 90./), res_p)
					dum(physloop,1,5) = gsn_add_polyline(wks, plot(physloop*2+0), (/60., 60./), (/-90., 90./), res_p)
				end if

				if (add_fine_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,1,6) = gsn_add_polyline(wks, plot(physloop*2+0), -(/lambda, lambda/), (/-theta, theta/), res_p)
					dum(physloop,1,7) = gsn_add_polyline(wks, plot(physloop*2+0),  (/lambda, lambda/), (/-theta, theta/), res_p)
					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,1,10+j) = gsn_add_polyline(wks, plot(physloop*2+0), (/lamb(j), lamb(j+1)/), -(/thet(j), thet(j+1)/), res_p)
						dum(physloop,1,10+num_int+j) = gsn_add_polyline(wks, plot(physloop*2+0), (/lamb(j), lamb(j+1)/),  (/thet(j), thet(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if

				if (add_coarse_mesh) then
;					res_p@gsLineThicknessF = 1.0
					res_p@gsLineColor = mesh_color
					; Vertical Lines are easy
					dum(physloop,1,8) = gsn_add_polyline(wks, plot(physloop*2+0), -(/lambda2, lambda2/), (/-theta2, theta2/), res_p)
					dum(physloop,1,9) = gsn_add_polyline(wks, plot(physloop*2+0),  (/lambda2, lambda2/), (/-theta2, theta2/), res_p)

					; Great-Circle arcs aren't
					do j=0,num_int-1
						dum(physloop,1,10+(2*num_int)+j) = gsn_add_polyline(wks, plot(physloop*2+0), (/lamb2(j), lamb2(j+1)/), -(/thet2(j), thet2(j+1)/), res_p)
						dum(physloop,1,10+(3*num_int)+j) = gsn_add_polyline(wks, plot(physloop*2+0), (/lamb2(j), lamb2(j+1)/),  (/thet2(j), thet2(j+1)/), res_p)
					end do
					res_p@gsLineThicknessF = 3.0
					res_p@gsLineColor = region_color
				end if
				;frame(wks)

				if (output_format.eq."ps") then
					delete(wks)
				end if
				delete(ps)
			end if
		end do
	end if
	
end do
	
;************************************************
; create panel
;************************************************


  resP                  = True                   ; modify the panel plot
  resP@gsnPanelLabelBar = True                   ; add common colorbar
  resP@amJust           = "BottomRight"

; Since there are two panels in the diff plots and three in the straight up
; plots, it appears things have to be scaled by a 2/3 ratio to show up OK
; in the plots when put into LaTeX template. There's probably a better fix
; for this, but this works for now.
if (diff .eq. False) then
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  resP@lbLabelFontHeightF = 0.013333
  resP@gsnPanelFigureStrings= (/"a.","b.","c."/)
  gsn_panel(wks,plot,(/3,numphystypes/),resP)               ; now draw as one plot
else
  resP@gsnPanelFigureStringsFontHeightF = 0.03
  resP@lbLabelFontHeightF = 0.02
  resP@gsnPanelFigureStrings= (/"d.","e."/)
  gsn_panel(wks,plot,(/2,numphystypes/),resP)               ; now draw as one plot
end if

delete(resP)

end do
end do
end do
  
end

