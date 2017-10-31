;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_gpi.ncl"
;========================================================
begin

startyear = 1995
endyear = 1995
numyears = endyear-startyear+1

do z = 0,numyears-1

year = startyear+z

filedir = "/glade/scratch/zarzycki/GPI_reanal/"

rhfile = addfile(filedir+"rhum."+year+".nc","r")
ufile = addfile(filedir+"uwnd."+year+".nc","r")
vfile =  addfile(filedir+"vwnd."+year+".nc","r")
sstfile = addfile(filedir+"air.sig995."+year+".nc","r")
lndfile = addfile(filedir+"land.nc","r")

startday = 0
endday = 364

daysarray = ispan(startday,endday,1)

;startday = 273
;endday = 303

lev  = rhfile->level
;time = rhfile->time
lat = rhfile->lat
lon = rhfile->lon

nlat = dimsizes(lat)
nlon = dimsizes(lon)

SST = short2flt(sstfile->air(startday:endday,:,:))

RH600 = short2flt(rhfile->rhum(startday:endday,{600},:,:))

U200 = short2flt(ufile->uwnd(startday:endday,{200},:,:))
U850 = short2flt(ufile->uwnd(startday:endday,{850},:,:))

V200 = short2flt(vfile->vwnd(startday:endday,{200},:,:))
V850 = short2flt(vfile->vwnd(startday:endday,{850},:,:))

LAND = short2flt(lndfile->land)

GPI = V850

do i = startday,endday
  GPI(i,:,:) = calc_gpi(U850(i,:,:),V850(i,:,:),U200(i,:,:),V200(i,:,:),RH600(i,:,:),SST(i,:,:),lat,lon)
end do

LAND = 1. - LAND

do i = 0,endday-startday
  ;print("Correct "+i)
  GPI(i,:,:) = GPI(i,:,:) * LAND(0,:,:)
end do

; do i = 0,endday-startday
;       print("Correct "+i)
;   do j = 0,nlat-1
;     do k = 0,nlon-1
;       if (LAND(0,j,k) .eq. 0) then
;         GPI(i,j,k) = 0
;       end if
;       end do
;       end do
; end do

GPI_AVG = dim_avg_n_Wrap( GPI, 0 )

GPI_MAX = dim_max_n_Wrap( GPI, 0 )
;GPI(0,:,:) = TOTSHEAR(0,:,:)

;print(max(vr))
;print(min(vr))
;vr@long_name = "vorticity"
;vr@units     = "scaled"

; Create Monthly arrays
years = 1

jan = new((/years,31,nlat,nlon/),"float")
feb = new((/years,28,nlat,nlon/),"float")
mar = new((/years,31,nlat,nlon/),"float")
apr = new((/years,30,nlat,nlon/),"float")
may = new((/years,31,nlat,nlon/),"float")
jun = new((/years,30,nlat,nlon/),"float")
jul = new((/years,31,nlat,nlon/),"float")
aug = new((/years,31,nlat,nlon/),"float")
sep = new((/years,30,nlat,nlon/),"float")
oct = new((/years,31,nlat,nlon/),"float")
nov = new((/years,30,nlat,nlon/),"float")
dec = new((/years,31,nlat,nlon/),"float")

; Store data in monthly arrays

do i = 0,years-1
	scale = i*365
	do j = 1,31
		jan(i,j-1,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 32,59
		feb(i,j-32,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 60,90
		mar(i,j-60,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 91,120
		apr(i,j-91,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 121,151
		may(i,j-121,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 152,181
		jun(i,j-152,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 182,212
		jul(i,j-182,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 213,243
		aug(i,j-213,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 244,273
		sep(i,j-244,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 274,304
		oct(i,j-274,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 305,334
		nov(i,j-305,:,:) = GPI(j+scale-1,:,:)
	end do
	do j = 335,365
		dec(i,j-335,:,:) = GPI(j+scale-1,:,:)
	end do
end do

; Average days to create one monthly average T per year at each x,y
yravg = new((/12,nlat,nlon/),"float")

yravg(0,:,:) = dim_avg_n(jan(0,:,:,:),0)
yravg(1,:,:) = dim_avg_n(feb(0,:,:,:),0)
yravg(2,:,:) = dim_avg_n(mar(0,:,:,:),0)
yravg(3,:,:) = dim_avg_n(apr(0,:,:,:),0)
yravg(4,:,:) = dim_avg_n(may(0,:,:,:),0)
yravg(5,:,:) = dim_avg_n(jun(0,:,:,:),0)
yravg(6,:,:) = dim_avg_n(jul(0,:,:,:),0)
yravg(7,:,:) = dim_avg_n(aug(0,:,:,:),0)
yravg(8,:,:) = dim_avg_n(sep(0,:,:,:),0)
yravg(9,:,:) = dim_avg_n(oct(0,:,:,:),0)
yravg(10,:,:) = dim_avg_n(nov(0,:,:,:),0)
yravg(11,:,:) = dim_avg_n(dec(0,:,:,:),0)

yravg!0 = "time"
yravg!1 = "lat"
yravg!2 = "lon"

yravg&lat = lat
yravg&lon = lon

yravgmax = dim_max_n_Wrap( yravg, 0 )

if (z .eq. 0) then
  yravgmaxtot = new((/numyears,nlat,nlon/),"float")
end if

yravgmaxtot(z,:,:) = yravgmax

;Atl_GPI = GPI(:,{17.5:32.5},{260:280})
;Atl_GPI_time = dim_sum_n_Wrap(Atl_GPI,(/1,2/))

Atl_GPI = yravg(:,{17.5:32.5},{260:280})
Atl_GPI_time = dim_sum_n_Wrap(Atl_GPI,(/1,2/))

end do

yravgmaxtot_avg = dim_max_n_Wrap( yravgmaxtot, 0 )

;**************** PLOT

 plot_type  = "x11"   ; plot types: ps,x11
 plot_name  = "vorticity"
 wks = gsn_open_wks(plot_type,plot_name)

;----------- Global resources -----------------------------------------
  
  res                 = True
  res@cnFillOn		  = True
  res@cnLinesOn   = False
  
  res@mpMaxLatF                   = 35           ; choose subregion           
 res@mpMinLatF                   = -35
; res@mpMinLonF = -150. 
;  res@mpMaxLonF = -30.
;   res@mpMinLonF = 90. 
;  res@mpMaxLonF = 180. 
  
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 0
  res@cnMaxLevelValF        = 5
 res@cnLevelSpacingF       = .1      ; contour spacing
  
  res@gsnSpreadColors = True
  
;  gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap
  
;   plot = gsn_csm_xy(wks,daysarray,Atl_GPI_time,False)
   plot = gsn_csm_y(wks,Atl_GPI_time,False)
;  plot = gsn_csm_contour_map(wks,yravgmaxtot_avg,res)    
  
end
