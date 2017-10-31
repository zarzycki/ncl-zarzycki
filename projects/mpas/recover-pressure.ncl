load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;wcStrt     = systemfunc("date")


;histfilename="/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999.cam.h2.1979-01-01-00000.nc"
histfile=addfile(histfilename,"r")
;outfilename = str_sub_str(histfilename,".h2.",".h2.PRES.")
outfilename = histfilename+".PRES.nc"

; check to see if mp120 or mp15a
if (.not.ismissing(str_match(histfilename,"mp120a_g16"))) then
  gridfilename="/glade/p/work/zarzycki/ASD2017_files/atm/cam/inic/mpas/x1.40962.CAM.L32.init.new.170303.nc"
else
  gridfilename="/glade/p/work/zarzycki/ASD2017_files/atm/cam/inic/mpas/x8.195266-US.CAM.L32.init.new.170222.nc"
end if

gridfile=addfile(gridfilename,"r")

print("HIST FILE: "+histfilename)
print("GRID FILE: "+gridfilename)
print("OUT  FILE: "+outfilename)

ZINT_DYN = tofloat(gridfile->zgrid(:,::-1))    ; ncol, nlev -- 0 = bottom, 32 = top, need to reverse
ZINT_DYN!0="ncol"
ZINT_DYN!1="levi"
ZINT_DYN_REORDER=ZINT_DYN(levi|:,ncol|:) 
delete(ZINT_DYN)
ZINT_DYN=ZINT_DYN_REORDER
delete(ZINT_DYN_REORDER)

;ZMID_HIST = tofloat(histfile->Z3(:,:,:))

; REMOVE
;PMID_HIST = tofloat(histfile->PRESSURE(:,:,:))    ; nlev, ncol, 32 = bottom

lat=histfile->lat
lon=histfile->lon

dims = dimsizes(histfile->T)
ncol = dims(2)
nlev = dims(1)
ntim = dims(0)
nlevp1 = nlev + 1

PINT_DIAG = new((/ntim,nlevp1,ncol/),typeof(histfile->PS))
PMID_DIAG = new((/ntim,nlev,ncol/),typeof(histfile->PS))

R = 287.058
g = 9.80665

do kk = 0,ntim-1
  T_HIST = tofloat(histfile->T(kk,:,:))
  Q_HIST = tofloat(histfile->Q(kk,:,:))
  PS_HIST = tofloat(histfile->PS(kk,:))

  print("kk "+kk+" of "+(ntim-1))
  do ii = 0,ncol-1
  ;do ii = 0,0
    ;print(Z_DYN(ii,:))
    do jj = 0,nlev-1
      botint=nlev-1-jj+1
      topint=nlev-1-jj
      levmid=nlev-1-jj
      if (jj .eq. 0)
        PINT_DIAG(kk,botint,ii) = PS_HIST(ii)
      end if
      DELTAZ = ZINT_DYN(topint,ii) - ZINT_DYN(botint,ii)
      TV = T_HIST(levmid,ii) * (1 + 0.606*Q_HIST(levmid,ii))
      PINT_DIAG(kk,topint,ii) = PINT_DIAG(kk,botint,ii) / exp ( g * DELTAZ / R / TV )
    end do
    PMID_DIAG(kk,:,ii) = (PINT_DIAG(kk,0:nlev-1,ii) + PINT_DIAG(kk,1:nlev,ii)) / 2.
  end do
  
  delete(T_HIST)
  delete(Q_HIST)
  delete(PS_HIST)
end do

delete(ZINT_DYN)

list_vars()

area=histfile->area
lev=histfile->lev
ilev=histfile->ilev
time=histfile->time

PINT_DIAG!2="ncol"
PMID_DIAG!2="ncol"

PINT_DIAG!1="ilev"
PMID_DIAG!1="lev"

PINT_DIAG!0="time"
PMID_DIAG!0="time"
PINT_DIAG&time=time
PMID_DIAG&time=time

;REMOVE
;copy_VarMeta(PMID_DIAG,PMID_HIST)
;ERR_PMID = PMID_DIAG
;ERR_PMID = abs(PMID_DIAG - PMID_HIST)
;;MAXDIFF_PMID=dim_max_n(ERR_PMID,1)
;MAXDIFF_PMID!0="time"
;MAXDIFF_PMID&time=time
;MAXDIFF_PMID!1="ncol"

print(".... writing file: "+outfilename)

system("/bin/rm -f "+outfilename)   ; remove any pre-existing file
ncdf = addfile(outfilename ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================


fileattdef( ncdf, histfile  )
fAtt               = True            ; assign file attributes
fAtt@title         = "Recovered PRES from MPAS using hydrostatic pres"
fAtt@source_file   =  histfilename+" "+gridfilename
;fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================

ncdf->PRESSUREi=PINT_DIAG
ncdf->PRESSURE=PMID_DIAG

; REMOVE
;ncdf->PMID_HIST=PMID_HIST
;ncdf->ERR_PMID=ERR_PMID
;ncdf->MAXDIFF_PMID=MAXDIFF_PMID

ncdf->time=time
ncdf->lat=lat
ncdf->lon=lon
ncdf->ilev=ilev
ncdf->lev=lev
ncdf->area=area

;wallClockElapseTime(wcStrt, "Total time for script to run", 0)

end
