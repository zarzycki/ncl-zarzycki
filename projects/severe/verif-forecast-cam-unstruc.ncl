load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.ncl"

begin

wcStrt     = systemfunc("date")

mpas=False
;config="mp120a_g16"
config="ne30_g16"
origname="f.asd2017.cesm20b05.FAMIPC6CLM5."+config+".cam.h2.1988-06-15-00000.nc"
origdir="/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5."+config+"/atm/hist/"
f = addfile(origdir+origname,"r")
;f2 = addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/USGS_smoothed_ne0np4conus30x8_c161115.nc","r")
f2 = addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc","r")
;f2=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp120a_topo_150430.nc","r")
;f2=addfile("/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc","r")
outfilename = str_sub_str(origname,"h2","h9")
outfile="/glade/scratch/zarzycki/tmp.nat_"+outfilename

startix=0
endix=0
horizstride=1

lat = f->lat(::horizstride)
lon = f->lon(::horizstride)
lev = f->lev(:)
nlev = dimsizes(lev)
if (mpas) then
  presname="f.asd2017.cesm20b05.FAMIPC6CLM5."+config+".cam.h2.1988-06-15-00000.nc.PRES.nc"
  f3 = addfile(origdir+presname,"r")
else
  hyam = f->hyam(:)
  hybm = f->hybm(:)
  hyai = f->hyai(:)
  hybi = f->hybi(:)
  P0=f->P0
end if

PSFCfull = f->PS(startix:endix,::horizstride)

; create arrays to hold indices
SCP = PSFCfull
SIGTOR = PSFCfull
shear=PSFCfull
srh3km=PSFCfull
SBCAPE=PSFCfull
LCL=PSFCfull
shear=PSFCfull

Ttmp = f->T(startix:endix,:,::horizstride)
Ztmp=Ttmp
Ptmp=Ttmp
delete(Ttmp)

delete(PSFCfull)

do ii = 0,endix-startix

PSFCf = f->PS(ii,::horizstride)
uuf = f->U(ii,:,::horizstride)
vvf = f->V(ii,:,::horizstride)
Tf = f->T(ii,:,::horizstride)
QVf = f->Q(ii,:,::horizstride)
PHISf = f2->PHIS(::horizstride)
TQVf = Tf * (1 + 0.61*QVf)
HGTf = PHISf/9.81
if (mpas) then
  PRES = f3->PRESSURE(ii,:,::horizstride)
  Z = f->Z3(ii,:,::horizstride)
end if

print("Starting time... "+ii+" of "+(endix-startix))
do jj=0,dimsizes(lat)-1
  if (mod(jj,100) .eq. 0) then
    print ("doing ncol: "+jj+" of "+(dimsizes(lat)-1))
  end if
  if (mpas) then
    if (jj .eq. 0) then
      pz = new((/2,nlev/),"float")
    end if
    pz(0,:) = PRES(::-1,jj)
    pz(1,:) = Z(::-1,jj)
  else
    pz = get_column_pz(hyam(::-1),hybm(::-1),TQVf(::-1,jj),tofloat(HGTf(jj)),tofloat(PSFCf(jj)),P0)
  end if

  ;print(pz(0,:))
  ;print(pz(1,:))
  Ztmp(ii,::-1,jj)=(/pz(1,:)/)
  Ptmp(ii,::-1,jj)=(/pz(0,:)/)

  severe_inds = get_severe_indices(tofloat(pz(0,:)),tofloat(Tf(::-1,jj)),tofloat(QVf(::-1,jj)),tofloat(pz(1,:)),tofloat(uuf(::-1,jj)),tofloat(vvf(::-1,jj)),tofloat(HGTf(jj)),tofloat(PSFCf(jj)))
  SCP(ii,jj)=(/severe_inds(0)/)
  SIGTOR(ii,jj)=(/severe_inds(1)/)
  shear(ii,jj)=(/severe_inds(2)/)
  srh3km(ii,jj)=(/severe_inds(4)/)
  SBCAPE(ii,jj)=(/severe_inds(7)/)
  LCL(ii,jj)=(/severe_inds(10)/)
end do
end do

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
ncdf->Z = Ztmp
ncdf->P = Ptmp

wallClockElapseTime(wcStrt, "Total time", 0)

end
