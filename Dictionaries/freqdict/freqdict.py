import csv
import json
from collections import defaultdict

with open("FreqDict.csv", "r") as input_file:
	mapping: defaultdict[str, list[int]] = defaultdict(list)
	reader = csv.reader(input_file, delimiter='\t')
	for row in reader:
		freq = int(row[0])
		entry_word_variants = row[1].split("/")
		for variant in entry_word_variants:
			mapping[variant].append(freq)
	average_mapping: dict[str, int] = { k: sum(v)//len(v) for k, v in mapping.items() }
	with open("FreqDict.json", "w+") as output_file:
		json.dump(average_mapping, output_file, ensure_ascii=False, indent=None)
