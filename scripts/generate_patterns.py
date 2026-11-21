"""Build the Verilog ROM and offline solver from the same validated CSV."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_patterns():
    patterns = {}
    with (ROOT / "data/patterns.csv").open(encoding="utf-8", newline="") as source:
        for row in csv.DictReader(source):
            key = int(row["seed"]), int(row["level"])
            sequence = [int(row[f"color{i}"]) for i in range(1, 9)]
            if sorted(sequence) != list(range(8)):
                raise ValueError(f"{key} must contain each color from 0 to 7 once")
            if key in patterns:
                raise ValueError(f"Repeated seed/level {key}")
            patterns[key] = sequence
    expected_keys = {(seed, level) for seed in range(8) for level in range(1, 9)}
    if patterns.keys() != expected_keys or len({tuple(row) for row in patterns.values()}) != 64:
        raise ValueError("Expected 64 distinct patterns covering seeds 0–7 and levels 1–8")
    return patterns


def verilog_rom(patterns):
    lines = [
        "`timescale 1ns / 1ps",
        "// Generated from data/patterns.csv by scripts/generate_patterns.py.",
        "module sequence_rom (",
        "    input wire [2:0] seed, level,",
        "    output reg [23:0] pattern",
        ");",
        "    // ROM address = {seed, zero-based level}. The first color occupies bits [2:0].",
        "    always @* begin",
        "        case ({seed, level})",
    ]
    for (seed, level), colors in sorted(patterns.items()):
        address = seed * 8 + level - 1
        word = sum(color << (3 * index) for index, color in enumerate(colors))
        comment = " ".join(map(str, colors))
        lines.append(f"            6'd{address:<2}: pattern = 24'h{word:06x}; // {comment}")
    lines += ["            default: pattern = 0;", "        endcase", "    end", "endmodule", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if either generated file differs")
    args = parser.parse_args()
    patterns = load_patterns()
    nested = [[patterns[seed, level] for level in range(1, 9)] for seed in range(8)]
    template = (ROOT / "solver/seed_solver.template").read_text(encoding="utf-8")
    outputs = {
        ROOT / "rtl/sequence_rom.v": verilog_rom(patterns),
        ROOT / "solver/seed_solver.html": template.replace(
            "__PATTERNS_JSON__", json.dumps(nested, separators=(",", ":"))
        ),
    }
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                parser.exit(1, f"Out of date: {path.relative_to(ROOT)}\n")
        else:
            path.write_text(content, encoding="utf-8", newline="\n")
    print("Verified 64 unique patterns." if args.check else "Generated ROM and seed solver.")


if __name__ == "__main__":
    main()
