version 1.0

import "https://raw.githubusercontent.com/UW-GAC/primed-file-checks/main/validate_genotype_model.wdl" as validate

workflow sim_admixed {
    input {
        Map[String, Map[String, Map[String, File]]] pgen
        Array[String] chrom
        Array[String] pop
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
        Int run_id = 1
        String source_data
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean import_tables = true
        Boolean overwrite = true
    }

    scatter(c in chrom) {
        scatter (p in pop) {
            call hapgen2 {
                input: pgen = pgen[c][p],
                       chrom = c,
                       build = build,
                       n_indiv = n_indiv
            }
        }

        call admix_simu {
            input: pgen = hapgen2.out_pgen,
                   psam = hapgen2.out_psam,
                   pvar = hapgen2.out_pvar,
                   admix_prop = admix_prop,
                   build = build,
                   n_indiv = n_indiv,
                   n_gen = n_gen
        }
    }

    call sim_data_model {
        input: pgen = admix_simu.out_pgen,
               psam = admix_simu.out_pgen[1]["psam"],
               lanc = admix_simu.out_lanc,
               chrom = chrom,
               pop = pop,
               admix_prop = admix_prop,
               build = build,
               n_indiv = n_indiv,
               n_gen = n_gen,
               run_id = run_id,
               source_data = source_data
    }

    call validate.results {
        input: table_files = sim_data_model.table_files,
               model_url = model_url,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    output {
        Array[Map[String, File]] out_pgen = admix_simu.out_pgen
        Array[File] out_lanc = admix_simu.out_lanc
        Map[String, File] table_files = sim_data_model.table_files
        File validation_report = results.validation_report
        Array[File]? tables = results.tables
    }
    
    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task hapgen2 {
    input {
        Map[String, File] pgen
        String chrom
        String build
        Int n_indiv
    }

    String pfile = basename(pgen["pgen"], ".pgen")

    command <<<
        ln -s ~{pgen["pgen"]} ~{pfile}.pgen
        ln -s ~{pgen["psam"]} ~{pfile}.psam
        ln -s ~{pgen["pvar"]} ~{pfile}.pvar
        admix hapgen2 \
            --pfile ~{pfile} \
            --n-indiv ~{n_indiv} \
            --out ~{pfile}_hapgen2 \
            --build ~{build} \
            --chrom ~{chrom}
    >>>

    output {
        File out_pgen = "~{pfile}_hapgen2.pgen"
        File out_psam = "~{pfile}_hapgen2.psam"
        File out_pvar = "~{pfile}_hapgen2.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "4GB"
    }
}


task admix_simu {
    input {
        Array[File] pgen
        Array[File] psam
        Array[File] pvar
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    command <<<
        admix admix-simu \
            --pfile-list "['~{sep="','" pgen}']" \
            --admix-prop "[~{sep=',' admix_prop}]" \
            --n-indiv ~{n_indiv} \
            --n-gen ~{n_gen} \
            --build ~{build} \
            --out admix
    >>>

    output {
        Map[String, File] out_pgen = {
            "pgen": "admix.pgen", 
            "psam": "admix.psam", 
            "pvar": "admix.pvar"
        }
        File out_lanc = "admix.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "16GB"
    }
}


task sim_data_model {
    input {
        Array[Map[String, String]] pgen
        File psam
        Array[String] lanc
        Array[String] chrom
        Array[String] pop
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
        Int run_id = 1
        String source_data
    }

    command <<<
        Rscript -e "\
        library(dplyr); \
        parse_array <- function(x) unlist(strsplit(x, split=' ', fixed=TRUE)); \
        pop <- parse_array('~{sep=' ' pop}'); \
        prop <- parse_array('~{sep=' ' admix_prop}'); \
        set <- paste0(paste(paste0(pop, prop), collapse='_'), '_N~{n_indiv}', '_GEN~{n_gen}', '_RUN~{run_id}'); \
        dat <- tibble(field='sample_set_id', value=set); \
        param <- paste0(paste(paste0(pop, prop), collapse='_'), ', ~{n_indiv} individuals, ~{n_gen} generations'); \
        dat <- bind_rows(dat, tibble(field='simulation_parameters', value=param)); \
        ref <- c('hg19'='GRCh37', 'hg38'='GRCh38')['~{build}']; \
        dat <- bind_rows(dat, tibble(field='reference_assembly', value=ref)); \
        dat <- bind_rows(dat, tibble(field='source_data', value='~{source_data}')); \
        dat <- bind_rows(dat, tibble(field='simulation_software', value='admix-kit')); \
        readr::write_tsv(dat, 'simulation_dataset_table.tsv'); \
        psam <- readr::read_tsv('~{psam}', col_names=c('subject_id', 'reported_sex'), skip=1); \
        subj <- mutate(subj, subject_id=paste(set, subject_id, sep='_')); \
        subj <- mutate(psam, consent_code='NRES', study_nickname=set); \
        readr::write_tsv(subj, 'subject_table.tsv'); \
        samp <- mutate(subj[,1], sample_id=subject_id, tissue_source=NA); \
        readr::write_tsv(samp, 'sample_table.tsv'); \
        sample_set <- mutate(select(samp, sample_id), sample_set_id=set); \
        readr::write_tsv(sample_set, 'sample_set_table.tsv'); \
        "
        Rscript -e "\
        library(dplyr); \
        parse_array <- function(x) unlist(strsplit(x, split=' ', fixed=TRUE)); \
        chromosome <- parse_array('~{sep=' ' chrom}'); \
        dat <- jsonlite::fromJSON('~{write_json(pgen)}'); \
        dat <- mutate(dat, chromosome=chromosome); \
        dat <- tidyr::pivot_longer(dat, -chromosome, names_to='file_type', values_to='file_path'); \
        psam <- filter(dat, file_type == 'psam'); \
        psam <- select(psam, file_type, file_path); \
        psam <- distinct(psam, file_type, .keep_all=TRUE); \
        dat <- filter(dat, file_type != 'psam'); \
        dat <- bind_rows(dat, psam); \
        dat <- mutate(dat, file_type=paste('PLINK2', file_type)); \
        dat_lanc <- tibble(file_path=parse_array('~{sep=' ' lanc}'), file_type='local ancestry', chromosome=chromosome); \
        dat <- bind_rows(dat, dat_lanc); \
        writeLines(dat[['file_path']], 'files.txt'); \
        readr::write_tsv(dat, 'simulation_file_table.tsv'); \
        "
        while read f; do
            echo $f
            gsutil ls -L $f | grep "md5" | awk '{print $3}' > md5_b64.txt
            echo "b64 checksum: "; cat md5_b64.txt
            python3 -c "import base64; import binascii; print(binascii.hexlify(base64.urlsafe_b64decode(open('md5_b64.txt').read())))" | cut -d "'" -f 2 >> md5_hex.txt
            echo "hex checksum: "; cat md5_hex.txt
        done < files.txt
        Rscript -e "\
        dat <- readr::read_tsv('simulation_file_table.tsv'); \
        md5_hex <- readLines('md5_hex.txt'); \
        dat <- dplyr::mutate(dat, md5sum=md5_hex); \
        readr::write_tsv(dat, 'simulation_file_table.tsv'); \
        "
    >>>

    output {
        Map[String, File] table_files = {
            "subject": "subject_table.tsv",
            "sample": "sample_table.tsv",
            "sample_set": "sample_set_table.tsv",
            "simulation_dataset": "simulation_dataset_table.tsv",
            "simulation_file": "simulation_file_table.tsv"
        }
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
