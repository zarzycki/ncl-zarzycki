;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
load "/glade/u/home/zarzycki/ncl/functions/calc_gpi.ncl"
;========================================================
begin

;year=1986
;grid="atl30x8"
;month="06"

print(year)
print(month)
outputdir="/glade/scratch/zarzycki/AMIPmonthly/"+year+"/"

;wcStrt     = systemfunc("date")
;wcStrtGetData = systemfunc("date")

;========================
; get list of all files and open as "one big file"
;========================                             
all_files = systemfunc ("ls /glade/p/p05010048/zarzycki/"+grid+"amip/"+year+"/*.cam.h3."+year+"-"+month+"*")
;all_files = systemfunc ("ls /glade/scratch/zarzycki/h3files/"+grid+"/"+year+"/*.cam.h3."+year+"-"+month+"*")
fall      = addfiles (all_files, "r")
;========================
; choose how files are combined and read in variable across files
;========================  
     ListSetType (fall, "cat")             ; concatenate or "merge" (default)
     
     dims = dimsizes(fall[:]->T)
     numdims = dimsizes(dims)
     if (numdims .eq. 4) then
       ntimes = dims(0)
       nlevs = dims(1)
       nlats = dims(2)
       nlons = dims(3)
       lev = fall[0]->lev
       lat = fall[0]->lat
       lon = fall[0]->lon
       Tavg_ = new((/nlevs,nlats,nlons/),"float")
       Uavg_ = new((/nlevs,nlats,nlons/),"float")
       Vavg_ = new((/nlevs,nlats,nlons/),"float")
       Qavg_ = new((/nlevs,nlats,nlons/),"float")
       Zavg_ = new((/nlevs,nlats,nlons/),"float")
       UTavg_ = new((/nlevs,nlats,nlons/),"float")
       VTavg_ = new((/nlevs,nlats,nlons/),"float")
       TTavg_ = new((/nlevs,nlats,nlons/),"float")
       UUavg_ = new((/nlevs,nlats,nlons/),"float")
       VUavg_ = new((/nlevs,nlats,nlons/),"float")
       VVavg_ = new((/nlevs,nlats,nlons/),"float")
       ZZavg_ = new((/nlevs,nlats,nlons/),"float")
       VZavg_ = new((/nlevs,nlats,nlons/),"float")
       QQavg_ = new((/nlevs,nlats,nlons/),"float")
       VQavg_ = new((/nlevs,nlats,nlons/),"float")
       TQavg_ = new((/nlevs,nlats,nlons/),"float")
       UQavg_ = new((/nlevs,nlats,nlons/),"float")
       UZavg_ = new((/nlevs,nlats,nlons/),"float")
     else
       ntimes = dims(0)
       nlevs = dims(1)
       ncol = dims(2)    
     end if
     
do i = 0,nlevs-1     

     print("Doing level number "+(i+1)+" of "+nlevs)
     print("Getting data")
     T    = fall[:]->T(:,i,:,:)                     ; note syntax [:]
     ;print("Getting U")
     U    = fall[:]->U(:,i,:,:)                     ; note syntax [:]
     ;print("Getting V")
     V    = fall[:]->V(:,i,:,:)                     ; note syntax [:]
     ;print("Getting Q")
     Q    = fall[:]->Q(:,i,:,:)                     ; note syntax [:]
     ;print("Getting Z")
     Z    = fall[:]->Z3(:,i,:,:)                    ; note syntax [:]

;wallClockElapseTime(wcStrtGetData, "Getting Data", 0)
;wcStrtDoMath = systemfunc("date")

     print("Doing eddy quantities")
     
     UT = tofloat(T*U)
     copy_VarCoords(U,UT)
     UTavg = dim_avg_n_Wrap(UT,0)
     delete(UT)
     
     ;Meridional heat transport
     VT = tofloat(T*V)
     copy_VarCoords(V,VT)
     VTavg = dim_avg_n_Wrap(VT,0)
     delete(VT)
     
     TT = tofloat(T*T)
     copy_VarCoords(T,TT)
     TTavg = dim_avg_n_Wrap(TT,0)
     delete(TT)
     
     ; Zonal velocity squared
     UU = tofloat(U*U)
     copy_VarCoords(U,UU)
     UUavg = dim_avg_n_Wrap(UU,0)
     delete(UU)   
     
     ; Meridional flux of zonal momentum
     VU = tofloat(V*U)
     copy_VarCoords(V,VU)
     VUavg = dim_avg_n_Wrap(VU,0)
     delete(VU)
     
     ; Meridional velocity squared
     VV = tofloat(V*V)
     copy_VarCoords(V,VV)
     VVavg = dim_avg_n_Wrap(VV,0)
     delete(VV)
     
     ; Eddy height variance
     ZZ = tofloat(Z*Z)
     copy_VarCoords(Z,ZZ)
     ZZavg = dim_avg_n_Wrap(ZZ,0)
     delete(ZZ) 
     
     ; Meridional transport of geopotential energy
     VZ = tofloat(V*Z)
     copy_VarCoords(V,VZ)
     VZavg = dim_avg_n_Wrap(VZ,0)
     delete(VZ)  
     
     ; Eddy moisture variance
     QQ = tofloat(Q*Q)
     copy_VarCoords(Q,QQ)
     QQavg = dim_avg_n_Wrap(QQ,0)
     delete(QQ)
     
     ; Meridional water transport
     VQ = tofloat(V*Q)
     copy_VarCoords(V,VQ)
     VQavg = dim_avg_n_Wrap(VQ,0)
     delete(VQ)
     
     TQ = tofloat(T*Q)
     copy_VarCoords(T,TQ)
     TQavg = dim_avg_n_Wrap(TQ,0)
     delete(TQ)
     
     UQ = tofloat(U*Q)
     copy_VarCoords(U,UQ)
     UQavg = dim_avg_n_Wrap(UQ,0)
     delete(UQ)
     
     UZ = tofloat(U*Z)
     copy_VarCoords(U,UZ)
     UZavg = dim_avg_n_Wrap(UZ,0)
     delete(UZ)

     
;wallClockElapseTime(wcStrtDoMath, "Doing Math", 0)
;wcStrtAvgData = systemfunc("date")
print("Doing averages")
Uavg = dim_avg_n_Wrap(U,0)
Vavg = dim_avg_n_Wrap(V,0)
Tavg = dim_avg_n_Wrap(T,0)
Qavg = dim_avg_n_Wrap(Q,0)
Zavg = dim_avg_n_Wrap(Z,0)

Uavg_(i,:,:) = Uavg
Vavg_(i,:,:) = Vavg
Tavg_(i,:,:) = Tavg
Qavg_(i,:,:) = Qavg
Zavg_(i,:,:) = Zavg

UTavg_(i,:,:) = UTavg
VTavg_(i,:,:) = VTavg
TTavg_(i,:,:) = TTavg
UUavg_(i,:,:) = UUavg
VUavg_(i,:,:) = VUavg
VVavg_(i,:,:) = VVavg
ZZavg_(i,:,:) = ZZavg
VZavg_(i,:,:) = VZavg
QQavg_(i,:,:) = QQavg
VQavg_(i,:,:) = VQavg
TQavg_(i,:,:) = TQavg
UQavg_(i,:,:) = UQavg
UZavg_(i,:,:) = UZavg

delete(U)
delete(T)
delete(V)
delete(Z)
delete(Q)
delete(Uavg)
delete(Vavg)
delete(Tavg)
delete(Qavg)
delete(Zavg)
delete(UTavg)
delete(VTavg)
delete(TTavg)
delete(UUavg)
delete(VUavg)
delete(VVavg)
delete(ZZavg)
delete(VZavg)
delete(QQavg)
delete(VQavg)
delete(TQavg)
delete(UQavg)
delete(UZavg)

;list_vars()

end do

Uavg_!0 = "lev"
Uavg_!1 = "lat"
Uavg_!2 = "lon"
Uavg_&lev = lev
Uavg_&lat = lat
Uavg_&lon = lon

copy_VarCoords(Uavg_,Vavg_)
copy_VarCoords(Uavg_,Tavg_)
copy_VarCoords(Uavg_,Zavg_)
copy_VarCoords(Uavg_,Qavg_)

copy_VarCoords(Uavg_,UTavg_)
copy_VarCoords(Uavg_,VTavg_)
copy_VarCoords(Uavg_,TTavg_)
copy_VarCoords(Uavg_,UUavg_)
copy_VarCoords(Uavg_,VUavg_)
copy_VarCoords(Uavg_,VVavg_)
copy_VarCoords(Uavg_,ZZavg_)
copy_VarCoords(Uavg_,VZavg_)
copy_VarCoords(Uavg_,QQavg_)
copy_VarCoords(Uavg_,VQavg_)
copy_VarCoords(Uavg_,TQavg_)
copy_VarCoords(Uavg_,UQavg_)
copy_VarCoords(Uavg_,UZavg_)


;wallClockElapseTime(wcStrtAvgData, "Averaging Data", 0)
;wcStrtWrite = systemfunc("date")

outputfilename=outputdir+"/"+grid+"_monthlyavg_"+year+month+"_3D.nc"
system("mkdir -p "+outputdir)
system("/bin/rm -f "+outputfilename)   ; remove any pre-existing file
ncdf = addfile(outputfilename,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->U = Uavg_     
ncdf->V = Vavg_
ncdf->T = Tavg_
ncdf->Z3 = Zavg_
ncdf->Q = Qavg_
ncdf->UT = UTavg_
ncdf->VT = VTavg_
ncdf->TT = TTavg_
ncdf->UU = UUavg_
ncdf->VQ = VQavg_
ncdf->VZ = VZavg_
ncdf->VU = VUavg_
ncdf->ZZ = ZZavg_
ncdf->VV = VVavg_
ncdf->QQ = QQavg_
ncdf->TT = TTavg_
ncdf->TQ = TQavg_
ncdf->UQ = UQavg_
ncdf->UZ = UZavg_

print("Fixing time dimension because NCO does it and I'm lazy")
system("ncecat -O -u time "+outputfilename+" "+grid+year+month+"temp.nc")
system("mv "+grid+year+month+"temp.nc "+outputfilename)
print("Done correcting...")

;wallClockElapseTime(wcStrtWrite, "Writing data", 0)
end
