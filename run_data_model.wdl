
version 1.0

workflow run_data_model {
    input {
        Array[Map[String, String]] pgen
        Array[String]? lanc
    }

    call sim_data_model {
        input: pgen = pgen,
               lanc = lanc
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
    }

    command <<<
        #Rscript -e "\
        #pgen_files <- readr::read_tsv(~write_map(flatten(pgen))); \
        #readr::write_tsv(pgen_files, 'files.tsv'); \
        #"
    >>>

    output {
        File file_table = write_map(flatten(pgen))
    }

    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.16.0"
    }
}
