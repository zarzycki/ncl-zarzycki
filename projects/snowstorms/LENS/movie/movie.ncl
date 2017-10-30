load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

outtype="pdf"

preclfile="slice-PRECL.nc"
preccfile="slice-PRECC.nc"
ptypefile="slice-PTYPE.nc"

f1=addfile(preclfile,"r")
f2=addfile(preccfile,"r")
f3=addfile(ptypefile,"r")

PRECL=f1->PRECL
PRECC=f2->PRECC
PTYPE=f3->PTYPE

PRECL = (PRECL+PRECC)*3600000

timehrl=f1->time
time6hr=f3->time

ntimes=dimsizes(timehrl)

; For this, convert to frozen and liquid
PTYPE = where(PTYPE .eq. 2,1,0)

PTYPEF = linint1_n_Wrap (time6hr, PTYPE, False, timehrl, 0, 0)
PTYPEI = round(PTYPEF,3)

printVarSummary(PTYPEI)
printVarSummary(PRECL)

PRECSN=PRECL
PRECRA=PRECL

PRECSN = where(PTYPEI.eq.0,PRECL,PRECL@_FillValue)
;PRECRA = where(PTYPEI.ne.0,PRECL,PRECL@_FillValue)

wks = gsn_open_wks(outtype,"test")

maxlat = 55.           ; choose subregion
minlat = 20.
maxlon = -60.
minlon = -90.

do zz = 0,90

  res                 = True

  res@gsnDraw      = False                        ; don't draw yet
  res@gsnFrame     = False                        ; don't advance frame yet
  res@gsnMaximize = True

  res@gsnAddCyclic = False                    ; Don't add a cyclic point.

  res@cnFillOn              = True
  res@cnLinesOn   = False

  resrain=res

  resrain@mpFillOn                    = False        ; turn off gray fill
  resrain@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
  resrain@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
  resrain@mpGeophysicalLineThicknessF = 3            ; thickness of outlines

  resrain@mpMaxLatF                   = maxlat           ; choose subregion
  resrain@mpMinLatF                   = minlat
  resrain@mpMinLonF = minlon
  resrain@mpMaxLonF = maxlon
  resrain@mpCenterLonF = (resrain@mpMinLonF+resrain@mpMaxLonF)/2.

  ;resrain@gsnSpreadColors      = True

  resrain@mpOutlineBoundarySets     = "geophysicalandusstates"; turn on states
  resrain@mpDataBaseVersion         = "mediumres"             ; select database
  resrain@mpDataSetName             = "Earth..2"

  ;;;;;;;;
  cmap = read_colormap_file("WhiteGreen")
  cmap_dims = dimsizes(cmap)
  ncolors = cmap_dims(0)
  npairs = cmap_dims(1)
  nnewcolors = 200
  cmap_interp = new((/nnewcolors,npairs/),typeof(cmap))
  do ii = 0,npairs-1
    cmap_interp(:,ii) = linint1 (fspan(0,1,ncolors), cmap(:,ii), False, fspan(0,1,nnewcolors), 0)
  end do
  cmap_interp(0,:) = cmap(0,:)
  cmap_interp(1,:) = cmap(1,:)
  resrain@cnFillPalette=cmap
  delete(cmap)
  delete(cmap_interp)
  resrain@cnLevelSelectionMode = "ExplicitLevels"                        ; set explicit contour levels
  resrain@cnLevels    = (/0.1,0.25,0.5,1.0,1.5,2.0,2.5,3.0,4.0,5.0/)        ; set levels
  ;;;;;;;;;;

  plotrain = gsn_csm_contour_map(wks,PRECRA(zz,:,:),resrain)

  ;;;;;;;;
  ressn=res
  cmap = read_colormap_file("WhiteBlue")
  cmap_dims = dimsizes(cmap)
  ncolors = cmap_dims(0)
  npairs = cmap_dims(1)
  nnewcolors = 200
  cmap_interp = new((/nnewcolors,npairs/),typeof(cmap))
  do ii = 0,npairs-1
    cmap_interp(:,ii) = linint1 (fspan(0,1,ncolors), cmap(:,ii), False, fspan(0,1,nnewcolors), 0)
  end do
  cmap_interp(0,:) = cmap(0,:)
  cmap_interp(1,:) = cmap(1,:)
  ressn@cnFillPalette=cmap
  delete(cmap)
  delete(cmap_interp)
  ressn@cnLevelSelectionMode = "ExplicitLevels"                        ; set explicit contour levels
  ressn@cnLevels    = (/0.1,0.25,0.5,1.0,1.5,2.0,2.5,3.0/)        ; set levels
  ;;;;;;;;;;

  plotsnow = gsn_csm_contour(wks,PRECSN(zz,:,:),ressn)

  overlay(plotrain,plotsnow)

  delete(res)
  delete(ressn)


  draw(plotrain)
  frame(wks)

end do

end