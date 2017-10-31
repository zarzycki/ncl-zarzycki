;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================

begin
  nrows = 5
  ncols = 7
  ave   = 0.0
  std   = 5.0
  xf    = random_normal (ave,std, (/nrows,ncols/))  ; float  
  xi    = round (xf, 3)                             ; integer
  xd    = todouble(xf)

  xf@_FillValue = 1e36
  xf(1,1) = xf@_FillValue
  xf(3,3) = xf@_FillValue

  option        = True
  option@row    = False
  option@tspace = 0

  print(xf)

  write_matrix (xf, "7f7.2", False)
end
