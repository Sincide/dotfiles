#!/usr/bin/env python3
import sys
import os
import re
import json

# Usage: text2quizjson.py input.txt [output.json]

def clean_question_text(text):
    # Remove lines with chapter, time spent, correctness, and answer key
    lines = text.splitlines()
    cleaned = []
    for line in lines:
        l = line.strip()
        if not l:
            continue
        if re.match(r'^chapter \d+:', l, re.IGNORECASE):
            continue
        if re.match(r'^overall time spent:', l, re.IGNORECASE):
            continue
        if l.lower() in ("correct", "incorrect"):
            continue
        if re.match(r'^[a-d](,\s*[a-d])* is correct$', l.lower()):
            continue
        if re.match(r'^\d+ of \d+$', l.lower()):
            continue
        cleaned.append(line)
    return '\n'.join(cleaned).strip()

def parse_quiz(text):
    # Split on '\nQuestion\n' or '\r\nQuestion\r\n'
    blocks = re.split(r'\nQuestion\n|\r\nQuestion\r\n', text)
    questions = []
    qnum = 1
    for i in range(len(blocks)):
        block = blocks[i].strip()
        if not block or not re.search(r'[A-F]\. ', block):
            continue
        # The answer lines are at the end of this block, after the explanation
        lines = block.splitlines()
        # Find the last option line
        last_opt_idx = -1
        for idx, line in enumerate(lines):
            if re.match(r'^[A-F]\. ', line.strip()):
                last_opt_idx = idx
        # Find 'Explanation' line
        expl_idx = -1
        for idx, line in enumerate(lines):
            if line.strip() == 'Explanation':
                expl_idx = idx
                break
        # Question text is from start to first option
        q_match = re.search(r'^(.*?)(?=\nA\. )', block, re.DOTALL)
        question_text = q_match.group(1).strip() if q_match else block
        question_text = clean_question_text(question_text)
        # Extract choices
        choices = {}
        for opt in ['A', 'B', 'C', 'D', 'E', 'F']:
            opt_match = re.search(rf'^{opt}\.\s*(.*)', block, re.MULTILINE)
            if opt_match:
                choices[opt] = opt_match.group(1).strip()
        # Extract explanation
        explanation = ''
        if expl_idx != -1:
            explanation = '\n'.join(lines[expl_idx+1:]).strip()
            # Remove any trailing lines that are just 'N of 20', 'X is correct', or blank
            explanation = re.split(r'\n\d+ of \d+\n|\n[A-F](?:,\s*[A-F])* is correct\n', explanation)[0].strip()
        # Now, look for the correct answer in the lines after this block, up to the next block
        correct = []
        if i+1 < len(blocks):
            # The text between this block and the next block
            after_block = blocks[i+1]
            m = re.search(r'([A-F](?:,\s*[A-F])*) is correct', after_block)
            if m:
                correct = [a.strip() for a in m.group(1).split(',')]
        else:
            # For the last block, look at the end
            m = re.search(r'([A-F](?:,\s*[A-F])*) is correct', block)
            if m:
                correct = [a.strip() for a in m.group(1).split(',')]
        questions.append({
            "number": qnum,
            "question": question_text,
            "choices": choices,
            "correct": correct,
            "explanation": explanation
        })
        qnum += 1
    return questions

def normalize_filename(name):
    # Remove special characters, replace spaces with underscores, lowercase
    base = os.path.splitext(os.path.basename(name))[0]
    base = re.sub(r'[^a-zA-Z0-9_]', '', base.replace(' ', '_')).lower()
    return base + '.json'

def main():
    if len(sys.argv) < 2:
        # Interactive prompt
        txt_files = [f for f in os.listdir('.') if f.endswith('.txt')]
        if not txt_files:
            print('No .txt files found in current directory.')
            sys.exit(1)
        print('Select input file:')
        for i, f in enumerate(txt_files):
            print(f'{i+1}: {f}')
        idx = int(input('Enter number: ')) - 1
        infile = txt_files[idx]
    else:
        infile = sys.argv[1]
    with open(infile, 'r', encoding='utf-8') as f:
        text = f.read()
    questions = parse_quiz(text)
    if len(sys.argv) >= 3:
        outfile = sys.argv[2]
    else:
        default_out = normalize_filename(infile)
        out_prompt = f'Output file [{default_out}]: '
        out_input = input(out_prompt)
        outfile = out_input.strip() or default_out
    with open(outfile, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    print(f'Wrote {len(questions)} questions to {outfile}')

if __name__ == '__main__':
    main() 