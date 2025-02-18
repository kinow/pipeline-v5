#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
    forward_reads: File?
    reverse_reads: File?  
    paired_reads_length_filter: int

    qc: boolean

steps:

# ----- PAIRED-END PART -----

# << unzipping paired reads >>
  count_submitted_reads:
    run: ../../utils/count_lines/count_lines.cwl
    when: $(inputs.single == undefined)
    in:
      single: single_reads
      sequences: forward_reads
      number: { default: 4 }
    out: [ count ]

# filter paired-end reads (for single do nothing)
  filter_paired:
    run: ../../tools/fastp/fastp.cwl
    in:
      fastq1: forward_reads
      fastq2: reverse_reads
      merge: {default: false}
      min_length_required: min_length_required
      disable_trim_poly_g: disable_trim_poly_g
      force_polyg_tail_trimming: force_polyg_tail_trimming
      threads: threads
      overlap_min_len: overlap_min_len
      unqualified_phred_quality: unqualified_phred_quality
      qualified_phred_quality: qualified_phred_quality

    out: [ out_fastq1, out_fastq2, json_report ]  # unzipped

# << SeqPrep only for paired reads with qc >>
  overlap_reads:
    label: Paired-end overlapping reads are merged
    run: ../../tools/SeqPrep/seqprep.cwl
    when: $(inputs.qc == true)
    in:
      qc: qc
      forward_reads: filter_paired/out_fastq1
      reverse_reads: filter_paired/out_fastq2
      namefile: forward_reads
    out: [ merged_reads, forward_unmerged_reads, reverse_unmerged_reads ]  # compressed

# << SeqPrep only for paired reads no-qc >>
  overlap_reads_noqc:
    label: Paired-end overlapping reads are merged
    run: ../../tools/SeqPrep/seqprep.cwl
    when: $(inputs.qc == false)
    in:
      qc: qc
      forward_reads: forward_reads
      reverse_reads: reverse_reads
      namefile: forward_reads
    out: [ merged_reads, forward_unmerged_reads, reverse_unmerged_reads ]  # compressed

# << unzip merged reads with qc >>
  unzip_merged_reads:
    when: $(inputs.qc == true)
    run: ../../utils/multiple-gunzip.cwl
    in:
      qc: qc
      target_reads: overlap_reads/merged_reads
      reads: { default: true }
    out: [ unzipped_file ]

# << unzip merged reads without qc >>
  unzip_merged_reads_noqc:
    when: $(inputs.target_reads != undefined && inputs.qc == false)
    run: ../../utils/multiple-gunzip.cwl
    in:
      qc: qc
      target_reads: overlap_reads_noqc/merged_reads
      reads: { default: true }
    out: [ unzipped_file ]


outputs:
  unzipped_single_reads:
    type: File
    outputSource:
      - unzip_merged_reads/unzipped_file
      - unzip_merged_reads_noqc/unzipped_file
    pickValue: first_non_null

  count_forward_submitted_reads:
    type: int
    outputSource:
      - count_submitted_reads/count
      - count_submitted_reads_single/count
    pickValue: first_non_null

  fastp_report:
    type: File?
    outputSource: filter_paired/json_report


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
