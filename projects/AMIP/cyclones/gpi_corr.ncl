;========================================================
; GPI correlations
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

  styr = 1981
  endyr = 2001
  numyrs = endyr-styr
  debug = 1 ; 0 no, 1 yes
  
  ncol = 5
;  ncep_data_full = readAsciiTable("ncep_GPI.txt", ncol, "float", 0)
  ncep_data_full = readAsciiTable("amip_ne30_GPI.txt", ncol, "float", 0)
  
  ncep_maskbasin = ncep_data_full(:,0)
;  ncep_year = ncep_data_full(:,1)
;  ncep_month = ncep_data(:,2)
;  ncep_gpi = ncep_data(:,3)
;  ncep_maskarea = ncep_data(:,4)
  
  amip_data_full = readAsciiTable("amip_refined_GPI.txt", ncol, "float", 0)
  
  amip_maskbasin = amip_data_full(:,0)
;  amip_year = amip_data_full(:,1)
;  amip_month = amip_data(:,2)
;  amip_gpi = amip_data(:,3)
;  amip_maskarea = amip_data(:,4)

  correl = new((/3,7/),float)
  dof = new(3,integer)
  
do choosebasin = 1,7

  ncep_data = ncep_data_full
  amip_data = amip_data_full

  do i = 0,dimsizes(ncep_maskbasin)-1
    if (ncep_data(i,0) .ne. choosebasin)
      ncep_data(i,:) = -999.
    end if
  end do
 
;  ncep_maskbasin = ncep_data(:,0)
  ncep_year = ncep_data(:,1)
  ncep_month = ncep_data(:,2)
  ncep_gpi = ncep_data(:,3)
  ncep_maskarea = ncep_data(:,4)
  
  if (debug .ne. 0)
  do i = 0,dimsizes(ncep_maskbasin)-1
    print(" "+ncep_data(i,0)+" "+ncep_data(i,1)+" "+ncep_data(i,2)+" "+ncep_data(i,3)+" "+ncep_data(i,4)+" ")
  end do
  end if
  
  do i = 0,dimsizes(amip_maskbasin)-1
    if (amip_maskbasin(i) .ne. choosebasin)
      amip_data(i,:) = -999.
    end if
  end do
 
;  amip_maskbasin = amip_data(:,0)
  amip_year = amip_data(:,1)
  amip_month = amip_data(:,2)
  amip_gpi = amip_data(:,3)
  amip_maskarea = amip_data(:,4)
  
  if (debug .ne. 0)
  do i = 0,dimsizes(amip_maskbasin)-1
    print(" "+amip_data(i,0)+" "+amip_data(i,1)+" "+amip_data(i,2)+" "+amip_data(i,3)+" "+amip_data(i,4)+" ")
  end do
  end if
  
  ncep_inx = 0
  year = ncep_year(ncep_inx)
   do while(year.ne.styr)
     ncep_inx=ncep_inx+1
     year = ncep_year(ncep_inx)
   end do
  amip_inx = 0
  year = amip_year(amip_inx)
   do while(year.ne.styr)
     amip_inx=amip_inx+1
     year = amip_year(amip_inx)
   end do
   
   ncep_enx = ncep_inx + (endyr-styr)*12 - 1
   amip_enx = amip_inx + (endyr-styr)*12 - 1
   
   if (debug .ne. 0)
       print("The year is "+ncep_year(ncep_enx)+" and month is: "+ncep_month(ncep_enx))
       print("The year is "+amip_year(amip_enx)+" and month is: "+amip_month(amip_enx))
   end if
   
   ncep_gpi_parse = ncep_gpi(ncep_inx:ncep_enx)
   amip_gpi_parse = amip_gpi(amip_inx:amip_enx)
   time_parse = ispan(ncep_inx,ncep_enx,1)
   
 ;ccr = escorc(amip_gpi_parse,ncep_gpi_parse)
 ;print(ccr)
 
 nummonths = ncep_enx-ncep_inx
 ncep_yr_avg = new(endyr-styr,"float")
 amip_yr_avg = new(endyr-styr,"float")
 ncep_sea_avg = new(endyr-styr,"float")
 amip_sea_avg = new(endyr-styr,"float")
 
 yearloopend = (numyrs-1)
 do i = 0,yearloopend
   ; Annual average GPI values
   ncep_yr_avg(i) = avg(ncep_gpi_parse(12*i:12*(i+1)-1))
   amip_yr_avg(i) = avg(amip_gpi_parse(12*i:12*(i+1)-1))
   ; Seasonal GPI values
   monind = ispan(-1,11,1)
   if (choosebasin .eq. 1) then ; Atlantic
     if (debug .ne. 0)
       print((12*i+monind(6)+" "+(12*i+monind(11))))
     end if
     ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(6)) : (12*(i)+monind(11)) ))
     amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(6)) : (12*(i)+monind(11)) ))
   else if (choosebasin .eq. 2) then ; EPAC
     ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(5)) : (12*(i)+monind(11)) ))
     amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(5)) : (12*(i)+monind(11)) ))
   else if (choosebasin .eq. 3) then ; CPAC
     ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(6)) : (12*(i)+monind(11)) ))
     amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(6)) : (12*(i)+monind(11)) ))
   else if (choosebasin .eq. 4) then ; WPAC
     ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(5)) : (12*(i)+monind(11)) ))
     amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(5)) : (12*(i)+monind(11)) ))
   else if (choosebasin .eq. 5) then ; NIO
     ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(4)) : (12*(i)+monind(12)) ))
     amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(4)) : (12*(i)+monind(12)) ))
   else if (choosebasin .eq. 6) then ; SIO
     if (i .eq. 0)
       ; first year
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(1)) : (12*(i)+monind(4)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(1)) : (12*(i)+monind(4)) ))
     else if (i .eq. yearloopend)
       ; last year
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(11)) : (12*(i)+monind(12)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(11)) : (12*(i)+monind(12)) ))
     else
       ; middle year
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(11)) : (12*(i+1)+monind(4)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(11)) : (12*(i+1)+monind(4)) ))
     end if
     end if
   else if (choosebasin .eq. 7) then ; SPAC
     if (i .eq. 0)
       ; first year, go from Jan-April
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(1)) : (12*(i)+monind(4)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(1)) : (12*(i)+monind(4)) ))
     else if (i .eq. yearloopend)
       ; last year, go from Nov-Dec
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(11)) : (12*(i)+monind(12)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(11)) : (12*(i)+monind(12)) ))
     else
       ; middle year, go from Nov of current i index to April of i+1 index
       ncep_sea_avg(i) = avg(ncep_gpi_parse( (12*i+monind(11)) : (12*(i+1)+monind(4)) ))
       amip_sea_avg(i) = avg(amip_gpi_parse( (12*i+monind(11)) : (12*(i+1)+monind(4)) ))
     end if
     end if
   else
     print("Hit a basin we are not using")
   end if
   end if
   end if
   end if
   end if
   end if
   end if
 end do

 correl(0,choosebasin-1) = escorc(ncep_gpi_parse,amip_gpi_parse)
 correl(1,choosebasin-1) = escorc(ncep_yr_avg,amip_yr_avg)
 correl(2,choosebasin-1) = escorc(ncep_sea_avg,amip_sea_avg)
 
 dof(0) = dimsizes(ncep_gpi_parse)
 dof(1) = dimsizes(ncep_yr_avg)
 dof(2) = dimsizes(ncep_sea_avg)

 
 delete([/ncep_data,ncep_year,ncep_month,ncep_gpi,ncep_maskarea,ncep_inx,ncep_enx/])
 delete([/amip_data,amip_year,amip_month,amip_gpi,amip_maskarea,amip_inx,amip_enx/])

 ;list_vars()
 
end do

print(dof)
print(correl)

   
;************************************************
; plotting parameters
;************************************************
 wks  = gsn_open_wks("x11","scatter")              ; specifies a ps plot
  plot = new(2,graphic) 
 
res                     = True                   ; plot mods desired
res@gsnMaximize         = True                   ; maximize plot in frame
  res@gsnDraw  = False                          ; don't draw
  res@gsnFrame = False       
  
res1 = res
 res1@xyMarkLineModes     = (/"Markers","Lines"/)  ; choose which have markers
 res1@xyMarkers           = 16                     ; choose type of marker 
 res1@xyMarkerColor       = "red"                  ; Marker color
 res1@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
 res1@xyDashPatterns      = 1                      ; solid line 
 res1@xyLineThicknesses   = (/1,2/)                ; set second line to 2

 res1@tiMainString        = "Scatter"  ; title
 res1@tiXAxisString = "AMIP"
 res1@tiYAxisString = "NCEP"

 ;plot(0)  = gsn_csm_xy (wks,amip_gpi_parse,ncep_gpi_parse,res1)        ; create plot
 plot(0)  = gsn_csm_xy (wks,amip_sea_avg,ncep_sea_avg,res1)        ; create plot

res2 = res
  res2@trYMaxF           = max(ncep_gpi_parse)+0.1*avg(ncep_gpi_parse)
  res2@trYMinF           = min(ncep_gpi_parse)-0.1*avg(ncep_gpi_parse)
res2@xyLineColors      = "blue"                   ; line color

res3 = res
  res3@trYMaxF           = max(amip_gpi_parse)+0.1*avg(amip_gpi_parse)
  res3@trYMinF           = min(amip_gpi_parse)-0.1*avg(amip_gpi_parse)
;  res3@trYMaxF           = res2@trYMaxF
;  res3@trYMinF           = res2@trYMinF
  res3@xyLineColors      = "red"


plot(1)  = gsn_csm_xy2(wks,time_parse,ncep_gpi_parse,amip_gpi_parse,res2,res3)

  gsn_panel(wks,plot,(/2,1/),False)             ; now draw as one plot


end
