from collections import defaultdict
from io import TextIOWrapper
import lxml.etree
import os
from dataclasses import dataclass
import json
import dataclasses
import math

# Use camelCase for field names
# because Swift needs to decode them
@dataclass(frozen=True, eq=True)
class Entry:
    origin: str
    vocabularyLevel: str
    prs: list[str]
    equivalentEnglishWords: list[list[str]]


class EnhancedJSONEncoder(json.JSONEncoder):
    def default(self, o: object):
        if dataclasses.is_dataclass(o):
            return dataclasses.asdict(o)
        return super().default(o)


# https://stackoverflow.com/a/52154263/6798201
class EnhancedJSONDecoder(json.JSONDecoder):
    def __init__(self, *args, **kwargs):
        json.JSONDecoder.__init__(self, object_hook=self.object_hook, *args, **kwargs)
    def object_hook(self, dict):
        if "origin" in dict:
            return Entry(
                dict["origin"],
                dict["vocabularyLevel"],
                dict["prs"],
                dict["equivalentEnglishWords"],
            )
        return dict

def parse_krdict(
    dict_xml: TextIOWrapper,
    words: dict[str, list[Entry]],
    english_word_freqs: dict[str, int],
) -> int:
    # create element tree object
    tree = lxml.etree.parse(dict_xml)
    # get root element
    root = tree.getroot().find("Lexicon")
    # number of english word groups in the dictionary
    english_word_group_size = 0

    for entry in root.findall("LexicalEntry"):
        # Get word
        word = entry.find("Lemma/feat").attrib["val"].strip()

        # Get vocabulary level
        vocabulary_level = entry.xpath("feat[@att='vocabularyLevel']")
        if len(vocabulary_level) > 0:
            level = vocabulary_level[0].attrib["val"]
            if level == "없음":
                vocabulary_level = "?"
            elif level == "초급":
                vocabulary_level = "elementary"
            elif level == "중급":
                vocabulary_level = "intermediate"
            elif level == "고급":
                vocabulary_level = "advanced"
            else:
                raise Exception("Unexpected vocabulary level {}".format(level))
        elif len(vocabulary_level) >= 2:
            raise Exception("Expecting only one vocabulary level field")
        else:
            vocabulary_level = "?"

        # Get origin
        origins = entry.xpath("feat[@att='origin']")
        origin: str = "?"
        if len(origins) == 1:
            origin = origins[0].attrib["val"].strip()
        elif len(origins) > 1:
            raise Exception("Expecting a single origin for the word {}", word)

        # Get pronunciations
        prs = entry.xpath(
            "WordForm/feat[@val='발음']/following-sibling::feat[@att='pronunciation']"
        )
        # Get rid of length marks
        valid_prs = list(
            map(
                lambda pr: pr.attrib["val"].replace("ː", "").strip(),
                filter(lambda pr: "val" in pr.attrib, prs),
            )
        )
        # valid_prs.freeze()
        # Get equivalent english words
        equivalent_english_words: list[list[str]] = []
        for sense in entry.findall("Sense"):
            for equivalent in sense.findall("Equivalent"):
                languages = equivalent.xpath("feat[@att='language']")
                if len(languages) == 1:
                    language = languages[0].attrib["val"]
                    # Found English equivalent words
                    if language == "영어":
                        english_val: str = equivalent.xpath("feat[@att='lemma']")[
                            0
                        ].attrib["val"]
                        english_words = list(
                            filter(lambda word: word != "(no equivalent expression)", map(lambda word: word.strip(), english_val.split(";")))
                        )
                        # english_words.freeze()
                        if len(english_words) > 0:
                            equivalent_english_words.append(english_words)
                            for english_word in set(english_words):
                                english_word_freqs[english_word] += 1
                            english_word_group_size += 1
                else:
                    raise Exception(
                        "Expecting a single language feat for the <Equivalent>"
                    )
        # equivalent_english_words.freeze()
        word_entry = Entry(
            origin, vocabulary_level, valid_prs, equivalent_english_words
        )
        words[word].append(word_entry)
    return english_word_group_size


def generate_dict():
    # create empty dictionary from (word, origin, vocabulary_level) to pronunciations
    words: defaultdict[str, list[Entry]] = defaultdict(list)
    english_word_group_size = 0
    english_word_freqs: defaultdict[str, int] = defaultdict(int)

    dir = "krdict/"

    # Parse dictionary XMLs
    for filename in os.listdir(dir):
        if not filename.endswith(".xml"):
            continue
        with open(dir + filename, "r") as krdict:
            english_word_group_size += parse_krdict(krdict, words, english_word_freqs)

    # Calculate Inverse Document Frequency
    english_word_idf = {word: math.log(english_word_group_size / freq) for word, freq in english_word_freqs.items()}
    english_word_idf = dict(sorted(english_word_idf.items(), key=lambda item: item[1]))
    stopwords = list(english_word_idf.items())[:20]
    for stopword in stopwords:
        print(stopword)

    # Write to output
    with open("KrDict.json", "w+") as output:
        word_list = list(
            map(lambda item: {"word": item[0], "entries": item[1]}, words.items())
        )
        output.write(
            json.dumps(
                word_list, cls=EnhancedJSONEncoder, ensure_ascii=False, indent=None
            )
        )


def generate_lookup_table(krdict: dict[str, list[Entry]]):
    lookup_table_with_freq: defaultdict[str, list[tuple[int, int, int]]] = defaultdict(list)
    for word_index, (_entry_word, entries) in enumerate(krdict.items()):
        for entry_index, entry in enumerate(entries):
            english_word_freqs: defaultdict[str, int] = defaultdict(int)
            for english_word_group in entry.equivalentEnglishWords:
                for english_word in english_word_group:
                    english_word = english_word.lower()
                    english_word_freqs[english_word] += 1
                    english_word_cleaned = remove_stopword_at_start(english_word)
                    if english_word_cleaned != english_word:
                        english_word_freqs[english_word_cleaned] += 1
            for english_word, freq in english_word_freqs.items():
                lookup_table_with_freq[english_word].append((word_index, entry_index, freq))
    lookup_table: dict[str, list[tuple[int, int]]] = {}
    for english_word, candidates in lookup_table_with_freq.items():
        lookup_table[english_word] = list(map(lambda candidate: candidate[:2],
            sorted(candidates, key=lambda candidate: candidate[2])
        ))
    # Write to output
    with open("KrDictEnglishLookUpTable.json", "w+") as output:
        output.write(
            json.dumps(
                lookup_table, ensure_ascii=False, indent=None
            )
        )


def remove_stopword_at_start(s: str) -> str:
    stopwords = {"a", "an", "the"}
    for stopword in stopwords:
        if s.startswith(stopword + " "):
            return s[len(stopword) + 1:]
    return s


def read_dict_from_json() -> dict[str, list[Entry]]:
    with open("KrDict.json", "r") as f:
        raw_dict = json.load(f, cls=EnhancedJSONDecoder)
        dict = {}
        for word in raw_dict:
            dict[word["word"]] = word["entries"]
        return dict


if __name__ == "__main__":
    # generate_dict()
    generate_lookup_table(read_dict_from_json())
