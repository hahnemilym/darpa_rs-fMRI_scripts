#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# I. Set up environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
source /usr/local/freesurfer/nmr-stable60-env

# Local Directory
setenv DIR /autofs/space/lilli_

# Subjects Directory
setenv SUBJECTS_DIR ${DIR}001/users/DARPA-Recons

# Analysis Directory
setenv ANALYSES_DIR ${DIR}001/users/DARPA-Scripts/tutorials/darpa_msit_ecr_pipeline/scripts

# Project Directory
setenv RS_DIR ${DIR}003/users/DARPA-RestingState

# Parameters Directory
setenv PARAMS_DIR $RS_DIR/RS_parameters/

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Uncomment #LPF to enable low-pass filter (controversial)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set FWHM = 6 
set TR = 3
set Nskip = 4
set Pfit = 5
#set LPF = ______
set HPF = .01
set MC_nuisreg = rest.mc.txt
set MC_censor = rest.censor.par
set fsd = rest_001
set subdir = 001
set L_seed = 1035 # lh-insula (obtained from $FREESUFER_DIR/FreeSurferColorLUT.txt)
set R_seed = 2035 # rh-insula (obtained from $FREESUFER_DIR/FreeSurferColorLUT.txt)
set subjects = ($PARAMS_DIR/rs_subjects_12-2-18.txt)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. Configure directory structure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

cd $RS_DIR

foreach SUBJECT ( `cat $subjects` )
#foreach SUBJECT ( hc001 )

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# IV. Preprocess
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

preproc-sess \
-surface $SUBJECT lhrh \
-mni305-2mm \
-s $SUBJECT \
-fwhm $FWHM \
-fsd $fsd \
-per-run \
-stc siemens \
-force

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# V. Generate WM and CSF regressors
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

fcseed-config \
-wm -fcname wm.dat \
-fsd $fsd \
-pca \
-cfg wm.config \
-overwrite

fcseed-config \
-vcsf \
-fcname vcsf.dat \
-fsd $fsd \
-pca \
-cfg vcsf.config \
-overwrite

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# VI. Extract nuisance regressors for WM and CSF
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

fcseed-sess \
-s $SUBJECT \
-cfg vcsf.config

fcseed-sess \
-s $SUBJECT \
-cfg wm.config

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Generate cfg file for the ROI to extract time signal
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# L hemispherere seed
fcseed-config \
-segid $L_seed \
-fcname $L_seed.lh.dat \
-fsd $fsd \
-mean \
-cfg mean.{$L_seed}.lh.config \
-overwrite

# R hemispherere seed

fcseed-config \
-segid $R_seed \
-fcname $R_seed.rh.dat \
-fsd $fsd \
-mean \
-cfg mean.{$R_seed}.rh.config \
-overwrite

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Extract the time signal from anatomical ROI for subject
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

fcseed-sess \
-s $SUBJECT \
-cfg mean.{$L_seed}.lh.config \
-overwrite

fcseed-sess \
-s $SUBJECT \
-cfg mean.{$R_seed}.rh.config \
-overwrite

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Uncomment global.waveform.dat to enable GSR
# Uncomment -mcextreg to enable default MC
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

mkanalysis-sess \
-analysis fc.{$L_seed}.lh \
-surface fsaverage lh \
-fwhm $FWHM \
-notask \
-taskreg $L_seed.lh.dat 1 \
-tpexclude $MC_censor \
-nuisreg $MC_nuisreg -1 \
-nuisreg vcsf.dat 5 \
-nuisreg wm.dat 5 \
-polyfit $Pfit \
-nskip $Nskip \
-fsd $fsd \
-TR $TR \
-per-run \
-hpf .02 \
##-nuisreg global.waveform.dat 1 \
##-mcextreg \
-force

mkanalysis-sess \
-analysis fc.{$R_seed}.rh \
-surface fsaverage rh \
-fwhm $FWHM \
-notask \
-taskreg $R_seed.rh.dat 1 \
-tpexclude $MC_censor \
-nuisreg $MC_nuisreg -1\
-nuisreg vcsf.dat 5 \
-nuisreg wm.dat 5 \
-polyfit $Pfit \
-nskip $Nskip \
-fsd $fsd \
-TR $TR \
-per-run \
-hpf .02 \
##-nuisreg global.waveform.dat 1 \
##-mcextreg \
-force

#foreach subcortices (mni305)

#mkanalysis-sess \
#-analysis fc.{$MNI_seed}.$subcortices \
#-mni305 \
#-fwhm $FWHM \
#-notask \
#-taskreg {$MNI_seed}.mni305.dat -1 \
#-tpexclude $MC_censor \
#-nuisreg $MC_nuisreg -1\
#-nuisreg vcsf.dat 5 \
#-nuisreg wm.dat 5 \
#-polyfit $Pfit \
#-nskip $Nskip \
#-fsd $fsd \
#-TR $TR \
#-per-run \
#-hpf .02 \
##-nuisreg global.waveform.dat 1 \
##-mcextreg \
#-force \

#end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Run intra-subject rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#foreach space (lh rh mni305)

selxavg3-sess -s $SUBJECT -a fc.{$L_seed}.lh #-no-con-ok

selxavg3-sess -s $SUBJECT -a fc.{$R_seed}.rh #-no-con-ok

#selxavg3-sess -s $SUBJECT -a fc.{$MNI_seed}.$space #-no-con-ok

#end

# end subjects loop
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Contacenate subjs for intra-subject rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#foreach cortices (lh rh)

#isxconcat-sess -sf $subjects -analysis fc.omnibus.$cortices -all-contrasts -o group.predictors -hemis

#end

#foreach subcortices (mni305)

#isxconcat-sess -sf $subjects -analysis fc.omnibus.$subcortices -all-contrasts -o group.predictors

#end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Run intra-subject rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Draft group analysis here --> selxavg3-sess for 2L

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

cd /autofs/space/lilli_001/users/DARPA-Scripts/tutorials/darpa_resting_state_EH

