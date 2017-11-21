load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"


begin
;   out_type = "eps"
	out_type = "pdf"
;	out_type = "x11"
;	out_type = "ps"

wks = gsn_open_wks(out_type,"dryvortexpanel")
plot2 = new(12,graphic)                         ; create graphic array



do filepick = 0,3

;************************************************
; read in netCDF file
;************************************************
if( filepick .eq. 0 ) then 
	refine_type = "hightolowvert"
	coarse_ne = 15
	num_refine = 8
	num_smth = 0
    a = addfile("/glade/p/work/zarzycki/cam5_work/hightolowvert_15_x8_adia/data_output/camrun.cam.h0.full.nc","r")
else
end if

if( filepick .eq. 1 ) then 
	refine_type = "lowtohighvert"
	coarse_ne = 15
	num_refine = 8
	num_smth = 0
    a = addfile("/glade/p/work/zarzycki/cam5_work/lowtohighvert_15_x8_adia/data_output/camrun.cam.h0.full.nc","r")
else
end if

if( filepick .eq. 2 ) then 
	refine_type = "uniform"
	coarse_ne = 15
	num_refine = 0
	num_smth = 0
    a = addfile("/glade/p/work/zarzycki/cam5_work/uniform_15_adia/data_output/camrun.cam.h0.full.nc","r")
else
end if

if( filepick .eq. 3 ) then 
	refine_type = "uniform"
	coarse_ne = 120
	num_refine = 0
	num_smth = 0
	a = addfile("/glade/p/work/zarzycki/cam5_work/uniform_120_adia/data_output/camrun.cam.h0.full.nc","r")
else
end if

ntime = getfilevardimsizes(a, "time" )

 mod_lat = a->lat({-30:30})
 mod_lon = a->lon
 
 mod_nlat = dimsizes(mod_lat)
 mod_nlon = dimsizes(mod_lon)

  u = a->U(:,{850},{-30:30},:)
  v = a->V(:,{850},{-30:30},:)
 
  u = u + 10
 
  wind = u
  wind = sqrt(u^2+v^2)
  
  wind@units = "m/s"
 wind!1 = "lat"
 wind!2 = "lon"
 wind&lat = mod_lat
 wind&lon = mod_lon
 wind@long_name = "Wind speed"
  
PS1 = a->PS(:,{-30:30},:)

;************************************************
; PS min solver
;************************************************

psminlat = new(3,double)
psminlon = new(3,double)

do plot = 0,2

    ;---FIND LOCATIONS OF PSMIN and WINDMAX
	;---Convert to 1D
		b = new((/mod_nlat,mod_nlon/),float)
		b(:,:) = PS1(10*plot,:,:)
		b1D      = ndtooned(b)
		dsizes_b = dimsizes(b)

	;---Resolve the 1D indices back to their original 3D array.
		b_indices  = ind_resolve(minind(b1D),dsizes_b)
  
	;---Convert index to lat/lon points
		psminlat(plot) = mod_lat(b_indices(0,0))
		psminlon(plot) = mod_lon(b_indices(0,1))
		
end do

		
;************************************************

;************************************************
; create plots
;************************************************




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
	gridfile = "/glade/u/home/zarzycki/grids/exodus/"+gridname+".g"
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

	res_p@gsLineThicknessF = 0.01
	res_p@gsLineColor   = "black"

	res2 = True
	
	res2@gsnDraw = False
	res2@gsnFrame = False
	res2@gsnMaximize = True
	
	res2@tiMainString = ""
	res2@gsnLeftString   = ""              ; add the gsn titles
    res2@gsnCenterString = ""
    res2@gsnRightString  = ""

	res2@mpOutlineOn = False
	res2@mpGreatCircleLinesOn = True

	res2@mpGridAndLimbOn = True
	res2@mpGridLineDashPattern = 2

	res2@gsnMajorLonSpacing = 20
	res2@mpGridLonSpacingF = 20
	res2@gsnMajorLatSpacing = 15
	res2@mpGridLatSpacingF = 15
  
    res2@cnFillOn		  = True
	
;   res2@mpMinLonF                   = -120 285 240
 

 
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
 res2@cnMaxLevelValF       =  35.0 ; Use 80.0 -> 60 for this
  
  res2@cnLinesOn   = False		   				; turn off the contour lines
  
  	res2@lbLabelBarOn         = False              ; turn off indiv. label bars
	res2@lbBoxLinesOn         = False
	res2@cnInfoLabelOn       = False           ; turn off cn info label
	
	  res2@gsnAddCyclic = True
  
;  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
;  res2@cnMinLevelValF  = 0.			; set the minimum contour level
;  res2@cnMaxLevelValF  = 600.			; set the maximum contour level
;  res2@cnLevelSpacingF = 30.			; set the interval between contours
 
;   res2@mpMaxLatF                   = psminlat(0) + 15
;   res2@mpMinLatF                   = psminlat(0) - 15
;   res2@mpMaxLonF                   = psminlon(0) + 15
;   res2@mpMinLonF                   = psminlon(0) - 15
;
;   res3 = res2
;   res4 = res2
;   res5 = res2
;   
;   res3@mpMaxLonF                   = psminlon(0) + 20
;   res3@mpMinLonF                   = psminlon(0) - 20
;   
;   res4@mpMaxLonF                   = psminlon(1) + 20
;   res4@mpMinLonF                   = psminlon(1) - 20
;   
;   res5@mpMaxLonF                   = psminlon(2) + 20
;   res5@mpMinLonF                   = psminlon(2) - 20

   res2@mpMaxLatF                   = 0 + 20
   res2@mpMinLatF                   = 0 - 20
   res2@mpMaxLonF                   = psminlon(0) + 20
   res2@mpMinLonF                   = psminlon(0) - 20

   res3 = res2
   res4 = res2
   res5 = res2
   
   res3@mpMaxLonF                   = 290 + 20
   res3@mpMinLonF                   = 290 - 20
   
   res4@mpMaxLonF                   = 270.5 + 20
   res4@mpMinLonF                   = 270.5 - 20
   
   res5@mpMaxLonF                   = 251 + 20
   res5@mpMinLonF                   = 251 - 20
   
print("At t = 0, psminlon = "+psminlon(0))
print("At t = 10, psminlon = "+psminlon(1))
print("At t = 20, psminlon = "+psminlon(2))

  

	plot2(3*filepick+0) = gsn_csm_contour_map(wks,wind(0,:,:),res3)
	plot2(3*filepick+1) = gsn_csm_contour_map(wks,wind(10,:,:),res4) 
	plot2(3*filepick+2) = gsn_csm_contour_map(wks,wind(20,:,:),res5) 

;************************************************
; Draw HOMME grid on top of plot
;************************************************



if( filepick .eq. 0 )
    dum0 = new(nelem,graphic)
        dum1 = new(nelem,graphic)
            dum2 = new(nelem,graphic)
end if
if( filepick .eq. 1 )
    dum3 = new(nelem,graphic)
        dum4 = new(nelem,graphic)
            dum5 = new(nelem,graphic)
end if
if( filepick .eq. 2 )
    dum6 = new(nelem,graphic)
        dum7 = new(nelem,graphic)
            dum8 = new(nelem,graphic)
end if
if( filepick .eq. 3 )
    dum9 = new(nelem,graphic)
        dum10 = new(nelem,graphic)
            dum11 = new(nelem,graphic)
end if

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

if( filepick .eq. 0 )
        xlat0 = xlat
        xlon0 = xlon
		if((xlat0(0) .gt. res2@mpMinLatF - 10) .and. (xlat0(0) .lt. res2@mpMaxLatF + 10)) then
		; .and. (xlon(0) .gt. res2@mpMinLonF - 10) .and. (xlat(0) .lt. res2@mpMaxLonF + 10)
		dum0(i) = gsn_add_polyline(wks,plot2(3*filepick+2),xlon0,xlat0,res_p)
		dum1(i) = gsn_add_polyline(wks,plot2(3*filepick+1),xlon0,xlat0,res_p)
		dum2(i) = gsn_add_polyline(wks,plot2(3*filepick+0),xlon0,xlat0,res_p)
		end if
end if
if( filepick .eq. 1 )
        xlat1 = xlat
        xlon1 = xlon
		if((xlat1(0) .gt. res2@mpMinLatF - 10) .and. (xlat1(0) .lt. res2@mpMaxLatF + 10)) then
		; .and. (xlon(0) .gt. res2@mpMinLonF - 10) .and. (xlat(0) .lt. res2@mpMaxLonF + 10)
		dum3(i) = gsn_add_polyline(wks,plot2(3*filepick+2),xlon1,xlat1,res_p)
		dum4(i) = gsn_add_polyline(wks,plot2(3*filepick+1),xlon1,xlat1,res_p)
		dum5(i) = gsn_add_polyline(wks,plot2(3*filepick+0),xlon1,xlat1,res_p)
		end if
end if
if( filepick .eq. 2 )
		if((xlat(0) .gt. res2@mpMinLatF - 10) .and. (xlat(0) .lt. res2@mpMaxLatF + 10)) then
		; .and. (xlon(0) .gt. res2@mpMinLonF - 10) .and. (xlat(0) .lt. res2@mpMaxLonF + 10)
		dum6(i) = gsn_add_polyline(wks,plot2(3*filepick+2),xlon,xlat,res_p)
		dum7(i) = gsn_add_polyline(wks,plot2(3*filepick+1),xlon,xlat,res_p)
		dum8(i) = gsn_add_polyline(wks,plot2(3*filepick+0),xlon,xlat,res_p)
		end if
end if		
if( filepick .eq. 3 )
        xlat3 = xlat
        xlon3 = xlon
		if((xlat3(0) .gt. res2@mpMinLatF - 5) .and. (xlat3(0) .lt. res2@mpMaxLatF + 5)) then
		; .and. (xlon(0) .gt. res2@mpMinLonF - 10) .and. (xlat(0) .lt. res2@mpMaxLonF + 10)
		dum9(i) = gsn_add_polyline(wks,plot2(3*filepick+2),xlon3,xlat3,res_p)
		dum10(i) = gsn_add_polyline(wks,plot2(3*filepick+1),xlon3,xlat3,res_p)
		dum11(i) = gsn_add_polyline(wks,plot2(3*filepick+0),xlon3,xlat3,res_p)
		end if
end if


		
	end do

	system("/bin/rm -f "+gridfile+".nc")
	
	delete([/xlon,xlat,j1,j2,coordx,coordy,coordz,lat,lon,nelem,map,dimsz,dimnames,u,v,PS1,wind/])

	
end do

;************************************************

  resP                     = True                ; modify the panel plot
;  resP@txString            = "A plot with a common label bar"
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
  resP@lbLabelStride    = 4
  
  resP@pmLabelBarWidthF = 0.7

  amres = True
  amres@amJust           = "TopRight"
  resP@gsnPanelFigureStrings= (/"a.","b.","c.","d.","e.","f.","g.","h.","i.","j.","k.","l."/)
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  
; resP@pmLabelBarHeightF

gsn_panel(wks,plot2,(/4,3/),resP)

end


