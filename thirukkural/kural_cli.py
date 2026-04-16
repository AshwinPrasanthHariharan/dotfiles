#!/usr/bin/env python3

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


def _load_json(path: Path) -> Any:
	try:
		with path.open("r", encoding="utf-8") as f:
			return json.load(f)
	except FileNotFoundError:
		print(f"Error: data file not found: {path}", file=sys.stderr)
		sys.exit(1)
	except json.JSONDecodeError as exc:
		print(f"Error: invalid JSON in {path}: {exc}", file=sys.stderr)
		sys.exit(1)


def _find_kural(kural_items: List[Dict[str, Any]], number: int) -> Optional[Dict[str, Any]]:
	for item in kural_items:
		if item.get("Number") == number:
			return item
	return None


def _find_kural_details(detail_data: List[Dict[str, Any]], number: int) -> Optional[Dict[str, Any]]:
	for root in detail_data:
		section = root.get("section", {})
		for paal in section.get("detail", []):
			chapter_group = paal.get("chapterGroup", {})
			for iyal in chapter_group.get("detail", []):
				for chapter in iyal.get("chapters", {}).get("detail", []):
					start = chapter.get("start")
					end = chapter.get("end")
					if isinstance(start, int) and isinstance(end, int) and start <= number <= end:
						return {
							"book_tamil": root.get("tamil"),
							"paal_name": paal.get("name"),
							"paal_translation": paal.get("translation"),
							"iyal_name": iyal.get("name"),
							"iyal_translation": iyal.get("translation"),
							"chapter_name": chapter.get("name"),
							"chapter_translation": chapter.get("translation"),
							"chapter_number": chapter.get("number"),
							"range_start": start,
							"range_end": end,
						}
	return None


def _print_kural(number: int, kural: Dict[str, Any], details: Optional[Dict[str, Any]]) -> None:
	print(f"Kural {number}")
	print("-" * 40)
	print(kural.get("Line1", ""))
	print(kural.get("Line2", ""))
	print()

	if kural.get("Translation"):
		print(f"Translation: {kural['Translation']}")
	if kural.get("transliteration1") or kural.get("transliteration2"):
		print("Transliteration:")
		if kural.get("transliteration1"):
			print(f"  {kural['transliteration1']}")
		if kural.get("transliteration2"):
			print(f"  {kural['transliteration2']}")

	if details:
		print()
		print("Details")
		print("-" * 40)
		print(f"Book: {details.get('book_tamil', '')}")
		print(
			f"Paal: {details.get('paal_name', '')}"
			f" ({details.get('paal_translation', '')})"
		)
		print(
			f"Iyal: {details.get('iyal_name', '')}"
			f" ({details.get('iyal_translation', '')})"
		)
		print(
			f"Chapter {details.get('chapter_number', '')}: {details.get('chapter_name', '')}"
			f" ({details.get('chapter_translation', '')})"
		)
		print(
			f"Chapter Kural Range: {details.get('range_start', '')}-"
			f"{details.get('range_end', '')}"
		)


def main() -> None:
	parser = argparse.ArgumentParser(
		description="Print a Thirukkural verse and metadata by Kural number."
	)
	parser.add_argument("number", type=int, help="Kural number (1-1330)")
	args = parser.parse_args()

	number = args.number
	if number < 1 or number > 1330:
		print("Error: kural number must be between 1 and 1330", file=sys.stderr)
		sys.exit(1)

	base_dir = Path(__file__).resolve().parent
	kural_data = _load_json(base_dir / "thirukkural.json")
	detail_data = _load_json(base_dir / "detail.json")

	kural_items = kural_data.get("kural", [])
	kural = _find_kural(kural_items, number)
	if not kural:
		print(f"Error: kural {number} not found", file=sys.stderr)
		sys.exit(1)

	details = _find_kural_details(detail_data, number)
	_print_kural(number, kural, details)


if __name__ == "__main__":
	main()
