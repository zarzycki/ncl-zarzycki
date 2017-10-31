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

    srcGridName = "src_SCRIP.nc"     ; "src_ESMF.nc"
    sfile = addfile(srcGridName,"r")

    nodeCoords=sfile->nodeCoords
    elementConn=sfile->elementConn
    numElementConn=sfile->numElementConn
    centerCoords=sfile->centerCoords
    elementConn=sfile->elementConn

    testIx = 4



end
