# admix-kit_workflow

Workflow to implement
[admix-kit](https://kangchenghou.github.io/admix-kit/) on AnVIL.

The workflows are written in the Workflow Description Language ([WDL](https://docs.dockstore.org/en/stable/getting-started/getting-started-with-wdl.html)). This GitHub repository contains the Dockerfile, the WDL code, and a JSON file containing inputs to the workflow, both for testing and to serve as an example.

The Dockerfile creates a docker image containing the admix-kit software and all dependencies. It is available on Docker Hub as
[uwgac/admix-kit](https://hub.docker.com/r/uwgac/admix-kit).

We provide three workflows:
- [sim_admixed](#sim_admixed): Simulate admixed individuals from a set of reference data. This workflow contains both steps of [run_hapgen](#run_hapgen) and [run_admix](#run_admix).
- [run_hapgen](#run_hapgen): Run HAPGEN2 to extend a set of reference population starting from one set of pgen files.
- [run_admix](#run_admix): Run admix_simu to simulate admixed individuals from a set of reference populations.

## sim_admixed

This workflow uses HAPGEN2 to simulate ancestral populations from reference data, and then simulates `n_gen` generations of admixture from the simulated ancestral populations.

The final step in the workflow is to generate data tables in the PRIMED data model as .tsv files. If import_tables is true, these tsv files will be imported to data tables in the workspace.

The user must specify the following inputs:

input | description
--- | ---
pgen | Input genotype files for the simulation. These must be provided in a nested array structure with the innermost layer being a set of pgen/psam/pvar files, the middle layer being an array of populations, and the outermost layer an array of chromosomes. This is best illustrated with [an example](https://github.com/UW-GAC/admix-kit_workflow/blob/main/sim_admixed.json).
admix_prop | Admixture proportions for each population in `pgen`
build | Genome build. "hg19" or "hg38"
n_indiv | Number of individuals to simulate
n_gen | Number of generations to simulate
import_tables | A boolean indicating whether data model tables should be imported to the workspace.
overwrite | A boolean indicating whether existing rows in the workspace data tables should be overwritten.
workspace_name | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace name is "Terra-Workflows-Quickstart"
workspace_namespace | A string with the workspace name. e.g, if the workspace URL is https://anvil.terra.bio/#workspaces/fc-product-demo/Terra-Workflows-Quickstart, the workspace namespace is "fc-product-demo"

The workflow returns the following outputs:

output | description
--- | ---
out_pgen | Output pgen files with admixed genotypes. This is an array of pgen/psam/pvar file sets for each chromosome.
out_lanc | Output local ancestry file for simulated individuals.


## run_hapgen

This workflow runs HAPGEN2 alone on a single set of pgen files.

The user must specify the following inputs:

input | description
--- | ---
pgen | Input genotype files for the simulation. These must be provided as a set of pgen/psam/pvar files. This is best illustrated with [an example](https://github.com/UW-GAC/admix-kit_workflow/blob/main/run_hapgen.json).
build | Genome build. "hg19" or "hg38"
n_indiv | Number of individuals to simulate

The workflow returns the following outputs:

output | description
--- | ---
out_pgen | Output pgen file with simulated genotypes
out_psam | Output psam file with simulated genotypes
out_pvar | Output pvar file with simulated genotypes


## run_admix

This workflow runs admix_simu alone on an array of pgen files for multiple populations. Unlike the inputs for sim_admixed and run_hapgen, the pgen/psam/pvar files must be provided as separate arrays. Here is [an example](https://github.com/UW-GAC/admix-kit_workflow/blob/main/run_admix.json).

The user must specify the following inputs:

input | description
--- | ---
pgen | Array of pgen files, one per population
psam | Array of psam files, one per population
pvar | Array of pvar files, one per population
admix_prop | Admixture proportions for each population in `pgen`
build | Genome build. "hg19" or "hg38"
n_indiv | Number of individuals to simulate
n_gen | Number of generations to simulate

The workflow returns the following outputs:

output | description
--- | ---
out_pgen | Output pgen files with admixed genotypes. This is an array of pgen/psam/pvar file sets for each chromosome.
out_lanc | Output local ancestry file for simulated individuals.

# Analysis notebook
We used this workflow to simulate African-European admixed individuals, using a demographic model similar to African American individuals with over 8 generations of admixture and an average proportion of 80% African and 20% European (ancestry proportion varies by individual). See an example analysis notebook of simulated data [here](https://nbviewer.org/github/UW-GAC/admix-kit_workflow/tree/main/notebooks/analysis.ipynb).