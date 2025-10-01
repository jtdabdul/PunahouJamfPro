#!/usr/bin/env python3
"""
Search Jamf Smart Group criteria for a matching string or regex.

- Auth: Jamf Pro Bearer token (POST /api/v1/auth/token), then Classic API GETs
- Scans: Computer Smart Groups, Mobile Device Smart Groups, and User Smart Groups
- Matches: criteria.name and criteria.value (case-insensitive by default)
- Output: human-readable table OR JSON

Usage examples:
  python jamf_smart_group_grep.py \
    --url https://yourorg.jamfcloud.com \
    --user API_USER --password '********' \
    --pattern 'Chrome'

  python jamf_smart_group_grep.py \
    --url https://yourorg.jamfcloud.com \
    --user API_USER --password '********' \
    --pattern '(?i)^department$' --regex --include computer mobile --json

Requires: Python 3.8+
"""

import argparse
import concurrent.futures as futures
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional, Tuple
from urllib.parse import urljoin

import requests
from xml.etree import ElementTree as ET


# ---------- Configuration / Constants ----------

GROUP_TYPES = ("computer", "mobile", "user")

CLASSIC_COLLECTION_ENDPOINT = {
    "computer": "computergroups",
    "mobile": "mobiledevicegroups",
    "user": "usergroups",
}

CLASSIC_DETAIL_ROOT_KEY = {
    "computer": "computer_group",
    "mobile": "mobile_device_group",
    "user": "user_group",
}

DEFAULT_TIMEOUT = 30
REQUESTS_RETRIES = 3
THREADS = 10


# ---------- Dataclasses ----------

@dataclass
class GroupSummary:
    group_type: str
    id: int
    name: str
    is_smart: bool


@dataclass
class Criterion:
    name: str
    search_type: Optional[str]
    value: Optional[str]
    and_or: Optional[str]


@dataclass
class Match:
    group_type: str
    group_id: int
    group_name: str
    matched_field: str  # "name" or "value"
    criterion: Criterion


# ---------- Jamf API Client ----------

class JamfClient:
    def __init__(self, base_url: str, username: Optional[str], password: Optional[str], token: Optional[str] = None, verify_ssl: bool = True):
        self.base = base_url.rstrip("/")
        self.username = username
        self.password = password
        self._token = token
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
        self.session.headers.update({"Accept": "application/json"})
        self.session.verify = verify_ssl

    # ---- Authentication ----
    def token(self) -> str:
        if self._token:
            return self._token
        if not (self.username and self.password):
            raise RuntimeError("Username/password or a pre-existing token is required.")
        url = urljoin(self.base, "/api/v1/auth/token")
        for attempt in range(1, REQUESTS_RETRIES + 1):
            resp = self.session.post(url, auth=(self.username, self.password), headers={"Accept": "application/json"}, timeout=DEFAULT_TIMEOUT)
            if resp.ok:
                data = resp.json()
                self._token = data.get("token")
                if not self._token:
                    raise RuntimeError("Token response did not include 'token'.")
                # Attach Authorization header for subsequent requests
                self.session.headers["Authorization"] = f"Bearer {self._token}"
                return self._token
            if attempt == REQUESTS_RETRIES:
                raise RuntimeError(f"Token request failed: {resp.status_code} {resp.text}")
            time.sleep(1.5 * attempt)
        raise RuntimeError("Failed to obtain token for unknown reasons.")

    # ---- Helpers to GET Classic API with graceful JSON/XML handling ----
    def _classic_get(self, path: str) -> Tuple[Optional[Dict[str, Any]], Optional[ET.Element]]:
        """
        Returns (json_dict, xml_root). If JSON available, xml_root is None.
        If JSON not available and XML returned, json_dict is None and xml_root is set.
        """
        self.token()  # ensure token set + Authorization header applied
        url = urljoin(self.base, f"/JSSResource/{path}".lstrip("/"))
        # Prefer JSON
        headers = dict(self.session.headers)
        headers["Accept"] = "application/json"
        resp = self.session.get(url, headers=headers, timeout=DEFAULT_TIMEOUT)
        if resp.ok and "application/json" in resp.headers.get("Content-Type", ""):
            return resp.json(), None

        # Fallback to XML
        headers["Accept"] = "application/xml"
        resp = self.session.get(url, headers=headers, timeout=DEFAULT_TIMEOUT)
        if resp.ok and "xml" in resp.headers.get("Content-Type", ""):
            try:
                root = ET.fromstring(resp.content)
                return None, root
            except ET.ParseError as e:
                raise RuntimeError(f"Failed to parse XML from {url}: {e}")
        resp.raise_for_status()
        raise RuntimeError(f"Unexpected response from {url}: {resp.status_code} {resp.text}")

    # ---- Listing & detail ----
    def list_groups(self, group_type: str) -> List[GroupSummary]:
        if group_type not in GROUP_TYPES:
            raise ValueError(f"Unknown group_type '{group_type}'")
        endpoint = CLASSIC_COLLECTION_ENDPOINT[group_type]
        json_obj, xml_root = self._classic_get(endpoint)

        results: List[GroupSummary] = []
        if json_obj is not None:
            # JSON shape:
            # { "computer_groups": [ {"id": 1, "name": "...", "is_smart": true}, ... ] }
            key = f"{group_type}_groups"
            arr = json_obj.get(key, [])
            for item in arr:
                results.append(
                    GroupSummary(
                        group_type=group_type,
                        id=int(item.get("id")),
                        name=str(item.get("name", "")),
                        is_smart=bool(item.get("is_smart", False)),
                    )
                )
            return results

        # XML fallback
        # <computer_groups><computer_group><id>...</id><name>...</name><is_smart>true</is_smart></computer_group>...</computer_groups>
        plural_tag = f"{group_type}_groups"
        singular_tag = f"{group_type}_group"
        for entry in xml_root.findall(f".//{singular_tag}"):
            gid = int((entry.findtext("id") or "0"))
            name = entry.findtext("name") or ""
            is_smart_text = (entry.findtext("is_smart") or "").strip().lower()
            results.append(
                GroupSummary(
                    group_type=group_type,
                    id=gid,
                    name=name,
                    is_smart=is_smart_text == "true",
                )
            )
        return results

    def get_group_criteria(self, group_type: str, group_id: int) -> List[Criterion]:
        endpoint = f"{CLASSIC_COLLECTION_ENDPOINT[group_type]}/id/{group_id}"
        root_key = CLASSIC_DETAIL_ROOT_KEY[group_type]
        json_obj, xml_root = self._classic_get(endpoint)

        crits: List[Criterion] = []
        if json_obj is not None:
            # JSON shape:
            # { "computer_group": { "criteria": { "size": N, "criterion": [ {name, search_type, value, and_or, ...}, ... ] } } }
            root = json_obj.get(root_key, {})
            criteria_block = root.get("criteria") or {}
            # Jamf sometimes returns "criterion" list, or a single dict
            raw = criteria_block.get("criterion", [])
            if isinstance(raw, dict):
                raw = [raw]
            for c in raw:
                crits.append(
                    Criterion(
                        name=str(c.get("name", "")),
                        search_type=c.get("search_type"),
                        value=str(c.get("value")) if c.get("value") is not None else None,
                        and_or=c.get("and_or"),
                    )
                )
            return crits

        # XML fallback:
        # .../<computer_group>/<criteria>/<criterion> with child nodes
        root_node = xml_root.find(f".//{root_key}")
        if root_node is None:
            return crits
        for c in root_node.findall(".//criteria/criterion"):
            crits.append(
                Criterion(
                    name=(c.findtext("name") or ""),
                    search_type=c.findtext("search_type"),
                    value=c.findtext("value"),
                    and_or=c.findtext("and_or"),
                )
            )
        return crits


# ---------- Search / Match Logic ----------

def build_matcher(pattern: str, use_regex: bool, case_insensitive: bool):
    if use_regex:
        flags = re.IGNORECASE if case_insensitive else 0
        compiled = re.compile(pattern, flags)
        def regex_match(s: Optional[str]) -> bool:
            return bool(s is not None and compiled.search(s))
        return regex_match
    else:
        needle = pattern.lower() if case_insensitive else pattern
        def substr_match(s: Optional[str]) -> bool:
            if s is None:
                return False
            hay = s.lower() if case_insensitive else s
            return needle in hay
        return substr_match


def scan_group(client: JamfClient, group: GroupSummary, matches_func) -> List[Match]:
    found: List[Match] = []
    criteria = client.get_group_criteria(group.group_type, group.id)  # static groups => empty criteria
    for c in criteria:
        for field_name in ("name", "value"):
            val = getattr(c, field_name)
            if matches_func(val):
                found.append(
                    Match(
                        group_type=group.group_type,
                        group_id=group.id,
                        group_name=group.name,
                        matched_field=field_name,
                        criterion=c,
                    )
                )
                break  # don’t duplicate per-criterion
    return found


# ---------- Output Helpers ----------

def to_json(matches: List[Match]) -> str:
    payload = []
    for m in matches:
        payload.append({
            "group_type": m.group_type,
            "group_id": m.group_id,
            "group_name": m.group_name,
            "matched_field": m.matched_field,
            "criterion": {
                "name": m.criterion.name,
                "search_type": m.criterion.search_type,
                "value": m.criterion.value,
                "and_or": m.criterion.and_or,
            }
        })
    return json.dumps(payload, indent=2, sort_keys=False)


def print_table(matches: List[Match]) -> None:
    if not matches:
        print("No matches found.")
        return
    # Pretty, multi-line grouped output
    by_group: Dict[Tuple[str, int, str], List[Match]] = {}
    for m in matches:
        key = (m.group_type, m.group_id, m.group_name)
        by_group.setdefault(key, []).append(m)

    def label(gt: str) -> str:
        return {"computer": "Computer SG", "mobile": "Mobile SG", "user": "User SG"}.get(gt, gt)

    for (gt, gid, gname), rows in sorted(by_group.items(), key=lambda x: (x[0][0], x[0][2].lower())):
        print(f"\n[{label(gt)}] {gname} (id={gid})")
        print("  Matches:")
        for m in rows:
            c = m.criterion
            op = c.search_type or "—"
            ao = c.and_or or "—"
            val = c.value if c.value is not None else "—"
            print(f"   • {m.matched_field:>5} → name='{c.name}', op='{op}', value='{val}', and_or='{ao}'")


# ---------- Main ----------

def main():
    parser = argparse.ArgumentParser(description="Search Jamf Smart Group criteria for a given string/regex.")
    parser.add_argument("--url", required=True, help="Base Jamf Pro URL, e.g., https://yourorg.jamfcloud.com")
    parser.add_argument("--user", help="Jamf API username (or set JAMF_USER)")
    parser.add_argument("--password", help="Jamf API password (or set JAMF_PASS)")
    parser.add_argument("--token", help="Pre-existing bearer token (alternatively, use --user/--password)")
    parser.add_argument("--pattern", required=True, help="String or regex to match against criteria name/value")
    parser.add_argument("--regex", action="store_true", help="Interpret --pattern as a regular expression")
    parser.add_argument("--case-insensitive", action="store_true", default=True, help="Case-insensitive match (default: on)")
    parser.add_argument("--case-sensitive", action="store_false", dest="case_insensitive", help="Case-sensitive match")
    parser.add_argument("--include", nargs="*", choices=GROUP_TYPES, default=list(GROUP_TYPES),
                        help="Group types to include (default: computer mobile user)")
    parser.add_argument("--json", action="store_true", help="Output JSON instead of a text table")
    parser.add_argument("--no-verify-ssl", action="store_true", help="Disable TLS cert verification (not recommended)")

    args = parser.parse_args()

    username = args.user or os.getenv("JAMF_USER")
    password = args.password or os.getenv("JAMF_PASS")
    token = args.token or os.getenv("JAMF_TOKEN")

    if not token and not (username and password):
        parser.error("Provide --token OR --user/--password (or set JAMF_TOKEN / JAMF_USER / JAMF_PASS).")

    client = JamfClient(args.url, username, password, token=token, verify_ssl=not args.no_verify_ssl)
    matcher = build_matcher(args.pattern, args.regex, args.case_insensitive)

    # List all groups for included types
    all_groups: List[GroupSummary] = []
    for gt in args.include:
        try:
            all_groups.extend(client.list_groups(gt))
        except Exception as e:
            print(f"ERROR listing {gt} groups: {e}", file=sys.stderr)

    # Scan ALL groups; some Jamf versions don’t expose is_smart in the list
    candidates = all_groups

    matches: List[Match] = []
    with futures.ThreadPoolExecutor(max_workers=THREADS) as pool:
        jobs = [pool.submit(scan_group, client, g, matcher) for g in candidates]
        for job in futures.as_completed(jobs):
            try:
                matches.extend(job.result())
            except Exception as e:
                print(f"ERROR scanning group: {e}", file=sys.stderr)

    # Output
    if args.json:
        print(to_json(matches))
    else:
        print_table(matches)


if __name__ == "__main__":
    main()