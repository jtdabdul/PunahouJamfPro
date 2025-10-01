#!/usr/bin/env python3
import argparse
import json
import sys
from typing import Any, Dict, List, Union

from jamf_pro_sdk import JamfProClient, ApiClientCredentialsProvider
from jamf_pro_sdk.clients.pro_api.pagination import Paginator

def _results_list(resp: Union[Dict[str, Any], List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    """
    Jamf Pro list endpoints typically return {"results": [...], "totalCount": N}.
    But if the SDK ever returns a bare list, handle that too.
    """
    if isinstance(resp, dict) and "results" in resp:
        return resp["results"]
    if isinstance(resp, list):
        return resp
    return []

def get_smart_groups(server: str, client_id: str, client_secret: str) -> Dict[str, List[Dict[str, Any]]]:
    client = JamfProClient(
        server=server,
        credentials=ApiClientCredentialsProvider(client_id, client_secret),
    )

    # NOTE: Paginator in 0.8a1 requires return_model; use None for raw JSON.
    comp_resp = Paginator(
        api_client=client.pro_api,
        resource_path="v1/computer-groups",
        return_model=None,
    )(return_generator=False)

    mobile_resp = Paginator(
        api_client=client.pro_api,
        resource_path="v1/mobile-device-groups",
        return_model=None,
    )(return_generator=False)

    comp_groups = [g for g in _results_list(comp_resp) if g.get("isSmart") is True]
    mobile_groups = [g for g in _results_list(mobile_resp) if g.get("isSmart") is True]

    return {
        "smartComputerGroups": comp_groups,
        "smartMobileDeviceGroups": mobile_groups,
    }

def main():
    parser = argparse.ArgumentParser(description="List all smart groups from Jamf Pro (client credentials only).")
    parser.add_argument("--server", required=True, help="Jamf Pro server, e.g. https://yourtenant.jamfcloud.com")
    parser.add_argument("--client-id", required=True, help="Jamf Pro API Client ID")
    parser.add_argument("--client-secret", required=True, help="Jamf Pro API Client Secret")
    args = parser.parse_args()

    data = get_smart_groups(args.server, args.client_id, args.client_secret)
    json.dump(data, sys.stdout, indent=2)
    print()

if __name__ == "__main__":
    main()
