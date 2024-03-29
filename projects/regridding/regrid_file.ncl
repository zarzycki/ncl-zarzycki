;----------------------------------------------------------------------
; This example uses ESMF regridding software to regrid from an
; unstructured SE grid to a CAM finite volume grid (96 x 144).
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

wgt_file = "/glade/scratch/zarzycki/ne30_to_1x1_patch.nc"
SE_dir   = "/glade/p/cesmdata/inputdata/atm/cam/topo/"
SE_file = "USGS-gtopo30_ne30np4_16xdel2-PFC-consistentSGH.nc"
RGRD_dir  = "/glade/scratch/zarzycki/"
RGRD_file = SE_file+"_regrid.nc"

sfile    = addfile(SE_dir +"/"+ SE_file,"r")
RGRD_path = RGRD_dir +"/"+  RGRD_file

var_in   = getfilevarnames( sfile )
nvar_in  = dimsizes(var_in)
print(var_in)

var_in_exclude = (/"lat", "lon", "area"/)  

var_in_copy = (/"time_bnds", "date_written", "time_written"/)  

;---Specify a list of variables to be regridded
;var_out        = "All_Variables"     ; to be regridded
var_out = (/"PHIS"/)
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

    system("/bin/rm -f "+RGRD_path)      ; delete any pre-existing file
    rgrd_nc   = addfile(RGRD_path, "c")  ; open for writing

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

           if (rank_in.eq.0 .or. any(var_in(nv).eq.var_in_copy)) then
               rgrd_nc->$var_in(nv)$ = sfile->$var_in(nv)$
           else
               if (rank_in.ge.1 .and.  \   (time, ncol) ,  (time, lev, ncol)
                  (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then

                   work = sfile->$var_in(nv)$
                   var_regrid  = ESMF_regrid_with_weights(work,wgt_file,Opt_RGRD)
                 ;;printVarSummary(var_regrid)

                   rgrd_nc->$var_in(nv)$   = var_regrid

                   delete([/var_regrid, work/])
               end if
           end if
       end if
    end do


