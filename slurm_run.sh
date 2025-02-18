#!/bin/bash

#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --nodelist=
#SBATCH --ntasks-per-node=20
#SBATCH --mem=
# Memory per node specification is in MB. It is optional.
# The default limit is 3000MB per core.
#SBATCH --job-name="eosc-test"
#SBATCH --output=test_rna_predict.output
#SBATCH --mail-user=haris.zafr@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --requeue


# load miniconda
module load miniconda3/default

# activate the conda env for our wf
conda activate EOSC-CWL

# load the Singularity module 
module load singularity/3.7.1

## run the wf
./run_wf.sh -n toil -d cwl-TEST -f test_input/wgs-paired-SRR1620013_1.fastq.gz -r test_input/wgs-paired-SRR1620013_2.fastq.gz

#cwltool --singularity --outdir cwltool-test-assembly workflows/gos_wf.cwl toil.yml

# disable the 
module purge

