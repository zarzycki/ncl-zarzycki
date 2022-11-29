f=addfile("/glade/u/home/zarzycki/scratch/ARM-RWP/sgp915rwpwindconC1.a1.20080715.001009.cdf","r")

time = f->time

print(time)

u_wind = f->u_wind(:,0:59,0)
v_wind = f->v_wind(:,0:59,0)

height_p = f->height_p(0:59,0)
height_p = where(abs(height_p) .gt. 999.0,max(height_p),height_p)
;height_p = where(ismissing(height_p),max(height_p),height_p)

v_wind!1 = "height"
v_wind&height = height_p

print(height_p)

printVarSummary(v_wind)
printVarSummary(height_p)

v_wind = where(abs(v_wind) .gt. 999.0,v_wind@_FillValue,v_wind)

wks  = gsn_open_wks("x11","conwomap")   ; send graphics to PNG file

res                     = True          ; plot mods desired

res@cnFillOn            = True          ; turn on color
res@cnFillPalette       = "gui_default" ; set color map


plot = gsn_csm_contour(wks,v_wind,res)       ; contour the variable