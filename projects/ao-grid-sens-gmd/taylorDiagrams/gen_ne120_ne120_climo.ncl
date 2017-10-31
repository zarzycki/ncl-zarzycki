;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "~/ncl/functions/clmMonTLU.ncl"
;========================================================
begin

RGRD_dir  = "/glade/p/work/zarzycki/atm-ocn-coupling/climo/"
RGRD_file = "ne120_ne120_climo.nc"
RGRD_path = RGRD_dir +"/"+  RGRD_file


theseVars=(/"PRECC","PRECL","FLUT","U","V","T","RELHUM","PS","PSL","LWCF","SWCF","TMQ"/)

do z = 0,dimsizes(theseVars)-1

if(z .eq. 0) then
  print("Deleting "+RGRD_path)
  system("/bin/rm -f "+RGRD_path)      ; delete any pre-existing file
end if

thisVar = theseVars(z)

SE_dir   = "/glade/p/cgd/ccr/f.e13.FAMIPC5.ne120_ne120.1979_2012.002/atm/proc/tseries/monthly"
SE_file = "f.e13.FAMIPC5.ne120_ne120.1979_2012.002.cam.h0."+thisVar+".197901-201212.nc"
wgt_file="/glade/p/work/zarzycki/atm-ocn-coupling/climo/ne120np4_to_0.25deg.nc"

sfile    = addfile(SE_dir +"/"+ SE_file,"r")


var_in_orig   = getfilevarnames( sfile )
var_in = str_left_strip(str_sub_str(var_in_orig,"/"," "))
nvar_in  = dimsizes(var_in)
print(var_in)

var_in_exclude = (/"lat", "lon", "area"/)

var_in_copy = (/"time_bnds", "date_written", "time_written"/)  

;---Specify a list of variables to be regridded

setfileoption("nc","Format","LargeFile")
if (isfilepresent(RGRD_path))
  rgrd_nc   = addfile(RGRD_path, "w")  ; open for writing
  var_out        = thisVar     ; to be regridded
else
  rgrd_nc   = addfile(RGRD_path, "c")  ; open for writing
  var_out        = "All_Variables"     ; to be regridded
end if


;var_out        = (/"CLDTOT","PRECT","OMEGA500","OMEGA850","PRECL","PRECC"/)

;---Read from the weight file the method used to derive the remap weights
    fWGT           = addfile(wgt_file, "r")

    map_method     = fWGT@map_method
    dst_grid_dims  = fWGT->dst_grid_dims
    dst_mlon       = dst_grid_dims(0)
    dst_nlat       = dst_grid_dims(1)
    dst_lat        = fWGT->yc_b(::dst_mlon)
    dst_lon        = fWGT->xc_b(:dst_mlon-1)

;---Generate or read the latitudinal weights
     wgt  = latRegWgt(dst_lat, "double", 0)
     wgt!0= "lat"

;---Loop over all variables; regrid appropriate variables; write to netCDF
;   *** Use the 'simple' approach to writing netCDF
;   *** This can be SLOW for big files     

    ;system("/bin/rm -f "+RGRD_path)      ; delete any pre-existing file
    

    global    = True
    global@separator2= "---------------------------------------"
    copy_VarAtts(sfile, global)
    global@separator1= "------- SOURCE FILE ATTRIBUTES --------"

    if (isatt(sfile,"title")) then
        global@TITLE = "REMAPPED: "+sfile@title
    end if
    global@remap         = "NCL: ESMF_regrid_with_weights"
    global@remap_method  = map_method
    global@creation_date = systemfunc("date")
    
    fileattdef( rgrd_nc, global )        ; copy file attributes

    Opt_RGRD  = True
    filedimdef(rgrd_nc,"time",-1,True)   ; force an unlimited dimension

    rgrd_nc->gw = wgt

    do nv=0,nvar_in-1
       print("Var number: "+nv+" of: "+nvar_in)
       if (.not.any(var_in(nv).eq.var_in_exclude)) then
           rank_in = dimsizes(getfilevardimsizes(sfile, var_in(nv)))

           if (rank_in.eq.1 .or. any(var_in(nv).eq.var_in_copy)) then
               rgrd_nc->$var_in(nv)$ = sfile->$var_in(nv)$
           else
               if (rank_in.ge.2 .and.  \   (time, ncol) ,  (time, lev, ncol)
                  (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then

                   
                   ;work = sfile->PRECC(0:11,:)

                   if(dimsizes(dimsizes(sfile->$var_in(nv)$)) .eq. 2) then
                     work = sfile->$var_in(nv)$(12:251,:)
                     vClm = clmMonTU( work )
                   else
                     work = sfile->$var_in(nv)$(12:251,:,:)
                     vClm = clmMonTLU( work )
                   end if

                   delete(work)

                   var_regrid  = ESMF_regrid_with_weights(vClm,wgt_file,Opt_RGRD)

                   delete(vClm)

                   rgrd_nc->$var_in(nv)$   = var_regrid

                   delete([/var_regrid/])
               end if
           end if
       end if
    end do

delete(thisVar)

end do

end

