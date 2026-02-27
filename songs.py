#!/usr/bin/env python3
"""
songs.py - manage song uploads to Google Drive

Commands:
  status          Show upload status of all songs
  upload <name>   Build, merge, and upload a song group

Upload units are grouped by artist + title (without Capo variant), e.g.:
  "Madonna/Borderline"      <- Borderline.tex + Borderline Capo X.tex
  "Madonna/Borderline (E)"  <- Borderline (E).tex + Borderline (E) Capo II.tex

Body files (e.g. "Borderline Body.tex") are excluded as standalone units
but are checked for staleness when evaluating their parent unit.

Auth:
  Place credentials.json and token.pickle in the repo root (or set
  GOOGLE_API_CREDENTIALS_FILE / GOOGLE_API_TOKEN_PICKLE_FILE env vars).
"""

import argparse
import json
import os
import pickle
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from pypdf import PdfWriter

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).parent
SONGS_DIR = REPO_ROOT / "songs"
BUILD_DIR = REPO_ROOT / "build" / "pdf"
MANIFEST_FILE = REPO_ROOT / "manifest.json"
TEXML_HOME = Path.home() / "Library" / "texmf" / "tex" / "latex"

DRIVE_FOLDER_ID = "1YBA99d9GmHTa6HktdpjHvSpoMQfoOrBb"
DRIVE_SCOPES = ["https://www.googleapis.com/auth/drive"]

CAPO_RE = re.compile(r"\s+Capo\s+[IVXLCivxlc]+$")
BODY_RE = re.compile(r"\s+Body$")


# ---------------------------------------------------------------------------
# Upload unit logic
# ---------------------------------------------------------------------------

def unit_name_for(stem):
    """Return the upload unit name for a .tex stem (strips trailing Capo X)."""
    return CAPO_RE.sub("", stem)


def is_body(stem):
    return bool(BODY_RE.search(stem))


def get_upload_units():
    """Walk songs/ and group .tex files into upload units.

    Returns dict mapping "Artist/Unit Name" -> [Path, ...] sorted so the
    base version (no capo) comes first.
    """
    units = {}
    for tex_file in sorted(SONGS_DIR.rglob("*.tex")):
        stem = tex_file.stem
        if is_body(stem):
            continue
        artist = tex_file.parent.name
        unit_key = f"{artist}/{unit_name_for(stem)}"
        units.setdefault(unit_key, []).append(tex_file)

    # Sort each group: base version first, then capo variants
    for key in units:
        units[key].sort(key=lambda f: (bool(CAPO_RE.search(f.stem)), f.stem))

    return units


def body_file_for(unit_key):
    """Return the Body .tex path for a unit if it exists."""
    artist, title = unit_key.split("/", 1)
    # Strip key variant like "(E)" to find the base body file
    # Body files are always named after the base song title
    base_title = re.sub(r"\s*\([^)]+\)\s*$", "", title).strip()
    return SONGS_DIR / artist / f"{base_title} Body.tex"


def latest_mtime(unit_key, tex_files):
    """Return the latest modification time across all source files for a unit."""
    mtimes = [f.stat().st_mtime for f in tex_files]
    body = body_file_for(unit_key)
    if body.exists():
        mtimes.append(body.stat().st_mtime)
    return datetime.fromtimestamp(max(mtimes), tz=timezone.utc)


# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------

def load_manifest():
    if MANIFEST_FILE.exists():
        with open(MANIFEST_FILE) as f:
            return json.load(f)
    return {}


def save_manifest(manifest):
    with open(MANIFEST_FILE, "w") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
        f.write("\n")


# ---------------------------------------------------------------------------
# Google Drive auth
# ---------------------------------------------------------------------------

def drive_auth():
    token_file = os.environ.get("GOOGLE_API_TOKEN_PICKLE_FILE", str(REPO_ROOT / "token.pickle"))
    creds_file = os.environ.get("GOOGLE_API_CREDENTIALS_FILE", str(REPO_ROOT / "credentials.json"))

    creds = None
    if os.path.exists(token_file):
        with open(token_file, "rb") as f:
            creds = pickle.load(f)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(creds_file, DRIVE_SCOPES)
            creds = flow.run_local_server()
        with open(token_file, "wb") as f:
            pickle.dump(creds, f)

    return build("drive", "v3", credentials=creds)


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

def setup_latex():
    """Ensure the custom LaTeX class is linked into ~/Library/texmf."""
    tex_link = TEXML_HOME / "tex"
    if not tex_link.exists():
        TEXML_HOME.mkdir(parents=True, exist_ok=True)
        tex_link.symlink_to(REPO_ROOT / "tex")


def build_pdf(tex_file):
    """Compile a .tex file with pdflatex. Returns path to the output PDF.

    Runs pdflatex twice: the first pass generates the .aux file, the second
    pass uses it (required by the leadsheets package).
    """
    artist_dir = tex_file.parent.name
    out_dir = BUILD_DIR / artist_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    env["TEXINPUTS"] = f"{tex_file.parent}:"

    cmd = ["pdflatex", "-interaction=nonstopmode", "-output-directory", str(out_dir), str(tex_file)]

    for _ in (1, 2):
        result = subprocess.run(cmd, env=env, cwd=str(REPO_ROOT), capture_output=True)

    pdf = out_dir / (tex_file.stem + ".pdf")
    if not pdf.exists():
        raise RuntimeError(
            f"pdflatex failed for {tex_file.name}:\n{result.stderr.decode()}\n"
            + result.stdout.decode()[-2000:]
        )
    return pdf


# ---------------------------------------------------------------------------
# PDF merge + Drive upload
# ---------------------------------------------------------------------------

def merge_pdfs(pdf_paths, output_path):
    writer = PdfWriter()
    for p in pdf_paths:
        writer.append(str(p))
    with open(output_path, "wb") as f:
        writer.write(f)


DRIVE_FILENAME_RE = re.compile(r"^(.*?)\s+[-\u2010]\s+(.*?)\s+\((\d{4})\)(?:\s+\[([^\]]+)\])?\.pdf$")

KEY_IN_TITLE_RE = re.compile(r"\s*\(([A-G][#b]?m?)\)$")


def parse_drive_filename(name):
    """Parse '<title> - <artist> (year) [key].pdf'.

    The [key] part is optional.
    Returns (title, artist, year, key) or None. key may be None.
    """
    m = DRIVE_FILENAME_RE.match(name)
    if not m:
        return None
    return m.group(1), m.group(2), m.group(3), m.group(4)


def extract_title_key(unit_title):
    """Split a unit title like 'Borderline (E)' into ('Borderline', 'E').

    Returns (base_title, key) where key may be None.
    """
    m = KEY_IN_TITLE_RE.search(unit_title)
    if m:
        base = unit_title[:m.start()].strip()
        return base, m.group(1)
    return unit_title, None


def list_drive_files(service):
    """List all PDF files in the Drive folder.

    Returns list of dicts with keys: id, name, title, artist, year, key.
    Files that don't match the expected naming convention are included
    with title/artist/year/key set to None.
    """
    files = []
    page_token = None
    while True:
        kwargs = dict(
            q=f"'{DRIVE_FOLDER_ID}' in parents and mimeType='application/pdf' and trashed=false",
            fields="nextPageToken, files(id, name)",
            pageSize=1000,
        )
        if page_token:
            kwargs["pageToken"] = page_token
        result = service.files().list(**kwargs).execute()
        for f in result.get("files", []):
            parsed = parse_drive_filename(f["name"])
            if parsed:
                title, artist, year, key = parsed
            else:
                title = artist = year = key = None
            files.append({"id": f["id"], "name": f["name"],
                          "title": title, "artist": artist, "year": year, "key": key})
        page_token = result.get("nextPageToken")
        if not page_token:
            break
    return files


TEX_YEAR_RE = re.compile(r"year=\{(\d{4})\}")
TEX_TITLE_RE = re.compile(r"title=\{([^}]+)\}")
TEX_BAND_RE = re.compile(r"band=\{([^}]+)\}")


def read_metadata_from_tex(tex_file):
    """Extract title, band, and year from a .tex file's song metadata.

    Returns (title, band, year) where any may be None if not found.
    """
    try:
        content = tex_file.read_text(encoding="utf-8")
        title_m = TEX_TITLE_RE.search(content)
        band_m = TEX_BAND_RE.search(content)
        year_m = TEX_YEAR_RE.search(content)
        def unescape(s):
            return s.replace(r"\&", "&") if s else s

        return (
            unescape(title_m.group(1)) if title_m else None,
            unescape(band_m.group(1)) if band_m else None,
            year_m.group(1) if year_m else None,
        )
    except OSError:
        return None, None, None


def drive_filename(unit_key, year, title=None, artist=None):
    """Build the Drive filename: '<title> - <artist> (year) [key].pdf'

    title and artist default to values derived from unit_key if not provided.
    The [key] suffix is included only when the unit title has a key variant.
    E.g. 'Madonna/Borderline (E)' -> 'Borderline - Madonna (1983) [E].pdf'
         'Madonna/Borderline'     -> 'Borderline - Madonna (1983).pdf'
    """
    unit_artist, unit_title = unit_key.split("/", 1)
    base_title, key = extract_title_key(unit_title)
    effective_title = title if title is not None else base_title
    effective_artist = artist if artist is not None else unit_artist
    if key:
        return f"{effective_title} - {effective_artist} ({year}) [{key}].pdf"
    return f"{effective_title} - {effective_artist} ({year}).pdf"


def upload_to_drive(service, pdf_path, unit_key, year, existing_uuid=None, title=None, artist=None):
    """Upload PDF to Drive. Returns the gd:xxx UUID."""
    filename = drive_filename(unit_key, year, title=title, artist=artist)
    media = MediaFileUpload(str(pdf_path), mimetype="application/pdf")

    if existing_uuid:
        from googleapiclient.errors import HttpError
        file_id = existing_uuid.removeprefix("gd:")
        try:
            service.files().update(
                fileId=file_id, body={"name": filename}, media_body=media
            ).execute()
            print(f"  Updated existing file {existing_uuid}")
            return existing_uuid
        except HttpError as e:
            if e.resp.status == 404:
                print(f"  Existing file {existing_uuid} not found in Drive, creating new...")
            else:
                raise

    metadata = {"name": filename, "parents": [DRIVE_FOLDER_ID]}
    result = service.files().create(
        body=metadata, media_body=media, fields="id"
    ).execute()
    uuid = "gd:" + result["id"]
    print(f"  Created new file {uuid}")
    return uuid


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_status(args):
    units = get_upload_units()
    manifest = load_manifest()

    missing, stale, ok = [], [], []

    for unit_key, tex_files in sorted(units.items()):
        entry = manifest.get(unit_key)
        if entry is None:
            missing.append(unit_key)
        else:
            uploaded_at = datetime.fromisoformat(entry["uploaded_at"])
            mtime = latest_mtime(unit_key, tex_files)
            if mtime > uploaded_at:
                stale.append((unit_key, mtime, uploaded_at))
            else:
                ok.append(unit_key)

    if missing:
        print(f"\n=== Not uploaded ({len(missing)}) ===")
        for u in missing:
            print(f"  {u}")

    if stale:
        print(f"\n=== Stale ({len(stale)}) ===")
        for u, mtime, uploaded in stale:
            print(f"  {u}  (modified {mtime:%Y-%m-%d}, uploaded {uploaded:%Y-%m-%d})")

    if not missing and not stale:
        print("All songs are up to date.")

    print(
        f"\nSummary: {len(missing)} not uploaded, {len(stale)} stale, {len(ok)} up to date"
        f" ({len(units)} total)"
    )


def upload_unit(unit_key, tex_files, manifest, service):
    """Build, merge, and upload a single unit. Updates manifest in place."""
    existing_uuid = manifest.get(unit_key, {}).get("uuid")

    title, band, year = read_metadata_from_tex(tex_files[0])
    if not year:
        raise RuntimeError(f"Could not read year from {tex_files[0].name}")
    if not title:
        raise RuntimeError(f"Could not read title from {tex_files[0].name}")
    if not band:
        raise RuntimeError(f"Could not read band from {tex_files[0].name}")

    print(f"Building: {unit_key}")
    print(f"  Drive filename: {drive_filename(unit_key, year, title=title, artist=band)}")

    pdf_paths = []
    for tex_file in tex_files:
        print(f"  pdflatex {tex_file.name} ...")
        pdf_paths.append(build_pdf(tex_file))

    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
        merged_path = tmp.name

    try:
        if len(pdf_paths) == 1:
            shutil.copy(pdf_paths[0], merged_path)
        else:
            print(f"  Merging {len(pdf_paths)} PDFs ...")
            merge_pdfs(pdf_paths, merged_path)

        print("  Uploading to Drive ...")
        uuid = upload_to_drive(service, merged_path, unit_key, year, existing_uuid,
                               title=title, artist=band)
    finally:
        os.unlink(merged_path)

    manifest[unit_key] = {
        "uuid": uuid,
        "uploaded_at": datetime.now(timezone.utc).isoformat(),
    }
    print(f"Done. {unit_key} → {uuid}")


def cmd_upload(args):
    units = get_upload_units()
    unit_key = args.unit

    if unit_key not in units:
        matches = [k for k in sorted(units) if args.unit.lower() in k.lower()]
        if matches:
            print(f"No exact match for '{unit_key}'. Did you mean:")
            for m in matches[:10]:
                print(f"  {m}")
        else:
            print(f"No unit found matching '{unit_key}'.")
        return

    setup_latex()
    manifest = load_manifest()
    service = drive_auth()
    upload_unit(unit_key, units[unit_key], manifest, service)
    save_manifest(manifest)


def cmd_upload_all(args):
    """Upload all units that are missing from Drive or stale."""
    units = get_upload_units()
    manifest = load_manifest()

    to_upload = []
    for unit_key, tex_files in sorted(units.items()):
        entry = manifest.get(unit_key)
        if entry is None:
            to_upload.append((unit_key, tex_files, "missing"))
        else:
            uploaded_at = datetime.fromisoformat(entry["uploaded_at"])
            mtime = latest_mtime(unit_key, tex_files)
            if mtime > uploaded_at:
                to_upload.append((unit_key, tex_files, "stale"))

    if not to_upload:
        print("Nothing to upload.")
        return

    print(f"{len(to_upload)} units to upload.")
    setup_latex()
    service = drive_auth()

    failed = []
    for i, (unit_key, tex_files, reason) in enumerate(to_upload, 1):
        print(f"\n[{i}/{len(to_upload)}] ({reason})")
        try:
            upload_unit(unit_key, tex_files, manifest, service)
            save_manifest(manifest)
        except Exception as e:
            print(f"  ERROR: {e}")
            failed.append((unit_key, str(e)))

    print(f"\nDone. {len(to_upload) - len(failed)} uploaded, {len(failed)} failed.")
    if failed:
        print("\nFailed:")
        for unit_key, err in failed:
            print(f"  {unit_key}: {err}")


def cmd_match(args):
    """Match upload units to existing Drive files and populate manifest.json."""
    units = get_upload_units()
    manifest = load_manifest()

    print("Fetching file list from Google Drive...")
    service = drive_auth()
    drive_files = list_drive_files(service)

    def normalize(s):
        return s.lower().strip() if s else ""

    # Build lookup: (norm_title, norm_artist, norm_key) -> drive file entry
    # key is None for files without a [key] suffix (stored as "")
    drive_by_key = {}
    unparseable = []
    for f in drive_files:
        if f["title"] is None:
            unparseable.append(f)
        else:
            k = (normalize(f["title"]), normalize(f["artist"]), normalize(f["key"] or ""))
            drive_by_key[k] = f

    # Build set of Drive file IDs that actually exist
    drive_ids = {f["id"] for f in drive_files}

    # Check existing manifest entries — flag any whose Drive file is gone
    stale_manifest = []
    for unit_key, entry in list(manifest.items()):
        file_id = entry.get("uuid", "").removeprefix("gd:")
        if file_id and file_id not in drive_ids:
            stale_manifest.append(unit_key)
            del manifest[unit_key]

    matched = []
    already_matched = []
    unmatched_units = []

    for unit_key, tex_files in sorted(units.items()):
        if unit_key in manifest:
            already_matched.append(unit_key)
            continue

        # Key variant (e.g. "E" from "Borderline (E)") still comes from unit title
        _, unit_title = unit_key.split("/", 1)
        _, key = extract_title_key(unit_title)

        # Title and artist come from tex file contents for accurate matching
        title, band, _ = read_metadata_from_tex(tex_files[0])
        if not title or not band:
            # Fall back to filename-derived values
            unit_artist, unit_title2 = unit_key.split("/", 1)
            title, _ = extract_title_key(unit_title2)
            band = unit_artist

        k = (normalize(title), normalize(band), normalize(key or ""))

        if k in drive_by_key:
            f = drive_by_key[k]
            uuid = "gd:" + f["id"]
            manifest[unit_key] = {
                "uuid": uuid,
                "uploaded_at": datetime.now(timezone.utc).isoformat(),
            }
            matched.append((unit_key, uuid))
        else:
            unmatched_units.append(unit_key)

    if stale_manifest:
        print(f"\n=== Manifest entries with missing Drive file ({len(stale_manifest)}) ===")
        for u in stale_manifest:
            print(f"  {u}  (removed from manifest)")

    if matched:
        print(f"\n=== Matched ({len(matched)}) ===")
        for unit_key, uuid in matched:
            print(f"  {unit_key} → {uuid}")

    if unmatched_units:
        print(f"\n=== No Drive file found ({len(unmatched_units)}) ===")
        for u in unmatched_units:
            print(f"  {u}")

    if unparseable:
        print(f"\n=== Drive files with unexpected filename format ({len(unparseable)}) ===")
        for f in unparseable:
            print(f"  {f['name']}")

    if stale_manifest or matched:
        save_manifest(manifest)

    print(
        f"\nSummary: {len(matched)} newly matched, {len(already_matched)} already in manifest,"
        f" {len(stale_manifest)} stale manifest entries removed,"
        f" {len(unmatched_units)} unmatched units"
    )


def cmd_rename(args):
    """Rename Drive files that embed the key in the title to use [key] suffix.

    Old format: 'Borderline (E) - Madonna (1983).pdf'
    New format: 'Borderline - Madonna (1983) [E].pdf'

    Only renames files where the title contains a key variant like '(E)'.
    Use --dry-run to preview without making changes.
    """
    print("Fetching file list from Google Drive...")
    service = drive_auth()
    drive_files = list_drive_files(service)

    to_rename = []
    for f in drive_files:
        if f["title"] is None:
            continue
        # Check if title contains a key variant like '(E)' or '(Bb)'
        base_title, key = extract_title_key(f["title"])
        if not key:
            continue
        # Build what the new name should be
        new_name = f"{base_title} - {f['artist']} ({f['year']}) [{key}].pdf"
        if new_name != f["name"]:
            to_rename.append((f, new_name))

    if not to_rename:
        print("No files need renaming.")
        return

    print(f"\n=== Files to rename ({len(to_rename)}) ===")
    for f, new_name in to_rename:
        print(f"  {f['name']}")
        print(f"    → {new_name}")

    if args.dry_run:
        print(f"\nDry run: {len(to_rename)} files would be renamed.")
        return

    print()
    renamed = 0
    for f, new_name in to_rename:
        service.files().update(fileId=f["id"], body={"name": new_name}).execute()
        print(f"  Renamed: {new_name}")
        renamed += 1

    print(f"\nDone. Renamed {renamed} files.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Manage song uploads to Google Drive"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("status", help="Show upload status of all songs")
    sub.add_parser("match", help="Match .tex files to existing Drive files and populate manifest")

    up = sub.add_parser("upload", help="Build and upload a song group")
    up.add_argument("unit", help='Upload unit, e.g. "Madonna/Borderline (E)"')

    sub.add_parser("upload-all", help="Build and upload all missing or stale units")

    rn = sub.add_parser("rename", help="Rename Drive files: move key from title to [key] suffix")
    rn.add_argument("--dry-run", action="store_true", help="Preview changes without renaming")

    args = parser.parse_args()

    if args.command == "status":
        cmd_status(args)
    elif args.command == "match":
        cmd_match(args)
    elif args.command == "upload":
        cmd_upload(args)
    elif args.command == "upload-all":
        cmd_upload_all(args)
    elif args.command == "rename":
        cmd_rename(args)


if __name__ == "__main__":
    main()
