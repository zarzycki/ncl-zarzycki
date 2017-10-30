load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"

undef("clmMonTLU")
function clmMonTLU (x[*][*][*]:numeric)
local dimx, klvl, ntim, ncells, i, nmo, nmos, aveMonth
begin
  dimx = dimsizes(x)
  ntim = dimx(0)

  nmos  = 12
  modCheck ("clmMonTLLL", ntim, nmos)   ; error check

  klvl = dimx(1)
  ncells = dimx(2)
;
; Compute all 12 monthly averages first.
;
   aveMonth = new((/nmos,klvl,ncells/),typeof(x) \
                                         ,getFillValue(x))
   do nmo=0,nmos-1
      aveMonth(nmo,:,:) = dim_avg_n( x(nmo:ntim-1:nmos,:,:), 0 )
   end do

; copy attributes and add a couple of informational attributes
; only need to do this if plotting or writing to netCDF file

   copy_VarAtts (x,aveMonth)
   aveMonth@time_op_ncl = "Climatology: "+ (ntim/nmos) +" years"
   aveMonth@info    = "function clmMonTLU: contributed.ncl"

; copy spatial (eg, lat/lon) coordinate variables

   do i=1,2
      if (.not.ismissing(x!i)) then
          aveMonth!i = x!i
          if (iscoord(x,x!i)) then
              aveMonth&$aveMonth!i$ = x&$x!i$
          end if
      end if
   end  do

   aveMonth!0     = "month"           ; create a "month" named dim
   aveMonth&month = ispan(0,nmos-1,1) ; create a month coord var

   return (aveMonth)
end

undef("clmMonTU")
function clmMonTU (x[*][*]:numeric)
local dimx, ntim, ncells, i, nmo, nmos, aveMonth
begin
  dimx = dimsizes(x)
  ntim = dimx(0)

  nmos  = 12
  modCheck ("clmMonTLLL", ntim, nmos)   ; error check

  ncells = dimx(1)
;
; Compute all 12 monthly averages first.
;
   aveMonth = new((/nmos,ncells/),typeof(x) \
                                         ,getFillValue(x))
   do nmo=0,nmos-1
      aveMonth(nmo,:) = dim_avg_n( x(nmo:ntim-1:nmos,:), 0 )
   end do

; copy attributes and add a couple of informational attributes
; only need to do this if plotting or writing to netCDF file

   copy_VarAtts (x,aveMonth)
   aveMonth@time_op_ncl = "Climatology: "+ (ntim/nmos) +" years"
   aveMonth@info    = "function clmMonTLU: contributed.ncl"

; copy spatial (eg, lat/lon) coordinate variables

   do i=1,1
      if (.not.ismissing(x!i)) then
          aveMonth!i = x!i
          if (iscoord(x,x!i)) then
              aveMonth&$aveMonth!i$ = x&$x!i$
          end if
      end if
   end  do

   aveMonth!0     = "month"           ; create a "month" named dim
   aveMonth&month = ispan(0,nmos-1,1) ; create a month coord var

   return (aveMonth)
end
