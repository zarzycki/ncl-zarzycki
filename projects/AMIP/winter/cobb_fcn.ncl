function cobb_fcn(omega_m[*]:numeric,T_m[*]:numeric,rh_m[*]:numeric,z_i[*]:numeric)

;========================================================
; CALCULATE SURFACE AREA OF GRIDBOXES
;========================================================

local omega_m,omega_max,delZ,weights,weights_sum,snowRatProfile,snowRatWeights,num_i,num_m
begin

;layerTemp = (/-29.0,-27.0,-25.0,-23.0,-21.0,-19.0,-17.0,-15.0,-13.0,-11.0/)
;snowRatio = (/ 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0/)

layerTemp_cobb = (/ \
-100, \
-29.5, \
-28.5, \
-27.5, \
-26.5, \
-25.5, \
-24.5, \
-23.5, \
-22.5, \
-21.5, \
-20.5, \
-19.5, \
-18.5, \
-17.5, \
-16.5, \
-15.5, \
-14.5, \
-13.5, \
-12.5, \
-11.5, \
-10.5, \
-9.5, \
-8.5, \
-7.5, \
-6.5, \
-5.5, \
-4.5, \
-3.5, \
-2.5, \
-1.5, \
-0.5, \
0.5, \
25., \ 
50. /)

snowRatio_cobb = (/ \
10, \
10, \
10, \
10, \
10, \
10, \
10, \
10, \
9.583333, \
10.364583, \
13.072917, \
19.114584, \
28.385416, \
38.802082, \
46.979168, \
50, \
45.729168, \
36.25, \
24.895834, \
14.947917, \
8.958333, \
6.1458335, \
5.7291665, \
5.9895835, \
6.3541665, \
6.3541665, \
6.1458335, \
5.8333335, \
5.15625, \
4.53125, \
3.6979167, \
2.8125, \
0.0, \
0.0 /)

;layerTemp = fspan(min(layerTemp_cobb),max(layerTemp_cobb),1000)
;snowRatio = linint1 (layerTemp_cobb,snowRatio_cobb, False, layerTemp, 0)

layerTemp = layerTemp_cobb
snowRatio = snowRatio_cobb

snowRatio!0="temp"
layerTempK = layerTemp + 273.15
snowRatio&temp=layerTempK

;printVarSummary(snowRatio)
;print(snowRatio({260.75}))

; This is the vertical profile of snow ratios built from T profile
snowRatProfile = snowRatio({T_m(:)})

rh_crit = 90.

num_i = dimsizes(z_i)
num_m = dimsizes(T_m)
delZ = z_i(0:num_i-2) - z_i(1:num_i-1)



; cloud is where rh > rh_crit
omega_m = where(rh_m.ge.rh_crit,omega_m,0)
omega_m = where(omega_m.le.0,0,omega_m)
omega_max = max(omega_m)

;print(omega_m)

; calculate weights for each column
if (omega_max .gt. 0) then
weights = omega_m(:)*(omega_m(:)/omega_max)^2*delZ(:)

weights_sum = sum(weights)
snowRatWeights = snowRatProfile*weights
ratio = sum(snowRatWeights)/weights_sum

else
ratio = 0
end if

;if (ratio .gt. 45)
;  print(omega_m)
;  print(omega_max)
;  print(snowRatProfile)
;  print(weights)
;end if
;print(ratio)

return(ratio)

end