.PHONY: deploy rollout rollback

deploy:
	kubectl apply -f manifests/
	kubectl rollout status deployment/weamind -n weamind

rollout:
	kubectl rollout status deployment/weamind -n weamind

rollback:
	kubectl rollout undo deployment/weamind -n weamind