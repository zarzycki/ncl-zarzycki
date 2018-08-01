;----------------------------------------------------------------------
; This example uses ESMF regridding software to regrid from an
; unstructured SE grid to a CAM finite volume grid (96 x 144).
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

;---Data file containing source grid and variables
;    SE_file  = "CHEY.VR28.NATL.EXT.CAM5.4CLM5.0.tau900.cam.h3.1985-12-21-00000.nc"
    sfile    = addfile(SE_file,"r")

    RGRD_file = SE_file+"_regrid.nc"

;---Get all variables on the SE file
    var_in   = getfilevarnames( sfile )
    nvar_in  = dimsizes(var_in)
    print(var_in)

;---Specify a list of 1D variables on the source SE file that should NOT be copied
;    var_in_exclude = (/"lat", "lon", "area"/)

;---Specify a list of variables on the source SE file that should be directly copied
    var_in_copy = (/"time_bnds", "date_written", "time_written"/)

;---Specify a list of variables to be regridded
    var_out        = "All_Variables"     ; to be regridded
   ;var_out        = (/"T","U10","V10")  ; selected variables

;---Loop over all variables; regrid appropriate variables; write to netCDF

    system("/bin/rm -f "+RGRD_file)      ; delete any pre-existing file
    rgrd_nc   = addfile(RGRD_file, "c")  ; open for writing

    setfileoption(rgrd_nc,"DefineMode",True)

    global    = True
    copy_VarAtts(sfile, global)
    
    fileattdef( rgrd_nc, global )        ; copy file attributes

    dimNames = (/"ncol","time", "nbnd", "chars", "lev","hyam","hybm","ilev","hyai","hybi"/)  
	  dimSizes = (/ 155981,-1   ,  2, 8, 32, 32, 32, 33, 33, 33 /) 
	  dimUnlim = (/ False,True , False, False, False, False, False , False, False, False/)   
	  filedimdef(rgrd_nc,dimNames,dimSizes,dimUnlim)

    ;===================================================================
    ; predefine the the dimensionality of the variables to be written out
    ;===================================================================
    ; Here we are using NCL functions to facilitate defining 
    ; each variable's dimension name(s) and type. 
    ; The following could be replaced with explicit, user defined dimension 
    ; names different from those associated with the variable in memory. 
    ; Say, PS(time,lat,lon) in the NCL script. They could be redefined for the file via: 
    ; filevardef(fout, "PS"   ,typeof(PS) ,(/"TIME","latitude","longitude"/)) 
    ;===================================================================
;       filevardef(fout, "time" ,typeof(time),getvardims(time)) 
;       filevardef(fout, "lev"  ,typeof(lev),getvardims(lev) )                           
;       filevardef(fout, "lat"  ,typeof(lat),getvardims(lat))                          
;       filevardef(fout, "lon"  ,typeof(lon),getvardims(lon))                          
;       filevardef(fout, "T"    ,typeof(T)  ,getvardims(T))    
;       filevardef(fout, "PS"   ,typeof(PS) ,getvardims(PS))          
;       filevardef(fout, "TOPOG",typeof(ORO),getvardims(ORO))  ; variable name on the file              


do nv=0,nvar_in-1
  print("defining..." +var_in(nv))
  rank_in = dimsizes(getfilevardimsizes(sfile, var_in(nv)))
  VARTYPE=getfilevartypes(sfile,var_in(nv))
  VARDIMS=getfilevardims(sfile,var_in(nv))
  if (rank_in.eq.1 .or. any(var_in(nv).eq.var_in_copy)) then
    filevardef(rgrd_nc, var_in(nv) ,VARTYPE,VARDIMS) 
  else
    if (rank_in.ge.2 .and.  \   (time, ncol) ,  (time, lev, ncol)
      (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then
      filevardef(rgrd_nc, var_in(nv) , "float" , VARDIMS) 
    end if
  end if
  delete([/VARTYPE, VARDIMS/])
end do

;do nv=0,nvar_in-1
;  print("copy attributes from "+var_in(nv))
;  filevarattdef(rgrd_nc,var_in(nv),sfile->$var_in(nv)$)
;end do

do nv=0,nvar_in-1
  print("copy attributes from "+var_in(nv))
  att_names =getfilevaratts(sfile,var_in(nv))
  tmp=0
  if(.not.all(ismissing(att_names)))
    do i = dimsizes(att_names)-1,0,1
      tmp@$att_names(i)$ = sfile->$var_in(nv)$@$att_names(i)$
    end do
    filevarattdef(rgrd_nc,var_in(nv),tmp)
  end if
  delete(tmp)
  delete(att_names)
end do

setfileoption(rgrd_nc,"DefineMode",False)

do nv=0,nvar_in-1
  rank_in = dimsizes(getfilevardimsizes(sfile, var_in(nv)))
  print("Writing... "+var_in(nv))
  if (rank_in.eq.1 .or. any(var_in(nv).eq.var_in_copy)) then
    rgrd_nc->$var_in(nv)$ = sfile->$var_in(nv)$
  else
    if (rank_in.ge.2 .and.  \   (time, ncol) ,  (time, lev, ncol)
      (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then

      print("... getting var.")
      work = sfile->$var_in(nv)$
      print("... converting var.")
      var_regrid  = tofloat(work)
      copy_VarMeta(work,var_regrid)
      print("... writing var.")
      ;rgrd_nc->$var_in(nv)$   = var_regrid
      rgrd_nc->$var_in(nv)$   = (/var_regrid/)

      delete([/var_regrid, work/])
    end if
  end if
end do

