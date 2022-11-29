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
  cmzyyyy="2011"
  ;cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  nt = 24
  tlin = fspan(0,23,nt) + 0.5
  tbounds = fspan(0,24,nt+1)

  ; start with rwp data

  datadir = "/glade/u/home/zarzycki/scratch/ARM-ecor"
  allfiles = systemfunc("ls "+datadir+"/sgp30ecorE14.b1.201[0-8]0[7]*.cdf")
  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")

  vf = new((/nt/),double)
  vf(:) = 0
  nvf = new((/nt/),integer)
  nvf(:) = 0
  
  shf = new((/nt/),double)
  shf(:) = 0
  nshf = new((/nt/),integer)
  nshf(:) = 0
  
  lhf = new((/nt/),double)
  lhf(:) = 0
  nlhf = new((/nt/),integer)
  nlhf(:) = 0
  
  kf = new((/nt/),double)
  kf(:) = 0
  nkf = new((/nt/),integer)
  nkf(:) = 0

  do fi=0,nf-1
  ;do fi=0,2
    t = a[fi]->time/3600
    ntdata = dimsizes(t)
    
    ; Get vars
    v = a[fi]->mean_v
    sh = a[fi]->h
    lh = a[fi]->lv_e
    k = a[fi]->k

      do ti=0,ntdata-1
          if .not.ismissing(v(ti)) then
              do tbini=0,nt-1
                if (t(ti).ge.tbounds(tbini).and.(t(ti).lt.tbounds(tbini+1)))  then
                  ;print("found bin")
                  ;print(tbounds(tbini) + " <= " + t(ti) + " < " + tbounds(tbini+1))
                  ;print(zbounds(zbini) + " <= " + z(zi,powi) + " < " + zbounds(zbini+1))
                  if .not.ismissing(v(ti)).and.(v(ti).le.v@valid_max).and.(v(ti).ge.v@valid_min) then
                    vf(tbini)  = vf(tbini) + v(ti)
                    nvf(tbini) = nvf(tbini) + 1
                  end if
                  
                  if .not.ismissing(sh(ti)).and.(sh(ti).le.sh@valid_max).and.(sh(ti).ge.sh@valid_min) then
                    shf(tbini)  = shf(tbini) + sh(ti)
                    nshf(tbini) = nshf(tbini) + 1
                  end if

                  if .not.ismissing(lh(ti)).and.(lh(ti).le.lh@valid_max).and.(lh(ti).ge.lh@valid_min) then
                    lhf(tbini)  = lhf(tbini) + lh(ti)
                    nlhf(tbini) = nlhf(tbini) + 1
                  end if

                  if .not.ismissing(k(ti)).and.(k(ti).le.k@valid_max) then
                    kf(tbini)  = kf(tbini) - k(ti)
                    nkf(tbini) = nkf(tbini) + 1
                  end if
                            
                end if
              end do
          end if

      end do

    delete(t)
    delete(v)
    delete(sh)
    delete(lh)
    delete(k)
    print("Done binning "+files(fi))
  end do

  nvf = where(nvf.eq.0,nvf@_FillValue,nvf)
  vf = vf/nvf

  nshf = where(nshf.eq.0,nshf@_FillValue,nshf)
  shf = shf/nshf

  nlhf = where(nlhf.eq.0,nlhf@_FillValue,nlhf)
  lhf = lhf/nlhf

  nkf = where(nkf.eq.0,nkf@_FillValue,nkf)
  kf = kf/nkf
  
  outfname=cmzconfig+"_"+cmzyyyy+".nc"
  system("/bin/rm -f "+outfname)
  ncdf = addfile(outfname,"c")
  print(outfname+" file created")
  ;filedimdef(ncdf,"Time",-1,True)

  tlin!0 = "Time"
  tlin&Time = tlin
  tlin@long_name = "Time of Day"
  tlin@units     = "hr"

  ncdf->Time = tlin

  vf!0 = "Time"
  vf&Time = tlin
  vf@long_name = "Diurnal-Avg Meridional Wind"
  vf@units     = "m s-1"
  
  ncdf->VBOT = vf

  copy_VarMeta(vf,shf)
  ncdf->SHFLX = shf

  copy_VarMeta(vf,lhf)
  ncdf->LHFLX = lhf

  copy_VarMeta(vf,kf)
  ncdf->TAU = kf
  
  thf = shf
  thf = shf + lhf
  ncdf->THFLX = thf
  
  exit
  
 wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file

 res                  = True                     ; plot mods desired
 res@tiMainString     = "Basic XY plot"          ; add title

 plot  = gsn_csm_xy (wks,tlin,kf,res) ; create plot
 
 
 
end
