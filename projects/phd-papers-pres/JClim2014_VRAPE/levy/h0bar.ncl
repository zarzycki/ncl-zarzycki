; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

 physicspkg="CAM5"
		
	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_120/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_15/h0avg_regrid_0.25x0.25.nc ; "\   
		)

	output_format = "x11"
;	output_format = "pdf"
;	output_format = "ps"
;	output_format = "ncgm"

;	run_names = (/"quad_15_x4", "uniform_15", "uniform_60"/)
	run_names = (/"quadrant_15_x8", "uniform_15", "uniform_120"/)
;	var_names = (/"PRECT", "PRECL", "PRECC", "PS","CLDTOT","OMEGA","OMEGA300","EKE100"/)
;	var_names = (/"PRECL", "CLDTOT", "PRECT"/)
	var_names = (/"PRECT", "CLDTOT"/)

	if (output_format.ne."ps") then
		plotname = "h0bar"
		plotname = "./"+output_format+"/"+plotname
		wks = gsn_open_wks(output_format,plotname)
	end if

	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)
	print(fnames)

	lthick=4
	thick=4
	style_list = (/0, 3, 0, 3/)
	color_list = (/"blue", "blue", "red", "red"/)
	ncolors = dimsizes(color_list)
	print(color_list(0)+": "+fnames(0)+" (fine region)")
	print(color_list(1)+": "+fnames(0)+" (coarse region)")
	print(color_list(2:fcnt)+": "+fnames(1:fcnt-1))

	; General plot properties
	res = True
	res@gsnFrame = False
	res@gsnXYBarChart = True
	res@gsnXYBarChartColors = color_list
	res@gsnXYBarChartPatterns = style_list
	res@gsnXYBarChartBarWidth = 0.75
	res@tmXBOn = False
	res@tmXTOn = False
	res@trXMinF = 0
	res@trXMaxF = 5

	res_txt = True
	res_txt@txFontHeightF = 0.015
	res_txt@txAngleF = 90.
	res_txt@txJust = "CenterLeft"
	labels = (/"2:S:o:N:", "x8 (coarse)", "0.25:S:o:N:", "x8 (fine)"/)
	print((/labels/))

	do m=0, dimsizes(var_names)-1
		cur_var = var_names(m)
		make_plot = False

		if(cur_var.eq."PRECT") then
			;
			;  zonal average plot PRECT
			;
			make_plot = True
			res@tiMainString        = ":F21:TOTAL PRECIPITATION"
			res@tiYAxisString          = ":F21:mm/day"
			res@trYMinF = 0.
			res@trYMaxF = 6.
			space = 0.04375
		end if

		if(cur_var.eq."PRECL") then
			;
			;  zonal average plot PRECL
			;
			make_plot = True
			res@tiMainString        = ":F21:LARGE-SCALE PRECIPITATION"
			res@tiYAxisString          = ":F21:mm/day"
			res@trYMinF = 0.
			res@trYMaxF = 3.5 
			res@tmYLFormat = "0@*+^sg"
			space = 0.04375
		end if

		if(cur_var.eq."CLDTOT") then
			;
			;  zonal average plot CLOUD TOT
			;
			make_plot = True
			res@tiMainString = ":F21:CLOUD FRACTION"
			res@tiYAxisString = ":F21:fraction"
			res@trYMinF = 0.
			res@trYMaxF = 0.8
			res@tmYLFormat = "@*+^sg"
			space = 0.01
		end if

		if (make_plot) then
			print(res@tiMainString)
			pll = new((/fcnt+1/),double)
			do k=0,3
				; Ordering for files:
				; 0 = high-res refined
				; 1 = low-res refined
				; 2 = high-res uniform (only center!)
				; 3 = low-res uniform (global)

				; Order for plotting:
				; 3
				; 1
				; 2
				; 0
				f = fall[max((/0,k-1/))]
				if (k.eq.0) then
					pll(3) = (wgt_areaave(f->$cur_var$(0,{-25:25},{0:30}), f->gw({-25:25}), 1.0, 1) + wgt_areaave(f->$cur_var$(0,{-25:25},{330:360}),f->gw({-25:25}),1.0,1))/2.
				end if

				if (k.eq.1) then
					pll(1) = wgt_areaave(f->$cur_var$(0,:,{60:300}), f->gw, 1.0, 1)
				end if
				
				if (k.eq.2) then
;					pll(2) = (wgt_areaave(f->$cur_var$(0,{-25:25},{0:30}), f->gw({-25:25}), 1.0, 1) + wgt_areaave(f->$cur_var$(0,{-25:25},{330:360}),f->gw({-25:25}),1.0,1))/2.
					pll(2) = (wgt_areaave(f->$cur_var$(0,{-25:25},:), f->gw({-25:25}), 1.0, 1) + wgt_areaave(f->$cur_var$(0,{-25:25},:),f->gw({-25:25}),1.0,1))/2.
				end if

				if (k.eq.3) then
					pll(0) = wgt_areaave(f->$cur_var$(0,:,:), f->gw, 1.0, 1)
				end if

				delete(f)
			end do

			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT")) then
				pll = pll*1000.*86400. ; convert to mm/day!
			end if
			print((/pll/))

			if (output_format.eq."ps") then
				plotname = "h0bar"
				plotname = "./"+output_format+"/"+plotname+"-"+cur_var
				wks = gsn_open_wks(output_format, plotname)
			end if
			plot = gsn_csm_xy(wks, ispan(1,4,1), pll, res)

			; Add labels
			do i=0,3
				gsn_text(wks, plot, labels(i), i+1, pll(i)+space, res_txt)
			end do

			frame(wks)
;			plot=gsn_xy(wks,fall[0]&lat,pll(:,:),res) ; create plot
			if (output_format.eq."ps") then
				delete(wks)
			end if
			delete(pll)
		end if
	end do

end
