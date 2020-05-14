#!/bin/bash
# Set name of job
#PBS -N xxNameOfJobxx
#PBS -o jobOutput.txt
#PBS -j oe
# Specify a queue:
#PBS -q yossarian
#PBS -l nodes=1:ppn=8
# Set your minimum acceptable walltime, format: day-hours:minutes:seconds
#PBS -l walltime=48:00:00
# Set minimum memory usage
#PBS -l mem=80GB
# Email user if job ends or aborts
#PBS -m a
#PBS -M oliver.cliff@sydney.edu.au
#PBS -V

# ---------------------------------------------------
cd "$PBS_O_WORKDIR"

# Show the host on which the job ran
hostname

# Load matlab module
module load Matlab2018a

# Launch the Matlab job
matlab -nodisplay -r "HCTSA_Runscript; exit"
