begin

CASE="RCE.QPC6.ne0np4tcfplane.ne15x8.exp290.001"
dir="~/scratch/"+CASE+"/run/"

f3=addfile(dir+"/"+CASE+".cam.h3.0001-01-08-00000.nc_regrid.nc","r")
f2=addfile(dir+"/"+CASE+".cam.h2.0001-01-08-00000.nc_regrid.nc","r")
f1=addfile(dir+"/"+CASE+".cam.h1.0001-01-08-00000.nc_regrid.nc","r")

print(dir+"/"+CASE+".cam.h3.0001-01-08-00000.nc_regrid.nc")

CK10=0.6
C_K =0.2

; METHOD 1
; Calculate Km directly from CLUBB (Kh_zm * c_k10)
KVH_CLUBB = f3->Kh_zt(0,:,:,:)
K1 = KVH_CLUBB
K1 = CK10 * K1

; METHOD 2
; Calculate Km from L and TKE - Eqn 35 in Golaz et al 2002
LSCALE = f3->Lscale(0,:,:,:)
TKE = f3->em(0,:,:,:)
K2 = LSCALE
K2 = C_K * CK10 * LSCALE * sqrt(TKE)

; Back out Lscale
LSCALE2 = LSCALE
LSCALE2 = KVH_CLUBB * CK10 / CK10 / sqrt(TKE)/ C_K

; METHOD 3
; Km indirectly via Km = - u'w' / dudz
U = f3->um(0,:,:,:)
V = f3->vm(0,:,:,:)
Z = f3->ZT_CLUBB(0,:,:,:)
nlev = dimsizes(f3->lev)
U = sqrt(U^2 + V^2)

UPWP = f3->upwp(0,:,:,:)
VPWP = f3->vpwp(0,:,:,:)
UPWP = sqrt(UPWP^2 + VPWP^2)
eps=1.0e-12

DUDZ = UPWP
DUDZ(1:nlev-1,:,:) = (U(0:nlev-2,:,:) - U(1:nlev-1,:,:)) / (Z(0:nlev-2,:,:) - Z(1:nlev-1,:,:))
DUDZ(0,:,:) = DUDZ(1,:,:)
DUDZ(nlev,:,:) = DUDZ(nlev-1,:,:)

DUDZ := center_finite_diff_n (U,Z,False,0,0)
;linlog=-2
;DUDZ := int2p_n_Wrap (U&lev,DUDZ,UPWP&ilev,linlog,0)

K3 = UPWP
K3 = UPWP/(DUDZ+eps)
;K3 = where(abs(K3) .gt. 1500.,K3@FillValue,K3)
printVarSummary(K3)

;************************************************
; plotting parameters
;************************************************
; wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file
; res                  = True                     ; plot mods desired
; res@tiMainString     = "Basic XY plot"          ; add title
; plot  = gsn_csm_xy (wks,K3(:,{-0.25},{-1.5}),K1&ilev,res) ; create plot


; 1115 HEIGHT                           m                  57 A  geopotential height above surface at interfaces (m)
;  2082 um                               m/s                57 A  East-west (u) wind [m/s]
; 2083 vm                               m/s                57 A  North-south (v) wind [m/s]


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
