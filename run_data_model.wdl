
version 1.0

workflow run_data_model {
    input {
        Array[Map[String, File]] pgen
        Array[String] lanc
        Array[String] chrom
        Array[String] pop
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
        String source_data = "1000 Genomes"
    }

    call sim_data_model {
        input: pgen = pgen,
               psam = pgen[1]["psam"],
               lanc = lanc,
               chrom = chrom,
               pop = pop,
               admix_prop = admix_prop,
               build = build,
               n_indiv = n_indiv,
               n_gen = n_gen,
               source_data = source_data
    }
    
    output {
        Map[String, File] table_files = sim_data_model.table_files
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"

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
        String source_data
    }

    command <<<
        Rscript -e "\
        library(dplyr); \
        parse_array <- function(x) unlist(strsplit(x, split=' ', fixed=TRUE)); \
        pop <- parse_array('~{sep=' ' pop}'); \
        prop <- parse_array('~{sep=' ' admix_prop}'); \
        set <- paste0(paste(paste0(pop, prop), collapse='_'), '_N~{n_indiv}', '_GEN~{n_gen}'); \
        dat <- tibble(field='sample_set_id', value=set); \
        param <- paste0(paste(paste0(pop, prop), collapse='_'), ', ~{n_indiv} individuals, ~{n_gen} generations'); \
        dat <- bind_rows(dat, tibble(field='simulation_parameters', value=param)); \
        ref <- c('hg19'='GRCh37', 'hg38'='GRCh38')['~{build}']; \
        dat <- bind_rows(dat, tibble(field='reference_assembly', value=ref)); \
        dat <- bind_rows(dat, tibble(field='source_data', value='~{source_data}')); \
        dat <- bind_rows(dat, tibble(field='simulation_software', value='admix-kit')); \
        readr::write_tsv(dat, 'simulation_dataset_table.tsv'); \
        psam <- readr::read_tsv('~{psam}', col_names=c('subject_id', 'reported_sex'), skip=1)
        subj <- mutate(psam, consent_code='NRES', study_nickname=set); \
        readr::write_tsv(subj, 'subject_table.tsv'); \
        samp <- mutate(psam[,1], sample_id=subject_id, tissue_source=NA); \
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
        dat <- mutate(file_type=paste('PLINK2', file_type)); \
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
