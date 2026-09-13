#!/usr/bin/env python3
"""Real Lua syntax check for DST mod files (Windows box, no luac/lua installed).

Primary : luaparser AST parse — catches real syntax errors (unbalanced end/function,
          bad table constructors, stray tokens) that a bracket counter misses.
Fallback: textual bracket balance check if luaparser isn't importable.

*** CORRECT luaparser ENTRY POINT ***
    from luaparser import ast
    ast.parse(src)
`luaparser.parse(src)` does NOT exist ->
    AttributeError: module 'luaparser' has no attribute 'parse'

luaparser is normally installed in the SYSTEM python, NOT the project venv:
    C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python311\\python.exe

Usage:
    python lua_syntax_check.py <file.lua> [more.lua ...]

Exit codes: 0 = all OK, 1 = at least one failure, 2 = no input files.
"""
import sys


def strip_lua(src):
    """Blank out string literals and -- line comments so brackets inside them don't count."""
    out = []
    i, n = 0, len(src)
    in_str, in_lc = False, False
    while i < n:
        c = src[i]
        if in_lc:
            if c == "\n":
                in_lc = False
                out.append(c)
            i += 1
            continue
        if in_str:
            out.append(" ")
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            in_lc = True
            out.append("  ")
            i += 2
            continue
        if c == '"':
            in_str = True
            out.append(" ")
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def bracket_ok(src):
    clean = strip_lua(src)
    ok = True
    for a, b in (("(", ")"), ("{", "}"), ("[", "]")):
        if clean.count(a) != clean.count(b):
            ok = False
    return ok


def check(path):
    with open(path, encoding="utf-8") as f:
        src = f.read()
    try:
        from luaparser import ast  # entry point is ast.parse, NOT luaparser.parse
        ast.parse(src)
        print("SYNTAX OK          %s  (luaparser)" % path)
        return True
    except ImportError:
        ok = bracket_ok(src)
        print("%s %s  (luaparser missing -> bracket fallback)"
              % ("BRACKETS OK      " if ok else "BRACKETS MISMATCH", path))
        return ok
    except Exception as e:
        print("SYNTAX FAIL        %s  %r" % (path, e))
        return False


if __name__ == "__main__":
    files = sys.argv[1:]
    if not files:
        print("usage: lua_syntax_check.py <file.lua> ...")
        sys.exit(2)
    sys.exit(0 if all(check(f) for f in files) else 1)
