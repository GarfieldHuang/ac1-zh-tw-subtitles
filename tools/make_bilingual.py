"""Merge an English and a Chinese SubtitleSynchAC1 subtitles.json into a
bilingual one (English line above, Chinese line below).

Usage: python make_bilingual.py EN_JSON ZH_JSON OUT_JSON

Both inputs map sound IDs to text segmented by <wait=..> and ended by
<duration=..>. A line is merged only when both sides carry identical tags in
the same order; otherwise the English line is kept and the ID is reported.
"""
import json
import re
import sys

TAG = re.compile(r'\s*(<(?:wait|duration)=[\d.]+>)\s*')


def split(text):
    """Return [(segment_text, tag), ...]."""
    parts = TAG.split(text.strip())
    return [(parts[i].strip(), parts[i + 1]) for i in range(0, len(parts) - 1, 2)]


def main(en_path, zh_path, out_path):
    en = json.load(open(en_path, encoding='utf-8'))
    zh = json.load(open(zh_path, encoding='utf-8'))

    out, merged, missing, mismatched = {}, 0, [], []
    for key, text in en.items():
        if key not in zh:
            missing.append(key)
            out[key] = text
            continue
        es, zs = split(text), split(zh[key])
        if [t for _, t in es] != [t for _, t in zs]:
            mismatched.append(key)
            out[key] = text
            continue
        out[key] = ' '.join(f'{e}\n{z} {t}' for (e, t), (z, _) in zip(es, zs))
        merged += 1

    json.dump(out, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'bilingual {merged}/{len(en)} lines')
    if missing:
        print(f'no translation ({len(missing)}): {missing[:10]}')
    if mismatched:
        print(f'tag mismatch, kept English ({len(mismatched)}): {mismatched[:10]}')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
