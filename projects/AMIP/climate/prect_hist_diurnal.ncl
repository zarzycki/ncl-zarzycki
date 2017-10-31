; FILE: prect_hist.ncl
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
print("prect_hist started")

vardata = getenv("VARDATA")
casename = getenv("CASENAME")
wkdir = getenv("WKDIR")
yr1 = getenv("firstyr_diurnal")
yr2 = getenv("lastyr_diurnal")
rgb = getenv("RGB")
landfrac_file = getenv("LANDFRAC_FILE")
landfrac_name_in_file = getenv("LANDFRAC_NAME")


firstyr = stringtointeger(yr1)
lastyr = stringtointeger(yr2)
ndays = (lastyr-firstyr+1)*365       ; no leap years

psfile = wkdir+"/VDIAG_"+casename+"/hourly/"+casename+"/"+casename+".PRECT.histogram"
wks = gsn_open_wks("ps",psfile)
print("prect_hist planning to write to "+psfile)

cmap = RGBtoCmap(rgb+"/redyellowblue.rgb")
gsn_define_colormap(wks,cmap)
plot = new(3,graphic)
res = True
res@gsnFrame = False
res@gsnDraw = False
res@gsnHistogramMinMaxBinsOn = True
res@gsnHistogramComputePercentages = True
res@gsnHistogramComputePercentagesNoMissing = True
res@gsnHistogramClassIntervals =(/0.,0.,.01,.1,1.,5.,10.,15.,20.,25.,30.,40./)
res@tmXBLabelFontHeightF = 0.018
res@tmYLLabelFontHeightF = 0.025
res@tiXAxisString = "Precipitation (mm/day)"
res@tiYAxisString = "Number of Grid Points"
res@tiXAxisFontHeightF = 0.025
res@tiYAxisFontHeightF = 0.025
res@tiMainFontHeightF = 0.022
res@tmYLFormat = "0@*+^se"

pan = True
pan@txString = casename+" Daily Data ("+yr1+"-"+yr2+")"
pan@txFontHeightF = 0.015
pan@gsnMaximize = True
pan@gsnPaperOrientation = "portrait"
;--------------------------------------------------------------------
print("prect_hist opening "+wkdir+"/"+casename+".PRECT.daily.nc")
f = addfile(getenv("filename"),"r") 
date = f->date
maxdays = dimsizes(date)
if (ndays .gt. maxdays) then
  ndays = maxdays
end if
print("prect_hist using "+ndays+" days of data")
prect = f->PRECT(0:ndays-1,{-10:60},:)
lat = f->lat
lon = f->lon
nlat = dimsizes(lat)
nlon = dimsizes(lon)

print("prect_hist LANDFRAC_FILE = "+landfrac_file)
print("isvar(landfrac_file)     "+isvar("landfrac_file"))

if ( isvar("landfrac_name_in_file")) then
    landfrac_name = landfrac_name_in_file
else
    landfrac_name = "LANDFRAC"    ;try this
end if

if ( isvar("landfrac_file")) then  ; look for envvar setting
    f = addfile(landfrac_file,"r")
    temp = f->$landfrac_name$
    num_dims = dimsizes(temp)
    if( num_dims(0) .eq. 1 ) then
        landmask = temp(0,{-10:60},:)
    else
        landmask = temp({-10:60},:)
    end if
    delete(temp)
    delete(num_dims)
else
	if (nlat.eq.48 .and. nlon.eq.96) then  ; T31
  	   f = addfile(vardata+"/landmasks/T31_LANDFRAC.nc","r")
	     landmask = f->landfrac({-10:60},:)   
	end if
	if (nlat.eq.64 .and. nlon.eq.128) then  ; T42
	  f = addfile(vardata+"/landmasks/T42_LANDFRAC.nc","r")
	    landmask = f->landfrac({-10:60},:)   
	end if
	if (nlat.eq.128 .and. nlon.eq.256) then  ; T85
	  f = addfile(vardata+"/landmasks/T85_LANDFRAC.nc","r")
	  landmask = f->landfrac({-10:60},:)   
	end if
	if (nlat.eq.256 .and. nlon.eq.512) then  ; T170
 	  f = addfile(vardata+"/landmasks/T170_LANDFRAC.nc","r")
	  landmask = f->landfrac({-10:60},:)   
	end if
	if (nlat.eq.96 .and. nlon.eq.144) then  ; Finite Volume
	  f = addfile(vardata+"/landmasks/FV_LANDFRAC_1.9x2.5.nc","r")
	  temp = f->LANDFRAC
	  landmask = temp(0,{-10:60},:)  
	  delete(temp) 
	end if
end if


; stop if not found
if ( .not. isvar("landmask")) then
    print("ERROR: prect_hist.ncl does not know what landmask file to read")
    print("        for resolution nlat "+nlat+" nlon "+nlon)           
    exit
end if

print("prect succesfully read landmask for resolution nlat "+nlat+" nlon "+nlon)           

ocean = prect
ocean = mask(prect,landmask.lt.0.2,True)
next_ocn = ndtooned(ocean(:,{30:60},:))
res@tiMainString = "Ocean Grid Points 30N-60N"
plot(0) = gsn_histogram(wks,next_ocn,res)
delete(ocean)
delete(next_ocn)

land = prect
land = mask(prect,landmask.gt.0.8,True)
next_lnd = ndtooned(land(:,{30:60},:))
res@tiMainString = "Land Grid Points 30N-60N"
plot(1) = gsn_histogram(wks,next_lnd,res)
delete(land)
delete(next_lnd)

;res@trYMaxF = 3.0e6
tropics = ndtooned(prect(:,{-10:10},:))
res@tiMainString = "All Grid Points 10S-10N"
plot(2) = gsn_histogram(wks,tropics,res)
delete(tropics)

gsn_panel(wks,plot,(/2,2/),pan)

print("prect_hist done")
end
