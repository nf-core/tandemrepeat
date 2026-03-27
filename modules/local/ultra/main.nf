process ULTRA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::ultra biochannel::repeatmasker"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ultra:0.1--pyhdfd78af_0' :
        'biocontainers/ultra:0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path(fai)

    output:
    tuple val(meta), path("*.gff")   , emit: gff
    tuple val(meta), path("*.gff.gz"), emit: gff_gz, optional: true
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Create ULTRA index if not exists
    if [ ! -d "ultra_index" ]; then
        ultra index \
            $fasta \
            ultra_index
    fi

    # Run ULTRA annotation
    ultra align \
        ultra_index \
        $fasta \
        ${prefix}.ultra.gff \
        --gff \
        $args

    # Compress output if needed
    if [ -f "${prefix}.ultra.gff" ]; then
        gzip -c ${prefix}.ultra.gff > ${prefix}.ultra.gff.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ultra: \$(ultra --version 2>&1 | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.ultra.gff
    touch ${prefix}.ultra.gff.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ultra: 0.1
    END_VERSIONS
    """
}
