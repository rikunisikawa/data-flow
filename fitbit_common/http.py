import json
import time
import urllib.error
import urllib.parse
import urllib.request


class FitbitApiError(Exception):
    pass


def request_json(method, url, headers=None, data=None, retries=2, retry_statuses=None, retry_backoff_seconds=1):
    retry_statuses = retry_statuses or {429, 500, 502, 503, 504}
    encoded_data = None
    if data is not None:
        if isinstance(data, dict):
            encoded_data = urllib.parse.urlencode(data).encode("utf-8")
        else:
            encoded_data = data

    for attempt in range(retries + 1):
        request = urllib.request.Request(url, data=encoded_data, headers=headers or {}, method=method)
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                status = response.status
                body = response.read().decode("utf-8")
                if status >= 400:
                    raise FitbitApiError(f"Fitbit API error {status}: {body}")
                if body:
                    return status, json.loads(body), dict(response.headers)
                return status, None, dict(response.headers)
        except urllib.error.HTTPError as exc:
            status = exc.code
            body = exc.read().decode("utf-8")
            if status in retry_statuses and attempt < retries:
                retry_after = exc.headers.get("Retry-After")
                if retry_after:
                    sleep_seconds = int(retry_after)
                else:
                    sleep_seconds = retry_backoff_seconds * (2 ** attempt)
                time.sleep(sleep_seconds)
                continue
            raise FitbitApiError(f"Fitbit API error {status}: {body}") from exc
        except urllib.error.URLError as exc:
            if attempt < retries:
                time.sleep(retry_backoff_seconds * (2 ** attempt))
                continue
            raise FitbitApiError(f"Fitbit API request failed: {exc}") from exc

    raise FitbitApiError("Fitbit API request exhausted retries")
