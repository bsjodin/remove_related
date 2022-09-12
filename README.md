
# remove_related

### Description and Installation
This script identifies and related individuals in a dataset and generates a remove list based on the Ritland estimator calculated using the [coancestry](https://rdrr.io/rforge/related/man/coancestry.html) function of the [related](https://rdrr.io/rforge/related/man/related-package.html) R-package.

This script first removes replicate samples (if present), then detects related pairs of individuals based on your specified threshold. It then iteratively removes one individual from each pair based either of frequency of interactions of proportion of missing genotypes until no related pairs remain, removing the fewest individuals as necessary. This script only compares individuals from within a population.

To install this script, use the following command:

```$ git clone https://github.com/bsjodin/remove_related```

You may need to change permissions, which can be done running the following:

```$ chmod 755 remove_related.sh```

### Usage and Options
**Usage**\
`$ ./remove_related.sh [threshold] [freq/miss] [no_reps #OPTIONAL]`

**Options**
| Argument | Description |
| --- | --- |
| threshold [int] | **Required**; relatedness threshold for highly-related individuals (*e.g.*, 0.5 to remove first order relatives) |
| freq/miss | **Required**; remove individuals based on their frequency of interactions (`freq`) or by proporition of missing genotypes (`miss`). `freq` will remove those individuals that are related to many others (*e.g.*, an individual related to 5 others will be removed over one that is related to only 3), while `miss` will remove those individuals with the highest missing data first |
| no_reps | **Optional**; disable removal of replicate samples prior to detection of related individuals. Use this option if your dataset does not contain replicate samples |

### Required Files
There following files are required:

1) Relatedness estimates from **coancestry** saved as `RelatednessEstimates.Txt` (default output from **coancestry**). These must include the Ritland estimator. To use other estimators, you must edit the `awk` command on line 27 to the appropriate column (*i.e*, change $9 to the appropriate column number).
2) A file with percent missingness per individual named `missing.txt`. This file should have one sample per line and follow the format of "IND MISSINGNESS". See [missing.txt](missing.txt) for an example file.
3) A file contain which replicate IDs to remove, one ID per line, saved as `bad_reps.txt`. This file is not needed if `no_reps` is specified.

### Outputs
This script generates three output files:

1) `remove.txt`      : A list of related individuals to remove for downstream analyses.
2) `related_ind.txt` : A list of related pairs based on your specified threshold.
3) `unique_ind.txt`  : A list of unique individuals across all related pairs.
