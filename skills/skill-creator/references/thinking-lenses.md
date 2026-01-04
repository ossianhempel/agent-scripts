# Thinking Lenses for Skill Analysis

Use these analytical frameworks to deeply understand requirements before creating or improving a skill. Apply relevant lenses based on the skill's complexity and domain.

## Core Lenses (Apply to Most Skills)

### 1. First Principles
Break down the problem to its fundamental truths.

**Questions:**
- What is the core problem being solved?
- What are the essential inputs and outputs?
- What would a minimal viable solution look like?
- What constraints are truly immovable vs assumed?

### 2. User-Centric
View the skill from the end user's perspective.

**Questions:**
- What does success look like for the user?
- What triggers would feel natural to say/type?
- What would frustrate a user about this skill?
- What implicit expectations does the user have?

### 3. Edge Cases
Identify boundary conditions and unusual scenarios.

**Questions:**
- What happens with empty/null input?
- What happens with extremely large input?
- What unusual but valid inputs could occur?
- What error states need handling?

### 4. Systems Thinking
Understand how the skill fits into the broader ecosystem.

**Questions:**
- How does this skill interact with other skills?
- What external dependencies does it have?
- What happens if a dependency fails?
- Are there feedback loops or side effects?

### 5. Pre-Mortem
Imagine the skill has failed and work backward.

**Questions:**
- If this skill fails in 6 months, why?
- What assumptions could become invalid?
- What external changes could break this?
- What maintenance burden does this create?

## Extended Lenses (Apply to Complex Skills)

### 6. Inversion
Consider the opposite perspective.

**Questions:**
- What would make this skill useless?
- What should this skill NOT do?
- What anti-patterns should be avoided?
- What's the worst way to implement this?

### 7. Second-Order Thinking
Consider downstream effects.

**Questions:**
- If users rely on this skill heavily, what happens next?
- What behaviors does this skill encourage?
- What unintended consequences could emerge?
- How might usage patterns evolve?

### 8. Devil's Advocate
Challenge your own assumptions.

**Questions:**
- Why might this approach be wrong?
- What would a critic say about this design?
- What alternative approaches were dismissed too quickly?
- What evidence contradicts the current plan?

### 9. Constraints Analysis
Examine limitations and boundaries.

**Questions:**
- What are the token/context constraints?
- What are the time/performance constraints?
- What are the capability constraints of the model?
- What are the user's environment constraints?

### 10. Pareto Principle
Identify the vital few vs trivial many.

**Questions:**
- What 20% of features provide 80% of value?
- What's the minimum scope that's still useful?
- What can be deferred to future iterations?
- What complexity can be eliminated?

### 11. Root Cause Analysis
Dig deeper into the underlying need.

**Questions:**
- Why does the user need this skill? (ask 5 times)
- What problem behind the problem exists?
- Is this skill treating symptoms or causes?
- What's the user's ultimate goal?

## How to Apply Lenses

### Quick Analysis (Simple Skills)
Apply 3-4 core lenses:
1. First Principles
2. User-Centric
3. Edge Cases
4. Pre-Mortem

### Deep Analysis (Complex Skills)
Apply all 11 lenses, documenting insights from each.

### Regression Questioning
After applying lenses, continue self-questioning until three consecutive rounds produce no new insights:

1. "What am I still assuming that might not be true?"
2. "What would a domain expert add?"
3. "What's the simplest version that provides value?"

## Output: Three-Layer Requirements

Organize discovered requirements into three layers:

| Layer | Description | How Discovered |
|-------|-------------|----------------|
| **Explicit** | Stated directly by user | User interview |
| **Implicit** | Expected but unstated | User-Centric, First Principles lenses |
| **Unknown Unknowns** | Discovered through analysis | Edge Cases, Pre-Mortem, Inversion lenses |

Document all three layers before proceeding to skill creation.
