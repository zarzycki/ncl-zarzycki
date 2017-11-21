load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/lib.percentiles.ncl"
;************************************************
begin

ibstyr=1980
ibenyr=2000

factor=1.0
ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"
ibfile = addfile(ibdir+ibfilename,"r")

topoFileName="/glade/u/home/zarzycki/work/cam_tools/hires-topo/2deg_cesm_topo_latlon.nc"
topoFile=addfile(topoFileName,"r")
topoLat=topoFile->lat
topoLon=topoFile->lon
topoTopo=topoFile->PHIS
topoTopo=topoTopo/9.81

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat_for_mapping(stix:enix,:)*.01
iblon = ibfile->lon_for_mapping(stix:enix,:)*.01
ibyear = toint(ibfile->season(stix:enix))
ibtype = toint(ibfile->nature_for_mapping(stix:enix,:))
ibwind = ibfile->source_wind(stix:enix,:,:)*.1/ms_to_kts
ibtime = ibfile->source_time(stix:enix,:)
ibnamechar = ibfile->name(stix:enix,:)
;ibname = conform(ibwind,ibnamesingle,0)

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

; Need to convert char to str for name
ibname = new(dimsizes(ibyear),"string")
do i = 0,dimsizes(ibyear)-1
  ibname(i)=oneDtostring(ibnamechar(i,:))
  ibname(i)=str_sub_str(ibname(i),",","")
end do
  
; Average over all centers -- for plotting, this is ok even if there
; are small discrepancies
ibwind_ = dim_avg_n_Wrap(ibwind,2)

; Convert to 1-D data structures
onedwind = ndtooned(ibwind_)
onedlat = ndtooned(iblat)
onedlon = ndtooned(iblon)
onedtype = ndtooned(ibtype)
;onedyear = ndtooned(conform_dims(dimsizes(iblat),ibyear,0))
onedtime = ndtooned(ibtime)
onedname = ndtooned(conform_dims(dimsizes(iblat),ibname,0))

ib_nrows = dimsizes(onedwind)

onedwind = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedwind,onedwind@_FillValue)
onedlat = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedlat,onedlat@_FillValue)
onedlon = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedlon,onedlon@_FillValue)
onedtime = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedtime,onedtime@_FillValue)
onedname = where(onedtime .ge. stDateIBUnits .and. onedtime .le. enDateIBUnits,onedname,onedname@_FillValue)

; Correct for non-standard times
onedwind = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedwind@_FillValue,onedwind)
onedlat = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedlat@_FillValue,onedlat)
onedlon = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedlon@_FillValue,onedlon)
onedtime = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedtime@_FillValue,onedtime)
onedname = where(mod(onedtime,0.25) .ge. 0.00001 .or. mod(onedtime,0.25) .le. -0.00001,onedname@_FillValue,onedname)

; Correct for wind
onedwind = where(onedwind .lt. ibcutwindArr(1),onedwind@_FillValue,onedwind)
onedlat = where(onedwind .lt. ibcutwindArr(1),onedlat@_FillValue,onedlat)
onedlon = where(onedwind .lt. ibcutwindArr(1),onedlon@_FillValue,onedlon)
onedtime = where(onedwind .lt. ibcutwindArr(1),onedtime@_FillValue,onedtime)
onedname = where(onedwind .lt. ibcutwindArr(1),onedname@_FillValue,onedname)

; Only choose tropical
onedwind = where(onedtype .ge. 2,onedwind@_FillValue,onedwind)
onedlat = where(onedtype .ge. 2,onedlat@_FillValue,onedlat)
onedlon = where(onedtype .ge. 2,onedlon@_FillValue,onedlon)
onedtime = where(onedtype .ge. 2,onedtime@_FillValue,onedtime)
onedname = where(onedtype .ge. 2,onedname@_FillValue,onedname)

onedtopo = onedwind
printVarSummary(onedwind)
printVarSummary(topoTopo)
do i = 0,dimsizes(onedwind)-1
  if (.not.ismissing(onedwind(i))) then
    thisLon=onedlon(i)+180.
    if (thisLon .ge. 360.) then
      thisLon = 359.5
    end if
    if (thisLon .le. 0.5) then
      thisLon = 0.5
    end if
    thisLat=onedlat(i)
    ;print(thisLat+" "+thisLon)
    onedtopo(i) = tofloat(topoTopo({thisLat},{thisLon}))
    ;print(onedtopo(i)+" ")
  end if
end do

opt = True
opt@PrintStat = True
statb = stat_dispersion(onedtopo, opt )

opt = True
opt@PrintStat = True
statb = stat_dispersion(abs(onedlat), opt )

val = percent_to_value(onedtopo,98.0)
print(val)

ap  = pdfx(onedtopo, 20, False)    ; specify 40 bins
nVar    = 1
nBin    = ap@nbins          ; retrieve the number of bins

xx      = new ( (/nVar, nBin/), typeof(ap))

xx(0,:) = ap@bin_center     ; assign appropriate "x" axis values

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap /)

wks  = gsn_open_wks ("x11","pdf")
res  = True
res@xyLineThicknesses        = (/2.0,2.0,2.0/)        
res@xyLineColors             = (/"blue","red","green"/)  
res@xyMonoDashPattern        = True              ; all solid 
res@tiYAxisString            = "PDF (%)"

res@gsnXYBarChart            = True              ; Create bar plot
res@gsnXYBarChartOutlineOnly = True

res@pmLegendDisplayMode    = "Always"            ; turn on legend
res@pmLegendSide           = "Top"               ; Change location of 
res@pmLegendParallelPosF   = .25                 ; move units right
res@pmLegendOrthogonalPosF = -0.4                ; move units down
res@pmLegendWidthF         = 0.125               ; Change width and
res@pmLegendHeightF        = 0.15                ; height of legend.
res@lgPerimOn              = True                ; turn off/on box around
res@lgLabelFontHeightF     = .015                ; label font height
res@xyExplicitLegendLabels = (/"AP"/)  ; create explicit labels

;  res@xyYStyle = "Log"

res@tiMainString           = "PDF: Three Distributions: 40 Bins"
plot = gsn_csm_xy (wks, xx, yy, res)



end
