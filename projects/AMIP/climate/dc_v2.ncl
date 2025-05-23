load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;==== INPUT DATA ============================================

case_desc = getenv("case_desc")
casenames = getenv("CASENAME")
dir_stub = getenv("WKDIR")
filename = getenv("filename")
;fincl = getenv("fincl")
ver = getenv("ver")
file_obs_DJF = getenv("file_obs_DJF")
file_obs_JJA = getenv("file_obs_JJA")
start_year = stringtodouble(getenv("firstyr_diurnal"))
end_year = stringtodouble(getenv("lastyr_diurnal"))
vars = (/"PRECT","TRIMM"/)
slatlim = -90.
nlatlim = 90.
;this_year = stringtodouble(getenv("year"))
plot_range = (/0,20./)
plot_mult = 1000*86400.

;cam_year0 = stringtodouble(getenv("base_year"))
tspd = 24
dtspd = 24d0
cam_time_shift = -0.5

;============================================================
; Derived/constant variables.
;
; Data regions.
north = (/10., -5.,  2.,  42.,  0.,  -6./) 
south = (/0., -20., -2.,  34.,   -10.,   -12./)
west  = (/20., 295., 110., 255., 65., 160./)
east  = (/30., 310., 116., 265., 90., 180./)

ptitle = (/"Africa (20E,0) (30E,10N)","Tropical S. America (65W,20S) (50W,5S)","Borneo (110E,2S) (116E,2N)","N. American Plains (105W,34N) (95W,42N)","Indian Ocean (65E,10S) (90E,0)","Western Pacific ITCZ (160E,12S) (180E,6S)"/)

nregions = dimsizes(ptitle)
ncases = dimsizes(casenames)
nvars  = dimsizes(vars)
dpy  = 365.d0
days2june01 = 151.d0
days2december01 = 334.d0
jja_days = 92.d0

time_diurnal = ispan(0,tspd,3)
time_dc  = ispan(0,tspd,1)
time_3dc = ispan(-tspd,2*tspd-1,1)


;============================================================
; Up-front Graphics Stuff
;
plot = new(nregions,graphic)

res = True 
res@gsnFrame             = False
res@gsnDraw              = False  
res@tmYLLabelFontHeightF = 0.015
res@tmXBLabelFontHeightF = 0.015
res@tiXAxisString = "Local Hour"
res@tiXAxisFontHeightF = 0.018
res@tiYAxisFontHeightF = 0.018
res@trYMinF = plot_range(0)
res@trYMaxF = plot_range(1)
res@gsnLeftString = ""
res@gsnRightString = ""
res@txFontHeightF = 0.018
res@xyLineThicknesses = (/3.,3./) 
res@xyDashPatterns = (/0,0,0,0/)
res@xyLineColors = (/"red","black"/)

res@tmXTOn              = False
res@tmYROn              = False
res@tmXBOn              = True


; model output   
   f = addfile(filename,"r")

; TRIMM
   f_obs_DJF = addfile(file_obs_DJF,"r")
   f_obs_JJA = addfile(file_obs_JJA,"r")
   precip_TRIMM_DJF = f_obs_DJF->precip
   precip_TRIMM_JJA = f_obs_JJA->precip
   precip_TRIMM_DJF = lonFlip(precip_TRIMM_DJF)
   precip_TRIMM_JJA = lonFlip(precip_TRIMM_JJA)
   lon_TRIMM = precip_TRIMM_DJF&lon
   lat_TRIMM = precip_TRIMM_DJF&lat
   hour_TRIMM = f_obs_DJF->time
   nlons_TRIMM = dimsizes(lon_TRIMM)
   nlats_TRIMM = dimsizes(lat_TRIMM)
   pi = 4.d0*atan(1.d0)
   gwmask_TRIMM = cos(lat_TRIMM/180.d0*pi)
   gwmask_TRIMM!0 = "lat"
   gwmask_TRIMM&lat = lat_TRIMM

   TRIMM_DJF_dc     = new((/nlons_TRIMM,nlats_TRIMM,tspd/),"double")
   TRIMM_JJA_dc     = new((/nlons_TRIMM,nlats_TRIMM,tspd/),"double")

   do ilon = 0,nlons_TRIMM-1
      TRIMM_DJF_dc(ilon,:,:) = linint1(int2flt(hour_TRIMM), precip_TRIMM_DJF(lon|ilon,lat|:,time|:),True,fspan(0,tspd-1,tspd), 0) 
      TRIMM_JJA_dc(ilon,:,:) = linint1(int2flt(hour_TRIMM), precip_TRIMM_JJA(lon|ilon,lat|:,time|:),True,fspan(0,tspd-1,tspd), 0) 
   end do

   TRIMM_DJF_3dc    = new((/nlons_TRIMM,nlats_TRIMM,3*tspd/),"double")
   TRIMM_DJF_adc    = new((/nlons_TRIMM,nlats_TRIMM,tspd+1/),"double")
   TRIMM_JJA_3dc    = new((/nlons_TRIMM,nlats_TRIMM,3*tspd/),"double")
   TRIMM_JJA_adc    = new((/nlons_TRIMM,nlats_TRIMM,tspd+1/),"double")

   TRIMM_JJA_adc!0   = "lon"
   TRIMM_JJA_adc&lon = lon_TRIMM
   TRIMM_JJA_adc!1   = "lat"
   TRIMM_JJA_adc&lat = lat_TRIMM
   TRIMM_JJA_adc!2   = "time"
   TRIMM_JJA_adc&time = time_dc
   copy_VarCoords(TRIMM_JJA_adc(lon|:,lat|:,time|:),TRIMM_DJF_adc)

;Netcdf output file.
  fout_JJA = addfile(dir_stub+"/"+casenames+"_PRECT_JJA_adc.nc","c")
  fout_DJF = addfile(dir_stub+"/"+casenames+"_PRECT_DJF_adc.nc","c")

  fout_TRIMM_JJA = addfile(dir_stub+"/TRIMM_JJA_adc.nc","c")
  fout_TRIMM_DJF = addfile(dir_stub+"/TRIMM_DJF_adc.nc","c")

  lon     = f->lon
  lat     = f->lat
  nlats = dimsizes(lat)
  nlons = dimsizes(lon)
  if(isfilevar(f,"gw")) then
    gwmask = f->gw
  else
    slat = new((/nlats+1/),"double")
    gwmask = new((/nlats/),"double")
    gwmask!0 = "lat"
    gwmask&lat = lat
    slat(0) = -90.d0
    slat(nlats) = 90.d0
    do i=1,nlats-1
     slat(i) = (lat(i-1)+lat(i))/2.d0
    end do
    pi = 4.d0*atan(1.d0)
    do i=0,nlats-1
     gwmask(i) = sin(slat(i+1)/180.d0*pi)-sin(slat(i)/180.d0*pi)
    end do
    delete(slat)
  end if

;  gwmask  = f->gw
  time0 = f->time
  time0@calendar = "noleap"
  t_utc = ut_calendar(time0,0)
  ntime = dimsizes(time0)

  year = floattointeger(t_utc(:,0))
  month = floattointeger(t_utc(:,1))
  day = floattointeger(t_utc(:,2))
  hour = floattointeger(t_utc(:,3))
  
;  date = f->date

;  year = date/10000
;  month = (date-year*10000)/100
;  day = date - year*10000 - month*100

;  hour1  = time0-(year-cam_year0)*dpy
    
;  do n=0,ntime-1
;   if( month(n).eq.1 ) then
;     hour1(n) = hour1(n)-(day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.2 ) then
;     hour1(n) = hour1(n)-(31.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.3 ) then 
;     hour1(n) = hour1(n)-(59.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.4 ) then 
;     hour1(n) = hour1(n)-(90.d0+day(n)-1.d0)*1.d0 
;   end if
;   if( month(n).eq.5 ) then
;     hour1(n) = hour1(n)-(120.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.6 ) then
;     hour1(n) = hour1(n)-(151.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.7 ) then
;    hour1(n) = hour1(n)-(181.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.8 ) then 
;     hour1(n) = hour1(n)-(212.d0+day(n)-1.d0)*1.d0 
;   end if
;   if( month(n).eq.9 ) then
;     hour1(n) = hour1(n)-(243.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.10 ) then
;     hour1(n) = hour1(n)-(273.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.11 ) then 
;     hour1(n) = hour1(n)-(304.d0+day(n)-1.d0)*1.d0
;   end if
;   if( month(n).eq.12 ) then 
;     hour1(n) = hour1(n)-(334.d0+day(n)-1.d0)*1.d0
;   end if 
;  end do
  
;  hour = doubletointeger(floor(hour1*24.d0+0.1)-1)
;  do n=0,ntime-1
;   if( hour(n).lt.0 ) then
;    hour(n) = 23
;   end if
;  end do

;  delete(hour1)

  count_JJA = new((/tspd/),"double")
  count_DJF = new((/tspd/),"double")
  count_JJA = 0.d0
  count_DJF = 0.d0
  
  do n=0,ntime-1
   if( (month(n).eq.6).or.(month(n).eq.7).or.(month(n).eq.8) ) then
    count_JJA(hour(n)) = count_JJA(hour(n))+1.d0
   end if
   if( (month(n).eq.12).or.(month(n).eq.1).or.(month(n).eq.2) ) then
    count_DJF(hour(n)) = count_DJF(hour(n))+1.d0
   end if 
  end do

; Main arrays
  var_JJA_3hourly = new((/nlons,nlats,9/),"double")
  var_JJA_dc     = new((/nlons,nlats,tspd/),"double")
  var_JJA_3dc    = new((/nlons,nlats,3*tspd/),"double")
  var_JJA_adc    = new((/nlons,nlats,tspd+1/),"double")
  region_JJA_adc = new((/nvars,tspd+1/),"double")
  var_JJA_adc!0   = "lon"
  var_JJA_adc&lon = lon
  var_JJA_adc!1   = "lat"
  var_JJA_adc&lat = lat
  var_JJA_adc!2   = "time"
  var_JJA_adc&time = time_dc
  region_JJA_adc!0 = "variable_number"
  region_JJA_adc!1 = "time"
  region_JJA_adc&time = time_dc
;  master_JJA_adc = new((/nlons,nlats,tspd+1,nvars/),"double")
;  master_JJA_adc!0   = "lon"
;  master_JJA_adc&lon = lon
;  master_JJA_adc!1   = "lat"
;  master_JJA_adc&lat = lat
;  master_JJA_adc!2   = "time"
;  master_JJA_adc&time = time_dc 
;  master_JJA_adc!3   = "variable_number"
;  copy_VarCoords_2(master_JJA_adc(variable_number|:,time|:,lat|:,lon|:),region_JJA_adc)
;  copy_VarCoords_1(master_JJA_adc(lon|:,lat|:,time|:,variable_number|:),var_JJA_adc)

  var_DJF_3hourly = new((/nlons,nlats,9/),"double")
  var_DJF_dc     = new((/nlons,nlats,tspd/),"double")
  var_DJF_3dc    = new((/nlons,nlats,3*tspd/),"double")
  var_DJF_adc    = new((/nlons,nlats,tspd+1/),"double")
  region_DJF_adc = new((/nvars,tspd+1/),"double")
  var_DJF_adc!0   = "lon"
  var_DJF_adc&lon = lon
  var_DJF_adc!1   = "lat"
  var_DJF_adc&lat = lat
  var_DJF_adc!2   = "time"
  var_DJF_adc&time = time_dc
  region_DJF_adc!0 = "variable_number"
  region_DJF_adc!1 = "time"
  region_DJF_adc&time = time_dc
;  master_DJF_adc = new((/nlons,nlats,tspd+1,nvars/),"double")
;  master_DJF_adc!0   = "lon"
;  master_DJF_adc&lon = lon
;  master_DJF_adc!1   = "lat"
;  master_DJF_adc&lat = lat
;  master_DJF_adc!2   = "time"
;  master_DJF_adc&time = time_dc 
;  master_DJF_adc!3   = "variable_number"
;  copy_VarCoords_2(master_DJF_adc(variable_number|:,time|:,lat|:,lon|:),region_DJF_adc)
;  copy_VarCoords_1(master_DJF_adc(lon|:,lat|:,time|:,variable_number|:),var_DJF_adc)


;  do ivars = 0, nvars(0)-1
    ivars = 0

    print("  Processing variable -- "+vars(ivars))
    print("    Reading data off files")

    this_var = vars(ivars)
    var_plot = f->$this_var$
    var_plot@long_name = "Total precipitation rate" 
    var_plot@units = "mm/day"      
    res@tiYAxisString = "Total precipitation rate"+" ("+var_plot@units+")"
    
    print("    Done...")

; Select required time period and latitudes.
  
     
; Generate diurnal cycle everywhere

    print("    Generating diurnal cycle")
;    do idc=0,tspd-1
;      time_samps = ispan(idc,ntime-1,tspd)
;      var_dc(:,:,idc) = dim_avg_Wrap(var_plot(lon|:,lat|:,time|time_samps))
;    end do
 
    var_JJA_dc = 0.d0
    var_DJF_dc = 0.d0
    var_JJA_3hourly = 0.d0
    var_DJF_3hourly = 0.d0

    do n = 0,ntime-1
     if( (month(n).eq.6).or.(month(n).eq.7).or.(month(n).eq.8) ) then
      var_JJA_3hourly(:,:,hour(n)/3) = var_JJA_3hourly(:,:,hour(n)/3)+var_plot(lon|:,lat|:,time|n)/count_JJA(hour(n))
     end if
     if( (month(n).eq.12).or.(month(n).eq.1).or.(month(n).eq.2) ) then
      var_DJF_3hourly(:,:,hour(n)/3) = var_DJF_3hourly(:,:,hour(n)/3)+var_plot(lon|:,lat|:,time|n)/count_DJF(hour(n))
     end if
    end do

    var_JJA_3hourly(:,:,8) = var_JJA_3hourly(:,:,0)
    var_DJF_3hourly(:,:,8) = var_DJF_3hourly(:,:,0)

    do ilon = 0,nlons-1
    do ilat = 0,nlats-1
      var_DJF_dc(ilon,ilat,:) = linint1(fspan(0,tspd,9), var_DJF_3hourly(ilon,ilat,:),True,fspan(0,tspd-1,tspd), 0) 
      var_JJA_dc(ilon,ilat,:) = linint1(fspan(0,tspd,9), var_JJA_3hourly(ilon,ilat,:),True,fspan(0,tspd-1,tspd), 0)
   end do
   end do

; Stick repeat DC at start and endd of data and time axis ready for interpolation to correct phase.

    var_JJA_3dc(:,:,0:tspd-1)        =  var_JJA_dc(:,:,0:tspd-1)
    var_JJA_3dc(:,:,tspd:2*tspd-1)   =  var_JJA_dc(:,:,0:tspd-1)
    var_JJA_3dc(:,:,2*tspd:3*tspd-1) =  var_JJA_dc(:,:,0:tspd-1)

    var_DJF_3dc(:,:,0:tspd-1)        =  var_DJF_dc(:,:,0:tspd-1)
    var_DJF_3dc(:,:,tspd:2*tspd-1)   =  var_DJF_dc(:,:,0:tspd-1)
    var_DJF_3dc(:,:,2*tspd:3*tspd-1) =  var_DJF_dc(:,:,0:tspd-1)

    TRIMM_JJA_3dc(:,:,0:tspd-1)        =  TRIMM_JJA_dc(:,:,0:tspd-1)
    TRIMM_JJA_3dc(:,:,tspd:2*tspd-1)   =  TRIMM_JJA_dc(:,:,0:tspd-1)
    TRIMM_JJA_3dc(:,:,2*tspd:3*tspd-1) =  TRIMM_JJA_dc(:,:,0:tspd-1)

    TRIMM_DJF_3dc(:,:,0:tspd-1)        =  TRIMM_DJF_dc(:,:,0:tspd-1)
    TRIMM_DJF_3dc(:,:,tspd:2*tspd-1)   =  TRIMM_DJF_dc(:,:,0:tspd-1)
    TRIMM_DJF_3dc(:,:,2*tspd:3*tspd-1) =  TRIMM_DJF_dc(:,:,0:tspd-1)

; Adjust according to central longitude to find local noon (var_adc)

       do ilon=0,nlons-1

; Phase shift the time-axis - plus a 30 minute -ve shift due to the CAM time step (01=ave 00-01).
        t_shift_dc = fspan(0,tspd,tspd+1)-(tspd*lon(ilon)/360. + cam_time_shift)
;        t_shift_dc = fspan(0,tspd,tspd+1)

; Linear interpolate between GMT and local time at every latitude.

        var_JJA_adc(ilon,:,:) = linint1(int2flt(time_3dc), var_JJA_3dc(ilon,:,:),True, t_shift_dc, 0)  
        var_DJF_adc(ilon,:,:) = linint1(int2flt(time_3dc), var_DJF_3dc(ilon,:,:),True, t_shift_dc, 0)
;        copy_VarCoords_1(master_JJA_adc(lon|:,lat|:,time|:,variable_number|:),var_JJA_adc)
;        copy_VarCoords_1(master_DJF_adc(lon|:,lat|:,time|:,variable_number|:),var_DJF_adc)
    end do

    do ilon=0,nlons_TRIMM-1
       t_shift_dc = fspan(0,tspd,tspd+1)-(tspd*lon_TRIMM(ilon)/360.)
       TRIMM_JJA_adc(ilon,:,:) = linint1(int2flt(time_3dc), TRIMM_JJA_3dc(ilon,:,:),True, t_shift_dc, 0)
       TRIMM_DJF_adc(ilon,:,:) = linint1(int2flt(time_3dc), TRIMM_DJF_3dc(ilon,:,:),True, t_shift_dc, 0)
    end do

; Write out to a file?

    fout_JJA->$vars(0)$=var_JJA_adc(time|:,lat|:,lon|:)
    fout_DJF->$vars(0)$=var_DJF_adc(time|:,lat|:,lon|:)

    fout_TRIMM_JJA->$vars(0)$=TRIMM_JJA_adc(time|:,lat|:,lon|:)
    fout_TRIMM_DJF->$vars(0)$=TRIMM_DJF_adc(time|:,lat|:,lon|:)

; Write this data to the master array to allow more than one variable on the plots
 
;    master_JJA_adc(:,:,:,0) = var_JJA_adc
;    master_DJF_adc(:,:,:,0) = var_DJF_adc
;    master_JJA_adc(:,:,:,1) = var_JJA_adc
;    master_DJF_adc(:,:,:,1) = var_DJF_adc

    delete(var_plot) ; Done with this variable.
;  end do ; Variables

    

; Plot fields
  plotname1 = "prect_JJA_dc_regions"
  plotname2 = "prect_DJF_dc_regions"

  print ("  Plotting fields for this case")
  wks = gsn_open_wks("ps",plotname1)
  
  print("  Averaging and plotting ADC for specified regions")
  do ireg=0,nregions-1
    print("    "+ptitle(ireg))
; Average for this region over the ADC
    
    region_JJA_adc(0,:) = plot_mult*wgt_areaave_Wrap(var_JJA_adc(time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask({lat|south(ireg):north(ireg)}),1.,0) 
    region_JJA_adc(1,:) = wgt_areaave_Wrap(TRIMM_JJA_adc(time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask_TRIMM({lat|south(ireg):north(ireg)}),1.,0) 
;    region_JJA_adc = wgt_areaave_Wrap(master_JJA_adc(variable_number|:,time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask({south(ireg):north(ireg)}),1.,0) 
     print("    Plotting...")
;Plot
    res@gsnCenterString=ptitle(ireg)
    plot(ireg) = gsn_csm_xy(wks,region_JJA_adc&time,region_JJA_adc,res)                  ; create plot
    print(region_JJA_adc)
  end do
  print("    Done plotting...")
  
  pnlres                = True
  pnlres@gsnFrame       = False
  pnlres@gsnMaximize    = True
  pnlres@gsnPanelBottom = 0.18  ; Leave room for legend at the bottom.
  if( start_year.eq.end_year ) then
  pnlres@txString       = doubletointeger(start_year)+" JJA Diurnal cycle - "+case_desc
  else
  pnlres@txString       = doubletointeger(start_year)+" to "+doubletointeger(end_year)+" JJA Diurnal cycle - "+case_desc
  end if

  gsn_panel(wks,plot,(/3,2/),pnlres)

; Create common legend when there are multiple lines

  legend = create "Legend" legendClass wks 
    "vpXF"                     : 0.26                    ; orientation on page
    "vpYF"                     : 0.17
    "vpWidthF"                 : 0.5                     ; width
    "vpHeightF"                : 0.1                     ; height
    "lgPerimOn"                : True                  ; no perimeter
    "lgItemCount"              : nvars                       ; how many
    "lgLineLabelStrings"       : vars ; labels
    "lgLabelsOn"               : False                   ; no default lables
    "lgLineLabelFontHeightF"   : 0.015                   ; font height
    "lgDashIndexes"            : res@xyDashPatterns             ; line paters
    "lgLineThicknessF"         : res@xyLineThicknesses
    "lgLineColors"             : res@xyLineColors
    "lgMonoLineLabelFontColor" : True                    ; one label color
  end create

  draw (legend)
  frame(wks)

  wks = gsn_open_wks("ps",plotname2)
  
  print("  Averaging and plotting ADC for specified regions")
  do ireg=0,nregions-1
    print("    "+ptitle(ireg))
; Average for this region over the ADC

    region_DJF_adc(0,:) = plot_mult*wgt_areaave_Wrap(var_DJF_adc(time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask({lat|south(ireg):north(ireg)}),1.,0) 
    region_DJF_adc(1,:) = wgt_areaave_Wrap(TRIMM_DJF_adc(time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask_TRIMM({lat|south(ireg):north(ireg)}),1.,0) 
;    region_DJF_adc = wgt_areaave_Wrap(master_DJF_adc(variable_number|:,time|:,{lat|south(ireg):north(ireg)},{lon|west(ireg):east(ireg)}),gwmask({south(ireg):north(ireg)}),1.,0) 
     print("    Plotting...")
;Plot
    res@gsnCenterString=ptitle(ireg)
    plot(ireg) = gsn_csm_xy(wks,region_DJF_adc&time,region_DJF_adc,res)                  ; create plot
    print(region_DJF_adc)
  end do
  print("    Done plotting...")
  
  pnlres                = True
  pnlres@gsnFrame       = False
  pnlres@gsnMaximize    = True
  pnlres@gsnPanelBottom = 0.18  ; Leave room for legend at the bottom.
  if( start_year.eq.end_year ) then
  pnlres@txString       = doubletointeger(start_year)+" DJF Diurnal cycle - "+case_desc
  else
  pnlres@txString       = doubletointeger(start_year)+" to "+doubletointeger(end_year)+" DJF Diurnal cycle - "+case_desc
  end if

  gsn_panel(wks,plot,(/3,2/),pnlres)

; Create common legend when there are multiple lines

  legend = create "Legend" legendClass wks 
    "vpXF"                     : 0.26                    ; orientation on page
    "vpYF"                     : 0.17
    "vpWidthF"                 : 0.5                     ; width
    "vpHeightF"                : 0.1                     ; height
    "lgPerimOn"                : True                  ; no perimeter
    "lgItemCount"              : nvars                       ; how many
    "lgLineLabelStrings"       : vars ; labels
    "lgLabelsOn"               : False                   ; no default lables
    "lgLineLabelFontHeightF"   : 0.015                   ; font height
    "lgDashIndexes"            : res@xyDashPatterns             ; line paters
    "lgLineThicknessF"         : res@xyLineThicknesses
    "lgLineColors"             : res@xyLineColors
    "lgMonoLineLabelFontColor" : True                    ; one label color
  end create

  draw (legend)
  frame(wks)

  print("Done for -- "+casenames)


end
