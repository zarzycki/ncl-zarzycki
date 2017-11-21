; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

 if_regrid = False
 
 phys_type = "CAM5"
 var_names = (/"PRECT"/)
 
	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/uniform_120/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/uniform_15/h0avg_regrid_0.25x0.25.nc ; "\   
		)
		
wnames = (/"/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc",\
 "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc",\
 "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"/)

	output_format = "pdf"
;	output_format = "pdf"
;	output_format = "ps"
;	output_format = "ncgm"

;	run_names = (/"quad_15_x4", "uniform_15", "uniform_60"/)
	run_names = (/"quadrant_15_x8", "uniform_15", "uniform_120"/)
;	var_names = (/"PRECT", "PRECL", "PRECC", "PS","CLDTOT","OMEGA","OMEGA300","EKE100"/)
;	var_names = (/"PRECL", "CLDTOT", "PRECT"/)
;	var_names = (/"PRECT", "CLDTOT"/)
	add_leg = True

	if (output_format.ne."ps") then
		plotname = "h0zoom_"+var_names+"_"+phys_type
		wks = gsn_open_wks(output_format,plotname)
		gsn_define_colormap(wks,"BlWhRe")
	end if

	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)
	print(fnames)

	lthick=4
	thick=4
	style_list = (/2, 2, 0, 0/)
	color_list = (/"red", "blue", "red", "blue"/)
	ncolors = dimsizes(color_list)
	print(color_list(0)+": "+fnames(0)+" (fine region)")
	print(color_list(1)+": "+fnames(0)+" (coarse region)")
	print(color_list(2:fcnt)+": "+fnames(1:fcnt-1))

	if (add_leg) then
		leg_labels = (/"x8 (fine region)", "x8 (coarse region)", \
		               "0.25:S:o:N:", "2:S:o:N:"/)
	end if

if (if_regrid .ne. True)
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
end if

	; General plot properties
	resxy = True
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
		resxy@pmLegendOrthogonalPosF = -.35
		resxy@pmLegendWidthF = 0.1
		resxy@pmLegendHeightF = 0.12
		resxy@lgLabelFontHeightF = 0.012
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

nlat = 720

		if (make_plot) then
			print(resxy@tiMainString)
			pll = new((/fcnt+1,nlat/),double)
			do k=0,3
		    print((/0,k-1/))
				f = fall[max((/0,k-1/))]
				if (k.eq.0) then
				  if (if_regrid .eq. True)

                    ps_se = f->$cur_var$
                    ps = ESMF_regrid_with_weights(ps_se,wnames(0),False)
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
                    
            varll = (dim_avg(f->$cur_var$(0,:,{0:30})) + dim_avg(f->$cur_var$(0,:,{330:360})))/2.        
				  else
					  varll = (dim_avg(f->$cur_var$(0,:,{0:30})) + dim_avg(f->$cur_var$(0,:,{330:360})))/2.
					end if
				end if

				if (k.eq.1) then
					varll = dim_avg(f->$cur_var$(0,:,{60:300}))
					; varll = dim_avg(f->$cur_var$(0,:,{45:315}))
					; varll = dim_avg(f->$cur_var$(0,:,{75:315}))
				end if
				
				if (k.ge.2) then
					varll = dim_avg(f->$cur_var$(0,:,:))
				end if

				if (avg_hemi) then
					resxy@trXMinF = -25.
					resxy@trXMaxF = 0.
					resxy@pmLegendParallelPosF = 0.5
					pll(k,0:nlat-1) = (varll(0:nlat-1) + varll(nlat-1:0))/2.
				else
					resxy@trXMinF = -25.
					resxy@trXMaxF = 25.
					resxy@pmLegendParallelPosF = 0.75
					pll(k,0:nlat-1) = varll(0:nlat-1)
				end if
				delete(varll)
				delete(f)
			end do

			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT")) then
				pll = pll*1000.*86400. ; convert to mm/day!
			end if
			print(max(pll))

			if (output_format.eq."ps") then
				plotname = "h0zoom"
				plotname = "./"+output_format+"/"+plotname+"-"+cur_var
				wks = gsn_open_wks(output_format, plotname)
				gsn_define_colormap(wks,"BlWhRe")
			end if
			plot=gsn_xy(wks,fall[0]&lat,pll(:,:),resxy) ; create plot
			if (output_format.eq."ps") then
				delete(wks)
			end if
			delete(pll)
		end if
	end do

end
