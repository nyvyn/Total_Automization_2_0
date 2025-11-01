#!/usr/bin/env python3

import json
import os
import platform
import shutil
import subprocess
import sys


def read_mod_metadata(mod_path: str) -> tuple[str, str]:
    info_path = os.path.join(mod_path, "info.json")
    if not os.path.isfile(info_path):
        raise FileNotFoundError(f'No "info.json" found in "{mod_path}".')

    with open(info_path, "r", encoding="utf-8") as info_file:
        info = json.load(info_file)

    return info["name"], info["version"]


def determine_mods_directory() -> str:
    system = platform.system()
    if system == "Windows":
        appdata = os.environ.get("APPDATA")
        if not appdata:
            raise EnvironmentError("APPDATA environment variable is not set.")
        return os.path.join(appdata, "Factorio", "mods")
    if system == "Darwin":
        return os.path.expanduser("~/Library/Application Support/factorio/mods")
    if system == "Linux":
        return os.path.expanduser("~/.factorio/mods")

    raise EnvironmentError(f"Unsupported platform: {system}")


def ensure_archive_exists(mod_path: str, archive_name: str) -> str:
    archive_filename = f"{archive_name}.zip"
    if not os.path.isfile(archive_filename):
        subprocess.run(
            [sys.executable, "ZipMod.py", mod_path],
            check=True,
        )
    if not os.path.isfile(archive_filename):
        raise FileNotFoundError(
            f'Archive "{archive_filename}" could not be created. '
            "Run ZipMod.py manually to investigate."
        )
    return archive_filename


def main():
    mod_path = sys.argv[1] if len(sys.argv) > 1 else "."
    if not os.path.isdir(mod_path):
        raise NotADirectoryError(f'"{mod_path}" is not a directory.')

    mod_name, mod_version = read_mod_metadata(mod_path)
    archive_basename = f"{mod_name}_{mod_version}"
    archive_path = ensure_archive_exists(mod_path, archive_basename)

    target_dir = determine_mods_directory()
    os.makedirs(target_dir, exist_ok=True)

    dest_path = os.path.join(target_dir, os.path.basename(archive_path))
    shutil.copy2(archive_path, dest_path)

    print(f"Copied {archive_path} -> {dest_path}")


if __name__ == "__main__":
    main()
