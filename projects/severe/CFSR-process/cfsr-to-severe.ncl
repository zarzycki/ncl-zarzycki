load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "../helicity.NEW.ncl"

;grb_filename="/glade/u/home/zarzycki/scratch/cfsr-test/pgbh06.gdas.2008020600.grb2"
grb_file=addfile(grb_filename,"r")

strs = str_split(grb_filename, ".")
fulldate=strs(2)
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(fulldate, dtime_map)
form_units="days since 1900-01-01 00:00:00"
opt=0
form_time = cd_inv_calendar(tofloat(tst_dtime(0)),tofloat(tst_dtime(1)),tofloat(tst_dtime(2)),tofloat(tst_dtime(3)),0.,0.,form_units,opt)
form_time = form_time + 0.25
print(form_time)

horizstride=1

minLat=20.
maxLat=55.
minLon=230.
maxLon=295.

grblat = grb_file->lat_0({minLat:maxLat:horizstride})
grblon = grb_file->lon_0({minLon:maxLon:horizstride})
grblev = grb_file->lv_ISBL0

nlat=dimsizes(grblat)
nlon=dimsizes(grblon)

ps = grb_file->PRES_P0_L1_GLL0({minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
t_gfs = grb_file->TMP_P0_L100_GLL0(:,{minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
u_gfs = grb_file->UGRD_P0_L100_GLL0(:,{minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
v_gfs = grb_file->VGRD_P0_L100_GLL0(:,{minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
rh_gfs = grb_file->RH_P0_L100_GLL0(:,{minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
phis_gfs = grb_file->HGT_P0_L1_GLL0({minLat:maxLat:horizstride},{minLon:maxLon:horizstride})
prect_gfs = grb_file->PRATE_P8_L1_GLL0_avg({minLat:maxLat:horizstride},{minLon:maxLon:horizstride})

print("Calculating q from RH")
q_gfs = mixhum_ptrh(conform(t_gfs,grblev,0)*0.01, t_gfs , rh_gfs, 2 ) ; specific humidity (g/kg)  
delete(rh_gfs)

print("---------------------------------------------------------")
print("Loading CAM levels")
print("Loading 32 level data")
fC   = addfile ("./L32template.nc", "r")
P0   = 100000.
hyam  = fC->hyam
hybm  = fC->hybm
hyai  = fC->hyai
hybi  = fC->hybi
lev = fC->lev
ilev = fC->ilev

Tf = pres2hybrid_Wrap(grblev,ps,P0,t_gfs,hyam,hybm,1)
uuf = pres2hybrid_Wrap(grblev,ps,P0,u_gfs,hyam,hybm,1)
vvf = pres2hybrid_Wrap(grblev,ps,P0,v_gfs,hyam,hybm,1)
QVf = pres2hybrid_Wrap(grblev,ps,P0,q_gfs,hyam,hybm,1)

TQVf = Tf * (1 + 0.61*QVf)
HGTf = phis_gfs/9.81
PSFCf = ps

Ttmp = Tf
Ztmp=Ttmp
Ptmp=Ttmp
delete(Ttmp)

; create arrays to hold indices
SCP = new((/1,nlat,nlon/),"float",1.e-36)
SCP!0="time"
SCP!1="lat"
SCP!2="lon"
SCP&time=form_time
SCP&lat=grblat
SCP&lon=grblon
SIGTOR = SCP
shear=SCP
srh3km=SCP
srheff=SCP
MUCAPE=SCP
SBCAPE=SCP
MUCIN=SCP
LFC=SCP
LCL=SCP
shear=SCP
SHIP=SCP
PRECT=SCP
PRECT(0,:,:)=(/prect_gfs(:,:)/)

do ii = 0,nlat-1
  if (mod(ii,10) .eq. 0) then
    print ("doing ncol: "+ii+" of "+nlat)
  end if
  do jj = 0,nlon-1
    pz = get_column_pz(hyam(::-1),hybm(::-1),TQVf(::-1,ii,jj),tofloat(HGTf(ii,jj)),tofloat(PSFCf(ii,jj)),P0)
    Ztmp(::-1,ii,jj)=(/pz(1,:)/)
    Ptmp(::-1,ii,jj)=(/pz(0,:)/)
    severe_inds = get_severe_indices(tofloat(pz(0,:)),tofloat(Tf(::-1,ii,jj)),tofloat(QVf(::-1,ii,jj)),tofloat(pz(1,:)),tofloat(uuf(::-1,ii,jj)),tofloat(vvf(::-1,ii,jj)),tofloat(HGTf(ii,jj)),tofloat(PSFCf(ii,jj)))

  SCP(0,ii,jj)=(/severe_inds(0)/)
  SIGTOR(0,ii,jj)=(/severe_inds(1)/)
  shear(0,ii,jj)=(/severe_inds(2)/)
  srh3km(0,ii,jj)=(/severe_inds(4)/)
  srheff(0,ii,jj)=(/severe_inds(5)/)
  MUCAPE(0,ii,jj)=(/severe_inds(6)/)
  SBCAPE(0,ii,jj)=(/severe_inds(7)/)
  MUCIN(0,ii,jj)=(/severe_inds(8)/)
  LFC(0,ii,jj)=(/severe_inds(9)/)
  LCL(0,ii,jj)=(/severe_inds(10)/)
  SHIP(0,ii,jj)=(/severe_inds(11)/)

  end do
end do

; METADATA

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

;=====================================================================================

outfile=outDir+"/cfsr."+cd_calendar(form_time,-3)+".nc"
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
ncdf = addfile(outfile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@source_file   =  grb_filename
fAtt@Conventions   = "None"
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
ncdf->SHIP = SHIP
ncdf->PRECT = PRECT
