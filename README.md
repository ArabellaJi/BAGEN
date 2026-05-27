# BAGEN

BAGEN is the codebase for experiments around progressive budget estimation in
long-horizon foundation-model agents.

BAGEN studies whether an agent can estimate, during execution, how
much remaining budget is needed to finish a task and when the task has become
infeasible. It builds on RAGEN/verl and adds budget-aware rollout logging,
offline replay environments, evaluation scripts, and SFT/RL training utilities.

The Python package directory is still named `ragen` because BAGEN is implemented
as an extension of the RAGEN framework. Keeping the import path stable avoids
breaking Hydra configs, wrappers, and existing training code.

## Paper Scope

The manuscript used as the release reference is:

> Towards Budget-Aware Agents: Do Agents Know What They Will Spend?

The public-facing code in this repository is organized around the paper's four
main settings:

- Sokoban token-budget estimation
- Search-R1 token-budget estimation
- SWE-bench-style coding token-budget estimation
- Warehouse multi-resource budget estimation

The repository also contains legacy RAGEN components because BAGEN
experiments are implemented as extensions to that framework. Legacy RAGEN
experiments such as rollout filtering, gradient diagnostics, and old RAGEN paper
assets are not part of the budget-awareness paper's main experimental claim.

## Repository Map

| Path | Purpose |
| --- | --- |
| `config/base.yaml`, `config/evaluate_api_llm.yaml` | Budget-control flags under `agent_proxy`, including estimation, compliance, and mixed-budget training modes. |
| `ragen/wrapper/ctx_manager_wrapper.py`, `ragen/llm_agent/ctx_manager.py` | Prompt injection and dialogue logging for budget-aware rollouts. |
| `ragen/wrapper/es_manager_wrapper.py`, `ragen/llm_agent/es_manager.py` | Budget sampling and reward shaping for turn, token, and tool-call budgets. |
| `ragen/env/token_estimation` | Offline token-budget estimation environment for Sokoban, Search-R1, SWE-bench-style dialogue logs, and similar rollouts. |
| `ragen/env/money_estimation` | Offline warehouse-budget estimation environment for time, warehouse item-weeks, and cumulative cost. |
| `scripts/evaluation-scripts/origin` | First-pass scripts for collecting task rollouts and dialogue JSON logs. |
| `scripts/evaluation-scripts/eval` | Second-pass budget-estimation scripts that call API models on saved rollouts. |
| `scripts/budget-estimation-benchmark` | Python entry points for token and money estimation replay. |
| `scripts/budget-rl` | SFT and GRPO utilities for training budget-estimation models. |
| `figure/bagen` | Analysis scripts and generated figures for budget-estimation results. |

Large rollout logs, API outputs, local search indices, model checkpoints,
Weights & Biases runs, and manuscript PDFs are intentionally ignored by Git.

## Setup

Clone with submodules:

```bash
git clone --recurse-submodules <repo-url>
cd BAGEN
conda create -n ragenv2 python=3.12 -y
conda activate ragenv2
bash scripts/setup_bagen.sh
export PYTHONPATH="$PWD:$PWD/verl"
```

For Search-R1 retrieval experiments, download/build the search index separately:

```bash
python scripts/download_search_index.py
```

## API Keys

API-based evaluation uses the provider selected by `MODEL_NAME`. Export only the
key required for the model you run:

```bash
export OPENAI_API_KEY=...
export ANTHROPIC_API_KEY=...
export OPENROUTER_API_KEY=...
export GEMINI_API_KEY=...
export TOGETHER_API_KEY=...
export DEEPSEEK_API_KEY=...
```

Set `DRY_RUN=1` on eval scripts to build prompts and validate inputs without
calling an API.

## Collect Original Rollouts

The `origin` scripts run a task model and write both rollout pickle files and
dialogue logs. The dialogue JSON is the input to the offline estimation replay.

Sokoban:

```bash
MODEL_NAME=OpenAI-5.2-Instant \
VAL_GROUPS=128 \
OUTPUT_DIR="$PWD/results/estimation/sokoban-origin-gpt5.2-instant-128-main" \
bash scripts/evaluation-scripts/origin/sokoban.sh
```

Search-R1 requires a retrieval server unless `SEARCH_MOCK_MODE=True`:

```bash
bash scripts/evaluation-scripts/origin/searchr1_server.sh start

MODEL_NAME=OpenRouter-Gemini-3.1-Pro-Preview \
SEARCH_MOCK_MODE=False \
bash scripts/evaluation-scripts/origin/searchr1.sh
```

Use `status`, `logs`, or `stop` with `searchr1_server.sh` to inspect or manage
the server.

## Run Offline Budget Estimation

The second-pass scripts replay saved prefixes and ask a model to output either a
remaining-budget interval or `impossible`.

Sokoban:

```bash
INPUT_JSON="$PWD/results/estimation/sokoban-origin-gpt5.2-instant-128-main/sokoban_api_eval_estimation_eval_estimation_dialogues.json" \
MODEL_NAME=qwen/qwen3-235b-a22b-2507 \
MAX_CONTEXT_WINDOW_TOKENS=2500 \
bash scripts/evaluation-scripts/eval/sokoban.sh
```

Search-R1:

```bash
INPUT_JSON="$PWD/results/estimation/searchr1-origin-gpt5.2-instant-128-main/search_r1_api_eval_estimation_eval_estimation_dialogues.json" \
MODEL_NAME=qwen/qwen3-235b-a22b-2507 \
MAX_CONTEXT_WINDOW_TOKENS=3500 \
bash scripts/evaluation-scripts/eval/searchr1.sh
```

SWE-bench-style coding:

```bash
INPUT_SOURCE=/path/to/swebench-origin-rollouts \
MODEL_NAME=Claude-Opus-4.7-low-thinking \
bash scripts/evaluation-scripts/eval/swebench.sh
```

Warehouse:

```bash
INPUT_SOURCE=/path/to/warehouse_rollouts.json \
MODEL_NAME=qwen/qwen3-235b-a22b-2507 \
BUDGET_PRESET=half-reachable \
bash scripts/evaluation-scripts/eval/warehouse.sh
```

All eval scripts write:

- `OUTPUT_JSON`: predictions, ground truth, API usage, and aggregate metrics
- `TEMP_JSON`: prompt/target pairs for inspection

Smoke-test an eval path without API calls:

```bash
DRY_RUN=1 MAX_SAMPLES=5 INPUT_JSON=/path/to/dialogues.json \
bash scripts/evaluation-scripts/eval/sokoban.sh
```

## Budget-RL Training

The SFT/GRPO pipeline for training a budget estimator is under
`scripts/budget-rl`.

```bash
DRY_RUN=1 bash scripts/budget-rl/run_budget_rl_pipeline.sh prepare,sft,rl
```

Then remove `DRY_RUN=1` and set the model, data, GPU, and checkpoint variables
for a real run:

```bash
TASK=sokoban \
ROLLOUT_MODEL=Qwen/Qwen3-8B \
LEARNER_MODEL=Qwen/Qwen2.5-7B-Instruct \
NUM_TRAJECTORIES=128 \
NGPUS=8 \
bash scripts/budget-rl/run_budget_rl_pipeline.sh all
```

## Public Release Notes

Do not commit local experiment outputs or private manuscript drafts. The release
expects these to stay outside Git:

- `results/`, `logs/`, `wandb/`, `outputs/`, `model_saving/`
- `data/`, `search_data/`, downloaded search indices, and raw warehouse data
- local PDFs such as `Budget_NeurIPS_2026*.pdf`
- API keys, `.env` files, and machine-specific absolute paths

The Warehouse data used by the paper should be released only in anonymized form.
Do not add raw enterprise records to this repository.

## License

This project follows the repository license in `LICENSE`. It includes external
submodules with their own licenses and citation requirements.
