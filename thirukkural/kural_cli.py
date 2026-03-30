#!/usr/bin/env python3
"""CLI for fetching a Thirukkural by number.

By default this tries to render in a PyQt window so Tamil text is displayed
using GUI fonts instead of terminal fonts.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="kural",
        description="Print a Thirukkural by number (1-1330).",
    )
    parser.add_argument("number", type=int, help="Kural number (1-1330)")
    parser.add_argument(
        "--text",
        action="store_true",
        help="Force terminal output instead of PyQt rendering.",
    )
    return parser.parse_args()


def load_kurals(json_path: Path) -> list[dict]:
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"Error: data file not found: {json_path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Error: invalid JSON in {json_path}: {exc}", file=sys.stderr)
        sys.exit(1)

    kurals = data.get("kural")
    if not isinstance(kurals, list):
        print("Error: unexpected JSON format in thirukkural.json", file=sys.stderr)
        sys.exit(1)

    return kurals


def find_kural(kurals: list[dict], number: int) -> dict | None:
    for item in kurals:
        if item.get("Number") == number:
            return item
    return None


def format_kural(entry: dict) -> str:
    lines: list[str] = [
        f"Kural {entry.get('Number')}",
        "",
        entry.get("Line1", ""),
        entry.get("Line2", ""),
    ]

    translation = entry.get("Translation")
    if translation:
        lines.extend(["", f"Translation: {translation}"])

    explanation = entry.get("explanation")
    if explanation:
        lines.append(f"Explanation: {explanation}")

    return "\n".join(lines)


def print_text(entry: dict) -> None:
    print(format_kural(entry))


def can_use_gui() -> bool:
    # Linux uses DISPLAY/Wayland for GUI sessions. Skip GUI in headless shells.
    return bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))


def render_with_pyqt(entry: dict) -> bool:
    try:
        from PyQt5.QtCore import Qt
        from PyQt5.QtGui import QFont
        from PyQt5.QtWidgets import QApplication, QLabel, QVBoxLayout, QWidget
        qt_major = 5
    except Exception:
        try:
            from PyQt6.QtCore import Qt
            from PyQt6.QtGui import QFont
            from PyQt6.QtWidgets import QApplication, QLabel, QVBoxLayout, QWidget
            qt_major = 6
        except Exception:
            return False

    class KuralWidget(QWidget):
        def __init__(self, kural_entry: dict) -> None:
            super().__init__()

            def _qt_flag(name: str):
                if hasattr(Qt, "WindowType"):
                    return getattr(Qt.WindowType, name)
                return getattr(Qt, name)

            # Frameless floating card similar to the provided example.
            self.setWindowFlags(
                _qt_flag("FramelessWindowHint")
                | _qt_flag("WindowStaysOnTopHint")
                | _qt_flag("Tool")
            )

            if qt_major == 5:
                self.setAttribute(Qt.WA_TranslucentBackground)
            else:
                self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

            layout = QVBoxLayout()
            layout.setContentsMargins(18, 18, 18, 18)
            layout.setSpacing(8)

            title = QLabel(f"Kural {kural_entry.get('Number')}")
            title.setFont(QFont("Inter", 10))
            title.setStyleSheet("color: rgba(255,255,255,180);")

            kural_text = QLabel(
                f"{kural_entry.get('Line1', '')}\n{kural_entry.get('Line2', '')}"
            )
            tamil_font = QFont("Noto Sans Tamil", 20)
            if tamil_font.family() == "":
                tamil_font = QFont("Noto Serif Tamil", 20)
            kural_text.setFont(tamil_font)
            kural_text.setWordWrap(True)
            kural_text.setStyleSheet("color: white; margin-top: 4px;")

            translation_value = kural_entry.get("Translation", "")
            translation = QLabel(translation_value)
            translation.setFont(QFont("Inter", 11))
            translation.setWordWrap(True)
            translation.setStyleSheet(
                "color: rgba(255,255,255,210); margin-top: 10px;"
            )

            explanation_value = kural_entry.get("explanation", "")
            explanation = QLabel(explanation_value)
            explanation.setFont(QFont("Inter", 10))
            explanation.setWordWrap(True)
            explanation.setStyleSheet("color: rgba(255,255,255,170); margin-top: 6px;")

            layout.addWidget(title)
            layout.addWidget(kural_text)
            if translation_value:
                layout.addWidget(translation)
            if explanation_value:
                layout.addWidget(explanation)

            self.setLayout(layout)
            self.setStyleSheet(
                """
                QWidget {
                    background-color: rgba(20, 20, 20, 185);
                    border: 1px solid rgba(255,255,255,24);
                    border-radius: 16px;
                }
                """
            )

            self.resize(520, 280)
            self.move(100, 100)
            self._old_pos = None

        def mousePressEvent(self, event):
            if qt_major == 5:
                self._old_pos = event.globalPos()
            else:
                self._old_pos = event.globalPosition().toPoint()

        def mouseMoveEvent(self, event):
            if self._old_pos is None:
                return

            if qt_major == 5:
                current = event.globalPos()
            else:
                current = event.globalPosition().toPoint()

            delta = current - self._old_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self._old_pos = current

    app = QApplication(sys.argv)
    widget = KuralWidget(entry)
    widget.show()
    app.exec()
    return True


def main() -> None:
    args = parse_args()
    number = args.number

    if number < 1 or number > 1330:
        print("Error: number must be between 1 and 1330.", file=sys.stderr)
        sys.exit(1)

    json_path = Path(__file__).with_name("thirukkural.json")
    kurals = load_kurals(json_path)
    entry = find_kural(kurals, number)

    if entry is None:
        print(f"Kural {number} not found.", file=sys.stderr)
        sys.exit(1)

    if args.text:
        print_text(entry)
        return

    if can_use_gui():
        if render_with_pyqt(entry):
            return

        print(
            "PyQt rendering unavailable. Install with: pip install PyQt5 or pip install PyQt6",
            file=sys.stderr,
        )
        print(
            "For best Tamil display install a Tamil font like 'Noto Sans Tamil'.",
            file=sys.stderr,
        )

    print_text(entry)


if __name__ == "__main__":
    main()
