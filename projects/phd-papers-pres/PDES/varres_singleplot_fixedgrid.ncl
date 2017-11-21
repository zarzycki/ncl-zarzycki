load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"


begin
;   out_type = "eps"
;	out_type = "pdf"
;	out_type = "x11"
	out_type = "ps"

wks = gsn_open_wks(out_type,"varres_single_fixedgrid")


;************************************************
; read in netCDF file
;************************************************
;  a = addfile("/Users/zarzycki/Research/data_files/HOMME/AGU/highres/cyclone_30_x4/camrun.cam.h1.0000-09-01-00000.nc","r")
;  a = addfile("/Users/zarzycki/Research/working/camrun.cam.h0.0000-09-01-00000.nc","r")
;    a = addfile("/Users/zarzycki/Research/data_files/HOMME/AGU/transition/out_of_mesh/lon_272/camrun.cam.h0.0000-09-01-00000.nc","r")
;   a = addfile("/Users/zarzycki/Research/data_files/HOMME/AGU/transition/camrun.cam.h0.0000-09-01-00000.nc","r")
;   a = addfile("/ptmp/zarzycki/cam5_work/lowtohighnorth_15_x8/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")
;   a = addfile("/ptmp/zarzycki/cam5_work/hightolownorth_15_x8/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")
   a = addfile("/ptmp/zarzycki/cam5_work/hightolownorth_15_x8_adia/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")
;   a = addfile("/ptmp/zarzycki/cam5_work/uniform_15/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")
;   a = addfile("/ptmp/zarzycki/cam5_work/cyclone_15_x8/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")

do time = 0,getfilevardimsizes(a, "time" )-1
level = 23

 mod_lat = a->lat
 mod_lon = a->lon
 
 mod_nlat = dimsizes(mod_lat)
 mod_nlon = dimsizes(mod_lon)
 
; temp = a->FLUT(time,:,:)            ; read in first time step of T data
; temp = a->TGCLDCWP(time,:,:)            ; read in first time step of T data
; temp = a->LHFLX(time,:,:)            ; read in first time step of T data
; temp = a->PS(time,:,:)
 
; PRECIP 
; Pct = a->PRECT(time,:,:)
; temp = Pct*3.6d6
; temp@units = "mm/hr"
; temp!0 = "lat"
; temp!1 = "lon"
; temp&lat = mod_lat
; temp&lon = mod_lon
; temp@long_name = "Total"

  u = a->U(time,level,:,:)
  v = a->V(time,level,:,:)
  
  wind = sqrt(u^2+v^2)
  
  wind@units = "m/s"
 wind!0 = "lat"
 wind!1 = "lon"
 wind&lat = mod_lat
 wind&lon = mod_lon
 wind@long_name = "Wind speed"
  
;  scale = 1.e05                                  
;  vrt   = u                                      ; retain coordinates
;  vrt   = uv2vrF_Wrap(u,v) * scale
;  vrt@long_name = "vorticity"
;  vrt@units     = "scaled"

PS1 = a->PS(time,:,:)

;************************************************
; PS min solver
;************************************************

if (time .eq. 0)

    ;---FIND LOCATIONS OF PSMIN and WINDMAX
	;---Convert to 1D
		b = new((/mod_nlat,mod_nlon/),float)
		b(:,:) = PS1(:,:)
		b1D      = ndtooned(b)
		dsizes_b = dimsizes(b)

	;---Resolve the 1D indices back to their original 3D array.
		b_indices  = ind_resolve(minind(b1D),dsizes_b)
  
	;---Convert index to lat/lon points
		psminlat = mod_lat(b_indices(0,0))
		psminlon = mod_lon(b_indices(0,1))
		
		print(psminlat)
		print(psminlon)

end if
		
;************************************************

;************************************************
; create plots
;************************************************

	refine_type = "hightolownorth"
	coarse_ne = 15
	num_refine = 8
	num_smth = 0

	if (refine_type.eq."mountain")
		drawmtn = True ; draw mtn from TC 5
	else
		drawmtn = False
	end if

	if (num_refine.eq.0) then
		gridname = "uniform_"+coarse_ne
	else
		gridname = refine_type + "_" + coarse_ne + "_x" + num_refine
		if (num_smth.ne.0) then
			gridname = gridname + "-s"+num_smth
		end if
	end if
	gridfile = "/glade/home/zarzycki/grids/exodus/"+gridname+".g"
	if (.not.isfilepresent(gridfile)) then
		print((/"Can not find "+gridfile+"!"/))
		exit
	end if

	print((/"Plotting mesh from "+gridfile/))
	system("ln -s "+gridfile+" "+gridfile+".nc")

	pi4= atan(1.d);
	pi2 = acos(0.d)
	pi = pi2*2.d
	f = addfile(gridfile+".nc","r")
	num_el_blk=dimsizes(f->eb_status)

	if ((num_el_blk.ne.6).and.(num_el_blk.ne.1)) then
		print("Neither cube nor sphere, can't plot!")
		system("/bin/rm -f "+gridfile+".nc")
		exit
	end if

	if (num_el_blk.eq.6) then
		IsCube = True
	else
		IsCube = False
	end if

	; cartesian coords:
	coordx = f->coord(0,:)
	coordy = f->coord(1,:)
	coordz = f->coord(2,:)

	; convert to lat/lon (project from cube to sphere!)
	if (IsCube) then 
		tol = 1e-8
		print("Projecting coordinates onto sphere...")
		n_nodes = dimsizes(coordx)
		r = sqrt(coordx*coordx + coordy*coordy + coordz*coordz)
		lat = new(n_nodes,"double")
		lon = new(n_nodes,"double")
		face = new(n_nodes,"double")
		do i=0,n_nodes-1
			face(i) = -1
			if ((coordx(i).le.-pi4+tol).and.(face(i).eq.-1)) then
				face(i) = 2
				alpha = -coordy(i)
				beta = coordz(i)
			end if
			if ((coordx(i).ge.pi4-tol).and.(face(i).eq.-1)) then
				face(i) = 0
				alpha = coordy(i)
				beta = coordz(i)
			end if
			if ((coordy(i).le.-pi4+tol).and.(face(i).eq.-1)) then
				face(i) = 3
				alpha = coordx(i)
				beta = coordz(i)
			end if
			if ((coordy(i).ge.pi4-tol).and.(face(i).eq.-1)) then
				face(i) = 1
				alpha = -coordx(i)
				beta = coordz(i)
			end if
			if ((coordz(i).le.-pi4+tol).and.(face(i).eq.-1)) then
				face(i) = 5
				alpha = coordy(i)
				beta = coordx(i)
			end if
			if ((coordz(i).ge.pi4-tol).and.(face(i).eq.-1)) then
				face(i) = 4
				alpha = coordy(i)
				beta = -coordx(i)
			end if
			if (face(i).eq.-1) then
				print("Error: face not assigned to a node!")
				print((/i+" "+coordx(i)+" "+coordy(i)+" "+coordz(i)/))
				system("rm -f "+gridfile+".nc")
				exit
			end if
			if (face(i).lt.4) then
				lon(i) = alpha+pi2*face(i)
				lat(i) = atan(tan(beta)*cos(alpha))
			end if
			if (face(i).eq.4) then
				lon(i) = atan2(tan(alpha), -tan(beta))
				if (tan(alpha)*tan(alpha)+tan(beta)*tan(beta).lt.tol) then
					lat(i) = pi2
				else
					lat(i) = atan(1.d/sqrt(tan(alpha)*tan(alpha)+tan(beta)*tan(beta)))
				end if
			end if
			if (face(i).eq.5) then
				lon(i) = atan2(tan(alpha), tan(beta));-pi
				if (tan(alpha)*tan(alpha)+tan(beta)*tan(beta).lt.tol) then
					lat(i) = -pi2
				else
					lat(i) = -atan(1.d/sqrt(tan(alpha)*tan(alpha)+tan(beta)*tan(beta)))
				end if
			end if
		end do
		print("... done!")
	else
		lat = asin(coordz)
		lon = atan2(coordy,coordx)
	end if
	lat = lat*180.d/pi
	lon = lon*180.d/pi

	if (drawmtn) then
	; CODE REMOVED
	end if

	print("number of verticies = "+dimsizes(lon))
	print("lat min/max = "+min(lat)+" "+max(lat))
  
	dimnames = getvardims(f)
	dimsz = getfiledimsizes(f)
	do i=0,dimsizes(dimnames)-1
		if ( dimnames(i).eq."num_elem") 
			print("dimname[i]="+dimnames(i)+" "+dimsz(i))
			nelem=dimsz(i)
		end if
	end do  

	map = new ( (/nelem,4/), "integer", -99 )

	count=0
	fcnt = dimsizes(f->connect1)
	print("dimsizes(map1)="+fcnt)
	n=fcnt(0)
	map(count:(n-1),:) = (/ f->connect1 /)
	count=count+n

	if (IsCube) 
		fcnt = dimsizes(f->connect2)
		print("dimsizes(map2)="+fcnt)
		n=fcnt(0)
		map(count:(count+n-1),:) = (/ f->connect2 /)
		count=count+n

		fcnt = dimsizes(f->connect3)
		print("dimsizes(map2)="+fcnt)
		n=fcnt(0)
		map(count:(count+n-1),:) = (/ f->connect3 /)
		count=count+n

		fcnt = dimsizes(f->connect4)
		print("dimsizes(map2)="+fcnt)
		n=fcnt(0)
		map(count:(count+n-1),:) = (/ f->connect4 /)
		count=count+n

		fcnt = dimsizes(f->connect5)
		print("dimsizes(map2)="+fcnt)
		n=fcnt(0)
		map(count:(count+n-1),:) = (/ f->connect5 /)
		count=count+n

		fcnt = dimsizes(f->connect6)
		print("dimsizes(map2)="+fcnt)
		n=fcnt(0)
		map(count:(count+n-1),:) = (/ f->connect6 /)
		count=count+n
	end if

	nelem=count
	print(dimsizes(map))
	print("number of elements = "+nelem)

;************************************************
;
;************************************************

  ii  = ispan(0,216,1)
  iis = sprinti("%0.4i",ii)   ; "000", "001", ... "100"
  
; THIS OUTPUT IS USED FOR CREATING ANIMATIONS
;	wks = gsn_open_wks(out_type,"./pdfs/"+iis(time))
;	wks = gsn_open_wks(out_type,"./pdfs/grid")
;	wks = gsn_open_wks(out_type,"./pdfs/grid")

;************************************************
; Plot underlying field
;************************************************

	; polygon resources
	res_p             = True

	res_p@gsLineThicknessF = 1.0
	res_p@gsLineColor   = "black"

	res2 = True
	res2@tiMainString = ""

	res2@gsnDraw = False
	res2@gsnFrame = False
  
	res2@mpOutlineOn = False
	res2@mpGreatCircleLinesOn = True

	res2@mpGridAndLimbOn = True
	res2@mpGridLineDashPattern = 2

	res2@gsnMajorLonSpacing = 20
	res2@mpGridLonSpacingF = 20
	res2@gsnMajorLatSpacing = 15
	res2@mpGridLatSpacingF = 15
	
;	gsn_define_colormap(wks,"gui_default")
;    gsn_define_colormap(wks,"nrl_sirkes")
    gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
  
    res2@cnFillOn		  = True
	
;  res2@mpMaxLatF                   = psminlat + 15           ; choose subregion           
;  res2@mpMinLatF                   = psminlat - 15
;  res2@mpMaxLonF                   = psminlon + 15
;  res2@mpMinLonF                   = psminlon - 15
;   res2@mpMaxLatF                   = 40           ; choose subregion           
;   res2@mpMinLatF                   = 5
;   res2@mpMaxLonF                   = -70
;   res2@mpMinLonF                   = -120
 
   res2@mpMaxLatF                   = psminlat + 30; choose subregion
   res2@mpMinLatF                   = psminlat - 5
   res2@mpMaxLonF                   = psminlon + 20
   res2@mpMinLonF                   = psminlon - 30
 
  ;res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  ;res2@cnMinLevelValF  = 0.			; set the minimum contour level
  ;res2@cnMaxLevelValF  = 2.			; set the maximum contour level

;  THESE ARE LEVELS FOR CLOUD WATER / IR SURROGATE PLOTS  
;  res2@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
;  res2@cnLevels    = (/ 0.06,0.10,0.25,0.5,0.75,1.0,1.5,2.0,2.5,3. /)	; set for water path

  

;  res2@cnLevelSelectionMode = "ExplicitLevels"
;  res2@gsnSpreadColors     = True	        ; use full colormap  
;  res2@gsnSpreadColorStart  = -1                 ; start with last color
;  res2@gsnSpreadColorEnd   = 2                   ; end with a beginning color
;  res2@cnLevels    = (/ 120.,125.,130.,140.,150.,190.,195.,200.,220.,240. /)	; set for OLR
 
; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
; res2@cnLevelSelectionMode = "ExplicitLevels"
; res2@cnLineLabelsOn       = False             ; turn off line labels
; res2@gsnSpreadColors      = True              ; use full colormap
; res2@lbLabelBarOn         = False              ; turn off indiv. label bars
; res2@lbLabelStride        = 4
; res2@cnInfoLabelOn        = False             ; turn off info label bar
; res2@cnLevels                =(/0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80./)
 
; SURFACE PRESSURE
; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
; res2@cnLineLabelsOn       = False             ; turn off line labels
; res2@gsnSpreadColors      = True              ; use full colormap
; res2@lbLabelStride        = 4
;  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
;  res2@cnMinLevelValF  = 98000.			; set the minimum contour level
;  res2@cnMaxLevelValF  = 102000.			; set the maximum contour level
;    res2@cnLevelSpacingF = 4.			; set the interval between contours
    
; WIND
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
 res2@cnLineLabelsOn       = False             ; turn off line labels
 res2@gsnSpreadColors      = True              ; use full colormap
 res2@lbLabelStride        = 2
 res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 res2@cnLevelSpacingF      =  2.5                ;
 res2@cnMinLevelValF       =  0.0           ;
 res2@cnMaxLevelValF       =  80.0 ; Use 80.0 -> 60 for this
  
  res2@cnLinesOn   = False		   				; turn off the contour lines
  
;  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
;  res2@cnMinLevelValF  = 0.			; set the minimum contour level
;  res2@cnMaxLevelValF  = 600.			; set the maximum contour level
;  res2@cnLevelSpacingF = 30.			; set the interval between contours
  

	plot2 = gsn_csm_contour_map(wks,wind(:,:),res2) 
	draw(plot2)

;************************************************
; Draw HOMME grid on top of plot
;************************************************

	xlon = new ( (/5/), "double")
	xlat = new ( (/5/), "double")
	
	j1 = ispan(0,3,1)
	j2 = (j1+1)%4

	do i=0,nelem-1
		if ( mod(i,1000).eq.0) then
			print ("i = "+i+"/"+(nelem-1))
		end if
		xlon(0:3) = lon(map(i,:)-1)
		xlat(0:3) = lat(map(i,:)-1)

		do j=0,2
			if ( abs(xlon(j+1)-xlon(j)) .gt. 180.0) then
				if (xlon(j+1) .gt. xlon(j) ) then
					xlon(j)=xlon(j)+360.
				else
				xlon(j+1)=xlon(j+1)+360.
				end if
			end if
		end do
	
		xlon(4)=xlon(0)
		xlat(4)=xlat(0)
		
		if((xlat(0) .gt. res2@mpMinLatF - 10) .and. (xlat(0) .lt. res2@mpMaxLatF + 10)) then
		; .and. (xlon(0) .gt. res2@mpMinLonF - 10) .and. (xlat(0) .lt. res2@mpMaxLonF + 10)
		
		gsn_polyline(wks, plot2, xlon,xlat,res_p)
		
		end if
		
	end do

	system("/bin/rm -f "+gridfile+".nc")
	frame(wks)
	
;************************************************

end do

end

