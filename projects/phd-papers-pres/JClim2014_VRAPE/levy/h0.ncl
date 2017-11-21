; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

  phys_type = "CAM4"
  	var_names = (/"CLDTOT"/)

	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/uniform_120/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+phys_type+"/uniform_15/h0avg_regrid_0.25x0.25.nc ; "\   
		)

	print(fnames)
	add_leg = True

	output_format = "pdf"
;	output_format = "pdf"
;	output_format = "ps"
;	output_format = "ncgm"

;	run_names = (/"quad_15_x4", "uniform_15", "uniform_60"/)
	run_names = (/"quadrant_15_x8", "uniform_15", "uniform_120"/)
;	var_names = (/"PRECT", "PRECL", "PRECC", "PS","CLDTOT","OMEGA","OMEGA300","EKE100"/)
;	var_names = (/"PRECL", "CLDTOT"/)


	if (output_format.ne."ps") then
		plotname = "h0_"+var_names+"_"+phys_type
		print(plotname)
		wks = gsn_open_wks(output_format,plotname)
		gsn_define_colormap(wks,"BlWhRe")
	end if

	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)

	lthick=4
	thick=4
	color_list = (/"black", "red", "blue"/)
	ncolors = dimsizes(color_list)
	if ((fcnt.ne.ncolors).and.(fcnt.gt.1).and.(ncolors.gt.1)) then
		print((/"Error, number of colors doesn't match number of files read!"/))
		exit
	end if
	print(color_list(0:fcnt-1)+": "+fnames)

	if (add_leg) then
		leg_labels = (/"variable res", "0.25:S:o:N:", "2:S:o:N:"/)
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
		; resxy@pmLegendOrthogonalPosF = -1.05
		resxy@pmLegendOrthogonalPosF = -.33
		resxy@pmLegendWidthF = 0.1
		resxy@pmLegendHeightF = 0.1
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
					resxy@pmLegendParallelPosF = 0.5
					pll(k,0:nlat-1) = (varll(0:nlat-1) + varll(nlat-1:0))/2.
				else
					resxy@trXMinF = -90.
					resxy@trXMaxF = 90.
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
				plotname = "h0"
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


;	resxy@tiMainString        = ":F21:CLOUD FRACTION"
;	resxy@tiYAxisString          = ":F21:fraction"
;	resxy@trXMinF = -30.
;	resxy@trXMaxF = 0.
;	resxy@trYMinF = 0.2
;	resxy@trYMaxF = 1.0

;pdfcropcommand = "pdfcrop --verbose "+plotname+"."+output_format+" "+plotname+"."+output_format
;print(" "+pdfcropcommand)
;system(pdfcropcommand)

end
