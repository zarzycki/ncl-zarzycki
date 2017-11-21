;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/sorting.ncl"

;========================================================

begin

dataprod="JRA"
var="DZ300500"
crit="DAYS"
out_type="pdf"

filename = "/glade/u/home/zarzycki/SAlib/TMP/morris."+var+"."+dataprod+"."+crit

; Read data into individual lines (one column) while tossing header
;Parameter Mu Sigma Mu_Star Mu_Star_Conf
  data = readAsciiTable(filename,1,"string",(/1,0/))
; replace space with , for splitting
  data = str_sub_str(data," ",",")

; split stuff
  parameter    = str_get_field(data,1,",")
  mu = stringtofloat(str_get_field(data,2,","))
  sigma = stringtofloat(str_get_field(data,3,","))
  mu_star = stringtofloat(str_get_field(data,4,","))
  mu_star_conf = stringtofloat(str_get_field(data,5,","))
  print(parameter + ": sigma: " + sigma + ": mu_star: " + mu_star+ ": mu_star_conf: " + mu_star_conf)
  nparams=12

; normalized distance from origin (1:1 relationship between mu/sigma for driving variance)
dist=sqrt( (mu_star/max(mu_star))^2 + (sigma/max(sigma))^2      )

sortDir=1    ; 1 is descending, 0 is ascending
; ====== This is the variable we want to sort by...
SORTVAR=dist(:,0)

SORTVAR_SORT=SORTVAR
parameter_SORT=parameter(:,0)
sortitF1S1(SORTVAR_SORT,parameter_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
sigma_SORT=sigma(:,0)
sortitF1F1(SORTVAR_SORT,sigma_SORT,sortDir)

;delete(SORTVAR_SORT)
;SORTVAR_SORT=SORTVAR
;dist_SORT=dist(:,0)
;sortitF1F1(SORTVAR_SORT,dist_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
mu_star_SORT=mu_star(:,0)
sortitF1F1(SORTVAR_SORT,mu_star_SORT,sortDir)

print("SORTVAR_SORT is " + SORTVAR_SORT + "  parameter_SORT is " + parameter_SORT+ "  sigma_SORT is " + sigma_SORT+ "  mu_star_SORT is " + mu_star_SORT)


quote = inttochar(34)
outDir="musigma_rankings/"
outName="musigma."+var+"."+dataprod+"."+crit+".csv"
delim=","

system("rm "+outDir+"/"+outName)
do ii = 0,nparams-1
  ; parameter, dist, sigma, mu_star, var, dataprod, crit
  system("echo "+quote+ parameter_SORT(ii)+delim+SORTVAR_SORT(ii)+delim+sigma_SORT(ii)+delim+mu_star_SORT(ii)+delim+var+delim+dataprod+delim+crit +quote+" >> "+outDir+"/"+outName)
end do

  wks   = gsn_open_wks (out_type,"musigma_pdfs/musigma."+var+"."+dataprod+"."+crit)            ; open workstation

  res                   = True                     ; plot mods desired
  res@gsnDraw=False
  res@gsnFrame=False

if (crit .eq. "HR_TS") then
  res@tiMainString      = dataprod+"-"+var+"-HR~B~TS~N~"          ; add title
else if (crit .eq. "FA_AS") then
  res@tiMainString      = dataprod+"-"+var+"-FA~B~AS~N~"          ; add title
else
  res@tiMainString      = dataprod+"-"+var+"-"+crit          ; add title
end if
end if

  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarkers         =  16                      ; choose type of marker  
  res@xyMarkerColor     = "grey60"               ; gray higher is lighter
  res@xyMarkerSizeF     = 0.017                     ; Marker size (default 0.01)
  
  res@tiXAxisString     = "~F8~m~S~*~"
  res@tiYAxisString     = "~F8~s~"

  ; nudge left axis left for label spacing
  res@trXMinF = -0.25*max(mu_star(:,0))
  ; nudge top axis up for label spacing
  res@trYMaxF = 1.05*max(sigma(:,0))


  plot  = gsn_csm_xy (wks,mu_star(:,0),sigma(:,0),res)                    ; create plot

txres=True
buffer=0.025*max(mu_star(:,0))   ; was 0.0175
;txres@amJust="CenterRight"
txres@txFontHeightF = 0.02             ; Set the font height
;txres@txBackgroundFillColor="White"
;txres@txPerimOn=True
;txres@txPerimColor="Black"
  do i = 0,nparams-1

;      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)

if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "DAYS") then
    if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="TopLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0),sigma(i,0)-buffer,txres)
    else if (parameter(i,0) .eq. "maxLat") then
      txres@amJust="TopRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0)-buffer,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0),sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="TopRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0),sigma(i,0),txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if

if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "COUNT") then
    if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOmag") then
      txres@amJust="TopLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0),sigma(i,0)+buffer,txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if

if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "ACE") then
    if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="TopLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOmag") then
      txres@amJust="TopRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="TopRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0),txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if

if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "FA_AS") then
    if (parameter(i,0) .eq. "maxLat") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="TopLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "pslFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0)+buffer,txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if

if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "HR_TS") then
    if (parameter(i,0) .eq. "maxLat") then
      txres@amJust="TopRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer*.75,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="BottomLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer*1.12,txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="CenterLeft"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)+buffer,sigma(i,0),txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="BottomRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0),sigma(i,0)+buffer*1.25,txres)
    else if (parameter(i,0) .eq. "pslFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if



if (dataprod .eq. "JRA" .and. var .eq. "DZ300500" .and. crit .eq. "NULL") then
    if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "minWind") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcOffset") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMaxGap") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "maxTopo") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "mergeDist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajRange") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "pslFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOmag") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "wcFOdist") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else if (parameter(i,0) .eq. "trajMinLen") then
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    else
      txres@amJust="CenterRight"
      text1 = gsn_add_text(wks,plot,parameter(i,0),mu_star(i,0)-buffer,sigma(i,0)+buffer,txres)
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
    end if
end if



  end do

txpanelres=True
txpanelres@amJust="TopLeft"
txpanelres@txFontHeightF = 0.05             ; Set the font height
txpanelres@txBackgroundFillColor="White"
txpanelres@txPerimOn=True
txpanelres@txPerimColor="Black"
if(crit .eq. "COUNT") then
  panelStr="a."
else if (crit .eq. "DAYS") then
  panelStr="b."
else if (crit .eq. "HR_TS") then
  panelStr="c."
else if (crit .eq. "FA_AS") then
  panelStr="d."
else if (crit .eq. "ACE") then
  panelStr="e."
else
  panelStr="x."
end if
end if
end if
end if
end if

tmp2=gsn_add_text(wks,plot,panelStr,res@trXMinF,res@trYMaxF,txpanelres)

  draw(plot)



  frame(wks)

end
