"""Local GitHub integration helper; credentials are captured only in memory."""
import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REPOSITORY = "nationalcptc-teamtools/United-States-Military-Academy"
ACCOUNT = "sebastianjsolberg"
API = "https://api.github.com"
GIT = "C:/Program Files/Git/cmd/git.exe"


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="action", required=True)
    subparsers.add_parser("inspect")
    create = subparsers.add_parser("create-pr")
    create.add_argument("--head", required=True)
    create.add_argument("--body-file", required=True)
    update = subparsers.add_parser("update-pr")
    update.add_argument("--number", required=True, type=int)
    update.add_argument("--head-sha", required=True)
    update.add_argument("--title", required=True)
    update.add_argument("--body-file", required=True)
    args = parser.parse_args()
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    env["GCM_INTERACTIVE"] = "Never"
    result = subprocess.run(
        [GIT, "-c", "credential.interactive=false", "credential", "fill"],
        input=f"protocol=https\nhost=github.com\nusername={ACCOUNT}\n\n",
        text=True, capture_output=True, timeout=20, env=env)
    if result.returncode:
        raise RuntimeError("No usable noninteractive GitHub credential")
    credentials = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    token = credentials.get("password")
    if not token:
        raise RuntimeError("No usable GitHub credential")
    headers = {
        "Authorization": "Bearer " + token,
        "Accept": "application/vnd.github+json",
        "User-Agent": "CPTC-repository-integration",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    def request(path, data=None, method=None):
        raw = None if data is None else json.dumps(data).encode()
        req = urllib.request.Request(API + path, data=raw, headers=headers, method=method)
        if raw is not None:
            req.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req, timeout=25) as response:
            return json.load(response)

    user = request("/user")
    if user.get("login") != ACCOUNT:
        raise RuntimeError("Authenticated GitHub account differs from approved account")
    repo = request("/repos/" + REPOSITORY)
    if not repo.get("permissions", {}).get("push"):
        raise RuntimeError("Approved account does not have repository write access")
    if args.action == "inspect":
        branches = request("/repos/" + REPOSITORY + "/branches?per_page=100")
        pulls = request("/repos/" + REPOSITORY + "/pulls?state=open&per_page=100")
        print(json.dumps({
            "account": user["login"],
            "commit_name": user.get("name") or user["login"],
            "commit_email": f"{user['id']}+{user['login']}@users.noreply.github.com",
            "default_branch": repo["default_branch"],
            "branches": [{"name": b["name"], "sha": b["commit"]["sha"]} for b in branches],
            "open_pull_requests": [
                {"number": p["number"], "title": p["title"], "head": p["head"]["ref"],
                 "base": p["base"]["ref"], "url": p["html_url"]} for p in pulls],
        }))
    elif args.action == "update-pr":
        path = "/repos/" + REPOSITORY + "/pulls/" + str(args.number)
        pull = request(path)
        if (pull["state"] != "open" or pull.get("merged") or
                pull["head"]["sha"] != args.head_sha or
                pull["head"]["ref"] != "codex/report-generator"):
            raise RuntimeError("Pull request state differs from reviewed update")
        body = Path(args.body_file).read_text(encoding="utf-8")
        pull = request(path, {"title": args.title, "body": body}, method="PATCH")
        if pull["body"] != body or pull["title"] != args.title:
            raise RuntimeError("Pull request metadata verification failed")
        print(json.dumps({
            "number": pull["number"], "url": pull["html_url"],
            "draft": pull["draft"], "head_sha": pull["head"]["sha"],
            "state": pull["state"], "merged": pull.get("merged"),
            "title": pull["title"], "account": user["login"],
        }))
    else:
        query = urllib.parse.urlencode({
            "state": "open", "head": REPOSITORY.split("/")[0] + ":" + args.head,
            "base": repo["default_branch"],
        })
        existing = request("/repos/" + REPOSITORY + "/pulls?" + query)
        if existing:
            pull = existing[0]
        else:
            pull = request("/repos/" + REPOSITORY + "/pulls", {
                "title": "Add offline Markdown and PDF reporting starter",
                "head": args.head, "base": repo["default_branch"], "draft": True,
                "body": Path(args.body_file).read_text(encoding="utf-8"),
            })
        print(json.dumps({
            "number": pull["number"], "url": pull["html_url"],
            "draft": pull["draft"], "head_sha": pull["head"]["sha"],
        }))


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"GitHub operation failed: HTTP {error.code}", file=sys.stderr)
        sys.exit(1)
    except (urllib.error.URLError, TimeoutError, RuntimeError, subprocess.TimeoutExpired):
        print("GitHub operation could not complete; check access or connectivity.", file=sys.stderr)
        sys.exit(1)
