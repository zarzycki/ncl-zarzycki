load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.NEW.ncl"

begin

wcStrt     = systemfunc("date")

f = addfile("/glade/p/work/zarzycki/sewx/INIC/fv0.23x0.31_L30_2017061300_INIC.nc","r")
f2 = addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS_gtopo30_0.23x0.31_remap_c061107.nc","r")
startix=0
endix=0
horizstride=1

maxlat=55.
minlat=22.
maxlon=295.
minlon=233.

lat = f->lat({minlat:maxlat:horizstride})
lon = f->lon({minlon:maxlon:horizstride})
slat = f->slat({minlat:maxlat:horizstride})
slon = f->slon({minlon:maxlon:horizstride})
lev = f->lev(:)
hyam = f->hyam(:)
hybm = f->hybm(:)
hyai = f->hyai(:)
hybi = f->hybi(:)
P0=100000.
PSFCf = f->PS(startix:endix,{minlat:maxlat:horizstride},{minlon:maxlon:horizstride})
uusf = f->US(startix:endix,:,{minlat:maxlat:horizstride},{minlon:maxlon:horizstride})
vvsf = f->VS(startix:endix,:,{minlat:maxlat:horizstride},{minlon:maxlon:horizstride})

Tf = f->T(startix:endix,:,{minlat:maxlat:horizstride},{minlon:maxlon:horizstride})
QVf = f->Q(startix:endix,:,{minlat:maxlat:horizstride},{minlon:maxlon:horizstride})
PHISf = f2->PHIS({minlat:maxlat:horizstride},{minlon:maxlon:horizstride})
TQVf = Tf * (1 + 0.61*QVf)
HGTf = PHISf/9.81

printVarSummary(uusf)

Pf = pres_hybrid_ccm(PSFCf,P0,hyam,hybm)
printVarSummary(Pf)
Zf = cz2ccm(PSFCf,PHISf,TQVf,P0,hyam(::-1),hybm(::-1),hyai(::-1),hybi(::-1))
uuf = linint2(lon,slat,uusf,False,lon,lat,0)
vvf = linint2(slon,lat,vvsf,False,lon,lat,0)

uuf = where(ismissing(uuf),0.00001,uuf)
vvf = where(ismissing(vvf),0.00001,vvf)

;---------------------------------------------

uuf=where(ismissing(uuf),0.0,uuf)
vvf=where(ismissing(vvf),0.0,vvf)

SCP = PSFCf
shear=PSFCf
srh3km=PSFCf
SBCAPE=PSFCf
LCL=PSFCf
SHIP=PSFCf

do ii = 0,0
do jj=0,dimsizes(lat)-1
do kk=0,dimsizes(lon)-1
  if (kk .eq. 0) then
    print ("doing lat: "+jj+" of "+(dimsizes(lat)-1))
  end if
  severe_inds = get_severe_indices(tofloat(Pf(ii,::-1,jj,kk)),tofloat(Tf(ii,::-1,jj,kk)),tofloat(QVf(ii,::-1,jj,kk)),tofloat(Zf(ii,::-1,jj,kk)),tofloat(uuf(ii,::-1,jj,kk)),tofloat(vvf(ii,::-1,jj,kk)),tofloat(HGTf(jj,kk)),tofloat(PSFCf(ii,jj,kk)))
  SCP(ii,jj,kk)=severe_inds(0)
  shear(ii,jj,kk)=severe_inds(2)
  srh3km(ii,jj,kk)=severe_inds(4)
  SBCAPE(ii,jj,kk)=severe_inds(7)
  LCL(ii,jj,kk)=severe_inds(10)
  SHIP(ii,jj,kk)=severe_inds(11)
end do
end do
end do



system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->SCP = SCP
ncdf->shear = shear
ncdf->srh3km = srh3km
ncdf->SBCAPE = SBCAPE
ncdf->LCL = LCL
ncdf->SHIP = SHIP

wallClockElapseTime(wcStrt, "Total time", 0)

end
