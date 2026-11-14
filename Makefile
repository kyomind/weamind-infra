.PHONY: deploy rollout rollback update-prompt-index

deploy:
	kubectl apply -f manifests/
	kubectl rollout status deployment/weamind -n weamind

rollout:
	kubectl rollout status deployment/weamind -n weamind

rollback:
	kubectl rollout undo deployment/weamind -n weamind

# 從各 prompt 的 description: 產生 .github/prompts/index.md；新增、刪除 prompt 或改 description 後重跑並一起 commit。
update-prompt-index:
	@{ echo '# Prompt Index'; echo; echo '> 由 `make update-prompt-index` 從各檔 `description:` 產生，不要手改。'; echo; \
	for f in .github/prompts/*.prompt.md; do \
		printf -- '- `%s` — %s\n' "$$(basename "$$f" .prompt.md)" "$$(sed -n 's/^description: *//p' "$$f" | head -1 | sed "s/^['\"]//; s/['\"]$$//")"; \
	done; } > .github/prompts/index.md
