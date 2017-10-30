;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; percentiles.ncl
;; Carl Schreck (carl@cicsnc.org)
;; August 2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; percent_to_value
;; percent_to_value_2d
;; value_to_percent
;; signif_diff_percentiles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;load "/home/carl/lib/print_clock.ncl"


undef ( "percent_to_value" )
function percent_to_value( \
  i_data           : numeric, \
  i_percentiles[*] : numeric  \
)
local None
begin

  retVal = new( dimsizes(i_percentiles), float )

  data1d = ndtooned( i_data )
  notMissing = data1d( ind(.not.ismissing(data1d) ) )

  qsort(notMissing)

  do p = 0, dimsizes(i_percentiles)-1
;   pInd = round( i_percentiles(p) * .01 * dimsizes(notMissing) + 0.5, 3 ) -1
;   pInd = where( pInd.ge.dimsizes(notMissing), dimsizes(notMissing)-1, pInd )
    floatInd = i_percentiles(p) * .01 * dimsizes(notMissing) - 0.5
    floorInd = toint( floor(floatInd) )
    floorInd = where( floorInd.lt.0, 0, floorInd )
    ceilInd = toint( ceil(floatInd) )
    ceilInd = where( ceilInd.ge.dimsizes(notMissing), \
        dimsizes(notMissing)-1, ceilInd )
;   print(pInd + " " + dimsizes(notMissing))
    if( ceilInd.eq.floorInd ) then
      retVal(p) = notMissing(floorInd)
    else
      retVal(p) = notMissing(floorInd) * ( ceilInd - floatInd ) \
          + notMissing(ceilInd) * ( floatInd - floorInd )
    end if
  end do

  return(retVal)
end ; percent_to_value


undef ( "percent_to_value_2d" )
function percent_to_value_2d( \
  i_data[*][*][*]  : numeric, \
  i_percentile[1]  : numeric  \
)
local None
begin

  dims = dimsizes(i_data)
  sorted = i_data
  ip = dim_pqsort_n( sorted, 2, 0 )

  pInd = round( i_percentile * .01 * dims(0) + 0.5, 3 ) -1
  pInd = where( pInd.ge.dims(0), dims(0)-1, pInd )
  retVal = sorted(pInd,:,:)
  copy_VarAtts( i_data, retVal )
  copy_VarCoords( i_data(0,:,:), retVal )

  return(retVal)
end ; percent_to_value_2d


undef ( "value_to_percent" )
function value_to_percent( \
  i_data      : numeric, \
  i_values[*] : numeric  \
)
local None
begin

  retVal = new( dimsizes(i_values), float )

  data1d = ndtooned( i_data )
  notMissing = data1d( ind(.not.ismissing(data1d) ) )

  qsort(notMissing)

  do v = 0, dimsizes(i_values)-1
    vInd = 1 + max( ind( notMissing.le.i_values(v) ) )
    if( ismissing(vInd) ) then
      retVal(v) = 0
    else
      retVal(v) = ( vInd - 0.5 ) * 100. / ( dimsizes(notMissing) )
    end if
  end do

  return(retVal)
end ; value_to_percent


undef ( "signif_diff_percentiles" )
function signif_diff_percentiles( \
  i_dataA[*]      : numeric, \
  i_dataB[*]      : numeric, \
  i_percentiles[*] : numeric, \
  i_nTests[1]     : integer  \
)
local None
begin

  nA = dimsizes(i_dataA)
  nB = dimsizes(i_dataB)

  pValue = 0. * i_percentiles

  do iTest = 0, i_nTests-1

    randIndA = toint( floor( random_uniform( 0, nA, nA ) ) )
    randIndB = toint( floor( random_uniform( 0, nB, nB ) ) )

    valueA = percent_to_value( i_dataA(randIndA), i_percentiles )
    valueB = percent_to_value( i_dataB(randIndB), i_percentiles )

    pValue = pValue + where( valueA.gt.valueB, 1, 0 )
  end do
  pValue = pValue / i_nTests

  retVal = -1 + ( 2 * dim_max_n( (/ (pValue), (1-pValue) /), 0 ) )
  retVal = pValue
  
  return(retVal)

end ; signif_diff_percentiles
