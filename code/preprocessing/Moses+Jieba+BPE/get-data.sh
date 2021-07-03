
# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e


#
# Data preprocessing configuration
#
N_MONO=1700000  # number of monolingual sentences for each language
CODES=32000     # number of BPE codes

#
# Initialize tools and data paths
#

# main paths
SRC=en
TGT=zh
TOOLS_PATH=tools
DATA_PATH=/data/s4238346/wmt
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para
PROC_PATH=$DATA_PATH/processed/$SRC-$TGT

# create paths
mkdir -p $TOOLS_PATH
mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH
mkdir -p $PROC_PATH

# moses
MOSES_DIR=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES_DIR/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES_DIR/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES_DIR/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES_DIR/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES_DIR/scripts/ems/support/input-from-sgm.perl

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

# raw and tokenized files
SRC_RAW=$MONO_PATH/$SRC/all.$SRC
TGT_RAW=$MONO_PATH/$TGT/all.$TGT
SRC_TOK=$SRC_RAW.tok
TGT_TOK=$TGT_RAW.tok

# BPE / vocab files
BPE_CODES=$PROC_PATH/codes
SRC_VOCAB=$PROC_PATH/vocab.$SRC
TGT_VOCAB=$PROC_PATH/vocab.$TGT
FULL_VOCAB=$PROC_PATH/vocab.$SRC-$TGT

# train / valid / test monolingual BPE data
SRC_TRAIN_BPE=$PROC_PATH/train.$SRC
TGT_TRAIN_BPE=$PROC_PATH/train.$TGT
SRC_VALID_BPE=$PROC_PATH/valid.$SRC
TGT_VALID_BPE=$PROC_PATH/valid.$TGT
SRC_TEST_BPE=$PROC_PATH/test.$SRC
TGT_TEST_BPE=$PROC_PATH/test.$TGT

# valid / test parallel BPE data
PARA_SRC_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$SRC
PARA_TGT_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$TGT
PARA_SRC_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$SRC
PARA_TGT_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$TGT

# valid / test file raw data
unset PARA_SRC_VALID PARA_TGT_VALID PARA_SRC_TEST PARA_TGT_TEST
PARA_SRC_VALID=$PARA_PATH/dev/newsdev2017-$SRC$TGT-src.$SRC
PARA_TGT_VALID=$PARA_PATH/dev/newsdev2017-$SRC$TGT-ref.$TGT
PARA_SRC_TEST=$PARA_PATH/dev/newstest2019-$SRC$TGT-src.$SRC
PARA_TGT_TEST=$PARA_PATH/dev/newstest2019-$SRC$TGT-ref.$TGT

#
# install tools
#
# tools
# install Jieba for ZH tokenization
# https://github.com/fxsjy/jieba
pip install jieba

# install Mose for EN tokenization
echo "Cloning $MOSES_DIR..."
if [ ! -d "$MOSES_DIR" ]; then
  cd $TOOLS_PATH
  echo "Cloning Moses from GitHub repository..."
  git clone https://github.com/moses-smt/mosesdecoder.git
  cd ..
fi

# install BPE for EN-ZH combined
if [ ! -d "$FASTBPE_DIR" ]; then
  echo "Cloning fastBPE from GitHub repository..."
  cd $TOOLS_PATH
  git clone https://github.com/glample/fastBPE
  cd fastBPE
  echo "Compiling fastBPE..."
  g++ -std=c++11 -pthread -O3 fastBPE/main.cc -IfastBPE -o fast
  cd ../..
fi

#
# Download and process training data
#
echo "Downloading English monolingual data ..."
# EN: WMT NewsCrawl 2014-2017
mkdir -p $MONO_PATH/en
wget -c http://data.statmt.org/news-crawl/en/news.2014.en.shuffled.deduped.gz -P $MONO_PATH/en
wget -c http://data.statmt.org/news-crawl/en/news.2015.en.shuffled.deduped.gz -P $MONO_PATH/en
wget -c http://data.statmt.org/news-crawl/en/news.2016.en.shuffled.deduped.gz -P $MONO_PATH/en
wget -c http://data.statmt.org/news-crawl/en/news.2017.en.shuffled.deduped.gz -P $MONO_PATH/en
##
echo "Downloading Chinese monolingual data ..."
# ZH: WMT newscrawl 2008-2018
mkdir -p $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2008.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2010.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2011.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2012.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2013.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2014.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2015.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2016.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2017.zh.shuffled.deduped.gz -P $MONO_PATH/zh
wget -c http://data.statmt.org/news-crawl/zh/news.2018.zh.shuffled.deduped.gz -P $MONO_PATH/zh

# decompress monolingual data
for FILENAME in $MONO_PATH/$SRC/news*gz $MONO_PATH/$TGT/news*gz; do
  OUTPUT="${FILENAME::-3}"
  if [ ! -f "$OUTPUT" ]; then
    echo "Decompressing $FILENAME..."
    gunzip -d $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done

# concatenate monolingual data files
if ! [[ -f "$SRC_RAW" ]]; then
  echo "Concatenating $SRC monolingual data..."
  cat $(ls $MONO_PATH/$SRC/news*$SRC* | grep -v gz) | head -n $N_MONO > $SRC_RAW
fi
if ! [[ -f "$TGT_RAW" ]]; then
  echo "Concatenating $TGT monolingual data..."
  cat $(ls $MONO_PATH/$TGT/news*$TGT* | grep -v gz) | head -n $N_MONO > $TGT_RAW
fi
echo "$SRC monolingual data concatenated in: $SRC_RAW"
echo "$TGT monolingual data concatenated in: $TGT_RAW"

# tokenize training data
echo "Tokenize monolingual data..."
if ! [[ -f "$SRC_TOK" ]]; then
  cat $SRC_RAW | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS > $SRC_TOK
fi
echo "$SRC monolingual data tokenized in: $SRC_TOK"

if ! [[ -f "$TGT_TOK" ]]; then
  python -m jieba $TGT_RAW -d " " > $TGT_TOK
fi
echo "$TGT monolingual data tokenized in: $TGT_TOK"

# extract BPE codes and vocabulary
# learn BPE codes
if [ ! -f "$BPE_CODES" ]; then
  echo "Learning BPE codes..."
  $FASTBPE learnbpe $CODES $SRC_TOK $TGT_TOK > $BPE_CODES
fi
echo "BPE learned in $BPE_CODES"

# apply BPE codes
if ! [[ -f "$SRC_TRAIN_BPE" ]]; then
  echo "Applying $SRC BPE codes..."
  $FASTBPE applybpe $SRC_TRAIN_BPE $SRC_TOK $BPE_CODES
fi
if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
  echo "Applying $TGT BPE codes..."
  $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TOK $BPE_CODES
fi
echo "BPE codes applied to $SRC in: $SRC_TRAIN_BPE"
echo "BPE codes applied to $TGT in: $TGT_TRAIN_BPE"

# extract source and target vocabulary
if ! [[ -f "$SRC_VOCAB" && -f "$TGT_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TRAIN_BPE > $SRC_VOCAB
  $FASTBPE getvocab $TGT_TRAIN_BPE > $TGT_VOCAB
fi
echo "$SRC vocab in: $SRC_VOCAB"
echo "$TGT vocab in: $TGT_VOCAB"

# extract full vocabulary
if ! [[ -f "$FULL_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TRAIN_BPE $TGT_TRAIN_BPE > $FULL_VOCAB
fi
echo "Full vocab in: $FULL_VOCAB"

# binarize data
if ! [[ -f "$SRC_TRAIN_BPE.pth" ]]; then
  echo "Binarizing $SRC data..."
  python preprocess.py $FULL_VOCAB $SRC_TRAIN_BPE
fi
if ! [[ -f "$TGT_TRAIN_BPE.pth" ]]; then
  echo "Binarizing $TGT data..."
  python preprocess.py $FULL_VOCAB $TGT_TRAIN_BPE
fi
echo "$SRC binarized data in: $SRC_TRAIN_BPE.pth"
echo "$TGT binarized data in: $TGT_TRAIN_BPE.pth"


#
# Download and process validation and test data
#
echo "Downloading parallel data (for evaluation only)..."
wget -c http://data.statmt.org/wmt20/translation-task/dev.tgz -P $PARA_PATH
#
echo "Extracting parallel data..."
tar zxvf $PARA_PATH/dev.tgz -C $PARA_PATH

# check if valid and test files are here
if ! [[ -f "$PARA_SRC_VALID.sgm" ]]; then echo "$PARA_SRC_VALID.sgm is not found!"; exit; fi
if ! [[ -f "$PARA_TGT_VALID.sgm" ]]; then echo "$PARA_TGT_VALID.sgm is not found!"; exit; fi
if ! [[ -f "$PARA_SRC_TEST.sgm" ]];  then echo "$PARA_SRC_TEST.sgm is not found!";  exit; fi
if ! [[ -f "$PARA_TGT_TEST.sgm" ]];  then echo "$PARA_TGT_TEST.sgm is not found!";  exit; fi
#
echo "Tokenizing valid and test data..."
$INPUT_FROM_SGM < $PARA_SRC_VALID.sgm | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS > $PARA_SRC_VALID
$INPUT_FROM_SGM < $PARA_TGT_VALID.sgm | python -m jieba -d " " > $PARA_TGT_VALID
$INPUT_FROM_SGM < $PARA_SRC_TEST.sgm | $REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS > $PARA_SRC_TEST
$INPUT_FROM_SGM < $PARA_TGT_TEST.sgm | python -m jieba -d " " > $PARA_TGT_TEST
#
echo "Applying BPE to valid and test files..."
$FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $SRC_VOCAB
$FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $TGT_VOCAB
$FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $SRC_VOCAB
$FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $TGT_VOCAB
#
echo "Binarizing data..."
rm -f $PARA_SRC_VALID_BPE.pth $PARA_TGT_VALID_BPE.pth $PARA_SRC_TEST_BPE.pth $PARA_TGT_TEST_BPE.pth
python preprocess.py $FULL_VOCAB $PARA_SRC_VALID_BPE
python preprocess.py $FULL_VOCAB $PARA_TGT_VALID_BPE
python preprocess.py $FULL_VOCAB $PARA_SRC_TEST_BPE
python preprocess.py $FULL_VOCAB $PARA_TGT_TEST_BPE

#
# Link monolingual validation and test data to parallel data
#
ln -sf $PARA_SRC_VALID_BPE.pth $SRC_VALID_BPE.pth
ln -sf $PARA_TGT_VALID_BPE.pth $TGT_VALID_BPE.pth
ln -sf $PARA_SRC_TEST_BPE.pth $SRC_TEST_BPE.pth
ln -sf $PARA_TGT_TEST_BPE.pth $TGT_TEST_BPE.pth

#
# Summary
#
echo ""
echo "===== Data summary"
echo "Monolingual training data:"
echo "    $SRC: $SRC_TRAIN_BPE.pth"
echo "    $TGT: $TGT_TRAIN_BPE.pth"
echo "Monolingual validation data:"
echo "    $SRC: $SRC_VALID_BPE.pth"
echo "    $TGT: $TGT_VALID_BPE.pth"
echo "Monolingual test data:"
echo "    $SRC: $SRC_TEST_BPE.pth"
echo "    $TGT: $TGT_TEST_BPE.pth"
echo "Parallel validation data:"
echo "    $SRC: $PARA_SRC_VALID_BPE.pth"
echo "    $TGT: $PARA_TGT_VALID_BPE.pth"
echo "Parallel test data:"
echo "    $SRC: $PARA_SRC_TEST_BPE.pth"
echo "    $TGT: $PARA_TGT_TEST_BPE.pth"
echo ""
