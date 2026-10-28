#!/usr/bin/env python3
"""Check every chart's primary image fallback and explicit override with Helm."""

import json
import re
import shutil
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
    if not (chart / "Chart.yaml").is_file() or chart.name == "common":
        continue
    values = (chart / "values.yaml").read_text()
    repository = re.search(r"^\s+repository: (\S+)", values, re.MULTILINE).group(1)
    tag_key = "image.tag"
    sentinel = "9.9.9-cpu"
    explicit_tag = "8.8.8@sha256:" + "a" * 64
    explicit_digest = "sha256:" + "b" * 64
    cases = [
        ("uses appVersion by default", {}, sentinel),
        ("uses appVersion when the override is empty", {tag_key: ""}, sentinel),
        ("preserves an explicit tag and digest", {tag_key: explicit_tag}, explicit_tag),
        ("gives image.digest precedence over tag", {tag_key: "7.7.7", "image.digest": explicit_digest}, "@" + explicit_digest),
    ]
    with tempfile.TemporaryDirectory(prefix="helm-image-contract-") as temporary:
        chart_copy = Path(temporary) / chart.name
        shutil.copytree(chart, chart_copy, ignore=shutil.ignore_patterns("__snapshot__"))
        chart_yaml = chart_copy / "Chart.yaml"
        copied_chart = chart_yaml.read_text()
        copied_chart, replacements = re.subn(
            r'(?m)^appVersion:\s+(?:"[^"\n]*"|[^\s#]+)',
            f'appVersion: "{sentinel}"',
            copied_chart,
            count=1,
        )
        assert replacements == 1, chart_yaml
        chart_yaml.write_text(copied_chart)
        for name, overrides, expected_tag in cases:
            command = ["helm", "template", "demo", str(chart_copy), "--show-only", "templates/deployment.yaml"]
            for key, value in settings_by_chart.get(chart.name, {}).items():
                command.extend(["--set-json", key + "=" + json.dumps(value)])
            for key, value in overrides.items():
                command.extend(["--set-json", key + "=" + json.dumps(value)])
            rendered = subprocess.run(
                command,
                check=True,
                capture_output=True,
                text=True,
                cwd=root,
            ).stdout
            image_match = re.search(r'(?m)^\s*image:\s+(?:"([^"\n]+)"|([^\s#]+))\s*$', rendered)
            assert image_match, (name, rendered)
            actual_image = next(value for value in image_match.groups() if value is not None)
            expected_image = repository + expected_tag if expected_tag.startswith("@") else repository + ":" + expected_tag
            assert actual_image == expected_image, (name, expected_image, actual_image)
            print(f"PASS  {chart.name}: {name}")

# User pod labels must never replace identity labels used by Deployment selectors.
reserved_labels = {
    "app.kubernetes.io/name": "changed",
    "app.kubernetes.io/instance": "changed",
    "team": "analytics",
}
rendered = subprocess.run(
    [
        "helm", "template", "demo", str(root / "charts/whoami"),
        "--set-json", "podLabels=" + json.dumps(reserved_labels),
    ],
    check=True,
    capture_output=True,
    text=True,
    cwd=root,
).stdout
pod_labels = rendered.split("template:\n    metadata:", 1)[1].split("\n    spec:", 1)[0]
assert "app.kubernetes.io/name: whoami" in pod_labels, pod_labels
assert "app.kubernetes.io/instance: demo" in pod_labels, pod_labels
assert "app.kubernetes.io/name: changed" not in pod_labels, pod_labels
assert "app.kubernetes.io/instance: changed" not in pod_labels, pod_labels
assert "team: analytics" in pod_labels, pod_labels
print("PASS  common selector labels override conflicting user podLabels")
