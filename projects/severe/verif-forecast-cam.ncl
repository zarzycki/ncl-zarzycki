load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.ncl"

begin

wcStrt     = systemfunc("date")

origname="f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h2.1988-06-15-00000.nc_regrid.nc"
f = addfile("~/scratch/"+origname,"r")
f2 = addfile("~/scratch/topo-se.nc","r")
startix=0
endix=0
horizstride=1

lat = f->lat(::horizstride)
lon = f->lon(::horizstride)
lev = f->lev(:)
hyam = f->hyam(:)
hybm = f->hybm(:)
hyai = f->hyai(:)
hybi = f->hybi(:)
P0=f->P0
PSFCf = f->PS(startix:endix,::horizstride,::horizstride)
uuf = f->U(startix:endix,:,::horizstride,::horizstride)
vvf = f->V(startix:endix,:,::horizstride,::horizstride)
Tf = f->T(startix:endix,:,::horizstride,::horizstride)
QVf = f->Q(startix:endix,:,::horizstride,::horizstride)
PHISf = f2->PHIS(::horizstride,::horizstride)
TQVf = Tf * (1 + 0.61*QVf)
HGTf = PHISf/9.81

Pf = pres_hybrid_ccm(PSFCf,P0,hyam,hybm)
Zf = cz2ccm(PSFCf,PHISf,TQVf,P0,hyam(::-1),hybm(::-1),hyai(::-1),hybi(::-1))
;---------------------------------------------

SCP = PSFCf
SIGTOR = PSFCf
shear=PSFCf
srh3km=PSFCf
SBCAPE=PSFCf
LCL=PSFCf
shear=PSFCf
shear=PSFCf

do ii = 0,endix-startix
print("Starting time... "+ii+" of "+(endix-startix))
do jj=0,dimsizes(lat)-1
do kk=0,dimsizes(lon)-1
  if (kk .eq. 0) then
    print ("doing lat: "+jj+" of "+(dimsizes(lat)-1))
  end if
  severe_inds = get_severe_indices(tofloat(Pf(ii,::-1,jj,kk)),tofloat(Tf(ii,::-1,jj,kk)),tofloat(QVf(ii,::-1,jj,kk)),tofloat(Zf(ii,::-1,jj,kk)),tofloat(uuf(ii,::-1,jj,kk)),tofloat(vvf(ii,::-1,jj,kk)),tofloat(HGTf(jj,kk)),tofloat(PSFCf(ii,jj,kk)))
  SCP(ii,jj,kk)=(/severe_inds(0)/)
  SIGTOR(ii,jj,kk)=(/severe_inds(1)/)
  shear(ii,jj,kk)=(/severe_inds(2)/)
  srh3km(ii,jj,kk)=(/severe_inds(4)/)
  SBCAPE(ii,jj,kk)=(/severe_inds(7)/)
  LCL(ii,jj,kk)=(/severe_inds(10)/)
end do
end do
end do

outfilename = str_sub_str(origname,"h2","h9")

outfile="/glade/scratch/zarzycki/"+outfilename
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->SCP = SCP
ncdf->SIGTOR = SIGTOR
ncdf->shear = shear
ncdf->srh3km = srh3km
ncdf->SBCAPE = SBCAPE
ncdf->LCL = LCL

wallClockElapseTime(wcStrt, "Total time", 0)

end
