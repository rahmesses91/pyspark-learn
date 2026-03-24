"""
Meta-test: ensures this folder stays discoverable and points agents to ICA_SIMULATION.md.

Safe to run with: python3 -m unittest discover -s . -p 'test_*.py' -v
(from ica_practice_test_simulation/)
"""

import unittest
from pathlib import Path


class AgentNotesTests(unittest.TestCase):
    def test_simulation_doc_exists(self) -> None:
        here = Path(__file__).resolve().parent
        doc = here / "ICA_SIMULATION.md"
        self.assertTrue(
            doc.is_file(),
            "ICA_SIMULATION.md must exist next to this file for agent reference.",
        )
        text = doc.read_text(encoding="utf-8")
        self.assertIn("Level 1 only", text)
        self.assertIn("No solutions", text)


if __name__ == "__main__":
    unittest.main()
