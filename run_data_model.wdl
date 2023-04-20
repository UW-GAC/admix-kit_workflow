
version 1.0

workflow run_data_model {
    input {
        Array[Map[String, String]] pgen
        Array[String]? lanc
        Array[String] chrom
        Array[String] pop
    }

    call sim_data_model {
        input: pgen = pgen,
               lanc = lanc,
               chrom = chrom,
               pop = pop
    }
    
    output {
        File file_table = sim_data_model.file_table
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"

    }
}

task sim_data_model {
    input {
        Array[Map[String, String]] pgen
        Array[String]? lanc
        Array[String] chrom
        Array[String] pop
    }

    command <<<
        Rscript -e "\
        dat <- jsonlite::fromJSON('~{write_json(pgen)}'); \
        print(dat); \
        dat$chromosome <- unlist(strsplit('~{sep=' ' chrom}', split=' ', fixed=TRUE)); \
        print(dat); \
        dat <- tidyr::pivot_longer(dat, -chromosome, names_to='file_type', values_to='file_path'); \
        print(dat); \
        dat <- dplyr::mutate(dat, file_type=paste('PLINK2', file_type)); \
        print(dat); \
        md5_b64 <- sapply(dat$file_path, function(x) system(paste('gsutil ls -L', x, '| grep \"md5\" | awk \'{print $3}\''), intern=TRUE), USE.NAMES=FALSE); \
        md5_hex <- sapply(md5_b64, function(x) system(paste('python3 -c \"import base64; import binascii; print(binascii.hexlify(base64.urlsafe_b64decode(\'', x, '\')))\" | cut -d \"\'\" -f 2'), intern=TRUE), USE.NAMES=FALSE); \
        dat$md5sum <- md5_hex; \
        print(dat); \
        readr::write_tsv(dat, 'simulation_file_table.tsv'); \
        #"
    >>>

    output {
        File file_table = "simulation_file_table.tsv"
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
