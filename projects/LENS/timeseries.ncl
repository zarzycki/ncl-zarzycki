;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;========================================================

begin

;sed -i "s/-999.0/      /g" station.SANJUAN.2071.001.csv 

CITYNAME="SANJUAN"
;yrlabel="2071"
;ENSMEM="001"

print(yrlabel)

if (yrlabel .eq. "2071") then
  modelconfig="BRCP85C5CNBDRD"
  hr6str="2071010100Z-2080123118Z"
  hr1str="20060101-20801231"
else if (yrlabel .eq. "2026") then
  modelconfig="BRCP85C5CNBDRD"
  hr6str="2026010100Z-2035123118Z"
  hr1str="20060101-20801231"
else if (yrlabel .eq. "1990") then
  modelconfig="B20TRC5CNBDRD"
  hr6str="1990010100Z-2005123118Z"
  if (ENSMEM .eq. "001") then
    hr1str="18500101-20051231"
  else
    hr1str="19200101-20051231"
  end if
else
end if
end if
end if

filelist = systemfunc ("ls /glade/p_old/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly6/PRECT/b.e11."+modelconfig+".f09_g16."+ENSMEM+".cam.h2.PRECT."+hr6str+".nc") ; file paths

f    = addfiles (filelist, "r")   
ListSetType (f, "cat")        ; concatenate (=default)
ftime = f[:]->time(:)
lat=f[0]->lat
lon=f[0]->lon
nftim = dimsizes(ftime)
TESTLAT=18.4655
TESTLON=293.8943

print(lat({TESTLAT})+" "+lon({TESTLON}))

PRECT    = f[:]->PRECT(:,{TESTLAT},{TESTLON})
PRECT = PRECT*8.64e7/4.  ; convert to mm/6hr
PRECT@_FillValue=-999.
PRECT = where(PRECT.lt.1e-3,0,PRECT)   ; correct for small eps values

delete(f)
; other files

var=(/"TREFHT","QREFHT","CLDTOT","FSDS","U","V","PS"/)
do ii = 0,dimsizes(var)-1
  print("Doing "+var(ii))
  filelist = systemfunc ("ls /glade/u/home/zarzycki/scratch/for-bec/b.e11."+modelconfig+".f09_g16."+ENSMEM+".cam.h2."+var(ii)+"."+hr6str+".nc") ; file paths
  f = addfiles (filelist, "r")
  ListSetType (f, "cat")
  if (var(ii) .eq. "TREFHT") then
    TS = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
  else if (var(ii) .eq. "QREFHT") then
    QS = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
  else if (var(ii) .eq. "CLDTOT") then
    CLDTOT = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
  else if (var(ii) .eq. "FSDS") then
    FSDS = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
  else if (var(ii) .eq. "PS") then
    PS = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
  else if (var(ii) .eq. "U") then
    UBOT = f[:]->$var(ii)$(:,29,{TESTLAT},{TESTLON})
    UBOT = UBOT*.85
  else if (var(ii) .eq. "V") then
    VBOT = f[:]->$var(ii)$(:,29,{TESTLAT},{TESTLON})
    VBOT = VBOT*.85
  else
    print("unsupported...")
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  delete(f)
end do
delete(var)

RH = relhum(TS, QS, PS)

U10=UBOT
U10=sqrt(UBOT^2+VBOT^2)

TS = TS - 273.15
QS = QS * 1000.
PS = PS / 100.


var=(/"TREFHTMN","TREFHTMX"/)
do ii = 0,dimsizes(var)-1
  print("Doing "+var(ii))
  filelist = systemfunc ("ls /glade/u/home/zarzycki/scratch/for-bec/b.e11."+modelconfig+".f09_g16."+ENSMEM+".cam.h1."+var(ii)+"."+hr1str+".nc") ; file paths
  f = addfiles (filelist, "r")
  ListSetType (f, "cat")
  ftime2 = f[:]->time(:)
  if (var(ii) .eq. "TREFHTMN") then
    TREFHTMN_ = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
    TREFHTMN=PRECT
    TREFHTMN=TREFHTMN@_FillValue
    do jj = 0,nftim-1
      if (.not.ismissing(ind(ftime2.eq.ftime(jj))))
        ix = ind(ftime2.eq.ftime(jj))
        TREFHTMN(jj)=TREFHTMN_(ix)
      end if
    end do
  else if (var(ii) .eq. "TREFHTMX") then
    TREFHTMX_ = f[:]->$var(ii)$(:,{TESTLAT},{TESTLON})
    TREFHTMX=PRECT
    TREFHTMX=TREFHTMX@_FillValue
    do jj = 0,nftim-1
      if (.not.ismissing(ind(ftime2.eq.ftime(jj))))
        ix = ind(ftime2.eq.ftime(jj))
        TREFHTMX(jj)=TREFHTMX_(ix)
      end if
    end do
  else
    print("unsupported...")
  end if
  end if
  
  delete(f)
  delete(ftime2)
end do

TREFHTMX = TREFHTMX-273.15
TREFHTMN = TREFHTMN-273.15


; -------------------------------------------------------------------------

outputname="station."+CITYNAME+"."+yrlabel+"."+ENSMEM+".csv"
system("rm "+outputname)
quote = inttochar(34)
delim = ","

alist   = [/conform(ftime,CITYNAME,-1),conform(ftime,TESTLAT,-1),conform(ftime,TESTLON,-1),"  "+tostring(cd_calendar(ftime,-3)),TS,TREFHTMN,TREFHTMX,QS,RH,PS,U10,PRECT,CLDTOT,FSDS/]
write_table(outputname, "w", alist, "%s,%7.1f,%7.1f,%s,%7.1f,%9.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f,%7.1f")

end
