#!/usr/bin/env python3
"""
Horoscope content library generator.

Calls the Anthropic Messages API to produce the bundled content pools used by
`HoroscopeContentLibrary` and `CosmicSignatureService` on the offline path:

  Devi/Resources/horoscope_library.json
    - houseThemes[house][30 variants]    → 360 themed daily readings
    - categoryReadings[house][category][30 variants]  → 1,440 category summaries

  Devi/Resources/cosmic_signature_library.json
    - tithiFragments[tithi][15]       → 450 fragments
    - nakshatraFragments[nakshatra][15] → 405 fragments
    - yogaFragments[yoga][15]          → 405 fragments

The generator is checkpointed: if a batch has already been produced, it is
skipped on re-run. Delete `scripts/_horoscope_checkpoint.json` to force a
full regeneration.

Usage
-----
  cd scripts
  source ../.venv/bin/activate
  pip install -r requirements.txt
  export ANTHROPIC_API_KEY=sk-...
  python3 generate_horoscope_content.py               # full run (~150 calls)
  python3 generate_horoscope_content.py --dry-run     # count batches, no API
  python3 generate_horoscope_content.py --only themes
  python3 generate_horoscope_content.py --only categories
  python3 generate_horoscope_content.py --only signatures
  python3 generate_horoscope_content.py --houses 1,5,12   # regenerate slots

Cost: ~150 calls × ~2-3K output tokens on `claude-sonnet-4-6` is a few USD.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# NOTE: The `anthropic` package is imported lazily inside `make_client()` so
# that `--dry-run` (which only plans batches) works on a bare interpreter
# without the API SDK installed.


# ── Paths ──────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
RESOURCES_DIR = REPO_ROOT / "Devi" / "Resources"
CHECKPOINT_PATH = SCRIPT_DIR / "_horoscope_checkpoint.json"
HOROSCOPE_OUTPUT = RESOURCES_DIR / "horoscope_library.json"
SIGNATURE_OUTPUT = RESOURCES_DIR / "cosmic_signature_library.json"


# ── Model Configuration ────────────────────────────────────────────────────

MODEL = "claude-sonnet-4-6"
LIBRARY_VERSION = 1
RATE_LIMIT_SLEEP = 0.3  # seconds between API calls to stay polite
MAX_TOKENS_PER_BATCH = 8192
TARGET_VARIANTS_PER_SLOT = 30
TARGET_FRAGMENTS_PER_SLOT = 15


# ── Reference Data (must match Devi/Models/HoroscopeContentLibrary.swift) ──

HOUSE_VEDIC_NAMES = {
    1:  ("Tanu Bhava",     "self, identity, physical body, appearance"),
    2:  ("Dhana Bhava",    "wealth, family, speech, food, values"),
    3:  ("Sahaja Bhava",   "siblings, courage, communication, short travel"),
    4:  ("Sukha Bhava",    "home, mother, comfort, inner peace"),
    5:  ("Putra Bhava",    "creativity, children, romance, intelligence"),
    6:  ("Shatru Bhava",   "service, health, obstacles, debts, enemies"),
    7:  ("Kalatra Bhava",  "marriage, partnerships, business relations"),
    8:  ("Ayur Bhava",     "transformation, secrets, occult, longevity"),
    9:  ("Dharma Bhava",   "fortune, higher learning, religion, long journeys"),
    10: ("Karma Bhava",    "career, reputation, public life, authority"),
    11: ("Labha Bhava",    "gains, friends, hopes, income, community"),
    12: ("Vyaya Bhava",    "losses, solitude, spirituality, foreign lands"),
}

CATEGORIES = ["love", "work", "spirituality", "health"]

TITHI_NAMES = (
    [f"Shukla {n}" for n in [
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
    ]]
    + [f"Krishna {n}" for n in [
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya",
    ]]
)

NAKSHATRA_NAMES = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
    "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
    "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
    "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
    "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
    "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
]

YOGA_NAMES = [
    "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana",
    "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda",
    "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
    "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
    "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
    "Indra", "Vaidhriti",
]


# ── Style Reference (excerpts of the hand-written voice) ───────────────────

STYLE_REFERENCE = """
Voice guidelines for all output:

- Second-person, present-tense ("Today you are…", "Step into…").
- Grounded Vedic flavor without being preachy. Reference planets, houses, or
  nakshatras when they add meaning, never as jargon.
- Short, flowing sentences. Avoid bullet points outside of doList/dontList.
- Tone is warm, reassuring, slightly poetic — think of a wise friend, not a
  fortune teller.
- No clichés ("the universe is aligning for you"), no empty hedging
  ("maybe…"), no crystal-ball phrasing ("tonight the stars say…").
- Length: theme statements ≤ 12 words. Supporting text ≤ 3 sentences, ~50 words.
  Category summaries ≤ 2 sentences, ~25 words. Do/Don't items ≤ 8 words each.
- Avoid repeating the exact phrasing of neighboring variants in the same pool.

Style examples (hand-written, do not copy verbatim):

Theme statement:
  "Today begins with you."
  "A steady, grounded day for quiet progress."
  "The pause before a new chapter — honor it."

Supporting text:
  "This is a day to honor what is already yours before reaching for what isn't.
   Small actions, done with full attention, matter more than grand plans. The
   world can wait while you remember who you are."

Category summary (love):
  "An honest word matters more than a grand gesture. Reach out first."

Do list item:
  "Write down three things you're grateful for"

Don't list item:
  "Force closure on what's still unfolding"
""".strip()


# ── Checkpoint Management ──────────────────────────────────────────────────

@dataclass
class Checkpoint:
    """On-disk record of which batches have already been generated."""
    themes: dict[str, list[dict]]          # "1".."12" → [variants]
    categories: dict[str, dict[str, list[dict]]]  # "1".."12" → category → [variants]
    tithi_fragments: dict[str, list[str]]
    nakshatra_fragments: dict[str, list[str]]
    yoga_fragments: dict[str, list[str]]

    @classmethod
    def load(cls) -> "Checkpoint":
        if not CHECKPOINT_PATH.exists():
            return cls({}, {}, {}, {}, {})
        raw = json.loads(CHECKPOINT_PATH.read_text())
        return cls(
            themes=raw.get("themes", {}),
            categories=raw.get("categories", {}),
            tithi_fragments=raw.get("tithi_fragments", {}),
            nakshatra_fragments=raw.get("nakshatra_fragments", {}),
            yoga_fragments=raw.get("yoga_fragments", {}),
        )

    def save(self) -> None:
        CHECKPOINT_PATH.write_text(json.dumps({
            "themes": self.themes,
            "categories": self.categories,
            "tithi_fragments": self.tithi_fragments,
            "nakshatra_fragments": self.nakshatra_fragments,
            "yoga_fragments": self.yoga_fragments,
        }, indent=2, ensure_ascii=False))


# ── Anthropic Client ───────────────────────────────────────────────────────

def make_client() -> Any:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    try:
        from anthropic import Anthropic
    except ImportError:
        print(
            "ERROR: anthropic package not installed. Run: pip install -r requirements.txt",
            file=sys.stderr,
        )
        sys.exit(1)
    return Anthropic(api_key=api_key)


def call_claude(client: Any, system: str, user: str) -> str:
    """Call the Messages API once with retry. Returns the text response."""
    for attempt in range(2):
        try:
            response = client.messages.create(
                model=MODEL,
                max_tokens=MAX_TOKENS_PER_BATCH,
                system=system,
                messages=[{"role": "user", "content": user}],
            )
            # Detect truncation before parsing
            if getattr(response, "stop_reason", None) == "max_tokens":
                raise RuntimeError(
                    f"Response truncated at {MAX_TOKENS_PER_BATCH} tokens — "
                    "increase MAX_TOKENS_PER_BATCH or reduce TARGET_VARIANTS_PER_SLOT"
                )
            # Concatenate text blocks
            text = "".join(
                block.text for block in response.content
                if getattr(block, "type", None) == "text"
            )
            return text
        except Exception as exc:  # noqa: BLE001 — broad catch is intentional for retry
            print(f"    API error (attempt {attempt + 1}/2): {exc}", file=sys.stderr)
            time.sleep(2)
    raise RuntimeError("API call failed after 2 attempts")


def _repair_json(text: str) -> str:
    """Attempt to fix common LLM JSON mistakes (missing commas, trailing commas)."""
    # Fix missing comma between adjacent strings: "..." "..."
    text = re.sub(r'"\s*\n\s*"', '",\n"', text)
    # Fix missing comma between } and {
    text = re.sub(r'\}\s*\n\s*\{', '},\n{', text)
    # Fix missing comma between } and "
    text = re.sub(r'\}\s*\n\s*"', '},\n"', text)
    # Fix missing comma between " and {
    text = re.sub(r'"\s*\n\s*\{', '",\n{', text)
    # Fix trailing commas before ] or }
    text = re.sub(r',\s*([}\]])', r'\1', text)
    return text


def extract_json(text: str) -> Any:
    """Pull the first JSON object/array out of a model response."""
    # Model often wraps JSON in a ```json fence; strip it.
    fenced = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1).strip()
    # Find the first { or [ and its matching close.
    start = None
    for i, ch in enumerate(text):
        if ch in "{[":
            start = i
            break
    if start is None:
        raise ValueError(f"No JSON found in response:\n{text[:500]}")
    # Use raw_decode to parse exactly one JSON value and ignore trailing text.
    decoder = json.JSONDecoder()
    try:
        obj, _ = decoder.raw_decode(text, start)
        return obj
    except json.JSONDecodeError:
        # Try repairing common LLM JSON mistakes before giving up.
        repaired = _repair_json(text)
        obj, _ = decoder.raw_decode(repaired, start)
        return obj


# ── Prompt Builders ────────────────────────────────────────────────────────

SYSTEM_PROMPT = (
    "You are a meticulous Vedic astrologer and content writer producing daily "
    "horoscope copy for a meditation app. Output ONLY valid JSON matching the "
    "requested schema. No prose, no commentary, no markdown fences outside the JSON block.\n\n"
    + STYLE_REFERENCE
)


def build_themes_prompt(house: int) -> str:
    vedic_name, themes = HOUSE_VEDIC_NAMES[house]
    return f"""Generate {TARGET_VARIANTS_PER_SLOT} unique daily horoscope theme variants for a user whose transit Moon is in their {house}{_ordinal_suffix(house)} house from their birth Moon.

House context:
- Vedic name: {vedic_name}
- Themes: {themes}

For each variant, produce an object with these exact keys:
  "themeStatement"  (≤12 words, evocative, not cliché)
  "supportingText"  (2-3 sentences, ~50 words, second-person present)
  "doList"          (array of exactly 3 short actionable items, ≤8 words each)
  "dontList"        (array of exactly 3 short warnings/avoidances, ≤8 words each)

Return STRICT JSON of the form:
{{"variants": [ {{ ... }}, {{ ... }}, ... ]}}

with exactly {TARGET_VARIANTS_PER_SLOT} entries in the variants array. No trailing commas, no markdown fences, no commentary."""


def build_category_prompt(house: int, category: str) -> str:
    vedic_name, themes = HOUSE_VEDIC_NAMES[house]
    category_lens = {
        "love":         "romantic relationships, emotional connection, self-love",
        "work":         "career, productivity, professional responsibilities",
        "spirituality": "inner practice, meditation, meaning, mantra, surrender",
        "health":       "body, energy, rest, movement, nourishment",
    }
    return f"""Generate {TARGET_VARIANTS_PER_SLOT} unique daily category readings for the '{category}' life domain when the transit Moon is in the {house}{_ordinal_suffix(house)} house.

House: {vedic_name} ({themes})
Category lens: {category_lens[category]}

For each variant, produce an object with these exact keys:
  "summary"   (1-2 sentences, ~25 words, second-person present tense)
  "intensity" (integer 1-5; 1 = muted/low-stakes, 5 = sharp/significant)

Return STRICT JSON of the form:
{{"variants": [ {{ "summary": "...", "intensity": 3 }}, ... ]}}

with exactly {TARGET_VARIANTS_PER_SLOT} entries in the variants array. No trailing commas, no markdown fences, no commentary."""


def build_tithi_fragment_prompt(tithi: str) -> str:
    return f"""Generate {TARGET_FRAGMENTS_PER_SLOT} unique sentence fragments describing the spiritual significance of the {tithi} tithi.

Each fragment is ONE sentence that will be combined with a nakshatra fragment and a yoga fragment to form a "cosmic signature" paragraph. It must read naturally in that position — it should NOT begin with a transition word like "Meanwhile" or "Additionally".

Requirements:
- Reference the tithi name or its ruling deity naturally.
- ≤ 28 words per fragment.
- Varied openings — do not start every fragment the same way.
- No numbered/bulleted prefixes.
- Second- or third-person, present tense.
- No sales-y language ("today is perfect for…"), no clichés ("the stars are aligned").

Return STRICT JSON of the form:
{{"fragments": ["...", "...", ...]}}

with exactly {TARGET_FRAGMENTS_PER_SLOT} strings in the fragments array. No trailing commas, no markdown fences, no commentary."""


def build_nakshatra_fragment_prompt(nakshatra: str) -> str:
    return f"""Generate {TARGET_FRAGMENTS_PER_SLOT} unique sentence fragments describing the energy of the {nakshatra} nakshatra.

Each fragment is ONE sentence that will be combined with a tithi fragment and a yoga fragment to form a "cosmic signature" paragraph. It must read naturally as a middle or closing sentence in a short paragraph.

Requirements:
- Reference the nakshatra name or its presiding deity naturally.
- ≤ 28 words per fragment.
- Varied openings — do not repeat sentence starts.
- Second- or third-person, present tense.
- Concrete imagery over abstract "energy flows" phrasing.

Return STRICT JSON:
{{"fragments": ["...", "...", ...]}}

Exactly {TARGET_FRAGMENTS_PER_SLOT} strings. No trailing commas, no markdown fences, no commentary."""


def build_yoga_fragment_prompt(yoga: str) -> str:
    return f"""Generate {TARGET_FRAGMENTS_PER_SLOT} unique sentence fragments describing the quality of the {yoga} yoga.

Each fragment is ONE sentence that will be combined with a tithi fragment and a nakshatra fragment to form a "cosmic signature" paragraph. It must read naturally as a middle or closing sentence.

Requirements:
- Reference the yoga name or its traditional quality.
- ≤ 28 words per fragment.
- Varied openings.
- Second- or third-person, present tense.

Return STRICT JSON:
{{"fragments": ["...", "...", ...]}}

Exactly {TARGET_FRAGMENTS_PER_SLOT} strings. No trailing commas, no markdown fences, no commentary."""


def _ordinal_suffix(n: int) -> str:
    if n == 1:
        return "st"
    if n == 2:
        return "nd"
    if n == 3:
        return "rd"
    return "th"


# ── Validators ─────────────────────────────────────────────────────────────

def validate_theme_variants(data: Any) -> list[dict]:
    if not isinstance(data, dict) or "variants" not in data:
        raise ValueError("expected {'variants': [...]}")
    variants = data["variants"]
    if not isinstance(variants, list) or len(variants) < TARGET_VARIANTS_PER_SLOT:
        raise ValueError(f"expected {TARGET_VARIANTS_PER_SLOT}+ variants, got {len(variants) if isinstance(variants, list) else 'non-list'}")
    for i, v in enumerate(variants[:TARGET_VARIANTS_PER_SLOT]):
        for key in ("themeStatement", "supportingText", "doList", "dontList"):
            if key not in v:
                raise ValueError(f"variant {i} missing key '{key}'")
        if not isinstance(v["doList"], list) or len(v["doList"]) != 3:
            raise ValueError(f"variant {i} doList must have exactly 3 items")
        if not isinstance(v["dontList"], list) or len(v["dontList"]) != 3:
            raise ValueError(f"variant {i} dontList must have exactly 3 items")
    return variants[:TARGET_VARIANTS_PER_SLOT]


def validate_category_variants(data: Any) -> list[dict]:
    if not isinstance(data, dict) or "variants" not in data:
        raise ValueError("expected {'variants': [...]}")
    variants = data["variants"]
    if not isinstance(variants, list) or len(variants) < TARGET_VARIANTS_PER_SLOT:
        raise ValueError(f"expected {TARGET_VARIANTS_PER_SLOT}+ variants, got {len(variants) if isinstance(variants, list) else 'non-list'}")
    normalized = []
    for i, v in enumerate(variants[:TARGET_VARIANTS_PER_SLOT]):
        if "summary" not in v:
            raise ValueError(f"category variant {i} missing 'summary'")
        intensity = v.get("intensity", 3)
        if not isinstance(intensity, int):
            intensity = int(intensity)
        intensity = max(1, min(5, intensity))
        normalized.append({"summary": v["summary"], "intensity": intensity})
    return normalized


def validate_fragments(data: Any) -> list[str]:
    if not isinstance(data, dict) or "fragments" not in data:
        raise ValueError("expected {'fragments': [...]}")
    fragments = data["fragments"]
    if not isinstance(fragments, list) or len(fragments) < TARGET_FRAGMENTS_PER_SLOT:
        raise ValueError(f"expected {TARGET_FRAGMENTS_PER_SLOT}+ fragments, got {len(fragments) if isinstance(fragments, list) else 'non-list'}")
    return [str(f).strip() for f in fragments[:TARGET_FRAGMENTS_PER_SLOT]]


JSON_RETRIES = 3  # retries for malformed JSON (re-calls the API each time)


def call_and_parse(client: Any, system: str, prompt: str, validator, label: str = ""):
    """Call the API, extract JSON, and validate — retrying on parse/validation errors."""
    for attempt in range(JSON_RETRIES):
        text = call_claude(client, system, prompt)
        try:
            return validator(extract_json(text))
        except (json.JSONDecodeError, ValueError) as exc:
            if attempt < JSON_RETRIES - 1:
                print(f"    {label}JSON retry {attempt + 1}/{JSON_RETRIES}: {exc}", file=sys.stderr)
                time.sleep(2)
            else:
                raise


# ── Batch Runners ──────────────────────────────────────────────────────────

def run_themes_batch(
    client: Anthropic,
    checkpoint: Checkpoint,
    houses_filter: set[int] | None,
    dry_run: bool,
) -> None:
    print("=== Themes ===")
    for house in range(1, 13):
        if houses_filter and house not in houses_filter:
            continue
        key = str(house)
        if key in checkpoint.themes and len(checkpoint.themes[key]) >= TARGET_VARIANTS_PER_SLOT:
            print(f"  house {house}: cached ({len(checkpoint.themes[key])} variants)")
            continue

        if dry_run:
            print(f"  house {house}: would call API")
            continue

        print(f"  house {house}: calling API...")
        prompt = build_themes_prompt(house)
        variants = call_and_parse(client, SYSTEM_PROMPT, prompt, validate_theme_variants, f"house {house}: ")
        checkpoint.themes[key] = variants
        checkpoint.save()
        print(f"  house {house}: OK — {len(variants)} variants saved")
        time.sleep(RATE_LIMIT_SLEEP)


def run_categories_batch(
    client: Anthropic,
    checkpoint: Checkpoint,
    houses_filter: set[int] | None,
    dry_run: bool,
) -> None:
    print("=== Categories ===")
    for house in range(1, 13):
        if houses_filter and house not in houses_filter:
            continue
        hkey = str(house)
        if hkey not in checkpoint.categories:
            checkpoint.categories[hkey] = {}

        for category in CATEGORIES:
            if category in checkpoint.categories[hkey] and len(checkpoint.categories[hkey][category]) >= TARGET_VARIANTS_PER_SLOT:
                print(f"  house {house} {category}: cached")
                continue

            if dry_run:
                print(f"  house {house} {category}: would call API")
                continue

            print(f"  house {house} {category}: calling API...")
            prompt = build_category_prompt(house, category)
            variants = call_and_parse(client, SYSTEM_PROMPT, prompt, validate_category_variants, f"house {house} {category}: ")
            checkpoint.categories[hkey][category] = variants
            checkpoint.save()
            print(f"  house {house} {category}: OK — {len(variants)} variants saved")
            time.sleep(RATE_LIMIT_SLEEP)


def run_signatures_batch(
    client: Anthropic,
    checkpoint: Checkpoint,
    dry_run: bool,
) -> None:
    print("=== Cosmic Signature Fragments ===")

    def run_pool(name: str, items: list[str], target: dict[str, list[str]], prompt_builder) -> None:
        print(f"  --- {name} ---")
        for item in items:
            if item in target and len(target[item]) >= TARGET_FRAGMENTS_PER_SLOT:
                print(f"    {item}: cached")
                continue
            if dry_run:
                print(f"    {item}: would call API")
                continue
            print(f"    {item}: calling API...")
            prompt = prompt_builder(item)
            fragments = call_and_parse(client, SYSTEM_PROMPT, prompt, validate_fragments, f"{item}: ")
            target[item] = fragments
            checkpoint.save()
            print(f"    {item}: OK — {len(fragments)} fragments saved")
            time.sleep(RATE_LIMIT_SLEEP)

    run_pool("tithis", TITHI_NAMES, checkpoint.tithi_fragments, build_tithi_fragment_prompt)
    run_pool("nakshatras", NAKSHATRA_NAMES, checkpoint.nakshatra_fragments, build_nakshatra_fragment_prompt)
    run_pool("yogas", YOGA_NAMES, checkpoint.yoga_fragments, build_yoga_fragment_prompt)


# ── Output Writers ─────────────────────────────────────────────────────────

def write_horoscope_library(checkpoint: Checkpoint) -> None:
    house_themes: dict[str, list[dict]] = {}
    category_readings: dict[str, dict[str, list[dict]]] = {}

    for house in range(1, 13):
        key = str(house)
        if key in checkpoint.themes:
            house_themes[key] = checkpoint.themes[key]
        if key in checkpoint.categories:
            bucket: dict[str, list[dict]] = {}
            for category in CATEGORIES:
                if category in checkpoint.categories[key]:
                    bucket[category] = checkpoint.categories[key][category]
            if bucket:
                category_readings[key] = bucket

    if not house_themes and not category_readings:
        print("(horoscope_library.json not written — no checkpoint data yet)")
        return

    payload = {
        "version": LIBRARY_VERSION,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "model": MODEL,
        "houseThemes": house_themes,
        "categoryReadings": category_readings,
    }
    HOROSCOPE_OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False))
    print(f"Wrote {HOROSCOPE_OUTPUT.relative_to(REPO_ROOT)}")


def write_signature_library(checkpoint: Checkpoint) -> None:
    if not (checkpoint.tithi_fragments or checkpoint.nakshatra_fragments or checkpoint.yoga_fragments):
        print("(cosmic_signature_library.json not written — no checkpoint data yet)")
        return

    payload = {
        "version": LIBRARY_VERSION,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "model": MODEL,
        "tithiFragments": checkpoint.tithi_fragments,
        "nakshatraFragments": checkpoint.nakshatra_fragments,
        "yogaFragments": checkpoint.yoga_fragments,
    }
    SIGNATURE_OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False))
    print(f"Wrote {SIGNATURE_OUTPUT.relative_to(REPO_ROOT)}")


# ── Main ───────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    parser.add_argument("--dry-run", action="store_true", help="Show what would be called without hitting the API")
    parser.add_argument(
        "--only",
        choices=["themes", "categories", "signatures"],
        help="Run only one content pool",
    )
    parser.add_argument(
        "--houses",
        help="Comma-separated list of houses to regenerate (e.g. 1,5,12)",
    )
    args = parser.parse_args()

    houses_filter: set[int] | None = None
    if args.houses:
        try:
            houses_filter = {int(h.strip()) for h in args.houses.split(",") if h.strip()}
        except ValueError:
            print(f"ERROR: invalid --houses value: {args.houses}", file=sys.stderr)
            return 1

    RESOURCES_DIR.mkdir(parents=True, exist_ok=True)

    checkpoint = Checkpoint.load()
    client = None if args.dry_run else make_client()

    pools = {"themes", "categories", "signatures"} if args.only is None else {args.only}

    if "themes" in pools:
        run_themes_batch(client, checkpoint, houses_filter, args.dry_run)
    if "categories" in pools:
        run_categories_batch(client, checkpoint, houses_filter, args.dry_run)
    if "signatures" in pools:
        run_signatures_batch(client, checkpoint, args.dry_run)

    if not args.dry_run:
        write_horoscope_library(checkpoint)
        write_signature_library(checkpoint)
    else:
        print("\n(dry run — no files written)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
