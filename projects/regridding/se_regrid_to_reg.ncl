;----------------------------------------------------------------------
; ESMF_unstruct_to_0.25deg.ncl
;
; This is an NCL/ESMF template file for regridding from an 
; unstructured grid to a 0.25 degree grid. It uses ESMF_regrid
; to do the regridding.
;
; This script can be easily modified to do use something other than
; a 0.25 degree grid: "1x1", "G64", "5deg", etc.
;
; The unstructured grid is assumed to be contained in a NetCDF file.
; 
; Search for lines with ";;---Change (likely)" or ";;---Change (maybe)".
; These are the lines you will likely or maybe have to change.
;
; Of course, you'll probably want to change other aspects of this
; code, like the options for plotting (titles, colors, etc).
;
; For more information on ESMF_regrid, see: 
;
;    http://www.ncl.ucar.edu/Document/Functions/ESMF/ESMF_regrid.shtml
;----------------------------------------------------------------------
; This example uses the ESMF application "ESMF_RegridWeightGen" to 
; generate the weights.
;
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in 
; NCL V6.1.0-beta and later.
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

    src_file = "/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/USGS-gtopo30_1.9x2.5_smooth500-50_ne16np4_c050602.nc"
    var_name = "PHIS"
    write_output=True

;---Data file containing source grid
    
    sfile    = addfile(src_file,"r")

;---Get variable to regrid
    var      = sfile->$var_name$(:)
    src_lat  = sfile->lat
    src_lon  = sfile->lon

;---Set up regridding options
    Opt                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
    Opt@SrcFileName = "/glade/scratch/zarzycki/srcgrid.nc"
    Opt@DstFileName = "/glade/scratch/zarzycki/dstgrid.nc"
    Opt@InterpMethod     = "patch"        ;;---Change (maybe)
    Opt@WgtFileName      = "/glade/scratch/zarzycki/north30x2_to_0.5x0.5_patch.nc"

    Opt@SrcGridLat       = src_lat
    Opt@SrcGridLon       = src_lon
    Opt@SrcRegional      = False            ;;--Change (maybe)
    Opt@SrcInputFileName = src_file          ; optional, but good idea
    Opt@SrcMask2D        = where(.not.ismissing(var),1,0) ; Necessary if has
                                                          ; missing values.
    ;regRes = 0.1
    regRes = 0.5

    Opt@DstGridType      = tostring(regRes)+"deg"
    Opt@DstTitle         = "World Grid 0.5 degree resolution"
    Opt@DstLLCorner      = (/-90.0d,   0.0d /)      ;;--Change (maybe)
    Opt@DstURCorner      = (/ 90.0d, 359.5d /)      ;;--Change (maybe)

    Opt@ForceOverwrite   = True
    Opt@Debug            = True
    Opt@PrintTimings     = True

    var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding
    printVarSummary(var_regrid)

if (write_output) then
   system("/bin/rm -f simple.nc")   ; remove any pre-existing file
   ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

   fAtt               = True            ; assign file attributes
   fAtt@title         = "NCL Simple Approach to netCDF Creation"
   fAtt@source_file   =  "original-file.nc"
   fAtt@Conventions   = "None"
   fAtt@creation_date = systemfunc ("date")
   fileattdef( ncdf, fAtt )            ; copy file attributes

   filedimdef(ncdf,"time",-1,True) 

   ncdf->var_regrid  = var_regrid           
end if


end
