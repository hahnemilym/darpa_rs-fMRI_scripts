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
set HPF = .02
set MC_nuisreg = rest.mc.txt
set MC_censor = rest.censor.par
set fsd = rest_001
set subdir = 001
#set L_seed = 1035 # ctx-lh-insula (obtained from $FREESUFER_DIR/FreeSurferColorLUT.txt)
#set R_seed = 2035 # ctx-rh-insula (obtained from $FREESUFER_DIR/FreeSurferColorLUT.txt)
set omnibus_seed = omnibus
#set subjects = ($PARAMS_DIR/rs_subjects_12-2-18.txt)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. Configure directory structure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

cd $RS_DIR

#foreach SUBJECT ( `cat $subjects` )
foreach SUBJECT ( hc001 )

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# IV. Preprocess
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#preproc-sess \
#-surface $SUBJECT lhrh \
#-mni305-2mm \
#-s $SUBJECT \
#-fwhm $FWHM \
#-fsd $fsd \
#-per-run \
#-stc siemens \
#-force

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

# Gray matter seed
fcseed-config \
#-segid $omnibus_seed \
-fcname {$omnibus_seed}.dat \
-fsd $fsd \
-mean \
-cfg mean.{$omnibus_seed}.config \
-overwrite

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Extract the time signal from anatomical ROI for subject
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

fcseed-sess \
-s $SUBJECT \
-cfg mean.{$omnibus_seed}.config \
-overwrite

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Uncomment global.waveform.dat to enable GSR
# Uncomment -mcextreg to enable default MC
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

foreach cortices ( lh rh )

mkanalysis-sess \
-analysis fc.{$omnibus_seed}.$cortices \
-surface fsaverage $cortices \
-fwhm $FWHM \
-notask \
#-taskreg {$omnibus_seed}.dat 1 \
-tpexclude $MC_censor \
-nuisreg $MC_nuisreg -1 \
-nuisreg vcsf.dat 5 \
-nuisreg wm.dat 5 \
-polyfit $Pfit \
-nskip $Nskip \
-fsd $fsd \
-TR $TR \
-per-run \
-hpf .01 \
##-nuisreg global.waveform.dat 1 \
##-mcextreg \
-force

end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Run intra-subject rs-fMRI analysis
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

foreach cortices (lh rh )

selxavg3-sess -s $SUBJECT -a fc.{$omnibus_seed}.$cortices -no-con-ok

#selxavg3-sess -s $SUBJECT -a fc.{$MNI_seed}.$space #-no-con-ok

end

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

# Draft group analysis here

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

cd /autofs/space/lilli_001/users/DARPA-Scripts/tutorials/darpa_resting_state_EH

