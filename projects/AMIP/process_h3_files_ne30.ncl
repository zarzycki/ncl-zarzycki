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
;grid="ne30"
;month="01"

print(year)
print(month)
outputdir="/glade/scratch/zarzycki/AMIPmonthly/"+year+"/"

;wcStrt     = systemfunc("date")
;wcStrtGetData = systemfunc("date")

;========================
; get list of all files and open as "one big file"
;========================                             
all_files = systemfunc ("ls /glade/scratch/zarzycki/h3files/"+grid+"/"+year+"/*.cam.h3."+year+"-"+month+"*")
fall      = addfiles (all_files, "r")
;========================
; choose how files are combined and read in variable across files
;========================  
     ListSetType (fall, "cat")             ; concatenate or "merge" (default)
     

     
     print("Getting T")
     T    = fall[:]->T                     ; note syntax [:]
     print("Getting U")
     U    = fall[:]->U                     ; note syntax [:]
     print("Getting V")
     V    = fall[:]->V                     ; note syntax [:]
     print("Getting Q")
     Q    = fall[:]->Q                     ; note syntax [:]
     print("Getting Z")
     Z    = fall[:]->Z3                    ; note syntax [:]

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
     
     TT = tofloat(T*T)
     copy_VarCoords(T,TT)
     TTavg = dim_avg_n_Wrap(TT,0)
     delete(TT)
    
     
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

delete(U)
delete(T)
delete(V)
delete(Z)
delete(Q)


;wallClockElapseTime(wcStrtAvgData, "Averaging Data", 0)
;wcStrtWrite = systemfunc("date")

outputfilename=outputdir+"/"+grid+"_monthlyavg_"+year+month+"_3D.nc"
system("mkdir -p "+outputdir)
system("/bin/rm -f "+outputfilename)   ; remove any pre-existing file
ncdf = addfile(outputfilename,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->U = Uavg     
ncdf->V = Vavg
ncdf->T = Tavg
ncdf->Z3 = Zavg
ncdf->Q = Qavg
ncdf->UT = UTavg
ncdf->VT = VTavg
ncdf->TT = TTavg
ncdf->UU = UUavg
ncdf->VQ = VQavg
ncdf->VZ = VZavg
ncdf->VU = VUavg
ncdf->ZZ = ZZavg
ncdf->VV = VVavg
ncdf->QQ = QQavg
ncdf->TT = TTavg
ncdf->TQ = TQavg
ncdf->UQ = UQavg
ncdf->UZ = UZavg

print("Fixing time dimension because NCO does it and I'm lazy")
system("ncecat -O -u time "+outputfilename+" "+grid+year+month+"temp.nc")
system("mv "+grid+year+month+"temp.nc "+outputfilename)
print("Done correcting...")

;wallClockElapseTime(wcStrtWrite, "Writing data", 0)
end
