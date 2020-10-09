begin

f=addfile("/glade/u/home/zarzycki/scratch/BOMEX.QPC6.ne0np4tcfplane.ne15x8.exp290.001/run/tmp.nc","r")

var = "U"

u=f->$var$(3:5,:,:,:)

printVarSummary(u)

uavg=dim_avg_n_Wrap(u,(/2,3/))

printVarSummary(uavg)

f2 = addfile("/glade/u/home/zarzycki/scratch/archive/SCAM-bomex/atm/hist/SCAM-bomex.cam.h0.1969-06-25-00000.nc","r")
;f2 = addfile("/glade/u/home/zarzycki/BOMEX_5day_4scam_c180703.ncc","r")

u2=f2->$var$(3:5,2:31,:,:)
u2avg=dim_avg_n_Wrap(u2,(/2,3/))

;print(u&lev+" "+u2&lev)

printVarSummary(u2avg)



wks   = gsn_open_wks ("x11","xy")                  ; send graphics to PNG file

res                   = True                       ; plot mods desired
res@tiMainString      = "Profile Plot"             ; add title
res@trYReverse        = True                       ; reverse Y-axis
res@xyDashPatterns    = 15                         ; choose dash patterns
res@trYMinF=800.
res@xyLineColor = "red"

;res@trXMinF=0.004
;res@trXMaxF=0.02

res2 = res
res2@xyLineColor = "blue"

plot  = gsn_csm_x2y (wks,uavg,u2avg,u&lev,res,res2) ; create plot

end