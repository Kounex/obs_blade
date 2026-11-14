#!/usr/bin/env python3
"""python3 -m unittest test_prune (next to prune.py)."""

import unittest
from datetime import datetime, timedelta

from prune import plan

NOW = datetime(2026, 11, 15, 12, 30)


def names(start: datetime, count: int, step: timedelta, name="remote-relay"):
    return [f"{name}-{(start - i * step):%Y-%m-%d_%H%M}.db.gz" for i in range(count)]


class PruneTests(unittest.TestCase):
    def kept(self, files, **kw):
        args = dict(hours=48, days=14, weeks=8, months=12) | kw
        gone = set(plan(files, "remote-relay", NOW, **args))
        return [f for f in files if f not in gone]

    def test_a_year_of_six_hourly_copies_stays_bounded(self):
        files = names(NOW, 4 * 400, timedelta(hours=6))
        kept = self.kept(files)
        # 48 h of copies + 14 days + 8 weeks + 12 months, overlapping
        self.assertLessEqual(len(kept), 8 + 14 + 8 + 12)
        self.assertGreaterEqual(len(kept), 25)
        self.assertIn(files[0], kept)
        oldest = min(datetime.strptime(f[13:28], "%Y-%m-%d_%H%M") for f in kept)
        self.assertGreater(oldest, NOW - timedelta(days=12 * 31 + 1))
        self.assertLess(oldest, NOW - timedelta(days=300))

    def test_recent_copies_all_kept(self):
        files = names(NOW, 8, timedelta(hours=6))
        self.assertEqual(self.kept(files), files)

    def test_newest_survives_a_long_outage(self):
        files = names(NOW - timedelta(days=500), 3, timedelta(hours=6))
        self.assertEqual(self.kept(files), files[:1])

    def test_no_monthly_rule(self):
        files = names(NOW, 4 * 120, timedelta(hours=6))
        kept = self.kept(files, days=7, weeks=4, months=0)
        oldest = min(datetime.strptime(f[13:28], "%Y-%m-%d_%H%M") for f in kept)
        self.assertGreater(oldest, NOW - timedelta(days=29))

    def test_other_files_untouched(self):
        files = ["remote-relay-2020-01-01.db.gz", ".remote-relay-x.part", "notes.txt"]
        self.assertEqual(plan(files, "remote-relay", NOW, 48, 14, 8, 12), [])


if __name__ == "__main__":
    unittest.main()
