#!/usr/bin/env python

import glob
import os
from pathlib import Path

FNL_ROOT = 'fnl'
LUA_ROOT = 'lua'

def get_files(root):
    return [f for f in glob.iglob(root + '/**', recursive=True)
            if os.path.isfile(f)]

fnlfiles = get_files(FNL_ROOT + "/")
luafiles = get_files(LUA_ROOT + "/")

# Compile source files which have been created or modified since the
# last build.
changes = False
for src in fnlfiles:
    out = src.replace(FNL_ROOT, LUA_ROOT, 1).replace('.fnl', '.lua')
    if (not os.path.exists(out)
            or os.path.getmtime(src) > os.path.getmtime(out)):
        changes = True
        # Create parent directories if they don't exist.
        Path(os.path.dirname(out)).mkdir(parents=True, exist_ok=True)
        cmd = "fennel --compile " + src + " > " + out
        print(cmd)
        os.system(cmd)
if not changes:
    print("nothing to compile")

# Remove leftover files whose sources have been deleted.
for out in luafiles:
    if out not in map(lambda f: f
            .replace(FNL_ROOT, LUA_ROOT, 1)
            .replace('.fnl', '.lua'),
            fnlfiles):
        print("removing output file with missing source: " + out)
        os.remove(out)
        # Remove parent directories if they have become empty.
        try:
            os.removedirs(os.path.dirname(out))
        except OSError:
            pass

