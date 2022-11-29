undef("sum_budgets")
function sum_budgets (vars:string, outvarname:string, f:file)
local ii, tmp
begin

  do ii = 0,dimsizes(vars)-1
    print("adding "+vars(ii))
    if (ii .eq. 0) then
      tmp = f->$vars(ii)$
    else
      tmp = tmp + (f->$vars(ii)$)
    end if
  end do

  print("writing: "+outvarname)
  
  f->$outvarname$ = tmp
  
  delete(tmp)
  delete(ii)
  
  return(True)
  
end
