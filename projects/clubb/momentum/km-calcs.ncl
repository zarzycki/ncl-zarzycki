begin

CASE="RCE.QPC6.ne0np4tcfplane.ne15x8.exp703.001"
f3=addfile(CASE+".cam.h3.0001-01-09-00000.nc_regrid.nc","r")
f2=addfile(CASE+".cam.h2.0001-01-09-00000.nc_regrid.nc","r")
f1=addfile(CASE+".cam.h1.0001-01-09-00000.nc_regrid.nc","r")

CK10=0.5
C_K =0.2

LSCALE = f3->LSCALE_CLUBB(0,:,:,:)
;LSCALE = LSCALE * 0.2 ; Ck!
TKE = f3->TKE_CLUBB(0,:,:,:)
K3 = LSCALE
K3 = C_K * CK10 * LSCALE * sqrt(TKE)

KVH_CLUBB = f3->KVH_CLUBB(0,:,:,:)
K1 = KVH_CLUBB
K1 = CK10 * K1

LSCALE2 = LSCALE
LSCALE2 = KVH_CLUBB * CK10 / CK10 / sqrt(TKE)/ C_K

U = f1->U(0,:,:,:)
V = f1->V(0,:,:,:)
Z = f1->Z3(0,:,:,:)
nlev = dimsizes(f1->lev)
U = sqrt(U^2 + V^2)

UPWP = f3->UPWP_CLUBB(0,:,:,:)
VPWP = f3->VPWP_CLUBB(0,:,:,:)
UPWP = sqrt(UPWP^2 + VPWP^2)
eps=1e-8

DUDZ = UPWP
DUDZ(1:nlev-1,:,:) = (U(0:nlev-2,:,:) - U(1:nlev-1,:,:)) / (Z(0:nlev-2,:,:) - Z(1:nlev-1,:,:))
DUDZ(0,:,:) = DUDZ(1,:,:)
DUDZ(nlev,:,:) = DUDZ(nlev-1,:,:)

;DUDZ := center_finite_diff_n (U,Z,False,0,0)
;linlog=-2
;DUDZ := int2p_n_Wrap (U&lev,DUDZ,UPWP&ilev,linlog,0)

K2 = UPWP
K2 = UPWP/(DUDZ+eps)


;==================================================================================================
outDir="./"
outFile="derived.nc"
system("/bin/rm -f "+outDir+"/"+outFile)   ; remove any pre-existing file
ncdf = addfile(outDir+"/"+outFile ,"c")  ; open output netCDF file

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
ncdf->LSCALE = LSCALE
ncdf->LSCALE2 = LSCALE2
ncdf->TKE = TKE
ncdf->DUDZ = DUDZ
ncdf->UPWP = UPWP

ncdf->K1 = K1
ncdf->K2 = K2
ncdf->K3 = K3

;==================================================================================================

end
