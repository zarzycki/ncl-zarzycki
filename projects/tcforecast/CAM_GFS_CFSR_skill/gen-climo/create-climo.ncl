load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "clm6hrTLL.ncl"

begin

;wget -r --no-parent -A 'hgt.20*.nc' ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/pressure/
;wget -r --no-parent -A 'air.198*.nc' -A 'air.199*.nc' -A 'air.200*.nc' ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/pressure/
;wget -r --no-parent -A 'air.sig995.*.nc' ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/

;diri = "/glade/u/home/zarzycki/scratch/ncep/ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/"
;fili = systemfunc("cd "+diri+" ; ls air.sig995.198*.nc air.sig995.199*.nc air.sig995.200*.nc")

ncepvarname="uwnd"
lev=850.
outvarname="U850"

diri = "/glade/u/home/zarzycki/scratch/ncep/ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/pressure/"
fili = systemfunc("cd "+diri+" ; ls "+ncepvarname+".198*.nc "+ncepvarname+".199*.nc "+ncepvarname+".200*.nc")
nfili= dimsizes(fili)
print("nfili="+nfili)

f    = addfiles(diri+fili,"r") 

lat  = f[0]->lat
lon  = f[0]->lon

;var = f[:]->air(:,:,:)
var = f[:]->$ncepvarname$(:,{lev},:,:)
time = f[:]->time

climo=clm6hrTLL(var,time)

; flip lats
climo=climo(:,::-1,:)

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@source_file   = fili
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

;ncdf->TS  = climo    
ncdf->$outvarname$ = climo

end

