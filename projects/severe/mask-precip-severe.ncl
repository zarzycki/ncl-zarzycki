load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "helicity.ncl"

begin

f=addfile("/glade/scratch/zarzycki/jun.nc","w")

PRECT=f->PRECT
SIGTOR=f->SIGTOR

mmdaythresh=50.
thresh = mmdaythresh*1.15741e-8

ntimes=120
PRECT(0:ntimes-2,:,:)=PRECT(1:ntimes-1,:,:)
PRECT(ntimes-1,:,:)=0.0

SIGTOR=where(PRECT.ge.thresh,SIGTOR,0.0)

f->SIGTOR_MASK = SIGTOR




end
