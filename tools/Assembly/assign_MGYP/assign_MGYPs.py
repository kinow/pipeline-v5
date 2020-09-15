#!/usr/bin/env python3

import argparse
import os
from Bio import SeqIO
import json
import re
import hashlib
import fcntl
from filelock import Timeout, FileLock

WAITING_TIME = 0  # (in sec)
# If timeout <= 0, there is no timeout and this method will block until the lock could be acquired.
# If timeout is None, the default timeout is used.


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--fasta', dest='fasta', required=True, help='Fasta file with proteins')
    parser.add_argument("-a", "--accession", help="run accession", dest="accession", required=True)
    parser.add_argument('-c', '--config', dest='config', required=True, help='path to mapping dir')
    parser.add_argument("-r", "--release", help="release name where to write new accessions", dest="release",
                        required=True)
    parser.add_argument("--private", help="set this option if run is from private request", dest="private",
                        required=False, action='store_true')
    return parser
"""
-f test.fasta \
-a ERZ*** \
-c new_config
    mapping: /nfs/production/interpro/metagenomics/peptide_db/mapping 
    peptides: /nfs/production/interpro/metagenomics/assembly_peptides_v5
    max_pep_length: 10000
-p /nfs/production/interpro/metagenomics/peptide_db/mapping/mgyp/20190531
-r 20200723 or another date
"""

def get_bioms(mapping):
    biome_file = os.path.join(mapping, 'biome', 'all-biomes.txt')
    biome = {}
    with open(biome_file) as bfh:
        for line in bfh:
            acc, b = line.rstrip().split('\t')
            biome[acc] = b
    print('Biome', len(biome))
    return biome


def create_peptides_file(peptides, accession):
    folder = os.path.join(peptides, accession[:7])
    if not os.path.exists(folder):
        os.mkdir(folder)
    subfolder = os.path.join(folder, accession)
    if not os.path.exists(subfolder):
        os.mkdir(subfolder)
    peptides_file = os.path.join(subfolder, 'peptides.txt')
    return peptides_file, subfolder


def create_digest(seq):
    dtype = 'sha256'
    h = hashlib.new(dtype)
    h.update(seq.encode('utf-8'))
    digest = h.hexdigest()
    return digest


def read_map_file(file):
    map = {}
    if not os.path.exists(file):
        return map
    with open(file) as fh:
        for line in fh:
            seq, partial, acc, _ = line.rstrip().split(' ')
            if not seq in map:
                map[seq] = {}
            map[seq][partial] = acc
    print('Length of already existing map-file: ', len(map))
    return map


def map_accessions(seq, partial, map, next_acc, biome, obs_biome, assembly):
    print(seq, partial)
    if seq in map and partial in map[seq]:
        print('found seq and partial in MAP')
        acc = map[seq][partial]
    elif seq in map:
        print('found seq in MAP')
        acc = "MGYP%012d" % next_acc
        next_acc += 1
        map[seq][partial] = acc
    else:
        acc = "MGYP%012d" % next_acc
        next_acc += 1
        map[seq] = {}
        map[seq][partial] = acc

    if assembly in biome:
        b = biome[assembly]
    else:
        b = ''
    if not b in obs_biome:
        obs_biome[b] = 0
    obs_biome[b] += 1
    print('update map file')
    return next_acc, acc


def parsing_header(header):
    if 'partial' in header:
        # prodigal header
        caller = 'Prodigal'
        start_coordinate, stop_coordinate, strand = re.findall(r"#\s(.*?)\s", header)
        id, partial, start_type, stop_type, rbs_motif = re.findall(r"\=(.*?)\;", header)
    else:
        #FGS header
        partial = '11'
        caller = 'FGS'
        list_fields = header.split('_')
        length = len(list_fields)
        sign_strand, stop_coordinate, start_coordinate = list_fields[length-1], list_fields[length-2], list_fields[length-3]
        strand = str(int(sign_strand + '1'))
    return partial, start_coordinate, stop_coordinate, strand, caller


if __name__ == "__main__":

    TYPE = 'mgyp'
    args = get_args().parse_args()
    with open(args.config, 'r') as fc:
        config = json.loads(fc.read())
        mapping_dir = config['mapping']
        max_pep_length = config['max_pep_length']
        peptides = config['peptides']
        if not os.path.exists(peptides): os.mkdir(peptides)
    public_value = 1 if args.private else 0

    peptides_file, peptides_subfolder = create_peptides_file(peptides, args.accession)

    # check mapping dir for existence
    cur_mapping_dir = os.path.join(mapping_dir, TYPE, args.release)
    print('Current mapping directory: ' + str(cur_mapping_dir))
    if not os.path.exists(cur_mapping_dir):
        print("Mapping directory doesn't exist")
        exit(1)

    dict_hash_records, obs_biome, files_hash = [{} for _ in range(3)]
    long_peptides = 0
    used_twochar = []
    # read fasta file, create digests
    for record in SeqIO.parse(args.fasta, "fasta"):
        if len(record.seq) > max_pep_length:
            long_peptides += 1
        hash_seq = create_digest(record.seq)
        twochar = hash_seq[:2]
        if twochar not in dict_hash_records:
            dict_hash_records[twochar] = []
        dict_hash_records[twochar].append(record)
    # write long peprides
    with open(os.path.join(peptides_subfolder, 'long-proteins-number.txt'), 'w') as long_file:
        print('Write number of long peptides: ', os.path.join(peptides_subfolder, 'long-proteins-number.txt'))
        long_file.write(str(long_peptides))

    used_twochar = list(dict_hash_records.keys())
    print('Used twochar hashes: ' + str(used_twochar))
    # prepare dict with names
    for twochar in used_twochar:
        files_hash[twochar] = os.path.join(cur_mapping_dir, twochar)

    biome = get_bioms(mapping_dir)

    file_peptides = open(peptides_file, 'w')
    new_fasta = open(args.accession + '_FASTA.mgyp.fasta', 'w')
    print('New FASTA file: ' + args.accession + '_FASTA.mgyp.fasta')

    # Read the last given accession number
    file_next_accession = os.path.join(cur_mapping_dir, 'max_acc')
    file_next_accession_lock_path = os.path.join(cur_mapping_dir, 'max_acc.lock')
    lock_max_acc = FileLock(file_next_accession_lock_path)

    # wait until max_acc would be available
    with lock_max_acc.acquire(timeout=WAITING_TIME):
        print('Locking max_acc file ...')
        fd = open(file_next_accession, 'r+')
        max = fd.read()
        next_acc = int(max) + 1
        print('Start with accession number ', next_acc)
        fd.seek(0)
        fd.truncate()

        for twochar in dict_hash_records:
            # read existing map-file
            mapping_dir_release = os.path.join(mapping_dir, TYPE, args.release, twochar)
            print('Reading map file from ' + str(mapping_dir_release))
            map = read_map_file(mapping_dir_release)
            print('Process ', twochar, 'peptides', len(dict_hash_records[twochar]), 'size of map: ' + str(len(map)))
            cur_twochar = files_hash[twochar]
            lock_cur_twochar = FileLock(cur_twochar + '.lock')
            with lock_cur_twochar.acquire(timeout=WAITING_TIME):
                file_desc_twochar = open(cur_twochar, 'r+')
                # adding all proteins
                for record in dict_hash_records[twochar]:
                    partial, start_coordinate, stop_coordinate, strand, caller = parsing_header(record.id)
                    next_acc, mgy_accession = map_accessions(map=map, next_acc=next_acc, seq=record.seq, biome=biome,
                                                             partial=partial, assembly=args.accession,
                                                            obs_biome=obs_biome)
                    # write table of protein data
                    file_peptides.write(' '.join([mgy_accession, record.id, start_coordinate, stop_coordinate, strand,
                                                  partial, caller]))
                    record.id = mgy_accession
                    record.description = mgy_accession
                    # write fasta file with new accessions
                    SeqIO.write(record, new_fasta, "fasta")
                    # write new sequences to twochar files
                    file_desc_twochar.write(' '.join([str(record.seq), str(partial), mgy_accession, str(public_value)]) + '\n')
            file_desc_twochar.close()
        # write next accession
        fd.write(str(next_acc))
        fd.close()
    print('... Return max_acc file')
    print('Write biom counts', os.path.join(cur_mapping_dir, 'mgy_biome_counts_' + args.release + '.tsv'))
    with open(os.path.join(cur_mapping_dir, 'mgy_biome_counts_' + args.release + '.tsv'), 'w') as fbiome:
        for b in sorted(obs_biome.items(), key=lambda x: x[1], reverse=True):
            fbiome.write(str(b[1]) + '\t' + b[0] + '\n')

    file_peptides.close()
    new_fasta.close()
