load "~/ncl/functions/getTrajectoriesGeneric.ncl"

FILTRANGE=5.0

fdir="./"
f = addfile(fdir+"/"+infile,"w")
VORT850 = f->VORT850
OMEGA500 = f->OMEGA500
PRECT = f->PRECT
PRECC = f->PRECC
PRECL = f->PRECL
time = f->time

trajdir="/glade/u/home/zarzycki/tempest-scripts/hyperion/"
thefile="trajectories.txt.CHEY.VR28.NATL.REF.CAM5.4CLM5.0."+thisConfig

ncols := 10 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data = getTrajectoriesGeneric(trajdir+"/"+thefile,ncols,maxLines,"start","tab",True,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlon = where(xlon .gt. 180,xlon - 360.,xlon)

xlat  = traj_data(:,3,:)
xpres  = tofloat(traj_data(:,4,:))/100.
xwind  = traj_data(:,5,:)*0.85
xyear  = toint(traj_data(:,7,:))
xmonth  = toint(traj_data(:,8,:))
xday  = toint(traj_data(:,9,:))
xhour  = toint(traj_data(:,10,:))
timeunits=time@units
xzero=xhour
xzero=0
xtime = cd_inv_calendar(xyear,xmonth,xday,xhour,xzero,xzero,timeunits,0)


onedtime = ndtooned(xtime)
onedlat = ndtooned(xlat)
onedlon = ndtooned(xlon)

MASK = VORT850
MASK = 0
lat2d=conform(MASK,MASK&lat,1)
lon2d=conform(MASK,MASK&lon,2)

do ii = 0,dimsizes(time)-1
  thisTime = time(ii)
  matchedTimes := where(onedtime .eq. thisTime,onedtime,onedtime@_FillValue)
  if (.not. all(ismissing(matchedTimes))) then
    ix := ind(.not.ismissing(matchedTimes))
    foundlat := onedlat(ix)
    foundlon := onedlon(ix)
    do jj = 0,dimsizes(ix)-1
      MASK(ii,:,:)=where(gc_latlon(foundlat(jj),foundlon(jj),lat2d(ii,:,:),lon2d(ii,:,:),2,2).lt.FILTRANGE,1,MASK(ii,:,:))
    end do
  end if
end do

VORT850_MASK = VORT850
VORT850_MASKI = VORT850
VORT850_MASK = where(MASK.eq.0,VORT850_MASK@_FillValue,VORT850_MASK)
VORT850_MASKI = where(MASK.eq.1,VORT850_MASKI@_FillValue,VORT850_MASKI)

OMEGA500_MASK = OMEGA500
OMEGA500_MASKI = OMEGA500
OMEGA500_MASK = where(MASK.eq.0,OMEGA500_MASK@_FillValue,OMEGA500_MASK)
OMEGA500_MASKI = where(MASK.eq.1,OMEGA500_MASKI@_FillValue,OMEGA500_MASKI)

PRECT_MASK = PRECT
PRECT_MASKI = PRECT
PRECT_MASK = where(MASK.eq.0,PRECT_MASK@_FillValue,PRECT_MASK)
PRECT_MASKI = where(MASK.eq.1,PRECT_MASKI@_FillValue,PRECT_MASKI)

PRECC_MASK = PRECC
PRECC_MASKI = PRECC
PRECC_MASK = where(MASK.eq.0,PRECC_MASK@_FillValue,PRECC_MASK)
PRECC_MASKI = where(MASK.eq.1,PRECC_MASKI@_FillValue,PRECC_MASKI)

PRECL_MASK = PRECL
PRECL_MASKI = PRECL
PRECL_MASK = where(MASK.eq.0,PRECL_MASK@_FillValue,PRECL_MASK)
PRECL_MASKI = where(MASK.eq.1,PRECL_MASKI@_FillValue,PRECL_MASKI)

VORT850_MASK_F = VORT850_MASK
VORT850_MASKI_F = VORT850_MASKI
OMEGA500_MASK_F = OMEGA500_MASK
OMEGA500_MASKI_F = OMEGA500_MASKI
PRECT_MASK_F = PRECT_MASK
PRECT_MASKI_F = PRECT_MASKI
PRECC_MASK_F = PRECC_MASK
PRECC_MASKI_F = PRECC_MASKI
PRECL_MASK_F = PRECL_MASK
PRECL_MASKI_F = PRECL_MASKI
guess     = 1                ; use zonal means
is_cyclic = False             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( VORT850_MASK_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VORT850_MASKI_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( OMEGA500_MASK_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( OMEGA500_MASKI_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECT_MASK_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECT_MASKI_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECC_MASK_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECC_MASKI_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECL_MASK_F, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( PRECL_MASKI_F, is_cyclic, guess, nscan, eps, relc, opt)

f->MASK  = MASK         
f->VORT850_MASK  = VORT850_MASK         
f->VORT850_MASKI  = VORT850_MASKI      
f->VORT850_MASK_F  = VORT850_MASK_F         
f->VORT850_MASKI_F  = VORT850_MASKI_F    
f->OMEGA500_MASK  = OMEGA500_MASK         
f->OMEGA500_MASKI  = OMEGA500_MASKI
f->OMEGA500_MASK_F  = OMEGA500_MASK_F         
f->OMEGA500_MASKI_F  = OMEGA500_MASKI_F    
f->PRECT_MASK  = PRECT_MASK         
f->PRECT_MASKI  = PRECT_MASKI
f->PRECT_MASK_F  = PRECT_MASK_F         
f->PRECT_MASKI_F  = PRECT_MASKI_F    
f->PRECC_MASK  = PRECC_MASK         
f->PRECC_MASKI  = PRECC_MASKI
f->PRECC_MASK_F  = PRECC_MASK_F         
f->PRECC_MASKI_F  = PRECC_MASKI_F
f->PRECL_MASK  = PRECL_MASK         
f->PRECL_MASKI  = PRECL_MASKI
f->PRECL_MASK_F  = PRECL_MASK_F         
f->PRECL_MASKI_F  = PRECL_MASKI_F    

exit