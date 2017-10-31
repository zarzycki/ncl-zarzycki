function plot_outline_fcn(wks,plot,linecolor,linethick)

;========================================================
; This function plots an outline of the AMIP refinement pattern over
; a map
;
; Inputs
; wks - workstation
; plot - plot
; linecolor - color of line (string)
; linethick - thickness of line (float)
;========================================================

;local nlat,mlon,re,pi,rad,rr,ASPHERE,dxeq,dx,dy,carea
begin

;fileinside="atl_30_x8_border_inside.txt"
;fileoutside="atl_30_x8_border_outside.txt"

;data_in = asciiread(fileinside,(/33,2/),"float")
;data_out = asciiread(fileoutside,(/25,2/),"float")

;lat_in = data_in(:,0)
;lon_in = data_in(:,1)
;lat_out = data_out(:,0)
;lon_out = data_out(:,1)

lon_in = (/ \
-178.45168,  \
-150.89735,  \
-121.87564,  \
-92.038704,  \
-67.90844,  \
-28.614992,  \
-11.006311,  \
-10.86483,  \
-21.788292,  \
-23.762386,  \
-40.40462,  \
-59.151505,  \
-77.08288,  \
-84.90143,  \
-102.18298,  \
-117.01757,  \
-134.78456,  \
-147.0168,  \
-161.85611,  \
-178.32468,  \
178.90344,  \
173.03389,  \
171.88785,  \
154.93016,  \
135.03563,  \
123.13819,  \
115.963394,  \
112.54347,  \
111.90179,  \
99.99873,  \
100.18896,  \
-178.45168 \
/)

lat_in = (/ \
1.2251173,  \
1.2500986,  \
1.2764102,  \
1.303461,  \
1.4885293,  \
1.5241535,  \
1.5401179,  \
25.366196,  \
24.866716,  \
44.284706,  \
57.324932,  \
53.880917,  \
50.11126,  \
41.781406,  \
40.623398,  \
37.998886,  \
32.760654,  \
37.15573,  \
39.75334,  \
41.04394,  \
41.20462,  \
41.1993,  \
41.420383,  \
47.71054,  \
51.28272,  \
46.049805,  \
47.02245,  \
42.61318,  \
31.026007,  \
31.994364,  \
1.9673125,  \
1.2251173 \
/)

lon_out = (/ \
-179.74901,  \
-135.05608,  \
-89.87127,  \
-45.178776,  \
-0.32021084,  \
0.13129939,  \
-27.627453,  \
-54.37897,  \
-78.84345,  \
-97.755295,  \
-107.04795,  \
-135.42325,  \
-156.14505,  \
-179.30977,  \
179.22218,  \
154.41965,  \
134.83981,  \
118.36911,  \
105.9756,  \
100.27773,  \
89.51259,  \
89.883316,  \
134.08734,  \
-179.74901 \
/)

lat_out = (/ \
-6.7845135,  \
-6.4360185,  \
-6.8663683,  \
-6.0274105,  \
-6.4580564,  \
35.395214,  \
67.250114,  \
67.55279,  \
64.09733,  \
53.28996,  \
47.722935,  \
39.84975,  \
46.37044,  \
48.63823,  \
48.636894,  \
58.260143,  \
64.618385,  \
60.02577,  \
56.25429,  \
43.824047,  \
43.16032,  \
-6.0491524,  \
-6.1915646,  \
-6.7845135 \
/)

resp                  = True                      ; polyline mods desired
resp@gsLineColor      = linecolor                    ; color of lines
resp@gsLineThicknessF = linethick
resp@mpGreatCircleLinesOn=True
resp@gsLineDashPattern  = 2

dum = new(500,"graphic")
count = 0

do hh = 0,dimsizes(lat_in) - 2		; Draw inner nest
  dum(hh) = gsn_add_polyline(wks,plot,lon_in(hh:hh+1),lat_in(hh:hh+1),resp)
  count = hh
end do

do hh = 0,dimsizes(lat_out) - 2		; Draw outer nest
  dum(hh+count+1) = gsn_add_polyline(wks,plot,lon_out(hh:hh+1),lat_out(hh:hh+1),resp)
end do

dname = unique_string("dum")            ; This setting is important! If
                                        ; you don't do this, gsn_add_polygon
                                        ; will fail.
plot@$dname$ = dum                      ; That way you assign a unique name
                                        ; to each "dum" attribute, thus saving
                                        ; each attribute and allowing each 
                                        ; line to be drawn on each plot.

return(plot)

end



 
