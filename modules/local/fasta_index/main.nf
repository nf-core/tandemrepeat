process FASTA_INDEX {
    tag "$fasta"
    label 'process_low'

    conda "bioconda::samtools=1.19.2"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_1' :
        'biocontainers/samtools:1.19.2--h50ea8bc_1' }"

    input:
    path fasta

    output:
    path "*.fai"       , emit: index
    path "*.gzi"       , emit: gzi, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    samtools \
        faidx \
        $args \
        $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
