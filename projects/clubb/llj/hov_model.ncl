f=addfile("/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-x010/run/FHIST-ne30-betacast-ERA5-x010.cam.h4.2018-07-23-00000.nc","r")

time = f->time

print(time)

VAR="V_97.49w_36.61n"
v_wind = f->$VAR$(:,:,0)

VAR="Z3_97.49w_36.61n"
z3 = f->$VAR$(0,:,0)

v_wind&lev = z3

wks  = gsn_open_wks("x11","conwomap")   ; send graphics to PNG file

res                     = True          ; plot mods desired

res@cnFillOn            = True          ; turn on color
res@cnFillPalette       = "gui_default" ; set color map


plot = gsn_csm_contour(wks,v_wind(:,{0:5000}),res)       ; contour the variable