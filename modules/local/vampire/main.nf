process VAMPIRE {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::vampire"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vampire:1.0--pyhdfd78af_0' :
        'biocontainers/vampire:1.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.bed"), emit: bed
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--min-motif-size 1 --max-motif-size 20'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    vampire \
        $fasta \
        ${prefix}.vampire.bed \
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vampire: \$(vampire --version 2>&1 | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "chr1\\t100\\t200\\tATCG\\t10\\t+" > ${prefix}.vampire.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vampire: 1.0
    END_VERSIONS
    """
}
