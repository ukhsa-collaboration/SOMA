process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' :
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' }"

    input:
    tuple val(meta), path(tiara_assignments), path(bam)

    output:
    tuple val(meta), path("*.bam"),  emit: bam,     optional: true
    tuple val(meta), path("*.cram"), emit: cram,    optional: true
    tuple val(meta), path("*.sam"),  emit: sam,     optional: true
    tuple val(meta), path("*.bai"),  emit: bai,     optional: true
    tuple val(meta), path("*.csi"),  emit: csi,     optional: true
    tuple val(meta), path("*.crai"), emit: crai,    optional: true
    path  "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
//    def reference = fasta ? "--reference ${fasta}" : ""
    def file_type = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt bam") ? "bam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    bam.getExtension()
//    if ("$bam" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    samtools \\
        view \\
        --threads ${task.cpus-1} \\
        $args \\
        -o ${prefix}.${file_type} \\
        $bam \\
        $args2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def file_type = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt bam") ? "bam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    input.getExtension()
    if ("$input" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"

    def index = args.contains("--write-index") ? "touch ${prefix}.csi" : ""

    """
    touch ${prefix}.${file_type}
    ${index}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
