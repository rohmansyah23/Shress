import sys
import re

def process(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    output = []
    pending = {}  # prefix -> [values_str, ...]

    insert_re = re.compile(
        r'''^(INSERT INTO (?:"\w+"\.\w+|\w+\.\w+|\w+) \([^)]+\)(?: OVERRIDING SYSTEM VALUE)?) VALUES \((.*)\);$'''
    )

    for line in lines:
        stripped = line.rstrip('\n')
        m = insert_re.match(stripped)

        if m:
            prefix, vals = m.group(1), m.group(2)
            pending.setdefault(prefix, []).append(vals)
        else:
            _flush(pending, output)
            output.append(line)

    _flush(pending, output)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(output)


def _flush(pending, output):
    for prefix, values_list in pending.items():
        output.append(f'{prefix} VALUES\n')
        for i, v in enumerate(values_list):
            sep = ',' if i < len(values_list) - 1 else ';'
            output.append(f'\t({v}){sep}\n')
    pending.clear()


if __name__ == '__main__':
    process(sys.argv[1], sys.argv[2])
