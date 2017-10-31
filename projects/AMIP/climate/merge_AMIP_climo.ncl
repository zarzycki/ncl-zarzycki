load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;climo_dir = "/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/"
;h0fileName = "atl30x4_monthlyavg_climo_h0.01.nc"
;h3fileName = "atl30x4_monthlyavg_climo_01_3D.nc"
;
;h0file = addfile(climo_dir+"/"+h0fileName,"r")
;h3file = addfile(climo_dir+"/"+h3fileName,"r")
;
;h0vnames = getfilevarnames(h0file)
;h3vnames = getfilevarnames(h3file)
;h0nvars = dimsizes(h0vnames)
;h3nvars = dimsizes(h3vnames)

grid = "ne30"

climo_dir = "/glade/scratch/zarzycki/AMIPmonthly/climo/"
if (grid .eq. "atl30x4") then
  h0fileName = systemfunc ("ls "+climo_dir+"atl30x4_monthlyavg_climo_h0.*.nc")
  h3fileName = systemfunc ("ls "+climo_dir+"atl30x4_monthlyavg_climo_*_3D.nc")
else
  h0fileName = systemfunc ("ls "+climo_dir+"ne30_monthlyavg_climo_h0.*.nc_regrid.nc")
  h3fileName = systemfunc ("ls "+climo_dir+"ne30_monthlyavg_climo_*_3D.nc_regrid.nc")
end if

print(h0fileName)

h0file = addfiles(h0fileName,"r")
h3file = addfiles(h3fileName,"r")
ListSetType (h0file, "cat")
ListSetType (h3file, "cat")

h0vnames = getfilevarnames(h0file[0])
h3vnames = getfilevarnames(h3file[0])
h0nvars = dimsizes(h0vnames)
h3nvars = dimsizes(h3vnames)

system("/bin/rm -f /glade/scratch/zarzycki/"+grid+"_climo.nc")
ncdf = addfile("/glade/scratch/zarzycki/"+grid+"_climo.nc" ,"c")
filedimdef(ncdf,"time",-1,True) 

do i = 0,h0nvars-1

  dims=dimsizes(h0file[:]->$h0vnames(i)$)
  rank=dimsizes(dims)
  if (rank .ge. 3) then
    print("Doing "+h0vnames(i))
    var = h0file[:]->$h0vnames(i)$
    ncdf->$h0vnames(i)$ = var
    delete(var)
  end if
  delete(dims)
  delete(rank)
end do

do i = 0,h3nvars-5
  dims=dimsizes(h3file[:]->$h3vnames(i)$)
  rank=dimsizes(dims)
  if (rank .ge. 3) then
    print("Doing "+h3vnames(i))
    var = h3file[:]->$h3vnames(i)$
    ncdf->$h3vnames(i)$ = var
    delete(var)
  end if
  delete(dims)
  delete(rank)
end do

end

