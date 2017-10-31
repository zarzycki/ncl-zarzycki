;========================================================
; AMIP Histogram by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
;========================================================
begin

ace = asciiread("ace.txt",(/23,2/),"float")

model = ace(:,0)
obs = ace(:,1)

obs_dt = dtrend(obs,False)
model_dt = dtrend(model,False)

ccr = escorc(obs_dt,model_dt)   ; ccr is a scalar
print("CCR between obs and model is "+ccr)
   
end
