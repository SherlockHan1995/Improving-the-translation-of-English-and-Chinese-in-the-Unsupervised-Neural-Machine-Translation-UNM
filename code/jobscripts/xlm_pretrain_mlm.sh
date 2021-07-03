#!/bin/bash

# The following script will pretrain a model with the MLM objective for English and Chinese

#SBATCH --time=24:00:00
#SBATCH --job-name=xlm_pretrain_mlm
#SBATCH --output=logs/job-%j.log
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32000

module purge
module load Python/3.8.6-GCCcore-10.2.0

source /data/s4238346/.envs/xlm_venv/bin/activate

python /data/s4238346/XLM/train.py --exp_name en_zh_translation --dump_path /data/s4238346/dumped --data_path /data/s4238346/wmt/processed/en-zh --lgs 'en-zh' --clm_steps '' --mlm_steps 'en,zh' --emb_dim 512 --n_layers 6 --n_heads 8 --dropout 0.1 --attention_dropout 0.1 --gelu_activation True --batch_size 128 --bptt 256 --optimizer adam,lr=0.0001 --epoch_size 200000 --max_epoch 300 --validation_metrics _valid_mlm_ppl --stopping_criterion _valid_mlm_ppl,10

deactivate

