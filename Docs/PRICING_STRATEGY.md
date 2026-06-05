# MyStudyDen Pricing Strategy

Last updated: 2026-06-05

This document captures the early pricing and unit economics plan for MyStudyDen before deeper product implementation. The goal is to keep AI costs predictable while offering a simple subscription that can work for an individual developer.

## Current Recommendation

Start with a simple subscription:

- Free trial: 30 days
- Base plan: $4.99/month
- Optional future Pro plan: $9.99/month
- Default model: low-cost fixed API model, preferably Gemini Flash-Lite class
- Free trial limits: strict usage caps, even during the trial

The core principle is that the app should never offer unlimited AI usage without server-side quotas.

## Revenue Assumptions

For App Store subscriptions, assume Apple keeps a commission before proceeds reach the developer.

Apple's Small Business Program offers a reduced 15% commission rate for eligible developers on paid apps and In-App Purchases. New developers and developers with up to $1M USD in prior-year proceeds can generally qualify, subject to Apple's rules.

Source: https://developer.apple.com/app-store/small-business-program/

For a $4.99/month subscription:

```text
Gross subscription price:        $4.99
Apple commission at 15%:        -$0.75
Developer proceeds before tax:   $4.24
```

For a $9.99/month subscription:

```text
Gross subscription price:        $9.99
Apple commission at 15%:        -$1.50
Developer proceeds before tax:   $8.49
```

These are simplified estimates. Actual proceeds can vary by country, tax, currency conversion, App Store terms, and eligibility.

## AI Model Cost Assumptions

Gemini Flash-Lite class models are the most realistic starting point for a cost-sensitive learning app.

Google's published Gemini API pricing includes low-cost Flash-Lite style pricing around:

```text
Input:  $0.10 / 1M tokens
Output: $0.40 / 1M tokens
```

Source: https://ai.google.dev/gemini-api/docs/pricing

For comparison, higher-quality Flash models can be several times more expensive, especially on output tokens. The product should use a cheap model by default and reserve more expensive models for retry, premium features, or future Pro plans.

## Packet Generation Cost

A reasonable early estimate for one study packet:

```text
Input tokens:   3,000
Output tokens:  1,200
```

At $0.10 input and $0.40 output per 1M tokens:

```text
Input cost:  3,000 / 1,000,000 * $0.10 = $0.00030
Output cost: 1,200 / 1,000,000 * $0.40 = $0.00048
Total:                                      $0.00078
```

Approximate LLM cost by packet volume:

```text
10 packets/month:    $0.0078
50 packets/month:    $0.0390
100 packets/month:   $0.0780
200 packets/month:   $0.1560
500 packets/month:   $0.3900
```

At this model price, packet generation alone is cheap enough for a $4.99 plan. The risk comes from long documents, repeated regeneration, tutor chat, search grounding, PDFs, audio/video, and expensive model retries.

## Trial Risk

A one-month free trial is viable only if usage is capped.

Example:

```text
Free trial users:        1,000
Packets per user:        100
Total generations:       100,000
Approx cost/generation:  $0.00078
LLM cost:                about $78
```

That is manageable with a cheap model, but the same trial can become expensive if users paste long PDFs, ask for repeated regeneration, or use a premium model.

Recommended free trial limits:

```text
Trial length:                 30 days
Packet generations:            50 total
Max source text per packet:     8,000-12,000 characters initially
Regeneration limit:             3 per source
Tutor chat:                     limited or disabled in trial
Premium model retries:          disabled or very limited
```

The trial should prove product value, not offer unlimited AI usage.

## Plan Shape

### Base Plan

Suggested price:

```text
$4.99/month
```

Suggested included usage:

```text
100-200 study packets/month
Basic review questions
Basic study guide generation
Limited regeneration
No large file ingestion at first
```

This plan should be profitable if the app uses a low-cost model and enforces quotas.

### Pro Plan

Suggested future price:

```text
$9.99/month
```

Possible Pro features:

```text
Higher monthly packet quota
Longer source text
Better model fallback
More tutor chat
Priority regeneration
PDF/slides support
Course-level synthesis across many packets
```

Pro should map directly to higher usage and higher AI cost.

## Cost Formula

Use this model when reviewing unit economics:

```text
monthly_revenue =
  paid_users * subscription_price * (1 - app_store_commission)

monthly_ai_cost =
  users * generations_per_user * (
    avg_input_tokens / 1,000,000 * input_price_per_1m
    + avg_output_tokens / 1,000,000 * output_price_per_1m
  )

monthly_profit_before_fixed_costs =
  monthly_revenue - monthly_ai_cost

monthly_profit_after_fixed_costs =
  monthly_profit_before_fixed_costs - server_cost - other_tools
```

Track these variables:

```text
Paid users
Trial users
Trial conversion rate
Subscription price
Apple commission rate
Average packets/user/month
Average input tokens/packet
Average output tokens/packet
Regeneration rate
Model retry rate
Server cost
Support/tooling cost
```

## How Individual Developers Commonly Approach AI App Pricing

There is no single standard, but current indie AI app patterns usually look like this:

### 1. Subscription plus quotas

Many small AI apps avoid unlimited usage. They sell a subscription but quietly or explicitly cap AI-heavy operations.

Common pattern:

```text
Free trial or free tier
Monthly subscription
Monthly AI action quota
Soft or hard limits for expensive operations
```

For MyStudyDen, this means "packets per month" is easier to reason about than raw token credits.

### 2. Cheap model by default

Individual developers often use the cheapest acceptable model for normal work, then reserve better models for premium paths.

For MyStudyDen:

```text
Default: cheap model for packet generation
Fallback: source-backed deterministic server logic
Premium retry: better model only when needed
```

This keeps average cost low without making every request expensive.

### 3. Feature limits instead of token limits

Users do not understand tokens. They understand:

```text
50 packets/month
10 source uploads/month
3 regenerations/source
limited tutor chats
```

The server can translate those product limits into token budgets internally.

### 4. Free trial with guardrails

A one-month free trial is common, but for AI apps it must have usage limits. Without limits, a small number of heavy users can consume the budget.

For MyStudyDen:

```text
30-day free trial
50 packet cap
source length cap
limited regeneration
no premium model retry during trial
```

### 5. Annual plan discount

Many indie apps offer monthly and annual subscriptions:

```text
$4.99/month
$39.99/year or $49.99/year
```

Annual plans improve cash flow and reduce churn. They are useful after the product has stable value.

### 6. Usage observability from day one

AI apps need usage tracking early, even before monetization. Track:

```text
user_id
provider
model
feature
input_tokens
output_tokens
request_status
estimated_cost
created_at
```

This should be server-side, not only in the app.

### 7. Avoiding "unlimited AI" language

For an individual developer, "unlimited" is risky unless there is a fair-use policy and server-side enforcement. Safer wording:

```text
Generous monthly limits
Includes 200 study packets/month
Fair use applies
```

## Recommended Next Product Decisions

Before adding more AI features, decide:

1. What counts as one billable app action?
   - Recommended: one generated study packet.

2. What is the initial monthly quota?
   - Recommended: 100 packets/month for Base.

3. What is the trial quota?
   - Recommended: 50 packets total.

4. What is the maximum source size?
   - Recommended: 8,000-12,000 characters initially.

5. What model should be the production default?
   - Recommended: Gemini Flash-Lite class model, with server fallback.

6. Should there be a Pro tier at launch?
   - Recommended: not necessary at first. Start with one plan and add Pro after measuring usage.

## Initial Business Model Recommendation

Start simple:

```text
Plan: MyStudyDen
Price: $4.99/month
Trial: 30 days
Trial cap: 50 packets
Paid cap: 150 packets/month
Model: Gemini Flash-Lite class
Fallback: server source-backed generation
```

Add later:

```text
Pro: $9.99/month
Higher packet quota
Longer source uploads
Better model retries
Course synthesis
Tutor chat
```

The main success metric is not just gross revenue. It is:

```text
average monthly proceeds per paid user
- average monthly AI cost per paid user
- server cost per user
```

If the app can keep AI cost below $0.50/user/month on a $4.99 plan, the unit economics are likely healthy enough for an individual developer to continue iterating.
