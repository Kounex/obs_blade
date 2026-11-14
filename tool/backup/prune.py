#!/usr/bin/env python3
"""Retention for pull-vps-backups.sh: <dir> <name> <hours> <days> <weeks> <months>.

Keeps every copy younger than <hours>, then the newest copy per day for
<days> days, per ISO week for <weeks> weeks, per month for <months> months,
and always the newest copy (so a long outage never deletes the last one).
Copies are <name>-YYYY-MM-DD_HHMM.db.gz; anything else is left alone.
"""

from __future__ import annotations

import os
import re
import sys
from datetime import datetime, timedelta


def plan(names: list[str], name: str, now: datetime, hours: int, days: int, weeks: int, months: int) -> list[str]:
    """The copies to delete."""
    pattern = re.compile(rf"^{re.escape(name)}-(\d{{4}}-\d{{2}}-\d{{2}}_\d{{4}})\.db\.gz$")
    copies = []
    for n in names:
        m = pattern.match(n)
        if m:
            copies.append((datetime.strptime(m.group(1), "%Y-%m-%d_%H%M"), n))
    copies.sort(reverse=True)  # newest first
    keep: set[str] = {copies[0][1]} if copies else set()
    seen: dict[str, set] = {"day": set(), "week": set(), "month": set()}
    for taken, n in copies:
        age = now - taken
        if age <= timedelta(hours=hours):
            keep.add(n)
        rules = (
            ("day", taken.date(), days),
            ("week", taken.isocalendar()[:2], weeks * 7),
            ("month", (taken.year, taken.month), months * 31),
        )
        for kind, key, limit_days in rules:
            if age <= timedelta(days=limit_days) and key not in seen[kind]:
                seen[kind].add(key)
                keep.add(n)
    return [n for _, n in copies if n not in keep]


def main() -> None:
    folder, name = sys.argv[1], sys.argv[2]
    hours, days, weeks, months = (int(x) for x in sys.argv[3:7])
    for n in plan(os.listdir(folder), name, datetime.now(), hours, days, weeks, months):
        os.unlink(os.path.join(folder, n))
        print(f"{name}: pruned {n}")


if __name__ == "__main__":
    main()
