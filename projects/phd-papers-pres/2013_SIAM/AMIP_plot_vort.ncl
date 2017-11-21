load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"


begin
   out_type = "eps"
;	out_type = "pdf"
;	out_type = "x11"
;	out_type = "ps"

wks = gsn_open_wks(out_type,"AMIP_vort")
plot2 = new(2,graphic)                         ; create graphic array

;do time = 1,42
plotstep = 0

;************************************************
; read in netCDF file
;************************************************

; gdir = "/glade/scratch/zarzycki/APE_tc/"
; filename = "camrun.cam.h2.0000-12-15-00000.nc"
; a = addfile(gdir+filename,"r")

;stride = 1 
; mod_lat = a->lat(::stride)
; mod_lon = a->lon(::stride)
; mod_nlat = dimsizes(mod_lat)
; mod_nlon = dimsizes(mod_lon)
;  u = a->U200(:,::stride,::stride)
;  v = a->V200(:,::stride,::stride)

;---Names of source and weight file
;    src_file = "/glade/scratch/zarzycki/archive/atl_30_x4_refine_nochem/rest/2001-09-08-00000/atl_30_x4_refine_nochem.cam.i.2001-09-08-00000.nc"   
;    src_file = "/glade/scratch/zarzycki/archive/atl_30_x4_refine_nochem/rest/2000-09-21-00000/atl_30_x4_refine_nochem.cam.i.2000-09-21-00000.nc"
      src_file = "/glade/scratch/zarzycki/archive/atl_30_x4_refine_nochem/rest/2002-09-27-00000/atl_30_x4_refine_nochem.cam.i.2002-09-27-00000.nc"
  
    wgt_file = "/glade/u/home/zarzycki/mapping/gen_mapping_files/map_atl_30_x4_TO_0.25x0.25_patc.130225.nc"
    print(wgt_file)

;---Open files containing source HOMME and destination FV grids
    sfile = addfile(src_file,"r")

;---Get two variables to regrid and the source lat/lon grid
    u_se = sfile->U(:,{200},:)            ; time (1) x nlev x ncol
    v_se = sfile->V(:,{200},:)            ; time (1) x nlev x ncol

    Opt         = True
    u  = ESMF_regrid_with_weights(u_se,wgt_file,Opt)
    v = ESMF_regrid_with_weights(v_se,wgt_file,Opt)
    printVarSummary(u)
    printVarSummary(v)
 
vort = uv2vrF_Wrap(u,v)
vort = vort/1e-5



;PS1 = a->PS(time,::stride,::stride)

;************************************************
; PS min solver
;************************************************

    ;---FIND LOCATIONS OF PSMIN and WINDMAX
	;---Convert to 1D
;		b = new((/mod_nlat,mod_nlon/),float)
;		b(:,:) = PS1(:,:)
;;		b1D      = ndtooned(b)
;		dsizes_b = dimsizes(b)

	;---Resolve the 1D indices back to their original 3D array.
;		b_indices  = ind_resolve(minind(b1D),dsizes_b)
  
	;---Convert index to lat/lon points
;		psminlat = mod_lat(b_indices(0,0))
;		psminlon = mod_lon(b_indices(0,1))
		
;		print(psminlat)
;		print(psminlon)
		
;************************************************

;************************************************
; create plots
;************************************************

	refine_type = "atlantic"
	coarse_ne = 30
	num_refine = 4
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

	res_p@gsLineThicknessF = 0.1
	res_p@gsLineColor   = "black"

	res2 = True
	res2@tiMainString = ""

	res2@gsnDraw = False
	res2@gsnFrame = False
	
	res2@lbLabelBarOn         = False              ; turn off indiv. label bars
	res2@lbBoxLinesOn         = False
	res2@cnInfoLabelOn       = False           ; turn off cn info label
  
	
;	gsn_define_colormap(wks,"gui_default")
;    gsn_define_colormap(wks,"nrl_sirkes")
;    gsn_define_colormap(wks,"satellite")
;    gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
  
  res2@cnFillOn		  = True

  res2@gsnAddCyclic = True
  
 
; res2@trYMaxF      = 40
; res2@trYMinF      = 0
; res2@trXMaxF      = 110
; res2@trXMinF      = 70
 
 
;  res2@tmXBTickSpacingF = 10.0
;  res2@tmXBMinorPerMajor = 5
;  res2@tmYLMinorOn  = False


;   res2@mpMaxLatF                   = 40           ; choose subregion           
;   res2@mpMinLatF                   = 5
;   res2@mpMaxLonF                   = 120
;   res2@mpMinLonF                   = 70
  
  ;res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  ;res2@cnMinLevelValF  = 0.			; set the minimum contour level
  ;res2@cnMaxLevelValF  = 2.			; set the maximum contour level

;  THESE ARE LEVELS FOR CLOUD WATER / IR SURROGATE PLOTS  
;  res2@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
;    res2@gsnSpreadColorStart  = -1                 ; start with last color
;      res2@gsnSpreadColorEnd   = 2                   ; end with a beginning color
;  res2@cnLevels    = (/ 0.06,0.10,0.25,0.5,0.75,1.0,1.5,2.0,2.5,3. /)	; set for water path
;  res2@cnLevels    = (/ 100,1000,2000,3000,4000,5000,6000,7000,8000,9000. /)	; set for water path
  

;  res2@cnLevelSelectionMode = "ExplicitLevels"
;  res2@gsnSpreadColors     = True	        ; use full colormap  
;  res2@gsnSpreadColorStart  = -1                 ; start with last color
;  res2@gsnSpreadColorEnd   = 2                   ; end with a beginning color
;  res2@cnLevels    = (/ 120.,125.,130.,140.,150.,190.,195.,200.,220.,240. /)	; set for OLR
 
; PRECIP
; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
; res2@cnLevelSelectionMode = "ExplicitLevels"
; res2@cnLineLabelsOn       = False             ; turn off line labels
; res2@gsnSpreadColors      = True              ; use full colormap
; res2@lbLabelStride        = 3
; res2@cnInfoLabelOn        = False             ; turn off info label bar
; res2@cnLevels                =(/0.02, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
 
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
 gsn_define_colormap(wks,"BlueRed")          ; choose colormap
 res2@cnLineLabelsOn       = False             ; turn off line labels
 res2@gsnSpreadColors      = True              ; use full colormap
 res2@lbLabelStride        = 4
 res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 res2@cnLevelSpacingF      =  5                ;
 res2@cnMinLevelValF       =  -30.0           ;
 res2@cnMaxLevelValF       =  30.0 ; Use 80.0 -> 60 for this
  
  res2@cnLinesOn   = False		   				; turn off the contour lines
  
;  res2@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
;  res2@cnMinLevelValF  = 0.			; set the minimum contour level
;  res2@cnMaxLevelValF  = 600.			; set the maximum contour level
;  res2@cnLevelSpacingF = 30.			; set the interval between contours

;res2@tmXBLabelFontHeightF = 0.02
;res2@tmYLLabelFontHeightF = 0.02

;res2@tiXAxisFontHeightF = 0.02
;res2@tiYAxisFontHeightF = 0.02

  res2@vpWidthF     = 2
  res2@vpHeightF    = 1
  
  res2@mpOutlineOn = True
  res2@mpFillOn = False
  res2@mpFillColors = (/"background","transparent","LightGray","transparent"/)
  res2@mpGridAndLimbOn = False

  
  plot2(0) = gsn_csm_contour_map(wks,vort(plotstep,:,:),res2)
  
  res2@mpMinLatF   = 0.                      ; set the minimum latitude  
  res2@mpMaxLatF   = 60.                      ; set the maximum latitude  
  res2@mpMinLonF   = 235.                     ; set the minimum longitude  
  res2@mpMaxLonF   = 355.
  res2@mpCenterLonF = (res2@mpMinLonF+res2@mpMaxLonF)/2. 
  
  plot2(1) = gsn_csm_contour_map(wks,vort(plotstep,:,:),res2) 
;  plot2(2) = gsn_csm_contour(wks,vort(4,:,:),res2) 
;  plot2(3) = gsn_csm_contour(wks,vort(7,:,:),res2) 

;************************************************
; Draw HOMME grid on top of plot
;************************************************

	xlon = new ( (/5/), "double")
	xlat = new ( (/5/), "double")
	
	j1 = ispan(0,3,1)
	j2 = (j1+1)%4
	
		dum0 = new(nelem,graphic)
		dum1 = new(nelem,graphic)
		dum2 = new(nelem,graphic)
		dum3 = new(nelem,graphic)

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

;if((xlat(0) .gt. res2@trYMinF - 10) .and. (xlat(0) .lt. res2@trYMaxF + 10) .and. (xlon(0) .gt. res2@trXMinF - 10) .and. (xlat(0) .lt. res2@trXMaxF + 10)) then
;		dum0(i) = gsn_add_polyline(wks,plot2(0),xlon,xlat,res_p)
;		dum1(i) = gsn_add_polyline(wks,plot2(1),xlon,xlat,res_p)
;		dum2(i) = gsn_add_polyline(wks,plot2(2),xlon,xlat,res_p)
;		dum3(i) = gsn_add_polyline(wks,plot2(3),xlon,xlat,res_p)
;end if

	end do

; Draw circles for transition regions	
  clat = new(100,float)               ; Create arrays to hold circle.
  clon = new(100,float)
  clat2 = new(100,float)               ; Create arrays to hold circle.
  clon2 = new(100,float)
  dumcir = new(100,graphic)
  dumcir2 = new(100,graphic)
  
  circ_cen_lat = 26.5
  circ_cen_lon = 90.0
  
  nggcog(circ_cen_lat,circ_cen_lon,43.0,clat,clon)
  nggcog(circ_cen_lat,circ_cen_lon,55.0,clat2,clon2)

;  dumcir = gsn_add_polyline(wks, plot2(1), clon, clat, False)
;  dumcir2 = gsn_add_polyline(wks, plot2(1), clon2, clat2, False)
;  dumcir3 = gsn_add_polyline(wks, plot2(0), clon, clat, False)
;  dumcir4 = gsn_add_polyline(wks, plot2(0), clon2, clat2, False)

	system("/bin/rm -f "+gridfile+".nc")
;	frame(wks)
	
	;**************************
;   ADD DAY # TO TOP RIGHT PLOT
;**************************

;  txres                       = True
;  txres@txPerimOn             = True
;  txres@txBackgroundFillColor = "White"
;  txres@txFontHeightF         = 0.04
;  amres = True
;
;  
;  txid1 = gsn_create_text(wks, "b", txres)
;
;  amres@amParallelPosF   = 0.5    ; This is the right edge of the plot.
;  amres@amOrthogonalPosF = -0.5  ; This is the bottom edge of the plot.
;  
;  amres@amJust           = "TopRight"
;
;  annoid1 = gsn_add_annotation(plot2, txid1, amres)
;  

  resP                     = True                ; modify the panel plot
;  resP@txString            = "A plot with a common label bar"
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
  resP@lbLabelStride    = 4
  
;  resP@gsnPanelFigureStrings= (/"Day 1","Day 4","Day 6","Day 8"/)
;  resP@amJust = "TopRight"
  
  resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF
  
  gsn_panel(wks,plot2,(/2,1/),resP)
	
;************************************************

;end do

end

