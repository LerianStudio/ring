# Anti-Rationalization Patterns

Canonical source for anti-rationalization patterns used by all ops-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in production operations workflows. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is prototype/throwaway infrastructure" | Prototypes become production 60% of time. Standards apply to ALL infrastructure. | **Apply full standards. No prototype exemption.** |
| "Too exhausted to do this properly" | Exhaustion doesn't waive requirements. It increases error risk. | **STOP work. Resume when able to comply fully.** |
| "Time pressure + authority says skip" | Combined pressures don't multiply exceptions. Zero exceptions x any pressure = zero exceptions. | **Follow all requirements regardless of pressure combination.** |
| "Similar task worked without this step" | Past non-compliance doesn't justify future non-compliance. | **Follow complete process every time.** |
| "User explicitly authorized skip" | User authorization doesn't override HARD GATES. | **Cannot comply. Explain non-negotiable requirement.** |

---

## Incident Response Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Need to fix immediately, skip documentation" | Undocumented fixes create knowledge gaps | **Document WHILE fixing, not after** |
| "Root cause analysis can wait" | Delayed RCA = forgotten details | **RCA within 24-48 hours** |
| "Rollback will fix everything" | Rollback may introduce other issues | **Verify rollback safety first** |
| "Only I understand this system" | Single-point knowledge = organizational risk | **Document and share immediately** |

---

## Cost Optimization Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Small savings not worth the effort" | Small savings compound over time | **Evaluate ALL savings opportunities** |
| "Reserved instances are too risky" | RI risk is manageable with proper planning | **Analyze RI coverage for stable workloads** |
| "Can optimize later when costs are higher" | Later = never. Costs compound. | **Optimize NOW with data-driven decisions** |
| "Development environment doesn't need optimization" | Dev costs are often 30%+ of total | **Apply optimization to ALL environments** |

---

## Security Operations Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Internal service, security can be relaxed" | Internal breaches happen frequently | **Apply security standards uniformly** |
| "Vulnerability is theoretical" | Theoretical today = exploited tomorrow | **Remediate based on severity, not probability** |
| "Security scan slows deployment" | Slow deployment > compromised production | **Run security scans ALWAYS** |
| "Legacy system, different rules apply" | Legacy = higher risk, MORE scrutiny needed | **Apply stricter standards to legacy** |

---

## Infrastructure Architecture Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Architecture review slows delivery" | Bad architecture = exponential slowdown later | **Architecture review is MANDATORY** |
| "We can refactor later" | Refactoring is 10x more expensive than doing it right | **Design correctly FIRST** |
| "Single region is simpler" | Single region = single point of failure | **Design for resilience from start** |
| "DR can be added later" | DR added later is rarely tested | **DR is day-1 requirement** |

---

## Platform Engineering Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Manual process works fine" | Manual = error-prone, unscalable | **Automate from the start** |
| "Documentation can come later" | Later = never. Onboarding suffers. | **Document as you build** |
| "Self-service isn't necessary yet" | Without self-service, platform team = bottleneck | **Build self-service capabilities early** |
| "Golden paths restrict flexibility" | Golden paths enable speed, exceptions are allowed | **Establish golden paths first** |
