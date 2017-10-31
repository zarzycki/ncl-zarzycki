;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "~/ncl/functions/clmMonTLU.ncl"
;========================================================

begin

RGRD_dir  = "/glade/p/work/zarzycki/atm-ocn-coupling/climo/"
RGRD_file = "ne120_gx1v6_climo.nc"
RGRD_path = RGRD_dir +"/"+  RGRD_file

latfile=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/climo/0.25latlon.nc","r")
newlat=latfile->lat
newlon=latfile->lon
                         
all_files = systemfunc ("ls /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/regrid/*h0.198*.nc /glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/regrid/*h0.199*.nc")
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (fall, "cat")             ; concatenate or "merge" (default)

print(fall)

theseVars=(/"PRECC","PRECL","FLUT","U","V","T","RELHUM","PS","PSL","LWCF","SWCF","TMQ"/)

do z = 0,dimsizes(theseVars)-1

if(z .eq. 0) then
  print("Deleting "+RGRD_path)
  system("/bin/rm -f "+RGRD_path)      ; delete any pre-existing file
end if

print("Doing var: "+theseVars(z))

theVar = fall[:]->$theseVars(z)$

if(dimsizes(dimsizes(theVar)) .eq. 3) then
  vClm = lonFlip(clmMonTLL( theVar ))
else
  vClm = lonFlip(clmMonTLLL( theVar ))
end if

delete(theVar)

vClm_regrid = linint2_Wrap(vClm&lon,vClm&lat,vClm,True,newlon,newlat,0)
;vClm_regrid = area_conserve_remap_Wrap(vClm&lon,vClm&lat,vClm,newlon,newlat,False)
delete(vClm)

setfileoption("nc","Format","LargeFile")
if (isfilepresent(RGRD_path))
  rgrd_nc   = addfile(RGRD_path, "w")  ; open for writing
else
  rgrd_nc   = addfile(RGRD_path, "c")  ; open for writing
  filedimdef(rgrd_nc,"time",-1,True) 
end if

rgrd_nc->$theseVars(z)$ = vClm_regrid

delete(vClm_regrid)

end do

end

