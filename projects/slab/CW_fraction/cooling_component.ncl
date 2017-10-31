load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

;h6filename="/glade/scratch/zarzycki/nhemi_30_x4_slab/run/1201/nhemi_30_x4_slab.cam.h5.1201-07-13-00000.nc_regrid.nc"
h6file=addfile(h6filename,"r")

;split_by_slash = str_split(h6filename,"/")
;outDir=""
;do i = 0,dimsizes(split_by_slash)-2
;  outDir = outDir+"/"+split_by_slash(i)
;end do
;print(outDir)

outFile=str_sub_str(h6filename,"h5","h8")

docnfilename="/glade/p/work/zarzycki/slab/docn_files/climo_1x1_slab_exp003.nc"
docnfile=addfile(docnfilename,"r")

hlat=h6file->lat
hlon=h6file->lon
u10=h6file->U10
sst=h6file->SST

lhflx=h6file->LHFLX
shflx=h6file->SHFLX
lwflx=h6file->FLNS
swflx=h6file->FSNS

dlat=docnfile->yc
dlon=docnfile->xc
hn_nat=docnfile->hblt(0,:,:)

hn_single = linint2_Wrap(dlon,dlat,hn_nat,False,hlon,hlat,0)
hn = conform_dims(dimsizes(u10), hn_single, (/1,2/)) 
copy_VarCoords(u10,hn)

TkFrzSw=271.0
logwgt = u10
logwgt = 1.0/(1.0 + exp(-0.5*(u10-30.0)))
dt=3.*3600.
;hn=30
R_cool=4.7
cpsw=3.996e3
rhosw=1.026e3
  
dSSTdt_turb=u10
dSSTdt_turb=-logwgt*(R_cool/86400.)*((sst-TkFrzSw)/27.0)*(30/hn)*dt

dSSTdt_flux=u10
dSSTdt_flux=-(lhflx+shflx+lwflx-swflx)*dt/(hn*cpsw*rhosw)

 system("/bin/rm -f "+outFile)   ; remove any pre-existing file
 ncdf = addfile(outFile ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
 fAtt               = True            ; assign file attributes
 fAtt@title         = "NCL Simple Approach to netCDF Creation"
 fAtt@source_file   =  "original-file.nc"
 fAtt@Conventions   = "None"
 fAtt@creation_date = systemfunc ("date")
 fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
 filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================
ncdf->dSST_turb  = dSSTdt_turb
;ncdf->logwgt       = logwgt
;ncdf->u10       = u10
ncdf->dSST_flux = dSSTdt_flux
;ncdf->lhflx = lhflx
;ncdf->shflx = shflx
;ncdf->lwflx=lwflx
;ncdf->swflx=swflx
;ncdf->hn=hn

end
