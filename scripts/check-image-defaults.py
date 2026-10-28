#!/usr/bin/env python3
"""Check every chart's primary image fallback and explicit override with Helm."""

import json
import re
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
settings_by_chart = {
    "ovms": {"model.source": "example/model"},
    "fider": {
        "fider.baseURL": "https://feedback.example.com",
        "fider.existingSecret.name": "fider-secret",
        "db.existingSecret.name": "db-secret",
        "email.noreply": "noreply@example.com",
    },
    "dub": {
        "dub.appUrl": "https://dub.example.com",
        "auth.existingSecret.name": "dub-auth",
        "db.existingSecret.name": "dub-db",
    },
    "searxng": {
        "searxng.baseURL": "https://search.example.com",
        "searxng.existingSecret.name": "search-secret",
    },
    "shlink": {
        "shlink.defaultDomain": "s.example.com",
        "geolite.skipDownload": True,
    },
}
for chart in sorted((root / "charts").iterdir()):
    if not (chart / "Chart.yaml").is_file():
        continue
    values = (chart / "values.yaml").read_text()
    repository = re.search(r"^\s+repository: (\S+)", values, re.MULTILINE).group(1)
    tag_key = "runtime.image.tag" if chart.name == "ovms" else "image.tag"
    explicit_tag = "8.8.8@sha256:" + "a" * 64
    cases = [
        ("uses appVersion by default", {}, "9.9.9-cpu"),
        ("uses appVersion when the override is empty", {tag_key: ""}, "9.9.9-cpu"),
        ("preserves an explicit tag and digest", {tag_key: explicit_tag}, explicit_tag),
    ]
    tests = []
    for name, overrides, tag in cases:
        tests.append({
            "it": name,
            "chart": {"appVersion": "9.9.9-cpu"},
            "set": {**settings_by_chart.get(chart.name, {}), **overrides},
            "template": "deployment.yaml",
            "asserts": [{"equal": {
                "path": "spec.template.spec.containers[0].image",
                "value": repository + ":" + tag,
            }}],
        })
    templates = ["deployment.yaml"]
    if chart.name == "searxng":
        # The deployment includes this template for its config checksum.
        templates.append("configmap.yaml")
    # JSON is valid YAML and avoids requiring a Python YAML dependency.
    with tempfile.NamedTemporaryFile(mode="w", suffix="_test.yaml") as suite:
        json.dump({
            "suite": "primary image version contract",
            "templates": templates,
            "tests": tests,
        }, suite)
        suite.flush()
        subprocess.run(
            ["helm", "unittest", "--file", suite.name, str(chart)],
            check=True,
            cwd=root,
        )
