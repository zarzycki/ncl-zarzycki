undef("calc_acc")
function calc_acc (forecast:numeric, analysis:numeric, minLat:numeric, maxLat:numeric, minLon:numeric, maxLon:numeric)
;
; Calculate anomaly correlation coefficient between two fields
;
; INPUTS
; forecast       : potential temperature (K)
; analysis       : zonal wind (m/s)
; minLat         : minimum latitude for calculation (deg_N)
; maxLat         : maximum latitude for calculation (deg_N)
; minLon         : minimum longitude for calculation (deg_E)
; maxLon         : maximum longitude for calculation (deg_E)
;
;

local ACC

begin

ACC = sum(     forecast({minLat:maxLat},{minLon:maxLon})*analysis({minLat:maxLat},{minLon:maxLon})) / sqrt(sum(     forecast({minLat:maxLat},{minLon:maxLon})^2)*sum(analysis({minLat:maxLat},{minLon:maxLon})^2))

return(ACC)

end
