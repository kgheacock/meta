#!/usr/bin/env python3
"""Scaffold a plain-Markdown TODO ledger entry (epic folder + task file).

Why this exists: creating the epic folder, instantiating the epic and task
files from templates, and wiring the task into the epic's Tasks list is
deterministic, fiddly, and easy to get subtly wrong by hand. This script does
it idempotently so the model can spend its attention on the parts that need
judgment (writing a good DoD, assessing whether the change meets it).

Layout produced (epic-folder-with-task-files):

    todos/
      EPIC-3-billing/
        epic.md
        TASK-7-invoices-endpoint.md

Usage:
    python scaffold_todo.py \
        --epic-id EPIC-3 --epic-title "Billing" \
        --task-id TASK-7 --task-title "Add invoices endpoint" \
        [--root todos] [--epic-slug billing] [--task-slug invoices-endpoint]

Behaviour:
  * Creates the epic folder and epic.md from the template if they don't exist.
  * Always creates the task file (errors if it already exists, to avoid clobber).
  * Appends a task line to the epic's "## Tasks" section if not already present.
  * Prints the relative paths of the epic and task files (one per line, keyed)
    so the caller can locate them for follow-up edits.

Slugs default to a lowercased, hyphenated form of the title.
"""

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, "..", "assets"))


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-") or "untitled"


def read_template(name: str) -> str:
    path = os.path.join(ASSETS, name)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def fill(template: str, mapping: dict) -> str:
    out = template
    for key, value in mapping.items():
        out = out.replace("{" + key + "}", value)
    return out


def ensure_epic(epic_dir: str, epic_id: str, epic_title: str) -> str:
    epic_path = os.path.join(epic_dir, "epic.md")
    if os.path.exists(epic_path):
        return epic_path
    os.makedirs(epic_dir, exist_ok=True)
    body = fill(
        read_template("epic-template.md"),
        {"EPIC-ID": epic_id, "Epic title": epic_title},
    )
    # Drop the placeholder task line; real tasks are appended below.
    body = re.sub(r"^- \[ \] \[\{TASK-ID\}.*$\n?", "", body, flags=re.MULTILINE)
    with open(epic_path, "w", encoding="utf-8") as f:
        f.write(body)
    return epic_path


def create_task(epic_dir: str, task_file: str, epic_id: str,
                task_id: str, task_title: str) -> str:
    task_path = os.path.join(epic_dir, task_file)
    if os.path.exists(task_path):
        sys.exit(f"Task file already exists: {task_path}")
    body = fill(
        read_template("task-template.md"),
        {"TASK-ID": task_id, "Task title": task_title, "EPIC-ID": epic_id},
    )
    with open(task_path, "w", encoding="utf-8") as f:
        f.write(body)
    return task_path


def link_task_in_epic(epic_path: str, task_id: str, task_title: str,
                      task_file: str) -> None:
    with open(epic_path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    task_line = f"- [ ] [{task_id}: {task_title}](./{task_file}) — PR: —"
    if any(task_id in ln and task_file in ln for ln in lines):
        return  # already linked

    # Find the "## Tasks" header and insert after the last existing task line.
    try:
        start = next(i for i, ln in enumerate(lines)
                     if ln.strip().lower() == "## tasks")
    except StopIteration:
        # No Tasks section — append one.
        lines += ["", "## Tasks", "", task_line]
        with open(epic_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        return

    insert_at = start + 1
    i = start + 1
    while i < len(lines) and not lines[i].startswith("## "):
        if lines[i].strip().startswith("- ["):
            insert_at = i + 1
        i += 1
    lines.insert(insert_at, task_line)
    with open(epic_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", default="todos", help="Root TODO directory (default: todos)")
    p.add_argument("--epic-id", required=True)
    p.add_argument("--epic-title", required=True)
    p.add_argument("--epic-slug")
    p.add_argument("--task-id", required=True)
    p.add_argument("--task-title", required=True)
    p.add_argument("--task-slug")
    args = p.parse_args()

    epic_slug = args.epic_slug or slugify(args.epic_title)
    task_slug = args.task_slug or slugify(args.task_title)
    epic_dir = os.path.join(args.root, f"{args.epic_id}-{epic_slug}")
    task_file = f"{args.task_id}-{task_slug}.md"

    epic_path = ensure_epic(epic_dir, args.epic_id, args.epic_title)
    task_path = create_task(epic_dir, task_file, args.epic_id,
                            args.task_id, args.task_title)
    link_task_in_epic(epic_path, args.task_id, args.task_title, task_file)

    print(f"epic: {epic_path}")
    print(f"task: {task_path}")


if __name__ == "__main__":
    main()
