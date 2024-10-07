process INSTRAIN_PROFILE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/instrain:1.7.1--pyhdfd78af_0' :
        'https://depot.galaxyproject.org/singularity/instrain:1.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(genome_fasta), path(stb_file)
//    path genes_fasta
//    path stb_file

    output:
    tuple val(meta), path("*.IS")                               , emit: profile , optional: true
    tuple val(meta), path("*.IS/output/*.IS_SNVs.tsv")          , emit: snvs, optional: true
    tuple val(meta), path("*.IS/output/*.IS_gene_info.tsv")     , emit: gene_info       , optional: true
    tuple val(meta), path("*.IS/output/*.IS_genome_info.tsv")   , emit: genome_info, optional: true
    tuple val(meta), path("*.IS/output/*.IS_linkage.tsv")       , emit: linkage, optional: true
    tuple val(meta), path("*.IS/output/*.IS_mapping_info.tsv")  , emit: mapping_info, optional: true
    tuple val(meta), path("*.IS/output/*.IS_scaffold_info.tsv") , emit: scaffold_info, optional: true
    path "versions.yml"                                         , emit: versions, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
//    def genes_args = genes_fasta ? "-g ${genes_fasta}": ''
    def stb_args = stb_file ? "-s ${stb_file}": ''
    """
    inStrain \\
        profile \\
        $bam \\
        $genome_fasta \\
        -o ${prefix}.IS \\
        -p $task.cpus \\
        $stb_args \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        instrain: \$(echo \$(inStrain profile --version 2>&1) | awk 'NF{ print \$NF }')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def genes_args = genes_fasta ? "-g ${genes_fasta}": ''
    def stb_args = stb_file ? "-s ${stb_file}": ''
    """
    mkdir -p ${prefix}.IS/output
    touch ${prefix}.IS/output/${prefix}.IS_SNVs.tsv
    touch ${prefix}.IS/output/${prefix}.IS_gene_info.tsv
    touch ${prefix}.IS/output/${prefix}.IS_genome_info.tsv
    touch ${prefix}.IS/output/${prefix}.IS_linkage.tsv
    touch ${prefix}.IS/output/${prefix}.IS_mapping_info.tsv
    touch ${prefix}.IS/output/${prefix}.IS_scaffold_info.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        instrain: \$(echo \$(inStrain profile --version 2>&1) | awk 'NF{ print \$NF }')
    END_VERSIONS
    """
}
