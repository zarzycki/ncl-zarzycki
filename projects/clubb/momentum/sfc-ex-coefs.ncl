begin

;f=addfile("RCE.QPC6.ne0np4tcfplane.ne15x8.exp606.001.cam.h1.0001-01-09-00000.nc_regrid.nc","r")
f=addfile("tmp.nc","r")

; constants
Rd = 287.
cp=1004.
Lv = 2.5104e6

; load required variables
shf=f->SHFLX
lhf=f->LHFLX
tbot=f->TBOT
ubot=f->UBOT
ustar=f->USTAR
vbot=f->VBOT
wbot=f->QBOT
sst=f->SST
ps=f->PS
taux=f->TAUX
tauy=f->TAUY

; any diag printing?
print("SST -- max: "+max(sst)+"   min: "+min(sst)+"   mean: "+avg(sst))

; calculate derived vars
tau = sqrt(taux^2+tauy^2)
fullpres=pres_hybrid_ccm(ps,100000.,f->hyam,f->hybm)
rho = fullpres(:,29,:,:)/Rd/tbot
windbot=vbot
windbot=sqrt(vbot^2+ubot^2)
theta = pot_temp(fullpres(:,29,:,:), tbot, 0, False)

; ==== Calculate DELQ ===========================================================

;qbot = mixhum_convert(wbot, "w", (/0,0/))
;qbot = wbot
;print("qbot 1 "+avg(qbot))

qbot = wbot / (1. + wbot)
;print("qbot 2 "+avg(qbot))

;qsat = qbot
;qsat = 640380.0 / exp(5107.4/sst)

qsat = mixhum_ptrh (ps/100., conform (ps,sst,-1), conform(ps,100.,-1), 2)*1.02
;print("qsat 1 "+avg(qsat))

; method from model
;qsat2 = 640380. / exp(5107.4/sst)
;qsat2 := 0.98 * qsat2 / rho
;print("qsat 2 "+avg(qsat2))

delq=qsat-qbot


; ==== Calculate DELT ===========================================================


delt=sst-tbot

;print("ustar 1 "+avg(ustar))
;myustar = windbot * sqrt(1.2E-3)
;print("ustar 2 "+avg(myustar))

; ==== Calculate coefficients ===========================================================

CH=ps
CD=ps
CQ=ps
CK=ps

CH = (shf/rho/cp/windbot/delt)
CD = (ustar/windbot)^2
CQ = (lhf/rho/Lv/windbot/delq)

;CK = (shf+lhf)/(rho*Lv*windbot*delq+rho*cp*windbot*delt)
CK = (CH*shf+CQ*lhf)/(shf+lhf)

print("CH: "+dim_median_n(CH,(/1,2/)))
print("CQ: "+dim_median_n(CQ,(/1,2/)))
print("CD: "+dim_median_n(CD,(/1,2/)))
print("CK: "+dim_median_n(CK,(/1,2/)))

ratio=ps
ratio=CK/CD

; ==== Write NetCDF file ===========================================================

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
