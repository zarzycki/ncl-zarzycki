
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "/glade/u/home/dtatch/ncl/functions/wkSpaceTime_panel.ncl"
;************************************************

;===============================================
; This calls the function wkSpaceTime_panel.ncl to 
; create a panel plot of Wheeler-Kiladis diagrams
;
; Required Input:
;    fnam      - an array of the file paths
;    nfiles    - number of files to be paneled
;    panelSize - dimensions of panel ie (/1,2/)
;    diro      - output directory
;    caseName  - used for file name
;    varName   - variable name in data file
;    latBound  - boundary latitude ie 15
;    spd       - samples per day
;    nDayWin   - temporal window length
;    nDaySkip  - days between temporal windows
;    opt       - resource with a variety of options
;    plotTit   - an array of titles over each plot
;
; Diana Thatcher, dtatch@umich.edu, 8/29/2013
;================================================

  begin

print("wk_panel_plot.ncl")

; Settings ----------------------------------

  whois = "colin"       ; Currently supports diana, colin, and vera

        varName = "PRECL"     ; variable to use
        diro     = "./"       ; output dir: location of plots

        latBound = 15       ; latBound
        nDayWin  = 96       ; Wheeler-Kiladis [WK] temporal window length (days) 15
        nDaySkip = -60      ; time (days) between temporal windows [segments] 5
        spd      = 4        ; samples per day (6 hour sampling rate)

        opt             = True
        opt@pltType     = "eps"              ; format of plot file
        opt@debug       = False              ; if =True, Multiple printVarSummary will be activated
        opt@cnLinesOn   = False              ; turn off contour lines
        opt@pltColorMap = "nrl_sirkes"       ; wgne15 works okay or nrl_sirkes
        opt@Fig_3a = fspan(0.4,  4.4,  16)   ; specify range for contours
        opt@Fig_3b = fspan(0.4,  4.4,  16)   ; specify range for contours


  if (whois .eq. "diana") then
        varName = "PRECL"     ; variable to use
        diro     = "./"       ; output dir: location of plots

        latBound = 15       ; latBound
        nDayWin  = 96       ; Wheeler-Kiladis [WK] temporal window length (days) 15
        nDaySkip = -60      ; time (days) between temporal windows [segments] 5
        spd      = 4        ; samples per day (6 hour sampling rate)

        opt             = True
        opt@pltType     = "eps"              ; format of plot file
        opt@debug       = False              ; if =True, Multiple printVarSummary will be activated
        opt@cnLinesOn   = False              ; turn off contour lines
        opt@pltColorMap = "nrl_sirkes"       ; wgne15 works okay or nrl_sirkes
        opt@Fig_3a = fspan(0.4,  4.4,  16)   ; specify range for contours
        opt@Fig_3b = fspan(0.4,  4.4,  16)   ; specify range for contours

    ; File paths -----------------------------
      eulpath = getenv("eulpathbranch")
      fvpath = getenv("fvpathbranch")
      sepath = getenv("sepathbranch")
      sldpath = getenv("sldpathbranch")
      apepath = getenv("apepathbranch")

      eulcase = getenv("eulcasebranch")
      fvcase = getenv("fvcasebranch")
      secase = getenv("secasebranch")
      sldcase = getenv("sldcasebranch")
      apecase = getenv("apecasebranch")

      setting = getenv("setting")

      if (setting .eq. "all")
          nfiles = 4             ; number of files
          panelSize = (/2,2/)    ; panel dimensions
          caseName =    "wk_all"

          plotTit = (/"(a) EUL","(b) FV","(c) SE","(d) SLD"/)
          yaxTit = (/"Frequency (cpd)"," ","Frequency (cpd)"," "/) 
          xaxTit = (/" "," ","Zonal Wave Number","Zonal Wave Number"/)
          paths = (/eulpath,fvpath,sepath,sldpath/)
          cases = (/eulcase,fvcase,secase,sldcase/)

      else if (setting .eq. "APE")
          nfiles = 2             ; number of files
          panelSize = (/1,2/)    ; panel dimensions
          caseName =    "wk_ape"

          plotTit = (/"(a) Moist Idealized","(b) APE"/)
          yaxTit = (/"Frequency (cpd)"," "/)
          xaxTit = (/"Zonal Wave Number","Zonal Wave Number"/)
          paths = (/sepath,apepath/)
          cases = (/secase,apecase/)

      end if
      end if

      fnam = new(nfiles,string)
      do file_step = 0,nfiles-1
         fnam(file_step) = paths(file_step)+cases(file_step)+".cam.h0.*.nc"
      end do

  else if (whois .eq. "colin") then
        varName = "FLUT"     ; variable to use
        diro     = "./"       ; output dir: location of plots

        latBound = 15       ; latBound
        nDayWin  = 96       ; Wheeler-Kiladis [WK] temporal window length (days) 15
        nDaySkip = -60      ; time (days) between temporal windows [segments] 5
        spd      = 4        ; samples per day (6 hour sampling rate)

        opt             = True
        opt@pltType     = "pdf"              ; format of plot file
        opt@debug       = True               ; if =True, Multiple printVarSummary will be activated
        opt@cnLinesOn   = False              ; turn off contour lines
        opt@pltColorMap = "nrl_sirkes"       ; wgne15 works okay or nrl_sirkes
        opt@Fig_3a = fspan(0.4,  4.4,  16)   ; specify range for contours
        opt@Fig_3b = fspan(0.4,  4.4,  16)   ; specify range for contours

        ; for now, have to run regrid_file.ncl before to gen lat/lon
        ; --> someday will create driver
        ; to do this online instead of offline

        nfiles = 3             ; number of files
        panelSize = (/1,3/)    ; panel dimensions
        caseName =    "wk_varres_CAM5"

        plotTit = (/"uniform_15","quadrant_15_x8","uniform_120"/)
        yaxTit = (/"Frequency (cpd)"," "," "/)
        xaxTit = (/"Zonal Wave Number","Zonal Wave Number","Zonal Wave Number"/)

        paths = (/"/glade/scratch/zarzycki/APE_levy/CAM5/"+plotTit(0)+"/","/glade/scratch/zarzycki/APE_levy/CAM5/"+plotTit(1)+"/","/glade/scratch/zarzycki/APE_levy/CAM5/"+plotTit(2)+"/"/)
        cases = (/"h2wk_regrid_0.25x0.25.nc","h2wk_regrid_0.25x0.25.nc","h2wk_regrid_0.25x0.25.nc"/)

      fnam = new(nfiles,string)
      do file_step = 0,nfiles-1
         fnam(file_step) = paths(file_step)+cases(file_step)
      end do

  else if (whois .eq. "vera") then
      
      print("Im so sleepy")
      exit

  end if
  end if
  end if



   wkSpaceTime_panel(fnam,nfiles,panelSize,diro,caseName,varName,latBound,spd,nDayWin,nDaySkip,opt,plotTit,yaxTit,xaxTit)



end
