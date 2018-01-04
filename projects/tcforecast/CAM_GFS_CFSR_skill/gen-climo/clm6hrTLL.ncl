; =====================================
undef("clm6hrTLL")
function clm6hrTLL (x[*][*][*]:numeric, yyyyddd:numeric)
;
; calculate the mean Annual Cycle from daily data.
; The return array will gave the raw climatology at each grid point
;
;              x(time,lat,lon)  <==== input dimension order
;              x!0 = "time"     <==== time is in days
;              x!1 = "lat"
;              x!2 = "lon"
;
;    non-Leap  yyyyddd
;              1905001 =>  Jan  1, 1905
;              1905032 =>  Feb  1, 1905
;              1905059 =>  Feb 28, 1905
;              1905060 =>  Mar  1, 1905
;              1905365 =>  Dec 31, 1905
;
;    Leap
;              1908001 =>  Jan  1, 1908]
;              1908032 =>  Feb  1, 1908]
;              1908059 =>  Feb 28, 1908]
;              1908060 =>  Feb 29, 1908]
;              1908061 =>  Mar  1, 1908]
;              1908366 =>  Dec 31, 1908]
;
; Usage:  xClmDay = clmDAY_TLL (x, yyyyddd)
; -------

local dimx, ntim, nlat, mlon, ndys, days, clm6hr, ndy, indx, year_day, nFill
begin

   avg_leap = True

   dimx  = dimsizes (x)

   ntim  = dimx(0)
   nlat  = dimx(1)
   mlon  = dimx(2)
   if (isatt(yyyyddd,"calendar")) then
       if (yyyyddd@calendar.eq."360_day" .or. yyyyddd@calendar.eq."360") then
           ndys = 360
       end if
       if (yyyyddd@calendar.eq."365_day" .or. yyyyddd@calendar.eq."365"      .or. \
           yyyyddd@calendar.eq."noleap"  .or. yyyyddd@calendar.eq."no_leap") then
           ndys  = 365
       end if
       if (yyyyddd@calendar.eq."366_day" .or. yyyyddd@calendar.eq."366"      .or. \
           yyyyddd@calendar.eq."allleap" .or. yyyyddd@calendar.eq."all_leap") then
           ndys  = 366
       end if
       if (yyyyddd@calendar.eq."standard" .or. yyyyddd@calendar.eq."gregorian") then
           ndys  = 366
       end if
   else
       ndys  = 366     ; default
   end if

   nhrs=ndys*4
   climo_day = fspan(0,ndys-0.25,nhrs)
   climo_day@units="days since 2000-01-01"
   utc_climo=cd_calendar(climo_day,0)
   MMDDHH_climo=utc_climo(:,1)*10000+utc_climo(:,2)*100+utc_climo(:,3)

   print(MMDDHH_climo+" "+climo_day)

   clm6hr= new((/nhrs,nlat,mlon/),typeof(x), getFillValue(x) ) ; 6hrly climatology

;
; Get MMDDHH from actual data
;

   utc_date=cd_calendar(yyyyddd,0)
   MMDDHH_date=utc_date(:,1)*10000+utc_date(:,2)*100+utc_date(:,3)
;
; Compute averages for each sequential day of the year.
;

   do nhr=0,nhrs-1
      climohr=MMDDHH_climo(nhr)
      print(climohr+"")
      indx = ind( MMDDHH_date .eq. climohr )
      if (.not.ismissing(indx(0))) then
          nindx = dimsizes(indx)
          if (nindx.eq.1) then                       ; force 3rd dimension
              clm6hr(nhr,:,:) = dim_avg_n(x(indx:indx,:,:), 0)
          else
              clm6hr(nhr,:,:) = dim_avg_n(x(indx,:,:), 0)
          end if
      end if
      delete(indx)
   end do

;   if (.not.isatt(yyyyddd,"calendar") .or. \
;       isatt(yyyyddd,"calendar") .and. yyyyddd@calendar.eq."standard" .or. \
;                                       yyyyddd@calendar.eq."gregorian") then
;                                                   ; nominal day 366
;                                                   ; ave(31 Dec + 1 Jan)=leap
;       clm6hr(ndys-1,:,:) = (clm6hr(0,:,:) + clm6hr(ndys-2,:,:))*0.5
;   end if

   if (avg_leap) then
;(232)	22800 58
;(233)	22806 58.25
;(234)	22812 58.5
;(235)	22818 58.75
;(236)	22900 59
;(237)	22906 59.25
;(238)	22912 59.5
;(239)	22918 59.75
;(240)	30100 60
;(241)	30106 60.25
;(242)	30112 60.5
;(243)	30118 60.75
     clm6hr(236,:,:)=(clm6hr(232,:,:)+clm6hr(240,:,:))/2.
     clm6hr(237,:,:)=(clm6hr(233,:,:)+clm6hr(241,:,:))/2.
     clm6hr(238,:,:)=(clm6hr(234,:,:)+clm6hr(242,:,:))/2.
     clm6hr(239,:,:)=(clm6hr(235,:,:)+clm6hr(243,:,:))/2.
     ;clm6hr(nhr,:,:)
   end if

   nFill = num(ismissing(clm6hr))
   if (nFill.eq.0) then
       delete(clm6hr@_FillValue)
   end if

   clm6hr@long_name   = "6-hourly Climatology"
   if (isatt(x,"long_name")) then
       clm6hr@long_name = clm6hr@long_name +": "+x@long_name
   end if
   if (isatt(x,"units")) then
       clm6hr@units     = x@units
   end if
   clm6hr@information = "Raw 6-hrly averages across all years"
   clm6hr@smoothing   = "None"

   time           = climo_day

   clm6hr!0       = "time"
   clm6hr&time    =  time

   copy_VarCoords(x(0,:,:), clm6hr(0,:,:))   ; trick
   if (isatt(clm6hr,"time")) then
       delete(clm6hr@time)               ; clean up
   end if

   if (isatt(yyyyddd,"calendar")) then
       clm6hr@calendar = yyyyddd@calendar
   end if

   return (clm6hr)
end
