#!/usr/bin/env python3
"""Cheap Lua syntax sanity check when luac/lua are NOT installed (typical Windows DST box).

Strips strings and -- line comments, then verifies bracket balance for ( ) { } [ ].
Catches unbalanced parens/braces from careless edits; NOT a logic checker.

Usage:
    python lua_bracket_check.py <file.lua> [more.lua ...]

Exit code: 0 = all balanced, 1 = at least one mismatch, 2 = no files given.
"""
import sys


def strip_lua(src):
    out = []
    i, n = 0, len(src)
    in_str, in_lc = False, False  # in string literal / in line comment
    while i < n:
        c = src[i]
        if in_lc:
            if c == '\n':
                in_lc = False
                out.append(c)
            i += 1
            continue
        if in_str:
            out.append(' ')
            if c == '\\':
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '-' and i + 1 < n and src[i + 1] == '-':
            in_lc = True
            out.append('  ')
            i += 2
            continue
        if c == '"':
            in_str = True
            out.append(' ')
            i += 1
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def check(path):
    with open(path, encoding='utf-8') as f:
        src = f.read()
    clean = strip_lua(src)
    ok = True
    for a, b in (('(', ')'), ('{', '}'), ('[', ']')):
        ca, cb = clean.count(a), clean.count(b)
        if ca != cb:
            ok = False
        print(f'{path}: {a}{b} {ca}/{cb} {"OK" if ca == cb else "MISMATCH"}')
    return ok


if __name__ == '__main__':
    files = sys.argv[1:]
    if not files:
        print('usage: lua_bracket_check.py <file.lua> ...')
        sys.exit(2)
    sys.exit(0 if all(check(f) for f in files) else 1)
