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

domask = 0 ; 0 = true, 1 = false
maskbasin = 1
grid = "ne30" ; Options are "ne30" and "refined"

numyears = 20
startyear = 1981
monGPIarray = new(12*numyears,"float")
yeararray = new(12*numyears,"integer")
monarray = new(12*numyears,"integer")
monstr = new(12,"string")

monstr(:) = (/ "01","02","03","04","05","06","07","08","09","10","11","12" /)

horizstride = 8
print("With horizstride = "+horizstride+" the effective resolution is: "+(0.25*horizstride)+" degrees")

tcMask = mask_tc(0,-2,-2,horizstride/4,360)

a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
lsdata = a->LSMASK

if (grid .eq. "refined") then
  filesdir = "/glade/scratch/zarzycki/AMIP_monthly/"
else if (grid .eq. "ne30") then
  filesdir = "/glade/scratch/zarzycki/ne30amip_monthly/"
else
  print("Incorrect grid specified")
  exit
end if
end if

do yearloop = 0,numyears-1
do monloop = 0,11

year = startyear+yearloop


h1file = addfile(filesdir+"monavg_h0."+year+"-"+monstr(monloop)+".nc","r")
h3file = addfile(filesdir+"monavg_h3."+year+"-"+monstr(monloop)+".nc","r")

lev  = h3file->lev
timeh3 = h3file->time
lat = h3file->lat(::horizstride)
lon = h3file->lon(::horizstride)



;SST = h1file->SST(:,::horizstride,::horizstride)
SST = h1file->TREFHT(:,::horizstride,::horizstride)

T = h3file->T(::4,{800:400},::horizstride,::horizstride)
Tlev = h3file->lev({800:400})
T600 = int2p_n_Wrap(Tlev,T,(/ 600. /),2,1)
;T850 = rm_single_dims(T850)
delete(T)
delete(Tlev)

Q = h3file->Q(::4,{800:400},::horizstride,::horizstride)
Qlev = h3file->lev({800:400})
Q600 = int2p_n_Wrap(Qlev,Q,(/ 600. /),2,1)
delete(Q)
delete(Qlev)

U = h3file->U(::4,{1000:100},::horizstride,::horizstride)
Ulev = h3file->lev({1000:100})
U200 = int2p_n_Wrap(Ulev,U,(/ 200. /),2,1)
U850 = int2p_n_Wrap(Ulev,U,(/ 850. /),2,1)
delete(U)
delete(Ulev)

V = h3file->V(::4,{1000:100},::horizstride,::horizstride)
Vlev = h3file->lev({1000:100})
V200 = int2p_n_Wrap(Vlev,V,(/ 200. /),2,1)
V850 = int2p_n_Wrap(Vlev,V,(/ 850. /),2,1)
delete(V)
delete(Vlev)

P600 = conform(T600,600.*100.,-1)
P600@_FillValue = 9.969209968386869e+36

RH600 = relhum(T600(:,:,:,:),Q600(:,:,:,:),P600(:,:,:,:))

gridarea = calc_area(lat,lon)

GPI = calc_gpi(U850(0,0,:,:),V850(0,0,:,:),U200(0,0,:,:),V200(0,0,:,:),RH600(0,0,:,:),SST(0,:,:),lat,lon)

delete([/U850,V850,U200,V200,RH600,SST,Q600,P600,T600/])

lsm = landsea_mask(lsdata,GPI&lat,GPI&lon)
; lsm is a 2D array, in order to use it in mask, we must conform it
; to the size of the 3D array "data". 
GPI = mask(GPI,lsm.gt.0,False)

maskGPI  =  mask(GPI, tcMask, maskbasin)
maskarea  =  mask(gridarea, tcMask, maskbasin)
copy_VarMeta(GPI,maskGPI)

maskGPI(:,:) = maskGPI(:,:) * tofloat(gridarea(:,:))

GPI_singval = tofloat(sum(maskGPI)/sum(maskarea))

print(year+" GPI for the "+monstr(monloop)+" is "+GPI_singval)


monGPIarray(yearloop*12+monloop) = GPI_singval
yeararray(yearloop*12+monloop) = year
monarray(yearloop*12+monloop) = monloop+1
maskareasum = sum(maskarea)



delete([/lev,lat,lon,timeh3,maskGPI,maskarea,GPI_singval,GPI/])

;list_vars()

end do
end do

lines = sprinti("%i", maskbasin) + "  " + \
        sprinti("%i", yeararray) + "  " + \
        sprinti("%3.0i", monarray) + "  " + \
        sprintf("%E", monGPIarray) + "  " + \
        sprintf("%E", maskareasum)

;---Write to a file
  asciiwrite(maskbasin+"_amip.txt",lines)

 wks   = gsn_open_wks ("x11","xy")                ; open workstation

 res                  = True                     ; plot mods desired
 res@tiMainString     = "Basic XY plot"          ; add title
 
;   res@trYMinF  = 0.0                  ; min value on y-axis
;  res@trYMaxF  =  3.0e+07                  ; max value on y-axis

 plot  = gsn_csm_y (wks,monGPIarray,res) ; create plot

; ;**************** PLOT
; 
;  plot_type  = "x11"   ; plot types: ps,x11
;  plot_name  = "vorticity"
;  wks = gsn_open_wks(plot_type,plot_name)
; 
; ;----------- Global resources -----------------------------------------
;   
;   res                 = True
;   res@cnFillOn		  = True
;   res@cnLinesOn   = False
;   
; ;  res@mpMaxLatF                   = 30           ; choose subregion           
; ;  res@mpMinLatF                   = 0
; ;  res@mpMinLonF = 250.
; ;  res@mpCenterLonF = 285.
; ;  res@mpMaxLonF = 320. 
;   
;   res@cnLevelSelectionMode  = "ManualLevels"
;   res@cnMinLevelValF        = 0
;   res@cnMaxLevelValF        = 10
;   res@cnLevelSpacingF       = 1      ; contour spacing
;   
;   res@gsnSpreadColors = True
;   
; ;  gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
;   gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap
; 
;   plot = gsn_csm_contour_map(wks,maskGPIavg(0,:,:),res)    
  
end
