#!/bin/bash

#SBATCH --time=00:20:00
#SBATCH --job-name=xlm_translate
#SBATCH --output=logs/job-%j.log
#SBATCH --partition=gpushort
#SBATCH --gres=gpu:v100:1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=16000

module purge
module load Python/3.8.6-GCCcore-10.2.0

source /data/s4238346/.envs/xlm_venv/bin/activate

cat /data/s4238346/wmt/processed/en-zh/test.en-zh.en | python /data/s4238346/XLM/translate.py --exp_name translation_en_to_zh --src_lang en --tgt_lang zh --model_path '/data/s4238346/dumped/unsupMT_enzh/20306574/best-valid_en-zh_mt_bleu.pth' --output_path /data/s4238346/dumped/translation/mtoutput.zh

cat /data/s4238346/wmt/processed/zh-en/test.zh-en.zh | python /data/s4238346/XLM/translate.py --exp_name translation_zh_to_en --src_lang zh --tgt_lang en --model_path '/data/s4238346/dumped/unsupMT_enzh/20306574/best-valid_en-zh_mt_bleu.pth' --output_path /data/s4238346/dumped/translation/mtoutput.en

# detokenize EN data with MOSE
echo "Detokenize EN data..."
$DETOKENIZER -l en < /data/s4238346/dumped/translation/mtoutput.en | tr -d "@" > /data/s4238346/dumped/translation/mtoutput.en.detok


# detokenize ZH data
echo "Detokenize ZH data..."
cat /data/s4238346/dumped/translation/mtoutput.zh | tr -d " @" > /data/s4238346/dumped/translation/mtoutput.zh.detok

#scoring
cat /data/s4238346/dumped/translation/mtoutput.zh.detok | sacrebleu -t wmt19 -l en-zh
cat /data/s4238346/dumped/translation/mtoutput.en.detok | sacrebleu -t wmt19 -l zh-en

deactivate

