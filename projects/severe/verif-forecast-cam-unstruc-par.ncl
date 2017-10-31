load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.NEW.ncl"

begin

wcStrt     = systemfunc("date")

;INIX=10
;config="ne0conus30x8_t12.exp003"
;config="mp120a_g16"
;config="mp15a-120a-US_t12"
;config="ne30_g16"
horizstride=1


if (str_get_cols(config,0,1) .eq. "mp") then
  mpas=True
  print("MPAS detected....")
else
  mpas=False
  print("non-MPAS detected....")
end if

;origname="f.asd2017.cesm20b05.FAMIPC6CLM5."+config+".cam.h2.1988-06-15-00000.nc"
origdir="/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5."+config+"/atm/hist/"
;origfull=origdir+"/"+origname
f = addfile(origfull,"r")

print(""+origfull)

if (config .eq. "mp120a_g16") then
  toponame="/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp120a_topo_150430.nc"
else if (config .eq. "mp15a-120a-US_t12" .or. config .eq. "mp15a-120a-US_t12.exp004") then
  toponame="/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/mp15a-120a-US.topo.170118.nc"
else if (config .eq. "ne30_g16") then
  toponame="/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc"
else if (config .eq. "ne0conus30x8_t12" .or. config .eq. "ne0conus30x8_t12.exp003") then
  toponame="/glade/p/work/zarzycki/ASD2017_files/atm/cam/topo/USGS_smoothed_ne0np4conus30x8_c161115.nc"
else
  print("cannot find topo file... exiting...")
  exit
end if
end if
end if
end if
print("using topo file: "+toponame)
f2=addfile(toponame,"r")

INIX=toint(INIX)
print("doing index "+INIX)

origname=systemfunc("basename "+origfull)
;outfilename = str_sub_str(origname,"h2","h9")
outdir="/glade/scratch/zarzycki/SEVEREPROC/"+config+"/"
outfile=outdir+"/tmp.nat2_"+sprinti("%0.4i", INIX)+"_"+origname

startix=INIX
endix=INIX

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
srheff=PSFCfull
MUCAPE=PSFCfull
SBCAPE=PSFCfull
MUCIN=PSFCfull
LFC=PSFCfull
LCL=PSFCfull
SHIP=PSFCfull

Ttmp = f->T(startix:endix,:,::horizstride)
Ztmp=Ttmp
Ptmp=Ttmp
delete(Ttmp)

delete(PSFCfull)

PRECT = f->PRECT(startix:endix,::horizstride)

PSFCf = f->PS(INIX,::horizstride)
uuf = f->U(INIX,:,::horizstride)
vvf = f->V(INIX,:,::horizstride)
Tf = f->T(INIX,:,::horizstride)
QVf = f->Q(INIX,:,::horizstride)
PHISf = f2->PHIS(::horizstride)
TQVf = Tf * (1 + 0.61*QVf)
HGTf = PHISf/9.81
if (mpas) then
  PRES = f3->PRESSURE(INIX,:,::horizstride)
  Z = f->Z3(INIX,:,::horizstride)
end if

;do jj=9595,9595
do jj=0,dimsizes(lat)-1
  if (mod(jj,1000) .eq. 0) then
    print ("doing ncol: "+jj+" of "+(dimsizes(lat)-1))
  end if
  if (mpas) then
    if (.not.isdefined("pz")) then
      pz = new((/2,nlev/),"float")
    end if
    pz(0,:) = PRES(::-1,jj)
    pz(1,:) = Z(::-1,jj)
  else
    pz = get_column_pz(hyam(::-1),hybm(::-1),TQVf(::-1,jj),tofloat(HGTf(jj)),tofloat(PSFCf(jj)),P0)
  end if

  ;print(pz(0,:))
  ;print(pz(1,:))
  Ztmp(0,::-1,jj)=(/pz(1,:)/)
  Ptmp(0,::-1,jj)=(/pz(0,:)/)

  severe_inds = get_severe_indices(tofloat(pz(0,:)),tofloat(Tf(::-1,jj)),tofloat(QVf(::-1,jj)),tofloat(pz(1,:)),tofloat(uuf(::-1,jj)),tofloat(vvf(::-1,jj)),tofloat(HGTf(jj)),tofloat(PSFCf(jj)))
  SCP(0,jj)=(/severe_inds(0)/)
  SIGTOR(0,jj)=(/severe_inds(1)/)
  shear(0,jj)=(/severe_inds(2)/)
  srh3km(0,jj)=(/severe_inds(4)/)
  srheff(0,jj)=(/severe_inds(5)/)
  MUCAPE(0,jj)=(/severe_inds(6)/)
  SBCAPE(0,jj)=(/severe_inds(7)/)
  MUCIN(0,jj)=(/severe_inds(8)/)
  LFC(0,jj)=(/severe_inds(9)/)
  LCL(0,jj)=(/severe_inds(10)/)
  SHIP(0,jj)=(/severe_inds(11)/)
end do

; insert metadata
SCP@long_name = "Supercell Composite Parameter"
SCP@units = "-"

SIGTOR@long_name = "Significant Tornado Parameter"
SIGTOR@units = "-"

shear@long_name = "0-6km wind shear"
shear@units = "m/s"

srh3km@long_name = "0-3km storm relative helicity"
srh3km@units = "m2/s2"

srheff@long_name = "Effective storm relative helicity"
srheff@units = "m2/s2"

MUCAPE@long_name = "Maximum unstable convective available potential energy"
MUCAPE@units = "J/kg"

SBCAPE@long_name = "Surface-based convective available potential energy"
SBCAPE@units = "J/kg"

MUCIN@long_name = "Maximum unstable convective inhibition"
MUCIN@units = "J/kg"

LCL@long_name = "Lifted condensation level"
LCL@units = "m"

LFC@long_name = "Level of free convection"
LFC@units = "m"

SHIP@long_name = "Significant Hail Parameter"
SHIP@units = "-"

system("mkdir -p "+outdir)   ; remove any pre-existing file
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "Severe Convective Parameters"
fAtt@source_file   =  origfull
fAtt@Conventions   = "None"
fAtt@Author   = "Colin Zarzycki"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True)

ncdf->SCP = SCP
ncdf->SIGTOR = SIGTOR
ncdf->SHEAR_0_6 = shear
ncdf->SRH_0_3 = srh3km
ncdf->SRH_EFF = srheff
ncdf->MUCAPE = MUCAPE
ncdf->MUCIN = MUCIN
ncdf->SBCAPE = SBCAPE
ncdf->LCL = LCL
ncdf->LFC = LFC
ncdf->PRECT = PRECT
ncdf->SHIP = SHIP

;ncdf->Z = Ztmp
;ncdf->P = Ptmp

wallClockElapseTime(wcStrt, "Total time", 0)

end
