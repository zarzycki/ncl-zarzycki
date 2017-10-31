load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

gridfile=addfile("x1.40962.CAM.L32.init.new.170303.nc","r")
;histfile=addfile("/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.cam.h0.2000-12.nc","r")
;histfile=addfile("/glade2/h2/acgd0005/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999/run/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999.cam.h2.1979-01-01-00000.nc","r")
histfile=addfile("/glade2/h2/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999.cam.h2.1979-01-01-00000.nc","r")

;histfile=addfile("f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp999.cam.h2.1979-01-01-00000.nc","r")

ZINT_DYN = tofloat(gridfile->zgrid(:,::-1))    ; ncol, nlev -- 0 = bottom, 32 = top, need to reverse
;ZZ_DYN = tofloat(gridfile->zz)

ZINT_DYN!0="ncol"
ZINT_DYN!1="levi"
ZINT_DYN_REORDER=ZINT_DYN(levi|:,ncol|:) 
delete(ZINT_DYN)
ZINT_DYN=ZINT_DYN_REORDER
delete(ZINT_DYN_REORDER)

timeind=5

ZMID_HIST = tofloat(histfile->Z3(timeind,:,:))

PMID_HIST = tofloat(histfile->PRESSURE(timeind,:,:))    ; nlev, ncol, 32 = bottom
PINT_HIST = tofloat(histfile->PRESSUREi(timeind,:,:))
T_HIST = tofloat(histfile->T(timeind,:,:))
Q_HIST = tofloat(histfile->Q(timeind,:,:))
PS_HIST = tofloat(histfile->PS(timeind,:))

lat=histfile->lat
lon=histfile->lon

dims = dimsizes(T_HIST)
ncol = dims(1)
nlev = dims(0)
nlevp1 = nlev + 1

PINT_DIAG = PINT_HIST
PMID_DIAG = PMID_HIST

ZMID_DYN = ZMID_HIST

ZINT_HIST = ZINT_DYN
do jj = nlevp1-1,0,1
  print(jj+"")
  if (jj .eq. nlevp1-1)
    ;ZINT_HIST(jj,:)=0.
  else if (jj .ne. 0) then
    ZINT_HIST(jj,:)=(ZMID_HIST(jj,:)+ZMID_HIST(jj-1,:))/2.
  else
    ; do nothing
  end if
  end if
end do

R = 287.058
g = 9.80665

do ii = 0,ncol-1
;do ii = 0,0
  ;print(Z_DYN(ii,:))
  do jj = 0,nlev-1
    botint=nlev-1-jj+1
    topint=nlev-1-jj
    levmid=nlev-1-jj
    if (jj .eq. 0)
      PINT_DIAG(botint,ii) = PS_HIST(ii)
    end if
    DELTAZ = ZINT_DYN(topint,ii) - ZINT_DYN(botint,ii)
    TV = T_HIST(levmid,ii) * (1 + 0.606*Q_HIST(levmid,ii))
    PINT_DIAG(topint,ii) = PINT_DIAG(botint,ii) / exp ( g * DELTAZ / R / TV )
    ;print("botint ix: "+botint+"   topint ix: "+topint+"    levmid ix: "+levmid)
    ;print("DELTAZ: "+DELTAZ+"   TV: "+TV+"    T: "+T_HIST(levmid,ii)+"    Q: "+Q_HIST(levmid,ii))
  end do
  PMID_DIAG(:,ii) = (PINT_DIAG(0:nlev-1,ii) + PINT_DIAG(1:nlev,ii)) / 2.
  ZMID_DYN(:,ii) = (ZINT_DYN(0:nlev-1,ii) + ZINT_DYN(1:nlev,ii)) / 2.
end do

ERR_PINT = PINT_HIST
ERR_PINT = abs(PINT_DIAG - PINT_HIST)
ERR_ZMID = ZMID_HIST
ERR_ZMID = abs(ZMID_DYN - ZMID_HIST)

PINT_DIAG!1="ncol"
PINT_HIST!1="ncol"
PMID_DIAG!1="ncol"
PMID_HIST!1="ncol"
ZMID_DYN!1="ncol"
ZMID_HIST!1="ncol"
ERR_PINT!1="ncol"
ERR_ZMID!1="ncol"
ZINT_DYN!1="ncol"
ZINT_HIST!1="ncol"

PINT_DIAG!0="levi"
PINT_HIST!0="levi"
PMID_DIAG!0="lev"
PMID_HIST!0="lev"
ZMID_DYN!0="lev"
ZMID_HIST!0="lev"
ERR_PINT!0="levi"
ERR_ZMID!0="lev"
ZINT_DYN!0="levi"
ZINT_HIST!0="levi"

MAXDIFF_PINT=dim_max_n(ERR_PINT,0)
MAXDIFF_PINT!0="ncol"

MAXDIFF_ZMID=dim_max_n(ERR_ZMID,0)
MAXDIFF_ZMID!0="ncol"

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True) 

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================

ncdf->PINT_DIAG=PINT_DIAG
ncdf->PINT_HIST=PINT_HIST

ncdf->ZINT_DYN=ZINT_DYN
ncdf->ZINT_HIST=ZINT_HIST

ncdf->PMID_DIAG=PMID_DIAG
ncdf->PMID_HIST=PMID_HIST

ncdf->ZMID_DYN = ZMID_DYN
ncdf->ZMID_HIST = ZMID_HIST

ncdf->ERR_PINT=ERR_PINT
ncdf->ERR_ZMID=ERR_ZMID

ncdf->MAXDIFF_PINT=MAXDIFF_PINT
ncdf->MAXDIFF_ZMID=MAXDIFF_ZMID

ncdf->lat=lat
ncdf->lon=lon

end
