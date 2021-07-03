# run this script in the venv where stanza is installed: source /data/s4238346/.envs/xlm_venv/bin/activate
# sample data generated by: 
#    - head /data/s4238346/wmt/processed/en-zh/train.en > /home/s4238346/bpe_sample.en
#    - head /data/s4238346/wmt/processed/en-zh/train.zh > /home/s4238346/bpe_sample.zh

import sys
import os
import stanza
from stanza.models.common.doc import Document

# check arguments
if len(sys.argv) != 3:
  raise ValueError('Please provide required arguments: python corenlp.py [Lang (en or zh)] [BPE file path]')
  
lang = sys.argv[1]
file_path = sys.argv[2]
if not os.path.isfile(file_path):
  raise ValueError('The file path provided does not exist.')

# Build pipeline
if lang == 'en':
  print("Downloading English model...")
  stanza.download('en')
  # Build an English pipeline, with dependency parse on pretagged document
  print("Building an English pipeline...")
  nlp_pipe = stanza.Pipeline('en')
elif lang == 'zh':
  # Download a Chinese model
  print("Downloading Chinese model...")
  stanza.download('zh', verbose=False)
  # Build a Chinese pipeline
  print("Building a Chinese pipeline...")
  nlp_pipe = stanza.Pipeline('zh', processors='tokenize,lemma,pos,depparse')
else:
  raise ValueError("Incorrect language arg provided. The only permitted argument is either en or zh.")
  
outputs = []
with open(file_path, "r") as f:
  for s in f:
    s_out = ''
    #print("\nOriginal:\n", en_s)
    # annotate text
    s_doc = nlp_pipe(s)
    # access annotations
    for i, sent in enumerate(s_doc.sentences):
      # ignore if sentence length is greater than 100
      if len(sent.words) <= 100:
        for word in sent.words:
          #print(word.text, end = " ")
          s_out += "%s " % word.text
        #print("##", end = " ")
        s_out += "## "
        for word in sent.words:
          #print(word.deprel, end = " ")
          s_out += "%s " % word.deprel
        #print(s_out)
    s_out += "\n"
    outputs.append(s_out)
    
# write outputs
output_path = file_path + '.depparse'
out_f = open(output_path, 'w')
out_f.writelines(outputs)
out_f.close()
print("Output is saved to %s" % output_path)

