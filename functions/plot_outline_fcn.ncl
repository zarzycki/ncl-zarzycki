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

lat_in = (/ \
54.409, \
50.42, \
45.205, \
40.909, \
32.318, \
34.466, \
31.705, \
17.591, \
17.284, \
14.216, \
3.784, \
0.716, \
0.409, \
3.17, \
5.625, \
6.545, \
9.614, \
12.375, \
12.375, \
15.136, \
32.318, \
35.08, \
35.693, \
38.455, \
41.523, \
42.136, \
44.591, \
47.045, \
47.352, \
51.341, \
51.341, \
53.489, \
54.409 \
/)

lon_in = (/ \
303.891, \
314.949, \
323.857, \
329.693, \
330, \
344.13, \
347.201, \
347.816, \
350.273, \
353.345, \
353.345, \
350.273, \
297.747, \
294.369, \
294.061, \
273.481, \
270.41, \
270.102, \
261.195, \
258.43, \
258.43, \
261.502, \
270.102, \
270.41, \
273.481, \
276.553, \
276.553, \
280.546, \
283.311, \
290.683, \
294.061, \
298.669, \
303.891 \
/)

lat_out = (/ \
70.67, \
64.534, \
48.58, \
49.5, \
43.364, \
31.705, \
28.33, \
25.568, \
-7.875, \
-13.398, \
-13.091, \
-10.023, \
-13.705, \
-7.568, \
-7.568, \
-2.045, \
-1.739, \
4.091, \
40.602, \
47.045, \
48.58, \
58.091, \
64.841, \
68.83, \
70.67 \
/)

lon_out = (/ \
301.126, \
324.164, \
341.058, \
355.188, \
1.945, \
1.945, \
5.324, \
7.782, \
8.703, \
1.945, \
340.751, \
314.642, \
286.382, \
279.932, \
262.423, \
256.28, \
250.137, \
244.3, \
243.993, \
246.758, \
252.901, \
261.809, \
272.253, \
285.461, \
301.126 \
/)

resp                  = True                      ; polyline mods desired
resp@gsLineColor      = linecolor                    ; color of lines
resp@gsLineThicknessF = linethick
resp@mpGreatCircleLinesOn=True

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



 
