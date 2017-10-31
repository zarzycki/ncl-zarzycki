;**************************************************************
; D. Shea
; Driver for NCL function "omega_ccm"
; It calculates intermediate quantities needed for input.
;
undef("omega_ccm_driver")
function omega_driver(p0,psfc,u,v,hyam[*],hybm[*],hyai[*],hybi[*])

; calculate assorted intermediate quantities
; prior to invoking the built-in function "omega_ccm"
;
;  p0     - Scalar numeric value equal to surface reference pressure in Pa.
;  psfc   - 2D or 3D array  ([time,]lat,lon) of surface pressures in Pa.
;  u, v   - 3D or 4D arrays ([time,]lev,lat,lon) of zonal and meridional wind (m/s)
;  hyam   - 1D array containing the hybrid A coefficients. Must have the
;           same dimension as the level dimension of u and v.
;           The order must be top-to-bottom.
;  hybm   - 1D array containing the hybrid B coefficients. Must have the
;           same dimension as the level dimension of u and v.
;           The order must be top-to-bottom.
;  hyai   - 1D array containing the interface hybrid A coefficients.
;           The order must be top-to-bottom.
;  hybi   - 1D array containing the interface hybrid B coefficients.
;           The order must be top-to-bottom.


begin
  dimps  = dimsizes(psfc)
  rankps = dimsizes(dimps)
  dimu   = dimsizes(u)
  ranku  = dimsizes(dimu)
  if ((ranku .eq.rankps)             .or. \
      (ranku .le.2 .or.  ranku.ge.5) .or. \
      (rankps.le.1 .or. rankps.ge.4) .or. \
      (ranku .eq.4 .and.rankps.ne.3) .or. \
      (ranku .eq.3 .and.rankps.ne.2)) then
      print("omega_ccm_driver: expected ranku=3 or 4 and rankps=2 or 3")
      print("omega_ccm_driver: got      ranku="+ranku+"  and rankps="+rankps)
      exit
  end if

  if (ranku.eq.3) then
    klev   = dimu(0)
    nlat   = dimu(1)
    mlon   = dimu(2)
  else
    ntim   = dimu(0)
    klev   = dimu(1)
    nlat   = dimu(2)
    mlon   = dimu(3)
  end if

  omega = u                                 ; create space
  omega@long_name = "Vertical pressure velocity"
  omega@units     = "Pa/s"

  lat   = omega&lat
                      ;  hybd  = new((/klev/),typeof(hyai))
                      ;  do k=0,klev-1
                      ;    hybd(k) = hybi(k+1)-hybi(k)
                      ;  end do
  klevi  = dimsizes(hybi)
  hybd   = hybi(1:) - hybi(0:klevi-2)
  nprlev = 0                                ; number of pure pressure levels
  do k=1,klev
    if (nprlev .eq. 0 .and. hybi(k) .ne. 0.0) then
      nprlev = k - 1
    end if
  end do

  pdel  = dpres_hybrid_ccm(psfc,p0,hyai,hybi)
  pmid  = pres_hybrid_ccm (psfc,p0,hyam,hybm)

  dpsl  = psfc                            ; create space for retrn variables
  dpsm  = psfc
  psln  = log(psfc)
  gradsg(psln,dpsl,dpsm)                  ; gradients of log(psfc) gaussian grid

  div   = uv2dvG(u,v)                     ; divergence on gaussian grid

  print(nprlev)

  omega = omega_ccm(u       ,v       ,div     ,dpsl    \
                   ,dpsm    ,pmid    ,pdel             \
                   ,psfc    ,hybd    ,hybm    ,nprlev  )

  return(omega)
end
