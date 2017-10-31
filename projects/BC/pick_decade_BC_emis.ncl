;----------------------------------------------------------------------
; This example uses ESMF regridding software to regrid from an
; unstructured SE grid to a CAM finite volume grid (96 x 144).
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

decade="1980"
path_to_BC_files="/glade/u/home/zarzycki/work/BC_emis_files/"
;orig_file="ar5_mam3_bc_surf_1850-2005_c090804.nc"
orig_file="ar5_mam3_bc_elev_1850-2005_c090804.nc"
new_file=orig_file+"_"+decade+".nc"
system("cp "+path_to_BC_files+"/"+orig_file+" "+path_to_BC_files+"/"+new_file)

ofile=addfile(path_to_BC_files+"/"+orig_file,"w")
sfile=addfile(path_to_BC_files+"/"+new_file,"w")



var_in   = getfilevarnames( sfile )
nvar_in  = dimsizes(var_in)
print(var_in)

var_in_exclude = (/"lat", "lon", "date","altitude","altitude_int"/)  

var_in_copy = (/"time_bnds", "date_written", "time_written"/)

date=ofile->date
totmonths=dimsizes(date)
print(totmonths)
numyears = totmonths/12
print(numyears)
stval = toint(decade+"0115")
stinx       = closest_val(stval,date)
enval = toint(decade+"1215")
eninx       = closest_val(enval,date)
print(stinx+" "+eninx)
print(date(stinx)+" "+date(eninx))


;---Specify a list of variables to be regridded
var_out        = "All_Variables"     ; to be regridded
;var_out        = (/"CLDTOT","PRECT","OMEGA500","OMEGA850","PRECL","PRECC"/)


do nv=0,nvar_in-1
  print("Var number: "+nv+" of: "+nvar_in)
  if (.not.any(var_in(nv).eq.var_in_exclude)) then
    rank_in = dimsizes(getfilevardimsizes(ofile, var_in(nv)))
    if rank_in.eq.3 then
      work = ofile->$var_in(nv)$(stinx:eninx,:,:)
      fullArr = sfile->$var_in(nv)$
      do yr = 0,numyears-1
        fullArr(yr*12:yr*12+11,:,:) = work
      end do
    else if rank_in.eq.4 then
      work = ofile->$var_in(nv)$(stinx:eninx,:,:,:)
      fullArr = sfile->$var_in(nv)$
      do yr = 0,numyears-1
        fullArr(yr*12:yr*12+11,:,:,:) = work
      end do
    else
      print("invalid rank eq: "+rank_in)
      exit
    end if
    end if
    sfile->$var_in(nv)$ = fullArr
    delete([/work,fullArr/])
  end if
end do


