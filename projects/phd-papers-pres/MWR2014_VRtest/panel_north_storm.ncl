load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin
   out_type = "pdf"
;	out_type = "pdf"
;	out_type = "x11"
;	out_type = "ps"

wks = gsn_open_wks(out_type,"panel_northern_storm")
plot2 = new(4,graphic)                         ; create graphic array

;old time = 26
time = 0

;parsetime = 28
;setlatmin = 15.07
;setlonmin = 88.43

parsetime = 32
setlatmin = 19.12
setlonmin = 80.32

;do time = 10,28

do parsetime = 36,36,2

level = 23

;************************************************
; read in netCDF file
;************************************************

 gdir = "/glade/scratch/zarzycki/APE_tc/year0001/"
 in1 = addfile(gdir+"northstorm.nc","r")
 in2 = addfile(gdir+"northstorm_h2.nc","r")
 
 wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_cyc_15_x8_TO_0.25x0.25_patc.130225.nc"

;---Get two variables to regrid and the source lat/lon grid
; Pct_se  = in1->PRECT(:,:)            ; time (1) x ncol
 u_se = in1->U(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
 v_se = in1->V(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
 t_se = in1->T(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
 q_se = in1->Q(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
 ps_se = in1->PS(parsetime:parsetime+1,:)            ; time (1) x ncol

 Opt         = True
; Pct  = ESMF_regrid_with_weights(Pct_se,wgt_file,Opt)
 u = ESMF_regrid_with_weights(u_se,wgt_file,Opt)
 v = ESMF_regrid_with_weights(v_se,wgt_file,Opt)
 t = ESMF_regrid_with_weights(t_se,wgt_file,Opt)
 q = ESMF_regrid_with_weights(q_se,wgt_file,Opt)
 PS1 = ESMF_regrid_with_weights(ps_se,wgt_file,Opt)

  
 mod_lat = u&lat
 mod_lon = u&lon
 mod_lat!0 = "lat"
 mod_lon!0 = "lon"
 mod_lat&lat = mod_lat
 mod_lon&lon = mod_lon
 lev  = in1->lev
 
 mod_lat2 = in2->lat
 mod_lon2 = in2->lon
 
 mod_nlat = dimsizes(mod_lat)
 mod_nlon = dimsizes(mod_lon)
 mod_nlat2 = dimsizes(mod_lat2)
 mod_nlon2 = dimsizes(mod_lon2)
 

; PRECIP 
 Pct = in2->PRECT(round(parsetime/2,3),:,:)
 temp = Pct*3.6d6
 temp@units = "mm/hr"
 temp!0 = "lat"
 temp!1 = "lon"
 temp&lat = mod_lat2
 temp&lon = mod_lon2
 temp@long_name = "Total Precip. Rate"
 
 dbz = rainratetodbz(temp,0)

;  u = in1->U(time,level,:,:)
;  v = in1->V(time,level,:,:)
  
  wind = sqrt(u^2+v^2)
  
  wind@units = "m/s"
  wind!1 = "lev"
  wind!2 = "lat"
  wind!3 = "lon"

  wind&lev = lev
  wind&lat = mod_lat
  wind&lon = mod_lon
  wind@long_name = "850 hPa wind speed"
  
;************************************************
; PS min solver
;************************************************

    ;---FIND LOCATIONS OF PSMIN and WINDMAX
	;---Convert to 1D
	    latcyc = mod_lat({19.-30.:19.+30.})
        loncyc = mod_lon({80.-30.:80.+30.})
	    PScyc = PS1(:,{19.-30.:19.+30.},{80.-30.:80.+30.})
        mod_nlatcyc = dimsizes(latcyc)
        mod_nloncyc = dimsizes(loncyc)
	    
		b = new((/mod_nlatcyc,mod_nloncyc/),float)
		b(:,:) = PScyc(time,:,:)
		b1D      = ndtooned(b)
		dsizes_b = dimsizes(b)

	;---Resolve the 1D indices back to their original 3D array.
		b_indices  = ind_resolve(minind(b1D),dsizes_b)
  
	;---Convert index to lat/lon points
		psminlat = latcyc(b_indices(0,0))
		psminlon = loncyc(b_indices(0,1))
		
		print(psminlat)
		print(psminlon)
		
;************************************************

;PS1 = in1->PS(time,:,:)
hyam = in1->hyam
hybm = in1->hybm 
qint = 10
pcount = 1  ; 1 if aqua 4 is simple



 psmin = new ( (/1,1/) , double )
 psxi  = new ( (/1,1/) , integer )
 psyi  = new ( (/1,1/) , integer )

;========================================================
; Define Constants
;========================================================
 pi    = 4.d0*atan(1.d0)
 con   = pi/180.d0
 a     = 6371220.d0
 omega = 7.292115d-5
 p0    = 101500.d0
 p00   = 100000.d0
 g     = 9.80616d0
 Rd    = 287.04d0
 Rv    = 461.5d0
 Lv    = 2501000.d0
 cp    = 1004.64d0
; f_cor     = 2.d0*omega*sin(10.d0*pi/180.d0)
  constq = 0.608d0

 Ts    = 302.15d0
 
 nmin = local_min(PS1(time,:,:), True, 0.0)
 wind2 = ind(nmin@minval.eq.min(nmin@minval))
 psmin = nmin@minval(wind2)
 psxi  = nmin@xi(wind2)
 psyi  = nmin@yi(wind2)
 

 
 ;psxi(0,0) = closest_val(setlonmin,mod_lon)
 ;psyi(0,0) = closest_val(setlatmin,mod_lat)

 psxi(0,0) = closest_val(psminlon,mod_lon)
 psyi(0,0) = closest_val(psminlat,mod_lat)

 print(psxi)
 print(psyi)
 
 lat_x  = mod_lat( (psyi(0,0)-qint) : (psyi(0,0)+qint) )                ; get lat
 lon_x  = mod_lon( (psxi(0,0)-qint) : (psxi(0,0)+qint) )                ; get lon

 
 d2r = 4.d0*atan(1.d0)/180.d0 
 r = new ( (/2*qint+1/) , double )
       do i = 0,qint-1
          r(i) = -a/1000.d0*(acos(sin(d2r*lat_x(qint))*sin(d2r*lat_x(qint))+cos(d2r*lat_x(qint))*cos(d2r*lat_x(qint))*cos(d2r*lon_x(qint)-d2r*lon_x(i))))
       end do
       do i = qint,2*qint
          r(i) =  a/1000.d0*(acos(sin(d2r*lat_x(qint))*sin(d2r*lat_x(qint))+cos(d2r*lat_x(qint))*cos(d2r*lat_x(qint))*cos(d2r*lon_x(qint)-d2r*lon_x(i))))
       end do

 PS = PS1(time,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 
 Pm = pres_hybrid_ccm(PS(:,:),p00,hyam,hybm)

 Ti = new ( (/dimsizes(lev)+1,dimsizes(lat_x),dimsizes(lon_x)/) , double )
 T  = t(time,:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 Q  = q(time,:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 
       do k = 1,(dimsizes(lev)-1)
          Ti(k,:,:) = (T(k,:,:)*(1.d0+constq*Q(k,:,:))+T(k-1,:,:)*(1.d0+constq*Q(k,:,:)))/2.d0
       end do
       Ti(dimsizes(lev),:,:) = Ts*((1.d0+constq*Q(dimsizes(lev)-1,:,:)))

 z = new ( (/dimsizes(lev),dimsizes(lat_x),dimsizes(lon_x)/) , double )      
       z(dimsizes(lev)-1,:,:) = -(Rd/(g*1000.d0))*(Ti(dimsizes(lev),:,:)+T(dimsizes(lev)-1,:,:)*(1.d0+constq*Q(dimsizes(lev)-1,:,:)))/2.d0*log(Pm(dimsizes(lev)-1,:,:)/PS(:,:))
       do k =(dimsizes(lev)-2),1,1
          z(k,:,:) =z(k+1,:,:)-(Rd/(g*1000.d0))*Ti(k+1,:,:)*log(Pm(k,:,:)/Pm(k+1,:,:))
       end do
 z(0,:,:) = z(1,:,:)+1.d0

 U  = u(time,:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))           ; read in data (time,lev,lat,lon)
 V  = v(time,:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))           ; read in data (time,lev,lat,lon)
  
 ;U  = in1->U(time,:,:,:)         ; read in data (time,lat,lon)
 ;V  = in1->V(time,:,:,:)         ; read in data (time,lat,lon)

 M = sqrt(U^2.d0+V^2.d0)
 
do cxloopindx = 0,1
 
if (cxloopindx .eq. 1) then

M = T
Tref = T(:,qint/2,0)
 
do j = 0,dimsizes(lat_x)-1
do k = 0,dimsizes(lon_x)-1
   M(:,j,k) = T(:,j,k) - Tref(:)
end do
end do

end if


 
; UU = u(time,level,:,:)
; VV = v(time,level,:,:)
; Pt = in1->PRECT(time,:,:)
; prect = Pt*3.6d6
 
; latdum = in1->lat
; londum = in1->lon
 
; totwind = sqrt(UU^2.d0+VV^2.d0)
 
; totwind@units = "m/s"
; totwind!0 = "lat"
; totwind!1 = "lon"
; totwind&lat = latdum
; totwind&lon = londum
; totwind@long_name = "Wind speed"
 
; prect@units = "mm/hr"
; prect!0 = "lat"
; prect!1 = "lon"
; prect&lat = latdum
; prect&lon = londum
; prect@long_name = "Total Precipitation"
  
 M!0 = "lev"
 M!1 = "lat"
 M!2 = "lon"
 M&lev = lev
 M&lat = lat_x
 M&lon = lon_x
 
 z!0 = "lev"
 z!1 = "lat"
 z!2 = "lon"
 z&lev = lev
 z&lat = lat_x
 z&lon = lon_x
 
 znew = (/ 16.d0, 15.d0, 14.d0, 13.d0, 12.d0, 11.d0, 10.d0, 9.d0, 8.d0, 7.d0, 6.d0, 5.d0, 4.d0, 3.d0, 2.d0, 1.5d0, 1.d0, .5d0, .25d0, .2d0, .15d0, 0.1d0/)
 zint = z(lat|:,lon|:,lev|:)
 Mint = M(lat|:,lon|:,lev|:)

 Mtest = linint1(zint, Mint, False, znew, 0)
  
 znew@units = "km"
 Mtest!2 = "znew"
 Mtest!0 = "lat"
 Mtest!1 = "lon"
 Mtest&znew = znew
 Mtest&lat = lat_x
 Mtest&lon = lon_x

 Mn = Mtest(znew|:,lat|:,lon|:) 

 Mn@units = "m/s"
 Mn!0 = "znew"
 Mn!1 = "lat"
 Mn!2 = "lon"
 Mn&znew = znew
 Mn&lat = lat_x
 Mn&lon = lon_x
  
 Ma  = (/Mn(:,qint,:)/)  

 r(qint) = 0.d0
 znew@units = "km"
 r@units = "km"
 Ma@units = "m/s"
 Ma!0 = "znew"
 Ma!1 = "r"
 Ma&znew = znew
 Ma&r   = r
 
if (cxloopindx .eq. 0) then
 Mwind = Ma
 delete(Ma)
end if

end do

 plev = dimsizes(znew)-pcount
 



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

	res_p@gsLineThicknessF = 1.0
	res_p@gsLineColor   = "black"

	resmain = True
	resmain@tiMainString = ""

	resmain@gsnDraw = False
	resmain@gsnFrame = False
	
	resmain@lbLabelBarOn         = True              ; turn off indiv. label bars
	resmain@lbBoxLinesOn         = False
;	resmain@lbOrientation = "vertical"
  
    resmain@cnFillOn		  = True

  resmain@gsnAddCyclic = False
  
 resmain@trYMaxF      = psminlat + 4
 resmain@trYMinF      = psminlat - 4
 resmain@trXMaxF      = psminlon + 4
 resmain@trXMinF      = psminlon - 4
 
  resmain@tmXBMode = "Explicit"
  resmain@tmXBValues = (/75,78,81,84,87/)
  resmain@tmXBLabels = (/"75E","78E","81E","84E","87E"/)
  resmain@tmXBMinorValues = (/74,75,76,77,78,79,80,81,82,83,84,85/)

  resmain@tmYLMode = "Explicit"
  resmain@tmYLValues = (/12,15,18,21,24,27/)
  resmain@tmYLLabels = (/"12N","15N","18N","21N","24N","27N"/)
  resmain@tmYLMinorValues = (/12,13,14,15,16,17,18,19,20,21,22,23,24/)
  
  resmain@cnLinesOn   = False		   				; turn off the contour lines
  
   resmain@vpWidthF     = 1
 resmain@vpHeightF    = 1

resprecip = resmain
reswind = resmain
 
; PRECIP

; WIND

whichrainplot = 1 ; 0 = rain rate, 1 = dbz


 ;BlAqGrYeOrReVi200
; gsn_define_colormap(wks,"cb_rainbow")          ; choose colormap

 
if whichrainplot .eq. 0 then
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
end if

if whichrainplot .eq. 1 then
  gsn_merge_colormaps(wks,"BlAqGrYeOrReVi200","rainsnowradar")
end if
 
   
 
 
 
 reswind@cnLineLabelsOn       = False             ; turn off line labels
 reswind@gsnSpreadColors      = True              ; use full colormap
 reswind@gsnSpreadColorStart = 2
 reswind@gsnSpreadColorEnd = 201 
 reswind@lbLabelStride        = 4
 reswind@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 reswind@cnLevelSpacingF      =  2.5                ;
 reswind@cnMinLevelValF       =  0.0           ;
 reswind@cnMaxLevelValF       =  80.0 ; Use 80.0 -> 60 for this


;res2@tmXBLabelFontHeightF = 0.02
;res2@tmYLLabelFontHeightF = 0.02

;res2@tiXAxisFontHeightF = 0.02
;res2@tiYAxisFontHeightF = 0.02

plot2(0) = gsn_csm_contour(wks,wind(time,level,:,:),reswind)



if whichrainplot .eq. 0 then
; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
 resprecip@cnLevelSelectionMode = "ExplicitLevels"
 resprecip@cnLineLabelsOn       = False             ; turn off line labels
 resprecip@gsnSpreadColors      = True              ; use full colormap
 resprecip@gsnSpreadColorStart = 2
 resprecip@gsnSpreadColorEnd = 201 
 resprecip@lbLabelStride        = 3
 resprecip@cnInfoLabelOn        = False             ; turn off info label bar
 ;res2@cnLevels                =(/0.02, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
; resprecip@cnLevels                =(/0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80./)
; resprecip@cnLevels                =(/0.02, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
 resprecip@cnLevels                =(/0.002, 0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
 	plot2(1) = gsn_csm_contour(wks,temp(:,:),resprecip)
end if

if whichrainplot .eq. 1 then
   resprecip@gsnSpreadColors      = False              ; use full colormap
 resprecip@cnFillColors = (/1,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232/)
  resprecip@cnLevelSelectionMode = "ExplicitLevels"                      ; set explicit contour levels
  resprecip@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/) ; set levels
; resprecip@gsnSpreadColors      = True              ; use full colormap
; resprecip@gsnSpreadColorStart = 218
; resprecip@gsnSpreadColorEnd = 232 
   resprecip@lbLabelStride        = 3
     resprecip@tiMainString = ""
  resprecip@gsnLeftString = "Simulated Reflectivity"
  resprecip@gsnRightString = "dBZ"
	plot2(1) = gsn_csm_contour(wks,dbz(:,:),resprecip)
end if

	

;************************************************
; Draw HOMME grid on top of plot
;************************************************

	xlon = new ( (/5/), "double")
	xlat = new ( (/5/), "double")
	
	j1 = ispan(0,3,1)
	j2 = (j1+1)%4
	
		dum0 = new(nelem,graphic)
		dum1 = new(nelem,graphic)

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

;if((xlat(0) .gt. resmain@trYMinF - 10) .and. (xlat(0) .lt. resmain@trYMaxF + 10) .and. (xlon(0) .gt. resmain@trXMinF - 10) .and. (xlat(0) .lt. resmain@trXMaxF + 10)) then
;		dum0(i) = gsn_add_polyline(wks,plot2(0),xlon,xlat,res_p)
;		dum1(i) = gsn_add_polyline(wks,plot2(1),xlon,xlat,res_p)
;end if

	end do

	system("/bin/rm -f "+gridfile+".nc")





 cxmain                      = True              ; turn on contour resources
 cxmain@gsnDraw              = False             ; don't draw plot
 cxmain@gsnFrame             = False             ; don't advance frame

 cxmain@cnFillOn             = True              ; turn on color
 cxmain@cnLinesOn            = False             ; turn off contour lines
 cxmain@cnLineLabelsOn       = False             ; turn off line labels
 cxmain@gsnSpreadColors      = True              ; use full colormap
  cxmain@gsnSpreadColorStart = 2
 cxmain@gsnSpreadColorEnd = 201
 cxmain@lbLabelBarOn         = True              ; turn off indiv. label bars
; cxmain@lbOrientation = "vertical"
 cxmain@lbBoxLinesOn         = False
 cxmain@cnInfoLabelOn        = False             ; turn off info label bar
 
; cxmain@pmLabelBarOrthogonalPosF = .05           ; move whole thing down
 
  cxmain@vpWidthF     = 1
 cxmain@vpHeightF    = 1

 cxmain@gsnYAxisIrregular2Linear  = True 

 cxmain@trXMinF      = -350
 cxmain@trXMaxF      = 350
 
; cnres1@vpYF = 0.45   ; Change Y location of plot.
 

    
 cxmain@lbTitleFontHeightF= .045

;cxmain@tiXAxisFontHeightF = 0.025
 cxmain@tiYAxisFontHeightF = 0.045
 

 cxwind = cxmain
 cxtemp = cxmain
 
 cxwind@cnLevelSelectionMode = "manualLevels"    ; set contour intervals
 cxwind@cnLevelSpacingF      =  2.5                ;
 cxwind@cnMinLevelValF       =  0.0           ;
 cxwind@cnMaxLevelValF       =  80.0 ;
 cxwind@lbLabelStride              = 4 
 cxwind@gsnLeftString = "Wind speed"
 cxwind@gsnRightString = "m/s"
; cxwind@tiXAxisString        = "Radius (km)"
 cxwind@tiYAxisString        = "Height (km)"
 cxwind@lbTitleString    = "Radius (km)"

 cxtemp@cnLevelSelectionMode = "manualLevels"    ; set contour intervals
 cxtemp@cnLevelSpacingF      =  1                ;
; cxtemp@cnMinLevelValF       =  -4           ;
; cxtemp@cnMaxLevelValF       =  14 ;
  cxtemp@cnMinLevelValF       =  -2           ;
 cxtemp@cnMaxLevelValF       =  16 ;
 cxtemp@lbLabelStride              = 2 
 cxtemp@gsnLeftString = "Temp. anomaly"
 cxtemp@gsnRightString = "K"
; cxtemp@tiXAxisString        = "Radius (km)"
 cxtemp@lbTitleString    = "Radius (km)"




 plot2(2) = gsn_csm_contour(wks,Mwind(:,:),cxwind)
 plot2(3) = gsn_csm_contour(wks,Ma(:,:),cxtemp)









  resP                     = True                ; modify the panel plot
  
  gsn_panel(wks,plot2,(/2,2/),resP)
  
end do
	
;************************************************


end
