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
module load singularity/3.6.2




outputPrefix=example
normal_id=example_BS_GL_sorted
tumor_id=example_tumor_sorted
bamNormal=/lohhla/example-file/bam/example_BS_GL_sorted.bam
bamTumor=/lohhla/example-file/bam/example_tumor_sorted.bam
hlaFasta=/juno/work/greenbaum/software/polysolver/v4/data/abc_complete.fasta
hlaDat=/juno/work/greenbaum/database/HLA/hla.dat
tumor_purity_ploidy=/juno/work/greenbaum/users/lih7/test/lohhla_test/lohhla/example-file/tumor_purity_ploidy.txt
hla_file=/juno/work/greenbaum/users/lih7/test/lohhla_test/lohhla/example-file/hlas

img_path=/juno/work/greenbaum/software/images/lohhla_1.1.3.sif
singularity exec --bind /juno/work $img_path \
    Rscript --no-init-file /juno/work/greenbaum/users/lih7/test/lohhla_test/lohhla/LOHHLAscript.R \
        --patientId ${outputPrefix} \
        --normalID ${normal_id} \
        --tumorID ${tumor_id} \
        --normalBAMfile ${bamNormal} \
        --tumorBAMfile ${bamTumor} \
        --HLAfastaLoc ${hlaFasta} \
        --HLAexonLoc ${hlaDat} \
        --CopyNumLoc $tumor_purity_ploidy \
        --hlaPath $hla_file \
        --gatkDir /picard-tools \
        --novoDir /opt/conda/bin \
        --outputDir /juno/work/home/$USER/new_results




