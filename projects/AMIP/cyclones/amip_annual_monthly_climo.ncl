;========================================================
; AMIP Histogram by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
;========================================================
begin

datatoplot = 1 ; 0 = ibTracs, 1 = CAM-SE
factor = 0.9
domask = 0 ; 0 = true, 1 = false
maskbasin = 2
gridsize = 1.0
countCut = 33 ;33 for hurricane
numyears = 23

  ; 1 = ATL
  ; 2 = EPAC
  ; 3 = CPAC
  ; 4 = WPAC
  ; 5 = NIO
  ; 6 = SIO
  ; 7 = SPAC
  ; 8 = SATL
  
; ==== CREATE GRID

if (datatoplot .eq. 0) then
  latS =    -90
  latN =   90
  lonW = -180
  lonE =    180
else if (datatoplot .eq. 1) then
  latS =    -90
  latN =   90
  lonW = 0
  lonE =    360
else
end if
end if

tcMask = mask_tc(0,-2,-2,gridsize,toint(lonE))

traj_filename = "/glade/p/work/zarzycki/AMIP_TC_stats/outfile.txt"
traj_ncols = numAsciiCol(traj_filename)

; Given the # of columns, we can use readAsciiTable to read this file.
traj_data = readAsciiTable(traj_filename,traj_ncols,"float",0)

traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows

print("'" + traj_filename + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
        
stormid = traj_data(:,0)
year = traj_data(:,1)
month = toint(traj_data(:,2))
day = traj_data(:,3)
hour = traj_data(:,4)
startlat = traj_data(:,5)
startlon = traj_data(:,6)
maxwind = traj_data(:,7)
minpres = traj_data(:,8)

numstorms = toint(max(stormid))
months = new(12,integer)
monthsInd = ispan(1,12,1)
months(:) = 0

if (domask .eq. 0)
  do i = 0,numstorms-1
        if (tcMask({startlat(i)},{startlon(i)}) .ne. maskbasin)
          month(i) = month@_FillValue
          maxwind(i) = maxwind@_FillValue
        end if
  end do
end if

do i = 0,11
  months(i) = num(month.eq.(i+1))
end do

print(months)

; ======= PLOTTING STUFF ===========================

wks   = gsn_open_wks ("x11","xy")                ; open workstation
res                  = True                     ; plot mods desired
res@tiMainString     = "Basic XY plot"          ; add title
plot  = gsn_csm_xy (wks,monthsInd,tofloat(months)/numyears,res) ; create plot


end