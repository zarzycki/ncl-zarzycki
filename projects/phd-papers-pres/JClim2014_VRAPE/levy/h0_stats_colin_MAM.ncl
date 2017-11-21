; Redsky
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

output_format = "x11"
physicspkg="CAM5_MAM"
conserve_remap=True
already_regridded=True ; Currently False is not supported because I'm too lazy to deal with GWs
;run_names = (/"quadrant_15_x8", "uniform_120", "uniform_15"/)
;var_names = (/"PRECT","PRECL","PRECT","CLDTOT","TMQ"/)
var_names = (/"PRECC","PRECL","PRECT","CLDTOT","TMQ"/)

fnames =  (/"/glade/scratch/zarzycki/APE_levy/"+physicspkg+"/quadrant_15_x8/h0avg_regrid_0.25x0.25.nc","/glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_120/h0avg_regrid_0.25x0.25.nc","/glade/scratch/zarzycki/APE_levy/"+physicspkg+"/uniform_15/h0avg_regrid_0.25x0.25.nc"/)

fcnt = dimsizes(fnames)

latband = 25
londelta = 30
pi = 3.1415926
  
print("Using latband = "+latband)

if (conserve_remap) then
  latS = -90
  latN =  90
  lonW = 0
  lonE = 360
  dlat =  2.0
  dlon =  2.0
  noutlat = toint((latN-latS)/dlat) + 1
  moutlon = toint((lonE-lonW)/dlon)
  outlat  = fspan(latS, latN, noutlat)
  outlon  = fspan(lonW, lonE-dlon, moutlon)
  outlat@units = "degrees_north"
  outlon@units = "degrees_east"
end if

                        print("0 - Low res uniform")
                        print("1 - Low res VR")
                        print("2 - High res uniform")
                        print("3 - High res VR")
  
	do m=0, dimsizes(var_names)-1
		cur_var = var_names(m)
		pll = new((/fcnt+1/),double)
			do k=0,1
			  f = addfile(fnames(max((/0,k-1/))),"r")
			  printVarSummary(f)
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
				;if (k.eq.0) then
				  var_in = f->$cur_var$(0,:,:)
				  
				  if (conserve_remap) then
            fo = area_conserve_remap_Wrap (var_in&lon,var_in&lat,var_in,outlon,outlat,False)
            delete(var_in)
            var_in = fo
            delete(fo)
				  end if
				  
				  if(any(ismissing(var_in))) then
            print("Your data contains some missing values. Beware.")
          end if
				  
				  gw = cos(var_in&LAT * pi/180.)
				  gw!0 = "lat"
				  gw&lat = var_in&LAT
				
            if (k.eq.0) then
                pll(3) = (wgt_areaave(var_in({-latband:latband},{0:londelta}), gw({-latband:latband}), 1.0, 1) + wgt_areaave(var_in({-latband:latband},{(360-londelta):360}),gw({-latband:latband}),1.0,1))/2.
            end if
            if (k.eq.1) then
              pll(1) = wgt_areaave(var_in({-latband:latband},{60+(30-londelta):300}), gw({-latband:latband}), 1.0, 1)
            end if	
            if (k.eq.2) then
              pll(2) = (wgt_areaave(var_in({-latband:latband},{0:londelta}), gw({-latband:latband}), 1.0, 1) + wgt_areaave(var_in({-latband:latband},{(360-londelta):360}),gw({-latband:latband}),1.0,1))/2.
            end if
            if (k.eq.3) then
              pll(0) = wgt_areaave(var_in({-latband:latband},{60+(30-londelta):300}), gw({-latband:latband}), 1.0, 1)
            end if

			
			delete(var_in)
			delete(gw)
			delete(f)


			


	end do
	
	    			if ((cur_var.eq."PRECL").or.(cur_var.eq."PRECT").or.(cur_var.eq."PRECC")) then
			  pll = pll*1000.*86400. ; convert to mm/day!
	    end if
	
			print("Now working: "+cur_var)
			print((/pll/))
			delete(pll)
	
end do
	
	


end
