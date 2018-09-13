;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

;ensnum="001"
print(ensnum)

indir="/glade/u/home/zarzycki/scratch/LENS-snow/"
files = (/indir+"/b.e11.B20TRC5CNBDRD.f09_g16."+ensnum+".cam.h2.PRECT_SNOW.1990010100Z-2005123118Z.nc", indir+"/b.e11.BRCP85C5CNBDRD.f09_g16."+ensnum+".cam.h2.PRECT_SNOW.2026010100Z-2035123118Z.nc", indir+"/b.e11.BRCP85C5CNBDRD.f09_g16."+ensnum+".cam.h2.PRECT_SNOW.2071010100Z-2080123118Z.nc"/)
nyrs = (/16, 10, 10/)
outdir=indir

outvarname="PRECBSN_FREQ_PRECT"
fileout = (/outdir+"/b.e11.B20TRC5CNBDRD.f09_g16."+ensnum+".cam.h2."+outvarname+".1990010100Z-2005123118Z.nc", outdir+"/b.e11.BRCP85C5CNBDRD.f09_g16."+ensnum+".cam.h2."+outvarname+".2026010100Z-2035123118Z.nc", outdir+"/b.e11.BRCP85C5CNBDRD.f09_g16."+ensnum+".cam.h2."+outvarname+".2071010100Z-2080123118Z.nc"/)

do ii = 0,dimsizes(files)-1
  f = addfile(files(ii),"r")
  ptype = f->PRECT_SNOW(:,:,:)
  
  ptype = where(ptype .gt. 1e-8,1,0)
  ptype_sum = dim_sum_n_Wrap(ptype,0)
  ptype_sum=ptype_sum/nyrs(ii)/4.

   system("/bin/rm -f "+fileout(ii))   ; remove any pre-existing file
   ncdf = addfile(fileout(ii) ,"c")  ; open output netCDF file
   fAtt               = True            ; assign file attributes
   fAtt@creation_date = systemfunc ("date")
   fileattdef( ncdf, fAtt )            ; copy file attributes
   filedimdef(ncdf,"time",-1,True) 
   ncdf->$outvarname$ = ptype_sum   

   delete(f)
   delete(ptype)
   delete(ptype_sum)
end do

end 