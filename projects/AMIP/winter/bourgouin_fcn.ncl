function bourgouin_fcn(pres_m[*]:numeric,pres_i[*]:numeric,T_m[*]:numeric,T_i_in[*]:numeric)

;========================================================
; CALCULATE SURFACE AREA OF GRIDBOXES
;========================================================

local linlog,Rd,cp,area,area_sign,eps,signchange,pres_i_top,pres_i_bot,ptype
begin

linlog=-1
eps=10^-10
Rd=287
cp=1004

if (T_i_in .lt. 0) then
  ; we need to interpolate
  T_i = int2p_Wrap(pres_m,T_m,pres_i,linlog)
else
  T_i = T_i_in
end if

; Calculate array of midlevel tops and midlevel bottoms
pres_i_top = pres_i(0:dimsizes(pres_i)-2)
pres_i_bot = pres_i(1:dimsizes(pres_i)-1)

area = -cp*(T_m-273.15)*log(pres_i_top/pres_i_bot)
area = where(abs(area).le.eps,eps,area)
area_sign = area/abs(area)

signchange = 0
do k = 0,dimsizes(area_sign)-2
  if (area_sign(k) - area_sign(k+1) .ne. 0) then
    signchange = signchange+1
  end if
end do

if (signchange .eq. 0) then
  ; SNOW
  ptype = 0
else
  ;== We need to calculate PA/NA
	area_arr = new(signchange+1,double)
	area_arr = 0
	counter=0
	do k = 0,dimsizes(area_sign)-2
	  area_arr(counter) = area_arr(counter)+area(k)
	  if (area_sign(k) - area_sign(k+1) .ne. 0) then
		counter = counter+1
	  end if
	end do
	area_arr(counter) = area_arr(counter)+area(dimsizes(area_sign)-1)
	
	if (signchange .eq. 1) then
		PA = area_arr(1)
		if (PA.lt.5.6) then
			; === SNOW
			ptype = 0
		else if (PA.gt.13.2) then
			; === RAIN
			ptype = 2
		else
			; === MIX
			ptype = 1
		end if
		end if
	else if (signchange .eq. 2) then
	  ; area_arr(0) wasted stuff above first cross
	  ; area_arr(1) PA
	  ; area_arr(2) NA
	  PA = area_arr(1)
	  NA = -area_arr(2)
	  ;print("PA: "+PA+"    NA: "+NA)
		if (NA .gt. 66+0.66*PA) then
			; ==== ICE
			ptype = 3
		else if (NA .lt. 46+0.66*PA) then
		  ; ==== FZRA
			ptype = 4
		else
		  ; ==== MIX OF FZRA/ICE
			ptype = 1
		end if
		end if
	else if (signchange .eq. 3) then
	  ; area_arr(0) wasted stuff above first cross
	  ; area_arr(1) PA_a
	  ; area_arr(2) NA
	  ; area_arr(3) PA_sfc
	  PA_a = area_arr(1)
	  NA = -area_arr(2)
	  PA_sfc = area_arr(3)
	  if (PA_a .gt. 2) then
	  ; we use Eqn 4
			if (NA .gt. 66+0.66*PA_sfc) then
				; ==== ICE
				ptype = 3
			else if (NA .lt. 46+0.66*PA_sfc) then
				; ==== RAIN
				ptype = 2
			else
				; ==== MIX OF ICE/RAIN
				ptype = 1
			end if
			end if
		else
			if (PA_sfc.lt.5.6) then
				; === ICE
				ptype = 3
			else if (PA_sfc.gt.13.2) then
				; === RAIN
				ptype = 2
			else
				; === MIX
				ptype = 1
			end if
			end if
	  end if
	else
	  print("LOTS OF SIGN CHANGES "+signchange)
	  if (mod(signchange,2) .eq. 0) then
	    area_arr(0)=0
      PA = sum(where(area_arr.gt.0,area_arr,0))
      NA = -sum(where(area_arr.lt.0,area_arr,0))
      ;print("PA: "+PA+"    NA: "+NA)
      ;print(area)
				if (NA .gt. 66+0.66*PA) then
					; ==== ICE
					ptype = 3
					print("ICE")
				else if (NA .lt. 46+0.66*PA) then
					; ==== FZRA
					ptype = 4
					print("FRZRA")
				else
					; ==== MIX OF FZRA/ICE
					ptype = 1
					print("MIX")
				end if
				end if
	  else 
	    area_arr(0)=0
      PA_sfc = area_arr(dimsizes(area_arr)-1)
      area_arr(dimsizes(area_arr)-1) = 0
      PA_a = sum(where(area_arr.gt.0,area_arr,0))
      NA = -sum(where(area_arr.lt.0,area_arr,0))
      ;print("PA_a: "+PA_a+"    NA: "+NA+"    PA_sfc: "+PA_sfc)
      ;print(area)
			if (PA_a .gt. 2) then
			; we use Eqn 4
				if (NA .gt. 66+0.66*PA_sfc) then
					; ==== ICE
					ptype = 3
				else if (NA .lt. 46+0.66*PA_sfc) then
					; ==== RAIN
					ptype = 2
				else
					; ==== MIX OF ICE/RAIN
					ptype = 1
				end if
				end if
			else
				if (PA_sfc.lt.5.6) then
					; === ICE
					ptype = 3
				else if (PA_sfc.gt.13.2) then
					; === RAIN
					ptype = 2
				else
					; === MIX
					ptype = 1
				end if
				end if
			end if
			print("ptype = "+ptype)
	  end if	    
	end if
	end if
	end if
end if

print(PA)
print(NA)
print(area_arr)
	  
return(ptype)

end