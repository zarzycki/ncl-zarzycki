begin

f=addfile("~/scratch/ERA5-ptype/2013010100_ptype.nc","r")

TIMEIX=0
LONIX=282
LATIX=312


pmid = f->P4D(TIMEIX,:,LATIX,LONIX)
zint = f->ZINT2(TIMEIX,:,LATIX,LONIX)
pint = f->PINT2(TIMEIX,:,LATIX,LONIX)
tmid = f->T(TIMEIX,:,LATIX,LONIX)

pmidp1=new(dimsizes(pmid)+1,typeof(pmid))
pmidp1(1:dimsizes(pmid))=pmid

print(toint(zint)+" "+pint+" "+pmidp1)

do ii = 0,dimsizes(zint)-2
  print(pint(ii)+"")
  print("----"+pmid(ii)+" "+tmid(ii))
  print(pint(ii+1)+"")
  print(" ")
end do

end