#!/bin/bash

#SBATCH --time=12:00:00
#SBATCH --job-name=train_unsupMT
#SBATCH --output=logs/job-%j.log
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32000

module purge
module load Python/3.8.6-GCCcore-10.2.0

source /data/s4238346/.envs/xlm_venv/bin/activate

python /data/s4238346/XLM/train.py --exp_name unsupMT_enzh --dump_path /data/s4238346/dumped \
	--reload_model '/data/s4238346/dumped/en_zh_translation/20386338/best-valid_mlm_ppl.pth,/data/s4238346/dumped/en_zh_translation/20386338/best-valid_mlm_ppl.pth' \
	--data_path /data/s4238346/wmt/processed/en-zh --lgs 'en-zh' --ae_steps 'en,zh' --bt_steps 'en-zh-en,zh-en-zh' --word_shuffle 3 --word_dropout 0.1 --word_blank 0.1 \
	--lambda_ae '0:1,100000:0.1,300000:0' --encoder_only false --emb_dim 512 --n_layers 6 --n_heads 8 --dropout 0.1 --attention_dropout 0.1 --gelu_activation true --tokens_per_batch 2000 \
	--batch_size 128 --bptt 256 --optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 --epoch_size 200000 --max_epoch 100 --eval_bleu true --stopping_criterion 'valid_en-zh_mt_bleu,10' \
	--validation_metrics 'valid_en-zh_mt_bleu'

deactivate

