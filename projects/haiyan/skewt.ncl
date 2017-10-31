;**************************************************
; skewt_4.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Drawing two raobs on the same Skew-T plot
;   - Customizing the background of a Skew-T plot
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl" 

 begin

f = addfile("/glade/u/home/zarzycki/work/apply-haiyan-perturb/haiyan_48_x8_INIC_filter.nc_NOTREAL_CAM_sfccorr.nc","r")

lat=f->lat
lon=f->lon
whatlat=lat
whatlon=lon
whatlat=10.
whatlon=120.

gcdist = gc_latlon(lat,lon,whatlat,whatlon,2,4)
ix = minind(gcdist)
  
PSL = f->PS(0,ix)
T  = f->T(0,::-1,ix)
Q  = f->Q(0,::-1,ix)
Z3  = f->Q(0,::-1,ix)
P0 = f->P0

hya  = f->hyam(::-1)
hyb  = f->hybm(::-1)

;PSL = PSL+400.

p = (hya*P0+hyb*PSL)/100.
tc   = T-273.15
rh   = relhum(T, Q, p*100.)
tdk  = dewtemp_trh(T,rh)
tdc  = tdk-273.15
z    = Z3
wspd = tdc
wdir = tdc
wspd = tdc@_FillValue
wdir = tdc@_FillValue

print(wspd)

;*************************
; create plot
;*************************
  wks  = gsn_open_wks ("pdf", "skewt")

; --- Create background skew-T and plot sounding----------------

  skewtOpts                 = True
  skewtOpts@DrawColAreaFill = True    ; default is False
  skewtOpts@tiMainString    = "ATS Rawindsonde: Multiple Soundings" 

  skewt_bkgd = skewT_BackGround (wks, skewtOpts)
  draw (skewt_bkgd)

  dataOpts                  = True     ; options describing data and ploting
  dataOpts@DrawFahrenheit   = False    ; default is True
  dataOpts@PrintZ           = True    ; do not print Z 
  dataOpts@ThermoInfo       = True    ; print thermodynamic info
  dataOpts@WspdWdir = False
  dataOpts@PlotWindH = False

;*****************************************************************
; First sounding
;*****************************************************************
  dataOpts@colTemperature   = "black"
  dataOpts@colDewPt         = dataOpts@colTemperature
  dataOpts@linePatternDewPt = 1
  skewt_data = skewT_PlotData   (wks, skewt_bkgd, p,tc,tdc,z \
                                    , wspd,wdir, dataOpts)
                                       
  draw (skewt_data)
  frame(wks)

 end
