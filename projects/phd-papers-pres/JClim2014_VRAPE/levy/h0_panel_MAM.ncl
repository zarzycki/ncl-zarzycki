; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin


  phys_type = "MAM"
  
  wks = gsn_open_wks("pdf","h0_line_panel_MAM_comp")  
  plot = new(4,graphic)
  ;plotname = "h0_"+var_names+"_"+phys_type
	gsn_define_colormap(wks,"BlWhRe")

	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/CAM5_MAM/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
		)

	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)
	print(fnames)
	add_leg = True

	run_names = (/"CAM5_BAM", "CAM5_MAM"/)

	lthick=4
	thick=4
	
	do jj = 0,1
  
  if (jj .eq. 0)
    var_names = "CLDTOT"
  else
    var_names = "PRECT"
  end if  
	
  do ii = 0,1
  
  if (ii .eq. 0)
    doFull = True
    doZoom = False
  else
    doFull = False
    doZoom = True
  end if

  if (doFull) then

	color_list = (/"red", "blue"/)
	ncolors = dimsizes(color_list)
	if ((fcnt.ne.ncolors).and.(fcnt.gt.1).and.(ncolors.gt.1)) then
		print((/"Error, number of colors doesn't match number of files read!"/))
		exit
	end if
	print(color_list(0:fcnt-1)+": "+fnames)

	if (add_leg) then
		leg_labels = (/"BAM", "MAM"/)
		nlabels = dimsizes(leg_labels)
		if (nlabels.ne.fcnt) then
			print((/"Error, number of legend labels doesn't match number of files read!"/))
			exit
		end if
	end if

	; Make sure dimensions are the same in all files!
	nlat = dimsizes(fall[0]&lat)
	nlon = dimsizes(fall[0]&lon)
	if (fcnt.gt.1) then
		do fk=1, fcnt-1
			if ((dimsizes(fall[fk]&lat).ne.nlat).or.(dimsizes(fall[fk]&lon).ne.nlon)) then
				print((/"Error in dim sizes:"/))
				print((/fnames(0)+" is "+nlon+" x "+nlat/))
				print((/fnames(fk)+" is "+dimsizes(fall[fk]&lat)+" x "+dimsizes(fall[fk]&lon)/))
				print((/"All files must be interpolated to same grid!"/))
				exit
			end if
		end do
	end if
	print ("nlat x nlon: "+nlat+" x "+nlon)

	; General plot properties
	resxy = True
	resxy@gsnFrame = False
	resxy@gsnDraw = False
	resxy@xyMonoDashPattern = True
	resxy@xyLineColors      = color_list
		
	resxy@tmXMajorGridThicknessF = 6.0
	resxy@tmYLLabelFont = 21    ;  21 = helvetica
	resxy@tmXBLabelFont = 21    ;  22 = helvetica-bold

	resxy@tmXBMajorThicknessF = thick
	resxy@tmYLMajorThicknessF = thick
	resxy@tmXBMinorThicknessF = thick 
	resxy@tmYLMinorThicknessF = thick 
	resxy@tmBorderThicknessF = thick
	resxy@tiXAxisString          = ":F21:latitude"
	resxy@xyLineThicknessF = lthick

	if (add_leg) then
		resxy@lgAutoManage = False
		resxy@pmLegendDisplayMode = "Always"
		resxy@lgPerimOn = True
		resxy@pmLegendSide = "Top"
		if (phys_type .eq. "CAM4") then
		  resxy@pmLegendOrthogonalPosF = -.33
		else
		  if (var_names.eq."PRECT") then
		    resxy@pmLegendOrthogonalPosF = -.33
		    resxy@pmLegendParallelPosF = .75
		  end if
		  if (var_names.eq."CLDTOT") then
		    resxy@pmLegendOrthogonalPosF = -1.02
		    resxy@pmLegendParallelPosF = .7
		  end if
		end if
		resxy@pmLegendWidthF = 0.1
		resxy@pmLegendHeightF = 0.1
		resxy@lgLabelFontHeightF = 0.016
		resxy@xyExplicitLegendLabels = leg_labels
	end if

	do m=0, dimsizes(var_names)-1
		cur_var = var_names(m)
		make_plot = False

		if(cur_var.eq."PRECT") then
			;
			;  zonal average plot PRECT
			;
			make_plot = True
			resxy@tiMainString        = ":F21:TOTAL PRECIPITATION"
			resxy@tiYAxisString          = ":F21:mm/day"
			resxy@trYMinF = 0.
			resxy@trYMaxF = 32.
			avg_hemi = False
		end if

		if(cur_var.eq."PRECL") then
			;
			;  zonal average plot PRECL
			;
			make_plot = True
			resxy@tiMainString        = ":F21:LARGE-SCALE PRECIPITATION"
			resxy@tiYAxisString          = ":F21:mm/day"
			resxy@trYMinF = 0.
			resxy@trYMaxF = 22.
			avg_hemi = False
		end if

		if(cur_var.eq."CLDTOT") then
			;
			;  zonal average plot CLOUD TOT
			;
			make_plot = True
			resxy@tiMainString        = ":F21:CLOUD FRACTION"
			resxy@tiYAxisString          = ":F21:fraction"
			resxy@trYMinF = 0.2
			resxy@trYMaxF = 1.
			; avg_hemi = False
			avg_hemi = True
		end if

		if (make_plot) then
			print(resxy@tiMainString)
			pll = new((/fcnt,nlat/),double)
			do k=0,fcnt-1
				f = fall[k]
				varll = dim_avg(f->$cur_var$(0,:,:))

				if (avg_hemi) then
					resxy@trXMinF = -90.
					resxy@trXMaxF = 0.
					if (phys_type .eq. "CAM4") then
					  resxy@pmLegendParallelPosF = 0.5
					end if
					pll(k,0:nlat-1) = (varll(0:nlat-1) + varll(nlat-1:0))/2.
				else
					resxy@trXMinF = -90.
					resxy@trXMaxF = 90.
					if (phys_type .eq. "CAM4") then
					  resxy@pmLegendParallelPosF = 0.75
					end if
					pll(k,0:nlat-1) = varll(0:nlat-1)
				end if
				delete(varll)
				delete(f)
			end do

			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT")) then
				pll = pll*1000.*86400. ; convert to mm/day!
			end if
			print(max(pll))


			plot(ii+(2*jj))=gsn_xy(wks,fall[0]&lat,pll(:,:),resxy) ; create plot

			delete(pll)
		end if
	end do
	
	
	end if


  ; ======================================================== ZOOM CODE
  
  if (doZoom) then

	style_list = (/2, 0, 2, 0/)
	color_list = (/"red", "red", "blue", "blue"/)
	ncolors = dimsizes(color_list)
	print(color_list(0)+": "+fnames(0)+" (fine region)")
	print(color_list(1)+": "+fnames(0)+" (coarse region)")
	print(color_list(2:fcnt)+": "+fnames(1:fcnt-1))

	if (add_leg) then
		leg_labels = (/"BAM (fine region)", "BAM (coarse region)", \
		               "MAM (fine region)", "MAM (coarse region)"/)
	end if


	; Make sure dimensions are the same in all files!
	nlat = dimsizes(fall[0]&lat)
	nlon = dimsizes(fall[0]&lon)
	if (fcnt.gt.1) then
		do fk=1, fcnt-1
			if ((dimsizes(fall[fk]&lat).ne.nlat).or.(dimsizes(fall[fk]&lon).ne.nlon)) then
				print((/"Error in dim sizes:"/))
				print((/fnames(0)+" is "+nlon+" x "+nlat/))
				print((/fnames(fk)+" is "+dimsizes(fall[fk]&lat)+" x "+dimsizes(fall[fk]&lon)/))
				print((/"All files must be interpolated to same grid!"/))
				exit
			end if
		end do
	end if
	print ("nlat x nlon: "+nlat+" x "+nlon)


	; General plot properties
	resxy = True
		resxy@gsnFrame = False
	resxy@gsnDraw = False
	resxy@xyMonoDashPattern = False
	resxy@xyLineColors      = color_list
	resxy@xyDashPatterns    = style_list
		
	resxy@tmXMajorGridThicknessF = 6.0
	resxy@tmYLLabelFont = 21    ;  21 = helvetica
	resxy@tmXBLabelFont = 21    ;  22 = helvetica-bold

	resxy@tmXBMajorThicknessF = thick
	resxy@tmYLMajorThicknessF = thick
	resxy@tmXBMinorThicknessF = thick 
	resxy@tmYLMinorThicknessF = thick 
	resxy@tmBorderThicknessF = thick
	resxy@tiXAxisString          = ":F21:latitude"
	resxy@xyLineThicknessF = lthick

	if (add_leg) then
		resxy@lgAutoManage = False
		resxy@pmLegendDisplayMode = "Always"
		resxy@lgPerimOn = True
		resxy@pmLegendSide = "Top"
		; resxy@pmLegendOrthogonalPosF = -1.05
		if (phys_type .eq. "CAM4") then
		  resxy@pmLegendOrthogonalPosF = -.35
		else
		  if (var_names.eq."PRECT") then
		    resxy@pmLegendOrthogonalPosF = -.33
		    resxy@pmLegendParallelPosF = .75
		  end if
		  if (var_names.eq."CLDTOT") then
		    resxy@pmLegendOrthogonalPosF = -1.02
		    resxy@pmLegendParallelPosF = .7
		  end if
		end if
		resxy@pmLegendWidthF = 0.1
		resxy@pmLegendHeightF = 0.12
		resxy@lgLabelFontHeightF = 0.016
		resxy@xyExplicitLegendLabels = leg_labels
	end if

	do m=0, dimsizes(var_names)-1
		cur_var = var_names(m)
		make_plot = False

		if(cur_var.eq."PRECT") then
			;
			;  zonal average plot PRECT
			;
			make_plot = True
			resxy@tiMainString        = ":F21:TOTAL PRECIPITATION"
			resxy@tiYAxisString          = ":F21:mm/day"
			resxy@trYMinF = 0.
			resxy@trYMaxF = 32.
			avg_hemi = False
		end if

		if(cur_var.eq."PRECL") then
			;
			;  zonal average plot PRECL
			;
			make_plot = True
			resxy@tiMainString        = ":F21:LARGE-SCALE PRECIPITATION"
			resxy@tiYAxisString          = ":F21:mm/day"
			resxy@trYMinF = 0.
			resxy@trYMaxF = 22.
			avg_hemi = False
		end if

		if(cur_var.eq."CLDTOT") then
			;
			;  zonal average plot CLOUD TOT
			;
			make_plot = True
			resxy@tiMainString        = ":F21:CLOUD FRACTION"
			resxy@tiYAxisString          = ":F21:fraction"
			resxy@trYMinF = 0.2
			resxy@trYMaxF = 1.
			avg_hemi = False
		end if
		
		resxy@tiYAxisString          = ""

nlat = 720

		if (make_plot) then
			print(resxy@tiMainString)
			pll = new((/4,nlat/),double)
			do k=0,3
		    
		    if (k.le.1) then
		      f = fall[0]
		    else
		      f = fall[1]
		    end if
				
				if (k.eq.0 .or. k.eq.2) then

					  varll = (dim_avg(f->$cur_var$(0,:,{0:30})) + dim_avg(f->$cur_var$(0,:,{330:360})))/2.

				end if

				if (k.eq.1 .or. k.eq.3) then
					varll = dim_avg(f->$cur_var$(0,:,{60:300}))
					; varll = dim_avg(f->$cur_var$(0,:,{45:315}))
					; varll = dim_avg(f->$cur_var$(0,:,{75:315}))
				end if
				
				;if (k.ge.2) then
				;	varll = dim_avg(f->$cur_var$(0,:,:))
				;end if

				if (avg_hemi) then
					resxy@trXMinF = -25.
					resxy@trXMaxF = 0.
					if (phys_type .eq. "CAM4") then
					  resxy@pmLegendParallelPosF = 0.5
					end if
					pll(k,0:nlat-1) = (varll(0:nlat-1) + varll(nlat-1:0))/2.
				else
					resxy@trXMinF = -25.
					resxy@trXMaxF = 25.
					if (phys_type .eq. "CAM4") then
					  resxy@pmLegendParallelPosF = 0.75
					end if
					pll(k,0:nlat-1) = varll(0:nlat-1)
				end if
				delete(varll)
				delete(f)
			end do

			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT")) then
				pll = pll*1000.*86400. ; convert to mm/day!
			end if
			print(max(pll))


			plot(ii+(jj*2))=gsn_xy(wks,fall[0]&lat,pll(:,:),resxy) ; create plot

			delete(pll)
		end if
	end do
	
	
	end if
	
		delete(color_list)
	delete(ncolors)
	delete(leg_labels)
	delete(resxy)
	
	end do
	end do
	
 resP                  = True                   ; modify the panel plot
 resP@amJust           = "TopLeft"
 resP@gsnPanelFigureStringsFontHeightF = 0.02
 resP@gsnPanelFigureStrings= (/"a.","b.","c.","d."/)
 
	
	gsn_panel(wks,plot,(/2,2/),resP)             ; now draw as one plot

end

