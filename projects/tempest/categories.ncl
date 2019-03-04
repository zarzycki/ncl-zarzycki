;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "../../functions/getTrajectoriesGeneric.ncl"

;========================================================
begin

;===========================================================================================

thedir="/global/homes/p/paullric/tempestextremes/test/era5/"
thefile="trajectories.txt.ERA5"
;thedir="./"
;thefile="ibtracs-2006-2016-GLOB.txt"

ncols = 11                    ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
isUnstruc=False

;===========================================================================================

traj_data = getTrajectoriesGeneric(thedir+"/"+thefile,ncols,maxLines,headerDelimStr,delimStr,isUnstruc,isHeader)

windcorrfactor=1.0

lon = traj_data(:,2,:)
lat = traj_data(:,3,:)
wind = traj_data(:,5,:)*windcorrfactor
pres = traj_data(:,4,:)/100.
yyyy=  traj_data(:,7,:)
mm= traj_data(:,8,:)
dd= traj_data(:,9,:)
hh= traj_data(:,10,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

minPres=dim_min_n_Wrap(pres,1)
maxWind=dim_max_n_Wrap(wind,1)

SScats=(/"TS","Cat1","Cat2","Cat3","Cat4","Cat5"/)
SSwindcounts = new(6,"integer")
SSwindcounts = 0
SSprescounts = SSwindcounts

SSwindcuts=(/17.,33.,43.,49.,58./)
SSprescuts=(/994.,980.,965.,945.,920./)

do ii = 0,nstorms-1
  thisWind=maxWind(ii)
  thisPres=minPres(ii)

  ; do wind cuts
  if (thisWind .lt. SSwindcuts(0))
    SSwindcounts(0) = SSwindcounts(0)+1
    thisCat=SScats(0)
  else if (thisWind .ge. SSwindcuts(0) .and. thisWind .lt. SSwindcuts(1))
    SSwindcounts(1) = SSwindcounts(1)+1
    thisCat=SScats(1)
  else if (thisWind .ge. SSwindcuts(1) .and. thisWind .lt. SSwindcuts(2))
    SSwindcounts(2) = SSwindcounts(2)+1
    thisCat=SScats(2)
  else if (thisWind .ge. SSwindcuts(2) .and. thisWind .lt. SSwindcuts(3))
    SSwindcounts(3) = SSwindcounts(3)+1
    thisCat=SScats(3)+"********"
  else if (thisWind .ge. SSwindcuts(3) .and. thisWind .lt. SSwindcuts(4))
    SSwindcounts(4) = SSwindcounts(4)+1
    thisCat=SScats(4)+"********"
  else
    SSwindcounts(5) = SSwindcounts(5)+1
    thisCat=SScats(5)+"********"
  end if
  end if
  end if
  end if
  end if

  ; do pres cuts
  if (thisPres .gt. SSprescuts(0))
    SSprescounts(0) = SSprescounts(0)+1
    thisCat=SScats(0)
  else if (thisPres .le. SSprescuts(0) .and. thisPres .gt. SSprescuts(1))
    SSprescounts(1) = SSprescounts(1)+1
    thisCat=SScats(1)
  else if (thisPres .le. SSprescuts(1) .and. thisPres .gt. SSprescuts(2))
    SSprescounts(2) = SSprescounts(2)+1
    thisCat=SScats(2)
  else if (thisPres .le. SSprescuts(2) .and. thisPres .gt. SSprescuts(3))
    SSprescounts(3) = SSprescounts(3)+1
    thisCat=SScats(3)+"********"
  else if (thisPres .le. SSprescuts(3) .and. thisPres .gt. SSprescuts(4))
    SSprescounts(4) = SSprescounts(4)+1
    thisCat=SScats(4)+"********"
  else
    SSprescounts(5) = SSprescounts(5)+1
    thisCat=SScats(5)+"********"
  end if
  end if
  end if
  end if
  end if

  print(thisWind+" "+thisCat)
end do

SSwindperc = tofloat(SSwindcounts) / tofloat(sum(SSwindcounts))
SSpresperc = tofloat(SSprescounts) / tofloat(sum(SSprescounts))

print(SScats+"  "+SSwindcounts+"  "+SSprescounts+"       "+SSwindperc+"  "+SSpresperc)


end
