begin

f=addfile("tmp.nc","r")

shf=f->SHFLX
lhf=f->LHFLX
tbot=f->TBOT
ubot=f->UBOT
vbot=f->VBOT
qbot=f->QBOT
sst=f->SST
ps=f->PS
taux=f->TAUX
tauy=f->TAUY

tau = sqrt(taux^2+tauy^2)

fullpres=pres_hybrid_ccm(ps,100000.,f->hyam,f->hybm)
print(fullpres(0,:,0,0))

theta = pot_temp(fullpres(:,29,:,:), tbot, 0, False)


windbot=vbot
windbot=sqrt(vbot^2+ubot^2)

qsat = qbot
qsat = 640380.0 / exp(5107.4/sst)

delq=qsat-qbot
delt=sst-theta
rho=1.003
cp=1004.
Lv = 2.5104e6

CH=ps
CD=ps
CQ=ps
CK=ps

CH = shf/rho/cp/windbot/delt
CD = tau/rho/windbot/windbot
CQ = lhf/rho/Lv/windbot/delq

CK = (shf+lhf)/(rho*Lv*windbot*delq+rho*cp*windbot*delt)

ratio=ps
ratio=CK/CD

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->CH  = CH
ncdf->CD  = CD
ncdf->CQ  = CQ
ncdf->CK  = CK

ncdf->RATIO  = ratio
ncdf->WINDBOT = windbot

end