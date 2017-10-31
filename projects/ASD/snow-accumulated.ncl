load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin

LWE=11.0
ms_to_inhr=141732.

f = addfile("/glade/scratch/zarzycki/snow-sub.nc","w")

PRECBSN = f->PRECBSN

PRECBSN = PRECBSN*6*ms_to_inhr*LWE
printVarSummary(PRECBSN)

PRECBSN_SUM = dim_cumsum_n_Wrap(PRECBSN,2,0)

f->PRECBSN_SUM=PRECBSN_SUM

end
