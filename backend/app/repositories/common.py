from typing import Any

from sqlalchemy import RowMapping


def row_to_dict(row: RowMapping[str, Any] | None) -> dict[str, Any] | None:
    return dict(row) if row is not None else None


def rows_to_dicts(rows: list[RowMapping[str, Any]]) -> list[dict[str, Any]]:
    return [dict(row) for row in rows]
