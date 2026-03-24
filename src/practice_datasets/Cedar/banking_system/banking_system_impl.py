"""Your implementation — subclass :class:`BankingSystem` and fill in behavior (``question.txt``).

Level 1 (CREATE_ACCOUNT, DEPOSIT, PAY) is implemented below.

Level 2 (``TOP_ACTIVITY``): use :class:`banking_activity_impl.BankingActivityImpl` and :meth:`_handle_top_activity`.
"""

from __future__ import annotations

from banking_activity_impl import BankingActivityImpl
from banking_system import BankingSystem
from collections import defaultdict

_KNOWN_OPS = frozenset({"CREATE_ACCOUNT", "DEPOSIT", "PAY", "TOP_ACTIVITY"})


def _banking_activity() -> dict:
    return {
        "activity": 0,
        "timestamp": 0,
        "balance": 0,
    }


class BankingSystemImpl(BankingSystem):
    def __init__(self) -> None:
        self.accounts: dict[str, dict[str, int]] = defaultdict(dict)
        self._banking_activity = BankingActivityImpl()
        self.total_activity: defaultdict[str, int] = defaultdict(int)

    def _handle_top_activity(self, query: list[str]) -> str:
        """
        Level 2 — handle ``TOP_ACTIVITY`` (rank accounts by transaction activity; see ``question.txt``).

        Use ``self._banking_activity.parse_top_activity_query`` / ``format_top_activity_response`` once
        implemented in ``banking_activity_impl.py``; track per-account activity on successful
        ``DEPOSIT`` / ``PAY`` as needed.
        """
        raise NotImplementedError
    
    def _query_to_dict(self, query: list[str]) -> dict:
        return {
            "activity": query[0],
            "timestamp": int(query[1]),
            "account_id": query[2],
            "amount": int(query[3]) if len(query) == 4 else None,
        }

    def execute(self, query: list[str]) -> str:
        if not query:
            raise ValueError("empty query")

        op = query[0]
        if op not in _KNOWN_OPS:
            raise ValueError(f"unknown operation: {op!r}")

        if op == "CREATE_ACCOUNT":
            if len(query) != 3:
                raise ValueError(f"CREATE_ACCOUNT query must have length 3, got {query!r}")
            activity, ts_s, account_id = query
            if account_id in self.accounts:
                return "false"
            self.accounts[account_id]["account_info"] = {
                "timestamp": int(ts_s),
                "balance": 0,
                "recent_activity": activity,
            }
            self.accounts[account_id]["banking_activity"] = [self._query_to_dict(query)]
            self.total_activity[account_id] = 0
            return "true"

        if op == "DEPOSIT":
            if len(query) != 4:
                raise ValueError(f"DEPOSIT query must have length 4, got {query!r}")
            activity, ts_s, account_id, amount_s = query
            if account_id not in self.accounts:
                return ""
            ts = int(ts_s)
            amount = int(amount_s)
            acc = self.accounts[account_id]
            if ts <= acc['account_info']["timestamp"]:
                raise ValueError(
                    f"query timestamp {ts} must be greater than account timestamp {acc['account_info']['timestamp']}"
                )
            acc["account_info"]["balance"] += amount
            acc["account_info"]["timestamp"] = ts
            acc["account_info"]["recent_activity"] = activity
            acc["banking_activity"].append(self._query_to_dict(query))
            self.total_activity[account_id] += amount
            return str(acc["account_info"]["balance"])

        if op == "PAY":
            if len(query) != 4:
                raise ValueError(f"PAY query must have length 4, got {query!r}")
            activity, ts_s, account_id, amount_s = query
            if account_id not in self.accounts:
                return ""
            ts = int(ts_s)  
            acc = self.accounts[account_id]
            amount = int(amount_s)
            if ts <= acc['account_info']["timestamp"]:
                raise ValueError(
                    f"query timestamp {ts} must be greater than account timestamp {acc['account_info']['timestamp']}"
                )
            if acc["account_info"]["balance"] < amount:
                return ""
            acc["account_info"]["balance"] -= amount
            acc["account_info"]["timestamp"] = ts
            acc["account_info"]["recent_activity"] = activity
            acc["banking_activity"].append(self._query_to_dict(query))
            self.total_activity[account_id] += amount
            return str(acc["account_info"]["balance"])

        if op == "TOP_ACTIVITY":
            if len(query) != 3:
                raise ValueError(f"TOP_ACTIVITY query must have length 3, got {query!r}")
            activity, ts_s, n_s = query
            ts = int(ts_s)
            n = int(n_s)
            if n < 0:
                raise ValueError(f"TOP_ACTIVITY n must be non-negative, got {n!r}")
            if n == 0 or not self.accounts:
                return ""

            ranked = sorted(
                self.total_activity.items(),
                key=lambda pair: (-pair[1], pair[0]),
            )
            top = ranked[:n]
            return self._banking_activity.format_top_activity_response(top)



def run_queries(queries: list[list[str]]) -> list[str]:
    """Run many queries on a **new** :class:`BankingSystemImpl` instance; return each result string."""
    bank = BankingSystemImpl()
    return [bank.execute(q) for q in queries]
