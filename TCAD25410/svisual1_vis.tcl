	#setdep @node|sdevice@

set n @node|sdevice@
set wtot @wtot@	;# device width in x direction
set signalIntensity 0.02 ;# W/cm2

load_file bias_n${n}_des.plt -name WithBias($n)
load_file n${n}_des.plt -name WithBiasSignal($n)
load_file n${n}_spec_des.tdr -name Spectrum($n)

set dsWavelength "Device=,File=CommandFile/Physics,DefaultRegionPhysics,ModelParameter=Optics/Excitation/Wavelength"
set dsCurrent "cathode TotalCurrent"
set dsOpticalGeneration "IntegrSemiconductor OpticalGeneration"

load_library physicalconstants
set h $::const::PlanckConstant
set c $::const::SpeedOfLight
set q $::const::ElementaryCharge

set umtocm 1e-4
set umtom 1e-6
set AtomA 1e3


if {[lsearch [list_plots] Plot_RQESpectra] == -1} {
	create_plot -1d -name Plot_RQESpectra
	link_plots [list_plots] -unlink		
}

set Wavelength_um [get_variable_data -dataset WithBiasSignal($n) $dsWavelength]

set Wavelength_nm [list]
foreach num $Wavelength_um {
	lappend Wavelength_nm [expr $num * 1000]
}

create_variable \
	-name Wavelength \
	-dataset CurrentDensities($n) \
	-values $Wavelength_nm

set Jin_sig {}
foreach num $Wavelength_um {
	lappend Jin_sig [expr {$AtomA*$q*$num*$umtom*$signalIntensity/($h*$c)}]
}
create_variable \
	-name Jin_sig \
	-dataset CurrentDensities($n) \
	-values $Jin_sig

set Jsc_bias [get_variable_data -dataset WithBias($n) $dsCurrent]
set Jsc_tot [get_variable_data -dataset WithBiasSignal($n) $dsCurrent]
set Jsc_sig [list]
foreach jsctot $Jsc_tot {
	lappend Jsc_sig [expr $jsctot - $Jsc_bias]
}
create_variable \
	-name Jsc_sig \
	-dataset CurrentDensities($n) \
	-values $Jsc_sig

select_plots Plot_RQESpectra

create_curve \
	-name Jin_sig($n) \
	-dataset CurrentDensities($n) \
	-axisX Wavelength \
	-axisY Jin_sig

create_curve \
	-name Jsc_sig($n) \
	-dataset CurrentDensities($n) \
	-axisX Wavelength \
	-axisY Jsc_sig

create_curve -name EQE($n) -function "<Jsc_sig($n)>/<Jin_sig($n)>*100"

remove_curves "Jin_sig($n) Jsc_sig($n)"

set_curve_prop EQE($n) \
	-label "Stimulated EQE" \
	-color blue \
	-line_style solid \
	-line_width 4 \
	-show_markers \
	-markers_type circle \
	-markers_size 10 \
	
set_plot_prop \
	-title "EQE Result" \
	-title_font_size 20 \
	-show_grid \
	-show_legend

set_axis_prop -axis x \
	-title {Wavelength (nm)} \
    -title_font_size 16 \
    -label_format fixed \
    -label_font_size 14 \
    -type linear 

set_axis_prop -axis y \
	-title {EQE (%)} \
    -title_font_size 16 \
	-label_font_size 14 \
	-label_format fixed \
	-type linear \
    -min 0 \
    -min_fixed
  
set_legend_prop \
	-label_font_size 12 \
	-label_font_att bold \
	-location top_left 
	
