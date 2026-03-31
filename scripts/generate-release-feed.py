#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from email.utils import format_datetime
from pathlib import Path
from urllib.parse import quote
from xml.etree import ElementTree as ET


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


@dataclass
class ArchiveMetadata:
    filename: str
    url: str
    size: int
    sha256: str
    sparkle_ed_signature: str | None


@dataclass
class ReleaseNotesMetadata:
    filename: str
    url: str
    size: int
    sha256: str
    sparkle_ed_signature: str | None


@dataclass
class ReleaseMetadata:
    app_name: str
    bundle_identifier: str
    version: str
    build: str
    minimum_system_version: str
    published_at: str
    appcast_url: str
    archive: ArchiveMetadata
    release_notes: ReleaseNotesMetadata | None
    release_notes_url: str | None
    appcast_signature_embedded: bool


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_archive_url(base_url: str, filename: str) -> str:
    return base_url.rstrip("/") + "/" + quote(filename)


def build_metadata(args: argparse.Namespace) -> ReleaseMetadata:
    archive_path = Path(args.archive).resolve()
    archive = ArchiveMetadata(
        filename=archive_path.name,
        url=build_archive_url(args.download_base_url, archive_path.name),
        size=archive_path.stat().st_size,
        sha256=sha256(archive_path),
        sparkle_ed_signature=args.ed_signature,
    )
    release_notes = None
    if args.release_notes_file and args.release_notes_url:
        release_notes_path = Path(args.release_notes_file).resolve()
        release_notes = ReleaseNotesMetadata(
            filename=release_notes_path.name,
            url=args.release_notes_url,
            size=release_notes_path.stat().st_size,
            sha256=sha256(release_notes_path),
            sparkle_ed_signature=args.release_notes_ed_signature,
        )
    return ReleaseMetadata(
        app_name=args.app_name,
        bundle_identifier=args.bundle_id,
        version=args.version,
        build=args.build,
        minimum_system_version=args.minimum_system,
        published_at=args.published_at
        or datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        appcast_url=args.appcast_url,
        archive=archive,
        release_notes=release_notes,
        release_notes_url=args.release_notes_url,
        appcast_signature_embedded=args.appcast_signature_embedded,
    )


def write_metadata(path: Path, metadata: ReleaseMetadata) -> None:
    path.write_text(json.dumps(asdict(metadata), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def write_appcast(path: Path, metadata: ReleaseMetadata) -> None:
    rss = ET.Element("rss", {"version": "2.0"})
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = f"{metadata.app_name} Updates"
    ET.SubElement(channel, "link").text = metadata.appcast_url
    ET.SubElement(channel, "description").text = f"Updates for {metadata.app_name}"
    ET.SubElement(channel, "language").text = "en"
    item = ET.SubElement(channel, "item")
    ET.SubElement(item, "title").text = f"Version {metadata.version}"
    published_at = datetime.fromisoformat(metadata.published_at.replace("Z", "+00:00"))
    ET.SubElement(item, "pubDate").text = format_datetime(published_at)
    ET.SubElement(item, f"{{{SPARKLE_NS}}}version").text = metadata.build
    ET.SubElement(item, f"{{{SPARKLE_NS}}}shortVersionString").text = metadata.version
    ET.SubElement(item, f"{{{SPARKLE_NS}}}minimumSystemVersion").text = metadata.minimum_system_version
    if metadata.release_notes_url:
        release_notes_attributes = {}
        if metadata.release_notes and metadata.release_notes.sparkle_ed_signature:
            release_notes_attributes[f"{{{SPARKLE_NS}}}edSignature"] = metadata.release_notes.sparkle_ed_signature
            release_notes_attributes["length"] = str(metadata.release_notes.size)
        release_notes_element = ET.SubElement(item, f"{{{SPARKLE_NS}}}releaseNotesLink", release_notes_attributes)
        release_notes_element.text = metadata.release_notes_url
    enclosure_attributes = {
        "url": metadata.archive.url,
        "length": str(metadata.archive.size),
        "type": "application/octet-stream",
    }
    if metadata.archive.sparkle_ed_signature:
        enclosure_attributes[f"{{{SPARKLE_NS}}}edSignature"] = metadata.archive.sparkle_ed_signature
    ET.SubElement(item, "enclosure", enclosure_attributes)
    tree = ET.ElementTree(rss)
    ET.indent(tree, space="  ")
    tree.write(path, encoding="utf-8", xml_declaration=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Sparkle-ready release metadata and appcast files")
    parser.add_argument("--archive", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--download-base-url", required=True)
    parser.add_argument("--appcast-url", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--app-name", default="Codex Lobster Island")
    parser.add_argument("--bundle-id", default="com.codex.lobsterisland")
    parser.add_argument("--minimum-system", default="14.0")
    parser.add_argument("--release-notes-url")
    parser.add_argument("--release-notes-file")
    parser.add_argument("--release-notes-ed-signature")
    parser.add_argument("--published-at")
    parser.add_argument("--ed-signature")
    parser.add_argument("--appcast-signature-embedded", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    archive_path = Path(args.archive)
    if not archive_path.is_file():
        raise SystemExit(f"Archive not found: {archive_path}")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    metadata = build_metadata(args)
    write_metadata(output_dir / "release-metadata.json", metadata)
    write_appcast(output_dir / "appcast.xml", metadata)


if __name__ == "__main__":
    main()
