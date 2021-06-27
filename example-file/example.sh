#!/bin/bash
#BSUB -J lohhla[1]
#BSUB -n 1
#BSUB -R rusage[mem=2]
#BSUB -W 01:00
#BSUB -o logs/my_job_%J_%I.stdout -e logs/my_job_%J_%I.err

module load bedtools
module load samtools
module load R/R-4.0.4 # for R package requirements
module load novocraft
module load java
module load picard/2.11.0
module load jellyfish

# If these commands are not already in your path, they must be added or pointed to
#alias samtools=/path/to/samtools
#alias jellyfish=/path/to/jellyfish
#alias bedtools=/path/to/bedtools
lohhla_dir=/work/greenbaum/software/lohhla

Rscript $lohhla_dir/LOHHLAscript.R  \
--patientId example  \
--outputDir /work/greenbaum/users/lih7/test/lohhla_test/  \
--normalBAMfile /work/greenbaum/software/lohhla/example-file/bam/example_BS_GL_sorted.bam  \
--BAMDir $lohhla_dir/example-file/bam/   \
--hlaPath $lohhla_dir/example-file/hlas \
--HLAfastaLoc $lohhla_dir/data/example.patient.hlaFasta.fa \
--CopyNumLoc $lohhla_dir/example-file/solutions.txt \
--mappingStep TRUE \
--minCoverageFilter 10 \
--fishingStep TRUE \
--cleanUp FALSE \
--gatkDir $PICARDJAR \
--novoDir /juno/work/greenbaum/software/modules/novocraft/3.07.00/




