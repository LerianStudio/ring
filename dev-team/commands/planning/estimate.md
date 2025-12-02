---
allowed-tools: Bash(*), Read(*), Grep(*), Task(*), WebSearch(*)
description: Generate accurate project time estimates using historical data and team velocity
argument-hint: [--task=<task-description>]
---

# /shared:planning:estimate

## Context

Generate data-driven project estimates using historical analysis and team metrics. Transform gut-feel estimates into data-backed predictions by analyzing git history, commit patterns, and team velocity.

## Features

- 📊 Historical data analysis from git and project tools
- 👥 Team and individual velocity tracking
- 📈 Complexity-based adjustments
- 🎯 Confidence intervals and risk assessment

## Usage

```bash
# Estimate a specific task
claude "Estimate task: Implement OAuth2 login flow with Google in React"

# Check estimation accuracy

claude "Show estimation accuracy for the last 10 sprints"

# Get assignee-specific estimates

claude "How long would Alice take to implement the payment webhook in Node.js?"
```

## Process

### Estimation Methodology

### 1. Gather Historical Data

```bash
# Get 6 months of commit history
git log --pretty=format:"%h|%an|%ad|%s" --date=iso --since="6 months ago"

# Get file change frequency
git log --pretty=format: --name-only --since="6 months ago" | sort | uniq -c | sort -rn

# Track file change patterns
git shortlog -sn --since="6 months ago"
```


### 2. Calculate Complexity Metrics

**Code Analysis Factors:**

- Lines of code and cyclomatic complexity
- Dependencies (imports/requires)
- Framework-specific complexity (React hooks, TypeScript types)
- File change frequency and similarity to existing code

**Task Classification:**

- **High complexity**: Refactoring, migrations, architecture changes
- **Medium complexity**: New features, integrations, component creation
- **Low complexity**: Bug fixes, styling, minor modifications

### 3. Build Estimation Model

**Core Algorithm:**

1. Find similar completed tasks using feature extraction
2. Calculate median estimate from similar tasks
3. Apply complexity multipliers based on task characteristics
4. Adjust for assignee velocity (if specified)
5. Add confidence intervals based on data quality

**Velocity Calculation:**

- Track story points per sprint by team member
- Calculate lines of code per day averages
- Measure estimate accuracy over time
- Account for task type specializations

### 4. Generate Estimates

**Output Format:**

```
Task: "Refactor user authentication to use JWT tokens"

📊 Analysis:
- Base estimate: 4 points (from 23 similar auth tasks)
- Complexity adjustments: +1.5 points (refactoring + security)
- Assignee factor: -0.5 points (Bob is 20% faster on refactoring)

Final Estimate: 5 Story Points
Confidence: 78% | Range: 3-8 points | Time: 15-25 hours

📝 Breakdown:
1. Analyze current system (0.5 pts)
2. Design JWT structure (0.5 pts)
3. Implement JWT service (1.5 pts)
4. Update middleware (1.5 pts)
5. Tests and docs (1 pt)
```

## Confidence Levels
| Level     | Criteria           | Variance |
| --------- | ------------------ | -------- |
| High      | 20+ similar tasks  | ±15%     |
| Medium    | 5-20 similar tasks | ±30%     |
| Low       | <5 similar tasks   | ±50%     |
| Uncertain | No historical data | ±100%    |

## Patterns

**JavaScript/TypeScript Indicators:**

- React components: Count hooks and component definitions
- API work: REST/GraphQL endpoint complexity
- State management: Redux/Context API integration
- Testing: Coverage and test type requirements

**Team Factors:**

- Individual velocity vs team average
- Specialization areas (UI, backend, testing)
- Recent performance trends
- Current sprint capacity

## Implementation
1. **Data Collection**: Run git analysis commands
2. **Feature Extraction**: Parse task description for complexity indicators
3. **Similarity Matching**: Find comparable completed tasks
4. **Adjustment Calculation**: Apply complexity and velocity factors
5. **Confidence Assessment**: Evaluate estimate reliability
6. **Report Generation**: Provide breakdown and recommendations

## Best Practices
- Maintain 6+ months of historical data
- Re-calibrate after each sprint
- Account for meetings/context switching (60-70% coding time)
- Include code review and testing buffers
- Document estimation assumptions
- Track actual vs estimated for continuous improvement
