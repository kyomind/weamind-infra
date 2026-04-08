# Darkmind Lab

Darkmind is a small Kubernetes troubleshooting lab for W6 command drills.
It is not part of the WeaMind production deployment.

## Design Goal

- Keep the lab isolated in the `darkmind` namespace.
- Make every scenario easy to `apply`, inspect, and delete.
- Practice evidence-based debugging with real Kubernetes states.
- Support W6 drills for `get`, `describe`, `events`, `logs`, `logs --previous`, `rollout`, `exec`, and `port-forward`.

## Non-Goals

- Do not connect to the real WeaMind application, LINE webhook, PostgreSQL, or Redis.
- Do not reuse the production `weamind` namespace.
- Do not optimize for production-grade app behavior.
- Do not make the first version depend on custom images.
- Do not cover every possible Kubernetes failure mode.

## Scope Rule

Darkmind follows the 70-point rule: cover the classic failures that make `kubectl` troubleshooting visible, then stop.

Each scenario should have:

1. One clear symptom.
2. One primary Kubernetes layer to inspect.
3. One or two high-value commands.
4. A small enough output surface for command drill.

Avoid adding scenarios only because they are possible. Add a scenario only when it teaches a distinct debugging move that the current lab does not already cover.

## Directory Layout

```text
darkmind/
  README.md
  namespace.yaml
  healthy.yaml
  scenarios/
    image-pull-error.yaml
    crash-loop.yaml
    readiness-fail.yaml
    bad-rollout-01-good.yaml
    bad-rollout-02-bad.yaml
```

## Scenario Map

| Scenario | Main symptom | Practice focus |
| --- | --- | --- |
| `healthy.yaml` | Normal Deployment and Service | `get`, `describe`, `exec`, `port-forward` |
| `image-pull-error.yaml` | Pod cannot pull image | `describe pod`, `events` |
| `crash-loop.yaml` | Container exits repeatedly | `logs`, `logs --previous`, `describe pod` |
| `readiness-fail.yaml` | Pod is Running but not Ready | readiness probe, Service endpoints |
| `bad-rollout-01-good.yaml` + `bad-rollout-02-bad.yaml` | Deployment rollout gets stuck | `rollout status`, `history`, `undo` |

## Basic Usage

Create the namespace first:

```bash
kubectl apply -f darkmind/namespace.yaml
```

Apply the healthy baseline:

```bash
kubectl apply -f darkmind/healthy.yaml
```

Inspect the baseline:

```bash
kubectl get all -n darkmind
kubectl describe deploy darkmind-healthy -n darkmind
kubectl port-forward -n darkmind svc/darkmind-healthy 8080:80
```

Clean up the whole lab:

```bash
kubectl delete namespace darkmind
```

## Scenario Usage

Apply one broken scenario at a time when possible. This keeps the output short and makes the debugging target clear.

Image pull failure:

```bash
kubectl apply -f darkmind/scenarios/image-pull-error.yaml
kubectl get pods -n darkmind
kubectl describe pod -n darkmind -l app=darkmind-image-pull-error
kubectl get events -n darkmind --sort-by=.lastTimestamp
```

Crash loop:

```bash
kubectl apply -f darkmind/scenarios/crash-loop.yaml
kubectl get pods -n darkmind
kubectl logs -n darkmind -l app=darkmind-crash-loop
kubectl logs -n darkmind -l app=darkmind-crash-loop --previous
```

Readiness failure:

```bash
kubectl apply -f darkmind/scenarios/readiness-fail.yaml
kubectl get pods -n darkmind
kubectl describe pod -n darkmind -l app=darkmind-readiness-fail
kubectl get endpoints -n darkmind darkmind-readiness-fail
```

Bad rollout:

```bash
kubectl apply -f darkmind/scenarios/bad-rollout-01-good.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=60s
kubectl apply -f darkmind/scenarios/bad-rollout-02-bad.yaml
kubectl rollout status deploy/darkmind-rollout -n darkmind --timeout=30s
kubectl rollout history deploy/darkmind-rollout -n darkmind
kubectl rollout undo deploy/darkmind-rollout -n darkmind
```

## W6 Operating Rule

For command drill, the goal is not to run the most commands. The goal is to explain:

1. What symptom did I observe?
2. Which Kubernetes layer am I checking now?
3. What evidence did this command give me?
4. What is the next smallest useful command?
