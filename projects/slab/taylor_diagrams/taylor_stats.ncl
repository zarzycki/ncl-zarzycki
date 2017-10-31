;*****************************************************
; taylor_7.ncl     **Basic* Model-to-Model comparison
;*****************************************************
; ---------------------------------------------
; User specified parameters
; -------------------------
; Make use of NCL's scoping rules [same as Pascal].
; Define "global" variables. These can be "seen"
; by all cade that follows. NCL has no explicit
; way to define global variables. However, the NCL 
; convention is to make them all capital letters
;----------------------------------------------
lonEW = False


CNTL_DIR     = "/glade/u/home/zarzycki/work/ncep/"            ; Reference dataset    
TEST_DIR     = (/ "/glade/p/work/zarzycki/slab/slab_taylor/","/glade/p/work/zarzycki/slab/slab_taylor/","/glade/p/work/zarzycki/slab/slab_taylor/" /)   ; Test dataset directories

CNTL_CASE    = "ncep_climo_avg" 
;TEST_CASE    = (/ "TOTAVG_slab2_nativegrid.nc_regrid","TOTAVG_slab_nativegrid.nc_regrid","TOTAVG_fixedSST_nativegrid.nc_regrid" /)  
TEST_CASE    = (/ "TOTAVG_slab3_nativegrid.nc_regrid","TOTAVG_slab_nativegrid.nc_regrid","TOTAVG_fixedSST_nativegrid.nc_regrid" /)  
REGIONS = (/"central"/)  ;globe, atl, pac, central

SEASONS      = (/ "FULL" /) ;ANN counts, too.
VAR_COMPARE  = (/ "PSL","TMQ","U850","RH500","T500","PRECT" /)
;CASES        = (/  "SLAB2","SLAB1","FIXEDSST"/)         ; possibly rename if TEST_CASE is long          
CASES        = (/  "THERMO","SLAB1","FIXEDSST"/)         ; possibly rename if TEST_CASE is long          

TEST_MARKERS = (/ 16, 16 , 16/)               ; one for each TEST_CASE
TEST_COLORS  = (/ "red", "blue" ,"darkgreen"/)
TEST_MKSIZE =  0.021
TEST_MKTXTOFFSET = 0.035 ; Offset of marker label above polymarkers
TEST_LEGTXTHGT = 0.29

PRINT_MINMAX = True
PLOT_TYPE    = "pdf"

    
; ---------------------------------------------
; End user specified parameters
; ---------------------------------------------
; Optional:
; Not implemented. Must follow some rules.
; User specified function to read/process data.
; Same argument sequence as predefined "getData"
; Allows users to create own getData module.
;----------------------------------------------
;undef("getDataUser")
;function getDataUser (f:file          \  ; file reference [pointer]
;                     ,varName:string  \  ; variable name
;                     ,monsea:string   \  ; month/season name
;                     ,w[*]:numeric    \  ; weights
;                     ,opt:logical)    \  ; opt arguments [not used]
;
;begin
;    vFlag = False                    ; flag if variable found
;    return()
;end

;#################################################################
;#################################################################
;#################################################################
;#################################################################

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "./taylor_diagram.ncl"
load "./taylor_diagram_cam.ncl"
load "./taylor_metrics_table.ncl"

;================================================
; function to read scalar or vector components for 
; user specified variable [varName] and 
; month/season [monsea] from a file pointed to by "f"
;================================================
undef("getData")
function getData (f:file          \  ; file reference [pointer]
                 ,avgarea:string  \  ; variable name
                 ,varName:string  \  ; variable name
                 ,monsea:string   \  ; month/season name
                 ,w[*]:numeric    \  ; weights
                 ,opt:logical)    \  ; optional argument [not used]

local vClm, vClmx, vClmy, vFlag, vClass, dNam, i, i3, month, sea3
begin
    vFlag = False                    ; flag if variable found
                                     ; READ FULL CLIMATOLOGY (12,:,:)

    if (lonEW) then
      print("Adjusting longitudes")
      minlon = minlon - 180
      maxlon = maxlon - 180
    end if
  
    if (isfilevar(f, varName)) then
        vClm       = f->$varName$(:,:,:)
        vFlag      = True
        vClass     = "scalar"
        vClm@class =  vClass
        vClm@wgt   = w
    else

        if (varName.eq."U200") then
            vClm   = f->U(:,{200},:,:)
            vClm@long_name = "U200"
            vFlag  = True
            vClass = "scalar"
            vClm@wgt   = w
            vClm@class = vClass
        end if
        
        if (varName.eq."U850") then
            vClm   = f->U(:,{850},:,:)
            vClm@long_name = "U850"
            vFlag  = True
            vClass = "scalar"
            vClm@wgt   = w
            vClm@class = vClass
        end if
        
        if (varName.eq."RH500") then
            vClm   = f->RELHUM(:,{500},:,:)
            vClm@long_name = "RH500"
            vFlag  = True
            vClass = "scalar"
            vClm@wgt   = w
            vClm@class = vClass
        end if

        if (varName.eq."T500") then
            vClm   = f->T(:,{500},:,:)
            vClm@long_name = "T500"
            vFlag  = True
            vClass = "scalar"
            vClm@wgt   = w
            vClm@class = vClass
        end if

        if (.not.vFlag) then
           ;if (isdefined("getDataUser")) then   ; has user defined function
           ;    vClm = getDataUser( f, varName, monsea, gw, opt ) 
           ;    if (all(ismissing(vClm))) then
           ;    
           ;    end if
           ;end if

            print("------------------------------------------")
            print("-->TAYLOR: getData: "+varName+" not found <--")
            print("------------------------------------------")
            vClm = 1e20
            vClm@_FillValue = 1e20
            return(vClm)
        end if
   end if
                                       ; select appropriate month/season
                                       ; perform averaging ... if needed


   if (vClass.eq."scalar") then        ; "METHODS" for scalar
       i = 0
       if (.not.ismissing(i)) then
           data = vClm(0,:,:)          ; extract specified month
           return( data )
       end if
   end if

   print("------------------------------------------")
   print("-->TAYLOR: getData: "+varName+" <--")
   print("--> Not sure how we got here  <--")
   print("------------------------------------------")
   exit

end
;************************************************************
; ==============>  Main [driver] Script  <==================
;************************************************************

begin
    nSeason     = dimsizes( SEASONS )
    nVar        = dimsizes( VAR_COMPARE )
    nCase       = dimsizes( CASES )

    ratio       = new ((/nCase, nVar/), "double" )  
    cc          = new ((/nCase, nVar/), "double" ) 
    table       = new ((/nCase,nSeason,nVar/), typeof(ratio) )
    bias        = new ((/nCase, nVar/), "double" , 1d20)

;----------------------------------------------
; Generate one Taylor diagram per season
;----------------------------------------------
    CNTL_FILE   = CNTL_CASE+".nc"
    fc = addfile(CNTL_DIR+CNTL_FILE, "r") ; open control file with monthly files   
    gw = fc->gw                           ; gw(nlat)

    do ns=0,nSeason-1                     ; loop over seasons

     do nc=0,nCase-1                      ; loop over all the test cases       
        ft = addfile(TEST_DIR(nc)+TEST_CASE(nc)+".nc", "r") ;      case/test

      do nv=0,nVar-1
                                          ; READ DATA
         cdata  = getData( fc, REGIONS, VAR_COMPARE(nv), SEASONS(ns), gw, False ) 
         tdata  = getData( ft, REGIONS, VAR_COMPARE(nv), SEASONS(ns), gw, False ) 
 
         vClass = cdata@class
         if (vClass.eq."scalar") then
             vcntl  = cdata
             vtest  = tdata
         else                              ; must be vector class
             vcntlx = cdata(0,:,:)
             vcntly = cdata(1,:,:)
             vtestx = tdata(0,:,:)
             vtesty = tdata(1,:,:)
         end if

         wt = cdata@wgt                    ; weights associated with cdata

         delete(cdata)                     ; no longer needed
         delete(tdata)

         if (PRINT_MINMAX) then
             if (vClass.eq."scalar") then
                 printMinMax(vcntl , True )
                 printMinMax(vtest , False)
             else
                 printMinMax(vcntlx, True )
                 printMinMax(vcntly, False)
                 printMinMax(vtestx, False)
                 printMinMax(vtesty, False)
             end if
         end if

         if (vClass.eq."scalar") then 
                                         ; SCALAR
             dims        = dimsizes(vcntl)
             ntim        = dims(0)             
             rank        = dimsizes(dims)    ; all 3D in test

             wgt         = conform(vcntl, wt , rank-2) 
           ;;wgt         = mask(wgt, lsflag.eq.0, False)   ; if desired  
           ;;wgt         = mask(wgt, lsflag.eq.1, False)  
  
                                         ; temporary variables
             sumw        = sum(wgt)
             sumwc       = sum(wgt*vcntl)
             sumwt       = sum(wgt*vtest)
                                         ; wgted areal mean
             wmean_cntl  = sumwc/sumw
             wmean_test  = sumwt/sumw
             
             norm_wgt_arr = wgt/sumw
                                         ; wgted areal variance
             ;wvar_cntl   = sum(wgt*(vcntl-wmean_cntl)^2)/sumw  
             ;wvar_test   = sum(wgt*(vtest-wmean_test)^2)/sumw  
             wvar_cntl   = sum(norm_wgt_arr*(vcntl-wmean_cntl)^2)
             wvar_test   = sum(norm_wgt_arr*(vtest-wmean_test)^2) 
             ; wgted mean
             ;printVarSummary(wgt)
             ;printVarSummary(vcntl)
             wavg_cntl   = wgt_areaave(vcntl, wgt(:,0), 1.0, 0)
             wavg_test   = wgt_areaave(vtest, wgt(:,0), 1.0, 0)
    
                                         ; wgted correlation coef
             ;wcc         = (sum(wgt*vcntl*vtest) - sumwc*sumwt/sumw )/ \
             ;             ((sum(wgt*vcntl^2) - sumwc^2/sumw) *         \
             ;              (sum(wgt*vtest^2) - sumwt^2/sumw) )^0.5   
             
             wcc = pattern_cor(vcntl,vtest,wgt,0)
             

    
             delete( vcntl )             ; delete variables which may change
             delete( vtest )             ; rank on next variable iteration
         else                     
                                         ; VECTOR
             dims        = dimsizes(vcntlx)
             ntim        = dims(0)             
             rank        = dimsizes(dims)    ; all 3D in test

             wgt         = conform(vcntlx, wt ,rank-2) 
           ;;wgt         = mask(wgt, lsflag.eq.0, False)   ; if desired  
           ;;wgt         = mask(wgt, lsflag.eq.1, False)  
                                         ; temporary variables
             sumw        = sum(wgt)
             sumwcx      = sum(wgt*vcntlx)
             sumwcy      = sum(wgt*vcntly)
             sumwtx      = sum(wgt*vtestx)
             sumwty      = sum(wgt*vtesty)
                                         ; wgted areal means (vector components)
             wmean_cntlx = sumwcx/sumw
             wmean_cntly = sumwcy/sumw
             wmean_testx = sumwtx/sumw
             wmean_testy = sumwty/sumw
                                         ; wgted areal variance (vector)
             wvar_cntl   = sum(wgt*((vcntlx-wmean_cntl)^2 +\
                                    (vcntly-wmean_cntl)^2))/sumw  
             wvar_test   = sum(wgt*((vtestx-wmean_test)^2 +\
                                    (vtesty-wmean_test)^2))/sumw  
 
                                         ; wgted vector correlation coef [note cross prod)
             wcc         = sum(wgt*( (vcntlx-wmean_cntl)*(vtestx-wmean_test)    \
                                    +(vcntly-wmean_cntl)*(vtesty-wmean_test)))  \
                                    /(sqrt(wvar_cntl*wvar_test)*sumw)

             delete( vcntlx )            ; delete variables which may change
             delete( vcntly )            ; rank on next variable iteration
             delete( vtestx )
             delete( vtesty )
         end if
         delete( dims )
         delete( wgt  )                  ; shape may change
         delete( wt   )                  ; shape may change

         ratio(nc,nv)    = (wvar_test/wvar_cntl)^0.5
         cc(nc,nv)       = wcc
         table(nc,ns,nv) = ratio(nc,nv)
         bias(nc,nv)     = wavg_test - wavg_cntl          
         if (wavg_cntl.ne.0) then
             bias(nc,nv) = abs((bias(nc,nv))/wavg_cntl)*100    ; bias [%]
         end if

      end do                             ; end VARIABLE loop
     end do                              ; end CASE loop
    
    

     plot_root_name   = "slab_taylor_diagram"
     if (isvar("PLOT_TYPE")) then
         plot_type    = PLOT_TYPE
     else
         plot_type    = "pdf"
     end if
     plot_file        = plot_root_name +"."+plot_type

     opt              = True
     opt@varLabels    = VAR_COMPARE
     opt@caseLabels   = CASES
     opt@tiMainString = ""

     if (isvar("TEST_MARKERS")) then
         opt@Markers  = TEST_MARKERS 
     end if
     if (isvar("TEST_COLORS")) then
         opt@Colors   = TEST_COLORS
     end if
     if (isvar("TEST_MKSIZE")) then
         opt@gsMarkerSizeF = TEST_MKSIZE
     end if     
     if (isvar("TEST_MKTXTOFFSET")) then
         opt@markerTxYOffset  = TEST_MKTXTOFFSET
     end if       
     if (isvar("TEST_LEGTXTHGT")) then
         opt@caseLabelsFontHeightF = TEST_LEGTXTHGT
     end if  
     
     opt@varLabelsFontHeightF = .015
     opt@tiMainFontHeightF = 0.023
     
     ;nCase = 8
     ;opt@legendWidth           = 0.020
     ;opt@legendHeight          = 0.040*nCase
     
     ;opt@caseLabelsFontHeightF = 0.05
     opt@varLabelsFontHeightF  = 0.02
     opt@txFontHeightF = 0.02 ; was 0.15, controls size of labels above polymarkers and title labels
     
     ;opt@varLabelsYloc = 0.10 ; Sets the y axis position of var labels in bot left
     
     opt@centerDiffRMS = True               ; RMS 'circles'
 
     wks              = gsn_open_wks(plot_type,plot_root_name)
     ;res@gsnDraw    = False
     ;res@gsnFrame   = False
     opt@taylorDraw  = False
     opt@taylorFrame = False
     plot            = taylor_diagram(wks,ratio,cc,opt)
     ;plot           = taylor_diagram_cam(wks,ratio,cc,bias,opt)
     
      resP = True
      resP@amOrthogonalPosF = -0.28
      resP@amParallelPosF = -0.35
      ;resP@amJust           = "TopLeft"
      
      resP@gsnPanelFigureStringsFontHeightF = 0.05
      gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot
     
     
     
    end do                              ; end SEASON loop

    ;tt_opt        = True
    ;tt_opt@pltType= "pdf"                ; "eps" [default], "pdf", "ps"
    ;taylor_metrics_table("metrics", VAR_COMPARE, CASES ,SEASONS, table, tt_opt)

end
