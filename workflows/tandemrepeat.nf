/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_tandemrepeat_pipeline'

include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { FASTA_INDEX                 } from '../modules/local/fasta_index'
include { TRF                         } from '../modules/local/trf'
include { ULTRA                       } from '../modules/local/ultra'
include { VAMPIRE                     } from '../modules/local/vampire'

workflow TANDEMREPEAT {

    take:
    ch_samplesheet // channel: [ val(meta), path(fasta) ]
    ch_fasta       // channel: path(fasta)

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_samplesheet
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Index reference genome if needed
    //
    FASTA_INDEX (
        ch_fasta
    )
    ch_versions = ch_versions.mix(FASTA_INDEX.out.versions)

    // Parse tools parameter
    def tools = params.tools ? params.tools.split(',').collect{ it.trim().toLowerCase() } : []

    //
    // MODULE: Run TRF for tandem repeat detection
    //
    ch_trf_results = Channel.empty()
    if (tools.contains('trf')) {
        TRF (
            INPUT_CHECK.out.fasta
        )
        ch_trf_results = TRF.out.dat
        ch_versions = ch_versions.mix(TRF.out.versions)
    }

    //
    // MODULE: Run ULTRA for tandem repeat detection
    //
    ch_ultra_results = Channel.empty()
    if (tools.contains('ultra')) {
        ULTRA (
            INPUT_CHECK.out.fasta,
            FASTA_INDEX.out.index
        )
        ch_ultra_results = ULTRA.out.gff
        ch_versions = ch_versions.mix(ULTRA.out.versions)
    }

    //
    // MODULE: Run Vampire for tandem repeat detection
    //
    ch_vampire_results = Channel.empty()
    if (tools.contains('vampire')) {
        VAMPIRE (
            INPUT_CHECK.out.fasta
        )
        ch_vampire_results = VAMPIRE.out.bed
        ch_versions = ch_versions.mix(VAMPIRE.out.versions)
    }

    //
    // Collate and save software versions
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo   ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()

    summary_params      = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}
