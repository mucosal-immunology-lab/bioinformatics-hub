# Data Best Practices

This page provides a guide to data storage best practices within the Mucosal Immunology Lab, focusing on the efficient and organised management of sequencing and LC-MS data. Additionally, we emphasise the importance of maintaining a centralised record by listing datasets in a communal spreadsheet.

We will cover the proper use of Monash Vault for long-term storage, including step-by-step instructions for converting, transferring, and retrieving raw sequencing data. To ensure data integrity and quality, this page details processes such as SHA-256 sum checks and quality control using TrimGalore and FastQC. 

## Data storage and location

All raw sequencing and LCMS data must meet the following requirements to ensure ongoing access to the data in the future.

### 1) Store raw data on the Vault 🏦

All data must be stored on the Monash Vault with minimal metadata (sample names, groups, library preparation kits, indexes etc.)

```bash title="Marsland Lab sequencing archive Vault location"
MONASH\\<short-monash-id>@vault-v2.erc.monash.edu:Marsland-CCS-RAW-Sequencing-Archive/vault/
```

!!! note "Vault access 🔐"

    Users need to make sure they have requested and been granted Vault access first &ndash; Monash credentials alone are not sufficient.

    - The `<short-monash-id>` refers to the short version of your username, rather than the full name as per your email address.

#### Convert raw sequencing data 🔄

The majority of the time, your data will have been converted to FASTQ format via BaseSpace immediately following sequencing.
However, if your raw sequencing data is still in `BCL` format, follow the guide for [converting raw NovaSeq outputs](./convert-raw-novaseq-outputs.md).

#### Transfer your data to the Vault ⬆️📂

Transferring data is a simple process that involves using `rsync`, which is already installed on the M3 MASSIVE cluster &ndash; see the guide on [Vault storage](./vault-storage.md). Simply swap out the following values:

- `local-folder-path`: the path to the local (or M3 MASSIVE cluster) folder.
- `short-monash-id`: your Monash ID.
- `sharename`: the name of the Vault share folder you want to copy to, i.e. `Marsland-CCS-RAW-Sequencing-Archive`.
- `path`: the path to the Vault folder.

```bash
rsync -aHWv --stats --progress --no-p --no-g --chmod=ugo=rwX /<local-folder-path>/ MONASH\\<short-monash-id>@vault-v2.erc.monash.edu:<sharename>/vault/<path>
```

#### Transfer your data from Vault ⬇️📂

The same process works in reverse to retrieve data from the Vault.

```bash
rsync -aHWv --stats --progress --no-p --no-g --chmod=ugo=rwX MONASH\\<short-monash-id>@vault-v2.erc.monash.edu:<sharename>/vault/<path> /<local-folder-path>/
```

### 2) List your dataset in the communal spreadsheet 📋

The dataset must be listed in the communal Google Drive [Sequencing Data](https://docs.google.com/spreadsheets/d/1bKI-RgzfuWd-3C4_xZPCM-YlK7k0Fzn5/edit?usp=sharing&ouid=105349381251392029405&rtpof=true&sd=true) spreadsheet.

### 3) Check dataset integrity and quality ✅💾

We can verify the integrity of files we transfer up to the Vault using SHA-256 checksums. By generating a checksum for each file before transfer and comparing it with the checksum of the received file, we can confirm that no data corruption or tampering occurred during the process. This method ensures the security and reliability of critical file exchanges, providing confidence that the uploaded data remains identical to the original. Implementing checksum verification as a routine step can be particularly valuable for sensitive or large-scale data transfers.

#### Generating SHA-256 checksum files 🛠️🔐

The bash script [`generate_checksums.sh`](../assets/Utilities/seq_data/generate_checksums.sh) automates that creation of SHA-256 checksums for all files in each directory within a specified base folder. It will generate one `SHA256SUMS` files per directory which contains the names and checksums of all regular files in that directory. These will then be uploaded to the Vault along with your data, and can be verified when the data is downloaded again.

```bash title="Generate SHA-256 checksum files"
# Run script with 8 parallel processes
bash generate_checksums.sh <path-to-folder> -j 8
```

??? question "What does the script do?"

    **Workflow:**

    1. It removes any existing `SHA256SUMS` files in each directory to prevents duplication or conflicts.
    2. It generates SHA-256 checksums for all regular files in the directory (excluding `SHA256SUMS`) and sorts the output for consistency.
    3. The checksums are saved in a new `SHA256SUMS` file in each respective folder.

    **Parallelisation:** it utilises GNU Parallel for faster execution, allowing checksum generation across multiple directories at the same time.

    **Usage:**

    - The default behaviour is to process the current directory (and its subdirectories).
    - Accepts a base directory and additional GNU Parallel options (e.g. specifying the number of parallel jobs using `-j`).

    !!! warning "Ensure GNU Parallel is installed"

        Make sure you have installed GNU Parallel on your system. The script will exit and warn you if it's not installed in any case.

#### Verifying SHA-256 checksum files 🔍🔑

The bash script [`verify_checksums.sh`](../assets/Utilities/seq_data/verify_checksums.sh) ensures the integrity of files by validating SHA-256 checksums against pre-existing `SHA256SUMS` files within directory and subfolders. This process is particularly useful for making sure that large files have not become corrupted during data transfer.

```bash title="Verify SHA-256 checksum files"
# Verify checksums with 8 parallel processes
bash verify_checksums.sh <path-to-folder> -j 8
```

??? question "What does the script do?"

    **Workflow:**

    1. Identifies all directories that contain a `SHA256SUMS` file.
    2. Recomputes SHA-256 checksums for all regular files in the directory (excluding the `SHA256SUMS` file itself).
    3. Sorts and compares the recomputed checksums with those in the reference `SHA256SUMS` file.
    4. Reports whether the verification succeeded or failed for each directory, highlighting any discrepancies.

    **Parallelisation:** it utilises GNU Parallel for faster execution, allowing checksum generation across multiple directories at the same time.

    **Usage:**

    - The default behaviour is to process the current directory (and its subdirectories).
    - Accepts a base directory and additional GNU Parallel options (e.g. specifying the number of parallel jobs using `-j`).

    **Error handling:**

    - Exits with an error if `SHA256SUMS` is missing or if checksum verification fails in any directory.
    - Provides detailed output for failed comparisons to help with debugging.

    !!! warning "Ensure GNU Parallel is installed"

        Make sure you have installed GNU Parallel on your system. The script will exit and warn you if it's not installed in any case.