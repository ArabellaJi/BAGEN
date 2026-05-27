# BAGEN Setup

## Release Environment Setup

Use the setup flow below for the validated BAGEN environment.

This setup has been validated on `H100`, `H200`, and `B200`, and supports:
- `bandit`
- `sokoban`
- `frozenlake`
- `metamathqa`
- `countdown`
- `deepcoder`

## Requirements

- `CUDA >= 12.8`

### 1. Clone the repository

```bash
git clone --recurse-submodules <repo-url>
cd BAGEN
```

### 2. Create and activate the conda environment

```bash
conda create -n bagen python=3.12 -y
conda activate bagen
```

### 3. Run the environment setup script

```bash
bash scripts/setup_bagen.sh
```

If you want to install the `search` environment, use the following command:

```bash
bash scripts/setup_bagen.sh --with-search
```

This release setup does not install `webshop`. If you need `webshop`, use its
separate setup flow instead of `setup_bagen.sh`.
