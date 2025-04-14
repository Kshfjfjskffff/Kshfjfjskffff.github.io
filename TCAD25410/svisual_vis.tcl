# $Id: //tcad/support/main/examples/opto/solarcell/iiiv/sc-iiiv-sj-epi-eqe/svisual_vis.tcl#13 $
	#setdep @node|sdevice@

#; ----------------------------------------
# This script plots
# a) Spectral Current Densities: incident photon current density, photogenerated current density and short-circuit current density 
# b) Reflectance spectra
# c) QE spectra under short-circuit conditions
# 
# The script extracts following parameters:
#	Rtot [%]: Total reflectance
#	jsc [mA/cm2]: Short-circuit current density
#	jsc_eqe [mA/cm2]: Short-circuit current density from EQE
#; ----------------------------------------

# (file →) dataset → variable (y)
# plot → curve (x y)

echo "sourcing libraries"
load_library physicalconstants

set i @node:index@
set wtot @wtot@	;# device width in x direction
set signalIntensity @signalIntensity@ ;# W/cm2

#- Automatic alternating symbol assignment tied to node index
set SYMBOL [list square circle diamond squaref circlef diamondf plus x]
set NSYMBOLS [llength $SYMBOL]
set symbol   [lindex  $SYMBOL [expr $i%$NSYMBOLS]]

echo "defining physical constants"
set h $::const::PlanckConstant ;# unit: kg·m2/s
set c $::const::SpeedOfLight ;# unit: m/s
set q $::const::ElementaryCharge ;# unit: A·s

echo "defining unit conversion factors"
set umtocm 1e-4 ;# 1um = $umtocm * 1cm
set umtom 1e-6 ;# 1um = $umtom * 1m
set AtomA 1e3 ;# 1A = $AtomA * 1mA

echo "defining some parameters"
set iqeFromJphSwitch 0 ;# 1: calculates IQE=Jsc_sig/Jph_sig 0: calculates IQE=EQE/(1-R)
set n @node|sdevice@

echo "defining files to be loaded"
set gc "n${n}_des"
set gcbias "bias_n${n}_des"
set gcspec "n${n}_spec_des"
set spectrum "!(puts -nonewline $spectrum)!"
echo "loading plt files"
load_file $gcbias.plt -name WithBias($n)
load_file $gc.plt -name WithBiasSignal($n)
load_file $gcspec.plt -name Spectrum($n)
# 載入下面這 3 個由 SDEVICE 所匯出的檔案，並將其資料分別放入各資料庫(dataset)中，命名如下 :
# |		File		|	Dataset name		|
# |	------------	|	----------------	|
# |	nX_des.plt		|	WithBiasSignal($n)	|
# |	bias_nX_des.plt	|	WithBias($n)		|
# |	nX_spec_des.plt	|	Spectrum($n)		|

echo "defining datasets"
set dsWavelength "Device=,File=CommandFile/Physics,DefaultRegionPhysics,ModelParameter=Optics/Excitation/Wavelength"
# Wavelength
set dsOpticalGeneration  "IntegrSemiconductor OpticalGeneration"
# Jph
set dsCurrent "cathode TotalCurrent"
# Jsc
set groupNameTMM "LayerStack(unnamed_0)"

echo "creating plots"
if {[lsearch [list_plots] Plot_JSpectra] == -1} {
	create_plot -1d -name Plot_JSpectra
	link_plots [list_plots] -unlink		
}
# 創建一個名為「Plot_JSpectra」的 xy 軸。

if {[lsearch [list_plots] Plot_RQESpectra] == -1} {
	create_plot -1d -name Plot_RQESpectra
	link_plots [list_plots] -unlink		
}
# 創建一個名為「Plot_RQESpectra」的 xy 軸。

# create_plot @ P.232
# link_plots @ P.302 : Links plot properties of two or more plots.
# 	-unlink: Removes linking.
# list_plots @ P.314 : Returns a list of plot names according to the given pattern. If no pattern is specified, all plots are returned.

echo "Plotting Spectral Current Densities"

select_plots Plot_JSpectra ;# Select_plots @ P.344
# 選擇名為「Plot_JSpectra」的 xy plot，進行接下來的操作。

echo "creating wavelength curve"
create_curve -name wl($n) -dataset WithBiasSignal($n) -axisX $dsWavelength -axisY $dsWavelength
# 創建一個名為「wl($n)」的 curve，x 軸與 y 軸皆為名為「WithBiasSignal($n)」的 dataset 中的 $dsWavelength。(之後會刪掉。)
create_variable -name Wavelength -dataset CurrentDensities($n) -values [get_variable_data -dataset WithBiasSignal($n) $dsWavelength]
# 創立一組名為「Wavelength」的 variable，放入名為「CurrentDensities($n)」的 dataset 中，
# variable 的來源為名為「WithBiasSignal($n)」的 dataset 中的 $dsWavelength。這個「Wavelength」變數列在很後面才會用到。

echo "creating incident photon current density (signal) (Jin_sig (mA/cm2)) curve"
create_curve -name Jin_sig($n) -function "$AtomA*$q*<wl($n)>*$umtom*$signalIntensity/($h*$c)"; # unit: mA/cm2
# 創建一個名為「Jin_sig($n)」的 curve，這個 curve 是由名為「wl($n)」的 curve 進行如上的調整的。見 greadme.pdf，P.18，式 (12)。
create_variable -name Jin_sig -dataset CurrentDensities($n) -values [get_curve_data Jin_sig($n) -axisY]
# 創立一組名為「Jin_sig」的 variable，放入名為「CurrentDensities($n)」的 dataset 中，這個 variable 是取自名為「Jin_sig($n)」的 curve 的 y 軸。

remove_curves "wl($n)"
# 將名為「wl($n)」的 curve 刪除。

echo "creating signal photogenerated current density (Jph_sig (mA/cm2)) curve"
# Computing bias photogenerated current density
set intGopt_bias [get_variable_data -dataset WithBias($n) $dsOpticalGeneration]
# 設立一個名為「intGopt_bias」的 list，該 list 取自名為「WithBias($n)」的 dataset 中，$dsOpticalGeneration 的部分。
# 這裡的 intGopt_bias 代表的是 greadme.pdf 中，P.20，式 (31) 中的 N_(ph)^(bias) (\lambda)，單位為 #/s。

set Jph_bias [expr $AtomA*$q*$umtocm*$intGopt_bias/$wtot] ;#mA/cm2
# 設立一個名為「Jph_bias」的 list，該 list 由名為「intGopt_bias」的 list，經過如上的計算而得。

echo [format "Bias photogenerated current density is %.4g mA/cm2" $Jph_bias]

# Computing signal photogenerated current density
set intGopt_tot [get_variable_data -dataset WithBiasSignal($n) $dsOpticalGeneration]
# 設立一個名為「intGopt_tot」的 list，該數列取自名為「WithBiasSignal($n)」的 dataset 中，$dsOpticalGeneration 的部分。
# 這裡的 intGopt_tot 代表的是 greadme.pdf 中，P.20，式 (31) 中的 N_(ph)^(tot) (\lambda)，單位為 #/s。

set Jph_tot [list]
# 設立一個名為「Jph_tot」的空數列。
set Jph_sig [list]
# 設立一個名為「Jph_sig」的空數列。

foreach intGopttot $intGopt_tot {
	# Computing total photogenerated current density 
	set jphtot [expr $AtomA*$q*$umtocm*$intGopttot/$wtot] ;#mA/cm2
	lappend Jph_tot $jphtot
	# Computing signal photogenerated current density by substracting white light bias
	lappend Jph_sig [expr $jphtot - $Jph_bias] ;#mA/cm2
}
# 最後得到我們想要的東西，即名為「Jph_sig」的 list。

create_variable -name Jph_sig -dataset CurrentDensities($n) -values $Jph_sig
# 在名為「CurrentDensities($n)」的 dataset 中建立名為「Jph_sig」的 variable，取自名為「Jph_sig」的 list。
create_curve -name Jph_sig($n) -dataset CurrentDensities($n) -axisX Wavelength -axisY Jph_sig ;#mA/cm2
# 建立一個名為「Jph_sig($n)」的 curve，並將名為「CurrentDensities($n)」的資料庫中，
# 名為「Wavelength」的 variable 與名為「Jph_sig」的 variable 分別設為 X-axis 與 Y-axis。

echo "creating signal short-circuit current density (Jsc_sig (mA/cm2)) curve"
# Computing bias short-circuit current density 
set Jsc_bias [get_variable_data -dataset WithBias($n) $dsCurrent]
set Jsc_bias [lindex $Jsc_bias end]
echo [format "short-circuit current density is %.4g mA/cm2" $Jsc_bias]
# Computing total short-circuit current density 
set Jsc_tot [get_variable_data -dataset WithBiasSignal($n) $dsCurrent]
# Computing total short-circuit current density by substracting white light bias
set Jsc_sig [list]
foreach jsctot $Jsc_tot {
	lappend Jsc_sig [expr $jsctot - $Jsc_bias]
}
create_variable -name Jsc_sig -dataset CurrentDensities($n) -values $Jsc_sig	
create_curve -name Jsc_sig($n) -dataset CurrentDensities($n) -axisX Wavelength -axisY Jsc_sig ;#mA/cm2
	
echo "setting plot properties"
if {[info exists runVisualizerNodesTogether]} { 
	# executed only if visualization wrapper script is used to visualize curves
	set_curve_prop Jin_sig($n)
		-label "J<sub>in</sub> (signal) $legend" 
		-color red
		-line_style solid
		-line_width 3 
		-show_markers
		-markers_size 10
		-markers_type $symbol
	set_curve_prop Jph_sig($n)
		-label "J<sub>ph</sub> (signal) $legend" 
		-color blue
		-line_style solid
		-line_width 3
		-show_markers
		-markers_size 10
		-markers_type $symbol
	set_curve_prop Jsc_sig($n)
		-label "J<sub>sc</sub> (signal) $legend" 
		-color green
		-line_style solid
		-line_width 3
		-show_markers
		-markers_size 10
		-markers_type $symbol
}

echo "Plotting Reflectance spectra"
select_plots Plot_RQESpectra

echo "plotting reflectance spectra"
create_curve -name R($n) -dataset Spectrum($n) \
	-axisX "wavelength" -axisY "$groupNameTMM R_Total"

echo "plotting transmittance spectra"
create_curve -name T($n) -dataset Spectrum($n) \
	-axisX "wavelength" -axisY "$groupNameTMM T_Total"

echo "plotting absorbance spectra"
create_curve -name A($n) -dataset Spectrum($n) \
	-axisX "wavelength" -axisY "$groupNameTMM A_Total"

echo "plotting EQE spectra"
create_curve -name Jin_sig($n) -dataset CurrentDensities($n) \
	-axisX Wavelength -axisY Jin_sig
create_curve -name Jph_sig($n) -dataset CurrentDensities($n) \
	-axisX Wavelength -axisY Jph_sig
create_curve -name Jsc_sig($n) -dataset CurrentDensities($n) \
	-axisX Wavelength -axisY Jsc_sig
create_curve -name EQE($n) -function "<Jsc_sig($n)>/<Jin_sig($n)>"

echo "plotting IQE spectra"
if {$iqeFromJphSwitch} {
	echo "calculating IQE=Jsc/Jph"
	create_curve -name IQE($n) -function "<Jsc_sig($n)>/<Jph_sig($n)>"	
} else {
	echo "calculating IQE=EQE/(1-R)"
	create_curve -name IQE($n) -function "<EQE($n)>/(1-<R($n)>)"
}	
remove_curves "Jin_sig($n) Jph_sig($n) Jsc_sig($n)"

echo "setting curve properties"
if {[info exists runVisualizerNodesTogether]} { 
	# executed only if visualization wrapper script is used to visualize curves
	set_curve_prop R($n)
		-label "Reflectance $legend"
		-color green
		-line_style solid
		-line_width 3
		-show_markers
		-markers_size 10
		-markers_type $symbol
	set_curve_prop T($n)
		-label "Transmittance $legend"
		-color brown
		-line_style solid
		-line_width 3
		-show_markers
		-markers_size10
		-markers_type $symbol
	set_curve_prop A($n)
		-label "Absorbance $legend"
		-color black
		-line_style solid
		-line_width 3
		-show_markers
		-markers_size 10
		-markers_type $symbol	
	set_curve_prop EQE($n) -label "EQE $legend" -color red \
		-line_style solid -line_width 3 \
		-show_markers -markers_size 10 -markers_type $symbol 
	set_curve_prop IQE($n) -label "IQE $legend" -color blue \
		-line_style solid -line_width 3 \
		-show_markers -markers_size 10 -markers_type $symbol 

echo "setting plot properties"
select_plots Plot_JSpectra
set_plot_prop -title "Spectral Current Densities" -title_font_size 20 -show_legend 
set_axis_prop -axis x -title {Wavelength [<greek>m</greek>m]} \
    -title_font_size 16 -label_font_size 14 -type linear 
  set_axis_prop -axis y -title {Current Density [mA/cm<sup>2</sup>]} \
    -title_font_size 16 -label_font_size 14 -type linear \
    -min 0 -min_fixed	
  set_legend_prop -label_font_size 12 -label_font_att bold -location top_left 
  #---
  select_plots Plot_RQESpectra
  set_plot_prop -title "Reflectance and QE Spectra" -title_font_size 20 -show_legend
  set_axis_prop -axis x -title {Wavelength [<greek>m</greek>m]} \
    -title_font_size 16 -label_font_size 14 -type linear
  set_axis_prop -axis y -title {QE / R / T / A [1]} \
    -title_font_size 16 -label_font_size 14 -type linear \
    -min 0 -min_fixed -max 1.01 -max_fixed
  set_legend_prop -label_font_size 12 -label_font_att bold -location top_left 
}


echo "get total reflectance (weighted with spectrum)"
set Rtot [get_variable_data -dataset WithBias($n) "$groupNameTMM R_Total"]
echo "[format "Total reflectance Rtot is %.4g" $Rtot]"


echo "computing jsc from EQE"
create_curve -name ww -dataset Spectrum($n) \
	-axisX "wavelength" -axisY "wavelength"
create_curve -name Iin -dataset Spectrum($n) \
	-axisX "wavelength" -axisY "intensity"
create_curve -name Jin \
	-function "$AtomA*$q*<Iin>/($h*$c/(<ww>*$umtom))" ;# mA/cm2
set Jin_list [get_curve_data Jin -axisY]
set EQE_list [get_curve_data EQE($n) -axisY]
set Jsc_eqe 0
set Jin_bias 0
foreach eqe $EQE_list jin $Jin_list {
	set Jsc_eqe [expr $Jsc_eqe + $eqe*$jin]
	set Jin_bias [expr $Jin_bias + $jin]
}
remove_curves {ww Iin Jin}
echo "[format "incident photon current density is %.4g" $Jin_bias]"
echo "[format "Short-circuit current density from EQE is %.4g" $Jsc_eqe]"


echo "Writing extracted values to SWB"
puts "DOE: Rtot [format %.4g $Rtot]"
puts "DOE: jsc [format %.4g $Jsc_bias]"
puts "DOE: jsc_eqe [format %.4g $Jsc_eqe]"