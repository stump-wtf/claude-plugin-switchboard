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
#
# @joestump 09/12/2026 - Added the positive assertion that the skill still names the live docs
# site. Measured gap, not a theoretical one: stripping the switchboard.stump.wtf URL out of
# SKILL.md entirely left `make lint` exiting 0. The retired-link grep below only fires when a
# dead URL comes BACK, so a skill carrying no docs link at all passed clean — and the correct
# URL appearing in that check's error message made it look asserted when it was not. Every
# guard here now fails in both directions: the banned thing appearing, and the required thing
# going away. Note the idiom — `grep -q ... || { ...; exit 1; }` as the final command in the
# loop body. A non-final `! grep -q` is exempt from errexit and would silently assert nothing.
#
# @joestump 09/21/2026 - Added the reference-file cross-check. The skill body sits at its line
# cap, so behaviour now lives in references/*.md behind a pointer; a renamed or deleted
# reference would leave the pointer dangling, and an unreferenced one is never loaded. Both
# directions fail.

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
	@echo "==> skill still names the live docs site"
	@for f in skills/*/SKILL.md; do \
		grep -q 'switchboard\.stump\.wtf/docs' "$$f" || { \
			echo "$$f: no link to https://switchboard.stump.wtf/docs/"; \
			echo "the retired-link check below only catches a dead URL coming BACK; without this"; \
			echo "assertion a skill with no docs link at all passes clean."; exit 1; }; \
	done
	@echo "==> skill references resolve, and every reference is pointed at"
	@for f in skills/*/SKILL.md; do \
		d=$$(dirname "$$f"); \
		for r in $$(grep -oE 'references/[a-z0-9-]+\.md' "$$f" | sort -u); do \
			[ -f "$$d/$$r" ] || { echo "$$f: points at $$r, which does not exist"; exit 1; }; \
		done; \
		for r in $$d/references/*.md; do \
			[ -e "$$r" ] || continue; \
			grep -q "references/$$(basename "$$r")" "$$f" || { echo "$$r: not referenced from $$f"; exit 1; }; \
		done; \
	done
	@echo "==> no retired switchboard links"
	@if grep -rn --exclude-dir=.git --exclude-dir=.claude \
		--include='*.md' --include='*.json' \
		-e 'joestump\.github\.io/switchboard' \
		-e 'github\.com/joestump/switchboard' . ; then \
		echo "retired Switchboard docs/repo link above; use https://switchboard.stump.wtf/docs/"; \
		exit 1; \
	fi
	@echo "==> no issue references (this plugin is public; the tracker is not)"
	@if grep -rnE '#[0-9]+' --exclude-dir=.git --exclude-dir=.claude \
		--include='*.md' skills/ ; then \
		echo "issue reference above. This plugin installs publicly, but switchboard's tracker is"; \
		echo "private: a bare #NNN resolves to THIS repo, and a qualified one resolves for nobody."; \
		echo "Describe the behaviour instead, and link https://switchboard.stump.wtf/docs/ if needed."; \
		exit 1; \
	fi
	@echo "OK"
