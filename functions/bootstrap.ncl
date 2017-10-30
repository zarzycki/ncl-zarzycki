load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/lib.percentiles.ncl"

undef ( "bootstrap_testmeans" )
function bootstrap_testmeans( \
  X1[*]           : numeric, \
  X2[*]           : numeric, \
  nReps           : numeric, \
  alpha           : numeric \
)
local None

begin

debug=False

;Remove missing values from X1 and X2
ix1 = ind(.not.ismissing(X1))
x1 = X1(ix1)
ix2 = ind(.not.ismissing(X2))
x2 = X2(ix2)

dateSecSeed = toint(systemfunc("date +%s"))
random_setallseed(dateSecSeed,toint(ceil(dateSecSeed/21)))

trueMean = avg(x1)-avg(x2)

n1 = dimsizes(x1)
n2 = dimsizes(x2)

bootstrapStat = new(toint(nReps),"float")
bootstrapStat = 0.0

sampX1 = new(n1,"float")
sampX2 = new(n2,"float")

eps = 1e-5 ;needed so that if rand = 1, ncl doesn't throw out of bounds error when indexing

do i = 0,nReps-1
  randX1 = toint(floor(n1*random_uniform(0.,1.-eps,n1)))
  randX2 = toint(floor(n2*random_uniform(0.,1.-eps,n2)))
  if (debug) then
    print(min(randX1)+" "+max(randX1))
    print(min(randX2)+" "+max(randX2))
    print(n1+" "+n2)
  end if
  sampX1 = x1(randX1)
  sampX2 = x2(randX2)
  bootstrapStat(i) = avg(sampX1)-avg(sampX2)
end do

;print("Sample mean: "+trueMean)
;print("Bootstrap mean: "+avg(bootstrapStat))

;opt = True
;opt@PrintStat = True
;bootStats = stat_dispersion(bootstrapStat,opt)

pctiles = percent_to_value(bootstrapStat,(/100*(alpha/2),100*(1.0-(alpha/2))/))
;print(pctiles)

;if(pctiles(0) .lt. 0 .and. pctiles(1) .gt. 0) then
;  print("means not different")
;else
;  print("H0 is rejected, means different")
;end if

return(pctiles)

end
