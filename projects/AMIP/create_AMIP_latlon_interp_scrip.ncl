;========================================================
; GPI correlations
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

filesdir = "/glade/scratch/zarzycki/AMIP_monthly/"
srcFileName = filesdir+"monavg_h0.1982-01.nc"

;---Output (and input) files
    srcGridName = "AMIP_scrip.nc"

;----------------------------------------------------------------------
; Convert original source NCEP grid to a SCRIP convention file.
;----------------------------------------------------------------------
    src_file = addfile(srcFileName,"r")
    temp     = src_file->TREFHT(0,:,:)

    Opt                = True
;    Opt@Mask2D         = where(.not.ismissing(temp),1,0)
    Opt@ForceOverwrite = True
    Opt@PrintTimings   = True
    Opt@Title          = "Refined AMIP lat/lon grid"

    rectilinear_to_SCRIP(srcGridName,temp&lat,temp&lon,Opt)

;---Clean up
    delete(Opt)

end
