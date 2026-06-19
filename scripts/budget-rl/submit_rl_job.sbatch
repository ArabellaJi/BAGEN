#!/bin/bash
# SLURM batch job for BAGEN budget-RL training (single H100).
#
# Usage:
#   mkdir -p /projects/p33224/bagen_experiments/logs
#   sbatch scripts/budget-rl/submit_rl_job.sbatch
#
# Override defaults at submit time, e.g.:
#   sbatch --export=ALL,STAGES=sft,rl,LEARNER_MODEL=Qwen/Qwen2.5-3B \
#          scripts/budget-rl/submit_rl_job.sbatch
#
#SBATCH --job-name=bagen_rl
#SBATCH --account=p33224
#SBATCH --partition=gengpu
#SBATCH --gres=gpu:h100:1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/p33224/bagen_experiments/logs/%x_%j.out
#SBATCH --error=/projects/p33224/bagen_experiments/logs/%x_%j.err

# NOTE: if "--gres=gpu:h100:1" is rejected on your cluster, try one of:
#   #SBATCH --gres=gpu:1
#   #SBATCH --gres=gpu:1
#   #SBATCH --constraint=h100

set -uo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/home/eiu4164/projects/BAGEN}"
cd "$PROJECT_ROOT"

echo "=== Job info ==="
echo "  job id   : ${SLURM_JOB_ID:-N/A}"
echo "  node     : $(hostname)"
echo "  started  : $(date)"
nvidia-smi || true
echo "================"

# --- Make conda available (the pipeline scripts activate 'bagen' themselves) ---
export PROJ_LIB="${PROJ_LIB:-}"
export PROJ_DATA="${PROJ_DATA:-}"
if [ -f /software/miniconda3/4.10.3/etc/profile.d/conda.sh ]; then
  # shellcheck disable=SC1091
  source /software/miniconda3/4.10.3/etc/profile.d/conda.sh
fi

# --- Runtime environment (matches the working interactive-node config) ---
export WANDB_DISABLED=true
export TRANSFORMERS_ATTENTION_IMPLEMENTATION=eager
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:False

# --- Experiment configuration (override via --export=ALL,VAR=...) ---
export EXP_BASE="${EXP_BASE:-/projects/p33224/bagen_experiments/sokoban_Qwen-Qwen3-8B_to_Qwen-Qwen2-5-3B}"
export LEARNER_MODEL="${LEARNER_MODEL:-Qwen/Qwen2.5-3B}"
export NGPUS="${NGPUS:-1}"
export RL_PPO_MICRO_BS="${RL_PPO_MICRO_BS:-1}"
export RL_LOGPROB_MICRO_BS="${RL_LOGPROB_MICRO_BS:-1}"
export STAGES="${STAGES:-rl}"

echo "=== Launching pipeline: STAGES=${STAGES} LEARNER_MODEL=${LEARNER_MODEL} ==="
bash scripts/budget-rl/run_budget_rl_pipeline.sh

echo "=== Job finished: $(date) ==="
