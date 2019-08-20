#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
requirements:
  ResourceRequirement:
    coresMax: 1
    ramMin: 1024  # just a default, could be lowered
  DockerRequirement:
    dockerPull: quay.io/biocontainers/seqprep:1.1--1

#hints:
 #SoftwareRequirement:
   #packages:
     #seqprep:
       #specs: [ "https://identifiers.org/rrid/RRID:SCR_013004" ]
       #version: [ "1.1" ]

inputs:
 forward_reads:
   type: File
   format: edam:format_1930  # FASTQ
   label: first read input fastq
   inputBinding:
     prefix: -f
 reverse_reads:
   type: File
   format: edam:format_1930  # FASTQ
   label: second read input fastq
   inputBinding:
     prefix: -r

baseCommand: SeqPrep

arguments:
 - "-1"
 - forward_unmerged.fastq.gz
 - "-2"
 - reverse_unmerged.fastq.gz
 - -s
 - merged.fastq.gz
 # - "-3"
 # - forward_discarded.fastq.gz
 # - "-4"
 # - reverse_discarded.fastq.gz


outputs:
  merged_reads:
    type: File
    format: edam:format_1930  # FASTQ
    outputBinding:
      glob: merged.fastq.gz
  forward_unmerged_reads:
    type: File
    format: edam:format_1930  # FASTQ
    outputBinding:
      glob: forward_unmerged.fastq.gz
  reverse_unmerged_reads:
    type: File
    format: edam:format_1930  # FASTQ
    outputBinding:
      glob: reverse_unmerged.fastq.gz

doc: >
  SeqPrep is a program to merge paired end Illumina reads that are overlapping into a single
  longer read. It may also just be used for its adapter trimming feature without doing any paired
  end overlap. When an adapter sequence is present, that means that the two reads must overlap (in most cases)
  so they are forcefully merged. When reads do not have adapter sequence they must be treated
  with care when doing the merging, so a much more specific approach is taken. The default
  parameters were chosen with specificity in mind, so that they could be ran on libraries where
  very few reads are expected to overlap. It is always safest though to save the overlapping
  procedure for libraries where you have some prior knowledge that a significant portion of
  the reads will have some overlap.

label: Tool for stripping adaptors and/or merging paired reads with overlap into single reads.

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
