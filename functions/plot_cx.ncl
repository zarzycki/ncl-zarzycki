function plot_cx(in1,m,q,type)

;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================

;========================================================
begin
;========================================================
; USER OPTIONS
;========================================================

 pcount = 4  ; 1 if aqua 4 is simple
 
 PS1 = in1->PS(:,:,:)           ; read in data (time,lat,lon)
 lev  = in1->lev
 time = in1->time
 hyam = in1->hyam
 hybm = in1->hybm

 timeset  = new ( (/3,1/) , integer )
 
 if type .ge. 2
 	timeset(0,0) = 1
 	timeset(1,0) = 5
 	timeset(2,0) = 10  
 else
	timeset(0,0) = 0
 	timeset(1,0) = 5
 	timeset(2,0) = 10  
 end if
  
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
 f     = 2.d0*omega*sin(10.d0*pi/180.d0)
  constq = 0.608d0

 Ts    = 302.15d0

;========================================================
; Create plot
;========================================================

  
 nmin = local_min(PS1(timeset(m,0),:,:), True, 0.0)
 wind = ind(nmin@minval.eq.min(nmin@minval))
 psmin = nmin@minval(wind)
 psxi  = nmin@xi(wind)
 psyi  = nmin@yi(wind)
 
 lat  = in1 ->lat((psyi(0,0)-q):(psyi(0,0)+q))                ; get lat
 lon  = in1->lon((psxi(0,0)-q):(psxi(0,0)+q))                ; get lon

 
 d2r = 4.d0*atan(1.d0)/180.d0 
 r = new ( (/2*q+1/) , double )
       do i = 0,q-1
          r(i) = -a/1000.d0*(acos(sin(d2r*lat(q))*sin(d2r*lat(q))+cos(d2r*lat(q))*cos(d2r*lat(q))*cos(d2r*lon(q)-d2r*lon(i))))
       end do
       do i = q,2*q
          r(i) =  a/1000.d0*(acos(sin(d2r*lat(q))*sin(d2r*lat(q))+cos(d2r*lat(q))*cos(d2r*lat(q))*cos(d2r*lon(q)-d2r*lon(i))))
       end do

 PS = in1->PS(timeset(m,0),(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))
 
 Pm = pres_hybrid_ccm(PS(:,:),p00,hyam,hybm)
 
 printVarSummary(Pm)
 
 Pnorm = Pm
 
 do i=0,dimsizes(lev)-1
 	do j=0,dimsizes(lat)-1
 		do k=0,dimsizes(lon)-1
 			if( Pm(i,j,k) .gt. 85000 ) then 
 				Pnorm(i,j,k) = 1
 			else 
				Pnorm(i,j,k) = 0
 			end if
 		end do
 	end do
 end do

 Ti = new ( (/dimsizes(lev)+1,dimsizes(lat),dimsizes(lon)/) , double )
 T  = in1->T(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))
 Q  = in1->Q(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))
 
       do k = 1,(dimsizes(lev)-1)
          Ti(k,:,:) = (T(k,:,:)*(1.d0+constq*Q(k,:,:))+T(k-1,:,:)*(1.d0+constq*Q(k,:,:)))/2.d0
       end do
       Ti(dimsizes(lev),:,:) = Ts*((1.d0+constq*Q(dimsizes(lev)-1,:,:)))

 z = new ( (/dimsizes(lev),dimsizes(lat),dimsizes(lon)/) , double )      
       z(dimsizes(lev)-1,:,:) = -(Rd/(g*1000.d0))*(Ti(dimsizes(lev),:,:)+T(dimsizes(lev)-1,:,:)*(1.d0+constq*Q(dimsizes(lev)-1,:,:)))/2.d0*log(Pm(dimsizes(lev)-1,:,:)/PS(:,:))
       do k =(dimsizes(lev)-2),1,1
          z(k,:,:) =z(k+1,:,:)-(Rd/(g*1000.d0))*Ti(k+1,:,:)*log(Pm(k,:,:)/Pm(k+1,:,:))
       end do
 z(0,:,:) = z(1,:,:)+1.d0
 
; ====================Q MOM FLUX=============================

if type .eq. 0

 QMOMFLX  = in1->QMOMFLX(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 ;V  = in1->V(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 
 QMOMFLXdummy = QMOMFLX
 
  do i=0,dimsizes(lev)-1
 	do j=0,dimsizes(lat)-1
 		do k=0,dimsizes(lon)-1
 			QMOMFLXdummy(i,j,k) = QMOMFLX(i,j,k)*Pnorm(i,j,k)
 		end do
 	end do
 end do
 
 M = QMOMFLXdummy*1000
 
 else
 end if
 
 ; ====================T MOM FLUX=============================
 
 if type .eq. 1

 TMOMFLX  = in1->TMOMFLX(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 V  = in1->V(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 
 TMOMFLXdummy = TMOMFLX
 
  do i=0,dimsizes(lev)-1
 	do j=0,dimsizes(lat)-1
 		do k=0,dimsizes(lon)-1
 			TMOMFLXdummy(i,j,k) = TMOMFLX(i,j,k)*Pnorm(i,j,k)
 		end do
 	end do
 end do
 
 M = TMOMFLXdummy
 
 else
 end if
 
 ; ====================U MOM FLUX=============================
 
 if type .eq. 2

 UMOMFLX  = in1->UMOMFLX(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 ;V  = in1->V(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 
 UMOMFLXdummy = UMOMFLX
 
  do i=0,dimsizes(lev)-1
 	do j=0,dimsizes(lat)-1
 		do k=0,dimsizes(lon)-1
 			UMOMFLXdummy(i,j,k) = UMOMFLX(i,j,k)*Pnorm(i,j,k)
 		end do
 	end do
 end do
 
 M = UMOMFLXdummy
 
 else
 end if
 
 ; ====================V MOM FLUX=============================
 
 if type .eq. 3

 VMOMFLX  = in1->VMOMFLX(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 ;V  = in1->V(timeset(m,0),:,(psyi(0,0)-q):(psyi(0,0)+q),(psxi(0,0)-q):(psxi(0,0)+q))           ; read in data (time,lev,lat,lon)
 
 VMOMFLXdummy = VMOMFLX
 
  do i=0,dimsizes(lev)-1
 	do j=0,dimsizes(lat)-1
 		do k=0,dimsizes(lon)-1
 			VMOMFLXdummy(i,j,k) = VMOMFLX(i,j,k)*Pnorm(i,j,k)
 		end do
 	end do
 end do
 
 M = VMOMFLXdummy
 
 else
 end if
 
  ; =================================================
  
 M!0 = "lev"
 M!1 = "lat"
 M!2 = "lon"
 M&lev = lev
 M&lat = lat
 M&lon = lon
 
 z!0 = "lev"
 z!1 = "lat"
 z!2 = "lon"
 z&lev = lev
 z&lat = lat
 z&lon = lon
 
 znew = (/ 16.d0, 15.d0, 14.d0, 13.d0, 12.d0, 11.d0, 10.d0, 9.d0, 8.d0, 7.d0, 6.d0, 5.d0, 4.d0, 3.d0, 2.d0, 1.5d0, 1.d0, .5d0, .25d0, .2d0, .15d0, 0.1d0/)
 zint = z(lat|:,lon|:,lev|:)
 Mint = M(lat|:,lon|:,lev|:)

 Mtest = linint1(zint, Mint, False, znew, 0)
  
 znew@units = "km"
 Mtest!2 = "znew"
 Mtest!0 = "lat"
 Mtest!1 = "lon"
 Mtest&znew = znew
 Mtest&lat = lat
 Mtest&lon = lon

 Mn = Mtest(znew|:,lat|:,lon|:) 

 Mn@units = "m/s"
 Mn!0 = "znew"
 Mn!1 = "lat"
 Mn!2 = "lon"
 Mn&znew = znew
 Mn&lat = lat
 Mn&lon = lon
  
 Ma  = (/Mn(:,q,:)/)  

 r(q) = 0.d0
 znew@units = "km"
 r@units = "km"
 Ma@units = "m/s"
 Ma!0 = "znew"
 Ma!1 = "r"
 Ma&znew = znew
 Ma&r   = r

 plev = dimsizes(znew)-pcount

return(Ma)

end
