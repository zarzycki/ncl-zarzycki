;
; Sort x and move coresponding values of y into
; the same locations.
; 
procedure sortitF1S1(
	x[*]:float, 	; x coordinate field that gets sorted
	y[*]:string,	   ; corresponding y coordinate
  sorttype:integer ; 0 = smallest to largest, any other integer largest to smallest
) 
local 
	ind, 		; temporary value that holds index of value to be swapped
	k, 		; index variable
	p, 		; index variable
	tmp,		; temporary value used to swap individual values
  tmp2
begin
	ind = 0
	do k = 0, dimsizes(x) - 2 
		ind = k
		if(.not. ismissing(x(ind))) then
			do p = k + 1, dimsizes(x) - 1
				if((.not. ismissing(x(p))).and.(x(ind) .ge. x(p))) then
					ind = p
				end if
			end do
			if(ind .ne. k) then
				tmp = x(ind)
				x(ind) = x(k)
				x(k) = tmp
				tmp2 = y(ind)
				y(ind) = y(k)
				y(k) = tmp2
			end if
		end if
	end do
  if (sorttype .ne. 0) then
    x = x(::-1)
    y = y(::-1)
  end if
end 

procedure sortitF1F1(
	x[*]:float, 	   ; x coordinate field that gets sorted
	y[*]:float,	   ; corresponding y coordinate
  sorttype:integer ; 0 = smallest to largest, any other integer largest to smallest
) 
local 
	ind, 		; temporary value that holds index of value to be swapped
	k, 		; index variable
	p, 		; index variable
	tmp,		; temporary value used to swap individual values
  tmp2
begin
	ind = 0
	do k = 0, dimsizes(x) - 2 
		ind = k
		if(.not. ismissing(x(ind))) then
			do p = k + 1, dimsizes(x) - 1
				if((.not. ismissing(x(p))).and.(x(ind) .ge. x(p))) then
					ind = p
				end if
			end do
			if(ind .ne. k) then
				tmp = x(ind)
				x(ind) = x(k)
				x(k) = tmp
				tmp2 = y(ind)
				y(ind) = y(k)
				y(k) = tmp2
			end if
		end if
	end do
  if (sorttype .ne. 0) then
    x = x(::-1)
    y = y(::-1)
  end if
end

procedure sortitF1I1(
	x[*]:float, 	   ; x coordinate field that gets sorted
	y[*]:integer,	   ; corresponding y coordinate
  sorttype:integer ; 0 = smallest to largest, any other integer largest to smallest
) 
local 
	ind, 		; temporary value that holds index of value to be swapped
	k, 		; index variable
	p, 		; index variable
	tmp,		; temporary value used to swap individual values
  tmp2
begin
	ind = 0
	do k = 0, dimsizes(x) - 2 
		ind = k
		if(.not. ismissing(x(ind))) then
			do p = k + 1, dimsizes(x) - 1
				if((.not. ismissing(x(p))).and.(x(ind) .ge. x(p))) then
					ind = p
				end if
			end do
			if(ind .ne. k) then
				tmp = x(ind)
				x(ind) = x(k)
				x(k) = tmp
				tmp2 = y(ind)
				y(ind) = y(k)
				y(k) = tmp2
			end if
		end if
	end do
  if (sorttype .ne. 0) then
    x = x(::-1)
    y = y(::-1)
  end if
end

procedure sortitF1F2(
; ARRAY must be structured such that rightmost dimension of Y matches X!!!!
	x[*]:float, 	   ; x coordinate field that gets sorted
	y:float,	   ; corresponding y coordinate
  sorttype:integer ; 0 = smallest to largest, any other integer largest to smallest
) 
local 
	ind, 		; temporary value that holds index of value to be swapped
	k, 		; index variable
	p, 		; index variable
	tmp,		; temporary value used to swap individual values
  tmp2
begin
	ind = 0
	do k = 0, dimsizes(x) - 2 
		ind = k
		if(.not. ismissing(x(ind))) then
			do p = k + 1, dimsizes(x) - 1
				if((.not. ismissing(x(p))).and.(x(ind) .ge. x(p))) then
					ind = p
				end if
			end do
			if(ind .ne. k) then
				tmp = x(ind)
				x(ind) = x(k)
				x(k) = tmp
				tmp2 = y(:,ind)
				y(:,ind) = y(:,k)
				y(:,k) = tmp2
			end if
		end if
	end do
  if (sorttype .ne. 0) then
    x = x(::-1)
    y = y(:,::-1)
  end if
end 
