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

startyear = 1992
endyear = 1998
datayear = 1948
startinx = (startyear - datayear)*12
endinx = (endyear - datayear)*12 - 1

filedir = "/glade/p/work/zarzycki/ncep_monthly/"

rhfile = addfile(filedir+"rhum.mon.mean.nc","r")
ufile = addfile(filedir+"uwnd.mon.mean.nc","r")
vfile =  addfile(filedir+"vwnd.mon.mean.nc","r")
sstfile = addfile(filedir+"air.sfc.mon.mean.nc","r")
lndfile = addfile(filedir+"land.nc","r")

horizstride = 1
;maskbasin = 4

lev  = rhfile->level
time = rhfile->time
lat = rhfile->lat(::-horizstride)
lon = rhfile->lon(::horizstride)

gridarea = calc_area(lat,lon)

nlat = dimsizes(lat)
nlon = dimsizes(lon)

SST = short2flt(sstfile->air(:,::-horizstride,::horizstride))

RH600 = short2flt(rhfile->rhum(:,{600},::-horizstride,::horizstride))

U200 = short2flt(ufile->uwnd(:,{200},::-horizstride,::horizstride))
U850 = short2flt(ufile->uwnd(:,{850},::-horizstride,::horizstride))

V200 = short2flt(vfile->vwnd(:,{200},::-horizstride,::horizstride))
V850 = short2flt(vfile->vwnd(:,{850},::-horizstride,::horizstride))

LAND = short2flt(lndfile->land)

printVarSummary(RH600)
printVarSummary(time)

; =============== CONVERT FROM HOURS SINCE TO UTC TIME ===================
month_abbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep", \
                    "Oct","Nov","Dec"/)
 ;
 ; Convert to UTC time.
 ;
   utc_date = ut_calendar(time, 0)
 ;
 ; Store return information into more meaningful variables.
 ;
   year   = tointeger(utc_date(:,0))    ; Convert to integer for
   month  = tointeger(utc_date(:,1))    ; use sprinti
   day    = tointeger(utc_date(:,2))
   hour   = tointeger(utc_date(:,3))
   minute = tointeger(utc_date(:,4))
   second = utc_date(:,5)
 ;
 ; Write out strings in the format "hhZ dd mmm yyyy".
 ;

   date_str = sprinti("%0.2iZ ", hour) + sprinti("%0.2i ", day) + \
              month + " "  + sprinti("%0.4i", year)
              

   print(date_str(startinx))
   print(date_str(endinx))

; =============== CONVERT FROM HOURS SINCE TO UTC TIME ===================


GPI = V850

do i = 0,dimsizes(time)-1
  print("Calculating GPI for "+date_str(i))
  GPI(i,:,:) = calc_gpi(U850(i,:,:),V850(i,:,:),U200(i,:,:),V200(i,:,:),RH600(i,:,:),SST(i,:,:),lat,lon)
end do

a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
lsdata = a->LSMASK
lsm = landsea_mask(lsdata,GPI&lat,GPI&lon)

; lsm is a 2D array, in order to use it in mask, we must conform it
; to the size of the 3D array "data". 
  GPI = mask(GPI,lsm.gt.0,False)

;tcMask_orig = mask_tc(0,-1,-1,2.5,360)
tcMask = mask_tc(1,GPI&lat,GPI&lon,1,360)

do maskbasin = 1,8

    maskGPI  =  mask(GPI, tcMask, maskbasin)
    maskarea  =  mask(gridarea, tcMask, maskbasin)
    copy_VarMeta(GPI,maskGPI)
    
    monGPIarray = new(dimsizes(time),float)
    do i = 0,dimsizes(time)-1
      maskGPI(i,:,:) = maskGPI(i,:,:) * tofloat(gridarea(:,:))
      monGPIarray(i) = sum(maskGPI(i,:,:))/sum(maskarea)
    end do
    
    lines = sprinti("%i", maskbasin) + "  " + \
            sprinti("%i", year) + "  " + \
            sprinti("%3.0i", month) + "  " + \
            sprintf("%E", monGPIarray) + "  " + \
            sprintf("%E", sum(maskarea))
    
    ;---Write to a file
      asciiwrite(maskbasin+"_ncep.txt",lines)

end do

dummy = systemfunc("cat *_ncep.txt > ncep_GPI.txt")
dummy = systemfunc("rm *_ncep.txt")
delete(dummy)
    


;wks   = gsn_open_wks ("x11","xy")                ; open workstation

; res                  = True                     ; plot mods desired
; res@tiMainString     = "Basic XY plot"          ; add title
 
;   res@trYMinF  = 0.0                  ; min value on y-axis
;  res@trYMaxF  =  3.0e+07                  ; max value on y-axis

; plot  = gsn_csm_y (wks,monGPIarray(startinx:endinx),res) ; create plot
 

; >> plot_type  = "x11"   ; plot types: ps,x11
; >> plot_name  = "vorticity"
; >> wks = gsn_open_wks(plot_type,plot_name)
; >>
; >>;----------- Global resources -----------------------------------------
; >>  
; >>  res                 = True
; >>  res@cnFillOn		  = True
; >>  res@cnLinesOn   = False
; >>  
; >>  res@mpMaxLatF                   = 35           ; choose subregion           
; >> res@mpMinLatF                   = -35
; >>; res@mpMinLonF = -150. 
; >>;  res@mpMaxLonF = -30.
; >>;   res@mpMinLonF = 90. 
; >>;  res@mpMaxLonF = 180. 
; >>  
; >>  res@cnLevelSelectionMode  = "ManualLevels"
; >>  res@cnMinLevelValF        = 0
; >>  res@cnMaxLevelValF        = 5
; >> res@cnLevelSpacingF       = .1      ; contour spacing
; >>  
; >>  res@gsnSpreadColors = True
; >>  
; >>;  gsn_define_colormap(wks,"BlWhRe")              ; choose colormap
; >>  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap
; >>  
; >>;   plot = gsn_csm_xy(wks,daysarray,Atl_GPI_time,False)
; >>;   plot = gsn_csm_y(wks,Atl_GPI_time,False)
; >>  plot = gsn_csm_contour_map(wks,maskGPI(startinx+9,:,:),res)    
  
end
