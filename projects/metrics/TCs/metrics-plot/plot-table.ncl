;***********************************************************
; csv_2.ncl
;
; Concepts illustrated:
;   - Reading a CSV file
;   - Using str_get_field to parse a string
;   - Using conversion functions to convert strings to numeric values
;   - Reading an ASCII file with delimiters
;
;***********************************************************
; This is an example of reading a CSV file that has string,
; integer, and float fields.
;***********************************************************

begin

  plot_bias=True
  invert_stoplight=False

  filename = "../csv-files/metrics_climo_mean.csv"

  lines = asciiread(filename,-1,"string")
  delim = ","

  ; get nvars by going to first line, finding number of entries
  ; and subtracting one because we don't want to count the model title
  nvars=dimsizes(str_split(lines(1),delim))-1

  header_name    = str_get_field(lines(0),1,delim)

  header = new(nvars,"string")
  do jj = 0,nvars-1
    header(jj) = str_get_field(lines(0),jj+2,delim)
  end do

  name_var  =           str_get_field(lines(2:),1,delim)
  ncases = dimsizes(name_var)
  var    = new((/nvars,ncases/),"float")
  varref = new((/nvars/),"float")

  do ii = 0,nvars-1
    varref(ii) = tofloat(str_get_field(lines(1),ii+2,delim))
    var(ii,:) = tofloat(str_get_field(lines(2:),ii+2,delim))
  end do

  if (plot_bias) then
    do ii = 0,nvars-1
      var(ii,:) = var(ii,:) - varref(ii)
    end do
  end if



; Sub header
  ncr2  = (/1,nvars/)               ; 2 rows, 2 columns
  x2    = (/0.2,1.0/)       ; Start and end X
  y2    = (/0.925,1.0/)       ; Start and end Y
  text2 = header

; Main table body
  ncr3  = (/ncases,nvars+1/)              ; 16 rows, 3 columns
  x3    = (/0.0,1.0/)       ; Start and end X
  y3    = (/0.0,0.925/)       ; Start and end Y

  xreshape = reshape(name_var,(/ncases,1/))
  printVarSummary(xreshape)
  do ii = 0,nvars-1
    if (ii .eq. 0) then
      text3 := table_attach_columns(reshape(name_var,(/ncases,1/)), reshape(sprintf("%5.2f", var(ii,:)),(/ncases,1/)), 0)
    else
      text3 := table_attach_columns(text3, reshape(sprintf("%5.2f", var(ii,:)),(/ncases,1/)), 0)
    end if
  end do

  wks = gsn_open_wks("png","table")  ; send graphics to PNG file

  if (plot_bias) then
    cmap = read_colormap_file("hotcold_18lev")
  else
    if (invert_stoplight) then
      cmap = read_colormap_file("excel_greentored.rgb")
    else
      cmap = read_colormap_file("excel_redtogreen.rgb")
    end if
  end if
  gsn_define_colormap(wks,cmap(:,0:2))
  tmpdims=dimsizes(cmap)

  ncolors=tofloat(tmpdims(0))
  ncolors=ncolors-2-1
  print(ncolors+" ")

  setvalues wks            
    "wkBackgroundColor" : (/1.,1.,1./) 
    "wkForegroundColor" : (/0.,0.,0./)  
  end setvalues
;
; Sub header
;
  res2               = True
  res2@txFontHeightF = 0.022

  gsn_table(wks,ncr2,x2,y2,text2,res2)

;
; Main body of table.
;
  res3 = True             ; Set up resource list

  res3@gsnDebug = True     ; Useful to print NDC row,col values used.

  res3@txFontHeightF = 0.022
  
  FillColors = new(dimsizes(text3),"string")
  FillColors = "white"
  
  do ii = 1,nvars  
    if (plot_bias) then
      minVal=-1.*max(abs(tofloat(text3(:,ii))))
      maxVal= 1.*max(abs(tofloat(text3(:,ii))))
    else
      maxVal = max(tofloat(text3(:,ii)))
      minVal = min(tofloat(text3(:,ii)))
    end if
    do zz = 0,ncases-1
      thisVal=tofloat(text3(zz,ii))
      percentage = (thisVal - minVal) / (maxVal - minVal)
      percentage = max((/0.,percentage/))
      percentage = min((/1.,percentage/))
      FillColors(zz,ii) = floor(ncolors*percentage)+2
      print(name_var(zz)+" "+percentage+"   "+floor(ncolors*percentage)+" "+FillColors(zz,ii))
    end do
  end do
  

  res3@gsFillColor = FillColors

  ;draw_color_palette(wks,cmap,False)  

  gsn_table(wks,ncr3,x3,y3,text3,res3)

  frame(wks)      ; Advance the frame.


end
