#!/bin/bash

#SBATCH --job-name=ndp_test                   #This is the name of your job
#SBATCH --cpus-per-task=8                  #This is the number of cores reserved
#SBATCH --mem-per-cpu=4G              #This is the memory reserved per core.
#Total memory reserved: 32GB

#SBATCH --time=1-00:00:00        #This is the time that your task will run
#SBATCH --qos=1day           #You will run in this queue

# Paths to STDOUT or STDERR files should be absolute or relative to current working directory
#SBATCH --output=/PATH/TO/ndp/stdout     #These are the STDOUT and STDERR files
#SBATCH --error=/PATH/TO/ndp/stderr

#This job runs from the current working directory


#Remember:
#The variable $TMPDIR points to the local hard disks in the computing nodes.
#The variable $HOME points to your home directory.
#The variable $SLURM_JOBID stores the ID number of your job.


#load your required modules below
#################################
module purge
module load Java/11.0.3_7

#export your required environment variables below
#################################################

#add your command lines below
#############################
nextflow run ndp.nf