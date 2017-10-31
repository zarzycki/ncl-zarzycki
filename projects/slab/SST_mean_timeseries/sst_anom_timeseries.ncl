load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

debug=True
out_type="pdf"

if(debug) then
  basin="WPAC"
  config="slab3"
end if


if(basin .eq. "NATL") then
  minlat=10.
  maxlat=20.
  minlon=280.
  maxlon=340.
  theColor="red"
else if (basin .eq. "EPAC") then
  minlat=10.
  maxlat=20.
  minlon=230.
  maxlon=265.
  theColor="darkgreen"
else if (basin .eq. "WPAC") then
  minlat=10.
  maxlat=25.
  minlon=120.
  maxlon=170.
  theColor="blue"
else
  print("what basin?")
  exit
end if
end if
end if

;10°N–26°N, 122°E–170°E

timeStride=4

;years=(/1201,1202,1203,1204,1205,1206,1207,1208,1209,1210,1211,1212,1213,1214,1215,1216,1217,1218,1219,1220,1221,1222,1223,1224,1225/)
years=(/1201,1202,1203,1204,1205,1206,1207,1208,1209,1210,1211,1212,1213,1214,1215,1216/)
;years=(/1201,1202/)

nyrs = dimsizes(years)

do i = 0,nyrs-1
print("Doing year: "+years(i))

fileDir="/glade/u/home/zarzycki/scratch/nhemi_30_x4_"+config+"/run/"+years(i)+"/"

all_files = systemfunc ("ls "+fileDir+"/nhemi_30_x4_"+config+".cam.h7.*.nc_regrid.nc | grep -v '"+years(i)+"-05-'")
fall      = addfiles (all_files, "r")

ListSetType (fall, "cat")
SST = fall[:]->SST(::timeStride,{minlat:maxlat},{minlon:maxlon})

if (i .eq. 0)
  time = fall[:]->time(::timeStride)
  time@units="days since 1001-05-01 00:00:00" ;
  ntim = dimsizes(time)
  timeMin=time(0)
  timeMax=time(ntim-1)
  ;SSTdims = dimsizes(SST)
  ;nlat = SSTdims(1)
  ;nlon = SSTdims(2)
  print("Generating data array")
  SST_timeseries = new((/nyrs+1,ntim/),"float")
  SST_timeseries!1="time"
  SST_timeseries&time=time
end if

SST_timeseries(i+1,:) = dim_avg_n_Wrap( SST(:,{minlat:maxlat},{minlon:maxlon}), (/1,2/))

delete([/all_files,fall,SST/])

end do

SST_timeseries(0,:) = dim_avg_n_Wrap(SST_timeseries(1:nyrs,:),0)

timeMeanSST=dim_avg_n_Wrap(SST_timeseries(0,:),0)

wks   = gsn_open_wks (out_type,"pdf/sstmeananom_"+config+"_"+basin)                ; open workstation
res                  = True                     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
res@xyLineColors = (/theColor/)
res@xyLineThicknesses = (/8.0/)

res@trYMinF=-1.4                   ; min value on y-axis
res@trYMaxF=1.4                ; max value on y-axis

res@trXMinF=timeMin
res@trXMaxF=timeMax

if (config .eq. "slab2") then
  res@tiMainString=basin+" - SLAB2"
else if (config .eq. "slab3") then
  res@tiMainString=basin+" - THERMO"
else
  res@tiMainString=basin+" - SLAB1"
end if
end if
res@tiXAxisString     = ""
res@tiYAxisString     = "SST (K)"

restick = True
restick@ttmFormat = "%d %c"
restick@ttmValues = (/(/1001,6,1,0,0,0/), \
                    (/1001,7,1,0,0,0/), \
                    (/1001,8,1,0,0,0/), \
                    (/1001,9,1,0,0,0/), \
                    (/1001,10,1,0,0,0/), \
                    (/1001,11,1,0,0,0/), \
                    (/1001,12,1,0,0,0/)/)
time_axis_labels(time,res,restick)

plot  = gsn_csm_xy(wks,time,SST_timeseries,res)

;lnid = gsn_add_polyline(wks,plot,(/-1000,1000/),(/0.,0./),False)

plot2  = gsn_csm_xy(wks,time,SST_timeseries(0,:),res)
overlay(plot,plot2)



txres = True        
txres@txFontColor=theColor
txres@txFontHeightF=0.03              
text = gsn_add_text(wks,plot,sprintf("%4.2f", timeMeanSST)+" K",175,-0.7,txres)

if (config .eq. "slab2") then
  if (basin .eq. "NATL") then
    panelStr="b."
  else if (basin .eq. "EPAC") then
    panelStr="d."
  else if (basin .eq. "WPAC") then
    panelStr="f."
  else
    panelStr="x."
  end if
  end if
  end if
else
  if (basin .eq. "NATL") then
    panelStr="a."
  else if (basin .eq. "EPAC") then
    panelStr="c."
  else if (basin .eq. "WPAC") then
    panelStr="e."
  else
    panelStr="x."
  end if
  end if
  end if
end if

paneltxres                       = True
paneltxres@txPerimOn             = True
paneltxres@txFontHeightF         = 0.05
amres_tr                  = True
amres_tr@amParallelPosF   =  0.48    ; This is the right edge of the plot.
amres_tr@amOrthogonalPosF = -0.48    ; This is the top edge of the plot.
amres_tr@amJust           = "TopRight"
paneltxres@txBackgroundFillColor = "White"
txid = gsn_create_text(wks, panelStr, paneltxres)
amid = gsn_add_annotation(plot, txid, amres_tr)

draw(plot)
frame(wks)

end
