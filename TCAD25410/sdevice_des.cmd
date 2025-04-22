# Parameters: signalIntansity, av, TrapDensity

!(
	set spectrum "@pwd@/par/spectra/wl20.txt"
	set spectrumstart 0.4
	set spectrumend 1.1
	set wavelengthlist {}
	set fid [open $spectrum r]
	while { [gets $fid LINE] >= 0 } {
		set LINE [string trim $LINE]
		if { [string range $LINE 0 0] == "#" || [string length $LINE] == 0} {continue}
		if {![regexp {^[0-9\.eE\-\+]+} [lindex $LINE 0]]} {continue}
		set w [lindex $LINE 0]
		if {$spectrumstart <= $w && $w <= $spectrumend} {lappend wavelengthlist $w}
	}
	close $fid
	set wavelengthlist [lsort -real $wavelengthlist]
	set wstart [lindex $wavelengthlist 0]
	set wend [lindex $wavelengthlist end]
	set wsteps [llength $wavelengthlist]
	puts "* wavelength range: \[$wstart, $wend\] entries: $wsteps"
	set timelist {}
	foreach w $wavelengthlist {
		lappend timelist [expr 1.*($w-$wstart)/($wend-$wstart)]
	}
)!

# Now, we have: wstart, wend, wsteps, wavelengthlist, timelist.

File {
	*-Input
		Grid=         "@tdr@"
		Parameter=    "@mprpar@"
		IlluminationSpectrum= "!(puts -nonewline $spectrum)!"
	*-Output	
		Current=      "@plot@"
		Plot=         "@tdrdat@"
		SpectralPlot= "n@node@_spec"
		Output=       "@log@"
}

Electrode {
	{ Name= "anode"  Voltage= @av@ }
	{ Name= "cathode"  Voltage= 0 }
}

*--------------------------------------------------
Plot {
*- Doping Profiles
	DopingConcentration DonorConcentration AcceptorConcentration
*- Band structure
	BandGap BandGapNarrowing ElectronAffinity
	ConductionBandEnergy ValenceBandEnergy
	eQuasiFermiEnergy hQuasiFermiEnergy		
*- Carrier Densities:
  	eDensity hDensity
	EffectiveIntrinsicDensity IntrinsicDensity
*- Fields, Potentials and Charge distributions
	ElectricField/Vector
	Potential
	SpaceCharge	
*- Currents	
	Current/Vector eCurrent/Vector  hCurrent/Vector
	CurrentPotential	* for visualizing current flow lines
	eMobility hMobility
*- Generation/Recombination	
	srhRecombination AugerRecombination TotalRecombination SurfaceRecombination
	RadiativeRecombination eLifeTime hLifeTime	
*- Optical Generation	
  ComplexRefractiveIndex QuantumYield
	OpticalIntensity AbsorbedPhotonDensity OpticalGeneration	
}

*--------------------------------------------------
CurrentPlot {
	ModelParameter="Wavelength"
	OpticalGeneration(Integrate(Semiconductor)) *used to calculate IQE in Inspect
	AbsorbedPhotonDensity(Integrate(Semiconductor) ) 
}
*--------------------------------------------------
Physics {
	AreaFactor= @< 1e11/wtot>@ * to get current in mA/cm^2
	Fermi
	HeteroInterface
# ==============================================================
#	Recombination(
#	* Typical, Ch.16.
#		SRH
#		Auger
#		Radiative
#	* Trap-asisted Tunnel Model, Ch.16, P.553.
#		SRH(
#			ElectricField(
#				Lifetime=Constant
#				Lifetime=Hurkx
#				Lifetime=Schenk
#			)
#		)
#		SRH(
#			NonlocalPath(
#				Lifetime=Hurkx
#				Fermi
#				TwoBand
#			)
#		)
#	* Band to band tunneling, Ch.16, P.553.
#		Band2Band(
#			Model = Schenk
#			Model = Hurkx
#			Model = modifiedHurkx
#			Model = E1
#			Model = E1_5
#			Model = E2
#			Model = NonlocalPath
#			DensityCorrection = Local | None
#			InterfaceReflection | -InterfaceReflection
#			FranzDispersion | -FranzDispersion
#			ParameterSetName = (<string>...)
#		)
#	)
# -------------------------------------------------------------
	#if @SRH@ == 1
	Recombination(SRH)
	#elif @SRH@ == 2
	Recombination(
		SRH(
			ElectricField(Lifetime=Hurkx)
		)
	)
	#endif	
# ================================================================
	Mobility(ConstantMobility)
	EffectiveIntrinsicDensity(NoBandGapNarrowing)
	Optics(
		* 1
		ComplexRefractiveIndex (WavelengthDep(Real Imag))
		* 2
		Excitation (
			Wavelength = !(puts -nonewline $wstart)! * Incident light wavelength [um]
			Theta= 0			* Normal incidence
			Polarization= 0.5	* Unpolarized light
			Intensity  = 0		* Incident light intensity [W/cm2]
			Window (
				Line (  
				* for 1D we have no front metalization
				X1= 0
				X2= @wtot@
				) *end Line
			) * end window
		) * end Excitation
		* 3
		OpticalGeneration (
			QuantumYield (
				StepFunction (EffectiveBandgap)
			) * generated carriers/photon, default: 1
			ComputeFromSpectrum(
				Select(
					Condition="!(puts -nonewline $spectrumstart)! <= $wavelength && $wavelength <= !(puts -nonewline $spectrumend)!"
				)
				keepSpectralData
			)
			ComputeFromMonochromaticSource
		) * end OpticalGeneration

		* 4
		OpticalSolver (
			TMM (
				IntensityPattern= StandingWave
				LayerStackExtraction ()*end LayerStackExtraction
			) *end TMM
		)	* end OpticalSolver
	) * end optics
}


	#if @Trap@ == 1
# Active Layer
Physics (Region="MAPbI3") {
	Traps(
		Donor
		Level
		fromValBand
		EnergyMid=0.6
		Conc=1E14
		Tunneling(Hurkx)
	)
}

# ETL
Physics (Region="PCBM") {
	Traps(
		Donor
		Level
		fromCondBand
		EnergyMid=0.01
		Conc=1e15
		Tunneling(Hurkx)
	)
}

# HTL
Physics (Region="PEDOT") {
	Traps(
		Acceptor
		Level
		fromCondBand
		EnergyMid=0.2
		Conc=1e15
		Tunneling(Hurkx)
	)
}
	#endif


# For Math section, see Chapter 6, P.200.
Math {
	Extrapolate 
#	* Convergence and Error Control,  P. 204~206.
	Iterations=200				* Default: 50
	-RhsAndUpdateConvergence	* Default.
	RhsFactor=1e101				* Default: 1e10
	RhsFactor1=1e102			* I dont know what it is but it appears in the LogFile.
	RhsMin=1e-5					* Default.
	RhsMinFactor=1e-5			* Default.
	RhsMax=1e15					* Default.
	RhsMaxQ=1e100				* Default.
	-CheckRhsAfterUpdate		* Default , + or -.	
	RelErrControl				* Default, + or -.
	Digits=6					* Defauly: 5
	ErrRef(Poisson)=0.0258		* Default, [V].
	ErrRef(Electron)=1e10		* Default, [cm-3].
	ErrRef(Hole)=1e10			* Default, [cm-3].
	UpdateIncrease=1.e100		* Default.
	UpdateMax=1.e100			* Default.
#	* Damped Newton Iterations,  P. 206~207.	Methods: Line searth damping & Bank-Rose damping(v)
#	LineSearthDamping=1			* Default.
	Notdamped=50
#	* Derivatives, P. 207
	Derivatives						* Default, + or -.
	AvalDerivatives					* Default, + or -.
#	* Linear Sovlers, P. 213~P. 214	
	Method= Blocked				* Default, P.213. See Table 226 on P. 1589.
	SubMethod=ParDiSo				* See Table 226 on P. 1589.
#	SubMethod=Super				* See Table 226 on P. 1589.
#	* ??, P. 222??
#	AutoCNPMinStepFactor=0.1
#	AutoNPMinStepFactor=0.1
# 	Traps(Damping=10)
	ExitOnFailure
}

Solve{
	NewCurrentPrefix= "tmp_"
	Poisson
	
	* get bias current without monochromatic light
	NewCurrentPrefix = "bis_"
	Coupled {Poisson Electron Hole}
	
	NewCurrentPrefix= ""                    
	* switch on monochromatic light
	Quasistationary ( 
		InitialStep = 1
		MaxStep = 1
		Minstep = 1
		Goal {
			modelParameter="Intensity"
			value=@signalIntensity@ 
		}
	)
	{
		Coupled {Poisson Electron Hole}
		# Plot(FilePrefix=n@node@ NoOverwrite)
	}

	* ramp through wavelength
	Quasistationary ( 
		InitialStep = 1
		MaxStep = 1
		Minstep = 1
		Goal { modelParameter="Wavelength" value=!(puts -nonewline $wend)! }
		){ 
		Coupled {Poisson Electron Hole}
		Plot(FilePrefix=n@node@ NoOverwrite)
 		CurrentPlot(Time=(!(puts -nonewline "[join [lrange $timelist 1 end] "\;"]")!))
		}
	System("rm -f tmp*") *remove the plot we dont need anymore.              
}