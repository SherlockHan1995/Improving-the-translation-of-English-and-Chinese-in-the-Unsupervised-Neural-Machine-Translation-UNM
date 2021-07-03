# run this script in the venv where stanza is installed: source /data/s4238346/.envs/xlm_venv/bin/activate

import sys
import os
from pypinyin import pinyin, lazy_pinyin, Style

usage = 'Please provide required arguments: python pinyin.py [mode (ChPy | WdPy | ChPyT | WdPyT)] [zh file path]'
if len(sys.argv) != 3:
  raise ValueError(usage)
  
mode = sys.argv[1]
file_path = sys.argv[2]
if not os.path.isfile(file_path):
  raise ValueError('The file path provided does not exist.')
  
print("Apply lazy_pinyin...")
outputs = []
with open(file_path, "r") as f:
  for s in f:
    #print(s)
    pinyin_list = []
    s_out = ''
    if mode.lower() == "chpy":
      pinyin_list = lazy_pinyin(s)
    elif mode.lower() == "chpyt":
      pinyin_list = pinyin(s)
    elif mode.lower() == "wdpy":
      words = s.split()
      #print(words)
      for w in words:
        py = lazy_pinyin(w)
        pinyin_list.append("".join(py))
    elif mode.lower() == "wdpyt":
      words = s.split()
      for w in words:
        py = pinyin(w)
        pinyin_list.append("".join('%s' %id for id in py))
    else:
      print("Invalid mode! Quit.\n" + usage)
      sys.exit(0)
    s_out = " ".join('%s' %id for id in pinyin_list)
    s_out = s.rstrip() + "## " + s_out
    # print(s_out)
    s_out += "\n"
    outputs.append(s_out)

# write outputs
output_path = file_path + '.' + mode +'.pinyin'
out_f = open(output_path, 'w')
out_f.writelines(outputs)
out_f.close()
print("Output is saved to %s" % output_path)

