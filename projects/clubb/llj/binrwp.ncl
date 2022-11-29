;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

;for i in $(seq 2010 2018); do ncl binrwp.ncl in_yyyy=${i}; done

  cmzconfig="RWP"
  ;cmzyyyy="2011"
  cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  dz = 100
  zmax = 2500
  zmin = 100
  nz =  (zmax-zmin)/dz + 1
  zlin = fspan(zmin,zmax,nz)
  zbounds = fspan(50,2550,nz+1)

  nt = 24
  tlin = fspan(0,23,nt) + 0.5
  tbounds = fspan(0,24,nt+1)

  ; start with rwp data

  datadir = "/glade/u/home/zarzycki/scratch/ARM-RWP"
  allfiles = systemfunc("ls "+datadir+"/sgp915rwpwindconC1.a1.201[0-8]0[7]*.cdf")
  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")

  vf = new((/nz,nt/),double)
  vf(:,:) = 0
  nvf = new((/nz,nt/),integer)
  nvf(:,:) = 0
  uf = new((/nz,nt/),double)
  uf(:,:) = 0
  nuf = new((/nz,nt/),integer)
  nuf(:,:) = 0

  do fi=0,nf-1
  ;do fi=0,2
    t = a[fi]->time/3600
    ntdata = dimsizes(t)
    z = a[fi]->height_p*1000
    v = a[fi]->v_wind
    u = a[fi]->u_wind
    zdims = dimsizes(z)
    npow = zdims(1)
    nzdata = zdims(0)
    do zi=0,nzdata-1
      do ti=0,ntdata-1
        do powi=0,0

          if .not.ismissing(z(zi,powi)) then
            do tbini=0,nt-1
              do zbini=0,nz-1
                if (t(ti).ge.tbounds(tbini).and.(t(ti).lt.tbounds(tbini+1))) .and. \
                   (z(zi,powi).ge.zbounds(zbini).and.(z(zi,powi).lt.zbounds(zbini+1)))  then
                  ;print("found bin")
                  ;print(tbounds(tbini) + " <= " + t(ti) + " < " + tbounds(tbini+1))
                  ;print(zbounds(zbini) + " <= " + z(zi,powi) + " < " + zbounds(zbini+1))
                  if .not.ismissing(v(ti,zi,powi)).and.(v(ti,zi,powi).lt.200) then
                    vf(zbini,tbini)  = vf(zbini,tbini) + v(ti,zi,powi)
                    nvf(zbini,tbini) = nvf(zbini,tbini) + 1
                  end if
                  if .not.ismissing(u(ti,zi,powi)).and.(u(ti,zi,powi).lt.200) then
                    uf(zbini,tbini)  = uf(zbini,tbini) + u(ti,zi,powi)
                    nuf(zbini,tbini) = nuf(zbini,tbini) + 1
                  end if
                end if
              end do
            end do
          end if

        end do
      end do
    end do

    delete(t)
    delete(u)
    delete(v)
    delete(z)
    print("Done binning "+files(fi))
    print(ntdata + " " + nzdata + " " + npow)
  end do

  nvf = where(nvf.eq.0,nvf@_FillValue,nvf)
  vf = vf/nvf
  nuf = where(nuf.eq.0,nuf@_FillValue,nuf)
  uf = uf/nuf

print(zlin + " " + dim_avg_n(nvf,1) + " " + dim_avg_n(vf,1))

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

  vf!0 = "z"
  vf!1 = "Time"
  vf&z = zlin
  vf&Time = tlin
  vf@long_name = "Diurnal-Avg Meridional Wind"
  vf@units     = "m s-1"
  ncdf->v = vf

  copy_VarMeta(vf,uf)
  uf@long_name = "Diurnal-Avg Zonal Wind"
  ncdf->u = uf

  copy_VarMeta(vf,uf)
  uf@long_name = "Diurnal-Avg Zonal Wind"

end
