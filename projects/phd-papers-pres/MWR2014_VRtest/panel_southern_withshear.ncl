load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"



begin

;   out_type = "eps"
	out_type = "pdf"
;	out_type = "x11"
;	out_type = "ps"

wks = gsn_open_wks(out_type,"panel_southstorm_withvort")
plotU = new(4,graphic)                         ; create graphic array
plotL = new(4,graphic)                         ; create graphic array

time = 1
;************************************************
; read in netCDF file
;************************************************

 gdir = "/glade/scratch/zarzycki/APE_tc/year0002/"
 a = addfile(gdir+"southstorm.nc","r")

stride = 1 

;mod_lat = a->lat(::stride)
;mod_lon = a->lon(::stride)
 
;mod_nlat = dimsizes(mod_lat)
;mod_nlon = dimsizes(mod_lon)

 gdir2 = "/glade/scratch/zarzycki/APE_tc/year0002/"
 in1 = addfile(gdir+"southstormh0.nc","r")

 wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_cyc_15_x8_TO_0.25x0.25_patc.130225.nc"

;---Get two variables to regrid and the source lat/lon grid
; Pct_se  = in1->PRECT(:,:)            ; time (1) x ncol
 u_se = in1->U(16:34:6,{200},:)            ; time (1) x nlev x ncol
 v_se = in1->V(16:34:6,{200},:)            ; time (1) x nlev x ncol
 u_se_850 = in1->U(16:34:6,{500},:)            ; time (1) x nlev x ncol
 v_se_850 = in1->V(16:34:6,{500},:)            ; time (1) x nlev x ncol

 Opt         = True
 u = ESMF_regrid_with_weights(u_se,wgt_file,Opt)
 v = ESMF_regrid_with_weights(v_se,wgt_file,Opt)
 u850 = ESMF_regrid_with_weights(u_se_850,wgt_file,Opt)
 v850 = ESMF_regrid_with_weights(v_se_850,wgt_file,Opt)
 
 print("Done regridding")

shear850250 = u850
shear850250 = 1.943*sqrt((u850-u)^2 + (v850-v)^2)

; Delete u and v from above so we can load 850 mb winds from second file
;delete(u)
;delete(v)

;  u = a->U850(:,:,:)
;  v = a->V850(:,:,:)
  
  wind850 = u850
  wind850 = sqrt(u850^2+v850^2)
  
  wind850@units = "m/s"
; wind!1 = "lat"
; wind!2 = "lon"
; wind&lat = mod_lat
; wind&lon = mod_lon
 wind850@long_name = "850 hPa wind speed"
;********** Delete variables

delete(u)
delete(v)
delete(u850)
delete(v850)

;************************************************
; create plots
;************************************************

	refine_type = "cyclone"
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
	gridfile = "/glade/p/work/zarzycki/grids/exodus/"+gridname+".g"
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
	res2@tiMainString = ""

	res2@gsnDraw = False
	res2@gsnFrame = False
	
	res2@lbLabelBarOn         = False              ; turn off indiv. label bars
	res2@lbBoxLinesOn         = False
	res2@cnInfoLabelOn       = False           ; turn off cn info label
  
  res2@cnFillOn		  = True

  res2@gsnAddCyclic = False
  
 res2@trYMaxF      = -10
 res2@trYMinF      = -30
 res2@trXMaxF      = 110
 res2@trXMinF      = 85
 
  res2@tmXBTickSpacingF = 10.0
  res2@tmXBMinorPerMajor = 5
  
  res2@cnLinesOn   = False		   				; turn off the contour lines
  res2@cnLineLabelsOn       = False             ; turn off line labels

res2@gsnStringFontHeightF = 0.025
res2@gsnLeftString = ""
res2@gsnCenterString = ""
res2@gsnRightString = ""
res2@tmXBLabelFontHeightF = 0.025
res2@tmYLLabelFontHeightF = 0.025
;res2@tiYAxisFontHeightF = 0.02

;res2@vpWidthF     = 1
;res2@vpHeightF    = 1

;gsn_merge_colormaps(wks,"BlRe","gui_default")
;gsn_draw_colormap(wks) 


; WIND
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap

 res2@gsnSpreadColors      = True              ; use full colormap
 res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
; res2@lbLabelStride        = 4
 res2@cnLevelSpacingF      =  2.5                ;
 res2@cnMinLevelValF       =  0.0           ;
 res2@cnMaxLevelValF       =  60.0 ; Use 80.0 -> 60 for this
 
; print(res2@cnFillColors)
 

 

 ;print(res3@cnFillColors)
 
plotU(0) = gsn_csm_contour(wks,wind850(0,:,:),res2)
plotU(1) = gsn_csm_contour(wks,wind850(1,:,:),res2) 
plotU(2) = gsn_csm_contour(wks,wind850(2,:,:),res2) 
plotU(3) = gsn_csm_contour(wks,wind850(3,:,:),res2) 

;9, 33, 49, 69


;************************************************
; Draw HOMME grid on top of plot
;************************************************

; get nelem
; get map
; get lon
; get lat

	xlon = new ( (/5/), "double")
	xlat = new ( (/5/), "double")
	
	j1 = ispan(0,3,1)
	j2 = (j1+1)%4
	
		dum0 = new(nelem,graphic)
		dum1 = new(nelem,graphic)
		dum2 = new(nelem,graphic)
		dum3 = new(nelem,graphic)
		dum4 = new(nelem,graphic)
		dum5 = new(nelem,graphic)
		dum6 = new(nelem,graphic)
		dum7 = new(nelem,graphic)

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
		
if((xlat(0) .gt. res2@trYMinF - 10) .and. (xlat(0) .lt. res2@trYMaxF + 10) .and. (xlon(0) .gt. res2@trXMinF - 10) .and. (xlat(0) .lt. res2@trXMaxF + 10)) then
		dum0(i) = gsn_add_polyline(wks,plotU(0),xlon,xlat,res_p)
		dum1(i) = gsn_add_polyline(wks,plotU(1),xlon,xlat,res_p)
		dum2(i) = gsn_add_polyline(wks,plotU(2),xlon,xlat,res_p)
		dum3(i) = gsn_add_polyline(wks,plotU(3),xlon,xlat,res_p)
end if

	end do

;	system("/bin/rm -f "+gridfile+".nc")
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
;  resP@gsnPanelLabelBar    = True                ; add common colorbar
;  resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
;  resP@lbLabelStride    = 4
  
;  resP@gsnPanelFigureStrings= (/"Day 1","Day 4","Day 6","Day 8"/)
;  resP@amJust = "TopRight"
  
;  resP@pmLabelBarWidthF = 0.7



  resP                  = True
  resP@gsnMaximize      = True
  resP@gsnFrame         = False
  resP@gsnPaperOrientation = "auto"
;  resP@gsnPanelLabelBar = True 
  resP@gsnDraw = False
  
  pplots = gsn_panel_return(wks,plotU,(/1,4/),resP)
  bb     = NhlGetBB(pplots)
  height = max(bb(:,0)) - min(bb(:,1))
  
  print(height)  

  res_U                   = True
  res_U@gsnMaximize = True
  res_U@gsnPaperOrientation = "auto"
  res_U@gsnFrame          = False
  res_U@gsnPanelTop       = 1.0
  res_U@gsnPanelBottom    = res_U@gsnPanelTop - height
  res_U@gsnPanelLabelBar  = True
  res_U@lbLabelFontHeightF = 0.01
  res_U@lbLabelStride        = 5
  
  res_U@lbTitleString = "m/s"
  res_U@lbTitlePosition  = "Right"              ; title position
  res_U@lbTitleFontHeightF= .01                ; make title smaller
  res_U@lbTitleDirection = "Across"             ; title direction
  res_U@lbTitleExtentF = 0.01
  
res_U@gsnPanelFigureStrings= (/"a.) 00 hrs","b.) +18 hrs","c.) +36 hrs","d.) +54 hrs"/)
res_U@amJust = "TopRight"
res_U@gsnPanelFigureStringsFontHeightF = 0.007
  
  gsn_panel(wks,plotU,(/1,4/),res_U)
  
; VORT
 gsn_define_colormap(wks,"BlueRed")          ; choose colormap
 res3 = res2
 res3@gsnSpreadColors      = True              ; use full colormap
; res3@lbLabelStride        = 4
 res3@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
; res3@cnFillColors = ispan(2,97,1)
 res3@cnMinLevelValF       =  0           ;
 res3@cnMaxLevelValF       =  100 ; Use 80.0 -> 60 for this
 res3@cnLevelSpacingF      =  5.
  
  
  res_L                   = res_U
  res_L@gsnPanelTop       = res_U@gsnPanelBottom
  res_L@gsnPanelBottom    = res_L@gsnPanelTop - height
  res_L@gsnPanelFigureStrings= (/"e.) 00 hrs","f.) +18 hrs","g.) +36 hrs","h.) +54 hrs"/)
  res_L@lbTitleString = "10~S~-5~N~ s~S~-1"
  res_L@lbTitleExtentF = 0.02
 
plotL(0) = gsn_csm_contour(wks,shear850250(0,:,:),res3)
plotL(1) = gsn_csm_contour(wks,shear850250(1,:,:),res3) 
plotL(2) = gsn_csm_contour(wks,shear850250(2,:,:),res3) 
plotL(3) = gsn_csm_contour(wks,shear850250(3,:,:),res3)

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
		
if((xlat(0) .gt. res2@trYMinF - 10) .and. (xlat(0) .lt. res2@trYMaxF + 10) .and. (xlon(0) .gt. res2@trXMinF - 10) .and. (xlat(0) .lt. res2@trXMaxF + 10)) then
		dum4(i) = gsn_add_polyline(wks,plotL(0),xlon,xlat,res_p)
		dum5(i) = gsn_add_polyline(wks,plotL(1),xlon,xlat,res_p)
		dum6(i) = gsn_add_polyline(wks,plotL(2),xlon,xlat,res_p)
		dum7(i) = gsn_add_polyline(wks,plotL(3),xlon,xlat,res_p)
end if

	end do

	system("/bin/rm -f "+gridfile+".nc")
  
  gsn_panel(wks,plotL,(/1,4/),res_L)
  
frame(wks)
	
;************************************************

;end do

end

