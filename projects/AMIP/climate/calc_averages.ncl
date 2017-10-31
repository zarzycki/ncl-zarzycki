;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

grid="atl30x4"
filenumlist=(/"h0","h2"/)
avgarea="pac"

tab = str_get_tab()
print(grid+tab+avgarea)

do numfile = 0,dimsizes(filenumlist)-1
  filenum = filenumlist(numfile)
  if (avgarea .eq. "globe")
    minlat=-90
    maxlat=90
    minlon=0
    maxlon=360
  else if (avgarea .eq. "atl")
    minlat=8
    maxlat=43
    minlon=280
    maxlon=340
  else if (avgarea .eq. "pac")
    minlat=8
    maxlat=43
    minlon=160
    maxlon=220
  else
    print("Bad area")
    exit()
  end if
  end if
  end if
  
  filedir = "/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/"
  
  if (grid .eq. "ne30") then
    filename = "ne30_climo_"+filenum+".all.nc_regrid.nc"
  else if (grid .eq. "atl30x4") then
    filename = "atl30x4_climo_"+filenum+".all.nc"
  else
    print("Grid doesnt exist")
    exit()
  end if
  end if
  
  f = addfile(filedir+"/"+filename,"r")
  
  vnames = getfilevarnames(f)
  nvars = dimsizes(vnames)
  ;print(vnames)
  
  gw = f->gw({minlat:maxlat})

  

  
  do i = 0,nvars-1
    ;print("-----------------------------------------------------------")
    dims=dimsizes(f->$vnames(i)$)
    rank=dimsizes(dims)
    if (rank .eq. 3) then
      var = f->$vnames(i)$
      var_sub = var(0,{minlat:maxlat},{minlon:maxlon})
      unitsname = var_sub@units
      glAve = wgt_areaave_Wrap(var_sub, gw, 1.0, 1)
      print(vnames(i)+tab+glAve+tab+unitsname)
      delete(var)
      delete(var_sub)
      delete(glAve)
    end if
    delete(dims)
    delete(rank)
  end do
  
  delete(vnames)
  delete(nvars)
  delete(gw)
  delete(f)

end do
  
end
