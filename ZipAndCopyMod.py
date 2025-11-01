#!/usr/bin/env python3

import os
import subprocess
import sys


def main():
  mod_dir = sys.argv[1] if len(sys.argv) > 1 else "."
  if not os.path.isdir(mod_dir):
    raise NotADirectoryError(f'"{mod_dir}" is not a directory.')

  subprocess.run([sys.executable, "ZipMod.py", mod_dir], check=True)
  subprocess.run([sys.executable, "CopyMod.py", mod_dir], check=True)


if __name__ == "__main__":
  main()
