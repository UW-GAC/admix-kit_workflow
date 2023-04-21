
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
        #print(dat); \
        dat <- dplyr::mutate(dat, chromosome=unlist(strsplit('~{sep=' ' chrom}', split=' ', fixed=TRUE))); \
        #print(dat); \
        dat <- tidyr::pivot_longer(dat, -chromosome, names_to='file_type', values_to='file_path'); \
        #print(dat); \
        dat <- dplyr::mutate(dat, file_type=paste('PLINK2', file_type)); \
        #print(dat); \
        writeLines(dat[['file_path']], 'files.txt');\
        readr::write_tsv(dat, 'simulation_file_table.tsv'); \
        #"
        cat files.txt
        while read f; do
            echo $f
            gsutil ls -L $f | grep "md5" | awk '{print $3}' > md5_b64.txt
            echo "b64 checksum: "; cat md5_b64.txt
            python3 -c "import base64; import binascii; print(binascii.hexlify(base64.urlsafe_b64decode(open('md5_b64.txt').read())))" | cut -d "'" -f 2 >> md5_hex.txt
            echo "hex checksum: "; cat md5_hex.txt
        done < files.txt
        Rscript -e "\
        dat <- readr::read_tsv(simulation_file_table.tsv'); \
        md5_hex <- readLines('md5_hex.txt'); \
        dat <- dplyr::mutate(dat, md5sum=md5_hex); \
        print(dat); \
        readr::write_tsv(dat, 'simulation_file_table.tsv'); \
        #"
    >>>

    output {
        File file_table = "simulation_file_table.tsv"
        File files = "files.txt"
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
