;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin


;for i in $(seq 2010 2018); do ncl bincam.ncl in_yyyy=${i}; done

  ;cmzconfig="x013"
  ;cmzyyyy="2011"
  cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  dz = 100
  zmax = 4050
  zmin = 50
  nz =  (zmax-zmin)/dz + 1
  zlin = fspan(zmin,zmax,nz)

  nt = 24*2
  tlin = fspan(0,23,24) + 0.5

  file_created=False
  ; start with cam data

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-"+cmzconfig+"/run/"+cmzyyyy+"061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  print(allfiles)

  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")
 
  nlev = dimsizes(a[0]->lev)
 
  z = new((/nf,nt,nlev/),double)
  zi = new((/nf,nt,nlev+1/),double)
  
  ZVAR="Z3_97.49w_36.61n"
  PHISVAR="PHIS_97.49w_36.61n"
  do fi=0,nf-1
    z(fi,:,:) = a[fi]->$ZVAR$(:,::-1,0)
  end do
  thgt = a[0]->$PHISVAR$(0,0)/9.81
  z = z-thgt ; now in agl
  
  zi(:,:,1:nlev-1) = (z(:,:,0:nlev-2) + z(:,:,1:nlev-1)) / 2.
  zi(:,:,0) = 0.0
  zi(:,:,nlev) = zi(:,:,nlev-1) + 5000.

  print(zi(0,0,:)+"")
  print(z(0,0,:)+"")
  
  zdavg = dim_avg_n(z,0)
  zidavg = dim_avg_n(zi,0)

  stinds = ispan(0,23,1)*2
  spinds = stinds+1
  
  zdhavg = 0.5*(zdavg(stinds,:) + zdavg(spinds,:))
  zidhavg = 0.5*(zidavg(stinds,:) + zidavg(spinds,:))

  var_in   = getfilevarnames( a[0] )
  nvar_in  = dimsizes(var_in)

  print(var_in)


  var_in_exclude=(/"time_bnds","date_written","time_written"/)
  suff_exclude=(/"13.00e_23.00n"/)
  
do nv=0,nvar_in-1
  if (.not.any(var_in(nv).eq.var_in_exclude)) then
    
    excludethisVar=False
    rank_in = dimsizes(getfilevardimsizes(a[0], var_in(nv)))

    if (rank_in.eq.1) then
      print("Skipping "+var_in(nv))
      
    else if (rank_in.ge.2) then
    
      ; check to see if excluded string
      numsuffexc = dimsizes(suff_exclude)
      do ii = 0,numsuffexc-1
        if .not. ismissing(str_match(var_in(nv) , suff_exclude(ii) )) then
          excludethisVar=True
        end if
      end do
    
      if .not. excludethisVar then
    
        doilev=False
      
        print(" "+var_in(nv))
        VVAR = var_in(nv)
        dims = getvardims(a[0]->$VVAR$)
        if any(dims .eq. "ilev") then
          print("... ilev")
          doilev=True
          v = new((/nf,nt,nlev+1/),double)
        else if any(dims .eq. "lev") then
          print("... lev")
          v = new((/nf,nt,nlev/),double)
        else
          print("... 2D")
          v = new((/nf,nt/),double)
        end if
        end if

        if (rank_in .eq. 3) then
          do fi=0,nf-1
            v(fi,:,:) = a[fi]->$VVAR$(:,::-1,0)
          end do
          vdavg = dim_avg_n(v,0)
          vdhavg = 0.5*(vdavg(stinds,:) + vdavg(spinds,:))
        
          if (doilev) then
            vf = linint1_n(zidhavg,vdhavg,False,zlin,0,1)
          else
            vf = linint1_n(zdhavg,vdhavg,False,zlin,0,1)
          end if
        
        else
          do fi=0,nf-1
            v(fi,:) = a[fi]->$VVAR$(:,0)
          end do
          vdavg = dim_avg_n(v,0)
          vdhavg = 0.5*(vdavg(stinds) + vdavg(spinds))
          vf = vdhavg
        end if



        if ( .not. file_created ) then
          outfname=cmzconfig+"_"+cmzyyyy+".nc"
          system("/bin/rm -f "+outfname)
          ncdf = addfile(outfname,"c")
          print(outfname+" file created")
          ;filedimdef(ncdf,"Time",-1,True)

          tlin!0 = "Time"
          tlin&Time = tlin
          tlin@long_name = "Time of Day"
          tlin@units     = "hr"

          zlin!0 = "z"
          zlin&z = zlin
          zlin@long_name = "Height"
          zlin@units = "m"

          ncdf->Time = tlin
          ncdf->z = zlin
        
          file_created=True
        end if
      

        vf!0 = "Time"
        vf&Time = tlin

        if (rank_in .eq. 3) then
          vf!1 = "z"
          vf&z = zlin
          ncdf->$VVAR$ = vf(z|:,Time|:)
        else
          ncdf->$VVAR$ = vf(Time|:)
        end if
  
        delete(dims)
        delete(v)
        delete(vdavg)
        delete(vdhavg)
        delete(vf)
      
      end if
    
    else
      print("?")
    end if ; if rank = 2
    end if ; if rank = 1
    
  end if ; if not exclude
end do
    
  





end
