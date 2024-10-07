process FILTER_BAM {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(sub_contigs), path(bam)

    output:
    tuple val(meta), path(sub_contigs), path("*.fastq.gz"), emit: sp_sub_fastq
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools faidx $sub_contigs
    awk '{print \$1,0,\$2+1}' ${sub_contigs}.fai > ${prefix}.sub_ref.bed
    samtools view -@ ${task.cpus} -h -L ${prefix}.sub_ref.bed $bam | samtools sort -n -@ 1 -o ${prefix}.sub_filt.bam -

    samtools fastq -@ ${task.cpus} -s unpaired.remove.gz -1 ${prefix}.${meta.bin}_1.fastq.gz -2 ${prefix}.${meta.bin}_2.fastq.gz ${prefix}.sub_filt.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
