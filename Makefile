# Plugin Checks
#
# This repository ships markdown guidance rather than code, so `make test` and `make lint` run
# the same gate: the plugin manifests must be valid JSON, every skill must carry usable
# frontmatter, and no shipped document may link the retired Switchboard docs site or repo.
#
# The stale-link check earns its place: guidance that points agents at a dead repo is exactly
# the defect that made this target necessary, and a grep is the cheapest way to keep it dead.
#
# So does the body-cap check. A skill body over the cap is silently truncated where it is read,
# which loses the end of the file rather than failing loudly — and measuring by hand is exactly
# the step a hurried author skips.
#
# @joestump 09/12/2026 - Added test/lint/check alongside the skill's MCP-surface correction.
#
# @joestump 09/12/2026 - Added the 180-line skill body cap check, after breaching the cap twice
# in one session and pushing at 181 lines. A lint that checks manifests and links but not the
# cap lets the next author do the same.

.PHONY: check test lint

check: test lint

test: lint

lint:
	@echo "==> manifests parse"
	@for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do \
		python3 -m json.tool "$$f" >/dev/null || exit 1; \
	done
	@echo "==> skill frontmatter"
	@for f in skills/*/SKILL.md; do \
		head -1 "$$f" | grep -qx -- '---' || { echo "$$f: missing frontmatter opener"; exit 1; }; \
		grep -qE '^name: ' "$$f" || { echo "$$f: frontmatter has no name:"; exit 1; }; \
		grep -qE '^description: ' "$$f" || { echo "$$f: frontmatter has no description:"; exit 1; }; \
	done
	@echo "==> skill body within the 180-line cap"
	@for f in skills/*/SKILL.md; do \
		n=$$(awk '/^---$$/{c++; next} c>=2' "$$f" | wc -l | tr -d ' '); \
		[ "$$n" -le 180 ] || { echo "$$f: body is $$n lines, cap is 180"; exit 1; }; \
	done
	@echo "==> no retired switchboard links"
	@if grep -rn --exclude-dir=.git --exclude-dir=.claude \
		--include='*.md' --include='*.json' \
		-e 'joestump\.github\.io/switchboard' \
		-e 'github\.com/joestump/switchboard' . ; then \
		echo "retired Switchboard docs/repo link above; use https://switchboard.stump.wtf/docs/"; \
		exit 1; \
	fi
	@echo "OK"
