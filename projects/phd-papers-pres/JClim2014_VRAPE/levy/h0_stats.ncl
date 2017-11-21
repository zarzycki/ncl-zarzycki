; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

output_format = "x11"
physicspkg="CAM5"
already_regridded=True ; Currently False is not supported because I'm too lazy to deal with GWs
run_names = (/"quadrant_15_x8", "uniform_15", "uniform_120"/)
;var_names = (/"PRECC","PRECL","PRECT","CLDTOT","TMQ"/)
var_names = (/"PRECT","CLDTOT"/)

if (already_regridded .eq. True)
	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_120/h0avg_regrid_0.25x0.25.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_15/h0avg_regrid_0.25x0.25.nc ; "\   
		)
else
	fnames =  systemfunc(\
  "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/quadrant_15_x8/h0avg.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_120/h0avg.nc ; "\
+ "ls /glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_15/h0avg.nc ; "\   
		)
  wnames = (/"/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc",\
   "/glade/p/work/zarzycki/maps/plotmaps/map_uniform_120_TO_0.25x0.25_patc.130729.nc",\
   "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"/)
end if


	fall   = addfiles(fnames,"r")       ; Open netCDF files.	
	fcnt = dimsizes(fnames)
	print(fnames)
  
  do avgarea = 0,0
  
  if (avgarea .eq. 0) then
    latband = 90
    londelta = 30
  else if (avgarea .eq. 1) then
    latband = 25
    londelta = 30
  else if (avgarea .eq. 2) then
    latband = 20
    londelta = 10
  else
    print("Dum dum")
  end if
  end if
  end if
  
  print("Using latband = "+latband)
  
  
	do m=0, dimsizes(var_names)-1
		cur_var = var_names(m)

			pll = new((/fcnt+1/),double)
		 
                        print("0 - Low res uniform")
                        print("1 - Low res VR")
                        print("2 - High res uniform")
                        print("3 - High res VR")
	
			do k=0,3
				f = fall[max((/0,k-1/))]
				;printVarSummary(f)
				if (k.eq.0) then
				  if (already_regridded .eq. True)
				    ;pll(3) = (wgt_areaave(f->$cur_var$(0,{-latband:latband},{0:londelta}), f->gw({-latband:latband}), 1.0, 1) + wgt_areaave(f->$cur_var$(0,{-latband:latband},{(360-londelta):360}),f->gw({-latband:latband}),1.0,1))/2.
				    pll(3) = wgt_areaave(f->$cur_var$(0,:,:), f->gw(:), 1.0, 1)
				  else
				    ;f->$cur_var$
				  end if
				end if

				if (k.eq.1) then
					;pll(1) = wgt_areaave(f->$cur_var$(0,{-latband:latband},{60+(30-londelta):300}), f->gw({-latband:latband}), 1.0, 1)
					pll(1) = wgt_areaave(f->$cur_var$(0,:,:), f->gw(:), 1.0, 1)
				end if
				
				if (k.eq.2) then
					;pll(2) = (wgt_areaave(f->$cur_var$(0,{-latband:latband},{0:londelta}), f->gw({-latband:latband}), 1.0, 1) + wgt_areaave(f->$cur_var$(0,{-latband:latband},{(360-londelta):360}),f->gw({-latband:latband}),1.0,1))/2.
					pll(2) = wgt_areaave(f->$cur_var$(0,:,:), f->gw(:), 1.0, 1)
				end if

				if (k.eq.3) then
					;pll(0) = wgt_areaave(f->$cur_var$(0,{-latband:latband},{60+(30-londelta):300}), f->gw({-latband:latband}), 1.0, 1)
				  pll(0) = wgt_areaave(f->$cur_var$(0,:,:), f->gw(:), 1.0, 1)
				end if

				delete(f)
			end do

			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT").or.(cur_var.eq."PRECC")) then
				pll = pll*1000.*86400. ; convert to mm/day!
			end if
			
			print("Now working: "+cur_var)
			print((/pll/))

		
			delete(pll)

	end do
  end do
end
