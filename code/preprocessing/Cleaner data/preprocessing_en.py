#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import re
import string
from zhon.hanzi import punctuation as zh_punctuation, characters as zh_characters
from zhon.cedict import all as zh_all_ch
import pycorrector
from hanziconv import HanziConv


def remove_non_en_chars(sentences):
    new_sentences = []
    n = 0
    for s in sentences:
        print(s)
        en_ch_punc = re.findall(r'[[A-Za-z]+]|[%s]' % string.punctuation, s)
        new_s = "".join(en_ch_punc)
        print(new_s)
        new_sentences.append(new_s)
        if len(new_s) < len(s.strip()): # ignore the '\n' at the end of line
            n += 1	
        return new_sentences, n

def rearrange_newlines(sentences):
	"""
	The script was used to move the character appeared after the ideographic full stop to the beginning of the following line.
	"""
	new_sentences = []
	n = 0
	x = ""
	for line in sentences:
		# print("\'%s\'" % line)
		if len(line) >= 3 and line[-3]=="\u3002": #an ideographic full stop
			newline=x+line[:-2]
			if line[-2] == "\uff09" or line[-2] == "\uff08" or line[-2] == "\u201c" or line [-2] == "\u201d" or line [-2] == "\u2026" or line[-2] =="\n":
				x=""
			else:
				x=line[-2]
		else:
			newline=x+line[:-1]
			x=""
		# print("\'%s\'" % newline)
		new_sentences.append(newline)
		if len(newline) < len(line):
			n += 1	
	return new_sentences, n

def remove_sentences_50pc_punctuations(sentences):
	"""
	count both English and Chinese punctuations
	"""
	new_sentences = []
	n = 0
	for s in sentences:
		punc = re.findall(r"[%s]|[%s]" % (string.punctuation, zh_punctuation), s)
		if len(s) > 0 and len(punc) / len(s) < 0.5:
			new_sentences.append(s)
		else:
			n += 1
	return new_sentences, n

def apply_pycorrector(sentences):
	"""
	https://shibing624.github.io/pycorrector/README.en.html
	"""
	new_sentences = []
	n = 0
	count = 0
	for s in sentences:
		count += 1
		if count % 10000 == 0:
			print("%d/%d..." % (count, len(sentences)))
		# print("\'%s\'" % s)
		new_s, _ = pycorrector.correct(s)
		# print("\'%s\'" % new_s)
		if s != new_s:
			new_sentences.append(new_s)
			n += 1
		else:
			new_sentences.append(s)
	return new_sentences, n
	

if __name__ == '__main__':
	
	file_path = sys.argv[1]
	#print(file_path)
	with open(os.path.join(os.getcwd(), file_path), encoding='utf-8') as f:
		en_sentences = f.readlines()
		print('Total number of sentences read from file: %d\n' % len(en_sentences))
		# 1. remove non-English data
		output_1, count_1 = remove_non_en_chars(en_sentences)
		print('Number of sentences impacted by \'1. remove non-English data\': %d\n' % count_1)

		# 2. rearrange new lines
		output_2, count_2 = rearrange_newlines(output_1)
		print('Number of sentences impacted by \'2. rearrange new lines\': %d\n' % count_2)

    # 3. remove sentences where 50%+ is punctuation
		output_3, count_3 = remove_sentences_50pc_punctuations(output_2)
		print('Number of sentences impacted by \'3. remove sentences where 50 percent is punctuation\': %d\n' % count_3)

		# 4. pycorrector
		output_4, count_4 = apply_pycorrector(output_3)
		print('Number of sentences impacted by \'4. pycorrector\': %d\n' % count_4)
   
	with open(os.path.join(os.getcwd(), "preprocessing_en_output.txt"), 'w') as f_out:
		f_out.writelines('\n'.join(output_4))



