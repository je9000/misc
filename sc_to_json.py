#!/usr/bin/env python

# Try and convert scutil output to JSON. Doesn't do arrays correctly.

import json
import re

def sc_to_json(sc):
    lines = re.split(r'\n', sc)
    x = 0
    if ' {' not in lines[0] and ' :' not in lines[0]:
        lines[0] = ''

    while x < len(lines):
        lines[x] = re.sub(r'\s+:\s+<[a-zA-Z]+>\s+(\S)', r' : \1', lines[x])
        lines[x] = re.sub(r'\s+<[a-zA-Z]+>\s+{', r' : {', lines[x])
        if re.search(r'\s{\s*$', lines[x]):
            lines[x] = re.sub(r'^(\s*)([^:]+)\s+:\s+{\s*$', r'\1"\2": {', lines[x], 0, re.MULTILINE)
        elif re.search(r'[^{}]+\s*$', lines[x]):
            lines[x] = re.sub('^(\s*)([^:]+)\s+:\s+([^{]+)\s*$', r'\1"\2": "\3",', lines[x], 0, re.MULTILINE)
        x += 1
    sc = '\n'.join(lines)
    sc = re.sub(r'}', r'},', sc)
    sc = re.sub(r',(\s*)\n(\s*})', r'\1\n\2', sc)
    sc = re.sub(r',[\s\n]*\Z', r'', sc)
    return json.loads("{" + sc + "\n}")

if __name__ == "__main__":
    import sys
    print json.dumps(sc_to_json(sys.stdin.read()), sort_keys=True, indent=4, separators=(',', ': '))
