begin


configs=(/"x003","x121","x122","x123","x124","x125","x126","x127","x128","x129","x902","x903"/)
nconfigs=dimsizes(configs)

; do jet stuff
varname="V_97.49w_36.61n"

do ii = 0,nconfigs-1

config=configs(ii)

f=addfile("CAM_"+config+".nc","r")

if (ii .eq. 0) then
  ref = f->$varname$
end if

a = f->$varname$

a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
indices  = ind_resolve(maxind(a1D),dsizes_a)

time = f->Time
z = f->z

;print(config+"   "+z(indices(0,0))+"   "+time(indices(0,1))+"   "+a(indices(0,0),indices(0,1)))
print(config+"   "+dim_rmsd(ndtooned(ref),ndtooned(a))+" "+avg(a-ref))
print("---")




end do

end