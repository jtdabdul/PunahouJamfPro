#!/usr/bin/env python3
"""
Export criteria for ALL Computer Smart Groups using jamf-pro-sdk Classic API (tested with 0.8a1).

Auth: OAuth client credentials only (client_id/client_secret).
"""

import argparse
import json
import sys
from typing import Any, Dict, List, Optional

from jamf_pro_sdk import JamfProClient, ApiClientCredentialsProvider

# -------------------- attribute-safe access helpers --------------------

def _attr(o: Any, name: str, default=None):
    # Prefer attribute (Pydantic model fields), fallback to dict
    if hasattr(o, name):
        return getattr(o, name)
    if isinstance(o, dict):
        return o.get(name, default)
    return default

def _to_dict(o: Any) -> Dict[str, Any]:
    if isinstance(o, dict):
        return o
    for m in ("model_dump", "dict"):
        if hasattr(o, m):
            try:
                return getattr(o, m)()
            except Exception:
                pass
    return {}

def _is_smart(group: Any) -> bool:
    return bool(_attr(group, "is_smart", _attr(group, "isSmart", False)))

def _group_id(group: Any) -> Optional[int]:
    gid = _attr(group, "id", None)
    if gid is None:
        cg = _attr(group, "computer_group", None)
        if cg is not None:
            gid = _attr(cg, "id", None)
    try:
        return int(gid) if gid is not None else None
    except Exception:
        return None

def _group_name(group: Any) -> str:
    name = _attr(group, "name", None)
    if name is None:
        cg = _attr(group, "computer_group", None)
        if cg is not None:
            name = _attr(cg, "name", "")
    return str(name or "")

def _group_site(group: Any) -> Optional[str]:
    site = _attr(group, "site", None)
    if isinstance(site, dict):
        return site.get("name")
    name = _attr(site, "name", None)  # pydantic Site model
    return name if name is not None else (site if isinstance(site, str) else None)

def _normalize_criterion(c: Any) -> Dict[str, Any]:
    return {
        "name": _attr(c, "name"),
        "search_type": _attr(c, "search_type", _attr(c, "searchType", None)),
        "value": _attr(c, "value"),
        "and_or": _attr(c, "and_or", _attr(c, "andOr", None)),
    }

def _extract_criteria(detail: Any) -> List[Dict[str, Any]]:
    """
    Handles multiple shapes:
      - detail.computer_group.criteria is:
          a) an object with .criterion (list or single)
          b) a list/tuple of criterion models
          c) a dict with {'criterion': [...]} or a single dict
    """
    cg = _attr(detail, "computer_group", detail)

    criteria = _attr(cg, "criteria", None)
    if criteria is None:
        # Some payloads put 'criteria' directly as a list/iterable on the group
        # or under a 'computer_group' dict.
        cg_dict = _to_dict(cg)
        criteria = cg_dict.get("criteria")

    # (1) If criteria has '.criterion', use that
    crit_list = _attr(criteria, "criterion", None)
    if crit_list is not None:
        if isinstance(crit_list, dict):
            crit_list = [crit_list]
        return [_normalize_criterion(c) for c in (crit_list or [])]

    # (2) If 'criteria' itself is a list/tuple of criterion models/dicts
    if isinstance(criteria, (list, tuple)):
        return [_normalize_criterion(c) for c in criteria]

    # (3) If 'criteria' is a dict with 'criterion' key
    if isinstance(criteria, dict) and "criterion" in criteria:
        crit = criteria["criterion"]
        if isinstance(crit, dict):
            crit = [crit]
        return [_normalize_criterion(c) for c in (crit or [])]

    # (4) Some Classic responses use 'criteria' -> {'size': N, 'criterion': [...]}
    if isinstance(criteria, dict) and "size" in criteria:
        crit = criteria.get("criterion", [])
        if isinstance(crit, dict):
            crit = [crit]
        return [_normalize_criterion(c) for c in (crit or [])]

    # Nothing found
    return []

# -------------------- core logic --------------------

def list_smart_computer_group_criteria(server: str, client_id: str, client_secret: str) -> List[Dict[str, Any]]:
    client = JamfProClient(
        server=server,
        credentials=ApiClientCredentialsProvider(client_id, client_secret),
    )

    # 1) List all computer groups (Classic)
    all_groups_resp = client.classic_api.list_all_computer_groups()

    # Support both model and dict/list returns
    groups = _attr(all_groups_resp, "computer_groups", None)
    if groups is None:
        if isinstance(all_groups_resp, dict):
            groups = all_groups_resp.get("computer_groups", all_groups_resp.get("results", []))
        elif isinstance(all_groups_resp, list):
            groups = all_groups_resp
        else:
            groups = []

    results: List[Dict[str, Any]] = []
    for g in groups:
        if not _is_smart(g):
            continue

        gid = _group_id(g)
        if gid is None:
            continue

        # 2) Fetch detail. Some SDK builds/servers need 'view=full' to include criteria.
        try:
            detail = client.classic_api.get_computer_group_by_id(gid, view="full")  # try full view
        except TypeError:
            # Fallback if method signature doesn't accept 'view'
            detail = client.classic_api.get_computer_group_by_id(gid)

        crit = _extract_criteria(detail)

        results.append({
            "id": gid,
            "name": _group_name(g),
            "site": _group_site(g),
            "criteria": crit,
        })

    return results

# -------------------- CLI --------------------

def main():
    ap = argparse.ArgumentParser(description="Export criteria for all Computer Smart Groups (Classic API, 0.8a1-safe).")
    ap.add_argument("--server", required=True, help="Jamf Pro server domain (no protocol), e.g. yourtenant.jamfcloud.com")
    ap.add_argument("--client-id", required=True, help="Jamf Pro API Client ID")
    ap.add_argument("--client-secret", required=True, help="Jamf Pro API Client Secret")
    args = ap.parse_args()

    data = list_smart_computer_group_criteria(args.server, args.client_id, args.client_secret)
    json.dump(data, sys.stdout, indent=2)
    sys.stdout.write("\n")

if __name__ == "__main__":
    main()
