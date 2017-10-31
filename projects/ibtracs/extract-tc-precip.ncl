;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"

;========================================================
begin

output_type="png"
basin="tropics"
cutwind=0.0
factor = 1.0

pres_thresh=910.
basinfilt = 1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

thefile="ibtracs-1979-2012-NATL_only.txt"
ncols = 10                    ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
traj_data = getTrajectories(thefile,ncols,maxLines,headerDelimStr,delimStr,isHeader)

lon = traj_data(:,1,:)
lat = traj_data(:,2,:)
wind = traj_data(:,4,:)*factor
pres = traj_data(:,3,:)/100.
yyyy=  traj_data(:,6,:)
mm= traj_data(:,7,:)
dd= traj_data(:,8,:)
hh= traj_data(:,9,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

;===========================================================================================



deltaDeg=2.5

loadedYear=-1

do ii = 0,nstorms-1
;do ii = 190,191

  thisYear=toint(yyyy(ii,0))

  if (thisYear .ne. loadedYear)
    if (isdefined("time"))
      delete(time)
    end if
    PRECTDIR="/glade/scratch/zarzycki/h1files/JRA/"+thisYear+"/"
    PRECTFILE="JRA.h1."+thisYear+".PRECT.nc"
    f = addfile(PRECTDIR+"/"+PRECTFILE,"r")
    time = f->time
    loadedYear=thisYear
  end if

  print("Storm #"+ii+" of "+(nstorms-1)+"    "+thisYear)
  do jj = 0,ntimes-1
    if(.not.ismissing(yyyy(ii,jj)) .and. yyyy(ii,jj) .eq. loadedYear)
      ;print(yyyy(ii,jj)+" "+mm(ii,jj)+" "+dd(ii,jj)+" "+hh(ii,jj))
      thisTime=cd_inv_calendar(toint(yyyy(ii,jj)),toint(mm(ii,jj)),toint(dd(ii,jj)),toint(hh(ii,jj)),0,0,time@units,0)
      minLat=lat(ii,jj)-deltaDeg
      maxLat=lat(ii,jj)+deltaDeg
      minLon=lon(ii,jj)-deltaDeg
      maxLon=lon(ii,jj)+deltaDeg

      PRECT=f->PRECT({thisTime},:,:)
      PRECT = PRECT * 141732. * 6.
      
      if (.not.isdefined("PRECT_SUM"))
        lat2D=conform(PRECT,PRECT&lat,0)
        lon2D=conform(PRECT,PRECT&lon,1)
        PRECT=where(lat2D .ge. minLat .and. lat2D .le. maxLat .and. lon2D .ge. minLon .and. lon2D .le. maxLon,PRECT,0.)
        PRECT_SUM=PRECT
      else
        PRECT=where(lat2D .ge. minLat .and. lat2D .le. maxLat .and. lon2D .ge. minLon .and. lon2D .le. maxLon,PRECT,0.)
        PRECT_SUM(:,:) = PRECT(:,:)+PRECT_SUM(:,:)
      end if



    end if
  end do
end do

a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
lsdata = a->LSMASK
lsm  = landsea_mask(lsdata,PRECT_SUM&lat,PRECT_SUM&lon)
PRECT_SUM = mask(PRECT_SUM,lsm.eq.0,False)
PRECT_SUM = mask(PRECT_SUM,lsm.ge.2,False)

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->PRECT_SUM  = PRECT_SUM 

end
