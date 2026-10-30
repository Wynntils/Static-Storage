#!/usr/bin/env python3
"""Edit manual obtain methods for items whose API obtain info resolves to unknown."""

import argparse
from copy import deepcopy
import json
import os
from pathlib import Path
import tempfile
from urllib.parse import quote
import webbrowser


OBTAIN_TYPES = {
    "altar": "Boss Altar",
    "challenge": "Challenge",
    "dungeon": "Dungeon Rain",
    "dungeonMerchant": "Dungeon Merchant",
    "event": "Event",
    "guild": "Guild",
    "lootrun": "Lootrun",
    "merchant": "Merchant",
    "miniboss": "Miniboss",
    "quest": "Quest",
    "raid": "Raid",
    "caveCompletion": "Cave Completion",
    "caveLootChest": "Tier 3/4 Loot Chest",
    "discovery": "Discovery",
    "environment": "Environment",
    "forgeryChest": "Forgery Chest",
    "gathering": "Gathering",
    "interaction": "World Interaction",
    "lootChest": "Any Loot Chest",
    "mobDropRegion": "Mobs in",
    "normalMobDrop": "Normal Mob Drop",
    "rareMobDropRegion": "Rare Mobs in",
    "specificMobDrop": "Specific Mob Drop",
    "timeTrial": "Time Trial",
    "tinkering": "Tinkering",
    "worldEvent": "World Event",
    "unavailable": "Unavailable",
    "unknown": "Unknown",
}
CATEGORIES = ("gear", "ingredients", "charms", "tomes")


def needs_manual_obtain_info(item):
    """Mirror parseObtainInfo's type selection and drop-restriction fallback."""
    drop_meta = item.get("dropMeta") or {}
    meta_types = drop_meta.get("type") or []
    if isinstance(meta_types, str):
        meta_types = [meta_types]
    # Unrecognized API types are ignored; explicit UNKNOWN still blocks the fallback.
    recognized_types = [meta_type for meta_type in meta_types if meta_type in OBTAIN_TYPES]
    if recognized_types:
        return all(meta_type == "unknown" for meta_type in recognized_types)
    return item.get("dropRestriction", "never") not in ("normal", "lootchest")


def wiki_url(name):
    return "https://wynncraft.wiki.gg/wiki/" + quote(name.replace(" ", "_"), safe="")


class ObtainData:
    """Data access kept independent of Tk so it also works without a display."""

    def __init__(self, root):
        self.path = Path(root) / "Data-Storage" / "item_obtain_v2.json"
        self.original = self.path.read_bytes()
        self.manual = json.loads(self.original)
        if not isinstance(self.manual, dict):
            raise ValueError("Manual obtain data must be a JSON object")
        self.items = {}
        current_names = set()
        for category in CATEGORIES:
            path = Path(root) / "Reference" / (category + ".json")
            for name, item in json.loads(path.read_text(encoding="utf-8")).items():
                current_names.add(name)
                if needs_manual_obtain_info(item):
                    self.items[(category, name)] = item
        # Only purge after every reference has loaded, including items with API obtain info.
        current_manual = {name: entries for name, entries in self.manual.items() if name in current_names}
        if current_manual != self.manual:
            self._write(current_manual)
        else:
            self._write_expanded()

    def filtered(self, search="", category="All", hide_manual=True):
        return sorted(
            (key for key in self.items
             if (category == "All" or key[0] == category)
             and search.casefold() in key[1].casefold()
             and (not hide_manual or not self.manual.get(key[1]))),
            key=lambda key: (key[1].casefold(), key[0]),
        )

    def save(self, name, entries):
        for entry in entries:
            if not isinstance(entry, dict) or not entry.get("type"):
                raise ValueError("Every obtain method needs a type")
        updated = deepcopy(self.manual)
        if entries:
            updated[name] = deepcopy(entries)
        else:
            updated.pop(name, None)
        self._write(updated)

    def _write(self, updated):
        # Keep the stored JSON compact and preserve unrelated entries.
        payload = json.dumps(dict(sorted(updated.items())), ensure_ascii=False, separators=(",", ":"))
        if self.original.endswith(b"\n"):
            payload += "\n"
        encoded = payload.encode("utf-8")
        if self.path.read_bytes() != self.original:
            raise ValueError("The manual file changed outside this editor. Restart the editor to load it before saving.")
        self._replace_file(self.path, encoded)
        self.manual = updated
        self.original = encoded
        self._write_expanded()

    def _write_expanded(self):
        if self.path.read_bytes() != self.original:
            raise ValueError("The manual file changed outside this editor. Restart the editor to load it before saving.")
        path = self.path.with_name(self.path.stem + "_expanded.json")
        payload = json.dumps(dict(sorted(self.manual.items())), ensure_ascii=False, indent=2) + "\n"
        encoded = payload.encode("utf-8")
        if not path.exists() or path.read_bytes() != encoded:
            self._replace_file(path, encoded)

    def _replace_file(self, path, encoded):
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".item_obtain_", suffix=".tmp", delete=False) as out:
                temporary = Path(out.name)
                out.write(encoded)
                out.flush()
                os.fsync(out.fileno())
            temporary.chmod((path if path.exists() else self.path).stat().st_mode & 0o777)
            os.replace(temporary, path)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)


class ObtainEditor:
    def __init__(self, root, data):
        import tkinter as tk
        from tkinter import messagebox, ttk
        from tkinter.scrolledtext import ScrolledText

        self.tk, self.ttk, self.dialog = tk, ttk, messagebox
        self.root, self.data = root, data
        self.selected = None
        self.rows = []
        self.dirty = False
        self.loading = False
        self.active_filters = ("", "All", True)
        self.visible = []
        self.search = tk.StringVar()
        self.category = tk.StringVar(value="All")
        self.hide_manual = tk.BooleanVar(value=True)
        self.title = tk.StringVar(value="Select an item")
        self.status = tk.StringVar()
        root.title("Item obtain editor")
        root.geometry("1150x760")
        root.minsize(850, 560)
        root.protocol("WM_DELETE_WINDOW", self.close)

        filters = ttk.Frame(root, padding=10)
        filters.pack(fill="x")
        ttk.Label(filters, text="Search:").pack(side="left")
        ttk.Entry(filters, textvariable=self.search, width=28).pack(side="left", padx=(5, 15))
        ttk.Label(filters, text="Category:").pack(side="left")
        ttk.Combobox(filters, textvariable=self.category, values=("All",) + CATEGORIES,
                     state="readonly", width=14).pack(side="left", padx=5)
        ttk.Checkbutton(filters, text="Hide items with manual obtain info", variable=self.hide_manual).pack(side="left", padx=10)

        panes = ttk.Panedwindow(root, orient="horizontal")
        panes.pack(fill="both", expand=True, padx=10)
        left = ttk.Frame(panes)
        right = ttk.Frame(panes, padding=(12, 0, 0, 0))
        panes.add(left, weight=1)
        panes.add(right, weight=2)
        self.tree = ttk.Treeview(left, columns=("category", "manual"), selectmode="browse")
        self.tree.heading("#0", text="Item")
        self.tree.heading("category", text="Category")
        self.tree.heading("manual", text="Manual")
        self.tree.column("#0", width=250, minwidth=100)
        self.tree.column("category", width=85, stretch=False)
        self.tree.column("manual", width=60, stretch=False)
        scroll = ttk.Scrollbar(left, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=scroll.set)
        self.tree.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")
        self.tree.bind("<<TreeviewSelect>>", self.select)

        ttk.Label(right, textvariable=self.title, wraplength=530, font=("", 12, "bold")).pack(anchor="w")
        ttk.Button(right, text="Open wiki page", command=self.open_wiki).pack(anchor="w", pady=8)
        ttk.Label(right, text="Manual obtain methods — optional name can describe a source or location.",
                  wraplength=530).pack(anchor="w", pady=(0, 5))

        editor = ttk.Frame(right)
        editor.pack(fill="both", expand=True)
        canvas = tk.Canvas(editor, highlightthickness=0, height=220)
        row_scroll = ttk.Scrollbar(editor, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=row_scroll.set)
        canvas.pack(side="left", fill="both", expand=True)
        row_scroll.pack(side="right", fill="y")
        self.row_frame = ttk.Frame(canvas)
        window = canvas.create_window((0, 0), window=self.row_frame, anchor="nw")
        self.row_frame.bind("<Configure>", lambda event: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda event: canvas.itemconfigure(window, width=event.width))
        ttk.Button(right, text="+ Add obtain method", command=self.add_row).pack(anchor="w", pady=5)
        actions = ttk.Frame(right)
        actions.pack(fill="x", pady=5)
        ttk.Button(actions, text="Save", command=self.save).pack(side="left")
        ttk.Button(actions, text="Save & next", command=lambda: self.save(advance=True)).pack(side="left", padx=5)
        ttk.Button(actions, text="Next / skip", command=self.next_item).pack(side="left")
        ttk.Label(right, text="API item details (read only)").pack(anchor="w", pady=(10, 4))
        self.details = ScrolledText(right, height=12, width=55, wrap="word", state="disabled")
        self.details.pack(fill="both", expand=True)
        ttk.Label(root, textvariable=self.status, padding=10).pack(fill="x")
        root.bind("<Control-s>", lambda event: self.save())
        for variable in (self.search, self.category, self.hide_manual):
            variable.trace_add("write", self.filter_changed)
        self.refresh()

    def mark_dirty(self, *args):
        if not self.loading:
            self.dirty = True
            self.status.set("Unsaved changes — Save writes this item's methods to " + str(self.data.path))

    def add_row(self, entry=None):
        if self.selected is None:
            return
        original = deepcopy(entry) if entry is not None else {}
        kind = original.get("type", "unknown")
        labels = {key: label + " (" + key + ")" for key, label in OBTAIN_TYPES.items()}
        labels.setdefault(kind, kind)
        type_var = self.tk.StringVar(value=labels[kind])
        name_var = self.tk.StringVar(value=original.get("name", ""))
        frame = self.ttk.Frame(self.row_frame, padding=(0, 4))
        frame.pack(fill="x")
        frame.columnconfigure(1, weight=1)
        self.ttk.Combobox(frame, textvariable=type_var, values=list(labels.values()), state="readonly", width=30).grid(row=0, column=0, padx=(0, 5))
        self.ttk.Entry(frame, textvariable=name_var).grid(row=0, column=1, sticky="ew")
        row = (frame, type_var, name_var, original, {v: k for k, v in labels.items()})
        self.ttk.Button(frame, text="Remove", command=lambda: self.remove_row(row)).grid(row=0, column=2, padx=5)
        self.rows.append(row)
        type_var.trace_add("write", self.mark_dirty)
        name_var.trace_add("write", self.mark_dirty)
        self.mark_dirty()

    def remove_row(self, row):
        row[0].destroy()
        self.rows.remove(row)
        self.mark_dirty()

    def entries(self):
        result = []
        for _, type_var, name_var, original, keys in self.rows:
            entry = deepcopy(original)
            entry["type"] = keys[type_var.get()]
            name = name_var.get().strip()
            if name:
                entry["name"] = name
            else:
                entry.pop("name", None)
            result.append(entry)
        return result

    def may_leave(self):
        if not self.dirty:
            return True
        answer = self.dialog.askyesnocancel("Unsaved changes", "Save changes to this item before continuing?", parent=self.root)
        if answer is None:
            return False
        if answer:
            return self.write_selected()
        self.dirty = False
        return True

    def write_selected(self):
        if self.selected is None:
            return True
        try:
            self.data.save(self.selected[1], self.entries())
        except (OSError, ValueError) as error:
            self.dialog.showerror("Could not save", str(error), parent=self.root)
            return False
        self.dirty = False
        return True

    def refresh(self, preferred=None):
        self.loading = True
        self.active_filters = (self.search.get(), self.category.get(), self.hide_manual.get())
        self.visible = self.data.filtered(self.search.get(), self.category.get(), self.hide_manual.get())
        self.tree.delete(*self.tree.get_children())
        for index, (category, name) in enumerate(self.visible):
            self.tree.insert("", "end", iid=str(index), text=name,
                             values=(category, "Yes" if self.data.manual.get(name) else "No"))
        self.loading = False
        if self.visible:
            key = preferred if preferred in self.visible else self.visible[0]
            self.show(key)
            self.focus_item(key)
        else:
            self.show(None)
        self.status.set(f"{len(self.visible)} shown / {len(self.data.items)} without API obtain info. Manual file: {self.data.path}")

    def focus_item(self, key):
        if key in self.visible:
            iid = str(self.visible.index(key))
            self.tree.selection_set(iid)
            self.tree.focus(iid)
            self.tree.see(iid)

    def show(self, key):
        self.loading = True
        for row in self.rows:
            row[0].destroy()
        self.rows.clear()
        self.selected = key
        self.title.set(f"{key[1]} — {key[0]}" if key else "No matching items")
        if key:
            for entry in self.data.manual.get(key[1], []):
                self.add_row(entry)
        self.details.configure(state="normal")
        self.details.delete("1.0", "end")
        if key:
            self.details.insert("1.0", json.dumps(self.data.items[key], ensure_ascii=False, indent=2))
        self.details.configure(state="disabled")
        self.dirty = False
        self.loading = False

    def select(self, event=None):
        selection = self.tree.selection()
        if self.loading or not selection:
            return
        key = self.visible[int(selection[0])]
        if key == self.selected:
            return
        if self.may_leave():
            # A save may change whether the old item matches the filters.
            self.refresh(preferred=key)
        else:
            self.focus_item(self.selected)

    def filter_changed(self, *args):
        if self.loading:
            return
        if self.may_leave():
            self.refresh(preferred=self.selected)
        else:
            self.loading = True
            for variable, value in zip((self.search, self.category, self.hide_manual), self.active_filters):
                variable.set(value)
            self.loading = False

    def following(self):
        if self.selected in self.visible:
            index = self.visible.index(self.selected)
            if index + 1 < len(self.visible):
                return self.visible[index + 1]
        return self.selected

    def save(self, advance=False):
        if self.selected is None:
            return
        name = self.selected[1]
        target = self.following() if advance else self.selected
        if self.write_selected():
            self.refresh(preferred=target)
            self.status.set(f"Saved {name}. {len(self.visible)} items shown.")

    def next_item(self):
        target = self.following()
        if self.may_leave():
            self.refresh(preferred=target)

    def open_wiki(self):
        if self.selected:
            url = wiki_url(self.selected[1])
            try:
                if not webbrowser.open(url):
                    self.dialog.showinfo("Wiki page", "Open this guessed URL in your browser:\n" + url, parent=self.root)
            except webbrowser.Error as error:
                self.dialog.showerror("Could not open browser", str(error), parent=self.root)

    def close(self):
        if self.may_leave():
            self.root.destroy()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parent.parent,
                        help="Repository containing Reference/ and Data-Storage/ (defaults to this script's repository)")
    parser.add_argument("--summary", action="store_true", help="Print counts without opening the UI")
    args = parser.parse_args()
    try:
        data = ObtainData(args.repo_root)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Could not load item data: {error}\n")
    if args.summary:
        for category in CATEGORIES:
            missing = len(data.filtered(category=category, hide_manual=False))
            undocumented = len(data.filtered(category=category))
            print(f"{category}: {missing} resolve to unknown API obtain info; {undocumented} also missing manual info")
        return
    try:
        import tkinter as tk
        root = tk.Tk()
    except ImportError:
        parser.exit(1, "Tkinter is required.\n")
    except tk.TclError as error:
        parser.exit(1, f"Could not open the UI. Run from a desktop session: {error}\n")
    ObtainEditor(root, data)
    root.mainloop()


if __name__ == "__main__":
    main()
