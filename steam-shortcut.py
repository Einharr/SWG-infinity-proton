#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import struct
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Node:
    kind: int
    key: str
    value: bytes | list["Node"]


def read_cstring(data: bytes, pos: int) -> tuple[str, int]:
    end = data.index(0, pos)
    return data[pos:end].decode("utf-8", errors="surrogateescape"), end + 1


def parse_node(data: bytes, pos: int) -> tuple[Node, int]:
    kind = data[pos]
    pos += 1
    key, pos = read_cstring(data, pos)
    if kind == 0:
        children: list[Node] = []
        while data[pos] != 8:
            child, pos = parse_node(data, pos)
            children.append(child)
        return Node(kind, key, children), pos + 1
    if kind == 1:
        end = data.index(0, pos)
        return Node(kind, key, data[pos : end + 1]), end + 1
    sizes = {2: 4, 3: 4, 4: 4, 6: 4, 7: 8, 10: 8}
    if kind not in sizes:
        raise ValueError(f"unsupported binary VDF type {kind}")
    size = sizes[kind]
    return Node(kind, key, data[pos : pos + size]), pos + size


def encode_node(node: Node) -> bytes:
    header = bytes([node.kind]) + node.key.encode("utf-8") + b"\0"
    if node.kind == 0:
        assert isinstance(node.value, list)
        return header + b"".join(encode_node(child) for child in node.value) + b"\x08"
    assert isinstance(node.value, bytes)
    return header + node.value


def string_node(key: str, value: str) -> Node:
    return Node(1, key, value.encode("utf-8") + b"\0")


def dword_node(key: str, value: int) -> Node:
    return Node(2, key, struct.pack("<I", value))


def string_field(node: Node, key: str) -> str:
    assert isinstance(node.value, list)
    for child in node.value:
        if child.kind == 1 and child.key == key:
            assert isinstance(child.value, bytes)
            return child.value[:-1].decode("utf-8", errors="replace")
    return ""


def appid_field(node: Node) -> int | None:
    assert isinstance(node.value, list)
    for child in node.value:
        if child.kind == 2 and child.key == "appid":
            assert isinstance(child.value, bytes)
            return struct.unpack("<I", child.value)[0]
    return None


def write_atomic(path: Path, data: bytes | str) -> None:
    mode = "wb" if isinstance(data, bytes) else "w"
    kwargs = {} if isinstance(data, bytes) else {"encoding": "utf-8", "newline": ""}
    with tempfile.NamedTemporaryFile(mode=mode, dir=path.parent, delete=False, **kwargs) as out:
        out.write(data)
        temp = Path(out.name)
    temp.replace(path)


def update_shortcuts(path: Path, appid: int, exe: str, start_dir: str, options: str) -> None:
    if path.exists() and path.stat().st_size:
        data = path.read_bytes()
        root, pos = parse_node(data, 0)
        if root.kind != 0 or root.key != "shortcuts" or any(b != 8 for b in data[pos:]):
            raise ValueError("unexpected shortcuts.vdf structure")
    else:
        root = Node(0, "shortcuts", [])
    assert isinstance(root.value, list)

    for entry in root.value:
        existing_id = appid_field(entry)
        if existing_id == appid and string_field(entry, "AppName") != "SWG Infinity":
            raise RuntimeError(f"Steam shortcut appid {appid} is already in use")

    entry = Node(
        0,
        "0",
        [
            dword_node("appid", appid),
            string_node("AppName", "SWG Infinity"),
            string_node("Exe", f'"{exe}"'),
            string_node("StartDir", f'"{start_dir}"'),
            string_node("icon", exe),
            string_node("ShortcutPath", ""),
            string_node("LaunchOptions", options),
            dword_node("IsHidden", 0),
            dword_node("AllowDesktopConfig", 1),
            dword_node("AllowOverlay", 1),
            dword_node("OpenVR", 0),
            dword_node("Devkit", 0),
            string_node("DevkitGameID", ""),
            dword_node("DevkitOverrideAppID", 0),
            dword_node("LastPlayTime", 0),
            string_node("FlatpakAppID", ""),
            string_node("sortas", ""),
            Node(0, "tags", []),
        ],
    )

    replaced = False
    for index, current in enumerate(root.value):
        if appid_field(current) == appid or string_field(current, "AppName") == "SWG Infinity":
            entry.key = current.key
            root.value[index] = entry
            replaced = True
            break
    if not replaced:
        numeric = [int(item.key) for item in root.value if item.key.isdigit()]
        entry.key = str(max(numeric, default=-1) + 1)
        root.value.append(entry)
    write_atomic(path, encode_node(root) + b"\x08")


def matching_brace(text: str, opening: int) -> int:
    depth = 0
    quoted = False
    escaped = False
    for index in range(opening, len(text)):
        char = text[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("unbalanced config.vdf braces")


def keyed_block(text: str, key: str, start: int = 0, end: int | None = None) -> tuple[int, int] | None:
    limit = len(text) if end is None else end
    match = re.search(rf'"{re.escape(key)}"\s*\{{', text[start:limit], re.IGNORECASE)
    if not match:
        return None
    block_start = start + match.start()
    opening = start + match.end() - 1
    return block_start, matching_brace(text, opening) + 1


def update_compat_mapping(path: Path, appid: int, tool: str) -> None:
    text = path.read_text(encoding="utf-8", errors="surrogateescape")
    mapping = keyed_block(text, "CompatToolMapping")
    entry = (
        f'\n\t\t\t\t\t"{appid}"\n'
        "\t\t\t\t\t{\n"
        f'\t\t\t\t\t\t"name"\t\t"{tool}"\n'
        '\t\t\t\t\t\t"config"\t\t""\n'
        '\t\t\t\t\t\t"priority"\t\t"250"\n'
        "\t\t\t\t\t}"
    )
    if mapping:
        old = keyed_block(text, str(appid), mapping[0], mapping[1])
        if old:
            text = text[: old[0]] + entry.lstrip("\n") + text[old[1] :]
        else:
            text = text[: mapping[1] - 1] + entry + "\n\t\t\t\t" + text[mapping[1] - 1 :]
    else:
        steam = keyed_block(text, "Steam")
        if not steam:
            raise ValueError("Steam block not found in config.vdf")
        block = '\n\t\t\t\t"CompatToolMapping"\n\t\t\t\t{' + entry + "\n\t\t\t\t}\n\t\t\t"
        text = text[: steam[1] - 1] + block + text[steam[1] - 1 :]
    write_atomic(path, text)


def main() -> None:
    if len(sys.argv) != 9:
        raise SystemExit(
            "usage: steam-shortcut.py SHORTCUTS CONFIG BACKUP_DIR APPID TOOL EXE START_DIR OPTIONS"
        )
    shortcuts, config, backup_dir = map(Path, sys.argv[1:4])
    appid = int(sys.argv[4])
    tool, exe, start_dir, options = sys.argv[5:9]
    backup_dir.mkdir(parents=True, exist_ok=True)
    if shortcuts.exists() and not (backup_dir / "shortcuts.vdf").exists():
        shutil.copy2(shortcuts, backup_dir / "shortcuts.vdf")
    if not (backup_dir / "config.vdf").exists():
        shutil.copy2(config, backup_dir / "config.vdf")
    shortcuts.parent.mkdir(parents=True, exist_ok=True)
    update_shortcuts(shortcuts, appid, exe, start_dir, options)
    update_compat_mapping(config, appid, tool)


if __name__ == "__main__":
    main()
